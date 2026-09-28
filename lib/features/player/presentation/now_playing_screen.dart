import 'dart:math' as math;

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../app/theme/app_colors.dart';
import '../../../common/models/playable_media.dart';
import '../../../common/utils/text_utils.dart';
import '../../../common/widgets/artwork.dart';
import '../../../common/widgets/live_badge.dart';
import '../data/audio_player_service.dart';
import '../data/playback_memory.dart';
import '../providers/player_providers.dart';

/// Opens the full-screen player over everything (tabs and bottom bar).
/// It slides up from the bottom; drag it down or tap ⌄ to close.
Future<void> showNowPlaying(BuildContext context) {
  return showModalBottomSheet<void>(
    context: context,
    useRootNavigator: true,
    isScrollControlled: true,
    backgroundColor: Colors.transparent,
    barrierColor: Colors.black54,
    shape: const RoundedRectangleBorder(),
    // Full width on desktop too (sheets default to a 640px max).
    constraints: const BoxConstraints(),
    builder: (_) => const NowPlayingScreen(),
  );
}

/// Spotify-style full player. Radio gets a LIVE header and the current song;
/// podcasts get a seek bar, ±10 s skips and a speed control.
class NowPlayingScreen extends ConsumerWidget {
  const NowPlayingScreen({super.key});

  static const skipInterval = Duration(seconds: 10);

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    // Close when playback is stopped (from here or from the notification).
    ref.listen(audioPlayerProvider.select((p) => p.current == null), (
      _,
      stopped,
    ) {
      if (stopped && context.mounted) Navigator.of(context).pop();
    });

    final player = ref.watch(audioPlayerProvider);
    final media = player.current;
    final size = MediaQuery.sizeOf(context);

    return Container(
      width: size.width,
      height: size.height,
      decoration: const BoxDecoration(
        // Fixed Reelhouse glow: marquee amber bleeding into velvet plum.
        gradient: RadialGradient(
          center: Alignment(0, -0.9),
          radius: 1.3,
          colors: [Color(0xFF5A4326), AppColors.accent, AppColors.background],
          stops: [0, 0.4, 0.95],
        ),
      ),
      child: SafeArea(
        child: media == null
            ? const SizedBox.shrink()
            : Center(
                child: ConstrainedBox(
                  // Keeps the layout phone-shaped on wide desktop windows.
                  constraints: const BoxConstraints(maxWidth: 520),
                  child: _Body(media: media, player: player),
                ),
              ),
      ),
    );
  }
}

class _Body extends StatelessWidget {
  const _Body({required this.media, required this.player});

  final PlayableMedia media;
  final AudioPlayerService player;

  @override
  Widget build(BuildContext context) {
    return Column(
      children: [
        _TopBar(media: media),
        Expanded(
          child: LayoutBuilder(
            builder: (context, constraints) {
              final side = math.min(
                math.min(constraints.maxWidth - 48, constraints.maxHeight - 24),
                440.0,
              );
              return Center(
                child: DecoratedBox(
                  decoration: BoxDecoration(
                    borderRadius: BorderRadius.circular(AppColors.radius),
                    boxShadow: const [
                      BoxShadow(
                        color: Colors.black54,
                        blurRadius: 32,
                        offset: Offset(0, 12),
                      ),
                    ],
                  ),
                  child: Artwork(
                    url: media.artworkUrl,
                    // Shrinks on short (landscape / desktop) windows.
                    size: math.max(side, 0),
                    borderRadius: AppColors.radius,
                    fallbackIcon: media.isLive
                        ? Icons.radio_rounded
                        : Icons.podcasts_rounded,
                  ),
                ),
              );
            },
          ),
        ),
        Padding(
          padding: const EdgeInsets.fromLTRB(24, 8, 24, 0),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              _TitleBlock(media: media, player: player),
              const SizedBox(height: 16),
              if (media.isLive)
                const SizedBox(height: 8)
              else
                _SeekBar(player: player),
              const SizedBox(height: 8),
              _Controls(media: media, player: player),
              const SizedBox(height: 32),
            ],
          ),
        ),
      ],
    );
  }
}

class _TopBar extends StatelessWidget {
  const _TopBar({required this.media});

  final PlayableMedia media;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return Padding(
      padding: const EdgeInsets.fromLTRB(8, 4, 8, 0),
      child: Row(
        children: [
          IconButton(
            tooltip: 'Close',
            iconSize: 32,
            icon: const Icon(Icons.keyboard_arrow_down_rounded),
            onPressed: () => Navigator.of(context).pop(),
          ),
          Expanded(
            child: Column(
              children: [
                Text(
                  media.isLive ? 'PLAYING FROM RADIO' : 'PLAYING FROM PODCAST',
                  style: theme.textTheme.labelSmall?.copyWith(
                    letterSpacing: 1.4,
                    fontWeight: FontWeight.w600,
                  ),
                ),
                const SizedBox(height: 2),
                Text(
                  media.subtitle,
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                  style: theme.textTheme.titleSmall,
                ),
              ],
            ),
          ),
          // Balances the close button so the header stays centered.
          const SizedBox(width: 48),
        ],
      ),
    );
  }
}

class _TitleBlock extends StatelessWidget {
  const _TitleBlock({required this.media, required this.player});

  final PlayableMedia media;
  final AudioPlayerService player;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final colors = theme.colorScheme;
    final song = player.nowPlayingTitle;
    final error = player.status == PlaybackStatus.error
        ? player.errorMessage
        : null;

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          media.title,
          maxLines: 2,
          overflow: TextOverflow.ellipsis,
          style: theme.textTheme.headlineSmall,
        ),
        const SizedBox(height: 6),
        Row(
          children: [
            if (media.isLive) ...[
              LiveBadge(
                large: true,
                pulsing: player.status == PlaybackStatus.playing,
              ),
              const SizedBox(width: 8),
            ],
            Expanded(
              child: Text(
                media.subtitle,
                maxLines: 1,
                overflow: TextOverflow.ellipsis,
                style: theme.textTheme.titleMedium?.copyWith(
                  color: media.isLive
                      ? colors.onSurfaceVariant
                      : colors.primary,
                ),
              ),
            ),
          ],
        ),
        // The song currently on air, when the station broadcasts it.
        AnimatedSwitcher(
          duration: const Duration(milliseconds: 300),
          child: song == null
              ? const SizedBox.shrink()
              : Padding(
                  key: ValueKey(song),
                  padding: const EdgeInsets.only(top: 12),
                  child: Row(
                    children: [
                      Icon(
                        Icons.music_note_rounded,
                        size: 18,
                        color: colors.primary,
                      ),
                      const SizedBox(width: 6),
                      Expanded(
                        child: Text(
                          song,
                          maxLines: 2,
                          overflow: TextOverflow.ellipsis,
                          style: theme.textTheme.bodyLarge,
                        ),
                      ),
                    ],
                  ),
                ),
        ),
        if (error != null)
          Padding(
            padding: const EdgeInsets.only(top: 12),
            child: Text(
              error,
              style: theme.textTheme.bodyMedium?.copyWith(color: colors.error),
            ),
          ),
      ],
    );
  }
}

/// Draggable progress bar with elapsed / remaining time. While dragging it
/// shows the finger's position and seeks only on release.
class _SeekBar extends StatefulWidget {
  const _SeekBar({required this.player});

  final AudioPlayerService player;

  @override
  State<_SeekBar> createState() => _SeekBarState();
}

class _SeekBarState extends State<_SeekBar> {
  late final _progress = widget.player.progressStream;
  double? _dragMs;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

    return StreamBuilder<PlaybackProgress>(
      stream: _progress,
      initialData: widget.player.progress,
      builder: (context, snapshot) {
        final progress = snapshot.data!;
        final totalMs = progress.duration?.inMilliseconds.toDouble() ?? 0;
        final known = totalMs > 0;
        final valueMs = (_dragMs ?? progress.position.inMilliseconds.toDouble())
            .clamp(0.0, known ? totalMs : 0.0);
        final position = Duration(milliseconds: valueMs.round());

        return Column(
          children: [
            SliderTheme(
              data: SliderTheme.of(context).copyWith(
                trackHeight: 4,
                thumbShape: const RoundSliderThumbShape(enabledThumbRadius: 7),
                overlayShape: const RoundSliderOverlayShape(overlayRadius: 18),
                activeTrackColor: theme.colorScheme.primary,
                inactiveTrackColor: Colors.white24,
                thumbColor: theme.colorScheme.onSurface,
                trackShape: const RoundedRectSliderTrackShape(),
              ),
              child: Slider(
                min: 0,
                max: known ? totalMs : 1,
                value: known ? valueMs : 0,
                semanticFormatterCallback: (v) =>
                    formatClock(Duration(milliseconds: v.round())),
                onChangeStart: known
                    ? (v) => setState(() => _dragMs = v)
                    : null,
                onChanged: known ? (v) => setState(() => _dragMs = v) : null,
                onChangeEnd: known
                    ? (v) async {
                        await widget.player.seek(
                          Duration(milliseconds: v.round()),
                        );
                        if (mounted) setState(() => _dragMs = null);
                      }
                    : null,
              ),
            ),
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 4),
              child: Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Text(
                    formatClock(position),
                    style: theme.textTheme.labelSmall,
                  ),
                  Text(
                    known
                        ? '-${formatClock(progress.duration! - position)}'
                        : '--:--',
                    style: theme.textTheme.labelSmall,
                  ),
                ],
              ),
            ),
          ],
        );
      },
    );
  }
}

class _Controls extends StatelessWidget {
  const _Controls({required this.media, required this.player});

  final PlayableMedia media;
  final AudioPlayerService player;

  @override
  Widget build(BuildContext context) {
    final colors = Theme.of(context).colorScheme;
    final stop = IconButton(
      tooltip: 'Stop',
      iconSize: 28,
      color: colors.onSurfaceVariant,
      icon: const Icon(Icons.stop_rounded),
      onPressed: player.stop,
    );

    if (media.isLive) {
      return Row(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          const SizedBox(width: 56),
          const Spacer(),
          _BigPlayButton(player: player),
          const Spacer(),
          SizedBox(width: 56, child: stop),
        ],
      );
    }

    return Row(
      mainAxisAlignment: MainAxisAlignment.spaceBetween,
      children: [
        SizedBox(width: 56, child: _SpeedButton(player: player)),
        IconButton(
          tooltip: 'Back 10 seconds',
          iconSize: 36,
          icon: const Icon(Icons.replay_10_rounded),
          onPressed: () => player.skip(-NowPlayingScreen.skipInterval),
        ),
        _BigPlayButton(player: player),
        IconButton(
          tooltip: 'Forward 10 seconds',
          iconSize: 36,
          icon: const Icon(Icons.forward_10_rounded),
          onPressed: () => player.skip(NowPlayingScreen.skipInterval),
        ),
        SizedBox(width: 56, child: stop),
      ],
    );
  }
}

class _BigPlayButton extends StatelessWidget {
  const _BigPlayButton({required this.player});

  final AudioPlayerService player;

  static const _size = 76.0;

  @override
  Widget build(BuildContext context) {
    final colors = Theme.of(context).colorScheme;

    return StreamBuilder<PlaybackStatus>(
      stream: player.statusStream,
      initialData: player.status,
      builder: (context, snapshot) {
        final status = snapshot.data ?? PlaybackStatus.idle;
        final (icon, tooltip, action) = switch (status) {
          PlaybackStatus.playing => (
            Icons.pause_rounded,
            'Pause',
            player.pause,
          ),
          PlaybackStatus.error => (
            Icons.refresh_rounded,
            'Retry',
            player.retry,
          ),
          _ => (Icons.play_arrow_rounded, 'Play', player.resume),
        };

        return Tooltip(
          message: status == PlaybackStatus.loading ? 'Loading' : tooltip,
          child: Material(
            color: colors.primary,
            shape: const CircleBorder(),
            elevation: 6,
            shadowColor: colors.primary.withValues(alpha: 0.5),
            child: InkWell(
              customBorder: const CircleBorder(),
              onTap: status == PlaybackStatus.loading ? null : action,
              child: SizedBox.square(
                dimension: _size,
                child: Center(
                  child: status == PlaybackStatus.loading
                      ? SizedBox.square(
                          dimension: 28,
                          child: CircularProgressIndicator(
                            strokeWidth: 3,
                            color: colors.onPrimary,
                          ),
                        )
                      : AnimatedSwitcher(
                          duration: const Duration(milliseconds: 180),
                          transitionBuilder: (child, animation) =>
                              ScaleTransition(scale: animation, child: child),
                          child: Icon(
                            icon,
                            key: ValueKey(icon),
                            size: 44,
                            color: colors.onPrimary,
                          ),
                        ),
                ),
              ),
            ),
          ),
        );
      },
    );
  }
}

/// Tap to cycle 0.75× → 1× → … → 2×.
class _SpeedButton extends StatelessWidget {
  const _SpeedButton({required this.player});

  final AudioPlayerService player;

  static String label(double speed) =>
      '${speed.toStringAsFixed(2).replaceFirst(RegExp(r'\.?0+$'), '')}×';

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    const speeds = PlaybackMemory.speeds;
    final current = player.speed;

    return TextButton(
      style: TextButton.styleFrom(
        foregroundColor: current == 1.0
            ? theme.colorScheme.onSurfaceVariant
            : theme.colorScheme.primary,
        padding: EdgeInsets.zero,
        minimumSize: const Size(48, 40),
      ),
      onPressed: () {
        final i = speeds.indexOf(current);
        player.setSpeed(speeds[(i + 1) % speeds.length]);
      },
      child: Semantics(
        label: 'Playback speed ${label(current)}',
        child: Text(label(current), style: theme.textTheme.titleSmall),
      ),
    );
  }
}
