import 'package:collection/collection.dart';
import '../errors/failures.dart';
import '../cache/cache_manager.dart';
import '../cache/cached_repository.dart';
import '../cache/cache_keys.dart';
import '../../models/song.dart';
import '../../services/firebase_service.dart';
import '../monitoring/performance_monitor.dart';
import '../logging/app_loggers.dart';
import '../../utils/utils.dart';
import 'jazz_standards_repository.dart';

/// Enhanced jazz standards repository with comprehensive caching
class CachedJazzStandardsRepository implements JazzStandardsRepository {
  final FirebaseService _firebaseService;
  final CacheManager _cacheManager;
  final PerformanceMonitor _performanceMonitor;
  late final CachedRepository _cache;

  CachedJazzStandardsRepository(
    this._firebaseService,
    this._cacheManager,
    this._performanceMonitor,
  ) {
    _cache = CachedRepository(_cacheManager, 'JazzStandardsRepository');
  }

  @override
  Future<Result<List<Song>>> getJazzStandards() async {
    return await _cache.executeList<Song>(
      cacheKey: CacheKeys.jazzStandards,
      ttl: CacheTTL.jazzStandards,
      operation: () async {
        final stopwatch = Stopwatch()..start();
        try {
          _performanceMonitor.recordCacheMiss('jazz_standards');
          final standards = await _firebaseService.loadJazzStandards();

          stopwatch.stop();
          _performanceMonitor.recordRepositoryCall(
            'getJazzStandards',
            stopwatch.elapsed,
          );
          return Success(standards);
        } catch (e) {
          stopwatch.stop();
          _performanceMonitor.recordRepositoryCall(
            'getJazzStandards',
            stopwatch.elapsed,
            hasError: true,
          );
          return Error(
            DatabaseFailure('Failed to load jazz standards: ${e.toString()}'),
          );
        }
      },
      fromJson: (json) => Song.fromJson(json['title'] ?? '', json),
      toJson: (song) => {'title': song.title, ...song.toJson()},
    );
  }

  @override
  Future<Result<List<Song>>> searchJazzStandards(String query) async {
    // First check if we have a cached search result
    final searchCacheKey = CacheKeys.jazzStandardsSearch(query);

    return await _cache.executeList<Song>(
      cacheKey: searchCacheKey,
      ttl: CacheTTL.jazzStandardSearch,
      operation: () async {
        try {
          // Get all standards (this will use the main cache)
          final standardsResult = await getJazzStandards();
          if (standardsResult.isError) {
            return Error(standardsResult.failure!);
          }

          final standards = standardsResult.data!;
          final filteredStandards =
              standards.where((song) {
                final titleMatch = song.title.toLowerCase().contains(
                  query.toLowerCase(),
                );
                final composerMatch = song.songwriters.toLowerCase().contains(
                  query.toLowerCase(),
                );
                return titleMatch || composerMatch;
              }).toList();

          return Success(filteredStandards);
        } catch (e) {
          return Error(
            DatabaseFailure('Failed to search jazz standards: ${e.toString()}'),
          );
        }
      },
      fromJson: (json) => Song.fromJson(json['title'] ?? '', json),
      toJson: (song) => {'title': song.title, ...song.toJson()},
    );
  }

  @override
  Future<Result<Song?>> getJazzStandardByTitle(String title) async {
    // Check individual song cache first
    final songCacheKey = CacheKeys.jazzStandardByTitle(title);

    return await _cache.execute<Song?>(
      cacheKey: songCacheKey,
      ttl: CacheTTL.jazzStandards,
      operation: () async {
        try {
          // Get all standards and find the specific one
          final standardsResult = await getJazzStandards();
          if (standardsResult.isError) {
            return Error(standardsResult.failure!);
          }

          final standards = standardsResult.data!;
          final song =
              standards
                  .where((s) => s.title.toLowerCase() == title.toLowerCase())
                  .firstOrNull;

          return Success(song);
        } catch (e) {
          return Error(
            DatabaseFailure('Failed to get jazz standard: ${e.toString()}'),
          );
        }
      },
      fromJson:
          (json) =>
              json.isNotEmpty ? Song.fromJson(json['title'] ?? '', json) : null,
      toJson:
          (song) => song != null ? {'title': song.title, ...song.toJson()} : {},
    );
  }

  /// Preload jazz standards into cache
  Future<void> preloadJazzStandards() async {
    log.info('🔥 Preloading jazz standards...');
    AppLoggers.cache.info('Starting jazz standards preload');

    await _cache.preloadCache(
      cacheKey: CacheKeys.jazzStandards,
      operation: () => getJazzStandards(),
      ttl: CacheTTL.jazzStandards,
      strategy: CacheStrategy.hybrid,
    );

    log.info('✅ Jazz standards preloaded');
    AppLoggers.cache.info('Jazz standards preload completed');
  }

  /// Get popular jazz standards (cached subset)
  Future<Result<List<Song>>> getPopularJazzStandards({int limit = 50}) async {
    const popularCacheKey = 'jazz_standards_popular';

    return await _cache.executeList<Song>(
      cacheKey: popularCacheKey,
      ttl: CacheTTL.jazzStandards,
      operation: () async {
        try {
          final standardsResult = await getJazzStandards();
          if (standardsResult.isError) {
            return Error(standardsResult.failure!);
          }

          final standards = standardsResult.data!;
          // Sort by some popularity criteria (you can customize this)
          final popularStandards = standards.take(limit).toList();

          return Success(popularStandards);
        } catch (e) {
          return Error(
            DatabaseFailure(
              'Failed to get popular jazz standards: ${e.toString()}',
            ),
          );
        }
      },
      fromJson: (json) => Song.fromJson(json['title'] ?? '', json),
      toJson: (song) => {'title': song.title, ...song.toJson()},
    );
  }

  /// Search jazz standards by composer
  Future<Result<List<Song>>> searchByComposer(String composer) async {
    final composerCacheKey =
        'jazz_standards_composer_${composer.toLowerCase()}';

    return await _cache.executeList<Song>(
      cacheKey: composerCacheKey,
      ttl: CacheTTL.jazzStandardSearch,
      operation: () async {
        try {
          final standardsResult = await getJazzStandards();
          if (standardsResult.isError) {
            return Error(standardsResult.failure!);
          }

          final standards = standardsResult.data!;
          final composerStandards =
              standards.where((song) {
                return song.songwriters.toLowerCase().contains(
                  composer.toLowerCase(),
                );
              }).toList();

          return Success(composerStandards);
        } catch (e) {
          return Error(
            DatabaseFailure('Failed to search by composer: ${e.toString()}'),
          );
        }
      },
      fromJson: (json) => Song.fromJson(json['title'] ?? '', json),
      toJson: (song) => {'title': song.title, ...song.toJson()},
    );
  }

  /// Clear all jazz standards caches
  Future<void> clearCache() async {
    await _cacheManager.clear(pattern: 'jazz_standards');
    log.info('🗑️ Jazz standards cache cleared');
  }

  /// Force refresh jazz standards (bypass cache)
  Future<Result<List<Song>>> refreshJazzStandards() async {
    return await _cache.executeList<Song>(
      cacheKey: CacheKeys.jazzStandards,
      ttl: CacheTTL.jazzStandards,
      forceRefresh: true,
      operation: () async {
        final stopwatch = Stopwatch()..start();
        try {
          final standards = await _firebaseService.loadJazzStandards();

          stopwatch.stop();
          _performanceMonitor.recordRepositoryCall(
            'refreshJazzStandards',
            stopwatch.elapsed,
          );
          return Success(standards);
        } catch (e) {
          stopwatch.stop();
          _performanceMonitor.recordRepositoryCall(
            'refreshJazzStandards',
            stopwatch.elapsed,
            hasError: true,
          );
          return Error(
            DatabaseFailure(
              'Failed to refresh jazz standards: ${e.toString()}',
            ),
          );
        }
      },
      fromJson: (json) => Song.fromJson(json['title'] ?? '', json),
      toJson: (song) => {'title': song.title, ...song.toJson()},
    );
  }

  /// Get cache statistics
  String getCacheStats() {
    return _cacheManager.stats.toString();
  }

  /// Get cache hit rate for jazz standards
  double getJazzStandardsCacheHitRate() {
    return _cacheManager.stats.hitRate;
  }
}
