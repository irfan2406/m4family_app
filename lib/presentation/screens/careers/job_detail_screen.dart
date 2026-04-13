import 'dart:ui';
import 'package:m4_mobile/core/theme/app_theme.dart';
import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:lucide_icons/lucide_icons.dart';
import 'package:flutter_animate/flutter_animate.dart';
import 'package:m4_mobile/presentation/screens/careers/job_apply_screen.dart';
import 'package:m4_mobile/presentation/widgets/conditional_drawer.dart';

class JobDetailScreen extends StatelessWidget {
  final Map<String, dynamic> job;

  const JobDetailScreen({super.key, required this.job});

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    return Scaffold(
      backgroundColor: isDark ? Colors.black : Colors.white,
      extendBodyBehindAppBar: true,
      appBar: AppBar(
        title: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              (job['title'] ?? '').toString().toUpperCase(),
              style: GoogleFonts.montserrat(
                color: isDark ? Colors.white : Colors.black,
                fontWeight: FontWeight.bold,
                fontSize: 14,
                letterSpacing: 0.5,
              ),
              overflow: TextOverflow.ellipsis,
            ),
            const SizedBox(height: 2),
            Text(
              (job['department'] ?? '').toString().toUpperCase(),
              style: GoogleFonts.montserrat(
                color: (isDark ? Colors.white : Colors.black).withOpacity(0.5),
                fontWeight: FontWeight.w900,
                fontSize: 9,
                letterSpacing: 2,
              ),
            ),
          ],
        ),
        backgroundColor: (isDark ? Colors.black : Colors.white).withOpacity(0.8),
        flexibleSpace: ClipRRect(
          child: BackdropFilter(
            filter: ImageFilter.blur(sigmaX: 10, sigmaY: 10),
            child: Container(color: Colors.transparent),
          ),
        ),
        elevation: 0,
        leading: IconButton(
          icon: Icon(LucideIcons.arrowLeft, color: isDark ? Colors.white70 : Colors.black54),
          onPressed: () => Navigator.pop(context),
        ),
        actions: [
          Builder(
            builder: (context) => IconButton(
              icon: Icon(LucideIcons.moreHorizontal, color: isDark ? Colors.white : Colors.black),
              onPressed: () => Scaffold.of(context).openDrawer(),
            ),
          ),
        ],
      ),
      drawer: const ConditionalDrawer(),
      body: Container(
        padding: const EdgeInsets.only(top: 120),
        decoration: BoxDecoration(
          color: isDark ? Colors.black : Colors.white,
          gradient: isDark ? const RadialGradient(
            center: Alignment.topCenter,
            radius: 2.0,
            colors: [Color(0xFF0F1115), Colors.black],
          ) : null,
        ),
        child: Column(
          children: [
            Expanded(
              child: SingleChildScrollView(
                padding: const EdgeInsets.symmetric(horizontal: 24),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    // Department Badge
                    Container(
                      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 6),
                      decoration: BoxDecoration(
                        color: (isDark ? Colors.white : Colors.black).withOpacity(0.08),
                        borderRadius: BorderRadius.circular(20),
                        border: Border.all(color: (isDark ? Colors.white : Colors.black).withOpacity(0.1)),
                      ),
                      child: Text(
                        (job['department'] ?? '').toString().toUpperCase(),
                        style: GoogleFonts.montserrat(
                          color: Colors.white70,
                          fontSize: 9,
                          fontWeight: FontWeight.w900,
                          letterSpacing: 2,
                        ),
                      ),
                    ),
                    const SizedBox(height: 24),

                    // Job Title
                    Text(
                      (job['title'] ?? '').toString().toUpperCase(),
                      style: GoogleFonts.montserrat(
                        color: isDark ? Colors.white : Colors.black,
                        fontWeight: FontWeight.w900,
                        fontSize: 32,
                        letterSpacing: -1.5,
                        height: 1.1,
                      ),
                    ),
                    const SizedBox(height: 32),

                    // Meta Info
                    Row(
                      children: [
                        _buildMetaBadge(LucideIcons.mapPin, (job['location'] ?? 'Mumbai').toString()),
                        const SizedBox(width: 12),
                        _buildMetaBadge(LucideIcons.clock, (job['type'] ?? 'Full-time').toString()),
                      ],
                    ),
                    const SizedBox(height: 48),

                    // Job Description Toggle
                    Text(
                      'JOB DESCRIPTION',
                      style: GoogleFonts.montserrat(
                        color: (isDark ? Colors.white : Colors.black).withOpacity(0.5),
                        fontSize: 10,
                        fontWeight: FontWeight.w900,
                        letterSpacing: 3,
                      ),
                    ),
                    const SizedBox(height: 24),

                    // Description Content
                    Container(
                      padding: const EdgeInsets.all(32),
                      decoration: BoxDecoration(
                        color: (isDark ? Colors.white : Colors.black).withOpacity(0.04),
                        borderRadius: BorderRadius.circular(40),
                        border: Border.all(color: (isDark ? Colors.white : Colors.black).withOpacity(0.05)),
                      ),
                      child: Text(
                        (job['description'] ?? 'WE ARE LOOKING FOR A HIGH-PERFORMING ${job['title']} TO HELP US MEET OUR CUSTOMER ACQUISITION AND REVENUE GROWTH TARGETS BY KEEPING OUR COMPANY COMPETITIVE AND INNOVATIVE.').toString(),
                        style: GoogleFonts.montserrat(
                          color: (isDark ? Colors.white : Colors.black).withOpacity(0.7),
                          fontSize: 13,
                          fontWeight: FontWeight.w500,
                          height: 1.8,
                        ),
                      ),
                    ),
                    const SizedBox(height: 120),
                  ],
                ),
              ),
            ),
          ],
        ),
      ),
      bottomSheet: Container(
        color: isDark ? Colors.black : Colors.white,
        padding: const EdgeInsets.fromLTRB(24, 16, 24, 40),
        child: SizedBox(
          width: double.infinity,
          height: 64,
          child: ElevatedButton(
            onPressed: () {
              Navigator.push(
                context,
                MaterialPageRoute(builder: (context) => JobApplyScreen(job: job)),
              );
            },
            style: ElevatedButton.styleFrom(
              backgroundColor: isDark ? Colors.white : Colors.black,
              foregroundColor: isDark ? Colors.black : Colors.white,
              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(32)),
              elevation: 20,
              shadowColor: Colors.white.withOpacity(0.2),
            ),
            child: Row(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Text(
                  'APPLY FOR THIS POSITION',
                  style: GoogleFonts.montserrat(
                    fontWeight: FontWeight.w900,
                    fontSize: 11,
                    letterSpacing: 1.5,
                  ),
                ),
                const SizedBox(width: 12),
                const Icon(LucideIcons.chevronRight, size: 16),
              ],
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildMetaBadge(IconData icon, String text) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
      decoration: BoxDecoration(
        color: Colors.white.withOpacity(0.05),
        border: Border.all(color: Colors.white.withOpacity(0.1)),
        borderRadius: BorderRadius.circular(20),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(icon, color: Colors.white70, size: 14),
          const SizedBox(width: 8),
          Text(
            text.toUpperCase(),
            style: GoogleFonts.montserrat(
              color: Colors.white70,
              fontSize: 9,
              fontWeight: FontWeight.w900,
              letterSpacing: 1.5,
            ),
          ),
        ],
      ),
    );
  }
}
