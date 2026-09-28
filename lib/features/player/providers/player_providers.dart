import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_riverpod/legacy.dart';

import '../../../core/settings/settings_controller.dart';
import '../data/audio_player_service.dart';
import '../data/playback_memory.dart';
import '../widgets/persistent_player.dart';

/// App-wide audio player. `main()` overrides this with the real
/// just_audio/audio_service player; the mock default keeps tests offline.
final audioPlayerProvider = ChangeNotifierProvider<AudioPlayerService>(
  (ref) => MockAudioPlayerService(),
);

/// Saved podcast positions + preferred speed. `main()` overrides this with
/// the same instance the player writes to.
final playbackMemoryProvider = ChangeNotifierProvider<PlaybackMemory>(
  (ref) => PlaybackMemory(ref.watch(sharedPreferencesProvider)),
);

/// Bottom padding scrollable screens add so their last row isn't hidden
/// behind the persistent player.
final playerInsetProvider = Provider<double>((ref) {
  final visible = ref.watch(
    audioPlayerProvider.select((player) => player.current != null),
  );
  return visible ? PersistentPlayer.height + PersistentPlayer.margin * 2 : 0;
});
