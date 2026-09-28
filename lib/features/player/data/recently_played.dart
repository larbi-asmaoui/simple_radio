import 'dart:convert';

import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../common/models/playable_media.dart';
import '../../../core/settings/settings_controller.dart';

final recentlyPlayedProvider =
    NotifierProvider<RecentlyPlayedController, List<PlayableMedia>>(
      RecentlyPlayedController.new,
    );

/// Most-recent-first history of what was played, persisted across launches.
class RecentlyPlayedController extends Notifier<List<PlayableMedia>> {
  static const _key = 'recently_played';
  static const _maxItems = 12;

  @override
  List<PlayableMedia> build() {
    final raw = ref.watch(sharedPreferencesProvider).getStringList(_key);
    if (raw == null) return const [];
    try {
      return raw
          .map(
            (s) =>
                PlayableMedia.fromJson(jsonDecode(s) as Map<String, Object?>),
          )
          .toList();
    } catch (_) {
      return const []; // Corrupt/old format: start fresh.
    }
  }

  void add(PlayableMedia media) {
    state = [
      media,
      ...state.where((m) => m.id != media.id),
    ].take(_maxItems).toList();
    _persist();
  }

  void clear() {
    state = const [];
    _persist();
  }

  void _persist() => ref
      .read(sharedPreferencesProvider)
      .setStringList(_key, state.map((m) => jsonEncode(m.toJson())).toList());
}
