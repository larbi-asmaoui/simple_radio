import 'package:flutter_test/flutter_test.dart';
import 'package:simple_radio/features/podcast/data/rss_parser.dart';

const _feed = '''<?xml version="1.0" encoding="UTF-8"?>
<rss version="2.0" xmlns:itunes="http://www.itunes.com/dtds/podcast-1.0.dtd">
  <channel>
    <title>Test Show</title>
    <description><![CDATA[<p>A show &amp; more.</p>]]></description>
    <item>
      <title>Episode 2</title>
      <guid>ep-2</guid>
      <pubDate>Mon, 28 Sep 2026 09:46:25 +0000</pubDate>
      <itunes:duration>1:02:03</itunes:duration>
      <itunes:image href="https://example.com/ep2.jpg"/>
      <enclosure url="https://example.com/ep2.mp3" type="audio/mpeg" length="1"/>
    </item>
    <item>
      <title>Trailer without audio</title>
    </item>
    <item>
      <title>Episode 1</title>
      <pubDate>Sun, 20 Sep 2026 10:00:00 PDT</pubDate>
      <itunes:duration>2710</itunes:duration>
      <enclosure url="https://example.com/ep1.mp3" type="audio/mpeg"/>
    </item>
  </channel>
</rss>''';

void main() {
  test('parses channel and audio items, skipping items without audio', () {
    final details = parsePodcastFeed(_feed);

    expect(details.description, 'A show & more.');
    expect(details.episodes.map((e) => e.title), ['Episode 2', 'Episode 1']);

    final ep2 = details.episodes.first;
    expect(ep2.id, 'ep-2');
    expect(ep2.duration, const Duration(hours: 1, minutes: 2, seconds: 3));
    expect(ep2.artworkUrl, 'https://example.com/ep2.jpg');
    expect(ep2.publishedAt!.toUtc(), DateTime.utc(2026, 9, 28, 9, 46, 25));

    final ep1 = details.episodes.last;
    expect(ep1.id, 'https://example.com/ep1.mp3'); // No guid: falls back.
    expect(ep1.duration, const Duration(seconds: 2710));
    expect(ep1.publishedAt!.toUtc(), DateTime.utc(2026, 9, 20, 17));
  });

  test('duration and date edge cases', () {
    expect(
      parseItunesDuration('45:10'),
      const Duration(minutes: 45, seconds: 10),
    );
    expect(parseItunesDuration('abc'), isNull);
    expect(parseRssDate('2026-09-01T12:00:00Z'), DateTime.utc(2026, 9, 1, 12));
    expect(parseRssDate('garbage'), isNull);
  });
}
