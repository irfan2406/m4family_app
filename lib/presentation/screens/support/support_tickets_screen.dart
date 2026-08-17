import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:lucide_icons/lucide_icons.dart';
import 'package:flutter_animate/flutter_animate.dart';

/// Web `/support/logs` (`app/(user)/support/logs/page.tsx`) — "Operational Logs
/// / Full Audit History". Web renders a static set of mock audit logs; this
/// mirrors that data and card design (ID + type + status badges, title,
/// description, clock/View Details footer) plus a details bottom sheet.
class SupportTicketsScreen extends ConsumerStatefulWidget {
  const SupportTicketsScreen({super.key});

  @override
  ConsumerState<SupportTicketsScreen> createState() =>
      _SupportTicketsScreenState();
}

class _SupportTicketsScreenState extends ConsumerState<SupportTicketsScreen> {
  final _searchController = TextEditingController();
  String? _selectedType;

  // Web parity: the same mock audit logs the web page renders.
  static const List<Map<String, dynamic>> _mockLogs = [
    {
      'id': 'LOG-5421',
      'title': 'Site Visit Confirmed - M4 Core',
      'status': 'Completed',
      'date': 'Just Now',
      'type': 'System',
      'description':
          'The site visit request for M4 Core has been successfully confirmed by the sales team. The customer has been notified via email and SMS.',
      'actor': 'System Automator',
      'details': {
        'Location': 'M4 Core Site',
        'Visit Time': '2024-02-05 11:00 AM',
        'Assigned Agent': 'Rahul Sharma',
      },
    },
    {
      'id': 'T-1024',
      'title': 'Payment Query - M4 Elegance',
      'status': 'Open',
      'date': '2 Hours ago',
      'type': 'Ticket',
      'description':
          'Customer raised a query regarding the latest installment payment for M4 Elegance. Waiting for finance team review.',
      'actor': 'Customer Care',
      'details': {
        'Ticket Id': 'T-1024',
        'Priority': 'High',
        'Department': 'Finance',
      },
    },
    {
      'id': 'DOC-882',
      'title': 'KYC Documents Verified',
      'status': 'Verified',
      'date': '5 Hours ago',
      'type': 'Update',
      'description':
          'Identity and address proofs for Mr. J. Singh have been verified by the compliance department.',
      'actor': 'Compliance Dept',
      'details': {'Doc Type': 'Aadhar, PAN', 'Verification Id': 'V-88291'},
    },
    {
      'id': 'T-1021',
      'title': 'Site Visit Reschedule',
      'status': 'Closed',
      'date': 'Yesterday',
      'type': 'Ticket',
      'description':
          "Site visit for Juhu Executive Suites rescheduled from Sunday to Monday at customer's request.",
      'actor': 'Front Desk',
      'details': {
        'Old Date': 'Sunday',
        'New Date': 'Monday',
        'Reason': 'Personal Conflict',
      },
    },
    {
      'id': 'SYS-009',
      'title': 'Profile Security Migration',
      'status': 'Active',
      'date': '2 Days ago',
      'type': 'Security',
      'description':
          'Upgrading user profile encryption to AES-256 standards as part of mandatory security maintenance.',
      'actor': 'Admin Engine',
      'details': {'Status': '75% Complete', 'Encrypted User Count': '1,240'},
    },
    {
      'id': 'LOG-5390',
      'title': 'Booking Deposit Received',
      'status': 'Success',
      'date': '3 Days ago',
      'type': 'Finance',
      'description':
          'Token amount of ₹5,00,000 received for Unit 402, M4 Core. Payment confirmed via bank transfer.',
      'actor': 'HDFC Payment Gateway',
      'details': {
        'Amount': '₹5,00,000',
        'Transaction Id': 'TXN_449210',
        'Method': 'NEFT',
      },
    },
    {
      'id': 'T-998',
      'title': 'Brochure for Crown Residences',
      'status': 'Closed',
      'date': '4 Days ago',
      'type': 'Ticket',
      'description':
          "Digital brochure for Crown Residences sent to the customer's registered email address.",
      'actor': 'Sales Bot',
      'details': {
        'Sent To': 'user@example.com',
        'File Format': 'PDF',
        'Size': '4.2 MB',
      },
    },
    {
      'id': 'LOG-5382',
      'title': 'Project Update Notification',
      'status': 'Sent',
      'date': '1 Week ago',
      'type': 'Broadcast',
      'description':
          'Monthly progress report for January sent to all M4 Family members. High engagement rate detected.',
      'actor': 'Marketing System',
      'details': {
        'Recipients': '4,500+',
        'Open Rate': '68%',
        'Click Rate': '22%',
      },
    },
  ];

  List<String> get _logTypes =>
      _mockLogs.map((l) => l['type'] as String).toSet().toList();

  @override
  void dispose() {
    _searchController.dispose();
    super.dispose();
  }

  Color _statusColor(String status) {
    final s = status.toLowerCase();
    if (s == 'completed' || s == 'verified' || s == 'success') {
      return const Color(0xFF16A34A); // green
    }
    if (s == 'open' || s == 'active') {
      return const Color(0xFF2563EB); // blue
    }
    return const Color(0xFF6B7280); // grey
  }

  void _showFilterSheet(ColorScheme scheme) {
    const sheetBg = Color(0xFF0D0D0D);
    showModalBottomSheet(
      context: context,
      backgroundColor: Colors.transparent,
      builder: (ctx) => Container(
        padding: const EdgeInsets.fromLTRB(28, 14, 28, 8),
        decoration: const BoxDecoration(
          color: sheetBg,
          borderRadius: BorderRadius.vertical(top: Radius.circular(32)),
        ),
        child: SafeArea(
          top: false,
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              Center(
                child: Container(
                  width: 40,
                  height: 4,
                  decoration: BoxDecoration(
                    color: Colors.white.withValues(alpha: 0.2),
                    borderRadius: BorderRadius.circular(99),
                  ),
                ),
              ),
              const SizedBox(height: 16),
              // Close button (top-right).
              Align(
                alignment: Alignment.centerRight,
                child: GestureDetector(
                  onTap: () => Navigator.pop(ctx),
                  child: Container(
                    width: 40,
                    height: 40,
                    alignment: Alignment.center,
                    decoration: const BoxDecoration(
                      color: Colors.white,
                      shape: BoxShape.circle,
                    ),
                    child: const Icon(
                      LucideIcons.x,
                      size: 18,
                      color: Colors.black,
                    ),
                  ),
                ),
              ),
              const SizedBox(height: 16),
              Text(
                'LOG CATEGORY',
                style: GoogleFonts.gelasio(
                  fontSize: 10,
                  fontWeight: FontWeight.w900,
                  letterSpacing: 2,
                  color: Colors.white.withValues(alpha: 0.68),
                ),
              ),
              const SizedBox(height: 16),
              // Web mock categories as a 2-column grid of cards (no "All").
              GridView.count(
                shrinkWrap: true,
                physics: const NeverScrollableScrollPhysics(),
                crossAxisCount: 2,
                crossAxisSpacing: 14,
                mainAxisSpacing: 14,
                childAspectRatio: 2.6,
                children: _logTypes.map((t) {
                  final active = _selectedType == t;
                  return GestureDetector(
                    onTap: () {
                      setState(() => _selectedType = t);
                      Navigator.pop(ctx);
                    },
                    child: Container(
                      alignment: Alignment.center,
                      decoration: BoxDecoration(
                        color: active ? const Color(0xFF1A1A24) : Colors.white,
                        borderRadius: BorderRadius.circular(18),
                        border: active
                            ? Border.all(
                                color: Colors.white.withValues(alpha: 0.2),
                              )
                            : null,
                      ),
                      child: Text(
                        t.toUpperCase(),
                        style: GoogleFonts.ebGaramond(
                          fontSize: 12,
                          fontWeight: FontWeight.w900,
                          letterSpacing: 1,
                          color: active ? Colors.white : Colors.black,
                        ),
                      ),
                    ),
                  );
                }).toList(),
              ),
              const SizedBox(height: 12),
            ],
          ),
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final scheme = Theme.of(context).colorScheme;

    final query = _searchController.text.toLowerCase().trim();
    final filtered = _mockLogs.where((log) {
      final matchesQuery =
          query.isEmpty ||
          (log['title'] as String).toLowerCase().contains(query) ||
          (log['id'] as String).toLowerCase().contains(query) ||
          (log['description'] as String).toLowerCase().contains(query);
      final matchesType = _selectedType == null || log['type'] == _selectedType;
      return matchesQuery && matchesType;
    }).toList();

    return Scaffold(
      backgroundColor: scheme.surface,
      body: SafeArea(
        child: Column(
          children: [
            _buildHeader(context, scheme),
            _buildSearchBar(scheme),
            if (_selectedType != null) _buildActiveFilter(scheme),
            Expanded(
              child: filtered.isEmpty
                  ? _buildEmptyState(scheme)
                  : ListView.builder(
                      padding: const EdgeInsets.fromLTRB(24, 16, 24, 40),
                      physics: const BouncingScrollPhysics(),
                      itemCount: filtered.length,
                      itemBuilder: (context, i) =>
                          _logCard(filtered[i], scheme, i),
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
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(10),
              ),
            ),
          ),
          Column(
            children: [
              Text(
                'OPERATIONAL LOGS',
                style: GoogleFonts.gelasio(
                  fontSize: 14,
                  fontWeight: FontWeight.w900,
                  color: scheme.onSurface,
                  letterSpacing: 1.5,
                ),
              ),
              const SizedBox(height: 2),
              Text(
                'FULL AUDIT HISTORY',
                style: GoogleFonts.gelasio(
                  fontSize: 8,
                  fontWeight: FontWeight.w900,
                  color: scheme.onSurface.withValues(alpha: 0.68),
                  letterSpacing: 2,
                ),
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
                border: Border.all(
                  color: scheme.outlineVariant.withValues(alpha: 0.3),
                ),
                boxShadow: [
                  BoxShadow(
                    color: Colors.black.withValues(alpha: 0.03),
                    blurRadius: 10,
                    offset: const Offset(0, 4),
                  ),
                ],
              ),
              child: TextField(
                controller: _searchController,
                onChanged: (_) => setState(() {}),
                style: GoogleFonts.ebGaramond(
                  fontSize: 15,
                  fontWeight: FontWeight.w800,
                ),
                decoration: InputDecoration(
                  hintText: 'SEARCH LOGS, TICKETS, UPD...',
                  hintStyle: GoogleFonts.ebGaramond(
                    fontSize: 12,
                    fontWeight: FontWeight.w800,
                    color: scheme.onSurface.withValues(alpha: 0.68),
                    letterSpacing: 0.3,
                  ),
                  prefixIcon: Icon(
                    LucideIcons.search,
                    size: 16,
                    color: scheme.onSurface.withValues(alpha: 0.4),
                  ),
                  suffixIcon: _searchController.text.isNotEmpty
                      ? IconButton(
                          icon: Icon(
                            LucideIcons.x,
                            size: 14,
                            color: scheme.onSurface.withValues(alpha: 0.4),
                          ),
                          onPressed: () =>
                              setState(() => _searchController.clear()),
                        )
                      : null,
                  border: InputBorder.none,
                  contentPadding: const EdgeInsets.symmetric(vertical: 14),
                ),
              ),
            ),
          ),
          const SizedBox(width: 12),
          Material(
            color: _selectedType == null ? scheme.surface : scheme.onSurface,
            borderRadius: BorderRadius.circular(12),
            child: InkWell(
              onTap: () => _showFilterSheet(scheme),
              borderRadius: BorderRadius.circular(12),
              child: Container(
                width: 48,
                height: 48,
                decoration: BoxDecoration(
                  borderRadius: BorderRadius.circular(12),
                  border: Border.all(
                    color: _selectedType == null
                        ? scheme.outlineVariant.withValues(alpha: 0.3)
                        : scheme.onSurface,
                  ),
                ),
                child: Icon(
                  LucideIcons.filter,
                  size: 18,
                  color: _selectedType == null
                      ? scheme.onSurface
                      : scheme.surface,
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildActiveFilter(ColorScheme scheme) {
    return Padding(
      padding: const EdgeInsets.fromLTRB(24, 4, 24, 4),
      child: Row(
        children: [
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
            decoration: BoxDecoration(
              color: scheme.onSurface.withValues(alpha: 0.05),
              borderRadius: BorderRadius.circular(99),
              border: Border.all(
                color: scheme.outlineVariant.withValues(alpha: 0.3),
              ),
            ),
            child: Row(
              mainAxisSize: MainAxisSize.min,
              children: [
                Text(
                  'TYPE: ${_selectedType!.toUpperCase()}',
                  style: GoogleFonts.ebGaramond(
                    fontSize: 8,
                    fontWeight: FontWeight.w900,
                    color: scheme.onSurface,
                    letterSpacing: 1,
                  ),
                ),
                const SizedBox(width: 8),
                GestureDetector(
                  onTap: () => setState(() => _selectedType = null),
                  child: Icon(
                    LucideIcons.x,
                    size: 11,
                    color: scheme.onSurface.withValues(alpha: 0.6),
                  ),
                ),
              ],
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
                border: Border.all(
                  color: scheme.outlineVariant.withValues(alpha: 0.2),
                ),
              ),
              child: Icon(
                LucideIcons.search,
                size: 24,
                color: scheme.onSurface.withValues(alpha: 0.4),
              ),
            ),
            const SizedBox(height: 24),
            Text(
              'NO LOGS FOUND',
              style: GoogleFonts.ebGaramond(
                fontSize: 14,
                fontWeight: FontWeight.w900,
                color: scheme.onSurface,
                letterSpacing: 1,
              ),
            ),
            const SizedBox(height: 8),
            Text(
              'TRY ADJUSTING YOUR SEARCH OR FILTERS',
              style: GoogleFonts.ebGaramond(
                fontSize: 9,
                fontWeight: FontWeight.w900,
                color: scheme.onSurface.withValues(alpha: 0.68),
                letterSpacing: 1,
              ),
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
                    _selectedType = null;
                  });
                },
                borderRadius: BorderRadius.circular(12),
                child: Container(
                  padding: const EdgeInsets.symmetric(
                    horizontal: 32,
                    vertical: 14,
                  ),
                  decoration: BoxDecoration(
                    borderRadius: BorderRadius.circular(12),
                    border: Border.all(
                      color: scheme.outlineVariant.withValues(alpha: 0.3),
                    ),
                  ),
                  child: Text(
                    'RESET MATRIX',
                    style: GoogleFonts.ebGaramond(
                      fontSize: 10,
                      fontWeight: FontWeight.w900,
                      color: scheme.onSurface,
                      letterSpacing: 1,
                    ),
                  ),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  // Web parity: glass card with ID + type badges, a colored status badge, the
  // title, a one-line description, and a clock/View Details footer.
  Widget _logCard(Map<String, dynamic> log, ColorScheme scheme, int index) {
    final statusColor = _statusColor(log['status'] as String);
    return GestureDetector(
      onTap: () => _showLogDetails(log, scheme),
      child: Container(
        margin: const EdgeInsets.only(bottom: 16),
        padding: const EdgeInsets.all(20),
        decoration: BoxDecoration(
          color: scheme.surface,
          borderRadius: BorderRadius.circular(28),
          border: Border.all(
            color: scheme.outlineVariant.withValues(alpha: 0.22),
          ),
          boxShadow: [
            BoxShadow(
              color: Colors.black.withValues(alpha: 0.05),
              blurRadius: 24,
              offset: const Offset(0, 12),
            ),
          ],
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Top row: ID + type badges | status badge
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Expanded(
                  child: Row(
                    children: [
                      Container(
                        padding: const EdgeInsets.symmetric(
                          horizontal: 8,
                          vertical: 4,
                        ),
                        decoration: BoxDecoration(
                          color: scheme.onSurface.withValues(alpha: 0.04),
                          borderRadius: BorderRadius.circular(6),
                          border: Border.all(
                            color: scheme.outlineVariant.withValues(alpha: 0.3),
                          ),
                        ),
                        child: Text(
                          log['id'] as String,
                          style: GoogleFonts.ebGaramond(
                            fontSize: 8,
                            fontWeight: FontWeight.w800,
                            color: scheme.onSurface.withValues(alpha: 0.68),
                            letterSpacing: 1,
                          ),
                        ),
                      ),
                      const SizedBox(width: 8),
                      Container(
                        padding: const EdgeInsets.symmetric(
                          horizontal: 8,
                          vertical: 4,
                        ),
                        decoration: BoxDecoration(
                          borderRadius: BorderRadius.circular(6),
                          border: Border.all(
                            color: scheme.outlineVariant.withValues(alpha: 0.4),
                          ),
                        ),
                        child: Text(
                          (log['type'] as String).toUpperCase(),
                          style: GoogleFonts.ebGaramond(
                            fontSize: 8,
                            fontWeight: FontWeight.w800,
                            color: scheme.onSurface.withValues(alpha: 0.68),
                            letterSpacing: 1,
                          ),
                        ),
                      ),
                    ],
                  ),
                ),
                const SizedBox(width: 8),
                Container(
                  padding: const EdgeInsets.symmetric(
                    horizontal: 12,
                    vertical: 5,
                  ),
                  decoration: BoxDecoration(
                    color: statusColor.withValues(alpha: 0.1),
                    borderRadius: BorderRadius.circular(8),
                  ),
                  child: Text(
                    (log['status'] as String).toUpperCase(),
                    style: GoogleFonts.ebGaramond(
                      fontSize: 8,
                      fontWeight: FontWeight.w900,
                      color: statusColor,
                      letterSpacing: 1,
                    ),
                  ),
                ),
              ],
            ),
            const SizedBox(height: 16),
            Text(
              (log['title'] as String).toUpperCase(),
              style: GoogleFonts.ebGaramond(
                fontSize: 14,
                fontWeight: FontWeight.w900,
                color: scheme.onSurface,
                letterSpacing: -0.2,
              ),
              maxLines: 2,
              overflow: TextOverflow.ellipsis,
            ),
            const SizedBox(height: 8),
            Text(
              (log['description'] as String).toUpperCase(),
              style: GoogleFonts.ebGaramond(
                fontSize: 10,
                fontWeight: FontWeight.w700,
                color: scheme.onSurface.withValues(alpha: 0.68),
                letterSpacing: 0.2,
                height: 1.4,
              ),
              maxLines: 1,
              overflow: TextOverflow.ellipsis,
            ),
            const SizedBox(height: 16),
            Divider(
              height: 1,
              thickness: 1,
              color: scheme.outlineVariant.withValues(alpha: 0.3),
            ),
            const SizedBox(height: 14),
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Row(
                  children: [
                    Icon(
                      LucideIcons.clock,
                      size: 12,
                      color: scheme.onSurface.withValues(alpha: 0.4),
                    ),
                    const SizedBox(width: 8),
                    Text(
                      (log['date'] as String).toUpperCase(),
                      style: GoogleFonts.ebGaramond(
                        fontSize: 9,
                        fontWeight: FontWeight.w900,
                        color: scheme.onSurface.withValues(alpha: 0.68),
                        letterSpacing: 1,
                      ),
                    ),
                  ],
                ),
                Row(
                  children: [
                    Text(
                      'VIEW DETAILS',
                      style: GoogleFonts.ebGaramond(
                        fontSize: 8,
                        fontWeight: FontWeight.w900,
                        color: scheme.onSurface.withValues(alpha: 0.68),
                        letterSpacing: 1,
                      ),
                    ),
                    const SizedBox(width: 4),
                    Icon(
                      LucideIcons.chevronRight,
                      size: 12,
                      color: scheme.onSurface.withValues(alpha: 0.5),
                    ),
                  ],
                ),
              ],
            ),
          ],
        ),
      ),
    ).animate().fadeIn(delay: (index * 60).ms).slideY(begin: 0.1, end: 0);
  }

  // Web parity: the details modal is a fixed DARK sheet (web `bg-[#0d0d0d]`),
  // regardless of the app theme — light STATUS/ACTOR/data cards on a dark body.
  void _showLogDetails(Map<String, dynamic> log, ColorScheme scheme) {
    final statusColor = _statusColor(log['status'] as String);
    final details = (log['details'] as Map).cast<String, dynamic>();

    const sheetBg = Color(0xFF0D0D0D);
    const labelGrey = Color(0xFF8A8A8A);
    const summaryText = Color(0xFF9A9A9A);

    // Full-screen page (web parity — the log detail is its own page, not a
    // half-height sheet).
    Navigator.of(context).push(
      MaterialPageRoute(
        fullscreenDialog: true,
        builder: (ctx) => Scaffold(
          backgroundColor: sheetBg,
          body: SafeArea(
            child: Column(
              children: [
                Expanded(
                  child: SingleChildScrollView(
                    padding: const EdgeInsets.fromLTRB(28, 40, 28, 24),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Container(
                          padding: const EdgeInsets.symmetric(
                            horizontal: 18,
                            vertical: 11,
                          ),
                          decoration: BoxDecoration(
                            // Web parity: `bg-card` renders as a light/white pill
                            // with grey `text-[#666]` text on the dark modal.
                            color: Colors.white,
                            borderRadius: BorderRadius.circular(99),
                          ),
                          child: Text(
                            '${log['id']} • ${(log['type'] as String).toUpperCase()}',
                            style: GoogleFonts.gelasio(
                              fontSize: 10,
                              fontWeight: FontWeight.w900,
                              color: const Color(0xFF666666),
                              letterSpacing: 2,
                            ),
                          ),
                        ),
                        const SizedBox(height: 36),
                        IntrinsicHeight(
                          child: Row(
                            crossAxisAlignment: CrossAxisAlignment.stretch,
                            children: [
                              Expanded(
                                child: _darkDetailBox(
                                  'STATUS',
                                  log['status'] as String,
                                  dotColor: statusColor,
                                ),
                              ),
                              const SizedBox(width: 14),
                              Expanded(
                                child: _darkDetailBox(
                                  'ACTOR',
                                  log['actor'] as String,
                                  maxLines: 2,
                                ),
                              ),
                            ],
                          ),
                        ),
                        const SizedBox(height: 36),
                        Text(
                          'LOG SUMMARY',
                          style: GoogleFonts.gelasio(
                            fontSize: 11,
                            fontWeight: FontWeight.w900,
                            color: labelGrey,
                            letterSpacing: 2,
                          ),
                        ),
                        const SizedBox(height: 16),
                        Container(
                          width: double.infinity,
                          padding: const EdgeInsets.all(26),
                          decoration: BoxDecoration(
                            color: Colors.white.withValues(alpha: 0.03),
                            borderRadius: BorderRadius.circular(28),
                            border: Border.all(
                              color: Colors.white.withValues(alpha: 0.14),
                            ),
                          ),
                          child: Text(
                            (log['description'] as String).toUpperCase(),
                            style: GoogleFonts.ebGaramond(
                              fontSize: 12.5,
                              fontWeight: FontWeight.w700,
                              color: summaryText,
                              height: 1.7,
                              letterSpacing: 0.2,
                            ),
                          ),
                        ),
                        const SizedBox(height: 36),
                        Text(
                          'STRUCTURAL DATA',
                          style: GoogleFonts.gelasio(
                            fontSize: 11,
                            fontWeight: FontWeight.w900,
                            color: labelGrey,
                            letterSpacing: 2,
                          ),
                        ),
                        const SizedBox(height: 16),
                        Container(
                          decoration: BoxDecoration(
                            color: const Color(0xFFECECEE),
                            borderRadius: BorderRadius.circular(26),
                          ),
                          clipBehavior: Clip.antiAlias,
                          child: Column(
                            children: [
                              for (int i = 0; i < details.length; i++) ...[
                                if (i > 0)
                                  Divider(
                                    height: 1,
                                    color: Colors.black.withValues(alpha: 0.08),
                                  ),
                                Padding(
                                  padding: const EdgeInsets.symmetric(
                                    horizontal: 22,
                                    vertical: 20,
                                  ),
                                  child: Row(
                                    mainAxisAlignment:
                                        MainAxisAlignment.spaceBetween,
                                    children: [
                                      Text(
                                        details.keys.elementAt(i).toUpperCase(),
                                        style: GoogleFonts.ebGaramond(
                                          fontSize: 10,
                                          fontWeight: FontWeight.w800,
                                          color: Colors.black.withValues(
                                            alpha: 0.68,
                                          ),
                                          letterSpacing: 1,
                                        ),
                                      ),
                                      const SizedBox(width: 12),
                                      Flexible(
                                        child: Text(
                                          details.values
                                              .elementAt(i)
                                              .toString()
                                              .toUpperCase(),
                                          textAlign: TextAlign.right,
                                          style: GoogleFonts.ebGaramond(
                                            fontSize: 12,
                                            fontWeight: FontWeight.w900,
                                            color: Colors.black,
                                            letterSpacing: 0.2,
                                          ),
                                        ),
                                      ),
                                    ],
                                  ),
                                ),
                              ],
                            ],
                          ),
                        ),
                      ],
                    ),
                  ),
                ),
                SafeArea(
                  top: false,
                  child: Padding(
                    padding: const EdgeInsets.fromLTRB(28, 12, 28, 20),
                    child: SizedBox(
                      width: double.infinity,
                      height: 56,
                      child: ElevatedButton(
                        onPressed: () => Navigator.pop(ctx),
                        style: ElevatedButton.styleFrom(
                          backgroundColor: const Color(0xFF1A1A24),
                          foregroundColor: Colors.white,
                          elevation: 0,
                          shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(18),
                            side: BorderSide(
                              color: Colors.white.withValues(alpha: 0.08),
                            ),
                          ),
                        ),
                        child: Text(
                          'BACK TO OPERATIONAL LOGS',
                          style: GoogleFonts.gelasio(
                            fontSize: 11,
                            fontWeight: FontWeight.w900,
                            letterSpacing: 1.5,
                          ),
                        ),
                      ),
                    ),
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }

  // Light card used inside the dark details sheet (STATUS / ACTOR).
  Widget _darkDetailBox(
    String label,
    String value, {
    Color? dotColor,
    int maxLines = 1,
  }) {
    return Container(
      padding: const EdgeInsets.all(22),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(22),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            label,
            style: GoogleFonts.gelasio(
              fontSize: 10,
              fontWeight: FontWeight.w900,
              color: const Color(0xFF6B6B6B),
              letterSpacing: 1.5,
            ),
          ),
          const SizedBox(height: 12),
          Row(
            children: [
              if (dotColor != null) ...[
                Container(
                  width: 9,
                  height: 9,
                  decoration: BoxDecoration(
                    color: dotColor,
                    shape: BoxShape.circle,
                  ),
                ),
                const SizedBox(width: 8),
              ],
              Flexible(
                child: Text(
                  value.toUpperCase(),
                  style: GoogleFonts.ebGaramond(
                    fontSize: 14,
                    fontWeight: FontWeight.w900,
                    color: Colors.black,
                    letterSpacing: 0.2,
                    height: 1.25,
                  ),
                  maxLines: maxLines,
                  overflow: TextOverflow.ellipsis,
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }
}
