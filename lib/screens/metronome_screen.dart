import 'package:flutter/material.dart';
import '../widgets/metronome_widget.dart';
import '../widgets/metronome_controller.dart';
import '../widgets/main_drawer.dart'; 
// import '../widgets/tuner_widget.dart';

class MetronomeScreen extends StatefulWidget {
  const MetronomeScreen({super.key});

  @override
  State<MetronomeScreen> createState() => _MetronomeScreenState();
}

class _MetronomeScreenState extends State<MetronomeScreen> {
  final MetronomeController _metronomeController = MetronomeController();

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Metronome'),
        leading: Builder(
          builder: (context) => IconButton(
            icon: const Icon(Icons.menu),
            tooltip: 'Open navigation menu',
            onPressed: () => Scaffold.of(context).openDrawer(),
          ),
        ),
      ),
      drawer: const MainDrawer(),
      body: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          children: [
            MetronomeWidget(controller: _metronomeController),
            const SizedBox(height: 24),
            // Optional external control buttons
            Row(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                ElevatedButton(
                  onPressed: () => _metronomeController.start(),
                  child: const Text("Start"),
                ),
                const SizedBox(width: 16),
                ElevatedButton(
                  onPressed: () => _metronomeController.stop(),
                  child: const Text("Stop"),
                ),
              ],
            ),
            const SizedBox(height: 32),
            // TunerWidget(),
          ],
        ),
      ),
    );
  }
}
