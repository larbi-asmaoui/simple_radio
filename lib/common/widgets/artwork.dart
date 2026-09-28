import 'package:flutter/material.dart';

/// Rounded network artwork with a themed placeholder while loading and a
/// fallback icon when the image fails (offline, dead URL, widget tests).
class Artwork extends StatelessWidget {
  const Artwork({
    super.key,
    required this.url,
    this.size,
    this.borderRadius = 8,
    this.fallbackIcon = Icons.radio_rounded,
  });

  final String url;

  /// Square edge length. When null the artwork fills its parent.
  final double? size;
  final double borderRadius;
  final IconData fallbackIcon;

  @override
  Widget build(BuildContext context) {
    final colors = Theme.of(context).colorScheme;

    final placeholder = ColoredBox(
      color: colors.surfaceContainerHigh,
      child: Center(
        child: Icon(
          fallbackIcon,
          color: colors.onSurfaceVariant,
          size: size == null ? 40 : size! * 0.45,
        ),
      ),
    );

    return ClipRRect(
      borderRadius: BorderRadius.circular(borderRadius),
      child: SizedBox(
        width: size,
        height: size,
        // Many radio stations have no favicon at all.
        child: url.isEmpty
            ? placeholder
            : Image(
                image: NetworkImage(url),
                fit: BoxFit.cover,
                // Fade the image in over the placeholder once the first frame lands.
                frameBuilder: (context, child, frame, wasSynchronouslyLoaded) {
                  if (wasSynchronouslyLoaded) return child;
                  return Stack(
                    fit: StackFit.expand,
                    children: [
                      placeholder,
                      AnimatedOpacity(
                        opacity: frame == null ? 0 : 1,
                        duration: const Duration(milliseconds: 250),
                        curve: Curves.easeOut,
                        child: child,
                      ),
                    ],
                  );
                },
                errorBuilder: (_, _, _) => placeholder,
              ),
      ),
    );
  }
}
