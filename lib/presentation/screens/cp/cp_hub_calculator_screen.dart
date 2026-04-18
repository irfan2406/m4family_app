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
    final fmt = NumberFormat.currency(locale: 'en_IN', symbol: '₹', decimalDigits: 0);

    return Scaffold(
      appBar: AppBar(
        leading: IconButton(icon: const Icon(LucideIcons.arrowLeft), onPressed: () => context.pop()),
        title: Text('Calculator', style: GoogleFonts.montserrat(fontWeight: FontWeight.w800)),
      ),
      body: ListView(
        padding: const EdgeInsets.all(20),
        children: [
          Card(
            color: Colors.purple.withValues(alpha: 0.15),
            child: Padding(
              padding: const EdgeInsets.all(20),
              child: Column(
                children: [
                  Text(
                    'PROJECTED MATURITY',
                    style: TextStyle(fontSize: 10, letterSpacing: 2, color: Theme.of(context).hintColor),
                  ),
                  const SizedBox(height: 8),
                  Text(fmt.format(total), style: GoogleFonts.montserrat(fontSize: 26, fontWeight: FontWeight.w900)),
                  const SizedBox(height: 8),
                  Text(
                    '+ ${fmt.format(profit)} profit',
                    style: const TextStyle(color: Colors.greenAccent, fontWeight: FontWeight.bold),
                  ),
                ],
              ),
            ),
          ),
          const SizedBox(height: 24),
          Text('Investment', style: GoogleFonts.montserrat(fontWeight: FontWeight.w600)),
          Slider(
            value: _investment,
            min: 1e6,
            max: 5e7,
            divisions: 98,
            label: fmt.format(_investment),
            onChanged: (v) => setState(() => _investment = v),
          ),
          Text('Years', style: GoogleFonts.montserrat(fontWeight: FontWeight.w600)),
          Slider(
            value: _years,
            min: 1,
            max: 15,
            divisions: 14,
            label: '${_years.toInt()} y',
            onChanged: (v) => setState(() => _years = v),
          ),
          Text('Rate % p.a.', style: GoogleFonts.montserrat(fontWeight: FontWeight.w600)),
          Slider(
            value: _rate,
            min: 6,
            max: 18,
            divisions: 24,
            label: '${_rate.toStringAsFixed(1)}%',
            onChanged: (v) => setState(() => _rate = v),
          ),
        ],
      ),
    );
  }

}
