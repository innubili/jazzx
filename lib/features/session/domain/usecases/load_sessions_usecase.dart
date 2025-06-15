import '../../../../core/errors/failures.dart';
import '../../../../core/repositories/user_repository.dart';
import '../../../../models/session.dart';

class LoadSessionsUseCase {
  final UserRepository _userRepository;
  
  // In-memory cache for performance
  final Map<String, List<MapEntry<String, Session>>> _cache = {};
  final Map<String, DateTime> _cacheTimestamps = {};
  static const Duration _cacheExpiration = Duration(minutes: 5);

  LoadSessionsUseCase(this._userRepository);

  Future<Result<List<MapEntry<String, Session>>>> call({
    required String userId,
    int pageSize = 20,
    String? startAfterId,
    bool forceRefresh = false,
  }) async {
    final cacheKey = '${userId}_${pageSize}_${startAfterId ?? 'initial'}';
    
    // Check cache first (unless force refresh)
    if (!forceRefresh && _isCacheValid(cacheKey)) {
      return Success(_cache[cacheKey]!);
    }

    // Load from repository
    final result = await _userRepository.getUserSessions(
      userId,
      limit: pageSize,
      startAfter: startAfterId,
    );

    if (result.isSuccess) {
      // Update cache
      _cache[cacheKey] = result.data!;
      _cacheTimestamps[cacheKey] = DateTime.now();
    }

    return result;
  }

  bool _isCacheValid(String cacheKey) {
    if (!_cache.containsKey(cacheKey) || !_cacheTimestamps.containsKey(cacheKey)) {
      return false;
    }
    
    final cacheTime = _cacheTimestamps[cacheKey]!;
    return DateTime.now().difference(cacheTime) < _cacheExpiration;
  }

  void clearCache() {
    _cache.clear();
    _cacheTimestamps.clear();
  }

  void invalidateUserCache(String userId) {
    final keysToRemove = _cache.keys.where((key) => key.startsWith(userId)).toList();
    for (final key in keysToRemove) {
      _cache.remove(key);
      _cacheTimestamps.remove(key);
    }
  }
}
