import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:lucide_icons/lucide_icons.dart';
import 'package:m4_mobile/core/providers/theme_provider.dart';
import 'package:m4_mobile/presentation/providers/auth_provider.dart';
import 'package:dio/dio.dart';

class ReferralRedeemScreen extends ConsumerStatefulWidget {
  final double walletBalance;

  const ReferralRedeemScreen({super.key, required this.walletBalance});

  @override
  ConsumerState<ReferralRedeemScreen> createState() => _ReferralRedeemScreenState();
}

class _ReferralRedeemScreenState extends ConsumerState<ReferralRedeemScreen> {
  String? _selectedOption;
  bool _isLoading = false;
  final TextEditingController _amountController = TextEditingController();

  @override
  void dispose() {
    _amountController.dispose();
    super.dispose();
  }

  final List<Map<String, dynamic>> _redemptionOptions = [
    {
      'id': 'wallet_credit',
      'title': 'M4 WALLET CREDIT',
      'subtitle': '1 POINT = ₹1',
      'icon': LucideIcons.wallet,
    },
    {
      'id': 'booking_discount',
      'title': 'BOOKING DISCOUNT',
      'subtitle': '1 POINT = ₹1',
      'icon': LucideIcons.creditCard,
    },
    {
      'id': 'shopping_vouchers',
      'title': 'SHOPPING VOUCHERS',
      'subtitle': '100 POINTS = ₹80',
      'icon': LucideIcons.shoppingBag,
    },
    {
      'id': 'priority_concierge',
      'title': 'PRIORITY CONCIERGE',
      'subtitle': 'FIXED: 2000 POINTS',
      'icon': LucideIcons.zap,
    },
  ];

  @override
  Widget build(BuildContext context) {
    final themeMode = ref.watch(themeProvider);
    final isDark = themeMode == ThemeMode.dark;

    return Scaffold(
      backgroundColor: Theme.of(context).scaffoldBackgroundColor,
      appBar: AppBar(
        backgroundColor: Colors.transparent,
        elevation: 0,
        leading: IconButton(
          icon: Icon(LucideIcons.chevronLeft, color: isDark ? Colors.white : Colors.black),
          onPressed: () => Navigator.pop(context),
        ),
        title: Text(
          'REDEEM POINTS',
          style: GoogleFonts.montserrat(
            color: isDark ? Colors.white : Colors.black,
            fontSize: 14,
            fontWeight: FontWeight.w900,
            letterSpacing: 2,
          ),
        ),
        centerTitle: true,
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.symmetric(horizontal: 20),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const SizedBox(height: 20),
            _buildWalletCard(isDark),
            const SizedBox(height: 40),
            Text(
              'REDEMPTION MATRIX',
              style: GoogleFonts.montserrat(
                color: isDark ? Colors.white24 : Colors.black26,
                fontSize: 10,
                fontWeight: FontWeight.w800,
                letterSpacing: 2,
              ),
            ),
            const SizedBox(height: 20),
            ..._redemptionOptions.map((opt) => _buildOption(opt, isDark)).toList(),
            if (_selectedOption != null) ...[
              const SizedBox(height: 10),
              _buildVolumeInput(isDark),
            ],
            const SizedBox(height: 40),
            _buildConfirmButton(isDark),
            const SizedBox(height: 40),
          ],
        ),
      ),
    );
  }

  Widget _buildWalletCard(bool isDark) {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(30),
      decoration: BoxDecoration(
        color: isDark ? const Color(0xFF0A0C10) : Colors.white,
        borderRadius: BorderRadius.circular(30),
        border: Border.all(color: (isDark ? Colors.white : Colors.black).withOpacity(0.05)),
        boxShadow: isDark ? null : [
          BoxShadow(color: Colors.black.withOpacity(0.05), blurRadius: 20, offset: const Offset(0, 10)),
        ],
      ),
      child: Column(
        children: [
          Text(
            'AVAILABLE BALANCE',
            style: GoogleFonts.montserrat(
              color: isDark ? Colors.white24 : Colors.black26,
              fontSize: 10,
              fontWeight: FontWeight.w800,
              letterSpacing: 2,
            ),
          ),
          const SizedBox(height: 10),
          Row(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Text(
                widget.walletBalance.toStringAsFixed(0),
                style: GoogleFonts.montserrat(
                  color: isDark ? Colors.white : Colors.black,
                  fontSize: 48,
                  fontWeight: FontWeight.w900,
                ),
              ),
              const SizedBox(width: 8),
              Text(
                'PTS',
                style: GoogleFonts.montserrat(
                  color: isDark ? Colors.white38 : Colors.black38,
                  fontSize: 16,
                  fontWeight: FontWeight.w700,
                ),
              ),
            ],
          ),
          const SizedBox(height: 10),
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 6),
            decoration: BoxDecoration(
              color: (isDark ? Colors.white : Colors.black).withOpacity(0.05),
              borderRadius: BorderRadius.circular(20),
            ),
            child: Text(
              'VALUE: ₹${widget.walletBalance.toStringAsFixed(0)}',
              style: GoogleFonts.montserrat(
                color: isDark ? Colors.white : Colors.black,
                fontSize: 10,
                fontWeight: FontWeight.w900,
                letterSpacing: 1,
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildOption(Map<String, dynamic> opt, bool isDark) {
    final isSelected = _selectedOption == opt['id'];
    return GestureDetector(
      onTap: () {
        setState(() {
          _selectedOption = opt['id'];
        });
      },
      child: Container(
        margin: const EdgeInsets.only(bottom: 15),
        padding: const EdgeInsets.all(20),
        decoration: BoxDecoration(
          color: isDark ? const Color(0xFF080A0E) : Colors.white,
          borderRadius: BorderRadius.circular(25),
          border: Border.all(
            color: isSelected ? (isDark ? Colors.white : Colors.black) : (isDark ? Colors.white : Colors.black).withOpacity(0.05),
            width: isSelected ? 2 : 1,
          ),
          boxShadow: isDark ? null : [
            BoxShadow(color: Colors.black.withOpacity(0.02), blurRadius: 10, offset: const Offset(0, 5)),
          ],
        ),
        child: Row(
          children: [
            Container(
              padding: const EdgeInsets.all(12),
              decoration: BoxDecoration(
                color: (isDark ? Colors.white : Colors.black).withOpacity(0.05),
                shape: BoxShape.circle,
              ),
              child: Icon(opt['icon'], color: isDark ? Colors.white : Colors.black, size: 20),
            ),
            const SizedBox(width: 20),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    opt['title'],
                    style: GoogleFonts.montserrat(
                      color: isDark ? Colors.white : Colors.black,
                      fontSize: 14,
                      fontWeight: FontWeight.w800,
                    ),
                  ),
                  const SizedBox(height: 2),
                  Text(
                    opt['subtitle'],
                    style: GoogleFonts.montserrat(
                      color: isDark ? Colors.white38 : Colors.black38,
                      fontSize: 10,
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                ],
              ),
            ),
            if (isSelected)
              Icon(LucideIcons.checkCircle2, color: isDark ? Colors.white : Colors.black, size: 20),
          ],
        ),
      ),
    );
  }

  Widget _buildVolumeInput(bool isDark) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Padding(
          padding: const EdgeInsets.only(left: 10, bottom: 10, top: 10),
          child: Text(
            'REDEEM VOLUME',
            style: GoogleFonts.montserrat(
              color: isDark ? Colors.white24 : Colors.black26,
              fontSize: 10,
              fontWeight: FontWeight.w800,
              letterSpacing: 2,
            ),
          ),
        ),
        Container(
          decoration: BoxDecoration(
            color: isDark ? const Color(0xFF080A0E) : Colors.white,
            borderRadius: BorderRadius.circular(20),
            border: Border.all(color: (isDark ? Colors.white : Colors.black).withOpacity(0.05)),
          ),
          child: TextField(
            controller: _amountController,
            keyboardType: TextInputType.number,
            textAlign: TextAlign.center,
            style: GoogleFonts.montserrat(
              color: isDark ? Colors.white : Colors.black,
              fontSize: 24,
              fontWeight: FontWeight.w800,
            ),
            onChanged: (val) => setState(() {}),
            decoration: const InputDecoration(
              hintText: '0000',
              border: InputBorder.none,
              contentPadding: EdgeInsets.symmetric(vertical: 20),
            ),
          ),
        ),
        const SizedBox(height: 15),
        Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [500, 1000, 2000].map((amount) => _buildPresetButton(amount.toString(), isDark)).toList()..add(
            _buildPresetButton('MAX', isDark, isMax: true),
          ),
        ),
      ],
    );
  }

  Widget _buildPresetButton(String label, bool isDark, {bool isMax = false}) {
    return Expanded(
      child: GestureDetector(
        onTap: () {
          setState(() {
            if (isMax) {
              _amountController.text = widget.walletBalance.toInt().toString();
            } else {
              _amountController.text = label;
            }
          });
        },
        child: Container(
          margin: const EdgeInsets.symmetric(horizontal: 4),
          padding: const EdgeInsets.symmetric(vertical: 12),
          decoration: BoxDecoration(
            color: isMax ? (isDark ? Colors.white10 : Colors.black12) : Colors.transparent,
            borderRadius: BorderRadius.circular(12),
            border: Border.all(color: (isDark ? Colors.white : Colors.black).withOpacity(0.1)),
          ),
          alignment: Alignment.center,
          child: Text(
            label,
            style: GoogleFonts.montserrat(
              color: isDark ? Colors.white : Colors.black,
              fontSize: 10,
              fontWeight: FontWeight.w800,
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildConfirmButton(bool isDark) {
    final isEnabled = _selectedOption != null && _amountController.text.isNotEmpty && !_isLoading;
    return GestureDetector(
      onTap: isEnabled ? () async {
        setState(() => _isLoading = true);
        try {
          final apiClient = ref.read(apiClientProvider);
          final response = await apiClient.redeemPoints({
            'points': _amountController.text,
            'optionId': _selectedOption,
          });

          if (response.data['status'] == true) {
            if (mounted) {
              ScaffoldMessenger.of(context).showSnackBar(
                SnackBar(content: Text(response.data['message'] ?? 'Redemption Request Submitted')),
              );
              Navigator.pop(context, true); // true indicates success so previous screen can refresh
            }
          } else {
             if (mounted) {
               ScaffoldMessenger.of(context).showSnackBar(
                 SnackBar(content: Text(response.data['message'] ?? 'Redemption failed')),
               );
             }
          }
        } catch (e) {
          String errorMessage = 'Failed to process redemption request. Please try again later.';
          if (e is DioException && e.response?.data != null) {
            errorMessage = e.response!.data['message'] ?? errorMessage;
          }
          if (mounted) {
            ScaffoldMessenger.of(context).showSnackBar(
              SnackBar(content: Text(errorMessage)),
            );
          }
        } finally {
          if (mounted) {
            setState(() => _isLoading = false);
          }
        }
      } : null,
      child: Opacity(
        opacity: isEnabled ? 1.0 : 0.5,
        child: Container(
          width: double.infinity,
          padding: const EdgeInsets.symmetric(vertical: 20),
          decoration: BoxDecoration(
            color: isDark ? Colors.white : Colors.black,
            borderRadius: BorderRadius.circular(15),
          ),
          alignment: Alignment.center,
          child: _isLoading 
            ? SizedBox(
                width: 20,
                height: 20,
                child: CircularProgressIndicator(strokeWidth: 2, color: isDark ? Colors.black : Colors.white),
              )
            : Row(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Icon(LucideIcons.gift, color: isDark ? Colors.black : Colors.white, size: 16),
                  const SizedBox(width: 10),
                  Text(
                    'CONFIRM REDEMPTION',
                    style: GoogleFonts.montserrat(
                      color: isDark ? Colors.black : Colors.white,
                      fontSize: 12,
                      fontWeight: FontWeight.w900,
                      letterSpacing: 2,
                    ),
                  ),
                ],
              ),
        ),
      ),
    );
  }
}
