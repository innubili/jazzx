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
                  Text('Name: ${profile.name}', style: Theme.of(context).textTheme.headline6),
                  Text('Instrument: ${profile.instrument}', style: Theme.of(context).textTheme.subtitle1),
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