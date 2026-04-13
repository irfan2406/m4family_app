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
      backgroundColor: Colors.black,
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
      margin: const EdgeInsets.only(bottom: 40),
      padding: const EdgeInsets.all(10),
      decoration: BoxDecoration(
        color: Colors.black.withValues(alpha: 0.95),
        borderRadius: BorderRadius.circular(50),
        border: Border.all(color: Colors.white.withValues(alpha: 0.08)),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.4),
            blurRadius: 30,
            spreadRadius: 2,
            offset: const Offset(0, 10),
          )
        ],
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          _NavIcon(icon: LucideIcons.home, isActive: currentIndex == 0, onTap: () => onTap(0)),
          const SizedBox(width: 8),
          _NavIcon(icon: LucideIcons.layoutGrid, isActive: currentIndex == 1, onTap: () => onTap(1)),
          const SizedBox(width: 8),
          _NavIcon(icon: LucideIcons.info, isActive: currentIndex == 2, onTap: () => onTap(2)),
          const SizedBox(width: 8),
          _NavIcon(icon: LucideIcons.briefcase, isActive: currentIndex == 3, onTap: () => onTap(3)),
          const SizedBox(width: 8),
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
    return _ScaleButton(
      onTap: onTap,
      child: Container(
        width: 48,
        height: 48,
        decoration: BoxDecoration(
          color: isActive ? Colors.white : Colors.transparent,
          shape: BoxShape.circle,
          boxShadow: isActive ? [BoxShadow(color: Colors.white.withValues(alpha: 0.2), blurRadius: 10)] : [],
        ),
        child: Center(
          child: Icon(
            icon, 
            color: isActive ? Colors.black : Colors.white60, 
            size: 20
          ),
        ),
      ),
    );
  }
}

class _ScaleButton extends StatefulWidget {
  final Widget child;
  final VoidCallback onTap;
  const _ScaleButton({required this.child, required this.onTap});

  @override
  State<_ScaleButton> createState() => _ScaleButtonState();
}

class _ScaleButtonState extends State<_ScaleButton> with SingleTickerProviderStateMixin {
  late AnimationController _controller;
  late Animation<double> _scale;

  @override
  void initState() {
    super.initState();
    _controller = AnimationController(vsync: this, duration: const Duration(milliseconds: 100));
    _scale = Tween<double>(begin: 1.0, end: 0.95).animate(CurvedAnimation(parent: _controller, curve: Curves.easeInOut));
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTapDown: (_) => _controller.forward(),
      onTapUp: (_) => _controller.reverse(),
      onTapCancel: () => _controller.reverse(),
      onTap: widget.onTap,
      child: ScaleTransition(scale: _scale, child: widget.child),
    );
  }
}
