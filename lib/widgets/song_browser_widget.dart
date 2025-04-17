import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../models/song.dart';
import '../providers/user_profile_provider.dart';
import 'song_widget.dart';

typedef SongSelectedCallback = void Function(Song song);

class SongBrowserWidget extends StatefulWidget {
  final List<Song> songs;
  final bool readOnly;
  final bool selectable;
  final SongSelectedCallback? onSelected;
  final bool showDeleted;

  const SongBrowserWidget({
    super.key,
    required this.songs,
    this.readOnly = false,
    this.selectable = false,
    this.onSelected,
    this.showDeleted = false,
  });

  @override
  State<SongBrowserWidget> createState() => _SongBrowserWidgetState();
}

class _SongBrowserWidgetState extends State<SongBrowserWidget> {
  String _searchQuery = '';
  String _sortField = 'title';
  bool _ascending = true;

  List<Song> _filteredAndSortedSongs(List<Song> songs) {
    final query = _searchQuery.toLowerCase();

    final filtered =
        songs.where((s) {
          final inTitle = s.title.toLowerCase().contains(query);
          final inSummary = s.summary.toLowerCase().contains(query);
          return inTitle || inSummary;
        }).toList();

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

  @override
  Widget build(BuildContext context) {
    final profile = Provider.of<UserProfileProvider>(context, listen: false);

    final songs = _filteredAndSortedSongs(
      widget.showDeleted
          ? widget.songs
          : widget.songs.where((s) => !s.deleted).toList(),
    );

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
                  onChanged: (val) => setState(() => _searchQuery = val.trim()),
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
                key: ValueKey(song.title),
                margin: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                child: Padding(
                  padding: const EdgeInsets.symmetric(
                    horizontal: 12,
                    vertical: 8,
                  ),
                  child: SongWidget(
                    song: song,
                    highlightQuery: _searchQuery,
                    readOnly: widget.readOnly,
                    selectable: widget.selectable,
                    onSelected:
                        widget.onSelected != null
                            ? () => widget.onSelected!(song)
                            : null,
                    onUpdated:
                        widget.readOnly
                            ? (_) {}
                            : (updated) => profile.updateSong(updated),
                    onCopy:
                        widget.readOnly
                            ? () {}
                            : () {
                              final copied = song.copyWith(
                                title: "${song.title} (copy)",
                              );
                              profile.addSong(copied);
                            },
                    onDelete:
                        widget.readOnly
                            ? () {}
                            : () {
                              final updated = song.copyWith(deleted: true);
                              profile.updateSong(updated);
                            },
                  ),
                ),
              );
            },
          ),
        ),
        if (!widget.readOnly)
          Padding(
            padding: const EdgeInsets.symmetric(vertical: 8),
            child: TextButton.icon(
              icon: Icon(
                widget.showDeleted ? Icons.visibility_off : Icons.visibility,
              ),
              label: Text(
                widget.showDeleted
                    ? 'Hide deleted songs'
                    : 'Show deleted songs',
              ),
              onPressed: () => setState(() {}),
            ),
          ),
      ],
    );
  }
}
