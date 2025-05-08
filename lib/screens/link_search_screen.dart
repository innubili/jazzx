import 'package:flutter/material.dart';
import 'package:flutter_svg/flutter_svg.dart';
import '../models/link.dart';

import '../services/youtube_service.dart';
import '../services/spotify_service.dart';
import '../widgets/search_bar_widget.dart';
import '../widgets/link_view_panel.dart';
import '../widgets/main_drawer.dart'; // Import the MainDrawer widget

class LinkSearchScreen extends StatefulWidget {
  final String query;
  final void Function(Link link) onSelected;
  final LinkKind? initialKind;
  final LinkCategory? initialCategory;

  const LinkSearchScreen({
    super.key,
    required this.query,
    required this.onSelected,
    this.initialKind,
    this.initialCategory,
  });

  @override
  State<LinkSearchScreen> createState() => _LinkSearchScreenState();
}

class _LinkSearchScreenState extends State<LinkSearchScreen> {
  late TextEditingController _controller;
  final List<SearchResult> _results = [];
  final ScrollController _scrollController = ScrollController();
  SearchResult? _selectedResult;
  final _ytService = YouTubeSearchService();
  final _spotifyService = SpotifySearchService();
  bool _isLoading = false;
  String _currentQuery = '';
  late LinkCategory _selectedCategory;
  late Set<LinkKind> _selectedKinds;
  final Map<ValueKey, GlobalKey> _itemKeys = {};

  // --- Utility: Detect if query is a URL or domain ---
  String? _normalizeUrl(String query) {
    final trimmed = query.trim();
    // Accept if it's a full URL
    final urlPattern = RegExp(r'^(https?://)');
    if (urlPattern.hasMatch(trimmed)) {
      try {
        final uri = Uri.parse(trimmed);
        if (uri.hasAbsolutePath || uri.host.isNotEmpty) return trimmed;
      } catch (_) {}
    }
    // Accept if it looks like a domain (e.g. www.youtube.com/...)
    final domainPattern = RegExp(r'^(www\.|[a-zA-Z0-9-]+\.[a-zA-Z]{2,})(/.*)?');
    if (domainPattern.hasMatch(trimmed)) {
      final candidate = 'https://$trimmed';
      try {
        final uri = Uri.parse(candidate);
        if (uri.hasAbsolutePath || uri.host.isNotEmpty) return candidate;
      } catch (_) {}
    }
    return null;
  }

  @override
  void initState() {
    super.initState();
    _controller = TextEditingController(text: widget.query);
    _selectedCategory = widget.initialCategory ?? LinkCategory.backingTrack;
    _selectedKinds =
        widget.initialKind != null ? {widget.initialKind!} : {LinkKind.youtube};
    final suffix = _categorySuffix(_selectedCategory);
    final initialQuery =
        '${widget.query} ${suffix.isNotEmpty ? suffix : ''}'.trim();
    _searchAllSources(initialQuery);
    _scrollController.addListener(_onScrollEndTrigger);
  }

  @override
  void dispose() {
    _controller.dispose();
    _scrollController.dispose();
    super.dispose();
  }

  void _searchAllSources(String query, {bool loadMore = false}) async {
    if (_isLoading) return;
    setState(() => _isLoading = true);

    try {
      if (!loadMore) {
        _ytService.resetPagination();
        _spotifyService.resetPagination();
        _results.clear();
        _selectedResult = null;
        _currentQuery = query;
      } else {
        _results.removeWhere((r) => !_selectedKinds.contains(r.kind));
      }

      final futures = <Future<List<SearchResult>>>[];

      if (_selectedKinds.contains(LinkKind.youtube)) {
        futures.add(
          _ytService.search(
            query,
            category: _selectedCategory,
            loadMore: loadMore,
          ),
        );
      }
      if (_selectedKinds.contains(LinkKind.spotify)) {
        futures.add(
          _spotifyService.search(
            query,
            category: _selectedCategory,
            loadMore: loadMore,
          ),
        );
      }

      final newResults = (await Future.wait(futures)).expand((r) => r).toList();
      setState(() => _results.addAll(newResults));
    } catch (e) {
      debugPrint('Search error: $e');
    }

    setState(() => _isLoading = false);
  }

  void _onSearch(String query) {
    _searchAllSources(query);
  }

  void _onSelect(SearchResult result) {
    final link = Link(
      key: '',
      name: result.title,
      link: result.url,
      kind: result.kind,
      category: _selectedCategory,
      isDefault: false,
    );
    Navigator.pop(context, link);
  }

  void _onConfirmSelection() {
    if (_selectedResult == null) return;

    final baseLink = Link(
      key: '',
      name: _selectedResult!.title,
      link: _selectedResult!.url,
      kind: _selectedResult!.kind,
      category: _selectedCategory,
      isDefault: false,
    );

    widget.onSelected(baseLink);
  }

  void _onScrollEndTrigger() {
    if (_scrollController.position.pixels >=
        _scrollController.position.maxScrollExtent - 100) {
      _onScrollEnd();
    }
  }

  void _onScrollEnd() {
    if (_selectedKinds.contains(LinkKind.youtube) && _ytService.hasMore) {
      _searchAllSources(_currentQuery, loadMore: true);
    } else if (_selectedKinds.contains(LinkKind.spotify) &&
        _spotifyService.hasMore) {
      _searchAllSources(_currentQuery, loadMore: true);
    }
  }

  void _scrollToSelected() {
    if (_selectedResult == null) return;
    final key = ValueKey(_selectedResult!.url);

    // Find the corresponding widget and ensure it's visible
    final context = _itemKeys[key]?.currentContext;
    if (context != null) {
      Scrollable.ensureVisible(
        context,
        duration: const Duration(milliseconds: 300),
        curve: Curves.easeInOut,
        alignment: 0.5, // Center the item if possible
      );
    }
  }

  void _handleCategoryChange(LinkCategory category) {
    setState(() => _selectedCategory = category);
    _updateSearchQuery();
  }

  void _handleKindChange(Set<LinkKind> kinds) {
    setState(() => _selectedKinds = kinds);
    _searchAllSources(_controller.text);
  }

  void _updateSearchQuery() {
    final suffix = _categorySuffix(_selectedCategory);
    final base = widget.query;
    final query = '$base ${suffix.isNotEmpty ? suffix : ''}'.trim();
    _controller.text = query;
    _onSearch(query);
  }

  String _categorySuffix(LinkCategory category) {
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

  void _onPrevResult() {
    if (_selectedResult == null || _results.isEmpty) return;
    final i = _results.indexOf(_selectedResult!);
    if (i > 0) {
      setState(() => _selectedResult = _results[i - 1]);
      _scrollToSelected();
    }
  }

  void _onNextResult() {
    if (_selectedResult == null || _results.isEmpty) return;
    final i = _results.indexOf(_selectedResult!);
    if (i < _results.length - 1) {
      setState(() => _selectedResult = _results[i + 1]);
      _scrollToSelected();
    } else {
      _onScrollEnd();
    }
  }

  Widget _kindBadge(LinkKind kind) {
    final asset =
        kind == LinkKind.spotify
            ? 'assets/icons/spotify_icon.svg'
            : kind == LinkKind.youtube
            ? 'assets/icons/youtube_icon.svg'
            : null;

    return asset == null
        ? const SizedBox.shrink()
        : Positioned(
          top: 2,
          right: 2,
          child: SvgPicture.asset(asset, width: 16, height: 16),
        );
  }

  @override
  Widget build(BuildContext context) {
    final normalizedUrl = _normalizeUrl(_controller.text);
    return Scaffold(
      appBar: AppBar(
        title: Text('Find link for "${widget.query}"'),
        leading: Builder(
          builder:
              (context) => IconButton(
                icon: const Icon(Icons.menu),
                tooltip: 'Open navigation menu',
                onPressed: () => Scaffold.of(context).openDrawer(),
              ),
        ),
      ),
      drawer: const MainDrawer(),
      body: Column(
        children: [
          SearchBarWidget(
            controller: _controller,
            onQueryChanged: _onSearch,
            onClear: () {
              _controller.clear();
              _onSearch('');
            },
            selectedCategory: _selectedCategory,
            onCategoryChanged: _handleCategoryChange,
            selectedKinds: _selectedKinds,
            onKindsChanged: _handleKindChange,
          ),
          if (normalizedUrl != null)
            ListTile(
              leading: const Icon(Icons.link),
              title: const Text('Use this link'),
              subtitle: Text(normalizedUrl),
              tileColor: Colors.green.shade50,
              onTap: () {
                final link = Link(
                  key: '',
                  name: normalizedUrl,
                  kind: LinkKind.youtube, // Or infer from context
                  link: normalizedUrl,
                  category: _selectedCategory,
                  isDefault: false,
                );
                Navigator.pop(context, link);
              },
            ),
          if (_selectedResult != null)
            LinkViewPanel(
              link: Link(
                key: '',
                name: _selectedResult!.title,
                link: _selectedResult!.url,
                kind: _selectedResult!.kind,
                category: _selectedCategory,
                isDefault: false,
              ),
              onButtonPressed: _onConfirmSelection,
              buttonText: 'Add This Link',
              onPrev: _onPrevResult,
              onNext: _onNextResult,
            ),
          Expanded(
            child: Stack(
              children: [
                ListView.separated(
                  controller: _scrollController,
                  itemCount: _results.length,
                  separatorBuilder: (_, __) => const Divider(height: 1),
                  itemBuilder: (context, index) {
                    final result = _results[index];
                    final isActive = _selectedResult?.url == result.url;
                    final itemKey = ValueKey(result.url);
                    final globalKey = GlobalKey();
                    _itemKeys[itemKey] = globalKey;

                    return KeyedSubtree(
                      key: globalKey,
                      child: ListTile(
                        key: itemKey,
                        contentPadding: const EdgeInsets.symmetric(
                          horizontal: 12,
                          vertical: 8,
                        ),
                        leading: Stack(
                          children: [
                            result.thumbnailUrl != null
                                ? ClipRRect(
                                  borderRadius: BorderRadius.circular(4),
                                  child: Image.network(
                                    result.thumbnailUrl!,
                                    width: 60,
                                    height: 60,
                                    fit: BoxFit.cover,
                                  ),
                                )
                                : Container(
                                  width: 60,
                                  height: 60,
                                  alignment: Alignment.center,
                                  decoration: BoxDecoration(
                                    borderRadius: BorderRadius.circular(4),
                                    color: Colors.grey.shade200,
                                  ),
                                  child: Icon(
                                    result.kind == LinkKind.spotify
                                        ? Icons.music_note
                                        : Icons.play_circle_fill,
                                    size: 32,
                                  ),
                                ),
                            _kindBadge(result.kind),
                          ],
                        ),
                        title: Text(
                          result.title,
                          maxLines: 2,
                          overflow: TextOverflow.ellipsis,
                        ),
                        tileColor: isActive ? Colors.deepPurple.shade50 : null,
                        onTap: () => _onSelect(result),
                      ),
                    );
                  },
                ),
                if (_isLoading)
                  const Positioned(
                    bottom: 8,
                    left: 0,
                    right: 0,
                    child: Center(child: CircularProgressIndicator()),
                  ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

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
