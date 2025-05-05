import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../models/song.dart';
import '../models/link.dart';
import '../providers/user_profile_provider.dart';

import 'song_widget.dart';

typedef SongSelectedCallback = void Function(Song song);

class SongBrowserWidget extends StatefulWidget {
  final List<Song> songs;
  final bool readOnly;
  final bool selectable;
  final SongSelectedCallback? onSelected;
  final bool showDeleted;
  final LinkKind? addLinkForKind; // new param
  final Set<String>? bookmarkedTitles;

  // New: optional scroll/expand
  final String? initialScrollToTitle;
  final bool expandInitially;

  const SongBrowserWidget({
    super.key,
    required this.songs,
    this.readOnly = false,
    this.selectable = false,
    this.onSelected,
    this.showDeleted = false,
    this.initialScrollToTitle,
    this.expandInitially = false,
    this.addLinkForKind, // new param
    this.bookmarkedTitles,
  });

  @override
  State<SongBrowserWidget> createState() => _SongBrowserWidgetState();
}

class _SongBrowserWidgetState extends State<SongBrowserWidget> {
  final _scrollController = ScrollController();
  final _itemKeys = <String, GlobalKey>{};

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) => _scrollToInitialSong());
  }

  void _scrollToInitialSong() {
    if (widget.initialScrollToTitle == null) return;
    final key = _itemKeys[widget.initialScrollToTitle!];
    if (key?.currentContext != null) {
      Scrollable.ensureVisible(
        key!.currentContext!,
        duration: const Duration(milliseconds: 500),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    final songs = widget.showDeleted
        ? widget.songs
        : widget.songs.where((s) => !s.deleted).toList();

    return ListView.builder(
      controller: _scrollController,
      itemCount: songs.length,
      itemBuilder: (context, index) {
        final song = songs[index];
        final key = _itemKeys.putIfAbsent(song.title, () => GlobalKey());
        return Card(
          key: key,
          margin: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
          child: Padding(
            padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
            child: SongWidget(
              song: song,
              highlightQuery: '', // No highlight, search handled by parent
              readOnly: widget.readOnly,
              selectable: widget.selectable,
              onSelected: widget.onSelected != null ? () => widget.onSelected!(song) : null,
              addLinkForKind: widget.addLinkForKind,
              initiallyExpanded: widget.initialScrollToTitle == song.title && widget.expandInitially,
              onUpdated: (updatedSong) {
                // Save song changes to Firebase via provider
                final userProfileProvider = Provider.of<UserProfileProvider>(context, listen: false);
                userProfileProvider.updateSong(updatedSong);
              },
              onCopy: () {},
              onDelete: () {},
              leading: widget.bookmarkedTitles != null &&
                      widget.bookmarkedTitles!.contains(song.title.trim().toLowerCase())
                  ? const Icon(Icons.bookmark, color: Colors.amber)
                  : null,
            ),
          ),
        );
      },
    );
  }
}
