import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../providers/user_profile_provider.dart';
import '../models/session.dart';
import '../screens/session_summary_screen.dart';

class SessionLogScreen extends StatelessWidget {
  const SessionLogScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text("Session Log")),
      body: Consumer<UserProfileProvider>(
        builder: (context, profileProvider, _) {
          final sessions = profileProvider.profile == null ? [] : profileProvider.profile!.sessions;

          if (sessions.isEmpty) {
            return const Center(child: Text("No sessions recorded."));
          }

          return ListView.builder(
            itemCount: sessions.length,
            itemBuilder: (context, index) {
              final session = sessions[index];
              return ListTile(
                title: Text('Session ${session.ended}'),
                subtitle: Text('Duration: ${session.duration} seconds'),
                onTap: () {
                  Navigator.push(context, MaterialPageRoute(
                    builder: (_) => SessionSummaryScreen(sessionData: session.toJson()),
                  ));
                },
              );
            },
          );
        },
      ),
    );
  }
}