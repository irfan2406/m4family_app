import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:lucide_icons/lucide_icons.dart';
import 'package:m4_mobile/core/models/activity_log.dart';
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
      ref.read(supportProvider.notifier).fetchLogs();
    });
  }

  @override
  void dispose() {
    _searchController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final state = ref.watch(supportProvider);
    final filteredLogs = state.logs.where((log) {
      final matchesSearch = log.displayId.toLowerCase().contains(_searchQuery.toLowerCase()) ||
          log.title.toLowerCase().contains(_searchQuery.toLowerCase());
      
      final isPending = log.status.toLowerCase() != 'completed' && log.status.toLowerCase() != 'resolved' && log.status.toLowerCase() != 'verified';
      final matchesPending = !_showOnlyPending || isPending;
      
      final matchesCategory = _selectedCategory == null || log.type.toLowerCase() == _selectedCategory!.toLowerCase();

      return matchesSearch && matchesPending && matchesCategory;
    }).toList();

    return Scaffold(
      backgroundColor: const Color(0xFF09090B),
      body: SafeArea(
        child: Stack(
          children: [
            Column(
              children: [
                _buildHeader(),
                _buildSearchAndFilter(),
                _buildAuditHeader(filteredLogs.length),
                Expanded(
                  child: state.isLoading && state.logs.isEmpty
                      ? const Center(child: CircularProgressIndicator(color: Colors.white, strokeWidth: 2))
                      : filteredLogs.isEmpty
                          ? _buildEmptyState()
                          : ListView.builder(
                              physics: const BouncingScrollPhysics(),
                              padding: const EdgeInsets.only(left: 24, right: 24, bottom: 100),
                              itemCount: filteredLogs.length,
                              itemBuilder: (context, index) => _LogCard(
                                log: filteredLogs[index],
                                onTap: () => _showLogDetails(filteredLogs[index]),
                              ),
                            ),
                ),
              ],
            ),
            Positioned(
              bottom: 24,
              left: 24,
              right: 24,
              child: _buildInitiateButton(),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildHeader() {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 20),
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
                  'TICKET LOGS',
                  style: GoogleFonts.montserrat(
                    fontSize: 16,
                    fontWeight: FontWeight.w900,
                    color: Colors.white,
                    letterSpacing: 0,
                  ),
                ),
                Text(
                  'CONCIERGE HISTORY',
                  style: GoogleFonts.montserrat(
                    fontSize: 8,
                    fontWeight: FontWeight.w700,
                    color: Colors.white38,
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

  Widget _buildSearchAndFilter() {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 8),
      child: Row(
        children: [
          Expanded(
            child: Container(
              height: 48,
              padding: const EdgeInsets.symmetric(horizontal: 16),
              decoration: BoxDecoration(
                color: Colors.white.withValues(alpha: 0.03),
                borderRadius: BorderRadius.circular(16),
                border: Border.all(color: Colors.white.withValues(alpha: 0.05)),
              ),
              child: Row(
                children: [
                  Icon(LucideIcons.search, size: 16, color: Colors.white.withValues(alpha: 0.2)),
                  const SizedBox(width: 12),
                  Expanded(
                    child: TextField(
                      controller: _searchController,
                      onChanged: (val) => setState(() => _searchQuery = val),
                      style: GoogleFonts.montserrat(color: Colors.white, fontSize: 11, fontWeight: FontWeight.w700),
                      decoration: InputDecoration(
                        hintText: 'SEARCH BY',
                        hintStyle: GoogleFonts.montserrat(
                          color: Colors.white.withValues(alpha: 0.1),
                          fontSize: 10,
                          fontWeight: FontWeight.w800,
                          letterSpacing: 1,
                        ),
                        border: InputBorder.none,
                      ),
                    ),
                  ),
                ],
              ),
            ),
          ),
          const SizedBox(width: 12),
          GestureDetector(
            onTap: _showCategoryFilter,
            child: Container(
              height: 48,
              width: 48,
              decoration: BoxDecoration(
                color: _selectedCategory != null ? Colors.white : Colors.white.withValues(alpha: 0.03),
                borderRadius: BorderRadius.circular(16),
                border: Border.all(color: Colors.white.withValues(alpha: 0.05)),
              ),
              child: Icon(
                LucideIcons.slidersHorizontal, 
                color: _selectedCategory != null ? Colors.black : Colors.white24, 
                size: 18,
              ),
            ),
          ),
          const SizedBox(width: 12),
          GestureDetector(
            onTap: () => setState(() => _showOnlyPending = !_showOnlyPending),
            child: Container(
              height: 48,
              padding: const EdgeInsets.symmetric(horizontal: 16),
              decoration: BoxDecoration(
                color: _showOnlyPending ? Colors.white : Colors.white.withValues(alpha: 0.03),
                borderRadius: BorderRadius.circular(16),
                border: Border.all(color: Colors.white.withValues(alpha: 0.05)),
              ),
              child: Center(
                child: Text(
                  _showOnlyPending ? 'IN PROGRESS' : 'PENDING',
                  style: GoogleFonts.montserrat(
                    color: _showOnlyPending ? Colors.black : Colors.white24,
                    fontSize: 7,
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

  void _showCategoryFilter() {
    showModalBottomSheet(
      context: context,
      backgroundColor: const Color(0xFF111111),
      shape: const RoundedRectangleBorder(borderRadius: BorderRadius.vertical(top: Radius.circular(24))),
      builder: (context) => Container(
        padding: const EdgeInsets.all(24),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              'FILTER BY CATEGORY',
              style: GoogleFonts.montserrat(color: Colors.white38, fontSize: 10, fontWeight: FontWeight.w800, letterSpacing: 1),
            ),
            const SizedBox(height: 24),
            Wrap(
              spacing: 12,
              runSpacing: 12,
              children: [
                _buildCategoryPill(null, 'ALL'),
                _buildCategoryPill('System', 'SYSTEM'),
                _buildCategoryPill('Ticket', 'TICKETS'),
                _buildCategoryPill('Update', 'UPDATES'),
              ],
            ),
            const SizedBox(height: 32),
          ],
        ),
      ),
    );
  }

  Widget _buildCategoryPill(String? value, String label) {
    final isSelected = _selectedCategory == value;
    return GestureDetector(
      onTap: () {
        setState(() => _selectedCategory = value);
        Navigator.pop(context);
      },
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 12),
        decoration: BoxDecoration(
          color: isSelected ? Colors.white : Colors.white.withValues(alpha: 0.05),
          borderRadius: BorderRadius.circular(12),
        ),
        child: Text(
          label,
          style: GoogleFonts.montserrat(
            color: isSelected ? Colors.black : Colors.white,
            fontSize: 10,
            fontWeight: FontWeight.w800,
          ),
        ),
      ),
    );
  }

  void _showLogDetails(ActivityLog log) {
    showModalBottomSheet(
      context: context,
      backgroundColor: Colors.transparent,
      isScrollControlled: true,
      builder: (context) => _LogDetailSheet(log: log),
    );
  }

  Widget _buildAuditHeader(int count) {
    return Padding(
      padding: const EdgeInsets.fromLTRB(24, 32, 24, 16),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Text(
            'SERVICE AUDIT',
            style: GoogleFonts.montserrat(
              color: Colors.white38,
              fontSize: 10,
              fontWeight: FontWeight.w800,
              letterSpacing: 1,
            ),
          ),
          Text(
            '$count LOGS RETRIEVED',
            style: GoogleFonts.montserrat(
              color: Colors.white38,
              fontSize: 9,
              fontWeight: FontWeight.w600,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildInitiateButton() {
    return Container(
      width: double.infinity,
      height: 56,
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(16),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.2),
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
                  color: Colors.black,
                  fontSize: 12,
                  fontWeight: FontWeight.w900,
                  letterSpacing: 0,
                ),
              ),
              const SizedBox(width: 12),
              const Icon(LucideIcons.messageSquare, color: Colors.black, size: 18),
            ],
          ),
        ),
      ),
    ).animate().fadeIn(delay: 400.ms).slideY(begin: 0.2);
  }

  Widget _buildEmptyState() {
    return Center(
      child: Text(
        'NO LOGS FOUND',
        style: GoogleFonts.montserrat(
          color: Colors.white.withValues(alpha: 0.1),
          fontSize: 10,
          fontWeight: FontWeight.w900,
          letterSpacing: 2,
        ),
      ),
    );
  }
}

class _LogCard extends StatelessWidget {
  final ActivityLog log;
  final VoidCallback onTap;
  const _LogCard({required this.log, required this.onTap});

  @override
  Widget build(BuildContext context) {
    final status = log.status.toLowerCase();
    final isResolved = status == 'resolved' || status == 'completed' || status == 'verified';
    final isPending = status == 'pending' || status == 'open';
    final isProgress = status == 'in progress';
    final isHighPriority = log.priority?.toLowerCase() == 'high';

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
          color: Colors.white.withValues(alpha: 0.03),
          borderRadius: BorderRadius.circular(24),
          border: Border.all(color: Colors.white.withValues(alpha: 0.04)),
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
                        color: Colors.white.withValues(alpha: 0.05),
                        borderRadius: BorderRadius.circular(6),
                      ),
                      child: Text(
                        log.displayId,
                        style: GoogleFonts.montserrat(
                          color: Colors.white38,
                          fontSize: 8,
                          fontWeight: FontWeight.w800,
                        ),
                      ),
                    ),
                    const SizedBox(width: 8),
                    Container(
                      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                      decoration: BoxDecoration(
                        color: statusColor.withValues(alpha: 0.1),
                        borderRadius: BorderRadius.circular(6),
                      ),
                      child: Row(
                        children: [
                          Icon(
                            isResolved 
                                ? LucideIcons.checkCircle2 
                                : isPending 
                                    ? LucideIcons.clock 
                                    : LucideIcons.refreshCw,
                            size: 10,
                            color: statusColor,
                          ),
                          const SizedBox(width: 6),
                          Text(
                            log.status.toUpperCase(),
                            style: GoogleFonts.montserrat(
                              color: statusColor,
                              fontSize: 8,
                              fontWeight: FontWeight.w900,
                            ),
                          ),
                        ],
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 20),
                Text(
                  log.title.toUpperCase(),
                  style: GoogleFonts.montserrat(
                    color: Colors.white,
                    fontWeight: FontWeight.w900,
                    fontSize: 14,
                    letterSpacing: 0.5,
                  ),
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                ),
                const SizedBox(height: 24),
                Row(
                  children: [
                    _DetailItem(label: 'ASSET CONTEXT', value: log.description.split('\r\n')[0].toUpperCase()),
                    _DetailItem(label: 'AUDIT DATE', value: DateFormat('dd MMM, yyyy').format(log.createdAt).toUpperCase()),
                  ],
                ),
                const SizedBox(height: 20),
                Row(
                  children: [
                    _DetailItem(label: 'CATEGORY', value: log.type.toUpperCase()),
                    _DetailItem(
                      label: 'PRIORITY',
                      value: (log.priority ?? 'MEDIUM').toUpperCase(),
                      valueColor: isHighPriority ? Colors.red : null,
                    ),
                  ],
                ),
              ],
            ),
            Positioned(
              right: 0,
              top: 60,
              child: Icon(LucideIcons.chevronRight, color: Colors.white.withValues(alpha: 0.1), size: 20),
            ),
          ],
        ),
      ).animate().fadeIn().slideX(begin: 0.05),
    );
  }
}

class _LogDetailSheet extends StatelessWidget {
  final ActivityLog log;
  const _LogDetailSheet({required this.log});

  @override
  Widget build(BuildContext context) {
    final isResolved = log.status.toLowerCase() == 'resolved' || log.status.toLowerCase() == 'completed';

    return Container(
      decoration: const BoxDecoration(
        color: Color(0xFF111111),
        borderRadius: BorderRadius.vertical(top: Radius.circular(40)),
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
                color: Colors.white10,
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
                  color: Colors.white.withValues(alpha: 0.05),
                  borderRadius: BorderRadius.circular(8),
                ),
                child: Text(
                  log.displayId,
                  style: GoogleFonts.montserrat(color: Colors.white38, fontSize: 10, fontWeight: FontWeight.w900),
                ),
              ),
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
                decoration: BoxDecoration(
                  color: (isResolved ? Colors.green : Colors.blue).withValues(alpha: 0.1),
                  borderRadius: BorderRadius.circular(8),
                ),
                child: Text(
                  log.status.toUpperCase(),
                  style: GoogleFonts.montserrat(color: isResolved ? Colors.green : Colors.blue, fontSize: 10, fontWeight: FontWeight.w900),
                ),
              ),
            ],
          ),
          const SizedBox(height: 24),
          Text(
            log.title.toUpperCase(),
            style: GoogleFonts.montserrat(color: Colors.white, fontSize: 20, fontWeight: FontWeight.w900),
          ),
          const SizedBox(height: 32),
          _buildInfoRow('ACTOR', log.actor.toUpperCase()),
          const SizedBox(height: 16),
          _buildInfoRow('AUDIT DATE', DateFormat('dd MMMM yyyy, hh:mm a').format(log.createdAt).toUpperCase()),
          const SizedBox(height: 16),
          _buildInfoRow('SECURITY', 'VERIFIED SYSTEM LOG', valueColor: const Color(0xFF22C55E)),
          const SizedBox(height: 32),
          Text(
            'DESCRIPTION',
            style: GoogleFonts.montserrat(color: Colors.white24, fontSize: 10, fontWeight: FontWeight.w800, letterSpacing: 1),
          ),
          const SizedBox(height: 12),
          Text(
            log.description,
            style: GoogleFonts.montserrat(color: Colors.white70, fontSize: 13, height: 1.6),
          ),
          const SizedBox(height: 40),
          SizedBox(
            width: double.infinity,
            height: 56,
            child: ElevatedButton(
              onPressed: () => Navigator.pop(context),
              style: ElevatedButton.styleFrom(
                backgroundColor: Colors.white,
                foregroundColor: Colors.black,
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

  Widget _buildInfoRow(String label, String value, {Color? valueColor}) {
    return Row(
      mainAxisAlignment: MainAxisAlignment.spaceBetween,
      children: [
        Text(
          label,
          style: GoogleFonts.montserrat(color: Colors.white24, fontSize: 10, fontWeight: FontWeight.w800, letterSpacing: 0.5),
        ),
        Text(
          value,
          style: GoogleFonts.montserrat(color: valueColor ?? Colors.white, fontSize: 10, fontWeight: FontWeight.w900),
        ),
      ],
    );
  }
}

class _DetailItem extends StatelessWidget {
  final String label;
  final String value;
  final Color? valueColor;

  const _DetailItem({required this.label, required this.value, this.valueColor});

  @override
  Widget build(BuildContext context) {
    return Expanded(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            label,
            style: GoogleFonts.montserrat(
              color: Colors.white24,
              fontSize: 8,
              fontWeight: FontWeight.w800,
              letterSpacing: 0.5,
            ),
          ),
          const SizedBox(height: 6),
          Text(
            value,
            style: GoogleFonts.montserrat(
              color: valueColor ?? Colors.white70,
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
