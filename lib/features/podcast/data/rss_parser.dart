import 'package:xml/xml.dart';

import '../../../common/utils/text_utils.dart';
import '../models/podcast.dart';

/// Parses a podcast RSS 2.0 feed (with the iTunes namespace).
///
/// Top-level so it can run on a background isolate via `compute`: popular
/// feeds are several MB and would otherwise jank the UI.
PodcastDetails parsePodcastFeed(String xml) {
  final channel = XmlDocument.parse(xml).findAllElements('channel').first;

  final episodes = <Episode>[];
  for (final item in channel.findElements('item')) {
    final enclosure = item.getElement('enclosure');
    final audioUrl = enclosure?.getAttribute('url');
    if (audioUrl == null || audioUrl.isEmpty) continue; // Not an audio item.

    episodes.add(
      Episode(
        id: _text(item, 'guid') ?? audioUrl,
        title: _text(item, 'title') ?? 'Untitled episode',
        audioUrl: audioUrl,
        publishedAt: parseRssDate(_text(item, 'pubDate')),
        duration: parseItunesDuration(_text(item, 'itunes:duration')),
        description: stripHtml(
          _text(item, 'itunes:summary') ?? _text(item, 'description') ?? '',
        ),
        artworkUrl: item.getElement('itunes:image')?.getAttribute('href'),
      ),
    );
    if (episodes.length == 100) break; // Plenty for a list; keeps memory sane.
  }

  return PodcastDetails(
    description: stripHtml(
      _text(channel, 'description') ?? _text(channel, 'itunes:summary') ?? '',
    ),
    episodes: episodes,
  );
}

String? _text(XmlElement parent, String qualifiedName) {
  final value = parent.getElement(qualifiedName)?.innerText.trim();
  return (value == null || value.isEmpty) ? null : value;
}

/// `itunes:duration` is "3600", "59:10" or "1:02:03".
Duration? parseItunesDuration(String? raw) {
  if (raw == null) return null;
  final parts = raw.split(':').map((p) => int.tryParse(p.trim())).toList();
  if (parts.isEmpty || parts.contains(null)) return null;
  var seconds = 0;
  for (final p in parts) {
    seconds = seconds * 60 + p!;
  }
  return seconds > 0 ? Duration(seconds: seconds) : null;
}

const _monthIndex = {
  'jan': 1,
  'feb': 2,
  'mar': 3,
  'apr': 4,
  'may': 5,
  'jun': 6,
  'jul': 7,
  'aug': 8,
  'sep': 9,
  'oct': 10,
  'nov': 11,
  'dec': 12,
};

const _zoneHours = {
  'GMT': 0,
  'UT': 0,
  'UTC': 0,
  'Z': 0,
  'EST': -5,
  'EDT': -4,
  'CST': -6,
  'CDT': -5,
  'MST': -7,
  'MDT': -6,
  'PST': -8,
  'PDT': -7,
};

final _rfc822 = RegExp(
  r'(\d{1,2})\s+([A-Za-z]{3})[A-Za-z]*\s+(\d{2,4})\s+(\d{1,2}):(\d{2})(?::(\d{2}))?\s*([+-]\d{4}|[A-Za-z]{1,4})?',
);

/// Lenient RFC 822 parser (`Mon, 28 Sep 2026 09:46:25 +0000`). Real feeds
/// deviate from the spec a lot, so we also accept ISO 8601.
DateTime? parseRssDate(String? raw) {
  if (raw == null) return null;
  final m = _rfc822.firstMatch(raw);
  if (m == null) return DateTime.tryParse(raw);

  final month = _monthIndex[m[2]!.toLowerCase()];
  if (month == null) return null;
  var year = int.parse(m[3]!);
  if (year < 100) year += 2000;

  var offset = Duration.zero;
  final zone = m[7];
  if (zone != null) {
    if (zone.startsWith('+') || zone.startsWith('-')) {
      final sign = zone.startsWith('-') ? -1 : 1;
      offset = Duration(
        hours: sign * int.parse(zone.substring(1, 3)),
        minutes: sign * int.parse(zone.substring(3, 5)),
      );
    } else {
      offset = Duration(hours: _zoneHours[zone.toUpperCase()] ?? 0);
    }
  }

  return DateTime.utc(
    year,
    month,
    int.parse(m[1]!),
    int.parse(m[4]!),
    int.parse(m[5]!),
    int.parse(m[6] ?? '0'),
  ).subtract(offset).toLocal();
}
