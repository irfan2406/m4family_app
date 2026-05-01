import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:lucide_icons/lucide_icons.dart';
import 'package:m4_mobile/core/providers/theme_provider.dart';
import 'package:m4_mobile/presentation/providers/auth_provider.dart';
import 'package:flutter/services.dart';
import 'package:m4_mobile/core/network/api_client.dart';
import 'package:m4_mobile/presentation/screens/profile/referral_redeem_screen.dart';
import 'package:m4_mobile/presentation/providers/project_provider.dart';
import 'package:dio/dio.dart';
import 'package:flutter_animate/flutter_animate.dart';
import 'package:intl/intl.dart';

class ReferralScreen extends ConsumerStatefulWidget {
  const ReferralScreen({super.key});

  @override
  ConsumerState<ReferralScreen> createState() => _ReferralScreenState();
}

class _ReferralScreenState extends ConsumerState<ReferralScreen> {
  bool _isLoading = true;
  double _walletBalance = 0;
  double _cashBalance = 0;
  String _referralCode = '';
  List<dynamic> _referrals = [];
  List<dynamic> _history = [];

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
          _walletBalance = double.tryParse(data['walletBalance'].toString()) ?? 0;
          _cashBalance = double.tryParse(data['cashBalance'].toString()) ?? 0;
          _referrals = data['activeReferrals'] ?? [];
          _history = data['transactions'] ?? [];
        });
      } else {
        _walletBalance = double.tryParse(user?['loyaltyPoints']?.toString() ?? '0') ?? 0;
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
        child: Column(
          children: [
            _buildHeader(),
            Expanded(
              child: _isLoading 
                ? Center(child: CircularProgressIndicator(color: colorScheme.primary, strokeWidth: 2))
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
                          _buildPremiumRewardsCard(),
                          const SizedBox(height: 32),
                          _buildActionGrid(),
                          const SizedBox(height: 48),
                          _buildSectionHeader('ACTIVE PIPELINE', LucideIcons.trendingUp),
                          const SizedBox(height: 16),
                          _buildLeadsPipeline(),
                          const SizedBox(height: 48),
                          _buildSectionHeader('POINT HISTORY', LucideIcons.history),
                          const SizedBox(height: 16),
                          _buildHistoryList(),
                          const SizedBox(height: 40),
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
                child: Icon(LucideIcons.chevronLeft, color: foreground, size: 16),
              ),
            ),
          ),
          Text(
            'REWARDS HUB',
            style: GoogleFonts.montserrat(
              color: foreground,
              fontSize: 14,
              fontWeight: FontWeight.w900,
              letterSpacing: 2,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildPremiumRewardsCard() {
    final theme = Theme.of(context);
    final isDark = theme.brightness == Brightness.dark;
    final cardBg = isDark ? theme.cardColor : const Color(0xFF09090B);
    final cardFg = Colors.white;

    return Container(
      width: double.infinity,
      decoration: BoxDecoration(
        color: cardBg,
        borderRadius: BorderRadius.circular(40),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.3),
            blurRadius: 30,
            offset: const Offset(0, 15),
          ),
        ],
      ),
      child: Stack(
        children: [
          Positioned(
            right: -20,
            top: 20,
            child: Opacity(
              opacity: 0.1,
              child: Icon(LucideIcons.gift, size: 140, color: cardFg),
            ),
          ),
          Padding(
            padding: const EdgeInsets.all(32),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  'M4 REWARD POINTS',
                  style: GoogleFonts.montserrat(
                    color: cardFg.withOpacity(0.4),
                    fontSize: 10,
                    fontWeight: FontWeight.w800,
                    letterSpacing: 1.5,
                  ),
                ),
                const SizedBox(height: 8),
                Row(
                  crossAxisAlignment: CrossAxisAlignment.end,
                  children: [
                    Text(
                      NumberFormat('#,###').format(_walletBalance),
                      style: GoogleFonts.montserrat(
                        color: cardFg,
                        fontSize: 48,
                        fontWeight: FontWeight.w900,
                        height: 1,
                        fontStyle: FontStyle.italic,
                      ),
                    ),
                    const SizedBox(width: 8),
                    Padding(
                      padding: const EdgeInsets.only(bottom: 6),
                      child: Text(
                        'PTS',
                        style: GoogleFonts.montserrat(
                          color: cardFg.withOpacity(0.4),
                          fontSize: 14,
                          fontWeight: FontWeight.w900,
                        ),
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 12),
                Row(
                  children: [
                    _buildPill('VALUE: ₹${NumberFormat('#,###').format(_walletBalance)}', cardFg.withOpacity(0.1)),
                    const Spacer(),
                    _buildPill('CASH: ₹${NumberFormat('#,###').format(_cashBalance)}', const Color(0xFF10B981)),
                  ],
                ),
                const SizedBox(height: 32),
                GestureDetector(
                  onTap: () => Navigator.push(context, MaterialPageRoute(builder: (context) => ReferralRedeemScreen(walletBalance: _walletBalance))),
                  child: Container(
                    height: 64,
                    width: double.infinity,
                    decoration: BoxDecoration(
                      color: Colors.white,
                      borderRadius: BorderRadius.circular(20),
                      boxShadow: [
                        BoxShadow(color: Colors.black.withOpacity(0.1), blurRadius: 10, offset: const Offset(0, 5)),
                      ],
                    ),
                    alignment: Alignment.center,
                    child: Row(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        Text(
                          'REDEEM POINTS',
                          style: GoogleFonts.montserrat(
                            color: Colors.black,
                            fontSize: 12,
                            fontWeight: FontWeight.w900,
                            letterSpacing: 1,
                          ),
                        ),
                        const SizedBox(width: 12),
                        const Icon(LucideIcons.checkCircle2, color: Colors.black, size: 18),
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

  Widget _buildPill(String label, Color color) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
      decoration: BoxDecoration(
        color: color,
        borderRadius: BorderRadius.circular(8),
      ),
      child: Text(
        label,
        style: GoogleFonts.montserrat(
          color: Colors.white,
          fontSize: 8,
          fontWeight: FontWeight.w900,
          letterSpacing: 0.5,
        ),
      ),
    );
  }

  Widget _buildActionGrid() {
    return Row(
      children: [
        Expanded(child: _buildActionCard('REFER FRIEND', LucideIcons.users, _showReferralForm)),
        const SizedBox(width: 16),
        Expanded(child: _buildActionCard('SHARE APP', LucideIcons.share2, () {
          Clipboard.setData(ClipboardData(text: _referralCode));
          ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('App link & code copied!')));
        })),
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
          borderRadius: BorderRadius.circular(32),
          border: Border.all(color: foreground.withOpacity(0.05)),
        ),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(icon, color: theme.colorScheme.primary, size: 24),
            const SizedBox(height: 12),
            Text(
              label,
              style: GoogleFonts.montserrat(
                color: foreground.withOpacity(0.4),
                fontSize: 8,
                fontWeight: FontWeight.w900,
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
          style: GoogleFonts.montserrat(
            color: foreground.withOpacity(0.3),
            fontSize: 10,
            fontWeight: FontWeight.w800,
            letterSpacing: 1.5,
          ),
        ),
        const Spacer(),
        Icon(icon, color: foreground.withOpacity(0.1), size: 14),
      ],
    );
  }

  Widget _buildLeadsPipeline() {
    if (_referrals.isEmpty) {
      return Center(
        child: Padding(
          padding: const EdgeInsets.symmetric(vertical: 40),
          child: Text(
            'NO ACTIVE LEADS',
            style: GoogleFonts.montserrat(
              color: Theme.of(context).colorScheme.onSurface.withOpacity(0.1),
              fontSize: 10,
              fontWeight: FontWeight.w900,
              letterSpacing: 2,
            ),
          ),
        ),
      );
    }

    return Column(
      children: _referrals.map((lead) => _buildLeadCard(lead)).toList(),
    );
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
                        style: GoogleFonts.montserrat(color: foreground, fontSize: 12, fontWeight: FontWeight.w900, letterSpacing: -0.5),
                      ),
                      const SizedBox(height: 4),
                      Text(
                        project.toString().toUpperCase(),
                        style: GoogleFonts.montserrat(color: foreground.withOpacity(0.3), fontSize: 8, fontWeight: FontWeight.w900, fontStyle: FontStyle.italic),
                      ),
                    ],
                  ),
                ),
                Container(
                  padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
                  decoration: BoxDecoration(
                    color: theme.colorScheme.primary.withOpacity(0.05),
                    borderRadius: BorderRadius.circular(8),
                    border: Border.all(color: theme.colorScheme.primary.withOpacity(0.2)),
                  ),
                  child: Text(
                    status,
                    style: GoogleFonts.montserrat(
                      color: theme.colorScheme.primary,
                      fontSize: 7,
                      fontWeight: FontWeight.w900,
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
                  style: GoogleFonts.montserrat(color: foreground.withOpacity(0.3), fontSize: 7, fontWeight: FontWeight.w900, letterSpacing: 1),
                ),
                Text(
                  '${NumberFormat('#,###').format(points)} PTS',
                  style: GoogleFonts.montserrat(color: const Color(0xFFF59E0B), fontSize: 10, fontWeight: FontWeight.w900, fontStyle: FontStyle.italic),
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
            style: GoogleFonts.montserrat(
              color: Theme.of(context).colorScheme.onSurface.withOpacity(0.1),
              fontSize: 10,
              fontWeight: FontWeight.w900,
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

  Widget _buildHistoryItem(dynamic txn) {
    final type = (txn['type'] ?? 'Referral').toString().toUpperCase();
    final date = txn['createdAt'] != null ? DateTime.parse(txn['createdAt'].toString()) : DateTime.now();
    final amount = txn['amount'] ?? 0;
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
          Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                type,
                style: GoogleFonts.montserrat(color: foreground, fontSize: 9, fontWeight: FontWeight.w900),
              ),
              const SizedBox(height: 2),
              Text(
                DateFormat('dd/MM/yyyy').format(date),
                style: GoogleFonts.montserrat(color: foreground.withOpacity(0.3), fontSize: 7, fontWeight: FontWeight.w800),
              ),
            ],
          ),
          Column(
            crossAxisAlignment: CrossAxisAlignment.end,
            children: [
              Text(
                '${isRedemption ? '-' : '+'}$amount',
                style: GoogleFonts.montserrat(
                  color: isRedemption ? Colors.redAccent : const Color(0xFF10B981),
                  fontSize: 10,
                  fontWeight: FontWeight.w900,
                  fontStyle: FontStyle.italic,
                ),
              ),
              Text(
                'STATUS: $status',
                style: GoogleFonts.montserrat(color: foreground.withOpacity(0.2), fontSize: 6, fontWeight: FontWeight.w900),
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
                left: 32, right: 32, top: 40,
                bottom: MediaQuery.of(context).viewInsets.bottom + 40,
              ),
              decoration: BoxDecoration(
                color: theme.scaffoldBackgroundColor,
                borderRadius: const BorderRadius.vertical(top: Radius.circular(40)),
                border: Border.all(color: foreground.withOpacity(0.1)),
              ),
              child: Column(
                mainAxisSize: MainAxisSize.min,
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    'REFER FRIEND',
                    style: GoogleFonts.montserrat(color: foreground, fontSize: 24, fontWeight: FontWeight.w900, fontStyle: FontStyle.italic),
                  ),
                  const SizedBox(height: 8),
                  Text(
                    'ADD TO YOUR SUCCESS MATRIX',
                    style: GoogleFonts.montserrat(
                      color: foreground.withOpacity(0.3),
                      fontSize: 9,
                      fontWeight: FontWeight.w900,
                      letterSpacing: 3,
                    ),
                  ),
                  const SizedBox(height: 48),
                  
                  Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        'SELECT PROJECT',
                        style: GoogleFonts.montserrat(color: foreground.withOpacity(0.4), fontSize: 8, fontWeight: FontWeight.w900, letterSpacing: 1),
                      ),
                      const SizedBox(height: 8),
                      GestureDetector(
                        onTap: () => setModalState(() => isProjectDropdownOpen = !isProjectDropdownOpen),
                        child: Container(
                          height: 56,
                          padding: const EdgeInsets.symmetric(horizontal: 20),
                          decoration: BoxDecoration(
                            color: foreground.withOpacity(0.05),
                            borderRadius: BorderRadius.circular(16),
                            border: Border.all(color: foreground.withOpacity(0.1)),
                          ),
                          child: Row(
                            children: [
                              Text(
                                selectedProjectName.isEmpty ? 'CHOOSE OPPORTUNITY' : selectedProjectName.toUpperCase(),
                                style: GoogleFonts.montserrat(
                                  color: selectedProjectName.isEmpty ? foreground.withOpacity(0.4) : foreground, 
                                  fontSize: 10, 
                                  fontWeight: FontWeight.w900
                                ),
                              ),
                              const Spacer(),
                              Icon(
                                isProjectDropdownOpen ? LucideIcons.chevronUp : LucideIcons.chevronDown, 
                                color: foreground.withOpacity(0.4), 
                                size: 16
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
                            border: Border.all(color: foreground.withOpacity(0.05)),
                          ),
                          child: Consumer(
                            builder: (context, ref, child) {
                              final projectsAsync = ref.watch(projectsProvider);
                              return projectsAsync.when(
                                data: (projects) {
                                  if (projects.isEmpty) {
                                    return Center(child: Padding(padding: const EdgeInsets.all(20), child: Text('No projects available', style: TextStyle(color: foreground.withOpacity(0.38)))));
                                  }
                                  return SingleChildScrollView(
                                    child: Column(
                                      children: projects.map((p) {
                                        final name = p['title'] ?? p['name'] ?? 'UNKNOWN PROJECT';
                                        final isSelected = selectedProjectId == p['_id'];
                                        return GestureDetector(
                                          onTap: () => setModalState(() {
                                            selectedProjectName = name;
                                            selectedProjectId = p['_id'] ?? '';
                                            isProjectDropdownOpen = false;
                                          }),
                                          child: Container(
                                            width: double.infinity,
                                            padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 16),
                                            decoration: BoxDecoration(
                                              color: isSelected ? theme.colorScheme.primary.withOpacity(0.1) : Colors.transparent,
                                              borderRadius: BorderRadius.circular(12),
                                            ),
                                            child: Text(
                                              name.toString().toUpperCase(),
                                              style: GoogleFonts.montserrat(
                                                color: isSelected ? theme.colorScheme.primary : foreground.withOpacity(0.6),
                                                fontSize: 10,
                                                fontWeight: FontWeight.w900,
                                              ),
                                            ),
                                          ),
                                        );
                                      }).toList(),
                                    ),
                                  );
                                },
                                loading: () => Center(child: Padding(padding: const EdgeInsets.all(20), child: CircularProgressIndicator(strokeWidth: 2, color: foreground))),
                                error: (e, s) => const Padding(padding: EdgeInsets.all(20), child: Text('Failed to load projects', style: TextStyle(color: Colors.red))),
                              );
                            },
                          ),
                        ),
                      ],
                    ],
                  ),

                  const SizedBox(height: 24),
                  _buildInputField('FRIEND NAME', 'FULL NAME', nameController),
                  const SizedBox(height: 24),
                  _buildInputField('MOBILE NUMBER', 'MOBILE NUMBER', phoneController, isPhone: true),
                  const SizedBox(height: 48),
                  
                  GestureDetector(
                    behavior: HitTestBehavior.opaque,
                    onTap: isLoading ? null : () async {
                      if (nameController.text.isEmpty || phoneController.text.isEmpty || selectedProjectName.isEmpty) {
                         ScaffoldMessenger.of(context).showSnackBar(const SnackBar(
                           content: Text('All fields are required.'),
                           backgroundColor: Colors.redAccent,
                           duration: Duration(seconds: 2),
                         ));
                         return;
                      }
                      setModalState(() => isLoading = true);
                      try {
                        final apiClient = ref.read(apiClientProvider);
                        final response = await apiClient.submitReferral({
                          'projectName': selectedProjectName,
                          'referralName': nameController.text,
                          'referralPhone': phoneController.text,
                        });
                        
                        if (response.data['status'] == true || response.statusCode == 200 || response.statusCode == 201) {
                          if (mounted) {
                            Navigator.pop(context);
                            _fetchReferralData();
                            ScaffoldMessenger.of(context).showSnackBar(const SnackBar(
                              content: Text('Referral recorded successfully!'),
                              backgroundColor: Colors.green,
                            ));
                          }
                        } else {
                          if (mounted) {
                            ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text(response.data['message'] ?? 'Submission failed.')));
                          }
                        }
                      } catch (e) {
                        if (mounted) {
                          ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('Submission error. Check your connection.')));
                        }
                      } finally {
                        if (mounted) setModalState(() => isLoading = false);
                      }
                    },
                    child: Container(
                      width: double.infinity,
                      height: 64,
                      decoration: BoxDecoration(
                        color: theme.colorScheme.onSurface,
                        borderRadius: BorderRadius.circular(16),
                        boxShadow: [
                          BoxShadow(color: theme.colorScheme.onSurface.withOpacity(0.2), blurRadius: 20, offset: const Offset(0, 10)),
                        ],
                      ),
                      alignment: Alignment.center,
                      child: isLoading
                        ? CircularProgressIndicator(color: theme.colorScheme.surface, strokeWidth: 2)
                        : Text(
                            'SUBMIT LEAD VERIFICATION',
                            style: GoogleFonts.montserrat(color: theme.colorScheme.surface, fontSize: 10, fontWeight: FontWeight.w900, letterSpacing: 2),
                          ),
                    ),
                  ),
                ],
              ),
            );
          }
        );
      },
    );
  }

  Widget _buildInputField(String label, String hint, TextEditingController controller, {bool isDropdown = false, bool isPhone = false}) {
    final foreground = Theme.of(context).colorScheme.onSurface;
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          label,
          style: GoogleFonts.montserrat(color: foreground.withOpacity(0.4), fontSize: 8, fontWeight: FontWeight.w900, letterSpacing: 1),
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
                  child: Text('+91', style: GoogleFonts.montserrat(color: foreground, fontWeight: FontWeight.bold)),
                ),
                Container(width: 1, height: 20, color: foreground.withOpacity(0.1)),
              ],
              Expanded(
                child: TextField(
                  controller: controller,
                  readOnly: isDropdown,
                  style: GoogleFonts.montserrat(color: foreground, fontSize: 10, fontWeight: FontWeight.w900),
                  decoration: InputDecoration(
                    hintText: hint,
                    hintStyle: GoogleFonts.montserrat(color: foreground.withOpacity(0.2), fontSize: 10, fontWeight: FontWeight.w900),
                    border: InputBorder.none,
                    contentPadding: const EdgeInsets.symmetric(horizontal: 20),
                    suffixIcon: isDropdown ? Icon(LucideIcons.chevronDown, color: foreground.withOpacity(0.24), size: 16) : null,
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
