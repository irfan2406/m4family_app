import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:m4_mobile/core/theme/app_theme.dart';
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
  final TextEditingController _otpController = TextEditingController();
  bool _showPhoneInput = false;
  String _selectedRole = 'CUSTOMER';

  @override
  Widget build(BuildContext context) {
    final authState = ref.watch(authProvider);

    ref.listen(authProvider, (previous, next) {
      if (next.status == AuthStatus.authenticated) {
        context.go('/home');
      } else if (next.status == AuthStatus.error) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text(next.error ?? 'Error occurred')),
        );
      }
    });

    return Scaffold(
      body: Stack(
        fit: StackFit.expand,
        children: [
          // Background Image
          Image.network(
            'https://images.unsplash.com/photo-1512917774080-9991f1c4c750?q=80&w=1000&auto=format&fit=crop',
            fit: BoxFit.cover,
          ),
          // Dark Overlay
          Container(
            color: Colors.black.withOpacity(0.85),
          ),
          
          SafeArea(
            child: Padding(
              padding: const EdgeInsets.symmetric(horizontal: 40.0),
              child: Column(
                children: [
                  const SizedBox(height: 64),
                  // Logo Icon
                  Container(
                    padding: const EdgeInsets.all(12),
                    decoration: BoxDecoration(
                      borderRadius: BorderRadius.circular(16),
                      border: Border.all(color: Colors.white24),
                      color: Colors.white.withOpacity(0.05),
                    ),
                    child: const Icon(LucideIcons.building2, color: Colors.white, size: 32),
                  ).animate().fadeIn(duration: 800.ms).scale(begin: const Offset(0.8, 0.8)),
                  
                  const SizedBox(height: 24),
                  
                  // Title
                  Text(
                    'M4 FAMILY',
                    style: GoogleFonts.montserrat(
                      fontSize: 28,
                      fontWeight: FontWeight.bold,
                      color: Colors.white,
                      letterSpacing: 2,
                    ),
                  ).animate().fadeIn(delay: 200.ms),
                  
                  // Subtitle
                  Text(
                    'CORPORATE IDENTITY & PREMIUM ASSETS',
                    textAlign: TextAlign.center,
                    style: GoogleFonts.montserrat(
                      fontSize: 10,
                      fontWeight: FontWeight.w600,
                      color: Colors.white54,
                      letterSpacing: 1.5,
                    ),
                  ).animate().fadeIn(delay: 400.ms),
                  
                  const Spacer(),
                  
                  if (authState.status == AuthStatus.otpSent) ...[
                    // Final Check View
                    Align(
                      alignment: Alignment.centerLeft,
                      child: IconButton(
                        icon: const Icon(LucideIcons.arrowLeft, color: Colors.white),
                        onPressed: () => ref.read(authProvider.notifier).reset(),
                      ),
                    ).animate().fadeIn(),
                    const SizedBox(height: 16),
                    
                    Text(
                      'FINAL CHECK',
                      style: GoogleFonts.montserrat(fontSize: 28, fontWeight: FontWeight.bold, color: Colors.white, letterSpacing: 1.5),
                    ),
                    Text(
                      'WHATSAPP CODE SENT TO ${authState.identifier}',
                      style: GoogleFonts.montserrat(color: Colors.white54, fontSize: 10, fontWeight: FontWeight.bold, letterSpacing: 1.2),
                    ),
                    
                    if (authState.devOtp != null) ...[
                      const SizedBox(height: 32),
                      Container(
                        padding: const EdgeInsets.all(16),
                        decoration: BoxDecoration(
                          color: Colors.amber.withOpacity(0.1),
                          borderRadius: BorderRadius.circular(12),
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
                                      letterSpacing: 8,
                                    ),
                                  ),
                                ],
                              ),
                            ),
                            TextButton(
                              onPressed: () => _otpController.text = authState.devOtp!,
                              style: TextButton.styleFrom(
                                backgroundColor: Colors.amber.withOpacity(0.2),
                                padding: const EdgeInsets.symmetric(horizontal: 16),
                              ),
                              child: const Text('AUTO-FILL', style: TextStyle(color: Colors.amber, fontSize: 10, fontWeight: FontWeight.bold)),
                            ),
                          ],
                        ),
                      ).animate().fadeIn().scale(begin: const Offset(0.9, 0.9)),
                    ],

                    const SizedBox(height: 32),
                    _LuxuryInput(
                      controller: _otpController,
                      hint: 'Enter token',
                      icon: LucideIcons.shieldCheck,
                      keyboardType: TextInputType.number,
                    ),
                    const SizedBox(height: 24),
                    SizedBox(
                      width: double.infinity,
                      child: _ActionButton(
                        label: 'AUTHENTICATE TOKEN',
                        onPressed: authState.status == AuthStatus.loading
                            ? null
                            : () => ref.read(authProvider.notifier).verifyOtp(_otpController.text),
                      ),
                    ),
                    const SizedBox(height: 24),
                    Center(
                      child: TextButton(
                        onPressed: null,
                        child: Text(
                          'RESEND CODE',
                          style: GoogleFonts.montserrat(color: Colors.white24, fontSize: 10, fontWeight: FontWeight.bold, letterSpacing: 1.5),
                        ),
                      ),
                    ),
                  ] else if (!_showPhoneInput) ...[
                    // Role Portal Selection
                    const Text(
                      'SELECT YOUR PORTAL',
                      style: TextStyle(fontSize: 10, fontWeight: FontWeight.bold, letterSpacing: 1.5, color: Colors.white54),
                    ),
                    const SizedBox(height: 16),
                    _LoginButton(
                      label: 'CONTINUE WITH PHONE',
                      icon: LucideIcons.phone,
                      isPrimary: true,
                      onTap: () => setState(() => _showPhoneInput = true),
                    ),
                    const SizedBox(height: 16),
                    _LoginButton(
                      label: 'BROWSE AS GUEST',
                      icon: LucideIcons.user,
                      onTap: () => context.go('/home'),
                    ),
                    const SizedBox(height: 16),
                    _LoginButton(
                      label: 'CHANNEL PARTNER',
                      icon: LucideIcons.users,
                      accentColor: Colors.purpleAccent,
                      onTap: () => setState(() {
                        _selectedRole = 'CP';
                        _showPhoneInput = true;
                      }),
                    ),
                    const SizedBox(height: 16),
                    _LoginButton(
                      label: 'INVESTOR PORTAL',
                      icon: LucideIcons.trendingUp,
                      accentColor: M4Theme.premiumBlue,
                      onTap: () => setState(() {
                        _selectedRole = 'INVESTOR';
                        _showPhoneInput = true;
                      }),
                    ),
                  ] else ...[
                    // Phone Gateway View
                    Align(
                      alignment: Alignment.centerLeft,
                      child: IconButton(
                        icon: const Icon(LucideIcons.arrowLeft, color: Colors.white),
                        onPressed: () => setState(() => _showPhoneInput = false),
                      ),
                    ).animate().fadeIn(),
                    const SizedBox(height: 16),
                    
                    Text(
                      'PHONE GATEWAY',
                      style: GoogleFonts.montserrat(fontSize: 28, fontWeight: FontWeight.bold, color: Colors.white, letterSpacing: 1.5),
                    ),
                    const Text(
                      'SECURE MULTI-FACTOR AUTHENTICATION',
                      style: TextStyle(color: Colors.white54, fontSize: 10, fontWeight: FontWeight.bold, letterSpacing: 1.2),
                    ),
                    const SizedBox(height: 48),

                    const Text(
                      'WHATSAPP NUMBER (WITH COUNTRY CODE)',
                      style: TextStyle(fontSize: 9, fontWeight: FontWeight.bold, letterSpacing: 1.2, color: Colors.white54),
                    ),
                    const SizedBox(height: 12),
                    
                    _LuxuryInput(
                      controller: _phoneController,
                      hint: '+971 50 XXX XXXX',
                      icon: LucideIcons.phone,
                      keyboardType: TextInputType.phone,
                    ),
                    const SizedBox(height: 24),
                    
                    const Text(
                      'A secure one-time access token will be dispatched via\nWhatsApp for identity validation.',
                      textAlign: TextAlign.center,
                      style: TextStyle(color: Colors.white24, fontSize: 8),
                    ),
                    const SizedBox(height: 32),
                    
                    SizedBox(
                      width: double.infinity,
                      child: _ActionButton(
                        label: 'REQUEST TOKEN',
                        showArrow: true,
                        onPressed: authState.status == AuthStatus.loading
                            ? null
                            : () => ref.read(authProvider.notifier).sendOtp(_phoneController.text, _selectedRole),
                      ),
                    ),
                  ],
                  
                  const Spacer(),
                  
                  // Footer
                  Text(
                    'M4 FAMILY SECURE ACCESS\nV2.4.0 - ENCRYPTED',
                    textAlign: TextAlign.center,
                    style: GoogleFonts.montserrat(
                      fontSize: 8,
                      fontWeight: FontWeight.bold,
                      color: Colors.white24,
                      letterSpacing: 1.2,
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

class _LoginButton extends StatelessWidget {
  final String label;
  final IconData icon;
  final bool isPrimary;
  final Color? accentColor;
  final VoidCallback? onTap;

  const _LoginButton({
    required this.label,
    required this.icon,
    this.isPrimary = false,
    this.accentColor,
    this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        padding: const EdgeInsets.symmetric(vertical: 16, horizontal: 24),
        decoration: BoxDecoration(
          color: isPrimary ? Colors.white : Colors.white.withOpacity(0.05),
          borderRadius: BorderRadius.circular(12),
          border: Border.all(color: Colors.white.withOpacity(0.1)),
        ),
        child: Row(
          children: [
            Icon(
              icon,
              size: 20,
              color: isPrimary ? Colors.black : (accentColor ?? Colors.white),
            ),
            const SizedBox(width: 16),
            Expanded(
              child: Text(
                label,
                style: GoogleFonts.montserrat(
                  fontSize: 12,
                  fontWeight: FontWeight.bold,
                  color: isPrimary ? Colors.black : Colors.white,
                  letterSpacing: 1.1,
                ),
              ),
            ),
          ],
        ),
      ),
    ).animate().fadeIn(delay: 600.ms).slideY(begin: 0.1, end: 0);
  }
}

class _LuxuryInput extends StatelessWidget {
  final TextEditingController controller;
  final String hint;
  final IconData icon;
  final TextInputType keyboardType;

  const _LuxuryInput({
    required this.controller,
    required this.hint,
    required this.icon,
    required this.keyboardType,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      decoration: BoxDecoration(
        color: Colors.white.withOpacity(0.05),
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: Colors.white.withOpacity(0.1)),
      ),
      child: TextField(
        controller: controller,
        keyboardType: keyboardType,
        style: const TextStyle(color: Colors.white),
        decoration: InputDecoration(
          hintText: hint,
          hintStyle: const TextStyle(color: Colors.white24),
          prefixIcon: Icon(icon, color: Colors.white70, size: 20),
          border: InputBorder.none,
          contentPadding: const EdgeInsets.symmetric(horizontal: 20, vertical: 16),
        ),
      ),
    );
  }
}

class _ActionButton extends StatelessWidget {
  final String label;
  final VoidCallback? onPressed;
  final bool showArrow;

  const _ActionButton({
    required this.label,
    this.onPressed,
    this.showArrow = false,
  });

  @override
  Widget build(BuildContext context) {
    return ElevatedButton(
      onPressed: onPressed,
      style: ElevatedButton.styleFrom(
        backgroundColor: Colors.white,
        foregroundColor: Colors.black,
        padding: const EdgeInsets.symmetric(vertical: 16, horizontal: 24),
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(30)),
      ),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Text(
            label,
            style: GoogleFonts.montserrat(
              fontSize: 12,
              fontWeight: FontWeight.bold,
              letterSpacing: 1.2,
            ),
          ),
          if (showArrow) ...[
            const SizedBox(width: 12),
            const Icon(LucideIcons.arrowRight, size: 16),
          ],
        ],
      ),
    );
  }
}
