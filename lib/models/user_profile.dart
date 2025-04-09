// lib/models/user_profile.dart
import 'session.dart';
import 'song.dart';
import 'statistics.dart';
import 'video.dart';

class UserProfile {
  final String id; // typically the user's email or UID
  final ProfileSettings profile;
  final Map<String, Session> sessions;
  final Map<String, Song> songs;
  final Statistics statistics;
  final Map<String, Video> videos;

  UserProfile({
    required this.id,
    required this.profile,
    required this.sessions,
    required this.songs,
    required this.statistics,
    required this.videos,
  });

  factory UserProfile.fromJson(String id, Map<String, dynamic> json) {
    final profileData = json['profile'] ?? {};
    final sessionsData = json['sessions'] ?? {};
    final songsData = json['songs'] ?? {};
    final statisticsData = json['statistics'] ?? {};
    final videosData = json['videos'] ?? {};

    return UserProfile(
      id: id,
      profile: ProfileSettings.fromJson(profileData),
      sessions: Map.fromEntries(
        sessionsData.entries.map((entry) =>
            MapEntry(entry.key, Session.fromJson(entry.value))),
      ),
      songs: Map.fromEntries(
        songsData.entries.map((entry) =>
            MapEntry(entry.key, Song.fromJson(entry.key, entry.value))),
      ),
      statistics: Statistics.fromJson(statisticsData),
      videos: Map.fromEntries(
        videosData.entries.map((entry) =>
            MapEntry(entry.key, Video.fromJson(entry.value))),
      ),
    );
  }
}

class ProfileSettings {
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

  ProfileSettings({
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
  });

  factory ProfileSettings.fromJson(Map<String, dynamic> json) {
    final internal = json['internal'] ?? {};
    return ProfileSettings(
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
    );
  }
}
