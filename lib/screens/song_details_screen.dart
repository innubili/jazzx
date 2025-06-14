import 'package:flutter/material.dart';
import 'package:url_launcher/url_launcher.dart';
import '../models/song.dart';
import '../widgets/main_drawer.dart';
import '../widgets/song_widget.dart'; // Assuming SongWidget is in this file

class SongDetailsScreen extends StatefulWidget {
  final Song song;
  final bool editMode;

  const SongDetailsScreen({
    super.key,
    required this.song,
    this.editMode = false,
  });

  @override
  State<SongDetailsScreen> createState() => _SongDetailsScreenState();
}

class _SongDetailsScreenState extends State<SongDetailsScreen> {
  bool _editMode = false;

  @override
  void initState() {
    super.initState();
    _editMode = widget.editMode;
  }

  Future<void> _openLink(String url) async {
    final uri = Uri.tryParse(url);
    if (uri != null && await canLaunchUrl(uri)) {
      await launchUrl(uri);
    } else if (mounted) {
      ScaffoldMessenger.of(
        context,
      ).showSnackBar(const SnackBar(content: Text('Could not open link')));
    }
  }

  @override
  Widget build(BuildContext context) {
    final song = widget.song;

    return Scaffold(
      appBar: AppBar(
        title: Text(song.title),
        leading: Builder(
          builder:
              (context) => IconButton(
                icon: const Icon(Icons.menu),
                tooltip: 'Open navigation menu',
                onPressed: () => Scaffold.of(context).openDrawer(),
              ),
        ),
      ),
      drawer: const MainDrawer(),
      body: Padding(
        padding: const EdgeInsets.all(16),
        child:
            _editMode
                ? SongWidget(
                  song: widget.song,
                  onUpdated: (updated) {},
                  onCopy: () {},
                  onDelete: () {},
                  readOnly: false,
                  initiallyExpanded: true,
                )
                : Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      song.title,
                      style: Theme.of(context).textTheme.headlineLarge,
                    ),
                    const SizedBox(height: 8),
                    Text('Key: ${song.key}'),
                    Text('Form: ${song.form}'),
                    Text('BPM: ${song.bpm}'),
                    const SizedBox(height: 16),
                    const Text(
                      'Links:',
                      style: TextStyle(fontWeight: FontWeight.bold),
                    ),
                    ...song.links.map(
                      (link) => ListTile(
                        title: Text(link.name),
                        subtitle: Text(link.category.name),
                        trailing: IconButton(
                          icon: const Icon(Icons.open_in_new),
                          onPressed: () => _openLink(link.link),
                        ),
                      ),
                    ),
                  ],
                ),
      ),
    );
  }
}
