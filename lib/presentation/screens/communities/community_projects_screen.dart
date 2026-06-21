import 'dart:ui';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:lucide_icons/lucide_icons.dart';
import 'package:cached_network_image/cached_network_image.dart';
import 'package:flutter_animate/flutter_animate.dart';
import 'package:m4_mobile/core/theme/app_theme.dart';
import 'package:m4_mobile/core/network/api_client.dart';
import 'package:m4_mobile/presentation/providers/auth_provider.dart';

/// GUEST: all projects within a single community, scoped by [slug].
/// Mirrors web `/guest/communities/[slug]/projects`.
class CommunityProjectsListScreen extends ConsumerStatefulWidget {
  final String slug;
  const CommunityProjectsListScreen({super.key, required this.slug});

  @override
  ConsumerState<CommunityProjectsListScreen> createState() => _CommunityProjectsListScreenState();
}

class _CommunityProjectsListScreenState extends ConsumerState<CommunityProjectsListScreen> {
  Map<String, dynamic>? _community;
  List<dynamic> _projects = [];
  bool _loading = true;
  String? _error;

  @override
  void initState() {
    super.initState();
    _fetchData();
  }

  Future<void> _fetchData() async {
    setState(() {
      _loading = true;
      _error = null;
    });
    try {
      final apiClient = ref.read(apiClientProvider);

      // 1. Fetch community by slug → extract ID.
      final commRes = await apiClient.getCommunityBySlug(widget.slug);
      if (commRes.data['status'] == true && commRes.data['data'] != null) {
        final community = Map<String, dynamic>.from(commRes.data['data'] as Map);
        final communityId = (community['_id'] ?? community['id'])?.toString();

        List<dynamic> projects = [];
        if (communityId != null && communityId.isNotEmpty) {
          // 2. Fetch projects for this community.
          final projRes = await apiClient.getProjectsByCommunity(communityId);
          if (projRes.data['status'] == true) {
            projects = projRes.data['data'] as List? ?? [];
          }
        }

        if (mounted) {
          setState(() {
            _community = community;
            _projects = projects;
            _loading = false;
          });
        }
      } else {
        if (mounted) {
          setState(() {
            _error = 'Community not found';
            _loading = false;
          });
        }
      }
    } catch (e) {
      if (mounted) {
        setState(() {
          _error = e.toString();
          _loading = false;
        });
      }
    }
  }

  void _goBack() {
    if (context.canPop()) {
      context.pop();
    } else {
      context.go('/communities');
    }
  }

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final bg = isDark ? Colors.black : Colors.white;
    final textPrimary = isDark ? Colors.white : Colors.black;
    final muted = (isDark ? Colors.white : Colors.black).withValues(alpha: 0.5);
    final apiClient = ref.watch(apiClientProvider);

    return Scaffold(
      backgroundColor: bg,
      body: _loading
          ? const Center(child: CircularProgressIndicator(color: M4Theme.premiumBlue))
          : _error != null
              ? _ErrorState(message: _error!, isDark: isDark, onBack: _goBack)
              : SafeArea(
                  bottom: false,
                  child: CustomScrollView(
                    slivers: [
                      // 🔝 Sticky Glass Header
                      SliverPersistentHeader(
                        pinned: true,
                        delegate: _GlassHeaderDelegate(
                          isDark: isDark,
                          textPrimary: textPrimary,
                          muted: muted,
                          onBack: _goBack,
                        ),
                      ),

                      // 🏷️ Community Intro (left-bordered title block)
                      SliverToBoxAdapter(
                        child: Padding(
                          padding: const EdgeInsets.fromLTRB(28, 32, 28, 28),
                          child: Container(
                            padding: const EdgeInsets.only(left: 16),
                            decoration: BoxDecoration(
                              border: Border(
                                left: BorderSide(
                                  color: (isDark ? Colors.white : Colors.black)
                                      .withValues(alpha: isDark ? 0.3 : 0.2),
                                  width: 4,
                                ),
                              ),
                            ),
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Text(
                                  (_community?['title'] ?? '').toString().toUpperCase(),
                                  style: GoogleFonts.montserrat(
                                    fontSize: 30,
                                    fontWeight: FontWeight.w900,
                                    color: textPrimary,
                                    letterSpacing: -1,
                                    height: 1.0,
                                  ),
                                ),
                                const SizedBox(height: 10),
                                Text(
                                  'DISCOVER ALL PROJECTS IN THIS COMMUNITY',
                                  style: GoogleFonts.montserrat(
                                    fontSize: 10,
                                    fontWeight: FontWeight.w700,
                                    color: muted,
                                    letterSpacing: 3,
                                  ),
                                ),
                              ],
                            ),
                          ),
                        ),
                      ),

                      // 🏙️ Projects feed (single column) or empty state
                      if (_projects.isEmpty)
                        SliverFillRemaining(
                          hasScrollBody: false,
                          child: _EmptyState(isDark: isDark, muted: muted, onReturn: _goBack),
                        )
                      else
                        SliverPadding(
                          padding: const EdgeInsets.fromLTRB(28, 0, 28, 60),
                          sliver: SliverList(
                            delegate: SliverChildBuilderDelegate(
                              (context, index) {
                                final project = _projects[index];
                                return _ProjectCard(
                                  project: project,
                                  apiClient: apiClient,
                                  index: index,
                                  onTap: () {
                                    final projectId = (project['_id'] ?? project['id'])?.toString() ?? '';
                                    if (projectId.isEmpty) return;
                                    final map = project is Map<String, dynamic>
                                        ? project
                                        : Map<String, dynamic>.from(project as Map);
                                    context.push('/guest/projects/$projectId', extra: map);
                                  },
                                );
                              },
                              childCount: _projects.length,
                            ),
                          ),
                        ),
                    ],
                  ),
                ),
    );
  }
}

// ==========================================
// STICKY GLASS HEADER
// ==========================================
class _GlassHeaderDelegate extends SliverPersistentHeaderDelegate {
  final bool isDark;
  final Color textPrimary;
  final Color muted;
  final VoidCallback onBack;

  _GlassHeaderDelegate({
    required this.isDark,
    required this.textPrimary,
    required this.muted,
    required this.onBack,
  });

  @override
  double get minExtent => 76;
  @override
  double get maxExtent => 76;

  @override
  Widget build(BuildContext context, double shrinkOffset, bool overlapsContent) {
    final bg = isDark ? Colors.black : Colors.white;
    return ClipRect(
      child: BackdropFilter(
        filter: ImageFilter.blur(sigmaX: 18, sigmaY: 18),
        child: Container(
          padding: const EdgeInsets.symmetric(horizontal: 24),
          decoration: BoxDecoration(
            color: bg.withValues(alpha: 0.8),
            border: Border(
              bottom: BorderSide(
                color: (isDark ? Colors.white : Colors.black).withValues(alpha: 0.08),
              ),
            ),
          ),
          child: Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              // Back button
              _ScaleButton(
                onTap: onBack,
                child: Row(
                  children: [
                    Icon(LucideIcons.arrowLeft, color: muted, size: 20),
                    const SizedBox(width: 8),
                    Text(
                      'BACK',
                      style: GoogleFonts.montserrat(
                        fontSize: 10,
                        fontWeight: FontWeight.w900,
                        color: muted,
                        letterSpacing: 2,
                      ),
                    ),
                  ],
                ),
              ),
              // Title + subtitle
              Column(
                mainAxisAlignment: MainAxisAlignment.center,
                crossAxisAlignment: CrossAxisAlignment.end,
                children: [
                  Text(
                    'M4 FAMILY',
                    style: GoogleFonts.montserrat(
                      fontSize: 18,
                      fontWeight: FontWeight.w900,
                      color: textPrimary,
                      letterSpacing: -1,
                      height: 1.0,
                    ),
                  ),
                  const SizedBox(height: 4),
                  Text(
                    'COMMUNITY PORTFOLIO',
                    style: GoogleFonts.montserrat(
                      fontSize: 8,
                      fontWeight: FontWeight.w700,
                      color: muted,
                      letterSpacing: 3,
                    ),
                  ),
                ],
              ),
            ],
          ),
        ),
      ),
    );
  }

  @override
  bool shouldRebuild(covariant _GlassHeaderDelegate oldDelegate) {
    return oldDelegate.isDark != isDark ||
        oldDelegate.textPrimary != textPrimary ||
        oldDelegate.muted != muted;
  }
}

// ==========================================
// HERO-IMAGE PROJECT CARD (single column feed)
// ==========================================
class _ProjectCard extends StatelessWidget {
  final dynamic project;
  final ApiClient apiClient;
  final int index;
  final VoidCallback onTap;

  const _ProjectCard({
    required this.project,
    required this.apiClient,
    required this.index,
    required this.onTap,
  });

  bool _hasStartingPrice(String? price) {
    if (price == null || price.isEmpty) return false;
    final lower = price.toLowerCase();
    if (lower.contains('request')) return false;
    if (price.contains('%')) return false;
    return true;
  }

  @override
  Widget build(BuildContext context) {
    final status = project['status']?.toString() ?? '';
    final isCompleted = status.toLowerCase() == 'completed';
    final startingPrice = project['startingPrice']?.toString();
    final rawHero = project['heroImage']?.toString() ?? project['image']?.toString();
    final imageUrl = apiClient.resolveUrl(rawHero);
    final location = (project['location']?['name'] ?? project['location'] ?? '').toString();

    return _ScaleButton(
      onTap: onTap,
      child: Container(
        margin: const EdgeInsets.only(bottom: 28),
        height: 250,
        decoration: BoxDecoration(
          borderRadius: BorderRadius.circular(28),
          boxShadow: [
            BoxShadow(
              color: Colors.black.withValues(alpha: 0.25),
              blurRadius: 24,
              offset: const Offset(0, 12),
            ),
          ],
        ),
        clipBehavior: Clip.antiAlias,
        child: Stack(
          fit: StackFit.expand,
          children: [
            // Hero image
            CachedNetworkImage(
              imageUrl: imageUrl,
              fit: BoxFit.cover,
              fadeInDuration: const Duration(milliseconds: 400),
              placeholder: (context, url) => Container(color: Colors.black12),
              errorWidget: (context, url, error) =>
                  Container(color: Colors.black26, child: const Icon(Icons.error, color: Colors.white24)),
            ),

            // Top dark gradient (black/0.6 → transparent)
            Container(
              decoration: BoxDecoration(
                gradient: LinearGradient(
                  begin: Alignment.topCenter,
                  end: Alignment.center,
                  colors: [
                    Colors.black.withValues(alpha: 0.6),
                    Colors.transparent,
                  ],
                ),
              ),
            ),
            // Bottom dark gradient (black/0.9 → transparent top)
            Container(
              decoration: BoxDecoration(
                gradient: LinearGradient(
                  begin: Alignment.bottomCenter,
                  end: Alignment.topCenter,
                  colors: [
                    Colors.black.withValues(alpha: 0.9),
                    Colors.black.withValues(alpha: 0.2),
                    Colors.transparent,
                  ],
                  stops: const [0.0, 0.55, 1.0],
                ),
              ),
            ),

            // Status badge (top-right)
            if (status.isNotEmpty)
              Positioned(
                top: 24,
                right: 24,
                child: Container(
                  padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 8),
                  decoration: BoxDecoration(
                    color: Colors.white.withValues(alpha: 0.1),
                    borderRadius: BorderRadius.circular(30),
                    border: Border.all(color: Colors.white.withValues(alpha: 0.1)),
                  ),
                  child: Text(
                    status.toUpperCase(),
                    style: GoogleFonts.montserrat(
                      fontSize: 9,
                      fontWeight: FontWeight.w900,
                      color: Colors.white,
                      letterSpacing: 2,
                    ),
                  ),
                ),
              ),

            // Top-left content block
            Positioned(
              top: 28,
              left: 28,
              right: 28,
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    (project['title'] ?? '').toString().toUpperCase(),
                    style: GoogleFonts.montserrat(
                      fontSize: 24,
                      fontWeight: FontWeight.w900,
                      color: Colors.white,
                      letterSpacing: -1,
                      height: 1.0,
                    ),
                    maxLines: 2,
                    overflow: TextOverflow.ellipsis,
                  ),
                  const SizedBox(height: 8),
                  Row(
                    children: [
                      Icon(LucideIcons.mapPin, size: 12, color: Colors.white.withValues(alpha: 0.6)),
                      const SizedBox(width: 6),
                      Expanded(
                        child: Text(
                          location.toUpperCase(),
                          style: GoogleFonts.montserrat(
                            fontSize: 8,
                            fontWeight: FontWeight.w700,
                            color: Colors.white.withValues(alpha: 0.6),
                            letterSpacing: 2,
                          ),
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 14),
                  // Divider
                  Container(
                    height: 1,
                    width: 40,
                    color: Colors.white.withValues(alpha: 0.2),
                  ),
                  if (_hasStartingPrice(startingPrice)) ...[
                    const SizedBox(height: 14),
                    Text(
                      'STARTING FROM',
                      style: GoogleFonts.montserrat(
                        fontSize: 7,
                        fontWeight: FontWeight.w900,
                        color: Colors.white.withValues(alpha: 0.4),
                        letterSpacing: 2,
                      ),
                    ),
                    const SizedBox(height: 4),
                    Text(
                      startingPrice!,
                      style: GoogleFonts.montserrat(
                        fontSize: 16,
                        fontWeight: FontWeight.w900,
                        color: const Color(0xFFC4A484),
                        letterSpacing: -0.2,
                      ),
                    ),
                  ],
                ],
              ),
            ),

            // Artistic impression label (bottom-left)
            if (!isCompleted)
              Positioned(
                bottom: 24,
                left: 28,
                child: Text(
                  '* ARTISTIC IMPRESSION',
                  style: GoogleFonts.montserrat(
                    fontSize: 6,
                    fontWeight: FontWeight.w700,
                    color: Colors.white.withValues(alpha: 0.3),
                    letterSpacing: 2,
                  ),
                ),
              ),

            // Action arrow (bottom-right)
            Positioned(
              bottom: 28,
              right: 28,
              child: Container(
                width: 48,
                height: 48,
                decoration: BoxDecoration(
                  color: Colors.white,
                  shape: BoxShape.circle,
                  boxShadow: [
                    BoxShadow(
                      color: Colors.black.withValues(alpha: 0.3),
                      blurRadius: 12,
                      offset: const Offset(0, 6),
                    ),
                  ],
                ),
                child: const Icon(LucideIcons.arrowRight, color: Colors.black, size: 20),
              ),
            ),
          ],
        ),
      ),
    ).animate().fadeIn(delay: (index * 80).ms).slideY(begin: 0.06, end: 0);
  }
}

// ==========================================
// EMPTY STATE
// ==========================================
class _EmptyState extends StatelessWidget {
  final bool isDark;
  final Color muted;
  final VoidCallback onReturn;
  const _EmptyState({required this.isDark, required this.muted, required this.onReturn});

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 28, vertical: 60),
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Icon(LucideIcons.layoutGrid, size: 48, color: muted.withValues(alpha: 0.4)),
          const SizedBox(height: 20),
          Text(
            'NO PROJECTS FOUND IN THIS COMMUNITY',
            textAlign: TextAlign.center,
            style: GoogleFonts.montserrat(
              fontSize: 12,
              fontWeight: FontWeight.w900,
              color: muted,
              letterSpacing: 2,
            ),
          ),
          const SizedBox(height: 28),
          OutlinedButton(
            onPressed: onReturn,
            style: OutlinedButton.styleFrom(
              padding: const EdgeInsets.symmetric(horizontal: 40, vertical: 18),
              side: BorderSide(color: (isDark ? Colors.white : Colors.black).withValues(alpha: 0.2)),
              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
            ),
            child: Text(
              'RETURN',
              style: GoogleFonts.montserrat(
                fontSize: 10,
                fontWeight: FontWeight.w900,
                color: isDark ? Colors.white : Colors.black,
                letterSpacing: 2,
              ),
            ),
          ),
        ],
      ),
    );
  }
}

// ==========================================
// ERROR STATE
// ==========================================
class _ErrorState extends StatelessWidget {
  final String message;
  final bool isDark;
  final VoidCallback onBack;
  const _ErrorState({required this.message, required this.isDark, required this.onBack});

  @override
  Widget build(BuildContext context) {
    final muted = (isDark ? Colors.white : Colors.black).withValues(alpha: 0.5);
    return Center(
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 28),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(LucideIcons.alertTriangle, size: 44, color: muted.withValues(alpha: 0.5)),
            const SizedBox(height: 18),
            Text(
              'UNABLE TO LOAD PROJECTS',
              textAlign: TextAlign.center,
              style: GoogleFonts.montserrat(
                fontSize: 12,
                fontWeight: FontWeight.w900,
                color: isDark ? Colors.white : Colors.black,
                letterSpacing: 2,
              ),
            ),
            const SizedBox(height: 8),
            Text(
              message,
              textAlign: TextAlign.center,
              maxLines: 3,
              overflow: TextOverflow.ellipsis,
              style: GoogleFonts.montserrat(fontSize: 10, color: muted, fontWeight: FontWeight.w500),
            ),
            const SizedBox(height: 28),
            OutlinedButton(
              onPressed: onBack,
              style: OutlinedButton.styleFrom(
                padding: const EdgeInsets.symmetric(horizontal: 40, vertical: 18),
                side: BorderSide(color: (isDark ? Colors.white : Colors.black).withValues(alpha: 0.2)),
                shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
              ),
              child: Text(
                'GO BACK',
                style: GoogleFonts.montserrat(
                  fontSize: 10,
                  fontWeight: FontWeight.w900,
                  color: isDark ? Colors.white : Colors.black,
                  letterSpacing: 2,
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}

// ==========================================
// PRESS-FEEDBACK WRAPPER
// ==========================================
class _ScaleButton extends StatefulWidget {
  final Widget child;
  final VoidCallback onTap;
  const _ScaleButton({required this.child, required this.onTap});

  @override
  State<_ScaleButton> createState() => _ScaleButtonState();
}

class _ScaleButtonState extends State<_ScaleButton> {
  bool _pressed = false;

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTapDown: (_) => setState(() => _pressed = true),
      onTapUp: (_) => setState(() => _pressed = false),
      onTapCancel: () => setState(() => _pressed = false),
      onTap: widget.onTap,
      child: AnimatedScale(
        scale: _pressed ? 0.97 : 1.0,
        duration: const Duration(milliseconds: 120),
        child: widget.child,
      ),
    );
  }
}
