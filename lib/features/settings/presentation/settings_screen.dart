import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:google_fonts/google_fonts.dart';

import '../../../core/settings/app_settings.dart';
import '../../../core/settings/settings_controller.dart';
import '../../player/data/recently_played.dart';
import '../../player/providers/player_providers.dart';

class SettingsScreen extends ConsumerWidget {
  const SettingsScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final settings = ref.watch(settingsProvider);
    final hasHistory = ref.watch(recentlyPlayedProvider).isNotEmpty;
    final bottomInset = ref.watch(playerInsetProvider);

    return Scaffold(
      appBar: AppBar(title: const Text('Settings')),
      body: ListView(
        padding: EdgeInsets.only(bottom: 16 + bottomInset),
        children: [
          const _SectionLabel('Appearance'),
          ListTile(
            leading: const Icon(Icons.text_fields_rounded),
            title: const Text('Font'),
            subtitle: Text(settings.font.label),
            trailing: const Icon(Icons.chevron_right_rounded),
            onTap: () => _pickFont(context, ref),
          ),

          const _SectionLabel('Content'),
          ListTile(
            leading: const Icon(Icons.public_rounded),
            title: const Text('Region'),
            subtitle: Text(
              '${flagEmoji(settings.countryCode)}  ${regionName(settings.countryCode)}'
              ' · stations and podcast charts',
            ),
            trailing: const Icon(Icons.chevron_right_rounded),
            onTap: () => _pickRegion(context, ref),
          ),

          const _SectionLabel('History'),
          ListTile(
            leading: const Icon(Icons.history_rounded),
            title: const Text('Clear recently played'),
            enabled: hasHistory,
            onTap: () {
              ref.read(recentlyPlayedProvider.notifier).clear();
              ScaffoldMessenger.of(
                context,
              ).showSnackBar(const SnackBar(content: Text('History cleared')));
            },
          ),

          const _SectionLabel('About'),
          const ListTile(
            leading: Icon(Icons.info_outline_rounded),
            title: Text('SimpleRadio'),
            subtitle: Text('Version 1.0.0'),
          ),
          const ListTile(
            leading: Icon(Icons.radio_rounded),
            title: Text('Radio directory'),
            subtitle: Text('Radio Browser · radio-browser.info'),
          ),
          const ListTile(
            leading: Icon(Icons.podcasts_rounded),
            title: Text('Podcast directory'),
            subtitle: Text('Apple Podcasts charts · show RSS feeds'),
          ),
        ],
      ),
    );
  }

  Future<void> _pickFont(BuildContext context, WidgetRef ref) {
    final current = ref.read(settingsProvider).font;
    return showModalBottomSheet<void>(
      context: context,
      useRootNavigator: true,
      showDragHandle: true,
      builder: (sheetContext) => SafeArea(
        child: ListView(
          shrinkWrap: true,
          children: [
            for (final font in AppFont.values)
              ListTile(
                title: Text(
                  font.label,
                  style: _fontPreview(
                    font.displayFamily,
                    Theme.of(sheetContext).textTheme.titleLarge,
                  ),
                ),
                subtitle: Text(
                  'The quick brown fox tunes in',
                  style: _fontPreview(
                    font.bodyFamily,
                    Theme.of(sheetContext).textTheme.bodyMedium,
                  ),
                ),
                trailing: font == current
                    ? Icon(
                        Icons.check_rounded,
                        color: Theme.of(sheetContext).colorScheme.primary,
                      )
                    : null,
                onTap: () {
                  ref.read(settingsProvider.notifier).setFont(font);
                  Navigator.pop(sheetContext);
                },
              ),
          ],
        ),
      ),
    );
  }

  static TextStyle? _fontPreview(String? family, TextStyle? base) {
    if (family == null) {
      // The ambient theme already uses the chosen Google font; reset to
      // the platform's own family for an honest preview.
      return base?.copyWith(
        fontFamily: Typography.material2021(platform: defaultTargetPlatform)
            .black
            .bodyMedium
            ?.fontFamily,
      );
    }
    return GoogleFonts.getFont(family, textStyle: base);
  }

  Future<void> _pickRegion(BuildContext context, WidgetRef ref) {
    final current = ref.read(settingsProvider).countryCode;
    return showModalBottomSheet<void>(
      context: context,
      useRootNavigator: true,
      showDragHandle: true,
      isScrollControlled: true,
      builder: (sheetContext) => DraggableScrollableSheet(
        expand: false,
        initialChildSize: 0.6,
        maxChildSize: 0.9,
        builder: (_, scrollController) => ListView(
          controller: scrollController,
          children: [
            for (final (code, name) in kRegions)
              ListTile(
                leading: Text(
                  flagEmoji(code),
                  style: const TextStyle(fontSize: 24),
                ),
                title: Text(name),
                trailing: code == current
                    ? Icon(
                        Icons.check_rounded,
                        color: Theme.of(sheetContext).colorScheme.primary,
                      )
                    : null,
                onTap: () {
                  ref.read(settingsProvider.notifier).setCountry(code);
                  Navigator.pop(sheetContext);
                },
              ),
          ],
        ),
      ),
    );
  }
}

class _SectionLabel extends StatelessWidget {
  const _SectionLabel(this.text);

  final String text;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return Padding(
      padding: const EdgeInsets.fromLTRB(16, 24, 16, 8),
      child: Text(
        text.toUpperCase(),
        style: theme.textTheme.labelMedium?.copyWith(
          color: theme.colorScheme.primary,
          fontWeight: FontWeight.w700,
          letterSpacing: 1.1,
        ),
      ),
    );
  }
}
