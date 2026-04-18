import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:m4_mobile/presentation/providers/auth_provider.dart';
import 'package:go_router/go_router.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:lucide_icons/lucide_icons.dart';

/// Web `/cp/payments`: wallet + commission ledger (`/api/cp/wallet`, `/api/cp/commissions`).
class CpPaymentsScreen extends ConsumerStatefulWidget {
  const CpPaymentsScreen({super.key});

  @override
  ConsumerState<CpPaymentsScreen> createState() => _CpPaymentsScreenState();
}

class _CpPaymentsScreenState extends ConsumerState<CpPaymentsScreen> {
  Map<String, dynamic>? _wallet;
  List<dynamic> _commissions = [];
  bool _loading = true;
  String _searchQuery = '';
  String _filter = 'All';

  @override
  void initState() {
    super.initState();
    _load();
  }

  Future<void> _load() async {
    setState(() => _loading = true);
    try {
      final api = ref.read(apiClientProvider);
      final w = await api.getCpWallet();
      final c = await api.getCpCommissions();
      if (!mounted) return;
      if (w.statusCode == 200 && w.data['status'] == true) {
        final d = w.data['data'];
        if (d is Map) _wallet = Map<String, dynamic>.from(d);
      }
      if (c.statusCode == 200 && c.data['status'] == true) {
        final d = c.data['data'];
        if (d is List) _commissions = List<dynamic>.from(d);
      }
    } catch (_) {}
    if (mounted) setState(() => _loading = false);
  }

  num _balance() {
    final w = _wallet;
    if (w == null) return 0;
    return (w['balance'] ?? w['availableBalance'] ?? 0) as num? ?? 0;
  }

  num _totalEarned() {
    final w = _wallet;
    if (w == null) return 0;
    return (w['totalEarned'] ?? 0) as num? ?? 0;
  }

  @override
  Widget build(BuildContext context) {
    final scheme = Theme.of(context).colorScheme;
    final q = _searchQuery.toLowerCase();

    final filtered = _commissions.where((c) {
      final amount = (c['amount'] ?? 0).toString();
      final status = (c['status'] ?? '').toString();
      final id = (c['_id'] ?? '').toString();
      final booking = c['bookingId'];
      String bookingRef = '';
      if (booking is Map) {
        bookingRef = (booking['_id'] ?? booking['bookingId'] ?? '').toString();
      } else if (booking != null) {
        bookingRef = booking.toString();
      }
      final text = '$amount $status $id $bookingRef'.toLowerCase();
      final searchOk = q.isEmpty || text.contains(q);
      if (_filter == 'All') return searchOk;
      if (_filter == 'Commission') return searchOk && status.isNotEmpty;
      if (_filter == 'Withdrawal') return false;
      return searchOk;
    }).toList();

    return Scaffold(
      appBar: AppBar(
        leading: IconButton(
          icon: const Icon(LucideIcons.arrowLeft),
          onPressed: () => context.pop(),
        ),
        title: Text(
          'Wallet & history',
          style: GoogleFonts.montserrat(fontWeight: FontWeight.w800, fontSize: 16),
        ),
      ),
      body: _loading
          ? const Center(child: CircularProgressIndicator())
          : RefreshIndicator(
              onRefresh: _load,
              child: ListView(
                padding: const EdgeInsets.all(16),
                children: [
                  Row(
                    children: [
                      Expanded(
                        child: _statTile(context, 'Available balance', 'AED ${_balance()}'),
                      ),
                      const SizedBox(width: 12),
                      Expanded(
                        child: _statTile(context, 'Total earned', 'AED ${_totalEarned()}', highlight: true),
                      ),
                    ],
                  ),
                  const SizedBox(height: 16),
                  TextField(
                    onChanged: (v) => setState(() => _searchQuery = v),
                    decoration: const InputDecoration(
                      hintText: 'Search transactions...',
                      prefixIcon: Icon(LucideIcons.search, size: 20),
                      border: OutlineInputBorder(),
                      isDense: true,
                    ),
                  ),
                  const SizedBox(height: 12),
                  Wrap(
                    spacing: 8,
                    children: ['All', 'Commission', 'Withdrawal'].map((f) {
                      final sel = _filter == f;
                      return ChoiceChip(
                        label: Text(f, style: const TextStyle(fontSize: 11)),
                        selected: sel,
                        onSelected: (_) => setState(() => _filter = f),
                      );
                    }).toList(),
                  ),
                  const SizedBox(height: 16),
                  if (filtered.isEmpty)
                    Padding(
                      padding: const EdgeInsets.all(32),
                      child: Center(
                        child: Text(
                          'No transactions yet',
                          style: TextStyle(color: scheme.outline),
                        ),
                      ),
                    )
                  else
                    ...filtered.map((c) {
                      final id = c['_id']?.toString() ?? '';
                      final short = id.length > 6 ? id.substring(id.length - 6).toUpperCase() : id.toUpperCase();
                      final amount = c['amount'];
                      final status = (c['status'] ?? '').toString();
                      final created = c['createdAt']?.toString();
                      DateTime? dt;
                      if (created != null) {
                        dt = DateTime.tryParse(created);
                      }
                      final booking = c['bookingId'];
                      String sub = 'Commission';
                      if (booking is Map) {
                        sub = 'Booking ${booking['bookingId'] ?? booking['_id'] ?? ''}';
                      }
                      return Card(
                        margin: const EdgeInsets.only(bottom: 10),
                        child: ListTile(
                          leading: const CircleAvatar(
                            child: Icon(LucideIcons.arrowDownLeft, size: 18),
                          ),
                          title: Text('AED ${amount ?? 0} • $short'),
                          subtitle: Text(
                            '${dt != null ? MaterialLocalizations.of(context).formatShortDate(dt) : ''} · $sub',
                            style: TextStyle(fontSize: 12, color: scheme.outline),
                          ),
                          trailing: Chip(
                            label: Text(status, style: const TextStyle(fontSize: 10)),
                          ),
                        ),
                      );
                    }),
                ],
              ),
            ),
    );
  }

  Widget _statTile(BuildContext context, String label, String value, {bool highlight = false}) {
    return Container(
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: Theme.of(context).colorScheme.outlineVariant),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            label.toUpperCase(),
            style: GoogleFonts.montserrat(fontSize: 9, letterSpacing: 1, color: Theme.of(context).hintColor),
          ),
          const SizedBox(height: 4),
          Text(
            value,
            style: GoogleFonts.montserrat(
              fontWeight: FontWeight.w800,
              fontSize: 14,
              color: highlight ? Colors.greenAccent : null,
            ),
          ),
        ],
      ),
    );
  }
}
