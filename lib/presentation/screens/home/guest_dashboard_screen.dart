import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:m4_mobile/core/theme/app_theme.dart';
import 'package:flutter_animate/flutter_animate.dart';
import 'package:lucide_icons/lucide_icons.dart';
import 'package:google_fonts/google_fonts.dart';
import 'dart:ui';
import 'dart:convert';
import 'dart:typed_data';
import 'package:m4_mobile/presentation/widgets/guest_sidebar_menu.dart';
import 'package:m4_mobile/core/network/api_client.dart';
import 'package:m4_mobile/presentation/providers/auth_provider.dart';
import 'package:flutter_secure_storage/flutter_secure_storage.dart';
import 'package:m4_mobile/presentation/screens/projects/guest_project_detail_screen.dart';
import 'package:m4_mobile/presentation/screens/projects/project_list_screen.dart';
import 'package:m4_mobile/presentation/screens/communities/community_detail_screen.dart';
import 'package:m4_mobile/presentation/screens/communities/community_list_screen.dart';
import 'dart:async';
import 'package:go_router/go_router.dart';
import 'package:url_launcher/url_launcher.dart';
import 'package:cached_network_image/cached_network_image.dart';

/// Decoded base64 image bytes, keyed by the raw `data:` URI, so each image is
/// decoded once (not on every rebuild/hero-cycle) — keeps the UI responsive.
final Map<String, Uint8List> _base64Cache = {};

/// Caches the last-loaded guest home payload so the dashboard renders
/// instantly on repeat mounts (e.g. right after logout) instead of blocking
/// on a fresh network fetch. It still refreshes in the background each mount.
class GuestHomeData {
  final List<dynamic> projects;
  final List<dynamic> communities;
  final List<dynamic> media;
  const GuestHomeData({
    required this.projects,
    required this.communities,
    required this.media,
  });
}

final guestHomeCacheProvider = StateProvider<GuestHomeData?>((ref) => null);

/// Placeholder media cards shown when the backend returns no media, so the
/// Media tab isn't blank. (Unchanged content — only lifted out of the fetch
/// method so both the fetch and the prefetch-skip path can reuse it.)
const List<Map<String, dynamic>> _dummyMedia = [
  {
    '_id': 'dummy1',
    'title': 'CLÉDOR LUXURY LIVING',
    'thumbnail':
        'https://images.unsplash.com/photo-1600210492486-724fe5c67fb0?auto=format&fit=crop&q=80',
    'description':
        'Discover the epitome of refinement in our latest architectural masterpiece.',
    'slug': 'cledor-luxury-living',
  },
  {
    '_id': 'dummy2',
    'title': 'OCEAN VIEW RESIDENCES',
    'thumbnail':
        'https://images.unsplash.com/photo-1512917774080-9991f1c4c750?auto=format&fit=crop&q=80',
    'description':
        'Where horizon meets home. Experience coastal elegance like never before.',
    'slug': 'ocean-view-residences',
  },
  {
    '_id': 'dummy3',
    'title': 'URBAN SANCTUARY',
    'thumbnail':
        'https://images.unsplash.com/photo-1484154218962-a197022b5858?auto=format&fit=crop&q=80',
    'description': 'A peaceful retreat in the heart of the city.',
    'slug': 'urban-sanctuary',
  },
];

/// When the guest catalog was last warmed by [prefetchGuestHome]. Lets the
/// dashboard skip its immediate refetch right after launch (the data is already
/// fresh), so prefetching costs no extra API calls overall.
final guestPrefetchAtProvider = StateProvider<DateTime?>((ref) => null);

/// Warms the guest-home catalog cache in the background — e.g. during the
/// onboarding splash animation — so the guest home renders with data instantly
/// instead of showing a spinner. Fires the same three catalog requests in
/// parallel, mirrors the dashboard's parse logic, and is a no-op on error.
/// Skipped for signed-in users (they land on their own portal, not the guest
/// home), so it never adds wasted calls.
Future<void> prefetchGuestHome(WidgetRef ref) async {
  if (ref.read(guestHomeCacheProvider) != null) return;
  try {
    const storage = FlutterSecureStorage();
    final token = await storage.read(key: 'jwt_token');
    if (token != null && token.isNotEmpty) return; // signed in → not guest home

    final api = ref.read(apiClientProvider);
    List<dynamic> pick(dynamic res) {
      final d = res.data;
      if (d is Map && d['data'] is List) return d['data'] as List;
      if (d is List) return d;
      return [];
    }
    Future<List<dynamic>> safe(Future Function() call) async {
      try {
        return pick(await call());
      } catch (_) {
        return [];
      }
    }

    final results = await Future.wait([
      safe(api.getProjects),
      safe(api.getCommunities),
      safe(() => api.getContent('media')),
    ]);
    if (results.every((r) => r.isEmpty)) return;
    ref.read(guestHomeCacheProvider.notifier).state = GuestHomeData(
      projects: results[0],
      communities: results[1],
      media: results[2],
    );
    ref.read(guestPrefetchAtProvider.notifier).state = DateTime.now();
  } catch (_) {}
}

class GuestDashboardScreen extends ConsumerStatefulWidget {
  const GuestDashboardScreen({super.key});

  @override
  ConsumerState<GuestDashboardScreen> createState() =>
      _GuestDashboardScreenState();
}

class _GuestDashboardScreenState extends ConsumerState<GuestDashboardScreen> {
  final ScrollController _scrollController = ScrollController();
  final GlobalKey _interestFormKey = GlobalKey();
  final GlobalKey<ScaffoldState> _scaffoldKey = GlobalKey<ScaffoldState>();

  int _heroIndex = 0;
  List<dynamic> _projects = [];
  List<dynamic> _communities = [];
  List<dynamic> _media = [];
  bool _loading = true;
  String _activeTab = 'Communities';
  int _featuredIndex = 0;

  // 📝 Interest Form Controllers
  final TextEditingController _nameController = TextEditingController();
  final TextEditingController _emailController = TextEditingController();
  final TextEditingController _phoneController = TextEditingController();
  final TextEditingController _messageController = TextEditingController();
  bool _submitting = false;
  bool _agreedToTerms = false;

  Timer? _heroTimer;

  @override
  void initState() {
    super.initState();
    // Show cached content instantly if we've loaded before (e.g. after
    // logout), then refresh in the background — no blocking spinner.
    final cached = ref.read(guestHomeCacheProvider);
    if (cached != null) {
      _projects = cached.projects;
      _communities = cached.communities;
      _media = cached.media;
      _loading = false;
    }
    // If the onboarding prefetch just warmed the catalog (< 15s ago), the data
    // is already fresh — skip the redundant immediate refetch so prefetching
    // adds no extra network calls. Any later visit refreshes as before.
    final prefetchAt = ref.read(guestPrefetchAtProvider);
    final justPrefetched = cached != null &&
        prefetchAt != null &&
        DateTime.now().difference(prefetchAt).inSeconds < 15;
    if (justPrefetched) {
      // Media dummies are normally added by _fetchData; ensure they're present
      // when we skip it so the media tab isn't empty on first paint.
      if (_media.isEmpty) _media = _dummyMedia;
    } else {
      _fetchData();
    }
    _heroTimer = Timer.periodic(const Duration(seconds: 3), (timer) {
      if (mounted && _projects.isNotEmpty) {
        setState(
          () => _heroIndex =
              (_heroIndex + 1) % (_projects.length > 5 ? 5 : _projects.length),
        );
      }
    });
  }

  @override
  void dispose() {
    _scrollController.dispose();
    _nameController.dispose();
    _emailController.dispose();
    _phoneController.dispose();
    _messageController.dispose();
    _heroTimer?.cancel();
    super.dispose();
  }

  // Fetch one catalog list, returning [] on any error instead of throwing —
  // so a single slow/failed request can't wipe out the others.
  Future<List<dynamic>> _safeList(
    Future Function() call, {
    int retries = 2,
  }) async {
    for (int attempt = 0; attempt <= retries; attempt++) {
      try {
        final res = await call();
        final data = res.data;
        if (data is Map && data['data'] is List) return data['data'] as List;
        if (data is List) return data;
        return [];
      } catch (_) {
        // Transient connection/DNS blips are common on mobile; retry with a
        // short backoff so a single failed request doesn't leave the section
        // permanently empty until the user reloads.
        if (attempt == retries) return [];
        await Future.delayed(Duration(milliseconds: 700 * (attempt + 1)));
      }
    }
    return [];
  }

  Future<void> _fetchData() async {
    try {
      final apiClient = ref.read(apiClientProvider);
      // Independent requests: previously a single Future.wait meant that if
      // ANY one of projects/communities/media failed or timed out, all three
      // came back empty — which is why Communities showed nothing on slower
      // connections. Now each populates on its own.
      // All three still start in parallel (fastest total time), but we reveal
      // the page as soon as PROJECTS arrive (they drive the hero + featured
      // sections) instead of blocking the whole screen on the slowest request —
      // communities/media then stream into their tabs a moment later.
      final projectsFuture = _safeList(apiClient.getProjects);
      final communitiesFuture = _safeList(apiClient.getCommunities);
      final mediaFuture = _safeList(() => apiClient.getContent('media'));

      unawaited(
        projectsFuture.then((projects) {
          if (mounted && projects.isNotEmpty) {
            setState(() {
              _projects = projects;
              _loading = false;
            });
          }
        }),
      );

      final results = await Future.wait([
        projectsFuture,
        communitiesFuture,
        mediaFuture,
      ]);

      if (mounted) {
        setState(() {
          // Keep the last good data if a refresh comes back empty (e.g. a
          // dropped/failed request) instead of blanking a section that
          // previously had content.
          if (results[0].isNotEmpty) _projects = results[0];
          if (results[1].isNotEmpty) _communities = results[1];
          if (results[2].isNotEmpty) _media = results[2];

          // 💡 Add dummy content if media is empty to fill blank space
          if (_media.isEmpty) {
            _media = _dummyMedia;
          }
          _loading = false;
        });
        // Cache the fresh payload so the next guest-home mount is instant.
        // Only cache when we actually have content, so a failed/offline load
        // never poisons the cache with an empty payload that would then show
        // empty on the next open.
        if (_projects.isNotEmpty ||
            _communities.isNotEmpty ||
            _media.isNotEmpty) {
          ref.read(guestHomeCacheProvider.notifier).state = GuestHomeData(
            projects: _projects,
            communities: _communities,
            media: _media,
          );
        }
      }
    } catch (e) {
      if (mounted) setState(() => _loading = false);
    }
  }

  void _scrollToInterestForm() {
    final context = _interestFormKey.currentContext;
    if (context != null) {
      Scrollable.ensureVisible(
        context,
        duration: const Duration(seconds: 1),
        curve: Curves.easeInOut,
      );
    }
  }

  Future<void> _submitInterest() async {
    if (_nameController.text.isEmpty ||
        _emailController.text.isEmpty ||
        _phoneController.text.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Please fill all required fields (*)')),
      );
      return;
    }
    if (!_agreedToTerms) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Please agree to the Privacy Policy')),
      );
      return;
    }

    setState(() => _submitting = true);
    try {
      final apiClient = ref.read(apiClientProvider);
      await apiClient.submitLead({
        'name': _nameController.text,
        'email': _emailController.text,
        'phone': _phoneController.text,
        'message': _messageController.text,
        'interest': 'Guest Interest',
        'source': 'Mobile Guest Portal',
      });

      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('Interest registered successfully!'),
            backgroundColor: Colors.green,
          ),
        );
        _nameController.clear();
        _emailController.clear();
        _phoneController.clear();
        _messageController.clear();
        setState(() => _agreedToTerms = false);
      }
    } catch (e) {
      ScaffoldMessenger.of(
        context,
      ).showSnackBar(SnackBar(content: Text('Submission failed: $e')));
    } finally {
      if (mounted) setState(() => _submitting = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    if (_loading)
      return Material(
        color: Theme.of(context).scaffoldBackgroundColor,
        child: Center(
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              SizedBox(
                width: 34,
                height: 34,
                child: CircularProgressIndicator(
                  color: M4Theme.premiumBlue,
                  strokeWidth: 2.5,
                ),
              ),
              const SizedBox(height: 18),
              Text(
                'M4 FAMILY',
                style: GoogleFonts.gelasio(
                  fontSize: 11,
                  fontWeight: FontWeight.w900,
                  letterSpacing: 5,
                  color: Theme.of(
                    context,
                  ).colorScheme.onSurface.withValues(alpha: 0.55),
                ),
              ),
            ],
          ),
        ),
      );

    return Material(
      color: Theme.of(context).scaffoldBackgroundColor,
      child: CustomScrollView(
        controller: _scrollController,
        slivers: [
          // ⭐️ FIXED HEADER (Web Parity)
          SliverAppBar(
            pinned: true,
            toolbarHeight: 120,
            backgroundColor: Theme.of(
              context,
            ).scaffoldBackgroundColor.withOpacity(0.9),
            automaticallyImplyLeading: false,
            elevation: 0,
            titleSpacing: 0,
            title: Padding(
              padding: const EdgeInsets.symmetric(horizontal: 24),
              child: Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  ColorFiltered(
                    colorFilter: ColorFilter.matrix(
                      Theme.of(context).brightness == Brightness.dark
                          ? const [
                              // Invert logo for dark mode
                              -1, 0, 0, 0, 255,
                              0, -1, 0, 0, 255,
                              0, 0, -1, 0, 255,
                              0, 0, 0, 1, 0,
                            ]
                          : const [
                              // Identity matrix for light mode
                              1, 0, 0, 0, 0,
                              0, 1, 0, 0, 0,
                              0, 0, 1, 0, 0,
                              0, 0, 0, 1, 0,
                            ],
                    ),
                    child: Image.asset(
                      'assets/m4_family_logo.png',
                      height: 85, // 👈 Reduced for better balance
                      fit: BoxFit.contain,
                    ),
                  ),
                  Builder(
                    builder: (context) => GestureDetector(
                      onTap: () => Scaffold.of(context).openDrawer(),
                      child: Container(
                        width: 56,
                        height: 36,
                        decoration: BoxDecoration(
                          color: Colors.transparent,
                          borderRadius: BorderRadius.circular(14),
                        ),
                        child: Icon(
                          LucideIcons.menu,
                          color: Theme.of(context).colorScheme.onSurface,
                          size: 24,
                        ),
                      ),
                    ),
                  ),
                ],
              ),
            ),
          ),

          // ⭐️ TAGLINE & HERO SECTION
          SliverToBoxAdapter(
            child: Padding(
              padding: const EdgeInsets.fromLTRB(0, 0, 0, 0),
              // The tagline + hero image are painted upward via Transform, but
              // still reserve their full height. heightFactor trims the empty
              // reserved space at the bottom so the tabs sit closer (no big gap).
              child: Align(
                alignment: Alignment.topCenter,
                heightFactor: 0.82,
                child: Column(
                crossAxisAlignment: CrossAxisAlignment.center,
                children: [
                  // ⭐️ Tagline (Living the M4 Life)
                  Transform.translate(
                    offset: const Offset(0, -50),
                    child: Padding(
                      padding: const EdgeInsets.symmetric(vertical: 0),
                      child: M4Theme.taglineWordmark(context, height: 200),
                    ),
                  ),

                  // Hero Image Container
                  Transform.translate(
                    offset: const Offset(
                      0,
                      -110,
                    ), // 👈 Adjusted from -140 to fix overlap
                    child: Padding(
                      padding: const EdgeInsets.symmetric(horizontal: 24),
                      child: Builder(
                        builder: (context) {
                          final mainImage = _projects.isNotEmpty
                              ? (_projects[_heroIndex %
                                        _projects.length]['heroImage'] ??
                                    _projects[_heroIndex %
                                        _projects.length]['image'] ??
                                    'https://images.unsplash.com/photo-1545324418-cc1a3fa10c00?auto=format&fit=crop&q=80')
                              : [
                                  'https://images.unsplash.com/photo-1545324418-cc1a3fa10c00?auto=format&fit=crop&q=80',
                                  'https://images.unsplash.com/photo-1512917774080-9991f1c4c750?auto=format&fit=crop&q=80',
                                  'https://images.unsplash.com/photo-1484154218962-a197022b5858?auto=format&fit=crop&q=80',
                                ][_heroIndex % 3];

                          return Stack(
                            children: [
                              AspectRatio(
                                aspectRatio: 4 / 3,
                                child: Container(
                                  decoration: BoxDecoration(
                                    borderRadius: BorderRadius.circular(32),
                                  ),
                                  child: ClipRRect(
                                    borderRadius: BorderRadius.circular(32),
                                    child: AnimatedSwitcher(
                                      duration: const Duration(
                                        milliseconds: 800,
                                      ),
                                      transitionBuilder:
                                          (
                                            Widget child,
                                            Animation<double> animation,
                                          ) {
                                            return FadeTransition(
                                              opacity: animation,
                                              child: child,
                                            );
                                          },
                                      child: _buildProjectImage(
                                        mainImage.toString(),
                                        key: ValueKey<int>(_heroIndex),
                                        width: double.infinity,
                                        height: double.infinity,
                                        errorIcon: LucideIcons.image,
                                        errorIconSize: 50,
                                      ),
                                    ),
                                  ),
                                ),
                              ),

                              // Artistic Impression Badge
                              Positioned(
                                top: 16,
                                right: 16,
                                child: Container(
                                  padding: const EdgeInsets.symmetric(
                                    horizontal: 8,
                                    vertical: 4,
                                  ),
                                  decoration: BoxDecoration(
                                    color: Colors.black.withOpacity(0.4),
                                    borderRadius: BorderRadius.circular(4),
                                    border: Border.all(
                                      color: Colors.white.withOpacity(0.1),
                                    ),
                                  ),
                                  child: Text(
                                    'ARTISTIC IMPRESSION',
                                    style: GoogleFonts.gelasio(
                                      color: Colors.white,
                                      fontSize: 7,
                                      fontWeight: FontWeight.w900,
                                      letterSpacing: 1.5,
                                    ),
                                  ),
                                ),
                              ),

                              // Pagination Dots
                              Positioned(
                                bottom: 24,
                                left: 0,
                                right: 0,
                                child: Row(
                                  mainAxisAlignment: MainAxisAlignment.center,
                                  children: List.generate(3, (index) {
                                    final isSelected =
                                        (_heroIndex % 3) == index;
                                    return AnimatedContainer(
                                      duration: const Duration(
                                        milliseconds: 300,
                                      ),
                                      margin: const EdgeInsets.symmetric(
                                        horizontal: 4,
                                      ),
                                      width: isSelected ? 32 : 24,
                                      height: 4,
                                      decoration: BoxDecoration(
                                        color: isSelected
                                            ? Colors.black
                                            : Colors.white.withValues(
                                                alpha: 0.5,
                                              ),
                                        borderRadius: BorderRadius.circular(2),
                                      ),
                                    );
                                  }),
                                ),
                              ),
                            ],
                          );
                        },
                      ),
                    ),
                  ),
                ],
              ),
              ),
            ),
          ),
          SliverPadding(
            padding: const EdgeInsets.only(bottom: 32),
            sliver: SliverList(
              delegate: SliverChildListDelegate([
                // Pull the tabs up under the hero, but keep them tappable: the
                // internal SizedBox keeps the tab bar inside the sliver item's
                // layout bounds so hit-testing lands correctly (a bare
                // Transform on a sliver child shifts paint but not hit-tests).
                Transform.translate(
                  offset: const Offset(0, -60),
                  child: Padding(
                    padding: const EdgeInsets.symmetric(horizontal: 24),
                    child: Column(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        const SizedBox(height: 60),
                        _buildTabsSection(),
                      ],
                    ),
                  ),
                ),
                Padding(
                  padding: const EdgeInsets.symmetric(horizontal: 24),
                  child: _buildPhilosophy(),
                ),
                const SizedBox(height: 40),
                _buildFeaturedSection(),
                const SizedBox(height: 40),
                Padding(
                  padding: const EdgeInsets.symmetric(horizontal: 24),
                  child: _buildConnectGrid(),
                ),
                const SizedBox(height: 40),
                Padding(
                  padding: const EdgeInsets.symmetric(horizontal: 24),
                  child: _buildInterestForm(),
                ),
                const SizedBox(height: 120),
              ]),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildPhilosophy() {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          'OUR PHILOSOPHY',
          style: GoogleFonts.gelasio(
            fontSize: 32,
            fontWeight: FontWeight.w400,
            color: Theme.of(context).colorScheme.onSurface,
            letterSpacing: -0.5,
          ),
        ),
        const SizedBox(height: 24),
        RichText(
          text: TextSpan(
            style: GoogleFonts.ebGaramond(
              color: Theme.of(context).colorScheme.onSurface.withOpacity(0.6),
              fontSize: 14,
              height: 1.8,
            ),
            children: [
              const TextSpan(
                text:
                    'To redefine modern luxury living by crafting homes with cutting edge design, enduring quality and thoughtful amenities delivered with trust, transparency, timeliness, and a human touch that creates lasting value for every homeowner. ',
              ),
              WidgetSpan(
                child: GestureDetector(
                  onTap: () => context.push('/about'),
                  child: Text(
                    'Who We Are',
                    style: GoogleFonts.ebGaramond(
                      color: isDark ? Colors.white : Colors.black,
                      fontWeight: FontWeight.bold,
                      decoration: TextDecoration.underline,
                    ),
                  ),
                ),
              ),
            ],
          ),
        ),
      ],
    );
  }

  Widget _buildTabsSection() {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    return Column(
      children: [
        Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          crossAxisAlignment: CrossAxisAlignment.baseline,
          textBaseline: TextBaseline.alphabetic,
          children: [
            Expanded(
              child: SingleChildScrollView(
                scrollDirection: Axis.horizontal,
                physics: const BouncingScrollPhysics(),
                child: Row(
                  children: ['communities', 'properties', 'media'].map((tab) {
                    final isSelected = _activeTab.toLowerCase() == tab;
                    return GestureDetector(
                      // Make the whole tab (incl. padding) tappable, not just
                      // the exact text pixels — fixes hard-to-tap tabs.
                      behavior: HitTestBehavior.opaque,
                      onTap: () => setState(
                        () => _activeTab =
                            tab[0].toUpperCase() + tab.substring(1),
                      ),
                      child: Padding(
                        padding: const EdgeInsets.only(right: 24),
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(
                              tab.toUpperCase(),
                              style: GoogleFonts.gelasio(
                                color: isSelected
                                    ? (isDark ? Colors.white : Colors.black)
                                    : (isDark ? Colors.white : Colors.black)
                                          .withValues(alpha: 0.68),
                                fontSize: 12,
                                fontWeight: FontWeight.w900,
                                letterSpacing: 2,
                              ),
                            ),
                            const SizedBox(height: 10),
                            if (isSelected)
                              Container(
                                width: 24,
                                height: 2,
                                decoration: BoxDecoration(
                                  color: isDark ? Colors.white : Colors.black,
                                  borderRadius: BorderRadius.circular(1),
                                ),
                              ),
                          ],
                        ),
                      ),
                    );
                  }).toList(),
                ),
              ),
            ),
          ],
        ),
        const SizedBox(height: 32),
        Builder(
          builder: (context) {
            final List<dynamic> items = _activeTab == 'Communities'
                ? _communities
                : (_activeTab == 'Media' ? _media : _projects);
            // While the payload is still loading, show a spinner instead of a
            // blank 360px gap (which looked like nothing was there); once
            // loaded, show a subtle message if the list is genuinely empty.
            if (items.isEmpty) {
              return SizedBox(
                height: 360,
                child: Center(
                  child: _loading
                      ? const CircularProgressIndicator(
                          color: Color(0xFFC5A35B),
                          strokeWidth: 2,
                        )
                      : Text(
                          'No ${_activeTab.toLowerCase()} available yet.',
                          style: GoogleFonts.ebGaramond(
                            color: Colors.white.withOpacity(0.6),
                            fontSize: 13,
                          ),
                        ),
                ),
              );
            }
            return SizedBox(
              height: 360,
              child: ListView.builder(
                scrollDirection: Axis.horizontal,
                physics: const BouncingScrollPhysics(),
                itemCount: items.length,
                itemBuilder: (context, index) => _buildTabCard(items[index]),
              ),
            );
          },
        ),
      ],
    );
  }

  Widget _buildTabCard(dynamic item) {
    final isCommunity = _activeTab.toLowerCase() == 'communities';
    final isMedia = _activeTab.toLowerCase() == 'media';
    final rawImage =
        (isCommunity
                ? (item['image'] ??
                      'https://images.unsplash.com/photo-1486406146926-c627a92ad1ab?auto=format&fit=crop&q=80')
                : (isMedia
                      ? ((item['thumbnail']?.toString().isNotEmpty ?? false)
                            ? item['thumbnail']
                            : (item['image']?.toString().isNotEmpty ?? false)
                            ? item['image']
                            : 'https://images.unsplash.com/photo-1556761175-b413da4baf72?auto=format&fit=crop&q=80')
                      : (item['heroImage'] ??
                            'https://images.unsplash.com/photo-1613545325278-f24b0cae1224?auto=format&fit=crop&q=80')))
            .toString();

    return _ScaleButton(
      onTap: () {
        if (isCommunity) {
          context.push('/communities/${item['_id']}', extra: item);
        } else if (isMedia) {
          context.push('/media');
        } else {
          context.push('/projects/${item['_id']}', extra: item);
        }
      },
      child: Container(
        width: 300,
        margin: const EdgeInsets.only(right: 20, bottom: 10),
        decoration: BoxDecoration(
          borderRadius: BorderRadius.circular(40),
        ),
        child: ClipRRect(
          borderRadius: BorderRadius.circular(40),
          child: Stack(
            fit: StackFit.expand,
            children: [
              // 🖼️ High Resolution Image
              _buildProjectImage(rawImage, errorIconSize: 40),

              // 🌫️ High-End Gradient Overlay
              Container(
                decoration: BoxDecoration(
                  gradient: LinearGradient(
                    begin: Alignment.topCenter,
                    end: Alignment.bottomCenter,
                    stops: const [0.3, 1.0],
                    colors: [
                      Colors.transparent,
                      Colors.black.withValues(alpha: 0.85),
                    ],
                  ),
                ),
              ),

              // 🎬 Play Icon for Media
              if (isMedia)
                Center(
                  child:
                      Container(
                        width: 60,
                        height: 60,
                        decoration: BoxDecoration(
                          color: Colors.white.withValues(alpha: 0.2),
                          shape: BoxShape.circle,
                          border: Border.all(
                            color: Colors.white.withValues(alpha: 0.4),
                            width: 2,
                          ),
                        ),
                        child: const Center(
                          child: Icon(
                            LucideIcons.play,
                            color: Colors.white,
                            size: 30,
                          ),
                        ),
                      ).animate().scale(
                        begin: const Offset(0.8, 0.8),
                        curve: Curves.elasticOut,
                        duration: 800.ms,
                      ),
                ),

              // 🏷️ Badge (for Properties/Media)
              if (!isCommunity)
                Positioned(
                  top: 24,
                  right: 24,
                  child: Container(
                    padding: const EdgeInsets.symmetric(
                      horizontal: 12,
                      vertical: 6,
                    ),
                    decoration: BoxDecoration(
                      color: Colors.black.withValues(alpha: 0.6),
                      borderRadius: BorderRadius.circular(20),
                      border: Border.all(
                        color: Colors.white.withValues(alpha: 0.1),
                      ),
                    ),
                    child: Text(
                      isMedia
                          ? 'MEDIA'
                          : (item['status']?.toString() ?? 'ONGOING')
                                .toUpperCase(),
                      style: GoogleFonts.ebGaramond(
                        color: Colors.white,
                        fontSize: 8,
                        fontWeight: FontWeight.w400,
                        letterSpacing: 1,
                      ),
                    ),
                  ),
                ),

              // 📄 Content Section
              Positioned(
                bottom: 24,
                left: 24,
                right: 24,
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      (item['title'] ?? item['name'] ?? '')
                          .toString()
                          .toUpperCase(),
                      style: GoogleFonts.gelasio(
                        color: Colors.white,
                        fontSize: 22,
                        fontWeight: FontWeight.w400,
                        letterSpacing: -0.5,
                      ),
                    ),
                    const SizedBox(height: 10),
                    Text(
                      (isCommunity
                              ? (item['overview'] ?? item['description'] ?? '')
                              : isMedia
                              ? (item['description'] ?? item['type'] ?? 'MEDIA')
                              : (item['location'] is Map
                                    ? item['location']['name']
                                    : item['location'] ?? 'MAZGAON'))
                          .toString()
                          .toUpperCase(),
                      maxLines: 2,
                      overflow: TextOverflow.ellipsis,
                      style: GoogleFonts.ebGaramond(
                        color: Colors.white.withValues(alpha: 0.7),
                        fontSize: 10,
                        fontWeight: FontWeight.w800,
                        letterSpacing: 0.5,
                        height: 1.4,
                      ),
                    ),
                    const SizedBox(height: 24),
                    Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        Text(
                          isCommunity
                              ? 'EXPLORE COMMUNITY'
                              : (isMedia ? 'READ ARTICLE' : 'VIEW PROPERTY'),
                          style: GoogleFonts.ebGaramond(
                            color: Colors.white,
                            fontSize: 10,
                            fontWeight: FontWeight.w400,
                            letterSpacing: 1.2,
                          ),
                        ),
                        Container(
                          width: 44,
                          height: 44,
                          decoration: BoxDecoration(
                            color: Colors.white,
                            shape: BoxShape.circle,
                            boxShadow: [
                              BoxShadow(
                                color: Colors.black.withValues(alpha: 0.2),
                                blurRadius: 10,
                                offset: const Offset(0, 4),
                              ),
                            ],
                          ),
                          child: const Icon(
                            LucideIcons.arrowRight,
                            color: Colors.black,
                            size: 18,
                          ),
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
    );
  }

  /// Renders a project image the same way the web does (see web `getAssetUrl`):
  /// inline base64 `data:` URIs are decoded with [Image.memory] (CachedNetworkImage
  /// can only fetch network URLs), `http(s)` URLs load directly, and relative
  /// paths are resolved against the API host. Empty values fall back to a stock image.
  Widget _buildProjectImage(
    String raw, {
    Key? key,
    double? width,
    double? height,
    BoxFit fit = BoxFit.cover,
    IconData errorIcon = LucideIcons.building2,
    double errorIconSize = 64,
  }) {
    Widget errorBox() => Container(
      color: const Color(0xFF141B3A),
      child: Center(
        child: Icon(errorIcon, color: Colors.white24, size: errorIconSize),
      ),
    );

    final src = raw.trim().isEmpty
        ? 'https://images.unsplash.com/photo-1545324418-cc1a3fa10c00?auto=format&fit=crop&q=80'
        : raw.trim();

    if (src.startsWith('data:')) {
      try {
        // Decode each base64 image ONCE (cached) instead of on every rebuild —
        // otherwise the hero's cycling stalls the UI thread and drops taps.
        final bytes = _base64Cache.putIfAbsent(
          src,
          () => base64Decode(
            src.substring(src.indexOf(',') + 1).replaceAll(RegExp(r'\s'), ''),
          ),
        );
        return Image.memory(
          bytes,
          key: key,
          width: width,
          height: height,
          fit: fit,
          gaplessPlayback: true,
          // Downsample large images to keep decode cost + memory in check.
          cacheWidth: 1080,
          errorBuilder: (_, __, ___) => errorBox(),
        );
      } catch (_) {
        return errorBox();
      }
    }

    final url = src.startsWith('http')
        ? src
        : ref.read(apiClientProvider).resolveUrl(src);
    return CachedNetworkImage(
      key: key,
      imageUrl: url,
      width: width,
      height: height,
      fit: fit,
      placeholder: (context, u) => Container(color: Colors.black12),
      errorWidget: (context, u, e) => errorBox(),
    );
  }

  Widget _buildFeaturedSection() {
    if (_projects.isEmpty) return const SizedBox.shrink();
    final project = _projects[_featuredIndex % _projects.length];
    final isDark = Theme.of(context).brightness == Brightness.dark;

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        // ⭐️ Header (Matched with Our Philosophy)
        Padding(
          padding: const EdgeInsets.symmetric(horizontal: 24),
          child: Text(
            'FEATURED PROPERTY',
            style: GoogleFonts.gelasio(
              fontSize: 32,
              fontWeight: FontWeight.w400,
              color: Theme.of(context).colorScheme.onSurface,
              letterSpacing: -0.5,
            ),
          ),
        ),
        const SizedBox(height: 40),

        // ⭐️ Main Artistic Card
        Container(
          margin: const EdgeInsets.symmetric(horizontal: 24),
          decoration: BoxDecoration(
            borderRadius: BorderRadius.circular(50),
          ),
          child: ClipRRect(
            borderRadius: BorderRadius.circular(50),
            child: Stack(
              children: [
                _buildProjectImage(
                  () {
                    final hero = project['heroImages'];
                    if (hero is List &&
                        hero.isNotEmpty &&
                        hero.first != null &&
                        hero.first.toString().trim().isNotEmpty) {
                      return hero.first.toString();
                    }
                    return (project['heroImage'] ??
                            project['image'] ??
                            project['coverImage'] ??
                            '')
                        .toString();
                  }(),
                  height: 520,
                  width: double.infinity,
                ),
                // Gradient Overlay
                Positioned.fill(
                  child: Container(
                    decoration: BoxDecoration(
                      gradient: LinearGradient(
                        begin: Alignment.topCenter,
                        end: Alignment.bottomCenter,
                        colors: [
                          Colors.transparent,
                          Colors.black.withOpacity(0.7),
                        ],
                        stops: const [0.5, 1.0],
                      ),
                    ),
                  ),
                ),
                // Artistic Impression Badge
                Positioned(
                  top: 24,
                  right: 24,
                  child: Container(
                    padding: const EdgeInsets.symmetric(
                      horizontal: 12,
                      vertical: 6,
                    ),
                    decoration: BoxDecoration(
                      color: Colors.black.withOpacity(0.6),
                      borderRadius: BorderRadius.circular(4),
                      border: Border.all(color: Colors.white.withOpacity(0.2)),
                    ),
                    child: Text(
                      'ARTISTIC IMPRESSION',
                      style: GoogleFonts.gelasio(
                        color: Colors.white,
                        fontSize: 7,
                        fontWeight: FontWeight.w900,
                        letterSpacing: 1.5,
                      ),
                    ),
                  ),
                ),
                // Content Overlay
                Positioned(
                  bottom: 40,
                  left: 32,
                  right: 32,
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        'FEATURED PROPERTY',
                        style: GoogleFonts.gelasio(
                          color: const Color(0xFFC5A35B),
                          fontSize: 9,
                          fontWeight: FontWeight.w900,
                          letterSpacing: 2.5,
                        ),
                      ),
                      const SizedBox(height: 12),
                      Text(
                        (project['title'] ?? '').toString(),
                        style: GoogleFonts.gelasio(
                          color: Colors.white,
                          fontSize: 44,
                          fontWeight: FontWeight.w400,
                          height: 1,
                          letterSpacing: -1,
                        ),
                      ),
                      const SizedBox(height: 16),
                      Text(
                        'Live smart at Aura Heights—space-efficient 1 & 2 BHK homes with curated amenities and rare parking solutions.'
                            .toUpperCase(),
                        maxLines: 2,
                        overflow: TextOverflow.ellipsis,
                        style: GoogleFonts.ebGaramond(
                          color: Colors.white.withOpacity(0.8),
                          fontSize: 9,
                          height: 1.6,
                          fontWeight: FontWeight.w900,
                          letterSpacing: 1.2,
                        ),
                      ),
                    ],
                  ),
                ),
              ],
            ),
          ),
        ),

        const SizedBox(height: 48),

        // ⭐️ Feature Icons (Synchronized with Web Grid)
        Padding(
          padding: const EdgeInsets.symmetric(horizontal: 32),
          child: Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              _buildFeatureIcon(LucideIcons.building2, 'FULLY\nFURNISHED'),
              _buildFeatureIcon(LucideIcons.mapPin, 'PRIME\nLOCATION'),
              _buildFeatureIcon(
                LucideIcons.smartphone,
                '20 MIN FROM\nSHEIKH ZAYED RD',
              ),
            ],
          ),
        ),

        const SizedBox(height: 48),

        // ⭐️ Center Navigation (Synchronized with Web)
        Padding(
          padding: const EdgeInsets.symmetric(horizontal: 24),
          child: Row(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              _ScaleButton(
                onTap: () => setState(
                  () => _featuredIndex =
                      (_featuredIndex - 1 + _projects.length) %
                      _projects.length,
                ),
                child: Container(
                  width: 56,
                  height: 56,
                  decoration: BoxDecoration(
                    color: Colors.transparent,
                    shape: BoxShape.circle,
                    border: Border.all(
                      color: (isDark ? Colors.white : Colors.black).withOpacity(
                        0.1,
                      ),
                    ),
                  ),
                  child: Icon(
                    LucideIcons.arrowLeft,
                    color: isDark ? Colors.white : Colors.black,
                    size: 20,
                  ),
                ),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: _ScaleButton(
                  onTap: () => context.push(
                    '/projects/${project['_id']}',
                    extra: project,
                  ),
                  child: Container(
                    height: 56,
                    decoration: BoxDecoration(
                      color: isDark ? Colors.white : Colors.black,
                      borderRadius: BorderRadius.circular(14),
                    ),
                    child: Center(
                      child: Text(
                        'READ MORE',
                        style: GoogleFonts.gelasio(
                          color: isDark ? Colors.black : Colors.white,
                          fontWeight: FontWeight.w900,
                          fontSize: 12,
                          letterSpacing: 3,
                        ),
                      ),
                    ),
                  ),
                ),
              ),
              const SizedBox(width: 12),
              _ScaleButton(
                onTap: () => setState(
                  () =>
                      _featuredIndex = (_featuredIndex + 1) % _projects.length,
                ),
                child: Container(
                  width: 56,
                  height: 56,
                  decoration: BoxDecoration(
                    color: Colors.transparent,
                    shape: BoxShape.circle,
                    border: Border.all(
                      color: (isDark ? Colors.white : Colors.black).withOpacity(
                        0.1,
                      ),
                    ),
                  ),
                  child: Icon(
                    LucideIcons.arrowRight,
                    color: isDark ? Colors.white : Colors.black,
                    size: 20,
                  ),
                ),
              ),
            ],
          ),
        ),
      ],
    );
  }

  Widget _buildFeatureIcon(IconData icon, String label) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    return Column(
      children: [
        Icon(icon, color: isDark ? Colors.white : Colors.black, size: 24),
        const SizedBox(height: 8),
        Text(
          label,
          textAlign: TextAlign.center,
          style: GoogleFonts.gelasio(
            color: isDark ? Colors.white : Colors.black,
            fontSize: 9,
            fontWeight: FontWeight.w800,
            letterSpacing: 1.5,
          ),
        ),
      ],
    );
  }

  Widget _buildCircularNavButton(IconData icon, VoidCallback onTap) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    return GestureDetector(
      onTap: onTap,
      child: Container(
        width: 56,
        height: 56,
        decoration: BoxDecoration(
          color: Theme.of(context).scaffoldBackgroundColor,
          borderRadius: BorderRadius.circular(16),
          border: Border.all(
            color: (isDark ? Colors.white : Colors.black).withOpacity(0.05),
          ),
        ),
        child: Icon(
          icon,
          color: isDark ? Colors.white70 : Colors.black87,
          size: 20,
        ),
      ),
    );
  }

  Widget _buildConnectGrid() {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        // ⭐️ Header (Matched with Register Interest)
        Text(
          'EXPLORE, CONNECT\nAND ENGAGE WITH US',
          style: GoogleFonts.gelasio(
            fontSize: 32,
            fontWeight: FontWeight.w400,
            color: Theme.of(context).colorScheme.onSurface,
            letterSpacing: -1,
            height: 1.1,
          ),
        ),
        const SizedBox(height: 40),

        // ⭐️ Unified Grid Card
        Container(
          decoration: BoxDecoration(
            color: isDark
                ? Colors.white.withOpacity(0.03)
                : Colors.black.withOpacity(0.02),
            borderRadius: BorderRadius.circular(32),
            border: Border.all(
              color: (isDark ? Colors.white : Colors.black).withOpacity(0.08),
            ),
          ),
          child: ClipRRect(
            borderRadius: BorderRadius.circular(32),
            child: GridView.count(
              shrinkWrap: true,
              physics: const NeverScrollableScrollPhysics(),
              crossAxisCount: 2,
              mainAxisSpacing: 1,
              crossAxisSpacing: 1,
              childAspectRatio: 0.95,
              children: [
                _buildConnectItem(
                  LucideIcons.building2,
                  'EXPLORE PROJECTS',
                  'Browse our portfolio of properties',
                  () => Navigator.push(
                    context,
                    MaterialPageRoute(
                      builder: (context) => const ProjectListScreen(),
                    ),
                  ),
                ),
                _buildConnectItem(
                  LucideIcons.calendarDays,
                  'BOOK A VIEWING',
                  'Schedule a visit to our show apartment',
                  _scrollToInterestForm,
                ),
                _buildConnectItem(
                  LucideIcons.image,
                  'MEDIA GALLERY',
                  'Watch films and view property renders',
                  () => context.push('/media'),
                ),
                _buildConnectItem(
                  LucideIcons.user,
                  'REGISTER INTEREST',
                  'Register your interest in our properties',
                  _scrollToInterestForm,
                ),
              ],
            ),
          ),
        ),
      ],
    );
  }

  Widget _buildConnectItem(
    IconData icon,
    String title,
    String desc,
    VoidCallback onTap,
  ) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    return InkWell(
      onTap: onTap,
      child: Padding(
        padding: const EdgeInsets.all(20),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Container(
              width: 48,
              height: 48,
              decoration: BoxDecoration(
                color: (isDark ? Colors.white : Colors.black).withOpacity(0.05),
                shape: BoxShape.circle,
                border: Border.all(
                  color: (isDark ? Colors.white : Colors.black).withOpacity(
                    0.1,
                  ),
                ),
              ),
              child: Icon(
                icon,
                color: isDark ? Colors.white : Colors.black,
                size: 20,
              ),
            ),
            const SizedBox(height: 16),
            Text(
              title,
              textAlign: TextAlign.center,
              style: GoogleFonts.ebGaramond(
                color: isDark ? Colors.white : Colors.black,
                fontWeight: FontWeight.w900,
                fontSize: 10,
                letterSpacing: 1,
              ),
            ),
            const SizedBox(height: 6),
            Text(
              desc,
              textAlign: TextAlign.center,
              style: GoogleFonts.ebGaramond(
                color: (isDark ? Colors.white : Colors.black).withOpacity(0.68),
                fontSize: 8,
                fontWeight: FontWeight.w500,
                height: 1.4,
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildInterestForm() {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    return Column(
      key: _interestFormKey,
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          'REGISTER YOUR\nINTEREST',
          style: GoogleFonts.gelasio(
            color: isDark ? Colors.white : Colors.black,
            fontSize: 32,
            fontWeight: FontWeight.w400,
            letterSpacing: -1,
            height: 1.1,
          ),
        ),
        const SizedBox(height: 48),
        _buildLuxuryInput('Full Name *', _nameController),
        const SizedBox(height: 16),
        _buildLuxuryInput('Email *', _emailController),
        const SizedBox(height: 16),
        _buildLuxuryInput('Phone Number *', _phoneController),
        const SizedBox(height: 16),
        _buildLuxuryInput('Message', _messageController, isLong: true),
        const SizedBox(height: 24),
        Row(
          children: [
            Checkbox(
              value: _agreedToTerms,
              onChanged: (val) => setState(() => _agreedToTerms = val ?? false),
              activeColor: isDark ? Colors.white : Colors.black,
              checkColor: isDark ? Colors.black : Colors.white,
              side: BorderSide(color: isDark ? Colors.white24 : Colors.black26),
            ),
            Expanded(
              child: Text(
                "I've read and agree to the Privacy Policy",
                style: GoogleFonts.ebGaramond(
                  color: isDark ? Colors.white54 : Colors.black54,
                  fontSize: 11,
                  letterSpacing: 1,
                ),
              ),
            ),
          ],
        ),
        const SizedBox(height: 32),
        SizedBox(
          width: double.infinity,
          height: 64,
          child: _ScaleButton(
            onTap: _submitting ? () {} : _submitInterest,
            child: Container(
              decoration: BoxDecoration(
                color: isDark ? Colors.white : Colors.black,
                borderRadius: BorderRadius.circular(16),
              ),
              child: Center(
                child: _submitting
                    ? CircularProgressIndicator(
                        color: isDark ? Colors.black : Colors.white,
                      )
                    : Text(
                        'SUBMIT INTEREST',
                        style: GoogleFonts.ebGaramond(
                          color: isDark ? Colors.black : Colors.white,
                          fontWeight: FontWeight.w400,
                          letterSpacing: 2,
                        ),
                      ),
              ),
            ),
          ),
        ),
      ],
    );
  }

  Widget _buildLuxuryInput(
    String hint,
    TextEditingController controller, {
    bool isLong = false,
  }) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    return Container(
      decoration: BoxDecoration(
        color: Theme.of(context).scaffoldBackgroundColor,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(
          color: (isDark ? Colors.white : Colors.black).withOpacity(0.12),
        ),
        boxShadow: isDark
            ? []
            : [
                BoxShadow(
                  color: Colors.black.withOpacity(0.05),
                  blurRadius: 20,
                  offset: const Offset(0, 10),
                ),
              ],
      ),
      child: TextField(
        controller: controller,
        style: TextStyle(color: isDark ? Colors.white : Colors.black),
        maxLines: isLong ? 5 : 1,
        decoration: InputDecoration(
          hintText: hint,
          hintStyle: GoogleFonts.ebGaramond(
            color: isDark ? Colors.white54 : Colors.black45,
            fontSize: 13,
          ),
          contentPadding: const EdgeInsets.symmetric(
            horizontal: 24,
            vertical: 12,
          ),
          filled: false, border: InputBorder.none, enabledBorder: InputBorder.none, focusedBorder: InputBorder.none,
        ),
      ),
    );
  }
}

class _ScaleButton extends StatefulWidget {
  final Widget child;
  final VoidCallback onTap;
  const _ScaleButton({required this.child, required this.onTap});

  @override
  State<_ScaleButton> createState() => _ScaleButtonState();
}

class _ScaleButtonState extends State<_ScaleButton>
    with SingleTickerProviderStateMixin {
  late AnimationController _controller;
  late Animation<double> _scale;

  @override
  void initState() {
    super.initState();
    _controller = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 100),
    );
    _scale = Tween<double>(
      begin: 1.0,
      end: 0.95,
    ).animate(CurvedAnimation(parent: _controller, curve: Curves.easeInOut));
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTapDown: (_) => _controller.forward(),
      onTapUp: (_) => _controller.reverse(),
      onTapCancel: () => _controller.reverse(),
      onTap: widget.onTap,
      child: ScaleTransition(scale: _scale, child: widget.child),
    );
  }
}
