import 'dart:async';
import 'dart:convert';
import 'package:shared_preferences/shared_preferences.dart';
import '../../utils/utils.dart';

/// Unified cache manager with multiple cache layers and strategies
class CacheManager {
  static final CacheManager _instance = CacheManager._internal();
  factory CacheManager() => _instance;
  CacheManager._internal();

  // Memory cache (fastest, volatile)
  final Map<String, CacheEntry> _memoryCache = {};

  // Persistent cache (slower, survives app restarts)
  SharedPreferences? _prefs;

  // Cache statistics for monitoring
  final CacheStats _stats = CacheStats();

  // Cache configuration
  static const int _maxMemoryCacheSize = 50; // Max items in memory
  static const Duration _defaultTtl = Duration(hours: 1);

  /// Initialize the cache manager
  Future<void> initialize() async {
    _prefs = await SharedPreferences.getInstance();
    await _cleanExpiredEntries();
    log.info('🗄️ CacheManager initialized');
  }

  /// Get data from cache with automatic fallback strategy
  Future<T?> get<T>(
    String key, {
    Duration? ttl,
    bool persistentOnly = false,
    T Function(Map<String, dynamic>)? fromJson,
  }) async {
    _stats.recordRequest();

    // Try memory cache first (unless persistent only)
    if (!persistentOnly && _memoryCache.containsKey(key)) {
      final entry = _memoryCache[key]!;
      if (!entry.isExpired) {
        _stats.recordHit(CacheLayer.memory);
        return entry.data as T?;
      } else {
        _memoryCache.remove(key);
      }
    }

    // Try persistent cache
    final persistentData = await _getPersistent<T>(key, fromJson: fromJson);
    if (persistentData != null) {
      // Promote to memory cache for faster future access
      _setMemory(key, persistentData, ttl ?? _defaultTtl);
      _stats.recordHit(CacheLayer.persistent);
      return persistentData;
    }

    _stats.recordMiss();
    return null;
  }

  /// Set data in cache with automatic layer management
  Future<void> set<T>(
    String key,
    T data, {
    Duration? ttl,
    CacheStrategy strategy = CacheStrategy.hybrid,
    Map<String, dynamic> Function(T)? toJson,
  }) async {
    final effectiveTtl = ttl ?? _defaultTtl;

    switch (strategy) {
      case CacheStrategy.memoryOnly:
        _setMemory(key, data, effectiveTtl);
        break;
      case CacheStrategy.persistentOnly:
        await _setPersistent(key, data, effectiveTtl, toJson: toJson);
        break;
      case CacheStrategy.hybrid:
        _setMemory(key, data, effectiveTtl);
        await _setPersistent(key, data, effectiveTtl, toJson: toJson);
        break;
    }
  }

  /// Remove data from all cache layers
  Future<void> remove(String key) async {
    _memoryCache.remove(key);
    await _prefs?.remove('cache_$key');
    await _prefs?.remove('cache_meta_$key');
  }

  /// Clear cache by pattern or completely
  Future<void> clear({String? pattern}) async {
    if (pattern != null) {
      // Clear by pattern
      final keysToRemove =
          _memoryCache.keys.where((key) => key.contains(pattern)).toList();

      for (final key in keysToRemove) {
        await remove(key);
      }
    } else {
      // Clear everything
      _memoryCache.clear();
      final keys = _prefs?.getKeys() ?? <String>{};
      for (final key in keys) {
        if (key.startsWith('cache_')) {
          await _prefs?.remove(key);
        }
      }
    }
    log.info(
      '🗑️ Cache cleared${pattern != null ? ' (pattern: $pattern)' : ''}',
    );
  }

  /// Get cache statistics
  CacheStats get stats => _stats;

  /// Preload critical data into cache
  Future<void> preloadCriticalData() async {
    // This will be called during app startup to warm the cache
    log.info('🔥 Preloading critical data into cache...');
    // Implementation will be added when we integrate with repositories
  }

  // Private methods

  void _setMemory<T>(String key, T data, Duration ttl) {
    // Implement LRU eviction if cache is full
    if (_memoryCache.length >= _maxMemoryCacheSize) {
      _evictLeastRecentlyUsed();
    }

    _memoryCache[key] = CacheEntry(
      data: data,
      expiresAt: DateTime.now().add(ttl),
      lastAccessed: DateTime.now(),
    );
  }

  Future<void> _setPersistent<T>(
    String key,
    T data,
    Duration ttl, {
    Map<String, dynamic> Function(T)? toJson,
  }) async {
    if (_prefs == null) return;

    try {
      String jsonString;
      if (toJson != null) {
        jsonString = jsonEncode(toJson(data));
      } else if (data is Map<String, dynamic>) {
        jsonString = jsonEncode(data);
      } else if (data is List) {
        jsonString = jsonEncode(data);
      } else {
        jsonString = jsonEncode({'value': data});
      }

      await _prefs!.setString('cache_$key', jsonString);
      await _prefs!.setString(
        'cache_meta_$key',
        jsonEncode({
          'expiresAt': DateTime.now().add(ttl).millisecondsSinceEpoch,
          'createdAt': DateTime.now().millisecondsSinceEpoch,
        }),
      );
    } catch (e) {
      log.warning('Failed to set persistent cache for $key: $e');
    }
  }

  Future<T?> _getPersistent<T>(
    String key, {
    T Function(Map<String, dynamic>)? fromJson,
  }) async {
    if (_prefs == null) return null;

    try {
      final metaString = _prefs!.getString('cache_meta_$key');
      if (metaString == null) return null;

      final meta = jsonDecode(metaString) as Map<String, dynamic>;
      final expiresAt = DateTime.fromMillisecondsSinceEpoch(meta['expiresAt']);

      if (DateTime.now().isAfter(expiresAt)) {
        // Expired, clean up
        await remove(key);
        return null;
      }

      final dataString = _prefs!.getString('cache_$key');
      if (dataString == null) return null;

      final jsonData = jsonDecode(dataString);

      if (fromJson != null && jsonData is Map<String, dynamic>) {
        return fromJson(jsonData);
      } else if (jsonData is Map<String, dynamic> &&
          jsonData.containsKey('value')) {
        return jsonData['value'] as T;
      } else {
        return jsonData as T;
      }
    } catch (e) {
      log.warning('Failed to get persistent cache for $key: $e');
      await remove(key); // Clean up corrupted cache
      return null;
    }
  }

  void _evictLeastRecentlyUsed() {
    if (_memoryCache.isEmpty) return;

    String? oldestKey;
    DateTime? oldestTime;

    for (final entry in _memoryCache.entries) {
      if (oldestTime == null || entry.value.lastAccessed.isBefore(oldestTime)) {
        oldestTime = entry.value.lastAccessed;
        oldestKey = entry.key;
      }
    }

    if (oldestKey != null) {
      _memoryCache.remove(oldestKey);
    }
  }

  Future<void> _cleanExpiredEntries() async {
    if (_prefs == null) return;

    final keys = _prefs!.getKeys();
    final metaKeys = keys.where((key) => key.startsWith('cache_meta_'));

    for (final metaKey in metaKeys) {
      try {
        final metaString = _prefs!.getString(metaKey);
        if (metaString == null) continue;

        final meta = jsonDecode(metaString) as Map<String, dynamic>;
        final expiresAt = DateTime.fromMillisecondsSinceEpoch(
          meta['expiresAt'],
        );

        if (DateTime.now().isAfter(expiresAt)) {
          final dataKey = metaKey.replaceFirst('cache_meta_', 'cache_');
          await _prefs!.remove(metaKey);
          await _prefs!.remove(dataKey);
        }
      } catch (e) {
        // Clean up corrupted entries
        await _prefs!.remove(metaKey);
      }
    }
  }
}

/// Cache entry with metadata
class CacheEntry {
  final dynamic data;
  final DateTime expiresAt;
  DateTime lastAccessed;

  CacheEntry({
    required this.data,
    required this.expiresAt,
    required this.lastAccessed,
  });

  bool get isExpired => DateTime.now().isAfter(expiresAt);

  void markAccessed() {
    lastAccessed = DateTime.now();
  }
}

/// Cache strategy options
enum CacheStrategy {
  memoryOnly, // Fast but volatile
  persistentOnly, // Slower but survives restarts
  hybrid, // Both layers (recommended)
}

/// Cache layer identification
enum CacheLayer { memory, persistent }

/// Cache statistics for monitoring
class CacheStats {
  int _requests = 0;
  int _memoryHits = 0;
  int _persistentHits = 0;
  int _misses = 0;

  void recordRequest() => _requests++;
  void recordHit(CacheLayer layer) {
    switch (layer) {
      case CacheLayer.memory:
        _memoryHits++;
        break;
      case CacheLayer.persistent:
        _persistentHits++;
        break;
    }
  }

  void recordMiss() => _misses++;

  int get requests => _requests;
  int get totalHits => _memoryHits + _persistentHits;
  int get memoryHits => _memoryHits;
  int get persistentHits => _persistentHits;
  int get misses => _misses;

  double get hitRate => _requests > 0 ? totalHits / _requests : 0.0;
  double get memoryHitRate => _requests > 0 ? _memoryHits / _requests : 0.0;

  void reset() {
    _requests = 0;
    _memoryHits = 0;
    _persistentHits = 0;
    _misses = 0;
  }

  @override
  String toString() {
    return 'CacheStats(requests: $_requests, hits: $totalHits, misses: $_misses, hitRate: ${(hitRate * 100).toStringAsFixed(1)}%)';
  }
}
