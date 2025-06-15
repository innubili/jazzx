import '../services/firebase_service.dart';
import '../models/practice_category.dart';
import '../models/session.dart';
import '../utils/utils.dart';
import '../utils/session_utils.dart';
import '../core/logging/app_loggers.dart';

/// Utility to fix legacy/invalid session data in Firebase by:
/// - Fixing 'strted' typo to 'started' field using sessionId as the correct timestamp
/// - Removing or correcting invalid practice categories (e.g., 'warmup')
/// - Fixing session duration and ensuring session.ended is correct
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

        // --- Fix 'strted' typo: use sessionId as the correct 'started' value ---
        int correctStarted;
        try {
          correctStarted = int.parse(sessionId);
        } catch (_) {
          correctStarted = session.started; // fallback to existing value
        }

        // --- Fix duration ---
        final correctDuration = recalculateSessionDuration(session);

        // --- Fix ended ---
        final correctEnded = correctStarted + correctDuration;

        // Update session with corrected values
        session = session.copyWith(
          started: correctStarted, // This will set the 'started' property
          duration: correctDuration,
          ended: correctEnded,
        );

        // Remove categories with time == 0 before saving
        final cleanedCategories = <PracticeCategory, SessionCategory>{
          for (final cat in session.categories.entries)
            if (cat.value.time > 0) cat.key: cat.value,
        };
        final fixedSession = session.copyWith(categories: cleanedCategories);

        // Create JSON with correct field names: 'started' instead of 'strted'
        final sessionJson = fixedSession.toJson();
        sessionJson['started'] = fixedSession.started; // Add correct field
        sessionJson.remove('strted'); // Remove typo field

        await ref.child(sessionId).set(sessionJson);
        fixedCount++;
      } catch (e, st) {
        AppLoggers.error.error(
          'Error fixing session',
          metadata: {'session_id': sessionId, 'error': e.toString()},
          stackTrace: st.toString(),
        );
        errorCount++;
      }
    }
    AppLoggers.system.info(
      'Firebase sessions fixed',
      metadata: {'fixed_count': fixedCount, 'error_count': errorCount},
    );
  } catch (e, st) {
    AppLoggers.error.fatal(
      'Fatal error fixing Firebase sessions',
      error: e.toString(),
      stackTrace: st.toString(),
    );
    rethrow;
  }
}

// --- Fix legacy song.links keys in Firebase ---
Future<void> fixSongLinks() async {
  try {
    await FirebaseService().ensureInitialized();
    final userKey = FirebaseService().currentUserUid;
    if (userKey == null) throw Exception('No current user.');
    final ref = FirebaseService().dbRef('users/$userKey/songs');
    final snapshot = await ref.get();
    if (!snapshot.exists || snapshot.value == null) return;
    final songsRaw = normalizeFirebaseJson(snapshot.value);
    int fixedCount = 0;
    int errorCount = 0;

    for (final entry in (songsRaw as Map<String, dynamic>).entries) {
      final songKey = entry.key;
      try {
        final songMap = asStringKeyedMap(entry.value);
        final linksRaw = asStringKeyedMap(songMap['links']);
        final fixedLinks = <String, dynamic>{};
        for (final linkEntry in linksRaw.entries) {
          final oldKey = linkEntry.key;
          final linkData = linkEntry.value;

          // Step 1: Try to recover the original URL from the key (handle over-encoded keys)
          String decodedKey = oldKey;
          // Repeatedly decode percent-encoding until it stabilizes
          String prevDecoded;
          do {
            prevDecoded = decodedKey;
            decodedKey = Uri.decodeComponent(decodedKey);
          } while (decodedKey != prevDecoded && decodedKey.contains('%'));

          // Step 2: Convert Firebase-safe '_' back to '.'
          String possibleUrl = decodedKey.replaceAll('_', '.');

          // Step 3: If the URL starts with 'http' or 'https', treat as valid link
          if (possibleUrl.startsWith('http://') ||
              possibleUrl.startsWith('https://')) {
            final sanitizedKey = sanitizeLinkKey(possibleUrl);
            final updatedLinkData = Map<String, dynamic>.from(linkData as Map);
            updatedLinkData['link'] = possibleUrl;
            fixedLinks[sanitizedKey] = updatedLinkData;
          }
          // Otherwise, ignore or log invalid links
        }
        // Update in Firebase if any keys were changed
        await ref.child(songKey).child('links').set(fixedLinks);
        fixedCount++;
      } catch (e, st) {
        AppLoggers.error.error(
          'Error fixing song links',
          metadata: {'song_key': songKey, 'error': e.toString()},
          stackTrace: st.toString(),
        );
        errorCount++;
      }
    }
    AppLoggers.system.info(
      'Song links fixed',
      metadata: {'fixed_count': fixedCount, 'error_count': errorCount},
    );
  } catch (e, st) {
    AppLoggers.error.fatal(
      'Fatal error fixing song links',
      error: e.toString(),
      stackTrace: st.toString(),
    );
    rethrow;
  }
}
