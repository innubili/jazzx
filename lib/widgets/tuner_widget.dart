/*
import 'dart:async';
import 'dart:js_interop';
import 'dart:math' as math;
import 'package:js/js_util.dart' as js_util;
import 'package:js/js.dart';
import 'package:flutter/material.dart';
import 'package:pitch_detector_dart/pitch_detector.dart';
import 'package:web/web.dart' as web;
import 'package:provider/provider.dart';
import '../providers/user_profile_provider.dart';
import '../utils/utils.dart';

const Map<String, List<Map<String, dynamic>>> instrumentTunings = {
  'Guitar': [
    {'note': 'E2', 'freq': 82.41},
    {'note': 'A2', 'freq': 110.00},
    {'note': 'D3', 'freq': 146.83},
    {'note': 'G3', 'freq': 196.00},
    {'note': 'B3', 'freq': 246.94},
    {'note': 'E4', 'freq': 329.63},
  ],
  'Bass': [
    {'note': 'E1', 'freq': 41.20},
    {'note': 'A1', 'freq': 55.00},
    {'note': 'D2', 'freq': 73.42},
    {'note': 'G2', 'freq': 98.00},
  ],
  'Double Bass': [
    {'note': 'E1', 'freq': 41.20},
    {'note': 'A1', 'freq': 55.00},
    {'note': 'D2', 'freq': 73.42},
    {'note': 'G2', 'freq': 98.00},
  ],
  'Violin': [
    {'note': 'G3', 'freq': 196.00},
    {'note': 'D4', 'freq': 293.66},
    {'note': 'A4', 'freq': 440.00},
    {'note': 'E5', 'freq': 659.25},
  ],
  'Cello': [
    {'note': 'C2', 'freq': 65.41},
    {'note': 'G2', 'freq': 98.00},
    {'note': 'D3', 'freq': 146.83},
    {'note': 'A3', 'freq': 220.00},
  ],
  'Clarinet': [
    {'note': 'A4', 'freq': 440.00},
  ],
  'Flute': [
    {'note': 'A4', 'freq': 440.00},
  ],
  'Alto Saxophone': [
    {'note': 'A4', 'freq': 440.00},
  ],
  'Tenor Saxophone': [
    {'note': 'A4', 'freq': 440.00},
  ],
  'Baritone Saxophone': [
    {'note': 'A4', 'freq': 440.00},
  ],
  'Soprano Saxophone': [
    {'note': 'A4', 'freq': 440.00},
  ],
  'Trumpet': [
    {'note': 'A4', 'freq': 440.00},
  ],
  'Trombone': [
    {'note': 'A4', 'freq': 440.00},
  ],
};

const Map<String, String> instrumentTips = {
  'Guitar': 'Strings stretch, affected by temperature/humidity.',
  'Bass': 'Same as guitar (less sensitive, but still tuned).',
  'Double Bass': 'Gut/synthetic strings especially sensitive.',
  'Violin': 'Very sensitive to tuning changes.',
  'Cello': 'Same as violin.',
  'Clarinet': 'Woodwind, affected by temperature (especially upper joint).',
  'Flute': 'Needs embouchure + minor headjoint adjustments.',
  'Alto Saxophone':
      'Tuning via mouthpiece and embouchure—always adjusted before playing.',
  'Tenor Saxophone':
      'Tuning via mouthpiece and embouchure—always adjusted before playing.',
  'Baritone Saxophone':
      'Tuning via mouthpiece and embouchure—always adjusted before playing.',
  'Soprano Saxophone':
      'Tuning via mouthpiece and embouchure—always adjusted before playing.',
  'Trumpet':
      'Brass instruments warm up and shift pitch; tuning slide adjusted.',
  'Trombone': 'Tuning slide and embouchure checked before playing.',
};

class TunerWidget extends StatefulWidget {
  const TunerWidget({super.key});

  @override
  State<TunerWidget> createState() => _TunerWidgetState();
}

class _TunerWidgetState extends State<TunerWidget> {
  PitchDetector? _detector;
  web.AudioContext? _audioContext;
  web.ScriptProcessorNode? _processor;
  bool _listening = false;
  List<String> _userInstruments = [];
  String? _selectedInstrument;
  int? _selectedStringIdx;
  String _detectedNote = '';
  double _detectedFreq = 0.0;
  double _cents = 0.0;

  List<Map<String, dynamic>>? get _currentTuningPreset {
    if (_selectedInstrument == null) return null;
    return instrumentTunings[_selectedInstrument!];
  }

  bool get _isStringInstrument {
    return [
      'Guitar',
      'Bass',
      'Double Bass',
      'Violin',
      'Cello',
    ].contains(_selectedInstrument);
  }

  DateTime? _lastUpdateTime;
  final int _minUpdateIntervalMs = 50; // Only update at most every 50ms

  // Store timing logs in memory
  final List<int> _updateTimestamps = [];

  // Track time between pressing start and effective audio processing
  DateTime? _startButtonPressedTime;
  DateTime? _firstAudioProcessTime;

  void _prewarmAudioContext() {
    _audioContext ??= web.AudioContext();
    log.info(
      '[PROFILE] AudioContext prewarmed at: ${DateTime.now().toIso8601String()}',
    );
  }

  @override
  void initState() {
    super.initState();
    // Detector will be initialized after AudioContext is ready, with correct sample rate
    _prewarmAudioContext();
  }

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    final profileProvider = Provider.of<UserProfileProvider>(
      context,
      listen: false,
    );
    final instruments = profileProvider.profile?.preferences.instruments ?? [];
    _userInstruments =
        instruments
            .where(
              (i) =>
                  !i.toLowerCase().contains('piano') &&
                  !i.toLowerCase().contains('keyboard'),
            )
            .toList();
    // If the user has no non-piano/keyboard instruments, show the card message as before
    if (_userInstruments.isEmpty) {
      _selectedInstrument = null;
    } else if (_userInstruments.length == 1) {
      _selectedInstrument = _userInstruments.first;
    } else if (_selectedInstrument == null ||
        !_userInstruments.contains(_selectedInstrument)) {
      // If we have a previously selected instrument in preferences, use it
      final preferred = instruments.firstWhere(
        (i) => _userInstruments.contains(i),
        orElse: () => _userInstruments.first,
      );
      _selectedInstrument = preferred;
    }
    _selectedStringIdx = null;
  }

  Future<void> _startListening() async {
    if (_listening) return;
    _startButtonPressedTime = DateTime.now();
    _firstAudioProcessTime = null;
    _listening = true;
    _updateTimestamps.clear(); // Clear timing log when starting
    log.info(
      '[PROFILE] Start button pressed at: ${_startButtonPressedTime!.toIso8601String()}',
    );
    final constraints = js_util.jsify({'audio': true});
    final getUserMediaStart = DateTime.now();
    log.info(
      '[PROFILE] getUserMedia requested at: ${getUserMediaStart.toIso8601String()}',
    );
    final promise = web.window.navigator.mediaDevices.getUserMedia(constraints);
    final stream = await promise.toDart;
    final getUserMediaEnd = DateTime.now();
    log.info(
      '[PROFILE] getUserMedia resolved at: ${getUserMediaEnd.toIso8601String()} (delta: ${getUserMediaEnd.difference(getUserMediaStart).inMilliseconds}ms)',
    );
    // If prewarmed, resume if needed
    if (_audioContext == null) {
      _audioContext = web.AudioContext();
      log.info(
        '[PROFILE] AudioContext created at: ${DateTime.now().toIso8601String()}',
      );
    } else if (_audioContext!.state == 'suspended') {
      await js_util.promiseToFuture(_audioContext!.resume());
      log.info(
        '[PROFILE] AudioContext resumed at: ${DateTime.now().toIso8601String()}',
      );
    }
    // Always (re)initialize PitchDetector with the actual sample rate and buffer size
    final sampleRate = js_util.getProperty<double>(
      _audioContext!,
      'sampleRate',
    );
    log.info('[DEBUG] Using sample rate for PitchDetector: $sampleRate');
    _detector = PitchDetector(audioSampleRate: sampleRate, bufferSize: 2048);
    final source = _audioContext?.createMediaStreamSource(stream);
    // Use a buffer size of 2048 for compatibility with pitch detection
    _processor = _audioContext?.createScriptProcessor(2048, 1, 1);

    if (_processor != null) {
      js_util.setProperty(
        _processor!,
        'onaudioprocess',
        allowInterop((web.AudioProcessingEvent audioEvent) {
          // Log every audio process event
          // log.info(
          //   '[PROFILE] onaudioprocess event at: ${DateTime.now().toIso8601String()}',
          // );
          if (_firstAudioProcessTime == null) {
            _firstAudioProcessTime = DateTime.now();
            if (_startButtonPressedTime != null) {
              final diff =
                  _firstAudioProcessTime!
                      .difference(_startButtonPressedTime!)
                      .inMilliseconds;
              log.info(
                '[DEBUG] Time from start button to first audio process: ${diff}ms',
              );
              log.info(
                '[PROFILE] First audio process at: ${_firstAudioProcessTime!.toIso8601String()} (delta from getUserMedia resolved: ${_firstAudioProcessTime!.difference(getUserMediaEnd).inMilliseconds}ms)',
              );
            }
          }
          final inputBuffer = audioEvent.inputBuffer;
          final inputData = inputBuffer.getChannelData(0);
          final length = js_util.getProperty<int>(inputData, 'length');
          final samples = List<double>.generate(
            length,
            (i) => js_util.callMethod(inputData, 'at', [i]) as double,
          );
          // Only process if buffer is exactly 2048 samples (required by pitch_detector_dart)
          if (samples.length != 2048) {
            log.info(
              '[DEBUG] Skipping pitch detection: buffer size = ${samples.length}, required = 2048',
            );
            return;
          }
          // Log buffer stats for diagnostics
          final minSample = samples.reduce((a, b) => a < b ? a : b);
          final maxSample = samples.reduce((a, b) => a > b ? a : b);
          final first10 = samples.take(10).toList();
          final hasNaN = samples.any((v) => v.isNaN);
          final hasInf = samples.any((v) => v.isInfinite);
          final allZero = samples.every((v) => v == 0.0);

          // Amplitude threshold for noise handling
          // If the maximum absolute value is too low, treat as silence/noise and skip pitch detection
          final amplitudeThreshold =
              0.01; // You can tune this value (0.01 = -40dBFS)
          final maxAbs = samples.map((v) => v.abs()).reduce(math.max);

          // log.info('[DEBUG] Buffer stats: min=$minSample, max=$maxSample, first10=$first10, hasNaN=$hasNaN, hasInf=$hasInf, allZero=$allZero, maxAbs=$maxAbs',);
          if (hasNaN || hasInf || allZero || maxAbs < amplitudeThreshold) {
            //  log.info(
            //    '[DEBUG] Skipping pitch detection due to invalid buffer or low amplitude (noise/silence)',
            //  );
            return;
          }
          try {
            _detector?.getPitchFromFloatBuffer(samples).then((result) {
              // Log every pitch detection attempt
              // log.info(
              //   '[PROFILE] Pitch detection result: pitched=${result.pitched}, pitch=${result.pitch}',
              // );
              if (result.pitched) {
                final noteData = _findClosestNote(result.pitch);
                final now = DateTime.now();
                // Throttle: Only update at most every _minUpdateIntervalMs ms
                if (_lastUpdateTime != null &&
                    now.difference(_lastUpdateTime!).inMilliseconds <
                        _minUpdateIntervalMs) {
                  return;
                }
                // Optionally: Only update if values changed significantly
                // (Temporarily relax this logic for diagnostics)
                // final double newCents = _calculateCents(
                //   result.pitch,
                //   noteData['freq'] as double,
                // );
                // if ((_detectedNote == noteData['note'] as String) &&
                //     (_detectedFreq - result.pitch).abs() < 0.5 &&
                //     (_cents - newCents).abs() < 1) {
                //   return;
                // }
                _lastUpdateTime = now;
                // Log the timestamp (milliseconds since epoch)
                _updateTimestamps.add(now.millisecondsSinceEpoch);
                setState(() {
                  _detectedNote = noteData['note'] as String;
                  _detectedFreq = result.pitch;
                  _cents = _calculateCents(
                    result.pitch,
                    noteData['freq'] as double,
                  );
                });
              }
            });
          } catch (e, st) {
            log.info('[ERROR] Pitch detection error: $e\n$st');
          }
        }),
      );
    }

    if (source != null && _processor != null) {
      js_util.callMethod(source, 'connect', [_processor!]);
    }
    if (_processor != null && _audioContext?.destination != null) {
      js_util.callMethod(_processor!, 'connect', [_audioContext!.destination]);
    }
  }

  void _stopListening() {
    log.info('[DEBUG] _stopListening called');
    try {
      _processor?.disconnect();
      // Attempt to remove JS event handler if possible
      if (_processor != null) {
        try {
          js_util.setProperty(_processor!, 'onaudioprocess', null);
        } catch (e) {
          log.info('[DEBUG] Failed to remove onaudioprocess handler: $e');
        }
      }
      _processor = null;
      _audioContext != null
          ? js_util
              .promiseToFuture(_audioContext!.close())
              .then((_) {
                log.info('[DEBUG] AudioContext closed');
                _audioContext = null;
              })
              .catchError((e) {
                log.info('[DEBUG] AudioContext close error: $e');
              })
          : null;
      _lastUpdateTime = null;
      // log.info the timing log when stopping
      if (_updateTimestamps.isNotEmpty) {
        final List<int> diffs = [];
        for (int i = 1; i < _updateTimestamps.length; i++) {
          diffs.add(_updateTimestamps[i] - _updateTimestamps[i - 1]);
        }
        log.info('Tuner update timings (ms between updates): $diffs');
        log.info('Total updates: ${_updateTimestamps.length}');
      }
      setState(() {
        _listening = false;
        _detectedNote = '';
        _detectedFreq = 0.0;
        _cents = 0.0;
      });
    } catch (e, st) {
      log.info('[DEBUG] Error in _stopListening: $e\n$st');
    }
  }

  Map<String, Object> _findClosestNote(double freq) {
    final notes = _currentTuningPreset;
    if (notes == null || notes.isEmpty) {
      return {'note': '', 'freq': 0.0};
    }
    if (_isStringInstrument && _selectedStringIdx != null) {
      final note = notes[_selectedStringIdx!];
      return Map<String, Object>.from(note);
    }
    Map<String, Object> closest = Map<String, Object>.from(notes.first);
    double minDiff = (freq - (closest['freq'] as double)).abs();
    for (int i = 0; i < notes.length; i++) {
      final noteObj = Map<String, Object>.from(notes[i]);
      final diff = (freq - (noteObj['freq'] as double)).abs();
      if (diff < minDiff) {
        closest = noteObj;
        minDiff = diff;
        if (_isStringInstrument) {
          _selectedStringIdx = i;
        }
      }
    }
    return closest;
  }

  double _calculateCents(double freq, double refFreq) {
    return 1200 *
        (freq > 0 && refFreq > 0 ? (math.log(freq / refFreq) / math.ln2) : 0);
  }

  @override
  void dispose() {
    log.info('[DEBUG] dispose called');
    _stopListening();
    super.dispose();
    log.info('[DEBUG] super.dispose finished');
  }

  @override
  Widget build(BuildContext context) {
    final userProfileProvider = Provider.of<UserProfileProvider>(context);
    _userInstruments =
        userProfileProvider.profile?.preferences.instruments ?? [];
    _selectedInstrument ??=
        _userInstruments.isNotEmpty
            ? _userInstruments.first
            : instrumentTunings.keys.first;
    final notes = _currentTuningPreset ?? [];
    // final reversedNotes = List<Map<String, dynamic>>.from(notes.reversed);

    // Instrument label/selector with tooltip
    Widget instrumentLabel = Tooltip(
      message: instrumentTips[_selectedInstrument ?? ''] ?? '',
      child:
          _userInstruments.length > 1
              ? DropdownButton<String>(
                value: _selectedInstrument,
                items:
                    _userInstruments
                        .map(
                          (instr) => DropdownMenuItem<String>(
                            value: instr,
                            child: Text(instr),
                          ),
                        )
                        .toList(),
                onChanged: (value) {
                  setState(() {
                    _selectedInstrument = value;
                    _selectedStringIdx = null;
                  });
                },
                underline: const SizedBox.shrink(),
              )
              : Text(
                _selectedInstrument!,
                style: Theme.of(context).textTheme.titleSmall,
              ),
    );

    // --- Note selector row (centered, metronome style, tooltips, manual only, no Auto) ---
    Widget noteSelector = const SizedBox.shrink();
    if (_isStringInstrument && notes.isNotEmpty) {
      int? matchedIdx;
      if (_detectedNote.isNotEmpty) {
        for (int i = 0; i < notes.length; i++) {
          if (notes[i]['note'] == _detectedNote) {
            matchedIdx = i;
            break;
          }
        }
      }
      noteSelector = Row(
        mainAxisAlignment: MainAxisAlignment.center,
        mainAxisSize: MainAxisSize.min,
        children: List.generate(notes.length, (idx) {
          final note = notes[idx]['note'] as String;
          final selected = idx == _selectedStringIdx;
          final matched = matchedIdx == idx;
          // Color logic
          Color? highlightColor;
          Color? textColor = Colors.black;
          if (matched) {
            final cents = _cents.abs();
            if (cents < 10) {
              highlightColor = Colors.green.withValues(
                red: Colors.green.r.toDouble(),
                green: Colors.green.g.toDouble(),
                blue: Colors.green.b.toDouble(),
                alpha: 0.25 * 255,
              );
              textColor = Colors.green;
            } else if (cents < 25) {
              highlightColor = Colors.orange.withValues(
                red: Colors.orange.r.toDouble(),
                green: Colors.orange.g.toDouble(),
                blue: Colors.orange.b.toDouble(),
                alpha: 0.25 * 255,
              );
              textColor = Colors.orange;
            } else {
              highlightColor = Colors.red.withValues(
                red: Colors.red.r.toDouble(),
                green: Colors.red.g.toDouble(),
                blue: Colors.red.b.toDouble(),
                alpha: 0.25 * 255,
              );
              textColor = Colors.red;
            }
          }
          if (selected) {
            final primary = Theme.of(context).colorScheme.primary;
            highlightColor = primary.withValues(
              red: primary.r.toDouble(),
              green: primary.g.toDouble(),
              blue: primary.b.toDouble(),
              alpha: 0.25 * 255,
            );
            textColor = Theme.of(context).colorScheme.primary;
          }
          return Tooltip(
            message: 'String ${notes.length - idx}: $note',
            child: GestureDetector(
              onTap: () {
                setState(() {
                  if (_selectedStringIdx == idx) {
                    _selectedStringIdx =
                        null; // Deselect for auto mode (no highlight)
                    log.info('[DEBUG] Tuner mode changed: AUTO');
                  } else {
                    _selectedStringIdx = idx;
                    log.info(
                      '[DEBUG] Tuner mode changed: SELECTED NOTE ($note)',
                    );
                  }
                });
              },
              child: AnimatedContainer(
                duration: const Duration(milliseconds: 120),
                padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                margin: const EdgeInsets.symmetric(horizontal: 2),
                decoration: BoxDecoration(
                  color: highlightColor ?? Colors.transparent,
                  borderRadius: BorderRadius.circular(8),
                ),
                child: Text(
                  note,
                  style: TextStyle(
                    fontWeight: selected ? FontWeight.bold : FontWeight.normal,
                    color: textColor,
                    fontSize: 16,
                  ),
                ),
              ),
            ),
          );
        }),
      );
    }

    // --- Indicator bar (metronome style, gradient, responsive) ---
    int activeIdx = ((_cents + 50) / 100 * 8).round();
    activeIdx = activeIdx.clamp(0, 8);

    // --- Main tuner card layout ---
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 10),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: Colors.grey.shade300),
      ),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          // Controls row: mic, note selector, instrument label
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            crossAxisAlignment: CrossAxisAlignment.center,
            children: [
              Padding(
                padding: const EdgeInsets.only(left: 4),
                child: Tooltip(
                  message: _listening ? 'Stop Tuner' : 'Start Tuner',
                  child: IconButton(
                    icon: Icon(
                      _listening ? Icons.mic : Icons.mic_off,
                      color:
                          _listening
                              ? Theme.of(context).colorScheme.primary
                              : Colors.grey,
                    ),
                    onPressed: _listening ? _stopListening : _startListening,
                    tooltip: _listening ? 'Stop Tuner' : 'Start Tuner',
                    padding: EdgeInsets.zero,
                    constraints: const BoxConstraints(
                      minWidth: 36,
                      minHeight: 36,
                    ),
                  ),
                ),
              ),
              Expanded(child: Center(child: noteSelector)),
              Padding(
                padding: const EdgeInsets.only(right: 4),
                child: instrumentLabel,
              ),
            ],
          ),
          const SizedBox(height: 8),
          // Indicator row: show only flat/sharp icons, with same insets as row 1
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            crossAxisAlignment: CrossAxisAlignment.center,
            children: [
              Padding(
                padding: const EdgeInsets.only(left: 20),
                child: Text(
                  '♭',
                  style: TextStyle(color: Colors.grey, fontSize: 20),
                ),
              ),
              Expanded(child: GradientIndicatorBar(activeIdx: activeIdx)),
              Padding(
                padding: const EdgeInsets.only(right: 16),
                child: Text(
                  '#',
                  style: TextStyle(color: Colors.grey, fontSize: 20),
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }
}

// --- Efficient, stateful indicator bar ---
class GradientIndicatorBar extends StatefulWidget {
  final int activeIdx;
  final int segments;
  final double height;
  final double horizontalPadding;
  const GradientIndicatorBar({
    super.key,
    required this.activeIdx,
    this.segments = 9,
    this.height = 28,
    this.horizontalPadding = 36, // 20+16
  });

  @override
  State<GradientIndicatorBar> createState() => _GradientIndicatorBarState();
}

class _GradientIndicatorBarState extends State<GradientIndicatorBar> {
  double? _cachedWidth;

  @override
  Widget build(BuildContext context) {
    return LayoutBuilder(
      builder: (context, constraints) {
        final width = (constraints.maxWidth - widget.horizontalPadding).clamp(
          0.0,
          double.infinity,
        );
        if (_cachedWidth != width) {
          _cachedWidth = width;
        }
        return Container(
          width: width,
          height: widget.height,
          alignment: Alignment.center,
          decoration: BoxDecoration(borderRadius: BorderRadius.circular(8)),
          child: Row(
            mainAxisAlignment: MainAxisAlignment.center,
            children: _buildIndicatorSegments(width),
          ),
        );
      },
    );
  }

  List<Widget> _buildIndicatorSegments(double width) {
    final int segments = widget.segments;
    final int activeIdx = widget.activeIdx;
    final double segmentWidth = (width - 16 * (segments - 1)) / segments;
    List<Color> gradientColors = [
      Colors.red,
      Colors.orange,
      Colors.yellow,
      Colors.lightGreen,
      Colors.green,
      Colors.lightGreen,
      Colors.yellow,
      Colors.orange,
      Colors.red,
    ];
    return List.generate(segments, (i) {
      final bool isActive = i == activeIdx;
      Color color = gradientColors[i];
      return AnimatedContainer(
        duration: const Duration(milliseconds: 120),
        margin: const EdgeInsets.symmetric(horizontal: 8),
        width: segmentWidth,
        height: isActive ? 14 : 10,
        decoration: BoxDecoration(
          color:
              isActive
                  ? color
                  : color.withValues(
                    red: color.r.toDouble(),
                    green: color.g.toDouble(),
                    blue: color.b.toDouble(),
                    alpha: 0.25 * 255,
                  ),
          borderRadius: BorderRadius.circular(4),
          border: isActive ? Border.all(color: Colors.black12, width: 1) : null,
        ),
      );
    });
  }
}
*/
