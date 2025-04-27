import 'package:flutter/material.dart';

class AboutScreen extends StatelessWidget {
  const AboutScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('About'),
        leading: IconButton(
          icon: const Icon(Icons.home),
          tooltip: 'Back to Home',
          onPressed: () {
            Navigator.of(context).pushNamedAndRemoveUntil('/', (route) => false);
          },
        ),
      ),
      body: Padding(
        padding: const EdgeInsets.all(16),
        child: SingleChildScrollView(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              const Text('JazzX App - A Music Practice App', style: TextStyle(fontSize: 24, fontWeight: FontWeight.bold)),
              const SizedBox(height: 16),
              const Text('This app helps musicians track and practice jazz standards. Enjoy your practice sessions!'),
              const SizedBox(height: 24),
              const Text('Key Features:', style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold)),
              const SizedBox(height: 8),
              const Text('• Practice sessions with timer and metronome'),
              const Text('• Jazz standards library and song details'),
              const Text('• Personal song collection and progress tracking'),
              const Text('• Session log and statistics'),
              const Text('• Resource search (YouTube, Spotify, sheet music, etc.)'),
              const Text('• Cloud sync and backup via Firebase'),
              const Text('• Authentication (email/password & Google)'),
              const SizedBox(height: 24),
              const Text('Developer:', style: TextStyle(fontWeight: FontWeight.bold)),
              const Text('JazzX Team'),
              const SizedBox(height: 8),
              const Text('Version: 1.0.0'),
              const SizedBox(height: 16),
              const Text('Contact & Support:', style: TextStyle(fontWeight: FontWeight.bold)),
              const Text('support@jazzx.app'),
              const SizedBox(height: 16),
              const Text('Credits:', style: TextStyle(fontWeight: FontWeight.bold)),
              const Text('Thanks to the open-source Flutter, Firebase, and music education communities.'),
              const SizedBox(height: 16),
              // Optionally add links to website or privacy policy here if available
              Center(
                child: ElevatedButton(
                  onPressed: () => Navigator.pop(context),
                  child: const Text('Back to Home'),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}