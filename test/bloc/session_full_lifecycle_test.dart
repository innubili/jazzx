// ignore_for_file: avoid_print

import 'package:flutter_test/flutter_test.dart';

import 'package:jazzx_app/bloc/session_bloc.dart';
import 'package:jazzx_app/core/time/app_clock.dart';
import 'package:jazzx_app/models/practice_category.dart';
import 'package:jazzx_app/models/session.dart';

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

void main() {
  group('Session Full Lifecycle Tests', () {
    /// Reusable test function for different session configurations
    Future<void> runSessionLifecycleTest({
      required String testName,
      required bool warmupEnabled,
      required bool autoPauseEnabled,
      Session? initialSession,
    }) async {
      print('\n🎯 Testing: $testName');
      print('   📋 Warmup: ${warmupEnabled ? "ENABLED" : "DISABLED"}');
      print('   ⏸️  Auto-pause: ${autoPauseEnabled ? "ENABLED" : "DISABLED"}');
      print(
        '   📂 Initial session: ${initialSession != null ? "EXISTING" : "NEW"}',
      );

      const baseTime = 1700000000;
      var clock = ControllableClock(baseTime * 1000);
      final sessionBloc = SessionBloc(clock: clock);

      try {
        SessionActive state;

        // ========================================================================
        // INITIALIZATION: Handle different starting scenarios
        // ========================================================================
        if (initialSession != null) {
          // Start with existing/aborted session
          sessionBloc.add(SessionLoaded(initialSession));
          await Future.delayed(Duration(milliseconds: 10));

          state = sessionBloc.state as SessionActive;
          print(
            '✅ Loaded existing session with ${initialSession.categories.length} categories',
          );
        } else {
          // Start new session
          sessionBloc.add(
            createPracticeModeSelected(
              PracticeCategory.exercise,
              warmupEnabled: warmupEnabled,
              autoPauseEnabled: autoPauseEnabled,
            ),
          );
          await Future.delayed(Duration(milliseconds: 10));

          state = sessionBloc.state as SessionActive;
          print('✅ Created new session');
        }

        // ========================================================================
        // PHASE 1: WARMUP LIFECYCLE (if enabled)
        // ========================================================================
        if (warmupEnabled) {
          print('\n📋 PHASE 1: WARMUP LIFECYCLE');

          if (initialSession == null) {
            // New session starts in warmup
            expect(state.isInWarmup, true);
            expect(state.isPaused, true);
            print('✅ Session started in warmup mode');

            // Start warmup
            sessionBloc.add(TimerStartPressed());
            await Future.delayed(Duration(milliseconds: 10));

            state = sessionBloc.state as SessionActive;
            expect(state.isInWarmup, true);
            expect(state.isPaused, false);
            print('✅ Warmup started');

            // Run warmup for 5 minutes, then complete
            clock.advanceMinutes(5);
            sessionBloc.add(TimerSkipPressed()); // Skip warmup
            await Future.delayed(Duration(milliseconds: 10));

            state = sessionBloc.state as SessionActive;
            expect(state.isInWarmup, false);
            expect(state.session.warmup?.time, equals(300)); // 5 minutes
            print('✅ Warmup completed: 5 minutes saved');
          } else {
            // Existing session may already have warmup data
            final existingWarmup = state.session.warmup?.time ?? 0;
            print('✅ Existing session warmup: ${existingWarmup}s');
          }
        } else {
          print('\n📋 PHASE 1: WARMUP SKIPPED (disabled)');

          if (state.isInWarmup) {
            // Skip warmup immediately
            sessionBloc.add(TimerSkipPressed());
            await Future.delayed(Duration(milliseconds: 10));

            state = sessionBloc.state as SessionActive;
            expect(state.isInWarmup, false);
            print('✅ Warmup skipped');
          }
        }

        // ========================================================================
        // PHASE 2: PRACTICE LIFECYCLE
        // ========================================================================
        print('\n📋 PHASE 2: PRACTICE LIFECYCLE');

        // Ensure we're in practice mode
        expect(state.isInWarmup, false);
        expect(state.currentPracticeCategory, isNotNull);

        // For existing sessions, we need to set the current category first
        if (initialSession != null) {
          sessionBloc.add(SessionCategoryChanged(PracticeCategory.exercise));
          await Future.delayed(Duration(milliseconds: 10));
          state = sessionBloc.state as SessionActive;
          print('✅ Set current category for existing session');
        }

        // Start practice if paused
        if (state.isPaused) {
          sessionBloc.add(TimerStartPressed());
          await Future.delayed(Duration(milliseconds: 10));
          state = sessionBloc.state as SessionActive;
        }

        // Practice for 10 minutes
        final initialExerciseTime =
            state.session.categories[PracticeCategory.exercise]?.time ?? 0;
        clock.advanceMinutes(10);
        sessionBloc.add(SessionPaused());
        await Future.delayed(Duration(milliseconds: 10));

        state = sessionBloc.state as SessionActive;
        final expectedExerciseTime = initialExerciseTime + 600; // +10 minutes
        expect(
          state.session.categories[PracticeCategory.exercise]?.time,
          equals(expectedExerciseTime),
        );
        print(
          '✅ Exercise practiced for 10 minutes (total: ${expectedExerciseTime}s)',
        );

        // ========================================================================
        // PHASE 3: AUTO-PAUSE BREAK LIFECYCLE (if enabled)
        // ========================================================================
        if (autoPauseEnabled) {
          print('\n📋 PHASE 3: AUTO-PAUSE BREAK LIFECYCLE');

          // Simulate auto-pause break trigger
          sessionBloc.add(SessionAutoPauseChanged(true));
          await Future.delayed(Duration(milliseconds: 10));

          state = sessionBloc.state as SessionActive;
          expect(state.isOnBreak, true);
          expect(state.isPaused, true);
          print('✅ Auto-pause break started');

          // Start break countdown
          sessionBloc.add(TimerStartPressed());
          await Future.delayed(Duration(milliseconds: 10));

          state = sessionBloc.state as SessionActive;
          expect(state.isOnBreak, true);
          expect(state.isPaused, false);
          print('✅ Break countdown started');

          // Break runs for 2 minutes, then skip
          clock.advanceMinutes(2);
          sessionBloc.add(TimerSkipPressed()); // Skip break
          await Future.delayed(Duration(milliseconds: 10));

          state = sessionBloc.state as SessionActive;
          expect(state.isOnBreak, false);
          expect(state.isPaused, false);
          print('✅ Break skipped after 2 minutes, back to practice');
        } else {
          print('\n📋 PHASE 3: AUTO-PAUSE DISABLED');
          print('✅ No break lifecycle needed');
        }

        // ========================================================================
        // PHASE 4: PRACTICE MODE CHANGE DURING SESSION
        // ========================================================================
        print('\n📋 PHASE 4: PRACTICE MODE CHANGE');

        // Practice Exercise for 3 more minutes
        if (!state.isPaused) {
          // If we're running from break skip, we need to pause first
          clock.advanceMinutes(3);
          sessionBloc.add(SessionPaused());
          await Future.delayed(Duration(milliseconds: 10));

          state = sessionBloc.state as SessionActive;
          final finalExerciseTime =
              expectedExerciseTime + 180; // +3 more minutes
          expect(
            state.session.categories[PracticeCategory.exercise]?.time,
            equals(finalExerciseTime),
          );
          print(
            '✅ Exercise total: ${finalExerciseTime}s (${finalExerciseTime ~/ 60} min)',
          );
        }

        // Pause before changing category (if not already paused)
        if (!state.isPaused) {
          sessionBloc.add(SessionPaused());
          await Future.delayed(Duration(milliseconds: 10));
          state = sessionBloc.state as SessionActive;
          print('✅ Paused before category change');
        }

        // Change to New Song mode
        sessionBloc.add(SessionCategoryChanged(PracticeCategory.newsong));
        await Future.delayed(Duration(milliseconds: 10));

        state = sessionBloc.state as SessionActive;
        expect(state.currentPracticeCategory, PracticeCategory.newsong);
        expect(state.isPaused, true);
        print('✅ Changed to New Song mode');

        // Practice New Song for 7 minutes
        sessionBloc.add(TimerStartPressed());
        await Future.delayed(Duration(milliseconds: 10));

        clock.advanceMinutes(7);
        sessionBloc.add(SessionPaused());
        await Future.delayed(Duration(milliseconds: 10));

        state = sessionBloc.state as SessionActive;
        final initialNewSongTime =
            initialSession?.categories[PracticeCategory.newsong]?.time ?? 0;
        final expectedNewSongTime = initialNewSongTime + 420; // +7 minutes
        expect(
          state.session.categories[PracticeCategory.newsong]?.time,
          equals(expectedNewSongTime),
        );
        print(
          '✅ New Song practiced for 7 minutes (total: ${expectedNewSongTime}s)',
        );

        // ========================================================================
        // PHASE 5: SESSION COMPLETION
        // ========================================================================
        print('\n📋 PHASE 5: SESSION COMPLETION');

        // Complete the session
        sessionBloc.add(SessionCompleted());
        await Future.delayed(Duration(milliseconds: 10));

        final completedState = sessionBloc.state as SessionCompletedState;
        final session = completedState.session;

        // Calculate expected totals
        final warmupTime = session.warmup?.time ?? 0;
        final exerciseTime =
            session.categories[PracticeCategory.exercise]?.time ?? 0;
        final newSongTime =
            session.categories[PracticeCategory.newsong]?.time ?? 0;
        final expectedTotal = warmupTime + exerciseTime + newSongTime;

        expect(session.duration, equals(expectedTotal));

        print('✅ Session completed successfully!');
        print('📊 Final session summary:');
        print('   🔥 Warmup: ${warmupTime}s (${warmupTime ~/ 60} min)');
        print('   🎸 Exercise: ${exerciseTime}s (${exerciseTime ~/ 60} min)');
        print('   🎵 New Song: ${newSongTime}s (${newSongTime ~/ 60} min)');
        print(
          '   ⏱️  Total: ${session.duration}s (${session.duration ~/ 60} min)',
        );
        print('   📅 Session ID: ${session.id}');

        print('\n🎉 FULL LIFECYCLE TEST SUCCESSFUL: $testName');
        print('   ✅ Warmup lifecycle complete');
        print('   ✅ Practice with time tracking working');
        if (autoPauseEnabled) {
          print('   ✅ Auto-pause break lifecycle complete');
        }
        print('   ✅ Practice mode changes working');
        print('   ✅ Session completion working');
        print('   ✅ Time calculations accurate');
      } finally {
        sessionBloc.close();
      }
    }

    // ========================================================================
    // TEST SCENARIOS
    // ========================================================================

    test('Full Featured Session (Warmup + Auto-pause)', () async {
      await runSessionLifecycleTest(
        testName: 'Full Featured Session',
        warmupEnabled: true,
        autoPauseEnabled: true,
        initialSession: null,
      );
    });

    test('Quick Practice Session (No Warmup, No Auto-pause)', () async {
      await runSessionLifecycleTest(
        testName: 'Quick Practice Session',
        warmupEnabled: false,
        autoPauseEnabled: false,
        initialSession: null,
      );
    });

    test('Warmup Only Session (No Auto-pause)', () async {
      await runSessionLifecycleTest(
        testName: 'Warmup Only Session',
        warmupEnabled: true,
        autoPauseEnabled: false,
        initialSession: null,
      );
    });

    test('Auto-pause Only Session (No Warmup)', () async {
      await runSessionLifecycleTest(
        testName: 'Auto-pause Only Session',
        warmupEnabled: false,
        autoPauseEnabled: true,
        initialSession: null,
      );
    });

    test('Resume Aborted Session (Warmup + Auto-pause)', () async {
      // Create a partially completed session to resume
      final abortedSession = Session.getDefault(
        sessionId: 1700000000000,
        instrument: 'guitar',
      );

      // Add some existing practice time
      final existingExercise = abortedSession
          .categories[PracticeCategory.exercise]!
          .copyWith(time: 300); // 5 minutes
      final existingNewSong = abortedSession
          .categories[PracticeCategory.newsong]!
          .copyWith(time: 180); // 3 minutes
      final updatedSession = abortedSession
          .copyWithCategory(PracticeCategory.exercise, existingExercise)
          .copyWithCategory(PracticeCategory.newsong, existingNewSong);

      await runSessionLifecycleTest(
        testName: 'Resume Aborted Session (Full Featured)',
        warmupEnabled: true,
        autoPauseEnabled: true,
        initialSession: updatedSession,
      );
    });

    test('Resume Aborted Session (Warmup Only)', () async {
      final abortedSession = Session.getDefault(
        sessionId: 1700000000000,
        instrument: 'guitar',
      );

      final existingExercise = abortedSession
          .categories[PracticeCategory.exercise]!
          .copyWith(time: 240); // 4 minutes
      final updatedSession = abortedSession.copyWithCategory(
        PracticeCategory.exercise,
        existingExercise,
      );

      await runSessionLifecycleTest(
        testName: 'Resume Aborted Session (Warmup Only)',
        warmupEnabled: true,
        autoPauseEnabled: false,
        initialSession: updatedSession,
      );
    });

    test('Resume Aborted Session (Auto-pause Only)', () async {
      final abortedSession = Session.getDefault(
        sessionId: 1700000000000,
        instrument: 'guitar',
      );

      final existingExercise = abortedSession
          .categories[PracticeCategory.exercise]!
          .copyWith(time: 360); // 6 minutes
      final updatedSession = abortedSession.copyWithCategory(
        PracticeCategory.exercise,
        existingExercise,
      );

      await runSessionLifecycleTest(
        testName: 'Resume Aborted Session (Auto-pause Only)',
        warmupEnabled: false,
        autoPauseEnabled: true,
        initialSession: updatedSession,
      );
    });

    test('Resume Aborted Session (Quick Practice)', () async {
      final abortedSession = Session.getDefault(
        sessionId: 1700000000000,
        instrument: 'guitar',
      );

      final existingExercise = abortedSession
          .categories[PracticeCategory.exercise]!
          .copyWith(time: 120); // 2 minutes
      final existingNewSong = abortedSession
          .categories[PracticeCategory.newsong]!
          .copyWith(time: 90); // 1.5 minutes
      final updatedSession = abortedSession
          .copyWithCategory(PracticeCategory.exercise, existingExercise)
          .copyWithCategory(PracticeCategory.newsong, existingNewSong);

      await runSessionLifecycleTest(
        testName: 'Resume Aborted Session (Quick Practice)',
        warmupEnabled: false,
        autoPauseEnabled: false,
        initialSession: updatedSession,
      );
    });
  });
}
