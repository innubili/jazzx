import 'package:flutter/material.dart';
import '../models/song.dart';
import '../widgets/song_link_widget.dart';

class SongDetailsScreen extends StatelessWidget {
  final Song song;

  const SongDetailsScreen({super.key, required this.song});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: Text(song.title)),
      body: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(song.title, style: Theme.of(context).textTheme.headlineLarge),
            const SizedBox(height: 8),
            Text('Key: ${song.key}'),
            Text('Form: ${song.form}'),
            Text('BPM: ${song.bpm}'),
            const SizedBox(height: 16),
            const Text('Links:', style: TextStyle(fontWeight: FontWeight.bold)),
            ...song.links.map((link) => SongLinkWidget(link: link)).toList(),
          ],
        ),
      ),
    );
  }
}