import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:lucide_icons/lucide_icons.dart';
import 'package:m4_mobile/core/network/api_client.dart';
import 'package:m4_mobile/presentation/providers/auth_provider.dart';
import 'package:flutter_animate/flutter_animate.dart';
import 'package:url_launcher/url_launcher.dart';
import 'dart:ui';
import 'package:m4_mobile/presentation/widgets/conditional_drawer.dart';
import 'package:webview_flutter/webview_flutter.dart';

class ContactScreen extends ConsumerStatefulWidget {
  const ContactScreen({super.key});

  @override
  ConsumerState<ContactScreen> createState() => _ContactScreenState();
}

class _ContactScreenState extends ConsumerState<ContactScreen> {
  Map<String, dynamic>? _config;
  bool _isLoading = true;
  bool _submitting = false;
  bool _agreed = false;
  late final WebViewController _mapController;

  final _nameController = TextEditingController();
  final _emailController = TextEditingController();
  final _phoneController = TextEditingController();
  final _messageController = TextEditingController();

  @override
  void initState() {
    super.initState();
    _initMapController();
    _fetchData();
  }

  @override
  void dispose() {
    _nameController.dispose();
    _emailController.dispose();
    _phoneController.dispose();
    _messageController.dispose();
    super.dispose();
  }

  void _initMapController() {
    _mapController = WebViewController()
      ..setJavaScriptMode(JavaScriptMode.unrestricted)
      ..setBackgroundColor(const Color(0x00000000))
      ..loadHtmlString('''
        <!DOCTYPE html>
        <html>
        <head>
          <meta name="viewport" content="width=device-width, initial-scale=1.0">
          <style>
            body { margin: 0; padding: 0; overflow: hidden; }
            iframe { 
              width: 100vw; 
              height: 100vh; 
              border: 0; 
              filter: grayscale(1) contrast(1.1);
            }
          </style>
        </head>
        <body>
          <iframe 
            src="https://www.google.com/maps/embed?pb=!1m18!1m12!1m3!1d3773.743144883176!2d72.812627!3d18.960416!2m3!1f0!2f0!3f0!3m2!1i1024!2i768!4f13.1!3m3!1m2!1s0x3be7ce0e2634354b%3A0x67399a9b3a3a3a3a!2sM4+Aura+Heights!5e0!3m2!1sen!2sin!4v1711234567890!5m2!1sen!2sin" 
            allowfullscreen="" 
            loading="lazy" 
            referrerpolicy="no-referrer-when-downgrade">
          </iframe>
        </body>
        </html>
      ''');
  }

  Future<void> _fetchData() async {
    try {
      final apiClient = ref.read(apiClientProvider);
      final res = await apiClient.getSystemConfig();
      if (res.data['status'] == true || res.data['status'] == 'true') {
        setState(() => _config = res.data['data']);
      }
    } catch (e) {
      debugPrint("Error fetching contact config: $e");
    } finally {
      if (mounted) setState(() => _isLoading = false);
    }
  }

  Future<void> _handleSubmit() async {
    if (_nameController.text.isEmpty || _emailController.text.isEmpty || _phoneController.text.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Please fill in all required fields.')),
      );
      return;
    }
    if (!_agreed) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Please agree to the privacy policy.')),
      );
      return;
    }

    setState(() => _submitting = true);
    try {
      final apiClient = ref.read(apiClientProvider);
      final res = await apiClient.post("/leads", {
        "name": _nameController.text,
        "email": _emailController.text,
        "phone": _phoneController.text,
        "message": _messageController.text,
        "interest": "General Enquiry",
        "source": "Mobile App",
        "status": "New"
      });

      if (res.data['status'] == true) {
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(content: Text('Enquiry sent successfully! Our team will contact you shortly.')),
          );
          _nameController.clear();
          _emailController.clear();
          _phoneController.clear();
          _messageController.clear();
          setState(() => _agreed = false);
        }
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Error: ${e.toString()}')),
        );
      }
    } finally {
      if (mounted) setState(() => _submitting = false);
    }
  }

  Future<void> _launchUrl(String url) async {
    final uri = Uri.parse(url);
    if (await canLaunchUrl(uri)) {
      await launchUrl(uri, mode: LaunchMode.externalApplication);
    }
  }

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final offices = (_config?['offices'] as List?) ?? [];
    final mapConfig = _config?['map_config'] as Map? ?? {};
    final contactEmail = _config?['contact_email'] ?? "sales@m4group.in";
    final contactPhone = _config?['contact_phone'] ?? "+91 99308 50993";

    return Scaffold(
      backgroundColor: isDark ? Colors.black : Colors.white,
      extendBodyBehindAppBar: true,
      appBar: AppBar(
        title: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text('M4 FAMILY', 
                style: GoogleFonts.montserrat(
                  color: isDark ? Colors.white : Colors.black, 
                  fontWeight: FontWeight.w900, 
                  fontSize: 18, 
                  letterSpacing: -0.5
                )),
            Text('DEVELOPMENTS', 
                style: GoogleFonts.montserrat(
                  color: (isDark ? Colors.white : Colors.black).withOpacity(0.5), 
                  fontWeight: FontWeight.w900, 
                  fontSize: 8, 
                  letterSpacing: 4
                )),
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
            builder: (context) => IconButton(
              onPressed: () => Scaffold.of(context).openDrawer(),
              icon: Icon(LucideIcons.moreHorizontal, color: isDark ? Colors.white : Colors.black),
            ),
          ),
        ],
      ),
      drawer: const ConditionalDrawer(),
      body: _isLoading 
        ? Center(child: CircularProgressIndicator(color: isDark ? Colors.white24 : Colors.black12))
        : SingleChildScrollView(
            padding: const EdgeInsets.fromLTRB(24, 130, 24, 120),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                // ⭐️ Hero Intro
                Text(
                  'Get in touch with us',
                  style: GoogleFonts.dmSerifDisplay(
                    fontSize: 32,
                    fontWeight: FontWeight.w400,
                    color: isDark ? Colors.white : Colors.black,
                    letterSpacing: -0.5,
                  ),
                ),
                const SizedBox(height: 16),
                Text(
                  "Thank you for visiting our website! We would love to hear from you. Whether you have a question, feedback, or simply want to say hello we're here to help. Please feel free to get in touch with us using the contact information below or by filling out the contact form. We strive to respond to all inquiries promptly.",
                  style: GoogleFonts.inter(
                    fontSize: 14,
                    height: 1.6,
                    color: (isDark ? Colors.white : Colors.black).withOpacity(0.6),
                  ),
                ),

                const SizedBox(height: 48),

                // ⭐️ Contact Form
                _buildInquiryForm(isDark),

                const SizedBox(height: 64),

                // ⭐️ Contact Information
                Text(
                  'CONTACT INFORMATION',
                  style: GoogleFonts.dmSerifDisplay(
                    fontSize: 24,
                    fontWeight: FontWeight.w400,
                    color: isDark ? Colors.white : Colors.black,
                  ),
                ),
                const SizedBox(height: 32),
                
                _buildContactInfoTile(
                  icon: LucideIcons.phone,
                  label: 'SALES INQUIRY',
                  value: contactPhone,
                  subValue: contactEmail,
                  onTap: () => _launchUrl('tel:$contactPhone'),
                  isDark: isDark,
                ),
                const SizedBox(height: 32),
                _buildContactInfoTile(
                  icon: LucideIcons.mail,
                  label: 'OTHER INQUIRIES',
                  value: '+91 22 4601 8844',
                  subValue: contactEmail,
                  onTap: () => _launchUrl('mailto:$contactEmail'),
                  isDark: isDark,
                ),
                const SizedBox(height: 32),
                _buildContactInfoTile(
                  icon: LucideIcons.mapPin,
                  label: 'ADDRESS',
                  value: offices.isNotEmpty ? offices[0]['address'] : "604, 6th Flr, M4 Aura Heights,\nGrant Road, Mumbai 400007",
                  onTap: () => _launchUrl(offices.isNotEmpty ? offices[0]['mapLink'] : mapConfig['google_maps_url'] ?? ''),
                  isDark: isDark,
                ),

                const SizedBox(height: 64),

                // ⭐️ Map Section
                Text(
                  'OUR HEAD OFFICE',
                  style: GoogleFonts.dmSerifDisplay(
                    fontSize: 24,
                    fontWeight: FontWeight.w400,
                    color: isDark ? Colors.white : Colors.black,
                  ),
                ),
                const SizedBox(height: 24),
                _buildMapSection(mapConfig, isDark),
              ],
            ),
          ),
    );
  }

  Widget _buildInquiryForm(bool isDark) {
    return Column(
      children: [
        _buildTextField('Full Name *', isDark, controller: _nameController),
        const SizedBox(height: 16),
        _buildTextField('Email *', isDark, controller: _emailController),
        const SizedBox(height: 16),
        _buildTextField('Phone Number *', isDark, controller: _phoneController),
        const SizedBox(height: 16),
        _buildTextField('Message', isDark, controller: _messageController, isMultiline: true),
        const SizedBox(height: 24),
        GestureDetector(
          onTap: () => setState(() => _agreed = !_agreed),
          behavior: HitTestBehavior.opaque,
          child: Row(
            children: [
              Container(
                width: 20,
                height: 20,
                decoration: BoxDecoration(
                  color: _agreed ? (isDark ? Colors.white : Colors.black) : Colors.transparent,
                  border: Border.all(color: (isDark ? Colors.white : Colors.black).withOpacity(_agreed ? 1.0 : 0.1)),
                  borderRadius: BorderRadius.circular(6),
                ),
                child: _agreed 
                  ? Icon(LucideIcons.check, size: 12, color: isDark ? Colors.black : Colors.white)
                  : null,
              ),
              const SizedBox(width: 12),
              Expanded(
                child: Text(
                  "I've read and agree to the Privacy Policy.",
                  style: GoogleFonts.inter(
                    fontSize: 11,
                    fontWeight: FontWeight.w500,
                    color: (isDark ? Colors.white : Colors.black).withOpacity(0.5),
                  ),
                ),
              ),
            ],
          ),
        ),
        const SizedBox(height: 32),
        ElevatedButton(
          onPressed: _submitting ? null : _handleSubmit,
          style: ElevatedButton.styleFrom(
            backgroundColor: isDark ? Colors.white : Colors.black,
            foregroundColor: isDark ? Colors.black : Colors.white,
            disabledBackgroundColor: (isDark ? Colors.white : Colors.black).withOpacity(0.3),
            minimumSize: const Size(double.infinity, 64),
            shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
            elevation: 0,
          ),
          child: _submitting 
            ? const SizedBox(width: 20, height: 20, child: CircularProgressIndicator(strokeWidth: 2, color: Colors.grey))
            : Text(
                'SUBMIT INQUIRY',
                style: GoogleFonts.montserrat(
                  fontSize: 11,
                  fontWeight: FontWeight.w900,
                  letterSpacing: 2,
                ),
              ),
        ),
      ],
    );
  }

  Widget _buildTextField(String hint, bool isDark, {required TextEditingController controller, bool isMultiline = false}) {
    return Container(
      decoration: BoxDecoration(
        color: (isDark ? Colors.white : Colors.black).withOpacity(0.03),
        borderRadius: BorderRadius.circular(20),
        border: Border.all(color: (isDark ? Colors.white : Colors.black).withOpacity(0.05)),
      ),
      child: TextField(
        controller: controller,
        maxLines: isMultiline ? 5 : 1,
        style: GoogleFonts.inter(fontSize: 14, color: isDark ? Colors.white : Colors.black),
        decoration: InputDecoration(
          hintText: hint,
          hintStyle: GoogleFonts.inter(
            color: (isDark ? Colors.white : Colors.black).withOpacity(0.3),
            fontSize: 14,
          ),
          contentPadding: const EdgeInsets.symmetric(horizontal: 24, vertical: 20),
          border: InputBorder.none,
        ),
      ),
    );
  }

  Widget _buildContactInfoTile({
    required IconData icon,
    required String label,
    required String value,
    String? subValue,
    required VoidCallback onTap,
    required bool isDark,
  }) {
    return InkWell(
      onTap: onTap,
      child: Row(
        children: [
          Container(
            width: 56,
            height: 56,
            decoration: BoxDecoration(
              color: isDark ? Colors.white : Colors.black,
              shape: BoxShape.circle,
            ),
            child: Icon(icon, color: isDark ? Colors.black : Colors.white, size: 24),
          ),
          const SizedBox(width: 20),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  label,
                  style: GoogleFonts.montserrat(
                    fontSize: 10,
                    fontWeight: FontWeight.w900,
                    letterSpacing: 2,
                    color: (isDark ? Colors.white : Colors.black).withOpacity(0.3),
                  ),
                ),
                const SizedBox(height: 4),
                Text(
                  value,
                  style: GoogleFonts.montserrat(
                    fontSize: 16,
                    fontWeight: FontWeight.bold,
                    color: isDark ? Colors.white : Colors.black,
                  ),
                ),
                if (subValue != null) ...[
                  const SizedBox(height: 2),
                  Text(
                    subValue,
                    style: GoogleFonts.montserrat(
                      fontSize: 11,
                      fontWeight: FontWeight.w500,
                      color: (isDark ? Colors.white : Colors.black).withOpacity(0.4),
                    ),
                  ),
                ],
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildMapSection(Map mapConfig, bool isDark) {
    return Container(
      height: 320,
      decoration: BoxDecoration(
        color: (isDark ? Colors.white : Colors.black).withOpacity(0.03),
        borderRadius: BorderRadius.circular(40),
        border: Border.all(color: (isDark ? Colors.white : Colors.black).withOpacity(0.05)),
      ),
      clipBehavior: Clip.antiAlias,
      child: Stack(
        fit: StackFit.expand,
        children: [
          WebViewWidget(controller: _mapController),
          Positioned.fill(
            child: GestureDetector(
              onTap: () => _launchUrl(mapConfig['google_maps_url'] ?? 'https://maps.google.com/?q=M4+Aura+Heights'),
              child: Container(color: Colors.transparent),
            ),
          ),
          Positioned(
            bottom: 24,
            left: 0,
            right: 0,
            child: Center(
              child: Container(
                padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 12),
                decoration: BoxDecoration(
                  color: Colors.black.withOpacity(0.8),
                  borderRadius: BorderRadius.circular(30),
                  border: Border.all(color: Colors.white10),
                ),
                child: Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    const Icon(LucideIcons.mapPin, color: Colors.white, size: 14),
                    const SizedBox(width: 8),
                    Text(
                      'OPEN MAP',
                      style: GoogleFonts.montserrat(
                        color: Colors.white,
                        fontSize: 10,
                        fontWeight: FontWeight.w900,
                        letterSpacing: 2,
                      ),
                    ),
                  ],
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }
}
