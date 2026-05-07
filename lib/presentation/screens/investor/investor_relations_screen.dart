import 'dart:ui';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:lucide_icons/lucide_icons.dart';
import 'package:flutter_animate/flutter_animate.dart';
import 'package:cached_network_image/cached_network_image.dart';
import 'package:m4_mobile/core/network/api_client.dart';
import 'package:m4_mobile/core/utils/support_handlers.dart';
import 'package:m4_mobile/presentation/providers/auth_provider.dart';
import 'package:m4_mobile/presentation/widgets/conditional_drawer.dart';

class InvestorRelationsScreen extends ConsumerStatefulWidget {
  const InvestorRelationsScreen({super.key});

  @override
  ConsumerState<InvestorRelationsScreen> createState() => _InvestorRelationsScreenState();
}

class _InvestorRelationsScreenState extends ConsumerState<InvestorRelationsScreen> {
  bool _isLoading = true;
  bool _isSubmitting = false;
  Map<String, dynamic>? _pageData;
  Map<String, dynamic>? _configData;
  bool _agreedPrivacy = false;
  bool _agreedNews = false;
  bool _prefPhone = false;
  bool _prefEmail = false;

  final _firstNameController = TextEditingController();
  final _lastNameController = TextEditingController();
  final _emailController = TextEditingController();
  final _phoneController = TextEditingController();
  final _messageController = TextEditingController();

  @override
  void initState() {
    super.initState();
    _fetchData();
  }

  @override
  void dispose() {
    _firstNameController.dispose();
    _lastNameController.dispose();
    _emailController.dispose();
    _phoneController.dispose();
    _messageController.dispose();
    super.dispose();
  }

  Future<void> _fetchData() async {
    try {
      final apiClient = ref.read(apiClientProvider);
      final results = await Future.wait([
        apiClient.getCmsPage('investor-relations'),
        apiClient.getSystemConfig(),
      ]);

      final cmsResponse = results[0];
      final configResponse = results[1];

      if (cmsResponse.data['status'] == true) {
        _pageData = cmsResponse.data['data'];
      }
      if (configResponse.data['status'] == true) {
        _configData = configResponse.data['data'];
      }
    } catch (_) {}
    if (mounted) setState(() => _isLoading = false);
  }

  Future<void> _submitInquiry() async {
    if (!_agreedPrivacy) {
      _showToast('Please agree to the Privacy Policy', isError: true);
      return;
    }
    if (_firstNameController.text.trim().isEmpty ||
        _lastNameController.text.trim().isEmpty ||
        _emailController.text.trim().isEmpty ||
        _phoneController.text.trim().isEmpty) {
      _showToast('Please fill in all required fields', isError: true);
      return;
    }

    setState(() => _isSubmitting = true);
    try {
      final apiClient = ref.read(apiClientProvider);
      final response = await apiClient.submitLead({
        'name': '${_firstNameController.text.trim()} ${_lastNameController.text.trim()}',
        'email': _emailController.text.trim(),
        'phone': _phoneController.text.trim(),
        'message': _messageController.text.trim(),
        'interest': 'Investing',
        'source': 'online',
        'notes': 'Submitted via Investor Relations Page',
      });

      if (response.data['status'] == true) {
        _showToast('Inquiry Submitted Successfully!');
        _firstNameController.clear();
        _lastNameController.clear();
        _emailController.clear();
        _phoneController.clear();
        _messageController.clear();
        setState(() {
          _agreedPrivacy = false;
          _agreedNews = false;
        });
      } else {
        _showToast(response.data['message'] ?? 'Submission failed', isError: true);
      }
    } catch (_) {
      _showToast('Submission failed. Please try again.', isError: true);
    } finally {
      if (mounted) setState(() => _isSubmitting = false);
    }
  }

  void _showToast(String message, {bool isError = false}) {
    if (!mounted) return;
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(message, style: GoogleFonts.montserrat(fontWeight: FontWeight.bold, fontSize: 12)),
        backgroundColor: isError ? Colors.redAccent : Colors.teal,
        behavior: SnackBarBehavior.floating,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    return Scaffold(
      backgroundColor: Theme.of(context).scaffoldBackgroundColor,
      extendBodyBehindAppBar: true,
      appBar: AppBar(
        title: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text('INVESTOR RELATIONS',
                style: GoogleFonts.montserrat(color: isDark ? Colors.white : Colors.black, fontWeight: FontWeight.bold, fontSize: 18, letterSpacing: 1)),
            Text('M4 FAMILY DEVELOPMENTS',
                style: GoogleFonts.montserrat(color: (isDark ? Colors.white : Colors.black).withOpacity(0.5), fontWeight: FontWeight.w900, fontSize: 9, letterSpacing: 4)),
          ],
        ),
        backgroundColor: (isDark ? Colors.black : Colors.white).withOpacity(0.8),
        flexibleSpace: ClipRRect(
          child: BackdropFilter(
            filter: ImageFilter.blur(sigmaX: 10, sigmaY: 10),
            child: Container(color: Colors.transparent),
          ),
        ),
        elevation: 0,
        leading: IconButton(
          icon: Icon(LucideIcons.arrowLeft, color: isDark ? Colors.white70 : Colors.black54),
          onPressed: () => Navigator.pop(context),
        ),
        actions: [
          Builder(
            builder: (context) => GestureDetector(
              onTap: () => Scaffold.of(context).openDrawer(),
              child: Container(
                margin: const EdgeInsets.only(right: 16, top: 12, bottom: 12),
                padding: const EdgeInsets.symmetric(horizontal: 14),
                decoration: BoxDecoration(
                  color: isDark ? Colors.white : Colors.black,
                  borderRadius: BorderRadius.circular(20),
                ),
                child: Icon(
                  LucideIcons.moreHorizontal, 
                  color: isDark ? Colors.black : Colors.white, 
                  size: 20
                ),
              ),
            ),
          ),
        ],
      ),
      drawer: const ConditionalDrawer(),
      body: Container(
        decoration: BoxDecoration(
          color: Theme.of(context).scaffoldBackgroundColor,
          gradient: isDark 
            ? const RadialGradient(
                center: Alignment.topCenter,
                radius: 2.5,
                colors: [Color(0xFF0F1115), Colors.black],
              )
            : null,
        ),
        child: SafeArea(
          child: _isLoading
              ? Center(child: CircularProgressIndicator(color: isDark ? Colors.white24 : Colors.black12))
              : SingleChildScrollView(
                  padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 24),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.stretch,
                    children: [
                      _buildOverview(),
                      const SizedBox(height: 40),
                      _buildImage(),
                      const SizedBox(height: 48),
                      _buildContactForm(),
                      const SizedBox(height: 48),
                      _buildInvestorContact(),
                      const SizedBox(height: 48),
                    ],
                  ),
                ),
        ),
      ),
    );
  }

  // ─── CMS Overview ─────────────────────────────────────────
  Widget _buildOverview() {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final title = _pageData?['title'] ?? 'INVESTOR\nRELATIONS';
    final content = _pageData?['content'] ?? '';

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          title.toString().toUpperCase(),
          style: GoogleFonts.playfairDisplay(
            color: isDark ? Colors.white : Colors.black,
            fontSize: 36,
            fontWeight: FontWeight.w300,
            letterSpacing: -0.5,
            height: 1.1,
          ),
        ),
        const SizedBox(height: 28),
        if (content.toString().isNotEmpty)
          ...content.toString().split('\n\n').map((paragraph) => Padding(
                padding: const EdgeInsets.only(bottom: 16, right: 16),
                child: Text(
                  paragraph,
                  style: GoogleFonts.inter(color: (isDark ? Colors.white : Colors.black).withOpacity(0.6), fontSize: 14, fontWeight: FontWeight.w500, height: 1.6),
                ),
              )),
      ],
    ).animate().fadeIn().slideY(begin: 0.1);
  }

  // ─── Handshake Image ──────────────────────────────────────
  Widget _buildImage() {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    return ClipRRect(
      borderRadius: BorderRadius.circular(32),
      child: AspectRatio(
        aspectRatio: 4 / 3,
        child: CachedNetworkImage(
          imageUrl: 'https://images.unsplash.com/photo-1556761175-b413da4baf72?auto=format&fit=crop&q=80',
          fit: BoxFit.cover,
          color: isDark ? Colors.white : null,
          colorBlendMode: isDark ? BlendMode.saturation : null,
          placeholder: (_, __) => Container(color: (isDark ? Colors.white : Colors.black).withOpacity(0.05)),
          errorWidget: (_, __, ___) => Container(
            color: (isDark ? Colors.white : Colors.black).withOpacity(0.05),
            child: Center(child: Icon(LucideIcons.image, color: (isDark ? Colors.white : Colors.black).withOpacity(0.24), size: 40)),
          ),
        ),
      ),
    ).animate().fadeIn(delay: 200.ms).slideY(begin: 0.1);
  }

  // ─── Contact / Lead Form ──────────────────────────────────
  Widget _buildContactForm() {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          'STAY IN TOUCH\nWITH US',
          style: GoogleFonts.playfairDisplay(
            color: isDark ? Colors.white : Colors.black,
            fontSize: 28,
            fontWeight: FontWeight.w300,
            letterSpacing: -0.5,
            height: 1.15,
          ),
        ),
        const SizedBox(height: 32),

        // First Name / Last Name Row
        Row(
          children: [
            Expanded(child: _buildInputField(controller: _firstNameController, hint: 'First Name *')),
            const SizedBox(width: 12),
            Expanded(child: _buildInputField(controller: _lastNameController, hint: 'Last Name *')),
          ],
        ),
        const SizedBox(height: 12),
        _buildInputField(controller: _emailController, hint: 'Email *', isEmail: true),
        const SizedBox(height: 12),
        _buildInputField(controller: _phoneController, hint: 'Phone Number *', isPhone: true),
        const SizedBox(height: 12),
        _buildMessageField(),
        const SizedBox(height: 28),

        // Preferred Contact Mode
        Text(
          'PREFERRED MODE OF CONTACT:',
          style: GoogleFonts.montserrat(color: (isDark ? Colors.white : Colors.black).withOpacity(0.54), fontSize: 9, fontWeight: FontWeight.w900, letterSpacing: 2),
        ),
        const SizedBox(height: 16),
        Row(
          children: [
            _buildCheckOption('Phone', _prefPhone, (v) => setState(() => _prefPhone = v)),
            const SizedBox(width: 32),
            _buildCheckOption('Email', _prefEmail, (v) => setState(() => _prefEmail = v)),
          ],
        ),
        const SizedBox(height: 24),

        // Checkboxes
        _buildCheckOption(
          "I'd like to hear about news and offers.",
          _agreedNews,
          (v) => setState(() => _agreedNews = v),
        ),
        const SizedBox(height: 12),
        _buildCheckOption(
          "I've read and agree to the Privacy Policy",
          _agreedPrivacy,
          (v) => setState(() => _agreedPrivacy = v),
        ),
        const SizedBox(height: 32),

        // Submit Button
        SizedBox(
          width: double.infinity,
          height: 64,
          child: ElevatedButton(
            onPressed: _isSubmitting ? null : _submitInquiry,
            style: ElevatedButton.styleFrom(
              backgroundColor: isDark ? Colors.white : Colors.black,
              foregroundColor: isDark ? Colors.black : Colors.white,
              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
              elevation: 0,
            ),
            child: _isSubmitting
                ? SizedBox(width: 20, height: 20, child: CircularProgressIndicator(strokeWidth: 2, color: isDark ? Colors.black : Colors.white))
                : Text('SUBMIT', style: GoogleFonts.montserrat(fontSize: 14, fontWeight: FontWeight.w900, letterSpacing: 1)),
          ),
        ),
      ],
    ).animate().fadeIn(delay: 300.ms).slideY(begin: 0.1);
  }

  // ─── Investor Contact Section ─────────────────────────────
  Widget _buildInvestorContact() {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final contactEmail = _configData?['contact_email'] ?? 'sales@m4group.in';
    final contactPhone = _configData?['contact_phone'] ?? '+91 22 4601 8844';

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          'INVESTOR CONTACT',
          style: GoogleFonts.playfairDisplay(
            color: isDark ? Colors.white : Colors.black,
            fontSize: 24,
            fontWeight: FontWeight.w300,
            letterSpacing: -0.5,
          ),
        ),
        const SizedBox(height: 12),
        Text(
          'FOR ANY INVESTOR RELATION RELATED QUESTIONS OR QUERIES PLEASE CONTACT VIA BELOW EMAIL',
          style: GoogleFonts.montserrat(color: (isDark ? Colors.white : Colors.black).withOpacity(0.38), fontSize: 9, fontWeight: FontWeight.w800, letterSpacing: 1.5, height: 1.6),
        ),
        const SizedBox(height: 24),

        // Email Card
        _buildContactCard(
          icon: LucideIcons.mail,
          label: 'Email:',
          value: contactEmail,
          onTap: () => SupportHandlers.launchEmail(contactEmail),
        ),
        const SizedBox(height: 12),

        // Phone Card
        _buildContactCard(
          icon: LucideIcons.phone,
          label: 'Phone:',
          value: contactPhone,
          onTap: () => SupportHandlers.launchCall(contactPhone),
        ),
      ],
    ).animate().fadeIn(delay: 400.ms).slideY(begin: 0.1);
  }

  // ─── Helper Widgets ───────────────────────────────────────
  Widget _buildContactCard({required IconData icon, required String label, required String value, required VoidCallback onTap}) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(28),
      child: ClipRRect(
        borderRadius: BorderRadius.circular(28),
        child: BackdropFilter(
          filter: ImageFilter.blur(sigmaX: 10, sigmaY: 10),
          child: Container(
            padding: const EdgeInsets.all(24),
            decoration: BoxDecoration(
              color: (isDark ? Colors.white : Colors.black).withOpacity(0.04),
              borderRadius: BorderRadius.circular(28),
              border: Border.all(color: (isDark ? Colors.white : Colors.black).withOpacity(0.05)),
            ),
            child: Row(
              children: [
                Container(
                  width: 56,
                  height: 56,
                  decoration: BoxDecoration(color: isDark ? Colors.white : Colors.black, shape: BoxShape.circle),
                  child: Icon(icon, color: isDark ? Colors.black : Colors.white, size: 24),
                ),
                const SizedBox(width: 20),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(label.toUpperCase(),
                          style: GoogleFonts.montserrat(color: (isDark ? Colors.white : Colors.black).withOpacity(0.54), fontSize: 9, fontWeight: FontWeight.w900, letterSpacing: 2)),
                      const SizedBox(height: 4),
                      Text(value.toUpperCase(),
                          style: GoogleFonts.montserrat(color: isDark ? Colors.white : Colors.black, fontSize: 14, fontWeight: FontWeight.w900, letterSpacing: -0.5)),
                    ],
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildInputField({required TextEditingController controller, required String hint, bool isEmail = false, bool isPhone = false}) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    return TextField(
      controller: controller,
      keyboardType: isEmail ? TextInputType.emailAddress : isPhone ? TextInputType.phone : TextInputType.text,
      style: GoogleFonts.inter(color: isDark ? Colors.white : Colors.black, fontWeight: FontWeight.w500, fontSize: 14),
      decoration: InputDecoration(
        hintText: hint,
        hintStyle: GoogleFonts.inter(color: (isDark ? Colors.white : Colors.black).withOpacity(0.24), fontWeight: FontWeight.w500, fontSize: 14),
        filled: true,
        fillColor: (isDark ? Colors.white : Colors.black).withOpacity(0.04),
        contentPadding: const EdgeInsets.symmetric(horizontal: 24, vertical: 20),
        border: OutlineInputBorder(borderRadius: BorderRadius.circular(20), borderSide: BorderSide(color: (isDark ? Colors.white : Colors.black).withOpacity(0.1))),
        enabledBorder: OutlineInputBorder(borderRadius: BorderRadius.circular(20), borderSide: BorderSide(color: (isDark ? Colors.white : Colors.black).withOpacity(0.1))),
        focusedBorder: OutlineInputBorder(borderRadius: BorderRadius.circular(20), borderSide: BorderSide(color: isDark ? Colors.white : Colors.black, width: 1.5)),
      ),
    );
  }

  Widget _buildMessageField() {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    return TextField(
      controller: _messageController,
      maxLines: 5,
      style: GoogleFonts.inter(color: isDark ? Colors.white : Colors.black, fontWeight: FontWeight.w500, fontSize: 14),
      decoration: InputDecoration(
        hintText: 'Message',
        hintStyle: GoogleFonts.inter(color: (isDark ? Colors.white : Colors.black).withOpacity(0.24), fontWeight: FontWeight.w500, fontSize: 14),
        filled: true,
        fillColor: (isDark ? Colors.white : Colors.black).withOpacity(0.04),
        contentPadding: const EdgeInsets.symmetric(horizontal: 24, vertical: 20),
        border: OutlineInputBorder(borderRadius: BorderRadius.circular(20), borderSide: BorderSide(color: (isDark ? Colors.white : Colors.black).withOpacity(0.1))),
        enabledBorder: OutlineInputBorder(borderRadius: BorderRadius.circular(20), borderSide: BorderSide(color: (isDark ? Colors.white : Colors.black).withOpacity(0.1))),
        focusedBorder: OutlineInputBorder(borderRadius: BorderRadius.circular(20), borderSide: BorderSide(color: isDark ? Colors.white : Colors.black, width: 1.5)),
      ),
    );
  }

  Widget _buildCheckOption(String label, bool value, ValueChanged<bool> onChanged) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    return InkWell(
      onTap: () => onChanged(!value),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Container(
            width: 20,
            height: 20,
            margin: const EdgeInsets.only(top: 2),
            decoration: BoxDecoration(
              color: value ? (isDark ? Colors.white : Colors.black) : Colors.transparent,
              border: Border.all(color: (isDark ? Colors.white : Colors.black).withOpacity(0.3)),
              borderRadius: BorderRadius.circular(6),
            ),
            child: value ? Icon(LucideIcons.check, color: isDark ? Colors.black : Colors.white, size: 14) : null,
          ),
          const SizedBox(width: 12),
          Flexible(
            child: Text(
              label,
              style: GoogleFonts.inter(color: (isDark ? Colors.white : Colors.black).withOpacity(0.6), fontSize: 13, fontWeight: FontWeight.w500),
            ),
          ),
        ],
      ),
    );
  }
}

