import 'dart:async';
import 'dart:js' as js;
import 'metronome_sound_player.dart';

class MetronomeSoundPlayerImpl implements MetronomeSoundPlayer {
  @override
  Future<void> init() async {}

  @override
  Future<void> dispose() async {}

  @override
  Future<void> play({required bool isDownbeat, double volume = 1.0}) async {
    final freq = isDownbeat ? 660 : 880;
    final duration = 5; // ms
    // Volume: scale to 0.25 for web, adjust if needed
    final webGain = (volume * 0.25).toStringAsFixed(3);
    js.context.callMethod('eval', [
      """
      (function() {
        var ctx = window.audioCtx || (window.audioCtx = new (window.AudioContext || window.webkitAudioContext)());
        var o = ctx.createOscillator();
        var g = ctx.createGain();
        o.type = 'square';
        o.frequency.value = $freq;
        g.gain.value = $webGain;
        o.connect(g);
        g.connect(ctx.destination);
        var now = ctx.currentTime;
        o.start(now);
        o.stop(now + $duration / 1000.0);
      })();
      """,
    ]);
  }
}
