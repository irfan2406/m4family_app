import 'dart:ui';

import 'package:flutter/material.dart';
import 'package:m4_mobile/presentation/widgets/nav_style.dart';

/// THE M4 bottom navigation bar.
///
/// Every portal — guest, customer, CP, investor — renders this one widget, so
/// the bar is byte-for-byte identical everywhere. Portals only supply their own
/// icons, selected index and tap handler; nothing about the look is passed in,
/// because nothing about the look is allowed to differ.
///
/// Every measurement comes from the Figma spec (see [M4Nav]):
/// 329 × 65, radius 32.5, #FFFFFF at 10% over a 30px backdrop blur.
class M4BottomNav extends StatelessWidget {
  const M4BottomNav({
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
    // Figma shows a distinctly lighter frosted pill on both surfaces: a whiter
    // frost on the cream screens (clearly lighter than #D4CFBC), a subtler
    // light frost over the green showcase screens.
    final bool onCream = Theme.of(context).brightness == Brightness.light;
    final Color glass = onCream
        ? Colors.white.withValues(alpha: 0.60)
        : Colors.white.withValues(alpha: 0.14);
    final Color hairline = onCream
        ? Colors.white.withValues(alpha: 0.70)
        : Colors.white.withValues(alpha: 0.22);

    return SafeArea(
      top: false,
      // Clear the gesture bar / home indicator, then float the spec gap above
      // it, so the bar never touches the bottom edge on any device.
      child: Padding(
        // Falls back to a smaller gutter only on phones too narrow for the
        // spec width; on a standard frame the ConstrainedBox wins at 329.
        padding: const EdgeInsets.fromLTRB(16, 0, 16, M4Nav.bottomInset),
        child: Center(
          // heightFactor 1 keeps this sized to the bar. Without it, Center
          // expands to every pixel the parent offers and floats the bar into
          // the middle of the screen.
          heightFactor: 1,
          child: ConstrainedBox(
            constraints: const BoxConstraints(maxWidth: M4Nav.width),
            child: DecoratedBox(
              // The lift lives outside the clip, or the corners would shear it.
              decoration: BoxDecoration(
                borderRadius: BorderRadius.circular(M4Nav.radius),
                boxShadow: M4Nav.shadow(true),
              ),
              child: ClipRRect(
                borderRadius: BorderRadius.circular(M4Nav.radius),
                child: BackdropFilter(
                  filter: ImageFilter.blur(
                    sigmaX: M4Nav.blur,
                    sigmaY: M4Nav.blur,
                  ),
                  child: Container(
                    height: M4Nav.height,
                    decoration: BoxDecoration(
                      color: glass,
                      borderRadius: BorderRadius.circular(M4Nav.radius),
                      border: Border.all(color: hairline, width: 1),
                    ),
                    child: Row(
                      mainAxisAlignment: MainAxisAlignment.spaceEvenly,
                      children: List.generate(
                        icons.length,
                        (i) => _M4NavTab(
                          icon: icons[i],
                          isActive: currentIndex == i,
                          onTap: () => onTap(i),
                        ),
                      ),
                    ),
                  ),
                ),
              ),
            ),
          ),
        ),
      ),
    );
  }
}

/// One tab: the glyph, and a soft translucent disc behind it when selected.
class _M4NavTab extends StatefulWidget {
  const _M4NavTab({
    required this.icon,
    required this.isActive,
    required this.onTap,
  });

  final IconData icon;
  final bool isActive;
  final VoidCallback onTap;

  @override
  State<_M4NavTab> createState() => _M4NavTabState();
}

class _M4NavTabState extends State<_M4NavTab>
    with SingleTickerProviderStateMixin {
  late final AnimationController _controller = AnimationController(
    vsync: this,
    duration: const Duration(milliseconds: 100),
  );
  late final Animation<double> _scale = Tween<double>(
    begin: 1,
    end: 0.95,
  ).animate(CurvedAnimation(parent: _controller, curve: Curves.easeInOut));

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    // Follow the surface behind the bar: green showcase screens report a dark
    // brightness, cream info screens a light one.
    final bool onCream = Theme.of(context).brightness == Brightness.light;

    // Figma active tab: a SOLID filled disc. On cream it's brand green with a
    // cream glyph; on the green showcase screens it's a cream/white disc with a
    // green glyph. Inactive glyphs are muted in the surface's foreground tone.
    final Color discColor = widget.isActive
        ? (onCream ? M4Nav.discGreen : M4Nav.glyphOnDisc)
        : Colors.transparent;
    final Color glyphColor = widget.isActive
        ? (onCream ? M4Nav.glyphOnDisc : M4Nav.discGreen)
        : (onCream
              ? M4Nav.glyphOnCream.withValues(alpha: M4Nav.inactiveOpacity)
              : M4Nav.glyphOnGreen.withValues(alpha: M4Nav.inactiveOpacity));

    return GestureDetector(
      behavior: HitTestBehavior.opaque,
      onTapDown: (_) => _controller.forward(),
      onTapUp: (_) => _controller.reverse(),
      onTapCancel: () => _controller.reverse(),
      onTap: widget.onTap,
      child: ScaleTransition(
        scale: _scale,
        child: AnimatedContainer(
          duration: M4Nav.animation,
          curve: M4Nav.curve,
          width: M4Nav.activeDisc,
          height: M4Nav.activeDisc,
          decoration: BoxDecoration(color: discColor, shape: BoxShape.circle),
          child: Center(
            child: Icon(widget.icon, size: M4Nav.iconSize, color: glyphColor),
          ),
        ),
      ),
    );
  }
}
