import 'package:flutter_test/flutter_test.dart';
import 'package:jazzx_app/models/session.dart';
import 'package:jazzx_app/models/practice_category.dart';
import 'package:jazzx_app/utils/session_utils.dart';

void main() {
  group('Draft Session Continue Flow', () {
    test('createRandomDraftSession produces session with correct timestamp', () {
      // Create a random draft session
      final draftSession = createRandomDraftSession(
        totalDuration: 1800, // 30 minutes
        withWarmup: true,
      );

      // Verify the session has realistic timestamp
      final now = DateTime.now();
      final sessionDate = DateTime.fromMillisecondsSinceEpoch(draftSession.started * 1000);
      final timeDifference = now.difference(sessionDate);

      // Session should appear to have started recently (within the last hour)
      expect(timeDifference.inMinutes, lessThan(60));
      expect(timeDifference.inMinutes, greaterThanOrEqualTo(0));
      
      // Session should have the expected duration
      expect(draftSession.duration, equals(1800));
      
      // Session should be a draft (not ended)
      expect(draftSession.ended, equals(0));
      
      print('✅ Draft session created with realistic timestamp:');
      print('   Session date: ${sessionDate.toIso8601String()}');
      print('   Current time: ${now.toIso8601String()}');
      print('   Time difference: ${timeDifference.inMinutes} minutes');
      print('   Duration: ${draftSession.duration} seconds');
    });

    test('draft session JSON can be marked for continuation', () {
      // Create a draft session
      final draftSession = createRandomDraftSession(totalDuration: 900);
      
      // Convert to JSON and add continuation flag (simulating AuthGate logic)
      final draftSessionJson = Map<String, dynamic>.from(draftSession.toJson());
      draftSessionJson['_shouldContinue'] = true;
      
      // Verify the flag is present
      expect(draftSessionJson['_shouldContinue'], isTrue);
      
      // Verify we can still create a session from the JSON after removing the flag
      final cleanDraftJson = Map<String, dynamic>.from(draftSessionJson);
      cleanDraftJson.remove('_shouldContinue');
      final restoredSession = Session.fromJson(cleanDraftJson);
      
      // Verify the restored session matches the original
      expect(restoredSession.started, equals(draftSession.started));
      expect(restoredSession.duration, equals(draftSession.duration));
      expect(restoredSession.ended, equals(draftSession.ended));
      expect(restoredSession.instrument, equals(draftSession.instrument));
      
      print('✅ Draft session continuation flow works correctly:');
      print('   Original session ID: ${draftSession.started}');
      print('   Restored session ID: ${restoredSession.started}');
      print('   Continuation flag handled properly');
    });

    test('draft session time analysis works correctly', () {
      // Create a session that appears to have started 10 minutes ago
      final tenMinutesAgo = DateTime.now().subtract(const Duration(minutes: 10));
      final sessionId = tenMinutesAgo.millisecondsSinceEpoch ~/ 1000;
      
      final draftSession = createRandomDraftSession(
        totalDuration: 600,
        sessionId: sessionId,
      );
      
      // Simulate the time analysis logic from main.dart
      final now = DateTime.now();
      final sessionDate = DateTime.fromMillisecondsSinceEpoch(draftSession.started * 1000);
      final timeDifference = now.difference(sessionDate);
      final isRecent = timeDifference.inMinutes <= 15;
      
      // Should be considered recent (within 15 minutes)
      expect(isRecent, isTrue);
      expect(timeDifference.inMinutes, lessThanOrEqualTo(15));
      expect(timeDifference.inMinutes, greaterThanOrEqualTo(8)); // Allow some test execution time
      
      print('✅ Time analysis works correctly:');
      print('   Session date: ${sessionDate.toIso8601String()}');
      print('   Current time: ${now.toIso8601String()}');
      print('   Time difference: ${timeDifference.inMinutes} minutes');
      print('   Is recent: $isRecent');
      print('   Should show Continue button: $isRecent');
    });

    test('old draft session is not considered recent', () {
      // Create a session that appears to have started 20 minutes ago
      final twentyMinutesAgo = DateTime.now().subtract(const Duration(minutes: 20));
      final sessionId = twentyMinutesAgo.millisecondsSinceEpoch ~/ 1000;
      
      final draftSession = createRandomDraftSession(
        totalDuration: 600,
        sessionId: sessionId,
      );
      
      // Simulate the time analysis logic from main.dart
      final now = DateTime.now();
      final sessionDate = DateTime.fromMillisecondsSinceEpoch(draftSession.started * 1000);
      final timeDifference = now.difference(sessionDate);
      final isRecent = timeDifference.inMinutes <= 15;
      
      // Should NOT be considered recent (older than 15 minutes)
      expect(isRecent, isFalse);
      expect(timeDifference.inMinutes, greaterThan(15));
      
      print('✅ Old session correctly identified as not recent:');
      print('   Session date: ${sessionDate.toIso8601String()}');
      print('   Current time: ${now.toIso8601String()}');
      print('   Time difference: ${timeDifference.inMinutes} minutes');
      print('   Is recent: $isRecent');
      print('   Should show Continue button: $isRecent');
    });
  });
}
