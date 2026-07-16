import 'package:flutter/material.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:m4_mobile/core/theme/app_theme.dart';
import 'package:flutter_animate/flutter_animate.dart';
import 'package:lucide_icons/lucide_icons.dart';
import 'package:google_fonts/google_fonts.dart';
import 'dart:io';
import 'dart:ui';
import 'dart:convert';
import 'dart:typed_data';
import 'package:m4_mobile/presentation/widgets/guest_sidebar_menu.dart';
import 'package:m4_mobile/core/network/api_client.dart';
import 'package:m4_mobile/presentation/providers/auth_provider.dart';
import 'package:m4_mobile/presentation/providers/project_provider.dart';
import 'package:m4_mobile/presentation/screens/projects/guest_project_detail_screen.dart';
import 'package:m4_mobile/presentation/screens/projects/project_list_screen.dart';
import 'package:m4_mobile/presentation/screens/communities/community_detail_screen.dart';
import 'package:m4_mobile/presentation/screens/communities/community_list_screen.dart';
import 'package:m4_mobile/presentation/widgets/guest_main_shell.dart';
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

  // Inline validation for the "Register your interest" form — the field itself
  // turns red instead of a snackbar popping over the page.
  String? _nameError;
  String? _emailError;
  String? _phoneError;
  // Per-slice freshness: set when NETWORK data lands, so the async disk-cache
  // read never overwrites fresh data — but still fills slices whose fetch
  // failed or is still in flight (e.g. offline cold start).
  bool _hasFreshFast = false;
  bool _hasFreshProjects = false;
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
    } else {
      // Cold start: render the last-known payload from disk immediately
      // (stale-while-revalidate) instead of blocking on the network.
      _loadDiskCache();
    }
    // Deferred to a microtask: _fetchData initializes/invalidates providers,
    // which must not notify other watchers mid-build (initState runs during
    // element inflation).
    Future.microtask(() {
      if (!mounted) return;
      // Keep _projects in sync with later provider refreshes too (e.g. the
      // Projects tab's RETRY re-fetching after an offline start).
      ref.listenManual(projectsProvider, (previous, next) {
        final data = next.asData?.value;
        if (data == null || !mounted) return;
        setState(() {
          _projects = data;
          _hasFreshProjects = true;
          _loading = false;
        });
      });
      // Menu "Enquiry" → jump to this page's Register Your Interest form.
      ref.listenManual(scrollToRegisterProvider, (previous, next) {
        if (!mounted) return;
        // Let the home tab become visible/settle, then scroll to the form.
        Future.delayed(const Duration(milliseconds: 250), () {
          if (mounted) _scrollToInterestForm();
        });
      });
      _fetchData();
    });
    _heroTimer = Timer.periodic(const Duration(seconds: 3), (timer) {
      if (!mounted) return;
      // Cycles both the real hero set and the placeholder set (same getter).
      final count = _heroSlides.length;
      setState(() => _heroIndex = (_heroIndex + 1) % count);
    });
  }

  /// Web parity: the hero cycles the first 3 catalog projects (the web shows
  /// 3 dots and leads with the newest project — currently the Cledor tower),
  /// keeping a reference to each project so slides with attached media get
  /// the web's ▶ play affordance. Falls back to curated stock shots while
  /// projects are still loading.
  List<Map<String, dynamic>> get _heroSlides {
    // Web parity: the hero leads with the newest live (Ongoing) project and
    // then the completed showcases — Upcoming projects and additional
    // Ongoing ones never appear (matches the web's slide set).
    final slides = <Map<String, dynamic>>[];
    var ongoingTaken = false;
    for (final p in _projects) {
      final status = (p['status'] ?? '').toString().toLowerCase();
      if (status == 'upcoming') continue;
      if (status == 'ongoing') {
        if (ongoingTaken) continue;
        ongoingTaken = true;
      }
      final img = _pickImage([p['heroImage'], p['image']], '');
      if (img.isEmpty) continue;
      slides.add({'image': img, 'project': p});
      if (slides.length == 3) break;
    }
    if (slides.isNotEmpty) {
      // The Artistic Impression hero leads with a bright interior render
      // (bundled asset) rather than the project's exterior shot.
      slides[0] = {...slides[0], 'image': 'assets/hero_artistic.jpg'};
      return slides;
    }
    return const [
      {'image': 'assets/hero_artistic.jpg', 'project': null},
      {
        'image':
            'https://images.unsplash.com/photo-1512917774080-9991f1c4c750?auto=format&fit=crop&q=80',
        'project': null,
      },
      {
        'image':
            'https://images.unsplash.com/photo-1484154218962-a197022b5858?auto=format&fit=crop&q=80',
        'project': null,
      },
    ];
  }

  File get _diskCacheFile =>
      File('${Directory.systemTemp.path}/m4_guest_home_cache.json');

  /// Reads the persisted guest-home payload (if any) so a cold app start
  /// renders instantly; the network refresh in [_fetchData] replaces it.
  Future<void> _loadDiskCache() async {
    try {
      final file = _diskCacheFile;
      if (!await file.exists()) return;
      final raw = await file.readAsString();
      // Decode off the UI isolate — the payload can be multiple MB.
      final map = await compute(jsonDecode, raw) as Map<String, dynamic>;
      if (!mounted) return;
      setState(() {
        // Fill only the slices the network hasn't (yet) delivered — the disk
        // copy must never overwrite fresh data, but it must still cover
        // failed/pending fetches (e.g. offline cold start).
        if (!_hasFreshProjects) {
          _projects = map['projects'] as List<dynamic>? ?? [];
        }
        if (!_hasFreshFast) {
          _communities = map['communities'] as List<dynamic>? ?? [];
          _media = map['media'] as List<dynamic>? ?? [];
        }
        _loading = false;
      });
    } catch (_) {
      // Corrupt/unreadable cache: ignore, the network fetch still runs.
    }
  }

  /// Persists the freshly fetched payload for instant cold starts.
  Future<void> _saveDiskCache() async {
    try {
      final raw = await compute(jsonEncode, <String, dynamic>{
        'projects': _projects,
        'communities': _communities,
        'media': _media,
      });
      await _diskCacheFile.writeAsString(raw);
    } catch (_) {
      // Best-effort cache; failures must never surface to the UI.
    }
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

  Future<void> _fetchData() async {
    final apiClient = ref.read(apiClientProvider);

    // The communities + media payloads are a few KB and land in well under a
    // second; the projects payload can be several MB (hero images). Fetch them
    // independently and render as soon as the fast pair arrives — the hero
    // section shows its built-in placeholders until projects stream in.
    final fastPair = Future.wait([apiClient.getCommunities(), apiClient.getContent('media')])
        .then((results) {
          if (!mounted) return false;
          setState(() {
            _communities = results[0].data['data'] ?? [];
            _media = results[1].data['data'] ?? [];

            // 💡 Add dummy content if media is empty to fill blank space
            if (_media.isEmpty) {
              _media = [
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
            }
            _hasFreshFast = true;
            _loading = false;
          });
          return true;
        })
        .catchError((_) {
          if (mounted) setState(() => _loading = false);
          return false;
        });

    // Projects come through the shared [projectsProvider] so this screen and
    // ProjectListScreen (both alive in the guest IndexedStack) reuse ONE
    // download of the multi-MB payload instead of fetching it twice.
    // FutureProviders cache errors: if a previous attempt failed, retry it on
    // this mount (matches the old fetch-per-mount recovery behaviour).
    if (ref.read(projectsProvider) is AsyncError) {
      ref.invalidate(projectsProvider);
    }
    final projectsFetch = ref
        .read(projectsProvider.future)
        .then((projects) {
          if (!mounted) return false;
          setState(() {
            _projects = projects;
            _hasFreshProjects = true;
            _loading = false;
          });
          return true;
        })
        .catchError((_) {
          if (mounted) setState(() => _loading = false);
          return false;
        });

    final ok = await Future.wait([fastPair, projectsFetch]);
    if (!mounted || ok.contains(false)) return;

    // Cache the complete fresh payload so the next guest-home mount is
    // instant (in memory for this session, on disk for the next cold start).
    ref.read(guestHomeCacheProvider.notifier).state = GuestHomeData(
      projects: _projects,
      communities: _communities,
      media: _media,
    );
    _saveDiskCache();
  }

  void _scrollToInterestForm() {
    final ctx = _interestFormKey.currentContext;
    if (ctx != null) {
      Scrollable.ensureVisible(
        ctx,
        duration: const Duration(seconds: 1),
        curve: Curves.easeInOut,
      );
    } else if (_scrollController.hasClients) {
      // Form not laid out yet (page at the top). It's the last section, so
      // animate to the bottom to reveal it, then settle exactly onto it.
      _scrollController
          .animateTo(
            _scrollController.position.maxScrollExtent,
            duration: const Duration(milliseconds: 800),
            curve: Curves.easeInOut,
          )
          .then((_) {
            final c = _interestFormKey.currentContext;
            if (c != null) {
              Scrollable.ensureVisible(
                c,
                duration: const Duration(milliseconds: 300),
                curve: Curves.easeInOut,
              );
            }
          });
    }
  }

  /// Marks the empty required fields red in place. Returns true when valid.
  bool _validateInterest() {
    final nameErr = _nameController.text.trim().isEmpty
        ? 'Please enter your full name'
        : null;
    final emailErr = _emailController.text.trim().isEmpty
        ? 'Please enter your email address'
        : null;
    final phoneErr = _phoneController.text.trim().isEmpty
        ? 'Please enter your phone number'
        : null;
    setState(() {
      _nameError = nameErr;
      _emailError = emailErr;
      _phoneError = phoneErr;
    });
    return nameErr == null && emailErr == null && phoneErr == null;
  }

  Future<void> _submitInterest() async {
    if (!_validateInterest()) return;
    if (!_agreedToTerms) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          backgroundColor: Color(0xFFE24B4A),
          content: Text('Please agree to the Privacy Policy'),
        ),
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
        // Server-side enums — anything else is rejected with a 400. Valid:
        // interest = Buying | Selling | Site Visit | Video Call
        // (case-sensitive); source = online | cp | walk-in | referral | other.
        'interest': 'Buying',
        'source': 'online',
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
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          backgroundColor: const Color(0xFFE24B4A),
          content: Text('Submission failed: $e'),
        ),
      );
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
                style: GoogleFonts.dmSerifDisplay(
                  fontSize: 11,
                  fontWeight: FontWeight.w600,
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
          // ⭐️ HEADER (web parity: scrolls away with content — pinning it
          // made scrolled content bleed through the translucent bar)
          SliverAppBar(
            pinned: false,
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
                          color: Theme.of(context).brightness == Brightness.dark
                              ? Colors.white
                              : Colors.black,
                          borderRadius: BorderRadius.circular(14),
                        ),
                        child: Icon(
                          LucideIcons.moreHorizontal,
                          color: Theme.of(context).brightness == Brightness.dark
                              ? Colors.black
                              : Colors.white,
                          size: 24,
                        ),
                      ),
                    ),
                  ),
                ],
              ),
            ),
          ),

          // ⭐️ TAGLINE & HERO SECTION (web parity: compact left tagline, no
          // translate hacks — natural flow keeps the hero→tabs gap tight)
          SliverToBoxAdapter(
            child: Padding(
              padding: const EdgeInsets.fromLTRB(0, 0, 0, 0),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  // Tagline (Living the M4 Life) — full-width script image,
                  // cropped tight to the text band so there is no large gap
                  // before the hero. Same in light and dark mode.
                  Padding(
                    padding: const EdgeInsets.only(top: 12, bottom: 8),
                    child: ColorFiltered(
                      colorFilter: ColorFilter.matrix(
                        Theme.of(context).brightness == Brightness.dark
                            ? const [
                                // Dark Mode: Invert and boost to white
                                -5.0, 0, 0, 0, 255,
                                0, -5.0, 0, 0, 255,
                                0, -5.0, 0, 0, 255,
                                0, 0, 0, 1, 0,
                              ]
                            : const [
                                // Light Mode: Crush to black
                                5.0, 0, 0, 0, -150,
                                0, 5.0, 0, 0, -150,
                                0, 0, 5.0, 0, -150,
                                0, 0, 0, 1, 0,
                              ],
                      ),
                      child: Image.asset(
                        'assets/living_m4_life.png',
                        width: MediaQuery.of(context).size.width,
                        height: 120,
                        fit: BoxFit.fitWidth,
                      ),
                    ),
                  ),

                  // Hero Image Container
                  Padding(
                    padding: const EdgeInsets.symmetric(horizontal: 24),
                    child: Builder(
                      builder: (context) {
                        final slides = _heroSlides;
                        final slide = slides[_heroIndex % slides.length];
                        final mainImage = slide['image'] as String;
                        final project = slide['project'];
                        final hasMedia =
                            project != null &&
                            project['media'] is List &&
                            (project['media'] as List).isNotEmpty;
                        final dotCount = slides.length;

                        return Stack(
                          children: [
                            AspectRatio(
                              aspectRatio: 4 / 3,
                              child: Container(
                                decoration: BoxDecoration(
                                  borderRadius: BorderRadius.circular(24),
                                  boxShadow: [
                                    BoxShadow(
                                      color: Colors.black.withOpacity(0.12),
                                      blurRadius: 24,
                                      offset: const Offset(0, 12),
                                    ),
                                  ],
                                ),
                                child: ClipRRect(
                                  borderRadius: BorderRadius.circular(24),
                                  child: AnimatedSwitcher(
                                    duration: const Duration(milliseconds: 800),
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
                                  color: Colors.black.withOpacity(0.45),
                                  borderRadius: BorderRadius.circular(6),
                                  border: Border.all(
                                    color: Colors.white.withOpacity(0.1),
                                  ),
                                ),
                                child: Text(
                                  'ARTISTIC IMPRESSION',
                                  style: GoogleFonts.dmSerifDisplay(
                                    color: Colors.white,
                                    fontSize: 8,
                                    fontWeight: FontWeight.w600,
                                    letterSpacing: 1.5,
                                  ),
                                ),
                              ),
                            ),

                            // ▶ Play affordance (web parity: shown when the
                            // project has attached media)
                            if (hasMedia)
                              Positioned.fill(
                                child: Center(
                                  child: GestureDetector(
                                    onTap: () {
                                      final id = project['_id'];
                                      if (id != null) {
                                        context.push(
                                          '/projects/$id',
                                          extra: project,
                                        );
                                      }
                                    },
                                    child: Container(
                                      width: 64,
                                      height: 64,
                                      decoration: BoxDecoration(
                                        color: Colors.white.withValues(
                                          alpha: 0.75,
                                        ),
                                        shape: BoxShape.circle,
                                      ),
                                      child: const Center(
                                        child: Icon(
                                          LucideIcons.play,
                                          color: Colors.black87,
                                          size: 26,
                                        ),
                                      ),
                                    ),
                                  ),
                                ),
                              ),

                            // Pagination Dots (web parity: bottom-left,
                            // active becomes a wider dark pill; count follows
                            // the actual carousel length)
                            Positioned(
                              bottom: 18,
                              left: 20,
                              child: Row(
                                mainAxisSize: MainAxisSize.min,
                                children: List.generate(dotCount, (index) {
                                  final isSelected =
                                      (_heroIndex % dotCount) == index;
                                  return AnimatedContainer(
                                    duration: const Duration(milliseconds: 300),
                                    margin: const EdgeInsets.symmetric(
                                      horizontal: 4,
                                    ),
                                    width: isSelected ? 22 : 8,
                                    height: 8,
                                    decoration: BoxDecoration(
                                      color: isSelected
                                          ? Colors.black.withValues(alpha: 0.85)
                                          : Colors.white.withValues(
                                              alpha: 0.75,
                                            ),
                                      borderRadius: BorderRadius.circular(4),
                                      boxShadow: [
                                        BoxShadow(
                                          color: Colors.black.withValues(
                                            alpha: 0.15,
                                          ),
                                          blurRadius: 4,
                                        ),
                                      ],
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
                ],
              ),
            ),
          ),
          SliverPadding(
            padding: const EdgeInsets.only(bottom: 32),
            sliver: SliverList(
              delegate: SliverChildListDelegate([
                // Tabs sit in natural flow right under the hero (web parity —
                // the old translate hack left a large ghost gap here).
                Padding(
                  padding: const EdgeInsets.fromLTRB(24, 40, 24, 0),
                  child: _buildTabsSection(),
                ),
                const SizedBox(height: 48),
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
          style: GoogleFonts.dmSerifDisplay(
            fontSize: 32,
            fontWeight: FontWeight.w400,
            color: Theme.of(context).colorScheme.onSurface,
            letterSpacing: -0.5,
          ),
        ),
        const SizedBox(height: 24),
        RichText(
          text: TextSpan(
            style: GoogleFonts.dmSerifDisplay(
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
                    style: GoogleFonts.dmSerifDisplay(
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
                        padding: const EdgeInsets.only(right: 28),
                        // Web parity: the active underline spans the full tab
                        // text width (border-bottom), not a short stub.
                        child: Container(
                          padding: const EdgeInsets.only(bottom: 8),
                          decoration: BoxDecoration(
                            border: Border(
                              bottom: BorderSide(
                                color: isSelected
                                    ? (isDark ? Colors.white : Colors.black)
                                    : Colors.transparent,
                                width: 2,
                              ),
                            ),
                          ),
                          child: Text(
                            tab.toUpperCase(),
                            style: GoogleFonts.dmSerifDisplay(
                              color: isSelected
                                  ? (isDark ? Colors.white : Colors.black)
                                  : (isDark ? Colors.white : Colors.black)
                                        .withValues(alpha: 0.55),
                              fontSize: 12,
                              fontWeight: FontWeight.w600,
                              letterSpacing: 2,
                            ),
                          ),
                        ),
                      ),
                    );
                  }).toList(),
                ),
              ),
            ),
          ],
        ),
        const SizedBox(height: 24),
        SizedBox(
          // The Properties info-card (image + text + button) needs more room
          // than the image-overlay cards used by Communities/Media. Horizontal
          // lists stretch children to this height, so it matches the card's
          // content height exactly (image 180 + info section + margin).
          height: _activeTab == 'Properties' ? 336 : 320,
          child: Builder(
            builder: (context) {
              final isCommunities = _activeTab == 'Communities';
              final items = isCommunities ? _communities : _projects;
              // Properties/Media render the projects payload, which arrives via
              // projectsProvider and can take a while (multi-MB). Surface its
              // real state — an empty box while loading/failed reads as broken.
              if (items.isEmpty && !isCommunities) {
                final projectsAsync = ref.watch(projectsProvider);
                if (projectsAsync is AsyncLoading) {
                  return const Center(
                    child: SizedBox(
                      width: 22,
                      height: 22,
                      child: CircularProgressIndicator(strokeWidth: 2),
                    ),
                  );
                }
                if (projectsAsync is AsyncError) {
                  return Center(
                    child: TextButton.icon(
                      onPressed: () => ref.invalidate(projectsProvider),
                      icon: const Icon(LucideIcons.refreshCw, size: 14),
                      label: Text(
                        'RETRY',
                        style: GoogleFonts.dmSerifDisplay(
                          fontSize: 11,
                          fontWeight: FontWeight.w700,
                          letterSpacing: 1.5,
                        ),
                      ),
                    ),
                  );
                }
              }
              return ListView.builder(
                scrollDirection: Axis.horizontal,
                physics: const BouncingScrollPhysics(),
                // Web parity: the Media tab is a visual gallery of the catalog
                // projects (hero image + title), not the CMS media articles.
                itemCount: items.length,
                itemBuilder: (context, index) => _buildTabCard(items[index]),
              );
            },
          ),
        ),
      ],
    );
  }

  /// Web parity: JS `||` treats empty strings as missing, Dart `??` does not.
  /// The API returns `image: ""` for some records — those must fall back to
  /// the same stock image the web shows, not slip through as "present".
  static String _pickImage(List<dynamic> candidates, String fallback) {
    for (final c in candidates) {
      final s = (c ?? '').toString().trim();
      if (s.isNotEmpty) return s;
    }
    return fallback;
  }

  Widget _buildTabCard(dynamic item) {
    final isCommunity = _activeTab.toLowerCase() == 'communities';
    final isMedia = _activeTab.toLowerCase() == 'media';

    // Web parity: Media cards are a plain visual gallery — project image with
    // only the title bottom-left (no badge/play/action row).
    if (isMedia) return _buildMediaCard(item);

    final rawImage = isCommunity
        ? _pickImage(
            [item['image']],
            'https://images.unsplash.com/photo-1486406146926-c627a92ad1ab?auto=format&fit=crop&q=80',
          )
        : (isMedia
              ? _pickImage(
                  [item['thumbnail'], item['image']],
                  'https://images.unsplash.com/photo-1556761175-b413da4baf72?auto=format&fit=crop&q=80',
                )
              : _pickImage(
                  [item['heroImage']],
                  'https://images.unsplash.com/photo-1613545325278-f24b0cae1224?auto=format&fit=crop&q=80',
                ));

    // Web parity: the Properties tab uses a light "info card" layout (image
    // on top, title/location below, READ MORE button) — unlike the
    // image-overlay cards used by Communities and Media.
    if (!isCommunity && !isMedia) {
      return _buildPropertyCard(item, rawImage);
    }

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
        // Web parity: card ≈56% of screen width so ~1.7 cards peek into view,
        // with softer 24px corners.
        width: MediaQuery.of(context).size.width * 0.56,
        margin: const EdgeInsets.only(right: 16, bottom: 10),
        decoration: BoxDecoration(
          borderRadius: BorderRadius.circular(24),
          boxShadow: [
            BoxShadow(
              color: Colors.black.withValues(alpha: 0.12),
              blurRadius: 18,
              offset: const Offset(0, 8),
            ),
          ],
        ),
        child: ClipRRect(
          borderRadius: BorderRadius.circular(24),
          child: Stack(
            fit: StackFit.expand,
            children: [
              // 🖼️ High Resolution Image
              _buildProjectImage(rawImage, errorIconSize: 40),

              // 🌫️ Text scrim (web parity: cards stay bright, only the
              // bottom label area gets a soft dark fade)
              Container(
                decoration: BoxDecoration(
                  gradient: LinearGradient(
                    begin: Alignment.topCenter,
                    end: Alignment.bottomCenter,
                    stops: const [0.55, 1.0],
                    colors: [
                      Colors.transparent,
                      Colors.black.withValues(alpha: 0.7),
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
                      style: GoogleFonts.dmSerifDisplay(
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
                      style: GoogleFonts.dmSerifDisplay(
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
                              : (item['location'] is Map
                                    ? item['location']['name']
                                    : item['location'] ?? 'MAZGAON'))
                          .toString()
                          .toUpperCase(),
                      maxLines: 2,
                      overflow: TextOverflow.ellipsis,
                      style: GoogleFonts.dmSerifDisplay(
                        color: Colors.white.withValues(alpha: 0.7),
                        fontSize: 10,
                        fontWeight: FontWeight.w600,
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
                          style: GoogleFonts.dmSerifDisplay(
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

  /// Web-parity media card: the web's Media tab is a visual gallery of the
  /// catalog projects — full-bleed hero image with just the project title in
  /// small white caps at the bottom-left.
  /// Opens the featured project's detail page. Shared by the card image and the
  /// READ MORE button — tapping the artwork did nothing before, which read as
  /// the section being dead.
  void _openFeatured(dynamic project) {
    final id = project['_id'];
    if (id != null) {
      context.push('/projects/$id', extra: project);
    } else {
      // No live project at all: fall back to the Projects tab.
      ref.read(guestNavigationProvider.notifier).state = 1;
    }
  }

  Widget _buildMediaCard(dynamic item) {
    final rawImage = _pickImage(
      [item['heroImage'], item['image']],
      'https://images.unsplash.com/photo-1556761175-b413da4baf72?auto=format&fit=crop&q=80',
    );
    return _ScaleButton(
      // Media tiles open the Media Gallery (content hub) — the same target as
      // the menu's Media entry. They used to open the project detail page,
      // which is the Properties tab's destination, not this one's.
      onTap: () => context.push('/media'),
      child: Container(
        width: MediaQuery.of(context).size.width * 0.56,
        margin: const EdgeInsets.only(right: 16, bottom: 10),
        decoration: BoxDecoration(
          borderRadius: BorderRadius.circular(24),
          boxShadow: [
            BoxShadow(
              color: Colors.black.withValues(alpha: 0.12),
              blurRadius: 18,
              offset: const Offset(0, 8),
            ),
          ],
        ),
        child: ClipRRect(
          borderRadius: BorderRadius.circular(24),
          child: Stack(
            fit: StackFit.expand,
            children: [
              _buildProjectImage(rawImage, errorIconSize: 40),
              // Soft scrim so the title stays readable on bright images.
              Container(
                decoration: BoxDecoration(
                  gradient: LinearGradient(
                    begin: Alignment.topCenter,
                    end: Alignment.bottomCenter,
                    stops: const [0.6, 1.0],
                    colors: [
                      Colors.transparent,
                      Colors.black.withValues(alpha: 0.55),
                    ],
                  ),
                ),
              ),
              Positioned(
                left: 18,
                bottom: 16,
                child: Text(
                  (item['title'] ?? item['name'] ?? '')
                      .toString()
                      .toUpperCase(),
                  style: GoogleFonts.dmSerifDisplay(
                    color: Colors.white,
                    fontSize: 12,
                    fontWeight: FontWeight.w600,
                    letterSpacing: 1.5,
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  /// Web-parity property card: image on top (status pill + ARTISTIC
  /// IMPRESSION badge), then title, pinned location and a full-width dark
  /// READ MORE button on a light card surface.
  Widget _buildPropertyCard(dynamic item, String rawImage) {
    final scheme = Theme.of(context).colorScheme;
    final title = (item['title'] ?? item['name'] ?? '').toString();
    final location =
        (item['location'] is Map
                ? item['location']['name']
                : item['location'] ?? '')
            .toString();
    final status = (item['status'] ?? 'Ongoing').toString();

    return _ScaleButton(
      onTap: () => context.push('/projects/${item['_id']}', extra: item),
      child: Container(
        width: MediaQuery.of(context).size.width * 0.68,
        margin: const EdgeInsets.only(right: 16, bottom: 10),
        decoration: BoxDecoration(
          color: scheme.surface,
          borderRadius: BorderRadius.circular(24),
          boxShadow: [
            BoxShadow(
              color: Colors.black.withValues(alpha: 0.1),
              blurRadius: 18,
              offset: const Offset(0, 8),
            ),
          ],
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // 🖼️ Image with badges
            ClipRRect(
              borderRadius: const BorderRadius.vertical(
                top: Radius.circular(24),
              ),
              child: Stack(
                children: [
                  _buildProjectImage(
                    rawImage,
                    height: 180,
                    width: double.infinity,
                    errorIconSize: 40,
                  ),
                  Positioned(
                    top: 12,
                    right: 12,
                    child: Container(
                      padding: const EdgeInsets.symmetric(
                        horizontal: 12,
                        vertical: 6,
                      ),
                      decoration: BoxDecoration(
                        color: Colors.black.withValues(alpha: 0.75),
                        borderRadius: BorderRadius.circular(20),
                      ),
                      child: Text(
                        status.toUpperCase(),
                        style: GoogleFonts.dmSerifDisplay(
                          color: Colors.white,
                          fontSize: 8,
                          fontWeight: FontWeight.w500,
                          letterSpacing: 1,
                        ),
                      ),
                    ),
                  ),
                  Positioned(
                    bottom: 10,
                    right: 10,
                    child: Container(
                      padding: const EdgeInsets.symmetric(
                        horizontal: 8,
                        vertical: 4,
                      ),
                      decoration: BoxDecoration(
                        color: Colors.black.withValues(alpha: 0.55),
                        borderRadius: BorderRadius.circular(4),
                      ),
                      child: Text(
                        'ARTISTIC IMPRESSION',
                        style: GoogleFonts.dmSerifDisplay(
                          color: Colors.white,
                          fontSize: 6.5,
                          fontWeight: FontWeight.w600,
                          letterSpacing: 1.2,
                        ),
                      ),
                    ),
                  ),
                ],
              ),
            ),

            // 📄 Info section
            Padding(
              padding: const EdgeInsets.fromLTRB(16, 14, 16, 16),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    title,
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                    style: GoogleFonts.dmSerifDisplay(
                      color: scheme.onSurface,
                      fontSize: 18,
                      fontWeight: FontWeight.w500,
                    ),
                  ),
                  const SizedBox(height: 6),
                  Row(
                    children: [
                      Icon(
                        LucideIcons.mapPin,
                        size: 12,
                        color: scheme.onSurface.withValues(alpha: 0.55),
                      ),
                      const SizedBox(width: 4),
                      Expanded(
                        child: Text(
                          location.toUpperCase(),
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                          style: GoogleFonts.dmSerifDisplay(
                            color: scheme.onSurface.withValues(alpha: 0.55),
                            fontSize: 10,
                            fontWeight: FontWeight.w500,
                            letterSpacing: 1.5,
                          ),
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 14),
                  Container(
                    width: double.infinity,
                    height: 44,
                    decoration: BoxDecoration(
                      color: scheme.onSurface,
                      borderRadius: BorderRadius.circular(14),
                    ),
                    child: Row(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        Text(
                          'READ MORE',
                          style: GoogleFonts.dmSerifDisplay(
                            color: scheme.surface,
                            fontSize: 10,
                            fontWeight: FontWeight.w600,
                            letterSpacing: 2,
                          ),
                        ),
                        const SizedBox(width: 6),
                        Icon(
                          LucideIcons.chevronRight,
                          size: 14,
                          color: scheme.surface,
                        ),
                      ],
                    ),
                  ),
                ],
              ),
            ),
          ],
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
      color: const Color(0xFF1A1A1A),
      child: Center(
        child: Icon(errorIcon, color: Colors.white24, size: errorIconSize),
      ),
    );

    final src = raw.trim().isEmpty
        ? 'https://images.unsplash.com/photo-1545324418-cc1a3fa10c00?auto=format&fit=crop&q=80'
        : raw.trim();

    if (src.startsWith('assets/')) {
      return Image.asset(
        src,
        key: key,
        width: width,
        height: height,
        fit: fit,
        errorBuilder: (_, __, ___) => errorBox(),
      );
    }

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
    // Web parity: the FEATURED PROPERTY block always renders. When the projects
    // API is unavailable (e.g. a 504 timeout) and nothing is cached, fall back
    // to a bundled brand feature so the section never disappears from home.
    final List<dynamic> featuredList = _projects.isNotEmpty
        ? _projects
        : [
            {
              // Carries an id (and the fields the detail page reads) so READ
              // MORE can actually open it. Without `_id` the button fell
              // through to "switch to the Projects tab" and the card looked
              // dead — the detail screen renders from the `extra` we pass, so
              // this works even though the id isn't a real ObjectId.
              '_id': 'cledor',
              'title': 'Cledor',
              'status': 'Ongoing',
              'location': {'name': 'Mumbai'},
              'description':
                  'CLÉDOR is a thoughtfully designed residential tower that '
                  'blends modern architecture with timeless elegance—crafted '
                  'for those who value refined, future-ready living.',
              'heroImage': 'assets/hero_artistic.jpg',
            },
          ];
    final project = featuredList[_featuredIndex % featuredList.length];
    final isDark = Theme.of(context).brightness == Brightness.dark;

    // Web parity: use the featured project's own description (HTML stripped),
    // falling back to a brand blurb only when the project has none.
    final rawDesc = (project['description'] ?? '')
        .toString()
        .replaceAll(RegExp(r'<[^>]*>'), ' ')
        .replaceAll(RegExp(r'\s+'), ' ')
        .trim();
    final featuredDesc = rawDesc.isNotEmpty
        ? rawDesc
        : 'Live smart at Aura Heights—space-efficient 1 & 2 BHK homes with '
              'curated amenities and rare parking solutions.';

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        // ⭐️ Header (Matched with Our Philosophy)
        Padding(
          padding: const EdgeInsets.symmetric(horizontal: 24),
          child: Text(
            'FEATURED PROPERTY',
            style: GoogleFonts.dmSerifDisplay(
              fontSize: 32,
              fontWeight: FontWeight.w400,
              color: Theme.of(context).colorScheme.onSurface,
              letterSpacing: -0.5,
            ),
          ),
        ),
        const SizedBox(height: 40),

        // ⭐️ Main Artistic Card — the artwork itself opens the project, same as
        // READ MORE below it.
        GestureDetector(
          onTap: () => _openFeatured(project),
          behavior: HitTestBehavior.opaque,
          child: Container(
            margin: const EdgeInsets.symmetric(horizontal: 24),
            decoration: BoxDecoration(
              borderRadius: BorderRadius.circular(50),
              boxShadow: [
                BoxShadow(
                  color: Colors.black.withOpacity(0.2),
                  blurRadius: 40,
                  offset: const Offset(0, 20),
                ),
              ],
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
                        border: Border.all(
                          color: Colors.white.withOpacity(0.2),
                        ),
                      ),
                      child: Text(
                        'ARTISTIC IMPRESSION',
                        style: GoogleFonts.dmSerifDisplay(
                          color: Colors.white,
                          fontSize: 7,
                          fontWeight: FontWeight.w600,
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
                          style: GoogleFonts.dmSerifDisplay(
                            color: const Color(0xFFC5A358),
                            fontSize: 9,
                            fontWeight: FontWeight.w600,
                            letterSpacing: 2.5,
                          ),
                        ),
                        const SizedBox(height: 12),
                        Text(
                          (project['title'] ?? '').toString(),
                          style: GoogleFonts.dmSerifDisplay(
                            color: Colors.white,
                            fontSize: 44,
                            fontWeight: FontWeight.w400,
                            height: 1,
                            letterSpacing: -1,
                          ),
                        ),
                        const SizedBox(height: 16),
                        Text(
                          featuredDesc.toUpperCase(),
                          maxLines: 2,
                          overflow: TextOverflow.ellipsis,
                          style: GoogleFonts.dmSerifDisplay(
                            color: Colors.white.withOpacity(0.8),
                            fontSize: 9,
                            height: 1.6,
                            fontWeight: FontWeight.w600,
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
                      (_featuredIndex - 1 + featuredList.length) %
                      featuredList.length,
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
                  onTap: () => _openFeatured(project),
                  child: Container(
                    height: 56,
                    decoration: BoxDecoration(
                      color: isDark ? Colors.white : Colors.black,
                      borderRadius: BorderRadius.circular(14),
                      boxShadow: [
                        BoxShadow(
                          color: Colors.black.withOpacity(0.2),
                          blurRadius: 20,
                          offset: const Offset(0, 10),
                        ),
                      ],
                    ),
                    child: Center(
                      child: Text(
                        'READ MORE',
                        style: GoogleFonts.dmSerifDisplay(
                          color: isDark ? Colors.black : Colors.white,
                          fontWeight: FontWeight.w600,
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
                  () => _featuredIndex =
                      (_featuredIndex + 1) % featuredList.length,
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
          style: GoogleFonts.dmSerifDisplay(
            color: isDark ? Colors.white : Colors.black,
            fontSize: 9,
            fontWeight: FontWeight.w600,
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
          color: isDark ? Colors.black : Colors.white,
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
          style: GoogleFonts.dmSerifDisplay(
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
            boxShadow: [
              BoxShadow(
                color: Colors.black.withOpacity(0.03),
                blurRadius: 20,
                offset: const Offset(0, 10),
              ),
            ],
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
              style: GoogleFonts.dmSerifDisplay(
                color: isDark ? Colors.white : Colors.black,
                fontWeight: FontWeight.w600,
                fontSize: 10,
                letterSpacing: 1,
              ),
            ),
            const SizedBox(height: 6),
            Text(
              desc,
              textAlign: TextAlign.center,
              style: GoogleFonts.dmSerifDisplay(
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
          style: GoogleFonts.dmSerifDisplay(
            color: isDark ? Colors.white : Colors.black,
            fontSize: 32,
            fontWeight: FontWeight.w400,
            letterSpacing: -1,
            height: 1.1,
          ),
        ),
        const SizedBox(height: 48),
        _buildLuxuryInput(
          'Full Name *',
          _nameController,
          errorText: _nameError,
          // Clear the red state as soon as they start typing.
          onChanged: (v) {
            if (_nameError != null) setState(() => _nameError = null);
          },
        ),
        const SizedBox(height: 16),
        _buildLuxuryInput(
          'Email *',
          _emailController,
          errorText: _emailError,
          onChanged: (v) {
            if (_emailError != null) setState(() => _emailError = null);
          },
        ),
        const SizedBox(height: 16),
        _buildLuxuryInput(
          'Phone Number *',
          _phoneController,
          errorText: _phoneError,
          onChanged: (v) {
            if (_phoneError != null) setState(() => _phoneError = null);
          },
        ),
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
                style: GoogleFonts.dmSerifDisplay(
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
                        style: GoogleFonts.dmSerifDisplay(
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
    // When set, the field turns red and shows the message underneath — keeps
    // validation on the field instead of a snackbar over the page.
    String? errorText,
    ValueChanged<String>? onChanged,
  }) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final hasError = errorText != null;
    const errorColor = Color(0xFFE24B4A);
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Container(
          decoration: BoxDecoration(
            color: isDark ? Colors.black : Colors.white,
            borderRadius: BorderRadius.circular(16),
            border: Border.all(
              color: hasError
                  ? errorColor
                  : (isDark ? Colors.white : Colors.black).withOpacity(0.12),
              width: hasError ? 1.5 : 1,
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
            onChanged: onChanged,
            style: TextStyle(color: isDark ? Colors.white : Colors.black),
            maxLines: isLong ? 5 : 1,
            decoration: InputDecoration(
              hintText: hint,
              hintStyle: GoogleFonts.dmSerifDisplay(
                color: hasError
                    ? errorColor.withOpacity(0.75)
                    : (isDark ? Colors.white54 : Colors.black45),
                fontSize: 13,
              ),
              contentPadding: const EdgeInsets.symmetric(
                horizontal: 24,
                vertical: 20,
              ),
              border: InputBorder.none,
            ),
          ),
        ),
        if (hasError)
          Padding(
            padding: const EdgeInsets.only(left: 10, top: 6),
            child: Text(
              errorText,
              style: GoogleFonts.dmSerifDisplay(
                color: errorColor,
                fontSize: 11,
                fontWeight: FontWeight.w600,
              ),
            ),
          ),
      ],
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
