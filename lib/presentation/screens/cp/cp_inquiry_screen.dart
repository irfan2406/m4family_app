import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:lucide_icons/lucide_icons.dart';
import 'package:m4_mobile/presentation/providers/auth_provider.dart';
import 'package:m4_mobile/presentation/providers/cp_shell_provider.dart';
import 'package:m4_mobile/presentation/widgets/cp_bottom_nav.dart';

/// Web parity: the "Register Interest" form (web `/cp/home#interest-form`).
/// Full Name, Email, Phone, Message, a privacy-policy checkbox, and a black
/// "Submit Interest" button — white rounded card inputs like the web home
/// form. Submits a lead via `POST /api/leads`.
class CpInquiryScreen extends ConsumerStatefulWidget {
  const CpInquiryScreen({super.key});

  @override
  ConsumerState<CpInquiryScreen> createState() => _CpInquiryScreenState();
}

class _CpInquiryScreenState extends ConsumerState<CpInquiryScreen> {
  final _formKey = GlobalKey<FormState>();
  final _name = TextEditingController();
  final _email = TextEditingController();
  final _phone = TextEditingController();
  final _message = TextEditingController();
  bool _agreedToTerms = false;
  bool _submitting = false;

  @override
  void dispose() {
    _name.dispose();
    _email.dispose();
    _phone.dispose();
    _message.dispose();
    super.dispose();
  }

  void _validationToast(String msg) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(content: Text(msg), backgroundColor: Colors.red.shade700),
    );
  }

  // Inline field validators (shown as red text under each field).
  String? _validateName(String? v) {
    final s = (v ?? '').trim();
    if (s.isEmpty) return 'Full name is required';
    if (s.length < 2) return 'Please enter a valid name';
    return null;
  }

  String? _validateEmail(String? v) {
    final s = (v ?? '').trim();
    if (s.isEmpty) return 'Email is required';
    if (!RegExp(r'^[\w.+-]+@[\w-]+\.[\w.-]+$').hasMatch(s)) {
      return 'Enter a valid email address';
    }
    return null;
  }

  String? _validatePhone(String? v) {
    final s = (v ?? '').trim();
    if (s.isEmpty) return 'Phone number is required';
    if (s.replaceAll(RegExp(r'\D'), '').length < 10) {
      return 'Enter a valid 10-digit phone number';
    }
    return null;
  }

  Future<void> _submit() async {
    final name = _name.text.trim();
    final email = _email.text.trim();
    final phone = _phone.text.trim();

    // Run all field validators (shows inline red errors).
    if (!(_formKey.currentState?.validate() ?? false)) {
      _validationToast('Please fix the highlighted fields');
      return;
    }
    if (!_agreedToTerms) {
      _validationToast('Please agree to the Privacy Policy');
      return;
    }
    setState(() => _submitting = true);
    try {
      final res = await ref.read(apiClientProvider).submitLead({
        'name': name,
        'email': email,
        'phone': phone,
        'interest': 'Channel Partner Interest',
        'source': 'cp inquiry',
        'notes': _message.text.trim(),
      });
      if (!mounted) return;
      final ok =
          (res.statusCode == 200 || res.statusCode == 201) &&
          res.data is Map &&
          res.data['status'] == true;
      if (ok) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Interest registered successfully!')),
        );
        context.pop();
      } else {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(
              (res.data is Map ? res.data['message']?.toString() : null) ??
                  'Failed to submit',
            ),
          ),
        );
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(
          context,
        ).showSnackBar(SnackBar(content: Text('$e')));
      }
    } finally {
      if (mounted) setState(() => _submitting = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;

    return Scaffold(
      backgroundColor: Theme.of(context).scaffoldBackgroundColor,
      extendBody: true,
      bottomNavigationBar: CpBottomNav(
        currentIndex: -1,
        onTap: (i) {
          ref.read(cpNavigationIndexProvider.notifier).state = i;
          if (context.canPop()) context.pop();
        },
      ),
      body: SafeArea(
        child: SingleChildScrollView(
          padding: const EdgeInsets.fromLTRB(24, 12, 24, 48),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // Back button
              GestureDetector(
                onTap: () => context.pop(),
                child: Container(
                  width: 40,
                  height: 40,
                  alignment: Alignment.center,
                  decoration: BoxDecoration(
                    color: (isDark ? Colors.white : Colors.black).withValues(
                      alpha: 0.05,
                    ),
                    shape: BoxShape.circle,
                    border: Border.all(
                      color: (isDark ? Colors.white : Colors.black).withValues(
                        alpha: 0.1,
                      ),
                    ),
                  ),
                  child: Icon(
                    LucideIcons.arrowLeft,
                    size: 18,
                    color: isDark ? Colors.white : Colors.black,
                  ),
                ),
              ),
              const SizedBox(height: 24),
              // Web parity: "REGISTER INTEREST" serif heading.
              Text(
                'REGISTER\nINTEREST',
                style: GoogleFonts.dmSerifDisplay(
                  color: isDark ? Colors.white : Colors.black,
                  fontSize: 34,
                  fontWeight: FontWeight.w400,
                  letterSpacing: -0.5,
                  height: 1.1,
                ),
              ),
              const SizedBox(height: 40),
              Form(
                key: _formKey,
                autovalidateMode: AutovalidateMode.onUserInteraction,
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    _luxuryInput(
                      'Full Name *',
                      _name,
                      validator: _validateName,
                    ),
                    const SizedBox(height: 16),
                    _luxuryInput(
                      'Email *',
                      _email,
                      keyboardType: TextInputType.emailAddress,
                      validator: _validateEmail,
                    ),
                    const SizedBox(height: 16),
                    _luxuryInput(
                      '+91 98653 21250 *',
                      _phone,
                      keyboardType: TextInputType.phone,
                      validator: _validatePhone,
                    ),
                    const SizedBox(height: 16),
                    _luxuryInput('Message', _message, isLong: true),
                  ],
                ),
              ),
              const SizedBox(height: 24),
              Row(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Checkbox(
                    value: _agreedToTerms,
                    onChanged: (val) =>
                        setState(() => _agreedToTerms = val ?? false),
                    activeColor: isDark ? Colors.white : Colors.black,
                    checkColor: isDark ? Colors.black : Colors.white,
                    side: BorderSide(
                      color: isDark ? Colors.white24 : Colors.black26,
                    ),
                  ),
                  Expanded(
                    child: Padding(
                      padding: const EdgeInsets.only(top: 12),
                      child: RichText(
                        text: TextSpan(
                          style: GoogleFonts.montserrat(
                            color: isDark ? Colors.white54 : Colors.black54,
                            fontSize: 11,
                            fontWeight: FontWeight.w700,
                            letterSpacing: 0.8,
                          ),
                          children: [
                            const TextSpan(text: "I'VE READ AND AGREE TO THE "),
                            TextSpan(
                              text: 'PRIVACY POLICY',
                              style: GoogleFonts.montserrat(
                                color: isDark ? Colors.white : Colors.black,
                                fontSize: 11,
                                fontWeight: FontWeight.w900,
                                letterSpacing: 0.8,
                                decoration: TextDecoration.underline,
                              ),
                            ),
                            const TextSpan(text: '.'),
                          ],
                        ),
                      ),
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 28),
              SizedBox(
                width: double.infinity,
                height: 64,
                child: ElevatedButton(
                  onPressed: _submitting ? null : _submit,
                  style: ElevatedButton.styleFrom(
                    backgroundColor: isDark ? Colors.white : Colors.black,
                    foregroundColor: isDark ? Colors.black : Colors.white,
                    elevation: 0,
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(16),
                    ),
                  ),
                  child: _submitting
                      ? SizedBox(
                          width: 22,
                          height: 22,
                          child: CircularProgressIndicator(
                            strokeWidth: 2,
                            color: isDark ? Colors.black : Colors.white,
                          ),
                        )
                      : Text(
                          'SUBMIT INTEREST',
                          style: GoogleFonts.montserrat(
                            fontWeight: FontWeight.w800,
                            fontSize: 13,
                            letterSpacing: 2,
                          ),
                        ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  // Web parity: white rounded card input with soft shadow, label as hint.
  Widget _luxuryInput(
    String label,
    TextEditingController controller, {
    bool isLong = false,
    TextInputType? keyboardType,
    String? Function(String?)? validator,
  }) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    return Container(
      decoration: BoxDecoration(
        color: isDark ? Colors.black : Colors.white,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(
          color: (isDark ? Colors.white : Colors.black).withValues(alpha: 0.12),
        ),
        boxShadow: isDark
            ? null
            : [
                BoxShadow(
                  color: Colors.black.withValues(alpha: 0.05),
                  blurRadius: 20,
                  offset: const Offset(0, 10),
                ),
              ],
      ),
      child: TextFormField(
        controller: controller,
        keyboardType: keyboardType,
        maxLines: isLong ? 5 : 1,
        validator: validator,
        style: TextStyle(color: isDark ? Colors.white : Colors.black),
        decoration: InputDecoration(
          hintText: label,
          hintStyle: GoogleFonts.montserrat(
            color: isDark ? Colors.white54 : Colors.black45,
            fontSize: 13,
          ),
          errorStyle: GoogleFonts.montserrat(
            color: Colors.redAccent,
            fontSize: 11,
            fontWeight: FontWeight.w600,
          ),
          contentPadding: const EdgeInsets.symmetric(
            horizontal: 24,
            vertical: 20,
          ),
          border: InputBorder.none,
        ),
      ),
    );
  }
}
