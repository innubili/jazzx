import 'dart:async';
import 'dart:convert';
import 'package:bloc/bloc.dart';
import 'package:equatable/equatable.dart';
import '../core/logging/app_loggers.dart';
import '../core/time/app_clock.dart';
import '../models/link.dart';
import '../models/practice_category.dart';
import '../models/session.dart';

part 'session_event.dart';
part 'session_state.dart';

class SessionBloc extends Bloc<SessionEvent, SessionState> {
  final AppClock _clock;
  Timer? _timerTicker; // Timer for updating display seconds
  int? _timerStartTime; // When the timer was started (epoch seconds)
  int? _initialTimerValue; // Initial timer value when started

  // User preferences for auto-pause and BPM settings
  int _warmupTime = 1200; // Default 20 minutes
  int _pauseDurationTime = 300; // Default 5 minutes
  int _warmupBpm = 80; // Default warmup BPM

  SessionBloc({AppClock? clock})
    : _clock = clock ?? SystemClock(),
      super(SessionInitial()) {
    AppLoggers.system.info('SessionBloc constructor started');
    on<SessionStarted>(_onSessionStarted);
    on<SessionCategoryChanged>(_onCategoryChanged);
    on<SessionPaused>(_onPaused);
    on<SessionResumed>(_onResumed);
    on<SessionUpdated>(_onUpdated);
    on<SessionCompleted>(_onCompleted);
    on<SessionDiscarded>(_onDiscarded);
    on<SessionDraftSaved>(_onDraftSaved);
    on<SessionSaved>(_onSaved);
    on<SessionLoaded>(_onLoaded);
    on<SessionAutoSaveWithDraft>(_onAutoSaveWithDraft);
    on<SessionInitialize>(_onInitialize);
    on<SessionWarmupChanged>(_onWarmupChanged);
    on<SessionWarmupStarted>(_onWarmupStarted);
    on<SessionWarmupCompleted>(_onWarmupCompleted);
    on<SessionWarmupSkipped>(_onWarmupSkipped);
    on<SessionBreakSkipped>(_onBreakSkipped);
    on<SessionAutoPauseChanged>(_onAutoPauseChanged);
    on<SessionNoteChanged>(_onNoteChanged);
    on<SessionLinksChanged>(_onLinksChanged);
    on<SessionSongsChanged>(_onSongsChanged);
    on<SessionAutoSave>(_onAutoSave);

    // Clean widget events
    on<TimerStartPressed>(_onTimerStartPressed);
    on<TimerStopPressed>(_onTimerStopPressed);
    on<TimerSkipPressed>(_onTimerSkipPressed);
    on<TimerDonePressed>(_onTimerDonePressed);
    on<TimerTick>(_onTimerTick);
    on<CategorySelected>(_onCategorySelected);
    on<PracticeModeSelected>(_onPracticeModeSelected);
    on<PracticeCategoryDetailChanged>(_onPracticeCategoryDetailChanged);

    AppLoggers.system.info('SessionBloc constructor completed successfully');
  }

  /// Log session state changes for debugging
  void _logSessionStateChange(String event, SessionState newState) {
    if (newState is SessionActive) {
      final metadata = {
        'event': event,
        'state_type': 'SessionActive',
        'current_category': newState.currentPracticeCategory.name,
        'is_paused': newState.isPaused,
        'is_on_break': newState.isOnBreak,
        'is_in_warmup': newState.isInWarmup,
        'practice_started_at': newState.practiceStartedAt,
        'auto_pause_start_time': newState.autoPauseStartTime,
        'session_data': newState.session.asLogString(),
      };

      // Pretty print the metadata
      final prettyJson = const JsonEncoder.withIndent('  ').convert(metadata);
      AppLoggers.system.debug('Session state changed: $event\n$prettyJson');
    } else {
      final metadata = {
        'event': event,
        'state_type': newState.runtimeType.toString(),
      };
      final prettyJson = const JsonEncoder.withIndent('  ').convert(metadata);
      AppLoggers.system.debug('Session state changed: $event\n$prettyJson');
    }
  }

  /// Smart emit that only emits if the new state is actually different
  void _smartEmit(
    SessionState newState,
    Emitter<SessionState> emit, {
    String? eventName,
  }) {
    // Only emit if state actually changed (Equatable will handle comparison)
    if (state != newState) {
      // Skip detailed logging for timer ticks to improve performance
      if (eventName != 'TimerTick') {
        _logSessionStateChange(eventName ?? 'unknown', newState);
      }
      emit(newState);
    }
  }

  /// Start the timer ticker for updating display seconds
  void _startTimerTicker() {
    _stopTimerTicker(); // Stop any existing timer
    _timerStartTime = _clock.nowSeconds;

    // Store the initial timer value when starting
    final currentState = state;
    if (currentState is SessionActive) {
      _initialTimerValue = currentState.timerDisplaySeconds;
    }

    _timerTicker = Timer.periodic(const Duration(seconds: 1), (timer) {
      final currentState = state;
      if (currentState is SessionActive &&
          currentState.timerIsRunning &&
          _initialTimerValue != null) {
        final elapsed = _clock.nowSeconds - _timerStartTime!;
        int newDisplaySeconds;

        if (currentState.timerIsCountdown) {
          // Countdown: subtract elapsed time from initial value
          newDisplaySeconds =
              (_initialTimerValue! - elapsed).clamp(0, double.infinity).toInt();

          // Check if countdown reached zero
          if (newDisplaySeconds <= 0) {
            _stopTimerTicker();
            if (currentState.isInWarmup) {
              add(
                SessionWarmupCompleted(actualWarmupTime: _initialTimerValue!),
              );
            }
            return;
          }
        } else {
          // Count up: add elapsed time to initial value
          newDisplaySeconds = _initialTimerValue! + elapsed;
        }

        // Trigger a timer tick event to update display
        add(TimerTick(newDisplaySeconds: newDisplaySeconds));
      } else {
        // Timer is not running, stop the ticker
        _stopTimerTicker();
      }
    });
  }

  /// Stop the timer ticker
  void _stopTimerTicker() {
    _timerTicker?.cancel();
    _timerTicker = null;
    _timerStartTime = null;
    _initialTimerValue = null;
  }

  @override
  Future<void> close() {
    _stopTimerTicker();
    return super.close();
  }

  /// Create optimized SessionActive state
  SessionActive _createSessionActive({
    required Session session,
    required PracticeCategory currentPracticeCategory,
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
    final currentState = state;
    if (currentState is SessionActive) {
      return currentState.copyWithVersion(
        session: session,
        currentPracticeCategory: currentPracticeCategory,
        isPaused: isPaused ?? currentState.isPaused,
        isOnBreak: isOnBreak ?? currentState.isOnBreak,
        warmupTime: warmupTime ?? currentState.warmupTime,
        isInWarmup: isInWarmup ?? currentState.isInWarmup,
        targetPracticeCategory:
            clearTargetPracticeCategory
                ? null
                : (targetPracticeCategory ??
                    currentState.targetPracticeCategory),
        autoPauseStartTime:
            autoPauseStartTime ?? currentState.autoPauseStartTime,
        practiceStartedAt: practiceStartedAt,
        warmupStartedAt: warmupStartedAt,
        timerIsRunning: timerIsRunning ?? currentState.timerIsRunning,
        timerDisplaySeconds:
            timerDisplaySeconds ?? currentState.timerDisplaySeconds,
        timerIsCountdown: timerIsCountdown ?? currentState.timerIsCountdown,
        clearPracticeStartedAt: clearPracticeStartedAt,
        clearWarmupStartedAt: clearWarmupStartedAt,
        clearTargetPracticeCategory: clearTargetPracticeCategory,
        forceUpdate: forceUpdate,
      );
    }

    return SessionActive(
      session: session,
      currentPracticeCategory: currentPracticeCategory,
      isPaused: isPaused ?? false,
      isOnBreak: isOnBreak ?? false,
      warmupTime: warmupTime,
      isInWarmup: isInWarmup ?? false,
      targetPracticeCategory: targetPracticeCategory,
      autoPauseStartTime: autoPauseStartTime,
      practiceStartedAt: practiceStartedAt,
      warmupStartedAt: warmupStartedAt,
      timerIsRunning: timerIsRunning ?? false,
      timerDisplaySeconds: timerDisplaySeconds ?? 0,
      timerIsCountdown: timerIsCountdown ?? false,
    );
  }

  void _onSessionStarted(SessionStarted event, Emitter<SessionState> emit) {
    // Select initial category (first category in session)
    final initialCategory =
        event.session.categories.keys.isNotEmpty
            ? event.session.categories.keys.first
            : PracticeCategory.exercise;
    final newState = SessionActive(
      session: event.session,
      currentPracticeCategory: initialCategory,
    );
    _logSessionStateChange('SessionStarted', newState);
    emit(newState);
  }

  void _onCategoryChanged(
    SessionCategoryChanged event,
    Emitter<SessionState> emit,
  ) {
    final currentState = state;
    if (currentState is SessionActive) {
      Session updatedSession = currentState.session;

      // Handle category change during warmup differently
      if (currentState.isInWarmup) {
        // During warmup: pause warmup, update target category, keep warmup active
        if (currentState.warmupStartedAt != null) {
          final now = _clock.nowSeconds;
          final warmupElapsed = now - currentState.warmupStartedAt!;

          // Update session with current warmup time (partial)
          final warmup = Warmup(time: warmupElapsed, bpm: 80);
          updatedSession = currentState.session.copyWith(warmup: warmup);
        }

        final newState = _createSessionActive(
          session: updatedSession,
          currentPracticeCategory:
              currentState
                  .currentPracticeCategory, // Keep current category during warmup
          isPaused: true, // Pause warmup
          isInWarmup: true, // Stay in warmup mode
          targetPracticeCategory:
              event.currentPracticeCategory, // Update target for after warmup
          warmupTime: currentState.warmupTime,
          clearWarmupStartedAt: true, // Clear warmup timestamp when paused
          forceUpdate: true,
        );
        _logSessionStateChange('CategoryChanged', newState);
        emit(newState);
        return;
      }

      // Handle category change during normal practice
      // SAVE-BEFORE-CHANGE RULE: Save elapsed time for current category before switching using timestamps
      if (currentState.practiceStartedAt != null) {
        final now = _clock.nowSeconds;
        final elapsedSeconds = now - currentState.practiceStartedAt!;

        final currentCategory = currentState.currentPracticeCategory;
        final currentCategoryData = updatedSession.categories[currentCategory];
        if (currentCategoryData != null) {
          // Add elapsed time to existing time for current category
          final newTime = currentCategoryData.time + elapsedSeconds;
          final updatedCategoryData = currentCategoryData.copyWith(
            time: newTime,
          );
          updatedSession = updatedSession.copyWithCategory(
            currentCategory,
            updatedCategoryData,
          );
        }
      }

      // Category switching always pauses the session and stops the timer
      _stopTimerTicker(); // Stop the timer when changing categories

      // Get accumulated time for the NEW category to display on timer
      final newCategoryAccumulatedTime =
          updatedSession.categories[event.currentPracticeCategory]?.time ?? 0;

      final newState = _createSessionActive(
        session: updatedSession,
        currentPracticeCategory: event.currentPracticeCategory,
        isPaused: true, // Always pause when changing categories
        isOnBreak: currentState.isOnBreak,
        warmupTime: currentState.warmupTime,
        timerIsRunning: false, // Stop timer when changing categories
        timerDisplaySeconds:
            newCategoryAccumulatedTime, // Show accumulated time for new category
        timerIsCountdown: false, // Practice mode counts up
        clearPracticeStartedAt:
            true, // Clear timestamp when pausing due to category change
        forceUpdate: true,
      );
      _logSessionStateChange('CategoryChanged', newState);
      emit(newState);
    }
  }

  void _onPaused(SessionPaused event, Emitter<SessionState> emit) {
    final currentState = state;
    if (currentState is SessionActive && !currentState.isPaused) {
      Session updatedSession = currentState.session;

      // Debug log to check warmup pause conditions
      AppLoggers.system.debug(
        'Pause event - checking warmup conditions',
        metadata: {
          'is_in_warmup': currentState.isInWarmup,
          'warmup_started_at': currentState.warmupStartedAt,
          'warmup_started_at_is_null': currentState.warmupStartedAt == null,
          'current_session_warmup_time': currentState.session.warmup?.time ?? 0,
        },
      );

      // Handle warmup pause - save warmup time using timestamps
      if (currentState.isInWarmup && currentState.warmupStartedAt != null) {
        final now = _clock.nowSeconds;
        final warmupElapsed = now - currentState.warmupStartedAt!;

        // Add elapsed time to existing warmup time (accumulate)
        final existingWarmupTime = currentState.session.warmup?.time ?? 0;
        final totalWarmupTime = existingWarmupTime + warmupElapsed;

        final warmup = Warmup(time: totalWarmupTime, bpm: 80);
        updatedSession = currentState.session.copyWith(warmup: warmup);

        // Debug log to verify warmup time calculation
        AppLoggers.system.debug(
          'Warmup pause calculation',
          metadata: {
            'warmup_elapsed_seconds': warmupElapsed,
            'existing_warmup_time': existingWarmupTime,
            'total_warmup_time': totalWarmupTime,
            'warmup_started_at': currentState.warmupStartedAt,
            'current_time': now,
            'session_warmup_before': currentState.session.warmup?.time ?? 0,
            'session_warmup_after': updatedSession.warmup?.time ?? 0,
          },
        );
      }

      // Handle practice pause - save practice time using timestamps
      if (!currentState.isInWarmup && currentState.practiceStartedAt != null) {
        final now = _clock.nowSeconds;
        final elapsedSeconds = now - currentState.practiceStartedAt!;

        final currentCategory = currentState.currentPracticeCategory;
        final currentCategoryData = updatedSession.categories[currentCategory];
        if (currentCategoryData != null) {
          // Add elapsed time to existing time for current category
          final newTime = currentCategoryData.time + elapsedSeconds;
          final updatedCategoryData = currentCategoryData.copyWith(
            time: newTime,
          );
          updatedSession = updatedSession.copyWithCategory(
            currentCategory,
            updatedCategoryData,
          );
        }
      }

      final newState = _createSessionActive(
        session: updatedSession,
        currentPracticeCategory: currentState.currentPracticeCategory,
        isPaused: true,
        isOnBreak: currentState.isOnBreak,
        warmupTime: currentState.warmupTime,
        isInWarmup: currentState.isInWarmup,
        targetPracticeCategory: currentState.targetPracticeCategory,
        clearPracticeStartedAt: true, // Clear practice timestamp when paused
        clearWarmupStartedAt: true, // Clear warmup timestamp when paused
        forceUpdate: true,
      );
      _logSessionStateChange('SessionPaused', newState);
      emit(newState);
    }
  }

  /// Shared helper method for resuming practice (from pause or break)
  void _resumePractice({
    required SessionActive currentState,
    required Emitter<SessionState> emit,
    bool? isOnBreak,
  }) {
    final now = _clock.nowSeconds;

    // Start auto-pause monitoring only for practice (not warmup)
    int? autoPauseStartTime = currentState.autoPauseStartTime;
    if (!currentState.isInWarmup) {
      // Reset auto-pause timer on practice start/restart
      autoPauseStartTime = now;
    }

    // Handle warmup resume: account for already accumulated warmup time
    int? warmupStartedAt;
    int? remainingWarmupTime;
    if (currentState.isInWarmup) {
      final accumulatedWarmupTime = currentState.session.warmup?.time ?? 0;
      final totalWarmupTime =
          currentState.warmupTime ?? 1200; // 20 minutes default

      // Calculate remaining warmup time for timer initialization
      remainingWarmupTime = totalWarmupTime - accumulatedWarmupTime;

      // Set warmup start time to current time (not adjusted)
      // The pause calculation will account for accumulated time
      warmupStartedAt = now;
    }

    final newState = _createSessionActive(
      session: currentState.session,
      currentPracticeCategory: currentState.currentPracticeCategory,
      isPaused: false,
      isOnBreak: isOnBreak ?? currentState.isOnBreak,
      autoPauseStartTime: autoPauseStartTime,
      practiceStartedAt:
          currentState.isInWarmup
              ? null
              : now, // Set timestamp when resuming practice (not warmup)
      warmupStartedAt: warmupStartedAt, // Use calculated warmup start time
      warmupTime:
          remainingWarmupTime ??
          currentState.warmupTime, // Pass remaining time for timer
      forceUpdate: true, // Force update for resume
    );
    _smartEmit(newState, emit, eventName: 'ResumePractice');
  }

  void _onResumed(SessionResumed event, Emitter<SessionState> emit) {
    final currentState = state;
    if (currentState is SessionActive && currentState.isPaused) {
      _resumePractice(currentState: currentState, emit: emit);
    }
  }

  void _onUpdated(SessionUpdated event, Emitter<SessionState> emit) {
    final currentState = state;
    if (currentState is SessionActive) {
      emit(
        SessionActive(
          session: event.session,
          currentPracticeCategory: currentState.currentPracticeCategory,
          isPaused: currentState.isPaused,
          isOnBreak: currentState.isOnBreak,
          warmupTime: currentState.warmupTime,
        ),
      );
    }
  }

  void _onCompleted(SessionCompleted event, Emitter<SessionState> emit) {
    final currentState = state;
    if (currentState is SessionActive) {
      Session updatedSession = currentState.session;

      // Save current elapsed time before completion using timestamps
      if (currentState.practiceStartedAt != null) {
        final now = _clock.nowSeconds;
        final elapsedSeconds = now - currentState.practiceStartedAt!;

        final currentCategory = currentState.currentPracticeCategory;
        final currentCategoryData = updatedSession.categories[currentCategory];
        if (currentCategoryData != null) {
          // Add elapsed time to existing time for current category
          final newTime = currentCategoryData.time + elapsedSeconds;
          final updatedCategoryData = currentCategoryData.copyWith(
            time: newTime,
          );
          updatedSession = updatedSession.copyWithCategory(
            currentCategory,
            updatedCategoryData,
          );
        }
      }

      // Calculate final session duration: sum of all category times + warmup time
      int totalDuration = 0;
      for (final categoryData in updatedSession.categories.values) {
        totalDuration += categoryData.time;
      }
      if (updatedSession.warmup != null) {
        totalDuration += updatedSession.warmup!.time;
      }

      // Set end timestamp and final duration
      final endTimestamp = _clock.nowSeconds;
      final completedSession = updatedSession.copyWith(
        duration: totalDuration,
        ended: endTimestamp,
      );

      final newState = SessionCompletedState(completedSession);
      _logSessionStateChange('SessionCompleted', newState);
      emit(newState);
    }
  }

  void _onDiscarded(SessionDiscarded event, Emitter<SessionState> emit) {
    emit(SessionInitial());
  }

  void _onDraftSaved(SessionDraftSaved event, Emitter<SessionState> emit) {
    emit(SessionDraftSavedState(event.session));
  }

  Future<void> _onSaved(SessionSaved event, Emitter<SessionState> emit) async {
    try {
      // Get the user profile provider from the context
      // Note: This requires dependency injection or service locator pattern
      // For now, we'll emit a state that the UI can listen to and handle the save
      emit(SessionSavedState(event.session));
    } catch (e) {
      // Handle error - could emit an error state
      AppLoggers.system.error('Failed to save session: $e');
      // For now, stay in current state
    }
  }

  Future<void> _onAutoSaveWithDraft(
    SessionAutoSaveWithDraft event,
    Emitter<SessionState> emit,
  ) async {
    final currentState = state;

    // Only auto-save for active sessions that haven't been completed
    if (currentState is SessionActive && !currentState.isPaused) {
      // Emit a state that the UI can listen to for draft saving
      // This maintains BLoC architecture by keeping business logic in BLoC
      emit(SessionAutoSaveWithDraftState(currentState.session));

      // Immediately return to the current active state
      emit(currentState);
    }
  }

  Future<void> _onInitialize(
    SessionInitialize event,
    Emitter<SessionState> emit,
  ) async {
    AppLoggers.system.info('SessionBloc _onInitialize called');

    // Emit a state that the UI can listen to for initialization
    // This will trigger the UI to check for draft sessions
    emit(SessionInitializeState());

    AppLoggers.system.info('SessionBloc emitted SessionInitializeState');
  }

  void _onLoaded(SessionLoaded event, Emitter<SessionState> emit) {
    if (event.session != null) {
      final session = event.session!;
      final initialCategory =
          session.categories.keys.isNotEmpty
              ? session.categories.keys.first
              : PracticeCategory.exercise;

      // Calculate timer display based on accumulated time for the initial category
      final accumulatedTime = session.categories[initialCategory]?.time ?? 0;

      // Create session state with proper timer display
      final newState = _createSessionActive(
        session: session,
        currentPracticeCategory: initialCategory,
        isPaused: true, // Start paused when loading a session
        timerDisplaySeconds: accumulatedTime, // Show accumulated time
        timerIsCountdown: false, // Practice mode counts up
        timerIsRunning: false, // Start stopped
        forceUpdate: true,
      );

      _smartEmit(newState, emit, eventName: 'SessionLoaded');
    } else {
      emit(SessionInitial());
    }
  }

  void _onWarmupChanged(
    SessionWarmupChanged event,
    Emitter<SessionState> emit,
  ) {
    final currentState = state;
    if (currentState is SessionActive) {
      emit(
        SessionActive(
          session: currentState.session,
          currentPracticeCategory: currentState.currentPracticeCategory,
          isPaused: currentState.isPaused,
          isOnBreak: currentState.isOnBreak,
          warmupTime: event.warmupTime,
          isInWarmup: currentState.isInWarmup,
          targetPracticeCategory: currentState.targetPracticeCategory,
        ),
      );
    }
  }

  void _onWarmupStarted(
    SessionWarmupStarted event,
    Emitter<SessionState> emit,
  ) {
    final currentState = state;
    if (currentState is SessionActive) {
      // Start warmup phase with timestamp tracking
      final now = _clock.nowSeconds;
      final newState = _createSessionActive(
        session: currentState.session,
        currentPracticeCategory:
            PracticeCategory.exercise, // Placeholder during warmup
        isPaused: true, // Start paused
        isInWarmup: true, // Mark as warmup phase
        targetPracticeCategory:
            event.targetCategory, // Store target for after warmup
        warmupTime: event.warmupTime,
        warmupStartedAt: now, // Set warmup start timestamp
        forceUpdate: true,
      );
      _smartEmit(newState, emit);
    }
  }

  /// Shared helper method for transitioning from warmup to practice
  void _transitionFromWarmupToPractice({
    required SessionActive currentState,
    required int actualWarmupTime,
    required Emitter<SessionState> emit,
    int? warmupBpm,
  }) {
    // Create warmup data with actual time spent
    final warmup = Warmup(
      time: actualWarmupTime,
      bpm: warmupBpm ?? 80, // Use provided warmup BPM or default
    );

    // Update session with warmup data
    final updatedSession = currentState.session.copyWith(warmup: warmup);

    // Transition to target practice category
    final targetCategory =
        currentState.targetPracticeCategory ?? PracticeCategory.exercise;

    // Start practice with timestamps and timer setup
    final now = _clock.nowSeconds;

    // Get accumulated time for the target practice category (should be 0 for first time)
    final accumulatedTime =
        updatedSession.categories[targetCategory]?.time ?? 0;

    final newState = _createSessionActive(
      session: updatedSession,
      currentPracticeCategory: targetCategory,
      isPaused: false, // Auto-start practice after warmup
      isInWarmup: false, // No longer in warmup
      autoPauseStartTime: now, // Start auto-pause timer
      practiceStartedAt: now, // Start practice timestamp
      timerDisplaySeconds:
          accumulatedTime, // Show accumulated practice time (usually 00:00:00)
      timerIsCountdown: false, // Practice mode counts up
      timerIsRunning: true, // Auto-start timer
      clearTargetPracticeCategory: true, // Clear target practice category
      forceUpdate: true,
    );
    _smartEmit(newState, emit, eventName: 'WarmupToPracticeTransition');

    // Start the timer ticker for practice mode
    _startTimerTicker();
  }

  void _onWarmupCompleted(
    SessionWarmupCompleted event,
    Emitter<SessionState> emit,
  ) {
    final currentState = state;
    if (currentState is SessionActive && currentState.isInWarmup) {
      // Calculate actual warmup time using timestamps instead of timer elapsed time
      final actualWarmupTime =
          currentState.warmupStartedAt != null
              ? _clock.nowSeconds - currentState.warmupStartedAt!
              : event
                  .actualWarmupTime; // Fallback to timer value if no timestamp

      _transitionFromWarmupToPractice(
        currentState: currentState,
        actualWarmupTime: actualWarmupTime,
        emit: emit,
        warmupBpm: _warmupBpm,
      );
    }
  }

  void _onWarmupSkipped(
    SessionWarmupSkipped event,
    Emitter<SessionState> emit,
  ) {
    final currentState = state;
    if (currentState is SessionActive && currentState.isInWarmup) {
      // Calculate actual warmup time using timestamps instead of timer elapsed time
      final actualWarmupTime =
          currentState.warmupStartedAt != null
              ? _clock.nowSeconds - currentState.warmupStartedAt!
              : event
                  .actualWarmupTime; // Fallback to timer value if no timestamp

      _transitionFromWarmupToPractice(
        currentState: currentState,
        actualWarmupTime: actualWarmupTime,
        emit: emit,
        warmupBpm: _warmupBpm,
      );
    }
  }

  void _onBreakSkipped(SessionBreakSkipped event, Emitter<SessionState> emit) {
    final currentState = state;
    if (currentState is SessionActive && currentState.isOnBreak) {
      // End break and resume practice
      _resumePractice(
        currentState: currentState,
        emit: emit,
        isOnBreak: false, // No longer on break
      );
    }
  }

  void _onAutoPauseChanged(
    SessionAutoPauseChanged event,
    Emitter<SessionState> emit,
  ) {
    final currentState = state;
    if (currentState is SessionActive) {
      emit(
        SessionActive(
          session: currentState.session,
          currentPracticeCategory: currentState.currentPracticeCategory,
          isPaused: currentState.isPaused,
          isOnBreak: event.isOnBreak,
          warmupTime: currentState.warmupTime,
        ),
      );
    }
  }

  void _onNoteChanged(SessionNoteChanged event, Emitter<SessionState> emit) {
    final currentState = state;
    if (currentState is SessionActive) {
      final category = event.category;
      final oldCategory = currentState.session.categories[category];
      if (oldCategory != null) {
        // Skip update if note hasn't actually changed
        if (oldCategory.note == event.note) return;

        final updatedCategory = oldCategory.copyWith(note: event.note);
        final updatedSession = currentState.session.copyWithCategory(
          category,
          updatedCategory,
        );

        final newState = _createSessionActive(
          session: updatedSession,
          currentPracticeCategory: currentState.currentPracticeCategory,
          forceUpdate: false, // Let smart emit decide
        );
        _smartEmit(newState, emit, eventName: 'NoteChanged');
      }
    }
  }

  void _onLinksChanged(SessionLinksChanged event, Emitter<SessionState> emit) {
    final currentState = state;
    if (currentState is SessionActive) {
      final category = event.category;
      final oldCategory = currentState.session.categories[category];
      if (oldCategory != null) {
        // Convert List<String> to List<Link> by matching keys or creating new Link objects
        final updatedLinks =
            event.links.map((url) {
              // Try to find existing link by key or url
              final existing = oldCategory.links?.firstWhere(
                (l) => l.link == url || l.key == url,
                orElse:
                    () => Link(
                      key: url,
                      name: url,
                      kind: LinkKind.youtube,
                      link: url,
                      category: LinkCategory.other,
                      isDefault: false,
                    ),
              );
              return existing ??
                  Link(
                    key: url,
                    name: url,
                    kind: LinkKind.youtube,
                    link: url,
                    category: LinkCategory.other,
                    isDefault: false,
                  );
            }).toList();
        final updatedCategory = oldCategory.copyWith(links: updatedLinks);
        final updatedSession = currentState.session.copyWithCategory(
          category,
          updatedCategory,
        );
        emit(
          SessionActive(
            session: updatedSession,
            currentPracticeCategory: currentState.currentPracticeCategory,
            isPaused: currentState.isPaused,
            isOnBreak: currentState.isOnBreak,
            warmupTime: currentState.warmupTime,
          ),
        );
      }
    }
  }

  void _onSongsChanged(SessionSongsChanged event, Emitter<SessionState> emit) {
    final currentState = state;
    if (currentState is SessionActive) {
      final category = event.category;
      final oldCategory = currentState.session.categories[category];
      if (oldCategory != null) {
        // Expecting Map<String, int> for songs
        final updatedCategory = oldCategory.copyWith(
          songs: Map<String, int>.from(event.songs),
        );
        final updatedSession = currentState.session.copyWithCategory(
          category,
          updatedCategory,
        );
        emit(
          SessionActive(
            session: updatedSession,
            currentPracticeCategory: currentState.currentPracticeCategory,
            isPaused: currentState.isPaused,
            isOnBreak: currentState.isOnBreak,
            warmupTime: currentState.warmupTime,
          ),
        );
      }
    }
  }

  void _onAutoSave(SessionAutoSave event, Emitter<SessionState> emit) {
    final currentState = state;
    if (currentState is SessionActive) {
      Session updatedSession = currentState.session;

      // Save current elapsed time before auto-save
      if (event.currentElapsedSeconds != null) {
        final currentCategory = currentState.currentPracticeCategory;
        final currentCategoryData = updatedSession.categories[currentCategory];
        if (currentCategoryData != null) {
          // Add elapsed time to existing time for current category
          final newTime =
              currentCategoryData.time + event.currentElapsedSeconds!;
          final updatedCategoryData = currentCategoryData.copyWith(
            time: newTime,
          );
          updatedSession = updatedSession.copyWithCategory(
            currentCategory,
            updatedCategoryData,
          );
        }
      }

      // Use smart emit to avoid unnecessary UI rebuilds for auto-save
      final newState = _createSessionActive(
        session: updatedSession,
        currentPracticeCategory: currentState.currentPracticeCategory,
        forceUpdate: false, // Don't force update for auto-save
      );
      _smartEmit(newState, emit);
    }
  }

  // ============================================================================
  // CLEAN WIDGET EVENT HANDLERS
  // ============================================================================

  void _onTimerStartPressed(
    TimerStartPressed event,
    Emitter<SessionState> emit,
  ) {
    final currentState = state;
    if (currentState is SessionActive) {
      // Calculate timer display and mode based on current state
      int timerDisplaySeconds;
      bool timerIsCountdown;

      if (currentState.isInWarmup) {
        // Warmup mode: countdown from remaining warmup time
        final accumulatedWarmupTime = currentState.session.warmup?.time ?? 0;
        final totalWarmupTime =
            currentState.warmupTime ?? 1200; // 20 minutes default
        timerDisplaySeconds = totalWarmupTime - accumulatedWarmupTime;
        timerIsCountdown = true;
      } else {
        // Practice mode: count up from accumulated category time
        final accumulatedTime =
            currentState
                .session
                .categories[currentState.currentPracticeCategory]
                ?.time ??
            0;
        timerDisplaySeconds = accumulatedTime;
        timerIsCountdown = false;
      }

      // Set timestamps for time tracking
      final now = _clock.nowSeconds;
      int? practiceStartedAt;
      int? warmupStartedAt;
      int? autoPauseStartTime;

      if (currentState.isInWarmup) {
        // For warmup: set warmup timestamp to current time
        // The pause calculation will account for accumulated time
        warmupStartedAt = now;
      } else {
        // For practice: set practice timestamp and auto-pause timer
        practiceStartedAt = now;
        autoPauseStartTime = now; // Reset auto-pause timer on practice start
      }

      // Update timer state and resume session with proper timestamps
      final newState = _createSessionActive(
        session: currentState.session,
        currentPracticeCategory: currentState.currentPracticeCategory,
        isPaused: false,
        timerIsRunning: true,
        timerDisplaySeconds: timerDisplaySeconds,
        timerIsCountdown: timerIsCountdown,
        practiceStartedAt: practiceStartedAt,
        warmupStartedAt: warmupStartedAt,
        autoPauseStartTime: autoPauseStartTime,
        forceUpdate: true,
      );
      _smartEmit(newState, emit, eventName: 'TimerStartPressed');

      // Start the timer ticker for display updates
      _startTimerTicker();
    }
  }

  void _onTimerStopPressed(TimerStopPressed event, Emitter<SessionState> emit) {
    final currentState = state;
    if (currentState is SessionActive) {
      // Stop the timer ticker
      _stopTimerTicker();

      // Update timer state to stopped
      final newState = _createSessionActive(
        session: currentState.session,
        currentPracticeCategory: currentState.currentPracticeCategory,
        timerIsRunning: false,
        forceUpdate: true,
      );
      _smartEmit(newState, emit, eventName: 'TimerStopPressed');

      // Also trigger pause logic for timestamps
      add(SessionPaused());
    }
  }

  void _onTimerTick(TimerTick event, Emitter<SessionState> emit) {
    final currentState = state;
    if (currentState is SessionActive && currentState.timerIsRunning) {
      // Update timer display
      final newState = _createSessionActive(
        session: currentState.session,
        currentPracticeCategory: currentState.currentPracticeCategory,
        timerDisplaySeconds: event.newDisplaySeconds,
        forceUpdate: false, // Don't force update for timer ticks
      );
      _smartEmit(newState, emit, eventName: 'TimerTick');
    }
  }

  void _onTimerSkipPressed(TimerSkipPressed event, Emitter<SessionState> emit) {
    final currentState = state;
    if (currentState is SessionActive) {
      if (currentState.isInWarmup) {
        // Skip warmup
        final actualWarmupTime =
            currentState.warmupStartedAt != null
                ? _clock.nowSeconds - currentState.warmupStartedAt!
                : 0;
        add(SessionWarmupSkipped(actualWarmupTime: actualWarmupTime));
      } else if (currentState.isOnBreak) {
        // Skip break
        add(SessionBreakSkipped());
      }
    }
  }

  void _onTimerDonePressed(TimerDonePressed event, Emitter<SessionState> emit) {
    // Timer done means complete session
    add(SessionCompleted());
  }

  void _onCategorySelected(CategorySelected event, Emitter<SessionState> emit) {
    final currentState = state;
    if (currentState is SessionInitial) {
      // For new sessions, use PracticeModeSelected for complete flow
      // Use provided preferences or defaults
      final warmupEnabled = event.warmupEnabled ?? true; // Default to enabled
      final warmupTime = event.warmupTime ?? 1200; // Default to 20 minutes
      final warmupBpm = event.warmupBpm ?? 80; // Default warmup BPM
      final exerciseBpm = event.exerciseBpm ?? 100; // Default exercise BPM
      final lastSessionId = event.lastSessionId ?? ''; // Default empty
      final autoPauseEnabled =
          event.autoPauseEnabled ?? false; // Default disabled
      final pauseIntervalTime =
          event.pauseIntervalTime ?? 1200; // Default 20 minutes
      final pauseDurationTime =
          event.pauseDurationTime ?? 300; // Default 5 minutes

      add(
        PracticeModeSelected(
          event.category,
          warmupEnabled: warmupEnabled,
          warmupTime: warmupTime,
          warmupBpm: warmupBpm,
          exerciseBpm: exerciseBpm,
          lastSessionId: lastSessionId,
          autoPauseEnabled: autoPauseEnabled,
          pauseIntervalTime: pauseIntervalTime,
          pauseDurationTime: pauseDurationTime,
        ),
      );
    } else if (currentState is SessionActive) {
      // Change category in existing session
      add(SessionCategoryChanged(event.category));
    }
  }

  void _onPracticeModeSelected(
    PracticeModeSelected event,
    Emitter<SessionState> emit,
  ) async {
    final currentState = state;
    if (currentState is SessionInitial) {
      // Create new session and start warmup in one atomic operation
      final sessionId = _clock.nowMilliseconds;

      // Load last session for category inheritance if lastSessionId is provided
      Session? lastSession;
      if (event.lastSessionId.isNotEmpty) {
        // TODO: Load session by ID from repository
        // For now, we'll implement this later when we have access to the repository
        // lastSession = await _loadSessionById(event.lastSessionId);
      }

      final newSession = Session.getDefault(
        sessionId: sessionId,
        instrument: 'guitar', // Default instrument
        lastSession: lastSession, // Copy category details (except time)
      );

      // Apply BPM preferences to appropriate categories
      final updatedSession = _applyBpmPreferences(newSession, event);

      // Use warmup settings from user preferences
      final warmupEnabled = event.warmupEnabled;
      final warmupTime = event.warmupTime;

      if (warmupEnabled) {
        // Create session in warmup state
        final newState = _createSessionActive(
          session: updatedSession,
          currentPracticeCategory:
              PracticeCategory.exercise, // Placeholder during warmup
          isPaused: true, // Start paused, ready for user to begin
          isInWarmup: true, // Mark as warmup phase
          targetPracticeCategory:
              event.category, // Store target for after warmup
          warmupTime: warmupTime,
          warmupStartedAt: null, // Will be set when user starts timer
          timerDisplaySeconds: warmupTime, // Show warmup countdown initially
          timerIsCountdown: true, // Warmup is countdown mode
          forceUpdate: true,
        );

        _smartEmit(newState, emit, eventName: 'PracticeModeSelected');
      } else {
        // Skip warmup - go directly to practice mode
        final newState = _createSessionActive(
          session: updatedSession,
          currentPracticeCategory: event.category,
          isPaused: true, // Start paused, ready for user to begin
          isInWarmup: false, // No warmup
          timerDisplaySeconds: 0, // Start from 0:00 for practice
          timerIsCountdown: false, // Practice mode counts up
          forceUpdate: true,
        );

        _smartEmit(newState, emit, eventName: 'PracticeModeSelected');
      }

      // Store auto-pause preferences for later use
      _warmupBpm = event.warmupBpm;
    }
  }

  void _onPracticeCategoryDetailChanged(
    PracticeCategoryDetailChanged event,
    Emitter<SessionState> emit,
  ) {
    // Route to existing specific handlers based on field
    switch (event.field) {
      case 'time':
        add(SessionTimeChanged(event.category, event.value as int));
        break;
      case 'note':
        add(SessionNoteChanged(event.category, event.value as String));
        break;
      case 'songs':
        add(
          SessionSongsChanged(
            event.category,
            event.value as Map<String, dynamic>,
          ),
        );
        break;
      case 'links':
        add(SessionLinksChanged(event.category, event.value as List<String>));
        break;
    }
  }

  /// Apply BPM preferences to session categories
  Session _applyBpmPreferences(Session session, PracticeModeSelected event) {
    final categories = <PracticeCategory, SessionCategory>{};

    for (final entry in session.categories.entries) {
      final category = entry.key;
      final sessionCategory = entry.value;

      // Apply exerciseBpm only to Exercise category if no BPM is set
      if (category == PracticeCategory.exercise &&
          sessionCategory.bpm == null) {
        categories[category] = sessionCategory.copyWith(bpm: event.exerciseBpm);
      } else {
        categories[category] = sessionCategory;
      }
    }

    return session.copyWith(categories: categories);
  }
}
