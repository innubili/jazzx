import '../models/link.dart';
import '../screens/link_search_screen.dart';

Future<List<SearchResult>> searchLinks({
  required String query,
  required SearchMode mode,
  required LinkCategory category,
}) async {
  switch (mode) {
    case SearchMode.web:
      return await _searchWeb(query, category);
    case SearchMode.local:
      return await _searchLocal(query, category);
    case SearchMode.irealpro:
      return await _searchIRealPro(query, category);
  }
}

Future<List<SearchResult>> _searchWeb(
  String query,
  LinkCategory category,
) async {
  // TODO: Replace with real APIs
  return [
    SearchResult(
      url: 'https://www.youtube.com/watch?v=abc123',
      title: '$query - Backing Track',
      kind: LinkKind.youtube,
    ),
    SearchResult(
      url: 'https://open.spotify.com/track/xyz456',
      title: '$query - Spotify Backing Track',
      kind: LinkKind.spotify,
    ),
  ];
}

Future<List<SearchResult>> _searchLocal(
  String query,
  LinkCategory category,
) async {
  // Local file search is triggered manually via FilePicker
  return [];
}

Future<List<SearchResult>> _searchIRealPro(
  String query,
  LinkCategory category,
) async {
  // No real search available — just simulate a result
  return [
    SearchResult(
      url: 'irealpro://open?song=$query',
      title: 'Open $query in iRealPro',
      kind: LinkKind.iReal,
    ),
  ];
}
