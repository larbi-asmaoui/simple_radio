import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:shared_preferences/shared_preferences.dart';

import 'app/main_screen.dart';
import 'app/theme/app_theme.dart';
import 'core/settings/settings_controller.dart';
import 'features/player/data/audio_setup.dart';
import 'features/player/data/playback_memory.dart';
import 'features/player/providers/player_providers.dart';

Future<void> main() async {
  WidgetsFlutterBinding.ensureInitialized();
  final prefs = await SharedPreferences.getInstance();
  final memory = PlaybackMemory(prefs);
  final player = await createAudioPlayerService(memory);

  runApp(
    ProviderScope(
      overrides: [
        sharedPreferencesProvider.overrideWithValue(prefs),
        playbackMemoryProvider.overrideWith((ref) => memory),
        audioPlayerProvider.overrideWith((ref) => player),
      ],
      // No silent auto-retry: errors show a Retry button instead.
      retry: (_, _) => null,
      child: const SimpleRadioApp(),
    ),
  );
}

class SimpleRadioApp extends ConsumerWidget {
  const SimpleRadioApp({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final font = ref.watch(settingsProvider.select((s) => s.font));

    // Reelhouse is dark-only, like the streaming-site-next web app.
    return MaterialApp(
      title: 'SimpleRadio',
      debugShowCheckedModeBanner: false,
      theme: AppTheme.build(font),
      themeMode: ThemeMode.dark,
      home: const MainScreen(),
    );
  }
}
