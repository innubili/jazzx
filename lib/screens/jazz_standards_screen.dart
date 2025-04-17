import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../widgets/song_browser_widget.dart';
import '../providers/jazz_standards_provider.dart';

class JazzStandardsScreen extends StatelessWidget {
  const JazzStandardsScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final standards = Provider.of<JazzStandardsProvider>(context).standards;

    return Scaffold(
      appBar: AppBar(title: const Text("Jazz Standards")),
      body: SongBrowserWidget(songs: standards, readOnly: true),
    );
  }
}
