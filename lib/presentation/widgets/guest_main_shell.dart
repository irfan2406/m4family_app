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

// Bumped when the user taps "Enquiry" in the menu; the guest home watches this
// and scrolls to its "Register Your Interest" form.
final scrollToRegisterProvider = StateProvider<int>((ref) => 0);

class GuestMainShell extends ConsumerWidget {
  const GuestMainShell({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final currentIndex = ref.watch(guestNavigationProvider);
    final isDrawerOpen = ref.watch(drawerOpenProvider);

    final bool appIsDark = Theme.of(context).brightness == Brightness.dark;

    // LIGHT mode: Home (0) & Properties (1) are the deep-green "showcase"
    // screens (white typography); the info tabs stay cream with green
    // typography. DARK mode: everything inherits the navy theme.
    Widget showcase(Widget child) => appIsDark
        ? child
        : Theme(data: M4Theme.darkTheme, child: child);

    final List<Widget> screens = [
      showcase(const GuestDashboardScreen()), // 0: Home     — green
      showcase(const ProjectListScreen()), // 1: Projects — green
      const AboutScreen(), // 2: About    — cream
      const CareersScreen(), // 3: Careers  — cream
      const ContactScreen(), // 4: Contact  — cream
    ];

    // Nav pill follows the active tab's surface: green on the showcase tabs,
    // cream on the info tabs, navy in dark mode.
    final ThemeData navTheme = appIsDark
        ? M4Theme.darkThemeNavy
        : (currentIndex <= 1 ? M4Theme.darkTheme : M4Theme.lightTheme);

    return Scaffold(
      backgroundColor: navTheme.scaffoldBackgroundColor,
      drawer: const ConditionalDrawer(),
      onDrawerChanged: (isOpen) =>
          ref.read(drawerOpenProvider.notifier).state = isOpen,
      body: Stack(
        children: [
          IndexedStack(index: currentIndex, children: screens),
          if (!isDrawerOpen)
            Align(
              alignment: Alignment.bottomCenter,
              child: Theme(
                data: navTheme,
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
    // Frosted-glass pill: the surface follows the screen behind it (deep-green
    // on the showcase tabs, cream on the info tabs, navy in dark), with a
    // hairline border and a soft shadow — no heavy dark halo.
    return Container(
      margin: const EdgeInsets.only(bottom: 48),
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(100),
        // Soft float: a wide, very low-opacity shadow lifts the glass off the
        // page without the dark halo a tight shadow produces.
        boxShadow: [
          BoxShadow(
            color: const Color(0xFF0F2A20).withValues(alpha: isDark ? 0.28 : 0.10),
            blurRadius: 28,
            spreadRadius: -6,
            offset: const Offset(0, 10),
          ),
        ],
      ),
      child: ClipRRect(
        borderRadius: BorderRadius.circular(100),
        child: BackdropFilter(
          filter: ImageFilter.blur(sigmaX: 30, sigmaY: 30),
          child: Container(
      padding: const EdgeInsets.all(10),
      decoration: BoxDecoration(
        // Frosted glass: a translucent tint over the 30px blur, with a top-down
        // reflection so the bar reads as glass rather than a flat panel.
        gradient: LinearGradient(
          begin: Alignment.topCenter,
          end: Alignment.bottomCenter,
          colors: isDark
              ? [
                  Colors.white.withValues(alpha: 0.10),
                  Colors.white.withValues(alpha: 0.02),
                ]
              : [
                  Colors.white.withValues(alpha: 0.72),
                  Colors.white.withValues(alpha: 0.38),
                ],
        ),
        borderRadius: BorderRadius.circular(100),
        border: Border.all(
          color: (isDark ? M4Theme.cream : Colors.white)
              .withValues(alpha: isDark ? 0.16 : 0.65),
          width: 1.2,
        ),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          _NavIcon(
            icon: LucideIcons.home,
            isActive: currentIndex == 0,
            onTap: () => onTap(0),
          ),
          const SizedBox(width: 12),
          _NavIcon(
            icon: LucideIcons.building2,
            isActive: currentIndex == 1,
            onTap: () => onTap(1),
          ),
          const SizedBox(width: 12),
          _NavIcon(
            icon: LucideIcons.info,
            isActive: currentIndex == 2,
            onTap: () => onTap(2),
          ),
          const SizedBox(width: 12),
          _NavIcon(
            icon: LucideIcons.briefcase,
            isActive: currentIndex == 3,
            onTap: () => onTap(3),
          ),
          const SizedBox(width: 12),
          _NavIcon(
            icon: LucideIcons.headphones,
            isActive: currentIndex == 4,
            onTap: () => onTap(4),
          ),
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

  const _NavIcon({
    required this.icon,
    required this.isActive,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    return _ScaleButton(
      onTap: onTap,
      child: Container(
        width: 56,
        height: 56,
        decoration: BoxDecoration(
          color: isActive
              ? (isDark ? Colors.white : Color(0xFF163A2C))
              : Colors.transparent,
          shape: BoxShape.circle,
          boxShadow: isActive
              ? [
                  BoxShadow(
                    color: (isDark ? Colors.white : Color(0xFF163A2C)).withOpacity(
                      0.1,
                    ),
                    blurRadius: 10,
                  ),
                ]
              : [],
        ),
        child: Center(
          child: Icon(
            icon,
            color: isActive
                ? (isDark ? Colors.black : Colors.white)
                : (isDark ? Colors.white70 : Color(0xFF5E6B60)),
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

class _ScaleButtonState extends State<_ScaleButton>
    with SingleTickerProviderStateMixin {
  late AnimationController _controller;
  late Animation<double> _scale;

  @override
  void initState() {
    super.initState();
    _controller = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 100),
    );
    _scale = Tween<double>(
      begin: 1.0,
      end: 0.95,
    ).animate(CurvedAnimation(parent: _controller, curve: Curves.easeInOut));
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
