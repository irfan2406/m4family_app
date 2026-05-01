import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:lucide_icons/lucide_icons.dart';
import 'package:m4_mobile/data/models/ticket_model.dart';
import 'package:m4_mobile/presentation/providers/support_provider.dart';
import 'package:flutter_animate/flutter_animate.dart';
import 'package:intl/intl.dart';
import 'dart:ui';
import 'package:m4_mobile/presentation/screens/support/create_ticket_screen.dart';

class SupportLogsScreen extends ConsumerStatefulWidget {
  const SupportLogsScreen({super.key});

  @override
  ConsumerState<SupportLogsScreen> createState() => _SupportLogsScreenState();
}

class _SupportLogsScreenState extends ConsumerState<SupportLogsScreen> {
  final TextEditingController _searchController = TextEditingController();
  String _searchQuery = "";
  bool _showOnlyPending = false;
  String? _selectedCategory;

  @override
  void initState() {
    super.initState();
    Future.microtask(() {
      ref.read(supportProvider.notifier).fetchTickets();
    });
  }

  @override
  void dispose() {
    _searchController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final state = ref.watch(supportProvider);
    final filteredTickets = state.tickets.where((ticket) {
      final matchesSearch = ticket.displayId.toLowerCase().contains(_searchQuery.toLowerCase()) ||
          ticket.subject.toLowerCase().contains(_searchQuery.toLowerCase());
      
      final isPending = ticket.status.toLowerCase() != 'completed' && ticket.status.toLowerCase() != 'resolved' && ticket.status.toLowerCase() != 'closed';
      final matchesPending = !_showOnlyPending || isPending;
      
      final matchesCategory = _selectedCategory == null || ticket.category.toLowerCase() == _selectedCategory!.toLowerCase();

      return matchesSearch && matchesPending && matchesCategory;
    }).toList();

    return Scaffold(
      backgroundColor: isDark ? const Color(0xFF09090B) : const Color(0xFFF8FAFC),
      body: SafeArea(
        child: Stack(
          children: [
            Column(
              children: [
                _buildHeader(isDark),
                _buildSearchAndFilter(isDark),
                _buildAuditHeader(filteredTickets.length, isDark),
                Expanded(
                  child: state.isLoading && state.tickets.isEmpty
                      ? Center(child: CircularProgressIndicator(color: isDark ? Colors.white : Colors.black, strokeWidth: 2))
                      : filteredTickets.isEmpty
                          ? _buildEmptyState(isDark)
                          : ListView.builder(
                              physics: const BouncingScrollPhysics(),
                              padding: const EdgeInsets.only(left: 24, right: 24, bottom: 100),
                              itemCount: filteredTickets.length,
                              itemBuilder: (context, index) => _TicketCard(
                                ticket: filteredTickets[index],
                                isDark: isDark,
                                onTap: () => _showTicketDetails(filteredTickets[index], isDark),
                              ),
                            ),
                ),
              ],
            ),
            Positioned(
              bottom: 24,
              left: 24,
              right: 24,
              child: _buildInitiateButton(isDark),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildHeader(bool isDark) {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 20),
      child: Row(
        children: [
          GestureDetector(
            onTap: () => Navigator.pop(context),
            child: Container(
              padding: const EdgeInsets.all(8),
              decoration: BoxDecoration(
                color: (isDark ? Colors.white : Colors.black).withOpacity(0.05),
                shape: BoxShape.circle,
                border: Border.all(color: (isDark ? Colors.white : Colors.black).withOpacity(0.1)),
              ),
              child: Icon(LucideIcons.chevronLeft, color: isDark ? Colors.white : Colors.black, size: 16),
            ),
          ),
          Expanded(
            child: Column(
              children: [
                Text(
                  'TICKET LOGS',
                  style: GoogleFonts.montserrat(
                    fontSize: 16,
                    fontWeight: FontWeight.w900,
                    color: isDark ? Colors.white : Colors.black,
                    letterSpacing: 0,
                  ),
                ),
                Text(
                  'CONCIERGE HISTORY',
                  style: GoogleFonts.montserrat(
                    fontSize: 8,
                    fontWeight: FontWeight.w700,
                    color: isDark ? Colors.white38 : Colors.black38,
                    letterSpacing: 1,
                  ),
                ),
              ],
            ),
          ),
          const SizedBox(width: 40), // Balance the back button
        ],
      ),
    );
  }

  Widget _buildSearchAndFilter(bool isDark) {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 8),
      child: Row(
        children: [
          Expanded(
            child: Container(
              height: 48,
              padding: const EdgeInsets.symmetric(horizontal: 16),
              decoration: BoxDecoration(
                color: (isDark ? Colors.white : Colors.black).withOpacity(0.03),
                borderRadius: BorderRadius.circular(12),
                border: Border.all(color: (isDark ? Colors.white : Colors.black).withOpacity(0.05)),
              ),
              child: Row(
                children: [
                  Icon(LucideIcons.search, color: isDark ? Colors.white24 : Colors.black26, size: 18),
                  const SizedBox(width: 12),
                  Expanded(
                    child: TextField(
                      controller: _searchController,
                      onChanged: (value) => setState(() => _searchQuery = value),
                      style: GoogleFonts.montserrat(color: isDark ? Colors.white : Colors.black, fontSize: 13, fontWeight: FontWeight.w700),
                      decoration: InputDecoration(
                        hintText: 'SEARCH BY ID OR SUBJECT...',
                        hintStyle: GoogleFonts.montserrat(color: isDark ? Colors.white12 : Colors.black12, fontSize: 11, fontWeight: FontWeight.w800, letterSpacing: 0.5),
                        border: InputBorder.none,
                        contentPadding: const EdgeInsets.symmetric(vertical: 12),
                      ),
                    ),
                  ),
                ],
              ),
            ),
          ),
          const SizedBox(width: 12),
          GestureDetector(
            onTap: () {
              _showCategoryFilter(isDark);
            },
            child: Container(
              height: 48,
              width: 48,
              decoration: BoxDecoration(
                color: isDark ? Colors.white : Colors.black,
                borderRadius: BorderRadius.circular(12),
              ),
              child: Icon(LucideIcons.sliders, color: isDark ? Colors.black : Colors.white, size: 18),
            ),
          ),
          const SizedBox(width: 12),
          GestureDetector(
            onTap: () => setState(() => _showOnlyPending = !_showOnlyPending),
            child: Container(
              height: 48,
              padding: const EdgeInsets.symmetric(horizontal: 16),
              decoration: BoxDecoration(
                color: (isDark ? Colors.white : Colors.black).withOpacity(0.03),
                borderRadius: BorderRadius.circular(12),
                border: Border.all(color: _showOnlyPending ? (isDark ? Colors.white : Colors.black).withOpacity(0.2) : (isDark ? Colors.white : Colors.black).withOpacity(0.05)),
              ),
              child: Center(
                child: Text(
                  _showOnlyPending ? 'PENDING' : 'ALL',
                  style: GoogleFonts.montserrat(
                    color: isDark ? Colors.white : Colors.black,
                    fontSize: 9,
                    fontWeight: FontWeight.w900,
                    letterSpacing: 1,
                  ),
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }

  void _showCategoryFilter(bool isDark) {
    showModalBottomSheet(
      context: context,
      backgroundColor: isDark ? const Color(0xFF111111) : Colors.white,
      shape: const RoundedRectangleBorder(borderRadius: BorderRadius.vertical(top: Radius.circular(24))),
      builder: (context) => Container(
        padding: const EdgeInsets.all(24),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              'FILTER BY CATEGORY',
              style: GoogleFonts.montserrat(color: isDark ? Colors.white38 : Colors.black38, fontSize: 10, fontWeight: FontWeight.w800, letterSpacing: 1),
            ),
            const SizedBox(height: 24),
            Wrap(
              spacing: 12,
              runSpacing: 12,
              children: [
                _buildCategoryPill(null, 'ALL', isDark),
                _buildCategoryPill('System', 'SYSTEM', isDark),
                _buildCategoryPill('Ticket', 'TICKETS', isDark),
                _buildCategoryPill('Update', 'UPDATES', isDark),
              ],
            ),
            const SizedBox(height: 32),
          ],
        ),
      ),
    );
  }

  Widget _buildCategoryPill(String? value, String label, bool isDark) {
    final isSelected = _selectedCategory == value;
    return GestureDetector(
      onTap: () {
        setState(() => _selectedCategory = value);
        Navigator.pop(context);
      },
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 12),
        decoration: BoxDecoration(
          color: isSelected 
              ? (isDark ? Colors.white : Colors.black) 
              : (isDark ? Colors.white : Colors.black).withOpacity(0.05),
          borderRadius: BorderRadius.circular(12),
        ),
        child: Text(
          label,
          style: GoogleFonts.montserrat(
            color: isSelected 
                ? (isDark ? Colors.black : Colors.white) 
                : (isDark ? Colors.white : Colors.black),
            fontSize: 10,
            fontWeight: FontWeight.w800,
          ),
        ),
      ),
    );
  }

  void _showTicketDetails(TicketModel ticket, bool isDark) {
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (context) => _TicketDetailSheet(ticket: ticket, isDark: isDark),
    );
  }

  Widget _buildAuditHeader(int count, bool isDark) {
    return Padding(
      padding: const EdgeInsets.fromLTRB(24, 32, 24, 16),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Text(
            'SERVICE AUDIT',
            style: GoogleFonts.montserrat(
              color: isDark ? Colors.white38 : Colors.black38,
              fontSize: 10,
              fontWeight: FontWeight.w800,
              letterSpacing: 1,
            ),
          ),
          Text(
            '$count LOGS RETRIEVED',
            style: GoogleFonts.montserrat(
              color: isDark ? Colors.white38 : Colors.black38,
              fontSize: 9,
              fontWeight: FontWeight.w600,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildInitiateButton(bool isDark) {
    return Container(
      width: double.infinity,
      height: 56,
      decoration: BoxDecoration(
        color: isDark ? Colors.white : Colors.black,
        borderRadius: BorderRadius.circular(16),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.2),
            blurRadius: 20,
            offset: const Offset(0, 10),
          ),
        ],
      ),
      child: Material(
        color: Colors.transparent,
        child: InkWell(
          onTap: () => Navigator.push(context, MaterialPageRoute(builder: (_) => const CreateTicketScreen())),
          borderRadius: BorderRadius.circular(16),
          child: Row(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Text(
                'INITIATE NEW SERVICE TICKET',
                style: GoogleFonts.montserrat(
                  color: isDark ? Colors.black : Colors.white,
                  fontSize: 11,
                  fontWeight: FontWeight.w900,
                  letterSpacing: 0.5,
                ),
              ),
              const SizedBox(width: 12),
              Icon(LucideIcons.messageSquare, color: isDark ? Colors.black : Colors.white, size: 16),
            ],
          ),
        ),
      ),
    ).animate().fadeIn(delay: 400.ms).slideY(begin: 0.2);
  }

  Widget _buildEmptyState(bool isDark) {
    return Center(
      child: Text(
        'NO LOGS FOUND',
        style: GoogleFonts.montserrat(
          color: (isDark ? Colors.white : Colors.black).withOpacity(0.1),
          fontSize: 10,
          fontWeight: FontWeight.w900,
          letterSpacing: 2,
        ),
      ),
    );
  }
}

class _TicketCard extends StatelessWidget {
  final TicketModel ticket;
  final VoidCallback onTap;
  final bool isDark;
  const _TicketCard({required this.ticket, required this.onTap, required this.isDark});

  @override
  Widget build(BuildContext context) {
    final status = ticket.status.toLowerCase();
    final isResolved = status == 'resolved' || status == 'completed' || status == 'closed';
    final isPending = status == 'pending' || status == 'open';
    final isProgress = status == 'in progress';
    final isHighPriority = ticket.priority.toLowerCase() == 'high';

    final statusColor = isResolved 
        ? const Color(0xFF22C55E) 
        : isPending 
            ? const Color(0xFFF59E0B) 
            : const Color(0xFF3B82F6);

    return GestureDetector(
      onTap: onTap,
      child: Container(
        margin: const EdgeInsets.only(bottom: 16),
        padding: const EdgeInsets.all(24),
        decoration: BoxDecoration(
          color: (isDark ? Colors.white : Colors.black).withOpacity(0.03),
          borderRadius: BorderRadius.circular(24),
          border: Border.all(color: (isDark ? Colors.white : Colors.black).withOpacity(0.04)),
        ),
        child: Stack(
          children: [
            Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  children: [
                    Container(
                      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                      decoration: BoxDecoration(
                        color: (isDark ? Colors.white : Colors.black).withOpacity(0.05),
                        borderRadius: BorderRadius.circular(6),
                      ),
                      child: Text(
                        ticket.displayId,
                        style: GoogleFonts.montserrat(
                          color: isDark ? Colors.white38 : Colors.black38,
                          fontSize: 8,
                          fontWeight: FontWeight.w800,
                        ),
                      ),
                    ),
                    const SizedBox(width: 8),
                    Container(
                      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                      decoration: BoxDecoration(
                        color: statusColor.withOpacity(0.1),
                        borderRadius: BorderRadius.circular(6),
                      ),
                      child: Row(
                        children: [
                          Icon(LucideIcons.clock, color: statusColor, size: 8),
                          const SizedBox(width: 4),
                          Text(
                            ticket.status.toUpperCase(),
                            style: GoogleFonts.montserrat(color: statusColor, fontSize: 8, fontWeight: FontWeight.w900),
                          ),
                        ],
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 16),
                Text(
                  ticket.subject.toUpperCase(),
                  style: GoogleFonts.montserrat(color: isDark ? Colors.white : Colors.black, fontSize: 16, fontWeight: FontWeight.w900),
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                ),
                const SizedBox(height: 20),
                Row(
                  children: [
                    _DetailItem(
                      label: 'CATEGORY',
                      value: ticket.category.toUpperCase(),
                      isDark: isDark,
                    ),
                    _DetailItem(
                      label: 'PRIORITY',
                      value: ticket.priority.toUpperCase(),
                      isDark: isDark,
                      valueColor: isHighPriority ? Colors.red : null,
                    ),
                  ],
                ),
              ],
            ),
            Positioned(
              right: 0,
              top: 60,
              child: Icon(LucideIcons.chevronRight, color: (isDark ? Colors.white : Colors.black).withOpacity(0.1), size: 20),
            ),
          ],
        ),
      ).animate().fadeIn().slideX(begin: 0.05),
    );
  }
}

class _TicketDetailSheet extends StatelessWidget {
  final TicketModel ticket;
  final bool isDark;
  const _TicketDetailSheet({required this.ticket, required this.isDark});

  @override
  Widget build(BuildContext context) {
    final isResolved = ticket.status.toLowerCase() == 'resolved' || ticket.status.toLowerCase() == 'completed' || ticket.status.toLowerCase() == 'closed';

    return Container(
      decoration: BoxDecoration(
        color: isDark ? const Color(0xFF111111) : Colors.white,
        borderRadius: const BorderRadius.vertical(top: Radius.circular(40)),
      ),
      padding: const EdgeInsets.all(32),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Center(
            child: Container(
              width: 40,
              height: 4,
              decoration: BoxDecoration(
                color: (isDark ? Colors.white : Colors.black).withOpacity(0.1),
                borderRadius: BorderRadius.circular(2),
              ),
            ),
          ),
          const SizedBox(height: 32),
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
                decoration: BoxDecoration(
                  color: (isDark ? Colors.white : Colors.black).withOpacity(0.05),
                  borderRadius: BorderRadius.circular(8),
                ),
                child: Text(
                  ticket.displayId,
                  style: GoogleFonts.montserrat(color: isDark ? Colors.white38 : Colors.black38, fontSize: 10, fontWeight: FontWeight.w900),
                ),
              ),
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
                decoration: BoxDecoration(
                  color: (isResolved ? Colors.green : Colors.blue).withOpacity(0.1),
                  borderRadius: BorderRadius.circular(8),
                ),
                child: Text(
                  ticket.status.toUpperCase(),
                  style: GoogleFonts.montserrat(color: isResolved ? Colors.green : Colors.blue, fontSize: 10, fontWeight: FontWeight.w900),
                ),
              ),
            ],
          ),
          const SizedBox(height: 24),
          Text(
            ticket.subject.toUpperCase(),
            style: GoogleFonts.montserrat(color: isDark ? Colors.white : Colors.black, fontSize: 20, fontWeight: FontWeight.w900),
          ),
          const SizedBox(height: 32),
          _buildInfoRow('CATEGORY', ticket.category.toUpperCase(), isDark),
          const SizedBox(height: 16),
          _buildInfoRow('AUDIT DATE', DateFormat('dd MMMM yyyy, hh:mm a').format(ticket.createdAt).toUpperCase(), isDark),
          const SizedBox(height: 16),
          _buildInfoRow('PRIORITY', ticket.priority.toUpperCase(), isDark, valueColor: ticket.priority.toLowerCase() == 'high' ? Colors.red : null),
          const SizedBox(height: 32),
          Text(
            'DESCRIPTION',
            style: GoogleFonts.montserrat(color: isDark ? Colors.white24 : Colors.black26, fontSize: 10, fontWeight: FontWeight.w800, letterSpacing: 1),
          ),
          const SizedBox(height: 12),
          Text(
            ticket.message ?? 'No description provided.',
            style: GoogleFonts.montserrat(color: isDark ? Colors.white70 : Colors.black87, fontSize: 13, height: 1.6),
          ),
          const SizedBox(height: 40),
          SizedBox(
            width: double.infinity,
            height: 56,
            child: ElevatedButton(
              onPressed: () => Navigator.pop(context),
              style: ElevatedButton.styleFrom(
                backgroundColor: isDark ? Colors.white : Colors.black,
                foregroundColor: isDark ? Colors.black : Colors.white,
                shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
              ),
              child: Text(
                'DISMISS AUDIT',
                style: GoogleFonts.montserrat(fontWeight: FontWeight.w900, fontSize: 12),
              ),
            ),
          ),
          const SizedBox(height: 20),
        ],
      ),
    );
  }

  Widget _buildInfoRow(String label, String value, bool isDark, {Color? valueColor}) {
    return Row(
      mainAxisAlignment: MainAxisAlignment.spaceBetween,
      children: [
        Text(
          label,
          style: GoogleFonts.montserrat(color: isDark ? Colors.white24 : Colors.black26, fontSize: 10, fontWeight: FontWeight.w800, letterSpacing: 0.5),
        ),
        Text(
          value,
          style: GoogleFonts.montserrat(color: valueColor ?? (isDark ? Colors.white : Colors.black), fontSize: 10, fontWeight: FontWeight.w900),
        ),
      ],
    );
  }
}

class _DetailItem extends StatelessWidget {
  final String label;
  final String value;
  final bool isDark;
  final Color? valueColor;

  const _DetailItem({required this.label, required this.value, required this.isDark, this.valueColor});

  @override
  Widget build(BuildContext context) {
    return Expanded(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            label,
            style: GoogleFonts.montserrat(
              color: isDark ? Colors.white24 : Colors.black26,
              fontSize: 8,
              fontWeight: FontWeight.w800,
              letterSpacing: 0.5,
            ),
          ),
          const SizedBox(height: 6),
          Text(
            value,
            style: GoogleFonts.montserrat(
              color: valueColor ?? (isDark ? Colors.white70 : Colors.black87),
              fontSize: 10,
              fontWeight: FontWeight.w800,
            ),
            maxLines: 1,
            overflow: TextOverflow.ellipsis,
          ),
        ],
      ),
    );
  }
}
