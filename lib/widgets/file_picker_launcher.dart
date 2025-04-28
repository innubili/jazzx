// FilePickerLauncher widget for selecting local files

import 'package:flutter/material.dart';
// import 'package:file_picker/file_picker.dart';

class FilePickerLauncher extends StatefulWidget {
  final void Function(String path) onFilePicked;

  const FilePickerLauncher({super.key, required this.onFilePicked});

  @override
  State<FilePickerLauncher> createState() => _FilePickerLauncherState();
}

class _FilePickerLauncherState extends State<FilePickerLauncher> {
  Future<void> _pickFile() async {
    // final result = await FilePicker.platform.pickFiles();
    // if (!mounted) return;

    // if (result != null && result.files.single.path != null) {
    //   widget.onFilePicked(result.files.single.path!);
    // } else {
    //   ScaffoldMessenger.of(
    //     context,
    //   ).showSnackBar(const SnackBar(content: Text('No file selected')));
    // }
  }

  @override
  Widget build(BuildContext context) {
    return ElevatedButton.icon(
      icon: const Icon(Icons.folder_open),
      label: const Text('Select Local File'),
      onPressed: _pickFile,
    );
  }
}
