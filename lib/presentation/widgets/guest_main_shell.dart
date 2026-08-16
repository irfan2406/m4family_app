import 'dart:ui';
import 'package:flutter/material.dart';
import 'package:m4_mobile/core/theme/app_theme.dart';
import 'package:m4_mobile/presentation/screens/home/guest_dashboard_screen.dart';
import 'package:m4_mobile/presentation/screens/projects/project_list_screen.dart';
import 'package:m4_mobile/presentation/screens/about/about_screen.dart';
import 'package:m4_mobile/presentation/screens/careers/careers_screen.dart';
import 'package:m4_mobile/presentation/screens/support/support_screen.dart';
import 'package:m4_mobile/presentation/screens/support/contact_screen.dart';
import 'package:m4_mobile/presentation/widgets/conditional_drawer.dart';
import 'package:m4_mobile/presentation/widgets/navigation_pill.dart';
import 'package:lucide_icons/lucide_icons.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

final guestNavigationProvider = StateProvider<int>((ref) => 0);
final drawerOpenProvider = StateProvider<bool>((ref) => false);

class GuestMainShell extends ConsumerWidget {
  const GuestMainShell({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final currentIndex = ref.watch(guestNavigationProvider);
    final isDrawerOpen = ref.watch(drawerOpenProvider);

    final bool appIsDark = Theme.of(context).brightness == Brightness.dark;

    // LIGHT mode: Home (0) & Properties (1) keep the GREEN showcase look
    // (Figma frames 1 & 4) — unchanged. DARK mode: they inherit the app's
    // navy theme like every other section, so dark mode is navy everywhere.
    Widget showcase(Widget child) => appIsDark
        ? child // dark → inherit the app's navy theme
        : Theme(data: M4Theme.darkTheme, child: child); // light → green

    final List<Widget> screens = [
      showcase(const GuestDashboardScreen()), // 0: Home     — green / navy
      showcase(const ProjectListScreen()),    // 1: Projects  — green / navy
      const AboutScreen(),                    // 2: About     — cream / navy
      const CareersScreen(),                  // 3: Careers   — cream / navy
      const ContactScreen(),                  // 4: Contact   — cream / navy
    ];

    // Nav-pill surface: navy in dark mode (all tabs); in light mode green on
    // the showcase tabs and cream on the info tabs.
    final ThemeData pillTheme = appIsDark
        ? M4Theme.darkThemeNavy
        : (currentIndex <= 1 ? M4Theme.darkTheme : M4Theme.lightTheme);

    return Scaffold(
      backgroundColor: Theme.of(context).scaffoldBackgroundColor,
      drawer: const ConditionalDrawer(),
      onDrawerChanged: (isOpen) => ref.read(drawerOpenProvider.notifier).state = isOpen,
      body: Stack(
        children: [
          IndexedStack(
            index: currentIndex,
            children: screens,
          ),
          if (!isDrawerOpen)
            Align(
              alignment: Alignment.bottomCenter,
              child: Theme(
                data: pillTheme,
                child: _GuestNavigationPill(
                  currentIndex: currentIndex,
                  onTap: (index) =>
                      ref.read(guestNavigationProvider.notifier).state = index,
                ),
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
    final isDark = Theme.of(context).brightness == Brightness.dark;
    return Container(
      margin: const EdgeInsets.only(bottom: 48),
      decoration: const BoxDecoration(
        borderRadius: BorderRadius.all(Radius.circular(100)),
      ),
      // Frosted-glass pill: the blur only affects the content BEHIND the bar;
      // the icons sit on top and stay perfectly crisp.
      child: ClipRRect(
        borderRadius: BorderRadius.circular(100),
        child: BackdropFilter(
          filter: ImageFilter.blur(sigmaX: 30, sigmaY: 30),
          child: Container(
            padding: const EdgeInsets.all(10),
            decoration: BoxDecoration(
              // Frosted glass follows the surface: green on the green light
              // screens, navy in dark mode, white on the cream screens.
              color: isDark
                  ? Theme.of(context).scaffoldBackgroundColor.withOpacity(0.5)
                  : Colors.white.withOpacity(0.6),
              borderRadius: BorderRadius.circular(100),
              border: Border.all(
                color: (isDark ? M4Theme.cream : M4Theme.deepGreen)
                    .withOpacity(0.14),
              ),
            ),
            child: Row(
              mainAxisSize: MainAxisSize.min,
              children: [
                _NavIcon(icon: LucideIcons.home, isActive: currentIndex == 0, onTap: () => onTap(0)),
                const SizedBox(width: 12),
                _NavIcon(icon: LucideIcons.building2, isActive: currentIndex == 1, onTap: () => onTap(1)),
                const SizedBox(width: 12),
                _NavIcon(icon: LucideIcons.info, isActive: currentIndex == 2, onTap: () => onTap(2)),
                const SizedBox(width: 12),
                _NavIcon(icon: LucideIcons.briefcase, isActive: currentIndex == 3, onTap: () => onTap(3)),
                const SizedBox(width: 12),
                _NavIcon(icon: LucideIcons.headphones, isActive: currentIndex == 4, onTap: () => onTap(4)),
              ],
            ),
          ),
        ),
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
    final isDark = Theme.of(context).brightness == Brightness.dark;
    // Reference: the active tab is a solid green circle on the cream screens
    // and a solid white circle on the green screens; inactive icons are the
    // opposite tone, dimmed, but still clearly legible on the frosted glass.
    final activeCircle = isDark ? M4Theme.cream : M4Theme.midGreen;
    final activeIcon = isDark ? M4Theme.navyBackground : M4Theme.cream;
    final inactiveIcon = isDark
        ? M4Theme.cream.withOpacity(0.75)
        : M4Theme.deepGreen.withOpacity(0.72);
    return _ScaleButton(
      onTap: onTap,
      child: Container(
        width: 56,
        height: 56,
        decoration: BoxDecoration(
          color: isActive ? activeCircle : Colors.transparent,
          shape: BoxShape.circle,
          boxShadow: isActive
              ? [BoxShadow(color: activeCircle.withOpacity(0.3), blurRadius: 12)]
              : [],
        ),
        child: Center(
          child: Icon(
            icon,
            color: isActive ? activeIcon : inactiveIcon,
            size: 24,
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
