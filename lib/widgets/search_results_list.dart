import 'package:flutter/material.dart';
import '../models/search_result.dart';


class SearchResultsList extends StatefulWidget {
  final List<SearchResult> results;
  final ValueChanged<SearchResult> onSelected;
  final SearchResult? selected;
  final void Function()? onScrollEnd;

  const SearchResultsList({
    super.key,
    required this.results,
    required this.onSelected,
    this.selected,
    this.onScrollEnd,
  });

  @override
  State<SearchResultsList> createState() => _SearchResultsListState();
}

class _SearchResultsListState extends State<SearchResultsList> {
  final _scrollController = ScrollController();
  final _itemKeys = <String, GlobalKey>{};

  @override
  void initState() {
    super.initState();
    _scrollController.addListener(_onScroll);
  }

  @override
  void didUpdateWidget(covariant SearchResultsList oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (widget.selected?.url != oldWidget.selected?.url) {
      _scrollToSelected();
    }
  }

  void _onScroll() {
    if (_scrollController.position.pixels >=
        _scrollController.position.maxScrollExtent - 100) {
      widget.onScrollEnd?.call();
    }
  }

  void _scrollToSelected() {
    final key = widget.selected?.url;
    if (key != null && _itemKeys.containsKey(key)) {
      final context = _itemKeys[key]!.currentContext;
      if (context != null) {
        Scrollable.ensureVisible(
          context,
          duration: const Duration(milliseconds: 300),
          alignment: 0.5,
        );
      }
    }
  }

  @override
  void dispose() {
    _scrollController.removeListener(_onScroll);
    _scrollController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return ListView.separated(
      controller: _scrollController,
      itemCount: widget.results.length,
      separatorBuilder: (_, __) => const Divider(height: 1),
      itemBuilder: (context, index) {
        final result = widget.results[index];
        final isActive = widget.selected?.url == result.url;
        final key = _itemKeys.putIfAbsent(result.url, () => GlobalKey());

        return ListTile(
          key: key,
          contentPadding: const EdgeInsets.symmetric(
            horizontal: 12,
            vertical: 8,
          ),
          leading:
              result.thumbnailUrl != null
                  ? ClipRRect(
                    borderRadius: BorderRadius.circular(4),
                    child: Image.network(
                      result.thumbnailUrl!,
                      width: 80,
                      height: 60,
                      fit: BoxFit.cover,
                      errorBuilder: (context, error, stackTrace) => Icon(Icons.broken_image, size: 48, color: Colors.grey),
                    ),
                  )
                  : const Icon(Icons.music_video, size: 40),
          title: Text(
            result.title,
            maxLines: 2,
            overflow: TextOverflow.ellipsis,
          ),
          tileColor: isActive ? Colors.deepPurple.shade50 : null,
          onTap: () => widget.onSelected(result),
        );
      },
    );
  }
}
