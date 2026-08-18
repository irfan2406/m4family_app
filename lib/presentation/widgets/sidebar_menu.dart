import 'package:flutter/material.dart';
import 'package:lucide_icons/lucide_icons.dart';
import 'package:google_fonts/google_fonts.dart';
import 'dart:ui';

import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:m4_mobile/presentation/widgets/main_shell.dart';
import 'package:m4_mobile/core/utils/support_handlers.dart';
import 'package:m4_mobile/presentation/screens/about/about_screen.dart';
import 'package:m4_mobile/presentation/screens/support/contact_screen.dart';
import 'package:m4_mobile/presentation/screens/careers/careers_screen.dart';
import 'package:m4_mobile/presentation/providers/auth_provider.dart';
import 'package:m4_mobile/core/providers/theme_provider.dart';

class SidebarMenu extends ConsumerStatefulWidget {
  const SidebarMenu({super.key});

  @override
  ConsumerState<SidebarMenu> createState() => _SidebarMenuState();
}

class _SidebarMenuState extends ConsumerState<SidebarMenu> {
  bool _isContentOpen = false;
  bool _isCustomViewsOpen = false;

  @override
  Widget build(BuildContext context) {
    final currentIndex = ref.watch(navigationProvider);
    final authState = ref.watch(authProvider);
    final themeMode = ref.watch(themeProvider);
    final isDark = themeMode == ThemeMode.dark;
    final user = authState.user;
    final role = user?['role']?.toString().toLowerCase();
    final isInvestor = role == 'investor';
    // Web parity: the user accent is `primary` (near-black in light mode),
    // not white — a hardcoded white active state is invisible on the light
    // glass sidebar.
    final accentColor = isInvestor
        ? const Color(0xFFC5A358)
        : Theme.of(context).colorScheme.onSurface;

    void navigateTo(int index) {
      final currentIndex = ref.read(navigationProvider);
      if (currentIndex != index) {
        ref.read(previousNavigationProvider.notifier).state = currentIndex;
      }
      ref.read(navigationProvider.notifier).state = index;

      // Close drawer first
      Navigator.pop(context);

      // Then pop back to the main shell (index 0 of the root navigator usually)
      // to ensure the tab switch is visible.
      while (Navigator.of(context).canPop()) {
        Navigator.of(context).pop();
      }
    }

    final currentRouteName = ModalRoute.of(context)?.settings.name;

    return Drawer(
      width: MediaQuery.of(context).size.width * 0.85,
      backgroundColor: Colors.transparent,
      child: Stack(
        children: [
          // 🧊 Premium Glassmorphism Background
          BackdropFilter(
            filter: ImageFilter.blur(sigmaX: 30, sigmaY: 30),
            child: Container(
              decoration: BoxDecoration(
                color: Theme.of(context).brightness == Brightness.dark
                    ? Colors.black.withOpacity(0.4)
                    : const Color(0xFF0F2A20).withValues(alpha: 0.72),
                border: Border(
                  right: BorderSide(
                    color:
                        (Theme.of(context).brightness == Brightness.dark
                                ? Colors.white
                                : Colors.white)
                            .withOpacity(0.1),
                    width: 1,
                  ),
                ),
              ),
            ),
          ),

          SafeArea(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                // Header
                Padding(
                  padding: const EdgeInsets.fromLTRB(32, 48, 32, 32),
                  child: Row(
                    children: [
                      Text(
                        isInvestor ? 'INVESTOR MENU' : 'MENU',
                        style: GoogleFonts.gelasio(
                          color: Theme.of(context).colorScheme.onSurface,
                          fontSize: 10,
                          fontWeight: FontWeight.w900,
                          letterSpacing: 4,
                        ),
                      ),
                    ],
                  ),
                ),

                // Navigation Items
                Expanded(
                  child: ListView(
                    padding: const EdgeInsets.symmetric(horizontal: 12),
                    children: [
                      _SidebarItem(
                        icon: LucideIcons.home,
                        label: 'Home',
                        isActive: currentIndex == 0 && currentRouteName == null,
                        activeColor: accentColor,
                        onTap: () => navigateTo(0),
                      ),
                      _SidebarItem(
                        icon: LucideIcons.building2,
                        label: 'Communities', // 👈 Web plural
                        isActive: currentIndex == 4,
                        activeColor: accentColor,
                        onTap: () => navigateTo(4),
                      ),
                      _SidebarItem(
                        icon: LucideIcons.layoutGrid,
                        label: 'Properties',
                        isActive: currentIndex == 1,
                        activeColor: accentColor,
                        onTap: () => navigateTo(1),
                      ),

                      // 🏗️ Content Hub Dropdown
                      _SidebarDropdown(
                        icon: LucideIcons.bell,
                        label: 'Content Hub',
                        isOpen: _isContentOpen,
                        onToggle: () =>
                            setState(() => _isContentOpen = !_isContentOpen),
                        subItems: [
                          _SidebarSubItem(
                            label: 'Media',
                            icon: LucideIcons.playCircle,
                            onTap: () {
                              ref.read(contentHubTypeProvider.notifier).state =
                                  'media';
                              navigateTo(9);
                            },
                          ),
                          _SidebarSubItem(
                            label: 'Highlights',
                            icon: LucideIcons.zap,
                            onTap: () {
                              ref.read(contentHubTypeProvider.notifier).state =
                                  'highlight';
                              navigateTo(9);
                            },
                          ),
                          _SidebarSubItem(
                            label: 'Events',
                            icon: LucideIcons.calendar,
                            onTap: () {
                              ref.read(contentHubTypeProvider.notifier).state =
                                  'event';
                              navigateTo(9);
                            },
                          ),
                          _SidebarSubItem(
                            label: 'Blog',
                            icon: LucideIcons.fileText,
                            onTap: () {
                              ref.read(contentHubTypeProvider.notifier).state =
                                  'blog';
                              navigateTo(9);
                            },
                          ),
                        ],
                      ),

                      // 🎨 Custom Views Dropdown
                      _SidebarDropdown(
                        icon: LucideIcons.sparkles,
                        label: 'Custom Views',
                        isOpen: _isCustomViewsOpen,
                        onToggle: () => setState(
                          () => _isCustomViewsOpen = !_isCustomViewsOpen,
                        ),
                        subItems: [
                          _SidebarSubItem(
                            label: 'My Custom Views',
                            icon: LucideIcons.logIn,
                            onTap: () => navigateTo(7),
                          ),
                          _SidebarSubItem(
                            label: 'Custom Views',
                            icon: LucideIcons.logIn,
                            onTap: () => navigateTo(6),
                          ),
                        ],
                      ),

                      _SidebarItem(
                        icon: LucideIcons.bell,
                        label: 'Notifications',
                        isActive: currentIndex == 5,
                        activeColor: accentColor,
                        onTap: () => navigateTo(5),
                      ),

                      _SidebarItem(
                        icon: LucideIcons.info,
                        label: 'Who we are',
                        isActive: currentRouteName == 'about',
                        onTap: () {
                          Navigator.pop(context);
                          if (currentRouteName == 'about') return;
                          Navigator.push(
                            context,
                            MaterialPageRoute(
                              settings: const RouteSettings(name: 'about'),
                              builder: (context) => const AboutScreen(),
                            ),
                          );
                        },
                      ),

                      _SidebarItem(
                        icon: LucideIcons.headphones,
                        label: 'Contact Us',
                        isActive: currentRouteName == 'contact',
                        onTap: () {
                          Navigator.pop(context);
                          if (currentRouteName == 'contact') return;
                          Navigator.push(
                            context,
                            MaterialPageRoute(
                              settings: const RouteSettings(name: 'contact'),
                              builder: (context) => const ContactScreen(),
                            ),
                          );
                        },
                      ),

                      _SidebarItem(
                        icon: LucideIcons.briefcase,
                        label: 'Careers',
                        isActive: currentRouteName == 'careers',
                        onTap: () {
                          Navigator.pop(context);
                          if (currentRouteName == 'careers') return;
                          Navigator.push(
                            context,
                            MaterialPageRoute(
                              settings: const RouteSettings(name: 'careers'),
                              builder: (context) => const CareersScreen(),
                            ),
                          );
                        },
                      ),

                      const SizedBox(height: 32),
                      Padding(
                        padding: const EdgeInsets.symmetric(
                          horizontal: 24,
                          vertical: 8,
                        ),
                        child: Text(
                          'QUICK ACTIONS',
                          style: GoogleFonts.gelasio(
                            color: Theme.of(
                              context,
                            ).colorScheme.onSurface.withOpacity(0.68),
                            fontSize: 10,
                            fontWeight: FontWeight.w900, // 👈 Match web bold
                            letterSpacing: 4,
                          ),
                        ),
                      ),
                      _SidebarItem(
                        icon: LucideIcons.mail,
                        label: 'Enquiry',
                        onTap: () {
                          ref.read(navigationProvider.notifier).state = 0;
                          ref
                              .read(inquiryScrollTriggerProvider.notifier)
                              .state++;
                          Navigator.pop(context);
                        },
                      ),
                      _SidebarItem(
                        icon: LucideIcons.phone,
                        label: 'Call',
                        onTap: SupportHandlers.launchCall,
                      ),
                      _SidebarItem(
                        icon: LucideIcons.messageSquare,
                        label: 'Whatsapp',
                        onTap: SupportHandlers.launchWhatsApp,
                      ),
                      _SidebarItem(
                        icon: LucideIcons.info,
                        label: 'About',
                        onTap: () {
                          Navigator.pop(context);
                          Navigator.push(
                            context,
                            MaterialPageRoute(
                              builder: (context) => const AboutScreen(),
                            ),
                          );
                        },
                      ),

                      const SizedBox(height: 120),
                    ],
                  ),
                ),

                // Footer — divider line ABOVE the THEME MODE row + LOG OUT
                // (matches web: line separates QUICK ACTIONS from the footer).
                Container(
                  decoration: BoxDecoration(
                    border: Border(
                      top: BorderSide(
                        color: Colors.white.withOpacity(isDark ? 0.05 : 0.2),
                      ),
                    ),
                  ),
                  child: Column(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      // Theme Mode Toggle
                      Padding(
                        padding: const EdgeInsets.fromLTRB(32, 16, 32, 8),
                        child: Row(
                          mainAxisAlignment: MainAxisAlignment.spaceBetween,
                          children: [
                            Text(
                              'THEME MODE',
                              style: GoogleFonts.gelasio(
                                color: isDark ? Colors.white70 : const Color(0xFFF4EFE3),
                                fontSize: 10,
                                fontWeight: FontWeight.w900,
                                letterSpacing: 2,
                              ),
                            ),
                            GestureDetector(
                              onTap: () {
                                ref
                                    .read(themeProvider.notifier)
                                    .setTheme(
                                      isDark ? ThemeMode.light : ThemeMode.dark,
                                    );
                              },
                              child: Container(
                                padding: const EdgeInsets.all(10),
                                decoration: BoxDecoration(
                                  color: (isDark ? Colors.white : const Color(0xFFF4EFE3))
                                      .withOpacity(0.08),
                                  borderRadius: BorderRadius.circular(12),
                                  border: Border.all(
                                    color:
                                        (isDark ? Colors.white : const Color(0xFFF4EFE3))
                                            .withOpacity(0.1),
                                  ),
                                ),
                                child: Icon(
                                  isDark
                                      ? LucideIcons.moon
                                      : LucideIcons.sparkles,
                                  color: isDark ? Colors.white : const Color(0xFFF4EFE3),
                                  size: 18,
                                ),
                              ),
                            ),
                          ],
                        ),
                      ),

                      // Bottom Actions (LOG OUT)
                      Container(
                        padding: const EdgeInsets.fromLTRB(24, 8, 24, 24),
                        decoration: BoxDecoration(
                          gradient: LinearGradient(
                            begin: Alignment.topCenter,
                            end: Alignment.bottomCenter,
                            colors: [
                              Colors.transparent,
                              (isDark ? Colors.black : Colors.white)
                                  .withOpacity(0.2),
                            ],
                          ),
                        ),
                        child: _SidebarExitButton(),
                      ),
                    ],
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

class _SidebarExitButton extends ConsumerWidget {
  @override
  Widget build(BuildContext context, WidgetRef ref) {
    return GestureDetector(
      onTap: () {
        showDialog(
          context: context,
          builder: (context) => AlertDialog(
            backgroundColor: const Color(0xFF18181B),
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(20),
            ),
            title: Text(
              'Logout',
              style: GoogleFonts.gelasio(
                color: Colors.white,
                fontWeight: FontWeight.bold,
                fontSize: 22,
              ),
            ),
            content: Text(
              'Are you sure you want to logout?',
              style: GoogleFonts.ebGaramond(
                color: Colors.white70,
                fontSize: 14,
              ),
            ),
            actions: [
              TextButton(
                onPressed: () => Navigator.pop(context),
                child: Text(
                  'CANCEL',
                  style: GoogleFonts.ebGaramond(color: const Color(0xFFC5A35B)),
                ),
              ),
              TextButton(
                onPressed: () {
                  ref.read(authProvider.notifier).logout();
                  Navigator.pop(context);
                  // Web parity: after logout, drop into guest mode
                  // (browse-as-guest home), not the login/onboarding screen.
                  context.go('/home');
                },
                child: Text(
                  'LOGOUT',
                  style: GoogleFonts.ebGaramond(
                    color: Colors.redAccent,
                    fontWeight: FontWeight.bold,
                  ),
                ),
              ),
            ],
          ),
        );
      },
      child: Container(
        width: double.infinity,
        height: 56, // 👈 Match web h-14 (14 * 4 = 56)
        decoration: BoxDecoration(
          color: Colors.red.withOpacity(0.08),
          borderRadius: BorderRadius.circular(16), // 👈 Web rounded-2xl
          border: Border.all(color: Colors.red.withOpacity(0.2), width: 1),
          boxShadow: [
            BoxShadow(
              color: Colors.red.withOpacity(0.05),
              blurRadius: 20,
              offset: const Offset(0, 10),
            ),
          ],
        ),
        child: Row(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            const Icon(LucideIcons.logOut, color: Color(0xFFEF4444), size: 16),
            const SizedBox(width: 12),
            Text(
              'LOG OUT',
              style: GoogleFonts.gelasio(
                color: const Color(0xFFEF4444),
                fontSize: 11,
                fontWeight: FontWeight.w900,
                letterSpacing: 4,
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _SidebarItem extends StatelessWidget {
  final IconData icon;
  final String label;
  final bool isActive;
  final Color? activeColor;
  final VoidCallback? onTap;
  final Widget? trailing;

  const _SidebarItem({
    required this.icon,
    required this.label,
    this.isActive = false,
    this.activeColor,
    this.onTap,
    this.trailing,
  });

  @override
  Widget build(BuildContext context) {
    final onSurface = Theme.of(context).colorScheme.onSurface;
    // Default active colour is the theme foreground (black in light mode,
    // white in dark) so active items never show white on the light sidebar.
    final activeColor = this.activeColor ?? onSurface;
    return Container(
      margin: const EdgeInsets.symmetric(vertical: 5),
      child: Stack(
        children: [
          // Active Indicator
          if (isActive)
            Positioned(
              left: 0,
              top: 15,
              bottom: 15,
              child: Container(
                width: 4,
                decoration: BoxDecoration(
                  color: activeColor,
                  borderRadius: const BorderRadius.only(
                    topRight: Radius.circular(10),
                    bottomRight: Radius.circular(10),
                  ),
                ),
              ),
            ),

          ListTile(
            leading: Container(
              width: 40,
              height: 40,
              decoration: BoxDecoration(
                // Web: bg-black/5 (light) / white/5 (dark) → theme-aware.
                color: isActive
                    ? activeColor.withOpacity(0.1)
                    : onSurface.withOpacity(0.05),
                borderRadius: BorderRadius.circular(12),
                border: Border.all(
                  color: isActive
                      ? activeColor.withOpacity(0.3)
                      : Colors.transparent,
                ),
                boxShadow: isActive
                    ? [
                        BoxShadow(
                          color: activeColor.withOpacity(0.15),
                          blurRadius: 20,
                          spreadRadius: 0,
                        ),
                      ]
                    : null,
              ),
              child: Icon(
                icon,
                color: isActive ? activeColor : onSurface.withOpacity(0.4),
                size: 18,
              ),
            ),
            title: Text(
              label,
              style: GoogleFonts.ebGaramond(
                color: isActive ? activeColor : onSurface.withOpacity(0.65),
                fontSize: 14,
                fontWeight: isActive ? FontWeight.w900 : FontWeight.w800,
                letterSpacing: -0.2,
              ),
            ),
            trailing: trailing,
            onTap: onTap,
            contentPadding: const EdgeInsets.symmetric(
              horizontal: 20,
              vertical: 4,
            ),
          ),
        ],
      ),
    );
  }
}

class _SidebarDropdown extends StatelessWidget {
  final IconData icon;
  final String label;
  final bool isOpen;
  final VoidCallback onToggle;
  final List<Widget> subItems;

  const _SidebarDropdown({
    required this.icon,
    required this.label,
    required this.isOpen,
    required this.onToggle,
    required this.subItems,
  });

  @override
  Widget build(BuildContext context) {
    return Column(
      children: [
        _SidebarItem(
          icon: icon,
          label: label,
          isActive: isOpen,
          // Theme-aware active colour: black in light mode, white in dark
          // (was hardcoded white → invisible/wrong on the light sidebar).
          activeColor: Theme.of(context).colorScheme.onSurface,
          onTap: onToggle,
          trailing: Icon(
            isOpen ? LucideIcons.chevronUp : LucideIcons.chevronDown,
            color: Theme.of(context).colorScheme.onSurface.withOpacity(0.4),
            size: 16,
          ),
        ),
        if (isOpen)
          Padding(
            padding: const EdgeInsets.only(left: 60, right: 12),
            child: Column(children: subItems),
          ),
      ],
    );
  }
}

class _SidebarSubItem extends StatelessWidget {
  final String label;
  final IconData icon;
  final VoidCallback onTap;

  const _SidebarSubItem({
    required this.label,
    required this.icon,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    final onSurface = Theme.of(context).colorScheme.onSurface;
    return ListTile(
      onTap: onTap,
      contentPadding: EdgeInsets.zero,
      visualDensity: VisualDensity.compact,
      leading: Container(
        width: 32,
        height: 32,
        decoration: BoxDecoration(
          color: onSurface.withOpacity(0.06),
          borderRadius: BorderRadius.circular(8),
        ),
        child: Icon(icon, color: onSurface.withOpacity(0.6), size: 15),
      ),
      title: Text(
        label,
        style: GoogleFonts.ebGaramond(
          color: onSurface.withOpacity(0.85),
          fontSize: 12.5,
          fontWeight: FontWeight.w800,
        ),
      ),
    );
  }
}
