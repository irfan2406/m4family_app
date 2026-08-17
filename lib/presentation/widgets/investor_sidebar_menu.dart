import 'dart:ui';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:lucide_icons/lucide_icons.dart';
import 'package:m4_mobile/presentation/providers/auth_provider.dart';
import 'package:m4_mobile/presentation/providers/investor_shell_provider.dart';
import 'package:m4_mobile/core/providers/theme_provider.dart';
import 'package:m4_mobile/core/utils/support_handlers.dart';
import 'package:m4_mobile/presentation/screens/investor/investor_relations_screen.dart';

/// Investor drawer — mirrors [CpSidebarMenu] with gold accent and investor menu items.
/// Home/Projects/Support switch shell tabs; the rest route via `context.push`.
class InvestorSidebarMenu extends ConsumerStatefulWidget {
  const InvestorSidebarMenu({super.key});

  @override
  ConsumerState<InvestorSidebarMenu> createState() =>
      _InvestorSidebarMenuState();
}

class _InvestorSidebarMenuState extends ConsumerState<InvestorSidebarMenu> {
  static const _gold = Color(0xFFE8850C);
  bool _isContentOpen = false;
  bool _isCustomViewsOpen = false;

  void _close() => Navigator.of(context).pop();

  void _setTab(int i) {
    ref.read(investorNavigationIndexProvider.notifier).state = i;
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
                  ? Colors.white.withValues(alpha: 0.08)
                  : Colors.black.withValues(alpha: 0.06),
            ),
          ),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Container(
                width: 52,
                height: 52,
                decoration: BoxDecoration(
                  color: Colors.red.withValues(alpha: 0.12),
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
                              ? Colors.white.withValues(alpha: 0.06)
                              : const Color(0xFFF3F4F6),
                          borderRadius: BorderRadius.circular(14),
                          border: Border.all(
                            color: isDark
                                ? Colors.white.withValues(alpha: 0.08)
                                : Colors.black.withValues(alpha: 0.06),
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
    final idx = ref.watch(investorNavigationIndexProvider);
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
                color: (isDark ? Colors.black : Colors.white).withValues(
                  alpha: 0.6,
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
                  padding: const EdgeInsets.fromLTRB(24, 20, 24, 12),
                  child: Row(
                    children: [
                      Text(
                        'INVESTOR MENU',
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
                      // Web parity: the investor menu mirrors the web nav —
                      // Home, Communities, Properties, Content Hub (dropdown),
                      // Custom Views (dropdown), Notifications, Who we are,
                      // Contact Us, Careers.
                      _SidebarItem(
                        icon: LucideIcons.home,
                        label: 'Home',
                        isActive: idx == 0,
                        onTap: () => _setTab(0),
                      ),
                      _SidebarItem(
                        icon: LucideIcons.building2,
                        label: 'Communities',
                        isActive: false,
                        onTap: () => _go('/investor/communities'),
                      ),
                      _SidebarItem(
                        icon: LucideIcons.layoutGrid,
                        label: 'Properties',
                        isActive: idx == 1,
                        onTap: () => _setTab(1),
                      ),
                      _SidebarDropdown(
                        icon: LucideIcons.bell,
                        label: 'Content Hub',
                        isOpen: _isContentOpen,
                        onToggle: () =>
                            setState(() => _isContentOpen = !_isContentOpen),
                        subItems: [
                          _SidebarSubItem(
                            icon: LucideIcons.playCircle,
                            label: 'Media',
                            onTap: () => _go('/investor/media'),
                          ),
                          _SidebarSubItem(
                            icon: LucideIcons.zap,
                            label: 'Highlights',
                            onTap: () => _go('/investor/highlights'),
                          ),
                          _SidebarSubItem(
                            icon: LucideIcons.calendar,
                            label: 'Events',
                            onTap: () => _go('/investor/events'),
                          ),
                          _SidebarSubItem(
                            icon: LucideIcons.fileText,
                            label: 'Blog',
                            onTap: () => _go('/investor/blog'),
                          ),
                        ],
                      ),
                      _SidebarDropdown(
                        icon: LucideIcons.sparkles,
                        label: 'Custom Views',
                        isOpen: _isCustomViewsOpen,
                        onToggle: () => setState(
                          () => _isCustomViewsOpen = !_isCustomViewsOpen,
                        ),
                        subItems: [
                          _SidebarSubItem(
                            icon: LucideIcons.sparkles,
                            label: 'Custom Views',
                            onTap: () => _go('/investor/custom-views'),
                          ),
                          _SidebarSubItem(
                            icon: LucideIcons.star,
                            label: 'My Custom Views',
                            onTap: () => _go('/investor/my-custom-views'),
                          ),
                        ],
                      ),
                      _SidebarItem(
                        icon: LucideIcons.bell,
                        label: 'Notifications',
                        isActive: false,
                        onTap: () => _go('/investor/notifications'),
                      ),
                      _SidebarItem(
                        icon: LucideIcons.info,
                        label: 'Who we are',
                        isActive: false,
                        onTap: () => _go('/investor/about'),
                      ),
                      _SidebarItem(
                        icon: LucideIcons.headphones,
                        label: 'Contact Us',
                        isActive: false,
                        onTap: () => _go('/investor/contact'),
                      ),
                      _SidebarItem(
                        icon: LucideIcons.briefcase,
                        label: 'Careers',
                        isActive: false,
                        onTap: () => _go('/investor/careers'),
                      ),
                      _SidebarItem(
                        icon: LucideIcons.trendingUp,
                        label: 'Investor Relations',
                        isActive: false,
                        onTap: () {
                          _close();
                          Navigator.of(context).push(
                            MaterialPageRoute(
                              builder: (_) => const InvestorRelationsScreen(),
                            ),
                          );
                        },
                      ),

                      // Quick Actions (web parity)
                      Padding(
                        padding: const EdgeInsets.fromLTRB(8, 24, 8, 8),
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
                        onTap: () {
                          ref
                                  .read(
                                    investorNavigationIndexProvider.notifier,
                                  )
                                  .state =
                              0;
                          ref
                              .read(
                                investorInquiryScrollTriggerProvider.notifier,
                              )
                              .state++;
                          _close();
                        },
                      ),
                      _SidebarItem(
                        icon: LucideIcons.phone,
                        label: 'Call',
                        isActive: false,
                        onTap: SupportHandlers.launchCall,
                      ),
                      _SidebarItem(
                        icon: LucideIcons.messageSquare,
                        label: 'Whatsapp',
                        isActive: false,
                        onTap: SupportHandlers.launchWhatsApp,
                      ),
                      _SidebarItem(
                        icon: LucideIcons.users,
                        label: 'Referral',
                        isActive: false,
                        onTap: () => _go('/investor/referral'),
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
                                .withValues(alpha: 0.08),
                            borderRadius: BorderRadius.circular(12),
                            border: Border.all(
                              color: (isDark ? Colors.white : const Color(0xFFF4EFE3))
                                  .withValues(alpha: 0.1),
                            ),
                          ),
                          child: Icon(
                            isDark ? LucideIcons.sparkles : LucideIcons.moon,
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
                        color: Colors.white.withValues(alpha: 0.9),
                        borderRadius: BorderRadius.circular(16),
                        boxShadow: [
                          BoxShadow(
                            color: Colors.black.withValues(alpha: 0.05),
                            blurRadius: 10,
                            offset: const Offset(0, 4),
                          ),
                        ],
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
  final Widget? trailing;

  const _SidebarItem({
    required this.icon,
    required this.label,
    required this.isActive,
    this.onTap,
    this.trailing,
  });

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    const gold = Color(0xFFE8850C);

    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(16),
      child: Padding(
        padding: const EdgeInsets.symmetric(vertical: 8),
        child: Row(
          children: [
            Container(
              width: 44,
              height: 44,
              decoration: BoxDecoration(
                color: (isDark ? Colors.white : const Color(0xFFF4EFE3)).withValues(
                  alpha: 0.05,
                ),
                borderRadius: BorderRadius.circular(12),
              ),
              child: Center(
                child: Icon(
                  icon,
                  size: 18,
                  color: isActive
                      ? gold
                      : (isDark ? Colors.white70 : Color(0xFF5E6B60)),
                ),
              ),
            ),
            const SizedBox(width: 16),
            Expanded(
              child: Text(
                label,
                style: GoogleFonts.ebGaramond(
                  fontSize: 13,
                  fontWeight: FontWeight.w800,
                  color: isActive
                      ? gold
                      : (isDark ? Colors.white : const Color(0xFF1E293B)),
                ),
              ),
            ),
            if (trailing != null) trailing!,
          ],
        ),
      ),
    );
  }
}

/// Expandable menu group (Content Hub / Custom Views) — a header row with a
/// chevron that reveals its sub-items.
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
    final isDark = Theme.of(context).brightness == Brightness.dark;
    return Column(
      children: [
        _SidebarItem(
          icon: icon,
          label: label,
          isActive: false,
          onTap: onToggle,
          trailing: Icon(
            isOpen ? LucideIcons.chevronUp : LucideIcons.chevronDown,
            color: (isDark ? Colors.white : const Color(0xFFF4EFE3)).withValues(
              alpha: 0.4,
            ),
            size: 16,
          ),
        ),
        if (isOpen)
          Padding(
            padding: const EdgeInsets.only(left: 56, right: 8),
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
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final fg = isDark ? Colors.white : const Color(0xFF1E293B);
    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(12),
      child: Padding(
        padding: const EdgeInsets.symmetric(vertical: 6),
        child: Row(
          children: [
            Container(
              width: 32,
              height: 32,
              decoration: BoxDecoration(
                color: (isDark ? Colors.white : const Color(0xFFF4EFE3)).withValues(
                  alpha: 0.05,
                ),
                borderRadius: BorderRadius.circular(8),
              ),
              child: Center(
                child: Icon(icon, size: 15, color: fg.withValues(alpha: 0.7)),
              ),
            ),
            const SizedBox(width: 12),
            Expanded(
              child: Text(
                label,
                style: GoogleFonts.ebGaramond(
                  fontSize: 12.5,
                  fontWeight: FontWeight.w600,
                  color: fg.withValues(alpha: 0.85),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}
