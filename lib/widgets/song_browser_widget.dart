import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:flutter/gestures.dart';
import '../models/song.dart';
import '../providers/jazz_standards_provider.dart';
import '../providers/user_profile_provider.dart';
import 'song_widget.dart';

enum SongBrowserMode { standards, user }

typedef SongSelectedCallback = void Function(Song song);

class SongBrowserWidget extends StatefulWidget {
  final SongBrowserMode mode;
  final bool selectable;
  final SongSelectedCallback? onSelected;

  const SongBrowserWidget({
    super.key,
    required this.mode,
    this.selectable = false,
    this.onSelected,
  });

  @override
  State<SongBrowserWidget> createState() => _SongBrowserWidgetState();
}

class _SongBrowserWidgetState extends State<SongBrowserWidget> {
  String _searchQuery = '';
  String _sortField = 'title';
  bool _ascending = true;
  String? _expandedTitle;

  List<Song> _getSongs(BuildContext context) {
    if (widget.mode == SongBrowserMode.standards) {
      return Provider.of<JazzStandardsProvider>(
        context,
        listen: false,
      ).standards;
    } else {
      final userSongs =
          Provider.of<UserProfileProvider>(
            context,
            listen: false,
          ).profile?.songs;
      return userSongs?.values.toList() ?? [];
    }
  }

  List<Song> _filteredAndSortedSongs(List<Song> songs) {
    final filtered =
        songs
            .where(
              (s) =>
                  s.title.toLowerCase().contains(_searchQuery.toLowerCase()) ||
                  s.songwriters.toLowerCase().contains(
                    _searchQuery.toLowerCase(),
                  ),
            )
            .toList();

    filtered.sort((a, b) {
      final aValue = _getFieldValue(a);
      final bValue = _getFieldValue(b);
      return _ascending ? aValue.compareTo(bValue) : bValue.compareTo(aValue);
    });

    return filtered;
  }

  String _getFieldValue(Song song) {
    switch (_sortField) {
      case 'title':
        return song.title;
      case 'composer':
        return song.songwriters;
      case 'key':
        return song.key;
      case 'style':
        return song.type;
      default:
        return song.title;
    }
  }

  void _copySong(Song song) {
    final profile = Provider.of<UserProfileProvider>(context, listen: false);
    final copiedSong = song.copyWith(title: '${song.title} (Copy)');
    profile.addSong(copiedSong);
    setState(() => _expandedTitle = copiedSong.title);
  }

  void _deleteSong(Song song) async {
    final confirmed = await showDialog<bool>(
      context: context,
      builder:
          (context) => AlertDialog(
            title: const Text("Delete Song"),
            content: Text("Are you sure you want to delete '${song.title}'?"),
            actions: [
              TextButton(
                onPressed: () => Navigator.pop(context, false),
                child: const Text("Cancel"),
              ),
              ElevatedButton(
                onPressed: () => Navigator.pop(context, true),
                child: const Text("Delete"),
              ),
            ],
          ),
    );

    if (confirmed == true) {
      setState(() {
        final profile = Provider.of<UserProfileProvider>(
          context,
          listen: false,
        );
        profile.removeSong(song.title);
        _expandedTitle = null;
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    final songs = _filteredAndSortedSongs(_getSongs(context));

    return Column(
      children: [
        Padding(
          padding: const EdgeInsets.all(8.0),
          child: Row(
            children: [
              Expanded(
                child: TextField(
                  decoration: const InputDecoration(
                    labelText: 'Search songs...',
                  ),
                  onChanged: (val) => setState(() => _searchQuery = val),
                ),
              ),
              const SizedBox(width: 8),
              DropdownButton<String>(
                value: _sortField,
                items: const [
                  DropdownMenuItem(value: 'title', child: Text('Title')),
                  DropdownMenuItem(value: 'composer', child: Text('Composer')),
                  DropdownMenuItem(value: 'key', child: Text('Key')),
                  DropdownMenuItem(value: 'style', child: Text('Style')),
                ],
                onChanged: (val) => setState(() => _sortField = val ?? 'title'),
              ),
              IconButton(
                icon: Icon(
                  _ascending ? Icons.arrow_upward : Icons.arrow_downward,
                ),
                onPressed: () => setState(() => _ascending = !_ascending),
              ),
            ],
          ),
        ),
        Expanded(
          child: ListView.builder(
            itemCount: songs.length,
            itemBuilder: (context, index) {
              final song = songs[index];
              return Card(
                child: ExpansionTile(
                  key: PageStorageKey(song.title),
                  title: Text(song.title),
                  subtitle: Text(
                    '${song.songwriters} (${song.year}) • ${song.key} • ${song.type} • ${song.form} • ${song.bpm} BPM',
                  ),
                  initiallyExpanded: _expandedTitle == song.title,
                  onExpansionChanged: (expanded) {
                    setState(() {
                      _expandedTitle = expanded ? song.title : null;
                    });
                  },
                  children: [
                    ScrollConfiguration(
                      behavior: ScrollConfiguration.of(context).copyWith(
                        scrollbars: false,
                        overscroll: false,
                        dragDevices: {
                          PointerDeviceKind.touch,
                          PointerDeviceKind.mouse,
                        },
                      ),
                      child: SongWidget(
                        song: song,
                        onUpdated:
                            (updated) => Provider.of<UserProfileProvider>(
                              context,
                              listen: false,
                            ).updateSong(updated),
                        onCopy: () => _copySong(song),
                        onDelete: () => _deleteSong(song),
                      ),
                    ),
                  ],
                ),
              );
            },
          ),
        ),
      ],
    );
  }
}
