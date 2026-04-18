import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:lucide_icons/lucide_icons.dart';
import 'package:m4_mobile/presentation/providers/auth_provider.dart';
import 'package:m4_mobile/presentation/providers/cp_shell_provider.dart';

/// Web `/cp/hub`: performance headline + tiles (analytics, calculator, network, reports, insights).
class CpHubScreen extends ConsumerStatefulWidget {
  const CpHubScreen({super.key});

  @override
  ConsumerState<CpHubScreen> createState() => _CpHubScreenState();
}

class _CpHubScreenState extends ConsumerState<CpHubScreen> {
  Map<String, dynamic>? _perf;
  bool _loading = true;

  @override
  void initState() {
    super.initState();
    _load();
  }

  Future<void> _load() async {
    try {
      final api = ref.read(apiClientProvider);
      final res = await api.getCpPerformance();
      if (!mounted) return;
      if (res.statusCode == 200 && res.data['status'] == true) {
        final d = res.data['data'];
        if (d is Map) _perf = Map<String, dynamic>.from(d);
      }
    } catch (_) {}
    if (mounted) setState(() => _loading = false);
  }

  @override
  Widget build(BuildContext context) {
    final user = ref.watch(authProvider).user;
    final name = user?['firstName']?.toString() ??
        user?['companyName']?.toString().split(' ').first ??
        'Partner';
    final scheme = Theme.of(context).colorScheme;

    return Scaffold(
      body: CustomScrollView(
        slivers: [
          SliverAppBar(
            expandedHeight: 120,
            pinned: true,
            flexibleSpace: FlexibleSpaceBar(
              title: Text(
                'Partner Hub',
                style: GoogleFonts.montserrat(fontWeight: FontWeight.w800, fontSize: 16),
              ),
            ),
          ),
          SliverToBoxAdapter(
            child: Padding(
              padding: const EdgeInsets.all(20),
              child: _loading
                  ? const Center(child: Padding(padding: EdgeInsets.all(32), child: CircularProgressIndicator()))
                  : Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          'Hi, $name',
                          style: GoogleFonts.montserrat(fontSize: 22, fontWeight: FontWeight.w300),
                        ),
                        const SizedBox(height: 16),
                        if (_perf != null) ...[
                          _metricRow(context, 'Total leads', '${_perf!['totalLeads'] ?? 0}'),
                          _metricRow(context, 'Conversions', '${_perf!['totalConversions'] ?? 0}'),
                          _metricRow(context, 'Conversion rate', '${_perf!['conversionRate'] ?? '0%'}'),
                          _metricRow(
                            context,
                            'Commission',
                            '${_perf!['totalCommission'] ?? 0}',
                          ),
                        ],
                        const SizedBox(height: 24),
                        Text(
                          'TOOLS',
                          style: GoogleFonts.montserrat(
                            fontSize: 10,
                            fontWeight: FontWeight.w800,
                            letterSpacing: 3,
                            color: scheme.outline,
                          ),
                        ),
                        const SizedBox(height: 12),
                        _tile(context, LucideIcons.barChart3, 'Analytics', '/cp/hub/analytics', Colors.teal),
                        _tile(context, LucideIcons.calculator, 'Calculator', '/cp/hub/calculator', Colors.purple),
                        _tile(context, LucideIcons.users, 'Network', '/cp/hub/network', Colors.deepPurple),
                        _tile(context, LucideIcons.fileText, 'Reports', '/cp/hub/reports', Colors.blue),
                        _tile(context, LucideIcons.zap, 'Insights', '/cp/hub/insights', Colors.amber),
                        const SizedBox(height: 16),
                        ListTile(
                          leading: const Icon(LucideIcons.messageCircle),
                          title: const Text('Concierge / Support'),
                          trailing: const Icon(LucideIcons.chevronRight),
                          onTap: () {
                            ref.read(cpNavigationIndexProvider.notifier).state = 4;
                          },
                        ),
                      ],
                    ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _metricRow(BuildContext context, String label, String value) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 8),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Text(label, style: TextStyle(color: Theme.of(context).hintColor, fontSize: 13)),
          Text(value, style: const TextStyle(fontWeight: FontWeight.w700)),
        ],
      ),
    );
  }

  Widget _tile(BuildContext context, IconData icon, String title, String route, Color c) {
    return Card(
      margin: const EdgeInsets.only(bottom: 10),
      child: ListTile(
        leading: CircleAvatar(backgroundColor: c.withValues(alpha: 0.2), child: Icon(icon, color: c, size: 20)),
        title: Text(title, style: GoogleFonts.montserrat(fontWeight: FontWeight.w700)),
        trailing: const Icon(LucideIcons.chevronRight, size: 18),
        onTap: () => context.push(route),
      ),
    );
  }
}
