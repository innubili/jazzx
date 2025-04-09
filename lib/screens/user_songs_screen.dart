import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../providers/user_songs_provider.dart';
import '../widgets/song_widget.dart';

class UserSongsScreen extends StatelessWidget {
  const UserSongsScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text("My Songs")),
      body: Consumer<UserSongsProvider>(
        builder: (context, provider, _) {
          if (provider.songs.isEmpty) {
            return const Center(child: CircularProgressIndicator());
          }

          return ListView.builder(
            itemCount: provider.songs.length,
            itemBuilder: (context, index) {
              final song = provider.songs[index];
              return SongWidget(song: song);
            },
          );
        },
      ),
    );
  }
}