import 'metronome_widget.dart';

class MetronomeController {
  MetronomeWidgetState? _state;

  // Called by the widget to attach its state.
  void attach(MetronomeWidgetState state) {
    _state = state;
  }

  // Detach the widget's state.
  void detach() {
    _state = null;
  }

  /// Starts the metronome.
  void start() {
    _state?.startMetronome();
    _state?.setRunning(true);
  }

  /// Stops the metronome.
  void stop() {
    _state?.stopMetronome();
    _state?.setRunning(false);
  }

  /// Toggles the metronome state.
  void toggle() {
    if (_state?.isPlaying == true) {
      stop();
    } else {
      start();
    }
  }

  /// Gets whether the metronome is currently playing.
  bool get isRunning => _state?.isPlaying ?? false;

  /// Gets the current BPM.
  int get bpm => _state?.bpm ?? 0;

  /// Sets a new BPM. If the metronome is running, it restarts with the new BPM.
  void setBpm(int newBpm) {
    _state?.setBpm(newBpm);
  }

  /// Sets a new time signature.
  void setTimeSignature(String newSignature) {
    _state?.setTimeSignature(newSignature);
  }

  /// Sets a new bits pattern (subdivision).
  void setBitsPattern(String newPattern) {
    _state?.setBitsPattern(newPattern);
  }
}
