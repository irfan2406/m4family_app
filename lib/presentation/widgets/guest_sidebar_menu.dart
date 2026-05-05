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
                        _MenuItem(label: 'HOME', icon: LucideIcons.home, isActive: GoRouterState.of(context).uri.path == '/home', onTap: () => context.go('/home')),
                        _MenuItem(label: 'COMMUNITY', icon: LucideIcons.building2, isActive: GoRouterState.of(context).uri.path == '/communities', onTap: () => context.push('/communities')),
                        _MenuItem(label: 'PROPERTIES', icon: LucideIcons.layoutGrid, isActive: GoRouterState.of(context).uri.path == '/projects', onTap: () => context.push('/projects')),
                        
                        _DropdownMenuItem(
                          label: 'CONTENT HUB',
                          icon: LucideIcons.bell,
                          isOpen: _isContentOpen,
                          onToggle: () => setState(() => _isContentOpen = !_isContentOpen),
                          subItems: [
                            _SubItem(label: 'MEDIA', icon: LucideIcons.playCircle, onTap: () {
                              context.push('/media');
                              Navigator.pop(context);
                            }),
                            _SubItem(label: 'HIGHLIGHTS', icon: LucideIcons.zap, onTap: () {
                              context.push('/highlights');
                              Navigator.pop(context);
                            }),
                            _SubItem(label: 'EVENTS', icon: LucideIcons.calendar, onTap: () {
                              context.push('/events');
                              Navigator.pop(context);
                            }),
                            _SubItem(label: 'BLOG', icon: LucideIcons.fileText, onTap: () {
                              context.push('/blog');
                              Navigator.pop(context);
                            }),
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
                            _SubItem(label: 'CP LOGIN', icon: LucideIcons.user, onTap: () => context.go('/login')),
                            _SubItem(label: 'INVESTOR LOGIN', icon: LucideIcons.crown, onTap: () => context.go('/login')),
                            _SubItem(label: 'CUSTOMER LOGIN', icon: LucideIcons.users, onTap: () => context.go('/login')),
                          ],
                        ),
                        
                        _MenuItem(label: 'CAREERS', icon: LucideIcons.briefcase, isActive: GoRouterState.of(context).uri.path == '/careers', onTap: () => context.push('/careers')),
                        _MenuItem(label: 'CONTACT', icon: LucideIcons.phone, isActive: GoRouterState.of(context).uri.path == '/contact', onTap: () => context.push('/contact')),
                      
                      const SizedBox(height: 32),
                      Padding(
                        padding: const EdgeInsets.symmetric(horizontal: 14),
                        child: Text('QUICK ACTIONS', style: GoogleFonts.montserrat(color: (isDark ? Colors.white : Colors.black).withOpacity(0.6), fontSize: 10, fontWeight: FontWeight.w900, letterSpacing: 3)),
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
                      Text('THEME MODE', style: GoogleFonts.montserrat(color: isDark ? Colors.white : Colors.black, fontSize: 11, fontWeight: FontWeight.w900, letterSpacing: 1.5)),
                      GestureDetector(
                        onTap: () {
                          ref.read(themeProvider.notifier).setTheme(isDark ? ThemeMode.light : ThemeMode.dark);
                        },
                        child: Container(
                          padding: const EdgeInsets.all(8),
                          decoration: BoxDecoration(
                            border: Border.all(color: (isDark ? Colors.white : Colors.black).withOpacity(0.3)),
                            borderRadius: BorderRadius.circular(12),
                          ),
                          child: Icon(isDark ? LucideIcons.moon : LucideIcons.sparkles, color: isDark ? Colors.white : Colors.black, size: 16),
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
                            Text('EXIT APP', style: GoogleFonts.montserrat(color: Colors.red, fontWeight: FontWeight.w900, fontSize: 13, letterSpacing: 1)),
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
    return Row(
      children: [
        AnimatedContainer(
          duration: const Duration(milliseconds: 300),
          width: 4,
          height: isActive ? 24 : 0,
          decoration: BoxDecoration(
            color: isDark ? Colors.white : Colors.black,
            borderRadius: BorderRadius.circular(2),
            boxShadow: [
              BoxShadow(color: (isDark ? Colors.white : Colors.black).withOpacity(0.5), blurRadius: 8)
            ],
          ),
        ),
        Expanded(
          child: ListTile(
            onTap: onTap,
            leading: Container(
              width: 40, height: 40,
              decoration: BoxDecoration(
                color: isActive ? (isDark ? Colors.white : Colors.black).withOpacity(0.15) : (isDark ? Colors.white : Colors.black).withOpacity(0.08), 
                borderRadius: BorderRadius.circular(12),
                border: isActive ? Border.all(color: (isDark ? Colors.white : Colors.black).withOpacity(0.2)) : null,
              ),
              child: Icon(icon, color: isActive ? (isDark ? Colors.white : Colors.black) : (isDark ? Colors.white.withOpacity(0.4) : Colors.black.withOpacity(0.5)), size: 18),
            ),
            title: Text(label, style: GoogleFonts.montserrat(color: isActive ? (isDark ? Colors.white : Colors.black) : (isDark ? Colors.white.withOpacity(0.7) : Colors.black.withOpacity(0.8)), fontSize: 13, fontWeight: isActive ? FontWeight.w900 : FontWeight.w800, letterSpacing: 1.2)),
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
    final isDark = Theme.of(context).brightness == Brightness.dark;
    return Column(
      children: [
        ListTile(
          onTap: onToggle,
          leading: Container(
            width: 40, height: 40,
            decoration: BoxDecoration(
              color: isOpen ? (isDark ? Colors.white : Colors.black).withOpacity(0.15) : (isDark ? Colors.white : Colors.black).withOpacity(0.08), 
              borderRadius: BorderRadius.circular(12),
              border: isOpen ? Border.all(color: (isDark ? Colors.white : Colors.black).withOpacity(0.2)) : null,
            ),
            child: Icon(icon, color: isOpen ? (isDark ? Colors.white : Colors.black) : (isDark ? Colors.white.withOpacity(0.4) : Colors.black.withOpacity(0.5)), size: 18),
          ),
          title: Text(label, style: GoogleFonts.montserrat(color: (isDark ? Colors.white : Colors.black).withOpacity(isOpen ? 1.0 : 0.8), fontSize: 13, fontWeight: FontWeight.w900, letterSpacing: 1.2)),
          trailing: Icon(isOpen ? LucideIcons.chevronUp : LucideIcons.chevronDown, color: isDark ? Colors.white.withOpacity(0.3) : Colors.black.withOpacity(0.3), size: 16),
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
        leading: Icon(icon, size: 14, color: (isDark ? Colors.white : Colors.black).withOpacity(0.3)),
        title: Text(label, style: GoogleFonts.montserrat(color: (isDark ? Colors.white : Colors.black).withOpacity(0.5), fontSize: 12, fontWeight: FontWeight.w800, letterSpacing: 1)),
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
      leading: Container(
        width: 40, height: 40,
        decoration: BoxDecoration(color: (isDark ? Colors.white : Colors.black).withOpacity(0.08), borderRadius: BorderRadius.circular(12)),
        child: Icon(icon, color: (isDark ? Colors.white : Colors.black).withOpacity(0.5), size: 18),
      ),
      title: Text(label, style: GoogleFonts.montserrat(color: (isDark ? Colors.white : Colors.black).withOpacity(0.6), fontSize: 13, fontWeight: FontWeight.w800, letterSpacing: 1.2)),
    );
  }
}
