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
import '../models/song.dart';
// import 'song_details_screen.dart';

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
    allSongs.sort(
      (a, b) => a.title.toLowerCase().compareTo(b.title.toLowerCase()),
    );
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
          IconButton(
            icon: const Icon(Icons.note_add),
            tooltip: 'Create new song',
            onPressed: () async {
              final profileProvider = Provider.of<UserProfileProvider>(
                context,
                listen: false,
              );
              final standards =
                  Provider.of<JazzStandardsProvider>(
                    context,
                    listen: false,
                  ).standards;
              final userSongs = profileProvider.profile?.songs ?? {};

              await showDialog(
                context: context,
                builder: (context) {
                  final controller = TextEditingController();
                  String? errorText;
                  bool isValid = false;
                  return StatefulBuilder(
                    builder: (context, setState) {
                      void validate(String value) {
                        final trimmed = value.trim();
                        final lower = trimmed.toLowerCase();
                        final exists =
                            userSongs.keys
                                .map((k) => k.trim().toLowerCase())
                                .contains(lower) ||
                            standards.any(
                              (s) => s.title.trim().toLowerCase() == lower,
                            );
                        if (trimmed.isEmpty) {
                          errorText = 'Title required';
                          isValid = false;
                        } else if (exists) {
                          errorText = 'Title already exists';
                          isValid = false;
                        } else {
                          errorText = null;
                          isValid = true;
                        }
                      }

                      validate(controller.text);
                      return AlertDialog(
                        title: const Text('Create New Song'),
                        content: TextField(
                          controller: controller,
                          autofocus: true,
                          decoration: InputDecoration(
                            labelText: 'Song Title',
                            errorText: errorText,
                          ),
                          onChanged: (value) {
                            setState(() {
                              validate(value);
                            });
                          },
                        ),
                        actions: [
                          TextButton(
                            child: const Text('Cancel'),
                            onPressed: () => Navigator.of(context).pop(),
                          ),
                          ElevatedButton(
                            onPressed:
                                isValid
                                    ? () {
                                      final trimmed = controller.text.trim();
                                      final now =
                                          DateTime.now()
                                              .toUtc()
                                              .millisecondsSinceEpoch ~/
                                          1000;
                                      final newSong = Song.getDefault(
                                        trimmed,
                                      ).copyWith(added: now);
                                      profileProvider.addSong(newSong);
                                      Navigator.of(context).pop();
                                      setState(() {
                                        _searchQuery = '';
                                      });
                                      WidgetsBinding.instance
                                          .addPostFrameCallback((_) {
                                            Navigator.of(
                                              context,
                                            ).pushReplacement(
                                              MaterialPageRoute(
                                                builder:
                                                    (_) => UserSongsScreen(),
                                                settings: RouteSettings(
                                                  arguments: {
                                                    'initialScrollToTitle':
                                                        trimmed,
                                                    'expandInitially': true,
                                                  },
                                                ),
                                              ),
                                            );
                                          });
                                    }
                                    : null,
                            child: const Text('Create'),
                          ),
                        ],
                      );
                    },
                  );
                },
              );
            },
          ),
          IconButton(
            icon: const Icon(Icons.add),
            tooltip: 'Add song from standards',
            onPressed: () async {
              final profile = profileProvider.profile;
              final selectedSongTitle = await showModalBottomSheet<String>(
                context: context,
                isScrollControlled: true,
                builder:
                    (context) => SongPickerSheet(bookmarkedTitles: <String>{}),
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
    );
  }
}
