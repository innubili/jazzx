import '../models/session.dart';
import '../services/firebase_service.dart';
import 'package:firebase_database/firebase_database.dart';

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
  final warmup = session.warmup?.time ?? 0;
  return categorySum + warmup;
}

/// Ensures duration and ended are recalculated before saving/updating a session.
Session recalculateSessionFields(Session session, {DateTime? manualEnded}) {
  final duration = recalculateSessionDuration(session);
  // If a manual ended time is provided, use it; otherwise, use the session's ended if valid, else now
  int ended;
  if (manualEnded != null) {
    ended = manualEnded.millisecondsSinceEpoch ~/ 1000;
  } else if (session.ended > 1000000000) {
    ended = session.ended;
  } else {
    ended = DateTime.now().millisecondsSinceEpoch ~/ 1000;
  }
  return session.copyWith(duration: duration, ended: ended);
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

/// Updates all sessions in Firebase for the current user, adding the .started field to each session.
Future<void> addStartedToAllSessionsInFirebase() async {
  final service = FirebaseService();
  await service.ensureInitialized();
  final userId = service.currentUserUid;
  if (userId == null) throw Exception('User not signed in');
  final sessionsRef = FirebaseDatabase.instance.ref('users/$userId/sessions');
  final snapshot = await sessionsRef.get();
  if (!snapshot.exists || snapshot.value == null) return;
  final sessionsMap = Map<String, dynamic>.from(snapshot.value as Map);
  for (final entry in sessionsMap.entries) {
    final sessionId = entry.key;
    final started = int.tryParse(sessionId) ?? 0;
    await sessionsRef.child(sessionId).update({'started': started});
  }
}
