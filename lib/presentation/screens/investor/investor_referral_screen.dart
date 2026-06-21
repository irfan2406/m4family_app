import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:lucide_icons/lucide_icons.dart';
import 'package:m4_mobile/core/theme/app_theme.dart';
import 'package:m4_mobile/presentation/providers/auth_provider.dart';
import 'package:m4_mobile/presentation/providers/project_provider.dart';

/// Investor `/investor/referral` parity (web `app/investor/referral/page.tsx`):
/// referral code card, stats (points / active / closed), quick redeem, refer &
/// share actions, active referrals list and point history.
/// Data: `/api/investor/wallet`, `/api/investor/referrals`, `/api/rewards/transactions`.
class InvestorReferralScreen extends ConsumerStatefulWidget {
  const InvestorReferralScreen({super.key});

  @override
  ConsumerState<InvestorReferralScreen> createState() => _InvestorReferralScreenState();
}

class _InvestorReferralScreenState extends ConsumerState<InvestorReferralScreen> {
  static const _gold = Color(0xFFFFD700);
  static const _closedStatuses = {'CLOSED', 'CREDITED', 'BOOKING_DONE', 'Booked'};

  Map<String, dynamic>? _wallet;
  List<dynamic> _referrals = [];
  List<dynamic> _transactions = [];
  bool _loading = true;
  bool _error = false;

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) => _load());
  }

  Future<void> _load() async {
    if (mounted) setState(() => _loading = true);
    final api = ref.read(apiClientProvider);
    try {
      final results = await Future.wait([
        api.getInvestorWallet(),
        api.get('/api/investor/referrals'),
        api.get('/api/rewards/transactions'),
      ]);
      if (!mounted) return;
      final w = results[0];
      final r = results[1];
      final t = results[2];

      if (w.data is Map && w.data['status'] == true && w.data['data'] is Map) {
        _wallet = Map<String, dynamic>.from(w.data['data'] as Map);
      }
      if (r.data is Map && r.data['status'] == true && r.data['data'] is List) {
        _referrals = List<dynamic>.from(r.data['data'] as List);
      }
      if (t.data is Map && t.data['status'] == true && t.data['data'] is List) {
        _transactions = List<dynamic>.from(t.data['data'] as List);
      }
      _error = false;
    } catch (_) {
      if (mounted) _error = true;
    }
    if (mounted) setState(() => _loading = false);
  }

  // ─── Derived data ──────────────────────────────────────────────
  num _points() {
    final w = _wallet;
    if (w == null) return 0;
    return (w['balance'] ?? w['availableBalance'] ?? 0) as num? ?? 0;
  }

  bool _isClosed(dynamic r) => _closedStatuses.contains((r is Map ? r['status'] : null)?.toString());

  List<dynamic> get _activeReferrals => _referrals.where((r) => !_isClosed(r)).toList();
  int get _closedCount => _referrals.where(_isClosed).length;

  String _referralCode() {
    final user = ref.read(authProvider).user;
    final code = user?['referralCode']?.toString();
    if (code == null || code.isEmpty) return 'N/A';
    return code;
  }

  String _refName(dynamic r) => (r['referralName'] ?? r['clientName'] ?? 'REFERRAL').toString();
  String _refStatus(dynamic r) => (r['status'] ?? 'NEW').toString();
  String _refProject(dynamic r) {
    final pid = r['projectId'];
    if (pid is Map) return (pid['title'] ?? 'M4 PROJECT').toString();
    return (r['projectName'] ?? 'M4 PROJECT').toString();
  }

  // ━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━
  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final bg = isDark ? Colors.black : Colors.white;
    final textPrimary = isDark ? Colors.white : Colors.black;

    return Scaffold(
      backgroundColor: bg,
      body: SafeArea(
        child: Column(
          children: [
            _buildHeader(isDark, textPrimary),
            Expanded(
              child: _loading
                  ? const Center(child: CircularProgressIndicator(color: M4Theme.premiumBlue))
                  : _error && _wallet == null && _referrals.isEmpty
                      ? _buildErrorState(isDark, textPrimary)
                      : RefreshIndicator(
                          onRefresh: _load,
                          color: M4Theme.premiumBlue,
                          backgroundColor: isDark ? const Color(0xFF1C1C1E) : Colors.white,
                          child: SingleChildScrollView(
                            physics: const AlwaysScrollableScrollPhysics(),
                            padding: const EdgeInsets.symmetric(horizontal: 24),
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                const SizedBox(height: 12),
                                _buildCodeCard(isDark, textPrimary),
                                const SizedBox(height: 20),
                                _buildStatsRow(isDark, textPrimary),
                                const SizedBox(height: 20),
                                _buildRedeemButton(isDark, textPrimary),
                                const SizedBox(height: 20),
                                _buildActionGrid(isDark, textPrimary),
                                const SizedBox(height: 32),
                                _buildSectionHeader('ACTIVE REFERRALS', LucideIcons.users, isDark, textPrimary),
                                const SizedBox(height: 16),
                                _buildReferralsList(isDark, textPrimary),
                                const SizedBox(height: 32),
                                _buildSectionHeader('POINT HISTORY', LucideIcons.history, isDark, textPrimary),
                                const SizedBox(height: 16),
                                _buildHistoryList(isDark, textPrimary),
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

  // ─── Header ────────────────────────────────────────────────────
  Widget _buildHeader(bool isDark, Color textPrimary) {
    return Padding(
      padding: const EdgeInsets.fromLTRB(24, 20, 24, 20),
      child: Row(
        children: [
          GestureDetector(
            onTap: () => context.canPop() ? context.pop() : context.go('/investor/home'),
            child: Container(
              padding: const EdgeInsets.all(10),
              decoration: BoxDecoration(
                color: textPrimary.withValues(alpha: 0.05),
                shape: BoxShape.circle,
                border: Border.all(color: textPrimary.withValues(alpha: 0.1)),
              ),
              child: Icon(LucideIcons.arrowLeft, size: 16, color: textPrimary),
            ),
          ),
          Expanded(
            child: Text(
              'REFERRAL & REWARDS',
              textAlign: TextAlign.center,
              style: GoogleFonts.montserrat(
                fontSize: 16,
                fontWeight: FontWeight.w900,
                color: textPrimary,
                letterSpacing: 1.5,
              ),
            ),
          ),
          const SizedBox(width: 36),
        ],
      ),
    );
  }

  // ─── Referral Code Card ────────────────────────────────────────
  Widget _buildCodeCard(bool isDark, Color textPrimary) {
    final code = _referralCode();
    final card = isDark ? Colors.white.withValues(alpha: 0.03) : Colors.white;
    final border = isDark ? Colors.white.withValues(alpha: 0.08) : Colors.black.withValues(alpha: 0.06);

    return Container(
      width: double.infinity,
      padding: const EdgeInsets.symmetric(vertical: 28, horizontal: 24),
      decoration: BoxDecoration(
        color: card,
        borderRadius: BorderRadius.circular(28),
        border: Border.all(color: border),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: isDark ? 0.2 : 0.05),
            blurRadius: 24,
            offset: const Offset(0, 12),
          ),
        ],
      ),
      child: Column(
        children: [
          Text(
            'MY REFERRAL IDENTITY CODE',
            style: GoogleFonts.montserrat(
              fontSize: 9,
              fontWeight: FontWeight.w900,
              letterSpacing: 2,
              color: textPrimary.withValues(alpha: 0.5),
            ),
          ),
          const SizedBox(height: 16),
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 12),
            decoration: BoxDecoration(
              color: textPrimary.withValues(alpha: 0.04),
              borderRadius: BorderRadius.circular(16),
              border: Border.all(color: border),
            ),
            child: Row(
              mainAxisSize: MainAxisSize.min,
              children: [
                Text(
                  code,
                  style: GoogleFonts.montserrat(
                    fontSize: 18,
                    fontWeight: FontWeight.w900,
                    letterSpacing: 3,
                    color: M4Theme.premiumBlue,
                  ),
                ),
                const SizedBox(width: 12),
                GestureDetector(
                  onTap: () {
                    if (code == 'N/A') return;
                    Clipboard.setData(ClipboardData(text: code));
                    _toast('Referral code copied to clipboard!', success: true);
                  },
                  child: Icon(LucideIcons.copy, size: 16, color: textPrimary.withValues(alpha: 0.5)),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  // ─── Stats Row ─────────────────────────────────────────────────
  Widget _buildStatsRow(bool isDark, Color textPrimary) {
    return Row(
      children: [
        Expanded(child: _statCard('POINTS', _points().toString(), isDark, textPrimary)),
        const SizedBox(width: 12),
        Expanded(child: _statCard('REFERRALS', _activeReferrals.length.toString(), isDark, textPrimary)),
        const SizedBox(width: 12),
        Expanded(child: _statCard('CLOSED', _closedCount.toString(), isDark, textPrimary)),
      ],
    );
  }

  Widget _statCard(String label, String value, bool isDark, Color textPrimary) {
    final card = isDark ? Colors.white.withValues(alpha: 0.03) : Colors.white;
    final border = isDark ? Colors.white.withValues(alpha: 0.08) : Colors.black.withValues(alpha: 0.06);
    return Container(
      padding: const EdgeInsets.symmetric(vertical: 22),
      decoration: BoxDecoration(
        color: card,
        borderRadius: BorderRadius.circular(28),
        border: Border.all(color: border),
      ),
      child: Column(
        children: [
          Text(
            label,
            style: GoogleFonts.montserrat(
              fontSize: 8,
              fontWeight: FontWeight.w900,
              letterSpacing: 1.5,
              color: textPrimary.withValues(alpha: 0.5),
            ),
          ),
          const SizedBox(height: 10),
          Text(
            value,
            style: GoogleFonts.montserrat(
              fontSize: 24,
              fontWeight: FontWeight.w900,
              color: textPrimary,
              height: 1,
            ),
          ),
        ],
      ),
    );
  }

  // ─── Quick Redeem ──────────────────────────────────────────────
  Widget _buildRedeemButton(bool isDark, Color textPrimary) {
    return GestureDetector(
      onTap: () async {
        await context.push('/investor/referral/redeem');
        if (mounted) _load();
      },
      child: Container(
        width: double.infinity,
        height: 56,
        decoration: BoxDecoration(
          color: textPrimary,
          borderRadius: BorderRadius.circular(18),
          boxShadow: [
            BoxShadow(
              color: textPrimary.withValues(alpha: 0.2),
              blurRadius: 15,
              offset: const Offset(0, 8),
            ),
          ],
        ),
        child: Row(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Text(
              'REDEEM REWARDS',
              style: GoogleFonts.montserrat(
                fontSize: 11,
                fontWeight: FontWeight.w900,
                letterSpacing: 2,
                color: isDark ? Colors.black : Colors.white,
              ),
            ),
            const SizedBox(width: 12),
            Icon(LucideIcons.gift, size: 18, color: isDark ? Colors.black : Colors.white),
          ],
        ),
      ),
    );
  }

  // ─── Action Grid (Refer / Share) ───────────────────────────────
  Widget _buildActionGrid(bool isDark, Color textPrimary) {
    return Row(
      children: [
        Expanded(
          child: _actionCard(
            LucideIcons.users,
            'REFER FRIEND',
            isDark,
            textPrimary,
            () => _showReferralForm(isDark, textPrimary),
          ),
        ),
        const SizedBox(width: 16),
        Expanded(
          child: _actionCard(
            LucideIcons.share2,
            'SHARE CODE',
            isDark,
            textPrimary,
            () {
              final code = _referralCode();
              final text = 'Join M4 Family using my referral code: $code';
              Clipboard.setData(ClipboardData(text: text));
              _toast('Referral link copied to clipboard!', success: true);
            },
          ),
        ),
      ],
    );
  }

  Widget _actionCard(IconData icon, String label, bool isDark, Color textPrimary, VoidCallback onTap) {
    final card = isDark ? Colors.white.withValues(alpha: 0.03) : Colors.white;
    final border = isDark ? Colors.white.withValues(alpha: 0.08) : Colors.black.withValues(alpha: 0.06);
    return GestureDetector(
      onTap: onTap,
      child: Container(
        height: 130,
        decoration: BoxDecoration(
          color: card,
          borderRadius: BorderRadius.circular(32),
          border: Border.all(color: border),
        ),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Container(
              padding: const EdgeInsets.all(14),
              decoration: BoxDecoration(
                color: textPrimary.withValues(alpha: 0.04),
                borderRadius: BorderRadius.circular(16),
                border: Border.all(color: border),
              ),
              child: Icon(icon, size: 22, color: textPrimary),
            ),
            const SizedBox(height: 14),
            Text(
              label,
              style: GoogleFonts.montserrat(
                fontSize: 9,
                fontWeight: FontWeight.w900,
                letterSpacing: 1.5,
                color: textPrimary.withValues(alpha: 0.5),
              ),
            ),
          ],
        ),
      ),
    );
  }

  // ─── Section Header ────────────────────────────────────────────
  Widget _buildSectionHeader(String title, IconData icon, bool isDark, Color textPrimary) {
    return Row(
      children: [
        Text(
          title,
          style: GoogleFonts.montserrat(
            fontSize: 9,
            fontWeight: FontWeight.w900,
            letterSpacing: 2,
            color: textPrimary.withValues(alpha: 0.4),
          ),
        ),
        const Spacer(),
        Icon(icon, size: 14, color: textPrimary.withValues(alpha: 0.15)),
      ],
    );
  }

  // ─── Active Referrals List ─────────────────────────────────────
  Widget _buildReferralsList(bool isDark, Color textPrimary) {
    final active = _activeReferrals;
    if (active.isEmpty) {
      return _emptyBox('NO ACTIVE REFERRALS YET', isDark, textPrimary);
    }
    return Column(
      children: active.map((r) => _referralCard(r, isDark, textPrimary)).toList(),
    );
  }

  Widget _referralCard(dynamic r, bool isDark, Color textPrimary) {
    final card = isDark ? Colors.white.withValues(alpha: 0.03) : Colors.white;
    final border = isDark ? Colors.white.withValues(alpha: 0.08) : Colors.black.withValues(alpha: 0.06);
    final name = _refName(r);
    final project = _refProject(r);
    final status = _refStatus(r);
    final code = (r is Map ? r['referralCode'] : null)?.toString();

    return Container(
      margin: const EdgeInsets.only(bottom: 12),
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: card,
        borderRadius: BorderRadius.circular(20),
        border: Border.all(color: border),
      ),
      child: Row(
        children: [
          Container(
            padding: const EdgeInsets.all(12),
            decoration: BoxDecoration(
              color: textPrimary.withValues(alpha: 0.04),
              borderRadius: BorderRadius.circular(16),
              border: Border.all(color: border),
            ),
            child: Icon(LucideIcons.users, size: 20, color: textPrimary),
          ),
          const SizedBox(width: 16),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  name.toUpperCase(),
                  style: GoogleFonts.montserrat(
                    fontSize: 13,
                    fontWeight: FontWeight.w800,
                    color: textPrimary,
                  ),
                ),
                const SizedBox(height: 2),
                Text(
                  project.toUpperCase(),
                  style: GoogleFonts.montserrat(
                    fontSize: 8,
                    fontWeight: FontWeight.w900,
                    letterSpacing: 1.5,
                    color: M4Theme.premiumBlue,
                  ),
                ),
                if (code != null && code.isNotEmpty) ...[
                  const SizedBox(height: 2),
                  Text(
                    code,
                    style: GoogleFonts.montserrat(
                      fontSize: 9,
                      fontWeight: FontWeight.w700,
                      letterSpacing: 1,
                      color: _gold,
                    ),
                  ),
                ],
              ],
            ),
          ),
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
            decoration: BoxDecoration(
              color: textPrimary.withValues(alpha: 0.04),
              borderRadius: BorderRadius.circular(8),
              border: Border.all(color: border),
            ),
            child: Text(
              status.toUpperCase(),
              style: GoogleFonts.montserrat(
                fontSize: 8,
                fontWeight: FontWeight.w900,
                letterSpacing: 1,
                color: textPrimary.withValues(alpha: 0.5),
              ),
            ),
          ),
        ],
      ),
    );
  }

  // ─── Point History List ────────────────────────────────────────
  Widget _buildHistoryList(bool isDark, Color textPrimary) {
    if (_transactions.isEmpty) {
      return _emptyBox('NO RECENT HISTORY', isDark, textPrimary);
    }
    return Column(
      children: _transactions.map((t) => _historyItem(t, isDark, textPrimary)).toList(),
    );
  }

  Widget _historyItem(dynamic txn, bool isDark, Color textPrimary) {
    final border = isDark ? Colors.white.withValues(alpha: 0.08) : Colors.black.withValues(alpha: 0.06);
    final type = (txn['type'] ?? 'CREDIT').toString();
    final reference = (txn['reference'] ?? '').toString();
    final status = (txn['status'] ?? '').toString();
    final amount = txn['amount'] ?? txn['points'] ?? 0;
    final isDebit = type.toUpperCase() == 'DEBIT';
    final date = _formatDate(txn['createdAt']);

    final title = reference.isNotEmpty ? '${type.toUpperCase()} - $reference' : type.toUpperCase();

    return Container(
      margin: const EdgeInsets.only(bottom: 8),
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: isDark ? Colors.white.withValues(alpha: 0.03) : Colors.white,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: border),
      ),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  title,
                  style: GoogleFonts.montserrat(
                    fontSize: 10,
                    fontWeight: FontWeight.w900,
                    color: textPrimary,
                  ),
                ),
                const SizedBox(height: 2),
                Text(
                  date,
                  style: GoogleFonts.montserrat(
                    fontSize: 8,
                    fontWeight: FontWeight.w700,
                    color: textPrimary.withValues(alpha: 0.4),
                  ),
                ),
              ],
            ),
          ),
          Column(
            crossAxisAlignment: CrossAxisAlignment.end,
            children: [
              Text(
                '${isDebit ? '-' : '+'}$amount',
                style: GoogleFonts.montserrat(
                  fontSize: 12,
                  fontWeight: FontWeight.w900,
                  color: isDebit ? Colors.redAccent : const Color(0xFF10B981),
                ),
              ),
              if (status.isNotEmpty)
                Text(
                  'STATUS: ${status.toUpperCase()}',
                  style: GoogleFonts.montserrat(
                    fontSize: 7,
                    fontWeight: FontWeight.w900,
                    color: textPrimary.withValues(alpha: 0.35),
                  ),
                ),
            ],
          ),
        ],
      ),
    );
  }

  // ─── Shared widgets ────────────────────────────────────────────
  Widget _emptyBox(String label, bool isDark, Color textPrimary) {
    final border = isDark ? Colors.white.withValues(alpha: 0.08) : Colors.black.withValues(alpha: 0.06);
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.symmetric(vertical: 40),
      decoration: BoxDecoration(
        color: isDark ? Colors.white.withValues(alpha: 0.03) : Colors.white,
        borderRadius: BorderRadius.circular(20),
        border: Border.all(color: border),
      ),
      child: Center(
        child: Text(
          label,
          style: GoogleFonts.montserrat(
            fontSize: 10,
            fontWeight: FontWeight.w900,
            letterSpacing: 2,
            color: textPrimary.withValues(alpha: 0.15),
          ),
        ),
      ),
    );
  }

  Widget _buildErrorState(bool isDark, Color textPrimary) {
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(32),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(LucideIcons.alertCircle, size: 40, color: textPrimary.withValues(alpha: 0.3)),
            const SizedBox(height: 16),
            Text(
              'FAILED TO LOAD REWARD HUB',
              textAlign: TextAlign.center,
              style: GoogleFonts.montserrat(
                fontSize: 11,
                fontWeight: FontWeight.w900,
                letterSpacing: 1.5,
                color: textPrimary.withValues(alpha: 0.5),
              ),
            ),
            const SizedBox(height: 20),
            GestureDetector(
              onTap: _load,
              child: Container(
                padding: const EdgeInsets.symmetric(horizontal: 28, vertical: 14),
                decoration: BoxDecoration(
                  color: M4Theme.premiumBlue,
                  borderRadius: BorderRadius.circular(14),
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
      ),
    );
  }

  // ━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━
  // REFERRAL FORM — Modal bottom sheet (web "form" step)
  // ━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━
  void _showReferralForm(bool isDark, Color textPrimary) {
    final nameCtrl = TextEditingController();
    final phoneCtrl = TextEditingController();
    final emailCtrl = TextEditingController();
    String? selectedProjectId;
    bool submitting = false;

    final border = isDark ? Colors.white.withValues(alpha: 0.08) : Colors.black.withValues(alpha: 0.06);

    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (ctx) {
        return StatefulBuilder(
          builder: (ctx, setModalState) {
            return Container(
              padding: EdgeInsets.only(
                left: 28,
                right: 28,
                top: 32,
                bottom: MediaQuery.of(ctx).viewInsets.bottom + 32,
              ),
              decoration: BoxDecoration(
                color: isDark ? const Color(0xFF18181B) : Colors.white,
                borderRadius: const BorderRadius.vertical(top: Radius.circular(40)),
                border: Border.all(color: border),
              ),
              child: SingleChildScrollView(
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Center(
                      child: Container(
                        width: 40,
                        height: 4,
                        decoration: BoxDecoration(
                          color: textPrimary.withValues(alpha: 0.15),
                          borderRadius: BorderRadius.circular(2),
                        ),
                      ),
                    ),
                    const SizedBox(height: 28),
                    Text(
                      'NEW\nREFERRAL',
                      style: GoogleFonts.montserrat(
                        fontSize: 24,
                        fontWeight: FontWeight.w900,
                        color: textPrimary,
                        height: 1.1,
                      ),
                    ),
                    const SizedBox(height: 8),
                    Text(
                      'REFER & EARN REWARDS',
                      style: GoogleFonts.montserrat(
                        fontSize: 9,
                        fontWeight: FontWeight.w900,
                        letterSpacing: 2,
                        color: textPrimary.withValues(alpha: 0.3),
                      ),
                    ),
                    const SizedBox(height: 32),

                    // Project selector
                    _formLabel('SELECT PROJECT', textPrimary),
                    const SizedBox(height: 10),
                    Consumer(
                      builder: (ctx, ref, _) {
                        final projectsAsync = ref.watch(projectsProvider);
                        return projectsAsync.when(
                          loading: () => Container(
                            height: 56,
                            decoration: _inputBox(isDark, textPrimary),
                            child: const Center(
                              child: SizedBox(
                                width: 20,
                                height: 20,
                                child: CircularProgressIndicator(strokeWidth: 2, color: M4Theme.premiumBlue),
                              ),
                            ),
                          ),
                          error: (_, __) => Container(
                            height: 56,
                            alignment: Alignment.centerLeft,
                            padding: const EdgeInsets.symmetric(horizontal: 20),
                            decoration: _inputBox(isDark, textPrimary),
                            child: Text(
                              'COULD NOT LOAD PROJECTS',
                              style: GoogleFonts.montserrat(
                                fontSize: 10,
                                fontWeight: FontWeight.w800,
                                color: textPrimary.withValues(alpha: 0.4),
                              ),
                            ),
                          ),
                          data: (projects) => Container(
                            height: 56,
                            padding: const EdgeInsets.symmetric(horizontal: 20),
                            decoration: _inputBox(isDark, textPrimary),
                            child: DropdownButtonHideUnderline(
                              child: DropdownButton<String>(
                                isExpanded: true,
                                value: selectedProjectId,
                                hint: Text(
                                  'SELECT PROJECT',
                                  style: GoogleFonts.montserrat(
                                    fontSize: 11,
                                    fontWeight: FontWeight.w800,
                                    color: textPrimary.withValues(alpha: 0.3),
                                  ),
                                ),
                                dropdownColor: isDark ? const Color(0xFF1C1C1E) : Colors.white,
                                icon: Icon(LucideIcons.chevronDown, size: 16, color: textPrimary.withValues(alpha: 0.3)),
                                items: [
                                  for (final p in projects)
                                    if ((p['_id']?.toString() ?? '').isNotEmpty)
                                      DropdownMenuItem(
                                        value: p['_id'].toString(),
                                        child: Text(
                                          (p['title'] ?? p['name'] ?? 'PROJECT').toString().toUpperCase(),
                                          style: GoogleFonts.montserrat(
                                            fontSize: 10,
                                            fontWeight: FontWeight.w800,
                                            color: textPrimary,
                                          ),
                                        ),
                                      ),
                                ],
                                onChanged: (v) => setModalState(() => selectedProjectId = v),
                              ),
                            ),
                          ),
                        );
                      },
                    ),
                    const SizedBox(height: 20),

                    _formLabel("FRIEND'S NAME", textPrimary),
                    const SizedBox(height: 10),
                    _formField(nameCtrl, 'FULL NAME', isDark, textPrimary),
                    const SizedBox(height: 20),

                    _formLabel('MOBILE NUMBER', textPrimary),
                    const SizedBox(height: 10),
                    _formField(phoneCtrl, '+91 XXXXX XXXXX', isDark, textPrimary, type: TextInputType.phone),
                    const SizedBox(height: 20),

                    _formLabel("FRIEND'S EMAIL", textPrimary),
                    const SizedBox(height: 10),
                    _formField(emailCtrl, 'email@example.com', isDark, textPrimary, type: TextInputType.emailAddress),
                    const SizedBox(height: 32),

                    GestureDetector(
                      onTap: submitting
                          ? null
                          : () async {
                              if (selectedProjectId == null ||
                                  nameCtrl.text.trim().isEmpty ||
                                  phoneCtrl.text.trim().isEmpty ||
                                  emailCtrl.text.trim().isEmpty) {
                                _toast('Please fill all fields to proceed');
                                return;
                              }
                              setModalState(() => submitting = true);
                              final navigator = Navigator.of(ctx);
                              try {
                                final api = ref.read(apiClientProvider);
                                final res = await api.post('/api/investor/referrals', {
                                  'projectId': selectedProjectId,
                                  'referralName': nameCtrl.text.trim(),
                                  'referralPhone': phoneCtrl.text.trim(),
                                  'referralEmail': emailCtrl.text.trim(),
                                });
                                if (!mounted) return;
                                final ok = res.data is Map && res.data['status'] == true ||
                                    res.statusCode == 200 ||
                                    res.statusCode == 201;
                                if (ok) {
                                  navigator.pop();
                                  _toast('Referral registered!', success: true);
                                  _load();
                                } else {
                                  final msg = res.data is Map ? res.data['message']?.toString() : null;
                                  _toast(msg ?? 'Failed to register referral');
                                  setModalState(() => submitting = false);
                                }
                              } catch (_) {
                                if (mounted) {
                                  _toast('Network error — referral not saved.');
                                  setModalState(() => submitting = false);
                                }
                              }
                            },
                      child: Container(
                        width: double.infinity,
                        height: 56,
                        decoration: BoxDecoration(
                          color: textPrimary,
                          borderRadius: BorderRadius.circular(14),
                        ),
                        alignment: Alignment.center,
                        child: submitting
                            ? SizedBox(
                                width: 20,
                                height: 20,
                                child: CircularProgressIndicator(
                                  strokeWidth: 2,
                                  color: isDark ? Colors.black : Colors.white,
                                ),
                              )
                            : Text(
                                'SUBMIT REFERRAL',
                                style: GoogleFonts.montserrat(
                                  fontSize: 10,
                                  fontWeight: FontWeight.w900,
                                  letterSpacing: 2,
                                  color: isDark ? Colors.black : Colors.white,
                                ),
                              ),
                      ),
                    ),
                  ],
                ),
              ),
            );
          },
        );
      },
    );
  }

  // ─── Form helpers ──────────────────────────────────────────────
  Widget _formLabel(String text, Color textPrimary) {
    return Text(
      text,
      style: GoogleFonts.montserrat(
        fontSize: 9,
        fontWeight: FontWeight.w900,
        letterSpacing: 1.5,
        color: textPrimary.withValues(alpha: 0.4),
      ),
    );
  }

  BoxDecoration _inputBox(bool isDark, Color textPrimary) {
    return BoxDecoration(
      color: textPrimary.withValues(alpha: isDark ? 0.05 : 0.03),
      borderRadius: BorderRadius.circular(16),
      border: Border.all(color: textPrimary.withValues(alpha: 0.08)),
    );
  }

  Widget _formField(TextEditingController controller, String hint, bool isDark, Color textPrimary,
      {TextInputType type = TextInputType.text}) {
    return Container(
      height: 56,
      decoration: _inputBox(isDark, textPrimary),
      child: TextField(
        controller: controller,
        keyboardType: type,
        style: GoogleFonts.montserrat(
          fontSize: 13,
          fontWeight: FontWeight.w700,
          color: textPrimary,
        ),
        decoration: InputDecoration(
          hintText: hint,
          hintStyle: GoogleFonts.montserrat(
            fontSize: 12,
            fontWeight: FontWeight.w700,
            color: textPrimary.withValues(alpha: 0.25),
          ),
          border: InputBorder.none,
          contentPadding: const EdgeInsets.symmetric(horizontal: 20),
        ),
      ),
    );
  }

  // ─── Utilities ─────────────────────────────────────────────────
  String _formatDate(dynamic raw) {
    if (raw == null) return '';
    final parsed = DateTime.tryParse(raw.toString());
    if (parsed == null) return '';
    final d = parsed.toLocal();
    String two(int n) => n.toString().padLeft(2, '0');
    return '${two(d.day)}/${two(d.month)}/${d.year}';
  }

  void _toast(String message, {bool success = false}) {
    if (!mounted) return;
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(message),
        backgroundColor: success ? Colors.green : Colors.redAccent,
        duration: const Duration(seconds: 2),
      ),
    );
  }
}
