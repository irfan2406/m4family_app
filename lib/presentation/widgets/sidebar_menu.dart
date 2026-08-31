import 'package:m4_mobile/presentation/widgets/drawer_glass.dart';
import 'package:flutter/material.dart';
import 'package:lucide_icons/lucide_icons.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:m4_mobile/core/theme/app_theme.dart';

import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:m4_mobile/presentation/widgets/main_shell.dart';
import 'package:m4_mobile/core/utils/support_handlers.dart';
import 'package:m4_mobile/presentation/screens/about/about_screen.dart';
import 'package:m4_mobile/presentation/screens/support/contact_screen.dart';
import 'package:m4_mobile/presentation/screens/careers/careers_screen.dart';
import 'package:m4_mobile/presentation/providers/auth_provider.dart';

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
    // Dark mode is gone, so this is always false. It is NOT read from the
    // ambient brightness: the drawer can be opened from a green "showcase"
    // screen, whose theme reports Brightness.dark, and that would flip the
    // menu to tones it never used in light mode.
    const bool isDark = false;
    final user = authState.user;
    final role = user?['role']?.toString().toLowerCase();
    final isInvestor = role == 'investor';
    // Web parity: the user accent is `primary` (near-black in light mode),
    // not white — a hardcoded white active state is invisible on the light
    // glass sidebar.
    final accentColor = isInvestor
        ? const Color(0xFFC5A35B)
        : const Color(0xFFF4EFE3);

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
      width: M4Drawer.panelWidth(context),
      backgroundColor: Colors.transparent,
      child: DecoratedBox(
        // Large soft ambient lift and an almost-invisible cream hairline —
        // the luxury floating-card effect, no hard shadow or harsh outline.
        decoration: BoxDecoration(
          boxShadow: M4Drawer.shadow,
          border: Border(right: BorderSide(color: M4Drawer.border)),
        ),
        child: Stack(
          children: [
            // Figma glass panel: deep-green base, cream bloom through
            // the middle, blue bloom low down, #0B0000 10% veil, blur 40.
            const DrawerGlass(),

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
                            color: Colors.white,
                            fontSize: 12,
                            fontWeight: FontWeight.w700,
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
                          isActive:
                              currentIndex == 0 && currentRouteName == null,
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
                                ref
                                        .read(contentHubTypeProvider.notifier)
                                        .state =
                                    'media';
                                navigateTo(9);
                              },
                            ),
                            _SidebarSubItem(
                              label: 'Highlights',
                              icon: LucideIcons.zap,
                              onTap: () {
                                ref
                                        .read(contentHubTypeProvider.notifier)
                                        .state =
                                    'highlight';
                                navigateTo(9);
                              },
                            ),
                            _SidebarSubItem(
                              label: 'Events',
                              icon: LucideIcons.calendar,
                              onTap: () {
                                ref
                                        .read(contentHubTypeProvider.notifier)
                                        .state =
                                    'event';
                                navigateTo(9);
                              },
                            ),
                            _SidebarSubItem(
                              label: 'Blog',
                              icon: LucideIcons.fileText,
                              onTap: () {
                                ref
                                        .read(contentHubTypeProvider.notifier)
                                        .state =
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
                              // The drawer is always the dark green panel, so the
                              // section label is cream like MENU above it —
                              // onSurface resolved dark here and sank into the
                              // background.
                              color: const Color(0xFFF4EFE3),
                              fontSize: 12,
                              fontWeight: FontWeight.w700, // 👈 Match web bold
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
                        const _SidebarItem(
                          icon: LucideIcons.phone,
                          label: 'Call',
                          onTap: SupportHandlers.launchCall,
                        ),
                        const _SidebarItem(
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
            backgroundColor: Theme.of(context).brightness == Brightness.dark
                ? const Color(0xFF141B3A)
                : const Color(0xFFF4EFE3),
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(20),
            ),
            // The sheet is navy in dark mode but CREAM in light — hardcoded
            // white type vanished on it. Both tones now follow the surface.
            title: Text(
              'Logout',
              style: GoogleFonts.gelasio(
                color: Theme.of(context).brightness == Brightness.dark
                    ? Colors.white
                    : M4Theme.lightForeground,
                fontWeight: FontWeight.bold,
                fontSize: 22,
              ),
            ),
            content: Text(
              'Are you sure you want to logout?',
              style: GoogleFonts.inter(
                color: Theme.of(context).brightness == Brightness.dark
                    ? Colors.white70
                    : M4Theme.lightForeground.withOpacity(0.78),
                fontSize: 15,
              ),
            ),
            actions: [
              TextButton(
                onPressed: () => Navigator.pop(context),
                child: Text(
                  'CANCEL',
                  style: GoogleFonts.inter(
                    // Gold reads on navy but washes out on cream.
                    color: Theme.of(context).brightness == Brightness.dark
                        ? const Color(0xFFC5A35B)
                        : const Color(0xFF163A2C),
                    fontWeight: FontWeight.w600,
                  ),
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
                  style: GoogleFonts.inter(
                    color: const Color(0xFFC65B46),
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
          color: const Color(0xFFC65B46).withOpacity(0.08),
          borderRadius: BorderRadius.circular(16), // 👈 Web rounded-2xl
          border: Border.all(
            color: const Color(0xFFC65B46).withOpacity(0.2),
            width: 1,
          ),
          boxShadow: [
            BoxShadow(
              color: const Color(0xFFC65B46).withOpacity(0.05),
              blurRadius: 20,
              offset: const Offset(0, 10),
            ),
          ],
        ),
        child: Row(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            const Icon(LucideIcons.logOut, color: Color(0xFFC65B46), size: 16),
            const SizedBox(width: 12),
            Text(
              'LOG OUT',
              style: GoogleFonts.gelasio(
                color: const Color(0xFFC65B46),
                fontSize: 11,
                fontWeight: FontWeight.w700,
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

  // Rendering is M4DrawerTile — the one row every portal uses. The portal
  // accent (investor gold vs cream) still comes through.
  @override
  Widget build(BuildContext context) => M4DrawerTile(
    icon: icon,
    label: label,
    isActive: isActive,
    onTap: onTap,
    trailing: trailing,
    accent: activeColor,
  );
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
          activeColor: Colors.white,
          onTap: onToggle,
          trailing: Icon(
            isOpen ? LucideIcons.chevronUp : LucideIcons.chevronDown,
            color: Colors.white,
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
    return ListTile(
      onTap: onTap,
      contentPadding: EdgeInsets.zero,
      visualDensity: VisualDensity.compact,
      leading: Container(
        width: 32,
        height: 32,
        decoration: BoxDecoration(
          color: Colors.white.withValues(alpha: 0.08),
          borderRadius: BorderRadius.circular(8),
        ),
        child: Icon(icon, color: Colors.white, size: 15),
      ),
      title: Text(
        label,
        style: GoogleFonts.inter(
          color: const Color(0xFFF4EFE3),
          fontSize: 14,
          fontWeight: FontWeight.w500,
        ),
      ),
    );
  }
}
