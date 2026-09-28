import 'package:flutter/foundation.dart';

import '../../../common/models/playable_media.dart';

/// A podcast show, as listed in charts/search results. Some fields are only
/// known once the details are loaded (see [PodcastDetails]).
@immutable
class Podcast {
  const Podcast({
    required this.id,
    required this.title,
    required this.publisher,
    required this.artworkUrl,
    this.description = '',
    this.feedUrl,
  });

  /// Apple Podcasts collection id.
  final String id;
  final String title;
  final String publisher;
  final String artworkUrl;
  final String description;

  /// RSS feed, when known (free source).
  final String? feedUrl;

  // Used as a provider family key, so equality is by identity of the show.
  @override
  bool operator ==(Object other) => other is Podcast && other.id == id;

  @override
  int get hashCode => id.hashCode;
}

@immutable
class PodcastDetails {
  const PodcastDetails({required this.description, required this.episodes});

  final String description;
  final List<Episode> episodes;
}

@immutable
class Episode {
  const Episode({
    required this.id,
    required this.title,
    required this.audioUrl,
    this.publishedAt,
    this.duration,
    this.description = '',
    this.artworkUrl,
  });

  final String id;
  final String title;
  final String audioUrl;
  final DateTime? publishedAt;
  final Duration? duration;
  final String description;

  /// Episode-specific art; falls back to the show's artwork.
  final String? artworkUrl;

  PlayableMedia toPlayable(Podcast podcast) => PlayableMedia(
    id: 'episode:${podcast.id}:$id',
    title: title,
    subtitle: podcast.title,
    artworkUrl: artworkUrl ?? podcast.artworkUrl,
    streamUrl: audioUrl,
    kind: MediaKind.onDemand,
  );
}
