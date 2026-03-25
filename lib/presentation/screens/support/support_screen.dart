import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:lucide_icons/lucide_icons.dart';
import 'package:m4_mobile/presentation/providers/support_provider.dart';
import 'package:m4_mobile/presentation/screens/support/create_ticket_screen.dart';
import 'package:m4_mobile/presentation/screens/support/schedule_visit_screen.dart';
import 'package:m4_mobile/presentation/screens/support/help_center_screen.dart';
import 'package:m4_mobile/presentation/screens/support/support_logs_screen.dart';
import 'package:m4_mobile/core/utils/support_handlers.dart';


import 'package:m4_mobile/presentation/widgets/main_shell.dart';
import 'package:flutter_animate/flutter_animate.dart';
import 'package:intl/intl.dart';
import 'dart:ui';


class SupportScreen extends ConsumerStatefulWidget {
  const SupportScreen({super.key});

  @override
  ConsumerState<SupportScreen> createState() => _SupportScreenState();
}

class _SupportScreenState extends ConsumerState<SupportScreen> {
  @override
  void initState() {
    super.initState();
    Future.microtask(() {
      ref.read(supportProvider.notifier).fetchTickets();
      ref.read(supportProvider.notifier).fetchLogs();
    });
  }

  @override
  Widget build(BuildContext context) {
    final state = ref.watch(supportProvider);

    return Scaffold(
      backgroundColor: Colors.black,
      body: Container(
        decoration: const BoxDecoration(
          gradient: LinearGradient(
            begin: Alignment.topLeft,
            end: Alignment.bottomRight,
            colors: [Color(0xFF0F1115), Color(0xFF050505)],
          ),
        ),
        child: SafeArea(
          child: Column(
            children: [
              // Header
              _buildHeader(context),

              Expanded(
                child: RefreshIndicator(
                  onRefresh: () => ref.read(supportProvider.notifier).fetchTickets(),
                  color: Colors.black,
                  backgroundColor: Colors.white,
                  child: ListView(
                    padding: const EdgeInsets.symmetric(horizontal: 24),
                    children: [
                      const SizedBox(height: 20),
                      _buildSupportMatrix(),
                      const SizedBox(height: 40),
                      _buildOperationalLogsHeader(),
                      const SizedBox(height: 20),
                      if (state.isLoading && state.logs.isEmpty)
                        const Center(child: Padding(
                          padding: EdgeInsets.all(40.0),
                          child: CircularProgressIndicator(color: Colors.white24),
                        ))
                      else if (state.logs.isEmpty)
                        _buildEmptyState()
                      else
                        ...state.logs.take(3).map((log) => _LogPreviewItem(log: log)).toList(),
                      const SizedBox(height: 120), // Bottom padding

                    ],
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
      floatingActionButton: Padding(
        padding: const EdgeInsets.only(bottom: 90),
        child: FloatingActionButton.extended(
          onPressed: () => Navigator.push(
            context,
            MaterialPageRoute(builder: (context) => const CreateTicketScreen()),
          ),
          backgroundColor: Colors.white,
          elevation: 10,
          label: Text(
            'NEW TICKET',
            style: GoogleFonts.montserrat(
              color: Colors.black,
              fontWeight: FontWeight.w900,
              fontSize: 12,
              letterSpacing: 1.5,
            ),
          ),
          icon: const Icon(LucideIcons.plus, color: Colors.black, size: 18),
        ),
      ).animate().scale(delay: 400.ms),
    );
  }

  Widget _buildHeader(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 20),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Expanded(
            child: Row(
              children: [
                IconButton(
                  onPressed: () {
                    ref.read(navigationProvider.notifier).state = 0; // Back to Home
                  },
                  icon: const Icon(LucideIcons.chevronLeft, color: Colors.white70),
                ),
                const SizedBox(width: 4),
                Flexible(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        'SUPPORT HUB',
                        style: GoogleFonts.montserrat(
                          fontSize: 24,
                          fontWeight: FontWeight.w300,
                          color: Colors.white,
                          letterSpacing: 2,
                        ),
                        overflow: TextOverflow.ellipsis,
                      ),
                      Text(
                        'HOW CAN WE HELP?',
                        style: GoogleFonts.montserrat(
                          fontSize: 9,
                          fontWeight: FontWeight.w900,
                          color: Colors.white54,
                          letterSpacing: 4,
                        ),
                        overflow: TextOverflow.ellipsis,
                      ),
                    ],
                  ),
                ),
              ],
            ),
          ),

          Container(
            padding: const EdgeInsets.all(10),
            decoration: BoxDecoration(
              color: Colors.white.withOpacity(0.05),
              shape: BoxShape.circle,
              border: Border.all(color: Colors.white10),
            ),
            child: const Icon(LucideIcons.headphones, color: Colors.white70, size: 20),
          ),
        ],
      ),
    ).animate().fadeIn().slideX(begin: -0.1);
  }

  Widget _buildSupportMatrix() {
    return GridView.count(
      shrinkWrap: true,
      physics: const NeverScrollableScrollPhysics(),
      crossAxisCount: 2,
      crossAxisSpacing: 16,
      mainAxisSpacing: 16,
      childAspectRatio: 1.2,
      children: [
        _MatrixItem(
          icon: LucideIcons.messageCircle,
          title: 'WhatsApp Support',
          subtitle: 'Instant help via WhatsApp',
          color: Colors.greenAccent,
          onTap: SupportHandlers.launchWhatsApp,
        ),
        _MatrixItem(
          icon: LucideIcons.calendar,
          title: 'Schedule Visit',
          subtitle: 'Book a site tour',
          color: Colors.blueAccent,
          onTap: () {
            Navigator.push(
              context,
              MaterialPageRoute(builder: (context) => const ScheduleVisitScreen()),
            );
          },
        ),
        _MatrixItem(
          icon: LucideIcons.phone,
          title: 'Call Us',
          subtitle: 'Speak with our support team',
          color: Colors.orangeAccent,
          onTap: SupportHandlers.launchCall,
        ),
        _MatrixItem(
          icon: LucideIcons.helpCircle,
          title: 'Help Center',
          subtitle: 'Read our FAQs & Guides',
          color: Colors.purpleAccent,
          onTap: () {
            Navigator.push(
              context,
              MaterialPageRoute(builder: (context) => const HelpCenterScreen()),
            );
          },
        ),



      ],
    ).animate().fadeIn(delay: 200.ms).scale(begin: const Offset(0.9, 0.9));
  }

  Widget _buildOperationalLogsHeader() {
    return Row(
      mainAxisAlignment: MainAxisAlignment.spaceBetween,
      crossAxisAlignment: CrossAxisAlignment.end,
      children: [
        Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              'OPERATIONAL LOGS',
              style: GoogleFonts.montserrat(
                fontSize: 12,
                fontWeight: FontWeight.w900,
                color: Colors.white70,
                letterSpacing: 2,
              ),
            ),
            const SizedBox(height: 4),
            Container(
              width: 40,
              height: 2,
              color: Colors.white24,
            ),
          ],
        ),
        GestureDetector(
          onTap: () {
            Navigator.push(
              context,
              MaterialPageRoute(builder: (context) => const SupportLogsScreen()),
            );
          },
          child: Text(
            'VIEW ALL LOGS',
            style: GoogleFonts.montserrat(
              fontSize: 9,
              fontWeight: FontWeight.w900,
              color: Colors.white38,
              letterSpacing: 2,
            ),
          ),
        ),
      ],
    );
  }

  Widget _buildEmptyState() {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.symmetric(vertical: 48, horizontal: 24),
      decoration: BoxDecoration(
        color: Colors.white.withOpacity(0.02),
        borderRadius: BorderRadius.circular(24),
        border: Border.all(color: Colors.white.withOpacity(0.05)),
      ),
      child: Center(
        child: Text(
          'No active tickets.',
          style: GoogleFonts.montserrat(
            fontSize: 13,
            fontWeight: FontWeight.w500,
            color: Colors.white24,
          ),
        ),
      ),
    ).animate().fadeIn();
  }

}

class _MatrixItem extends StatelessWidget {
  final IconData icon;
  final String title;
  final String subtitle;
  final Color color;
  final VoidCallback onTap;

  const _MatrixItem({
    required this.icon,
    required this.title,
    required this.subtitle,
    required this.color,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onTap,
      behavior: HitTestBehavior.opaque,
      child: ClipRRect(
        borderRadius: BorderRadius.circular(24),
        child: BackdropFilter(
          filter: ImageFilter.blur(sigmaX: 10, sigmaY: 10),
          child: Container(
            padding: const EdgeInsets.all(20),
            decoration: BoxDecoration(
              color: Colors.white.withOpacity(0.03),
              borderRadius: BorderRadius.circular(24),
              border: Border.all(color: Colors.white.withOpacity(0.08)),
            ),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Icon(icon, color: color, size: 28),
                const SizedBox(height: 16),
                Text(
                  title,
                  style: GoogleFonts.montserrat(
                    color: Colors.white,
                    fontWeight: FontWeight.w700,
                    fontSize: 13,
                  ),
                ),
                const SizedBox(height: 4),
                Text(
                  subtitle,
                  style: GoogleFonts.montserrat(
                    color: Colors.white38,
                    fontSize: 9,
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}


class _LogPreviewItem extends StatelessWidget {
  final dynamic log;

  const _LogPreviewItem({required this.log});

  @override
  Widget build(BuildContext context) {
    return Container(
      margin: const EdgeInsets.only(bottom: 12),
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: Colors.white.withOpacity(0.04),
        borderRadius: BorderRadius.circular(24),
        border: Border.all(color: Colors.white.withOpacity(0.05)),
      ),
      child: Row(
        children: [
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  children: [
                    Container(
                      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                      decoration: BoxDecoration(
                        color: Colors.blueAccent.withOpacity(0.1),
                        borderRadius: BorderRadius.circular(6),
                      ),
                      child: Text(
                        log.displayId,
                        style: GoogleFonts.montserrat(
                          color: Colors.blueAccent,
                          fontSize: 8,
                          fontWeight: FontWeight.w900,
                        ),
                      ),
                    ),
                    const SizedBox(width: 8),
                    Text(
                      log.title.toUpperCase(),
                      style: GoogleFonts.montserrat(
                        color: Colors.white,
                        fontWeight: FontWeight.w700,
                        fontSize: 13,
                      ),
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                    ),
                  ],
                ),
                const SizedBox(height: 12),
                Row(
                  children: [
                    const Icon(LucideIcons.clock, size: 12, color: Colors.white24),
                    const SizedBox(width: 6),
                    Text(
                      _getTimeAgo(log.createdAt).toUpperCase(),
                      style: GoogleFonts.montserrat(
                        color: Colors.white24,
                        fontSize: 9,
                        fontWeight: FontWeight.w900,
                      ),
                    ),
                  ],
                ),
              ],
            ),
          ),
          _buildStatusBadge(log.status),
        ],
      ),
    );
  }

  Widget _buildStatusBadge(String status) {
    final bool isPositive = ['completed', 'verified', 'success', 'sent'].contains(status.toLowerCase());
    final color = isPositive ? Colors.greenAccent : Colors.blueAccent;
    
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
      decoration: BoxDecoration(
        color: color.withOpacity(0.1),
        borderRadius: BorderRadius.circular(8),
      ),
      child: Text(
        status.toUpperCase(),
        style: GoogleFonts.montserrat(
          color: color,
          fontSize: 8,
          fontWeight: FontWeight.w900,
        ),
      ),
    );
  }

  String _getTimeAgo(DateTime dateTime) {
    final duration = DateTime.now().difference(dateTime);
    if (duration.inMinutes < 60) return '${duration.inMinutes} mins ago';
    if (duration.inHours < 24) return '${duration.inHours} hours ago';
    return DateFormat('MMM d').format(dateTime);
  }
}

