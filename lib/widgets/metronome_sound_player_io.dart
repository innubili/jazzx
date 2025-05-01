import 'metronome_sound_player.dart';

class MetronomeSoundPlayerImpl implements MetronomeSoundPlayer {
  @override
  Future<void> init() async {}

  @override
  Future<void> dispose() async {}

  @override
  Future<void> play({required bool isDownbeat, double volume = 1.0}) async {}
}
