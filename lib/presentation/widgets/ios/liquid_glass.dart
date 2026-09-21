import 'dart:ui';

import 'package:flutter/material.dart';
import 'package:m4_mobile/presentation/widgets/drawer_glass.dart' show M4Drawer;

/// How much of the scene behind a [LiquidGlass] surface is dissolved.
///
/// Mirrors the iOS materials: thin for small floating controls, regular for
/// bars, thick for large panels that carry a lot of text.
enum LiquidGlassThickness {
  thin(14),
  regular(24),
  thick(36);

  const LiquidGlassThickness(this.blur);

  /// Backdrop blur sigma.
  final double blur;
}

/// Apple-style Liquid Glass surface for the iOS presentation layer.
///
/// Four layers, bottom to top, in M4's palette:
///  1. the scene behind, blurred and saturated (iOS vibrancy) so colour
///     diffuses through the glass instead of greying out;
///  2. a frost that follows the surface — white on the cream screens, a
///     lighter veil over the deep-green showcase screens;
///  3. a lens highlight: light gathered along the top edge, fading down;
///  4. a specular rim — light catching the glass edge, brightest top-left and
///     again, softer, bottom-right.
///
/// Only the iOS code paths build this. Android keeps its own surfaces.
class LiquidGlass extends StatelessWidget {
  const LiquidGlass({
    super.key,
    required this.child,
    this.borderRadius = const BorderRadius.all(Radius.circular(24)),
    this.thickness = LiquidGlassThickness.regular,
    this.frost,
    this.lift = true,
  });

  final Widget child;
  final BorderRadius borderRadius;
  final LiquidGlassThickness thickness;

  /// Overrides the frost colour; defaults to one that follows the surface.
  final Color? frost;

  /// Whether the surface floats on a soft brand-tinted shadow.
  final bool lift;

  /// The frost for a surface of the given brightness.
  static Color frostFor(bool onLight) => onLight
      ? Colors.white.withValues(alpha: 0.56)
      : Colors.white.withValues(alpha: 0.12);

  /// A soft lift: deep green, not black, so nothing muddy pools on cream.
  static List<BoxShadow> liftFor(bool onLight) => [
    BoxShadow(
      color: const Color(0xFF0C312B).withValues(alpha: onLight ? 0.14 : 0.30),
      blurRadius: 30,
      spreadRadius: -8,
      offset: const Offset(0, 12),
    ),
  ];

  @override
  Widget build(BuildContext context) {
    final bool onLight = Theme.of(context).brightness == Brightness.light;

    return DecoratedBox(
      // The lift sits outside the clip, or the corners would shear it.
      decoration: BoxDecoration(
        borderRadius: borderRadius,
        boxShadow: lift ? liftFor(onLight) : null,
      ),
      child: ClipRRect(
        borderRadius: borderRadius,
        child: BackdropFilter(
          // compose() runs inner first: saturate, then blur.
          filter: ImageFilter.compose(
            outer: ImageFilter.blur(
              sigmaX: thickness.blur,
              sigmaY: thickness.blur,
            ),
            inner: ColorFilter.matrix(M4Drawer.saturate(1.8)),
          ),
          child: CustomPaint(
            foregroundPainter: _SpecularRim(
              borderRadius: borderRadius,
              onLight: onLight,
            ),
            child: DecoratedBox(
              decoration: BoxDecoration(color: frost ?? frostFor(onLight)),
              child: DecoratedBox(
                decoration: BoxDecoration(
                  gradient: LinearGradient(
                    begin: Alignment.topCenter,
                    end: Alignment.bottomCenter,
                    colors: [
                      Colors.white.withValues(alpha: onLight ? 0.34 : 0.14),
                      Colors.white.withValues(alpha: 0),
                      Colors.white.withValues(alpha: onLight ? 0.10 : 0.05),
                    ],
                    stops: const [0.0, 0.52, 1.0],
                  ),
                ),
                child: child,
              ),
            ),
          ),
        ),
      ),
    );
  }
}

/// The light caught along the glass edge.
class _SpecularRim extends CustomPainter {
  _SpecularRim({required this.borderRadius, required this.onLight});

  final BorderRadius borderRadius;
  final bool onLight;

  @override
  void paint(Canvas canvas, Size size) {
    final Rect rect = Offset.zero & size;
    final Paint paint = Paint()
      ..style = PaintingStyle.stroke
      ..strokeWidth = 1
      ..shader = LinearGradient(
        begin: Alignment.topLeft,
        end: Alignment.bottomRight,
        colors: [
          Colors.white.withValues(alpha: onLight ? 0.95 : 0.55),
          Colors.white.withValues(alpha: onLight ? 0.30 : 0.08),
          Colors.white.withValues(alpha: onLight ? 0.65 : 0.26),
        ],
        stops: const [0.0, 0.55, 1.0],
      ).createShader(rect);
    canvas.drawRRect(borderRadius.toRRect(rect).deflate(0.5), paint);
  }

  @override
  bool shouldRepaint(_SpecularRim old) =>
      old.borderRadius != borderRadius || old.onLight != onLight;
}
