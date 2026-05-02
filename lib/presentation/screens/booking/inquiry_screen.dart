import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:lucide_icons/lucide_icons.dart';
import 'package:m4_mobile/core/theme/app_theme.dart';
import 'package:m4_mobile/core/network/api_client.dart';
import 'package:m4_mobile/presentation/providers/auth_provider.dart';
import 'package:flutter_animate/flutter_animate.dart';

class InquiryScreen extends ConsumerStatefulWidget {
  final dynamic project;
  final String projectId;

  const InquiryScreen({
    super.key,
    required this.projectId,
    this.project,
  });

  @override
  ConsumerState<InquiryScreen> createState() => _InquiryScreenState();
}

class _InquiryScreenState extends ConsumerState<InquiryScreen> {
  final TextEditingController _nameController = TextEditingController();
  final TextEditingController _phoneController = TextEditingController();
  final TextEditingController _emailController = TextEditingController();
  final TextEditingController _notesController = TextEditingController();
  bool _isLoading = false;
  bool _isSuccess = false;

  @override
  void initState() {
    super.initState();
    // Prefill user data
    final authUser = ref.read(authProvider).user;
    if (authUser != null) {
      _nameController.text = authUser['fullName']?.toString() ?? authUser['username']?.toString() ?? '';
      _phoneController.text = authUser['phone']?.toString() ?? '';
      _emailController.text = authUser['email']?.toString() ?? '';
    }
  }

  @override
  void dispose() {
    _nameController.dispose();
    _phoneController.dispose();
    _emailController.dispose();
    _notesController.dispose();
    super.dispose();
  }

  Future<void> _submitInquiry() async {
    if (_nameController.text.isEmpty || _phoneController.text.isEmpty || _emailController.text.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('Please fill in all required fields')));
      return;
    }

    setState(() => _isLoading = true);
    try {
      final apiClient = ref.read(apiClientProvider);
      
      final res = await apiClient.submitLead({
        'name': _nameController.text.trim(),
        'email': _emailController.text.trim(),
        'phone': _phoneController.text.trim(),
        'message': _notesController.text.trim(),
        'interest': 'Buying',
        'source': 'App',
        'project': widget.projectId,
      });

      if (res.data['status'] == true) {
        setState(() => _isSuccess = true);
      } else {
        ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text(res.data['message'] ?? 'Failed to send inquiry')));
      }
    } catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('Error sending inquiry. Please try again.')));
    } finally {
      if (mounted) setState(() => _isLoading = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;

    if (_isSuccess) {
      return Scaffold(
        backgroundColor: isDark ? const Color(0xFF0F1115) : Colors.white,
        body: Center(
          child: Padding(
            padding: const EdgeInsets.all(40),
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Container(
                  width: 100,
                  height: 100,
                  decoration: BoxDecoration(
                    color: isDark ? Colors.white : Colors.black,
                    borderRadius: BorderRadius.circular(30),
                  ),
                  child: Icon(LucideIcons.check, color: isDark ? Colors.black : Colors.white, size: 50),
                ).animate().scale(duration: 500.ms, curve: Curves.elasticOut),
                const SizedBox(height: 40),
                Text(
                  'REQUEST REGISTERED',
                  style: GoogleFonts.montserrat(fontSize: 24, fontWeight: FontWeight.w900, letterSpacing: -1),
                ).animate().fadeIn(delay: 200.ms),
                const SizedBox(height: 16),
                Text(
                  'Your inquiry has been secured. Our premium sales associate will contact you shortly with the institutional brochure.',
                  textAlign: TextAlign.center,
                  style: GoogleFonts.montserrat(fontSize: 10, color: isDark ? Colors.white38 : Colors.black38, fontWeight: FontWeight.w900, letterSpacing: 1.5, height: 1.8),
                ).animate().fadeIn(delay: 400.ms),
                const SizedBox(height: 48),
                GestureDetector(
                  onTap: () => Navigator.pop(context),
                  child: Container(
                    width: double.infinity,
                    height: 64,
                    decoration: BoxDecoration(
                      color: isDark ? Colors.white : Colors.black,
                      borderRadius: BorderRadius.circular(32),
                      boxShadow: [BoxShadow(color: (isDark ? Colors.white : Colors.black).withOpacity(0.1), blurRadius: 20, offset: const Offset(0, 10))],
                    ),
                    child: Center(
                      child: Text(
                        'RETURN TO PROJECT',
                        style: GoogleFonts.montserrat(color: isDark ? Colors.black : Colors.white, fontWeight: FontWeight.w900, fontSize: 10, letterSpacing: 2),
                      ),
                    ),
                  ),
                ).animate().fadeIn(delay: 600.ms).moveY(begin: 20, end: 0),
              ],
            ),
          ),
        ),
      );
    }

    return Scaffold(
      backgroundColor: isDark ? const Color(0xFF0F1115) : Colors.white,
      appBar: AppBar(
        backgroundColor: Colors.transparent,
        elevation: 0,
        leading: IconButton(
          icon: Icon(LucideIcons.chevronLeft, color: isDark ? Colors.white : Colors.black),
          onPressed: () => Navigator.pop(context),
        ),
        title: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text('SEND INQUIRY', style: GoogleFonts.montserrat(fontSize: 14, fontWeight: FontWeight.w900, color: isDark ? Colors.white : Colors.black)),
            Text('INSTITUTIONAL PROTOCOL', style: GoogleFonts.montserrat(fontSize: 8, color: M4Theme.premiumBlue, fontWeight: FontWeight.w900, letterSpacing: 1.5)),
          ],
        ),
      ),
      body: Stack(
        children: [
          // Background ambient
          Positioned(
            top: -100,
            right: -100,
            child: Container(width: 300, height: 300, decoration: BoxDecoration(color: M4Theme.premiumBlue.withOpacity(0.05), shape: BoxShape.circle)),
          ),
          
          SingleChildScrollView(
            padding: const EdgeInsets.all(24),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                // Info Card
                Container(
                  padding: const EdgeInsets.all(24),
                  decoration: BoxDecoration(
                    color: isDark ? Colors.white.withOpacity(0.02) : Colors.white,
                    borderRadius: BorderRadius.circular(32),
                    border: Border.all(color: isDark ? Colors.white.withOpacity(0.05) : Colors.black.withOpacity(0.05)),
                    boxShadow: isDark ? [] : [BoxShadow(color: Colors.black.withOpacity(0.05), blurRadius: 20, offset: const Offset(0, 10))],
                  ),
                  child: Row(
                    children: [
                      Container(
                        width: 56,
                        height: 56,
                        decoration: BoxDecoration(
                          color: M4Theme.premiumBlue,
                          borderRadius: BorderRadius.circular(16),
                          boxShadow: [BoxShadow(color: M4Theme.premiumBlue.withOpacity(0.3), blurRadius: 15, offset: const Offset(0, 8))],
                        ),
                        child: const Icon(LucideIcons.sparkles, color: Colors.white, size: 28),
                      ),
                      const SizedBox(width: 20),
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(
                              'PRIORITY INTEREST',
                              style: GoogleFonts.montserrat(fontSize: 10, fontWeight: FontWeight.w900, letterSpacing: 1.5),
                            ),
                            const SizedBox(height: 4),
                            Text(
                              'COMPLETE THE PROTOCOL TO UNLOCK THE DETAILED ASSET INVENTORY.',
                              style: GoogleFonts.montserrat(fontSize: 9, color: isDark ? Colors.white38 : Colors.black38, fontWeight: FontWeight.bold, height: 1.4),
                            ),
                          ],
                        ),
                      ),
                    ],
                  ),
                ).animate().fadeIn().moveY(begin: 20, end: 0),
                
                const SizedBox(height: 48),
                
                _buildFieldLabel('FULL IDENTITY'),
                _buildTextField(_nameController, LucideIcons.user, 'ENTER FULL NAME'),
                const SizedBox(height: 32),
                
                _buildFieldLabel('COMMUNICATIONS'),
                _buildTextField(_emailController, LucideIcons.mail, 'EMAIL@M4FAMILY.COM'),
                const SizedBox(height: 32),
                
                _buildFieldLabel('DIRECT LINE'),
                _buildTextField(_phoneController, LucideIcons.phone, '+91 XXXXX XXXXX'),
                const SizedBox(height: 32),
                
                _buildFieldLabel('SPECIFIC BRIEFING (OPTIONAL)'),
                _buildTextField(_notesController, LucideIcons.messageSquare, 'DETAILS REGARDING UNIT PREFERENCES, ETC...', maxLines: 5),
                
                const SizedBox(height: 56),
                
                GestureDetector(
                  onTap: _isLoading ? null : _submitInquiry,
                  child: Container(
                    width: double.infinity,
                    height: 72,
                    decoration: BoxDecoration(
                      color: isDark ? Colors.white : Colors.black,
                      borderRadius: BorderRadius.circular(36),
                      boxShadow: [BoxShadow(color: (isDark ? Colors.white : Colors.black).withOpacity(0.2), blurRadius: 30, offset: const Offset(0, 15))],
                    ),
                    child: Center(
                      child: _isLoading 
                        ? SizedBox(width: 24, height: 24, child: CircularProgressIndicator(color: isDark ? Colors.black : Colors.white, strokeWidth: 3))
                        : Row(
                            mainAxisAlignment: MainAxisAlignment.center,
                            children: [
                              Text(
                                'AUTHORIZE INQUIRY',
                                style: GoogleFonts.montserrat(color: isDark ? Colors.black : Colors.white, fontWeight: FontWeight.w900, fontSize: 11, letterSpacing: 3),
                              ),
                              const SizedBox(width: 16),
                              Icon(LucideIcons.send, color: isDark ? Colors.black : Colors.white, size: 18),
                            ],
                          ),
                    ),
                  ),
                ).animate().fadeIn(delay: 400.ms),
                
                const SizedBox(height: 32),
                Center(
                  child: Padding(
                    padding: const EdgeInsets.symmetric(horizontal: 24),
                    child: Text(
                      '* BY SUBMITTING, YOU AGREE TO RECEIVE INSTITUTIONAL COMMUNICATIONS REGARDING M4 FAMILY ASSETS.',
                      textAlign: TextAlign.center,
                      style: GoogleFonts.montserrat(fontSize: 8, fontWeight: FontWeight.w900, color: isDark ? Colors.white24 : Colors.black26, letterSpacing: 0.5, height: 1.6),
                    ),
                  ),
                ),
                const SizedBox(height: 64),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildFieldLabel(String label) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    return Padding(
      padding: const EdgeInsets.only(left: 6, bottom: 12),
      child: Text(
        label,
        style: GoogleFonts.montserrat(fontSize: 9, fontWeight: FontWeight.w900, color: isDark ? Colors.white38 : Colors.black38, letterSpacing: 2),
      ),
    );
  }

  Widget _buildTextField(TextEditingController controller, IconData icon, String hint, {int maxLines = 1}) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 24),
      decoration: BoxDecoration(
        color: isDark ? Colors.white.withOpacity(0.02) : Colors.black.withOpacity(0.02),
        borderRadius: BorderRadius.circular(20),
        border: Border.all(color: isDark ? Colors.white.withOpacity(0.05) : Colors.black.withOpacity(0.05)),
      ),
      child: TextField(
        controller: controller,
        maxLines: maxLines,
        style: GoogleFonts.montserrat(fontSize: 12, fontWeight: FontWeight.w900, color: isDark ? Colors.white : Colors.black, letterSpacing: 0.5),
        decoration: InputDecoration(
          border: InputBorder.none,
          hintText: hint,
          hintStyle: GoogleFonts.montserrat(fontSize: 12, color: isDark ? Colors.white12 : Colors.black12, fontWeight: FontWeight.w900),
          icon: maxLines == 1 ? Icon(icon, color: isDark ? Colors.white24 : Colors.black26, size: 20) : null,
          contentPadding: const EdgeInsets.symmetric(vertical: 20),
        ),
      ),
    );
  }
}
