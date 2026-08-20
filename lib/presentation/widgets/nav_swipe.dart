import 'package:flutter/material.dart';

import 'nav_style.dart';

/// Wraps a shell body so a horizontal fling moves to the next/previous tab.
///
/// This adds no navigation of its own: it calls back with the new index and the
/// shell sets the same provider its bottom bar already sets, so routes, deep
/// links and back behaviour are untouched.
///
/// The gesture only fires when nothing else claimed it. Horizontal carousels
/// and scrollables win the arena first, and a fling must clear
/// [M4Nav.swipeVelocity] before it counts, so ordinary scrolling is never
/// hijacked.
class NavSwipe extends StatelessWidget {
  const NavSwipe({
    super.key,
    required this.index,
    required this.count,
    required this.onIndexChanged,
    required this.child,
  });

  final int index;
  final int count;
  final ValueChanged<int> onIndexChanged;
  final Widget child;

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      behavior: HitTestBehavior.translucent,
      onHorizontalDragEnd: (details) {
        final v = details.primaryVelocity ?? 0;
        if (v.abs() < M4Nav.swipeVelocity) return;
        // Swipe left (negative velocity) advances a tab; right goes back.
        final next = v < 0 ? index + 1 : index - 1;
        if (next < 0 || next >= count || next == index) return;
        onIndexChanged(next);
      },
      child: child,
    );
  }
}
