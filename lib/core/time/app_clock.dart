/// Abstract clock interface for time operations
/// Allows for easy testing with controllable time
abstract class AppClock {
  /// Get current time in milliseconds since epoch
  int get nowMilliseconds;

  /// Get current time in seconds since epoch
  int get nowSeconds;

  /// Get current DateTime
  DateTime get now;
}

/// Production clock that uses real system time
class SystemClock implements AppClock {
  @override
  int get nowMilliseconds => DateTime.now().millisecondsSinceEpoch;

  @override
  int get nowSeconds => nowMilliseconds ~/ 1000;

  @override
  DateTime get now => DateTime.fromMillisecondsSinceEpoch(nowMilliseconds);
}

/// Test clock that can be controlled for testing
class TestClock implements AppClock {
  int _currentTime;
  final int _timeMultiplier;

  TestClock({
    required int startTime,
    int timeMultiplier = 1000, // 1 second per millisecond by default
  }) : _currentTime = startTime,
       _timeMultiplier = timeMultiplier;

  @override
  int get nowMilliseconds {
    // Advance time automatically based on multiplier
    _currentTime += _timeMultiplier;
    return _currentTime;
  }

  @override
  int get nowSeconds => nowMilliseconds ~/ 1000;

  @override
  DateTime get now => DateTime.fromMillisecondsSinceEpoch(nowMilliseconds);

  /// Manually set the current time
  void setTime(int milliseconds) {
    _currentTime = milliseconds;
  }

  /// Advance time by specified amount
  void advance(Duration duration) {
    _currentTime += duration.inMilliseconds;
  }

  /// Advance time by seconds
  void advanceSeconds(int seconds) {
    _currentTime += seconds * 1000;
  }
}

/// Controllable clock for tests that doesn't auto-advance
class ControllableClock implements AppClock {
  int _currentTime;

  ControllableClock(this._currentTime);

  @override
  int get nowMilliseconds => _currentTime;

  @override
  int get nowSeconds => nowMilliseconds ~/ 1000;

  @override
  DateTime get now => DateTime.fromMillisecondsSinceEpoch(nowMilliseconds);

  /// Manually set the current time
  void setTime(int milliseconds) {
    _currentTime = milliseconds;
  }

  /// Advance time by specified amount
  void advance(Duration duration) {
    _currentTime += duration.inMilliseconds;
  }

  /// Advance time by seconds
  void advanceSeconds(int seconds) {
    _currentTime += seconds * 1000;
  }

  /// Advance time by minutes
  void advanceMinutes(int minutes) {
    _currentTime += minutes * 60 * 1000;
  }
}
