/// Whether the stream has a fixed length (podcast) or is endless (radio).
enum MediaKind { liveStream, onDemand }

/// The one shape the player understands. Radio stations and podcast episodes
/// convert themselves into this so the player never depends on a feature.
///
/// Maps 1:1 onto `audio_service`'s `MediaItem` when the real engine lands.
class PlayableMedia {
  const PlayableMedia({
    required this.id,
    required this.title,
    required this.subtitle,
    required this.artworkUrl,
    required this.streamUrl,
    required this.kind,
  });

  final String id;
  final String title;

  /// Genre for a station, podcast name for an episode.
  final String subtitle;
  final String artworkUrl;
  final String streamUrl;
  final MediaKind kind;

  bool get isLive => kind == MediaKind.liveStream;

  Map<String, Object?> toJson() => {
    'id': id,
    'title': title,
    'subtitle': subtitle,
    'artworkUrl': artworkUrl,
    'streamUrl': streamUrl,
    'kind': kind.name,
  };

  factory PlayableMedia.fromJson(Map<String, Object?> json) => PlayableMedia(
    id: json['id'] as String,
    title: json['title'] as String,
    subtitle: json['subtitle'] as String? ?? '',
    artworkUrl: json['artworkUrl'] as String? ?? '',
    streamUrl: json['streamUrl'] as String,
    kind: json['kind'] == MediaKind.onDemand.name
        ? MediaKind.onDemand
        : MediaKind.liveStream,
  );
}
