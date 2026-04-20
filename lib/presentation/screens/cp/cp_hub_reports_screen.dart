import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:lucide_icons/lucide_icons.dart';
import 'package:m4_mobile/presentation/providers/auth_provider.dart';
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
        if (d is List) _reports = List<dynamic>.from(d);
      }
    } catch (_) {}
    if (mounted) setState(() => _loading = false);
  }

  Future<void> _openUrl(String? url) async {
    if (url == null || url.isEmpty) return;
    final resolved = ref.read(apiClientProvider).resolveUrl(url);
    await launchUrl(Uri.parse(resolved), mode: LaunchMode.externalApplication);
  }

  String _stringUrl(dynamic v) {
    if (v == null) return '';
    if (v is String) return v;
    if (v is Map) {
      return v['url']?.toString() ?? v['fileUrl']?.toString() ?? v['src']?.toString() ?? v['path']?.toString() ?? '';
    }
    return v.toString();
  }

  @override
  Widget build(BuildContext context) {
    final scheme = Theme.of(context).colorScheme;
    final isLight = scheme.brightness == Brightness.light;
    final accent = isLight ? Colors.black : scheme.primary;
    const years = ['2024', '2023', '2022'];
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
          // Year filter (web chips)
          Container(
            width: double.infinity,
            padding: const EdgeInsets.fromLTRB(16, 10, 16, 12),
            decoration: BoxDecoration(
              border: Border(bottom: BorderSide(color: scheme.outlineVariant.withValues(alpha: 0.35))),
            ),
            child: SingleChildScrollView(
              scrollDirection: Axis.horizontal,
              child: Row(
                children: [
                  for (final y in years)
                    Padding(
                      padding: const EdgeInsets.only(right: 10),
                      child: OutlinedButton(
                        onPressed: _year == y
                            ? null
                            : () {
                                setState(() => _year = y);
                                _load();
                              },
                        style: OutlinedButton.styleFrom(
                          backgroundColor: _year == y ? accent : Colors.transparent,
                          foregroundColor: _year == y ? Colors.white : scheme.onSurface.withValues(alpha: 0.75),
                          side: BorderSide(color: _year == y ? accent : scheme.outlineVariant.withValues(alpha: 0.5)),
                          padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
                          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                        ),
                        child: Text(
                          'FY $y',
                          style: GoogleFonts.montserrat(fontSize: 10, fontWeight: FontWeight.w900, letterSpacing: 1.6),
                        ),
                      ),
                    ),
                ],
              ),
            ),
          ),
          Expanded(
            child: _loading
                ? Center(child: CircularProgressIndicator(color: accent))
                : _reports.isEmpty
                    ? Center(child: Text('No reports yet', style: GoogleFonts.montserrat(color: scheme.onSurfaceVariant)))
                    : ListView.separated(
                        padding: const EdgeInsets.fromLTRB(16, 14, 16, 20),
                        itemCount: _reports.length,
                        separatorBuilder: (_, __) => const SizedBox(height: 10),
                        itemBuilder: (_, i) {
                          final r = _reports[i];
                          if (r is! Map) return const SizedBox.shrink();
                          final m = Map<String, dynamic>.from(r);
                          final title = (m['title'] ?? m['name'] ?? m['label'] ?? 'Report').toString();
                          final date = (m['date'] ?? m['createdAt'] ?? '').toString();
                          final size = (m['size'] ?? m['fileSize'] ?? '').toString();
                          final url = _stringUrl(m['url'] ?? m['file'] ?? m['fileUrl'] ?? m['path']);

                          return Material(
                            color: scheme.surfaceContainerHighest.withValues(alpha: 0.18),
                            borderRadius: BorderRadius.circular(16),
                            child: InkWell(
                              borderRadius: BorderRadius.circular(16),
                              onTap: url.isEmpty ? null : () => _openUrl(url),
                              child: Container(
                                padding: const EdgeInsets.all(14),
                                decoration: BoxDecoration(
                                  borderRadius: BorderRadius.circular(16),
                                  border: Border.all(color: scheme.outlineVariant.withValues(alpha: 0.35)),
                                ),
                                child: Row(
                                  children: [
                                    Container(
                                      width: 44,
                                      height: 44,
                                      decoration: BoxDecoration(
                                        borderRadius: BorderRadius.circular(12),
                                        color: const Color(0x1A60A5FA),
                                      ),
                                      child: const Icon(LucideIcons.fileText, color: Color(0xFF60A5FA), size: 20),
                                    ),
                                    const SizedBox(width: 12),
                                    Expanded(
                                      child: Column(
                                        crossAxisAlignment: CrossAxisAlignment.start,
                                        children: [
                                          Text(title, style: GoogleFonts.montserrat(fontSize: 12, fontWeight: FontWeight.w800)),
                                          const SizedBox(height: 4),
                                          Text(
                                            [date, size].where((x) => x.trim().isNotEmpty).join(' • ').toUpperCase(),
                                            style: GoogleFonts.montserrat(fontSize: 9, fontWeight: FontWeight.w700, letterSpacing: 1.2, color: scheme.onSurface.withValues(alpha: 0.55)),
                                          ),
                                        ],
                                      ),
                                    ),
                                    const SizedBox(width: 10),
                                    IconButton(
                                      onPressed: url.isEmpty ? null : () => _openUrl(url),
                                      icon: const Icon(LucideIcons.download, size: 18),
                                    ),
                                  ],
                                ),
                              ),
                            ),
                          );
                        },
                      ),
          ),
        ],
      ),
    );
  }
}
