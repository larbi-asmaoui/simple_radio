import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../core/navigation/app_tab.dart';
import '../features/home/presentation/home_screen.dart';
import '../features/player/widgets/persistent_player.dart';
import '../features/podcast/presentation/podcast_screen.dart';
import '../features/radio/presentation/radio_screen.dart';
import '../features/settings/presentation/settings_screen.dart';

/// App shell: bottom navigation, one nested [Navigator] per tab, and the
/// persistent player docked above the navigation bar.
///
/// Every tab stays mounted, so scroll positions and pushed screens (e.g. an
/// open episode list) survive switching tabs. Tabs cross-fade on switch.
class MainScreen extends ConsumerStatefulWidget {
  const MainScreen({super.key});

  @override
  ConsumerState<MainScreen> createState() => _MainScreenState();
}

class _MainScreenState extends ConsumerState<MainScreen> {
  static Widget _rootOf(AppTab tab) => switch (tab) {
    AppTab.home => const HomeScreen(),
    AppTab.radio => const RadioScreen(),
    AppTab.podcasts => const PodcastScreen(),
    AppTab.settings => const SettingsScreen(),
  };

  final _navigatorKeys = {
    for (final tab in AppTab.values) tab: GlobalKey<NavigatorState>(),
  };

  // Nested navigators need their own HeroController for Hero animations.
  final _heroControllers = {
    for (final tab in AppTab.values)
      tab: MaterialApp.createMaterialHeroController(),
  };

  void _onTabTapped(AppTab tab) {
    if (tab == ref.read(selectedTabProvider)) {
      // Re-tapping the active tab returns it to its root screen.
      _navigatorKeys[tab]!.currentState?.popUntil((route) => route.isFirst);
      return;
    }
    ref.read(selectedTabProvider.notifier).select(tab);
  }

  /// Android back: pop inside the current tab, then go Home, then exit.
  void _onBack(bool didPop, Object? _) {
    if (didPop) return;
    final current = ref.read(selectedTabProvider);
    final navigator = _navigatorKeys[current]!.currentState;
    if (navigator != null && navigator.canPop()) {
      navigator.pop();
    } else if (current != AppTab.home) {
      ref.read(selectedTabProvider.notifier).select(AppTab.home);
    } else {
      SystemNavigator.pop();
    }
  }

  @override
  void dispose() {
    for (final controller in _heroControllers.values) {
      controller.dispose();
    }
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final selected = ref.watch(selectedTabProvider);

    return PopScope(
      canPop: false,
      onPopInvokedWithResult: _onBack,
      child: Scaffold(
        body: Stack(
          children: [
            for (final tab in AppTab.values) _buildTab(tab, tab == selected),
            // Body ends at the top of the nav bar, so bottom: 0 docks the
            // player right above it.
            const Positioned(
              left: 0,
              right: 0,
              bottom: 0,
              child: PersistentPlayer(),
            ),
          ],
        ),
        bottomNavigationBar: BottomNavigationBar(
          currentIndex: selected.index,
          onTap: (i) => _onTabTapped(AppTab.values[i]),
          items: [
            for (final tab in AppTab.values)
              BottomNavigationBarItem(
                icon: Icon(tab.icon),
                activeIcon: Icon(tab.activeIcon),
                label: tab.label,
              ),
          ],
        ),
      ),
    );
  }

  Widget _buildTab(AppTab tab, bool active) {
    // Inactive tabs stay in the tree (state preserved) but are invisible,
    // non-interactive, hidden from accessibility, and have tickers paused.
    return Positioned.fill(
      child: AnimatedOpacity(
        opacity: active ? 1 : 0,
        duration: const Duration(milliseconds: 220),
        curve: Curves.easeOut,
        child: IgnorePointer(
          ignoring: !active,
          child: ExcludeSemantics(
            excluding: !active,
            child: TickerMode(
              enabled: active,
              child: HeroControllerScope(
                controller: _heroControllers[tab]!,
                child: Navigator(
                  key: _navigatorKeys[tab],
                  onGenerateRoute: (settings) => MaterialPageRoute<void>(
                    settings: settings,
                    builder: (_) => _rootOf(tab),
                  ),
                ),
              ),
            ),
          ),
        ),
      ),
    );
  }
}
