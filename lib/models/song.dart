import '../utils/utils.dart';
import 'link.dart';

// ignore: constant_identifier_names
const List<String> MusicalKeys = [
  'C',
  'Cm',
  'Db',
  'Dbm',
  'D',
  'Dm',
  'Eb',
  'Ebm',
  'E',
  'Em',
  'F',
  'Fm',
  'Gb',
  'Gbm',
  'G',
  'Gm',
  'Ab',
  'Abm',
  'A',
  'Am',
  'Bb',
  'Bbm',
  'B',
  'Bm',
];

class Song {
  final String title;
  final String key;
  final String type;
  final String form;
  final int bpm;
  final List<Link> links;
  final String notes;
  final String recommendedVersions;
  final String songwriters;
  final String year;
  final bool deleted;
  final int? added; // Timestamp (UNIX seconds), optional for backward compatibility

  Song({
    required this.title,
    required this.key,
    required this.type,
    required this.form,
    required this.bpm,
    required this.links,
    required this.notes,
    required this.recommendedVersions,
    required this.songwriters,
    required this.year,
    this.deleted = false,
    this.added,
  });

  Song copyWith({
    String? title,
    String? key,
    String? type,
    String? form,
    int? bpm,
    List<Link>? links,
    String? notes,
    String? recommendedVersions,
    String? songwriters,
    String? year,
    bool? deleted,
    int? added,
  }) {
    return Song(
      title: title ?? this.title,
      key: key ?? this.key,
      type: type ?? this.type,
      form: form ?? this.form,
      bpm: bpm ?? this.bpm,
      links: links ?? this.links,
      notes: notes ?? this.notes,
      recommendedVersions: recommendedVersions ?? this.recommendedVersions,
      songwriters: songwriters ?? this.songwriters,
      year: year ?? this.year,
      deleted: deleted ?? this.deleted,
      added: added ?? this.added,
    );
  }

  String get summary =>
      '$songwriters ($year) • $key • $type • $form • $bpm BPM';

  bool hasLink(LinkKind type) =>
      links.any((link) => link.kind.name == type.name);

  bool hasLinkCategory(LinkCategory category) =>
      links.any((link) => link.category == category);

  factory Song.fromJson(String title, Map<String, dynamic> json) {
    final linksJson = asStringKeyedMap(json['links']);
    final parsedLinks = <Link>[];

    for (final entry in linksJson.entries) {
      if (entry.key == 'NA') continue;
      final linkMap = asStringKeyedMap(entry.value);
      parsedLinks.add(
        Link.fromJson({
          'link': desanitizeLinkKey(entry.key),
          'key': linkMap['key'] ?? '',
          'kind': linkMap['kind'] ?? '',
          'name': linkMap['name'] ?? '',
          'category': linkMap['category'] ?? 'other',
          'default': linkMap['default'] ?? false,
        }),
      );
    }

    return Song(
      title: title,
      key: json['key'] ?? '',
      type: json['type'] ?? '',
      form: json['form'] ?? '',
      bpm: json['bpm'] ?? 100,
      links: parsedLinks,
      notes: json['notes'] ?? '',
      recommendedVersions: json['recommendedversions'] ?? '',
      songwriters: json['songwriters'] ?? '',
      year: json['year'] ?? '',
      deleted: json['deleted'] ?? false,
      added: json['added'], // Will be null for jazz_standards
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'key': key,
      'type': type,
      'form': form,
      'bpm': bpm,
      'notes': notes,
      'recommendedversions': recommendedVersions,
      'songwriters': songwriters,
      'year': year,
      'deleted': deleted,
      'added': added,
      'links': {
        for (var link in links)
          sanitizeLinkKey(link.link): {
            'key': link.key,
            'kind': link.kind,
            'name': link.name,
            'category': link.category.name,
            'default': link.isDefault,
          },
      },
    };
  }

  static void removeSong(List<Song> list, Song song) {
    list.removeWhere((s) => s.title == song.title);
  }

  static void updateSong(List<Song> list, Song song) {
    final index = list.indexWhere((s) => s.title == song.title);
    if (index != -1) list[index] = song;
  }

  static Song getDefault(String title) => Song(
    title: title,
    key: '',
    type: '',
    form: '',
    bpm: 120,
    links: [],
    notes: '',
    recommendedVersions: '',
    songwriters: '',
    year: '',
    added: DateTime.now().toUtc().millisecondsSinceEpoch ~/ 1000,
  );
}
