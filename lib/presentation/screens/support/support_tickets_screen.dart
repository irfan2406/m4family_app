import 'dart:ui';

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:intl/intl.dart';
import 'package:lucide_icons/lucide_icons.dart';
import 'package:m4_mobile/presentation/providers/support_provider.dart';

/// Web parity for `/cp/support/logs` (web lists recent tickets here).
class SupportTicketsScreen extends ConsumerStatefulWidget {
  const SupportTicketsScreen({super.key});

  @override
  ConsumerState<SupportTicketsScreen> createState() => _SupportTicketsScreenState();
}

class _SupportTicketsScreenState extends ConsumerState<SupportTicketsScreen> {
  @override
  void initState() {
    super.initState();
    Future.microtask(() => ref.read(supportProvider.notifier).fetchTickets());
  }

  @override
  Widget build(BuildContext context) {
    final scheme = Theme.of(context).colorScheme;
    final state = ref.watch(supportProvider);

    return Scaffold(
      backgroundColor: Theme.of(context).scaffoldBackgroundColor,
      body: SafeArea(
        child: Column(
          children: [
            Padding(
              padding: const EdgeInsets.fromLTRB(24, 20, 24, 16),
              child: Row(
                children: [
                  GestureDetector(
                    onTap: () => Navigator.pop(context),
                    child: Container(
                      padding: const EdgeInsets.all(8),
                      decoration: BoxDecoration(
                        color: Colors.white.withValues(alpha: 0.05),
                        shape: BoxShape.circle,
                        border: Border.all(color: Colors.white.withValues(alpha: 0.1)),
                      ),
                      child: const Icon(LucideIcons.chevronLeft, color: Colors.white, size: 16),
                    ),
                  ),
                  Expanded(
                    child: Column(
                      children: [
                        Text(
                          'OPERATIONAL LOGS',
                          style: GoogleFonts.montserrat(fontSize: 16, fontWeight: FontWeight.w900, color: Colors.white),
                        ),
                        Text(
                          'RECENT TICKETS',
                          style: GoogleFonts.montserrat(fontSize: 8, fontWeight: FontWeight.w700, color: Colors.white38, letterSpacing: 1),
                        ),
                      ],
                    ),
                  ),
                  const SizedBox(width: 40),
                ],
              ),
            ),
            Expanded(
              child: RefreshIndicator(
                onRefresh: () => ref.read(supportProvider.notifier).fetchTickets(),
                child: state.isLoading && state.tickets.isEmpty
                    ? const Center(child: CircularProgressIndicator(color: Colors.white, strokeWidth: 2))
                    : state.tickets.isEmpty
                        ? Center(
                            child: Text(
                              'NO ACTIVE TICKETS.',
                              style: GoogleFonts.montserrat(
                                color: scheme.onSurface.withValues(alpha: 0.35),
                                fontWeight: FontWeight.w900,
                                letterSpacing: 2,
                              ),
                            ),
                          )
                        : ListView.builder(
                            padding: const EdgeInsets.fromLTRB(24, 8, 24, 24),
                            physics: const BouncingScrollPhysics(),
                            itemCount: state.tickets.length,
                            itemBuilder: (context, i) {
                              final t = state.tickets[i];
                              final id = t.id;
                              final title = t.subject;
                              final status = t.status;
                              final isOpen = status.toLowerCase() == 'open' || status.toLowerCase() == 'in progress';
                              final badgeBg = isOpen ? Colors.blueAccent.withValues(alpha: 0.1) : Colors.greenAccent.withValues(alpha: 0.12);
                              final badgeFg = isOpen ? Colors.blueAccent : Colors.greenAccent;

                              return ClipRRect(
                                borderRadius: BorderRadius.circular(24),
                                child: BackdropFilter(
                                  filter: ImageFilter.blur(sigmaX: 10, sigmaY: 10),
                                  child: Container(
                                    margin: const EdgeInsets.only(bottom: 12),
                                    padding: const EdgeInsets.all(20),
                                    decoration: BoxDecoration(
                                      color: Colors.white.withValues(alpha: 0.6),
                                      borderRadius: BorderRadius.circular(24),
                                      border: Border.all(color: Colors.white.withValues(alpha: 0.6)),
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
                                                      color: Colors.black.withValues(alpha: 0.04),
                                                      borderRadius: BorderRadius.circular(6),
                                                      border: Border.all(color: Colors.black.withValues(alpha: 0.06)),
                                                    ),
                                                    child: Text(
                                                      id.isEmpty ? '—' : id.substring(0, id.length.clamp(0, 8)),
                                                      style: GoogleFonts.montserrat(
                                                        color: Colors.black.withValues(alpha: 0.55),
                                                        fontSize: 8,
                                                        fontWeight: FontWeight.w900,
                                                        letterSpacing: 1.2,
                                                      ),
                                                    ),
                                                  ),
                                                  const SizedBox(width: 10),
                                                  Expanded(
                                                    child: Text(
                                                      title,
                                                      maxLines: 1,
                                                      overflow: TextOverflow.ellipsis,
                                                      style: GoogleFonts.montserrat(fontSize: 13, fontWeight: FontWeight.w800),
                                                    ),
                                                  ),
                                                ],
                                              ),
                                              const SizedBox(height: 10),
                                              Row(
                                                children: [
                                                  Icon(LucideIcons.clock, size: 12, color: Colors.black.withValues(alpha: 0.25)),
                                                  const SizedBox(width: 6),
                                                  Text(
                                                    DateFormat('MMM d').format(t.createdAt).toUpperCase(),
                                                    style: GoogleFonts.montserrat(
                                                      color: Colors.black.withValues(alpha: 0.25),
                                                      fontSize: 9,
                                                      fontWeight: FontWeight.w900,
                                                      letterSpacing: 1.4,
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
                            },
                          ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}

