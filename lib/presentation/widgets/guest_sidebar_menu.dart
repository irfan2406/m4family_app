import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:m4_mobile/core/theme/app_theme.dart';
import 'package:lucide_icons/lucide_icons.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:go_router/go_router.dart';
import 'dart:ui';
import 'package:url_launcher/url_launcher.dart';
import 'package:m4_mobile/core/providers/theme_provider.dart';
import 'package:m4_mobile/presentation/widgets/main_shell.dart';

class GuestSidebarMenu extends ConsumerStatefulWidget {
  const GuestSidebarMenu({super.key});

  @override
  ConsumerState<GuestSidebarMenu> createState() => _GuestSidebarMenuState();
}

class _GuestSidebarMenuState extends ConsumerState<GuestSidebarMenu> {
  bool _isContentOpen = false;
  bool _isConnectOpen = false;

  @override
  Widget build(BuildContext context) {
    final themeMode = ref.watch(themeProvider);
    // The guest drawer is GREEN glass in LIGHT mode (Figma frame 2 — unchanged)
    // and NAVY glass in DARK mode, so it darkens with the rest of the app.
    // `realIsDark` drives the panel tint + theme toggle; `isDark` (forced true)
    // keeps text/icons cream-on-dark for both tints.
    final realIsDark = themeMode == ThemeMode.dark;
    const isDark = true;

    return Theme(
      data: realIsDark ? M4Theme.darkThemeNavy : M4Theme.darkTheme,
      child: Drawer(
      backgroundColor: Colors.transparent,
      width: MediaQuery.of(context).size.width * 0.85,
      child: Stack(
        children: [
          BackdropFilter(
            filter: ImageFilter.blur(sigmaX: 30, sigmaY: 30),
            child: Container(
              decoration: BoxDecoration(
                // Frosted glass: green tint in LIGHT mode, deep navy tint in
                // DARK mode.
                color: realIsDark
                    ? M4Theme.navyBackground.withOpacity(0.62)
                    : M4Theme.deepGreen.withOpacity(0.6),
                border: Border(
                  right: BorderSide(color: M4Theme.gold.withOpacity(0.18)),
                ),
              ),
            ),
          ),
          SafeArea(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Padding(
                  padding: const EdgeInsets.fromLTRB(24, 20, 24, 10),
                  child: Text(
                    'MENU',
                    style: GoogleFonts.gelasio(
                      color: (isDark ? Colors.white : M4Theme.deepGreen).withOpacity(
                        0.68,
                      ),
                      fontSize: 10,
                      fontWeight: FontWeight.w900,
                      letterSpacing: 4,
                    ),
                  ),
                ),
                Expanded(
                  child: ListView(
                    padding: const EdgeInsets.symmetric(horizontal: 12),
                    children: [
                      _MenuItem(
                        label: 'Home',
                        icon: LucideIcons.home,
                        isActive: GoRouterState.of(context).uri.path == '/home',
                        onTap: () => context.go('/home'),
                      ),
                      _MenuItem(
                        label: 'Community',
                        icon: LucideIcons.building2,
                        isActive:
                            GoRouterState.of(context).uri.path ==
                            '/communities',
                        onTap: () => context.push('/communities'),
                      ),
                      _MenuItem(
                        label: 'Properties',
                        icon: LucideIcons.layoutGrid,
                        isActive:
                            GoRouterState.of(context).uri.path == '/projects',
                        onTap: () => context.push('/projects'),
                      ),

                      _DropdownMenuItem(
                        label: 'Content Hub',
                        icon: LucideIcons.bell,
                        isOpen: _isContentOpen,
                        onToggle: () =>
                            setState(() => _isContentOpen = !_isContentOpen),
                        subItems: [
                          _SubItem(
                            label: 'Media',
                            icon: LucideIcons.playCircle,
                            onTap: () {
                              context.push('/media');
                              Navigator.pop(context);
                            },
                          ),
                          _SubItem(
                            label: 'Highlights',
                            icon: LucideIcons.zap,
                            onTap: () {
                              context.push('/highlights');
                              Navigator.pop(context);
                            },
                          ),
                          _SubItem(
                            label: 'Events',
                            icon: LucideIcons.calendar,
                            onTap: () {
                              context.push('/events');
                              Navigator.pop(context);
                            },
                          ),
                          _SubItem(
                            label: 'Blog',
                            icon: LucideIcons.fileText,
                            onTap: () {
                              context.push('/blog');
                              Navigator.pop(context);
                            },
                          ),
                        ],
                      ),

                      _MenuItem(
                        label: 'Custom Views',
                        icon: LucideIcons.sparkles,
                        isActive:
                            GoRouterState.of(context).uri.path ==
                            '/custom-views',
                        onTap: () => context.push('/custom-views'),
                      ),
                      _MenuItem(
                        label: 'Who We Are',
                        icon: LucideIcons.info,
                        isActive:
                            GoRouterState.of(context).uri.path == '/about',
                        onTap: () => context.push('/about'),
                      ),

                      _DropdownMenuItem(
                        label: 'Connect',
                        icon: LucideIcons.share2,
                        isOpen: _isConnectOpen,
                        onToggle: () =>
                            setState(() => _isConnectOpen = !_isConnectOpen),
                        subItems: [
                          _SubItem(
                            label: 'CP Login',
                            icon: LucideIcons.logIn,
                            onTap: () {
                              context.push('/auth/cp/login?from=guest');
                              Navigator.pop(context);
                            },
                          ),
                          _SubItem(
                            label: 'Investor Login',
                            icon: LucideIcons.logIn,
                            onTap: () {
                              context.push('/investor/login');
                              Navigator.pop(context);
                            },
                          ),
                          _SubItem(
                            label: 'Customer Login',
                            icon: LucideIcons.logIn,
                            onTap: () {
                              context.push('/login?step=1');
                              Navigator.pop(context);
                            },
                          ),
                        ],
                      ),

                      _MenuItem(
                        label: 'Careers',
                        icon: LucideIcons.briefcase,
                        isActive:
                            GoRouterState.of(context).uri.path == '/careers',
                        onTap: () => context.push('/careers'),
                      ),
                      _MenuItem(
                        label: 'Contact',
                        icon: LucideIcons.phone,
                        isActive:
                            GoRouterState.of(context).uri.path == '/contact',
                        onTap: () => context.push('/contact'),
                      ),

                      const SizedBox(height: 32),
                      Padding(
                        padding: const EdgeInsets.symmetric(horizontal: 14),
                        child: Text(
                          'QUICK ACTIONS',
                          style: GoogleFonts.gelasio(
                            color: (isDark ? Colors.white : M4Theme.deepGreen)
                                .withOpacity(0.6),
                            fontSize: 10,
                            fontWeight: FontWeight.w900,
                            letterSpacing: 3,
                          ),
                        ),
                      ),
                      const SizedBox(height: 12),
                      _QuickActionItem(
                        label: 'Enquiry',
                        icon: LucideIcons.mail,
                        onTap: () => context.push('/contact'),
                      ),
                      _QuickActionItem(
                        label: 'Call',
                        icon: LucideIcons.phone,
                        onTap: () => launchUrl(Uri.parse('tel:+912246018844')),
                      ),
                      _QuickActionItem(
                        label: 'WhatsApp',
                        icon: LucideIcons.messageSquare,
                        onTap: () =>
                            launchUrl(Uri.parse('https://wa.me/912246018844')),
                      ),
                      _QuickActionItem(
                        label: 'Location',
                        icon: LucideIcons.mapPin,
                        onTap: () =>
                            launchUrl(Uri.parse('https://maps.google.com')),
                      ),
                    ],
                  ),
                ),

                // Bottom section
                Padding(
                  padding: const EdgeInsets.symmetric(
                    horizontal: 24,
                    vertical: 8,
                  ),
                  child: Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      Text(
                        'THEME MODE',
                        style: GoogleFonts.ebGaramond(
                          color: isDark ? Colors.white70 : M4Theme.deepGreen,
                          fontSize: 11,
                          fontWeight: FontWeight.w900,
                          letterSpacing: 1,
                        ),
                      ),
                      GestureDetector(
                        onTap: () {
                          ref
                              .read(themeProvider.notifier)
                              .setTheme(
                                realIsDark ? ThemeMode.light : ThemeMode.dark,
                              );
                        },
                        child: Container(
                          padding: const EdgeInsets.all(10),
                          decoration: BoxDecoration(
                            color: (isDark ? Colors.white : M4Theme.deepGreen)
                                .withOpacity(0.08),
                            borderRadius: BorderRadius.circular(12),
                            border: Border.all(
                              color: (isDark ? Colors.white : M4Theme.deepGreen)
                                  .withOpacity(0.1),
                            ),
                          ),
                          child: Icon(
                            realIsDark ? LucideIcons.sparkles : LucideIcons.moon,
                            color: Colors.white,
                            size: 18,
                          ),
                        ),
                      ),
                    ],
                  ),
                ),
                Padding(
                  padding: const EdgeInsets.fromLTRB(24, 12, 24, 40),
                  child: Container(
                    width: double.infinity,
                    height: 60,
                    decoration: BoxDecoration(
                      color: M4Theme.coral.withOpacity(0.14),
                      borderRadius: BorderRadius.circular(20),
                      border: Border.all(color: M4Theme.coral.withOpacity(0.35)),
                    ),
                    child: InkWell(
                      onTap: () => context.go('/onboarding'),
                      borderRadius: BorderRadius.circular(20),
                      child: Row(
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: [
                          const Icon(
                            LucideIcons.logOut,
                            color: M4Theme.coral,
                            size: 20,
                          ),
                          const SizedBox(width: 12),
                          Text(
                            'EXIT APP',
                            style: GoogleFonts.ebGaramond(
                              color: M4Theme.coral,
                              fontWeight: FontWeight.w900,
                              fontSize: 13,
                              letterSpacing: 1,
                            ),
                          ),
                        ],
                      ),
                    ),
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

class _MenuItem extends StatelessWidget {
  final String label;
  final IconData icon;
  final bool isActive;
  final VoidCallback onTap;
  const _MenuItem({
    required this.label,
    required this.icon,
    required this.onTap,
    this.isActive = false,
  });

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    // Reference: no gold. The active item gets a bright vertical accent bar on
    // the far left (white on the green theme, deep-green on the cream theme), a
    // subtly-lifted frosted icon box, and a full-strength icon + label.
    final accent = isDark ? Colors.white : M4Theme.deepGreen;
    return Stack(
      alignment: Alignment.centerLeft,
      children: [
        ListTile(
          onTap: onTap,
          contentPadding: const EdgeInsets.symmetric(
            horizontal: 14,
            vertical: 2,
          ),
          leading: Container(
            width: 44,
            height: 44,
            decoration: BoxDecoration(
              color: accent.withOpacity(isActive ? 0.16 : 0.06),
              borderRadius: BorderRadius.circular(12),
              border: isActive
                  ? Border.all(color: accent.withOpacity(0.25))
                  : null,
            ),
            child: Icon(
              icon,
              color: isActive ? accent : accent.withOpacity(0.45),
              size: 20,
            ),
          ),
          title: Text(
            label,
            style: GoogleFonts.ebGaramond(
              color: isActive ? accent : accent.withOpacity(0.75),
              fontSize: 15,
              fontWeight: isActive ? FontWeight.w800 : FontWeight.w700,
              letterSpacing: -0.2,
            ),
          ),
        ),
        // Far-left active accent bar (does not shift the row — overlaid).
        if (isActive)
          Container(
            width: 3,
            height: 26,
            decoration: BoxDecoration(
              color: accent,
              borderRadius: BorderRadius.circular(3),
            ),
          ),
      ],
    );
  }
}

class _DropdownMenuItem extends StatelessWidget {
  final String label;
  final IconData icon;
  final bool isOpen;
  final VoidCallback onToggle;
  final List<Widget> subItems;
  const _DropdownMenuItem({
    required this.label,
    required this.icon,
    required this.isOpen,
    required this.onToggle,
    required this.subItems,
  });

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    return Column(
      children: [
        ListTile(
          onTap: onToggle,
          contentPadding: const EdgeInsets.symmetric(
            horizontal: 14,
            vertical: 2,
          ),
          leading: Container(
            width: 44,
            height: 44,
            decoration: BoxDecoration(
              color: isOpen
                  ? (isDark ? Colors.white : M4Theme.deepGreen).withOpacity(0.15)
                  : (isDark ? Colors.white : M4Theme.deepGreen).withOpacity(0.08),
              borderRadius: BorderRadius.circular(12),
            ),
            child: Icon(
              icon,
              color: isOpen
                  ? (isDark ? Colors.white : M4Theme.deepGreen)
                  : (isDark
                        ? Colors.white.withOpacity(0.4)
                        : M4Theme.deepGreen.withOpacity(0.5)),
              size: 20,
            ),
          ),
          title: Text(
            label,
            style: GoogleFonts.ebGaramond(
              color: (isDark ? Colors.white : M4Theme.deepGreen).withOpacity(
                isOpen ? 1.0 : 0.8,
              ),
              fontSize: 15,
              fontWeight: FontWeight.w700,
              letterSpacing: -0.2,
            ),
          ),
          trailing: Icon(
            isOpen ? LucideIcons.chevronUp : LucideIcons.chevronDown,
            color: isDark ? Colors.white30 : M4Theme.deepGreen.withOpacity(0.35),
            size: 18,
          ),
        ),
        if (isOpen) ...subItems,
      ],
    );
  }
}

class _SubItem extends StatelessWidget {
  final String label;
  final IconData icon;
  final Color? color;
  final VoidCallback onTap;
  const _SubItem({
    required this.label,
    required this.icon,
    this.color,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    return Padding(
      padding: const EdgeInsets.only(left: 64),
      child: ListTile(
        onTap: onTap,
        dense: true,
        leading: Icon(
          icon,
          size: 16,
          color:
              color ?? (isDark ? Colors.white : M4Theme.deepGreen).withOpacity(0.6),
        ),
        title: Text(
          label,
          style: GoogleFonts.ebGaramond(
            color: (isDark ? Colors.white : M4Theme.deepGreen).withOpacity(0.85),
            fontSize: 13,
            fontWeight: FontWeight.w700,
          ),
        ),
      ),
    );
  }
}

class _QuickActionItem extends StatelessWidget {
  final String label;
  final IconData icon;
  final VoidCallback onTap;
  const _QuickActionItem({
    required this.label,
    required this.icon,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    return ListTile(
      onTap: onTap,
      contentPadding: const EdgeInsets.symmetric(horizontal: 14),
      leading: Container(
        width: 44,
        height: 44,
        decoration: BoxDecoration(
          color: (isDark ? Colors.white : M4Theme.deepGreen).withOpacity(0.08),
          borderRadius: BorderRadius.circular(12),
        ),
        child: Icon(
          icon,
          color: (isDark ? Colors.white : M4Theme.deepGreen).withOpacity(0.5),
          size: 18,
        ),
      ),
      title: Text(
        label,
        style: GoogleFonts.ebGaramond(
          color: (isDark ? Colors.white : M4Theme.deepGreen).withOpacity(0.8),
          fontSize: 15,
          fontWeight: FontWeight.w700,
          letterSpacing: -0.2,
        ),
      ),
    );
  }
}
