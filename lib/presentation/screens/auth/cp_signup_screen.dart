import 'package:dio/dio.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:lucide_icons/lucide_icons.dart';
import 'package:m4_mobile/presentation/providers/auth_provider.dart';

/// Mirrors web `app/auth/cp/signup/page.tsx`: `POST /auth/register` with `role: CP` and CP fields.
class CpSignupScreen extends ConsumerStatefulWidget {
  const CpSignupScreen({super.key});

  @override
  ConsumerState<CpSignupScreen> createState() => _CpSignupScreenState();
}

class _CpSignupScreenState extends ConsumerState<CpSignupScreen> {
  final _fullName = TextEditingController();
  final _companyName = TextEditingController();
  final _email = TextEditingController();
  final _phone = TextEditingController();
  final _reraNumber = TextEditingController();
  final _reraId = TextEditingController();
  final _cpId = TextEditingController();
  final _password = TextEditingController();
  final _confirmPassword = TextEditingController();

  bool _submitting = false;

  @override
  void dispose() {
    _fullName.dispose();
    _companyName.dispose();
    _email.dispose();
    _phone.dispose();
    _reraNumber.dispose();
    _reraId.dispose();
    _cpId.dispose();
    _password.dispose();
    _confirmPassword.dispose();
    super.dispose();
  }

  Future<void> _submit() async {
    final fn = _fullName.text.trim();
    final parts = fn.split(RegExp(r'\s+'));
    final firstName = parts.isNotEmpty ? parts.first : '';
    final lastName = parts.length > 1 ? parts.sublist(1).join(' ') : '';

    if (fn.isEmpty ||
        _companyName.text.trim().isEmpty ||
        _email.text.trim().isEmpty ||
        _phone.text.trim().isEmpty ||
        _reraNumber.text.trim().isEmpty ||
        _reraId.text.trim().isEmpty ||
        _cpId.text.trim().isEmpty ||
        _password.text.isEmpty ||
        _confirmPassword.text.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Please fill in all required fields')),
      );
      return;
    }
    if (_password.text != _confirmPassword.text) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Passwords do not match')),
      );
      return;
    }

    setState(() => _submitting = true);
    try {
      final api = ref.read(apiClientProvider);
      final res = await api.register({
        'phone': _phone.text.trim(),
        'email': _email.text.trim(),
        'password': _password.text,
        'role': 'CP',
        'firstName': firstName,
        'lastName': lastName,
        'companyName': _companyName.text.trim(),
        'reraNumber': _reraNumber.text.trim(),
        'reraId': _reraId.text.trim(),
        'cpId': _cpId.text.trim(),
      });
      if (!mounted) return;
      if (res.statusCode == 201 && res.data['status'] == true) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Registration successful! Please login.')),
        );
        final fromGuest = GoRouterState.of(context).uri.queryParameters['from'] == 'guest';
        context.go('/auth/cp/login${fromGuest ? '?from=guest' : ''}');
      } else {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text(res.data['message']?.toString() ?? 'Registration failed')),
        );
      }
    } on DioException catch (e) {
      final msg = e.response?.data is Map ? (e.response?.data['message']?.toString()) : null;
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text(msg ?? e.message ?? 'Registration failed')),
        );
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text(e.toString())));
      }
    } finally {
      if (mounted) setState(() => _submitting = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    final fromGuest = GoRouterState.of(context).uri.queryParameters['from'] == 'guest';

    return Scaffold(
      backgroundColor: Colors.black,
      body: Stack(
        fit: StackFit.expand,
        children: [
          Positioned.fill(child: Image.asset('assets/login-bg.png', fit: BoxFit.cover)),
          Container(
            decoration: BoxDecoration(
              gradient: LinearGradient(
                colors: [Colors.black.withValues(alpha: 0.55), Colors.black.withValues(alpha: 0.85)],
              ),
            ),
          ),
          SafeArea(
            child: SingleChildScrollView(
              padding: const EdgeInsets.symmetric(horizontal: 24),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.stretch,
                children: [
                  if (fromGuest)
                    Padding(
                      padding: const EdgeInsets.only(bottom: 12),
                      child: OutlinedButton(
                        onPressed: () => context.go('/home'),
                        child: Text(
                          'BACK TO GUEST PORTAL',
                          style: GoogleFonts.montserrat(fontSize: 10, fontWeight: FontWeight.bold, letterSpacing: 2),
                        ),
                      ),
                    ),
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      IconButton(
                        style: IconButton.styleFrom(backgroundColor: Colors.white.withValues(alpha: 0.1)),
                        onPressed: () => context.go('/auth/cp/login${fromGuest ? '?from=guest' : ''}'),
                        icon: const Icon(LucideIcons.chevronLeft, color: Colors.white),
                      ),
                      Container(
                        padding: const EdgeInsets.all(12),
                        decoration: BoxDecoration(
                          color: Colors.purple.withValues(alpha: 0.2),
                          borderRadius: BorderRadius.circular(14),
                          border: Border.all(color: Colors.purple.withValues(alpha: 0.35)),
                        ),
                        child: const Icon(LucideIcons.sparkles, color: Colors.purpleAccent, size: 26),
                      ),
                    ],
                  ),
                  const SizedBox(height: 20),
                  Text(
                    'PARTNER REGISTRATION',
                    style: GoogleFonts.montserrat(
                      fontSize: 28,
                      fontWeight: FontWeight.bold,
                      color: Colors.white,
                    ),
                  ),
                  const SizedBox(height: 8),
                  Text(
                    'JOIN M4 FAMILY CHANNEL PARTNER NETWORK',
                    style: GoogleFonts.montserrat(
                      fontSize: 10,
                      color: Colors.white54,
                      letterSpacing: 2,
                    ),
                  ),
                  const SizedBox(height: 28),
                  _section('PERSONAL INFORMATION'),
                  _CpField(label: 'FULL NAME *', controller: _fullName, icon: LucideIcons.user, hint: 'John Doe'),
                  _CpField(label: 'COMPANY NAME *', controller: _companyName, icon: LucideIcons.building2),
                  _CpField(label: 'EMAIL *', controller: _email, icon: LucideIcons.mail, keyboard: TextInputType.emailAddress),
                  _CpField(label: 'PHONE *', controller: _phone, icon: LucideIcons.phone, keyboard: TextInputType.phone),
                  const SizedBox(height: 16),
                  _section('RERA CREDENTIALS'),
                  _CpField(label: 'RERA NUMBER *', controller: _reraNumber, icon: LucideIcons.fileText),
                  _CpField(label: 'RERA ID *', controller: _reraId, icon: LucideIcons.fileText),
                  const SizedBox(height: 16),
                  _section('ACCOUNT SETUP'),
                  _CpField(label: 'CHANNEL PARTNER ID *', controller: _cpId, icon: LucideIcons.sparkles, hint: 'CP-XXXXX'),
                  _CpField(label: 'PASSWORD *', controller: _password, icon: LucideIcons.lock, obscure: true),
                  _CpField(label: 'CONFIRM PASSWORD *', controller: _confirmPassword, icon: LucideIcons.lock, obscure: true),
                  const SizedBox(height: 28),
                  SizedBox(
                    height: 56,
                    child: FilledButton(
                      onPressed: _submitting ? null : _submit,
                      style: FilledButton.styleFrom(
                        backgroundColor: Colors.purple.shade600,
                        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
                      ),
                      child: _submitting
                          ? const SizedBox(
                              width: 22,
                              height: 22,
                              child: CircularProgressIndicator(strokeWidth: 2, color: Colors.white),
                            )
                          : Text(
                              'COMPLETE REGISTRATION',
                              style: GoogleFonts.montserrat(fontWeight: FontWeight.bold, letterSpacing: 2),
                            ),
                    ),
                  ),
                  TextButton(
                    onPressed: () => context.go('/auth/cp/login${fromGuest ? '?from=guest' : ''}'),
                    child: Text(
                      'ALREADY HAVE AN ACCOUNT? LOGIN',
                      style: GoogleFonts.montserrat(fontSize: 10, fontWeight: FontWeight.bold, color: Colors.white54, letterSpacing: 2),
                    ),
                  ),
                  const SizedBox(height: 24),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _section(String t) => Padding(
        padding: const EdgeInsets.only(bottom: 12),
        child: Text(
          t,
          style: GoogleFonts.montserrat(
            fontSize: 10,
            fontWeight: FontWeight.bold,
            color: Colors.purpleAccent.withValues(alpha: 0.7),
            letterSpacing: 2,
          ),
        ),
      );
}

class _CpField extends StatelessWidget {
  final String label;
  final TextEditingController controller;
  final IconData icon;
  final String? hint;
  final bool obscure;
  final TextInputType? keyboard;

  const _CpField({
    required this.label,
    required this.controller,
    required this.icon,
    this.hint,
    this.obscure = false,
    this.keyboard,
  });

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 14),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            label,
            style: GoogleFonts.montserrat(fontSize: 9, fontWeight: FontWeight.bold, color: Colors.white54, letterSpacing: 2),
          ),
          const SizedBox(height: 6),
          TextField(
            controller: controller,
            obscureText: obscure,
            keyboardType: keyboard,
            style: const TextStyle(color: Colors.white, fontWeight: FontWeight.w600, fontSize: 14),
            decoration: InputDecoration(
              hintText: hint,
              hintStyle: TextStyle(color: Colors.white.withValues(alpha: 0.35)),
              prefixIcon: Icon(icon, color: Colors.white54, size: 20),
              filled: true,
              fillColor: Colors.black.withValues(alpha: 0.4),
              border: OutlineInputBorder(borderRadius: BorderRadius.circular(14)),
              enabledBorder: OutlineInputBorder(
                borderRadius: BorderRadius.circular(14),
                borderSide: BorderSide(color: Colors.white.withValues(alpha: 0.12)),
              ),
            ),
          ),
        ],
      ),
    );
  }
}
