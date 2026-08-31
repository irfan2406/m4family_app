import 'package:dio/dio.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:lucide_icons/lucide_icons.dart';
import 'package:m4_mobile/core/utils/validators.dart';
import 'package:m4_mobile/presentation/providers/auth_provider.dart';

/// Mirrors web `app/auth/cp/forgot-password/page.tsx`: forgot → OTP → reset.
class CpForgotPasswordScreen extends ConsumerStatefulWidget {
  const CpForgotPasswordScreen({super.key});

  @override
  ConsumerState<CpForgotPasswordScreen> createState() =>
      _CpForgotPasswordScreenState();
}

class _CpForgotPasswordScreenState
    extends ConsumerState<CpForgotPasswordScreen> {
  int _step = 0;
  final _emailController = TextEditingController();
  final _newPasswordController = TextEditingController();
  final _confirmPasswordController = TextEditingController();
  final List<TextEditingController> _otpControllers = List.generate(
    6,
    (_) => TextEditingController(),
  );
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
    final emailErr = Validators.emailError(email);
    if (emailErr != null) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          backgroundColor: const Color(0xFFC65B46),
          content: Text(emailErr),
        ),
      );
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
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            backgroundColor: Color(0xFF163A2C),
            content: Text('Security code sent!'),
          ),
        );
        if (dev != null && dev.isNotEmpty) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
              content: Text('DEV: recovery code $dev'),
              backgroundColor: const Color(0xFFC65B46),
            ),
          );
        }
      } else {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            backgroundColor: const Color(0xFFC65B46),
            content: Text(res.data['message']?.toString() ?? 'Failed'),
          ),
        );
      }
    } on DioException catch (e) {
      final msg = e.response?.data is Map
          ? e.response?.data['message']?.toString()
          : null;
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            backgroundColor: const Color(0xFFC65B46),
            content: Text(msg ?? 'User not found'),
          ),
        );
      }
    } finally {
      if (mounted) setState(() => _loading = false);
    }
  }

  void _goPasswordStep() {
    final code = _otpControllers.map((c) => c.text).join();
    if (code.length != 6) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          backgroundColor: Color(0xFFC65B46),
          content: Text('Enter the complete 6-digit code'),
        ),
      );
      return;
    }
    setState(() => _step = 2);
  }

  Future<void> _resetPassword() async {
    final np = _newPasswordController.text;
    final cp = _confirmPasswordController.text;
    if (np.isEmpty || cp.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          backgroundColor: Color(0xFFC65B46),
          content: Text('Please fill in all fields'),
        ),
      );
      return;
    }
    if (np != cp) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          backgroundColor: Color(0xFFC65B46),
          content: Text('Passwords do not match'),
        ),
      );
      return;
    }
    if (np.length < 8) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          backgroundColor: Color(0xFFC65B46),
          content: Text('Password must be at least 8 characters'),
        ),
      );
      return;
    }
    final identifier = _emailController.text.trim();
    final token = _otpControllers.map((c) => c.text).join();
    setState(() => _loading = true);
    try {
      final api = ref.read(apiClientProvider);
      final res = await api.resetPassword(
        identifier: identifier,
        token: token,
        newPassword: np,
      );
      if (!mounted) return;
      if (res.statusCode == 200 && res.data['status'] == true) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            backgroundColor: Color(0xFF163A2C),
            content: Text('Password updated. You can login.'),
          ),
        );
        final fromGuest =
            GoRouterState.of(context).uri.queryParameters['from'] == 'guest';
        context.go('/auth/cp/login${fromGuest ? '?from=guest' : ''}');
      } else {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            backgroundColor: const Color(0xFFC65B46),
            content: Text(res.data['message']?.toString() ?? 'Reset failed'),
          ),
        );
      }
    } on DioException catch (e) {
      final msg = e.response?.data is Map
          ? e.response?.data['message']?.toString()
          : null;
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            backgroundColor: const Color(0xFFC65B46),
            content: Text(msg ?? 'Reset failed'),
          ),
        );
      }
    } finally {
      if (mounted) setState(() => _loading = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    final fromGuest =
        GoRouterState.of(context).uri.queryParameters['from'] == 'guest';

    return Scaffold(
      backgroundColor: const Color(0xFF0C312B),
      body: Stack(
        fit: StackFit.expand,
        children: [
          // Solid M4 forest green, exactly as the CP login screen paints it.
          // The photo sat outside the palette and left the "BACK TO GUEST
          // PORTAL" pill unreadable against it.
          const Positioned.fill(child: ColoredBox(color: Color(0xFF0C312B))),
          SafeArea(
            // Edge-to-edge: content runs under the gesture bar so scrolling fills
            // the screen. Trailing padding keeps the last item reachable.
            bottom: false,
            child: Padding(
              padding: const EdgeInsets.symmetric(horizontal: 24),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.stretch,
                children: [
                  if (fromGuest)
                    Padding(
                      padding: const EdgeInsets.only(bottom: 8),
                      // Matches the CP login pill: faint cream fill + hairline
                      // border. The themed OutlinedButton painted dark green
                      // text on the dark background, so it was invisible.
                      child: GestureDetector(
                        onTap: () => context.go('/home'),
                        child: Container(
                          padding: const EdgeInsets.symmetric(vertical: 16),
                          decoration: BoxDecoration(
                            color: const Color(
                              0xFFF4EFE3,
                            ).withValues(alpha: 0.05),
                            borderRadius: BorderRadius.circular(16),
                            border: Border.all(
                              color: const Color(
                                0xFFF4EFE3,
                              ).withValues(alpha: 0.12),
                            ),
                          ),
                          child: Row(
                            mainAxisAlignment: MainAxisAlignment.center,
                            children: [
                              Icon(
                                LucideIcons.chevronLeft,
                                color: const Color(
                                  0xFFF4EFE3,
                                ).withValues(alpha: 0.6),
                                size: 15,
                              ),
                              const SizedBox(width: 10),
                              Text(
                                'BACK TO GUEST PORTAL',
                                style: GoogleFonts.inter(
                                  color: const Color(
                                    0xFFF4EFE3,
                                  ).withValues(alpha: 0.6),
                                  fontWeight: FontWeight.w700,
                                  fontSize: 11,
                                  letterSpacing: 2,
                                ),
                              ),
                            ],
                          ),
                        ),
                      ),
                    ),
                  Row(
                    children: [
                      IconButton(
                        style: IconButton.styleFrom(
                          backgroundColor: const Color(
                            0xFFF4EFE3,
                          ).withValues(alpha: 0.08),
                        ),
                        onPressed: () {
                          if (_step == 0) {
                            context.go(
                              '/auth/cp/login${fromGuest ? '?from=guest' : ''}',
                            );
                          } else {
                            setState(() => _step = _step - 1);
                          }
                        },
                        icon: const Icon(
                          LucideIcons.chevronLeft,
                          color: Color(0xFFF4EFE3),
                        ),
                      ),
                    ],
                  ),
                  // The form sits in the middle of the space under the header
                  // instead of stacking at the top with a screenful of empty
                  // green beneath it. LayoutBuilder + a minHeight equal to the
                  // viewport keeps it centred while still allowing a scroll
                  // once the keyboard claims the room.
                  Expanded(
                    child: LayoutBuilder(
                      builder: (context, viewport) => SingleChildScrollView(
                        child: ConstrainedBox(
                          constraints: BoxConstraints(
                            minHeight: viewport.maxHeight,
                          ),
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.stretch,
                            children: [
                              const SizedBox(height: 20),
                              Text(
                                _step == 0
                                    ? 'RESET ACCESS'
                                    : _step == 1
                                    ? 'VERIFY CODE'
                                    : 'NEW PASSWORD',
                                style: GoogleFonts.gelasio(
                                  fontSize: 30,
                                  fontWeight: FontWeight.bold,
                                  color: const Color(0xFFF4EFE3),
                                ),
                              ),
                              const SizedBox(height: 8),
                              Text(
                                'RECOVER YOUR PARTNER ACCOUNT',
                                style: GoogleFonts.inter(
                                  fontSize: 11,
                                  fontWeight: FontWeight.w600,
                                  letterSpacing: 2,
                                  color: const Color(
                                    0xFFF4EFE3,
                                  ).withValues(alpha: 0.55),
                                ),
                              ),
                              const SizedBox(height: 36),
                              if (_step == 0) ...[
                                Text(
                                  'REGISTERED EMAIL',
                                  style: GoogleFonts.inter(
                                    fontSize: 10,
                                    fontWeight: FontWeight.w700,
                                    letterSpacing: 2,
                                    color: const Color(
                                      0xFFF4EFE3,
                                    ).withValues(alpha: 0.55),
                                  ),
                                ),
                                const SizedBox(height: 10),
                                TextField(
                                  controller: _emailController,
                                  keyboardType: TextInputType.emailAddress,
                                  inputFormatters: Validators.emailFormatters,
                                  style: const TextStyle(
                                    color: Color(0xFFF4EFE3),
                                  ),
                                  decoration: InputDecoration(
                                    // Placeholder wording left exactly as it
                                    // was; it is a hint now rather than a
                                    // floating label because the field has its
                                    // own "REGISTERED EMAIL" label above it.
                                    hintText: 'Enter Email Address',
                                    hintStyle: TextStyle(
                                      color: const Color(
                                        0xFFF4EFE3,
                                      ).withValues(alpha: 0.5),
                                      fontSize: 13,
                                    ),
                                    contentPadding: const EdgeInsets.symmetric(
                                      horizontal: 20,
                                      vertical: 20,
                                    ),
                                    filled: true,
                                    fillColor: const Color(
                                      0xFFF4EFE3,
                                    ).withValues(alpha: 0.06),
                                    border: OutlineInputBorder(
                                      borderRadius: BorderRadius.circular(14),
                                      borderSide: BorderSide(
                                        color: const Color(
                                          0xFFF4EFE3,
                                        ).withValues(alpha: 0.18),
                                      ),
                                    ),
                                    enabledBorder: OutlineInputBorder(
                                      borderRadius: BorderRadius.circular(14),
                                      borderSide: BorderSide(
                                        color: const Color(
                                          0xFFF4EFE3,
                                        ).withValues(alpha: 0.18),
                                      ),
                                    ),
                                    focusedBorder: OutlineInputBorder(
                                      borderRadius: BorderRadius.circular(14),
                                      borderSide: BorderSide(
                                        color: const Color(
                                          0xFFF4EFE3,
                                        ).withValues(alpha: 0.45),
                                      ),
                                    ),
                                  ),
                                ),
                                const SizedBox(height: 14),
                                Text(
                                  'A secure verification code will be sent to this email address to reset your password.',
                                  style: GoogleFonts.inter(
                                    fontSize: 11.5,
                                    height: 1.5,
                                    color: const Color(
                                      0xFFF4EFE3,
                                    ).withValues(alpha: 0.55),
                                  ),
                                ),
                                const SizedBox(height: 28),
                                FilledButton(
                                  onPressed: _loading ? null : _sendEmail,
                                  style: FilledButton.styleFrom(
                                    backgroundColor: const Color(0xFFF4EFE3),
                                    foregroundColor: const Color(0xFF0C312B),
                                    minimumSize: const Size(
                                      double.infinity,
                                      60,
                                    ),
                                    padding: const EdgeInsets.symmetric(
                                      horizontal: 24,
                                    ),
                                    shape: RoundedRectangleBorder(
                                      borderRadius: BorderRadius.circular(18),
                                    ),
                                  ),
                                  child: _loading
                                      ? const SizedBox(
                                          width: 22,
                                          height: 22,
                                          child: CircularProgressIndicator(
                                            strokeWidth: 2,
                                            color: Color(0xFF0C312B),
                                          ),
                                        )
                                      : Row(
                                          mainAxisAlignment:
                                              MainAxisAlignment.spaceBetween,
                                          children: [
                                            Text(
                                              'SEND RESET CODE',
                                              style: GoogleFonts.inter(
                                                fontSize: 13,
                                                fontWeight: FontWeight.w700,
                                                letterSpacing: 1.5,
                                                color: const Color(0xFF0C312B),
                                              ),
                                            ),
                                            Container(
                                              padding: const EdgeInsets.all(7),
                                              decoration: BoxDecoration(
                                                color: const Color(
                                                  0xFF0C312B,
                                                ).withValues(alpha: 0.12),
                                                shape: BoxShape.circle,
                                              ),
                                              child: const Icon(
                                                LucideIcons.arrowRight,
                                                size: 16,
                                                color: Color(0xFF0C312B),
                                              ),
                                            ),
                                          ],
                                        ),
                                ),
                              ],
                              if (_step == 1) ...[
                                if (_devOtp != null && _devOtp!.isNotEmpty)
                                  Container(
                                    margin: const EdgeInsets.only(bottom: 16),
                                    padding: const EdgeInsets.all(12),
                                    decoration: BoxDecoration(
                                      color: const Color(
                                        0xFFF4EFE3,
                                      ).withValues(alpha: 0.10),
                                      borderRadius: BorderRadius.circular(12),
                                      border: Border.all(
                                        color: const Color(
                                          0xFFF4EFE3,
                                        ).withValues(alpha: 0.3),
                                      ),
                                    ),
                                    child: Text(
                                      'DEV: code $_devOtp',
                                      style: const TextStyle(
                                        color: Color(0xFFF4EFE3),
                                        fontWeight: FontWeight.bold,
                                      ),
                                    ),
                                  ),
                                Row(
                                  mainAxisAlignment:
                                      MainAxisAlignment.spaceBetween,
                                  children: List.generate(6, (i) {
                                    return SizedBox(
                                      width: 44,
                                      child: TextField(
                                        controller: _otpControllers[i],
                                        focusNode: _otpFocus[i],
                                        textAlign: TextAlign.center,
                                        maxLength: 1,
                                        keyboardType: TextInputType.number,
                                        style: const TextStyle(
                                          color: Color(0xFFF4EFE3),
                                          fontSize: 20,
                                          fontWeight: FontWeight.bold,
                                        ),
                                        decoration: InputDecoration(
                                          counterText: '',
                                          filled: true,
                                          fillColor: const Color(
                                            0xFFF4EFE3,
                                          ).withValues(alpha: 0.06),
                                          border: OutlineInputBorder(
                                            borderRadius: BorderRadius.circular(
                                              10,
                                            ),
                                            borderSide: BorderSide(
                                              color: const Color(
                                                0xFFF4EFE3,
                                              ).withValues(alpha: 0.18),
                                            ),
                                          ),
                                        ),
                                        onChanged: (v) {
                                          if (v.length == 1 && i < 5)
                                            _otpFocus[i + 1].requestFocus();
                                          if (v.isEmpty && i > 0)
                                            _otpFocus[i - 1].requestFocus();
                                        },
                                      ),
                                    );
                                  }),
                                ),
                                const SizedBox(height: 24),
                                FilledButton(
                                  onPressed: _goPasswordStep,
                                  style: FilledButton.styleFrom(
                                    backgroundColor: const Color(0xFFF4EFE3),
                                    foregroundColor: const Color(0xFF0C312B),
                                    minimumSize: const Size(
                                      double.infinity,
                                      52,
                                    ),
                                    shape: RoundedRectangleBorder(
                                      borderRadius: BorderRadius.circular(14),
                                    ),
                                  ),
                                  child: const Text('CONTINUE'),
                                ),
                              ],
                              if (_step == 2) ...[
                                TextField(
                                  controller: _newPasswordController,
                                  obscureText: true,
                                  style: const TextStyle(
                                    color: Color(0xFFF4EFE3),
                                  ),
                                  decoration: InputDecoration(
                                    labelText: 'Enter New Password',
                                    labelStyle: TextStyle(
                                      color: const Color(
                                        0xFFF4EFE3,
                                      ).withValues(alpha: 0.6),
                                      fontSize: 13,
                                    ),
                                    prefixIcon: Icon(
                                      LucideIcons.lock,
                                      color: const Color(
                                        0xFFF4EFE3,
                                      ).withValues(alpha: 0.6),
                                    ),
                                    filled: true,
                                    fillColor: const Color(
                                      0xFFF4EFE3,
                                    ).withValues(alpha: 0.06),
                                    border: OutlineInputBorder(
                                      borderRadius: BorderRadius.circular(14),
                                      borderSide: BorderSide(
                                        color: const Color(
                                          0xFFF4EFE3,
                                        ).withValues(alpha: 0.18),
                                      ),
                                    ),
                                    enabledBorder: OutlineInputBorder(
                                      borderRadius: BorderRadius.circular(14),
                                      borderSide: BorderSide(
                                        color: const Color(
                                          0xFFF4EFE3,
                                        ).withValues(alpha: 0.18),
                                      ),
                                    ),
                                    focusedBorder: OutlineInputBorder(
                                      borderRadius: BorderRadius.circular(14),
                                      borderSide: BorderSide(
                                        color: const Color(
                                          0xFFF4EFE3,
                                        ).withValues(alpha: 0.45),
                                      ),
                                    ),
                                  ),
                                ),
                                const SizedBox(height: 12),
                                TextField(
                                  controller: _confirmPasswordController,
                                  obscureText: true,
                                  style: const TextStyle(
                                    color: Color(0xFFF4EFE3),
                                  ),
                                  decoration: InputDecoration(
                                    labelText: 'Confirm New Password',
                                    labelStyle: TextStyle(
                                      color: const Color(
                                        0xFFF4EFE3,
                                      ).withValues(alpha: 0.6),
                                      fontSize: 13,
                                    ),
                                    prefixIcon: Icon(
                                      LucideIcons.lock,
                                      color: const Color(
                                        0xFFF4EFE3,
                                      ).withValues(alpha: 0.6),
                                    ),
                                    filled: true,
                                    fillColor: const Color(
                                      0xFFF4EFE3,
                                    ).withValues(alpha: 0.06),
                                    border: OutlineInputBorder(
                                      borderRadius: BorderRadius.circular(14),
                                      borderSide: BorderSide(
                                        color: const Color(
                                          0xFFF4EFE3,
                                        ).withValues(alpha: 0.18),
                                      ),
                                    ),
                                    enabledBorder: OutlineInputBorder(
                                      borderRadius: BorderRadius.circular(14),
                                      borderSide: BorderSide(
                                        color: const Color(
                                          0xFFF4EFE3,
                                        ).withValues(alpha: 0.18),
                                      ),
                                    ),
                                    focusedBorder: OutlineInputBorder(
                                      borderRadius: BorderRadius.circular(14),
                                      borderSide: BorderSide(
                                        color: const Color(
                                          0xFFF4EFE3,
                                        ).withValues(alpha: 0.45),
                                      ),
                                    ),
                                  ),
                                ),
                                const SizedBox(height: 24),
                                FilledButton(
                                  onPressed: _loading ? null : _resetPassword,
                                  style: FilledButton.styleFrom(
                                    backgroundColor: const Color(0xFFF4EFE3),
                                    foregroundColor: const Color(0xFF0C312B),
                                    minimumSize: const Size(
                                      double.infinity,
                                      52,
                                    ),
                                    shape: RoundedRectangleBorder(
                                      borderRadius: BorderRadius.circular(14),
                                    ),
                                  ),
                                  child: _loading
                                      ? const SizedBox(
                                          width: 22,
                                          height: 22,
                                          child: CircularProgressIndicator(
                                            strokeWidth: 2,
                                            color: Color(0xFF0C312B),
                                          ),
                                        )
                                      : const Text('UPDATE PASSWORD'),
                                ),
                              ],
                            ],
                          ),
                        ),
                      ),
                    ),
                  ),
                  Padding(
                    padding: const EdgeInsets.only(top: 12, bottom: 28),
                    child: Text(
                      'M4 FAMILY PARTNER NETWORK',
                      textAlign: TextAlign.center,
                      style: GoogleFonts.inter(
                        fontSize: 10,
                        fontWeight: FontWeight.w600,
                        letterSpacing: 2,
                        color: const Color(0xFFF4EFE3).withValues(alpha: 0.45),
                      ),
                    ),
                  ),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }
}
