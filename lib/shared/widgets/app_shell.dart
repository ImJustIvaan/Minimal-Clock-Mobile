import 'dart:io';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../core/providers/ui_visibility_provider.dart';
import '../../features/clock/clock_screen.dart';
import '../../features/countdowns/countdowns_screen.dart';
import '../../features/timer/timer_screen.dart';
import '../../features/settings/settings_screen.dart';
import 'liquid_glass.dart';

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
    final navBar = uiHidden
        ? null
        : NavigationBar(
            selectedIndex: _index,
            onDestinationSelected: (i) => setState(() => _index = i),
            labelBehavior: NavigationDestinationLabelBehavior.alwaysShow,
            height: 64,
            backgroundColor: Platform.isIOS ? Colors.transparent : null,
            elevation: Platform.isIOS ? 0 : null,
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
          );

    return Scaffold(
      extendBody: Platform.isIOS,
      body: AnimatedSwitcher(
        duration: const Duration(milliseconds: 200),
        child: KeyedSubtree(
          key: ValueKey(_index),
          child: _screens[_index],
        ),
      ),
      // On iOS the bottom bar floats as a Liquid Glass pill, matching the
      // system look introduced in iOS 26. Other platforms keep the plain
      // anchored Material nav bar.
      bottomNavigationBar: navBar == null
          ? null
          : Platform.isIOS
              ? SafeArea(
                  minimum: const EdgeInsets.fromLTRB(16, 0, 16, 12),
                  child: LiquidGlass(
                    borderRadius: BorderRadius.circular(32),
                    child: navBar,
                  ),
                )
              : navBar,
    );
  }
}
