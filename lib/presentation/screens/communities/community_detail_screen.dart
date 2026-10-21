import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:m4_mobile/core/utils/media_url.dart';
import 'package:m4_mobile/presentation/widgets/image_overlay_label.dart';
import 'package:m4_mobile/presentation/widgets/m4_map_view.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:m4_mobile/presentation/providers/live_sync_provider.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:lucide_icons/lucide_icons.dart';
import 'package:flutter_animate/flutter_animate.dart';
import 'dart:ui';
import 'package:m4_mobile/core/theme/app_theme.dart';
import 'package:m4_mobile/core/utils/validators.dart';
import 'package:m4_mobile/presentation/providers/auth_provider.dart';
import 'package:m4_mobile/presentation/screens/projects/project_detail_screen.dart';
import 'package:m4_mobile/presentation/screens/projects/guest_project_detail_screen.dart';
import 'package:url_launcher/url_launcher.dart';
import 'package:m4_mobile/core/utils/support_handlers.dart';
import 'package:m4_mobile/core/network/api_client.dart';
import 'package:m4_mobile/presentation/widgets/conditional_drawer.dart';
import 'package:m4_mobile/presentation/widgets/article_text.dart';
import 'package:m4_mobile/presentation/widgets/luxury_amenity_icon.dart';
import 'package:cached_network_image/cached_network_image.dart';
import 'package:go_router/go_router.dart';
import 'package:m4_mobile/presentation/providers/cp_shell_provider.dart';
import 'package:m4_mobile/presentation/widgets/cp_bottom_nav.dart';
import 'package:m4_mobile/presentation/widgets/home_image_card.dart';

/// Project imagery arrives either as a URL or as an inline `data:image;base64`
/// payload (the CMS stores some heroes that way — Skyline Heights is one).
/// CachedNetworkImage is an HTTP loader and renders a data URI as an empty box,
/// so those are decoded to bytes instead.
Widget _communityProjectImage(String url, {BoxFit fit = BoxFit.cover}) {
  Widget fallback() => Container(
    color: const Color(0xFF141B3A),
    child: const Center(
      child: Icon(LucideIcons.building2, color: Colors.white24, size: 40),
    ),
  );
  if (url.isEmpty) return fallback();
  if (url.startsWith('data:')) {
    try {
      final bytes = base64Decode(
        url.substring(url.indexOf(',') + 1).replaceAll(RegExp(r'\s'), ''),
      );
      return Image.memory(
        bytes,
        fit: fit,
        cacheWidth: 1080,
        errorBuilder: (_, _, _) => fallback(),
      );
    } catch (_) {
      return fallback();
    }
  }
  return CachedNetworkImage(
    fadeInDuration: Duration.zero,
    fadeOutDuration: Duration.zero,
    memCacheWidth: 1080,
    imageUrl: url,
    fit: fit,
    placeholder: (context, u) => Container(color: Colors.black12),
    errorWidget: (context, u, e) => fallback(),
  );
}

/// Opens a community project the same way the project list and search do:
/// logged-in users get the full project screen, guests get the guest screen.
/// Shared by the community page and the community projects list.
void openCommunityProject(
  BuildContext context,
  WidgetRef ref,
  dynamic project,
) {
  final projectId = (project['_id'] ?? project['id'])?.toString() ?? '';
  if (projectId.isEmpty) return;
  final loggedIn = ref.read(authProvider).status == AuthStatus.authenticated;
  Navigator.push(
    context,
    MaterialPageRoute(
      builder: (context) => loggedIn
          ? ProjectDetailScreen(projectId: projectId, projectData: project)
          : GuestProjectDetailScreen(projectId: projectId, projectData: project),
    ),
  );
}

class CommunityDetailScreen extends ConsumerStatefulWidget {
  final dynamic community;
  const CommunityDetailScreen({super.key, required this.community});

  @override
  ConsumerState<CommunityDetailScreen> createState() =>
      _CommunityDetailScreenState();
}

class _CommunityDetailScreenState extends ConsumerState<CommunityDetailScreen> {
  // Fresh copy of this community from the server (live sync), merged over the
  // one the screen was opened with. Until it arrives the original is shown.
  Map<String, dynamic>? _freshCommunity;
  dynamic get _community => _freshCommunity ?? widget.community;

  /// Re-reads this community so admin edits to its title, description, images
  /// and benefits show while the screen is open. Merged over the current copy:
  /// the by-slug endpoint omits fields the list carries (e.g. projectCount).
  Future<void> _refreshCommunity() async {
    final current = _community;
    if (current is! Map) return;
    final id = (current['_id'] ?? current['id'])?.toString() ?? '';
    final isObjectId =
        id.length == 24 && !id.contains(RegExp(r'[^0-9a-fA-F]'));
    // Routes opened without `extra` carry the slug in `_id`.
    final slug = (current['slug'] ?? (isObjectId ? '' : id)).toString();
    if (slug.isEmpty) return;
    try {
      final res = await ref.read(apiClientProvider).getCommunityBySlug(slug);
      final body = res.data;
      final data = body is Map ? (body['data'] ?? body) : null;
      if (!mounted || data is! Map) return;
      setState(() {
        _freshCommunity = Map<String, dynamic>.from(current)
          ..addAll(Map<String, dynamic>.from(data));
      });
    } catch (_) {}
  }

  final ScrollController _scrollController = ScrollController();
  final GlobalKey _inquiryKey = GlobalKey();
  List<dynamic> _projects = [];
  bool _projectsLoading = true;
  bool _isSubmitting = false;
  String _selectedProject = 'Any';

  final TextEditingController _nameController = TextEditingController();
  final TextEditingController _emailController = TextEditingController();
  final TextEditingController _phoneController = TextEditingController();
  final TextEditingController _locationController = TextEditingController();

  void _scrollToInquiry() {
    Scrollable.ensureVisible(
      _inquiryKey.currentContext!,
      duration: const Duration(milliseconds: 800),
      curve: Curves.easeInOut,
    );
  }

  @override
  void initState() {
    super.initState();
    _fetchCommunityProjects();
  }

  @override
  void dispose() {
    _scrollController.dispose();
    _nameController.dispose();
    _emailController.dispose();
    _phoneController.dispose();
    _locationController.dispose();
    super.dispose();
  }

  Future<void> _fetchCommunityProjects() async {
    try {
      final apiClient = ref.read(apiClientProvider);
      var communityId = (_community['_id'] ?? _community['id'])
          ?.toString();
      // Routes that open this screen without `extra` put the SLUG in `_id`.
      // The projects endpoint casts that value straight to an ObjectId and
      // answers 500 ("Cast to ObjectId failed"), which silently left the
      // carousel empty. An ObjectId is 24 hex chars; anything else is a slug,
      // so look the community up first and use its real id.
      final isObjectId =
          communityId != null &&
          communityId.length == 24 &&
          !communityId.contains(RegExp(r'[^0-9a-fA-F]'));
      if (communityId != null && communityId.isNotEmpty && !isObjectId) {
        final look = await apiClient.getCommunityBySlug(communityId);
        final body = look.data;
        final data = body is Map ? (body['data'] ?? body) : null;
        if (data is Map) {
          communityId = (data['_id'] ?? data['id'])?.toString();
        }
      }
      if (communityId != null && communityId.isNotEmpty) {
        final res = await apiClient.getProjectsByCommunity(communityId);
        if (!mounted) return;
        if (res.data['status'] == true) {
          setState(() {
            _projects = res.data['data'] as List;
            _projectsLoading = false;
          });
        } else {
          setState(() => _projectsLoading = false);
        }
      } else {
        setState(() => _projectsLoading = false);
      }
    } catch (e) {
      debugPrint('Community projects failed: $e');
      if (mounted) setState(() => _projectsLoading = false);
    }
  }

  Future<void> _handleLeadSubmission() async {
    final validationError =
        Validators.nameError(_nameController.text, field: 'full name') ??
        Validators.emailError(_emailController.text) ??
        Validators.phoneError(_phoneController.text);
    if (validationError != null) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          backgroundColor: const Color(0xFFC65B46),
          content: Text(validationError),
        ),
      );
      return;
    }

    setState(() => _isSubmitting = true);
    try {
      final apiClient = ref.read(apiClientProvider);
      await apiClient.submitLead({
        'name': _nameController.text,
        'email': _emailController.text,
        'phone': _phoneController.text,
        'location': _locationController.text,
        // Server-side enums: interest = Buying | Selling | Site Visit | Video
        // Call (case-sensitive); source = online | cp | walk-in | referral |
        // other. Anything else is rejected with a 400.
        'interest': 'Buying',
        'message':
            'Expressing interest in community: ${_community['title']}'
            '${_selectedProject != 'Any' ? ' | Interested Project: $_selectedProject' : ''}',
        'projectName': _selectedProject != 'Any'
            ? _selectedProject
            : _community['title'],
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
        _locationController.clear();
        setState(() => _selectedProject = 'Any');
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            backgroundColor: const Color(0xFFC65B46),
            content: Text('Submission failed: $e'),
          ),
        );
      }
    } finally {
      if (mounted) setState(() => _isSubmitting = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    // Admin edits: reload in place when the server reports a change.
    listenForAdminChanges(
      ref,
      const {SyncTopic.communities},
      _refreshCommunity,
    );
    listenForAdminChanges(
      ref,
      const {SyncTopic.catalog, SyncTopic.communities},
      _fetchCommunityProjects,
    );
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final user = ref.watch(authProvider).user;
    final role = user?['role']?.toString().toLowerCase();
    final isCp = role == 'cp';
    final cpIdx = ref.watch(cpNavigationIndexProvider);
    final apiClient = ref.watch(apiClientProvider);
    // The community's own uploaded image, or nothing. There used to be an
    // Unsplash stand-in here so the hero always had a picture; it meant a
    // community with no artwork quietly showed stock as if it were the
    // client's. Empty lets the renderer draw the branded placeholder.
    final rawCommunityImage = mediaUrlOf(_community['image']);
    final heroImageUrl =
        (rawCommunityImage.isEmpty || isStockImageUrl(rawCommunityImage))
        ? ''
        : apiClient.resolveUrl(rawCommunityImage);
    final benefitsRaw = _community['benefits'] as List? ?? [];
    final benefits = benefitsRaw.isNotEmpty
        ? benefitsRaw
        : [
            {'icon': 'LayoutGrid', 'label': 'COMMUNITY CENTRIC DESIGN'},
            {'icon': 'MapPin', 'label': 'PRIME LOCATION'},
            {'icon': 'Trees', 'label': 'GREEN SPACES AND PARKS'},
            {'icon': 'Shield', 'label': 'SAFETY AND SECURITY'},
            {'icon': 'ShoppingBag', 'label': 'RETAIL OUTLETS'},
            {'icon': 'Bus', 'label': 'TRANSPORTATION ACCESS'},
          ];

    return Scaffold(
      backgroundColor: Theme.of(context).scaffoldBackgroundColor,
      drawer: const ConditionalDrawer(),
      bottomNavigationBar: isCp
          ? CpBottomNav(
              currentIndex: cpIdx,
              onTap: (i) {
                context.go('/home');
                ref.read(cpNavigationIndexProvider.notifier).state = i;
              },
            )
          : null,
      body: CustomScrollView(
        controller: _scrollController,
        slivers: [
          // 🔝 Sticky Header
          SliverToBoxAdapter(
            // Web parity: a single "← Communities" back control, and a hairline
            // under the bar (web `header … border-b border-border`).
            child: Container(
              padding: const EdgeInsets.fromLTRB(24, 56, 24, 18),
              decoration: BoxDecoration(
                border: Border(
                  bottom: BorderSide(
                    color: (isDark ? Colors.white : const Color(0xFF0C312B))
                        .withOpacity(0.08),
                  ),
                ),
              ),
              child: GestureDetector(
                onTap: () => Navigator.pop(context),
                behavior: HitTestBehavior.opaque,
                child: Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Icon(
                      LucideIcons.arrowLeft,
                      color: (isDark ? Colors.white : const Color(0xFF0C312B))
                          .withOpacity(0.7),
                      size: 20,
                    ),
                    const SizedBox(width: 8),
                    Text(
                      'COMMUNITIES',
                      style: GoogleFonts.gelasio(
                        color: (isDark ? Colors.white : const Color(0xFF0C312B))
                            .withOpacity(0.7),
                        fontSize: 13,
                        fontWeight: FontWeight.w700,
                        letterSpacing: 2,
                      ),
                    ),
                  ],
                ),
              ),
            ),
          ),

          // 🏗️ Hero Section
          // The image runs edge to edge with no inset or rounding, at the 16:9
          // ratio every other hero and thumbnail in the app uses.
          SliverToBoxAdapter(
            child: AspectRatio(
              aspectRatio: 16 / 9,
              child: SizedBox(
                width: double.infinity,
                child: Stack(
                  fit: StackFit.expand,
                  children: [
                    CachedNetworkImage(
                      fadeInDuration: Duration.zero,
                      fadeOutDuration: Duration.zero,
                      memCacheWidth: 1080,
                      imageUrl: heroImageUrl,
                      fit: BoxFit.cover,
                      placeholder: (context, url) =>
                          Container(color: Colors.black12),
                      errorWidget: (context, url, error) => Container(
                        color: const Color(0xFF141B3A),
                        child: const Center(
                          child: Icon(
                            LucideIcons.building2,
                            color: Colors.white24,
                            size: 40,
                          ),
                        ),
                      ),
                    ),
                    // No name and no dark shade over the picture: the community
                    // is already named in the header ("ABOUT <NAME>") right
                    // below the hero, so the photo shows clean.
                  ],
                ),
              ),
            ),
          ),

          // 🏗️ Main Content
          SliverToBoxAdapter(
            child: Padding(
              padding: const EdgeInsets.all(25),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  // Location Card
                  GestureDetector(
                    onTap: () async {
                      final query = Uri.encodeComponent(
                        _community['location'] ?? 'Dubai',
                      );
                      final url = Uri.parse(
                        'https://www.google.com/maps/search/?api=1&query=$query',
                      );
                      if (await canLaunchUrl(url)) {
                        await launchUrl(url);
                      }
                    },
                    child: Container(
                      padding: const EdgeInsets.all(20),
                      decoration: BoxDecoration(
                        color: (isDark ? Colors.white : const Color(0xFF0C312B))
                            .withOpacity(0.05),
                        borderRadius: BorderRadius.circular(20),
                        border: Border.all(
                          color:
                              (isDark ? Colors.white : const Color(0xFF0C312B))
                                  .withOpacity(0.1),
                        ),
                      ),
                      child: Row(
                        children: [
                          Container(
                            padding: const EdgeInsets.all(10),
                            decoration: BoxDecoration(
                              color: isDark
                                  ? Colors.white
                                  : const Color(0xFF0C312B),
                              shape: BoxShape.circle,
                            ),
                            child: Icon(
                              LucideIcons.mapPin,
                              color: Theme.of(context).scaffoldBackgroundColor,
                              size: 18,
                            ),
                          ),
                          const SizedBox(width: 15),
                          Text(
                            (_community['location'] ?? '')
                                .toString()
                                .toUpperCase(),
                            style: GoogleFonts.inter(
                              color: isDark
                                  ? Colors.white
                                  : const Color(0xFF155A4F),
                              fontSize: 12,
                              fontWeight: FontWeight.bold,
                              letterSpacing: 1,
                            ),
                          ),
                        ],
                      ),
                    ),
                  ),

                  const SizedBox(height: 50),

                  // About Section
                  // Web parity: the heading is "ABOUT THE COMMUNITY" with the
                  // community name as the kicker beneath it — we had the two
                  // the other way round.
                  _SectionHeader(
                    title: 'About the community',
                    subtitle:
                        'About ${_community['title']?.toString() ?? 'Community'}',
                  ),
                  const SizedBox(height: 25),
                  ArticleText(
                    text:
                        (_community['overview'] ??
                                _community['description'] ??
                                '')
                            .toString(),
                    style: GoogleFonts.inter(
                      color: (isDark ? Colors.white : const Color(0xFF0C312B))
                          .withOpacity(0.6),
                      fontSize: 14,
                      height: 1.55,
                      fontWeight: FontWeight.w500,
                    ),
                    linkColor: isDark
                        ? Colors.white
                        : const Color(0xFF155A4F),
                    // Edge to edge without widened word gaps (plain justify
                    // left big gaps on a phone width), and a tight gap
                    // between paragraphs.
                    balancedJustify: true,
                    paragraphGap: 4,
                  ).animate().fadeIn(delay: 200.ms),

                  const SizedBox(height: 50),

                  // Benefits
                  // Web shows a bare "BENEFITS" heading — no kicker.
                  const _SectionHeader(title: 'Benefits', subtitle: ''),
                  const SizedBox(height: 30),
                  // Same look as a project's Amenities: a bare vector icon with
                  // its label underneath — no card or tile behind it — three
                  // across. Each row's items are top-aligned, so every icon
                  // sits at the same height even when a label wraps to two
                  // lines.
                  Wrap(
                    spacing: 10,
                    runSpacing: 24,
                    children: benefits.map((benefit) {
                      // Content width inside the page's 25px side padding.
                      final cell =
                          (MediaQuery.of(context).size.width - 50 - 20) / 3;
                      final label = benefit is Map
                          ? (benefit['label']?.toString() ?? '')
                          : benefit.toString();
                      // Backend-driven (web parity): each benefit carries an
                      // uploaded icon image in R2 (benefit['image']); only fall
                      // back to a Lucide glyph when it has none.
                      final rawImg =
                          (benefit is Map
                                  ? benefit['image']?.toString()
                                  : null)
                              ?.trim() ??
                          '';
                      return SizedBox(
                        width: cell,
                        child: Column(
                          mainAxisSize: MainAxisSize.min,
                          children: [
                            if (rawImg.isNotEmpty)
                              LuxuryAmenityIcon(
                                name: label,
                                iconUrl: apiClient.resolveUrl(rawImg),
                                // Same size, weight and colour as Amenities.
                                size: kAmenityGridIconSize,
                                emphasized: true,
                                color: amenityGridIconColor(isDark),
                              )
                            else
                              SizedBox.square(
                                dimension: kAmenityGridIconSize,
                                child: Icon(
                                  benefit is Map
                                      ? _getIcon(
                                          benefit['icon']?.toString() ?? '',
                                        )
                                      : LucideIcons.star,
                                  color: amenityGridIconColor(isDark),
                                  size: 40,
                                ),
                              ),
                            const SizedBox(height: 10),
                            Text(
                              label,
                              textAlign: TextAlign.center,
                              maxLines: 2,
                              overflow: TextOverflow.ellipsis,
                              style: GoogleFonts.inter(
                                fontSize: 11,
                                fontWeight: FontWeight.w700,
                                color: isDark
                                    ? Colors.white.withValues(alpha: 0.9)
                                    : const Color(0xFF0C312B),
                                letterSpacing: 0.3,
                                height: 1.2,
                              ),
                            ),
                          ],
                        ),
                      );
                    }).toList(),
                  ),

                  const SizedBox(height: 60),

                  // Projects Section
                  if (_projects.isNotEmpty) ...[
                    Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      crossAxisAlignment: CrossAxisAlignment.end,
                      children: [
                        // _SectionHeader lays its own Row out with an Expanded
                        // inside, so it needs a bounded width. Nested in this
                        // Row it would be unbounded and the layout throws,
                        // which left this section — and everything after it —
                        // occupying space but painting nothing.
                        Expanded(
                          child: _SectionHeader(
                            title: 'Projects',
                            subtitle:
                                'Explore ${_community['title']?.toString() ?? 'Community'} Masterpieces',
                          ),
                        ),
                        TextButton(
                          onPressed: () => Navigator.push(
                            context,
                            MaterialPageRoute(
                              builder: (context) => CommunityProjectsScreen(
                                community: _community,
                                projects: _projects,
                              ),
                            ),
                          ),
                          child: Text(
                            'VIEW ALL',
                            style: GoogleFonts.gelasio(
                              color:
                                  (isDark
                                          ? Colors.white
                                          : const Color(0xFF0C312B))
                                      .withOpacity(0.68),
                              fontSize: 10,
                              fontWeight: FontWeight.w700,
                              letterSpacing: 2,
                            ),
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 30),
                    SizedBox(
                      // The card (picture + name panel), its 10 bottom
                      // margin, and 20 more so the card's shadow fades out
                      // inside the row instead of being cut off by its edge.
                      height: HomeImageCard.heightFor(260) + 30,
                      child: ListView.builder(
                        scrollDirection: Axis.horizontal,
                        padding: const EdgeInsets.only(bottom: 20),
                        // Let the cards' soft shadow fade out past the row's
                        // edges; clipped, it left a hard-edged band under them.
                        clipBehavior: Clip.none,
                        itemCount: _projects.length,
                        itemBuilder: (context, index) {
                          final project = _projects[index];
                          // "From ..." only when there is a price to show.
                          final price =
                              project['startingPrice']?.toString().trim() ??
                              '';
                          final showPrice =
                              price.isNotEmpty &&
                              !['price on request', 'upon request']
                                  .contains(price.toLowerCase());
                          return GestureDetector(
                            onTap: () => openCommunityProject(context, ref, project),
                            // The app's one image card: clean picture, name
                            // and details on a panel beneath it.
                            child: HomeImageCard(
                              width: 260,
                              margin: const EdgeInsets.only(
                                right: 14,
                                bottom: 10,
                              ),
                              image: (fit) => _communityProjectImage(
                                apiClient.resolveUrl(
                                  project['heroImage'] ?? project['image'],
                                ),
                                fit: fit,
                              ),
                              title: project['title']?.toString() ?? '',
                              caption: (project['location']?['name'] ??
                                      project['location'] ??
                                      '')
                                  .toString(),
                              tags: [if (showPrice) 'From $price'],
                            ),
                          );
                        },
                      ),
                    ),
                    // 60 below the cards as before (20 of it is the row's
                    // shadow room above).
                    const SizedBox(height: 40),
                  ],

                  // Express Interest Form
                  Column(
                    key: _inquiryKey,
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      // Web keeps this on one line.
                      const _SectionHeader(
                        title: 'Express interest',
                        subtitle: 'Initialize your premium experience',
                      ),
                      const SizedBox(height: 30),
                      _buildInput(
                        'Enter Full Name',
                        _nameController,
                        keyboardType: TextInputType.name,
                        inputFormatters: Validators.nameFormatters,
                      ),
                      const SizedBox(height: 12),
                      Row(
                        children: [
                          Expanded(
                            child: _buildInput(
                              'Enter Email Address',
                              _emailController,
                              keyboardType: TextInputType.emailAddress,
                              inputFormatters: Validators.emailFormatters,
                            ),
                          ),
                          const SizedBox(width: 12),
                          Expanded(
                            child: _buildInput(
                              'Enter Mobile Number',
                              _phoneController,
                              keyboardType: TextInputType.phone,
                              inputFormatters: Validators.phoneFormatters,
                            ),
                          ),
                        ],
                      ),
                      const SizedBox(height: 12),
                      _buildInput(
                        'Enter City and Country',
                        _locationController,
                      ),
                      const SizedBox(height: 20),
                      SizedBox(
                        width: double.infinity,
                        height: 70,
                        child: ElevatedButton(
                          onPressed: _isSubmitting
                              ? null
                              : _handleLeadSubmission,
                          style: ElevatedButton.styleFrom(
                            backgroundColor: isDark
                                ? Colors.white
                                : const Color(0xFF0C312B),
                            foregroundColor: isDark
                                ? Colors.black
                                : Colors.white,
                            shape: RoundedRectangleBorder(
                              borderRadius: BorderRadius.circular(20),
                            ),
                          ),
                          child: _isSubmitting
                              ? CircularProgressIndicator.adaptive(
                                  valueColor: AlwaysStoppedAnimation<Color>(
                                    Theme.of(context).scaffoldBackgroundColor,
                                  ),
                                )
                              : Text(
                                  'REGISTER INTEREST',
                                  style: GoogleFonts.gelasio(
                                    fontSize: 12,
                                    fontWeight: FontWeight.w700,
                                    letterSpacing: 3,
                                  ),
                                ),
                        ),
                      ),
                      const SizedBox(height: 20),
                      Center(
                        child: Text(
                          'EXCLUSIVE GUEST PREVIEW - LIMITED OPPORTUNITIES',
                          style: GoogleFonts.gelasio(
                            color:
                                (isDark
                                        ? Colors.white
                                        : const Color(0xFF0C312B))
                                    .withOpacity(0.68),
                            fontSize: 8,
                            fontWeight: FontWeight.w700,
                            letterSpacing: 2,
                          ),
                        ),
                      ),
                    ],
                  ),

                  const SizedBox(height: 60),

                  // Map Section
                  const _SectionHeader(
                    title: 'FIND US',
                    subtitle: 'OUR STRATEGIC HEADQUARTERS',
                  ),
                  const SizedBox(height: 15),
                  // The same map card the properties section renders, in place
                  // of the decorative world-map photograph.
                  M4MapView(
                    query: 'M4 Aura Heights, Grant Road, Mumbai - 400007',
                    onOpen: () async {
                      final uri = Uri.parse(
                        'https://www.google.com/maps/search/?api=1&query=604,+6th+Floor,+M4+Aura+Heights,+Grant+Road,+Mumbai+-+400007',
                      );
                      if (await canLaunchUrl(uri)) {
                        await launchUrl(
                          uri,
                          mode: LaunchMode.externalApplication,
                        );
                      }
                    },
                  ),

                  const SizedBox(height: 100),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildInput(
    String hint,
    TextEditingController controller, {
    TextInputType? keyboardType,
    List<TextInputFormatter>? inputFormatters,
  }) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 20),
      decoration: BoxDecoration(
        color: (isDark ? Colors.white : const Color(0xFF0C312B)).withOpacity(
          0.05,
        ),
        borderRadius: BorderRadius.circular(20),
        border: Border.all(
          color: (isDark ? Colors.white : const Color(0xFF0C312B)).withOpacity(
            0.05,
          ),
        ),
      ),
      child: TextField(
        controller: controller,
        keyboardType: keyboardType,
        inputFormatters: inputFormatters,
        style: GoogleFonts.inter(
          color: isDark ? Colors.white : const Color(0xFF155A4F),
          fontSize: 15,
          fontWeight: FontWeight.bold,
        ),
        decoration: InputDecoration(
          filled: false,
          border: InputBorder.none,
          enabledBorder: InputBorder.none,
          focusedBorder: InputBorder.none,
          hintText: hint,
          hintStyle: GoogleFonts.gelasio(
            color: (isDark ? Colors.white : const Color(0xFF0C312B))
                .withOpacity(0.68),
            fontSize: 10,
            fontWeight: FontWeight.w700,
            letterSpacing: 2,
          ),
        ),
      ),
    );
  }

  /// The "About the community" copy.
  ///
  /// The CMS stores one long string with a blank line between paragraphs. It
  /// used to be handed to a single Text at height: 1.8, so every blank line
  /// rendered as a full empty line on top of that generous leading — the wide
  /// gaps down the section. Splitting on the blank lines and spacing the
  /// paragraphs ourselves gives one even rhythm, and a single newline inside a
  /// paragraph (the "A community that grows." run) still breaks the line.
  ///
  IconData _getIcon(String icon) {
    // The CMS is not consistent about how an icon name is written — the same
    // glyph arrives as "LayoutGrid", "layout-grid" or "layout grid" depending
    // on who typed it. Compare on letters only so every spelling resolves to
    // the same icon instead of falling through to the unknown glyph.
    final key = icon.toLowerCase().replaceAll(RegExp(r'[^a-z0-9]'), '');
    switch (key) {
      case 'layoutgrid':
        return LucideIcons.layoutGrid;
      case 'mappin':
      case 'map':
      case 'location':
        return LucideIcons.mapPin;
      case 'trees':
      case 'tree':
      case 'park':
        return LucideIcons.trees;
      case 'shield':
      case 'shieldcheck':
      case 'security':
        return LucideIcons.shield;
      case 'shoppingbag':
      case 'shoppingcart':
      case 'retail':
        return LucideIcons.shoppingBag;
      case 'bus':
      case 'train':
      case 'transport':
        return LucideIcons.bus;
      case 'building':
      case 'building2':
        return LucideIcons.building2;
      case 'car':
      case 'parking':
        return LucideIcons.car;
      case 'waves':
      case 'water':
      case 'waterfront':
        return LucideIcons.waves;
      case 'users':
      case 'community':
        return LucideIcons.users;
      case 'sparkles':
        return LucideIcons.sparkles;
      case 'school':
      case 'graduationcap':
        return LucideIcons.graduationCap;
      case 'hospital':
      case 'heartpulse':
        return LucideIcons.heartPulse;
      default:
        // Web parity: the site draws sparkles for an icon name it does not
        // recognise — checked against the live community page, whose
        // "Central Connect" and "Downtown Access" benefits (names the CMS
        // stores in the icon field, so nothing can resolve them) render as
        // sparkles there.
        //
        // This was switched to a circle-question-mark on the belief that the
        // web showed one; it does not, and a question mark reads as an error
        // rather than a benefit.
        return LucideIcons.sparkles;
    }
  }
}

class _SectionHeader extends StatelessWidget {
  final String title;
  final String subtitle;
  const _SectionHeader({required this.title, required this.subtitle});

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          children: [
            Container(
              width: 4,
              height: 40,
              color: isDark ? Colors.white : const Color(0xFF0C312B),
            ),
            const SizedBox(width: 20),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    // Web parity: the section heading is a heavy uppercase
                    // display line (it wraps), not a light title-case one.
                    title.toUpperCase(),
                    style: GoogleFonts.gelasio(
                      color: isDark ? Colors.white : const Color(0xFF0C312B),
                      fontSize: 24,
                      fontWeight: FontWeight.w700,
                      letterSpacing: -0.5,
                      height: 1.15,
                    ),
                  ),
                  if (subtitle.isNotEmpty) ...[
                    const SizedBox(height: 5),
                    Text(
                      subtitle.toUpperCase(),
                      style: GoogleFonts.gelasio(
                        color: (isDark ? Colors.white : const Color(0xFF0C312B))
                            .withOpacity(0.68),
                        fontSize: 10,
                        fontWeight: FontWeight.w700,
                        letterSpacing: 2,
                      ),
                    ),
                  ],
                ],
              ),
            ),
          ],
        ),
      ],
    );
  }
}

class CommunityProjectsScreen extends ConsumerWidget {
  final dynamic community;
  final List<dynamic> projects;
  const CommunityProjectsScreen({
    super.key,
    required this.community,
    required this.projects,
  });

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final apiClient = ref.watch(apiClientProvider);
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final scheme = Theme.of(context).colorScheme;
    final user = ref.watch(authProvider).user;
    final role = user?['role']?.toString().toLowerCase();
    final isCp = role == 'cp';
    final cpIdx = ref.watch(cpNavigationIndexProvider);

    return Scaffold(
      backgroundColor: scheme.surface,
      bottomNavigationBar: isCp
          ? CpBottomNav(
              currentIndex: cpIdx,
              onTap: (i) {
                context.go('/home');
                ref.read(cpNavigationIndexProvider.notifier).state = i;
              },
            )
          : null,
      body: CustomScrollView(
        slivers: [
          // 🔝 Header
          SliverToBoxAdapter(
            child: Container(
              padding: const EdgeInsets.fromLTRB(25, 60, 25, 20),
              child: Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  GestureDetector(
                    onTap: () => Navigator.pop(context),
                    child: Row(
                      children: [
                        Icon(
                          LucideIcons.arrowLeft,
                          color: isDark
                              ? Colors.white
                              : const Color(0xFF0C312B),
                          size: 20,
                        ),
                        const SizedBox(width: 10),
                        Text(
                          'BACK',
                          style: GoogleFonts.gelasio(
                            color:
                                (isDark
                                        ? Colors.white
                                        : const Color(0xFF0C312B))
                                    .withOpacity(0.68),
                            fontSize: 10,
                            fontWeight: FontWeight.w700,
                            letterSpacing: 2,
                          ),
                        ),
                      ],
                    ),
                  ),
                  Column(
                    crossAxisAlignment: CrossAxisAlignment.end,
                    children: [
                      Text(
                        'M4 FAMILY',
                        style: GoogleFonts.gelasio(
                          color: isDark
                              ? Colors.white
                              : const Color(0xFF0C312B),
                          fontSize: 18,
                          fontWeight: FontWeight.w700,
                          letterSpacing: -1,
                        ),
                      ),
                      Text(
                        'COMMUNITY PORTFOLIO',
                        style: GoogleFonts.inter(
                          color:
                              (isDark ? Colors.white : const Color(0xFF0C312B))
                                  .withOpacity(0.68),
                          fontSize: 8,
                          fontWeight: FontWeight.bold,
                          letterSpacing: 1,
                        ),
                      ),
                    ],
                  ),
                ],
              ),
            ),
          ),

          // 🏗️ Title Section
          SliverToBoxAdapter(
            child: Padding(
              padding: const EdgeInsets.fromLTRB(25, 30, 25, 40),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  _SectionHeader(
                    title: community['title']?.toString().toUpperCase() ?? '',
                    subtitle: 'DISCOVER ALL PROJECTS IN THIS COMMUNITY',
                  ),
                ],
              ),
            ),
          ),

          // 🏗️ Projects List
          SliverPadding(
            padding: const EdgeInsets.symmetric(horizontal: 20),
            sliver: SliverList(
              delegate: SliverChildBuilderDelegate((context, index) {
                final project = projects[index];
                final status = project['status']?.toString() ?? '';
                final startingPrice = project['startingPrice']?.toString();
                final location = (project['location']?['name'] ??
                        project['location'] ??
                        '')
                    .toString();

                return GestureDetector(
                  onTap: () => openCommunityProject(context, ref, project),
                  // The app's one image card: clean picture, name and
                  // details on a panel beneath it.
                  child: HomeImageCard(
                    width: null,
                    margin: const EdgeInsets.only(bottom: 16),
                    image: (fit) => CachedNetworkImage(
                      fadeInDuration: Duration.zero,
                      fadeOutDuration: Duration.zero,
                      memCacheWidth: 1080,
                      imageUrl: apiClient.resolveUrl(
                        project['heroImage'] ?? project['image'],
                      ),
                      fit: fit,
                      placeholder: (context, url) =>
                          Container(color: Colors.black12),
                      errorWidget: (context, url, error) => Container(
                        color: const Color(0xFF141B3A),
                        child: const Center(
                          child: Icon(
                            LucideIcons.building2,
                            color: Colors.white24,
                            size: 36,
                          ),
                        ),
                      ),
                    ),
                    title: project['title']?.toString() ?? '',
                    caption: location,
                    tags: [
                      status,
                      startingPrice != null &&
                              startingPrice.isNotEmpty &&
                              !['price on request', 'upon request']
                                  .contains(startingPrice.toLowerCase())
                          ? 'From $startingPrice'
                          : '',
                    ],
                    // The Admin Panel image-overlay label, only while it is
                    // switched on.
                    imageBadge: ImageOverlayLabel(
                      builder: (label) => Text(
                        '* $label',
                        style: GoogleFonts.gelasio(
                          color: Colors.white.withValues(alpha: 0.85),
                          fontSize: 7,
                          fontWeight: FontWeight.w700,
                          letterSpacing: 1.5,
                        ),
                      ),
                    ),
                  ),
                );
              }, childCount: projects.length),
            ),
          ),
          const SliverToBoxAdapter(child: SizedBox(height: 60)),
        ],
      ),
    );
  }
}
