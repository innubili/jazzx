import 'package:flutter_test/flutter_test.dart';
import 'package:jazzx_app/utils/session_utils.dart';
import 'package:jazzx_app/models/practice_category.dart';

void main() {
  group('createRandomDraftSession Demo', () {
    test('demonstrates random draft session creation', () {
      print('\n=== Random Draft Session Demo ===\n');
      
      // Create a few different types of sessions
      final sessions = [
        createRandomDraftSession(
          totalDuration: 600, // 10 minutes
          withWarmup: true,
          instrument: 'guitar',
        ),
        createRandomDraftSession(
          totalDuration: 3600, // 60 minutes
          withWarmup: false,
          instrument: 'piano',
        ),
        createRandomDraftSession(), // Completely random
      ];
      
      for (int i = 0; i < sessions.length; i++) {
        final session = sessions[i];
        print('Session ${i + 1}:');
        print('  ID: ${session.id}');
        print('  Instrument: ${session.instrument}');
        print('  Total Duration: ${intSecondsToHHmmss(session.duration)}');
        print('  Warmup: ${session.warmup != null ? intSecondsToHHmmss(session.warmup!.time) : 'None'}');
        
        if (session.warmup != null) {
          print('  Warmup BPM: ${session.warmup!.bpm}');
        }
        
        print('  Practice Categories:');
        for (final entry in session.categories.entries) {
          if (entry.value.time > 0) {
            print('    ${entry.key.name}: ${intSecondsToHHmmss(entry.value.time)} (BPM: ${entry.value.bpm})');
          }
        }
        
        // Verify the session structure
        final recalculatedDuration = recalculateSessionDuration(session);
        print('  Recalculated Duration: ${intSecondsToHHmmss(recalculatedDuration)}');
        print('  Duration Match: ${session.duration == recalculatedDuration ? '✅' : '❌'}');
        
        final categoriesWithTime = session.categories.values.where((cat) => cat.time > 0).length;
        print('  Categories with Time: $categoriesWithTime');
        print('  Has Exactly 2 Categories: ${categoriesWithTime == 2 ? '✅' : '❌'}');
        
        print('');
      }
      
      // All sessions should be valid
      for (final session in sessions) {
        expect(session.duration, greaterThan(0));
        expect(recalculateSessionDuration(session), equals(session.duration));
        
        final categoriesWithTime = session.categories.values.where((cat) => cat.time > 0).length;
        expect(categoriesWithTime, equals(2));
      }
    });
    
    test('demonstrates duration ranges', () {
      print('\n=== Duration Range Demo ===\n');
      
      // Generate multiple sessions to show duration variety
      final sessions = List.generate(10, (_) => createRandomDraftSession());
      
      final shortSessions = <int>[];
      final longSessions = <int>[];
      
      for (final session in sessions) {
        if (session.duration >= 360 && session.duration <= 600) {
          shortSessions.add(session.duration);
        } else if (session.duration >= 1200 && session.duration <= 10800) {
          longSessions.add(session.duration);
        }
      }
      
      print('Short Sessions (6-10 min): ${shortSessions.map((d) => intSecondsToHHmmss(d)).join(', ')}');
      print('Long Sessions (20-180 min): ${longSessions.map((d) => intSecondsToHHmmss(d)).join(', ')}');
      print('Total Sessions: ${sessions.length}');
      print('Short: ${shortSessions.length}, Long: ${longSessions.length}');
      
      // Verify all sessions fall into expected ranges
      expect(shortSessions.length + longSessions.length, equals(sessions.length));
    });
    
    test('demonstrates time allocation ratios', () {
      print('\n=== Time Allocation Demo ===\n');
      
      const testDuration = 1800; // 30 minutes
      final session = createRandomDraftSession(
        totalDuration: testDuration,
        withWarmup: true,
      );
      
      final warmupTime = session.warmup?.time ?? 0;
      final practiceTime = testDuration - warmupTime;
      
      final categoriesWithTime = session.categories.entries
          .where((entry) => entry.value.time > 0)
          .toList();
      
      print('Total Duration: ${intSecondsToHHmmss(testDuration)}');
      print('Warmup Time: ${intSecondsToHHmmss(warmupTime)}');
      print('Practice Time: ${intSecondsToHHmmss(practiceTime)}');
      print('');
      
      for (final entry in categoriesWithTime) {
        final percentage = (entry.value.time / practiceTime * 100).round();
        print('${entry.key.name}: ${intSecondsToHHmmss(entry.value.time)} (${percentage}% of practice time)');
      }
      
      // Verify 1/3 and 2/3 allocation
      final times = categoriesWithTime.map((e) => e.value.time).toList()..sort();
      final expectedFirst = (practiceTime * 0.33).round();
      final expectedSecond = practiceTime - expectedFirst;
      
      print('');
      print('Expected 1/3: ${intSecondsToHHmmss(expectedFirst)}');
      print('Expected 2/3: ${intSecondsToHHmmss(expectedSecond)}');
      print('Actual allocation: ${times.map((t) => intSecondsToHHmmss(t)).join(' + ')}');
      
      expect(times[0], equals(expectedFirst));
      expect(times[1], equals(expectedSecond));
    });
  });
}
