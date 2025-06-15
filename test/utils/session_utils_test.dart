import 'package:flutter_test/flutter_test.dart';
import 'package:jazzx_app/utils/session_utils.dart';
import 'package:jazzx_app/models/practice_category.dart';

void main() {
  group('createRandomDraftSession', () {
    test('creates session with specified total duration', () {
      const totalDuration = 1800; // 30 minutes
      final session = createRandomDraftSession(totalDuration: totalDuration);

      expect(session.duration, equals(totalDuration));
      expect(session.ended, equals(0)); // Draft session not ended
      expect(session.instrument, equals('guitar')); // Default instrument
    });

    test('creates session with custom instrument', () {
      final session = createRandomDraftSession(instrument: 'piano');

      expect(session.instrument, equals('piano'));
    });

    test('creates session with warmup when specified', () {
      final session = createRandomDraftSession(
        totalDuration: 1800,
        withWarmup: true,
      );

      expect(session.warmup, isNotNull);
      expect(session.warmup!.time, greaterThan(0));
      expect(
        session.warmup!.time,
        greaterThanOrEqualTo(60),
      ); // At least 1 minute
      expect(session.warmup!.time, lessThanOrEqualTo(180)); // At most 3 minutes
      expect(session.warmup!.bpm, greaterThanOrEqualTo(60));
      expect(session.warmup!.bpm, lessThanOrEqualTo(120));
    });

    test('creates session without warmup when specified', () {
      final session = createRandomDraftSession(
        totalDuration: 1800,
        withWarmup: false,
      );

      expect(session.warmup, isNull);
    });

    test('allocates time to exactly 2 practice categories', () {
      final session = createRandomDraftSession(
        totalDuration: 1800,
        withWarmup: false,
      );

      final categoriesWithTime =
          session.categories.entries
              .where((entry) => entry.value.time > 0)
              .toList();

      expect(categoriesWithTime.length, equals(2));
    });

    test('allocates time in 1/3 and 2/3 ratio for practice categories', () {
      const totalDuration = 1800; // 30 minutes
      final session = createRandomDraftSession(
        totalDuration: totalDuration,
        withWarmup: false,
      );

      final categoriesWithTime =
          session.categories.entries
              .where((entry) => entry.value.time > 0)
              .map((entry) => entry.value.time)
              .toList()
            ..sort();

      expect(categoriesWithTime.length, equals(2));

      final totalPracticeTime = categoriesWithTime[0] + categoriesWithTime[1];
      expect(totalPracticeTime, equals(totalDuration));

      // Check 1/3 and 2/3 ratio (with some tolerance for rounding)
      final expectedFirstTime = (totalDuration * 0.33).round();
      final expectedSecondTime = totalDuration - expectedFirstTime;

      expect(categoriesWithTime[0], equals(expectedFirstTime));
      expect(categoriesWithTime[1], equals(expectedSecondTime));
    });

    test('allocates time correctly with warmup', () {
      const totalDuration = 1800; // 30 minutes
      final session = createRandomDraftSession(
        totalDuration: totalDuration,
        withWarmup: true,
      );

      final warmupTime = session.warmup?.time ?? 0;
      final categoriesWithTime =
          session.categories.entries
              .where((entry) => entry.value.time > 0)
              .map((entry) => entry.value.time)
              .toList();

      final totalCategoryTime = categoriesWithTime.fold<int>(
        0,
        (sum, time) => sum + time,
      );

      expect(warmupTime + totalCategoryTime, equals(totalDuration));
      expect(categoriesWithTime.length, equals(2));
    });

    test('sets BPM for categories with time', () {
      final session = createRandomDraftSession(
        totalDuration: 1800,
        withWarmup: false,
      );

      for (final entry in session.categories.entries) {
        if (entry.value.time > 0) {
          expect(entry.value.bpm, isNotNull);
          expect(entry.value.bpm!, greaterThanOrEqualTo(60));
          expect(entry.value.bpm!, lessThanOrEqualTo(180));
          expect(entry.value.note, equals('Random practice session'));
        } else {
          expect(entry.value.bpm, isNull);
          expect(entry.value.note, isNull);
        }
      }
    });

    test('creates session with custom session ID', () {
      const customId = 1234567890;
      final session = createRandomDraftSession(sessionId: customId);

      expect(session.started, equals(customId));
      expect(session.id, equals(customId.toString()));
    });

    test('generates random duration in correct ranges', () {
      // Test multiple sessions to check duration ranges
      final sessions = List.generate(20, (_) => createRandomDraftSession());

      final shortSessions =
          sessions.where((s) => s.duration >= 360 && s.duration <= 600).length;
      final longSessions =
          sessions
              .where((s) => s.duration >= 1200 && s.duration <= 10800)
              .length;

      // All sessions should be either short or long
      expect(shortSessions + longSessions, equals(sessions.length));

      // We should have some variety (not all the same type)
      // Note: This is probabilistic, but with 20 sessions it's very likely
      expect(shortSessions > 0 || longSessions > 0, isTrue);
    });

    test('creates valid session structure', () {
      final session = createRandomDraftSession();

      // Check all required categories are present
      expect(session.categories.length, equals(PracticeCategory.values.length));

      for (final category in PracticeCategory.values) {
        expect(session.categories.containsKey(category), isTrue);
        expect(session.categories[category], isNotNull);
      }

      // Check that only the 4 practice mode categories have time allocated
      final availableCategories = [
        PracticeCategory.exercise,
        PracticeCategory.newsong,
        PracticeCategory.repertoire,
        PracticeCategory.fun,
      ];

      final categoriesWithTime =
          session.categories.entries
              .where((entry) => entry.value.time > 0)
              .map((entry) => entry.key)
              .toList();

      // All categories with time should be from the available categories
      for (final category in categoriesWithTime) {
        expect(availableCategories.contains(category), isTrue);
      }

      // Check session has valid timestamp
      expect(session.started, greaterThan(0));
      expect(session.duration, greaterThan(0));
    });

    test('recalculated duration matches specified duration', () {
      const totalDuration = 2400; // 40 minutes
      final session = createRandomDraftSession(
        totalDuration: totalDuration,
        withWarmup: true,
      );

      final recalculatedDuration = recalculateSessionDuration(session);
      expect(recalculatedDuration, equals(totalDuration));
      expect(session.duration, equals(totalDuration));
    });

    test('creates different sessions on multiple calls', () {
      final session1 = createRandomDraftSession();
      final session2 = createRandomDraftSession();

      // Sessions should have different start times (unless called at exact same millisecond)
      // and likely different category allocations
      expect(
        session1.started != session2.started ||
            session1.categories != session2.categories ||
            session1.warmup != session2.warmup,
        isTrue,
      );
    });

    test('only uses practice mode button categories', () {
      // Test multiple sessions to ensure consistency
      final sessions = List.generate(10, (_) => createRandomDraftSession());

      final expectedCategories = {
        PracticeCategory.exercise,
        PracticeCategory.newsong,
        PracticeCategory.repertoire,
        PracticeCategory.fun,
      };

      for (final session in sessions) {
        final categoriesWithTime =
            session.categories.entries
                .where((entry) => entry.value.time > 0)
                .map((entry) => entry.key)
                .toSet();

        // Should have exactly 2 categories with time
        expect(categoriesWithTime.length, equals(2));

        // All categories with time should be from the expected set
        for (final category in categoriesWithTime) {
          expect(expectedCategories.contains(category), isTrue);
        }

        // Categories not in the expected set should have 0 time
        for (final category in PracticeCategory.values) {
          if (!expectedCategories.contains(category)) {
            expect(session.categories[category]!.time, equals(0));
          }
        }
      }
    });

    test('sets started timestamp to now() - duration', () {
      final beforeCreation = DateTime.now();
      final session = createRandomDraftSession(
        totalDuration: 1800,
      ); // 30 minutes
      final afterCreation = DateTime.now();

      // Calculate expected started time range
      final expectedStartedMin = beforeCreation.subtract(
        Duration(seconds: session.duration),
      );
      final expectedStartedMax = afterCreation.subtract(
        Duration(seconds: session.duration),
      );

      final actualStarted = DateTime.fromMillisecondsSinceEpoch(
        session.started * 1000,
      );

      // The started time should be approximately now() - duration
      expect(
        actualStarted.isAfter(
          expectedStartedMin.subtract(Duration(seconds: 1)),
        ),
        isTrue,
      );
      expect(
        actualStarted.isBefore(expectedStartedMax.add(Duration(seconds: 1))),
        isTrue,
      );

      // Verify that started + duration ≈ now
      final calculatedEnd = actualStarted.add(
        Duration(seconds: session.duration),
      );
      expect(
        calculatedEnd.isAfter(beforeCreation.subtract(Duration(seconds: 1))),
        isTrue,
      );
      expect(
        calculatedEnd.isBefore(afterCreation.add(Duration(seconds: 1))),
        isTrue,
      );
    });
  });
}
