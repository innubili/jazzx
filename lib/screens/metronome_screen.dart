import 'package:flutter/material.dart';
import '../widgets/metronome_widget.dart';
import '../widgets/metronome_controller.dart';

class MetronomeScreen extends StatelessWidget {
  final MetronomeController controller = MetronomeController();

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text("Metronome")),
      body: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          children: [
            SizedBox(
              height: 250,
              child: MetronomeWidget(
                controller: controller,
                disableToggle: false,
              ),
            ),
            ElevatedButton(
              onPressed: () => controller.start(),
              child: const Text("Start Metronome"),
            ),
          ],
        ),
      ),
    );
  }
}