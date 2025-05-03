import '../utils/utils.dart';
import 'practice_category.dart';
import '../utils/session_utils.dart';

class SessionCategory {
  final int time; // in seconds
  final String? note; // text
  final int? bpm; // beats per minute
  final Map<String, int>? songs;
  final List<String>? links;

  SessionCategory({
    required this.time,
    this.note,
    this.bpm,
    this.songs,
    this.links,
  });

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
      links:
          safeJson['links'] is List
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

class Warmup {
  final int time;
  final int bpm;

  Warmup({required this.time, required this.bpm});

  factory Warmup.fromJson(Map<String, dynamic> json) =>
      Warmup(time: json['time'] ?? 0, bpm: json['bpm'] ?? 0);

  Map<String, dynamic> toJson() => {'time': time, 'bpm': bpm};

  Warmup copyWith({int? time, int? bpm}) {
    return Warmup(time: time ?? this.time, bpm: bpm ?? this.bpm);
  }
}

class Session {
  final int duration; // in seconds
  final int ended; // timestamp
  final String instrument;
  final Map<PracticeCategory, SessionCategory> categories;
  final Warmup? warmup;

  Session({
    required this.duration,
    required this.ended,
    required this.instrument,
    required this.categories,
    this.warmup,
  });

  factory Session.fromJson(Map<String, dynamic> json) {
    final safeJson = asStringKeyedMap(json);
    final warmupJson = asStringKeyedMap(safeJson['warmup']);
    final catRaw = asStringKeyedMap(safeJson['categories']);
    final catMap = <PracticeCategory, SessionCategory>{};
    if (catRaw.isNotEmpty) {
      for (final entry in catRaw.entries) {
        final cat = PracticeCategoryExtension.fromName(entry.key);
        if (cat != null) {
          // Defensive: always convert to Map<String, dynamic>
          final valueMap = asStringKeyedMap(entry.value);
          catMap[cat] = SessionCategory.fromJson(valueMap);
        }
      }
    }
    // Ensure all categories are present, missing ones get time=0
    for (final cat in PracticeCategory.values) {
      catMap.putIfAbsent(cat, () => SessionCategory(time: 0));
    }
    return Session(
      duration: safeJson['duration'] ?? 0,
      ended: safeJson['ended'] ?? 0,
      instrument: safeJson['instrument'] ?? '',
      categories: catMap,
      warmup: warmupJson.isNotEmpty ? Warmup.fromJson(warmupJson) : null,
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'duration': duration,
      'ended': ended,
      'instrument': instrument,
      'categories': {
        for (final entry in categories.entries)
          if (entry.value.time > 0)
            entry.key.name: entry.value.toJson(),
      },
      'warmup': warmup?.toJson() ?? {'time': 0, 'bpm': 0},
    };
  }

  Session copyWith({
    int? duration,
    int? ended,
    String? instrument,
    Map<PracticeCategory, SessionCategory>? categories,
    Warmup? warmup,
  }) {
    return Session(
      duration: duration ?? this.duration,
      ended: ended ?? this.ended,
      instrument: instrument ?? this.instrument,
      categories: categories ?? this.categories,
      warmup: warmup ?? this.warmup,
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
      warmup: warmup,
    );
  }

  static Session getDefault({String instrument = 'guitar'}) => Session(
    duration: 0,
    ended: 0,
    instrument: instrument,
    warmup: null,
    categories: {
      for (final cat in PracticeCategory.values) cat: SessionCategory(time: 0),
    },
  );

  @override
  String toString() =>
      'Session\n\t$instrument\n\twup:(${intSecondsToHHmm(warmup?.time ?? 0)})\n\tcategories:\n\t${categories.map((k, v) => MapEntry(k.name, v))})';
}
