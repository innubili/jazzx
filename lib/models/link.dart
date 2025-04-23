enum LinkKind { iReal, youtube, spotify, apple, media, skool, soundslice }

enum LinkCategory { backingTrack, playlist, lesson, scores, other }

extension LinkKindExtension on LinkKind {
  int get priority {
    switch (this) {
      case LinkKind.iReal:
      case LinkKind.youtube:
        return 1;
      case LinkKind.spotify:
      case LinkKind.apple:
        return 2;
      case LinkKind.media:
        return 3;
      case LinkKind.skool:
        return 4;
      case LinkKind.soundslice:
        return 5;
    }
  }
}

extension LinkCategoryExtension on LinkCategory {
  int get priority {
    switch (this) {
      case LinkCategory.backingTrack:
        return 1;
      case LinkCategory.playlist:
        return 2;
      case LinkCategory.lesson:
        return 3;
      case LinkCategory.scores:
        return 4;
      case LinkCategory.other:
        return 5;
    }
  }
}

LinkCategory suggestNextCategory(List<Link> existingLinks) {
  final existingPriorities =
      existingLinks.map((l) => l.category.priority).toSet();
  for (int i = 1; i <= 5; i++) {
    final candidate = LinkCategory.values.firstWhere(
      (cat) => cat.priority == i,
      orElse: () => LinkCategory.other,
    );
    if (!existingPriorities.contains(candidate.priority)) return candidate;
  }
  return LinkCategory.other;
}

LinkKind suggestNextKind(List<Link> existingLinks) {
  final existingPriorities = existingLinks.map((l) => l.kind.priority).toSet();
  for (int i = 1; i <= 5; i++) {
    final candidate = LinkKind.values.firstWhere(
      (kind) => kind.priority == i,
      orElse: () => LinkKind.youtube,
    );
    if (!existingPriorities.contains(candidate.priority)) return candidate;
  }
  return LinkKind.youtube;
}

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
      name: songTitle,
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
