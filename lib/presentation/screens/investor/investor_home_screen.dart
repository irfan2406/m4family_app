import 'dart:async';
import 'dart:convert';
import 'dart:io';
import 'dart:typed_data';

import 'package:cached_network_image/cached_network_image.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:lucide_icons/lucide_icons.dart';
import 'package:flutter/services.dart';
import 'package:m4_mobile/core/theme/app_theme.dart';
import 'package:m4_mobile/core/utils/api_error.dart';
import 'package:m4_mobile/core/utils/project_highlights.dart';
import 'package:m4_mobile/core/utils/validators.dart';
import 'package:m4_mobile/presentation/providers/auth_provider.dart';
import 'package:m4_mobile/presentation/providers/project_provider.dart';
import 'package:m4_mobile/presentation/providers/investor_shell_provider.dart';
import 'package:m4_mobile/presentation/screens/projects/project_list_screen.dart';
import 'package:m4_mobile/presentation/screens/home/guest_dashboard_screen.dart'
    show guestHomeCacheProvider, GuestHomeData;

/// Mirrors web `app/investor/home/page.tsx`, which renders the same
/// `SharedHomePage` component as the guest/cp home. This is a TAB inside
/// [InvestorMainShell] (which owns the Scaffold + drawer + bottom nav), so this
/// widget returns only the scroll body — the header "..." button calls
/// `Scaffold.of(context).openDrawer()` to open the shell's `InvestorSidebarMenu`.
/// Decoded base64 image bytes, keyed by the raw `data:` URI, so each image is
/// decoded once (not on every rebuild/hero-cycle) — keeps the UI responsive.
final Map<String, Uint8List> _investorB64Cache = {};

class InvestorHomeScreen extends ConsumerStatefulWidget {
  const InvestorHomeScreen({super.key});

  @override
  ConsumerState<InvestorHomeScreen> createState() => _InvestorHomeScreenState();
}

class _InvestorHomeScreenState extends ConsumerState<InvestorHomeScreen> {
  final ScrollController _scrollController = ScrollController();
  final GlobalKey _interestFormKey = GlobalKey();

  int _heroIndex = 0;
  List<dynamic> _projects = [];
  List<dynamic> _communities = [];
  List<dynamic> _media = [];
  bool _loading = true;
  String _activeTab = 'Communities';
  int _featuredIndex = 0;

  // Interest form controllers
  final TextEditingController _nameController = TextEditingController();
  final TextEditingController _emailController = TextEditingController();
  final TextEditingController _phoneController = TextEditingController();
  final TextEditingController _messageController = TextEditingController();
  bool _submitting = false;
  bool _agreedToTerms = false;

  // Inline validation for the "Register your interest" form — the field itself
  // turns red instead of a snackbar popping over the page.
  String? _nameError;
  String? _emailError;
  String? _phoneError;

  Timer? _heroTimer;

  @override
  void initState() {
    super.initState();
    // Show cached content instantly if the home has loaded before (shared with
    // the guest home), then refresh in the background — no blocking spinner.
    final cached = ref.read(guestHomeCacheProvider);
    if (cached != null) {
      _projects = cached.projects;
      _communities = cached.communities;
      _media = cached.media;
      _loading = false;
    }
    _fetchData();
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

  // Renders an image that may be a base64 `data:` URI (how the backend stores
  // images — CachedNetworkImage can't handle those), an http URL, or a
  // relative path. Mirrors the guest home helper.
  // Web parity: JS `||` treats empty strings as missing; Dart `??` does not.
  // The API returns `image: ""` / `heroImage: ""` for some records, so pick the
  // first non-empty candidate (else the fallback) instead of letting "" slip
  // through as "present" and render an empty (placeholder) image.
  static String _pickImage(List<dynamic> candidates, String fallback) {
    for (final c in candidates) {
      final s = (c ?? '').toString().trim();
      if (s.isNotEmpty) return s;
    }
    return fallback;
  }

  Widget _buildProjectImage(
    String raw, {
    Key? key,
    double? width,
    double? height,
    BoxFit fit = BoxFit.cover,
    double errorIconSize = 50,
    Alignment alignment = Alignment.center,
  }) {
    Widget errorBox() => Container(
      color: Colors.white10,
      child: Center(
        child: Icon(
          LucideIcons.image,
          color: Colors.white24,
          size: errorIconSize,
        ),
      ),
    );

    final src = raw.trim();
    if (src.isEmpty) return errorBox();

    if (src.startsWith('assets/')) {
      return Image.asset(
        src,
        key: key,
        width: width,
        height: height,
        fit: fit,
        alignment: alignment,
        errorBuilder: (_, __, ___) => errorBox(),
      );
    }

    if (src.startsWith('data:')) {
      try {
        // Decode each base64 image ONCE (cached) instead of on every rebuild —
        // otherwise the hero's cycling stalls the UI thread and drops taps.
        final bytes = _investorB64Cache.putIfAbsent(
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
          alignment: alignment,
          gaplessPlayback: true,
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
      alignment: alignment,
      placeholder: (c, u) => Container(color: Colors.black12),
      errorWidget: (c, u, e) => errorBox(),
    );
  }

  // Reads the last-known-good projects the guest home persisted to disk, so the
  // Properties tab can show data when the (bloated) projects call 504s.
  Future<List<dynamic>?> _loadCachedProjectsFromDisk() async {
    try {
      final f = File('${Directory.systemTemp.path}/m4_guest_home_cache.json');
      if (!await f.exists()) return null;
      final map = jsonDecode(await f.readAsString());
      final list = map is Map ? map['projects'] : null;
      return (list is List && list.isNotEmpty) ? list : null;
    } catch (_) {
      return null;
    }
  }

  // Shown in the Properties tab when the real projects can't load (the bloated
  // base64 hero image makes GET /projects 504 on a cold cache) so the tab is
  // never blank. Replaced by real data the moment it arrives.
  static final List<Map<String, dynamic>> _placeholderProjects = [
    {
      '_id': 'cledor',
      'title': 'Cledor',
      'location': 'Mumbai',
      'status': 'Ongoing',
      'heroImage': 'assets/cledor_featured.jpg',
      'description':
          'Live smart at Aura Heights—space-efficient 1 & 2 BHK homes with curated amenities and rare parking solutions.',
    },
    {
      '_id': 'skai',
      'title': 'Skai',
      'location': 'Mumbai',
      'status': 'Ongoing',
      'heroImage': 'assets/cledor_interior.jpg',
      'description':
          'Elevated living with panoramic city views and world-class amenities.',
    },
    {
      '_id': 'ocean-view',
      'title': 'Ocean View Residences',
      'location': 'Mumbai',
      'status': 'Completed',
      'heroImage':
          'https://images.unsplash.com/photo-1512917774080-9991f1c4c750?auto=format&fit=crop&q=80',
      'description': 'Where horizon meets home. Coastal elegance redefined.',
    },
  ];

  // Web parity: the MEDIA tab shows real-estate cards over interior/property
  // photos (matching the web), not the project towers only.
  static final List<Map<String, dynamic>> _placeholderMedia = [
    {
      '_id': 'media1',
      'title': 'Ocean View',
      'image': 'assets/hero_artistic.jpg',
    },
    {
      '_id': 'media2',
      'title': 'Ocean View',
      'image': 'assets/custom_view_1.png',
    },
    {
      '_id': 'media3',
      'title': 'Aura Residences',
      'image': 'assets/community_luxury.png',
    },
    {'_id': 'media4', 'title': 'Cledor', 'image': 'assets/cledor_featured.jpg'},
  ];

  Future<void> _fetchData() async {
    final apiClient = ref.read(apiClientProvider);

    // Cold start with no in-memory cache: hydrate projects from the on-disk
    // payload so the Properties tab shows instantly instead of waiting on (and
    // then failing) the slow projects call.
    if (_projects.isEmpty) {
      final cachedProjects = await _loadCachedProjectsFromDisk();
      if (cachedProjects != null && mounted) {
        setState(() {
          _projects = cachedProjects;
          _loading = false;
        });
      }
    }

    // Communities + media are small and reliable — load them first, on their
    // own, so the tabs populate even when the bloated projects call is slow or
    // 504s. (Previously all three shared one Future.wait, so a projects failure
    // discarded the communities/media too.)
    try {
      final results = await Future.wait([
        apiClient.getCommunities(),
        apiClient.getContent('media'),
      ]);

      if (mounted) {
        setState(() {
          _communities = results[0].data['data'] ?? _communities;
          _media = results[1].data['data'] ?? _media;

          // Fill blank space with placeholder media when none returned.
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
          _loading = false;
        });
      }
    } catch (_) {
      if (mounted) setState(() => _loading = false);
    }

    // Projects can be slow / return a 504 (multi-MB base64 hero image) — fetch
    // separately so a failure never wipes the communities/media loaded above.
    // Via the shared projectsProvider: cached + retried + ONE download for the
    // whole app, instead of this screen pulling the multi-MB catalog again.
    try {
      if (ref.read(projectsProvider) is AsyncError) {
        ref.invalidate(projectsProvider);
      }
      final list = await ref.read(projectsProvider.future);
      if (mounted && list.isNotEmpty) setState(() => _projects = list);
    } catch (_) {}

    // Cache whatever we managed to load for an instant next mount.
    if (mounted) {
      ref.read(guestHomeCacheProvider.notifier).state = GuestHomeData(
        projects: _projects,
        communities: _communities,
        media: _media,
      );
    }
  }

  void _scrollToInterestForm() {
    final ctx = _interestFormKey.currentContext;
    if (ctx != null) {
      Scrollable.ensureVisible(
        ctx,
        duration: const Duration(milliseconds: 800),
        curve: Curves.easeInOut,
        alignment: 0.1,
      );
    } else if (_scrollController.hasClients) {
      // Fallback: the Register Interest form sits near the bottom of the page.
      _scrollController.animateTo(
        _scrollController.position.maxScrollExtent,
        duration: const Duration(milliseconds: 800),
        curve: Curves.easeInOut,
      );
    }
  }

  /// Marks the empty required fields red in place. Returns true when valid.
  bool _validateInterest() {
    // Full validation (was empty-check only): name = letters, email = proper
    // format, phone = 10-digit. Errors show in red on each field.
    final nameErr = Validators.nameError(
      _nameController.text,
      field: 'full name',
    );
    final emailErr = Validators.emailError(_emailController.text);
    final phoneErr = Validators.phoneError(_phoneController.text);
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
          backgroundColor: Color(0xFFC65B46),
          content: Text('Please agree to the Privacy Policy'),
        ),
      );
      return;
    }

    setState(() => _submitting = true);
    try {
      final apiClient = ref.read(apiClientProvider);
      final user = ref.read(authProvider).user;
      // `userId` is an ObjectId reference — the old code put the investor's
      // *display name* here ('Investor' / firstName), which made the API reject
      // the whole lead with:
      //   userId: Cast to ObjectId failed for value "Investor" … BSONError
      final investorId = (user?['_id'] ?? user?['id'])?.toString() ?? '';
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
        if (investorId.length == 24) 'userId': investorId,
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
      if (mounted)
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            backgroundColor: const Color(0xFFC65B46),
            // Was 'Submission failed: $e', which printed the whole
            // DioException (status-code explanation, MDN link and all) at the
            // user. The backend sends an empty error body, so translate it.
            content: Text(
              friendlyApiError(
                e,
                fallback:
                    'Could not register your interest. Please check the form and try again.',
              ),
            ),
          ),
        );
    } finally {
      if (mounted) setState(() => _submitting = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    // Sidebar "Enquiry" quick action: scroll the Register Interest form in.
    ref.listen<int>(investorInquiryScrollTriggerProvider, (prev, next) {
      if (next > 0 && (prev == null || next > prev)) {
        // Delay so the drawer close + tab switch settle before scrolling.
        Future.delayed(const Duration(milliseconds: 450), () {
          if (mounted) _scrollToInterestForm();
        });
      }
    });

    if (_loading) {
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
                  fontWeight: FontWeight.w700,
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
    }

    return Material(
      color: Theme.of(context).scaffoldBackgroundColor,
      child: CustomScrollView(
        controller: _scrollController,
        slivers: [
          // HEADER (Web Parity): M4 logo + "..." menu opening the shell drawer.
          SliverAppBar(
            pinned: true,
            toolbarHeight: 120,
            backgroundColor: Theme.of(
              context,
            ).scaffoldBackgroundColor.withValues(alpha: 0.9),
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
                      height: 85,
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
                          color: Theme.of(context).brightness == Brightness.dark ? Colors.white : Theme.of(context).colorScheme.onSurface,
                          size: 24,
                        ),
                      ),
                    ),
                  ),
                ],
              ),
            ),
          ),

          // TAGLINE & HERO SECTION
          SliverToBoxAdapter(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.center,
              children: [
                // Tagline (Living the M4 Life) — script image, not text.
                M4Theme.taglineWordmark(context, height: 120),

                // Hero carousel (4:3, auto-cycle, badge, dots).
                // Was -110, which pulled the hero up until it touched the
                // "Living the M4 Life" logo — leave it breathing room.
                Transform.translate(
                  offset: const Offset(0, 0),
                  child: Padding(
                    padding: const EdgeInsets.symmetric(horizontal: 24),
                    child: Builder(
                      builder: (context) {
                        final heroProject = _projects.isNotEmpty
                            ? _projects[_heroIndex % _projects.length]
                            : null;
                        final mainImage = heroProject != null
                            ? _pickImage([
                                heroProject['heroImage'],
                                heroProject['image'],
                                heroProject['coverImage'],
                              ], 'assets/hero_artistic.jpg')
                            : [
                                'assets/hero_artistic.jpg',
                                'https://images.unsplash.com/photo-1512917774080-9991f1c4c750?auto=format&fit=crop&q=80',
                                'https://images.unsplash.com/photo-1484154218962-a197022b5858?auto=format&fit=crop&q=80',
                              ][_heroIndex % 3];

                        return Stack(
                          children: [
                            AspectRatio(
                              aspectRatio: 4 / 3,
                              child: Container(
                                decoration: BoxDecoration(
                                  borderRadius: BorderRadius.circular(20),
                                  boxShadow: [
                                    BoxShadow(
                                      color: Colors.black.withValues(
                                        alpha: 0.15,
                                      ),
                                      blurRadius: 30,
                                      offset: const Offset(0, 15),
                                    ),
                                  ],
                                ),
                                child: ClipRRect(
                                  borderRadius: BorderRadius.circular(20),
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
                                  color: Colors.black.withValues(alpha: 0.4),
                                  borderRadius: BorderRadius.circular(4),
                                  border: Border.all(
                                    color: Colors.white.withValues(alpha: 0.1),
                                  ),
                                ),
                                child: Text(
                                  'ARTISTIC IMPRESSION',
                                  style: GoogleFonts.gelasio(
                                    color: const Color(0xFFF4EFE3),
                                    fontSize: 9,
                                    fontWeight: FontWeight.w700,
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
                                  final isSelected = (_heroIndex % 3) == index;
                                  return AnimatedContainer(
                                    duration: const Duration(milliseconds: 300),
                                    margin: const EdgeInsets.symmetric(
                                      horizontal: 4,
                                    ),
                                    width: isSelected ? 32 : 24,
                                    height: 4,
                                    decoration: BoxDecoration(
                                      color: isSelected
                                          ? Colors.black
                                          : Colors.white.withValues(alpha: 0.5),
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
          SliverPadding(
            padding: const EdgeInsets.only(bottom: 96),
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
                        const SizedBox(height: 84),
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
                const SizedBox(height: 96),
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
            fontWeight: FontWeight.w600,
            color: Theme.of(context).colorScheme.onSurface,
            letterSpacing: -0.5,
          ),
        ),
        const SizedBox(height: 24),
        RichText(
          text: TextSpan(
            style: GoogleFonts.inter(
              // Was 0.6 — too faint/grey to read. Darker + slightly heavier.
              color: Theme.of(
                context,
              ).colorScheme.onSurface.withValues(alpha: 0.82),
              fontSize: 14,
              fontWeight: FontWeight.w600,
              height: 1.8,
            ),
            children: [
              const TextSpan(
                text:
                    'To redefine modern luxury living by crafting homes with cutting edge design, enduring quality and thoughtful amenities delivered with trust, transparency, timeliness, and a human touch that creates lasting value for every homeowner. ',
              ),
              WidgetSpan(
                child: GestureDetector(
                  onTap: () => context.push('/investor/about'),
                  child: Text(
                    'Who We Are',
                    style: GoogleFonts.inter(
                      color: isDark ? Colors.white : Color(0xFF155A4F),
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
                                    ? (isDark ? Colors.white : Color(0xFF0C312B))
                                    : (isDark ? Colors.white : Color(0xFF0C312B))
                                          .withValues(alpha: 0.72),
                                fontSize: 12,
                                fontWeight: FontWeight.w700,
                                letterSpacing: 2,
                              ),
                            ),
                            const SizedBox(height: 10),
                            if (isSelected)
                              Container(
                                width: 24,
                                height: 2,
                                decoration: BoxDecoration(
                                  color: isDark ? Colors.white : Color(0xFF0C312B),
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
            // Web parity: Properties shows the projects (white info cards);
            // Media shows "Ocean View" living-room boxes; Communities its own
            // list. Projects fall back to placeholders when the projects call
            // 504s / cache is cold, so no tab is ever blank.
            final projectItems = _projects.isNotEmpty
                ? _projects
                : _placeholderProjects;
            final tabItems = _activeTab == 'Communities'
                ? _communities
                : (_activeTab == 'Media' ? _placeholderMedia : projectItems);
            return SizedBox(
              height: 360,
              child: ListView.builder(
                scrollDirection: Axis.horizontal,
                physics: const BouncingScrollPhysics(),
                itemCount: tabItems.length,
                itemBuilder: (context, index) => _buildTabCard(tabItems[index]),
              ),
            );
          },
        ),
      ],
    );
  }

  // Web parity: Properties tab card is a white "info card" — image on top with
  // COMPLETED + ARTISTIC IMPRESSION badges, then a white section with the title,
  // location and a READ MORE button (same as the guest home / web).
  Widget _buildInvestorPropertyCard(dynamic item, String imageUrl) {
    final scheme = Theme.of(context).colorScheme;
    final title = (item['title'] ?? item['name'] ?? '').toString();
    final location =
        (item['location'] is Map
                ? item['location']['name']
                : item['location'] ?? '')
            .toString();
    final status = (item['status'] ?? 'Ongoing').toString();

    return _ScaleButton(
      onTap: () =>
          context.push('/investor/projects/${item['_id']}', extra: item),
      child: Container(
        width: 300,
        margin: const EdgeInsets.only(right: 20, bottom: 10),
        decoration: BoxDecoration(
          color: scheme.surface,
          borderRadius: BorderRadius.circular(24),
          boxShadow: [
            BoxShadow(
              color: Colors.black.withValues(alpha: 0.12),
              blurRadius: 18,
              offset: const Offset(0, 8),
            ),
          ],
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            ClipRRect(
              borderRadius: const BorderRadius.vertical(
                top: Radius.circular(24),
              ),
              child: Stack(
                children: [
                  _buildProjectImage(
                    imageUrl,
                    height: 200,
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
                        style: GoogleFonts.inter(
                          color: const Color(0xFFF4EFE3),
                          fontSize: 10,
                          fontWeight: FontWeight.w600,
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
                        style: GoogleFonts.inter(
                          color: const Color(0xFFF4EFE3),
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
            Padding(
              padding: const EdgeInsets.fromLTRB(16, 14, 16, 16),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    title,
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                    style: GoogleFonts.gelasio(
                      color: scheme.onSurface,
                      fontSize: 20,
                      fontWeight: FontWeight.w600,
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
                          style: GoogleFonts.inter(
                            color: scheme.onSurface.withValues(alpha: 0.55),
                            fontSize: 10,
                            fontWeight: FontWeight.w600,
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
                          style: GoogleFonts.inter(
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

  Widget _buildTabCard(dynamic item) {
    final isCommunity = _activeTab.toLowerCase() == 'communities';
    final isMedia = _activeTab.toLowerCase() == 'media';
    final apiClient = ref.read(apiClientProvider);

    final picked = isCommunity
        ? _pickImage(
            [item['image'], item['heroImage']],
            'https://images.unsplash.com/photo-1486406146926-c627a92ad1ab?auto=format&fit=crop&q=80',
          )
        : (isMedia
              ? _pickImage(
                  [
                    item['thumbnail'],
                    item['image'],
                    item['heroImage'],
                    item['coverImage'],
                  ],
                  'https://images.unsplash.com/photo-1556761175-b413da4baf72?auto=format&fit=crop&q=80',
                )
              : _pickImage(
                  [item['heroImage'], item['image'], item['coverImage']],
                  'https://images.unsplash.com/photo-1613545325278-f24b0cae1224?auto=format&fit=crop&q=80',
                ));
    // Asset paths must bypass resolveUrl (it would prepend the backend host and
    // 404); http/relative paths still resolve normally.
    final imageUrl = picked.startsWith('assets/')
        ? picked
        : apiClient.resolveUrl(picked);

    // Web parity: Properties uses the white info card; Communities/Media keep
    // the full-bleed image-overlay card.
    if (!isCommunity && !isMedia) {
      return _buildInvestorPropertyCard(item, imageUrl);
    }

    return _ScaleButton(
      onTap: () {
        if (isCommunity) {
          context.push('/investor/communities/${item['_id']}', extra: item);
        } else if (isMedia) {
          context.push('/investor/media');
        } else {
          context.push('/investor/projects/${item['_id']}', extra: item);
        }
      },
      child: Container(
        width: 300,
        margin: const EdgeInsets.only(right: 20, bottom: 10),
        decoration: BoxDecoration(
          borderRadius: BorderRadius.circular(isMedia ? 24 : 40),
          boxShadow: [
            BoxShadow(
              color: Colors.black.withValues(alpha: 0.15),
              blurRadius: 20,
              offset: const Offset(0, 10),
            ),
          ],
        ),
        child: ClipRRect(
          borderRadius: BorderRadius.circular(isMedia ? 24 : 40),
          child: Stack(
            fit: StackFit.expand,
            children: [
              // High Resolution Image (Media biases the crop toward the tower)
              _buildProjectImage(
                imageUrl,
                errorIconSize: 40,
                alignment: Alignment.center,
              ),

              // Gradient Overlay — subtle for Media (title only), stronger for
              // Communities (description + action row need more contrast).
              Container(
                decoration: BoxDecoration(
                  gradient: LinearGradient(
                    begin: Alignment.topCenter,
                    end: Alignment.bottomCenter,
                    stops: isMedia ? const [0.55, 1.0] : const [0.3, 1.0],
                    colors: [
                      Colors.transparent,
                      Colors.black.withValues(alpha: isMedia ? 0.6 : 0.85),
                    ],
                  ),
                ),
              ),

              // Content Section
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
                      // Web parity: Media titles are small + letterspaced
                      // (CLEDOR / SKAI); Communities use the large serif.
                      style: isMedia
                          ? GoogleFonts.gelasio(
                              color: const Color(0xFFF4EFE3),
                              fontSize: 14,
                              fontWeight: FontWeight.w700,
                              letterSpacing: 2,
                            )
                          : GoogleFonts.gelasio(
                              color: const Color(0xFFF4EFE3),
                              fontSize: 22,
                              fontWeight: FontWeight.w600,
                              letterSpacing: -0.5,
                            ),
                    ),
                    // Media (web parity): the card shows only the title over
                    // the image + play button. Communities keep the fuller
                    // layout (description + EXPLORE COMMUNITY action row).
                    if (isCommunity) ...[
                      const SizedBox(height: 10),
                      Text(
                        (item['overview'] ?? item['description'] ?? '')
                            .toString()
                            .toUpperCase(),
                        maxLines: 2,
                        overflow: TextOverflow.ellipsis,
                        style: GoogleFonts.inter(
                          // Brighter on the dark card = clearly readable.
                          color: Colors.white.withValues(alpha: 0.92),
                          fontSize: 10.5,
                          fontWeight: FontWeight.w500,
                          letterSpacing: 0.5,
                          height: 1.4,
                        ),
                      ),
                      const SizedBox(height: 24),
                      Row(
                        mainAxisAlignment: MainAxisAlignment.spaceBetween,
                        children: [
                          Text(
                            'EXPLORE COMMUNITY',
                            style: GoogleFonts.inter(
                              color: const Color(0xFFF4EFE3),
                              fontSize: 10,
                              fontWeight: FontWeight.w600,
                              letterSpacing: 1.2,
                            ),
                          ),
                          Container(
                            width: 44,
                            height: 44,
                            decoration: BoxDecoration(
                              color: const Color(0xFFF4EFE3),
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
                  ],
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildFeaturedSection() {
    // Always render — fall back to placeholder projects when the real list is
    // empty (cold cache / 504) so the Featured section matches the web instead
    // of vanishing.
    final featured = _projects.isNotEmpty ? _projects : _placeholderProjects;
    final project = featured[_featuredIndex % featured.length];
    final isDark = Theme.of(context).brightness == Brightness.dark;

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        // Header (Matched with Our Philosophy)
        Padding(
          padding: const EdgeInsets.symmetric(horizontal: 24),
          child: Text(
            'FEATURED PROPERTY',
            style: GoogleFonts.gelasio(
              fontSize: 32,
              fontWeight: FontWeight.w600,
              color: Theme.of(context).colorScheme.onSurface,
              letterSpacing: -0.5,
            ),
          ),
        ),
        const SizedBox(height: 40),

        // Main Artistic Card — tapping the image opens the project (web parity).
        GestureDetector(
          behavior: HitTestBehavior.opaque,
          onTap: () => context.push(
            '/investor/projects/${project['_id']}',
            extra: project,
          ),
          child: Container(
            margin: const EdgeInsets.symmetric(horizontal: 24),
            decoration: BoxDecoration(
              borderRadius: BorderRadius.circular(50),
              boxShadow: [
                BoxShadow(
                  color: Colors.black.withValues(alpha: 0.2),
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
                    _pickImage([
                      project['heroImage'],
                      project['image'],
                      project['coverImage'],
                    ], 'assets/hero_artistic.jpg'),
                    height: 520,
                    width: double.infinity,
                    errorIconSize: 64,
                    // Bias the crop toward the tower (right side) so the featured
                    // card frames the building like the web, not just the ocean.
                    alignment: const Alignment(0.55, 0),
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
                            Colors.black.withValues(alpha: 0.7),
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
                        color: Colors.black.withValues(alpha: 0.6),
                        borderRadius: BorderRadius.circular(4),
                        border: Border.all(
                          color: Colors.white.withValues(alpha: 0.2),
                        ),
                      ),
                      child: Text(
                        'ARTISTIC IMPRESSION',
                        style: GoogleFonts.gelasio(
                          color: const Color(0xFFF4EFE3),
                          fontSize: 9,
                          fontWeight: FontWeight.w700,
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
                            color: const Color(0xFFF4EFE3),
                            fontSize: 11,
                            fontWeight: FontWeight.w700,
                            letterSpacing: 2.5,
                          ),
                        ),
                        const SizedBox(height: 12),
                        Text(
                          (project['title'] ?? '').toString(),
                          // Lighter serif: DM Serif Display ships only weight
                          // 400, so fontWeight can't thin it. Playfair Display
                          // at w400 reads noticeably less bold.
                          style: GoogleFonts.gelasio(
                            // White on the photo: the title sat in black over a dark night render
                            // and was unreadable. A soft shadow keeps it legible on light images too.
                            color: Colors.white,
                            shadows: [
                              Shadow(
                                color: Colors.black.withValues(alpha: 0.45),
                                blurRadius: 12,
                                offset: const Offset(0, 2),
                              ),
                            ],
                            fontSize: 44,
                            fontWeight: FontWeight.w600,
                            height: 1,
                            letterSpacing: -1,
                          ),
                        ),
                        const SizedBox(height: 16),
                        Text(
                          ((project['description'] ?? '')
                                      .toString()
                                      .trim()
                                      .isNotEmpty
                                  ? project['description'].toString()
                                  : 'Live smart at Aura Heights—space-efficient 1 & 2 BHK homes with curated amenities and rare parking solutions.')
                              .toUpperCase(),
                          maxLines: 2,
                          overflow: TextOverflow.ellipsis,
                          style: GoogleFonts.inter(
                            color: Colors.white.withValues(alpha: 0.8),
                            fontSize: 11,
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

        // Feature Icons (Synchronized with Web Grid)
        Padding(
          padding: const EdgeInsets.symmetric(horizontal: 32),
          child: Row(
            // Web parity: USPs come from the featured project's backend
            // `highlights` (e.g. ["Prime Location", "20 min from Airport"]),
            // not a hardcoded pair. Each is Expanded so its label wraps.
            children: [
              for (final h in projectHighlights(project).take(3))
                Expanded(
                  child: _buildFeatureIcon(highlightIcon(h), h.toUpperCase()),
                ),
            ],
          ),
        ),

        const SizedBox(height: 48),

        // Center Navigation (prev / Read More / next)
        Padding(
          padding: const EdgeInsets.symmetric(horizontal: 24),
          child: Row(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              _ScaleButton(
                onTap: () => setState(
                  () => _featuredIndex =
                      (_featuredIndex - 1 + featured.length) % featured.length,
                ),
                child: Container(
                  width: 56,
                  height: 56,
                  decoration: BoxDecoration(
                    color: Colors.transparent,
                    shape: BoxShape.circle,
                    border: Border.all(
                      color: (isDark ? Colors.white : Color(0xFF0C312B)).withValues(
                        alpha: 0.1,
                      ),
                    ),
                  ),
                  child: Icon(
                    LucideIcons.arrowLeft,
                    color: isDark ? Colors.white : Color(0xFF0C312B),
                    size: 20,
                  ),
                ),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: _ScaleButton(
                  onTap: () => context.push(
                    '/investor/projects/${project['_id']}',
                    extra: project,
                  ),
                  child: Container(
                    height: 56,
                    decoration: BoxDecoration(
                      color: isDark ? Colors.white : Color(0xFF0C312B),
                      borderRadius: BorderRadius.circular(14),
                      boxShadow: [
                        BoxShadow(
                          color: Colors.black.withValues(alpha: 0.2),
                          blurRadius: 20,
                          offset: const Offset(0, 10),
                        ),
                      ],
                    ),
                    child: Center(
                      child: Text(
                        'READ MORE',
                        style: GoogleFonts.gelasio(
                          color: isDark ? const Color(0xFF1C4535) : const Color(0xFFF4EFE3),
                          fontWeight: FontWeight.w700,
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
                  () => _featuredIndex = (_featuredIndex + 1) % featured.length,
                ),
                child: Container(
                  width: 56,
                  height: 56,
                  decoration: BoxDecoration(
                    color: Colors.transparent,
                    shape: BoxShape.circle,
                    border: Border.all(
                      color: (isDark ? Colors.white : Color(0xFF0C312B)).withValues(
                        alpha: 0.1,
                      ),
                    ),
                  ),
                  child: Icon(
                    LucideIcons.arrowRight,
                    color: isDark ? Colors.white : Color(0xFF0C312B),
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
        Icon(icon, color: isDark ? Colors.white : Color(0xFF0C312B), size: 24),
        const SizedBox(height: 8),
        Text(
          label,
          textAlign: TextAlign.center,
          style: GoogleFonts.gelasio(
            color: isDark ? Colors.white : Color(0xFF0C312B),
            fontSize: 11,
            fontWeight: FontWeight.w700,
            letterSpacing: 1.5,
          ),
        ),
      ],
    );
  }

  Widget _buildConnectGrid() {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        // Header (Matched with Register Interest)
        Text(
          'EXPLORE, CONNECT\nAND ENGAGE WITH US',
          style: GoogleFonts.gelasio(
            fontSize: 32,
            fontWeight: FontWeight.w600,
            color: Theme.of(context).colorScheme.onSurface,
            letterSpacing: -1,
            height: 1.1,
          ),
        ),
        const SizedBox(height: 40),

        // Unified Grid Card
        Container(
          decoration: BoxDecoration(
            color: isDark
                ? Colors.white.withValues(alpha: 0.03)
                : Colors.black.withValues(alpha: 0.02),
            borderRadius: BorderRadius.circular(20),
            border: Border.all(
              color: (isDark ? Colors.white : Color(0xFF0C312B)).withValues(
                alpha: 0.08,
              ),
            ),
            boxShadow: [
              BoxShadow(
                color: Colors.black.withValues(alpha: 0.03),
                blurRadius: 20,
                offset: const Offset(0, 10),
              ),
            ],
          ),
          child: ClipRRect(
            borderRadius: BorderRadius.circular(20),
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
                      builder: (context) => Theme(
                        data: M4Theme.darkTheme,
                        child: const ProjectListScreen(),
                      ),
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
                  () => context.push('/investor/media'),
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
                color: (isDark ? Colors.white : Color(0xFF0C312B)).withValues(
                  alpha: 0.05,
                ),
                shape: BoxShape.circle,
                border: Border.all(
                  color: (isDark ? Colors.white : Color(0xFF0C312B)).withValues(
                    alpha: 0.1,
                  ),
                ),
              ),
              child: Icon(
                icon,
                color: isDark ? Colors.white : Color(0xFF0C312B),
                size: 20,
              ),
            ),
            const SizedBox(height: 16),
            Text(
              title,
              textAlign: TextAlign.center,
              style: GoogleFonts.inter(
                color: isDark ? Colors.white : Color(0xFF155A4F),
                fontWeight: FontWeight.w600,
                fontSize: 13,
                letterSpacing: 1,
              ),
            ),
            const SizedBox(height: 6),
            Text(
              desc,
              textAlign: TextAlign.center,
              style: GoogleFonts.inter(
                color: (isDark ? Colors.white : Color(0xFF0C312B)).withValues(
                  alpha: 0.5,
                ),
                fontSize: 11,
                fontWeight: FontWeight.w600,
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
          'REGISTER\nINTEREST',
          style: GoogleFonts.gelasio(
            color: isDark ? Colors.white : Color(0xFF0C312B),
            fontSize: 32,
            fontWeight: FontWeight.w600,
            letterSpacing: -1,
            height: 1.1,
          ),
        ),
        const SizedBox(height: 48),
        _buildLuxuryInput(
          'Full Name *',
          _nameController,
          keyboardType: TextInputType.name,
          inputFormatters: Validators.nameFormatters,
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
          keyboardType: TextInputType.emailAddress,
          inputFormatters: Validators.emailFormatters,
          errorText: _emailError,
          onChanged: (v) {
            if (_emailError != null) setState(() => _emailError = null);
          },
        ),
        const SizedBox(height: 16),
        _buildLuxuryInput(
          'Phone Number *',
          _phoneController,
          keyboardType: TextInputType.phone,
          inputFormatters: Validators.phoneFormatters,
          hint: '+91 98653 21250 *',
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
              activeColor: isDark ? Colors.white : Color(0xFF0C312B),
              checkColor: isDark ? Colors.black : const Color(0xFFF4EFE3),
              side: BorderSide(color: isDark ? Colors.white24 : Colors.black26),
            ),
            Expanded(
              child: RichText(
                text: TextSpan(
                  style: GoogleFonts.inter(
                    color: isDark ? Colors.white54 : Color(0xFF155A4F),
                    fontSize: 11,
                    letterSpacing: 0.8,
                    height: 1.4,
                  ),
                  children: [
                    const TextSpan(text: "I'VE READ AND AGREE TO THE "),
                    TextSpan(
                      text: 'PRIVACY POLICY',
                      style: GoogleFonts.inter(
                        color: isDark ? Colors.white : Color(0xFF155A4F),
                        fontSize: 11,
                        fontWeight: FontWeight.w600,
                        letterSpacing: 0.8,
                        decoration: TextDecoration.underline,
                      ),
                    ),
                    const TextSpan(text: '.'),
                  ],
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
                color: isDark ? Colors.white : const Color(0xFF0C312B),
                borderRadius: BorderRadius.circular(16),
              ),
              child: Center(
                child: _submitting
                    ? CircularProgressIndicator(
                        color: isDark ? Colors.black : const Color(0xFFF4EFE3),
                      )
                    : Text(
                        'SUBMIT INTEREST',
                        style: GoogleFonts.inter(
                          color: isDark ? Colors.black : const Color(0xFFF4EFE3),
                          fontWeight: FontWeight.w600,
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
    String label,
    TextEditingController controller, {
    bool isLong = false,
    TextInputType? keyboardType,
    List<TextInputFormatter>? inputFormatters,
    String? hint,
    // When set, the field turns red and shows the message underneath — keeps
    // validation on the field instead of a snackbar over the page.
    String? errorText,
    ValueChanged<String>? onChanged,
  }) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final hasError = errorText != null;
    const errorColor = Color(0xFFC65B46);
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Container(
          decoration: BoxDecoration(
            // Same fill the guest form uses: a translucent white lift over the
            // green showcase rather than a solid mid-green, so the field reads
            // identically in both portals.
            color: isDark
                ? Colors.white.withValues(alpha: 0.08)
                : const Color(0xFFF4EFE3),
            borderRadius: BorderRadius.circular(16),
            border: Border.all(
              color: hasError
                  ? errorColor
                  : (isDark ? Colors.white : Color(0xFF0C312B)).withValues(
                      alpha: 0.12,
                    ),
              width: hasError ? 1.5 : 1,
            ),
            boxShadow: isDark
                ? []
                : [
                    BoxShadow(
                      color: Colors.black.withValues(alpha: 0.05),
                      blurRadius: 20,
                      offset: const Offset(0, 10),
                    ),
                  ],
          ),
          child: TextField(
            cursorColor: Theme.of(context).brightness == Brightness.dark ? Colors.white : Theme.of(context).colorScheme.onSurface,
            controller: controller,
            keyboardType: keyboardType,
            inputFormatters: inputFormatters,
            onChanged: onChanged,
            style: TextStyle(color: isDark ? Colors.white : Color(0xFF0C312B)),
            maxLines: isLong ? 5 : 1,
            decoration: InputDecoration(
              hintText: hint ?? label,
              hintStyle: GoogleFonts.inter(
                color: hasError
                    ? errorColor.withValues(alpha: 0.75)
                    : (isDark ? Colors.white54 : Colors.black45),
                fontSize: 13,
              ),
              contentPadding: const EdgeInsets.symmetric(
                horizontal: 24,
                vertical: 20,
              ),
              filled: false,
              border: InputBorder.none,
              enabledBorder: InputBorder.none,
              focusedBorder: InputBorder.none,
            ),
          ),
        ),
        if (hasError)
          Padding(
            padding: const EdgeInsets.only(left: 10, top: 6),
            child: Text(
              errorText,
              style: GoogleFonts.inter(
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
