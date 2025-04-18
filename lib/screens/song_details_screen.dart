import 'package:flutter/material.dart';
import 'package:url_launcher/url_launcher.dart';
import '../models/song.dart';

class SongDetailsScreen extends StatelessWidget {
  final Song song;

  const SongDetailsScreen({super.key, required this.song});

  void _openLink(BuildContext context, String url) async {
    final uri = Uri.tryParse(url);
    if (uri != null && await canLaunchUrl(uri)) {
      await launchUrl(uri);
    } else {
      ScaffoldMessenger.of(
        context,
      ).showSnackBar(const SnackBar(content: Text('Could not open link')));
    }
  }

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
            ...song.links.map(
              (link) => ListTile(
                title: Text(link.name),
                subtitle: Text(link.category),
                trailing: IconButton(
                  icon: const Icon(Icons.open_in_new),
                  onPressed: () => _openLink(context, link.link),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}
