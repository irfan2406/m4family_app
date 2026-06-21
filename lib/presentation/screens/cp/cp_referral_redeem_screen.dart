import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:lucide_icons/lucide_icons.dart';
import 'package:m4_mobile/presentation/providers/auth_provider.dart';

/// Web `/cp/referral/redeem` parity: wallet balance + redemption matrix +
/// volume input + confirm. Mirrors the web prototype, which validates &
/// confirms client-side (no dedicated CP redeem endpoint exists in the backend).
class CpReferralRedeemScreen extends ConsumerStatefulWidget {
  const CpReferralRedeemScreen({super.key});

  @override
  ConsumerState<CpReferralRedeemScreen> createState() => _CpReferralRedeemScreenState();
}

class _CpReferralRedeemScreenState extends ConsumerState<CpReferralRedeemScreen> {
  final TextEditingController _amountController = TextEditingController();

  String? _selectedOption;
  num _balance = 0;
  bool _loading = true;
  bool _submitting = false;

  // Mirrors the web `redeemOptions` matrix (id / title / rate / minPoints).
  static const List<Map<String, dynamic>> _options = [
    {
      'id': 'wallet',
      'title': 'M4 WALLET CREDIT',
      'subtitle': '1 POINT = ₹1',
      'icon': LucideIcons.wallet,
      'min': 100,
    },
    {
      'id': 'discount',
      'title': 'BOOKING DISCOUNT',
      'subtitle': '1 POINT = ₹1',
      'icon': LucideIcons.creditCard,
      'min': 500,
    },
    {
      'id': 'voucher',
      'title': 'SHOPPING VOUCHERS',
      'subtitle': '100 POINTS = ₹80',
      'icon': LucideIcons.shoppingBag,
      'min': 1000,
    },
    {
      'id': 'premium',
      'title': 'PRIORITY CONCIERGE',
      'subtitle': 'FIXED: 2000 POINTS',
      'icon': LucideIcons.zap,
      'min': 2000,
    },
  ];

  @override
  void initState() {
    super.initState();
    _load();
  }

  @override
  void dispose() {
    _amountController.dispose();
    super.dispose();
  }

  Future<void> _load() async {
    setState(() => _loading = true);
    try {
      final api = ref.read(apiClientProvider);
      final w = await api.getCpWallet();
      if (!mounted) return;
      if (w.statusCode == 200 && w.data['status'] == true) {
        final d = w.data['data'];
        if (d is Map) {
          _balance = (d['balance'] ?? d['availableBalance'] ?? 0) as num? ?? 0;
        }
      }
    } catch (_) {}
    if (mounted) setState(() => _loading = false);
  }

  void _handleRedeem() {
    if (_submitting) return;
    final option = _options.firstWhere(
      (o) => o['id'] == _selectedOption,
      orElse: () => const {},
    );
    if (option.isEmpty) {
      _snack('Please select a redemption option', error: true);
      return;
    }

    final points = int.tryParse(_amountController.text.trim()) ?? 0;
    final min = option['min'] as int? ?? 0;

    if (points < min) {
      _snack('Minimum $min points required', error: true);
      return;
    }
    if (points > _balance) {
      _snack('Insufficient points', error: true);
      return;
    }

    setState(() => _submitting = true);
    _snack('$points points redeemed for ${option['title']}');
    Future.delayed(const Duration(milliseconds: 1200), () {
      if (!mounted) return;
      if (context.canPop()) {
        context.pop(true);
      } else {
        context.go('/cp/referral');
      }
    });
  }

  void _snack(String msg, {bool error = false}) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(msg),
        backgroundColor: error ? Colors.redAccent : Colors.green,
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final scheme = Theme.of(context).colorScheme;
    final isDark = Theme.of(context).brightness == Brightness.dark;

    return Scaffold(
      backgroundColor: Theme.of(context).scaffoldBackgroundColor,
      body: SafeArea(
        child: Column(
          children: [
            // ─── Header ──────────────────────────────────────────
            Padding(
              padding: const EdgeInsets.fromLTRB(24, 20, 24, 20),
              child: Row(
                children: [
                  GestureDetector(
                    onTap: () {
                      if (context.canPop()) {
                        context.pop();
                      } else {
                        context.go('/cp/referral');
                      }
                    },
                    child: Container(
                      padding: const EdgeInsets.all(10),
                      decoration: BoxDecoration(
                        color: scheme.onSurface.withValues(alpha: 0.05),
                        shape: BoxShape.circle,
                        border: Border.all(color: scheme.onSurface.withValues(alpha: 0.1)),
                      ),
                      child: Icon(LucideIcons.arrowLeft, size: 16, color: scheme.onSurface),
                    ),
                  ),
                  Expanded(
                    child: Column(
                      children: [
                        Text(
                          'REDEEM REWARDS',
                          textAlign: TextAlign.center,
                          style: GoogleFonts.montserrat(
                            fontSize: 16,
                            fontWeight: FontWeight.w900,
                            color: scheme.onSurface,
                            letterSpacing: 1.5,
                          ),
                        ),
                        const SizedBox(height: 2),
                        Text(
                          'CONVERT YOUR POINTS',
                          textAlign: TextAlign.center,
                          style: GoogleFonts.montserrat(
                            fontSize: 8,
                            fontWeight: FontWeight.w900,
                            color: scheme.onSurface.withValues(alpha: 0.4),
                            letterSpacing: 2,
                          ),
                        ),
                      ],
                    ),
                  ),
                  const SizedBox(width: 36),
                ],
              ),
            ),

            // ─── Body ────────────────────────────────────────────
            Expanded(
              child: _loading
                  ? Center(child: CircularProgressIndicator(color: scheme.onSurface, strokeWidth: 2))
                  : RefreshIndicator(
                      onRefresh: _load,
                      color: scheme.onSurface,
                      child: SingleChildScrollView(
                        physics: const AlwaysScrollableScrollPhysics(),
                        padding: const EdgeInsets.symmetric(horizontal: 24),
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            const SizedBox(height: 12),
                            _buildWalletCard(scheme, isDark),
                            const SizedBox(height: 28),

                            Text(
                              'REDEMPTION MATRIX',
                              style: GoogleFonts.montserrat(
                                fontSize: 9,
                                fontWeight: FontWeight.w900,
                                letterSpacing: 2,
                                color: scheme.onSurface.withValues(alpha: 0.4),
                              ),
                            ),
                            const SizedBox(height: 16),
                            ..._options.map((o) => _buildOption(o, scheme, isDark)),

                            if (_selectedOption != null) ...[
                              const SizedBox(height: 12),
                              _buildVolumeInput(scheme, isDark),
                            ],

                            const SizedBox(height: 28),
                            _buildConfirmButton(scheme, isDark),
                            const SizedBox(height: 60),
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

  // ━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━
  // WALLET CARD
  // ━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━
  Widget _buildWalletCard(ColorScheme scheme, bool isDark) {
    return Container(
      width: double.infinity,
      decoration: BoxDecoration(
        color: isDark ? const Color(0xFF1C1C1E) : Colors.white,
        borderRadius: BorderRadius.circular(40),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: isDark ? 0.3 : 0.08),
            blurRadius: 30,
            offset: const Offset(0, 15),
          ),
        ],
      ),
      child: Stack(
        children: [
          // Ghost gift icon (top-right, faint)
          Positioned(
            right: 16,
            top: 24,
            child: Opacity(
              opacity: isDark ? 0.05 : 0.03,
              child: Icon(LucideIcons.gift, size: 120, color: scheme.onSurface),
            ),
          ),
          Padding(
            padding: const EdgeInsets.all(32),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.center,
              children: [
                Text(
                  'AVAILABLE BALANCE',
                  style: GoogleFonts.montserrat(
                    fontSize: 9,
                    fontWeight: FontWeight.w900,
                    letterSpacing: 2,
                    color: scheme.onSurface.withValues(alpha: 0.4),
                  ),
                ),
                const SizedBox(height: 16),
                Row(
                  mainAxisAlignment: MainAxisAlignment.center,
                  crossAxisAlignment: CrossAxisAlignment.baseline,
                  textBaseline: TextBaseline.alphabetic,
                  children: [
                    Text(
                      _formatNumber(_balance),
                      style: GoogleFonts.montserrat(
                        fontSize: 44,
                        fontWeight: FontWeight.w900,
                        color: scheme.onSurface,
                        height: 1,
                      ),
                    ),
                    const SizedBox(width: 8),
                    Text(
                      'PTS',
                      style: GoogleFonts.montserrat(
                        fontSize: 16,
                        fontWeight: FontWeight.w900,
                        color: scheme.onSurface.withValues(alpha: 0.3),
                        letterSpacing: 2,
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 16),
                Container(
                  padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 6),
                  decoration: BoxDecoration(
                    color: scheme.onSurface.withValues(alpha: 0.05),
                    borderRadius: BorderRadius.circular(20),
                    border: Border.all(color: scheme.onSurface.withValues(alpha: 0.08)),
                  ),
                  child: Text(
                    'VALUE: ₹${_formatNumber(_balance)}',
                    style: GoogleFonts.montserrat(
                      fontSize: 9,
                      fontWeight: FontWeight.w900,
                      letterSpacing: 1.5,
                      color: scheme.onSurface,
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

  // ━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━
  // OPTION CARD
  // ━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━
  Widget _buildOption(Map<String, dynamic> opt, ColorScheme scheme, bool isDark) {
    final isSelected = _selectedOption == opt['id'];
    return GestureDetector(
      onTap: () => setState(() => _selectedOption = opt['id'] as String),
      child: Container(
        margin: const EdgeInsets.only(bottom: 12),
        padding: const EdgeInsets.all(18),
        decoration: BoxDecoration(
          color: isDark ? scheme.onSurface.withValues(alpha: 0.03) : Colors.white,
          borderRadius: BorderRadius.circular(20),
          border: Border.all(
            color: isSelected ? scheme.onSurface : scheme.onSurface.withValues(alpha: 0.08),
            width: isSelected ? 2 : 1,
          ),
          boxShadow: isDark
              ? null
              : [
                  BoxShadow(
                    color: Colors.black.withValues(alpha: 0.02),
                    blurRadius: 10,
                    offset: const Offset(0, 5),
                  ),
                ],
        ),
        child: Row(
          children: [
            Container(
              padding: const EdgeInsets.all(12),
              decoration: BoxDecoration(
                color: scheme.onSurface.withValues(alpha: 0.04),
                borderRadius: BorderRadius.circular(14),
                border: Border.all(color: scheme.onSurface.withValues(alpha: 0.08)),
              ),
              child: Icon(opt['icon'] as IconData, color: scheme.onSurface, size: 20),
            ),
            const SizedBox(width: 16),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    opt['title'] as String,
                    style: GoogleFonts.montserrat(
                      fontSize: 13,
                      fontWeight: FontWeight.w800,
                      color: scheme.onSurface,
                    ),
                  ),
                  const SizedBox(height: 3),
                  Text(
                    opt['subtitle'] as String,
                    style: GoogleFonts.montserrat(
                      fontSize: 9,
                      fontWeight: FontWeight.w900,
                      letterSpacing: 1.5,
                      color: scheme.onSurface.withValues(alpha: 0.4),
                    ),
                  ),
                ],
              ),
            ),
            if (isSelected)
              Icon(LucideIcons.checkCircle2, color: scheme.onSurface, size: 22),
          ],
        ),
      ),
    );
  }

  // ━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━
  // VOLUME INPUT (conditional)
  // ━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━
  Widget _buildVolumeInput(ColorScheme scheme, bool isDark) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Padding(
          padding: const EdgeInsets.only(bottom: 12, top: 6),
          child: Text(
            'REDEEM VOLUME',
            style: GoogleFonts.montserrat(
              fontSize: 9,
              fontWeight: FontWeight.w900,
              letterSpacing: 2,
              color: scheme.onSurface.withValues(alpha: 0.4),
            ),
          ),
        ),
        Container(
          decoration: BoxDecoration(
            color: isDark ? scheme.onSurface.withValues(alpha: 0.03) : Colors.white,
            borderRadius: BorderRadius.circular(18),
            border: Border.all(color: scheme.onSurface.withValues(alpha: 0.08)),
          ),
          child: TextField(
            controller: _amountController,
            keyboardType: TextInputType.number,
            inputFormatters: [FilteringTextInputFormatter.digitsOnly],
            textAlign: TextAlign.center,
            onChanged: (_) => setState(() {}),
            style: GoogleFonts.montserrat(
              fontSize: 26,
              fontWeight: FontWeight.w900,
              color: scheme.onSurface,
            ),
            decoration: InputDecoration(
              hintText: '0000',
              hintStyle: GoogleFonts.montserrat(
                fontSize: 26,
                fontWeight: FontWeight.w900,
                color: scheme.onSurface.withValues(alpha: 0.2),
              ),
              border: InputBorder.none,
              contentPadding: const EdgeInsets.symmetric(vertical: 18),
            ),
          ),
        ),
        const SizedBox(height: 14),
        Row(
          children: [
            _buildPreset('500', scheme),
            _buildPreset('1000', scheme),
            _buildPreset('2000', scheme),
            _buildPreset('MAX', scheme, isMax: true),
          ],
        ),
      ],
    );
  }

  Widget _buildPreset(String label, ColorScheme scheme, {bool isMax = false}) {
    return Expanded(
      child: GestureDetector(
        onTap: () => setState(() {
          _amountController.text =
              isMax ? _balance.toInt().toString() : label;
        }),
        child: Container(
          margin: const EdgeInsets.symmetric(horizontal: 4),
          padding: const EdgeInsets.symmetric(vertical: 12),
          decoration: BoxDecoration(
            color: isMax ? scheme.onSurface.withValues(alpha: 0.06) : Colors.transparent,
            borderRadius: BorderRadius.circular(12),
            border: Border.all(color: scheme.onSurface.withValues(alpha: 0.1)),
          ),
          alignment: Alignment.center,
          child: Text(
            label,
            style: GoogleFonts.montserrat(
              fontSize: 9,
              fontWeight: FontWeight.w900,
              letterSpacing: 1.5,
              color: scheme.onSurface.withValues(alpha: isMax ? 1 : 0.5),
            ),
          ),
        ),
      ),
    );
  }

  // ━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━
  // CONFIRM BUTTON
  // ━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━
  Widget _buildConfirmButton(ColorScheme scheme, bool isDark) {
    final isEnabled =
        _selectedOption != null && _amountController.text.trim().isNotEmpty && !_submitting;
    return GestureDetector(
      onTap: isEnabled ? _handleRedeem : null,
      child: Opacity(
        opacity: isEnabled ? 1.0 : 0.3,
        child: Container(
          width: double.infinity,
          height: 56,
          decoration: BoxDecoration(
            color: scheme.onSurface,
            borderRadius: BorderRadius.circular(14),
            boxShadow: [
              BoxShadow(
                color: scheme.onSurface.withValues(alpha: 0.2),
                blurRadius: 15,
                offset: const Offset(0, 8),
              ),
            ],
          ),
          alignment: Alignment.center,
          child: _submitting
              ? SizedBox(
                  width: 20,
                  height: 20,
                  child: CircularProgressIndicator(strokeWidth: 2, color: scheme.surface),
                )
              : Row(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    Icon(LucideIcons.gift, color: scheme.surface, size: 16),
                    const SizedBox(width: 12),
                    Text(
                      'CONFIRM REDEMPTION',
                      style: GoogleFonts.montserrat(
                        fontSize: 11,
                        fontWeight: FontWeight.w900,
                        letterSpacing: 2,
                        color: scheme.surface,
                      ),
                    ),
                  ],
                ),
        ),
      ),
    );
  }

  String _formatNumber(num n) {
    if (n >= 1000) {
      return n.toStringAsFixed(0).replaceAllMapped(
            RegExp(r'(\d)(?=(\d{3})+(?!\d))'),
            (m) => '${m[1]},',
          );
    }
    return n.toStringAsFixed(0);
  }
}
