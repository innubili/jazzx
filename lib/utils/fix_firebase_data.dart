import '../services/firebase_service.dart';
import '../models/practice_category.dart';
import '../models/session.dart';
import '../utils/utils.dart';
import '../utils/session_utils.dart';

/// Utility to fix legacy/invalid session data in Firebase by removing or correcting invalid practice categories (e.g., 'warmup'),
/// fixing session duration, and ensuring session.ended is correct.
Future<void> fixFirebaseSessions() async {
  try {
    await FirebaseService().ensureInitialized();
    // ignore: invalid_use_of_protected_member
    final userKey = FirebaseService().currentUserUid;
    if (userKey == null) throw Exception('No current user.');
    final ref = FirebaseService().dbRef('users/$userKey/sessions');
    final snapshot = await ref.get();
    if (!snapshot.exists || snapshot.value == null) return;
    final sessionsRaw = normalizeFirebaseJson(snapshot.value);
    int fixedCount = 0;
    int errorCount = 0;

    for (final entry in (sessionsRaw as Map<String, dynamic>).entries) {
      final sessionId = entry.key;
      try {
        final sessionMap = entry.value as Map<String, dynamic>;
        var session = Session.fromJson(sessionMap);

        // --- Fix duration ---
        final correctDuration = recalculateSessionDuration(session);
        // --- Fix ended ---
        int sessionStart;
        try {
          sessionStart = int.parse(sessionId);
        } catch (_) {
          sessionStart = session.ended; // fallback
        }
        final correctEnded = sessionStart + correctDuration;

        // Only update if fixes are needed
        if (session.duration != correctDuration || session.ended != correctEnded) {
          session = session.copyWith(
            duration: correctDuration,
            ended: correctEnded,
          );
        }

        // Remove categories with time == 0 before saving
        final cleanedCategories = <PracticeCategory, SessionCategory>{
          for (final cat in session.categories.entries)
            if (cat.value.time > 0) cat.key: cat.value
        };
        final fixedSession = session.copyWith(categories: cleanedCategories);
        await ref.child(sessionId).set(fixedSession.toJson());
        fixedCount++;
      } catch (e, st) {
        log.severe('[fixFirebaseSessions] Error fixing session $sessionId: $e\n$st');
        errorCount++;
      }
    }
    log.info('Fixed $fixedCount sessions with invalid categories or duration/ended. Errors: $errorCount');
  } catch (e, st) {
    log.severe('[fixFirebaseSessions] Fatal error: $e\n$st');
    rethrow;
  }
}
