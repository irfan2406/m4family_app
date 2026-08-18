import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:lucide_icons/lucide_icons.dart';
import 'package:m4_mobile/core/utils/validators.dart';
import 'package:m4_mobile/presentation/widgets/side_menu_button.dart';
import 'package:m4_mobile/presentation/widgets/conditional_drawer.dart';
import 'package:m4_mobile/presentation/providers/auth_provider.dart';
import 'package:flutter_animate/flutter_animate.dart';
import 'package:url_launcher/url_launcher.dart';
import 'package:webview_flutter/webview_flutter.dart';
import 'package:m4_mobile/presentation/widgets/navigation_pill.dart';
import 'package:m4_mobile/presentation/widgets/main_shell.dart';

/// Web `/contact` (`app/(user)/contact/page.tsx`) — "M4 Family Developments /
/// Get in touch with us": a gradient intro + contact form (name/email/phone/
/// message), followed by office cards, a grayscale map preview, and a direct
/// email/phone card.
class ContactScreen extends ConsumerStatefulWidget {
  const ContactScreen({super.key});

  @override
  ConsumerState<ContactScreen> createState() => _ContactScreenState();
}

class _ContactScreenState extends ConsumerState<ContactScreen> {
  Map<String, dynamic>? _config;
  bool _isLoading = true;
  late final WebViewController _mapController;

  // Contact form (web parity: "Get in touch with us").
  final _nameController = TextEditingController();
  final _emailController = TextEditingController();
  final _phoneController = TextEditingController();
  final _messageController = TextEditingController();
  bool _isSubmitting = false;
  bool _agreedToPrivacy = false;

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

  Future<void> _submitForm() async {
    final validationError =
        Validators.nameError(_nameController.text, field: 'full name') ??
        Validators.emailError(_emailController.text) ??
        Validators.phoneError(_phoneController.text);
    if (validationError != null) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          backgroundColor: const Color(0xFFC65B46),
          content: Text(validationError),
        ),
      );
      return;
    }
    if (!_agreedToPrivacy) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          backgroundColor: Color(0xFFC65B46),
          content: Text('Please agree to the Privacy Policy'),
        ),
      );
      return;
    }
    setState(() => _isSubmitting = true);
    try {
      final apiClient = ref.read(apiClientProvider);
      await apiClient.submitLead({
        'name': _nameController.text.trim(),
        'email': _emailController.text.trim(),
        'phone': _phoneController.text.trim(),
        'message': _messageController.text.trim(),
        // Server-side enum: source = online | cp | walk-in | referral | other.
        'source': 'online',
      });
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Thank you! We will get in touch with you shortly.'),
          backgroundColor: Color(0xFF163A2C),
        ),
      );
      _nameController.clear();
      _emailController.clear();
      _phoneController.clear();
      _messageController.clear();
      _agreedToPrivacy = false;
    } catch (e) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          backgroundColor: const Color(0xFFC65B46),
          content: Text('Error: $e'),
        ),
      );
    } finally {
      if (mounted) setState(() => _isSubmitting = false);
    }
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

  Future<void> _launchUrl(String url) async {
    if (url.isEmpty) return;
    final uri = Uri.parse(url);
    if (await canLaunchUrl(uri)) {
      await launchUrl(uri, mode: LaunchMode.externalApplication);
    }
  }

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final mapConfig = _config?['map_config'] as Map? ?? {};
    final contactEmail = _config?['contact_email'] ?? "sales@m4group.in";
    final contactPhone = _config?['contact_phone'] ?? "+91 99308 50993";

    // Head-office address for the CONTACT INFORMATION block.
    final rawOffices = (_config?['offices'] as List?) ?? [];
    final contactAddress = rawOffices.isNotEmpty
        ? ((rawOffices.first as Map)['address'] ?? '').toString()
        : '604, 6th Floor, M4 Aura Heights, Maulana Shaukat Ali Road, '
              'Grant Road, Mumbai - 400007';
    final mapsUrl =
        (mapConfig['google_maps_url'] ??
                'https://maps.google.com/?q=M4+Aura+Heights')
            .toString();

    return Scaffold(
      backgroundColor: Theme.of(context).scaffoldBackgroundColor,
      extendBody: true,
      drawer: const ConditionalDrawer(),
      // Own nav pill ONLY when pushed standalone (from the menu). As a tab
      // inside GuestMainShell the shell already draws one — rendering both
      // stacked two navigation bars on top of each other.
      bottomNavigationBar: Navigator.of(context).canPop()
          ? NavigationPill(
              currentIndex: -1,
              onTap: (i) {
                ref.read(navigationProvider.notifier).state = i;
                Navigator.of(context).popUntil((r) => r.isFirst);
              },
            )
          : null,
      body: _isLoading
          ? Center(
              child: CircularProgressIndicator(
                color: isDark ? Colors.white24 : Colors.black12,
              ),
            )
          : SafeArea(
              bottom: false,
              child: SingleChildScrollView(
                padding: const EdgeInsets.fromLTRB(24, 8, 24, 120),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    _buildHeader(isDark),
                    const SizedBox(height: 28),
                    // Web parity: "GET IN TOUCH WITH US" intro + contact form.
                    _buildIntro(isDark),
                    const SizedBox(height: 32),
                    _buildContactForm(isDark),
                    const SizedBox(height: 48),
                    // CONTACT INFORMATION — plain black heading (no gradient).
                    Text(
                      'CONTACT INFORMATION',
                      style: GoogleFonts.gelasio(
                        color: isDark ? Colors.white : Color(0xFF163A2C),
                        fontSize: 22,
                        fontWeight: FontWeight.w700,
                        letterSpacing: -0.5,
                      ),
                    ),
                    const SizedBox(height: 24),
                    _buildContactInfo(
                      contactEmail,
                      contactPhone,
                      contactAddress,
                      mapsUrl,
                      isDark,
                    ),
                    const SizedBox(height: 44),
                    // OUR HEAD OFFICE — plain black heading (no gradient).
                    Text(
                      'OUR HEAD OFFICE',
                      style: GoogleFonts.gelasio(
                        color: isDark ? Colors.white : Color(0xFF163A2C),
                        fontSize: 22,
                        fontWeight: FontWeight.w700,
                        letterSpacing: -0.5,
                      ),
                    ),
                    const SizedBox(height: 20),
                    _buildMapSection(mapConfig, isDark),
                  ],
                ),
              ),
            ),
    );
  }

  // Web parity: rounded back button + "M4 FAMILY" / "DEVELOPMENTS".
  Widget _buildHeader(bool isDark) {
    return Row(
      children: [
        GestureDetector(
          onTap: () => Navigator.pop(context),
          child: Container(
            width: 44,
            height: 44,
            alignment: Alignment.center,
            decoration: BoxDecoration(
              color: isDark ? Colors.white.withOpacity(0.05) : Colors.white,
              borderRadius: BorderRadius.circular(16),
              border: Border.all(
                color: (isDark ? Colors.white : Color(0xFF163A2C)).withOpacity(0.08),
              ),
              boxShadow: isDark
                  ? null
                  : [
                      BoxShadow(
                        color: Colors.black.withOpacity(0.05),
                        blurRadius: 16,
                        offset: const Offset(0, 6),
                      ),
                    ],
            ),
            child: Icon(
              LucideIcons.arrowLeft,
              size: 18,
              color: isDark ? Colors.white : Color(0xFF163A2C),
            ),
          ),
        ),
        const SizedBox(width: 16),
        Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              'M4 FAMILY',
              style: GoogleFonts.gelasio(
                fontSize: 20,
                fontWeight: FontWeight.w800,
                color: isDark ? Colors.white : Color(0xFF163A2C),
                letterSpacing: -0.3,
              ),
            ),
            const SizedBox(height: 2),
            Text(
              'DEVELOPMENTS',
              style: GoogleFonts.gelasio(
                fontSize: 9,
                fontWeight: FontWeight.w800,
                color: (isDark ? Colors.white : Color(0xFF163A2C)).withOpacity(0.68),
                letterSpacing: 3.5,
              ),
            ),
          ],
        ),
        const Spacer(),
        const SideMenuButton(),
      ],
    ).animate().fadeIn().slideX(begin: -0.1);
  }

  // "GET IN TOUCH WITH US" heading + intro paragraph.
  Widget _buildIntro(bool isDark) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        _introText(
          'GET IN TOUCH WITH US',
          GoogleFonts.gelasio(
            fontSize: 26,
            fontWeight: FontWeight.w800,
            letterSpacing: -0.5,
            height: 1.15,
          ),
          isDark,
        ),
        const SizedBox(height: 18),
        _introText(
          "Thank you for visiting our website! We would love to hear from "
          "you. Whether you have a question, feedback, or simply want to say "
          "hello we're here to help. Please feel free to get in touch with us "
          "using the contact information below or by filling out the contact "
          "form. We strive to respond to all inquiries promptly.",
          GoogleFonts.ebGaramond(
            fontSize: 14,
            fontWeight: FontWeight.w500,
            height: 1.7,
          ),
          isDark,
        ),
      ],
    ).animate().fadeIn(delay: 80.ms);
  }

  // Was a blue→gold gradient (ShaderMask) in light mode; now solid — near-black
  // on light, white on dark so it stays readable in both.
  Widget _introText(String text, TextStyle style, bool isDark) {
    return Text(
      text,
      style: style.copyWith(
        color: isDark ? Colors.white.withOpacity(0.9) : Colors.black,
      ),
    );
  }

  Widget _buildContactForm(bool isDark) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        _formField(
          _nameController,
          'Full Name *',
          keyboardType: TextInputType.name,
          inputFormatters: Validators.nameFormatters,
        ),
        const SizedBox(height: 16),
        _formField(
          _emailController,
          'Email *',
          keyboardType: TextInputType.emailAddress,
          inputFormatters: Validators.emailFormatters,
        ),
        const SizedBox(height: 16),
        _formField(
          _phoneController,
          '+91 98653 21250 *',
          keyboardType: TextInputType.phone,
          inputFormatters: Validators.phoneFormatters,
        ),
        const SizedBox(height: 16),
        _formField(_messageController, 'Message', maxLines: 4),
        const SizedBox(height: 20),
        _buildPrivacyCheckbox(isDark),
        const SizedBox(height: 20),
        SizedBox(
          height: 58,
          child: ElevatedButton(
            onPressed: _isSubmitting ? null : _submitForm,
            style: ElevatedButton.styleFrom(
              backgroundColor: isDark ? Colors.white : Color(0xFF163A2C),
              foregroundColor: isDark ? Colors.black : Colors.white,
              elevation: 0,
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(18),
              ),
            ),
            child: _isSubmitting
                ? SizedBox(
                    width: 20,
                    height: 20,
                    child: CircularProgressIndicator(
                      strokeWidth: 2,
                      color: Theme.of(context).scaffoldBackgroundColor,
                    ),
                  )
                : Row(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      Text(
                        'SUBMIT INQUIRY',
                        style: GoogleFonts.gelasio(
                          fontSize: 12,
                          fontWeight: FontWeight.w800,
                          letterSpacing: 1.5,
                        ),
                      ),
                      const SizedBox(width: 10),
                      const Icon(LucideIcons.arrowRight, size: 16),
                    ],
                  ),
          ),
        ),
      ],
    ).animate().fadeIn(delay: 150.ms);
  }

  Widget _formField(
    TextEditingController controller,
    String hint, {
    int maxLines = 1,
    TextInputType? keyboardType,
    List<TextInputFormatter>? inputFormatters,
  }) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    return TextField(
      controller: controller,
      maxLines: maxLines,
      keyboardType: keyboardType,
      inputFormatters: inputFormatters,
      style: GoogleFonts.ebGaramond(
        color: isDark ? Colors.white : Color(0xFF163A2C),
        fontSize: 15,
        fontWeight: FontWeight.w500,
      ),
      decoration: InputDecoration(
        hintText: hint,
        hintStyle: GoogleFonts.ebGaramond(
          // Was 0.4 — too faint to read on the white field.
          color: (isDark ? Colors.white : Color(0xFF163A2C)).withOpacity(0.6),
          fontSize: 14,
          fontWeight: FontWeight.w500,
        ),
        filled: true,
        fillColor: isDark ? Colors.white.withOpacity(0.03) : Colors.white,
        contentPadding: const EdgeInsets.symmetric(
          horizontal: 20,
          vertical: 18,
        ),
        enabledBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(16),
          borderSide: BorderSide(
            color: (isDark ? Colors.white : Color(0xFF163A2C)).withOpacity(0.1),
          ),
        ),
        focusedBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(16),
          borderSide: const BorderSide(color: Color(0xFFC5A35B), width: 1.6),
        ),
      ),
    );
  }

  Widget _buildPrivacyCheckbox(bool isDark) {
    return GestureDetector(
      onTap: () => setState(() => _agreedToPrivacy = !_agreedToPrivacy),
      behavior: HitTestBehavior.opaque,
      child: Row(
        children: [
          Container(
            width: 22,
            height: 22,
            alignment: Alignment.center,
            decoration: BoxDecoration(
              color: _agreedToPrivacy
                  ? (isDark ? Colors.white : Color(0xFF163A2C))
                  : Colors.transparent,
              borderRadius: BorderRadius.circular(6),
              border: Border.all(
                color: (isDark ? Colors.white : Color(0xFF163A2C)).withOpacity(0.3),
                width: 1.5,
              ),
            ),
            child: _agreedToPrivacy
                ? Icon(
                    LucideIcons.check,
                    size: 14,
                    color: Theme.of(context).scaffoldBackgroundColor,
                  )
                : null,
          ),
          const SizedBox(width: 12),
          Expanded(
            child: RichText(
              text: TextSpan(
                style: GoogleFonts.ebGaramond(
                  fontSize: 12,
                  fontWeight: FontWeight.w500,
                  color: (isDark ? Colors.white : Color(0xFF163A2C)).withOpacity(
                    0.7,
                  ),
                ),
                children: [
                  const TextSpan(text: "I've read and agree to the "),
                  TextSpan(
                    text: 'Privacy Policy',
                    style: GoogleFonts.ebGaramond(
                      fontSize: 12,
                      fontWeight: FontWeight.w800,
                      color: isDark ? Colors.white : Color(0xFF163A2C),
                      decoration: TextDecoration.underline,
                    ),
                  ),
                  const TextSpan(text: '.'),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildContactInfo(
    String email,
    String phone,
    String address,
    String mapsUrl,
    bool isDark,
  ) {
    final emailUpper = email.toUpperCase();
    return Column(
      children: [
        _contactInfoRow(
          icon: LucideIcons.phone,
          label: 'SALES INQUIRY',
          value: phone,
          sub: emailUpper,
          onTap: () =>
              _launchUrl('tel:${phone.replaceAll(RegExp(r'[^+0-9]'), '')}'),
          isDark: isDark,
        ),
        const SizedBox(height: 28),
        _contactInfoRow(
          icon: LucideIcons.mail,
          label: 'OTHER INQUIRIES',
          value: '+91 22 4601 8844',
          sub: emailUpper,
          onTap: () => _launchUrl('tel:+912246018844'),
          isDark: isDark,
        ),
        const SizedBox(height: 28),
        _contactInfoRow(
          icon: LucideIcons.mapPin,
          label: 'ADDRESS',
          value: address,
          sub: null,
          onTap: () => _launchUrl(mapsUrl),
          isDark: isDark,
          valueSize: 12.5,
        ),
      ],
    ).animate().fadeIn(delay: 250.ms);
  }

  Widget _contactInfoRow({
    required IconData icon,
    required String label,
    required String value,
    String? sub,
    required VoidCallback onTap,
    required bool isDark,
    double valueSize = 15,
  }) {
    return GestureDetector(
      onTap: onTap,
      behavior: HitTestBehavior.opaque,
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Container(
            width: 52,
            height: 52,
            alignment: Alignment.center,
            decoration: BoxDecoration(
              color: isDark ? Colors.white : Color(0xFF163A2C),
              shape: BoxShape.circle,
              boxShadow: isDark
                  ? null
                  : [
                      BoxShadow(
                        color: Colors.black.withOpacity(0.12),
                        blurRadius: 14,
                        offset: const Offset(0, 6),
                      ),
                    ],
            ),
            child: Icon(
              icon,
              color: Theme.of(context).scaffoldBackgroundColor,
              size: 20,
            ),
          ),
          const SizedBox(width: 18),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  label,
                  style: GoogleFonts.gelasio(
                    color: isDark
                        ? Colors.white.withOpacity(0.7)
                        : const Color(0xFF141B3A),
                    fontSize: 10,
                    fontWeight: FontWeight.w800,
                    letterSpacing: 2,
                  ),
                ),
                const SizedBox(height: 5),
                Text(
                  value,
                  style: GoogleFonts.ebGaramond(
                    color: isDark ? Colors.white : Color(0xFF163A2C),
                    fontSize: valueSize,
                    fontWeight: FontWeight.w800,
                    letterSpacing: -0.2,
                    height: 1.4,
                  ),
                ),
                if (sub != null) ...[
                  const SizedBox(height: 4),
                  Text(
                    sub,
                    style: GoogleFonts.ebGaramond(
                      color: (isDark ? Colors.white : Color(0xFF163A2C)).withOpacity(
                        0.5,
                      ),
                      fontSize: 10,
                      fontWeight: FontWeight.w600,
                      letterSpacing: 1,
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

  // ignore: unused_element
  Widget _sectionLabel(String text, bool isDark) {
    return Padding(
      padding: const EdgeInsets.only(left: 8),
      child: Text(
        text,
        style: GoogleFonts.gelasio(
          fontSize: 9,
          fontWeight: FontWeight.w800,
          color: (isDark ? Colors.white : Color(0xFF163A2C)).withOpacity(0.68),
          letterSpacing: 2,
        ),
      ),
    );
  }

  // Web parity: glass card (rounded-[2.5rem]) with a MapPin icon box, title +
  // address, and Directions (outline) / Call Now (filled) buttons.
  // Retained for future use (superseded by the CONTACT INFORMATION block).
  // ignore: unused_element
  Widget _officeCard(Map office, bool isDark) {
    final title = (office['title'] ?? 'Corporate Head Office').toString();
    final address = (office['address'] ?? '').toString();
    final phone = (office['phone'] ?? '').toString();
    final mapLink = (office['mapLink'] ?? '').toString();

    return Container(
      padding: const EdgeInsets.all(28),
      decoration: BoxDecoration(
        color: isDark ? Colors.white.withOpacity(0.03) : Colors.white,
        borderRadius: BorderRadius.circular(36),
        border: Border.all(
          color: (isDark ? Colors.white : Color(0xFF163A2C)).withOpacity(0.06),
        ),
        boxShadow: isDark
            ? null
            : [
                BoxShadow(
                  color: Colors.black.withOpacity(0.06),
                  blurRadius: 30,
                  offset: const Offset(0, 14),
                ),
              ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Container(
                width: 48,
                height: 48,
                alignment: Alignment.center,
                decoration: BoxDecoration(
                  color: isDark ? Colors.white.withOpacity(0.05) : Colors.white,
                  borderRadius: BorderRadius.circular(16),
                  border: Border.all(
                    color: (isDark ? Colors.white : Color(0xFF163A2C)).withOpacity(
                      0.08,
                    ),
                  ),
                  boxShadow: isDark
                      ? null
                      : [
                          BoxShadow(
                            color: Colors.black.withOpacity(0.06),
                            blurRadius: 16,
                            offset: const Offset(0, 6),
                          ),
                        ],
                ),
                child: Icon(
                  LucideIcons.mapPin,
                  color: isDark ? Colors.white : Color(0xFF163A2C),
                  size: 20,
                ),
              ),
              const SizedBox(width: 20),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      title.toUpperCase(),
                      style: GoogleFonts.ebGaramond(
                        fontSize: 17,
                        fontWeight: FontWeight.w800,
                        color: isDark ? Colors.white : Color(0xFF163A2C),
                        letterSpacing: -0.2,
                        height: 1.15,
                      ),
                    ),
                    const SizedBox(height: 12),
                    Text(
                      address,
                      style: GoogleFonts.ebGaramond(
                        fontSize: 11,
                        fontWeight: FontWeight.w500,
                        color: (isDark ? Colors.white : Color(0xFF163A2C))
                            .withOpacity(0.6),
                        height: 1.6,
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ),
          const SizedBox(height: 24),
          Row(
            children: [
              // Directions (outline)
              Expanded(
                child: GestureDetector(
                  onTap: () => _launchUrl(mapLink),
                  child: Container(
                    height: 48,
                    alignment: Alignment.center,
                    decoration: BoxDecoration(
                      color: isDark
                          ? Colors.white.withOpacity(0.03)
                          : Colors.white,
                      borderRadius: BorderRadius.circular(14),
                      border: Border.all(
                        color: (isDark ? Colors.white : Color(0xFF163A2C))
                            .withOpacity(0.12),
                      ),
                    ),
                    child: Row(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        Icon(
                          LucideIcons.externalLink,
                          size: 15,
                          color: isDark ? Colors.white : Color(0xFF163A2C),
                        ),
                        const SizedBox(width: 8),
                        Text(
                          'DIRECTIONS',
                          style: GoogleFonts.gelasio(
                            fontSize: 9,
                            fontWeight: FontWeight.w800,
                            letterSpacing: 1.5,
                            color: isDark ? Colors.white : Color(0xFF163A2C),
                          ),
                        ),
                      ],
                    ),
                  ),
                ),
              ),
              const SizedBox(width: 12),
              // Call Now (filled)
              Expanded(
                child: GestureDetector(
                  onTap: () => _launchUrl('tel:$phone'),
                  child: Container(
                    height: 48,
                    alignment: Alignment.center,
                    decoration: BoxDecoration(
                      color: isDark ? Colors.white : Color(0xFF163A2C),
                      borderRadius: BorderRadius.circular(14),
                    ),
                    child: Row(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        Icon(
                          LucideIcons.phone,
                          size: 15,
                          color: Theme.of(context).scaffoldBackgroundColor,
                        ),
                        const SizedBox(width: 8),
                        Text(
                          'CALL NOW',
                          style: GoogleFonts.gelasio(
                            fontSize: 9,
                            fontWeight: FontWeight.w800,
                            letterSpacing: 1.5,
                            color: Theme.of(context).scaffoldBackgroundColor,
                          ),
                        ),
                      ],
                    ),
                  ),
                ),
              ),
            ],
          ),
        ],
      ),
    ).animate().fadeIn(delay: 100.ms);
  }

  Widget _buildMapSection(Map mapConfig, bool isDark) {
    final mapsUrl =
        mapConfig['google_maps_url'] ??
        'https://maps.google.com/?q=M4+Aura+Heights';
    return Container(
      height: 300,
      decoration: BoxDecoration(
        color: (isDark ? Colors.white : Color(0xFF163A2C)).withOpacity(0.03),
        borderRadius: BorderRadius.circular(36),
        border: Border.all(
          color: (isDark ? Colors.white : Color(0xFF163A2C)).withOpacity(0.06),
        ),
        boxShadow: isDark
            ? null
            : [
                BoxShadow(
                  color: Colors.black.withOpacity(0.06),
                  blurRadius: 30,
                  offset: const Offset(0, 14),
                ),
              ],
      ),
      clipBehavior: Clip.antiAlias,
      child: Stack(
        fit: StackFit.expand,
        children: [
          WebViewWidget(controller: _mapController),
          // Web parity: "Open in Maps" link top-left.
          Positioned(
            top: 16,
            left: 16,
            child: GestureDetector(
              onTap: () => _launchUrl(mapsUrl),
              child: Container(
                padding: const EdgeInsets.symmetric(
                  horizontal: 12,
                  vertical: 8,
                ),
                decoration: BoxDecoration(
                  color: (isDark ? Colors.black : Colors.white).withOpacity(
                    0.8,
                  ),
                  borderRadius: BorderRadius.circular(10),
                ),
                child: Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Text(
                      'Open in Maps',
                      style: GoogleFonts.ebGaramond(
                        color: isDark ? Colors.white : Color(0xFF163A2C),
                        fontSize: 10,
                        fontWeight: FontWeight.w700,
                      ),
                    ),
                    const SizedBox(width: 6),
                    Icon(
                      LucideIcons.externalLink,
                      size: 12,
                      color: isDark ? Colors.white : Color(0xFF163A2C),
                    ),
                  ],
                ),
              ),
            ),
          ),
          // "OPEN MAP" pill bottom-center.
          Positioned(
            bottom: 24,
            left: 0,
            right: 0,
            child: Center(
              child: GestureDetector(
                onTap: () => _launchUrl(mapsUrl),
                child: Container(
                  padding: const EdgeInsets.symmetric(
                    horizontal: 28,
                    vertical: 12,
                  ),
                  decoration: BoxDecoration(
                    color: (isDark ? Colors.black : Colors.white).withOpacity(
                      0.92,
                    ),
                    borderRadius: BorderRadius.circular(30),
                    border: Border.all(
                      color: (isDark ? Colors.white : Color(0xFF163A2C)).withOpacity(
                        0.1,
                      ),
                    ),
                  ),
                  child: Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Icon(
                        LucideIcons.mapPin,
                        color: isDark ? Colors.white : Color(0xFF163A2C),
                        size: 14,
                      ),
                      const SizedBox(width: 8),
                      Text(
                        'OPEN MAP',
                        style: GoogleFonts.gelasio(
                          color: isDark ? Colors.white : Color(0xFF163A2C),
                          fontSize: 10,
                          fontWeight: FontWeight.w800,
                          letterSpacing: 2,
                        ),
                      ),
                    ],
                  ),
                ),
              ),
            ),
          ),
        ],
      ),
    ).animate().fadeIn(delay: 200.ms);
  }

  // Web parity: one card with email + phone rows separated by a divider.
  // Retained for future use (superseded by the CONTACT INFORMATION block).
  // ignore: unused_element
  Widget _buildDirectContact(String email, String phone, bool isDark) {
    return Container(
      decoration: BoxDecoration(
        color: isDark ? Colors.white.withOpacity(0.03) : Colors.white,
        borderRadius: BorderRadius.circular(28),
        border: Border.all(
          color: (isDark ? Colors.white : Color(0xFF163A2C)).withOpacity(0.06),
        ),
        boxShadow: isDark
            ? null
            : [
                BoxShadow(
                  color: Colors.black.withOpacity(0.06),
                  blurRadius: 30,
                  offset: const Offset(0, 14),
                ),
              ],
      ),
      clipBehavior: Clip.antiAlias,
      child: Column(
        children: [
          _contactRow(
            icon: LucideIcons.mail,
            value: email,
            label: 'SALES & ENQUIRIES',
            onTap: () => _launchUrl('mailto:$email'),
            isDark: isDark,
          ),
          Divider(
            height: 1,
            thickness: 1,
            color: (isDark ? Colors.white : Color(0xFF163A2C)).withOpacity(0.06),
          ),
          _contactRow(
            icon: LucideIcons.phone,
            value: phone,
            label: 'DIRECT LINE',
            onTap: () => _launchUrl('tel:$phone'),
            isDark: isDark,
          ),
        ],
      ),
    ).animate().fadeIn(delay: 300.ms);
  }

  // ignore: unused_element
  Widget _contactRow({
    required IconData icon,
    required String value,
    required String label,
    required VoidCallback onTap,
    required bool isDark,
  }) {
    return Material(
      color: Colors.transparent,
      child: InkWell(
        onTap: onTap,
        child: Padding(
          padding: const EdgeInsets.all(20),
          child: Row(
            children: [
              Container(
                width: 48,
                height: 48,
                alignment: Alignment.center,
                decoration: BoxDecoration(
                  color: isDark ? Colors.white.withOpacity(0.05) : Colors.white,
                  borderRadius: BorderRadius.circular(16),
                  border: Border.all(
                    color: (isDark ? Colors.white : Color(0xFF163A2C)).withOpacity(
                      0.08,
                    ),
                  ),
                  boxShadow: isDark
                      ? null
                      : [
                          BoxShadow(
                            color: Colors.black.withOpacity(0.05),
                            blurRadius: 14,
                            offset: const Offset(0, 6),
                          ),
                        ],
                ),
                child: Icon(
                  icon,
                  color: isDark ? Colors.white : Color(0xFF163A2C),
                  size: 18,
                ),
              ),
              const SizedBox(width: 20),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      value,
                      style: GoogleFonts.ebGaramond(
                        fontSize: 15,
                        fontWeight: FontWeight.w800,
                        color: isDark ? Colors.white : Color(0xFF163A2C),
                        letterSpacing: -0.2,
                      ),
                    ),
                    const SizedBox(height: 3),
                    Text(
                      label,
                      style: GoogleFonts.gelasio(
                        fontSize: 9,
                        fontWeight: FontWeight.w800,
                        color: (isDark ? Colors.white : Color(0xFF163A2C))
                            .withOpacity(0.68),
                        letterSpacing: 2,
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
