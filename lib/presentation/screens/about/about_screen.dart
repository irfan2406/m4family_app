import 'dart:ui';
import 'package:m4_mobile/core/theme/app_theme.dart';
import 'package:m4_mobile/core/utils/validators.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:cached_network_image/cached_network_image.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:lucide_icons/lucide_icons.dart';
import 'package:m4_mobile/presentation/widgets/side_menu_button.dart';
import 'package:flutter_animate/flutter_animate.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:m4_mobile/core/network/api_client.dart';
import 'package:m4_mobile/presentation/widgets/conditional_drawer.dart';
import 'package:m4_mobile/presentation/widgets/main_shell.dart';
import 'package:m4_mobile/presentation/widgets/navigation_pill.dart';
import 'package:m4_mobile/presentation/providers/auth_provider.dart';
import 'package:m4_mobile/presentation/widgets/guest_main_shell.dart';

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

  final _nameController = TextEditingController();
  final _phoneController = TextEditingController();
  final _emailController = TextEditingController();
  final _scrollController = ScrollController();
  bool _isSubmitting = false;

  @override
  void dispose() {
    _nameController.dispose();
    _phoneController.dispose();
    _emailController.dispose();
    _scrollController.dispose();
    super.dispose();
  }

  static const List<Map<String, dynamic>> _steps = [
    {'id': 'about', 'label': 'About', 'icon': LucideIcons.users},
    {'id': 'journey', 'label': 'Journey', 'icon': LucideIcons.milestone},
    {'id': 'pillars', 'label': '4 Pillars', 'icon': LucideIcons.shieldCheck},
    {'id': 'philosophy', 'label': 'Philosophy', 'icon': LucideIcons.eye},
    {'id': 'custom', 'label': 'Custom Views', 'icon': LucideIcons.compass},
  ];

  static const List<Map<String, String>> _milestones = [
    {
      'year': "2011",
      'title': "Foundations",
      'desc':
          "M4 Family established its roots in Mumbai's premium real estate landscape with a vision for excellence.",
    },
    {
      'year': "2015",
      'title': "Aura Heights",
      'desc':
          "A landmark delivery at Grant Road, setting new standards for refined urban living.",
    },
    {
      'year': "2019",
      'title': "South Mumbai Scaling",
      'desc':
          "Expanded our footprint with institutional-grade developments in elite neighborhoods.",
    },
    {
      'year': "2023",
      'title': "Ocean View",
      'desc':
          "Unveiled our signature coastal address, blending modern luxury with timeless seaside charm.",
    },
    {
      'year': "Present",
      'title': "Future Forward",
      'desc':
          "Continuing to shape spaces that endure through generations with innovation and trust.",
    },
  ];

  static const List<Map<String, dynamic>> _defaultSections = [
    {
      'title': "Our Philosophy",
      'icon': "Eye",
      'content':
          "To redefine the horizon of Mumbai by crafting iconic architectural landmarks that harmonize luxury, sustainability, and enduring value.",
    },
    {
      'title': "Our Mission",
      'icon': "Target",
      'content':
          "To deliver uncompromising quality and institutional-grade excellence in every square foot, fostering trust and a sense of belonging for our community.",
    },
    {
      'title': "Core Values",
      'icon': "ShieldCheck",
      'content':
          "Integrity, Transparency, and Innovation drive every decision we make, ensuring our legacy remains as solid as the structures we build.",
    },
  ];

  static const List<Map<String, dynamic>> _pillars = [
    {
      'title': "TRUST",
      'desc': "A DÉCADE OF UNWAVERING INTEGRITY IN EVERY STRUCTURE.",
      'icon': LucideIcons.shieldCheck,
    },
    {
      'title': "TRANSPARENCY",
      'desc': "CLEAR, HONEST COMMUNICATION AT EVERY MILESTONE.",
      'icon': LucideIcons.eye,
    },
    {
      'title': "TIMELINESS",
      'desc': "COMMITTED TO DELIVERING YOUR VISION ON SCHEDULE.",
      'icon': LucideIcons.milestone,
    },
    {
      'title': "HUMAN TOUCH",
      'desc': "PERSONALIZED SERVICE THAT PUTS YOUR NEEDS FIRST.",
      'icon': LucideIcons.heart,
    },
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
    final isDark = Theme.of(context).brightness == Brightness.dark;
    return Scaffold(
      backgroundColor: Theme.of(context).scaffoldBackgroundColor,
      extendBodyBehindAppBar: true,
      extendBody: true,
      // Bottom nav — shown only when pushed standalone (from the menu), not
      // when embedded as a shell tab (the shell provides its own nav).
      bottomNavigationBar: Navigator.of(context).canPop()
          ? NavigationPill(
              currentIndex: -1,
              onTap: (i) {
                ref.read(navigationProvider.notifier).state = i;
                Navigator.of(context).popUntil((r) => r.isFirst);
              },
            )
          : null,
      appBar: AppBar(
        centerTitle: true,
        title: Column(
          crossAxisAlignment: CrossAxisAlignment.center,
          children: [
            Text(
              'WHO WE ARE',
              style: GoogleFonts.gelasio(
                color: isDark ? Colors.white : Color(0xFF0C312B),
                fontWeight: FontWeight.bold,
                fontSize: 14,
                letterSpacing: 2,
              ),
            ),
            Text(
              'M4 FAMILY COLLECTIVE',
              style: GoogleFonts.inter(
                color: isDark ? Colors.white : Color(0xFF155A4F),
                fontWeight: FontWeight.w400,
                fontSize: 8,
                letterSpacing: 2,
              ),
            ),
          ],
        ),
        backgroundColor: isDark ? const Color(0xFF0B1026) : Theme.of(context).scaffoldBackgroundColor,
        flexibleSpace: ClipRRect(
          child: BackdropFilter(
            filter: ImageFilter.blur(sigmaX: 10, sigmaY: 10),
            child: Container(color: Colors.transparent),
          ),
        ),
        elevation: 0,
        leadingWidth: 56,
        leading: Center(
          child: Padding(
            padding: const EdgeInsets.only(left: 12),
            child: InkWell(
              onTap: () {
                if (Navigator.of(context).canPop()) {
                  Navigator.pop(context);
                } else {
                  ref.read(guestNavigationProvider.notifier).state = 0;
                }
              },
              borderRadius: BorderRadius.circular(12),
              child: Container(
                width: 36,
                height: 36,
                alignment: Alignment.center,
                decoration: BoxDecoration(
                  color: (isDark ? Colors.white : Color(0xFF0C312B)).withOpacity(
                    0.05,
                  ),
                  borderRadius: BorderRadius.circular(12),
                  border: Border.all(
                    color: (isDark ? Colors.white : Color(0xFF0C312B)).withOpacity(
                      0.08,
                    ),
                  ),
                ),
                child: Icon(
                  LucideIcons.arrowLeft,
                  color: isDark ? Colors.white : Color(0xFF0C312B),
                  size: 16,
                ),
              ),
            ),
          ),
        ),
        actions: [
          Builder(
            builder: (context) => Center(
              child: Padding(
                padding: const EdgeInsets.only(right: 12),
                child: const SideMenuButton(),
              ),
            ),
          ),
        ],
      ),
      drawer: const ConditionalDrawer(),
      body: Container(
        decoration: BoxDecoration(
          color: Theme.of(context).scaffoldBackgroundColor,
          gradient: isDark
              ? const RadialGradient(
                  center: Alignment.topCenter,
                  radius: 2.5,
                  colors: [Color(0xFF141B3A), Color(0xFF0B1026)],
                )
              : null,
        ),
        child: SafeArea(
          // Edge-to-edge: content runs under the gesture bar so scrolling fills
          // the screen. Trailing padding keeps the last item reachable.
          bottom: false,
          child: Column(
            children: [
              _buildStepIndicator(),
              Expanded(
                child: _isLoading
                    ? Center(
                        child: CircularProgressIndicator(
                          color: isDark ? Colors.white24 : Colors.black12,
                        ),
                      )
                    : SingleChildScrollView(
                        controller: _scrollController,
                        padding: const EdgeInsets.fromLTRB(24, 32, 24, 120),
                        child: Column(
                          children: [
                            AnimatedSwitcher(
                              duration: const Duration(milliseconds: 400),
                              child: _getStepContent(),
                            ),
                            const SizedBox(height: 32),
                            _buildNavigationButtons(),
                          ],
                        ),
                      ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildStepIndicator() {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final colorScheme = Theme.of(context).colorScheme;

    return Container(
      padding: const EdgeInsets.symmetric(vertical: 24, horizontal: 24),
      decoration: BoxDecoration(
        color: isDark ? const Color(0xFF0B1026) : Theme.of(context).scaffoldBackgroundColor,
        border: Border(
          bottom: BorderSide(color: Colors.white.withOpacity(0.05)),
        ),
      ),
      child: LayoutBuilder(
        builder: (context, constraints) {
          final totalWidth = constraints.maxWidth;
          final stepWidth = totalWidth / _steps.length;
          final progressWidth = stepWidth * _currentStep + (stepWidth / 2);

          return Stack(
            children: [
              // Background connecting line
              Positioned(
                top: 20,
                left: stepWidth / 2,
                right: stepWidth / 2,
                child: Container(
                  height: 2,
                  color: (isDark ? Colors.white : Color(0xFF0C312B)).withOpacity(
                    0.05,
                  ),
                ),
              ),
              // Animated Progress Line
              AnimatedPositioned(
                duration: const Duration(milliseconds: 500),
                curve: Curves.easeInOut,
                top: 20,
                left: stepWidth / 2,
                width: (_currentStep == 0) ? 0 : (stepWidth * _currentStep),
                child: Container(height: 2, color: colorScheme.primary),
              ),
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: List.generate(_steps.length, (idx) {
                  final step = _steps[idx];
                  final isActive = _currentStep == idx;
                  final isCompleted = idx < _currentStep;

                  return Expanded(
                    child: GestureDetector(
                      behavior: HitTestBehavior.opaque,
                      onTap: () {
                        setState(() => _currentStep = idx);
                        _scrollController.animateTo(
                          0,
                          duration: const Duration(milliseconds: 300),
                          curve: Curves.easeOut,
                        );
                      },
                      child: Column(
                        children: [
                          AnimatedContainer(
                            duration: const Duration(milliseconds: 300),
                            // Figma "Rectangle 12": the active step is a 39x39
                            // rounded square (radius 8) filled #155A4F. Inactive
                            // steps stay circles.
                            width: 39,
                            height: 39,
                            decoration: BoxDecoration(
                              color: isActive
                                  ? const Color(0xFF155A4F)
                                  : isCompleted
                                  ? (isDark ? const Color(0xFF141B3A) : const Color(0xFFF4EFE3))
                                  : (isDark
                                        ? Colors.white.withOpacity(0.05)
                                        : Colors.black.withOpacity(0.04)),
                              // Always a rectangle: the active step is a
                              // rounded square (radius 8), inactive steps use a
                              // full radius (39/2) so they read as circles.
                              // Animating radius-to-radius avoids the shape
                              // mismatch that threw a red error frame on switch.
                              shape: BoxShape.rectangle,
                              borderRadius: BorderRadius.circular(
                                isActive ? 8 : 19.5,
                              ),
                              border: Border.all(
                                color: isActive
                                    ? const Color(0xFF155A4F)
                                    : isCompleted
                                    ? colorScheme.primary.withOpacity(0.55)
                                    : (isDark
                                          ? Colors.white.withOpacity(0.1)
                                          : Colors.black.withOpacity(0.1)),
                                width: 2,
                              ),
                            ),
                            child: Icon(
                              step['icon'],
                              color: isActive
                                  ? (isDark ? const Color(0xFF141B3A) : const Color(0xFFF4EFE3))
                                  : isCompleted
                                  ? colorScheme.primary.withOpacity(0.62)
                                  : (isDark ? Colors.white60 : Color(0xFF155A4F)),
                              size: 16,
                            ),
                          ),
                          const SizedBox(height: 8),
                          // Web parity: single line — long labels auto-shrink
                          // to fit (e.g. "CUSTOM VIEWS") instead of wrapping.
                          Padding(
                            // Gutter between neighbouring labels: without it
                            // PHILOSOPHY and CUSTOM VIEWS fill their cells edge
                            // to edge and run into each other.
                            padding: const EdgeInsets.symmetric(horizontal: 4),
                            child: FittedBox(
                              fit: BoxFit.scaleDown,
                              child: Text(
                                step['label'].toString().toUpperCase(),
                                maxLines: 1,
                                softWrap: false,
                                // 9.5 so the longest name (CUSTOM VIEWS) fits
                                // its cell unscaled: FittedBox only shrinks
                                // what overflows, so a size the long labels
                                // clear is what keeps all five equal.
                                style: GoogleFonts.inter(
                                  color: isActive
                                      ? (isDark
                                            ? Colors.white
                                            : M4Theme.lightForeground)
                                      : (isDark
                                            ? Colors.white70
                                            : M4Theme.lightForeground
                                                  .withOpacity(0.72)),
                                  fontSize: 9.5,
                                  fontWeight: FontWeight.w700,
                                  letterSpacing: 0,
                                ),
                              ),
                            ),
                          ),
                        ],
                      ),
                    ),
                  );
                }),
              ),
            ],
          );
        },
      ),
    );
  }

  Widget _getStepContent() {
    switch (_currentStep) {
      case 0:
        return _buildAboutStep();
      case 1:
        return _buildJourneyStep();
      case 2:
        return _buildPillarsStep();
      case 3:
        return _buildPhilosophyStep();
      case 4:
        return _buildCustomStep();
      default:
        return const SizedBox.shrink();
    }
  }

  Widget _buildAboutStep() {
    final isDark = Theme.of(context).brightness == Brightness.dark;
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
              // Centred, a size up and a shade darker so the copy reads
              // clearly on the cream card.
              Text(
                '"M4 Family, with over a decade of excellence in Mumbai’s real estate landscape, has established itself as a trusted name in premium residential development."',
                textAlign: TextAlign.center,
                style: GoogleFonts.inter(
                  color: isDark ? Colors.white : M4Theme.lightForeground,
                  fontSize: 15,
                  fontWeight: FontWeight.w500,
                  height: 1.8,
                ),
              ),
              const SizedBox(height: 6),
              Text(
                'Renowned for delivering homes that blend contemporary design with enduring quality, we take pride in creating spaces that inspire modern living while retaining timeless value.',
                textAlign: TextAlign.center,
                style: GoogleFonts.inter(
                  color: isDark ? Colors.white : M4Theme.lightForeground,
                  fontSize: 15,
                  fontWeight: FontWeight.w500,
                  height: 1.8,
                ),
              ),
              const SizedBox(height: 6),
              Text(
                'Every development we undertake reflects meticulous planning, uncompromising quality, and a commitment to delivering on promises. From Aura Heights to our latest offering Ocean View, we continue to redefine what it means to call a place home.',
                textAlign: TextAlign.center,
                style: GoogleFonts.inter(
                  color: isDark ? Colors.white : M4Theme.lightForeground,
                  fontSize: 15,
                  fontWeight: FontWeight.w500,
                  height: 1.8,
                ),
              ),
            ],
          ),
        ),
      ],
    ).animate().fadeIn();
  }

  Widget _buildJourneyStep() {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final colorScheme = Theme.of(context).colorScheme;
    final List milestones = (_cmsData?['milestones'] as List?) ?? _milestones;

    return Column(
      key: const ValueKey('step_1'),
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        _buildSectionHeader(LucideIcons.milestone, 'OUR MILESTONES'),
        const SizedBox(height: 40),
        ListView.builder(
          shrinkWrap: true,
          physics: const NeverScrollableScrollPhysics(),
          itemCount: milestones.length,
          itemBuilder: (context, idx) {
            final item = milestones[idx];
            return IntrinsicHeight(
              child: Row(
                children: [
                  Column(
                    children: [
                      Container(
                        width: 24,
                        height: 24,
                        padding: const EdgeInsets.all(4),
                        decoration: BoxDecoration(
                          color: Theme.of(context).scaffoldBackgroundColor,
                          shape: BoxShape.circle,
                          border: Border.all(
                            color: colorScheme.primary,
                            width: 4,
                          ),
                          boxShadow: [
                            BoxShadow(
                              color: colorScheme.primary.withOpacity(0.2),
                              blurRadius: 10,
                            ),
                          ],
                        ),
                        child: Container(
                          decoration: BoxDecoration(
                            color: colorScheme.primary,
                            shape: BoxShape.circle,
                          ),
                        ),
                      ),
                      if (idx < _milestones.length - 1)
                        Expanded(
                          child: Container(
                            width: 2,
                            decoration: BoxDecoration(
                              gradient: LinearGradient(
                                begin: Alignment.topCenter,
                                end: Alignment.bottomCenter,
                                colors: [
                                  colorScheme.primary,
                                  colorScheme.primary.withOpacity(0.1),
                                ],
                              ),
                            ),
                          ),
                        ),
                    ],
                  ),
                  const SizedBox(width: 24),
                  Expanded(
                    child: Padding(
                      padding: const EdgeInsets.only(bottom: 40, top: 4),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            item['year']!,
                            style: GoogleFonts.gelasio(
                              color: colorScheme.primary,
                              fontSize: 10,
                              fontWeight: FontWeight.w700,
                              letterSpacing: 2,
                            ),
                          ),
                          const SizedBox(height: 8),
                          Text(
                            item['title']!.toUpperCase(),
                            style: GoogleFonts.inter(
                              color: isDark ? Colors.white : Color(0xFF155A4F),
                              fontSize: 16,
                              fontWeight: FontWeight.w600,
                              letterSpacing: -0.5,
                            ),
                          ),
                          const SizedBox(height: 8),
                          Text(
                            (item['desc'] ?? item['content'] ?? '').toString(),
                            style: GoogleFonts.inter(
                              color: isDark ? Colors.white70 : Color(0xFF155A4F),
                              fontSize: 12,
                              height: 1.6,
                              fontWeight: FontWeight.w500,
                            ),
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
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final colorScheme = Theme.of(context).colorScheme;
    final List pillars = (_cmsData?['pillars'] as List?) ?? _pillars;

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
            childAspectRatio: 0.8,
          ),
          itemCount: pillars.length,
          itemBuilder: (context, idx) {
            final pillar = pillars[idx];
            final iconData = (pillar['icon'] is IconData)
                ? pillar['icon']
                : _getIconData(pillar['icon'].toString());

            return Container(
              padding: const EdgeInsets.all(20),
              decoration: BoxDecoration(
                color: isDark ? Colors.white.withOpacity(0.03) : const Color(0xFFF4EFE3),
                borderRadius: BorderRadius.circular(20),
                border: Border.all(
                  color: isDark
                      ? Colors.white.withOpacity(0.05)
                      : Colors.black.withOpacity(0.05),
                ),
                boxShadow: isDark
                    ? null
                    : [
                        BoxShadow(
                          color: Colors.black.withOpacity(0.04),
                          blurRadius: 16,
                          offset: const Offset(0, 6),
                        ),
                      ],
              ),
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Container(
                    width: 44,
                    height: 44,
                    decoration: BoxDecoration(
                      color: colorScheme.primary.withOpacity(0.1),
                      borderRadius: BorderRadius.circular(14),
                    ),
                    child: Icon(iconData, color: colorScheme.primary, size: 22),
                  ),
                  const SizedBox(height: 16),
                  Text(
                    pillar['title'].toString().toUpperCase(),
                    style: GoogleFonts.gelasio(
                      color: isDark ? Colors.white : Color(0xFF0C312B),
                      fontSize: 11,
                      fontWeight: FontWeight.w700,
                      letterSpacing: 2,
                    ),
                  ),
                  const SizedBox(height: 8),
                  Text(
                    pillar['desc'],
                    textAlign: TextAlign.center,
                    style: GoogleFonts.inter(
                      color: (isDark ? Colors.white : Color(0xFF0C312B)).withOpacity(
                        0.68,
                      ),
                      fontSize: 9,
                      fontWeight: FontWeight.w600,
                      letterSpacing: -0.5,
                      height: 1.4,
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

  Widget _buildPhilosophyStep() {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final List sections = (_cmsData?['sections'] as List?) ?? _defaultSections;

    return Column(
      key: const ValueKey('step_3'),
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        _buildSectionHeader(LucideIcons.eye, 'OUR PHILOSOPHY'),
        const SizedBox(height: 40),
        ...sections.map(
          (section) => Padding(
            padding: const EdgeInsets.only(bottom: 24),
            child: _buildPhilosophyCard(Map<String, dynamic>.from(section)),
          ),
        ),
      ],
    ).animate().fadeIn();
  }

  Widget _buildCustomStep() {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    return Column(
      key: const ValueKey('step_4'),
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        _buildSectionHeader(LucideIcons.sparkles, 'INTERACTIVE LIVING'),
        // 24, matching the OUR STORY step's header-to-card gap.
        const SizedBox(height: 24),
        _buildPhilosophyQuote(),
        const SizedBox(height: 32),
        Text(
          'EXPERIENCE THE FUTURE OF HOME PERSONALISATION. OUR PROPRIETARY CUSTOM VIEWS SUITE ALLOWS YOU TO VISUALISE AND CRAFT YOUR DREAM SPACE BEFORE IT\'S EVEN BUILT.',
          textAlign: TextAlign.center,
          // Was 11px at 60% — too faint to read on the cream page.
          style: GoogleFonts.inter(
            color: (isDark ? Colors.white : M4Theme.lightForeground)
                .withOpacity(0.82),
            fontSize: 13,
            fontWeight: FontWeight.w500,
            height: 1.8,
            letterSpacing: 0.5,
          ),
        ),
        const SizedBox(height: 40),
        Row(
          children: [
            Expanded(
              child: _buildPromoImage(
                ref
                    .read(apiClientProvider)
                    .resolveUrl(
                      '/public/premium_interior_modern_living_room_1774856579067.png',
                    ),
              ),
            ),
            const SizedBox(width: 16),
            Expanded(
              child: _buildPromoImage(
                ref
                    .read(apiClientProvider)
                    .resolveUrl(
                      '/public/premium_kitchen_modular_modern_1774856602851.png',
                    ),
              ),
            ),
          ],
        ),
        const SizedBox(height: 40),
        _buildFinalCTA(),
      ],
    ).animate().fadeIn();
  }

  Widget _buildPhilosophyQuote() {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final colorScheme = Theme.of(context).colorScheme;
    // Card chrome comes from the same builder the OUR STORY card uses, so the
    // surface, radius, padding, border and shadow can never drift apart.
    return _buildGlassCard(
      // Same treatment as the OUR STORY card: centred, EB Garamond at 15,
      // full-strength foreground, upright rather than italic.
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.center,
        children: [
          Text(
            'CUSTOMER VIEWS',
            textAlign: TextAlign.center,
            style: GoogleFonts.gelasio(
              color: colorScheme.primary,
              fontSize: 11,
              fontWeight: FontWeight.w700,
              letterSpacing: 2,
            ),
          ),
          const SizedBox(height: 16),
          Text(
            // Sentence case, like the OUR STORY copy: at the same 15pt, all
            // caps render a size larger because every glyph sits at cap
            // height, so the case is what made this card look bigger.
            '"At M4 Family, we believe that luxury is deeply personal. Our \'Customer Views\' philosophy ensures that every resident\'s perspective is valued, allowing for a collaborative approach to creating living spaces that reflect individual lifestyles and aspirations. We invite you to explore our bespoke personalisation options, where your vision meets our architectural excellence."',
            textAlign: TextAlign.center,
            style: GoogleFonts.inter(
              color: isDark ? Colors.white : M4Theme.lightForeground,
              // Same 15 as the OUR STORY card, so both steps' body copy
              // matches point for point.
              fontSize: 15,
              fontWeight: FontWeight.w500,
              height: 1.8,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildHeroCard() {
    return Container(
      height: 200,
      width: double.infinity,
      decoration: BoxDecoration(borderRadius: BorderRadius.circular(40)),
      child: ClipRRect(
        borderRadius: BorderRadius.circular(40),
        child: Stack(
          children: [
            CachedNetworkImage(
              imageUrl: ref
                  .read(apiClientProvider)
                  .resolveUrl(
                    '/uploads/media/south_mumbai_skyline_luxury_residence_1774856627856.png',
                  ),
              fit: BoxFit.cover,
              width: double.infinity,
              height: double.infinity,
              placeholder: (context, url) => Container(color: Colors.black12),
              errorWidget: (context, url, error) =>
                  Container(color: Colors.black12),
            ),
            Container(
              decoration: BoxDecoration(
                gradient: LinearGradient(
                  begin: Alignment.topCenter,
                  end: Alignment.bottomCenter,
                  colors: [Colors.transparent, Colors.black26, Colors.black87],
                  stops: const [0.0, 0.5, 1.0],
                ),
              ),
            ),
            Padding(
              padding: const EdgeInsets.all(32),
              child: Column(
                mainAxisAlignment: MainAxisAlignment.end,
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    'THE COLLECTIVE',
                    style: GoogleFonts.gelasio(
                      color: Colors.white70,
                      fontSize: 10,
                      fontWeight: FontWeight.w700,
                      letterSpacing: 3,
                    ),
                  ),
                  const SizedBox(height: 4),
                  Text(
                    'M4 LEGACY',
                    style: GoogleFonts.gelasio(
                      color: Colors.white,
                      fontSize: 32,
                      fontWeight: FontWeight.w700,
                      letterSpacing: -1,
                      height: 1.1,
                    ),
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildSectionHeader(IconData icon, String title) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final colorScheme = Theme.of(context).colorScheme;
    return Row(
      children: [
        Container(
          width: 44,
          height: 44,
          decoration: BoxDecoration(
            color: (isDark ? Colors.black : Colors.white).withOpacity(0.8),
            borderRadius: BorderRadius.circular(16),
            border: Border.all(
              color: (isDark ? Colors.white : Color(0xFF0C312B)).withOpacity(0.05),
            ),
            boxShadow: [
              BoxShadow(color: Colors.black.withOpacity(0.05), blurRadius: 10),
            ],
          ),
          child: ClipRRect(
            borderRadius: BorderRadius.circular(16),
            child: BackdropFilter(
              filter: ImageFilter.blur(sigmaX: 10, sigmaY: 10),
              child: Center(
                // Softer green, matching the step marks above.
                child: Icon(
                  icon,
                  color: colorScheme.primary.withOpacity(0.62),
                  size: 18,
                ),
              ),
            ),
          ),
        ),
        const SizedBox(width: 16),
        Text(
          title,
          style: GoogleFonts.gelasio(
            color: isDark ? Colors.white : Color(0xFF0C312B),
            fontSize: 18,
            fontWeight: FontWeight.w700,
            letterSpacing: -1,
          ),
        ),
      ],
    );
  }

  Widget _buildGlassCard({required Widget child}) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    return Container(
      padding: const EdgeInsets.all(32),
      decoration: BoxDecoration(
        color: isDark ? Colors.white.withOpacity(0.04) : const Color(0xFFF4EFE3),
        borderRadius: BorderRadius.circular(40),
        border: Border.all(
          color: isDark
              ? Colors.white.withOpacity(0.05)
              : Colors.black.withOpacity(0.05),
        ),
        boxShadow: isDark
            ? null
            : [
                BoxShadow(
                  color: Colors.black.withOpacity(0.04),
                  blurRadius: 16,
                  offset: const Offset(0, 6),
                ),
              ],
      ),
      child: child,
    );
  }

  // Web parity: IconMap[section.icon] || Users (matches AboutContent.tsx).
  IconData _sectionIcon(String? name) {
    switch (name) {
      case 'Users':
        return LucideIcons.users;
      case 'Target':
        return LucideIcons.target;
      case 'Trophy':
        return LucideIcons.trophy;
      case 'Award':
        return LucideIcons.award;
      case 'ShieldCheck':
        return LucideIcons.shieldCheck;
      case 'Compass':
        return LucideIcons.compass;
      case 'Sparkles':
        return LucideIcons.sparkles;
      default:
        return LucideIcons.users; // web default fallback
    }
  }

  Widget _buildPhilosophyCard(Map<String, dynamic> section) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final colorScheme = Theme.of(context).colorScheme;
    return _buildGlassCard(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Container(
                width: 48,
                height: 48,
                decoration: BoxDecoration(
                  // Web: glass white tile, rounded-2xl, subtle border + shadow.
                  color: isDark ? Colors.white.withOpacity(0.06) : const Color(0xFFF4EFE3),
                  borderRadius: BorderRadius.circular(16),
                  border: Border.all(
                    color: colorScheme.primary.withOpacity(0.1),
                  ),
                  boxShadow: isDark
                      ? null
                      : [
                          BoxShadow(
                            color: Colors.black.withOpacity(0.06),
                            blurRadius: 12,
                            offset: const Offset(0, 4),
                          ),
                        ],
                ),
                child: Center(
                  child: Icon(
                    _sectionIcon(section['icon']?.toString()),
                    color: colorScheme.primary,
                    size: 22,
                  ),
                ),
              ),
              const SizedBox(width: 16),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      section['title'].toString().toUpperCase(),
                      style: GoogleFonts.inter(
                        color: isDark ? Colors.white : Color(0xFF155A4F),
                        fontSize: 15,
                        fontWeight: FontWeight.w600,
                        letterSpacing: -0.5,
                      ),
                    ),
                    const SizedBox(height: 6),
                    Container(
                      width: 32,
                      height: 4,
                      decoration: BoxDecoration(
                        color: colorScheme.primary.withOpacity(0.4),
                        borderRadius: BorderRadius.circular(2),
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ),
          const SizedBox(height: 24),
          Text(
            section['content'].toString().toUpperCase(),
            // Web parity: lighter, less heavy body copy inside the card.
            style: GoogleFonts.inter(
              color: (isDark ? Colors.white : Color(0xFF0C312B)).withOpacity(0.5),
              fontSize: 11,
              fontWeight: FontWeight.w600,
              height: 1.6,
              letterSpacing: 0.5,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildPromoImage(String url) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    return AspectRatio(
      aspectRatio: 1,
      child: Container(
        decoration: BoxDecoration(
          borderRadius: BorderRadius.circular(20),
          border: Border.all(
            color: isDark
                ? Colors.white.withOpacity(0.1)
                : Colors.black.withOpacity(0.05),
          ),
        ),
        child: ClipRRect(
          borderRadius: BorderRadius.circular(20),
          child: CachedNetworkImage(
            imageUrl: url,
            fit: BoxFit.cover,
            placeholder: (context, url) => Container(color: Colors.black12),
            errorWidget: (context, url, error) =>
                Container(color: Colors.black12),
          ),
        ),
      ),
    );
  }

  Widget _buildFinalCTA() {
    final colorScheme = Theme.of(context).colorScheme;
    return Container(
      width: double.infinity,
      decoration: BoxDecoration(
        color: Colors.black,
        borderRadius: BorderRadius.circular(48),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.4),
            blurRadius: 40,
            offset: const Offset(0, 20),
          ),
        ],
      ),
      child: ClipRRect(
        borderRadius: BorderRadius.circular(48),
        child: Stack(
          children: [
            Positioned(
              top: -100,
              right: -100,
              child: Container(
                width: 300,
                height: 300,
                decoration: BoxDecoration(
                  gradient: RadialGradient(
                    colors: [
                      colorScheme.primary.withOpacity(0.15),
                      Colors.transparent,
                    ],
                  ),
                ),
              ),
            ),
            Padding(
              padding: const EdgeInsets.all(40),
              child: Column(
                children: [
                  Container(
                    width: 60,
                    height: 60,
                    decoration: BoxDecoration(
                      color: Colors.white.withOpacity(0.1),
                      shape: BoxShape.circle,
                      border: Border.all(color: Colors.white.withOpacity(0.1)),
                    ),
                    child: const Icon(
                      LucideIcons.compass,
                      color: Colors.white,
                      size: 28,
                    ),
                  ),
                  const SizedBox(height: 24),
                  Text(
                    'YOUR DESIGN JOURNEY',
                    style: GoogleFonts.gelasio(
                      color: Colors.white,
                      fontSize: 22,
                      fontWeight: FontWeight.w700,
                      letterSpacing: -1,
                    ),
                  ),
                  const SizedBox(height: 4),
                  Text(
                    'PERSONALISE EVERY DETAIL',
                    style: GoogleFonts.gelasio(
                      color: Colors.white.withOpacity(0.68),
                      fontSize: 10,
                      fontWeight: FontWeight.w700,
                      letterSpacing: 2,
                    ),
                  ),
                  const SizedBox(height: 24),
                  Text(
                    'CHOOSE YOUR MATERIALS, EXPLORE CONFIGURATIONS, AND SEE YOUR VISION COME TO LIFE WITH M4 CUSTOM VIEWS.',
                    textAlign: TextAlign.center,
                    style: GoogleFonts.inter(
                      color: Colors.white.withOpacity(0.7),
                      fontSize: 11,
                      fontWeight: FontWeight.w600,
                      height: 1.6,
                      letterSpacing: 0.2,
                    ),
                  ),
                  const SizedBox(height: 32),
                  SizedBox(
                    width: double.infinity,
                    height: 64,
                    child: ElevatedButton(
                      onPressed: () {
                        final authState = ref.read(authProvider);
                        if (authState.status == AuthStatus.authenticated) {
                          // Update navigation state to Custom Views (index 6)
                          ref.read(navigationProvider.notifier).state = 6;

                          // If this screen was pushed onto the navigator stack,
                          // we need to pop back to the shell to see the tab switch.
                          while (Navigator.of(context).canPop()) {
                            Navigator.of(context).pop();
                          }
                        } else {
                          _showCustomEnquiryForm(context);
                        }
                      },
                      style: ElevatedButton.styleFrom(
                        backgroundColor: Colors.white,
                        foregroundColor: Colors.black,
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(24),
                        ),
                        elevation: 0,
                      ),
                      child: Row(
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: [
                          Text(
                            ref.read(authProvider).status ==
                                    AuthStatus.authenticated
                                ? 'CUSTOM VIEWS'
                                : 'ENQUIRE FOR CUSTOM VIEWS',
                            style: GoogleFonts.inter(
                              fontWeight: FontWeight.w600,
                              fontSize: 11,
                              letterSpacing: 1,
                            ),
                          ),
                          const SizedBox(width: 12),
                          const Icon(LucideIcons.chevronRight, size: 16),
                        ],
                      ),
                    ),
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  void _showCustomEnquiryForm(BuildContext context) {
    String? submitError;
    showDialog(
      context: context,
      barrierColor: Colors.black.withOpacity(0.6),
      builder: (context) => StatefulBuilder(
        builder: (context, setModalState) {
          final isDark = Theme.of(context).brightness == Brightness.dark;
          // Web parity: a centered floating card with margins on every edge,
          // rounded on all corners — not a full-width bottom sheet.
          return Dialog(
            backgroundColor: isDark ? const Color(0xFF141B3A) : const Color(0xFFF4EFE3),
            insetPadding: const EdgeInsets.symmetric(
              horizontal: 20,
              vertical: 44,
            ),
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(28),
            ),
            clipBehavior: Clip.antiAlias,
            child: ConstrainedBox(
              constraints: BoxConstraints(
                maxHeight: MediaQuery.of(context).size.height * 0.82,
              ),
              child: SingleChildScrollView(
                child: Padding(
                  padding: const EdgeInsets.fromLTRB(24, 28, 24, 28),
                  child: Column(
                    mainAxisSize: MainAxisSize.min,
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Row(
                        mainAxisAlignment: MainAxisAlignment.spaceBetween,
                        children: [
                          Expanded(
                            child: Text(
                              'CUSTOM PERSONALISATION',
                              style: GoogleFonts.inter(
                                color: isDark ? Colors.white : Color(0xFF155A4F),
                                fontWeight: FontWeight.w600,
                                fontSize: 17,
                                letterSpacing: -0.3,
                              ),
                            ),
                          ),
                          IconButton(
                            icon: Icon(
                              LucideIcons.x,
                              color: isDark ? Colors.white : Color(0xFF0C312B),
                              size: 20,
                            ),
                            onPressed: () => Navigator.pop(context),
                          ),
                        ],
                      ),
                      const SizedBox(height: 8),
                      Text(
                        'Enter your details to receive our premium personalisation catalog and schedule a consultation.',
                        style: GoogleFonts.inter(
                          // Web parity: muted gray subtitle, not solid black.
                          color: isDark
                              ? Colors.white54
                              : const Color(0xFFC5A35B),
                          fontSize: 12,
                          height: 1.5,
                          fontWeight: FontWeight.w500,
                        ),
                      ),
                      const SizedBox(height: 32),

                      _buildFieldLabel('FULL NAME'),
                      _buildTextField(
                        _nameController,
                        'Your Name',
                        LucideIcons.user,
                        keyboardType: TextInputType.name,
                        inputFormatters: Validators.nameFormatters,
                      ),
                      const SizedBox(height: 20),

                      _buildFieldLabel('PHONE NUMBER'),
                      _buildTextField(
                        _phoneController,
                        'Mobile Number',
                        LucideIcons.phone,
                        keyboardType: TextInputType.phone,
                        inputFormatters: Validators.phoneFormatters,
                      ),
                      const SizedBox(height: 20),

                      _buildFieldLabel('EMAIL ADDRESS (OPTIONAL)'),
                      _buildTextField(
                        _emailController,
                        'Email Address',
                        LucideIcons.mail,
                        keyboardType: TextInputType.emailAddress,
                        inputFormatters: Validators.emailFormatters,
                      ),
                      const SizedBox(height: 40),

                      if (submitError != null) ...[
                        Container(
                          width: double.infinity,
                          padding: const EdgeInsets.symmetric(
                            horizontal: 14,
                            vertical: 12,
                          ),
                          decoration: BoxDecoration(
                            color: const Color(0xFFC65B46).withOpacity(0.12),
                            borderRadius: BorderRadius.circular(14),
                            border: Border.all(
                              color: const Color(0xFFC65B46).withOpacity(0.4),
                            ),
                          ),
                          child: Row(
                            children: [
                              const Icon(
                                LucideIcons.alertCircle,
                                color: Color(0xFFC65B46),
                                size: 18,
                              ),
                              const SizedBox(width: 10),
                              Expanded(
                                child: Text(
                                  submitError!,
                                  style: GoogleFonts.inter(
                                    color: const Color(0xFFC65B46),
                                    fontSize: 13,
                                    fontWeight: FontWeight.w600,
                                  ),
                                ),
                              ),
                            ],
                          ),
                        ),
                        const SizedBox(height: 16),
                      ],

                      SizedBox(
                        width: double.infinity,
                        height: 60,
                        child: ElevatedButton(
                          onPressed: _isSubmitting
                              ? null
                              : () async {
                                  final vErr =
                                      Validators.nameError(
                                        _nameController.text,
                                        field: 'name',
                                      ) ??
                                      Validators.phoneError(
                                        _phoneController.text,
                                      ) ??
                                      (_emailController.text.trim().isEmpty
                                          ? null
                                          : Validators.emailError(
                                              _emailController.text,
                                            ));
                                  if (vErr != null) {
                                    ScaffoldMessenger.of(context).showSnackBar(
                                      SnackBar(
                                        backgroundColor: const Color(
                                          0xFFC65B46,
                                        ),
                                        content: Text(vErr),
                                      ),
                                    );
                                    return;
                                  }

                                  setModalState(() {
                                    _isSubmitting = true;
                                    submitError = null;
                                  });
                                  try {
                                    final apiClient = ref.read(
                                      apiClientProvider,
                                    );
                                    // Web parity: this is a lead enquiry, so it
                                    // posts to /api/leads (submitLead) with a
                                    // valid `source` enum — not /api/custom-views
                                    // (which expects a full customization payload
                                    // and 400s for a plain enquiry).
                                    await apiClient.submitLead({
                                      'name': _nameController.text.trim(),
                                      'phone': _phoneController.text.trim(),
                                      'email': _emailController.text.trim(),
                                      'source': 'online',
                                    });

                                    if (context.mounted) {
                                      Navigator.pop(context);
                                      ScaffoldMessenger.of(
                                        context,
                                      ).showSnackBar(
                                        const SnackBar(
                                          backgroundColor: Color(0xFF163A2C),
                                          content: Text(
                                            'Enquiry submitted successfully! We will contact you soon.',
                                          ),
                                        ),
                                      );
                                      _nameController.clear();
                                      _phoneController.clear();
                                      _emailController.clear();
                                    }
                                  } catch (e) {
                                    // Show a short, friendly error INSIDE the
                                    // dialog (on top) instead of dumping the raw
                                    // DioException in a giant toast behind it.
                                    setModalState(
                                      () => submitError =
                                          'Could not submit right now. Please check your details and try again.',
                                    );
                                  } finally {
                                    if (context.mounted)
                                      setModalState(
                                        () => _isSubmitting = false,
                                      );
                                  }
                                },
                          style: ElevatedButton.styleFrom(
                            backgroundColor: isDark
                                ? Colors.white
                                : Color(0xFF0C312B),
                            foregroundColor: isDark
                                ? Colors.black
                                : const Color(0xFFF4EFE3),
                            shape: RoundedRectangleBorder(
                              borderRadius: BorderRadius.circular(20),
                            ),
                          ),
                          child: _isSubmitting
                              ? SizedBox(
                                  width: 20,
                                  height: 20,
                                  child: CircularProgressIndicator(
                                    strokeWidth: 2,
                                    color: Theme.of(context).scaffoldBackgroundColor,
                                  ),
                                )
                              : Text(
                                  'SEND REQUEST',
                                  style: GoogleFonts.inter(
                                    fontWeight: FontWeight.w400,
                                    fontSize: 12,
                                    letterSpacing: 2,
                                  ),
                                ),
                        ),
                      ),
                    ],
                  ),
                ),
              ),
            ),
          );
        },
      ),
    );
  }

  Widget _buildFieldLabel(String label) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    return Padding(
      padding: const EdgeInsets.only(left: 4, bottom: 10),
      child: Text(
        label,
        style: GoogleFonts.inter(
          // Web parity: muted slate-gray field labels.
          color: isDark ? Colors.white54 : const Color(0xFFC5A35B),
          fontSize: 10,
          fontWeight: FontWeight.w700,
          letterSpacing: 1.2,
        ),
      ),
    );
  }

  Widget _buildTextField(
    TextEditingController controller,
    String hint,
    IconData icon, {
    TextInputType? keyboardType,
    List<TextInputFormatter>? inputFormatters,
  }) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    // Web parity: plain light-filled input, no leading icon, and a gold
    // border only while focused (matches the reference popup).
    final fill = isDark
        ? Colors.white.withOpacity(0.04)
        : const Color(0xFFC5A35B);
    final baseBorder = isDark
        ? Colors.white.withOpacity(0.06)
        : Colors.transparent;
    const gold = Color(0xFFC5A35B);
    return TextField(
      controller: controller,
      keyboardType: keyboardType,
      inputFormatters: inputFormatters,
      style: GoogleFonts.inter(
        color: isDark ? Colors.white : Color(0xFF155A4F),
        fontSize: 15,
        fontWeight: FontWeight.w500,
      ),
      decoration: InputDecoration(
        hintText: hint,
        hintStyle: GoogleFonts.inter(
          color: isDark ? Colors.white38 : const Color(0xFFC5A35B),
          fontSize: 14,
          fontWeight: FontWeight.w500,
        ),
        filled: true,
        fillColor: fill,
        contentPadding: const EdgeInsets.symmetric(
          horizontal: 20,
          vertical: 18,
        ),
        enabledBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(16),
          borderSide: BorderSide(color: baseBorder, width: 1),
        ),
        focusedBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(16),
          borderSide: const BorderSide(color: gold, width: 1.8),
        ),
      ),
    );
  }

  Widget _buildNavigationButtons() {
    final isDark = Theme.of(context).brightness == Brightness.dark;

    return Row(
      children: [
        if (_currentStep > 0)
          Expanded(
            flex: 1,
            child: Padding(
              padding: const EdgeInsets.only(right: 12),
              child: OutlinedButton(
                onPressed: () {
                  setState(() => _currentStep--);
                  _scrollController.animateTo(
                    0,
                    duration: const Duration(milliseconds: 300),
                    curve: Curves.easeOut,
                  );
                },
                style: OutlinedButton.styleFrom(
                  padding: const EdgeInsets.symmetric(vertical: 18),
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(20),
                  ),
                  side: BorderSide(
                    color: isDark ? Colors.white24 : Colors.black26,
                    width: 1.5,
                  ),
                ),
                child: Text(
                  'BACK',
                  style: GoogleFonts.gelasio(
                    color: isDark ? Colors.white : Color(0xFF0C312B),
                    fontWeight: FontWeight.w700,
                    fontSize: 10,
                    letterSpacing: 2,
                  ),
                ),
              ),
            ),
          ),
        if (_currentStep < _steps.length - 1)
          Expanded(
            flex: 2,
            child: ElevatedButton(
              onPressed: () {
                if (_currentStep < _steps.length - 1) {
                  setState(() => _currentStep++);
                  _scrollController.animateTo(
                    0,
                    duration: const Duration(milliseconds: 300),
                    curve: Curves.easeOut,
                  );
                }
              },
              style: ElevatedButton.styleFrom(
                backgroundColor: isDark ? Colors.white : Color(0xFF0C312B),
                foregroundColor: isDark ? Colors.black : const Color(0xFFF4EFE3),
                padding: const EdgeInsets.symmetric(vertical: 18),
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(20),
                ),
              ),
              child: Row(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Text(
                    'NEXT STEP',
                    style: GoogleFonts.gelasio(
                      fontWeight: FontWeight.w700,
                      fontSize: 10,
                      letterSpacing: 2,
                    ),
                  ),
                  const SizedBox(width: 8),
                  Icon(
                    LucideIcons.chevronRight,
                    size: 14,
                    color: Theme.of(context).scaffoldBackgroundColor,
                  ),
                ],
              ),
            ),
          ),
      ],
    );
  }

  IconData _getIconData(String? iconName) {
    switch (iconName) {
      case 'Users':
        return LucideIcons.users;
      case 'Target':
        return LucideIcons.target;
      case 'Trophy':
        return LucideIcons.trophy;
      case 'Award':
        return LucideIcons.award;
      case 'ShieldCheck':
        return LucideIcons.shieldCheck;
      case 'Compass':
        return LucideIcons.compass;
      case 'Sparkles':
        return LucideIcons.sparkles;
      case 'Eye':
        return LucideIcons.eye;
      case 'Milestone':
        return LucideIcons.milestone;
      case 'Heart':
        return LucideIcons.heart;
      case 'Briefcase':
        return LucideIcons.briefcase;
      default:
        return LucideIcons.helpCircle;
    }
  }
}
