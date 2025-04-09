enum LinkType {
  youtube,
  irealPro,
  spotify,
  localFile,
}

extension LinkTypeExtension on LinkType {
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
      default:
        return 'Unknown';
    }
  }

  String get icon {
    switch (this) {
      case LinkType.youtube:
        return 'assets/icons/youtube.png'; // Update with your actual icon
      case LinkType.irealPro:
        return 'assets/icons/irealpro.png'; // Update with your actual icon
      case LinkType.spotify:
        return 'assets/icons/spotify.png'; // Update with your actual icon
      case LinkType.localFile:
        return 'assets/icons/file.png'; // Update with your actual icon
      default:
        return 'assets/icons/default.png'; // Default icon
    }
  }
}
