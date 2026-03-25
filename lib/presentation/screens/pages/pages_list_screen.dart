import 'dart:ui';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:lucide_icons/lucide_icons.dart';
import 'package:flutter_animate/flutter_animate.dart';
import 'package:m4_mobile/core/network/api_client.dart';
import 'package:m4_mobile/presentation/providers/auth_provider.dart';
import 'package:m4_mobile/presentation/screens/pages/page_detail_screen.dart';

class PagesListScreen extends ConsumerStatefulWidget {
  const PagesListScreen({super.key});

  @override
  ConsumerState<PagesListScreen> createState() => _PagesListScreenState();
}

class _PagesListScreenState extends ConsumerState<PagesListScreen> {
  List<dynamic> _pages = [];
  bool _isLoading = true;

  @override
  void initState() {
    super.initState();
    _fetchPages();
  }

  Future<void> _fetchPages() async {
    try {
      final apiClient = ref.read(apiClientProvider);
      final response = await apiClient.getCmsPages();
      if (response.data['status'] == true && response.data['data'] is List) {
        setState(() {
          _pages = (response.data['data'] as List).where((p) => p['published'] == true).toList();
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
            Text('PAGES',
                style: GoogleFonts.montserrat(color: Colors.white, fontWeight: FontWeight.bold, fontSize: 20, letterSpacing: 1)),
            Text('BROWSE ALL PUBLISHED PAGES',
                style: GoogleFonts.montserrat(color: Colors.white54, fontWeight: FontWeight.w900, fontSize: 9, letterSpacing: 4)),
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
      ),
      body: Container(
        decoration: const BoxDecoration(
          gradient: RadialGradient(
            center: Alignment.topCenter,
            radius: 2.5,
            colors: [Color(0xFF0F1115), Colors.black],
          ),
        ),
        child: SafeArea(
          child: _isLoading
              ? const Center(child: CircularProgressIndicator(color: Colors.white24))
              : _pages.isEmpty
                  ? Center(
                      child: Text('No published pages available.',
                          style: GoogleFonts.inter(color: Colors.white54, fontSize: 14)),
                    )
                  : ListView.builder(
                      padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 24),
                      itemCount: _pages.length,
                      itemBuilder: (context, index) => _buildPageCard(_pages[index], index),
                    ),
        ),
      ),
    );
  }

  Widget _buildPageCard(Map<String, dynamic> page, int index) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 16),
      child: Material(
        color: Colors.transparent,
        child: InkWell(
          onTap: () {
            Navigator.push(
              context,
              MaterialPageRoute(
                builder: (context) => PageDetailScreen(slug: page['slug'] ?? ''),
              ),
            );
          },
          borderRadius: BorderRadius.circular(24),
          child: ClipRRect(
            borderRadius: BorderRadius.circular(24),
            child: BackdropFilter(
              filter: ImageFilter.blur(sigmaX: 10, sigmaY: 10),
              child: Container(
                padding: const EdgeInsets.all(20),
                decoration: BoxDecoration(
                  color: Colors.white.withOpacity(0.04),
                  borderRadius: BorderRadius.circular(24),
                  border: Border.all(color: Colors.white.withOpacity(0.05)),
                ),
                child: Row(
                  children: [
                    Container(
                      width: 44,
                      height: 44,
                      decoration: BoxDecoration(
                        color: Colors.white.withOpacity(0.06),
                        borderRadius: BorderRadius.circular(14),
                      ),
                      child: const Icon(LucideIcons.fileText, color: Colors.white70, size: 20),
                    ),
                    const SizedBox(width: 16),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            (page['title'] ?? 'Untitled').toString(),
                            style: GoogleFonts.montserrat(
                              color: Colors.white,
                              fontSize: 15,
                              fontWeight: FontWeight.w800,
                            ),
                          ),
                          const SizedBox(height: 4),
                          Row(
                            children: [
                              Icon(LucideIcons.globe, color: Colors.white.withOpacity(0.3), size: 12),
                              const SizedBox(width: 6),
                              Text(
                                '/${page['slug'] ?? ''}',
                                style: GoogleFonts.inter(color: Colors.white38, fontSize: 11, fontWeight: FontWeight.w500),
                              ),
                            ],
                          ),
                        ],
                      ),
                    ),
                    Icon(LucideIcons.arrowRight, color: Colors.white.withOpacity(0.3), size: 20),
                  ],
                ),
              ),
            ),
          ),
        ),
      ),
    ).animate().fadeIn(delay: (index * 80).ms).slideX(begin: 0.05);
  }
}
