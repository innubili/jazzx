import 'package:flutter/material.dart';
import '../models/user_profile.dart';
import '../models/song.dart';
import '../models/link.dart';
import '../models/session.dart';
import '../models/preferences.dart';
import '../models/statistics.dart';
import '../services/firebase_service.dart';

class UserProfileProvider extends ChangeNotifier {
  UserProfile? _profile;
  String? _userId;
  Map<String, dynamic> _rawJson = {};

  UserProfile? get profile => _profile;
  String? get userId => _userId;
  Map<String, dynamic> get rawJson => _rawJson;

  /// Loads the user profile from Firebase
  Future<void> loadUserProfile() async {
    final profile = await FirebaseService().loadUserProfile();
    if (profile != null) {
      _profile = profile;
      _userId = profile.id;
      notifyListeners();
    }
  }

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
    print('[UserProfileProvider] Saving session $sessionId: ${session.toJson()}');
    print('[UserProfileProvider] All sessions before save:');
    newSessions.forEach((k, v) => print('  $k: ${v.toJson()}'));

    // Update lastSessionId if needed
    String lastSessionId = _profile!.preferences.lastSessionId;
    ProfilePreferences prefsToSave = _profile!.preferences;
    if (lastSessionId.isEmpty || int.parse(sessionId) > int.parse(lastSessionId)) {
      prefsToSave = _profile!.preferences.copyWith(lastSessionId: sessionId);
      await FirebaseService().savePreferences(prefsToSave);
    }
    // Update profile in memory
    _profile = _profile!.copyWith(
      preferences: prefsToSave,
      sessions: newSessions,
    );
    try {
      // Only persist the single session
      await FirebaseService().saveSingleSession(_userId!, sessionId, session);
      print('[UserProfileProvider] Single session successfully saved to Firebase.');
    } catch (e, st) {
      print('[UserProfileProvider] ERROR saving single session to Firebase: $e\n$st');
      rethrow;
    }
    WidgetsBinding.instance.addPostFrameCallback((_) {
      notifyListeners();
    });
  }
}
