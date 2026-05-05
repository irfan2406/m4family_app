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
      duration: const Duration(seconds: 5),
    )..forward().then((_) {
        if (mounted) {
          context.go('/login');
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
          // Background Image with Subtle Zoom
          Positioned.fill(
            child: Opacity(
              opacity: 0.6,
              child: Image.asset(
                'assets/login-bg.png',
                fit: BoxFit.cover,
              )
                  .animate(onPlay: (controller) => controller.repeat(reverse: true))
                  .scale(
                    begin: const Offset(1.1, 1.1),
                    end: const Offset(1.0, 1.0),
                    duration: 5.seconds,
                    curve: Curves.easeOut,
                  ),
            ),
          ),
          
          // Gradient Overlay and Backdrop Blur
          Container(
            decoration: BoxDecoration(
              gradient: LinearGradient(
                begin: Alignment.topCenter,
                end: Alignment.bottomCenter,
                colors: [
                  Colors.black.withOpacity(0.0),
                  Colors.black.withOpacity(0.4),
                  Colors.black,
                ],
                stops: const [0, 0.4, 1],
              ),
            ),
          ),

          // Main Animation Stack
          Center(
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Stack(
                  alignment: Alignment.center,
                  children: [
                    // Floating Premium Particles
                    ...List.generate(8, (index) => FloatingParticle(index: index)),

                    // Logo Container (Centered and Clean)
                    Container(
                      padding: const EdgeInsets.all(24),
                      child: Stack(
                        alignment: Alignment.center,
                        children: [
                          // Main Gold Logo (Smaller size: 180)
                          Stack(
                            alignment: Alignment.center,
                            children: [
                              // Subtle Glow/Shadow layer for legibility
                              Image.asset(
                                'assets/m4_family_logo.png',
                                width: 180,
                                fit: BoxFit.contain,
                                color: const Color(0xFFFFD700).withOpacity(0.3),
                              ).animate().fadeIn(duration: 2.seconds).blur(begin: const Offset(0, 0), end: const Offset(10, 10)),

                              // Main vibrant logo layer
                              Image.asset(
                                'assets/m4_family_logo.png',
                                width: 180,
                                fit: BoxFit.contain,
                                color: const Color(0xFFFFD700),
                                colorBlendMode: BlendMode.srcIn,
                              )
                                  .animate()
                                  .fadeIn(duration: 2.seconds, curve: Curves.easeOut)
                                  .scale(begin: const Offset(0.9, 0.9), end: const Offset(1, 1), duration: 2.seconds, curve: const Cubic(0.16, 1, 0.3, 1))
                                  .moveY(begin: 20, end: 0, duration: 2.seconds)
                                  .animate(onPlay: (controller) => controller.repeat(reverse: true))
                                  .moveY(begin: -5, end: 5, duration: 6.seconds, curve: Curves.easeInOut),
                            ],
                          ),

                          // Diagonal Sweep Light Effect
                          ClipRect(
                            child: SizedBox(
                              width: 180,
                              height: 100,
                              child: Stack(
                                children: [
                                  Positioned.fill(
                                    child: Transform.rotate(
                                      angle: -0.3,
                                      child: Container(
                                        decoration: BoxDecoration(
                                          gradient: LinearGradient(
                                            begin: Alignment.topLeft,
                                            end: Alignment.bottomRight,
                                            colors: [
                                              Colors.transparent,
                                              Colors.white.withOpacity(0.5),
                                              Colors.transparent,
                                            ],
                                            stops: const [0.35, 0.5, 0.65],
                                          ),
                                        ),
                                      ).animate()
                                       .moveX(begin: -300, end: 300, delay: 500.ms, duration: 2.seconds, curve: Curves.easeInOut),
                                    ),
                                  ),
                                ],
                              ),
                            ),
                          ),
                        ],
                      ),
                    ),
                  ],
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
                // CORPORATE IDENTITY • PREMIUM ASSETS
                Text(
                  'CORPORATE IDENTITY • PREMIUM ASSETS',
                  style: GoogleFonts.montserrat(
                    fontSize: 10,
                    fontWeight: FontWeight.bold,
                    color: const Color(0xFFC6A355),
                    letterSpacing: 4,
                  ),
                ).animate().fadeIn(delay: 800.ms, duration: 1200.ms).moveY(begin: 10, end: 0),
                
                const SizedBox(height: 24),
                
                // Progress Line
                Container(
                  width: 160,
                  height: 1,
                  decoration: BoxDecoration(
                    color: Colors.white.withOpacity(0.1),
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
                            decoration: const BoxDecoration(
                              color: Color(0xFFC6A355),
                              boxShadow: [
                                BoxShadow(
                                  color: Color(0xFFC6A355),
                                  blurRadius: 4,
                                ),
                              ],
                            ),
                          ).animate().moveX(begin: -160, end: 160, duration: 5.seconds, curve: Curves.linear),
                        ),
                      ),
                    ],
                  ),
                ),
                
                const SizedBox(height: 24),
                
                // M4 PRIVATE ACCESS SYSTEM
                Text(
                  'M4 PRIVATE ACCESS SYSTEM',
                  style: GoogleFonts.montserrat(
                    fontSize: 11,
                    fontWeight: FontWeight.normal,
                    color: Colors.white.withOpacity(0.9),
                    letterSpacing: 5,
                  ),
                ).animate().fadeIn(delay: 1200.ms, duration: 1500.ms),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

class RotatingRaysPainter extends CustomPainter {
  @override
  void paint(Canvas canvas, Size size) {
    final center = Offset(size.width / 2, size.height / 2);
    final radius = size.width / 2;
    
    final paint = Paint()
      ..shader = SweepGradient(
        colors: [
          Colors.transparent,
          const Color(0xFFFFD700).withOpacity(0.05),
          Colors.transparent,
          const Color(0xFFFFD700).withOpacity(0.05),
          Colors.transparent,
          const Color(0xFFFFD700).withOpacity(0.05),
          Colors.transparent,
          const Color(0xFFFFD700).withOpacity(0.05),
          Colors.transparent,
        ],
        stops: const [0.0, 0.125, 0.25, 0.375, 0.5, 0.625, 0.75, 0.875, 1.0],
      ).createShader(Rect.fromCircle(center: center, radius: radius))
      ..maskFilter = const MaskFilter.blur(BlurStyle.normal, 80);

    canvas.drawCircle(center, radius, paint);
  }

  @override
  bool shouldRepaint(covariant CustomPainter oldDelegate) => false;
}

class FloatingParticle extends StatelessWidget {
  final int index;
  const FloatingParticle({super.key, required this.index});

  @override
  Widget build(BuildContext context) {
    return Positioned(
      child: Container(
        width: 3,
        height: 3,
        decoration: const BoxDecoration(
          color: Color(0xFFC6A355),
          shape: BoxShape.circle,
        ),
      )
          .animate(onPlay: (controller) => controller.repeat())
          .move(
            begin: Offset((index % 2 == 0 ? 1 : -1) * (100 + index * 5), (index % 3 == 0 ? 1 : -1) * (100 + index * 5)),
            end: Offset((index % 2 == 0 ? -1 : 1) * (100 + index * 5), (index % 3 == 0 ? -1 : 1) * (100 + index * 5)),
            duration: (8 + index * 0.5).seconds,
            curve: Curves.easeInOut,
          )
          .custom(
            begin: 0,
            end: 0.6,
            duration: 4.seconds,
            builder: (context, value, child) => Opacity(opacity: (value < 0.3) ? (value / 0.3) : (0.6 - value) / 0.3 * 0.6, child: child),
          ),
    );
  }
}

