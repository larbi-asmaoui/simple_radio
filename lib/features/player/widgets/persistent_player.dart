import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../common/models/playable_media.dart';
import '../../../common/widgets/artwork.dart';
import '../../../common/widgets/live_badge.dart';
import '../data/audio_player_service.dart';
import '../presentation/now_playing_screen.dart';
import '../providers/player_providers.dart';

/// Mini player docked above the bottom navigation bar. Tap it (or swipe
/// up) to open the full Now Playing page.
///
/// Slides up when something starts playing and slides away on stop. The
/// parent (`MainScreen`) owns the `Positioned`; this widget owns its
/// appearance and animation.
class PersistentPlayer extends ConsumerWidget {
  const PersistentPlayer({super.key});

  static const double height = 64;
  static const double margin = 8;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final player = ref.watch(audioPlayerProvider);
    final media = player.current;

    return AnimatedSwitcher(
      duration: const Duration(milliseconds: 320),
      switchInCurve: Curves.easeOutCubic,
      switchOutCurve: Curves.easeInCubic,
      transitionBuilder: (child, animation) => SlideTransition(
        position: Tween(
          begin: const Offset(0, 1),
          end: Offset.zero,
        ).animate(animation),
        child: FadeTransition(opacity: animation, child: child),
      ),
      child: media == null
          ? const SizedBox.shrink(key: ValueKey('empty'))
          // Constant key: switching tracks updates the bar in place instead
          // of sliding it out and back in.
          : _PlayerBar(
              key: const ValueKey('bar'),
              media: media,
              player: player,
            ),
    );
  }
}

class _PlayerBar extends StatelessWidget {
  const _PlayerBar({super.key, required this.media, required this.player});

  final PlayableMedia media;
  final AudioPlayerService player;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final colors = theme.colorScheme;

    return Padding(
      padding: const EdgeInsets.all(PersistentPlayer.margin),
      child: Material(
        color: colors.surfaceContainerHigh,
        elevation: 8,
        shadowColor: Colors.black54,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(12),
          side: BorderSide(color: colors.outlineVariant),
        ),
        clipBehavior: Clip.antiAlias,
        child: SizedBox(
          height: PersistentPlayer.height,
          child: StreamBuilder<PlaybackStatus>(
            stream: player.statusStream,
            initialData: player.status,
            builder: (context, snapshot) {
              final status = snapshot.data ?? PlaybackStatus.idle;
              return Stack(
                children: [
                  Row(
                    children: [
                      const SizedBox(width: 8),
                      _NowPlayingInfo(
                        media: media,
                        song: player.nowPlayingTitle,
                        errorMessage: status == PlaybackStatus.error
                            ? player.errorMessage
                            : null,
                        onOpen: () => showNowPlaying(context),
                      ),
                      _PlayPauseButton(status: status, player: player),
                      IconButton(
                        tooltip: 'Stop',
                        icon: const Icon(Icons.close_rounded),
                        color: colors.onSurfaceVariant,
                        onPressed: player.stop,
                      ),
                      const SizedBox(width: 4),
                    ],
                  ),
                  // Thin buffering indicator along the bottom edge.
                  if (status == PlaybackStatus.loading)
                    const Positioned(
                      left: 0,
                      right: 0,
                      bottom: 0,
                      child: LinearProgressIndicator(minHeight: 2),
                    )
                  // Podcast progress; live radio has no length.
                  else if (!media.isLive && status != PlaybackStatus.error)
                    Positioned(
                      left: 0,
                      right: 0,
                      bottom: 0,
                      child: StreamBuilder<PlaybackProgress>(
                        stream: player.progressStream,
                        builder: (context, snapshot) {
                          final fraction = snapshot.data?.fraction;
                          if (fraction == null) return const SizedBox.shrink();
                          return LinearProgressIndicator(
                            value: fraction,
                            minHeight: 2,
                          );
                        },
                      ),
                    ),
                ],
              );
            },
          ),
        ),
      ),
    );
  }
}

/// Artwork + title + subtitle; cross-fades when the track changes.
class _NowPlayingInfo extends StatelessWidget {
  const _NowPlayingInfo({
    required this.media,
    required this.onOpen,
    this.song,
    this.errorMessage,
  });

  final PlayableMedia media;
  final VoidCallback onOpen;

  /// Song on air (radio), shown instead of the genre when known.
  final String? song;

  /// Replaces the subtitle while playback is failing.
  final String? errorMessage;

  @override
  Widget build(BuildContext context) {
    final textTheme = Theme.of(context).textTheme;

    return Expanded(
      child: Semantics(
        button: true,
        label: 'Open player',
        child: GestureDetector(
          // Swipe up, like Spotify, as well as tap.
          onVerticalDragEnd: (details) {
            if ((details.primaryVelocity ?? 0) < -200) onOpen();
          },
          child: InkWell(
            onTap: onOpen,
            borderRadius: BorderRadius.circular(8),
            child: AnimatedSwitcher(
              duration: const Duration(milliseconds: 250),
              layoutBuilder: (current, previous) => Stack(
                alignment: Alignment.centerLeft,
                children: [...previous, ?current],
              ),
              child: Row(
                key: ValueKey(media.id),
                children: [
                  Artwork(
                    url: media.artworkUrl,
                    size: 48,
                    borderRadius: 6,
                    fallbackIcon: media.isLive
                        ? Icons.radio_rounded
                        : Icons.podcasts_rounded,
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    child: Column(
                      mainAxisAlignment: MainAxisAlignment.center,
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          media.title,
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                          style: textTheme.titleSmall,
                        ),
                        const SizedBox(height: 2),
                        Row(
                          children: [
                            if (media.isLive && errorMessage == null) ...[
                              const LiveBadge(),
                              const SizedBox(width: 6),
                            ],
                            Expanded(
                              child: Text(
                                errorMessage ?? song ?? media.subtitle,
                                maxLines: 1,
                                overflow: TextOverflow.ellipsis,
                                style: errorMessage == null
                                    ? textTheme.bodySmall
                                    : textTheme.bodySmall?.copyWith(
                                        color: Theme.of(context)
                                            .colorScheme
                                            .error,
                                      ),
                              ),
                            ),
                          ],
                        ),
                      ],
                    ),
                  ),
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }
}

class _PlayPauseButton extends StatelessWidget {
  const _PlayPauseButton({required this.status, required this.player});

  final PlaybackStatus status;
  final AudioPlayerService player;

  @override
  Widget build(BuildContext context) {
    final colors = Theme.of(context).colorScheme;

    if (status == PlaybackStatus.loading) {
      return const SizedBox.square(
        dimension: 48,
        child: Center(
          child: SizedBox.square(
            dimension: 22,
            child: CircularProgressIndicator(strokeWidth: 2.5),
          ),
        ),
      );
    }

    if (status == PlaybackStatus.error) {
      return IconButton(
        tooltip: 'Retry',
        iconSize: 28,
        color: colors.onSurface,
        onPressed: player.retry,
        icon: const Icon(Icons.refresh_rounded),
      );
    }

    final isPlaying = status == PlaybackStatus.playing;
    return IconButton(
      tooltip: isPlaying ? 'Pause' : 'Play',
      iconSize: 32,
      color: colors.onSurface,
      onPressed: player.togglePlayPause,
      icon: AnimatedSwitcher(
        duration: const Duration(milliseconds: 180),
        transitionBuilder: (child, animation) =>
            ScaleTransition(scale: animation, child: child),
        child: Icon(
          isPlaying ? Icons.pause_rounded : Icons.play_arrow_rounded,
          key: ValueKey(isPlaying),
        ),
      ),
    );
  }
}
