import 'package:flutter/material.dart';
import 'package:lucide_icons/lucide_icons.dart';
import 'package:m4_mobile/presentation/widgets/m4_bottom_nav.dart';

/// Customer portal bar: Home, Explore, Messages, Profile.
///
/// Nothing but the icons and the tap handler live here — the bar itself is
/// [M4BottomNav], the single component every portal renders.
class NavigationPill extends StatelessWidget {
  final int currentIndex;
  final Function(int) onTap;

  const NavigationPill({
    super.key,
    required this.currentIndex,
    required this.onTap,
  });

  static const _icons = <IconData>[
    LucideIcons.home,
    LucideIcons.compass,
    LucideIcons.messageSquare,
    LucideIcons.user,
  ];

  @override
  Widget build(BuildContext context) {
    return M4BottomNav(
      icons: _icons,
      currentIndex: currentIndex,
      onTap: (i) => onTap(i),
    );
  }
}
