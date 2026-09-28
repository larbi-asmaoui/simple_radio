import 'package:flutter/material.dart';

import '../../../../common/widgets/artwork.dart';
import '../../models/podcast.dart';

/// Hero tag shared by the list tile and the episode screen header.
String podcastArtworkHeroTag(Podcast podcast) => 'podcast-art-${podcast.id}';

/// List row: artwork, title, publisher.
class PodcastTile extends StatelessWidget {
  const PodcastTile({super.key, required this.podcast, required this.onTap});

  final Podcast podcast;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

    return InkWell(
      onTap: onTap,
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
        child: Row(
          children: [
            Hero(
              tag: podcastArtworkHeroTag(podcast),
              child: Artwork(
                url: podcast.artworkUrl,
                size: 72,
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
                    maxLines: 2,
                    overflow: TextOverflow.ellipsis,
                    style: theme.textTheme.titleMedium,
                  ),
                  const SizedBox(height: 4),
                  Text(
                    podcast.publisher,
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                    style: theme.textTheme.bodyMedium?.copyWith(
                      color: theme.colorScheme.onSurfaceVariant,
                    ),
                  ),
                ],
              ),
            ),
            Icon(
              Icons.chevron_right_rounded,
              color: theme.colorScheme.onSurfaceVariant,
            ),
          ],
        ),
      ),
    );
  }
}
