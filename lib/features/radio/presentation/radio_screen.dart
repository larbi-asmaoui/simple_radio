import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../common/widgets/state_views.dart';
import '../../player/providers/player_providers.dart';
import '../models/radio_station.dart';
import '../providers/radio_providers.dart';
import 'station_search_screen.dart';
import 'widgets/station_card.dart';

class RadioScreen extends ConsumerWidget {
  const RadioScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final genre = ref.watch(selectedGenreProvider);
    final stations = ref.watch(stationsProvider(genre.tag));

    return Scaffold(
      appBar: AppBar(
        title: const Text('Radio'),
        actions: [
          IconButton(
            tooltip: 'Search stations',
            icon: const Icon(Icons.search_rounded),
            onPressed: () => Navigator.of(context).push(
              MaterialPageRoute<void>(
                builder: (_) => const StationSearchScreen(),
              ),
            ),
          ),
          const SizedBox(width: 4),
        ],
      ),
      body: Column(
        children: [
          const _GenreChips(),
          Expanded(
            child: RefreshIndicator(
              onRefresh: () => ref.refresh(stationsProvider(genre.tag).future),
              child: switch (stations) {
                AsyncData(:final value) when value.isEmpty => ListView(
                  children: const [
                    SizedBox(height: 80),
                    MessageView(
                      icon: Icons.radio_rounded,
                      message:
                          'No stations found for this genre in your region.',
                    ),
                  ],
                ),
                AsyncData(:final value) => StationGrid(stations: value),
                AsyncError(:final error) => ListView(
                  children: [
                    const SizedBox(height: 80),
                    MessageView.error(
                      error,
                      onRetry: () =>
                          ref.invalidate(stationsProvider(genre.tag)),
                    ),
                  ],
                ),
                _ => const _GridSkeleton(),
              },
            ),
          ),
        ],
      ),
    );
  }
}

/// Station grid shared by the Radio tab and search results.
class StationGrid extends ConsumerWidget {
  const StationGrid({super.key, required this.stations});

  final List<RadioStation> stations;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final bottomInset = ref.watch(playerInsetProvider);
    final currentId = ref.watch(
      audioPlayerProvider.select((p) => p.current?.id),
    );

    return GridView.builder(
      padding: EdgeInsets.fromLTRB(16, 8, 16, 16 + bottomInset),
      gridDelegate: const SliverGridDelegateWithMaxCrossAxisExtent(
        maxCrossAxisExtent: 200,
        mainAxisSpacing: 12,
        crossAxisSpacing: 12,
        childAspectRatio: 0.78,
      ),
      itemCount: stations.length,
      itemBuilder: (context, index) {
        final station = stations[index];
        return StationCard(
          station: station,
          isActive: currentId == station.toPlayable().id,
          onTap: () => ref.playStation(station),
        );
      },
    );
  }
}

class _GenreChips extends ConsumerWidget {
  const _GenreChips();

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final selected = ref.watch(selectedGenreProvider);
    final colors = Theme.of(context).colorScheme;

    return SizedBox(
      height: 48,
      child: ListView.separated(
        scrollDirection: Axis.horizontal,
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 6),
        itemCount: kRadioGenres.length,
        separatorBuilder: (_, _) => const SizedBox(width: 8),
        itemBuilder: (context, index) {
          final genre = kRadioGenres[index];
          final isSelected = genre == selected;
          return ChoiceChip(
            label: Text(genre.label),
            selected: isSelected,
            showCheckmark: false,
            labelStyle: TextStyle(
              color: isSelected ? colors.onPrimary : colors.onSurface,
              fontWeight: FontWeight.w600,
            ),
            onSelected: (_) =>
                ref.read(selectedGenreProvider.notifier).select(genre),
          );
        },
      ),
    );
  }
}

class _GridSkeleton extends StatelessWidget {
  const _GridSkeleton();

  @override
  Widget build(BuildContext context) {
    return GridView.builder(
      physics: const NeverScrollableScrollPhysics(),
      padding: const EdgeInsets.fromLTRB(16, 8, 16, 16),
      gridDelegate: const SliverGridDelegateWithMaxCrossAxisExtent(
        maxCrossAxisExtent: 200,
        mainAxisSpacing: 12,
        crossAxisSpacing: 12,
        childAspectRatio: 0.78,
      ),
      itemCount: 8,
      itemBuilder: (_, _) => const SkeletonBox(radius: 12),
    );
  }
}
