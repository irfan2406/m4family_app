import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import 'package:m4_mobile/presentation/providers/auth_provider.dart';
import 'package:m4_mobile/presentation/providers/cp_shell_provider.dart';
import 'package:m4_mobile/presentation/providers/investor_shell_provider.dart';
import 'package:m4_mobile/presentation/widgets/cp_bottom_nav.dart';
import 'package:m4_mobile/presentation/widgets/guest_main_shell.dart';
import 'package:m4_mobile/presentation/widgets/investor_bottom_nav.dart';
import 'package:m4_mobile/presentation/widgets/m4_bottom_nav.dart';
import 'package:m4_mobile/presentation/widgets/main_shell.dart';
import 'package:m4_mobile/presentation/widgets/navigation_pill.dart';

/// The bottom nav belonging to the signed-in account's portal.
///
/// Screens pushed out of a shell — the Support Hub's destinations, WHO WE ARE,
/// the booking flows — each drew the customer [NavigationPill] regardless of
/// which portal opened them, and its taps set [navigationProvider], the
/// CUSTOMER shell's index. So a Channel Partner who tapped it was carried into
/// another portal, and the bar itself was visibly the wrong one (four icons
/// instead of CP's five).
///
/// This picks the nav — and the shell index it drives — from the account's
/// role, so a pushed screen keeps the portal it was opened from.
class PortalBottomNav extends ConsumerWidget {
  const PortalBottomNav({super.key, this.currentIndex = -1});

  /// -1 leaves every tab unselected, which is what a pushed screen wants: it
  /// is not one of the shell's tabs.
  final int currentIndex;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final signedIn = ref.watch(
      authProvider.select((s) => s.status == AuthStatus.authenticated),
    );
    final role = ref.watch(
      authProvider.select(
        (s) => s.user?['role']?.toString().toLowerCase() ?? '',
      ),
    );

    void goToTab(StateProvider<int> shellIndex, int i) {
      ref.read(shellIndex.notifier).state = i;
      Navigator.of(context).popUntil((r) => r.isFirst);
    }

    // A visitor has no role at all, so this has to come before the switch —
    // otherwise guest fell through to the customer pill.
    if (!signedIn) {
      return M4BottomNav(
        icons: guestNavIcons,
        currentIndex: currentIndex,
        onTap: (i) => goToTab(guestNavigationProvider, i),
      );
    }

    switch (role) {
      case 'cp':
        return CpBottomNav(
          currentIndex: currentIndex,
          onTap: (i) => goToTab(cpNavigationIndexProvider, i),
        );
      case 'investor':
        return InvestorBottomNav(
          currentIndex: currentIndex,
          onTap: (i) => goToTab(investorNavigationIndexProvider, i),
        );
      default:
        return NavigationPill(
          currentIndex: currentIndex,
          onTap: (i) => goToTab(navigationProvider, i),
        );
    }
  }
}
