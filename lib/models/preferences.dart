// ignore_for_file: constant_identifier_names

import '../utils/utils.dart';

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
  final bool autoPause;
  final int pauseEvery; // stored in seconds shown in minutes
  final int pauseBreak; // stored in seconds shown in minutes

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
    required this.pauseEvery,
    required this.pauseBreak,
  });

  factory ProfilePreferences.fromJson(Map<String, dynamic> json) {
    final map = asStringKeyedMap(json);
    List<String> instruments;
    final instrumentField = map['instrument'] ?? map['instruments'];
    if (instrumentField is String) {
      instruments = [instrumentField];
    } else if (instrumentField is List) {
      instruments = List<String>.from(instrumentField);
    } else {
      instruments = [];
    }
    return ProfilePreferences(
      darkMode: map['darkMode'] ?? false,
      exerciseBpm: map['exerciseBpm'] ?? 100,
      instruments: instruments,
      admin: map['admin'] ?? false,
      pro: map['pro'] ?? false,
      metronomeEnabled: map['metronomeEnabled'] ?? true,
      name: map['name'] ?? '',
      teacher: map['teacher'] ?? '',
      warmupBpm: map['warmupBpm'] ?? 80,
      warmupEnabled: map['warmupEnabled'] ?? true,
      warmupTime: map['warmupTime'] ?? 300,
      lastSessionId: map['lastSessionId'] ?? '',
      autoPause: map['autoPause'] ?? false,
      pauseEvery: map['pauseEveryMinutes'] ?? 20,
      pauseBreak: map['pauseBreakMinutes'] ?? 4,
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
    'pauseEveryMinutes': pauseEvery,
    'pauseBreakMinutes': pauseBreak,
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
      pauseEvery: 1800,
      pauseBreak: 240,
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
    int? pauseEvery,
    int? pauseBreak,
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
      pauseEvery: pauseEvery ?? this.pauseEvery,
      pauseBreak: pauseBreak ?? this.pauseBreak,
    );
  }
}
