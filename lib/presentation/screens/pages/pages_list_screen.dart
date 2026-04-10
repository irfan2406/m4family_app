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
          _pages = (response.data['data'] as List).where((p) => 
            p['published'] == true || p['status'] == 'published'
          ).toList();
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
      backgroundColor: Theme.of(context).scaffoldBackgroundColor,
      appBar: null,
      body: Container(
        decoration: const BoxDecoration(
          color: Colors.black,
        ),
        child: SafeArea(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // ─── Custom Navigation Header ───────────────────────
              Padding(
                padding: const EdgeInsets.fromLTRB(24, 16, 24, 0),
                child: InkWell(
                  onTap: () => Navigator.pop(context),
                  child: Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      const Icon(LucideIcons.chevronLeft, color: Colors.white, size: 16),
                      const SizedBox(width: 8),
                      Text(
                        'Back to Home',
                        style: GoogleFonts.inter(
                          color: Colors.white,
                          fontSize: 13,
                          fontWeight: FontWeight.w500,
                        ),
                      ),
                    ],
                  ),
                ),
              ),

              const SizedBox(height: 48),

              // ─── Title & Subtitle ──────────────────────────────
              Padding(
                padding: const EdgeInsets.symmetric(horizontal: 24),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      'Pages',
                      style: GoogleFonts.montserrat(
                        color: Colors.white,
                        fontSize: 32,
                        fontWeight: FontWeight.w900,
                        letterSpacing: -1,
                      ),
                    ),
                    const SizedBox(height: 8),
                    Text(
                      'Browse all published pages.',
                      style: GoogleFonts.inter(
                        color: Colors.white60,
                        fontSize: 14,
                        fontWeight: FontWeight.w400,
                      ),
                    ),
                  ],
                ),
              ),

              const SizedBox(height: 48),

              // ─── List Content ──────────────────────────────────
              Expanded(
                child: _isLoading
                    ? const Center(child: CircularProgressIndicator(color: Colors.white24))
                    : _pages.isEmpty
                        ? Center(
                            child: Text(
                              'No published pages available.',
                              style: GoogleFonts.inter(
                                color: Colors.white38,
                                fontSize: 13,
                              ),
                            ),
                          )
                        : ListView.builder(
                            padding: const EdgeInsets.fromLTRB(24, 0, 24, 40),
                            itemCount: _pages.length,
                            itemBuilder: (context, index) => _buildPageCard(_pages[index], index),
                          ),
              ),
            ],
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
