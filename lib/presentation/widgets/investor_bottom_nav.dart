import 'package:m4_mobile/presentation/widgets/nav_style.dart';
import 'dart:ui';

import 'package:flutter/material.dart';
import 'package:lucide_icons/lucide_icons.dart';

/// Web `InvestorBottomNav`: Home, Projects (compass), Support (message), Profile (4 tabs).
/// Styling mirrors [CpBottomNav].
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
    final isDark = Theme.of(context).brightness == Brightness.dark;
    // The pill is green on the showcase tabs and cream on the light ones, so
    // the glyphs invert to keep contrast on whichever surface they sit on.
    final navIcon = isDark
        ? const Color(0xFFF4EFE3)
        : const Color(0xFF163A2C);
    final activeDisc = isDark
        ? const Color(0xFFF4EFE3)
        : const Color(0xFF0C312B);
    final activeGlyph = isDark
        ? const Color(0xFF0C312B)
        : const Color(0xFFF4EFE3);

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
                  borderRadius: BorderRadius.circular(M4Nav.radius),
                  // Frosted tint follows the page: deep green on the showcase tabs, cream
                  // on the light ones. Cream over the greige page keeps the bar visibly
                  // lighter than what is behind it, so it still reads as glass.
                  gradient: LinearGradient(
                    begin: Alignment.topCenter,
                    end: Alignment.bottomCenter,
                    colors: isDark
                        ? [
                            Color.alphaBlend(
                              Colors.white.withValues(alpha: 0.16),
                              const Color(0xFF0C312B).withValues(alpha: 0.62),
                            ),
                            const Color(0xFF0C312B).withValues(alpha: M4Nav.inactiveOpacity),
                          ]
                        : [
                            const Color(0xFFF4EFE3).withValues(alpha: 0.82),
                            const Color(0xFFF4EFE3).withValues(alpha: 0.68),
                          ],
                  ),
                  border: Border.all(
                    color: Colors.white.withValues(alpha: 0.16),
                    width: 0.8,
                  ),
                  boxShadow: M4Nav.shadow(isDark),
                ),
              child: Row(
                mainAxisAlignment: MainAxisAlignment.spaceEvenly,
                children: List.generate(_icons.length, (i) {
                  final active = currentIndex == i;
                  final onSurf = Theme.of(context).colorScheme.onSurface;
                  return InkWell(
                    onTap: () => onTap(i),
                    borderRadius: BorderRadius.circular(14),
                    child: Padding(
                      padding: const EdgeInsets.symmetric(
                        horizontal: 6,
                        vertical: 6,
                      ),
                      child: Column(
                        mainAxisAlignment: MainAxisAlignment.center,
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          // Figma: the selected tab is a solid deep-green disc with a cream
                          // glyph; unselected tabs are the bare icon on the glass.
                          AnimatedContainer(
                            duration: M4Nav.animation,
                            curve: M4Nav.curve,
                            padding: const EdgeInsets.all(9),
                            decoration: BoxDecoration(
                              shape: BoxShape.circle,
                              color: active ? activeDisc : Colors.transparent,
                            ),
                            child: Icon(
                              _icons[i],
                              size: M4Nav.iconSize,
                              color: active
                                  ? activeGlyph
                                  : navIcon.withValues(alpha: M4Nav.inactiveOpacity),
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
                              color: active ? onSurf : Colors.transparent,
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
