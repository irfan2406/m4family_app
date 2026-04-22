import 'dart:ui';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:lucide_icons/lucide_icons.dart';
import 'package:m4_mobile/core/utils/support_handlers.dart';
import 'package:m4_mobile/presentation/providers/auth_provider.dart';
import 'package:m4_mobile/presentation/providers/cp_shell_provider.dart';

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

  @override
  Widget build(BuildContext context) {
    final idx = ref.watch(cpNavigationIndexProvider);
    final isDark = Theme.of(context).brightness == Brightness.dark;

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
                      const Icon(LucideIcons.sparkles, size: 16, color: Color(0xFF9333EA)),
                      const SizedBox(width: 10),
                      Text(
                        'PARTNER MENU',
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
                        label: 'Dashboard',
                        isActive: idx == 0,
                        onTap: () => _setTab(0),
                      ),
                      _SidebarItem(
                        icon: LucideIcons.crown,
                        label: 'Partner Hub',
                        isActive: false,
                        onTap: () => _go('/cp/hub'),
                      ),
                      _SidebarItem(
                        icon: LucideIcons.user,
                        label: 'Profile',
                        isActive: idx == 5,
                        onTap: () => _setTab(5),
                      ),
                      _SidebarItem(
                        icon: LucideIcons.layoutGrid,
                        label: 'Property Catalog',
                        isActive: idx == 3,
                        onTap: () => _setTab(3),
                      ),
                      
                      Theme(
                        data: Theme.of(context).copyWith(dividerColor: Colors.transparent),
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
                          children: [
                            _SubItem(label: 'Media', onTap: () => _go('/media')),
                            _SubItem(label: 'Highlights', onTap: () => _go('/highlights')),
                            _SubItem(label: 'Events', onTap: () => _go('/events')),
                            _SubItem(label: 'Blog', onTap: () => _go('/cp/blog')),
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
                        label: 'Support Tickets',
                        isActive: idx == 4,
                        onTap: () => _setTab(4),
                      ),
                      _SidebarItem(
                        icon: LucideIcons.bell,
                        label: 'Notifications',
                        isActive: false,
                        onTap: () => _go('/notifications'),
                      ),

                      const SizedBox(height: 24),
                      Padding(
                        padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 8),
                        child: Text(
                          'QUICK ACTIONS',
                          style: GoogleFonts.montserrat(
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
                      _SidebarItem(
                        icon: LucideIcons.users,
                        label: 'Referral',
                        isActive: false,
                        onTap: () => _go('/cp/referral'),
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
                      context.go('/auth/cp/login');
                    },
                    child: Container(
                      height: 56,
                      width: double.infinity,
                      decoration: BoxDecoration(
                        color: Colors.white.withOpacity(0.9),
                        borderRadius: BorderRadius.circular(16),
                        boxShadow: [
                          BoxShadow(color: Colors.black.withOpacity(0.05), blurRadius: 10, offset: const Offset(0, 4)),
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
    final purple = const Color(0xFF9333EA);

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
                color: (isDark ? Colors.white : Colors.black).withOpacity(0.05),
                borderRadius: BorderRadius.circular(12),
              ),
              child: Center(
                child: Icon(
                  icon,
                  size: 18,
                  color: isActive ? purple : (isDark ? Colors.white70 : Colors.black54),
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
                  color: isActive ? purple : (isDark ? Colors.white : const Color(0xFF1E293B)),
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
                color: (isDark ? Colors.white : Colors.black).withOpacity(0.05),
                borderRadius: BorderRadius.circular(8),
              ),
              child: Icon(
                LucideIcons.logIn,
                size: 14,
                color: isDark ? Colors.white38 : Colors.black26,
              ),
            ),
            const SizedBox(width: 12),
            Text(
              label,
              style: GoogleFonts.montserrat(
                fontSize: 12,
                fontWeight: FontWeight.w600,
                color: isDark ? Colors.white54 : Colors.grey[700],
              ),
            ),
          ],
        ),
      ),
    );
  }
}
