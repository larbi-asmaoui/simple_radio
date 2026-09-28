import 'dart:async';

import 'package:flutter/foundation.dart';

import '../../../common/models/playable_media.dart';

enum PlaybackStatus { idle, loading, playing, paused, error }

/// Position within an on-demand item (podcasts). Live streams have no
/// [duration].
@immutable
class PlaybackProgress {
  const PlaybackProgress(this.position, this.duration);

  final Duration position;
  final Duration? duration;

  /// 0..1, or null when the length is unknown (live radio).
  double? get fraction {
    final total = duration?.inMilliseconds ?? 0;
    if (total <= 0) return null;
    return (position.inMilliseconds / total).clamp(0.0, 1.0);
  }
}

/// Contract the UI talks to. [AudioHandlerPlayerService] is the real
/// implementation; [MockAudioPlayerService] keeps widget tests hermetic.
///
/// It is both a [ChangeNotifier] (for Riverpod rebuilds on metadata changes)
/// and a status [Stream] (for `StreamBuilder`, mirroring how
/// `AudioHandler.playbackState` is consumed).
abstract class AudioPlayerService extends ChangeNotifier {
  PlayableMedia? get current;
  PlaybackStatus get status;
  Stream<PlaybackStatus> get statusStream;
  Stream<PlaybackProgress> get progressStream;

  /// Latest position; the stream above samples this.
  PlaybackProgress get progress;

  /// Human-readable reason when [status] is [PlaybackStatus.error].
  String? get errorMessage;

  /// Song currently on air, when a radio station broadcasts it (ICY
  /// metadata). Null for podcasts and stations that don't send it.
  String? get nowPlayingTitle;

  /// Podcast playback speed (1.0 = normal). Live radio always plays at 1x.
  double get speed;
  Future<void> setSpeed(double speed);

  Future<void> play(PlayableMedia media);
  Future<void> pause();
  Future<void> resume();
  Future<void> stop();
  Future<void> seek(Duration position);

  /// Jumps by [offset] (negative = back), clamped to the item's bounds.
  Future<void> skip(Duration offset) {
    final p = progress;
    var target = p.position + offset;
    if (target < Duration.zero) target = Duration.zero;
    if (p.duration != null && target > p.duration!) target = p.duration!;
    return seek(target);
  }

  Future<void> togglePlayPause() =>
      status == PlaybackStatus.playing ? pause() : resume();

  /// Tries the current item again after an error.
  Future<void> retry();

  bool isCurrent(String mediaId) => current?.id == mediaId;
}

/// Simulates a player: a short buffering phase, then "playing".
class MockAudioPlayerService extends AudioPlayerService {
  MockAudioPlayerService({
    this.bufferingDelay = const Duration(milliseconds: 900),
  });

  /// How long the fake "loading" phase lasts before playback starts.
  final Duration bufferingDelay;

  final _statusController = StreamController<PlaybackStatus>.broadcast();
  late final Stream<PlaybackStatus> _statusStream = _statusController.stream;

  PlayableMedia? _current;
  PlaybackStatus _status = PlaybackStatus.idle;
  Timer? _bufferingTimer;

  @override
  PlayableMedia? get current => _current;

  @override
  PlaybackStatus get status => _status;

  @override
  Stream<PlaybackStatus> get statusStream => _statusStream;

  @override
  Stream<PlaybackProgress> get progressStream => const Stream.empty();

  @override
  PlaybackProgress get progress => const PlaybackProgress(Duration.zero, null);

  @override
  String? get errorMessage => null;

  @override
  String? get nowPlayingTitle => null;

  double _speed = 1.0;

  @override
  double get speed => _speed;

  @override
  Future<void> setSpeed(double speed) async {
    _speed = speed;
    notifyListeners();
  }

  @override
  Future<void> play(PlayableMedia media) async {
    // Tapping what's already loaded just makes sure it's playing.
    if (_current?.id == media.id && _status != PlaybackStatus.idle) {
      if (_status == PlaybackStatus.paused) await resume();
      return;
    }

    _bufferingTimer?.cancel();
    _current = media;
    _setStatus(PlaybackStatus.loading);
    _bufferingTimer = Timer(bufferingDelay, () {
      _setStatus(PlaybackStatus.playing);
    });
  }

  @override
  Future<void> pause() async {
    if (_status != PlaybackStatus.playing) return;
    _setStatus(PlaybackStatus.paused);
  }

  @override
  Future<void> resume() async {
    if (_status != PlaybackStatus.paused) return;
    _setStatus(PlaybackStatus.playing);
  }

  @override
  Future<void> stop() async {
    _bufferingTimer?.cancel();
    _current = null;
    _setStatus(PlaybackStatus.idle);
  }

  @override
  Future<void> seek(Duration position) async {}

  @override
  Future<void> retry() async {}

  void _setStatus(PlaybackStatus next) {
    _status = next;
    _statusController.add(next);
    notifyListeners();
  }

  @override
  void dispose() {
    _bufferingTimer?.cancel();
    _statusController.close();
    super.dispose();
  }
}

/// Used when no audio backend could start (e.g. Linux without libmpv), so
/// the app still opens and explains the problem when the user hits play.
class UnavailableAudioPlayerService extends MockAudioPlayerService {
  UnavailableAudioPlayerService(this._reason);

  final String _reason;

  @override
  String? get errorMessage => _reason;

  @override
  Future<void> play(PlayableMedia media) async {
    _current = media;
    _setStatus(PlaybackStatus.error);
  }

  @override
  Future<void> retry() async => _setStatus(PlaybackStatus.error);
}
