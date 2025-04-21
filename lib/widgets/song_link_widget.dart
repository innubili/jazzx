/*import 'package:flutter/material.dart';
import '../utils/utils.dart';
import '../models/link.dart';

class SongLinkWidget extends StatefulWidget {
  final String? link;
  final LinkKind? kind;
  final LinkCategory? category;
  final void Function(String link, LinkKind kind, LinkCategory category)
  onSaved;

  const SongLinkWidget({
    super.key,
    this.link,
    this.kind,
    this.category,
    required this.onSaved,
  });

  @override
  State<SongLinkWidget> createState() => _SongLinkWidgetState();
}

class _SongLinkWidgetState extends State<SongLinkWidget> {
  late TextEditingController _linkController;
  LinkCategory? _selectedCategory;
  LinkKind? _selectedKind;

  @override
  void initState() {
    super.initState();
    _linkController = TextEditingController(text: widget.link ?? '');
    _selectedKind = widget.kind;
    _selectedCategory = widget.category;
  }

  @override
  void dispose() {
    _linkController.dispose();
    super.dispose();
  }

  void _pickLocalFile() async {
    // TODO: Implement local file picker
    log.warning('\u{1F4C1} Pick local file (not implemented yet)');
  }

  void _openSearchScreen() async {
    if (_selectedCategory == null) return;

    final mockLink = await Navigator.push<String>(
      context,
      MaterialPageRoute(
        builder:
            (_) => Scaffold(
              appBar: AppBar(title: Text('Search ${_selectedCategory!.name}')),
              body: ListView(
                children: [
                  ListTile(
                    title: const Text('https://example.com/mock1'),
                    onTap:
                        () =>
                            Navigator.pop(context, 'https://example.com/mock1'),
                  ),
                  ListTile(
                    title: const Text('https://example.com/mock2'),
                    onTap:
                        () =>
                            Navigator.pop(context, 'https://example.com/mock2'),
                  ),
                ],
              ),
            ),
      ),
    );

    if (mockLink != null) {
      setState(() {
        _linkController.text = mockLink;
      });
    }
  }

  void _save() {
    final trimmedLink = _linkController.text.trim();
    if (trimmedLink.isEmpty ||
        _selectedKind == null ||
        _selectedCategory == null) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Please provide a link, kind, and category.'),
        ),
      );
      return;
    }

    widget.onSaved(trimmedLink, _selectedKind!, _selectedCategory!);
  }

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
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
              child: DropdownButtonFormField<LinkCategory>(
                value: _selectedCategory,
                decoration: const InputDecoration(
                  labelText: 'Category',
                  border: OutlineInputBorder(),
                ),
                items:
                    LinkCategory.values
                        .map(
                          (c) =>
                              DropdownMenuItem(value: c, child: Text(c.name)),
                        )
                        .toList(),
                onChanged: (val) => setState(() => _selectedCategory = val),
              ),
            ),
            const SizedBox(width: 8),
            Expanded(
              child: DropdownButtonFormField<LinkKind>(
                value: _selectedKind,
                decoration: const InputDecoration(
                  labelText: 'Kind',
                  border: OutlineInputBorder(),
                ),
                items:
                    LinkKind.values
                        .map(
                          (k) =>
                              DropdownMenuItem(value: k, child: Text(k.name)),
                        )
                        .toList(),
                onChanged: (val) => setState(() => _selectedKind = val),
              ),
            ),
          ],
        ),
        const SizedBox(height: 8),
        Row(
          children: [
            ElevatedButton.icon(
              icon: const Icon(Icons.search),
              label: const Text("Search Web"),
              onPressed: _openSearchScreen,
            ),
            const SizedBox(width: 8),
            ElevatedButton.icon(
              icon: const Icon(Icons.folder_open),
              label: const Text("Pick File"),
              onPressed: _pickLocalFile,
            ),
            const SizedBox(width: 8),
            ElevatedButton.icon(
              icon: const Icon(Icons.check),
              label: const Text("Done"),
              onPressed: _save,
            ),
          ],
        ),
      ],
    );
  }
}

*/
