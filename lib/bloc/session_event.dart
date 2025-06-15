part of 'session_bloc.dart';

abstract class SessionEvent extends Equatable {
  @override
  List<Object?> get props => [];
}

class SessionWarmupCompleted extends SessionEvent {
  final int actualWarmupTime; // Actual time spent in warmup
  SessionWarmupCompleted({required this.actualWarmupTime});
  @override
  List<Object?> get props => [actualWarmupTime];
}

class SessionWarmupStarted extends SessionEvent {
  final PracticeCategory targetCategory;
  final int warmupTime;
  SessionWarmupStarted({
    required this.targetCategory,
    required this.warmupTime,
  });
  @override
  List<Object?> get props => [targetCategory, warmupTime];
}

class SessionStarted extends SessionEvent {
  final Session session;
  SessionStarted(this.session);
  @override
  List<Object?> get props => [session];
}

class SessionCategoryChanged extends SessionEvent {
  final PracticeCategory currentPracticeCategory;
  // No currentElapsedSeconds needed - we use timestamps now
  SessionCategoryChanged(this.currentPracticeCategory);
  @override
  List<Object?> get props => [currentPracticeCategory];
}

class SessionPaused extends SessionEvent {
  // No parameters needed - we'll use timestamps to calculate elapsed time
  SessionPaused();
  @override
  List<Object?> get props => [];
}

class SessionResumed extends SessionEvent {
  @override
  List<Object?> get props => [];
}

class SessionUpdated extends SessionEvent {
  final Session session;
  SessionUpdated(this.session);
  @override
  List<Object?> get props => [session];
}

class SessionCompleted extends SessionEvent {
  // No parameters needed - we'll use timestamps to calculate elapsed time
  SessionCompleted();
  @override
  List<Object?> get props => [];
}

class SessionDiscarded extends SessionEvent {
  @override
  List<Object?> get props => [];
}

class SessionDraftSaved extends SessionEvent {
  final Session session;
  SessionDraftSaved(this.session);
  @override
  List<Object?> get props => [session];
}

class SessionSaved extends SessionEvent {
  final Session session;
  SessionSaved(this.session);
  @override
  List<Object?> get props => [session];
}

class SessionLoaded extends SessionEvent {
  final Session? session;
  SessionLoaded([this.session]);
  @override
  List<Object?> get props => [session];
}

class SessionWarmupChanged extends SessionEvent {
  final int warmupTime;
  SessionWarmupChanged(this.warmupTime);
  @override
  List<Object?> get props => [warmupTime];
}

class SessionAutoPauseChanged extends SessionEvent {
  final bool isOnBreak;
  SessionAutoPauseChanged(this.isOnBreak);
  @override
  List<Object?> get props => [isOnBreak];
}

class SessionNoteChanged extends SessionEvent {
  final PracticeCategory category;
  final String note;
  SessionNoteChanged(this.category, this.note);
  @override
  List<Object?> get props => [category, note];
}

class SessionLinksChanged extends SessionEvent {
  final PracticeCategory category;
  final List<String> links;
  SessionLinksChanged(this.category, this.links);
  @override
  List<Object?> get props => [category, links];
}

class SessionSongsChanged extends SessionEvent {
  final PracticeCategory category;
  final Map<String, dynamic> songs;
  SessionSongsChanged(this.category, this.songs);
  @override
  List<Object?> get props => [category, songs];
}

class SessionTimeChanged extends SessionEvent {
  final PracticeCategory category;
  final int seconds;
  SessionTimeChanged(this.category, this.seconds);
  @override
  List<Object?> get props => [category, seconds];
}

class SessionAutoSave extends SessionEvent {
  final int?
  currentElapsedSeconds; // Current elapsed time to save before auto-save
  SessionAutoSave({this.currentElapsedSeconds});
  @override
  List<Object?> get props => [currentElapsedSeconds];
}

class SessionAutoSaveWithDraft extends SessionEvent {
  @override
  List<Object?> get props => [];
}

class SessionInitialize extends SessionEvent {
  @override
  List<Object?> get props => [];
}

class SessionWarmupSkipped extends SessionEvent {
  final int actualWarmupTime; // Time spent before skipping
  SessionWarmupSkipped({required this.actualWarmupTime});
  @override
  List<Object?> get props => [actualWarmupTime];
}

class SessionBreakSkipped extends SessionEvent {
  SessionBreakSkipped();
  @override
  List<Object?> get props => [];
}

// ============================================================================
// CLEAN WIDGET EVENTS - Emitted by widgets, handled by SessionBloc
// ============================================================================

// Clean Timer Events - emitted by PracticeTimerWidget
class TimerStartPressed extends SessionEvent {
  @override
  List<Object?> get props => [];
}

class TimerStopPressed extends SessionEvent {
  @override
  List<Object?> get props => [];
}

class TimerSkipPressed extends SessionEvent {
  @override
  List<Object?> get props => [];
}

class TimerDonePressed extends SessionEvent {
  @override
  List<Object?> get props => [];
}

class TimerTick extends SessionEvent {
  final int newDisplaySeconds;
  TimerTick({required this.newDisplaySeconds});
  @override
  List<Object?> get props => [newDisplaySeconds];
}

// Clean Category Events - emitted by PracticeModeButtons
class CategorySelected extends SessionEvent {
  final PracticeCategory category;
  final bool? warmupEnabled; // Optional - only needed for new sessions
  final int? warmupTime; // Optional - only needed for new sessions
  final int? warmupBpm; // Optional - only needed for new sessions
  final int? exerciseBpm; // Optional - only needed for new sessions
  final String? lastSessionId; // Optional - only needed for new sessions
  final bool? autoPauseEnabled; // Optional - only needed for new sessions
  final int? pauseIntervalTime; // Optional - only needed for new sessions
  final int? pauseDurationTime; // Optional - only needed for new sessions

  CategorySelected(
    this.category, {
    this.warmupEnabled,
    this.warmupTime,
    this.warmupBpm,
    this.exerciseBpm,
    this.lastSessionId,
    this.autoPauseEnabled,
    this.pauseIntervalTime,
    this.pauseDurationTime,
  });

  @override
  List<Object?> get props => [
    category,
    warmupEnabled,
    warmupTime,
    warmupBpm,
    exerciseBpm,
    lastSessionId,
    autoPauseEnabled,
    pauseIntervalTime,
    pauseDurationTime,
  ];
}

// Practice Mode Selection - handles complete flow (session creation + warmup)
class PracticeModeSelected extends SessionEvent {
  final PracticeCategory category;
  final bool warmupEnabled;
  final int warmupTime; // in seconds
  final int warmupBpm;
  final int exerciseBpm;
  final String lastSessionId; // for copying category details
  final bool autoPauseEnabled;
  final int pauseIntervalTime; // in seconds
  final int pauseDurationTime; // in seconds

  PracticeModeSelected(
    this.category, {
    required this.warmupEnabled,
    required this.warmupTime,
    required this.warmupBpm,
    required this.exerciseBpm,
    required this.lastSessionId,
    required this.autoPauseEnabled,
    required this.pauseIntervalTime,
    required this.pauseDurationTime,
  });

  @override
  List<Object?> get props => [
    category,
    warmupEnabled,
    warmupTime,
    warmupBpm,
    exerciseBpm,
    lastSessionId,
    autoPauseEnabled,
    pauseIntervalTime,
    pauseDurationTime,
  ];
}

// Clean Detail Events - emitted by PracticeDetailWidget
class PracticeCategoryDetailChanged extends SessionEvent {
  final PracticeCategory category;
  final String field; // 'time', 'note', 'songs', 'links'
  final dynamic value;

  PracticeCategoryDetailChanged({
    required this.category,
    required this.field,
    required this.value,
  });

  @override
  List<Object?> get props => [category, field, value];
}
