import '../errors/failures.dart';
import '../cache/cache_manager.dart';
import '../cache/cached_repository.dart';
import '../cache/cache_keys.dart';
import '../../models/user_profile.dart';
import '../../models/session.dart';
import '../../models/song.dart';
import '../../models/statistics.dart';
import '../../models/preferences.dart';
import '../../services/firebase_service.dart';
import '../../utils/utils.dart';
import 'user_repository.dart';

/// Enhanced user repository with comprehensive caching
class CachedUserRepository implements UserRepository {
  final FirebaseService _firebaseService;
  final CacheManager _cacheManager;
  late final CachedRepository _cache;

  CachedUserRepository(this._firebaseService, this._cacheManager) {
    _cache = CachedRepository(_cacheManager, 'UserRepository');
  }

  /// Helper method to convert UserProfile to JSON
  Map<String, dynamic> _userProfileToJson(UserProfile profile) {
    return {
      'id': profile.id,
      'preferences': profile.preferences.toJson(),
      'sessions': {
        for (var entry in profile.sessions.entries)
          entry.key: entry.value.toJson(),
      },
      'songs': {
        for (var entry in profile.songs.entries)
          entry.key: entry.value.toJson(),
      },
      'statistics': profile.statistics.toJson(),
      'videos': {
        for (var entry in profile.videos.entries)
          entry.key: {
            'title': entry.value.title,
            'date': entry.value.date
                .toIso8601String()
                .substring(0, 10)
                .replaceAll('-', ''),
          },
      },
    };
  }

  @override
  Future<Result<UserProfile?>> getUserProfile(String userId) async {
    return await _cache.execute<UserProfile?>(
      cacheKey: CacheKeys.userProfile(userId),
      ttl: CacheTTL.userProfile,
      operation: () async {
        try {
          final profile = await _firebaseService.loadUserProfile();
          return Success(profile);
        } catch (e) {
          return Error(
            DatabaseFailure('Failed to load user profile: ${e.toString()}'),
          );
        }
      },
      fromJson: (json) => UserProfile.fromJson(userId, json),
      toJson: (profile) => profile != null ? _userProfileToJson(profile) : {},
    );
  }

  @override
  Future<Result<void>> saveUserProfile(UserProfile profile) async {
    final userId = profile.id;
    try {
      await _firebaseService.saveUserProfile(profile);

      // Update cache immediately
      await _cacheManager.set(
        CacheKeys.userProfile(userId),
        profile,
        ttl: CacheTTL.userProfile,
        toJson: (p) => _userProfileToJson(p),
      );

      // Invalidate related caches
      await _invalidateUserRelatedCaches(userId);

      return const Success(null);
    } catch (e) {
      return Error(
        DatabaseFailure('Failed to save user profile: ${e.toString()}'),
      );
    }
  }

  @override
  Future<Result<List<MapEntry<String, Session>>>> getUserSessions(
    String userId, {
    int? limit,
    String? startAfter,
  }) async {
    return await _cache.executeList<MapEntry<String, Session>>(
      cacheKey: CacheKeys.userSessions(
        userId,
        pageSize: limit,
        startAfter: startAfter,
      ),
      ttl: CacheTTL.userSessions,
      operation: () async {
        try {
          final entries = await _firebaseService.loadSessionsPage(
            pageSize: limit ?? 20,
            startAfterId: startAfter,
          );
          return Success(entries);
        } catch (e) {
          return Error(
            DatabaseFailure('Failed to load sessions: ${e.toString()}'),
          );
        }
      },
      fromJson: (json) {
        final sessionData = json['session'] as Map<String, dynamic>;
        final sessionId = json['id'] as String;
        return MapEntry(sessionId, Session.fromJson(sessionData));
      },
      toJson: (entry) => {'id': entry.key, 'session': entry.value.toJson()},
    );
  }

  @override
  Future<Result<void>> saveSession(
    String userId,
    String sessionId,
    Session session,
  ) async {
    try {
      await _firebaseService.saveSingleSession(userId, sessionId, session);

      // Update individual session cache
      await _cacheManager.set(
        CacheKeys.singleSession(userId, sessionId),
        session,
        ttl: CacheTTL.singleSession,
        toJson: (s) => s.toJson(),
      );

      // Invalidate sessions list cache to force refresh
      await _cacheManager.clear(pattern: 'user_sessions_$userId');

      // Invalidate statistics cache since session data changed
      await _cacheManager.remove(CacheKeys.userStatistics(userId));

      return const Success(null);
    } catch (e) {
      return Error(DatabaseFailure('Failed to save session: ${e.toString()}'));
    }
  }

  /// Get a single session with caching
  Future<Result<Session?>> getSingleSession(
    String userId,
    String sessionId,
  ) async {
    return await _cache.execute<Session?>(
      cacheKey: CacheKeys.singleSession(userId, sessionId),
      ttl: CacheTTL.singleSession,
      operation: () async {
        try {
          final session = await _firebaseService.loadSingleSession(sessionId);
          return Success(session);
        } catch (e) {
          return Error(
            DatabaseFailure('Failed to load session: ${e.toString()}'),
          );
        }
      },
      fromJson: (json) => Session.fromJson(json),
      toJson: (session) => session?.toJson() ?? {},
    );
  }

  /// Get user statistics with caching
  @override
  Future<Result<Statistics?>> getUserStatistics(String userId) async {
    return await _cache.execute<Statistics?>(
      cacheKey: CacheKeys.userStatistics(userId),
      ttl: CacheTTL.userStatistics,
      operation: () async {
        try {
          final stats = await _firebaseService.loadStatistics(userId);
          return Success(stats);
        } catch (e) {
          return Error(
            DatabaseFailure('Failed to load statistics: ${e.toString()}'),
          );
        }
      },
      fromJson: (json) => Statistics.fromJson(json),
      toJson: (stats) => stats?.toJson() ?? {},
    );
  }

  /// Save user statistics with cache update
  @override
  Future<Result<void>> saveStatistics(
    String userId,
    Statistics statistics,
  ) async {
    try {
      await _firebaseService.saveStatistics(statistics);

      // Update cache immediately
      await _cacheManager.set(
        CacheKeys.userStatistics(userId),
        statistics,
        ttl: CacheTTL.userStatistics,
        toJson: (s) => s.toJson(),
      );

      return const Success(null);
    } catch (e) {
      return Error(
        DatabaseFailure('Failed to save statistics: ${e.toString()}'),
      );
    }
  }

  @override
  Future<Result<void>> updateUserPreferences(
    String userId,
    ProfilePreferences preferences,
  ) async {
    try {
      await _firebaseService.savePreferences(preferences);

      // Update cache immediately
      await _cacheManager.set(
        CacheKeys.userPreferences(userId),
        preferences,
        ttl: CacheTTL.userPreferences,
        toJson: (p) => p.toJson(),
      );

      return const Success(null);
    } catch (e) {
      return Error(
        DatabaseFailure('Failed to update preferences: ${e.toString()}'),
      );
    }
  }

  @override
  Future<Result<void>> deleteSession(String userId, String sessionId) async {
    try {
      await _firebaseService.removeSingleSession(userId, sessionId);

      // Remove from cache
      await _cacheManager.remove(CacheKeys.singleSession(userId, sessionId));

      // Invalidate sessions list cache
      await _cacheManager.clear(pattern: 'user_sessions_$userId');

      return const Success(null);
    } catch (e) {
      return Error(
        DatabaseFailure('Failed to delete session: ${e.toString()}'),
      );
    }
  }

  @override
  Future<Result<Map<String, Song>>> getUserSongs(String userId) async {
    return await _cache.execute<Map<String, Song>>(
      cacheKey: CacheKeys.userSongs(userId),
      ttl: CacheTTL.userProfile, // Use same TTL as profile
      operation: () async {
        try {
          final profile = await _firebaseService.loadUserProfile();
          return Success(profile?.songs ?? {});
        } catch (e) {
          return Error(
            DatabaseFailure('Failed to load songs: ${e.toString()}'),
          );
        }
      },
      fromJson:
          (json) => {
            for (var entry in json.entries)
              entry.key: Song.fromJson(
                entry.key,
                Map<String, dynamic>.from(entry.value),
              ),
          },
      toJson:
          (songs) => {
            for (var entry in songs.entries) entry.key: entry.value.toJson(),
          },
    );
  }

  @override
  Future<Result<void>> saveSong(String userId, Song song) async {
    try {
      await _firebaseService.saveSong(userId, song);

      // Invalidate user songs cache
      await _cacheManager.remove(CacheKeys.userSongs(userId));

      return const Success(null);
    } catch (e) {
      return Error(DatabaseFailure('Failed to save song: ${e.toString()}'));
    }
  }

  /// Preload critical user data into cache
  Future<void> preloadUserData(String userId) async {
    log.info('🔥 Preloading user data for: $userId');

    final tasks = [
      _cache.preloadCache(
        cacheKey: CacheKeys.userProfile(userId),
        operation: () => getUserProfile(userId),
        ttl: CacheTTL.userProfile,
      ),
      _cache.preloadCache(
        cacheKey: CacheKeys.userStatistics(userId),
        operation: () => getUserStatistics(userId),
        ttl: CacheTTL.userStatistics,
      ),
      _cache.preloadCache(
        cacheKey: CacheKeys.userSessions(userId),
        operation: () => getUserSessions(userId, limit: 10),
        ttl: CacheTTL.userSessions,
      ),
    ];

    await Future.wait(tasks);
    log.info('✅ User data preloaded for: $userId');
  }

  /// Invalidate all user-related caches
  Future<void> _invalidateUserRelatedCaches(String userId) async {
    final keysToInvalidate = CacheKeys.getUserRelatedKeys(userId);
    await _cache.invalidateCache(keys: keysToInvalidate);

    // Also clear session-related patterns
    await _cacheManager.clear(pattern: 'user_sessions_$userId');
    await _cacheManager.clear(pattern: 'session_${userId}_');
  }

  /// Force refresh user data (bypass cache)
  Future<Result<UserProfile?>> refreshUserProfile(String userId) async {
    return await _cache.execute<UserProfile?>(
      cacheKey: CacheKeys.userProfile(userId),
      ttl: CacheTTL.userProfile,
      forceRefresh: true,
      operation: () async {
        try {
          final profile = await _firebaseService.loadUserProfile();
          return Success(profile);
        } catch (e) {
          return Error(
            DatabaseFailure('Failed to refresh user profile: ${e.toString()}'),
          );
        }
      },
      fromJson: (json) => UserProfile.fromJson(userId, json),
      toJson: (profile) => profile != null ? _userProfileToJson(profile) : {},
    );
  }

  /// Get cache statistics for this repository
  String getCacheStats() {
    return _cacheManager.stats.toString();
  }

  /// Clear all caches for this repository
  Future<void> clearAllCaches() async {
    await _cacheManager.clear();
    log.info('🗑️ All user repository caches cleared');
  }
}
