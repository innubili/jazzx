import 'dart:convert';
import 'package:http/http.dart' as http;

import '../models/link.dart';
import '../secrets.dart'; // contains APP_GOOGLE_API_KEY
import '../screens/link_search_screen.dart'; // for SearchResult

class YouTubeSearchService {
  String? _nextPageToken;
  final Map<String, List<SearchResult>> _cache = {};
  final Map<String, bool> _fullyFetched = {};

  void resetPagination() {
    _nextPageToken = null;
  }

  bool get hasMore => _nextPageToken != null;

  String _cacheKey(String query, LinkCategory category) =>
      '$query|${category.name}';

  Future<List<SearchResult>> search(
    String query, {
    required LinkCategory category,
    bool loadMore = false,
  }) async {
    final type = (category == LinkCategory.playlist) ? 'playlist' : 'video';
    final key = _cacheKey(query, category);

    if (!loadMore && _cache.containsKey(key)) {
      return _cache[key]!;
    }

    if (loadMore && (_fullyFetched[key] ?? false)) {
      return _cache[key] ?? [];
    }

    final baseParams = {
      'part': 'snippet',
      'type': type,
      'maxResults': '50',
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
    if (_nextPageToken == null) {
      _fullyFetched[key] = true;
    }

    final results =
        (data['items'] as List)
            .map((item) {
              final id = item['id'];
              final snippet = item['snippet'];

              String? videoId = id?['videoId'];
              String? playlistId = id?['playlistId'];
              final title = snippet?['title'] ?? 'Untitled';
              final thumbnail = snippet?['thumbnails']?['default']?['url'];

              String? url;
              if (type == 'playlist' && playlistId != null) {
                url = 'https://www.youtube.com/playlist?list=$playlistId';
              } else if (type == 'video' && videoId != null) {
                url = 'https://www.youtube.com/watch?v=$videoId';
              }

              if (url == null) return null;

              return SearchResult(
                url: url,
                title: title,
                kind: LinkKind.youtube,
                thumbnailUrl: thumbnail,
              );
            })
            .whereType<SearchResult>()
            .toList();

    final existing = _cache[key] ?? [];
    final combined = [...existing, ...results];
    if (combined.length >= 100 || _nextPageToken == null) {
      _fullyFetched[key] = true;
    }

    _cache[key] = combined;
    return combined;
  }

  /// Fetches all videos from a given playlist ID
  Future<List<SearchResult>> getPlaylistItems(String playlistId) async {
    final uri = Uri.https('www.googleapis.com', '/youtube/v3/playlistItems', {
      'part': 'snippet',
      'playlistId': playlistId,
      'maxResults': '50',
      'key': APP_GOOGLE_API_KEY,
    });

    final response = await http.get(uri);
    if (response.statusCode != 200) {
      throw Exception('Failed to load playlist items');
    }

    final data = json.decode(response.body);
    final items = data['items'] as List;

    return items
        .map((item) {
          final snippet = item['snippet'];
          final title = snippet['title'] ?? 'Untitled';
          final videoId = snippet['resourceId']?['videoId'];
          final thumbnail = snippet['thumbnails']?['default']?['url'];

          if (videoId == null) return null;

          return SearchResult(
            url: 'https://www.youtube.com/watch?v=$videoId',
            title: title,
            kind: LinkKind.youtube,
            thumbnailUrl: thumbnail,
          );
        })
        .whereType<SearchResult>()
        .toList();
  }
}
