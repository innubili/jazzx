import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../providers/session_provider.dart';
import '../widgets/confirm_dialog.dart';
import 'session_summary_screen.dart';

class SessionLogScreen extends StatelessWidget {
  const SessionLogScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Session Log'),
        leading: IconButton(
          icon: const Icon(Icons.home),
          tooltip: 'Back to Home',
          onPressed: () {
            Navigator.of(context).pushNamedAndRemoveUntil('/', (route) => false);
          },
        ),
      ),
      body: Consumer<SessionProvider>(
        builder: (context, sessionProvider, _) {
          final sessions = sessionProvider.sessions;

          if (sessions.isEmpty) {
            return const Center(child: Text("No sessions recorded."));
          }

          final sortedSessions = [...sessions]..sort((a, b) {
            final aTs = a['timestamp'] ?? 0;
            final bTs = b['timestamp'] ?? 0;
            return bTs.compareTo(aTs);
          });

          return ListView.builder(
            itemCount: sortedSessions.length,
            itemBuilder: (context, index) {
              final session = sortedSessions[index];
              final sessionTimestamp = session['timestamp'] ?? 0;
              final sessionDate = DateTime.fromMillisecondsSinceEpoch(
                sessionTimestamp,
              );

              return ListTile(
                title: Text('Session on ${sessionDate.toLocal()}'),
                subtitle: Text('Duration: ${session['duration'] ?? 0} seconds'),
                onTap: () {
                  Navigator.push(
                    context,
                    MaterialPageRoute(
                      builder:
                          (_) => SessionSummaryScreen(
                            sessionData: session,
                            onConfirm: (updatedData) {
                              final originalIndex = sessionProvider.sessions
                                  .indexOf(session);
                              if (originalIndex != -1) {
                                sessionProvider.updateSession(
                                  originalIndex,
                                  updatedData,
                                );
                              }
                              Navigator.pop(context);
                            },
                          ),
                    ),
                  );
                },
                trailing: IconButton(
                  icon: const Icon(Icons.delete),
                  onPressed: () {
                    showDialog(
                      context: context,
                      builder:
                          (ctx) => ConfirmDialog(
                            title: "Confirm Deletion",
                            content:
                                "Are you sure you want to delete this session?",
                            onCancel: () => Navigator.pop(ctx),
                            onConfirm: () {
                              Navigator.pop(ctx);
                              final originalIndex = sessionProvider.sessions
                                  .indexOf(session);
                              if (originalIndex != -1) {
                                sessionProvider.deleteSession(originalIndex);
                              }
                            },
                          ),
                    );
                  },
                ),
              );
            },
          );
        },
      ),
    );
  }
}
