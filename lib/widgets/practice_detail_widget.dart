import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../models/practice_category.dart';
import '../models/link.dart';
import '../providers/user_profile_provider.dart';
import '../providers/jazz_standards_provider.dart';
import 'song_line_widget.dart';
import 'song_picker_sheet.dart';
import 'multi_song_picker_sheet.dart';
import '../screens/link_search_screen.dart';

import 'link_widget.dart'; // Import LinkWidget
import 'link_editor_widgets.dart' show LinkConfirmationDialog;

class PracticeDetailWidget extends StatefulWidget {
  final PracticeCategory category;
  final String note;
  final List<String> songs;
  final int time;
  final List<Link> links;
  final ValueChanged<String> onNoteChanged;
  final ValueChanged<List<String>> onSongsChanged;
  final ValueChanged<int> onTimeChanged;
  final ValueChanged<List<Link>> onLinksChanged;

  const PracticeDetailWidget({
    super.key,
    required this.category,
    required this.note,
    required this.songs,
    required this.time,
    required this.onNoteChanged,
    required this.onSongsChanged,
    required this.onTimeChanged,
    this.links = const [],
    required this.onLinksChanged,
  });

  @override
  State<PracticeDetailWidget> createState() => _PracticeDetailWidgetState();
}

class _PracticeDetailWidgetState extends State<PracticeDetailWidget> {
  // Track which link viewers are open by link key
  final Set<String> _openViewers = {};

  void _handleOpenViewer(String key) {
    setState(() {
      _openViewers.add(key);
    });
  }

  void _handleCloseViewer(String key) {
    setState(() {
      _openViewers.remove(key);
    });
  }

  @override
  Widget build(BuildContext context) {
    final profileProvider = Provider.of<UserProfileProvider>(
      context,
      listen: false,
    );
    final standards =
        Provider.of<JazzStandardsProvider>(context, listen: false).standards;

    final selectedSong =
        widget.songs.isNotEmpty
            ? (profileProvider.profile?.songs[widget.songs.first] ??
                standards.firstWhere((s) => s.title == widget.songs.first))
            : null;

    return Padding(
      padding: const EdgeInsets.fromLTRB(
        8.0,
        8.0,
        16.0,
        16.0,
      ), // Reduced left/top padding
      child: SingleChildScrollView(
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            if (widget.category.allowsNote)
              _NoteTextField(
                note: widget.note,
                onNoteChanged: widget.onNoteChanged,
              ),
            if (widget.category.allowsNote) const SizedBox(height: 16),

            // Song Picker for newsong
            if (widget.category == PracticeCategory.newsong &&
                widget.category.allowsSongs)
              Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  if (selectedSong != null)
                    SongLineWidget(
                      song: selectedSong,
                      onIconPressed: (type) {
                        debugPrint(
                          "Pressed icon for $type on ${selectedSong.title}",
                        );
                        // _TODO: Handle actual action (e.g. launch link)
                      },
                    )
                  else
                    const Text("No song selected"),
                  const SizedBox(height: 8),
                  TextButton(
                    onPressed: () async {
                      final profile = profileProvider.profile;
                      final userSongTitles =
                          (profile?.songs.keys.toSet() ?? {})
                              .map((e) => e.trim().toLowerCase())
                              .toSet();
                      final selectedSongTitle =
                          await showModalBottomSheet<String>(
                            context: context,
                            isScrollControlled: true,
                            builder:
                                (context) => SongPickerSheet(
                                  bookmarkedTitles: userSongTitles,
                                ),
                          );
                      if (selectedSongTitle != null &&
                          selectedSongTitle.isNotEmpty) {
                        widget.onSongsChanged([selectedSongTitle]);
                      }
                    },
                    child: const Text("Choose Song"),
                  ),
                ],
              ),
            if (widget.category == PracticeCategory.newsong &&
                widget.category.allowsSongs)
              const SizedBox(height: 16),

            // Repertoire Multi Song Picker
            if (widget.category == PracticeCategory.repertoire &&
                widget.category.allowsSongs)
              Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  const Text(
                    "Repertoire Songs",
                    style: TextStyle(fontWeight: FontWeight.bold),
                  ),
                  if (widget.songs.isEmpty) const Text("No songs selected"),
                  ...widget.songs.map((s) => Text("• $s")),
                  TextButton(
                    onPressed: () async {
                      final selectedTitles =
                          await showModalBottomSheet<List<String>>(
                            context: context,
                            isScrollControlled: true,
                            builder:
                                (context) => MultiSongPickerSheet(
                                  initialSelection: widget.songs,
                                  onSongsSelected:
                                      (selected) =>
                                          Navigator.pop(context, selected),
                                ),
                          );

                      if (selectedTitles != null) {
                        widget.onSongsChanged(selectedTitles);
                      }
                    },
                    child: const Text("Select Songs"),
                  ),
                ],
              ),
            if (widget.category.allowsLinks)
              Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  const Text(
                    'Links',
                    style: TextStyle(fontWeight: FontWeight.bold),
                  ),
                  if (widget.links.isEmpty) const Text("No links added"),
                  ...widget.links.map(
                    (link) => LinkWidget(
                      link: link,
                      readOnly: false,
                      isViewerOpen: _openViewers.contains(link.key),
                      onOpenViewer: () => _handleOpenViewer(link.key),
                      onCloseViewer: () => _handleCloseViewer(link.key),
                      onUpdated: (updatedLink) {
                        final newLinks =
                            widget.links
                                .map(
                                  (l) =>
                                      l.key == updatedLink.key
                                          ? updatedLink
                                          : l,
                                )
                                .toList();
                        widget.onLinksChanged(newLinks);
                      },
                      onDelete: () {
                        final newLinks = List<Link>.from(widget.links)
                          ..remove(link);
                        widget.onLinksChanged(newLinks);
                      },
                      highlightQuery: null,
                    ),
                  ),
                  TextButton(
                    onPressed: () async {
                      final params =
                          practiceCategoryLinkSearchSchema[widget.category] ??
                          LinkSearchParams(
                            query: '',
                            initialKind: LinkKind.youtube,
                            initialCategory: LinkCategory.other,
                          );
                      final selectedLink = await Navigator.of(
                        context,
                      ).push<Link>(
                        MaterialPageRoute(
                          builder:
                              (ctx) => LinkSearchScreen(
                                query: params.query,
                                initialKind: params.initialKind,
                                initialCategory: params.initialCategory,
                                onSelected: (selected) {
                                  Navigator.pop(ctx, selected);
                                },
                              ),
                        ),
                      );
                      if (selectedLink != null) {
                        if (!mounted) return;
                        final confirmed = await showDialog<Link>(
                          context: this.context,
                          builder:
                              (_) => LinkConfirmationDialog(
                                initialLink: selectedLink,
                              ),
                        );
                        if (confirmed != null) {
                          if (!mounted) return;
                          final updatedLinks = [...widget.links, confirmed];
                          widget.onLinksChanged(updatedLinks);
                        }
                      }
                    },
                    child: const Text("Add Link"),
                  ),
                ],
              ),
            if (widget.category.allowsLinks) const SizedBox(height: 16),
          ],
        ),
      ),
    );
  }
}

class _NoteTextField extends StatefulWidget {
  final String note;
  final ValueChanged<String> onNoteChanged;
  const _NoteTextField({required this.note, required this.onNoteChanged});

  @override
  State<_NoteTextField> createState() => _NoteTextFieldState();
}

class _NoteTextFieldState extends State<_NoteTextField> {
  late final TextEditingController _controller;
  @override
  void initState() {
    super.initState();
    _controller = TextEditingController(text: widget.note);
    _controller.addListener(_handleChange);
  }

  @override
  void didUpdateWidget(covariant _NoteTextField oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (oldWidget.note != widget.note && _controller.text != widget.note) {
      _controller.value = TextEditingValue(
        text: widget.note,
        selection: TextSelection.collapsed(offset: widget.note.length),
      );
    }
  }

  void _handleChange() {
    if (_controller.text != widget.note) {
      widget.onNoteChanged(_controller.text);
    }
  }

  @override
  void dispose() {
    _controller.removeListener(_handleChange);
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return TextField(
      controller: _controller,
      decoration: const InputDecoration(labelText: "Note"),
    );
  }
}
