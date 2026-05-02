import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:lucide_icons/lucide_icons.dart';
import 'package:m4_mobile/core/theme/app_theme.dart';
import 'package:flutter_animate/flutter_animate.dart';
import 'package:m4_mobile/presentation/screens/booking/site_visit_screen.dart';
import 'package:m4_mobile/presentation/screens/booking/payment_plan_screen.dart';
import 'package:m4_mobile/presentation/screens/booking/inquiry_screen.dart';
import 'package:m4_mobile/presentation/screens/more/about_screen.dart';

class BookingStartScreen extends ConsumerWidget {
  final dynamic project;
  final String projectId;

  const BookingStartScreen({
    super.key,
    required this.projectId,
    this.project,
  });

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final projectTitle = project?['title'] ?? 'Project';

    final List<Map<String, dynamic>> options = [
      {
        'id': 'inquiry',
        'title': 'SEND INQUIRY',
        'desc': 'Get detailed brochure and pricing via email/WhatsApp.',
        'icon': LucideIcons.messageSquare,
        'color': const Color(0xFF3B82F6),
      },
      {
        'id': 'site-visit',
        'title': 'SCHEDULE SITE VISIT',
        'desc': 'Book a personalized tour with our project manager.',
        'icon': LucideIcons.calendar,
        'color': const Color(0xFF10B981),
      },
      {
        'id': 'token',
        'title': 'TOKEN BOOKING',
        'desc': 'Lock your preferred unit with a refundable token amount.',
        'icon': LucideIcons.creditCard,
        'color': const Color(0xFFF59E0B),
      }
    ];

    return Scaffold(
      backgroundColor: isDark ? const Color(0xFF0F1115) : Colors.white,
      body: Stack(
        children: [
          // Background accents
          Positioned(
            top: -100,
            right: -100,
            child: Container(
              width: 300,
              height: 300,
              decoration: BoxDecoration(
                color: M4Theme.premiumBlue.withOpacity(0.05),
                shape: BoxShape.circle,
              ),
            ),
          ).animate().fadeIn(duration: 1000.ms),
          
          SafeArea(
            child: SingleChildScrollView(
              padding: const EdgeInsets.symmetric(horizontal: 32, vertical: 24),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  // Back Button
                  GestureDetector(
                    onTap: () => Navigator.pop(context),
                    child: Container(
                      width: 56,
                      height: 56,
                      decoration: BoxDecoration(
                        color: isDark ? Colors.white.withOpacity(0.05) : Colors.white,
                        borderRadius: BorderRadius.circular(20),
                        border: Border.all(color: isDark ? Colors.white.withOpacity(0.1) : Colors.black.withOpacity(0.05)),
                        boxShadow: isDark ? [] : [BoxShadow(color: Colors.black.withOpacity(0.05), blurRadius: 20, offset: const Offset(0, 10))],
                      ),
                      child: Icon(LucideIcons.arrowLeft, color: isDark ? Colors.white : Colors.black, size: 24),
                    ),
                  ),
                  
                  const SizedBox(height: 48),
                  
                  // Header
                  Text(
                    'HOW CAN\nWE HELP?',
                    style: GoogleFonts.montserrat(
                      fontSize: 36, 
                      fontWeight: FontWeight.w900, 
                      color: isDark ? Colors.white : Colors.black,
                      height: 0.9,
                      letterSpacing: -2,
                    ),
                  ).animate().fadeIn(delay: 200.ms).moveY(begin: 20, end: 0),
                  
                  const SizedBox(height: 16),
                  
                  Text(
                    'INTERESTED IN ${projectTitle.toUpperCase()}?\nCHOOSE HOW YOU\'D LIKE TO PROCEED.',
                    style: GoogleFonts.montserrat(
                      fontSize: 10, 
                      color: isDark ? Colors.white38 : Colors.black38, 
                      fontWeight: FontWeight.w900, 
                      letterSpacing: 2.5,
                      height: 1.8,
                    ),
                  ).animate().fadeIn(delay: 400.ms).moveY(begin: 10, end: 0),
                  
                  const SizedBox(height: 56),
                  
                  // Options
                  ...options.asMap().entries.map((entry) {
                    final i = entry.key;
                    final opt = entry.value;
                    return Padding(
                      padding: const EdgeInsets.only(bottom: 20),
                      child: _BookingOptionCard(
                        opt: opt,
                        isDark: isDark,
                        onTap: () {
                          if (opt['id'] == 'inquiry') {
                            Navigator.push(
                              context,
                              MaterialPageRoute(
                                builder: (context) => InquiryScreen(
                                  projectId: projectId,
                                  project: project,
                                ),
                              ),
                            );
                          } else if (opt['id'] == 'site-visit') {
                            Navigator.push(
                              context,
                              MaterialPageRoute(
                                builder: (context) => SiteVisitScreen(
                                  projectId: projectId,
                                  project: project,
                                ),
                              ),
                            );
                          } else if (opt['id'] == 'token') {
                            Navigator.push(
                              context,
                              MaterialPageRoute(
                                builder: (context) => PaymentPlanScreen(
                                  projectId: projectId,
                                  project: project,
                                ),
                              ),
                            );
                          }
                        },
                      ),
                    ).animate().fadeIn(delay: (600 + (i * 100)).ms).moveX(begin: -20, end: 0);
                  }),
                  
                  const SizedBox(height: 40),
                  
                  // Info Box
                  Container(
                    padding: const EdgeInsets.all(24),
                    decoration: BoxDecoration(
                      color: M4Theme.premiumBlue.withOpacity(0.05),
                      borderRadius: BorderRadius.circular(24),
                      border: Border.all(color: M4Theme.premiumBlue.withOpacity(0.1)),
                    ),
                    child: Row(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Container(
                          width: 40,
                          height: 40,
                          decoration: BoxDecoration(
                            color: M4Theme.premiumBlue,
                            borderRadius: BorderRadius.circular(12),
                            boxShadow: [BoxShadow(color: M4Theme.premiumBlue.withOpacity(0.3), blurRadius: 10, offset: const Offset(0, 4))],
                          ),
                          child: const Icon(LucideIcons.info, color: Colors.white, size: 20),
                        ),
                        const SizedBox(width: 20),
                        Expanded(
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Text(
                                'M4 FAMILY MEMBERS GET PRIORITY SITE VISITS AND EXCLUSIVE UNIT SELECTION WINDOWS.',
                                style: GoogleFonts.montserrat(
                                  fontSize: 9, 
                                  fontWeight: FontWeight.w900, 
                                  color: isDark ? Colors.white60 : Colors.black54, 
                                  letterSpacing: 0.5,
                                  height: 1.6,
                                ),
                              ),
                              const SizedBox(height: 8),
                              GestureDetector(
                                onTap: () => Navigator.push(
                                  context,
                                  MaterialPageRoute(builder: (context) => const AboutScreen()),
                                ),
                                child: Text(
                                  'LEARN MORE',
                                  style: GoogleFonts.montserrat(
                                    fontSize: 10, 
                                    fontWeight: FontWeight.w900, 
                                    color: M4Theme.premiumBlue, 
                                    letterSpacing: 1,
                                    decoration: TextDecoration.underline,
                                  ),
                                ),
                              ),
                            ],
                          ),
                        ),
                      ],
                    ),
                  ).animate().fadeIn(delay: 1000.ms).scale(begin: const Offset(0.95, 0.95), end: const Offset(1, 1)),
                  
                  const SizedBox(height: 64),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }
}

class _BookingOptionCard extends StatelessWidget {
  final Map<String, dynamic> opt;
  final bool isDark;
  final VoidCallback onTap;

  const _BookingOptionCard({required this.opt, required this.isDark, required this.onTap});

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        padding: const EdgeInsets.all(20),
        decoration: BoxDecoration(
          color: isDark ? Colors.white.withOpacity(0.02) : Colors.white,
          borderRadius: BorderRadius.circular(24),
          border: Border.all(color: isDark ? Colors.white.withOpacity(0.05) : Colors.black.withOpacity(0.05)),
          boxShadow: isDark ? [] : [BoxShadow(color: Colors.black.withOpacity(0.04), blurRadius: 20, offset: const Offset(0, 10))],
        ),
        child: Row(
          children: [
            Container(
              width: 52,
              height: 52,
              decoration: BoxDecoration(
                color: (opt['color'] as Color).withOpacity(0.1),
                borderRadius: BorderRadius.circular(16),
              ),
              child: Icon(opt['icon'] as IconData, color: opt['color'] as Color, size: 24),
            ),
            const SizedBox(width: 20),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    opt['title'],
                    style: GoogleFonts.montserrat(fontSize: 12, fontWeight: FontWeight.w900, color: isDark ? Colors.white : Colors.black, letterSpacing: 0.5),
                  ),
                  const SizedBox(height: 4),
                  Text(
                    opt['desc'],
                    style: GoogleFonts.montserrat(fontSize: 9, color: isDark ? Colors.white38 : Colors.black38, fontWeight: FontWeight.bold, height: 1.4),
                  ),
                ],
              ),
            ),
            const SizedBox(width: 12),
            Container(
              width: 32,
              height: 32,
              decoration: BoxDecoration(
                color: isDark ? Colors.white.withOpacity(0.05) : Colors.black.withOpacity(0.05),
                shape: BoxShape.circle,
              ),
              child: Icon(LucideIcons.chevronRight, color: isDark ? Colors.white38 : Colors.black38, size: 16),
            ),
          ],
        ),
      ),
    );
  }
}
