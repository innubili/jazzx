import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../providers/jazz_standards_provider.dart';
import '../widgets/song_browser_widget.dart';
import '../providers/user_profile_provider.dart';
import '../widgets/song_picker_sheet.dart';
import '../utils/utils.dart';
import '../models/link.dart';
import '../widgets/search_app_bar.dart';
import '../widgets/main_drawer.dart'; // Import the MainDrawer widget

class UserSongsScreen extends StatefulWidget {
  const UserSongsScreen({super.key});

  @override
  State<UserSongsScreen> createState() => _UserSongsScreenState();
}

class _UserSongsScreenState extends State<UserSongsScreen> {
  String _searchQuery = '';

  _onSongsChanged(List<String> songs) {
    // Handle the song changes here
    debugPrint('songlist: $songs');
  }

  @override
  Widget build(BuildContext context) {
    final args =
        ModalRoute.of(context)?.settings.arguments as Map<String, dynamic>?;

    final initialScrollToTitle = args?['initialScrollToTitle'] as String?;
    final expandInitially = args?['expandInitially'] as bool? ?? false;
    final addLinkForKindStr = args?['addLinkForKind'] as String?;
    final addLinkForKind = enumFromString(addLinkForKindStr, LinkKind.values);

    final profileProvider = Provider.of<UserProfileProvider>(context);
    final profile = profileProvider.profile;
    final allSongs =
        profile?.songs.values.where((s) => !s.deleted).toList() ?? [];
    final standards =
        Provider.of<JazzStandardsProvider>(context, listen: false).standards;

    final filtered =
        _searchQuery.isEmpty
            ? allSongs
            : allSongs.where((s) {
              final q = _searchQuery.toLowerCase();
              return s.title.toLowerCase().contains(q) ||
                  s.songwriters.toLowerCase().contains(q) ||
                  s.summary.toLowerCase().contains(q);
            }).toList();

    return Scaffold(
      appBar: SearchAppBar(
        title: 'My Songs',
        searchHint: 'Search a song...',
        onSearchChanged: (query) {
          setState(() => _searchQuery = query);
        },
        actions: [
          Builder(
            builder:
                (context) => IconButton(
                  icon: const Icon(Icons.menu),
                  tooltip: 'Open navigation menu',
                  onPressed: () => Scaffold.of(context).openDrawer(),
                ),
          ),
        ],
      ),
      drawer: const MainDrawer(),
      body: SongBrowserWidget(
        songs: filtered,
        readOnly: false,
        showDeleted: false,
        initialScrollToTitle: initialScrollToTitle,
        expandInitially: expandInitially,
        addLinkForKind: addLinkForKind,
      ),
      floatingActionButton: FloatingActionButton(
        tooltip: 'Add New Song',
        shape: const CircleBorder(),
        onPressed: () async {
          final profile = profileProvider.profile;
          final excludeTitles = profile?.songs.keys.toList() ?? [];

          final selectedSongTitle = await showModalBottomSheet<String>(
            context: context,
            isScrollControlled: true,
            builder:
                (context) => SongPickerSheet(
                  // excludeTitles: excludeTitles,
                  bookmarkedTitles: <String>{},
                ),
          );

          if (selectedSongTitle == null) return;

          final isNotInUserSongs =
              profile?.songs.containsKey(selectedSongTitle) == false;

          if (isNotInUserSongs) {
            final selected = standards.firstWhere(
              (s) => s.title == selectedSongTitle,
            );
            profileProvider.addSong(selected.copyWith());
          }

          _onSongsChanged([selectedSongTitle]);
        },
        child: const Icon(Icons.add),
      ),
    );
  }
}
