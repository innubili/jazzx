/// Centralized cache key management for consistency and easy maintenance
class CacheKeys {
  // User-related cache keys
  static String userProfile(String userId) => 'user_profile_$userId';
  static String userSessions(String userId, {int? pageSize, String? startAfter}) {
    final suffix = pageSize != null || startAfter != null 
        ? '_${pageSize ?? 20}_${startAfter ?? 'initial'}'
        : '';
    return 'user_sessions_$userId$suffix';
  }
  static String userStatistics(String userId) => 'user_statistics_$userId';
  static String userPreferences(String userId) => 'user_preferences_$userId';
  static String userSongs(String userId) => 'user_songs_$userId';

  // Jazz standards cache keys
  static const String jazzStandards = 'jazz_standards_all';
  static String jazzStandardByTitle(String title) => 'jazz_standard_${title.toLowerCase().replaceAll(' ', '_')}';
  static String jazzStandardsSearch(String query) => 'jazz_standards_search_${query.toLowerCase()}';

  // Search-related cache keys
  static String youtubeSearch(String query, String category) => 'youtube_search_${category}_$query';
  static String spotifySearch(String query, String category) => 'spotify_search_${category}_$query';
  static String googleSearch(String query, String category) => 'google_search_${category}_$query';

  // Session-related cache keys
  static String singleSession(String userId, String sessionId) => 'session_${userId}_$sessionId';
  static String sessionSummary(String userId, String sessionId) => 'session_summary_${userId}_$sessionId';

  // Performance and monitoring
  static const String performanceMetrics = 'performance_metrics';
  static const String cacheStatistics = 'cache_statistics';

  // App-level cache keys
  static const String appConfig = 'app_config';
  static const String lastSyncTime = 'last_sync_time';
  static const String offlineQueue = 'offline_queue';

  // Utility methods for cache key patterns
  static List<String> getUserRelatedKeys(String userId) {
    return [
      userProfile(userId),
      userStatistics(userId),
      userPreferences(userId),
      userSongs(userId),
    ];
  }

  static List<String> getSearchRelatedKeys() {
    return [
      'youtube_search_',
      'spotify_search_',
      'google_search_',
      'jazz_standards_search_',
    ];
  }

  /// Generate a cache key with timestamp for versioning
  static String withTimestamp(String baseKey) {
    return '${baseKey}_${DateTime.now().millisecondsSinceEpoch}';
  }

  /// Generate a cache key with hash for complex objects
  static String withHash(String baseKey, Object data) {
    return '${baseKey}_${data.hashCode}';
  }
}

/// Cache TTL (Time To Live) configurations for different data types
class CacheTTL {
  // User data - medium duration (user data changes occasionally)
  static const Duration userProfile = Duration(hours: 2);
  static const Duration userPreferences = Duration(hours: 6);
  static const Duration userStatistics = Duration(hours: 1);

  // Session data - short to medium duration
  static const Duration userSessions = Duration(minutes: 30);
  static const Duration singleSession = Duration(hours: 24);
  static const Duration sessionSummary = Duration(hours: 12);

  // Jazz standards - long duration (rarely changes)
  static const Duration jazzStandards = Duration(days: 7);
  static const Duration jazzStandardSearch = Duration(hours: 6);

  // Search results - short duration (results can change frequently)
  static const Duration searchResults = Duration(minutes: 15);
  static const Duration youtubeSearch = Duration(minutes: 30);
  static const Duration spotifySearch = Duration(minutes: 30);

  // App configuration - very long duration
  static const Duration appConfig = Duration(days: 30);
  static const Duration performanceMetrics = Duration(hours: 1);

  // Offline support
  static const Duration offlineQueue = Duration(days: 7);
  static const Duration lastSyncTime = Duration(days: 30);
}

/// Cache priority levels for memory management
enum CachePriority {
  critical,  // Never evict (user profile, preferences)
  high,      // Evict only when necessary (jazz standards, current session)
  medium,    // Evict when memory pressure (search results, session history)
  low,       // Evict first (temporary data, previews)
}

/// Cache configuration for different data types
class CacheConfig {
  final Duration ttl;
  final CachePriority priority;
  final bool persistToDisk;
  final bool preloadOnStartup;

  const CacheConfig({
    required this.ttl,
    this.priority = CachePriority.medium,
    this.persistToDisk = true,
    this.preloadOnStartup = false,
  });

  // Predefined configurations
  static const CacheConfig userProfile = CacheConfig(
    ttl: CacheTTL.userProfile,
    priority: CachePriority.critical,
    persistToDisk: true,
    preloadOnStartup: true,
  );

  static const CacheConfig jazzStandards = CacheConfig(
    ttl: CacheTTL.jazzStandards,
    priority: CachePriority.high,
    persistToDisk: true,
    preloadOnStartup: true,
  );

  static const CacheConfig searchResults = CacheConfig(
    ttl: CacheTTL.searchResults,
    priority: CachePriority.low,
    persistToDisk: false,
    preloadOnStartup: false,
  );

  static const CacheConfig sessionData = CacheConfig(
    ttl: CacheTTL.userSessions,
    priority: CachePriority.medium,
    persistToDisk: true,
    preloadOnStartup: false,
  );
}
