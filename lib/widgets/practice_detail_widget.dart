import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../models/practice_category.dart';
import '../providers/user_profile_provider.dart';
import '../providers/jazz_standards_provider.dart';
import 'song_picker_sheet.dart';
import 'multi_song_picker_sheet.dart';

class PracticeDetailWidget extends StatelessWidget {
  final PracticeCategory category;
  final String note;
  final List<String> songs;
  final ValueChanged<String> onNoteChanged;
  final ValueChanged<List<String>> onSongsChanged;

  const PracticeDetailWidget({
    super.key,
    required this.category,
    required this.note,
    required this.songs,
    required this.onNoteChanged,
    required this.onSongsChanged,
  });

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.all(16.0),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          TextField(
            decoration: const InputDecoration(labelText: "Note"),
            controller: TextEditingController(text: note),
            onChanged: onNoteChanged,
          ),
          const SizedBox(height: 16),

          // New Song Picker
          if (category == PracticeCategory.newsong)
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Expanded(
                  child: Text(
                    songs.isNotEmpty ? songs.first : "No song selected",
                    style: const TextStyle(fontSize: 16),
                  ),
                ),
                TextButton(
                  onPressed: () async {
                    final profileProvider = Provider.of<UserProfileProvider>(
                      context,
                      listen: false,
                    );
                    final profile = profileProvider.profile;
                    final standards =
                        Provider.of<JazzStandardsProvider>(
                          context,
                          listen: false,
                        ).standards;

                    final excludeTitles = profile?.songs.keys.toList() ?? [];

                    final selectedSongTitle =
                        await showModalBottomSheet<String>(
                          context: context,
                          isScrollControlled: true,
                          builder:
                              (context) =>
                                  SongPickerSheet(excludeTitles: excludeTitles),
                        );

                    if (selectedSongTitle != null) {
                      if (profile != null &&
                          !profile.songs.containsKey(selectedSongTitle)) {
                        final selected = standards.firstWhere(
                          (s) => s.title == selectedSongTitle,
                          orElse:
                              () =>
                                  throw Exception(
                                    'Song not found in standards',
                                  ),
                        );
                        profileProvider.addSong(selected.copyWith());
                      }

                      onSongsChanged([selectedSongTitle]);
                    }
                  },
                  child: const Text("Choose Song"),
                ),
              ],
            ),

          // Repertoire Multi Song Picker
          if (category == PracticeCategory.repertoire)
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
