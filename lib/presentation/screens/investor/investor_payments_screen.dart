import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:lucide_icons/lucide_icons.dart';
import 'package:m4_mobile/core/theme/app_theme.dart';
import 'package:m4_mobile/presentation/providers/auth_provider.dart';

/// Investor payment-history ledger — mirrors web `/investor/payments`
/// (`GET /api/payment-schedule`). Lists invested / returns / dividend
/// transactions with search, type filter, status badges and direction icons.
class InvestorPaymentsScreen extends ConsumerStatefulWidget {
  const InvestorPaymentsScreen({super.key});

  @override
  ConsumerState<InvestorPaymentsScreen> createState() => _InvestorPaymentsScreenState();
}

class _InvestorPaymentsScreenState extends ConsumerState<InvestorPaymentsScreen> {
  static const _gold = Color(0xFFFFD700);
  static const _green = Color(0xFF22C55E);

  bool _loading = true;
  bool _error = false;
  List<Map<String, dynamic>> _transactions = [];
  String _searchQuery = '';
  String _filter = 'All';

  static const List<String> _filterOptions = ['All', 'Investment', 'Dividend', 'Fee', 'Refund'];

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) => _load());
  }

  Future<void> _load() async {
    setState(() {
      _loading = true;
      _error = false;
    });
    try {
      final apiClient = ref.read(apiClientProvider);
      final res = await apiClient.get('/api/payment-schedule');
      final body = res.data;
      List<dynamic> schedules = [];
      if (body is Map) {
        final data = body['data'];
        if (data is Map && data['schedules'] is List) {
          schedules = List<dynamic>.from(data['schedules'] as List);
        } else if (data is List) {
          schedules = List<dynamic>.from(data);
        }
      }
      final mapped = schedules.whereType<Map>().map<Map<String, dynamic>>((s) {
        final m = Map<String, dynamic>.from(s);
        final project = m['projectId'];
        final projectTitle = project is Map ? project['title']?.toString() : null;
        final num amount = (m['amountDue'] ?? m['amount'] ?? 0) as num? ?? 0;
        final status = (m['status'] ?? '').toString();
        return {
          'id': (m['_id'] ?? '').toString(),
          'description': (m['milestoneName'] ?? projectTitle ?? 'Investment Payment').toString(),
          'type': (m['type'] ?? 'Investment').toString(),
          'rawAmount': amount,
          'date': (m['dueDate'] ?? m['createdAt'] ?? '').toString(),
          'status': status,
          'direction': status.toUpperCase() == 'PAID' ? 'in' : 'out',
        };
      }).toList();
      if (!mounted) return;
      setState(() => _transactions = mapped);
    } catch (_) {
      if (!mounted) return;
      setState(() => _error = true);
    } finally {
      if (mounted) setState(() => _loading = false);
    }
  }

  String _formatAmount(num value) {
    final whole = value.round();
    final str = whole.abs().toString();
    final buf = StringBuffer();
    for (int i = 0; i < str.length; i++) {
      if (i > 0 && (str.length - i) % 3 == 0) buf.write(',');
      buf.write(str[i]);
    }
    return '${whole < 0 ? '-' : ''}${buf.toString()}';
  }

  String _formatDate(String raw) {
    final dt = DateTime.tryParse(raw);
    if (dt == null) return raw;
    const months = [
      'Jan', 'Feb', 'Mar', 'Apr', 'May', 'Jun',
      'Jul', 'Aug', 'Sep', 'Oct', 'Nov', 'Dec'
    ];
    return '${dt.day} ${months[dt.month - 1]} ${dt.year}';
  }

  List<Map<String, dynamic>> get _filtered {
    final q = _searchQuery.toLowerCase();
    return _transactions.where((t) {
      final desc = (t['description'] ?? '').toString().toLowerCase();
      final id = (t['id'] ?? '').toString().toLowerCase();
      final matchesSearch = q.isEmpty || desc.contains(q) || id.contains(q);
      if (_filter == 'All') return matchesSearch;
      return matchesSearch && (t['type'] ?? '').toString() == _filter;
    }).toList();
  }

  num get _totalInvested => _transactions
      .where((t) => t['direction'] == 'out' && (t['status'] ?? '').toString().toUpperCase() == 'PAID')
      .fold<num>(0, (sum, t) => sum + ((t['rawAmount'] ?? 0) as num));

  num get _totalReturns => _transactions
      .where((t) => t['direction'] == 'in')
      .fold<num>(0, (sum, t) => sum + ((t['rawAmount'] ?? 0) as num));

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final bg = isDark ? Colors.black : Colors.white;
    final textPrimary = isDark ? Colors.white : Colors.black;
    final muted = (isDark ? Colors.white : Colors.black).withValues(alpha: 0.5);
    final border = isDark ? Colors.white.withValues(alpha: 0.08) : Colors.black.withValues(alpha: 0.06);

    return Scaffold(
      backgroundColor: bg,
      appBar: AppBar(
        backgroundColor: bg,
        elevation: 0,
        leading: IconButton(
          icon: Icon(LucideIcons.arrowLeft, color: textPrimary),
          onPressed: () => context.canPop() ? context.pop() : context.go('/investor/home'),
        ),
        title: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              'Payment History',
              style: GoogleFonts.montserrat(color: textPrimary, fontWeight: FontWeight.w800, fontSize: 16),
            ),
            Text(
              'FINANCIAL LEDGER',
              style: GoogleFonts.montserrat(color: muted, fontWeight: FontWeight.w900, fontSize: 8, letterSpacing: 3),
            ),
          ],
        ),
      ),
      body: _loading
          ? const Center(child: CircularProgressIndicator(color: M4Theme.premiumBlue))
          : _error
              ? _buildError(textPrimary, muted)
              : RefreshIndicator(
                  color: M4Theme.premiumBlue,
                  onRefresh: _load,
                  child: ListView(
                    physics: const AlwaysScrollableScrollPhysics(),
                    padding: const EdgeInsets.fromLTRB(20, 8, 20, 32),
                    children: [
                      _buildStats(isDark, textPrimary, muted, border),
                      const SizedBox(height: 20),
                      _buildSearch(isDark, textPrimary, muted, border),
                      const SizedBox(height: 12),
                      _buildFilters(isDark, muted, border),
                      const SizedBox(height: 20),
                      ..._buildList(isDark, textPrimary, muted, border),
                    ],
                  ),
                ),
    );
  }

  Widget _buildStats(bool isDark, Color textPrimary, Color muted, Color border) {
    final card = isDark ? Colors.white.withValues(alpha: 0.03) : Colors.white;
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 4, vertical: 16),
      decoration: BoxDecoration(
        color: card,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: border),
      ),
      child: Row(
        children: [
          Expanded(child: _statCell('TOTAL INVESTED', 'AED ${_formatAmount(_totalInvested)}', textPrimary, muted)),
          Container(width: 1, height: 36, color: border),
          Expanded(child: _statCell('TOTAL RETURNS', 'AED ${_formatAmount(_totalReturns)}', _green, muted)),
        ],
      ),
    );
  }

  Widget _statCell(String label, String value, Color valueColor, Color muted) {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 12),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            label,
            style: GoogleFonts.montserrat(color: muted, fontSize: 8, fontWeight: FontWeight.w900, letterSpacing: 1.5),
          ),
          const SizedBox(height: 6),
          Text(
            value,
            style: GoogleFonts.montserrat(color: valueColor, fontSize: 14, fontWeight: FontWeight.w800),
          ),
        ],
      ),
    );
  }

  Widget _buildSearch(bool isDark, Color textPrimary, Color muted, Color border) {
    final card = isDark ? Colors.white.withValues(alpha: 0.03) : Colors.white;
    return TextField(
      onChanged: (v) => setState(() => _searchQuery = v),
      style: GoogleFonts.montserrat(color: textPrimary, fontSize: 13, fontWeight: FontWeight.w500),
      decoration: InputDecoration(
        hintText: 'Search transactions...',
        hintStyle: GoogleFonts.montserrat(color: muted, fontSize: 13, fontWeight: FontWeight.w500),
        prefixIcon: Icon(LucideIcons.search, size: 18, color: muted),
        filled: true,
        fillColor: card,
        isDense: true,
        contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
        border: OutlineInputBorder(borderRadius: BorderRadius.circular(12), borderSide: BorderSide(color: border)),
        enabledBorder: OutlineInputBorder(borderRadius: BorderRadius.circular(12), borderSide: BorderSide(color: border)),
        focusedBorder: OutlineInputBorder(borderRadius: BorderRadius.circular(12), borderSide: BorderSide(color: muted)),
      ),
    );
  }

  Widget _buildFilters(bool isDark, Color muted, Color border) {
    final card = isDark ? Colors.white.withValues(alpha: 0.03) : Colors.white;
    return Wrap(
      spacing: 8,
      runSpacing: 8,
      children: _filterOptions.map((f) {
        final selected = _filter == f;
        return GestureDetector(
          onTap: () => setState(() => _filter = f),
          child: Container(
            padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 8),
            decoration: BoxDecoration(
              color: selected ? _gold.withValues(alpha: 0.12) : card,
              borderRadius: BorderRadius.circular(10),
              border: Border.all(color: selected ? _gold.withValues(alpha: 0.4) : border),
            ),
            child: Text(
              f.toUpperCase(),
              style: GoogleFonts.montserrat(
                color: selected ? _gold : muted,
                fontSize: 9,
                fontWeight: FontWeight.w800,
                letterSpacing: 1,
              ),
            ),
          ),
        );
      }).toList(),
    );
  }

  List<Widget> _buildList(bool isDark, Color textPrimary, Color muted, Color border) {
    final items = _filtered;
    if (items.isEmpty) {
      return [_buildEmpty(textPrimary, muted)];
    }
    return items.map((t) => _buildRow(t, isDark, textPrimary, muted, border)).toList();
  }

  Widget _buildRow(Map<String, dynamic> t, bool isDark, Color textPrimary, Color muted, Color border) {
    final card = isDark ? Colors.white.withValues(alpha: 0.03) : Colors.white;
    final isIn = t['direction'] == 'in';
    final status = (t['status'] ?? '').toString();
    final statusUpper = status.toUpperCase();
    final num amount = (t['rawAmount'] ?? 0) as num;
    final id = (t['id'] ?? '').toString();
    final shortId = id.length > 6 ? id.substring(id.length - 6).toUpperCase() : id.toUpperCase();

    Color statusColor;
    if (statusUpper == 'PAID') {
      statusColor = _green;
    } else if (statusUpper == 'PENDING') {
      statusColor = const Color(0xFFF59E0B);
    } else {
      statusColor = muted;
    }

    return Container(
      margin: const EdgeInsets.only(bottom: 10),
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: card,
        borderRadius: BorderRadius.circular(14),
        border: Border.all(color: border),
      ),
      child: Row(
        children: [
          Container(
            width: 40,
            height: 40,
            decoration: BoxDecoration(
              color: isIn ? _green.withValues(alpha: 0.1) : (isDark ? Colors.white.withValues(alpha: 0.05) : Colors.black.withValues(alpha: 0.04)),
              borderRadius: BorderRadius.circular(10),
              border: Border.all(color: isIn ? _green.withValues(alpha: 0.2) : border),
            ),
            child: Icon(
              isIn ? LucideIcons.arrowDownLeft : LucideIcons.arrowUpRight,
              size: 18,
              color: isIn ? _green : muted,
            ),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  (t['description'] ?? '').toString(),
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                  style: GoogleFonts.montserrat(color: textPrimary, fontSize: 12.5, fontWeight: FontWeight.w700),
                ),
                const SizedBox(height: 4),
                Row(
                  children: [
                    Flexible(
                      child: Text(
                        _formatDate((t['date'] ?? '').toString()),
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                        style: GoogleFonts.montserrat(color: muted, fontSize: 9, fontWeight: FontWeight.w600, letterSpacing: 0.5),
                      ),
                    ),
                    if (shortId.isNotEmpty) ...[
                      Container(
                        width: 3,
                        height: 3,
                        margin: const EdgeInsets.symmetric(horizontal: 6),
                        decoration: BoxDecoration(color: muted, shape: BoxShape.circle),
                      ),
                      Text(
                        shortId,
                        style: GoogleFonts.montserrat(color: muted, fontSize: 9, fontWeight: FontWeight.w600, letterSpacing: 0.5),
                      ),
                    ],
                  ],
                ),
              ],
            ),
          ),
          const SizedBox(width: 8),
          Column(
            crossAxisAlignment: CrossAxisAlignment.end,
            children: [
              Text(
                '${isIn ? '+' : ''}AED ${_formatAmount(amount)}',
                style: GoogleFonts.montserrat(
                  color: isIn ? _green : textPrimary,
                  fontSize: 13,
                  fontWeight: FontWeight.w800,
                ),
              ),
              const SizedBox(height: 4),
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
                decoration: BoxDecoration(
                  color: statusColor.withValues(alpha: 0.1),
                  borderRadius: BorderRadius.circular(6),
                  border: Border.all(color: statusColor.withValues(alpha: 0.25)),
                ),
                child: Text(
                  statusUpper.isEmpty ? '—' : statusUpper,
                  style: GoogleFonts.montserrat(color: statusColor, fontSize: 8, fontWeight: FontWeight.w800, letterSpacing: 0.5),
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildEmpty(Color textPrimary, Color muted) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 64),
      child: Column(
        children: [
          Icon(LucideIcons.creditCard, size: 36, color: muted.withValues(alpha: 0.6)),
          const SizedBox(height: 16),
          Text(
            'No transactions found',
            style: GoogleFonts.montserrat(color: textPrimary, fontSize: 13, fontWeight: FontWeight.w700),
          ),
          const SizedBox(height: 6),
          Text(
            'Your payment ledger is empty.',
            style: GoogleFonts.montserrat(color: muted, fontSize: 11, fontWeight: FontWeight.w500),
          ),
        ],
      ),
    );
  }

  Widget _buildError(Color textPrimary, Color muted) {
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(32),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(LucideIcons.alertTriangle, size: 36, color: muted),
            const SizedBox(height: 16),
            Text(
              'Unable to load payments',
              style: GoogleFonts.montserrat(color: textPrimary, fontSize: 14, fontWeight: FontWeight.w700),
            ),
            const SizedBox(height: 6),
            Text(
              'Please check your connection and try again.',
              textAlign: TextAlign.center,
              style: GoogleFonts.montserrat(color: muted, fontSize: 11, fontWeight: FontWeight.w500),
            ),
            const SizedBox(height: 20),
            ElevatedButton(
              onPressed: _load,
              style: ElevatedButton.styleFrom(
                backgroundColor: M4Theme.premiumBlue,
                foregroundColor: Colors.white,
                shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
              ),
              child: Text('RETRY', style: GoogleFonts.montserrat(fontSize: 12, fontWeight: FontWeight.w800, letterSpacing: 1)),
            ),
          ],
        ),
      ),
    );
  }
}
