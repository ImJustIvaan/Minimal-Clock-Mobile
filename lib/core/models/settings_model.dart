import 'package:flutter/material.dart';

class AppSettings {
  final ThemeMode themeMode;
  final bool use24Hour;
  final bool showSeconds;
  final bool showDate;
  final bool showWeekday;
  final double clockFontSize;
  final bool keepScreenAwake;
  final bool hourlyNotifier;

  const AppSettings({
    this.themeMode = ThemeMode.system,
    this.use24Hour = false,
    this.showSeconds = true,
    this.showDate = true,
    this.showWeekday = true,
    this.clockFontSize = 72,
    this.keepScreenAwake = false,
    this.hourlyNotifier = false,
  });

  AppSettings copyWith({
    ThemeMode? themeMode,
    bool? use24Hour,
    bool? showSeconds,
    bool? showDate,
    bool? showWeekday,
    double? clockFontSize,
    bool? keepScreenAwake,
    bool? hourlyNotifier,
  }) {
    return AppSettings(
      themeMode: themeMode ?? this.themeMode,
      use24Hour: use24Hour ?? this.use24Hour,
      showSeconds: showSeconds ?? this.showSeconds,
      showDate: showDate ?? this.showDate,
      showWeekday: showWeekday ?? this.showWeekday,
      clockFontSize: clockFontSize ?? this.clockFontSize,
      keepScreenAwake: keepScreenAwake ?? this.keepScreenAwake,
      hourlyNotifier: hourlyNotifier ?? this.hourlyNotifier,
    );
  }

  Map<String, dynamic> toJson() => {
        'themeMode': themeMode.index,
        'use24Hour': use24Hour,
        'showSeconds': showSeconds,
        'showDate': showDate,
        'showWeekday': showWeekday,
        'clockFontSize': clockFontSize,
        'keepScreenAwake': keepScreenAwake,
        'hourlyNotifier': hourlyNotifier,
      };

  factory AppSettings.fromJson(Map<String, dynamic> json) => AppSettings(
        themeMode: ThemeMode.values[json['themeMode'] as int? ?? 0],
        use24Hour: json['use24Hour'] as bool? ?? false,
        showSeconds: json['showSeconds'] as bool? ?? true,
        showDate: json['showDate'] as bool? ?? true,
        showWeekday: json['showWeekday'] as bool? ?? true,
        clockFontSize: (json['clockFontSize'] as num?)?.toDouble() ?? 72,
        keepScreenAwake: json['keepScreenAwake'] as bool? ?? false,
        hourlyNotifier: json['hourlyNotifier'] as bool? ?? false,
      );
}
