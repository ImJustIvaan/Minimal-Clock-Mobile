import 'package:watch_connectivity/watch_connectivity.dart';
import 'supabase_service.dart';

/// Pushes the signed-in user's session token and a couple of display
/// settings to the paired Apple Watch app via WatchConnectivity, so it can
/// show the same timezone/time format and fetch the user's own countdowns
/// directly from Supabase without needing the phone nearby.
class WatchSyncService {
  WatchSyncService._();
  static final instance = WatchSyncService._();

  final _watch = WatchConnectivity();

  Future<void> syncNow({bool? use24Hour, String? selectedTimezone}) async {
    try {
      if (!(await _watch.isSupported)) return;
      final session = SupabaseService.client.auth.currentSession;
      await _watch.updateApplicationContext({
        if (session != null) 'accessToken': session.accessToken,
        if (use24Hour != null) 'use24Hour': use24Hour,
        if (selectedTimezone != null) 'selectedTimezone': selectedTimezone,
      });
    } catch (_) {
      // Not on a watch-capable platform, no watch paired, etc. — non-fatal.
    }
  }
}
