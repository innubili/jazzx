import 'package:flutter/material.dart';
import '../models/link.dart';
import '../widgets/link_widget.dart';

typedef LinkSelectedCallback = void Function(Link link);

class LinkBrowserWidget extends StatefulWidget {
  final List<Link> links;
  final bool readOnly;
  final bool selectable;
  final LinkSelectedCallback? onSelected;
  final String? initialScrollToKey;
  final bool expandInitially;
  final void Function()? onAddNew;
  final String? filterKind;

  const LinkBrowserWidget({
    super.key,
    required this.links,
    this.readOnly = false,
    this.selectable = false,
    this.onSelected,
    this.initialScrollToKey,
    this.expandInitially = false,
    this.onAddNew,
    this.filterKind,
  });

  @override
  State<LinkBrowserWidget> createState() => _LinkBrowserWidgetState();
}

class _LinkBrowserWidgetState extends State<LinkBrowserWidget> {
  final _scrollController = ScrollController();
  final _itemKeys = <String, GlobalKey>{};

  String _searchQuery = '';
  String _sortField = 'key';
  bool _ascending = true;

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) => _scrollToInitialLink());
  }

  void _scrollToInitialLink() {
    if (widget.initialScrollToKey == null) return;
    final key = _itemKeys[widget.initialScrollToKey!];
    if (key?.currentContext != null) {
      Scrollable.ensureVisible(
        key!.currentContext!,
        duration: const Duration(milliseconds: 500),
      );
    }
  }

  List<Link> _filteredAndSortedLinks(List<Link> links) {
    final query = _searchQuery.toLowerCase();
    final filtered =
        links.where((l) {
          final matchesQuery =
              l.key.toLowerCase().contains(query) ||
              l.kind.toLowerCase().contains(query);
          final matchesKind =
              widget.filterKind == null || l.kind == widget.filterKind;
          return matchesQuery && matchesKind;
        }).toList();

    filtered.sort((a, b) {
      final aValue = _getFieldValue(a);
      final bValue = _getFieldValue(b);
      return _ascending ? aValue.compareTo(bValue) : bValue.compareTo(aValue);
    });

    return filtered;
  }

  String _getFieldValue(Link link) {
    switch (_sortField) {
      case 'kind':
        return link.kind;
      default:
        return link.key;
    }
  }

  @override
  Widget build(BuildContext context) {
    final links = _filteredAndSortedLinks(widget.links);

    return Column(
      children: [
        Padding(
          padding: const EdgeInsets.all(8),
          child: Row(
            children: [
              Expanded(
                child: TextField(
                  decoration: const InputDecoration(
                    labelText: 'Search links...',
                  ),
                  onChanged: (val) => setState(() => _searchQuery = val.trim()),
                ),
              ),
              const SizedBox(width: 8),
              DropdownButton<String>(
                value: _sortField,
                items: const [
                  DropdownMenuItem(value: 'key', child: Text('Key')),
                  DropdownMenuItem(value: 'kind', child: Text('Kind')),
                ],
                onChanged: (val) => setState(() => _sortField = val ?? 'key'),
              ),
              IconButton(
                icon: Icon(
                  _ascending ? Icons.arrow_upward : Icons.arrow_downward,
                ),
                onPressed: () => setState(() => _ascending = !_ascending),
              ),
            ],
          ),
        ),
        Expanded(
          child: ListView.builder(
            controller: _scrollController,
            itemCount: links.length,
            itemBuilder: (context, index) {
              final link = links[index];
              final initiallyExpanded =
                  widget.expandInitially &&
                  link.key == widget.initialScrollToKey;

              final key = _itemKeys.putIfAbsent(link.key, () => GlobalKey());

              return Card(
                key: key,
                margin: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                child: Padding(
                  padding: const EdgeInsets.symmetric(
                    horizontal: 12,
                    vertical: 8,
                  ),
                  child: LinkWidget(
                    link: link,
                    readOnly: widget.readOnly,
                    selectable: widget.selectable,
                    initiallyExpanded: initiallyExpanded,
                    onSelected:
                        widget.onSelected != null
                            ? () => widget.onSelected!(link)
                            : null,
                    onUpdated: (updated) {
                      setState(() {
                        final i = widget.links.indexWhere(
                          (l) => l.key == updated.key,
                        );
                        if (i >= 0) {
                          widget.links[i] = updated;
                        }
                      });
                    },
                    onDelete: () {
                      setState(() {
                        widget.links.removeWhere((l) => l.key == link.key);
                      });
                    },
                  ),
                ),
              );
            },
          ),
        ),
        if (!widget.readOnly && widget.onAddNew != null)
          Padding(
            padding: const EdgeInsets.symmetric(vertical: 12),
            child: ElevatedButton.icon(
              icon: const Icon(Icons.add),
              label: const Text("Add New Link"),
              onPressed: widget.onAddNew,
            ),
          ),
      ],
    );
  }
}
