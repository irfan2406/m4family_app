import 'dart:ui';
import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:lucide_icons/lucide_icons.dart';
import 'package:m4_mobile/presentation/widgets/side_menu_button.dart';
import 'package:url_launcher/url_launcher.dart';
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
      backgroundColor: Theme.of(context).scaffoldBackgroundColor,
      extendBodyBehindAppBar: true,
      appBar: AppBar(
        centerTitle: true,
        title: Column(
          crossAxisAlignment: CrossAxisAlignment.center,
          children: [
            Text(
              (job['title'] ?? '').toString().toUpperCase(),
              style: GoogleFonts.inter(
                color: isDark ? Colors.white : const Color(0xFF155A4F),
                fontWeight: FontWeight.bold,
                fontSize: 14,
                letterSpacing: 0.5,
              ),
              overflow: TextOverflow.ellipsis,
            ),
            const SizedBox(height: 2),
            Text(
              (job['department'] ?? '').toString().toUpperCase(),
              style: GoogleFonts.inter(
                color: (isDark ? Colors.white : const Color(0xFF0C312B))
                    .withOpacity(0.68),
                fontWeight: FontWeight.w400,
                fontSize: 8,
                letterSpacing: 2,
              ),
            ),
          ],
        ),
        backgroundColor: isDark
            ? const Color(0xFF0B1026)
            : Theme.of(context).scaffoldBackgroundColor,
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
                  color: (isDark ? Colors.white : const Color(0xFF0C312B))
                      .withOpacity(0.05),
                  borderRadius: BorderRadius.circular(12),
                  border: Border.all(
                    color: (isDark ? Colors.white : const Color(0xFF0C312B))
                        .withOpacity(0.08),
                  ),
                ),
                child: Icon(
                  LucideIcons.arrowLeft,
                  color: isDark ? Colors.white : const Color(0xFF0C312B),
                  size: 16,
                ),
              ),
            ),
          ),
        ),
        actions: [
          Builder(
            builder: (context) => const Center(
              child: Padding(
                padding: EdgeInsets.only(right: 12),
                child: SideMenuButton(),
              ),
            ),
          ),
        ],
      ),
      drawer: const ConditionalDrawer(),
      body: Container(
        padding: const EdgeInsets.only(top: 120),
        decoration: BoxDecoration(
          color: Theme.of(context).scaffoldBackgroundColor,
          gradient: isDark
              ? const RadialGradient(
                  center: Alignment.topCenter,
                  radius: 2.0,
                  colors: [Color(0xFF141B3A), Color(0xFF0B1026)],
                )
              : null,
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
                      padding: const EdgeInsets.symmetric(
                        horizontal: 16,
                        vertical: 6,
                      ),
                      decoration: BoxDecoration(
                        color: (isDark ? Colors.white : const Color(0xFF0C312B))
                            .withOpacity(0.08),
                        borderRadius: BorderRadius.circular(20),
                        border: Border.all(
                          color:
                              (isDark ? Colors.white : const Color(0xFF0C312B))
                                  .withOpacity(0.1),
                        ),
                      ),
                      child: Text(
                        (job['department'] ?? '').toString().toUpperCase(),
                        style: GoogleFonts.gelasio(
                          color: isDark
                              ? Colors.white70
                              : const Color(0xFF0C312B),
                          fontSize: 9,
                          fontWeight: FontWeight.w700,
                          letterSpacing: 2,
                        ),
                      ),
                    ),
                    const SizedBox(height: 24),

                    // Job Title
                    Text(
                      (job['title'] ?? '').toString().toUpperCase(),
                      style: GoogleFonts.gelasio(
                        color: isDark ? Colors.white : const Color(0xFF0C312B),
                        fontWeight: FontWeight.w700,
                        fontSize: 32,
                        letterSpacing: -1.5,
                        height: 0.95,
                      ),
                    ),
                    const SizedBox(height: 32),

                    // Meta Info — location + employment type (web parity).
                    // Both badges are Flexible so long values ellipsize safely
                    // instead of laying an inner Flexible out under unbounded
                    // constraints.
                    Row(
                      children: [
                        Flexible(
                          child: _buildMetaBadge(
                            LucideIcons.mapPin,
                            (job['location'] ?? 'Mumbai').toString(),
                            isDark,
                          ),
                        ),
                        const SizedBox(width: 12),
                        Flexible(
                          child: _buildMetaBadge(
                            LucideIcons.clock,
                            (job['type'] ??
                                    job['jobType'] ??
                                    job['employment_type'] ??
                                    'Full-Time')
                                .toString(),
                            isDark,
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 40),

                    // Job Description — inside a bordered card with gradient copy.
                    Text(
                      'JOB DESCRIPTION',
                      style: GoogleFonts.gelasio(
                        color: (isDark ? Colors.white : const Color(0xFF0C312B))
                            .withOpacity(0.9),
                        fontSize: 10,
                        fontWeight: FontWeight.w700,
                        letterSpacing: 3,
                      ),
                    ),
                    const SizedBox(height: 20),
                    Container(
                      width: double.infinity,
                      padding: const EdgeInsets.all(24),
                      decoration: BoxDecoration(
                        color: isDark
                            ? Colors.white.withOpacity(0.03)
                            : const Color(0xFFF4EFE3),
                        borderRadius: BorderRadius.circular(24),
                        border: Border.all(
                          color:
                              (isDark ? Colors.white : const Color(0xFF0C312B))
                                  .withOpacity(0.08),
                        ),
                        boxShadow: isDark
                            ? null
                            : [
                                BoxShadow(
                                  color: Colors.black.withOpacity(0.03),
                                  blurRadius: 20,
                                  offset: const Offset(0, 8),
                                ),
                              ],
                      ),
                      child: _gradientBody(
                        (job['description'] ?? '').toString(),
                        isDark,
                      ),
                    ),
                    const SizedBox(height: 40),

                    // Direct Recruitment Contact — sits directly under the
                    // description card (web parity: reference screenshot 2).
                    Text(
                      'DIRECT RECRUITMENT CONTACT',
                      style: GoogleFonts.gelasio(
                        color: (isDark ? Colors.white : const Color(0xFF0C312B))
                            .withOpacity(0.9),
                        fontSize: 10,
                        fontWeight: FontWeight.w700,
                        letterSpacing: 3,
                      ),
                    ),
                    const SizedBox(height: 20),
                    _buildRecruitmentContact(isDark),
                    const SizedBox(height: 40),

                    // Responsibilities
                    if (job['responsibilities'] != null &&
                        (job['responsibilities'] as List).isNotEmpty) ...[
                      _buildSectionHeader('KEY RESPONSIBILITIES', isDark),
                      const SizedBox(height: 24),
                      ...((job['responsibilities'] as List).map(
                        (item) => _buildListItem(item.toString(), isDark),
                      )),
                      const SizedBox(height: 48),
                    ],

                    // Requirements (web matching tag badges)
                    if (job['requirements'] != null &&
                        (job['requirements'] as List).isNotEmpty) ...[
                      _buildSectionHeader('REQUIREMENTS', isDark),
                      const SizedBox(height: 24),
                      Wrap(
                        spacing: 8,
                        runSpacing: 8,
                        children: (job['requirements'] as List)
                            .map(
                              (item) => Container(
                                padding: const EdgeInsets.symmetric(
                                  horizontal: 16,
                                  vertical: 10,
                                ),
                                decoration: BoxDecoration(
                                  color: isDark
                                      ? Colors.white
                                      : const Color(0xFF0C312B),
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
                                  style: GoogleFonts.gelasio(
                                    color: Theme.of(
                                      context,
                                    ).scaffoldBackgroundColor,
                                    fontWeight: FontWeight.w700,
                                    fontSize: 9,
                                    letterSpacing: 1.5,
                                  ),
                                ),
                              ),
                            )
                            .toList(),
                      ),
                      const SizedBox(height: 48),
                    ],

                    // Benefits
                    if (job['benefits'] != null &&
                        (job['benefits'] as List).isNotEmpty) ...[
                      _buildSectionHeader('WHY JOIN US?', isDark),
                      const SizedBox(height: 24),
                      GridView.builder(
                        shrinkWrap: true,
                        physics: const NeverScrollableScrollPhysics(),
                        gridDelegate:
                            const SliverGridDelegateWithFixedCrossAxisCount(
                              crossAxisCount: 2,
                              crossAxisSpacing: 16,
                              mainAxisSpacing: 16,
                              childAspectRatio: 1.5,
                            ),
                        itemCount: (job['benefits'] as List).length,
                        itemBuilder: (context, index) {
                          return _buildBenefitCard(
                            (job['benefits'] as List)[index].toString(),
                            isDark,
                          );
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
        color: Theme.of(context).scaffoldBackgroundColor,
        padding: const EdgeInsets.fromLTRB(24, 16, 24, 40),
        child: SizedBox(
          width: double.infinity,
          height: 64,
          child: ElevatedButton(
            onPressed: () {
              Navigator.push(
                context,
                MaterialPageRoute(
                  builder: (context) => JobApplyScreen(job: job),
                ),
              );
            },
            style: ElevatedButton.styleFrom(
              backgroundColor: isDark ? Colors.white : const Color(0xFF0C312B),
              foregroundColor: isDark ? Colors.black : const Color(0xFFF4EFE3),
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(20),
              ),
              elevation: 20,
              shadowColor: Colors.white.withOpacity(0.2),
            ),
            child: Row(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Text(
                  'APPLY FOR THIS POSITION',
                  style: GoogleFonts.gelasio(
                    fontWeight: FontWeight.w700,
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
      style: GoogleFonts.gelasio(
        color: (isDark ? Colors.white : const Color(0xFF0C312B)).withOpacity(
          0.9,
        ),
        fontSize: 10,
        fontWeight: FontWeight.w700,
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
              child: Icon(
                LucideIcons.checkCircle2,
                color: colorScheme.primary,
                size: 14,
              ),
            ),
          ),
          const SizedBox(width: 16),
          Expanded(
            child: Text(
              text,
              style: GoogleFonts.inter(
                color: (isDark ? Colors.white : const Color(0xFF0C312B))
                    .withOpacity(0.8),
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
              color: (isDark ? Colors.white : const Color(0xFF0C312B))
                  .withValues(alpha: 0.5),
              shape: BoxShape.circle,
            ),
          ),
          Expanded(
            child: Text(
              text,
              style: GoogleFonts.inter(
                color: (isDark ? Colors.white : const Color(0xFF0C312B))
                    .withValues(alpha: 0.8),
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
        color: (isDark ? Colors.white : const Color(0xFF0C312B)).withOpacity(
          0.04,
        ),
        borderRadius: BorderRadius.circular(24),
        border: Border.all(
          color: (isDark ? Colors.white : const Color(0xFF0C312B)).withOpacity(
            0.05,
          ),
        ),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Container(
            padding: const EdgeInsets.all(8),
            decoration: BoxDecoration(
              color: (isDark ? Colors.white : const Color(0xFF0C312B))
                  .withOpacity(0.05),
              shape: BoxShape.circle,
            ),
            child: Icon(
              LucideIcons.heart,
              color: isDark ? Colors.white70 : const Color(0xFF0C312B),
              size: 14,
            ),
          ),
          const SizedBox(height: 16),
          Text(
            text.toUpperCase(),
            style: GoogleFonts.inter(
              color: isDark ? Colors.white : const Color(0xFF155A4F),
              fontSize: 10,
              fontWeight: FontWeight.w600,
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
      padding: const EdgeInsets.symmetric(horizontal: 18, vertical: 13),
      decoration: BoxDecoration(
        // Web parity: white pill with a subtle border/shadow and dark content.
        color: isDark
            ? Colors.white.withOpacity(0.05)
            : const Color(0xFFF4EFE3),
        border: Border.all(
          color: (isDark ? Colors.white : const Color(0xFF0C312B)).withOpacity(
            0.1,
          ),
        ),
        borderRadius: BorderRadius.circular(16),
        boxShadow: isDark
            ? null
            : [
                BoxShadow(
                  color: Colors.black.withOpacity(0.04),
                  blurRadius: 12,
                  offset: const Offset(0, 4),
                ),
              ],
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(
            icon,
            color: isDark ? Colors.white : const Color(0xFF0C312B),
            size: 15,
          ),
          const SizedBox(width: 8),
          Flexible(
            child: Text(
              text.toUpperCase(),
              maxLines: 1,
              overflow: TextOverflow.ellipsis,
              style: GoogleFonts.inter(
                color: isDark ? Colors.white : const Color(0xFF155A4F),
                fontSize: 10,
                fontWeight: FontWeight.w500,
                letterSpacing: 1.2,
              ),
            ),
          ),
        ],
      ),
    );
  }

  // Web parity: description copy rendered with the M4 blue→gold gradient in
  // light mode; plain readable text in dark mode.
  Widget _gradientBody(String text, bool isDark) {
    final style = GoogleFonts.inter(
      fontSize: 14,
      fontWeight: FontWeight.w500,
      height: 1.7,
    );
    if (text.trim().isEmpty) {
      return Text(
        'Details for this role will be shared during the interview process.',
        style: style.copyWith(
          color: (isDark ? Colors.white : const Color(0xFF0C312B)).withOpacity(
            0.9,
          ),
        ),
      );
    }
    if (isDark) {
      return Text(
        text,
        style: style.copyWith(color: Colors.white.withOpacity(0.85)),
      );
    }
    // Solid forest green (was a left-to-right navy->cream gradient that faded
    // the last words into the cream card and made them unreadable).
    return Text(text, style: style.copyWith(color: const Color(0xFF163A2C)));
  }

  // Web parity: one card with EMAIL RECRUITMENT + CAREER HELPLINE rows.
  Widget _buildRecruitmentContact(bool isDark) {
    const email = 'HR@M4FAMILY.COM';
    const helpline = '+91 99308 50993';
    return Container(
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: isDark
            ? Colors.white.withOpacity(0.03)
            : const Color(0xFFF4EFE3),
        borderRadius: BorderRadius.circular(24),
        border: Border.all(
          color: (isDark ? Colors.white : const Color(0xFF0C312B)).withOpacity(
            0.08,
          ),
        ),
        boxShadow: isDark
            ? null
            : [
                BoxShadow(
                  color: Colors.black.withOpacity(0.03),
                  blurRadius: 20,
                  offset: const Offset(0, 8),
                ),
              ],
      ),
      child: Column(
        children: [
          _recruitRow(
            icon: LucideIcons.mail,
            label: 'EMAIL RECRUITMENT',
            value: email,
            onTap: () => _launchUrl('mailto:${email.toLowerCase()}'),
            isDark: isDark,
          ),
          const SizedBox(height: 18),
          _recruitRow(
            icon: LucideIcons.phone,
            label: 'CAREER HELPLINE',
            value: helpline,
            onTap: () => _launchUrl(
              'tel:${helpline.replaceAll(RegExp(r'[^+0-9]'), '')}',
            ),
            isDark: isDark,
          ),
        ],
      ),
    );
  }

  Widget _recruitRow({
    required IconData icon,
    required String label,
    required String value,
    required VoidCallback onTap,
    required bool isDark,
  }) {
    return GestureDetector(
      onTap: onTap,
      behavior: HitTestBehavior.opaque,
      child: Row(
        children: [
          Container(
            width: 48,
            height: 48,
            alignment: Alignment.center,
            decoration: BoxDecoration(
              color: (isDark ? Colors.white : const Color(0xFF0C312B))
                  .withOpacity(0.05),
              borderRadius: BorderRadius.circular(14),
              border: Border.all(
                color: (isDark ? Colors.white : const Color(0xFF0C312B))
                    .withOpacity(0.08),
              ),
            ),
            child: Icon(
              icon,
              color: isDark ? Colors.white : const Color(0xFF0C312B),
              size: 18,
            ),
          ),
          const SizedBox(width: 18),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  label,
                  style: GoogleFonts.gelasio(
                    color: isDark
                        ? Colors.white.withOpacity(0.85)
                        : const Color(0xFF163A2C),
                    fontSize: 10,
                    fontWeight: FontWeight.w700,
                    letterSpacing: 2,
                  ),
                ),
                const SizedBox(height: 4),
                Text(
                  value,
                  style: GoogleFonts.inter(
                    color: isDark ? Colors.white : const Color(0xFF155A4F),
                    fontSize: 15,
                    fontWeight: FontWeight.w500,
                    letterSpacing: -0.2,
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Future<void> _launchUrl(String url) async {
    final uri = Uri.parse(url);
    if (await canLaunchUrl(uri)) {
      await launchUrl(uri, mode: LaunchMode.externalApplication);
    } else if (mounted) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          backgroundColor: const Color(0xFFC65B46),
          content: Text('Could not open $url'),
        ),
      );
    }
  }
}
