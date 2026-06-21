import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:lucide_icons/lucide_icons.dart';
import 'package:go_router/go_router.dart';
import 'package:m4_mobile/core/theme/app_theme.dart';
import 'package:m4_mobile/presentation/providers/auth_provider.dart';
import 'package:flutter_animate/flutter_animate.dart';
import 'package:share_plus/share_plus.dart';

class CpBookingConfirmationScreen extends ConsumerStatefulWidget {
  final String projectId;
  final dynamic project;
  final String? bookingId;
  final String? amount;

  const CpBookingConfirmationScreen({
    super.key,
    required this.projectId,
    this.project,
    this.bookingId,
    this.amount,
  });

  @override
  ConsumerState<CpBookingConfirmationScreen> createState() =>
      _CpBookingConfirmationScreenState();
}

class _CpBookingConfirmationScreenState
    extends ConsumerState<CpBookingConfirmationScreen> {
  dynamic _project;
  bool _loading = false;

  static const String _fallbackReceipt = 'M4-2026-8812';
  static const String _fallbackAmount = '1,00,000.00';

  @override
  void initState() {
    super.initState();
    _project = widget.project;
    if (_project == null) {
      _fetchProject();
    }
  }

  Future<void> _fetchProject() async {
    setState(() => _loading = true);
    try {
      final apiClient = ref.read(apiClientProvider);
      final res = await apiClient.get('/api/catalog/projects/${widget.projectId}');
      if (res.data['status'] == true) {
        if (mounted) setState(() => _project = res.data['data']);
      }
    } catch (_) {
      // Keep fallback strings on failure.
    } finally {
      if (mounted) setState(() => _loading = false);
    }
  }

  String get _projectTitle {
    final title = _project?['title'];
    if (title != null && title.toString().trim().isNotEmpty) {
      return title.toString();
    }
    return 'M4 Project';
  }

  String get _receiptId =>
      widget.bookingId?.trim().isNotEmpty == true ? widget.bookingId! : widget.projectId;

  String get _amount =>
      widget.amount?.trim().isNotEmpty == true ? widget.amount! : _fallbackAmount;

  String _formattedDate() {
    final now = DateTime.now();
    return '${now.day.toString().padLeft(2, '0')}/${now.month.toString().padLeft(2, '0')}/${now.year}';
  }

  String _buildReceiptContent() {
    return 'M4 FAMILY - BOOKING RECEIPT\n'
        '============================\n\n'
        'Receipt No: #${_receiptId.isNotEmpty ? _receiptId : _fallbackReceipt}\n'
        'Project: $_projectTitle\n'
        'Amount Paid: ₹$_amount\n'
        'Status: VERIFIED\n'
        'Date: ${_formattedDate()}\n\n'
        'Thank you for your booking!\n'
        'For support, contact: support@m4family.com';
  }

  Future<void> _handleSaveReceipt() async {
    // Mobile parity for the web text-file download: share the receipt text so the
    // user can save it to Files / Notes / etc. Clipboard fallback on failure.
    final content = _buildReceiptContent();
    try {
      await Share.share(content, subject: 'M4 Family Booking Receipt');
    } catch (_) {
      await Clipboard.setData(ClipboardData(text: content));
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Receipt copied to clipboard')),
        );
      }
    }
  }

  Future<void> _handleShare() async {
    final text =
        "I've successfully booked a unit in $_projectTitle! 🎉\n\n"
        'Receipt: #${_receiptId.isNotEmpty ? _receiptId : _fallbackReceipt}\n'
        'Amount: ₹$_amount';
    try {
      await Share.share(text, subject: 'M4 Family Booking Confirmed');
    } catch (_) {
      await Clipboard.setData(ClipboardData(text: text));
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Booking details copied to clipboard')),
        );
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final textPrimary = isDark ? Colors.white : Colors.black;
    final muted = (isDark ? Colors.white : Colors.black).withValues(alpha: 0.4);

    if (_loading) {
      return Scaffold(
        backgroundColor: isDark ? const Color(0xFF0F1115) : Colors.white,
        body: const Center(
          child: CircularProgressIndicator(color: M4Theme.premiumBlue),
        ),
      );
    }

    return Scaffold(
      backgroundColor: isDark ? const Color(0xFF0F1115) : Colors.white,
      body: Stack(
        children: [
          // Decorative background circles
          Positioned(
            top: -120,
            right: -100,
            child: Container(
              width: 320,
              height: 320,
              decoration: BoxDecoration(
                color: M4Theme.premiumBlue.withValues(alpha: 0.05),
                shape: BoxShape.circle,
              ),
            ),
          ).animate().fadeIn(duration: 1000.ms),
          Positioned(
            bottom: -140,
            left: -120,
            child: Container(
              width: 300,
              height: 300,
              decoration: BoxDecoration(
                color: M4Theme.premiumBlue.withValues(alpha: 0.05),
                shape: BoxShape.circle,
              ),
            ),
          ).animate().fadeIn(duration: 1200.ms),

          SafeArea(
            child: SingleChildScrollView(
              padding: const EdgeInsets.symmetric(horizontal: 32, vertical: 24),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.center,
                children: [
                  // Back button (top-left)
                  Align(
                    alignment: Alignment.centerLeft,
                    child: GestureDetector(
                      onTap: () => Navigator.pop(context),
                      child: Container(
                        width: 56,
                        height: 56,
                        decoration: BoxDecoration(
                          color: isDark ? Colors.white.withValues(alpha: 0.05) : Colors.white,
                          borderRadius: BorderRadius.circular(20),
                          border: Border.all(
                            color: isDark
                                ? Colors.white.withValues(alpha: 0.1)
                                : Colors.black.withValues(alpha: 0.05),
                          ),
                          boxShadow: isDark
                              ? []
                              : [
                                  BoxShadow(
                                    color: Colors.black.withValues(alpha: 0.05),
                                    blurRadius: 20,
                                    offset: const Offset(0, 10),
                                  )
                                ],
                        ),
                        child: Icon(LucideIcons.arrowLeft, color: textPrimary, size: 24),
                      ),
                    ),
                  ),

                  const SizedBox(height: 32),

                  // Success icon
                  Container(
                    width: 96,
                    height: 96,
                    decoration: BoxDecoration(
                      color: isDark ? Colors.white.withValues(alpha: 0.05) : Colors.white,
                      borderRadius: BorderRadius.circular(32),
                      border: Border.all(
                        color: isDark
                            ? Colors.white.withValues(alpha: 0.1)
                            : Colors.black.withValues(alpha: 0.05),
                      ),
                      boxShadow: [
                        BoxShadow(
                          color: M4Theme.premiumBlue.withValues(alpha: 0.15),
                          blurRadius: 40,
                          offset: const Offset(0, 20),
                        ),
                      ],
                    ),
                    child: const Icon(LucideIcons.checkCircle2,
                        color: M4Theme.premiumBlue, size: 48),
                  )
                      .animate()
                      .fadeIn(duration: 400.ms)
                      .scale(
                        begin: const Offset(0, 0),
                        end: const Offset(1, 1),
                        curve: Curves.elasticOut,
                        duration: 700.ms,
                      )
                      .rotate(begin: -0.06, end: 0, duration: 700.ms),

                  const SizedBox(height: 32),

                  // Header
                  Text(
                    'BOOKING\nCONFIRMED!',
                    textAlign: TextAlign.center,
                    style: GoogleFonts.montserrat(
                      fontSize: 30,
                      fontWeight: FontWeight.w900,
                      color: textPrimary,
                      height: 0.9,
                      letterSpacing: -2,
                    ),
                  ).animate().fadeIn(delay: 200.ms).moveY(begin: -20, end: 0),

                  const SizedBox(height: 16),

                  // Subtitle with highlighted project title
                  Text.rich(
                    TextSpan(
                      style: GoogleFonts.montserrat(
                        fontSize: 9,
                        fontWeight: FontWeight.w900,
                        color: muted,
                        letterSpacing: 2.5,
                        height: 1.8,
                      ),
                      children: [
                        const TextSpan(
                            text: "CONGRATULATIONS! YOU'VE SUCCESSFULLY LOCKED YOUR UNIT IN "),
                        TextSpan(
                          text: _projectTitle.toUpperCase(),
                          style: GoogleFonts.montserrat(
                            fontSize: 9,
                            fontWeight: FontWeight.w900,
                            color: M4Theme.premiumBlue,
                            letterSpacing: 2.5,
                            height: 1.8,
                          ),
                        ),
                        const TextSpan(text: '.'),
                      ],
                    ),
                    textAlign: TextAlign.center,
                  ).animate().fadeIn(delay: 400.ms).moveY(begin: -10, end: 0),

                  const SizedBox(height: 40),

                  // Receipt card
                  _buildReceiptCard(isDark, textPrimary, muted)
                      .animate()
                      .fadeIn(delay: 600.ms)
                      .moveY(begin: 20, end: 0),

                  const SizedBox(height: 32),

                  // Action buttons
                  Row(
                    children: [
                      Expanded(
                        child: _ActionButton(
                          icon: LucideIcons.download,
                          label: 'SAVE RECEIPT',
                          isDark: isDark,
                          onTap: _handleSaveReceipt,
                        ),
                      ),
                      const SizedBox(width: 16),
                      Expanded(
                        child: _ActionButton(
                          icon: LucideIcons.share2,
                          label: 'SHARE NOW',
                          isDark: isDark,
                          onTap: _handleShare,
                        ),
                      ),
                    ],
                  ).animate().fadeIn(delay: 800.ms).moveY(begin: 10, end: 0),

                  const SizedBox(height: 24),

                  // Primary CTA
                  _PressableScale(
                    onTap: () {
                      try {
                        context.go('/cp/dashboard');
                      } catch (_) {
                        Navigator.of(context).popUntil((route) => route.isFirst);
                      }
                    },
                    child: Container(
                      width: double.infinity,
                      height: 64,
                      decoration: BoxDecoration(
                        color: isDark ? Colors.white : Colors.black,
                        borderRadius: BorderRadius.circular(32),
                      ),
                      child: Row(
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: [
                          Icon(LucideIcons.home,
                              color: isDark ? Colors.black : Colors.white, size: 18),
                          const SizedBox(width: 14),
                          Text(
                            'BACK TO DASHBOARD',
                            style: GoogleFonts.montserrat(
                              color: isDark ? Colors.black : Colors.white,
                              fontWeight: FontWeight.w900,
                              fontSize: 12,
                              letterSpacing: 2,
                            ),
                          ),
                        ],
                      ),
                    ),
                  ).animate().fadeIn(delay: 1000.ms).moveY(begin: 10, end: 0),

                  const SizedBox(height: 32),

                  // Help link
                  GestureDetector(
                    onTap: () {
                      try {
                        context.push('/cp/support');
                      } catch (_) {}
                    },
                    child: Text(
                      'NEED HELP WITH YOUR BOOKING?',
                      style: GoogleFonts.montserrat(
                        fontSize: 10,
                        fontWeight: FontWeight.w900,
                        color: muted,
                        letterSpacing: 2,
                        decoration: TextDecoration.underline,
                        decorationColor: muted,
                      ),
                    ),
                  ).animate().fadeIn(delay: 1100.ms),

                  const SizedBox(height: 48),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildReceiptCard(bool isDark, Color textPrimary, Color muted) {
    final divider = isDark
        ? Colors.white.withValues(alpha: 0.08)
        : Colors.black.withValues(alpha: 0.06);

    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(28),
      decoration: BoxDecoration(
        color: isDark ? Colors.white.withValues(alpha: 0.02) : Colors.white,
        borderRadius: BorderRadius.circular(40),
        border: Border.all(
          color: isDark
              ? Colors.white.withValues(alpha: 0.08)
              : Colors.black.withValues(alpha: 0.06),
        ),
        boxShadow: isDark
            ? []
            : [
                BoxShadow(
                  color: Colors.black.withValues(alpha: 0.08),
                  blurRadius: 40,
                  offset: const Offset(0, 20),
                )
              ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Receipt ID
          Padding(
            padding: const EdgeInsets.only(bottom: 24),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  'RECEIPT ID',
                  style: GoogleFonts.montserrat(
                    fontSize: 10,
                    fontWeight: FontWeight.w900,
                    color: muted,
                    letterSpacing: 2,
                  ),
                ),
                const SizedBox(height: 6),
                Text(
                  '#${(_receiptId.isNotEmpty ? _receiptId : _fallbackReceipt).toUpperCase()}',
                  style: GoogleFonts.montserrat(
                    fontSize: 14,
                    fontWeight: FontWeight.w900,
                    color: textPrimary,
                    letterSpacing: -0.5,
                  ),
                ),
              ],
            ),
          ),
          Divider(height: 1, color: divider),
          const SizedBox(height: 24),

          // Project
          _DetailRow(label: 'PROJECT', muted: muted, child: Text(
            _projectTitle.toUpperCase(),
            style: GoogleFonts.montserrat(
              fontSize: 14,
              fontWeight: FontWeight.w900,
              color: textPrimary,
              letterSpacing: -0.5,
            ),
          )),

          const SizedBox(height: 20),

          // Amount + Status side-by-side
          Row(
            crossAxisAlignment: CrossAxisAlignment.end,
            children: [
              Expanded(
                child: _DetailRow(
                  label: 'AMOUNT PAID',
                  muted: muted,
                  child: Text(
                    '₹$_amount',
                    style: GoogleFonts.montserrat(
                      fontSize: 14,
                      fontWeight: FontWeight.w900,
                      color: M4Theme.premiumBlue,
                      letterSpacing: -0.5,
                    ),
                  ),
                ),
              ),
              const SizedBox(width: 16),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.end,
                  children: [
                    Text(
                      'STATUS',
                      style: GoogleFonts.montserrat(
                        fontSize: 9,
                        fontWeight: FontWeight.w900,
                        color: muted,
                        letterSpacing: 2,
                      ),
                    ),
                    const SizedBox(height: 8),
                    Container(
                      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
                      decoration: BoxDecoration(
                        color: const Color(0xFF10B981).withValues(alpha: 0.1),
                        borderRadius: BorderRadius.circular(999),
                      ),
                      child: Row(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          const Icon(LucideIcons.checkCircle2,
                              color: Color(0xFF10B981), size: 12),
                          const SizedBox(width: 6),
                          Text(
                            'VERIFIED',
                            style: GoogleFonts.montserrat(
                              fontSize: 8,
                              fontWeight: FontWeight.w900,
                              color: const Color(0xFF10B981),
                              letterSpacing: 2,
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
        ],
      ),
    );
  }
}

class _DetailRow extends StatelessWidget {
  final String label;
  final Color muted;
  final Widget child;

  const _DetailRow({required this.label, required this.muted, required this.child});

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          label,
          style: GoogleFonts.montserrat(
            fontSize: 9,
            fontWeight: FontWeight.w900,
            color: muted,
            letterSpacing: 2,
          ),
        ),
        const SizedBox(height: 6),
        child,
      ],
    );
  }
}

class _ActionButton extends StatelessWidget {
  final IconData icon;
  final String label;
  final bool isDark;
  final VoidCallback onTap;

  const _ActionButton({
    required this.icon,
    required this.label,
    required this.isDark,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return _PressableScale(
      onTap: onTap,
      child: Container(
        height: 56,
        decoration: BoxDecoration(
          color: isDark ? Colors.white.withValues(alpha: 0.03) : Colors.white,
          borderRadius: BorderRadius.circular(24),
          border: Border.all(
            color: isDark
                ? Colors.white.withValues(alpha: 0.08)
                : Colors.black.withValues(alpha: 0.06),
          ),
          boxShadow: isDark
              ? []
              : [
                  BoxShadow(
                    color: Colors.black.withValues(alpha: 0.04),
                    blurRadius: 20,
                    offset: const Offset(0, 10),
                  )
                ],
        ),
        child: Row(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(icon, color: M4Theme.premiumBlue, size: 16),
            const SizedBox(width: 8),
            Flexible(
              child: Text(
                label,
                overflow: TextOverflow.ellipsis,
                style: GoogleFonts.montserrat(
                  fontSize: 8,
                  fontWeight: FontWeight.w900,
                  color: isDark ? Colors.white : Colors.black,
                  letterSpacing: 1.5,
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}

/// Simple press-feedback wrapper used across booking screens.
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
        scale: _pressed ? 0.95 : 1.0,
        duration: const Duration(milliseconds: 120),
        child: widget.child,
      ),
    );
  }
}
