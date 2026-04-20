import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:m4_mobile/presentation/providers/cp_shell_provider.dart';
import 'package:m4_mobile/presentation/screens/cp/cp_home_screen.dart';
import 'package:m4_mobile/presentation/screens/cp/cp_profile_screen.dart';
import 'package:m4_mobile/presentation/screens/projects/project_list_screen.dart';
import 'package:m4_mobile/presentation/screens/cp/cp_dashboard_screen.dart';
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

    final screens = [
      const CpHomeScreen(),
      const CpDashboardScreen(embeddedInShell: true),
      const CpTrackerScreen(embeddedInShell: true),
      const ProjectListScreen(cpCatalogMode: true),
      const SupportScreen(),
      const CpProfileScreen(),
    ];

    return Scaffold(
      drawer: const CpSidebarMenu(),
      body: IndexedStack(
        index: idx,
        children: screens,
      ),
      bottomNavigationBar: CpBottomNav(
        currentIndex: idx,
        onTap: (i) => ref.read(cpNavigationIndexProvider.notifier).state = i,
      ),
    );
  }
}
