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

const Map<String, List<Map<String, dynamic>>> instrumentTunings = {
  'Guitar': [
    {'note': 'E4', 'freq': 329.63},
    {'note': 'B3', 'freq': 246.94},
    {'note': 'G3', 'freq': 196.00},
    {'note': 'D3', 'freq': 146.83},
    {'note': 'A2', 'freq': 110.00},
    {'note': 'E2', 'freq': 82.41},
  ],
  'Bass': [
    {'note': 'G2', 'freq': 98.00},
    {'note': 'D2', 'freq': 73.42},
    {'note': 'A1', 'freq': 55.00},
    {'note': 'E1', 'freq': 41.20},
  ],
  'Double Bass': [
    {'note': 'G2', 'freq': 98.00},
    {'note': 'D2', 'freq': 73.42},
    {'note': 'A1', 'freq': 55.00},
    {'note': 'E1', 'freq': 41.20},
  ],
  'Violin': [
    {'note': 'E5', 'freq': 659.25},
    {'note': 'A4', 'freq': 440.00},
    {'note': 'D4', 'freq': 293.66},
    {'note': 'G3', 'freq': 196.00},
  ],
  'Cello': [
    {'note': 'A3', 'freq': 220.00},
    {'note': 'D3', 'freq': 146.83},
    {'note': 'G2', 'freq': 98.00},
    {'note': 'C2', 'freq': 65.41},
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
  const TunerWidget({Key? key}) : super(key: key);

  @override
  State<TunerWidget> createState() => _TunerWidgetState();
}

class _TunerWidgetState extends State<TunerWidget> {
  late PitchDetector _detector;
  web.AudioContext? _audioContext;
  web.ScriptProcessorNode? _processor;
  String _detectedNote = '';
  double _detectedFreq = 0.0;
  double _cents = 0.0;
  bool _listening = false;
  List<String> _userInstruments = [];
  String? _selectedInstrument;

  @override
  void initState() {
    super.initState();
    _detector = PitchDetector(audioSampleRate: 44100, bufferSize: 4096);
  }

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    final profileProvider = Provider.of<UserProfileProvider>(
      context,
      listen: false,
    );
    final instruments = profileProvider.profile?.preferences.instruments ?? [];
    // Filter out piano/keyboard
    _userInstruments =
        instruments
            .where(
              (i) =>
                  !i.toLowerCase().contains('piano') &&
                  !i.toLowerCase().contains('keyboard'),
            )
            .toList();
    if (_userInstruments.isEmpty) {
      _selectedInstrument = null;
    } else if (_userInstruments.length == 1) {
      _selectedInstrument = _userInstruments.first;
    } else if (_selectedInstrument == null ||
        !_userInstruments.contains(_selectedInstrument)) {
      _selectedInstrument = _userInstruments.first;
    }
  }

  Future<void> _startListening() async {
    if (_listening) return;
    _listening = true;
    final constraints = js_util.jsify({'audio': true});
    final promise = web.window.navigator.mediaDevices.getUserMedia(constraints);
    final stream = await promise.toDart;
    _audioContext = web.AudioContext();
    final source = _audioContext?.createMediaStreamSource(stream);
    _processor = _audioContext?.createScriptProcessor(4096, 1, 1);

    if (_processor != null) {
      js_util.setProperty(
        _processor!,
        'onaudioprocess',
        allowInterop((web.AudioProcessingEvent audioEvent) {
          final inputBuffer = audioEvent.inputBuffer;
          final inputData = inputBuffer.getChannelData(0);
          final length = js_util.getProperty<int>(inputData, 'length');
          final samples = List<double>.generate(
            length,
            (i) => js_util.callMethod(inputData, 'at', [i]) as double,
          );
          _detector.getPitchFromFloatBuffer(samples).then((result) {
            if (result.pitched) {
              final noteData = _findClosestNote(result.pitch);
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
        }),
      );
    }

    // Use js_util.callMethod for connect to ensure JS interop compatibility
    if (source != null && _processor != null) {
      js_util.callMethod(source, 'connect', [_processor!]);
    }
    if (_processor != null && _audioContext?.destination != null) {
      js_util.callMethod(_processor!, 'connect', [_audioContext!.destination]);
    }
  }

  void _stopListening() {
    _processor?.disconnect();
    _audioContext?.close();
    _audioContext = null;
    setState(() {
      _listening = false;
      _detectedNote = '';
      _detectedFreq = 0.0;
      _cents = 0.0;
    });
  }

  Map<String, Object> _findClosestNote(double freq) {
    final notes = instrumentTunings[_selectedInstrument ?? 'Guitar'];
    Map<String, Object> closest = Map<String, Object>.from(notes!.first);
    double minDiff = (freq - (closest['freq'] as double)).abs();
    for (final note in notes) {
      final noteObj = Map<String, Object>.from(note);
      final diff = (freq - (noteObj['freq'] as double)).abs();
      if (diff < minDiff) {
        closest = noteObj;
        minDiff = diff;
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
    _stopListening();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    // If no tunable instruments, show a message
    if (_userInstruments.isEmpty || _selectedInstrument == null) {
      return Card(
        margin: const EdgeInsets.all(16),
        child: Padding(
          padding: const EdgeInsets.all(24),
          child: Center(
            child: Text(
              'No tuning required for piano/keyboard instruments.',
              style: Theme.of(context).textTheme.titleLarge,
              textAlign: TextAlign.center,
            ),
          ),
        ),
      );
    }

    return Card(
      margin: const EdgeInsets.all(16),
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            if (_userInstruments.length > 1)
              Row(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  const Text('Instrument:'),
                  const SizedBox(width: 8),
                  DropdownButton<String>(
                    value: _selectedInstrument,
                    items:
                        _userInstruments.map((instrument) {
                          return DropdownMenuItem(
                            value: instrument,
                            child: Text(instrument),
                          );
                        }).toList(),
                    onChanged: (val) {
                      if (val != null) {
                        setState(() {
                          _selectedInstrument = val;
                        });
                      }
                    },
                  ),
                ],
              ),
            const SizedBox(height: 16),
            ElevatedButton(
              onPressed: _listening ? _stopListening : _startListening,
              child: Text(_listening ? 'Stop' : 'Start'),
            ),
            const SizedBox(height: 24),
            Text(
              _detectedNote.isNotEmpty
                  ? 'Note: $_detectedNote'
                  : 'Play a note...',
              style: Theme.of(context).textTheme.headlineSmall,
            ),
            Text(
              _detectedFreq > 0 ? '${_detectedFreq.toStringAsFixed(2)} Hz' : '',
              style: Theme.of(context).textTheme.titleMedium,
            ),
            const SizedBox(height: 16),
            _detectedNote.isNotEmpty
                ? _buildTuningIndicator(_cents)
                : const SizedBox.shrink(),
            if (_selectedInstrument != null &&
                instrumentTips[_selectedInstrument!] != null)
              Padding(
                padding: const EdgeInsets.only(top: 20),
                child: Text(
                  instrumentTips[_selectedInstrument!]!,
                  style: Theme.of(
                    context,
                  ).textTheme.bodyMedium?.copyWith(color: Colors.blueGrey),
                  textAlign: TextAlign.center,
                ),
              ),
          ],
        ),
      ),
    );
  }

  Widget _buildTuningIndicator(double cents) {
    return Column(
      mainAxisSize: MainAxisSize.min,
      children: [
        Text(
          _detectedNote,
          style: const TextStyle(fontSize: 48, fontWeight: FontWeight.bold),
        ),
        const SizedBox(height: 8),
        HorizontalTuningBar(cents: cents),
      ],
    );
  }
}

class HorizontalTuningBar extends StatelessWidget {
  final double cents; // -50 (flat) to +50 (sharp)
  final int segments;

  const HorizontalTuningBar({Key? key, required this.cents, this.segments = 11})
    : super(key: key);

  Color _getColor(int idx, int centerIdx) {
    final distance = (idx - centerIdx).abs();
    if (distance >= 4) return Colors.red.shade900;
    if (distance == 3) return Colors.red;
    if (distance == 2) return Colors.orange;
    if (distance == 1) return Colors.amber;
    return Colors.yellow;
  }

  @override
  Widget build(BuildContext context) {
    final centerIdx = segments ~/ 2;
    // Map cents to segment index
    int activeIdx = ((cents + 50) / 100 * (segments - 1)).round();
    activeIdx = activeIdx.clamp(0, segments - 1);
    return Row(
      mainAxisAlignment: MainAxisAlignment.center,
      children: [
        const Padding(
          padding: EdgeInsets.only(right: 8),
          child: Text('♭', style: TextStyle(color: Colors.grey, fontSize: 24)),
        ),
        ...List.generate(segments, (i) {
          final isActive = (i - activeIdx).abs() <= 0;
          final color =
              isActive ? _getColor(i, centerIdx) : Colors.grey.shade300;
          return AnimatedContainer(
            duration: const Duration(milliseconds: 100),
            margin: const EdgeInsets.symmetric(horizontal: 2),
            width: 20,
            height: 32,
            decoration: BoxDecoration(
              color: color,
              borderRadius: BorderRadius.circular(6),
            ),
          );
        }),
        const Padding(
          padding: EdgeInsets.only(left: 8),
          child: Text('#', style: TextStyle(color: Colors.grey, fontSize: 24)),
        ),
      ],
    );
  }
}
