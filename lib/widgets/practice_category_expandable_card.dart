import 'package:flutter/material.dart';
import '../models/practice_category.dart';
import '../models/session.dart';
import 'practice_detail_widget.dart';

class PracticeCategoryExpandableCard extends StatelessWidget {
  final PracticeCategory category;
  final SessionCategory data;
  final bool isExpanded;
  final bool editMode;
  final VoidCallback onTap;
  final ValueChanged<String> onNoteChanged;
  final ValueChanged<List<String>> onSongsChanged;
  final ValueChanged<int> onTimeChanged;
  final ValueChanged<List<String>> onLinksChanged;
  final bool editRecordedSession;

  const PracticeCategoryExpandableCard({
    super.key,
    required this.category,
    required this.data,
    required this.isExpanded,
    required this.editMode,
    required this.onTap,
    required this.onNoteChanged,
    required this.onSongsChanged,
    required this.onTimeChanged,
    required this.onLinksChanged,
    this.editRecordedSession = false,
  });

  @override
  Widget build(BuildContext context) {
    final topBar = Padding(
      padding: const EdgeInsets.all(12.0),
      child: Row(
        children: [
          Icon(
            PracticeCategoryUtils.icons[category],
            color: _categoryColor(category),
          ),
          const SizedBox(width: 8),
          Text(
            category.name.capitalize(),
            style: const TextStyle(fontWeight: FontWeight.bold),
          ),
          const Spacer(),
          if (editMode && isExpanded && !editRecordedSession) ...[
            IconButton(
              icon: const Icon(Icons.remove),
              onPressed:
                  data.time >= 300
                      ? () => onTimeChanged((data.time - 300).clamp(0, 28800))
                      : null,
            ),
            Text(
              _formatDurationHHmm(data.time),
              style: const TextStyle(fontWeight: FontWeight.bold),
            ),
            IconButton(
              icon: const Icon(Icons.add),
              onPressed:
                  data.time < 28800
                      ? () => onTimeChanged((data.time + 300).clamp(0, 28800))
                      : null,
            ),
          ] else ...[
            Text(
              _formatDuration(data.time),
              style: const TextStyle(fontWeight: FontWeight.bold),
            ),
          ],
        ],
      ),
    );

    final editor = Padding(
      padding: const EdgeInsets.all(12.0),
      child: PracticeDetailWidget(
        category: category,
        note: data.note ?? '',
        songs: data.songs?.keys.toList() ?? [],
        links: data.links ?? [],
        onNoteChanged: onNoteChanged,
        onSongsChanged: onSongsChanged,
        time: data.time,
        onTimeChanged: (_) {},
        onLinksChanged: onLinksChanged,
      ),
    );

    VoidCallback buildOnTap(BuildContext context) {
      if (editMode && category == PracticeCategory.repertoire) {
        return () {
          // Only show alert if user is trying to add or save songs, not just expand
          if ((data.time > 0) &&
              (data.songs == null || data.songs!.isEmpty) &&
              !isExpanded) {
            showDialog(
              context: context,
              builder:
                  (ctx) => AlertDialog(
                    title: const Text('Select Songs'),
                    content: const Text(
                      'Please select at least one song for Repertoire.',
                    ),
                    actions: [
                      TextButton(
                        onPressed: () => Navigator.of(ctx).pop(),
                        child: const Text('OK'),
                      ),
                    ],
                  ),
            );
            return;
          }
          onTap();
        };
      } else {
        return onTap;
      }
    }

    return Card(
      margin: const EdgeInsets.symmetric(vertical: 8),
      child:
          editMode
              ? isExpanded
                  ? Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      InkWell(onTap: buildOnTap(context), child: topBar),
                      AnimatedCrossFade(
                        crossFadeState: CrossFadeState.showSecond,
                        duration: const Duration(milliseconds: 200),
                        firstChild: const SizedBox.shrink(),
                        secondChild: editor,
                      ),
                    ],
                  )
                  : InkWell(onTap: buildOnTap(context), child: topBar)
              : topBar,
    );
  }

  String _formatDuration(int seconds) {
    final hours = seconds ~/ 3600;
    final minutes = (seconds % 3600) ~/ 60;
    return '${hours.toString().padLeft(2, '0')}:${minutes.toString().padLeft(2, '0')}';
  }

  String _formatDurationHHmm(int seconds) {
    final h = seconds ~/ 3600;
    final m = (seconds % 3600) ~/ 60;
    return h > 0
        ? '${h.toString().padLeft(2, '0')}:${m.toString().padLeft(2, '0')}'
        : '00:${m.toString().padLeft(2, '0')}';
  }

  Color _categoryColor(PracticeCategory category) {
    switch (category) {
      case PracticeCategory.exercise:
        return Colors.blue;
      case PracticeCategory.newsong:
        return Colors.green;
      case PracticeCategory.repertoire:
        return Colors.purple;
      case PracticeCategory.lesson:
        return Colors.orange;
      case PracticeCategory.theory:
        return Colors.teal;
      case PracticeCategory.video:
        return Colors.red;
      case PracticeCategory.gig:
        return Colors.amber;
      case PracticeCategory.fun:
        return Colors.pink;
    }
  }
}

extension StringCapitalize on String {
  String capitalize() =>
      isEmpty ? this : '${this[0].toUpperCase()}${substring(1)}';
}
