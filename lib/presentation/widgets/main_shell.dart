import 'package:flutter/material.dart';
import 'package:m4_mobile/presentation/screens/home/dashboard_screen.dart';
import 'package:m4_mobile/presentation/screens/projects/project_list_screen.dart';
import 'package:m4_mobile/presentation/widgets/navigation_pill.dart';
import 'package:m4_mobile/presentation/widgets/sidebar_menu.dart';

import 'package:flutter_riverpod/flutter_riverpod.dart';

final navigationProvider = StateProvider<int>((ref) => 0);

class MainShell extends ConsumerStatefulWidget {
  const MainShell({super.key});

  @override
  ConsumerState<MainShell> createState() => _MainShellState();
}

class _MainShellState extends ConsumerState<MainShell> {

  final List<Widget> _screens = [
    const DashboardScreen(),
    const ProjectListScreen(),
    const PlaceholderScreen(title: 'Support'),
    const PlaceholderScreen(title: 'Profile'),
];

  @override
  Widget build(BuildContext context) {
    final currentIndex = ref.watch(navigationProvider);
    
    return Scaffold(
      drawer: const SidebarMenu(),
      body: Stack(
        children: [
          IndexedStack(
            index: currentIndex,
            children: _screens,
          ),
          Align(
            alignment: Alignment.bottomCenter,
            child: NavigationPill(
              currentIndex: currentIndex,
              onTap: (index) {
                ref.read(navigationProvider.notifier).state = index;
              },
            ),
          ),
        ],
      ),
    );
  }
}

class PlaceholderScreen extends StatelessWidget {
  final String title;
  const PlaceholderScreen({super.key, required this.title});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: Text(title)),
      body: Center(child: Text('Coming Soon: $title')),
    );
  }
}
