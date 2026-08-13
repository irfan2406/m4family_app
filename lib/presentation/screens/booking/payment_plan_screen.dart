import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:lucide_icons/lucide_icons.dart';
import 'package:m4_mobile/core/theme/app_theme.dart';
import 'package:m4_mobile/core/network/api_client.dart';
import 'package:m4_mobile/presentation/providers/auth_provider.dart';
import 'package:flutter_animate/flutter_animate.dart';
import 'package:m4_mobile/presentation/screens/booking/token_payment_screen.dart';
import 'package:m4_mobile/presentation/widgets/navigation_pill.dart';
import 'package:m4_mobile/presentation/widgets/main_shell.dart';

class PaymentPlanScreen extends ConsumerStatefulWidget {
  final dynamic project;
  final String projectId;

  const PaymentPlanScreen({super.key, required this.projectId, this.project});

  @override
  ConsumerState<PaymentPlanScreen> createState() => _PaymentPlanScreenState();
}

class _PaymentPlanScreenState extends ConsumerState<PaymentPlanScreen> {
  List<dynamic> _plans = [];
  bool _isLoading = true;

  @override
  void initState() {
    super.initState();
    _fetchPlans();
  }

  Future<void> _fetchPlans() async {
    try {
      final apiClient = ref.read(apiClientProvider);
      final res = await apiClient.get(
        '/payment/schedule?projectId=${widget.projectId}',
      );

      if (res.data['status'] == true) {
        setState(() {
          _plans = res.data['data'] ?? [];
          _isLoading = false;
        });
      } else {
        _useFallbackPlans();
      }
    } catch (e) {
      _useFallbackPlans();
    }
  }

  void _useFallbackPlans() {
    setState(() {
      _plans = [
        {
          '_id': 'std',
          'name': '60/40 Standard Plan',
          'description': 'Construction linked payment schedule.',
          'benefit': 'Lower upfront cost',
          'icon': LucideIcons.zap,
          'color': const Color(0xFFC5A35B),
        },
      ];
      _isLoading = false;
    });
  }

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;

    return Scaffold(
      backgroundColor: isDark ? const Color(0xFF0B1026) : Colors.white,
      extendBody: true,
      bottomNavigationBar: NavigationPill(
        currentIndex: -1,
        onTap: (i) {
          ref.read(navigationProvider.notifier).state = i;
          Navigator.of(context).popUntil((r) => r.isFirst);
        },
      ),
      appBar: AppBar(
        backgroundColor: Colors.transparent,
        elevation: 0,
        leading: IconButton(
          icon: Icon(
            LucideIcons.chevronLeft,
            color: isDark ? Colors.white : Colors.black,
          ),
          onPressed: () => Navigator.pop(context),
        ),
        title: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              'CHOOSE PLAN',
              style: GoogleFonts.ebGaramond(
                fontSize: 17,
                fontWeight: FontWeight.w900,
                color: isDark ? Colors.white : Colors.black,
                letterSpacing: -0.5,
              ),
            ),
            Text(
              'SELECT YOUR PREFERRED SCHEDULE',
              style: GoogleFonts.ebGaramond(
                fontSize: 8,
                color: (isDark ? Colors.white : Colors.black).withOpacity(0.68),
                fontWeight: FontWeight.w900,
                letterSpacing: 1,
              ),
            ),
          ],
        ),
      ),
      body: _isLoading
          ? const Center(child: CircularProgressIndicator())
          : SingleChildScrollView(
              padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 32),
              child: Column(
                children: [
                  ..._plans.asMap().entries.map((entry) {
                    final index = entry.key;
                    final plan = entry.value;
                    final isZap = index % 2 == 0;
                    final icon = isZap
                        ? LucideIcons.zap
                        : LucideIcons.shieldCheck;
                    final color = isZap
                        ? const Color(0xFFC5A35B)
                        : const Color(0xFFC5A35B);
                    final benefit =
                        plan['name']?.toString().contains('Down') == true
                        ? 'MAX SAVINGS'
                        : 'LOWER UPFRONT COST';

                    return Padding(
                          padding: const EdgeInsets.only(bottom: 24),
                          child: _PaymentPlanCard(
                            plan: plan,
                            icon: icon,
                            color: color,
                            benefit: benefit,
                            isDark: isDark,
                            onTap: () => Navigator.push(
                              context,
                              MaterialPageRoute(
                                builder: (context) => TokenPaymentScreen(
                                  projectId: widget.projectId,
                                  project: widget.project,
                                  plan: plan,
                                ),
                              ),
                            ),
                          ),
                        )
                        .animate()
                        .fadeIn(delay: (index * 100).ms)
                        .moveX(begin: -20, end: 0);
                  }).toList(),

                  const SizedBox(height: 12),
                  // Compare Plans Card
                  Container(
                    padding: const EdgeInsets.all(24),
                    decoration: BoxDecoration(
                      color: isDark
                          ? Colors.white.withOpacity(0.03)
                          : Colors.black.withOpacity(0.04),
                      borderRadius: BorderRadius.circular(32),
                      border: Border.all(
                        color: isDark
                            ? Colors.white.withOpacity(0.05)
                            : Colors.black.withOpacity(0.05),
                      ),
                    ),
                    child: Row(
                      children: [
                        Container(
                          width: 56,
                          height: 56,
                          decoration: BoxDecoration(
                            color: isDark ? Colors.white : Colors.black,
                            borderRadius: BorderRadius.circular(16),
                          ),
                          child: Icon(
                            LucideIcons.info,
                            color: isDark ? Colors.black : Colors.white,
                            size: 24,
                          ),
                        ),
                        const SizedBox(width: 20),
                        Expanded(
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Text(
                                'COMPARE PLANS',
                                style: GoogleFonts.ebGaramond(
                                  fontSize: 10,
                                  fontWeight: FontWeight.w900,
                                  letterSpacing: 1.5,
                                  color: isDark ? Colors.white : Colors.black,
                                ),
                              ),
                              const SizedBox(height: 4),
                              Text(
                                'VIEW A DETAILED SIDE-BY-SIDE COMPARISON OF ALL AVAILABLE PAYMENT SCHEDULES.',
                                style: GoogleFonts.ebGaramond(
                                  fontSize: 8,
                                  color: (isDark ? Colors.white : Colors.black)
                                      .withOpacity(0.68),
                                  fontWeight: FontWeight.bold,
                                  height: 1.4,
                                ),
                              ),
                            ],
                          ),
                        ),
                      ],
                    ),
                  ).animate().fadeIn(delay: 400.ms),

                  const SizedBox(height: 32),
                  // Download Button
                  Container(
                    width: double.infinity,
                    padding: const EdgeInsets.symmetric(vertical: 24),
                    decoration: BoxDecoration(
                      borderRadius: BorderRadius.circular(32),
                      border: Border.all(
                        color: isDark
                            ? Colors.white.withOpacity(0.05)
                            : Colors.black.withOpacity(0.05),
                      ),
                    ),
                    child: Center(
                      child: Text(
                        'DOWNLOAD ALL PAYMENT PLANS (PDF)',
                        style: GoogleFonts.ebGaramond(
                          fontSize: 9,
                          fontWeight: FontWeight.w900,
                          letterSpacing: 1,
                          color: isDark ? Colors.white : Colors.black,
                        ),
                      ),
                    ),
                  ).animate().fadeIn(delay: 500.ms),

                  const SizedBox(height: 64),
                ],
              ),
            ),
    );
  }
}

class _PaymentPlanCard extends StatelessWidget {
  final dynamic plan;
  final IconData icon;
  final Color color;
  final String benefit;
  final bool isDark;
  final VoidCallback onTap;

  const _PaymentPlanCard({
    required this.plan,
    required this.icon,
    required this.color,
    required this.benefit,
    required this.isDark,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        decoration: BoxDecoration(
          color: isDark ? Colors.white.withOpacity(0.02) : Colors.white,
          borderRadius: BorderRadius.circular(40),
          border: Border.all(
            color: isDark
                ? Colors.white.withOpacity(0.05)
                : Colors.black.withOpacity(0.05),
          ),
          boxShadow: isDark
              ? []
              : [
                  BoxShadow(
                    color: Colors.black.withOpacity(0.08),
                    blurRadius: 40,
                    offset: const Offset(0, 20),
                  ),
                ],
        ),
        clipBehavior: Clip.antiAlias,
        child: Padding(
          padding: const EdgeInsets.all(32),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Expanded(
                    child: Text(
                      (plan['name'] ?? 'Plan').toString().toUpperCase(),
                      style: GoogleFonts.ebGaramond(
                        fontSize: 26,
                        fontWeight: FontWeight.w900,
                        color: isDark ? Colors.white : Colors.black,
                        height: 1.1,
                        letterSpacing: -0.5,
                      ),
                    ),
                  ),
                  const SizedBox(width: 20),
                  Container(
                    width: 60,
                    height: 60,
                    decoration: BoxDecoration(
                      color: color.withOpacity(0.1),
                      borderRadius: BorderRadius.circular(16),
                    ),
                    child: Icon(icon, color: color, size: 24),
                  ),
                ],
              ),
              const SizedBox(height: 34),
              // Web parity: divider between the plan title and the benefit row.
              Divider(
                height: 1,
                color: (isDark ? Colors.white : Colors.black).withOpacity(0.08),
              ),
              const SizedBox(height: 30),
              Row(
                children: [
                  Expanded(
                    child: Row(
                      children: [
                        Container(
                          width: 6,
                          height: 6,
                          decoration: BoxDecoration(
                            color: isDark ? Colors.white : Colors.black,
                            shape: BoxShape.circle,
                          ),
                        ),
                        const SizedBox(width: 12),
                        Flexible(
                          child: Text(
                            benefit,
                            maxLines: 1,
                            overflow: TextOverflow.ellipsis,
                            style: GoogleFonts.ebGaramond(
                              fontSize: 9,
                              fontWeight: FontWeight.w900,
                              color: isDark ? Colors.white : Colors.black,
                              letterSpacing: 1,
                            ),
                          ),
                        ),
                      ],
                    ),
                  ),
                  const SizedBox(width: 12),
                  Container(
                    padding: const EdgeInsets.symmetric(
                      horizontal: 20,
                      vertical: 12,
                    ),
                    decoration: BoxDecoration(
                      color: isDark
                          ? Colors.white.withOpacity(0.05)
                          : Colors.black.withOpacity(0.03),
                      borderRadius: BorderRadius.circular(20),
                    ),
                    child: Row(
                      children: [
                        Text(
                          'SELECT PLAN',
                          style: GoogleFonts.ebGaramond(
                            fontSize: 9,
                            fontWeight: FontWeight.w900,
                            color: isDark ? Colors.white : Colors.black,
                            letterSpacing: 1,
                          ),
                        ),
                        const SizedBox(width: 10),
                        Icon(
                          LucideIcons.arrowRight,
                          color: isDark ? Colors.white : Colors.black,
                          size: 14,
                        ),
                      ],
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
