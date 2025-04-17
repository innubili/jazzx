import 'package:flutter/material.dart';
import '../models/song.dart';

class LinkWidget extends StatefulWidget {
  final SongLink link;
  final ValueChanged<SongLink> onUpdated;
  final VoidCallback onDelete;
  final String? highlightQuery;
  final bool readOnly;
  final bool selectable;
  final VoidCallback? onSelected;
  final bool initiallyExpanded;

  const LinkWidget({
    super.key,
    required this.link,
    required this.onUpdated,
    required this.onDelete,
    this.highlightQuery,
    this.readOnly = false,
    this.selectable = false,
    this.onSelected,
    this.initiallyExpanded = false,
  });

  @override
  State<LinkWidget> createState() => _LinkWidgetState();
}

class _LinkWidgetState extends State<LinkWidget> {
  late SongLink _editedLink;
  bool _editMode = false;
  bool _expanded = false;

  @override
  void initState() {
    super.initState();
    _editedLink = widget.link;
    _expanded = widget.initiallyExpanded;
  }

  TextSpan _highlightedText(String text) {
    final query = widget.highlightQuery?.toLowerCase() ?? '';
    if (query.isEmpty || _editMode) return TextSpan(text: text);

    final spans = <TextSpan>[];
    int start = 0;
    final lower = text.toLowerCase();

    while (true) {
      final index = lower.indexOf(query, start);
      if (index < 0) {
        spans.add(TextSpan(text: text.substring(start)));
        break;
      }
      if (index > start) {
        spans.add(TextSpan(text: text.substring(start, index)));
      }
      spans.add(
        TextSpan(
          text: text.substring(index, index + query.length),
          style: const TextStyle(backgroundColor: Colors.yellow),
        ),
      );
      start = index + query.length;
    }

    return TextSpan(children: spans);
  }

  Widget _editableText(
    String label,
    String value,
    ValueChanged<String> onChanged,
  ) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 4),
      child: TextFormField(
        initialValue: value,
        enabled: _editMode,
        decoration: InputDecoration(labelText: label, filled: true),
        onChanged: onChanged,
      ),
    );
  }

  Widget _topBar() {
    return Row(
      mainAxisAlignment: MainAxisAlignment.spaceBetween,
      children: [
        Expanded(
          child:
              _editMode
                  ? TextFormField(
                    initialValue: _editedLink.key,
                    style: const TextStyle(
                      fontSize: 16,
                      fontWeight: FontWeight.bold,
                    ),
                    decoration: const InputDecoration(border: InputBorder.none),
                    onChanged:
                        (val) => setState(() {
                          _editedLink = _editedLink.copyWith(key: val);
                        }),
                  )
                  : RichText(
                    text: TextSpan(
                      style: const TextStyle(
                        fontSize: 16,
                        fontWeight: FontWeight.bold,
                        color: Colors.black,
                      ),
                      children: [_highlightedText(_editedLink.key)],
                    ),
                    overflow: TextOverflow.ellipsis,
                  ),
        ),
        if (!_editMode && !widget.readOnly) ...[
          IconButton(
            icon: const Icon(Icons.edit),
            tooltip: 'Edit',
            onPressed: () => setState(() => _editMode = true),
          ),
          IconButton(
            icon: const Icon(Icons.delete),
            tooltip: 'Delete',
            onPressed: () async {
              final confirm = await showDialog<bool>(
                context: context,
                builder:
                    (_) => AlertDialog(
                      title: const Text('Confirm Deletion'),
                      content: Text(
                        'Are you sure you want to delete link "${_editedLink.key}"?',
                      ),
                      actions: [
                        TextButton(
                          onPressed: () => Navigator.pop(context, false),
                          child: const Text('Cancel'),
                        ),
                        TextButton(
                          onPressed: () => Navigator.pop(context, true),
                          child: const Text('Delete'),
                        ),
                      ],
                    ),
              );
              if (confirm == true) widget.onDelete();
            },
          ),
        ] else if (_editMode && !widget.readOnly) ...[
          IconButton(
            icon: const Icon(Icons.check),
            tooltip: 'Save',
            onPressed: () {
              widget.onUpdated(_editedLink);
              setState(() => _editMode = false);
            },
          ),
          IconButton(
            icon: const Icon(Icons.close),
            tooltip: 'Cancel',
            onPressed:
                () => setState(() {
                  _editMode = false;
                  _editedLink = widget.link;
                }),
          ),
        ] else if (widget.readOnly && !_expanded) ...[
          IconButton(
            icon: const Icon(Icons.expand_more),
            tooltip: 'Expand',
            onPressed: () => setState(() => _expanded = true),
          ),
        ] else if (widget.readOnly && _expanded) ...[
          IconButton(
            icon: const Icon(Icons.expand_less),
            tooltip: 'Collapse',
            onPressed: () => setState(() => _expanded = false),
          ),
        ],
      ],
    );
  }

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        _topBar(),
        if (_editMode && !widget.readOnly) ...[
          _editableText(
            'Type',
            _editedLink.kind,
            (val) =>
                setState(() => _editedLink = _editedLink.copyWith(kind: val)),
          ),
          _editableText(
            'Link',
            _editedLink.link,
            (val) =>
                setState(() => _editedLink = _editedLink.copyWith(link: val)),
          ),
        ] else if (widget.readOnly && _expanded) ...[
          const SizedBox(height: 8),
          Text('Kind: ${_editedLink.kind}'),
          Text('URL: ${_editedLink.link}'),
          if (widget.selectable && widget.onSelected != null)
            Align(
              alignment: Alignment.centerRight,
              child: TextButton.icon(
                icon: const Icon(Icons.check_circle_outline),
                label: const Text('Select This Link'),
                onPressed: widget.onSelected,
              ),
            ),
        ],
      ],
    );
  }
}
