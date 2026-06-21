import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:intl/intl.dart';
import 'package:lucide_icons/lucide_icons.dart';
import 'package:m4_mobile/core/theme/app_theme.dart';
import 'package:m4_mobile/presentation/providers/auth_provider.dart';

/// `GET /api/investor/tax-reports` — Fiscal compliance documents
/// (Consolidated Tax Statement, Capital Gains, TDS, Dividend Income, etc.).
/// Web parity: app/investor/tax-reports/page.tsx
class InvestorTaxReportsScreen extends ConsumerStatefulWidget {
  const InvestorTaxReportsScreen({super.key});

  @override
  ConsumerState<InvestorTaxReportsScreen> createState() =>
      _InvestorTaxReportsScreenState();
}

class _InvestorTaxReportsScreenState
    extends ConsumerState<InvestorTaxReportsScreen> {
  static const Color _gold = Color(0xFFFFD700);

  List<dynamic> _rows = [];
  bool _loading = true;
  bool _error = false;
  String? _yearFilter;

  @override
  void initState() {
    super.initState();
    _load();
  }

  Future<void> _load() async {
    setState(() {
      _loading = true;
      _error = false;
    });
    try {
      final apiClient = ref.read(apiClientProvider);
      // Fetch the currently-selected year (or all rows on first load so the
      // year selector can surface every available FY).
      final res = await apiClient.get(
        '/api/investor/tax-reports',
        queryParameters: _yearFilter != null ? {'year': _yearFilter} : null,
      );
      if (!mounted) return;
      if (res.statusCode == 200 && res.data['status'] == true) {
        final d = res.data['data'];
        if (d is List) {
          _rows = List<dynamic>.from(d);
          // Default to the most recent year if none selected.
          if (_yearFilter == null && _years.isNotEmpty) {
            _yearFilter = _years.first;
          }
        }
      } else {
        _error = true;
      }
    } catch (_) {
      _error = true;
    }
    if (mounted) setState(() => _loading = false);
  }

  /// Distinct years, preserving the API ordering (newest first in the mock).
  List<String> get _years {
    final seen = <String>{};
    final out = <String>[];
    for (final r in _rows) {
      if (r is Map && r['year'] != null) {
        final y = r['year'].toString();
        if (seen.add(y)) out.add(y);
      }
    }
    return out;
  }

  List<Map<String, dynamic>> get _filtered {
    return _rows
        .whereType<Map>()
        .map((r) => Map<String, dynamic>.from(r))
        .where((m) => _yearFilter == null || m['year']?.toString() == _yearFilter)
        .toList();
  }

  /// Sum of TDS for the selected year — matches web's summary card.
  num get _totalTaxDeducted {
    num total = 0;
    for (final m in _filtered) {
      total += num.tryParse((m['totalTaxDeducted'] ?? 0).toString()) ?? 0;
    }
    return total;
  }

  void _toast(String msg) {
    if (!mounted) return;
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(content: Text(msg, style: GoogleFonts.montserrat(fontSize: 12))),
    );
  }

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final bg = isDark ? Colors.black : Colors.white;
    final textPrimary = isDark ? Colors.white : Colors.black;
    final muted = (isDark ? Colors.white : Colors.black).withValues(alpha: 0.5);
    final card = isDark ? Colors.white.withValues(alpha: 0.03) : Colors.white;
    final border = isDark
        ? Colors.white.withValues(alpha: 0.08)
        : Colors.black.withValues(alpha: 0.06);

    return Scaffold(
      backgroundColor: bg,
      appBar: AppBar(
        backgroundColor: bg,
        elevation: 0,
        leading: IconButton(
          icon: Icon(LucideIcons.arrowLeft, color: textPrimary),
          onPressed: () =>
              context.canPop() ? context.pop() : context.go('/investor/home'),
        ),
        title: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          mainAxisSize: MainAxisSize.min,
          children: [
            Text(
              'Tax Reports',
              style: GoogleFonts.montserrat(
                fontWeight: FontWeight.w800,
                fontSize: 16,
                color: textPrimary,
              ),
            ),
            Text(
              'FISCAL COMPLIANCE',
              style: GoogleFonts.montserrat(
                fontSize: 9,
                letterSpacing: 1.5,
                fontWeight: FontWeight.w600,
                color: muted,
              ),
            ),
          ],
        ),
      ),
      body: _loading
          ? const Center(
              child: CircularProgressIndicator(color: M4Theme.premiumBlue),
            )
          : _error
              ? _errorState(textPrimary, muted)
              : RefreshIndicator(
                  color: M4Theme.premiumBlue,
                  onRefresh: _load,
                  child: ListView(
                    physics: const AlwaysScrollableScrollPhysics(),
                    padding: EdgeInsets.zero,
                    children: [
                      _yearSelector(textPrimary, muted, card, border),
                      _summaryCard(isDark, textPrimary, muted, border),
                      _documentList(isDark, textPrimary, muted, card, border),
                      const SizedBox(height: 24),
                    ],
                  ),
                ),
    );
  }

  // ─── Error State ──────────────────────────────────────────────────────────────
  Widget _errorState(Color textPrimary, Color muted) {
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(32),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(LucideIcons.alertCircle, size: 40, color: muted),
            const SizedBox(height: 16),
            Text(
              'Unable to load tax reports.',
              textAlign: TextAlign.center,
              style: GoogleFonts.montserrat(
                fontSize: 13,
                fontWeight: FontWeight.w600,
                color: textPrimary,
              ),
            ),
            const SizedBox(height: 16),
            OutlinedButton.icon(
              onPressed: _load,
              icon: const Icon(LucideIcons.refreshCw, size: 14),
              style: OutlinedButton.styleFrom(
                foregroundColor: textPrimary,
                side: BorderSide(color: muted),
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(8),
                ),
              ),
              label: Text(
                'RETRY',
                style: GoogleFonts.montserrat(
                  fontSize: 10,
                  fontWeight: FontWeight.w700,
                  letterSpacing: 1,
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  // ─── Year Selector ──────────────────────────────────────────────────────────
  Widget _yearSelector(Color textPrimary, Color muted, Color card, Color border) {
    final years = _years;
    if (years.isEmpty) return const SizedBox.shrink();
    return Container(
      padding: const EdgeInsets.fromLTRB(16, 8, 16, 12),
      decoration: BoxDecoration(
        border: Border(bottom: BorderSide(color: border)),
      ),
      child: SingleChildScrollView(
        scrollDirection: Axis.horizontal,
        child: Row(
          children: years.map((year) {
            final selected = _yearFilter == year;
            return Padding(
              padding: const EdgeInsets.only(right: 8),
              child: GestureDetector(
                onTap: () => setState(() => _yearFilter = year),
                child: AnimatedContainer(
                  duration: const Duration(milliseconds: 200),
                  padding:
                      const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
                  decoration: BoxDecoration(
                    color: selected ? _gold : card,
                    borderRadius: BorderRadius.circular(10),
                    border: Border.all(color: selected ? _gold : border),
                    boxShadow: selected
                        ? [
                            BoxShadow(
                              color: _gold.withValues(alpha: 0.3),
                              blurRadius: 15,
                            ),
                          ]
                        : null,
                  ),
                  child: Text(
                    year.toUpperCase(),
                    style: GoogleFonts.montserrat(
                      fontSize: 10,
                      fontWeight: FontWeight.bold,
                      letterSpacing: 1,
                      color: selected ? Colors.black : muted,
                    ),
                  ),
                ),
              ),
            );
          }).toList(),
        ),
      ),
    );
  }

  // ─── Summary Card ─────────────────────────────────────────────────────────────
  Widget _summaryCard(bool isDark, Color textPrimary, Color muted, Color border) {
    final fmt =
        NumberFormat.currency(locale: 'en_IN', symbol: '₹', decimalDigits: 0);
    final total = _totalTaxDeducted;
    return Padding(
      padding: const EdgeInsets.fromLTRB(16, 16, 16, 8),
      child: Container(
        padding: const EdgeInsets.all(20),
        decoration: BoxDecoration(
          borderRadius: BorderRadius.circular(20),
          border: Border.all(color: border),
          gradient: LinearGradient(
            begin: Alignment.topLeft,
            end: Alignment.bottomRight,
            colors: [
              (isDark ? Colors.white : Colors.black).withValues(alpha: 0.05),
              Colors.transparent,
            ],
          ),
        ),
        child: Stack(
          clipBehavior: Clip.hardEdge,
          children: [
            // Watermark Award icon (top-right, opacity 10%).
            Positioned(
              top: -4,
              right: -4,
              child: Icon(
                LucideIcons.award,
                size: 96,
                color: textPrimary.withValues(alpha: 0.1),
              ),
            ),
            Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  'TOTAL TAX DEDUCTED',
                  style: GoogleFonts.montserrat(
                    fontSize: 9,
                    fontWeight: FontWeight.bold,
                    letterSpacing: 2,
                    color: muted,
                  ),
                ),
                const SizedBox(height: 4),
                Row(
                  crossAxisAlignment: CrossAxisAlignment.end,
                  children: [
                    Text(
                      fmt.format(total),
                      style: GoogleFonts.montserrat(
                        fontSize: 36,
                        fontWeight: FontWeight.w800,
                        height: 1,
                        letterSpacing: -0.5,
                        color: textPrimary,
                      ),
                    ),
                    Text(
                      '.00',
                      style: GoogleFonts.montserrat(
                        fontSize: 18,
                        fontWeight: FontWeight.w400,
                        color: muted,
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 16),
                OutlinedButton.icon(
                  onPressed: () => _toast('Downloading summary...'),
                  icon: const Icon(LucideIcons.download, size: 13),
                  style: OutlinedButton.styleFrom(
                    foregroundColor: textPrimary,
                    side: BorderSide(color: border),
                    padding:
                        const EdgeInsets.symmetric(horizontal: 14, vertical: 6),
                    minimumSize: const Size(0, 32),
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(8),
                    ),
                  ),
                  label: Text(
                    'DOWNLOAD SUMMARY',
                    style: GoogleFonts.montserrat(
                      fontSize: 9,
                      fontWeight: FontWeight.w600,
                      letterSpacing: 1,
                    ),
                  ),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }

  // ─── Document List ────────────────────────────────────────────────────────────
  Widget _documentList(
    bool isDark,
    Color textPrimary,
    Color muted,
    Color card,
    Color border,
  ) {
    final reports = _filtered;
    return Padding(
      padding: const EdgeInsets.fromLTRB(16, 8, 16, 0),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Padding(
            padding: const EdgeInsets.fromLTRB(4, 8, 4, 12),
            child: Text(
              'AVAILABLE DOCUMENTS',
              style: GoogleFonts.montserrat(
                fontSize: 10,
                fontWeight: FontWeight.bold,
                letterSpacing: 2,
                color: muted,
              ),
            ),
          ),
          if (reports.isEmpty)
            Padding(
              padding: const EdgeInsets.symmetric(vertical: 40),
              child: Center(
                child: Text(
                  'No reports found for this year.',
                  style: GoogleFonts.montserrat(fontSize: 10, color: muted),
                ),
              ),
            )
          else
            ...reports.asMap().entries.map(
                  (e) => _documentCard(
                    e.value,
                    e.key,
                    isDark,
                    textPrimary,
                    muted,
                    card,
                    border,
                  ),
                ),
        ],
      ),
    );
  }

  Widget _documentCard(
    Map<String, dynamic> m,
    int index,
    bool isDark,
    Color textPrimary,
    Color muted,
    Color card,
    Color border,
  ) {
    const red = Color(0xFFEF4444);
    final id = m['id']?.toString() ?? '';
    final name = m['name']?.toString() ?? 'Statement';
    final date = m['date']?.toString() ?? '';
    final size = m['size']?.toString() ?? '';

    return TweenAnimationBuilder<double>(
      key: ValueKey('$id-$_yearFilter'),
      tween: Tween(begin: 0, end: 1),
      duration: Duration(milliseconds: 250 + (index * 50)),
      curve: Curves.easeOut,
      builder: (context, t, child) => Opacity(
        opacity: t.clamp(0.0, 1.0),
        child: Transform.translate(
          offset: Offset(-10 * (1 - t), 0),
          child: child,
        ),
      ),
      child: Padding(
        padding: const EdgeInsets.only(bottom: 10),
        child: Material(
          color: isDark ? Colors.white.withValues(alpha: 0.03) : card,
          borderRadius: BorderRadius.circular(12),
          child: InkWell(
            borderRadius: BorderRadius.circular(12),
            onTap: id.isEmpty
                ? () => _toast('Opening $name')
                : () => context.push('/investor/tax-reports/$id', extra: m),
            child: Container(
              padding: const EdgeInsets.all(16),
              decoration: BoxDecoration(
                borderRadius: BorderRadius.circular(12),
                border: Border.all(color: border),
              ),
              child: Row(
                children: [
                  // File icon box.
                  Container(
                    width: 40,
                    height: 40,
                    decoration: BoxDecoration(
                      color: red.withValues(alpha: 0.1),
                      borderRadius: BorderRadius.circular(10),
                      border: Border.all(color: red.withValues(alpha: 0.2)),
                    ),
                    child: const Icon(LucideIcons.fileText, size: 20, color: red),
                  ),
                  const SizedBox(width: 16),
                  // Title + meta.
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          name,
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                          style: GoogleFonts.montserrat(
                            fontSize: 14,
                            fontWeight: FontWeight.w600,
                            color: textPrimary,
                          ),
                        ),
                        const SizedBox(height: 4),
                        Row(
                          children: [
                            Flexible(
                              child: Text(
                                date.toUpperCase(),
                                maxLines: 1,
                                overflow: TextOverflow.ellipsis,
                                style: GoogleFonts.montserrat(
                                  fontSize: 9,
                                  fontWeight: FontWeight.w500,
                                  letterSpacing: 1,
                                  color: muted,
                                ),
                              ),
                            ),
                            if (size.isNotEmpty) ...[
                              Padding(
                                padding:
                                    const EdgeInsets.symmetric(horizontal: 8),
                                child: Container(
                                  width: 3,
                                  height: 3,
                                  decoration: BoxDecoration(
                                    shape: BoxShape.circle,
                                    color: muted.withValues(alpha: 0.5),
                                  ),
                                ),
                              ),
                              Text(
                                size.toUpperCase(),
                                style: GoogleFonts.montserrat(
                                  fontSize: 9,
                                  fontWeight: FontWeight.w500,
                                  letterSpacing: 1,
                                  color: muted,
                                ),
                              ),
                            ],
                          ],
                        ),
                      ],
                    ),
                  ),
                  const SizedBox(width: 12),
                  // Download button (separate tap, stopPropagation equivalent).
                  Material(
                    color: card,
                    borderRadius: BorderRadius.circular(10),
                    child: InkWell(
                      borderRadius: BorderRadius.circular(10),
                      onTap: () => _toast('Downloading $name...'),
                      child: Container(
                        width: 32,
                        height: 32,
                        decoration: BoxDecoration(
                          borderRadius: BorderRadius.circular(10),
                          border: Border.all(color: border),
                        ),
                        child:
                            Icon(LucideIcons.download, size: 16, color: muted),
                      ),
                    ),
                  ),
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }
}
