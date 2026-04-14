import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:lucide_icons/lucide_icons.dart';
import 'package:flutter_animate/flutter_animate.dart';
import 'package:m4_mobile/presentation/widgets/conditional_drawer.dart';

class GuestContentHubScreen extends StatelessWidget {
  final String title;
  final String subtitle;
  final IconData typeIcon;
  final String emptyMessage;

  const GuestContentHubScreen({
    super.key,
    required this.title,
    required this.subtitle,
    required this.typeIcon,
    required this.emptyMessage,
  });

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    
    return Scaffold(
      backgroundColor: isDark ? Colors.black : Colors.white,
      drawer: const ConditionalDrawer(),
      body: CustomScrollView(
        slivers: [
          SliverAppBar(
            floating: true,
            backgroundColor: (isDark ? Colors.black : Colors.white).withOpacity(0.9),
            surfaceTintColor: Colors.transparent,
            elevation: 0,
            leadingWidth: 80,
            leading: Padding(
              padding: const EdgeInsets.only(left: 12),
              child: Center(
                child: IconButton(
                  onPressed: () => Navigator.pop(context),
                  icon: Icon(LucideIcons.chevronLeft, color: isDark ? Colors.white : Colors.black, size: 28),
                  style: IconButton.styleFrom(
                    backgroundColor: (isDark ? Colors.white : Colors.black).withOpacity(0.04),
                    padding: EdgeInsets.zero,
                  ),
                ),
              ),
            ),
            title: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              mainAxisSize: MainAxisSize.min,
              children: [
                Text(
                  'M4 FAMILY',
                  style: GoogleFonts.montserrat(
                    fontSize: 16,
                    fontWeight: FontWeight.w400,
                    letterSpacing: -0.5,
                    color: isDark ? Colors.white : Colors.black,
                  ),
                ),
                Text(
                  'DEVELOPMENTS',
                  style: GoogleFonts.montserrat(
                    fontSize: 8,
                    fontWeight: FontWeight.w400,
                    letterSpacing: 3,
                    color: (isDark ? Colors.white : Colors.black).withOpacity(0.5),
                  ),
                ),
              ],
            ),
            actions: [
              Builder(
                builder: (context) => IconButton(
                  onPressed: () => Scaffold.of(context).openDrawer(),
                  icon: Icon(
                    LucideIcons.moreHorizontal,
                    color: isDark ? Colors.white : Colors.black,
                    size: 28,
                  ),
                ),
              ),
              const SizedBox(width: 12),
            ],
          ),

          SliverFillRemaining(
            child: Padding(
              padding: const EdgeInsets.symmetric(horizontal: 24),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  const SizedBox(height: 40),
                  
                  Container(
                    padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
                    decoration: BoxDecoration(
                      color: (isDark ? Colors.white : Colors.black).withOpacity(0.05),
                      borderRadius: BorderRadius.circular(12),
                      border: Border.all(color: (isDark ? Colors.white : Colors.black).withOpacity(0.1)),
                    ),
                    child: Row(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        Icon(typeIcon, color: isDark ? Colors.white : Colors.black, size: 16),
                        const SizedBox(width: 12),
                        Text(
                          'CONTENT HUB',
                          style: GoogleFonts.montserrat(
                            color: isDark ? Colors.white : Colors.black,
                            fontSize: 10,
                            fontWeight: FontWeight.w400,
                            letterSpacing: 1,
                          ),
                        ),
                      ],
                    ),
                  ).animate().fadeIn().slideX(begin: -0.2),

                  const SizedBox(height: 24),

                  Text(
                    title,
                    style: GoogleFonts.montserrat(
                      fontSize: 48,
                      fontWeight: FontWeight.w400,
                      letterSpacing: -2,
                      height: 0.9,
                      color: isDark ? Colors.white : Colors.black,
                    ),
                  ).animate().fadeIn().slideY(begin: 0.2),

                  const SizedBox(height: 16),

                  Text(
                    subtitle,
                    style: GoogleFonts.montserrat(
                      fontSize: 14,
                      color: (isDark ? Colors.white : Colors.black).withOpacity(0.5),
                      fontWeight: FontWeight.w500,
                    ),
                  ).animate().fadeIn(delay: 200.ms),

                  const Spacer(),

                  Center(
                    child: Column(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        Container(
                          width: 80,
                          height: 80,
                          decoration: BoxDecoration(
                            color: (isDark ? Colors.white : Colors.black).withOpacity(0.03),
                            borderRadius: BorderRadius.circular(24),
                            border: Border.all(color: (isDark ? Colors.white : Colors.black).withOpacity(0.1)),
                          ),
                          child: Icon(typeIcon, color: (isDark ? Colors.white : Colors.black).withOpacity(0.2), size: 32),
                        ),
                        const SizedBox(height: 32),
                        Text(
                          emptyMessage,
                          textAlign: TextAlign.center,
                          style: GoogleFonts.montserrat(
                            color: isDark ? Colors.white : Colors.black,
                            fontSize: 18,
                            fontWeight: FontWeight.w800,
                          ),
                        ),
                        const SizedBox(height: 12),
                        Text(
                          'We\'re working on something amazing.\nCheck back soon for fresh updates.',
                          textAlign: TextAlign.center,
                          style: GoogleFonts.montserrat(
                            color: (isDark ? Colors.white : Colors.black).withOpacity(0.4),
                            fontSize: 12,
                            height: 1.5,
                          ),
                        ),
                      ],
                    ),
                  ).animate().fadeIn(delay: 500.ms).scale(begin: const Offset(0.9, 0.9)),

                  const Spacer(flex: 2),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }
}
