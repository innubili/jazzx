import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../models/song.dart';
import '../providers/user_profile_provider.dart';
import '../widgets/song_widget.dart';

class UserSongsScreen extends StatelessWidget {
  const UserSongsScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final profile = Provider.of<UserProfileProvider>(context);
    final firstSong = profile.profile?.songs.values.first;

    if (firstSong == null) {
      return const Center(child: Text("No songs available."));
    }

    return Scaffold(
      appBar: AppBar(title: const Text("My Songs")),
      body: SongWidget(
        song: firstSong,
        onUpdated: (updated) => profile.updateSong(updated),
        onCopy:
            () => profile.addSong(
              firstSong.copyWith(title: "${firstSong.title} (Copy)"),
            ),
        onDelete: () => profile.removeSong(firstSong.title),
      ),
    );
  }
}
