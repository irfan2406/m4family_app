import 'dart:ui';

import 'package:flutter/material.dart';

/// Single source of truth for the M4 navigation drawer's glass panel.
///
/// Figma (Rectangle 2): 332 × 885, fill #0B0000 at 10%, over a strong backdrop
/// blur. The deep-green base, the warm cream bloom through the middle and the
/// cool blue bloom low down are separate translucent layers on top of the blur,
/// which is what keeps the panel from reading as one flat colour.
class M4Drawer {
  M4Drawer._();

  /// Figma panel width. The drawer never exceeds this.
  static const double width = 332;

  /// The panel's width on this screen: the Figma 332, or 85% of the screen on
  /// phones too narrow to fit it. Every portal's drawer calls this, so they are
  /// all exactly the same width.
  static double panelWidth(BuildContext context) {
    final fraction = MediaQuery.of(context).size.width * 0.85;
    return fraction < width ? fraction : width;
  }

  /// Backdrop blur behind the panel. Strong enough that whatever is behind
  /// dissolves into soft colour instead of staying legible through the glass.
  static const double blur = 48;

  /// How much of the tint survives. Low on purpose: a panel painted at 85–90%
  /// is a dark surface with a blur behind it, not glass. These let the blurred
  /// screen read through, which is what sells the water-glass look.
  static const double baseAlphaEdge = 0.52;
  static const double baseAlphaCentre = 0.38;

  /// The light catching the top of the glass.
  static const Color sheen = Colors.white;

  /// Figma fill: #0B0000 at 10%.
  static const Color veil = Color(0x1A0B0000);

  /// Deep emerald base, darker at the edges than through the middle.
  static const Color greenDeep = Color(0xFF0C312B);
  static const Color greenEdge = Color(0xFF08221E);

  /// Warm cream bloom, centred vertically.
  static const Color creamGlow = Color(0xFFF4EFE3);

  /// Cool blue bloom, low in the panel.
  static const Color blueGlow = Color(0xFF6E9BC4);

  /// Almost invisible cream hairline down the open edge.
  static Color get border => creamGlow.withValues(alpha: 0.10);

  /// Large, soft ambient lift — no hard edge anywhere.
  static List<BoxShadow> get shadow => [
    BoxShadow(
      color: Colors.black.withValues(alpha: 0.35),
      blurRadius: 60,
      spreadRadius: -10,
      offset: const Offset(8, 0),
    ),
  ];
}

/// The drawer's frosted panel: blur, deep-green base, cream and blue blooms,
/// then the Figma veil. Purely decorative — it takes no space and swallows no
/// taps, so it can sit behind any drawer content.
class DrawerGlass extends StatelessWidget {
  const DrawerGlass({super.key});

  @override
  Widget build(BuildContext context) {
    return Positioned.fill(
      child: IgnorePointer(
        child: ClipRect(
          child: BackdropFilter(
            filter: ImageFilter.blur(
              sigmaX: M4Drawer.blur,
              sigmaY: M4Drawer.blur,
            ),
            child: Stack(
              fit: StackFit.expand,
              children: [
                // Deep emerald base — thin, and darker at the edges than
                // through the middle, so the panel has depth rather than one
                // flat wash.
                DecoratedBox(
                  decoration: BoxDecoration(
                    gradient: LinearGradient(
                      begin: Alignment.topLeft,
                      end: Alignment.bottomRight,
                      colors: [
                        M4Drawer.greenEdge.withValues(
                          alpha: M4Drawer.baseAlphaEdge,
                        ),
                        M4Drawer.greenDeep.withValues(
                          alpha: M4Drawer.baseAlphaCentre,
                        ),
                        M4Drawer.greenEdge.withValues(
                          alpha: M4Drawer.baseAlphaEdge + 0.02,
                        ),
                      ],
                      stops: const [0.0, 0.45, 1.0],
                    ),
                  ),
                ),
                // Warm cream bloom through the middle.
                DecoratedBox(
                  decoration: BoxDecoration(
                    gradient: RadialGradient(
                      center: const Alignment(0.15, 0.02),
                      radius: 0.95,
                      colors: [
                        M4Drawer.creamGlow.withValues(alpha: 0.12),
                        M4Drawer.creamGlow.withValues(alpha: 0.05),
                        Colors.transparent,
                      ],
                      stops: const [0.0, 0.45, 1.0],
                    ),
                  ),
                ),
                // Cool blue bloom low down.
                DecoratedBox(
                  decoration: BoxDecoration(
                    gradient: RadialGradient(
                      center: const Alignment(-0.1, 0.72),
                      radius: 0.85,
                      colors: [
                        M4Drawer.blueGlow.withValues(alpha: 0.14),
                        M4Drawer.blueGlow.withValues(alpha: 0.05),
                        Colors.transparent,
                      ],
                      stops: const [0.0, 0.5, 1.0],
                    ),
                  ),
                ),
                // Figma veil: #0B0000 at 10% over everything.
                const ColoredBox(color: M4Drawer.veil),
                // Reflection: light grazing the top of the pane and fading out
                // by the upper third. Above the veil, or the veil would dull
                // the very highlight that makes it read as glass.
                DecoratedBox(
                  decoration: BoxDecoration(
                    gradient: LinearGradient(
                      begin: Alignment.topCenter,
                      end: Alignment.bottomCenter,
                      colors: [
                        M4Drawer.sheen.withValues(alpha: 0.13),
                        M4Drawer.sheen.withValues(alpha: 0.04),
                        Colors.transparent,
                      ],
                      stops: const [0.0, 0.16, 0.52],
                    ),
                  ),
                ),
                // Soft inner border — the lit edge of a pane of glass, drawn
                // inside the panel so it never reads as a drawn outline.
                DecoratedBox(
                  decoration: BoxDecoration(
                    border: Border.all(
                      color: M4Drawer.sheen.withValues(alpha: 0.09),
                      width: 0.8,
                    ),
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}
