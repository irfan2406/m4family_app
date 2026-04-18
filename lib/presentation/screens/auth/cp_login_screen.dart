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
    final fromGuest = GoRouterState.of(context).uri.queryParameters['from'] == 'guest';

    ref.listen<AuthState>(authProvider, (prev, next) {
      if (next.status == AuthStatus.authenticated) {
        context.go('/home');
      }
    });

    return Scaffold(
      backgroundColor: Colors.black,
      body: Stack(
        fit: StackFit.expand,
        children: [
          Positioned.fill(
            child: Image.asset('assets/login-bg.png', fit: BoxFit.cover),
          ),
          Container(
            decoration: BoxDecoration(
              gradient: LinearGradient(
                begin: Alignment.topCenter,
                end: Alignment.bottomCenter,
                colors: [
                  Colors.black.withValues(alpha: 0.55),
                  Colors.black.withValues(alpha: 0.75),
                ],
              ),
            ),
          ),
          SafeArea(
            child: SingleChildScrollView(
              padding: const EdgeInsets.symmetric(horizontal: 28),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.stretch,
                children: [
                  const SizedBox(height: 16),
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      IconButton(
                        style: IconButton.styleFrom(
                          backgroundColor: Colors.white.withValues(alpha: 0.1),
                        ),
                        onPressed: () => context.go('/login'),
                        icon: const Icon(LucideIcons.chevronLeft, color: Colors.white),
                      ),
                      Container(
                        padding: const EdgeInsets.all(10),
                        decoration: BoxDecoration(
                          color: Colors.purple.withValues(alpha: 0.2),
                          borderRadius: BorderRadius.circular(12),
                          border: Border.all(color: Colors.purple.withValues(alpha: 0.35)),
                        ),
                        child: const Icon(LucideIcons.sparkles, color: Colors.purpleAccent, size: 22),
                      ),
                    ],
                  ),
                  if (fromGuest) ...[
                    const SizedBox(height: 12),
                    OutlinedButton(
                      onPressed: () => context.go('/home'),
                      child: Text(
                        'BACK TO GUEST PORTAL',
                        style: GoogleFonts.montserrat(fontSize: 10, fontWeight: FontWeight.bold, letterSpacing: 2),
                      ),
                    ),
                  ],
                  const SizedBox(height: 32),
                  Text(
                    'CHANNEL PARTNER',
                    style: GoogleFonts.montserrat(
                      fontSize: 32,
                      fontWeight: FontWeight.bold,
                      color: Colors.white,
                      letterSpacing: -0.5,
                    ),
                  ),
                  const SizedBox(height: 8),
                  Text(
                    'AUTHORIZED PARTNER ACCESS PORTAL',
                    style: GoogleFonts.montserrat(
                      fontSize: 10,
                      fontWeight: FontWeight.w600,
                      color: Colors.white54,
                      letterSpacing: 3,
                    ),
                  ),
                  const SizedBox(height: 36),
                  _Field(
                    label: 'CHANNEL PARTNER ID',
                    controller: _cpIdController,
                    icon: LucideIcons.user,
                    hint: 'CP-XXXXX',
                  ),
                  const SizedBox(height: 20),
                  _Field(
                    label: 'PRIVATE PASSWORD',
                    controller: _passwordController,
                    icon: LucideIcons.lock,
                    obscure: true,
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
                          style: GoogleFonts.montserrat(
                            fontSize: 10,
                            fontWeight: FontWeight.bold,
                            color: Colors.white54,
                            letterSpacing: 2,
                          ),
                        ),
                      ),
                      TextButton(
                        onPressed: () => context.push(
                          '/auth/cp/signup${fromGuest ? '?from=guest' : ''}',
                        ),
                        child: Text(
                          'REGISTER NOW',
                          style: GoogleFonts.montserrat(
                            fontSize: 10,
                            fontWeight: FontWeight.bold,
                            color: Colors.purpleAccent,
                            letterSpacing: 2,
                          ),
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 24),
                  Consumer(
                    builder: (context, ref, _) {
                      final loading = ref.watch(authProvider.select((s) => s.status == AuthStatus.loading));
                      return SizedBox(
                        height: 56,
                        child: FilledButton(
                          onPressed: loading
                              ? null
                              : () async {
                                  final id = _cpIdController.text.trim();
                                  final pw = _passwordController.text;
                                  if (id.isEmpty || pw.isEmpty) {
                                    ScaffoldMessenger.of(context).showSnackBar(
                                      const SnackBar(content: Text('Please enter both CP ID and password')),
                                    );
                                    return;
                                  }
                                  final err = await ref.read(authProvider.notifier).loginCpWithPassword(id, pw);
                                  if (!context.mounted) return;
                                  if (err != null) {
                                    ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text(err)));
                                  }
                                },
                          style: FilledButton.styleFrom(
                            backgroundColor: Colors.purple.shade600,
                            shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
                          ),
                          child: loading
                              ? const SizedBox(
                                  width: 22,
                                  height: 22,
                                  child: CircularProgressIndicator(strokeWidth: 2, color: Colors.white),
                                )
                              : Row(
                                  mainAxisAlignment: MainAxisAlignment.center,
                                  children: [
                                    Text(
                                      'AUTHORIZE ACCESS',
                                      style: GoogleFonts.montserrat(fontWeight: FontWeight.bold, letterSpacing: 2),
                                    ),
                                    const SizedBox(width: 12),
                                    const Icon(LucideIcons.arrowRight, size: 20),
                                  ],
                                ),
                        ),
                      );
                    },
                  ),
                  const SizedBox(height: 32),
                  Text(
                    'M4 FAMILY PARTNER NETWORK\nSECURE • VERIFIED • TRUSTED',
                    textAlign: TextAlign.center,
                    style: GoogleFonts.montserrat(
                      fontSize: 9,
                      fontWeight: FontWeight.bold,
                      color: Colors.white38,
                      letterSpacing: 2,
                      height: 1.6,
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
}

class _Field extends StatelessWidget {
  final String label;
  final TextEditingController controller;
  final IconData icon;
  final String? hint;
  final bool obscure;

  const _Field({
    required this.label,
    required this.controller,
    required this.icon,
    this.hint,
    this.obscure = false,
  });

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          label,
          style: GoogleFonts.montserrat(
            fontSize: 9,
            fontWeight: FontWeight.bold,
            color: Colors.white54,
            letterSpacing: 2,
          ),
        ),
        const SizedBox(height: 8),
        TextField(
          controller: controller,
          obscureText: obscure,
          style: const TextStyle(color: Colors.white, fontWeight: FontWeight.w600),
          decoration: InputDecoration(
            hintText: hint,
            hintStyle: TextStyle(color: Colors.white.withValues(alpha: 0.35)),
            prefixIcon: Icon(icon, color: Colors.white54),
            filled: true,
            fillColor: Colors.black.withValues(alpha: 0.4),
            border: OutlineInputBorder(
              borderRadius: BorderRadius.circular(16),
              borderSide: BorderSide(color: Colors.white.withValues(alpha: 0.12)),
            ),
            enabledBorder: OutlineInputBorder(
              borderRadius: BorderRadius.circular(16),
              borderSide: BorderSide(color: Colors.white.withValues(alpha: 0.12)),
            ),
          ),
        ),
      ],
    );
  }
}
