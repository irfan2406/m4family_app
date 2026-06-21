import 'package:cached_network_image/cached_network_image.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:lucide_icons/lucide_icons.dart';
import 'package:m4_mobile/core/theme/app_theme.dart';
import 'package:m4_mobile/presentation/providers/auth_provider.dart';

/// Web `/cp/elite/investor-connect` — "Partner Terminal" institutional portfolio
/// engine: performance metrics, high-yield ventures, and a wealth-concierge panel.
class CpEliteInvestorConnectScreen extends ConsumerStatefulWidget {
  const CpEliteInvestorConnectScreen({super.key});

  @override
  ConsumerState<CpEliteInvestorConnectScreen> createState() => _CpEliteInvestorConnectScreenState();
}

class _CpEliteInvestorConnectScreenState extends ConsumerState<CpEliteInvestorConnectScreen> {
  bool _loading = true;
  List<_Stat> _stats = const [];
  List<_Opp> _opps = const [];

  // Static demo data (web `/cp/elite/investor-connect` is a curated prototype).
  static const _demoStats = [
    _Stat('Portfolio Value', '₹12.4 Cr', '+14.2%', LucideIcons.dollarSign),
    _Stat('Total ROI', '18.5%', '+2.1%', LucideIcons.trendingUp),
    _Stat('Active Assets', '08', 'Stable', LucideIcons.pieChart),
  ];

  static const _demoOpps = [
    _Opp(
      'M4 Sky Gardens — Phase 2',
      'Equity Investment',
      '₹2.5 Cr',
      '22% IRR',
      'https://images.unsplash.com/photo-1545324418-cc1a3fa10c00?auto=format&fit=crop&w=400&q=80',
    ),
    _Opp(
      'Commercial Hub — Powai',
      'Rental Yield Asset',
      '₹5.0 Cr',
      '9% Yield',
      'https://images.unsplash.com/photo-1486406146926-c627a92ad1ab?auto=format&fit=crop&w=400&q=80',
    ),
  ];

  @override
  void initState() {
    super.initState();
    _load();
  }

  Future<void> _load() async {
    setState(() => _loading = true);
    // No dedicated elite-opportunities endpoint exists yet; fall back to curated
    // demo data so the terminal matches the client-approved web prototype.
    try {
      // Touch the api client so wiring stays ready when an endpoint lands.
      ref.read(apiClientProvider);
    } catch (_) {}
    if (!mounted) return;
    setState(() {
      _stats = _demoStats;
      _opps = _demoOpps;
      _loading = false;
    });
  }

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final scheme = Theme.of(context).colorScheme;

    final bg = isDark ? Colors.black : Colors.white;
    final textPrimary = isDark ? Colors.white : Colors.black;
    final muted = (isDark ? Colors.white : Colors.black).withValues(alpha: 0.5);
    final card = isDark ? Colors.white.withValues(alpha: 0.03) : Colors.white;
    final border = scheme.outlineVariant.withValues(alpha: 0.5);

    return Scaffold(
      appBar: AppBar(
        leading: IconButton(
          icon: const Icon(LucideIcons.arrowLeft),
          onPressed: () => context.pop(),
        ),
        title: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              'Partner Terminal',
              style: GoogleFonts.montserrat(fontWeight: FontWeight.w900, fontSize: 16),
            ),
            Text(
              'INSTITUTIONAL PORTFOLIO ENGINE',
              style: GoogleFonts.montserrat(
                fontSize: 8,
                fontWeight: FontWeight.w900,
                letterSpacing: 2,
                color: scheme.primary,
              ),
            ),
          ],
        ),
      ),
      body: _loading
          ? const Center(child: CircularProgressIndicator(color: M4Theme.premiumBlue))
          : RefreshIndicator(
              onRefresh: _load,
              child: ListView(
                padding: const EdgeInsets.all(20),
                children: [
                  // ── Performance Metrics ─────────────────────────────────
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      Text(
                        'PERFORMANCE METRICS',
                        style: GoogleFonts.montserrat(
                          fontSize: 10,
                          fontWeight: FontWeight.w800,
                          letterSpacing: 4,
                          color: muted,
                        ),
                      ),
                      Container(
                        padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 5),
                        decoration: BoxDecoration(
                          color: scheme.primary.withValues(alpha: 0.2),
                          borderRadius: BorderRadius.circular(999),
                        ),
                        child: Text(
                          'REAL-TIME DATA',
                          style: GoogleFonts.montserrat(
                            fontSize: 8,
                            fontWeight: FontWeight.w900,
                            letterSpacing: 1.5,
                            color: scheme.primary,
                          ),
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 20),
                  ..._stats.map((s) => _statCard(s, isDark, textPrimary, muted, card, border, scheme)),

                  const SizedBox(height: 20),

                  // ── High-Yield Ventures ─────────────────────────────────
                  Text(
                    'HIGH-YIELD VENTURES',
                    style: GoogleFonts.montserrat(
                      fontSize: 10,
                      fontWeight: FontWeight.w800,
                      letterSpacing: 4,
                      color: muted,
                    ),
                  ),
                  const SizedBox(height: 20),
                  if (_opps.isEmpty)
                    Padding(
                      padding: const EdgeInsets.symmetric(vertical: 40),
                      child: Center(
                        child: Text(
                          'No ventures available right now',
                          style: GoogleFonts.montserrat(color: muted, fontWeight: FontWeight.w700),
                        ),
                      ),
                    )
                  else
                    ..._opps.map((o) => _oppCard(o, isDark, bg, textPrimary, muted, card, border, scheme)),

                  const SizedBox(height: 20),

                  // ── Advisory Panel (Wealth Concierge) ───────────────────
                  _advisoryPanel(isDark, bg, textPrimary, scheme),

                  const SizedBox(height: 40),
                ],
              ),
            ),
    );
  }

  // ── Stat card ─────────────────────────────────────────────────────────────
  Widget _statCard(
    _Stat s,
    bool isDark,
    Color textPrimary,
    Color muted,
    Color card,
    Color border,
    ColorScheme scheme,
  ) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 24),
      child: InkWell(
        onTap: () {},
        borderRadius: BorderRadius.circular(56),
        child: Container(
          padding: const EdgeInsets.all(20),
          decoration: BoxDecoration(
            color: card,
            borderRadius: BorderRadius.circular(56),
            border: Border.all(color: border),
            boxShadow: [
              BoxShadow(
                color: Colors.black.withValues(alpha: 0.1),
                blurRadius: 30,
                offset: const Offset(0, 12),
              ),
            ],
          ),
          child: Row(
            children: [
              // Icon box: 72x72 rounded-[2rem], bg-background, inner shadow.
              Container(
                width: 72,
                height: 72,
                decoration: BoxDecoration(
                  color: isDark ? Colors.black : Colors.white,
                  borderRadius: BorderRadius.circular(32),
                  border: Border.all(color: border),
                  boxShadow: [
                    BoxShadow(
                      color: Colors.black.withValues(alpha: isDark ? 0.4 : 0.06),
                      blurRadius: 8,
                      offset: const Offset(0, 2),
                    ),
                  ],
                ),
                alignment: Alignment.center,
                child: Icon(s.icon, size: 40, color: scheme.primary),
              ),
              const SizedBox(width: 24),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      s.label.toUpperCase(),
                      style: GoogleFonts.montserrat(
                        fontSize: 11,
                        fontWeight: FontWeight.w900,
                        letterSpacing: 3,
                        color: muted,
                      ),
                    ),
                    const SizedBox(height: 6),
                    Row(
                      crossAxisAlignment: CrossAxisAlignment.end,
                      children: [
                        Flexible(
                          child: Text(
                            s.value.toUpperCase(),
                            style: GoogleFonts.montserrat(
                              fontSize: 28,
                              fontWeight: FontWeight.w900,
                              height: 1,
                              letterSpacing: -1,
                              color: textPrimary,
                            ),
                          ),
                        ),
                        const SizedBox(width: 12),
                        Padding(
                          padding: const EdgeInsets.only(bottom: 4),
                          child: Text(
                            s.growth.toUpperCase(),
                            style: GoogleFonts.montserrat(
                              fontSize: 10,
                              fontWeight: FontWeight.w900,
                              letterSpacing: -0.5,
                              color: Colors.green.shade500,
                            ),
                          ),
                        ),
                      ],
                    ),
                  ],
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  // ── Opportunity card ───────────────────────────────────────────────────────
  Widget _oppCard(
    _Opp o,
    bool isDark,
    Color bg,
    Color textPrimary,
    Color muted,
    Color card,
    Color border,
    ColorScheme scheme,
  ) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 32),
      child: Container(
        decoration: BoxDecoration(
          color: card,
          borderRadius: BorderRadius.circular(64),
          border: Border.all(color: border),
          boxShadow: [
            BoxShadow(
              color: Colors.black.withValues(alpha: 0.15),
              blurRadius: 40,
              offset: const Offset(0, 18),
            ),
          ],
        ),
        child: ClipRRect(
          borderRadius: BorderRadius.circular(64),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              // Image section with gradient overlay + ROI badge.
              SizedBox(
                height: 240,
                child: Stack(
                  fit: StackFit.expand,
                  children: [
                    CachedNetworkImage(
                      imageUrl: o.image,
                      fit: BoxFit.cover,
                      placeholder: (_, __) => Container(color: scheme.surfaceContainerHighest),
                      errorWidget: (_, __, ___) => Container(
                        color: scheme.surfaceContainerHighest,
                        child: Icon(LucideIcons.image, color: muted),
                      ),
                    ),
                    // gradient-to-t from-background via-transparent
                    DecoratedBox(
                      decoration: BoxDecoration(
                        gradient: LinearGradient(
                          begin: Alignment.bottomCenter,
                          end: Alignment.topCenter,
                          colors: [bg, bg.withValues(alpha: 0.0)],
                        ),
                      ),
                    ),
                    // expectedROI badge — top-right.
                    Positioned(
                      top: 16,
                      right: 16,
                      child: Container(
                        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
                        decoration: BoxDecoration(
                          color: scheme.primary,
                          borderRadius: BorderRadius.circular(999),
                          boxShadow: [
                            BoxShadow(
                              color: Colors.black.withValues(alpha: 0.25),
                              blurRadius: 24,
                              offset: const Offset(0, 8),
                            ),
                          ],
                        ),
                        child: Text(
                          o.roi.toUpperCase(),
                          style: GoogleFonts.montserrat(
                            fontSize: 10,
                            fontWeight: FontWeight.w900,
                            letterSpacing: 1.5,
                            color: scheme.onPrimary,
                          ),
                        ),
                      ),
                    ),
                  ],
                ),
              ),
              // Content section.
              Padding(
                padding: const EdgeInsets.all(28),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      o.title.toUpperCase(),
                      style: GoogleFonts.montserrat(
                        fontSize: 22,
                        fontWeight: FontWeight.w900,
                        letterSpacing: -1,
                        height: 1,
                        color: textPrimary,
                      ),
                    ),
                    const SizedBox(height: 8),
                    Row(
                      children: [
                        Icon(LucideIcons.globe, size: 16, color: scheme.primary),
                        const SizedBox(width: 12),
                        Flexible(
                          child: Text(
                            o.type.toUpperCase(),
                            style: GoogleFonts.montserrat(
                              fontSize: 10,
                              fontWeight: FontWeight.w900,
                              letterSpacing: 1.5,
                              color: muted,
                            ),
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 24),
                    Divider(height: 1, color: border),
                    const SizedBox(height: 24),
                    Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      crossAxisAlignment: CrossAxisAlignment.center,
                      children: [
                        Expanded(
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Text(
                                'INSTITUTIONAL ENTRY',
                                style: GoogleFonts.montserrat(
                                  fontSize: 9,
                                  fontWeight: FontWeight.w900,
                                  letterSpacing: 3,
                                  color: muted,
                                ),
                              ),
                              const SizedBox(height: 6),
                              Text(
                                o.minTicket.toUpperCase(),
                                style: GoogleFonts.montserrat(
                                  fontSize: 20,
                                  fontWeight: FontWeight.w900,
                                  letterSpacing: -1,
                                  height: 1,
                                  color: textPrimary,
                                ),
                              ),
                            ],
                          ),
                        ),
                        const SizedBox(width: 12),
                        _CommitButton(
                          isDark: isDark,
                          onTap: () {
                            ScaffoldMessenger.of(context).showSnackBar(
                              const SnackBar(content: Text('Contact your RM for allocation — demo')),
                            );
                          },
                        ),
                      ],
                    ),
                  ],
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  // ── Advisory panel (Wealth Concierge) ──────────────────────────────────────
  Widget _advisoryPanel(bool isDark, Color bg, Color textPrimary, ColorScheme scheme) {
    // Card: bg-foreground text-background — inverted surface.
    final panelBg = textPrimary;
    final onPanel = bg;
    return Container(
      decoration: BoxDecoration(
        color: panelBg,
        borderRadius: BorderRadius.circular(56),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.2),
            blurRadius: 40,
            offset: const Offset(0, 18),
          ),
        ],
      ),
      child: ClipRRect(
        borderRadius: BorderRadius.circular(56),
        child: Stack(
          children: [
            // gradient-to-tr from-primary/20 to-transparent
            Positioned.fill(
              child: DecoratedBox(
                decoration: BoxDecoration(
                  gradient: LinearGradient(
                    begin: Alignment.bottomLeft,
                    end: Alignment.topRight,
                    colors: [
                      scheme.primary.withValues(alpha: 0.2),
                      scheme.primary.withValues(alpha: 0.0),
                    ],
                  ),
                ),
              ),
            ),
            Padding(
              padding: const EdgeInsets.all(20),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    children: [
                      Container(
                        width: 72,
                        height: 72,
                        decoration: BoxDecoration(
                          color: onPanel,
                          shape: BoxShape.circle,
                          border: Border.all(color: onPanel.withValues(alpha: 0.2)),
                          boxShadow: [
                            BoxShadow(
                              color: Colors.black.withValues(alpha: 0.25),
                              blurRadius: 24,
                              offset: const Offset(0, 8),
                            ),
                          ],
                        ),
                        alignment: Alignment.center,
                        child: Icon(LucideIcons.shieldCheck, size: 40, color: scheme.primary),
                      ),
                      const SizedBox(width: 24),
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(
                              'WEALTH CONCIERGE',
                              style: GoogleFonts.montserrat(
                                fontSize: 20,
                                fontWeight: FontWeight.w900,
                                letterSpacing: -1,
                                height: 1,
                                color: onPanel,
                              ),
                            ),
                            const SizedBox(height: 6),
                            Text(
                              'GLOBAL STRATEGY DESK',
                              style: GoogleFonts.montserrat(
                                fontSize: 10,
                                fontWeight: FontWeight.w900,
                                letterSpacing: 1.5,
                                color: onPanel.withValues(alpha: 0.6),
                              ),
                            ),
                          ],
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 24),
                  SizedBox(
                    width: double.infinity,
                    height: 60,
                    child: OutlinedButton(
                      onPressed: () {
                        ScaffoldMessenger.of(context).showSnackBar(
                          const SnackBar(content: Text('Scheduling protocol call — demo')),
                        );
                      },
                      style: OutlinedButton.styleFrom(
                        backgroundColor: onPanel.withValues(alpha: 0.1),
                        side: BorderSide(color: onPanel.withValues(alpha: 0.2)),
                        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(999)),
                      ),
                      child: Text(
                        'SCHEDULE PROTOCOL CALL',
                        style: GoogleFonts.montserrat(
                          fontSize: 10,
                          fontWeight: FontWeight.w900,
                          letterSpacing: 3,
                          color: onPanel,
                        ),
                      ),
                    ),
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

/// "Commit Funds" pill — bg-foreground text-background with active:scale-95.
class _CommitButton extends StatefulWidget {
  const _CommitButton({required this.isDark, required this.onTap});

  final bool isDark;
  final VoidCallback onTap;

  @override
  State<_CommitButton> createState() => _CommitButtonState();
}

class _CommitButtonState extends State<_CommitButton> {
  bool _pressed = false;

  @override
  Widget build(BuildContext context) {
    final fg = widget.isDark ? Colors.white : Colors.black; // foreground
    final bg = widget.isDark ? Colors.black : Colors.white; // background
    return GestureDetector(
      onTapDown: (_) => setState(() => _pressed = true),
      onTapUp: (_) => setState(() => _pressed = false),
      onTapCancel: () => setState(() => _pressed = false),
      onTap: widget.onTap,
      child: AnimatedScale(
        scale: _pressed ? 0.95 : 1.0,
        duration: const Duration(milliseconds: 120),
        child: Container(
          height: 56,
          padding: const EdgeInsets.symmetric(horizontal: 28),
          alignment: Alignment.center,
          decoration: BoxDecoration(
            color: fg,
            borderRadius: BorderRadius.circular(999),
            boxShadow: [
              BoxShadow(
                color: Colors.black.withValues(alpha: 0.25),
                blurRadius: 24,
                offset: const Offset(0, 8),
              ),
            ],
          ),
          child: Text(
            'COMMIT FUNDS',
            style: GoogleFonts.montserrat(
              fontSize: 10,
              fontWeight: FontWeight.w900,
              letterSpacing: 2,
              color: bg,
            ),
          ),
        ),
      ),
    );
  }
}

class _Stat {
  final String label;
  final String value;
  final String growth;
  final IconData icon;
  const _Stat(this.label, this.value, this.growth, this.icon);
}

class _Opp {
  final String title;
  final String type;
  final String minTicket;
  final String roi;
  final String image;
  const _Opp(this.title, this.type, this.minTicket, this.roi, this.image);
}
