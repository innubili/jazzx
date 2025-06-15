import '../../../../core/errors/failures.dart';
import '../../../../core/repositories/user_repository.dart';
import '../../../../models/session.dart';

class SaveSessionUseCase {
  final UserRepository _userRepository;

  SaveSessionUseCase(this._userRepository);

  Future<Result<void>> call({
    required String userId,
    required String sessionId,
    required Session session,
  }) async {
    // Validate session data
    final validationResult = _validateSession(session);
    if (validationResult != null) {
      return Error(validationResult);
    }

    // Save session using repository
    final result = await _userRepository.saveSession(userId, sessionId, session);
    
    return result;
  }

  ValidationFailure? _validateSession(Session session) {
    if (session.started <= 0) {
      return const ValidationFailure('Session start time is invalid');
    }
    
    if (session.ended > 0 && session.ended <= session.started) {
      return const ValidationFailure('Session end time must be after start time');
    }
    
    // Validate session duration (max 8 hours)
    if (session.ended > 0) {
      final duration = session.ended - session.started;
      if (duration > 8 * 60 * 60) { // 8 hours in seconds
        return const ValidationFailure('Session duration cannot exceed 8 hours');
      }
    }
    
    // Validate instrument
    if (session.instrument.trim().isEmpty) {
      return const ValidationFailure('Session must have an instrument specified');
    }
    
    return null;
  }
}
