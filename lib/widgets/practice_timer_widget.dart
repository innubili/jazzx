// Practice Timer Widget with play/pause and 'Done' functionality
// Tracks time, supports countdown and provides callbacks for stop, completion, and done

import 'package:flutter/material.dart';

class PracticeTimerController {
  VoidCallback? start;
  VoidCallback? stop;
  VoidCallback? reset;
  void Function(int seconds)? startCountdown;

  int elapsedSeconds = 0;
}

class PracticeTimerWidget extends StatefulWidget {
  final String practiceCategory;
  final PracticeTimerController controller;
  final VoidCallback? onStopped;
  final VoidCallback? onCountdownComplete;
  final VoidCallback? onSessionDone;
  final int? countdownSeconds;

  const PracticeTimerWidget({
    super.key,
    required this.practiceCategory,
    required this.controller,
    this.onStopped,
    this.onCountdownComplete,
    this.onSessionDone,
    this.countdownSeconds,
  });

  @override
  State<PracticeTimerWidget> createState() => _PracticeTimerWidgetState();
}

class _PracticeTimerWidgetState extends State<PracticeTimerWidget> {
  late Stopwatch _stopwatch;
  late final Ticker _ticker;
  Duration _elapsed = Duration.zero;
  int? _countdownFrom;
  bool _isRunning = false;
  bool _isCountdown = false;

  @override
  void initState() {
    super.initState();
    _stopwatch = Stopwatch();
    _ticker = Ticker(_onTick);

    widget.controller.start = start;
    widget.controller.stop = stop;
    widget.controller.reset = reset;
    widget.controller.startCountdown = (seconds) {
      _countdownFrom = seconds;
      _isCountdown = true;
      start();
    };
  }

  void _onTick(Duration _) {
    setState(() {
      _elapsed = _stopwatch.elapsed;
    });

    widget.controller.elapsedSeconds = _elapsed.inSeconds;

    if (_isCountdown && _countdownFrom != null) {
      final remaining = _countdownFrom! - _elapsed.inSeconds;
      if (remaining <= 0) {
        stop();
        widget.onCountdownComplete?.call();
      }
    }
  }

  void start() {
    _stopwatch.start();
    _ticker.start();
    setState(() => _isRunning = true);
  }

  void stop() {
    _stopwatch.stop();
    _ticker.stop();
    setState(() => _isRunning = false);
    widget.onStopped?.call();
  }

  void reset() {
    _stopwatch.reset();
    _elapsed = Duration.zero;
    setState(() {});
  }

  String _formatTime(Duration d) {
    final h = d.inHours.toString().padLeft(2, '0');
    final m = (d.inMinutes % 60).toString().padLeft(2, '0');
    final s = (d.inSeconds % 60).toString().padLeft(2, '0');
    return "$h:$m:$s";
  }

  @override
  void dispose() {
    _ticker.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final displayTime = _isCountdown && _countdownFrom != null
        ? Duration(seconds: (_countdownFrom! - _elapsed.inSeconds).clamp(0, _countdownFrom!))
        : _elapsed;

    return Column(
      mainAxisSize: MainAxisSize.min,
      children: [
        Text(widget.practiceCategory, style: const TextStyle(fontSize: 20)),
        const SizedBox(height: 8),
        Text(
          _formatTime(displayTime),
          style: const TextStyle(fontSize: 36, fontWeight: FontWeight.bold),
        ),
        const SizedBox(height: 8),
        Row(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            IconButton(
              icon: Icon(_isRunning ? Icons.pause : Icons.play_arrow, size: 32),
              onPressed: _isRunning ? stop : start,
            ),
            const SizedBox(width: 16),
            TextButton.icon(
              icon: const Icon(Icons.timer_check_outlined),
              label: const Text("Done"),
              onPressed: widget.onSessionDone,
            )
          ],
        ),
      ],
    );
  }
}

class Ticker {
  final void Function(Duration) onTick;
  Duration _interval = const Duration(seconds: 1);
  bool _running = false;
  late final Stopwatch _tickerStopwatch;

  Ticker(this.onTick);

  void start() {
    if (_running) return;
    _running = true;
    _tickerStopwatch = Stopwatch()..start();
    _tick();
  }

  void stop() {
    _running = false;
    _tickerStopwatch.stop();
  }

  void dispose() {
    stop();
  }

  Future<void> _tick() async {
    while (_running) {
      await Future.delayed(_interval);
      if (_running) onTick(_tickerStopwatch.elapsed);
    }
  }
}