import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:lucide_icons/lucide_icons.dart';
import 'package:flutter_animate/flutter_animate.dart';
import 'package:m4_mobile/core/theme/app_theme.dart';
import 'package:m4_mobile/presentation/providers/auth_provider.dart';

/// Web `/investor/installments` parity — INSTALLMENT SCHEDULE.
/// Fetches `GET /api/investor/installments`, maps each record into a milestone
/// row with status-based icon colors (green / amber / red), project title,
/// milestone name, amount and due date. Shows Paid / Due stats and status
/// filters above an animated list. Mirrors CP/investor list-screen styling.
class InvestorInstallmentsScreen extends ConsumerStatefulWidget {
  const InvestorInstallmentsScreen({super.key});

  @override
  ConsumerState<InvestorInstallmentsScreen> createState() =>
      _InvestorInstallmentsScreenState();
}

class _InvestorInstallmentsScreenState
    extends ConsumerState<InvestorInstallmentsScreen> {
  static const Color _gold = Color(0xFFFFD700);

  bool _loading = true;
  bool _error = false;
  List<_Installment> _installments = [];
  String _activeFilter = 'All';

  static const List<String> _filters = ['All', 'PAID', 'PENDING', 'OVERDUE'];

  static const List<String> _months = [
    'Jan', 'Feb', 'Mar', 'Apr', 'May', 'Jun',
    'Jul', 'Aug', 'Sep', 'Oct', 'Nov', 'Dec'
  ];

  @override
  void initState() {
    super.initState();
    _fetchInstallments();
  }

  Future<void> _fetchInstallments() async {
    setState(() {
      _loading = true;
      _error = false;
    });
    try {
      final apiClient = ref.read(apiClientProvider);
      final res = await apiClient.get('/api/investor/installments');
      if (!mounted) return;
      if (res.data is Map &&
          res.data['status'] == true &&
          res.data['data'] is List) {
        final list = List<dynamic>.from(res.data['data']);
        final today = DateTime.now();
        final mapped = list.map((raw) {
          final s = raw is Map ? raw : <String, dynamic>{};
          final dueRaw = (s['dueDate'] ?? s['createdAt'])?.toString();
          final dueDate = DateTime.tryParse(dueRaw ?? '');
          final rawStatus = (s['status'] ?? '').toString().toUpperCase();
          String status;
          if (rawStatus == 'PAID') {
            status = 'PAID';
          } else if (dueDate != null &&
              dueDate.isBefore(today) &&
              rawStatus != 'PAID') {
            status = 'OVERDUE';
          } else {
            status = 'PENDING';
          }

          final amount = _toNum(s['amountDue'] ?? s['amount']);

          final project = s['project'];
          final investment = s['investmentId'];
          String projectTitle = 'Investment';
          if (project is Map && project['title'] != null) {
            projectTitle = project['title'].toString();
          } else if (investment is Map &&
              investment['projectId'] is Map &&
              (investment['projectId'] as Map)['title'] != null) {
            projectTitle = (investment['projectId'] as Map)['title'].toString();
          }

          return _Installment(
            id: (s['_id'] ?? s['id'] ?? '').toString(),
            projectTitle: projectTitle,
            milestoneName:
                (s['milestoneName'] ?? 'Installment Payment').toString(),
            amount: amount,
            dueDate: dueDate != null ? _formatDate(dueDate) : '--',
            status: status,
          );
        }).toList();

        setState(() {
          _installments = mapped;
          _loading = false;
        });
      } else {
        setState(() {
          _installments = [];
          _loading = false;
        });
      }
    } catch (_) {
      if (!mounted) return;
      setState(() {
        _error = true;
        _loading = false;
      });
    }
  }

  double _toNum(dynamic v) {
    if (v is num) return v.toDouble();
    if (v is String) return double.tryParse(v) ?? 0;
    return 0;
  }

  String _formatDate(DateTime d) => '${d.day} ${_months[d.month - 1]} ${d.year}';

  String _formatAmount(double amount) {
    final whole = amount.round().toString();
    final buffer = StringBuffer();
    final digits = whole.length;
    for (int i = 0; i < digits; i++) {
      buffer.write(whole[i]);
      final remaining = digits - i - 1;
      if (remaining > 3 && (remaining - 3) % 2 == 0) {
        buffer.write(',');
      } else if (remaining == 3) {
        buffer.write(',');
      }
    }
    return '₹${buffer.toString()}';
  }

  Color _statusColor(String status) {
    switch (status) {
      case 'PAID':
        return const Color(0xFF34D399); // green
      case 'OVERDUE':
        return const Color(0xFFF87171); // red
      default:
        return const Color(0xFFFBBF24); // amber
    }
  }

  IconData _statusIcon(String status) {
    switch (status) {
      case 'PAID':
        return LucideIcons.checkCircle2;
      case 'OVERDUE':
        return LucideIcons.alertCircle;
      default:
        return LucideIcons.clock;
    }
  }

  String _statusLabel(String status) {
    switch (status) {
      case 'PAID':
        return 'Paid';
      case 'OVERDUE':
        return 'Overdue';
      case 'PENDING':
        return 'Pending';
      default:
        return 'All';
    }
  }

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final bg = isDark ? Colors.black : Colors.white;
    final textPrimary = isDark ? Colors.white : Colors.black;
    final muted = (isDark ? Colors.white : Colors.black).withValues(alpha: 0.5);
    final border = isDark
        ? Colors.white.withValues(alpha: 0.08)
        : Colors.black.withValues(alpha: 0.06);

    final filtered = _activeFilter == 'All'
        ? _installments
        : _installments.where((i) => i.status == _activeFilter).toList();

    final totalPaid = _installments
        .where((i) => i.status == 'PAID')
        .fold<double>(0, (sum, i) => sum + i.amount);
    final totalDue = _installments
        .where((i) => i.status == 'PENDING' || i.status == 'OVERDUE')
        .fold<double>(0, (sum, i) => sum + i.amount);

    return Scaffold(
      backgroundColor: bg,
      body: SafeArea(
        child: Column(
          children: [
            // ─── Header ─────────────────────────────────
            Padding(
              padding: const EdgeInsets.fromLTRB(24, 20, 24, 16),
              child: Row(
                children: [
                  GestureDetector(
                    onTap: () => context.canPop()
                        ? context.pop()
                        : context.go('/investor/home'),
                    child: Container(
                      width: 48,
                      height: 48,
                      decoration: BoxDecoration(
                        color: (isDark ? Colors.white : Colors.black)
                            .withValues(alpha: 0.04),
                        shape: BoxShape.circle,
                        border: Border.all(color: border),
                      ),
                      child: Icon(LucideIcons.chevronLeft,
                          size: 20, color: textPrimary),
                    ),
                  ),
                  const SizedBox(width: 16),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          'INSTALLMENT SCHEDULE',
                          style: GoogleFonts.montserrat(
                            fontSize: 20,
                            fontWeight: FontWeight.w900,
                            letterSpacing: -0.5,
                            color: textPrimary,
                          ),
                        ),
                        const SizedBox(height: 2),
                        Text(
                          'PAYMENT PLAN',
                          style: GoogleFonts.montserrat(
                            fontSize: 8,
                            fontWeight: FontWeight.w900,
                            letterSpacing: 2,
                            color: muted,
                          ),
                        ),
                      ],
                    ),
                  ),
                ],
              ),
            ),

            // ─── Body ───────────────────────────────────
            Expanded(
              child: _loading
                  ? const Center(
                      child: CircularProgressIndicator(
                          color: M4Theme.premiumBlue),
                    )
                  : _error
                      ? _buildError(isDark, textPrimary, muted)
                      : RefreshIndicator(
                          onRefresh: _fetchInstallments,
                          color: M4Theme.premiumBlue,
                          child: CustomScrollView(
                            physics: const AlwaysScrollableScrollPhysics(),
                            slivers: [
                              // Stats
                              SliverToBoxAdapter(
                                child: _buildStats(
                                  isDark: isDark,
                                  border: border,
                                  muted: muted,
                                  totalPaid: totalPaid,
                                  totalDue: totalDue,
                                ),
                              ),
                              // Filters
                              SliverToBoxAdapter(
                                child: _buildFilters(
                                  isDark: isDark,
                                  border: border,
                                  muted: muted,
                                ),
                              ),
                              // List / Empty
                              if (filtered.isEmpty)
                                SliverFillRemaining(
                                  hasScrollBody: false,
                                  child: _buildEmpty(muted),
                                )
                              else
                                SliverPadding(
                                  padding: const EdgeInsets.fromLTRB(
                                      24, 16, 24, 32),
                                  sliver: SliverList(
                                    delegate: SliverChildBuilderDelegate(
                                      (context, index) {
                                        final item = filtered[index];
                                        return Padding(
                                          padding:
                                              const EdgeInsets.only(bottom: 12),
                                          child: _buildRow(
                                            item: item,
                                            isDark: isDark,
                                            border: border,
                                            textPrimary: textPrimary,
                                            muted: muted,
                                          ),
                                        )
                                            .animate()
                                            .fadeIn(delay: (index * 50).ms)
                                            .moveY(begin: 10, end: 0);
                                      },
                                      childCount: filtered.length,
                                    ),
                                  ),
                                ),
                            ],
                          ),
                        ),
            ),
          ],
        ),
      ),
    );
  }

  // ─── Stats ──────────────────────────────────────────────
  Widget _buildStats({
    required bool isDark,
    required Color border,
    required Color muted,
    required double totalPaid,
    required double totalDue,
  }) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 18),
      decoration: BoxDecoration(
        color: (isDark ? Colors.white : Colors.black).withValues(alpha: 0.02),
        border: Border(bottom: BorderSide(color: border)),
      ),
      child: Row(
        children: [
          Expanded(
            child: _statTile(
              label: 'PAID',
              value: _formatAmount(totalPaid),
              color: const Color(0xFF34D399),
              muted: muted,
            ),
          ),
          Container(
            width: 1,
            height: 40,
            color: border,
          ),
          const SizedBox(width: 16),
          Expanded(
            child: _statTile(
              label: 'DUE / REMAINING',
              value: _formatAmount(totalDue),
              color: const Color(0xFFFBBF24),
              muted: muted,
            ),
          ),
        ],
      ),
    );
  }

  Widget _statTile({
    required String label,
    required String value,
    required Color color,
    required Color muted,
  }) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          label,
          style: GoogleFonts.montserrat(
            fontSize: 8,
            fontWeight: FontWeight.w900,
            letterSpacing: 1.5,
            color: muted,
          ),
        ),
        const SizedBox(height: 6),
        Text(
          value,
          style: GoogleFonts.montserrat(
            fontSize: 15,
            fontWeight: FontWeight.w900,
            color: color,
          ),
        ),
      ],
    );
  }

  // ─── Filters ────────────────────────────────────────────
  Widget _buildFilters({
    required bool isDark,
    required Color border,
    required Color muted,
  }) {
    return Container(
      padding: const EdgeInsets.fromLTRB(24, 16, 24, 8),
      decoration: BoxDecoration(
        border: Border(bottom: BorderSide(color: border)),
      ),
      child: Wrap(
        spacing: 8,
        runSpacing: 8,
        children: _filters.map((f) {
          final active = _activeFilter == f;
          const activeColor = Color(0xFFFBBF24);
          return GestureDetector(
            onTap: () => setState(() => _activeFilter = f),
            child: Container(
              padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 8),
              decoration: BoxDecoration(
                color: active
                    ? activeColor.withValues(alpha: 0.1)
                    : (isDark ? Colors.white : Colors.black)
                        .withValues(alpha: 0.03),
                borderRadius: BorderRadius.circular(8),
                border: Border.all(
                  color: active
                      ? activeColor.withValues(alpha: 0.3)
                      : border,
                ),
              ),
              child: Text(
                (f == 'All' ? 'All' : _statusLabel(f)).toUpperCase(),
                style: GoogleFonts.montserrat(
                  fontSize: 9,
                  fontWeight: FontWeight.w800,
                  letterSpacing: 1,
                  color: active ? activeColor : muted,
                ),
              ),
            ),
          );
        }).toList(),
      ),
    );
  }

  // ─── Installment Row ────────────────────────────────────
  Widget _buildRow({
    required _Installment item,
    required bool isDark,
    required Color border,
    required Color textPrimary,
    required Color muted,
  }) {
    final color = _statusColor(item.status);
    final cardBg =
        isDark ? Colors.white.withValues(alpha: 0.03) : Colors.white;

    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: cardBg,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: border),
        boxShadow: isDark
            ? []
            : [
                BoxShadow(
                  color: Colors.black.withValues(alpha: 0.04),
                  blurRadius: 20,
                  offset: const Offset(0, 8),
                ),
              ],
      ),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Status icon
          Container(
            width: 38,
            height: 38,
            decoration: BoxDecoration(
              color: color.withValues(alpha: 0.1),
              borderRadius: BorderRadius.circular(10),
              border: Border.all(color: color.withValues(alpha: 0.3)),
            ),
            child: Icon(_statusIcon(item.status), color: color, size: 18),
          ),
          const SizedBox(width: 12),
          // Milestone + project + date
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  item.milestoneName,
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                  style: GoogleFonts.montserrat(
                    fontSize: 12,
                    fontWeight: FontWeight.w700,
                    color: textPrimary,
                  ),
                ),
                const SizedBox(height: 2),
                Text(
                  item.projectTitle,
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                  style: GoogleFonts.montserrat(
                    fontSize: 9,
                    fontWeight: FontWeight.w500,
                    color: muted,
                  ),
                ),
                const SizedBox(height: 4),
                Row(
                  children: [
                    Icon(LucideIcons.calendarClock,
                        size: 10,
                        color: muted.withValues(alpha: 0.7)),
                    const SizedBox(width: 4),
                    Text(
                      item.dueDate,
                      style: GoogleFonts.montserrat(
                        fontSize: 9,
                        fontWeight: FontWeight.w500,
                        color: muted,
                      ),
                    ),
                  ],
                ),
              ],
            ),
          ),
          const SizedBox(width: 10),
          // Amount + status pill
          Column(
            crossAxisAlignment: CrossAxisAlignment.end,
            children: [
              Text(
                _formatAmount(item.amount),
                style: GoogleFonts.montserrat(
                  fontSize: 14,
                  fontWeight: FontWeight.w900,
                  color: textPrimary,
                ),
              ),
              const SizedBox(height: 6),
              Container(
                padding:
                    const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
                decoration: BoxDecoration(
                  color: color.withValues(alpha: 0.1),
                  borderRadius: BorderRadius.circular(6),
                  border: Border.all(color: color.withValues(alpha: 0.3)),
                ),
                child: Text(
                  _statusLabel(item.status).toUpperCase(),
                  style: GoogleFonts.montserrat(
                    fontSize: 8,
                    fontWeight: FontWeight.w900,
                    letterSpacing: 0.8,
                    color: color,
                  ),
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }

  // ─── Empty State ────────────────────────────────────────
  Widget _buildEmpty(Color muted) {
    return Center(
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 32, vertical: 48),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(LucideIcons.calendarClock,
                size: 44, color: muted.withValues(alpha: 0.4)),
            const SizedBox(height: 16),
            Text(
              'NO INSTALLMENTS FOUND',
              textAlign: TextAlign.center,
              style: GoogleFonts.montserrat(
                fontSize: 11,
                fontWeight: FontWeight.w900,
                letterSpacing: 1.5,
                color: muted,
              ),
            ),
            const SizedBox(height: 8),
            Text(
              'Your payment schedule will appear here once an investment is confirmed.',
              textAlign: TextAlign.center,
              style: GoogleFonts.montserrat(
                fontSize: 10,
                fontWeight: FontWeight.w500,
                height: 1.5,
                color: muted,
              ),
            ),
          ],
        ),
      ),
    );
  }

  // ─── Error State ────────────────────────────────────────
  Widget _buildError(bool isDark, Color textPrimary, Color muted) {
    return Center(
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 32),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(LucideIcons.alertTriangle,
                size: 44, color: _gold.withValues(alpha: 0.8)),
            const SizedBox(height: 16),
            Text(
              'COULD NOT LOAD SCHEDULE',
              textAlign: TextAlign.center,
              style: GoogleFonts.montserrat(
                fontSize: 11,
                fontWeight: FontWeight.w900,
                letterSpacing: 1.5,
                color: textPrimary,
              ),
            ),
            const SizedBox(height: 8),
            Text(
              'Please check your connection and try again.',
              textAlign: TextAlign.center,
              style: GoogleFonts.montserrat(
                fontSize: 10,
                fontWeight: FontWeight.w500,
                color: muted,
              ),
            ),
            const SizedBox(height: 20),
            GestureDetector(
              onTap: _fetchInstallments,
              child: Container(
                padding:
                    const EdgeInsets.symmetric(horizontal: 24, vertical: 12),
                decoration: BoxDecoration(
                  color: M4Theme.premiumBlue,
                  borderRadius: BorderRadius.circular(12),
                ),
                child: Text(
                  'RETRY',
                  style: GoogleFonts.montserrat(
                    fontSize: 10,
                    fontWeight: FontWeight.w900,
                    letterSpacing: 1.5,
                    color: Colors.white,
                  ),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _Installment {
  final String id;
  final String projectTitle;
  final String milestoneName;
  final double amount;
  final String dueDate;
  final String status;

  const _Installment({
    required this.id,
    required this.projectTitle,
    required this.milestoneName,
    required this.amount,
    required this.dueDate,
    required this.status,
  });
}
