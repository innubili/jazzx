import 'package:flutter/material.dart';
import 'package:file_picker/file_picker.dart';
import '../models/link.dart';
import '../services/youtube_service.dart';
import '../widgets/search_bar_widget.dart';
import '../widgets/search_results_list.dart';
import '../widgets/result_preview_panel.dart';

class LinkSearchScreen extends StatefulWidget {
  final String songTitle;
  final LinkCategory category;
  final void Function(String url, LinkKind kind) onSelected;

  const LinkSearchScreen({
    super.key,
    required this.songTitle,
    required this.category,
    required this.onSelected,
  });

  @override
  State<LinkSearchScreen> createState() => _LinkSearchScreenState();
}

class _LinkSearchScreenState extends State<LinkSearchScreen> {
  late TextEditingController _controller;
  SearchMode _mode = SearchMode.web;
  List<SearchResult> _results = [];
  SearchResult? _selectedResult;

  @override
  void initState() {
    super.initState();
    final categorySuffix = _friendlyCategoryLabel(widget.category).trim();
    final initialText =
        categorySuffix.isNotEmpty
            ? '${widget.songTitle} $categorySuffix'
            : widget.songTitle;

    _controller = TextEditingController(text: initialText);
    _onSearch(initialText);
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  String _friendlyCategoryLabel(LinkCategory category) {
    switch (category) {
      case LinkCategory.backingTrack:
        return 'backing track';
      case LinkCategory.playlist:
        return 'playlist';
      case LinkCategory.lesson:
        return 'lesson';
      case LinkCategory.scores:
        return 'sheet music';
      case LinkCategory.other:
        return '';
    }
  }

  void _onSearch(String query) async {
    setState(() {
      _selectedResult = null;
      _results = [];
    });

    if (_mode == SearchMode.local) {
      final result = await FilePicker.platform.pickFiles();
      if (result != null) {
        final file = result.files.first;
        final fileResult = SearchResult(
          url: file.path ?? '',
          title: file.name,
          kind: LinkKind.media,
        );
        setState(() {
          _results = [fileResult];
          _selectedResult = fileResult;
        });
      }
    } else if (_mode == SearchMode.web) {
      final ytService = YouTubeSearchService();
      final results = await ytService.search(query);
      setState(() {
        _results = results;
      });
    } else if (_mode == SearchMode.irealpro) {
      // TODO: Handle iRealPro logic
    }
  }

  void _onSelect(SearchResult result) {
    setState(() => _selectedResult = result);
  }

  void _onConfirmSelection() {
    if (_selectedResult != null) {
      widget.onSelected(_selectedResult!.url, _selectedResult!.kind);
      Navigator.pop(context);
    }
  }

  void _onToggleMode(SearchMode mode) {
    setState(() => _mode = mode);
  }

  void _onPrevResult() {
    if (_selectedResult == null || _results.isEmpty) return;
    final i = _results.indexOf(_selectedResult!);
    if (i > 0) setState(() => _selectedResult = _results[i - 1]);
  }

  void _onNextResult() {
    if (_selectedResult == null || _results.isEmpty) return;
    final i = _results.indexOf(_selectedResult!);
    if (i < _results.length - 1)
      setState(() => _selectedResult = _results[i + 1]);
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: Text('Find link for "${widget.songTitle}"')),
      body: Column(
        children: [
          SearchBarWidget(
            controller: _controller,
            onQueryChanged: _onSearch,
            onClear: () {
              _controller.clear();
              _onSearch('');
            },
            searchLocal: _mode == SearchMode.local,
            searchIRealPro: _mode == SearchMode.irealpro,
            onToggleLocal:
                (val) => _onToggleMode(val ? SearchMode.local : SearchMode.web),
            onToggleIRealPro:
                (val) =>
                    _onToggleMode(val ? SearchMode.irealpro : SearchMode.web),
          ),
          if (_selectedResult != null)
            ResultPreviewPanel(
              result: _selectedResult!,
              onAddLink: _onConfirmSelection,
              onPrev: _onPrevResult,
              onNext: _onNextResult,
            ),
          Expanded(
            child: SearchResultsList(
              results: _results,
              onSelected: _onSelect,
              selected: _selectedResult,
            ),
          ),
        ],
      ),
    );
  }
}

// ─────────── Enums + Result Struct ───────────

enum SearchMode { web, local, irealpro }

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
