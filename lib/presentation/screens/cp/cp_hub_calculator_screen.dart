import 'dart:math' as math;

import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:lucide_icons/lucide_icons.dart';
import 'package:intl/intl.dart';

/// Web `/cp/hub/calculator` — local compound projection (no API).
class CpHubCalculatorScreen extends StatefulWidget {
  const CpHubCalculatorScreen({super.key});

  @override
  State<CpHubCalculatorScreen> createState() => _CpHubCalculatorScreenState();
}

class _CpHubCalculatorScreenState extends State<CpHubCalculatorScreen> {
  double _investment = 5000000;
  double _years = 5;
  double _rate = 12;

  @override
  Widget build(BuildContext context) {
    final total = _investment * math.pow(1 + _rate / 100, _years).toDouble();
    final profit = total - _investment;
    final fmt = NumberFormat.currency(
      locale: 'en_IN',
      symbol: '₹',
      decimalDigits: 0,
    );
    final scheme = Theme.of(context).colorScheme;
    final isLight = scheme.brightness == Brightness.light;
    const purple = Color(0xFFC5A35B);

    return Scaffold(
      appBar: AppBar(
        leading: IconButton(
          icon: const Icon(LucideIcons.arrowLeft),
          onPressed: () => context.pop(),
        ),
        title: Text(
          'Calculator',
          style: GoogleFonts.ebGaramond(fontWeight: FontWeight.w600),
        ),
      ),
      body: ListView(
        padding: const EdgeInsets.fromLTRB(20, 14, 20, 24),
        children: [
          // Result card (web gradient, centered)
          Container(
            padding: const EdgeInsets.all(18),
            decoration: BoxDecoration(
              borderRadius: BorderRadius.circular(24),
              gradient: LinearGradient(
                begin: Alignment.topLeft,
                end: Alignment.bottomRight,
                colors: [
                  purple.withValues(alpha: 0.18),
                  purple.withValues(alpha: 0.06),
                ],
              ),
              border: Border.all(color: purple.withValues(alpha: 0.28)),
            ),
            child: Column(
              children: [
                Text(
                  'PROJECTED MATURITY VALUE',
                  style: GoogleFonts.gelasio(
                    fontSize: 10,
                    fontWeight: FontWeight.w700,
                    letterSpacing: 2,
                    color: purple,
                  ),
                ),
                const SizedBox(height: 10),
                Text(
                  fmt.format(total),
                  textAlign: TextAlign.center,
                  style: GoogleFonts.gelasio(
                    fontSize: 28,
                    fontWeight: FontWeight.w700,
                    letterSpacing: -0.4,
                  ),
                ),
                const SizedBox(height: 12),
                Container(
                  padding: const EdgeInsets.symmetric(
                    horizontal: 12,
                    vertical: 8,
                  ),
                  decoration: BoxDecoration(
                    borderRadius: BorderRadius.circular(12),
                    color: Colors.black.withValues(alpha: 0.25),
                    border: Border.all(
                      color: scheme.outlineVariant.withValues(alpha: 0.35),
                    ),
                  ),
                  child: Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      const Icon(
                        LucideIcons.trendingUp,
                        size: 14,
                        color: Color(0xFF163A2C),
                      ),
                      const SizedBox(width: 8),
                      Text(
                        '+${fmt.format(profit)} PROFIT',
                        style: GoogleFonts.ebGaramond(
                          fontSize: 10,
                          fontWeight: FontWeight.w600,
                          letterSpacing: 1.2,
                          color: const Color(0xFF163A2C),
                        ),
                      ),
                    ],
                  ),
                ),
              ],
            ),
          ),
          const SizedBox(height: 22),

          _sliderBlock(
            label: 'Investment Amount',
            valueText: fmt.format(_investment),
            child: Slider(
              value: _investment,
              min: 1e6,
              max: 5e7,
              divisions: 98,
              activeColor: purple,
              inactiveColor: scheme.surfaceContainerHighest,
              onChanged: (v) => setState(() => _investment = v),
            ),
          ),
          const SizedBox(height: 12),
          _sliderBlock(
            label: 'Duration (Years)',
            valueText: '${_years.toInt()} Years',
            child: Slider(
              value: _years,
              min: 1,
              max: 10,
              divisions: 9,
              activeColor: purple,
              inactiveColor: scheme.surfaceContainerHighest,
              onChanged: (v) => setState(() => _years = v),
            ),
          ),
          const SizedBox(height: 12),
          _sliderBlock(
            label: 'Expected ROI',
            valueText: '${_rate.toStringAsFixed(1)}%',
            child: Slider(
              value: _rate,
              min: 5,
              max: 25,
              divisions: 40,
              activeColor: purple,
              inactiveColor: scheme.surfaceContainerHighest,
              onChanged: (v) => setState(() => _rate = v),
            ),
          ),
          const SizedBox(height: 18),
          Container(
            padding: const EdgeInsets.all(14),
            decoration: BoxDecoration(
              borderRadius: BorderRadius.circular(16),
              border: Border.all(
                color: scheme.outlineVariant.withValues(alpha: 0.4),
              ),
              color: scheme.onSurface.withValues(alpha: isLight ? 0.03 : 0.06),
            ),
            child: Row(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const Padding(
                  padding: EdgeInsets.only(top: 2),
                  child: Icon(LucideIcons.refreshCw, size: 16),
                ),
                const SizedBox(width: 10),
                Expanded(
                  child: Text(
                    'Disclaimer: Calculations are estimates based on compounded annual growth rate. Actual returns may vary based on market conditions and project performance.',
                    style: GoogleFonts.ebGaramond(
                      fontSize: 10,
                      fontWeight: FontWeight.w700,
                      height: 1.5,
                      color: scheme.onSurface.withValues(alpha: 0.6),
                    ),
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _sliderBlock({
    required String label,
    required String valueText,
    required Widget child,
  }) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            Text(
              label.toUpperCase(),
              style: GoogleFonts.gelasio(
                fontSize: 10,
                fontWeight: FontWeight.w700,
                letterSpacing: 1.6,
                color: Theme.of(
                  context,
                ).colorScheme.onSurface.withValues(alpha: 0.68),
              ),
            ),
            Text(
              valueText,
              style: GoogleFonts.ebGaramond(
                fontSize: 12,
                fontWeight: FontWeight.w600,
              ),
            ),
          ],
        ),
        const SizedBox(height: 8),
        child,
      ],
    );
  }
}
