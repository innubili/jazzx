import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../providers/user_profile_provider.dart';
import '../utils/statistics_utils.dart';

class SettingsScreen extends StatelessWidget {
  const SettingsScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final profileProvider = Provider.of<UserProfileProvider>(context);
    final profile = profileProvider.profile;

    return Scaffold(
      appBar: AppBar(title: const Text('Settings')),
      body: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            if (profile != null) ...[
              Text('Name: ${profile.preferences.name}'),
              Text('Instrument: ${profile.preferences.instrument}'),
            ],
            const SizedBox(height: 24),
            const Divider(),
            const SizedBox(height: 24),
            TextButton.icon(
              icon: const Icon(Icons.refresh),
              label: const Text('Recalculate Statistics'),
              onPressed: () async {
                final confirm = await showDialog<bool>(
                  context: context,
                  builder:
                      (context) => AlertDialog(
                        title: const Text('Recalculate Statistics?'),
                        content: const Text(
                          'This will recompute statistics from all saved sessions and update the JSON file. Proceed?',
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

                if (confirm == true) {
                  final messenger = ScaffoldMessenger.of(context);
                  await recalculateAndUpdateStatistics(context);
                  if (!context.mounted) return;
                  messenger.showSnackBar(
                    const SnackBar(
                      content: Text(
                        'Statistics recalculated and saved to assets.',
                      ),
                    ),
                  );
                }
              },
            ),
          ],
        ),
      ),
    );
  }
}
