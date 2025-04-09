import 'package:firebase_database/firebase_database.dart';
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../providers/user_profile_provider.dart';
import '../widgets/confirm_dialog.dart';
import 'session_summary_screen.dart';

class SessionLogScreen extends StatelessWidget {
  const SessionLogScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text("Session Log")),
      body: Consumer<UserProfileProvider>(
        builder: (context, profileProvider, _) {
          final sessionsMap = profileProvider.profile?.sessions ?? {};

          if (sessionsMap.isEmpty) {
            return const Center(child: Text("No sessions recorded."));
          }

          final sessionsList = sessionsMap.entries.toList()
            ..sort((a, b) => b.key.compareTo(a.key)); // latest first

          return ListView.builder(
            itemCount: sessionsList.length,
            itemBuilder: (context, index) {
              final sessionEntry = sessionsList[index];
              final sessionId = sessionEntry.key;
              final session = sessionEntry.value;
              final sessionDate = DateTime.fromMillisecondsSinceEpoch(
                  int.parse(sessionId) * 1000);

              return ListTile(
                title: Text('Session on ${sessionDate.toLocal()}'),
                subtitle: Text('Duration: ${session.duration} seconds'),
                onTap: () {
                  Navigator.push(
                    context,
                    MaterialPageRoute(
                      builder: (_) => SessionSummaryScreen(
                        sessionData: session.toJson(),
                        onConfirm: (updatedData) {
                          final userId = profileProvider.userId;
                          if (userId != null) {
                            final sessionRef = FirebaseDatabase.instance
                                .ref('users/\$userId/sessions/\$sessionId');
                            sessionRef.set(updatedData);
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
                      builder: (ctx) => ConfirmDialog(
                        title: "Confirm Deletion",
                        content: "Are you sure you want to delete this session?",
                        onCancel: () => Navigator.pop(ctx),
                        onConfirm: () {
                          // TODO: implement actual deletion logic here
                          Navigator.pop(ctx);
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
