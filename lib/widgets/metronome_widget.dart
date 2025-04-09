// Placeholder implementation of the MetronomeWidget
import 'package:flutter/material.dart';

class MetronomeController {
  void start() {}
  void stop() {}
  void setBpm(int bpm) {}
}

class MetronomeWidget extends StatelessWidget {
  final MetronomeController controller;
  final bool disableToggle;

  const MetronomeWidget({super.key, required this.controller, this.disableToggle = false});

  @override
  Widget build(BuildContext context) {
    return Center(
      child: Text("Metronome Widget Placeholder", style: Theme.of(context).textTheme.titleMedium),
    );
  }
}