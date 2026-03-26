import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:lucide_icons/lucide_icons.dart';
import 'package:m4_mobile/core/providers/theme_provider.dart';
import 'package:m4_mobile/presentation/providers/auth_provider.dart';
import 'package:flutter/services.dart';
import 'package:m4_mobile/core/network/api_client.dart';
import 'package:m4_mobile/presentation/screens/profile/referral_redeem_screen.dart';
import 'package:dio/dio.dart';

class ReferralScreen extends ConsumerStatefulWidget {
  const ReferralScreen({super.key});

  @override
  ConsumerState<ReferralScreen> createState() => _ReferralScreenState();
}

class _ReferralScreenState extends ConsumerState<ReferralScreen> {
  bool _isLoading = true;
  double _walletBalance = 0;
  String _referralCode = '';
  List<dynamic> _referrals = [];

  @override
  void initState() {
    super.initState();
    _fetchReferralData();
  }

  Future<void> _fetchReferralData() async {
    try {
      final apiClient = ref.read(apiClientProvider);
      final user = ref.read(authProvider).user;
      
      // 1. Get Wallet Balance (Try Investor API first, fallback to user model)
      try {
        final walletRes = await apiClient.getInvestorWallet();
        if (walletRes.data['status'] == true) {
          _walletBalance = double.tryParse(walletRes.data['data']['balance'].toString()) ?? 0;
        }
      } catch (e) {
        _walletBalance = double.tryParse(user?['loyaltyPoints']?.toString() ?? '0') ?? 0;
      }

      // 2. Get Referral Code from user model
      _referralCode = user?['referralCode'] ?? 'M4-GEN-001';

      // 3. Get Referrals List
      try {
        final refRes = await apiClient.getInvestorReferrals();
        if (refRes.data['status'] == true && refRes.data['data'] is List) {
          _referrals = refRes.data['data'];
        }
      } catch (e) {
        _referrals = [];
      }

      if (mounted) setState(() => _isLoading = false);
    } catch (e) {
      if (mounted) setState(() => _isLoading = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    final themeMode = ref.watch(themeProvider);
    final isDark = themeMode == ThemeMode.dark;

    return Scaffold(
      backgroundColor: Theme.of(context).scaffoldBackgroundColor,
      appBar: AppBar(
        backgroundColor: Colors.transparent,
        elevation: 0,
        leading: IconButton(
          icon: Icon(LucideIcons.chevronLeft, color: isDark ? Colors.white : Colors.black),
          onPressed: () => Navigator.pop(context),
        ),
        title: Text(
          'REFERRAL & REWARDS',
          style: GoogleFonts.montserrat(
            color: isDark ? Colors.white : Colors.black,
            fontSize: 14,
            fontWeight: FontWeight.w900,
            letterSpacing: 2,
          ),
        ),
        centerTitle: true,
      ),
      body: _isLoading 
        ? const Center(child: CircularProgressIndicator())
        : RefreshIndicator(
            onRefresh: _fetchReferralData,
            child: SingleChildScrollView(
              padding: const EdgeInsets.symmetric(horizontal: 20),
              child: Column(
                children: [
                  const SizedBox(height: 20),
                  _buildWalletCard(isDark),
                  const SizedBox(height: 30),
                  _buildReferralOptions(isDark),
                  const SizedBox(height: 30),
                  _buildActiveReferrals(isDark),
                  const SizedBox(height: 100),
                ],
              ),
            ),
          ),
    );
  }

  Widget _buildWalletCard(bool isDark) {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(30),
      decoration: BoxDecoration(
        color: isDark ? const Color(0xFF0A0C10) : Colors.white,
        borderRadius: BorderRadius.circular(30),
        border: Border.all(color: (isDark ? Colors.white : Colors.black).withOpacity(0.05)),
        boxShadow: isDark ? null : [
          BoxShadow(color: Colors.black.withOpacity(0.05), blurRadius: 20, offset: const Offset(0, 10)),
        ],
      ),
      child: Column(
        children: [
          Text(
            'WALLET BALANCE',
            style: GoogleFonts.montserrat(
              color: isDark ? Colors.white24 : Colors.black26,
              fontSize: 10,
              fontWeight: FontWeight.w800,
              letterSpacing: 2,
            ),
          ),
          const SizedBox(height: 10),
          Row(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Text(
                _walletBalance.toStringAsFixed(0),
                style: GoogleFonts.montserrat(
                  color: isDark ? Colors.white : Colors.black,
                  fontSize: 48,
                  fontWeight: FontWeight.w900,
                ),
              ),
              const SizedBox(width: 8),
              Text(
                'PTS',
                style: GoogleFonts.montserrat(
                  color: isDark ? Colors.white38 : Colors.black38,
                  fontSize: 16,
                  fontWeight: FontWeight.w700,
                ),
              ),
            ],
          ),
          const SizedBox(height: 25),
          GestureDetector(
            onTap: () async {
               final result = await Navigator.push(
                 context,
                 MaterialPageRoute(
                   builder: (context) => ReferralRedeemScreen(walletBalance: _walletBalance),
                 ),
               );
               if (result == true && mounted) {
                 _fetchReferralData();
               }
            },
            child: Container(
              padding: const EdgeInsets.symmetric(horizontal: 40, vertical: 15),
              decoration: BoxDecoration(
                color: isDark ? Colors.white : Colors.black,
                borderRadius: BorderRadius.circular(40),
              ),
              child: Text(
                'REDEEM NOW',
                style: GoogleFonts.montserrat(
                  color: isDark ? Colors.black : Colors.white,
                  fontSize: 12,
                  fontWeight: FontWeight.w900,
                  letterSpacing: 1,
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildReferralOptions(bool isDark) {
    return Column(
      children: [
        _buildOptionItem(LucideIcons.userPlus, 'REFER A FRIEND', 'GET 500 PTS PER REF', isDark, () {
          _showReferralForm(isDark);
        }),
        const SizedBox(height: 15),
        _buildOptionItem(LucideIcons.share2, 'SHARE CODE', _referralCode, isDark, () {
          Clipboard.setData(ClipboardData(text: _referralCode));
          ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('Referral code copied to clipboard!')));
        }),
      ],
    );
  }

  Widget _buildOptionItem(IconData icon, String title, String subtitle, bool isDark, VoidCallback onTap) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        padding: const EdgeInsets.all(20),
        decoration: BoxDecoration(
          color: isDark ? const Color(0xFF080A0E) : Colors.white,
          borderRadius: BorderRadius.circular(20),
          border: Border.all(color: (isDark ? Colors.white : Colors.black).withOpacity(0.03)),
        ),
        child: Row(
          children: [
            Container(
              padding: const EdgeInsets.all(12),
              decoration: BoxDecoration(
                color: (isDark ? Colors.white : Colors.black).withOpacity(0.05),
                shape: BoxShape.circle,
              ),
              child: Icon(icon, color: isDark ? Colors.white : Colors.black, size: 20),
            ),
            const SizedBox(width: 20),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    title,
                    style: GoogleFonts.montserrat(
                      color: isDark ? Colors.white : Colors.black,
                      fontSize: 14,
                      fontWeight: FontWeight.w800,
                    ),
                  ),
                  Text(
                    subtitle,
                    style: GoogleFonts.montserrat(
                      color: isDark ? Colors.white38 : Colors.black38,
                      fontSize: 10,
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                ],
              ),
            ),
            Icon(LucideIcons.chevronRight, color: (isDark ? Colors.white : Colors.black).withOpacity(0.1), size: 18),
          ],
        ),
      ),
    );
  }

  Widget _buildActiveReferrals(bool isDark) {
    if (_referrals.isEmpty) {
       return Column(
         crossAxisAlignment: CrossAxisAlignment.start,
         children: [
           Padding(
            padding: const EdgeInsets.only(left: 10, bottom: 15),
            child: Text(
              'ACTIVE REFERRALS',
              style: GoogleFonts.montserrat(
                color: isDark ? Colors.white24 : Colors.black26,
                fontSize: 10,
                fontWeight: FontWeight.w800,
                letterSpacing: 1.5,
              ),
            ),
          ),
          Center(
            child: Text(
              'NO ACTIVE REFERRALS YET', 
              style: GoogleFonts.montserrat(color: isDark ? Colors.white12 : Colors.black12, fontSize: 10, fontWeight: FontWeight.w800)
            )
          ),
         ],
       );
    }

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Padding(
          padding: const EdgeInsets.only(left: 10, bottom: 15),
          child: Text(
            'ACTIVE REFERRALS',
            style: GoogleFonts.montserrat(
              color: isDark ? Colors.white24 : Colors.black26,
              fontSize: 10,
              fontWeight: FontWeight.w800,
              letterSpacing: 1.5,
            ),
          ),
        ),
        ..._referrals.map((ref) => Column(
          children: [
            _buildReferralTile(
              ref['referredUser']?['firstName'] ?? 'User', 
              ref['status'] ?? 'Pending', 
              '${ref['points'] ?? 0} PTS', 
              isDark
            ),
            const SizedBox(height: 10),
          ],
        )).toList(),
      ],
    );
  }

  Widget _buildReferralTile(String name, String status, String pts, bool isDark) {
    // ...existing code...
    final bool isVerified = status.toLowerCase() == 'verified' || status.toLowerCase() == 'active';
    return Container(
      padding: const EdgeInsets.all(15),
      decoration: BoxDecoration(
        color: isDark ? const Color(0xFF080A0E).withOpacity(0.5) : Colors.grey[100],
        borderRadius: BorderRadius.circular(15),
      ),
      child: Row(
        children: [
          CircleAvatar(
            backgroundColor: (isDark ? Colors.white : Colors.black).withOpacity(0.05),
            child: Text(name[0], style: TextStyle(color: isDark ? Colors.white38 : Colors.black38)),
          ),
          const SizedBox(width: 15),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(name, style: GoogleFonts.montserrat(color: isDark ? Colors.white : Colors.black, fontSize: 13, fontWeight: FontWeight.w700)),
                Text(status.toUpperCase(), style: GoogleFonts.montserrat(color: isVerified ? Colors.green : Colors.orange, fontSize: 10, fontWeight: FontWeight.w600)),
              ],
            ),
          ),
          Text(pts, style: GoogleFonts.montserrat(color: isDark ? Colors.white : Colors.black, fontSize: 12, fontWeight: FontWeight.w900)),
        ],
      ),
    );
  }

  void _showReferralForm(bool isDark) {
    final nameController = TextEditingController();
    final phoneController = TextEditingController();
    final projectController = TextEditingController();
    bool isLoading = false;

    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (context) {
        return StatefulBuilder(
          builder: (context, setState) {
            return Padding(
              padding: EdgeInsets.only(bottom: MediaQuery.of(context).viewInsets.bottom),
              child: Container(
                padding: const EdgeInsets.all(30),
                decoration: BoxDecoration(
                  color: isDark ? const Color(0xFF030406) : Colors.white,
                  borderRadius: const BorderRadius.vertical(top: Radius.circular(40)),
                  border: Border.all(color: (isDark ? Colors.white : Colors.black).withOpacity(0.05)),
                ),
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      'NEW REFERRAL',
                      style: GoogleFonts.montserrat(
                        color: isDark ? Colors.white : Colors.black,
                        fontSize: 24,
                        fontWeight: FontWeight.w900,
                      ),
                    ),
                    const SizedBox(height: 4),
                    Text(
                      'REFER & EARN REWARDS',
                      style: GoogleFonts.montserrat(
                        color: isDark ? Colors.white54 : Colors.black54,
                        fontSize: 10,
                        fontWeight: FontWeight.w800,
                        letterSpacing: 2,
                      ),
                    ),
                    const SizedBox(height: 30),
                    _buildInputField('SELECT PROJECT', 'Project Name', projectController, isDark),
                    const SizedBox(height: 20),
                    _buildInputField('FRIEND\'S NAME', 'FULL NAME', nameController, isDark),
                    const SizedBox(height: 20),
                    _buildInputField('MOBILE NUMBER', '+91 XXXXX XXXXX', phoneController, isDark, isNumber: true),
                    const SizedBox(height: 40),
                    GestureDetector(
                      onTap: isLoading ? null : () async {
                        if (nameController.text.isEmpty || phoneController.text.isEmpty) {
                           ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('Please fill all required fields.')));
                           return;
                        }
                        setState(() => isLoading = true);
                        try {
                          final apiClient = ref.read(apiClientProvider);
                          final response = await apiClient.submitReferral({
                            'clientName': nameController.text,
                            'clientPhone': phoneController.text,
                            'projectName': projectController.text,
                          });
                          
                          if (response.data['status'] == true) {
                            if (mounted) {
                              Navigator.pop(context); // close modal
                              _fetchReferralData(); // refresh list
                              ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('Referral Submitted Successfully!')));
                            }
                          } else {
                            if (mounted) {
                               ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text(response.data['message'] ?? 'Failed to submit.')));
                            }
                          }
                        } catch (e) {
                          String errorMessage = 'Error submitting referral. Please try again.';
                          if (e is DioException && e.response?.data != null) {
                            errorMessage = e.response!.data['message'] ?? errorMessage;
                          }
                          if (mounted) {
                             ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text(errorMessage)));
                          }
                        } finally {
                          if (mounted) {
                            setState(() => isLoading = false);
                          }
                        }
                      },
                      child: Opacity(
                        opacity: isLoading ? 0.5 : 1.0,
                        child: Container(
                          width: double.infinity,
                          padding: const EdgeInsets.symmetric(vertical: 20),
                          decoration: BoxDecoration(
                            color: isDark ? Colors.white : Colors.black,
                            borderRadius: BorderRadius.circular(15),
                          ),
                          alignment: Alignment.center,
                          child: isLoading
                            ? SizedBox(width: 20, height: 20, child: CircularProgressIndicator(strokeWidth: 2, color: isDark ? Colors.black : Colors.white))
                            : Text(
                                'SUBMIT REFERRAL',
                                style: GoogleFonts.montserrat(
                                  color: isDark ? Colors.black : Colors.white,
                                  fontSize: 12,
                                  fontWeight: FontWeight.w900,
                                  letterSpacing: 2,
                                ),
                              ),
                        ),
                      ),
                    ),
                    const SizedBox(height: 20),
                  ],
                ),
              ),
            );
          }
        );
      },
    );
  }

  Widget _buildInputField(String label, String hint, TextEditingController controller, bool isDark, {bool isNumber = false}) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Padding(
          padding: const EdgeInsets.only(left: 10, bottom: 8),
          child: Text(
            label,
            style: GoogleFonts.montserrat(
              color: isDark ? Colors.white54 : Colors.black54,
              fontSize: 10,
              fontWeight: FontWeight.w800,
              letterSpacing: 2,
            ),
          ),
        ),
        Container(
          decoration: BoxDecoration(
            color: (isDark ? Colors.white : Colors.black).withOpacity(0.02),
            borderRadius: BorderRadius.circular(20),
            border: Border.all(color: (isDark ? Colors.white : Colors.black).withOpacity(0.05)),
          ),
          child: TextField(
            controller: controller,
            keyboardType: isNumber ? TextInputType.phone : TextInputType.text,
            style: GoogleFonts.montserrat(
              color: isDark ? Colors.white : Colors.black,
              fontSize: 14,
              fontWeight: FontWeight.w600,
            ),
            decoration: InputDecoration(
              hintText: hint,
              hintStyle: GoogleFonts.montserrat(
                color: isDark ? Colors.white24 : Colors.black26,
                fontSize: 14,
                fontWeight: FontWeight.w600,
              ),
              border: InputBorder.none,
              contentPadding: const EdgeInsets.symmetric(horizontal: 20, vertical: 16),
            ),
          ),
        ),
      ],
    );
  }
}
