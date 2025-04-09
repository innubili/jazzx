enum LinkType {
  youtube,
  irealPro,
  spotify,
  localFile,
}

extension LinkTypeExtension on LinkType {
  static LinkType fromString(String value) {
    switch (value.toLowerCase()) {
      case 'youtube':
        return LinkType.youtube;
      case 'irealpro':
        return LinkType.irealPro;
      case 'spotify':
        return LinkType.spotify;
      case 'localfile':
        return LinkType.localFile;
      default:
        return LinkType.youtube; // Fallback (or throw error if preferred)
    }
  }

  String get name {
    switch (this) {
      case LinkType.youtube:
        return 'YouTube';
      case LinkType.irealPro:
        return 'iRealPro';
      case LinkType.spotify:
        return 'Spotify';
      case LinkType.localFile:
        return 'Local File';
    }
  }

  String get icon {
    switch (this) {
      case LinkType.youtube:
        return 'assets/icons/youtube.png';
      case LinkType.irealPro:
        return 'assets/icons/irealpro.png';
      case LinkType.spotify:
        return 'assets/icons/spotify.png';
      case LinkType.localFile:
        return 'assets/icons/file.png';
    }
  }
}

