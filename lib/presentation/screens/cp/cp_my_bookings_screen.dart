import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:intl/intl.dart';
import 'package:lucide_icons/lucide_icons.dart';
import 'package:m4_mobile/presentation/providers/auth_provider.dart';

/// Web `/cp/booking/my-bookings` — `GET /api/bookings/my` (CP sees `cp` bookings).
class CpMyBookingsScreen extends ConsumerStatefulWidget {
  const CpMyBookingsScreen({super.key});

  @override
  ConsumerState<CpMyBookingsScreen> createState() => _CpMyBookingsScreenState();
}

class _CpMyBookingsScreenState extends ConsumerState<CpMyBookingsScreen> {
  List<dynamic> _list = [];
  bool _loading = true;

  @override
  void initState() {
    super.initState();
    _load();
  }

  Future<void> _load() async {
    setState(() => _loading = true);
    try {
      final res = await ref.read(apiClientProvider).getCpBookings();
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
        title: Text('My bookings', style: GoogleFonts.montserrat(fontWeight: FontWeight.w800)),
      ),
      body: _loading
          ? const Center(child: CircularProgressIndicator())
          : RefreshIndicator(
              onRefresh: _load,
              child: _list.isEmpty
                  ? ListView(
                      children: const [
                        SizedBox(height: 80),
                        Center(child: Text('No bookings yet')),
                      ],
                    )
                  : ListView.builder(
                      padding: const EdgeInsets.all(16),
                      itemCount: _list.length,
                      itemBuilder: (_, i) {
                        final b = _list[i];
                        final proj = b['project'];
                        String title = 'Project';
                        if (proj is Map) title = (proj['title'] ?? 'Project').toString();
                        final type = (b['type'] ?? '').toString();
                        final status = (b['status'] ?? '').toString();
                        final sd = b['scheduledDate'];
                        DateTime? dt;
                        if (sd != null) dt = DateTime.tryParse(sd.toString());
                        return Card(
                          child: ListTile(
                            leading: Icon(
                              type.contains('Site') ? LucideIcons.calendar : LucideIcons.building2,
                            ),
                            title: Text(title, style: const TextStyle(fontWeight: FontWeight.bold)),
                            subtitle: Text(
                              '[$type] ${dt != null ? DateFormat.yMMMd().add_jm().format(dt.toLocal()) : ''}',
                            ),
                            trailing: Chip(label: Text(status, style: const TextStyle(fontSize: 10))),
                          ),
                        );
                      },
                    ),
            ),
    );
  }
}
