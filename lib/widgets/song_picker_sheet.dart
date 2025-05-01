import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../providers/jazz_standards_provider.dart';
import '../providers/user_profile_provider.dart';
import '../widgets/song_browser_widget.dart';
import '../utils/utils.dart';
import '../models/song.dart';

class SongPickerSheet extends StatelessWidget {
  final Set<String> bookmarkedTitles;

  const SongPickerSheet({super.key, required this.bookmarkedTitles});

  @override
  Widget build(BuildContext context) {
    final allSongs = Provider.of<JazzStandardsProvider>(context).standards;
    return FractionallySizedBox(
      heightFactor: 0.60,
      child: SafeArea(
        top: false,
        child: _SongPickerSheetContent(
          songs: allSongs,
          bookmarkedTitles: bookmarkedTitles,
        ),
      ),
    );
  }
}

class _SongPickerSheetContent extends StatefulWidget {
  final List<Song> songs;
  final Set<String> bookmarkedTitles;
  const _SongPickerSheetContent({
    required this.songs,
    required this.bookmarkedTitles,
  });

  @override
  State<_SongPickerSheetContent> createState() =>
      _SongPickerSheetContentState();
}

class _SongPickerSheetContentState extends State<_SongPickerSheetContent> {
  String _searchQuery = '';

  @override
  Widget build(BuildContext context) {
    final filtered =
        _searchQuery.isEmpty
            ? widget.songs
            : widget.songs.where((s) {
              final q = _searchQuery.toLowerCase();
              return s.title.toLowerCase().contains(q) ||
                  s.songwriters.toLowerCase().contains(q) ||
                  s.summary.toLowerCase().contains(q);
            }).toList();
    return Column(
      children: [
        const SizedBox(height: 8),
        Container(
          width: 40,
          height: 4,
          decoration: BoxDecoration(
            color: Colors.grey[400],
            borderRadius: BorderRadius.circular(2),
          ),
        ),
        const SizedBox(height: 8),
        AppBar(
          automaticallyImplyLeading: false,
          title: const Text('Pick a Song'),
          actions: [
            IconButton(
              icon: const Icon(Icons.close),
              tooltip: 'Cancel',
              onPressed: () => Navigator.pop(context),
            ),
          ],
        ),
        Padding(
          padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
          child: TextField(
            decoration: const InputDecoration(
              hintText: 'Search a jazz standard...',
              border: OutlineInputBorder(),
              prefixIcon: Icon(Icons.search),
            ),
            onChanged: (val) => setState(() => _searchQuery = val.trim()),
          ),
        ),
        Expanded(
          child: SongBrowserWidget(
            songs: filtered,
            readOnly: true,
            selectable: true,
            bookmarkedTitles: widget.bookmarkedTitles,
            onSelected: (song) async {
              final userProfileProvider = Provider.of<UserProfileProvider>(
                context,
                listen: false,
              );
              userProfileProvider.addSong(song);
              log.info('✅ Added to user songs: \x1b[1m${song.title}\x1b[0m');
              Navigator.pop(context, song.title);
            },
          ),
        ),
      ],
    );
  }
}
