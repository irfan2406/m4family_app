import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:lucide_icons/lucide_icons.dart';
import 'package:m4_mobile/core/theme/app_theme.dart';
import 'package:m4_mobile/presentation/providers/auth_provider.dart' show apiClientProvider;

/// Web `/investor/referral/closed` parity (web `app/investor/referral/closed/page.tsx`):
/// the "Success Vault" — closed/credited referrals that converted into bookings.
/// Shows referral name, project, converted badge, unit config, date closed and
/// the reward (commission) points earned. Data: `/api/investor/referrals`
/// filtered by status IN [CLOSED, CREDITED, BOOKING_DONE, Booked].
class InvestorReferralClosedScreen extends ConsumerStatefulWidget {
  const InvestorReferralClosedScreen({super.key});

  @override
  ConsumerState<InvestorReferralClosedScreen> createState() =>
      _InvestorReferralClosedScreenState();
}

class _InvestorReferralClosedScreenState
    extends ConsumerState<InvestorReferralClosedScreen> {
  static const _gold = Color(0xFFFFD700);
  static const _emerald = Color(0xFF10B981);

  // Statuses considered closed/credited (the only ones shown here).
  static const _closedStatuses = ['CLOSED', 'CREDITED', 'BOOKING_DONE', 'Booked'];

  List<dynamic> _referrals = [];
  bool _loading = true;
  bool _error = false;

  @override
  void initState() {
    super.initState();
    _load();
  }

  Future<void> _load() async {
    setState(() {
      _loading = true;
      _error = false;
    });
    try {
      final api = ref.read(apiClientProvider);
      final res = await api.get('/api/investor/referrals');
      if (!mounted) return;
      if (res.statusCode == 200 && res.data['status'] == true) {
        final data = res.data['data'];
        final list = data is List ? List<dynamic>.from(data) : <dynamic>[];
        _referrals = list
            .where((r) => _closedStatuses.contains(_status(r)))
            .toList();
      } else {
        _error = true;
      }
    } catch (_) {
      if (mounted) _error = true;
    }
    if (mounted) setState(() => _loading = false);
  }

  // ─── Derived data ──────────────────────────────────────────────
  String _status(dynamic r) => (r['status'] ?? 'CLOSED').toString();

  String _name(dynamic r) =>
      (r['referralName'] ?? r['clientName'] ?? 'Referral').toString();

  String _project(dynamic r) {
    final pid = r['projectId'];
    if (pid is Map) return (pid['title'] ?? 'M4 Project').toString();
    return (r['projectName'] ?? 'M4 Project').toString();
  }

  String _unitConfig(dynamic r) {
    final booking = r['bookingId'];
    if (booking is Map) {
      final config = (booking['configuration'] ?? '').toString().trim();
      final unit = (booking['unitNumber'] ?? '').toString().trim();
      if (config.isNotEmpty && unit.isNotEmpty) return '$config - Unit $unit';
      if (config.isNotEmpty) return config;
      if (unit.isNotEmpty) return 'Unit $unit';
    }
    return 'Premium Suite';
  }

  num _points(dynamic r) {
    final p = r['pointsEarned'] ?? r['rewardAmount'] ?? r['points'] ?? 0;
    return p is num ? p : (num.tryParse(p.toString()) ?? 0);
  }

  String _closedDate(dynamic r) {
    final raw = r['closedAt'] ?? r['creditedAt'] ?? r['updatedAt'] ?? r['createdAt'];
    if (raw == null) return '';
    final parsed = DateTime.tryParse(raw.toString());
    if (parsed == null) return '';
    final d = parsed.toLocal();
    String two(int n) => n.toString().padLeft(2, '0');
    return '${two(d.day)}/${two(d.month)}/${d.year}';
  }

  // ━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━
  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final bg = isDark ? Colors.black : Colors.white;
    final textPrimary = isDark ? Colors.white : Colors.black;
    final muted = (isDark ? Colors.white : Colors.black).withValues(alpha: 0.5);
    final border = isDark
        ? Colors.white.withValues(alpha: 0.08)
        : Colors.black.withValues(alpha: 0.06);

    return Scaffold(
      backgroundColor: bg,
      body: SafeArea(
        child: Column(
          children: [
            _buildHeader(textPrimary, muted, border),
            Expanded(
              child: _loading
                  ? const Center(
                      child: CircularProgressIndicator(
                        color: M4Theme.premiumBlue,
                        strokeWidth: 2,
                      ),
                    )
                  : _error
                      ? _buildError(muted)
                      : _referrals.isEmpty
                          ? _buildEmpty(muted)
                          : _buildList(isDark, textPrimary, muted, border),
            ),
          ],
        ),
      ),
    );
  }

  // ─── Header ──────────────────────────────────────────────────────────────
  Widget _buildHeader(Color textPrimary, Color muted, Color border) {
    return Padding(
      padding: const EdgeInsets.fromLTRB(24, 20, 24, 16),
      child: Row(
        children: [
          GestureDetector(
            onTap: () {
              if (context.canPop()) {
                context.pop();
              } else {
                context.go('/investor/home');
              }
            },
            child: Container(
              padding: const EdgeInsets.all(10),
              decoration: BoxDecoration(
                shape: BoxShape.circle,
                border: Border.all(color: border),
              ),
              child: Icon(LucideIcons.arrowLeft, size: 16, color: textPrimary),
            ),
          ),
          Expanded(
            child: Column(
              children: [
                Text(
                  'SUCCESS VAULT',
                  textAlign: TextAlign.center,
                  style: GoogleFonts.montserrat(
                    fontSize: 13,
                    fontWeight: FontWeight.w900,
                    letterSpacing: 2,
                    color: textPrimary,
                  ),
                ),
                const SizedBox(height: 4),
                Text(
                  'CLOSED CONVERSIONS',
                  textAlign: TextAlign.center,
                  style: GoogleFonts.montserrat(
                    fontSize: 8,
                    fontWeight: FontWeight.w900,
                    letterSpacing: 3,
                    color: muted,
                  ),
                ),
              ],
            ),
          ),
          const SizedBox(width: 36),
        ],
      ),
    );
  }

  // ─── List ────────────────────────────────────────────────────────────────
  Widget _buildList(bool isDark, Color textPrimary, Color muted, Color border) {
    final card = isDark ? Colors.white.withValues(alpha: 0.03) : Colors.white;

    return RefreshIndicator(
      onRefresh: _load,
      color: M4Theme.premiumBlue,
      child: ListView(
        physics: const AlwaysScrollableScrollPhysics(),
        padding: const EdgeInsets.fromLTRB(24, 8, 24, 100),
        children: [
          // Count summary chip
          Row(
            children: [
              const Icon(LucideIcons.trophy, size: 14, color: _gold),
              const SizedBox(width: 8),
              Text(
                '${_referrals.length} CONVERTED',
                style: GoogleFonts.montserrat(
                  fontSize: 9,
                  fontWeight: FontWeight.w900,
                  letterSpacing: 2,
                  color: muted,
                ),
              ),
            ],
          ),
          const SizedBox(height: 16),
          ..._referrals.map(
            (r) => _buildCard(r, card, textPrimary, muted, border),
          ),
        ],
      ),
    );
  }

  Widget _buildCard(
    dynamic r,
    Color card,
    Color textPrimary,
    Color muted,
    Color border,
  ) {
    final name = _name(r);
    final project = _project(r);
    final unitConfig = _unitConfig(r);
    final points = _points(r);
    final date = _closedDate(r);

    return Container(
      margin: const EdgeInsets.only(bottom: 16),
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: card,
        borderRadius: BorderRadius.circular(28),
        border: Border.all(color: border),
      ),
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
                    Row(
                      children: [
                        Flexible(
                          child: Text(
                            name,
                            style: GoogleFonts.montserrat(
                              fontSize: 15,
                              fontWeight: FontWeight.w900,
                              color: textPrimary,
                            ),
                          ),
                        ),
                        const SizedBox(width: 6),
                        const Icon(
                          LucideIcons.badgeCheck,
                          size: 16,
                          color: _emerald,
                        ),
                      ],
                    ),
                    const SizedBox(height: 4),
                    Text(
                      project.toUpperCase(),
                      style: GoogleFonts.montserrat(
                        fontSize: 9,
                        fontWeight: FontWeight.w900,
                        letterSpacing: 1.5,
                        color: muted,
                      ),
                    ),
                  ],
                ),
              ),
              const SizedBox(width: 12),
              _buildConvertedBadge(),
            ],
          ),
          const SizedBox(height: 16),
          Divider(height: 1, color: border),
          const SizedBox(height: 16),
          Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // Unit config
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(
                      children: [
                        Icon(LucideIcons.hardDrive, size: 11, color: muted),
                        const SizedBox(width: 5),
                        Text(
                          'UNIT CONFIG',
                          style: GoogleFonts.montserrat(
                            fontSize: 7,
                            fontWeight: FontWeight.w900,
                            letterSpacing: 1.5,
                            color: muted,
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 6),
                    Text(
                      unitConfig.toUpperCase(),
                      style: GoogleFonts.montserrat(
                        fontSize: 10,
                        fontWeight: FontWeight.w900,
                        color: textPrimary,
                      ),
                    ),
                  ],
                ),
              ),
              const SizedBox(width: 12),
              // Reward earned
              Column(
                crossAxisAlignment: CrossAxisAlignment.end,
                children: [
                  Text(
                    'REWARD EARNED',
                    style: GoogleFonts.montserrat(
                      fontSize: 7,
                      fontWeight: FontWeight.w900,
                      letterSpacing: 1.5,
                      color: muted,
                    ),
                  ),
                  const SizedBox(height: 6),
                  Text(
                    '+${_formatNumber(points)} PTS',
                    style: GoogleFonts.montserrat(
                      fontSize: 12,
                      fontWeight: FontWeight.w900,
                      color: _emerald,
                    ),
                  ),
                ],
              ),
            ],
          ),
          if (date.isNotEmpty) ...[
            const SizedBox(height: 14),
            Row(
              children: [
                Icon(LucideIcons.calendarCheck, size: 11, color: muted),
                const SizedBox(width: 6),
                Text(
                  'CLOSED $date',
                  style: GoogleFonts.montserrat(
                    fontSize: 8,
                    fontWeight: FontWeight.w900,
                    letterSpacing: 1.5,
                    color: muted,
                  ),
                ),
              ],
            ),
          ],
        ],
      ),
    );
  }

  Widget _buildConvertedBadge() {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
      decoration: BoxDecoration(
        color: _emerald.withValues(alpha: 0.1),
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: _emerald.withValues(alpha: 0.2)),
      ),
      child: Text(
        'CONVERTED',
        style: GoogleFonts.montserrat(
          fontSize: 8,
          fontWeight: FontWeight.w900,
          letterSpacing: 1,
          color: _emerald,
        ),
      ),
    );
  }

  // ─── Empty ───────────────────────────────────────────────────────────────
  Widget _buildEmpty(Color muted) {
    return RefreshIndicator(
      onRefresh: _load,
      color: M4Theme.premiumBlue,
      child: ListView(
        physics: const AlwaysScrollableScrollPhysics(),
        children: [
          SizedBox(height: MediaQuery.of(context).size.height * 0.28),
          Icon(
            LucideIcons.trophy,
            size: 48,
            color: muted.withValues(alpha: 0.4),
          ),
          const SizedBox(height: 20),
          Text(
            'NO CLOSED REFERRALS YET',
            textAlign: TextAlign.center,
            style: GoogleFonts.montserrat(
              fontSize: 10,
              fontWeight: FontWeight.w900,
              letterSpacing: 2,
              color: muted,
            ),
          ),
        ],
      ),
    );
  }

  // ─── Error ───────────────────────────────────────────────────────────────
  Widget _buildError(Color muted) {
    return Center(
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(LucideIcons.alertCircle, size: 44, color: muted),
          const SizedBox(height: 16),
          Text(
            'COULD NOT LOAD SUCCESS VAULT',
            style: GoogleFonts.montserrat(
              fontSize: 10,
              fontWeight: FontWeight.w900,
              letterSpacing: 2,
              color: muted,
            ),
          ),
          const SizedBox(height: 20),
          GestureDetector(
            onTap: _load,
            child: Container(
              padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 12),
              decoration: BoxDecoration(
                color: M4Theme.premiumBlue,
                borderRadius: BorderRadius.circular(12),
              ),
              child: Text(
                'RETRY',
                style: GoogleFonts.montserrat(
                  fontSize: 10,
                  fontWeight: FontWeight.w900,
                  letterSpacing: 2,
                  color: Colors.white,
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }

  // ─── Utilities ─────────────────────────────────────────────────
  String _formatNumber(num value) {
    final s = value.toStringAsFixed(0);
    final buffer = StringBuffer();
    final digits = s.replaceFirst('-', '');
    final neg = s.startsWith('-');
    for (int i = 0; i < digits.length; i++) {
      if (i != 0 && (digits.length - i) % 3 == 0) buffer.write(',');
      buffer.write(digits[i]);
    }
    return neg ? '-${buffer.toString()}' : buffer.toString();
  }
}
