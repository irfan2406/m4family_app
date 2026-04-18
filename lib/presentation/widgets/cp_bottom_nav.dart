import 'dart:ui';

import 'package:flutter/material.dart';
import 'package:lucide_icons/lucide_icons.dart';

/// Web CP mobile mockup: Home, Dashboard, Performance, Hub, Support, Profile (6 tabs).
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
    LucideIcons.layoutGrid,
    LucideIcons.barChart3,
    LucideIcons.compass,
    LucideIcons.messageSquare,
    LucideIcons.user,
  ];

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final surface = isDark
        ? Colors.white.withValues(alpha: 0.08)
        : Colors.white.withValues(alpha: 0.95);
    final border = (isDark ? Colors.white : Colors.black).withValues(alpha: 0.08);

    return SafeArea(
      top: false,
      child: Padding(
        padding: const EdgeInsets.fromLTRB(16, 0, 16, 20),
        child: ClipRRect(
          borderRadius: BorderRadius.circular(40),
          child: BackdropFilter(
            filter: ImageFilter.blur(sigmaX: 20, sigmaY: 20),
            child: Container(
              height: 74,
              padding: const EdgeInsets.symmetric(horizontal: 8),
              decoration: BoxDecoration(
                color: surface,
                borderRadius: BorderRadius.circular(40),
                border: Border.all(color: border),
                boxShadow: [
                  BoxShadow(
                    color: Colors.black.withValues(alpha: isDark ? 0.35 : 0.1),
                    blurRadius: 28,
                    offset: const Offset(0, 14),
                  ),
                ],
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
                      padding: const EdgeInsets.symmetric(horizontal: 2, vertical: 10),
                      child: Column(
                        mainAxisAlignment: MainAxisAlignment.center,
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          Container(
                            padding: const EdgeInsets.all(8),
                            decoration: BoxDecoration(
                              borderRadius: BorderRadius.circular(14),
                              color: active
                                  ? onSurf.withValues(alpha: isDark ? 0.12 : 0.08)
                                  : null,
                              border: active
                                  ? Border.all(color: onSurf.withValues(alpha: 0.12))
                                  : null,
                            ),
                            child: Icon(
                              _icons[i],
                              size: 22,
                              color: active ? onSurf : onSurf.withValues(alpha: 0.38),
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
