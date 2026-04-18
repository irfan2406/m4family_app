import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:lucide_icons/lucide_icons.dart';
import 'package:m4_mobile/presentation/providers/auth_provider.dart';

/// Web `/cp/hub/insights` — narrative from `GET /api/cp/performance`.
class CpHubInsightsScreen extends ConsumerStatefulWidget {
  const CpHubInsightsScreen({super.key});

  @override
  ConsumerState<CpHubInsightsScreen> createState() => _CpHubInsightsScreenState();
}

class _CpHubInsightsScreenState extends ConsumerState<CpHubInsightsScreen> {
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
    final rate = _data?['conversionRate']?.toString() ?? '0%';
    final leads = _data?['totalLeads'] ?? 0;
    final books = _data?['totalConversions'] ?? 0;

    return Scaffold(
      appBar: AppBar(
        leading: IconButton(icon: const Icon(LucideIcons.arrowLeft), onPressed: () => context.pop()),
        title: Text('Insights', style: GoogleFonts.montserrat(fontWeight: FontWeight.w800)),
      ),
      body: _loading
          ? const Center(child: CircularProgressIndicator())
          : Padding(
              padding: const EdgeInsets.all(20),
              child: Text(
                'Your pipeline shows $leads assigned leads with $books closed bookings, '
                'yielding a conversion rate of $rate. Focus follow-ups on high-intent prospects '
                'to improve commission eligibility.',
                style: const TextStyle(height: 1.5, fontSize: 15),
              ),
            ),
    );
  }
}
