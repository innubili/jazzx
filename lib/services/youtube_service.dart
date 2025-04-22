import 'dart:convert';
import 'package:http/http.dart' as http;

import '../models/link.dart';
import '../secrets.dart'; // contains APP_GOOGLE_API_KEY
import '../screens/link_search_screen.dart'; // for SearchResult

class YouTubeSearchService {
  String? _nextPageToken;

  /// Resets pagination when a new search query is started.
  void resetPagination() {
    _nextPageToken = null;
  }

  /// Whether there is another page to load.
  bool get hasMore => _nextPageToken != null;

  /// Performs a YouTube video search using the given query.
  /// If [loadMore] is true, it uses [_nextPageToken] to fetch the next page.
  Future<List<SearchResult>> search(
    String query, {
    bool loadMore = false,
  }) async {
    final baseParams = {
      'part': 'snippet',
      'type': 'video',
      'maxResults': '20',
      'q': query,
      'key': APP_GOOGLE_API_KEY,
    };

    if (loadMore && _nextPageToken != null) {
      baseParams['pageToken'] = _nextPageToken!;
    }

    final uri = Uri.https(
      'www.googleapis.com',
      '/youtube/v3/search',
      baseParams,
    );
    final response = await http.get(uri);

    if (response.statusCode != 200) {
      throw Exception('YouTube API error: ${response.body}');
    }

    final data = json.decode(response.body);
    _nextPageToken = data['nextPageToken'];

    return (data['items'] as List)
        .map((item) {
          final videoId = item['id']?['videoId'];
          final snippet = item['snippet'];

          if (videoId == null || snippet == null) return null;

          final title = snippet['title'] ?? 'Untitled';
          final thumbnail = snippet['thumbnails']?['default']?['url'];
          final url = 'https://www.youtube.com/watch?v=$videoId';

          return SearchResult(
            url: url,
            title: title,
            kind: LinkKind.youtube,
            thumbnailUrl: thumbnail,
          );
        })
        .whereType<SearchResult>()
        .toList();
  }
}
