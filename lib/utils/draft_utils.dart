import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../providers/user_profile_provider.dart';
import '../models/session.dart';
import '../utils/utils.dart';

/// Saves the current session as a draft in user preferences if not ended.
/// This is reusable for SessionScreen and SessionReviewScreen.
void saveDraftSession(BuildContext context, Session session) {
  final profileProvider = Provider.of<UserProfileProvider>(
    context,
    listen: false,
  );
  final prefs = profileProvider.profile?.preferences;
  String s = 'saveDraftSession ${session.asLogString()}';
  bool done = false;

  if (prefs != null) {
    if (session.ended == 0 && session.duration == 0) {
      profileProvider.saveUserPreferences(
        prefs.copyWith(draftSession: session.toJson()),
      );
      done = true;
    } else {}
    log.info('$s ${done ? 'done' : 'skipped'}');
  }
}

/// Clears the draft session from user preferences.
Future<void> clearDraftSession(UserProfileProvider profileProvider) async {
  final prefs = profileProvider.profile?.preferences;
  if (prefs != null) {
    await profileProvider.saveUserPreferences(
      prefs.copyWith(draftSession: null),
    );
    log.info('Cleared draft session via clearDraftSession utility.');
  } else {
    log.warning('Attempted to clear draft session, but preferences were null.');
  }
}
