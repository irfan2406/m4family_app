import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:m4_mobile/presentation/providers/auth_provider.dart';
import 'package:go_router/go_router.dart';
import 'package:flutter_animate/flutter_animate.dart';
import 'package:lucide_icons/lucide_icons.dart';
import 'package:google_fonts/google_fonts.dart';

class LoginScreen extends ConsumerStatefulWidget {
  const LoginScreen({super.key});

  @override
  ConsumerState<LoginScreen> createState() => _LoginScreenState();
}

class _LoginScreenState extends ConsumerState<LoginScreen> {
  final TextEditingController _phoneController = TextEditingController();
  final List<TextEditingController> _otpControllers = List.generate(6, (index) => TextEditingController());
  final List<FocusNode> _focusNodes = List.generate(6, (index) => FocusNode());
  
  int _step = 0; // 0: Options, 1: Phone, 2: OTP
  String _selectedRole = 'CUSTOMER';

  @override
  void dispose() {
    _phoneController.dispose();
    for (var controller in _otpControllers) {
      controller.dispose();
    }
    for (var node in _focusNodes) {
      node.dispose();
    }
    super.dispose();
  }

  void _onOtpChanged(String value, int index) {
    if (value.length == 1 && index < 5) {
      _focusNodes[index + 1].requestFocus();
    }
    if (value.isEmpty && index > 0) {
      _focusNodes[index - 1].requestFocus();
    }
  }

  @override
  Widget build(BuildContext context) {
    final authState = ref.watch(authProvider);

    ref.listen(authProvider, (previous, next) {
      if (next.status == AuthStatus.authenticated) {
        context.go('/home');
      } else if (next.status == AuthStatus.error) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(next.error ?? 'Error occurred'),
            backgroundColor: Colors.redAccent,
          ),
        );
      } else if (next.status == AuthStatus.otpSent) {
        setState(() => _step = 2);
      }
    });

    return Scaffold(
      backgroundColor: Colors.black,
      body: Stack(
        fit: StackFit.expand,
        children: [
          // Background Image with Overlay
          Positioned.fill(
            child: Image.asset(
              'assets/login-bg.png',
              fit: BoxFit.cover,
            ),
          ),
          Container(
            decoration: BoxDecoration(
              gradient: LinearGradient(
                begin: Alignment.topCenter,
                end: Alignment.bottomCenter,
                colors: [
                  Colors.black.withOpacity(0.4),
                  Colors.black.withOpacity(0.1),
                  Colors.black,
                ],
                stops: const [0, 0.4, 1],
              ),
            ),
          ),
          Positioned.fill(
            child: Container(
              color: Colors.black.withOpacity(0.4),
            ),
          ),

          // Main Content
          SafeArea(
            child: SingleChildScrollView(
              padding: const EdgeInsets.symmetric(horizontal: 32.0),
              child: Column(
                children: [
                   const SizedBox(height: 48),
                   _buildHeader(),
                   const SizedBox(height: 48),
                   _buildStepContent(authState),
                   const SizedBox(height: 48),
                   _buildFooter(),
                   const SizedBox(height: 32),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildHeader() {
    return Column(
      children: [
        // Main Logo
        Container(
          width: 80,
          height: 80,
          decoration: BoxDecoration(
            color: Colors.black.withOpacity(0.4),
            borderRadius: BorderRadius.circular(20),
            border: Border.all(color: Colors.white.withOpacity(0.1)),
          ),
          child: Padding(
            padding: const EdgeInsets.all(12),
            child: Image.asset(
              'assets/m4_family_logo.png',
              color: const Color(0xFFFFD700),
              colorBlendMode: BlendMode.srcIn,
            ),
          ),
        ).animate().scale(duration: 500.ms, curve: Curves.easeOut),
        
        const SizedBox(height: 24),
        
        Text(
          'M4 FAMILY',
          style: GoogleFonts.montserrat(
            fontSize: 28,
            fontWeight: FontWeight.bold,
            color: Colors.white,
            letterSpacing: 2,
          ),
        ).animate().fadeIn(delay: 200.ms),
        
        const SizedBox(height: 8),
        
        Text(
          'CORPORATE IDENTITY & PREMIUM ASSETS',
          textAlign: TextAlign.center,
          style: GoogleFonts.montserrat(
            fontSize: 10,
            fontWeight: FontWeight.w600,
            color: Colors.white54,
            letterSpacing: 3,
          ),
        ).animate().fadeIn(delay: 400.ms),
      ],
    );
  }

  Widget _buildStepContent(AuthState authState) {
    return AnimatedSwitcher(
      duration: const Duration(milliseconds: 300),
      child: _step == 0 
        ? _buildOptions() 
        : _step == 1 
          ? _buildPhoneInput(authState) 
          : _buildOtpInput(authState),
    );
  }

  Widget _buildOptions() {
    return Column(
      key: const ValueKey('options'),
      children: [
        _PremiumButton(
          label: 'CONTINUE WITH PHONE',
          icon: LucideIcons.phone,
          isPrimary: true,
          onTap: () => setState(() {
            _selectedRole = 'CUSTOMER';
            _step = 1;
          }),
        ),
        const SizedBox(height: 16),
        _PremiumButton(
          label: 'BROWSE AS GUEST',
          icon: LucideIcons.building2,
          onTap: () => context.go('/home'),
        ),
        const SizedBox(height: 32),
        _PremiumButton(
          label: 'CHANNEL PARTNER',
          icon: LucideIcons.sparkles,
          iconColor: Colors.purpleAccent,
          onTap: () => context.push('/auth/cp/login'),
        ),
        const SizedBox(height: 12),
        _PremiumButton(
          label: 'INVESTOR PORTAL',
          icon: LucideIcons.trendingUp,
          iconColor: Colors.amber,
          onTap: () => setState(() {
            _selectedRole = 'INVESTOR';
            _step = 1;
          }),
        ),
      ],
    );
  }

  Widget _buildPhoneInput(AuthState authState) {
    return Column(
      key: const ValueKey('phone'),
      children: [
        Row(
          children: [
            IconButton(
              icon: const Icon(LucideIcons.chevronLeft, color: Colors.white),
              onPressed: () => setState(() => _step = 0),
            ),
            const SizedBox(width: 8),
            Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  'PHONE GATEWAY',
                  style: GoogleFonts.montserrat(
                    fontSize: 24,
                    fontWeight: FontWeight.bold,
                    color: Colors.white,
                    letterSpacing: 1,
                  ),
                ),
                Text(
                  'SECURE MULTI-FACTOR AUTHENTICATION',
                  style: GoogleFonts.montserrat(
                    fontSize: 10,
                    fontWeight: FontWeight.w600,
                    color: Colors.white54,
                    letterSpacing: 1,
                  ),
                ),
              ],
            ),
          ],
        ),
        const SizedBox(height: 48),
        _LuxuryInputField(
          controller: _phoneController,
          label: 'WHATSAPP NUMBER (WITH COUNTRY CODE)',
          hint: '+971 50 XXX XXXX',
          icon: LucideIcons.phone,
          keyboardType: TextInputType.phone,
        ),
        const SizedBox(height: 32),
        SizedBox(
          width: double.infinity,
          height: 64,
          child: ElevatedButton(
            onPressed: authState.status == AuthStatus.loading
                ? null
                : () => ref.read(authProvider.notifier).sendOtp(_phoneController.text, _selectedRole),
            style: ElevatedButton.styleFrom(
              backgroundColor: Colors.white,
              foregroundColor: Colors.black,
              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
              padding: const EdgeInsets.symmetric(horizontal: 24),
            ),
            child: authState.status == AuthStatus.loading
              ? const SizedBox(width: 24, height: 24, child: CircularProgressIndicator(color: Colors.black, strokeWidth: 2))
              : Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Text(
                      'REQUEST TOKEN',
                      style: GoogleFonts.montserrat(fontWeight: FontWeight.bold, letterSpacing: 2),
                    ),
                    const Icon(LucideIcons.arrowRight, size: 20),
                  ],
                ),
          ),
        ),
      ],
    );
  }

  Widget _buildOtpInput(AuthState authState) {
    return Column(
      key: const ValueKey('otp'),
      children: [
        Row(
          children: [
            IconButton(
              icon: const Icon(LucideIcons.chevronLeft, color: Colors.white),
              onPressed: () => setState(() => _step = 1),
            ),
            const SizedBox(width: 8),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    'FINAL CHECK',
                    style: GoogleFonts.montserrat(
                      fontSize: 24,
                      fontWeight: FontWeight.bold,
                      color: Colors.white,
                      letterSpacing: 1,
                    ),
                  ),
                  Text(
                    'WHATSAPP CODE SENT TO ${authState.identifier}',
                    overflow: TextOverflow.ellipsis,
                    style: GoogleFonts.montserrat(
                      fontSize: 10,
                      fontWeight: FontWeight.w600,
                      color: Colors.white54,
                      letterSpacing: 1,
                    ),
                  ),
                ],
              ),
            ),
          ],
        ),
        const SizedBox(height: 32),
        
        if (authState.devOtp != null) ...[
          Container(
            padding: const EdgeInsets.all(16),
            decoration: BoxDecoration(
              color: Colors.amber.withOpacity(0.1),
              borderRadius: BorderRadius.circular(16),
              border: Border.all(color: Colors.amber.withOpacity(0.3)),
            ),
            child: Row(
              children: [
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      const Text(
                        '⚡ DEV MODE — SIMULATED OTP',
                        style: TextStyle(color: Colors.amber, fontSize: 8, fontWeight: FontWeight.bold),
                      ),
                      const SizedBox(height: 4),
                      Text(
                        authState.devOtp!,
                        style: GoogleFonts.montserrat(
                          fontSize: 24,
                          fontWeight: FontWeight.bold,
                          color: Colors.amber,
                          letterSpacing: 4,
                        ),
                      ),
                    ],
                  ),
                ),
                TextButton(
                  onPressed: () {
                    for (int i = 0; i < 6; i++) {
                      if (i < authState.devOtp!.length) {
                        _otpControllers[i].text = authState.devOtp![i];
                      }
                    }
                  },
                  style: TextButton.styleFrom(
                    backgroundColor: Colors.amber.withOpacity(0.2),
                  ),
                  child: const Text('AUTO-FILL', style: TextStyle(color: Colors.amber, fontSize: 10, fontWeight: FontWeight.bold)),
                ),
              ],
            ),
          ).animate().fadeIn(),
          const SizedBox(height: 32),
        ],

        Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: List.generate(6, (index) {
            return SizedBox(
              width: 45,
              height: 60,
              child: TextField(
                controller: _otpControllers[index],
                focusNode: _focusNodes[index],
                textAlign: TextAlign.center,
                keyboardType: TextInputType.number,
                maxLength: 1,
                style: const TextStyle(color: Colors.white, fontSize: 24, fontWeight: FontWeight.bold),
                decoration: InputDecoration(
                  counterText: "",
                  enabledBorder: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(12),
                    borderSide: BorderSide(color: Colors.white.withOpacity(0.1)),
                  ),
                  focusedBorder: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(12),
                    borderSide: const BorderSide(color: Colors.white),
                  ),
                  fillColor: Colors.white.withOpacity(0.05),
                  filled: true,
                ),
                onChanged: (value) => _onOtpChanged(value, index),
              ),
            );
          }),
        ),
        const SizedBox(height: 48),
        SizedBox(
          width: double.infinity,
          height: 64,
          child: ElevatedButton(
            onPressed: authState.status == AuthStatus.loading
                ? null
                : () {
                    final code = _otpControllers.map((c) => c.text).join();
                    if (code.length == 6) {
                      ref.read(authProvider.notifier).verifyOtp(code);
                    }
                  },
            style: ElevatedButton.styleFrom(
              backgroundColor: Colors.white,
              foregroundColor: Colors.black,
              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
            ),
            child: authState.status == AuthStatus.loading
              ? const CircularProgressIndicator(color: Colors.black)
              : Text(
                  'AUTHENTICATE TOKEN',
                  style: GoogleFonts.montserrat(fontWeight: FontWeight.bold, letterSpacing: 2),
                ),
          ),
        ),
        const SizedBox(height: 32),
        TextButton(
          onPressed: () => ref.read(authProvider.notifier).sendOtp(_phoneController.text, _selectedRole),
          child: Text(
            'RESEND CODE',
            style: GoogleFonts.montserrat(
              fontSize: 10,
              fontWeight: FontWeight.bold,
              color: Colors.white54,
              letterSpacing: 2,
            ),
          ),
        ),
      ],
    );
  }

  Widget _buildFooter() {
    return Opacity(
      opacity: 0.5,
      child: Column(
        children: [
          Text(
            'M4 FAMILY SECURE ACCESS',
            style: GoogleFonts.montserrat(
              fontSize: 9,
              fontWeight: FontWeight.bold,
              color: Colors.white,
              letterSpacing: 2,
            ),
          ),
          const SizedBox(height: 4),
          Text(
            'V2.4.0 • ENCRYPTED',
            style: GoogleFonts.montserrat(
              fontSize: 8,
              color: Colors.white,
              letterSpacing: 1.5,
            ),
          ),
        ],
      ),
    );
  }
}

class _PremiumButton extends StatelessWidget {
  final String label;
  final IconData icon;
  final bool isPrimary;
  final Color? iconColor;
  final VoidCallback onTap;

  const _PremiumButton({
    required this.label,
    required this.icon,
    this.isPrimary = false,
    this.iconColor,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        height: 64,
        padding: const EdgeInsets.symmetric(horizontal: 24),
        decoration: BoxDecoration(
          color: isPrimary ? Colors.white : Colors.black.withOpacity(0.4),
          borderRadius: BorderRadius.circular(16),
          border: Border.all(color: Colors.white.withOpacity(0.1)),
        ),
        child: Row(
          children: [
            Icon(
              icon,
              color: isPrimary ? Colors.black : (iconColor ?? Colors.white54),
              size: 20,
            ),
            const SizedBox(width: 16),
            Text(
              label,
              style: GoogleFonts.montserrat(
                fontSize: 11,
                fontWeight: FontWeight.bold,
                color: isPrimary ? Colors.black : Colors.white,
                letterSpacing: 2,
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _LuxuryInputField extends StatelessWidget {
  final TextEditingController controller;
  final String label;
  final String hint;
  final IconData icon;
  final TextInputType keyboardType;

  const _LuxuryInputField({
    required this.controller,
    required this.label,
    required this.hint,
    required this.icon,
    required this.keyboardType,
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
            letterSpacing: 1.5,
          ),
        ),
        const SizedBox(height: 12),
        Container(
          height: 64,
          decoration: BoxDecoration(
            color: Colors.white.withOpacity(0.05),
            borderRadius: BorderRadius.circular(16),
            border: Border.all(color: Colors.white.withOpacity(0.1)),
          ),
          child: TextField(
            controller: controller,
            keyboardType: keyboardType,
            style: const TextStyle(color: Colors.white, fontSize: 18, fontWeight: FontWeight.bold),
            decoration: InputDecoration(
              hintText: hint,
              hintStyle: TextStyle(color: Colors.white.withOpacity(0.2)),
              prefixIcon: Icon(icon, color: Colors.white54, size: 20),
              border: InputBorder.none,
              contentPadding: const EdgeInsets.symmetric(horizontal: 20, vertical: 16),
            ),
          ),
        ),
      ],
    );
  }
}
