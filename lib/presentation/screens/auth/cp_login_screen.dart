import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:lucide_icons/lucide_icons.dart';
import 'package:m4_mobile/presentation/providers/auth_provider.dart';

/// Mirrors web `app/auth/cp/login/page.tsx`: CP ID + password → `POST /auth/login`, role must be CP.
class CpLoginScreen extends ConsumerStatefulWidget {
  const CpLoginScreen({super.key});

  @override
  ConsumerState<CpLoginScreen> createState() => _CpLoginScreenState();
}

class _CpLoginScreenState extends ConsumerState<CpLoginScreen> {
  final _cpIdController = TextEditingController();
  final _passwordController = TextEditingController();

  @override
  void dispose() {
    _cpIdController.dispose();
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
      backgroundColor: const Color(0xFF0F2A20),
      body: Stack(
        fit: StackFit.expand,
        children: [
          const Positioned.fill(child: ColoredBox(color: Color(0xFF0F2A20))),
          SafeArea(
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
                      // Web parity: purple lock badge in the top-right corner.
                      Container(
                        padding: const EdgeInsets.all(12),
                        decoration: BoxDecoration(
                          color: const Color(0xFFC5A35B).withValues(alpha: 0.2),
                          borderRadius: BorderRadius.circular(14),
                          border: Border.all(
                            color: const Color(0xFFC5A35B).withValues(alpha: 0.35),
                          ),
                        ),
                        child: const Icon(
                          LucideIcons.lock,
                          color: Colors.white,
                          size: 24,
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
                              style: GoogleFonts.ebGaramond(
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
                    const SizedBox(height: 40),
                  ],
                  Text(
                    'CHANNEL\nPARTNER',
                    style: GoogleFonts.ebGaramond(
                      fontSize: 46,
                      fontWeight: FontWeight.w800,
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
                          style: GoogleFonts.ebGaramond(
                            color: const Color(0xFFC5A35B),
                            fontWeight: FontWeight.w700,
                            fontSize: 10,
                            letterSpacing: 2,
                          ),
                        ),
                        const TextSpan(text: ' ACCESS PORTAL'),
                      ],
                    ),
                    style: GoogleFonts.ebGaramond(
                      fontSize: 10,
                      fontWeight: FontWeight.w700,
                      color: Colors.white70,
                      letterSpacing: 2,
                    ),
                  ),
                  const SizedBox(height: 48),
                  _Field(
                    label: 'CHANNEL PARTNER ID',
                    controller: _cpIdController,
                    hint: 'CP-XXXXX',
                  ),
                  const SizedBox(height: 24),
                  _Field(
                    label: 'PRIVATE PASSWORD',
                    controller: _passwordController,
                    obscure: true,
                    hint: '••••••••',
                  ),
                  const SizedBox(height: 16),
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      TextButton(
                        onPressed: () => context.push(
                          '/auth/cp/forgot-password${fromGuest ? '?from=guest' : ''}',
                        ),
                        child: Text(
                          'FORGOT PASSWORD?',
                          style: GoogleFonts.ebGaramond(
                            fontSize: 10,
                            fontWeight: FontWeight.w800,
                            color: Colors.white70,
                            letterSpacing: 1.5,
                          ),
                        ),
                      ),
                      TextButton(
                        onPressed: () => context.push(
                          '/auth/cp/signup${fromGuest ? '?from=guest' : ''}',
                        ),
                        child: Text(
                          'REGISTER NOW',
                          style: GoogleFonts.ebGaramond(
                            fontSize: 10,
                            fontWeight: FontWeight.w900,
                            color: const Color(0xFFC5A35B),
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
                          borderRadius: BorderRadius.circular(32),
                          child: InkWell(
                            borderRadius: BorderRadius.circular(32),
                            onTap: loading
                                ? null
                                : () async {
                                    final id = _cpIdController.text.trim();
                                    final pw = _passwordController.text;
                                    if (id.isEmpty || pw.isEmpty) {
                                      ScaffoldMessenger.of(
                                        context,
                                      ).showSnackBar(
                                        const SnackBar(
                                          backgroundColor: Color(0xFFC65B46),
                                          content: Text(
                                            'Please enter both CP ID and password',
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
                                  colors: [Color(0xFFF4EFE3), Color(0xFFFBF7EF)],
                                ),
                                borderRadius: BorderRadius.circular(32),
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
                                              style: GoogleFonts.ebGaramond(
                                                color: const Color(0xFF0F2A20),
                                                fontWeight: FontWeight.w800,
                                                fontSize: 13,
                                                letterSpacing: 1.5,
                                              ),
                                            ),
                                            Container(
                                              padding: const EdgeInsets.all(6),
                                              decoration: BoxDecoration(
                                                color: const Color(0xFF0F2A20).withOpacity(
                                                  0.2,
                                                ),
                                                shape: BoxShape.circle,
                                              ),
                                              child: const Icon(
                                                LucideIcons.arrowRight,
                                                color: Colors.white,
                                                size: 18,
                                              ),
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
                    style: GoogleFonts.ebGaramond(
                      fontSize: 10,
                      fontWeight: FontWeight.w800,
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

  const _Field({
    required this.label,
    required this.controller,
    this.hint,
    this.obscure = false,
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
          style: GoogleFonts.ebGaramond(
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
