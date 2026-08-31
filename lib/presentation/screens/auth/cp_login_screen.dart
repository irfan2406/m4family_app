import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:lucide_icons/lucide_icons.dart';
import 'package:m4_mobile/core/utils/validators.dart';
import 'package:m4_mobile/presentation/providers/auth_provider.dart';

/// Mirrors web `app/auth/cp/login/page.tsx`: mobile number + password →
/// `POST /auth/login`, role must be CP.
class CpLoginScreen extends ConsumerStatefulWidget {
  const CpLoginScreen({super.key});

  @override
  ConsumerState<CpLoginScreen> createState() => _CpLoginScreenState();
}

class _CpLoginScreenState extends ConsumerState<CpLoginScreen> {
  final _phoneController = TextEditingController();
  final _passwordController = TextEditingController();

  @override
  void dispose() {
    _phoneController.dispose();
    _passwordController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final fromGuest =
        GoRouterState.of(context).uri.queryParameters['from'] == 'guest';

    ref.listen<AuthState>(authProvider, (prev, next) {
      if (next.status == AuthStatus.authenticated) {
        context.go('/home');
      }
    });

    return Scaffold(
      backgroundColor: const Color(0xFF0C312B),
      body: Stack(
        fit: StackFit.expand,
        children: [
          const Positioned.fill(child: ColoredBox(color: Color(0xFF0C312B))),
          SafeArea(
            // Edge-to-edge: content runs under the gesture bar so scrolling fills
            // the screen. Trailing padding keeps the last item reachable.
            bottom: false,
            child: SingleChildScrollView(
              padding: const EdgeInsets.symmetric(horizontal: 32),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.stretch,
                children: [
                  const SizedBox(height: 16),
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      IconButton(
                        onPressed: () => context.go('/home'),
                        icon: Container(
                          padding: const EdgeInsets.all(8),
                          decoration: BoxDecoration(
                            color: Colors.white.withOpacity(0.05),
                            borderRadius: BorderRadius.circular(10),
                            border: Border.all(
                              color: Colors.white.withOpacity(0.1),
                            ),
                          ),
                          child: const Icon(
                            LucideIcons.chevronLeft,
                            color: Colors.white70,
                            size: 18,
                          ),
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 24),
                  if (fromGuest) ...[
                    GestureDetector(
                      onTap: () => context.go('/home'),
                      child: Container(
                        padding: const EdgeInsets.symmetric(vertical: 16),
                        decoration: BoxDecoration(
                          color: Colors.white.withOpacity(0.05),
                          borderRadius: BorderRadius.circular(16),
                          border: Border.all(
                            color: Colors.white.withOpacity(0.12),
                          ),
                        ),
                        child: Row(
                          mainAxisAlignment: MainAxisAlignment.center,
                          children: [
                            Icon(
                              LucideIcons.chevronLeft,
                              color: Colors.white.withOpacity(0.6),
                              size: 15,
                            ),
                            const SizedBox(width: 10),
                            Text(
                              'BACK TO GUEST PORTAL',
                              style: GoogleFonts.inter(
                                color: Colors.white.withValues(alpha: 0.6),
                                fontWeight: FontWeight.w700,
                                fontSize: 11,
                                letterSpacing: 2,
                              ),
                            ),
                          ],
                        ),
                      ),
                    ),
                    const SizedBox(height: 24),
                  ],
                  Text(
                    'CHANNEL\nPARTNER',
                    style: GoogleFonts.gelasio(
                      fontSize: 36,
                      fontWeight: FontWeight.w500,
                      color: Colors.white,
                      height: 1.05,
                      letterSpacing: -1.5,
                    ),
                  ),
                  const SizedBox(height: 12),
                  Text.rich(
                    TextSpan(
                      children: [
                        const TextSpan(text: 'AUTHORIZED '),
                        TextSpan(
                          text: 'PARTNER',
                          style: GoogleFonts.inter(
                            color: const Color(0xFFF4EFE3),
                            fontWeight: FontWeight.w700,
                            fontSize: 10,
                            letterSpacing: 2,
                          ),
                        ),
                        const TextSpan(text: ' ACCESS PORTAL'),
                      ],
                    ),
                    style: GoogleFonts.inter(
                      fontSize: 10,
                      fontWeight: FontWeight.w700,
                      color: Colors.white70,
                      letterSpacing: 2,
                    ),
                  ),
                  const SizedBox(height: 48),
                  // Sign in with the mobile number rather than the CP ID.
                  // /api/auth/login takes a single `identifier`, which the
                  // backend resolves against phone / email / id alike (the
                  // investor screen documents the same contract), so only the
                  // field changes — the request shape is untouched.
                  _Field(
                    label: 'MOBILE NUMBER',
                    controller: _phoneController,
                    hint: 'Enter Mobile Number',
                    keyboardType: TextInputType.phone,
                    inputFormatters: Validators.phoneFormatters,
                  ),
                  const SizedBox(height: 24),
                  _Field(
                    label: 'PASSWORD',
                    controller: _passwordController,
                    obscure: true,
                    hint: 'Enter Password',
                  ),
                  const SizedBox(height: 16),
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      TextButton(
                        // Flat link: no ripple, highlight or shadow on press.
                        style: TextButton.styleFrom(
                          overlayColor: Colors.transparent,
                          shadowColor: Colors.transparent,
                          elevation: 0,
                          splashFactory: NoSplash.splashFactory,
                        ),
                        onPressed: () => context.push(
                          '/auth/cp/forgot-password${fromGuest ? '?from=guest' : ''}',
                        ),
                        child: Text(
                          'FORGOT PASSWORD?',
                          style: GoogleFonts.inter(
                            fontSize: 10,
                            fontWeight: FontWeight.w500,
                            color: Colors.white70,
                            letterSpacing: 1.5,
                          ),
                        ),
                      ),
                      TextButton(
                        // Flat link: no ripple, highlight or shadow on press.
                        style: TextButton.styleFrom(
                          overlayColor: Colors.transparent,
                          shadowColor: Colors.transparent,
                          elevation: 0,
                          splashFactory: NoSplash.splashFactory,
                        ),
                        onPressed: () => context.push(
                          '/auth/cp/signup${fromGuest ? '?from=guest' : ''}',
                        ),
                        child: Text(
                          'REGISTER NOW',
                          style: GoogleFonts.inter(
                            fontSize: 10,
                            fontWeight: FontWeight.w600,
                            color: const Color(0xFFF4EFE3),
                            letterSpacing: 1.5,
                          ),
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 32),
                  Consumer(
                    builder: (context, ref, _) {
                      final loading = ref.watch(
                        authProvider.select(
                          (s) => s.status == AuthStatus.loading,
                        ),
                      );
                      return SizedBox(
                        height: 64,
                        child: Material(
                          color: Colors.transparent,
                          borderRadius: BorderRadius.circular(20),
                          child: InkWell(
                            borderRadius: BorderRadius.circular(20),
                            onTap: loading
                                ? null
                                : () async {
                                    final id = _phoneController.text.trim();
                                    final pw = _passwordController.text;
                                    if (id.isEmpty || pw.isEmpty) {
                                      ScaffoldMessenger.of(
                                        context,
                                      ).showSnackBar(
                                        const SnackBar(
                                          backgroundColor: Color(0xFFC65B46),
                                          content: Text(
                                            'Please enter both mobile number and password',
                                          ),
                                        ),
                                      );
                                      return;
                                    }
                                    final err = await ref
                                        .read(authProvider.notifier)
                                        .loginCpWithPassword(id, pw);
                                    if (!context.mounted) return;
                                    if (err != null) {
                                      ScaffoldMessenger.of(
                                        context,
                                      ).showSnackBar(
                                        SnackBar(
                                          backgroundColor: const Color(
                                            0xFFC65B46,
                                          ),
                                          content: Text(err),
                                        ),
                                      );
                                    }
                                  },
                            child: Ink(
                              decoration: BoxDecoration(
                                gradient: const LinearGradient(
                                  begin: Alignment.centerLeft,
                                  end: Alignment.centerRight,
                                  colors: [
                                    Color(0xFFF4EFE3),
                                    Color(0xFFF4EFE3),
                                  ],
                                ),
                                borderRadius: BorderRadius.circular(20),
                              ),
                              child: Padding(
                                padding: const EdgeInsets.symmetric(
                                  horizontal: 24,
                                ),
                                child: Center(
                                  child: loading
                                      ? const SizedBox(
                                          width: 22,
                                          height: 22,
                                          child: CircularProgressIndicator(
                                            strokeWidth: 2,
                                            color: Colors.white,
                                          ),
                                        )
                                      : Row(
                                          mainAxisAlignment:
                                              MainAxisAlignment.spaceBetween,
                                          children: [
                                            Text(
                                              'AUTHORIZE ACCESS',
                                              style: GoogleFonts.inter(
                                                color: const Color(0xFF0C312B),
                                                fontWeight: FontWeight.w500,
                                                fontSize: 13,
                                                letterSpacing: 1.5,
                                              ),
                                            ),
                                            // The arrow sits at 20% opacity,
                                            // which reads as a disabled
                                            // affordance. Once the mobile number and
                                            // password are both filled the
                                            // circle goes solid green so the
                                            // button looks ready to authorize.
                                            // Listening to the two controllers
                                            // rebuilds only this circle as the
                                            // user types.
                                            AnimatedBuilder(
                                              animation: Listenable.merge([
                                                _phoneController,
                                                _passwordController,
                                              ]),
                                              builder: (context, _) {
                                                final ready =
                                                    _phoneController.text
                                                        .trim()
                                                        .isNotEmpty &&
                                                    _passwordController
                                                        .text
                                                        .isNotEmpty;
                                                return AnimatedContainer(
                                                  duration: const Duration(
                                                    milliseconds: 200,
                                                  ),
                                                  padding: const EdgeInsets.all(
                                                    6,
                                                  ),
                                                  decoration: BoxDecoration(
                                                    color: ready
                                                        ? const Color(
                                                            0xFF0C312B,
                                                          )
                                                        : const Color(
                                                            0xFF0C312B,
                                                          ).withOpacity(0.2),
                                                    shape: BoxShape.circle,
                                                  ),
                                                  child: const Icon(
                                                    LucideIcons.arrowRight,
                                                    color: Colors.white,
                                                    size: 18,
                                                  ),
                                                );
                                              },
                                            ),
                                          ],
                                        ),
                                ),
                              ),
                            ),
                          ),
                        ),
                      );
                    },
                  ),
                  const SizedBox(height: 32),
                  Text(
                    'M4 FAMILY PARTNER NETWORK\nSECURE • VERIFIED • TRUSTED',
                    textAlign: TextAlign.center,
                    style: GoogleFonts.inter(
                      fontSize: 10,
                      fontWeight: FontWeight.w500,
                      color: Colors.white70,
                      letterSpacing: 2,
                      height: 1.6,
                    ),
                  ),
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

class _Field extends StatefulWidget {
  final String label;
  final TextEditingController controller;
  final String? hint;
  final bool obscure;
  final TextInputType? keyboardType;
  final List<TextInputFormatter>? inputFormatters;

  const _Field({
    required this.label,
    required this.controller,
    this.hint,
    this.obscure = false,
    this.keyboardType,
    this.inputFormatters,
  });

  @override
  State<_Field> createState() => _FieldState();
}

class _FieldState extends State<_Field> {
  late bool _hidden = widget.obscure;

  @override
  Widget build(BuildContext context) {
    // Web parity: no left icon; password field carries an eye toggle on the
    // right; pill-rounded dark field.
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          widget.label,
          style: GoogleFonts.inter(
            fontSize: 9,
            fontWeight: FontWeight.bold,
            color: Colors.white70,
            letterSpacing: 2,
          ),
        ),
        const SizedBox(height: 8),
        TextField(
          controller: widget.controller,
          obscureText: _hidden,
          keyboardType: widget.keyboardType,
          inputFormatters: widget.inputFormatters,
          // White cursor so it's visible on the dark field (default cursor is
          // the theme primary, which is near-black here = invisible).
          cursorColor: Colors.white,
          style: const TextStyle(
            color: Colors.white,
            fontWeight: FontWeight.w600,
          ),
          decoration: InputDecoration(
            hintText: widget.hint,
            hintStyle: TextStyle(color: Colors.white.withValues(alpha: 0.5)),
            contentPadding: const EdgeInsets.symmetric(
              horizontal: 24,
              vertical: 20,
            ),
            suffixIcon: widget.obscure
                ? IconButton(
                    onPressed: () => setState(() => _hidden = !_hidden),
                    icon: Icon(
                      _hidden ? LucideIcons.eye : LucideIcons.eyeOff,
                      color: Colors.white54,
                      size: 20,
                    ),
                  )
                : null,
            filled: true,
            fillColor: Colors.white.withValues(alpha: 0.03),
            border: OutlineInputBorder(
              borderRadius: BorderRadius.circular(24),
              borderSide: BorderSide(
                color: Colors.white.withValues(alpha: 0.12),
              ),
            ),
            enabledBorder: OutlineInputBorder(
              borderRadius: BorderRadius.circular(24),
              borderSide: BorderSide(
                color: Colors.white.withValues(alpha: 0.12),
              ),
            ),
            focusedBorder: OutlineInputBorder(
              borderRadius: BorderRadius.circular(24),
              borderSide: BorderSide(
                color: Colors.white.withValues(alpha: 0.85),
              ),
            ),
          ),
        ),
      ],
    );
  }
}
