import '../utils/log.dart';
import 'session.dart';
import 'song.dart';
import 'statistics.dart';
import 'video.dart';

class UserProfile {
  final String id; // typically the user's email or UID
  final ProfilePreferences preferences;
  final Map<String, Session> sessions;
  final Map<String, Song> songs;
  final Statistics statistics;
  final Map<String, Video> videos;

  UserProfile({
    required this.id,
    required this.preferences,
    required this.sessions,
    required this.songs,
    required this.statistics,
    required this.videos,
  });

  // Static method to provide a default UserProfile
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
    final preferencesData = json['preferences'] ?? {};
    final sessionsData = json['sessions'] ?? {};
    final songsData = json['songs'] ?? {};
    final statisticsData = json['statistics'] ?? {};
    //    final videosData = json['videos'] ?? {};

    return UserProfile(
      id: id,
      preferences: ProfilePreferences.fromJson(preferencesData),
      sessions: (sessionsData as Map<String, dynamic>).map(
        (key, value) => MapEntry(key, Session.fromJson(value)),
      ),
      songs:
          (() {
            final Map<String, Song> parsedSongs = {};
            songsData.forEach((key, value) {
              if (value is Map<String, dynamic>) {
                parsedSongs[key] = Song.fromJson(key, value);
              } else {
                log.warning('Invalid song entry for key "$key" — skipped.');
              }
            });
            return parsedSongs;
          })(),
      statistics: Statistics.fromJson(statisticsData),
      videos:
          (json['videos'] as Map?)?.map(
            (key, value) => MapEntry(key as String, Video.fromJson(value)),
          ) ??
          {},
    );
  }
}

class ProfilePreferences {
  final bool darkMode;
  final int exerciseBpm;
  final String instrument;
  final bool admin;
  final bool pro;
  final bool metronomeEnabled;
  final bool multiEnabled;
  final String name;
  final String teacher;
  final int warmupBpm;
  final bool warmupEnabled;
  final int warmupTime;
  final String lastSessionId;

  static ProfilePreferences defaultPreferences() {
    return ProfilePreferences(
      darkMode: false,
      exerciseBpm: 100,
      instrument: '',
      admin: false,
      pro: false,
      metronomeEnabled: true,
      multiEnabled: false,
      name: '',
      teacher: '',
      warmupBpm: 80,
      warmupEnabled: true,
      warmupTime: 300,
      lastSessionId: '',
    );
  }

  ProfilePreferences({
    required this.darkMode,
    required this.exerciseBpm,
    required this.instrument,
    required this.admin,
    required this.pro,
    required this.metronomeEnabled,
    required this.multiEnabled,
    required this.name,
    required this.teacher,
    required this.warmupBpm,
    required this.warmupEnabled,
    required this.warmupTime,
    required this.lastSessionId,
  });

  factory ProfilePreferences.fromJson(Map<String, dynamic> json) {
    final internal = json['internal'] ?? {};
    return ProfilePreferences(
      darkMode: json['darkMode'] ?? false,
      exerciseBpm: json['exerciseBpm'] ?? 100,
      instrument: json['instrument'] ?? '',
      admin: internal['admin'] ?? false,
      pro: internal['pro'] ?? false,
      metronomeEnabled: json['metronomeEnabled'] ?? true,
      multiEnabled: json['multiEnabled'] ?? false,
      name: json['name'] ?? '',
      teacher: json['teacher'] ?? '',
      warmupBpm: json['warmupBpm'] ?? 80,
      warmupEnabled: json['warmupEnabled'] ?? true,
      warmupTime: json['warmupTime'] ?? 300,
      lastSessionId: json['lastSessionId'] ?? '',
    );
  }
}
