import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:m4_mobile/core/utils/validators.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:cached_network_image/cached_network_image.dart';
import 'package:m4_mobile/presentation/widgets/m4_image.dart';
import 'package:m4_mobile/core/theme/app_theme.dart';
import 'package:m4_mobile/core/utils/project_highlights.dart';
import 'package:flutter_animate/flutter_animate.dart';
import 'package:lucide_icons/lucide_icons.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:go_router/go_router.dart';
import 'dart:ui';
import 'package:m4_mobile/presentation/widgets/conditional_drawer.dart';
import 'package:m4_mobile/presentation/widgets/main_shell.dart';
import 'package:m4_mobile/core/utils/support_handlers.dart';
import 'package:m4_mobile/core/network/api_client.dart';
import 'package:m4_mobile/presentation/providers/auth_provider.dart';
import 'package:m4_mobile/presentation/providers/project_provider.dart';
import 'package:m4_mobile/presentation/screens/pages/pages_list_screen.dart';
import 'package:m4_mobile/presentation/screens/projects/project_detail_screen.dart';
import 'package:m4_mobile/presentation/screens/projects/project_list_screen.dart';
import 'package:m4_mobile/presentation/screens/communities/community_detail_screen.dart';
import 'package:m4_mobile/presentation/screens/communities/community_list_screen.dart';
import 'dart:async';

class DashboardScreen extends ConsumerStatefulWidget {
  const DashboardScreen({super.key});

  @override
  ConsumerState<DashboardScreen> createState() => _DashboardScreenState();
}

class _DashboardScreenState extends ConsumerState<DashboardScreen> {
  final PageController _featuredController = PageController();
  final ScrollController _scrollController = ScrollController();
  final GlobalKey _inquiryKey = GlobalKey();
  final GlobalKey<ScaffoldState> _scaffoldKey = GlobalKey<ScaffoldState>();

  int _currentHeroIndex = 0;
  int _heroSlide =
      0; // top hero cycles the featured project's heroImages (web parity)
  String _searchQuery = '';
  String _selectedCategory = 'ALL';
  List<dynamic> _projects = [];
  bool _projectsLoading = true;
  List<dynamic> _updates = [];
  bool _updatesLoading = true;
  String _updateCategory = 'PROPERTIES';
  List<dynamic> _communities = [];
  bool _communitiesLoading = true;
  String _topTabCategory = 'COMMUNITIES';

  Timer? _heroTimer;
  Timer? _scrollTimer;
  final ScrollController _recommendedScrollController = ScrollController();

  // 📝 Inquiry Form Controllers
  final TextEditingController _nameController = TextEditingController();
  final TextEditingController _emailController = TextEditingController();
  final TextEditingController _phoneController = TextEditingController();
  final TextEditingController _messageController = TextEditingController();
  String? _selectedProject;

  // Inline validation for the "Register your interest" form — the field itself
  // turns red instead of a snackbar popping over the page.
  String? _nameError;
  String? _emailError;
  String? _phoneError;
  bool _isSubmitting = false;

  @override
  void initState() {
    super.initState();
    _fetchProjects();
    _fetchUpdates();
    _fetchCommunities();
    _startTimers();
  }

  Future<void> _fetchCommunities() async {
    try {
      final apiClient = ref.read(apiClientProvider);
      final response = await apiClient.getCommunities();
      if (response.data['status'] == true && response.data['data'] is List) {
        setState(() {
          _communities = response.data['data'];
          _communitiesLoading = false;
        });
      } else {
        setState(() => _communitiesLoading = false);
      }
    } catch (e) {
      setState(() => _communitiesLoading = false);
    }
  }

  void _startTimers() {
    _heroTimer = Timer.periodic(const Duration(seconds: 3), (timer) {
      if (_projects.isNotEmpty) {
        setState(() {
          // Cycle the 3 hero slides (featured project's heroImages) — web parity.
          _heroSlide = (_heroSlide + 1) % 3;
        });
      }
    });

    _scrollTimer = Timer.periodic(const Duration(seconds: 3), (timer) {
      if (_recommendedScrollController.hasClients) {
        double maxScroll =
            _recommendedScrollController.position.maxScrollExtent;
        double currentScroll = _recommendedScrollController.offset;
        double nextScroll = currentScroll + 260; // card width + margin

        if (nextScroll >= maxScroll) {
          _recommendedScrollController.animateTo(
            0,
            duration: 800.ms,
            curve: Curves.easeInOut,
          );
        } else {
          _recommendedScrollController.animateTo(
            nextScroll,
            duration: 800.ms,
            curve: Curves.easeInOut,
          );
        }
      }
    });
  }

  /// Web parity (SharedHomePage.getImg): prefer heroImages[idx], then the
  /// singular heroImage (idx 0), then images[0], then a stock fallback. The web
  /// hero/cards read heroImages first — the app previously read heroImage /
  /// images[0], which surfaced concept/palette graphics instead of the real
  /// interior renders.
  String _projImg(dynamic p, int idx) {
    if (p is Map) {
      final hero = p['heroImages'];
      if (hero is List && idx < hero.length) {
        final v = hero[idx]?.toString();
        if (v != null && v.isNotEmpty) return v;
      }
      if (idx == 0) {
        final single = p['heroImage']?.toString();
        if (single != null && single.isNotEmpty) return single;
        final imgs = p['images'];
        if (imgs is List && imgs.isNotEmpty) {
          final v = imgs[0]?.toString();
          if (v != null && v.isNotEmpty) return v;
        }
      }
    }
    return 'https://images.unsplash.com/photo-1613545325278-f24b0cae1224?auto=format&fit=crop&q=80';
  }

  /// Web parity: MEDIA tab = a gallery built from every project's heroImages.
  Widget _buildMediaRow(BuildContext context) {
    final media = <Map<String, dynamic>>[];
    for (final p in _projects) {
      if (p is! Map) continue;
      final hero = p['heroImages'];
      final list = hero is List
          ? hero
          : (p['heroImage'] != null ? [p['heroImage']] : const []);
      for (final img in list) {
        final url = img?.toString() ?? '';
        if (url.isEmpty) continue;
        media.add({
          'image': url,
          'title': p['title']?.toString() ?? '',
          'project': p,
        });
      }
    }
    if (media.isEmpty) {
      return Center(
        child: Text(
          'NO MEDIA FOUND',
          style: GoogleFonts.gelasio(
            // Was Colors.white10 — invisible on the light background.
            color: Theme.of(
              context,
            ).colorScheme.onSurface.withValues(alpha: 0.72),
            fontSize: 10,
            fontWeight: FontWeight.w700,
            letterSpacing: 1.5,
          ),
        ),
      );
    }
    return ListView.builder(
      scrollDirection: Axis.horizontal,
      physics: const BouncingScrollPhysics(),
      padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 20),
      itemCount: media.length > 12 ? 12 : media.length,
      itemBuilder: (context, index) {
        final m = media[index];
        return _MediaCard(
          imageUrl: m['image'] as String,
          title: m['title'] as String,
          // Media tiles open the Media Gallery (content hub) — same target as
          // the menu's Media entry and the guest home — not the project page.
          onTap: () => context.push('/media'),
        );
      },
    );
  }

  Future<void> _fetchUpdates() async {
    try {
      final apiClient = ref.read(apiClientProvider);
      final response = await apiClient.getGlobalUpdates();
      if (response.data['status'] == true && response.data['data'] is List) {
        setState(() {
          _updates = response.data['data'];
          _updatesLoading = false;
        });
      } else {
        setState(() => _updatesLoading = false);
      }
    } catch (e) {
      setState(() => _updatesLoading = false);
    }
  }

  Future<void> _fetchProjects() async {
    // Go through the shared projectsProvider rather than a bare getProjects():
    // it caches the (multi-MB) catalog payload so re-entering Home is instant,
    // retries cold-start timeouts, and shares ONE download with the Projects
    // tab. The old direct call also gated on `status == true`, which left the
    // list silently empty whenever the API omitted that field.
    try {
      if (ref.read(projectsProvider) is AsyncError) {
        ref.invalidate(projectsProvider);
      }
      final projects = await ref.read(projectsProvider.future);
      if (!mounted) return;
      setState(() {
        _projects = projects;
        _projectsLoading = false;
      });
    } catch (e) {
      if (mounted) {
        setState(() => _projectsLoading = false);
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Failed to load projects: $e'),
            backgroundColor: Colors.redAccent,
          ),
        );
      }
    }
  }

  @override
  void dispose() {
    _nameController.dispose();
    _emailController.dispose();
    _phoneController.dispose();
    _messageController.dispose();
    _featuredController.dispose();
    _scrollController.dispose();
    _recommendedScrollController.dispose();
    _heroTimer?.cancel();
    _scrollTimer?.cancel();
    super.dispose();
  }

  void _scrollToInquiry() {
    final context = _inquiryKey.currentContext;
    if (context != null) {
      Scrollable.ensureVisible(
        context,
        duration: const Duration(seconds: 1),
        curve: Curves.easeInOut,
      );
    }
  }

  /// Marks the empty required fields red in place. Returns true when valid.
  /// (Replaces the old snackbar — and the `_selectedProject == null` gate,
  /// which could never pass: the project dropdown isn't part of this form, so
  /// nothing ever set it and every submit failed even when fully filled.)
  bool _validateInquiry() {
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

  Future<void> _submitInquiry() async {
    final apiClient = ref.read(apiClientProvider);
    if (!_validateInquiry()) return;

    setState(() => _isSubmitting = true);

    try {
      final response = await apiClient.submitLead({
        'name': _nameController.text,
        'email': _emailController.text,
        'phone': _phoneController.text,
        'message': _messageController.text,
        // `interest` and `source` are server-side enums — anything else is
        // rejected with a 400. Valid: interest = Buying | Selling | Site Visit
        // | Video Call (case-sensitive); source = online | cp | walk-in |
        // referral | other.
        'interest': 'Buying',
        'projectName': _selectedProject,
        'source': 'online',
      });

      if (!mounted) return;
      if (response.data['status'] == true) {
        _nameController.clear();
        _emailController.clear();
        _phoneController.clear();
        _messageController.clear();
        setState(() => _selectedProject = null);

        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('Inquiry submitted successfully!'),
            backgroundColor: Colors.green,
          ),
        );
      } else {
        // The API answered but rejected it — don't fail silently.
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('Could not submit right now. Please try again.'),
            backgroundColor: Colors.redAccent,
          ),
        );
      }
    } catch (e) {
      if (!mounted) return;
      // A raw DioException dump helps nobody — keep it human.
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Could not submit right now. Please try again.'),
          backgroundColor: Colors.redAccent,
        ),
      );
    } finally {
      if (mounted) setState(() => _isSubmitting = false);
    }
  }

  Widget _buildWebUSP(BuildContext context, IconData icon, String label) {
    final foreground = Theme.of(context).colorScheme.onSurface;
    return Column(
      children: [
        Icon(icon, color: foreground, size: 24),
        const SizedBox(height: 12),
        Text(
          label,
          textAlign: TextAlign.center,
          // Was 8px / 60% — far too small and faint to read. Bigger + darker.
          style: GoogleFonts.inter(
            color: foreground.withOpacity(0.85),
            fontSize: 10.5,
            fontWeight: FontWeight.w600,
            letterSpacing: 0.5,
            height: 1.4,
          ),
        ),
      ],
    );
  }

  @override
  Widget build(BuildContext context) {
    final apiClient = ref.watch(apiClientProvider);

    // Listen for external scroll triggers (e.g., from Sidebar)
    // Listen for external scroll triggers (e.g., from Sidebar)
    ref.listen(inquiryScrollTriggerProvider, (previous, next) {
      if (next > 0) {
        _scrollToInquiry();
      }
    });

    return Material(
      color: Theme.of(context).scaffoldBackgroundColor,
      child: CustomScrollView(
        controller: _scrollController,
        slivers: <Widget>[
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
                      height:
                          85, // 👈 Reduced for a more elegant, minimalist footprint
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
                          // Toggle button background: White in Dark Mode, Black in Light Mode
                          color: Colors.transparent,
                          borderRadius: BorderRadius.circular(14),
                        ),
                        child: Icon(
                          LucideIcons.menu,
                          // White on the dark navy surfaces, theme ink on cream.
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

          // ⭐️ TAGLINE & HERO SECTION
          SliverToBoxAdapter(
            child: Padding(
              padding: const EdgeInsets.fromLTRB(
                0,
                0,
                0,
                0,
              ), // 👈 Zero bottom padding
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.center,
                children: [
                  // ⭐️ Tagline (Living the M4 Life)
                  // Tagline (Living the M4 Life) — full-width script image,
                  // cropped tight to the text band so there is no large gap
                  // before the hero. Same in light and dark mode.
                  Padding(
                    padding: const EdgeInsets.only(top: 12, bottom: 8),
                    child: M4Theme.taglineWordmark(context, height: 120),
                  ),

                  // Hero Image Container
                  Padding(
                    padding: const EdgeInsets.symmetric(horizontal: 24),
                    child: Builder(
                      builder: (context) {
                        // Web parity: the top hero cycles the FIRST (featured)
                        // project's heroImages[0..2], matching SharedHomePage.
                        final featured = _projects.isNotEmpty
                            ? _projects[0]
                            : null;
                        final mainImage = _projImg(featured, _heroSlide % 3);

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
                                    child: M4Image(
                                      key: ValueKey<int>(_heroSlide),
                                      imageUrl: mainImage,
                                      fit: BoxFit.cover,
                                      width: double.infinity,
                                      height: double.infinity,
                                      placeholder: Container(
                                        color: Colors.black12,
                                      ),
                                      errorWidget: Container(
                                        color: Colors.white10,
                                        child: const Center(
                                          child: Icon(
                                            LucideIcons.image,
                                            color: Colors.white24,
                                            size: 50,
                                          ),
                                        ),
                                      ),
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
                                  color: Colors.black.withOpacity(0.6),
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
                                    fontWeight: FontWeight.w700,
                                    letterSpacing: 1.5,
                                  ),
                                ),
                              ),
                            ),

                            // Carousel Indicators
                            Positioned(
                              bottom: 24,
                              left: 0,
                              right: 0,
                              child: Row(
                                mainAxisAlignment: MainAxisAlignment.center,
                                children: List.generate(3, (index) {
                                  final isSelected = (_heroSlide % 3) == index;
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
                                          : Colors.white.withOpacity(0.5),
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
          ),

          // ⭐️ DISCOVERY SECTION TABS (Web Parity)
          SliverToBoxAdapter(
            child: Padding(
              padding: const EdgeInsets.fromLTRB(24, 20, 24, 0),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  SingleChildScrollView(
                    scrollDirection: Axis.horizontal,
                    physics: const BouncingScrollPhysics(),
                    child: Row(
                      children: [
                        _WebTab(
                          label: 'COMMUNITIES',
                          isActive: _topTabCategory == 'COMMUNITIES',
                          onTap: () =>
                              setState(() => _topTabCategory = 'COMMUNITIES'),
                        ),
                        const SizedBox(width: 44),
                        _WebTab(
                          label: 'PROPERTIES',
                          isActive: _topTabCategory == 'PROPERTIES',
                          onTap: () =>
                              setState(() => _topTabCategory = 'PROPERTIES'),
                        ),
                        const SizedBox(width: 44),
                        _WebTab(
                          label: 'MEDIA',
                          isActive: _topTabCategory == 'MEDIA',
                          onTap: () =>
                              setState(() => _topTabCategory = 'MEDIA'),
                        ),
                      ],
                    ),
                  ),
                  const SizedBox(height: 28),
                  Text(
                    _topTabCategory == 'COMMUNITIES'
                        ? 'M4 COMMUNITIES'
                        : _topTabCategory == 'MEDIA'
                        ? 'M4 MEDIA'
                        : 'M4 PROPERTIES',
                    style: GoogleFonts.gelasio(
                      fontSize: 32,
                      fontWeight: FontWeight.w400,
                      color: Theme.of(context).colorScheme.onSurface,
                      letterSpacing: -1,
                    ),
                  ),
                ],
              ),
            ),
          ),

          SliverToBoxAdapter(
            child: SizedBox(
              height: 380,
              child:
                  (_topTabCategory == 'COMMUNITIES'
                      ? _communitiesLoading
                      : _projectsLoading)
                  ? Center(
                      // Was Colors.white10 — invisible on the light background,
                      // so the section read as "nothing is loading".
                      child: SizedBox(
                        width: 24,
                        height: 24,
                        child: CircularProgressIndicator(
                          strokeWidth: 2,
                          color: Theme.of(
                            context,
                          ).colorScheme.onSurface.withValues(alpha: 0.4),
                        ),
                      ),
                    )
                  : Builder(
                      builder: (context) {
                        // Web parity: MEDIA tab shows a gallery of every project's
                        // heroImages (image tiles), not the project cards.
                        if (_topTabCategory == 'MEDIA') {
                          return _buildMediaRow(context);
                        }
                        final items = _topTabCategory == 'COMMUNITIES'
                            ? _communities
                            : _projects.where((p) {
                                if (_selectedCategory == 'ALL') return true;
                                return p['status']?.toString().toUpperCase() ==
                                    _selectedCategory;
                              }).toList();

                        if (items.isEmpty) {
                          return Center(
                            child: Text(
                              'NO ITEMS FOUND',
                              style: GoogleFonts.gelasio(
                                color: Theme.of(
                                  context,
                                ).colorScheme.onSurface.withValues(alpha: 0.72),
                                fontSize: 10,
                                fontWeight: FontWeight.w700,
                                letterSpacing: 1.5,
                              ),
                            ),
                          );
                        }

                        return ListView.builder(
                          scrollDirection: Axis.horizontal,
                          physics: const BouncingScrollPhysics(),
                          padding: const EdgeInsets.symmetric(
                            horizontal: 20,
                            vertical: 20,
                          ),
                          itemCount: items.length > 8 ? 8 : items.length,
                          itemBuilder: (context, index) {
                            final item = items[index];
                            if (_topTabCategory == 'COMMUNITIES') {
                              return _CommunityCard(
                                title: item['title'] ?? 'UNTITLED',
                                description:
                                    item['overview'] ??
                                    item['description'] ??
                                    'Explore this master-planned community',
                                imageUrl: (() {
                                  final title = (item['title'] ?? '')
                                      .toString()
                                      .toUpperCase();
                                  if (title.contains('HEEYYA HOOO')) {
                                    return 'https://images.unsplash.com/photo-1486406146926-c627a92ad1ab?auto=format&fit=crop&q=80';
                                  }
                                  if (title.contains('MAZGAON')) {
                                    return 'https://images.unsplash.com/photo-1512917774080-9991f1c4c750?auto=format&fit=crop&q=80';
                                  }

                                  final rawImg = item['image']?.toString();
                                  if (rawImg != null &&
                                      rawImg.isNotEmpty &&
                                      rawImg != 'null' &&
                                      rawImg != '[]' &&
                                      rawImg.trim().isNotEmpty) {
                                    return rawImg;
                                  }
                                  final heroImgs = item['heroImages'];
                                  if (heroImgs is List && heroImgs.isNotEmpty) {
                                    return heroImgs[0].toString();
                                  }
                                  return 'https://images.unsplash.com/photo-1486406146926-c627a92ad1ab?auto=format&fit=crop&q=80';
                                })(),
                                onTap: () {
                                  Navigator.push(
                                    context,
                                    MaterialPageRoute(
                                      builder: (context) =>
                                          CommunityDetailScreen(
                                            community: item,
                                          ),
                                    ),
                                  );
                                },
                              );
                            } else {
                              final locData = item['location'];
                              final locationName = (locData is Map)
                                  ? locData['name']?.toString() ?? ''
                                  : '';
                              final imageUrl = _projImg(item, 0);

                              return _ProjectCard(
                                title: item['title']?.toString() ?? 'Untitled',
                                location: locationName,
                                status: item['status']?.toString() ?? '',
                                imageUrl: imageUrl,
                                onTap: () {
                                  final projectId =
                                      item['_id']?.toString() ??
                                      item['id']?.toString() ??
                                      '';
                                  if (projectId.isNotEmpty) {
                                    Navigator.push(
                                      context,
                                      MaterialPageRoute(
                                        builder: (context) =>
                                            ProjectDetailScreen(
                                              projectId: projectId,
                                              projectData: item,
                                            ),
                                      ),
                                    );
                                  }
                                },
                              );
                            }
                          },
                        );
                      },
                    ),
            ),
          ),

          // 5. 📜 Stage 5: Our Philosophy
          SliverToBoxAdapter(
            child: Padding(
              padding: const EdgeInsets.fromLTRB(30, 40, 30, 40),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: <Widget>[
                  Text(
                    'OUR PHILOSOPHY',
                    style: GoogleFonts.gelasio(
                      fontSize: 32,
                      fontWeight: FontWeight.w400,
                      color: Theme.of(context).colorScheme.onSurface,
                      letterSpacing: -0.5,
                    ),
                  ),
                  const SizedBox(height: 20),
                  Text(
                    'To redefine modern luxury living by crafting homes with cutting edge design, enduring quality and thoughtful amenities delivered with trust, transparency, timeliness, and a human touch that creates lasting value for every homeowner.',
                    textAlign: TextAlign.justify,
                    style: GoogleFonts.inter(
                      color: Theme.of(
                        context,
                      ).colorScheme.onSurface.withOpacity(0.6),
                      fontSize: 14,
                      height: 1.8,
                    ),
                  ),
                ],
              ),
            ),
          ),

          // 6. 🖼️ Stage 6: Featured Selection Hero (Slider + Info below)
          SliverToBoxAdapter(
            child: Padding(
              padding: const EdgeInsets.symmetric(horizontal: 30, vertical: 10),
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
          ),
          SliverToBoxAdapter(
            child: Padding(
              padding: const EdgeInsets.symmetric(horizontal: 25),
              child: SizedBox(
                height: 480, // Increased height for overlay content
                child: _projectsLoading
                    ? const Center(
                        child: CircularProgressIndicator(color: Colors.white24),
                      )
                    : _projects.isEmpty
                    ? const Center(
                        child: Text(
                          'No featured properties',
                          style: TextStyle(color: Colors.white24),
                        ),
                      )
                    : PageView.builder(
                        controller: _featuredController,
                        itemCount: _projects.length > 5 ? 5 : _projects.length,
                        onPageChanged: (index) =>
                            setState(() => _currentHeroIndex = index),
                        itemBuilder: (context, index) {
                          final project = _projects[index];
                          final title =
                              project['title']?.toString() ?? 'UNTITLED';
                          // Web parity: SharedHomePage shows this fixed blurb
                          // under the featured title.
                          const tagline =
                              'Live smart at Aura Heights—space-efficient 1 & 2 BHK homes with curated amenities and rare parking solutions.';
                          final imageUrl = _projImg(project, 0);

                          return Padding(
                            padding: const EdgeInsets.symmetric(horizontal: 10),
                            child: GestureDetector(
                              onTap: () {
                                final projectId =
                                    project['_id']?.toString() ??
                                    project['id']?.toString() ??
                                    '';
                                if (projectId.isNotEmpty) {
                                  Navigator.push(
                                    context,
                                    MaterialPageRoute(
                                      builder: (context) => ProjectDetailScreen(
                                        projectId: projectId,
                                        projectData: project,
                                      ),
                                    ),
                                  );
                                }
                              },
                              child: Stack(
                                children: <Widget>[
                                  ClipRRect(
                                    borderRadius: BorderRadius.circular(40),
                                    child: imageUrl.isNotEmpty
                                        ? M4Image(
                                            imageUrl: imageUrl,
                                            fit: BoxFit.cover,
                                            height: 480,
                                            width: double.infinity,
                                            placeholder: Container(
                                              height: 480,
                                              color: Colors.black12,
                                            ),
                                            errorWidget: Container(
                                              height: 480,
                                              width: double.infinity,
                                              color: Colors.white.withOpacity(
                                                0.05,
                                              ),
                                              child: const Center(
                                                child: Icon(
                                                  LucideIcons.image,
                                                  color: Colors.white10,
                                                ),
                                              ),
                                            ),
                                          )
                                        : Container(
                                            color: Colors.white10,
                                            child: const Center(
                                              child: Icon(
                                                LucideIcons.image,
                                                color: Colors.white24,
                                              ),
                                            ),
                                          ),
                                  ),
                                  // Gradient Overlay
                                  Container(
                                    height: 480,
                                    decoration: BoxDecoration(
                                      borderRadius: BorderRadius.circular(40),
                                      gradient: LinearGradient(
                                        begin: Alignment.topCenter,
                                        end: Alignment.bottomCenter,
                                        colors: [
                                          Colors.transparent,
                                          Colors.black.withOpacity(0.1),
                                          Colors.black.withOpacity(0.8),
                                        ],
                                        stops: const [0.4, 0.6, 1.0],
                                      ),
                                    ),
                                  ),
                                  // Content Overlay
                                  Positioned(
                                    bottom: 40,
                                    left: 30,
                                    right: 30,
                                    child: Column(
                                      crossAxisAlignment:
                                          CrossAxisAlignment.start,
                                      children: [
                                        Text(
                                          'FEATURED PROPERTY',
                                          // Was 9px — too small to read.
                                          style: GoogleFonts.gelasio(
                                            color: const Color(0xFFF4EFE3),
                                            fontSize: 11,
                                            fontWeight: FontWeight.w700,
                                            letterSpacing: 2,
                                          ),
                                        ),
                                        const SizedBox(height: 8),
                                        Text(
                                          title,
                                          style: GoogleFonts.gelasio(
                                            color: Colors.white,
                                            fontSize: 34,
                                            height: 1,
                                            letterSpacing: -1,
                                          ),
                                        ),
                                        const SizedBox(height: 12),
                                        Text(
                                          tagline.toUpperCase(),
                                          maxLines: 2,
                                          overflow: TextOverflow.ellipsis,
                                          // Was 10px / 80% — faint on the photo.
                                          // Bigger, bolder, near-solid white.
                                          style: GoogleFonts.inter(
                                            color: Colors.white.withOpacity(
                                              0.95,
                                            ),
                                            fontSize: 11.5,
                                            fontWeight: FontWeight.w700,
                                            height: 1.5,
                                            letterSpacing: 0.8,
                                          ),
                                        ),
                                      ],
                                    ),
                                  ),
                                  // Artistic Impression Badge
                                  Positioned(
                                    top: 25,
                                    right: 25,
                                    child: Container(
                                      padding: const EdgeInsets.symmetric(
                                        horizontal: 14,
                                        vertical: 8,
                                      ),
                                      decoration: BoxDecoration(
                                        color: Colors.black.withOpacity(0.4),
                                        borderRadius: BorderRadius.circular(10),
                                        border: Border.all(
                                          color: Colors.white.withOpacity(0.1),
                                        ),
                                      ),
                                      child: Text(
                                        'ARTISTIC IMPRESSION',
                                        style: GoogleFonts.gelasio(
                                          color: Colors.white,
                                          fontSize: 8,
                                          fontWeight: FontWeight.w700,
                                          letterSpacing: 1.5,
                                        ),
                                      ),
                                    ),
                                  ),
                                ],
                              ),
                            ),
                          );
                        },
                      ),
              ),
            ),
          ),
          SliverToBoxAdapter(
            child: Padding(
              padding: const EdgeInsets.symmetric(vertical: 30),
              child: Column(
                children: <Widget>[
                  // USP Row (Web Parity)
                  Padding(
                    padding: const EdgeInsets.symmetric(horizontal: 24),
                    child: Row(
                      // Web parity: USPs come from the featured project's
                      // backend `highlights` (e.g. ["Prime Location", "20 min
                      // from Airport"]), not a hardcoded pair. Each is Expanded
                      // so its label wraps.
                      children: [
                        for (final h in projectHighlights(
                          _projects.isNotEmpty ? _projects.first : null,
                        ).take(3))
                          Expanded(
                            child: _buildWebUSP(
                              context,
                              highlightIcon(h),
                              h.toUpperCase(),
                            ),
                          ),
                      ],
                    ),
                  ),
                  const SizedBox(height: 40),
                  Row(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: <Widget>[
                      _SliderNavButton(
                        icon: LucideIcons.arrowLeft,
                        onTap: () {
                          if (_featuredController.hasClients) {
                            final maxItems = _projects.length > 5
                                ? 5
                                : _projects.length;
                            if (_currentHeroIndex > 0) {
                              _featuredController.previousPage(
                                duration: 500.ms,
                                curve: Curves.easeInOut,
                              );
                            } else {
                              _featuredController.animateToPage(
                                maxItems - 1,
                                duration: 800.ms,
                                curve: Curves.easeInOut,
                              );
                            }
                          }
                        },
                      ),
                      const SizedBox(width: 25),
                      GestureDetector(
                        onTap: () {
                          if (_projects.isNotEmpty) {
                            final maxItems = _projects.length > 5
                                ? 5
                                : _projects.length;
                            final currentIndex = _currentHeroIndex % maxItems;
                            final currentProject = _projects[currentIndex];
                            final projectId =
                                currentProject['_id']?.toString() ??
                                currentProject['id']?.toString() ??
                                '';
                            if (projectId.isNotEmpty) {
                              Navigator.push(
                                context,
                                MaterialPageRoute(
                                  builder: (context) => ProjectDetailScreen(
                                    projectId: projectId,
                                    projectData: currentProject,
                                  ),
                                ),
                              );
                            }
                          }
                        },
                        child: Container(
                          padding: const EdgeInsets.symmetric(
                            horizontal: 45,
                            vertical: 15,
                          ),
                          decoration: BoxDecoration(
                            color:
                                Theme.of(context).brightness == Brightness.dark
                                ? Colors.white
                                : Colors.black,
                            borderRadius: BorderRadius.circular(20),
                          ),
                          child: Text(
                            'READ MORE',
                            style: GoogleFonts.gelasio(
                              color:
                                  Theme.of(context).brightness ==
                                      Brightness.dark
                                  ? Colors.black
                                  : Colors.white,
                              fontWeight: FontWeight.w700,
                              fontSize: 13,
                              letterSpacing: 1.5,
                            ),
                          ),
                        ),
                      ),
                      const SizedBox(width: 25),
                      _SliderNavButton(
                        icon: LucideIcons.arrowRight,
                        onTap: () {
                          if (_featuredController.hasClients) {
                            final maxItems = _projects.length > 5
                                ? 5
                                : _projects.length;
                            if (_currentHeroIndex < (maxItems - 1)) {
                              _featuredController.nextPage(
                                duration: 500.ms,
                                curve: Curves.easeInOut,
                              );
                            } else {
                              _featuredController.animateToPage(
                                0,
                                duration: 800.ms,
                                curve: Curves.easeInOut,
                              );
                            }
                          }
                        },
                      ),
                    ],
                  ),
                ],
              ),
            ),
          ),

          // 7. Explore, Connect and Engage With Us (web parity)
          SliverToBoxAdapter(
            child: Padding(
              padding: const EdgeInsets.fromLTRB(25, 10, 25, 60),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: <Widget>[
                  Text(
                    'EXPLORE,\nCONNECT AND ENGAGE\nWITH US',
                    style: GoogleFonts.gelasio(
                      fontSize: 30,
                      fontWeight: FontWeight.w400,
                      height: 1.15,
                      color: Theme.of(context).colorScheme.onSurface,
                      letterSpacing: -0.5,
                    ),
                  ),
                  const SizedBox(height: 28),
                  Container(
                    decoration: BoxDecoration(
                      // Investor parity: a 3% translucent lift over the page
                      // rather than a solid surface panel, so the card reads as
                      // the same colour in both portals.
                      color: Theme.of(
                        context,
                      ).colorScheme.onSurface.withOpacity(0.03),
                      borderRadius: BorderRadius.circular(24),
                      border: Border.all(
                        color: Theme.of(
                          context,
                        ).colorScheme.onSurface.withOpacity(0.08),
                      ),
                    ),
                    child: ClipRRect(
                      borderRadius: BorderRadius.circular(24),
                      child: Column(
                        children: <Widget>[
                          // No IntrinsicHeight: it measures wrapping Text as a
                          // single line, then forces that height on the row —
                          // the 2-line title + 3-line desc of REGISTER INTEREST
                          // overflowed by 20px. A plain Row sizes to the tallest
                          // cell correctly. Cells have no background or divider,
                          // so equal heights are not needed visually.
                          Row(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: <Widget>[
                              Expanded(
                                child: _EngageCell(
                                  icon: LucideIcons.building2,
                                  title: 'EXPLORE PROJECTS',
                                  desc: 'Browse our portfolio of properties',
                                  onTap: () =>
                                      ref
                                              .read(navigationProvider.notifier)
                                              .state =
                                          1,
                                ),
                              ),
                              Expanded(
                                child: _EngageCell(
                                  icon: LucideIcons.layoutGrid,
                                  title: 'BOOK A VIEWING',
                                  desc:
                                      'Schedule a visit to our show apartment',
                                  onTap: _scrollToInquiry,
                                ),
                              ),
                            ],
                          ),
                          Row(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: <Widget>[
                              Expanded(
                                child: _EngageCell(
                                  icon: LucideIcons.image,
                                  title: 'MEDIA GALLERY',
                                  desc: 'Watch films and view property renders',
                                  onTap: () => context.push('/media'),
                                ),
                              ),
                              Expanded(
                                child: _EngageCell(
                                  icon: LucideIcons.user,
                                  title: 'REGISTER INTEREST',
                                  desc:
                                      'Register your interest in our properties',
                                  onTap: _scrollToInquiry,
                                ),
                              ),
                            ],
                          ),
                        ],
                      ),
                    ),
                  ),
                ],
              ),
            ),
          ),

          // 8. 📝 Stage 8: Official Inquiry Form
          SliverToBoxAdapter(
            key: _inquiryKey,
            child: Container(
              padding: const EdgeInsets.fromLTRB(30, 80, 30, 60),
              decoration: BoxDecoration(
                color: Theme.of(
                  context,
                ).colorScheme.onSurface.withOpacity(0.02),
                borderRadius: const BorderRadius.only(
                  topLeft: Radius.circular(50),
                  topRight: Radius.circular(50),
                ),
                border: Border.all(
                  color: Theme.of(
                    context,
                  ).colorScheme.onSurface.withOpacity(0.04),
                ),
              ),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: <Widget>[
                  Text(
                    'REGISTER YOUR\nINTEREST',
                    style: GoogleFonts.gelasio(
                      fontSize: 32,
                      fontWeight: FontWeight.w400,
                      color: Theme.of(context).colorScheme.onSurface,
                      height: 1.1,
                      letterSpacing: -1,
                    ),
                  ),
                  const SizedBox(height: 8),
                  Text(
                    'OFFICIAL INQUIRY FORM',
                    // Was 10px / 68% — small and washed out.
                    style: TextStyle(
                      color: Theme.of(
                        context,
                      ).colorScheme.onSurface.withOpacity(0.85),
                      fontSize: 12,
                      fontWeight: FontWeight.bold,
                      letterSpacing: 2,
                    ),
                  ),
                  const SizedBox(height: 48),
                  _PremiumInputField(
                    label: 'Full Name *',
                    controller: _nameController,
                    errorText: _nameError,
                    keyboardType: TextInputType.name,
                    inputFormatters: Validators.nameFormatters,
                    // Clear the red state as soon as they start typing.
                    onChanged: (v) {
                      if (_nameError != null) setState(() => _nameError = null);
                    },
                  ),
                  _PremiumInputField(
                    label: 'Email Address *',
                    controller: _emailController,
                    keyboardType: TextInputType.emailAddress,
                    inputFormatters: Validators.emailFormatters,
                    errorText: _emailError,
                    onChanged: (v) {
                      if (_emailError != null) {
                        setState(() => _emailError = null);
                      }
                    },
                  ),
                  _PremiumInputField(
                    label: 'Phone Number *',
                    controller: _phoneController,
                    keyboardType: TextInputType.phone,
                    inputFormatters: Validators.phoneFormatters,
                    errorText: _phoneError,
                    onChanged: (v) {
                      if (_phoneError != null) {
                        setState(() => _phoneError = null);
                      }
                    },
                  ),
                  _PremiumInputField(
                    label: 'Message',
                    controller: _messageController,
                    maxLines: 3,
                  ),
                  const SizedBox(height: 32),
                  SizedBox(
                    width: double.infinity,
                    child: ElevatedButton(
                      onPressed: _isSubmitting ? null : _submitInquiry,
                      style: ElevatedButton.styleFrom(
                        backgroundColor: Theme.of(
                          context,
                        ).colorScheme.onSurface,
                        foregroundColor: Theme.of(context).colorScheme.surface,
                        padding: const EdgeInsets.symmetric(vertical: 22),
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(15),
                        ),
                      ),
                      child: _isSubmitting
                          ? SizedBox(
                              height: 15,
                              width: 15,
                              child: CircularProgressIndicator(
                                strokeWidth: 2,
                                color: Theme.of(context).colorScheme.surface,
                              ),
                            )
                          : Text(
                              'SUBMIT INTEREST',
                              style: GoogleFonts.gelasio(
                                fontWeight: FontWeight.bold,
                                letterSpacing: 3,
                                fontSize: 12,
                              ),
                            ),
                    ),
                  ),
                ],
              ),
            ),
          ),

          SliverToBoxAdapter(child: SizedBox(height: 96)),
        ],
      ),
    );
  }
}

class _CategoryChip extends StatelessWidget {
  final String label;
  final bool isActive;
  final VoidCallback? onTap;
  const _CategoryChip({required this.label, this.isActive = false, this.onTap});

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    return GestureDetector(
      onTap: onTap,
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 30, vertical: 12),
        decoration: BoxDecoration(
          color: isActive
              ? (isDark ? Colors.white : Color(0xFF0C312B))
              : (isDark
                    ? Colors.white.withOpacity(0.05)
                    : Colors.black.withOpacity(0.05)),
          borderRadius: BorderRadius.circular(20),
          border: Border.all(
            color: (isDark ? Colors.white : Color(0xFF0C312B)).withOpacity(0.1),
          ),
        ),
        child: Text(
          label,
          style: GoogleFonts.gelasio(
            color: isActive
                ? (isDark ? Colors.black : Colors.white)
                : (isDark ? Colors.white38 : Color(0xFF155A4F)),
            fontSize: 10,
            fontWeight: FontWeight.bold,
            letterSpacing: 2,
          ),
        ),
      ),
    );
  }
}

class _ProjectCard extends StatelessWidget {
  final String title;
  final String location;
  final String status;
  final String imageUrl;
  final VoidCallback onTap;
  const _ProjectCard({
    required this.title,
    required this.location,
    required this.status,
    required this.imageUrl,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    final scheme = Theme.of(context).colorScheme;
    // Web parity: light "info card" — image on top (with ONGOING + ARTISTIC
    // IMPRESSION badges), then title / location / a full-width READ MORE
    // button below. (Was a full-bleed image-overlay card with VIEW PROPERTY.)
    return GestureDetector(
      onTap: onTap,
      child: Container(
        width: 280,
        margin: const EdgeInsets.only(right: 20, bottom: 10),
        decoration: BoxDecoration(
          color: scheme.surface,
          borderRadius: BorderRadius.circular(24),
          boxShadow: [
            BoxShadow(
              color: Colors.black.withOpacity(0.1),
              blurRadius: 18,
              offset: const Offset(0, 8),
            ),
          ],
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Image on top with badges — fills the space above the footer.
            Expanded(
              child: ClipRRect(
                borderRadius: const BorderRadius.vertical(
                  top: Radius.circular(24),
                ),
                child: Stack(
                  fit: StackFit.expand,
                  children: [
                    imageUrl.isNotEmpty
                        ? M4Image(
                            imageUrl: imageUrl,
                            height: double.infinity,
                            width: double.infinity,
                            fit: BoxFit.cover,
                            placeholder: Container(color: Colors.black12),
                            errorWidget: Container(color: Colors.white10),
                          )
                        : Container(
                            color: scheme.onSurface.withOpacity(0.05),
                            child: Center(
                              child: Icon(
                                LucideIcons.building,
                                color: scheme.onSurface.withOpacity(0.2),
                                size: 40,
                              ),
                            ),
                          ),
                    if (status.isNotEmpty)
                      Positioned(
                        top: 12,
                        right: 12,
                        child: Container(
                          padding: const EdgeInsets.symmetric(
                            horizontal: 12,
                            vertical: 6,
                          ),
                          decoration: BoxDecoration(
                            color: Colors.black.withOpacity(0.75),
                            borderRadius: BorderRadius.circular(20),
                          ),
                          child: Text(
                            status.toUpperCase(),
                            style: GoogleFonts.inter(
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
                          color: Colors.black.withOpacity(0.55),
                          borderRadius: BorderRadius.circular(4),
                        ),
                        child: Text(
                          'ARTISTIC IMPRESSION',
                          style: GoogleFonts.inter(
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
            ),
            // Info section: title, location, full-width READ MORE button.
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
                        color: scheme.onSurface.withOpacity(0.55),
                      ),
                      const SizedBox(width: 4),
                      Expanded(
                        child: Text(
                          location.toUpperCase(),
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                          style: GoogleFonts.inter(
                            color: scheme.onSurface.withOpacity(0.55),
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
}

class _QuickAction extends StatelessWidget {
  final IconData icon;
  final String label;
  final VoidCallback onTap;

  const _QuickAction({
    required this.icon,
    required this.label,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    return GestureDetector(
      onTap: onTap,
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          ClipRRect(
            borderRadius: BorderRadius.circular(20),
            child: BackdropFilter(
              filter: ImageFilter.blur(sigmaX: 10, sigmaY: 10),
              child: Container(
                padding: const EdgeInsets.all(14),
                decoration: BoxDecoration(
                  color: (isDark ? Colors.white : Color(0xFF0C312B))
                      .withOpacity(0.05),
                  borderRadius: BorderRadius.circular(20),
                  border: Border.all(
                    color: (isDark ? Colors.white : Color(0xFF0C312B))
                        .withOpacity(0.08),
                  ),
                ),
                child: Icon(
                  icon,
                  color: Theme.of(context).colorScheme.onSurface,
                  size: 24,
                ),
              ),
            ),
          ),
          const SizedBox(height: 10),
          Text(
            label,
            style: GoogleFonts.inter(
              fontSize: 8,
              fontWeight: FontWeight.w700,
              color: Theme.of(context).colorScheme.onSurface.withOpacity(0.68),
              letterSpacing: 1,
            ),
          ),
        ],
      ),
    );
  }
}

class _EngageCell extends StatelessWidget {
  final IconData icon;
  final String title;
  final String desc;
  final VoidCallback? onTap;

  const _EngageCell({
    required this.icon,
    required this.title,
    required this.desc,
    this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    final scheme = Theme.of(context).colorScheme;
    return InkWell(
      onTap: onTap,
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 26),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            // Icon in a bordered circle (web: w-10 h-10 rounded-full border).
            // Fill/border alphas match the investor connect grid.
            Container(
              width: 44,
              height: 44,
              decoration: BoxDecoration(
                shape: BoxShape.circle,
                color: scheme.onSurface.withOpacity(0.05),
                border: Border.all(color: scheme.onSurface.withOpacity(0.1)),
              ),
              child: Icon(icon, color: scheme.onSurface, size: 20),
            ),
            const SizedBox(height: 14),
            Text(
              title,
              textAlign: TextAlign.center,
              style: GoogleFonts.inter(
                fontSize: 15,
                fontWeight: FontWeight.w600,
                color: scheme.onSurface,
                letterSpacing: 0.8,
                height: 1.2,
              ),
            ),
            const SizedBox(height: 8),
            Text(
              desc,
              textAlign: TextAlign.center,
              // Muted to 50%, matching the investor connect grid exactly.
              // (Previously 95% — a deliberate earlier bump that made this
              // portal's copy read far heavier than the other portals'.)
              style: GoogleFonts.inter(
                fontSize: 14,
                fontWeight: FontWeight.w700,
                color: scheme.onSurface.withOpacity(0.5),
                height: 1.4,
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _QuickFilterSheet extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    return Container(
      decoration: BoxDecoration(
        color: isDark ? const Color(0xFF141B3A) : const Color(0xFFF4EFE3),
        borderRadius: const BorderRadius.only(
          topLeft: Radius.circular(35),
          topRight: Radius.circular(35),
        ),
      ),
      padding: const EdgeInsets.fromLTRB(25, 15, 25, 40),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Center(
            child: Container(
              width: 40,
              height: 4,
              decoration: BoxDecoration(
                color: Theme.of(context).colorScheme.onSurface.withOpacity(0.2),
                borderRadius: BorderRadius.circular(2),
              ),
            ),
          ),
          const SizedBox(height: 25),
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Text(
                'QUICK FILTERS',
                style: GoogleFonts.gelasio(
                  fontSize: 18,
                  fontWeight: FontWeight.w700,
                  color: Theme.of(context).colorScheme.onSurface,
                  letterSpacing: 1,
                ),
              ),
              GestureDetector(
                onTap: () => Navigator.pop(context),
                child: Container(
                  padding: const EdgeInsets.all(8),
                  decoration: BoxDecoration(
                    shape: BoxShape.circle,
                    color: (isDark ? Colors.white : Color(0xFF0C312B))
                        .withOpacity(0.1),
                  ),
                  child: Icon(
                    LucideIcons.x,
                    color: Theme.of(context).colorScheme.onSurface,
                    size: 18,
                  ),
                ),
              ),
            ],
          ),
          const SizedBox(height: 35),
          _FilterSection(
            title: 'LOCATION',
            options: const ['SOUTH MUMBAI', 'WORLI', 'BANDRA', 'JUHU', 'POWAI'],
          ),
          const SizedBox(height: 30),
          _FilterSection(
            title: 'PROPERTY TYPE',
            options: const ['RESIDENTIAL', 'COMMERCIAL'],
          ),
          const SizedBox(height: 50),
          GestureDetector(
            onTap: () => Navigator.pop(context),
            child: Container(
              width: double.infinity,
              padding: const EdgeInsets.symmetric(vertical: 20),
              decoration: BoxDecoration(
                color: isDark ? Colors.white : Color(0xFF0C312B),
                borderRadius: BorderRadius.circular(20),
              ),
              child: Center(
                child: Text(
                  'SHOW RESULTS',
                  style: GoogleFonts.gelasio(
                    color: isDark ? Colors.black : const Color(0xFFF4EFE3),
                    fontWeight: FontWeight.w700,
                    fontSize: 12,
                    letterSpacing: 1.5,
                  ),
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }
}

class _FilterSection extends StatelessWidget {
  final String title;
  final List<String> options;

  const _FilterSection({required this.title, required this.options});

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          title,
          style: GoogleFonts.gelasio(
            fontSize: 10,
            fontWeight: FontWeight.w700,
            color: Theme.of(context).colorScheme.onSurface.withOpacity(0.68),
            letterSpacing: 1.5,
          ),
        ),
        const SizedBox(height: 15),
        Wrap(
          spacing: 10,
          runSpacing: 12,
          children: options
              .map(
                (opt) => Container(
                  padding: const EdgeInsets.symmetric(
                    horizontal: 20,
                    vertical: 12,
                  ),
                  decoration: BoxDecoration(
                    color: (isDark ? Colors.white : Color(0xFF0C312B))
                        .withOpacity(0.05),
                    borderRadius: BorderRadius.circular(20),
                    border: Border.all(
                      color: (isDark ? Colors.white : Color(0xFF0C312B))
                          .withOpacity(0.05),
                    ),
                  ),
                  child: Text(
                    opt,
                    style: GoogleFonts.inter(
                      color: Theme.of(context).colorScheme.onSurface,
                      fontSize: 9,
                      fontWeight: FontWeight.w600,
                      letterSpacing: 1,
                    ),
                  ),
                ),
              )
              .toList(),
        ),
      ],
    );
  }
}

class _SliderNavButton extends StatelessWidget {
  final IconData icon;
  final VoidCallback onTap;
  const _SliderNavButton({required this.icon, required this.onTap});

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final foreground = isDark ? Colors.white : Color(0xFF0C312B);

    return GestureDetector(
      onTap: onTap,
      behavior: HitTestBehavior.opaque,
      child: Container(
        padding: const EdgeInsets.all(12),
        decoration: BoxDecoration(
          shape: BoxShape.circle,
          color: foreground.withOpacity(0.08),
          border: Border.all(color: foreground.withOpacity(0.1)),
        ),
        child: Icon(icon, color: foreground, size: 20),
      ),
    );
  }
}

class _PremiumInputField extends StatelessWidget {
  final String label;
  final TextEditingController controller;
  final TextInputType keyboardType;
  final int maxLines;

  /// When set, the field itself turns red and shows this message underneath —
  /// validation stays on the field instead of a snackbar over the page.
  final String? errorText;
  final ValueChanged<String>? onChanged;

  /// Blocks invalid characters as the user types (e.g. digits in a name).
  final List<TextInputFormatter>? inputFormatters;

  const _PremiumInputField({
    required this.label,
    required this.controller,
    this.keyboardType = TextInputType.text,
    this.maxLines = 1,
    this.errorText,
    this.onChanged,
    this.inputFormatters,
  });

  static const _errorColor = Color(0xFFC65B46);

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final hasError = errorText != null;
    return Container(
      margin: const EdgeInsets.only(bottom: 20),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          ClipRRect(
            borderRadius: BorderRadius.circular(15),
            child: BackdropFilter(
              filter: ImageFilter.blur(sigmaX: 15, sigmaY: 15),
              child: Container(
                padding: const EdgeInsets.symmetric(
                  horizontal: 22,
                  vertical: 9,
                ),
                decoration: BoxDecoration(
                  // Web parity: white field with a soft shadow.
                  color: isDark
                      ? Colors.white.withOpacity(0.04)
                      : const Color(0xFFF4EFE3),
                  borderRadius: BorderRadius.circular(16),
                  border: Border.all(
                    color: hasError
                        ? _errorColor
                        : (isDark ? Colors.white : Color(0xFF0C312B))
                              .withOpacity(0.08),
                    width: hasError ? 1.5 : 1,
                  ),
                  boxShadow: isDark
                      ? null
                      : [
                          BoxShadow(
                            color: Colors.black.withOpacity(0.05),
                            blurRadius: 18,
                            offset: const Offset(0, 8),
                          ),
                        ],
                ),
                child: TextFormField(
                  controller: controller,
                  keyboardType: keyboardType,
                  maxLines: maxLines,
                  onChanged: onChanged,
                  inputFormatters: inputFormatters,
                  cursorColor: Theme.of(context).colorScheme.onSurface,
                  style: GoogleFonts.inter(
                    color: Theme.of(context).colorScheme.onSurface,
                    fontSize: 15.5,
                    fontWeight: FontWeight.w700,
                  ),
                  // Web parity: a placeholder that disappears on typing (not a
                  // floating label that sits above the typed text).
                  decoration: InputDecoration(
                    isCollapsed: true,
                    hintText: label,
                    // Was 14px / 68% — the placeholder read as washed out.
                    hintStyle: GoogleFonts.inter(
                      color: hasError
                          ? _errorColor.withOpacity(0.85)
                          : Theme.of(
                              context,
                            ).colorScheme.onSurface.withOpacity(0.82),
                      fontSize: 14.5,
                      fontWeight: FontWeight.w600,
                    ),
                    filled: false,
                    border: InputBorder.none,
                    enabledBorder: InputBorder.none,
                    focusedBorder: InputBorder.none,
                  ),
                ),
              ),
            ),
          ),
          if (hasError)
            Padding(
              padding: const EdgeInsets.only(left: 10, top: 6),
              child: Text(
                errorText!,
                style: GoogleFonts.inter(
                  color: _errorColor,
                  fontSize: 11,
                  fontWeight: FontWeight.w600,
                ),
              ),
            ),
        ],
      ),
    );
  }
}

class _PremiumDropdownField extends StatelessWidget {
  final String label;
  final String? value;
  final List<String> options;
  final Function(String?) onChanged;

  const _PremiumDropdownField({
    required this.label,
    this.value,
    required this.options,
    required this.onChanged,
  });

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    return Container(
      margin: const EdgeInsets.only(bottom: 20),
      child: ClipRRect(
        borderRadius: BorderRadius.circular(15),
        child: BackdropFilter(
          filter: ImageFilter.blur(sigmaX: 15, sigmaY: 15),
          child: Container(
            padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 18),
            decoration: BoxDecoration(
              color: (isDark ? Colors.white : Color(0xFF0C312B)).withOpacity(
                0.03,
              ),
              borderRadius: BorderRadius.circular(15),
              border: Border.all(
                color: (isDark ? Colors.white : Color(0xFF0C312B)).withOpacity(
                  0.05,
                ),
              ),
            ),
            child: DropdownButtonHideUnderline(
              child: DropdownButtonFormField<String>(
                value: value,
                dropdownColor: isDark
                    ? const Color(0xFF141B3A)
                    : const Color(0xFFF4EFE3),
                style: GoogleFonts.inter(
                  color: Theme.of(context).colorScheme.onSurface,
                  fontSize: 13,
                ),
                icon: Icon(
                  LucideIcons.chevronDown,
                  color: Theme.of(
                    context,
                  ).colorScheme.onSurface.withOpacity(0.3),
                  size: 16,
                ),
                decoration: InputDecoration(
                  labelText: label,
                  labelStyle: GoogleFonts.inter(
                    color: Theme.of(
                      context,
                    ).colorScheme.onSurface.withOpacity(0.68),
                    fontSize: 13,
                  ),
                  filled: false,
                  border: InputBorder.none,
                  enabledBorder: InputBorder.none,
                  focusedBorder: InputBorder.none,
                  contentPadding: EdgeInsets.zero,
                ),
                items: options
                    .toSet()
                    .map(
                      (opt) => DropdownMenuItem(value: opt, child: Text(opt)),
                    )
                    .toList(),
                onChanged: onChanged,
              ),
            ),
          ),
        ),
      ),
    );
  }
}

class _PremiumFormField extends StatelessWidget {
  final String label;
  final bool hasDropdown;
  const _PremiumFormField({required this.label, this.hasDropdown = false});

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;

    return Container(
      margin: const EdgeInsets.only(bottom: 20),
      child: ClipRRect(
        borderRadius: BorderRadius.circular(15),
        child: BackdropFilter(
          filter: ImageFilter.blur(sigmaX: 10, sigmaY: 10),
          child: Container(
            padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 22),
            decoration: BoxDecoration(
              color: (isDark ? Colors.white : Color(0xFF0C312B)).withOpacity(
                0.03,
              ),
              borderRadius: BorderRadius.circular(15),
              border: Border.all(
                color: (isDark ? Colors.white : Color(0xFF0C312B)).withOpacity(
                  0.05,
                ),
              ),
            ),
            child: Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Text(
                  label,
                  style: GoogleFonts.inter(
                    color: Theme.of(
                      context,
                    ).colorScheme.onSurface.withOpacity(0.68),
                    fontSize: 13,
                    fontWeight: FontWeight.w500,
                  ),
                ),
                if (hasDropdown)
                  Icon(
                    LucideIcons.chevronDown,
                    color: Theme.of(
                      context,
                    ).colorScheme.onSurface.withOpacity(0.3),
                    size: 16,
                  ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}

class _GlassSearchField extends StatelessWidget {
  final Function(String) onChanged;
  const _GlassSearchField({required this.onChanged});

  @override
  Widget build(BuildContext context) {
    return ClipRRect(
      borderRadius: BorderRadius.circular(20),
      child: BackdropFilter(
        filter: ImageFilter.blur(sigmaX: 25, sigmaY: 25),
        child: Container(
          height: 60,
          padding: const EdgeInsets.symmetric(horizontal: 20),
          decoration: BoxDecoration(
            color: Colors.white.withOpacity(0.4),
            borderRadius: BorderRadius.circular(20),
            border: Border.all(color: Colors.white.withOpacity(0.4)),
          ),
          child: Row(
            children: [
              const Icon(LucideIcons.search, color: Colors.white, size: 20),
              const SizedBox(width: 15),
              Expanded(
                child: TextField(
                  cursorColor: Theme.of(context).brightness == Brightness.dark
                      ? Colors.white
                      : Theme.of(context).colorScheme.onSurface,
                  onChanged: onChanged,
                  style: GoogleFonts.inter(color: Colors.black, fontSize: 15),
                  decoration: InputDecoration(
                    hintText: 'Search residences...',
                    hintStyle: GoogleFonts.inter(
                      color: Colors.black45,
                      fontSize: 13,
                    ),
                    filled: false,
                    border: InputBorder.none,
                    enabledBorder: InputBorder.none,
                    focusedBorder: InputBorder.none,
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class _GlassIconButton extends StatelessWidget {
  final IconData icon;
  final VoidCallback onTap;
  final double size;
  const _GlassIconButton({
    required this.icon,
    required this.onTap,
    this.size = 60,
  });

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onTap,
      child: ClipRRect(
        borderRadius: BorderRadius.circular(20),
        child: BackdropFilter(
          filter: ImageFilter.blur(sigmaX: 25, sigmaY: 25),
          child: Container(
            height: size,
            width: size,
            decoration: BoxDecoration(
              color: Colors.white.withOpacity(0.4),
              borderRadius: BorderRadius.circular(20),
              border: Border.all(color: Colors.white.withOpacity(0.4)),
            ),
            child: Icon(icon, color: Colors.black, size: 20),
          ),
        ),
      ),
    );
  }
}

class _WebTab extends StatelessWidget {
  final String label;
  final bool isActive;
  final VoidCallback onTap;

  const _WebTab({
    required this.label,
    this.isActive = false,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    final onSurface = Theme.of(context).colorScheme.onSurface;
    return GestureDetector(
      onTap: onTap,
      child: Container(
        padding: const EdgeInsets.only(bottom: 8),
        decoration: BoxDecoration(
          border: isActive
              ? Border(bottom: BorderSide(color: onSurface, width: 2))
              : null,
        ),
        child: Text(
          label,
          style: GoogleFonts.inter(
            color: isActive ? onSurface : onSurface.withOpacity(0.55),
            fontSize: 12,
            fontWeight: FontWeight.w600,
            letterSpacing: 2,
          ),
        ),
      ),
    );
  }
}

class _UpdateCard extends StatelessWidget {
  final String title;
  final String type;
  final String date;
  final String imageUrl;
  final String snippet;
  final VoidCallback onTap;

  const _UpdateCard({
    required this.title,
    required this.type,
    required this.date,
    required this.imageUrl,
    required this.snippet,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    return GestureDetector(
      onTap: onTap,
      child: Container(
        width: 280,
        margin: const EdgeInsets.only(left: 20, right: 10),
        decoration: BoxDecoration(
          color: (isDark ? Colors.white : Color(0xFF0C312B)).withOpacity(0.04),
          borderRadius: BorderRadius.circular(20),
          border: Border.all(
            color: (isDark ? Colors.white : Color(0xFF0C312B)).withOpacity(
              0.05,
            ),
          ),
        ),
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            ClipRRect(
              borderRadius: BorderRadius.circular(25),
              child: CachedNetworkImage(
                imageUrl: imageUrl,
                height: 120,
                width: double.infinity,
                fit: BoxFit.cover,
                placeholder: (context, url) =>
                    Container(height: 120, color: Colors.black12),
                errorWidget: (_, __, ___) => Container(color: Colors.white10),
              ),
            ),
            const SizedBox(height: 16),
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Container(
                  padding: const EdgeInsets.symmetric(
                    horizontal: 8,
                    vertical: 4,
                  ),
                  decoration: BoxDecoration(
                    color: Theme.of(
                      context,
                    ).colorScheme.onSurface.withOpacity(0.05),
                    borderRadius: BorderRadius.circular(8),
                  ),
                  child: Text(
                    type,
                    style: GoogleFonts.inter(
                      fontSize: 7,
                      fontWeight: FontWeight.w600,
                      color: Theme.of(
                        context,
                      ).colorScheme.onSurface.withOpacity(0.5),
                    ),
                  ),
                ),
                Text(
                  date,
                  style: GoogleFonts.inter(
                    fontSize: 8,
                    fontWeight: FontWeight.bold,
                    color: Theme.of(
                      context,
                    ).colorScheme.onSurface.withOpacity(0.72),
                  ),
                ),
              ],
            ),
            const SizedBox(height: 12),
            Text(
              title,
              style: GoogleFonts.inter(
                fontSize: 12,
                fontWeight: FontWeight.w600,
                color: Theme.of(context).colorScheme.onSurface,
                letterSpacing: -0.5,
              ),
              maxLines: 1,
              overflow: TextOverflow.ellipsis,
            ),
            const SizedBox(height: 6),
            Text(
              snippet,
              style: GoogleFonts.inter(
                fontSize: 9,
                color: Theme.of(context).colorScheme.onSurface.withOpacity(0.5),
                height: 1.4,
              ),
              maxLines: 2,
              overflow: TextOverflow.ellipsis,
            ),
          ],
        ),
      ),
    );
  }
}

class _MediaCard extends StatelessWidget {
  final String imageUrl;
  final String title;
  final VoidCallback onTap;

  const _MediaCard({
    required this.imageUrl,
    required this.title,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        width: 280,
        margin: const EdgeInsets.only(right: 20),
        decoration: BoxDecoration(
          borderRadius: BorderRadius.circular(20),
          boxShadow: [
            BoxShadow(
              color: Colors.black.withOpacity(0.1),
              blurRadius: 10,
              offset: const Offset(0, 5),
            ),
          ],
        ),
        child: ClipRRect(
          borderRadius: BorderRadius.circular(20),
          child: Stack(
            children: [
              M4Image(
                imageUrl: imageUrl,
                height: double.infinity,
                width: double.infinity,
                fit: BoxFit.cover,
                placeholder: Container(color: Colors.black12),
                errorWidget: Container(color: Colors.white10),
              ),
              Container(
                decoration: BoxDecoration(
                  gradient: LinearGradient(
                    begin: Alignment.topCenter,
                    end: Alignment.bottomCenter,
                    colors: [
                      Colors.transparent,
                      Colors.black.withOpacity(0.75),
                    ],
                    stops: const [0.5, 1.0],
                  ),
                ),
              ),
              Positioned(
                top: 16,
                left: 16,
                child: Container(
                  padding: const EdgeInsets.symmetric(
                    horizontal: 10,
                    vertical: 5,
                  ),
                  decoration: BoxDecoration(
                    color: Colors.black.withOpacity(0.6),
                    borderRadius: BorderRadius.circular(6),
                    border: Border.all(color: Colors.white.withOpacity(0.15)),
                  ),
                  child: Text(
                    'ARTISTIC IMPRESSION',
                    style: GoogleFonts.gelasio(
                      color: Colors.white,
                      fontSize: 7,
                      fontWeight: FontWeight.w700,
                      letterSpacing: 1.5,
                    ),
                  ),
                ),
              ),
              Positioned(
                bottom: 22,
                left: 22,
                right: 22,
                child: Text(
                  title.toUpperCase(),
                  maxLines: 2,
                  overflow: TextOverflow.ellipsis,
                  style: GoogleFonts.gelasio(
                    color: Colors.white,
                    fontSize: 20,
                    fontWeight: FontWeight.w400,
                    letterSpacing: -0.5,
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class _CommunityCard extends StatelessWidget {
  final String title;
  final String description;
  final String imageUrl;
  final VoidCallback onTap;

  const _CommunityCard({
    required this.title,
    required this.description,
    required this.imageUrl,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        width: 300,
        margin: const EdgeInsets.only(right: 20, bottom: 10),
        decoration: BoxDecoration(
          borderRadius: BorderRadius.circular(40),
          boxShadow: [
            BoxShadow(
              color: Colors.black.withOpacity(0.15),
              blurRadius: 20,
              offset: const Offset(0, 10),
            ),
          ],
        ),
        child: ClipRRect(
          borderRadius: BorderRadius.circular(40),
          child: Stack(
            fit: StackFit.expand,
            children: [
              M4Image(
                imageUrl: imageUrl,
                height: double.infinity,
                width: double.infinity,
                fit: BoxFit.cover,
                placeholder: Container(color: Colors.black12),
                errorWidget: Container(color: Colors.white10),
              ),
              Container(
                decoration: BoxDecoration(
                  gradient: LinearGradient(
                    begin: Alignment.topCenter,
                    end: Alignment.bottomCenter,
                    stops: const [0.3, 1.0],
                    colors: [
                      Colors.transparent,
                      Colors.black.withOpacity(0.85),
                    ],
                  ),
                ),
              ),
              Positioned(
                bottom: 24,
                left: 24,
                right: 24,
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      title.toUpperCase(),
                      style: GoogleFonts.gelasio(
                        color: Colors.white,
                        fontSize: 22,
                        fontWeight: FontWeight.w700,
                        letterSpacing: -0.5,
                      ),
                    ),
                    const SizedBox(height: 10),
                    Text(
                      description,
                      style: GoogleFonts.inter(
                        color: Colors.white.withOpacity(0.7),
                        fontSize: 10,
                        fontWeight: FontWeight.w500,
                        letterSpacing: 0.5,
                        height: 1.4,
                      ),
                      maxLines: 2,
                      overflow: TextOverflow.ellipsis,
                    ),
                    const SizedBox(height: 24),
                    Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        Text(
                          'EXPLORE COMMUNITY',
                          style: GoogleFonts.inter(
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
                                color: Colors.black.withOpacity(0.2),
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
}
