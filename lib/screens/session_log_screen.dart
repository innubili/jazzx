import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../widgets/main_drawer.dart';
import '../providers/user_profile_provider.dart';
import '../widgets/session_summary_widget.dart';

class SessionLogScreen extends StatelessWidget {
  const SessionLogScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final profileProvider = Provider.of<UserProfileProvider>(context);
    final sessionsMap = profileProvider.profile?.sessions ?? {};
    // The session ID is the timestamp in SECONDS, not milliseconds
    final sessionEntries = sessionsMap.entries.toList();
    sessionEntries.sort((a, b) => int.parse(b.key).compareTo(int.parse(a.key)));

    return Scaffold(
      appBar: AppBar(
        title: const Text('Session Log'),
        leading: Builder(
          builder: (context) => IconButton(
            icon: const Icon(Icons.menu),
            tooltip: 'Open navigation menu',
            onPressed: () => Scaffold.of(context).openDrawer(),
          ),
        ),
      ),
      drawer: const MainDrawer(),
      body: sessionEntries.isEmpty
          ? const Center(child: Text('No sessions recorded.'))
          : ListView.separated(
              padding: const EdgeInsets.all(16),
              itemCount: sessionEntries.length,
              separatorBuilder: (_, __) => const Divider(height: 16),
              itemBuilder: (context, index) {
                final entry = sessionEntries[index];
                final sessionId = entry.key;
                final session = entry.value;
                return ListTile(
                  title: SessionSummaryWidget(
                    sessionId: sessionId,
                    session: session,
                  ),
                  trailing: const Icon(Icons.chevron_right),
                  onTap: () {
                    Navigator.pushNamed(
                      context,
                      '/session_summary',
                      arguments: {
                        'sessionData': session.toJson(),
                        'onConfirm': null, // Implement edit/save if needed
                      },
                    );
                  },
                );
              },
            ),
    );
  }
}
