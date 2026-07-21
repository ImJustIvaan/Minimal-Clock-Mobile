import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../core/providers/ui_visibility_provider.dart';
import '../../features/clock/clock_screen.dart';
import '../../features/countdowns/countdowns_screen.dart';
import '../../features/timer/timer_screen.dart';
import '../../features/settings/settings_screen.dart';

class AppShell extends ConsumerStatefulWidget {
  const AppShell({super.key});

  @override
  ConsumerState<AppShell> createState() => _AppShellState();
}

class _AppShellState extends ConsumerState<AppShell> {
  int _index = 0;

  static const _screens = [
    ClockScreen(),
    TimerScreen(),
    CountdownsScreen(),
    SettingsScreen(),
  ];

  @override
  Widget build(BuildContext context) {
    final color = Theme.of(context).colorScheme.onSurface;
    final uiHidden = ref.watch(uiHiddenProvider);
    return Scaffold(
      body: AnimatedSwitcher(
        duration: const Duration(milliseconds: 200),
        child: KeyedSubtree(
          key: ValueKey(_index),
          child: _screens[_index],
        ),
      ),
      bottomNavigationBar: uiHidden
          ? null
          : NavigationBar(
              selectedIndex: _index,
              onDestinationSelected: (i) => setState(() => _index = i),
              labelBehavior: NavigationDestinationLabelBehavior.alwaysShow,
              height: 64,
              destinations: [
                NavigationDestination(
                  icon: Icon(Icons.access_time_outlined, color: color.withOpacity(0.4)),
                  selectedIcon: Icon(Icons.access_time_filled, color: color),
                  label: 'Clock',
                ),
                NavigationDestination(
                  icon: Icon(Icons.timer_outlined, color: color.withOpacity(0.4)),
                  selectedIcon: Icon(Icons.timer, color: color),
                  label: 'Timer',
                ),
                NavigationDestination(
                  icon: Icon(Icons.event_outlined, color: color.withOpacity(0.4)),
                  selectedIcon: Icon(Icons.event, color: color),
                  label: 'Countdowns',
                ),
                NavigationDestination(
                  icon: Icon(Icons.tune_outlined, color: color.withOpacity(0.4)),
                  selectedIcon: Icon(Icons.tune, color: color),
                  label: 'Settings',
                ),
              ],
            ),
    );
  }
}
