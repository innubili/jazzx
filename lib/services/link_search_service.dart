import '../models/link.dart';
import '../models/search_result.dart';
import 'youtube_service.dart';
import 'spotify_service.dart';
import 'link_query_schema.dart';
import 'google_search_service.dart';
import '../secrets.dart';
import '../utils/utils.dart';

/// Unified service for searching links by kind and category.
class LinkSearchService {
  final YouTubeSearchService _youtubeService;
  final SpotifySearchService _spotifyService;
  final GoogleSearchService _googleService = GoogleSearchService(
    apiKey: APP_GOOGLE_API_KEY,
    cx: GOOGLE_CUSTOM_SEARCH_CX,
  );

  LinkSearchService({
    YouTubeSearchService? youtubeService,
    SpotifySearchService? spotifyService,
  }) : _youtubeService = youtubeService ?? YouTubeSearchService(),
       _spotifyService = spotifyService ?? SpotifySearchService();

  /// Unified search method
  Future<List<SearchResult>> search({
    required String query,
    required LinkCategory category,
    required LinkKind kind,
    bool loadMore = false,
  }) async {
    // Use the schema to build the effective query
    final effectiveQuery = buildLinkQuery(kind, category, query);
    log.info(
      'SEARCH | kind: $kind | category: $category | query: "$effectiveQuery" | service: google',
    );
    // Always use GoogleSearchService for all searches
    final results = await _googleService.search(effectiveQuery, kind: kind);
    return results;
  }

  /// Optionally, expose pagination helpers
  bool hasMore(LinkKind kind) {
    switch (kind) {
      case LinkKind.youtube:
        return _youtubeService.hasMore;
      case LinkKind.spotify:
        return _spotifyService.hasMore;
      // Add other LinkKinds as needed
      default:
        // Optionally, fallback to Google search here in the future
        return false;
    }
  }

  void resetPagination(LinkKind kind) {
    switch (kind) {
      case LinkKind.youtube:
        _youtubeService.resetPagination();
        break;
      case LinkKind.spotify:
        _spotifyService.resetPagination();
        break;
      default:
        break;
    }
  }
}
