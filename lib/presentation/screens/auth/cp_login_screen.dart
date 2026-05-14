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
                  Colors.black,
                ],
              ),
            ),
          ),
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
                            border: Border.all(color: Colors.white.withOpacity(0.1)),
                          ),
                          child: const Icon(LucideIcons.chevronLeft, color: Colors.white70, size: 18),
                        ),
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
                  const SizedBox(height: 24),
                  if (fromGuest) ...[
                    Align(
                      alignment: Alignment.centerLeft,
                      child: GestureDetector(
                        onTap: () => context.go('/home'),
                        child: Container(
                          padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 14),
                          decoration: BoxDecoration(
                            color: Colors.white.withOpacity(0.05),
                            borderRadius: BorderRadius.circular(16),
                            border: Border.all(color: Colors.white.withOpacity(0.15)),
                          ),
                          child: Row(
                            mainAxisSize: MainAxisSize.min,
                            children: [
                              const Icon(LucideIcons.chevronLeft, color: Colors.white, size: 16),
                              const SizedBox(width: 12),
                              Text(
                                'BACK TO GUEST PORTAL',
                                style: GoogleFonts.montserrat(
                                  color: Colors.white,
                                  fontWeight: FontWeight.w900,
                                  fontSize: 11,
                                  letterSpacing: 2,
                                ),
                              ),
                            ],
                          ),
                        ),
                      ),
                    ),
                    const SizedBox(height: 48),
                  ],
                  Text(
                    'CHANNEL\nPARTNER',
                    style: GoogleFonts.montserrat(
                      fontSize: 48,
                      fontWeight: FontWeight.w900,
                      color: Colors.white,
                      height: 1.1,
                      letterSpacing: -1,
                    ),
                  ),
                  const SizedBox(height: 12),
                  Text(
                    'AUTHORIZED PARTNER ACCESS PORTAL',
                    style: GoogleFonts.montserrat(
                      fontSize: 10,
                      fontWeight: FontWeight.w700,
                      color: Colors.white54,
                      letterSpacing: 2,
                    ),
                  ),
                  const SizedBox(height: 48),
                  _Field(
                    label: 'CHANNEL PARTNER ID',
                    controller: _cpIdController,
                    icon: LucideIcons.user,
                    hint: 'CP-XXXXX',
                  ),
                  const SizedBox(height: 24),
                  _Field(
                    label: 'PRIVATE PASSWORD',
                    controller: _passwordController,
                    icon: LucideIcons.lock,
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
                          style: GoogleFonts.montserrat(
                            fontSize: 10,
                            fontWeight: FontWeight.w800,
                            color: Colors.white54,
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
                          style: GoogleFonts.montserrat(
                            fontSize: 10,
                            fontWeight: FontWeight.w900,
                            color: Colors.purpleAccent,
                            letterSpacing: 1.5,
                          ),
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 32),
                  Consumer(
                    builder: (context, ref, _) {
                      final loading = ref.watch(authProvider.select((s) => s.status == AuthStatus.loading));
                      return SizedBox(
                        height: 64,
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
                            shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(32)),
                            padding: const EdgeInsets.symmetric(horizontal: 24),
                          ),
                          child: loading
                              ? const SizedBox(
                                  width: 22,
                                  height: 22,
                                  child: CircularProgressIndicator(strokeWidth: 2, color: Colors.white),
                                )
                              : Row(
                                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                                  children: [
                                    Text(
                                      'AUTHORIZE ACCESS',
                                      style: GoogleFonts.montserrat(fontWeight: FontWeight.w900, fontSize: 13, letterSpacing: 1.5),
                                    ),
                                    Container(
                                      padding: const EdgeInsets.all(6),
                                      decoration: BoxDecoration(
                                        color: Colors.white.withOpacity(0.2),
                                        shape: BoxShape.circle,
                                      ),
                                      child: const Icon(LucideIcons.arrowRight, size: 18),
                                    ),
                                  ],
                                ),
                        ),
                      );
                    },
                  ),
                  const SizedBox(height: 48),
                  Text(
                    'M4 FAMILY PARTNER NETWORK\nSECURE • VERIFIED • TRUSTED',
                    textAlign: TextAlign.center,
                    style: GoogleFonts.montserrat(
                      fontSize: 10,
                      fontWeight: FontWeight.w800,
                      color: Colors.white38,
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
