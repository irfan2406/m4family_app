import 'package:flutter/material.dart';
import 'package:flutter/foundation.dart' show kDebugMode;
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:lucide_icons/lucide_icons.dart';
import 'package:m4_mobile/core/utils/validators.dart';
import 'package:m4_mobile/presentation/providers/auth_provider.dart';
import 'package:flutter/services.dart';
import 'package:m4_mobile/presentation/screens/profile/referral_redeem_screen.dart';
import 'package:m4_mobile/presentation/providers/project_provider.dart';
import 'package:intl/intl.dart';

class ReferralScreen extends ConsumerStatefulWidget {
  const ReferralScreen({super.key});

  @override
  ConsumerState<ReferralScreen> createState() => _ReferralScreenState();
}

class _ReferralScreenState extends ConsumerState<ReferralScreen> {
  // Same closed-set the investor referral screen uses, so both portals agree
  // on what "CLOSED" means.
  static const _closedStatuses = {
    'CLOSED',
    'CREDITED',
    'BOOKING_DONE',
    'Booked',
  };

  bool _isLoading = true;
  double _walletBalance = 0;
  String _referralCode = '';
  List<dynamic> _referrals = [];
  List<dynamic> _history = [];

  /// Which stat tile is selected: 'active', 'closed', or null for all.
  /// Drives the pipeline list below, so the tile that shows a count also
  /// shows the leads behind it.
  String? _statFilter;
  final _pipelineKey = GlobalKey();
  final _historyKey = GlobalKey();

  /// The leads the pipeline shows for the current tile selection.
  List<dynamic> get _pipelineLeads {
    switch (_statFilter) {
      case 'active':
        return _activeReferrals;
      case 'closed':
        return _referrals.where(_isClosed).toList();
      default:
        return _referrals;
    }
  }

  void _selectStat(String? filter, GlobalKey target) {
    setState(() => _statFilter = _statFilter == filter ? null : filter);
    WidgetsBinding.instance.addPostFrameCallback((_) {
      final ctx = target.currentContext;
      if (ctx == null) return;
      Scrollable.ensureVisible(
        ctx,
        duration: const Duration(milliseconds: 400),
        curve: Curves.easeInOut,
        alignment: 0.05,
      );
    });
  }

  bool _isClosed(dynamic r) =>
      _closedStatuses.contains((r is Map ? r['status'] : null)?.toString());

  List<dynamic> get _activeReferrals =>
      _referrals.where((r) => !_isClosed(r)).toList();
  int get _closedCount => _referrals.where(_isClosed).length;

  @override
  void initState() {
    super.initState();
    _fetchReferralData();
  }

  Future<void> _fetchReferralData() async {
    try {
      final apiClient = ref.read(apiClientProvider);
      final user = ref.read(authProvider).user;

      final response = await apiClient.getReferralDashboard();
      if (response.data['status'] == true) {
        final data = response.data['data'];
        setState(() {
          _walletBalance =
              double.tryParse(data['walletBalance'].toString()) ?? 0;
          _referrals = data['activeReferrals'] ?? [];
          _history = data['transactions'] ?? [];
        });
        // Debug-only: names the keys a transaction actually carries, so the
        // points field can be confirmed from logcat if a row still reads 0.
        if (kDebugMode && _history.isNotEmpty && _history.first is Map) {
          debugPrint('M4 txn keys: ${(_history.first as Map).keys.join(', ')}');
        }
      } else {
        _walletBalance =
            double.tryParse(user?['loyaltyPoints']?.toString() ?? '0') ?? 0;
        _referrals = [];
        _history = [];
      }

      _referralCode = user?['referralCode'] ?? 'M4-GEN-001';
      if (mounted) setState(() => _isLoading = false);
    } catch (e) {
      if (mounted) setState(() => _isLoading = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final colorScheme = theme.colorScheme;

    return Scaffold(
      backgroundColor: theme.scaffoldBackgroundColor,
      body: SafeArea(
        // Edge-to-edge: content runs under the gesture bar so scrolling fills
        // the screen. Trailing padding keeps the last item reachable.
        bottom: false,
        child: Column(
          children: [
            _buildHeader(),
            Expanded(
              child: _isLoading
                  ? Center(
                      child: CircularProgressIndicator(
                        color: colorScheme.primary,
                        strokeWidth: 2,
                      ),
                    )
                  : RefreshIndicator(
                      onRefresh: _fetchReferralData,
                      color: colorScheme.primary,
                      backgroundColor: theme.cardColor,
                      child: SingleChildScrollView(
                        physics: const BouncingScrollPhysics(),
                        padding: const EdgeInsets.symmetric(horizontal: 24),
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            const SizedBox(height: 12),
                            // Web parity: identity code card, then the three
                            // stat tiles, then a standalone redeem button.
                            _buildCodeCard(),
                            const SizedBox(height: 16),
                            _buildStatsRow(),
                            const SizedBox(height: 20),
                            _buildRedeemButton(),
                            const SizedBox(height: 20),
                            _buildActionGrid(),
                            const SizedBox(height: 24),
                            Container(
                              key: _pipelineKey,
                              child: _buildSectionHeader(
                                _statFilter == 'closed'
                                    ? 'CLOSED REFERRALS'
                                    : 'ACTIVE PIPELINE',
                                LucideIcons.trendingUp,
                              ),
                            ),
                            const SizedBox(height: 12),
                            _buildLeadsPipeline(),
                            const SizedBox(height: 24),
                            Container(
                              key: _historyKey,
                              child: _buildSectionHeader(
                                'POINT HISTORY',
                                LucideIcons.history,
                              ),
                            ),
                            const SizedBox(height: 12),
                            _buildHistoryList(),
                            const SizedBox(height: 32),
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

  Widget _buildHeader() {
    final foreground = Theme.of(context).colorScheme.onSurface;
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 20),
      child: Stack(
        alignment: Alignment.center,
        children: [
          Align(
            alignment: Alignment.centerLeft,
            child: GestureDetector(
              onTap: () => Navigator.pop(context),
              child: Container(
                padding: const EdgeInsets.all(8),
                decoration: BoxDecoration(
                  color: foreground.withOpacity(0.05),
                  shape: BoxShape.circle,
                  border: Border.all(color: foreground.withOpacity(0.1)),
                ),
                child: Icon(
                  LucideIcons.chevronLeft,
                  color: foreground,
                  size: 16,
                ),
              ),
            ),
          ),
          Text(
            'REWARDS HUB',
            style: GoogleFonts.gelasio(
              color: foreground,
              fontSize: 14,
              fontWeight: FontWeight.w700,
              letterSpacing: 2,
            ),
          ),
        ],
      ),
    );
  }

  // ── Referral identity code (web parity) ──────────────────────────────
  Widget _buildCodeCard() {
    final theme = Theme.of(context);
    final isDark = theme.brightness == Brightness.dark;
    final fg = theme.colorScheme.onSurface;
    final card = isDark
        ? Colors.white.withOpacity(0.03)
        : const Color(0xFFF4EFE3);
    final border = isDark
        ? Colors.white.withOpacity(0.08)
        : const Color(0xFF0C312B).withOpacity(0.06);

    return Container(
      width: double.infinity,
      padding: const EdgeInsets.symmetric(vertical: 28, horizontal: 24),
      decoration: BoxDecoration(
        color: card,
        borderRadius: BorderRadius.circular(28),
        border: Border.all(color: border),
        boxShadow: [
          BoxShadow(
            color: const Color(0xFF0C312B).withOpacity(isDark ? 0.2 : 0.05),
            blurRadius: 24,
            offset: const Offset(0, 12),
          ),
        ],
      ),
      child: Column(
        children: [
          Text(
            'MY REFERRAL IDENTITY CODE',
            style: GoogleFonts.gelasio(
              fontSize: 11,
              fontWeight: FontWeight.w700,
              letterSpacing: 2,
              color: fg.withOpacity(0.75),
            ),
          ),
          const SizedBox(height: 16),
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 12),
            decoration: BoxDecoration(
              color: fg.withOpacity(0.04),
              borderRadius: BorderRadius.circular(16),
              border: Border.all(color: border),
            ),
            child: Row(
              mainAxisSize: MainAxisSize.min,
              children: [
                Flexible(
                  child: Text(
                    _referralCode.isEmpty ? 'N/A' : _referralCode,
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                    style: GoogleFonts.gelasio(
                      fontSize: 18,
                      fontWeight: FontWeight.w700,
                      letterSpacing: 3,
                      color: fg,
                    ),
                  ),
                ),
                const SizedBox(width: 12),
                GestureDetector(
                  onTap: () {
                    if (_referralCode.isEmpty) return;
                    Clipboard.setData(ClipboardData(text: _referralCode));
                    ScaffoldMessenger.of(context).showSnackBar(
                      const SnackBar(
                        backgroundColor: Color(0xFF163A2C),
                        content: Text('Referral code copied to clipboard!'),
                      ),
                    );
                  },
                  child: Icon(
                    LucideIcons.copy,
                    size: 16,
                    color: fg.withOpacity(0.75),
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  // ── POINTS / REFERRALS / CLOSED (web parity) ─────────────────────────
  Widget _buildStatsRow() {
    return Row(
      children: [
        Expanded(
          child: _statCard(
            'POINTS',
            NumberFormat('#,###').format(_walletBalance),
            // POINTS is not a pipeline filter: it clears any selection
            // and jumps to the transactions the balance came from.
            onTap: () => _selectStat(null, _historyKey),
          ),
        ),
        const SizedBox(width: 12),
        Expanded(
          child: _statCard(
            'REFERRALS',
            _activeReferrals.length.toString(),
            onTap: () => _selectStat('active', _pipelineKey),
            selected: _statFilter == 'active',
          ),
        ),
        const SizedBox(width: 12),
        Expanded(
          child: _statCard(
            'CLOSED',
            _closedCount.toString(),
            onTap: () => _selectStat('closed', _pipelineKey),
            selected: _statFilter == 'closed',
          ),
        ),
      ],
    );
  }

  Widget _statCard(
    String label,
    String value, {
    VoidCallback? onTap,
    bool selected = false,
  }) {
    final theme = Theme.of(context);
    final isDark = theme.brightness == Brightness.dark;
    final fg = theme.colorScheme.onSurface;
    final card = isDark
        ? Colors.white.withOpacity(0.03)
        : const Color(0xFFF4EFE3);
    // A selected tile carries a solid outline so it is obvious which count
    // the list below is showing.
    final border = selected
        ? fg.withOpacity(0.45)
        : isDark
        ? Colors.white.withOpacity(0.08)
        : const Color(0xFF0C312B).withOpacity(0.06);

    return GestureDetector(
      onTap: onTap,
      behavior: HitTestBehavior.opaque,
      child: Container(
        padding: const EdgeInsets.symmetric(vertical: 22, horizontal: 8),
        decoration: BoxDecoration(
          color: card,
          borderRadius: BorderRadius.circular(28),
          border: Border.all(color: border),
        ),
        child: Column(
          children: [
            Text(
              label,
              maxLines: 1,
              overflow: TextOverflow.ellipsis,
              style: GoogleFonts.gelasio(
                fontSize: 10,
                fontWeight: FontWeight.w700,
                letterSpacing: 1.5,
                color: fg.withOpacity(0.75),
              ),
            ),
            const SizedBox(height: 10),
            FittedBox(
              fit: BoxFit.scaleDown,
              child: Text(
                value,
                style: GoogleFonts.gelasio(
                  fontSize: 24,
                  fontWeight: FontWeight.w700,
                  color: fg,
                  height: 1,
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  // ── Redeem action (web parity: full-width dark pill with gift icon) ──
  Widget _buildRedeemButton() {
    final theme = Theme.of(context);
    final isDark = theme.brightness == Brightness.dark;
    final fill = isDark ? const Color(0xFF1C4535) : const Color(0xFF0C312B);
    const onFill = Color(0xFFF4EFE3);

    return GestureDetector(
      onTap: () => Navigator.push(
        context,
        MaterialPageRoute(
          builder: (context) =>
              ReferralRedeemScreen(walletBalance: _walletBalance),
        ),
      ),
      child: Container(
        width: double.infinity,
        height: 56,
        decoration: BoxDecoration(
          color: fill,
          borderRadius: BorderRadius.circular(18),
          boxShadow: [
            BoxShadow(
              color: fill.withOpacity(0.35),
              blurRadius: 15,
              offset: const Offset(0, 8),
            ),
          ],
        ),
        child: Row(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Text(
              'REDEEM POINTS',
              style: GoogleFonts.gelasio(
                fontSize: 11,
                fontWeight: FontWeight.w700,
                letterSpacing: 2,
                color: onFill,
              ),
            ),
            const SizedBox(width: 12),
            const Icon(LucideIcons.gift, size: 18, color: onFill),
          ],
        ),
      ),
    );
  }

  Widget _buildActionGrid() {
    return Row(
      children: [
        Expanded(
          child: _buildActionCard(
            'REFER FRIEND',
            LucideIcons.users,
            _showReferralForm,
          ),
        ),
        const SizedBox(width: 16),
        Expanded(
          child: _buildActionCard('SHARE APP', LucideIcons.share2, () {
            Clipboard.setData(ClipboardData(text: _referralCode));
            ScaffoldMessenger.of(context).showSnackBar(
              const SnackBar(
                backgroundColor: Color(0xFF163A2C),
                content: Text('App link & code copied!'),
              ),
            );
          }),
        ),
      ],
    );
  }

  Widget _buildActionCard(String label, IconData icon, VoidCallback onTap) {
    final theme = Theme.of(context);
    final foreground = theme.colorScheme.onSurface;
    return GestureDetector(
      onTap: onTap,
      child: Container(
        height: 120,
        decoration: BoxDecoration(
          color: theme.cardColor.withOpacity(0.4),
          borderRadius: BorderRadius.circular(20),
          border: Border.all(color: foreground.withOpacity(0.05)),
        ),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(icon, color: theme.colorScheme.primary, size: 24),
            const SizedBox(height: 12),
            Text(
              label,
              style: GoogleFonts.inter(
                color: foreground.withOpacity(0.72),
                fontSize: 10,
                fontWeight: FontWeight.w600,
                letterSpacing: 1.2,
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildSectionHeader(String title, IconData icon) {
    final foreground = Theme.of(context).colorScheme.onSurface;
    return Row(
      children: [
        Text(
          title,
          style: GoogleFonts.gelasio(
            color: foreground.withOpacity(0.72),
            fontSize: 10,
            fontWeight: FontWeight.w700,
            letterSpacing: 1.5,
          ),
        ),
        const Spacer(),
        Icon(icon, color: foreground.withOpacity(0.1), size: 14),
      ],
    );
  }

  Widget _buildLeadsPipeline() {
    final leads = _pipelineLeads;
    if (leads.isEmpty) {
      return Center(
        child: Padding(
          padding: const EdgeInsets.symmetric(vertical: 40),
          child: Text(
            'NO ACTIVE LEADS',
            style: GoogleFonts.gelasio(
              color: Theme.of(context).colorScheme.onSurface.withOpacity(0.72),
              fontSize: 10,
              fontWeight: FontWeight.w700,
              letterSpacing: 2,
            ),
          ),
        ),
      );
    }

    return Column(children: leads.map((lead) => _buildLeadCard(lead)).toList());
  }

  Widget _buildLeadCard(dynamic lead) {
    final status = (lead['status'] ?? 'Pending').toString().toUpperCase();
    final name = lead['referralName'] ?? lead['clientName'] ?? 'REFERRAL LEAD';
    final project = lead['projectName'] ?? 'GENERAL SELECTION';
    final points = lead['pointsEarned'] ?? 0;

    final theme = Theme.of(context);
    final foreground = theme.colorScheme.onSurface;

    return Container(
      margin: const EdgeInsets.only(bottom: 12),
      decoration: BoxDecoration(
        color: theme.cardColor.withOpacity(0.4),
        borderRadius: BorderRadius.circular(24),
        border: Border.all(color: foreground.withOpacity(0.05)),
      ),
      child: Column(
        children: [
          Padding(
            padding: const EdgeInsets.all(20),
            child: Row(
              children: [
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        name.toString().toUpperCase(),
                        style: GoogleFonts.inter(
                          color: foreground,
                          fontSize: 12,
                          fontWeight: FontWeight.w600,
                          letterSpacing: -0.5,
                        ),
                      ),
                      const SizedBox(height: 4),
                      Text(
                        project.toString().toUpperCase(),
                        style: GoogleFonts.inter(
                          color: foreground.withOpacity(0.72),
                          fontSize: 10,
                          fontWeight: FontWeight.w600,
                          fontStyle: FontStyle.italic,
                        ),
                      ),
                    ],
                  ),
                ),
                Container(
                  padding: const EdgeInsets.symmetric(
                    horizontal: 10,
                    vertical: 6,
                  ),
                  decoration: BoxDecoration(
                    color: theme.colorScheme.primary.withOpacity(0.05),
                    borderRadius: BorderRadius.circular(8),
                    border: Border.all(
                      color: theme.colorScheme.primary.withOpacity(0.2),
                    ),
                  ),
                  child: Text(
                    status,
                    style: GoogleFonts.inter(
                      color: theme.colorScheme.primary,
                      fontSize: 9,
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                ),
              ],
            ),
          ),
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 12),
            decoration: BoxDecoration(
              border: Border.all(color: foreground.withOpacity(0.05)),
            ),
            child: Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Text(
                  'EST. REWARD',
                  style: GoogleFonts.inter(
                    color: foreground.withOpacity(0.72),
                    fontSize: 9,
                    fontWeight: FontWeight.w600,
                    letterSpacing: 1,
                  ),
                ),
                Text(
                  '${NumberFormat('#,###').format(points)} PTS',
                  style: GoogleFonts.inter(
                    // Was the gold accent — plain green ink, matching the rest
                    // of the palette.
                    color: foreground,
                    fontSize: 10,
                    fontWeight: FontWeight.w600,
                    fontStyle: FontStyle.italic,
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildHistoryList() {
    if (_history.isEmpty) {
      return Center(
        child: Padding(
          padding: const EdgeInsets.symmetric(vertical: 40),
          child: Text(
            'NO RECENT HISTORY',
            style: GoogleFonts.gelasio(
              color: Theme.of(context).colorScheme.onSurface.withOpacity(0.72),
              fontSize: 10,
              fontWeight: FontWeight.w700,
              letterSpacing: 2,
            ),
          ),
        ),
      );
    }

    return Column(
      children: _history.map((txn) => _buildHistoryItem(txn)).toList(),
    );
  }

  /// The dashboard's transactions do not consistently carry the points under
  /// `amount` — referral credits put them in `pointsEarned`, which is why the
  /// list used to read "+0". Take the first key that yields a non-zero value
  /// (a plain `??` chain would stop at an `amount` that is present but 0).
  num _txnAmount(dynamic txn) {
    if (txn is! Map) return 0;
    const keys = [
      'amount',
      'points',
      'pointsEarned',
      'pointsAwarded',
      'pointsCredited',
      'value',
      'credit',
    ];
    for (final k in keys) {
      final v = txn[k];
      if (v == null) continue;
      final n = v is num
          ? v
          : num.tryParse(v.toString().replaceAll(RegExp(r'[^0-9.\-]'), ''));
      if (n != null && n != 0) return n;
    }
    return 0;
  }

  Widget _buildHistoryItem(dynamic txn) {
    final type = (txn['type'] ?? 'Referral').toString().toUpperCase();
    final date = txn['createdAt'] != null
        ? DateTime.parse(txn['createdAt'].toString())
        : DateTime.now();
    final amount = _txnAmount(txn);
    final status = (txn['status'] ?? 'Completed').toString().toUpperCase();
    final isRedemption = type == 'REDEMPTION' || type == 'WITHDRAWAL';

    final theme = Theme.of(context);
    final foreground = theme.colorScheme.onSurface;

    return Container(
      margin: const EdgeInsets.only(bottom: 8),
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: theme.cardColor.withOpacity(0.2),
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: foreground.withOpacity(0.05)),
      ),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  type,
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                  style: GoogleFonts.inter(
                    color: foreground,
                    fontSize: 13,
                    fontWeight: FontWeight.w700,
                  ),
                ),
                const SizedBox(height: 3),
                Text(
                  DateFormat('dd/MM/yyyy').format(date),
                  style: GoogleFonts.inter(
                    color: foreground.withOpacity(0.72),
                    fontSize: 11,
                    fontWeight: FontWeight.w500,
                  ),
                ),
              ],
            ),
          ),
          const SizedBox(width: 12),
          Column(
            crossAxisAlignment: CrossAxisAlignment.end,
            children: [
              Text(
                '${isRedemption ? '-' : '+'}${NumberFormat('#,###').format(amount)}',
                maxLines: 1,
                style: GoogleFonts.inter(
                  color: isRedemption
                      ? const Color(0xFFC65B46)
                      : const Color(0xFF163A2C),
                  fontSize: 14,
                  fontWeight: FontWeight.w700,
                  fontStyle: FontStyle.italic,
                ),
              ),
              const SizedBox(height: 2),
              Text(
                'STATUS: $status',
                maxLines: 1,
                style: GoogleFonts.inter(
                  color: foreground.withOpacity(0.72),
                  fontSize: 9,
                  fontWeight: FontWeight.w600,
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }

  void _showReferralForm() {
    final nameController = TextEditingController();
    final phoneController = TextEditingController();
    final emailController = TextEditingController();
    String selectedProjectName = '';
    String selectedProjectId = '';
    bool isProjectDropdownOpen = false;
    bool isLoading = false;

    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (context) {
        return StatefulBuilder(
          builder: (context, setModalState) {
            final theme = Theme.of(context);
            final foreground = theme.colorScheme.onSurface;
            return Container(
              padding: EdgeInsets.only(
                left: 32,
                right: 32,
                top: 40,
                bottom: MediaQuery.of(context).viewInsets.bottom + 40,
              ),
              decoration: BoxDecoration(
                color: theme.scaffoldBackgroundColor,
                borderRadius: const BorderRadius.vertical(
                  top: Radius.circular(40),
                ),
                border: Border.all(color: foreground.withOpacity(0.1)),
              ),
              child: SingleChildScrollView(
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      'REFER FRIEND',
                      style: GoogleFonts.gelasio(
                        color: foreground,
                        fontSize: 24,
                        fontWeight: FontWeight.w700,
                      ),
                    ),
                    const SizedBox(height: 8),
                    Text(
                      'ADD TO YOUR SUCCESS MATRIX',
                      style: GoogleFonts.gelasio(
                        color: foreground.withOpacity(0.72),
                        fontSize: 10,
                        fontWeight: FontWeight.w700,
                        letterSpacing: 3,
                      ),
                    ),
                    const SizedBox(height: 48),

                    Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          'SELECT PROJECT',
                          style: GoogleFonts.inter(
                            color: foreground.withOpacity(0.72),
                            fontSize: 10,
                            fontWeight: FontWeight.w600,
                            letterSpacing: 1,
                          ),
                        ),
                        const SizedBox(height: 8),
                        GestureDetector(
                          onTap: () => setModalState(
                            () =>
                                isProjectDropdownOpen = !isProjectDropdownOpen,
                          ),
                          child: Container(
                            height: 56,
                            padding: const EdgeInsets.symmetric(horizontal: 20),
                            decoration: BoxDecoration(
                              color: foreground.withOpacity(0.05),
                              borderRadius: BorderRadius.circular(16),
                              border: Border.all(
                                color: foreground.withOpacity(0.1),
                              ),
                            ),
                            child: Row(
                              children: [
                                Text(
                                  selectedProjectName.isEmpty
                                      ? 'CHOOSE PROJECT'
                                      : selectedProjectName.toUpperCase(),
                                  style: GoogleFonts.inter(
                                    color: selectedProjectName.isEmpty
                                        ? foreground.withOpacity(0.72)
                                        : foreground,
                                    fontSize: 10,
                                    fontWeight: FontWeight.w600,
                                  ),
                                ),
                                const Spacer(),
                                Icon(
                                  isProjectDropdownOpen
                                      ? LucideIcons.chevronUp
                                      : LucideIcons.chevronDown,
                                  color: foreground.withOpacity(0.4),
                                  size: 16,
                                ),
                              ],
                            ),
                          ),
                        ),
                        if (isProjectDropdownOpen) ...[
                          const SizedBox(height: 4),
                          Container(
                            constraints: const BoxConstraints(maxHeight: 200),
                            decoration: BoxDecoration(
                              color: theme.cardColor,
                              borderRadius: BorderRadius.circular(16),
                              border: Border.all(
                                color: foreground.withOpacity(0.05),
                              ),
                            ),
                            child: Consumer(
                              builder: (context, ref, child) {
                                final projectsAsync = ref.watch(
                                  projectsProvider,
                                );
                                return projectsAsync.when(
                                  data: (projects) {
                                    if (projects.isEmpty) {
                                      return Center(
                                        child: Padding(
                                          padding: const EdgeInsets.all(20),
                                          child: Text(
                                            'No projects available',
                                            style: TextStyle(
                                              color: foreground.withOpacity(
                                                0.72,
                                              ),
                                            ),
                                          ),
                                        ),
                                      );
                                    }
                                    return SingleChildScrollView(
                                      child: Column(
                                        children: projects.map((p) {
                                          final name =
                                              p['title'] ??
                                              p['name'] ??
                                              'UNKNOWN PROJECT';
                                          final isSelected =
                                              selectedProjectId == p['_id'];
                                          return GestureDetector(
                                            onTap: () => setModalState(() {
                                              selectedProjectName = name;
                                              selectedProjectId =
                                                  p['_id'] ?? '';
                                              isProjectDropdownOpen = false;
                                            }),
                                            child: Container(
                                              width: double.infinity,
                                              padding:
                                                  const EdgeInsets.symmetric(
                                                    horizontal: 20,
                                                    vertical: 16,
                                                  ),
                                              decoration: BoxDecoration(
                                                color: isSelected
                                                    ? theme.colorScheme.primary
                                                          .withOpacity(0.1)
                                                    : Colors.transparent,
                                                borderRadius:
                                                    BorderRadius.circular(12),
                                              ),
                                              child: Text(
                                                name.toString().toUpperCase(),
                                                style: GoogleFonts.inter(
                                                  color: isSelected
                                                      ? theme
                                                            .colorScheme
                                                            .primary
                                                      : foreground.withOpacity(
                                                          0.6,
                                                        ),
                                                  fontSize: 10,
                                                  fontWeight: FontWeight.w600,
                                                ),
                                              ),
                                            ),
                                          );
                                        }).toList(),
                                      ),
                                    );
                                  },
                                  loading: () => Center(
                                    child: Padding(
                                      padding: const EdgeInsets.all(20),
                                      child: CircularProgressIndicator(
                                        strokeWidth: 2,
                                        color: foreground,
                                      ),
                                    ),
                                  ),
                                  error: (e, s) => const Padding(
                                    padding: EdgeInsets.all(20),
                                    child: Text(
                                      'Failed to load projects',
                                      style: TextStyle(color: Colors.red),
                                    ),
                                  ),
                                );
                              },
                            ),
                          ),
                        ],
                      ],
                    ),

                    const SizedBox(height: 24),
                    _buildInputField(
                      'FRIEND NAME',
                      'Enter Full Name',
                      nameController,
                    ),
                    const SizedBox(height: 24),
                    _buildInputField(
                      'MOBILE NUMBER',
                      'Enter Mobile Number',
                      phoneController,
                      isPhone: true,
                    ),
                    const SizedBox(height: 24),
                    // Web parity: the web form carries an optional email.
                    _buildInputField(
                      'EMAIL (OPTIONAL)',
                      'Enter Email Address',
                      emailController,
                      isEmail: true,
                    ),
                    const SizedBox(height: 48),

                    GestureDetector(
                      behavior: HitTestBehavior.opaque,
                      onTap: isLoading
                          ? null
                          : () async {
                              final email = emailController.text.trim();
                              final vErr =
                                  Validators.nameError(
                                    nameController.text,
                                    field: 'friend name',
                                  ) ??
                                  Validators.phoneError(phoneController.text) ??
                                  // Optional: only validated when filled in.
                                  (email.isEmpty
                                      ? null
                                      : Validators.emailError(email));
                              if (selectedProjectName.isEmpty) {
                                ScaffoldMessenger.of(context).showSnackBar(
                                  const SnackBar(
                                    content: Text('Please select a project.'),
                                    backgroundColor: Colors.redAccent,
                                    duration: Duration(seconds: 2),
                                  ),
                                );
                                return;
                              }
                              if (vErr != null) {
                                ScaffoldMessenger.of(context).showSnackBar(
                                  SnackBar(
                                    content: Text(vErr),
                                    backgroundColor: Colors.redAccent,
                                    duration: const Duration(seconds: 2),
                                  ),
                                );
                                return;
                              }
                              setModalState(() => isLoading = true);
                              try {
                                final apiClient = ref.read(apiClientProvider);
                                final response = await apiClient.submitReferral({
                                  // projectId, like the CP and investor forms
                                  // — the server keys off the ObjectId, not the
                                  // title. projectName is kept alongside it.
                                  'projectId': selectedProjectId,
                                  'projectName': selectedProjectName,
                                  'referralName': nameController.text.trim(),
                                  'referralPhone': phoneController.text.trim(),
                                  // Same key the investor referral form posts.
                                  if (email.isNotEmpty) 'referralEmail': email,
                                });

                                if (response.data['status'] == true ||
                                    response.statusCode == 200 ||
                                    response.statusCode == 201) {
                                  if (mounted) {
                                    Navigator.pop(context);
                                    _fetchReferralData();
                                    ScaffoldMessenger.of(context).showSnackBar(
                                      const SnackBar(
                                        content: Text(
                                          'Referral recorded successfully!',
                                        ),
                                        backgroundColor: Colors.green,
                                      ),
                                    );
                                  }
                                } else {
                                  if (mounted) {
                                    ScaffoldMessenger.of(context).showSnackBar(
                                      SnackBar(
                                        backgroundColor: const Color(
                                          0xFFC65B46,
                                        ),
                                        content: Text(
                                          response.data['message'] ??
                                              'Submission failed.',
                                        ),
                                      ),
                                    );
                                  }
                                }
                              } catch (e) {
                                if (mounted) {
                                  ScaffoldMessenger.of(context).showSnackBar(
                                    const SnackBar(
                                      backgroundColor: Color(0xFFC65B46),
                                      content: Text(
                                        'Submission error. Check your connection.',
                                      ),
                                    ),
                                  );
                                }
                              } finally {
                                if (mounted)
                                  setModalState(() => isLoading = false);
                              }
                            },
                      child: Container(
                        width: double.infinity,
                        height: 64,
                        decoration: BoxDecoration(
                          color: theme.colorScheme.onSurface,
                          borderRadius: BorderRadius.circular(16),
                          boxShadow: [
                            BoxShadow(
                              color: theme.colorScheme.onSurface.withOpacity(
                                0.2,
                              ),
                              blurRadius: 20,
                              offset: const Offset(0, 10),
                            ),
                          ],
                        ),
                        alignment: Alignment.center,
                        child: isLoading
                            ? CircularProgressIndicator(
                                color: theme.colorScheme.surface,
                                strokeWidth: 2,
                              )
                            : Padding(
                                padding: const EdgeInsets.symmetric(
                                  horizontal: 16,
                                ),
                                child: FittedBox(
                                  fit: BoxFit.scaleDown,
                                  child: Text(
                                    'SUBMIT LEAD VERIFICATION',
                                    maxLines: 1,
                                    style: GoogleFonts.gelasio(
                                      color: theme.colorScheme.surface,
                                      fontSize: 12,
                                      fontWeight: FontWeight.w700,
                                      letterSpacing: 2,
                                    ),
                                  ),
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

  Widget _buildInputField(
    String label,
    String hint,
    TextEditingController controller, {
    bool isDropdown = false,
    bool isPhone = false,
    bool isEmail = false,
  }) {
    final foreground = Theme.of(context).colorScheme.onSurface;
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          label,
          style: GoogleFonts.inter(
            color: foreground.withOpacity(0.72),
            fontSize: 10,
            fontWeight: FontWeight.w600,
            letterSpacing: 1,
          ),
        ),
        const SizedBox(height: 8),
        Container(
          height: 56,
          decoration: BoxDecoration(
            color: foreground.withOpacity(0.05),
            borderRadius: BorderRadius.circular(16),
            border: Border.all(color: foreground.withOpacity(0.1)),
          ),
          child: Row(
            children: [
              if (isPhone) ...[
                Padding(
                  padding: const EdgeInsets.only(left: 20, right: 10),
                  child: Text(
                    '+91',
                    style: GoogleFonts.inter(
                      color: foreground,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                ),
                Container(
                  width: 1,
                  height: 20,
                  color: foreground.withOpacity(0.1),
                ),
              ],
              Expanded(
                child: TextField(
                  controller: controller,
                  readOnly: isDropdown,
                  keyboardType: isDropdown
                      ? null
                      : isPhone
                      ? TextInputType.phone
                      : isEmail
                      ? TextInputType.emailAddress
                      : TextInputType.name,
                  inputFormatters: isDropdown || isEmail
                      ? null
                      : isPhone
                      ? Validators.phoneFormatters
                      : Validators.nameFormatters,
                  style: GoogleFonts.inter(
                    color: foreground,
                    fontSize: 15,
                    fontWeight: FontWeight.w600,
                  ),
                  decoration: InputDecoration(
                    hintText: hint,
                    hintStyle: GoogleFonts.inter(
                      color: foreground.withOpacity(0.72),
                      fontSize: 10,
                      fontWeight: FontWeight.w600,
                    ),
                    filled: false,
                    border: InputBorder.none,
                    enabledBorder: InputBorder.none,
                    focusedBorder: InputBorder.none,
                    contentPadding: const EdgeInsets.symmetric(horizontal: 20),
                    suffixIcon: isDropdown
                        ? Icon(
                            LucideIcons.chevronDown,
                            color: foreground.withOpacity(0.24),
                            size: 16,
                          )
                        : null,
                  ),
                ),
              ),
            ],
          ),
        ),
      ],
    );
  }
}
