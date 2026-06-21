import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:lucide_icons/lucide_icons.dart';
import 'package:m4_mobile/presentation/providers/auth_provider.dart';

/// Mirrors web `app/investor/login/page.tsx`: premium gold landing → credentials,
/// `POST /api/investor/login`, role must be INVESTOR. Follows [CpLoginScreen] pattern.
class InvestorLoginScreen extends ConsumerStatefulWidget {
  const InvestorLoginScreen({super.key});

  @override
  ConsumerState<InvestorLoginScreen> createState() => _InvestorLoginScreenState();
}

class _InvestorLoginScreenState extends ConsumerState<InvestorLoginScreen> {
  static const _gold = Color(0xFFFFD700);
  static const _amber = Color(0xFFF59E0B);

  final _emailController = TextEditingController();
  final _passwordController = TextEditingController();
  int _step = 0; // 0: landing, 1: credentials
  bool _showPassword = false;

  @override
  void dispose() {
    _emailController.dispose();
    _passwordController.dispose();
    super.dispose();
  }

  Future<void> _submit() async {
    final email = _emailController.text.trim();
    final pw = _passwordController.text;
    if (email.isEmpty || pw.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Please provide your Email and Password')),
      );
      return;
    }
    final err = await ref.read(authProvider.notifier).loginInvestorWithPassword(email, pw);
    if (!mounted) return;
    if (err != null) {
      ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text(err)));
    }
  }

  @override
  Widget build(BuildContext context) {
    ref.listen<AuthState>(authProvider, (prev, next) {
      if (next.status == AuthStatus.authenticated) {
        context.go('/home');
      }
    });

    final loading = ref.watch(authProvider.select((s) => s.status == AuthStatus.loading));

    return Scaffold(
      backgroundColor: Colors.black,
      body: SafeArea(
        child: SingleChildScrollView(
          padding: const EdgeInsets.symmetric(horizontal: 28),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              const SizedBox(height: 12),
              Align(
                alignment: Alignment.centerLeft,
                child: IconButton(
                  onPressed: () {
                    if (_step == 1) {
                      setState(() => _step = 0);
                    } else {
                      context.go('/home');
                    }
                  },
                  icon: Container(
                    padding: const EdgeInsets.all(8),
                    decoration: BoxDecoration(
                      color: Colors.white.withValues(alpha: 0.05),
                      borderRadius: BorderRadius.circular(12),
                      border: Border.all(color: Colors.white.withValues(alpha: 0.1)),
                    ),
                    child: const Icon(LucideIcons.chevronLeft, color: Colors.white70, size: 20),
                  ),
                ),
              ),
              const SizedBox(height: 16),
              if (_step == 0) _buildLanding() else _buildCredentials(loading),
              const SizedBox(height: 32),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildLanding() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.center,
      children: [
        const SizedBox(height: 24),
        // Crown badge
        Container(
          width: 96,
          height: 96,
          decoration: BoxDecoration(
            borderRadius: BorderRadius.circular(24),
            gradient: LinearGradient(
              colors: [_amber.withValues(alpha: 0.3), _amber.withValues(alpha: 0.08)],
              begin: Alignment.topLeft,
              end: Alignment.bottomRight,
            ),
            border: Border.all(color: _amber.withValues(alpha: 0.3), width: 2),
          ),
          child: const Icon(LucideIcons.crown, color: _amber, size: 44),
        ),
        const SizedBox(height: 28),
        Text(
          'INVESTOR',
          textAlign: TextAlign.center,
          style: GoogleFonts.montserrat(
            fontSize: 38,
            fontWeight: FontWeight.w900,
            color: Colors.white,
            height: 1.0,
            letterSpacing: -1,
          ),
        ),
        Text(
          'PORTAL',
          textAlign: TextAlign.center,
          style: GoogleFonts.montserrat(
            fontSize: 38,
            fontWeight: FontWeight.w900,
            color: _gold,
            height: 1.0,
            letterSpacing: -1,
          ),
        ),
        const SizedBox(height: 12),
        Text(
          'PREMIUM ACCESS • ELITE DASHBOARD',
          textAlign: TextAlign.center,
          style: GoogleFonts.montserrat(
            fontSize: 10,
            fontWeight: FontWeight.w700,
            color: Colors.white54,
            letterSpacing: 3,
          ),
        ),
        const SizedBox(height: 28),
        const Wrap(
          spacing: 10,
          runSpacing: 10,
          alignment: WrapAlignment.center,
          children: [
            _FeaturePill(icon: LucideIcons.shield, label: 'SECURE'),
            _FeaturePill(icon: LucideIcons.sparkles, label: 'ANALYTICS'),
            _FeaturePill(icon: LucideIcons.fingerprint, label: 'REAL-TIME'),
            _FeaturePill(icon: LucideIcons.crown, label: 'PREMIUM'),
          ],
        ),
        const SizedBox(height: 36),
        SizedBox(
          height: 64,
          child: FilledButton(
            onPressed: () => setState(() => _step = 1),
            style: FilledButton.styleFrom(
              backgroundColor: _amber,
              foregroundColor: Colors.black,
              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
            ),
            child: Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Text(
                  'ACCESS INVESTOR HUB',
                  style: GoogleFonts.montserrat(fontWeight: FontWeight.w900, fontSize: 12, letterSpacing: 1.5),
                ),
                Container(
                  padding: const EdgeInsets.all(6),
                  decoration: BoxDecoration(
                    color: Colors.black.withValues(alpha: 0.1),
                    shape: BoxShape.circle,
                  ),
                  child: const Icon(LucideIcons.arrowRight, size: 18),
                ),
              ],
            ),
          ),
        ),
        const SizedBox(height: 24),
        Row(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(LucideIcons.shield, size: 14, color: _amber.withValues(alpha: 0.6)),
            const SizedBox(width: 8),
            Text(
              'INSTITUTIONAL GRADE SECURITY',
              style: GoogleFonts.montserrat(
                fontSize: 9,
                fontWeight: FontWeight.w800,
                color: Colors.white38,
                letterSpacing: 2.5,
              ),
            ),
          ],
        ),
      ],
    );
  }

  Widget _buildCredentials(bool loading) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        Row(
          children: [
            Container(
              width: 56,
              height: 56,
              decoration: BoxDecoration(
                borderRadius: BorderRadius.circular(16),
                gradient: LinearGradient(
                  colors: [_amber.withValues(alpha: 0.3), _amber.withValues(alpha: 0.08)],
                ),
                border: Border.all(color: _amber.withValues(alpha: 0.3)),
              ),
              child: const Icon(LucideIcons.briefcase, color: _amber, size: 26),
            ),
            const SizedBox(width: 16),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    'INVESTOR',
                    style: GoogleFonts.montserrat(
                      fontSize: 22,
                      fontWeight: FontWeight.w900,
                      color: Colors.white,
                      height: 1.0,
                    ),
                  ),
                  Text(
                    'CREDENTIALS',
                    style: GoogleFonts.montserrat(
                      fontSize: 18,
                      fontWeight: FontWeight.w900,
                      color: _gold,
                      height: 1.1,
                    ),
                  ),
                ],
              ),
            ),
          ],
        ),
        const SizedBox(height: 8),
        Text(
          'SECURE INSTITUTIONAL ACCESS GATEWAY',
          style: GoogleFonts.montserrat(
            fontSize: 9,
            fontWeight: FontWeight.w700,
            color: Colors.white54,
            letterSpacing: 2.5,
          ),
        ),
        const SizedBox(height: 36),
        _Field(
          label: 'REGISTERED EMAIL',
          controller: _emailController,
          icon: LucideIcons.mail,
          hint: 'investor@institution.com',
          keyboardType: TextInputType.emailAddress,
        ),
        const SizedBox(height: 24),
        _Field(
          label: 'SECURE PASSWORD',
          controller: _passwordController,
          icon: LucideIcons.lock,
          hint: '••••••••••••',
          obscure: !_showPassword,
          suffix: IconButton(
            onPressed: () => setState(() => _showPassword = !_showPassword),
            icon: Icon(
              _showPassword ? LucideIcons.eyeOff : LucideIcons.eye,
              color: Colors.white54,
              size: 18,
            ),
          ),
        ),
        const SizedBox(height: 32),
        SizedBox(
          height: 64,
          child: FilledButton(
            onPressed: loading ? null : _submit,
            style: FilledButton.styleFrom(
              backgroundColor: _amber,
              foregroundColor: Colors.black,
              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
            ),
            child: loading
                ? const SizedBox(
                    width: 22,
                    height: 22,
                    child: CircularProgressIndicator(strokeWidth: 2, color: Colors.black),
                  )
                : Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      Text(
                        'LOGIN',
                        style: GoogleFonts.montserrat(fontWeight: FontWeight.w900, fontSize: 13, letterSpacing: 1.5),
                      ),
                      Container(
                        padding: const EdgeInsets.all(6),
                        decoration: BoxDecoration(
                          color: Colors.black.withValues(alpha: 0.1),
                          shape: BoxShape.circle,
                        ),
                        child: const Icon(LucideIcons.arrowRight, size: 18),
                      ),
                    ],
                  ),
          ),
        ),
        const SizedBox(height: 24),
        Center(
          child: Text(
            'INVESTOR PORTAL v3.0\nPOWERED BY M4 FAMILY CAPITAL',
            textAlign: TextAlign.center,
            style: GoogleFonts.montserrat(
              fontSize: 9,
              fontWeight: FontWeight.w800,
              color: Colors.white38,
              letterSpacing: 2,
              height: 1.6,
            ),
          ),
        ),
      ],
    );
  }
}

class _FeaturePill extends StatelessWidget {
  final IconData icon;
  final String label;

  const _FeaturePill({required this.icon, required this.label});

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 8),
      decoration: BoxDecoration(
        color: Colors.black.withValues(alpha: 0.4),
        borderRadius: BorderRadius.circular(100),
        border: Border.all(color: Colors.white.withValues(alpha: 0.1)),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(icon, size: 14, color: const Color(0xFFF59E0B)),
          const SizedBox(width: 8),
          Text(
            label,
            style: GoogleFonts.montserrat(
              fontSize: 9,
              fontWeight: FontWeight.w700,
              color: Colors.white,
              letterSpacing: 1.5,
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
  final TextInputType? keyboardType;
  final Widget? suffix;

  const _Field({
    required this.label,
    required this.controller,
    required this.icon,
    this.hint,
    this.obscure = false,
    this.keyboardType,
    this.suffix,
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
          keyboardType: keyboardType,
          style: const TextStyle(color: Colors.white, fontWeight: FontWeight.w600),
          decoration: InputDecoration(
            hintText: hint,
            hintStyle: TextStyle(color: Colors.white.withValues(alpha: 0.35)),
            prefixIcon: Icon(icon, color: Colors.white54),
            suffixIcon: suffix,
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
            focusedBorder: OutlineInputBorder(
              borderRadius: BorderRadius.circular(16),
              borderSide: const BorderSide(color: Color(0xFFF59E0B), width: 1.2),
            ),
          ),
        ),
      ],
    );
  }
}
