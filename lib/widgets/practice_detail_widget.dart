import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../models/practice_category.dart';
import '../providers/user_profile_provider.dart';
import '../providers/jazz_standards_provider.dart';
import 'song_line_widget.dart';
import 'song_picker_sheet.dart';
import 'multi_song_picker_sheet.dart';
import 'time_picker_wheel.dart';

class PracticeDetailWidget extends StatelessWidget {
  final PracticeCategory category;
  final String note;
  final List<String> songs;
  final int time;
  final List<String> links;
  final ValueChanged<String> onNoteChanged;
  final ValueChanged<List<String>> onSongsChanged;
  final ValueChanged<int> onTimeChanged;
  final ValueChanged<List<String>> onLinksChanged;

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
  Widget build(BuildContext context) {
    final profileProvider = Provider.of<UserProfileProvider>(
      context,
      listen: false,
    );
    final standards =
        Provider.of<JazzStandardsProvider>(context, listen: false).standards;

    final selectedSong =
        songs.isNotEmpty
            ? (profileProvider.profile?.songs[songs.first] ??
                standards.firstWhere((s) => s.title == songs.first))
            : null;

    return Padding(
      padding: const EdgeInsets.all(16.0),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              const Text('Time:'),
              const SizedBox(width: 8),
              TimePickerDropdown(
                initialSeconds: time,
                onChanged: onTimeChanged,
              ),
            ],
          ),
          const SizedBox(height: 16),
          if (category.allowsNote)
            _NoteTextField(note: note, onNoteChanged: onNoteChanged),
          if (category.allowsNote) const SizedBox(height: 16),

          if (category.allowsLinks)
            _LinksField(
              links: links,
              onLinksChanged: onLinksChanged,
            ),
          if (category.allowsLinks) const SizedBox(height: 16),

          // Song Picker for newsong
          if (category == PracticeCategory.newsong && category.allowsSongs)
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
                    final userSongTitles = (profile?.songs.keys.toSet() ?? {}).map((e) => e.trim().toLowerCase()).toSet();
                    final selectedSongTitle =
                        await showModalBottomSheet<String>(
                          context: context,
                          isScrollControlled: true,
                          builder:
                              (context) => SongPickerSheet(bookmarkedTitles: userSongTitles),
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

                    onSongsChanged([selectedSongTitle]);
                  },
                  child: const Text("Choose Song"),
                ),
              ],
            ),
          // Repertoire Multi Song Picker
          if (category == PracticeCategory.repertoire && category.allowsSongs)
            Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const Text(
                  "Repertoire Songs",
                  style: TextStyle(fontWeight: FontWeight.bold),
                ),
                if (songs.isEmpty) const Text("No songs selected"),
                ...songs.map((s) => Text("• $s")),
                TextButton(
                  onPressed: () async {
                    final selectedTitles =
                        await showModalBottomSheet<List<String>>(
                          context: context,
                          isScrollControlled: true,
                          builder:
                              (context) => MultiSongPickerSheet(
                                initialSelection: songs,
                                onSongsSelected:
                                    (selected) =>
                                        Navigator.pop(context, selected),
                              ),
                        );

                    if (selectedTitles != null) {
                      onSongsChanged(selectedTitles);
                    }
                  },
                  child: const Text("Select Songs"),
                ),
              ],
            ),
        ],
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

class _LinksField extends StatelessWidget {
  final List<String> links;
  final ValueChanged<List<String>> onLinksChanged;
  const _LinksField({required this.links, required this.onLinksChanged});

  @override
  Widget build(BuildContext context) {
    final controller = TextEditingController(text: links.join('\n'));
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const Text('Links (one per line):'),
        TextField(
          controller: controller,
          minLines: 1,
          maxLines: 5,
          decoration: const InputDecoration(hintText: 'Paste or type links here'),
          onChanged: (value) {
            final newLinks = value.split('\n').map((s) => s.trim()).where((s) => s.isNotEmpty).toList();
            onLinksChanged(newLinks);
          },
        ),
      ],
    );
  }
}
