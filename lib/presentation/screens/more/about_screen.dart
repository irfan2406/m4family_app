import 'package:flutter/material.dart';
import 'package:flutter/cupertino.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:lucide_icons/lucide_icons.dart';
import 'package:m4_mobile/core/theme/app_theme.dart';
import 'package:flutter_animate/flutter_animate.dart';

class AboutScreen extends StatefulWidget {
  const AboutScreen({super.key});

  @override
  State<AboutScreen> createState() => _AboutScreenState();
}

class _AboutScreenState extends State<AboutScreen> {
  int _activeTab = 0;
  final List<Map<String, dynamic>> _tabs = [
    {'name': 'ABOUT', 'icon': LucideIcons.users},
    {'name': 'JOURNEY', 'icon': LucideIcons.milestone},
    {'name': '4 PILLARS', 'icon': LucideIcons.shieldCheck},
    {'name': 'PHILOSOPHY', 'icon': LucideIcons.eye},
    {'name': 'CUSTOM VIEWS', 'icon': LucideIcons.compass},
  ];

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;

    return Scaffold(
      backgroundColor: isDark ? const Color(0xFF0F1115) : const Color(0xFFF9FAFB),
      appBar: AppBar(
        backgroundColor: Colors.transparent,
        elevation: 0,
        leading: IconButton(
          icon: Icon(LucideIcons.chevronLeft, color: isDark ? Colors.white : Colors.black),
          onPressed: () => Navigator.pop(context),
        ),
        title: Column(
          children: [
            Text(
              'WHO WE ARE',
              style: GoogleFonts.montserrat(fontSize: 14, fontWeight: FontWeight.w900, color: isDark ? Colors.white : Colors.black, letterSpacing: 1),
            ),
            Text(
              'M4 FAMILY COLLECTIVE',
              style: GoogleFonts.montserrat(fontSize: 8, fontWeight: FontWeight.w900, color: M4Theme.premiumBlue, letterSpacing: 1.5),
            ),
          ],
        ),
        actions: [
          Container(
            margin: const EdgeInsets.only(right: 16),
            padding: const EdgeInsets.all(8),
            decoration: BoxDecoration(color: isDark ? Colors.white.withOpacity(0.05) : Colors.black.withOpacity(0.05), shape: BoxShape.circle),
            child: const Icon(LucideIcons.moreHorizontal, size: 16),
          ),
        ],
      ),
      body: SingleChildScrollView(
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const SizedBox(height: 32),
            
            // Premium Navigation Pills
            SizedBox(
              height: 80,
              child: ListView.builder(
                padding: const EdgeInsets.symmetric(horizontal: 24),
                scrollDirection: Axis.horizontal,
                itemCount: _tabs.length,
                itemBuilder: (context, index) {
                  final isActive = _activeTab == index;
                  return GestureDetector(
                    onTap: () => setState(() => _activeTab = index),
                    child: Container(
                      margin: const EdgeInsets.only(right: 20),
                      child: Column(
                        children: [
                          Container(
                            width: 48,
                            height: 48,
                            decoration: BoxDecoration(
                              color: isActive ? Colors.black : (isDark ? Colors.white.withOpacity(0.05) : Colors.white),
                              shape: BoxShape.circle,
                              border: Border.all(color: isActive ? Colors.black : (isDark ? Colors.white10 : Colors.black.withOpacity(0.05))),
                              boxShadow: isActive ? [BoxShadow(color: Colors.black.withOpacity(0.2), blurRadius: 10, offset: const Offset(0, 4))] : [],
                            ),
                            child: Icon(_tabs[index]['icon'], color: isActive ? Colors.white : (isDark ? Colors.white38 : Colors.black38), size: 20),
                          ),
                          const SizedBox(height: 8),
                          Text(
                            _tabs[index]['name'],
                            style: GoogleFonts.montserrat(fontSize: 7, fontWeight: FontWeight.w900, color: isActive ? (isDark ? Colors.white : Colors.black) : (isDark ? Colors.white24 : Colors.black26), letterSpacing: 1),
                          ),
                        ],
                      ),
                    ),
                  );
                },
              ),
            ),
            
            const SizedBox(height: 32),
            
            // Hero Image Card
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 24),
              child: Container(
                height: 240,
                width: double.infinity,
                decoration: BoxDecoration(
                  borderRadius: BorderRadius.circular(40),
                  image: const DecorationImage(
                    image: NetworkImage('https://images.unsplash.com/photo-1512917774080-9991f1c4c750?auto=format&fit=crop&q=80'),
                    fit: BoxFit.cover,
                  ),
                  boxShadow: [BoxShadow(color: Colors.black.withOpacity(0.2), blurRadius: 40, offset: const Offset(0, 20))],
                ),
                child: Container(
                  decoration: BoxDecoration(
                    borderRadius: BorderRadius.circular(40),
                    gradient: LinearGradient(
                      begin: Alignment.topCenter,
                      end: Alignment.bottomCenter,
                      colors: [Colors.transparent, Colors.black.withOpacity(0.7)],
                    ),
                  ),
                  padding: const EdgeInsets.all(32),
                  child: Column(
                    mainAxisAlignment: MainAxisAlignment.end,
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        'THE COLLECTIVE',
                        style: GoogleFonts.montserrat(fontSize: 12, fontWeight: FontWeight.w900, color: Colors.white70, letterSpacing: 2),
                      ),
                      Text(
                        'M4 LEGACY',
                        style: GoogleFonts.montserrat(fontSize: 32, fontWeight: FontWeight.w900, color: Colors.white, letterSpacing: -1, height: 1),
                      ),
                    ],
                  ),
                ),
              ),
            ).animate().fadeIn().scale(begin: const Offset(0.95, 0.95)),
            
            const SizedBox(height: 48),
            
            // Story Section
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 24),
              child: Row(
                children: [
                  Container(
                    width: 48,
                    height: 48,
                    decoration: BoxDecoration(
                      color: isDark ? Colors.white.withOpacity(0.05) : Colors.white,
                      borderRadius: BorderRadius.circular(16),
                      border: Border.all(color: isDark ? Colors.white10 : Colors.black.withOpacity(0.05)),
                    ),
                    child: const Icon(LucideIcons.briefcase, size: 20),
                  ),
                  const SizedBox(width: 20),
                  Text(
                    'OUR STORY',
                    style: GoogleFonts.montserrat(fontSize: 16, fontWeight: FontWeight.w900, color: isDark ? Colors.white : Colors.black, letterSpacing: -0.5),
                  ),
                ],
              ),
            ),
            
            const SizedBox(height: 32),
            
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 24),
              child: Container(
                padding: const EdgeInsets.all(32),
                decoration: BoxDecoration(
                  color: isDark ? Colors.white.withOpacity(0.02) : Colors.white,
                  borderRadius: BorderRadius.circular(40),
                  border: Border.all(color: isDark ? Colors.white10 : Colors.black.withOpacity(0.05)),
                ),
                child: Column(
                  children: [
                    Text(
                      '"M4 Family, with over a decade of excellence in Mumbai\'s real estate landscape, has established itself as a trusted name in premium residential development."',
                      style: GoogleFonts.montserrat(fontSize: 14, color: isDark ? Colors.white70 : Colors.black87, height: 1.8, fontStyle: FontStyle.italic, fontWeight: FontWeight.w500),
                    ),
                    const SizedBox(height: 24),
                    Text(
                      'Renowned for delivering homes that blend contemporary design with timeless aesthetics, every development we undertake is a testament to our commitment to quality and institutional standards.',
                      style: GoogleFonts.montserrat(fontSize: 13, color: isDark ? Colors.white38 : Colors.black45, height: 1.8, fontWeight: FontWeight.w600),
                    ),
                  ],
                ),
              ),
            ).animate().fadeIn(delay: 400.ms),
            
            const SizedBox(height: 100),
          ],
        ),
      ),
    );
  }
}
