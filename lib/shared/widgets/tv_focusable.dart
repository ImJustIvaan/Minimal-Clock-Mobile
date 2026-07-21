import 'package:flutter/material.dart';

/// Wraps a tappable widget so it can be reached and activated with a D-pad
/// (Android TV remote): focusable via arrow-key traversal, and a visible
/// highlight ring plus scale so the currently-focused item is obvious from
/// across the room. Activated by Enter/Space/D-pad center, same as a tap.
class TvFocusable extends StatefulWidget {
  final Widget child;
  final VoidCallback? onTap;
  final BorderRadius? borderRadius;

  const TvFocusable({
    super.key,
    required this.child,
    required this.onTap,
    this.borderRadius,
  });

  @override
  State<TvFocusable> createState() => _TvFocusableState();
}

class _TvFocusableState extends State<TvFocusable> {
  bool _focused = false;

  @override
  Widget build(BuildContext context) {
    final color = Theme.of(context).colorScheme.onSurface;
    final radius = widget.borderRadius ?? BorderRadius.circular(12);
    return FocusableActionDetector(
      enabled: widget.onTap != null,
      onShowFocusHighlight: (v) => setState(() => _focused = v),
      actions: {
        ActivateIntent: CallbackAction<ActivateIntent>(
          onInvoke: (_) => widget.onTap?.call(),
        ),
      },
      child: GestureDetector(
        onTap: widget.onTap,
        child: AnimatedScale(
          duration: const Duration(milliseconds: 120),
          scale: _focused ? 1.03 : 1.0,
          child: Container(
            decoration: BoxDecoration(
              borderRadius: radius,
              border: _focused
                  ? Border.all(color: color.withOpacity(0.8), width: 2)
                  : null,
            ),
            child: widget.child,
          ),
        ),
      ),
    );
  }
}
