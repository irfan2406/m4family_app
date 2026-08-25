import 'package:m4_mobile/presentation/widgets/nav_swipe.dart';
import 'package:flutter/material.dart';
import 'package:m4_mobile/core/theme/app_theme.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:m4_mobile/presentation/providers/investor_shell_provider.dart';
import 'package:m4_mobile/presentation/screens/investor/investor_home_screen.dart';
import 'package:m4_mobile/presentation/screens/investor/investor_profile_screen.dart';
import 'package:m4_mobile/presentation/screens/projects/project_list_screen.dart';
import 'package:m4_mobile/presentation/screens/support/support_screen.dart';
import 'package:m4_mobile/presentation/widgets/investor_bottom_nav.dart';
import 'package:m4_mobile/presentation/widgets/investor_sidebar_menu.dart';

/// Investor shell: web `InvestorBottomNav` + `InvestorSidebar` (drawer).
/// Tabs: 0 Home, 1 Projects, 2 Support, 3 Profile.
class InvestorMainShell extends ConsumerWidget {
  const InvestorMainShell({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final idx = ref.watch(investorNavigationIndexProvider);

    // Home (0) & Projects (1) are the deep-green "showcase" screens (white
    // typography); Support/Profile stay cream with green typography.
    Widget showcase(Widget child) =>
        Theme(data: M4Theme.darkTheme, child: child);

    final screens = [
      showcase(const InvestorHomeScreen()),
      showcase(const ProjectListScreen()),
      const SupportScreen(),
      const InvestorProfileScreen(),
    ];

    // Nav + scaffold follow the active tab's surface.
    final ThemeData navTheme = (idx == 0 || idx == 1)
              ? M4Theme.darkTheme
              // Investor light tabs sit on a deeper warm greige than the other
              // portals' cream, so the cream cards read as raised surfaces.
              : M4Theme.lightTheme.copyWith(
                  scaffoldBackgroundColor: const Color(0xFFD4CFBC),
                );

    return Scaffold(
      backgroundColor: navTheme.scaffoldBackgroundColor,
      drawer: const InvestorSidebarMenu(),
      // No extendBody: Scaffold reserves the pill's slot so page content stops
      // above it. With it enabled the last element — the white SUBMIT INTEREST
      // button on Home — slid under the bar, and the glass blur picked up that
      // white, washing the green pill out to a pale grey-green.
      extendBody: false,
      // Horizontal fling moves a tab. It sets the same provider the bottom
      // bar sets, so no second navigation path is introduced.
      body: NavSwipe(
        index: idx,
        count: screens.length,
        onIndexChanged: (i) =>
            ref.read(investorNavigationIndexProvider.notifier).state = i,
        child: IndexedStack(index: idx, children: screens),
      ),
      bottomNavigationBar: Theme(
        data: navTheme,
        child: InvestorBottomNav(
          currentIndex: idx,
          onTap: (i) =>
              ref.read(investorNavigationIndexProvider.notifier).state = i,
        ),
      ),
    );
  }
}
