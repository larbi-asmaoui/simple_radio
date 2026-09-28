import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../common/widgets/search_app_bar.dart';
import '../../../common/widgets/state_views.dart';
import '../providers/podcast_providers.dart';
import 'podcast_screen.dart';

class PodcastSearchScreen extends ConsumerStatefulWidget {
  const PodcastSearchScreen({super.key});

  @override
  ConsumerState<PodcastSearchScreen> createState() =>
      _PodcastSearchScreenState();
}

class _PodcastSearchScreenState extends ConsumerState<PodcastSearchScreen> {
  String _query = '';

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: SearchAppBar(
        hintText: 'Search podcasts',
        onQueryChanged: (q) => setState(() => _query = q),
      ),
      body: _query.length < 2
          ? const MessageView(
              icon: Icons.search_rounded,
              message: 'Find a show by name, topic or host.',
            )
          : switch (ref.watch(podcastSearchProvider(_query))) {
              AsyncData(:final value) when value.isEmpty => MessageView(
                icon: Icons.search_off_rounded,
                message: 'No podcasts match "$_query".',
              ),
              AsyncData(:final value) => PodcastList(podcasts: value),
              AsyncError(:final error) => MessageView.error(
                error,
                onRetry: () => ref.invalidate(podcastSearchProvider(_query)),
              ),
              _ => const Center(child: CircularProgressIndicator()),
            },
    );
  }
}
