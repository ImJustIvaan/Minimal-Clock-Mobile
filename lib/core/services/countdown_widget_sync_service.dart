import 'dart:convert';
import 'package:home_widget/home_widget.dart';
import '../models/countdown_model.dart';

/// Pushes the signed-in user's countdowns to the shared App Group storage
/// so the iOS home screen widget (which runs in a separate process and has
/// no access to Dart/Supabase) can read them and let the user pick one to
/// display. Android reads the same JSON blob from its own widget provider.
class CountdownWidgetSyncService {
  CountdownWidgetSyncService._();
  static final instance = CountdownWidgetSyncService._();

  static const _appGroupId = 'group.com.ImJustIvaan.MimClock';
  static const _dataKey = 'countdowns_json';
  static const _iOSWidgetKind = 'MinimalClockCountdownWidget';

  bool _initialized = false;

  Future<void> _ensureInitialized() async {
    if (_initialized) return;
    await HomeWidget.setAppGroupId(_appGroupId);
    _initialized = true;
  }

  Future<void> syncCountdowns(List<Countdown> countdowns) async {
    try {
      await _ensureInitialized();
      final payload = countdowns
          .map((c) => {
                'id': c.id,
                'title': c.title,
                'targetDate': c.targetDate.toIso8601String(),
              })
          .toList();
      await HomeWidget.saveWidgetData<String>(_dataKey, jsonEncode(payload));
      await HomeWidget.updateWidget(
        iOSName: _iOSWidgetKind,
        androidName: 'MinimalClockWidgetProvider',
      );
    } catch (_) {
      // Widgets are a nice-to-have; never let a sync failure affect the
      // main app (e.g. running on a platform/OS version without widgets).
    }
  }
}
