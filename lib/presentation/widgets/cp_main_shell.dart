import 'package:flutter/material.dart';
import 'package:m4_mobile/core/theme/app_theme.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:m4_mobile/presentation/providers/cp_shell_provider.dart';
import 'package:m4_mobile/presentation/screens/cp/cp_home_screen.dart';
import 'package:m4_mobile/presentation/screens/cp/cp_profile_screen.dart';
import 'package:m4_mobile/presentation/screens/projects/project_list_screen.dart';
import 'package:m4_mobile/presentation/screens/cp/cp_tracker_screen.dart';
import 'package:m4_mobile/presentation/screens/support/support_screen.dart';
import 'package:m4_mobile/presentation/widgets/cp_bottom_nav.dart';
import 'package:m4_mobile/presentation/widgets/cp_sidebar_menu.dart';

/// Channel Partner shell: web `CPBottomNav` + `CPSidebar` (drawer).
class CpMainShell extends ConsumerWidget {
  const CpMainShell({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final idx = ref.watch(cpNavigationIndexProvider);

    final bool appIsDark = Theme.of(context).brightness == Brightness.dark;

    // Home (0) & Projects (2) are the deep-green "showcase" screens in LIGHT
    // mode (white typography); the rest stay cream with green typography. In
    // DARK mode everything inherits the navy theme.
    Widget showcase(Widget child) => appIsDark
        ? child
        : Theme(data: M4Theme.darkTheme, child: child);

    // 5 tabs matching web AppShell CP bar: Home, Tracker, Projects, Support, Profile.
    final screens = [
      showcase(const CpHomeScreen()),
      const CpTrackerScreen(embeddedInShell: true),
      showcase(const ProjectListScreen(cpCatalogMode: true)),
      const SupportScreen(),
      const CpProfileScreen(),
    ];

    // Nav + scaffold follow the active tab's surface.
    final ThemeData navTheme = appIsDark
        ? M4Theme.darkThemeNavy
        : ((idx == 0 || idx == 2) ? M4Theme.darkTheme : M4Theme.lightTheme);

    return Scaffold(
      backgroundColor: navTheme.scaffoldBackgroundColor,
      drawer: const CpSidebarMenu(),
      body: IndexedStack(index: idx, children: screens),
      bottomNavigationBar: Theme(
        data: navTheme,
        child: CpBottomNav(
          currentIndex: idx,
          onTap: (i) => ref.read(cpNavigationIndexProvider.notifier).state = i,
        ),
      ),
    );
  }
}
