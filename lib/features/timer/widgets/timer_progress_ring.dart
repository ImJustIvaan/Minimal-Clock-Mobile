import 'dart:math' as math;
import 'package:flutter/material.dart';
import '../../../core/providers/timer_provider.dart';

class TimerProgressRing extends StatelessWidget {
  final TimerState state;
  final Color color;

  const TimerProgressRing({super.key, required this.state, required this.color});

  String _format(Duration d) {
    final h = d.inHours.toString().padLeft(2, '0');
    final m = (d.inMinutes % 60).toString().padLeft(2, '0');
    final s = (d.inSeconds % 60).toString().padLeft(2, '0');
    return d.inHours > 0 ? '$h:$m:$s' : '$m:$s';
  }

  @override
  Widget build(BuildContext context) {
    final isFinished = state.status == TimerStatus.finished;
    final screenWidth = MediaQuery.of(context).size.width;
    final ringSize = screenWidth >= 600 ? 380.0 : 260.0;
    final timeFontSize = screenWidth >= 600 ? 64.0 : 48.0;
    final finFontSize = screenWidth >= 600 ? 40.0 : 28.0;
    return SizedBox(
      width: ringSize,
      height: ringSize,
      child: Stack(
        alignment: Alignment.center,
        children: [
          AnimatedBuilder(
            animation: const AlwaysStoppedAnimation(0),
            builder: (_, __) => CustomPaint(
              size: Size(ringSize, ringSize),
              painter: _RingPainter(
                progress: state.progress,
                color: color,
                finished: isFinished,
              ),
            ),
          ),
          Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              AnimatedSwitcher(
                duration: const Duration(milliseconds: 200),
                child: Text(
                  isFinished ? 'Timer\nFinished' : _format(state.remaining),
                  key: ValueKey(isFinished ? 'fin' : state.remaining.inSeconds),
                  textAlign: TextAlign.center,
                  style: TextStyle(
                    fontSize: isFinished ? finFontSize : timeFontSize,
                    fontWeight: FontWeight.w200,
                    color: color,
                    letterSpacing: -1,
                    height: 1.2,
                  ),
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }
}

class _RingPainter extends CustomPainter {
  final double progress;
  final Color color;
  final bool finished;

  _RingPainter({required this.progress, required this.color, required this.finished});

  @override
  void paint(Canvas canvas, Size size) {
    final center = Offset(size.width / 2, size.height / 2);
    final radius = size.width / 2 - 8;
    const strokeWidth = 3.0;

    // Background track
    canvas.drawCircle(
      center,
      radius,
      Paint()
        ..color = color.withOpacity(0.08)
        ..style = PaintingStyle.stroke
        ..strokeWidth = strokeWidth,
    );

    if (progress <= 0) return;

    // Progress arc
    canvas.drawArc(
      Rect.fromCircle(center: center, radius: radius),
      -math.pi / 2,
      2 * math.pi * progress,
      false,
      Paint()
        ..color = finished ? color.withOpacity(0.3) : color.withOpacity(0.8)
        ..style = PaintingStyle.stroke
        ..strokeWidth = strokeWidth
        ..strokeCap = StrokeCap.round,
    );
  }

  @override
  bool shouldRepaint(covariant _RingPainter old) =>
      old.progress != progress || old.finished != finished;
}
