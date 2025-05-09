import 'dart:convert';
import 'package:http/http.dart' as http;
import '../models/search_result.dart';
import '../models/link.dart';

/// Service for querying Google Custom Search JSON API.
class GoogleSearchService {
  final String apiKey;
  final String cx;

  GoogleSearchService({required this.apiKey, required this.cx});

  Future<List<SearchResult>> search(
    String query, {
    int num = 6,
    LinkKind kind = LinkKind.youtube,
  }) async {
    final url = Uri.https('www.googleapis.com', '/customsearch/v1', {
      'key': apiKey,
      'cx': cx,
      'q': query,
      'num': num.toString(),
    });
    final response = await http.get(url);
    if (response.statusCode == 200) {
      final data = json.decode(response.body);
      final items = data['items'] as List<dynamic>?;
      if (items == null) return [];
      return items.map((item) {
        return SearchResult(
          url: item['link'] ?? '',
          title: item['title'] ?? '',
          kind: kind,
          thumbnailUrl: item['pagemap']?['cse_image']?[0]?['src'],
        );
      }).toList();
    } else {
      throw Exception(
        'Failed to fetch Google search results: ${response.body}',
      );
    }
  }
}
