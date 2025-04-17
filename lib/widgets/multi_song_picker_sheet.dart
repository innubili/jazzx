import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../providers/user_profile_provider.dart';

class MultiSongPickerSheet extends StatefulWidget {
  final List<String> initialSelection;
  final ValueChanged<List<String>> onSongsSelected;

  const MultiSongPickerSheet({
    super.key,
    required this.initialSelection,
    required this.onSongsSelected,
  });

  @override
  State<MultiSongPickerSheet> createState() => _MultiSongPickerSheetState();
}

class _MultiSongPickerSheetState extends State<MultiSongPickerSheet> {
  late List<String> selectedTitles;

  @override
  void initState() {
    super.initState();
    selectedTitles = List.from(widget.initialSelection);
  }

  void _toggleSelection(String title) {
    setState(() {
      if (selectedTitles.contains(title)) {
        selectedTitles.remove(title);
      } else {
        selectedTitles.add(title);
      }
    });
  }

  @override
  Widget build(BuildContext context) {
    final userSongs =
        Provider.of<UserProfileProvider>(
          context,
        ).profile?.songs.values.where((s) => !s.deleted).toList() ??
        [];

    return FractionallySizedBox(
      heightFactor: 0.8,
      child: SafeArea(
        top: false,
        child: Column(
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
              title: const Text('Select Repertoire Songs'),
              actions: [
                IconButton(
                  icon: const Icon(Icons.close),
                  tooltip: 'Cancel',
                  onPressed: () => Navigator.pop(context),
                ),
              ],
            ),
            if (userSongs.isEmpty)
              const Padding(
                padding: EdgeInsets.all(16),
                child: Text("No user songs available."),
              ),
            if (userSongs.isNotEmpty)
              Expanded(
                child: ListView.builder(
                  itemCount: userSongs.length,
                  itemBuilder: (context, index) {
                    final song = userSongs[index];
                    final isSelected = selectedTitles.contains(song.title);
                    return ListTile(
                      title: Text(song.title),
                      subtitle: Text(song.summary),
                      trailing: Icon(
                        isSelected
                            ? Icons.check_box
                            : Icons.check_box_outline_blank,
                      ),
                      onTap: () => _toggleSelection(song.title),
                    );
                  },
                ),
              ),
            Padding(
              padding: const EdgeInsets.symmetric(vertical: 12),
              child: ElevatedButton.icon(
                icon: const Icon(Icons.check_circle),
                label: const Text("Confirm Selection"),
                onPressed: () {
                  Navigator.pop(context, selectedTitles);
                },
              ),
            ),
          ],
        ),
      ),
    );
  }
}
