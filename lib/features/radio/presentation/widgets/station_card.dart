import 'package:flutter/material.dart';

import '../../../../common/widgets/artwork.dart';
import '../../models/radio_station.dart';

/// Grid tile: artwork, station name, genre. The currently playing station
/// gets a brand-colored outline (Material animates the shape change) and an
/// equalizer chip.
class StationCard extends StatelessWidget {
  const StationCard({
    super.key,
    required this.station,
    required this.isActive,
    required this.onTap,
  });

  final RadioStation station;
  final bool isActive;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final colors = theme.colorScheme;

    return Card(
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(12),
        side: BorderSide(
          color: isActive ? colors.primary : Colors.transparent,
          width: 2,
        ),
      ),
      child: InkWell(
        onTap: onTap,
        child: Padding(
          padding: const EdgeInsets.all(10),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              // Expanded (not AspectRatio) so larger text scales shrink the
              // artwork instead of overflowing the tile.
              Expanded(
                child: Stack(
                  fit: StackFit.expand,
                  children: [
                    Artwork(url: station.artworkUrl),
                    Positioned(
                      right: 6,
                      bottom: 6,
                      child: AnimatedScale(
                        scale: isActive ? 1 : 0,
                        duration: const Duration(milliseconds: 220),
                        curve: Curves.easeOutBack,
                        child: CircleAvatar(
                          radius: 14,
                          backgroundColor: colors.primary,
                          child: Icon(
                            Icons.graphic_eq_rounded,
                            size: 18,
                            color: colors.onPrimary,
                          ),
                        ),
                      ),
                    ),
                  ],
                ),
              ),
              const SizedBox(height: 10),
              Text(
                station.name,
                maxLines: 1,
                overflow: TextOverflow.ellipsis,
                style: theme.textTheme.titleSmall?.copyWith(
                  color: isActive ? colors.primary : null,
                ),
              ),
              const SizedBox(height: 2),
              Text(
                station.genre,
                maxLines: 1,
                overflow: TextOverflow.ellipsis,
                style: theme.textTheme.bodySmall,
              ),
            ],
          ),
        ),
      ),
    );
  }
}
