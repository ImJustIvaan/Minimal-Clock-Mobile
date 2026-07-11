import 'dart:io';
import 'package:flutter_local_notifications/flutter_local_notifications.dart';
import 'package:flutter_timezone/flutter_timezone.dart';
import 'package:permission_handler/permission_handler.dart';
import 'package:timezone/data/latest_all.dart' as tz_data;
import 'package:timezone/timezone.dart' as tz;

class NotificationService {
  NotificationService._();
  static final instance = NotificationService._();

  final _plugin = FlutterLocalNotificationsPlugin();

  Future<void> init() async {
    tz_data.initializeTimeZones();
    try {
      final name = await FlutterTimezone.getLocalTimezone();
      tz.setLocalLocation(tz.getLocation(name));
    } catch (_) {
      // Falls back to UTC if the device timezone can't be resolved.
    }

    const android = AndroidInitializationSettings('@mipmap/ic_launcher');
    const ios = DarwinInitializationSettings(
      requestAlertPermission: true,
      requestBadgePermission: true,
      requestSoundPermission: true,
    );
    await _plugin.initialize(
      const InitializationSettings(android: android, iOS: ios),
    );
    await _requestPermissions();
  }

  Future<void> _requestPermissions() async {
    if (Platform.isAndroid) {
      await Permission.notification.request();
      await _plugin
          .resolvePlatformSpecificImplementation<
              AndroidFlutterLocalNotificationsPlugin>()
          ?.requestExactAlarmsPermission();
    } else if (Platform.isIOS) {
      await _plugin
          .resolvePlatformSpecificImplementation<
              IOSFlutterLocalNotificationsPlugin>()
          ?.requestPermissions(
            alert: true,
            badge: true,
            sound: true,
          );
    }
  }

  static const _timerNotificationId = 0;

  Future<void> showTimerFinished() async {
    const androidDetails = AndroidNotificationDetails(
      'timer_channel',
      'Timer',
      channelDescription: 'Timer finished notifications',
      importance: Importance.max,
      priority: Priority.high,
      playSound: true,
      enableVibration: true,
      fullScreenIntent: true,
    );
    const iosDetails = DarwinNotificationDetails(
      presentAlert: true,
      presentBadge: true,
      presentSound: true,
    );
    await _plugin.show(
      _timerNotificationId,
      'Minimal Clock',
      'Timer Finished',
      const NotificationDetails(android: androidDetails, iOS: iosDetails),
    );
  }

  /// Pre-schedules the timer-finished alert with the OS, so it still fires
  /// if the app gets backgrounded/suspended before the countdown reaches
  /// zero (a plain in-app Timer stops advancing once iOS suspends the app).
  Future<void> scheduleTimerNotification(Duration remaining) async {
    await cancelTimerNotification();
    if (remaining <= Duration.zero) return;
    final scheduled = tz.TZDateTime.now(tz.local).add(remaining);

    const androidDetails = AndroidNotificationDetails(
      'timer_channel',
      'Timer',
      channelDescription: 'Timer finished notifications',
      importance: Importance.max,
      priority: Priority.high,
      playSound: true,
      enableVibration: true,
      fullScreenIntent: true,
    );
    const iosDetails = DarwinNotificationDetails(
      presentAlert: true,
      presentBadge: true,
      presentSound: true,
    );

    await _plugin.zonedSchedule(
      _timerNotificationId,
      'Minimal Clock',
      'Timer Finished',
      scheduled,
      const NotificationDetails(android: androidDetails, iOS: iosDetails),
      androidScheduleMode: AndroidScheduleMode.exactAllowWhileIdle,
      uiLocalNotificationDateInterpretation:
          UILocalNotificationDateInterpretation.absoluteTime,
    );
  }

  Future<void> cancelTimerNotification() async {
    await _plugin.cancel(_timerNotificationId);
  }

  /// Deterministic int id for a countdown's notification, stable across
  /// app restarts/platforms (Dart's String.hashCode is not guaranteed to be).
  int _countdownNotificationId(String countdownId) {
    var hash = 0x811c9dc5;
    for (final unit in countdownId.codeUnits) {
      hash ^= unit;
      hash = (hash * 0x01000193) & 0x7fffffff;
    }
    return hash;
  }

  Future<void> scheduleCountdownNotification({
    required String countdownId,
    required String title,
    required DateTime targetDate,
  }) async {
    final id = _countdownNotificationId(countdownId);
    if (targetDate.isBefore(DateTime.now())) return;
    final scheduled = tz.TZDateTime.from(targetDate, tz.local);

    const androidDetails = AndroidNotificationDetails(
      'countdown_channel',
      'Countdowns',
      channelDescription: 'Notifies you when a countdown ends',
      importance: Importance.max,
      priority: Priority.high,
      playSound: true,
      enableVibration: true,
      fullScreenIntent: true,
    );
    const iosDetails = DarwinNotificationDetails(
      presentAlert: true,
      presentBadge: true,
      presentSound: true,
    );

    await _plugin.zonedSchedule(
      id,
      title,
      "It's time!",
      scheduled,
      const NotificationDetails(android: androidDetails, iOS: iosDetails),
      androidScheduleMode: AndroidScheduleMode.exactAllowWhileIdle,
      uiLocalNotificationDateInterpretation:
          UILocalNotificationDateInterpretation.absoluteTime,
    );
  }

  Future<void> cancelCountdownNotification(String countdownId) async {
    await _plugin.cancel(_countdownNotificationId(countdownId));
  }
}
