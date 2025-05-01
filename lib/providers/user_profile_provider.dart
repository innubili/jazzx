import 'package:flutter/material.dart';
import '../models/user_profile.dart';
import '../models/song.dart';
import '../models/link.dart';
import '../models/session.dart';
import '../models/preferences.dart';
import '../models/statistics.dart';
import '../services/firebase_service.dart';
import '../utils/utils.dart';
import '../utils/statistics_utils.dart';

class UserProfileProvider extends ChangeNotifier {
  UserProfile? _profile;
  String? _userId;
  Map<String, dynamic> _rawJson = {};

  UserProfile? get profile => _profile;
  String? get userId => _userId;
  Map<String, dynamic> get rawJson => _rawJson;

  /*
  /// Loads the user profile from Firebase
  Future<void> loadUserProfile() async {
    final profile = await FirebaseService().loadUserProfile();
    if (profile != null) {
      _profile = profile;
      _userId = profile.id;
      notifyListeners();
    }
  }
*/
  /// Allows manually setting the user profile from raw JSON (optional fallback)
  void setUser({
    required String userId,
    required Map<String, dynamic> profile,
  }) {
    final sanitizedUserId = userId.replaceAll('.', '_');
    _userId = sanitizedUserId;
    _profile = UserProfile.fromJson(
      sanitizedUserId,
      Map<String, dynamic>.from(profile),
    );
    _rawJson = profile;
    WidgetsBinding.instance.addPostFrameCallback((_) {
      notifyListeners();
    });
  }

  void setUserFromObject(UserProfile profile) {
    _userId = profile.id;
    _profile = profile;
    _rawJson = {}; // or maybe profile.toJson() if needed
    WidgetsBinding.instance.addPostFrameCallback((_) {
      notifyListeners();
    });
    // --- Check if statistics dirty and recalculate if needed ---
    if (profile.preferences.statisticsDirty) {
      log.info(
        '[UserProfileProvider] statisticsDirty flag is TRUE on setUserFromObject. Triggering full statistics recalculation.',
      );
      recalculateStatisticsFromAllSessionsAndClearFlag();
    } else {
      log.info(
        '[UserProfileProvider] statisticsDirty flag is FALSE on setUserFromObject. No recalculation needed.',
      );
    }
  }

  void removeSong(String title) {
    if (_profile?.songs.containsKey(title) ?? false) {
      _profile!.songs.remove(title);
      if (_profile != null && _userId != null) {
        FirebaseService().saveUserSongs(_userId!, _profile!.songs);
      }
      WidgetsBinding.instance.addPostFrameCallback((_) {
        notifyListeners();
      });
    }
  }

  void updateSong(Song song) {
    _profile?.songs[song.title] = song;
    if (_profile != null && _userId != null) {
      FirebaseService().saveUserSongs(_userId!, _profile!.songs);
    }
    WidgetsBinding.instance.addPostFrameCallback((_) {
      notifyListeners();
    });
  }

  void addSong(Song song) {
    if (_profile == null) return;
    _profile!.songs[song.title] = song;
    if (_userId != null) {
      FirebaseService().saveUserSongs(_userId!, _profile!.songs);
    }
    WidgetsBinding.instance.addPostFrameCallback((_) {
      notifyListeners();
    });
  }

  // Add, update, and remove song links with partial update to Firebase
  void addSongLink(String songTitle, Link link) {
    if (_profile == null || _userId == null) return;
    final song = _profile!.songs[songTitle];
    if (song == null) return;
    final updatedLinks = [...song.links, link];
    _profile!.songs[songTitle] = song.copyWith(links: updatedLinks);
    FirebaseService().saveSongLinks(_userId!, songTitle, updatedLinks);
    WidgetsBinding.instance.addPostFrameCallback((_) {
      notifyListeners();
    });
  }

  void updateSongLink(String songTitle, Link updatedLink) {
    if (_profile == null || _userId == null) return;
    final song = _profile!.songs[songTitle];
    if (song == null) return;
    final updatedLinks =
        song.links
            .map((l) => l.key == updatedLink.key ? updatedLink : l)
            .toList();
    _profile!.songs[songTitle] = song.copyWith(links: updatedLinks);
    FirebaseService().saveSongLinks(_userId!, songTitle, updatedLinks);
    WidgetsBinding.instance.addPostFrameCallback((_) {
      notifyListeners();
    });
  }

  void removeSongLink(String songTitle, String linkKey) {
    if (_profile == null || _userId == null) return;
    final song = _profile!.songs[songTitle];
    if (song == null) return;
    final updatedLinks = song.links.where((l) => l.key != linkKey).toList();
    _profile!.songs[songTitle] = song.copyWith(links: updatedLinks);
    FirebaseService().saveSongLinks(_userId!, songTitle, updatedLinks);
    WidgetsBinding.instance.addPostFrameCallback((_) {
      notifyListeners();
    });
  }

  // Save only the user's statistics to Firebase (partial update)
  Future<void> saveUserStatistics(Statistics stats) async {
    if (_profile == null || _userId == null) return;
    _profile = _profile!.copyWith(statistics: stats);
    await FirebaseService().saveStatistics(
      stats,
    ); // Use consistent key logic inside FirebaseService
    WidgetsBinding.instance.addPostFrameCallback((_) {
      notifyListeners();
    });
  }

  // Save only the user's preferences to Firebase (partial update)
  Future<void> saveUserPreferences(ProfilePreferences prefs) async {
    if (_profile == null || _userId == null) return;
    _profile = _profile!.copyWith(preferences: prefs);
    await FirebaseService().savePreferences(prefs);
    WidgetsBinding.instance.addPostFrameCallback((_) {
      notifyListeners();
    });
  }

  // --- STATISTICS MANAGEMENT ---

  /// Loads statistics from the user profile (Firebase).
  Statistics? get statistics => _profile?.statistics;

  /// Updates statistics in the user profile and saves to Firebase.
  Future<void> updateStatistics(Statistics newStats) async {
    if (_profile == null || _userId == null) return;
    _profile = _profile!.copyWith(statistics: newStats);
    await FirebaseService().saveStatistics(
      newStats,
    ); // Implement this in FirebaseService
    notifyListeners();
  }

  /// Update a single session in the user profile and save to Firebase.
  Future<void> updateSession(String sessionId, Session updated) async {
    if (_profile == null || _userId == null) return;
    _profile!.sessions[sessionId] = updated;
    await FirebaseService().saveUserProfile(_profile!);
    WidgetsBinding.instance.addPostFrameCallback((_) {
      notifyListeners();
    });
  }

  /// Save a session and update lastSessionId in preferences if needed, but only persist the single session to Firebase.
  Future<void> saveSessionWithId(String sessionId, Session session) async {
    if (_profile == null || _userId == null) return;
    final newSessions = Map<String, Session>.from(_profile!.sessions);
    newSessions[sessionId] = session;

    // Debug: Print session to be saved
    // log.info('[UserProfileProvider] Saving session $sessionId: ${session.toJson()}');
    // Update lastSessionId if needed
    ProfilePreferences prefsToSave = _profile!.preferences;
    if (prefsToSave.lastSessionId.isEmpty ||
        int.parse(sessionId) > int.parse(prefsToSave.lastSessionId)) {
      prefsToSave = prefsToSave.copyWith(lastSessionId: sessionId);
    }
    // Update profile in memory
    _profile = _profile!.copyWith(
      preferences: prefsToSave,
      sessions: newSessions,
    );
    try {
      // Only persist the single session
      await FirebaseService().saveSingleSession(_userId!, sessionId, session);
      // Mark statistics as dirty
      prefsToSave = prefsToSave.copyWith(statisticsDirty: true);
      await FirebaseService().savePreferences(prefsToSave);
      // Immediately trigger recalculation if dirty
      if (prefsToSave.statisticsDirty) {
        log.info('[UserProfileProvider] statisticsDirty flag is TRUE after saveSessionWithId. Triggering full statistics recalculation.');
        await recalculateStatisticsFromAllSessionsAndClearFlag();
      }
    } catch (e, st) {
      log.info(
        '[UserProfileProvider] ERROR saving single session to Firebase: $e\n$st',
      );
      rethrow;
    }
    WidgetsBinding.instance.addPostFrameCallback((_) {
      notifyListeners();
    });
  }

  /// Loads only the last session at startup (from preferences.lastSessionId).
  Future<Session?> loadLastSession() async {
    await FirebaseService().ensureInitialized();
    final prefs = await FirebaseService().getPreferences();
    if (prefs == null || prefs.lastSessionId.isEmpty) return null;
    final session = await FirebaseService().loadSingleSession(
      prefs.lastSessionId,
    );
    if (session != null && _profile != null) {
      _profile = _profile!.copyWith(sessions: {prefs.lastSessionId: session});
      WidgetsBinding.instance.addPostFrameCallback((_) {
        notifyListeners();
      });
    }
    return session;
  }

  /// Loads a page of sessions for session log/statistics (latest first, paginated)
  /// Also loads the first page at startup for fast access to lastSessionId & session log.
  Future<List<MapEntry<String, Session>>> loadInitialSessionsPage({
    int pageSize = 100,
  }) async {
    final entries = await FirebaseService().loadSessionsPage(
      pageSize: pageSize,
      startAfterId: null,
    );
    if (_profile != null) {
      // Merge into profile.sessions (avoid duplicates)
      final newSessions = Map<String, Session>.from(_profile!.sessions);
      for (var entry in entries) {
        newSessions[entry.key] = entry.value;
      }
      // Update lastSessionId to latest if available
      String? latestId = entries.isNotEmpty ? entries.first.key : null;
      ProfilePreferences prefs = _profile!.preferences;
      if (latestId != null &&
          (prefs.lastSessionId.isEmpty ||
              int.parse(latestId) > int.parse(prefs.lastSessionId))) {
        prefs = prefs.copyWith(lastSessionId: latestId);
      }
      _profile = _profile!.copyWith(sessions: newSessions, preferences: prefs);
      WidgetsBinding.instance.addPostFrameCallback((_) {
        notifyListeners();
      });
    }
    return entries;
  }

  /// Loads a page of sessions for session log/statistics (latest first, paginated)
  Future<List<MapEntry<String, Session>>> loadSessionsPage({
    int pageSize = 20,
    String? startAfterId,
  }) async {
    final entries = await FirebaseService().loadSessionsPage(
      pageSize: pageSize,
      startAfterId: startAfterId,
    );
    if (_profile != null) {
      // Merge into profile.sessions (avoid duplicates)
      final newSessions = Map<String, Session>.from(_profile!.sessions);
      for (var entry in entries) {
        newSessions[entry.key] = entry.value;
      }
      _profile = _profile!.copyWith(sessions: newSessions);
      WidgetsBinding.instance.addPostFrameCallback((_) {
        notifyListeners();
      });
    }
    return entries;
  }

  /// Remove a session by its sessionId and update Firebase and local profile.
  Future<void> removeSessionById(String sessionId) async {
    if (_profile == null || _userId == null) return;
    final newSessions = Map<String, Session>.from(_profile!.sessions);
    newSessions.remove(sessionId);
    // Update lastSessionId if needed
    ProfilePreferences prefsToSave = _profile!.preferences;
    if (_profile!.preferences.lastSessionId == sessionId) {
      // Set lastSessionId to latest remaining session or empty
      String newLast = '';
      if (newSessions.isNotEmpty) {
        newLast = newSessions.keys.reduce(
          (a, b) => int.parse(a) > int.parse(b) ? a : b,
        );
      }
      prefsToSave = prefsToSave.copyWith(lastSessionId: newLast);
    }
    _profile = _profile!.copyWith(
      sessions: newSessions,
      preferences: prefsToSave,
    );
    try {
      await FirebaseService().removeSingleSession(_userId!, sessionId);
      log.info(
        '[UserProfileProvider] Removed session $sessionId from Firebase.',
      );
      // Mark statistics as dirty
      prefsToSave = prefsToSave.copyWith(statisticsDirty: true);
      await FirebaseService().savePreferences(prefsToSave);
      // Immediately trigger recalculation if dirty
      if (prefsToSave.statisticsDirty) {
        log.info('[UserProfileProvider] statisticsDirty flag is TRUE after removeSessionById. Triggering full statistics recalculation.');
        await recalculateStatisticsFromAllSessionsAndClearFlag();
      }
    } catch (e, st) {
      log.info(
        '[UserProfileProvider] ERROR removing session from Firebase: $e\n$st',
      );
      rethrow;
    }
    WidgetsBinding.instance.addPostFrameCallback((_) {
      notifyListeners();
    });
  }

  /// Recalculate statistics from all sessions and clear the dirty flag
  Future<void> recalculateStatisticsFromAllSessionsAndClearFlag() async {
    if (_profile == null || _userId == null) return;
    log.info(
      '[UserProfileProvider] Starting full statistics recalculation from all sessions...',
    );
    final sessions = _profile!.sessions.values.toList();
    final updatedStats = recalculateStatisticsFromSessions(sessions);
    // Update statistics and clear dirty flag
    final updatedPrefs = _profile!.preferences.copyWith(statisticsDirty: false);
    _profile = _profile!.copyWith(
      statistics: updatedStats,
      preferences: updatedPrefs,
    );
    await FirebaseService().saveStatistics(updatedStats);
    await FirebaseService().savePreferences(updatedPrefs);
    log.info(
      '[UserProfileProvider] Full statistics recalculation complete. statisticsDirty flag reset to FALSE.',
    );
    notifyListeners();
  }
}
