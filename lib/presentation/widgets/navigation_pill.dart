import 'package:flutter/material.dart';
import 'package:lucide_icons/lucide_icons.dart';
import 'package:m4_mobile/presentation/widgets/m4_bottom_nav.dart';

/// Customer portal bar: Home, Explore, Who We Are, Messages, Profile.
///
/// Nothing but the icons and the tap handler live here — the bar itself is
/// [M4BottomNav], the single component every portal renders.
///
/// [currentIndex] and [onTap] speak the customer shell's tab indices. WHO WE
/// ARE is the shell's tab [whoWeAreTab] but sits in the middle of the bar (as
/// in the guest portal), so the bar maps its positions to tabs with
/// [tabOrder] — every existing tab keeps its index.
class NavigationPill extends StatelessWidget {
  final int currentIndex;
  final Function(int) onTap;

  const NavigationPill({
    super.key,
    required this.currentIndex,
    required this.onTap,
  });

  /// The customer shell's WHO WE ARE tab.
  static const int whoWeAreTab = 10;

  /// The shell tab behind each bar position, left to right.
  static const List<int> tabOrder = [0, 1, whoWeAreTab, 2, 3];

  static const _icons = <IconData>[
    LucideIcons.home,
    LucideIcons.compass,
    LucideIcons.info,
    LucideIcons.messageSquare,
    LucideIcons.user,
  ];

  @override
  Widget build(BuildContext context) {
    return M4BottomNav(
      icons: _icons,
      currentIndex: tabOrder.indexOf(currentIndex),
      onTap: (i) => onTap(tabOrder[i]),
    );
  }
}
