import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:lucide_icons/lucide_icons.dart';
import 'package:flutter_animate/flutter_animate.dart';
import 'package:intl/intl.dart';
import 'package:m4_mobile/core/network/api_client.dart';
import 'package:m4_mobile/presentation/providers/auth_provider.dart';
import 'package:m4_mobile/presentation/screens/content/content_detail_screen.dart';
import 'package:m4_mobile/presentation/widgets/main_shell.dart';

class GuestContentHubScreen extends ConsumerStatefulWidget {
  final String title;
  final String subtitle;
  final IconData typeIcon;
  final String emptyMessage;
  final String contentType;

  const GuestContentHubScreen({
    super.key,
    required this.title,
    required this.subtitle,
    required this.typeIcon,
    required this.emptyMessage,
    required this.contentType,
  });

  @override
  ConsumerState<GuestContentHubScreen> createState() => _GuestContentHubScreenState();
}

class _GuestContentHubScreenState extends ConsumerState<GuestContentHubScreen> {
  List<dynamic> _items = [];
  bool _isLoading = true;

  @override
  void initState() {
    super.initState();
    _fetchContent();
  }

  @override
  void didUpdateWidget(GuestContentHubScreen oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (oldWidget.contentType != widget.contentType) {
      _fetchContent();
    }
  }

  Future<void> _fetchContent() async {
    print('Fetching content for type: ${widget.contentType}');
    setState(() {
      _isLoading = true;
      _items = []; // Clear old items to avoid stale UI
    });
    try {
      final apiClient = ref.read(apiClientProvider);
      final authState = ref.read(authProvider);
      
      String userRole = 'guest';
      if (authState.status == AuthStatus.authenticated) {
        final rawRole = authState.user?['role']?.toString().toLowerCase() ?? 'user';
        userRole = rawRole == 'customer' ? 'user' : rawRole;
      }

      final res = await apiClient.getContent(
        widget.contentType,
        role: userRole,
      );

      if (res.statusCode == 200 && res.data['status'] == true && res.data['data'] is List) {
        setState(() {
          _items = res.data['data'];
          _isLoading = false;
        });
      } else {
        setState(() => _isLoading = false);
      }
    } catch (e) {
      setState(() => _isLoading = false);
    }
  }

  void _openDetail(dynamic item) {
    Navigator.push(
      context,
      MaterialPageRoute(
        builder: (context) => ContentDetailScreen(content: item),
      ),
    );
  }

  IconData _getIcon() {
    switch (widget.contentType.toLowerCase()) {
      case 'media': return LucideIcons.playCircle;
      case 'highlight':
      case 'highlights': return LucideIcons.zap;
      case 'blog': return LucideIcons.fileText;
      case 'event':
      case 'events': return LucideIcons.calendar;
      default: return widget.typeIcon;
    }
  }

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final scheme = Theme.of(context).colorScheme;

    return Scaffold(
      backgroundColor: scheme.surface,
      body: Container(
        decoration: BoxDecoration(
          gradient: RadialGradient(
            center: Alignment.topLeft,
            radius: 1.5,
            colors: isDark 
              ? [const Color(0xFF1A1A1A), const Color(0xFF0A0A0A)]
              : [scheme.surface, scheme.surfaceContainerLowest],
          ),
        ),
        child: SafeArea(
          child: Column(
            children: [
              // 🏷️ STANDARDIZED HEADER (Web Parity)
              Padding(
                padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 15),
                child: Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    _buildCircleButton(
                      icon: LucideIcons.arrowLeft,
                      onTap: () {
                        if (Navigator.canPop(context)) {
                          Navigator.pop(context);
                        } else {
                          ref.read(navigationProvider.notifier).state = 0;
                        }
                      },
                    ),
                    Column(
                      children: [
                        Text(
                          'M4 FAMILY',
                          style: GoogleFonts.montserrat(
                            fontSize: 14,
                            fontWeight: FontWeight.w900,
                            letterSpacing: 2.5,
                            color: scheme.onSurface,
                          ),
                        ),
                        Text(
                          'DEVELOPMENTS',
                          style: GoogleFonts.montserrat(
                            fontSize: 8,
                            fontWeight: FontWeight.w700,
                            letterSpacing: 3.5,
                            color: scheme.onSurface.withOpacity(0.4),
                          ),
                        ),
                      ],
                    ),
                    _buildMenuButton(),
                  ],
                ),
              ),

              // 🏷️ INTRO SECTION
              Padding(
                padding: const EdgeInsets.fromLTRB(20, 20, 20, 10),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(
                      children: [
                        Container(
                          padding: const EdgeInsets.all(10),
                          decoration: BoxDecoration(
                            color: const Color(0xFF60A5FA).withOpacity(0.1),
                            shape: BoxShape.circle,
                          ),
                          child: Icon(_getIcon(), color: const Color(0xFF60A5FA), size: 18),
                        ),
                        const SizedBox(width: 15),
                        Text(
                          'CONTENT HUB',
                          style: GoogleFonts.montserrat(
                            fontSize: 10,
                            fontWeight: FontWeight.w900,
                            letterSpacing: 3,
                            color: const Color(0xFF60A5FA),
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 20),
                    Text(
                      _getTitle(),
                      style: GoogleFonts.montserrat(
                        fontSize: 32,
                        fontWeight: FontWeight.w900,
                        color: scheme.onSurface,
                        letterSpacing: -1,
                        height: 0.9,
                      ),
                    ),
                    const SizedBox(height: 15),
                    Text(
                      _getSubtitle(),
                      style: GoogleFonts.inter(
                        fontSize: 14,
                        color: scheme.onSurface.withOpacity(0.5),
                        fontWeight: FontWeight.w500,
                        height: 1.5,
                      ),
                    ),
                  ],
                ),
              ),

              Expanded(
                child: _isLoading
                    ? const Center(child: CircularProgressIndicator(color: Color(0xFF60A5FA)))
                    : _items.isEmpty
                        ? _buildEmptyState()
                        : ListView.builder(
                            padding: const EdgeInsets.fromLTRB(20, 20, 20, 100),
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

  Widget _buildCircleButton({required IconData icon, required VoidCallback onTap}) {
    final scheme = Theme.of(context).colorScheme;
    return GestureDetector(
      onTap: onTap,
      child: Container(
        width: 48,
        height: 48,
        decoration: BoxDecoration(
          color: scheme.surface,
          borderRadius: BorderRadius.circular(16),
          border: Border.all(color: scheme.onSurface.withOpacity(0.05)),
          boxShadow: [
            BoxShadow(
              color: Colors.black.withOpacity(0.05),
              blurRadius: 20,
              offset: const Offset(0, 10),
            ),
          ],
        ),
        child: Icon(icon, size: 20, color: scheme.onSurface),
      ),
    );
  }

  Widget _buildMenuButton() {
    final scheme = Theme.of(context).colorScheme;
    return GestureDetector(
      onTap: () {
        Scaffold.of(context).openDrawer();
      },
      child: Container(
        width: 56,
        height: 48,
        decoration: BoxDecoration(
          color: scheme.onSurface,
          borderRadius: BorderRadius.circular(18),
          boxShadow: [
            BoxShadow(
              color: scheme.onSurface.withOpacity(0.2),
              blurRadius: 20,
              offset: const Offset(0, 10),
            ),
          ],
        ),
        child: Icon(LucideIcons.moreHorizontal, size: 24, color: scheme.surface),
      ),
    );
  }

  Widget _buildEmptyState() {
    final scheme = Theme.of(context).colorScheme;
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Container(
            padding: const EdgeInsets.all(30),
            decoration: BoxDecoration(
              color: const Color(0xFF60A5FA).withOpacity(0.1),
              borderRadius: BorderRadius.circular(30),
            ),
            child: Icon(_getIcon(), size: 40, color: const Color(0xFF60A5FA)),
          ),
          const SizedBox(height: 25),
          Text(
            'NO ${widget.contentType.toUpperCase()} POSTS FOUND',
            style: GoogleFonts.montserrat(
              fontSize: 16,
              fontWeight: FontWeight.w900,
              color: scheme.onSurface,
            ),
          ),
          const SizedBox(height: 10),
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 40),
            child: Text(
              "We're working on something amazing. Check back soon for fresh updates from our content hub.",
              textAlign: TextAlign.center,
              style: GoogleFonts.inter(
                fontSize: 13,
                color: scheme.onSurface.withOpacity(0.5),
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
    final String? rawImage = (item['image'] != null && item['image'].toString().isNotEmpty) 
        ? item['image'] 
        : (item['thumbnail'] != null && item['thumbnail'].toString().isNotEmpty)
            ? item['thumbnail']
            : item['coverImage'];
    final imageUrl = apiClient.resolveUrl(rawImage);
    final date = DateTime.tryParse(item['createdAt'] ?? '') ?? DateTime.now();
    final formattedDate = DateFormat('MM/dd/yyyy').format(date);
    final scheme = Theme.of(context).colorScheme;

    return GestureDetector(
      onTap: () => _openDetail(item),
      child: Container(
        margin: const EdgeInsets.only(bottom: 16),
        decoration: BoxDecoration(
          color: scheme.surface,
          borderRadius: BorderRadius.circular(16),
          border: Border.all(color: scheme.onSurface.withOpacity(0.05)),
          boxShadow: [
            BoxShadow(
              color: Colors.black.withOpacity(0.05),
              blurRadius: 20,
              offset: const Offset(0, 10),
            ),
          ],
        ),
        child: Row(
          children: [
            // 🖼️ COMPACT IMAGE
            Container(
              width: 100,
              height: 100,
              margin: const EdgeInsets.all(10),
              decoration: BoxDecoration(
                color: scheme.onSurface.withOpacity(0.05),
                borderRadius: BorderRadius.circular(12),
                image: imageUrl.isNotEmpty
                    ? DecorationImage(
                        image: NetworkImage(imageUrl),
                        fit: BoxFit.cover,
                      )
                    : null,
              ),
              child: imageUrl.isEmpty
                  ? Center(
                      child: Icon(
                        _getIcon(),
                        color: scheme.onSurface.withOpacity(0.1),
                        size: 30,
                      ),
                    )
                  : null,
            ),

            // 📄 CONTENT INFO
            Expanded(
              child: Padding(
                padding: const EdgeInsets.fromLTRB(0, 12, 16, 12),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        Container(
                          padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                          decoration: BoxDecoration(
                            color: const Color(0xFF60A5FA).withOpacity(0.1),
                            borderRadius: BorderRadius.circular(4),
                          ),
                          child: Text(
                            (item['type'] ?? widget.contentType).toString().toUpperCase(),
                            style: GoogleFonts.montserrat(
                              fontSize: 7,
                              fontWeight: FontWeight.w900,
                              color: const Color(0xFF60A5FA),
                              letterSpacing: 1,
                            ),
                          ),
                        ),
                        Text(
                          formattedDate,
                          style: GoogleFonts.inter(
                            fontSize: 9,
                            fontWeight: FontWeight.bold,
                            color: scheme.onSurface.withOpacity(0.2),
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 8),
                    Text(
                      item['title'].toString().toUpperCase(),
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                      style: GoogleFonts.montserrat(
                        fontSize: 14,
                        fontWeight: FontWeight.w900,
                        color: scheme.onSurface,
                        letterSpacing: -0.5,
                      ),
                    ),
                    const SizedBox(height: 4),
                    Text(
                      item['description'] ?? '',
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                      style: GoogleFonts.inter(
                        fontSize: 10,
                        color: scheme.onSurface.withOpacity(0.5),
                        fontWeight: FontWeight.w500,
                      ),
                    ),
                    const SizedBox(height: 12),
                    Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        Text(
                          'READ ARTICLE',
                          style: GoogleFonts.montserrat(
                            fontSize: 10,
                            fontWeight: FontWeight.w900,
                            color: const Color(0xFF60A5FA),
                            letterSpacing: 1,
                          ),
                        ),
                        const Icon(LucideIcons.arrowRight, size: 14, color: Color(0xFF60A5FA)),
                      ],
                    ),
                  ],
                ),
              ),
            ),
          ],
        ),
      ),
    ).animate().fadeIn(delay: (index * 100).ms).slideX(begin: 0.1);
  }

  String _getTitle() {
    switch (widget.contentType.toLowerCase()) {
      case 'media': return 'MEDIA GALLERY';
      case 'highlight':
      case 'highlights': return 'PROJECT HIGHLIGHTS';
      case 'event':
      case 'events': return 'M4 EVENTS';
      case 'blog': return 'M4 BLOG';
      default: return widget.title.replaceAll('\n', ' ').toUpperCase();
    }
  }

  String _getSubtitle() {
    final type = widget.contentType.toLowerCase();
    return 'Stay updated with our latest ${type == 'media' ? 'multimedia releases' : (type == 'highlight' || type == 'highlights') ? 'achievements and milestones' : (type == 'event' || type == 'events') ? 'upcoming events' : 'insights and news'}.';
  }
}
