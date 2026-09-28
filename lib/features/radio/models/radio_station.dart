import '../../../common/models/playable_media.dart';

/// A live radio station, as returned by the Radio Browser API.
class RadioStation {
  const RadioStation({
    required this.id,
    required this.name,
    required this.genre,
    required this.artworkUrl,
    required this.streamUrl,
    this.country = '',
    this.codec = '',
    this.bitrate = 0,
  });

  /// Maps a Radio Browser station object (`/json/stations/...`).
  factory RadioStation.fromRadioBrowser(Map<String, dynamic> json) {
    final tags = (json['tags'] as String? ?? '')
        .split(',')
        .map((t) => t.trim())
        .where((t) => t.isNotEmpty)
        .take(2)
        .map(_titleCase);
    final resolved = json['url_resolved'] as String? ?? '';
    return RadioStation(
      id: json['stationuuid'] as String,
      name: (json['name'] as String? ?? '').trim(),
      genre: tags.isEmpty ? 'Radio' : tags.join(' · '),
      artworkUrl: json['favicon'] as String? ?? '',
      streamUrl: resolved.isNotEmpty ? resolved : json['url'] as String? ?? '',
      country: json['country'] as String? ?? '',
      codec: json['codec'] as String? ?? '',
      bitrate: (json['bitrate'] as num?)?.toInt() ?? 0,
    );
  }

  final String id;
  final String name;
  final String genre;

  /// Station favicon; often missing or tiny, so the UI always has a fallback.
  final String artworkUrl;
  final String streamUrl;
  final String country;
  final String codec;
  final int bitrate;

  PlayableMedia toPlayable() => PlayableMedia(
    id: 'station:$id',
    title: name,
    subtitle: genre,
    artworkUrl: artworkUrl,
    streamUrl: streamUrl,
    kind: MediaKind.liveStream,
  );

  static String _titleCase(String s) => s
      .split(' ')
      .map((w) => w.isEmpty ? w : w[0].toUpperCase() + w.substring(1))
      .join(' ');
}
