import 'link.dart';

class Song {
  static const List<String> musicalKeys = [
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
    this.deleted = false, // ← Add this line
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
    bool? deleted, // ← Add this line
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
    );
  }

  String get summary =>
      '$songwriters ($year) • $key • $type • $form • $bpm BPM';

  bool hasLink(LinkKind type) {
    return links.any((link) => link.kind == type.name);
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
      'links': {
        for (var link in links)
          link.link: {
            'key': link.key,
            'kind': link.kind,
            'default': link.isDefault,
          },
      },
    };
  }

  factory Song.fromJson(String title, Map<String, dynamic> json) => Song(
    title: title,
    key: json['key'] ?? '',
    type: json['type'] ?? '',
    form: json['form'] ?? '',
    bpm: json['bpm'] ?? 100,
    notes: json['notes'] ?? '',
    recommendedVersions: json['recommendedversions'] ?? '',
    songwriters: json['songwriters'] ?? '',
    year: json['year'] ?? '',
    deleted: json['deleted'] ?? false,
    links:
        (json['links'] as Map?)?.entries.where((e) => e.key != 'NA').map((e) {
          final data = e.value as Map<String, dynamic>;
          return Link.fromJson({
            'link': e.key,
            'key': data['key'] ?? '',
            'kind': data['kind'] ?? '',
            'name': data['name'] ?? '',
            'category': data['category'] ?? 'other',
            'default': data['default'] ?? false,
          });
        }).toList() ??
        [],
  );

  static void removeSong(List<Song> list, Song song) {
    list.removeWhere((s) => s.title == song.title);
  }

  static void updateSong(List<Song> list, Song song) {
    final index = list.indexWhere((s) => s.title == song.title);
    if (index != -1) {
      list[index] = song;
    }
  }

  hasLinkCategory(LinkCategory scores) {
    return links.any((link) => link.category == scores.name);
  }
}
