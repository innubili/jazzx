import 'dart:convert';
import 'dart:io';
import 'package:path_provider/path_provider.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'structured_logger.dart';

/// Handles persistence of log entries to local storage
class LogPersistenceHandler {
  static const String _logFilePrefix = 'jazzx_logs_';
  static const String _logIndexKey = 'log_file_index';
  static const int _maxLogFileSize = 1024 * 1024; // 1MB per file
  static const int _maxLogFiles = 10; // Keep max 10 log files
  static const int _batchSize = 50; // Write logs in batches

  final List<LogEntry> _pendingLogs = [];
  String? _currentLogFilePath;
  int _currentFileIndex = 0;

  /// Initialize the persistence handler
  Future<void> initialize() async {
    await _loadCurrentFileIndex();
    await _createCurrentLogFile();
    await _cleanupOldLogFiles();
  }

  /// Handle a new log entry
  Future<void> handleLog(LogEntry logEntry) async {
    _pendingLogs.add(logEntry);
    
    // Write in batches for better performance
    if (_pendingLogs.length >= _batchSize) {
      await _flushPendingLogs();
    }
  }

  /// Force flush all pending logs
  Future<void> flush() async {
    if (_pendingLogs.isNotEmpty) {
      await _flushPendingLogs();
    }
  }

  /// Get all stored log entries
  Future<List<LogEntry>> getAllLogs({
    DateTime? since,
    LogLevel? minLevel,
    LogCategory? category,
    int? limit,
  }) async {
    final allLogs = <LogEntry>[];
    
    // Read from all log files
    final logFiles = await _getLogFiles();
    
    for (final file in logFiles) {
      try {
        final content = await file.readAsString();
        final lines = content.split('\n').where((line) => line.trim().isNotEmpty);
        
        for (final line in lines) {
          try {
            final json = jsonDecode(line);
            final logEntry = LogEntry.fromJson(json);
            
            // Apply filters
            if (since != null && logEntry.timestamp.isBefore(since)) continue;
            if (minLevel != null && LogLevel.values.indexOf(logEntry.level) < LogLevel.values.indexOf(minLevel)) continue;
            if (category != null && logEntry.category != category) continue;
            
            allLogs.add(logEntry);
          } catch (e) {
            // Skip malformed log entries
            continue;
          }
        }
      } catch (e) {
        // Skip unreadable files
        continue;
      }
    }
    
    // Sort by timestamp (newest first)
    allLogs.sort((a, b) => b.timestamp.compareTo(a.timestamp));
    
    // Apply limit
    if (limit != null && allLogs.length > limit) {
      return allLogs.take(limit).toList();
    }
    
    return allLogs;
  }

  /// Export logs as JSON string
  Future<String> exportLogs({
    DateTime? since,
    LogLevel? minLevel,
    LogCategory? category,
  }) async {
    final logs = await getAllLogs(
      since: since,
      minLevel: minLevel,
      category: category,
    );
    
    final exportData = {
      'export_timestamp': DateTime.now().toIso8601String(),
      'total_logs': logs.length,
      'filters': {
        'since': since?.toIso8601String(),
        'min_level': minLevel?.name,
        'category': category?.name,
      },
      'logs': logs.map((log) => log.toJson()).toList(),
    };
    
    return jsonEncode(exportData);
  }

  /// Clear all stored logs
  Future<void> clearAllLogs() async {
    final logFiles = await _getLogFiles();
    
    for (final file in logFiles) {
      try {
        await file.delete();
      } catch (e) {
        // Ignore deletion errors
      }
    }
    
    _pendingLogs.clear();
    _currentFileIndex = 0;
    await _saveCurrentFileIndex();
    await _createCurrentLogFile();
  }

  /// Get log storage statistics
  Future<Map<String, dynamic>> getStorageStats() async {
    final logFiles = await _getLogFiles();
    int totalSize = 0;
    int totalLogs = 0;
    
    for (final file in logFiles) {
      try {
        final stat = await file.stat();
        totalSize += stat.size;
        
        // Count lines (approximate log count)
        final content = await file.readAsString();
        totalLogs += content.split('\n').where((line) => line.trim().isNotEmpty).length;
      } catch (e) {
        // Skip unreadable files
      }
    }
    
    return {
      'total_files': logFiles.length,
      'total_size_bytes': totalSize,
      'total_size_mb': (totalSize / (1024 * 1024)).toStringAsFixed(2),
      'total_logs': totalLogs,
      'pending_logs': _pendingLogs.length,
      'current_file_index': _currentFileIndex,
    };
  }

  /// Private methods

  Future<void> _loadCurrentFileIndex() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      _currentFileIndex = prefs.getInt(_logIndexKey) ?? 0;
    } catch (e) {
      _currentFileIndex = 0;
    }
  }

  Future<void> _saveCurrentFileIndex() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      await prefs.setInt(_logIndexKey, _currentFileIndex);
    } catch (e) {
      // Ignore save errors
    }
  }

  Future<void> _createCurrentLogFile() async {
    try {
      final directory = await getApplicationDocumentsDirectory();
      final fileName = '$_logFilePrefix${_currentFileIndex.toString().padLeft(3, '0')}.jsonl';
      _currentLogFilePath = '${directory.path}/$fileName';
      
      final file = File(_currentLogFilePath!);
      if (!await file.exists()) {
        await file.create(recursive: true);
      }
    } catch (e) {
      _currentLogFilePath = null;
    }
  }

  Future<void> _flushPendingLogs() async {
    if (_currentLogFilePath == null || _pendingLogs.isEmpty) return;
    
    try {
      final file = File(_currentLogFilePath!);
      
      // Check if we need to rotate to a new file
      if (await file.exists()) {
        final stat = await file.stat();
        if (stat.size > _maxLogFileSize) {
          await _rotateLogFile();
        }
      }
      
      // Write pending logs
      final logLines = _pendingLogs.map((log) => jsonEncode(log.toJson())).join('\n');
      await file.writeAsString('$logLines\n', mode: FileMode.append);
      
      _pendingLogs.clear();
    } catch (e) {
      // If writing fails, keep logs in memory
    }
  }

  Future<void> _rotateLogFile() async {
    _currentFileIndex++;
    await _saveCurrentFileIndex();
    await _createCurrentLogFile();
    await _cleanupOldLogFiles();
  }

  Future<void> _cleanupOldLogFiles() async {
    try {
      final logFiles = await _getLogFiles();
      
      if (logFiles.length > _maxLogFiles) {
        // Sort by modification time (oldest first)
        logFiles.sort((a, b) => a.lastModifiedSync().compareTo(b.lastModifiedSync()));
        
        // Delete oldest files
        final filesToDelete = logFiles.take(logFiles.length - _maxLogFiles);
        for (final file in filesToDelete) {
          try {
            await file.delete();
          } catch (e) {
            // Ignore deletion errors
          }
        }
      }
    } catch (e) {
      // Ignore cleanup errors
    }
  }

  Future<List<File>> _getLogFiles() async {
    try {
      final directory = await getApplicationDocumentsDirectory();
      final files = await directory.list().toList();
      
      return files
          .whereType<File>()
          .where((file) => file.path.contains(_logFilePrefix))
          .toList();
    } catch (e) {
      return [];
    }
  }
}

/// Log analytics handler for tracking patterns and metrics
class LogAnalyticsHandler {
  final Map<String, int> _eventCounts = {};
  final Map<String, List<DateTime>> _eventTimestamps = {};
  final Map<String, Duration> _operationDurations = {};

  /// Handle a new log entry for analytics
  void handleLog(LogEntry logEntry) {
    final key = '${logEntry.category.name}:${logEntry.level.name}';
    
    // Count events
    _eventCounts[key] = (_eventCounts[key] ?? 0) + 1;
    
    // Track timestamps for rate analysis
    _eventTimestamps.putIfAbsent(key, () => []).add(logEntry.timestamp);
    
    // Track operation durations
    if (logEntry.metadata.containsKey('duration_ms')) {
      final duration = Duration(milliseconds: logEntry.metadata['duration_ms']);
      _operationDurations[logEntry.message] = duration;
    }
    
    // Clean old timestamps (keep only last hour)
    final oneHourAgo = DateTime.now().subtract(const Duration(hours: 1));
    _eventTimestamps[key]?.removeWhere((timestamp) => timestamp.isBefore(oneHourAgo));
  }

  /// Get analytics summary
  Map<String, dynamic> getAnalytics() {
    final now = DateTime.now();
    final oneHourAgo = now.subtract(const Duration(hours: 1));
    
    // Calculate event rates (events per hour)
    final eventRates = <String, double>{};
    for (final entry in _eventTimestamps.entries) {
      final recentEvents = entry.value.where((timestamp) => timestamp.isAfter(oneHourAgo)).length;
      eventRates[entry.key] = recentEvents.toDouble();
    }
    
    // Find most common events
    final sortedEvents = _eventCounts.entries.toList()
      ..sort((a, b) => b.value.compareTo(a.value));
    
    // Calculate average operation durations
    final avgDurations = <String, int>{};
    for (final entry in _operationDurations.entries) {
      avgDurations[entry.key] = entry.value.inMilliseconds;
    }
    
    return {
      'total_events': _eventCounts.values.fold(0, (sum, count) => sum + count),
      'event_counts': Map.from(_eventCounts),
      'event_rates_per_hour': eventRates,
      'top_events': sortedEvents.take(10).map((e) => {'event': e.key, 'count': e.value}).toList(),
      'operation_durations_ms': avgDurations,
      'analysis_timestamp': now.toIso8601String(),
    };
  }

  /// Reset analytics data
  void reset() {
    _eventCounts.clear();
    _eventTimestamps.clear();
    _operationDurations.clear();
  }
}
