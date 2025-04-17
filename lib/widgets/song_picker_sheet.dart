import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../providers/jazz_standards_provider.dart';
import '../widgets/song_browser_widget.dart';
import '../utils/log.dart';

class SongPickerSheet extends StatelessWidget {
  final List<String> excludeTitles;

  const SongPickerSheet({super.key, required this.excludeTitles});

  @override
  Widget build(BuildContext context) {
    final allSongs = Provider.of<JazzStandardsProvider>(context).standards;

    final excludeSet = excludeTitles.map((e) => e.trim().toLowerCase()).toSet();

    final filteredSongs =
        allSongs
            .where(
              (song) => !excludeSet.contains(song.title.trim().toLowerCase()),
            )
            .toList();

    return FractionallySizedBox(
      heightFactor: 0.60,
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
              title: const Text('Pick a Song'),
              actions: [
                IconButton(
                  icon: const Icon(Icons.close),
                  tooltip: 'Cancel',
                  onPressed: () => Navigator.pop(context),
                ),
              ],
            ),
            Expanded(
              child: SongBrowserWidget(
                songs: filteredSongs,
                readOnly: true,
                selectable: true,
                onSelected: (song) {
                  log.info('✅ Selected: ${song.title}');
                  Navigator.pop(context, song.title);
                },
              ),
            ),
          ],
        ),
      ),
    );
  }
}
