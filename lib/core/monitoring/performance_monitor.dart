import 'dart:collection';
import '../../utils/utils.dart';

/// Performance monitoring service for tracking app performance metrics
class PerformanceMonitor {
  static final PerformanceMonitor _instance = PerformanceMonitor._internal();
  factory PerformanceMonitor() => _instance;
  PerformanceMonitor._internal();

  // Cache metrics
  int _cacheHits = 0;
  int _cacheMisses = 0;
  final Map<String, int> _cacheHitsByType = {};
  final Map<String, int> _cacheMissesByType = {};

  // Repository performance metrics
  final Map<String, List<Duration>> _repositoryCallDurations = {};
  final Map<String, int> _repositoryCallCounts = {};
  final Map<String, int> _repositoryErrorCounts = {};

  // Network metrics
  int _networkCalls = 0;
  int _networkErrors = 0;
  final List<Duration> _networkCallDurations = [];

  // Memory usage tracking
  final Queue<MemorySnapshot> _memorySnapshots = Queue();
  static const int _maxMemorySnapshots = 100;

  /// Record a cache hit
  void recordCacheHit(String cacheType) {
    _cacheHits++;
    _cacheHitsByType[cacheType] = (_cacheHitsByType[cacheType] ?? 0) + 1;
    log.info('📊 Cache HIT: $cacheType (Total hits: $_cacheHits)');
  }

  /// Record a cache miss
  void recordCacheMiss(String cacheType) {
    _cacheMisses++;
    _cacheMissesByType[cacheType] = (_cacheMissesByType[cacheType] ?? 0) + 1;
    log.info('📊 Cache MISS: $cacheType (Total misses: $_cacheMisses)');
  }

  /// Record repository call performance
  void recordRepositoryCall(
    String repositoryMethod,
    Duration duration, {
    bool hasError = false,
  }) {
    _repositoryCallDurations
        .putIfAbsent(repositoryMethod, () => [])
        .add(duration);
    _repositoryCallCounts[repositoryMethod] =
        (_repositoryCallCounts[repositoryMethod] ?? 0) + 1;

    if (hasError) {
      _repositoryErrorCounts[repositoryMethod] =
          (_repositoryErrorCounts[repositoryMethod] ?? 0) + 1;
    }

    log.info(
      '📊 Repository call: $repositoryMethod took ${duration.inMilliseconds}ms ${hasError ? "(ERROR)" : ""}',
    );
  }

  /// Record network call
  void recordNetworkCall(Duration duration, {bool hasError = false}) {
    _networkCalls++;
    _networkCallDurations.add(duration);

    if (hasError) {
      _networkErrors++;
    }

    log.info(
      '📊 Network call took ${duration.inMilliseconds}ms ${hasError ? "(ERROR)" : ""}',
    );
  }

  /// Record memory snapshot
  void recordMemorySnapshot(int usedMemoryMB) {
    final snapshot = MemorySnapshot(
      timestamp: DateTime.now(),
      usedMemoryMB: usedMemoryMB,
    );

    _memorySnapshots.add(snapshot);

    // Keep only recent snapshots
    while (_memorySnapshots.length > _maxMemorySnapshots) {
      _memorySnapshots.removeFirst();
    }

    log.info('📊 Memory usage: ${usedMemoryMB}MB');
  }

  /// Get cache hit rate
  double get cacheHitRate {
    final total = _cacheHits + _cacheMisses;
    return total > 0 ? _cacheHits / total : 0.0;
  }

  /// Get cache hit rate by type
  double getCacheHitRateByType(String cacheType) {
    final hits = _cacheHitsByType[cacheType] ?? 0;
    final misses = _cacheMissesByType[cacheType] ?? 0;
    final total = hits + misses;
    return total > 0 ? hits / total : 0.0;
  }

  /// Get average repository call duration
  Duration getAverageRepositoryCallDuration(String repositoryMethod) {
    final durations = _repositoryCallDurations[repositoryMethod];
    if (durations == null || durations.isEmpty) return Duration.zero;

    final totalMs = durations.fold(
      0,
      (sum, duration) => sum + duration.inMilliseconds,
    );
    return Duration(milliseconds: totalMs ~/ durations.length);
  }

  /// Get repository error rate
  double getRepositoryErrorRate(String repositoryMethod) {
    final errors = _repositoryErrorCounts[repositoryMethod] ?? 0;
    final total = _repositoryCallCounts[repositoryMethod] ?? 0;
    return total > 0 ? errors / total : 0.0;
  }

  /// Get network error rate
  double get networkErrorRate {
    return _networkCalls > 0 ? _networkErrors / _networkCalls : 0.0;
  }

  /// Get average network call duration
  Duration get averageNetworkCallDuration {
    if (_networkCallDurations.isEmpty) return Duration.zero;

    final totalMs = _networkCallDurations.fold(
      0,
      (sum, duration) => sum + duration.inMilliseconds,
    );
    return Duration(milliseconds: totalMs ~/ _networkCallDurations.length);
  }

  /// Get performance summary
  PerformanceSummary getPerformanceSummary() {
    return PerformanceSummary(
      cacheHitRate: cacheHitRate,
      totalCacheHits: _cacheHits,
      totalCacheMisses: _cacheMisses,
      networkErrorRate: networkErrorRate,
      averageNetworkDuration: averageNetworkCallDuration,
      totalNetworkCalls: _networkCalls,
      repositoryMetrics:
          _repositoryCallCounts.keys
              .map(
                (method) => RepositoryMetric(
                  method: method,
                  callCount: _repositoryCallCounts[method] ?? 0,
                  averageDuration: getAverageRepositoryCallDuration(method),
                  errorRate: getRepositoryErrorRate(method),
                ),
              )
              .toList(),
      memoryUsageMB:
          _memorySnapshots.isNotEmpty ? _memorySnapshots.last.usedMemoryMB : 0,
    );
  }

  /// Log performance summary
  void logPerformanceSummary() {
    final summary = getPerformanceSummary();

    log.info('📊 === PERFORMANCE SUMMARY ===');
    log.info(
      '📊 Cache Hit Rate: ${(summary.cacheHitRate * 100).toStringAsFixed(1)}%',
    );
    log.info(
      '📊 Cache Hits: ${summary.totalCacheHits}, Misses: ${summary.totalCacheMisses}',
    );
    log.info(
      '📊 Network Error Rate: ${(summary.networkErrorRate * 100).toStringAsFixed(1)}%',
    );
    log.info(
      '📊 Average Network Duration: ${summary.averageNetworkDuration.inMilliseconds}ms',
    );
    log.info('📊 Total Network Calls: ${summary.totalNetworkCalls}');
    log.info('📊 Memory Usage: ${summary.memoryUsageMB}MB');

    for (final metric in summary.repositoryMetrics) {
      log.info(
        '📊 ${metric.method}: ${metric.callCount} calls, ${metric.averageDuration.inMilliseconds}ms avg, ${(metric.errorRate * 100).toStringAsFixed(1)}% errors',
      );
    }
    log.info('📊 === END SUMMARY ===');
  }

  /// Reset all metrics
  void reset() {
    _cacheHits = 0;
    _cacheMisses = 0;
    _cacheHitsByType.clear();
    _cacheMissesByType.clear();
    _repositoryCallDurations.clear();
    _repositoryCallCounts.clear();
    _repositoryErrorCounts.clear();
    _networkCalls = 0;
    _networkErrors = 0;
    _networkCallDurations.clear();
    _memorySnapshots.clear();
    log.info('📊 Performance metrics reset');
  }
}

class MemorySnapshot {
  final DateTime timestamp;
  final int usedMemoryMB;

  MemorySnapshot({required this.timestamp, required this.usedMemoryMB});
}

class PerformanceSummary {
  final double cacheHitRate;
  final int totalCacheHits;
  final int totalCacheMisses;
  final double networkErrorRate;
  final Duration averageNetworkDuration;
  final int totalNetworkCalls;
  final List<RepositoryMetric> repositoryMetrics;
  final int memoryUsageMB;

  PerformanceSummary({
    required this.cacheHitRate,
    required this.totalCacheHits,
    required this.totalCacheMisses,
    required this.networkErrorRate,
    required this.averageNetworkDuration,
    required this.totalNetworkCalls,
    required this.repositoryMetrics,
    required this.memoryUsageMB,
  });
}

class RepositoryMetric {
  final String method;
  final int callCount;
  final Duration averageDuration;
  final double errorRate;

  RepositoryMetric({
    required this.method,
    required this.callCount,
    required this.averageDuration,
    required this.errorRate,
  });
}
