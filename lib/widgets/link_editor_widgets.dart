import 'package:flutter/material.dart';
import 'package:flutter_svg/flutter_svg.dart';
import '../models/link.dart';
import '../models/song.dart';
import 'package:provider/provider.dart';
import '../providers/user_profile_provider.dart';

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
    // Update provider (Firebase) if possible
    final userProfileProvider = Provider.of<UserProfileProvider>(
      context,
      listen: false,
    );
    final song = userProfileProvider.profile?.songs[updated.name];
    if (song != null) {
      userProfileProvider.updateSongLink(updated.name, updated);
    }
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
              onChanged: (val) => setState(() => _key = val!),
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

  Widget _iconFor(LinkCategory category, bool isSelected) {
    final color = isSelected ? Colors.white : Colors.grey.shade700;
    switch (category) {
      case LinkCategory.backingTrack:
        return SvgPicture.asset(
          'assets/icons/iRP_icon.svg',
          height: 20,
          colorFilter: ColorFilter.mode(color, BlendMode.srcIn),
        );
      case LinkCategory.playlist:
        return Icon(Icons.queue_music, size: 20, color: color);
      case LinkCategory.lesson:
        return Icon(Icons.school, size: 20, color: color);
      case LinkCategory.scores:
        return Icon(Icons.picture_as_pdf, size: 20, color: color);
      case LinkCategory.other:
        return Icon(Icons.link, size: 20, color: color);
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

    return Center(
      child: ToggleButtons(
        borderRadius: BorderRadius.circular(8),
        isSelected: List.generate(
          categories.length,
          (i) => categories[i] == selected,
        ),
        onPressed: (index) => onChanged(categories[index]),
        constraints: const BoxConstraints(minWidth: 72, minHeight: 64),
        selectedColor: Colors.white,
        fillColor: Colors.deepPurple,
        color: Colors.grey.shade700,
        children:
            categories.map((cat) {
              final isSelected = cat == selected;
              return Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  _iconFor(cat, isSelected),
                  const SizedBox(height: 4),
                  Text(
                    _labelFor(cat),
                    style: TextStyle(
                      fontSize: 11,
                      color: isSelected ? Colors.white : Colors.grey.shade700,
                    ),
                  ),
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

  Widget _iconFor(LinkKind kind, bool isSelected) {
    final color = isSelected ? Colors.white : Colors.grey.shade700;
    switch (kind) {
      case LinkKind.youtube:
        return SvgPicture.asset(
          'assets/icons/youtube_icon.svg',
          height: 20,
          colorFilter: ColorFilter.mode(color, BlendMode.srcIn),
        );
      case LinkKind.spotify:
        return SvgPicture.asset(
          'assets/icons/spotify_icon.svg',
          height: 20,
          colorFilter: ColorFilter.mode(color, BlendMode.srcIn),
        );
      case LinkKind.iReal:
        return SvgPicture.asset(
          'assets/icons/iRP_icon.svg',
          height: 20,
          colorFilter: ColorFilter.mode(color, BlendMode.srcIn),
        );
      case LinkKind.media:
        return Icon(Icons.insert_drive_file, color: color);
      default:
        return Icon(Icons.link, color: color);
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
        isSelected: kinds.map((k) => selected.contains(k)).toList(),
        onPressed: (index) {
          final kind = kinds[index];
          // Single-select: only one kind can be selected at a time
          final newSet = <LinkKind>{kind};
          onChanged(newSet);
        },
        constraints: const BoxConstraints(minWidth: 72, minHeight: 64),
        selectedColor: Colors.white,
        fillColor: Colors.deepPurple,
        color: Colors.grey.shade700,
        children:
            kinds.map((kind) {
              final isSelected = selected.contains(kind);
              return Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  _iconFor(kind, isSelected),
                  const SizedBox(height: 4),
                  Text(
                    _labelFor(kind),
                    style: TextStyle(
                      fontSize: 11,
                      color: isSelected ? Colors.white : Colors.grey.shade700,
                    ),
                  ),
                ],
              );
            }).toList(),
      ),
    );
  }
}
