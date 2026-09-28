import 'dart:async';

import 'package:audio_service/audio_service.dart';

import '../../../common/models/playable_media.dart';
import 'audio_player_service.dart';
import 'playback_memory.dart';

/// Adapts an `audio_service` [AudioHandler] to the app's
/// [AudioPlayerService]. State changes coming from outside the app
/// (notification buttons, headset, lock screen) flow back in through
/// [AudioHandler.playbackState], so the UI always matches the system.
///
/// With a [PlaybackMemory], podcast positions are saved while playing and
/// restored on the next play, and the chosen speed sticks across items.
class AudioHandlerPlayerService extends AudioPlayerService {
  AudioHandlerPlayerService(this._handler, {this._memory}) {
    _stateSub = _handler.playbackState.listen(_onPlaybackState);
    _itemSub = _handler.mediaItem.listen(_onMediaItem);
  }

  final AudioHandler _handler;
  final PlaybackMemory? _memory;
  late final StreamSubscription<PlaybackState> _stateSub;
  late final StreamSubscription<MediaItem?> _itemSub;
  Timer? _saveTimer;

  static const _saveEvery = Duration(seconds: 5);

  final _statusController = StreamController<PlaybackStatus>.broadcast();
  late final Stream<PlaybackStatus> _statusStream = _statusController.stream;

  PlayableMedia? _current;
  PlaybackStatus _status = PlaybackStatus.idle;
  String? _errorMessage;
  String? _nowPlayingTitle;
  late double _speed = _memory?.speed ?? 1.0;

  @override
  PlayableMedia? get current => _current;

  @override
  PlaybackStatus get status => _status;

  @override
  Stream<PlaybackStatus> get statusStream => _statusStream;

  @override
  String? get errorMessage => _errorMessage;

  @override
  String? get nowPlayingTitle => _nowPlayingTitle;

  @override
  double get speed => _speed;

  /// `PlaybackState.position` extrapolates from the last event while
  /// playing, so sampling it is enough for a progress bar.
  @override
  PlaybackProgress get progress => PlaybackProgress(
    _handler.playbackState.value.position,
    _handler.mediaItem.value?.duration,
  );

  @override
  Stream<PlaybackProgress> get progressStream =>
      Stream.periodic(const Duration(milliseconds: 250), (_) => progress);

  @override
  Future<void> play(PlayableMedia media) async {
    if (_current?.id == media.id &&
        _status != PlaybackStatus.idle &&
        _status != PlaybackStatus.error) {
      if (_status == PlaybackStatus.paused) await resume();
      return;
    }

    _savePosition(); // Remember where the previous episode was left.
    _current = media;
    _errorMessage = null;
    _nowPlayingTitle = null;
    _setStatus(PlaybackStatus.loading);

    final startAt = media.isLive ? null : _memory?.resumePointFor(media.id);
    await _handler.playMediaItem(
      MediaItem(
        id: media.id,
        title: media.title,
        artist: media.subtitle,
        album: media.isLive ? 'Live radio' : media.subtitle,
        artUri: media.artworkUrl.isEmpty
            ? null
            : Uri.tryParse(media.artworkUrl),
        extras: {
          'url': media.streamUrl,
          'live': media.isLive,
          'startAt': ?startAt?.inMilliseconds,
        },
      ),
    );
    if (!media.isLive && _speed != 1.0) await _handler.setSpeed(_speed);
  }

  @override
  Future<void> pause() async {
    await _handler.pause();
    _savePosition();
  }

  @override
  Future<void> resume() => _handler.play();

  @override
  Future<void> seek(Duration position) async {
    await _handler.seek(position);
    _savePosition();
  }

  @override
  Future<void> setSpeed(double speed) async {
    _speed = speed;
    _memory?.speed = speed;
    notifyListeners();
    if (_current?.isLive == false) await _handler.setSpeed(speed);
  }

  @override
  Future<void> retry() async {
    final media = _current;
    if (media == null) return;
    _status = PlaybackStatus.idle; // Force a fresh load.
    await play(media);
  }

  @override
  Future<void> stop() async {
    _savePosition();
    _current = null;
    _errorMessage = null;
    _nowPlayingTitle = null;
    _setStatus(PlaybackStatus.idle);
    await _handler.stop();
  }

  void _onPlaybackState(PlaybackState state) {
    if (_current == null) return;

    // Stopped from outside the app (notification "stop" button).
    if (state.processingState == AudioProcessingState.idle &&
        _handler.mediaItem.value == null) {
      _current = null;
      _setStatus(PlaybackStatus.idle);
      return;
    }

    if (state.processingState == AudioProcessingState.completed &&
        _current?.isLive == false) {
      _memory?.markFinished(_current!.id);
    }

    final next = switch (state.processingState) {
      AudioProcessingState.error => PlaybackStatus.error,
      AudioProcessingState.loading ||
      AudioProcessingState.buffering => PlaybackStatus.loading,
      // just_audio drops to idle right after a failure; keep showing the
      // error. Otherwise idle is the gap before the next item loads.
      AudioProcessingState.idle =>
        _status == PlaybackStatus.error
            ? PlaybackStatus.error
            : PlaybackStatus.loading,
      AudioProcessingState.ready || AudioProcessingState.completed =>
        state.playing ? PlaybackStatus.playing : PlaybackStatus.paused,
    };

    // Only the error event itself carries the reason; later idle events
    // must not overwrite it.
    if (state.processingState == AudioProcessingState.error) {
      _errorMessage = _friendlyError(state.errorMessage);
    }
    if (next != _status) _setStatus(next);
  }

  void _onMediaItem(MediaItem? item) {
    if (item == null || item.id != _current?.id) return;
    if (item.displayTitle != _nowPlayingTitle) {
      _nowPlayingTitle = item.displayTitle;
      notifyListeners();
    }
  }

  /// Saves the podcast position every few seconds while playing, so even a
  /// killed app resumes close to where it was.
  void _syncSaveTimer() {
    final shouldSave =
        _status == PlaybackStatus.playing && _current?.isLive == false;
    if (shouldSave && _saveTimer == null) {
      _saveTimer = Timer.periodic(_saveEvery, (_) => _savePosition());
    } else if (!shouldSave) {
      _saveTimer?.cancel();
      _saveTimer = null;
    }
  }

  void _savePosition() {
    final media = _current;
    if (_memory == null || media == null || media.isLive) return;
    // Not yet loaded: position 0 would wipe a real saved position.
    if (_status == PlaybackStatus.loading || _status == PlaybackStatus.error) {
      return;
    }
    final p = progress;
    _memory.save(media.id, p.position, p.duration);
  }

  static String _friendlyError(String? raw) {
    final text = raw?.toLowerCase() ?? '';
    if (text.contains('404') || text.contains('not found')) {
      return 'This stream is offline.';
    }
    if (text.contains('format') || text.contains('codec')) {
      return "This stream's format isn't supported.";
    }
    return "Couldn't play this. Check your connection.";
  }

  void _setStatus(PlaybackStatus next) {
    _status = next;
    _statusController.add(next);
    _syncSaveTimer();
    notifyListeners();
  }

  @override
  void dispose() {
    _saveTimer?.cancel();
    _stateSub.cancel();
    _itemSub.cancel();
    _statusController.close();
    super.dispose();
  }
}
