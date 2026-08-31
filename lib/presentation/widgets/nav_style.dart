import 'package:flutter/material.dart';

/// Single source of truth for the M4 floating bottom navigation.
///
/// Guest, Customer, CP and Investor each build their own bar (different tab
/// counts and destinations), but every visual value comes from here so the
/// component reads as one shared M4 element regardless of which portal is open.
class M4Nav {
  M4Nav._();

  /// Bar height, excluding the float margin. Figma: 65.
  static const double height = 65;

  /// Fully rounded pill — Figma radius 32.5, exactly half the height, so both
  /// ends are true semicircles.
  static const double radius = 32.5;

  /// Frosted-glass blur applied behind the bar.
  static const double blur = 30;

  /// Side inset from the screen edge, and the float gap above the bottom.
  /// Figma: a 329-wide bar on a 390-wide frame — (390 - 329) / 2 = 30.5.
  static const double sideInset = 30.5;
  static const double bottomInset = 14;

  /// Figma bar width. The bar is centred and never exceeds this.
  static const double width = 329;

  /// Figma glass fill: #FFFFFF at 10%, over the blur. One flat tint for every
  /// portal — no per-portal gradients, so all four bars read identically.
  static const Color glass = Color(0x1AFFFFFF);

  // The active-tab treatment follows the surface behind the bar.
  //
  // On the deep-green "showcase" screens the disc is a soft translucent white
  // with a white glyph (the Figma glass look). On the cream info screens that
  // would be white-on-cream — invisible — so there the disc is a SOLID brand
  // green with a cream glyph, and inactive glyphs are muted green.
  //
  // Brand green for the filled disc on cream.
  static const Color discGreen = Color(0xFF0C312B);

  /// Glyph on the green showcase surfaces.
  static const Color glyphOnGreen = Colors.white;

  /// Glyph inside the solid green disc on cream.
  static const Color glyphOnDisc = Color(0xFFF4EFE3);

  /// Inactive glyph on cream (muted brand green).
  static const Color glyphOnCream = Color(0xFF0C312B);

  /// Translucent disc on the green surfaces.
  static const Color activeDiscTint = Color(0x38FFFFFF); // white at 22%

  /// Inner horizontal padding between the pill edge and the first/last tab.
  static const double innerPadding = 16;

  /// Tab glyph size.
  static const double iconSize = 24;

  /// Active-tab disc diameter.
  static const double activeDisc = 50;

  /// Inactive glyphs sit at this opacity of the active colour.
  static const double inactiveOpacity = 0.72;

  /// Tab-change animation. Short enough to feel responsive, long enough to
  /// read as a transition rather than a jump.
  static const Duration animation = Duration(milliseconds: 260);
  static const Curve curve = Curves.easeOutCubic;

  /// A swipe must clear this horizontal velocity to change tabs, so ordinary
  /// scrolling and card carousels are never hijacked.
  static const double swipeVelocity = 250;

  /// Soft lift instead of a hard drop shadow: deep green at low alpha with a
  /// negative spread, so nothing pools past the pill's corners and no black
  /// shadow appears on the cream screens.
  static List<BoxShadow> shadow(bool isDark) => [
    BoxShadow(
      color: const Color(0xFF0C312B).withValues(alpha: isDark ? 0.24 : 0.10),
      blurRadius: 24,
      spreadRadius: -10,
      offset: const Offset(0, 8),
    ),
  ];
}
