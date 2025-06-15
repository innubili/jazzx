import 'dart:async';
import '../errors/failures.dart';
import 'cache_manager.dart';
import 'cache_keys.dart';
import '../../utils/utils.dart';

/// Generic cached repository wrapper that adds caching to any repository
class CachedRepository {
  final CacheManager _cacheManager;
  final String _repositoryName;

  CachedRepository(this._cacheManager, this._repositoryName);

  /// Execute a repository operation with caching
  Future<Result<R>> execute<R>({
    required String cacheKey,
    required Future<Result<R>> Function() operation,
    Duration? ttl,
    CacheStrategy strategy = CacheStrategy.hybrid,
    R Function(Map<String, dynamic>)? fromJson,
    Map<String, dynamic> Function(R)? toJson,
    bool forceRefresh = false,
  }) async {
    // Check cache first (unless force refresh)
    if (!forceRefresh) {
      final cached = await _cacheManager.get<R>(
        cacheKey,
        ttl: ttl,
        fromJson: fromJson,
      );

      if (cached != null) {
        log.info('🎯 Cache hit for $_repositoryName: $cacheKey');
        return Success(cached);
      }
    }

    // Execute the actual operation
    log.info(
      '🔄 Cache miss for $_repositoryName: $cacheKey, executing operation...',
    );
    final result = await operation();

    // Cache the result if successful
    if (result.isSuccess) {
      final data = result.data;
      if (data != null) {
        await _cacheManager.set(
          cacheKey,
          data,
          ttl: ttl,
          strategy: strategy,
          toJson: toJson,
        );
        log.info('💾 Cached result for $_repositoryName: $cacheKey');
      }
    }

    return result;
  }

  /// Execute a list operation with caching
  Future<Result<List<T>>> executeList<T>({
    required String cacheKey,
    required Future<Result<List<T>>> Function() operation,
    Duration? ttl,
    CacheStrategy strategy = CacheStrategy.hybrid,
    T Function(Map<String, dynamic>)? fromJson,
    Map<String, dynamic> Function(T)? toJson,
    bool forceRefresh = false,
  }) async {
    // Check cache first (unless force refresh)
    if (!forceRefresh) {
      final cached = await _cacheManager.get<List<dynamic>>(cacheKey, ttl: ttl);

      if (cached != null && fromJson != null) {
        try {
          final typedList =
              cached
                  .cast<Map<String, dynamic>>()
                  .map((item) => fromJson(item))
                  .toList();
          log.info('🎯 Cache hit for $_repositoryName list: $cacheKey');
          return Success(typedList);
        } catch (e) {
          log.warning('Failed to deserialize cached list for $cacheKey: $e');
          await _cacheManager.remove(cacheKey);
        }
      } else if (cached != null) {
        log.info('🎯 Cache hit for $_repositoryName list: $cacheKey');
        return Success(cached.cast<T>());
      }
    }

    // Execute the actual operation
    log.info(
      '🔄 Cache miss for $_repositoryName list: $cacheKey, executing operation...',
    );
    final result = await operation();

    // Cache the result if successful
    if (result.isSuccess) {
      final data = result.data;
      if (data != null) {
        List<dynamic> cacheData;
        if (toJson != null) {
          cacheData = data.map((item) => toJson(item)).toList();
        } else {
          cacheData = data;
        }

        await _cacheManager.set(
          cacheKey,
          cacheData,
          ttl: ttl,
          strategy: strategy,
        );
        log.info('💾 Cached list result for $_repositoryName: $cacheKey');
      }
    }

    return result;
  }

  /// Invalidate cache for specific keys or patterns
  Future<void> invalidateCache({String? pattern, List<String>? keys}) async {
    if (keys != null) {
      for (final key in keys) {
        await _cacheManager.remove(key);
        log.info('🗑️ Invalidated cache for $_repositoryName: $key');
      }
    } else if (pattern != null) {
      await _cacheManager.clear(pattern: pattern);
      log.info('🗑️ Invalidated cache pattern for $_repositoryName: $pattern');
    }
  }

  /// Preload data into cache
  Future<void> preloadCache<R>({
    required String cacheKey,
    required Future<Result<R>> Function() operation,
    Duration? ttl,
    CacheStrategy strategy = CacheStrategy.hybrid,
    Map<String, dynamic> Function(R)? toJson,
  }) async {
    log.info('🔥 Preloading cache for $_repositoryName: $cacheKey');

    final result = await operation();
    if (result.isSuccess) {
      final data = result.data;
      if (data != null) {
        await _cacheManager.set(
          cacheKey,
          data,
          ttl: ttl,
          strategy: strategy,
          toJson: toJson,
        );
        log.info('✅ Preloaded cache for $_repositoryName: $cacheKey');
      } else {
        log.warning(
          '❌ Failed to preload cache for $_repositoryName: $cacheKey (data is null)',
        );
      }
    } else {
      log.warning('❌ Failed to preload cache for $_repositoryName: $cacheKey');
    }
  }
}

/// Mixin for repositories to easily add caching capabilities
mixin CacheableMixin {
  late final CachedRepository _cachedRepo;

  void initializeCache(CacheManager cacheManager, String repositoryName) {
    _cachedRepo = CachedRepository(cacheManager, repositoryName);
  }

  CachedRepository get cache => _cachedRepo;
}

/// Cache warming strategies
enum CacheWarmingStrategy {
  eager, // Load all critical data immediately
  lazy, // Load data as needed
  scheduled, // Load data at specific times
  background, // Load data in background
}

/// Cache warming manager
class CacheWarmer {
  final CacheManager _cacheManager;
  final List<CacheWarmingTask> _tasks = [];

  CacheWarmer(this._cacheManager);

  void addTask(CacheWarmingTask task) {
    _tasks.add(task);
  }

  /// Get the cache manager (for internal use)
  CacheManager get cacheManager => _cacheManager;

  Future<void> warmCache({
    CacheWarmingStrategy strategy = CacheWarmingStrategy.eager,
  }) async {
    log.info('🔥 Starting cache warming with strategy: $strategy');

    switch (strategy) {
      case CacheWarmingStrategy.eager:
        await _warmEager();
        break;
      case CacheWarmingStrategy.lazy:
        // No immediate action needed
        break;
      case CacheWarmingStrategy.scheduled:
        await _warmScheduled();
        break;
      case CacheWarmingStrategy.background:
        unawaited(_warmBackground());
        break;
    }
  }

  Future<void> _warmEager() async {
    final criticalTasks = _tasks.where(
      (task) => task.priority == CachePriority.critical,
    );
    await Future.wait(criticalTasks.map((task) => task.execute()));
  }

  Future<void> _warmScheduled() async {
    // Implement scheduled warming logic
    final now = DateTime.now();
    final tasksToRun = _tasks.where(
      (task) => task.shouldRunAt != null && now.isAfter(task.shouldRunAt!),
    );

    await Future.wait(tasksToRun.map((task) => task.execute()));
  }

  Future<void> _warmBackground() async {
    // Run all tasks in background with delays to avoid blocking
    for (final task in _tasks) {
      await task.execute();
      await Future.delayed(const Duration(milliseconds: 100)); // Small delay
    }
  }
}

/// Individual cache warming task
class CacheWarmingTask {
  final String name;
  final Future<void> Function() execute;
  final CachePriority priority;
  final DateTime? shouldRunAt;

  CacheWarmingTask({
    required this.name,
    required this.execute,
    this.priority = CachePriority.medium,
    this.shouldRunAt,
  });
}
