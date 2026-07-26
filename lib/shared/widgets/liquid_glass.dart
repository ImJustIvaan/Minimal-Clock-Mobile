import 'dart:ui';
import 'package:flutter/material.dart';

/// Extra bottom clearance a screen's own floating content (e.g. a FAB)
/// needs on iOS so it doesn't sit behind the floating Liquid Glass nav bar
/// — that bar's own height (64) plus its bottom margin (12) plus a small
/// visual gap above it.
const double kLiquidGlassNavClearance = 88;

/// A frosted, refractive surface that approximates iOS 26's "Liquid Glass"
/// material: a blurred backdrop, a faint tinted fill, and a bright
/// highlight along the top edge that reads as light catching curved glass.
/// Flutter has no binding to Apple's real UIGlassEffect, so this is a
/// visual approximation built from BackdropFilter + gradients — intended
/// for iOS only, where the rest of the system now uses this look.
class LiquidGlass extends StatelessWidget {
  final Widget child;
  final BorderRadius borderRadius;
  final double blur;
  final EdgeInsetsGeometry? padding;

  const LiquidGlass({
    super.key,
    required this.child,
    this.borderRadius = const BorderRadius.all(Radius.circular(28)),
    this.blur = 24,
    this.padding,
  });

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final tint = isDark ? Colors.white : Colors.black;
    final highlight = isDark ? Colors.white : Colors.white;

    return ClipRRect(
      borderRadius: borderRadius,
      child: BackdropFilter(
        filter: ImageFilter.blur(sigmaX: blur, sigmaY: blur),
        child: Container(
          padding: padding,
          decoration: BoxDecoration(
            borderRadius: borderRadius,
            gradient: LinearGradient(
              begin: Alignment.topCenter,
              end: Alignment.bottomCenter,
              colors: [
                tint.withValues(alpha: isDark ? 0.16 : 0.06),
                tint.withValues(alpha: isDark ? 0.08 : 0.03),
              ],
            ),
            border: Border.all(
              color: highlight.withValues(alpha: isDark ? 0.22 : 0.55),
              width: 0.8,
            ),
            boxShadow: [
              BoxShadow(
                color: Colors.black.withValues(alpha: isDark ? 0.35 : 0.10),
                blurRadius: 20,
                offset: const Offset(0, 8),
              ),
            ],
          ),
          child: child,
        ),
      ),
    );
  }
}
