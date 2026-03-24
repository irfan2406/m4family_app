import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:m4_mobile/core/theme/app_theme.dart';
import 'package:flutter_animate/flutter_animate.dart';
import 'package:lucide_icons/lucide_icons.dart';
import 'package:google_fonts/google_fonts.dart';
import 'dart:ui';
import 'package:m4_mobile/presentation/widgets/main_shell.dart';

class DashboardScreen extends ConsumerStatefulWidget {
  const DashboardScreen({super.key});

  @override
  ConsumerState<DashboardScreen> createState() => _DashboardScreenState();
}

class _DashboardScreenState extends ConsumerState<DashboardScreen> {
  final PageController _featuredController = PageController();
  final ScrollController _scrollController = ScrollController();
  final GlobalKey _inquiryKey = GlobalKey();
  
  String _searchQuery = '';
  String _selectedCategory = 'ALL';

  @override
  void dispose() {
    _featuredController.dispose();
    _scrollController.dispose();
    super.dispose();
  }

  void _scrollToInquiry() {
    Scrollable.ensureVisible(
      _inquiryKey.currentContext!,
      duration: const Duration(seconds: 1),
      curve: Curves.easeInOut,
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: M4Theme.background,
      body: CustomScrollView(
        controller: _scrollController,
        slivers: [
          // 1. Featured Selection (Functional Slider - TOP ELEMENT)
          SliverToBoxAdapter(
            child: Padding(
              padding: const EdgeInsets.symmetric(horizontal: 0, vertical: 0),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  const SizedBox(height: 50), // Status bar space
                  Padding(
                    padding: const EdgeInsets.symmetric(horizontal: 20),
                    child: Text(
                      'FEATURED PROPERTY',
                      style: GoogleFonts.montserrat(
                        fontSize: 10,
                        fontWeight: FontWeight.w900,
                        color: Colors.white54,
                        letterSpacing: 2,
                      ),
                    ),
                  ),
                  const SizedBox(height: 20),
                  SizedBox(
                    height: 420,
                    child: PageView.builder(
                      controller: _featuredController,
                      itemCount: 3,
                      itemBuilder: (context, index) {
                        final images = [
                          'https://images.pexels.com/photos/323780/pexels-photo-323780.jpeg?auto=compress&cs=tinysrgb&w=1200',
                          'https://images.pexels.com/photos/1571460/pexels-photo-1571460.jpeg?auto=compress&cs=tinysrgb&w=1200',
                          'https://images.pexels.com/photos/209235/pexels-photo-209235.jpeg?auto=compress&cs=tinysrgb&w=1200',
                        ];
                        final titles = ['CLÉDOR', 'M4 AURA', 'SKAI RESIDENCES'];
                        
                        return Stack(
                          children: [
                            ClipRRect(
                              borderRadius: BorderRadius.circular(40),
                              child: Image.network(
                                images[index],
                                height: 420,
                                width: double.infinity,
                                fit: BoxFit.cover,
                                errorBuilder: (context, error, stackTrace) => Container(
                                  color: Colors.white10,
                                  child: const Center(child: Icon(LucideIcons.image, color: Colors.white24)),
                                ),
                              ),
                            ),
                            Container(
                              height: 420,
                              decoration: BoxDecoration(
                                borderRadius: BorderRadius.circular(40),
                                gradient: LinearGradient(
                                  begin: Alignment.topCenter,
                                  end: Alignment.bottomCenter,
                                  colors: [Colors.transparent, Colors.black.withOpacity(0.9)],
                                  stops: const [0.7, 1.0],
                                ),
                              ),
                            ),
                            Positioned(
                              bottom: 20,
                              left: 30,
                              child: Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  Text(
                                    'FEATURED SELECTION',
                                    style: GoogleFonts.montserrat(
                                      fontSize: 10,
                                      fontWeight: FontWeight.w600,
                                      color: Colors.white.withOpacity(0.7),
                                      letterSpacing: 1,
                                    ),
                                  ),
                                  Text(
                                    titles[index],
                                    style: GoogleFonts.montserrat(
                                      fontSize: 34,
                                      fontWeight: FontWeight.bold,
                                      color: Colors.white,
                                    ),
                                  ),
                                ],
                              ).animate().fadeIn(delay: 400.ms).moveY(begin: 10, end: 0),
                            ),
                          ],
                        ).animate().fadeIn();
                      },
                    ),
                  ),
                  const SizedBox(height: 30),
                  Row(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      _SliderNavButton(
                        icon: LucideIcons.arrowLeft, 
                        onTap: () => _featuredController.previousPage(duration: 500.ms, curve: Curves.easeInOut),
                      ),
                      const SizedBox(width: 20),
                      GestureDetector(
                        onTap: () => ref.read(navigationProvider.notifier).state = 1,
                        child: Container(
                          padding: const EdgeInsets.symmetric(horizontal: 50, vertical: 16),
                          decoration: BoxDecoration(
                            color: Colors.white,
                            borderRadius: BorderRadius.circular(30),
                          ),
                          child: Text(
                            'EXPLORE NOW',
                            style: GoogleFonts.montserrat(
                              color: Colors.black,
                              fontWeight: FontWeight.w900,
                              fontSize: 11,
                              letterSpacing: 1.5,
                            ),
                          ),
                        ),
                      ),
                      const SizedBox(width: 20),
                      _SliderNavButton(
                        icon: LucideIcons.arrowRight, 
                        onTap: () => _featuredController.nextPage(duration: 500.ms, curve: Curves.easeInOut),
                      ),
                    ],
                  ).animate().fadeIn(delay: 500.ms),
                ],
              ),
            ),
          ),

          // Slider placeholder for removal (already replaced above)

          // 4. Recommended Section
          SliverToBoxAdapter(
            child: Padding(
              padding: const EdgeInsets.symmetric(horizontal: 20.0),
              child: Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                   Text(
                    'RECOMMENDED FOR YOU',
                    style: GoogleFonts.montserrat(fontSize: 10, fontWeight: FontWeight.w900, color: Colors.white54, letterSpacing: 1.5),
                  ),
                  Text(
                    'VIEW ALL',
                    style: GoogleFonts.montserrat(fontSize: 10, fontWeight: FontWeight.w900, color: Colors.white, letterSpacing: 1.5),
                  ),
                ],
              ),
            ),
          ),

          SliverToBoxAdapter(
            child: SizedBox(
              height: 380,
              child: Builder(
                builder: (context) {
                  final projects = [
                    {'title': 'M4 AURA', 'category': 'ONGOING'},
                    {'title': 'SKAI RESIDENCES', 'category': 'UPCOMING'},
                    {'title': 'CLÉDOR', 'category': 'ONGOING'},
                  ];
                  
                  final filtered = projects.where((p) {
                    final matchesSearch = p['title']!.toLowerCase().contains(_searchQuery.toLowerCase());
                    final matchesCategory = _selectedCategory == 'ALL' || p['category'] == _selectedCategory;
                    return matchesSearch && matchesCategory;
                  }).toList();

                  if (filtered.isEmpty) {
                    return Center(
                      child: Text('No projects found', style: GoogleFonts.montserrat(color: Colors.white24)),
                    );
                  }

                  return ListView.builder(
                    scrollDirection: Axis.horizontal,
                    padding: const EdgeInsets.all(20),
                    itemCount: filtered.length,
                    itemBuilder: (context, index) => _ProjectCard(
                      index: index,
                      title: filtered[index]['title']!,
                      onTap: () {
                        ScaffoldMessenger.of(context).showSnackBar(
                          SnackBar(content: Text('Viewing ${filtered[index]['title']} detail...'))
                        );
                      },
                    ),
                  );
                }
              ),
            ),
          ),

          // 5. Philosophy Section
          SliverToBoxAdapter(
            child: Padding(
              padding: const EdgeInsets.all(30.0),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    'OUR PHILOSOPHY',
                    style: GoogleFonts.montserrat(fontSize: 24, fontWeight: FontWeight.bold, color: Colors.white),
                  ),
                  const SizedBox(height: 16),
                  Text(
                    'To redefine modern luxury living by crafting homes with cutting edge design, enduring quality and thoughtful amenities delivered with trust, transparency, timeliness, and a human touch that creates lasting value for every homeowner.',
                    style: GoogleFonts.montserrat(color: Colors.white70, fontSize: 13, height: 1.6),
                  ),
                ],
              ),
            ),
          ),

          // 6. Quick Actions Grid
          SliverToBoxAdapter(
            child: Padding(
              padding: const EdgeInsets.symmetric(horizontal: 20),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  const Text('FEATURED SELECTION', style: TextStyle(color: Colors.white54, fontSize: 9, fontWeight: FontWeight.bold, letterSpacing: 1.5)),
                  Text('CLÉDOR', style: GoogleFonts.montserrat(fontSize: 24, fontWeight: FontWeight.bold, color: Colors.white)),
                  const SizedBox(height: 20),
                  Row(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      GestureDetector(
                        onTap: () {
                          _featuredController.previousPage(
                            duration: const Duration(milliseconds: 500),
                            curve: Curves.easeInOut,
                          );
                        },
                        child: Container(
                          padding: const EdgeInsets.all(12),
                          decoration: BoxDecoration(shape: BoxShape.circle, color: Colors.white.withOpacity(0.05), border: Border.all(color: Colors.white10)),
                          child: const Icon(LucideIcons.arrowLeft, color: Colors.white, size: 16),
                        ),
                      ),
                      const SizedBox(width: 20),
                      Container(
                        padding: const EdgeInsets.symmetric(horizontal: 40, vertical: 16),
                        decoration: BoxDecoration(color: Colors.white, borderRadius: BorderRadius.circular(30)),
                        child: Text('EXPLORE NOW', style: GoogleFonts.montserrat(color: Colors.black, fontWeight: FontWeight.bold, fontSize: 12)),
                      ),
                      const SizedBox(width: 20),
                      GestureDetector(
                        onTap: () {
                          _featuredController.nextPage(
                            duration: const Duration(milliseconds: 500),
                            curve: Curves.easeInOut,
                          );
                        },
                        child: Container(
                          padding: const EdgeInsets.all(12),
                          decoration: BoxDecoration(shape: BoxShape.circle, color: Colors.white.withOpacity(0.05), border: Border.all(color: Colors.white10)),
                          child: const Icon(LucideIcons.arrowRight, color: Colors.white, size: 16),
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 40),
                  // 3. Quick Action Row (Image 2 Match: Single Row of 4 Icons)
                  Padding(
                    padding: const EdgeInsets.symmetric(horizontal: 0, vertical: 20),
                    child: Row(
                      mainAxisAlignment: MainAxisAlignment.spaceAround,
                      children: [
                        _QuickAction(
                          icon: LucideIcons.search, 
                          label: 'EXPLORE', 
                          onTap: () => ref.read(navigationProvider.notifier).state = 1,
                        ),
                        _QuickAction(
                          icon: LucideIcons.mapPin, 
                          label: 'VISIT', 
                          onTap: () => ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('Launching site map...'))),
                        ),
                        _QuickAction(
                          icon: LucideIcons.playCircle, 
                          label: 'VIDEO', 
                          onTap: () => ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('Opening virtual walkthrough...'))),
                        ),
                        _QuickAction(
                          icon: LucideIcons.edit3, 
                          label: 'REGISTER', 
                          onTap: _scrollToInquiry,
                        ),
                      ],
                    ),
                  ),
                ],
              ),
            ),
          ),

          // 7. Inquiry Form (FUNCTIONAL SCROLL TARGET)
          SliverToBoxAdapter(
            key: _inquiryKey,
            child: Container(
              padding: const EdgeInsets.fromLTRB(30, 80, 30, 60),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    'REGISTER YOUR\nINTEREST',
                    style: GoogleFonts.montserrat(fontSize: 32, fontWeight: FontWeight.w300, color: Colors.white, height: 1.1),
                  ),
                  const Text('OFFICIAL INQUIRY FORM', style: TextStyle(color: Colors.white54, fontSize: 10, fontWeight: FontWeight.bold, letterSpacing: 2)),
                  const SizedBox(height: 48),
                  _PremiumFormField(label: 'Full Name *'),
                  _PremiumFormField(label: 'Email Address *'),
                  _PremiumFormField(label: 'Phone Number *'),
                  _PremiumFormField(label: 'Select Project *', hasDropdown: true),
                  const SizedBox(height: 32),
                  SizedBox(
                    width: double.infinity,
                    child: ElevatedButton(
                      onPressed: () {
                        ScaffoldMessenger.of(context).showSnackBar(
                          const SnackBar(
                            content: Text('Thank you! Interest registered successfully.'),
                            backgroundColor: M4Theme.premiumBlue,
                          ),
                        );
                      },
                      style: ElevatedButton.styleFrom(
                        backgroundColor: Colors.white,
                        foregroundColor: Colors.black,
                        padding: const EdgeInsets.symmetric(vertical: 22),
                        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(15)),
                      ),
                      child: Text('SUBMIT INTEREST', style: GoogleFonts.montserrat(fontWeight: FontWeight.bold, letterSpacing: 3, fontSize: 12)),
                    ),
                  ),
                ],
              ),
            ),
          ),
          
          const SliverToBoxAdapter(child: SizedBox(height: 120)),
        ],
      ),
    );
  }
}

class _CategoryChip extends StatelessWidget {
  final String label;
  final bool isActive;
  final VoidCallback? onTap;
  const _CategoryChip({required this.label, this.isActive = false, this.onTap});

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 30, vertical: 12),
        decoration: BoxDecoration(
          color: isActive ? Colors.white : Colors.white.withOpacity(0.05),
          borderRadius: BorderRadius.circular(30),
          border: Border.all(color: Colors.white10),
        ),
        child: Text(
          label,
          style: TextStyle(
            color: isActive ? Colors.black : Colors.white60,
            fontSize: 10,
            fontWeight: FontWeight.bold,
            letterSpacing: 1.2,
          ),
        ),
      ),
    );
  }
}

class _ProjectCard extends StatelessWidget {
  final int index;
  final String title;
  final VoidCallback onTap;
  const _ProjectCard({super.key, required this.index, required this.title, required this.onTap});

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        width: 280,
        margin: const EdgeInsets.only(right: 20),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Expanded(
              child: Stack(
                children: [
                  ClipRRect(
                    borderRadius: BorderRadius.circular(20),
                    child: Image.network(
                      index == 0 
                        ? 'https://images.unsplash.com/photo-1545324418-cc1a3fa10c00?auto=format&fit=crop&q=80'
                        : 'https://images.unsplash.com/photo-1512917774080-9991f1c4c750?auto=format&fit=crop&q=80',
                      width: double.infinity,
                      fit: BoxFit.cover,
                    ),
                  ),
                  Positioned(
                    top: 15,
                    left: 15,
                    child: Container(
                      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 5),
                      decoration: BoxDecoration(color: Colors.black54, borderRadius: BorderRadius.circular(10)),
                      child: Text(index == 0 ? 'COMPLETED' : 'UPCOMING', style: const TextStyle(color: Colors.white, fontSize: 8, fontWeight: FontWeight.bold)),
                    ),
                  ),
                  Positioned(
                    top: 15,
                    right: 15,
                    child: Container(
                      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 5),
                      decoration: BoxDecoration(color: Colors.black54, borderRadius: BorderRadius.circular(10)),
                      child: const Text('ARTISTIC IMPRESSION', style: TextStyle(color: Colors.white, fontSize: 8, fontWeight: FontWeight.bold)),
                    ),
                  ),
                ],
              ),
            ),
            const SizedBox(height: 12),
            Text(
              index == 0 ? 'OCEAN VIEW' : 'PROJECT WORKSPACE',
              style: GoogleFonts.montserrat(fontSize: 16, fontWeight: FontWeight.bold, color: Colors.white),
            ),
            Row(
              children: [
                const Icon(LucideIcons.mapPin, color: Colors.white54, size: 10),
                const SizedBox(width: 4),
                Text('N/A', style: GoogleFonts.montserrat(color: Colors.white54, fontSize: 10)),
              ],
            ),
            const SizedBox(height: 12),
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
              decoration: BoxDecoration(color: Colors.white10, borderRadius: BorderRadius.circular(10)),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  const Text('STARTING FROM', style: TextStyle(color: Colors.white38, fontSize: 7, fontWeight: FontWeight.bold)),
                  Text('N/A', style: GoogleFonts.montserrat(fontSize: 12, fontWeight: FontWeight.bold, color: Colors.white)),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _QuickAction extends StatelessWidget {
  final IconData icon;
  final String label;
  final VoidCallback onTap;

  const _QuickAction({required this.icon, required this.label, required this.onTap});

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onTap,
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          Container(
            padding: const EdgeInsets.all(12),
            decoration: BoxDecoration(
              color: Colors.white.withOpacity(0.05),
              borderRadius: BorderRadius.circular(15),
              border: Border.all(color: Colors.white.withOpacity(0.05)),
            ),
            child: Icon(icon, color: Colors.white, size: 22),
          ),
          const SizedBox(height: 8),
          Text(
            label,
            style: GoogleFonts.montserrat(
              fontSize: 8,
              fontWeight: FontWeight.w900,
              color: Colors.white54,
              letterSpacing: 1,
            ),
          ),
        ],
      ),
    );
  }
}

class _QuickActionBox extends StatelessWidget {
  final IconData icon;
  final String title;
  final String subtitle;
  final VoidCallback? onTap;

  const _QuickActionBox({required this.icon, required this.title, required this.subtitle, this.onTap});

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        decoration: BoxDecoration(
          color: const Color(0xFF0C0C0E), // Match Image 2 deep dark
          borderRadius: BorderRadius.circular(35),
          border: Border.all(color: Colors.white.withOpacity(0.08)),
        ),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Container(
              padding: const EdgeInsets.all(12),
              decoration: BoxDecoration(
                shape: BoxShape.circle,
                color: Colors.white.withOpacity(0.05),
              ),
              child: Icon(icon, color: Colors.white70, size: 24),
            ),
            const SizedBox(height: 12),
            Text(
              title, 
              style: GoogleFonts.montserrat(
                fontSize: 13, 
                fontWeight: FontWeight.w900, 
                color: Colors.white, 
                letterSpacing: 1.5,
              ),
            ),
            const SizedBox(height: 4),
            Text(
              subtitle, 
              style: GoogleFonts.montserrat(
                fontSize: 8, 
                color: Colors.white38, 
                fontWeight: FontWeight.w900,
                letterSpacing: 0.5,
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _QuickFilterSheet extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    return Container(
      decoration: const BoxDecoration(
        color: Color(0xFF070708),
        borderRadius: BorderRadius.only(topLeft: Radius.circular(35), topRight: Radius.circular(35)),
      ),
      padding: const EdgeInsets.fromLTRB(25, 15, 25, 40),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Center(
            child: Container(
              width: 40,
              height: 4,
              decoration: BoxDecoration(color: Colors.white24, borderRadius: BorderRadius.circular(2)),
            ),
          ),
          const SizedBox(height: 25),
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Text(
                'QUICK FILTERS',
                style: GoogleFonts.montserrat(
                  fontSize: 18, 
                  fontWeight: FontWeight.w900, 
                  color: Colors.white,
                  letterSpacing: 1,
                ),
              ),
              GestureDetector(
                onTap: () => Navigator.pop(context),
                child: Container(
                  padding: const EdgeInsets.all(8),
                  decoration: const BoxDecoration(shape: BoxShape.circle, color: Color(0xFF1C1C1E)),
                  child: const Icon(LucideIcons.x, color: Colors.white, size: 18),
                ),
              ),
            ],
          ),
          const SizedBox(height: 35),
          _FilterSection(title: 'LOCATION', options: const ['SOUTH MUMBAI', 'WORLI', 'BANDRA', 'JUHU', 'POWAI']),
          const SizedBox(height: 30),
          _FilterSection(title: 'PROPERTY TYPE', options: const ['RESIDENTIAL', 'COMMERCIAL']),
          const SizedBox(height: 50),
          GestureDetector(
            onTap: () => Navigator.pop(context),
            child: Container(
              width: double.infinity,
              padding: const EdgeInsets.symmetric(vertical: 20),
              decoration: BoxDecoration(
                color: Colors.white,
                borderRadius: BorderRadius.circular(35),
              ),
              child: Center(
                child: Text(
                  'SHOW RESULTS',
                  style: GoogleFonts.montserrat(
                    color: Colors.black,
                    fontWeight: FontWeight.w900,
                    fontSize: 12,
                    letterSpacing: 1.5,
                  ),
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }
}

class _FilterSection extends StatelessWidget {
  final String title;
  final List<String> options;

  const _FilterSection({required this.title, required this.options});

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          title,
          style: GoogleFonts.montserrat(
            fontSize: 10,
            fontWeight: FontWeight.w900,
            color: Colors.white54,
            letterSpacing: 1.5,
          ),
        ),
        const SizedBox(height: 15),
        Wrap(
          spacing: 10,
          runSpacing: 12,
          children: options.map((opt) => Container(
            padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 12),
            decoration: BoxDecoration(
              color: const Color(0xFF101012),
              borderRadius: BorderRadius.circular(20),
              border: Border.all(color: Colors.white.withOpacity(0.05)),
            ),
            child: Text(
              opt,
              style: GoogleFonts.montserrat(
                color: Colors.white,
                fontSize: 9,
                fontWeight: FontWeight.w900,
                letterSpacing: 1,
              ),
            ),
          )).toList(),
        ),
      ],
    );
  }
}

class _SliderNavButton extends StatelessWidget {
  final IconData icon;
  final VoidCallback onTap;
  const _SliderNavButton({required this.icon, required this.onTap});

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        padding: const EdgeInsets.all(14),
        decoration: BoxDecoration(
          shape: BoxShape.circle,
          color: Colors.white.withOpacity(0.05),
          border: Border.all(color: Colors.white.withOpacity(0.1)),
        ),
        child: Icon(icon, color: Colors.white, size: 18),
      ),
    );
  }
}

class _PremiumFormField extends StatelessWidget {
  final String label;
  final bool hasDropdown;
  const _PremiumFormField({required this.label, this.hasDropdown = false});

  @override
  Widget build(BuildContext context) {
    return Container(
      margin: const EdgeInsets.only(bottom: 20),
      child: ClipRRect(
        borderRadius: BorderRadius.circular(15),
        child: BackdropFilter(
          filter: ImageFilter.blur(sigmaX: 5, sigmaY: 5),
          child: Container(
            padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 22),
            decoration: BoxDecoration(
              color: Colors.white.withOpacity(0.02),
              borderRadius: BorderRadius.circular(15),
              border: Border.all(color: Colors.white.withOpacity(0.05)),
            ),
            child: Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Text(label, style: GoogleFonts.montserrat(color: Colors.white30, fontSize: 13, fontWeight: FontWeight.w500)),
                if (hasDropdown) const Icon(LucideIcons.chevronDown, color: Colors.white30, size: 16),
              ],
            ),
          ),
        ),
      ),
    );
  }
}
