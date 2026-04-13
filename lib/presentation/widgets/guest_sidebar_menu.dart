import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:m4_mobile/core/theme/app_theme.dart';
import 'package:lucide_icons/lucide_icons.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:go_router/go_router.dart';
import 'dart:ui';
import 'package:url_launcher/url_launcher.dart';
import 'package:m4_mobile/core/providers/theme_provider.dart';

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
    final isDark = themeMode == ThemeMode.dark;
    
    return Drawer(
      backgroundColor: Colors.transparent,
      width: MediaQuery.of(context).size.width * 0.85,
      child: Stack(
        children: [
          BackdropFilter(
            filter: ImageFilter.blur(sigmaX: 30, sigmaY: 30),
            child: Container(
              decoration: BoxDecoration(
                color: Colors.black.withOpacity(0.4),
                border: Border(right: BorderSide(color: Colors.white.withOpacity(0.1))),
              ),
            ),
          ),
          SafeArea(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Padding(
                  padding: const EdgeInsets.fromLTRB(24, 20, 24, 10),
                  child: Text('MENU', style: GoogleFonts.montserrat(color: Colors.white38, fontSize: 10, fontWeight: FontWeight.w800, letterSpacing: 3)),
                ),
                Expanded(
                    child: ListView(
                      padding: const EdgeInsets.symmetric(horizontal: 12),
                      children: [
                        _MenuItem(label: 'HOME', icon: LucideIcons.home, isActive: GoRouterState.of(context).uri.path == '/home', onTap: () => context.go('/home')),
                        _MenuItem(label: 'COMMUNITY', icon: LucideIcons.building2, isActive: GoRouterState.of(context).uri.path == '/communities', onTap: () => context.push('/communities')),
                        _MenuItem(label: 'PROPERTIES', icon: LucideIcons.layoutGrid, isActive: GoRouterState.of(context).uri.path == '/projects', onTap: () => context.push('/projects')),
                        
                        _DropdownMenuItem(
                          label: 'CONTENT HUB',
                          icon: LucideIcons.bell,
                          isOpen: _isContentOpen,
                          onToggle: () => setState(() => _isContentOpen = !_isContentOpen),
                          subItems: [
                            _SubItem(label: 'MEDIA', onTap: () => context.push('/media')),
                            _SubItem(label: 'HIGHLIGHTS', onTap: () => context.push('/highlights')),
                            _SubItem(label: 'EVENTS', onTap: () => context.push('/events')),
                            _SubItem(label: 'BLOG', onTap: () => context.push('/blog')),
                          ],
                        ),
                        
                        _MenuItem(label: 'CUSTOM VIEWS', icon: LucideIcons.sparkles, isActive: GoRouterState.of(context).uri.path == '/custom-views', onTap: () => context.push('/custom-views')),
                        _MenuItem(label: 'WHO WE ARE', icon: LucideIcons.info, isActive: GoRouterState.of(context).uri.path == '/about', onTap: () => context.push('/about')),
                        
                        _DropdownMenuItem(
                          label: 'CONNECT',
                          icon: LucideIcons.share2,
                          isOpen: _isConnectOpen,
                          onToggle: () => setState(() => _isConnectOpen = !_isConnectOpen),
                          subItems: [
                            _SubItem(label: 'CP LOGIN', onTap: () => context.go('/login')),
                            _SubItem(label: 'INVESTOR LOGIN', onTap: () => context.go('/login')),
                            _SubItem(label: 'CUSTOMER LOGIN', onTap: () => context.go('/login')),
                          ],
                        ),
                        
                        _MenuItem(label: 'CAREERS', icon: LucideIcons.briefcase, isActive: GoRouterState.of(context).uri.path == '/careers', onTap: () => context.push('/careers')),
                        _MenuItem(label: 'CONTACT', icon: LucideIcons.phone, isActive: GoRouterState.of(context).uri.path == '/contact', onTap: () => context.push('/contact')),
                      
                      const SizedBox(height: 32),
                      Padding(
                        padding: const EdgeInsets.symmetric(horizontal: 14),
                        child: Text('QUICK ACTIONS', style: GoogleFonts.montserrat(color: Colors.white38, fontSize: 10, fontWeight: FontWeight.w800, letterSpacing: 3)),
                      ),
                      const SizedBox(height: 12),
                      _QuickActionItem(label: 'ENQUIRY', icon: LucideIcons.mail, onTap: () => context.push('/contact')),
                      _QuickActionItem(label: 'CALL', icon: LucideIcons.phone, onTap: () => launchUrl(Uri.parse('tel:+912246018844'))),
                      _QuickActionItem(label: 'WHATSAPP', icon: LucideIcons.messageSquare, onTap: () => launchUrl(Uri.parse('https://wa.me/912246018844'))),
                      _QuickActionItem(label: 'LOCATION', icon: LucideIcons.mapPin, onTap: () => launchUrl(Uri.parse('https://maps.google.com'))),
                    ],
                  ),
                ),
                Padding(
                  padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 8),
                  child: Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      Text('THEME MODE', style: GoogleFonts.montserrat(color: Colors.white, fontSize: 10, fontWeight: FontWeight.w800, letterSpacing: 2)),
                      GestureDetector(
                        onTap: () {
                          ref.read(themeProvider.notifier).setTheme(isDark ? ThemeMode.light : ThemeMode.dark);
                        },
                        child: Container(
                          padding: const EdgeInsets.all(8),
                          decoration: BoxDecoration(
                            border: Border.all(color: Colors.white.withOpacity(0.2)),
                            borderRadius: BorderRadius.circular(12),
                          ),
                          child: Icon(isDark ? LucideIcons.moon : LucideIcons.sparkles, color: Colors.white, size: 16),
                        ),
                      )
                    ],
                  ),
                ),
                Padding(
                  padding: const EdgeInsets.fromLTRB(24, 12, 24, 100), // Increased bottom padding to 100
                  child: Container(
                    width: double.infinity,
                    height: 56,
                    decoration: BoxDecoration(
                      color: Colors.red.withOpacity(0.08),
                      borderRadius: BorderRadius.circular(20),
                      border: Border.all(color: Colors.red.withOpacity(0.2)),
                    ),
                    child: InkWell(
                        onTap: () => context.go('/onboarding'),
                        borderRadius: BorderRadius.circular(20),
                        child: Row(
                          mainAxisAlignment: MainAxisAlignment.center,
                          children: [
                            const Icon(LucideIcons.logOut, color: Colors.red, size: 18),
                            const SizedBox(width: 12),
                            Text('EXIT APP', style: GoogleFonts.montserrat(color: Colors.red, fontWeight: FontWeight.w800, fontSize: 13, letterSpacing: 1)),
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

class _MenuItem extends StatelessWidget {
  final String label;
  final IconData icon;
  final bool isActive;
  final VoidCallback onTap;
  const _MenuItem({required this.label, required this.icon, required this.onTap, this.isActive = false});

  @override
  Widget build(BuildContext context) {
    return Row(
      children: [
        AnimatedContainer(
          duration: const Duration(milliseconds: 300),
          width: 4,
          height: isActive ? 24 : 0,
          decoration: BoxDecoration(
            color: Colors.white,
            borderRadius: BorderRadius.circular(2),
            boxShadow: [
              BoxShadow(color: Colors.white.withOpacity(0.5), blurRadius: 8)
            ],
          ),
        ),
        Expanded(
          child: ListTile(
            onTap: onTap,
            leading: Container(
              width: 40, height: 40,
              decoration: BoxDecoration(
                color: isActive ? Colors.white.withOpacity(0.1) : Colors.white.withOpacity(0.05), 
                borderRadius: BorderRadius.circular(12),
                border: isActive ? Border.all(color: Colors.white.withOpacity(0.1)) : null,
              ),
              child: Icon(icon, color: isActive ? Colors.white : Colors.white54, size: 18),
            ),
            title: Text(label, style: GoogleFonts.montserrat(color: isActive ? Colors.white : Colors.white70, fontSize: 12, fontWeight: isActive ? FontWeight.w800 : FontWeight.w700, letterSpacing: 1.5)),
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
  const _DropdownMenuItem({required this.label, required this.icon, required this.isOpen, required this.onToggle, required this.subItems});

  @override
  Widget build(BuildContext context) {
    return Column(
      children: [
        ListTile(
          onTap: onToggle,
          leading: Container(
            width: 40, height: 40,
            decoration: BoxDecoration(
              color: isOpen ? M4Theme.premiumBlue.withOpacity(0.1) : Colors.white.withOpacity(0.05), 
              borderRadius: BorderRadius.circular(12),
              border: isOpen ? Border.all(color: M4Theme.premiumBlue.withOpacity(0.2)) : null,
            ),
            child: Icon(icon, color: isOpen ? M4Theme.premiumBlue : Colors.white54, size: 18),
          ),
          title: Text(label, style: GoogleFonts.montserrat(color: isOpen ? M4Theme.premiumBlue : Colors.white, fontSize: 12, fontWeight: FontWeight.w700, letterSpacing: 1.5)),
          trailing: Icon(isOpen ? LucideIcons.chevronUp : LucideIcons.chevronDown, color: Colors.white24, size: 16),
        ),
        if (isOpen) ...subItems,
      ],
    );
  }
}

class _SubItem extends StatelessWidget {
  final String label;
  final VoidCallback onTap;
  const _SubItem({required this.label, required this.onTap});

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.only(left: 64),
      child: ListTile(
        onTap: onTap,
        dense: true,
        title: Text(label, style: GoogleFonts.montserrat(color: Colors.white54, fontSize: 11, fontWeight: FontWeight.w600, letterSpacing: 1)),
      ),
    );
  }
}

class _QuickActionItem extends StatelessWidget {
  final String label;
  final IconData icon;
  final VoidCallback onTap;
  const _QuickActionItem({required this.label, required this.icon, required this.onTap});

  @override
  Widget build(BuildContext context) {
    return ListTile(
      onTap: onTap,
      leading: Container(
        width: 40, height: 40,
        decoration: BoxDecoration(color: Colors.white.withOpacity(0.05), borderRadius: BorderRadius.circular(12)),
        child: Icon(icon, color: Colors.white54, size: 18),
      ),
      title: Text(label, style: GoogleFonts.montserrat(color: Colors.white54, fontSize: 12, fontWeight: FontWeight.w700, letterSpacing: 1.5)),
    );
  }
}
