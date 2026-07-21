import 'dart:io';
import 'package:flutter/services.dart';

/// Detects whether the app is currently running on an Android TV device
/// (as opposed to a phone/tablet), so the UI can favor a QR sign-in flow
/// and remote-friendly navigation instead of a keyboard-heavy form.
class TvPlatformService {
  TvPlatformService._();

  static const _channel = MethodChannel('com.imjustivaan.mimclock/tv');
  static bool? _cached;

  static Future<bool> isAndroidTv() async {
    if (!Platform.isAndroid) return false;
    final cached = _cached;
    if (cached != null) return cached;
    try {
      final result = await _channel.invokeMethod<bool>('isTv');
      _cached = result ?? false;
    } catch (_) {
      _cached = false;
    }
    return _cached!;
  }
}
