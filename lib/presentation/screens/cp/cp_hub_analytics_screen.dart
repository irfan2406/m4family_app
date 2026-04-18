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
  bool _loading = true;

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
        if (d is Map) _data = Map<String, dynamic>.from(d);
      }
    } catch (_) {}
    if (mounted) setState(() => _loading = false);
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        leading: IconButton(icon: const Icon(LucideIcons.arrowLeft), onPressed: () => context.pop()),
        title: Text('Analytics', style: GoogleFonts.montserrat(fontWeight: FontWeight.w800)),
      ),
      body: _loading
          ? const Center(child: CircularProgressIndicator())
          : ListView(
              padding: const EdgeInsets.all(20),
              children: [
                if (_data != null) ...[
                  _row('Total leads', '${_data!['totalLeads']}'),
                  _row('Bookings / conversions', '${_data!['totalConversions']}'),
                  _row('Conversion rate', '${_data!['conversionRate']}'),
                  _row('Total commission', '${_data!['totalCommission']}'),
                  _row('Paid commission', '${_data!['paidCommission']}'),
                ],
              ],
            ),
    );
  }

  Widget _row(String k, String v) => Padding(
        padding: const EdgeInsets.symmetric(vertical: 10),
        child: Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            Expanded(child: Text(k)),
            Text(v, style: const TextStyle(fontWeight: FontWeight.bold)),
          ],
        ),
      );
}
