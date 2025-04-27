// lib/models/user_profile.dart

import '../utils/utils.dart';
import 'session.dart';
import 'song.dart';
import 'statistics.dart';
import 'video.dart';
import 'preferences.dart';

class UserProfile {
  final String id;
  final ProfilePreferences preferences;
  final Map<String, Session> sessions;
  final Map<String, Song> songs;
  Statistics statistics; // Mutable
  final Map<String, Video> videos;

  UserProfile({
    required this.id,
    required this.preferences,
    required this.sessions,
    required this.songs,
    required this.statistics,
    required this.videos,
  });

  static UserProfile defaultProfile() {
    return UserProfile(
      id: 'none',
      preferences: ProfilePreferences.defaultPreferences(),
      sessions: {},
      songs: {},
      statistics: Statistics.defaultStatistics(),
      videos: {},
    );
  }

  factory UserProfile.fromJson(String id, Map<String, dynamic> json) {
    final sessionsJson = normalizeFirebaseJson(json['sessions'] ?? {});
    final songsJson = normalizeFirebaseJson(json['songs'] ?? {});
    final videosJson = normalizeFirebaseJson(json['videos'] ?? {});
    final prefsJson = normalizeFirebaseJson(json['preferences'] ?? {});
    final statisticsJson = normalizeFirebaseJson(json['statistics'] ?? {});

    final sessions = <String, Session>{
      for (final entry in sessionsJson.entries)
        entry.key: Session.fromJson(normalizeFirebaseJson(entry.value)),
    };

    final songs = <String, Song>{
      for (final entry in songsJson.entries)
        entry.key: Song.fromJson(entry.key, normalizeFirebaseJson(entry.value)),
    };

    final videos = <String, Video>{
      for (final entry in videosJson.entries)
        entry.key: Video.fromKeyAndJson(
          entry.key,
          normalizeFirebaseJson(entry.value),
        ),
    };

    final stats = Statistics.fromJson(statisticsJson);
    final prefs = ProfilePreferences.fromJson(prefsJson);

    return UserProfile(
      id: id,
      preferences: prefs,
      sessions: sessions,
      songs: songs,
      statistics: stats,
      videos: videos,
    );
  }

  UserProfile copyWith({
    String? id,
    ProfilePreferences? preferences,
    Map<String, Session>? sessions,
    Map<String, Song>? songs,
    Statistics? statistics,
    Map<String, Video>? videos,
  }) {
    return UserProfile(
      id: id ?? this.id,
      preferences: preferences ?? this.preferences,
      sessions: sessions ?? this.sessions,
      songs: songs ?? this.songs,
      statistics: statistics ?? this.statistics,
      videos: videos ?? this.videos,
    );
  }
}
