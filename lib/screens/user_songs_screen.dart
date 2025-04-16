import 'package:flutter/material.dart';
import '../widgets/song_browser_widget.dart';

class UserSongsScreen extends StatelessWidget {
  const UserSongsScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('My Songs')),
      body: const SongBrowserWidget(mode: SongBrowserMode.user),
    );
  }
}
