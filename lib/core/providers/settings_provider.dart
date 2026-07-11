import 'dart:convert';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:shared_preferences/shared_preferences.dart';
import '../models/settings_model.dart';
import '../services/notification_service.dart';

const _kSettingsKey = 'app_settings';

class SettingsNotifier extends AsyncNotifier<AppSettings> {
  @override
  Future<AppSettings> build() async {
    final prefs = await SharedPreferences.getInstance();
    final raw = prefs.getString(_kSettingsKey);
    AppSettings settings;
    try {
      settings = raw == null
          ? const AppSettings()
          : AppSettings.fromJson(jsonDecode(raw) as Map<String, dynamic>);
    } catch (_) {
      settings = const AppSettings();
    }
    NotificationService.instance.setHourlyNotifierEnabled(settings.hourlyNotifier);
    return settings;
  }

  Future<void> save(AppSettings settings) async {
    state = AsyncData(settings);
    NotificationService.instance.setHourlyNotifierEnabled(settings.hourlyNotifier);
    final prefs = await SharedPreferences.getInstance();
    await prefs.setString(_kSettingsKey, jsonEncode(settings.toJson()));
  }
}

final settingsProvider =
    AsyncNotifierProvider<SettingsNotifier, AppSettings>(SettingsNotifier.new);
