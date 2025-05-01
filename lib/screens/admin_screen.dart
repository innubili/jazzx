import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../models/session.dart';
import '../providers/user_profile_provider.dart';
import '../utils/session_utils.dart';
import '../utils/statistics_utils.dart';
import '../widgets/main_drawer.dart';

class AdminScreen extends StatelessWidget {
  const AdminScreen({super.key});

  Future<void> _onRecalculateStatistics(BuildContext context) async {
    final confirm = await showDialog<bool>(
      context: context,
      builder:
          (context) => AlertDialog(
            title: const Text('Recalculate Statistics?'),
            content: const Text(
              'This will recompute statistics from all saved sessions and update your profile in Firebase. Proceed?',
            ),
            actions: [
              TextButton(
                onPressed: () => Navigator.pop(context, false),
                child: const Text('Cancel'),
              ),
              ElevatedButton(
                onPressed: () => Navigator.pop(context, true),
                child: const Text('Confirm'),
              ),
            ],
          ),
    );
    if (confirm != true) return;
    final profileProvider = Provider.of<UserProfileProvider>(
      context,
      listen: false,
    );
    final profile = profileProvider.profile;
    if (profile != null) {
      final sessions = profile.sessions.values.toList();
      final updatedStats = recalculateStatisticsFromSessions(sessions);
      await profileProvider.updateStatistics(updatedStats);
    }
    if (!context.mounted) return;
    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(
        content: Text('Statistics recalculated and saved to your profile.'),
      ),
    );
  }

  Future<void> _onFixSessionDurations(BuildContext context) async {
    final profileProvider = Provider.of<UserProfileProvider>(
      context,
      listen: false,
    );
    final profile = profileProvider.profile;
    if (profile == null) return;
    final sessions = profile.sessions;
    final wrongs = findSessionsWithWrongDuration(sessions);
    if (wrongs.isEmpty) {
      if (!context.mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('All session durations are correct.')),
      );
      return;
    }
    final confirm = await showDialog<bool>(
      context: context,
      builder:
          (context) => AlertDialog(
            title: const Text('Fix Session Durations?'),
            content: Text(
              'Found ${wrongs.length} session(s) with wrong duration. Update durations in Firebase?',
            ),
            actions: [
              TextButton(
                onPressed: () => Navigator.pop(context, false),
                child: const Text('Cancel'),
              ),
              ElevatedButton(
                onPressed: () => Navigator.pop(context, true),
                child: const Text('Confirm'),
              ),
            ],
          ),
    );
    if (confirm != true) return;
    for (final entry in wrongs.entries) {
      final sessionId = entry.key;
      final correctDuration = entry.value;
      final oldSession = sessions[sessionId]!;
      final updatedSession = Session(
        duration: correctDuration,
        ended: oldSession.ended,
        instrument: oldSession.instrument,
        categories: oldSession.categories,
        warmupTime: oldSession.warmupTime,
        warmupBpm: oldSession.warmupBpm,
      );
      await profileProvider.updateSession(sessionId, updatedSession);
      if (!context.mounted) return;
    }
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text('Fixed durations for ${wrongs.length} session(s).'),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Admin'),
        leading: Builder(
          builder:
              (context) => IconButton(
                icon: const Icon(Icons.menu),
                tooltip: 'Open navigation menu',
                onPressed: () => Scaffold.of(context).openDrawer(),
              ),
        ),
      ),
      drawer: const MainDrawer(),
      body: Padding(
        padding: const EdgeInsets.all(24.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            ElevatedButton.icon(
              icon: const Icon(Icons.refresh),
              label: const Text('Recalculate Statistics'),
              style: ElevatedButton.styleFrom(
                minimumSize: const Size(220, 48),
                textStyle: const TextStyle(fontSize: 16),
              ),
              onPressed: () => _onRecalculateStatistics(context),
            ),
            const SizedBox(height: 12),
            ElevatedButton.icon(
              icon: const Icon(Icons.timer_outlined),
              label: const Text('Fix Session Durations'),
              style: ElevatedButton.styleFrom(
                minimumSize: const Size(220, 48),
                textStyle: const TextStyle(fontSize: 16),
              ),
              onPressed: () => _onFixSessionDurations(context),
            ),
          ],
        ),
      ),
    );
  }
}
