import 'package:flutter/material.dart';

/// Brand-colored "LIVE" pill for radio streams. With [pulsing], a dot
/// breathes in front of the label to show the stream is on air.
class LiveBadge extends StatelessWidget {
  const LiveBadge({super.key, this.pulsing = false, this.large = false});

  final bool pulsing;

  /// Bigger variant for the Now Playing page.
  final bool large;

  @override
  Widget build(BuildContext context) {
    final colors = Theme.of(context).colorScheme;
    final fontSize = large ? 11.0 : 9.0;

    return Container(
      padding: EdgeInsets.symmetric(
        horizontal: large ? 8 : 5,
        vertical: large ? 3 : 1,
      ),
      decoration: BoxDecoration(
        color: colors.primary,
        borderRadius: BorderRadius.circular(4),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          if (pulsing) ...[
            _PulsingDot(color: colors.onPrimary, size: fontSize * 0.6),
            SizedBox(width: fontSize * 0.45),
          ],
          Text(
            'LIVE',
            style: TextStyle(
              color: colors.onPrimary,
              fontSize: fontSize,
              fontWeight: FontWeight.w800,
              letterSpacing: 0.6,
            ),
          ),
        ],
      ),
    );
  }
}

class _PulsingDot extends StatefulWidget {
  const _PulsingDot({required this.color, required this.size});

  final Color color;
  final double size;

  @override
  State<_PulsingDot> createState() => _PulsingDotState();
}

class _PulsingDotState extends State<_PulsingDot>
    with SingleTickerProviderStateMixin {
  late final _controller = AnimationController(
    vsync: this,
    duration: const Duration(milliseconds: 900),
  )..repeat(reverse: true);

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return FadeTransition(
      opacity: Tween(begin: 0.25, end: 1.0).animate(_controller),
      child: Container(
        width: widget.size,
        height: widget.size,
        decoration: BoxDecoration(color: widget.color, shape: BoxShape.circle),
      ),
    );
  }
}
