enum LinkKind { iReal, youtube, spotify, apple, media, skool, soundslice }

enum LinkCategory { backingTrack, playlist, lesson, scores, other }

class Link {
  final String key;
  final LinkKind kind;
  final String name;
  final LinkCategory category;
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

  factory Link.fromJson(Map<String, dynamic> json) {
    return Link(
      key: json['key'] ?? '',
      name: json['name'] ?? '',
      link: json['link'] ?? '',
      kind: LinkKind.values.firstWhere(
        (e) => e.name == json['kind'],
        orElse: () => LinkKind.media,
      ),
      category: LinkCategory.values.firstWhere(
        (e) => e.name == json['category'],
        orElse: () => LinkCategory.other,
      ),
      isDefault: json['default'] ?? false,
    );
  }

  Map<String, dynamic> toJson() => {
    'key': key,
    'name': name,
    'link': link,
    'kind': kind.name,
    'category': category.name,
    'default': isDefault,
  };

  bool get isLocal => link.startsWith('file://');

  bool get isBlank => link.isEmpty && name.isEmpty;

  factory Link.defaultLink(String songTitle) {
    return Link(
      key: 'C',
      kind: LinkKind.iReal,
      link: '',
      name: '$songTitle backing track',
      category: LinkCategory.backingTrack,
      isDefault: false,
    );
  }

  Link copyWith({
    String? key,
    LinkKind? kind,
    String? link,
    String? name,
    LinkCategory? category,
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
