import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:m4_mobile/core/theme/app_theme.dart';
import 'package:flutter_animate/flutter_animate.dart';
import 'package:lucide_icons/lucide_icons.dart';
import 'package:google_fonts/google_fonts.dart';
import 'dart:ui';
import 'package:m4_mobile/presentation/widgets/guest_sidebar_menu.dart';
import 'package:m4_mobile/core/network/api_client.dart';
import 'package:m4_mobile/presentation/providers/auth_provider.dart';
import 'package:m4_mobile/presentation/screens/projects/guest_project_detail_screen.dart';
import 'package:m4_mobile/presentation/screens/projects/project_list_screen.dart';
import 'package:m4_mobile/presentation/screens/communities/community_detail_screen.dart';
import 'package:m4_mobile/presentation/screens/communities/community_list_screen.dart';
import 'dart:async';
import 'package:go_router/go_router.dart';
import 'package:url_launcher/url_launcher.dart';
import 'package:cached_network_image/cached_network_image.dart';

class GuestDashboardScreen extends ConsumerStatefulWidget {
  const GuestDashboardScreen({super.key});

  @override
  ConsumerState<GuestDashboardScreen> createState() => _GuestDashboardScreenState();
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
    _fetchData();
    _heroTimer = Timer.periodic(const Duration(seconds: 3), (timer) {
      if (mounted && _projects.isNotEmpty) {
        setState(() => _heroIndex = (_heroIndex + 1) % (_projects.length > 5 ? 5 : _projects.length));
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
      final results = await Future.wait([
        apiClient.getProjects(),
        apiClient.getCommunities(),
        apiClient.getContent('media'),
      ]);

      if (mounted) {
        setState(() {
          _projects = results[0].data['data'] ?? [];
          _communities = results[1].data['data'] ?? [];
          _media = results[2].data['data'] ?? [];
          
          // 💡 Add dummy content if media is empty to fill blank space
          if (_media.isEmpty) {
            _media = [
              {
                '_id': 'dummy1',
                'title': 'CLÉDOR LUXURY LIVING',
                'thumbnail': 'https://images.unsplash.com/photo-1600210492486-724fe5c67fb0?auto=format&fit=crop&q=80',
                'description': 'Discover the epitome of refinement in our latest architectural masterpiece.',
                'slug': 'cledor-luxury-living'
              },
              {
                '_id': 'dummy2',
                'title': 'OCEAN VIEW RESIDENCES',
                'thumbnail': 'https://images.unsplash.com/photo-1512917774080-9991f1c4c750?auto=format&fit=crop&q=80',
                'description': 'Where horizon meets home. Experience coastal elegance like never before.',
                'slug': 'ocean-view-residences'
              },
              {
                '_id': 'dummy3',
                'title': 'URBAN SANCTUARY',
                'thumbnail': 'https://images.unsplash.com/photo-1484154218962-a197022b5858?auto=format&fit=crop&q=80',
                'description': 'A peaceful retreat in the heart of the city.',
                'slug': 'urban-sanctuary'
              }
            ];
          }
          _loading = false;
        });
      }
    } catch (e) {
      if (mounted) setState(() => _loading = false);
    }
  }

  void _scrollToInterestForm() {
    final context = _interestFormKey.currentContext;
    if (context != null) {
      Scrollable.ensureVisible(context, duration: const Duration(seconds: 1), curve: Curves.easeInOut);
    }
  }

  Future<void> _submitInterest() async {
    if (_nameController.text.isEmpty || _emailController.text.isEmpty || _phoneController.text.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('Please fill all required fields (*)')));
      return;
    }
    if (!_agreedToTerms) {
      ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('Please agree to the Privacy Policy')));
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
        ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('Interest registered successfully!'), backgroundColor: Colors.green));
        _nameController.clear();
        _emailController.clear();
        _phoneController.clear();
        _messageController.clear();
        setState(() => _agreedToTerms = false);
      }
    } catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text('Submission failed: $e')));
    } finally {
      if (mounted) setState(() => _submitting = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    if (_loading) return Material(color: Theme.of(context).scaffoldBackgroundColor, child: Center(child: CircularProgressIndicator(color: M4Theme.premiumBlue)));

    return Material(
      color: Theme.of(context).scaffoldBackgroundColor,
      child: CustomScrollView(
        controller: _scrollController,
        slivers: [
          // ⭐️ FIXED HEADER (Web Parity)
          SliverAppBar(
            pinned: true,
            toolbarHeight: 120,
            backgroundColor: Theme.of(context).scaffoldBackgroundColor.withOpacity(0.9),
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
                          size: 24
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
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.center,
                children: [
                  // ⭐️ Tagline (Living the M4 Life)
                  Transform.translate(
                    offset: const Offset(0, -50),
                    child: Padding(
                      padding: const EdgeInsets.symmetric(vertical: 0),
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
                          height: 200, // 👈 Reduced from 300
                          fit: BoxFit.fitWidth,
                        ),
                      ),
                    ),
                  ),

                  // Hero Image Container
                  Transform.translate(
                    offset: const Offset(0, -110), // 👈 Adjusted from -140 to fix overlap
                    child: Padding(
                      padding: const EdgeInsets.symmetric(horizontal: 24),
                      child: Builder(
                    builder: (context) {
                      final mainImage = _projects.isNotEmpty 
                          ? (_projects[_heroIndex % _projects.length]['heroImage'] ?? _projects[_heroIndex % _projects.length]['image'] ?? 'https://images.unsplash.com/photo-1545324418-cc1a3fa10c00?auto=format&fit=crop&q=80')
                          : [
                              'https://images.unsplash.com/photo-1545324418-cc1a3fa10c00?auto=format&fit=crop&q=80',
                              'https://images.unsplash.com/photo-1512917774080-9991f1c4c750?auto=format&fit=crop&q=80',
                              'https://images.unsplash.com/photo-1484154218962-a197022b5858?auto=format&fit=crop&q=80'
                            ][_heroIndex % 3];
                      
                      return Stack(
                        children: [
                          AspectRatio(
                            aspectRatio: 4 / 3,
                            child: Container(
                              decoration: BoxDecoration(
                                borderRadius: BorderRadius.circular(32),
                                boxShadow: [
                                  BoxShadow(
                                    color: Colors.black.withOpacity(0.15),
                                    blurRadius: 30,
                                    offset: const Offset(0, 15),
                                  ),
                                ],
                              ),
                              child: ClipRRect(
                                borderRadius: BorderRadius.circular(32),
                        child: AnimatedSwitcher(
                          duration: const Duration(milliseconds: 800),
                          transitionBuilder: (Widget child, Animation<double> animation) {
                            return FadeTransition(opacity: animation, child: child);
                          },
                          child: CachedNetworkImage(
                            key: ValueKey<int>(_heroIndex),
                            imageUrl: mainImage.toString().startsWith('http') 
                                ? mainImage.toString() 
                                : ref.read(apiClientProvider).resolveUrl(mainImage.toString()),
                            fit: BoxFit.cover,
                            width: double.infinity,
                            height: double.infinity,
                            placeholder: (context, url) => Container(color: Colors.black12),
                            errorWidget: (context, url, error) => Container(
                              color: Colors.white10,
                              child: const Center(child: Icon(LucideIcons.image, color: Colors.white24, size: 50)),
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
                              padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                              decoration: BoxDecoration(
                                color: Colors.black.withOpacity(0.4),
                                borderRadius: BorderRadius.circular(4),
                                border: Border.all(color: Colors.white.withOpacity(0.1)),
                              ),
                              child: Text(
                                'ARTISTIC IMPRESSION',
                                style: GoogleFonts.montserrat(
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
                                final isSelected = (_heroIndex % 3) == index;
                                return AnimatedContainer(
                                  duration: const Duration(milliseconds: 300),
                                  margin: const EdgeInsets.symmetric(horizontal: 4),
                                  width: isSelected ? 32 : 24,
                                  height: 4,
                                  decoration: BoxDecoration(
                                    color: isSelected ? Colors.black : Colors.white.withValues(alpha: 0.5),
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
          SliverPadding(
            padding: const EdgeInsets.only(bottom: 32),
            sliver: SliverList(
              delegate: SliverChildListDelegate([
                Transform.translate(
                  offset: const Offset(0, -60),
                  child: Padding(
                    padding: const EdgeInsets.symmetric(horizontal: 24),
                    child: _buildTabsSection(),
                  ),
                ),
                const SizedBox(height: 30),
                Padding(
                  padding: const EdgeInsets.symmetric(horizontal: 24),
                  child: _buildPhilosophy(),
                ),
                const SizedBox(height: 60),
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
            style: GoogleFonts.montserrat(
              color: Theme.of(context).colorScheme.onSurface.withOpacity(0.6),
              fontSize: 14,
              height: 1.8,
            ),
            children: [
              const TextSpan(text: 'To redefine modern luxury living by crafting homes with cutting edge design, enduring quality and thoughtful amenities delivered with trust, transparency, timeliness, and a human touch that creates lasting value for every homeowner. '),
              WidgetSpan(
                child: GestureDetector(
                  onTap: () => context.push('/about'),
                  child: Text('Who We Are', style: GoogleFonts.montserrat(color: isDark ? Colors.white : Colors.black, fontWeight: FontWeight.bold, decoration: TextDecoration.underline)),
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
                      onTap: () => setState(() => _activeTab = tab[0].toUpperCase() + tab.substring(1)),
                      child: Padding(
                        padding: const EdgeInsets.only(right: 24),
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(
                              tab.toUpperCase(), 
                              style: GoogleFonts.montserrat(
                                color: isSelected 
                                    ? (isDark ? Colors.white : Colors.black) 
                                    : (isDark ? Colors.white : Colors.black).withValues(alpha: 0.4), 
                                fontSize: 12, 
                                fontWeight: FontWeight.w900, 
                                letterSpacing: 2,
                              )
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
        SizedBox(
          height: 360,
          child: ListView.builder(
            scrollDirection: Axis.horizontal,
            physics: const BouncingScrollPhysics(),
            itemCount: _activeTab == 'Communities' 
                ? _communities.length 
                : (_activeTab == 'Media' ? _media.length : _projects.length),
            itemBuilder: (context, index) {
              final item = _activeTab == 'Communities' 
                  ? _communities[index] 
                  : (_activeTab == 'Media' ? _media[index] : _projects[index]);
              return _buildTabCard(item);
            },
          ),
        ),
      ],
    );
  }

  Widget _buildTabCard(dynamic item) {
    final isCommunity = _activeTab.toLowerCase() == 'communities';
    final isMedia = _activeTab.toLowerCase() == 'media';
    final apiClient = ref.read(apiClientProvider);
    final isDark = Theme.of(context).brightness == Brightness.dark;
    
    final imageUrl = apiClient.resolveUrl(isCommunity 
        ? (item['image'] ?? 'https://images.unsplash.com/photo-1486406146926-c627a92ad1ab?auto=format&fit=crop&q=80')
        : (isMedia 
            ? (item['thumbnail'] ?? item['image'] ?? 'https://images.unsplash.com/photo-1556761175-b413da4baf72?auto=format&fit=crop&q=80')
            : (item['heroImage'] ?? 'https://images.unsplash.com/photo-1613545325278-f24b0cae1224?auto=format&fit=crop&q=80')));

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
        margin: const EdgeInsets.only(right: 20, bottom: 20),
        decoration: BoxDecoration(
          borderRadius: BorderRadius.circular(40),
          boxShadow: [
            BoxShadow(
              color: Colors.black.withValues(alpha: 0.15),
              blurRadius: 20,
              offset: const Offset(0, 10),
            )
          ],
        ),
        child: ClipRRect(
          borderRadius: BorderRadius.circular(40),
          child: Stack(
            fit: StackFit.expand,
            children: [
              // 🖼️ High Resolution Image
              CachedNetworkImage(
                imageUrl: imageUrl, 
                fit: BoxFit.cover,
                placeholder: (context, url) => Container(color: Colors.black12),
                errorWidget: (context, url, error) => const Icon(Icons.error),
              ),
              
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
                  child: Container(
                    width: 60,
                    height: 60,
                    decoration: BoxDecoration(
                      color: Colors.white.withValues(alpha: 0.2),
                      shape: BoxShape.circle,
                      border: Border.all(color: Colors.white.withValues(alpha: 0.4), width: 2),
                    ),
                    child: const Center(
                      child: Icon(LucideIcons.play, color: Colors.white, size: 30),
                    ),
                  ).animate().scale(begin: const Offset(0.8, 0.8), curve: Curves.elasticOut, duration: 800.ms),
                ),

              // 🏷️ Badge (for Properties/Media)
              if (!isCommunity)
                Positioned(
                  top: 24,
                  right: 24,
                  child: Container(
                    padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
                    decoration: BoxDecoration(
                      color: Colors.black.withValues(alpha: 0.6),
                      borderRadius: BorderRadius.circular(20),
                      border: Border.all(color: Colors.white.withValues(alpha: 0.1)),
                    ),
                    child: Text(
                      isMedia 
                          ? 'MEDIA' 
                          : (item['status']?.toString() ?? 'ONGOING').toUpperCase(), 
                      style: GoogleFonts.montserrat(color: Colors.white, fontSize: 8, fontWeight: FontWeight.w400, letterSpacing: 1)
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
                      (item['title'] ?? item['name'] ?? '').toString().toUpperCase(), 
                      style: GoogleFonts.dmSerifDisplay(
                        color: Colors.white, 
                        fontSize: 22, 
                        fontWeight: FontWeight.w400,
                        letterSpacing: -0.5,
                      )
                    ),
                    const SizedBox(height: 10),
                    Text(
                      (isCommunity 
                        ? (item['overview'] ?? item['description'] ?? '') 
                        : (item['location'] is Map ? item['location']['name'] : item['location'] ?? 'MAZGAON')).toString().toUpperCase(),
                      maxLines: 2,
                      overflow: TextOverflow.ellipsis,
                      style: GoogleFonts.montserrat(
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
                          isCommunity ? 'EXPLORE COMMUNITY' : (isMedia ? 'READ ARTICLE' : 'VIEW PROPERTY'),
                          style: GoogleFonts.montserrat(
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
                              )
                            ],
                          ),
                          child: const Icon(LucideIcons.arrowRight, color: Colors.black, size: 18),
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

  Widget _buildFeaturedSection() {
    if (_projects.isEmpty) return const SizedBox.shrink();
    final project = _projects[_featuredIndex % _projects.length];
    final apiClient = ref.read(apiClientProvider);
    final isDark = Theme.of(context).brightness == Brightness.dark;

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

        // ⭐️ Main Artistic Card
        Container(
          margin: const EdgeInsets.symmetric(horizontal: 24),
          decoration: BoxDecoration(
            borderRadius: BorderRadius.circular(50),
            boxShadow: [
              BoxShadow(
                color: Colors.black.withOpacity(0.2),
                blurRadius: 40,
                offset: const Offset(0, 20),
              )
            ],
          ),
          child: ClipRRect(
            borderRadius: BorderRadius.circular(50),
            child: Stack(
              children: [
                CachedNetworkImage(
                  imageUrl: apiClient.resolveUrl(project['heroImage'] ?? ''),
                  height: 520, 
                  width: double.infinity, 
                  fit: BoxFit.cover,
                  placeholder: (context, url) => Container(color: Colors.black12),
                  errorWidget: (context, url, error) => const Icon(Icons.error),
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
                  top: 24, right: 24,
                  child: Container(
                    padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
                    decoration: BoxDecoration(
                      color: Colors.black.withOpacity(0.6), 
                      borderRadius: BorderRadius.circular(4),
                      border: Border.all(color: Colors.white.withOpacity(0.2)),
                    ),
                    child: Text(
                      'ARTISTIC IMPRESSION', 
                      style: GoogleFonts.montserrat(color: Colors.white, fontSize: 7, fontWeight: FontWeight.w900, letterSpacing: 1.5)
                    ),
                  ),
                ),
                // Content Overlay
                Positioned(
                  bottom: 40, left: 32, right: 32,
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        'FEATURED PROPERTY', 
                        style: GoogleFonts.montserrat(color: const Color(0xFFC5A358), fontSize: 9, fontWeight: FontWeight.w900, letterSpacing: 2.5)
                      ),
                      const SizedBox(height: 12),
                      Text(
                        (project['title'] ?? '').toString(), 
                        style: GoogleFonts.lora(color: Colors.white, fontSize: 44, fontWeight: FontWeight.w400, height: 1, letterSpacing: -1)
                      ),
                      const SizedBox(height: 16),
                      Text(
                        (project['startingPrice'] ?? project['description'] ?? '').toUpperCase(),
                        maxLines: 2, 
                        overflow: TextOverflow.ellipsis,
                        style: GoogleFonts.montserrat(color: Colors.white.withOpacity(0.8), fontSize: 9, height: 1.6, fontWeight: FontWeight.w900, letterSpacing: 1.2),
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
              _buildFeatureIcon(LucideIcons.smartphone, 'SMART\nHOMES'),
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
                onTap: () => setState(() => _featuredIndex = (_featuredIndex - 1 + _projects.length) % _projects.length),
                child: Container(
                  width: 56,
                  height: 56,
                  decoration: BoxDecoration(
                    color: Colors.transparent,
                    shape: BoxShape.circle,
                    border: Border.all(color: (isDark ? Colors.white : Colors.black).withOpacity(0.1)),
                  ),
                  child: Icon(LucideIcons.arrowLeft, color: isDark ? Colors.white : Colors.black, size: 20),
                ),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: _ScaleButton(
                  onTap: () => context.push('/projects/${project['_id']}', extra: project),
                  child: Container(
                    height: 56,
                    decoration: BoxDecoration(
                      color: isDark ? Colors.white : Colors.black, 
                      borderRadius: BorderRadius.circular(14),
                      boxShadow: [
                        BoxShadow(color: Colors.black.withOpacity(0.2), blurRadius: 20, offset: const Offset(0, 10))
                      ],
                    ),
                    child: Center(
                      child: Text(
                        'READ MORE', 
                        style: GoogleFonts.montserrat(color: isDark ? Colors.black : Colors.white, fontWeight: FontWeight.w900, fontSize: 12, letterSpacing: 3)
                      ),
                    ),
                  ),
                ),
              ),
              const SizedBox(width: 12),
              _ScaleButton(
                onTap: () => setState(() => _featuredIndex = (_featuredIndex + 1) % _projects.length),
                child: Container(
                  width: 56,
                  height: 56,
                  decoration: BoxDecoration(
                    color: Colors.transparent,
                    shape: BoxShape.circle,
                    border: Border.all(color: (isDark ? Colors.white : Colors.black).withOpacity(0.1)),
                  ),
                  child: Icon(LucideIcons.arrowRight, color: isDark ? Colors.white : Colors.black, size: 20),
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
        Text(label, textAlign: TextAlign.center, style: GoogleFonts.montserrat(color: isDark ? Colors.white : Colors.black, fontSize: 9, fontWeight: FontWeight.w800, letterSpacing: 1.5)),
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
        decoration: BoxDecoration(color: isDark ? Colors.black : Colors.white, borderRadius: BorderRadius.circular(16), border: Border.all(color: (isDark ? Colors.white : Colors.black).withOpacity(0.05))),
        child: Icon(icon, color: isDark ? Colors.white70 : Colors.black87, size: 20),
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
            color: isDark ? Colors.white.withOpacity(0.03) : Colors.black.withOpacity(0.02),
            borderRadius: BorderRadius.circular(32),
            border: Border.all(color: (isDark ? Colors.white : Colors.black).withOpacity(0.08)),
            boxShadow: [
              BoxShadow(
                color: Colors.black.withOpacity(0.03),
                blurRadius: 20,
                offset: const Offset(0, 10),
              )
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
                _buildConnectItem(LucideIcons.building2, 'EXPLORE PROJECTS', 'Browse our portfolio of properties', () => Navigator.push(context, MaterialPageRoute(builder: (context) => const ProjectListScreen()))),
                _buildConnectItem(LucideIcons.calendarDays, 'BOOK A VIEWING', 'Schedule a visit to our show apartment', _scrollToInterestForm),
                _buildConnectItem(LucideIcons.image, 'MEDIA GALLERY', 'Watch films and view property renders', () => context.push('/media')),
                _buildConnectItem(LucideIcons.user, 'REGISTER INTEREST', 'Register your interest in our properties', _scrollToInterestForm),
              ],
            ),
          ),
        ),
      ],
    );
  }

  Widget _buildConnectItem(IconData icon, String title, String desc, VoidCallback onTap) {
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
                border: Border.all(color: (isDark ? Colors.white : Colors.black).withOpacity(0.1)),
              ),
              child: Icon(icon, color: isDark ? Colors.white : Colors.black, size: 20),
            ),
            const SizedBox(height: 16),
            Text(
              title,
              textAlign: TextAlign.center,
              style: GoogleFonts.montserrat(
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
              style: GoogleFonts.montserrat(
                color: (isDark ? Colors.white : Colors.black).withOpacity(0.5),
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
          )
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
              child: Text("I've read and agree to the Privacy Policy", style: GoogleFonts.montserrat(color: isDark ? Colors.white54 : Colors.black54, fontSize: 11, letterSpacing: 1)),
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
              decoration: BoxDecoration(color: isDark ? Colors.white : Colors.black, borderRadius: BorderRadius.circular(16)),
              child: Center(
                child: _submitting 
                    ? CircularProgressIndicator(color: isDark ? Colors.black : Colors.white)
                    : Text('SUBMIT INTEREST', style: GoogleFonts.montserrat(color: isDark ? Colors.black : Colors.white, fontWeight: FontWeight.w400, letterSpacing: 2)),
              ),
            ),
          ),
        ),
      ],
    );
  }

  Widget _buildLuxuryInput(String hint, TextEditingController controller, {bool isLong = false}) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    return Container(
      decoration: BoxDecoration(
        color: isDark ? Colors.black : Colors.white, 
        borderRadius: BorderRadius.circular(16), 
        border: Border.all(color: (isDark ? Colors.white : Colors.black).withOpacity(0.12)),
        boxShadow: isDark ? [] : [
          BoxShadow(color: Colors.black.withOpacity(0.05), blurRadius: 20, offset: const Offset(0, 10))
        ]
      ),
      child: TextField(
        controller: controller,
        style: TextStyle(color: isDark ? Colors.white : Colors.black),
        maxLines: isLong ? 5 : 1,
        decoration: InputDecoration(
          hintText: hint,
          hintStyle: GoogleFonts.montserrat(color: isDark ? Colors.white54 : Colors.black45, fontSize: 13),
          contentPadding: const EdgeInsets.symmetric(horizontal: 24, vertical: 20),
          border: InputBorder.none,
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

class _ScaleButtonState extends State<_ScaleButton> with SingleTickerProviderStateMixin {
  late AnimationController _controller;
  late Animation<double> _scale;

  @override
  void initState() {
    super.initState();
    _controller = AnimationController(vsync: this, duration: const Duration(milliseconds: 100));
    _scale = Tween<double>(begin: 1.0, end: 0.95).animate(CurvedAnimation(parent: _controller, curve: Curves.easeInOut));
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
