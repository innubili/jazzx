// This is the updated LinkWidget implementation with:
// 1. Narrow Key field
// 2. Segmented category buttons
// 3. Two search buttons on right of the link input

import 'package:flutter/material.dart';
import 'package:flutter_svg/flutter_svg.dart';
import '../models/link.dart';

class LinkCategoryPicker extends StatelessWidget {
  final String selected;
  final ValueChanged<String> onChanged;

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
      default:
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
      default:
        return 'Other';
    }
  }

  @override
  Widget build(BuildContext context) {
    final categories = LinkCategory.values;
    final selectedIndex = categories.indexWhere((cat) => cat.name == selected);

    return Center(
      child: ToggleButtons(
        borderRadius: BorderRadius.circular(8),
        isSelected: List.generate(categories.length, (i) => i == selectedIndex),
        onPressed: (index) => onChanged(categories[index].name),
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

class LinkUrlFieldWithButtons extends StatelessWidget {
  final String value;
  final ValueChanged<String> onChanged;
  final VoidCallback onWebSearch;
  final VoidCallback onFilePick;

  const LinkUrlFieldWithButtons({
    super.key,
    required this.value,
    required this.onChanged,
    required this.onWebSearch,
    required this.onFilePick,
  });

  @override
  Widget build(BuildContext context) {
    return Row(
      children: [
        Expanded(
          child: TextFormField(
            initialValue: value,
            decoration: const InputDecoration(labelText: 'URL or File'),
            onChanged: onChanged,
          ),
        ),
        IconButton(
          icon: const Icon(Icons.search),
          tooltip: 'Search Web',
          onPressed: onWebSearch,
        ),
        IconButton(
          icon: const Icon(Icons.folder_open),
          tooltip: 'Pick Local File',
          onPressed: onFilePick,
        ),
      ],
    );
  }
}
