import 'package:flutter/material.dart';
import '../models/user_profile.dart';
import '../models/session.dart';
import '../models/preferences.dart';
import '../core/repositories/user_repository.dart';
import '../features/session/domain/usecases/save_session_usecase.dart';
import '../features/session/domain/usecases/load_sessions_usecase.dart';
import '../core/di/service_locator.dart';
import '../core/errors/failures.dart';
import '../utils/utils.dart';

/// Improved UserProfileProvider using Repository Pattern and Use Cases
/// This provides better error handling, caching, and separation of concerns
class ImprovedUserProfileProvider extends ChangeNotifier {
  final UserRepository _userRepository;
  final SaveSessionUseCase _saveSessionUseCase;
  final LoadSessionsUseCase _loadSessionsUseCase;

  UserProfile? _profile;
  String? _userId;
  bool _isLoading = false;
  String? _errorMessage;

  ImprovedUserProfileProvider({
    UserRepository? userRepository,
    SaveSessionUseCase? saveSessionUseCase,
    LoadSessionsUseCase? loadSessionsUseCase,
  }) : _userRepository = userRepository ?? ServiceLocator.userRepository,
       _saveSessionUseCase =
           saveSessionUseCase ?? ServiceLocator.saveSessionUseCase,
       _loadSessionsUseCase =
           loadSessionsUseCase ?? ServiceLocator.loadSessionsUseCase;

  // Getters
  UserProfile? get profile => _profile;
  String? get userId => _userId;
  bool get isLoading => _isLoading;
  String? get errorMessage => _errorMessage;
  bool get hasError => _errorMessage != null;

  /// Load user profile with proper error handling
  Future<void> loadUserProfile(String userId) async {
    _setLoading(true);
    _clearError();

    final result = await _userRepository.getUserProfile(userId);

    result.fold((failure) => _setError(failure.message), (profile) {
      _profile = profile;
      _userId = userId;
      log.info('✅ Profile loaded successfully for user: $userId');
    });

    _setLoading(false);
    notifyListeners();
  }

  /// Save session with validation and error handling
  Future<bool> saveSession(String sessionId, Session session) async {
    if (_userId == null) {
      _setError('User not logged in');
      return false;
    }

    _setLoading(true);
    _clearError();

    final result = await _saveSessionUseCase.call(
      userId: _userId!,
      sessionId: sessionId,
      session: session,
    );

    final success = result.fold(
      (failure) {
        _setError(failure.message);
        return false;
      },
      (_) {
        // Update local profile
        if (_profile != null) {
          final updatedSessions = Map<String, Session>.from(_profile!.sessions);
          updatedSessions[sessionId] = session;
          _profile = _profile!.copyWith(sessions: updatedSessions);
        }
        log.info('✅ Session saved successfully: $sessionId');
        return true;
      },
    );

    _setLoading(false);
    notifyListeners();
    return success;
  }

  /// Load sessions with caching and pagination
  Future<List<MapEntry<String, Session>>> loadSessions({
    int pageSize = 20,
    String? startAfterId,
    bool forceRefresh = false,
  }) async {
    if (_userId == null) {
      _setError('User not logged in');
      return [];
    }

    _setLoading(true);
    _clearError();

    final result = await _loadSessionsUseCase.call(
      userId: _userId!,
      pageSize: pageSize,
      startAfterId: startAfterId,
      forceRefresh: forceRefresh,
    );

    final sessions = result.fold(
      (failure) {
        _setError(failure.message);
        return <MapEntry<String, Session>>[];
      },
      (sessions) {
        // Update local profile with loaded sessions
        if (_profile != null) {
          final updatedSessions = Map<String, Session>.from(_profile!.sessions);
          for (final entry in sessions) {
            updatedSessions[entry.key] = entry.value;
          }
          _profile = _profile!.copyWith(sessions: updatedSessions);
        }
        return sessions;
      },
    );

    _setLoading(false);
    notifyListeners();
    return sessions;
  }

  /// Update user preferences
  Future<bool> updatePreferences(ProfilePreferences preferences) async {
    if (_userId == null) {
      _setError('User not logged in');
      return false;
    }

    _setLoading(true);
    _clearError();

    final result = await _userRepository.updateUserPreferences(
      _userId!,
      preferences,
    );

    final success = result.fold(
      (failure) {
        _setError(failure.message);
        return false;
      },
      (_) {
        // Update local profile
        if (_profile != null) {
          _profile = _profile!.copyWith(preferences: preferences);
        }
        log.info('✅ Preferences updated successfully');
        return true;
      },
    );

    _setLoading(false);
    notifyListeners();
    return success;
  }

  /// Clear all data (for logout)
  void clear() {
    _profile = null;
    _userId = null;
    _clearError();
    _setLoading(false);
    notifyListeners();
  }

  /// Refresh profile data
  Future<void> refresh() async {
    if (_userId != null) {
      await loadUserProfile(_userId!);
    }
  }

  // Private helper methods
  void _setLoading(bool loading) {
    _isLoading = loading;
  }

  void _setError(String message) {
    _errorMessage = message;
    log.severe('❌ UserProfileProvider error: $message');
  }

  void _clearError() {
    _errorMessage = null;
  }
}
