import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:m4_mobile/core/theme/app_theme.dart';
import 'package:flutter_animate/flutter_animate.dart';
import 'package:lucide_icons/lucide_icons.dart';
import 'package:google_fonts/google_fonts.dart';
import 'dart:ui';
import 'package:m4_mobile/presentation/widgets/sidebar_menu.dart';
import 'package:m4_mobile/presentation/widgets/main_shell.dart';
import 'package:m4_mobile/core/utils/support_handlers.dart';
import 'package:m4_mobile/core/network/api_client.dart';
import 'package:m4_mobile/presentation/providers/auth_provider.dart';
import 'package:m4_mobile/presentation/screens/pages/pages_list_screen.dart';
import 'package:m4_mobile/presentation/screens/projects/project_detail_screen.dart';
import 'package:m4_mobile/presentation/screens/projects/project_list_screen.dart';


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
      backgroundColor: Colors.white,
      drawer: const SidebarMenu(),
      body: CustomScrollView(
        controller: _scrollController,
        slivers: [
          // ⭐️ Stage 1: Fullscreen Hero Stack (Web Parity Overlaid Design)
          SliverToBoxAdapter(
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

                return Container(
                  height: 650,
                  decoration: BoxDecoration(
                    image: DecorationImage(image: NetworkImage(apiClient.resolveUrl(mainImage)), fit: BoxFit.cover),
                  ),
                  child: Stack(
                    children: [
                        // 1. Gradient Overlay
                        Container(
                          decoration: BoxDecoration(
                            gradient: LinearGradient(
                              begin: Alignment.topCenter,
                              end: Alignment.bottomCenter,
                              colors: [
                                Colors.black.withOpacity(0.3),
                                Colors.transparent,
                                Colors.black.withOpacity(0.4),
                              ],
                              stops: const [0.0, 0.4, 1.0],
                            ),
                          ),
                        ),
                        
                        // 2. Global Header & Search (Top) - ALWAYS VISIBLE
                        Positioned(
                          top: 60,
                          left: 25,
                          right: 25,
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Row(
                                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                                children: [
                                  Text(
                                    'DISCOVER',
                                    style: GoogleFonts.montserrat(
                                      fontSize: 10,
                                      fontWeight: FontWeight.w600,
                                      color: Colors.white.withOpacity(0.6),
                                      letterSpacing: 2,
                                    ),
                                  ),
                                  _GlassIconButton(
                                    icon: LucideIcons.menu, 
                                    onTap: () => _scaffoldKey.currentState?.openDrawer(),
                                    size: 45,
                                  ),
                                ],
                              ),
                              Text(
                                'M4 Projects',
                                style: GoogleFonts.montserrat(
                                  fontSize: 42,
                                  fontWeight: FontWeight.w900,
                                  color: Colors.white,
                                  letterSpacing: -1,
                                ),
                              ),
                              const SizedBox(height: 30),
                              Row(
                                children: [
                                  Expanded(
                                    child: _GlassSearchField(
                                      onChanged: (val) => setState(() => _searchQuery = val),
                                    ),
                                  ),
                                  const SizedBox(width: 15),
                                  _GlassIconButton(
                                    icon: LucideIcons.slidersHorizontal,
                                    size: 60,
                                    onTap: () {
                                      showModalBottomSheet(
                                        context: context,
                                        backgroundColor: Colors.transparent,
                                        isScrollControlled: true,
                                        builder: (context) => _QuickFilterSheet(),
                                      );
                                    },
                                  ),
                                ],
                              ),
                              const SizedBox(height: 20),
                              SingleChildScrollView(
                                scrollDirection: Axis.horizontal,
                                child: Row(
                                  children: [
                                    _CategoryChip(
                                      label: 'ALL', 
                                      isActive: _selectedCategory == 'ALL', 
                                      onTap: () => setState(() => _selectedCategory = 'ALL'),
                                    ),
                                    const SizedBox(width: 15),
                                    _CategoryChip(
                                      label: 'ONGOING', 
                                      isActive: _selectedCategory == 'ONGOING', 
                                      onTap: () => setState(() => _selectedCategory = 'ONGOING'),
                                    ),
                                    const SizedBox(width: 15),
                                    _CategoryChip(
                                      label: 'UPCOMING', 
                                      isActive: _selectedCategory == 'UPCOMING', 
                                      onTap: () => setState(() => _selectedCategory = 'UPCOMING'),
                                    ),
                                  ],
                                ),
                              ),
                            ],
                          ),
                        ),
                        
                        // 3. Featured Project Info or Loading/Empty indicator
                        if (_projectsLoading)
                           const Center(child: CircularProgressIndicator(color: Colors.white24))
                        else if (_projects.isEmpty)
                           Center(child: Text('No projects found.', style: GoogleFonts.montserrat(color: Colors.white24, fontSize: 14)))
                        else if (featured != null)
                          Positioned(
                            bottom: 40,
                            left: 30,
                            child: GestureDetector(
                              onTap: () {
                                final projectId = featured['_id']?.toString() ?? '';
                                if (projectId.isNotEmpty) {
                                  Navigator.push(
                                    context,
                                    MaterialPageRoute(
                                      builder: (context) => ProjectDetailScreen(
                                        projectId: projectId,
                                        projectData: featured,
                                      ),
                                    ),
                                  );
                                }
                              },
                              child: Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  Row(
                                    children: [
                                      Container(
                                        padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 5),
                                        decoration: BoxDecoration(color: M4Theme.premiumBlue.withOpacity(0.2), borderRadius: BorderRadius.circular(8)),
                                        child: Text('FEATURED', style: GoogleFonts.montserrat(color: Colors.white, fontSize: 10, fontWeight: FontWeight.bold, letterSpacing: 1.5)),
                                      ),
                                      const SizedBox(width: 10),
                                      Container(width: 6, height: 6, decoration: const BoxDecoration(color: M4Theme.premiumBlue, shape: BoxShape.circle)),
                                    ],
                                  ),
                                  const SizedBox(height: 10),
                                  Text(
                                    featured['title']?.toString().toUpperCase() ?? 'M4 PROJECT',
                                    style: GoogleFonts.montserrat(color: Colors.white, fontSize: 44, fontWeight: FontWeight.w900, letterSpacing: -1.5),
                                  ),
                                  const SizedBox(height: 5),
                                  Row(
                                    children: [
                                      const Icon(LucideIcons.mapPin, color: Colors.white60, size: 14),
                                      const SizedBox(width: 5),
                                      Text(
                                        featured['location']?['name'] ?? 'MUMBAI',
                                        style: GoogleFonts.montserrat(color: Colors.white60, fontSize: 12, fontWeight: FontWeight.w700, letterSpacing: 1),
                                      ),
                                      const SizedBox(width: 20),
                                      Text(
                                        featured['startingPrice'] != null && featured['startingPrice'] != "N/A" 
                                          ? '₹ ${featured['startingPrice']}' 
                                          : 'Price on Request',
                                        style: GoogleFonts.montserrat(color: Colors.white, fontSize: 14, fontWeight: FontWeight.bold),
                                      ),
                                    ],
                                  ),
                                ],
                              ),
                            ),
                          ),
                    ],
                  ),
                );
              },
            ),
          ),

          // ⭐️ Stage 2: Recommended for You (Relocated below Search like web)
          SliverToBoxAdapter(
            child: Padding(
              padding: const EdgeInsets.fromLTRB(30, 10, 30, 10),
              child: Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                   Text(
                    'RECOMMENDED FOR YOU',
                    style: GoogleFonts.montserrat(
                      fontSize: 10, 
                      fontWeight: FontWeight.w900, 
                      color: Theme.of(context).colorScheme.onSurface.withOpacity(0.5), 
                      letterSpacing: 1.5
                    ),
                  ),
                  Text(
                    'VIEW ALL',
                    style: GoogleFonts.montserrat(
                      fontSize: 10, 
                      fontWeight: FontWeight.w900, 
                      color: Theme.of(context).colorScheme.onSurface, 
                      letterSpacing: 1.5
                    ),
                  ),
                ],
              ),
            ),
          ),
          SliverToBoxAdapter(
            child: _projectsLoading
                ? const SizedBox(
                    height: 380,
                    child: Center(child: CircularProgressIndicator(color: Colors.white24)),
                  )
                : SizedBox(
                    height: 380,
                    child: Builder(
                      builder: (context) {
                        final filteredProjects = _projects.where((p) {
                          if (_selectedCategory == 'ALL') return true;
                          final status = p['status']?.toString().toUpperCase();
                          return status == _selectedCategory;
                        }).toList();

                        if (filteredProjects.isEmpty) {
                          return Center(child: Text('No projects found.', style: GoogleFonts.montserrat(color: Colors.white24, fontSize: 12)));
                        }

                        return ListView.builder(
                          scrollDirection: Axis.horizontal,
                          padding: const EdgeInsets.all(20),
                          itemCount: filteredProjects.length > 8 ? 8 : filteredProjects.length,
                          itemBuilder: (context, index) {
                            final project = filteredProjects[index];
                            final locData = project['location'];
                            final locationName = (locData is Map) ? locData['name']?.toString() ?? '' : '';
                            
                            final imageUrl = project['heroImage'] != null
                                ? project['heroImage'].toString()
                                : (project['images'] is List && (project['images'] as List).isNotEmpty
                                    ? project['images'][0].toString()
                                    : '');

                            return _ProjectCard(
                              title: project['title']?.toString() ?? 'Untitled',
                              location: locationName,
                              status: project['status']?.toString() ?? '',
                              imageUrl: apiClient.resolveUrl(imageUrl),
                              startingPrice: project['startingPrice']?.toString() ?? '',
                              onTap: () {
                                final projectId = project['_id']?.toString() ?? '';
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
                            );
                          },
                        );
                      }
                    ),
                  ),
          ),

          // 4. ⚡️ Stage 4: Latest Updates / Quick Nav (Web Parity text tabs)
          SliverToBoxAdapter(
            child: Padding(
              padding: const EdgeInsets.fromLTRB(30, 20, 0, 30),
              child: Row(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  SizedBox(
                    width: 100,
                    child: Text(
                      'LATEST\nUPDATES',
                      style: GoogleFonts.montserrat(
                        fontSize: 11, 
                        fontWeight: FontWeight.w900, 
                        color: Theme.of(context).colorScheme.onSurface, 
                        letterSpacing: 2, 
                        height: 1.5,
                      ),
                    ),
                  ),
                  const SizedBox(width: 15),
                  Expanded(
                    child: SingleChildScrollView(
                      scrollDirection: Axis.horizontal,
                      physics: const BouncingScrollPhysics(),
                      child: Row(
                        children: [
                          _TextTab(
                            label: 'PROPERTIES', 
                            isActive: true, 
                            onTap: () => Navigator.push(context, MaterialPageRoute(builder: (_) => ProjectListScreen())),
                          ),
                          _TextTab(
                            label: 'BLOGS', 
                            isActive: false, 
                            onTap: () => ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('Blogs coming soon!'))),
                          ),
                          _TextTab(
                            label: 'COMMUNITIES', 
                            isActive: false, 
                            onTap: () => ref.read(navigationProvider.notifier).state = 1,
                          ),
                          _TextTab(
                            label: 'MEDIA', 
                            isActive: false, 
                            onTap: () => ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('Media coming soon!'))),
                          ),
                          _TextTab(
                            label: 'ENQUIRY', 
                            isActive: false, 
                            onTap: _scrollToInquiry,
                          ),
                          const SizedBox(width: 30),
                        ],
                      ),
                    ),
                  ),
                ],
              ),
            ),
          ),


          // 5. 📜 Stage 5: Our Philosophy
          SliverToBoxAdapter(
            child: Padding(
              padding: const EdgeInsets.fromLTRB(30, 40, 30, 40),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
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
                              children: [
                                ClipRRect(
                                  borderRadius: BorderRadius.circular(40),
                                  child: imageUrl.isNotEmpty
                                      ? Container(
                                          height: 420,
                                          width: double.infinity,
                                          decoration: BoxDecoration(
                                            image: DecorationImage(
                                              image: NetworkImage(apiClient.resolveUrl(imageUrl)),
                                              fit: BoxFit.cover,
                                            ),
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
                children: [
                  Text(
                    'FEATURED SELECTION',
                    style: GoogleFonts.montserrat(
                      fontSize: 10,
                      fontWeight: FontWeight.w600,
                      color: Theme.of(context).colorScheme.onSurface.withOpacity(0.4),
                      letterSpacing: 2,
                    ),
                  ),
                  const SizedBox(height: 12),
                  Text(
                    _projectsLoading || _projects.isEmpty 
                        ? 'LOADING...' 
                        : (_projects[_currentHeroIndex % _projects.length]['title']?.toString().toUpperCase() ?? 'UNTITLED'),
                    style: GoogleFonts.montserrat(
                      fontSize: 42,
                      fontWeight: FontWeight.w900,
                      color: Theme.of(context).colorScheme.onSurface,
                    ),
                  ),
                  const SizedBox(height: 35),
                  Row(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      _SliderNavButton(
                        icon: LucideIcons.arrowLeft, 
                        onTap: () => _featuredController.previousPage(duration: 500.ms, curve: Curves.easeInOut),
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
                            color: Colors.black,
                            borderRadius: BorderRadius.circular(35),
                          ),
                          child: Text(
                            'EXPLORE NOW',
                            style: GoogleFonts.montserrat(
                              color: Colors.white,
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
                        onTap: () => _featuredController.nextPage(duration: 500.ms, curve: Curves.easeInOut),
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
                children: [
                  Row(
                    children: [
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
                    children: [
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
                color: Colors.black.withOpacity(0.02),
                borderRadius: const BorderRadius.only(topLeft: Radius.circular(50), topRight: Radius.circular(50)),
                border: Border.all(color: Colors.black.withOpacity(0.04)),
              ),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
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
                        backgroundColor: Colors.white,
                        foregroundColor: Colors.black,
                        padding: const EdgeInsets.symmetric(vertical: 22),
                        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(15)),
                      ),
                      child: _isSubmitting 
                        ? const SizedBox(height: 15, width: 15, child: CircularProgressIndicator(strokeWidth: 2, color: Colors.black))
                        : Text('SUBMIT INTEREST', style: GoogleFonts.montserrat(fontWeight: FontWeight.bold, letterSpacing: 3, fontSize: 12)),
                    ),
                  ),
                ],
              ),
            ),
          ),
          
          const SliverToBoxAdapter(child: SizedBox(height: 120)),
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
    final displayPrice = startingPrice.isNotEmpty ? '₹ $startingPrice' : 'Contact Us';
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
                children: [
                  ClipRRect(
                    borderRadius: BorderRadius.circular(20),
                    child: hasImage
                        ? Image.network(
                            imageUrl,
                            width: double.infinity,
                            fit: BoxFit.cover,
                            errorBuilder: (_, __, ___) => Container(
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
                filter: ImageFilter.blur(sigmaX: 15, sigmaY: 15),
                child: Container(
                  padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 12),
                  decoration: BoxDecoration(
                    color: Colors.white.withOpacity(0.6), 
                    borderRadius: BorderRadius.circular(15),
                    border: Border.all(color: Colors.white.withOpacity(0.6)),
                  ),
                  child: Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text('STARTING FROM', style: TextStyle(color: Theme.of(context).colorScheme.onSurface.withOpacity(0.3), fontSize: 7, fontWeight: FontWeight.bold)),
                          Text(displayPrice, style: GoogleFonts.montserrat(fontSize: 14, fontWeight: FontWeight.bold, color: Theme.of(context).colorScheme.onSurface)),
                        ],
                      ),
                      Icon(LucideIcons.arrowRight, color: Theme.of(context).colorScheme.onSurface.withOpacity(0.2), size: 14),
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

class _TextTab extends StatelessWidget {
  final String label;
  final bool isActive;
  final VoidCallback onTap;

  const _TextTab({required this.label, this.isActive = false, required this.onTap});

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    return GestureDetector(
      onTap: onTap,
      child: Padding(
        padding: const EdgeInsets.only(right: 25),
        child: Container(
          padding: const EdgeInsets.only(bottom: 6),
          decoration: BoxDecoration(
            border: isActive ? Border(bottom: BorderSide(color: isDark ? Colors.white : Colors.black, width: 2)) : null,
          ),
          child: Text(
            label,
            style: GoogleFonts.montserrat(
              color: isActive ? (isDark ? Colors.white : Colors.black) : (isDark ? Colors.white60 : Colors.black54),
              fontSize: 11,
              fontWeight: FontWeight.w900,
              letterSpacing: 1.5,
            ),
          ),
        ),
      ),
    );
  }
}
