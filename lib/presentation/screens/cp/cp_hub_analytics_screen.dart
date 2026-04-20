import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:lucide_icons/lucide_icons.dart';
import 'package:m4_mobile/presentation/providers/auth_provider.dart';

/// Web `/cp/hub/analytics` — `GET /api/cp/performance`.
class CpHubAnalyticsScreen extends ConsumerStatefulWidget {
  const CpHubAnalyticsScreen({super.key});

  @override
  ConsumerState<CpHubAnalyticsScreen> createState() => _CpHubAnalyticsScreenState();
}

class _CpHubAnalyticsScreenState extends ConsumerState<CpHubAnalyticsScreen> {
  Map<String, dynamic>? _data;
  List<dynamic> _months = const [];
  bool _loading = true;
  String _range = '1Y';

  @override
  void initState() {
    super.initState();
    _load();
  }

  Future<void> _load() async {
    try {
      final res = await ref.read(apiClientProvider).getCpPerformance();
      if (!mounted) return;
      if (res.statusCode == 200 && res.data['status'] == true) {
        final d = res.data['data'];
        if (d is Map) {
          _data = Map<String, dynamic>.from(d);
          if (d['monthlyGraph'] is List) _months = List<dynamic>.from(d['monthlyGraph'] as List);
        }
      }
    } catch (_) {}
    if (mounted) setState(() => _loading = false);
  }

  double _asDouble(dynamic v) => v is num ? v.toDouble() : double.tryParse(v?.toString() ?? '') ?? 0;

  String _fmtCompact(num n) {
    if (n >= 10000000) return '${(n / 10000000).toStringAsFixed(1)}Cr';
    if (n >= 100000) return '${(n / 100000).toStringAsFixed(1)}L';
    if (n >= 1000) return '${(n / 1000).toStringAsFixed(1)}K';
    return n.toStringAsFixed(0);
  }

  String _monthShort(String raw) {
    final s = raw.trim();
    if (s.length >= 3) return s.substring(0, 3).toUpperCase();
    return s.toUpperCase();
  }

  @override
  Widget build(BuildContext context) {
    final scheme = Theme.of(context).colorScheme;
    final isLight = scheme.brightness == Brightness.light;
    final accent = isLight ? Colors.black : scheme.primary;
    const purple = Color(0xFFA855F7); // web hue

    final totalLeads = _asDouble(_data?['totalLeads']);
    final totalConv = _asDouble(_data?['totalConversions']);
    final conversionRateStr = (_data?['conversionRate'] ?? '0%').toString();
    final totalCommission = _asDouble(_data?['totalCommission']);

    // Map backend fields into the web-style stat cards.
    final stat1 = conversionRateStr; // Total ROI in web UI
    final stat2 = '₹${_fmtCompact(totalCommission)}'; // Net Profit in web UI
    final stat3 = totalLeads <= 0 ? '0%' : '${((totalConv / totalLeads) * 100).clamp(0, 100).toStringAsFixed(1)}%'; // Avg Yield

    return Scaffold(
      backgroundColor: scheme.surface,
      appBar: AppBar(
        backgroundColor: scheme.surface,
        elevation: 0,
        leading: IconButton(icon: const Icon(LucideIcons.arrowLeft), onPressed: () => context.pop()),
        title: Text('Analytics', style: GoogleFonts.montserrat(fontWeight: FontWeight.w900)),
      ),
      body: _loading
          ? Center(child: CircularProgressIndicator(color: accent))
          : ListView(
              padding: const EdgeInsets.fromLTRB(20, 10, 20, 24),
              children: [
                Text('PORTFOLIO PERFORMANCE', style: GoogleFonts.montserrat(fontSize: 9, fontWeight: FontWeight.w900, letterSpacing: 2.4, color: scheme.onSurface.withValues(alpha: 0.55))),
                const SizedBox(height: 14),
                _rangeTabs(scheme, selected: _range, onPick: (v) => setState(() => _range = v)),
                const SizedBox(height: 16),
                Row(
                  children: [
                    Expanded(child: _statCard(scheme, label: 'TOTAL ROI', value: stat1, change: '', trendUp: true, accent: purple)),
                    const SizedBox(width: 10),
                    Expanded(child: _statCard(scheme, label: 'NET PROFIT', value: stat2, change: '', trendUp: true, accent: purple)),
                    const SizedBox(width: 10),
                    Expanded(child: _statCard(scheme, label: 'AVG. YIELD', value: stat3, change: '', trendUp: false, accent: purple)),
                  ],
                ),
                const SizedBox(height: 16),
                _growthCard(scheme, months: _months, accent: purple),
                const SizedBox(height: 16),
                Row(
                  children: [
                    Icon(LucideIcons.pieChart, size: 16, color: purple),
                    const SizedBox(width: 8),
                    Text('Asset Allocation', style: GoogleFonts.montserrat(fontSize: 12, fontWeight: FontWeight.w800)),
                  ],
                ),
                const SizedBox(height: 12),
                _allocRow(scheme, label: 'Commercial Real Estate', value: 65, color: purple),
                _allocRow(scheme, label: 'Residential Luxury', value: 25, color: const Color(0xFF60A5FA)),
                _allocRow(scheme, label: 'REITs & Bonds', value: 10, color: purple),
                const SizedBox(height: 16),
                // Keep the raw backend numbers visible (small) for correctness/debug parity.
                if (_data != null)
                  Container(
                    padding: const EdgeInsets.all(14),
                    decoration: BoxDecoration(
                      borderRadius: BorderRadius.circular(16),
                      border: Border.all(color: scheme.outlineVariant.withValues(alpha: 0.4)),
                      color: scheme.surfaceContainerHighest.withValues(alpha: 0.14),
                    ),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text('BACKEND (CP PERFORMANCE)', style: GoogleFonts.montserrat(fontSize: 9, fontWeight: FontWeight.w900, letterSpacing: 2, color: scheme.onSurface.withValues(alpha: 0.55))),
                        const SizedBox(height: 10),
                        _kv('Total leads', '${_data!['totalLeads'] ?? 0}', scheme),
                        _kv('Bookings / conversions', '${_data!['totalConversions'] ?? 0}', scheme),
                        _kv('Conversion rate', '${_data!['conversionRate'] ?? '0%'}', scheme),
                        _kv('Total commission', '${_data!['totalCommission'] ?? 0}', scheme),
                        _kv('Paid commission', '${_data!['paidCommission'] ?? 0}', scheme),
                      ],
                    ),
                  ),
              ],
            ),
    );
  }

  Widget _rangeTabs(ColorScheme scheme, {required String selected, required ValueChanged<String> onPick}) {
    const ranges = ['1M', '3M', '6M', '1Y', 'ALL'];
    final isLight = scheme.brightness == Brightness.light;
    return Container(
      padding: const EdgeInsets.all(6),
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(14),
        color: scheme.surfaceContainerHighest.withValues(alpha: isLight ? 0.16 : 0.22),
        border: Border.all(color: scheme.outlineVariant.withValues(alpha: 0.4)),
      ),
      child: Row(
        children: [
          for (final r in ranges)
            Expanded(
              child: GestureDetector(
                onTap: () => onPick(r),
                child: AnimatedContainer(
                  duration: const Duration(milliseconds: 160),
                  padding: const EdgeInsets.symmetric(vertical: 10),
                  decoration: BoxDecoration(
                    borderRadius: BorderRadius.circular(10),
                    color: selected == r ? const Color(0xFFA855F7) : Colors.transparent,
                  ),
                  child: Text(
                    r,
                    textAlign: TextAlign.center,
                    style: GoogleFonts.montserrat(
                      fontSize: 10,
                      fontWeight: FontWeight.w900,
                      letterSpacing: 1.4,
                      color: selected == r ? Colors.white : scheme.onSurface.withValues(alpha: 0.65),
                    ),
                  ),
                ),
              ),
            ),
        ],
      ),
    );
  }

  Widget _statCard(
    ColorScheme scheme, {
    required String label,
    required String value,
    required String change,
    required bool trendUp,
    required Color accent,
  }) {
    return Container(
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(14),
        border: Border.all(color: scheme.outlineVariant.withValues(alpha: 0.4)),
        color: scheme.onSurface.withValues(alpha: 0.03),
      ),
      child: Column(
        children: [
          Text(label, textAlign: TextAlign.center, style: GoogleFonts.montserrat(fontSize: 9, fontWeight: FontWeight.w900, letterSpacing: 1.1, color: scheme.onSurface.withValues(alpha: 0.55))),
          const SizedBox(height: 8),
          Text(value, style: GoogleFonts.montserrat(fontSize: 12, fontWeight: FontWeight.w900)),
          const SizedBox(height: 6),
          if (change.isNotEmpty)
            Row(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Icon(trendUp ? LucideIcons.trendingUp : LucideIcons.activity, size: 12, color: trendUp ? const Color(0xFF34D399) : const Color(0xFFF87171)),
                const SizedBox(width: 4),
                Text(change, style: GoogleFonts.montserrat(fontSize: 9, fontWeight: FontWeight.w900, color: trendUp ? const Color(0xFF34D399) : const Color(0xFFF87171))),
              ],
            ),
        ],
      ),
    );
  }

  Widget _growthCard(ColorScheme scheme, {required List<dynamic> months, required Color accent}) {
    final items = months.whereType<Map>().map((m) => Map<String, dynamic>.from(m)).toList();
    // Use last 8 points similar to web bars.
    final last = items.length > 8 ? items.sublist(items.length - 8) : items;
    final values = last.map((m) => _asDouble(m['leads'] ?? m['count'] ?? 0)).toList();
    final maxV = values.isEmpty ? 1.0 : values.reduce((a, b) => a > b ? a : b).clamp(1, double.infinity);

    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(18),
        border: Border.all(color: scheme.outlineVariant.withValues(alpha: 0.4)),
        gradient: LinearGradient(
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
          colors: [
            Colors.white.withValues(alpha: 0.05),
            Colors.transparent,
          ],
        ),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text('Growth Trajectory', style: GoogleFonts.montserrat(fontSize: 12, fontWeight: FontWeight.w900)),
                  const SizedBox(height: 2),
                  Text('Portfolio valuation over time', style: GoogleFonts.montserrat(fontSize: 10, fontWeight: FontWeight.w700, color: scheme.onSurface.withValues(alpha: 0.55))),
                ],
              ),
              Container(
                width: 34,
                height: 34,
                decoration: BoxDecoration(
                  borderRadius: BorderRadius.circular(10),
                  color: accent.withValues(alpha: 0.12),
                ),
                child: Icon(LucideIcons.barChart3, size: 16, color: accent),
              ),
            ],
          ),
          const SizedBox(height: 16),
          SizedBox(
            height: 140,
            child: Row(
              crossAxisAlignment: CrossAxisAlignment.end,
              children: [
                for (int i = 0; i < (values.isEmpty ? 8 : values.length); i++)
                  Expanded(
                    child: Padding(
                      padding: const EdgeInsets.symmetric(horizontal: 4),
                      child: AnimatedContainer(
                        duration: const Duration(milliseconds: 520),
                        curve: Curves.easeOutCubic,
                        height: 18 + (values.isEmpty ? 0 : (values[i] / maxV) * 112),
                        decoration: BoxDecoration(
                          borderRadius: const BorderRadius.vertical(top: Radius.circular(6)),
                          gradient: LinearGradient(
                            begin: Alignment.bottomCenter,
                            end: Alignment.topCenter,
                            colors: [accent.withValues(alpha: 0.25), accent],
                          ),
                        ),
                      ),
                    ),
                  ),
              ],
            ),
          ),
          const SizedBox(height: 10),
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              for (final m in (last.isEmpty ? const <Map<String, dynamic>>[] : last))
                Expanded(
                  child: Text(
                    _monthShort((m['_id'] ?? '').toString()),
                    textAlign: TextAlign.center,
                    style: GoogleFonts.montserrat(fontSize: 8, fontWeight: FontWeight.w900, letterSpacing: 1.8, color: scheme.onSurface.withValues(alpha: 0.45)),
                  ),
                ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _allocRow(ColorScheme scheme, {required String label, required int value, required Color color}) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 12),
      child: Column(
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Expanded(child: Text(label, style: GoogleFonts.montserrat(fontSize: 10, fontWeight: FontWeight.w800, color: scheme.onSurface.withValues(alpha: 0.7)))),
              Text('$value%', style: GoogleFonts.montserrat(fontSize: 10, fontWeight: FontWeight.w900, color: scheme.onSurface.withValues(alpha: 0.7))),
            ],
          ),
          const SizedBox(height: 6),
          ClipRRect(
            borderRadius: BorderRadius.circular(999),
            child: SizedBox(
              height: 6,
              child: Stack(
                children: [
                  Positioned.fill(child: Container(color: scheme.surfaceContainerHighest.withValues(alpha: 0.45))),
                  Positioned.fill(
                    child: FractionallySizedBox(
                      alignment: Alignment.centerLeft,
                      widthFactor: (value / 100).clamp(0.0, 1.0),
                      child: Container(color: color),
                    ),
                  ),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _kv(String k, String v, ColorScheme scheme) => Padding(
        padding: const EdgeInsets.symmetric(vertical: 6),
        child: Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            Expanded(child: Text(k, style: GoogleFonts.montserrat(fontSize: 11, fontWeight: FontWeight.w600, color: scheme.onSurface.withValues(alpha: 0.65)))),
            Text(v, style: GoogleFonts.montserrat(fontSize: 11, fontWeight: FontWeight.w900)),
          ],
        ),
      );
}
