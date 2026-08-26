import 'package:m4_mobile/presentation/widgets/drawer_glass.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:lucide_icons/lucide_icons.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:go_router/go_router.dart';
import 'package:url_launcher/url_launcher.dart';
import 'package:m4_mobile/presentation/widgets/guest_main_shell.dart';

class GuestSidebarMenu extends ConsumerStatefulWidget {
  const GuestSidebarMenu({super.key});

  @override
  ConsumerState<GuestSidebarMenu> createState() => _GuestSidebarMenuState();
}

class _GuestSidebarMenuState extends ConsumerState<GuestSidebarMenu> {
  bool _isContentOpen = false;
  bool _isConnectOpen = false;

  // Confirm before leaving — a Yes/No popup so a stray tap can't exit the app.
  Future<void> _confirmExit() async {
    // Dark mode is gone, so this is always false. It is NOT read from the
    // ambient brightness: the drawer can be opened from a green "showcase"
    // screen, whose theme reports Brightness.dark, and that would flip the
    // menu to tones it never used in light mode.
    final bool isDark = false;
    final confirmed = await showDialog<bool>(
      context: context,
      barrierDismissible: true,
      builder: (dialogCtx) => Dialog(
        backgroundColor: Colors.transparent,
        insetPadding: const EdgeInsets.symmetric(horizontal: 40),
        child: Container(
          padding: const EdgeInsets.all(24),
          decoration: BoxDecoration(
            color: isDark ? const Color(0xFF141B3A) : const Color(0xFFF4EFE3),
            borderRadius: BorderRadius.circular(20),
            border: Border.all(
              color: isDark
                  ? Colors.white.withOpacity(0.08)
                  : const Color(0xFF0C312B).withOpacity(0.08),
            ),
          ),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Container(
                width: 52,
                height: 52,
                decoration: BoxDecoration(
                  color: const Color(0xFFC65B46).withOpacity(0.12),
                  shape: BoxShape.circle,
                ),
                child: const Icon(
                  LucideIcons.logOut,
                  color: const Color(0xFFC65B46),
                  size: 24,
                ),
              ),
              const SizedBox(height: 16),
              Text(
                'Exit App',
                style: GoogleFonts.gelasio(
                  fontSize: 20,
                  fontWeight: FontWeight.w700,
                  color: isDark ? Colors.white : const Color(0xFF0C312B),
                ),
              ),
              const SizedBox(height: 8),
              Text(
                'Are you sure you want to exit the app?',
                textAlign: TextAlign.center,
                style: GoogleFonts.inter(
                  fontSize: 13,
                  color: isDark
                      ? Colors.white60
                      : const Color(0xFF0C312B).withOpacity(0.7),
                ),
              ),
              const SizedBox(height: 22),
              Row(
                children: [
                  Expanded(
                    child: GestureDetector(
                      onTap: () => Navigator.of(dialogCtx).pop(false),
                      child: Container(
                        height: 48,
                        alignment: Alignment.center,
                        decoration: BoxDecoration(
                          color: isDark
                              ? Colors.white.withOpacity(0.06)
                              : const Color(0xFF0C312B).withOpacity(0.05),
                          borderRadius: BorderRadius.circular(14),
                          border: Border.all(
                            color: isDark
                                ? Colors.white.withOpacity(0.08)
                                : const Color(0xFF0C312B).withOpacity(0.12),
                          ),
                        ),
                        child: Text(
                          'NO',
                          style: GoogleFonts.inter(
                            fontSize: 13,
                            fontWeight: FontWeight.w500,
                            letterSpacing: 1.2,
                            color: isDark
                                ? Colors.white70
                                : const Color(0xFF0C312B),
                          ),
                        ),
                      ),
                    ),
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    child: GestureDetector(
                      onTap: () => Navigator.of(dialogCtx).pop(true),
                      child: Container(
                        height: 48,
                        alignment: Alignment.center,
                        decoration: BoxDecoration(
                          color: const Color(0xFFC65B46),
                          borderRadius: BorderRadius.circular(14),
                        ),
                        child: Text(
                          'YES',
                          style: GoogleFonts.inter(
                            fontSize: 13,
                            fontWeight: FontWeight.w500,
                            letterSpacing: 1.2,
                            color: Colors.white,
                          ),
                        ),
                      ),
                    ),
                  ),
                ],
              ),
            ],
          ),
        ),
      ),
    );

    if (confirmed != true) return;
    if (!mounted) return;
    context.go('/onboarding');
  }

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;

    // The drawer can be opened from a screen pushed with Navigator.push (e.g.
    // the guest project detail), which is NOT under a GoRoute builder — so
    // GoRouterState.of(context) throws there. Read the path defensively; when
    // it's unavailable, no tab is marked active, which is correct on a pushed
    // detail screen anyway. Taps still use context.go/push, which work under
    // MaterialApp.router regardless.
    String? currentPath;
    try {
      currentPath = GoRouterState.of(context).uri.path;
    } catch (_) {
      currentPath = null;
    }

    return Drawer(
      backgroundColor: Colors.transparent,
      width: M4Drawer.panelWidth(context),
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
                  Padding(
                    padding: const EdgeInsets.fromLTRB(24, 20, 24, 10),
                    child: Text(
                      'MENU',
                      style: GoogleFonts.gelasio(
                        color: (isDark ? Colors.white : const Color(0xFFF4EFE3))
                            .withOpacity(0.68),
                        fontSize: 10,
                        fontWeight: FontWeight.w700,
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
                          isActive: currentPath == '/home',
                          onTap: () => context.go('/home'),
                        ),
                        _MenuItem(
                          label: 'Community',
                          icon: LucideIcons.building2,
                          isActive: currentPath == '/communities',
                          onTap: () => context.push('/communities'),
                        ),
                        _MenuItem(
                          label: 'Properties',
                          icon: LucideIcons.layoutGrid,
                          isActive: currentPath == '/projects',
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
                          isActive: currentPath == '/custom-views',
                          onTap: () => context.push('/custom-views'),
                        ),
                        _MenuItem(
                          label: 'Who We Are',
                          icon: LucideIcons.info,
                          isActive: currentPath == '/about',
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
                          isActive: currentPath == '/careers',
                          onTap: () => context.push('/careers'),
                        ),
                        _MenuItem(
                          label: 'Contact',
                          icon: LucideIcons.phone,
                          isActive: currentPath == '/contact',
                          onTap: () => context.push('/contact'),
                        ),

                        const SizedBox(height: 32),
                        Padding(
                          padding: const EdgeInsets.symmetric(horizontal: 14),
                          child: Text(
                            'QUICK ACTIONS',
                            style: GoogleFonts.gelasio(
                              color:
                                  (isDark
                                          ? Colors.white
                                          : const Color(0xFFF4EFE3))
                                      .withOpacity(0.6),
                              fontSize: 10,
                              fontWeight: FontWeight.w700,
                              letterSpacing: 3,
                            ),
                          ),
                        ),
                        const SizedBox(height: 12),
                        _QuickActionItem(
                          label: 'Enquiry',
                          icon: LucideIcons.mail,
                          // Go to the home page and scroll straight to its
                          // "Register Your Interest" form.
                          onTap: () {
                            Navigator.of(
                              context,
                            ).pop(); // close the menu drawer
                            ref.read(guestNavigationProvider.notifier).state =
                                0;
                            ref.read(scrollToRegisterProvider.notifier).state++;
                            context.go('/home');
                          },
                        ),
                        _QuickActionItem(
                          label: 'Call',
                          icon: LucideIcons.phone,
                          onTap: () =>
                              launchUrl(Uri.parse('tel:+912246018844')),
                        ),
                        _QuickActionItem(
                          label: 'WhatsApp',
                          icon: LucideIcons.messageSquare,
                          onTap: () => launchUrl(
                            Uri.parse('https://wa.me/912246018844'),
                          ),
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

                  Padding(
                    padding: const EdgeInsets.fromLTRB(24, 12, 24, 40),
                    child: Container(
                      width: double.infinity,
                      height: 60,
                      decoration: BoxDecoration(
                        color: const Color(0xFFC65B46).withOpacity(0.12),
                        borderRadius: BorderRadius.circular(20),
                        border: Border.all(
                          color: const Color(0xFFC65B46).withOpacity(0.1),
                        ),
                      ),
                      child: InkWell(
                        onTap: _confirmExit,
                        borderRadius: BorderRadius.circular(20),
                        child: Row(
                          mainAxisAlignment: MainAxisAlignment.center,
                          children: [
                            const Icon(
                              LucideIcons.logOut,
                              color: const Color(0xFFC65B46),
                              size: 20,
                            ),
                            const SizedBox(width: 12),
                            Text(
                              'EXIT APP',
                              style: GoogleFonts.inter(
                                color: const Color(0xFFC65B46),
                                fontWeight: FontWeight.w600,
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

  // Rendering is M4DrawerTile — the one row every portal uses.
  @override
  Widget build(BuildContext context) =>
      M4DrawerTile(icon: icon, label: label, isActive: isActive, onTap: onTap);
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

  // Same shared row as every other menu item, with a chevron trailing.
  @override
  Widget build(BuildContext context) => Column(
    children: [
      M4DrawerTile(
        icon: icon,
        label: label,
        isActive: isOpen,
        onTap: onToggle,
        trailing: Icon(
          isOpen ? LucideIcons.chevronUp : LucideIcons.chevronDown,
          color: M4Drawer.creamGlow.withValues(alpha: isOpen ? 1.0 : 0.8),
          size: 18,
        ),
      ),
      if (isOpen) ...subItems,
    ],
  );
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
        leading: Icon(icon, size: 16, color: color ?? Colors.white),
        title: Text(
          label,
          style: GoogleFonts.inter(
            color: (isDark ? Colors.white : const Color(0xFFF4EFE3))
                .withOpacity(0.85),
            fontSize: 13,
            fontWeight: FontWeight.w500,
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
          color: (isDark ? Colors.white : const Color(0xFFF4EFE3)).withOpacity(
            0.08,
          ),
          borderRadius: BorderRadius.circular(12),
        ),
        child: Icon(icon, color: Colors.white, size: 18),
      ),
      title: Text(
        label,
        style: GoogleFonts.inter(
          color: (isDark ? Colors.white : const Color(0xFFF4EFE3)).withOpacity(
            0.8,
          ),
          fontSize: 16.5,
          fontWeight: FontWeight.w500,
          letterSpacing: -0.2,
        ),
      ),
    );
  }
}
