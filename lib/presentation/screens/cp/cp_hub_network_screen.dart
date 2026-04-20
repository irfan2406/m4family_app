import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:lucide_icons/lucide_icons.dart';
import 'package:m4_mobile/presentation/providers/auth_provider.dart';

/// Web `/cp/hub/network` — upcoming events + member spotlight + forum teaser.
/// Flutter: member spotlight backed by `GET /api/cp/referrals` (database).
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
    final scheme = Theme.of(context).colorScheme;
    const purple = Color(0xFFA855F7);

    final events = const [
      {
        'title': 'Annual Partner Gala',
        'date': 'Dec 15, 2024',
        'location': 'Grand Hyatt, Mumbai',
        'type': 'Exclusive',
      },
      {
        'title': 'Q3 Project Walkthrough',
        'date': 'Oct 10, 2024',
        'location': 'Aura Heights Site',
        'type': 'Site Visit',
      },
    ];

    final members = _list.whereType<Map>().map((m) => Map<String, dynamic>.from(m)).toList();
    return Scaffold(
      appBar: AppBar(
        leading: IconButton(icon: const Icon(LucideIcons.arrowLeft), onPressed: () => context.pop()),
        title: Text('Network', style: GoogleFonts.montserrat(fontWeight: FontWeight.w800)),
      ),
      body: _loading
          ? const Center(child: CircularProgressIndicator())
          : RefreshIndicator(
              onRefresh: _load,
              child: ListView(
                padding: const EdgeInsets.fromLTRB(16, 14, 16, 24),
                children: [
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      Row(
                        children: [
                          const Icon(LucideIcons.calendar, size: 16, color: purple),
                          const SizedBox(width: 8),
                          Text('Upcoming Events', style: GoogleFonts.montserrat(fontSize: 12, fontWeight: FontWeight.w900, letterSpacing: 0.2)),
                        ],
                      ),
                      TextButton(
                        onPressed: () => ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('Events coming soon'))),
                        child: Text('VIEW ALL', style: GoogleFonts.montserrat(fontSize: 9, fontWeight: FontWeight.w900, letterSpacing: 1.6, color: purple)),
                      ),
                    ],
                  ),
                  const SizedBox(height: 10),
                  for (final e in events) ...[
                    Container(
                      margin: const EdgeInsets.only(bottom: 10),
                      padding: const EdgeInsets.all(14),
                      decoration: BoxDecoration(
                        borderRadius: BorderRadius.circular(16),
                        border: Border.all(color: scheme.outlineVariant.withValues(alpha: 0.4)),
                        color: scheme.surfaceContainerHighest.withValues(alpha: 0.18),
                      ),
                      child: Stack(
                        children: [
                          Positioned(
                            top: -14,
                            right: -14,
                            child: Container(
                              padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
                              decoration: const BoxDecoration(
                                color: purple,
                                borderRadius: BorderRadius.only(bottomLeft: Radius.circular(12), topRight: Radius.circular(16)),
                              ),
                              child: Text(
                                (e['type'] ?? '').toString().toUpperCase(),
                                style: GoogleFonts.montserrat(fontSize: 8, fontWeight: FontWeight.w900, letterSpacing: 1.2, color: Colors.white),
                              ),
                            ),
                          ),
                          Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Text(e['title']!.toString(), style: GoogleFonts.montserrat(fontSize: 13, fontWeight: FontWeight.w900)),
                              const SizedBox(height: 6),
                              Text(
                                '${e['date']} • ${e['location']}',
                                style: GoogleFonts.montserrat(fontSize: 10, fontWeight: FontWeight.w700, color: scheme.onSurface.withValues(alpha: 0.55)),
                              ),
                              const SizedBox(height: 10),
                              FilledButton(
                                onPressed: () => ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('RSVP received'))),
                                style: FilledButton.styleFrom(
                                  backgroundColor: scheme.surfaceContainerHighest,
                                  foregroundColor: scheme.onSurface,
                                  minimumSize: const Size.fromHeight(36),
                                  shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                                ),
                                child: Text('RSVP NOW', style: GoogleFonts.montserrat(fontSize: 9, fontWeight: FontWeight.w900, letterSpacing: 2)),
                              ),
                            ],
                          ),
                        ],
                      ),
                    ),
                  ],
                  const SizedBox(height: 10),
                  Row(
                    children: [
                      const Icon(LucideIcons.users, size: 16, color: purple),
                      const SizedBox(width: 8),
                      Text('Member Spotlight', style: GoogleFonts.montserrat(fontSize: 12, fontWeight: FontWeight.w900, letterSpacing: 0.2)),
                    ],
                  ),
                  const SizedBox(height: 10),
                  if (members.isEmpty)
                    Text('No referrals in your network yet', style: GoogleFonts.montserrat(color: scheme.onSurfaceVariant))
                  else
                    GridView.builder(
                      shrinkWrap: true,
                      physics: const NeverScrollableScrollPhysics(),
                      gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
                        crossAxisCount: 3,
                        crossAxisSpacing: 10,
                        mainAxisSpacing: 10,
                      ),
                      itemCount: members.length.clamp(0, 6),
                      itemBuilder: (_, i) {
                        final r = members[i];
                        final name = (r['referralName'] ?? r['clientName'] ?? r['name'] ?? '').toString().trim();
                        final industry = (r['projectName'] ?? r['project'] ?? r['source'] ?? 'Partner').toString();
                        final initial = name.isNotEmpty ? name[0].toUpperCase() : 'P';
                        return Container(
                          padding: const EdgeInsets.all(10),
                          decoration: BoxDecoration(
                            borderRadius: BorderRadius.circular(14),
                            border: Border.all(color: scheme.outlineVariant.withValues(alpha: 0.4)),
                            color: scheme.onSurface.withValues(alpha: 0.03),
                          ),
                          child: Column(
                            mainAxisAlignment: MainAxisAlignment.center,
                            children: [
                              Container(
                                width: 40,
                                height: 40,
                                decoration: const BoxDecoration(
                                  shape: BoxShape.circle,
                                  gradient: LinearGradient(colors: [Color(0xFFA855F7), Color(0xFF6D28D9)]),
                                ),
                                child: Center(child: Text(initial, style: GoogleFonts.montserrat(color: Colors.white, fontWeight: FontWeight.w900))),
                              ),
                              const SizedBox(height: 8),
                              Text(
                                name.isEmpty ? 'Partner' : name,
                                maxLines: 1,
                                overflow: TextOverflow.ellipsis,
                                style: GoogleFonts.montserrat(fontSize: 10, fontWeight: FontWeight.w900),
                              ),
                              const SizedBox(height: 2),
                              Text(
                                industry.toUpperCase(),
                                maxLines: 1,
                                overflow: TextOverflow.ellipsis,
                                style: GoogleFonts.montserrat(fontSize: 8, fontWeight: FontWeight.w800, letterSpacing: 1.2, color: scheme.onSurface.withValues(alpha: 0.5)),
                              ),
                            ],
                          ),
                        );
                      },
                    ),
                  const SizedBox(height: 16),
                  Container(
                    padding: const EdgeInsets.all(14),
                    decoration: BoxDecoration(
                      borderRadius: BorderRadius.circular(16),
                      border: Border.all(color: const Color(0x3360A5FA)),
                      color: const Color(0x1A60A5FA),
                    ),
                    child: Row(
                      children: [
                        Expanded(
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Text('Private Forum', style: GoogleFonts.montserrat(fontSize: 12, fontWeight: FontWeight.w900)),
                              const SizedBox(height: 4),
                              Text(
                                'Discuss trends with verified Partners',
                                style: GoogleFonts.montserrat(fontSize: 10, fontWeight: FontWeight.w700, color: scheme.onSurface.withValues(alpha: 0.55)),
                              ),
                            ],
                          ),
                        ),
                        IconButton(
                          onPressed: () => ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('Forum coming soon'))),
                          icon: const Icon(LucideIcons.messageSquare, size: 18),
                        ),
                      ],
                    ),
                  ),
                ],
              ),
            ),
    );
  }
}
