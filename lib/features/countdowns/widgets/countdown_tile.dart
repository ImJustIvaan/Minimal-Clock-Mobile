import 'dart:async';
import 'package:flutter/material.dart';
import '../../../core/models/countdown_model.dart';

String formatRemaining(Duration d) {
  if (d.isNegative) return 'Ended';
  final days = d.inDays;
  final hours = d.inHours % 24;
  final minutes = d.inMinutes % 60;
  final seconds = d.inSeconds % 60;
  if (days > 0) return '${days}d ${hours}h ${minutes}m';
  if (hours > 0) return '${hours}h ${minutes}m ${seconds}s';
  if (minutes > 0) return '${minutes}m ${seconds}s';
  return '${seconds}s';
}

class CountdownTile extends StatefulWidget {
  final Countdown countdown;
  final bool notify;
  final VoidCallback onTap;

  const CountdownTile({
    super.key,
    required this.countdown,
    required this.notify,
    required this.onTap,
  });

  @override
  State<CountdownTile> createState() => _CountdownTileState();
}

class _CountdownTileState extends State<CountdownTile> {
  late Timer _timer;

  @override
  void initState() {
    super.initState();
    _timer = Timer.periodic(const Duration(seconds: 1), (_) {
      if (mounted) setState(() {});
    });
  }

  @override
  void dispose() {
    _timer.cancel();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final color = Theme.of(context).colorScheme.onSurface;
    final remaining = widget.countdown.targetDate.difference(DateTime.now());
    return InkWell(
      onTap: widget.onTap,
      child: Padding(
        padding: const EdgeInsets.symmetric(vertical: 14),
        child: Row(
          children: [
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    widget.countdown.title,
                    style: TextStyle(
                      fontSize: 16,
                      fontWeight: FontWeight.w400,
                      color: color,
                    ),
                  ),
                  const SizedBox(height: 4),
                  Text(
                    formatRemaining(remaining),
                    style: TextStyle(
                      fontSize: 13,
                      color: color.withOpacity(0.45),
                      fontWeight: FontWeight.w300,
                    ),
                  ),
                ],
              ),
            ),
            if (widget.notify)
              Icon(Icons.notifications_active_outlined,
                  size: 18, color: color.withOpacity(0.4)),
            const SizedBox(width: 8),
            Icon(Icons.chevron_right, color: color.withOpacity(0.25)),
          ],
        ),
      ),
    );
  }
}
