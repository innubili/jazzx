import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../providers/jazz_standards_provider.dart';
import '../widgets/song_widget.dart';

class JazzStandardsScreen extends StatelessWidget {
  const JazzStandardsScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text("Jazz Standards")),
      body: Consumer<JazzStandardsProvider>(
        builder: (context, provider, _) {
          if (provider.standards.isEmpty) {
            return const Center(child: CircularProgressIndicator());
          }

          return ListView.builder(
            itemCount: provider.standards.length,
            itemBuilder: (context, index) {
              final song = provider.standards[index];
              return SongWidget(song: song);
            },
          );
        },
      ),
    );
  }
}