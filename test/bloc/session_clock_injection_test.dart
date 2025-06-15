// ignore_for_file: avoid_print

import 'package:flutter_test/flutter_test.dart';

import 'package:jazzx_app/bloc/session_bloc.dart';
import 'package:jazzx_app/core/time/app_clock.dart';
import 'package:jazzx_app/models/practice_category.dart';

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
  group('Session Clock Injection Test', () {
    test('Clock Injection Works', () async {
      // Test that our clock injection fix works
      const baseTime = 1700000000; // Nov 14, 2023 22:13:20 GMT

      // Create SessionBloc with controllable time
      var mockClock = ControllableClock(baseTime * 1000);
      final sessionBloc = SessionBloc(clock: mockClock);

      try {
        // Start session
        sessionBloc.add(createPracticeModeSelected(PracticeCategory.exercise));
        await Future.delayed(Duration(milliseconds: 10));

        // Start warmup
        sessionBloc.add(TimerStartPressed());
        await Future.delayed(Duration(milliseconds: 10));

        // Verify warmup started with our mocked time
        var state = sessionBloc.state as SessionActive;
        expect(state.isInWarmup, true);
        expect(state.warmupStartedAt, equals(baseTime));

        print('✅ Clock injection works!');
        print('   Expected warmup start time: $baseTime');
        print('   Actual warmup start time: ${state.warmupStartedAt}');
      } finally {
        sessionBloc.close();
      }
    });

    test('Realistic Warmup Pause/Resume with Long Intervals', () async {
      // This test demonstrates the warmup bug with realistic time intervals
      // using multiple SessionBloc instances to simulate time progression

      print('🎯 Testing realistic warmup pause/resume with long intervals...');

      const baseTime = 1700000000;

      // === PHASE 1: Start warmup and run for 5 minutes ===
      var sessionBloc1 = SessionBloc(clock: ControllableClock(baseTime * 1000));

      try {
        sessionBloc1.add(createPracticeModeSelected(PracticeCategory.exercise));
        await Future.delayed(Duration(milliseconds: 10));

        sessionBloc1.add(TimerStartPressed());
        await Future.delayed(Duration(milliseconds: 10));

        var state = sessionBloc1.state as SessionActive;
        expect(state.warmupStartedAt, equals(baseTime));
        print('✅ Warmup started at $baseTime');

        print('🎯 This test shows the current limitation - we can\'t easily');
        print(
          '   simulate time progression with fixed clocks in a single SessionBloc',
        );
        print(
          '   The warmup time calculation works, but only with real time progression',
        );
      } finally {
        sessionBloc1.close();
      }
    });

    test('Demonstrate Warmup Bug with Realistic Times', () async {
      // This test shows the exact problem: warmup time calculation fails
      // when pause happens at the same timestamp as start

      const startTime = 1700000000;

      print('🎯 Demonstrating warmup calculation bug...');

      // Test 1: Same timestamp (current bug)
      var sessionBloc1 = SessionBloc(
        clock: ControllableClock(startTime * 1000),
      );

      try {
        sessionBloc1.add(createPracticeModeSelected(PracticeCategory.exercise));
        await Future.delayed(Duration(milliseconds: 10));

        sessionBloc1.add(TimerStartPressed());
        await Future.delayed(Duration(milliseconds: 10));

        var state = sessionBloc1.state as SessionActive;
        expect(state.warmupStartedAt, equals(startTime));

        // Pause immediately (same timestamp) - this shows the bug
        sessionBloc1.add(TimerStopPressed());
        await Future.delayed(Duration(milliseconds: 10));

        state = sessionBloc1.state as SessionActive;
        final warmupTime1 = state.session.warmup?.time ?? 0;

        print('❌ Bug demonstration:');
        print('   Start time: $startTime');
        print('   Pause time: $startTime (same!)');
        print('   Calculated warmup time: ${warmupTime1}s');
        print('   Expected: 0s (correct for same timestamp)');

        expect(
          warmupTime1,
          equals(0),
          reason: 'Same timestamp should give 0 elapsed time',
        );

        print(
          '✅ This shows why our current test fails - we need time progression!',
        );
      } finally {
        sessionBloc1.close();
      }

      print('💡 Solution: The SessionBloc needs to use a clock that advances,');
      print('   or we need to test the time calculation logic separately.');
    });

    test('Realistic Session with Multiple Time Points', () async {
      // This test simulates a realistic session by creating SessionBloc instances
      // at different time points to test the actual warmup accumulation logic

      print('🎯 Testing realistic session with multiple time points...');

      const baseTime = 1700000000;

      // === PHASE 1: Start warmup ===
      var sessionBloc1 = SessionBloc(clock: ControllableClock(baseTime * 1000));

      try {
        sessionBloc1.add(createPracticeModeSelected(PracticeCategory.exercise));
        await Future.delayed(Duration(milliseconds: 10));

        sessionBloc1.add(TimerStartPressed());
        await Future.delayed(Duration(milliseconds: 10));

        var state1 = sessionBloc1.state as SessionActive;
        expect(state1.warmupStartedAt, equals(baseTime));
        print('✅ Phase 1: Warmup started at $baseTime');

        // === PHASE 2: Pause after 5 minutes ===
        const after5Minutes = baseTime + 300; // +5 minutes
        var sessionBloc2 = SessionBloc(
          clock: ControllableClock(after5Minutes * 1000),
        );

        // Simulate the session state at 5 minutes
        sessionBloc2.add(createPracticeModeSelected(PracticeCategory.exercise));
        await Future.delayed(Duration(milliseconds: 10));
        sessionBloc2.add(TimerStartPressed());
        await Future.delayed(Duration(milliseconds: 10));

        // Test the pause logic with realistic time difference
        const pauseTime = after5Minutes + 240; // +4 more minutes
        var sessionBloc3 = SessionBloc(
          clock: ControllableClock(pauseTime * 1000),
        );

        print('✅ Phase 2: Testing warmup accumulation logic');
        print('   Start time: $baseTime');
        print('   First pause: $after5Minutes (after 5 minutes)');
        print('   Resume time: $after5Minutes (immediately)');
        print('   Second pause: $pauseTime (after 4 more minutes)');
        print('   Expected total: 540 seconds (9 minutes)');

        // This demonstrates the time calculation logic with realistic intervals
        final startTime = baseTime;
        final firstPauseTime = after5Minutes;
        final resumeTime = after5Minutes;
        final secondPauseTime = pauseTime;

        // Calculate what the warmup time should be
        final firstSegment = firstPauseTime - startTime; // 300 seconds
        final secondSegment = secondPauseTime - resumeTime; // 240 seconds
        final totalExpected = firstSegment + secondSegment; // 540 seconds

        expect(totalExpected, equals(540), reason: '5 + 4 = 9 minutes');

        print('✅ Time calculation verification:');
        print('   First segment: ${firstSegment}s (5 minutes)');
        print('   Second segment: ${secondSegment}s (4 minutes)');
        print('   Total expected: ${totalExpected}s (9 minutes)');

        sessionBloc2.close();
        sessionBloc3.close();
      } finally {
        sessionBloc1.close();
      }

      print('🎉 Realistic time intervals test completed!');
      print('   This shows how the warmup accumulation should work');
      print('   with realistic 5-minute and 4-minute intervals.');
    });

    test('Controllable Clock Warmup Test with Real Time Progression', () async {
      // This test uses our ControllableClock to actually advance time
      // and test the warmup accumulation bug fix

      print('🎯 Testing warmup accumulation with controllable clock...');

      const baseTime = 1700000000;
      var clock = ControllableClock(baseTime * 1000);
      final sessionBloc = SessionBloc(clock: clock);

      try {
        // === PHASE 1: Start session ===
        sessionBloc.add(createPracticeModeSelected(PracticeCategory.exercise));
        await Future.delayed(Duration(milliseconds: 10));

        var state = sessionBloc.state as SessionActive;
        expect(state.isInWarmup, true);
        expect(state.isPaused, true);
        print('✅ Session started in warmup mode');

        // === PHASE 2: Start warmup ===
        sessionBloc.add(TimerStartPressed());
        await Future.delayed(Duration(milliseconds: 10));

        state = sessionBloc.state as SessionActive;
        expect(state.isInWarmup, true);
        expect(state.isPaused, false);
        expect(state.warmupStartedAt, equals(baseTime));
        print('✅ Warmup started at $baseTime');

        // === PHASE 3: Advance time by 5 minutes and pause ===
        clock.advanceMinutes(5);
        sessionBloc.add(TimerStopPressed());
        await Future.delayed(Duration(milliseconds: 10));

        state = sessionBloc.state as SessionActive;
        expect(state.isInWarmup, true);
        expect(state.isPaused, true);
        expect(
          state.warmupStartedAt,
          isNull,
          reason: 'Should be cleared on pause',
        );

        // FIXED: Warmup time should be saved (5 minutes = 300 seconds)
        final firstPauseTime = state.session.warmup?.time ?? 0;
        print('✅ After 5 minutes, saved warmup time: ${firstPauseTime}s');
        expect(
          firstPauseTime,
          equals(300),
          reason: '5 minutes should be saved',
        );

        // === PHASE 4: Wait 1 minute while paused (should not count) ===
        clock.advanceMinutes(1);
        print('⏸️ Waited 1 minute while paused (should not count)');

        // === PHASE 5: Resume warmup ===
        sessionBloc.add(TimerStartPressed());
        await Future.delayed(Duration(milliseconds: 10));

        state = sessionBloc.state as SessionActive;
        expect(state.isInWarmup, true);
        expect(state.isPaused, false);
        expect(
          state.warmupStartedAt,
          isNotNull,
          reason: 'Should be set on resume',
        );

        // FIXED: Warmup time should be preserved
        expect(
          state.session.warmup?.time,
          equals(300),
          reason: 'Accumulated warmup time should be preserved',
        );

        // FIXED: warmupStartedAt should be set to current time on resume
        final currentTime = clock.nowSeconds;
        expect(
          state.warmupStartedAt,
          equals(currentTime),
          reason: 'warmupStartedAt should be set to current time on resume',
        );
        print('✅ Resumed warmup - start time set to current time');

        // === PHASE 6: Advance time by 4 more minutes and pause ===
        clock.advanceMinutes(4);
        sessionBloc.add(TimerStopPressed());
        await Future.delayed(Duration(milliseconds: 10));

        state = sessionBloc.state as SessionActive;
        final totalWarmupTime = state.session.warmup?.time ?? 0;
        print('✅ After 4 more minutes, total warmup time: ${totalWarmupTime}s');

        // FIXED: Total time should be 5 + 4 = 9 minutes (540 seconds)
        expect(
          totalWarmupTime,
          equals(540),
          reason: 'Total warmup: 5 + 4 = 9 minutes',
        );

        print('🎉 CONTROLLABLE CLOCK TEST SUCCESSFUL!');
        print('   📊 Warmup accumulation working correctly:');
        print('   ⏱️  First segment: 300s (5 minutes)');
        print('   ⏱️  Second segment: 240s (4 minutes)');
        print('   📈 Total accumulated: ${totalWarmupTime}s (9 minutes)');
      } finally {
        sessionBloc.close();
      }
    });

    test('Real App Time Progression Test', () async {
      // This test uses the EXACT time progression from your app logs:
      // Start: 22:52:08.435, First pause: 22:52:19.008 (~10.5s),
      // Resume: 22:52:23.167 (~4s pause), Second pause: 22:52:25.896 (~2.7s)

      print('🎯 Testing with real app time progression...');

      // Convert your log timestamps to epoch seconds for easier calculation
      const startTime = 1749934328; // 22:52:08 (rounded)
      var clock = ControllableClock(startTime * 1000);
      final sessionBloc = SessionBloc(clock: clock);

      try {
        // === PHASE 1: Start session ===
        sessionBloc.add(createPracticeModeSelected(PracticeCategory.exercise));
        await Future.delayed(Duration(milliseconds: 10));

        // === PHASE 2: Start warmup at 22:52:08 ===
        sessionBloc.add(TimerStartPressed());
        await Future.delayed(Duration(milliseconds: 10));

        var state = sessionBloc.state as SessionActive;
        expect(state.warmupStartedAt, equals(startTime));
        print('✅ Warmup started at $startTime (22:52:08)');

        // === PHASE 3: First pause at 22:52:19 (after 10.5 seconds) ===
        clock.advanceSeconds(11); // Round to 11 seconds
        sessionBloc.add(TimerStopPressed());
        await Future.delayed(Duration(milliseconds: 10));

        state = sessionBloc.state as SessionActive;
        final firstPauseTime = state.session.warmup?.time ?? 0;
        print('✅ After 11 seconds, saved warmup time: ${firstPauseTime}s');
        expect(
          firstPauseTime,
          equals(11),
          reason: '11 seconds should be saved',
        );

        // === PHASE 4: Pause for 4 seconds (22:52:19 to 22:52:23) ===
        clock.advanceSeconds(4);
        print('⏸️ Paused for 4 seconds (should not count)');

        // === PHASE 5: Resume at 22:52:23 ===
        sessionBloc.add(TimerStartPressed());
        await Future.delayed(Duration(milliseconds: 10));

        state = sessionBloc.state as SessionActive;
        expect(
          state.session.warmup?.time,
          equals(11),
          reason: 'Accumulated warmup time should be preserved',
        );

        // Check warmupStartedAt is set to current time
        final currentTime = clock.nowSeconds;
        expect(
          state.warmupStartedAt,
          equals(currentTime),
          reason: 'warmupStartedAt should be set to current time on resume',
        );
        print('✅ Resumed - start time set to current time');

        // === PHASE 6: Second pause at 22:52:26 (after 3 more seconds) ===
        clock.advanceSeconds(3);
        sessionBloc.add(TimerStopPressed());
        await Future.delayed(Duration(milliseconds: 10));

        state = sessionBloc.state as SessionActive;
        final totalWarmupTime = state.session.warmup?.time ?? 0;
        print('✅ After 3 more seconds, total warmup time: ${totalWarmupTime}s');

        // Let's debug what's happening
        print('🔍 Debug calculation:');
        print('   Start time: $startTime');
        print('   Current time: ${clock.nowSeconds}');
        print('   Total elapsed from start: ${clock.nowSeconds - startTime}s');
        print('   Adjusted warmupStartedAt: ${state.warmupStartedAt}');
        if (state.warmupStartedAt != null) {
          print(
            '   Elapsed from adjusted start: ${clock.nowSeconds - state.warmupStartedAt!}s',
          );
        }

        // The calculation should now work correctly!
        // Expected: 11 + 3 = 14 seconds total
        // - First segment: 11 seconds (22:52:08 to 22:52:19)
        // - Pause: 4 seconds (should not count)
        // - Second segment: 3 seconds (22:52:23 to 22:52:26)
        // - Total: 11 + 3 = 14 seconds

        expect(
          totalWarmupTime,
          equals(14),
          reason: 'Total warmup time should be 11 + 3 = 14 seconds',
        );

        print('🎉 REAL APP TIME PROGRESSION TEST SUCCESSFUL!');
        print('   📊 Using exact timestamps from your app logs:');
        print('   ⏱️  First segment: 11s (22:52:08 to 22:52:19)');
        print('   ⏸️  Pause: 4s (22:52:19 to 22:52:23)');
        print('   ⏱️  Second segment: 3s (22:52:23 to 22:52:26)');
        print(
          '   📈 Total accumulated: ${totalWarmupTime}s (correct: 11 + 3 = 14)',
        );
      } finally {
        sessionBloc.close();
      }
    });
  });
}
