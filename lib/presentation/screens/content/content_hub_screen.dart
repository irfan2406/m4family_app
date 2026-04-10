import 'dart:ui';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:lucide_icons/lucide_icons.dart';
import 'package:flutter_animate/flutter_animate.dart';
import 'package:intl/intl.dart';
import 'package:m4_mobile/core/network/api_client.dart';
import 'package:m4_mobile/presentation/providers/auth_provider.dart';

class ContentHubScreen extends ConsumerStatefulWidget {
  final String type; // 'media', 'highlights', 'events', 'blog'
  const ContentHubScreen({super.key, required this.type});

  @override
  ConsumerState<ContentHubScreen> createState() => _ContentHubScreenState();
}

class _ContentHubScreenState extends ConsumerState<ContentHubScreen> {
  List<dynamic> _items = [];
  bool _isLoading = true;

  @override
  void initState() {
    super.initState();
    _fetchContent();
  }

  Future<void> _fetchContent() async {
    try {
      final apiClient = ref.read(apiClientProvider);
      // Determine type for API
      String apiType = widget.type;
      if (widget.type == 'events') apiType = 'event';
      if (widget.type == 'highlights') apiType = 'highlight';

      final response = await apiClient.getContent(apiType);
      if (response.data['status'] == true && response.data['data'] is List) {
        setState(() {
          _items = response.data['data'] as List;
          _isLoading = false;
        });
      } else {
        setState(() => _isLoading = false);
      }
    } catch (_) {
      setState(() => _isLoading = false);
    }
  }

  String _getTitle() {
    switch (widget.type) {
      case 'media': return 'MEDIA GALLERY';
      case 'highlights': return 'PROJECT HIGHLIGHTS';
      case 'events': return 'M4 EVENTS';
      case 'blog': return 'M4 BLOG';
      default: return 'CONTENT HUB';
    }
  }

  String _getSubtitle() {
    switch (widget.type) {
      case 'media': return 'MULTIMEDIA RELEASES';
      case 'highlights': return 'ACHIEVEMENTS AND MILESTONES';
      case 'events': return 'UPCOMING EVENTS';
      case 'blog': return 'INSIGHTS AND NEWS';
      default: return 'LATEST UPDATES';
    }
  }

  IconData _getIcon() {
    switch (widget.type) {
      case 'media': return LucideIcons.playCircle;
      case 'highlights': return LucideIcons.zap;
      case 'blog': return LucideIcons.fileText;
      case 'events': return LucideIcons.calendar;
      default: return LucideIcons.layout;
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.black,
      extendBodyBehindAppBar: true,
      appBar: PreferredSize(
        preferredSize: const Size.fromHeight(100),
        child: ClipRRect(
          child: BackdropFilter(
            filter: ImageFilter.blur(sigmaX: 20, sigmaY: 20),
            child: AppBar(
              backgroundColor: Colors.black.withOpacity(0.5),
              elevation: 0,
              leading: Padding(
                padding: const EdgeInsets.only(left: 20, top: 20),
                child: IconButton(
                  icon: const Icon(LucideIcons.arrowLeft, color: Colors.white, size: 24),
                  onPressed: () => Navigator.pop(context),
                ),
              ),
              centerTitle: true,
              title: Padding(
                padding: const EdgeInsets.only(top: 25),
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Text(
                      'M4 FAMILY',
                      style: GoogleFonts.montserrat(
                        color: Colors.white,
                        fontSize: 14,
                        fontWeight: FontWeight.w900,
                        letterSpacing: 3,
                      ),
                    ),
                    Text(
                      'DEVELOPMENTS',
                      style: GoogleFonts.montserrat(
                        color: Colors.white.withOpacity(0.4),
                        fontSize: 8,
                        fontWeight: FontWeight.bold,
                        letterSpacing: 5,
                      ),
                    ),
                  ],
                ),
              ),
            ),
          ),
        ),
      ),
      body: Container(
        decoration: const BoxDecoration(
          gradient: RadialGradient(
            center: Alignment.topCenter,
            radius: 1.5,
            colors: [Color(0xFF1A1D23), Colors.black],
          ),
        ),
        child: SafeArea(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // Header Intro
              Padding(
                padding: const EdgeInsets.fromLTRB(25, 30, 25, 40),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(
                      children: [
                        Container(
                          padding: const EdgeInsets.all(12),
                          decoration: BoxDecoration(
                            color: const Color(0xFF60A5FA).withOpacity(0.1),
                            borderRadius: BorderRadius.circular(16),
                            border: Border.all(color: const Color(0xFF60A5FA).withOpacity(0.2)),
                          ),
                          child: Icon(_getIcon(), color: const Color(0xFF60A5FA), size: 18),
                        ),
                        const SizedBox(width: 15),
                        Text(
                          'CONTENT HUB',
                          style: GoogleFonts.montserrat(
                            color: const Color(0xFF60A5FA),
                            fontSize: 10,
                            fontWeight: FontWeight.w900,
                            letterSpacing: 2,
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 25),
                    Text(
                      _getTitle(),
                      style: GoogleFonts.montserrat(
                        color: Colors.white,
                        fontSize: 32,
                        fontWeight: FontWeight.w900,
                        letterSpacing: -1,
                        height: 1,
                      ),
                    ),
                    const SizedBox(height: 15),
                    Text(
                      _getSubtitle(),
                      style: GoogleFonts.inter(
                        color: Colors.white.withOpacity(0.5),
                        fontSize: 14,
                        fontWeight: FontWeight.w500,
                        height: 1.5,
                      ),
                    ),
                  ],
                ),
              ),

              // Content List
              Expanded(
                child: _isLoading
                    ? const Center(child: CircularProgressIndicator(color: Color(0xFF60A5FA)))
                    : _items.isEmpty
                        ? _buildEmptyState()
                        : ListView.builder(
                            padding: const EdgeInsets.symmetric(horizontal: 25),
                            itemCount: _items.length,
                            itemBuilder: (context, index) => _buildContentCard(_items[index], index),
                          ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildEmptyState() {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Container(
            padding: const EdgeInsets.all(30),
            decoration: BoxDecoration(
              color: Colors.white.withOpacity(0.05),
              shape: BoxShape.circle,
            ),
            child: Icon(_getIcon(), color: Colors.white.withOpacity(0.2), size: 50),
          ),
          const SizedBox(height: 25),
          Text(
            'NO ${_getTitle()} POSTS FOUND',
            style: GoogleFonts.montserrat(
              color: Colors.white,
              fontSize: 14,
              fontWeight: FontWeight.w900,
            ),
          ),
          const SizedBox(height: 10),
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 50),
            child: Text(
              "WE'RE WORKING ON SOMETHING AMAZING. CHECK BACK SOON FOR FRESH UPDATES FROM OUR CONTENT HUB.",
              textAlign: TextAlign.center,
              style: GoogleFonts.inter(
                color: Colors.white.withOpacity(0.4),
                fontSize: 11,
                fontWeight: FontWeight.w500,
                height: 1.5,
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildContentCard(dynamic item, int index) {
    final apiClient = ref.read(apiClientProvider);
    final imageUrl = apiClient.resolveUrl(item['image'] ?? item['thumbnail'] ?? item['coverImage']);
    final date = DateTime.tryParse(item['createdAt'] ?? '') ?? DateTime.now();
    final formattedDate = DateFormat('MMM dd, yyyy').format(date);

    return Container(
      margin: const EdgeInsets.only(bottom: 30),
      decoration: BoxDecoration(
        color: const Color(0xFF18181B),
        borderRadius: BorderRadius.circular(40),
        border: Border.all(color: Colors.white.withOpacity(0.05)),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.3),
            blurRadius: 30,
            offset: const Offset(0, 15),
          ),
        ],
      ),
      child: ClipRRect(
        borderRadius: BorderRadius.circular(40),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Image Stack
            Stack(
              children: [
                AspectRatio(
                  aspectRatio: 16 / 10,
                  child: Image.network(imageUrl, fit: BoxFit.cover),
                ),
                Positioned.fill(
                  child: Container(
                    decoration: BoxDecoration(
                      gradient: LinearGradient(
                        begin: Alignment.topCenter,
                        end: Alignment.bottomCenter,
                        colors: [Colors.transparent, Colors.black.withOpacity(0.7)],
                      ),
                    ),
                  ),
                ),
                Positioned(
                  top: 25,
                  right: 25,
                  child: Container(
                    padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
                    decoration: BoxDecoration(
                      color: Colors.white.withOpacity(0.1),
                      borderRadius: BorderRadius.circular(20),
                      border: Border.all(color: Colors.white.withOpacity(0.2)),
                    ),
                    child: BackdropFilter(
                      filter: ImageFilter.blur(sigmaX: 10, sigmaY: 10),
                      child: Text(
                        (item['type'] ?? widget.type).toString().toUpperCase(),
                        style: GoogleFonts.montserrat(
                          color: Colors.white,
                          fontSize: 9,
                          fontWeight: FontWeight.w900,
                          letterSpacing: 2,
                        ),
                      ),
                    ),
                  ),
                ),
              ],
            ),

            // Content Info
            Padding(
              padding: const EdgeInsets.all(30),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    children: [
                      Icon(LucideIcons.calendar, size: 12, color: Colors.white.withOpacity(0.3)),
                      const SizedBox(width: 8),
                      Text(
                        formattedDate.toUpperCase(),
                        style: GoogleFonts.montserrat(
                          color: Colors.white.withOpacity(0.3),
                          fontSize: 9,
                          fontWeight: FontWeight.w900,
                          letterSpacing: 1,
                        ),
                      ),
                      const SizedBox(width: 15),
                      Container(width: 4, height: 4, decoration: BoxDecoration(color: const Color(0xFF60A5FA).withOpacity(0.4), shape: BoxShape.circle)),
                      const SizedBox(width: 15),
                      Icon(LucideIcons.user, size: 12, color: Colors.white.withOpacity(0.3)),
                      const SizedBox(width: 8),
                      Text(
                        'BY M4 TEAM',
                        style: GoogleFonts.montserrat(
                          color: Colors.white.withOpacity(0.3),
                          fontSize: 9,
                          fontWeight: FontWeight.w900,
                          letterSpacing: 1,
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 20),
                  Text(
                    (item['title'] ?? 'UNTITLED').toString().toUpperCase(),
                    maxLines: 2,
                    overflow: TextOverflow.ellipsis,
                    style: GoogleFonts.montserrat(
                      color: Colors.white,
                      fontSize: 18,
                      fontWeight: FontWeight.w900,
                      height: 1.1,
                    ),
                  ),
                  const SizedBox(height: 12),
                  Text(
                    (item['description'] ?? 'NO DESCRIPTION AVAILABLE').toString(),
                    maxLines: 2,
                    overflow: TextOverflow.ellipsis,
                    style: GoogleFonts.inter(
                      color: Colors.white.withOpacity(0.5),
                      fontSize: 13,
                      fontWeight: FontWeight.w500,
                      height: 1.5,
                    ),
                  ),
                  const SizedBox(height: 30),
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      TextButton.icon(
                        onPressed: () {},
                        style: TextButton.styleFrom(padding: EdgeInsets.zero),
                        icon: Text(
                          'READ MORE',
                          style: GoogleFonts.montserrat(
                            color: const Color(0xFF60A5FA),
                            fontSize: 10,
                            fontWeight: FontWeight.w900,
                            letterSpacing: 2,
                          ),
                        ),
                        label: const Icon(LucideIcons.arrowRight, color: Color(0xFF60A5FA), size: 16),
                      ),
                      Container(
                        width: 44,
                        height: 44,
                        decoration: BoxDecoration(
                          color: Colors.white.withOpacity(0.05),
                          borderRadius: BorderRadius.circular(14),
                        ),
                        child: const Icon(LucideIcons.share2, color: Colors.white54, size: 18),
                      ),
                    ],
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    ).animate().fadeIn(delay: (index * 100).ms).slideY(begin: 0.1, curve: Curves.easeOutCubic, duration: 600.ms);
  }
}
