import 'dart:convert';

import 'package:flutter/foundation.dart';
import 'package:shared_preferences/shared_preferences.dart';

/// Where the listener stopped in an on-demand item.
@immutable
class SavedPosition {
  const SavedPosition({
    required this.position,
    this.duration,
    this.finished = false,
    required this.updatedAt,
  });

  factory SavedPosition.fromJson(Map<String, dynamic> json) => SavedPosition(
    position: Duration(milliseconds: json['p'] as int),
    duration: switch (json['d']) {
      final int ms => Duration(milliseconds: ms),
      _ => null,
    },
    finished: json['f'] == true,
    updatedAt: DateTime.fromMillisecondsSinceEpoch(json['u'] as int),
  );

  final Duration position;
  final Duration? duration;
  final bool finished;
  final DateTime updatedAt;

  /// 0..1 when the length is known.
  double? get fraction {
    final total = duration?.inMilliseconds ?? 0;
    if (total <= 0) return null;
    return (position.inMilliseconds / total).clamp(0.0, 1.0);
  }

  Duration? get remaining => duration == null ? null : duration! - position;

  Map<String, Object?> toJson() => {
    'p': position.inMilliseconds,
    'd': duration?.inMilliseconds,
    'f': finished,
    'u': updatedAt.millisecondsSinceEpoch,
  };
}

/// Remembers podcast positions ("resume where I left off") and the
/// preferred playback speed across launches.
///
/// Shared by the player (writes) and the UI (progress on episode rows and
/// Recently played), hence a [ChangeNotifier].
class PlaybackMemory extends ChangeNotifier {
  PlaybackMemory(this._prefs) {
    try {
      final raw = _prefs.getString(_kPositions);
      if (raw != null) {
        final json = jsonDecode(raw) as Map<String, dynamic>;
        json.forEach(
          (id, v) => _positions[id] = SavedPosition.fromJson(
            v as Map<String, dynamic>,
          ),
        );
      }
    } catch (_) {
      // Corrupt data: start fresh rather than crash.
    }
  }

  static const _kPositions = 'playback_positions';
  static const _kSpeed = 'playback_speed';
  static const _maxEntries = 300;

  /// Closer than this to either end counts as "start over" / "finished".
  static const _edge = Duration(seconds: 15);

  static const speeds = [0.75, 1.0, 1.25, 1.5, 1.75, 2.0];

  final SharedPreferences _prefs;
  final _positions = <String, SavedPosition>{};

  SavedPosition? positionOf(String mediaId) => _positions[mediaId];

  /// Where to start [mediaId], or null to start from the beginning.
  Duration? resumePointFor(String mediaId) {
    final saved = _positions[mediaId];
    if (saved == null || saved.finished || saved.position < _edge) return null;
    final remaining = saved.remaining;
    if (remaining != null && remaining < _edge) return null;
    return saved.position;
  }

  void save(String mediaId, Duration position, Duration? duration) {
    final nearEnd = duration != null && duration - position < _edge;
    _positions[mediaId] = SavedPosition(
      position: position,
      duration: duration ?? _positions[mediaId]?.duration,
      finished: nearEnd,
      updatedAt: DateTime.now(),
    );
    _persist();
  }

  void markFinished(String mediaId) {
    final saved = _positions[mediaId];
    _positions[mediaId] = SavedPosition(
      position: saved?.duration ?? saved?.position ?? Duration.zero,
      duration: saved?.duration,
      finished: true,
      updatedAt: DateTime.now(),
    );
    _persist();
  }

  double get speed => _prefs.getDouble(_kSpeed) ?? 1.0;

  set speed(double value) {
    _prefs.setDouble(_kSpeed, value);
    notifyListeners();
  }

  void _persist() {
    if (_positions.length > _maxEntries) {
      final oldest = _positions.entries.toList()
        ..sort((a, b) => a.value.updatedAt.compareTo(b.value.updatedAt));
      for (final e in oldest.take(_positions.length - _maxEntries)) {
        _positions.remove(e.key);
      }
    }
    _prefs.setString(
      _kPositions,
      jsonEncode(_positions.map((id, p) => MapEntry(id, p.toJson()))),
    );
    notifyListeners();
  }
}
