import '../utils/utils.dart';
import 'practice_category.dart';

class SessionCategory {
  final int time;
  final String? note;
  final int? bpm;
  final Map<String, int>? songs;

  SessionCategory({required this.time, this.note, this.bpm, this.songs});

  factory SessionCategory.fromJson(Map<String, dynamic> json) {
    final safeJson = asStringKeyedMap(json);
    return SessionCategory(
      time: safeJson['time'] ?? 0,
      note: safeJson['note'],
      bpm: safeJson['bpm'],
      songs:
          safeJson['songs'] is Map
              ? Map<String, int>.from(safeJson['songs'])
              : null,
    );
  }

  Map<String, dynamic> toJson() => {
    'time': time,
    if (note != null) 'note': note,
    if (bpm != null) 'bpm': bpm,
    if (songs != null) 'songs': songs,
  };

  @override
  String toString() =>
      'SessionCategory(time: $time, note: $note, bpm: $bpm, songs: ${songs?.keys.toList()})';
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
    final safeJson = asStringKeyedMap(json);
    final warmup = asStringKeyedMap(safeJson['warmup']);
    final catRaw = asStringKeyedMap(safeJson['categories']);

    final catMap = <PracticeCategory, SessionCategory>{};
    for (final entry in catRaw.entries) {
      final cat = entry.key.tryToPracticeCategory();
      if (cat != null && entry.value is Map) {
        catMap[cat] = SessionCategory.fromJson(
          Map<String, dynamic>.from(entry.value),
        );
      }
    }

    return Session(
      duration: safeJson['duration'] ?? 0,
      ended: safeJson['ended'] ?? 0,
      instrument: safeJson['instrument'] ?? '',
      categories: catMap,
      warmupTime: warmup['time'],
      warmupBpm: warmup['bpm'],
    );
  }

  Map<String, dynamic> toJson() {
    final Map<String, dynamic> json = {
      'duration': duration,
      'ended': ended,
      'instrument': instrument,
      'categories': {
        for (final entry in categories.entries)
          entry.key.name: entry.value.toJson(),
      },
      'warmup': {'time': warmupTime ?? 0, 'bpm': warmupBpm ?? 0},
    };
    return json;
  }

  static Session getDefault({String instrument = 'guitar'}) => Session(
    duration: 0,
    ended: 0,
    instrument: instrument,
    warmupTime: 0,
    warmupBpm: 0,
    categories: {
      for (final cat in PracticeCategory.values) cat: SessionCategory(time: 0),
    },
  );

  @override
  String toString() =>
      'Session(instrument: $instrument, categories: ${categories.map((k, v) => MapEntry(k.name, v))})';
}
