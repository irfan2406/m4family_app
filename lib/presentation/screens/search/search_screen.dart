import 'dart:ui';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:cached_network_image/cached_network_image.dart';
import 'package:lucide_icons/lucide_icons.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:flutter_animate/flutter_animate.dart';
import 'package:m4_mobile/core/theme/app_theme.dart';
import 'package:m4_mobile/core/network/api_client.dart';
import 'package:m4_mobile/presentation/providers/auth_provider.dart';
import 'package:m4_mobile/presentation/screens/projects/project_detail_screen.dart';
import 'package:m4_mobile/presentation/screens/projects/guest_project_detail_screen.dart';

/// Query parameters that drive the search. Mirrors the web `/search` page which
/// reads `query`, `location` (comma list), `budget` (comma list), `type`
/// (comma list) and `status` from the URL search params.
class SearchQuery {
  final String query;
  final List<String> locations;
  final List<String> budgets;
  final List<String> types;
  final String status;

  const SearchQuery({
    this.query = '',
    this.locations = const [],
    this.budgets = const [],
    this.types = const [],
    this.status = '',
  });

  /// Accepts both a raw `Map<String, dynamic>` (Navigator push `extra`) and the
  /// `Map<String, String>` produced by GoRouter `state.uri.queryParameters`.
  factory SearchQuery.fromParams(Map<String, dynamic> params) {
    List<String> splitParam(dynamic v) {
      if (v == null) return const [];
      if (v is List) {
        return v.map((e) => e.toString().trim()).where((e) => e.isNotEmpty).toList();
      }
      return v
          .toString()
          .split(',')
          .map((e) => e.trim())
          .where((e) => e.isNotEmpty)
          .toList();
    }

    return SearchQuery(
      query: params['query']?.toString() ?? '',
      locations: splitParam(params['location']),
      budgets: splitParam(params['budget']),
      types: splitParam(params['type']),
      status: params['status']?.toString() ?? '',
    );
  }

  @override
  bool operator ==(Object other) =>
      other is SearchQuery &&
      other.query == query &&
      other.status == status &&
      other.locations.join(',') == locations.join(',') &&
      other.budgets.join(',') == budgets.join(',') &&
      other.types.join(',') == types.join(',');

  @override
  int get hashCode => Object.hash(
        query,
        status,
        locations.join(','),
        budgets.join(','),
        types.join(','),
      );
}

/// Fetches all projects via [ApiClient.getProjects] then filters client-side,
/// matching the web `/search` page logic exactly.
final searchResultsProvider =
    FutureProvider.family<List<dynamic>, SearchQuery>((ref, q) async {
  final apiClient = ref.watch(apiClientProvider);
  try {
    final response = await apiClient.getProjects();
    final ok = response.statusCode == 200 || response.statusCode == 201;
    if (!ok) return const [];
    final List<dynamic> projects = (response.data['data'] as List?) ?? const [];

    final queryLc = q.query.toLowerCase();

    return projects.where((p) {
      final title = (p['title']?.toString() ?? '').toLowerCase();
      final location =
          (p['location']?['name']?.toString() ?? '').toLowerCase();
      final description = (p['description']?.toString() ?? '').toLowerCase();
      final statusVal = (p['status']?.toString() ?? '');
      final startingPrice = (p['startingPrice']?.toString() ?? '');
      final projectType = (p['category']?['name']?.toString() ?? '');

      final matchesQuery = q.query.isEmpty ||
          title.contains(queryLc) ||
          location.contains(queryLc) ||
          description.contains(queryLc);

      final matchesStatus = q.status.isEmpty ||
          statusVal.toLowerCase() == q.status.toLowerCase();

      final matchesLocation = q.locations.isEmpty ||
          q.locations.any((loc) => location.contains(loc.toLowerCase()));

      final matchesBudget = q.budgets.isEmpty ||
          q.budgets.any((budget) {
            final priceValue = double.tryParse(
                    startingPrice.replaceAll(RegExp(r'[^\d.]'), '')) ??
                0;
            switch (budget) {
              case '< 5 Cr':
                return priceValue < 5;
              case '5 - 10 Cr':
                return priceValue >= 5 && priceValue <= 10;
              case '10 - 20 Cr':
                return priceValue >= 10 && priceValue <= 20;
              case '20 Cr +':
                return priceValue > 20;
              default:
                return true;
            }
          });

      final matchesType = q.types.isEmpty ||
          q.types.any((type) =>
              projectType.toLowerCase().contains(type.toLowerCase()) ||
              description.contains(type.toLowerCase()));

      return matchesQuery &&
          matchesStatus &&
          matchesLocation &&
          matchesBudget &&
          matchesType;
    }).toList();
  } catch (_) {
    return const [];
  }
});

/// Search results screen. Reached via go_router `/search?query=...` or pushed
/// from a parent screen (project_list / custom_views) with an `extra` Map of
/// query params.
class SearchScreen extends ConsumerStatefulWidget {
  const SearchScreen({super.key, this.params});

  /// Raw query params when pushed via Navigator (extra Map). When reached via
  /// go_router the params are read from the route's query parameters instead.
  final Map<String, dynamic>? params;

  @override
  ConsumerState<SearchScreen> createState() => _SearchScreenState();
}

class _SearchScreenState extends ConsumerState<SearchScreen> {
  late SearchQuery _query;

  @override
  void initState() {
    super.initState();
    _query = SearchQuery.fromParams(widget.params ?? const {});
  }

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    // When reached via go_router, prefer the route's query parameters.
    if (widget.params == null) {
      final routerState = GoRouterState.of(context);
      final qp = routerState.uri.queryParameters;
      if (qp.isNotEmpty) {
        _query = SearchQuery.fromParams(Map<String, dynamic>.from(qp));
      }
    }
  }

  void _goBack() {
    if (context.canPop()) {
      context.pop();
    } else {
      context.go('/home');
    }
  }

  void _openProject(BuildContext context, dynamic project) {
    final projectId = project['_id']?.toString() ?? '';
    if (projectId.isEmpty) return;
    final authState = ref.read(authProvider);
    if (authState.status == AuthStatus.authenticated) {
      Navigator.push(
        context,
        MaterialPageRoute(
          builder: (context) =>
              ProjectDetailScreen(projectId: projectId, projectData: project),
        ),
      );
    } else {
      Navigator.push(
        context,
        MaterialPageRoute(
          builder: (context) => GuestProjectDetailScreen(
              projectId: projectId, projectData: project),
        ),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final bg = isDark ? Colors.black : Colors.white;
    final textPrimary = isDark ? Colors.white : Colors.black;
    final muted = (isDark ? Colors.white : Colors.black).withValues(alpha: 0.5);
    final card = isDark ? Colors.white.withValues(alpha: 0.03) : Colors.white;
    final border = isDark
        ? Colors.white.withValues(alpha: 0.08)
        : Colors.black.withValues(alpha: 0.06);

    final resultsAsync = ref.watch(searchResultsProvider(_query));
    final apiClient = ref.read(apiClientProvider);
    final count = resultsAsync.maybeWhen(data: (d) => d.length, orElse: () => 0);

    final summaryTags = [..._query.locations, ..._query.budgets, ..._query.types];

    return Scaffold(
      backgroundColor: bg,
      body: SafeArea(
        bottom: false,
        child: Column(
          children: [
            // ── Sticky Header ──────────────────────────────────────────────
            ClipRect(
              child: BackdropFilter(
                filter: ImageFilter.blur(sigmaX: 12, sigmaY: 12),
                child: Container(
                  decoration: BoxDecoration(
                    color: bg.withValues(alpha: 0.8),
                    border: Border(bottom: BorderSide(color: border)),
                  ),
                  padding: const EdgeInsets.fromLTRB(20, 16, 24, 16),
                  child: Row(
                    children: [
                      _PressableScale(
                        onTap: _goBack,
                        child: Container(
                          width: 48,
                          height: 48,
                          decoration: BoxDecoration(
                            color: card,
                            borderRadius: BorderRadius.circular(16),
                            border: Border.all(color: border),
                          ),
                          child: Icon(LucideIcons.arrowLeft,
                              color: textPrimary, size: 22),
                        ),
                      ),
                      const SizedBox(width: 16),
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          mainAxisSize: MainAxisSize.min,
                          children: [
                            Text(
                              'SEARCH RESULTS',
                              style: GoogleFonts.montserrat(
                                fontSize: 22,
                                fontWeight: FontWeight.w900,
                                color: textPrimary,
                                letterSpacing: -0.5,
                              ),
                            ),
                            const SizedBox(height: 4),
                            Text(
                              'FOUND $count PROPERTIES',
                              style: GoogleFonts.montserrat(
                                fontSize: 10,
                                fontWeight: FontWeight.w900,
                                color: muted,
                                letterSpacing: 4,
                              ),
                            ),
                          ],
                        ),
                      ),
                    ],
                  ),
                ),
              ),
            ),

            // ── Body ───────────────────────────────────────────────────────
            Expanded(
              child: ListView(
                padding: const EdgeInsets.fromLTRB(24, 24, 24, 120),
                children: [
                  // ── Filter summary badges ──────────────────────────────
                  if (_query.query.isNotEmpty ||
                      _query.status.isNotEmpty ||
                      summaryTags.isNotEmpty) ...[
                    Wrap(
                      spacing: 10,
                      runSpacing: 10,
                      children: [
                        if (_query.query.isNotEmpty)
                          _FilterBadge(
                            text: 'QUERY: ${_query.query}',
                            background: textPrimary,
                            foreground: bg,
                            border: textPrimary,
                          ),
                        if (_query.status.isNotEmpty)
                          _FilterBadge(
                            text: _query.status,
                            background: const Color(0xFFF59E0B),
                            foreground: Colors.black,
                            border: const Color(0xFFF59E0B),
                          ),
                        ...summaryTags.map((tag) => _FilterBadge(
                              text: tag,
                              background: card,
                              foreground: muted,
                              border: border,
                            )),
                      ],
                    ),
                    const SizedBox(height: 32),
                  ],

                  // ── Loading / Results / Empty ──────────────────────────
                  resultsAsync.when(
                    loading: () => _LoadingSkeletons(card: card, border: border),
                    error: (e, s) => _EmptyState(
                      textPrimary: textPrimary,
                      muted: muted,
                      border: border,
                      onChangeFilters: () => context.go('/home'),
                    ),
                    data: (results) {
                      if (results.isEmpty) {
                        return _EmptyState(
                          textPrimary: textPrimary,
                          muted: muted,
                          border: border,
                          onChangeFilters: () => context.go('/home'),
                        );
                      }
                      return Column(
                        children: [
                          for (int i = 0; i < results.length; i++) ...[
                            _ResultCard(
                              project: results[i],
                              apiClient: apiClient,
                              textPrimary: textPrimary,
                              muted: muted,
                              border: border,
                              onTap: () => _openProject(context, results[i]),
                            )
                                .animate()
                                .fadeIn(
                                    duration: 400.ms,
                                    delay: (i * 100).ms)
                                .moveY(
                                    begin: 20,
                                    end: 0,
                                    duration: 400.ms,
                                    delay: (i * 100).ms,
                                    curve: Curves.easeOut),
                            if (i != results.length - 1)
                              const SizedBox(height: 24),
                          ],
                        ],
                      );
                    },
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
}

// ── Filter summary badge ──────────────────────────────────────────────────
class _FilterBadge extends StatelessWidget {
  const _FilterBadge({
    required this.text,
    required this.background,
    required this.foreground,
    required this.border,
  });

  final String text;
  final Color background;
  final Color foreground;
  final Color border;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 9),
      decoration: BoxDecoration(
        color: background,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: border),
      ),
      child: Text(
        text.toUpperCase(),
        style: GoogleFonts.montserrat(
          fontSize: 10,
          fontWeight: FontWeight.w900,
          color: foreground,
          letterSpacing: 1.5,
        ),
      ),
    );
  }
}

// ── Loading skeletons (3x h-64 pulse cards) ───────────────────────────────
class _LoadingSkeletons extends StatelessWidget {
  const _LoadingSkeletons({required this.card, required this.border});

  final Color card;
  final Color border;

  @override
  Widget build(BuildContext context) {
    // Neutral institutional accent (kept for parity with M4 design language).
    const accent = M4Theme.premiumBlue;
    return Column(
      children: List.generate(3, (i) {
        return Padding(
          padding: EdgeInsets.only(bottom: i == 2 ? 0 : 24),
          child: Container(
            height: 256,
            decoration: BoxDecoration(
              color: Color.alphaBlend(accent.withValues(alpha: 0.02), card),
              borderRadius: BorderRadius.circular(32),
              border: Border.all(color: border),
            ),
          )
              .animate(onPlay: (c) => c.repeat(reverse: true))
              .fadeIn(duration: 700.ms)
              .then()
              .fade(begin: 1, end: 0.4, duration: 700.ms),
        );
      }),
    );
  }
}

// ── Result card ───────────────────────────────────────────────────────────
class _ResultCard extends StatelessWidget {
  const _ResultCard({
    required this.project,
    required this.apiClient,
    required this.textPrimary,
    required this.muted,
    required this.border,
    required this.onTap,
  });

  final dynamic project;
  final ApiClient apiClient;
  final Color textPrimary;
  final Color muted;
  final Color border;
  final VoidCallback onTap;

  String _resolveImage() {
    final images = project['images'] as List?;
    final heroImages = project['heroImages'] as List?;
    final raw = project['heroImage']?.toString() ??
        ((heroImages != null && heroImages.isNotEmpty)
            ? heroImages[0].toString()
            : null) ??
        ((images != null && images.isNotEmpty) ? images[0].toString() : null);
    return apiClient.resolveUrl(raw);
  }

  @override
  Widget build(BuildContext context) {
    final imageUrl = _resolveImage();
    final title = project['title']?.toString() ?? 'M4 PROJECT';
    final status = project['status']?.toString() ?? '';
    final locationFull = project['location']?['name']?.toString() ?? '';
    final locationShort =
        locationFull.split(',').first.trim().isEmpty ? 'N/A' : locationFull.split(',').first.trim();
    final startingPrice = project['startingPrice']?.toString() ?? '';
    final showPrice =
        startingPrice.isNotEmpty && !startingPrice.toLowerCase().contains('request');

    return _PressableScale(
      onTap: onTap,
      child: Container(
        height: 280,
        clipBehavior: Clip.antiAlias,
        decoration: BoxDecoration(
          borderRadius: BorderRadius.circular(32),
          border: Border.all(color: border),
          boxShadow: [
            BoxShadow(
              color: Colors.black.withValues(alpha: 0.25),
              blurRadius: 24,
              offset: const Offset(0, 12),
            ),
          ],
        ),
        child: Stack(
          fit: StackFit.expand,
          children: [
            CachedNetworkImage(
              imageUrl: imageUrl,
              fit: BoxFit.cover,
              placeholder: (context, url) =>
                  Container(color: Colors.black.withValues(alpha: 0.1)),
              errorWidget: (context, url, error) => Container(
                color: Colors.black.withValues(alpha: 0.2),
                child: const Icon(LucideIcons.image, color: Colors.white38),
              ),
            ),
            // Gradient overlay: from-black/95 via-black/20 to-transparent
            Container(
              decoration: BoxDecoration(
                gradient: LinearGradient(
                  begin: Alignment.bottomCenter,
                  end: Alignment.topCenter,
                  colors: [
                    Colors.black.withValues(alpha: 0.95),
                    Colors.black.withValues(alpha: 0.20),
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
                child: ClipRRect(
                  borderRadius: BorderRadius.circular(8),
                  child: BackdropFilter(
                    filter: ImageFilter.blur(sigmaX: 12, sigmaY: 12),
                    child: Container(
                      padding: const EdgeInsets.symmetric(
                          horizontal: 16, vertical: 6),
                      decoration: BoxDecoration(
                        color: Colors.white.withValues(alpha: 0.15),
                        borderRadius: BorderRadius.circular(8),
                        border: Border.all(
                            color: Colors.white.withValues(alpha: 0.2)),
                      ),
                      child: Text(
                        status.toUpperCase(),
                        style: GoogleFonts.montserrat(
                          fontSize: 9,
                          fontWeight: FontWeight.w900,
                          color: Colors.white,
                          letterSpacing: 1.5,
                        ),
                      ),
                    ),
                  ),
                ),
              ),

            // Bottom content
            Positioned(
              left: 0,
              right: 0,
              bottom: 0,
              child: Padding(
                padding: const EdgeInsets.all(28),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Text(
                      title.toUpperCase(),
                      maxLines: 2,
                      overflow: TextOverflow.ellipsis,
                      style: GoogleFonts.montserrat(
                        fontSize: 20,
                        fontWeight: FontWeight.w900,
                        color: Colors.white,
                        letterSpacing: -0.5,
                      ),
                    ),
                    const SizedBox(height: 6),
                    Row(
                      crossAxisAlignment: CrossAxisAlignment.center,
                      children: [
                        Expanded(
                          child: Row(
                            children: [
                              Icon(LucideIcons.mapPin,
                                  size: 14,
                                  color: Colors.white.withValues(alpha: 0.7)),
                              const SizedBox(width: 6),
                              Expanded(
                                child: Text(
                                  locationShort.toUpperCase(),
                                  maxLines: 1,
                                  overflow: TextOverflow.ellipsis,
                                  style: GoogleFonts.montserrat(
                                    fontSize: 9,
                                    fontWeight: FontWeight.w900,
                                    color: Colors.white.withValues(alpha: 0.7),
                                    letterSpacing: 1.5,
                                  ),
                                ),
                              ),
                            ],
                          ),
                        ),
                        if (showPrice) ...[
                          const SizedBox(width: 12),
                          ClipRRect(
                            borderRadius: BorderRadius.circular(12),
                            child: BackdropFilter(
                              filter:
                                  ImageFilter.blur(sigmaX: 12, sigmaY: 12),
                              child: Container(
                                padding: const EdgeInsets.symmetric(
                                    horizontal: 16, vertical: 8),
                                decoration: BoxDecoration(
                                  color: Colors.white.withValues(alpha: 0.12),
                                  borderRadius: BorderRadius.circular(12),
                                  border: Border.all(
                                      color: Colors.white
                                          .withValues(alpha: 0.2)),
                                ),
                                child: Text(
                                  startingPrice,
                                  style: GoogleFonts.montserrat(
                                    fontSize: 18,
                                    fontWeight: FontWeight.w900,
                                    fontStyle: FontStyle.italic,
                                    color: Colors.white,
                                    letterSpacing: -0.5,
                                  ),
                                ),
                              ),
                            ),
                          ),
                        ],
                      ],
                    ),
                  ],
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}

// ── Empty state ───────────────────────────────────────────────────────────
class _EmptyState extends StatelessWidget {
  const _EmptyState({
    required this.textPrimary,
    required this.muted,
    required this.border,
    required this.onChangeFilters,
  });

  final Color textPrimary;
  final Color muted;
  final Color border;
  final VoidCallback onChangeFilters;

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 80),
      child: Column(
        children: [
          ClipRRect(
            borderRadius: BorderRadius.circular(32),
            child: BackdropFilter(
              filter: ImageFilter.blur(sigmaX: 8, sigmaY: 8),
              child: Container(
                width: 128,
                height: 128,
                decoration: BoxDecoration(
                  color: textPrimary.withValues(alpha: 0.03),
                  borderRadius: BorderRadius.circular(32),
                  border: Border.all(color: border),
                ),
                child: Icon(
                  LucideIcons.search,
                  size: 48,
                  color: muted.withValues(alpha: 0.6),
                ),
              ),
            ),
          ),
          const SizedBox(height: 32),
          Text(
            'NO MATCHES',
            style: GoogleFonts.montserrat(
              fontSize: 22,
              fontWeight: FontWeight.w900,
              color: textPrimary,
              letterSpacing: -0.5,
            ),
          ),
          const SizedBox(height: 12),
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 24),
            child: Text(
              'TRY ADJUSTING YOUR FILTERS TO FIND MORE PROPERTIES.',
              textAlign: TextAlign.center,
              style: GoogleFonts.montserrat(
                fontSize: 9,
                fontWeight: FontWeight.w900,
                color: muted,
                letterSpacing: 3.6,
                height: 1.8,
              ),
            ),
          ),
          const SizedBox(height: 32),
          _PressableScale(
            onTap: onChangeFilters,
            child: Container(
              height: 56,
              padding: const EdgeInsets.symmetric(horizontal: 48),
              alignment: Alignment.center,
              decoration: BoxDecoration(
                color: textPrimary.withValues(alpha: 0.03),
                borderRadius: BorderRadius.circular(12),
                border: Border.all(color: border),
              ),
              child: Text(
                'CHANGE FILTERS',
                style: GoogleFonts.montserrat(
                  fontSize: 10,
                  fontWeight: FontWeight.w900,
                  color: textPrimary,
                  letterSpacing: 1.5,
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }
}

// ── Press feedback wrapper ────────────────────────────────────────────────
class _PressableScale extends StatefulWidget {
  const _PressableScale({required this.child, required this.onTap});

  final Widget child;
  final VoidCallback onTap;

  @override
  State<_PressableScale> createState() => _PressableScaleState();
}

class _PressableScaleState extends State<_PressableScale> {
  bool _pressed = false;

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTapDown: (_) => setState(() => _pressed = true),
      onTapUp: (_) => setState(() => _pressed = false),
      onTapCancel: () => setState(() => _pressed = false),
      onTap: widget.onTap,
      child: AnimatedScale(
        scale: _pressed ? 0.96 : 1.0,
        duration: const Duration(milliseconds: 120),
        child: widget.child,
      ),
    );
  }
}
