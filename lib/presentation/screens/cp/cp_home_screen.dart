import 'dart:async';
import 'dart:convert';

import 'package:dio/dio.dart';

import 'package:cached_network_image/cached_network_image.dart';
import 'package:flutter/material.dart';
import 'package:m4_mobile/presentation/widgets/image_loading_shimmer.dart';
import 'package:m4_mobile/core/utils/media_url.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:m4_mobile/presentation/providers/live_sync_provider.dart';
import 'package:go_router/go_router.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:lucide_icons/lucide_icons.dart';
import 'package:flutter/services.dart';
import 'package:m4_mobile/core/theme/app_theme.dart';
import 'package:m4_mobile/core/utils/project_highlights.dart';
import 'package:m4_mobile/core/utils/validators.dart';
import 'package:m4_mobile/core/utils/image_prewarm.dart';
import 'package:m4_mobile/core/utils/media_url.dart';
import 'package:m4_mobile/presentation/providers/auth_provider.dart';
import 'package:m4_mobile/presentation/providers/hero_slider_provider.dart';
import 'package:m4_mobile/presentation/providers/project_provider.dart';
import 'package:m4_mobile/presentation/providers/cp_shell_provider.dart';
import 'package:m4_mobile/presentation/screens/projects/project_list_screen.dart';
import 'package:m4_mobile/presentation/widgets/image_overlay_label.dart';
import 'package:m4_mobile/presentation/widgets/home_image_card.dart';

/// Mirrors web `app/(cp)/cp/home/page.tsx`, which renders the same
/// `SharedHomePage` component as the guest/user home. This is a TAB inside
/// [CpMainShell] (which owns the Scaffold + drawer + bottom nav), so this
/// widget returns only the scroll body — the header "..." button calls
/// `Scaffold.of(context).openDrawer()` to open the shell's `CpSidebarMenu`.
class CpHomeScreen extends ConsumerStatefulWidget {
  const CpHomeScreen({super.key});

  @override
  ConsumerState<CpHomeScreen> createState() => _CpHomeScreenState();
}

class _CpHomeScreenState extends ConsumerState<CpHomeScreen> {
  final ScrollController _scrollController = ScrollController();
  final GlobalKey _interestFormKey = GlobalKey();

  int _heroIndex = 0;

  /// Hero slides the Admin Panel controls (`GET /api/config` ->
  /// heroSliderImages). Empty means this dashboard keeps its own catalog/asset
  /// slides, which is also what an offline start gets.
  List<HeroSlide> get _adminHeroSlides =>
      ref.read(heroSliderProvider).asData?.value ?? const <HeroSlide>[];

  /// How many slides the hero cycles. The admin set decides it when there is
  /// one; otherwise it stays the three the carousel was built around.
  int get _heroSlideCount {
    final slides = ref.read(heroSliderProvider).asData?.value;
    return (slides != null && slides.isNotEmpty) ? slides.length : 3;
  }

  /// The admin slide for the current index, or null to fall back.
  String? get _adminHeroImage {
    final slides = ref.read(heroSliderProvider).asData?.value;
    if (slides == null || slides.isEmpty) return null;
    return slides[_heroIndex % slides.length].url;
  }

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

  // Inline validation for the partner interest form — errors live on the field
  // itself instead of a toast over the page.
  String? _nameError;
  String? _emailError;
  String? _phoneError;
  bool _termsError = false;

  Timer? _heroTimer;

  @override
  void initState() {
    super.initState();
    _fetchData();
    _heroTimer = Timer.periodic(const Duration(seconds: 5), (timer) {
      // Also cycles when only the admin slider has loaded — that carousel does
      // not need the project catalog.
      if (mounted && (_projects.isNotEmpty || _adminHeroSlides.isNotEmpty)) {
        // The admin slides when there are any, else the featured project's
        // three media slides, matching web.
        setState(() => _heroIndex = (_heroIndex + 1) % _heroSlideCount);
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

  Future<void> _fetchData() async {
    try {
      final apiClient = ref.read(apiClientProvider);
      // Projects go through the shared projectsProvider rather than a bare
      // getProjects(): it caches the multi-MB catalog (so re-entering the CP
      // portal is instant), retries cold-start timeouts, and shares ONE
      // download with the other screens instead of re-fetching per screen.
      if (ref.read(projectsProvider) is AsyncError) {
        ref.invalidate(projectsProvider);
      }
      final projectsFuture = ref.read(projectsProvider.future);
      final communitiesFuture = apiClient.getCommunities();
      final mediaFuture = apiClient.getContent('media', role: 'cp');
      // Awaited independently. Both used to sit under one try, so when the
      // projects call failed (it is the bloated multi-MB catalog and can time
      // out) the already-successful communities response was discarded with it
      // and the Communities tab rendered empty.
      List<dynamic> projects = const [];
      try {
        projects = await projectsFuture;
      } catch (_) {
        projects = const [];
      }
      List<dynamic> communities = const [];
      try {
        final communitiesRes = await communitiesFuture;
        communities = communitiesRes.data['data'] ?? const [];
      } catch (_) {
        communities = const [];
      }
      // The Media tab is the admin's media library, the same feed the guest
      // and investor homes read. It used to be faked by flattening every
      // project's hero photos into "media" items, so the tab showed building
      // shots captioned with project names instead of published articles.
      List<dynamic> media = const [];
      try {
        final mediaRes = await mediaFuture;
        media = mediaRes.data['data'] ?? const [];
      } catch (_) {
        media = const [];
      }

      if (mounted) {
        setState(() {
          _projects = projects;
          _communities = communities;

          _media = media;
          _loading = false;
        });
        _prewarmHomeImages();
      }
    } catch (e) {
      if (mounted) setState(() => _loading = false);
    }
  }

  /// Warms the shared image cache with the first cards' hero photos as soon as
  /// projects arrive. The backend's originals are several MB each, so starting
  /// the download here means the cards paint from disk instead of waiting on
  /// the network when scrolled into view.
  void _prewarmHomeImages() {
    final api = ref.read(apiClientProvider);
    final urls = <String>[];
    for (final p in _projects.take(4)) {
      if (p is! Map) continue;
      // The card shows the Project Master Image (`heroImage`) only.
      final hero = projectHeroUrl(p);
      if (hero.isNotEmpty) urls.add(api.resolveUrl(hero));
    }
    prewarmImages(urls);
  }

  void _scrollToInterestForm() {
    final ctx = _interestFormKey.currentContext;
    if (ctx != null) {
      Scrollable.ensureVisible(
        ctx,
        duration: const Duration(seconds: 1),
        curve: Curves.easeInOut,
      );
    }
  }

  /// Validates in place: every problem is shown ON the field it belongs to
  /// (red border + message) rather than as a toast over the page.
  bool _validateInterest() {
    // Shared rules: name = letters only, email = proper format, phone = 10-digit.
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
      _termsError = !_agreedToTerms;
    });
    return nameErr == null &&
        emailErr == null &&
        phoneErr == null &&
        _agreedToTerms;
  }

  Future<void> _submitInterest() async {
    if (!_validateInterest()) return;
    final name = _nameController.text.trim();
    final email = _emailController.text.trim();
    final phone = _phoneController.text.trim();

    setState(() => _submitting = true);
    try {
      final apiClient = ref.read(apiClientProvider);
      final user = ref.read(authProvider).user;
      // `userId` is an ObjectId reference. The old code put the partner's
      // *display name* here ('Partner' / firstName / companyName), which made
      // the API reject the entire lead with:
      //   userId: Cast to ObjectId failed for value "Partner" … BSONError
      // Send the real id, and only when it actually looks like one.
      final partnerId = (user?['_id'] ?? user?['id'])?.toString() ?? '';
      await apiClient.submitLead({
        'name': name,
        'email': email,
        'phone': phone,
        'message': _messageController.text.trim(),
        // Server-side enums: interest = Buying | Selling | Site Visit | Video
        // Call (case-sensitive); source = online | cp | walk-in | referral |
        // other. Anything else is rejected with a 400.
        'interest': 'Buying',
        'source': 'cp',
        if (partnerId.length == 24) 'userId': partnerId,
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
      if (!mounted) return;
      // Surface the API's own reason; a raw DioException dump filled the screen
      // and told the user nothing.
      String msg = 'Could not submit right now. Please try again.';
      if (e is DioException) {
        final data = e.response?.data;
        if (data is Map && data['message'] != null) {
          msg = data['message'].toString();
        } else if (e.type == DioExceptionType.connectionError ||
            e.type == DioExceptionType.connectionTimeout ||
            e.type == DioExceptionType.receiveTimeout) {
          msg = 'Connection problem. Please try again.';
        }
      }
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(msg),
          backgroundColor: const Color(0xFFC65B46),
          behavior: SnackBarBehavior.floating,
        ),
      );
    } finally {
      if (mounted) setState(() => _submitting = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    // Admin edits: reload in place when the server reports a change.
    listenForAdminChanges(
      ref,
      const {SyncTopic.catalog, SyncTopic.content, SyncTopic.communities},
      _fetchData,
    );
    // Sidebar quick action: scroll partner inquiry into view.
    // The hero reads the admin slider through [_adminHeroImage], which uses
    // ref.read so the cycling timer can call it too. Watch it here so the page
    // still rebuilds when the config lands.
    ref.watch(heroSliderProvider);
    ref.listen<int>(cpInquiryScrollTriggerProvider, (prev, next) {
      if (next > 0 && (prev == null || next > prev)) {
        WidgetsBinding.instance.addPostFrameCallback(
          (_) => _scrollToInterestForm(),
        );
      }
    });

    if (_loading) {
      return Material(
        color: Theme.of(context).scaffoldBackgroundColor,
        child: Center(
          child: CircularProgressIndicator.adaptive(
            valueColor: AlwaysStoppedAnimation<Color>(
              M4Theme.loaderGreen(context),
            ),
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
                          color: Theme.of(context).brightness == Brightness.dark
                              ? Colors.white
                              : Theme.of(context).colorScheme.onSurface,
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
                // Guest parity: natural flow with a small top gap (no -50
                // translate), so it never touches the logo or the hero.
                Padding(
                  padding: const EdgeInsets.only(top: 12, bottom: 8),
                  child: M4Theme.taglineWordmark(context, height: 120),
                ),

                // Hero carousel (4:3, auto-cycle, badge, dots). Guest parity:
                // natural flow (no OverflowBox / -110 translate / box shrink) so
                // spacing above (tagline) and below (tabs) matches the guest home.
                Padding(
                  padding: const EdgeInsets.symmetric(horizontal: 24),
                  child: Builder(
                    builder: (context) {
                      // Web parity: the hero cycles the FEATURED
                      // project's 3 media slides, not different projects.
                      final featured = _projects.isNotEmpty
                          ? _projects[0]
                          : null;
                      // Admin Panel slider first, the featured project's media
                      // second.
                      final mainImage =
                          _adminHeroImage ?? _getImg(featured, _heroIndex % 3);

                      return Stack(
                        children: [
                          AspectRatio(
                            aspectRatio: 16 / 9,
                            child: Container(
                              decoration: BoxDecoration(
                                borderRadius: BorderRadius.circular(16),
                                boxShadow: [
                                  BoxShadow(
                                    color: Colors.black.withValues(alpha: 0.15),
                                    blurRadius: 30,
                                    offset: const Offset(0, 15),
                                  ),
                                ],
                              ),
                              child: ClipRRect(
                                borderRadius: BorderRadius.circular(16),
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

                          // Play tour button — only the first slide is
                          // the "video" (web parity). An admin slide is plain
                          // artwork, so it does not get one.
                          if (_adminHeroSlides.isEmpty && (_heroIndex % 3) == 0)
                            Positioned.fill(
                              child: Center(
                                child: Container(
                                  width: 56,
                                  height: 56,
                                  decoration: BoxDecoration(
                                    color: Colors.white.withValues(alpha: 0.3),
                                    shape: BoxShape.circle,
                                    border: Border.all(
                                      color: Colors.white.withValues(
                                        alpha: 0.6,
                                      ),
                                      width: 1.5,
                                    ),
                                  ),
                                  child: const Icon(
                                    LucideIcons.play,
                                    color: Colors.white,
                                    size: 22,
                                  ),
                                ),
                              ),
                            ),

                          // Artistic Impression Badge
                          Positioned(
                            top: 16,
                            right: 16,
                            child: ImageOverlayLabel(
                              builder: (label) => Container(
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
                                child: FittedBox(
                                  fit: BoxFit.scaleDown,
                                  child: Text(
                                    label,
                                    maxLines: 1,
                                    style: GoogleFonts.gelasio(
                                      color: Colors.white,
                                      fontSize: 7,
                                      fontWeight: FontWeight.w700,
                                      letterSpacing: 1.5,
                                    ),
                                  ),
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
                              children: List.generate(_heroSlideCount, (index) {
                                final isSelected =
                                    (_heroIndex % _heroSlideCount) == index;
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
              ],
            ),
          ),
          SliverPadding(
            padding: const EdgeInsets.only(bottom: 96),
            sliver: SliverList(
              delegate: SliverChildListDelegate([
                Padding(
                  // Guest parity: 40px top gap so the tabs sit below the hero
                  // with breathing room (was flush against the image).
                  padding: const EdgeInsets.fromLTRB(24, 40, 24, 0),
                  child: _buildTabsSection(),
                ),
                const SizedBox(height: 12),
                Padding(
                  padding: const EdgeInsets.symmetric(horizontal: 24),
                  child: _buildPhilosophy(),
                ),
                if (_projects.any(
                  (p) =>
                      p is Map &&
                      (p['featured'] == true ||
                          p['featured']?.toString().toLowerCase() == 'true'),
                )) ...[
                  const SizedBox(height: 40),
                  _buildFeaturedSection(),
                ],
                const SizedBox(height: 12),
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

  /// Mirrors web `getImg(p, idx)`: prefer `heroImages[idx]`, then (for the first
  /// slide only) `heroImage`. Backend-driven: with no image the caller gets an
  /// empty string and renders the branded placeholder (no stock photo).
  /// The card image for a project.
  ///
  /// Always the Project Master Image via [projectHeroUrl]: the `heroImages`
  /// gallery [idx] used to rotate through held demo stock photos and has
  /// been removed from every project.
  String _getImg(dynamic p, [int idx = 0]) {
    if (p is! Map) return '';
    return projectHeroUrl(p);
  }

  /// Web `value || fallback` semantics: null, empty, or whitespace -> fallback.
  /// (Dart's `??` only catches null, so empty-string image fields — e.g. a
  /// community with `image: ""` — slipped through to the wrong fallback.)
  String _imgOr(dynamic value, String fallback) {
    final s = value?.toString().trim() ?? '';
    return s.isEmpty ? fallback : s;
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
    bool fill = false,
  }) {
    Widget errorBox() => Container(
      color: const Color(0xFF1C4535),
      child: Center(
        child: Icon(errorIcon, color: Colors.white24, size: errorIconSize),
      ),
    );

    // Backend-driven: no image URL -> branded placeholder, never a stock photo.
    final src = raw.trim();
    if (src.isEmpty) return errorBox();
    // PNG/SVG logos -> contain (full), JPEG photos -> cover (fill).
    // [fill]: always fill the frame (the image cards), even for a PNG,
    // which would otherwise be shown whole as if it were a logo.
    final effFit = !fill && fit == BoxFit.cover ? fitForMediaUrl(src) : fit;

    if (src.startsWith('data:')) {
      try {
        final base64Str = src
            .substring(src.indexOf(',') + 1)
            .replaceAll(RegExp(r'\s'), '');
        final bytes = base64Decode(base64Str);
        return Image.memory(
          bytes,
          cacheWidth: 1080,
          key: key,
          width: width,
          height: height,
          fit: effFit,
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
      fadeInDuration: Duration.zero,
      fadeOutDuration: Duration.zero,
      memCacheWidth: 1080,
      // Backend serves multi-MB originals; cache a downscaled copy on disk to
      // bound memory and make repeat views instant.
      maxWidthDiskCache: 1600,
      maxHeightDiskCache: 1600,
      key: key,
      imageUrl: url,
      width: width,
      height: height,
      fit: effFit,
      placeholder: (context, u) => const ImageLoadingShimmer(),
      errorWidget: (context, u, e) => errorBox(),
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
        const SizedBox(height: 8),
        RichText(
          // Natural word spacing, deliberately not justified: on a phone
          // width justify stretched the gaps between words very wide.
          text: TextSpan(
            style: GoogleFonts.inter(
              color: Theme.of(
                context,
              ).colorScheme.onSurface.withValues(alpha: 0.6),
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
                  onTap: () => context.push('/cp/about'),
                  child: Text(
                    'Who We Are',
                    style: GoogleFonts.inter(
                      color: isDark ? Colors.white : const Color(0xFF155A4F),
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

  /// The rows behind whichever tab is selected. Was inlined twice in the
  /// list below — once for the count, once for the item — which is what let
  /// an empty list fall through to a blank strip unnoticed.
  List<dynamic> get _activeTabItems => _activeTab == 'Communities'
      ? _communities
      : (_activeTab == 'Media' ? _media : _projects);

  /// Drawn in place of the card strip when the active tab has no rows. The
  /// backend returning an empty list is a normal state, not a failure, so it
  /// says so in the page's own palette rather than leaving dead space.
  Widget _buildTabEmpty(bool isDark) {
    final Color ink = isDark
        ? const Color(0xFFF4EFE3)
        : const Color(0xFF0C312B);

    final (IconData icon, String title, String line) = switch (_activeTab) {
      'Communities' => (
        LucideIcons.mapPin,
        'NO COMMUNITIES YET',
        'Communities will appear here once they are published.',
      ),
      'Media' => (
        LucideIcons.image,
        'NO MEDIA YET',
        'Films and renders will appear here once they are published.',
      ),
      _ => (
        LucideIcons.layoutGrid,
        'NO PROPERTIES YET',
        'Properties will appear here once they are published.',
      ),
    };

    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 44),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          Container(
            width: 86,
            height: 86,
            alignment: Alignment.center,
            decoration: BoxDecoration(
              color: ink.withValues(alpha: 0.05),
              shape: BoxShape.circle,
              border: Border.all(color: ink.withValues(alpha: 0.08)),
            ),
            child: Icon(icon, size: 30, color: ink.withValues(alpha: 0.35)),
          ),
          const SizedBox(height: 26),
          Text(
            title,
            textAlign: TextAlign.center,
            maxLines: 2,
            overflow: TextOverflow.ellipsis,
            style: GoogleFonts.gelasio(
              fontSize: 11,
              fontWeight: FontWeight.w700,
              letterSpacing: 2,
              color: ink.withValues(alpha: 0.85),
            ),
          ),
          const SizedBox(height: 10),
          Text(
            line,
            textAlign: TextAlign.center,
            maxLines: 3,
            overflow: TextOverflow.ellipsis,
            style: GoogleFonts.inter(
              fontSize: 12,
              fontWeight: FontWeight.w500,
              color: ink.withValues(alpha: 0.5),
            ),
          ),
        ],
      ),
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
                                    ? (isDark
                                          ? Colors.white
                                          : const Color(0xFF0C312B))
                                    : (isDark
                                              ? Colors.white
                                              : const Color(0xFF0C312B))
                                          .withValues(alpha: 0.68),
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
                                  color: isDark
                                      ? Colors.white
                                      : const Color(0xFF0C312B),
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
        if (_activeTabItems.isEmpty)
          _buildTabEmpty(isDark)
        else
          SizedBox(
            // Media tiles are landscape (wider than tall); Communities and
            // Properties keep their portrait cards, so the row height follows
            // the active tab. 230 leaves the tile 220 tall after its 10 bottom
            // margin — the overlay needs ~160 from the bottom (title, location,
            // the 44 circle) and ~45 for the badge at the top, so anything
            // shorter makes the two collide.
            // Every tab draws the same full-bleed 16:9 tile (320 wide -> 180
            // tall) plus the card's 10dp bottom margin.
            // Every tab draws the same card: picture plus name panel.
            height: HomeImageCard.rowHeight,
            child: ListView.builder(
              scrollDirection: Axis.horizontal,
              physics: const BouncingScrollPhysics(),
              itemCount: _activeTabItems.length,
              itemBuilder: (context, index) =>
                  _buildTabCard(_activeTabItems[index]),
            ),
          ),
      ],
    );
  }

  Widget _buildTabCard(dynamic item) {
    final isCommunity = _activeTab.toLowerCase() == 'communities';
    final isMedia = _activeTab.toLowerCase() == 'media';

    // Properties use the web's distinct "image on top + content panel" card.
    if (!isCommunity && !isMedia) {
      return _buildPropertyCard(item);
    }

    // Community/media only (properties return early above). Backend-driven:
    // empty image fields render the branded placeholder, not stock.
    // Stock-filtered: the catalog seeds `thumbnail` with Unsplash, so a media
    // tile handed a project record used to show stock.
    final rawImage = (isCommunity
            ? [mediaUrlOf(item['image'])]
            : [mediaUrlOf(item['thumbnail']), mediaUrlOf(item['image'])])
        .firstWhere(
          (u) => u.isNotEmpty && !isStockImageUrl(u),
          orElse: () => '',
        );

    // Guest parity: Media is the plain gallery tile (image + title), the same
    // card the Guest home draws.
    if (isMedia) return _buildMediaCard(item, rawImage);

    // Communities only (Media and Properties returned above): the clean
    // picture with the name and arrow on a panel beneath it, the same card
    // on every portal's home.
    return _ScaleButton(
      onTap: () => context.push('/cp/communities/${item['_id']}', extra: item),
      child: HomeImageCard(
        image: (fit) => _buildProjectImage(
          rawImage,
          errorIconSize: 40,
          fit: fit,
          fill: true,
        ),
        title: (item['title'] ?? item['name'] ?? '').toString(),
      ),
    );
  }

  /// Guest-parity media card: the full-bleed 16:9 image with just the title in
  /// small white caps at the bottom-left — the same card the Guest home draws.
  Widget _buildMediaCard(dynamic item, String rawImage) {
    return _ScaleButton(
      onTap: () => context.push('/cp/media'),
      child: HomeImageCard(
        image: (fit) => _buildProjectImage(
          rawImage,
          errorIconSize: 40,
          fit: fit,
          fill: true,
        ),
        title: (item['title'] ?? item['name'] ?? '').toString(),
      ),
    );
  }

  /// Web-parity property card: a full-bleed 16:9 photo with the status pill
  /// top-right and the project name, locality and a round arrow over the bottom
  /// of the image — the same shape the Communities and Media tiles use. It used
  /// to be a photo above a light info panel with a full-width READ MORE button,
  /// which the web does not have.
  Widget _buildPropertyCard(dynamic item) {
    final title = (item['title'] ?? item['name'] ?? '').toString();
    final status = (item['status']?.toString() ?? 'ONGOING').toUpperCase();
    final location =
        (item['location'] is Map
                ? (item['location']['name'] ?? 'MUMBAI')
                : (item['location'] ?? 'MUMBAI'))
            .toString()
            .toUpperCase();
    final rawImage = _getImg(item, 0);

    return _ScaleButton(
      onTap: () => context.push('/cp/projects/${item['_id']}', extra: item),
      child: HomeImageCard(
        image: (fit) => _buildProjectImage(
          rawImage,
          errorIconSize: 40,
          fit: fit,
          fill: true,
        ),
        title: title,
        caption: location,
        tags: [status],
      ),
    );
  }

  Widget _buildFeaturedSection() {
    // Backend-driven: only projects explicitly flagged `featured` appear here;
    // nothing shows when none are flagged (no default project).
    final featuredList = _projects
        .where(
          (p) =>
              p is Map &&
              (p['featured'] == true ||
                  p['featured']?.toString().toLowerCase() == 'true'),
        )
        .toList();
    if (featuredList.isEmpty) return const SizedBox.shrink();
    final project = featuredList[_featuredIndex % featuredList.length];
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
              fontWeight: FontWeight.w400,
              color: Theme.of(context).colorScheme.onSurface,
              letterSpacing: -0.5,
            ),
          ),
        ),
        const SizedBox(height: 40),

        // Main Artistic Card — the artwork itself opens the project detail,
        // same target as READ MORE below (it wasn't tappable before).
        GestureDetector(
          onTap: () =>
              context.push('/cp/projects/${project['_id']}', extra: project),
          behavior: HitTestBehavior.opaque,
          child: Container(
            margin: const EdgeInsets.symmetric(horizontal: 24),
            decoration: BoxDecoration(
              borderRadius: BorderRadius.circular(16),
              boxShadow: [
                BoxShadow(
                  color: Colors.black.withValues(alpha: 0.2),
                  blurRadius: 40,
                  offset: const Offset(0, 20),
                ),
              ],
            ),
            child: ClipRRect(
              borderRadius: BorderRadius.circular(16),
              child: Stack(
                children: [
                  // 16:9 thumbnail — the ratio every card image uses. The web
                  // keeps the text on the photo and sizes it to fit the frame.
                  AspectRatio(
                    aspectRatio: 16 / 9,
                    child: _buildProjectImage(
                      _getImg(project, 0),
                      height: double.infinity,
                      width: double.infinity,
                    ),
                  ),
                  // Text scrim so the type stays readable on the photo.
                  Positioned.fill(
                    child: Container(
                      decoration: BoxDecoration(
                        gradient: LinearGradient(
                          begin: Alignment.topCenter,
                          end: Alignment.bottomCenter,
                          colors: [
                            Colors.transparent,
                            Colors.black.withValues(alpha: 0.55),
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
                    child: ImageOverlayLabel(
                      builder: (label) => Container(
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
                          label,
                          style: GoogleFonts.gelasio(
                            color: Colors.white,
                            fontSize: 7,
                            fontWeight: FontWeight.w700,
                            letterSpacing: 1.5,
                          ),
                        ),
                      ),
                    ),
                  ),
                  // The text sits between the corner badge (top 24, ~24 tall) and the
                  // photo's bottom. The subtitle may take two lines; if the block is
                  // still too tall (small phone, large text) it scales down a little
                  // rather than being cut off or running into the badge.
                  Positioned(
                    top: 56,
                    bottom: 24,
                    left: 24,
                    right: 24,
                    child: LayoutBuilder(
                      builder: (context, box) => Align(
                        alignment: Alignment.bottomLeft,
                        child: FittedBox(
                          fit: BoxFit.scaleDown,
                          alignment: Alignment.bottomLeft,
                          child: SizedBox(
                            width: box.maxWidth,
                            child: Column(
                                    mainAxisSize: MainAxisSize.min,
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Text(
                                  'FEATURED PROPERTY',
                                  style: GoogleFonts.gelasio(
                                    color: const Color(0xFFF4EFE3),
                                    fontSize: 9,
                                    fontWeight: FontWeight.w700,
                                    letterSpacing: 1.8,
                                  ),
                                ),
                                const SizedBox(height: 8),
                                // Web renders this in Montserrat (globals.css forces
                                // montserrat !important over the font-serif class), light
                                // weight, text-4xl, tracking-tight.
                                Text(
                                  (project['title'] ?? '').toString(),
                                  maxLines: 1,
                                  overflow: TextOverflow.ellipsis,
                                  style: GoogleFonts.gelasio(
                                    color: Theme.of(context).colorScheme.onSurface,
                                    fontSize: 34,
                                    fontWeight: FontWeight.w500,
                                    height: 1,
                                    letterSpacing: -0.5,
                                  ),
                                ),
                                const SizedBox(height: 6),
                                // Hardcoded subtitle to match web SharedHomePage.
                                Text(
                                  'Live smart at Aura Heights—space-efficient 1 & 2 BHK homes with curated amenities and rare parking solutions.'
                                      .toUpperCase(),
                                  maxLines: 2,
                                  overflow: TextOverflow.ellipsis,
                                  style: GoogleFonts.inter(
                                    color: Colors.white.withValues(alpha: 0.8),
                                    fontSize: 10,
                                    height: 1.5,
                                    fontWeight: FontWeight.w500,
                                    letterSpacing: 1.2,
                                  ),
                                ),
                              ],
                            ),
                          ),
                        ),
                      ),
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
                      color: (isDark ? Colors.white : const Color(0xFF0C312B))
                          .withValues(alpha: 0.1),
                    ),
                  ),
                  child: Icon(
                    LucideIcons.arrowLeft,
                    color: isDark ? Colors.white : const Color(0xFF0C312B),
                    size: 20,
                  ),
                ),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: _ScaleButton(
                  onTap: () => context.push(
                    '/cp/projects/${project['_id']}',
                    extra: project,
                  ),
                  child: Container(
                    height: 56,
                    decoration: BoxDecoration(
                      color: isDark ? Colors.white : const Color(0xFF0C312B),
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
                          color: isDark
                              ? const Color(0xFF0C312B)
                              : const Color(0xFFF4EFE3),
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
                      color: (isDark ? Colors.white : const Color(0xFF0C312B))
                          .withValues(alpha: 0.1),
                    ),
                  ),
                  child: Icon(
                    LucideIcons.arrowRight,
                    color: isDark ? Colors.white : const Color(0xFF0C312B),
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
        Icon(
          icon,
          color: isDark ? Colors.white : const Color(0xFF0C312B),
          size: 24,
        ),
        const SizedBox(height: 8),
        Text(
          label,
          textAlign: TextAlign.center,
          style: GoogleFonts.gelasio(
            color: isDark ? Colors.white : const Color(0xFF0C312B),
            fontSize: 9,
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
            fontWeight: FontWeight.w400,
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
              color: (isDark ? Colors.white : const Color(0xFF0C312B))
                  .withValues(alpha: 0.08),
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
            child: LayoutBuilder(
              builder: (context, constraints) {
                // A cell has to hold the 48px icon, a two-line title and a
                // two-line description: about 178px once the 20px padding on
                // each side is counted. Below that the ratio would make it
                // shorter than its own content.
                final cellWidth = (constraints.maxWidth - 1) / 2;
                final designHeight = cellWidth / 0.95;
                final cellHeight = designHeight < 178 ? 178.0 : designHeight;
                return GridView.count(
                  shrinkWrap: true,
                  physics: const NeverScrollableScrollPhysics(),
                  crossAxisCount: 2,
                  mainAxisSpacing: 1,
                  crossAxisSpacing: 1,
                  childAspectRatio: cellWidth / cellHeight,
                  children: [
                    _buildConnectItem(
                      LucideIcons.building2,
                      'EXPLORE PROJECTS',
                      'Browse our portfolio of properties',
                      () => Navigator.push(
                        context,
                        MaterialPageRoute(
                          // Green showcase, same as the Properties tab in the shell.
                          builder: (context) => Theme(
                            data: M4Theme.darkTheme,
                            child: const ProjectListScreen(cpCatalogMode: true),
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
                      () => context.push('/cp/media'),
                    ),
                    _buildConnectItem(
                      LucideIcons.user,
                      'REGISTER INTEREST',
                      'Register your interest in our properties',
                      _scrollToInterestForm,
                    ),
                  ],
                );
              },
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
                color: (isDark ? Colors.white : const Color(0xFF0C312B))
                    .withValues(alpha: 0.05),
                shape: BoxShape.circle,
                border: Border.all(
                  color: (isDark ? Colors.white : const Color(0xFF0C312B))
                      .withValues(alpha: 0.1),
                ),
              ),
              child: Icon(
                icon,
                color: isDark ? Colors.white : const Color(0xFF0C312B),
                size: 20,
              ),
            ),
            // Every cell in the grid gets the same height, so the text has to
            // give way on a narrow screen rather than run past the bottom.
            const SizedBox(height: 16),
            Text(
              title,
              textAlign: TextAlign.center,
              maxLines: 2,
              overflow: TextOverflow.ellipsis,
              style: GoogleFonts.inter(
                color: isDark ? Colors.white : const Color(0xFF155A4F),
                fontWeight: FontWeight.w600,
                fontSize: 13,
                letterSpacing: 1,
              ),
            ),
            const SizedBox(height: 6),
            Flexible(
              child: Text(
                desc,
                textAlign: TextAlign.center,
                // Two lines, as designed. Without an explicit maxLines the
                // ellipsis collapses it to one even when there is room.
                maxLines: 2,
                overflow: TextOverflow.ellipsis,
                style: GoogleFonts.inter(
                  color: (isDark ? Colors.white : const Color(0xFF0C312B))
                      .withValues(alpha: 0.68),
                  fontSize: 11,
                  fontWeight: FontWeight.w500,
                  height: 1.4,
                ),
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
            color: isDark ? Colors.white : const Color(0xFF0C312B),
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
          keyboardType: TextInputType.name,
          inputFormatters: Validators.nameFormatters,
          hint: 'Enter Full Name',
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
          hint: 'Enter Email Address',
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
          hint: 'Enter Mobile Number',
          errorText: _phoneError,
          onChanged: (v) {
            if (_phoneError != null) setState(() => _phoneError = null);
          },
        ),
        const SizedBox(height: 16),
        _buildLuxuryInput(
          'Message',
          _messageController,
          isLong: true,
          hint: 'Enter Message',
        ),
        const SizedBox(height: 24),
        Row(
          children: [
            Checkbox.adaptive(
              value: _agreedToTerms,
              // Un-ticked on submit turns this red in place — no popup.
              onChanged: (val) => setState(() {
                _agreedToTerms = val ?? false;
                if (_agreedToTerms) _termsError = false;
              }),
              activeColor: isDark ? Colors.white : const Color(0xFF0C312B),
              checkColor: isDark ? Colors.black : const Color(0xFFF4EFE3),
              side: BorderSide(
                color: _termsError
                    ? const Color(0xFFC65B46)
                    : (isDark ? Colors.white24 : Colors.black26),
                width: _termsError ? 1.8 : 1,
              ),
            ),
            Expanded(
              child: Text(
                "I've read and agree to the Privacy Policy",
                style: GoogleFonts.inter(
                  color: _termsError
                      ? const Color(0xFFC65B46)
                      : (isDark ? Colors.white54 : const Color(0xFF155A4F)),
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
                color: isDark ? Colors.white : const Color(0xFF0C312B),
                borderRadius: BorderRadius.circular(16),
              ),
              child: Center(
                child: _submitting
                    ? CircularProgressIndicator.adaptive(
                        valueColor: AlwaysStoppedAnimation<Color>(
                          isDark ? Colors.black : const Color(0xFFF4EFE3),
                        ),
                      )
                    : Text(
                        'SUBMIT INTEREST',
                        style: GoogleFonts.inter(
                          color: isDark
                              ? const Color(0xFF0C312B)
                              : const Color(0xFFF4EFE3),
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
    String label,
    TextEditingController controller, {
    bool isLong = false,
    TextInputType? keyboardType,
    List<TextInputFormatter>? inputFormatters,
    String? hint,
    // When set, the field turns red and shows the message underneath — keeps
    // validation on the field instead of a toast over the page.
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
            // Frosted field: translucent white on the green/navy surfaces, cream on
            // the light ones - never a solid black box.
            color: isDark
                ? Colors.white.withValues(alpha: 0.08)
                : const Color(0xFFF4EFE3),
            borderRadius: BorderRadius.circular(16),
            border: Border.all(
              color: hasError
                  ? errorColor
                  : (isDark ? Colors.white : const Color(0xFF0C312B))
                        .withValues(alpha: 0.12),
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
            cursorColor: Theme.of(context).brightness == Brightness.dark
                ? Colors.white
                : Theme.of(context).colorScheme.onSurface,
            controller: controller,
            keyboardType: keyboardType,
            inputFormatters: inputFormatters,
            onChanged: onChanged,
            style: TextStyle(
              color: isDark ? Colors.white : const Color(0xFF0C312B),
            ),
            maxLines: isLong ? 5 : 1,
            decoration: InputDecoration(
              hintText: hint ?? label,
              hintStyle: GoogleFonts.inter(
                color: hasError
                    ? errorColor.withValues(alpha: 0.75)
                    : (isDark
                          ? Colors.white54
                          : const Color(0xFF0C312B).withValues(alpha: 0.5)),
                fontSize: 12,
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
