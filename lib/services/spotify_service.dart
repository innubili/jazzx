import 'dart:convert';
import 'package:http/http.dart' as http;

import '../models/link.dart';
import '../screens/link_search_screen.dart'; // For SearchResult
import '../secrets.dart'; // For Spotify credentials

class SpotifySearchService {
  static const String _baseUrl = 'https://api.spotify.com/v1';
  static const String _authUrl = 'https://accounts.spotify.com/api/token';

  String? _nextPageUrl;
  String? _accessToken;

  /// Reset pagination for a new search
  void resetPagination() {
    _nextPageUrl = null;
  }

  /// Whether more results are available
  bool get hasMore => _nextPageUrl != null;

  /// Automatically fetch and set a valid OAuth access token
  Future<void> authenticate() async {
    final credentials = base64.encode(
      utf8.encode('$SPOTIFY_CLIENT_ID:$SPOTIFY_CLIENT_SECRET'),
    );
    final response = await http.post(
      Uri.parse(_authUrl),
      headers: {
        'Authorization': 'Basic $credentials',
        'Content-Type': 'application/x-www-form-urlencoded',
      },
      body: {'grant_type': 'client_credentials'},
    );

    if (response.statusCode != 200) {
      throw Exception('Spotify authentication failed: ${response.body}');
    }

    final data = json.decode(response.body);
    _accessToken = data['access_token'];
  }

  /// Search for Spotify tracks or playlists based on the category
  Future<List<SearchResult>> search(
    String query, {
    required LinkCategory category,
    bool loadMore = false,
  }) async {
    if (_accessToken == null) {
      await authenticate();
    }

    final type = (category == LinkCategory.playlist) ? 'playlist' : 'track';
    final uri =
        loadMore && _nextPageUrl != null
            ? Uri.parse(_nextPageUrl!)
            : Uri.parse('$_baseUrl/search?q=$query&type=$type&limit=20');

    final response = await http.get(
      uri,
      headers: {'Authorization': 'Bearer $_accessToken'},
    );

    if (response.statusCode != 200) {
      throw Exception('Spotify API error: ${response.body}');
    }

    final data = json.decode(response.body);
    final items =
        type == 'playlist'
            ? data['playlists']['items']
            : data['tracks']['items'];

    _nextPageUrl =
        type == 'playlist' ? data['playlists']['next'] : data['tracks']['next'];

    return (items as List?)
            ?.where((item) => item != null)
            .map((item) {
              final name = item['name'] ?? 'Untitled';
              final url = item['external_urls']['spotify'];
              final thumbnail =
                  item['images'] != null && item['images'].isNotEmpty
                      ? item['images'][0]['url']
                      : null;

              return SearchResult(
                url: url,
                title: name,
                kind: LinkKind.spotify,
                thumbnailUrl: thumbnail,
              );
            })
            .whereType<SearchResult>()
            .toList() ??
        [];
  }
}
