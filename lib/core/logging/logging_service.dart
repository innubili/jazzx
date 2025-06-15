import 'package:flutter/foundation.dart';
import 'package:package_info_plus/package_info_plus.dart';
import 'structured_logger.dart';
import 'app_loggers.dart';
import 'log_persistence.dart';

/// Main logging service that coordinates all logging functionality
class LoggingService {
  static final LoggingService _instance = LoggingService._internal();
  factory LoggingService() => _instance;
  LoggingService._internal();

  late final StructuredLogger _structuredLogger;
  late final LogPersistenceHandler _persistenceHandler;
  late final LogAnalyticsHandler _analyticsHandler;

  bool _isInitialized = false;
  bool _persistenceEnabled = true;
  bool _analyticsEnabled = true;

  /// Initialize the logging service
  Future<void> initialize({
    bool enablePersistence = true,
    bool enableAnalytics = true,
    LogLevel minLevel = LogLevel.debug,
  }) async {
    if (_isInitialized) return;

    _structuredLogger = StructuredLogger();
    _persistenceHandler = LogPersistenceHandler();
    _analyticsHandler = LogAnalyticsHandler();

    _persistenceEnabled = enablePersistence;
    _analyticsEnabled = enableAnalytics;

    // Initialize persistence if enabled
    if (_persistenceEnabled) {
      try {
        await _persistenceHandler.initialize();
        _structuredLogger.addLogHandler(_persistenceHandler.handleLog);
        AppLoggers.system.info('Log persistence initialized');
      } catch (e) {
        debugPrint('Failed to initialize log persistence: $e');
        _persistenceEnabled = false;
      }
    }

    // Initialize analytics if enabled
    if (_analyticsEnabled) {
      _structuredLogger.addLogHandler(_analyticsHandler.handleLog);
      AppLoggers.system.info('Log analytics initialized');
    }

    // Set up global context
    await _setupGlobalContext();

    _isInitialized = true;
    AppLoggers.system.info(
      'Logging service initialized',
      metadata: {
        'persistence_enabled': _persistenceEnabled,
        'analytics_enabled': _analyticsEnabled,
        'min_level': minLevel.name,
      },
    );
  }

  /// Set user context for all logs
  void setUserContext(String userId, {Map<String, dynamic>? userMetadata}) {
    LogContext.setUser(userId);

    if (userMetadata != null) {
      for (final entry in userMetadata.entries) {
        LogContext.addGlobalMetadata('user_${entry.key}', entry.value);
      }
    }

    AppLoggers.auth.info(
      'User context set',
      metadata: {
        'user_id': userId,
        'metadata_keys': userMetadata?.keys.toList(),
      },
    );
  }

  /// Set session context for all logs
  void setSessionContext(
    String sessionId, {
    Map<String, dynamic>? sessionMetadata,
  }) {
    LogContext.setSession(sessionId);

    if (sessionMetadata != null) {
      for (final entry in sessionMetadata.entries) {
        LogContext.addGlobalMetadata('session_${entry.key}', entry.value);
      }
    }

    AppLoggers.system.info(
      'Session context set',
      metadata: {
        'session_id': sessionId,
        'metadata_keys': sessionMetadata?.keys.toList(),
      },
    );
  }

  /// Set current feature context
  void setFeatureContext(String feature) {
    LogContext.setCurrentFeature(feature);
    AppLoggers.ui.debug('Feature context set', metadata: {'feature': feature});
  }

  /// Clear user context
  void clearUserContext() {
    final userId = LogContext.userId;
    LogContext.setUser(null);

    // Remove user metadata
    final keysToRemove =
        LogContext.globalMetadata.keys
            .where((key) => key.startsWith('user_'))
            .toList();
    for (final key in keysToRemove) {
      LogContext.removeGlobalMetadata(key);
    }

    AppLoggers.auth.info(
      'User context cleared',
      metadata: {'previous_user_id': userId},
    );
  }

  /// Clear session context
  void clearSessionContext() {
    final sessionId = LogContext.sessionId;
    LogContext.setSession(null);

    // Remove session metadata
    final keysToRemove =
        LogContext.globalMetadata.keys
            .where((key) => key.startsWith('session_'))
            .toList();
    for (final key in keysToRemove) {
      LogContext.removeGlobalMetadata(key);
    }

    AppLoggers.system.info(
      'Session context cleared',
      metadata: {'previous_session_id': sessionId},
    );
  }

  /// Get recent logs with filtering
  Future<List<LogEntry>> getRecentLogs({
    int limit = 100,
    LogLevel? minLevel,
    LogCategory? category,
    String? component,
    bool includeMemoryLogs = true,
    bool includePersistedLogs = true,
  }) async {
    final allLogs = <LogEntry>[];

    // Get memory logs
    if (includeMemoryLogs) {
      final memoryLogs = _structuredLogger.getRecentLogs(
        limit: limit,
        minLevel: minLevel,
        category: category,
        component: component,
      );
      allLogs.addAll(memoryLogs);
    }

    // Get persisted logs
    if (includePersistedLogs && _persistenceEnabled) {
      try {
        final persistedLogs = await _persistenceHandler.getAllLogs(
          minLevel: minLevel,
          category: category,
          limit: limit,
        );
        allLogs.addAll(persistedLogs);
      } catch (e) {
        AppLoggers.error.error(
          'Failed to retrieve persisted logs',
          error: e.toString(),
        );
      }
    }

    // Remove duplicates and sort
    final uniqueLogs = <String, LogEntry>{};
    for (final log in allLogs) {
      final key = '${log.timestamp.millisecondsSinceEpoch}_${log.message}';
      uniqueLogs[key] = log;
    }

    final sortedLogs =
        uniqueLogs.values.toList()
          ..sort((a, b) => b.timestamp.compareTo(a.timestamp));

    return sortedLogs.take(limit).toList();
  }

  /// Export logs for debugging or support
  Future<String> exportLogs({
    DateTime? since,
    LogLevel? minLevel,
    LogCategory? category,
  }) async {
    if (!_persistenceEnabled) {
      throw Exception('Log persistence is not enabled');
    }

    try {
      return await _persistenceHandler.exportLogs(
        since: since,
        minLevel: minLevel,
        category: category,
      );
    } catch (e) {
      AppLoggers.error.error('Failed to export logs', error: e.toString());
      rethrow;
    }
  }

  /// Get logging statistics
  Map<String, dynamic> getLoggingStatistics() {
    final stats = <String, dynamic>{};

    // Memory statistics
    stats['memory'] = _structuredLogger.getLogStatistics();

    // Analytics statistics
    if (_analyticsEnabled) {
      stats['analytics'] = _analyticsHandler.getAnalytics();
    }

    // Context information
    stats['context'] = {
      'user_id': LogContext.userId,
      'session_id': LogContext.sessionId,
      'current_feature': LogContext.currentFeature,
      'global_metadata_keys': LogContext.globalMetadata.keys.toList(),
    };

    // Service status
    stats['service'] = {
      'initialized': _isInitialized,
      'persistence_enabled': _persistenceEnabled,
      'analytics_enabled': _analyticsEnabled,
    };

    return stats;
  }

  /// Get storage statistics (if persistence is enabled)
  Future<Map<String, dynamic>?> getStorageStatistics() async {
    if (!_persistenceEnabled) return null;

    try {
      return await _persistenceHandler.getStorageStats();
    } catch (e) {
      AppLoggers.error.error(
        'Failed to get storage statistics',
        error: e.toString(),
      );
      return null;
    }
  }

  /// Clear all logs
  Future<void> clearAllLogs() async {
    // Clear memory logs
    _structuredLogger.clearBuffer();

    // Clear persisted logs
    if (_persistenceEnabled) {
      try {
        await _persistenceHandler.clearAllLogs();
      } catch (e) {
        AppLoggers.error.error(
          'Failed to clear persisted logs',
          error: e.toString(),
        );
      }
    }

    // Reset analytics
    if (_analyticsEnabled) {
      _analyticsHandler.reset();
    }

    AppLoggers.system.info('All logs cleared');
  }

  /// Flush pending logs to storage
  Future<void> flush() async {
    if (_persistenceEnabled) {
      try {
        await _persistenceHandler.flush();
      } catch (e) {
        AppLoggers.error.error('Failed to flush logs', error: e.toString());
      }
    }
  }

  /// Shutdown the logging service
  Future<void> shutdown() async {
    if (!_isInitialized) return;

    AppLoggers.system.info('Logging service shutting down');

    // Flush any pending logs
    await flush();

    // Clear contexts
    LogContext.reset();

    _isInitialized = false;
  }

  /// Private methods

  Future<void> _setupGlobalContext() async {
    // Get app version from package info
    try {
      final packageInfo = await PackageInfo.fromPlatform();
      LogContext.addGlobalMetadata('app_version', packageInfo.version);
      LogContext.addGlobalMetadata('build_number', packageInfo.buildNumber);
      LogContext.addGlobalMetadata('app_name', packageInfo.appName);
      LogContext.addGlobalMetadata('package_name', packageInfo.packageName);
    } catch (e) {
      // Fallback to hardcoded version if package info fails
      LogContext.addGlobalMetadata('app_version', '1.0.0');
      AppLoggers.error.warning(
        'Failed to get package info, using fallback version',
        metadata: {'error': e.toString()},
      );
    }

    // Add platform metadata
    LogContext.addGlobalMetadata('platform', defaultTargetPlatform.name);
    LogContext.addGlobalMetadata('debug_mode', kDebugMode);

    // Generate session ID
    final sessionId = DateTime.now().millisecondsSinceEpoch.toString();
    setSessionContext(
      sessionId,
      sessionMetadata: {'start_time': DateTime.now().toIso8601String()},
    );
  }
}

/// Convenience methods for quick logging
extension QuickLogging on LoggingService {
  void logCacheHit(String cacheKey, {int? responseTimeMs}) {
    AppLoggers.cache.hit(cacheKey, responseTimeMs: responseTimeMs);
  }

  void logCacheMiss(String cacheKey, {String? reason}) {
    AppLoggers.cache.miss(cacheKey, reason: reason);
  }

  void logNetworkCall(
    String method,
    String url,
    int statusCode,
    int durationMs,
  ) {
    AppLoggers.network.response(
      method,
      url,
      statusCode,
      durationMs: durationMs,
    );
  }

  void logUserAction(
    String action, {
    String? screen,
    Map<String, dynamic>? context,
  }) {
    AppLoggers.ui.userAction(action, element: screen, context: context);
  }

  void logError(String message, dynamic error, {StackTrace? stackTrace}) {
    AppLoggers.error.exception(message, error, stackTrace: stackTrace);
  }

  void logPerformance(String operation, int durationMs) {
    AppLoggers.performance.operationTiming(operation, durationMs);
  }
}
