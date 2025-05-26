// Web implementation of metronome sound player (no-op)
// This is a placeholder as web support is not actively maintained

import 'metronome_sound_player.dart';

/// No-op implementation for web platform
class MetronomeSoundPlayerImpl implements MetronomeSoundPlayer {
  @override
  Future<void> init() async {
    // No initialization needed for no-op implementation
  }

  @override
  Future<void> dispose() async {
    // No cleanup needed for no-op implementation
  }

  @override
  Future<void> play({required bool isDownbeat, double volume = 1.0}) async {
    // No sound will be played in the web version
    // This is a deliberate no-op as web support is not actively maintained
  }
}
