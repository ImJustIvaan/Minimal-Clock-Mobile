import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';

class AppTheme {
  static const _fontFamily = 'RobotoMono';

  static ThemeData light() => ThemeData(
        brightness: Brightness.light,
        colorScheme: const ColorScheme.light(
          primary: Colors.black,
          surface: Color(0xFFF8F8F8),
          onSurface: Colors.black,
        ),
        scaffoldBackgroundColor: const Color(0xFFF8F8F8),
        fontFamily: _fontFamily,
        useMaterial3: true,
        navigationBarTheme: const NavigationBarThemeData(
          backgroundColor: Color(0xFFF8F8F8),
          indicatorColor: Colors.black12,
        ),
        pageTransitionsTheme: const PageTransitionsTheme(
          builders: {
            TargetPlatform.android: FadeUpwardsPageTransitionsBuilder(),
            TargetPlatform.iOS: CupertinoPageTransitionsBuilder(),
          },
        ),
      );

  static ThemeData dark() => ThemeData(
        brightness: Brightness.dark,
        colorScheme: const ColorScheme.dark(
          primary: Colors.white,
          surface: Color(0xFF0A0A0A),
          onSurface: Colors.white,
        ),
        scaffoldBackgroundColor: const Color(0xFF0A0A0A),
        fontFamily: _fontFamily,
        useMaterial3: true,
        navigationBarTheme: const NavigationBarThemeData(
          backgroundColor: Color(0xFF111111),
          indicatorColor: Colors.white12,
        ),
        pageTransitionsTheme: const PageTransitionsTheme(
          builders: {
            TargetPlatform.android: FadeUpwardsPageTransitionsBuilder(),
            TargetPlatform.iOS: CupertinoPageTransitionsBuilder(),
          },
        ),
      );
}
