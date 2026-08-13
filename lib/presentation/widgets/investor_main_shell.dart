import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:m4_mobile/presentation/providers/investor_shell_provider.dart';
import 'package:m4_mobile/presentation/screens/investor/investor_home_screen.dart';
import 'package:m4_mobile/presentation/screens/investor/investor_profile_screen.dart';
import 'package:m4_mobile/presentation/screens/projects/project_list_screen.dart';
import 'package:m4_mobile/presentation/screens/support/support_screen.dart';
import 'package:m4_mobile/presentation/widgets/investor_bottom_nav.dart';
import 'package:m4_mobile/presentation/widgets/investor_sidebar_menu.dart';
import 'package:m4_mobile/core/theme/app_theme.dart';

/// Investor shell: web `InvestorBottomNav` + `InvestorSidebar` (drawer).
/// Tabs: 0 Home, 1 Projects, 2 Support, 3 Profile.
class InvestorMainShell extends ConsumerWidget {
  const InvestorMainShell({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final idx = ref.watch(investorNavigationIndexProvider);
    final bool appIsDark = Theme.of(context).brightness == Brightness.dark;

    // Match the GUEST portal: Home (0) and Projects (1) are the deep-green
    // "showcase" screens in LIGHT mode (navy in dark); the other tabs follow
    // the app theme (cream in light).
    Widget showcase(Widget child) => appIsDark
        ? child
        : Theme(data: M4Theme.darkTheme, child: child);

    final screens = [
      showcase(const InvestorHomeScreen()),
      showcase(const ProjectListScreen()),
      const SupportScreen(),
      const InvestorProfileScreen(),
    ];

    // Nav-pill surface: navy in dark; green on the showcase tabs, cream on the
    // rest in light — same rule as the guest nav.
    final ThemeData navTheme = appIsDark
        ? M4Theme.darkThemeNavy
        : ((idx == 0 || idx == 1) ? M4Theme.darkTheme : M4Theme.lightTheme);

    return Scaffold(
      backgroundColor: navTheme.scaffoldBackgroundColor,
      drawer: const InvestorSidebarMenu(),
      body: IndexedStack(
        index: idx,
        children: screens,
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
