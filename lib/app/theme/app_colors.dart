import 'package:flutter/material.dart';

/// "Reelhouse" design tokens, shared with the streaming-site-next web app
/// (`src/app/globals.css`): a velvet-seat plum background with a warm
/// marquee-bulb amber as the single accent. Dark only, like the site.
///
/// Values are the site's OKLCH tokens converted to sRGB.
abstract final class AppColors {
  static const background = Color(0xFF0F0A10); // oklch(0.155 0.014 320)
  static const foreground = Color(0xFFF6F3EF); // oklch(0.965 0.006 80)
  static const card = Color(0xFF19141B); // oklch(0.2 0.016 320)
  static const popover = Color(0xFF1A151C); // oklch(0.205 0.016 320)
  static const primary = Color(0xFFFFC744); // oklch(0.86 0.155 84)
  static const primaryForeground = Color(0xFF281606); // oklch(0.22 0.04 60)
  static const secondary = Color(0xFF28212A); // oklch(0.26 0.018 320)
  static const muted = Color(0xFF231D24); // oklch(0.24 0.016 320)
  static const mutedForeground = Color(0xFFA9A2AA); // oklch(0.72 0.014 320)
  static const accent = Color(0xFF302832); // oklch(0.29 0.022 320)
  static const destructive = Color(0xFFFF6367); // oklch(0.7 0.19 22)
  static const sidebar = Color(0xFF150F16); // oklch(0.18 0.015 320)
  static const border = Color(0x17FFFFFF); // white 9%
  static const input = Color(0x21FFFFFF); // white 13%

  /// `--radius: 0.625rem`
  static const radius = 10.0;
}
