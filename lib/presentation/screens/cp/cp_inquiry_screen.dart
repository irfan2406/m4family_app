import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:m4_mobile/core/utils/validators.dart';
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
  String? _validateName(String? v) =>
      Validators.nameError(v, field: 'full name');

  String? _validateEmail(String? v) => Validators.emailError(v);

  String? _validatePhone(String? v) => Validators.phoneError(v);

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
        // Server-side enums: interest = Buying | Selling | Site Visit | Video
        // Call (case-sensitive); source = online | cp | walk-in | referral |
        // other. Anything else is rejected with a 400.
        'interest': 'Buying',
        'source': 'cp',
        'notes': _message.text.trim(),
      });
      if (!mounted) return;
      final ok =
          (res.statusCode == 200 || res.statusCode == 201) &&
          res.data is Map &&
          res.data['status'] == true;
      if (ok) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            backgroundColor: Color(0xFF163A2C),
            content: Text('Interest registered successfully!'),
          ),
        );
        context.pop();
      } else {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            backgroundColor: const Color(0xFFC65B46),
            content: Text(
              (res.data is Map ? res.data['message']?.toString() : null) ??
                  'Failed to submit',
            ),
          ),
        );
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            backgroundColor: const Color(0xFFC65B46),
            content: Text('$e'),
          ),
        );
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
        // Edge-to-edge: content runs under the gesture bar so scrolling fills
        // the screen. Trailing padding keeps the last item reachable.
        bottom: false,
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
                    color: (isDark ? Colors.white : Color(0xFF0C312B))
                        .withValues(alpha: 0.05),
                    shape: BoxShape.circle,
                    border: Border.all(
                      color: (isDark ? Colors.white : Color(0xFF0C312B))
                          .withValues(alpha: 0.1),
                    ),
                  ),
                  child: Icon(
                    LucideIcons.arrowLeft,
                    size: 18,
                    color: isDark ? Colors.white : Color(0xFF0C312B),
                  ),
                ),
              ),
              const SizedBox(height: 24),
              // Web parity: "REGISTER INTEREST" serif heading.
              Text(
                'REGISTER\nINTEREST',
                style: GoogleFonts.gelasio(
                  color: isDark ? Colors.white : Color(0xFF0C312B),
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
                      keyboardType: TextInputType.name,
                      inputFormatters: Validators.nameFormatters,
                      validator: _validateName,
                    ),
                    const SizedBox(height: 16),
                    _luxuryInput(
                      'Email *',
                      _email,
                      keyboardType: TextInputType.emailAddress,
                      inputFormatters: Validators.emailFormatters,
                      validator: _validateEmail,
                    ),
                    const SizedBox(height: 16),
                    _luxuryInput(
                      '+91 98653 21250 *',
                      _phone,
                      keyboardType: TextInputType.phone,
                      inputFormatters: Validators.phoneFormatters,
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
                    activeColor: isDark ? Colors.white : Color(0xFF0C312B),
                    checkColor: isDark ? Colors.black : const Color(0xFFF4EFE3),
                    side: BorderSide(
                      color: isDark ? Colors.white24 : Colors.black26,
                    ),
                  ),
                  Expanded(
                    child: Padding(
                      padding: const EdgeInsets.only(top: 12),
                      child: RichText(
                        text: TextSpan(
                          style: GoogleFonts.inter(
                            color: isDark ? Colors.white54 : Color(0xFF155A4F),
                            fontSize: 11,
                            fontWeight: FontWeight.w700,
                            letterSpacing: 0.8,
                          ),
                          children: [
                            const TextSpan(text: "I'VE READ AND AGREE TO THE "),
                            TextSpan(
                              text: 'PRIVACY POLICY',
                              style: GoogleFonts.inter(
                                color: isDark
                                    ? Colors.white
                                    : Color(0xFF155A4F),
                                fontSize: 11,
                                fontWeight: FontWeight.w600,
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
                    backgroundColor: isDark ? Colors.white : Color(0xFF0C312B),
                    foregroundColor: isDark
                        ? Colors.black
                        : const Color(0xFFF4EFE3),
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
                            color: isDark
                                ? Colors.black
                                : const Color(0xFFF4EFE3),
                          ),
                        )
                      : Text(
                          'SUBMIT INTEREST',
                          style: GoogleFonts.gelasio(
                            fontWeight: FontWeight.w700,
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
    List<TextInputFormatter>? inputFormatters,
    String? Function(String?)? validator,
  }) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    return Container(
      decoration: BoxDecoration(
        color: isDark ? Colors.black : const Color(0xFFF4EFE3),
        borderRadius: BorderRadius.circular(16),
        border: Border.all(
          color: (isDark ? Colors.white : Color(0xFF0C312B)).withValues(
            alpha: 0.12,
          ),
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
        inputFormatters: inputFormatters,
        maxLines: isLong ? 5 : 1,
        validator: validator,
        style: TextStyle(color: isDark ? Colors.white : Color(0xFF0C312B)),
        decoration: InputDecoration(
          hintText: label,
          hintStyle: GoogleFonts.inter(
            color: isDark ? Colors.white54 : Color(0x730C312B),
            fontSize: 13,
          ),
          errorStyle: GoogleFonts.inter(
            color: Colors.redAccent,
            fontSize: 11,
            fontWeight: FontWeight.w600,
          ),
          contentPadding: const EdgeInsets.symmetric(
            horizontal: 24,
            vertical: 20,
          ),
          filled: false,
          border: InputBorder.none,
          enabledBorder: InputBorder.none,
          focusedBorder: InputBorder.none,
        ),
      ),
    );
  }
}
