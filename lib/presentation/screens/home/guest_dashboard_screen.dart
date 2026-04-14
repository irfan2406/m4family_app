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
    _heroTimer = Timer.periodic(const Duration(seconds: 5), (timer) {
      if (mounted) {
        setState(() => _heroIndex = (_heroIndex + 1) % 3);
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
      ]);

      if (mounted) {
        setState(() {
          _projects = results[0].data['data'] ?? [];
          _communities = results[1].data['data'] ?? [];
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
    if (_loading) return Scaffold(body: Center(child: CircularProgressIndicator(color: M4Theme.premiumBlue)));

    return Scaffold(
      key: _scaffoldKey,
      backgroundColor: Theme.of(context).scaffoldBackgroundColor,
      drawer: const GuestSidebarMenu(),
      body: CustomScrollView(
        controller: _scrollController,
        slivers: [
          _buildHeroHeader(),
          SliverPadding(
            padding: const EdgeInsets.symmetric(horizontal: 0, vertical: 32),
            sliver: SliverList(
              delegate: SliverChildListDelegate([
                Padding(
                  padding: const EdgeInsets.symmetric(horizontal: 24),
                  child: _buildTabsSection(),
                ),
                const SizedBox(height: 60),
                Padding(
                  padding: const EdgeInsets.symmetric(horizontal: 24),
                  child: _buildPhilosophy(),
                ),
                const SizedBox(height: 100),
                _buildFeaturedSection(),
                const SizedBox(height: 100),
                Padding(
                  padding: const EdgeInsets.symmetric(horizontal: 24),
                  child: _buildConnectGrid(),
                ),
                const SizedBox(height: 100),
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

  Widget _buildHeroHeader() {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    return SliverToBoxAdapter(
      child: Container(
        padding: const EdgeInsets.only(top: 60, bottom: 20),
        decoration: BoxDecoration(
          color: Theme.of(context).scaffoldBackgroundColor,
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Logo and Menu Row
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 24),
              child: Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text('M4 FAMILY', style: GoogleFonts.montserrat(color: isDark ? Colors.white : Colors.black, fontWeight: FontWeight.w900, fontSize: 18, letterSpacing: -1)),
                      Text('DEVELOPMENTS', style: GoogleFonts.montserrat(color: isDark ? Colors.white60 : Colors.black54, fontWeight: FontWeight.w800, fontSize: 8, letterSpacing: 3)),
                    ],
                  ),
                  _ScaleButton(
                    onTap: () => _scaffoldKey.currentState?.openDrawer(),
                    child: Container(
                      width: 44,
                      height: 34,
                      decoration: BoxDecoration(
                        color: isDark ? Colors.white.withValues(alpha: 0.1) : Colors.black.withValues(alpha: 0.05),
                        borderRadius: BorderRadius.circular(10),
                        border: Border.all(color: isDark ? Colors.white.withValues(alpha: 0.1) : Colors.black.withValues(alpha: 0.1)),
                      ),
                      child: Icon(LucideIcons.moreHorizontal, color: isDark ? Colors.white : Colors.black, size: 20),
                    ),
                  ),
                ],
              ),
            ),
            const SizedBox(height: 50),
            
            // Living the M4 Life Title
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 24),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                   Text(
                    'Living the',
                    style: GoogleFonts.dmSerifDisplay(
                      color: (isDark ? Colors.white : Colors.black).withValues(alpha: 0.9),
                      fontSize: 34,
                      fontWeight: FontWeight.w400,
                      height: 1.1,
                    ),
                  ),
                  Text(
                    'M4 Life',
                    style: GoogleFonts.dmSerifDisplay(
                      color: isDark ? Colors.white : Colors.black,
                      fontSize: 42,
                      fontWeight: FontWeight.w400,
                      height: 1.1,
                    ),
                  ),
                ],
              ),
            ),
            const SizedBox(height: 40),

            // Featured Showcase Carousel (Matches Web Image 1 Centerpiece)
            Container(
              margin: const EdgeInsets.symmetric(horizontal: 24),
              height: 240,
              width: double.infinity,
              decoration: BoxDecoration(
                borderRadius: BorderRadius.circular(40),
                boxShadow: [
                  BoxShadow(color: Colors.black.withValues(alpha: 0.5), blurRadius: 40, spreadRadius: 5),
                ],
              ),
              child: ClipRRect(
                borderRadius: BorderRadius.circular(40),
                child: Stack(
                  children: [
                    AnimatedSwitcher(
                      duration: const Duration(milliseconds: 800),
                      child: Image.network(
                        [
                          'https://images.unsplash.com/photo-1613545325278-f24b0cae1224?auto=format&fit=crop&q=80',
                          'https://images.unsplash.com/photo-1486406146926-c627a92ad1ab?auto=format&fit=crop&q=80',
                          'https://images.unsplash.com/photo-1512917774080-9991f1c4c750?auto=format&fit=crop&q=80'
                        ][_heroIndex],
                        key: ValueKey(_heroIndex),
                        fit: BoxFit.cover,
                        width: double.infinity,
                        height: double.infinity,
                      ),
                    ),
                    Container(
                      decoration: BoxDecoration(
                        gradient: LinearGradient(
                          begin: Alignment.topCenter,
                          end: Alignment.bottomCenter,
                          colors: [Colors.transparent, Colors.black.withValues(alpha: 0.4)],
                        ),
                      ),
                    ),
                    Center(
                      child: _ScaleButton(
                        onTap: () {},
                        child: Container(
                          width: 48,
                          height: 48,
                          decoration: BoxDecoration(
                            color: Colors.white.withValues(alpha: 0.2),
                            shape: BoxShape.circle,
                            border: Border.all(color: Colors.white.withValues(alpha: 0.3)),
                          ),
                          child: const Icon(LucideIcons.play, color: Colors.white, size: 20),
                        ),
                      ),
                    ),
                    Positioned(
                      top: 20,
                      right: 20,
                      child: Container(
                        padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 5),
                        decoration: BoxDecoration(
                          color: Colors.black.withValues(alpha: 0.4),
                          borderRadius: BorderRadius.circular(5),
                          border: Border.all(color: Colors.white.withValues(alpha: 0.1)),
                        ),
                        child: Text('ARTISTIC IMPRESSION', style: GoogleFonts.montserrat(color: Colors.white, fontSize: 7, fontWeight: FontWeight.w900, letterSpacing: 1)),
                      ),
                    ),
                    // Carousel Indicators (Matches Web Image 1 dots)
                    Positioned(
                      bottom: 20,
                      left: 0,
                      right: 0,
                      child: Row(
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: List.generate(3, (index) => Container(
                          width: 24,
                          height: 2,
                          margin: const EdgeInsets.symmetric(horizontal: 4),
                          decoration: BoxDecoration(
                            color: _heroIndex == index ? Colors.white : Colors.white.withValues(alpha: 0.3),
                            borderRadius: BorderRadius.circular(1),
                          ),
                        )),
                      ),
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

  Widget _buildPhilosophy() {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          'OUR PHILOSOPHY', 
          style: GoogleFonts.montserrat(
            color: isDark ? Colors.white : Colors.black, 
            fontSize: 22, 
            fontWeight: FontWeight.w400, 
            letterSpacing: 2
          )
        ),
        const SizedBox(height: 24),
        RichText(
          text: TextSpan(
            style: GoogleFonts.montserrat(color: (isDark ? Colors.white : Colors.black).withValues(alpha: 0.7), fontSize: 13, height: 1.8),
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
            Row(
              children: ['communities', 'properties'].map((tab) {
                final isSelected = _activeTab.toLowerCase() == tab;
                return GestureDetector(
                  onTap: () => setState(() => _activeTab = tab[0].toUpperCase() + tab.substring(1)),
                  child: Padding(
                    padding: const EdgeInsets.only(right: 28),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          tab.toUpperCase(), 
                          style: GoogleFonts.montserrat(
                            color: isSelected 
                                ? (isDark ? Colors.white : Colors.black) 
                                : (isDark ? Colors.white24 : Colors.black26), 
                            fontSize: 10, 
                            fontWeight: FontWeight.w900, 
                            letterSpacing: 1.5
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
            GestureDetector(
              onTap: () {
                if (_activeTab == 'Communities') {
                  context.push('/communities');
                } else {
                  Navigator.push(context, MaterialPageRoute(builder: (context) => const ProjectListScreen()));
                }
              },
              child: Padding(
                padding: const EdgeInsets.only(bottom: 12),
                child: Text(
                  'VIEW ALL', 
                  style: GoogleFonts.montserrat(
                    color: (isDark ? Colors.white : Colors.black).withValues(alpha: 0.9), 
                    fontSize: 10, 
                    fontWeight: FontWeight.w900, 
                    letterSpacing: 1,
                  )
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
            itemCount: _activeTab == 'Communities' ? _communities.length : _projects.length,
            itemBuilder: (context, index) {
              final item = _activeTab == 'Communities' ? _communities[index] : _projects[index];
              return _buildTabCard(item);
            },
          ),
        ),
      ],
    );
  }

  Widget _buildTabCard(dynamic item) {
    final isCommunity = _activeTab == 'Communities';
    final apiClient = ref.read(apiClientProvider);
    final isDark = Theme.of(context).brightness == Brightness.dark;
    
    final imageUrl = apiClient.resolveUrl(isCommunity 
        ? (item['image'] ?? 'https://images.unsplash.com/photo-1486406146926-c627a92ad1ab?auto=format&fit=crop&q=80')
        : (item['heroImage'] ?? 'https://images.unsplash.com/photo-1613545325278-f24b0cae1224?auto=format&fit=crop&q=80'));

    return _ScaleButton(
      onTap: () {
        if (isCommunity) {
          context.push('/communities/${item['_id']}', extra: item);
        } else {
          context.push('/projects/${item['_id']}', extra: item);
        }
      },
      child: ClipRRect(
        borderRadius: BorderRadius.circular(40),
        child: BackdropFilter(
          filter: ImageFilter.blur(sigmaX: 10, sigmaY: 10),
          child: Container(
            width: 300,
            margin: const EdgeInsets.only(right: 20),
            decoration: BoxDecoration(
              color: isDark ? Colors.white.withValues(alpha: 0.03) : Colors.black.withValues(alpha: 0.04),
              borderRadius: BorderRadius.circular(40),
              border: Border.all(color: (isDark ? Colors.white : Colors.black).withValues(alpha: 0.08)),
            ),
            child: Column(
              children: [
                Expanded(
                  flex: 5,
                  child: ClipRRect(
                    borderRadius: const BorderRadius.vertical(top: Radius.circular(40)),
                    child: Stack(
                      fit: StackFit.expand,
                      children: [
                        Image.network(imageUrl, fit: BoxFit.cover, width: double.infinity),
                        if (!isCommunity) ...[
                          Positioned(
                            top: 20, right: 20,
                            child: Container(
                              padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
                              decoration: BoxDecoration(color: Colors.black.withValues(alpha: 0.6), borderRadius: BorderRadius.circular(20), border: Border.all(color: Colors.white.withValues(alpha: 0.1))),
                              child: Text((item['status']?.toString() ?? 'ONGOING').toUpperCase(), style: GoogleFonts.montserrat(color: Colors.white, fontSize: 8, fontWeight: FontWeight.w800, letterSpacing: 1)),
                            ),
                          ),
                        ],
                      ],
                    ),
                  ),
                ),
                Expanded(
                  flex: 4,
                  child: Padding(
                    padding: const EdgeInsets.all(24),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(item['title']?.toString() ?? '', style: GoogleFonts.dmSerifDisplay(color: isDark ? Colors.white : Colors.black, fontSize: 20)),
                        const SizedBox(height: 12),
                        if (isCommunity)
                          Text((item['description'] ?? item['overview'] ?? '').toUpperCase(), maxLines: 2, overflow: TextOverflow.ellipsis, style: GoogleFonts.montserrat(color: Colors.white54, fontSize: 7, fontWeight: FontWeight.w900, letterSpacing: 1.5))
                        else
                          Row(
                            children: [
                              const Icon(LucideIcons.mapPin, color: Colors.white38, size: 8),
                              const SizedBox(width: 6),
                              Text((item['location'] is Map ? item['location']['name'] : item['location'] ?? 'MAZGAON').toString().toUpperCase(), style: GoogleFonts.montserrat(color: Colors.white38, fontSize: 8, fontWeight: FontWeight.w900, letterSpacing: 1)),
                            ],
                          ),
                        const Spacer(),
                        Container(
                          height: 44,
                          decoration: BoxDecoration(
                            color: isDark ? Colors.white : Colors.black, 
                            borderRadius: BorderRadius.circular(12)
                          ),
                          child: Center(
                            child: Row(
                              mainAxisAlignment: MainAxisAlignment.center,
                              children: [
                                Text('READ MORE', style: GoogleFonts.montserrat(color: isDark ? Colors.black : Colors.white, fontWeight: FontWeight.w900, fontSize: 10, letterSpacing: 1)),
                                const SizedBox(width: 8),
                                Icon(LucideIcons.chevronRight, color: isDark ? Colors.black : Colors.white, size: 14),
                              ],
                            ),
                          ),
                        ),
                      ],
                    ),
                  ),
                ),
              ],
            ),
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
        // Header (Matches Image 4)
        Padding(
          padding: const EdgeInsets.symmetric(horizontal: 24),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                'FEATURED',
                style: GoogleFonts.montserrat(
                  color: (isDark ? Colors.white : Colors.black).withValues(alpha: 0.5),
                  fontSize: 12,
                  fontWeight: FontWeight.w900,
                  letterSpacing: 4,
                ),
              ),
              Text(
                'PROPERTIES',
                style: GoogleFonts.montserrat(
                  color: isDark ? Colors.white : Colors.black,
                  fontSize: 32,
                  fontWeight: FontWeight.w400,
                  letterSpacing: 1,
                ),
              ),
            ],
          ),
        ),
        const SizedBox(height: 40),

        // Main Card
        ClipRRect(
          borderRadius: BorderRadius.circular(40),
          child: BackdropFilter(
            filter: ImageFilter.blur(sigmaX: 10, sigmaY: 10),
            child: Container(
              margin: const EdgeInsets.symmetric(horizontal: 24),
              decoration: BoxDecoration(
                color: isDark ? Colors.white.withValues(alpha: 0.03) : Colors.black.withValues(alpha: 0.02),
                borderRadius: BorderRadius.circular(40),
                border: Border.all(color: (isDark ? Colors.white : Colors.black).withValues(alpha: 0.08)),
              ),
              child: Column(
                children: [
                  ClipRRect(
                    borderRadius: const BorderRadius.vertical(top: Radius.circular(40)),
                    child: Stack(
                      children: [
                        Image.network(
                          apiClient.resolveUrl(project['heroImage'] ?? ''),
                          height: 420, width: double.infinity, fit: BoxFit.cover,
                        ),
                        Positioned(
                          top: 24, right: 24,
                          child: Container(
                            padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
                            decoration: BoxDecoration(color: Colors.black.withValues(alpha: 0.5), borderRadius: BorderRadius.circular(4)),
                            child: Text('ARTISTIC IMPRESSION', style: GoogleFonts.montserrat(color: Colors.white, fontSize: 7, fontWeight: FontWeight.w800)),
                          ),
                        ),
                        Positioned(
                          bottom: 40, left: 32, right: 32,
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Text('FEATURED PROPERTY', style: GoogleFonts.montserrat(color: const Color(0xFFC5A358), fontSize: 10, fontWeight: FontWeight.w900, letterSpacing: 2)),
                              const SizedBox(height: 12),
                              Text(project['title'] ?? '', style: GoogleFonts.dmSerifDisplay(color: Colors.white, fontSize: 40)),
                              const SizedBox(height: 16),
                              Text(
                                (project['startingPrice'] ?? project['description'] ?? '').toUpperCase(),
                                maxLines: 2, overflow: TextOverflow.ellipsis,
                                style: GoogleFonts.montserrat(color: Colors.white70, fontSize: 10, height: 1.6, fontWeight: FontWeight.w900, letterSpacing: 1.5),
                              ),
                            ],
                          ),
                        ),
                      ],
                    ),
                  ),
                  Padding(
                    padding: const EdgeInsets.fromLTRB(24, 40, 24, 40),
                    child: Column(
                      children: [
                        Row(
                          mainAxisAlignment: MainAxisAlignment.spaceBetween,
                          children: [
                            _buildFeatureIcon(LucideIcons.building2, 'FULLY FURNISHED'),
                            _buildFeatureIcon(LucideIcons.mapPin, 'PRIME LOCATION'),
                            _buildFeatureIcon(LucideIcons.smartphone, 'SMART HOMES'),
                          ],
                        ),
                        const SizedBox(height: 40),
                        Row(
                          children: [
                            _ScaleButton(
                              onTap: () => setState(() => _featuredIndex = (_featuredIndex - 1 + _projects.length) % _projects.length),
                              child: Container(
                                padding: const EdgeInsets.all(16),
                                decoration: BoxDecoration(color: (isDark ? Colors.white : Colors.black).withValues(alpha: 0.1), shape: BoxShape.circle),
                                child: Icon(LucideIcons.arrowLeft, color: isDark ? Colors.white : Colors.black, size: 20),
                              ),
                            ),
                            const SizedBox(width: 16),
                            Expanded(
                              child: _ScaleButton(
                                onTap: () => context.push('/projects/${project['_id']}', extra: project),
                                child: Container(
                                  height: 56,
                                  decoration: BoxDecoration(color: isDark ? Colors.white : Colors.black, borderRadius: BorderRadius.circular(16)),
                                  child: Center(
                                    child: Text('READ MORE', style: GoogleFonts.montserrat(color: isDark ? Colors.black : Colors.white, fontWeight: FontWeight.w900, fontSize: 13, letterSpacing: 2)),
                                  ),
                                ),
                              ),
                            ),
                            const SizedBox(width: 16),
                            _ScaleButton(
                              onTap: () => setState(() => _featuredIndex = (_featuredIndex + 1) % _projects.length),
                              child: Container(
                                padding: const EdgeInsets.all(16),
                                decoration: BoxDecoration(color: (isDark ? Colors.white : Colors.black).withValues(alpha: 0.1), shape: BoxShape.circle),
                                child: Icon(LucideIcons.arrowRight, color: isDark ? Colors.white : Colors.black, size: 20),
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
        ),
      ],
    );
  }

  Widget _buildFeatureIcon(IconData icon, String label) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    return Column(
      children: [
        Icon(icon, color: isDark ? Colors.white38 : Colors.black38, size: 24),
        const SizedBox(height: 8),
        Text(label, textAlign: TextAlign.center, style: GoogleFonts.montserrat(color: isDark ? Colors.white38 : Colors.black38, fontSize: 9, fontWeight: FontWeight.w800, letterSpacing: 1.5)),
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
        Text(
          'EXPLORE, CONNECT', 
          style: GoogleFonts.dmSerifDisplay(color: isDark ? Colors.white : Colors.black, fontSize: 34, height: 1),
        ),
        Text(
          'AND ENGAGE WITH US', 
          style: GoogleFonts.dmSerifDisplay(color: isDark ? Colors.white : Colors.black, fontSize: 34, height: 1.2),
        ),
        const SizedBox(height: 48),
        GridView.count(
          shrinkWrap: true,
          physics: const NeverScrollableScrollPhysics(),
          crossAxisCount: 2,
          mainAxisSpacing: 1,
          crossAxisSpacing: 1,
          childAspectRatio: 0.9,
          children: List.generate(4, (i) {
            final items = [
              {'title': 'EXPLORE PROJECTS', 'desc': 'Browse our portfolio of properties', 'icon': LucideIcons.building2, 'route': '/projects'},
              {'title': 'BOOK A VIEWING', 'desc': 'Schedule a visit to our show apartment', 'icon': LucideIcons.calendarDays, 'action': _scrollToInterestForm},
              {'title': 'SALES VIDEO CALL', 'desc': 'Talk to one of our sales expert', 'icon': LucideIcons.play, 'link': 'https://wa.me/912246018844'},
              {'title': 'REGISTER INTEREST', 'desc': 'Register your interest in our properties', 'icon': LucideIcons.user, 'action': _scrollToInterestForm},
            ];
            final item = items[i];
            return ClipRRect(
              child: BackdropFilter(
                filter: ImageFilter.blur(sigmaX: 5, sigmaY: 5),
                child: Container(
                  color: isDark ? Colors.white.withValues(alpha: 0.02) : Colors.black.withValues(alpha: 0.03),
                  child: InkWell(
                onTap: () {
                  if (item['action'] != null) {
                    (item['action'] as Function)();
                  } else if (item['link'] != null) {
                    launchUrl(Uri.parse(item['link'] as String), mode: LaunchMode.externalApplication);
                  } else if (item['route'] == '/projects') {
                    Navigator.push(context, MaterialPageRoute(builder: (context) => const ProjectListScreen()));
                  }
                },
                child: Padding(
                  padding: const EdgeInsets.all(24),
                  child: Column(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      Icon(item['icon'] as IconData, color: isDark ? Colors.white : Colors.black, size: 28),
                      const SizedBox(height: 20),
                      Text(item['title'] as String, textAlign: TextAlign.center, style: GoogleFonts.montserrat(color: isDark ? Colors.white : Colors.black, fontWeight: FontWeight.w900, fontSize: 9, letterSpacing: 1)),
                      const SizedBox(height: 8),
                      Text(item['desc'] as String, textAlign: TextAlign.center, style: GoogleFonts.montserrat(color: isDark ? Colors.white54 : Colors.black54, fontSize: 8)),
                    ],
                  ),
                ),
              ),
            ),
          ),
        );
      }),
    ),
  ],
);
}

  Widget _buildInterestForm() {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    return Column(
      key: _interestFormKey,
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          'REGISTER INTEREST', 
          style: GoogleFonts.montserrat(
            color: isDark ? Colors.white : Colors.black, 
            fontSize: 28, 
            fontWeight: FontWeight.w400, 
            letterSpacing: 2
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
                    : Text('SUBMIT INTEREST', style: GoogleFonts.montserrat(color: isDark ? Colors.black : Colors.white, fontWeight: FontWeight.w900, letterSpacing: 2)),
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
        border: Border.all(color: (isDark ? Colors.white : Colors.black).withOpacity(0.05)),
        boxShadow: isDark ? [] : [
          BoxShadow(color: Colors.black.withOpacity(0.03), blurRadius: 20, offset: const Offset(0, 10))
        ]
      ),
      child: TextField(
        controller: controller,
        style: TextStyle(color: isDark ? Colors.white : Colors.black),
        maxLines: isLong ? 5 : 1,
        decoration: InputDecoration(
          hintText: hint,
          hintStyle: GoogleFonts.montserrat(color: isDark ? Colors.white24 : Colors.black26, fontSize: 13),
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
