import 'dart:convert';
import 'package:http/http.dart' as http;

import '../models/link.dart';
import '../secrets.dart'; // contains APP_GOOGLE_API_KEY
import '../screens/link_search_screen.dart'; // for SearchResult

class YouTubeSearchService {
  YouTubeSearchService();
  String? _nextPageToken;

  Future<List<SearchResult>> search(
    String query, {
    bool loadMore = false,
  }) async {
    final uri = Uri.parse(
      'https://www.googleapis.com/youtube/v3/search'
      '?part=snippet&type=video&maxResults=20'
      '&q=${Uri.encodeComponent(query)}'
      '&key=$APP_GOOGLE_API_KEY'
      '${loadMore && _nextPageToken != null ? '&pageToken=$_nextPageToken' : ''}',
    );

    final response = await http.get(uri);
    if (response.statusCode == 200) {
      final data = json.decode(response.body);

      // Save pagination token
      _nextPageToken = data['nextPageToken'];

      return (data['items'] as List).map((item) {
        final videoId = item['id']['videoId'];
        final title = item['snippet']['title'];
        final thumbnail = item['snippet']['thumbnails']['default']['url'];
        final url = 'https://www.youtube.com/watch?v=$videoId';

        return SearchResult(
          url: url,
          title: title,
          kind: LinkKind.youtube,
          thumbnailUrl: thumbnail,
        );
      }).toList();
    } else {
      throw Exception('YouTube API error: ${response.body}');
    }
  }

  bool get hasMore => _nextPageToken != null;

  void resetPagination() {
    _nextPageToken = null;
  }
}
