import 'package:bloc_test/bloc_test.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:jazzx_app/bloc/session_bloc.dart';
import 'package:jazzx_app/models/session.dart';
import 'package:jazzx_app/models/practice_category.dart';

void main() {
  group('SessionBloc Simple Tests', () {
    late SessionBloc sessionBloc;
    late Session testSession;

    setUp(() {
      sessionBloc = SessionBloc();
      testSession = Session.getDefault(
        sessionId: 123456789,
        instrument: 'guitar',
      );
    });

    // Helper function for creating PracticeModeSelected events with default settings
    PracticeModeSelected createPracticeModeSelected(
      PracticeCategory category, {
      bool warmupEnabled = true,
      int warmupTime = 1200,
      int warmupBpm = 80,
      int exerciseBpm = 100,
      String lastSessionId = '',
      bool autoPauseEnabled = false,
      int pauseIntervalTime = 1200,
      int pauseDurationTime = 300,
    }) {
      return PracticeModeSelected(
        category,
        warmupEnabled: warmupEnabled,
        warmupTime: warmupTime,
        warmupBpm: warmupBpm,
        exerciseBpm: exerciseBpm,
        lastSessionId: lastSessionId,
        autoPauseEnabled: autoPauseEnabled,
        pauseIntervalTime: pauseIntervalTime,
        pauseDurationTime: pauseDurationTime,
      );
    }

    tearDown(() {
      sessionBloc.close();
    });

    test('initial state is SessionInitial', () {
      expect(sessionBloc.state, isA<SessionInitial>());
    });

    blocTest<SessionBloc, SessionState>(
      'emits SessionActive when SessionStarted is added',
      build: () => sessionBloc,
      act: (bloc) => bloc.add(SessionStarted(testSession)),
      expect:
          () => [
            isA<SessionActive>()
                .having((s) => s.session.started, 'sessionId', 123456789)
                .having(
                  (s) => s.currentPracticeCategory,
                  'category',
                  PracticeCategory.exercise,
                )
                .having((s) => s.timerIsRunning, 'timerIsRunning', false)
                .having((s) => s.timerDisplaySeconds, 'timerDisplaySeconds', 0)
                .having((s) => s.timerIsCountdown, 'timerIsCountdown', false),
          ],
    );

    group('Timer State Management', () {
      blocTest<SessionBloc, SessionState>(
        'timer state starts with default values',
        build: () => sessionBloc,
        act: (bloc) => bloc.add(SessionStarted(testSession)),
        expect:
            () => [
              isA<SessionActive>()
                  .having((s) => s.timerIsRunning, 'timerIsRunning', false)
                  .having(
                    (s) => s.timerDisplaySeconds,
                    'timerDisplaySeconds',
                    0,
                  )
                  .having((s) => s.timerIsCountdown, 'timerIsCountdown', false),
            ],
      );

      blocTest<SessionBloc, SessionState>(
        'TimerStartPressed sets timer running for practice mode (no warmup)',
        build: () => sessionBloc,
        act: (bloc) async {
          bloc.add(SessionStarted(testSession));
          await Future.delayed(Duration(milliseconds: 10));
          bloc.add(TimerStartPressed());
        },
        expect:
            () => [
              // SessionStarted
              isA<SessionActive>()
                  .having((s) => s.isInWarmup, 'isInWarmup', false)
                  .having((s) => s.timerIsRunning, 'timerIsRunning', false),
              // TimerStartPressed (starts practice timer)
              isA<SessionActive>()
                  .having((s) => s.timerIsRunning, 'timerIsRunning', true)
                  .having(
                    (s) => s.timerIsCountdown,
                    'timerIsCountdown',
                    false,
                  ) // Count up for practice
                  .having(
                    (s) => s.timerDisplaySeconds,
                    'timerDisplaySeconds',
                    0,
                  ), // Start from 0
            ],
      );

      blocTest<SessionBloc, SessionState>(
        'PracticeModeSelected immediately shows 20:00 timer display',
        build: () => sessionBloc,
        act: (bloc) {
          // Start from SessionInitial and use PracticeModeSelected to create session with warmup
          bloc.add(createPracticeModeSelected(PracticeCategory.exercise));
        },
        expect:
            () => [
              // PracticeModeSelected should immediately show 20:00 (1200 seconds) in warmup mode
              isA<SessionActive>()
                  .having((s) => s.isInWarmup, 'isInWarmup', true)
                  .having((s) => s.isPaused, 'isPaused', true)
                  .having((s) => s.timerIsRunning, 'timerIsRunning', false)
                  .having((s) => s.timerIsCountdown, 'timerIsCountdown', true)
                  .having(
                    (s) => s.timerDisplaySeconds,
                    'timerDisplaySeconds',
                    1200,
                  ), // Should show 20:00 immediately
            ],
      );

      blocTest<SessionBloc, SessionState>(
        'PracticeModeSelected starts warmup mode with timer setup',
        build: () => sessionBloc,
        act: (bloc) async {
          // Start from SessionInitial and use PracticeModeSelected to create session with warmup
          bloc.add(createPracticeModeSelected(PracticeCategory.exercise));
          await Future.delayed(Duration(milliseconds: 10));
          bloc.add(TimerStartPressed());
        },
        expect:
            () => [
              // PracticeModeSelected (creates session in warmup)
              isA<SessionActive>()
                  .having((s) => s.isInWarmup, 'isInWarmup', true)
                  .having((s) => s.isPaused, 'isPaused', true),
              // TimerStartPressed (starts warmup countdown)
              isA<SessionActive>()
                  .having((s) => s.timerIsRunning, 'timerIsRunning', true)
                  .having((s) => s.timerIsCountdown, 'timerIsCountdown', true)
                  .having(
                    (s) => s.timerDisplaySeconds,
                    'timerDisplaySeconds',
                    1200,
                  ), // 20 minutes
            ],
      );

      blocTest<SessionBloc, SessionState>(
        'TimerSkipPressed during warmup transitions to practice without pausing',
        build: () => sessionBloc,
        act: (bloc) async {
          // Start warmup
          bloc.add(createPracticeModeSelected(PracticeCategory.exercise));
          await Future.delayed(Duration(milliseconds: 10));
          bloc.add(TimerStartPressed());
          await Future.delayed(Duration(milliseconds: 10));

          // Skip warmup - should transition to practice mode without pausing
          bloc.add(TimerSkipPressed());
        },
        expect:
            () => [
              // PracticeModeSelected (creates session in warmup)
              isA<SessionActive>()
                  .having((s) => s.isInWarmup, 'isInWarmup', true)
                  .having((s) => s.isPaused, 'isPaused', true),
              // TimerStartPressed (starts warmup countdown)
              isA<SessionActive>()
                  .having((s) => s.timerIsRunning, 'timerIsRunning', true)
                  .having((s) => s.timerIsCountdown, 'timerIsCountdown', true),
              // TimerSkipPressed (transitions to practice mode)
              isA<SessionActive>()
                  .having((s) => s.isInWarmup, 'isInWarmup', false)
                  .having(
                    (s) => s.isPaused,
                    'isPaused',
                    false,
                  ) // Should NOT be paused
                  .having((s) => s.timerIsRunning, 'timerIsRunning', true)
                  .having((s) => s.timerIsCountdown, 'timerIsCountdown', false)
                  .having(
                    (s) => s.timerDisplaySeconds,
                    'timerDisplaySeconds',
                    0,
                  ), // Should show 00:00:00
            ],
      );

      blocTest<SessionBloc, SessionState>(
        'Warmup to practice transition shows correct timer display',
        build: () => sessionBloc,
        act: (bloc) async {
          // Start warmup and let it run for a bit
          bloc.add(createPracticeModeSelected(PracticeCategory.newsong));
          await Future.delayed(Duration(milliseconds: 10));
          bloc.add(TimerStartPressed());
          await Future.delayed(Duration(milliseconds: 10));

          // Skip warmup after some elapsed time
          bloc.add(TimerSkipPressed());
        },
        expect:
            () => [
              // PracticeModeSelected (creates session in warmup)
              isA<SessionActive>()
                  .having((s) => s.isInWarmup, 'isInWarmup', true)
                  .having(
                    (s) => s.currentPracticeCategory,
                    'currentPracticeCategory',
                    PracticeCategory.exercise,
                  ) // Placeholder during warmup
                  .having(
                    (s) => s.targetPracticeCategory,
                    'targetPracticeCategory',
                    PracticeCategory.newsong,
                  ), // Target after warmup
              // TimerStartPressed (starts warmup countdown)
              isA<SessionActive>().having(
                (s) => s.timerIsRunning,
                'timerIsRunning',
                true,
              ),
              // TimerSkipPressed (transitions to target practice category)
              isA<SessionActive>()
                  .having((s) => s.isInWarmup, 'isInWarmup', false)
                  .having(
                    (s) => s.currentPracticeCategory,
                    'currentPracticeCategory',
                    PracticeCategory.newsong,
                  ) // Should switch to target
                  .having(
                    (s) => s.targetPracticeCategory,
                    'targetPracticeCategory',
                    null,
                  ) // Should clear target
                  .having(
                    (s) => s.timerDisplaySeconds,
                    'timerDisplaySeconds',
                    0,
                  ) // Should show 00:00:00 for practice
                  .having(
                    (s) => s.timerIsCountdown,
                    'timerIsCountdown',
                    false,
                  ) // Practice counts up
                  .having(
                    (s) => s.timerIsRunning,
                    'timerIsRunning',
                    true,
                  ), // Should auto-start
            ],
      );

      blocTest<SessionBloc, SessionState>(
        'Timer ticks correctly without performance lag',
        build: () => sessionBloc,
        act: (bloc) async {
          // Start practice mode (skip warmup for faster test)
          bloc.add(createPracticeModeSelected(PracticeCategory.exercise));
          await Future.delayed(Duration(milliseconds: 10));
          bloc.add(
            TimerSkipPressed(),
          ); // Skip warmup to go directly to practice
          await Future.delayed(Duration(milliseconds: 10));

          // Simulate timer ticks manually (BLoC timer would normally do this)
          bloc.add(TimerTick(newDisplaySeconds: 1));
          bloc.add(TimerTick(newDisplaySeconds: 2));
          bloc.add(TimerTick(newDisplaySeconds: 3));
        },
        expect:
            () => [
              // PracticeModeSelected (creates session in warmup)
              isA<SessionActive>().having(
                (s) => s.isInWarmup,
                'isInWarmup',
                true,
              ),
              // TimerSkipPressed (transitions to practice mode)
              isA<SessionActive>()
                  .having((s) => s.isInWarmup, 'isInWarmup', false)
                  .having(
                    (s) => s.timerDisplaySeconds,
                    'timerDisplaySeconds',
                    0,
                  ),
              // TimerTick 1 second
              isA<SessionActive>().having(
                (s) => s.timerDisplaySeconds,
                'timerDisplaySeconds',
                1,
              ),
              // TimerTick 2 seconds
              isA<SessionActive>().having(
                (s) => s.timerDisplaySeconds,
                'timerDisplaySeconds',
                2,
              ),
              // TimerTick 3 seconds
              isA<SessionActive>().having(
                (s) => s.timerDisplaySeconds,
                'timerDisplaySeconds',
                3,
              ),
            ],
      );

      blocTest<SessionBloc, SessionState>(
        'Category change during practice pauses session and stops timer',
        build: () => sessionBloc,
        act: (bloc) async {
          // Start practice mode (skip warmup for faster test)
          bloc.add(createPracticeModeSelected(PracticeCategory.exercise));
          await Future.delayed(Duration(milliseconds: 10));
          bloc.add(
            TimerSkipPressed(),
          ); // Skip warmup to go directly to practice
          await Future.delayed(Duration(milliseconds: 10));

          // Change category while timer is running - should pause and stop timer
          bloc.add(CategorySelected(PracticeCategory.newsong));
        },
        expect:
            () => [
              // PracticeModeSelected (creates session in warmup)
              isA<SessionActive>().having(
                (s) => s.isInWarmup,
                'isInWarmup',
                true,
              ),
              // TimerSkipPressed (transitions to practice mode with running timer)
              isA<SessionActive>()
                  .having((s) => s.isInWarmup, 'isInWarmup', false)
                  .having((s) => s.timerIsRunning, 'timerIsRunning', true)
                  .having(
                    (s) => s.currentPracticeCategory,
                    'currentPracticeCategory',
                    PracticeCategory.exercise,
                  ),
              // CategorySelected (changes category and pauses session)
              isA<SessionActive>()
                  .having(
                    (s) => s.isPaused,
                    'isPaused',
                    true,
                  ) // Should be paused
                  .having(
                    (s) => s.timerIsRunning,
                    'timerIsRunning',
                    false,
                  ) // Timer should be stopped
                  .having(
                    (s) => s.currentPracticeCategory,
                    'currentPracticeCategory',
                    PracticeCategory.newsong,
                  ) // Should switch category
                  .having(
                    (s) => s.timerDisplaySeconds,
                    'timerDisplaySeconds',
                    0,
                  ), // Should show 00:00:00 for new category
            ],
      );

      blocTest<SessionBloc, SessionState>(
        'TimerStopPressed stops timer',
        build: () => sessionBloc,
        act: (bloc) async {
          bloc.add(SessionStarted(testSession));
          await Future.delayed(Duration(milliseconds: 10));
          bloc.add(TimerStartPressed());
          await Future.delayed(Duration(milliseconds: 10));
          bloc.add(TimerStopPressed());
        },
        expect:
            () => [
              // SessionStarted
              isA<SessionActive>(),
              // TimerStartPressed
              isA<SessionActive>().having(
                (s) => s.timerIsRunning,
                'timerIsRunning',
                true,
              ),
              // TimerStopPressed
              isA<SessionActive>().having(
                (s) => s.timerIsRunning,
                'timerIsRunning',
                false,
              ),
              // SessionPaused (triggered by TimerStopPressed)
              isA<SessionActive>().having((s) => s.isPaused, 'isPaused', true),
            ],
      );

      blocTest<SessionBloc, SessionState>(
        'TimerTick updates display seconds',
        build: () => sessionBloc,
        act: (bloc) async {
          bloc.add(SessionStarted(testSession));
          await Future.delayed(Duration(milliseconds: 10));
          bloc.add(TimerStartPressed());
          await Future.delayed(Duration(milliseconds: 10));
          bloc.add(
            TimerTick(newDisplaySeconds: 5),
          ); // 5 seconds elapsed in practice
        },
        expect:
            () => [
              // SessionStarted
              isA<SessionActive>(),
              // TimerStartPressed
              isA<SessionActive>().having(
                (s) => s.timerDisplaySeconds,
                'initial',
                0,
              ),
              // TimerTick
              isA<SessionActive>().having(
                (s) => s.timerDisplaySeconds,
                'after tick',
                5,
              ),
            ],
      );

      blocTest<SessionBloc, SessionState>(
        'SessionLoaded shows correct accumulated time in timer display',
        build: () => sessionBloc,
        act: (bloc) async {
          // Create a session with accumulated practice time
          final sessionWithTime = testSession.copyWithCategory(
            PracticeCategory.exercise,
            testSession.categories[PracticeCategory.exercise]!.copyWith(
              time: 300,
            ), // 5 minutes
          );

          // Load the session (simulating "Continue Session" from modal dialog)
          bloc.add(SessionLoaded(sessionWithTime));
        },
        expect:
            () => [
              // SessionLoaded should show accumulated time in timer display
              isA<SessionActive>()
                  .having(
                    (s) => s.currentPracticeCategory,
                    'category',
                    PracticeCategory.exercise,
                  )
                  .having(
                    (s) => s.isPaused,
                    'isPaused',
                    true,
                  ) // Should start paused
                  .having(
                    (s) => s.timerIsRunning,
                    'timerIsRunning',
                    false,
                  ) // Should start stopped
                  .having(
                    (s) => s.timerIsCountdown,
                    'timerIsCountdown',
                    false,
                  ) // Practice mode counts up
                  .having(
                    (s) => s.timerDisplaySeconds,
                    'timerDisplaySeconds',
                    300,
                  ) // Should show 5 minutes (300 seconds)
                  .having(
                    (s) =>
                        s.session.categories[PracticeCategory.exercise]?.time,
                    'session exercise time',
                    300,
                  ), // Verify session has the correct time
            ],
      );

      blocTest<SessionBloc, SessionState>(
        'SessionLoaded with multiple categories shows time for first category',
        build: () => sessionBloc,
        act: (bloc) async {
          // Create a session with time in multiple categories
          final sessionWithMultipleTime = testSession
              .copyWithCategory(
                PracticeCategory.exercise,
                testSession.categories[PracticeCategory.exercise]!.copyWith(
                  time: 180,
                ), // 3 minutes
              )
              .copyWithCategory(
                PracticeCategory.newsong,
                testSession.categories[PracticeCategory.newsong]!.copyWith(
                  time: 240,
                ), // 4 minutes
              );

          // Load the session
          bloc.add(SessionLoaded(sessionWithMultipleTime));
        },
        expect:
            () => [
              // SessionLoaded should show time for first category (Exercise = 180 seconds)
              isA<SessionActive>()
                  .having(
                    (s) => s.currentPracticeCategory,
                    'category',
                    PracticeCategory.exercise,
                  )
                  .having(
                    (s) => s.timerDisplaySeconds,
                    'timerDisplaySeconds',
                    180,
                  ), // Should show Exercise time (3 minutes)
            ],
      );

      blocTest<SessionBloc, SessionState>(
        'SessionSaved emits SessionSavedState for proper BLoC architecture',
        build: () => sessionBloc,
        act: (bloc) async {
          // Create a session with some practice time
          final sessionToSave = testSession.copyWithCategory(
            PracticeCategory.exercise,
            testSession.categories[PracticeCategory.exercise]!.copyWith(
              time: 300,
            ), // 5 minutes
          );

          // Trigger SessionSaved event (this should be called from UI instead of direct save)
          bloc.add(SessionSaved(sessionToSave));
        },
        expect:
            () => [
              // SessionSaved should emit SessionSavedState
              isA<SessionSavedState>().having(
                (s) => s.session,
                'session',
                isA<Session>().having(
                  (session) =>
                      session.categories[PracticeCategory.exercise]?.time,
                  'exercise time',
                  300,
                ),
              ),
            ],
      );

      blocTest<SessionBloc, SessionState>(
        'timer switches to practice mode after warmup completion',
        build: () => sessionBloc,
        act: (bloc) async {
          // Start from SessionInitial and create session with warmup
          bloc.add(createPracticeModeSelected(PracticeCategory.exercise));
          await Future.delayed(Duration(milliseconds: 10));
          bloc.add(TimerStartPressed());
          await Future.delayed(Duration(milliseconds: 10));
          // Skip warmup to enter practice mode
          bloc.add(TimerSkipPressed());
          await Future.delayed(Duration(milliseconds: 10));
          // Start practice timer
          bloc.add(TimerStartPressed());
        },
        expect:
            () => [
              // PracticeModeSelected (warmup)
              isA<SessionActive>().having(
                (s) => s.isInWarmup,
                'isInWarmup',
                true,
              ),
              // TimerStartPressed (warmup)
              isA<SessionActive>()
                  .having((s) => s.timerIsRunning, 'timerIsRunning', true)
                  .having((s) => s.timerIsCountdown, 'timerIsCountdown', true),
              // TimerSkipPressed (skip warmup) - this will trigger multiple state changes
              isA<SessionActive>().having(
                (s) => s.isInWarmup,
                'isInWarmup',
                false,
              ),
              // TimerStartPressed (practice mode)
              isA<SessionActive>()
                  .having((s) => s.timerIsRunning, 'timerIsRunning', true)
                  .having(
                    (s) => s.timerIsCountdown,
                    'timerIsCountdown',
                    false,
                  ) // Count up for practice
                  .having(
                    (s) => s.timerDisplaySeconds,
                    'timerDisplaySeconds',
                    0,
                  ), // Start from 0
            ],
      );

      blocTest<SessionBloc, SessionState>(
        'timer resumes with accumulated time in practice mode',
        build: () => sessionBloc,
        act: (bloc) async {
          // Create session with some accumulated practice time
          final sessionWithTime = testSession.copyWithCategory(
            PracticeCategory.exercise,
            testSession.categories[PracticeCategory.exercise]!.copyWith(
              time: 150,
            ), // 2:30
          );

          bloc.add(SessionStarted(sessionWithTime));
          await Future.delayed(Duration(milliseconds: 10));
          // Start practice timer directly - should show accumulated time
          bloc.add(TimerStartPressed());
        },
        expect:
            () => [
              // SessionStarted
              isA<SessionActive>(),
              // TimerStartPressed (practice with accumulated time)
              isA<SessionActive>()
                  .having(
                    (s) => s.timerDisplaySeconds,
                    'accumulated time',
                    150,
                  ) // Shows 2:30
                  .having((s) => s.timerIsCountdown, 'count up', false),
            ],
      );
    });

    blocTest<SessionBloc, SessionState>(
      'skip warmup functionality works',
      build: () => sessionBloc,
      seed:
          () => SessionActive(
            session: testSession,
            currentPracticeCategory: PracticeCategory.exercise,
            isInWarmup: true,
            targetPracticeCategory: PracticeCategory.newsong,
            warmupTime: 1200,
          ),
      act: (bloc) => bloc.add(SessionWarmupSkipped(actualWarmupTime: 600)),
      expect:
          () => [
            isA<SessionActive>()
                .having((s) => s.isInWarmup, 'isInWarmup', false)
                .having(
                  (s) => s.currentPracticeCategory,
                  'category',
                  PracticeCategory.newsong,
                )
                .having((s) => s.session.warmup, 'warmup', isNotNull)
                .having((s) => s.session.warmup?.time, 'warmupTime', 600),
          ],
    );

    blocTest<SessionBloc, SessionState>(
      'skip break functionality works',
      build: () => sessionBloc,
      seed:
          () => SessionActive(
            session: testSession,
            currentPracticeCategory: PracticeCategory.exercise,
            isPaused: false,
            isOnBreak: true,
          ),
      act: (bloc) => bloc.add(SessionBreakSkipped()),
      expect:
          () => [
            isA<SessionActive>()
                .having((s) => s.isOnBreak, 'isOnBreak', false)
                .having((s) => s.isPaused, 'isPaused', false)
                .having(
                  (s) => s.autoPauseStartTime,
                  'autoPauseStartTime',
                  isNotNull,
                ),
          ],
    );

    blocTest<SessionBloc, SessionState>(
      'SessionAutoSaveWithDraft emits proper state for BLoC auto-save architecture',
      build: () => sessionBloc,
      act: (bloc) async {
        // Start a session first
        bloc.add(SessionStarted(testSession));
        await Future.delayed(Duration(milliseconds: 10));

        // Trigger auto-save with draft
        bloc.add(SessionAutoSaveWithDraft());
      },
      expect:
          () => [
            // SessionStarted
            isA<SessionActive>(),
            // SessionAutoSaveWithDraft should emit draft state then return to active
            isA<SessionAutoSaveWithDraftState>(),
            isA<SessionActive>(),
          ],
    );

    blocTest<SessionBloc, SessionState>(
      'SessionInitialize emits SessionInitializeState for proper initialization',
      build: () => sessionBloc,
      act: (bloc) async {
        // Trigger initialization
        bloc.add(SessionInitialize());
      },
      expect:
          () => [
            // SessionInitialize should emit SessionInitializeState
            isA<SessionInitializeState>(),
          ],
    );

    blocTest<SessionBloc, SessionState>(
      'PracticeModeSelected respects user warmup preferences - 10 minutes',
      build: () => sessionBloc,
      act: (bloc) async {
        // Test with 10 minutes warmup (600 seconds) instead of default 20 minutes
        bloc.add(
          createPracticeModeSelected(
            PracticeCategory.exercise,
            warmupEnabled: true,
            warmupTime: 600,
          ),
        );
      },
      expect:
          () => [
            // Should create session with 10 minutes warmup time
            isA<SessionActive>()
                .having((s) => s.isInWarmup, 'isInWarmup', true)
                .having((s) => s.warmupTime, 'warmupTime', 600) // 10 minutes
                .having(
                  (s) => s.timerDisplaySeconds,
                  'timerDisplaySeconds',
                  600,
                ) // Should show 10:00
                .having((s) => s.timerIsCountdown, 'timerIsCountdown', true),
          ],
    );

    blocTest<SessionBloc, SessionState>(
      'PracticeModeSelected respects user warmup preferences - disabled',
      build: () => sessionBloc,
      act: (bloc) async {
        // Test with warmup disabled
        bloc.add(
          createPracticeModeSelected(
            PracticeCategory.exercise,
            warmupEnabled: false,
            warmupTime: 600,
          ),
        );
      },
      expect:
          () => [
            // Should skip warmup and go directly to practice mode
            isA<SessionActive>()
                .having((s) => s.isInWarmup, 'isInWarmup', false)
                .having(
                  (s) => s.currentPracticeCategory,
                  'currentPracticeCategory',
                  PracticeCategory.exercise,
                )
                .having(
                  (s) => s.timerDisplaySeconds,
                  'timerDisplaySeconds',
                  0,
                ) // Should show 0:00
                .having(
                  (s) => s.timerIsCountdown,
                  'timerIsCountdown',
                  false,
                ), // Practice mode counts up
          ],
    );

    blocTest<SessionBloc, SessionState>(
      'PracticeModeSelected applies exerciseBpm to Exercise category only',
      build: () => sessionBloc,
      act: (bloc) async {
        // Test with custom exercise BPM
        bloc.add(
          createPracticeModeSelected(
            PracticeCategory.exercise,
            warmupEnabled: false,
            exerciseBpm: 120, // Custom BPM for exercise
          ),
        );
      },
      expect:
          () => [
            // Should apply exerciseBpm to Exercise category
            isA<SessionActive>().having(
              (s) => s.session.categories[PracticeCategory.exercise]?.bpm,
              'exercise category BPM',
              120,
            ),
          ],
    );
  });
}
