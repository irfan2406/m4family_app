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

class _OnboardingScreenState extends State<OnboardingScreen> {
  final PageController _pageController = PageController();
  int _currentPage = 0;

  final List<OnboardingData> _pages = [
    OnboardingData(
      title: 'DISCOVER FUTURE\nLIVING',
      subtitle: 'Experience visionary high-rise living with signature architecture and panoramic sea views.',
      imageUrl: 'https://images.unsplash.com/photo-1545324418-cc1a3fa10c00?q=80&w=1000&auto=format&fit=crop',
    ),
    OnboardingData(
      title: 'CRAFT YOUR\nSANCTUARY',
      subtitle: 'Bespoke interiors designed with premium finishes and smart home technology.',
      imageUrl: 'https://images.unsplash.com/photo-1618221195710-dd6b41faaea6?q=80&w=1000&auto=format&fit=crop',
    ),
    OnboardingData(
      title: 'ELEVATED\nLIFESTYLE',
      subtitle: 'Access world-class amenities including an infinity pool and exclusive premium lounge.',
      imageUrl: 'https://images.unsplash.com/photo-1572120360610-d971b9d7767c?q=80&w=1000&auto=format&fit=crop',
    ),
  ];

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: Stack(
        children: [
          // Background PageView
          PageView.builder(
            controller: _pageController,
            itemCount: _pages.length,
            onPageChanged: (index) => setState(() => _currentPage = index),
            itemBuilder: (context, index) {
              return Stack(
                fit: StackFit.expand,
                children: [
                  Image.network(
                    _pages[index].imageUrl,
                    fit: BoxFit.cover,
                  ),
                  // Dark Overlay Gradient
                  Container(
                    decoration: BoxDecoration(
                      gradient: LinearGradient(
                        begin: Alignment.topCenter,
                        end: Alignment.bottomCenter,
                        colors: [
                          Colors.black.withOpacity(0.3),
                          Colors.black.withOpacity(0.8),
                        ],
                      ),
                    ),
                  ),
                ],
              );
            },
          ),

          // Content
          SafeArea(
            child: Padding(
              padding: const EdgeInsets.symmetric(horizontal: 40.0, vertical: 24.0),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  const Spacer(flex: 3),
                  
                  // Progress Indicators
                  Row(
                    children: List.generate(_pages.length, (index) {
                      return AnimatedContainer(
                        duration: 300.ms,
                        margin: const EdgeInsets.only(right: 8),
                        height: 2,
                        width: index == _currentPage ? 40 : 20,
                        color: index == _currentPage ? M4Theme.premiumBlue : Colors.white30,
                      );
                    }),
                  ).animate().fadeIn(delay: 200.ms),
                  
                  const SizedBox(height: 32),
                  
                  // Title
                  Text(
                    _pages[_currentPage].title,
                    style: GoogleFonts.montserrat(
                      fontSize: 32,
                      fontWeight: FontWeight.bold,
                      color: Colors.white,
                      height: 1.1,
                      letterSpacing: 1,
                    ),
                  ).animate(key: ValueKey('title_$_currentPage')).fadeIn(duration: 600.ms).slideX(begin: 0.1, end: 0),
                  
                  const SizedBox(height: 24),
                  
                  // Subtitle
                  Text(
                    _pages[_currentPage].subtitle,
                    style: GoogleFonts.montserrat(
                      fontSize: 14,
                      color: Colors.white70,
                      height: 1.6,
                    ),
                  ).animate(key: ValueKey('subtitle_$_currentPage')).fadeIn(delay: 200.ms),
                  
                  const Spacer(flex: 1),
                  
                  // Navigation
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      TextButton(
                        onPressed: () => context.go('/login'),
                        child: Text(
                          'SKIP',
                          style: GoogleFonts.montserrat(
                            fontSize: 10,
                            fontWeight: FontWeight.bold,
                            color: Colors.white,
                            letterSpacing: 2,
                          ),
                        ),
                      ),
                      
                      ElevatedButton(
                        onPressed: () {
                          if (_currentPage < _pages.length - 1) {
                            _pageController.nextPage(
                              duration: 500.ms,
                              curve: Curves.easeInOut,
                            );
                          } else {
                            context.go('/login');
                          }
                        },
                        style: ElevatedButton.styleFrom(
                          backgroundColor: Colors.white,
                          foregroundColor: Colors.black,
                          padding: const EdgeInsets.symmetric(horizontal: 32, vertical: 16),
                          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(30)),
                        ),
                        child: Row(
                          mainAxisSize: MainAxisSize.min,
                          children: [
                            Text(
                              _currentPage == _pages.length - 1 ? 'GET STARTED' : 'NEXT',
                              style: const TextStyle(fontWeight: FontWeight.bold),
                            ),
                            const SizedBox(width: 8),
                            const Icon(LucideIcons.chevronRight, size: 16),
                          ],
                        ),
                      ),
                    ],
                  ).animate().fadeIn(delay: 400.ms),
                  
                  const SizedBox(height: 20),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }
}

class OnboardingData {
  final String title;
  final String subtitle;
  final String imageUrl;

  OnboardingData({
    required this.title,
    required this.subtitle,
    required this.imageUrl,
  });
}
