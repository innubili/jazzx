// import 'package:provider/provider.dart';
import 'dart:math';
import '../models/session.dart';
import '../models/practice_category.dart';
import '../providers/user_profile_provider.dart';
import '../utils/utils.dart'; // For log

/// Saves the current session as a draft in user preferences if it has content.
Future<void> saveDraftSession(
  UserProfileProvider profileProvider,
  Session session,
) async {
  final prefs = profileProvider.profile?.preferences;
  final String logPrefix = 'saveDraftSession ${session.asLogString()}';

  if (prefs != null) {
    // Skip saving ONLY if the session has no timed content (warmup or categories).
    // session.duration should reflect the sum of warmup and all category times.
    if (session.duration == 0) {
      log.info('$logPrefix skipped (empty or no duration)');
      return; // Don't save if there's no duration
    }

    // If we reach here, there is content, so save the draft.
    try {
      await profileProvider.saveUserPreferences(
        prefs.copyWith(draftSession: session.toJson()),
      );
      log.info('$logPrefix done');
    } catch (e) {
      log.severe('$logPrefix failed: $e');
    }
  } else {
    log.warning('$logPrefix skipped (no preferences found)');
  }
}

/// Clears the draft session from user preferences.
Future<void> clearDraftSession(UserProfileProvider provider) async {
  final prefs = provider.profile?.preferences;
  log.info(
    'clearDraftSession called - prefs: ${prefs != null ? "found" : "null"}, draftSession: ${prefs?.draftSession != null ? "exists" : "null"}',
  );

  if (prefs != null) {
    log.info(
      'clearDraftSession - before clear: draftSession exists = ${prefs.draftSession != null}',
    );

    // Create a new UserPreferences object with draftSession set to null
    final clearedPrefs = prefs.copyWith(clearDraftSession: true);
    log.info(
      'clearDraftSession - after copyWith: draftSession exists = ${clearedPrefs.draftSession != null}',
    );

    await provider.saveUserPreferences(clearedPrefs);
    log.info('clearDraftSession - after save: preferences saved to provider');

    // Verify the draft session was actually cleared
    final verifyPrefs = provider.profile?.preferences;
    log.info(
      'clearDraftSession - verification: draftSession exists = ${verifyPrefs?.draftSession != null}',
    );

    log.info('clearDraftSession done - draft session cleared');
  } else {
    log.warning('clearDraftSession skipped (no preferences found)');
  }
}
