import 'package:flutter/material.dart';

class AnimatedClockText extends StatefulWidget {
  final String text;
  final double fontSize;
  final Color color;

  const AnimatedClockText({
    super.key,
    required this.text,
    required this.fontSize,
    required this.color,
  });

  @override
  State<AnimatedClockText> createState() => _AnimatedClockTextState();
}

class _AnimatedClockTextState extends State<AnimatedClockText>
    with SingleTickerProviderStateMixin {
  late AnimationController _ctrl;
  late Animation<double> _fade;
  String _displayed = '';

  @override
  void initState() {
    super.initState();
    _displayed = widget.text;
    _ctrl = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 200),
    );
    _fade = Tween<double>(begin: 0, end: 1).animate(
      CurvedAnimation(parent: _ctrl, curve: Curves.easeIn),
    );
  }

  @override
  void didUpdateWidget(covariant AnimatedClockText oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (oldWidget.text != widget.text) {
      _displayed = widget.text;
      _ctrl.forward(from: 0);
    }
  }

  @override
  void dispose() {
    _ctrl.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return AnimatedBuilder(
      animation: _fade,
      builder: (_, __) => Text(
        _displayed,
        style: TextStyle(
          fontSize: widget.fontSize,
          fontWeight: FontWeight.w200,
          color: widget.color,
          letterSpacing: -2,
          height: 1,
        ),
      ),
    );
  }
}
