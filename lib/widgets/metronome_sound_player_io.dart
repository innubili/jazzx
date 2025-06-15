import 'package:audioplayers/audioplayers.dart';
import 'metronome_sound_player.dart';
import '../utils/utils.dart';

class MetronomeSoundPlayerImpl implements MetronomeSoundPlayer {
  late AudioPlayer _tickPlayer;
  late AudioPlayer _downbeatPlayer;

  bool _isInitialized = false;

  // Use WAV files for best compatibility on Android/iOS
  final String _tickSoundPath =
      "sounds/tick.mp3"; 
  final String _downbeatSoundPath =
      "sounds/tack.mp3"; 

  @override
  Future<void> init() async {
    log.info('[METRONOME_AUDIO_DEBUG] init() called.');
    try {
      _tickPlayer = AudioPlayer();
      await _tickPlayer.setPlayerMode(PlayerMode.mediaPlayer);
      log.info(
        '[METRONOME_AUDIO_DEBUG] _tickPlayer configured for media player.',
      );
      await _tickPlayer.setSource(AssetSource(_tickSoundPath));
      log.info(
        '[METRONOME_AUDIO_DEBUG] _tickPlayer source set to: $_tickSoundPath',
      );

      _downbeatPlayer = AudioPlayer();
      await _downbeatPlayer.setPlayerMode(PlayerMode.mediaPlayer);
      log.info(
        '[METRONOME_AUDIO_DEBUG] _downbeatPlayer configured for media player.',
      );
      await _downbeatPlayer.setSource(AssetSource(_downbeatSoundPath));
      log.info(
        '[METRONOME_AUDIO_DEBUG] _downbeatPlayer source set to: $_downbeatSoundPath',
      );

      _isInitialized = true;
      log.info('[METRONOME_AUDIO_DEBUG] Initialization complete.');
    } catch (e) {
      log.info('[METRONOME_AUDIO_DEBUG] ERROR during init(): $e');
      _isInitialized = false;
    }
  }

  @override
  Future<void> dispose() async {
    if (!_isInitialized) return;
    await _tickPlayer.dispose();
    await _downbeatPlayer.dispose();
    _isInitialized = false;
  }

  @override
  Future<void> play({required bool isDownbeat, double volume = 1.0}) async {
    log.info(
      '[METRONOME_AUDIO_DEBUG] play() called. isDownbeat: $isDownbeat, _isInitialized: $_isInitialized, requested volume: $volume',
    );
    if (!_isInitialized) {
      log.info('[METRONOME_AUDIO_DEBUG] play() aborted: Not initialized.');
      return;
    }
    try {
      final player = isDownbeat ? _downbeatPlayer : _tickPlayer;

      await player.setVolume(volume);
      log.info('[METRONOME_AUDIO_DEBUG] Volume set to: $volume');

      await player.seek(Duration.zero);
      await player.resume();

      log.info(
        '[METRONOME_AUDIO_DEBUG] play(): ${isDownbeat ? _downbeatSoundPath : _tickSoundPath} sound played/resumed. (using .mp3)',
      );
    } catch (e) {
      log.info('[METRONOME_AUDIO_DEBUG] ERROR during play(): $e');
    }
  }
}
