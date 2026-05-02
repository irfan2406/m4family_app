import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:lucide_icons/lucide_icons.dart';
import 'package:m4_mobile/core/theme/app_theme.dart';
import 'package:m4_mobile/presentation/providers/auth_provider.dart';
import 'package:flutter_animate/flutter_animate.dart';
import 'package:url_launcher/url_launcher.dart';
import 'dart:ui';
import 'package:m4_mobile/presentation/widgets/conditional_drawer.dart';

class ContactScreen extends ConsumerStatefulWidget {
  const ContactScreen({super.key});

  @override
  ConsumerState<ContactScreen> createState() => _ContactScreenState();
}

class _ContactScreenState extends ConsumerState<ContactScreen> {
  final _formKey = GlobalKey<FormState>();
  final TextEditingController _nameController = TextEditingController();
  final TextEditingController _emailController = TextEditingController();
  final TextEditingController _phoneController = TextEditingController();
  final TextEditingController _messageController = TextEditingController();
  
  bool _agreed = false;
  bool _isSubmitting = false;

  @override
  void dispose() {
    _nameController.dispose();
    _emailController.dispose();
    _phoneController.dispose();
    _messageController.dispose();
    super.dispose();
  }

  Future<void> _handleSubmit() async {
    if (!_formKey.currentState!.validate()) return;
    if (!_agreed) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Please agree to the Privacy Policy')),
      );
      return;
    }

    setState(() => _isSubmitting = true);
    try {
      final apiClient = ref.read(apiClientProvider);
      final res = await apiClient.submitLead({
        'name': _nameController.text.trim(),
        'email': _emailController.text.trim(),
        'phone': _phoneController.text.trim(),
        'message': _messageController.text.trim(),
        'interest': 'General Enquiry',
        'source': 'online',
        'notes': 'Submitted via Mobile App Contact Page',
        'status': 'New',
      });

      if (res.data['status'] == true) {
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(content: Text('Enquiry Sent Successfully. Our team will contact you shortly.'), backgroundColor: Colors.green),
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
          SnackBar(content: Text('Failed to send enquiry: $e'), backgroundColor: Colors.redAccent),
        );
      }
    } finally {
      if (mounted) setState(() => _isSubmitting = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    
    return Scaffold(
      backgroundColor: Theme.of(context).scaffoldBackgroundColor,
      drawer: const ConditionalDrawer(),
      body: CustomScrollView(
        slivers: [
          // 🏷️ Header (Web Parity)
          SliverAppBar(
            floating: true,
            backgroundColor: Theme.of(context).scaffoldBackgroundColor.withOpacity(0.9),
            surfaceTintColor: Colors.transparent,
            elevation: 0,
            leadingWidth: 80,
            leading: Padding(
              padding: const EdgeInsets.only(left: 12),
              child: Center(
                child: IconButton(
                  onPressed: () => Navigator.pop(context),
                  icon: Icon(LucideIcons.chevronLeft, color: Theme.of(context).colorScheme.onSurface, size: 28),
                  style: IconButton.styleFrom(
                    backgroundColor: (isDark ? Colors.white : Colors.black).withOpacity(0.04),
                    padding: EdgeInsets.zero,
                  ),
                ),
              ),
            ),
            title: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              mainAxisSize: MainAxisSize.min,
              children: [
                Text(
                  'M4 FAMILY',
                  style: GoogleFonts.montserrat(
                    fontSize: 16,
                    fontWeight: FontWeight.w900,
                    letterSpacing: -0.5,
                    color: Theme.of(context).colorScheme.onSurface,
                  ),
                ),
                Text(
                  'DEVELOPMENTS',
                  style: GoogleFonts.montserrat(
                    fontSize: 8,
                    fontWeight: FontWeight.w900,
                    letterSpacing: 3,
                    color: Theme.of(context).colorScheme.onSurface.withOpacity(0.5),
                  ),
                ),
              ],
            ),
            actions: [
              Builder(
                builder: (context) => IconButton(
                  onPressed: () => Scaffold.of(context).openDrawer(),
                  icon: Icon(
                    LucideIcons.moreHorizontal,
                    color: Theme.of(context).colorScheme.onSurface,
                    size: 28,
                  ),
                ),
              ),
              const SizedBox(width: 12),
            ],
          ),

          SliverToBoxAdapter(
            child: Padding(
              padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 20),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  // 🎭 Hero Title (Web Parity)
                  Text(
                    'GET IN\nTOUCH WITH\nUS',
                    style: GoogleFonts.montserrat(
                      fontSize: 42,
                      fontWeight: FontWeight.w300,
                      letterSpacing: -1,
                      height: 1.0,
                      color: Theme.of(context).colorScheme.onSurface,
                    ),
                  ).animate().fadeIn().slideX(begin: -0.1),
                  
                  const SizedBox(height: 16),
                  
                  Text(
                    'Thank you for visiting our website! We would love to hear from you. Whether you have a question, feedback, or simply want to say hello we\'re here to help.',
                    style: GoogleFonts.montserrat(
                      fontSize: 14,
                      height: 1.6,
                      color: Theme.of(context).colorScheme.onSurface.withOpacity(0.7),
                      fontWeight: FontWeight.w500,
                    ),
                  ),

                  const SizedBox(height: 40),

                  // 📝 Contact Form
                  Form(
                    key: _formKey,
                    child: Column(
                      children: [
                        _buildField(_nameController, 'Full Name *', LucideIcons.user),
                        const SizedBox(height: 16),
                        _buildField(_emailController, 'Email *', LucideIcons.mail, isEmail: true),
                        const SizedBox(height: 16),
                        _buildField(_phoneController, 'Phone Number *', LucideIcons.phone, isPhone: true),
                        const SizedBox(height: 16),
                        _buildField(_messageController, 'Message', LucideIcons.messageSquare, isLarge: true),
                        
                        const SizedBox(height: 16),
                        
                        Row(
                          children: [
                            Checkbox(
                              value: _agreed,
                              onChanged: (val) => setState(() => _agreed = val ?? false),
                              activeColor: Theme.of(context).colorScheme.onSurface,
                              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(4)),
                            ),
                            Expanded(
                              child: Text(
                                'I\'ve read and agree to the Privacy Policy',
                                style: GoogleFonts.montserrat(fontSize: 11, fontWeight: FontWeight.w500),
                              ),
                            ),
                          ],
                        ),

                        const SizedBox(height: 32),

                        SizedBox(
                          width: double.infinity,
                          height: 64,
                          child: ElevatedButton(
                            onPressed: _isSubmitting ? null : _handleSubmit,
                            style: ElevatedButton.styleFrom(
                              backgroundColor: isDark ? Colors.white : Colors.black,
                              foregroundColor: isDark ? Colors.black : Colors.white,
                              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
                              elevation: 0,
                            ),
                            child: Text(
                              _isSubmitting ? 'SUBMITTING...' : 'SUBMIT',
                              style: GoogleFonts.montserrat(fontWeight: FontWeight.w900, letterSpacing: 1),
                            ),
                          ),
                        ),
                      ],
                    ),
                  ),

                  const SizedBox(height: 60),

                  // 📞 Contact Info Section
                  Text(
                    'CONTACT INFORMATION',
                    style: GoogleFonts.montserrat(
                      fontSize: 24,
                      fontWeight: FontWeight.w300,
                      letterSpacing: -0.5,
                      color: Theme.of(context).colorScheme.onSurface,
                    ),
                  ),
                  const SizedBox(height: 32),
                  
                  _InfoItem(
                    icon: LucideIcons.phone,
                    label: 'SALES INQUIRY',
                    value: '+91 99308 50993',
                    subValue: 'sales@m4group.in',
                    onTap: () => launchUrl(Uri.parse('tel:+919930850993')),
                  ),
                  const SizedBox(height: 32),
                  _InfoItem(
                    icon: LucideIcons.mail,
                    label: 'OTHER INQUIRIES',
                    value: '+91 22 4601 8844',
                    subValue: 'sales@m4group.in',
                    onTap: () => launchUrl(Uri.parse('tel:+912246018844')),
                  ),
                  const SizedBox(height: 32),
                  _InfoItem(
                    icon: LucideIcons.mapPin,
                    label: 'ADDRESS',
                    value: '604, 6TH FLR, M4 AURA HEIGHTS',
                    subValue: 'GRANT ROAD, MUMBAI 400007',
                    onTap: () => launchUrl(Uri.parse('https://maps.google.com')),
                  ),

                  const SizedBox(height: 60),

                  // 📍 Map Section
                  Text(
                    'OUR HEAD OFFICE',
                    style: GoogleFonts.montserrat(
                      fontSize: 24,
                      fontWeight: FontWeight.w300,
                      letterSpacing: -0.5,
                      color: Theme.of(context).colorScheme.onSurface,
                    ),
                  ),
                  const SizedBox(height: 24),
                  Container(
                    height: 300,
                    width: double.infinity,
                    decoration: BoxDecoration(
                      color: (isDark ? Colors.white : Colors.black).withOpacity(0.04),
                      borderRadius: BorderRadius.circular(40),
                      border: Border.all(color: (isDark ? Colors.white : Colors.black).withOpacity(0.1)),
                    ),
                    child: Stack(
                      children: [
                        Center(
                          child: Icon(LucideIcons.map, size: 48, color: (isDark ? Colors.white : Colors.black).withOpacity(0.1)),
                        ),
                        Align(
                          alignment: Alignment.center,
                          child: ElevatedButton(
                            onPressed: () => launchUrl(Uri.parse('https://maps.google.com')),
                            style: ElevatedButton.styleFrom(
                              backgroundColor: isDark ? Colors.white : Colors.black,
                              foregroundColor: isDark ? Colors.black : Colors.white,
                              padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 16),
                              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
                            ),
                            child: const Text('See Location on map', style: TextStyle(fontWeight: FontWeight.bold)),
                          ),
                        ),
                      ],
                    ),
                  ),

                  const SizedBox(height: 100),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildField(TextEditingController ctrl, String hint, IconData icon, {bool isLarge = false, bool isEmail = false, bool isPhone = false}) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    return TextFormField(
      controller: ctrl,
      maxLines: isLarge ? 5 : 1,
      style: GoogleFonts.montserrat(color: Theme.of(context).colorScheme.onSurface, fontSize: 14),
      keyboardType: isEmail ? TextInputType.emailAddress : (isPhone ? TextInputType.phone : TextInputType.text),
      validator: (val) {
        if (hint.contains('*') && (val == null || val.isEmpty)) return 'This field is required';
        return null;
      },
      decoration: InputDecoration(
        hintText: hint,
        hintStyle: GoogleFonts.montserrat(fontSize: 13, color: Theme.of(context).colorScheme.onSurface.withOpacity(0.4)),
        filled: true,
        fillColor: isDark ? const Color(0xFF18181B) : Colors.white,
        prefixIcon: Icon(icon, size: 18, color: Theme.of(context).colorScheme.onSurface.withOpacity(0.4)),
        contentPadding: const EdgeInsets.all(24),
        border: OutlineInputBorder(borderRadius: BorderRadius.circular(20), borderSide: BorderSide(color: (isDark ? Colors.white : Colors.black).withOpacity(0.1))),
        enabledBorder: OutlineInputBorder(borderRadius: BorderRadius.circular(20), borderSide: BorderSide(color: (isDark ? Colors.white : Colors.black).withOpacity(0.1))),
        focusedBorder: OutlineInputBorder(borderRadius: BorderRadius.circular(20), borderSide: BorderSide(color: Theme.of(context).colorScheme.primary, width: 2)),
      ),
    );
  }
}

class _InfoItem extends StatelessWidget {
  final IconData icon;
  final String label;
  final String value;
  final String subValue;
  final VoidCallback onTap;

  const _InfoItem({required this.icon, required this.label, required this.value, required this.subValue, required this.onTap});

  @override
  Widget build(BuildContext context) {
    return InkWell(
      onTap: onTap,
      child: Row(
        children: [
          Container(
            width: 56, height: 56,
            decoration: BoxDecoration(
              color: Theme.of(context).colorScheme.onSurface,
              shape: BoxShape.circle,
            ),
            child: Icon(icon, color: Theme.of(context).colorScheme.surface, size: 24),
          ),
          const SizedBox(width: 20),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(label, style: GoogleFonts.montserrat(fontSize: 10, fontWeight: FontWeight.w900, color: Colors.grey, letterSpacing: 2)),
                const SizedBox(height: 4),
                Text(value, style: GoogleFonts.montserrat(fontSize: 16, fontWeight: FontWeight.w900)),
                Text(subValue, style: GoogleFonts.montserrat(fontSize: 12, color: Colors.grey, fontWeight: FontWeight.w500)),
              ],
            ),
          ),
        ],
      ),
    );
  }
}
