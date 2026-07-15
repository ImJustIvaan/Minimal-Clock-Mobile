import 'dart:async';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:intl/intl.dart';
import 'package:timezone/timezone.dart' as tz;
import 'package:wakelock_plus/wakelock_plus.dart';
import '../../core/providers/settings_provider.dart';
import 'widgets/animated_digit.dart';

class ClockScreen extends ConsumerStatefulWidget {
  const ClockScreen({super.key});

  @override
  ConsumerState<ClockScreen> createState() => _ClockScreenState();
}

class _ClockScreenState extends ConsumerState<ClockScreen> {
  late Timer _timer;
  DateTime _now = DateTime.now();

  @override
  void initState() {
    super.initState();
    _timer = Timer.periodic(const Duration(seconds: 1), (_) {
      if (mounted) setState(() => _now = DateTime.now());
    });
  }

  @override
  void dispose() {
    _timer.cancel();
    super.dispose();
  }

  // timezone data is already initialized by NotificationService.init() at
  // app startup, so tz.getLocation() is safe to call here.
  DateTime _localizedNow(String tzId) {
    if (tzId.isEmpty) return _now;
    try {
      final tzNow = tz.TZDateTime.now(tz.getLocation(tzId));
      return DateTime(tzNow.year, tzNow.month, tzNow.day, tzNow.hour, tzNow.minute, tzNow.second);
    } catch (_) {
      return _now;
    }
  }

  @override
  Widget build(BuildContext context) {
    final settingsAsync = ref.watch(settingsProvider);
    return settingsAsync.when(
      loading: () => const SizedBox.shrink(),
      error: (_, __) => const SizedBox.shrink(),
      data: (settings) {
        // Wakelock
        if (settings.keepScreenAwake) {
          WakelockPlus.enable();
        } else {
          WakelockPlus.disable();
        }

        final displayNow = _localizedNow(settings.selectedTimezone);
        final timeFormat = settings.use24Hour
            ? (settings.showSeconds ? 'HH:mm:ss' : 'HH:mm')
            : (settings.showSeconds ? 'hh:mm:ss' : 'hh:mm');
        final timeStr = DateFormat(timeFormat).format(displayNow);
        final amPm = settings.use24Hour
            ? ''
            : DateFormat('a').format(displayNow);
        final dateStr = DateFormat('MMMM d, yyyy').format(displayNow);
        final weekdayStr = DateFormat('EEEE').format(displayNow);

        final color = Theme.of(context).colorScheme.onSurface;
        final screenWidth = MediaQuery.of(context).size.width;
        final isTablet = screenWidth >= 600;
        final fontSize = isTablet
            ? settings.clockFontSize * 1.6
            : settings.clockFontSize;

        // Custom digit display, not scrollable text — ignore the system's
        // accessibility text size so it can't blow out the fixed layout.
        return MediaQuery(
          data: MediaQuery.of(context).copyWith(textScaler: TextScaler.linear(1.0)),
          child: Scaffold(
          body: SafeArea(
            child: Center(
              child: Padding(
                padding: const EdgeInsets.symmetric(horizontal: 24),
                child: Column(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    if (settings.selectedTimezone.isNotEmpty) ...[
                      Text(
                        settings.selectedTimezone.replaceAll('_', ' '),
                        style: TextStyle(
                          fontSize: 11,
                          letterSpacing: 3,
                          color: color.withOpacity(0.3),
                        ),
                      ),
                      const SizedBox(height: 4),
                    ],
                    if (settings.showWeekday) ...[
                      Text(
                        weekdayStr.toUpperCase(),
                        style: TextStyle(
                          fontSize: 13,
                          letterSpacing: 4,
                          color: color.withOpacity(0.4),
                          fontWeight: FontWeight.w400,
                        ),
                      ),
                      const SizedBox(height: 8),
                    ],
                    // Clock digits with animated transitions
                    Row(
                      mainAxisAlignment: MainAxisAlignment.center,
                      crossAxisAlignment: CrossAxisAlignment.end,
                      children: [
                        AnimatedClockText(
                          text: timeStr,
                          fontSize: fontSize,
                          color: color,
                        ),
                        if (!settings.use24Hour && amPm.isNotEmpty) ...[
                          const SizedBox(width: 6),
                          Padding(
                            padding: EdgeInsets.only(bottom: fontSize * 0.08),
                            child: Text(
                              amPm,
                              style: TextStyle(
                                fontSize: fontSize * 0.22,
                                color: color.withOpacity(0.5),
                                fontWeight: FontWeight.w300,
                                letterSpacing: 1,
                              ),
                            ),
                          ),
                        ],
                      ],
                    ),
                    if (settings.showDate) ...[
                      const SizedBox(height: 16),
                      Text(
                        dateStr,
                        style: TextStyle(
                          fontSize: 16,
                          letterSpacing: 1,
                          color: color.withOpacity(0.45),
                          fontWeight: FontWeight.w300,
                        ),
                      ),
                    ],
                  ],
                ),
              ),
            ),
          ),
          ),
        );
      },
    );
  }
}
