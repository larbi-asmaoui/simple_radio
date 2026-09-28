import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../common/utils/text_utils.dart';
import '../../../common/widgets/artwork.dart';
import '../../../common/widgets/state_views.dart';
import '../../player/data/audio_player_service.dart';
import '../../player/data/playback_memory.dart';
import '../../player/providers/playback_actions.dart';
import '../../player/providers/player_providers.dart';
import '../models/podcast.dart';
import '../providers/podcast_providers.dart';
import 'widgets/podcast_tile.dart';

class EpisodeListScreen extends ConsumerWidget {
  const EpisodeListScreen({super.key, required this.podcast});

  final Podcast podcast;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final details = ref.watch(podcastDetailsProvider(podcast));
    final bottomInset = ref.watch(playerInsetProvider);

    return Scaffold(
      body: RefreshIndicator(
        edgeOffset: kToolbarHeight + MediaQuery.paddingOf(context).top,
        onRefresh: () => ref.refresh(podcastDetailsProvider(podcast).future),
        child: CustomScrollView(
          slivers: [
            SliverAppBar(
              pinned: true,
              title: Text(
                podcast.title,
                style: Theme.of(context).textTheme.titleMedium,
              ),
            ),
            SliverToBoxAdapter(
              child: _Header(
                podcast: podcast,
                // Charts/search results may lack a description; the feed has it.
                description: details.value?.description.isNotEmpty == true
                    ? details.value!.description
                    : podcast.description,
              ),
            ),
            switch (details) {
              AsyncData(:final value) when value.episodes.isEmpty =>
                const SliverToBoxAdapter(
                  child: MessageView(
                    icon: Icons.podcasts_rounded,
                    message: 'No playable episodes yet.',
                  ),
                ),
              AsyncData(:final value) => SliverList.separated(
                itemCount: value.episodes.length,
                separatorBuilder: (_, _) =>
                    const Divider(indent: 16, endIndent: 16),
                itemBuilder: (context, index) => _EpisodeRow(
                  podcast: podcast,
                  episode: value.episodes[index],
                ),
              ),
              AsyncError(:final error) => SliverToBoxAdapter(
                child: MessageView.error(
                  error,
                  onRetry: () =>
                      ref.invalidate(podcastDetailsProvider(podcast)),
                ),
              ),
              _ => const SliverToBoxAdapter(
                child: Padding(
                  padding: EdgeInsets.all(48),
                  child: Center(child: CircularProgressIndicator()),
                ),
              ),
            },
            SliverToBoxAdapter(child: SizedBox(height: 16 + bottomInset)),
          ],
        ),
      ),
    );
  }
}

class _Header extends StatelessWidget {
  const _Header({required this.podcast, required this.description});

  final Podcast podcast;
  final String description;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final colors = theme.colorScheme;

    return Padding(
      padding: const EdgeInsets.fromLTRB(16, 8, 16, 16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            crossAxisAlignment: CrossAxisAlignment.end,
            children: [
              Hero(
                tag: podcastArtworkHeroTag(podcast),
                child: Artwork(
                  url: podcast.artworkUrl,
                  size: 136,
                  borderRadius: 12,
                  fallbackIcon: Icons.podcasts_rounded,
                ),
              ),
              const SizedBox(width: 16),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      podcast.title,
                      maxLines: 3,
                      overflow: TextOverflow.ellipsis,
                      style: theme.textTheme.headlineSmall?.copyWith(
                        fontWeight: FontWeight.w800,
                      ),
                    ),
                    const SizedBox(height: 6),
                    Text(
                      podcast.publisher,
                      maxLines: 2,
                      overflow: TextOverflow.ellipsis,
                      style: theme.textTheme.titleSmall?.copyWith(
                        color: colors.primary,
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ),
          if (description.isNotEmpty) ...[
            const SizedBox(height: 16),
            _ExpandableText(description),
          ],
          const SizedBox(height: 24),
          Text('Episodes', style: theme.textTheme.titleLarge),
        ],
      ),
    );
  }
}

/// Collapsed to 3 lines; tap to expand. Show notes can be very long.
class _ExpandableText extends StatefulWidget {
  const _ExpandableText(this.text);

  final String text;

  @override
  State<_ExpandableText> createState() => _ExpandableTextState();
}

class _ExpandableTextState extends State<_ExpandableText> {
  bool _expanded = false;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return GestureDetector(
      onTap: () => setState(() => _expanded = !_expanded),
      child: AnimatedSize(
        duration: const Duration(milliseconds: 200),
        alignment: Alignment.topCenter,
        child: Text(
          widget.text,
          maxLines: _expanded ? null : 3,
          overflow: _expanded ? TextOverflow.visible : TextOverflow.ellipsis,
          style: theme.textTheme.bodyMedium?.copyWith(
            color: theme.colorScheme.onSurfaceVariant,
          ),
        ),
      ),
    );
  }
}

class _EpisodeRow extends ConsumerWidget {
  const _EpisodeRow({required this.podcast, required this.episode});

  final Podcast podcast;
  final Episode episode;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final theme = Theme.of(context);
    final colors = theme.colorScheme;
    final media = episode.toPlayable(podcast);
    final player = ref.watch(audioPlayerProvider);
    final isActive = player.isCurrent(media.id);
    final status = isActive ? player.status : PlaybackStatus.idle;

    // "Resume where I left off": show how far this episode was listened to.
    final saved = ref.watch(playbackMemoryProvider).positionOf(media.id);
    final remaining = saved?.remaining;
    final listening = switch (saved) {
      SavedPosition(finished: true) => 'Played',
      SavedPosition() when remaining != null && remaining.inMinutes >= 1 =>
        '${formatDuration(remaining)} left',
      _ => null,
    };

    final meta = [
      if (episode.publishedAt case final date?) formatDate(date),
      listening ??
          (episode.duration == null ? null : formatDuration(episode.duration!)),
    ].nonNulls.join(' · ');

    return InkWell(
      onTap: () => ref.playMedia(media),
      child: Padding(
        padding: const EdgeInsets.fromLTRB(16, 12, 8, 12),
        child: Row(
          children: [
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  if (meta.isNotEmpty) ...[
                    Text(meta, style: theme.textTheme.labelSmall),
                    const SizedBox(height: 4),
                  ],
                  Text(
                    episode.title,
                    maxLines: 2,
                    overflow: TextOverflow.ellipsis,
                    style: theme.textTheme.titleSmall?.copyWith(
                      color: isActive ? colors.primary : null,
                    ),
                  ),
                  if (episode.description.isNotEmpty) ...[
                    const SizedBox(height: 4),
                    Text(
                      episode.description,
                      maxLines: 2,
                      overflow: TextOverflow.ellipsis,
                      style: theme.textTheme.bodySmall,
                    ),
                  ],
                  if (saved?.fraction case final f?
                      when f > 0 && !saved!.finished) ...[
                    const SizedBox(height: 8),
                    ClipRRect(
                      borderRadius: BorderRadius.circular(2),
                      child: LinearProgressIndicator(
                        value: f,
                        minHeight: 3,
                        backgroundColor: colors.surfaceContainerHighest,
                      ),
                    ),
                  ],
                ],
              ),
            ),
            const SizedBox(width: 8),
            SizedBox.square(
              dimension: 48,
              child: switch (status) {
                PlaybackStatus.loading => const Center(
                  child: SizedBox.square(
                    dimension: 22,
                    child: CircularProgressIndicator(strokeWidth: 2.5),
                  ),
                ),
                PlaybackStatus.playing => IconButton(
                  tooltip: 'Pause',
                  iconSize: 36,
                  color: colors.primary,
                  icon: const Icon(Icons.pause_circle_filled_rounded),
                  onPressed: player.pause,
                ),
                _ => IconButton(
                  tooltip: 'Play',
                  iconSize: 36,
                  color: isActive ? colors.primary : colors.onSurface,
                  icon: const Icon(Icons.play_circle_filled_rounded),
                  onPressed: () => ref.playMedia(media),
                ),
              },
            ),
          ],
        ),
      ),
    );
  }
}
