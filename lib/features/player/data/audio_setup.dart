import 'package:audio_service/audio_service.dart';
import 'package:audio_session/audio_session.dart';
import 'package:flutter/foundation.dart';
import 'package:just_audio_media_kit/just_audio_media_kit.dart';

import '../../../app/theme/app_colors.dart';
import 'audio_handler_player_service.dart';
import 'audio_player_service.dart';
import 'playback_memory.dart';
import 'simple_radio_audio_handler.dart';

/// Builds the real player. Called once from `main()` before `runApp`.
///
/// - Android / iOS / macOS / web: the handler runs inside `audio_service`, so
///   playback continues in the background and shows system media controls.
/// - Linux / Windows: `just_audio` has no native backend there, so we plug in
///   libmpv via media_kit, and use the handler directly (no system service).
Future<AudioPlayerService> createAudioPlayerService(
  PlaybackMemory memory,
) async {
  try {
    JustAudioMediaKit.ensureInitialized(linux: true, windows: true);
  } catch (_) {
    // media_kit couldn't load libmpv. Keep the app usable and say why.
    return UnavailableAudioPlayerService(
      defaultTargetPlatform == TargetPlatform.linux
          ? 'Audio needs libmpv: sudo apt install libmpv2'
          : 'Audio needs libmpv, which is missing.',
    );
  }

  try {
    // Tells the OS we're a music app: ducking, pausing on calls, headphones
    // unplugged, etc.
    final session = await AudioSession.instance;
    await session.configure(const AudioSessionConfiguration.music());
  } catch (_) {
    // Not available on desktop Linux/Windows; nothing to configure there.
  }

  final handler = SimpleRadioAudioHandler();

  final hasSystemMediaService =
      kIsWeb ||
      switch (defaultTargetPlatform) {
        TargetPlatform.android ||
        TargetPlatform.iOS ||
        TargetPlatform.macOS => true,
        _ => false,
      };

  if (!hasSystemMediaService) {
    return AudioHandlerPlayerService(handler, memory: memory);
  }

  final systemHandler = await AudioService.init(
    builder: () => handler,
    config: const AudioServiceConfig(
      androidNotificationChannelId: 'com.example.simple_radio.playback',
      androidNotificationChannelName: 'Playback',
      androidNotificationChannelDescription: 'Radio and podcast controls',
      androidNotificationOngoing: true,
      androidStopForegroundOnPause: true,
      notificationColor: AppColors.primary,
      fastForwardInterval: Duration(seconds: 10),
      rewindInterval: Duration(seconds: 10),
    ),
  );
  return AudioHandlerPlayerService(systemHandler, memory: memory);
}
