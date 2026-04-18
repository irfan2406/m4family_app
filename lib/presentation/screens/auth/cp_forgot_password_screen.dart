import 'package:dio/dio.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:lucide_icons/lucide_icons.dart';
import 'package:m4_mobile/presentation/providers/auth_provider.dart';

/// Mirrors web `app/auth/cp/forgot-password/page.tsx`: forgot → OTP → reset.
class CpForgotPasswordScreen extends ConsumerStatefulWidget {
  const CpForgotPasswordScreen({super.key});

  @override
  ConsumerState<CpForgotPasswordScreen> createState() => _CpForgotPasswordScreenState();
}

class _CpForgotPasswordScreenState extends ConsumerState<CpForgotPasswordScreen> {
  int _step = 0;
  final _emailController = TextEditingController();
  final _newPasswordController = TextEditingController();
  final _confirmPasswordController = TextEditingController();
  final List<TextEditingController> _otpControllers = List.generate(6, (_) => TextEditingController());
  final List<FocusNode> _otpFocus = List.generate(6, (_) => FocusNode());

  String? _devOtp;
  bool _loading = false;

  @override
  void dispose() {
    _emailController.dispose();
    _newPasswordController.dispose();
    _confirmPasswordController.dispose();
    for (final c in _otpControllers) {
      c.dispose();
    }
    for (final f in _otpFocus) {
      f.dispose();
    }
    super.dispose();
  }

  Future<void> _sendEmail() async {
    final email = _emailController.text.trim();
    if (email.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('Please enter your email address')));
      return;
    }
    setState(() => _loading = true);
    try {
      final api = ref.read(apiClientProvider);
      final res = await api.forgotPassword(email);
      if (!mounted) return;
      if (res.statusCode == 200 && res.data['status'] == true) {
        final dev = res.data['data']?['devOtp']?.toString();
        setState(() {
          _devOtp = dev;
          _step = 1;
        });
        ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('Security code sent!')));
        if (dev != null && dev.isNotEmpty) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(content: Text('DEV: recovery code $dev'), backgroundColor: Colors.amber.shade900),
          );
        }
      } else {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text(res.data['message']?.toString() ?? 'Failed')),
        );
      }
    } on DioException catch (e) {
      final msg = e.response?.data is Map ? e.response?.data['message']?.toString() : null;
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text(msg ?? 'User not found')));
      }
    } finally {
      if (mounted) setState(() => _loading = false);
    }
  }

  void _goPasswordStep() {
    final code = _otpControllers.map((c) => c.text).join();
    if (code.length != 6) {
      ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('Enter the complete 6-digit code')));
      return;
    }
    setState(() => _step = 2);
  }

  Future<void> _resetPassword() async {
    final np = _newPasswordController.text;
    final cp = _confirmPasswordController.text;
    if (np.isEmpty || cp.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('Please fill in all fields')));
      return;
    }
    if (np != cp) {
      ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('Passwords do not match')));
      return;
    }
    if (np.length < 8) {
      ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('Password must be at least 8 characters')));
      return;
    }
    final identifier = _emailController.text.trim();
    final token = _otpControllers.map((c) => c.text).join();
    setState(() => _loading = true);
    try {
      final api = ref.read(apiClientProvider);
      final res = await api.resetPassword(identifier: identifier, token: token, newPassword: np);
      if (!mounted) return;
      if (res.statusCode == 200 && res.data['status'] == true) {
        ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('Password updated. You can login.')));
        final fromGuest = GoRouterState.of(context).uri.queryParameters['from'] == 'guest';
        context.go('/auth/cp/login${fromGuest ? '?from=guest' : ''}');
      } else {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text(res.data['message']?.toString() ?? 'Reset failed')),
        );
      }
    } on DioException catch (e) {
      final msg = e.response?.data is Map ? e.response?.data['message']?.toString() : null;
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text(msg ?? 'Reset failed')));
      }
    } finally {
      if (mounted) setState(() => _loading = false);
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
              gradient: LinearGradient(colors: [Colors.black.withValues(alpha: 0.55), Colors.black.withValues(alpha: 0.88)]),
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
                      padding: const EdgeInsets.only(bottom: 8),
                      child: OutlinedButton(
                        onPressed: () => context.go('/home'),
                        child: Text(
                          'BACK TO GUEST PORTAL',
                          style: GoogleFonts.montserrat(fontSize: 10, fontWeight: FontWeight.bold, letterSpacing: 2),
                        ),
                      ),
                    ),
                  Row(
                    children: [
                      IconButton(
                        style: IconButton.styleFrom(backgroundColor: Colors.white.withValues(alpha: 0.1)),
                        onPressed: () {
                          if (_step == 0) {
                            context.go('/auth/cp/login${fromGuest ? '?from=guest' : ''}');
                          } else {
                            setState(() => _step = _step - 1);
                          }
                        },
                        icon: const Icon(LucideIcons.chevronLeft, color: Colors.white),
                      ),
                    ],
                  ),
                  const SizedBox(height: 16),
                  Text(
                    _step == 0
                        ? 'RECOVER ACCESS'
                        : _step == 1
                            ? 'VERIFY CODE'
                            : 'NEW PASSWORD',
                    style: GoogleFonts.montserrat(fontSize: 26, fontWeight: FontWeight.bold, color: Colors.white),
                  ),
                  const SizedBox(height: 24),
                  if (_step == 0) ...[
                    TextField(
                      controller: _emailController,
                      keyboardType: TextInputType.emailAddress,
                      style: const TextStyle(color: Colors.white),
                      decoration: InputDecoration(
                        labelText: 'Email',
                        labelStyle: const TextStyle(color: Colors.white54),
                        prefixIcon: const Icon(LucideIcons.mail, color: Colors.white54),
                        filled: true,
                        fillColor: Colors.black.withValues(alpha: 0.4),
                        border: OutlineInputBorder(borderRadius: BorderRadius.circular(14)),
                      ),
                    ),
                    const SizedBox(height: 24),
                    FilledButton(
                      onPressed: _loading ? null : _sendEmail,
                      style: FilledButton.styleFrom(
                        backgroundColor: Colors.purple.shade600,
                        minimumSize: const Size(double.infinity, 52),
                        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(14)),
                      ),
                      child: _loading
                          ? const SizedBox(
                              width: 22,
                              height: 22,
                              child: CircularProgressIndicator(strokeWidth: 2, color: Colors.white),
                            )
                          : const Text('SEND CODE'),
                    ),
                  ],
                  if (_step == 1) ...[
                    if (_devOtp != null && _devOtp!.isNotEmpty)
                      Container(
                        margin: const EdgeInsets.only(bottom: 16),
                        padding: const EdgeInsets.all(12),
                        decoration: BoxDecoration(
                          color: Colors.amber.withValues(alpha: 0.15),
                          borderRadius: BorderRadius.circular(12),
                          border: Border.all(color: Colors.amber.withValues(alpha: 0.4)),
                        ),
                        child: Text(
                          'DEV: code $_devOtp',
                          style: const TextStyle(color: Colors.amber, fontWeight: FontWeight.bold),
                        ),
                      ),
                    Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: List.generate(6, (i) {
                        return SizedBox(
                          width: 44,
                          child: TextField(
                            controller: _otpControllers[i],
                            focusNode: _otpFocus[i],
                            textAlign: TextAlign.center,
                            maxLength: 1,
                            keyboardType: TextInputType.number,
                            style: const TextStyle(color: Colors.white, fontSize: 20, fontWeight: FontWeight.bold),
                            decoration: InputDecoration(
                              counterText: '',
                              filled: true,
                              fillColor: Colors.white.withValues(alpha: 0.06),
                              border: OutlineInputBorder(borderRadius: BorderRadius.circular(10)),
                            ),
                            onChanged: (v) {
                              if (v.length == 1 && i < 5) _otpFocus[i + 1].requestFocus();
                              if (v.isEmpty && i > 0) _otpFocus[i - 1].requestFocus();
                            },
                          ),
                        );
                      }),
                    ),
                    const SizedBox(height: 24),
                    FilledButton(
                      onPressed: _goPasswordStep,
                      style: FilledButton.styleFrom(
                        backgroundColor: Colors.purple.shade600,
                        minimumSize: const Size(double.infinity, 52),
                        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(14)),
                      ),
                      child: const Text('CONTINUE'),
                    ),
                  ],
                  if (_step == 2) ...[
                    TextField(
                      controller: _newPasswordController,
                      obscureText: true,
                      style: const TextStyle(color: Colors.white),
                      decoration: InputDecoration(
                        labelText: 'New password',
                        labelStyle: const TextStyle(color: Colors.white54),
                        prefixIcon: const Icon(LucideIcons.lock, color: Colors.white54),
                        filled: true,
                        fillColor: Colors.black.withValues(alpha: 0.4),
                        border: OutlineInputBorder(borderRadius: BorderRadius.circular(14)),
                      ),
                    ),
                    const SizedBox(height: 12),
                    TextField(
                      controller: _confirmPasswordController,
                      obscureText: true,
                      style: const TextStyle(color: Colors.white),
                      decoration: InputDecoration(
                        labelText: 'Confirm password',
                        labelStyle: const TextStyle(color: Colors.white54),
                        prefixIcon: const Icon(LucideIcons.lock, color: Colors.white54),
                        filled: true,
                        fillColor: Colors.black.withValues(alpha: 0.4),
                        border: OutlineInputBorder(borderRadius: BorderRadius.circular(14)),
                      ),
                    ),
                    const SizedBox(height: 24),
                    FilledButton(
                      onPressed: _loading ? null : _resetPassword,
                      style: FilledButton.styleFrom(
                        backgroundColor: Colors.purple.shade600,
                        minimumSize: const Size(double.infinity, 52),
                        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(14)),
                      ),
                      child: _loading
                          ? const SizedBox(
                              width: 22,
                              height: 22,
                              child: CircularProgressIndicator(strokeWidth: 2, color: Colors.white),
                            )
                          : const Text('UPDATE PASSWORD'),
                    ),
                  ],
                  const SizedBox(height: 32),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }
}
