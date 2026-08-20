import 'package:flutter/material.dart';

/// Single source of truth for the M4 floating bottom navigation.
///
/// Guest, Customer, CP and Investor each build their own bar (different tab
/// counts and destinations), but every visual value comes from here so the
/// component reads as one shared M4 element regardless of which portal is open.
class M4Nav {
  M4Nav._();

  /// Bar height, excluding the float margin.
  static const double height = 62;

  /// Fully rounded pill - both ends read as floating, never edge-attached.
  static const double radius = 40;

  /// Frosted-glass blur applied behind the bar.
  static const double blur = 30;

  /// Side inset from the screen edge, and the float gap above the bottom.
  static const double sideInset = 16;
  static const double bottomInset = 14;

  /// Inner horizontal padding between the pill edge and the first/last tab.
  static const double innerPadding = 8;

  /// Tab glyph size.
  static const double iconSize = 22;

  /// Active-tab disc diameter.
  static const double activeDisc = 40;

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
