import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../common/models/playable_media.dart';
import '../../../common/widgets/artwork.dart';
import '../../../common/widgets/state_views.dart';
import '../../../core/navigation/app_tab.dart';
import '../../../core/settings/app_settings.dart';
import '../../../core/settings/settings_controller.dart';
import '../../player/data/recently_played.dart';
import '../../player/providers/playback_actions.dart';
import '../../player/providers/player_providers.dart';
import '../../podcast/models/podcast.dart';
import '../../podcast/presentation/podcast_screen.dart';
import '../../podcast/presentation/widgets/podcast_tile.dart';
import '../../podcast/providers/podcast_providers.dart';
import '../../radio/models/radio_station.dart';
import '../../radio/providers/radio_providers.dart';

/// Landing tab: history, popular stations, genres and top podcasts.
class HomeScreen extends ConsumerWidget {
  const HomeScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final recents = ref.watch(recentlyPlayedProvider);
    final country = ref.watch(settingsProvider.select((s) => s.countryCode));
    final bottomInset = ref.watch(playerInsetProvider);

    void openRadio([RadioGenre? genre]) {
      ref
          .read(selectedGenreProvider.notifier)
          .select(genre ?? kRadioGenres.first);
      ref.read(selectedTabProvider.notifier).select(AppTab.radio);
    }

    return Scaffold(
      appBar: AppBar(title: const _Brand()),
      body: RefreshIndicator(
        onRefresh: () => Future.wait([
          ref.refresh(stationsProvider(null).future),
          ref.refresh(topPodcastsProvider.future),
        ]),
        child: ListView(
          padding: EdgeInsets.only(bottom: 16 + bottomInset),
          children: [
            const _Greeting(),
            if (recents.isNotEmpty) ...[
              const SectionHeader(title: 'Recently played'),
              _Carousel(
                height: 188,
                itemCount: recents.length,
                itemBuilder: (context, i) => _RecentCard(media: recents[i]),
              ),
            ],
            SectionHeader(
              title: 'Popular stations ${flagEmoji(country)}',
              onSeeAll: openRadio,
            ),
            _AsyncCarousel<RadioStation>(
              value: ref.watch(stationsProvider(null)),
              onRetry: () => ref.invalidate(stationsProvider(null)),
              height: 188,
              itemBuilder: (context, station) => _MediaCard(
                artworkUrl: station.artworkUrl,
                title: station.name,
                subtitle: station.genre,
                onTap: () => ref.playStation(station),
              ),
            ),
            const SectionHeader(title: 'Browse genres'),
            _GenreGrid(onSelected: openRadio),
            SectionHeader(
              title: 'Top podcasts',
              onSeeAll: () => ref
                  .read(selectedTabProvider.notifier)
                  .select(AppTab.podcasts),
            ),
            _AsyncCarousel<Podcast>(
              value: ref.watch(topPodcastsProvider),
              onRetry: () => ref.invalidate(topPodcastsProvider),
              height: 188,
              itemBuilder: (context, podcast) => _MediaCard(
                artworkUrl: podcast.artworkUrl,
                title: podcast.title,
                subtitle: podcast.publisher,
                heroTag: podcastArtworkHeroTag(podcast),
                fallbackIcon: Icons.podcasts_rounded,
                onTap: () => openPodcast(context, podcast),
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _Brand extends StatelessWidget {
  const _Brand();

  @override
  Widget build(BuildContext context) {
    final colors = Theme.of(context).colorScheme;
    return Row(
      children: [
        Container(
          width: 32,
          height: 32,
          decoration: BoxDecoration(
            color: colors.primary,
            borderRadius: BorderRadius.circular(9),
          ),
          child: Icon(
            Icons.graphic_eq_rounded,
            color: colors.onPrimary,
            size: 20,
          ),
        ),
        const SizedBox(width: 10),
        const Flexible(
          child: Text('SimpleRadio', overflow: TextOverflow.ellipsis),
        ),
      ],
    );
  }
}

class _Greeting extends StatelessWidget {
  const _Greeting();

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final hour = DateTime.now().hour;
    final greeting = switch (hour) {
      < 5 => 'Late night vibes',
      < 12 => 'Good morning',
      < 18 => 'Good afternoon',
      _ => 'Good evening',
    };
    return Padding(
      padding: const EdgeInsets.fromLTRB(16, 8, 16, 0),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            greeting,
            style: theme.textTheme.headlineMedium?.copyWith(
              fontWeight: FontWeight.w800,
              letterSpacing: -0.5,
            ),
          ),
          const SizedBox(height: 4),
          Text(
            'What do you want to listen to?',
            style: theme.textTheme.bodyLarge?.copyWith(
              color: theme.colorScheme.onSurfaceVariant,
            ),
          ),
        ],
      ),
    );
  }
}

class _Carousel extends StatelessWidget {
  const _Carousel({
    required this.height,
    required this.itemCount,
    required this.itemBuilder,
  });

  final double height;
  final int itemCount;
  final IndexedWidgetBuilder itemBuilder;

  @override
  Widget build(BuildContext context) {
    return SizedBox(
      height: height,
      child: ListView.separated(
        scrollDirection: Axis.horizontal,
        padding: const EdgeInsets.symmetric(horizontal: 16),
        itemCount: itemCount,
        separatorBuilder: (_, _) => const SizedBox(width: 12),
        itemBuilder: itemBuilder,
      ),
    );
  }
}

/// Horizontal list over an async source, with skeleton and inline error.
class _AsyncCarousel<T> extends StatelessWidget {
  const _AsyncCarousel({
    required this.value,
    required this.onRetry,
    required this.height,
    required this.itemBuilder,
  });

  final AsyncValue<List<T>> value;
  final VoidCallback onRetry;
  final double height;
  final Widget Function(BuildContext, T) itemBuilder;

  static const _maxItems = 15;

  @override
  Widget build(BuildContext context) {
    return switch (value) {
      AsyncData(:final value) => _Carousel(
        height: height,
        itemCount: value.length.clamp(0, _maxItems),
        itemBuilder: (context, i) => itemBuilder(context, value[i]),
      ),
      AsyncError(:final error) => SizedBox(
        height: height,
        child: MessageView.error(error, onRetry: onRetry),
      ),
      _ => _Carousel(
        height: height,
        itemCount: 4,
        itemBuilder: (_, _) => const Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            SkeletonBox(width: 128, height: 128, radius: 10),
            SizedBox(height: 10),
            SkeletonBox(width: 100, height: 12),
            SizedBox(height: 6),
            SkeletonBox(width: 70, height: 10),
          ],
        ),
      ),
    };
  }
}

class _MediaCard extends StatelessWidget {
  const _MediaCard({
    required this.artworkUrl,
    required this.title,
    required this.subtitle,
    required this.onTap,
    this.heroTag,
    this.fallbackIcon = Icons.radio_rounded,
    this.progress,
  });

  final String artworkUrl;
  final String title;
  final String subtitle;
  final VoidCallback onTap;
  final Object? heroTag;
  final IconData fallbackIcon;

  /// Listening progress (0..1) drawn along the artwork's bottom edge.
  final double? progress;

  static const _size = 128.0;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    Widget art = Artwork(
      url: artworkUrl,
      size: _size,
      borderRadius: 10,
      fallbackIcon: fallbackIcon,
    );
    if (heroTag != null) art = Hero(tag: heroTag!, child: art);
    if (progress case final p?) {
      art = Stack(
        children: [
          art,
          Positioned(
            left: 8,
            right: 8,
            bottom: 8,
            child: ClipRRect(
              borderRadius: BorderRadius.circular(2),
              child: LinearProgressIndicator(
                value: p,
                minHeight: 3,
                backgroundColor: Colors.black54,
              ),
            ),
          ),
        ],
      );
    }

    return SizedBox(
      width: _size,
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(10),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            art,
            const SizedBox(height: 8),
            Text(
              title,
              maxLines: 1,
              overflow: TextOverflow.ellipsis,
              style: theme.textTheme.titleSmall,
            ),
            const SizedBox(height: 2),
            Text(
              subtitle,
              maxLines: 1,
              overflow: TextOverflow.ellipsis,
              style: theme.textTheme.bodySmall,
            ),
          ],
        ),
      ),
    );
  }
}

class _RecentCard extends ConsumerWidget {
  const _RecentCard({required this.media});

  final PlayableMedia media;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final saved = media.isLive
        ? null
        : ref.watch(
            playbackMemoryProvider.select((m) => m.positionOf(media.id)),
          );
    return _MediaCard(
      artworkUrl: media.artworkUrl,
      title: media.title,
      subtitle: media.isLive ? 'Live · ${media.subtitle}' : media.subtitle,
      fallbackIcon: media.isLive ? Icons.radio_rounded : Icons.podcasts_rounded,
      // Tapping resumes from the saved position (the player handles that).
      progress: saved == null || saved.finished ? null : saved.fraction,
      onTap: () => ref.playMedia(media),
    );
  }
}

class _GenreGrid extends StatelessWidget {
  const _GenreGrid({required this.onSelected});

  final ValueChanged<RadioGenre> onSelected;

  @override
  Widget build(BuildContext context) {
    final genres = kRadioGenres.where((g) => g.tag != null).toList();
    return GridView.builder(
      shrinkWrap: true,
      physics: const NeverScrollableScrollPhysics(),
      padding: const EdgeInsets.symmetric(horizontal: 16),
      gridDelegate: const SliverGridDelegateWithMaxCrossAxisExtent(
        maxCrossAxisExtent: 220,
        mainAxisExtent: 72,
        mainAxisSpacing: 10,
        crossAxisSpacing: 10,
      ),
      itemCount: genres.length,
      itemBuilder: (context, i) =>
          _GenreTile(genre: genres[i], onTap: () => onSelected(genres[i])),
    );
  }
}

class _GenreTile extends StatelessWidget {
  const _GenreTile({required this.genre, required this.onTap});

  final RadioGenre genre;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    final hsl = HSLColor.fromColor(genre.color);
    final darker = hsl
        .withLightness((hsl.lightness - 0.15).clamp(0, 1))
        .toColor();

    return Material(
      borderRadius: BorderRadius.circular(10),
      clipBehavior: Clip.antiAlias,
      child: Ink(
        decoration: BoxDecoration(
          gradient: LinearGradient(
            begin: Alignment.topLeft,
            end: Alignment.bottomRight,
            colors: [genre.color, darker],
          ),
        ),
        child: InkWell(
          onTap: onTap,
          child: Stack(
            children: [
              Positioned(
                right: -8,
                bottom: -10,
                child: Transform.rotate(
                  angle: 0.35,
                  child: Icon(genre.icon, size: 60, color: Colors.white24),
                ),
              ),
              Padding(
                padding: const EdgeInsets.all(12),
                child: Text(
                  genre.label,
                  style: Theme.of(context).textTheme.titleMedium?.copyWith(
                    color: Colors.white,
                    fontWeight: FontWeight.w800,
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
