import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:m4_mobile/core/theme/app_theme.dart';
import 'package:go_router/go_router.dart';
import 'package:flutter_animate/flutter_animate.dart';
import 'package:lucide_icons/lucide_icons.dart';

class OnboardingScreen extends StatefulWidget {
  const OnboardingScreen({super.key});

  @override
  State<OnboardingScreen> createState() => _OnboardingScreenState();
}

class _OnboardingScreenState extends State<OnboardingScreen> with SingleTickerProviderStateMixin {
  late AnimationController _controller;

  @override
  void initState() {
    super.initState();
    _controller = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 1800),
    )..forward().then((_) {
        if (mounted) {
          context.go('/home');
        }
      });
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.black,
      body: Stack(
        fit: StackFit.expand,
        children: [
          // Pure Black Background
          Positioned.fill(
            child: Container(color: Colors.black),
          ),
          
          // Main Animation Stack
          Center(
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                // Logo Container (Centered and Clean)
                Container(
                  padding: const EdgeInsets.all(24),
                  child: Image.asset(
                    'assets/m4_family_logo.png',
                    width: 220,
                    fit: BoxFit.contain,
                    color: Colors.white,
                  )
                  .animate()
                  .fadeIn(duration: 1500.ms, curve: Curves.easeOut)
                  .moveY(begin: 10, end: 0, duration: 1500.ms, curve: Curves.easeOut),
                ),
              ],
            ),
          ),

          // Footer Section
          Positioned(
            bottom: 64,
            left: 0,
            right: 0,
            child: Column(
              children: [
                // Minimal Progress Line
                Container(
                  width: 160,
                  height: 1,
                  decoration: BoxDecoration(
                    color: Colors.white.withOpacity(0.05),
                    borderRadius: BorderRadius.circular(1),
                  ),
                  clipBehavior: Clip.antiAlias,
                  child: Stack(
                    children: [
                      Positioned.fill(
                        child: FractionallySizedBox(
                          alignment: Alignment.centerLeft,
                          widthFactor: 1.0,
                          child: Container(
                            decoration: BoxDecoration(
                              color: Colors.white.withOpacity(0.6),
                              boxShadow: [
                                BoxShadow(
                                  color: Colors.white.withOpacity(0.4),
                                  blurRadius: 4,
                                ),
                              ],
                            ),
                          ).animate().moveX(begin: -160, end: 160, duration: 1800.ms, curve: Curves.linear),
                        ),
                      ),
                    ],
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}


