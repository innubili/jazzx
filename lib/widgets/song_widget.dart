import 'package:flutter/material.dart';
import '../models/song.dart';
import '../models/link.dart';
import '../screens/link_search_screen.dart' show LinkSearchScreen;
import 'link_editor_widgets.dart';
import 'link_widget.dart';
import 'link_view_panel.dart';

class SongWidget extends StatefulWidget {
  final Song song;
  final ValueChanged<Song> onUpdated;
  final VoidCallback onCopy;
  final VoidCallback onDelete;
  final String? highlightQuery;
  final bool readOnly;
  final bool selectable;
  final VoidCallback? onSelected;
  final bool initiallyExpanded;
  final LinkKind? addLinkForKind;

  const SongWidget({
    super.key,
    required this.song,
    required this.onUpdated,
    required this.onCopy,
    required this.onDelete,
    this.highlightQuery,
    this.readOnly = false,
    this.selectable = false,
    this.onSelected,
    this.initiallyExpanded = false,
    this.addLinkForKind,
  });

  @override
  State<SongWidget> createState() => _SongWidgetState();
}

class _SongWidgetState extends State<SongWidget> {
  late Song _editedSong;
  bool _editMode = false;
  bool _expanded = false;
  bool _useCustomKey = false;
  Link? _previewLink;

  final TextEditingController _customKeyController = TextEditingController();

  @override
  void initState() {
    super.initState();
    _editedSong = widget.song;
    _expanded = widget.initiallyExpanded;

    if (!MusicalKeys.contains(_editedSong.key)) {
      _useCustomKey = true;
      _customKeyController.text = _editedSong.key;
    }
    if (_expanded && widget.addLinkForKind != null) {
      _editMode = true;
      _addLinkOfKindIfMissing(widget.addLinkForKind!);
    }
  }

  @override
  void dispose() {
    _customKeyController.dispose();
    widget.onUpdated(_editedSong);
    super.dispose();
  }

  void _addLinkOfKindIfMissing(LinkKind kind) {
    final alreadyExists = _editedSong.links.any(
      (link) => link.kind.name == kind.name,
    );
    if (!alreadyExists) {
      final newLink = Link.defaultLink(_editedSong.title);
      setState(() {
        _editedSong = _editedSong.copyWith(
          links: [..._editedSong.links, newLink],
        );
      });
    }
  }

  void _toggleLinkPreview(Link link) {
    setState(() {
      _previewLink = (_previewLink == link) ? null : link;
    });
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

  Widget _editableBpm() {
    final bpmList = List.generate(41, (i) => (i * 5) + 60);
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 4),
      child: DropdownButtonFormField<int>(
        decoration: const InputDecoration(labelText: 'BPM', filled: true),
        value: _editedSong.bpm > 0 ? _editedSong.bpm : 100,
        items:
            bpmList
                .map(
                  (bpm) =>
                      DropdownMenuItem(value: bpm, child: Text(bpm.toString())),
                )
                .toList(),
        onChanged:
            _editMode
                ? (val) => setState(
                  () => _editedSong = _editedSong.copyWith(bpm: val ?? 100),
                )
                : null,
      ),
    );
  }

  Widget _editableKey() {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 4),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          DropdownButtonFormField<String>(
            decoration: const InputDecoration(labelText: 'Key', filled: true),
            value: _useCustomKey ? 'Other' : _editedSong.key,
            items: [
              ...MusicalKeys.map(
                (k) => DropdownMenuItem(value: k, child: Text(k)),
              ),
              const DropdownMenuItem(value: 'Other', child: Text('Other')),
            ],
            onChanged:
                _editMode
                    ? (val) => setState(() {
                      if (val == 'Other') {
                        _useCustomKey = true;
                        _editedSong = _editedSong.copyWith(
                          key: _customKeyController.text,
                        );
                      } else {
                        _useCustomKey = false;
                        _editedSong = _editedSong.copyWith(key: val ?? 'C');
                      }
                    })
                    : null,
          ),
          if (_editMode && _useCustomKey)
            TextFormField(
              controller: _customKeyController,
              decoration: const InputDecoration(
                labelText: 'Custom Key',
                filled: true,
              ),
              onChanged:
                  (val) => setState(
                    () => _editedSong = _editedSong.copyWith(key: val),
                  ),
            ),
        ],
      ),
    );
  }

  Widget _summaryRow() {
    final summary = _editedSong.summary;
    return Padding(
      padding: const EdgeInsets.only(top: 4),
      child: RichText(
        text: _highlightedText(summary),
        maxLines: 2,
        overflow: TextOverflow.ellipsis,
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
                    initialValue: _editedSong.title,
                    style: const TextStyle(
                      fontSize: 20,
                      fontWeight: FontWeight.bold,
                    ),
                    decoration: const InputDecoration(border: InputBorder.none),
                    onChanged:
                        (val) => setState(
                          () => _editedSong = _editedSong.copyWith(title: val),
                        ),
                  )
                  : RichText(
                    text: TextSpan(
                      style: const TextStyle(
                        fontSize: 20,
                        fontWeight: FontWeight.bold,
                        color: Colors.black,
                      ),
                      children: [_highlightedText(_editedSong.title)],
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
            icon: const Icon(Icons.copy),
            tooltip: 'Duplicate',
            onPressed: widget.onCopy,
          ),
          IconButton(
            icon: const Icon(Icons.delete),
            tooltip: 'Delete',
            onPressed: () async {
              final confirm = await showDialog<bool>(
                context: context,
                builder:
                    (context) => AlertDialog(
                      title: const Text('Confirm Deletion'),
                      content: Text(
                        'Are you sure you want to delete "${_editedSong.title}"?',
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
            onPressed: () => setState(() => _editMode = false),
          ),
          IconButton(
            icon: const Icon(Icons.close),
            tooltip: 'Cancel',
            onPressed:
                () => setState(() {
                  _editMode = false;
                  _editedSong = widget.song;
                  _customKeyController.text = widget.song.key;
                  _useCustomKey = !MusicalKeys.contains(widget.song.key);
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

  Widget _editableLinks() {
    if (!_editMode && _editedSong.links.isEmpty) return const SizedBox();

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const Divider(),
        const Text('Links', style: TextStyle(fontWeight: FontWeight.bold)),
        ..._editedSong.links.map(
          (link) => LinkWidget(
            link: link,
            readOnly: widget.readOnly,
            onViewPressed: () => _toggleLinkPreview(link),
            onUpdated: (updated) {
              final existingIndex = _editedSong.links.indexWhere(
                (l) => l.key == link.key,
              );

              List<Link> newLinks = [..._editedSong.links];
              if (existingIndex >= 0) {
                newLinks[existingIndex] = updated;
              } else {
                newLinks.add(updated);
              }

              setState(() {
                _editedSong = _editedSong.copyWith(links: newLinks);
              });
            },
            onDelete: () {
              final updatedLinks =
                  _editedSong.links.where((l) => l != link).toList();
              setState(() {
                _editedSong = _editedSong.copyWith(links: updatedLinks);
                if (_previewLink == link) _previewLink = null;
              });
            },
          ),
        ),
        if (_previewLink != null)
          LinkViewPanel(
            link: _previewLink!,
            onPrev: () {
              final i = _editedSong.links.indexOf(_previewLink!);
              if (i > 0) {
                setState(() => _previewLink = _editedSong.links[i - 1]);
              }
            },
            onNext: () {
              final i = _editedSong.links.indexOf(_previewLink!);
              if (i < _editedSong.links.length - 1) {
                setState(() => _previewLink = _editedSong.links[i + 1]);
              }
            },
            buttonText: 'Close',
            onButtonPressed: () => setState(() => _previewLink = null),
          ),
        if (_editMode && !_editedSong.links.any((link) => link.link.isEmpty))
          Align(
            alignment: Alignment.centerLeft,
            child: TextButton.icon(
              icon: const Icon(Icons.add),
              label: const Text("Add Link"),
              onPressed: () async {
                final newLink = Link.defaultLink(_editedSong.title);
                final selected = await Navigator.push<Link>(
                  context,
                  MaterialPageRoute(
                    builder:
                        (_) => LinkSearchScreen(
                          songTitle: newLink.name,
                          onSelected: (link) => Navigator.pop(context, link),
                        ),
                  ),
                );

                if (!mounted || selected == null) return;

                final confirmed = await showDialog<Link>(
                  context: context,
                  builder: (_) => LinkConfirmationDialog(initialLink: selected),
                );

                if (confirmed != null) {
                  setState(() {
                    _editedSong = _editedSong.copyWith(
                      links: [..._editedSong.links, confirmed],
                    );
                  });
                }
              },
            ),
          ),
      ],
    );
  }

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          _topBar(),
          if (!_editMode) _summaryRow(),
          if (_editMode && !widget.readOnly) ...[
            _editableText(
              "Composer",
              _editedSong.songwriters,
              (val) => setState(
                () => _editedSong = _editedSong.copyWith(songwriters: val),
              ),
            ),
            _editableKey(),
            _editableText(
              "Style",
              _editedSong.type,
              (val) =>
                  setState(() => _editedSong = _editedSong.copyWith(type: val)),
            ),
            _editableText(
              "Form",
              _editedSong.form,
              (val) =>
                  setState(() => _editedSong = _editedSong.copyWith(form: val)),
            ),
            _editableBpm(),
            _editableText(
              "Year",
              _editedSong.year,
              (val) =>
                  setState(() => _editedSong = _editedSong.copyWith(year: val)),
            ),
            _editableText(
              "Notes",
              _editedSong.notes,
              (val) => setState(
                () => _editedSong = _editedSong.copyWith(notes: val),
              ),
            ),
            _editableText(
              "Recommended Versions",
              _editedSong.recommendedVersions,
              (val) => setState(
                () =>
                    _editedSong = _editedSong.copyWith(
                      recommendedVersions: val,
                    ),
              ),
            ),
            _editableLinks(),
          ] else if (widget.readOnly && _expanded) ...[
            const SizedBox(height: 8),
            Text("Composer: ${_editedSong.songwriters}"),
            Text("Key: ${_editedSong.key}"),
            Text("Style: ${_editedSong.type}"),
            Text("Form: ${_editedSong.form}"),
            Text("BPM: ${_editedSong.bpm}"),
            Text("Year: ${_editedSong.year}"),
            if (_editedSong.notes.isNotEmpty)
              Text("Notes: ${_editedSong.notes}"),
            if (_editedSong.recommendedVersions.isNotEmpty)
              Text("Recommended: ${_editedSong.recommendedVersions}"),
            _editableLinks(),
            if (widget.selectable && widget.onSelected != null)
              Padding(
                padding: const EdgeInsets.only(top: 16.0),
                child: Align(
                  alignment: Alignment.centerRight,
                  child: TextButton.icon(
                    icon: const Icon(Icons.check_circle_outline),
                    label: const Text('Select This Song'),
                    onPressed: widget.onSelected,
                  ),
                ),
              ),
          ],
        ],
      ),
    );
  }
}
