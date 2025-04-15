import 'package:flutter/material.dart';
import '../widgets/song_browser_widget.dart';

class JazzStandardsScreen extends StatelessWidget {
  const JazzStandardsScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text("Jazz Standards")),
      body: SongBrowserWidget(mode: SongBrowserMode.standards),
    );
  }
}
