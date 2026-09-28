import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:simple_radio/features/home/presentation/home_screen.dart';
import 'package:simple_radio/features/player/presentation/now_playing_screen.dart';
import 'package:simple_radio/features/player/widgets/persistent_player.dart';
import 'package:simple_radio/features/podcast/presentation/episode_list_screen.dart';
import 'package:simple_radio/features/podcast/presentation/podcast_screen.dart';
import 'package:simple_radio/features/radio/presentation/radio_screen.dart';
import 'package:simple_radio/features/settings/presentation/settings_screen.dart';

import 'fakes.dart';

void main() {
  testWidgets('home plays a station and adds it to Recently played', (
    tester,
  ) async {
    final radio = await pumpApp(tester);

    expect(inTab(HomeScreen, find.text('Popular stations 🌍')), findsOneWidget);
    expect(inTab(HomeScreen, find.text('Recently played')), findsNothing);

    await tester.tap(inTab(HomeScreen, find.text('Station top 1')));
    await finishBuffering(tester);

    expect(find.byTooltip('Pause'), findsOneWidget);
    expect(radio.clicks, ['top-1']);
    expect(inTab(HomeScreen, find.text('Recently played')), findsOneWidget);

    await tester.tap(find.byTooltip('Stop'));
    await tester.pumpAndSettle();
    expect(find.byTooltip('Stop'), findsNothing);
  });

  testWidgets('home genre tile opens the Radio tab filtered by that genre', (
    tester,
  ) async {
    final radio = await pumpApp(tester);

    await tester.scrollUntilVisible(
      inTab(HomeScreen, find.text('Jazz')),
      200,
      scrollable: inTab(HomeScreen, find.byType(Scrollable)).first,
    );
    await tester.tap(inTab(HomeScreen, find.text('Jazz')));
    await tester.pumpAndSettle();

    expect(radio.requestedTags, contains('jazz'));
    expect(inTab(RadioScreen, find.text('Station jazz 1')), findsOneWidget);
  });

  testWidgets('podcast -> episode list -> play episode', (tester) async {
    await pumpApp(tester);

    await tester.tap(find.byIcon(Icons.podcasts_outlined));
    await tester.pumpAndSettle();

    await tester.tap(inTab(PodcastScreen, find.text('Night Shift')));
    await tester.pumpAndSettle();
    expect(find.text('About Night Shift'), findsOneWidget);

    await tester.tap(inTab(EpisodeListScreen, find.byTooltip('Play')).first);
    await finishBuffering(tester);

    // Mini player + the episode row both show a pause control.
    expect(find.byTooltip('Pause'), findsNWidgets(2));

    // Tapping the mini player opens the full podcast player.
    await tester.tap(
      find.descendant(
        of: find.byType(PersistentPlayer),
        matching: find.text('Night Shift episode 1'),
      ),
    );
    await tester.pumpAndSettle();

    final page = find.byType(NowPlayingScreen);
    expect(
      find.descendant(of: page, matching: find.text('PLAYING FROM PODCAST')),
      findsOneWidget,
    );
    expect(
      find.descendant(of: page, matching: find.byType(Slider)),
      findsOneWidget,
    );
    expect(
      find.descendant(of: page, matching: find.byTooltip('Back 10 seconds')),
      findsOneWidget,
    );
    expect(
      find.descendant(of: page, matching: find.byTooltip('Forward 10 seconds')),
      findsOneWidget,
    );

    // Speed cycles 1× -> 1.25×.
    await tester.tap(find.descendant(of: page, matching: find.text('1×')));
    await tester.pumpAndSettle();
    expect(
      find.descendant(of: page, matching: find.text('1.25×')),
      findsOneWidget,
    );

    // Close with the chevron; the mini player is still there.
    await tester.tap(find.byTooltip('Close'));
    await tester.pumpAndSettle();
    expect(page, findsNothing);
    expect(find.byType(PersistentPlayer), findsOneWidget);
  });

  testWidgets('radio Now Playing shows LIVE, no seek bar; stop closes it', (
    tester,
  ) async {
    await pumpApp(tester);

    await tester.tap(inTab(HomeScreen, find.text('Station top 1')));
    await finishBuffering(tester);

    await tester.tap(
      find.descendant(
        of: find.byType(PersistentPlayer),
        matching: find.text('Station top 1'),
      ),
    );
    // The LIVE dot pulses forever, so pump fixed frames instead of settling.
    await tester.pump(); // Starts the slide-up animation...
    await tester.pump(const Duration(milliseconds: 600)); // ...and ends it.

    final page = find.byType(NowPlayingScreen);
    expect(
      find.descendant(of: page, matching: find.text('PLAYING FROM RADIO')),
      findsOneWidget,
    );
    expect(
      find.descendant(of: page, matching: find.text('LIVE')),
      findsOneWidget,
    );
    expect(
      find.descendant(of: page, matching: find.byType(Slider)),
      findsNothing,
    );

    await tester.tap(
      find.descendant(of: page, matching: find.byTooltip('Stop')),
    );
    await tester.pumpAndSettle();
    expect(page, findsNothing);
    expect(find.byType(PersistentPlayer), findsOneWidget); // Present but empty.
    expect(find.text('Station top 1'), findsWidgets); // Still in the Home list.
  });

  testWidgets('changing region in Settings refetches stations', (tester) async {
    final radio = await pumpApp(tester);

    await tester.tap(find.byIcon(Icons.settings_outlined));
    await tester.pumpAndSettle();

    await tester.tap(inTab(SettingsScreen, find.text('Region')));
    await tester.pumpAndSettle();
    await tester.tap(find.text('France'));
    await tester.pumpAndSettle();

    expect(
      inTab(SettingsScreen, find.textContaining('France')),
      findsOneWidget,
    );
    // Hidden tabs are paused; stations reload for the new region on return.
    await tester.tap(find.byIcon(Icons.radio_outlined));
    await tester.pumpAndSettle();
    expect(radio.requestedCountries, contains('FR'));
  });
}
