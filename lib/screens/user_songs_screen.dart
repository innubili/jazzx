import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../widgets/song_browser_widget.dart';
import '../providers/user_profile_provider.dart';

class UserSongsScreen extends StatelessWidget {
  const UserSongsScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final songs =
        Provider.of<UserProfileProvider>(
          context,
        ).profile?.songs.values.where((s) => !s.deleted).toList() ??
        [];

    return Scaffold(
      appBar: AppBar(title: const Text('My Songs')),
      body: SongBrowserWidget(
        songs: songs,
        readOnly: false,
        showDeleted: false,
      ),
    );
  }
}
