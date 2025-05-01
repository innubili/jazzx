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
  });

  @override
  Widget build(BuildContext context) {
    final summaryRow = Padding(
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
          Text(
            _formatDuration(data.time),
            style: const TextStyle(fontWeight: FontWeight.bold),
          ),
        ],
      ),
    );

    final editor = Padding(
      padding: const EdgeInsets.all(12.0),
      child: PracticeDetailWidget(
        category: category,
        note: data.note ?? '',
        songs: data.songs?.keys.toList() ?? [],
        time: data.time,
        links: data.links ?? [],
        onNoteChanged: onNoteChanged,
        onSongsChanged: onSongsChanged,
        onTimeChanged: onTimeChanged,
        onLinksChanged: onLinksChanged,
      ),
    );

    VoidCallback buildOnTap(BuildContext context) {
      if (editMode && category == PracticeCategory.repertoire) {
        return () {
          if ((data.time > 0) && (data.songs == null || data.songs!.isEmpty)) {
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
                      InkWell(onTap: buildOnTap(context), child: summaryRow),
                      AnimatedCrossFade(
                        crossFadeState: CrossFadeState.showSecond,
                        duration: const Duration(milliseconds: 200),
                        firstChild: const SizedBox.shrink(),
                        secondChild: editor,
                      ),
                    ],
                  )
                  : InkWell(onTap: buildOnTap(context), child: summaryRow)
              : summaryRow,
    );
  }

  String _formatDuration(int seconds) {
    final hours = seconds ~/ 3600;
    final minutes = (seconds % 3600) ~/ 60;
    return '${hours.toString().padLeft(2, '0')}:${minutes.toString().padLeft(2, '0')}';
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
      case PracticeCategory.warmup:
        return Colors.deepOrange;
    }
  }
}

extension StringCapitalize on String {
  String capitalize() =>
      isEmpty ? this : '${this[0].toUpperCase()}${substring(1)}';
}
