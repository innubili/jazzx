import 'song.dart';

enum LinkType { youtube, irealPro, spotify, localFile, other }

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
      default:
        return 'Other';
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
      default:
        return 'assets/icons/other.png';
    }
  }
}

SongLinkCategory getCategoryForLinkType(LinkType type) {
  switch (type) {
    case LinkType.irealPro:
    case LinkType.localFile:
      return SongLinkCategory.backingTrack;
    case LinkType.spotify:
      return SongLinkCategory.playlist;
    case LinkType.youtube:
      return SongLinkCategory.lesson; // or adjust as needed
    case LinkType.other:
      return SongLinkCategory.other;
  }
}
