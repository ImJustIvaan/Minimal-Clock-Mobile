import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'core/providers/settings_provider.dart';
import 'core/services/notification_service.dart';
import 'core/services/supabase_service.dart';
import 'core/theme/app_theme.dart';
import 'shared/widgets/app_shell.dart';

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

  runApp(const ProviderScope(child: MinimumClockApp()));
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
