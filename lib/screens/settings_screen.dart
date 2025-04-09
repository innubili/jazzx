import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../providers/user_profile_provider.dart';

class SettingsScreen extends StatelessWidget {
  const SettingsScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final profile = Provider.of<UserProfileProvider>(context).profile;

    return Scaffold(
      appBar: AppBar(title: const Text("Settings")),
      body: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          children: [
            if (profile != null)
              Column(
                children: [
                  Text('Name: ${profile.profile.name}', style: Theme.of(context).textTheme.headlineSmall),
                  Text('Instrument: ${profile.profile.instrument}', style: Theme.of(context).textTheme.bodyMedium),
                ],
              )
            else
              const CircularProgressIndicator(),
            ElevatedButton(
              onPressed: () {},
              child: const Text('Edit Profile'),
            ),
          ],
        ),
      ),
    );
  }
}