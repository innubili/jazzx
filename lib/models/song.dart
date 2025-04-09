class SongLink {
  final String key;
  final String kind;
  final String link;
  final bool isDefault;

  SongLink({required this.key, required this.kind, required this.link, required this.isDefault});

  factory SongLink.fromJson(Map<String, dynamic> json) => SongLink(
        key: json['key'] ?? '',
        kind: json['kind'] ?? '',
        link: json['link'] ?? '',
        isDefault: json['default'] ?? false,
      );
}

class Song {
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
  });

  factory Song.fromJson(String title, Map<String, dynamic> json) =>
      Song(
        title: title,
        key: json['key'] ?? '',
        type: json['type'] ?? '',
        form: json['form'] ?? '',
        bpm: json['bpm'] ?? 100,
        notes: json['notes'] ?? '',
        recommendedVersions: json['recommendedversions'] ?? '',
        songwriters: json['songwriters'] ?? '',
        year: json['year'] ?? '',
        links: (json['links'] as List?)
            ?.map((l) => SongLink.fromJson(l))
            .toList() ?? [],
      );
}