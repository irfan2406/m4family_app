import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:lucide_icons/lucide_icons.dart';
import 'package:flutter_animate/flutter_animate.dart';
import 'package:intl/intl.dart';
import 'package:m4_mobile/core/providers/theme_provider.dart';
import 'package:m4_mobile/presentation/providers/auth_provider.dart';
import 'package:m4_mobile/core/network/api_client.dart';

class MyPropertyScreen extends ConsumerStatefulWidget {
  const MyPropertyScreen({super.key});

  @override
  ConsumerState<MyPropertyScreen> createState() => _MyPropertyScreenState();
}

class _MyPropertyScreenState extends ConsumerState<MyPropertyScreen> {
  bool _isLoading = true;
  List<dynamic> _bookings = [];
  double _totalValue = 0;

  @override
  void initState() {
    super.initState();
    _fetchBookings();
  }

  Future<void> _fetchBookings() async {
    try {
      final res = await ref.read(apiClientProvider).getMyBookings();
      if (res.data['status'] == true) {
        setState(() {
          _bookings = res.data['data'] ?? [];
          _totalValue = _bookings
              .where((b) => b['type'] == 'Token Reservation' && b['amount'] != null)
              .fold(0.0, (sum, b) {
                final amountStr = b['amount'].toString().replaceAll(RegExp(r'[^0-9]'), '');
                return sum + (double.tryParse(amountStr) ?? 0);
              });
        });
      }
    } catch (e) {
      debugPrint('Error fetching bookings: $e');
    } finally {
      if (mounted) setState(() => _isLoading = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    final isDark = ref.watch(themeProvider) == ThemeMode.dark;
    
    return Scaffold(
      backgroundColor: isDark ? const Color(0xFF09090B) : const Color(0xFFF8FAFC),
      body: SafeArea(
        child: Column(
          children: [
            _buildHeader(isDark),
            Expanded(
              child: _isLoading 
                ? const Center(child: CircularProgressIndicator())
                : RefreshIndicator(
                    onRefresh: _fetchBookings,
                    child: SingleChildScrollView(
                      physics: const BouncingScrollPhysics(),
                      padding: const EdgeInsets.all(24),
                      child: Column(
                        children: [
                          _buildPortfolioOverview(isDark),
                          const SizedBox(height: 32),
                          if (_bookings.isEmpty)
                            _buildEmptyState(isDark)
                          else
                            ..._bookings.map((booking) => _buildBookingCard(booking, isDark)).toList(),
                          const SizedBox(height: 100),
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

  Widget _buildHeader(bool isDark) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 16),
      child: Row(
        children: [
          _IconButton(
            icon: LucideIcons.chevronLeft,
            isDark: isDark,
            onTap: () => Navigator.pop(context),
          ),
          Expanded(
            child: Center(
              child: Text(
                'MY PROPERTY',
                style: GoogleFonts.montserrat(textStyle: const TextStyle(inherit: true), 
                  fontSize: 16,
                  fontWeight: FontWeight.w800,
                  color: isDark ? Colors.white : Colors.black,
                  letterSpacing: 2,
                ),
              ),
            ),
          ),
          const SizedBox(width: 44),
        ],
      ),
    );
  }

  Widget _buildPortfolioOverview(bool isDark) {
    final units = _bookings.where((b) => b['type'] == 'Token Reservation' || b['type'] == 'Booking Confirmation').length;
    final visits = _bookings.where((b) => b['type'] == 'Site Visit').length;

    return Container(
      padding: const EdgeInsets.all(24),
      decoration: BoxDecoration(
        color: isDark ? const Color(0xFF18181B) : Colors.white,
        borderRadius: BorderRadius.circular(32),
        border: Border.all(color: (isDark ? Colors.white : Colors.black).withOpacity(0.05)),
        boxShadow: isDark ? [] : [BoxShadow(color: Colors.black.withOpacity(0.05), blurRadius: 20, offset: const Offset(0, 10))],
      ),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                'PORTFOLIO OVERVIEW',
                style: GoogleFonts.montserrat(textStyle: const TextStyle(inherit: true), 
                  fontSize: 8,
                  fontWeight: FontWeight.w800,
                  color: isDark ? Colors.white38 : Colors.black38,
                  letterSpacing: 1.5,
                ),
              ),
              const SizedBox(height: 8),
              Text(
                '$units Units • $visits Visits',
                style: GoogleFonts.montserrat(textStyle: const TextStyle(inherit: true), 
                  fontSize: 16,
                  fontWeight: FontWeight.w800,
                  color: isDark ? Colors.white : Colors.black,
                ),
              ),
            ],
          ),
          Column(
            crossAxisAlignment: CrossAxisAlignment.end,
            children: [
              Text(
                'TOTAL VALUE',
                style: GoogleFonts.montserrat(textStyle: const TextStyle(inherit: true), 
                  fontSize: 8,
                  fontWeight: FontWeight.w800,
                  color: isDark ? Colors.white38 : Colors.black38,
                  letterSpacing: 1.5,
                ),
              ),
              const SizedBox(height: 8),
              Text(
                '₹${NumberFormat('#,##,###').format(_totalValue)}',
                style: GoogleFonts.montserrat(textStyle: const TextStyle(inherit: true), 
                  fontSize: 16,
                  fontWeight: FontWeight.w800,
                  color: const Color(0xFF22C55E),
                ),
              ),
            ],
          ),
        ],
      ),
    ).animate().fadeIn().slideY(begin: 0.1);
  }

  Widget _buildBookingCard(dynamic booking, bool isDark) {
    final project = booking['project'] ?? {};
    final status = booking['status'] ?? 'Unknown';
    final paymentPercent = booking['paymentPercent'] ?? 0;

    return Container(
      margin: const EdgeInsets.only(bottom: 20),
      decoration: BoxDecoration(
        color: isDark ? const Color(0xFF18181B) : Colors.white,
        borderRadius: BorderRadius.circular(32),
        border: Border.all(color: (isDark ? Colors.white : Colors.black).withOpacity(0.05)),
        boxShadow: isDark ? [] : [BoxShadow(color: Colors.black.withOpacity(0.05), blurRadius: 20, offset: const Offset(0, 10))],
      ),
      child: Column(
        children: [
          Padding(
            padding: const EdgeInsets.all(20),
            child: Row(
              children: [
                Container(
                  width: 50,
                  height: 50,
                  decoration: BoxDecoration(
                    color: (isDark ? Colors.white : Colors.black).withOpacity(0.05),
                    borderRadius: BorderRadius.circular(16),
                  ),
                  child: Icon(LucideIcons.building2, color: isDark ? Colors.white54 : Colors.black54, size: 24),
                ),
                const SizedBox(width: 16),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        (project['title'] ?? 'Unknown Project').toUpperCase(),
                        style: GoogleFonts.montserrat(textStyle: const TextStyle(inherit: true), 
                          fontSize: 14,
                          fontWeight: FontWeight.w800,
                          color: isDark ? Colors.white : Colors.black,
                        ),
                      ),
                      const SizedBox(height: 4),
                      Row(
                        children: [
                          Icon(LucideIcons.mapPin, size: 10, color: isDark ? Colors.white38 : Colors.black38),
                          const SizedBox(width: 4),
                          Text(
                            (project['location']?['name'] ?? 'Developing Area').toUpperCase(),
                            style: GoogleFonts.montserrat(textStyle: const TextStyle(inherit: true), 
                              fontSize: 9,
                              fontWeight: FontWeight.w700,
                              color: isDark ? Colors.white38 : Colors.black38,
                              letterSpacing: 0.5,
                            ),
                          ),
                        ],
                      ),
                    ],
                  ),
                ),
                _StatusBadge(status: status),
              ],
            ),
          ),
          Container(
            padding: const EdgeInsets.all(20),
            decoration: BoxDecoration(
              color: (isDark ? Colors.white : Colors.black).withOpacity(0.01),
              border: Border(top: BorderSide(color: (isDark ? Colors.white : Colors.black).withOpacity(0.05))),
            ),
            child: Column(
              children: [
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    _InfoItem(label: 'UNIT NUMBER', value: booking['unitNumber'] ?? 'N/A', isDark: isDark),
                    _InfoItem(label: 'FLOOR / LEVEL', value: booking['floor'] ?? 'PENDING', isDark: isDark, crossAlign: CrossAxisAlignment.end),
                  ],
                ),
                const SizedBox(height: 16),
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    _InfoItem(label: 'CONFIGURATION', value: booking['configuration'] ?? 'PREMIUM BHK', isDark: isDark),
                    _InfoItem(label: 'INVESTMENT', value: booking['amount'] ?? 'AED --', isDark: isDark, crossAlign: CrossAxisAlignment.end),
                  ],
                ),
                const SizedBox(height: 20),
                Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        Text('PAYMENT PROGRESS', style: GoogleFonts.montserrat(fontSize: 8, fontWeight: FontWeight.w900, color: isDark ? Colors.white24 : Colors.black26, letterSpacing: 1.5)),
                        Text('$paymentPercent% PAID', style: GoogleFonts.montserrat(fontSize: 9, fontWeight: FontWeight.w900, color: const Color(0xFF22C55E))),
                      ],
                    ),
                    const SizedBox(height: 8),
                    Container(
                      height: 6,
                      width: double.infinity,
                      decoration: BoxDecoration(
                        color: (isDark ? Colors.white : Colors.black).withOpacity(0.05),
                        borderRadius: BorderRadius.circular(3),
                      ),
                      child: FractionallySizedBox(
                        alignment: Alignment.centerLeft,
                        widthFactor: (paymentPercent / 100).clamp(0.05, 1.0),
                        child: Container(
                          decoration: BoxDecoration(
                            color: const Color(0xFF22C55E),
                            borderRadius: BorderRadius.circular(3),
                          ),
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
    ).animate().fadeIn().slideY(begin: 0.2);
  }

  Widget _buildEmptyState(bool isDark) {
    return Column(
      children: [
        const SizedBox(height: 60),
        Icon(LucideIcons.building2, size: 64, color: (isDark ? Colors.white : Colors.black).withOpacity(0.1)),
        const SizedBox(height: 24),
        Text(
          'NO PROPERTY RECORDS FOUND',
          style: GoogleFonts.montserrat(textStyle: const TextStyle(inherit: true), 
            fontSize: 10,
            fontWeight: FontWeight.w800,
            color: (isDark ? Colors.white : Colors.black).withOpacity(0.2),
            letterSpacing: 2,
          ),
        ),
      ],
    );
  }
}

class _StatusBadge extends StatelessWidget {
  final String status;
  const _StatusBadge({required this.status});

  @override
  Widget build(BuildContext context) {
    final color = status.toLowerCase() == 'confirmed' ? const Color(0xFF22C55E) : Colors.blueAccent;
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
      decoration: BoxDecoration(
        color: color.withOpacity(0.1),
        borderRadius: BorderRadius.circular(8),
        border: Border.all(color: color.withOpacity(0.2)),
      ),
      child: Text(
        status.toUpperCase(),
        style: GoogleFonts.montserrat(fontSize: 8, fontWeight: FontWeight.w900, color: color, letterSpacing: 0.5),
      ),
    );
  }
}

class _InfoItem extends StatelessWidget {
  final String label;
  final String value;
  final bool isDark;
  final CrossAxisAlignment crossAlign;
  const _InfoItem({required this.label, required this.value, required this.isDark, this.crossAlign = CrossAxisAlignment.start});

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: crossAlign,
      children: [
        Text(label, style: GoogleFonts.montserrat(fontSize: 8, fontWeight: FontWeight.w800, color: isDark ? Colors.white38 : Colors.black38, letterSpacing: 1)),
        const SizedBox(height: 4),
        Text(value, style: GoogleFonts.montserrat(fontSize: 11, fontWeight: FontWeight.w900, color: isDark ? Colors.white : Colors.black)),
      ],
    );
  }
}

class _IconButton extends StatelessWidget {
  final IconData icon;
  final bool isDark;
  final VoidCallback onTap;
  const _IconButton({required this.icon, required this.isDark, required this.onTap});

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        padding: const EdgeInsets.all(12),
        decoration: BoxDecoration(
          color: isDark ? const Color(0xFF18181B) : Colors.white,
          borderRadius: BorderRadius.circular(14),
          border: Border.all(color: (isDark ? Colors.white : Colors.black).withOpacity(0.05)),
        ),
        child: Icon(icon, color: isDark ? Colors.white54 : Colors.black54, size: 20),
      ),
    );
  }
}
