import 'dart:ui';
import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:lucide_icons/lucide_icons.dart';
import 'package:flutter_animate/flutter_animate.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:m4_mobile/core/network/api_client.dart';
import 'package:dio/dio.dart';
import 'package:m4_mobile/presentation/providers/auth_provider.dart';


class AboutScreen extends ConsumerStatefulWidget {
  const AboutScreen({super.key});

  @override
  ConsumerState<AboutScreen> createState() => _AboutScreenState();
}

class _AboutScreenState extends ConsumerState<AboutScreen> {
  Map<String, dynamic>? _cmsData;
  bool _isLoading = true;
  String? _error;

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
        setState(() {
          _error = response.data['message'] ?? 'Failed to load content';
          _isLoading = false;
        });
      }
    } catch (e) {
      setState(() {
        _error = 'Error connection to server: $e';
        _isLoading = false;
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Theme.of(context).scaffoldBackgroundColor,
      extendBodyBehindAppBar: true,
      appBar: AppBar(
        backgroundColor: Colors.transparent,
        elevation: 0,
        leading: IconButton(
          icon: const Icon(LucideIcons.chevronLeft, color: Colors.white70),
          onPressed: () => Navigator.pop(context),
        ),
      ),
      body: Container(
        decoration: const BoxDecoration(
          color: Colors.black,
          gradient: RadialGradient(
            center: Alignment.topLeft,
            radius: 1.5,
            colors: [Color(0xFF0A0C14), Colors.black],
          ),
        ),

        child: _isLoading 
          ? const Center(child: CircularProgressIndicator(color: Colors.white24))
          : _error != null
            ? Center(child: Text(_error!, style: const TextStyle(color: Colors.white38)))
            : SingleChildScrollView(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    _buildHero(),
                    Padding(
                      padding: const EdgeInsets.symmetric(horizontal: 24),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          const SizedBox(height: 32),
                          _buildLegacyCard(),
                          const SizedBox(height: 48),
                          _buildOurStory(),
                          const SizedBox(height: 48),
                          _buildSections(),
                          const SizedBox(height: 120),
                        ],
                      ),

                    ),
                  ],
                ),
              ),
      ),
    );
  }

  Widget _buildHero() {
    return Padding(
      padding: const EdgeInsets.only(top: 100, left: 24, right: 24, bottom: 24),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            _cmsData?['title']?.toUpperCase() ?? 'ABOUT M4',
            style: GoogleFonts.montserrat(
              fontSize: 32,
              fontWeight: FontWeight.w300,
              color: Colors.white,
              letterSpacing: 4,
            ),
          ),
          const SizedBox(height: 12),
          Text(
            _cmsData?['subtitle']?.toUpperCase() ?? 'VISION',
            style: GoogleFonts.montserrat(
              fontSize: 10,
              fontWeight: FontWeight.w900,
              color: Colors.white54,
              letterSpacing: 6,
            ),
          ),
        ],
      ).animate().fadeIn().slideY(begin: 0.1),
    );
  }


  Widget _buildLegacyCard() {
    return ClipRRect(
      borderRadius: BorderRadius.circular(24),
      child: BackdropFilter(
        filter: ImageFilter.blur(sigmaX: 10, sigmaY: 10),
        child: Container(
          width: double.infinity,
          padding: const EdgeInsets.all(32),
          decoration: BoxDecoration(
            color: Colors.white.withOpacity(0.08),
            borderRadius: BorderRadius.circular(24),
            border: Border.all(color: Colors.white.withOpacity(0.05)),
          ),

          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                'M4 LEGACY',
                style: GoogleFonts.montserrat(
                  color: Colors.white38,
                  fontWeight: FontWeight.w900,
                  fontSize: 10,
                  letterSpacing: 2,
                ),
              ),
              const SizedBox(height: 12),
              Text(
                'ESTABLISHED 2011',
                style: GoogleFonts.montserrat(
                  color: Colors.white54,
                  fontWeight: FontWeight.bold,
                  fontSize: 11,
                  letterSpacing: 1,
                ),
              ),
              const SizedBox(height: 24),
              Text(
                'INSTITUTIONAL GRADE DEVELOPMENT',
                style: GoogleFonts.montserrat(
                  color: Colors.white,
                  fontWeight: FontWeight.w900,
                  fontSize: 22,
                  height: 1.1,
                  letterSpacing: -0.5,
                ),
              ),
              const SizedBox(height: 12),
              Text(
                _cmsData?['content']?.toUpperCase() ?? 'INSTITUTIONAL GRADE DEVELOPMENT',
                style: GoogleFonts.montserrat(
                  color: Colors.white54,
                  fontWeight: FontWeight.bold,
                  fontSize: 10,
                  letterSpacing: 1.5,
                ),
              ),
            ],
          ),
        ),
      ),
    ).animate().fadeIn(delay: 200.ms).slideX(begin: 0.1);
  }

  Widget _buildOurStory() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          children: [
            Container(
              padding: const EdgeInsets.all(8),
              decoration: BoxDecoration(
                color: const Color(0xFF111418), // Dark box from the image
                borderRadius: BorderRadius.circular(8),
                border: Border.all(color: Colors.white.withOpacity(0.05)),
              ),
              child: const Icon(LucideIcons.building2, color: Colors.white, size: 16),
            ),

            const SizedBox(width: 16),
            Text(
              'OUR STORY',
              style: GoogleFonts.montserrat(
                fontSize: 12,
                fontWeight: FontWeight.w900,
                color: Colors.white,
                letterSpacing: 2,
              ),
            ),
          ],
        ),
        const SizedBox(height: 24),
        Text(
          'M4 Family, with over a decade of excellence in Mumbai’s real estate landscape, has established itself as a trusted name in premium residential development. Renowned for delivering homes that blend contemporary design with enduring quality, we take pride in creating spaces that inspire modern living while retaining timeless value.\n\nEvery development we undertake reflects meticulous planning, uncompromising quality, and a commitment to delivering on promises. With a focus on elevating lifestyles, our projects are crafted not only to meet expectations but to create lasting experiences that residents cherish for a lifetime.\n\nFrom Aura Heights at Grant Road, where families discovered the joy of refined living, to our latest offering Ocean View — a modern coastal address designed to enrich the lifestyle of South East Mumbai. M4 Family continues to redefine what it means to call a place home.\n\nAt M4 Family, we don’t just build residences; we build trust, foster belonging, and shape spaces that endure through generations.',
          style: GoogleFonts.montserrat(
            fontSize: 14,
            height: 1.8,
            color: Colors.white.withOpacity(0.7),
            fontWeight: FontWeight.w400,
          ),
        ),
      ],
    ).animate().fadeIn(delay: 400.ms);
  }

  Widget _buildSections() {
    final sections = (_cmsData?['sections'] as List?) ?? [];
    if (sections.isEmpty) return const SizedBox.shrink();

    return Column(
      children: sections.map((section) {
        return Padding(
          padding: const EdgeInsets.only(bottom: 24),
          child: _SectionCard(
            title: section['title'] ?? '',
            content: section['content'] ?? '',
            iconName: section['icon'] ?? 'Target',
          ),
        );
      }).toList(),
    ).animate().fadeIn(delay: 600.ms);
  }


}

class _SectionCard extends StatelessWidget {
  final String title;
  final String content;
  final String iconName;

  const _SectionCard({
    required this.title,
    required this.content,
    required this.iconName,
  });

  IconData _getIcon() {
    switch (iconName) {
      case 'Target': return LucideIcons.target;
      case 'Award': return LucideIcons.award;
      case 'Users': return LucideIcons.users;
      default: return LucideIcons.sparkles;
    }
  }

  @override
  Widget build(BuildContext context) {
    return ClipRRect(
      borderRadius: BorderRadius.circular(20),
      child: BackdropFilter(
        filter: ImageFilter.blur(sigmaX: 5, sigmaY: 5),
        child: Container(
          padding: const EdgeInsets.all(24),
          decoration: BoxDecoration(
            color: Colors.white.withOpacity(0.08),
            borderRadius: BorderRadius.circular(20),
            border: Border.all(color: Colors.white.withOpacity(0.05)),
          ),

          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Container(
                padding: const EdgeInsets.all(8),
                decoration: BoxDecoration(
                  color: Colors.white.withOpacity(0.05),
                  borderRadius: BorderRadius.circular(10),
                ),
                child: Icon(_getIcon(), color: Colors.white70, size: 20),
              ),
              const SizedBox(height: 20),
              Text(
                title.toUpperCase(),
                style: GoogleFonts.montserrat(
                  fontSize: 10,
                  fontWeight: FontWeight.w900,
                  color: Colors.white38,
                  letterSpacing: 2,
                ),
              ),
              const SizedBox(height: 12),
              Text(
                content,
                style: GoogleFonts.montserrat(
                  fontSize: 13,
                  height: 1.6,
                  color: Colors.white70,
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
