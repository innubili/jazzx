import 'package:flutter/material.dart';
import '../models/link.dart';
import 'link_editor_widgets.dart';

class SearchBarWidget extends StatelessWidget {
  final TextEditingController controller;
  final ValueChanged<String> onQueryChanged;
  final VoidCallback onClear;
  final LinkCategory selectedCategory;
  final ValueChanged<LinkCategory> onCategoryChanged;
  final Set<LinkKind> selectedKinds;
  final ValueChanged<Set<LinkKind>> onKindsChanged;

  const SearchBarWidget({
    super.key,
    required this.controller,
    required this.onQueryChanged,
    required this.onClear,
    required this.selectedCategory,
    required this.onCategoryChanged,
    required this.selectedKinds,
    required this.onKindsChanged,
  });

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
      default:
        return '';
    }
  }

  Set<LinkKind> _allowedKindsFor(LinkCategory category) {
    switch (category) {
      case LinkCategory.backingTrack:
        return LinkKind.values.toSet();
      case LinkCategory.playlist:
        return {LinkKind.youtube, LinkKind.spotify};
      case LinkCategory.lesson:
        return {LinkKind.youtube, LinkKind.media};
      case LinkCategory.scores:
        return {LinkKind.media};
      case LinkCategory.other:
        return {LinkKind.media};
    }
  }

  void _handleCategoryChange(BuildContext context, LinkCategory category) {
    onCategoryChanged(category);
    final allowed = _allowedKindsFor(category);
    onKindsChanged(allowed);

    final base =
        controller.text
            .split(
              RegExp(
                r'(backing track|playlist|lesson|sheet music)',
                caseSensitive: false,
              ),
            )[0]
            .trim();
    final updated = '$base ${_categorySuffix(category)}'.trim();
    controller.text = updated;
    onQueryChanged(updated);
  }

  void _handleKindChange(Set<LinkKind> kinds) {
    onKindsChanged(kinds);
  }

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.all(12),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Expanded(
                child: TextField(
                  controller: controller,
                  onChanged: onQueryChanged,
                  decoration: InputDecoration(
                    labelText: 'Search...',
                    suffixIcon: IconButton(
                      icon: const Icon(Icons.clear),
                      onPressed: onClear,
                    ),
                    border: const OutlineInputBorder(),
                  ),
                ),
              ),
            ],
          ),
          const SizedBox(height: 12),
          Text('Category:', style: Theme.of(context).textTheme.labelLarge),
          const SizedBox(height: 4),
          LinkCategoryPicker(
            selected: selectedCategory,
            onChanged: (val) => _handleCategoryChange(context, val),
          ),
          const SizedBox(height: 12),
          Text('Sources:', style: Theme.of(context).textTheme.labelLarge),
          const SizedBox(height: 4),
          LinkKindPicker(selected: selectedKinds, onChanged: _handleKindChange),
        ],
      ),
    );
  }
}
