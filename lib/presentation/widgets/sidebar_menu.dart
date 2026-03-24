import 'package:flutter/material.dart';
import 'package:m4_mobile/core/theme/app_theme.dart';
import 'package:lucide_icons/lucide_icons.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:flutter_animate/flutter_animate.dart';
import 'dart:ui';

import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:m4_mobile/presentation/widgets/main_shell.dart';

class SidebarMenu extends ConsumerWidget {
  const SidebarMenu({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
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
          // Solid/Glass Background (Match Web Portal Image 3)
          BackdropFilter(
            filter: ImageFilter.blur(sigmaX: 50, sigmaY: 50),
            child: Container(
              color: const Color(0xFF070708).withOpacity(0.98), // Near solid Zinc-950
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
                          color: Colors.white.withOpacity(0.05),
                          borderRadius: BorderRadius.circular(10),
                          border: Border.all(color: Colors.white10),
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
                        label: 'Communities',
                        isActive: currentIndex == 1,
                        onTap: () => navigateTo(1),
                      ),
                      _SidebarItem(
                        icon: LucideIcons.layoutGrid,
                        label: 'Properties',
                        isActive: currentIndex == 1, // Could also map to 1
                        onTap: () => navigateTo(1),
                      ),
                      _SidebarItem(icon: LucideIcons.sparkles, label: 'Custom Views'),
                      _SidebarItem(icon: LucideIcons.fileText, label: 'Selection Logs'),
                      _SidebarItem(icon: LucideIcons.bell, label: 'Notifications'),
                      _SidebarItem(icon: LucideIcons.headphones, label: 'Support'),
                      _SidebarItem(icon: LucideIcons.info, label: 'Who we are'),
                      _SidebarItem(icon: LucideIcons.phoneCall, label: 'Contact Us'),
                      _SidebarItem(icon: LucideIcons.briefcase, label: 'Careers'),
                      _SidebarItem(icon: LucideIcons.trendingUp, label: 'Investor Relations'),
                      _SidebarItem(icon: LucideIcons.layers, label: 'Pages'),
                      
                      const SizedBox(height: 32),
                      Padding(
                        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
                        child: Text(
                          'QUICK ACTIONS',
                          style: GoogleFonts.montserrat(
                            color: Colors.white38,
                            fontSize: 10,
                            fontWeight: FontWeight.bold,
                            letterSpacing: 3,
                          ),
                        ),
                      ),
                      _SidebarItem(icon: LucideIcons.mail, label: 'Enquiry'),
                      _SidebarItem(icon: LucideIcons.phone, label: 'Call'),
                      _SidebarItem(icon: LucideIcons.messageSquare, label: 'Whatsapp'),
                      _SidebarItem(icon: LucideIcons.helpCircle, label: 'About'),
                    ],
                  ),
                ),

                // Footer / Exit Button (Web Portal Red Border Style)
                GestureDetector(
                  onTap: () {
                    showDialog(
                      context: context,
                      builder: (context) => AlertDialog(
                        backgroundColor: const Color(0xFF18181B),
                        title: const Text('Exit App', style: TextStyle(color: Colors.white)),
                        content: const Text('Are you sure you want to logout?', style: TextStyle(color: Colors.white70)),
                        actions: [
                          TextButton(onPressed: () => Navigator.pop(context), child: const Text('CANCEL')),
                          TextButton(
                            onPressed: () {
                              Navigator.pop(context); // Close dialog
                              Navigator.pop(context); // Close drawer
                              ScaffoldMessenger.of(context).showSnackBar(
                                const SnackBar(content: Text('Logged out successfully')),
                              );
                            }, 
                            child: const Text('LOGOUT', style: TextStyle(color: Colors.redAccent))
                          ),
                        ],
                      ),
                    );
                  },
                  child: Padding(
                    padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 40),
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
                            'EXIT APP',
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
    this.isActive = false,
    this.onTap,
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
                color: isActive ? Colors.white : Colors.white54,
                fontSize: 15,
                fontWeight: isActive ? FontWeight.w700 : FontWeight.w500,
                letterSpacing: 0.8,
              ),
            ),
            onTap: onTap,
            contentPadding: const EdgeInsets.only(left: 28, right: 12),
            visualDensity: VisualDensity.compact,
          ),
        ],
      ),
    );
  }
}
