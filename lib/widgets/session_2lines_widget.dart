import 'package:flutter/material.dart';
import '../models/session.dart';
import '../models/practice_category.dart';
import '../utils/session_utils.dart';

class Session2LinesWidget extends StatelessWidget {
  final Session session;
  final String sessionId;
  const Session2LinesWidget({
    super.key,
    required this.session,
    required this.sessionId,
  });

  String _formatDuration(int seconds) {
    final d = Duration(seconds: seconds);
    final h = d.inHours;
    final m = d.inMinutes % 60;
    return '${h.toString().padLeft(2, '0')}:${m.toString().padLeft(2, '0')}';
  }

  @override
  Widget build(BuildContext context) {
    final catTimes = session.categories.entries.toList();
    final warmupTime = session.warmupTime ?? 0;
    final hasWarmup = warmupTime > 0;
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          children: [
            Expanded(
              child: Text(
                sessionIdToReadableString(sessionId),
                style: Theme.of(context).textTheme.bodyLarge,
              ),
            ),
            Text(
              _formatDuration(session.duration),
              style: Theme.of(context).textTheme.bodyMedium,
            ),
          ],
        ),
        const SizedBox(height: 2),
        Wrap(
          spacing: 8,
          runSpacing: 2,
          children: [
            if (hasWarmup)
              Chip(
                avatar: Icon(
                  PracticeCategoryUtils.icons[PracticeCategory.warmup],
                ),
                label: Text(_formatDuration(warmupTime)),
              ),
            ...catTimes
                .where((e) => e.value.time > 0)
                .map(
                  (e) => Chip(
                    avatar: Icon(PracticeCategoryUtils.icons[e.key]),
                    label: Text(_formatDuration(e.value.time)),
                  ),
                ),
          ],
        ),
      ],
    );
  }
}
