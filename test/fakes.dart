import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:simple_radio/core/settings/settings_controller.dart';
import 'package:simple_radio/features/podcast/data/podcast_repository.dart';
import 'package:simple_radio/features/podcast/models/podcast.dart';
import 'package:simple_radio/features/radio/data/radio_repository.dart';
import 'package:simple_radio/features/radio/models/radio_station.dart';
import 'package:simple_radio/main.dart';

class FakeRadioRepository implements RadioRepository {
  final requestedTags = <String?>[];
  final requestedCountries = <String>[];
  final clicks = <String>[];

  @override
  Future<List<RadioStation>> stations({
    String? tag,
    String countryCode = '',
  }) async {
    requestedTags.add(tag);
    requestedCountries.add(countryCode);
    final label = tag ?? 'top';
    return [
      for (var i = 1; i <= 6; i++)
        RadioStation(
          id: '$label-$i',
          name: 'Station $label $i',
          genre: label,
          artworkUrl: '',
          streamUrl: 'https://example.com/$label/$i',
        ),
    ];
  }

  @override
  Future<List<RadioStation>> search(
    String query, {
    String countryCode = '',
  }) async => [];

  @override
  Future<void> reportClick(String stationId) async => clicks.add(stationId);
}

class FakePodcastRepository implements PodcastRepository {
  @override
  String get attribution => 'Fake source';

  static const podcasts = [
    Podcast(
      id: 'p1',
      title: 'Night Shift',
      publisher: 'Midnight Media',
      artworkUrl: '',
    ),
    Podcast(
      id: 'p2',
      title: 'Signal & Noise',
      publisher: 'Frequency Labs',
      artworkUrl: '',
    ),
  ];

  @override
  Future<List<Podcast>> topPodcasts({required String region}) async => podcasts;

  @override
  Future<List<Podcast>> search(String query, {required String region}) async =>
      podcasts;

  @override
  Future<PodcastDetails> details(Podcast podcast) async => PodcastDetails(
    description: 'About ${podcast.title}',
    episodes: [
      for (var i = 1; i <= 3; i++)
        Episode(
          id: 'e$i',
          title: '${podcast.title} episode $i',
          audioUrl: 'https://example.com/e$i.mp3',
          publishedAt: DateTime(2026, 9, i),
          duration: const Duration(minutes: 42),
        ),
    ],
  );
}

/// Pumps the full app on a phone-sized screen with fake data sources.
/// Uses the platform font so tests never try to download Google Fonts.
Future<FakeRadioRepository> pumpApp(WidgetTester tester) async {
  tester.view.physicalSize = const Size(1080, 2400);
  tester.view.devicePixelRatio = 3;
  addTearDown(tester.view.reset);

  SharedPreferences.setMockInitialValues({
    'font': 'system',
    'country_code': '',
  });
  final prefs = await SharedPreferences.getInstance();
  final radio = FakeRadioRepository();

  await tester.pumpWidget(
    ProviderScope(
      overrides: [
        sharedPreferencesProvider.overrideWithValue(prefs),
        radioRepositoryProvider.overrideWithValue(radio),
        podcastRepositoryProvider.overrideWithValue(FakePodcastRepository()),
      ],
      retry: (_, _) => null,
      child: const SimpleRadioApp(),
    ),
  );
  await tester.pumpAndSettle();
  return radio;
}

/// Finds [finder] only inside the tab whose root screen is [screen]
/// (all tabs stay mounted, so plain finders would match hidden tabs too).
Finder inTab(Type screen, Finder finder) =>
    find.descendant(of: find.byType(screen), matching: finder);

/// Lets the mock player finish its fake buffering phase.
Future<void> finishBuffering(WidgetTester tester) async {
  await tester.pump(const Duration(seconds: 1));
  await tester.pumpAndSettle();
}
