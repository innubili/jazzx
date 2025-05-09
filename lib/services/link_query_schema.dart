import '../models/link.dart';

typedef QueryBuilder = String Function(String baseQuery);

class LinkQuerySchemaEntry {
  final QueryBuilder queryBuilder;
  const LinkQuerySchemaEntry({required this.queryBuilder});
}

/// Schema for building search queries based on LinkKind and LinkCategory.
/// Update this map to customize queries for each combination.
final Map<LinkKind, Map<LinkCategory, LinkQuerySchemaEntry>> linkQuerySchema = {
  LinkKind.youtube: {
    LinkCategory.backingTrack: LinkQuerySchemaEntry(
      queryBuilder: (base) => '$base backing track site:youtube.com',
    ),
    LinkCategory.lesson: LinkQuerySchemaEntry(
      queryBuilder: (base) => '$base lesson site:youtube.com',
    ),
    // Add more categories as needed
  },
  LinkKind.spotify: {
    LinkCategory.playlist: LinkQuerySchemaEntry(
      queryBuilder: (base) => '$base playlist site:open.spotify.com',
    ),
  },
  LinkKind.skool: {
    LinkCategory.lesson: LinkQuerySchemaEntry(
      queryBuilder: (base) => '$base site:skool.com',
    ),
  },
  LinkKind.iReal: {
    LinkCategory.lesson: LinkQuerySchemaEntry(
      queryBuilder: (base) => '$base site:iRealPro.com OR site:irealb.com',
    ),
  },
};

/// Helper to build a query for a given LinkKind and LinkCategory.
String buildLinkQuery(LinkKind kind, LinkCategory category, String baseQuery) {
  // Remove trailing category suffix if already present
  String categorySuffix = '';
  switch (category) {
    case LinkCategory.backingTrack:
      categorySuffix = 'backing track';
      break;
    case LinkCategory.playlist:
      categorySuffix = 'playlist';
      break;
    case LinkCategory.lesson:
      categorySuffix = 'lesson';
      break;
    case LinkCategory.scores:
      categorySuffix = 'sheet music';
      break;
    default:
      break;
  }
  String cleanedBase = baseQuery.trim();
  if (categorySuffix.isNotEmpty &&
      cleanedBase.toLowerCase().endsWith(categorySuffix.toLowerCase())) {
    cleanedBase =
        cleanedBase
            .substring(0, cleanedBase.length - categorySuffix.length)
            .trim();
  }
  final entry = linkQuerySchema[kind]?[category];
  if (entry != null) {
    return entry.queryBuilder(cleanedBase);
  }
  return cleanedBase;
}
