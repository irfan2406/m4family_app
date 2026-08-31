import 'package:flutter/material.dart';
import 'package:lucide_icons/lucide_icons.dart';
import 'package:m4_mobile/presentation/widgets/m4_bottom_nav.dart';

/// Web `InvestorBottomNav`: Home, Projects (compass), Support (message), Profile.
///
/// Rendering is [M4BottomNav] — identical to every other portal's bar.
class InvestorBottomNav extends StatelessWidget {
  final int currentIndex;
  final ValueChanged<int> onTap;

  const InvestorBottomNav({
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
    return M4BottomNav(icons: _icons, currentIndex: currentIndex, onTap: onTap);
  }
}
