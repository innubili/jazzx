import 'package:flutter/material.dart';

class PracticeTimerController {
  void Function({required int startFrom, bool countDown})? startCount;
  void Function()? stop;
  void Function()? reset;

  int _elapsedSeconds = 0;

  void updateElapsed(int seconds) {
    _elapsedSeconds = seconds;
  }

  int getElapsedSeconds() => _elapsedSeconds;
}

class PracticeTimerWidget extends StatefulWidget {
  final String practiceCategory;
  final PracticeTimerController controller;
  final void Function(int elapsedSeconds)? onStopped;
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
  final Stopwatch _stopwatch = Stopwatch();
  Ticker? _ticker;
  Duration _initialOffset = Duration.zero;
  int _startFrom = 0;
  bool _isCounting = false;
  bool _isRunning = false;

  Duration get _elapsed => _initialOffset + _stopwatch.elapsed;

  @override
  void initState() {
    super.initState();

    widget.controller.startCount = ({
      required int startFrom,
      bool countDown = false,
    }) {
      _ticker?.stop();
      _startFrom = startFrom;
      _isCounting = countDown;
      _initialOffset = countDown ? Duration.zero : Duration(seconds: startFrom);

      _stopwatch.reset();
      _stopwatch.start();
      _ticker = Ticker(_onTick)..start();

      // log.info("🕒 TimerWidget: startCount called at ${DateTime.now()}, startFrom: $_startFrom, countDown: $_isCounting",);

      setState(() => _isRunning = true);
    };

    widget.controller.stop = () {
      if (!_isRunning) return;
      _stopwatch.stop();
      _ticker?.stop();
      final elapsedSecs = _elapsed.inSeconds;
      widget.controller.updateElapsed(elapsedSecs);
      widget.onStopped?.call(elapsedSecs);
      setState(() => _isRunning = false);
    };

    widget.controller.reset = () {
      _stopwatch.reset();
      _ticker?.stop();
      _initialOffset = Duration.zero;
      widget.controller.updateElapsed(0);
      setState(() => _isRunning = false);
    };
  }

  void _onTick() {
    if (!mounted) return;

    final seconds = _elapsed.inSeconds;
    //final display = _isCounting ? (_startFrom - seconds).clamp(0, _startFrom) : seconds;

    widget.controller.updateElapsed(seconds);

    //log.info("⏱ Tick: elapsed=${seconds}s, display=${_formatTime(Duration(seconds: display))}",);

    if (_isCounting && seconds >= _startFrom) {
      widget.controller.stop?.call();
      widget.onCountComplete?.call();
    }

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
    _ticker?.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final seconds = _elapsed.inSeconds;
    final display =
        _isCounting
            ? Duration(seconds: (_startFrom - seconds).clamp(0, _startFrom))
            : _elapsed;

    return Column(
      mainAxisSize: MainAxisSize.min,
      children: [
        const SizedBox(height: 8),
        Text(
          _formatTime(display),
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
                onPressed:
                    widget.enabled
                        ? (_isRunning
                            ? () => widget.controller.stop?.call()
                            : () => widget.controller.startCount?.call(
                              startFrom: widget.controller.getElapsedSeconds(),
                              countDown: false,
                            ))
                        : null,
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
  final Duration _interval = const Duration(seconds: 1);
  final VoidCallback onTick;
  bool _running = false;

  Ticker(this.onTick);

  void start() async {
    if (_running) return;
    _running = true;
    while (_running) {
      await Future.delayed(_interval);
      if (_running) onTick();
    }
  }

  void stop() => _running = false;
  void dispose() => stop();
}
