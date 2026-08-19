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

    final bool appIsDark = Theme.of(context).brightness == Brightness.dark;

    // Home (0) & Projects (1) are the deep-green "showcase" screens in LIGHT
    // mode (white typography); Support/Profile stay cream with green
    // typography. In DARK mode everything inherits the navy theme.
    Widget showcase(Widget child) => appIsDark
        ? child
        : Theme(data: M4Theme.darkTheme, child: child);

    final screens = [
      showcase(const InvestorHomeScreen()),
      showcase(const ProjectListScreen()),
      const SupportScreen(),
      const InvestorProfileScreen(),
    ];

    // Nav + scaffold follow the active tab's surface.
    final ThemeData navTheme = appIsDark
        ? M4Theme.darkThemeNavy
        : ((idx == 0 || idx == 1)
              ? M4Theme.darkTheme
              // Investor light tabs sit on a deeper warm greige than the other
              // portals' cream, so the cream cards read as raised surfaces.
              : M4Theme.lightTheme.copyWith(
                  scaffoldBackgroundColor: const Color(0xFFD4CFBC),
                ));

    return Scaffold(
      backgroundColor: navTheme.scaffoldBackgroundColor,
      drawer: const InvestorSidebarMenu(),
      body: IndexedStack(index: idx, children: screens),
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
