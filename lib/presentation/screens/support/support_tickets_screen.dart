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
  final _searchController = TextEditingController();
  String _selectedStatus = 'ALL';

  @override
  void initState() {
    super.initState();
    Future.microtask(() => ref.read(supportProvider.notifier).fetchTickets());
  }

  @override
  void dispose() {
    _searchController.dispose();
    super.dispose();
  }

  void _showFilterSheet(ColorScheme scheme) {
    showModalBottomSheet(
      context: context,
      backgroundColor: Colors.transparent,
      builder: (ctx) => Container(
        padding: const EdgeInsets.symmetric(horizontal: 28, vertical: 32),
        decoration: BoxDecoration(
          color: scheme.surface,
          borderRadius: const BorderRadius.vertical(top: Radius.circular(32)),
        ),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            Text(
              'FILTER BY STATUS',
              style: GoogleFonts.montserrat(fontSize: 10, fontWeight: FontWeight.w900, letterSpacing: 2),
            ),
            const SizedBox(height: 24),
            ...['ALL', 'OPEN', 'IN PROGRESS', 'CLOSED'].map((s) {
              final active = _selectedStatus == s;
              return Padding(
                padding: const EdgeInsets.only(bottom: 12),
                child: Material(
                  color: active ? Colors.black : scheme.onSurface.withValues(alpha: 0.05),
                  borderRadius: BorderRadius.circular(16),
                  child: InkWell(
                    onTap: () {
                      setState(() => _selectedStatus = s);
                      Navigator.pop(ctx);
                    },
                    borderRadius: BorderRadius.circular(16),
                    child: Container(
                      padding: const EdgeInsets.symmetric(vertical: 16, horizontal: 20),
                      child: Row(
                        mainAxisAlignment: MainAxisAlignment.spaceBetween,
                        children: [
                          Text(
                            s,
                            style: GoogleFonts.montserrat(
                              fontSize: 11,
                              fontWeight: FontWeight.w800,
                              color: active ? Colors.white : scheme.onSurface,
                              letterSpacing: 1,
                            ),
                          ),
                          if (active) const Icon(LucideIcons.check, color: Colors.white, size: 16),
                        ],
                      ),
                    ),
                  ),
                ),
              );
            }),
          ],
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final scheme = Theme.of(context).colorScheme;
    final state = ref.watch(supportProvider);

    final query = _searchController.text.toLowerCase().trim();
    final filtered = state.tickets.where((t) {
      final matchesQuery = query.isEmpty ||
          (t.subject?.toLowerCase().contains(query) ?? false) ||
          (t.id?.toLowerCase().contains(query) ?? false);

      final matchesStatus = _selectedStatus == 'ALL' || (t.status?.toUpperCase() == _selectedStatus);

      return matchesQuery && matchesStatus;
    }).toList();

    return Scaffold(
      backgroundColor: scheme.surface,
      body: SafeArea(
        child: Column(
          children: [
            _buildHeader(context, scheme),
            _buildSearchBar(scheme),
            Expanded(
              child: RefreshIndicator(
                onRefresh: () => ref.read(supportProvider.notifier).fetchTickets(),
                color: Colors.black,
                child: state.isLoading && state.tickets.isEmpty
                    ? const Center(child: CircularProgressIndicator(color: Colors.black, strokeWidth: 2))
                    : filtered.isEmpty
                        ? _buildEmptyState(scheme)
                        : _buildTicketsList(filtered, scheme),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildHeader(BuildContext context, ColorScheme scheme) {
    return Padding(
      padding: const EdgeInsets.fromLTRB(16, 12, 16, 20),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          IconButton(
            onPressed: () => Navigator.pop(context),
            icon: const Icon(LucideIcons.arrowLeft, size: 18),
            style: IconButton.styleFrom(
              backgroundColor: scheme.onSurface.withValues(alpha: 0.05),
              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
            ),
          ),
          Column(
            children: [
              Text(
                'OPERATIONAL LOGS',
                style: GoogleFonts.montserrat(fontSize: 14, fontWeight: FontWeight.w900, color: scheme.onSurface, letterSpacing: 1.5),
              ),
              const SizedBox(height: 2),
              Text(
                'FULL AUDIT HISTORY',
                style: GoogleFonts.montserrat(fontSize: 8, fontWeight: FontWeight.w900, color: scheme.onSurface.withValues(alpha: 0.5), letterSpacing: 2),
              ),
            ],
          ),
          const SizedBox(width: 48), // Spacer for balance
        ],
      ),
    );
  }

  Widget _buildSearchBar(ColorScheme scheme) {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 8),
      child: Row(
        children: [
          Expanded(
            child: Container(
              height: 48,
              decoration: BoxDecoration(
                color: scheme.surface,
                borderRadius: BorderRadius.circular(12),
                border: Border.all(color: scheme.outlineVariant.withValues(alpha: 0.3)),
                boxShadow: [
                  BoxShadow(color: Colors.black.withValues(alpha: 0.03), blurRadius: 10, offset: const Offset(0, 4)),
                ],
              ),
              child: TextField(
                controller: _searchController,
                onChanged: (_) => setState(() {}),
                style: GoogleFonts.montserrat(fontSize: 12, fontWeight: FontWeight.w700),
                decoration: InputDecoration(
                  hintText: 'SEARCH LOGS, TICKETS, UPD...',
                  hintStyle: GoogleFonts.montserrat(fontSize: 9, fontWeight: FontWeight.w900, color: scheme.onSurface.withValues(alpha: 0.3), letterSpacing: 1),
                  prefixIcon: Icon(LucideIcons.search, size: 16, color: scheme.onSurface.withValues(alpha: 0.4)),
                  border: InputBorder.none,
                  contentPadding: const EdgeInsets.symmetric(vertical: 14),
                ),
              ),
            ),
          ),
          const SizedBox(width: 12),
          Material(
            color: _selectedStatus == 'ALL' ? scheme.surface : Colors.black,
            borderRadius: BorderRadius.circular(12),
            child: InkWell(
              onTap: () => _showFilterSheet(scheme),
              borderRadius: BorderRadius.circular(12),
              child: Container(
                width: 48,
                height: 48,
                decoration: BoxDecoration(
                  borderRadius: BorderRadius.circular(12),
                  border: Border.all(color: _selectedStatus == 'ALL' ? scheme.outlineVariant.withValues(alpha: 0.3) : Colors.black),
                ),
                child: Icon(
                  LucideIcons.filter,
                  size: 18,
                  color: _selectedStatus == 'ALL' ? scheme.onSurface : Colors.white,
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildEmptyState(ColorScheme scheme) {
    return SingleChildScrollView(
      physics: const AlwaysScrollableScrollPhysics(),
      child: Container(
        padding: const EdgeInsets.symmetric(vertical: 80),
        alignment: Alignment.center,
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Container(
              width: 56,
              height: 56,
              decoration: BoxDecoration(
                color: scheme.onSurface.withValues(alpha: 0.02),
                borderRadius: BorderRadius.circular(16),
                border: Border.all(color: scheme.outlineVariant.withValues(alpha: 0.2)),
              ),
              child: Icon(LucideIcons.search, size: 24, color: scheme.onSurface.withValues(alpha: 0.4)),
            ),
            const SizedBox(height: 24),
            Text(
              'NO LOGS FOUND',
              style: GoogleFonts.montserrat(fontSize: 14, fontWeight: FontWeight.w900, color: scheme.onSurface, letterSpacing: 1),
            ),
            const SizedBox(height: 8),
            Text(
              'TRY ADJUSTING YOUR SEARCH OR FILTERS',
              style: GoogleFonts.montserrat(fontSize: 9, fontWeight: FontWeight.w900, color: scheme.onSurface.withValues(alpha: 0.4), letterSpacing: 1),
            ),
            const SizedBox(height: 40),
            Material(
              color: scheme.surface,
              borderRadius: BorderRadius.circular(12),
              elevation: 4,
              shadowColor: Colors.black.withValues(alpha: 0.1),
              child: InkWell(
                onTap: () {
                  setState(() {
                    _searchController.clear();
                    _selectedStatus = 'ALL';
                  });
                  ref.read(supportProvider.notifier).fetchTickets();
                },
                borderRadius: BorderRadius.circular(12),
                child: Container(
                  padding: const EdgeInsets.symmetric(horizontal: 32, vertical: 14),
                  decoration: BoxDecoration(
                    borderRadius: BorderRadius.circular(12),
                    border: Border.all(color: scheme.outlineVariant.withValues(alpha: 0.3)),
                  ),
                  child: Text(
                    'RESET MATRIX',
                    style: GoogleFonts.montserrat(fontSize: 10, fontWeight: FontWeight.w900, color: scheme.onSurface, letterSpacing: 1),
                  ),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildTicketsList(List<dynamic> tickets, ColorScheme scheme) {
    return ListView.builder(
      padding: const EdgeInsets.fromLTRB(24, 16, 24, 24),
      physics: const BouncingScrollPhysics(),
      itemCount: tickets.length,
      itemBuilder: (context, i) {
        final t = tickets[i];
        final id = t.id ?? '';
        final title = t.subject ?? 'No Subject';
        final status = t.status ?? 'Open';
        final isOpen = status.toLowerCase() == 'open' || status.toLowerCase() == 'in progress';
        final badgeBg = isOpen ? Colors.blue.withValues(alpha: 0.05) : Colors.green.withValues(alpha: 0.05);
        final badgeFg = isOpen ? Colors.blue[700] : Colors.green[700];

        return Container(
          margin: const EdgeInsets.only(bottom: 12),
          padding: const EdgeInsets.all(16),
          decoration: BoxDecoration(
            color: scheme.surface,
            borderRadius: BorderRadius.circular(20),
            border: Border.all(color: scheme.outlineVariant.withValues(alpha: 0.3)),
          ),
          child: Row(
            children: [
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(
                      children: [
                        Text(
                          id.length > 8 ? id.substring(0, 8) : id,
                          style: GoogleFonts.montserrat(fontSize: 8, fontWeight: FontWeight.w900, color: scheme.onSurface.withValues(alpha: 0.3), letterSpacing: 1),
                        ),
                        const SizedBox(width: 8),
                        Expanded(
                          child: Text(
                            title.toUpperCase(),
                            style: GoogleFonts.montserrat(fontSize: 11, fontWeight: FontWeight.w900, color: scheme.onSurface, letterSpacing: 0.5),
                            maxLines: 1,
                            overflow: TextOverflow.ellipsis,
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 12),
                    Row(
                      children: [
                        Icon(LucideIcons.clock, size: 12, color: scheme.onSurface.withValues(alpha: 0.2)),
                        const SizedBox(width: 6),
                        Text(
                          DateFormat('MMM d, yyyy').format(t.createdAt).toUpperCase(),
                          style: GoogleFonts.montserrat(fontSize: 9, fontWeight: FontWeight.w900, color: scheme.onSurface.withValues(alpha: 0.3), letterSpacing: 1),
                        ),
                      ],
                    ),
                  ],
                ),
              ),
              const SizedBox(width: 12),
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
        );
      },
    );
  }
}

