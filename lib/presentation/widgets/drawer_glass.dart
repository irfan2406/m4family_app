import 'dart:ui';

import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';

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

  /// Cool icy blue-white bloom, low in the panel — the water-glass light.
  static const Color blueGlow = Color(0xFF9FC3E4);

  /// Saturation-boost matrix for the backdrop, so the diffused colours behind
  /// the glass read richer (Apple "vibrancy"), not washed out. [s] is the
  /// saturation multiplier (1 = unchanged).
  static List<double> saturate(double s) {
    const double lumR = 0.2126, lumG = 0.7152, lumB = 0.0722;
    final double inv = 1 - s;
    final double r = inv * lumR, g = inv * lumG, b = inv * lumB;
    return <double>[
      r + s, g, b, 0, 0,
      r, g + s, b, 0, 0,
      r, g, b + s, 0, 0,
      0, 0, 0, 1, 0,
    ];
  }

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

  // ---- Menu tile: a micro glass surface, shared by every portal ------------
  static const double tileRadius = 14;
  static const EdgeInsets tileMargin = EdgeInsets.symmetric(
    horizontal: 8,
    vertical: 3,
  );

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
            // Frosted-glass backdrop: blur, then a saturation boost so the
            // colours behind diffuse richly through the glass instead of
            // greying out. compose() runs `inner` first, then `outer`.
            filter: ImageFilter.compose(
              outer: ImageFilter.blur(
                sigmaX: M4Drawer.blur,
                sigmaY: M4Drawer.blur,
              ),
              inner: ColorFilter.matrix(M4Drawer.saturate(1.7)),
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
                // Top-left light entering the glass — gentle, cream-tinted
                // white, extremely subtle.
                DecoratedBox(
                  decoration: BoxDecoration(
                    gradient: RadialGradient(
                      center: const Alignment(-0.75, -0.95),
                      radius: 1.1,
                      colors: [
                        M4Drawer.creamGlow.withValues(alpha: 0.14),
                        M4Drawer.creamGlow.withValues(alpha: 0.05),
                        Colors.transparent,
                      ],
                      stops: const [0.0, 0.4, 1.0],
                    ),
                  ),
                ),
                // Center bloom — a large, very soft cream glow that looks
                // trapped inside the frosted glass. No hard edge anywhere.
                DecoratedBox(
                  decoration: BoxDecoration(
                    gradient: RadialGradient(
                      center: const Alignment(0.1, 0.05),
                      radius: 1.15,
                      colors: [
                        M4Drawer.creamGlow.withValues(alpha: 0.13),
                        M4Drawer.creamGlow.withValues(alpha: 0.05),
                        Colors.transparent,
                      ],
                      stops: const [0.0, 0.5, 1.0],
                    ),
                  ),
                ),
                // Bottom light — icy blue-white, large and diffuse: the
                // signature water-glass source.
                DecoratedBox(
                  decoration: BoxDecoration(
                    gradient: RadialGradient(
                      center: const Alignment(-0.15, 0.85),
                      radius: 1.0,
                      colors: [
                        M4Drawer.blueGlow.withValues(alpha: 0.18),
                        M4Drawer.blueGlow.withValues(alpha: 0.06),
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

/// THE M4 drawer row.
///
/// Guest, customer, CP and investor all render this one widget, so every
/// portal's menu is visually identical: same glass tile, same 44px icon
/// surface, same type, same active treatment. Portals only pass their own
/// icon, label, active flag and tap handler — nothing about the look.
class M4DrawerTile extends StatelessWidget {
  const M4DrawerTile({
    super.key,
    required this.icon,
    required this.label,
    required this.isActive,
    this.onTap,
    this.trailing,
    this.accent,
  });

  final IconData icon;
  final String label;
  final bool isActive;
  final VoidCallback? onTap;

  /// Chevron for expandable groups, badge counts, etc.
  final Widget? trailing;

  /// Portal accent for the active row (investor gold, otherwise cream).
  final Color? accent;

  @override
  Widget build(BuildContext context) {
    final Color on = accent ?? M4Drawer.creamGlow;
    // No card, no box, no border around the row: the items sit directly on the
    // panel's glass, exactly as in the reference. The only marks are the icon
    // surface and, when active, the lit accent bar — anything more turns the
    // menu into a stack of heavy tiles.
    return Container(
      margin: M4Drawer.tileMargin,
      child: Material(
        color: Colors.transparent,
        borderRadius: BorderRadius.circular(M4Drawer.tileRadius),
        child: InkWell(
          onTap: onTap,
          borderRadius: BorderRadius.circular(M4Drawer.tileRadius),
          child: Padding(
            padding: const EdgeInsets.fromLTRB(10, 10, 14, 10),
            child: Row(
              children: [
                // Active accent: a short lit bar on the leading edge.
                AnimatedContainer(
                  duration: const Duration(milliseconds: 300),
                  curve: Curves.easeOut,
                  width: 3,
                  height: 26,
                  decoration: BoxDecoration(
                    color: isActive ? on : Colors.transparent,
                    borderRadius: BorderRadius.circular(3),
                  ),
                ),
                const SizedBox(width: 10),
                // Icon surface.
                AnimatedContainer(
                  duration: const Duration(milliseconds: 300),
                  curve: Curves.easeOut,
                  width: 44,
                  height: 44,
                  decoration: BoxDecoration(
                    // Barely-there glass square; only the active one picks up a
                    // faint edge. Heavier than this and the row reads as a card.
                    color: on.withValues(alpha: isActive ? 0.12 : 0.06),
                    borderRadius: BorderRadius.circular(12),
                    border: isActive
                        ? Border.all(
                            color: on.withValues(alpha: 0.20),
                            width: 0.8,
                          )
                        : null,
                  ),
                  child: Center(
                    child: Icon(
                      icon,
                      size: 20,
                      color: on.withValues(alpha: isActive ? 1.0 : 0.80),
                    ),
                  ),
                ),
                const SizedBox(width: 14),
                Expanded(
                  child: Text(
                    label,
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                    style: GoogleFonts.inter(
                      fontSize: 15.5,
                      fontWeight: isActive ? FontWeight.w600 : FontWeight.w500,
                      letterSpacing: -0.2,
                      color: on.withValues(alpha: isActive ? 1.0 : 0.88),
                    ),
                  ),
                ),
                if (trailing != null) trailing!,
              ],
            ),
          ),
        ),
      ),
    );
  }
}
