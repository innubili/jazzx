enum SongLinkType {
  iRealBackingTrack,
  youtubeBackingTrack,
  spotifyBackingTrack,
  appleMusicBackingTrack,
  spotifyPlaylist,
  appleMusicPlaylist,
  youtubePlaylist,
  youtubeVideo,
  appleMusicVideo,
  localVideo,
  localAudio,
  pdf,
  skool,
}

class SongLink {
  final String key;
  final String kind;
  final String link;
  final bool isDefault;

  SongLink({
    required this.key,
    required this.kind,
    required this.link,
    required this.isDefault,
  });

  factory SongLink.fromJson(Map<String, dynamic> json) => SongLink(
    key: json['key'] ?? '',
    kind: json['kind'] ?? '',
    link: json['link'] ?? '',
    isDefault: json['default'] ?? false,
  );

  Map<String, dynamic> toJson() => {
    'key': key,
    'kind': kind,
    'link': link,
    'default': isDefault,
  };
}

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
  final List<SongLink> links;
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
    List<SongLink>? links,
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
        (json['links'] as Map?)?.entries
            .where((e) => e.key != 'NA')
            .map(
              (e) => SongLink.fromJson({
                'key': e.value['key'],
                'kind': e.value['kind'],
                'link': e.key,
                'default': e.value['default'] ?? false,
              }),
            )
            .toList() ??
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
}
