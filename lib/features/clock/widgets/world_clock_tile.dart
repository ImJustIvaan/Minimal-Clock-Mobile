import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import 'package:timezone/timezone.dart' as tz;

/// Small box showing the live time in another timezone, matching the
/// website's world clock widgets. Tap-and-hold to remove.
class WorldClockTile extends StatelessWidget {
  final String tzId;
  final bool use24Hour;
  final VoidCallback onRemove;

  const WorldClockTile({
    super.key,
    required this.tzId,
    required this.use24Hour,
    required this.onRemove,
  });

  String get _label => tzId.split('/').last.replaceAll('_', ' ');

  @override
  Widget build(BuildContext context) {
    final color = Theme.of(context).colorScheme.onSurface;
    DateTime now;
    try {
      now = tz.TZDateTime.now(tz.getLocation(tzId));
    } catch (_) {
      now = DateTime.now();
    }
    final timeStr = DateFormat(use24Hour ? 'HH:mm' : 'h:mm a').format(now);
    final localDay = DateTime.now().day;
    final dayDiff = now.day == localDay ? null : now.day;

    return GestureDetector(
      onLongPress: onRemove,
      child: Container(
        constraints: const BoxConstraints(minWidth: 92),
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 10),
        decoration: BoxDecoration(
          color: color.withOpacity(0.06),
          borderRadius: BorderRadius.circular(14),
        ),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Text(
              _label.toUpperCase(),
              style: TextStyle(
                fontSize: 11,
                letterSpacing: 1.5,
                color: color.withOpacity(0.5),
              ),
              maxLines: 1,
              overflow: TextOverflow.ellipsis,
            ),
            const SizedBox(height: 2),
            Text(
              timeStr,
              style: TextStyle(
                fontSize: 18,
                fontWeight: FontWeight.w600,
                color: color,
              ),
            ),
            if (dayDiff != null)
              Text(
                'Day $dayDiff',
                style: TextStyle(fontSize: 10, color: color.withOpacity(0.4)),
              ),
          ],
        ),
      ),
    );
  }
}
