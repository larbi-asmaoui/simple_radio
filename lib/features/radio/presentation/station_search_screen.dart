import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../common/widgets/search_app_bar.dart';
import '../../../common/widgets/state_views.dart';
import '../providers/radio_providers.dart';
import 'radio_screen.dart';

/// Live search against Radio Browser by station name.
class StationSearchScreen extends ConsumerStatefulWidget {
  const StationSearchScreen({super.key});

  @override
  ConsumerState<StationSearchScreen> createState() =>
      _StationSearchScreenState();
}

class _StationSearchScreenState extends ConsumerState<StationSearchScreen> {
  String _query = '';

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: SearchAppBar(
        hintText: 'Search stations',
        onQueryChanged: (q) => setState(() => _query = q),
      ),
      body: _query.length < 2
          ? const MessageView(
              icon: Icons.search_rounded,
              message: 'Find a station by name.',
            )
          : switch (ref.watch(stationSearchProvider(_query))) {
              AsyncData(:final value) when value.isEmpty => MessageView(
                icon: Icons.search_off_rounded,
                message: 'No stations match "$_query".',
              ),
              AsyncData(:final value) => StationGrid(stations: value),
              AsyncError(:final error) => MessageView.error(
                error,
                onRetry: () => ref.invalidate(stationSearchProvider(_query)),
              ),
              _ => const Center(child: CircularProgressIndicator()),
            },
    );
  }
}
