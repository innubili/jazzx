import 'dart:math';
import '../models/session.dart';
import '../models/practice_category.dart';
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

/// Converts an integer number of seconds to a string formatted as HH:mm:ss
String intSecondsToHHmmss(int seconds) {
  final int hours = seconds ~/ 3600;
  final int minutes = (seconds % 3600) ~/ 60;
  final int secs = seconds % 60;
  return '${hours.toString().padLeft(2, '0')}:${minutes.toString().padLeft(2, '0')}:${secs.toString().padLeft(2, '0')}';
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

/// Creates a random draft session for testing purposes.
///
/// Parameters:
/// - [totalDuration]: Either 6-10 minutes or 20-180 minutes (in seconds)
/// - [withWarmup]: Whether to include a warmup (random 1-3 minutes if true)
/// - [sessionId]: Optional session ID (defaults to now() - duration for realistic timeline)
/// - [instrument]: Instrument name (defaults to 'guitar')
///
/// The function ensures:
/// - At least 2 practice categories with time allocated
/// - First category gets 1/3 of practice time, second gets 2/3
/// - Remaining categories get 0 time
/// - Total duration matches the specified duration
/// - Started timestamp is set to now() - duration so session appears to have ended recently
Session createRandomDraftSession({
  int? totalDuration,
  bool? withWarmup,
  int? sessionId,
  String instrument = 'guitar',
}) {
  final random = Random();

  // Generate random total duration if not provided
  final duration = totalDuration ?? _generateRandomDuration(random);

  // Generate random warmup decision if not provided
  final hasWarmup = withWarmup ?? random.nextBool();

  // Calculate warmup time (1-3 minutes if enabled)
  final warmupTime =
      hasWarmup ? (60 + random.nextInt(120)) : 0; // 60-180 seconds

  // Calculate remaining time for practice categories
  final practiceTime = duration - warmupTime;

  // Select 2 random practice categories from the ones used in PracticeModeButtonsWidget
  final availableCategories = [
    PracticeCategory.exercise,
    PracticeCategory.newsong,
    PracticeCategory.repertoire,
    PracticeCategory.fun,
  ];
  availableCategories.shuffle(random);
  final selectedCategories = availableCategories.take(2).toList();

  // Allocate time: first category gets 1/3, second gets 2/3
  final firstCategoryTime = (practiceTime * 0.33).round();
  final secondCategoryTime = practiceTime - firstCategoryTime;

  // Create categories map
  final categories = <PracticeCategory, SessionCategory>{};
  for (final category in PracticeCategory.values) {
    int categoryTime = 0;
    if (category == selectedCategories[0]) {
      categoryTime = firstCategoryTime;
    } else if (category == selectedCategories[1]) {
      categoryTime = secondCategoryTime;
    }

    categories[category] = SessionCategory(
      time: categoryTime,
      note: categoryTime > 0 ? 'Random practice session' : null,
      bpm: categoryTime > 0 ? (60 + random.nextInt(120)) : null, // 60-180 BPM
    );
  }

  // Create warmup if enabled
  final warmup =
      hasWarmup
          ? Warmup(
            time: warmupTime,
            bpm: 60 + random.nextInt(60), // 60-120 BPM for warmup
          )
          : null;

  // Generate session ID (timestamp) - should be now() - duration for realistic timeline
  final now = DateTime.now();
  final id =
      sessionId ??
      (now.subtract(Duration(seconds: duration)).millisecondsSinceEpoch ~/
          1000);

  return Session(
    started: id,
    duration: duration,
    ended: 0, // Draft session, not ended yet
    instrument: instrument,
    categories: categories,
    warmup: warmup,
  );
}

/// Generates a random duration: either 6-10 minutes or 20-180 minutes
int _generateRandomDuration(Random random) {
  final useShortDuration = random.nextBool();

  if (useShortDuration) {
    // 6-10 minutes (360-600 seconds)
    return 360 + random.nextInt(241); // 360 + 0-240
  } else {
    // 20-180 minutes (1200-10800 seconds)
    return 1200 + random.nextInt(9601); // 1200 + 0-9600
  }
}
