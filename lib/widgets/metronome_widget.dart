import 'dart:async';
import 'package:flutter/material.dart';
import 'package:flutter/cupertino.dart';
import 'metronome_controller.dart';

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

  @override
  void initState() {
    super.initState();
    widget.controller.attach(this);  // Attach the widget's state to the controller
    _parseTimeSignature();
    _parseBitsPattern();
  }

  @override
  void dispose() {
    stopMetronome();
    widget.controller.detach();  // Detach the widget's state from the controller
    super.dispose();
  }

  Duration get _interval => Duration(milliseconds: (60000 / bpm / subdivisionMultiplier).round());

  // Public Method to start the metronome
  void startMetronome() {
    _timer?.cancel();
    tickCount = 0;
    _timer = Timer.periodic(_interval, (timer) {
      setState(() {
        tickCount++;
        isTick = true;
      });
      Future.delayed(Duration(milliseconds: 100), () {
        if (mounted) setState(() => isTick = false);
      });
    });
  }

  // Public Method to stop the metronome
  void stopMetronome() {
    _timer?.cancel();
    setState(() => isTick = false);
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
    final parts = timeSignature.split('/');
    beatsPerMeasure = int.tryParse(parts[0]) ?? 4;
  }

  // Private Method to parse the bits pattern (subdivision)
  void _parseBitsPattern() {
    if (bitsPattern == "1/4") subdivisionMultiplier = 1;
    else if (bitsPattern == "1/8") subdivisionMultiplier = 2;
    else if (bitsPattern.toLowerCase().contains("triplet")) subdivisionMultiplier = 3;
    else subdivisionMultiplier = 1;
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
  Future<void> _pick<T>(List<T> values, T current, Function(T) onSelected) async {
    final index = values.indexOf(current);
    await showModalBottomSheet(
      context: context,
      builder: (_) => Container(
        height: 250,
        child: CupertinoPicker(
          backgroundColor: Colors.white,
          itemExtent: 32,
          scrollController: FixedExtentScrollController(initialItem: index),
          onSelectedItemChanged: (i) => onSelected(values[i]),
          children: values.map((v) => Center(child: Text(v.toString()))).toList(),
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

  @override
  Widget build(BuildContext context) {
    return Column(
      children: [
        Row(
          mainAxisAlignment: MainAxisAlignment.spaceEvenly,
          children: [
            IconButton(
              icon: Icon(
                isPlaying ? Icons.music_note : Icons.music_off,
                color: isPlaying ? Colors.green : Colors.grey,
              ),
              onPressed: toggleMetronome,
            ),
            ElevatedButton(
              onPressed: () => _pick(
                ["1/2", "2/3", "3/4", "4/4", "5/4", "6/8"],
                timeSignature,
                setTimeSignature,
              ),
              child: Text(timeSignature),
            ),
            IconButton(
              icon: Icon(Icons.remove),
              onPressed: decrementBpm,
            ),
            ElevatedButton(
              onPressed: () => _pick(
                List.generate(169, (i) => (i + 40)),
                bpm,
                setBpm,
              ),
              child: Text(
                '$bpm',
                style: TextStyle(fontSize: 20, fontWeight: FontWeight.bold),
              ),
            ),
            IconButton(
              icon: Icon(Icons.add),
              onPressed: incrementBpm,
            ),
            IconButton(
              icon: Icon(Icons.touch_app),
              onPressed: tapTempo,
            ),
            ElevatedButton(
              onPressed: () => _pick(
                ["1/4", "1/8", "Triplets"],
                bitsPattern,
                setBitsPattern,
              ),
              child: Text(bitsPattern),
            ),
          ],
        ),
        AnimatedOpacity(
          opacity: isTick ? 1.0 : 0.0,
          duration: Duration(milliseconds: 100),
          child: Icon(Icons.circle, color: Colors.red, size: 40),
        ),
      ],
    );
  }
}
