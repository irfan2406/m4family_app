import 'package:flutter/material.dart';
import 'package:lucide_icons/lucide_icons.dart';

/// The single, canonical "..." side-menu button used across EVERY portal
/// (Guest, Customer, CP, Investor) and every screen.
///
/// It is an exact copy of the original Guest/Investor/CP/Customer home-header
/// button so the size, colour and behaviour are identical everywhere and in
/// both light and dark mode:
///   • 56 × 36 rounded (radius 14) pill
///   • black fill + white icon in LIGHT mode
///   • white fill + black icon in DARK mode
///   • centred [LucideIcons.menu] icon, size 24
///
/// By default it opens the nearest [Scaffold]'s drawer. Pass [onTap] to
/// override (e.g. to open an end-drawer or a custom menu).
class SideMenuButton extends StatelessWidget {
  const SideMenuButton({super.key, this.onTap});

  /// Optional tap override. When null, opens the enclosing Scaffold's drawer.
  final VoidCallback? onTap;

  @override
  Widget build(BuildContext context) {
    final bool isDark = Theme.of(context).brightness == Brightness.dark;
    return GestureDetector(
      behavior: HitTestBehavior.opaque,
      onTap:
          onTap ??
          () {
            final scaffold = Scaffold.maybeOf(context);
            if (scaffold?.hasDrawer ?? false) {
              scaffold!.openDrawer();
            }
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
          color: Theme.of(context).colorScheme.onSurface,
          size: 24,
        ),
      ),
    );
  }
}
