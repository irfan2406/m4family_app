import 'package:flutter/material.dart';
import 'package:flutter/cupertino.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:lucide_icons/lucide_icons.dart';
import 'package:m4_mobile/core/theme/app_theme.dart';
import 'package:m4_mobile/presentation/providers/auth_provider.dart';

/// Web `/cp/booking/token-payment` — CP secure token reservation payment.
///
/// Mirrors the user-side token payment flow but omits unit selection and
/// document upload (user-side features). Same 3 payment methods, terms
/// agreement and security messaging as the web prototype.
class CpTokenPaymentScreen extends ConsumerStatefulWidget {
  final String projectId;

  const CpTokenPaymentScreen({super.key, required this.projectId});

  @override
  ConsumerState<CpTokenPaymentScreen> createState() => _CpTokenPaymentScreenState();
}

class _CpTokenPaymentScreenState extends ConsumerState<CpTokenPaymentScreen> {
  String _selectedMethod = 'upi';
  bool _agreed = false;
  bool _isLoading = false;
  bool _isSuccess = false;
  String _tokenAmount = '1,00,000';
  String _projectName = '';
  String? _errorMessage;

  @override
  void initState() {
    super.initState();
    if (widget.projectId.isNotEmpty) {
      _fetchProject();
    }
  }

  Future<void> _fetchProject() async {
    try {
      final apiClient = ref.read(apiClientProvider);
      final res = await apiClient.get('/api/cp/projects/${widget.projectId}');
      if (res.data['status'] == true && res.data['data'] != null) {
        final data = res.data['data'];
        setState(() {
          _tokenAmount = (data['tokenAmount'] ?? '1,00,000').toString();
          _projectName = (data['title'] ?? data['name'] ?? '').toString();
        });
      }
    } catch (_) {
      // Keep default token amount; non-fatal.
    }
  }

  Future<void> _submitPayment() async {
    if (!_agreed) {
      _showToast('Please agree to the terms and conditions');
      return;
    }
    setState(() {
      _isLoading = true;
      _errorMessage = null;
    });
    try {
      final apiClient = ref.read(apiClientProvider);
      final res = await apiClient.post('/api/cp/bookings/token-payment', {
        'projectId': widget.projectId,
        'paymentMethod': _selectedMethod,
        'agreed': _agreed,
      });

      if (res.data['status'] == true) {
        setState(() => _isSuccess = true);
      } else {
        setState(() => _errorMessage =
            res.data['message']?.toString() ?? 'Payment could not be processed.');
        _showToast(_errorMessage!);
      }
    } catch (e) {
      setState(() => _errorMessage = 'Payment failed. Please try again.');
      _showToast('Payment failed: ${e.toString()}');
    } finally {
      if (mounted) setState(() => _isLoading = false);
    }
  }

  void _showToast(String message) {
    if (!mounted) return;
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(content: Text(message)),
    );
  }

  Widget _buildPaymentMethod(String id, String name, IconData icon, bool isDark) {
    final isActive = _selectedMethod == id;
    final muted = (isDark ? Colors.white : Colors.black).withValues(alpha: 0.5);
    final border = isDark
        ? Colors.white.withValues(alpha: 0.08)
        : Colors.black.withValues(alpha: 0.06);
    return Padding(
      padding: const EdgeInsets.only(bottom: 16),
      child: GestureDetector(
        onTap: () => setState(() => _selectedMethod = id),
        child: Container(
          padding: const EdgeInsets.all(20),
          decoration: BoxDecoration(
            color: isActive
                ? M4Theme.premiumBlue.withValues(alpha: 0.06)
                : (isDark ? Colors.white.withValues(alpha: 0.03) : Colors.white),
            borderRadius: BorderRadius.circular(24),
            border: Border.all(color: isActive ? M4Theme.premiumBlue : border),
          ),
          child: Row(
            children: [
              Container(
                width: 48,
                height: 48,
                decoration: BoxDecoration(
                  color: isActive
                      ? M4Theme.premiumBlue
                      : (isDark
                          ? Colors.white.withValues(alpha: 0.06)
                          : Colors.black.withValues(alpha: 0.04)),
                  borderRadius: BorderRadius.circular(16),
                ),
                child: Icon(icon, color: isActive ? Colors.white : muted, size: 22),
              ),
              const SizedBox(width: 16),
              Expanded(
                child: Text(
                  name,
                  style: GoogleFonts.montserrat(
                    fontSize: 12,
                    fontWeight: FontWeight.w900,
                    color: isDark ? Colors.white : Colors.black,
                    letterSpacing: 0.5,
                  ),
                ),
              ),
              if (isActive)
                Container(
                  width: 28,
                  height: 28,
                  decoration: const BoxDecoration(
                    color: M4Theme.premiumBlue,
                    shape: BoxShape.circle,
                  ),
                  child: const Icon(LucideIcons.check, color: Colors.white, size: 16),
                )
              else
                Container(
                  width: 28,
                  height: 28,
                  decoration: BoxDecoration(
                    shape: BoxShape.circle,
                    border: Border.all(color: border),
                  ),
                ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildSuccessScreen(bool isDark) {
    return Scaffold(
      backgroundColor: isDark ? Colors.black : Colors.white,
      body: GestureDetector(
        onTap: () => context.go('/cp/dashboard'),
        behavior: HitTestBehavior.opaque,
        child: Center(
          child: Padding(
            padding: const EdgeInsets.all(40),
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Container(
                  width: 96,
                  height: 96,
                  decoration: BoxDecoration(
                    color: M4Theme.premiumBlue.withValues(alpha: 0.1),
                    shape: BoxShape.circle,
                  ),
                  child: const Icon(LucideIcons.check, size: 48, color: M4Theme.premiumBlue),
                ),
                const SizedBox(height: 32),
                Text(
                  'PAYMENT SUCCESSFUL',
                  style: GoogleFonts.montserrat(
                    fontSize: 22,
                    fontWeight: FontWeight.w900,
                    color: isDark ? Colors.white : Colors.black,
                    letterSpacing: 0.5,
                  ),
                ),
                const SizedBox(height: 16),
                Text(
                  'Your token reservation of ₹$_tokenAmount has been received. Our team will verify the booking and contact you for the next steps.',
                  textAlign: TextAlign.center,
                  style: GoogleFonts.montserrat(
                    fontSize: 10,
                    color: (isDark ? Colors.white : Colors.black).withValues(alpha: 0.5),
                    fontWeight: FontWeight.w900,
                    letterSpacing: 1.2,
                    height: 1.8,
                  ),
                ),
                const SizedBox(height: 48),
                Container(
                  width: double.infinity,
                  height: 64,
                  decoration: BoxDecoration(
                    color: isDark ? Colors.white : Colors.black,
                    borderRadius: BorderRadius.circular(32),
                  ),
                  child: Center(
                    child: Text(
                      'GO TO DASHBOARD',
                      style: GoogleFonts.montserrat(
                        color: isDark ? Colors.black : Colors.white,
                        fontWeight: FontWeight.w900,
                        fontSize: 11,
                        letterSpacing: 2,
                      ),
                    ),
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final bg = isDark ? Colors.black : Colors.white;
    final textPrimary = isDark ? Colors.white : Colors.black;
    final muted = (isDark ? Colors.white : Colors.black).withValues(alpha: 0.5);

    if (_isSuccess) {
      return _buildSuccessScreen(isDark);
    }

    return Scaffold(
      backgroundColor: bg,
      appBar: AppBar(
        backgroundColor: Colors.transparent,
        elevation: 0,
        leading: IconButton(
          icon: Icon(LucideIcons.chevronLeft, color: textPrimary),
          onPressed: () => context.canPop() ? context.pop() : context.go('/cp/dashboard'),
        ),
        title: Text(
          'SECURE PAYMENT',
          style: GoogleFonts.montserrat(
            fontSize: 14,
            fontWeight: FontWeight.w900,
            color: textPrimary,
            letterSpacing: 0.5,
          ),
        ),
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 32),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Token Amount Card
            Container(
              width: double.infinity,
              height: 200,
              decoration: BoxDecoration(
                color: Colors.black,
                borderRadius: BorderRadius.circular(40),
                boxShadow: [
                  BoxShadow(
                    color: Colors.black.withValues(alpha: 0.3),
                    blurRadius: 40,
                    offset: const Offset(0, 20),
                  ),
                ],
              ),
              clipBehavior: Clip.antiAlias,
              child: Stack(
                children: [
                  Positioned(
                    right: -20,
                    bottom: -20,
                    child: Icon(
                      LucideIcons.shieldCheck,
                      color: Colors.white.withValues(alpha: 0.05),
                      size: 180,
                    ),
                  ),
                  Padding(
                    padding: const EdgeInsets.all(40),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        Text(
                          'TOKEN AMOUNT',
                          style: GoogleFonts.montserrat(
                            fontSize: 10,
                            fontWeight: FontWeight.w900,
                            color: Colors.white.withValues(alpha: 0.5),
                            letterSpacing: 2,
                          ),
                        ),
                        const SizedBox(height: 12),
                        Text(
                          '₹$_tokenAmount',
                          style: GoogleFonts.montserrat(
                            fontSize: 36,
                            fontWeight: FontWeight.w900,
                            color: Colors.white,
                            letterSpacing: -1,
                          ),
                        ),
                        const SizedBox(height: 16),
                        Container(
                          padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 7),
                          decoration: BoxDecoration(
                            color: M4Theme.premiumBlue.withValues(alpha: 0.15),
                            borderRadius: BorderRadius.circular(20),
                            border: Border.all(
                              color: M4Theme.premiumBlue.withValues(alpha: 0.3),
                            ),
                          ),
                          child: Row(
                            mainAxisSize: MainAxisSize.min,
                            children: [
                              const Icon(
                                LucideIcons.shieldCheck,
                                color: Color(0xFFFFD700),
                                size: 14,
                              ),
                              const SizedBox(width: 8),
                              Text(
                                '100% REFUNDABLE',
                                style: GoogleFonts.montserrat(
                                  fontSize: 9,
                                  fontWeight: FontWeight.w900,
                                  color: const Color(0xFFFFD700),
                                  letterSpacing: 1,
                                ),
                              ),
                            ],
                          ),
                        ),
                      ],
                    ),
                  ),
                ],
              ),
            ),

            if (_projectName.isNotEmpty) ...[
              const SizedBox(height: 16),
              Text(
                _projectName.toUpperCase(),
                style: GoogleFonts.montserrat(
                  fontSize: 10,
                  fontWeight: FontWeight.w900,
                  color: muted,
                  letterSpacing: 1.5,
                ),
              ),
            ],

            // Payment Methods
            const SizedBox(height: 48),
            Text(
              'PAYMENT METHOD',
              style: GoogleFonts.montserrat(
                fontSize: 10,
                fontWeight: FontWeight.w900,
                color: muted,
                letterSpacing: 1.5,
              ),
            ),
            const SizedBox(height: 24),
            _buildPaymentMethod('upi', 'UPI (PHONEPE/GPAY)', LucideIcons.smartphone, isDark),
            _buildPaymentMethod('card', 'CREDIT / DEBIT CARD', LucideIcons.creditCard, isDark),
            _buildPaymentMethod('net', 'NET BANKING', LucideIcons.wallet, isDark),

            // Terms Checkbox
            const SizedBox(height: 24),
            GestureDetector(
              onTap: () => setState(() => _agreed = !_agreed),
              child: Container(
                padding: const EdgeInsets.all(20),
                decoration: BoxDecoration(
                  color: M4Theme.premiumBlue.withValues(alpha: 0.04),
                  borderRadius: BorderRadius.circular(24),
                  border: Border.all(color: M4Theme.premiumBlue.withValues(alpha: 0.1)),
                ),
                child: Row(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Container(
                      width: 24,
                      height: 24,
                      decoration: BoxDecoration(
                        color: _agreed ? textPrimary : Colors.transparent,
                        borderRadius: BorderRadius.circular(6),
                        border: Border.all(color: textPrimary, width: 2),
                      ),
                      child: _agreed
                          ? Icon(LucideIcons.check, color: bg, size: 14)
                          : null,
                    ),
                    const SizedBox(width: 16),
                    Expanded(
                      child: Text(
                        'I AGREE TO THE BOOKING TERMS AND UNDERSTAND THAT THIS TOKEN AMOUNT IS FULLY REFUNDABLE WITHIN 7 DAYS OF PAYMENT.',
                        style: GoogleFonts.montserrat(
                          fontSize: 9,
                          color: muted,
                          fontWeight: FontWeight.w900,
                          height: 1.7,
                          letterSpacing: 0.5,
                        ),
                      ),
                    ),
                  ],
                ),
              ),
            ),

            // Pay Button
            const SizedBox(height: 32),
            SizedBox(
              width: double.infinity,
              child: ElevatedButton(
                onPressed: _agreed && !_isLoading ? _submitPayment : null,
                style: ElevatedButton.styleFrom(
                  backgroundColor: textPrimary,
                  foregroundColor: bg,
                  padding: const EdgeInsets.symmetric(vertical: 24),
                  shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(40)),
                  elevation: 0,
                ).copyWith(
                  backgroundColor: WidgetStateProperty.resolveWith((states) {
                    if (states.contains(WidgetState.disabled)) {
                      return textPrimary.withValues(alpha: 0.1);
                    }
                    return textPrimary;
                  }),
                ),
                child: _isLoading
                    ? CupertinoActivityIndicator(color: bg)
                    : Row(
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: [
                          Text(
                            'PAY ₹$_tokenAmount',
                            style: GoogleFonts.montserrat(
                              fontSize: 14,
                              fontWeight: FontWeight.w900,
                              letterSpacing: 1,
                            ),
                          ),
                          const SizedBox(width: 12),
                          const Icon(LucideIcons.creditCard, size: 18),
                        ],
                      ),
              ),
            ),

            // Security Footer
            const SizedBox(height: 32),
            Center(
              child: Row(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Icon(LucideIcons.shieldCheck, color: muted, size: 14),
                  const SizedBox(width: 10),
                  Text(
                    'PCI-DSS COMPLIANT • 256-BIT SSL ENCRYPTION',
                    style: GoogleFonts.montserrat(
                      fontSize: 8,
                      fontWeight: FontWeight.w900,
                      color: muted,
                      letterSpacing: 1,
                    ),
                  ),
                ],
              ),
            ),
            const SizedBox(height: 48),
          ],
        ),
      ),
    );
  }
}
