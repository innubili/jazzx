import 'package:flutter_test/flutter_test.dart';

/// Helper class for mocking time in tests
/// This allows us to control DateTime.now() to return specific timestamps
/// for testing timestamp-based calculations
class TimeMockHelper {
  static int? _mockedTimestamp;
  
  /// Mock DateTime.now() to return a specific timestamp
  static void mockTime(int timestamp) {
    _mockedTimestamp = timestamp;
  }
  
  /// Clear the mocked time and return to real time
  static void clearMock() {
    _mockedTimestamp = null;
  }
  
  /// Get the current timestamp (mocked or real)
  static int getCurrentTimestamp() {
    if (_mockedTimestamp != null) {
      return _mockedTimestamp!;
    }
    return DateTime.now().millisecondsSinceEpoch ~/ 1000;
  }
  
  /// Get the current DateTime (mocked or real)
  static DateTime getCurrentDateTime() {
    if (_mockedTimestamp != null) {
      return DateTime.fromMillisecondsSinceEpoch(_mockedTimestamp! * 1000);
    }
    return DateTime.now();
  }
}

/// Test constants for consistent timestamp testing
class TestTimestamps {
  static const int base = 1700000000; // Nov 14, 2023 22:13:20 GMT
  static const int t0 = base;
  static const int t5 = base + 5;
  static const int t10 = base + 10;
  static const int t15 = base + 15;
  static const int t20 = base + 20;
  static const int t30 = base + 30;
  static const int t45 = base + 45;
  static const int t60 = base + 60;
  static const int t90 = base + 90;
  static const int t120 = base + 120;
  static const int t300 = base + 300; // 5 minutes
  static const int t600 = base + 600; // 10 minutes
  static const int t1200 = base + 1200; // 20 minutes
}

/// Extension to make timestamp testing more readable
extension TimestampTesting on int {
  /// Convert seconds to a readable time format for test descriptions
  String get asTimeString {
    final minutes = this ~/ 60;
    final seconds = this % 60;
    return '${minutes.toString().padLeft(2, '0')}:${seconds.toString().padLeft(2, '0')}';
  }
  
  /// Calculate elapsed time from this timestamp to another
  int elapsedTo(int endTimestamp) {
    return endTimestamp - this;
  }
}

/// Test scenarios with predefined timestamps
class TestScenarios {
  /// Scenario: Quick practice session
  /// Exercise: 30 seconds
  static const quickPractice = {
    'start': TestTimestamps.t0,
    'exerciseEnd': TestTimestamps.t30,
    'exerciseTime': 30,
  };
  
  /// Scenario: Category switching
  /// Exercise: 30s -> New Song: 20s -> Exercise: 15s
  static const categorySwitching = {
    'start': TestTimestamps.t0,
    'exerciseEnd1': TestTimestamps.t30,
    'newSongStart': TestTimestamps.t30,
    'newSongEnd': TestTimestamps.base + 50,
    'exerciseStart2': TestTimestamps.base + 50,
    'exerciseEnd2': TestTimestamps.base + 65,
    'exerciseTime1': 30,
    'newSongTime': 20,
    'exerciseTime2': 15,
    'totalExerciseTime': 45,
  };
  
  /// Scenario: Warmup session
  /// Warmup: 60s -> Exercise: 45s
  static const warmupSession = {
    'warmupStart': TestTimestamps.t0,
    'warmupEnd': TestTimestamps.t60,
    'exerciseStart': TestTimestamps.t60,
    'exerciseEnd': TestTimestamps.base + 105,
    'warmupTime': 60,
    'exerciseTime': 45,
    'totalTime': 105,
  };
  
  /// Scenario: Long practice session
  /// Multiple categories over 30 minutes
  static const longSession = {
    'start': TestTimestamps.t0,
    'warmupTime': 300, // 5 minutes
    'exerciseTime': 600, // 10 minutes
    'newSongTime': 480, // 8 minutes
    'lessonTime': 420, // 7 minutes
    'totalTime': 1800, // 30 minutes
  };
}

/// Helper functions for common test operations
class TestHelpers {
  /// Create a session with specific category times
  static Map<String, int> createCategoryTimes({
    int exercise = 0,
    int newSong = 0,
    int repertoire = 0,
    int lesson = 0,
    int theory = 0,
    int video = 0,
    int gig = 0,
    int fun = 0,
  }) {
    return {
      'exercise': exercise,
      'newSong': newSong,
      'repertoire': repertoire,
      'lesson': lesson,
      'theory': theory,
      'video': video,
      'gig': gig,
      'fun': fun,
    };
  }
  
  /// Calculate total session duration
  static int calculateTotalDuration(Map<String, int> categoryTimes, {int warmupTime = 0}) {
    int total = warmupTime;
    for (final time in categoryTimes.values) {
      total += time;
    }
    return total;
  }
  
  /// Verify timestamp calculation
  static void verifyElapsedTime({
    required int startTime,
    required int endTime,
    required int expectedElapsed,
    String? description,
  }) {
    final actualElapsed = endTime - startTime;
    expect(
      actualElapsed,
      equals(expectedElapsed),
      reason: description ?? 'Elapsed time calculation mismatch',
    );
  }
  
  /// Verify category time accumulation
  static void verifyCategoryTimeAccumulation({
    required int existingTime,
    required int elapsedTime,
    required int expectedTotal,
    String? categoryName,
  }) {
    final actualTotal = existingTime + elapsedTime;
    expect(
      actualTotal,
      equals(expectedTotal),
      reason: 'Category ${categoryName ?? 'time'} accumulation mismatch',
    );
  }
}

/// Custom matchers for session testing
class SessionMatchers {
  /// Matcher for session duration
  static Matcher hasSessionDuration(int expectedDuration) {
    return predicate<dynamic>(
      (session) => session.duration == expectedDuration,
      'has session duration of $expectedDuration seconds (${expectedDuration.asTimeString})',
    );
  }
  
  /// Matcher for category time
  static Matcher hasCategoryTime(String categoryName, int expectedTime) {
    return predicate<dynamic>(
      (session) {
        final category = session.categories[categoryName];
        return category?.time == expectedTime;
      },
      'has $categoryName time of $expectedTime seconds (${expectedTime.asTimeString})',
    );
  }
  
  /// Matcher for warmup time
  static Matcher hasWarmupTime(int expectedTime) {
    return predicate<dynamic>(
      (session) => session.warmup?.time == expectedTime,
      'has warmup time of $expectedTime seconds (${expectedTime.asTimeString})',
    );
  }
}
