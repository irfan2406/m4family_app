import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:lucide_icons/lucide_icons.dart';
import 'package:m4_mobile/core/theme/app_theme.dart';
import 'package:m4_mobile/presentation/providers/auth_provider.dart';

/// Web `/investor/tax-reports/[id]` — a single fiscal compliance document
/// detail. Backed by `GET /api/investor/tax-reports`; the matching row is
/// located by `id` (no dedicated per-id endpoint), mirroring the web detail
/// page which renders a document overview, encrypted & verified badges,
/// metadata (generated date, file size, status), a description, a secure-note
/// warning, and open / download actions.
class InvestorTaxReportDetailScreen extends ConsumerStatefulWidget {
  final String reportId;
  final Map<String, dynamic>? initialData;

  const InvestorTaxReportDetailScreen({
    super.key,
    required this.reportId,
    this.initialData,
  });

  @override
  ConsumerState<InvestorTaxReportDetailScreen> createState() =>
      _InvestorTaxReportDetailScreenState();
}

class _InvestorTaxReportDetailScreenState
    extends ConsumerState<InvestorTaxReportDetailScreen> {
  Map<String, dynamic>? _report;
  bool _loading = true;
  bool _error = false;

  @override
  void initState() {
    super.initState();
    if (widget.initialData != null) {
      _report = Map<String, dynamic>.from(widget.initialData!);
    }
    _load();
  }

  Future<void> _load() async {
    setState(() {
      _loading = true;
      _error = false;
    });
    try {
      final apiClient = ref.read(apiClientProvider);
      final res = await apiClient.getInvestorTaxReports();
      if (!mounted) return;
      if (res.statusCode == 200 && res.data['status'] == true) {
        final d = res.data['data'];
        if (d is List) {
          final match = d.whereType<Map>().cast<Map>().firstWhere(
                (m) =>
                    (m['id']?.toString() ?? m['_id']?.toString() ?? '') ==
                    widget.reportId,
                orElse: () => const {},
              );
          if (match.isNotEmpty) {
            _report = Map<String, dynamic>.from(match);
          } else if (_report == null) {
            _error = true;
          }
        } else if (_report == null) {
          _error = true;
        }
      } else if (_report == null) {
        _error = true;
      }
    } catch (_) {
      if (_report == null) _error = true;
    }
    if (mounted) setState(() => _loading = false);
  }

  void _open() {
    if (!mounted) return;
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(
          'Opening $_name...',
          style: GoogleFonts.montserrat(fontSize: 12),
        ),
      ),
    );
  }

  void _download() {
    if (!mounted) return;
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(
          'Downloading $_name...',
          style: GoogleFonts.montserrat(fontSize: 12),
        ),
      ),
    );
  }

  String get _name => _report?['name']?.toString() ?? 'Tax Statement';
  String get _id => _report?['id']?.toString() ?? widget.reportId;
  String get _date => _report?['date']?.toString() ?? '';
  String get _size => _report?['size']?.toString() ?? '';
  String get _year => _report?['year']?.toString() ?? '';
  String get _type => _report?['type']?.toString() ?? 'PDF';
  String get _status => _report?['status']?.toString() ?? 'Available';
  bool get _isReady => _status.toLowerCase() == 'available';
  String get _description =>
      _report?['description']?.toString() ??
      'This is an official fiscal compliance document covering your '
          'investments and returns for the selected period. Keep this '
          'statement for your records and income tax filings.';

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final bg = isDark ? Colors.black : Colors.white;
    final textPrimary = isDark ? Colors.white : Colors.black;
    final muted = (isDark ? Colors.white : Colors.black).withValues(alpha: 0.5);

    return Scaffold(
      backgroundColor: bg,
      body: SafeArea(
        child: Column(
          children: [
            _header(textPrimary, muted, isDark),
            Expanded(
              child: _loading && _report == null
                  ? const Center(
                      child:
                          CircularProgressIndicator(color: M4Theme.premiumBlue),
                    )
                  : (_error && _report == null)
                      ? _errorState(textPrimary, muted)
                      : _content(isDark, textPrimary, muted),
            ),
          ],
        ),
      ),
    );
  }

  Widget _header(Color textPrimary, Color muted, bool isDark) {
    return Padding(
      padding: const EdgeInsets.fromLTRB(8, 8, 12, 8),
      child: Row(
        children: [
          IconButton(
            icon: Icon(LucideIcons.arrowLeft, color: textPrimary),
            onPressed: () => context.canPop()
                ? context.pop()
                : context.go('/investor/home'),
          ),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  'Report Details',
                  style: GoogleFonts.montserrat(
                    fontWeight: FontWeight.w900,
                    fontSize: 16,
                    color: textPrimary,
                  ),
                ),
                const SizedBox(height: 2),
                Text(
                  _id.toUpperCase(),
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
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
          InkWell(
            onTap: _download,
            borderRadius: BorderRadius.circular(10),
            child: Container(
              padding: const EdgeInsets.all(8),
              decoration: BoxDecoration(
                color: (isDark ? Colors.white : Colors.black)
                    .withValues(alpha: 0.04),
                borderRadius: BorderRadius.circular(10),
                border: Border.all(
                  color: (isDark ? Colors.white : Colors.black)
                      .withValues(alpha: 0.08),
                ),
              ),
              child: Icon(LucideIcons.download, size: 18, color: muted),
            ),
          ),
        ],
      ),
    );
  }

  Widget _errorState(Color textPrimary, Color muted) {
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(32),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(LucideIcons.fileText, size: 48, color: muted),
            const SizedBox(height: 16),
            Text(
              'Report not found',
              style: GoogleFonts.montserrat(
                fontSize: 15,
                fontWeight: FontWeight.w800,
                color: textPrimary,
              ),
            ),
            const SizedBox(height: 8),
            Text(
              'The requested tax report could not be found or you do not '
              'have access to it.',
              textAlign: TextAlign.center,
              style: GoogleFonts.montserrat(fontSize: 12, color: muted),
            ),
          ],
        ),
      ),
    );
  }

  Widget _content(bool isDark, Color textPrimary, Color muted) {
    const red = Color(0xFFEF4444);

    return RefreshIndicator(
      color: M4Theme.premiumBlue,
      onRefresh: _load,
      child: ListView(
        physics: const AlwaysScrollableScrollPhysics(),
        padding: const EdgeInsets.fromLTRB(24, 12, 24, 32),
        children: [
          _overviewCard(isDark, textPrimary, muted, red),
          const SizedBox(height: 14),
          _badgesRow(),
          const SizedBox(height: 16),
          _statusGrid(isDark, textPrimary, muted),
          const SizedBox(height: 16),
          _descriptionCard(isDark, textPrimary, muted),
          const SizedBox(height: 16),
          _secureNote(isDark, muted),
          const SizedBox(height: 24),
          _openButton(textPrimary, isDark),
          const SizedBox(height: 12),
          _downloadButton(),
        ],
      ),
    );
  }

  Widget _overviewCard(
      bool isDark, Color textPrimary, Color muted, Color red) {
    final card = isDark ? Colors.white.withValues(alpha: 0.03) : Colors.white;
    final border = isDark
        ? Colors.white.withValues(alpha: 0.08)
        : Colors.black.withValues(alpha: 0.06);

    final chips = <String>[
      if (_year.isNotEmpty) _year,
      [
        if (_type.isNotEmpty) _type,
        if (_size.isNotEmpty) _size,
      ].join(' • '),
    ].where((c) => c.isNotEmpty).toList();

    return Container(
      padding: const EdgeInsets.all(18),
      decoration: BoxDecoration(
        color: card,
        borderRadius: BorderRadius.circular(18),
        border: Border.all(color: border),
      ),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Container(
            width: 56,
            height: 56,
            decoration: BoxDecoration(
              color: red.withValues(alpha: 0.10),
              borderRadius: BorderRadius.circular(16),
              border: Border.all(color: red.withValues(alpha: 0.20)),
            ),
            child: Icon(LucideIcons.fileText, size: 28, color: red),
          ),
          const SizedBox(width: 14),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  _name,
                  style: GoogleFonts.montserrat(
                    fontSize: 17,
                    fontWeight: FontWeight.w900,
                    height: 1.25,
                    letterSpacing: -0.2,
                    color: textPrimary,
                  ),
                ),
                if (chips.isNotEmpty) ...[
                  const SizedBox(height: 10),
                  Wrap(
                    spacing: 8,
                    runSpacing: 8,
                    children:
                        chips.map((c) => _chip(c, isDark, muted)).toList(),
                  ),
                ],
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _chip(String label, bool isDark, Color muted) {
    final border = isDark
        ? Colors.white.withValues(alpha: 0.08)
        : Colors.black.withValues(alpha: 0.06);
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
      decoration: BoxDecoration(
        color:
            (isDark ? Colors.white : Colors.black).withValues(alpha: 0.03),
        borderRadius: BorderRadius.circular(7),
        border: Border.all(color: border),
      ),
      child: Text(
        label.toUpperCase(),
        style: GoogleFonts.montserrat(
          fontSize: 10,
          fontWeight: FontWeight.w700,
          letterSpacing: 0.8,
          color: muted,
        ),
      ),
    );
  }

  Widget _badgesRow() {
    const green = Color(0xFF10B981);
    const gold = Color(0xFFFFD700);
    return Wrap(
      spacing: 10,
      runSpacing: 10,
      children: [
        _badge('ENCRYPTED', LucideIcons.lock, gold),
        _badge('VERIFIED DOCUMENT', LucideIcons.badgeCheck, green),
      ],
    );
  }

  Widget _badge(String label, IconData icon, Color color) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
      decoration: BoxDecoration(
        color: color.withValues(alpha: 0.10),
        borderRadius: BorderRadius.circular(20),
        border: Border.all(color: color.withValues(alpha: 0.25)),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(icon, size: 14, color: color),
          const SizedBox(width: 6),
          Text(
            label,
            style: GoogleFonts.montserrat(
              fontSize: 9,
              fontWeight: FontWeight.w700,
              letterSpacing: 1.2,
              color: color,
            ),
          ),
        ],
      ),
    );
  }

  Widget _statusGrid(bool isDark, Color textPrimary, Color muted) {
    const green = Color(0xFF10B981);
    const amber = Color(0xFFF59E0B);
    return Row(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        Expanded(
          child: _infoTile(
            isDark,
            textPrimary,
            muted,
            label: 'GENERATED ON',
            value: _date.isNotEmpty ? _date : '—',
            valueColor: textPrimary,
            icon: LucideIcons.calendar,
            iconColor: muted,
          ),
        ),
        const SizedBox(width: 12),
        Expanded(
          child: _infoTile(
            isDark,
            textPrimary,
            muted,
            label: 'STATUS',
            value: _isReady ? 'Ready' : 'Pending',
            valueColor: _isReady ? green : amber,
            icon: _isReady ? LucideIcons.checkCircle : LucideIcons.info,
            iconColor: _isReady ? green : amber,
          ),
        ),
      ],
    );
  }

  Widget _infoTile(
    bool isDark,
    Color textPrimary,
    Color muted, {
    required String label,
    required String value,
    required Color valueColor,
    required IconData icon,
    required Color iconColor,
  }) {
    final card = isDark ? Colors.white.withValues(alpha: 0.03) : Colors.white;
    final border = isDark
        ? Colors.white.withValues(alpha: 0.08)
        : Colors.black.withValues(alpha: 0.06);
    return Container(
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: card,
        borderRadius: BorderRadius.circular(14),
        border: Border.all(color: border),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            label,
            style: GoogleFonts.montserrat(
              fontSize: 9,
              fontWeight: FontWeight.w700,
              letterSpacing: 1.2,
              color: muted,
            ),
          ),
          const SizedBox(height: 8),
          Row(
            children: [
              Icon(icon, size: 14, color: iconColor),
              const SizedBox(width: 6),
              Flexible(
                child: Text(
                  value,
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                  style: GoogleFonts.montserrat(
                    fontSize: 12,
                    fontWeight: FontWeight.w700,
                    color: valueColor,
                  ),
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _descriptionCard(bool isDark, Color textPrimary, Color muted) {
    final card = isDark ? Colors.white.withValues(alpha: 0.03) : Colors.white;
    final border = isDark
        ? Colors.white.withValues(alpha: 0.08)
        : Colors.black.withValues(alpha: 0.06);

    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: card,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: border),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Icon(LucideIcons.info, size: 15, color: muted),
              const SizedBox(width: 8),
              Text(
                'DESCRIPTION',
                style: GoogleFonts.montserrat(
                  fontSize: 10,
                  fontWeight: FontWeight.w700,
                  letterSpacing: 1.2,
                  color: muted,
                ),
              ),
            ],
          ),
          const SizedBox(height: 10),
          Text(
            _description,
            style: GoogleFonts.montserrat(
              fontSize: 13,
              height: 1.55,
              fontWeight: FontWeight.w400,
              color: textPrimary.withValues(alpha: 0.85),
            ),
          ),
        ],
      ),
    );
  }

  Widget _secureNote(bool isDark, Color muted) {
    const gold = Color(0xFFFFD700);
    return Container(
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: gold.withValues(alpha: 0.06),
        borderRadius: BorderRadius.circular(14),
        border: Border.all(color: gold.withValues(alpha: 0.18)),
      ),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Icon(LucideIcons.shield, size: 16, color: gold),
          const SizedBox(width: 10),
          Expanded(
            child: Text(
              'This document contains sensitive financial information. Please '
              'ensure you are in a secure environment before opening, '
              'downloading or sharing it.',
              style: GoogleFonts.montserrat(
                fontSize: 11,
                height: 1.5,
                fontWeight: FontWeight.w500,
                color: muted,
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _openButton(Color textPrimary, bool isDark) {
    final border = isDark
        ? Colors.white.withValues(alpha: 0.10)
        : Colors.black.withValues(alpha: 0.10);
    return SizedBox(
      width: double.infinity,
      child: OutlinedButton.icon(
        onPressed: _open,
        icon: const Icon(LucideIcons.eye, size: 16),
        style: OutlinedButton.styleFrom(
          foregroundColor: textPrimary,
          side: BorderSide(color: border),
          padding: const EdgeInsets.symmetric(vertical: 16),
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(14),
          ),
        ),
        label: Text(
          'VIEW DOCUMENT',
          style: GoogleFonts.montserrat(
            fontSize: 12,
            fontWeight: FontWeight.w700,
            letterSpacing: 1.2,
          ),
        ),
      ),
    );
  }

  Widget _downloadButton() {
    const gold = Color(0xFFFFD700);
    return SizedBox(
      width: double.infinity,
      child: ElevatedButton.icon(
        onPressed: _download,
        icon: const Icon(LucideIcons.download, size: 16),
        style: ElevatedButton.styleFrom(
          backgroundColor: gold,
          foregroundColor: Colors.black,
          padding: const EdgeInsets.symmetric(vertical: 16),
          elevation: 0,
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(14),
          ),
        ),
        label: Text(
          'DOWNLOAD DOCUMENT',
          style: GoogleFonts.montserrat(
            fontSize: 12,
            fontWeight: FontWeight.w700,
            letterSpacing: 1.2,
          ),
        ),
      ),
    );
  }
}
