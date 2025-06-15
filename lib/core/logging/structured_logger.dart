import 'dart:convert';
import 'package:flutter/foundation.dart';

/// Log levels with additional context
enum LogLevel { trace, debug, info, warning, error, fatal }

/// Log categories for better organization
enum LogCategory {
  cache,
  network,
  auth,
  performance,
  ui,
  database,
  error,
  analytics,
  system,
}

/// Structured log entry with metadata
class LogEntry {
  final DateTime timestamp;
  final LogLevel level;
  final LogCategory category;
  final String message;
  final String? component;
  final Map<String, dynamic> metadata;
  final String? userId;
  final String? sessionId;
  final String? error;
  final String? stackTrace;

  LogEntry({
    required this.timestamp,
    required this.level,
    required this.category,
    required this.message,
    this.component,
    this.metadata = const {},
    this.userId,
    this.sessionId,
    this.error,
    this.stackTrace,
  });

  /// Convert to JSON for storage/transmission
  Map<String, dynamic> toJson() {
    return {
      'timestamp': timestamp.toIso8601String(),
      'level': level.name,
      'category': category.name,
      'message': message,
      'component': component,
      'metadata': metadata,
      'userId': userId,
      'sessionId': sessionId,
      'error': error,
      'stackTrace': stackTrace,
    };
  }

  /// Create from JSON
  factory LogEntry.fromJson(Map<String, dynamic> json) {
    return LogEntry(
      timestamp: DateTime.parse(json['timestamp']),
      level: LogLevel.values.firstWhere((e) => e.name == json['level']),
      category: LogCategory.values.firstWhere(
        (e) => e.name == json['category'],
      ),
      message: json['message'],
      component: json['component'],
      metadata: Map<String, dynamic>.from(json['metadata'] ?? {}),
      userId: json['userId'],
      sessionId: json['sessionId'],
      error: json['error'],
      stackTrace: json['stackTrace'],
    );
  }

  /// Format for console output
  String get formattedMessage {
    final buffer = StringBuffer();

    // Timestamp and level
    buffer.write('${timestamp.toIso8601String().substring(11, 23)} ');
    buffer.write('[${level.name.toUpperCase().padRight(7)}] ');

    // Category and component
    buffer.write('[${category.name.toUpperCase()}');
    if (component != null) {
      buffer.write(':$component');
    }
    buffer.write('] ');

    // Message
    buffer.write(message);

    // Metadata
    if (metadata.isNotEmpty) {
      buffer.write(' | ${jsonEncode(metadata)}');
    }

    // Context
    if (userId != null || sessionId != null) {
      buffer.write(' | Context: ');
      if (userId != null) buffer.write('user=$userId ');
      if (sessionId != null) buffer.write('session=$sessionId');
    }

    // Error details
    if (error != null) {
      buffer.write('\n  ERROR: $error');
    }
    if (stackTrace != null && kDebugMode) {
      buffer.write('\n  STACK: $stackTrace');
    }

    return buffer.toString();
  }
}

/// Global log context for adding user/session info to all logs
class LogContext {
  static String? _userId;
  static String? _sessionId;
  static String? _currentFeature;
  static final Map<String, dynamic> _globalMetadata = {};

  static String? get userId => _userId;
  static String? get sessionId => _sessionId;
  static String? get currentFeature => _currentFeature;
  static Map<String, dynamic> get globalMetadata => Map.from(_globalMetadata);

  static void setUser(String? userId) {
    _userId = userId;
  }

  static void setSession(String? sessionId) {
    _sessionId = sessionId;
  }

  static void setCurrentFeature(String? feature) {
    _currentFeature = feature;
  }

  static void addGlobalMetadata(String key, dynamic value) {
    _globalMetadata[key] = value;
  }

  static void removeGlobalMetadata(String key) {
    _globalMetadata.remove(key);
  }

  static void clearGlobalMetadata() {
    _globalMetadata.clear();
  }

  static void reset() {
    _userId = null;
    _sessionId = null;
    _currentFeature = null;
    _globalMetadata.clear();
  }
}

/// Main structured logger class
class StructuredLogger {
  static final StructuredLogger _instance = StructuredLogger._internal();
  factory StructuredLogger() => _instance;
  StructuredLogger._internal();

  final List<LogEntry> _logBuffer = [];
  final int _maxBufferSize = 1000;

  // Callbacks for log processing
  final List<Function(LogEntry)> _logHandlers = [];

  /// Add a log handler (for persistence, analytics, etc.)
  void addLogHandler(Function(LogEntry) handler) {
    _logHandlers.add(handler);
  }

  /// Remove a log handler
  void removeLogHandler(Function(LogEntry) handler) {
    _logHandlers.remove(handler);
  }

  /// Log a structured entry
  void log(
    LogLevel level,
    LogCategory category,
    String message, {
    String? component,
    Map<String, dynamic>? metadata,
    String? error,
    String? stackTrace,
  }) {
    final entry = LogEntry(
      timestamp: DateTime.now(),
      level: level,
      category: category,
      message: message,
      component: component,
      metadata: {
        ...LogContext.globalMetadata,
        ...?metadata,
        if (LogContext.currentFeature != null)
          'feature': LogContext.currentFeature,
      },
      userId: LogContext.userId,
      sessionId: LogContext.sessionId,
      error: error,
      stackTrace: stackTrace,
    );

    // Add to buffer
    _logBuffer.add(entry);
    if (_logBuffer.length > _maxBufferSize) {
      _logBuffer.removeAt(0);
    }

    // Send to console
    _logToConsole(entry);

    // Send to handlers
    for (final handler in _logHandlers) {
      try {
        handler(entry);
      } catch (e) {
        // Don't let log handler errors break the app
        debugPrint('Log handler error: $e');
      }
    }
  }

  /// Log to console with clean output (no Flutter prefixes)
  void _logToConsole(LogEntry entry) {
    if (!kDebugMode) return;

    final timestamp = entry.timestamp.toIso8601String().substring(11, 23);
    final level = entry.level.name.toUpperCase().padRight(7);
    final category = entry.category.name.toUpperCase();
    final component = entry.component ?? category;

    final contextParts = <String>[];
    if (entry.userId != null) contextParts.add('user=${entry.userId}');
    if (entry.sessionId != null) contextParts.add('session=${entry.sessionId}');
    final contextStr =
        contextParts.isNotEmpty ? ' | Context: ${contextParts.join(', ')}' : '';

    final metadataStr =
        entry.metadata.isNotEmpty ? ' | ${jsonEncode(entry.metadata)}' : '';

    final errorStr = entry.error != null ? ' | ERROR: ${entry.error}' : '';

    final message =
        'JAZZX: $timestamp [$level] [$category:$component] ${entry.message}$metadataStr$contextStr$errorStr';

    // Use simple print with special prefix for easy filtering
    // ignore: avoid_print
    print(message);
  }

  /// Get recent log entries
  List<LogEntry> getRecentLogs({
    int? limit,
    LogLevel? minLevel,
    LogCategory? category,
    String? component,
  }) {
    var logs = List<LogEntry>.from(_logBuffer);

    // Filter by level
    if (minLevel != null) {
      final minIndex = LogLevel.values.indexOf(minLevel);
      logs =
          logs
              .where((log) => LogLevel.values.indexOf(log.level) >= minIndex)
              .toList();
    }

    // Filter by category
    if (category != null) {
      logs = logs.where((log) => log.category == category).toList();
    }

    // Filter by component
    if (component != null) {
      logs = logs.where((log) => log.component == component).toList();
    }

    // Sort by timestamp (newest first)
    logs.sort((a, b) => b.timestamp.compareTo(a.timestamp));

    // Apply limit
    if (limit != null && logs.length > limit) {
      logs = logs.take(limit).toList();
    }

    return logs;
  }

  /// Clear log buffer
  void clearBuffer() {
    _logBuffer.clear();
  }

  /// Get log statistics
  Map<String, dynamic> getLogStatistics() {
    final stats = <String, dynamic>{};

    // Count by level
    final levelCounts = <String, int>{};
    for (final level in LogLevel.values) {
      levelCounts[level.name] =
          _logBuffer.where((log) => log.level == level).length;
    }
    stats['levels'] = levelCounts;

    // Count by category
    final categoryCounts = <String, int>{};
    for (final category in LogCategory.values) {
      categoryCounts[category.name] =
          _logBuffer.where((log) => log.category == category).length;
    }
    stats['categories'] = categoryCounts;

    // Recent activity
    final now = DateTime.now();
    final last5Minutes = now.subtract(const Duration(minutes: 5));
    final recentLogs =
        _logBuffer.where((log) => log.timestamp.isAfter(last5Minutes)).length;
    stats['recent_activity'] = recentLogs;

    // Error rate
    final errorLogs =
        _logBuffer
            .where(
              (log) =>
                  log.level == LogLevel.error || log.level == LogLevel.fatal,
            )
            .length;
    stats['error_rate'] =
        _logBuffer.isEmpty ? 0.0 : errorLogs / _logBuffer.length;

    stats['total_logs'] = _logBuffer.length;
    stats['buffer_size'] = _maxBufferSize;

    return stats;
  }
}
