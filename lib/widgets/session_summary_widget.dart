import 'package:flutter/material.dart';
import '../models/session.dart';
import '../models/practice_category.dart';

/// Widget that displays a user-friendly summary of a session (for session log, etc).
class SessionSummaryWidget extends StatelessWidget {
  final String sessionId;
  final Session session;
  const SessionSummaryWidget({
    super.key,
    required this.sessionId,
    required this.session,
  });

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          _formatDateTime(sessionId),
          style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 18),
        ),
        const SizedBox(height: 4),
        Text(
          _buildSummaryLine(),
          style: TextStyle(color: Theme.of(context).hintColor),
        ),
      ],
    );
  }

  String _formatDateTime(String sessionId) {
    int timestamp;
    try {
      timestamp = int.parse(sessionId);
    } catch (_) {
      return 'Invalid date';
    }
    // If the timestamp is in seconds (e.g. 10 digits), convert to ms
    if (timestamp < 1000000000000) {
      timestamp = timestamp * 1000;
    }
    final date = DateTime.fromMillisecondsSinceEpoch(timestamp);
    // Format: DD-MMM-YYYY HH:mm
    final months = [
      'Jan',
      'Feb',
      'Mar',
      'Apr',
      'May',
      'Jun',
      'Jul',
      'Aug',
      'Sep',
      'Oct',
      'Nov',
      'Dec',
    ];
    final mmm = months[date.month - 1];
    return '${date.day.toString().padLeft(2, '0')}-$mmm-${date.year} '
        '${date.hour.toString().padLeft(2, '0')}:${date.minute.toString().padLeft(2, '0')}';
  }

  String _buildSummaryLine() {
    // Collect category times, sort, and format as single line
    final items = <_CategorySummary>[];
    session.categories.forEach((cat, catData) {
      if (catData.time > 0) {
        items.add(_CategorySummary(name: cat.displayName, time: catData.time));
      }
    });
    items.sort((a, b) => b.time.compareTo(a.time));
    if (items.isEmpty) return 'No practice recorded.';
    return items.map((e) => '${e.name} ${_formatMinutes(e.time)}').join(', ');
  }

  String _formatMinutes(int seconds) {
    final h = seconds ~/ 3600;
    final m = (seconds % 3600) ~/ 60;
    return '${h.toString().padLeft(2, '0')}:${m.toString().padLeft(2, '0')}';
  }
}

class _CategorySummary {
  final String name;
  final int time;
  _CategorySummary({required this.name, required this.time});
}

extension PracticeCategoryDisplay on PracticeCategory {
  String get displayName {
    switch (this) {
      case PracticeCategory.exercise:
        return 'Exercise';
      case PracticeCategory.newsong:
        return 'New Song';
      case PracticeCategory.repertoire:
        return 'Repertoire';
      case PracticeCategory.lesson:
        return 'Lesson';
      case PracticeCategory.theory:
        return 'Theory';
      case PracticeCategory.video:
        return 'Video';
      case PracticeCategory.gig:
        return 'Gig';
      case PracticeCategory.fun:
        return 'Fun';
      case PracticeCategory.warmup:
        return 'Warmup';
    }
  }
}
