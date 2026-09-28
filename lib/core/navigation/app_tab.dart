import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

enum AppTab {
  home('Home', Icons.home_outlined, Icons.home_rounded),
  radio('Radio', Icons.radio_outlined, Icons.radio),
  podcasts('Podcasts', Icons.podcasts_outlined, Icons.podcasts),
  settings('Settings', Icons.settings_outlined, Icons.settings);

  const AppTab(this.label, this.icon, this.activeIcon);

  final String label;
  final IconData icon;
  final IconData activeIcon;
}

/// Current bottom-nav tab. A provider (not widget state) so screens can
/// switch tabs, e.g. Home's "See all" buttons.
final selectedTabProvider = NotifierProvider<SelectedTab, AppTab>(
  SelectedTab.new,
);

class SelectedTab extends Notifier<AppTab> {
  @override
  AppTab build() => AppTab.home;

  void select(AppTab tab) => state = tab;
}
