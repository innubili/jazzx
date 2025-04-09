import 'package:flutter/material.dart';
import '../models/song.dart';
import '../screens/song_details_screen.dart';

class SongWidget extends StatelessWidget {
  final Song song;

  const SongWidget({super.key, required this.song});

  @override
  Widget build(BuildContext context) {
    return ListTile(
      title: Text(song.title),
      subtitle: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text('Key: ${song.key}'),
          Text('Form: ${song.form}'),
          Text('BPM: ${song.bpm}'),
        ],
      ),
      onTap: () {
        Navigator.push(
          context,
          MaterialPageRoute(
            builder: (_) => SongDetailsScreen(song: song),
          ),
        );
      },
    );
  }
}
