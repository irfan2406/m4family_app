import 'dart:ui';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:lucide_icons/lucide_icons.dart';
import 'package:m4_mobile/presentation/providers/auth_provider.dart';
import 'package:m4_mobile/presentation/providers/investor_shell_provider.dart';
import 'package:m4_mobile/core/providers/theme_provider.dart';

/// Investor drawer — mirrors [CpSidebarMenu] with gold accent and investor menu items.
/// Home/Projects/Support switch shell tabs; the rest route via `context.push`.
class InvestorSidebarMenu extends ConsumerStatefulWidget {
  const InvestorSidebarMenu({super.key});

  @override
  ConsumerState<InvestorSidebarMenu> createState() => _InvestorSidebarMenuState();
}

class _InvestorSidebarMenuState extends ConsumerState<InvestorSidebarMenu> {
  static const _gold = Color(0xFFFFD700);

  void _close() => Navigator.of(context).pop();

  void _setTab(int i) {
    ref.read(investorNavigationIndexProvider.notifier).state = i;
    _close();
  }

  void _go(String path) {
    _close();
    context.push(path);
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
                color: (isDark ? Colors.black : Colors.white).withValues(alpha: 0.6),
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
                      const Icon(LucideIcons.crown, size: 16, color: _gold),
                      const SizedBox(width: 10),
                      Text(
                        'INVESTOR MENU',
                        style: GoogleFonts.montserrat(
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
                      _SidebarItem(
                        icon: LucideIcons.home,
                        label: 'Home',
                        isActive: idx == 0,
                        onTap: () => _setTab(0),
                      ),
                      _SidebarItem(
                        icon: LucideIcons.compass,
                        label: 'Projects',
                        isActive: idx == 1,
                        onTap: () => _setTab(1),
                      ),
                      _SidebarItem(
                        icon: LucideIcons.pieChart,
                        label: 'Portfolio',
                        isActive: false,
                        onTap: () => _go('/investor/portfolio'),
                      ),
                      _SidebarItem(
                        icon: LucideIcons.creditCard,
                        label: 'Payments',
                        isActive: false,
                        onTap: () => _go('/investor/payments'),
                      ),
                      _SidebarItem(
                        icon: LucideIcons.calendar,
                        label: 'Installments',
                        isActive: false,
                        onTap: () => _go('/investor/installments'),
                      ),
                      _SidebarItem(
                        icon: LucideIcons.fileText,
                        label: 'Tax Reports',
                        isActive: false,
                        onTap: () => _go('/investor/tax-reports'),
                      ),
                      _SidebarItem(
                        icon: LucideIcons.folder,
                        label: 'Documents',
                        isActive: false,
                        onTap: () => _go('/investor/documents'),
                      ),
                      _SidebarItem(
                        icon: LucideIcons.crown,
                        label: 'Elite',
                        isActive: false,
                        onTap: () => _go('/investor/elite'),
                      ),
                      _SidebarItem(
                        icon: LucideIcons.users,
                        label: 'Referral',
                        isActive: false,
                        onTap: () => _go('/investor/referral'),
                      ),
                      _SidebarItem(
                        icon: LucideIcons.messageSquare,
                        label: 'Support',
                        isActive: idx == 2,
                        onTap: () => _setTab(2),
                      ),
                      _SidebarItem(
                        icon: LucideIcons.settings,
                        label: 'Settings',
                        isActive: false,
                        onTap: () => _go('/investor/settings'),
                      ),
                    ],
                  ),
                ),

                // Theme Mode Toggle
                Padding(
                  padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 8),
                  child: Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      Text(
                        'THEME MODE',
                        style: GoogleFonts.montserrat(
                          fontSize: 10,
                          fontWeight: FontWeight.w800,
                          letterSpacing: 2,
                          color: isDark ? Colors.white38 : Colors.grey[600],
                        ),
                      ),
                      GestureDetector(
                        onTap: () {
                          ref.read(themeProvider.notifier).setTheme(isDark ? ThemeMode.light : ThemeMode.dark);
                        },
                        child: Container(
                          padding: const EdgeInsets.all(10),
                          decoration: BoxDecoration(
                            color: (isDark ? Colors.white : Colors.black).withValues(alpha: 0.08),
                            borderRadius: BorderRadius.circular(12),
                            border: Border.all(color: (isDark ? Colors.white : Colors.black).withValues(alpha: 0.1)),
                          ),
                          child: Icon(
                            isDark ? LucideIcons.sparkles : LucideIcons.moon,
                            color: isDark ? Colors.white : Colors.black,
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
                    onTap: () async {
                      _close();
                      await ref.read(authProvider.notifier).logout();
                      if (!context.mounted) return;
                      context.go('/investor/login');
                    },
                    child: Container(
                      height: 56,
                      width: double.infinity,
                      decoration: BoxDecoration(
                        color: Colors.white.withValues(alpha: 0.9),
                        borderRadius: BorderRadius.circular(16),
                        boxShadow: [
                          BoxShadow(color: Colors.black.withValues(alpha: 0.05), blurRadius: 10, offset: const Offset(0, 4)),
                        ],
                      ),
                      child: Row(
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: [
                          const Icon(LucideIcons.logOut, size: 18, color: Colors.red),
                          const SizedBox(width: 10),
                          Text(
                            'LOGOUT',
                            style: GoogleFonts.montserrat(
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
    const gold = Color(0xFFFFD700);

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
                color: (isDark ? Colors.white : Colors.black).withValues(alpha: 0.05),
                borderRadius: BorderRadius.circular(12),
              ),
              child: Center(
                child: Icon(
                  icon,
                  size: 18,
                  color: isActive ? gold : (isDark ? Colors.white70 : Colors.black54),
                ),
              ),
            ),
            const SizedBox(width: 16),
            Expanded(
              child: Text(
                label,
                style: GoogleFonts.montserrat(
                  fontSize: 13,
                  fontWeight: FontWeight.w700,
                  color: isActive ? gold : (isDark ? Colors.white : const Color(0xFF1E293B)),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}
