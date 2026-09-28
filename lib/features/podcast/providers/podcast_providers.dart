import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../core/settings/settings_controller.dart';
import '../data/podcast_repository.dart';
import '../models/podcast.dart';

// Lists are de-duplicated (Podcast == is by id): each row carries a Hero,
// and two heroes with the same tag on one screen is an error.

final topPodcastsProvider = FutureProvider<List<Podcast>>((ref) async {
  final region = ref.watch(settingsProvider.select((s) => s.podcastRegion));
  final repo = ref.watch(podcastRepositoryProvider);
  return (await repo.topPodcasts(region: region)).toSet().toList();
});

final podcastSearchProvider = FutureProvider.autoDispose
    .family<List<Podcast>, String>((ref, query) async {
      final region = ref.watch(settingsProvider.select((s) => s.podcastRegion));
      final repo = ref.watch(podcastRepositoryProvider);
      return (await repo.search(query, region: region)).toSet().toList();
    });

/// Kept for the session (not autoDispose): reopening a show is instant
/// instead of re-downloading its feed.
final podcastDetailsProvider = FutureProvider.family<PodcastDetails, Podcast>(
  (ref, podcast) => ref.watch(podcastRepositoryProvider).details(podcast),
);
