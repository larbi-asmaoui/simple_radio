import 'package:flutter/foundation.dart';

/// Typefaces offered in Settings. All but [system] come from Google Fonts.
enum AppFont {
  /// The streaming-site-next pairing.
  reelhouse('Reelhouse', 'Instrument Sans', 'Big Shoulders'),
  plusJakartaSans(
    'Plus Jakarta Sans',
    'Plus Jakarta Sans',
    'Plus Jakarta Sans',
  ),
  outfit('Outfit', 'Outfit', 'Outfit'),
  manrope('Manrope', 'Manrope', 'Manrope'),
  spaceGrotesk('Space Grotesk', 'Space Grotesk', 'Space Grotesk'),
  system('System default', null, null);

  const AppFont(this.label, this.bodyFamily, this.displayFamily);

  final String label;

  /// Google Fonts family for text; null means the platform font.
  final String? bodyFamily;

  /// Google Fonts family for large headings; null means the platform font.
  final String? displayFamily;
}

@immutable
class AppSettings {
  const AppSettings({this.font = AppFont.reelhouse, this.countryCode = ''});

  final AppFont font;

  /// ISO 3166-1 alpha-2 (uppercase). Empty means worldwide.
  final String countryCode;

  /// Apple's podcast charts need a region; worldwide maps to the US charts.
  String get podcastRegion =>
      countryCode.isEmpty ? 'us' : countryCode.toLowerCase();

  AppSettings copyWith({AppFont? font, String? countryCode}) => AppSettings(
    font: font ?? this.font,
    countryCode: countryCode ?? this.countryCode,
  );
}

/// Regions offered in Settings (code, display name). '' = worldwide.
const kRegions = <(String, String)>[
  ('', 'Worldwide'),
  ('US', 'United States'),
  ('GB', 'United Kingdom'),
  ('CA', 'Canada'),
  ('AU', 'Australia'),
  ('IE', 'Ireland'),
  ('FR', 'France'),
  ('DE', 'Germany'),
  ('ES', 'Spain'),
  ('IT', 'Italy'),
  ('PT', 'Portugal'),
  ('NL', 'Netherlands'),
  ('BE', 'Belgium'),
  ('CH', 'Switzerland'),
  ('SE', 'Sweden'),
  ('NO', 'Norway'),
  ('PL', 'Poland'),
  ('MA', 'Morocco'),
  ('DZ', 'Algeria'),
  ('TN', 'Tunisia'),
  ('EG', 'Egypt'),
  ('SA', 'Saudi Arabia'),
  ('AE', 'United Arab Emirates'),
  ('TR', 'Türkiye'),
  ('IN', 'India'),
  ('JP', 'Japan'),
  ('KR', 'South Korea'),
  ('BR', 'Brazil'),
  ('MX', 'Mexico'),
  ('AR', 'Argentina'),
  ('ZA', 'South Africa'),
  ('NG', 'Nigeria'),
];

String regionName(String code) =>
    kRegions.firstWhere((r) => r.$1 == code, orElse: () => (code, code)).$2;

/// 'FR' -> 🇫🇷, '' -> 🌍
String flagEmoji(String code) {
  if (code.length != 2) return '🌍';
  const base = 0x1F1E6 - 0x41; // Regional indicator 'A' minus ASCII 'A'.
  return String.fromCharCodes(
    code.toUpperCase().codeUnits.map((c) => base + c),
  );
}
