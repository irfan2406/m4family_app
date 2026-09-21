import 'package:flutter/material.dart';
import 'package:lucide_icons/lucide_icons.dart';
import 'package:m4_mobile/core/platform/m4_platform.dart';
import 'package:m4_mobile/presentation/widgets/ios/liquid_glass.dart';

/// The single, canonical hamburger side-menu button used across EVERY portal
/// (Guest, Customer, CP, Investor) and every screen.
///
/// One shared button so size, colour and behaviour are identical everywhere in
/// both light and dark mode:
///   • 56 × 36 tap target, no filled pill (transparent — no white/black box)
///   • centred [LucideIcons.menu] hamburger, size 24
///   • icon colour follows the surface via `colorScheme.onSurface`, so it is
///     white on the deep-green showcase screens and forest-green on cream
///
/// By default it opens the nearest [Scaffold]'s drawer. Pass [onTap] to
/// override (e.g. to open an end-drawer or a custom menu).
class SideMenuButton extends StatelessWidget {
  const SideMenuButton({super.key, this.onTap});

  /// Optional tap override. When null, opens the enclosing Scaffold's drawer.
  final VoidCallback? onTap;

  @override
  Widget build(BuildContext context) {
    // iOS: a floating Liquid Glass capsule in the same 56 × 36 slot, so no
    // header moves. Everything below is the Android button, unchanged.
    if (M4Platform.isIOS) {
      return _GlassMenuButton(
        onTap: onTap ?? () => _openNearestDrawer(context),
        iconColor: Theme.of(context).brightness == Brightness.dark
            ? Colors.white
            : Theme.of(context).colorScheme.onSurface,
      );
    }

    final bool isDark = Theme.of(context).brightness == Brightness.dark;
    return GestureDetector(
      behavior: HitTestBehavior.opaque,
      onTap:
          onTap ??
          () {
            // Walk out to the first Scaffold that actually owns a drawer. A
            // tab screen nested in a shell has a Scaffold of its own with no
            // drawer; the shell above it holds the menu, and opening that one
            // gives the full-height panel that draws over the nav pill —
            // exactly what the Home tab shows.
            ScaffoldState? scaffold = Scaffold.maybeOf(context);
            while (scaffold != null && !scaffold.hasDrawer) {
              scaffold = scaffold.context
                  .findAncestorStateOfType<ScaffoldState>();
            }
            scaffold?.openDrawer();
          },
      child: Container(
        width: 56,
        height: 36,
        alignment: Alignment.center,
        decoration: BoxDecoration(
          color: Colors.transparent,
          borderRadius: BorderRadius.circular(14),
        ),
        child: Icon(
          LucideIcons.menu,
          color: Theme.of(context).brightness == Brightness.dark
              ? Colors.white
              : Theme.of(context).colorScheme.onSurface,
          size: 24,
        ),
      ),
    );
  }

  /// Opens the first enclosing Scaffold that owns a drawer — the same walk the
  /// Android button does inline.
  static void _openNearestDrawer(BuildContext context) {
    ScaffoldState? scaffold = Scaffold.maybeOf(context);
    while (scaffold != null && !scaffold.hasDrawer) {
      scaffold = scaffold.context.findAncestorStateOfType<ScaffoldState>();
    }
    scaffold?.openDrawer();
  }
}

/// iOS: the menu glyph on a small Liquid Glass capsule that dims under the
/// finger, the way iOS bar buttons respond.
class _GlassMenuButton extends StatefulWidget {
  const _GlassMenuButton({required this.onTap, required this.iconColor});

  final VoidCallback onTap;
  final Color iconColor;

  @override
  State<_GlassMenuButton> createState() => _GlassMenuButtonState();
}

class _GlassMenuButtonState extends State<_GlassMenuButton> {
  bool _pressed = false;

  void _press(bool down) {
    if (_pressed != down) setState(() => _pressed = down);
  }

  @override
  Widget build(BuildContext context) {
    return Semantics(
      button: true,
      label: 'Menu',
      child: GestureDetector(
        behavior: HitTestBehavior.opaque,
        onTapDown: (_) => _press(true),
        onTapUp: (_) => _press(false),
        onTapCancel: () => _press(false),
        onTap: widget.onTap,
        child: SizedBox(
          width: 56,
          height: 36,
          child: Center(
            child: AnimatedOpacity(
              opacity: _pressed ? 0.5 : 1,
              duration: const Duration(milliseconds: 120),
              child: LiquidGlass(
                thickness: LiquidGlassThickness.thin,
                borderRadius: BorderRadius.circular(18),
                child: SizedBox(
                  width: 48,
                  height: 36,
                  child: Icon(
                    LucideIcons.menu,
                    size: 20,
                    color: widget.iconColor,
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
