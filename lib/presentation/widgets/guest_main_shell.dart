import 'package:flutter/material.dart';
import 'package:m4_mobile/presentation/screens/home/guest_dashboard_screen.dart';
import 'package:m4_mobile/presentation/screens/projects/project_list_screen.dart';
import 'package:m4_mobile/presentation/screens/about/about_screen.dart';
import 'package:m4_mobile/presentation/screens/careers/careers_screen.dart';
import 'package:m4_mobile/presentation/screens/support/support_screen.dart';
import 'package:m4_mobile/presentation/widgets/conditional_drawer.dart';
import 'package:m4_mobile/presentation/widgets/navigation_pill.dart';
import 'package:lucide_icons/lucide_icons.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

final guestNavigationProvider = StateProvider<int>((ref) => 0);

class GuestMainShell extends ConsumerWidget {
  const GuestMainShell({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final currentIndex = ref.watch(guestNavigationProvider);

    final List<Widget> screens = [
      const GuestDashboardScreen(), // 0: Home
      const ProjectListScreen(),   // 1: Projects
      const AboutScreen(),         // 2: About
      const CareersScreen(),       // 3: Careers
      const SupportScreen(),       // 4: Support
    ];

    return Scaffold(
      drawer: const ConditionalDrawer(),
      body: Stack(
        children: [
          IndexedStack(
            index: currentIndex,
            children: screens,
          ),
          Align(
            alignment: Alignment.bottomCenter,
            child: _GuestNavigationPill(
              currentIndex: currentIndex,
              onTap: (index) => ref.read(guestNavigationProvider.notifier).state = index,
            ),
          ),
        ],
      ),
    );
  }
}

class _GuestNavigationPill extends StatelessWidget {
  final int currentIndex;
  final Function(int) onTap;

  const _GuestNavigationPill({required this.currentIndex, required this.onTap});

  @override
  Widget build(BuildContext context) {
    return Container(
      margin: const EdgeInsets.only(bottom: 30),
      padding: const EdgeInsets.all(8),
      decoration: BoxDecoration(
        color: Colors.black.withOpacity(0.8),
        borderRadius: BorderRadius.circular(40),
        border: Border.all(color: Colors.white.withOpacity(0.1)),
        boxShadow: [BoxShadow(color: Colors.black.withOpacity(0.5), blurRadius: 20, spreadRadius: 5)],
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          _NavIcon(icon: LucideIcons.home, isActive: currentIndex == 0, onTap: () => onTap(0)),
          _NavIcon(icon: LucideIcons.building2, isActive: currentIndex == 1, onTap: () => onTap(1)),
          _NavIcon(icon: LucideIcons.info, isActive: currentIndex == 2, onTap: () => onTap(2)),
          _NavIcon(icon: LucideIcons.briefcase, isActive: currentIndex == 3, onTap: () => onTap(3)),
          _NavIcon(icon: LucideIcons.phone, isActive: currentIndex == 4, onTap: () => onTap(4)),
        ],
      ),
    );
  }
}

class _NavIcon extends StatelessWidget {
  final IconData icon;
  final bool isActive;
  final VoidCallback onTap;

  const _NavIcon({required this.icon, required this.isActive, required this.onTap});

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        padding: const EdgeInsets.all(12),
        decoration: BoxDecoration(
          color: isActive ? Colors.white : Colors.transparent,
          shape: BoxShape.circle,
        ),
        child: Icon(icon, color: isActive ? Colors.black : Colors.white60, size: 20),
      ),
    );
  }
}
