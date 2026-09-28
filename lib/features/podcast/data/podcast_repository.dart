import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../core/network/dio_provider.dart';
import '../models/podcast.dart';
import 'apple_rss_podcast_repository.dart';

abstract interface class PodcastRepository {
  /// Human-readable attribution shown under podcast lists.
  String get attribution;

  Future<List<Podcast>> topPodcasts({required String region});

  Future<List<Podcast>> search(String query, {required String region});

  Future<PodcastDetails> details(Podcast podcast);
}

/// Apple Podcasts for discovery + each show's RSS feed. Free, no API key.
/// An interface so tests can swap in fake data.
final podcastRepositoryProvider = Provider<PodcastRepository>(
  (ref) => AppleRssPodcastRepository(ref.watch(dioProvider)),
);
