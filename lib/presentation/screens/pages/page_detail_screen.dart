import 'dart:ui';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:lucide_icons/lucide_icons.dart';
import 'package:flutter_animate/flutter_animate.dart';
import 'package:intl/intl.dart';
import 'package:m4_mobile/core/network/api_client.dart';
import 'package:m4_mobile/presentation/providers/auth_provider.dart';

class PageDetailScreen extends ConsumerStatefulWidget {
  final String slug;
  const PageDetailScreen({super.key, required this.slug});

  @override
  ConsumerState<PageDetailScreen> createState() => _PageDetailScreenState();
}

class _PageDetailScreenState extends ConsumerState<PageDetailScreen> {
  Map<String, dynamic>? _page;
  bool _isLoading = true;
  bool _isError = false;

  @override
  void initState() {
    super.initState();
    _fetchPage();
  }

  Future<void> _fetchPage() async {
    try {
      final apiClient = ref.read(apiClientProvider);
      final response = await apiClient.getCmsPage(widget.slug);
      if (response.data['status'] == true && response.data['data'] != null) {
        setState(() {
          _page = response.data['data'];
          _isLoading = false;
        });
      } else {
        setState(() { _isLoading = false; _isError = true; });
      }
    } catch (_) {
      setState(() { _isLoading = false; _isError = true; });
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Theme.of(context).scaffoldBackgroundColor,
      extendBodyBehindAppBar: true,
      appBar: AppBar(
        title: Text(
          _page?['title']?.toString().toUpperCase() ?? 'PAGE',
          style: GoogleFonts.montserrat(color: Colors.white, fontWeight: FontWeight.bold, fontSize: 16, letterSpacing: 1),
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
              : _isError
                  ? _buildErrorState()
                  : SingleChildScrollView(
                      padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 24),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.stretch,
                        children: [
                          _buildHero(),
                          const SizedBox(height: 32),
                          _buildContent(),
                          _buildSections(),
                          const SizedBox(height: 48),
                        ],
                      ),
                    ),
        ),
      ),
    );
  }

  Widget _buildErrorState() {
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(32),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Container(
              width: 72,
              height: 72,
              decoration: BoxDecoration(
                color: Colors.red.withOpacity(0.1),
                shape: BoxShape.circle,
              ),
              child: const Icon(LucideIcons.fileX, color: Colors.redAccent, size: 32),
            ),
            const SizedBox(height: 24),
            Text('Page Not Found',
                style: GoogleFonts.montserrat(color: Colors.white, fontSize: 24, fontWeight: FontWeight.bold)),
            const SizedBox(height: 12),
            Text(
              'The page /${widget.slug} does not exist or has not been published yet.',
              textAlign: TextAlign.center,
              style: GoogleFonts.inter(color: Colors.white54, fontSize: 14),
            ),
            const SizedBox(height: 24),
            TextButton.icon(
              onPressed: () => Navigator.pop(context),
              icon: const Icon(LucideIcons.arrowLeft, size: 16),
              label: const Text('Back to Pages'),
              style: TextButton.styleFrom(foregroundColor: Colors.white),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildHero() {
    String? updatedAt;
    if (_page?['updatedAt'] != null) {
      try {
        final date = DateTime.parse(_page!['updatedAt']);
        updatedAt = DateFormat('MMM dd, yyyy').format(date);
      } catch (_) {}
    }

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          (_page?['title'] ?? '').toString(),
          style: GoogleFonts.montserrat(
            color: Colors.white,
            fontSize: 32,
            fontWeight: FontWeight.w900,
            letterSpacing: -1,
          ),
        ),
        if (_page?['subtitle'] != null && _page!['subtitle'].toString().isNotEmpty) ...[
          const SizedBox(height: 12),
          Text(
            _page!['subtitle'].toString(),
            style: GoogleFonts.inter(color: Colors.white60, fontSize: 16, fontWeight: FontWeight.w500),
          ),
        ],
        const SizedBox(height: 20),
        Row(
          children: [
            Icon(LucideIcons.globe, color: Colors.white.withOpacity(0.3), size: 14),
            const SizedBox(width: 8),
            Text('Published', style: GoogleFonts.inter(color: Colors.white38, fontSize: 11, fontWeight: FontWeight.w500)),
            if (updatedAt != null) ...[
              const SizedBox(width: 20),
              Icon(LucideIcons.calendar, color: Colors.white.withOpacity(0.3), size: 14),
              const SizedBox(width: 8),
              Text('Last updated: $updatedAt',
                  style: GoogleFonts.inter(color: Colors.white38, fontSize: 11, fontWeight: FontWeight.w500)),
            ],
          ],
        ),
      ],
    ).animate().fadeIn().slideY(begin: 0.1);
  }

  Widget _buildContent() {
    final content = _page?['content']?.toString() ?? '';
    if (content.isEmpty) return const SizedBox.shrink();

    // Strip basic HTML tags for plain text rendering
    final plainText = content
        .replaceAll(RegExp(r'<br\s*/?>'), '\n')
        .replaceAll(RegExp(r'<p>'), '')
        .replaceAll(RegExp(r'</p>'), '\n\n')
        .replaceAll(RegExp(r'<[^>]*>'), '')
        .trim();

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: plainText.split('\n\n').where((p) => p.trim().isNotEmpty).map((paragraph) {
        return Padding(
          padding: const EdgeInsets.only(bottom: 16),
          child: Text(
            paragraph.trim(),
            style: GoogleFonts.inter(color: Colors.white.withOpacity(0.75), fontSize: 15, fontWeight: FontWeight.w400, height: 1.7),
          ),
        );
      }).toList(),
    ).animate().fadeIn(delay: 200.ms);
  }

  Widget _buildSections() {
    final sections = _page?['sections'];
    if (sections == null || sections is! List || sections.isEmpty) return const SizedBox.shrink();

    return Column(
      children: [
        const SizedBox(height: 24),
        ...sections.asMap().entries.map((entry) {
          final idx = entry.key;
          final section = entry.value;

          return Padding(
            padding: const EdgeInsets.only(bottom: 16),
            child: ClipRRect(
              borderRadius: BorderRadius.circular(24),
              child: BackdropFilter(
                filter: ImageFilter.blur(sigmaX: 10, sigmaY: 10),
                child: Container(
                  padding: const EdgeInsets.all(24),
                  decoration: BoxDecoration(
                    color: Colors.white.withOpacity(0.04),
                    borderRadius: BorderRadius.circular(24),
                    border: Border.all(color: Colors.white.withOpacity(0.05)),
                  ),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Row(
                        children: [
                          if (section['icon'] != null && section['icon'].toString().isNotEmpty)
                            Padding(
                              padding: const EdgeInsets.only(right: 10),
                              child: Text(section['icon'].toString(), style: const TextStyle(fontSize: 22)),
                            ),
                          Expanded(
                            child: Text(
                              (section['title'] ?? '').toString(),
                              style: GoogleFonts.montserrat(
                                color: Colors.white,
                                fontSize: 18,
                                fontWeight: FontWeight.w800,
                              ),
                            ),
                          ),
                        ],
                      ),
                      const SizedBox(height: 16),
                      Text(
                        (section['content'] ?? '')
                            .toString()
                            .replaceAll(RegExp(r'<[^>]*>'), '')
                            .trim(),
                        style: GoogleFonts.inter(
                          color: Colors.white.withOpacity(0.65),
                          fontSize: 14,
                          fontWeight: FontWeight.w400,
                          height: 1.6,
                        ),
                      ),
                    ],
                  ),
                ),
              ),
            ),
          ).animate().fadeIn(delay: (300 + idx * 100).ms).slideY(begin: 0.1);
        }),
      ],
    );
  }
}
