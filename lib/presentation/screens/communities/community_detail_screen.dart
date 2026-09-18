import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:m4_mobile/presentation/widgets/m4_map_view.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:lucide_icons/lucide_icons.dart';
import 'package:flutter_animate/flutter_animate.dart';
import 'dart:ui';
import 'package:m4_mobile/core/theme/app_theme.dart';
import 'package:m4_mobile/core/utils/validators.dart';
import 'package:m4_mobile/presentation/providers/auth_provider.dart';
import 'package:m4_mobile/presentation/screens/projects/project_detail_screen.dart';
import 'package:url_launcher/url_launcher.dart';
import 'package:m4_mobile/core/utils/support_handlers.dart';
import 'package:m4_mobile/core/network/api_client.dart';
import 'package:m4_mobile/presentation/widgets/conditional_drawer.dart';
import 'package:cached_network_image/cached_network_image.dart';
import 'package:go_router/go_router.dart';
import 'package:m4_mobile/presentation/providers/cp_shell_provider.dart';
import 'package:m4_mobile/presentation/widgets/cp_bottom_nav.dart';

/// Project imagery arrives either as a URL or as an inline `data:image;base64`
/// payload (the CMS stores some heroes that way — Skyline Heights is one).
/// CachedNetworkImage is an HTTP loader and renders a data URI as an empty box,
/// so those are decoded to bytes instead.
Widget _communityProjectImage(String url) {
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
        fit: BoxFit.cover,
        cacheWidth: 1080,
        errorBuilder: (_, _, _) => fallback(),
      );
    } catch (_) {
      return fallback();
    }
  }
  return CachedNetworkImage(
    memCacheWidth: 1080,
    imageUrl: url,
    fit: BoxFit.cover,
    placeholder: (context, u) => Container(color: Colors.black12),
    errorWidget: (context, u, e) => fallback(),
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
  final ScrollController _scrollController = ScrollController();
  final GlobalKey _inquiryKey = GlobalKey();
  List<dynamic> _projects = [];
  bool _projectsLoading = true;
  bool _isSubmitting = false;
  bool _aboutExpanded = false;
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
      var communityId = (widget.community['_id'] ?? widget.community['id'])
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
            'Expressing interest in community: ${widget.community['title']}'
            '${_selectedProject != 'Any' ? ' | Interested Project: $_selectedProject' : ''}',
        'projectName': _selectedProject != 'Any'
            ? _selectedProject
            : widget.community['title'],
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
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final user = ref.watch(authProvider).user;
    final role = user?['role']?.toString().toLowerCase();
    final isCp = role == 'cp';
    final cpIdx = ref.watch(cpNavigationIndexProvider);
    final apiClient = ref.watch(apiClientProvider);
    // Match the community card/thumbnail image exactly: use the community's own
    // image when present, otherwise the same Unsplash fallback the card uses
    // (guest_dashboard `_pickImage([item['image']], …photo-1486406146926…)`), so
    // the detail hero shows the same picture the thumbnail does.
    final rawCommunityImage = (widget.community['image'] ?? '')
        .toString()
        .trim();
    final heroImageUrl = rawCommunityImage.isNotEmpty
        ? apiClient.resolveUrl(rawCommunityImage)
        : 'https://images.unsplash.com/photo-1486406146926-c627a92ad1ab?auto=format&fit=crop&q=80';
    final benefitsRaw = widget.community['benefits'] as List? ?? [];
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
                    Container(
                      decoration: BoxDecoration(
                        gradient: LinearGradient(
                          begin: Alignment.topCenter,
                          end: Alignment.bottomCenter,
                          colors: [
                            Colors.transparent,
                            Colors.black.withOpacity(0.8),
                          ],
                        ),
                      ),
                    ),
                    // Web: `absolute bottom-10 left-8 right-8`.
                    Positioned(
                      bottom: 40,
                      left: 32,
                      right: 32,
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            widget.community['title']?.toString() ?? '',
                            style: GoogleFonts.gelasio(
                              // Web: `text-3xl font-light tracking-tight` — a
                              // light serif, not the heavy weight we had.
                              fontSize: 34,
                              fontWeight: FontWeight.w500,
                              letterSpacing: -0.8,
                              color: Colors.white,
                              height: 1.05,
                              shadows: const [
                                Shadow(
                                  blurRadius: 12,
                                  color: const Color(0xFF155A4F),
                                ),
                              ],
                            ),
                          ).animate().fadeIn(delay: 200.ms).slideY(begin: 0.2),
                          const SizedBox(height: 12),
                          Text(
                            (widget.community['subtitle'] ?? '')
                                .toString()
                                .toUpperCase(),
                            style: GoogleFonts.gelasio(
                              color: const Color(0xFFF4EFE3),
                              fontSize: 10,
                              fontWeight: FontWeight.w700,
                              letterSpacing: 3,
                            ),
                          ).animate().fadeIn(delay: 400.ms),
                        ],
                      ),
                    ),
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
                        widget.community['location'] ?? 'Dubai',
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
                            (widget.community['location'] ?? '')
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
                        'About ${widget.community['title']?.toString() ?? 'Community'}',
                  ),
                  const SizedBox(height: 25),
                  _buildAboutBody(
                    (widget.community['overview'] ??
                            widget.community['description'] ??
                            '')
                        .toString(),
                    isDark,
                  ),

                  const SizedBox(height: 50),

                  // Benefits
                  // Web shows a bare "BENEFITS" heading — no kicker.
                  const _SectionHeader(title: 'Benefits', subtitle: ''),
                  const SizedBox(height: 30),
                  // Web parity: compact fixed-size squares packed from the left
                  // (measured 126×126 with a 12px gap), NOT a 2-column grid —
                  // that stretched each card to half the screen and pushed a
                  // wide gap between them. Wrap also flows to a second row once
                  // there are more than two benefits.
                  Wrap(
                    spacing: 12,
                    runSpacing: 12,
                    children: benefits.map((benefit) {
                      // Web parity: three across, in reading order. The fixed
                      // 126 only ever fitted two on a phone.
                      final cell = (MediaQuery.of(context).size.width - 74) / 3;
                      return SizedBox(
                        width: cell,
                        height: cell - 10,
                        child: Container(
                          decoration: BoxDecoration(
                            color:
                                (isDark
                                        ? Colors.white
                                        : const Color(0xFF0C312B))
                                    .withOpacity(0.04),
                            borderRadius: BorderRadius.circular(16),
                            border: Border.all(
                              color:
                                  (isDark
                                          ? Colors.white
                                          : const Color(0xFF0C312B))
                                      .withOpacity(0.06),
                            ),
                          ),
                          child: Column(
                            mainAxisAlignment: MainAxisAlignment.center,
                            children: [
                              Container(
                                width: 48,
                                height: 48,
                                decoration: BoxDecoration(
                                  color:
                                      (isDark
                                              ? Colors.white
                                              : const Color(0xFF0C312B))
                                          .withOpacity(0.1),
                                  borderRadius: BorderRadius.circular(16),
                                ),
                                child: Icon(
                                  _getIcon(benefit['icon']),
                                  color: isDark
                                      ? Colors.white
                                      : const Color(0xFF0C312B),
                                  size: 24,
                                ),
                              ),
                              const SizedBox(height: 12),
                              Padding(
                                padding: const EdgeInsets.symmetric(
                                  horizontal: 6,
                                ),
                                child: Text(
                                  benefit['label'].toString().toUpperCase(),
                                  maxLines: 2,
                                  overflow: TextOverflow.ellipsis,
                                  textAlign: TextAlign.center,
                                  style: GoogleFonts.inter(
                                    color:
                                        (isDark
                                                ? Colors.white
                                                : const Color(0xFF0C312B))
                                            .withOpacity(0.7),
                                    fontSize: 8,
                                    fontWeight: FontWeight.w600,
                                    letterSpacing: 0.5,
                                    height: 1.4,
                                  ),
                                ),
                              ),
                            ],
                          ),
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
                                'Explore ${widget.community['title']?.toString() ?? 'Community'} Masterpieces',
                          ),
                        ),
                        TextButton(
                          onPressed: () => Navigator.push(
                            context,
                            MaterialPageRoute(
                              builder: (context) => CommunityProjectsScreen(
                                community: widget.community,
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
                      height: 140,
                      child: ListView.builder(
                        scrollDirection: Axis.horizontal,
                        itemCount: _projects.length,
                        itemBuilder: (context, index) {
                          final project = _projects[index];
                          return GestureDetector(
                            onTap: () => Navigator.push(
                              context,
                              MaterialPageRoute(
                                builder: (context) => ProjectDetailScreen(
                                  projectId: project['_id'] ?? project['id'],
                                  projectData: project,
                                ),
                              ),
                            ),
                            child: Container(
                              width: 248,
                              margin: const EdgeInsets.only(right: 14),
                              decoration: BoxDecoration(
                                borderRadius: BorderRadius.circular(20),
                              ),
                              child: ClipRRect(
                                borderRadius: BorderRadius.circular(20),
                                child: Stack(
                                  fit: StackFit.expand,
                                  children: [
                                    _communityProjectImage(
                                      apiClient.resolveUrl(
                                        project['heroImage'] ??
                                            project['image'],
                                      ),
                                    ),
                                    Container(
                                      decoration: BoxDecoration(
                                        gradient: LinearGradient(
                                          begin: Alignment.topCenter,
                                          end: Alignment.bottomCenter,
                                          colors: [
                                            Colors.transparent,
                                            Colors.black.withOpacity(0.8),
                                          ],
                                        ),
                                      ),
                                    ),
                                    Padding(
                                      padding: const EdgeInsets.all(20),
                                      child: Column(
                                        mainAxisAlignment:
                                            MainAxisAlignment.end,
                                        crossAxisAlignment:
                                            CrossAxisAlignment.start,
                                        children: [
                                          Text(
                                            project['title']
                                                    ?.toString()
                                                    .toUpperCase() ??
                                                '',
                                            style: GoogleFonts.inter(
                                              color: Colors.white,
                                              fontSize: 16,
                                              fontWeight: FontWeight.w600,
                                              letterSpacing: -0.5,
                                            ),
                                          ),
                                          const SizedBox(height: 4),
                                          if (project['startingPrice'] !=
                                                  null &&
                                              project['startingPrice']
                                                      .toString()
                                                      .toLowerCase() !=
                                                  'price on request' &&
                                              project['startingPrice']
                                                      .toString()
                                                      .toLowerCase() !=
                                                  'upon request')
                                            Padding(
                                              padding: const EdgeInsets.only(
                                                bottom: 2,
                                              ),
                                              child: Text(
                                                project['startingPrice']
                                                    .toString()
                                                    .toUpperCase(),
                                                style: GoogleFonts.inter(
                                                  color: Colors.white70,
                                                  fontSize: 10,
                                                  fontWeight: FontWeight.w700,
                                                  letterSpacing: 0.5,
                                                ),
                                              ),
                                            ),
                                          Row(
                                            children: [
                                              const Icon(
                                                LucideIcons.mapPin,
                                                color: Colors.white54,
                                                size: 10,
                                              ),
                                              const SizedBox(width: 5),
                                              Text(
                                                (project['location']?['name'] ??
                                                        project['location'] ??
                                                        '')
                                                    .toString()
                                                    .toUpperCase(),
                                                style: GoogleFonts.inter(
                                                  color: Colors.white70,
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
                                    Positioned(
                                      bottom: 20,
                                      right: 20,
                                      child: Container(
                                        width: 35,
                                        height: 35,
                                        decoration: const BoxDecoration(
                                          color: const Color(0xFFF4EFE3),
                                          shape: BoxShape.circle,
                                        ),
                                        child: const Icon(
                                          LucideIcons.arrowRight,
                                          color: const Color(0xFF0C312B),
                                          size: 18,
                                        ),
                                      ),
                                    ),
                                  ],
                                ),
                              ),
                            ),
                          );
                        },
                      ),
                    ),
                    const SizedBox(height: 60),
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
                              ? CircularProgressIndicator(
                                  color: Theme.of(
                                    context,
                                  ).scaffoldBackgroundColor,
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
  /// Long copy is collapsed to the first few paragraphs behind Read more,
  /// matching the community list's control.
  static const int _aboutCollapsedParagraphs = 3;

  Widget _buildAboutBody(String raw, bool isDark) {
    final fg = isDark ? Colors.white : const Color(0xFF0C312B);
    final paragraphs = raw
        .split(RegExp(r'\n[ \t]*\n'))
        .map((p) => p.trim())
        .where((p) => p.isNotEmpty)
        .toList();

    if (paragraphs.isEmpty) return const SizedBox.shrink();

    final hasMore = paragraphs.length > _aboutCollapsedParagraphs;
    final shown = (!hasMore || _aboutExpanded)
        ? paragraphs
        : paragraphs.take(_aboutCollapsedParagraphs).toList();

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        for (var i = 0; i < shown.length; i++) ...[
          if (i > 0) const SizedBox(height: 14),
          Text(
            shown[i],
            style: GoogleFonts.inter(
              color: fg.withOpacity(0.6),
              fontSize: 14,
              height: 1.55,
              fontWeight: FontWeight.w500,
            ),
          ),
        ],
        if (hasMore) ...[
          const SizedBox(height: 16),
          GestureDetector(
            onTap: () => setState(() => _aboutExpanded = !_aboutExpanded),
            child: Container(
              padding: const EdgeInsets.only(bottom: 2),
              decoration: BoxDecoration(
                border: Border(
                  bottom: BorderSide(color: fg.withOpacity(0.3), width: 1),
                ),
              ),
              child: Text(
                _aboutExpanded ? 'Read less' : 'Read more',
                style: GoogleFonts.inter(
                  color: isDark ? Colors.white : const Color(0xFF155A4F),
                  fontSize: 13,
                  fontWeight: FontWeight.w600,
                ),
              ),
            ),
          ),
        ],
      ],
    ).animate().fadeIn(delay: 200.ms);
  }

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
                  onTap: () => Navigator.push(
                    context,
                    MaterialPageRoute(
                      builder: (context) => ProjectDetailScreen(
                        projectId: project['_id'] ?? project['id'],
                        projectData: project,
                      ),
                    ),
                  ),
                  child: AspectRatio(
                    aspectRatio: 16 / 9,
                    child: Container(
                      margin: const EdgeInsets.only(bottom: 16),
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
                      child: ClipRRect(
                        borderRadius: BorderRadius.circular(20),
                        child: Stack(
                          fit: StackFit.expand,
                          children: [
                            CachedNetworkImage(
                              memCacheWidth: 1080,
                              imageUrl: apiClient.resolveUrl(
                                project['heroImage'] ?? project['image'],
                              ),
                              fit: BoxFit.cover,
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
                            // Gradient Overlays
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

                            // Status Label (Top Right)
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
                                      color: Colors.white,
                                      fontSize: 8,
                                      fontWeight: FontWeight.w700,
                                      letterSpacing: 1.5,
                                    ),
                                  ),
                                ),
                              ),

                            // Top Left Block: Title & Location
                            Positioned(
                              top: 18,
                              left: 18,
                              right: 75,
                              child: Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                mainAxisSize: MainAxisSize.min,
                                children: [
                                  Text(
                                    (project['title'] ?? '')
                                        .toString()
                                        .toUpperCase(),
                                    style: GoogleFonts.gelasio(
                                      color: Colors.white,
                                      fontSize: 20,
                                      fontWeight: FontWeight.w700,
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
                                        color: Colors.white.withValues(alpha: 0.7),
                                        size: 10,
                                      ),
                                      const SizedBox(width: 4),
                                      Expanded(
                                        child: Text(
                                          location.toUpperCase(),
                                          style: GoogleFonts.gelasio(
                                            color: Colors.white.withValues(alpha: 0.7),
                                            fontSize: 8,
                                            fontWeight: FontWeight.w700,
                                            letterSpacing: 1.5,
                                          ),
                                          maxLines: 1,
                                          overflow: TextOverflow.ellipsis,
                                        ),
                                      ),
                                    ],
                                  ),
                                  if (startingPrice != null &&
                                      startingPrice.isNotEmpty &&
                                      startingPrice.toLowerCase() !=
                                          'price on request' &&
                                      startingPrice.toLowerCase() !=
                                          'upon request') ...[
                                    const SizedBox(height: 4),
                                    Text(
                                      'STARTING FROM',
                                      style: GoogleFonts.gelasio(
                                        color: Colors.white.withValues(alpha: 0.65),
                                        fontSize: 7,
                                        fontWeight: FontWeight.w700,
                                        letterSpacing: 1.5,
                                      ),
                                    ),
                                    Text(
                                      startingPrice.toUpperCase(),
                                      style: GoogleFonts.inter(
                                        color: const Color(0xFFF4EFE3),
                                        fontSize: 13,
                                        fontWeight: FontWeight.w600,
                                      ),
                                    ),
                                  ],
                                ],
                              ),
                            ),

                            // Bottom Left: Artistic Impression
                            Positioned(
                              bottom: 16,
                              left: 18,
                              child: Text(
                                '* ARTISTIC IMPRESSION',
                                style: GoogleFonts.gelasio(
                                  color: Colors.white.withValues(alpha: 0.75),
                                  fontSize: 6,
                                  fontWeight: FontWeight.w700,
                                  letterSpacing: 1.5,
                                ),
                              ),
                            ),

                            // Bottom Right: Arrow Action Button
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
