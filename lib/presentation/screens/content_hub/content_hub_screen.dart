import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:lucide_icons/lucide_icons.dart';
import 'package:flutter_animate/flutter_animate.dart';
import 'package:cached_network_image/cached_network_image.dart';
import 'package:m4_mobile/presentation/providers/content_provider.dart';
import 'package:m4_mobile/presentation/providers/auth_provider.dart';
import 'package:m4_mobile/presentation/widgets/conditional_drawer.dart';
import 'package:url_launcher/url_launcher.dart';
import 'package:intl/intl.dart';

class GuestContentHubScreen extends ConsumerStatefulWidget {
  final String title;
  final String subtitle;
  final IconData typeIcon;
  final String emptyMessage;
  final String contentType; // "media", "blog", "highlight", "event"

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
  @override
  void initState() {
    super.initState();
    Future.microtask(() =>
        ref.read(contentProvider(widget.contentType).notifier).fetchContent(widget.contentType));
  }

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final state = ref.watch(contentProvider(widget.contentType));

    return Scaffold(
      backgroundColor: isDark ? Colors.black : Colors.white,
      drawer: const ConditionalDrawer(),
      body: CustomScrollView(
        slivers: [
          SliverAppBar(
            floating: true,
            backgroundColor: (isDark ? Colors.black : Colors.white).withOpacity(0.9),
            surfaceTintColor: Colors.transparent,
            elevation: 0,
            leadingWidth: 80,
            leading: Padding(
              padding: const EdgeInsets.only(left: 12),
              child: Center(
                child: IconButton(
                  onPressed: () => Navigator.pop(context),
                  icon: Icon(LucideIcons.chevronLeft, color: isDark ? Colors.white : Colors.black, size: 28),
                  style: IconButton.styleFrom(
                    backgroundColor: (isDark ? Colors.white : Colors.black).withOpacity(0.04),
                    padding: EdgeInsets.zero,
                  ),
                ),
              ),
            ),
            title: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              mainAxisSize: MainAxisSize.min,
              children: [
                Text(
                  'M4 FAMILY',
                  style: GoogleFonts.montserrat(
                    fontSize: 16,
                    fontWeight: FontWeight.w400,
                    letterSpacing: -0.5,
                    color: isDark ? Colors.white : Colors.black,
                  ),
                ),
                Text(
                  'DEVELOPMENTS',
                  style: GoogleFonts.montserrat(
                    fontSize: 8,
                    fontWeight: FontWeight.w400,
                    letterSpacing: 3,
                    color: (isDark ? Colors.white : Colors.black).withOpacity(0.5),
                  ),
                ),
              ],
            ),
            actions: [
              Builder(
                builder: (context) => IconButton(
                  onPressed: () => Scaffold.of(context).openDrawer(),
                  icon: Icon(
                    LucideIcons.moreHorizontal,
                    color: isDark ? Colors.white : Colors.black,
                    size: 28,
                  ),
                ),
              ),
              const SizedBox(width: 12),
            ],
          ),

          // Header Section
          SliverToBoxAdapter(
            child: Padding(
              padding: const EdgeInsets.symmetric(horizontal: 24),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  const SizedBox(height: 40),
                  Container(
                    padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
                    decoration: BoxDecoration(
                      color: (isDark ? Colors.white : Colors.black).withOpacity(0.05),
                      borderRadius: BorderRadius.circular(12),
                      border: Border.all(color: (isDark ? Colors.white : Colors.black).withOpacity(0.1)),
                    ),
                    child: Row(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        Icon(widget.typeIcon, color: isDark ? Colors.white : Colors.black, size: 16),
                        const SizedBox(width: 12),
                        Text(
                          'CONTENT HUB',
                          style: GoogleFonts.montserrat(
                            color: isDark ? Colors.white : Colors.black,
                            fontSize: 10,
                            fontWeight: FontWeight.w400,
                            letterSpacing: 1,
                          ),
                        ),
                      ],
                    ),
                  ).animate().fadeIn().slideX(begin: -0.2),
                  const SizedBox(height: 24),
                  Text(
                    widget.title,
                    style: GoogleFonts.montserrat(
                      fontSize: 48,
                      fontWeight: FontWeight.w400,
                      letterSpacing: -2,
                      height: 0.9,
                      color: isDark ? Colors.white : Colors.black,
                    ),
                  ).animate().fadeIn().slideY(begin: 0.2),
                  const SizedBox(height: 16),
                  Text(
                    widget.subtitle,
                    style: GoogleFonts.montserrat(
                      fontSize: 14,
                      color: (isDark ? Colors.white : Colors.black).withOpacity(0.5),
                      fontWeight: FontWeight.w500,
                    ),
                  ).animate().fadeIn(delay: 200.ms),
                  const SizedBox(height: 40),
                ],
              ),
            ),
          ),

          // Content Body
          if (state.isLoading)
            const SliverFillRemaining(
              child: Center(child: CircularProgressIndicator(strokeWidth: 2)),
            )
          else if (state.error != null)
            SliverFillRemaining(
              child: Center(
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Icon(LucideIcons.wifiOff, color: (isDark ? Colors.white : Colors.black).withOpacity(0.2), size: 48),
                    const SizedBox(height: 16),
                    Text(
                      'Unable to load content',
                      style: GoogleFonts.montserrat(color: (isDark ? Colors.white : Colors.black).withOpacity(0.5), fontSize: 14),
                    ),
                    const SizedBox(height: 16),
                    TextButton(
                      onPressed: () => ref.read(contentProvider(widget.contentType).notifier).fetchContent(widget.contentType),
                      child: Text('RETRY', style: GoogleFonts.montserrat(fontWeight: FontWeight.w700, letterSpacing: 2)),
                    ),
                  ],
                ),
              ),
            )
          else if (state.items.isEmpty)
            SliverFillRemaining(
              child: _buildEmptyState(isDark),
            )
          else
            SliverPadding(
              padding: const EdgeInsets.symmetric(horizontal: 24),
              sliver: SliverList(
                delegate: SliverChildBuilderDelegate(
                  (context, index) {
                    if (index >= state.items.length) return null;
                    return _buildContentCard(state.items[index], isDark, index);
                  },
                  childCount: state.items.length,
                ),
              ),
            ),
          
          // Bottom spacing
          const SliverToBoxAdapter(child: SizedBox(height: 100)),
        ],
      ),
    );
  }

  Widget _buildEmptyState(bool isDark) {
    return Center(
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          Container(
            width: 80,
            height: 80,
            decoration: BoxDecoration(
              color: (isDark ? Colors.white : Colors.black).withOpacity(0.03),
              borderRadius: BorderRadius.circular(24),
              border: Border.all(color: (isDark ? Colors.white : Colors.black).withOpacity(0.1)),
            ),
            child: Icon(widget.typeIcon, color: (isDark ? Colors.white : Colors.black).withOpacity(0.2), size: 32),
          ),
          const SizedBox(height: 32),
          Text(
            widget.emptyMessage,
            textAlign: TextAlign.center,
            style: GoogleFonts.montserrat(
              color: isDark ? Colors.white : Colors.black,
              fontSize: 18,
              fontWeight: FontWeight.w800,
            ),
          ),
          const SizedBox(height: 12),
          Text(
            'We\'re working on something amazing.\nCheck back soon for fresh updates.',
            textAlign: TextAlign.center,
            style: GoogleFonts.montserrat(
              color: (isDark ? Colors.white : Colors.black).withOpacity(0.4),
              fontSize: 12,
              height: 1.5,
            ),
          ),
        ],
      ),
    ).animate().fadeIn(delay: 500.ms).scale(begin: const Offset(0.9, 0.9));
  }

  Widget _buildContentCard(Map<String, dynamic> item, bool isDark, int index) {
    final apiClient = ref.read(apiClientProvider);
    final String title = item['title'] ?? '';
    final String description = item['description'] ?? '';
    final String? imageUrl = item['image'];
    final String? videoUrl = item['videoUrl'];
    final String? thumbnail = item['thumbnail'];
    final String type = item['type'] ?? widget.contentType;
    final DateTime? createdAt = item['createdAt'] != null ? DateTime.tryParse(item['createdAt']) : null;
    final String? projectTitle = item['project'] is Map ? item['project']['title'] : null;

    final String displayImage = thumbnail ?? imageUrl ?? '';
    final String resolvedImage = displayImage.isNotEmpty ? apiClient.resolveUrl(displayImage) : '';

    return Padding(
      padding: const EdgeInsets.only(bottom: 24),
      child: GestureDetector(
        onTap: () => _openContentDetail(item),
        child: Container(
          decoration: BoxDecoration(
            color: (isDark ? Colors.white : Colors.black).withOpacity(0.03),
            borderRadius: BorderRadius.circular(32),
            border: Border.all(color: (isDark ? Colors.white : Colors.black).withOpacity(0.06)),
          ),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // Image
              if (resolvedImage.isNotEmpty)
                ClipRRect(
                  borderRadius: const BorderRadius.vertical(top: Radius.circular(32)),
                  child: AspectRatio(
                    aspectRatio: 16 / 9,
                    child: Stack(
                      fit: StackFit.expand,
                      children: [
                        CachedNetworkImage(
                          imageUrl: resolvedImage,
                          fit: BoxFit.cover,
                          placeholder: (_, __) => Container(color: isDark ? Colors.white10 : Colors.black.withOpacity(0.05)),
                          errorWidget: (_, __, ___) => Container(
                            color: isDark ? Colors.white10 : Colors.black.withOpacity(0.05),
                            child: Icon(widget.typeIcon, color: (isDark ? Colors.white : Colors.black).withOpacity(0.15), size: 48),
                          ),
                        ),
                        // Play icon for video content
                        if (videoUrl != null && videoUrl.isNotEmpty)
                          Center(
                            child: Container(
                              width: 56,
                              height: 56,
                              decoration: BoxDecoration(
                                color: Colors.black.withOpacity(0.6),
                                shape: BoxShape.circle,
                              ),
                              child: const Icon(LucideIcons.play, color: Colors.white, size: 24),
                            ),
                          ),
                      ],
                    ),
                  ),
                ),

              // Content Body
              Padding(
                padding: const EdgeInsets.all(24),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    // Type badge + date
                    Row(
                      children: [
                        Container(
                          padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                          decoration: BoxDecoration(
                            color: (isDark ? Colors.white : Colors.black).withOpacity(0.06),
                            borderRadius: BorderRadius.circular(8),
                          ),
                          child: Text(
                            type.toUpperCase(),
                            style: GoogleFonts.montserrat(
                              color: isDark ? Colors.white : Colors.black,
                              fontSize: 8,
                              fontWeight: FontWeight.w700,
                              letterSpacing: 1.5,
                            ),
                          ),
                        ),
                        if (projectTitle != null) ...[
                          const SizedBox(width: 8),
                          Container(
                            padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                            decoration: BoxDecoration(
                              color: (isDark ? Colors.white : Colors.black).withOpacity(0.03),
                              borderRadius: BorderRadius.circular(8),
                              border: Border.all(color: (isDark ? Colors.white : Colors.black).withOpacity(0.06)),
                            ),
                            child: Text(
                              projectTitle.toUpperCase(),
                              style: GoogleFonts.montserrat(
                                color: (isDark ? Colors.white : Colors.black).withOpacity(0.5),
                                fontSize: 7,
                                fontWeight: FontWeight.w700,
                                letterSpacing: 1,
                              ),
                            ),
                          ),
                        ],
                        const Spacer(),
                        if (createdAt != null)
                          Text(
                            DateFormat('MMM d, yyyy').format(createdAt),
                            style: GoogleFonts.montserrat(
                              color: (isDark ? Colors.white : Colors.black).withOpacity(0.4),
                              fontSize: 10,
                              fontWeight: FontWeight.w500,
                            ),
                          ),
                      ],
                    ),
                    const SizedBox(height: 16),
                    // Title
                    Text(
                      title,
                      style: GoogleFonts.montserrat(
                        color: isDark ? Colors.white : Colors.black,
                        fontSize: 18,
                        fontWeight: FontWeight.w700,
                        letterSpacing: -0.5,
                        height: 1.3,
                      ),
                      maxLines: 2,
                      overflow: TextOverflow.ellipsis,
                    ),
                    if (description.isNotEmpty) ...[
                      const SizedBox(height: 8),
                      Text(
                        description,
                        style: GoogleFonts.montserrat(
                          color: (isDark ? Colors.white : Colors.black).withOpacity(0.6),
                          fontSize: 12,
                          height: 1.5,
                        ),
                        maxLines: 3,
                        overflow: TextOverflow.ellipsis,
                      ),
                    ],
                    const SizedBox(height: 16),
                    // Read More
                    Row(
                      children: [
                        Text(
                          videoUrl != null && videoUrl.isNotEmpty ? 'WATCH NOW' : 'READ MORE',
                          style: GoogleFonts.montserrat(
                            color: isDark ? Colors.white : Colors.black,
                            fontSize: 10,
                            fontWeight: FontWeight.w700,
                            letterSpacing: 2,
                          ),
                        ),
                        const SizedBox(width: 8),
                        Icon(
                          LucideIcons.arrowRight,
                          color: isDark ? Colors.white : Colors.black,
                          size: 14,
                        ),
                      ],
                    ),
                  ],
                ),
              ),
            ],
          ),
        ),
      ),
    ).animate(delay: Duration(milliseconds: 100 * index)).fadeIn().slideY(begin: 0.1);
  }

  void _openContentDetail(Map<String, dynamic> item) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final apiClient = ref.read(apiClientProvider);
    final videoUrl = item['videoUrl'];
    final content = item['content'] ?? '';
    final image = item['image'];
    final title = item['title'] ?? '';
    final description = item['description'] ?? '';

    // If it's a video, try to launch it directly
    if (videoUrl != null && videoUrl.toString().isNotEmpty) {
      launchUrl(Uri.parse(videoUrl.toString()), mode: LaunchMode.externalApplication);
      return;
    }

    // Otherwise show a detail bottom sheet
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (context) {
        return DraggableScrollableSheet(
          initialChildSize: 0.9,
          maxChildSize: 0.95,
          minChildSize: 0.5,
          builder: (context, scrollController) {
            return Container(
              decoration: BoxDecoration(
                color: isDark ? const Color(0xFF111111) : Colors.white,
                borderRadius: const BorderRadius.vertical(top: Radius.circular(32)),
              ),
              child: ListView(
                controller: scrollController,
                padding: const EdgeInsets.all(24),
                children: [
                  // Drag Handle
                  Center(
                    child: Container(
                      width: 40,
                      height: 4,
                      decoration: BoxDecoration(
                        color: (isDark ? Colors.white : Colors.black).withOpacity(0.1),
                        borderRadius: BorderRadius.circular(2),
                      ),
                    ),
                  ),
                  const SizedBox(height: 24),

                  // Hero image
                  if (image != null && image.toString().isNotEmpty)
                    ClipRRect(
                      borderRadius: BorderRadius.circular(24),
                      child: CachedNetworkImage(
                        imageUrl: apiClient.resolveUrl(image),
                        fit: BoxFit.cover,
                        width: double.infinity,
                        placeholder: (_, __) => Container(
                          height: 200,
                          color: isDark ? Colors.white10 : Colors.black.withOpacity(0.05),
                        ),
                      ),
                    ),
                  const SizedBox(height: 24),

                  // Title
                  Text(
                    title,
                    style: GoogleFonts.montserrat(
                      color: isDark ? Colors.white : Colors.black,
                      fontSize: 24,
                      fontWeight: FontWeight.w800,
                      letterSpacing: -0.5,
                      height: 1.2,
                    ),
                  ),
                  const SizedBox(height: 16),

                  // Description
                  if (description.isNotEmpty)
                    Text(
                      description,
                      style: GoogleFonts.montserrat(
                        color: (isDark ? Colors.white : Colors.black).withOpacity(0.6),
                        fontSize: 14,
                        height: 1.6,
                      ),
                    ),

                  // HTML Content (rendered as plain text for now)
                  if (content.toString().isNotEmpty) ...[
                    const SizedBox(height: 24),
                    Text(
                      _stripHtml(content.toString()),
                      style: GoogleFonts.montserrat(
                        color: (isDark ? Colors.white : Colors.black).withOpacity(0.8),
                        fontSize: 13,
                        height: 1.8,
                      ),
                    ),
                  ],

                  const SizedBox(height: 40),
                ],
              ),
            );
          },
        );
      },
    );
  }

  String _stripHtml(String html) {
    final RegExp exp = RegExp(r'<[^>]*>', multiLine: true, caseSensitive: true);
    return html.replaceAll(exp, '').replaceAll('&nbsp;', ' ').replaceAll('&amp;', '&').trim();
  }
}
