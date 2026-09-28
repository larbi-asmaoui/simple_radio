import 'dart:ui' show PlatformDispatcher;

import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:shared_preferences/shared_preferences.dart';

import 'app_settings.dart';

/// Loaded once in `main()` and injected with an override, so everything
/// downstream can read preferences synchronously.
final sharedPreferencesProvider = Provider<SharedPreferences>(
  (ref) => throw UnimplementedError('Override in main() / tests'),
);

final settingsProvider = NotifierProvider<SettingsController, AppSettings>(
  SettingsController.new,
);

class SettingsController extends Notifier<AppSettings> {
  static const _kFont = 'font';
  static const _kCountry = 'country_code';

  /// Keys from the removed Listen Notes integration. Deleted on launch so
  /// an old API key doesn't linger on the device.
  static const _legacyKeys = ['podcast_source', 'listen_notes_api_key'];

  SharedPreferences get _prefs => ref.read(sharedPreferencesProvider);

  @override
  AppSettings build() {
    final prefs = ref.watch(sharedPreferencesProvider);
    for (final key in _legacyKeys) {
      if (prefs.containsKey(key)) prefs.remove(key);
    }
    return AppSettings(
      font:
          _byName(AppFont.values, prefs.getString(_kFont)) ?? AppFont.reelhouse,
      countryCode: prefs.getString(_kCountry) ?? _deviceCountry(),
    );
  }

  void setFont(AppFont font) {
    _prefs.setString(_kFont, font.name);
    state = state.copyWith(font: font);
  }

  void setCountry(String code) {
    _prefs.setString(_kCountry, code);
    state = state.copyWith(countryCode: code);
  }

  static T? _byName<T extends Enum>(List<T> values, String? name) {
    for (final v in values) {
      if (v.name == name) return v;
    }
    return null;
  }

  /// First launch: use the device region if we offer it, else worldwide.
  static String _deviceCountry() {
    final code = PlatformDispatcher.instance.locale.countryCode?.toUpperCase();
    return kRegions.any((r) => r.$1 == code) ? code! : '';
  }
}
