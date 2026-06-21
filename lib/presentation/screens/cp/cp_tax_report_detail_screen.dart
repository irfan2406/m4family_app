import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:lucide_icons/lucide_icons.dart';
import 'package:m4_mobile/core/theme/app_theme.dart';
import 'package:m4_mobile/presentation/providers/auth_provider.dart';

/// Web `/cp/tax-reports/[id]` — single fiscal compliance document detail.
/// Backed by `GET /api/cp/tax-reports`; the matching row is located by `id`
/// (no dedicated per-id endpoint), mirroring the web detail page which renders
/// metadata (type, size, date, year, status), description, a secure-document
/// warning, and a download action.
class CpTaxReportDetailScreen extends ConsumerStatefulWidget {
  final String reportId;
  final Map<String, dynamic>? initialData;

  const CpTaxReportDetailScreen({
    super.key,
    required this.reportId,
    this.initialData,
  });

  @override
  ConsumerState<CpTaxReportDetailScreen> createState() =>
      _CpTaxReportDetailScreenState();
}

class _CpTaxReportDetailScreenState
    extends ConsumerState<CpTaxReportDetailScreen> {
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
      final api = ref.read(apiClientProvider);
      final res = await api.getCpTaxReports();
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

  void _download() {
    if (!mounted) return;
    final name = _report?['name']?.toString() ?? 'document';
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(
          'Downloading $name...',
          style: GoogleFonts.montserrat(fontSize: 12),
        ),
      ),
    );
  }

  String get _name => _report?['name']?.toString() ?? 'Statement';
  String get _date => _report?['date']?.toString() ?? '';
  String get _size => _report?['size']?.toString() ?? '';
  String get _year => _report?['year']?.toString() ?? '';
  String get _type => _report?['type']?.toString() ?? 'TDS Statement';
  String get _status => _report?['status']?.toString() ?? 'Available';
  String get _description =>
      _report?['description']?.toString() ??
      'This is an official fiscal compliance document containing your tax '
          'deducted at source (TDS) details for the selected period. Keep this '
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
            onPressed: () =>
                context.canPop() ? context.pop() : context.go('/cp/dashboard'),
          ),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  'Tax Report',
                  style: GoogleFonts.montserrat(
                    fontWeight: FontWeight.w900,
                    fontSize: 16,
                    color: textPrimary,
                  ),
                ),
                const SizedBox(height: 2),
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
          InkWell(
            onTap: _download,
            borderRadius: BorderRadius.circular(10),
            child: Container(
              padding: const EdgeInsets.all(8),
              decoration: BoxDecoration(
                color:
                    (isDark ? Colors.white : Colors.black).withValues(alpha: 0.04),
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
            Icon(LucideIcons.info, size: 48, color: muted),
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
              'This tax report could not be found or you do not have access.',
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
    const green = Color(0xFF10B981);

    return RefreshIndicator(
      color: M4Theme.premiumBlue,
      onRefresh: _load,
      child: ListView(
        physics: const AlwaysScrollableScrollPhysics(),
        padding: const EdgeInsets.fromLTRB(24, 12, 24, 32),
        children: [
          // Hero icon + title + verification badge.
          Column(
            children: [
              const SizedBox(height: 12),
              Container(
                width: 72,
                height: 72,
                decoration: BoxDecoration(
                  color: red.withValues(alpha: 0.10),
                  borderRadius: BorderRadius.circular(22),
                  border: Border.all(color: red.withValues(alpha: 0.20)),
                ),
                child: const Icon(LucideIcons.fileText, size: 34, color: red),
              ),
              const SizedBox(height: 16),
              Text(
                _name,
                textAlign: TextAlign.center,
                style: GoogleFonts.montserrat(
                  fontSize: 20,
                  fontWeight: FontWeight.w900,
                  letterSpacing: -0.3,
                  color: textPrimary,
                ),
              ),
              const SizedBox(height: 10),
              _verificationBadge(green),
              const SizedBox(height: 24),
            ],
          ),
          _metaCard(isDark, textPrimary, muted),
          const SizedBox(height: 16),
          _descriptionCard(isDark, textPrimary, muted),
          const SizedBox(height: 16),
          _secureWarning(isDark, textPrimary, muted),
          const SizedBox(height: 24),
          _downloadButton(),
        ],
      ),
    );
  }

  Widget _verificationBadge(Color green) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
      decoration: BoxDecoration(
        color: green.withValues(alpha: 0.10),
        borderRadius: BorderRadius.circular(20),
        border: Border.all(color: green.withValues(alpha: 0.25)),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(LucideIcons.badgeCheck, size: 14, color: green),
          const SizedBox(width: 6),
          Text(
            'VERIFIED DOCUMENT',
            style: GoogleFonts.montserrat(
              fontSize: 9,
              fontWeight: FontWeight.w700,
              letterSpacing: 1.2,
              color: green,
            ),
          ),
        ],
      ),
    );
  }

  Widget _metaCard(bool isDark, Color textPrimary, Color muted) {
    final card = isDark ? Colors.white.withValues(alpha: 0.03) : Colors.white;
    final border = isDark
        ? Colors.white.withValues(alpha: 0.08)
        : Colors.black.withValues(alpha: 0.06);
    final divider = (isDark ? Colors.white : Colors.black).withValues(alpha: 0.06);

    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: card,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: border),
      ),
      child: Column(
        children: [
          _metaRow('TYPE', _type, textPrimary, muted, icon: LucideIcons.fileText),
          if (_size.isNotEmpty) ...[
            _hr(divider),
            _metaRow('SIZE', _size.toUpperCase(), textPrimary, muted,
                icon: LucideIcons.hardDrive),
          ],
          if (_date.isNotEmpty) ...[
            _hr(divider),
            _metaRow('DATE', _date.toUpperCase(), textPrimary, muted,
                icon: LucideIcons.calendar),
          ],
          if (_year.isNotEmpty) ...[
            _hr(divider),
            _metaRow('YEAR', _year.toUpperCase(), textPrimary, muted,
                icon: LucideIcons.clock),
          ],
          _hr(divider),
          _metaRow('STATUS', _status.toUpperCase(), textPrimary, muted,
              icon: LucideIcons.checkCircle),
        ],
      ),
    );
  }

  Widget _metaRow(
    String label,
    String value,
    Color textPrimary,
    Color muted, {
    IconData? icon,
  }) {
    return Row(
      mainAxisAlignment: MainAxisAlignment.spaceBetween,
      crossAxisAlignment: CrossAxisAlignment.center,
      children: [
        Text(
          label,
          style: GoogleFonts.montserrat(
            fontSize: 10,
            fontWeight: FontWeight.w700,
            letterSpacing: 1.2,
            color: muted,
          ),
        ),
        Flexible(
          child: Row(
            mainAxisAlignment: MainAxisAlignment.end,
            mainAxisSize: MainAxisSize.min,
            children: [
              if (icon != null) ...[
                Icon(icon, size: 13, color: muted),
                const SizedBox(width: 6),
              ],
              Flexible(
                child: Text(
                  value,
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                  textAlign: TextAlign.right,
                  style: GoogleFonts.montserrat(
                    fontSize: 12,
                    fontWeight: FontWeight.w600,
                    color: textPrimary,
                  ),
                ),
              ),
            ],
          ),
        ),
      ],
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
          Text(
            'DESCRIPTION',
            style: GoogleFonts.montserrat(
              fontSize: 10,
              fontWeight: FontWeight.w700,
              letterSpacing: 1.2,
              color: muted,
            ),
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

  Widget _secureWarning(bool isDark, Color textPrimary, Color muted) {
    const gold = Color(0xFFFFD700);
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: gold.withValues(alpha: 0.08),
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: gold.withValues(alpha: 0.25)),
      ),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Icon(LucideIcons.shieldAlert, size: 18, color: gold),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  'SECURE DOCUMENT',
                  style: GoogleFonts.montserrat(
                    fontSize: 10,
                    fontWeight: FontWeight.w700,
                    letterSpacing: 1.2,
                    color: textPrimary,
                  ),
                ),
                const SizedBox(height: 6),
                Text(
                  'This document contains confidential financial information. '
                  'Do not share it with unauthorised parties.',
                  style: GoogleFonts.montserrat(
                    fontSize: 12,
                    height: 1.5,
                    fontWeight: FontWeight.w400,
                    color: muted,
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _downloadButton() {
    return SizedBox(
      width: double.infinity,
      child: ElevatedButton.icon(
        onPressed: _download,
        icon: const Icon(LucideIcons.download, size: 16),
        style: ElevatedButton.styleFrom(
          backgroundColor: M4Theme.premiumBlue,
          foregroundColor: Colors.white,
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

  Widget _hr(Color color) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 14),
      child: Container(height: 1, color: color),
    );
  }
}
