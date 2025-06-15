import 'dart:async';
import 'cache_manager.dart';
import 'cached_repository.dart';
import 'cache_keys.dart';
import '../di/service_locator.dart';
import '../repositories/user_repository.dart';
import '../repositories/jazz_standards_repository.dart';
import '../repositories/cached_user_repository.dart';
import '../repositories/cached_jazz_standards_repository.dart';
import '../logging/app_loggers.dart';

/// Service responsible for initializing and warming up caches during app startup
class CacheInitializationService {
  final CacheManager _cacheManager;
  late final CacheWarmer _cacheWarmer;

  CacheInitializationService(this._cacheManager) {
    _cacheWarmer = CacheWarmer(_cacheManager);
    _setupCacheWarmingTasks();
  }

  /// Initialize the cache system and warm critical data
  Future<void> initializeCache({
    CacheWarmingStrategy strategy = CacheWarmingStrategy.eager,
    String? userId,
  }) async {
    try {
      // Initialize cache manager
      await _cacheManager.initialize();

      // Clean up any expired entries
      await _cleanupExpiredEntries();

      // Warm up critical caches
      await _cacheWarmer.warmCache(strategy: strategy);

      // If user is logged in, preload user-specific data
      if (userId != null) {
        await _preloadUserSpecificData(userId);
      }

      AppLoggers.cache.info(
        'Cache system initialized',
        metadata: {'strategy': strategy.name, 'user_id': userId},
      );
      _logCacheStats();
    } catch (e, stackTrace) {
      AppLoggers.error.error(
        'Cache system initialization failed',
        error: e.toString(),
        stackTrace: stackTrace.toString(),
      );
      rethrow;
    }
  }

  /// Setup cache warming tasks for different data types
  void _setupCacheWarmingTasks() {
    // Critical data - load immediately
    _cacheWarmer.addTask(
      CacheWarmingTask(
        name: 'Jazz Standards',
        priority: CachePriority.critical,
        execute: () async {
          final repo =
              ServiceLocator.get<JazzStandardsRepository>()
                  as CachedJazzStandardsRepository;
          await repo.preloadJazzStandards();
        },
      ),
    );

    // App configuration - load immediately
    _cacheWarmer.addTask(
      CacheWarmingTask(
        name: 'App Config',
        priority: CachePriority.critical,
        execute: () async {
          await _preloadAppConfig();
        },
      ),
    );

    // Performance metrics - load in background
    _cacheWarmer.addTask(
      CacheWarmingTask(
        name: 'Performance Metrics',
        priority: CachePriority.low,
        execute: () async {
          await _preloadPerformanceMetrics();
        },
      ),
    );
  }

  /// Preload user-specific data when user logs in
  Future<void> preloadUserData(String userId) async {
    try {
      final userRepo =
          ServiceLocator.get<UserRepository>() as CachedUserRepository;
      await userRepo.preloadUserData(userId);

      AppLoggers.cache.info(
        'User-specific data preloaded',
        metadata: {'user_id': userId},
      );
    } catch (e) {
      AppLoggers.cache.warning(
        'Failed to preload user data',
        metadata: {'error': e.toString()},
      );
    }
  }

  /// Clear all caches (useful for logout or data refresh)
  Future<void> clearAllCaches() async {
    try {
      await _cacheManager.clear();
      AppLoggers.cache.info('All caches cleared');
    } catch (e) {
      AppLoggers.cache.warning(
        'Failed to clear caches',
        metadata: {'error': e.toString()},
      );
    }
  }

  /// Clear user-specific caches (useful for user switching)
  Future<void> clearUserCaches(String userId) async {
    try {
      final userKeys = CacheKeys.getUserRelatedKeys(userId);
      for (final key in userKeys) {
        await _cacheManager.remove(key);
      }

      // Also clear session-related patterns
      await _cacheManager.clear(pattern: 'user_sessions_$userId');
      await _cacheManager.clear(pattern: 'session_${userId}_');

      AppLoggers.cache.info(
        'User caches cleared',
        metadata: {'user_id': userId},
      );
    } catch (e) {
      AppLoggers.cache.warning(
        'Failed to clear user caches',
        metadata: {'user_id': userId, 'error': e.toString()},
      );
    }
  }

  /// Get comprehensive cache statistics
  Map<String, dynamic> getCacheStatistics() {
    final stats = _cacheManager.stats;

    return {
      'requests': stats.requests,
      'hits': stats.totalHits,
      'misses': stats.misses,
      'hitRate': (stats.hitRate * 100).toStringAsFixed(1),
      'memoryHits': stats.memoryHits,
      'persistentHits': stats.persistentHits,
      'memoryHitRate': (stats.memoryHitRate * 100).toStringAsFixed(1),
    };
  }

  /// Monitor cache performance and log warnings if needed
  void monitorCachePerformance() {
    final stats = _cacheManager.stats;

    if (stats.requests > 100) {
      // Only monitor after sufficient requests
      if (stats.hitRate < 0.7) {
        // Less than 70% hit rate
        AppLoggers.performance.warning(
          'Low cache hit rate detected',
          metadata: {
            'hit_rate': (stats.hitRate * 100).toStringAsFixed(1),
            'requests': stats.requests,
            'hits': stats.totalHits,
            'misses': stats.misses,
          },
        );
      }

      if (stats.memoryHitRate < 0.3) {
        // Less than 30% memory hits
        AppLoggers.performance.warning(
          'Low memory cache hit rate detected',
          metadata: {
            'memory_hit_rate': (stats.memoryHitRate * 100).toStringAsFixed(1),
            'memory_hits': stats.memoryHits,
            'persistent_hits': stats.persistentHits,
          },
        );
      }
    }
  }

  /// Schedule periodic cache maintenance
  void schedulePeriodicMaintenance() {
    Timer.periodic(const Duration(hours: 1), (timer) {
      _performMaintenance();
    });
  }

  // Private methods

  Future<void> _preloadUserSpecificData(String userId) async {
    try {
      final userRepo =
          ServiceLocator.get<UserRepository>() as CachedUserRepository;
      await userRepo.preloadUserData(userId);
    } catch (e) {
      AppLoggers.cache.warning(
        'Failed to preload user data',
        metadata: {'error': e.toString()},
      );
    }
  }

  Future<void> _preloadAppConfig() async {
    try {
      // Preload app configuration data
      await _cacheManager.set(CacheKeys.appConfig, {
        'version': '1.0.0',
        'lastUpdated': DateTime.now().toIso8601String(),
      }, ttl: CacheTTL.appConfig);
    } catch (e) {
      AppLoggers.cache.warning(
        'Failed to preload app config',
        metadata: {'error': e.toString()},
      );
    }
  }

  Future<void> _preloadPerformanceMetrics() async {
    try {
      // You can add logic here to cache performance metrics
      await _cacheManager.set(CacheKeys.performanceMetrics, {
        'initialized': true,
        'timestamp': DateTime.now().toIso8601String(),
      }, ttl: CacheTTL.performanceMetrics);
    } catch (e) {
      AppLoggers.cache.warning(
        'Failed to preload performance metrics',
        metadata: {'error': e.toString()},
      );
    }
  }

  Future<void> _cleanupExpiredEntries() async {
    try {
      // The cache manager handles this internally during initialization
    } catch (e) {
      AppLoggers.cache.warning(
        'Failed to cleanup expired entries',
        metadata: {'error': e.toString()},
      );
    }
  }

  void _logCacheStats() {
    final stats = getCacheStatistics();
    AppLoggers.performance.debug('Cache statistics', metadata: stats);
  }

  Future<void> _performMaintenance() async {
    try {
      // Monitor performance
      monitorCachePerformance();

      // Log current statistics
      _logCacheStats();
    } catch (e) {
      AppLoggers.cache.warning(
        'Cache maintenance failed',
        metadata: {'error': e.toString()},
      );
    }
  }
}

/// Factory for creating cache initialization service
class CacheInitializationServiceFactory {
  static CacheInitializationService create() {
    final cacheManager = ServiceLocator.get<CacheManager>();
    return CacheInitializationService(cacheManager);
  }
}
