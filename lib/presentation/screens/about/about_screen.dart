import 'dart:ui';
import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:lucide_icons/lucide_icons.dart';
import 'package:flutter_animate/flutter_animate.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:m4_mobile/core/network/api_client.dart';
import 'package:m4_mobile/presentation/widgets/sidebar_menu.dart';
import 'package:m4_mobile/presentation/widgets/main_shell.dart';
import 'package:m4_mobile/presentation/providers/auth_provider.dart';

class AboutScreen extends ConsumerStatefulWidget {
  const AboutScreen({super.key});

  @override
  ConsumerState<AboutScreen> createState() => _AboutScreenState();
}

class _AboutScreenState extends ConsumerState<AboutScreen> {
  int _currentStep = 0;
  Map<String, dynamic>? _cmsData;
  bool _isLoading = true;
  String? _error;

  static const List<Map<String, dynamic>> _steps = [
    {'id': 'about', 'label': 'About', 'icon': LucideIcons.users},
    {'id': 'journey', 'label': 'Journey', 'icon': LucideIcons.milestone},
    {'id': 'pillars', 'label': '4 Pillars', 'icon': LucideIcons.shieldCheck},
    {'id': 'philosophy', 'label': 'Philosophy', 'icon': LucideIcons.eye},
    {'id': 'custom', 'label': 'Custom Views', 'icon': LucideIcons.compass},
  ];

  static const List<Map<String, String>> _milestones = [
    { 'year': "2011", 'title': "Foundations", 'desc': "M4 Family established its roots in Mumbai's premium real estate landscape with a vision for excellence." },
    { 'year': "2015", 'title': "Aura Heights", 'desc': "A landmark delivery at Grant Road, setting new standards for refined urban living." },
    { 'year': "2019", 'title': "South Mumbai Scaling", 'desc': "Expanded our footprint with institutional-grade developments in elite neighborhoods." },
    { 'year': "2023", 'title': "Ocean View", 'desc': "Unveiled our signature coastal address, blending modern luxury with timeless seaside charm." },
    { 'year': "Present", 'title': "Future Forward", 'desc': "Continuing to shape spaces that endure through generations with innovation and trust." },
  ];

  static const List<Map<String, dynamic>> _pillars = [
    { 'title': "TRUST", 'desc': "A DÉCADE OF UNWAVERING INTEGRITY IN EVERY STRUCTURE.", 'icon': LucideIcons.shieldCheck },
    { 'title': "TRANSPARENCY", 'desc': "CLEAR, HONEST COMMUNICATION AT EVERY MILESTONE.", 'icon': LucideIcons.eye },
    { 'title': "TIMELINESS", 'desc': "COMMITTED TO DELIVERING YOUR VISION ON SCHEDULE.", 'icon': LucideIcons.milestone },
    { 'title': "HUMAN TOUCH", 'desc': "PERSONALIZED SERVICE THAT PUTS YOUR NEEDS FIRST.", 'icon': LucideIcons.heart },
  ];

  @override
  void initState() {
    super.initState();
    _fetchAboutContent();
  }

  Future<void> _fetchAboutContent() async {
    try {
      final apiClient = ref.read(apiClientProvider);
      final response = await apiClient.getCmsPage('about-us');
      if (response.data['status'] == true) {
        setState(() {
          _cmsData = response.data['data'];
          _isLoading = false;
        });
      } else {
        setState(() => _isLoading = false);
      }
    } catch (_) {
      setState(() => _isLoading = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.black,
      extendBodyBehindAppBar: true,
      appBar: AppBar(
        title: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text('WHO WE ARE', 
                style: GoogleFonts.montserrat(
                  color: Colors.white, 
                  fontWeight: FontWeight.bold, 
                  fontSize: 16, 
                  letterSpacing: 2
                )),
            Text('M4 FAMILY COLLECTIVE', 
                style: GoogleFonts.montserrat(
                  color: Colors.white24, 
                  fontWeight: FontWeight.w900, 
                  fontSize: 8, 
                  letterSpacing: 3
                )),
          ],
        ),
        backgroundColor: Colors.black.withOpacity(0.8),
        flexibleSpace: ClipRRect(
          child: BackdropFilter(
            filter: ImageFilter.blur(sigmaX: 10, sigmaY: 10),
            child: Container(color: Colors.transparent),
          ),
        ),
        elevation: 0,
        leading: IconButton(
          icon: const Icon(LucideIcons.arrowLeft, color: Colors.white70),
          onPressed: () => Navigator.pop(context),
        ),
        actions: [
          Builder(
            builder: (context) => IconButton(
              icon: const Icon(LucideIcons.moreHorizontal, color: Colors.white, size: 28),
              onPressed: () => Scaffold.of(context).openDrawer(),
            ),
          ),
          const SizedBox(width: 8),
        ],
      ),
      drawer: const SidebarMenu(),
      body: Container(
        decoration: const BoxDecoration(
          color: Colors.black,
          gradient: RadialGradient(
            center: Alignment.topCenter,
            radius: 2.5,
            colors: [Color(0xFF0F1115), Colors.black],
          ),
        ),
        child: SafeArea(
          child: Column(
            children: [
              _buildStepIndicator(),
              Expanded(
                child: _isLoading 
                    ? const Center(child: CircularProgressIndicator(color: Colors.white24))
                    : SingleChildScrollView(
                        padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 32),
                        child: AnimatedSwitcher(
                          duration: const Duration(milliseconds: 400),
                          child: _getStepContent(),
                        ),
                      ),
              ),
              _buildNavigationButtons(),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildStepIndicator() {
    return Container(
      padding: const EdgeInsets.symmetric(vertical: 24, horizontal: 24),
      decoration: BoxDecoration(
        color: Colors.black.withOpacity(0.3),
        border: Border(bottom: BorderSide(color: Colors.white.withOpacity(0.05))),
      ),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: List.generate(_steps.length, (idx) {
          final step = _steps[idx];
          final isActive = _currentStep == idx;
          final isCompleted = idx < _currentStep;

          return Expanded(
            child: GestureDetector(
              onTap: () => setState(() => _currentStep = idx),
              child: Column(
                children: [
                  Stack(
                    alignment: Alignment.center,
                    children: [
                      // Connecting line
                      if (idx < _steps.length - 1)
                        Positioned(
                          right: -500, // Large enough to span
                          left: 20,
                          top: 18,
                          child: Container(
                            height: 2,
                            color: isCompleted ? Colors.white24 : Colors.white10,
                          ),
                        ),
                      
                      AnimatedContainer(
                        duration: const Duration(milliseconds: 300),
                        width: 36,
                        height: 36,
                        decoration: BoxDecoration(
                          color: isActive ? Colors.white : Colors.white.withOpacity(0.05),
                          shape: BoxShape.circle,
                          border: Border.all(
                            color: isActive ? Colors.white : isCompleted ? Colors.white24 : Colors.white10,
                            width: 2,
                          ),
                          boxShadow: isActive ? [
                            BoxShadow(color: Colors.white.withOpacity(0.3), blurRadius: 15)
                          ] : null,
                        ),
                        child: Icon(
                          isActive || isCompleted ? step['icon'] : step['icon'],
                          color: isActive ? Colors.black : Colors.white24,
                          size: 14,
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 8),
                  Text(
                    step['label'].toString().toUpperCase(),
                    style: GoogleFonts.montserrat(
                      color: isActive ? Colors.white : Colors.white24,
                      fontSize: 7,
                      fontWeight: FontWeight.w900,
                      letterSpacing: 1,
                    ),
                  ),
                ],
              ),
            ),
          );
        }),
      ),
    );
  }

  Widget _getStepContent() {
    switch (_currentStep) {
      case 0: return _buildAboutStep();
      case 1: return _buildJourneyStep();
      case 2: return _buildPillarsStep();
      case 3: return _buildPhilosophyStep();
      case 4: return _buildCustomStep();
      default: return const SizedBox.shrink();
    }
  }

  Widget _buildAboutStep() {
    return Column(
      key: const ValueKey('step_0'),
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        _buildHeroCard(),
        const SizedBox(height: 48),
        _buildSectionHeader(LucideIcons.briefcase, 'OUR STORY'),
        const SizedBox(height: 24),
        _buildGlassCard(
          child: Column(
            children: [
              Text(
                '"M4 Family, with over a decade of excellence in Mumbai’s real estate landscape, has established itself as a trusted name in premium residential development."',
                style: GoogleFonts.montserrat(color: Colors.white70, fontSize: 13, fontWeight: FontWeight.w600, height: 1.8),
              ),
              const SizedBox(height: 20),
              Text(
                'Renowned for delivering homes that blend contemporary design with enduring quality, we take pride in creating spaces that inspire modern living while retaining timeless value.',
                style: GoogleFonts.montserrat(color: Colors.white, fontSize: 13, fontWeight: FontWeight.w500, height: 1.8),
              ),
              const SizedBox(height: 20),
              Text(
                'Every development we undertake reflects meticulous planning, uncompromising quality, and a commitment to delivering on promises. From Aura Heights to our latest offering Ocean View, we continue to redefine what it means to call a place home.',
                style: GoogleFonts.montserrat(color: Colors.white, fontSize: 13, fontWeight: FontWeight.w500, height: 1.8),
              ),
            ],
          ),
        ),
      ],
    ).animate().fadeIn();
  }

  Widget _buildJourneyStep() {
    return Column(
      key: const ValueKey('step_1'),
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        _buildSectionHeader(LucideIcons.milestone, 'OUR MILESTONES'),
        const SizedBox(height: 40),
        ListView.builder(
          shrinkWrap: true,
          physics: const NeverScrollableScrollPhysics(),
          itemCount: _milestones.length,
          itemBuilder: (context, idx) {
            final item = _milestones[idx];
            return IntrinsicHeight(
              child: Row(
                children: [
                  Column(
                    children: [
                      Container(
                        width: 14,
                        height: 14,
                        decoration: BoxDecoration(
                          color: Colors.black,
                          shape: BoxShape.circle,
                          border: Border.all(color: Colors.white, width: 3),
                        ),
                      ),
                      if (idx < _milestones.length - 1)
                        Expanded(
                          child: Container(
                            width: 2,
                            color: Colors.white10,
                          ),
                        ),
                    ],
                  ),
                  const SizedBox(width: 24),
                  Expanded(
                    child: Padding(
                      padding: const EdgeInsets.only(bottom: 40),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            item['year']!,
                            style: GoogleFonts.montserrat(color: Colors.white54, fontSize: 10, fontWeight: FontWeight.bold, letterSpacing: 2),
                          ),
                          const SizedBox(height: 8),
                          Text(
                            item['title']!.toUpperCase(),
                            style: GoogleFonts.montserrat(color: Colors.white, fontSize: 18, fontWeight: FontWeight.w900),
                          ),
                          const SizedBox(height: 12),
                          Text(
                            item['desc']!,
                            style: GoogleFonts.montserrat(color: Colors.white38, fontSize: 12, height: 1.6),
                          ),
                        ],
                      ),
                    ),
                  ),
                ],
              ),
            );
          },
        ),
      ],
    ).animate().fadeIn();
  }

  Widget _buildPillarsStep() {
    return Column(
      key: const ValueKey('step_2'),
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        _buildSectionHeader(LucideIcons.shieldCheck, 'THE 4 PILLARS'),
        const SizedBox(height: 40),
        GridView.builder(
          shrinkWrap: true,
          physics: const NeverScrollableScrollPhysics(),
          gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
            crossAxisCount: 2,
            mainAxisSpacing: 16,
            crossAxisSpacing: 16,
            childAspectRatio: 0.85,
          ),
          itemCount: _pillars.length,
          itemBuilder: (context, idx) {
            final pillar = _pillars[idx];
            return Container(
              padding: const EdgeInsets.all(24),
              decoration: BoxDecoration(
                color: Colors.white.withOpacity(0.03),
                borderRadius: BorderRadius.circular(32),
                border: Border.all(color: Colors.white.withOpacity(0.05)),
              ),
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Icon(pillar['icon'], color: Colors.white70, size: 28),
                  const SizedBox(height: 16),
                  Text(
                    pillar['title'],
                    style: GoogleFonts.montserrat(color: Colors.white, fontSize: 10, fontWeight: FontWeight.w900, letterSpacing: 2),
                  ),
                  const SizedBox(height: 12),
                  Text(
                    pillar['desc'],
                    textAlign: TextAlign.center,
                    style: GoogleFonts.montserrat(color: Colors.white24, fontSize: 8, fontWeight: FontWeight.w900, height: 1.5),
                  ),
                ],
              ),
            );
          },
        ),
      ],
    ).animate().fadeIn();
  }

  Widget _buildPhilosophyStep() {
    final sections = (_cmsData?['sections'] as List?) ?? [];
    return Column(
      key: const ValueKey('step_3'),
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        _buildSectionHeader(LucideIcons.eye, 'OUR PHILOSOPHY'),
        const SizedBox(height: 40),
        if (sections.isEmpty)
          const Center(child: Text('NO DATA AVAILABLE', style: TextStyle(color: Colors.white10)))
        else
          ...sections.map((section) => Padding(
                padding: const EdgeInsets.only(bottom: 24),
                child: _buildPhilosophyCard(section),
              )),
      ],
    ).animate().fadeIn();
  }

  Widget _buildCustomStep() {
    return Column(
      key: const ValueKey('step_4'),
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        _buildSectionHeader(LucideIcons.sparkles, 'INTERACTIVE LIVING'),
        const SizedBox(height: 24),
        Text(
          'EXPERIENCE THE FUTURE OF HOME PERSONALISATION. OUR PROPRIETARY CUSTOM VIEWS SUITE ALLOWS YOU TO VISUALISE AND CRAFT YOUR DREAM SPACE BEFORE IT\'S EVEN BUILT.',
          textAlign: TextAlign.center,
          style: GoogleFonts.montserrat(color: Colors.white54, fontSize: 11, fontWeight: FontWeight.w600, height: 1.8),
        ),
        const SizedBox(height: 40),
        Row(
          children: [
            Expanded(child: _buildPromoImage('https://images.unsplash.com/photo-1600210492486-724fe5c67fb0?auto=format&fit=crop&q=80')),
            const SizedBox(width: 16),
            Expanded(child: _buildPromoImage('https://images.unsplash.com/photo-1556911220-e15b29be8c8f?auto=format&fit=crop&q=80')),
          ],
        ),
        const SizedBox(height: 40),
        _buildFinalCTA(),
      ],
    ).animate().fadeIn();
  }

  Widget _buildHeroCard() {
    return Container(
      height: 200,
      width: double.infinity,
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(40),
        image: const DecorationImage(
          image: NetworkImage('https://images.unsplash.com/photo-1464938050520-ef2270bb8ce8?auto=format&fit=crop&q=80'),
          fit: BoxFit.cover,
          colorFilter: ColorFilter.mode(Colors.black45, BlendMode.darken),
        ),
      ),
      child: Padding(
        padding: const EdgeInsets.all(32),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.end,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text('THE COLLECTIVE', style: GoogleFonts.montserrat(color: Colors.white60, fontSize: 10, fontWeight: FontWeight.w900, letterSpacing: 3)),
            const SizedBox(height: 4),
            Text('M4 LEGACY', style: GoogleFonts.montserrat(color: Colors.white, fontSize: 24, fontWeight: FontWeight.w900, letterSpacing: -1)),
          ],
        ),
      ),
    );
  }

  Widget _buildSectionHeader(IconData icon, String title) {
    return Row(
      children: [
        Container(
          padding: const EdgeInsets.all(10),
          decoration: BoxDecoration(color: Colors.white.withOpacity(0.05), borderRadius: BorderRadius.circular(12)),
          child: Icon(icon, color: Colors.white, size: 18),
        ),
        const SizedBox(width: 16),
        Text(title, style: GoogleFonts.montserrat(color: Colors.white, fontSize: 18, fontWeight: FontWeight.w900, letterSpacing: -0.5)),
      ],
    );
  }

  Widget _buildGlassCard({required Widget child}) {
    return Container(
      padding: const EdgeInsets.all(32),
      decoration: BoxDecoration(
        color: Colors.white.withOpacity(0.04),
        borderRadius: BorderRadius.circular(40),
        border: Border.all(color: Colors.white.withOpacity(0.05)),
      ),
      child: child,
    );
  }

  Widget _buildPhilosophyCard(Map<String, dynamic> section) {
    return _buildGlassCard(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              const Icon(LucideIcons.target, color: Colors.white38, size: 16),
              const SizedBox(width: 12),
              Text(
                section['title'].toString().toUpperCase(),
                style: GoogleFonts.montserrat(color: Colors.white, fontSize: 14, fontWeight: FontWeight.w900),
              ),
            ],
          ),
          const SizedBox(height: 20),
          Text(
            section['content'],
            style: GoogleFonts.montserrat(color: Colors.white54, fontSize: 11, fontWeight: FontWeight.w900, height: 1.6, letterSpacing: 1),
          ),
        ],
      ),
    );
  }

  Widget _buildPromoImage(String url) {
    return AspectRatio(
      aspectRatio: 1,
      child: Container(
        decoration: BoxDecoration(
          borderRadius: BorderRadius.circular(32),
          image: DecorationImage(image: NetworkImage(url), fit: BoxFit.cover),
          border: Border.all(color: Colors.white.withOpacity(0.1)),
        ),
      ),
    );
  }

  Widget _buildFinalCTA() {
    return Container(
      padding: const EdgeInsets.all(40),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(40),
      ),
      child: Column(
        children: [
          const Icon(LucideIcons.compass, color: Colors.black, size: 32),
          const SizedBox(height: 24),
          Text('YOUR DESIGN JOURNEY', style: GoogleFonts.montserrat(color: Colors.black, fontSize: 20, fontWeight: FontWeight.w900, letterSpacing: -1)),
          const SizedBox(height: 8),
          Text('PERSONALISE EVERY DETAIL', style: GoogleFonts.montserrat(color: Colors.black54, fontSize: 9, fontWeight: FontWeight.w900, letterSpacing: 2)),
          const SizedBox(height: 24),
          Text(
            'choose your materials, explore configurations, and see your vision come to life with m4 custom views.'.toUpperCase(),
            textAlign: TextAlign.center,
            style: GoogleFonts.montserrat(color: Colors.black45, fontSize: 10, fontWeight: FontWeight.bold, height: 1.6),
          ),
          const SizedBox(height: 32),
          SizedBox(
            width: double.infinity,
            height: 60,
            child: ElevatedButton(
              onPressed: () {
                ref.read(navigationProvider.notifier).state = 6;
                Navigator.pop(context);
              },
              style: ElevatedButton.styleFrom(
                backgroundColor: Colors.black,
                foregroundColor: Colors.white,
                shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(24)),
                elevation: 0,
              ),
              child: Row(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Text('CUSTOM VIEWS', style: GoogleFonts.montserrat(fontWeight: FontWeight.w900, fontSize: 11, letterSpacing: 1)),
                  const SizedBox(width: 8),
                  const Icon(LucideIcons.chevronRight, size: 14),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildNavigationButtons() {
    return Container(
      padding: const EdgeInsets.fromLTRB(24, 16, 24, 32),
      decoration: BoxDecoration(
        color: Colors.black,
        border: Border(top: BorderSide(color: Colors.white.withOpacity(0.05))),
      ),
      child: Row(
        children: [
          if (_currentStep > 0)
            Expanded(
              flex: 1,
              child: Padding(
                padding: const EdgeInsets.only(right: 12),
                child: TextButton(
                  onPressed: () => setState(() => _currentStep--),
                  style: TextButton.styleFrom(
                    padding: const EdgeInsets.symmetric(vertical: 20),
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(20), 
                      side: const BorderSide(color: Colors.white12),
                    ),
                  ),
                  child: Text('BACK', style: GoogleFonts.montserrat(color: Colors.white54, fontWeight: FontWeight.w900, fontSize: 10, letterSpacing: 2)),
                ),
              ),
            ),
          Expanded(
            flex: 2,
            child: ElevatedButton(
              onPressed: () {
                if (_currentStep < _steps.length - 1) {
                  setState(() => _currentStep++);
                } else {
                  Navigator.pop(context);
                }
              },
              style: ElevatedButton.styleFrom(
                backgroundColor: Colors.white,
                foregroundColor: Colors.black,
                padding: const EdgeInsets.symmetric(vertical: 20),
                shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
              ),
              child: Text(
                _currentStep < _steps.length - 1 ? 'NEXT STEP' : 'FINISH',
                style: GoogleFonts.montserrat(fontWeight: FontWeight.w900, fontSize: 10, letterSpacing: 2),
              ),
            ),
          ),
        ],
      ),
    );
  }
}
