import 'dart:math' as math;

import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:intl/intl.dart';
import 'package:lucide_icons/lucide_icons.dart';
import 'package:m4_mobile/presentation/widgets/side_menu_button.dart';

/// Guest EMI / investment calculator — interactive tool for App Store utility.
class GuestCalculatorScreen extends StatefulWidget {
  /// When true, shown as a pushed route with a back button.
  /// When false, shown as an embedded tool from Account / Home with side menu.
  final bool pushed;

  const GuestCalculatorScreen({super.key, this.pushed = true});

  @override
  State<GuestCalculatorScreen> createState() => _GuestCalculatorScreenState();
}

class _GuestCalculatorScreenState extends State<GuestCalculatorScreen> {
  double _amount = 7500000;
  double _years = 20;
  double _rate = 8.5;

  double get _monthlyRate => _rate / 12 / 100;
  int get _months => (_years * 12).round();

  double get _emi {
    if (_monthlyRate == 0) return _amount / _months;
    final r = _monthlyRate;
    final n = _months;
    final pow = math.pow(1 + r, n).toDouble();
    return _amount * r * pow / (pow - 1);
  }

  double get _totalPayable => _emi * _months;
  double get _interest => _totalPayable - _amount;

  @override
  Widget build(BuildContext context) {
    final scheme = Theme.of(context).colorScheme;
    final isDark = scheme.brightness == Brightness.dark;
    const accent = Color(0xFF0C312B);
    final fmt = NumberFormat.currency(
      locale: 'en_IN',
      symbol: '₹',
      decimalDigits: 0,
    );

    return Scaffold(
      backgroundColor: Theme.of(context).scaffoldBackgroundColor,
      body: SafeArea(
        bottom: false,
        child: Column(
          children: [
            Padding(
              padding: const EdgeInsets.fromLTRB(16, 12, 16, 8),
              child: Row(
                children: [
                  if (widget.pushed)
                    IconButton(
                      onPressed: () {
                        if (context.canPop()) {
                          context.pop();
                        } else {
                          context.go('/home');
                        }
                      },
                      icon: const Icon(LucideIcons.arrowLeft),
                    )
                  else
                    const SideMenuButton(),
                  const SizedBox(width: 8),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          'EMI CALCULATOR',
                          style: GoogleFonts.gelasio(
                            fontSize: 18,
                            fontWeight: FontWeight.w700,
                            color: isDark ? Colors.white : accent,
                          ),
                        ),
                        Text(
                          'Estimate monthly payments for a property.',
                          style: GoogleFonts.inter(
                            fontSize: 12,
                            color: (isDark ? Colors.white : accent)
                                .withValues(alpha: 0.55),
                          ),
                        ),
                      ],
                    ),
                  ),
                ],
              ),
            ),
            Expanded(
              child: ListView(
                padding: const EdgeInsets.fromLTRB(20, 8, 20, 120),
                children: [
                  Container(
                    padding: const EdgeInsets.all(20),
                    decoration: BoxDecoration(
                      borderRadius: BorderRadius.circular(24),
                      gradient: LinearGradient(
                        begin: Alignment.topLeft,
                        end: Alignment.bottomRight,
                        colors: [
                          accent.withValues(alpha: isDark ? 0.35 : 0.16),
                          accent.withValues(alpha: isDark ? 0.12 : 0.05),
                        ],
                      ),
                      border: Border.all(
                        color: accent.withValues(alpha: 0.25),
                      ),
                    ),
                    child: Column(
                      children: [
                        Text(
                          'ESTIMATED MONTHLY EMI',
                          style: GoogleFonts.gelasio(
                            fontSize: 10,
                            fontWeight: FontWeight.w700,
                            letterSpacing: 2,
                            color: isDark
                                ? Colors.white70
                                : accent.withValues(alpha: 0.75),
                          ),
                        ),
                        const SizedBox(height: 10),
                        Text(
                          fmt.format(_emi),
                          textAlign: TextAlign.center,
                          style: GoogleFonts.gelasio(
                            fontSize: 32,
                            fontWeight: FontWeight.w700,
                            color: isDark ? Colors.white : accent,
                          ),
                        ),
                        const SizedBox(height: 16),
                        Row(
                          children: [
                            Expanded(
                              child: _MiniStat(
                                label: 'TOTAL INTEREST',
                                value: fmt.format(_interest),
                                isDark: isDark,
                              ),
                            ),
                            const SizedBox(width: 10),
                            Expanded(
                              child: _MiniStat(
                                label: 'TOTAL PAYABLE',
                                value: fmt.format(_totalPayable),
                                isDark: isDark,
                              ),
                            ),
                          ],
                        ),
                      ],
                    ),
                  ),
                  const SizedBox(height: 22),
                  _sliderBlock(
                    label: 'Loan Amount',
                    valueText: fmt.format(_amount),
                    isDark: isDark,
                    child: Slider(
                      value: _amount,
                      min: 1e6,
                      max: 5e7,
                      divisions: 98,
                      activeColor: accent,
                      inactiveColor: scheme.surfaceContainerHighest,
                      onChanged: (v) => setState(() => _amount = v),
                    ),
                  ),
                  const SizedBox(height: 12),
                  _sliderBlock(
                    label: 'Tenure',
                    valueText: '${_years.toInt()} Years',
                    isDark: isDark,
                    child: Slider(
                      value: _years,
                      min: 5,
                      max: 30,
                      divisions: 25,
                      activeColor: accent,
                      inactiveColor: scheme.surfaceContainerHighest,
                      onChanged: (v) => setState(() => _years = v),
                    ),
                  ),
                  const SizedBox(height: 12),
                  _sliderBlock(
                    label: 'Interest Rate (p.a.)',
                    valueText: '${_rate.toStringAsFixed(1)}%',
                    isDark: isDark,
                    child: Slider(
                      value: _rate,
                      min: 6,
                      max: 15,
                      divisions: 90,
                      activeColor: accent,
                      inactiveColor: scheme.surfaceContainerHighest,
                      onChanged: (v) => setState(() => _rate = v),
                    ),
                  ),
                  const SizedBox(height: 20),
                  Text(
                    'Figures are estimates for planning only and do not constitute a loan offer.',
                    textAlign: TextAlign.center,
                    style: GoogleFonts.inter(
                      fontSize: 11,
                      height: 1.4,
                      color: (isDark ? Colors.white : accent)
                          .withValues(alpha: 0.45),
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

  Widget _sliderBlock({
    required String label,
    required String valueText,
    required bool isDark,
    required Widget child,
  }) {
    final accent = isDark ? Colors.white : const Color(0xFF0C312B);
    return Container(
      padding: const EdgeInsets.fromLTRB(16, 14, 16, 8),
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(18),
        color: accent.withValues(alpha: 0.04),
        border: Border.all(color: accent.withValues(alpha: 0.08)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Expanded(
                child: Text(
                  label,
                  style: GoogleFonts.inter(
                    fontSize: 12,
                    fontWeight: FontWeight.w600,
                    color: accent.withValues(alpha: 0.7),
                  ),
                ),
              ),
              Text(
                valueText,
                style: GoogleFonts.inter(
                  fontSize: 13,
                  fontWeight: FontWeight.w700,
                  color: accent,
                ),
              ),
            ],
          ),
          child,
        ],
      ),
    );
  }
}

class _MiniStat extends StatelessWidget {
  final String label;
  final String value;
  final bool isDark;

  const _MiniStat({
    required this.label,
    required this.value,
    required this.isDark,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(14),
        color: Colors.black.withValues(alpha: isDark ? 0.25 : 0.06),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            label,
            style: GoogleFonts.inter(
              fontSize: 9,
              fontWeight: FontWeight.w700,
              letterSpacing: 1,
              color: (isDark ? Colors.white : const Color(0xFF0C312B))
                  .withValues(alpha: 0.55),
            ),
          ),
          const SizedBox(height: 6),
          Text(
            value,
            style: GoogleFonts.inter(
              fontSize: 13,
              fontWeight: FontWeight.w700,
              color: isDark ? Colors.white : const Color(0xFF0C312B),
            ),
          ),
        ],
      ),
    );
  }
}
