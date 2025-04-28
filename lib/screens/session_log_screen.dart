import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../widgets/main_drawer.dart';
import '../providers/user_profile_provider.dart';
// import '../widgets/session_review_widget.dart';
// import '../widgets/session_summary_widget.dart';
import '../widgets/session_2lines_widget.dart';
import 'session_review_screen.dart';

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
          builder:
              (context) => IconButton(
                icon: const Icon(Icons.menu),
                tooltip: 'Open navigation menu',
                onPressed: () => Scaffold.of(context).openDrawer(),
              ),
        ),
        actions: [
          IconButton(
            icon: const Icon(Icons.add),
            tooltip: 'Add manual session',
            onPressed: () async {
              // Pick date
              final now = DateTime.now();
              final pickedDate = await showDatePicker(
                context: context,
                initialDate: now,
                firstDate: DateTime(now.year - 1),
                lastDate: now,
              );
              if (pickedDate == null) return;
              // Pick time
              final pickedTime = await showTimePicker(
                context: context,
                initialTime: TimeOfDay.fromDateTime(now),
                builder: (context, child) => MediaQuery(
                  data: MediaQuery.of(context).copyWith(alwaysUse24HourFormat: true),
                  child: child!,
                ),
              );
              if (pickedTime == null) return;
              final sessionDateTime = DateTime(
                pickedDate.year,
                pickedDate.month,
                pickedDate.day,
                pickedTime.hour,
                pickedTime.minute,
              );
              final sessionId = sessionDateTime.millisecondsSinceEpoch ~/ 1000;
              if (!context.mounted) return;
              Navigator.push(
                context,
                MaterialPageRoute(
                  builder:
                      (_) => SessionReviewScreen(
                        sessionId: sessionId.toString(),
                        session: null, // Will be handled in SessionReviewScreen
                        manualEntry: true,
                        initialDateTime: sessionDateTime,
                      ),
                ),
              );
            },
          ),
        ],
      ),
      drawer: const MainDrawer(),
      body:
          sessionEntries.isEmpty
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
                    title: Session2LinesWidget(
                      sessionId: sessionId,
                      session: session,
                    ),
                    trailing: const Icon(Icons.chevron_right),
                    onTap: () {
                      Navigator.push(
                        context,
                        MaterialPageRoute(
                          builder:
                              (_) => SessionReviewScreen(
                                sessionId: sessionId,
                                session: session,
                              ),
                        ),
                      );
                    },
                  );
                },
              ),
    );
  }
}
