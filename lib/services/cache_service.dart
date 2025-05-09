import '../models/link.dart';
import '../models/search_result.dart';

/// A simple cache service for storing and retrieving search results by provider, query, and category.
class CacheService {
  static final CacheService _instance = CacheService._internal();
  factory CacheService() => _instance;
  CacheService._internal();

  final Map<String, List<SearchResult>> _cache = {};

  String buildKey(String provider, String query, LinkCategory category) =>
      '$provider|$query|${category.name}';

  void store(
    String provider,
    String query,
    LinkCategory category,
    List<SearchResult> results,
  ) {
    _cache[buildKey(provider, query, category)] = results;
  }

  List<SearchResult>? getExact(
    String provider,
    String query,
    LinkCategory category,
  ) {
    return _cache[buildKey(provider, query, category)];
  }

  void clear() => _cache.clear();
}
