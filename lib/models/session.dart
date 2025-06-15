import '../utils/utils.dart';
import 'practice_category.dart';
import '../utils/session_utils.dart';
import 'link.dart';

class SessionCategory {
  final int time; // in seconds
  final String? note; // text
  final int? bpm; // beats per minute
  final Map<String, int>? songs;
  final List<Link>? links;

  SessionCategory({
    required this.time,
    this.note,
    this.bpm,
    this.songs,
    this.links,
  });

  factory SessionCategory.fromJson(Map<String, dynamic> json) {
    final safeJson = asStringKeyedMap(json);
    List<Link>? parsedLinks;
    if (safeJson['links'] is Map) {
      parsedLinks = [];
      final linksMap = asStringKeyedMap(safeJson['links']);
      for (final entry in linksMap.entries) {
        final desanitizedKey = desanitizeLinkKey(entry.key);
        if (entry.value is Map) {
          parsedLinks.add(
            Link.fromJson({
              ...asStringKeyedMap(entry.value),
              'key': desanitizedKey,
            }),
          );
        }
      }
    } else if (safeJson['links'] is List) {
      // For backward compatibility: treat as list of URLs (strings)
      parsedLinks =
          List<String>.from(safeJson['links'])
              .map(
                (url) => Link(
                  key: sanitizeLinkKey(url),
                  name: url,
                  kind: LinkKind.youtube, // fallback
                  link: url,
                  category: LinkCategory.other,
                  isDefault: false,
                ),
              )
              .toList();
    }
    return SessionCategory(
      time: safeJson['time'] ?? 0,
      note: safeJson['note'],
      bpm: safeJson['bpm'],
      songs:
          safeJson['songs'] is Map
              ? Map<String, int>.from(safeJson['songs'])
              : null,
      links: parsedLinks,
    );
  }

  Map<String, dynamic> toJson() => {
    'time': time,
    if (note != null) 'note': note,
    if (bpm != null) 'bpm': bpm,
    if (songs != null) 'songs': songs,
    if (links != null)
      'links': {for (final link in links!) link.key: link.toJson()},
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
    List<Link>? links,
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
  /// .started: Timestamp of session start (UNIX seconds), used as sessionID as string in Firebase
  final int started; // timestamp
  final int duration; // in seconds
  final int ended; // timestamp
  final String instrument;
  final Map<PracticeCategory, SessionCategory> categories;
  final Warmup? warmup;

  Session({
    required this.started,
    required this.duration,
    required this.ended,
    required this.instrument,
    required this.categories,
    this.warmup,
  });

  /// Returns the session's ID (the .started field as a string, for Firebase compatibility)
  String get id => started.toString();

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
      started:
          safeJson['started'] ??
          safeJson['strted'] ??
          0, // Try 'started' first, fallback to 'strted' for backward compatibility
      duration: safeJson['duration'] ?? 0,
      ended: safeJson['ended'] ?? 0,
      instrument: safeJson['instrument'] ?? '',
      categories: catMap,
      warmup: warmupJson.isNotEmpty ? Warmup.fromJson(warmupJson) : null,
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'started': started, // Use correct field name
      'duration': duration,
      'ended': ended,
      'instrument': instrument,
      'categories': {
        for (final entry in categories.entries)
          if (entry.value.time > 0) entry.key.name: entry.value.toJson(),
      },
      'warmup': warmup?.toJson() ?? {'time': 0, 'bpm': 0},
    };
  }

  Session copyWith({
    int? started,
    int? duration,
    int? ended,
    String? instrument,
    Map<PracticeCategory, SessionCategory>? categories,
    Warmup? warmup,
  }) {
    return Session(
      started: started ?? this.started,
      duration: duration ?? this.duration,
      ended: ended ?? this.ended,
      instrument: instrument ?? this.instrument,
      categories: categories ?? this.categories,
      warmup: warmup ?? this.warmup,
    );
  }

  Session copyWithCategory(PracticeCategory category, SessionCategory data) {
    // Optimize: Only create new map if the category data actually changed
    final existingData = categories[category];
    if (existingData == data) {
      return this; // Return same instance if no change
    }

    // Use more efficient map copying for large sessions
    final newCategories = <PracticeCategory, SessionCategory>{};
    for (final entry in categories.entries) {
      newCategories[entry.key] = entry.key == category ? data : entry.value;
    }

    return Session(
      started: started,
      duration: duration,
      ended: ended,
      instrument: instrument,
      categories: newCategories,
      warmup: warmup,
    );
  }

  static Session getDefault({
    required int sessionId,
    String instrument = 'guitar',
    Session? lastSession,
  }) => Session(
    started: sessionId,
    duration: 0,
    ended: 0,
    instrument: instrument,
    warmup: null,
    categories: {
      for (final cat in PracticeCategory.values)
        cat: _createCategoryWithInheritance(cat, lastSession),
    },
  );

  /// Creates a SessionCategory with inherited data from last session (but time = 0)
  static SessionCategory _createCategoryWithInheritance(
    PracticeCategory category,
    Session? lastSession,
  ) {
    if (lastSession?.categories[category] != null) {
      final lastCategory = lastSession!.categories[category]!;
      // Copy note, links, songs, bpm but reset time to 0
      return SessionCategory(
        time: 0, // Always reset time for new session
        note: lastCategory.note,
        bpm: lastCategory.bpm,
        songs:
            lastCategory.songs != null
                ? Map<String, int>.from(lastCategory.songs!)
                : null,
        links:
            lastCategory.links != null
                ? List<Link>.from(lastCategory.links!)
                : null,
      );
    }
    // No last session or category doesn't exist - create empty
    return SessionCategory(time: 0);
  }

  /// Returns a pretty-printed log string with detailed session information.
  String asLogString() {
    // Format sessionId (UNIX timestamp in seconds) to DD-MMM-YYYY HH:mm:ss
    final ts = int.tryParse(id);
    String humanReadable = '';
    if (ts != null) {
      final dt = DateTime.fromMillisecondsSinceEpoch(ts * 1000);
      const months = [
        'Jan',
        'Feb',
        'Mar',
        'Apr',
        'May',
        'Jun',
        'Jul',
        'Aug',
        'Sep',
        'Oct',
        'Nov',
        'Dec',
      ];
      humanReadable =
          '${dt.day.toString().padLeft(2, '0')}-${months[dt.month - 1]}-${dt.year} '
          '${dt.hour.toString().padLeft(2, '0')}:${dt.minute.toString().padLeft(2, '0')}:${dt.second.toString().padLeft(2, '0')}';
    }

    // Format category times
    final categoryTimes = categories.entries
        .map((e) => '${e.key.name}:${intSecondsToHHmmss(e.value.time)}')
        .join(', ');

    final warmupTime =
        warmup != null ? intSecondsToHHmmss(warmup!.time) : '00:00:00';
    final totalTime = intSecondsToHHmmss(duration);

    return 'Session[$id] ($humanReadable) | Warmup:$warmupTime | Categories:[$categoryTimes] | Total:$totalTime';
  }

  @override
  String toString() =>
      'Session\n\t$instrument\n\twup:(${intSecondsToHHmmss(warmup?.time ?? 0)})\n\tcategories:\n\t${categories.map((k, v) => MapEntry(k.name, v))})';
}
