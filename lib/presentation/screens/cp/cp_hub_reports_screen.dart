import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:lucide_icons/lucide_icons.dart';
import 'package:m4_mobile/presentation/providers/auth_provider.dart';
import 'package:share_plus/share_plus.dart';
import 'package:url_launcher/url_launcher.dart';

/// Web `/cp/hub/reports` — UI: FY chips + downloadable reports list.
/// Flutter: backed by real API `GET /api/cp/tax-reports?year=YYYY` (database).
class CpHubReportsScreen extends ConsumerStatefulWidget {
  const CpHubReportsScreen({super.key});

  @override
  ConsumerState<CpHubReportsScreen> createState() => _CpHubReportsScreenState();
}

class _CpHubReportsScreenState extends ConsumerState<CpHubReportsScreen> {
  String _year = '2024';
  List<dynamic> _reports = const [];
  bool _loading = true;

  static const Color _gold = Color(0xFFFFD700);
  static const years = ['2024', '2023', '2022'];

  @override
  void initState() {
    super.initState();
    _load();
  }

  Future<void> _load() async {
    setState(() => _loading = true);
    try {
      final res = await ref.read(apiClientProvider).getCpTaxReports(year: _year);
      if (!mounted) return;
      if (res.statusCode == 200 && res.data['status'] == true) {
        final d = res.data['data'];
        if (d is List) {
          _reports = List<dynamic>.from(d);
        } else {
          _reports = const [];
        }
      } else {
        _reports = const [];
      }
    } catch (_) {
      _reports = const [];
    }
    if (mounted) setState(() => _loading = false);
  }

  Future<void> _openUrl(String? url) async {
    if (url == null || url.isEmpty) return;
    final resolved = ref.read(apiClientProvider).resolveUrl(url);
    await launchUrl(Uri.parse(resolved), mode: LaunchMode.externalApplication);
  }

  Future<void> _shareUrl(String? url, String title) async {
    if (url == null || url.isEmpty) return;
    final resolved = ref.read(apiClientProvider).resolveUrl(url);
    await Share.share('$title\n$resolved', subject: title);
  }

  String _stringUrl(dynamic v) {
    if (v == null) return '';
    if (v is String) return v;
    if (v is Map) {
      return v['url']?.toString() ?? v['fileUrl']?.toString() ?? v['src']?.toString() ?? v['path']?.toString() ?? '';
    }
    return v.toString();
  }

  /// Sum of any tax / TDS field across all reports for the summary card.
  num _totalTaxDeducted() {
    num total = 0;
    for (final r in _reports) {
      if (r is! Map) continue;
      final v = r['tax'] ?? r['taxDeducted'] ?? r['tds'] ?? r['amount'] ?? r['totalTax'];
      if (v is num) {
        total += v;
      } else if (v != null) {
        total += num.tryParse(v.toString().replaceAll(RegExp(r'[^0-9.\-]'), '')) ?? 0;
      }
    }
    return total;
  }

  String _formatAed(num value) {
    final s = value.toStringAsFixed(value == value.roundToDouble() ? 0 : 2);
    final parts = s.split('.');
    final intPart = parts[0];
    final buf = StringBuffer();
    for (int i = 0; i < intPart.length; i++) {
      if (i > 0 && (intPart.length - i) % 3 == 0) buf.write(',');
      buf.write(intPart[i]);
    }
    final formatted = parts.length > 1 ? '${buf.toString()}.${parts[1]}' : buf.toString();
    return 'AED $formatted';
  }

  /// Detect document type from filename / explicit field → badge label.
  String _docType(Map<String, dynamic> m, String url) {
    final explicit = (m['type'] ?? m['fileType'] ?? m['ext'] ?? '').toString().trim();
    final src = explicit.isNotEmpty ? explicit : url;
    final lower = src.toLowerCase();
    if (lower.contains('xlsx') || lower.contains('xls')) return 'XLSX';
    if (lower.contains('csv')) return 'CSV';
    if (lower.contains('doc')) return 'DOC';
    if (lower.contains('png') || lower.contains('jpg') || lower.contains('jpeg')) return 'IMG';
    return 'PDF';
  }

  Color _typeColor(String type) {
    switch (type) {
      case 'XLSX':
      case 'CSV':
        return const Color(0xFF34D399); // green — spreadsheets
      case 'DOC':
        return const Color(0xFF818CF8); // indigo — docs
      case 'IMG':
        return const Color(0xFFF59E0B); // amber — images
      default:
        return const Color(0xFF60A5FA); // blue — pdf
    }
  }

  IconData _typeIcon(String type) {
    switch (type) {
      case 'XLSX':
      case 'CSV':
        return LucideIcons.fileSpreadsheet;
      case 'IMG':
        return LucideIcons.fileImage;
      default:
        return LucideIcons.fileText;
    }
  }

  @override
  Widget build(BuildContext context) {
    final scheme = Theme.of(context).colorScheme;
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final accent = isDark ? scheme.primary : Colors.black;
    final textPrimary = isDark ? Colors.white : Colors.black;
    final muted = (isDark ? Colors.white : Colors.black).withValues(alpha: 0.5);
    final card = isDark ? Colors.white.withValues(alpha: 0.03) : Colors.white;
    final border = isDark ? Colors.white.withValues(alpha: 0.08) : Colors.black.withValues(alpha: 0.06);

    return Scaffold(
      backgroundColor: scheme.surface,
      appBar: AppBar(
        backgroundColor: scheme.surface,
        elevation: 0,
        leading: IconButton(icon: const Icon(LucideIcons.arrowLeft), onPressed: () => context.pop()),
        title: Text('Reports', style: GoogleFonts.montserrat(fontWeight: FontWeight.w900)),
      ),
      body: Column(
        children: [
          // ─── Year filter (glass-morphism chips) ─────────────────────────────
          Container(
            width: double.infinity,
            padding: const EdgeInsets.fromLTRB(16, 10, 16, 12),
            decoration: BoxDecoration(
              border: Border(bottom: BorderSide(color: border)),
            ),
            child: SingleChildScrollView(
              scrollDirection: Axis.horizontal,
              child: Row(
                children: [
                  for (final y in years) _yearChip(y, accent, textPrimary, muted, border, isDark),
                ],
              ),
            ),
          ),
          Expanded(
            child: _loading
                ? _buildLoading(card, border, accent)
                : RefreshIndicator(
                    onRefresh: _load,
                    color: accent,
                    child: _reports.isEmpty
                        ? _buildEmptyState(textPrimary, muted)
                        : ListView(
                            padding: const EdgeInsets.fromLTRB(16, 14, 16, 24),
                            children: [
                              _buildSummaryCard(card, border, textPrimary, muted, accent, isDark),
                              const SizedBox(height: 16),
                              for (int i = 0; i < _reports.length; i++)
                                Padding(
                                  padding: const EdgeInsets.only(bottom: 10),
                                  child: _buildReportItem(_reports[i], card, border, textPrimary, muted),
                                ),
                            ],
                          ),
                  ),
          ),
        ],
      ),
    );
  }

  // ─── Year chip ───────────────────────────────────────────────────────────
  Widget _yearChip(String y, Color accent, Color textPrimary, Color muted, Color border, bool isDark) {
    final selected = _year == y;
    return Padding(
      padding: const EdgeInsets.only(right: 10),
      child: GestureDetector(
        onTap: selected
            ? null
            : () {
                setState(() => _year = y);
                _load();
              },
        child: AnimatedContainer(
          duration: const Duration(milliseconds: 220),
          curve: Curves.easeOut,
          padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 11),
          decoration: BoxDecoration(
            color: selected ? accent : Colors.transparent,
            borderRadius: BorderRadius.circular(14),
            border: Border.all(color: selected ? accent : border),
            boxShadow: selected
                ? [
                    BoxShadow(
                      color: _gold.withValues(alpha: 0.30),
                      blurRadius: 16,
                      spreadRadius: 0,
                      offset: const Offset(0, 4),
                    ),
                  ]
                : null,
          ),
          child: Text(
            'FY $y',
            style: GoogleFonts.montserrat(
              fontSize: 10,
              fontWeight: FontWeight.w900,
              letterSpacing: 1.6,
              color: selected ? (isDark ? Colors.black : Colors.white) : muted,
            ),
          ),
        ),
      ),
    );
  }

  // ─── Summary card ──────────────────────────────────────────────────────────
  Widget _buildSummaryCard(Color card, Color border, Color textPrimary, Color muted, Color accent, bool isDark) {
    final total = _totalTaxDeducted();
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: card,
        borderRadius: BorderRadius.circular(28),
        border: Border.all(color: border),
        gradient: LinearGradient(
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
          colors: [
            _gold.withValues(alpha: isDark ? 0.07 : 0.05),
            Colors.transparent,
          ],
        ),
      ),
      child: Stack(
        children: [
          // Faint Award glyph (10% opacity) top-right.
          Positioned(
            top: -4,
            right: -4,
            child: Icon(LucideIcons.award, size: 64, color: _gold.withValues(alpha: 0.10)),
          ),
          Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                'TOTAL TAX DEDUCTED',
                style: GoogleFonts.montserrat(
                  fontSize: 9,
                  fontWeight: FontWeight.w800,
                  letterSpacing: 1.6,
                  color: muted,
                ),
              ),
              const SizedBox(height: 10),
              Text(
                _formatAed(total),
                style: GoogleFonts.montserrat(
                  fontSize: 26,
                  fontWeight: FontWeight.w900,
                  letterSpacing: -0.5,
                  color: textPrimary,
                ),
              ),
              const SizedBox(height: 4),
              Text(
                'FY $_year • ${_reports.length} ${_reports.length == 1 ? 'DOCUMENT' : 'DOCUMENTS'}',
                style: GoogleFonts.montserrat(
                  fontSize: 9,
                  fontWeight: FontWeight.w700,
                  letterSpacing: 1.2,
                  color: muted,
                ),
              ),
              const SizedBox(height: 16),
              SizedBox(
                height: 32,
                child: OutlinedButton.icon(
                  onPressed: _onDownloadSummary,
                  icon: const Icon(LucideIcons.download, size: 14),
                  label: Text(
                    'DOWNLOAD SUMMARY',
                    style: GoogleFonts.montserrat(fontSize: 9, fontWeight: FontWeight.w900, letterSpacing: 1.4),
                  ),
                  style: OutlinedButton.styleFrom(
                    foregroundColor: textPrimary,
                    side: BorderSide(color: border),
                    padding: const EdgeInsets.symmetric(horizontal: 14),
                    shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
                  ),
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }

  void _onDownloadSummary() {
    // Prefer the first report with a URL as the "summary" download target.
    String url = '';
    for (final r in _reports) {
      if (r is! Map) continue;
      url = _stringUrl(r['url'] ?? r['file'] ?? r['fileUrl'] ?? r['path']);
      if (url.isNotEmpty) break;
    }
    if (url.isNotEmpty) {
      _openUrl(url);
    } else {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Summary will be available soon', style: GoogleFonts.montserrat(fontSize: 12))),
      );
    }
  }

  // ─── Report item ───────────────────────────────────────────────────────────
  Widget _buildReportItem(dynamic r, Color card, Color border, Color textPrimary, Color muted) {
    if (r is! Map) return const SizedBox.shrink();
    final m = Map<String, dynamic>.from(r);
    final title = (m['title'] ?? m['name'] ?? m['label'] ?? 'Report').toString();
    final date = (m['date'] ?? m['createdAt'] ?? '').toString();
    final size = (m['size'] ?? m['fileSize'] ?? '').toString();
    final url = _stringUrl(m['url'] ?? m['file'] ?? m['fileUrl'] ?? m['path']);
    final type = _docType(m, url);
    final typeColor = _typeColor(type);

    return _TapScale(
      onTap: url.isEmpty ? null : () => _openUrl(url),
      child: Container(
        padding: const EdgeInsets.all(14),
        decoration: BoxDecoration(
          color: card,
          borderRadius: BorderRadius.circular(16),
          border: Border.all(color: border),
        ),
        child: Row(
          children: [
            // Glass icon container with doc-type badge.
            Stack(
              clipBehavior: Clip.none,
              children: [
                Container(
                  width: 46,
                  height: 46,
                  decoration: BoxDecoration(
                    borderRadius: BorderRadius.circular(12),
                    color: typeColor.withValues(alpha: 0.12),
                    border: Border.all(color: typeColor.withValues(alpha: 0.25)),
                  ),
                  child: Icon(_typeIcon(type), color: typeColor, size: 20),
                ),
                Positioned(
                  top: -6,
                  right: -6,
                  child: Container(
                    padding: const EdgeInsets.symmetric(horizontal: 5, vertical: 2),
                    decoration: BoxDecoration(
                      color: typeColor,
                      borderRadius: BorderRadius.circular(6),
                    ),
                    child: Text(
                      type,
                      style: GoogleFonts.montserrat(
                        fontSize: 7,
                        fontWeight: FontWeight.w900,
                        letterSpacing: 0.6,
                        color: Colors.white,
                      ),
                    ),
                  ),
                ),
              ],
            ),
            const SizedBox(width: 14),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    title,
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                    style: GoogleFonts.montserrat(fontSize: 12, fontWeight: FontWeight.w800, color: textPrimary),
                  ),
                  const SizedBox(height: 4),
                  Text(
                    [date, size].where((x) => x.trim().isNotEmpty).join(' • ').toUpperCase(),
                    style: GoogleFonts.montserrat(
                      fontSize: 9,
                      fontWeight: FontWeight.w700,
                      letterSpacing: 1.2,
                      color: muted,
                    ),
                  ),
                ],
              ),
            ),
            const SizedBox(width: 6),
            // Action group: download, share, more.
            IconButton(
              visualDensity: VisualDensity.compact,
              onPressed: url.isEmpty ? null : () => _openUrl(url),
              icon: Icon(LucideIcons.download, size: 18, color: textPrimary),
              tooltip: 'Download',
            ),
            IconButton(
              visualDensity: VisualDensity.compact,
              onPressed: url.isEmpty ? null : () => _shareUrl(url, title),
              icon: Icon(LucideIcons.share2, size: 18, color: muted),
              tooltip: 'Share',
            ),
            IconButton(
              visualDensity: VisualDensity.compact,
              onPressed: url.isEmpty ? null : () => _showMoreActions(title, url),
              icon: Icon(LucideIcons.moreVertical, size: 18, color: muted),
              tooltip: 'More',
            ),
          ],
        ),
      ),
    );
  }

  void _showMoreActions(String title, String url) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final textPrimary = isDark ? Colors.white : Colors.black;
    final muted = (isDark ? Colors.white : Colors.black).withValues(alpha: 0.5);
    showModalBottomSheet(
      context: context,
      backgroundColor: isDark ? const Color(0xFF111111) : Colors.white,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(24)),
      ),
      builder: (ctx) => SafeArea(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            const SizedBox(height: 12),
            Container(
              width: 40,
              height: 4,
              decoration: BoxDecoration(color: muted.withValues(alpha: 0.4), borderRadius: BorderRadius.circular(2)),
            ),
            const SizedBox(height: 8),
            ListTile(
              leading: Icon(LucideIcons.externalLink, color: textPrimary, size: 20),
              title: Text('Open / Print PDF',
                  style: GoogleFonts.montserrat(fontSize: 13, fontWeight: FontWeight.w700, color: textPrimary)),
              onTap: () {
                Navigator.pop(ctx);
                _openUrl(url);
              },
            ),
            ListTile(
              leading: Icon(LucideIcons.share2, color: textPrimary, size: 20),
              title: Text('Share document',
                  style: GoogleFonts.montserrat(fontSize: 13, fontWeight: FontWeight.w700, color: textPrimary)),
              onTap: () {
                Navigator.pop(ctx);
                _shareUrl(url, title);
              },
            ),
            const SizedBox(height: 8),
          ],
        ),
      ),
    );
  }

  // ─── Empty state ───────────────────────────────────────────────────────────
  Widget _buildEmptyState(Color textPrimary, Color muted) {
    return ListView(
      // ListView so RefreshIndicator still works on an empty list.
      physics: const AlwaysScrollableScrollPhysics(),
      children: [
        SizedBox(height: MediaQuery.of(context).size.height * 0.22),
        Icon(LucideIcons.fileX, size: 48, color: muted),
        const SizedBox(height: 16),
        Center(
          child: Text(
            'No documents available for FY $_year',
            textAlign: TextAlign.center,
            style: GoogleFonts.montserrat(fontSize: 13, fontWeight: FontWeight.w800, color: textPrimary),
          ),
        ),
        const SizedBox(height: 6),
        Center(
          child: Text(
            'Check back soon or select another year',
            textAlign: TextAlign.center,
            style: GoogleFonts.montserrat(fontSize: 11, fontWeight: FontWeight.w600, color: muted),
          ),
        ),
      ],
    );
  }

  // ─── Loading state (branded + skeleton cards) ────────────────────────────────
  Widget _buildLoading(Color card, Color border, Color accent) {
    return ListView(
      padding: const EdgeInsets.fromLTRB(16, 16, 16, 24),
      physics: const NeverScrollableScrollPhysics(),
      children: [
        Center(
          child: Padding(
            padding: const EdgeInsets.symmetric(vertical: 8),
            child: CircularProgressIndicator(color: accent, strokeWidth: 2.4),
          ),
        ),
        const SizedBox(height: 16),
        for (int i = 0; i < 4; i++)
          Padding(
            padding: const EdgeInsets.only(bottom: 10),
            child: Container(
              height: 74,
              decoration: BoxDecoration(
                color: card,
                borderRadius: BorderRadius.circular(16),
                border: Border.all(color: border),
              ),
            ),
          ),
      ],
    );
  }
}

/// Subtle press-down scale (0.98) used on tappable report cards.
class _TapScale extends StatefulWidget {
  const _TapScale({required this.child, this.onTap});

  final Widget child;
  final VoidCallback? onTap;

  @override
  State<_TapScale> createState() => _TapScaleState();
}

class _TapScaleState extends State<_TapScale> {
  bool _down = false;

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: widget.onTap,
      onTapDown: widget.onTap == null ? null : (_) => setState(() => _down = true),
      onTapUp: widget.onTap == null ? null : (_) => setState(() => _down = false),
      onTapCancel: widget.onTap == null ? null : () => setState(() => _down = false),
      child: AnimatedScale(
        scale: _down ? 0.98 : 1.0,
        duration: const Duration(milliseconds: 120),
        curve: Curves.easeOut,
        child: widget.child,
      ),
    );
  }
}
