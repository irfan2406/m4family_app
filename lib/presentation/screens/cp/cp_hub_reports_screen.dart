import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:lucide_icons/lucide_icons.dart';
import 'package:m4_mobile/presentation/providers/auth_provider.dart';

/// Web `/cp/hub/reports` — monthly lead trend from performance payload.
class CpHubReportsScreen extends ConsumerStatefulWidget {
  const CpHubReportsScreen({super.key});

  @override
  ConsumerState<CpHubReportsScreen> createState() => _CpHubReportsScreenState();
}

class _CpHubReportsScreenState extends ConsumerState<CpHubReportsScreen> {
  List<dynamic> _months = [];
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
        if (d is Map && d['monthlyGraph'] is List) {
          _months = List<dynamic>.from(d['monthlyGraph'] as List);
        }
      }
    } catch (_) {}
    if (mounted) setState(() => _loading = false);
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        leading: IconButton(icon: const Icon(LucideIcons.arrowLeft), onPressed: () => context.pop()),
        title: Text('Reports', style: GoogleFonts.montserrat(fontWeight: FontWeight.w800)),
      ),
      body: _loading
          ? const Center(child: CircularProgressIndicator())
          : _months.isEmpty
              ? const Center(child: Text('No monthly data yet'))
              : ListView.builder(
                  padding: const EdgeInsets.all(16),
                  itemCount: _months.length,
                  itemBuilder: (_, i) {
                    final m = _months[i];
                    final month = m['_id']?.toString() ?? '';
                    final count = m['leads'] ?? m['count'] ?? 0;
                    return Card(
                      child: ListTile(
                        title: Text(month),
                        trailing: Text('$count leads', style: const TextStyle(fontWeight: FontWeight.bold)),
                      ),
                    );
                  },
                ),
    );
  }
}
