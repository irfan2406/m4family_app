import 'package:flutter/material.dart';
import 'package:m4_mobile/presentation/widgets/ios/native_tab_bar.dart';
import 'package:m4_mobile/presentation/widgets/nav_style.dart';

/// iOS: the M4 bottom bar as a real Liquid Glass tab bar.
///
/// UIKit draws and drives the whole bar (see [NativeTabBar]); this is the M4
/// bottom nav's share of it — the Figma footprint (329 × 65, radius 32.5), the
/// round 50pt bead, and the glyph colours for each surface.
class LiquidTabBar extends StatelessWidget {
  const LiquidTabBar({
    super.key,
    required this.icons,
    required this.currentIndex,
    required this.onTap,
  });

  /// One glyph per tab, in tab order.
  final List<IconData> icons;

  /// Selected tab, or a negative value when no tab is selected.
  final int currentIndex;

  final ValueChanged<int> onTap;

  @override
  Widget build(BuildContext context) {
    final bool onCream = Theme.of(context).brightness == Brightness.light;

    return SafeArea(
      top: false,
      // Clears the home indicator, then floats the spec gap above it.
      child: Padding(
        padding: const EdgeInsets.fromLTRB(16, 0, 16, M4Nav.bottomInset),
        child: Center(
          heightFactor: 1,
          child: ConstrainedBox(
            constraints: const BoxConstraints(maxWidth: M4Nav.width),
            child: DecoratedBox(
              // The lift stays on the Flutter side: a shadow drawn inside the
              // platform view would be clipped to its own bounds.
              decoration: BoxDecoration(
                borderRadius: BorderRadius.circular(M4Nav.radius),
                boxShadow: M4Nav.shadow(!onCream),
              ),
              child: NativeTabBar(
                icons: icons,
                currentIndex: currentIndex,
                onTap: onTap,
                height: M4Nav.height,
                radius: M4Nav.radius,
                // A round bead, shrunk only when a bar with many tabs on a
                // narrow phone has less room than that per tab.
                beadWidth: M4Nav.activeDisc,
                beadHeight: M4Nav.activeDisc,
                iconSize: M4Nav.iconSize,
                // Over the clear glass bead the selected glyph takes the ink
                // of the surface: white on the green screens, M4 green on the
                // cream ones.
                activeColor: onCream ? M4Nav.discGreen : M4Nav.glyphOnGreen,
                inactiveColor:
                    (onCream ? M4Nav.glyphOnCream : M4Nav.glyphOnGreen)
                        .withValues(alpha: M4Nav.inactiveOpacity),
              ),
            ),
          ),
        ),
      ),
    );
  }
}
