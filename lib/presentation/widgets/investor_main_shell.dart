import 'package:flutter/material.dart';
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

    final screens = [
      const InvestorHomeScreen(),
      const ProjectListScreen(),
      const SupportScreen(),
      const InvestorProfileScreen(),
    ];

    return Scaffold(
      drawer: const InvestorSidebarMenu(),
      body: IndexedStack(
        index: idx,
        children: screens,
      ),
      bottomNavigationBar: InvestorBottomNav(
        currentIndex: idx,
        onTap: (i) => ref.read(investorNavigationIndexProvider.notifier).state = i,
      ),
    );
  }
}
