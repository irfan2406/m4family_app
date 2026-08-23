import 'package:m4_mobile/presentation/widgets/nav_style.dart';
import 'dart:ui';

import 'package:flutter/material.dart';
import 'package:lucide_icons/lucide_icons.dart';

/// Web `AppShell` CP bar: Home, Tracker, Projects (compass), Support, Profile (5 tabs).
class CpBottomNav extends StatelessWidget {
  final int currentIndex;
  final ValueChanged<int> onTap;

  const CpBottomNav({
    super.key,
    required this.currentIndex,
    required this.onTap,
  });

  static const _icons = <IconData>[
    LucideIcons.home,
    LucideIcons.barChart3,
    LucideIcons.compass,
    LucideIcons.messageSquare,
    LucideIcons.user,
  ];

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    // Frosted glass follows the surface: green on the green showcase screens,
    // navy in dark mode, translucent white on the cream screens. Icons stay crisp.
    final surface = isDark
        ? Theme.of(context).scaffoldBackgroundColor.withValues(alpha: 0.5)
        : Colors.white.withValues(alpha: 0.6);
    final border = (isDark ? const Color(0xFFF4EFE3) : const Color(0xFF0C312B))
        .withValues(alpha: 0.14);

    return SafeArea(
      bottom: false,
      top: false,
      child: Padding(
        padding: const EdgeInsets.fromLTRB(M4Nav.sideInset, 0, M4Nav.sideInset, M4Nav.bottomInset),
        child: ClipRRect(
          borderRadius: BorderRadius.circular(M4Nav.radius),
          child: BackdropFilter(
            filter: ImageFilter.blur(sigmaX: M4Nav.blur, sigmaY: M4Nav.blur),
            child: Container(
              height: M4Nav.height,
              padding: const EdgeInsets.symmetric(horizontal: 8),
              decoration: BoxDecoration(
                color: surface,
                borderRadius: BorderRadius.circular(M4Nav.radius),
                border: Border.all(color: border),
                boxShadow: M4Nav.shadow(isDark),
              ),
              child: Row(
                mainAxisAlignment: MainAxisAlignment.spaceEvenly,
                children: List.generate(_icons.length, (i) {
                  final active = currentIndex == i;
                  final onSurf = Theme.of(context).colorScheme.onSurface;
                  // Web parity: CPBottomNav uses text-primary, and the CP
                  // --primary is near-black navy (222 47% 6%), NOT purple — so
                  // the active tab is DARK (onSurface), inactive is muted.
                  final purple = onSurf;
                  return InkWell(
                    onTap: () => onTap(i),
                    borderRadius: BorderRadius.circular(14),
                    child: Padding(
                      // No vertical padding: the taller disc plus its dot
                      // already fills the 64px bar.
                      padding: const EdgeInsets.symmetric(
                        horizontal: 2,
                        vertical: 0,
                      ),
                      child: Column(
                        mainAxisAlignment: MainAxisAlignment.center,
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          AnimatedContainer(
                            duration: M4Nav.animation,
                            curve: M4Nav.curve,
                            padding: const EdgeInsets.all(13),
                            decoration: BoxDecoration(
                              borderRadius: BorderRadius.circular(14),
                              color: active
                                  ? purple.withValues(alpha: 0.12)
                                  : null,
                              border: active
                                  ? Border.all(
                                      color: purple.withValues(alpha: 0.25),
                                    )
                                  : null,
                            ),
                            child: Icon(
                              _icons[i],
                              size: M4Nav.iconSize,
                              color: active
                                  ? purple
                                  : onSurf.withValues(alpha: 0.5),
                            ),
                          ),
                          const SizedBox(height: 4),
                          AnimatedContainer(
                            duration: M4Nav.animation,
                            curve: M4Nav.curve,
                            width: 4,
                            height: 4,
                            decoration: BoxDecoration(
                              shape: BoxShape.circle,
                              color: active ? purple : Colors.transparent,
                            ),
                          ),
                        ],
                      ),
                    ),
                  );
                }),
              ),
            ),
          ),
        ),
      ),
    );
  }
}
