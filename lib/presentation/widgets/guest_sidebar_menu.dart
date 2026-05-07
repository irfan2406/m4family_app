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
                color: isDark ? Colors.black.withOpacity(0.8) : Colors.white.withOpacity(0.8),
                border: Border(right: BorderSide(color: (isDark ? Colors.white : Colors.black).withOpacity(0.05))),
              ),
            ),
          ),
          SafeArea(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Padding(
                  padding: const EdgeInsets.fromLTRB(24, 20, 24, 10),
                  child: Text('MENU', style: GoogleFonts.montserrat(color: (isDark ? Colors.white : Colors.black).withOpacity(0.5), fontSize: 10, fontWeight: FontWeight.w900, letterSpacing: 4)),
                ),
                Expanded(
                  child: ListView(
                    padding: const EdgeInsets.symmetric(horizontal: 12),
                    children: [
                      _MenuItem(label: 'Home', icon: LucideIcons.home, isActive: GoRouterState.of(context).uri.path == '/home', onTap: () => context.go('/home')),
                      _MenuItem(label: 'Community', icon: LucideIcons.building2, isActive: GoRouterState.of(context).uri.path == '/communities', onTap: () => context.push('/communities')),
                      _MenuItem(label: 'Properties', icon: LucideIcons.layoutGrid, isActive: GoRouterState.of(context).uri.path == '/projects', onTap: () => context.push('/projects')),
                      
                      _DropdownMenuItem(
                        label: 'Content Hub',
                        icon: LucideIcons.bell,
                        isOpen: _isContentOpen,
                        onToggle: () => setState(() => _isContentOpen = !_isContentOpen),
                        subItems: [
                          _SubItem(label: 'Media', icon: LucideIcons.playCircle, onTap: () {
                            context.push('/media');
                            Navigator.pop(context);
                          }),
                          _SubItem(label: 'Highlights', icon: LucideIcons.zap, onTap: () {
                            context.push('/highlights');
                            Navigator.pop(context);
                          }),
                          _SubItem(label: 'Events', icon: LucideIcons.calendar, onTap: () {
                            context.push('/events');
                            Navigator.pop(context);
                          }),
                          _SubItem(label: 'Blog', icon: LucideIcons.fileText, onTap: () {
                            context.push('/blog');
                            Navigator.pop(context);
                          }),
                        ],
                      ),
                      
                      _MenuItem(label: 'Custom Views', icon: LucideIcons.sparkles, isActive: GoRouterState.of(context).uri.path == '/custom-views', onTap: () => context.push('/custom-views')),
                      _MenuItem(label: 'Who We Are', icon: LucideIcons.info, isActive: GoRouterState.of(context).uri.path == '/about', onTap: () => context.push('/about')),
                      
                      _DropdownMenuItem(
                        label: 'Connect',
                        icon: LucideIcons.share2,
                        isOpen: _isConnectOpen,
                        onToggle: () => setState(() => _isConnectOpen = !_isConnectOpen),
                        subItems: [
                          _SubItem(label: 'CP Login', icon: LucideIcons.user, onTap: () => context.go('/login')),
                          _SubItem(label: 'Investor Login', icon: LucideIcons.crown, onTap: () => context.go('/login')),
                          _SubItem(label: 'Customer Login', icon: LucideIcons.users, onTap: () => context.go('/login')),
                        ],
                      ),
                      
                      _MenuItem(label: 'Careers', icon: LucideIcons.briefcase, isActive: GoRouterState.of(context).uri.path == '/careers', onTap: () => context.push('/careers')),
                      _MenuItem(label: 'Contact', icon: LucideIcons.phone, isActive: GoRouterState.of(context).uri.path == '/contact', onTap: () => context.push('/contact')),
                    
                      const SizedBox(height: 32),
                      Padding(
                        padding: const EdgeInsets.symmetric(horizontal: 14),
                        child: Text('QUICK ACTIONS', style: GoogleFonts.montserrat(color: (isDark ? Colors.white : Colors.black).withOpacity(0.6), fontSize: 10, fontWeight: FontWeight.w900, letterSpacing: 3)),
                      ),
                      const SizedBox(height: 12),
                      _QuickActionItem(label: 'Enquiry', icon: LucideIcons.mail, onTap: () => context.push('/contact')),
                      _QuickActionItem(label: 'Call', icon: LucideIcons.phone, onTap: () => launchUrl(Uri.parse('tel:+912246018844'))),
                      _QuickActionItem(label: 'WhatsApp', icon: LucideIcons.messageSquare, onTap: () => launchUrl(Uri.parse('https://wa.me/912246018844'))),
                      _QuickActionItem(label: 'Location', icon: LucideIcons.mapPin, onTap: () => launchUrl(Uri.parse('https://maps.google.com'))),
                    ],
                  ),
                ),
                
                // Bottom section
                Padding(
                  padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 8),
                  child: Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      Text('THEME MODE', style: GoogleFonts.montserrat(color: isDark ? Colors.white70 : Colors.black87, fontSize: 11, fontWeight: FontWeight.w900, letterSpacing: 1)),
                      GestureDetector(
                        onTap: () {
                          ref.read(themeProvider.notifier).setTheme(isDark ? ThemeMode.light : ThemeMode.dark);
                        },
                        child: Container(
                          padding: const EdgeInsets.all(10),
                          decoration: BoxDecoration(
                            color: (isDark ? Colors.white : Colors.black).withOpacity(0.08),
                            borderRadius: BorderRadius.circular(12),
                            border: Border.all(color: (isDark ? Colors.white : Colors.black).withOpacity(0.1)),
                          ),
                          child: Icon(isDark ? LucideIcons.sparkles : LucideIcons.moon, color: isDark ? Colors.white : Colors.black, size: 18),
                        ),
                      )
                    ],
                  ),
                ),
                Padding(
                  padding: const EdgeInsets.fromLTRB(24, 12, 24, 40),
                  child: Container(
                    width: double.infinity,
                    height: 60,
                    decoration: BoxDecoration(
                      color: Colors.red.withOpacity(0.12),
                      borderRadius: BorderRadius.circular(20),
                      border: Border.all(color: Colors.red.withOpacity(0.1)),
                    ),
                    child: InkWell(
                      onTap: () => context.go('/onboarding'),
                      borderRadius: BorderRadius.circular(20),
                      child: Row(
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: [
                          const Icon(LucideIcons.logOut, color: Colors.red, size: 20),
                          const SizedBox(width: 12),
                          Text(
                            'EXIT APP', 
                            style: GoogleFonts.montserrat(
                              color: Colors.red, 
                              fontWeight: FontWeight.w900, 
                              fontSize: 13, 
                              letterSpacing: 1
                            )
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

class _MenuItem extends StatelessWidget {
  final String label;
  final IconData icon;
  final bool isActive;
  final VoidCallback onTap;
  const _MenuItem({required this.label, required this.icon, required this.onTap, this.isActive = false});

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    return ListTile(
      onTap: onTap,
      contentPadding: const EdgeInsets.symmetric(horizontal: 14, vertical: 2),
      leading: Container(
        width: 44, height: 44,
        decoration: BoxDecoration(
          color: isActive ? (isDark ? Colors.white : Colors.black).withOpacity(0.15) : (isDark ? Colors.white : Colors.black).withOpacity(0.08), 
          borderRadius: BorderRadius.circular(12),
        ),
        child: Icon(icon, color: isActive ? (isDark ? Colors.white : Colors.black) : (isDark ? Colors.white.withOpacity(0.4) : Colors.black.withOpacity(0.5)), size: 20),
      ),
      title: Text(
        label, 
        style: GoogleFonts.montserrat(
          color: isActive ? (isDark ? Colors.white : Colors.black) : (isDark ? Colors.white.withOpacity(0.7) : Colors.black.withOpacity(0.8)), 
          fontSize: 15, 
          fontWeight: isActive ? FontWeight.w800 : FontWeight.w700,
          letterSpacing: -0.2
        )
      ),
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
    final isDark = Theme.of(context).brightness == Brightness.dark;
    return Column(
      children: [
        ListTile(
          onTap: onToggle,
          contentPadding: const EdgeInsets.symmetric(horizontal: 14, vertical: 2),
          leading: Container(
            width: 44, height: 44,
            decoration: BoxDecoration(
              color: isOpen ? (isDark ? Colors.white : Colors.black).withOpacity(0.15) : (isDark ? Colors.white : Colors.black).withOpacity(0.08), 
              borderRadius: BorderRadius.circular(12),
            ),
            child: Icon(icon, color: isOpen ? (isDark ? Colors.white : Colors.black) : (isDark ? Colors.white.withOpacity(0.4) : Colors.black.withOpacity(0.5)), size: 20),
          ),
          title: Text(
            label, 
            style: GoogleFonts.montserrat(
              color: (isDark ? Colors.white : Colors.black).withOpacity(isOpen ? 1.0 : 0.8), 
              fontSize: 15, 
              fontWeight: FontWeight.w700,
              letterSpacing: -0.2
            )
          ),
          trailing: Icon(isOpen ? LucideIcons.chevronUp : LucideIcons.chevronDown, color: isDark ? Colors.white30 : Colors.black26, size: 18),
        ),
        if (isOpen) ...subItems,
      ],
    );
  }
}

class _SubItem extends StatelessWidget {
  final String label;
  final IconData icon;
  final VoidCallback onTap;
  const _SubItem({required this.label, required this.icon, required this.onTap});

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    return Padding(
      padding: const EdgeInsets.only(left: 64),
      child: ListTile(
        onTap: onTap,
        dense: true,
        leading: Icon(icon, size: 16, color: (isDark ? Colors.white : Colors.black).withOpacity(0.3)),
        title: Text(
          label, 
          style: GoogleFonts.montserrat(
            color: (isDark ? Colors.white : Colors.black).withOpacity(0.5), 
            fontSize: 13, 
            fontWeight: FontWeight.w600
          )
        ),
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
    final isDark = Theme.of(context).brightness == Brightness.dark;
    return ListTile(
      onTap: onTap,
      contentPadding: const EdgeInsets.symmetric(horizontal: 14),
      leading: Container(
        width: 44, height: 44,
        decoration: BoxDecoration(color: (isDark ? Colors.white : Colors.black).withOpacity(0.08), borderRadius: BorderRadius.circular(12)),
        child: Icon(icon, color: (isDark ? Colors.white : Colors.black).withOpacity(0.5), size: 18),
      ),
      title: Text(
        label, 
        style: GoogleFonts.montserrat(
          color: (isDark ? Colors.white : Colors.black).withOpacity(0.8), 
          fontSize: 15, 
          fontWeight: FontWeight.w700,
          letterSpacing: -0.2
        )
      ),
    );
  }
}
