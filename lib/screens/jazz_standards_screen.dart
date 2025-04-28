import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../widgets/song_browser_widget.dart';
import '../providers/jazz_standards_provider.dart';
import '../providers/user_profile_provider.dart';
import '../widgets/main_drawer.dart';
import '../widgets/search_app_bar.dart';

class JazzStandardsScreen extends StatefulWidget {
  const JazzStandardsScreen({super.key});

  @override
  State<JazzStandardsScreen> createState() => _JazzStandardsScreenState();
}

class _JazzStandardsScreenState extends State<JazzStandardsScreen> {
  String _searchQuery = '';

  @override
  Widget build(BuildContext context) {
    final standards = Provider.of<JazzStandardsProvider>(context).standards;
    final userSongs = Provider.of<UserProfileProvider>(context).profile?.songs.keys
        .map((e) => e.trim().toLowerCase())
        .toSet() ?? {};
    final filtered = _searchQuery.isEmpty
        ? standards
        : standards.where((s) {
            final q = _searchQuery.toLowerCase();
            return s.title.toLowerCase().contains(q) ||
                s.songwriters.toLowerCase().contains(q) ||
                s.summary.toLowerCase().contains(q);
          }).toList();

    return Scaffold(
      appBar: SearchAppBar(
        title: 'Jazz Standards',
        searchHint: 'Search a jazz standard...',
        onSearchChanged: (query) {
          setState(() => _searchQuery = query);
        },
      ),
      body: SongBrowserWidget(
        songs: filtered,
        readOnly: true,
        bookmarkedTitles: userSongs,
      ),
      drawer: const MainDrawer(),
    );
  }
}
