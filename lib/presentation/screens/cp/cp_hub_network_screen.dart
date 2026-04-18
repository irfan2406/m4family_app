import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:lucide_icons/lucide_icons.dart';
import 'package:m4_mobile/presentation/providers/auth_provider.dart';

/// Web `/cp/hub/network` — referral graph from `GET /api/cp/referrals`.
class CpHubNetworkScreen extends ConsumerStatefulWidget {
  const CpHubNetworkScreen({super.key});

  @override
  ConsumerState<CpHubNetworkScreen> createState() => _CpHubNetworkScreenState();
}

class _CpHubNetworkScreenState extends ConsumerState<CpHubNetworkScreen> {
  List<dynamic> _list = [];
  bool _loading = true;

  @override
  void initState() {
    super.initState();
    _load();
  }

  Future<void> _load() async {
    try {
      final res = await ref.read(apiClientProvider).getCpReferrals();
      if (!mounted) return;
      if (res.statusCode == 200 && res.data['status'] == true) {
        final d = res.data['data'];
        if (d is List) _list = List<dynamic>.from(d);
      }
    } catch (_) {}
    if (mounted) setState(() => _loading = false);
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        leading: IconButton(icon: const Icon(LucideIcons.arrowLeft), onPressed: () => context.pop()),
        title: Text('Network', style: GoogleFonts.montserrat(fontWeight: FontWeight.w800)),
      ),
      body: _loading
          ? const Center(child: CircularProgressIndicator())
          : _list.isEmpty
              ? const Center(child: Text('No referrals in your network yet'))
              : RefreshIndicator(
                  onRefresh: _load,
                  child: ListView.builder(
                    padding: const EdgeInsets.all(16),
                    itemCount: _list.length,
                    itemBuilder: (_, i) {
                      final r = _list[i];
                      final name = (r['referralName'] ?? r['clientName'] ?? '').toString();
                      final st = (r['status'] ?? '').toString();
                      return Card(
                        child: ListTile(
                          title: Text(name),
                          subtitle: Text(st),
                          trailing: const Icon(LucideIcons.chevronRight),
                        ),
                      );
                    },
                  ),
                ),
    );
  }
}
