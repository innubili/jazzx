import 'package:flutter/material.dart';
import 'package:jazzx_app/models/link_type.dart';
import '../utils/log.dart';
import '../models/song.dart';

class SongLinkWidget extends StatefulWidget {
  final String? initialLink;
  final LinkType? initialType;
  final void Function(String link, LinkType type) onSaved;

  const SongLinkWidget({
    super.key,
    this.initialLink,
    this.initialType,
    required this.onSaved,
  });

  @override
  State<SongLinkWidget> createState() => _SongLinkWidgetState();
}

class _SongLinkWidgetState extends State<SongLinkWidget> {
  late TextEditingController _linkController;
  SongLinkCategory? _selectedCategory;
  LinkType? _determinedType;

  @override
  void initState() {
    super.initState();
    _linkController = TextEditingController(text: widget.initialLink ?? '');
    _determinedType = widget.initialType;
    _selectedCategory =
        widget.initialType != null
            ? getCategoryForLinkType(widget.initialType!)
            : null;
  }

  @override
  void dispose() {
    _linkController.dispose();
    super.dispose();
  }

  void _pickLocalFile() async {
    // TODO: Implement local file picker
    log.warning('📁 Pick local file (not implemented yet)');
  }

  void _onSavePressed() {
    final link = _linkController.text.trim();
    if (link.isEmpty || _determinedType == null) return;
    widget.onSaved(link, _determinedType!);
  }

  void _onCategoryChanged(SongLinkCategory? category) {
    setState(() {
      _selectedCategory = category;
      _determinedType = _defaultTypeForCategory(category);
    });
  }

  LinkType? _defaultTypeForCategory(SongLinkCategory? category) {
    if (category == null) return null;

    switch (category) {
      case SongLinkCategory.backingTrack:
        return LinkType.irealPro;
      case SongLinkCategory.playlist:
        return LinkType.spotify;
      case SongLinkCategory.lesson:
        return LinkType.youtube;
      case SongLinkCategory.scores:
        return LinkType.localFile;
      case SongLinkCategory.other:
        return LinkType.other;
    }
  }

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const Text(
          "Add or edit song link",
          style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold),
        ),
        const SizedBox(height: 8),

        TextField(
          controller: _linkController,
          decoration: const InputDecoration(
            labelText: 'Paste link here',
            border: OutlineInputBorder(),
          ),
        ),
        const SizedBox(height: 8),

        Row(
          children: [
            Expanded(
              child: DropdownButtonFormField<SongLinkCategory>(
                value: _selectedCategory,
                decoration: const InputDecoration(
                  labelText: 'Link Category',
                  border: OutlineInputBorder(),
                ),
                items:
                    SongLinkCategory.values
                        .map(
                          (c) =>
                              DropdownMenuItem(value: c, child: Text(c.name)),
                        )
                        .toList(),
                onChanged: _onCategoryChanged,
              ),
            ),
            const SizedBox(width: 8),
            ElevatedButton.icon(
              icon: const Icon(Icons.folder_open),
              label: const Text("Pick file"),
              onPressed: _pickLocalFile,
            ),
          ],
        ),
        const SizedBox(height: 12),

        Row(
          mainAxisAlignment: MainAxisAlignment.end,
          children: [
            ElevatedButton.icon(
              icon: const Icon(Icons.check),
              label: const Text("Save Link"),
              onPressed: _onSavePressed,
            ),
          ],
        ),
      ],
    );
  }
}
