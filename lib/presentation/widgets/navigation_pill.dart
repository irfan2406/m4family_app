import 'package:flutter/material.dart';
import 'package:m4_mobile/core/theme/app_theme.dart';
import 'package:lucide_icons/lucide_icons.dart';
import 'package:flutter_animate/flutter_animate.dart';
import 'dart:ui';

class NavigationPill extends StatelessWidget {
  final int currentIndex;
  final Function(int) onTap;

  const NavigationPill({
    super.key,
    required this.currentIndex,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    return Container(
      margin: const EdgeInsets.symmetric(horizontal: 24, vertical: 30),
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(35),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(isDark ? 0.4 : 0.08),
            blurRadius: 30,
            offset: const Offset(0, 15),
          ),
        ],
      ),
      child: ClipRRect(
        borderRadius: BorderRadius.circular(35),
        child: BackdropFilter(
          filter: ImageFilter.blur(sigmaX: 30, sigmaY: 30),
          child: Container(
            height: 70,
            padding: const EdgeInsets.symmetric(horizontal: 25),
            decoration: BoxDecoration(
              // Frosted glass: translucent deep-green on the green screens,
              // translucent white on the cream screens. Icons stay crisp.
              // Follow the surface behind the pill (deep-green on the showcase
              // screens, navy in dark mode) instead of a hardcoded navy, so the
              // frosted glass matches every portal's background.
              color: isDark
                  ? Theme.of(context).scaffoldBackgroundColor.withOpacity(0.5)
                  : Theme.of(context).scaffoldBackgroundColor.withOpacity(0.62),
              borderRadius: BorderRadius.circular(35),
              border: Border.all(
                color: (isDark ? M4Theme.cream : M4Theme.deepGreen)
                    .withOpacity(isDark ? 0.14 : 0.28),
                width: 1,
              ),
            ),
            child: Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                _NavItem(
                  icon: LucideIcons.home,
                  isActive: currentIndex == 0,
                  onTap: () => onTap(0),
                ),
                _NavItem(
                  icon: LucideIcons.compass,
                  isActive: currentIndex == 1,
                  onTap: () => onTap(1),
                ),
                _NavItem(
                  icon: LucideIcons.messageSquare,
                  isActive: currentIndex == 2,
                  onTap: () => onTap(2),
                ),
                _NavItem(
                  icon: LucideIcons.user,
                  isActive: currentIndex == 3,
                  onTap: () => onTap(3),
                ),
              ],
            ),
          ),
        ),
      ),
    ).animate().slideY(
      begin: 1.0,
      end: 0,
      duration: 600.ms,
      curve: Curves.easeOutBack,
    );
  }
}

class _NavItem extends StatelessWidget {
  final IconData icon;
  final bool isActive;
  final VoidCallback onTap;

  const _NavItem({
    required this.icon,
    required this.isActive,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    // Active: green circle on cream / white circle on green (reference);
    // inactive: the opposite tone, dimmed but legible on the frosted glass.
    final activeCircle = isDark ? M4Theme.cream : M4Theme.midGreen;
    final activeIcon = isDark ? M4Theme.navyBackground : M4Theme.cream;
    final inactiveIcon = isDark
        ? M4Theme.cream.withOpacity(0.75)
        : M4Theme.deepGreen.withOpacity(0.9);
    return GestureDetector(
      onTap: onTap,
      behavior: HitTestBehavior.opaque,
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        mainAxisSize: MainAxisSize.min,
        children: [
          Container(
            padding: const EdgeInsets.all(9),
            decoration: BoxDecoration(
              shape: BoxShape.circle,
              color: isActive ? activeCircle : Colors.transparent,
            ),
            child: Icon(
              icon,
              color: isActive ? activeIcon : inactiveIcon,
              size: 22,
            ),
          ),
        ],
      ),
    );
  }
}
