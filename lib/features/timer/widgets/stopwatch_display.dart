import 'package:flutter/material.dart';

class StopwatchDisplay extends StatelessWidget {
  final Duration elapsed;
  final Color color;

  const StopwatchDisplay({super.key, required this.elapsed, required this.color});

  String _format(Duration d) {
    final hours = d.inHours;
    final minutes = d.inMinutes % 60;
    final seconds = d.inSeconds % 60;
    final centis = (d.inMilliseconds % 1000) ~/ 10;
    final mm = minutes.toString().padLeft(2, '0');
    final ss = seconds.toString().padLeft(2, '0');
    final cs = centis.toString().padLeft(2, '0');
    return hours > 0 ? '$hours:$mm:$ss.$cs' : '$mm:$ss.$cs';
  }

  @override
  Widget build(BuildContext context) {
    return Text(
      _format(elapsed),
      style: TextStyle(
        fontSize: 56,
        fontWeight: FontWeight.w200,
        letterSpacing: -1,
        color: color,
      ),
    );
  }
}
