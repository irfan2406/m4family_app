import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:lucide_icons/lucide_icons.dart';
import 'package:m4_mobile/presentation/providers/auth_provider.dart';
import 'package:m4_mobile/presentation/providers/project_provider.dart';
import 'package:m4_mobile/presentation/screens/profile/referral_redeem_screen.dart';

/// Web `/cp/referral` parity: wallet card + action grid + referral history.
class CpReferralScreen extends ConsumerStatefulWidget {
  const CpReferralScreen({super.key});

  @override
  ConsumerState<CpReferralScreen> createState() => _CpReferralScreenState();
}

class _CpReferralScreenState extends ConsumerState<CpReferralScreen> {
  Map<String, dynamic>? _wallet;
  List<dynamic> _referrals = [];
  bool _loading = true;


  @override
  void initState() {
    super.initState();
    _load();
  }

  Future<void> _load() async {
    setState(() => _loading = true);
    try {
      final api = ref.read(apiClientProvider);
      final w = await api.getCpWallet();
      final r = await api.getCpReferrals();
      if (!mounted) return;
      if (w.statusCode == 200 && w.data['status'] == true) {
        final d = w.data['data'];
        if (d is Map) _wallet = Map<String, dynamic>.from(d);
      }
      if (r.statusCode == 200 && r.data['status'] == true) {
        final d = r.data['data'];
        if (d is List) _referrals = List<dynamic>.from(d);
      }
    } catch (_) {}
    if (mounted) setState(() => _loading = false);
  }

  num _balance() {
    final w = _wallet;
    if (w == null) return 0;
    return (w['balance'] ?? w['availableBalance'] ?? 0) as num? ?? 0;
  }

  String _name(dynamic r) => (r['referralName'] ?? r['clientName'] ?? '').toString();
  String _status(dynamic r) => (r['status'] ?? 'Pending').toString();
  String _project(dynamic r) {
    final pid = r['projectId'];
    if (pid is Map) return pid['title']?.toString() ?? '';
    return (r['projectName'] ?? r['interestedProject'] ?? '').toString();
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
            // Header
            Padding(
              padding: const EdgeInsets.fromLTRB(24, 20, 24, 20),
              child: Row(
                children: [
                  GestureDetector(
                    onTap: () => context.pop(),
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
                    child: Text(
                      'REFERRAL & REWARDS',
                      textAlign: TextAlign.center,
                      style: GoogleFonts.montserrat(
                        fontSize: 16,
                        fontWeight: FontWeight.w900,
                        color: scheme.onSurface,
                        letterSpacing: 1.5,
                      ),
                    ),
                  ),
                  const SizedBox(width: 36),
                ],
              ),
            ),

            // Body
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

                            // ─── Wallet Card ─────────────────────
                            _buildWalletCard(scheme, isDark),

                            const SizedBox(height: 20),

                            // ─── Action Grid ─────────────────────
                            _buildActionGrid(scheme, isDark),

                            const SizedBox(height: 32),

                            // ─── Active Referrals ────────────────
                            Text(
                              'ACTIVE REFERRALS',
                              style: GoogleFonts.montserrat(
                                fontSize: 9,
                                fontWeight: FontWeight.w900,
                                letterSpacing: 2,
                                color: scheme.onSurface.withValues(alpha: 0.4),
                              ),
                            ),
                            const SizedBox(height: 16),
                            _buildReferralsList(scheme, isDark),

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

  // ━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━
  // WALLET CARD — matches web CP exactly
  // ━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━
  Widget _buildWalletCard(ColorScheme scheme, bool isDark) {
    final pts = _balance();

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
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                // Label
                Text(
                  'WALLET BALANCE',
                  style: GoogleFonts.montserrat(
                    fontSize: 10,
                    fontWeight: FontWeight.w900,
                    letterSpacing: 2,
                    color: scheme.onSurface.withValues(alpha: 0.4),
                  ),
                ),
                const SizedBox(height: 8),

                // Points display
                Row(
                  crossAxisAlignment: CrossAxisAlignment.baseline,
                  textBaseline: TextBaseline.alphabetic,
                  children: [
                    Text(
                      _formatNumber(pts),
                      style: GoogleFonts.montserrat(
                        fontSize: 48,
                        fontWeight: FontWeight.w900,
                        color: scheme.onSurface,
                        height: 1,
                      ),
                    ),
                    const SizedBox(width: 8),
                    Padding(
                      padding: const EdgeInsets.only(bottom: 4),
                      child: Text(
                        'PTS',
                        style: GoogleFonts.montserrat(
                          fontSize: 18,
                          fontWeight: FontWeight.w900,
                          color: scheme.onSurface.withValues(alpha: 0.3),
                          letterSpacing: 2,
                        ),
                      ),
                    ),
                  ],
                ),

                const SizedBox(height: 4),

                // Value line
                Text(
                  'VALUE: AED ${_formatNumber(pts)}',
                  style: GoogleFonts.montserrat(
                    fontSize: 10,
                    fontWeight: FontWeight.w900,
                    letterSpacing: 2,
                    color: scheme.onSurface.withValues(alpha: 0.4),
                  ),
                ),

                const SizedBox(height: 24),

                // Redeem button
                GestureDetector(
                  onTap: () async {
                    final result = await Navigator.push(
                      context,
                      MaterialPageRoute(
                        builder: (_) => ReferralRedeemScreen(walletBalance: pts.toDouble()),
                      ),
                    );
                    if (result == true && mounted) _load();
                  },
                  child: Container(
                    width: double.infinity,
                    height: 56,
                    decoration: BoxDecoration(
                      color: scheme.onSurface,
                      borderRadius: BorderRadius.circular(16),
                      boxShadow: [
                        BoxShadow(
                          color: scheme.onSurface.withValues(alpha: 0.2),
                          blurRadius: 15,
                          offset: const Offset(0, 8),
                        ),
                      ],
                    ),
                    child: Row(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        Text(
                          'REDEEM NOW',
                          style: GoogleFonts.montserrat(
                            fontSize: 11,
                            fontWeight: FontWeight.w900,
                            letterSpacing: 2,
                            color: scheme.surface,
                          ),
                        ),
                        const SizedBox(width: 12),
                        Icon(LucideIcons.checkCircle2, size: 18, color: scheme.surface),
                      ],
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
  // ACTION GRID — REFER FRIEND / SHARE CODE
  // ━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━
  Widget _buildActionGrid(ColorScheme scheme, bool isDark) {
    return Row(
      children: [
        Expanded(
          child: _buildActionCard(
            scheme: scheme,
            isDark: isDark,
            icon: LucideIcons.users,
            label: 'REFER FRIEND',
            onTap: () => _showReferralForm(scheme, isDark),
          ),
        ),
        const SizedBox(width: 16),
        Expanded(
          child: _buildActionCard(
            scheme: scheme,
            isDark: isDark,
            icon: LucideIcons.share2,
            label: 'SHARE CODE',
            onTap: () {
              final code = _wallet?['cpId']?.toString().substring(0, 6) ?? 'M4FAM-CP';
              Clipboard.setData(ClipboardData(text: code));
              ScaffoldMessenger.of(context).showSnackBar(
                const SnackBar(content: Text('Referral code copied!'), backgroundColor: Colors.green),
              );
            },
          ),
        ),
      ],
    );
  }

  Widget _buildActionCard({
    required ColorScheme scheme,
    required bool isDark,
    required IconData icon,
    required String label,
    required VoidCallback onTap,
  }) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        height: 130,
        decoration: BoxDecoration(
          color: isDark ? scheme.onSurface.withValues(alpha: 0.04) : Colors.white.withValues(alpha: 0.4),
          borderRadius: BorderRadius.circular(32),
          border: Border.all(color: scheme.onSurface.withValues(alpha: 0.08)),
        ),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Container(
              padding: const EdgeInsets.all(14),
              decoration: BoxDecoration(
                color: scheme.onSurface.withValues(alpha: 0.04),
                borderRadius: BorderRadius.circular(16),
                border: Border.all(color: scheme.onSurface.withValues(alpha: 0.08)),
              ),
              child: Icon(icon, size: 22, color: scheme.onSurface),
            ),
            const SizedBox(height: 14),
            Text(
              label,
              style: GoogleFonts.montserrat(
                fontSize: 9,
                fontWeight: FontWeight.w900,
                letterSpacing: 1.5,
                color: scheme.onSurface.withValues(alpha: 0.5),
              ),
            ),
          ],
        ),
      ),
    );
  }

  // ━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━
  // REFERRALS LIST
  // ━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━
  Widget _buildReferralsList(ColorScheme scheme, bool isDark) {
    if (_referrals.isEmpty) {
      return Container(
        width: double.infinity,
        padding: const EdgeInsets.symmetric(vertical: 40),
        decoration: BoxDecoration(
          color: isDark ? scheme.onSurface.withValues(alpha: 0.03) : Colors.white.withValues(alpha: 0.4),
          borderRadius: BorderRadius.circular(20),
          border: Border.all(color: scheme.onSurface.withValues(alpha: 0.06)),
        ),
        child: Center(
          child: Text(
            'NO REFERRALS YET',
            style: GoogleFonts.montserrat(
              fontSize: 10,
              fontWeight: FontWeight.w900,
              letterSpacing: 2,
              color: scheme.onSurface.withValues(alpha: 0.15),
            ),
          ),
        ),
      );
    }

    return Column(
      children: _referrals.map((r) => _buildReferralCard(r, scheme, isDark)).toList(),
    );
  }

  Widget _buildReferralCard(dynamic r, ColorScheme scheme, bool isDark) {
    final name = _name(r);
    final status = _status(r);
    final project = _project(r);

    return Container(
      margin: const EdgeInsets.only(bottom: 12),
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: isDark ? scheme.onSurface.withValues(alpha: 0.03) : Colors.white.withValues(alpha: 0.5),
        borderRadius: BorderRadius.circular(20),
        border: Border.all(color: scheme.onSurface.withValues(alpha: 0.06)),
      ),
      child: Row(
        children: [
          // Icon
          Container(
            padding: const EdgeInsets.all(12),
            decoration: BoxDecoration(
              color: scheme.onSurface.withValues(alpha: 0.04),
              borderRadius: BorderRadius.circular(16),
              border: Border.all(color: scheme.onSurface.withValues(alpha: 0.08)),
            ),
            child: Icon(LucideIcons.users, size: 20, color: scheme.onSurface),
          ),
          const SizedBox(width: 16),

          // Name + Project
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  name.toUpperCase(),
                  style: GoogleFonts.montserrat(
                    fontSize: 13,
                    fontWeight: FontWeight.w800,
                    color: scheme.onSurface,
                  ),
                ),
                if (project.isNotEmpty) ...[
                  const SizedBox(height: 2),
                  Text(
                    project.toUpperCase(),
                    style: GoogleFonts.montserrat(
                      fontSize: 8,
                      fontWeight: FontWeight.w900,
                      letterSpacing: 1.5,
                      color: scheme.primary,
                    ),
                  ),
                ],
              ],
            ),
          ),

          // Status badge
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
            decoration: BoxDecoration(
              color: status == 'CONVERTED'
                  ? scheme.primary.withValues(alpha: 0.1)
                  : scheme.onSurface.withValues(alpha: 0.04),
              borderRadius: BorderRadius.circular(8),
              border: Border.all(color: scheme.onSurface.withValues(alpha: 0.08)),
            ),
            child: Text(
              status.toUpperCase(),
              style: GoogleFonts.montserrat(
                fontSize: 8,
                fontWeight: FontWeight.w900,
                letterSpacing: 1,
                color: status == 'CONVERTED' ? scheme.primary : scheme.onSurface.withValues(alpha: 0.5),
              ),
            ),
          ),
        ],
      ),
    );
  }

  // ━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━
  // REFERRAL FORM — Bottom Sheet (step-based like web)
  // ━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━
  void _showReferralForm(ColorScheme scheme, bool isDark) {
    final nameCtrl = TextEditingController();
    final phoneCtrl = TextEditingController();
    String? selectedProjectId;

    bool submitting = false;

    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (ctx) {
        return StatefulBuilder(
          builder: (ctx, setModalState) {
            return Container(
              padding: EdgeInsets.only(
                left: 28, right: 28, top: 32,
                bottom: MediaQuery.of(ctx).viewInsets.bottom + 32,
              ),
              decoration: BoxDecoration(
                color: isDark ? const Color(0xFF18181B) : Colors.white,
                borderRadius: const BorderRadius.vertical(top: Radius.circular(40)),
              ),
              child: Column(
                mainAxisSize: MainAxisSize.min,
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  // Handle
                  Center(
                    child: Container(
                      width: 40, height: 4,
                      decoration: BoxDecoration(
                        color: scheme.onSurface.withValues(alpha: 0.15),
                        borderRadius: BorderRadius.circular(2),
                      ),
                    ),
                  ),
                  const SizedBox(height: 28),

                  // Title
                  Text(
                    'NEW\nREFERRAL',
                    style: GoogleFonts.montserrat(
                      fontSize: 24,
                      fontWeight: FontWeight.w900,
                      color: scheme.onSurface,
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
                      color: scheme.onSurface.withValues(alpha: 0.3),
                    ),
                  ),
                  const SizedBox(height: 32),

                  // Project selector
                  _buildFormLabel('SELECT PROJECT', scheme),
                  const SizedBox(height: 10),
                  Consumer(
                    builder: (ctx, ref, _) {
                      final projectsAsync = ref.watch(projectsProvider);
                      return projectsAsync.when(
                        loading: () => Container(
                          height: 56,
                          decoration: _inputDecoration(scheme, isDark),
                          child: Center(child: CircularProgressIndicator(strokeWidth: 2, color: scheme.onSurface)),
                        ),
                        error: (_, __) => const Text('Could not load projects'),
                        data: (projects) {
                          return Container(
                            height: 56,
                            padding: const EdgeInsets.symmetric(horizontal: 20),
                            decoration: _inputDecoration(scheme, isDark),
                            child: DropdownButtonHideUnderline(
                              child: DropdownButton<String>(
                                isExpanded: true,
                                value: selectedProjectId,
                                hint: Text(
                                  'SELECT PROJECT',
                                  style: GoogleFonts.montserrat(
                                    fontSize: 11,
                                    fontWeight: FontWeight.w800,
                                    color: scheme.onSurface.withValues(alpha: 0.3),
                                  ),
                                ),
                                dropdownColor: isDark ? const Color(0xFF1C1C1E) : Colors.white,
                                icon: Icon(LucideIcons.chevronDown, size: 16, color: scheme.onSurface.withValues(alpha: 0.3)),
                                items: [
                                  for (final p in projects)
                                    if ((p['_id']?.toString() ?? '').isNotEmpty)
                                      DropdownMenuItem(
                                        value: p['_id'].toString(),
                                        child: Text(
                                          (p['title'] ?? 'Project').toString().toUpperCase(),
                                          style: GoogleFonts.montserrat(
                                            fontSize: 10,
                                            fontWeight: FontWeight.w800,
                                            color: scheme.onSurface,
                                          ),
                                        ),
                                      ),
                                ],
                                onChanged: (v) {
                                  setModalState(() {
                                    selectedProjectId = v;
                                  });
                                },
                              ),
                            ),
                          );
                        },
                      );
                    },
                  ),

                  const SizedBox(height: 20),

                  // Name
                  _buildFormLabel("FRIEND'S NAME", scheme),
                  const SizedBox(height: 10),
                  _buildTextField(nameCtrl, 'FULL NAME', scheme, isDark),

                  const SizedBox(height: 20),

                  // Phone
                  _buildFormLabel('MOBILE NUMBER', scheme),
                  const SizedBox(height: 10),
                  _buildTextField(phoneCtrl, '+91 XXXXX XXXXX', scheme, isDark, isPhone: true),

                  const SizedBox(height: 32),

                  // Submit
                  GestureDetector(
                    onTap: submitting
                        ? null
                        : () async {
                            if (nameCtrl.text.trim().isEmpty || phoneCtrl.text.trim().isEmpty || selectedProjectId == null) {
                              ScaffoldMessenger.of(context).showSnackBar(
                                const SnackBar(content: Text('Please fill all fields'), backgroundColor: Colors.redAccent),
                              );
                              return;
                            }
                            setModalState(() => submitting = true);
                            try {
                              final api = ref.read(apiClientProvider);
                              final res = await api.createCpReferral({
                                'referralName': nameCtrl.text.trim(),
                                'referralPhone': phoneCtrl.text.trim(),
                                'projectId': selectedProjectId,
                                'notes': 'Submitted via Flutter CP Portal',
                              });
                              if (!mounted) return;
                              if (res.statusCode == 201 && res.data['status'] == true) {
                                Navigator.pop(ctx);
                                ScaffoldMessenger.of(context).showSnackBar(
                                  const SnackBar(content: Text('Referral registered!'), backgroundColor: Colors.green),
                                );
                                _load();
                              } else {
                                ScaffoldMessenger.of(context).showSnackBar(
                                  SnackBar(content: Text(res.data['message']?.toString() ?? 'Failed')),
                                );
                              }
                            } catch (e) {
                              if (mounted) {
                                ScaffoldMessenger.of(context).showSnackBar(
                                  const SnackBar(content: Text('Submission error.')),
                                );
                              }
                            } finally {
                              if (mounted) setModalState(() => submitting = false);
                            }
                          },
                    child: Container(
                      width: double.infinity,
                      height: 56,
                      decoration: BoxDecoration(
                        color: scheme.onSurface,
                        borderRadius: BorderRadius.circular(12),
                      ),
                      alignment: Alignment.center,
                      child: submitting
                          ? SizedBox(width: 20, height: 20, child: CircularProgressIndicator(strokeWidth: 2, color: scheme.surface))
                          : Text(
                              'SUBMIT REFERRAL',
                              style: GoogleFonts.montserrat(
                                fontSize: 10,
                                fontWeight: FontWeight.w900,
                                letterSpacing: 2,
                                color: scheme.surface,
                              ),
                            ),
                    ),
                  ),
                ],
              ),
            );
          },
        );
      },
    );
  }

  // ─── Helpers ──────────────────────────────────────────────────
  Widget _buildFormLabel(String text, ColorScheme scheme) {
    return Text(
      text,
      style: GoogleFonts.montserrat(
        fontSize: 9,
        fontWeight: FontWeight.w900,
        letterSpacing: 1.5,
        color: scheme.onSurface.withValues(alpha: 0.3),
      ),
    );
  }

  BoxDecoration _inputDecoration(ColorScheme scheme, bool isDark) {
    return BoxDecoration(
      color: scheme.onSurface.withValues(alpha: isDark ? 0.05 : 0.03),
      borderRadius: BorderRadius.circular(16),
      border: Border.all(color: scheme.onSurface.withValues(alpha: 0.08)),
    );
  }

  Widget _buildTextField(TextEditingController controller, String hint, ColorScheme scheme, bool isDark, {bool isPhone = false}) {
    return Container(
      height: 56,
      decoration: _inputDecoration(scheme, isDark),
      child: TextField(
        controller: controller,
        keyboardType: isPhone ? TextInputType.phone : TextInputType.text,
        style: GoogleFonts.montserrat(
          fontSize: 12,
          fontWeight: FontWeight.w700,
          color: scheme.onSurface,
        ),
        decoration: InputDecoration(
          hintText: hint,
          hintStyle: GoogleFonts.montserrat(
            fontSize: 11,
            fontWeight: FontWeight.w800,
            color: scheme.onSurface.withValues(alpha: 0.2),
          ),
          border: InputBorder.none,
          contentPadding: const EdgeInsets.symmetric(horizontal: 20),
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
