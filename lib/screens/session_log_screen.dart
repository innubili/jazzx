import 'dart:convert';
import 'dart:io';
import 'package:flutter/material.dart';
import 'package:path_provider/path_provider.dart';
import '../widgets/confirm_dialog.dart';
import 'session_summary_screen.dart';

class SessionLogScreen extends StatefulWidget {
  const SessionLogScreen({super.key});

  @override
  State<SessionLogScreen> createState() => _SessionLogScreenState();
}

class _SessionLogScreenState extends State<SessionLogScreen> {
  List<Map<String, dynamic>> _sessions = [];

  @override
  void initState() {
    super.initState();
    _loadSessions();
  }

  Future<void> _loadSessions() async {
    try {
      final directory = await getApplicationDocumentsDirectory();
      final file = File('${directory.path}/sessions.json');
      if (await file.exists()) {
        final jsonString = await file.readAsString();
        final List<dynamic> jsonList = json.decode(jsonString);
        setState(() {
          _sessions = List<Map<String, dynamic>>.from(jsonList);
        });
      }
    } catch (e) {
      print("Error loading sessions: $e");
    }
  }

  Future<void> _saveSessions() async {
    try {
      final directory = await getApplicationDocumentsDirectory();
      final file = File('${directory.path}/sessions.json');
      await file.writeAsString(json.encode(_sessions));
    } catch (e) {
      print("Error saving sessions: $e");
    }
  }

  Future<void> _deleteSession(int index) async {
    setState(() {
      _sessions.removeAt(index);
    });
    await _saveSessions();
  }

  Future<void> _updateSession(
    int index,
    Map<String, dynamic> updatedData,
  ) async {
    setState(() {
      _sessions[index] = updatedData;
    });
    await _saveSessions();
  }

  @override
  Widget build(BuildContext context) {
    if (_sessions.isEmpty) {
      return Scaffold(
        appBar: AppBar(title: Text("Session Log")),
        body: Center(child: Text("No sessions recorded.")),
      );
    }

    // Sort latest first by timestamp field (if available)
    _sessions.sort((a, b) {
      final aTs = a['timestamp'] ?? 0;
      final bTs = b['timestamp'] ?? 0;
      return bTs.compareTo(aTs);
    });

    return Scaffold(
      appBar: AppBar(title: const Text("Session Log")),
      body: ListView.builder(
        itemCount: _sessions.length,
        itemBuilder: (context, index) {
          final session = _sessions[index];
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
                        onConfirm: (updatedData) async {
                          await _updateSession(index, updatedData);
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
                        onConfirm: () async {
                          Navigator.pop(ctx);
                          await _deleteSession(index);
                        },
                      ),
                );
              },
            ),
          );
        },
      ),
    );
  }
}


/*

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
*/