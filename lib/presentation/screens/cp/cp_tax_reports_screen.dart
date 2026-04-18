import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:intl/intl.dart';
import 'package:lucide_icons/lucide_icons.dart';
import 'package:m4_mobile/presentation/providers/auth_provider.dart';

/// `GET /api/cp/tax-reports` — TDS / statements list (server mock; same shape as investor).
class CpTaxReportsScreen extends ConsumerStatefulWidget {
  const CpTaxReportsScreen({super.key});

  @override
  ConsumerState<CpTaxReportsScreen> createState() => _CpTaxReportsScreenState();
}

class _CpTaxReportsScreenState extends ConsumerState<CpTaxReportsScreen> {
  List<dynamic> _rows = [];
  bool _loading = true;
  String? _yearFilter;

  @override
  void initState() {
    super.initState();
    _load();
  }

  Future<void> _load() async {
    setState(() => _loading = true);
    try {
      final res = await ref.read(apiClientProvider).getCpTaxReports(year: _yearFilter);
      if (!mounted) return;
      if (res.statusCode == 200 && res.data['status'] == true) {
        final d = res.data['data'];
        if (d is List) _rows = List<dynamic>.from(d);
      }
    } catch (_) {}
    if (mounted) setState(() => _loading = false);
  }

  Set<String> get _years {
    final s = <String>{};
    for (final r in _rows) {
      if (r is Map && r['year'] != null) s.add(r['year'].toString());
    }
    return s;
  }

  @override
  Widget build(BuildContext context) {
    final fmt = NumberFormat.currency(locale: 'en_IN', symbol: '₹', decimalDigits: 0);
    final scheme = Theme.of(context).colorScheme;

    return Scaffold(
      appBar: AppBar(
        leading: IconButton(icon: const Icon(LucideIcons.arrowLeft), onPressed: () => context.pop()),
        title: Text('Tax & statements', style: GoogleFonts.montserrat(fontWeight: FontWeight.w800)),
        actions: [
          PopupMenuButton<String?>(
            icon: const Icon(LucideIcons.filter),
            onSelected: (y) {
              setState(() => _yearFilter = y);
              _load();
            },
            itemBuilder: (context) => [
              const PopupMenuItem(value: null, child: Text('All years')),
              ..._years.map((y) => PopupMenuItem(value: y, child: Text(y))),
            ],
          ),
        ],
      ),
      body: _loading
          ? const Center(child: CircularProgressIndicator())
          : RefreshIndicator(
              onRefresh: _load,
              child: _rows.isEmpty
                  ? ListView(
                      children: const [
                        SizedBox(height: 80),
                        Center(child: Text('No statements available')),
                      ],
                    )
                  : ListView.builder(
                      padding: const EdgeInsets.all(16),
                      itemCount: _rows.length,
                      itemBuilder: (context, i) {
                        final r = _rows[i];
                        if (r is! Map) return const SizedBox.shrink();
                        final m = Map<String, dynamic>.from(r);
                        final name = m['name']?.toString() ?? 'Statement';
                        final type = m['type']?.toString() ?? 'PDF';
                        final date = m['date']?.toString() ?? '';
                        final year = m['year']?.toString() ?? '';
                        final tax = m['totalTaxDeducted'];
                        final taxStr = tax == null ? '—' : fmt.format(num.tryParse(tax.toString()) ?? 0);
                        return Card(
                          margin: const EdgeInsets.only(bottom: 10),
                          child: ListTile(
                            leading: CircleAvatar(
                              backgroundColor: scheme.primary.withValues(alpha: 0.15),
                              child: const Icon(LucideIcons.fileText, size: 20),
                            ),
                            title: Text(name, style: const TextStyle(fontWeight: FontWeight.w700)),
                            subtitle: Text('$year · $date · $type'),
                            trailing: Column(
                              mainAxisAlignment: MainAxisAlignment.center,
                              crossAxisAlignment: CrossAxisAlignment.end,
                              children: [
                                Text('TDS', style: TextStyle(fontSize: 10, color: scheme.outline)),
                                Text(taxStr, style: const TextStyle(fontWeight: FontWeight.w600, fontSize: 12)),
                              ],
                            ),
                            onTap: () {
                              ScaffoldMessenger.of(context).showSnackBar(
                                SnackBar(content: Text('Download $name — link when PDFs are hosted')),
                              );
                            },
                          ),
                        );
                      },
                    ),
            ),
    );
  }
}
