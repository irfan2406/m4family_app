import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:lucide_icons/lucide_icons.dart';
import 'package:flutter_animate/flutter_animate.dart';

/// Premium upsell checkout — mirrors web `/projects/premium-upsell/checkout`.
///
/// A 3-step payment flow: details -> processing -> success. The web prototype
/// simulates the charge with a 3-second timeout (no real gateway), so this
/// screen does the same with [Future.delayed].
class PremiumCheckoutScreen extends ConsumerStatefulWidget {
  final dynamic project;

  const PremiumCheckoutScreen({super.key, this.project});

  @override
  ConsumerState<PremiumCheckoutScreen> createState() =>
      _PremiumCheckoutScreenState();
}

enum _CheckoutStep { details, processing, success }

class _PremiumCheckoutScreenState extends ConsumerState<PremiumCheckoutScreen> {
  static const Color _gold = Color(0xFFFFD700);

  _CheckoutStep _step = _CheckoutStep.details;

  final TextEditingController _cardController = TextEditingController();
  final TextEditingController _expiryController = TextEditingController();
  final TextEditingController _cvvController = TextEditingController();

  @override
  void dispose() {
    _cardController.dispose();
    _expiryController.dispose();
    _cvvController.dispose();
    super.dispose();
  }

  void _onBack() {
    switch (_step) {
      case _CheckoutStep.details:
        if (context.canPop()) {
          context.pop();
        } else {
          context.go('/home');
        }
        break;
      case _CheckoutStep.success:
        context.go('/profile');
        break;
      case _CheckoutStep.processing:
        break; // disabled during processing
    }
  }

  Future<void> _handlePayment() async {
    setState(() => _step = _CheckoutStep.processing);

    // Web simulates the charge with a 3s timeout (localStorage only). Mirror it.
    await Future.delayed(const Duration(seconds: 3));
    if (!mounted) return;

    setState(() => _step = _CheckoutStep.success);

    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        backgroundColor: _gold,
        content: Text(
          'Welcome to M4 Elite! Your membership is now active.',
          style: GoogleFonts.montserrat(
            color: Colors.black,
            fontWeight: FontWeight.w700,
            fontSize: 13,
          ),
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final bg = isDark ? const Color(0xFF0F1115) : Colors.white;
    final textPrimary = isDark ? Colors.white : Colors.black;

    return Scaffold(
      backgroundColor: bg,
      appBar: AppBar(
        backgroundColor: Colors.transparent,
        elevation: 0,
        leading: IconButton(
          icon: Icon(LucideIcons.arrowLeft, color: textPrimary),
          onPressed: _step == _CheckoutStep.processing ? null : _onBack,
        ),
        title: Text(
          'ELITE CHECKOUT',
          style: GoogleFonts.montserrat(
            fontSize: 14,
            fontWeight: FontWeight.w900,
            color: textPrimary,
            letterSpacing: 1.5,
          ),
        ),
      ),
      body: SafeArea(
        child: switch (_step) {
          _CheckoutStep.details => _buildDetails(isDark),
          _CheckoutStep.processing => _buildProcessing(isDark),
          _CheckoutStep.success => _buildSuccess(isDark),
        },
      ),
    );
  }

  // ─────────────────────────── STEP 1 · DETAILS ───────────────────────────
  Widget _buildDetails(bool isDark) {
    final textPrimary = isDark ? Colors.white : Colors.black;
    final muted = (isDark ? Colors.white : Colors.black).withValues(alpha: 0.5);
    final card =
        isDark ? Colors.white.withValues(alpha: 0.03) : Colors.white;
    final border = isDark
        ? Colors.white.withValues(alpha: 0.08)
        : Colors.black.withValues(alpha: 0.06);

    return SingleChildScrollView(
      padding: const EdgeInsets.fromLTRB(24, 8, 24, 40),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // ── Summary Card ──
          Container(
            width: double.infinity,
            decoration: BoxDecoration(
              color: card,
              borderRadius: BorderRadius.circular(28),
              border: Border.all(color: border),
            ),
            padding: const EdgeInsets.all(24),
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
                          Container(
                            padding: const EdgeInsets.symmetric(
                                horizontal: 8, vertical: 3),
                            decoration: BoxDecoration(
                              color: _gold,
                              borderRadius: BorderRadius.circular(6),
                            ),
                            child: Text(
                              'M4 ELITE',
                              style: GoogleFonts.montserrat(
                                fontSize: 10,
                                fontWeight: FontWeight.w900,
                                color: Colors.black,
                                letterSpacing: 0.5,
                              ),
                            ),
                          ),
                          const SizedBox(height: 10),
                          Text(
                            'Lifetime Membership',
                            style: GoogleFonts.montserrat(
                              fontSize: 20,
                              fontWeight: FontWeight.bold,
                              color: textPrimary,
                            ),
                          ),
                        ],
                      ),
                    ),
                    Column(
                      crossAxisAlignment: CrossAxisAlignment.end,
                      children: [
                        Text(
                          '₹4,999',
                          style: GoogleFonts.montserrat(
                            fontSize: 24,
                            fontWeight: FontWeight.bold,
                            color: textPrimary,
                          ),
                        ),
                        Text(
                          'Fixed One-time',
                          style: GoogleFonts.montserrat(
                            fontSize: 10,
                            color: muted,
                          ),
                        ),
                      ],
                    ),
                  ],
                ),
                const SizedBox(height: 16),
                Divider(color: border, height: 1),
                const SizedBox(height: 16),
                _benefitRow('Full VR Access', muted),
                const SizedBox(height: 8),
                _benefitRow('Priority Support & Bookings', muted),
              ],
            ),
          ).animate().fadeIn(duration: 350.ms).scale(
                begin: const Offset(0.97, 0.97),
                end: const Offset(1, 1),
              ),

          const SizedBox(height: 32),

          // ── Payment Details ──
          Padding(
            padding: const EdgeInsets.only(left: 4, bottom: 12),
            child: Text(
              'PAYMENT DETAILS',
              style: GoogleFonts.montserrat(
                fontSize: 11,
                fontWeight: FontWeight.w900,
                color: muted,
                letterSpacing: 2,
              ),
            ),
          ),
          Container(
            decoration: BoxDecoration(
              color: card,
              borderRadius: BorderRadius.circular(20),
              border: Border.all(color: border),
            ),
            padding: const EdgeInsets.all(20),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                _fieldLabel('CARD NUMBER', muted),
                const SizedBox(height: 8),
                _cardField(
                  controller: _cardController,
                  hint: '0000 0000 0000 0000',
                  icon: LucideIcons.creditCard,
                  isDark: isDark,
                  border: border,
                  textPrimary: textPrimary,
                  muted: muted,
                  maxLength: 19,
                  keyboardType: TextInputType.number,
                  inputFormatters: [_CardNumberFormatter()],
                ),
                const SizedBox(height: 16),
                Row(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          _fieldLabel('EXPIRY DATE', muted),
                          const SizedBox(height: 8),
                          _cardField(
                            controller: _expiryController,
                            hint: 'MM/YY',
                            isDark: isDark,
                            border: border,
                            textPrimary: textPrimary,
                            muted: muted,
                            maxLength: 5,
                            center: true,
                            keyboardType: TextInputType.number,
                            inputFormatters: [_ExpiryFormatter()],
                          ),
                        ],
                      ),
                    ),
                    const SizedBox(width: 16),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          _fieldLabel('CVV', muted),
                          const SizedBox(height: 8),
                          _cardField(
                            controller: _cvvController,
                            hint: '***',
                            icon: LucideIcons.lock,
                            isDark: isDark,
                            border: border,
                            textPrimary: textPrimary,
                            muted: muted,
                            maxLength: 3,
                            center: true,
                            obscure: true,
                            keyboardType: TextInputType.number,
                            inputFormatters: [
                              FilteringTextInputFormatter.digitsOnly
                            ],
                          ),
                        ],
                      ),
                    ),
                  ],
                ),
              ],
            ),
          ).animate().fadeIn(delay: 100.ms, duration: 350.ms),

          const SizedBox(height: 20),

          // ── Security notice ──
          Container(
            padding: const EdgeInsets.all(16),
            decoration: BoxDecoration(
              color: card,
              borderRadius: BorderRadius.circular(20),
              border: Border.all(color: border),
            ),
            child: Row(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Icon(LucideIcons.shieldCheck,
                    color: const Color(0xFF22C55E).withValues(alpha: 0.6),
                    size: 28),
                const SizedBox(width: 14),
                Expanded(
                  child: Text(
                    'Your transaction is secured with bank-grade encryption. '
                    'M4 Family does not store your card details on our servers.',
                    style: GoogleFonts.montserrat(
                      fontSize: 11,
                      color: muted,
                      height: 1.5,
                    ),
                  ),
                ),
              ],
            ),
          ).animate().fadeIn(delay: 150.ms, duration: 350.ms),

          const SizedBox(height: 24),

          // ── Pay button ──
          _PressableScale(
            onTap: _handlePayment,
            child: Container(
              width: double.infinity,
              height: 64,
              decoration: BoxDecoration(
                color: _gold,
                borderRadius: BorderRadius.circular(20),
                boxShadow: [
                  BoxShadow(
                    color: _gold.withValues(alpha: 0.25),
                    blurRadius: 24,
                    offset: const Offset(0, 12),
                  ),
                ],
              ),
              child: Center(
                child: Text(
                  'Pay ₹4,999',
                  style: GoogleFonts.montserrat(
                    fontSize: 17,
                    fontWeight: FontWeight.bold,
                    color: Colors.black,
                  ),
                ),
              ),
            ),
          ).animate().fadeIn(delay: 200.ms, duration: 350.ms).moveY(
                begin: 12,
                end: 0,
              ),
        ],
      ),
    );
  }

  Widget _benefitRow(String label, Color muted) {
    return Row(
      children: [
        const Icon(LucideIcons.checkCircle2, size: 16, color: _gold),
        const SizedBox(width: 8),
        Text(
          label,
          style: GoogleFonts.montserrat(fontSize: 12, color: muted),
        ),
      ],
    );
  }

  Widget _fieldLabel(String text, Color muted) {
    return Text(
      text,
      style: GoogleFonts.montserrat(
        fontSize: 10,
        fontWeight: FontWeight.w900,
        color: muted,
        letterSpacing: 0.5,
      ),
    );
  }

  Widget _cardField({
    required TextEditingController controller,
    required String hint,
    required bool isDark,
    required Color border,
    required Color textPrimary,
    required Color muted,
    IconData? icon,
    int? maxLength,
    bool center = false,
    bool obscure = false,
    TextInputType? keyboardType,
    List<TextInputFormatter>? inputFormatters,
  }) {
    final fillColor = isDark
        ? Colors.black.withValues(alpha: 0.4)
        : Colors.black.withValues(alpha: 0.03);
    return TextField(
      controller: controller,
      obscureText: obscure,
      maxLength: maxLength,
      keyboardType: keyboardType,
      inputFormatters: inputFormatters,
      textAlign: center ? TextAlign.center : TextAlign.start,
      style: GoogleFonts.montserrat(
        fontSize: 17,
        fontWeight: FontWeight.w600,
        color: textPrimary,
        letterSpacing: 0.8,
      ),
      decoration: InputDecoration(
        counterText: '',
        hintText: hint,
        hintStyle: GoogleFonts.montserrat(
          fontSize: 17,
          fontWeight: FontWeight.w600,
          color: muted,
          letterSpacing: 0.8,
        ),
        filled: true,
        fillColor: fillColor,
        prefixIcon:
            icon != null ? Icon(icon, size: 18, color: muted) : null,
        contentPadding: EdgeInsets.symmetric(
          horizontal: icon != null ? 12 : 16,
          vertical: 16,
        ),
        enabledBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(14),
          borderSide: BorderSide(color: border),
        ),
        focusedBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(14),
          borderSide: const BorderSide(color: _gold, width: 1.5),
        ),
      ),
    );
  }

  // ────────────────────────── STEP 2 · PROCESSING ─────────────────────────
  Widget _buildProcessing(bool isDark) {
    final textPrimary = isDark ? Colors.white : Colors.black;
    final muted = (isDark ? Colors.white : Colors.black).withValues(alpha: 0.5);

    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          SizedBox(
            width: 96,
            height: 96,
            child: Stack(
              alignment: Alignment.center,
              children: [
                Container(
                  width: 96,
                  height: 96,
                  decoration: const BoxDecoration(
                    shape: BoxShape.circle,
                    border: Border(
                      bottom: BorderSide(color: _gold, width: 2),
                    ),
                  ),
                )
                    .animate(onPlay: (c) => c.repeat())
                    .rotate(duration: 2.seconds),
                Icon(LucideIcons.loader2, size: 32, color: muted)
                    .animate(onPlay: (c) => c.repeat(reverse: true))
                    .fadeIn(duration: 800.ms)
                    .then()
                    .fadeOut(duration: 800.ms),
              ],
            ),
          ),
          const SizedBox(height: 28),
          Text(
            'Verifying Payment',
            style: GoogleFonts.montserrat(
              fontSize: 22,
              fontWeight: FontWeight.bold,
              color: textPrimary,
            ),
          ),
          const SizedBox(height: 8),
          Text(
            'Communicating with your banking partner...',
            style: GoogleFonts.montserrat(fontSize: 13, color: muted),
          ),
        ],
      ),
    ).animate().fadeIn(duration: 300.ms).scale(
          begin: const Offset(0.9, 0.9),
          end: const Offset(1, 1),
        );
  }

  // ─────────────────────────── STEP 3 · SUCCESS ───────────────────────────
  Widget _buildSuccess(bool isDark) {
    final textPrimary = isDark ? Colors.white : Colors.black;
    final muted = (isDark ? Colors.white : Colors.black).withValues(alpha: 0.5);

    return SingleChildScrollView(
      padding: const EdgeInsets.symmetric(horizontal: 24),
      child: ConstrainedBox(
        constraints: BoxConstraints(
          minHeight: MediaQuery.of(context).size.height * 0.7,
        ),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            // Icon + ripple
            SizedBox(
              width: 160,
              height: 160,
              child: Stack(
                alignment: Alignment.center,
                children: [
                  Container(
                    width: 128,
                    height: 128,
                    decoration: const BoxDecoration(
                      shape: BoxShape.circle,
                      color: _gold,
                    ),
                  )
                      .animate(onPlay: (c) => c.repeat(reverse: true))
                      .scaleXY(
                        begin: 1,
                        end: 1.18,
                        duration: 1.seconds,
                      ),
                  Container(
                    width: 128,
                    height: 128,
                    decoration: BoxDecoration(
                      shape: BoxShape.circle,
                      color: _gold,
                      boxShadow: [
                        BoxShadow(
                          color: _gold.withValues(alpha: 0.4),
                          blurRadius: 40,
                          spreadRadius: 4,
                        ),
                      ],
                    ),
                    child: const Icon(LucideIcons.checkCircle2,
                        size: 64, color: Colors.black),
                  ).animate().scale(
                        begin: const Offset(0, 0),
                        end: const Offset(1, 1),
                        duration: 600.ms,
                        curve: Curves.elasticOut,
                      ),
                ],
              ),
            ),
            const SizedBox(height: 32),
            Text(
              'ELITE ACTIVE',
              style: GoogleFonts.montserrat(
                fontSize: 24,
                fontWeight: FontWeight.w900,
                color: textPrimary,
              ),
            ),
            const SizedBox(height: 8),
            Text(
              'WELCOME TO THE INNER CIRCLE',
              style: GoogleFonts.montserrat(
                fontSize: 11,
                fontWeight: FontWeight.bold,
                color: _gold,
                letterSpacing: 2,
              ),
            ),
            const SizedBox(height: 16),
            ConstrainedBox(
              constraints: const BoxConstraints(maxWidth: 280),
              child: Text(
                'Your premium membership is now active. Explore exclusive '
                'property tours and premium features.',
                textAlign: TextAlign.center,
                style: GoogleFonts.montserrat(
                  fontSize: 13,
                  color: muted,
                  height: 1.5,
                ),
              ),
            ),
            const SizedBox(height: 36),
            ConstrainedBox(
              constraints: const BoxConstraints(maxWidth: 280),
              child: Column(
                children: [
                  _PressableScale(
                    onTap: () => context.go('/home'),
                    child: Container(
                      width: double.infinity,
                      height: 52,
                      decoration: BoxDecoration(
                        color: isDark ? Colors.white : Colors.black,
                        borderRadius: BorderRadius.circular(18),
                      ),
                      child: Center(
                        child: Text(
                          'Explore M4 Projects',
                          style: GoogleFonts.montserrat(
                            fontSize: 14,
                            fontWeight: FontWeight.bold,
                            color: isDark ? Colors.black : Colors.white,
                          ),
                        ),
                      ),
                    ),
                  ),
                  const SizedBox(height: 12),
                  _PressableScale(
                    onTap: () => context.go('/profile'),
                    child: SizedBox(
                      width: double.infinity,
                      height: 52,
                      child: Center(
                        child: Text(
                          'Go to Profile',
                          style: GoogleFonts.montserrat(
                            fontSize: 14,
                            fontWeight: FontWeight.w600,
                            color: muted,
                          ),
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
    ).animate().fadeIn(duration: 400.ms).moveY(begin: 30, end: 0);
  }
}

/// Auto-formats a card number into groups of 4 digits.
class _CardNumberFormatter extends TextInputFormatter {
  @override
  TextEditingValue formatEditUpdate(
      TextEditingValue oldValue, TextEditingValue newValue) {
    final digits = newValue.text.replaceAll(RegExp(r'\D'), '');
    final buffer = StringBuffer();
    for (var i = 0; i < digits.length; i++) {
      if (i != 0 && i % 4 == 0) buffer.write(' ');
      buffer.write(digits[i]);
    }
    final formatted = buffer.toString();
    return TextEditingValue(
      text: formatted,
      selection: TextSelection.collapsed(offset: formatted.length),
    );
  }
}

/// Formats expiry as MM/YY while typing.
class _ExpiryFormatter extends TextInputFormatter {
  @override
  TextEditingValue formatEditUpdate(
      TextEditingValue oldValue, TextEditingValue newValue) {
    final digits = newValue.text.replaceAll(RegExp(r'\D'), '');
    final buffer = StringBuffer();
    for (var i = 0; i < digits.length && i < 4; i++) {
      if (i == 2) buffer.write('/');
      buffer.write(digits[i]);
    }
    final formatted = buffer.toString();
    return TextEditingValue(
      text: formatted,
      selection: TextSelection.collapsed(offset: formatted.length),
    );
  }
}

/// Tap-feedback wrapper: scales down briefly on press.
class _PressableScale extends StatefulWidget {
  final Widget child;
  final VoidCallback onTap;

  const _PressableScale({required this.child, required this.onTap});

  @override
  State<_PressableScale> createState() => _PressableScaleState();
}

class _PressableScaleState extends State<_PressableScale> {
  bool _pressed = false;

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTapDown: (_) => setState(() => _pressed = true),
      onTapUp: (_) => setState(() => _pressed = false),
      onTapCancel: () => setState(() => _pressed = false),
      onTap: widget.onTap,
      child: AnimatedScale(
        scale: _pressed ? 0.97 : 1.0,
        duration: const Duration(milliseconds: 120),
        child: widget.child,
      ),
    );
  }
}
