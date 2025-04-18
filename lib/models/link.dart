enum LinkKind {
  iReal,
  youtube,
  spotify,
  apple,
  media, // for local audio/video
  skool,
  soundslice,
}

enum LinkCategory { backingTrack, playlist, lesson, scores, other }

class Link {
  final String key;
  final String kind;
  final String name;
  final String category;
  final String link;
  final bool isDefault;

  Link({
    required this.key,
    required this.name,
    required this.kind,
    required this.link,
    required this.category,
    required this.isDefault,
  });

  factory Link.fromJson(Map<String, dynamic> json) => Link(
    key: json['key'] ?? '',
    kind: json['kind'] ?? '',
    link: json['link'] ?? '',
    name: json['name'] ?? '',
    category: json['category'] ?? '',
    isDefault: json['default'] ?? false,
  );

  bool get isLocal => link.startsWith('file://');

  bool get isBlank => link.isEmpty && name.isEmpty;

  Map<String, dynamic> toJson() => {
    'key': key,
    'kind': kind,
    'link': link,
    'name': name,
    'category': category,
    'default': isDefault,
  };

  factory Link.defaultLink(String songTitle) {
    return Link(
      key: 'C',
      kind: '',
      link: '',
      name: '$songTitle backing track',
      category: LinkCategory.backingTrack.name,
      isDefault: false,
    );
  }

  Link copyWith({
    String? key,
    String? kind,
    String? link,
    String? name,
    String? category,
    bool? isDefault,
  }) {
    return Link(
      key: key ?? this.key,
      kind: kind ?? this.kind,
      link: link ?? this.link,
      name: name ?? this.name,
      category: category ?? this.category,
      isDefault: isDefault ?? this.isDefault,
    );
  }
}
