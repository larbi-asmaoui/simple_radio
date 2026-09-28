import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../common/models/playable_media.dart';
import '../data/recently_played.dart';
import 'player_providers.dart';

/// Single entry point for "the user asked to play this", so every screen
/// gets the same side effects (history today; analytics later).
extension PlaybackActions on WidgetRef {
  void playMedia(PlayableMedia media) {
    read(audioPlayerProvider).play(media);
    read(recentlyPlayedProvider.notifier).add(media);
  }
}
