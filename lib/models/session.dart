import 'practice_category.dart';

class SessionCategory {
  final int time;
  final String? note;
  final int? bpm;
  final Map<String, int>? songs;

  SessionCategory({required this.time, this.note, this.bpm, this.songs});

  factory SessionCategory.fromJson(Map<String, dynamic> json) => SessionCategory(
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
    for (var key in json.keys) {
      if (['duration', 'ended', 'instrument', 'warmup'].contains(key)) continue;
      final cat = PracticeCategoryExtension.fromString(key);
      if (cat != null) {
        categories[cat] = SessionCategory.fromJson(json[key]);
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