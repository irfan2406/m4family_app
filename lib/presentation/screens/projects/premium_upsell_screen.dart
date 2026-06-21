import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:lucide_icons/lucide_icons.dart';
import 'package:flutter_animate/flutter_animate.dart';
import 'package:m4_mobile/core/theme/app_theme.dart';

/// Premium membership upgrade promo screen.
///
/// Mirrors the web prototype at `app/(user)/projects/premium-upsell/page.tsx`.
/// Static content (no data fetching). The web page reads an optional
/// `?feature=vr` query param but currently hardcodes the "Immersive VR Tour"
/// feature title, so we accept an optional [featureTitle] for future parity.
class PremiumUpsellScreen extends ConsumerWidget {
  final String featureTitle;

  const PremiumUpsellScreen({
    super.key,
    this.featureTitle = 'Immersive VR Tour',
  });

  static const _gold = Color(0xFFFFD700);

  void _back(BuildContext context) {
    if (Navigator.of(context).canPop()) {
      Navigator.pop(context);
    }
  }

  void _handleUpgrade(BuildContext context) {
    // Mirrors web: router.push("/projects/premium-upsell/checkout").
    // Checkout flow is not yet built in the app; surface a placeholder.
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(
          'Checkout coming soon',
          style: GoogleFonts.montserrat(fontSize: 12, fontWeight: FontWeight.bold),
        ),
        backgroundColor: M4Theme.premiumBlue,
        behavior: SnackBarBehavior.floating,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
      ),
    );
  }

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final bg = isDark ? Colors.black : Colors.white;
    final textPrimary = isDark ? Colors.white : Colors.black;
    final muted = (isDark ? Colors.white : Colors.black).withValues(alpha: 0.5);
    const subtle = Color(0xFF666666);
    final card = isDark ? Colors.white.withValues(alpha: 0.03) : Colors.white;
    final border = isDark ? Colors.white.withValues(alpha: 0.08) : Colors.black.withValues(alpha: 0.06);
    final iconCircleBg = isDark ? Colors.white.withValues(alpha: 0.06) : Colors.black.withValues(alpha: 0.04);

    final benefits = <_Benefit>[
      const _Benefit(
        title: 'VR Virtual Tours',
        desc: 'Step inside with immersive walkthroughs',
        icon: LucideIcons.glasses,
      ),
      const _Benefit(
        title: 'Priority Booking',
        desc: 'Early access to premium units and floors',
        icon: LucideIcons.zap,
      ),
      const _Benefit(
        title: 'Concierge Support',
        desc: 'Dedicated account manager for your needs',
        icon: LucideIcons.shieldCheck,
      ),
    ];

    return Scaffold(
      backgroundColor: bg,
      body: SafeArea(
        child: SingleChildScrollView(
          physics: const BouncingScrollPhysics(),
          padding: const EdgeInsets.only(bottom: 40),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // Header: back button
              Padding(
                padding: const EdgeInsets.fromLTRB(24, 14, 24, 4),
                child: _CircleAction(
                  icon: LucideIcons.chevronLeft,
                  onTap: () => _back(context),
                ),
              ),
              const SizedBox(height: 24),

              Center(
                child: ConstrainedBox(
                  constraints: const BoxConstraints(maxWidth: 360),
                  child: Padding(
                    padding: const EdgeInsets.symmetric(horizontal: 24),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.stretch,
                      children: [
                        // Hero Section
                        Column(
                          children: [
                            Container(
                              padding: const EdgeInsets.all(14),
                              decoration: BoxDecoration(
                                color: card,
                                borderRadius: BorderRadius.circular(20),
                                border: Border.all(color: border),
                              ),
                              child: Icon(LucideIcons.glasses, size: 26, color: textPrimary),
                            )
                                .animate()
                                .scale(
                                  begin: const Offset(0.8, 0.8),
                                  end: const Offset(1, 1),
                                  duration: 400.ms,
                                  curve: Curves.easeOut,
                                )
                                .fadeIn(duration: 400.ms),
                            const SizedBox(height: 14),
                            Text(
                              'UNLOCK ${featureTitle.toUpperCase()}',
                              textAlign: TextAlign.center,
                              style: GoogleFonts.montserrat(
                                fontSize: 20,
                                fontWeight: FontWeight.bold,
                                color: textPrimary,
                                letterSpacing: 1.5,
                              ),
                            )
                                .animate()
                                .moveY(begin: 20, end: 0, duration: 400.ms, curve: Curves.easeOut)
                                .fadeIn(duration: 400.ms),
                            const SizedBox(height: 12),
                            Padding(
                              padding: const EdgeInsets.symmetric(horizontal: 20),
                              child: Text(
                                'EXPERIENCE YOUR FUTURE HOME LIKE NEVER BEFORE. EXCLUSIVE ACCESS FOR M4 ELITE MEMBERS ONLY.',
                                textAlign: TextAlign.center,
                                style: GoogleFonts.montserrat(
                                  fontSize: 11,
                                  fontWeight: FontWeight.bold,
                                  color: subtle,
                                  letterSpacing: 0.8,
                                  height: 1.6,
                                ),
                              )
                                  .animate()
                                  .moveY(begin: 20, end: 0, delay: 100.ms, duration: 400.ms, curve: Curves.easeOut)
                                  .fadeIn(delay: 100.ms, duration: 400.ms),
                            ),
                          ],
                        ),
                        const SizedBox(height: 48),

                        // Benefits Section
                        Text(
                          'ELITE MEMBERSHIP BENEFITS',
                          textAlign: TextAlign.center,
                          style: GoogleFonts.montserrat(
                            fontSize: 9,
                            fontWeight: FontWeight.bold,
                            color: muted,
                            letterSpacing: 1.8,
                          ),
                        ),
                        const SizedBox(height: 16),
                        ...List.generate(benefits.length, (i) {
                          final b = benefits[i];
                          return Padding(
                            padding: const EdgeInsets.only(bottom: 12),
                            child: Container(
                              padding: const EdgeInsets.all(14),
                              decoration: BoxDecoration(
                                color: card,
                                borderRadius: BorderRadius.circular(20),
                                border: Border.all(color: border),
                              ),
                              child: Row(
                                children: [
                                  Container(
                                    width: 36,
                                    height: 36,
                                    decoration: BoxDecoration(
                                      color: iconCircleBg,
                                      borderRadius: BorderRadius.circular(12),
                                    ),
                                    child: Icon(b.icon, size: 16, color: textPrimary),
                                  ),
                                  const SizedBox(width: 16),
                                  Expanded(
                                    child: Column(
                                      crossAxisAlignment: CrossAxisAlignment.start,
                                      children: [
                                        Text(
                                          b.title.toUpperCase(),
                                          style: GoogleFonts.montserrat(
                                            fontSize: 11,
                                            fontWeight: FontWeight.bold,
                                            color: textPrimary,
                                            letterSpacing: -0.2,
                                          ),
                                        ),
                                        const SizedBox(height: 2),
                                        Text(
                                          b.desc.toUpperCase(),
                                          style: GoogleFonts.montserrat(
                                            fontSize: 9,
                                            fontWeight: FontWeight.bold,
                                            color: subtle,
                                            letterSpacing: -0.4,
                                          ),
                                        ),
                                      ],
                                    ),
                                  ),
                                  const SizedBox(width: 12),
                                  Container(
                                    width: 20,
                                    height: 20,
                                    decoration: const BoxDecoration(
                                      color: _gold,
                                      shape: BoxShape.circle,
                                    ),
                                    child: const Icon(LucideIcons.check, size: 12, color: Colors.black),
                                  ),
                                ],
                              ),
                            ),
                          )
                              .animate()
                              .moveX(
                                begin: -20,
                                end: 0,
                                delay: (200 + i * 100).ms,
                                duration: 400.ms,
                                curve: Curves.easeOut,
                              )
                              .fadeIn(delay: (200 + i * 100).ms, duration: 400.ms);
                        }),
                        const SizedBox(height: 36),

                        // Pricing Card + Maybe Later
                        Column(
                          children: [
                            Container(
                              padding: const EdgeInsets.all(24),
                              decoration: BoxDecoration(
                                color: textPrimary, // foreground container (inverted)
                                borderRadius: BorderRadius.circular(32),
                                boxShadow: [
                                  BoxShadow(
                                    color: Colors.black.withValues(alpha: 0.15),
                                    blurRadius: 30,
                                    offset: const Offset(0, 15),
                                  ),
                                ],
                              ),
                              child: Column(
                                children: [
                                  Text(
                                    'LIFETIME PASS',
                                    style: GoogleFonts.montserrat(
                                      fontSize: 9,
                                      fontWeight: FontWeight.bold,
                                      color: subtle,
                                      letterSpacing: 2,
                                    ),
                                  ),
                                  const SizedBox(height: 4),
                                  Row(
                                    mainAxisAlignment: MainAxisAlignment.center,
                                    crossAxisAlignment: CrossAxisAlignment.start,
                                    children: [
                                      Text(
                                        '₹4,999',
                                        style: GoogleFonts.montserrat(
                                          fontSize: 20,
                                          fontWeight: FontWeight.bold,
                                          color: bg, // contrasts with foreground container
                                        ),
                                      ),
                                      const SizedBox(width: 4),
                                      Padding(
                                        padding: const EdgeInsets.only(top: 4),
                                        child: Text(
                                          '/one-time',
                                          style: GoogleFonts.montserrat(
                                            fontSize: 11,
                                            fontWeight: FontWeight.bold,
                                            color: subtle,
                                          ),
                                        ),
                                      ),
                                    ],
                                  ),
                                  const SizedBox(height: 20),
                                  _ScaleButton(
                                    onTap: () => _handleUpgrade(context),
                                    child: Container(
                                      width: double.infinity,
                                      height: 48,
                                      alignment: Alignment.center,
                                      decoration: BoxDecoration(
                                        color: Colors.black,
                                        borderRadius: BorderRadius.circular(16),
                                        boxShadow: [
                                          BoxShadow(
                                            color: Colors.black.withValues(alpha: 0.2),
                                            blurRadius: 20,
                                            offset: const Offset(0, 8),
                                          ),
                                        ],
                                      ),
                                      child: Text(
                                        'UPGRADE TO ELITE',
                                        style: GoogleFonts.montserrat(
                                          fontSize: 10,
                                          fontWeight: FontWeight.bold,
                                          color: Colors.white,
                                          letterSpacing: 2,
                                        ),
                                      ),
                                    ),
                                  ),
                                  const SizedBox(height: 20),
                                  Text(
                                    '*GET INSTANT ACCESS TO ALL PREMIUM FEATURES AND PROPERTY TOURS',
                                    textAlign: TextAlign.center,
                                    style: GoogleFonts.montserrat(
                                      fontSize: 8,
                                      fontWeight: FontWeight.bold,
                                      fontStyle: FontStyle.italic,
                                      color: subtle,
                                      letterSpacing: -0.2,
                                    ),
                                  ),
                                ],
                              ),
                            ),
                            const SizedBox(height: 20),
                            GestureDetector(
                              onTap: () => _back(context),
                              behavior: HitTestBehavior.opaque,
                              child: Text(
                                'MAYBE LATER',
                                textAlign: TextAlign.center,
                                style: GoogleFonts.montserrat(
                                  fontSize: 10,
                                  fontWeight: FontWeight.bold,
                                  color: subtle,
                                  letterSpacing: 2,
                                ),
                              ),
                            ),
                          ],
                        )
                            .animate()
                            .moveY(begin: 20, end: 0, delay: 600.ms, duration: 400.ms, curve: Curves.easeOut)
                            .fadeIn(delay: 600.ms, duration: 400.ms),
                      ],
                    ),
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class _Benefit {
  final String title;
  final String desc;
  final IconData icon;
  const _Benefit({required this.title, required this.desc, required this.icon});
}

/// Press-feedback wrapper mirroring the project_detail_screen pattern.
class _ScaleButton extends StatefulWidget {
  final Widget child;
  final VoidCallback? onTap;
  const _ScaleButton({required this.child, this.onTap});

  @override
  State<_ScaleButton> createState() => _ScaleButtonState();
}

class _ScaleButtonState extends State<_ScaleButton> {
  bool _isPressed = false;

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTapDown: (_) => setState(() => _isPressed = true),
      onTapUp: (_) => setState(() => _isPressed = false),
      onTapCancel: () => setState(() => _isPressed = false),
      onTap: widget.onTap,
      child: AnimatedScale(
        scale: _isPressed ? 0.95 : 1.0,
        duration: const Duration(milliseconds: 100),
        child: widget.child,
      ),
    );
  }
}

/// Circular bordered back button mirroring _CircleAction in project_detail_screen.
class _CircleAction extends StatelessWidget {
  final IconData icon;
  final VoidCallback onTap;

  const _CircleAction({required this.icon, required this.onTap});

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    return GestureDetector(
      onTap: onTap,
      child: Container(
        padding: const EdgeInsets.all(12),
        decoration: BoxDecoration(
          color: isDark ? Colors.white.withValues(alpha: 0.1) : Colors.white,
          shape: BoxShape.circle,
          boxShadow: [
            BoxShadow(
              color: Colors.black.withValues(alpha: 0.1),
              blurRadius: 10,
              offset: const Offset(0, 4),
            ),
          ],
          border: Border.all(color: isDark ? Colors.white.withValues(alpha: 0.1) : Colors.black.withValues(alpha: 0.05)),
        ),
        child: Icon(icon, size: 20, color: isDark ? Colors.white : Colors.black),
      ),
    );
  }
}
