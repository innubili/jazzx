import 'package:flutter/material.dart';
import '../models/link.dart';
import 'link_editor_widgets.dart';
import 'package:url_launcher/url_launcher.dart';

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

    // Remove any trailing site:... or OR site:... from the text
    final base = controller.text
        .replaceAll(RegExp(r'(site:[^ ]+|OR site:[^ ]+)', caseSensitive: false), '')
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

  void _handleKindChange(BuildContext context, Set<LinkKind> kinds) {
    final kind = kinds.first;
    // Prepare the query
    final query = controller.text.trim();
    // Launch external app or picker based on kind
    switch (kind) {
      case LinkKind.youtube:
        _launchExternalApp(context, 'https://www.youtube.com/results?search_query=${Uri.encodeComponent(query)}');
        break;
      case LinkKind.spotify:
        _launchExternalApp(context, 'spotify:search:${Uri.encodeComponent(query)}');
        break;
      case LinkKind.media:
        _launchFilePicker(context);
        break;
      // Add other kinds as needed
      default:
        break;
    }
    // Optionally keep updating selectedKinds if needed
    onKindsChanged(kinds);
  }

  void _launchExternalApp(BuildContext context, String url) async {
    // Uses url_launcher (already in pubspec.yaml)
    try {
      final uri = Uri.parse(url);
      // ignore: use_build_context_synchronously
      if (!await canLaunchUrl(uri)) {
        if (!context.mounted) return;
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Could not launch external app.')),
        );
        return;
      }
      await launchUrl(uri, mode: LaunchMode.externalApplication);
    } catch (e) {
      if (!context.mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Failed to launch: $e')),
      );
    }
  }

  void _launchFilePicker(BuildContext context) async {
    // TODO: file_picker is commented out in pubspec.yaml. Uncomment it and run `flutter pub get` to enable file picking.
    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(content: Text('File picker is not enabled. Please enable file_picker in pubspec.yaml.')),
    );
    // Example code if file_picker is enabled:
    // import 'package:file_picker/file_picker.dart';
    // try {
    //   final result = await FilePicker.platform.pickFiles();
    //   if (result != null && result.files.isNotEmpty) {
    //     // Handle the picked file
    //     final file = result.files.first;
    //     // Do something with file.path
    //   }
    // } catch (e) {
    //   ScaffoldMessenger.of(context).showSnackBar(
    //     SnackBar(content: Text('Failed to pick file: $e')),
    //   );
    // }
  }

  @override
  Widget build(BuildContext context) {
    final allowedKinds = _allowedKindsFor(selectedCategory);
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
                  onSubmitted: onQueryChanged,
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
          LinkKindPicker(
          selected: selectedKinds,
          onChanged: (kinds) => _handleKindChange(context, kinds),
          allowedKinds: allowedKinds,
        ),
        ],
      ),
    );
  }
}
