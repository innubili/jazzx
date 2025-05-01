export 'metronome_sound_player_io.dart'
  if (dart.library.html) 'metronome_sound_player_web.dart';

import 'metronome_sound_player_io.dart'
  if (dart.library.html) 'metronome_sound_player_web.dart';
import 'metronome_sound_player.dart';

MetronomeSoundPlayer createMetronomeSoundPlayer() => MetronomeSoundPlayerImpl();
