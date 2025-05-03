// ignore_for_file: constant_identifier_names

/// List of typical jazz instruments for selection in the app.
const List<String> Instruments = [
  'Piano',
  'Guitar',
  'Bass',
  'Double Bass',
  'Drums',
  'Trumpet',
  'Trombone',
  'Alto Saxophone',
  'Tenor Saxophone',
  'Baritone Saxophone',
  'Soprano Saxophone',
  'Clarinet',
  'Flute',
  'Vibraphone',
  'Violin',
  'Cello',
  'Voice',
];

class ProfilePreferences {
  final bool darkMode;
  final int exerciseBpm;
  final List<String> instruments;
  final bool admin;
  final bool pro;
  final bool metronomeEnabled;
  final String name;
  final String teacher;
  final int warmupBpm;
  final bool warmupEnabled;
  final int warmupTime; // stored in seconds shown in minutes
  final String lastSessionId;
  final bool autoPause; // auto pause feature enabled
  // Pause interval between breaks during practice (in seconds)
  final int pauseIntervalTime;
  // Duration of each break during practice (in seconds)
  final int pauseDurationTime;
  final bool statisticsDirty;

  ProfilePreferences({
    required this.darkMode,
    required this.exerciseBpm,
    required this.instruments,
    required this.admin,
    required this.pro,
    required this.metronomeEnabled,
    required this.name,
    required this.teacher,
    required this.warmupBpm,
    required this.warmupEnabled,
    required this.warmupTime,
    required this.lastSessionId,
    required this.autoPause,
    required this.pauseIntervalTime,
    required this.pauseDurationTime,
    this.statisticsDirty = false,
  });

  factory ProfilePreferences.fromJson(Map<String, dynamic> json) {
    return ProfilePreferences(
      darkMode: json['darkMode'] ?? false,
      exerciseBpm: json['exerciseBpm'] ?? 100,
      instruments: List<String>.from(json['instruments'] ?? []),
      admin: json['admin'] ?? false,
      pro: json['pro'] ?? false,
      metronomeEnabled: json['metronomeEnabled'] ?? true,
      name: json['name'] ?? '',
      teacher: json['teacher'] ?? '',
      warmupBpm: json['warmupBpm'] ?? 80,
      warmupEnabled: json['warmupEnabled'] ?? true,
      warmupTime: json['warmupTime'] ?? 300,
      lastSessionId: json['lastSessionId'] ?? '',
      autoPause: json['autoPause'] ?? false,
      pauseIntervalTime: json['pauseIntervalTime'] ?? 1800,
      pauseDurationTime: json['pauseDurationTime'] ?? 240,
      statisticsDirty: json['statisticsDirty'] ?? false,
    );
  }

  Map<String, dynamic> toJson() => {
    'darkMode': darkMode,
    'exerciseBpm': exerciseBpm,
    'instruments': instruments,
    'admin': admin,
    'pro': pro,
    'metronomeEnabled': metronomeEnabled,
    'name': name,
    'teacher': teacher,
    'warmupBpm': warmupBpm,
    'warmupEnabled': warmupEnabled,
    'warmupTime': warmupTime,
    'lastSessionId': lastSessionId,
    'autoPause': autoPause,
    'pauseIntervalTime': pauseIntervalTime,
    'pauseDurationTime': pauseDurationTime,
    'statisticsDirty': statisticsDirty,
  };

  static ProfilePreferences defaultPreferences() {
    return ProfilePreferences(
      darkMode: false,
      exerciseBpm: 100,
      instruments: [],
      admin: false,
      pro: false,
      metronomeEnabled: true,
      name: '',
      teacher: '',
      warmupBpm: 80,
      warmupEnabled: true,
      warmupTime: 300,
      lastSessionId: '',
      autoPause: false,
      pauseIntervalTime: 1800,
      pauseDurationTime: 240,
      statisticsDirty: false,
    );
  }

  ProfilePreferences copyWith({
    bool? darkMode,
    int? exerciseBpm,
    List<String>? instruments,
    bool? admin,
    bool? pro,
    bool? metronomeEnabled,
    String? name,
    String? teacher,
    int? warmupBpm,
    bool? warmupEnabled,
    int? warmupTime,
    String? lastSessionId,
    bool? autoPause,
    int? pauseIntervalTime,
    int? pauseDurationTime,
    bool? statisticsDirty,
  }) {
    return ProfilePreferences(
      darkMode: darkMode ?? this.darkMode,
      exerciseBpm: exerciseBpm ?? this.exerciseBpm,
      instruments: instruments ?? this.instruments,
      admin: admin ?? this.admin,
      pro: pro ?? this.pro,
      metronomeEnabled: metronomeEnabled ?? this.metronomeEnabled,
      name: name ?? this.name,
      teacher: teacher ?? this.teacher,
      warmupBpm: warmupBpm ?? this.warmupBpm,
      warmupEnabled: warmupEnabled ?? this.warmupEnabled,
      warmupTime: warmupTime ?? this.warmupTime,
      lastSessionId: lastSessionId ?? this.lastSessionId,
      autoPause: autoPause ?? this.autoPause,
      pauseIntervalTime: pauseIntervalTime ?? this.pauseIntervalTime,
      pauseDurationTime: pauseDurationTime ?? this.pauseDurationTime,
      statisticsDirty: statisticsDirty ?? this.statisticsDirty,
    );
  }
}
