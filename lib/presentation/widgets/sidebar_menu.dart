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
                        padding: const EdgeInsets.all(10),
                        decoration: BoxDecoration(
                          color: Colors.white.withOpacity(0.05),
                          borderRadius: BorderRadius.circular(12),
                          border: Border.all(color: Colors.white.withOpacity(0.1)),
                        ),
                        child: const Icon(LucideIcons.sparkles, color: Colors.white, size: 18),
                      ),
                      const SizedBox(width: 16),
                      Text(
                        'MENU',
                        style: GoogleFonts.montserrat(
                          color: Colors.white,
                          fontSize: 14,
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
                        onTap: () => navigateTo(0),
                      ),
                      _SidebarItem(
                        icon: LucideIcons.building2,
                        label: 'Community',
                        isActive: currentIndex == 4,
                        onTap: () => navigateTo(4),
                      ),
                      _SidebarItem(
                        icon: LucideIcons.layoutGrid,
                        label: 'Properties',
                        isActive: currentIndex == 1,
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
                        icon: LucideIcons.sparkles, 
                        label: 'Custom Views',
                        isActive: currentIndex == 6,
                        onTap: () => navigateTo(6),
                      ),
                      
                      _SidebarItem(
                        icon: LucideIcons.fileText, 
                        label: 'Selection Logs',
                        isActive: currentIndex == 7,
                        onTap: () => navigateTo(7),
                      ),

                      _SidebarItem(
                        icon: LucideIcons.bell, 
                        label: 'Notifications',
                        isActive: currentIndex == 5,
                        onTap: () => navigateTo(5),
                      ),

                      _SidebarItem(
                        icon: LucideIcons.headphones, 
                        label: 'Support',
                        isActive: currentIndex == 2,
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

                      _SidebarItem(
                        icon: LucideIcons.phoneCall, 
                        label: 'Contact Us',
                        onTap: () {
                          Navigator.pop(context);
                          Navigator.push(context, MaterialPageRoute(builder: (context) => ContactSupportScreen()));
                        },
                      ),

                      _SidebarItem(
                        icon: LucideIcons.briefcase, 
                        label: 'Careers',
                        onTap: () {
                          Navigator.pop(context);
                          Navigator.push(context, MaterialPageRoute(builder: (context) => const CareersScreen()));
                        },
                      ),

                      _SidebarItem(
                        icon: LucideIcons.trendingUp,
                        label: 'Investor Relations',
                        onTap: () {
                          Navigator.pop(context);
                          Navigator.push(context, MaterialPageRoute(builder: (context) => const InvestorRelationsScreen()));
                        },
                      ),

                      _SidebarItem(
                        icon: LucideIcons.layers,
                        label: 'Pages',
                        onTap: () {
                          Navigator.pop(context);
                          Navigator.push(context, MaterialPageRoute(builder: (context) => const PagesListScreen()));
                        },
                      ),

                      const SizedBox(height: 32),
                      Padding(
                        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
                        child: Text(
                          'QUICK ACTIONS',
                          style: GoogleFonts.montserrat(
                            color: Colors.white.withOpacity(0.3),
                            fontSize: 10,
                            fontWeight: FontWeight.bold,
                            letterSpacing: 3,
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
                      
                      const SizedBox(height: 16),
                      _SidebarExitButton(),
                      const SizedBox(height: 120),

                    ],
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

class _SidebarExitButton extends ConsumerWidget {
  @override
  Widget build(BuildContext context, WidgetRef ref) {
    return GestureDetector(
      onTap: () {
        showDialog(
          context: context,
          builder: (context) => AlertDialog(
            backgroundColor: const Color(0xFF18181B), // Dark Zinc-900
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
            contentPadding: const EdgeInsets.fromLTRB(24, 20, 24, 10),
            actionsPadding: const EdgeInsets.fromLTRB(0, 0, 16, 16),
            actions: [
              TextButton(
                onPressed: () => Navigator.pop(context),
                child: Text(
                  'CANCEL',
                  style: GoogleFonts.montserrat(
                    color: const Color(0xFF60A5FA), // Bright Blue to match Image 2
                    fontWeight: FontWeight.w600,
                    fontSize: 13,
                  ),
                ),
              ),
              const SizedBox(width: 8),
              TextButton(
                onPressed: () {
                  // Actually clear the authentication state and storage
                  ref.read(authProvider.notifier).logout();
                  
                  Navigator.pop(context); // Close dialog
                  context.go('/login'); // Redirect to login
                }, 
                child: Text(
                  'LOGOUT',
                  style: GoogleFonts.montserrat(
                    color: const Color(0xFFEF4444), // Red-500
                    fontWeight: FontWeight.bold,
                    fontSize: 13,
                  ),
                ),
              ),
            ],
          ),
        );
      },
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 16),
        child: Container(
          width: double.infinity,
          padding: const EdgeInsets.symmetric(vertical: 20),
          decoration: BoxDecoration(
            color: Colors.red.withOpacity(0.02),
            borderRadius: BorderRadius.circular(16),
            border: Border.all(color: Colors.red.withOpacity(0.2), width: 1.5),
            boxShadow: [
              BoxShadow(
                color: Colors.red.withOpacity(0.05),
                blurRadius: 20,
                spreadRadius: -5,
              ),
            ],
          ),
          child: Row(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              const Icon(LucideIcons.logOut, color: Colors.redAccent, size: 18),
              const SizedBox(width: 12),
              Text(
                'LOGOUT',
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
    this.isActive = false,
    this.onTap,
    this.trailing,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      margin: const EdgeInsets.symmetric(vertical: 4),
      child: Stack(
        children: [
          // Active Indicator (White Vertical Capsule)
          if (isActive)
            Positioned(
              left: 2,
              top: 15,
              bottom: 15,
              child: Container(
                width: 4,
                decoration: BoxDecoration(
                  color: Colors.white,
                  borderRadius: BorderRadius.circular(2),
                  boxShadow: [
                    BoxShadow(
                      color: Colors.white.withOpacity(0.5),
                      blurRadius: 10,
                    ),
                  ],
                ),
              ),
            ),
          
          ListTile(
            leading: Container(
              width: 44,
              height: 44,
              decoration: BoxDecoration(
                color: Colors.white.withOpacity(isActive ? 0.1 : 0.03),
                borderRadius: BorderRadius.circular(12),
                border: Border.all(
                  color: isActive ? Colors.white.withOpacity(0.15) : Colors.white.withOpacity(0.05),
                ),
              ),
              child: Icon(
                icon, 
                color: isActive ? Colors.white : Colors.white30, 
                size: 20
              ),
            ),
            title: Text(
              label,
              style: GoogleFonts.montserrat(
                color: isActive 
                    ? Colors.white
                    : Colors.white.withOpacity(0.5),
                fontSize: 14,
                fontWeight: isActive ? FontWeight.w800 : FontWeight.w600,
                letterSpacing: 0,
              ),
            ),
            trailing: trailing,
            onTap: onTap,
            contentPadding: const EdgeInsets.only(left: 28, right: 12),
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
