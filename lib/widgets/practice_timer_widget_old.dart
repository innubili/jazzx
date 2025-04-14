import 'package:flutter/material.dart';
import '../utils/log.dart';

class PracticeTimerController {
  VoidCallback? start;
  VoidCallback? stop;
  VoidCallback? reset;
  void Function({required int startFrom, bool countDown})? startCount;

  int elapsedSeconds = 0;
}

class PracticeTimerWidget extends StatefulWidget {
  final String practiceCategory;
  final PracticeTimerController controller;
  final VoidCallback? onStopped;
  final VoidCallback? onCountComplete;
  final VoidCallback? onSessionDone;
  final Widget? leftButton;
  final bool enabled;

  const PracticeTimerWidget({
    super.key,
    required this.practiceCategory,
    required this.controller,
    this.onStopped,
    this.onCountComplete,
    this.onSessionDone,
    this.leftButton,
    this.enabled = true,
  });

  @override
  State<PracticeTimerWidget> createState() => _PracticeTimerWidgetState();
}

class _PracticeTimerWidgetState extends State<PracticeTimerWidget> {
  late Stopwatch _stopwatch;
  late final Ticker _ticker;
  Duration _elapsed = Duration.zero;
  int? _countFrom;
  bool _isRunning = false;
  bool _isCounting = false;

  @override
  void initState() {
    super.initState();
    _stopwatch = Stopwatch();
    _ticker = Ticker(_onTick);

    widget.controller.start = start;
    widget.controller.stop = stop;
    widget.controller.reset = reset;
    widget.controller.startCount = ({
      required int startFrom,
      bool countDown = false,
    }) {
      _ticker.reset(); // 🛠️ 1. reset ticker first

      _stopwatch.reset(); // 🛠️ 2. reset stopwatch
      _stopwatch.start(); // 🛠️ 3. start fresh

      _countFrom = startFrom;
      _isCounting = countDown;
      _elapsed = Duration(seconds: startFrom);
      widget.controller.elapsedSeconds = startFrom;

      _ticker.start(); // 🛠️ 4. now start ticker

      setState(() => _isRunning = true);
    };
  }

  void _onTick(Duration ticked) {
    if (!mounted) return;

    final elapsed = ticked;
    widget.controller.elapsedSeconds = elapsed.inSeconds;

    log.info(
      "⏳ Tick: stopwatch = ${elapsed.inSeconds}s, _startFrom = ${_countFrom ?? 0}, total = ${(_countFrom ?? 0) + elapsed.inSeconds}s",
    );

    setState(() {
      _elapsed = elapsed;
    });

    if (_isCounting && _countFrom != null) {
      final remaining = _countFrom! - elapsed.inSeconds;
      if (remaining <= 0) {
        stop();
        widget.onCountComplete?.call();
      }
    }
  }

  void start() {
    _stopwatch.start();
    _ticker.start();
    setState(() => _isRunning = true);
  }

  void stop() {
    if (!_isRunning) return;

    try {
      _stopwatch.stop();
      _ticker.stop();
      if (mounted) {
        setState(() => _isRunning = false);
      }
      widget.onStopped?.call();
    } catch (e) {
      log.warning("Error in PracticeTimerWidget.stop(): $e");
    }
  }

  void reset() {
    _stopwatch.reset();
    _elapsed = Duration.zero;
    if (mounted) {
      setState(() {});
    }
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
    final displayTime =
        _isCounting && _countFrom != null
            ? Duration(
              seconds: (_countFrom! - _elapsed.inSeconds).clamp(0, _countFrom!),
            )
            : _elapsed;

    return Column(
      mainAxisSize: MainAxisSize.min,
      children: [
        const SizedBox(height: 8),
        Text(
          _formatTime(displayTime),
          style: const TextStyle(fontSize: 36, fontWeight: FontWeight.bold),
        ),
        const SizedBox(height: 8),
        Row(
          crossAxisAlignment: CrossAxisAlignment.end,
          children: [
            Expanded(
              child: Align(
                alignment: Alignment.bottomCenter,
                child: widget.leftButton ?? const SizedBox.shrink(),
              ),
            ),
            SizedBox(
              width: 72,
              height: 72,
              child: RawMaterialButton(
                onPressed: widget.enabled ? (_isRunning ? stop : start) : null,
                shape: const CircleBorder(),
                fillColor: Theme.of(context).colorScheme.secondaryContainer,
                child: Icon(
                  _isRunning ? Icons.pause : Icons.play_arrow,
                  size: 36,
                ),
              ),
            ),
            Expanded(
              child: Align(
                alignment: Alignment.bottomCenter,
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    IconButton(
                      icon: const Icon(Icons.done_all_outlined),
                      onPressed: widget.onSessionDone,
                    ),
                    const Text("Done"),
                  ],
                ),
              ),
            ),
          ],
        ),
      ],
    );
  }
}

class Ticker {
  final void Function(Duration) onTick;
  final Duration _interval = const Duration(seconds: 1);
  bool _running = false;
  Stopwatch? _tickerStopwatch;

  Ticker(this.onTick);

  void start() {
    if (_running) return;
    _running = true;
    _tickerStopwatch = Stopwatch()..start();
    _tick();
  }

  void stop() {
    _running = false;
    _tickerStopwatch?.stop();
    _tickerStopwatch = null;
  }

  void dispose() {
    stop();
  }

  void reset() {
    _tickerStopwatch?.stop();
    _tickerStopwatch?.reset();
    _tickerStopwatch = Stopwatch(); // 🛠️ Force fresh instance
  }

  Future<void> _tick() async {
    while (_running) {
      await Future.delayed(_interval);
      if (_running) onTick(_tickerStopwatch?.elapsed ?? Duration.zero);
    }
  }
}
