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
    // Nav icons carry the brand: forest green on the cream surfaces, cream
    // on navy, instead of a washed-out 38% grey.
    final navIcon = isDark ? const Color(0xFFF4EFE3) : const Color(0xFF163A2C);

    return SafeArea(
      top: false,
      child: Padding(
        padding: const EdgeInsets.fromLTRB(36, 0, 36, 24),
        child: ClipRRect(
          borderRadius: BorderRadius.circular(40),
          child: BackdropFilter(
            filter: ImageFilter.blur(sigmaX: 32, sigmaY: 32),
            child: Container(
              height: 62,
              padding: const EdgeInsets.symmetric(horizontal: 8),
                decoration: BoxDecoration(
                  borderRadius: BorderRadius.circular(40),
                  // Pure glass: no colour tint at all - just a faint white sheen over
                  // the blur, so whatever is behind shows through in its own colour
                  // rather than being washed navy.
                  gradient: LinearGradient(
                    begin: Alignment.topCenter,
                    end: Alignment.bottomCenter,
                    colors: [
                      Colors.white.withValues(alpha: isDark ? 0.14 : 0.20),
                      Colors.white.withValues(alpha: isDark ? 0.05 : 0.08),
                    ],
                  ),
                  border: Border.all(
                    color: Colors.white.withValues(alpha: isDark ? 0.18 : 0.28),
                    width: 0.8,
                  ),
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
                          Container(
                            padding: const EdgeInsets.all(9),
                            decoration: BoxDecoration(
                              shape: BoxShape.circle,
                              color: active ? const Color(0xFF0F2A20) : Colors.transparent,
                            ),
                            child: Icon(
                              _icons[i],
                              size: 22,
                              color: active
                                  ? const Color(0xFFF4EFE3)
                                  : navIcon.withValues(alpha: 0.72),
                            ),
                          ),
                          const SizedBox(height: 4),
                          Container(
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
