// lib/models/session.dart

import 'practice_category.dart';

class SessionCategory {
  final int time;
  final String? note;
  final int? bpm;
  final Map<String, int>? songs;

  SessionCategory({required this.time, this.note, this.bpm, this.songs});

  factory SessionCategory.fromJson(Map<String, dynamic> json) =>
      SessionCategory(
        time: json['time'] ?? 0,
        note: json['note'],
        bpm: json['bpm'],
        songs: (json['songs'] as Map?)?.map((k, v) => MapEntry(k, v as int)),
      );
}

class Session {
  final int duration;
  final int ended;
  final String instrument;
  final Map<PracticeCategory, SessionCategory> categories;
  final int? warmupTime;
  final int? warmupBpm;

  Session({
    required this.duration,
    required this.ended,
    required this.instrument,
    required this.categories,
    this.warmupTime,
    this.warmupBpm,
  });

  factory Session.fromJson(Map<String, dynamic> json) {
    final categories = <PracticeCategory, SessionCategory>{};

    final categoriesJson = json['categories'] as Map<String, dynamic>? ?? {};

    for (var entry in categoriesJson.entries) {
      final category = entry.key.tryToPracticeCategory();
      if (category != null) {
        categories[category] = SessionCategory.fromJson(entry.value);
      }
    }

    final warmup = json['warmup'] ?? {};
    return Session(
      duration: json['duration'] ?? 0,
      ended: json['ended'] ?? 0,
      instrument: json['instrument'] ?? '',
      categories: categories,
      warmupTime: warmup['time'],
      warmupBpm: warmup['bpm'],
    );
  }

  Map<String, dynamic> toJson() {
    final Map<String, dynamic> json = {
      'duration': duration,
      'ended': ended,
      'instrument': instrument,
    };

    for (var entry in categories.entries) {
      json[entry.key.name] = {
        'time': entry.value.time,
        if (entry.value.note != null) 'note': entry.value.note,
        if (entry.value.bpm != null) 'bpm': entry.value.bpm,
        if (entry.value.songs != null) 'songs': entry.value.songs,
      };
    }

    json['warmup'] = {'time': warmupTime ?? 0, 'bpm': warmupBpm ?? 0};

    return json;
  }

  /// Returns a session with all zero durations and no content.
  static Session getDefault({String instrument = 'guitar'}) {
    return Session(
      duration: 0,
      ended: 0,
      instrument: instrument,
      warmupTime: 0,
      warmupBpm: 0,
      categories: {
        for (var cat in PracticeCategory.values) cat: SessionCategory(time: 0),
      },
    );
  }
}
