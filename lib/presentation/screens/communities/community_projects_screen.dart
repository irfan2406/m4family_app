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
  ConsumerState<CommunityProjectsListScreen> createState() =>
      _CommunityProjectsListScreenState();
}

class _CommunityProjectsListScreenState
    extends ConsumerState<CommunityProjectsListScreen> {
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
        final community = Map<String, dynamic>.from(
          commRes.data['data'] as Map,
        );
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
    final bg = isDark ? Colors.black : const Color(0xFFF4EFE3);
    final textPrimary = isDark ? Colors.white : const Color(0xFF0C312B);
    final muted = (isDark ? Colors.white : const Color(0xFF0C312B)).withValues(
      alpha: 0.5,
    );
    final apiClient = ref.watch(apiClientProvider);

    return Scaffold(
      backgroundColor: bg,
      body: _loading
          ? const Center(
              child: CircularProgressIndicator.adaptive(
                valueColor: AlwaysStoppedAnimation<Color>(M4Theme.premiumBlue),
              ),
            )
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
                              color:
                                  (isDark
                                          ? Colors.white
                                          : const Color(0xFF0C312B))
                                      .withValues(alpha: isDark ? 0.3 : 0.2),
                              width: 4,
                            ),
                          ),
                        ),
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(
                              (_community?['title'] ?? '')
                                  .toString()
                                  .toUpperCase(),
                              style: GoogleFonts.gelasio(
                                fontSize: 30,
                                fontWeight: FontWeight.w700,
                                color: textPrimary,
                                letterSpacing: -1,
                                height: 1.0,
                              ),
                            ),
                            const SizedBox(height: 10),
                            Text(
                              'DISCOVER ALL PROJECTS IN THIS COMMUNITY',
                              style: GoogleFonts.gelasio(
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
                      child: _EmptyState(
                        isDark: isDark,
                        muted: muted,
                        onReturn: _goBack,
                      ),
                    )
                  else
                    SliverPadding(
                      padding: const EdgeInsets.fromLTRB(20, 0, 20, 60),
                      sliver: SliverList(
                        delegate: SliverChildBuilderDelegate((context, index) {
                          final project = _projects[index];
                          return _ProjectCard(
                            project: project,
                            apiClient: apiClient,
                            index: index,
                            onTap: () {
                              final projectId =
                                  (project['_id'] ?? project['id'])
                                      ?.toString() ??
                                  '';
                              if (projectId.isEmpty) return;
                              final map = project is Map<String, dynamic>
                                  ? project
                                  : Map<String, dynamic>.from(project as Map);
                              context.push(
                                '/guest/projects/$projectId',
                                extra: map,
                              );
                            },
                          );
                        }, childCount: _projects.length),
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
  Widget build(
    BuildContext context,
    double shrinkOffset,
    bool overlapsContent,
  ) {
    return ClipRect(
      child: BackdropFilter(
        filter: ImageFilter.blur(sigmaX: 18, sigmaY: 18),
        child: Container(
          color: (isDark ? const Color(0xFF0D1D19) : const Color(0xFFFAF8F5))
              .withValues(alpha: 0.88),
          padding: const EdgeInsets.fromLTRB(20, 36, 20, 10),
          child: Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              _ScaleButton(
                onTap: onBack,
                child: Padding(
                  padding: const EdgeInsets.all(4),
                  child: Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Icon(
                        LucideIcons.arrowLeft,
                        size: 16,
                        color: textPrimary,
                      ),
                      const SizedBox(width: 8),
                      Text(
                        'BACK',
                        style: GoogleFonts.gelasio(
                          fontSize: 9,
                          fontWeight: FontWeight.w700,
                          color: textPrimary.withValues(alpha: 0.7),
                          letterSpacing: 2,
                        ),
                      ),
                    ],
                  ),
                ),
              ),

              Column(
                mainAxisSize: MainAxisSize.min,
                crossAxisAlignment: CrossAxisAlignment.end,
                children: [
                  Text(
                    'M4 FAMILY',
                    style: GoogleFonts.gelasio(
                      fontSize: 16,
                      fontWeight: FontWeight.w700,
                      color: textPrimary,
                      letterSpacing: -0.5,
                      height: 1.0,
                    ),
                  ),
                  const SizedBox(height: 2),
                  Text(
                    'COMMUNITY PORTFOLIO',
                    style: GoogleFonts.gelasio(
                      fontSize: 7,
                      fontWeight: FontWeight.w700,
                      color: muted,
                      letterSpacing: 1.5,
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
  bool shouldRebuild(covariant _GlassHeaderDelegate oldDelegate) =>
      oldDelegate.isDark != isDark ||
      oldDelegate.textPrimary != textPrimary ||
      oldDelegate.muted != muted;
}

// ==========================================
// PROJECT CARD
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
    if (price == null) return false;
    final lower = price.trim().toLowerCase();
    if (lower.isEmpty) return false;
    if (lower == 'price on request' || lower == 'upon request') return false;
    return true;
  }

  @override
  Widget build(BuildContext context) {
    final status = project['status']?.toString() ?? '';
    final isCompleted = status.toLowerCase() == 'completed';
    final startingPrice = project['startingPrice']?.toString();
    final rawHero =
        project['heroImage']?.toString() ?? project['image']?.toString();
    final imageUrl = apiClient.resolveUrl(rawHero);
    final location = (project['location']?['name'] ?? project['location'] ?? '')
        .toString();

    return _ScaleButton(
      onTap: onTap,
      // The 16dp gap to the next card sits outside the 16:9 frame. As a margin
      // inside it, the gap came off the card itself and left the thumbnail
      // 16dp short of 16:9 (about 1.95:1 on a phone).
      child: Padding(
        padding: const EdgeInsets.only(bottom: 16),
        child: AspectRatio(
          aspectRatio: 16 / 9,
          child: Container(
            decoration: BoxDecoration(
              borderRadius: BorderRadius.circular(20),
              boxShadow: [
                BoxShadow(
                  color: Colors.black.withValues(alpha: 0.2),
                  blurRadius: 16,
                  offset: const Offset(0, 8),
                ),
              ],
            ),
            clipBehavior: Clip.antiAlias,
            child: Stack(
              fit: StackFit.expand,
              children: [
                // Hero image
                CachedNetworkImage(
                  memCacheWidth: 1080,
                  imageUrl: imageUrl,
                  fit: BoxFit.cover,
                  fadeInDuration: const Duration(milliseconds: 400),
                  placeholder: (context, url) =>
                      Container(color: Colors.black12),
                  errorWidget: (context, url, error) => Container(
                    color: Colors.black26,
                    child: const Icon(
                      LucideIcons.alertCircle,
                      color: Colors.white38,
                    ),
                  ),
                ),

                // Gradient overlays
                Container(
                  decoration: BoxDecoration(
                    gradient: LinearGradient(
                      begin: Alignment.topCenter,
                      end: Alignment.bottomCenter,
                      colors: [
                        Colors.black.withValues(alpha: 0.5),
                        Colors.transparent,
                        Colors.black.withValues(alpha: 0.8),
                      ],
                      stops: const [0.0, 0.45, 1.0],
                    ),
                  ),
                ),

                // Status badge (top-right)
                if (status.isNotEmpty)
                  Positioned(
                    top: 16,
                    right: 16,
                    child: Container(
                      padding: const EdgeInsets.symmetric(
                        horizontal: 10,
                        vertical: 5,
                      ),
                      decoration: BoxDecoration(
                        color: Colors.white.withValues(alpha: 0.15),
                        borderRadius: BorderRadius.circular(16),
                        border: Border.all(
                          color: Colors.white.withValues(alpha: 0.2),
                        ),
                      ),
                      child: Text(
                        status.toUpperCase(),
                        style: GoogleFonts.gelasio(
                          fontSize: 8,
                          fontWeight: FontWeight.w700,
                          color: Colors.white,
                          letterSpacing: 1.5,
                        ),
                      ),
                    ),
                  ),

                // Top-left content block: Title & Location
                Positioned(
                  top: 18,
                  left: 18,
                  right: 75,
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        (project['title'] ?? '').toString().toUpperCase(),
                        style: GoogleFonts.gelasio(
                          fontSize: 20,
                          fontWeight: FontWeight.w700,
                          color: Colors.white,
                          letterSpacing: -0.5,
                          height: 1.0,
                        ),
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                      ),
                      const SizedBox(height: 3),
                      Row(
                        children: [
                          Icon(
                            LucideIcons.mapPin,
                            size: 10,
                            color: Colors.white.withValues(alpha: 0.7),
                          ),
                          const SizedBox(width: 4),
                          Expanded(
                            child: Text(
                              location.toUpperCase(),
                              style: GoogleFonts.gelasio(
                                fontSize: 8,
                                fontWeight: FontWeight.w700,
                                color: Colors.white.withValues(alpha: 0.7),
                                letterSpacing: 1.5,
                              ),
                              maxLines: 1,
                              overflow: TextOverflow.ellipsis,
                            ),
                          ),
                        ],
                      ),
                      if (_hasStartingPrice(startingPrice)) ...[
                        const SizedBox(height: 4),
                        Text(
                          'STARTING FROM',
                          style: GoogleFonts.gelasio(
                            fontSize: 7,
                            fontWeight: FontWeight.w700,
                            color: Colors.white.withValues(alpha: 0.65),
                            letterSpacing: 1.5,
                          ),
                        ),
                        Text(
                          startingPrice!,
                          style: GoogleFonts.inter(
                            fontSize: 13,
                            fontWeight: FontWeight.w600,
                            color: const Color(0xFFF4EFE3),
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
                    bottom: 16,
                    left: 18,
                    child: Text(
                      '* ARTISTIC IMPRESSION',
                      style: GoogleFonts.gelasio(
                        fontSize: 6,
                        fontWeight: FontWeight.w700,
                        color: Colors.white.withValues(alpha: 0.75),
                        letterSpacing: 1.5,
                      ),
                    ),
                  ),

                // Action arrow (bottom-right)
                Positioned(
                  bottom: 16,
                  right: 16,
                  child: Container(
                    width: 38,
                    height: 38,
                    decoration: BoxDecoration(
                      color: const Color(0xFFF4EFE3),
                      shape: BoxShape.circle,
                      boxShadow: [
                        BoxShadow(
                          color: Colors.black.withValues(alpha: 0.2),
                          blurRadius: 8,
                          offset: const Offset(0, 4),
                        ),
                      ],
                    ),
                    child: const Icon(
                      LucideIcons.arrowRight,
                      color: Color(0xFF0C312B),
                      size: 16,
                    ),
                  ),
                ),
              ],
            ),
          ),
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
  const _EmptyState({
    required this.isDark,
    required this.muted,
    required this.onReturn,
  });

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 28, vertical: 60),
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Icon(
            LucideIcons.layoutGrid,
            size: 48,
            color: muted.withValues(alpha: 0.4),
          ),
          const SizedBox(height: 20),
          Text(
            'NO PROJECTS FOUND IN THIS COMMUNITY',
            textAlign: TextAlign.center,
            style: GoogleFonts.gelasio(
              fontSize: 12,
              fontWeight: FontWeight.w700,
              color: muted,
              letterSpacing: 2,
            ),
          ),
          const SizedBox(height: 28),
          OutlinedButton(
            onPressed: onReturn,
            style: OutlinedButton.styleFrom(
              padding: const EdgeInsets.symmetric(horizontal: 40, vertical: 18),
              side: BorderSide(
                color: (isDark ? Colors.white : const Color(0xFF0C312B))
                    .withValues(alpha: 0.2),
              ),
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(20),
              ),
            ),
            child: Text(
              'RETURN',
              style: GoogleFonts.gelasio(
                fontSize: 10,
                fontWeight: FontWeight.w700,
                color: isDark ? Colors.white : const Color(0xFF0C312B),
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
  const _ErrorState({
    required this.message,
    required this.isDark,
    required this.onBack,
  });

  @override
  Widget build(BuildContext context) {
    final muted = (isDark ? Colors.white : const Color(0xFF0C312B)).withValues(
      alpha: 0.5,
    );
    return Center(
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 28),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(
              LucideIcons.alertTriangle,
              size: 44,
              color: muted.withValues(alpha: 0.5),
            ),
            const SizedBox(height: 18),
            Text(
              'UNABLE TO LOAD PROJECTS',
              textAlign: TextAlign.center,
              style: GoogleFonts.gelasio(
                fontSize: 12,
                fontWeight: FontWeight.w700,
                color: isDark ? Colors.white : const Color(0xFF0C312B),
                letterSpacing: 2,
              ),
            ),
            const SizedBox(height: 8),
            Text(
              message,
              textAlign: TextAlign.center,
              maxLines: 3,
              overflow: TextOverflow.ellipsis,
              style: GoogleFonts.inter(
                fontSize: 10,
                color: muted,
                fontWeight: FontWeight.w500,
              ),
            ),
            const SizedBox(height: 28),
            OutlinedButton(
              onPressed: onBack,
              style: OutlinedButton.styleFrom(
                padding: const EdgeInsets.symmetric(
                  horizontal: 40,
                  vertical: 18,
                ),
                side: BorderSide(
                  color: (isDark ? Colors.white : const Color(0xFF0C312B))
                      .withValues(alpha: 0.2),
                ),
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(20),
                ),
              ),
              child: Text(
                'GO BACK',
                style: GoogleFonts.gelasio(
                  fontSize: 10,
                  fontWeight: FontWeight.w700,
                  color: isDark ? Colors.white : const Color(0xFF0C312B),
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
