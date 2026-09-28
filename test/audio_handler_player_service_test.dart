import 'package:audio_service/audio_service.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:simple_radio/common/models/playable_media.dart';
import 'package:simple_radio/features/player/data/audio_handler_player_service.dart';
import 'package:simple_radio/features/player/data/audio_player_service.dart';
import 'package:simple_radio/features/player/data/playback_memory.dart';
import 'package:shared_preferences/shared_preferences.dart';

/// Stands in for the just_audio-backed handler; tests push states into it
/// the way the OS or the player would.
class FakeHandler extends BaseAudioHandler {
  final requested = <MediaItem>[];
  final speeds = <double>[];

  @override
  Future<void> setSpeed(double speed) async => speeds.add(speed);

  @override
  Future<void> playMediaItem(MediaItem mediaItem) async {
    requested.add(mediaItem);
    this.mediaItem.add(mediaItem);
  }

  @override
  Future<void> stop() async {
    mediaItem.add(null);
    emit(AudioProcessingState.idle);
  }

  void emit(AudioProcessingState s, {bool playing = false, String? error}) =>
      playbackState.add(
        playbackState.value.copyWith(
          processingState: s,
          playing: playing,
          errorMessage: error,
        ),
      );
}

const _station = PlayableMedia(
  id: 'station:1',
  title: 'Jazz FM',
  subtitle: 'Jazz',
  artworkUrl: '',
  streamUrl: 'https://example.com/jazz',
  kind: MediaKind.liveStream,
);

void main() {
  late FakeHandler handler;
  late AudioHandlerPlayerService player;

  setUp(() {
    handler = FakeHandler();
    player = AudioHandlerPlayerService(handler);
  });

  Future<void> settle() => Future<void>.delayed(Duration.zero);

  test('passes the stream to the handler and tracks its state', () async {
    await player.play(_station);
    expect(player.status, PlaybackStatus.loading);
    expect(handler.requested.single.extras, {
      'url': 'https://example.com/jazz',
      'live': true,
    });

    handler.emit(AudioProcessingState.ready, playing: true);
    await settle();
    expect(player.status, PlaybackStatus.playing);

    // Paused from the lock screen / notification.
    handler.emit(AudioProcessingState.ready, playing: false);
    await settle();
    expect(player.status, PlaybackStatus.paused);
  });

  test('an error survives the idle event that follows it', () async {
    await player.play(_station);
    handler.emit(AudioProcessingState.error, error: '404 Not Found');
    handler.emit(AudioProcessingState.idle);
    await settle();

    expect(player.status, PlaybackStatus.error);
    expect(player.errorMessage, 'This stream is offline.');

    await player.retry();
    expect(handler.requested, hasLength(2));
    expect(player.status, PlaybackStatus.loading);
  });

  test('stop from the notification clears the mini player', () async {
    await player.play(_station);
    handler.emit(AudioProcessingState.ready, playing: true);
    await settle();

    await handler.stop(); // Not via the app.
    await settle();
    expect(player.current, isNull);
    expect(player.status, PlaybackStatus.idle);
  });

  test('shows the song a station broadcasts', () async {
    await player.play(_station);
    final item = handler.mediaItem.value!;
    handler.mediaItem.add(item.copyWith(displayTitle: 'Miles Davis - So What'));
    await settle();
    expect(player.nowPlayingTitle, 'Miles Davis - So What');
  });

  group('with playback memory', () {
    const episode = PlayableMedia(
      id: 'episode:p1:e1',
      title: 'Episode 1',
      subtitle: 'Night Shift',
      artworkUrl: '',
      streamUrl: 'https://example.com/e1.mp3',
      kind: MediaKind.onDemand,
    );

    late PlaybackMemory memory;

    setUp(() async {
      SharedPreferences.setMockInitialValues({});
      memory = PlaybackMemory(await SharedPreferences.getInstance());
      player = AudioHandlerPlayerService(handler, memory: memory);
    });

    test('resumes an episode where it was left', () async {
      memory.save(
        episode.id,
        const Duration(minutes: 7),
        const Duration(hours: 1),
      );

      await player.play(episode);
      expect(handler.requested.single.extras!['startAt'], 7 * 60 * 1000);
    });

    test('radio never resumes or changes speed', () async {
      memory.speed = 1.5;
      player = AudioHandlerPlayerService(handler, memory: memory);

      await player.play(_station);
      expect(handler.requested.single.extras!.containsKey('startAt'), isFalse);
      expect(handler.speeds, isEmpty);
    });

    test('remembered speed applies to podcasts and persists', () async {
      await player.setSpeed(1.25);
      await player.play(episode);

      expect(handler.speeds.last, 1.25);
      expect(memory.speed, 1.25);
    });
  });
}
