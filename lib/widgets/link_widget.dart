import 'package:flutter/material.dart';
import 'package:font_awesome_flutter/font_awesome_flutter.dart';
import 'package:flutter_svg/flutter_svg.dart';
import 'package:url_launcher/url_launcher.dart';
import '../models/link.dart';
import '../models/song.dart';
import 'link_editor_widgets.dart';

class LinkWidget extends StatefulWidget {
  final Link link;
  final ValueChanged<Link> onUpdated;
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
  late Link _editedLink;
  bool _editMode = false;
  bool _expanded = false;

  @override
  void initState() {
    super.initState();
    _editedLink = widget.link;
    _expanded = widget.initiallyExpanded;

    if (_editedLink.link.isEmpty) {
      _editMode = true;
    }
  }

  void _openLink() async {
    final uri = Uri.tryParse(_editedLink.link);
    if (uri != null && await canLaunchUrl(uri)) {
      await launchUrl(uri, mode: LaunchMode.externalApplication);
    }
  }

  Widget _iconForKind(String kind) {
    switch (kind.toLowerCase()) {
      case 'youtube':
        return const Icon(FontAwesomeIcons.youtube);
      case 'spotify':
        return const Icon(FontAwesomeIcons.spotify);
      case 'media':
        return const Icon(Icons.audiotrack);
      case 'skool':
        return const Icon(Icons.school);
      case 'soundslice':
        return const Icon(Icons.slideshow);
      case 'ireal':
        return SvgPicture.asset(
          'assets/icons/iRP_icon.svg',
          height: 24,
          width: 24,
        );
      default:
        return const Icon(Icons.link);
    }
  }

  Widget _topBar() {
    return Row(
      mainAxisAlignment: MainAxisAlignment.spaceBetween,
      children: [
        if (!_editMode)
          IconButton(
            icon: _iconForKind(_editedLink.kind),
            tooltip: 'Open Link',
            onPressed: _openLink,
          ),
        Expanded(
          child:
              _editMode
                  ? Row(
                    children: [
                      SizedBox(
                        width: 70,
                        child: DropdownButtonFormField<String>(
                          value: _editedLink.key,
                          decoration: const InputDecoration(labelText: 'Key'),
                          items:
                              Song.musicalKeys
                                  .map(
                                    (k) => DropdownMenuItem(
                                      value: k,
                                      child: Text(k),
                                    ),
                                  )
                                  .toList(),
                          onChanged: (val) {
                            if (val != null) {
                              setState(() {
                                _editedLink = _editedLink.copyWith(key: val);
                              });
                            }
                          },
                        ),
                      ),
                      const SizedBox(width: 8),
                      Expanded(
                        child: TextFormField(
                          initialValue: _editedLink.name,
                          decoration: const InputDecoration(labelText: 'Label'),
                          onChanged:
                              (val) => setState(() {
                                _editedLink = _editedLink.copyWith(name: val);
                              }),
                        ),
                      ),
                    ],
                  )
                  : Text(
                    '${_editedLink.key} • ${_editedLink.name}',
                    style: const TextStyle(
                      fontSize: 16,
                      fontWeight: FontWeight.bold,
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
                      content: const Text(
                        'Are you sure you want to delete this link?',
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
            onPressed: () {
              final isNewEmptyLink = _editedLink.isBlank && widget.link.isBlank;
              if (isNewEmptyLink) {
                widget.onDelete();
              } else {
                setState(() {
                  _editMode = false;
                  _editedLink = widget.link;
                });
              }
            },
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

  void _openSearchScreen() async {
    // TODO: Implement real search logic
    debugPrint('🔍 Web search not implemented');
  }

  void _pickLocalFile() async {
    // TODO: Implement local file picker
    debugPrint('📁 Local file picker not implemented');
  }

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        _topBar(),
        if (_editMode && !widget.readOnly) ...[
          const SizedBox(height: 8),
          LinkCategoryPicker(
            selected: _editedLink.category,
            onChanged:
                (val) => setState(
                  () => _editedLink = _editedLink.copyWith(category: val),
                ),
          ),
          const SizedBox(height: 12),
          LinkUrlFieldWithButtons(
            value: _editedLink.link,
            onChanged:
                (val) => setState(
                  () => _editedLink = _editedLink.copyWith(link: val),
                ),
            onWebSearch: _openSearchScreen,
            onFilePick: _pickLocalFile,
          ),
        ] else if (widget.readOnly && _expanded) ...[
          const SizedBox(height: 8),
          Text('Kind: ${_editedLink.kind}'),
          Text('Category: ${_editedLink.category}'),
          Text('Link: ${_editedLink.link}'),
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
