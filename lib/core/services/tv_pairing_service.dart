import 'dart:async';
import 'dart:math';
import 'package:supabase_flutter/supabase_flutter.dart';
import 'supabase_service.dart';

/// Lets an Android TV sign in by showing a QR code / short code instead of
/// typing an email and password with a remote. The phone (already signed
/// in on the website) scans the code, confirms, and the website writes the
/// session tokens into the `tv_pairing_codes` row this class is polling.
/// Mirrors the Apple TV app's PairingManager against the same table.
class TvPairingService {
  Timer? _pollTimer;
  String? _code;

  static const _chars = 'ABCDEFGHJKLMNPQRSTUVWXYZ23456789'; // no 0/O/1/I
  static final _random = Random.secure();

  static String _generateCode() =>
      List.generate(6, (_) => _chars[_random.nextInt(_chars.length)]).join();

  /// Starts a new pairing session: creates the code row and begins polling.
  /// [onSignedIn] fires once the phone has claimed the code and the app has
  /// signed in with the resulting session. [onError] fires on failure.
  Future<String> start({
    required void Function() onSignedIn,
    required void Function(String message) onError,
  }) async {
    stop();
    final code = _generateCode();
    _code = code;
    final client = SupabaseService.client;

    try {
      await client.from('tv_pairing_codes').insert({'code': code});
    } catch (_) {
      onError("Couldn't start pairing. Check your connection.");
      return code;
    }

    _pollTimer = Timer.periodic(const Duration(seconds: 2), (_) async {
      try {
        final row = await client
            .from('tv_pairing_codes')
            .select()
            .eq('code', code)
            .maybeSingle();
        final accessToken = row?['access_token'] as String?;
        final refreshToken = row?['refresh_token'] as String?;
        if (accessToken != null && refreshToken != null) {
          stop();
          await client.auth.setSession(refreshToken);
          await client.from('tv_pairing_codes').delete().eq('code', code);
          onSignedIn();
        }
      } catch (_) {
        // Transient network errors are fine to ignore mid-poll.
      }
    });

    return code;
  }

  String get pairingUrl =>
      _code == null ? '' : 'https://time.ivaan.cc/?pair=$_code';

  void stop() {
    _pollTimer?.cancel();
    _pollTimer = null;
  }
}
