import 'dart:async';
import 'package:flutter/material.dart';
import 'package:flutter/cupertino.dart';
import 'metronome_controller.dart';
import '../utils/utils.dart';
import 'metronome_sound_player.dart';
import 'metronome_sound_player_factory.dart';

class MetronomeWidget extends StatefulWidget {
  final MetronomeController controller;

  const MetronomeWidget({super.key, required this.controller});

  @override
  MetronomeWidgetState createState() => MetronomeWidgetState();
}

class MetronomeWidgetState extends State<MetronomeWidget> {
  bool isPlaying = false;
  int bpm = 100;
  String timeSignature = "4/4";
  String bitsPattern = "1/4";

  Timer? _timer;
  bool isTick = false;
  int tickCount = 0;
  int subdivisionMultiplier = 1;
  int beatsPerMeasure = 4;

  final List<DateTime> _tapTimes = [];

  late final MetronomeSoundPlayer _soundPlayer;

  Stopwatch? _stopwatch;

  int _countInBeats =
      4; // Number of silent count-in beats (could match beatsPerMeasure)
  int _countInTick = 0;

  bool isCountInFlash = false;

  // Set this flag to true to enable count-in, or false to disable it.
  static const bool enableCountIn = true;

  // --- Time Signature Picklist ---
  static const List<String> timeSignaturePicklist = [
    '1/2',
    '2/2',
    '3/2',
    '4/2',
    '5/2',
    '6/2',
    '7/2',
    '8/2',
    '9/2',
    '10/2',
    '11/2',
    '12/2',
    '13/2',
    '1/4',
    '2/4',
    '3/4',
    '4/4',
    '5/4',
    '6/4',
    '7/4',
    '8/4',
    '9/4',
    '10/4',
    '11/4',
    '12/4',
    '13/4',
    '3/8',
    '6/8',
    '9/8',
    '12/8',
    '5/8 (3+2)',
    '5/8 (2+3)',
    '7/8 (3+2+2)',
    '7/8 (2+3+2)',
    '7/8 (2+2+3)',
  ];

  // --- Bits Pattern Picklist ---
  static const List<String> bitsPatternPicklist = [
    '1/4', // Quarter note
    '1/8', // Eighth note
    '1/8 triplet', // Eighth note triplet
    '1/16', // Sixteenth note
    // '1/16 triplet', // Sixteenth note triplet
  ];

  @override
  void initState() {
    super.initState();
    widget.controller.attach(
      this,
    ); // Attach the widget's state to the controller
    _parseTimeSignature();
    _parseBitsPattern();
    _soundPlayer = createMetronomeSoundPlayer();
    _soundPlayer.init();
    _stopwatch = Stopwatch();
  }

  @override
  void dispose() {
    _timer?.cancel();
    _stopwatch?.stop();
    isTick = false;
    widget.controller.detach();
    _soundPlayer.dispose();
    super.dispose();
  }

  // Public Method to start the metronome
  void startMetronome() {
    _timer?.cancel();
    tickCount = 0;
    _stopwatch?.reset();
    _stopwatch?.start();
    if (enableCountIn) {
      // Set count-in beats to match the current time signature
      _countInBeats = beatsPerMeasure;
      _countInTick = 0;
      _startCountIn();
    } else {
      _scheduleNextTick();
    }
  }

  void _startCountIn() {
    final int tickIntervalMs = (60000 / bpm / subdivisionMultiplier).round();
    _timer = Timer.periodic(Duration(milliseconds: tickIntervalMs), (timer) {
      _countInTick++;
      setState(() {
        isCountInFlash = true;
      });
      Future.delayed(const Duration(milliseconds: 100), () {
        if (mounted) setState(() => isCountInFlash = false);
      });
      //log.info('Metronome count-in: $_countInTick/$_countInBeats');
      if (_countInTick >= _countInBeats) {
        timer.cancel();
        _stopwatch?.reset();
        _stopwatch?.start();
        _scheduleNextTick();
      }
    });
  }

  // Schedule the next tick based on absolute elapsed time
  void _scheduleNextTick() {
    final int tickIntervalMs = (60000 / bpm / subdivisionMultiplier).round();
    final int elapsed = _stopwatch?.elapsedMilliseconds ?? 0;
    final int nextTick = ((elapsed / tickIntervalMs).ceil()) * tickIntervalMs;
    final int delay = nextTick - elapsed;
    _timer = Timer(Duration(milliseconds: delay), () {
      setState(() {
        tickCount++;
        isTick = true;
      });
      // Play tock on bit 1, tick otherwise
      final bool isDownbeat = ((tickCount - 1) % beatsPerMeasure == 0);
      _playTick(isDownbeat: isDownbeat);
      //log.info(
      //  'Metronome tick at: ${DateTime.now()} (elapsed: ${_stopwatch?.elapsedMilliseconds} ms) [sound: ${isDownbeat ? 'tock' : 'tick'}]',
      // );
      Future.delayed(const Duration(milliseconds: 100), () {
        if (mounted) setState(() => isTick = false);
      });
      if (isPlaying) {
        _scheduleNextTick();
      }
    });
  }

  // Public Method to stop the metronome
  void stopMetronome() {
    _timer?.cancel();
    _stopwatch?.stop();
    if (mounted) {
      setState(() => isTick = false);
    } else {
      isTick = false;
      log.warning(' stopMetronome() called after dispose');
    }
  }

  // Method to set the running state
  void setRunning(bool value) => setState(() => isPlaying = value);

  // Public Method to set the BPM
  void setBpm(int value) => setState(() {
    bpm = value.clamp(40, 208);
    if (isPlaying) {
      stopMetronome();
      startMetronome();
    }
  });

  // Public Method to set the time signature
  void setTimeSignature(String signature) {
    setState(() {
      timeSignature = signature;
      _parseTimeSignature();
      // Update count-in beats to match new time signature
      _countInBeats = beatsPerMeasure;
    });
  }

  // Public Method to set the bits pattern (subdivision)
  void setBitsPattern(String pattern) {
    setState(() {
      bitsPattern = pattern;
      _parseBitsPattern();
      if (isPlaying) {
        stopMetronome();
        startMetronome();
      }
    });
  }

  // Private Method to calculate the interval between beats based on BPM
  void _parseTimeSignature() {
    // Support grouped/compound signatures like '5/8 (3+2)'
    final mainPart = timeSignature.split(' ')[0];
    final parts = mainPart.split('/');
    beatsPerMeasure = int.tryParse(parts[0]) ?? 4;
    // Optionally, parse grouping if needed in the future
  }

  // Private Method to parse the bits pattern (subdivision)
  void _parseBitsPattern() {
    if (bitsPattern == "1/4") {
      subdivisionMultiplier = 1;
    } else if (bitsPattern == "1/8") {
      subdivisionMultiplier = 2;
    } else if (bitsPattern == "1/16") {
      subdivisionMultiplier = 4;
    } else if (bitsPattern.toLowerCase().contains("triplet")) {
      if (bitsPattern.startsWith("1/8")) {
        subdivisionMultiplier = 3;
      } else if (bitsPattern.startsWith("1/16")) {
        subdivisionMultiplier = 6;
      } else {
        subdivisionMultiplier = 3; // fallback for any triplet
      }
    } else {
      subdivisionMultiplier = 1;
    }
  }

  // Private Method for tap tempo to calculate BPM based on user taps
  void tapTempo() {
    final now = DateTime.now();
    _tapTimes.add(now);
    _tapTimes.removeWhere((t) => now.difference(t).inSeconds > 3);

    if (_tapTimes.length >= 2) {
      List<int> intervals = [];
      for (int i = 1; i < _tapTimes.length; i++) {
        intervals.add(_tapTimes[i].difference(_tapTimes[i - 1]).inMilliseconds);
      }
      final avgInterval = intervals.reduce((a, b) => a + b) ~/ intervals.length;
      final bpm = (60000 / avgInterval).round();
      setBpm(bpm);
    }
  }

  // Private Method to show the bottom sheet picker for various options
  Future<void> _pick<T>(
    List<T> values,
    T current,
    Function(T) onSelected,
  ) async {
    final index = values.indexOf(current);
    await showModalBottomSheet(
      context: context,
      builder:
          (_) => SizedBox(
            height: 250,
            child: CupertinoPicker(
              backgroundColor: Colors.white,
              itemExtent: 32,
              scrollController: FixedExtentScrollController(initialItem: index),
              onSelectedItemChanged: (i) => onSelected(values[i]),
              children:
                  values.map((v) => Center(child: Text(v.toString()))).toList(),
            ),
          ),
    );
  }

  // Exposed method for toggling the metronome (start/stop)
  void toggleMetronome() {
    if (isPlaying) {
      stopMetronome();
      setRunning(false);
    } else {
      startMetronome();
      setRunning(true);
    }
  }

  // Exposed methods for incrementing and decrementing BPM
  void incrementBpm() => setBpm(bpm + 1);
  void decrementBpm() => setBpm(bpm - 1);

  Future<void> _playTick({
    double volume = 1.0,
    required bool isDownbeat,
  }) async {
    await _soundPlayer.play(isDownbeat: isDownbeat, volume: volume);
  }

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: Colors.grey.shade900,
        borderRadius: BorderRadius.circular(12),
      ),
      //constraints: const BoxConstraints(minHeight: 80), // ensure enough height
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceEvenly,
            children: [
              IconButton(
                icon: Icon(
                  isPlaying ? Icons.music_note : Icons.music_off,
                  color: Colors.white,
                ),
                onPressed: toggleMetronome,
                tooltip: isPlaying ? 'Metronome On' : 'Metronome Off',
              ),
              IconButton(
                icon: const Icon(Icons.numbers, color: Colors.white),
                tooltip: timeSignature,
                onPressed:
                    () => _pick(
                      timeSignaturePicklist,
                      timeSignature,
                      setTimeSignature,
                    ),
              ),
              IconButton(
                icon: const Icon(Icons.remove, color: Colors.white),
                onPressed: decrementBpm,
              ),
              TextButton(
                onPressed:
                    () =>
                        _pick(List.generate(169, (i) => (i + 40)), bpm, setBpm),
                child: Text(
                  '$bpm',
                  style: const TextStyle(
                    fontSize: 20,
                    fontWeight: FontWeight.bold,
                    color: Colors.white,
                  ),
                ),
              ),
              IconButton(
                icon: const Icon(Icons.add, color: Colors.white),
                onPressed: incrementBpm,
              ),
              IconButton(
                icon: const Icon(Icons.touch_app, color: Colors.white),
                onPressed: tapTempo,
              ),
              IconButton(
                icon: const Icon(Icons.more_horiz, color: Colors.white),
                tooltip: bitsPattern,
                onPressed:
                    () =>
                        _pick(bitsPatternPicklist, bitsPattern, setBitsPattern),
              ),
            ],
          ),
          const SizedBox(height: 8),
          AnimatedOpacity(
            opacity: isPlaying ? 1.0 : 0.0,
            duration: const Duration(milliseconds: 300),
            child: Visibility(
              visible: true,
              maintainSize: true,
              maintainAnimation: true,
              maintainState: true,
              child: SizedBox(
                height: 16,
                child: Row(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: List.generate(beatsPerMeasure, (index) {
                    final isActive =
                        (index == (tickCount - 1) % beatsPerMeasure);
                    return AnimatedContainer(
                      duration: const Duration(milliseconds: 100),
                      margin: const EdgeInsets.symmetric(horizontal: 4),
                      width: 40,
                      height: 8,
                      decoration: BoxDecoration(
                        color:
                            isCountInFlash
                                ? Colors.red
                                : ((tickCount > 0 && isActive)
                                    ? Colors.red
                                    : Colors.grey.shade600),
                        borderRadius: BorderRadius.circular(4),
                      ),
                    );
                  }),
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }
}
