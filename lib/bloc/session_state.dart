part of 'session_bloc.dart';

abstract class SessionState extends Equatable {
  const SessionState();
  @override
  List<Object?> get props => [];
}

class SessionInitial extends SessionState {}

class SessionLoading extends SessionState {}

class SessionActive extends SessionState {
  final Session session;
  final PracticeCategory currentPracticeCategory;
  final bool isPaused;
  final bool isOnBreak;
  final int? warmupTime;
  final bool isInWarmup;
  final PracticeCategory?
  targetPracticeCategory; // Category to switch to after warmup
  final int?
  autoPauseStartTime; // When auto-pause monitoring started (epoch seconds)
  final int?
  practiceStartedAt; // When current practice session started (epoch seconds)
  final int?
  warmupStartedAt; // When warmup started (epoch seconds) - for timestamp-based warmup calculations

  // Timer state - owned by SessionBloc
  final bool timerIsRunning;
  final int timerDisplaySeconds; // What the timer should display
  final bool timerIsCountdown; // true for warmup/break, false for practice

  final int _stateVersion; // For intelligent diffing

  const SessionActive({
    required this.session,
    required this.currentPracticeCategory,
    this.isPaused = false,
    this.isOnBreak = false,
    this.warmupTime,
    this.isInWarmup = false,
    this.targetPracticeCategory,
    this.autoPauseStartTime,
    this.practiceStartedAt,
    this.warmupStartedAt,
    this.timerIsRunning = false,
    this.timerDisplaySeconds = 0,
    this.timerIsCountdown = false,
    int stateVersion = 0,
  }) : _stateVersion = stateVersion;

  @override
  List<Object?> get props => [
    session.started, // Use session ID instead of full session for comparison
    session.duration,
    session.ended,
    session.instrument,
    _getCategoryHash(), // Hash of categories instead of full categories
    currentPracticeCategory,
    isPaused,
    isOnBreak,
    warmupTime,
    isInWarmup,
    targetPracticeCategory,
    autoPauseStartTime,
    practiceStartedAt,
    warmupStartedAt,
    timerIsRunning,
    timerDisplaySeconds,
    timerIsCountdown,
    _stateVersion,
  ];

  /// Create optimized hash of categories for comparison
  int _getCategoryHash() {
    int hash = 0;
    for (final entry in session.categories.entries) {
      hash ^= entry.key.hashCode;
      hash ^= entry.value.time.hashCode;
      hash ^= (entry.value.note?.hashCode ?? 0);
      hash ^= (entry.value.songs?.length.hashCode ?? 0);
      hash ^= (entry.value.links?.length.hashCode ?? 0);
    }
    return hash;
  }

  /// Create a new state with incremented version (for forced updates)
  SessionActive copyWithVersion({
    Session? session,
    PracticeCategory? currentPracticeCategory,
    bool? isPaused,
    bool? isOnBreak,
    int? warmupTime,
    bool? isInWarmup,
    PracticeCategory? targetPracticeCategory,
    int? autoPauseStartTime,
    int? practiceStartedAt,
    int? warmupStartedAt,
    bool? timerIsRunning,
    int? timerDisplaySeconds,
    bool? timerIsCountdown,
    bool forceUpdate = false,
    bool clearPracticeStartedAt = false,
    bool clearWarmupStartedAt = false,
    bool clearTargetPracticeCategory = false,
  }) {
    return SessionActive(
      session: session ?? this.session,
      currentPracticeCategory:
          currentPracticeCategory ?? this.currentPracticeCategory,
      isPaused: isPaused ?? this.isPaused,
      isOnBreak: isOnBreak ?? this.isOnBreak,
      warmupTime: warmupTime ?? this.warmupTime,
      isInWarmup: isInWarmup ?? this.isInWarmup,
      targetPracticeCategory:
          clearTargetPracticeCategory
              ? null
              : (targetPracticeCategory ?? this.targetPracticeCategory),
      autoPauseStartTime: autoPauseStartTime ?? this.autoPauseStartTime,
      practiceStartedAt:
          clearPracticeStartedAt
              ? null
              : (practiceStartedAt ?? this.practiceStartedAt),
      warmupStartedAt:
          clearWarmupStartedAt
              ? null
              : (warmupStartedAt ?? this.warmupStartedAt),
      timerIsRunning: timerIsRunning ?? this.timerIsRunning,
      timerDisplaySeconds: timerDisplaySeconds ?? this.timerDisplaySeconds,
      timerIsCountdown: timerIsCountdown ?? this.timerIsCountdown,
      stateVersion: forceUpdate ? _stateVersion + 1 : _stateVersion,
    );
  }
}

class SessionPausedState extends SessionState {
  final Session session;
  const SessionPausedState(this.session);
  @override
  List<Object?> get props => [session];
}

class SessionCompletedState extends SessionState {
  final Session session;
  const SessionCompletedState(this.session);
  @override
  List<Object?> get props => [session];
}

class SessionDraftSavedState extends SessionState {
  final Session session;
  const SessionDraftSavedState(this.session);
  @override
  List<Object?> get props => [session];
}

class SessionSavedState extends SessionState {
  final Session session;
  const SessionSavedState(this.session);
  @override
  List<Object?> get props => [session];
}

class SessionAutoSaveWithDraftState extends SessionState {
  final Session session;
  const SessionAutoSaveWithDraftState(this.session);
  @override
  List<Object?> get props => [session];
}

class SessionInitializeState extends SessionState {
  const SessionInitializeState();
  @override
  List<Object?> get props => [];
}

class SessionError extends SessionState {
  final String message;
  const SessionError(this.message);
  @override
  List<Object?> get props => [message];
}
