import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../core/settings/settings_controller.dart';
import '../../player/providers/playback_actions.dart';
import '../data/radio_repository.dart';
import '../models/radio_station.dart';

/// A browsable genre. [tag] is the Radio Browser tag; null means "top".
class RadioGenre {
  const RadioGenre(this.label, this.tag, this.icon, this.color);

  final String label;
  final String? tag;
  final IconData icon;

  /// Accent used by the Home genre tiles.
  final Color color;
}

const kRadioGenres = <RadioGenre>[
  RadioGenre('Top', null, Icons.trending_up_rounded, Color(0xFFFFC744)),
  RadioGenre('Pop', 'pop', Icons.star_rounded, Color(0xFFE8115B)),
  RadioGenre('Rock', 'rock', Icons.electric_bolt_rounded, Color(0xFFBA5D07)),
  RadioGenre('Jazz', 'jazz', Icons.piano_rounded, Color(0xFF1E3264)),
  RadioGenre('News', 'news', Icons.newspaper_rounded, Color(0xFF477D95)),
  RadioGenre(
    'Electronic',
    'electronic',
    Icons.graphic_eq_rounded,
    Color(0xFF8D67AB),
  ),
  RadioGenre(
    'Classical',
    'classical',
    Icons.music_note_rounded,
    Color(0xFF7D4B32),
  ),
  RadioGenre('Hip-Hop', 'hip hop', Icons.mic_rounded, Color(0xFFBC5900)),
  RadioGenre('Chill', 'chillout', Icons.spa_rounded, Color(0xFF148A08)),
  RadioGenre('Talk', 'talk', Icons.forum_rounded, Color(0xFF503750)),
  RadioGenre('Dance', 'dance', Icons.nightlife_rounded, Color(0xFFDC148C)),
  RadioGenre('80s', '80s', Icons.album_rounded, Color(0xFF0D73EC)),
];

/// Genre selected on the Radio tab (Home genre tiles set it too).
final selectedGenreProvider = NotifierProvider<SelectedGenre, RadioGenre>(
  SelectedGenre.new,
);

class SelectedGenre extends Notifier<RadioGenre> {
  @override
  RadioGenre build() => kRadioGenres.first;

  void select(RadioGenre genre) => state = genre;
}

/// Stations for a tag (null = top), in the region chosen in Settings.
final stationsProvider = FutureProvider.family<List<RadioStation>, String?>((
  ref,
  tag,
) {
  final country = ref.watch(settingsProvider.select((s) => s.countryCode));
  return ref
      .watch(radioRepositoryProvider)
      .stations(tag: tag, countryCode: country);
});

final stationSearchProvider = FutureProvider.autoDispose
    .family<List<RadioStation>, String>((ref, query) {
      final country = ref.watch(settingsProvider.select((s) => s.countryCode));
      return ref
          .watch(radioRepositoryProvider)
          .search(query, countryCode: country);
    });

extension RadioPlayback on WidgetRef {
  void playStation(RadioStation station) {
    playMedia(station.toPlayable());
    read(radioRepositoryProvider).reportClick(station.id);
  }
}
