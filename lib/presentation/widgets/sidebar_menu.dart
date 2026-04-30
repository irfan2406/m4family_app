import 'package:flutter/material.dart';
import 'package:lucide_icons/lucide_icons.dart';
import 'package:google_fonts/google_fonts.dart';
import 'dart:ui';

import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:m4_mobile/presentation/widgets/main_shell.dart';
import 'package:m4_mobile/core/utils/support_handlers.dart';
import 'package:m4_mobile/presentation/screens/about/about_screen.dart';
import 'package:m4_mobile/presentation/screens/support/contact_support_screen.dart';
import 'package:m4_mobile/presentation/screens/careers/careers_screen.dart';
import 'package:m4_mobile/presentation/screens/investor/investor_relations_screen.dart';
import 'package:m4_mobile/presentation/screens/pages/pages_list_screen.dart';
import 'package:m4_mobile/presentation/screens/projects/project_list_screen.dart';
import 'package:m4_mobile/presentation/screens/content/content_hub_screen.dart';
import 'package:m4_mobile/presentation/providers/auth_provider.dart';





class SidebarMenu extends ConsumerStatefulWidget {
  const SidebarMenu({super.key});

  @override
  ConsumerState<SidebarMenu> createState() => _SidebarMenuState();
}

class _SidebarMenuState extends ConsumerState<SidebarMenu> {
  bool _isContentOpen = false;

  @override
  Widget build(BuildContext context) {
    final currentIndex = ref.watch(navigationProvider);
    final authState = ref.watch(authProvider);
    final user = authState.user;
    final role = user?['role']?.toString().toLowerCase();
    final isInvestor = role == 'investor';
    final accentColor = isInvestor ? const Color(0xFFC5A358) : Colors.white;

    void navigateTo(int index) {
      ref.read(navigationProvider.notifier).state = index;
      Navigator.pop(context); // Close drawer
    }

    return Drawer(
      width: MediaQuery.of(context).size.width * 0.85,
      backgroundColor: Colors.transparent,
      child: Stack(
        children: [
          // 🧊 Premium Glassmorphism Background
          BackdropFilter(
            filter: ImageFilter.blur(sigmaX: 30, sigmaY: 30),
            child: Container(
              color: const Color(0xFF09090B).withOpacity(0.4), // Low opacity for glass effect
            ),
          ),
          
          SafeArea(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                // Header
                Padding(
                  padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 32),
                  child: Row(
                    children: [
                      Container(
                        padding: const EdgeInsets.all(8),
                        decoration: BoxDecoration(
                          color: accentColor.withOpacity(0.1),
                          borderRadius: BorderRadius.circular(10),
                          border: Border.all(color: accentColor.withOpacity(0.2)),
                        ),
                        child: Icon(isInvestor ? LucideIcons.crown : LucideIcons.sparkles, color: accentColor, size: 20),
                      ),
                      const SizedBox(width: 16),
                      Text(
                        isInvestor ? 'INVESTOR MENU' : 'MENU',
                        style: GoogleFonts.montserrat(
                          color: accentColor,
                          fontSize: 10, // 👈 Web size
                          fontWeight: FontWeight.w900,
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
                        isActive: currentIndex == 0,
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
                        onToggle: () => setState(() => _isContentOpen = !_isContentOpen),
                        subItems: [
                          _SidebarSubItem(
                            label: 'Media',
                            onTap: () {
                              Navigator.pop(context);
                              Navigator.push(context, MaterialPageRoute(builder: (context) => const ContentHubScreen(type: 'media')));
                            },
                          ),
                          _SidebarSubItem(
                            label: 'Highlights',
                            onTap: () {
                              Navigator.pop(context);
                              Navigator.push(context, MaterialPageRoute(builder: (context) => const ContentHubScreen(type: 'highlights')));
                            },
                          ),
                          _SidebarSubItem(
                            label: 'Events',
                            onTap: () {
                              Navigator.pop(context);
                              Navigator.push(context, MaterialPageRoute(builder: (context) => const ContentHubScreen(type: 'events')));
                            },
                          ),
                          _SidebarSubItem(
                            label: 'Blog',
                            onTap: () {
                              Navigator.pop(context);
                              Navigator.push(context, MaterialPageRoute(builder: (context) => const ContentHubScreen(type: 'blog')));
                            },
                          ),
                        ],
                      ),

                      _SidebarItem(
                        icon: LucideIcons.layoutGrid, 
                        label: 'My Custom Views', // 👈 Added for web parity
                        isActive: currentIndex == 7,
                        activeColor: accentColor,
                        onTap: () => navigateTo(7),
                      ),

                      _SidebarItem(
                        icon: LucideIcons.sparkles, 
                        label: 'Custom Views',
                        isActive: currentIndex == 6,
                        activeColor: accentColor,
                        onTap: () => navigateTo(6),
                      ),
                      
                      _SidebarItem(
                        icon: LucideIcons.bell, 
                        label: 'Notifications',
                        isActive: currentIndex == 5,
                        activeColor: accentColor,
                        onTap: () => navigateTo(5),
                      ),

                      _SidebarItem(
                        icon: LucideIcons.headphones, 
                        label: 'Support',
                        isActive: currentIndex == 2,
                        activeColor: accentColor,
                        onTap: () => navigateTo(2),
                      ),
                      
                      _SidebarItem(
                        icon: LucideIcons.info, 
                        label: 'Who we are',
                        onTap: () {
                          Navigator.pop(context);
                          Navigator.push(context, MaterialPageRoute(builder: (context) => const AboutScreen()));
                        },
                      ),

                      const SizedBox(height: 32),
                      Padding(
                        padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 8),
                        child: Text(
                          'QUICK ACTIONS',
                          style: GoogleFonts.montserrat(
                            color: Colors.white.withOpacity(0.3),
                            fontSize: 10,
                            fontWeight: FontWeight.w900, // 👈 Match web bold
                            letterSpacing: 4,
                          ),
                        ),
                      ),
                      _SidebarItem(
                        icon: LucideIcons.mail, 
                        label: 'Enquiry',
                        onTap: () {
                          ref.read(navigationProvider.notifier).state = 0;
                          ref.read(inquiryScrollTriggerProvider.notifier).state++;
                          Navigator.pop(context);
                        },
                      ),
                      _SidebarItem(
                        icon: LucideIcons.phone, 
                        label: 'Call',
                        onTap: SupportHandlers.launchCall,
                      ),
                      _SidebarItem(
                        icon: LucideIcons.messageSquare, 
                        label: 'Whatsapp',
                        onTap: SupportHandlers.launchWhatsApp,
                      ),
                      _SidebarItem(
                        icon: LucideIcons.info, 
                        label: 'About',
                        onTap: () {
                          Navigator.pop(context);
                          Navigator.push(context, MaterialPageRoute(builder: (context) => const AboutScreen()));
                        },
                      ),

                      const SizedBox(height: 120),
                    ],
                  ),
                ),
                
                // Fixed Logout Button
                Padding(
                  padding: const EdgeInsets.fromLTRB(24, 12, 24, 100),
                  child: _SidebarExitButton(),
                ),
              ],
            ),
          ),
        ],
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
            backgroundColor: const Color(0xFF18181B),
            shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
            title: Text(
              'Logout',
              style: GoogleFonts.montserrat(
                color: Colors.white,
                fontWeight: FontWeight.bold,
                fontSize: 22,
              ),
            ),
            content: Text(
              'Are you sure you want to logout?',
              style: GoogleFonts.montserrat(
                color: Colors.white70,
                fontSize: 14,
              ),
            ),
            actions: [
              TextButton(
                onPressed: () => Navigator.pop(context),
                child: Text('CANCEL', style: GoogleFonts.montserrat(color: Colors.blueAccent)),
              ),
              TextButton(
                onPressed: () {
                  ref.read(authProvider.notifier).logout();
                  Navigator.pop(context);
                  context.go('/login');
                }, 
                child: Text('LOGOUT', style: GoogleFonts.montserrat(color: Colors.redAccent, fontWeight: FontWeight.bold)),
              ),
            ],
          ),
        );
      },
      child: Container(
        width: double.infinity,
        padding: const EdgeInsets.symmetric(vertical: 20),
        decoration: BoxDecoration(
          color: Colors.red.withOpacity(0.08), // 👈 Web style
          borderRadius: BorderRadius.circular(20), // 👈 More rounded like web
          border: Border.all(color: Colors.red.withOpacity(0.2), width: 1.5),
        ),
        child: Row(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Transform.rotate(
              angle: 3.14159, // 👈 Rotate 180 deg
              child: const Icon(LucideIcons.logOut, color: Colors.redAccent, size: 18),
            ),
            const SizedBox(width: 12),
            Text(
              'LOG OUT', // 👈 Web space
              style: GoogleFonts.montserrat(
                color: Colors.redAccent,
                fontSize: 11,
                fontWeight: FontWeight.w900,
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
  final Color activeColor;
  final VoidCallback? onTap;
  final Widget? trailing;

  const _SidebarItem({
    required this.icon,
    required this.label,
    this.isActive = false,
    this.activeColor = Colors.white,
    this.onTap,
    this.trailing,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      margin: const EdgeInsets.symmetric(vertical: 2),
      child: Stack(
        children: [
          // Active Indicator
          if (isActive)
            Positioned(
              left: 0,
              top: 12,
              bottom: 12,
              child: Container(
                width: 4,
                decoration: BoxDecoration(
                  color: activeColor,
                  borderRadius: const BorderRadius.only(
                    topRight: Radius.circular(4),
                    bottomRight: Radius.circular(4),
                  ),
                ),
              ),
            ),
          
          ListTile(
            leading: Container(
              width: 36, // 👈 Web size
              height: 36, // 👈 Web size
              decoration: BoxDecoration(
                color: isActive ? activeColor.withOpacity(0.1) : Colors.white.withOpacity(0.05),
                borderRadius: BorderRadius.circular(10), // 👈 Web radius
                border: Border.all(
                  color: isActive ? activeColor.withOpacity(0.3) : Colors.transparent,
                ),
                boxShadow: isActive ? [
                  BoxShadow(color: activeColor.withOpacity(0.15), blurRadius: 20, spreadRadius: 0)
                ] : null,
              ),
              child: Icon(
                icon, 
                color: isActive ? activeColor : Colors.white.withOpacity(0.4), 
                size: 16 // 👈 Web size
              ),
            ),
            title: Text(
              label,
              style: GoogleFonts.montserrat(
                color: isActive 
                    ? activeColor
                    : Colors.white.withOpacity(0.6),
                fontSize: 13, // 👈 Web size
                fontWeight: isActive ? FontWeight.w900 : FontWeight.w700, // 👈 Web weights
                letterSpacing: -0.2,
              ),
            ),
            trailing: trailing,
            onTap: onTap,
            contentPadding: const EdgeInsets.symmetric(horizontal: 24), // 👈 Web padding
            visualDensity: VisualDensity.compact,
          ),
        ],
      ),
    );
  }
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
          onTap: onToggle,
          trailing: Icon(
            isOpen ? LucideIcons.chevronUp : LucideIcons.chevronDown,
            color: Colors.white.withOpacity(0.3),
            size: 14,
          ),
        ),
        if (isOpen)
          Padding(
            padding: const EdgeInsets.only(left: 60, right: 12),
            child: Column(
              children: subItems,
            ),
          ),
      ],
    );
  }
}

class _SidebarSubItem extends StatelessWidget {
  final String label;
  final VoidCallback onTap;

  const _SidebarSubItem({required this.label, required this.onTap});

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
          color: Colors.white.withOpacity(0.05),
          borderRadius: BorderRadius.circular(8),
        ),
        child: const Icon(LucideIcons.logIn, color: Colors.white30, size: 14),
      ),
      title: Text(
        label,
        style: GoogleFonts.montserrat(
          color: Colors.white.withOpacity(0.6),
          fontSize: 12,
          fontWeight: FontWeight.w700,
        ),
      ),
    );
  }
}
