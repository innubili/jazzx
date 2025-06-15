import '../../models/user_profile.dart';
import '../../models/session.dart';
import '../../models/song.dart';
import '../../models/statistics.dart';
import '../../models/preferences.dart';
import '../../services/firebase_service.dart';
import '../errors/failures.dart';
import '../monitoring/performance_monitor.dart';

abstract class UserRepository {
  Future<Result<UserProfile?>> getUserProfile(String userId);
  Future<Result<void>> saveUserProfile(UserProfile profile);
  Future<Result<void>> updateUserPreferences(
    String userId,
    ProfilePreferences preferences,
  );
  Future<Result<List<MapEntry<String, Session>>>> getUserSessions(
    String userId, {
    int? limit,
    String? startAfter,
  });
  Future<Result<void>> saveSession(
    String userId,
    String sessionId,
    Session session,
  );
  Future<Result<void>> deleteSession(String userId, String sessionId);
  Future<Result<Map<String, Song>>> getUserSongs(String userId);
  Future<Result<void>> saveSong(String userId, Song song);
  Future<Result<Statistics?>> getUserStatistics(String userId);
  Future<Result<void>> saveStatistics(String userId, Statistics statistics);
}

class FirebaseUserRepository implements UserRepository {
  final FirebaseService _firebaseService;
  final PerformanceMonitor _performanceMonitor = PerformanceMonitor();

  FirebaseUserRepository(this._firebaseService);

  @override
  Future<Result<UserProfile?>> getUserProfile(String userId) async {
    final stopwatch = Stopwatch()..start();
    try {
      final profile = await _firebaseService.loadUserProfile();
      stopwatch.stop();
      _performanceMonitor.recordRepositoryCall(
        'getUserProfile',
        stopwatch.elapsed,
      );
      return Success(profile);
    } catch (e) {
      stopwatch.stop();
      _performanceMonitor.recordRepositoryCall(
        'getUserProfile',
        stopwatch.elapsed,
        hasError: true,
      );
      return Error(
        DatabaseFailure('Failed to load user profile: ${e.toString()}'),
      );
    }
  }

  @override
  Future<Result<void>> saveUserProfile(UserProfile profile) async {
    try {
      await _firebaseService.saveUserProfile(profile);
      return const Success(null);
    } catch (e) {
      return Error(
        DatabaseFailure('Failed to save user profile: ${e.toString()}'),
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
      return const Success(null);
    } catch (e) {
      return Error(
        DatabaseFailure('Failed to update preferences: ${e.toString()}'),
      );
    }
  }

  @override
  Future<Result<List<MapEntry<String, Session>>>> getUserSessions(
    String userId, {
    int? limit,
    String? startAfter,
  }) async {
    try {
      final entries = await _firebaseService.loadSessionsPage(
        pageSize: limit ?? 20,
        startAfterId: startAfter,
      );
      return Success(entries);
    } catch (e) {
      return Error(DatabaseFailure('Failed to load sessions: ${e.toString()}'));
    }
  }

  @override
  Future<Result<void>> saveSession(
    String userId,
    String sessionId,
    Session session,
  ) async {
    try {
      await _firebaseService.saveSingleSession(userId, sessionId, session);
      return const Success(null);
    } catch (e) {
      return Error(DatabaseFailure('Failed to save session: ${e.toString()}'));
    }
  }

  @override
  Future<Result<void>> deleteSession(String userId, String sessionId) async {
    try {
      await _firebaseService.removeSingleSession(userId, sessionId);
      return const Success(null);
    } catch (e) {
      return Error(
        DatabaseFailure('Failed to delete session: ${e.toString()}'),
      );
    }
  }

  @override
  Future<Result<Map<String, Song>>> getUserSongs(String userId) async {
    try {
      final profile = await _firebaseService.loadUserProfile();
      return Success(profile?.songs ?? {});
    } catch (e) {
      return Error(DatabaseFailure('Failed to load songs: ${e.toString()}'));
    }
  }

  @override
  Future<Result<void>> saveSong(String userId, Song song) async {
    try {
      await _firebaseService.saveSong(userId, song);
      return const Success(null);
    } catch (e) {
      return Error(DatabaseFailure('Failed to save song: ${e.toString()}'));
    }
  }

  @override
  Future<Result<Statistics?>> getUserStatistics(String userId) async {
    try {
      final statistics = await _firebaseService.loadStatistics(userId);
      return Success(statistics);
    } catch (e) {
      return Error(
        DatabaseFailure('Failed to load statistics: ${e.toString()}'),
      );
    }
  }

  @override
  Future<Result<void>> saveStatistics(
    String userId,
    Statistics statistics,
  ) async {
    try {
      await _firebaseService.saveStatistics(statistics);
      return const Success(null);
    } catch (e) {
      return Error(
        DatabaseFailure('Failed to save statistics: ${e.toString()}'),
      );
    }
  }
}
