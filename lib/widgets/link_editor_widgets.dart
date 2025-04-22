import 'package:flutter/material.dart';
import 'package:flutter_svg/flutter_svg.dart';
import '../models/link.dart';
import '../models/song.dart';

class LinkConfirmationDialog extends StatefulWidget {
  final Link initialLink;

  const LinkConfirmationDialog({super.key, required this.initialLink});

  @override
  State<LinkConfirmationDialog> createState() => _LinkConfirmationDialogState();
}

class _LinkConfirmationDialogState extends State<LinkConfirmationDialog> {
  late TextEditingController _nameController;
  late String _key;
  late TextEditingController _customKeyController;
  late LinkCategory _category;

  @override
  void initState() {
    super.initState();
    _nameController = TextEditingController(text: widget.initialLink.name);
    _customKeyController = TextEditingController();
    _key =
        MusicalKeys.contains(widget.initialLink.key)
            ? widget.initialLink.key
            : 'Other';
    _category = widget.initialLink.category;
  }

  @override
  void dispose() {
    _nameController.dispose();
    _customKeyController.dispose();
    super.dispose();
  }

  void _save() {
    final updated = widget.initialLink.copyWith(
      name: _nameController.text.trim(),
      key: _key,
      category: _category,
    );
    Navigator.pop(context, updated);
  }

  @override
  Widget build(BuildContext context) {
    return Dialog(
      insetPadding: const EdgeInsets.all(24),
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            const Text(
              "Link Details",
              style: TextStyle(fontWeight: FontWeight.bold),
            ),
            const SizedBox(height: 12),
            LinkCategoryPicker(
              selected: _category,
              onChanged: (cat) => setState(() => _category = cat),
            ),
            const SizedBox(height: 12),
            TextField(
              controller: _nameController,
              decoration: const InputDecoration(labelText: 'Name'),
            ),
            const SizedBox(height: 8),
            DropdownButtonFormField<String>(
              value: _key,
              decoration: const InputDecoration(labelText: 'Key'),
              items: [
                ...MusicalKeys.map(
                  (k) => DropdownMenuItem(value: k, child: Text(k)),
                ),
                const DropdownMenuItem(value: 'Other', child: Text('Other')),
              ],
              onChanged: (val) {
                setState(() {
                  _key = val!;
                });
              },
            ),

            const SizedBox(height: 12),
            IgnorePointer(
              child: Opacity(
                opacity: 0.5,
                child: LinkKindPicker(
                  selected: {widget.initialLink.kind},
                  onChanged: (_) {},
                ),
              ),
            ),
            const SizedBox(height: 12),
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                TextButton(
                  onPressed: () => Navigator.pop(context),
                  child: const Text("Cancel"),
                ),
                ElevatedButton(onPressed: _save, child: const Text("Save")),
              ],
            ),
          ],
        ),
      ),
    );
  }
}

class LinkCategoryPicker extends StatelessWidget {
  final LinkCategory selected;
  final ValueChanged<LinkCategory> onChanged;

  const LinkCategoryPicker({
    super.key,
    required this.selected,
    required this.onChanged,
  });

  Widget _iconFor(LinkCategory category) {
    switch (category) {
      case LinkCategory.backingTrack:
        return SvgPicture.asset('assets/icons/iRP_icon.svg', height: 20);
      case LinkCategory.playlist:
        return const Icon(Icons.queue_music, size: 20);
      case LinkCategory.lesson:
        return const Icon(Icons.school, size: 20);
      case LinkCategory.scores:
        return const Icon(Icons.picture_as_pdf, size: 20);
      case LinkCategory.other:
        return const Icon(Icons.link, size: 20);
    }
  }

  String _labelFor(LinkCategory category) {
    switch (category) {
      case LinkCategory.backingTrack:
        return 'B.Track';
      case LinkCategory.playlist:
        return 'Playlist';
      case LinkCategory.lesson:
        return 'Lesson';
      case LinkCategory.scores:
        return 'PDF';
      case LinkCategory.other:
        return 'Other';
    }
  }

  @override
  Widget build(BuildContext context) {
    final categories = LinkCategory.values;
    final selectedIndex = categories.indexOf(selected);

    return Center(
      child: ToggleButtons(
        borderRadius: BorderRadius.circular(8),
        isSelected: List.generate(categories.length, (i) => i == selectedIndex),
        onPressed: (index) => onChanged(categories[index]),
        constraints: const BoxConstraints(minWidth: 72, minHeight: 64),
        selectedColor: Colors.deepPurple,
        fillColor: Colors.deepPurple.shade50,
        color: Colors.grey.shade700,
        children:
            categories.map((cat) {
              return Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  _iconFor(cat),
                  const SizedBox(height: 4),
                  Text(_labelFor(cat), style: const TextStyle(fontSize: 11)),
                ],
              );
            }).toList(),
      ),
    );
  }
}

class LinkKindPicker extends StatelessWidget {
  final Set<LinkKind> selected;
  final ValueChanged<Set<LinkKind>> onChanged;

  const LinkKindPicker({
    super.key,
    required this.selected,
    required this.onChanged,
  });

  Widget _iconFor(LinkKind kind) {
    switch (kind) {
      case LinkKind.youtube:
        return SvgPicture.asset('assets/icons/youtube_icon.svg', height: 20);
      case LinkKind.spotify:
        return SvgPicture.asset('assets/icons/spotify_icon.svg', height: 20);
      case LinkKind.iReal:
        return SvgPicture.asset('assets/icons/iRP_icon.svg', height: 20);
      case LinkKind.media:
        return const Icon(Icons.insert_drive_file);
      default:
        return const Icon(Icons.link);
    }
  }

  String _labelFor(LinkKind kind) {
    switch (kind) {
      case LinkKind.youtube:
        return 'YouTube';
      case LinkKind.spotify:
        return 'Spotify';
      case LinkKind.iReal:
        return 'iRealPro';
      case LinkKind.media:
        return 'Files';
      default:
        return kind.name;
    }
  }

  @override
  Widget build(BuildContext context) {
    final kinds = [
      LinkKind.youtube,
      LinkKind.spotify,
      LinkKind.iReal,
      LinkKind.media,
    ];

    return Center(
      child: ToggleButtons(
        borderRadius: BorderRadius.circular(8),
        isSelected: List.generate(
          kinds.length,
          (i) => selected.contains(kinds[i]),
        ),
        onPressed: (index) {
          final kind = kinds[index];
          final newSet = Set<LinkKind>.from(selected);
          if (selected.contains(kind)) {
            newSet.remove(kind);
          } else {
            newSet.add(kind);
          }
          onChanged(newSet);
        },
        constraints: const BoxConstraints(minWidth: 72, minHeight: 64),
        selectedColor: Colors.deepPurple,
        fillColor: Colors.deepPurple.shade50,
        color: Colors.grey.shade700,
        children:
            kinds.map((kind) {
              return Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  _iconFor(kind),
                  const SizedBox(height: 4),
                  Text(_labelFor(kind), style: const TextStyle(fontSize: 11)),
                ],
              );
            }).toList(),
      ),
    );
  }
}
