import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../common/widgets/state_views.dart';
import '../../player/providers/player_providers.dart';
import '../data/podcast_repository.dart';
import '../models/podcast.dart';
import '../providers/podcast_providers.dart';
import 'episode_list_screen.dart';
import 'podcast_search_screen.dart';
import 'widgets/podcast_tile.dart';

class PodcastScreen extends ConsumerWidget {
  const PodcastScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final podcasts = ref.watch(topPodcastsProvider);

    return Scaffold(
      appBar: AppBar(
        title: const Text('Podcasts'),
        actions: [
          IconButton(
            tooltip: 'Search podcasts',
            icon: const Icon(Icons.search_rounded),
            onPressed: () => Navigator.of(context).push(
              MaterialPageRoute<void>(
                builder: (_) => const PodcastSearchScreen(),
              ),
            ),
          ),
          const SizedBox(width: 4),
        ],
      ),
      body: RefreshIndicator(
        onRefresh: () => ref.refresh(topPodcastsProvider.future),
        child: switch (podcasts) {
          AsyncData(:final value) => PodcastList(podcasts: value),
          AsyncError(:final error) => ListView(
            children: [
              const SizedBox(height: 80),
              MessageView.error(
                error,
                onRetry: () => ref.invalidate(topPodcastsProvider),
              ),
            ],
          ),
          _ => const _ListSkeleton(),
        },
      ),
    );
  }
}

/// Podcast rows + source attribution. Shared by the tab and search results.
class PodcastList extends ConsumerWidget {
  const PodcastList({super.key, required this.podcasts});

  final List<Podcast> podcasts;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final bottomInset = ref.watch(playerInsetProvider);
    final attribution = ref.watch(podcastRepositoryProvider).attribution;
    final theme = Theme.of(context);

    return ListView.builder(
      padding: EdgeInsets.only(top: 4, bottom: 8 + bottomInset),
      itemCount: podcasts.length + 1,
      itemBuilder: (context, index) {
        if (index == podcasts.length) {
          return Padding(
            padding: const EdgeInsets.all(24),
            child: Text(
              attribution,
              textAlign: TextAlign.center,
              style: theme.textTheme.bodySmall,
            ),
          );
        }
        final podcast = podcasts[index];
        return PodcastTile(
          podcast: podcast,
          onTap: () => openPodcast(context, podcast),
        );
      },
    );
  }
}

/// Pushes onto the current tab's Navigator, so the bottom bar and the
/// persistent player stay visible.
void openPodcast(BuildContext context, Podcast podcast) {
  Navigator.of(context).push(
    MaterialPageRoute<void>(
      builder: (_) => EpisodeListScreen(podcast: podcast),
    ),
  );
}

class _ListSkeleton extends StatelessWidget {
  const _ListSkeleton();

  @override
  Widget build(BuildContext context) {
    return ListView.builder(
      physics: const NeverScrollableScrollPhysics(),
      itemCount: 8,
      itemBuilder: (_, _) => const Padding(
        padding: EdgeInsets.symmetric(horizontal: 16, vertical: 8),
        child: Row(
          children: [
            SkeletonBox(width: 72, height: 72),
            SizedBox(width: 16),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  SkeletonBox(height: 16, width: 180),
                  SizedBox(height: 8),
                  SkeletonBox(height: 12, width: 110),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
}
