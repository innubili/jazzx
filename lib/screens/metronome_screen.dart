import 'package:flutter/material.dart';
import 'package:audioplayers/audioplayers.dart';
import '../utils/utils.dart';
import 'dart:async';
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
  @override
  void dispose() {
    _TestHFButton.disposePlayer();
    super.dispose();
  }

  final MetronomeController _metronomeController = MetronomeController();

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Metronome'),
        leading: Builder(
          builder:
              (context) => IconButton(
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
            const SizedBox(height: 32),

            // --- TEST BUTTONS: REMOVE AFTER TESTING ---
            // Test HF toggle button
            _TestHFButton(),

            // TunerWidget(),
          ],
        ),
      ),
    );
  }
}

// --- TEST BUTTONS (REMOVE AFTER TESTING) ---

class _TestHFButton extends StatefulWidget {
  static AudioPlayer? _player;
  static bool _isInitialized = false;
  static Future<void> _initPlayer() async {
    if (_player == null) {
      _player = AudioPlayer();
      await _player!.setPlayerMode(PlayerMode.lowLatency);
      await _player!.setSource(AssetSource('sounds/tick.wav'));
      _isInitialized = true;
      defLog('[TestHF] AudioPlayer initialized and tick.wav preloaded');
    }
  }

  static void disposePlayer() {
    _player?.dispose();
    _player = null;
    _isInitialized = false;
  }

  @override
  State<_TestHFButton> createState() => _TestHFButtonState();
}

class _TestHFButtonState extends State<_TestHFButton> {
  Timer? _timer;
  bool _isPlaying = false;

  @override
  void initState() {
    super.initState();
    _TestHFButton._initPlayer();
  }

  @override
  void dispose() {
    _timer?.cancel();
    super.dispose();
  }

  void _toggleHF() async {
    if (_isPlaying) {
      _timer?.cancel();
      setState(() => _isPlaying = false);
      defLog('[TestHF] Stopped high-frequency tick');
      return;
    }
    await _TestHFButton._initPlayer();
    setState(() => _isPlaying = true);
    defLog('[TestHF] Started high-frequency tick');
    _timer = Timer.periodic(const Duration(milliseconds: 83), (timer) async {
      defLog('[TestHF] Timer fired');
      if (_TestHFButton._isInitialized && _TestHFButton._player != null) {
        try {
          // Use play instead of seek+resume for each tick
          await _TestHFButton._player!.play(
            AssetSource('sounds/tick.wav'),
            volume: 1.0,
          );
          defLog('[TestHF] Tick play() called');
        } catch (e) {
          defLog('[TestHF] ERROR: $e');
        }
      } else {
        defLog('[TestHF] Player not initialized');
      }
    });
  }

  @override
  Widget build(BuildContext context) {
    return TextButton(
      onPressed: _toggleHF,
      child: Text(_isPlaying ? 'Stop HF' : 'Test HF'),
    );
  }
}

// --- END TEST BUTTONS ---
