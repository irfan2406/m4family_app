import 'package:flutter/material.dart';
import 'package:lucide_icons/lucide_icons.dart';
import 'package:m4_mobile/presentation/widgets/m4_bottom_nav.dart';

/// Web `AppShell` CP bar: Home, Tracker, Projects (compass), Who We Are,
/// Support, Profile.
///
/// Rendering is [M4BottomNav] — identical to every other portal's bar.
///
/// [currentIndex] and [onTap] speak the CP shell's tab indices. WHO WE ARE is
/// the shell's tab [whoWeAreTab] but sits after Projects on the bar, so the
/// bar maps its positions to tabs with [tabOrder] — every existing tab keeps
/// its index.
class CpBottomNav extends StatelessWidget {
  final int currentIndex;
  final ValueChanged<int> onTap;

  const CpBottomNav({
    super.key,
    required this.currentIndex,
    required this.onTap,
  });

  /// The CP shell's WHO WE ARE tab.
  static const int whoWeAreTab = 5;

  /// The shell tab behind each bar position, left to right.
  static const List<int> tabOrder = [0, 1, 2, whoWeAreTab, 3, 4];

  static const _icons = <IconData>[
    LucideIcons.home,
    LucideIcons.barChart3,
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
