import 'link.dart';

class SearchResult {
  final String url;
  final String title;
  final LinkKind kind;
  final String? thumbnailUrl;

  SearchResult({
    required this.url,
    required this.title,
    required this.kind,
    this.thumbnailUrl,
  });
}
