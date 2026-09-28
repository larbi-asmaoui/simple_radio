import 'dart:async';

import 'package:audio_service/audio_service.dart';
import 'package:just_audio/just_audio.dart';

/// Owns the actual [AudioPlayer] and publishes its state in `audio_service`
/// terms, which is what drives the Android notification, the iOS lock
/// screen / Control Center and headset buttons.
///
/// `MediaItem.extras` carries:
/// - `url`: the stream to play,
/// - `live`: true for endless radio streams (no seeking),
/// - `startAt`: optional resume position in milliseconds.
class SimpleRadioAudioHandler extends BaseAudioHandler with SeekHandler {
  SimpleRadioAudioHandler() {
    _player.playbackEventStream.listen(
      (_) => _broadcastState(),
      onError: (Object error, StackTrace _) => _broadcastError(error),
    );
    // Podcasts learn their length only after loading; the lock screen needs it.
    _player.durationStream.listen((duration) {
      final item = mediaItem.value;
      if (item != null && duration != null && item.duration != duration) {
        mediaItem.add(item.copyWith(duration: duration));
      }
    });
    // Many stations embed the current song in the stream ("Artist - Title").
    // Shown as the display title so the lock screen reads song / station.
    _player.icyMetadataStream.listen((icy) {
      final item = mediaItem.value;
      if (item == null || item.extras?['live'] != true) return;
      final song = icy?.info?.title?.trim();
      final next = (song == null || song.isEmpty || song == item.title)
          ? null
          : song;
      if (next == item.displayTitle) return;
      mediaItem.add(
        item.copyWith(
          displayTitle: next,
          displaySubtitle: next == null ? null : item.title,
        ),
      );
    });
  }

  final _player = AudioPlayer();

  bool get _isLive => mediaItem.value?.extras?['live'] == true;

  @override
  Future<void> playMediaItem(MediaItem mediaItem) async {
    this.mediaItem.add(mediaItem);
    try {
      final extras = mediaItem.extras!;
      final startAt = extras['startAt'] as int?;
      if (extras['live'] == true) await _player.setSpeed(1.0);
      await _player.setUrl(
        extras['url'] as String,
        initialPosition: startAt == null
            ? null
            : Duration(milliseconds: startAt),
      );
      // Not awaited: play() only completes when playback pauses or stops.
      unawaited(_player.play());
    } on PlayerInterruptedException {
      // Another item was requested before this one finished loading.
    } catch (error) {
      _broadcastError(error);
    }
  }

  @override
  Future<void> play() => _player.play();

  @override
  Future<void> pause() => _player.pause();

  @override
  Future<void> seek(Duration position) => _player.seek(position);

  @override
  Future<void> setSpeed(double speed) => _player.setSpeed(speed);

  @override
  Future<void> stop() async {
    await _player.stop();
    mediaItem.add(null);
    playbackState.add(
      playbackState.value.copyWith(
        processingState: AudioProcessingState.idle,
        playing: false,
      ),
    );
    await super.stop();
  }

  /// Swiping the app away on Android ends playback instead of leaving an
  /// orphaned notification.
  @override
  Future<void> onTaskRemoved() => stop();

  void _broadcastState() {
    final playing = _player.playing;
    playbackState.add(
      playbackState.value.copyWith(
        controls: [
          if (!_isLive) MediaControl.rewind,
          playing ? MediaControl.pause : MediaControl.play,
          if (!_isLive) MediaControl.fastForward,
          MediaControl.stop,
        ],
        systemActions: _isLive
            ? const {}
            : const {
                MediaAction.seek,
                MediaAction.seekForward,
                MediaAction.seekBackward,
              },
        androidCompactActionIndices: _isLive ? const [0, 1] : const [0, 1, 2],
        processingState: switch (_player.processingState) {
          ProcessingState.idle => AudioProcessingState.idle,
          ProcessingState.loading => AudioProcessingState.loading,
          ProcessingState.buffering => AudioProcessingState.buffering,
          ProcessingState.ready => AudioProcessingState.ready,
          ProcessingState.completed => AudioProcessingState.completed,
        },
        playing: playing,
        updatePosition: _player.position,
        bufferedPosition: _player.bufferedPosition,
        speed: _player.speed,
        errorMessage: null,
      ),
    );
  }

  void _broadcastError(Object error) {
    playbackState.add(
      playbackState.value.copyWith(
        processingState: AudioProcessingState.error,
        playing: false,
        errorMessage: switch (error) {
          PlayerException(:final message?) => message,
          _ => error.toString(),
        },
      ),
    );
  }
}
