import 'dart:ui';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:lucide_icons/lucide_icons.dart';
import 'package:m4_mobile/core/utils/support_handlers.dart';
import 'package:m4_mobile/presentation/providers/auth_provider.dart';
import 'package:m4_mobile/presentation/providers/cp_shell_provider.dart';
import 'package:m4_mobile/core/providers/theme_provider.dart';

class CpSidebarMenu extends ConsumerStatefulWidget {
  const CpSidebarMenu({super.key});

  @override
  ConsumerState<CpSidebarMenu> createState() => _CpSidebarMenuState();
}

class _CpSidebarMenuState extends ConsumerState<CpSidebarMenu> {
  void _close() => Navigator.of(context).pop();

  void _setTab(int i) {
    ref.read(cpNavigationIndexProvider.notifier).state = i;
    _close();
  }

  void _go(String path) {
    _close();
    context.push(path);
  }

  // Confirm before logging out — a Yes/No popup so a stray tap can't log out.
  Future<void> _confirmLogout() async {
    final isDark = ref.read(themeProvider) == ThemeMode.dark;
    final confirmed = await showDialog<bool>(
      context: context,
      barrierDismissible: true,
      builder: (dialogCtx) => Dialog(
        backgroundColor: Colors.transparent,
        insetPadding: const EdgeInsets.symmetric(horizontal: 40),
        child: Container(
          padding: const EdgeInsets.all(24),
          decoration: BoxDecoration(
            color: isDark ? const Color(0xFF15171C) : const Color(0xFF0F2A20).withValues(alpha: 0.72),
            borderRadius: BorderRadius.circular(20),
            border: Border.all(
              color: isDark
                  ? Colors.white.withOpacity(0.08)
                  : Colors.black.withOpacity(0.06),
            ),
          ),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Container(
                width: 52,
                height: 52,
                decoration: BoxDecoration(
                  color: Colors.red.withOpacity(0.12),
                  shape: BoxShape.circle,
                ),
                child: const Icon(
                  LucideIcons.logOut,
                  color: Colors.red,
                  size: 24,
                ),
              ),
              const SizedBox(height: 16),
              Text(
                'Logout',
                style: GoogleFonts.gelasio(
                  fontSize: 20,
                  fontWeight: FontWeight.w800,
                  color: isDark ? Colors.white : const Color(0xFFF4EFE3),
                ),
              ),
              const SizedBox(height: 8),
              Text(
                'Are you sure you want to logout?',
                textAlign: TextAlign.center,
                style: GoogleFonts.ebGaramond(
                  fontSize: 13,
                  color: isDark ? Colors.white60 : Colors.grey[600],
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
                              : const Color(0xFFF3F4F6),
                          borderRadius: BorderRadius.circular(14),
                          border: Border.all(
                            color: isDark
                                ? Colors.white.withOpacity(0.08)
                                : Colors.black.withOpacity(0.06),
                          ),
                        ),
                        child: Text(
                          'NO',
                          style: GoogleFonts.ebGaramond(
                            fontSize: 13,
                            fontWeight: FontWeight.w800,
                            letterSpacing: 1.2,
                            color: isDark ? Colors.white70 : Colors.grey[800],
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
                          color: Colors.red,
                          borderRadius: BorderRadius.circular(14),
                        ),
                        child: Text(
                          'YES',
                          style: GoogleFonts.ebGaramond(
                            fontSize: 13,
                            fontWeight: FontWeight.w800,
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
    _close();
    await ref.read(authProvider.notifier).logout();
    if (!mounted) return;
    // After logout, go to guest mode, not the login screen.
    context.go('/home');
  }

  @override
  Widget build(BuildContext context) {
    final idx = ref.watch(cpNavigationIndexProvider);
    final themeMode = ref.watch(themeProvider);
    final isDark = themeMode == ThemeMode.dark;

    return Drawer(
      width: MediaQuery.of(context).size.width * 0.8,
      backgroundColor: Colors.transparent,
      elevation: 0,
      child: Stack(
        children: [
          ClipRect(
            child: BackdropFilter(
              filter: ImageFilter.blur(sigmaX: 30, sigmaY: 30),
              child: Container(
                color: (isDark ? Colors.black : Colors.white).withOpacity(0.6),
              ),
            ),
          ),
          SafeArea(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                // Header
                Padding(
                  padding: const EdgeInsets.fromLTRB(24, 20, 24, 12),
                  child: Row(
                    children: [
                      Text(
                        'PARTNER MENU',
                        style: GoogleFonts.gelasio(
                          fontSize: 10,
                          fontWeight: FontWeight.w800,
                          letterSpacing: 2,
                          color: isDark ? Colors.white38 : Colors.grey[600],
                        ),
                      ),
                    ],
                  ),
                ),

                // Main Menu
                Expanded(
                  child: ListView(
                    padding: const EdgeInsets.symmetric(horizontal: 16),
                    children: [
                      // Web parity (CPSidebar.tsx menuItems order): Dashboard,
                      // Profile, Notifications, Properties, Custom Views,
                      // Content Hub, Communities, Bookings, Support Hub.
                      _SidebarItem(
                        icon: LucideIcons.home,
                        label: 'Dashboard',
                        isActive: idx == 0,
                        onTap: () => _setTab(0),
                      ),
                      _SidebarItem(
                        icon: LucideIcons.users,
                        label: 'Profile',
                        isActive: idx == 4,
                        onTap: () => _setTab(4),
                      ),
                      _SidebarItem(
                        icon: LucideIcons.bell,
                        label: 'Notifications',
                        isActive: false,
                        onTap: () => _go('/notifications'),
                      ),
                      _SidebarItem(
                        icon: LucideIcons.layoutGrid,
                        label: 'Properties',
                        isActive: idx == 2,
                        onTap: () => _setTab(2),
                      ),
                      _SidebarItem(
                        icon: LucideIcons.sparkles,
                        label: 'Custom Views',
                        isActive: false,
                        onTap: () => _go('/cp/custom-views'),
                      ),

                      Theme(
                        data: Theme.of(
                          context,
                        ).copyWith(dividerColor: Colors.transparent),
                        child: ExpansionTile(
                          iconColor: const Color(0xFF9333EA),
                          collapsedIconColor: const Color(0xFF9333EA),
                          onExpansionChanged: (_) {},
                          tilePadding: EdgeInsets.zero,
                          title: _SidebarItem(
                            icon: LucideIcons.sparkles,
                            label: 'Content Hub',
                            isActive: false,
                          ),
                          // Web parity: sub-items navigate to their own routes
                          // (/cp/media, /cp/highlights, /cp/events, /cp/blog) —
                          // there is no Content Hub tab in the CP shell, so the
                          // old setTab(9) crashed (index out of range).
                          children: [
                            _SubItem(
                              label: 'Media',
                              onTap: () => _go('/cp/media'),
                            ),
                            _SubItem(
                              label: 'Highlights',
                              onTap: () => _go('/cp/highlights'),
                            ),
                            _SubItem(
                              label: 'Events',
                              onTap: () => _go('/cp/events'),
                            ),
                            _SubItem(
                              label: 'Blog',
                              onTap: () => _go('/cp/blog'),
                            ),
                          ],
                        ),
                      ),

                      _SidebarItem(
                        icon: LucideIcons.building2,
                        label: 'Communities',
                        isActive: false,
                        onTap: () => _go('/communities'),
                      ),
                      _SidebarItem(
                        icon: LucideIcons.calendar,
                        label: 'Bookings',
                        isActive: false,
                        onTap: () => _go('/cp/booking/my-bookings'),
                      ),
                      _SidebarItem(
                        icon: LucideIcons.headphones,
                        label: 'Support Hub',
                        isActive: idx == 3,
                        onTap: () => _setTab(3),
                      ),

                      const SizedBox(height: 24),
                      Padding(
                        padding: const EdgeInsets.symmetric(
                          horizontal: 8,
                          vertical: 8,
                        ),
                        child: Text(
                          'QUICK ACTIONS',
                          style: GoogleFonts.gelasio(
                            fontSize: 10,
                            fontWeight: FontWeight.w800,
                            letterSpacing: 2,
                            color: isDark ? Colors.white38 : Colors.grey[600],
                          ),
                        ),
                      ),

                      _SidebarItem(
                        icon: LucideIcons.mail,
                        label: 'Enquiry',
                        isActive: false,
                        // Opens the "Register Interest" form (same fields and
                        // design as the web home #interest-form section).
                        onTap: () => _go('/cp/booking/inquiry'),
                      ),
                      _SidebarItem(
                        icon: LucideIcons.phone,
                        label: 'Call',
                        isActive: false,
                        onTap: () {
                          _close();
                          SupportHandlers.launchCall();
                        },
                      ),
                      _SidebarItem(
                        icon: LucideIcons.messageSquare,
                        label: 'Whatsapp',
                        isActive: false,
                        onTap: () {
                          _close();
                          SupportHandlers.launchWhatsApp();
                        },
                      ),
                    ],
                  ),
                ),

                // Theme Mode Toggle
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
                        style: GoogleFonts.gelasio(
                          fontSize: 10,
                          fontWeight: FontWeight.w800,
                          letterSpacing: 2,
                          color: isDark ? Colors.white38 : Colors.grey[600],
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
                              color: (isDark ? Colors.white : const Color(0xFFF4EFE3))
                                  .withOpacity(0.1),
                            ),
                          ),
                          // Web parity: light mode → Sparkles, dark → Moon
                          // (resolvedTheme === "dark" ? Moon : Sparkles).
                          child: Icon(
                            isDark ? LucideIcons.moon : LucideIcons.sparkles,
                            color: isDark ? Colors.white : const Color(0xFFF4EFE3),
                            size: 18,
                          ),
                        ),
                      ),
                    ],
                  ),
                ),

                // Logout
                Padding(
                  padding: const EdgeInsets.all(24),
                  child: GestureDetector(
                    onTap: _confirmLogout,
                    child: Container(
                      height: 56,
                      width: double.infinity,
                      decoration: BoxDecoration(
                        // Web parity: bg-red-50 (light) / red-900/10 (dark).
                        color: isDark
                            ? Colors.red.withOpacity(0.1)
                            : const Color(0xFFFEF2F2),
                        borderRadius: BorderRadius.circular(16),
                      ),
                      child: Row(
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: [
                          const Icon(
                            LucideIcons.logOut,
                            size: 18,
                            color: Colors.red,
                          ),
                          const SizedBox(width: 10),
                          Text(
                            'LOGOUT',
                            style: GoogleFonts.gelasio(
                              fontSize: 12,
                              fontWeight: FontWeight.w800,
                              letterSpacing: 1.5,
                              color: Colors.red,
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
    );
  }
}

class _SidebarItem extends StatelessWidget {
  final IconData icon;
  final String label;
  final bool isActive;
  final VoidCallback? onTap;

  const _SidebarItem({
    required this.icon,
    required this.label,
    required this.isActive,
    this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    const purple = Color(0xFF9333EA); // purple-600
    // Web parity: active → purple icon tile; inactive → slate tile + slate-400
    // icon.
    final iconBg = isActive
        ? (isDark
              ? purple.withOpacity(0.25)
              : const Color(0xFFF3E8FF)) // purple-100
        : (isDark
              ? const Color(0xFF1E293B)
              : const Color(0xFFF8FAFC)); // slate-800 / slate-50
    final iconColor = isActive ? purple : const Color(0xFF94A3B8); // slate-400

    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(16),
      child: Padding(
        // Web parity: px-6 py-3.5 (24px horizontal via the ListView pad + 8;
        // 14px vertical rhythm).
        padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 14),
        child: Row(
          children: [
            Container(
              width: 40,
              height: 40,
              decoration: BoxDecoration(
                color: iconBg,
                borderRadius: BorderRadius.circular(12),
              ),
              child: Center(child: Icon(icon, size: 16, color: iconColor)),
            ),
            const SizedBox(width: 16),
            Expanded(
              child: Text(
                label,
                style: GoogleFonts.ebGaramond(
                  fontSize: 14,
                  fontWeight: FontWeight.w800,
                  letterSpacing: -0.2,
                  color: isActive
                      ? purple
                      : (isDark ? Colors.white70 : const Color(0xFF1E293B)),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _SubItem extends StatelessWidget {
  final String label;
  final VoidCallback onTap;

  const _SubItem({required this.label, required this.onTap});

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;

    return InkWell(
      onTap: onTap,
      child: Padding(
        padding: const EdgeInsets.fromLTRB(60, 10, 24, 10),
        child: Row(
          children: [
            Container(
              width: 28,
              height: 28,
              decoration: BoxDecoration(
                color: (isDark ? Colors.white : const Color(0xFFF4EFE3)).withOpacity(0.05),
                borderRadius: BorderRadius.circular(8),
              ),
              child: Icon(
                LucideIcons.logIn,
                size: 14,
                color: isDark ? Colors.white70 : Color(0xFF5E6B60),
              ),
            ),
            const SizedBox(width: 12),
            Text(
              label,
              style: GoogleFonts.ebGaramond(
                fontSize: 13,
                fontWeight: FontWeight.w800,
                color: isDark ? Colors.white : const Color(0xFFF4EFE3),
              ),
            ),
          ],
        ),
      ),
    );
  }
}
