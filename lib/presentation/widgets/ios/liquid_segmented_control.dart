import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:m4_mobile/presentation/widgets/ios/liquid_glass_bar.dart';

/// A segmented filter control — Ongoing / Upcoming / Completed — on the same
/// Liquid Glass as the bottom nav.
///
/// Same material, same travelling bead, same press-and-drag; only the geometry
/// differs. The bead fills its slot here instead of being a round disc, which
/// keeps Figma's "polished light chip" while making it real glass rather than
/// a painted gradient.
class LiquidSegmentedControl extends StatelessWidget {
  const LiquidSegmentedControl({
    super.key,
    required this.labels,
    required this.currentIndex,
    required this.onSelected,
  });

  final List<String> labels;
  final int currentIndex;
  final ValueChanged<int> onSelected;

  /// Figma runs this control noticeably slimmer than a stock 45pt tab bar —
  /// that lower height is what makes it read as sleek rather than chunky.
  static const double height = 38;
  static const double radius = 19;

  @override
  Widget build(BuildContext context) {
    final bool onCream = Theme.of(context).brightness == Brightness.light;

    return LiquidGlassBar(
      slotCount: labels.length,
      currentIndex: currentIndex,
      onSelected: onSelected,
      height: height,
      radius: radius,
      // Both dimensions left at 0: the chip fills its slot, less the inset.
      beadInset: 3,
      barTintDark: 0.10,
      barTintCream: 0.12,
      // Brighter than the nav's bead so the chip still reads as the light
      // plate Figma asks for, and so dark ink sits legibly on it.
      beadTintDark: 0.46,
      beadTintCream: 0.38,
      slotBuilder: (context, i, isActive) => AnimatedDefaultTextStyle(
        duration: const Duration(milliseconds: 280),
        curve: Curves.easeOutCubic,
        style: GoogleFonts.inter(
          fontSize: 10,
          fontWeight: isActive ? FontWeight.w600 : FontWeight.bold,
          color: isActive
              ? const Color(0xFF15271E)
              : Theme.of(context).colorScheme.onSurface.withValues(
                  alpha: onCream ? 0.60 : 0.55,
                ),
          letterSpacing: 1,
        ),
        child: Text(labels[i].toUpperCase()),
      ),
    );
  }
}
