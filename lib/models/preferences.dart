import '../utils/utils.dart';

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
    final map = asStringKeyedMap(json);
    return ProfilePreferences(
      darkMode: map['darkMode'] ?? false,
      exerciseBpm: map['exerciseBpm'] ?? 100,
      instrument: map['instrument'] ?? '',
      admin: map['admin'] ?? false,
      pro: map['pro'] ?? false,
      metronomeEnabled: map['metronomeEnabled'] ?? true,
      multiEnabled: map['multiEnabled'] ?? false,
      name: map['name'] ?? '',
      teacher: map['teacher'] ?? '',
      warmupBpm: map['warmupBpm'] ?? 80,
      warmupEnabled: map['warmupEnabled'] ?? true,
      warmupTime: map['warmupTime'] ?? 300,
      lastSessionId: map['lastSessionId'] ?? '',
    );
  }

  Map<String, dynamic> toJson() => {
    'darkMode': darkMode,
    'exerciseBpm': exerciseBpm,
    'instrument': instrument,
    'admin': admin,
    'pro': pro,
    'metronomeEnabled': metronomeEnabled,
    'multiEnabled': multiEnabled,
    'name': name,
    'teacher': teacher,
    'warmupBpm': warmupBpm,
    'warmupEnabled': warmupEnabled,
    'warmupTime': warmupTime,
    'lastSessionId': lastSessionId,
  };

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

  ProfilePreferences copyWith({
    bool? darkMode,
    int? exerciseBpm,
    String? instrument,
    bool? admin,
    bool? pro,
    bool? metronomeEnabled,
    bool? multiEnabled,
    String? name,
    String? teacher,
    int? warmupBpm,
    bool? warmupEnabled,
    int? warmupTime,
    String? lastSessionId,
  }) {
    return ProfilePreferences(
      darkMode: darkMode ?? this.darkMode,
      exerciseBpm: exerciseBpm ?? this.exerciseBpm,
      instrument: instrument ?? this.instrument,
      admin: admin ?? this.admin,
      pro: pro ?? this.pro,
      metronomeEnabled: metronomeEnabled ?? this.metronomeEnabled,
      multiEnabled: multiEnabled ?? this.multiEnabled,
      name: name ?? this.name,
      teacher: teacher ?? this.teacher,
      warmupBpm: warmupBpm ?? this.warmupBpm,
      warmupEnabled: warmupEnabled ?? this.warmupEnabled,
      warmupTime: warmupTime ?? this.warmupTime,
      lastSessionId: lastSessionId ?? this.lastSessionId,
    );
  }
}
