import 'dart:ui';
import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:lucide_icons/lucide_icons.dart';
import 'package:m4_mobile/presentation/screens/careers/job_apply_screen.dart';
import 'package:m4_mobile/presentation/widgets/conditional_drawer.dart';

import 'package:flutter_riverpod/flutter_riverpod.dart';

class JobDetailScreen extends ConsumerStatefulWidget {
  final Map<String, dynamic> job;

  const JobDetailScreen({super.key, required this.job});

  @override
  ConsumerState<JobDetailScreen> createState() => _JobDetailScreenState();
}

class _JobDetailScreenState extends ConsumerState<JobDetailScreen> {
  @override
  Widget build(BuildContext context) {
    final job = widget.job;
    final isDark = Theme.of(context).brightness == Brightness.dark;
    return Scaffold(
      backgroundColor: isDark ? Colors.black : Colors.white,
      extendBodyBehindAppBar: true,
      appBar: AppBar(
        centerTitle: true,
        title: Column(
          crossAxisAlignment: CrossAxisAlignment.center,
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
                fontWeight: FontWeight.w400,
                fontSize: 8,
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
        leadingWidth: 56,
        leading: Center(
          child: Padding(
            padding: const EdgeInsets.only(left: 12),
            child: InkWell(
              onTap: () => Navigator.pop(context),
              borderRadius: BorderRadius.circular(12),
              child: Container(
                width: 36,
                height: 36,
                alignment: Alignment.center,
                decoration: BoxDecoration(
                  color: (isDark ? Colors.white : Colors.black).withOpacity(0.05),
                  borderRadius: BorderRadius.circular(12),
                  border: Border.all(color: (isDark ? Colors.white : Colors.black).withOpacity(0.08)),
                ),
                child: Icon(LucideIcons.arrowLeft, color: isDark ? Colors.white : Colors.black, size: 16),
              ),
            ),
          ),
        ),
        actions: [
          Builder(
            builder: (context) => Center(
              child: Padding(
                padding: const EdgeInsets.only(right: 12),
                child: InkWell(
                  onTap: () => Scaffold.of(context).openDrawer(),
                  borderRadius: BorderRadius.circular(12),
                  child: Container(
                    width: 40,
                    height: 36,
                    alignment: Alignment.center,
                    decoration: BoxDecoration(
                      color: isDark ? Colors.white : Colors.black,
                      borderRadius: BorderRadius.circular(12),
                    ),
                    child: Icon(LucideIcons.moreHorizontal, size: 18, color: isDark ? Colors.black : Colors.white),
                  ),
                ),
              ),
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
                          color: isDark ? Colors.white70 : Colors.black87,
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
                        height: 0.95,
                      ),
                    ),
                    const SizedBox(height: 32),

                    // Meta Info
                    Row(
                      children: [
                        _buildMetaBadge(LucideIcons.mapPin, (job['location'] ?? 'Mumbai').toString(), isDark),
                        const SizedBox(width: 12),
                        if ((job['salary'] ?? '').toString().isNotEmpty)
                          Flexible(
                            child: _buildMetaBadge(LucideIcons.dollarSign, job['salary'].toString(), isDark),
                          ),
                      ],
                    ),
                    const SizedBox(height: 48),

                    // Job Description
                    Text(
                      'ROLE OVERVIEW',
                      style: GoogleFonts.montserrat(
                        color: (isDark ? Colors.white : Colors.black).withOpacity(0.6),
                        fontSize: 10,
                        fontWeight: FontWeight.w900,
                        letterSpacing: 3,
                      ),
                    ),
                    const SizedBox(height: 24),
                    Text(
                      (job['description'] ?? '').toString(),
                      style: GoogleFonts.montserrat(
                        color: (isDark ? Colors.white : Colors.black).withOpacity(0.85),
                        fontSize: 13,
                        fontWeight: FontWeight.w500,
                        height: 1.8,
                      ),
                    ),
                    const SizedBox(height: 48),

                    // Responsibilities
                    if (job['responsibilities'] != null && (job['responsibilities'] as List).isNotEmpty) ...[
                      _buildSectionHeader('KEY RESPONSIBILITIES', isDark),
                      const SizedBox(height: 24),
                      ...((job['responsibilities'] as List).map((item) => _buildListItem(item.toString(), isDark))),
                      const SizedBox(height: 48),
                    ],

                    // Requirements (web matching tag badges)
                    if (job['requirements'] != null && (job['requirements'] as List).isNotEmpty) ...[
                      _buildSectionHeader('REQUIREMENTS', isDark),
                      const SizedBox(height: 24),
                      Wrap(
                        spacing: 8,
                        runSpacing: 8,
                        children: (job['requirements'] as List)
                            .map((item) => Container(
                                  padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 10),
                                  decoration: BoxDecoration(
                                    color: isDark ? Colors.white : Colors.black,
                                    borderRadius: BorderRadius.circular(10),
                                    boxShadow: [
                                      BoxShadow(
                                        color: Colors.black.withOpacity(0.15),
                                        blurRadius: 10,
                                        offset: const Offset(0, 4),
                                      ),
                                    ],
                                  ),
                                  child: Text(
                                    item.toString().toUpperCase(),
                                    style: GoogleFonts.montserrat(
                                      color: isDark ? Colors.black : Colors.white,
                                      fontWeight: FontWeight.w900,
                                      fontSize: 9,
                                      letterSpacing: 1.5,
                                    ),
                                  ),
                                ))
                            .toList(),
                      ),
                      const SizedBox(height: 48),
                    ],

                    // Benefits
                    if (job['benefits'] != null && (job['benefits'] as List).isNotEmpty) ...[
                      _buildSectionHeader('WHY JOIN US?', isDark),
                      const SizedBox(height: 24),
                      GridView.builder(
                        shrinkWrap: true,
                        physics: const NeverScrollableScrollPhysics(),
                        gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
                          crossAxisCount: 2,
                          crossAxisSpacing: 16,
                          mainAxisSpacing: 16,
                          childAspectRatio: 1.5,
                        ),
                        itemCount: (job['benefits'] as List).length,
                        itemBuilder: (context, index) {
                          return _buildBenefitCard((job['benefits'] as List)[index].toString(), isDark);
                        },
                      ),
                      const SizedBox(height: 48),
                    ],

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

  Widget _buildSectionHeader(String title, bool isDark) {
    return Text(
      title,
      style: GoogleFonts.montserrat(
        color: (isDark ? Colors.white : Colors.black).withOpacity(0.6),
        fontSize: 10,
        fontWeight: FontWeight.w900,
        letterSpacing: 3,
      ),
    );
  }

  Widget _buildListItem(String text, bool isDark) {
    final colorScheme = Theme.of(context).colorScheme;
    return Padding(
      padding: const EdgeInsets.only(bottom: 20),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Container(
            width: 20,
            height: 20,
            decoration: BoxDecoration(
              color: colorScheme.primary.withOpacity(0.1),
              shape: BoxShape.circle,
            ),
            child: Center(
              child: Icon(LucideIcons.checkCircle2, color: colorScheme.primary, size: 14),
            ),
          ),
          const SizedBox(width: 16),
          Expanded(
            child: Text(
              text,
              style: GoogleFonts.inter(
                color: (isDark ? Colors.white : Colors.black).withOpacity(0.8),
                fontSize: 13,
                fontWeight: FontWeight.w600,
                height: 1.5,
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildRequirementBullet(String text, bool isDark) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 20),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Small accent dot (matches web: w-1.5 h-1.5 rounded-full bg-accent/50 mt-2)
          Container(
            margin: const EdgeInsets.only(top: 8, left: 4, right: 16),
            width: 6,
            height: 6,
            decoration: BoxDecoration(
              color: (isDark ? Colors.white : Colors.black).withValues(alpha: 0.5),
              shape: BoxShape.circle,
            ),
          ),
          Expanded(
            child: Text(
              text,
              style: GoogleFonts.montserrat(
                color: (isDark ? Colors.white : Colors.black).withValues(alpha: 0.8),
                fontSize: 13,
                fontWeight: FontWeight.w500,
                height: 1.5,
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildBenefitCard(String text, bool isDark) {
    return Container(
      padding: const EdgeInsets.all(24),
      decoration: BoxDecoration(
        color: (isDark ? Colors.white : Colors.black).withOpacity(0.04),
        borderRadius: BorderRadius.circular(24),
        border: Border.all(color: (isDark ? Colors.white : Colors.black).withOpacity(0.05)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Container(
            padding: const EdgeInsets.all(8),
            decoration: BoxDecoration(
              color: (isDark ? Colors.white : Colors.black).withOpacity(0.05),
              shape: BoxShape.circle,
            ),
            child: Icon(LucideIcons.heart, color: isDark ? Colors.white70 : Colors.black87, size: 14),
          ),
          const SizedBox(height: 16),
          Text(
            text.toUpperCase(),
            style: GoogleFonts.montserrat(
              color: isDark ? Colors.white : Colors.black,
              fontSize: 10,
              fontWeight: FontWeight.w900,
              letterSpacing: 1,
            ),
            maxLines: 2,
            overflow: TextOverflow.ellipsis,
          ),
        ],
      ),
    );
  }

  Widget _buildMetaBadge(IconData icon, String text, bool isDark) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
      decoration: BoxDecoration(
        color: (isDark ? Colors.white : Colors.black).withOpacity(0.05),
        border: Border.all(color: (isDark ? Colors.white : Colors.black).withOpacity(0.1)),
        borderRadius: BorderRadius.circular(20),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(icon, color: isDark ? Colors.white70 : Colors.black54, size: 14),
          const SizedBox(width: 8),
          Flexible(
            child: Text(
              text.toUpperCase(),
              maxLines: 1,
              overflow: TextOverflow.ellipsis,
              style: GoogleFonts.montserrat(
                color: isDark ? Colors.white70 : Colors.black54,
                fontSize: 9,
                fontWeight: FontWeight.w900,
                letterSpacing: 1.5,
              ),
            ),
          ),
        ],
      ),
    );
  }
}
