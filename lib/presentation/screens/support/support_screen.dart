import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:lucide_icons/lucide_icons.dart';
import 'package:m4_mobile/presentation/providers/support_provider.dart';
import 'package:m4_mobile/presentation/screens/support/create_ticket_screen.dart';
import 'package:m4_mobile/presentation/screens/support/schedule_visit_screen.dart';
import 'package:m4_mobile/presentation/screens/support/help_center_screen.dart';
import 'package:m4_mobile/presentation/screens/support/support_tickets_screen.dart';
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
    });
  }

  @override
  Widget build(BuildContext context) {
    final state = ref.watch(supportProvider);

    return Scaffold(
      backgroundColor: Theme.of(context).scaffoldBackgroundColor,
      body: Container(
        decoration: BoxDecoration(
          color: Theme.of(context).scaffoldBackgroundColor,
        ),
        child: SafeArea(
          child: Column(
            children: [
              // Header
              _buildHeader(context),

              Expanded(
                child: RefreshIndicator(
                  onRefresh: () => ref.read(supportProvider.notifier).fetchTickets(),
                  color: Theme.of(context).colorScheme.onSurface,
                  backgroundColor: Theme.of(context).colorScheme.surface,
                  child: ListView(
                    padding: const EdgeInsets.symmetric(horizontal: 24),
                    children: [
                      const SizedBox(height: 20),
                      _buildSupportMatrix(),
                      const SizedBox(height: 40),
                      _buildOperationalLogsHeader(),
                      const SizedBox(height: 20),
                      if (state.isLoading && state.tickets.isEmpty)
                        const Center(child: Padding(
                          padding: EdgeInsets.all(40.0),
                          child: CircularProgressIndicator(color: Colors.white24),
                        ))
                      else if (state.tickets.isEmpty)
                        _buildEmptyState()
                      else
                        ...state.tickets.take(3).map((t) => _TicketPreviewItem(ticket: t)).toList(),
                      const SizedBox(height: 120), // Bottom padding

                    ],
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
      floatingActionButton: null,
    );
  }

  Widget _buildHeader(BuildContext context) {
    final scheme = Theme.of(context).colorScheme;
    final isLight = scheme.brightness == Brightness.light;
    return Padding(
      padding: const EdgeInsets.fromLTRB(24, 24, 24, 16),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Row(
            children: [
              GestureDetector(
                onTap: () {
                  if (Navigator.canPop(context)) {
                    Navigator.pop(context);
                  } else {
                    ref.read(navigationProvider.notifier).state = 0;
                  }
                },
                child: Container(
                  padding: const EdgeInsets.all(8),
                  decoration: BoxDecoration(
                    color: scheme.surfaceContainerHighest.withValues(alpha: isLight ? 0.65 : 0.25),
                    shape: BoxShape.circle,
                    border: Border.all(color: scheme.outlineVariant.withValues(alpha: 0.5)),
                  ),
                  child: Icon(LucideIcons.arrowLeft, color: scheme.onSurface, size: 16),
                ),
              ),
              const SizedBox(width: 16),
              Text(
                'SUPPORT HUB',
                style: GoogleFonts.montserrat(
                  fontSize: 18,
                  fontWeight: FontWeight.w900,
                  color: scheme.onSurface,
                  letterSpacing: 2.4,
                ),
              ),
            ],
          ),
        ],
      ),
    ).animate().fadeIn().slideY(begin: -0.1);
  }

  Widget _buildSupportMatrix() {
    final scheme = Theme.of(context).colorScheme;
    final isLight = scheme.brightness == Brightness.light;
    // web uses monochrome icons
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
          color: scheme.onSurface,
          onTap: SupportHandlers.launchWhatsApp,
        ),
        _MatrixItem(
          icon: LucideIcons.calendar,
          title: 'Schedule Visit',
          subtitle: 'Book a site tour',
          color: scheme.onSurface,
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
          color: scheme.onSurface,
          onTap: SupportHandlers.launchCall,
        ),
        _MatrixItem(
          icon: LucideIcons.helpCircle,
          title: 'Help Center',
          subtitle: 'Read our FAQs & Guides',
          color: scheme.onSurface,
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
    final scheme = Theme.of(context).colorScheme;
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
                fontSize: 10,
                fontWeight: FontWeight.w900,
                color: scheme.onSurface,
                letterSpacing: 3.2,
              ),
            ),
            const SizedBox(height: 4),
            Container(
              width: 40,
              height: 2,
              color: scheme.onSurface.withValues(alpha: 0.18),
            ),
          ],
        ),
        GestureDetector(
          onTap: () {
            Navigator.push(
              context,
              MaterialPageRoute(builder: (context) => const SupportTicketsScreen()),
            );
          },
          child: Text(
            'VIEW ALL LOGS',
            style: GoogleFonts.montserrat(
              fontSize: 9,
              fontWeight: FontWeight.w900,
              color: scheme.onSurface.withValues(alpha: 0.65),
              letterSpacing: 1.6,
            ),
          ),
        ),
      ],
    );
  }

  Widget _buildEmptyState() {
    final scheme = Theme.of(context).colorScheme;
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.symmetric(vertical: 48, horizontal: 24),
      decoration: BoxDecoration(
        color: scheme.onSurface.withValues(alpha: 0.02),
        borderRadius: BorderRadius.circular(24),
        border: Border.all(color: scheme.outlineVariant.withValues(alpha: 0.6), style: BorderStyle.solid),
      ),
      child: Center(
        child: Text(
          'NO ACTIVE TICKETS.',
          style: GoogleFonts.montserrat(
            fontSize: 11,
            fontWeight: FontWeight.w900,
            color: scheme.onSurface,
            letterSpacing: 3.2,
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
    final scheme = Theme.of(context).colorScheme;
    final isLight = scheme.brightness == Brightness.light;
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
              color: scheme.surfaceContainerHighest.withValues(alpha: isLight ? 0.65 : 0.22),
              borderRadius: BorderRadius.circular(24),
              border: Border.all(color: scheme.outlineVariant.withValues(alpha: 0.6)),
              boxShadow: [
                if (isLight) BoxShadow(color: Colors.black.withValues(alpha: 0.05), blurRadius: 20, offset: const Offset(0, 10)),
              ],
            ),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Container(
                  width: 40,
                  height: 40,
                  decoration: BoxDecoration(
                    borderRadius: BorderRadius.circular(12),
                    color: scheme.surface,
                    border: Border.all(color: scheme.outlineVariant.withValues(alpha: 0.6)),
                  ),
                  child: Icon(icon, color: color, size: 18),
                ),
                const SizedBox(height: 16),
                Text(
                  title.toUpperCase(),
                  style: GoogleFonts.montserrat(
                    color: scheme.onSurface,
                    fontWeight: FontWeight.w900,
                    fontSize: 11,
                    letterSpacing: 0.6,
                  ),
                ),
                const SizedBox(height: 4),
                Text(
                  subtitle.toUpperCase(),
                  style: GoogleFonts.montserrat(
                    color: scheme.onSurface.withValues(alpha: 0.65),
                    fontSize: 8.5,
                    fontWeight: FontWeight.w900,
                    letterSpacing: 1.2,
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


class _TicketPreviewItem extends StatelessWidget {
  final dynamic ticket;

  const _TicketPreviewItem({required this.ticket});

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final id = (ticket.id ?? '').toString();
    final title = (ticket.subject ?? 'Support Query').toString();
    final status = (ticket.status ?? 'Open').toString();
    final isOpen = status.toLowerCase() == 'open' || status.toLowerCase() == 'in progress';
    final badgeBg = isOpen ? Colors.blueAccent.withOpacity(0.1) : Colors.greenAccent.withOpacity(0.12);
    final badgeFg = isOpen ? Colors.blueAccent : Colors.greenAccent;
    return ClipRRect(
      borderRadius: BorderRadius.circular(24),
      child: BackdropFilter(
        filter: ImageFilter.blur(sigmaX: 10, sigmaY: 10),
        child: Container(
          margin: const EdgeInsets.only(bottom: 12),
          padding: const EdgeInsets.all(20),
          decoration: BoxDecoration(
            color: isDark ? const Color(0xFF18181B).withOpacity(0.8) : Colors.white.withOpacity(0.6),
            borderRadius: BorderRadius.circular(24),
            border: Border.all(color: isDark ? Colors.white.withOpacity(0.05) : Colors.white.withOpacity(0.6)),
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
                            id.isEmpty ? '—' : id.substring(0, id.length.clamp(0, 8)),
                            style: GoogleFonts.montserrat(
                              color: Colors.blueAccent,
                              fontSize: 8,
                              fontWeight: FontWeight.w900,
                            ),
                          ),
                        ),
                        const SizedBox(width: 8),
                        Expanded(
                          child: Text(
                            title.toUpperCase(),
                            style: GoogleFonts.montserrat(
                              color: Theme.of(context).colorScheme.onSurface,
                              fontWeight: FontWeight.w700,
                              fontSize: 13,
                            ),
                            maxLines: 1,
                            softWrap: false,
                            overflow: TextOverflow.ellipsis,
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 12),
                    Row(
                      children: [
                        Icon(LucideIcons.clock, size: 12, color: Theme.of(context).colorScheme.onSurface.withOpacity(0.2)),
                        const SizedBox(width: 6),
                        Text(
                          DateFormat('MMM d').format(ticket.createdAt).toUpperCase(),
                          style: GoogleFonts.montserrat(
                            color: Theme.of(context).colorScheme.onSurface.withOpacity(0.2),
                            fontSize: 9,
                            fontWeight: FontWeight.w900,
                          ),
                        ),
                      ],
                    ),
                  ],
                ),
              ),
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
                decoration: BoxDecoration(color: badgeBg, borderRadius: BorderRadius.circular(8)),
                child: Text(
                  status.toUpperCase(),
                  style: GoogleFonts.montserrat(color: badgeFg, fontSize: 8, fontWeight: FontWeight.w900),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

