import '../models/session.dart';

/// Utility for formatting a session ID (timestamp in seconds or ms) to a readable string.
String sessionIdToReadableString(String sessionId) {
  int timestamp;
  try {
    timestamp = int.parse(sessionId);
  } catch (_) {
    return 'Invalid date';
  }
  // If timestamp is in seconds, convert to ms
  if (timestamp < 1000000000000) {
    timestamp = timestamp * 1000;
  }
  final date = DateTime.fromMillisecondsSinceEpoch(timestamp);
  final months = [
    'January',
    'February',
    'March',
    'April',
    'May',
    'June',
    'July',
    'August',
    'September',
    'October',
    'November',
    'December',
  ];
  final mmmm = months[date.month - 1];
  final dd = date.day.toString().padLeft(2, '0');
  final yyyy = date.year;
  final hh = date.hour.toString().padLeft(2, '0');
  final mm = date.minute.toString().padLeft(2, '0');
  return '$dd-$mmmm-$yyyy $hh:$mm';
}

/// Converts an integer number of seconds to a string formatted as HH:mm
String intSecondsToHHmm(int seconds) {
  final int hours = seconds ~/ 3600;
  final int minutes = (seconds % 3600) ~/ 60;
  return '${hours.toString().padLeft(2, '0')}:${minutes.toString().padLeft(2, '0')}';
}

/// Converts a double number of seconds to a string formatted as HH:mm
String doubleSecondsToHHmm(double seconds) {
  final int hours = seconds ~/ 3600;
  final int minutes = (seconds % 3600) ~/ 60;
  return '${hours.toString().padLeft(2, '0')}:${minutes.toString().padLeft(2, '0')}';
}

/// Recalculates the duration for a session (sum of all category times + warmup).
int recalculateSessionDuration(Session session) {
  final categorySum = session.categories.values.fold<int>(
    0,
    (prev, cat) => prev + (cat.time),
  );
  final warmup = session.warmupTime ?? 0;
  return categorySum + warmup;
}

/// Returns a map of sessionId to correct duration for sessions whose durations are wrong.
Map<String, int> findSessionsWithWrongDuration(Map<String, Session> sessions) {
  final wrongs = <String, int>{};
  sessions.forEach((id, session) {
    final correct = recalculateSessionDuration(session);
    if (session.duration != correct) {
      wrongs[id] = correct;
    }
  });
  return wrongs;
}
