// FilePickerLauncher widget for selecting local files

import 'package:flutter/material.dart';
import 'package:file_picker/file_picker.dart';

class FilePickerLauncher extends StatelessWidget {
  final void Function(String path) onFilePicked;

  const FilePickerLauncher({super.key, required this.onFilePicked});

  Future<void> _pickFile(BuildContext context) async {
    final result = await FilePicker.platform.pickFiles();
    if (result != null && result.files.single.path != null) {
      onFilePicked(result.files.single.path!);
    } else {
      ScaffoldMessenger.of(
        context,
      ).showSnackBar(const SnackBar(content: Text('No file selected')));
    }
  }

  @override
  Widget build(BuildContext context) {
    return ElevatedButton.icon(
      icon: const Icon(Icons.folder_open),
      label: const Text('Select Local File'),
      onPressed: () => _pickFile(context),
    );
  }
}
