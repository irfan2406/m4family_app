import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:lucide_icons/lucide_icons.dart';
import 'package:m4_mobile/core/utils/support_handlers.dart';

/// Web `/cp/elite/cp-connect` — institutional partner network (curated demo data).
class CpEliteCpConnectScreen extends StatefulWidget {
  const CpEliteCpConnectScreen({super.key});

  @override
  State<CpEliteCpConnectScreen> createState() => _CpEliteCpConnectScreenState();
}

class _CpEliteCpConnectScreenState extends State<CpEliteCpConnectScreen> {
  final _search = TextEditingController();
  String _q = '';

  static const _stats = [
    _Stat('Active Partners', '124', LucideIcons.users),
    _Stat('Total Payouts', '₹2.8 Cr', LucideIcons.trophy),
    _Stat('Lead Pipeline', '450+', LucideIcons.barChart3),
  ];

  static const _partners = [
    _Partner(
      'Premium Realty Group',
      'Rajesh Malhotra',
      'South Mumbai',
      '4.9',
      12,
      'https://images.unsplash.com/photo-1560250097-0b93528c311a?auto=format&fit=crop&w=100&q=80',
    ),
    _Partner(
      'Prestige Assets CP',
      'Sneha Kapoor',
      'Bandra-Khar',
      '4.8',
      8,
      'https://images.unsplash.com/photo-1573496359142-b8d87734a5a2?auto=format&fit=crop&w=100&q=80',
    ),
  ];

  @override
  void dispose() {
    _search.dispose();
    super.dispose();
  }

  List<_Partner> get _filtered {
    if (_q.isEmpty) return _partners;
    return _partners
        .where((p) =>
            p.name.toLowerCase().contains(_q) ||
            p.expert.toLowerCase().contains(_q) ||
            p.region.toLowerCase().contains(_q))
        .toList();
  }

  Future<void> _launchWa() async {
    await SupportHandlers.launchWhatsApp();
  }

  Future<void> _launchTel() async {
    await SupportHandlers.launchCall();
  }

  @override
  Widget build(BuildContext context) {
    final scheme = Theme.of(context).colorScheme;
    return Scaffold(
      appBar: AppBar(
        leading: IconButton(icon: const Icon(LucideIcons.arrowLeft), onPressed: () => context.pop()),
        title: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text('Partners Portal', style: GoogleFonts.montserrat(fontWeight: FontWeight.w800, fontSize: 16)),
            Text(
              'INSTITUTIONAL CP NETWORK',
              style: GoogleFonts.montserrat(fontSize: 8, fontWeight: FontWeight.w800, letterSpacing: 2, color: scheme.primary),
            ),
          ],
        ),
      ),
      body: ListView(
        padding: const EdgeInsets.all(20),
        children: [
          TextField(
            controller: _search,
            decoration: InputDecoration(
              hintText: 'Search verified partners…',
              prefixIcon: const Icon(LucideIcons.search, size: 20),
              border: OutlineInputBorder(borderRadius: BorderRadius.circular(16)),
              isDense: true,
            ),
            onChanged: (v) => setState(() => _q = v.trim().toLowerCase()),
          ),
          const SizedBox(height: 20),
          ..._stats.map((s) => Padding(
                padding: const EdgeInsets.only(bottom: 10),
                child: Card(
                  child: ListTile(
                    leading: CircleAvatar(backgroundColor: scheme.primary.withValues(alpha: 0.15), child: Icon(s.icon, size: 20)),
                    title: Text(s.label, style: TextStyle(fontSize: 11, color: scheme.outline)),
                    subtitle: Text(s.value, style: GoogleFonts.montserrat(fontWeight: FontWeight.w800, fontSize: 18)),
                    trailing: const Icon(LucideIcons.chevronRight, size: 18),
                  ),
                ),
              )),
          const SizedBox(height: 8),
          Text(
            'VERIFIED PARTNERS',
            style: GoogleFonts.montserrat(fontSize: 10, fontWeight: FontWeight.w800, letterSpacing: 2, color: scheme.outline),
          ),
          const SizedBox(height: 12),
          ..._filtered.map((p) => _PartnerCard(partner: p, onMessage: _launchWa, onCall: _launchTel)),
          if (_filtered.isEmpty) const Center(child: Padding(padding: EdgeInsets.all(24), child: Text('No matches'))),
        ],
      ),
    );
  }
}

class _Stat {
  final String label;
  final String value;
  final IconData icon;
  const _Stat(this.label, this.value, this.icon);
}

class _Partner {
  final String name;
  final String expert;
  final String region;
  final String rating;
  final int activeProjects;
  final String image;
  const _Partner(this.name, this.expert, this.region, this.rating, this.activeProjects, this.image);
}

class _PartnerCard extends StatelessWidget {
  final _Partner partner;
  final VoidCallback onMessage;
  final VoidCallback onCall;

  const _PartnerCard({required this.partner, required this.onMessage, required this.onCall});

  @override
  Widget build(BuildContext context) {
    return Card(
      margin: const EdgeInsets.only(bottom: 14),
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                ClipRRect(
                  borderRadius: BorderRadius.circular(12),
                  child: Image.network(partner.image, width: 56, height: 56, fit: BoxFit.cover,
                      errorBuilder: (_, __, ___) => const SizedBox(width: 56, height: 56, child: Icon(LucideIcons.user))),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(partner.name, style: GoogleFonts.montserrat(fontWeight: FontWeight.w800)),
                      Text(
                        '${partner.expert} · ${partner.region}',
                        style: TextStyle(fontSize: 11, color: Theme.of(context).hintColor),
                      ),
                    ],
                  ),
                ),
                Column(
                  crossAxisAlignment: CrossAxisAlignment.end,
                  children: [
                    Row(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        Icon(LucideIcons.star, size: 14, color: Theme.of(context).colorScheme.primary),
                        Text(partner.rating, style: const TextStyle(fontWeight: FontWeight.bold)),
                      ],
                    ),
                    Text('${partner.activeProjects} ops', style: const TextStyle(fontSize: 10)),
                  ],
                ),
              ],
            ),
            const SizedBox(height: 12),
            Row(
              children: [
                Expanded(
                  child: OutlinedButton.icon(
                    onPressed: onMessage,
                    icon: const Icon(LucideIcons.messageCircle, size: 16),
                    label: const Text('Message'),
                  ),
                ),
                const SizedBox(width: 8),
                Expanded(
                  child: FilledButton.icon(
                    onPressed: onCall,
                    icon: const Icon(LucideIcons.phone, size: 16),
                    label: const Text('Call'),
                  ),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }
}
