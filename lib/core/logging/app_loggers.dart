import 'structured_logger.dart';

/// Convenient logger classes for different app components
class AppLoggers {
  /// Cache-related logging
  static final cache = CacheLogger._();

  /// Network-related logging
  static final network = NetworkLogger._();

  /// Authentication-related logging
  static final auth = AuthLogger._();

  /// Performance-related logging
  static final performance = PerformanceLogger._();

  /// UI-related logging
  static final ui = UILogger._();

  /// Database-related logging
  static final database = DatabaseLogger._();

  /// Error logging
  static final error = ErrorLogger._();

  /// Analytics logging
  static final analytics = AnalyticsLogger._();

  /// System logging
  static final system = SystemLogger._();
}

/// Base logger class with common functionality
abstract class BaseLogger {
  final LogCategory category;
  final String component;

  const BaseLogger(this.category, this.component);

  void trace(String message, {Map<String, dynamic>? metadata}) {
    StructuredLogger().log(
      LogLevel.trace,
      category,
      message,
      component: component,
      metadata: metadata,
    );
  }

  void debug(String message, {Map<String, dynamic>? metadata}) {
    StructuredLogger().log(
      LogLevel.debug,
      category,
      message,
      component: component,
      metadata: metadata,
    );
  }

  void info(String message, {Map<String, dynamic>? metadata}) {
    StructuredLogger().log(
      LogLevel.info,
      category,
      message,
      component: component,
      metadata: metadata,
    );
  }

  void warning(String message, {Map<String, dynamic>? metadata}) {
    StructuredLogger().log(
      LogLevel.warning,
      category,
      message,
      component: component,
      metadata: metadata,
    );
  }

  void error(
    String message, {
    Map<String, dynamic>? metadata,
    String? error,
    String? stackTrace,
  }) {
    StructuredLogger().log(
      LogLevel.error,
      category,
      message,
      component: component,
      metadata: metadata,
      error: error,
      stackTrace: stackTrace,
    );
  }

  void fatal(
    String message, {
    Map<String, dynamic>? metadata,
    String? error,
    String? stackTrace,
  }) {
    StructuredLogger().log(
      LogLevel.fatal,
      category,
      message,
      component: component,
      metadata: metadata,
      error: error,
      stackTrace: stackTrace,
    );
  }
}

/// Cache-specific logger
class CacheLogger extends BaseLogger {
  const CacheLogger._() : super(LogCategory.cache, 'Cache');

  void hit(String cacheKey, {int? responseTimeMs, String? cacheType}) {
    info(
      'Cache hit',
      metadata: {
        'cache_key': cacheKey,
        'cache_type': cacheType,
        'response_time_ms': responseTimeMs,
        'operation': 'hit',
      },
    );
  }

  void miss(String cacheKey, {String? cacheType, String? reason}) {
    info(
      'Cache miss',
      metadata: {
        'cache_key': cacheKey,
        'cache_type': cacheType,
        'reason': reason,
        'operation': 'miss',
      },
    );
  }

  void eviction(String cacheKey, {String? reason, int? itemCount}) {
    info(
      'Cache eviction',
      metadata: {
        'cache_key': cacheKey,
        'reason': reason,
        'item_count': itemCount,
        'operation': 'eviction',
      },
    );
  }

  void clear({String? cacheType, int? itemCount}) {
    info(
      'Cache cleared',
      metadata: {
        'cache_type': cacheType,
        'item_count': itemCount,
        'operation': 'clear',
      },
    );
  }

  void preload(String cacheKey, {int? itemCount, int? durationMs}) {
    info(
      'Cache preload',
      metadata: {
        'cache_key': cacheKey,
        'item_count': itemCount,
        'duration_ms': durationMs,
        'operation': 'preload',
      },
    );
  }
}

/// Network-specific logger
class NetworkLogger extends BaseLogger {
  const NetworkLogger._() : super(LogCategory.network, 'Network');

  void request(String method, String url, {Map<String, dynamic>? headers}) {
    debug(
      'Network request',
      metadata: {
        'method': method,
        'url': url,
        'headers': headers,
        'operation': 'request',
      },
    );
  }

  void response(
    String method,
    String url,
    int statusCode, {
    int? durationMs,
    int? responseSize,
  }) {
    info(
      'Network response',
      metadata: {
        'method': method,
        'url': url,
        'status_code': statusCode,
        'duration_ms': durationMs,
        'response_size_bytes': responseSize,
        'operation': 'response',
      },
    );
  }

  void timeout(String method, String url, {int? timeoutMs}) {
    warning(
      'Network timeout',
      metadata: {
        'method': method,
        'url': url,
        'timeout_ms': timeoutMs,
        'operation': 'timeout',
      },
    );
  }

  void retry(String method, String url, int attemptNumber, {String? reason}) {
    warning(
      'Network retry',
      metadata: {
        'method': method,
        'url': url,
        'attempt': attemptNumber,
        'reason': reason,
        'operation': 'retry',
      },
    );
  }
}

/// Authentication-specific logger
class AuthLogger extends BaseLogger {
  const AuthLogger._() : super(LogCategory.auth, 'Auth');

  void login(String method, {bool success = true, String? error}) {
    if (success) {
      info(
        'User login successful',
        metadata: {'method': method, 'operation': 'login', 'success': true},
      );
    } else {
      warning(
        'User login failed',
        metadata: {
          'method': method,
          'operation': 'login',
          'success': false,
          'error': error,
        },
      );
    }
  }

  void logout({String? reason}) {
    info('User logout', metadata: {'operation': 'logout', 'reason': reason});
  }

  void tokenRefresh({bool success = true, String? error}) {
    if (success) {
      debug(
        'Token refresh successful',
        metadata: {'operation': 'token_refresh', 'success': true},
      );
    } else {
      this.error(
        'Token refresh failed',
        metadata: {'operation': 'token_refresh', 'success': false},
        error: error,
      );
    }
  }
}

/// Performance-specific logger
class PerformanceLogger extends BaseLogger {
  const PerformanceLogger._() : super(LogCategory.performance, 'Performance');

  void operationTiming(
    String operation,
    int durationMs, {
    Map<String, dynamic>? details,
  }) {
    info(
      'Operation timing',
      metadata: {
        'operation': operation,
        'duration_ms': durationMs,
        'type': 'timing',
        ...?details,
      },
    );
  }

  void memoryUsage(int usedMemoryMB, {int? totalMemoryMB}) {
    debug(
      'Memory usage',
      metadata: {
        'used_memory_mb': usedMemoryMB,
        'total_memory_mb': totalMemoryMB,
        'type': 'memory',
      },
    );
  }

  void frameRate(double fps, {int? droppedFrames}) {
    debug(
      'Frame rate',
      metadata: {
        'fps': fps,
        'dropped_frames': droppedFrames,
        'type': 'frame_rate',
      },
    );
  }

  void slowOperation(String operation, int durationMs, {int? threshold}) {
    warning(
      'Slow operation detected',
      metadata: {
        'operation': operation,
        'duration_ms': durationMs,
        'threshold_ms': threshold,
        'type': 'slow_operation',
      },
    );
  }
}

/// UI-specific logger
class UILogger extends BaseLogger {
  const UILogger._() : super(LogCategory.ui, 'UI');

  void screenView(String screenName, {Map<String, dynamic>? parameters}) {
    info(
      'Screen view',
      metadata: {
        'screen_name': screenName,
        'parameters': parameters,
        'operation': 'screen_view',
      },
    );
  }

  void userAction(
    String action, {
    String? element,
    Map<String, dynamic>? context,
  }) {
    info(
      'User action',
      metadata: {
        'action': action,
        'element': element,
        'context': context,
        'operation': 'user_action',
      },
    );
  }

  void navigationEvent(String from, String to, {String? method}) {
    info(
      'Navigation',
      metadata: {
        'from': from,
        'to': to,
        'method': method,
        'operation': 'navigation',
      },
    );
  }
}

/// Database-specific logger
class DatabaseLogger extends BaseLogger {
  const DatabaseLogger._() : super(LogCategory.database, 'Database');

  void query(
    String operation,
    String collection, {
    int? durationMs,
    int? resultCount,
  }) {
    debug(
      'Database query',
      metadata: {
        'operation': operation,
        'collection': collection,
        'duration_ms': durationMs,
        'result_count': resultCount,
      },
    );
  }

  void transaction(String operation, {bool success = true, int? durationMs}) {
    info(
      'Database transaction',
      metadata: {
        'operation': operation,
        'success': success,
        'duration_ms': durationMs,
      },
    );
  }
}

/// Error-specific logger
class ErrorLogger extends BaseLogger {
  const ErrorLogger._() : super(LogCategory.error, 'Error');

  void exception(
    String message,
    dynamic exception, {
    StackTrace? stackTrace,
    Map<String, dynamic>? context,
  }) {
    error(
      'Exception occurred',
      metadata: {
        'exception_type': exception.runtimeType.toString(),
        'context': context,
      },
      error: exception.toString(),
      stackTrace: stackTrace?.toString(),
    );
  }

  void validation(String field, String message, {dynamic value}) {
    warning(
      'Validation error',
      metadata: {
        'field': field,
        'value': value?.toString(),
        'type': 'validation',
      },
    );
  }
}

/// Analytics-specific logger
class AnalyticsLogger extends BaseLogger {
  const AnalyticsLogger._() : super(LogCategory.analytics, 'Analytics');

  void event(String eventName, {Map<String, dynamic>? parameters}) {
    info(
      'Analytics event',
      metadata: {'event_name': eventName, 'parameters': parameters},
    );
  }

  void userProperty(String property, dynamic value) {
    debug('User property', metadata: {'property': property, 'value': value});
  }
}

/// System-specific logger
class SystemLogger extends BaseLogger {
  const SystemLogger._() : super(LogCategory.system, 'System');

  void startup({int? durationMs}) {
    info(
      'App startup',
      metadata: {'duration_ms': durationMs, 'operation': 'startup'},
    );
  }

  void shutdown({String? reason}) {
    info('App shutdown', metadata: {'reason': reason, 'operation': 'shutdown'});
  }

  void backgroundState(bool isBackground) {
    debug(
      'App state change',
      metadata: {'is_background': isBackground, 'operation': 'state_change'},
    );
  }
}
