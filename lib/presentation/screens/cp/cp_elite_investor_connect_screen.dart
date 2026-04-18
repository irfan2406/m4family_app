import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:lucide_icons/lucide_icons.dart';

/// Web `/cp/elite/investor-connect` — portfolio-style opportunities (curated demo).
class CpEliteInvestorConnectScreen extends StatelessWidget {
  const CpEliteInvestorConnectScreen({super.key});

  static const _stats = [
    _Row('Portfolio Value', '₹12.4 Cr', '+14.2%', LucideIcons.dollarSign),
    _Row('Total ROI', '18.5%', '+2.1%', LucideIcons.trendingUp),
    _Row('Active Assets', '08', 'Stable', LucideIcons.pieChart),
  ];

  static const _opps = [
    _Opp(
      'M4 Sky Gardens — Phase 2',
      'Equity Investment',
      '₹2.5 Cr',
      '22% IRR',
      '4 Days',
      'https://images.unsplash.com/photo-1545324418-cc1a3fa10c00?auto=format&fit=crop&w=400&q=80',
    ),
    _Opp(
      'Commercial Hub — Powai',
      'Rental Yield Asset',
      '₹5.0 Cr',
      '9% Yield',
      '12 Days',
      'https://images.unsplash.com/photo-1486406146926-c627a92ad1ab?auto=format&fit=crop&w=400&q=80',
    ),
  ];

  @override
  Widget build(BuildContext context) {
    final scheme = Theme.of(context).colorScheme;
    return Scaffold(
      appBar: AppBar(
        leading: IconButton(icon: const Icon(LucideIcons.arrowLeft), onPressed: () => context.pop()),
        title: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text('Partner Terminal', style: GoogleFonts.montserrat(fontWeight: FontWeight.w800, fontSize: 16)),
            Text(
              'INSTITUTIONAL PORTFOLIO',
              style: GoogleFonts.montserrat(fontSize: 8, fontWeight: FontWeight.w800, letterSpacing: 2, color: scheme.primary),
            ),
          ],
        ),
      ),
      body: ListView(
        padding: const EdgeInsets.all(20),
        children: [
          Text(
            'PERFORMANCE',
            style: GoogleFonts.montserrat(fontSize: 10, fontWeight: FontWeight.w800, letterSpacing: 2, color: scheme.outline),
          ),
          const SizedBox(height: 12),
          ..._stats.map((s) => Card(
                margin: const EdgeInsets.only(bottom: 10),
                child: ListTile(
                  leading: CircleAvatar(backgroundColor: Colors.teal.withValues(alpha: 0.15), child: Icon(s.icon, size: 20)),
                  title: Text(s.label, style: TextStyle(fontSize: 11, color: scheme.outline)),
                  subtitle: Row(
                    children: [
                      Text(s.value, style: GoogleFonts.montserrat(fontWeight: FontWeight.w800, fontSize: 20)),
                      const SizedBox(width: 8),
                      Text(s.growth, style: TextStyle(color: Colors.green.shade600, fontWeight: FontWeight.w600, fontSize: 12)),
                    ],
                  ),
                ),
              )),
          const SizedBox(height: 16),
          Text(
            'OPPORTUNITIES',
            style: GoogleFonts.montserrat(fontSize: 10, fontWeight: FontWeight.w800, letterSpacing: 2, color: scheme.outline),
          ),
          const SizedBox(height: 12),
          ..._opps.map((o) => Card(
                margin: const EdgeInsets.only(bottom: 14),
                clipBehavior: Clip.antiAlias,
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.stretch,
                  children: [
                    AspectRatio(
                      aspectRatio: 16 / 9,
                      child: Image.network(
                        o.image,
                        fit: BoxFit.cover,
                        errorBuilder: (_, __, ___) => Container(color: scheme.surfaceContainerHighest, child: const Icon(LucideIcons.image)),
                      ),
                    ),
                    Padding(
                      padding: const EdgeInsets.all(16),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(o.title, style: GoogleFonts.montserrat(fontWeight: FontWeight.w800)),
                          const SizedBox(height: 4),
                          Text(o.type, style: TextStyle(fontSize: 11, color: scheme.outline)),
                          const SizedBox(height: 8),
                          Wrap(
                            spacing: 12,
                            runSpacing: 4,
                            children: [
                              Chip(label: Text('Min ${o.minTicket}', style: const TextStyle(fontSize: 11))),
                              Chip(label: Text(o.roi, style: const TextStyle(fontSize: 11))),
                              Chip(label: Text('Closes ${o.closing}', style: const TextStyle(fontSize: 11))),
                            ],
                          ),
                          const SizedBox(height: 12),
                          SizedBox(
                            width: double.infinity,
                            child: OutlinedButton(
                              onPressed: () {
                                ScaffoldMessenger.of(context).showSnackBar(
                                  const SnackBar(content: Text('Contact RM for allocation — demo')),
                                );
                              },
                              child: const Text('Express interest'),
                            ),
                          ),
                        ],
                      ),
                    ),
                  ],
                ),
              )),
        ],
      ),
    );
  }
}

class _Row {
  final String label;
  final String value;
  final String growth;
  final IconData icon;
  const _Row(this.label, this.value, this.growth, this.icon);
}

class _Opp {
  final String title;
  final String type;
  final String minTicket;
  final String roi;
  final String closing;
  final String image;
  const _Opp(this.title, this.type, this.minTicket, this.roi, this.closing, this.image);
}
