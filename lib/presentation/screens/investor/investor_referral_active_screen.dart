import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:lucide_icons/lucide_icons.dart';
import 'package:m4_mobile/core/theme/app_theme.dart';
import 'package:m4_mobile/presentation/providers/auth_provider.dart' show apiClientProvider;

/// Web `/investor/referral/active` parity: active (not yet closed/credited)
/// referrals in the lead pipeline. Shows referral name, project, status and
/// referral code. Mirrors the web "Active Referrals — Lead Matrix" page.
class InvestorReferralActiveScreen extends ConsumerStatefulWidget {
  const InvestorReferralActiveScreen({super.key});

  @override
  ConsumerState<InvestorReferralActiveScreen> createState() =>
      _InvestorReferralActiveScreenState();
}

class _InvestorReferralActiveScreenState
    extends ConsumerState<InvestorReferralActiveScreen> {
  // Statuses considered closed/credited (excluded from the active list).
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
            .where((r) => !_closedStatuses.contains(_status(r)))
            .toList();
      } else {
        _error = true;
      }
    } catch (_) {
      if (mounted) _error = true;
    }
    if (mounted) setState(() => _loading = false);
  }

  String _name(dynamic r) =>
      (r['referralName'] ?? r['clientName'] ?? 'Referral').toString();

  String _status(dynamic r) => (r['status'] ?? 'NEW').toString();

  String _project(dynamic r) {
    final pid = r['projectId'];
    if (pid is Map) return (pid['title'] ?? 'M4 Project').toString();
    return (r['projectName'] ?? 'M4 Project').toString();
  }

  String _code(dynamic r) => (r['referralCode'] ?? '').toString();

  String _phone(dynamic r) => (r['referralPhone'] ?? '').toString();

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
                      ? _buildError(textPrimary, muted)
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
                  'ACTIVE REFERRALS',
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
                  'LEAD MATRIX',
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
              Icon(LucideIcons.users, size: 14, color: muted),
              const SizedBox(width: 8),
              Text(
                '${_referrals.length} IN PIPELINE',
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
    final status = _status(r);
    final code = _code(r);
    final phone = _phone(r);

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
                    Text(
                      name,
                      style: GoogleFonts.montserrat(
                        fontSize: 14,
                        fontWeight: FontWeight.w800,
                        color: textPrimary,
                      ),
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
                    if (code.isNotEmpty) ...[
                      const SizedBox(height: 4),
                      Text(
                        code,
                        style: GoogleFonts.montserrat(
                          fontSize: 10,
                          fontWeight: FontWeight.w700,
                          letterSpacing: 1,
                          color: M4Theme.premiumBlue,
                        ),
                      ),
                    ],
                  ],
                ),
              ),
              const SizedBox(width: 12),
              _buildStatusBadge(status, border, muted),
            ],
          ),
          const SizedBox(height: 16),
          Divider(height: 1, color: border),
          const SizedBox(height: 12),
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Row(
                children: [
                  const Icon(
                    LucideIcons.trendingUp,
                    size: 12,
                    color: Color(0xFF10B981),
                  ),
                  const SizedBox(width: 6),
                  Text(
                    'PIPELINE STATUS',
                    style: GoogleFonts.montserrat(
                      fontSize: 8,
                      fontWeight: FontWeight.w900,
                      letterSpacing: 1.5,
                      color: muted,
                    ),
                  ),
                ],
              ),
              if (phone.isNotEmpty)
                Text(
                  phone,
                  style: GoogleFonts.montserrat(
                    fontSize: 10,
                    fontWeight: FontWeight.w900,
                    color: textPrimary,
                  ),
                ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildStatusBadge(String status, Color border, Color muted) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
      decoration: BoxDecoration(
        color: M4Theme.premiumBlue.withValues(alpha: 0.06),
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: border),
      ),
      child: Text(
        status.toUpperCase(),
        style: GoogleFonts.montserrat(
          fontSize: 8,
          fontWeight: FontWeight.w900,
          letterSpacing: 1,
          color: M4Theme.premiumBlue,
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
            LucideIcons.users,
            size: 48,
            color: muted.withValues(alpha: 0.4),
          ),
          const SizedBox(height: 20),
          Text(
            'NO ACTIVE REFERRALS IN PIPELINE',
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
  Widget _buildError(Color textPrimary, Color muted) {
    return Center(
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(LucideIcons.alertCircle, size: 44, color: muted),
          const SizedBox(height: 16),
          Text(
            'COULD NOT LOAD REFERRALS',
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
}
