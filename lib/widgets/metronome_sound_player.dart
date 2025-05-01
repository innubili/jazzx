// Platform abstraction for metronome sound
abstract class MetronomeSoundPlayer {
  Future<void> init();
  Future<void> dispose();
  Future<void> play({required bool isDownbeat, double volume});
}
