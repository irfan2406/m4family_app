import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:lucide_icons/lucide_icons.dart';
import 'package:m4_mobile/core/utils/support_handlers.dart';
import 'package:m4_mobile/presentation/providers/auth_provider.dart';

/// Web `/investor/elite/cp-connect` — institutional CP / partner network from the
/// investor perspective: active partners, payouts, lead pipeline stats and a
/// Verified Node Matrix of partner cards (expert, region, rating, active projects).
/// Parity build: premium glass cards, search, Accelerator Protocol benefits.
class InvestorEliteCpConnectScreen extends ConsumerStatefulWidget {
  const InvestorEliteCpConnectScreen({super.key});

  @override
  ConsumerState<InvestorEliteCpConnectScreen> createState() =>
      _InvestorEliteCpConnectScreenState();
}

class _InvestorEliteCpConnectScreenState
    extends ConsumerState<InvestorEliteCpConnectScreen> {
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
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final muted = scheme.onSurface.withValues(alpha: 0.5);
    final card = scheme.surfaceContainerHighest.withValues(alpha: 0.4);
    final border = scheme.outlineVariant.withValues(alpha: 0.3);
    final filtered = _filtered;

    return Scaffold(
      backgroundColor: Theme.of(context).scaffoldBackgroundColor,
      appBar: AppBar(
        leading: IconButton(
          icon: Icon(LucideIcons.arrowLeft, color: scheme.onSurface),
          onPressed: () =>
              context.canPop() ? context.pop() : context.go('/investor/home'),
        ),
        title: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              'Partners Portal',
              style: GoogleFonts.montserrat(
                  fontWeight: FontWeight.w800,
                  fontSize: 16,
                  color: scheme.onSurface),
            ),
            Text(
              'INSTITUTIONAL CP NETWORK',
              style: GoogleFonts.montserrat(
                fontSize: 8,
                fontWeight: FontWeight.w800,
                letterSpacing: 2,
                color: scheme.primary,
              ),
            ),
          ],
        ),
      ),
      body: Stack(
        children: [
          // ── Background gradient overlay (top 40% of viewport) ──
          Positioned(
            top: 0,
            left: 0,
            right: 0,
            height: MediaQuery.of(context).size.height * 0.4,
            child: IgnorePointer(
              child: DecoratedBox(
                decoration: BoxDecoration(
                  gradient: LinearGradient(
                    begin: Alignment.topCenter,
                    end: Alignment.bottomCenter,
                    colors: [
                      scheme.primary.withValues(alpha: 0.03),
                      Colors.transparent,
                    ],
                  ),
                ),
              ),
            ),
          ),

          // ── Content ──
          ListView(
            padding: const EdgeInsets.fromLTRB(20, 16, 20, 32),
            children: [
              // Search input
              _buildSearch(scheme, card, border),
              const SizedBox(height: 24),

              // Dashboard stats
              ..._stats.map((s) => Padding(
                    padding: const EdgeInsets.only(bottom: 12),
                    child: _StatCard(
                        stat: s,
                        card: card,
                        border: border,
                        scheme: scheme,
                        muted: muted),
                  )),

              const SizedBox(height: 12),

              // Verified Node Matrix header + Top Tier badge
              Row(
                children: [
                  Icon(LucideIcons.users, size: 14, color: scheme.primary),
                  const SizedBox(width: 6),
                  Expanded(
                    child: Text(
                      'VERIFIED NODE MATRIX',
                      style: GoogleFonts.montserrat(
                        fontSize: 10,
                        fontWeight: FontWeight.w800,
                        letterSpacing: 2,
                        color: scheme.onSurface.withValues(alpha: 0.6),
                      ),
                    ),
                  ),
                  Container(
                    padding:
                        const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                    decoration: BoxDecoration(
                      color: scheme.primary.withValues(alpha: 0.2),
                      borderRadius: BorderRadius.circular(999),
                    ),
                    child: Text(
                      'TOP TIER',
                      style: GoogleFonts.montserrat(
                        fontSize: 8,
                        fontWeight: FontWeight.w800,
                        letterSpacing: 1.5,
                        color: scheme.primary,
                      ),
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 16),

              // Partner cards
              ...filtered.map((p) => _PartnerCard(
                    partner: p,
                    imageUrl: ref.read(apiClientProvider).resolveUrl(p.image),
                    card: card,
                    border: border,
                    scheme: scheme,
                    onMessage: _launchWa,
                    onCall: _launchTel,
                  )),

              if (filtered.isEmpty)
                Padding(
                  padding: const EdgeInsets.symmetric(vertical: 48),
                  child: Center(
                    child: Column(
                      children: [
                        Icon(LucideIcons.searchX,
                            size: 36,
                            color: scheme.onSurface.withValues(alpha: 0.25)),
                        const SizedBox(height: 12),
                        Text(
                          'NO MATCHES FOUND',
                          style: GoogleFonts.montserrat(
                            fontSize: 10,
                            fontWeight: FontWeight.w800,
                            letterSpacing: 2,
                            color: scheme.onSurface.withValues(alpha: 0.3),
                          ),
                        ),
                      ],
                    ),
                  ),
                ),

              const SizedBox(height: 20),

              // Accelerator Protocol card
              _AcceleratorCard(scheme: scheme, isDark: isDark),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildSearch(ColorScheme scheme, Color card, Color border) {
    return Container(
      height: 58,
      decoration: BoxDecoration(
        color: card,
        borderRadius: BorderRadius.circular(20),
        border: Border.all(color: border),
      ),
      child: TextField(
        controller: _search,
        style: GoogleFonts.montserrat(
          fontSize: 11,
          fontWeight: FontWeight.w800,
          letterSpacing: 0.5,
          color: scheme.onSurface,
        ),
        textCapitalization: TextCapitalization.characters,
        decoration: InputDecoration(
          hintText: 'SCAN VERIFIED INSTITUTIONAL PARTNERS…',
          hintStyle: GoogleFonts.montserrat(
            fontSize: 10,
            fontWeight: FontWeight.w800,
            letterSpacing: 0.5,
            color: scheme.onSurface.withValues(alpha: 0.35),
          ),
          prefixIcon: Icon(LucideIcons.search, size: 20, color: scheme.primary),
          border: InputBorder.none,
          contentPadding:
              const EdgeInsets.symmetric(horizontal: 8, vertical: 18),
        ),
        onChanged: (v) => setState(() => _q = v.trim().toLowerCase()),
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
  const _Partner(this.name, this.expert, this.region, this.rating,
      this.activeProjects, this.image);
}

// ━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━
// STAT CARD — premium glass row with icon circle + chevron
// ━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━
class _StatCard extends StatefulWidget {
  final _Stat stat;
  final Color card;
  final Color border;
  final ColorScheme scheme;
  final Color muted;
  const _StatCard({
    required this.stat,
    required this.card,
    required this.border,
    required this.scheme,
    required this.muted,
  });

  @override
  State<_StatCard> createState() => _StatCardState();
}

class _StatCardState extends State<_StatCard> {
  bool _pressed = false;

  @override
  Widget build(BuildContext context) {
    final scheme = widget.scheme;
    return GestureDetector(
      onTapDown: (_) => setState(() => _pressed = true),
      onTapUp: (_) => setState(() => _pressed = false),
      onTapCancel: () => setState(() => _pressed = false),
      child: AnimatedScale(
        scale: _pressed ? 0.98 : 1.0,
        duration: const Duration(milliseconds: 120),
        child: Container(
          padding: const EdgeInsets.all(16),
          decoration: BoxDecoration(
            color: _pressed
                ? scheme.surfaceContainerHighest.withValues(alpha: 0.6)
                : widget.card,
            borderRadius: BorderRadius.circular(24),
            border: Border.all(color: widget.border),
          ),
          child: Row(
            children: [
              // Icon circle
              Container(
                width: 48,
                height: 48,
                decoration: BoxDecoration(
                  color: scheme.surface,
                  borderRadius: BorderRadius.circular(15),
                  border:
                      Border.all(color: scheme.primary.withValues(alpha: 0.25)),
                ),
                child: Icon(widget.stat.icon, size: 22, color: scheme.primary),
              ),
              const SizedBox(width: 14),
              // Label + value
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      widget.stat.label.toUpperCase(),
                      style: GoogleFonts.montserrat(
                        fontSize: 9,
                        fontWeight: FontWeight.w800,
                        letterSpacing: 1.5,
                        color: widget.muted,
                      ),
                    ),
                    const SizedBox(height: 4),
                    Text(
                      widget.stat.value.toUpperCase(),
                      style: GoogleFonts.montserrat(
                        fontSize: 18,
                        fontWeight: FontWeight.w800,
                        color: scheme.onSurface,
                        height: 1,
                      ),
                    ),
                  ],
                ),
              ),
              // Chevron button
              Container(
                width: 40,
                height: 40,
                decoration: BoxDecoration(
                  color: scheme.surface,
                  shape: BoxShape.circle,
                  border: Border.all(color: widget.border),
                ),
                child: Icon(LucideIcons.chevronRight,
                    size: 18, color: widget.muted),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

// ━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━
// PARTNER CARD — premium glass card with image, rating, actions
// ━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━
class _PartnerCard extends StatefulWidget {
  final _Partner partner;
  final String imageUrl;
  final Color card;
  final Color border;
  final ColorScheme scheme;
  final VoidCallback onMessage;
  final VoidCallback onCall;

  const _PartnerCard({
    required this.partner,
    required this.imageUrl,
    required this.card,
    required this.border,
    required this.scheme,
    required this.onMessage,
    required this.onCall,
  });

  @override
  State<_PartnerCard> createState() => _PartnerCardState();
}

class _PartnerCardState extends State<_PartnerCard> {
  bool _pressed = false;

  @override
  Widget build(BuildContext context) {
    final p = widget.partner;
    final scheme = widget.scheme;
    final muted = scheme.onSurface.withValues(alpha: 0.6);

    return AnimatedScale(
      scale: _pressed ? 0.99 : 1.0,
      duration: const Duration(milliseconds: 120),
      child: Container(
        margin: const EdgeInsets.only(bottom: 14),
        padding: const EdgeInsets.all(18),
        decoration: BoxDecoration(
          color: _pressed
              ? scheme.surfaceContainerHighest.withValues(alpha: 0.6)
              : widget.card,
          borderRadius: BorderRadius.circular(24),
          border: Border.all(color: widget.border),
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Header row
            Row(
              children: [
                GestureDetector(
                  onTapDown: (_) => setState(() => _pressed = true),
                  onTapUp: (_) => setState(() => _pressed = false),
                  onTapCancel: () => setState(() => _pressed = false),
                  child: AnimatedScale(
                    scale: _pressed ? 1.05 : 1.0,
                    duration: const Duration(milliseconds: 150),
                    child: Container(
                      decoration: BoxDecoration(
                        borderRadius: BorderRadius.circular(16),
                        border: Border.all(color: scheme.surface, width: 2),
                        boxShadow: [
                          BoxShadow(
                            color: Colors.black.withValues(alpha: 0.15),
                            blurRadius: 12,
                            offset: const Offset(0, 6),
                          ),
                        ],
                      ),
                      child: ClipRRect(
                        borderRadius: BorderRadius.circular(14),
                        child: Image.network(
                          widget.imageUrl,
                          width: 64,
                          height: 64,
                          fit: BoxFit.cover,
                          errorBuilder: (_, __, ___) => Container(
                            width: 64,
                            height: 64,
                            color: scheme.surfaceContainerHighest,
                            child: Icon(LucideIcons.user, color: muted),
                          ),
                        ),
                      ),
                    ),
                  ),
                ),
                const SizedBox(width: 14),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        p.name.toUpperCase(),
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                        style: GoogleFonts.montserrat(
                          fontSize: 15,
                          fontWeight: FontWeight.w800,
                          color: scheme.onSurface,
                          height: 1.05,
                        ),
                      ),
                      const SizedBox(height: 4),
                      Text(
                        '${p.expert} • ${p.region}'.toUpperCase(),
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                        style: GoogleFonts.montserrat(
                          fontSize: 10,
                          fontWeight: FontWeight.w700,
                          color: muted,
                        ),
                      ),
                    ],
                  ),
                ),
                const SizedBox(width: 8),
                Column(
                  crossAxisAlignment: CrossAxisAlignment.end,
                  children: [
                    Row(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        Icon(LucideIcons.star, size: 14, color: scheme.primary),
                        const SizedBox(width: 3),
                        Text(
                          p.rating,
                          style: GoogleFonts.montserrat(
                            fontSize: 12,
                            fontWeight: FontWeight.w800,
                            color: scheme.primary,
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 2),
                    Text(
                      '${p.activeProjects} OPS',
                      style: GoogleFonts.montserrat(
                        fontSize: 9,
                        fontWeight: FontWeight.w700,
                        color: scheme.onSurface.withValues(alpha: 0.4),
                      ),
                    ),
                  ],
                ),
              ],
            ),
            const SizedBox(height: 16),

            // Button row
            Row(
              children: [
                Expanded(
                  child: SizedBox(
                    height: 48,
                    child: OutlinedButton.icon(
                      onPressed: widget.onMessage,
                      icon: Icon(LucideIcons.messageCircle,
                          size: 16, color: scheme.primary),
                      label: Text(
                        'TRANSMIT',
                        style: GoogleFonts.montserrat(
                          fontSize: 9,
                          fontWeight: FontWeight.w800,
                          letterSpacing: 1.5,
                          color: scheme.onSurface,
                        ),
                      ),
                      style: OutlinedButton.styleFrom(
                        backgroundColor: scheme.surface,
                        side: BorderSide(
                            color:
                                scheme.outlineVariant.withValues(alpha: 0.5)),
                        shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(20)),
                      ),
                    ),
                  ),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: SizedBox(
                    height: 48,
                    child: FilledButton.icon(
                      onPressed: widget.onCall,
                      icon: Icon(LucideIcons.phone,
                          size: 16, color: scheme.surface),
                      label: Text(
                        'LINK-UP',
                        style: GoogleFonts.montserrat(
                          fontSize: 9,
                          fontWeight: FontWeight.w800,
                          letterSpacing: 1.5,
                          color: scheme.surface,
                        ),
                      ),
                      style: FilledButton.styleFrom(
                        backgroundColor: scheme.onSurface,
                        foregroundColor: scheme.surface,
                        elevation: 3,
                        shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(20)),
                      ),
                    ),
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

// ━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━
// ACCELERATOR PROTOCOL — dark membership-benefits card
// ━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━
class _AcceleratorCard extends StatelessWidget {
  final ColorScheme scheme;
  final bool isDark;
  const _AcceleratorCard({required this.scheme, required this.isDark});

  @override
  Widget build(BuildContext context) {
    return Container(
      decoration: BoxDecoration(
        color: scheme.onSurface,
        borderRadius: BorderRadius.circular(24),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.25),
            blurRadius: 24,
            offset: const Offset(0, 12),
          ),
        ],
      ),
      child: ClipRRect(
        borderRadius: BorderRadius.circular(24),
        child: Stack(
          children: [
            // Subtle gradient overlay (top-right primary tint)
            Positioned.fill(
              child: IgnorePointer(
                child: DecoratedBox(
                  decoration: BoxDecoration(
                    gradient: LinearGradient(
                      begin: Alignment.bottomLeft,
                      end: Alignment.topRight,
                      colors: [
                        Colors.transparent,
                        scheme.primary.withValues(alpha: 0.1),
                      ],
                    ),
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
                        width: 48,
                        height: 48,
                        decoration: BoxDecoration(
                          color: scheme.surface,
                          borderRadius: BorderRadius.circular(12),
                        ),
                        child: Icon(LucideIcons.zap,
                            size: 24, color: scheme.primary),
                      ),
                      const SizedBox(width: 14),
                      Expanded(
                        child: Text(
                          'ACCELERATOR PROTOCOL',
                          style: GoogleFonts.montserrat(
                            fontSize: 18,
                            fontWeight: FontWeight.w800,
                            letterSpacing: -0.5,
                            color: scheme.surface,
                            height: 1,
                          ),
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 14),
                  Text(
                    'Maximize institutional yield with 1.5x commission vectors on all '
                    'Prestige-tier residential clusters in core markets.',
                    style: GoogleFonts.montserrat(
                      fontSize: 10,
                      fontWeight: FontWeight.w500,
                      height: 1.6,
                      color: scheme.surface.withValues(alpha: 0.7),
                    ),
                  ),
                  const SizedBox(height: 20),
                  SizedBox(
                    width: double.infinity,
                    height: 52,
                    child: FilledButton(
                      onPressed: () {
                        ScaffoldMessenger.of(context).showSnackBar(
                          const SnackBar(
                              content: Text('Yield structures coming soon.')),
                        );
                      },
                      style: FilledButton.styleFrom(
                        backgroundColor: scheme.surface,
                        foregroundColor: scheme.onSurface,
                        elevation: 3,
                        shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(20)),
                      ),
                      child: Text(
                        'VIEW YIELD STRUCTURES',
                        style: GoogleFonts.montserrat(
                          fontSize: 10,
                          fontWeight: FontWeight.w800,
                          letterSpacing: 2,
                          color: scheme.onSurface,
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
