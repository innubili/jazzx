import 'dart:convert';
import 'package:http/http.dart' as http;

import '../models/link.dart';
import '../secrets.dart'; // contains APP_GOOGLE_API_KEY
import '../screens/link_search_screen.dart'; // for SearchResult

class YouTubeSearchService {
  const YouTubeSearchService();

  Future<List<SearchResult>> search(String query) async {
    final url = Uri.parse(
      'https://www.googleapis.com/youtube/v3/search'
      '?part=snippet&type=video&maxResults=10'
      '&q=${Uri.encodeComponent(query)}&key=$APP_GOOGLE_API_KEY',
    );

    final response = await http.get(url);
    if (response.statusCode == 200) {
      final data = json.decode(response.body);
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
}
