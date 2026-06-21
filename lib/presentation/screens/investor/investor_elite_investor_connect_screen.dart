import 'package:cached_network_image/cached_network_image.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:lucide_icons/lucide_icons.dart';
import 'package:m4_mobile/core/theme/app_theme.dart';
import 'package:m4_mobile/presentation/providers/auth_provider.dart';

const Color _gold = Color(0xFFFFD700);

/// Web `/investor/elite/investor-connect` — "Investor Connect": the curated
/// investor network / community. Surfaces network stats, active co-investors,
/// and successful syndicate deals from the investor's perspective.
///
/// Mirrors [CpEliteInvestorConnectScreen] structure but with investor-specific,
/// community-oriented data. No dedicated network endpoint exists yet, so the
/// screen touches the api client (for future wiring) and falls back to curated
/// demo data matching the client-approved web prototype.
class InvestorEliteInvestorConnectScreen extends ConsumerStatefulWidget {
  const InvestorEliteInvestorConnectScreen({super.key});

  @override
  ConsumerState<InvestorEliteInvestorConnectScreen> createState() =>
      _InvestorEliteInvestorConnectScreenState();
}

class _InvestorEliteInvestorConnectScreenState
    extends ConsumerState<InvestorEliteInvestorConnectScreen> {
  bool _loading = true;
  String? _error;
  List<_Stat> _stats = const [];
  List<_Peer> _peers = const [];
  List<_Deal> _deals = const [];

  // ── Static demo data (web prototype is a curated network view) ─────────────
  static const _demoStats = [
    _Stat('Active Co-Investors', '142', '+12 this month', LucideIcons.users),
    _Stat('Deals Closed', '38', '+5 this quarter', LucideIcons.briefcase),
    _Stat('Network Capital', '₹248 Cr', '+8.4%', LucideIcons.trendingUp),
  ];

  static const _demoPeers = [
    _Peer(
      'Aarav Mehta',
      'Mumbai, MH',
      '₹18.2 Cr',
      ['Equity', 'Commercial', 'Land'],
      'https://images.unsplash.com/photo-1500648767791-00dcc994a43e?auto=format&fit=crop&w=200&q=80',
    ),
    _Peer(
      'Priya Sharma',
      'Bengaluru, KA',
      '₹11.6 Cr',
      ['Rental Yield', 'Co-Living'],
      'https://images.unsplash.com/photo-1494790108377-be9c29b29330?auto=format&fit=crop&w=200&q=80',
    ),
    _Peer(
      'Rohan Kapoor',
      'Delhi, DL',
      '₹26.9 Cr',
      ['REITs', 'Equity', 'Hospitality'],
      'https://images.unsplash.com/photo-1507003211169-0a1dd7228f2d?auto=format&fit=crop&w=200&q=80',
    ),
  ];

  static const _demoDeals = [
    _Deal(
      'M4 Sky Gardens — Phase 2',
      'Syndicate of 8 investors',
      '₹2.5 Cr',
      '22% IRR',
      'https://images.unsplash.com/photo-1545324418-cc1a3fa10c00?auto=format&fit=crop&w=400&q=80',
    ),
    _Deal(
      'Commercial Hub — Powai',
      'Syndicate of 5 investors',
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
    setState(() {
      _loading = true;
      _error = null;
    });
    // No dedicated investor-network endpoint exists yet; touch the api client so
    // wiring stays ready when an endpoint lands, then fall back to curated demo
    // data that matches the client-approved web prototype.
    try {
      ref.read(apiClientProvider);
      if (!mounted) return;
      setState(() {
        _stats = _demoStats;
        _peers = _demoPeers;
        _deals = _demoDeals;
        _loading = false;
      });
    } catch (e) {
      if (!mounted) return;
      setState(() {
        _error = 'Could not load the investor network. Please try again.';
        _loading = false;
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;

    final bg = isDark ? Colors.black : Colors.white;
    final textPrimary = isDark ? Colors.white : Colors.black;
    final muted = (isDark ? Colors.white : Colors.black).withValues(alpha: 0.5);
    final card = isDark ? Colors.white.withValues(alpha: 0.03) : Colors.white;
    final border = isDark
        ? Colors.white.withValues(alpha: 0.08)
        : Colors.black.withValues(alpha: 0.06);

    final user = ref.watch(authProvider).user;
    final name = (user?['name'] as String?)?.trim();
    final greeting = (name != null && name.isNotEmpty)
        ? 'Welcome back, ${name.split(' ').first}'
        : 'Your investor network';

    return Scaffold(
      backgroundColor: bg,
      appBar: AppBar(
        backgroundColor: bg,
        elevation: 0,
        leading: IconButton(
          icon: Icon(LucideIcons.arrowLeft, color: textPrimary),
          onPressed: () =>
              context.canPop() ? context.pop() : context.go('/investor/home'),
        ),
        title: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              'Investor Connect',
              style: GoogleFonts.montserrat(
                fontWeight: FontWeight.w900,
                fontSize: 16,
                color: textPrimary,
              ),
            ),
            Text(
              'ELITE INVESTOR NETWORK',
              style: GoogleFonts.montserrat(
                fontSize: 8,
                fontWeight: FontWeight.w900,
                letterSpacing: 2,
                color: M4Theme.premiumBlue,
              ),
            ),
          ],
        ),
      ),
      body: _loading
          ? const Center(
              child: CircularProgressIndicator(color: M4Theme.premiumBlue),
            )
          : _error != null
              ? _errorState(textPrimary, muted)
              : RefreshIndicator(
                  color: M4Theme.premiumBlue,
                  onRefresh: _load,
                  child: ListView(
                    padding: const EdgeInsets.all(20),
                    children: [
                      // ── Greeting ──────────────────────────────────────────
                      Text(
                        greeting,
                        style: GoogleFonts.montserrat(
                          fontSize: 22,
                          fontWeight: FontWeight.w900,
                          letterSpacing: -1,
                          height: 1,
                          color: textPrimary,
                        ),
                      ),
                      const SizedBox(height: 8),
                      Text(
                        'Connect with fellow investors and co-invest in proven deals.',
                        style: GoogleFonts.montserrat(
                          fontSize: 12,
                          fontWeight: FontWeight.w600,
                          color: muted,
                        ),
                      ),
                      const SizedBox(height: 24),

                      // ── Network Stats ────────────────────────────────────
                      Row(
                        mainAxisAlignment: MainAxisAlignment.spaceBetween,
                        children: [
                          Text(
                            'NETWORK STATS',
                            style: GoogleFonts.montserrat(
                              fontSize: 10,
                              fontWeight: FontWeight.w800,
                              letterSpacing: 4,
                              color: muted,
                            ),
                          ),
                          Container(
                            padding: const EdgeInsets.symmetric(
                                horizontal: 12, vertical: 5),
                            decoration: BoxDecoration(
                              color: M4Theme.premiumBlue.withValues(alpha: 0.2),
                              borderRadius: BorderRadius.circular(999),
                            ),
                            child: Text(
                              'LIVE',
                              style: GoogleFonts.montserrat(
                                fontSize: 8,
                                fontWeight: FontWeight.w900,
                                letterSpacing: 1.5,
                                color: M4Theme.premiumBlue,
                              ),
                            ),
                          ),
                        ],
                      ),
                      const SizedBox(height: 20),
                      ..._stats.map((s) =>
                          _statCard(s, isDark, textPrimary, muted, card, border)),

                      const SizedBox(height: 12),

                      // ── Active Co-Investors ──────────────────────────────
                      Text(
                        'ACTIVE CO-INVESTORS',
                        style: GoogleFonts.montserrat(
                          fontSize: 10,
                          fontWeight: FontWeight.w800,
                          letterSpacing: 4,
                          color: muted,
                        ),
                      ),
                      const SizedBox(height: 20),
                      if (_peers.isEmpty)
                        _emptyState(
                          'No co-investors in your network yet',
                          muted,
                        )
                      else
                        ..._peers.map((p) => _peerCard(
                            p, isDark, textPrimary, muted, card, border)),

                      const SizedBox(height: 12),

                      // ── Successful Deals ─────────────────────────────────
                      Text(
                        'SUCCESSFUL DEALS',
                        style: GoogleFonts.montserrat(
                          fontSize: 10,
                          fontWeight: FontWeight.w800,
                          letterSpacing: 4,
                          color: muted,
                        ),
                      ),
                      const SizedBox(height: 20),
                      if (_deals.isEmpty)
                        _emptyState('No deals to show right now', muted)
                      else
                        ..._deals.map((d) => _dealCard(
                            d, isDark, bg, textPrimary, muted, card, border)),

                      const SizedBox(height: 8),

                      // ── Concierge Panel ──────────────────────────────────
                      _concierge(isDark, bg, textPrimary),

                      const SizedBox(height: 40),
                    ],
                  ),
                ),
    );
  }

  // ── Error state ────────────────────────────────────────────────────────────
  Widget _errorState(Color textPrimary, Color muted) {
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(40),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(LucideIcons.wifiOff, size: 48, color: muted),
            const SizedBox(height: 16),
            Text(
              _error ?? 'Something went wrong',
              textAlign: TextAlign.center,
              style: GoogleFonts.montserrat(
                fontSize: 14,
                fontWeight: FontWeight.w700,
                color: textPrimary,
              ),
            ),
            const SizedBox(height: 20),
            OutlinedButton(
              onPressed: _load,
              style: OutlinedButton.styleFrom(
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(999),
                ),
              ),
              child: Text(
                'RETRY',
                style: GoogleFonts.montserrat(
                  fontSize: 11,
                  fontWeight: FontWeight.w900,
                  letterSpacing: 2,
                  color: M4Theme.premiumBlue,
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  // ── Empty state ──────────────────────────────────────────────────────────
  Widget _emptyState(String message, Color muted) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 40),
      child: Center(
        child: Text(
          message,
          style: GoogleFonts.montserrat(
            color: muted,
            fontWeight: FontWeight.w700,
          ),
        ),
      ),
    );
  }

  // ── Stat card ──────────────────────────────────────────────────────────────
  Widget _statCard(
    _Stat s,
    bool isDark,
    Color textPrimary,
    Color muted,
    Color card,
    Color border,
  ) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 16),
      child: Container(
        padding: const EdgeInsets.all(20),
        decoration: BoxDecoration(
          color: card,
          borderRadius: BorderRadius.circular(32),
          border: Border.all(color: border),
          boxShadow: [
            BoxShadow(
              color: Colors.black.withValues(alpha: 0.06),
              blurRadius: 24,
              offset: const Offset(0, 10),
            ),
          ],
        ),
        child: Row(
          children: [
            Container(
              width: 64,
              height: 64,
              decoration: BoxDecoration(
                color: isDark ? Colors.black : Colors.white,
                borderRadius: BorderRadius.circular(24),
                border: Border.all(color: border),
              ),
              alignment: Alignment.center,
              child: Icon(s.icon, size: 32, color: M4Theme.premiumBlue),
            ),
            const SizedBox(width: 20),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    s.label.toUpperCase(),
                    style: GoogleFonts.montserrat(
                      fontSize: 10,
                      fontWeight: FontWeight.w900,
                      letterSpacing: 2,
                      color: muted,
                    ),
                  ),
                  const SizedBox(height: 6),
                  Text(
                    s.value.toUpperCase(),
                    style: GoogleFonts.montserrat(
                      fontSize: 26,
                      fontWeight: FontWeight.w900,
                      height: 1,
                      letterSpacing: -1,
                      color: textPrimary,
                    ),
                  ),
                  const SizedBox(height: 4),
                  Text(
                    s.growth,
                    style: GoogleFonts.montserrat(
                      fontSize: 10,
                      fontWeight: FontWeight.w800,
                      color: Colors.green.shade500,
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

  // ── Peer (co-investor) card ──────────────────────────────────────────────
  Widget _peerCard(
    _Peer p,
    bool isDark,
    Color textPrimary,
    Color muted,
    Color card,
    Color border,
  ) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 16),
      child: Container(
        padding: const EdgeInsets.all(20),
        decoration: BoxDecoration(
          color: card,
          borderRadius: BorderRadius.circular(32),
          border: Border.all(color: border),
          boxShadow: [
            BoxShadow(
              color: Colors.black.withValues(alpha: 0.06),
              blurRadius: 24,
              offset: const Offset(0, 10),
            ),
          ],
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                // Avatar with gold ring (elite member).
                Container(
                  padding: const EdgeInsets.all(2),
                  decoration: BoxDecoration(
                    shape: BoxShape.circle,
                    border: Border.all(color: _gold, width: 2),
                  ),
                  child: ClipOval(
                    child: SizedBox(
                      width: 56,
                      height: 56,
                      child: CachedNetworkImage(
                        imageUrl:
                            ref.read(apiClientProvider).resolveUrl(p.avatar),
                        fit: BoxFit.cover,
                        placeholder: (_, __) => Container(
                          color: (isDark ? Colors.white : Colors.black)
                              .withValues(alpha: 0.06),
                        ),
                        errorWidget: (_, __, ___) => Container(
                          color: (isDark ? Colors.white : Colors.black)
                              .withValues(alpha: 0.06),
                          alignment: Alignment.center,
                          child: Icon(LucideIcons.user, color: muted, size: 24),
                        ),
                      ),
                    ),
                  ),
                ),
                const SizedBox(width: 16),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        p.name,
                        style: GoogleFonts.montserrat(
                          fontSize: 16,
                          fontWeight: FontWeight.w900,
                          letterSpacing: -0.5,
                          color: textPrimary,
                        ),
                      ),
                      const SizedBox(height: 4),
                      Row(
                        children: [
                          Icon(LucideIcons.mapPin, size: 13, color: muted),
                          const SizedBox(width: 4),
                          Flexible(
                            child: Text(
                              p.location,
                              style: GoogleFonts.montserrat(
                                fontSize: 11,
                                fontWeight: FontWeight.w700,
                                color: muted,
                              ),
                            ),
                          ),
                        ],
                      ),
                    ],
                  ),
                ),
                Column(
                  crossAxisAlignment: CrossAxisAlignment.end,
                  children: [
                    Text(
                      'PORTFOLIO',
                      style: GoogleFonts.montserrat(
                        fontSize: 8,
                        fontWeight: FontWeight.w900,
                        letterSpacing: 1.5,
                        color: muted,
                      ),
                    ),
                    const SizedBox(height: 2),
                    Text(
                      p.portfolio,
                      style: GoogleFonts.montserrat(
                        fontSize: 16,
                        fontWeight: FontWeight.w900,
                        letterSpacing: -0.5,
                        color: M4Theme.premiumBlue,
                      ),
                    ),
                  ],
                ),
              ],
            ),
            const SizedBox(height: 16),
            Wrap(
              spacing: 8,
              runSpacing: 8,
              children: p.interests
                  .map((tag) => Container(
                        padding: const EdgeInsets.symmetric(
                            horizontal: 12, vertical: 6),
                        decoration: BoxDecoration(
                          color: (isDark ? Colors.white : Colors.black)
                              .withValues(alpha: 0.04),
                          borderRadius: BorderRadius.circular(999),
                          border: Border.all(color: border),
                        ),
                        child: Text(
                          tag.toUpperCase(),
                          style: GoogleFonts.montserrat(
                            fontSize: 9,
                            fontWeight: FontWeight.w900,
                            letterSpacing: 1,
                            color: textPrimary,
                          ),
                        ),
                      ))
                  .toList(),
            ),
            const SizedBox(height: 16),
            SizedBox(
              width: double.infinity,
              height: 44,
              child: OutlinedButton.icon(
                onPressed: () {
                  ScaffoldMessenger.of(context).showSnackBar(
                    SnackBar(
                      content: Text('Connection request sent to ${p.name} — demo'),
                    ),
                  );
                },
                icon: const Icon(LucideIcons.userPlus,
                    size: 16, color: M4Theme.premiumBlue),
                style: OutlinedButton.styleFrom(
                  side: BorderSide(color: border),
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(999),
                  ),
                ),
                label: Text(
                  'CONNECT',
                  style: GoogleFonts.montserrat(
                    fontSize: 10,
                    fontWeight: FontWeight.w900,
                    letterSpacing: 2,
                    color: M4Theme.premiumBlue,
                  ),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  // ── Successful deal card ───────────────────────────────────────────────────
  Widget _dealCard(
    _Deal d,
    bool isDark,
    Color bg,
    Color textPrimary,
    Color muted,
    Color card,
    Color border,
  ) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 20),
      child: Container(
        decoration: BoxDecoration(
          color: card,
          borderRadius: BorderRadius.circular(40),
          border: Border.all(color: border),
          boxShadow: [
            BoxShadow(
              color: Colors.black.withValues(alpha: 0.08),
              blurRadius: 30,
              offset: const Offset(0, 14),
            ),
          ],
        ),
        child: ClipRRect(
          borderRadius: BorderRadius.circular(40),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              SizedBox(
                height: 180,
                child: Stack(
                  fit: StackFit.expand,
                  children: [
                    CachedNetworkImage(
                      imageUrl: ref.read(apiClientProvider).resolveUrl(d.image),
                      fit: BoxFit.cover,
                      placeholder: (_, __) => Container(
                        color: (isDark ? Colors.white : Colors.black)
                            .withValues(alpha: 0.06),
                      ),
                      errorWidget: (_, __, ___) => Container(
                        color: (isDark ? Colors.white : Colors.black)
                            .withValues(alpha: 0.06),
                        alignment: Alignment.center,
                        child: Icon(LucideIcons.image, color: muted),
                      ),
                    ),
                    DecoratedBox(
                      decoration: BoxDecoration(
                        gradient: LinearGradient(
                          begin: Alignment.bottomCenter,
                          end: Alignment.topCenter,
                          colors: [bg, bg.withValues(alpha: 0.0)],
                        ),
                      ),
                    ),
                    Positioned(
                      top: 16,
                      right: 16,
                      child: Container(
                        padding: const EdgeInsets.symmetric(
                            horizontal: 14, vertical: 7),
                        decoration: BoxDecoration(
                          color: _gold,
                          borderRadius: BorderRadius.circular(999),
                        ),
                        child: Text(
                          d.roi.toUpperCase(),
                          style: GoogleFonts.montserrat(
                            fontSize: 10,
                            fontWeight: FontWeight.w900,
                            letterSpacing: 1.5,
                            color: Colors.black,
                          ),
                        ),
                      ),
                    ),
                  ],
                ),
              ),
              Padding(
                padding: const EdgeInsets.all(24),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      d.title.toUpperCase(),
                      style: GoogleFonts.montserrat(
                        fontSize: 18,
                        fontWeight: FontWeight.w900,
                        letterSpacing: -0.5,
                        height: 1.1,
                        color: textPrimary,
                      ),
                    ),
                    const SizedBox(height: 8),
                    Row(
                      children: [
                        const Icon(LucideIcons.users,
                            size: 14, color: M4Theme.premiumBlue),
                        const SizedBox(width: 8),
                        Flexible(
                          child: Text(
                            d.syndicate.toUpperCase(),
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
                    const SizedBox(height: 16),
                    Divider(height: 1, color: border),
                    const SizedBox(height: 16),
                    Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      crossAxisAlignment: CrossAxisAlignment.end,
                      children: [
                        Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(
                              'TICKET CLOSED',
                              style: GoogleFonts.montserrat(
                                fontSize: 9,
                                fontWeight: FontWeight.w900,
                                letterSpacing: 2,
                                color: muted,
                              ),
                            ),
                            const SizedBox(height: 4),
                            Text(
                              d.ticket.toUpperCase(),
                              style: GoogleFonts.montserrat(
                                fontSize: 18,
                                fontWeight: FontWeight.w900,
                                letterSpacing: -0.5,
                                height: 1,
                                color: textPrimary,
                              ),
                            ),
                          ],
                        ),
                        Row(
                          children: [
                            Icon(LucideIcons.checkCircle,
                                size: 16, color: Colors.green.shade500),
                            const SizedBox(width: 6),
                            Text(
                              'FUNDED',
                              style: GoogleFonts.montserrat(
                                fontSize: 10,
                                fontWeight: FontWeight.w900,
                                letterSpacing: 2,
                                color: Colors.green.shade500,
                              ),
                            ),
                          ],
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

  // ── Concierge panel (inverted surface) ─────────────────────────────────────
  Widget _concierge(bool isDark, Color bg, Color textPrimary) {
    final panelBg = textPrimary;
    final onPanel = bg;
    return Container(
      decoration: BoxDecoration(
        color: panelBg,
        borderRadius: BorderRadius.circular(32),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.2),
            blurRadius: 30,
            offset: const Offset(0, 14),
          ),
        ],
      ),
      child: ClipRRect(
        borderRadius: BorderRadius.circular(32),
        child: Stack(
          children: [
            Positioned.fill(
              child: DecoratedBox(
                decoration: BoxDecoration(
                  gradient: LinearGradient(
                    begin: Alignment.bottomLeft,
                    end: Alignment.topRight,
                    colors: [
                      _gold.withValues(alpha: 0.18),
                      _gold.withValues(alpha: 0.0),
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
                        width: 64,
                        height: 64,
                        decoration: BoxDecoration(
                          color: onPanel,
                          shape: BoxShape.circle,
                          border: Border.all(
                              color: onPanel.withValues(alpha: 0.2)),
                        ),
                        alignment: Alignment.center,
                        child: const Icon(LucideIcons.shieldCheck,
                            size: 32, color: M4Theme.premiumBlue),
                      ),
                      const SizedBox(width: 20),
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(
                              'RELATIONSHIP DESK',
                              style: GoogleFonts.montserrat(
                                fontSize: 18,
                                fontWeight: FontWeight.w900,
                                letterSpacing: -0.5,
                                height: 1,
                                color: onPanel,
                              ),
                            ),
                            const SizedBox(height: 6),
                            Text(
                              'CURATED INTRODUCTIONS',
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
                  const SizedBox(height: 20),
                  SizedBox(
                    width: double.infinity,
                    height: 54,
                    child: OutlinedButton(
                      onPressed: () {
                        ScaffoldMessenger.of(context).showSnackBar(
                          const SnackBar(
                            content: Text('Requesting an introduction — demo'),
                          ),
                        );
                      },
                      style: OutlinedButton.styleFrom(
                        backgroundColor: onPanel.withValues(alpha: 0.1),
                        side: BorderSide(color: onPanel.withValues(alpha: 0.2)),
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(999),
                        ),
                      ),
                      child: Text(
                        'REQUEST AN INTRODUCTION',
                        style: GoogleFonts.montserrat(
                          fontSize: 10,
                          fontWeight: FontWeight.w900,
                          letterSpacing: 2,
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

class _Stat {
  final String label;
  final String value;
  final String growth;
  final IconData icon;
  const _Stat(this.label, this.value, this.growth, this.icon);
}

class _Peer {
  final String name;
  final String location;
  final String portfolio;
  final List<String> interests;
  final String avatar;
  const _Peer(
    this.name,
    this.location,
    this.portfolio,
    this.interests,
    this.avatar,
  );
}

class _Deal {
  final String title;
  final String syndicate;
  final String ticket;
  final String roi;
  final String image;
  const _Deal(
    this.title,
    this.syndicate,
    this.ticket,
    this.roi,
    this.image,
  );
}
