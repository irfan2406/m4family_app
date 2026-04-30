import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:cached_network_image/cached_network_image.dart';
import 'package:m4_mobile/core/theme/app_theme.dart';
import 'package:flutter_animate/flutter_animate.dart';
import 'package:lucide_icons/lucide_icons.dart';
import 'package:google_fonts/google_fonts.dart';
import 'dart:ui';
import 'package:m4_mobile/presentation/widgets/conditional_drawer.dart';
import 'package:m4_mobile/presentation/widgets/main_shell.dart';
import 'package:m4_mobile/core/utils/support_handlers.dart';
import 'package:m4_mobile/core/network/api_client.dart';
import 'package:m4_mobile/presentation/providers/auth_provider.dart';
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
    _heroTimer = Timer.periodic(const Duration(seconds: 5), (timer) {
      if (_projects.isNotEmpty) {
        setState(() {
          _currentHeroIndex = (_currentHeroIndex + 1) % 5;
        });
      }
    });

    _scrollTimer = Timer.periodic(const Duration(seconds: 3), (timer) {
      if (_recommendedScrollController.hasClients) {
        double maxScroll = _recommendedScrollController.position.maxScrollExtent;
        double currentScroll = _recommendedScrollController.offset;
        double nextScroll = currentScroll + 260; // card width + margin

        if (nextScroll >= maxScroll) {
          _recommendedScrollController.animateTo(0, duration: 800.ms, curve: Curves.easeInOut);
        } else {
          _recommendedScrollController.animateTo(nextScroll, duration: 800.ms, curve: Curves.easeInOut);
        }
      }
    });
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
    try {
      final apiClient = ref.read(apiClientProvider);
      final response = await apiClient.getProjects();
      if (response.data['status'] == true && response.data['data'] is List) {
        setState(() {
          _projects = response.data['data'];
          _projectsLoading = false;
        });
      } else {
        setState(() => _projectsLoading = false);
        final msg = response.data['message'] ?? 'Unknown error';
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('API Error: $msg'), backgroundColor: Colors.orangeAccent),
        );
      }
    } catch (e) {
      if (mounted) {
        setState(() => _projectsLoading = false);
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Failed to load projects: $e'), backgroundColor: Colors.redAccent),
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

  Future<void> _submitInquiry() async {
    final apiClient = ref.read(apiClientProvider);
    if (_nameController.text.isEmpty || _emailController.text.isEmpty || _phoneController.text.isEmpty || _selectedProject == null) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Please fill all required fields (*)'), backgroundColor: Colors.redAccent),
      );
      return;
    }

    setState(() => _isSubmitting = true);
    
    try {
      final response = await apiClient.submitLead({
        'name': _nameController.text,
        'email': _emailController.text,
        'phone': _phoneController.text,
        'message': _messageController.text,
        'interest': 'Property Inquiry',
        'projectName': _selectedProject,
        'source': 'Mobile Dashboard Inquiry',
      });

      if (response.data['status'] == true) {
        _nameController.clear();
        _emailController.clear();
        _phoneController.clear();
        _messageController.clear();
        setState(() => _selectedProject = null);
        
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Inquiry submitted successfully!'), backgroundColor: Colors.green),
        );
      }
    } catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Submission failed: $e'), backgroundColor: Colors.redAccent),
      );
    } finally {
      setState(() => _isSubmitting = false);
    }
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

    return Scaffold(
      key: _scaffoldKey,
      backgroundColor: Theme.of(context).scaffoldBackgroundColor,
      drawer: const ConditionalDrawer(),
      body: CustomScrollView(
        controller: _scrollController,
        slivers: <Widget>[
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
                      'assets/m4_logo.png',
                      height: 100,
                      fit: BoxFit.contain,
                    ),
                  ),
                  GestureDetector(
                    onTap: () => _scaffoldKey.currentState?.openDrawer(),
                    child: Container(
                      width: 56,
                      height: 36,
                      decoration: BoxDecoration(
                        // Toggle button background: White in Dark Mode, Black in Light Mode
                        color: Theme.of(context).brightness == Brightness.dark 
                            ? Colors.white 
                            : Colors.black,
                        borderRadius: BorderRadius.circular(14),
                      ),
                      child: Icon(
                        LucideIcons.moreHorizontal, 
                        // Toggle icon color: Black in Dark Mode, White in Light Mode
                        color: Theme.of(context).brightness == Brightness.dark 
                            ? Colors.black 
                            : Colors.white, 
                        size: 24
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
              padding: const EdgeInsets.fromLTRB(0, 0, 0, 0), // 👈 Zero bottom padding
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.center,
                children: [
                  // ⭐️ Tagline (Living the M4 Life)
                  Transform.translate(
                    offset: const Offset(0, -20), // 👈 Reduced from -60 to avoid overlap
                    child: Padding(
                      padding: const EdgeInsets.symmetric(vertical: 0),
                      child: ColorFiltered(
                        colorFilter: ColorFilter.matrix(
                          Theme.of(context).brightness == Brightness.dark
                              ? const [
                                  // Dark Mode: Invert and boost to white
                                  -5.0, 0, 0, 0, 255,
                                  0, -5.0, 0, 0, 255,
                                  0, 0, -5.0, 0, 255,
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
                          height: 140, // 👈 Reduced from 300
                          fit: BoxFit.fitWidth, // 👈 Force to edges
                        ),
                      ),
                    ),
                  ),

                  // Hero Image Container (Pulled UP)
                  Transform.translate(
                    offset: const Offset(0, -40), // 👈 Pull even higher due to taller tagline box
                    child: Padding(
                      padding: const EdgeInsets.symmetric(horizontal: 24),
                      child: Builder(
                    builder: (context) {
                      final featured = (_projects.isNotEmpty)
                          ? _projects.firstWhere((p) => p['featured'] == true, orElse: () => _projects.isNotEmpty ? _projects[0] : null)
                          : null;
                      
                      final mainImage = (featured != null)
                          ? (featured['heroImage'] != null
                              ? featured['heroImage'].toString()
                              : (featured['images'] is List && (featured['images'] as List).isNotEmpty
                                  ? featured['images'][0].toString()
                                  : 'https://images.unsplash.com/photo-1545324418-cc1a3fa10c00?auto=format&fit=crop&q=80'))
                          : 'https://images.unsplash.com/photo-1545324418-cc1a3fa10c00?auto=format&fit=crop&q=80';

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
                                child: CachedNetworkImage(
                                  imageUrl: apiClient.resolveUrl(mainImage),
                                  fit: BoxFit.cover,
                                  placeholder: (context, url) => Container(color: Colors.black12),
                                  errorWidget: (context, url, error) => Container(
                                    color: Colors.white10,
                                    child: const Center(child: Icon(LucideIcons.image, color: Colors.white24, size: 50)),
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

                          // Carousel Indicators
                          Positioned(
                            bottom: 24,
                            left: 0,
                            right: 0,
                            child: Row(
                              mainAxisAlignment: MainAxisAlignment.center,
                              children: List.generate(3, (index) => Container(
                                margin: const EdgeInsets.symmetric(horizontal: 3),
                                width: index == 0 ? 20 : 12,
                                height: 2,
                                decoration: BoxDecoration(
                                  color: index == 0 ? Colors.white : Colors.white.withOpacity(0.5),
                                  borderRadius: BorderRadius.circular(1),
                                ),
                              )),
                            ),
                          ),
                        ],
                      );
                    },
                  ),
                ),
              ), // 👈 Closing Transform.translate for Hero
                ],
              ),
            ),
          ),

          // ⭐️ DISCOVERY SECTION TABS (Web Parity)
          SliverToBoxAdapter(
            child: Padding(
              padding: const EdgeInsets.symmetric(horizontal: 24),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Container(
                    decoration: BoxDecoration(
                      border: Border(bottom: BorderSide(color: Theme.of(context).colorScheme.onSurface.withOpacity(0.1))),
                    ),
                    child: Row(
                      children: [
                        _WebTab(
                          label: 'COMMUNITIES',
                          isActive: _topTabCategory == 'COMMUNITIES',
                          onTap: () => setState(() => _topTabCategory = 'COMMUNITIES'),
                        ),
                        const SizedBox(width: 32),
                        _WebTab(
                          label: 'PROPERTIES',
                          isActive: _topTabCategory == 'PROPERTIES',
                          onTap: () => setState(() => _topTabCategory = 'PROPERTIES'),
                        ),
                        const SizedBox(width: 32),
                        _WebTab(
                          label: 'MEDIA',
                          isActive: _topTabCategory == 'MEDIA',
                          onTap: () => setState(() => _topTabCategory = 'MEDIA'),
                        ),
                      ],
                    ),
                  ),
                  const SizedBox(height: 32),
                  Text(
                    _topTabCategory == 'COMMUNITIES' ? 'M4 COMMUNITIES' : 'M4 PROJECTS',
                    style: GoogleFonts.montserrat(
                      fontSize: 28,
                      fontWeight: FontWeight.w900,
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
              child: (_topTabCategory == 'COMMUNITIES' ? _communitiesLoading : _projectsLoading)
                ? const Center(child: CircularProgressIndicator(color: Colors.white10))
                : Builder(
                    builder: (context) {
                      final items = _topTabCategory == 'COMMUNITIES' 
                          ? _communities 
                          : _projects.where((p) {
                              if (_selectedCategory == 'ALL') return true;
                              return p['status']?.toString().toUpperCase() == _selectedCategory;
                            }).toList();

                      if (items.isEmpty) {
                        return Center(child: Text('NO ITEMS FOUND', style: GoogleFonts.montserrat(color: Colors.white10, fontSize: 10, fontWeight: FontWeight.w900)));
                      }

                      return ListView.builder(
                        scrollDirection: Axis.horizontal,
                        physics: const BouncingScrollPhysics(),
                        padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 20),
                        itemCount: items.length > 8 ? 8 : items.length,
                        itemBuilder: (context, index) {
                          final item = items[index];
                          if (_topTabCategory == 'COMMUNITIES') {
                            return _CommunityCard(
                              title: item['title'] ?? 'UNTITLED',
                              description: item['overview'] ?? item['description'] ?? 'Explore this master-planned community',
                              imageUrl: apiClient.resolveUrl(item['image'] ?? (item['heroImages'] is List ? item['heroImages'][0] : null)),
                              onTap: () {
                                Navigator.push(
                                  context,
                                  MaterialPageRoute(
                                    builder: (context) => CommunityDetailScreen(community: item),
                                  ),
                                );
                              },
                            );
                          } else {
                            final locData = item['location'];
                            final locationName = (locData is Map) ? locData['name']?.toString() ?? '' : '';
                            final imageUrl = item['heroImage'] != null
                                ? item['heroImage'].toString()
                                : (item['images'] is List && (item['images'] as List).isNotEmpty
                                    ? item['images'][0].toString()
                                    : '');

                            return _ProjectCard(
                              title: item['title']?.toString() ?? 'Untitled',
                              location: locationName,
                              status: item['status']?.toString() ?? '',
                              imageUrl: apiClient.resolveUrl(imageUrl),
                              startingPrice: item['startingPrice']?.toString() ?? '',
                              onTap: () {
                                Navigator.push(
                                  context,
                                  MaterialPageRoute(
                                    builder: (context) => ProjectDetailScreen(
                                      projectId: item['_id']?.toString() ?? '',
                                      projectData: item,
                                    ),
                                  ),
                                );
                              },
                            );
                          }
                        },
                      );
                    }
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
                    style: GoogleFonts.montserrat(
                      fontSize: 28, 
                      fontWeight: FontWeight.w900, 
                      color: Theme.of(context).colorScheme.onSurface,
                      letterSpacing: -0.5,
                    ),
                  ),
                  const SizedBox(height: 20),
                  Text(
                    'To redefine modern luxury living by crafting homes with cutting edge design, enduring quality and thoughtful amenities delivered with trust, transparency, timeliness, and a human touch that creates lasting value for every homeowner.',
                    textAlign: TextAlign.justify,
                    style: GoogleFonts.montserrat(
                      color: Theme.of(context).colorScheme.onSurface.withOpacity(0.6), 
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
                style: GoogleFonts.montserrat(
                  fontSize: 18,
                  fontWeight: FontWeight.w400,
                  color: Theme.of(context).colorScheme.onSurface,
                  letterSpacing: 2,
                ),
              ),
            ),
          ),
          SliverToBoxAdapter(
            child: Padding(
              padding: const EdgeInsets.symmetric(horizontal: 25),
              child: SizedBox(
                height: 420,
                child: _projectsLoading
                    ? const Center(child: CircularProgressIndicator(color: Colors.white24))
                    : _projects.isEmpty
                        ? const Center(child: Text('No featured properties', style: TextStyle(color: Colors.white24)))
                        : PageView.builder(
                        controller: _featuredController,
                        itemCount: _projects.length > 5 ? 5 : _projects.length,
                        onPageChanged: (index) => setState(() => _currentHeroIndex = index),
                        itemBuilder: (context, index) {
                          final project = _projects[index];
                          final imageUrl = project['heroImage'] != null
                              ? project['heroImage'].toString()
                              : (project['images'] is List && (project['images'] as List).isNotEmpty
                                  ? project['images'][0].toString()
                                  : '');

                          return Padding(
                            padding: const EdgeInsets.symmetric(horizontal: 10),
                            child: Stack(
                              children: <Widget>[
                                ClipRRect(
                                  borderRadius: BorderRadius.circular(40),
                                  child: imageUrl.isNotEmpty
                                      ? CachedNetworkImage(
                                          imageUrl: apiClient.resolveUrl(imageUrl), 
                                          fit: BoxFit.cover,
                                          height: 420,
                                          width: double.infinity,
                                          placeholder: (context, url) => Container(height: 420, color: Colors.black12),
                                          errorWidget: (context, url, error) => Container(
                                            height: 420,
                                            width: double.infinity,
                                            color: Colors.white.withOpacity(0.05),
                                            child: const Center(child: Icon(LucideIcons.image, color: Colors.white10)),
                                          ),
                                        )
                                    : Container(
                                        color: Colors.white10,
                                        child: const Center(child: Icon(LucideIcons.image, color: Colors.white24)),
                                      ),
                              ),
                              Container(
                                height: 420,
                                decoration: BoxDecoration(
                                  borderRadius: BorderRadius.circular(40),
                                  gradient: LinearGradient(
                                    begin: Alignment.topCenter,
                                    end: Alignment.bottomCenter,
                                    colors: [Colors.transparent, Colors.black.withOpacity(0.4)],
                                    stops: const [0.6, 1.0],
                                  ),
                                ),
                              ),
                              Positioned(
                                top: 25,
                                right: 25,
                                child: Container(
                                  padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 8),
                                  decoration: BoxDecoration(
                                    color: Colors.white.withOpacity(0.1),
                                    borderRadius: BorderRadius.circular(10),
                                    border: Border.all(color: Colors.white.withOpacity(0.1)),
                                  ),
                                  child: Text(
                                    'ARTISTIC IMPRESSION',
                                    style: GoogleFonts.montserrat(
                                      color: Colors.white,
                                      fontSize: 8,
                                      fontWeight: FontWeight.w900,
                                      letterSpacing: 1.5,
                                    ),
                                  ),
                                ),
                              ),
                            ],
                          ),
                        );
                      },
                      ),
              ),
            ),
          ),
          SliverToBoxAdapter(
            child: Padding(
              padding: const EdgeInsets.symmetric(vertical: 40),
              child: Column(
                children: <Widget>[
                  Text(
                    'FEATURED SELECTION',
                    style: GoogleFonts.montserrat(
                      fontSize: 8, // Refined small scale
                      fontWeight: FontWeight.w900,
                      color: Theme.of(context).colorScheme.onSurface.withOpacity(0.3),
                      letterSpacing: 2.5,
                    ),
                  ),
                  const SizedBox(height: 12),
                  Text(
                    _projectsLoading || _projects.isEmpty 
                        ? 'LOADING...' 
                        : (_projects[_currentHeroIndex % _projects.length]['title']?.toString().toUpperCase() ?? 'UNTITLED'),
                    style: GoogleFonts.montserrat(
                      fontSize: 26, // Matched with Stage 1 Hero
                      fontWeight: FontWeight.w900,
                      color: Theme.of(context).colorScheme.onSurface,
                      letterSpacing: -1.2,
                    ),
                    textAlign: TextAlign.center,
                  ),
                  const SizedBox(height: 35),
                  Row(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: <Widget>[
                      _SliderNavButton(
                        icon: LucideIcons.arrowLeft, 
                        onTap: () {
                          if (_featuredController.hasClients) {
                             if (_currentHeroIndex > 0) {
                                _featuredController.previousPage(duration: 500.ms, curve: Curves.easeInOut);
                             } else {
                                _featuredController.animateToPage(_projects.length - 1, duration: 800.ms, curve: Curves.easeInOut);
                             }
                          }
                        },
                      ),
                      const SizedBox(width: 25),
                      GestureDetector(
                        onTap: () {
                          if (_projects.isNotEmpty) {
                            final currentIndex = _currentHeroIndex % _projects.length;
                            final currentProject = _projects[currentIndex];
                            final projectId = currentProject['_id']?.toString() ?? '';
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
                          padding: const EdgeInsets.symmetric(horizontal: 45, vertical: 15),
                          decoration: BoxDecoration(
                            color: Theme.of(context).brightness == Brightness.dark ? Colors.white : Colors.black,
                            borderRadius: BorderRadius.circular(35),
                          ),
                          child: Text(
                            'EXPLORE NOW',
                            style: GoogleFonts.montserrat(
                              color: Theme.of(context).brightness == Brightness.dark ? Colors.black : Colors.white,
                              fontWeight: FontWeight.w900,
                              fontSize: 11,
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
                             if (_currentHeroIndex < (_projects.length - 1)) {
                                _featuredController.nextPage(duration: 500.ms, curve: Curves.easeInOut);
                             } else {
                                _featuredController.animateToPage(0, duration: 800.ms, curve: Curves.easeInOut);
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

          // 7. 🔲 Stage 7: Quick Action Grid (2x2)
          SliverToBoxAdapter(
            child: Padding(
              padding: const EdgeInsets.fromLTRB(25, 0, 25, 60),
              child: Column(
                children: <Widget>[
                  Row(
                    children: <Widget>[
                      Expanded(
                        child: _LargeActionCard(
                          icon: LucideIcons.layoutGrid, 
                          title: 'EXPLORE', 
                          subtitle: 'VIEW ALL PROJECTS',
                          onTap: () => ref.read(navigationProvider.notifier).state = 1,
                        ),
                      ),
                      const SizedBox(width: 15),
                      Expanded(
                        child: _LargeActionCard(
                          icon: LucideIcons.mapPin, 
                          title: 'VISIT', 
                          subtitle: 'BOOK A SITE TOUR',
                          onTap: _scrollToInquiry,
                        ),
                      ),

                    ],
                  ),
                  const SizedBox(height: 15),
                  Row(
                    children: <Widget>[
                      Expanded(
                        child: _LargeActionCard(
                          icon: LucideIcons.playCircle, 
                          title: 'VIDEO', 
                          subtitle: 'WATCH WALKTHROUGHS',
                          onTap: () {},
                        ),
                      ),
                      const SizedBox(width: 15),
                      Expanded(
                        child: _LargeActionCard(
                          icon: LucideIcons.userPlus, 
                          title: 'REGISTER', 
                          subtitle: 'PRIORITY ACCESS',
                          onTap: _scrollToInquiry,
                        ),
                      ),
                    ],
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
                color: Theme.of(context).colorScheme.onSurface.withOpacity(0.02),
                borderRadius: const BorderRadius.only(topLeft: Radius.circular(50), topRight: Radius.circular(50)),
                border: Border.all(color: Theme.of(context).colorScheme.onSurface.withOpacity(0.04)),
              ),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: <Widget>[
                  Text(
                    'REGISTER YOUR\nINTEREST',
                    style: GoogleFonts.montserrat(fontSize: 32, fontWeight: FontWeight.w300, color: Theme.of(context).colorScheme.onSurface, height: 1.1),
                  ),
                  const SizedBox(height: 8),
                  Text('OFFICIAL INQUIRY FORM', style: TextStyle(color: Theme.of(context).colorScheme.onSurface.withOpacity(0.5), fontSize: 10, fontWeight: FontWeight.bold, letterSpacing: 2)),
                  const SizedBox(height: 48),
                  _PremiumInputField(label: 'Full Name *', controller: _nameController),
                  _PremiumInputField(label: 'Email Address *', controller: _emailController, keyboardType: TextInputType.emailAddress),
                  _PremiumInputField(label: 'Phone Number *', controller: _phoneController, keyboardType: TextInputType.phone),
                  _PremiumDropdownField(
                    label: 'Select Project *', 
                    value: _selectedProject,
                    options: _projects.map((p) => p['title'].toString()).toList(),
                    onChanged: (val) => setState(() => _selectedProject = val),
                  ),
                  _PremiumInputField(label: 'Message', controller: _messageController, maxLines: 3),
                  const SizedBox(height: 32),
                  SizedBox(
                    width: double.infinity,
                    child: ElevatedButton(
                      onPressed: _isSubmitting ? null : _submitInquiry,
                      style: ElevatedButton.styleFrom(
                        backgroundColor: Theme.of(context).colorScheme.onSurface,
                        foregroundColor: Theme.of(context).colorScheme.surface,
                        padding: const EdgeInsets.symmetric(vertical: 22),
                        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(15)),
                      ),
                      child: _isSubmitting 
                        ? SizedBox(height: 15, width: 15, child: CircularProgressIndicator(strokeWidth: 2, color: Theme.of(context).colorScheme.surface))
                        : Text('SUBMIT INTEREST', style: GoogleFonts.montserrat(fontWeight: FontWeight.bold, letterSpacing: 3, fontSize: 12)),
                    ),
                  ),
                ],
              ),
            ),
          ),
          
          SliverToBoxAdapter(child: SizedBox(height: 120)),
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
              ? (isDark ? Colors.white : Colors.black) 
              : (isDark ? Colors.white.withOpacity(0.05) : Colors.black.withOpacity(0.05)),
          borderRadius: BorderRadius.circular(30),
          border: Border.all(color: (isDark ? Colors.white : Colors.black).withOpacity(0.1)),
        ),
        child: Text(
          label,
          style: GoogleFonts.montserrat(
            color: isActive 
                ? (isDark ? Colors.black : Colors.white) 
                : (isDark ? Colors.white38 : Colors.black38),
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
  final String startingPrice;
  final VoidCallback onTap;
  const _ProjectCard({
    required this.title,
    required this.location,
    required this.status,
    required this.imageUrl,
    required this.startingPrice,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    final hasImage = imageUrl.isNotEmpty;
    final displayPrice = (startingPrice.isNotEmpty && !startingPrice.contains('YOY')) 
        ? '₹ $startingPrice' 
        : '';
    final displayLocation = location.isNotEmpty ? location.toUpperCase() : 'MUMBAI';
    final displayStatus = status.isNotEmpty ? status.toUpperCase() : 'UPCOMING';

    return GestureDetector(
      onTap: onTap,
      child: Container(
        width: 280,
        margin: const EdgeInsets.only(right: 20),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Expanded(
              child: Stack(
                children: <Widget>[
                  ClipRRect(
                    borderRadius: BorderRadius.circular(20),
                    child: hasImage
                        ? CachedNetworkImage(
                            imageUrl: imageUrl,
                            width: double.infinity,
                            fit: BoxFit.cover,
                            placeholder: (context, url) => Container(color: Colors.black12),
                            errorWidget: (_, __, ___) => Container(
                              color: Colors.white.withOpacity(0.05),
                              child: const Center(child: Icon(LucideIcons.building, color: Colors.white24, size: 40)),
                            ),
                          )
                        : Container(
                            color: Colors.white.withOpacity(0.05),
                            child: const Center(child: Icon(LucideIcons.building, color: Colors.white24, size: 40)),
                          ),
                  ),
                  Positioned(
                    top: 15,
                    left: 15,
                    child: ClipRRect(
                      borderRadius: BorderRadius.circular(10),
                      child: BackdropFilter(
                        filter: ImageFilter.blur(sigmaX: 10, sigmaY: 10),
                        child: Container(
                          padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 5),
                          decoration: BoxDecoration(
                            color: Colors.white.withOpacity(0.4), 
                            borderRadius: BorderRadius.circular(10),
                            border: Border.all(color: Colors.white.withOpacity(0.4)),
                          ),
                          child: Text(displayStatus, style: const TextStyle(color: Colors.black, fontSize: 8, fontWeight: FontWeight.bold)),
                        ),
                      ),
                    ),
                  ),
                ],
              ),
            ),
            const SizedBox(height: 12),
            Text(
              title.toUpperCase(),
              style: GoogleFonts.montserrat(
                fontSize: 16, 
                fontWeight: FontWeight.bold, 
                color: Theme.of(context).colorScheme.onSurface
              ),
              maxLines: 1,
              overflow: TextOverflow.ellipsis,
            ),
            Row(
              children: [
                Icon(LucideIcons.mapPin, color: Theme.of(context).colorScheme.onSurface.withOpacity(0.5), size: 10),
                const SizedBox(width: 4),
                Expanded(
                  child: Text(displayLocation, 
                    style: GoogleFonts.montserrat(color: Theme.of(context).colorScheme.onSurface.withOpacity(0.5), fontSize: 10),
                    maxLines: 1, overflow: TextOverflow.ellipsis),
                ),
              ],
            ),
            const SizedBox(height: 12),
            ClipRRect(
              borderRadius: BorderRadius.circular(15),
              child: BackdropFilter(
                filter: ImageFilter.blur(sigmaX: 10, sigmaY: 10),
                child: Container(
                  padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 12),
                  decoration: BoxDecoration(
                    color: Colors.white.withOpacity(0.12), 
                    borderRadius: BorderRadius.circular(15),
                    border: Border.all(color: Colors.white.withOpacity(0.15)),
                  ),
                  child: Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: <Widget>[
                      if (displayPrice.isNotEmpty)
                        Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: <Widget>[
                            Text('STARTING FROM', style: GoogleFonts.montserrat(color: Colors.white.withOpacity(0.5), fontSize: 7, fontWeight: FontWeight.w900, letterSpacing: 0.5)),
                            Text(displayPrice, style: GoogleFonts.montserrat(fontSize: 15, fontWeight: FontWeight.w900, color: Colors.white, letterSpacing: -0.5)),
                          ],
                        )
                      else
                        Text('EXPLORE NOW', style: GoogleFonts.montserrat(color: Colors.white.withOpacity(0.8), fontSize: 10, fontWeight: FontWeight.w900, letterSpacing: 1)),
                      const Icon(LucideIcons.arrowRight, color: Colors.white, size: 18),
                    ],
                  ),
                ),
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

  const _QuickAction({required this.icon, required this.label, required this.onTap});

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
                  color: (isDark ? Colors.white : Colors.black).withOpacity(0.05),
                  borderRadius: BorderRadius.circular(20),
                  border: Border.all(color: (isDark ? Colors.white : Colors.black).withOpacity(0.08)),
                ),
                child: Icon(icon, color: Theme.of(context).colorScheme.onSurface, size: 24),
              ),
            ),
          ),
          const SizedBox(height: 10),
          Text(
            label,
            style: GoogleFonts.montserrat(
              fontSize: 8,
              fontWeight: FontWeight.w900,
              color: Theme.of(context).colorScheme.onSurface.withOpacity(0.5),
              letterSpacing: 1,
            ),
          ),
        ],
      ),
    );
  }
}

class _LargeActionCard extends StatelessWidget {
  final IconData icon;
  final String title;
  final String subtitle;
  final VoidCallback? onTap;

  const _LargeActionCard({required this.icon, required this.title, required this.subtitle, this.onTap});

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    return GestureDetector(
      onTap: onTap,
      child: ClipRRect(
        borderRadius: BorderRadius.circular(35),
        child: BackdropFilter(
          filter: ImageFilter.blur(sigmaX: 15, sigmaY: 15),
          child: Container(
            height: 140,
            decoration: BoxDecoration(
              color: (isDark ? Colors.white : Colors.black).withOpacity(0.03), 
              borderRadius: BorderRadius.circular(35),
              border: Border.all(color: (isDark ? Colors.white : Colors.black).withOpacity(0.08)),
            ),
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Container(
                  padding: const EdgeInsets.all(12),
                  decoration: BoxDecoration(
                    shape: BoxShape.circle,
                    color: (isDark ? Colors.white : Colors.black).withOpacity(0.05),
                  ),
                  child: Icon(icon, color: Theme.of(context).colorScheme.onSurface, size: 24),
                ),
                const SizedBox(height: 12),
                Text(
                  title, 
                  style: GoogleFonts.montserrat(
                    fontSize: 13, 
                    fontWeight: FontWeight.w900, 
                    color: Theme.of(context).colorScheme.onSurface, 
                    letterSpacing: 1.5,
                  ),
                ),
                const SizedBox(height: 4),
                Text(
                  subtitle, 
                  style: GoogleFonts.montserrat(
                    fontSize: 8, 
                    color: Theme.of(context).colorScheme.onSurface.withOpacity(0.4), 
                    fontWeight: FontWeight.w900,
                    letterSpacing: 0.5,
                  ),
                ),
              ],
            ),
          ),
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
        color: isDark ? const Color(0xFF070708) : Colors.white,
        borderRadius: const BorderRadius.only(topLeft: Radius.circular(35), topRight: Radius.circular(35)),
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
              decoration: BoxDecoration(color: Theme.of(context).colorScheme.onSurface.withOpacity(0.2), borderRadius: BorderRadius.circular(2)),
            ),
          ),
          const SizedBox(height: 25),
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Text(
                'QUICK FILTERS',
                style: GoogleFonts.montserrat(
                  fontSize: 18, 
                  fontWeight: FontWeight.w900, 
                  color: Theme.of(context).colorScheme.onSurface,
                  letterSpacing: 1,
                ),
              ),
              GestureDetector(
                onTap: () => Navigator.pop(context),
                child: Container(
                  padding: const EdgeInsets.all(8),
                  decoration: BoxDecoration(shape: BoxShape.circle, color: (isDark ? Colors.white : Colors.black).withOpacity(0.1)),
                  child: Icon(LucideIcons.x, color: Theme.of(context).colorScheme.onSurface, size: 18),
                ),
              ),
            ],
          ),
          const SizedBox(height: 35),
          _FilterSection(title: 'LOCATION', options: const ['SOUTH MUMBAI', 'WORLI', 'BANDRA', 'JUHU', 'POWAI']),
          const SizedBox(height: 30),
          _FilterSection(title: 'PROPERTY TYPE', options: const ['RESIDENTIAL', 'COMMERCIAL']),
          const SizedBox(height: 50),
          GestureDetector(
            onTap: () => Navigator.pop(context),
            child: Container(
              width: double.infinity,
              padding: const EdgeInsets.symmetric(vertical: 20),
              decoration: BoxDecoration(
                color: isDark ? Colors.white : Colors.black,
                borderRadius: BorderRadius.circular(35),
              ),
              child: Center(
                child: Text(
                  'SHOW RESULTS',
                  style: GoogleFonts.montserrat(
                    color: isDark ? Colors.black : Colors.white,
                    fontWeight: FontWeight.w900,
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
          style: GoogleFonts.montserrat(
            fontSize: 10,
            fontWeight: FontWeight.w900,
            color: Theme.of(context).colorScheme.onSurface.withOpacity(0.5),
            letterSpacing: 1.5,
          ),
        ),
        const SizedBox(height: 15),
        Wrap(
          spacing: 10,
          runSpacing: 12,
          children: options.map((opt) => Container(
            padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 12),
            decoration: BoxDecoration(
              color: (isDark ? Colors.white : Colors.black).withOpacity(0.05),
              borderRadius: BorderRadius.circular(20),
              border: Border.all(color: (isDark ? Colors.white : Colors.black).withOpacity(0.05)),
            ),
            child: Text(
              opt,
              style: GoogleFonts.montserrat(
                color: Theme.of(context).colorScheme.onSurface,
                fontSize: 9,
                fontWeight: FontWeight.w900,
                letterSpacing: 1,
              ),
            ),
          )).toList(),
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
    return GestureDetector(
      onTap: onTap,
      behavior: HitTestBehavior.opaque, // Ensure tap is caught
      child: ClipRRect(
        borderRadius: BorderRadius.circular(40),
        child: BackdropFilter(
          filter: ImageFilter.blur(sigmaX: 10, sigmaY: 10),
          child: Container(
            padding: const EdgeInsets.all(14),
            decoration: BoxDecoration(
              shape: BoxShape.circle,
              color: Colors.white.withOpacity(0.4),
              border: Border.all(color: Colors.white.withOpacity(0.4)),
            ),
            child: Icon(icon, color: Colors.black, size: 18),
          ),
        ),
      ),
    );
  }
}

class _PremiumInputField extends StatelessWidget {
  final String label;
  final TextEditingController controller;
  final TextInputType keyboardType;
  final int maxLines;

  const _PremiumInputField({
    required this.label, 
    required this.controller, 
    this.keyboardType = TextInputType.text,
    this.maxLines = 1,
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
            padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 10),
            decoration: BoxDecoration(
              color: (isDark ? Colors.white : Colors.black).withOpacity(0.03),
              borderRadius: BorderRadius.circular(15),
              border: Border.all(color: (isDark ? Colors.white : Colors.black).withOpacity(0.05)),
            ),
            child: TextFormField(
              controller: controller,
              keyboardType: keyboardType,
              maxLines: maxLines,
              style: GoogleFonts.montserrat(color: Theme.of(context).colorScheme.onSurface, fontSize: 13),
              decoration: InputDecoration(
                labelText: label,
                labelStyle: GoogleFonts.montserrat(color: Theme.of(context).colorScheme.onSurface.withOpacity(0.3), fontSize: 13),
                border: InputBorder.none,
                floatingLabelBehavior: FloatingLabelBehavior.auto,
              ),
            ),
          ),
        ),
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
    required this.onChanged
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
              color: (isDark ? Colors.white : Colors.black).withOpacity(0.03),
              borderRadius: BorderRadius.circular(15),
              border: Border.all(color: (isDark ? Colors.white : Colors.black).withOpacity(0.05)),
            ),
            child: DropdownButtonHideUnderline(
              child: DropdownButtonFormField<String>(
                value: value,
                dropdownColor: isDark ? const Color(0xFF0F0F11) : Colors.white,
                style: GoogleFonts.montserrat(color: Theme.of(context).colorScheme.onSurface, fontSize: 13),
                icon: Icon(LucideIcons.chevronDown, color: Theme.of(context).colorScheme.onSurface.withOpacity(0.3), size: 16),
                decoration: InputDecoration(
                  labelText: label,
                  labelStyle: GoogleFonts.montserrat(color: Theme.of(context).colorScheme.onSurface.withOpacity(0.3), fontSize: 13),
                  border: InputBorder.none,
                  contentPadding: EdgeInsets.zero,
                ),
                items: options.toSet().map((opt) => DropdownMenuItem(
                  value: opt,
                  child: Text(opt),
                )).toList(),
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
              color: (isDark ? Colors.white : Colors.black).withOpacity(0.03),
              borderRadius: BorderRadius.circular(15),
              border: Border.all(color: (isDark ? Colors.white : Colors.black).withOpacity(0.05)),
            ),
            child: Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Text(label, style: GoogleFonts.montserrat(color: Theme.of(context).colorScheme.onSurface.withOpacity(0.3), fontSize: 13, fontWeight: FontWeight.w500)),
                if (hasDropdown) Icon(LucideIcons.chevronDown, color: Theme.of(context).colorScheme.onSurface.withOpacity(0.3), size: 16),
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
                  onChanged: onChanged,
                  style: GoogleFonts.montserrat(color: Colors.black, fontSize: 14),
                  decoration: InputDecoration(
                    hintText: 'Search residences...',
                    hintStyle: GoogleFonts.montserrat(color: Colors.black45, fontSize: 13),
                    border: InputBorder.none,
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
  const _GlassIconButton({required this.icon, required this.onTap, this.size = 60});

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

  const _WebTab({required this.label, this.isActive = false, required this.onTap});

  @override
  Widget build(BuildContext context) {
    final onSurface = Theme.of(context).colorScheme.onSurface;
    return GestureDetector(
      onTap: onTap,
      child: Container(
        padding: const EdgeInsets.only(bottom: 12),
        decoration: BoxDecoration(
          border: isActive 
              ? Border(bottom: BorderSide(color: onSurface, width: 2.5)) 
              : null,
        ),
        child: Text(
          label,
          style: GoogleFonts.montserrat(
            color: isActive ? onSurface : onSurface.withOpacity(0.4),
            fontSize: 12, // 👈 Matched with web text-xs
            fontWeight: FontWeight.w900, // 👈 Matched with web font-black
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
          color: (isDark ? Colors.white : Colors.black).withOpacity(0.04),
          borderRadius: BorderRadius.circular(35),
          border: Border.all(color: (isDark ? Colors.white : Colors.black).withOpacity(0.05)),
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
                placeholder: (context, url) => Container(height: 120, color: Colors.black12),
                errorWidget: (_, __, ___) => Container(color: Colors.white10),
              ),
            ),
            const SizedBox(height: 16),
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Container(
                  padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                  decoration: BoxDecoration(
                    color: Theme.of(context).colorScheme.onSurface.withOpacity(0.05),
                    borderRadius: BorderRadius.circular(8),
                  ),
                  child: Text(type, style: GoogleFonts.montserrat(fontSize: 7, fontWeight: FontWeight.w900, color: Theme.of(context).colorScheme.onSurface.withOpacity(0.5))),
                ),
                Text(date, style: GoogleFonts.montserrat(fontSize: 8, fontWeight: FontWeight.bold, color: Theme.of(context).colorScheme.onSurface.withOpacity(0.3))),
              ],
            ),
            const SizedBox(height: 12),
            Text(
              title,
              style: GoogleFonts.montserrat(fontSize: 12, fontWeight: FontWeight.w900, color: Theme.of(context).colorScheme.onSurface, letterSpacing: -0.5),
              maxLines: 1,
              overflow: TextOverflow.ellipsis,
            ),
            const SizedBox(height: 6),
            Text(
              snippet,
              style: GoogleFonts.montserrat(fontSize: 9, color: Theme.of(context).colorScheme.onSurface.withOpacity(0.5), height: 1.4),
              maxLines: 2,
              overflow: TextOverflow.ellipsis,
            ),
          ],
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
        width: 280,
        margin: const EdgeInsets.only(right: 20),
        decoration: BoxDecoration(
          borderRadius: BorderRadius.circular(35),
          boxShadow: [
            BoxShadow(
              color: Colors.black.withOpacity(0.1),
              blurRadius: 10,
              offset: const Offset(0, 5),
            ),
          ],
        ),
        child: ClipRRect(
          borderRadius: BorderRadius.circular(35),
          child: Stack(
            children: [
              CachedNetworkImage(
                imageUrl: imageUrl,
                height: double.infinity,
                width: double.infinity,
                fit: BoxFit.cover,
                placeholder: (context, url) => Container(color: Colors.black12),
                errorWidget: (_, __, ___) => Container(color: Colors.white10),
              ),
              Container(
                decoration: BoxDecoration(
                  gradient: LinearGradient(
                    begin: Alignment.topCenter,
                    end: Alignment.bottomCenter,
                    colors: [Colors.transparent, Colors.black.withOpacity(0.8)],
                    stops: const [0.5, 1.0],
                  ),
                ),
              ),
              Positioned(
                bottom: 25,
                left: 25,
                right: 25,
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      title.toUpperCase(),
                      style: GoogleFonts.montserrat(
                        color: Colors.white,
                        fontSize: 18,
                        fontWeight: FontWeight.w900,
                        letterSpacing: -0.5,
                      ),
                    ),
                    const SizedBox(height: 6),
                    Text(
                      description,
                      style: GoogleFonts.montserrat(
                        color: Colors.white.withOpacity(0.6),
                        fontSize: 10,
                        fontWeight: FontWeight.w700,
                        letterSpacing: 0.5,
                      ),
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                    ),
                    const SizedBox(height: 20),
                    Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        Text(
                          'EXPLORE COMMUNITY',
                          style: GoogleFonts.montserrat(
                            color: Colors.white.withOpacity(0.8),
                            fontSize: 9,
                            fontWeight: FontWeight.w900,
                            letterSpacing: 1.5,
                          ),
                        ),
                        Container(
                          padding: const EdgeInsets.all(10),
                          decoration: BoxDecoration(
                            color: Colors.white,
                            borderRadius: BorderRadius.circular(15),
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
}
