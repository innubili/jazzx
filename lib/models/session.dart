import '../utils/utils.dart';
import 'practice_category.dart';
import '../utils/session_utils.dart';

class SessionCategory {
  final int time;
  final String? note;
  final int? bpm;
  final Map<String, int>? songs;
  final List<String>? links;

  SessionCategory({required this.time, this.note, this.bpm, this.songs, this.links});

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
      links: safeJson['links'] is List
          ? List<String>.from(safeJson['links'])
          : null,
    );
  }

  Map<String, dynamic> toJson() => {
    'time': time,
    if (note != null) 'note': note,
    if (bpm != null) 'bpm': bpm,
    if (songs != null) 'songs': songs,
    if (links != null) 'links': links,
  };

  @override
  String toString() =>
      'Cat.(time: $time, note: $note, bpm: $bpm, songs: ${songs?.keys.toList()}, links: $links)';
}

extension SessionCategoryCopyWith on SessionCategory {
  SessionCategory copyWith({
    int? time,
    String? note,
    int? bpm,
    Map<String, int>? songs,
    List<String>? links,
  }) {
    return SessionCategory(
      time: time ?? this.time,
      note: note ?? this.note,
      bpm: bpm ?? this.bpm,
      songs: songs ?? this.songs,
      links: links ?? this.links,
    );
  }
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

  Session copyWith({
    int? duration,
    int? ended,
    String? instrument,
    Map<PracticeCategory, SessionCategory>? categories,
    int? warmupTime,
    int? warmupBpm,
  }) {
    return Session(
      duration: duration ?? this.duration,
      ended: ended ?? this.ended,
      instrument: instrument ?? this.instrument,
      categories: categories ?? this.categories,
      warmupTime: warmupTime ?? this.warmupTime,
      warmupBpm: warmupBpm ?? this.warmupBpm,
    );
  }

  Session copyWithCategory(PracticeCategory category, SessionCategory data) {
    final newCategories = Map<PracticeCategory, SessionCategory>.from(
      categories,
    );
    newCategories[category] = data;
    return Session(
      duration: duration,
      ended: ended,
      instrument: instrument,
      categories: newCategories,
      warmupTime: warmupTime,
      warmupBpm: warmupBpm,
    );
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
      'Session\n\t$instrument\n\twup:(${intSecondsToHHmm(warmupTime ?? 0)})\n\tcategories:\n\t${categories.map((k, v) => MapEntry(k.name, v))})';
}
