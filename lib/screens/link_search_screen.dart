import 'package:flutter/material.dart';
import '../models/link.dart';

class LinkSearchScreen extends StatefulWidget {
  final LinkCategory category;
  final void Function(String link, LinkKind kind, LinkCategory category)
  onLinkSelected;

  const LinkSearchScreen({
    super.key,
    required this.category,
    required this.onLinkSelected,
  });

  @override
  State<LinkSearchScreen> createState() => _LinkSearchScreenState();
}

class _LinkSearchScreenState extends State<LinkSearchScreen> {
  String _searchQuery = '';
  List<String> _results = [];

  LinkKind _inferKind(String link) {
    if (link.contains('youtube.com') || link.contains('youtu.be'))
      return LinkKind.youtube;
    if (link.contains('spotify.com')) return LinkKind.spotify;
    if (link.startsWith('file://')) return LinkKind.media;
    if (link.contains('ireal')) return LinkKind.iReal;
    return LinkKind.media;
  }

  void _performSearch(String query) {
    setState(() {
      _searchQuery = query;
      _results = [
        'https://example.com/result1?q=$query',
        'https://example.com/result2?q=$query',
      ]; // TODO: Replace with real API later
    });
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: Text('Search ${widget.category.name}')),
      body: Column(
        children: [
          Padding(
            padding: const EdgeInsets.all(12),
            child: TextField(
              decoration: const InputDecoration(
                labelText: 'Search...',
                border: OutlineInputBorder(),
              ),
              onSubmitted: _performSearch,
            ),
          ),
          Expanded(
            child: ListView.builder(
              itemCount: _results.length,
              itemBuilder: (_, i) {
                final link = _results[i];
                final kind = _inferKind(link);

                return ListTile(
                  title: Text(link),
                  trailing: const Icon(Icons.check_circle_outline),
                  onTap: () {
                    widget.onLinkSelected(link, kind, widget.category);
                  },
                );
              },
            ),
          ),
        ],
      ),
    );
  }
}
