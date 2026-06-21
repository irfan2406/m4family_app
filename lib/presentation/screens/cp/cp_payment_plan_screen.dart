import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:lucide_icons/lucide_icons.dart';
import 'package:flutter_animate/flutter_animate.dart';
import 'package:m4_mobile/core/theme/app_theme.dart';
import 'package:m4_mobile/presentation/providers/auth_provider.dart';

/// Web `/cp/booking/payment-plan` parity — CHOOSE PLAN.
/// Fetches `GET /payment/schedule?projectId=...`, falls back to two static
/// plans. Mirrors the user-side `PaymentPlanScreen` with CP styling.
class CpPaymentPlanScreen extends ConsumerStatefulWidget {
  final String projectId;
  final dynamic project;

  const CpPaymentPlanScreen({
    super.key,
    required this.projectId,
    this.project,
  });

  @override
  ConsumerState<CpPaymentPlanScreen> createState() => _CpPaymentPlanScreenState();
}

class _CpPaymentPlanScreenState extends ConsumerState<CpPaymentPlanScreen> {
  static const Color _gold = Color(0xFFFFD700);

  List<dynamic> _plans = [];
  bool _loading = true;

  @override
  void initState() {
    super.initState();
    _fetchPlans();
  }

  Future<void> _fetchPlans() async {
    setState(() => _loading = true);
    try {
      final apiClient = ref.read(apiClientProvider);
      final res = await apiClient.get(
        '/payment/schedule',
        queryParameters: {'projectId': widget.projectId},
      );
      if (!mounted) return;
      if (res.data is Map &&
          res.data['status'] == true &&
          res.data['data'] is List &&
          (res.data['data'] as List).isNotEmpty) {
        setState(() {
          _plans = List<dynamic>.from(res.data['data']);
          _loading = false;
        });
      } else {
        _useFallbackPlans();
      }
    } catch (_) {
      _useFallbackPlans();
    }
  }

  void _useFallbackPlans() {
    if (!mounted) return;
    setState(() {
      _plans = [
        {
          '_id': 'std',
          'name': 'Standard Plan',
          'description': 'Construction linked payment schedule.',
          'benefit': 'Lower upfront cost',
        },
        {
          '_id': 'down',
          'name': 'Down Payment',
          'description': 'Pay 90% upfront and get additional discount.',
          'benefit': 'Max Savings',
          'popular': true,
        },
      ];
      _loading = false;
    });
  }

  void _selectPlan(dynamic plan) {
    final planId = (plan['_id'] ?? plan['id'] ?? '').toString();
    context.push(
      '/booking/token-payment?projectId=${widget.projectId}&plan=$planId',
    );
  }

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final bg = isDark ? Colors.black : Colors.white;
    final textPrimary = isDark ? Colors.white : Colors.black;
    final muted = (isDark ? Colors.white : Colors.black).withValues(alpha: 0.5);
    final border = isDark
        ? Colors.white.withValues(alpha: 0.08)
        : Colors.black.withValues(alpha: 0.06);

    return Scaffold(
      backgroundColor: bg,
      body: SafeArea(
        child: Column(
          children: [
            // ─── Header ─────────────────────────────────
            Padding(
              padding: const EdgeInsets.fromLTRB(24, 20, 24, 16),
              child: Row(
                children: [
                  GestureDetector(
                    onTap: () =>
                        context.canPop() ? context.pop() : context.go('/cp/dashboard'),
                    child: Container(
                      width: 48,
                      height: 48,
                      decoration: BoxDecoration(
                        color: (isDark ? Colors.white : Colors.black)
                            .withValues(alpha: 0.04),
                        shape: BoxShape.circle,
                        border: Border.all(color: border),
                      ),
                      child: Icon(LucideIcons.chevronLeft, size: 20, color: textPrimary),
                    ),
                  ),
                  const SizedBox(width: 16),
                  Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        'CHOOSE PLAN',
                        style: GoogleFonts.montserrat(
                          fontSize: 22,
                          fontWeight: FontWeight.w900,
                          letterSpacing: -0.5,
                          color: textPrimary,
                        ),
                      ),
                      const SizedBox(height: 2),
                      Text(
                        'SELECT YOUR PREFERRED SCHEDULE',
                        style: GoogleFonts.montserrat(
                          fontSize: 8,
                          fontWeight: FontWeight.w900,
                          letterSpacing: 2,
                          color: muted,
                        ),
                      ),
                    ],
                  ),
                ],
              ),
            ),

            // ─── Body ───────────────────────────────────
            Expanded(
              child: _loading
                  ? const Center(
                      child: CircularProgressIndicator(color: M4Theme.premiumBlue),
                    )
                  : RefreshIndicator(
                      onRefresh: _fetchPlans,
                      color: M4Theme.premiumBlue,
                      child: SingleChildScrollView(
                        physics: const AlwaysScrollableScrollPhysics(),
                        padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 16),
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            ..._plans.asMap().entries.map((entry) {
                              final index = entry.key;
                              final plan = entry.value;
                              final isDown =
                                  (plan['name']?.toString().toLowerCase().contains('down') ??
                                          false) ||
                                      plan['popular'] == true;
                              final icon =
                                  isDown ? LucideIcons.shieldCheck : LucideIcons.zap;
                              final accent = isDown ? _gold : M4Theme.premiumBlue;
                              final benefit = (plan['benefit'] ??
                                      (isDown ? 'Max Savings' : 'Lower upfront cost'))
                                  .toString();

                              return Padding(
                                padding: const EdgeInsets.only(bottom: 20),
                                child: _PaymentPlanCard(
                                  plan: plan,
                                  icon: icon,
                                  accent: accent,
                                  benefit: benefit,
                                  popular: plan['popular'] == true,
                                  isDark: isDark,
                                  onTap: () => _selectPlan(plan),
                                ),
                              )
                                  .animate()
                                  .fadeIn(delay: (index * 100).ms)
                                  .moveX(begin: -20, end: 0);
                            }),

                            const SizedBox(height: 8),

                            // ─── Compare Plans box ──────────────
                            Container(
                              padding: const EdgeInsets.all(24),
                              decoration: BoxDecoration(
                                color: M4Theme.premiumBlue.withValues(alpha: 0.05),
                                borderRadius: BorderRadius.circular(32),
                                border: Border.all(
                                  color: M4Theme.premiumBlue.withValues(alpha: 0.12),
                                ),
                              ),
                              child: Row(
                                children: [
                                  Container(
                                    width: 56,
                                    height: 56,
                                    decoration: BoxDecoration(
                                      color: M4Theme.premiumBlue,
                                      borderRadius: BorderRadius.circular(18),
                                    ),
                                    child: const Icon(LucideIcons.info,
                                        color: Colors.white, size: 24),
                                  ),
                                  const SizedBox(width: 18),
                                  Expanded(
                                    child: Column(
                                      crossAxisAlignment: CrossAxisAlignment.start,
                                      children: [
                                        Text(
                                          'COMPARE PLANS',
                                          style: GoogleFonts.montserrat(
                                            fontSize: 11,
                                            fontWeight: FontWeight.w900,
                                            letterSpacing: 1.5,
                                            color: textPrimary,
                                          ),
                                        ),
                                        const SizedBox(height: 4),
                                        Text(
                                          'NEED HELP DECIDING? CONTACT YOUR RELATIONSHIP MANAGER FOR A DETAILED COMPARISON SHEET.',
                                          style: GoogleFonts.montserrat(
                                            fontSize: 8,
                                            fontWeight: FontWeight.bold,
                                            height: 1.5,
                                            letterSpacing: 0.5,
                                            color: muted,
                                          ),
                                        ),
                                      ],
                                    ),
                                  ),
                                ],
                              ),
                            ).animate().fadeIn(delay: 400.ms),

                            const SizedBox(height: 28),

                            // ─── Download PDF button ────────────
                            GestureDetector(
                              onTap: () {
                                ScaffoldMessenger.of(context).showSnackBar(
                                  const SnackBar(
                                    content: Text('Payment plan PDF will be available soon.'),
                                  ),
                                );
                              },
                              child: Container(
                                width: double.infinity,
                                padding: const EdgeInsets.symmetric(vertical: 20),
                                decoration: BoxDecoration(
                                  borderRadius: BorderRadius.circular(28),
                                  border: Border.all(
                                    color: M4Theme.premiumBlue.withValues(alpha: 0.15),
                                  ),
                                ),
                                child: Center(
                                  child: Text(
                                    'DOWNLOAD ALL PAYMENT PLANS (PDF)',
                                    style: GoogleFonts.montserrat(
                                      fontSize: 9,
                                      fontWeight: FontWeight.w900,
                                      letterSpacing: 2,
                                      color: M4Theme.premiumBlue,
                                    ),
                                  ),
                                ),
                              ),
                            ).animate().fadeIn(delay: 500.ms),

                            const SizedBox(height: 48),
                          ],
                        ),
                      ),
                    ),
            ),
          ],
        ),
      ),
    );
  }
}

class _PaymentPlanCard extends StatelessWidget {
  final dynamic plan;
  final IconData icon;
  final Color accent;
  final String benefit;
  final bool popular;
  final bool isDark;
  final VoidCallback onTap;

  const _PaymentPlanCard({
    required this.plan,
    required this.icon,
    required this.accent,
    required this.benefit,
    required this.popular,
    required this.isDark,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    final textPrimary = isDark ? Colors.white : Colors.black;
    final muted = (isDark ? Colors.white : Colors.black).withValues(alpha: 0.5);
    final cardBg = isDark ? Colors.white.withValues(alpha: 0.03) : Colors.white;
    final border = popular
        ? M4Theme.premiumBlue.withValues(alpha: 0.4)
        : (isDark
            ? Colors.white.withValues(alpha: 0.08)
            : Colors.black.withValues(alpha: 0.06));
    final desc = (plan['description'] ?? plan['desc'] ?? '').toString();

    return GestureDetector(
      onTap: onTap,
      child: Container(
        decoration: BoxDecoration(
          color: cardBg,
          borderRadius: BorderRadius.circular(40),
          border: Border.all(color: border, width: popular ? 1.5 : 1),
          boxShadow: isDark
              ? []
              : [
                  BoxShadow(
                    color: Colors.black.withValues(alpha: 0.08),
                    blurRadius: 40,
                    offset: const Offset(0, 20),
                  ),
                ],
        ),
        clipBehavior: Clip.antiAlias,
        child: Stack(
          children: [
            if (popular)
              Positioned(
                top: 0,
                right: 0,
                child: Container(
                  padding: const EdgeInsets.symmetric(horizontal: 18, vertical: 8),
                  decoration: const BoxDecoration(
                    color: M4Theme.premiumBlue,
                    borderRadius: BorderRadius.only(bottomLeft: Radius.circular(24)),
                  ),
                  child: Text(
                    'MOST POPULAR',
                    style: GoogleFonts.montserrat(
                      fontSize: 8,
                      fontWeight: FontWeight.w900,
                      letterSpacing: 2,
                      color: Colors.white,
                    ),
                  ),
                ),
              ),
            Padding(
              padding: const EdgeInsets.all(32),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(
                              (plan['name'] ?? 'Plan').toString().toUpperCase(),
                              style: GoogleFonts.montserrat(
                                fontSize: 22,
                                fontWeight: FontWeight.w900,
                                height: 1.1,
                                letterSpacing: -0.5,
                                color: textPrimary,
                              ),
                            ),
                            if (desc.isNotEmpty) ...[
                              const SizedBox(height: 8),
                              Text(
                                desc,
                                style: GoogleFonts.montserrat(
                                  fontSize: 11,
                                  fontWeight: FontWeight.w500,
                                  height: 1.4,
                                  color: muted,
                                ),
                              ),
                            ],
                          ],
                        ),
                      ),
                      const SizedBox(width: 20),
                      Container(
                        width: 56,
                        height: 56,
                        decoration: BoxDecoration(
                          color: accent.withValues(alpha: 0.12),
                          borderRadius: BorderRadius.circular(18),
                        ),
                        child: Icon(icon, color: accent, size: 26),
                      ),
                    ],
                  ),
                  const SizedBox(height: 28),
                  Divider(
                    height: 1,
                    color: (isDark ? Colors.white : Colors.black).withValues(alpha: 0.06),
                  ),
                  const SizedBox(height: 24),
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      Row(
                        children: [
                          Container(
                            width: 7,
                            height: 7,
                            decoration: BoxDecoration(
                              color: accent,
                              shape: BoxShape.circle,
                            ),
                          ),
                          const SizedBox(width: 12),
                          Text(
                            benefit.toUpperCase(),
                            style: GoogleFonts.montserrat(
                              fontSize: 9,
                              fontWeight: FontWeight.w900,
                              letterSpacing: 1,
                              color: accent,
                            ),
                          ),
                        ],
                      ),
                      Container(
                        padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 12),
                        decoration: BoxDecoration(
                          color: (isDark ? Colors.white : Colors.black)
                              .withValues(alpha: isDark ? 0.05 : 0.03),
                          borderRadius: BorderRadius.circular(999),
                        ),
                        child: Row(
                          children: [
                            Text(
                              'SELECT PLAN',
                              style: GoogleFonts.montserrat(
                                fontSize: 9,
                                fontWeight: FontWeight.w900,
                                letterSpacing: 1,
                                color: textPrimary,
                              ),
                            ),
                            const SizedBox(width: 10),
                            Icon(LucideIcons.arrowRight, size: 14, color: textPrimary),
                          ],
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
    );
  }
}
