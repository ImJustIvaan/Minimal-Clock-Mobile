import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'core/providers/settings_provider.dart';
import 'core/services/countdown_repository.dart';
import 'core/services/countdown_widget_sync_service.dart';
import 'core/services/deep_link_service.dart';
import 'core/services/notification_service.dart';
import 'core/services/purchase_service.dart';
import 'core/services/supabase_service.dart';
import 'core/services/watch_sync_service.dart';
import 'core/theme/app_theme.dart';
import 'shared/widgets/app_shell.dart';

final navigatorKey = GlobalKey<NavigatorState>();

void main() async {
  WidgetsFlutterBinding.ensureInitialized();

  SystemChrome.setPreferredOrientations([
    DeviceOrientation.portraitUp,
    DeviceOrientation.portraitDown,
    DeviceOrientation.landscapeLeft,
    DeviceOrientation.landscapeRight,
  ]);

  await SupabaseService.init();
  await NotificationService.instance.init();
  PurchaseService.instance.init();

  runApp(const ProviderScope(child: MinimumClockApp()));

  DeepLinkService.instance.init(navigatorKey);

  // Push countdowns to the widget's shared storage independent of whether
  // the Countdowns screen is ever opened — the widget's config picker
  // otherwise only ever sees data if that screen happened to have been
  // visited since the countdowns last changed (autoDispose Riverpod
  // provider that only syncs as a side effect of being watched there).
  Future<void> syncCountdownsToWidget() async {
    try {
      final followed = await CountdownRepository.instance.fetchMyCountdowns();
      await CountdownWidgetSyncService.instance
          .syncCountdowns(followed.map((f) => f.countdown).toList());
    } catch (_) {
      // Not signed in, offline, etc. — non-fatal, the Countdowns screen
      // will still sync normally once it's visited.
    }
  }

  syncCountdownsToWidget();

  // Re-push the session token to the watch, and the countdowns to the
  // widget, whenever sign-in state changes.
  SupabaseService.client.auth.onAuthStateChange.listen((_) {
    WatchSyncService.instance.syncNow();
    syncCountdownsToWidget();
  });
}

class MinimumClockApp extends ConsumerWidget {
  const MinimumClockApp({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final settingsAsync = ref.watch(settingsProvider);
    final themeMode = settingsAsync.valueOrNull?.themeMode ?? ThemeMode.system;

    return AnimatedTheme(
      data: themeMode == ThemeMode.dark
          ? AppTheme.dark()
          : themeMode == ThemeMode.light
              ? AppTheme.light()
              : MediaQuery.of(context).platformBrightness == Brightness.dark
                  ? AppTheme.dark()
                  : AppTheme.light(),
      duration: const Duration(milliseconds: 300),
      child: MaterialApp(
        navigatorKey: navigatorKey,
        title: 'Minimal Clock',
        debugShowCheckedModeBanner: false,
        theme: AppTheme.light(),
        darkTheme: AppTheme.dark(),
        themeMode: themeMode,
        // The clock/timer/countdown displays are custom-sized digit layouts,
        // not scrollable text — at large iOS/Android accessibility text
        // sizes they'd otherwise overflow their fixed-size cells and clip.
        builder: (context, child) => MediaQuery.withClampedTextScaling(
          minScaleFactor: 1.0,
          maxScaleFactor: 1.3,
          child: child!,
        ),
        home: const AppShell(),
      ),
    );
  }
}
