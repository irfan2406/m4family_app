import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:lucide_icons/lucide_icons.dart';

/// Web `/cp/elite/residential-connect` — institutional concierge / residence
/// suite (curated demo data). Parity build: premium glass cards, property
/// status, institutional services grid, update stream, resident-link CTA.
///
/// STUB — static layout with demo data. Ready for live API integration
/// (residential assets, concierge services, scheduled events) when endpoints
/// become available.
class CpResidentialConnectScreen extends ConsumerStatefulWidget {
  const CpResidentialConnectScreen({super.key});

  @override
  ConsumerState<CpResidentialConnectScreen> createState() =>
      _CpResidentialConnectScreenState();
}

class _CpResidentialConnectScreenState
    extends ConsumerState<CpResidentialConnectScreen> {
  static const _services = [
    _Service('Private Security', 'Active', LucideIcons.shield),
    _Service('Housekeeping', 'Daily 9 AM', LucideIcons.coffee),
    _Service('Valet Parking', '24/7', LucideIcons.key),
    _Service('Building Maint.', 'Scheduled', LucideIcons.hammer),
  ];

  static const _alerts = [
    _Alert('Monthly Maintenance Due', 'Due in 2 days', true),
    _Alert('Community Yoga Session', 'Tomorrow, 7 AM', false),
  ];

  @override
  Widget build(BuildContext context) {
    final scheme = Theme.of(context).colorScheme;
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final muted = scheme.onSurface.withValues(alpha: 0.5);
    final card = scheme.surfaceContainerHighest.withValues(alpha: 0.4);
    final border = scheme.outlineVariant.withValues(alpha: 0.3);

    return Scaffold(
      backgroundColor: Theme.of(context).scaffoldBackgroundColor,
      appBar: AppBar(
        leading: IconButton(
          icon: Icon(LucideIcons.arrowLeft, color: scheme.onSurface),
          onPressed: () =>
              context.canPop() ? context.pop() : context.go('/cp/dashboard'),
        ),
        title: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              'Residence Suite',
              style: GoogleFonts.montserrat(
                fontWeight: FontWeight.w800,
                fontSize: 16,
                color: scheme.onSurface,
              ),
            ),
            Text(
              'INSTITUTIONAL CONCIERGE',
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
              // Property status
              _PropertyCard(
                  card: card, border: border, scheme: scheme, muted: muted),
              const SizedBox(height: 28),

              // Institutional services
              _SectionHeader(label: 'INSTITUTIONAL SERVICES', muted: muted),
              const SizedBox(height: 16),
              GridView.count(
                crossAxisCount: 2,
                shrinkWrap: true,
                physics: const NeverScrollableScrollPhysics(),
                mainAxisSpacing: 16,
                crossAxisSpacing: 16,
                childAspectRatio: 1.05,
                children: _services
                    .map((s) => _ServiceCard(
                          service: s,
                          card: card,
                          border: border,
                          scheme: scheme,
                          muted: muted,
                        ))
                    .toList(),
              ),
              const SizedBox(height: 28),

              // Update stream
              _SectionHeader(label: 'UPDATE STREAM', muted: muted),
              const SizedBox(height: 16),
              ..._alerts.map((a) => Padding(
                    padding: const EdgeInsets.only(bottom: 12),
                    child: _AlertItem(
                      alert: a,
                      card: card,
                      border: border,
                      scheme: scheme,
                      muted: muted,
                    ),
                  )),
              const SizedBox(height: 16),

              // Community chat CTA
              _CommunityChatCard(scheme: scheme, isDark: isDark),
            ],
          ),
        ],
      ),
    );
  }
}

class _Service {
  final String name;
  final String status;
  final IconData icon;
  const _Service(this.name, this.status, this.icon);
}

class _Alert {
  final String title;
  final String date;
  final bool urgent;
  const _Alert(this.title, this.date, this.urgent);
}

// ━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━
// SECTION HEADER — uppercase letter-spaced label
// ━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━
class _SectionHeader extends StatelessWidget {
  final String label;
  final Color muted;
  const _SectionHeader({required this.label, required this.muted});

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 4),
      child: Text(
        label,
        style: GoogleFonts.montserrat(
          fontSize: 10,
          fontWeight: FontWeight.w800,
          letterSpacing: 3,
          color: muted,
        ),
      ),
    );
  }
}

// ━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━
// PROPERTY CARD — premium glass: icon, name/address, verified, progress
// ━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━
class _PropertyCard extends StatefulWidget {
  final Color card;
  final Color border;
  final ColorScheme scheme;
  final Color muted;
  const _PropertyCard({
    required this.card,
    required this.border,
    required this.scheme,
    required this.muted,
  });

  @override
  State<_PropertyCard> createState() => _PropertyCardState();
}

class _PropertyCardState extends State<_PropertyCard> {
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
          padding: const EdgeInsets.all(20),
          decoration: BoxDecoration(
            color: _pressed
                ? scheme.surfaceContainerHighest.withValues(alpha: 0.6)
                : widget.card,
            borderRadius: BorderRadius.circular(24),
            border: Border.all(color: widget.border),
            boxShadow: [
              BoxShadow(
                color: Colors.black.withValues(alpha: 0.08),
                blurRadius: 18,
                offset: const Offset(0, 8),
              ),
            ],
          ),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                children: [
                  // Icon circle (foreground bg)
                  Container(
                    width: 56,
                    height: 56,
                    decoration: BoxDecoration(
                      color: scheme.onSurface,
                      borderRadius: BorderRadius.circular(18),
                    ),
                    child: Icon(LucideIcons.home, size: 28, color: scheme.surface),
                  ),
                  const SizedBox(width: 14),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          'CROWN RESIDENCES',
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                          style: GoogleFonts.montserrat(
                            fontSize: 18,
                            fontWeight: FontWeight.w800,
                            color: scheme.onSurface,
                            height: 1.05,
                          ),
                        ),
                        const SizedBox(height: 4),
                        Text(
                          'TOWER A • SUITE 4802',
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                          style: GoogleFonts.montserrat(
                            fontSize: 10,
                            fontWeight: FontWeight.w800,
                            letterSpacing: 1.2,
                            color: widget.muted,
                          ),
                        ),
                      ],
                    ),
                  ),
                  const SizedBox(width: 8),
                  // Verified badge
                  Container(
                    padding:
                        const EdgeInsets.symmetric(horizontal: 10, vertical: 5),
                    decoration: BoxDecoration(
                      color: scheme.primary,
                      borderRadius: BorderRadius.circular(999),
                    ),
                    child: Text(
                      'VERIFIED',
                      style: GoogleFonts.montserrat(
                        fontSize: 8,
                        fontWeight: FontWeight.w800,
                        letterSpacing: 1.5,
                        color: scheme.onPrimary,
                      ),
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 22),
              // Asset utilization label row
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Text(
                    'ASSET UTILIZATION',
                    style: GoogleFonts.montserrat(
                      fontSize: 10,
                      fontWeight: FontWeight.w800,
                      letterSpacing: 2,
                      color: widget.muted,
                    ),
                  ),
                  Text(
                    '85% ACTIVE',
                    style: GoogleFonts.montserrat(
                      fontSize: 10,
                      fontWeight: FontWeight.w800,
                      letterSpacing: 2,
                      color: scheme.onSurface,
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 12),
              // Progress bar
              ClipRRect(
                borderRadius: BorderRadius.circular(999),
                child: LinearProgressIndicator(
                  value: 0.85,
                  minHeight: 10,
                  backgroundColor:
                      scheme.surfaceContainerHighest.withValues(alpha: 0.6),
                  valueColor: AlwaysStoppedAnimation<Color>(scheme.primary),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

// ━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━
// SERVICE CARD — glass tile: icon circle + name + status
// ━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━
class _ServiceCard extends StatefulWidget {
  final _Service service;
  final Color card;
  final Color border;
  final ColorScheme scheme;
  final Color muted;
  const _ServiceCard({
    required this.service,
    required this.card,
    required this.border,
    required this.scheme,
    required this.muted,
  });

  @override
  State<_ServiceCard> createState() => _ServiceCardState();
}

class _ServiceCardState extends State<_ServiceCard> {
  bool _pressed = false;

  @override
  Widget build(BuildContext context) {
    final scheme = widget.scheme;
    return GestureDetector(
      onTapDown: (_) => setState(() => _pressed = true),
      onTapUp: (_) => setState(() => _pressed = false),
      onTapCancel: () => setState(() => _pressed = false),
      child: AnimatedScale(
        scale: _pressed ? 0.95 : 1.0,
        duration: const Duration(milliseconds: 120),
        child: Container(
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
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              // Icon circle (background border)
              Container(
                width: 48,
                height: 48,
                decoration: BoxDecoration(
                  color: scheme.surface,
                  borderRadius: BorderRadius.circular(15),
                  border: Border.all(color: widget.border),
                ),
                child: Icon(widget.service.icon, size: 24, color: scheme.primary),
              ),
              const SizedBox(height: 14),
              Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    widget.service.name.toUpperCase(),
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                    style: GoogleFonts.montserrat(
                      fontSize: 13,
                      fontWeight: FontWeight.w800,
                      color: scheme.onSurface,
                      height: 1.05,
                    ),
                  ),
                  const SizedBox(height: 4),
                  Text(
                    widget.service.status.toUpperCase(),
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                    style: GoogleFonts.montserrat(
                      fontSize: 9,
                      fontWeight: FontWeight.w800,
                      letterSpacing: 1.2,
                      color: widget.muted,
                      height: 1,
                    ),
                  ),
                ],
              ),
            ],
          ),
        ),
      ),
    );
  }
}

// ━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━
// ALERT ITEM — full-width glass row: icon + title/date + chevron
// ━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━
class _AlertItem extends StatefulWidget {
  final _Alert alert;
  final Color card;
  final Color border;
  final ColorScheme scheme;
  final Color muted;
  const _AlertItem({
    required this.alert,
    required this.card,
    required this.border,
    required this.scheme,
    required this.muted,
  });

  @override
  State<_AlertItem> createState() => _AlertItemState();
}

class _AlertItemState extends State<_AlertItem> {
  bool _pressed = false;

  @override
  Widget build(BuildContext context) {
    final scheme = widget.scheme;
    final urgent = widget.alert.urgent;
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
                width: 52,
                height: 52,
                decoration: BoxDecoration(
                  color: urgent
                      ? Colors.red.withValues(alpha: 0.1)
                      : scheme.surface,
                  shape: BoxShape.circle,
                  border: Border.all(color: widget.border),
                ),
                child: Icon(
                  urgent ? LucideIcons.bell : LucideIcons.calendar,
                  size: 22,
                  color: urgent ? Colors.red : scheme.onSurface,
                ),
              ),
              const SizedBox(width: 14),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      widget.alert.title.toUpperCase(),
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                      style: GoogleFonts.montserrat(
                        fontSize: 13,
                        fontWeight: FontWeight.w800,
                        color: scheme.onSurface,
                        height: 1.1,
                      ),
                    ),
                    const SizedBox(height: 4),
                    Text(
                      widget.alert.date.toUpperCase(),
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                      style: GoogleFonts.montserrat(
                        fontSize: 9,
                        fontWeight: FontWeight.w800,
                        letterSpacing: 1.2,
                        color: widget.muted,
                      ),
                    ),
                  ],
                ),
              ),
              const SizedBox(width: 8),
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
// COMMUNITY CHAT CARD — dark CTA card (resident link)
// ━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━
class _CommunityChatCard extends StatelessWidget {
  final ColorScheme scheme;
  final bool isDark;
  const _CommunityChatCard({required this.scheme, required this.isDark});

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
                        scheme.primary.withValues(alpha: 0.2),
                      ],
                    ),
                  ),
                ),
              ),
            ),
            Padding(
              padding: const EdgeInsets.all(22),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    children: [
                      // Icon box (background color)
                      Container(
                        width: 56,
                        height: 56,
                        decoration: BoxDecoration(
                          color: scheme.surface,
                          borderRadius: BorderRadius.circular(18),
                        ),
                        child: Icon(LucideIcons.messageSquare,
                            size: 28, color: scheme.primary),
                      ),
                      const SizedBox(width: 14),
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(
                              'GLOBAL LOUNGE',
                              style: GoogleFonts.montserrat(
                                fontSize: 10,
                                fontWeight: FontWeight.w800,
                                letterSpacing: 3,
                                color: scheme.surface.withValues(alpha: 0.6),
                                height: 1,
                              ),
                            ),
                            const SizedBox(height: 6),
                            Text(
                              'RESIDENT LINK',
                              style: GoogleFonts.montserrat(
                                fontSize: 18,
                                fontWeight: FontWeight.w800,
                                letterSpacing: -0.5,
                                color: scheme.surface,
                                height: 1,
                              ),
                            ),
                          ],
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 22),
                  SizedBox(
                    width: double.infinity,
                    height: 56,
                    child: FilledButton(
                      onPressed: () {
                        ScaffoldMessenger.of(context).showSnackBar(
                          const SnackBar(
                              content: Text('Secure link coming soon.')),
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
                        'INITIATE SECURE LINK',
                        style: GoogleFonts.montserrat(
                          fontSize: 11,
                          fontWeight: FontWeight.w800,
                          letterSpacing: 3,
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
