import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:lucide_icons/lucide_icons.dart';
import 'package:flutter_animate/flutter_animate.dart';
import 'dart:ui';
import 'package:m4_mobile/core/theme/app_theme.dart';
import 'package:m4_mobile/presentation/providers/auth_provider.dart';
import 'package:m4_mobile/presentation/screens/projects/project_detail_screen.dart';
import 'package:url_launcher/url_launcher.dart';
import 'package:m4_mobile/core/utils/support_handlers.dart';
import 'package:m4_mobile/core/network/api_client.dart';
import 'package:m4_mobile/presentation/widgets/conditional_drawer.dart';

class CommunityDetailScreen extends ConsumerStatefulWidget {
  final dynamic community;
  const CommunityDetailScreen({super.key, required this.community});

  @override
  ConsumerState<CommunityDetailScreen> createState() => _CommunityDetailScreenState();
}

class _CommunityDetailScreenState extends ConsumerState<CommunityDetailScreen> {
  final ScrollController _scrollController = ScrollController();
  final GlobalKey _inquiryKey = GlobalKey();
  List<dynamic> _projects = [];
  bool _projectsLoading = true;
  bool _isSubmitting = false;

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
      final communityId = widget.community['_id'] ?? widget.community['id'];
      if (communityId != null) {
        final res = await apiClient.getProjectsByCommunity(communityId.toString());
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
      if (mounted) setState(() => _projectsLoading = false);
    }
  }

  Future<void> _handleLeadSubmission() async {
    if (_nameController.text.isEmpty || _emailController.text.isEmpty || _phoneController.text.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Please fill all required fields')),
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
        'interest': 'Community Interest',
        'message': 'Expressing interest in community: ${widget.community['title']}',
        'source': 'Mobile Guest Portal',
      });

      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Interest registered successfully!'), backgroundColor: Colors.green),
        );
        _nameController.clear();
        _emailController.clear();
        _phoneController.clear();
        _locationController.clear();
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Submission failed: $e')),
        );
      }
    } finally {
      if (mounted) setState(() => _isSubmitting = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final apiClient = ref.watch(apiClientProvider);
    final heroImageUrl = apiClient.resolveUrl(widget.community['image'] ?? widget.community['heroImage']);
    final benefitsRaw = widget.community['benefits'] as List? ?? [];
    final benefits = benefitsRaw.isNotEmpty ? benefitsRaw : [
      {'icon': 'LayoutGrid', 'label': 'COMMUNITY CENTRIC DESIGN'},
      {'icon': 'MapPin', 'label': 'PRIME LOCATION'},
      {'icon': 'Trees', 'label': 'GREEN SPACES AND PARKS'},
      {'icon': 'Shield', 'label': 'SAFETY AND SECURITY'},
      {'icon': 'ShoppingBag', 'label': 'RETAIL OUTLETS'},
      {'icon': 'Bus', 'label': 'TRANSPORTATION ACCESS'},
    ];

    return Scaffold(
      backgroundColor: isDark ? Colors.black : Colors.white,
      drawer: const ConditionalDrawer(),
      body: CustomScrollView(
        controller: _scrollController,
        slivers: [
              // 🔝 Sticky Header
              SliverToBoxAdapter(
                child: Container(
                  padding: const EdgeInsets.fromLTRB(25, 60, 15, 20),
                  child: Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                       GestureDetector(
                        onTap: () => Navigator.pop(context),
                        child: Container(
                          width: 45,
                          height: 45,
                          decoration: BoxDecoration(
                            shape: BoxShape.circle,
                            color: (isDark ? Colors.white : Colors.black).withOpacity(0.05),
                            border: Border.all(color: (isDark ? Colors.white : Colors.black).withOpacity(0.1)),
                          ),
                          child: Icon(LucideIcons.chevronLeft, color: isDark ? Colors.white : Colors.black, size: 20),
                        ),
                      ),
                      Row(
                        children: [
                          Column(
                            crossAxisAlignment: CrossAxisAlignment.end,
                            children: [
                              Text(
                                'M4 FAMILY',
                                style: GoogleFonts.inter(
                                  color: isDark ? Colors.white : Colors.black,
                                  fontSize: 18,
                                  fontWeight: FontWeight.w900,
                                  letterSpacing: -1,
                                ),
                              ),
                              Text(
                                'DEVELOPMENTS',
                                style: GoogleFonts.inter(
                                  color: (isDark ? Colors.white : Colors.black).withOpacity(0.5),
                                  fontSize: 8,
                                  fontWeight: FontWeight.bold,
                                  letterSpacing: 3,
                                ),
                              ),
                            ],
                          ),
                          const SizedBox(width: 8),
                          Builder(
                            builder: (context) => IconButton(
                              icon: Icon(LucideIcons.moreHorizontal, color: isDark ? Colors.white : Colors.black, size: 28),
                              onPressed: () => Scaffold.of(context).openDrawer(),
                            ),
                          ),
                        ],
                      ),
                    ],
                  ),
                ),
              ),

              // 🏗️ Hero Section
              SliverToBoxAdapter(
                child: Container(
                  height: 400,
                  width: double.infinity,
                  padding: const EdgeInsets.symmetric(horizontal: 25, vertical: 20),
                  child: ClipRRect(
                    borderRadius: BorderRadius.circular(50),
                    child: Stack(
                      fit: StackFit.expand,
                      children: [
                        Image.network(
                          heroImageUrl,
                          fit: BoxFit.cover,
                        ).animate().fadeIn(duration: 800.ms),
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
                        Positioned(
                          bottom: 40,
                          left: 30,
                          right: 30,
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Text(
                                widget.community['title']?.toString() ?? '',
                                style: GoogleFonts.lora(
                                  fontSize: 38,
                                  fontWeight: FontWeight.w400,
                                  color: Colors.white,
                                  height: 1,
                                ),
                              ).animate().fadeIn(delay: 200.ms).slideY(begin: 0.2),
                              const SizedBox(height: 12),
                              Text(
                                (widget.community['subtitle'] ?? '').toString().toUpperCase(),
                                style: GoogleFonts.inter(
                                  color: const Color(0xFFC6A355),
                                  fontSize: 10,
                                  fontWeight: FontWeight.w900,
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
                          final query = Uri.encodeComponent(widget.community['location'] ?? 'Dubai');
                          final url = Uri.parse('https://www.google.com/maps/search/?api=1&query=$query');
                          if (await canLaunchUrl(url)) {
                            await launchUrl(url);
                          }
                        },
                        child: Container(
                          padding: const EdgeInsets.all(20),
                          decoration: BoxDecoration(
                            color: (isDark ? Colors.white : Colors.black).withOpacity(0.05),
                            borderRadius: BorderRadius.circular(20),
                            border: Border.all(color: (isDark ? Colors.white : Colors.black).withOpacity(0.1)),
                          ),
                          child: Row(
                            children: [
                              Container(
                                padding: const EdgeInsets.all(10),
                                decoration: BoxDecoration(
                                  color: isDark ? Colors.white : Colors.black,
                                  shape: BoxShape.circle,
                                ),
                                child: Icon(LucideIcons.mapPin, color: isDark ? Colors.black : Colors.white, size: 18),
                              ),
                              const SizedBox(width: 15),
                              Text(
                                (widget.community['location'] ?? '').toString().toUpperCase(),
                                style: GoogleFonts.inter(
                                  color: isDark ? Colors.white : Colors.black,
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
                      _SectionHeader(
                        title: 'ABOUT THE\nCOMMUNITY',
                        subtitle: 'ABOUT ${widget.community['title']?.toString().toUpperCase()}',
                      ),
                      const SizedBox(height: 25),
                      Text(
                        widget.community['overview'] ?? widget.community['description'] ?? '',
                        style: GoogleFonts.lora(
                          color: (isDark ? Colors.white : Colors.black).withOpacity(0.6),
                          fontSize: 14,
                          height: 1.8,
                          fontWeight: FontWeight.w500,
                        ),
                      ).animate().fadeIn(delay: 200.ms),

                      const SizedBox(height: 50),

                      // Benefits
                      const _SectionHeader(title: 'BENEFITS', subtitle: 'LIFESTYLE ADVANTAGES'),
                      const SizedBox(height: 30),
                      GridView.builder(
                        shrinkWrap: true,
                        physics: const NeverScrollableScrollPhysics(),
                        gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
                          crossAxisCount: 2,
                          crossAxisSpacing: 15,
                          mainAxisSpacing: 15,
                          childAspectRatio: 1.0,
                        ),
                        itemCount: benefits.length,
                        itemBuilder: (context, index) {
                          final benefit = benefits[index];
                          return Container(
                            decoration: BoxDecoration(
                              color: (isDark ? Colors.white : Colors.black).withOpacity(0.04),
                              borderRadius: BorderRadius.circular(35),
                              border: Border.all(color: (isDark ? Colors.white : Colors.black).withOpacity(0.06)),
                            ),
                            child: Column(
                              mainAxisAlignment: MainAxisAlignment.center,
                              children: [
                                Container(
                                  width: 50,
                                  height: 50,
                                  decoration: BoxDecoration(
                                    color: (isDark ? Colors.white : Colors.black).withOpacity(0.1),
                                    borderRadius: BorderRadius.circular(20),
                                  ),
                                  child: Icon(_getIcon(benefit['icon']), color: isDark ? Colors.white : Colors.black, size: 24),
                                ),
                                const SizedBox(height: 15),
                                Padding(
                                  padding: const EdgeInsets.symmetric(horizontal: 10),
                                  child: Text(
                                    benefit['label'].toString().toUpperCase(),
                                    textAlign: TextAlign.center,
                                    style: GoogleFonts.inter(
                                      color: (isDark ? Colors.white : Colors.black).withOpacity(0.7),
                                      fontSize: 8,
                                      fontWeight: FontWeight.w900,
                                      letterSpacing: 0.5,
                                      height: 1.4,
                                    ),
                                  ),
                                ),
                              ],
                            ),
                          );
                        },
                      ),

                      const SizedBox(height: 60),

                      // Projects Section
                      if (_projects.isNotEmpty) ...[
                        Row(
                          mainAxisAlignment: MainAxisAlignment.spaceBetween,
                          crossAxisAlignment: CrossAxisAlignment.end,
                          children: [
                            const _SectionHeader(
                              title: 'PROJECTS',
                              subtitle: 'EXPLORE ARCHITECTURAL MASTERPIECES',
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
                                style: GoogleFonts.inter(
                                  color: Colors.white.withOpacity(0.5),
                                  fontSize: 10,
                                  fontWeight: FontWeight.w900,
                                  letterSpacing: 2,
                                ),
                              ),
                            ),
                          ],
                        ),
                        const SizedBox(height: 30),
                        SizedBox(
                          height: 200,
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
                                  width: 280,
                                  margin: const EdgeInsets.only(right: 20),
                                  decoration: BoxDecoration(
                                    borderRadius: BorderRadius.circular(30),
                                    image: DecorationImage(
                                      image: NetworkImage(apiClient.resolveUrl(project['heroImage'] ?? project['image'])),
                                      fit: BoxFit.cover,
                                    ),
                                  ),
                                  child: Stack(
                                    children: [
                                      Container(
                                        decoration: BoxDecoration(
                                          borderRadius: BorderRadius.circular(30),
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
                                          mainAxisAlignment: MainAxisAlignment.end,
                                          crossAxisAlignment: CrossAxisAlignment.start,
                                          children: [
                                            Text(
                                              project['title']?.toString().toUpperCase() ?? '',
                                              style: GoogleFonts.inter(
                                                color: Colors.white,
                                                fontSize: 16,
                                                fontWeight: FontWeight.w900,
                                                letterSpacing: -0.5,
                                              ),
                                            ),
                                            const SizedBox(height: 4),
                                            Row(
                                              children: [
                                                const Icon(LucideIcons.mapPin, color: Colors.white54, size: 10),
                                                const SizedBox(width: 5),
                                                Text(
                                                  (project['location']?['name'] ?? project['location'] ?? '').toString().toUpperCase(),
                                                  style: GoogleFonts.inter(
                                                    color: Colors.white54,
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
                                            color: Colors.white,
                                            shape: BoxShape.circle,
                                          ),
                                          child: const Icon(LucideIcons.arrowRight, color: Colors.black, size: 18),
                                        ),
                                      ),
                                    ],
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
                          const _SectionHeader(
                            title: 'EXPRESS\nINTEREST',
                            subtitle: 'INITIALIZE YOUR PREMIUM EXPERIENCE',
                          ),
                          const SizedBox(height: 30),
                          _buildInput('Full Name *', _nameController),
                          const SizedBox(height: 12),
                          Row(
                            children: [
                              Expanded(child: _buildInput('Email Address *', _emailController)),
                              const SizedBox(width: 12),
                              Expanded(child: _buildInput('Phone Number *', _phoneController)),
                            ],
                          ),
                          const SizedBox(height: 12),
                          _buildInput('Your Location (e.g. Dubai, UAE) *', _locationController),
                          const SizedBox(height: 20),
                          SizedBox(
                            width: double.infinity,
                            height: 70,
                            child: ElevatedButton(
                              onPressed: _isSubmitting ? null : _handleLeadSubmission,
                              style: ElevatedButton.styleFrom(
                                backgroundColor: isDark ? Colors.white : Colors.black,
                                foregroundColor: isDark ? Colors.black : Colors.white,
                                shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
                              ),
                              child: _isSubmitting 
                                ? CircularProgressIndicator(color: isDark ? Colors.black : Colors.white)
                                : Text(
                                    'REGISTER INTEREST',
                                    style: GoogleFonts.inter(
                                      fontSize: 12,
                                      fontWeight: FontWeight.w900,
                                      letterSpacing: 3,
                                    ),
                                  ),
                            ),
                          ),
                          const SizedBox(height: 20),
                          Center(
                            child: Text(
                              'EXCLUSIVE GUEST PREVIEW - LIMITED OPPORTUNITIES',
                              style: GoogleFonts.inter(
                                color: (isDark ? Colors.white : Colors.black).withOpacity(0.3),
                                fontSize: 8,
                                fontWeight: FontWeight.w900,
                                letterSpacing: 2,
                              ),
                            ),
                          ),
                        ],
                      ),

                      const SizedBox(height: 60),

                      // Map Section
                      const _SectionHeader(title: 'FIND US', subtitle: 'OUR STRATEGIC HEADQUARTERS'),
                      const SizedBox(height: 15),
                      GestureDetector(
                        onTap: () async {
                          const url = 'https://www.google.com/maps/search/?api=1&query=604,+6th+Floor,+M4+Aura+Heights,+Grant+Road,+Mumbai+-+400007';
                          if (await canLaunchUrl(Uri.parse(url))) {
                            await launchUrl(Uri.parse(url));
                          }
                        },
                        child: Container(
                          height: 300,
                          width: double.infinity,
                          decoration: BoxDecoration(
                            borderRadius: BorderRadius.circular(40),
                            image: const DecorationImage(
                              image: NetworkImage('https://images.unsplash.com/photo-1526778548025-fa2f459cd5c1?auto=format&fit=crop&q=80'),
                              fit: BoxFit.cover,
                              colorFilter: ColorFilter.mode(Colors.black54, BlendMode.darken),
                            ),
                          ),
                          child: Stack(
                            children: [
                              Positioned(
                                bottom: 30,
                                left: 30,
                                right: 30,
                                child: Row(
                                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                                  children: [
                                    Column(
                                      crossAxisAlignment: CrossAxisAlignment.start,
                                      children: [
                                        Text(
                                          'M4 AURA HEIGHTS',
                                          style: GoogleFonts.inter(
                                            color: Colors.white,
                                            fontSize: 16,
                                            fontWeight: FontWeight.w900,
                                          ),
                                        ),
                                        const SizedBox(height: 5),
                                        Text(
                                          'GRANT ROAD, MUMBAI - 400007',
                                          style: GoogleFonts.inter(
                                            color: Colors.white.withOpacity(0.6),
                                            fontSize: 10,
                                            fontWeight: FontWeight.w500,
                                            letterSpacing: 1,
                                          ),
                                        ),
                                      ],
                                    ),
                                    Container(
                                      width: 50,
                                      height: 50,
                                      decoration: BoxDecoration(
                                        color: Colors.white,
                                        borderRadius: BorderRadius.circular(20),
                                      ),
                                      child: const Icon(LucideIcons.mapPin, color: Colors.black, size: 24),
                                    ),
                                  ],
                                ),
                              ),
                            ],
                          ),
                        ),
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

  Widget _buildInput(String hint, TextEditingController controller) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 20),
      decoration: BoxDecoration(
        color: (isDark ? Colors.white : Colors.black).withOpacity(0.05),
        borderRadius: BorderRadius.circular(20),
        border: Border.all(color: (isDark ? Colors.white : Colors.black).withOpacity(0.05)),
      ),
      child: TextField(
        controller: controller,
        style: GoogleFonts.inter(color: isDark ? Colors.white : Colors.black, fontSize: 13, fontWeight: FontWeight.bold),
        decoration: InputDecoration(
          border: InputBorder.none,
          hintText: hint.toUpperCase(),
          hintStyle: GoogleFonts.inter(
            color: (isDark ? Colors.white : Colors.black).withOpacity(0.3),
            fontSize: 10,
            fontWeight: FontWeight.w900,
            letterSpacing: 2,
          ),
        ),
      ),
    );
  }

  IconData _getIcon(String icon) {
    switch (icon) {
      case 'LayoutGrid': return LucideIcons.layoutGrid;
      case 'MapPin': return LucideIcons.mapPin;
      case 'Trees': return LucideIcons.trees;
      case 'Shield': return LucideIcons.shield;
      case 'ShoppingBag': return LucideIcons.shoppingBag;
      case 'Bus': return LucideIcons.bus;
      default: return LucideIcons.sparkles;
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
            Container(width: 4, height: 40, color: isDark ? Colors.white : Colors.black),
            const SizedBox(width: 20),
            Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  title,
                  style: GoogleFonts.inter(
                    color: isDark ? Colors.white : Colors.black,
                    fontSize: 22,
                    fontWeight: FontWeight.w900,
                    height: 1.1,
                  ),
                ),
                const SizedBox(height: 5),
                Text(
                  subtitle,
                  style: GoogleFonts.inter(
                    color: (isDark ? Colors.white : Colors.black).withOpacity(0.4),
                    fontSize: 8,
                    fontWeight: FontWeight.w900,
                    letterSpacing: 2,
                  ),
                ),
              ],
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
  const CommunityProjectsScreen({super.key, required this.community, required this.projects});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final apiClient = ref.watch(apiClientProvider);

    return Scaffold(
      backgroundColor: Colors.black,
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
                        const Icon(LucideIcons.arrowLeft, color: Colors.white, size: 20),
                        const SizedBox(width: 10),
                        Text(
                          'BACK',
                          style: GoogleFonts.inter(
                            color: Colors.white.withOpacity(0.5),
                            fontSize: 10,
                            fontWeight: FontWeight.w900,
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
                        style: GoogleFonts.inter(
                          color: Colors.white,
                          fontSize: 18,
                          fontWeight: FontWeight.w900,
                          letterSpacing: -1,
                        ),
                      ),
                      Text(
                        'COMMUNITY PORTFOLIO',
                        style: GoogleFonts.inter(
                          color: Colors.white.withOpacity(0.5),
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
            padding: const EdgeInsets.symmetric(horizontal: 25),
            sliver: SliverList(
              delegate: SliverChildBuilderDelegate(
                (context, index) {
                  final project = projects[index];
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
                      height: 250,
                      margin: const EdgeInsets.only(bottom: 25),
                      decoration: BoxDecoration(
                        borderRadius: BorderRadius.circular(40),
                        image: DecorationImage(
                          image: NetworkImage(apiClient.resolveUrl(project['heroImage'] ?? project['image'])),
                          fit: BoxFit.cover,
                        ),
                      ),
                      child: Stack(
                        children: [
                          Container(
                            decoration: BoxDecoration(
                              borderRadius: BorderRadius.circular(40),
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
                          // Status Label (Top Right)
                          if (project['status'] != null)
                            Positioned(
                              top: 25,
                              right: 25,
                              child: Container(
                                padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
                                decoration: BoxDecoration(
                                  color: Colors.white.withOpacity(0.1),
                                  borderRadius: BorderRadius.circular(10),
                                  border: Border.all(color: Colors.white.withOpacity(0.2)),
                                ),
                                child: Text(
                                  project['status'].toString().toUpperCase(),
                                  style: GoogleFonts.inter(
                                    color: Colors.white,
                                    fontSize: 8,
                                    fontWeight: FontWeight.w900,
                                    letterSpacing: 1,
                                  ),
                                ),
                              ),
                            ),
                          // Bottom Content
                          Positioned(
                            bottom: 30,
                            left: 30,
                            right: 30,
                            child: Row(
                              crossAxisAlignment: CrossAxisAlignment.end,
                              children: [
                                Expanded(
                                  child: Column(
                                    crossAxisAlignment: CrossAxisAlignment.start,
                                    children: [
                                      Text(
                                        project['title']?.toString().toUpperCase() ?? '',
                                        style: GoogleFonts.inter(
                                          color: Colors.white,
                                          fontSize: 22,
                                          fontWeight: FontWeight.w900,
                                          letterSpacing: -1,
                                        ),
                                      ),
                                      const SizedBox(height: 5),
                                      Row(
                                        children: [
                                          const Icon(LucideIcons.mapPin, color: Colors.white54, size: 10),
                                          const SizedBox(width: 5),
                                          Text(
                                            (project['location']?['name'] ?? project['location'] ?? '').toString().toUpperCase(),
                                            style: GoogleFonts.inter(
                                              color: Colors.white54,
                                              fontSize: 9,
                                              fontWeight: FontWeight.bold,
                                              letterSpacing: 1,
                                            ),
                                          ),
                                        ],
                                      ),
                                      const SizedBox(height: 15),
                                      Text(
                                        'STARTING FROM',
                                        style: GoogleFonts.inter(
                                          color: Colors.white.withOpacity(0.4),
                                          fontSize: 7,
                                          fontWeight: FontWeight.w900,
                                          letterSpacing: 1,
                                        ),
                                      ),
                                      Text(
                                        (project['roiTarget'] ?? project['startingPrice'] ?? 'UPON REQUEST').toString().toUpperCase(),
                                        style: GoogleFonts.lora(
                                          color: Colors.white,
                                          fontSize: 18,
                                          fontWeight: FontWeight.w600,
                                        ),
                                      ),
                                      const SizedBox(height: 4),
                                      Text(
                                        '* ARTISTIC IMPRESSION',
                                        style: GoogleFonts.inter(
                                          color: Colors.white.withOpacity(0.2),
                                          fontSize: 6,
                                          fontWeight: FontWeight.bold,
                                          letterSpacing: 1,
                                        ),
                                      ),
                                    ],
                                  ),
                                ),
                                Container(
                                  width: 50,
                                  height: 50,
                                  decoration: const BoxDecoration(
                                    color: Colors.white,
                                    shape: BoxShape.circle,
                                  ),
                                  child: const Icon(LucideIcons.arrowRight, color: Colors.black, size: 20),
                                ),
                              ],
                            ),
                          ),
                        ],
                      ),
                    ),
                  );
                },
                childCount: projects.length,
              ),
            ),
          ),
          const SliverToBoxAdapter(child: SizedBox(height: 60)),
        ],
      ),
    );
  }
}
