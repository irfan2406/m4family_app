import 'package:dio/dio.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter/material.dart';
import 'package:m4_mobile/core/theme/app_theme.dart';
import 'package:m4_mobile/core/network/api_client.dart';
import 'package:lucide_icons/lucide_icons.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:flutter_animate/flutter_animate.dart';
import 'dart:ui';
import 'package:m4_mobile/core/utils/support_handlers.dart';
import 'package:m4_mobile/presentation/providers/auth_provider.dart';

class ProjectDetailScreen extends ConsumerStatefulWidget {
  final dynamic projectData; // Initial summary data from list
  final String projectId;

  const ProjectDetailScreen({
    super.key, 
    required this.projectId,
    this.projectData,
  });

  @override
  ConsumerState<ProjectDetailScreen> createState() => _ProjectDetailScreenState();
}

class _ProjectDetailScreenState extends ConsumerState<ProjectDetailScreen> with SingleTickerProviderStateMixin {
  late TabController _tabController;
  dynamic _fullProject;
  List<dynamic> _updates = [];
  List<dynamic> _inventory = [];
  bool _isLoading = true;

  final List<String> _tabs = [
    'OVERVIEW',
    'AMENITIES',
    'PRICING',
    'INVENTORY',
    'UPDATES',
    'LOCATION',
    'PLANNING',
    'MEDIA',
    'DOCUMENTS',
  ];

  @override
  void initState() {
    super.initState();
    _tabController = TabController(length: _tabs.length, vsync: this);
    _fetchProjectData();
  }

  Future<void> _fetchProjectData() async {
    try {
      final apiClient = ref.read(apiClientProvider);
      
      // Parallel fetches for speed
      final results = await Future.wait<Response<dynamic>>([
        apiClient.getProjectDetails(widget.projectId),
        apiClient.getProjectUpdates(widget.projectId),
        apiClient.getProjectInventory(widget.projectId),
      ]);

      if (mounted) {
        setState(() {
          if (results[0].data['status'] == true) {
            _fullProject = results[0].data['data'];
          }
          if (results[1].data['status'] == true) {
            _updates = results[1].data['data'] ?? [];
          }
           if (results[2].data['status'] == true) {
            _inventory = results[2].data['data'] ?? [];
          }
          _isLoading = false;
        });
      }
    } catch (e) {
      if (mounted) setState(() => _isLoading = false);
    }
  }

  @override
  void dispose() {
    _tabController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    // Fallback to widget.projectData if _fullProject isn't loaded yet
    final project = _fullProject ?? widget.projectData;
    if (project == null && _isLoading) {
      return const Scaffold(
        backgroundColor: M4Theme.background,
        body: Center(child: CircularProgressIndicator(color: Colors.white24)),
      );
    }

    return Scaffold(
      backgroundColor: M4Theme.background,
      body: Stack(
        children: [
          // Main Scrollable Content
          NestedScrollView(
            headerSliverBuilder: (context, innerBoxIsScrolled) {
              return [
                _buildSliverAppBar(project),
                _buildSliverTabBar(),
              ];
            },
            body: TabBarView(
              controller: _tabController,
              children: [
                _buildOverview(project),
                _buildAmenities(project),
                _buildPricing(project),
                _buildInventory(),
                _buildUpdates(),
                _buildLocation(project),
                _buildPlanning(project),
                _buildMedia(project),
                _buildDocuments(project),
              ],
            ),
          ),

          // Custom Back Button (Floating)
          Positioned(
            top: MediaQuery.of(context).padding.top + 10,
            left: 20,
            child: GestureDetector(
              onTap: () => Navigator.pop(context),
              child: ClipRRect(
                borderRadius: BorderRadius.circular(15),
                child: BackdropFilter(
                  filter: ImageFilter.blur(sigmaX: 10, sigmaY: 10),
                  child: Container(
                    padding: const EdgeInsets.all(12),
                    decoration: BoxDecoration(
                      color: Colors.black.withOpacity(0.35),
                      borderRadius: BorderRadius.circular(15),
                      border: Border.all(color: Colors.white.withOpacity(0.1)),
                    ),
                    child: const Icon(LucideIcons.chevronLeft, color: Colors.white, size: 20),
                  ),
                ),
              ),
            ),
          ),

          // Bottom Action Bar
          Positioned(
            bottom: 30,
            left: 24,
            right: 24,
            child: _buildBottomActions(project),
          ),
        ],
      ),
    );
  }

  Widget _buildSliverAppBar(dynamic project) {
    final heroImage = project?['heroImages'] != null && project['heroImages'].isNotEmpty
        ? project['heroImages'][0]
        : 'https://images.unsplash.com/photo-1545324418-cc1a3fa10c00?auto=format&fit=crop&q=80';

    return SliverAppBar(
      expandedHeight: 450,
      backgroundColor: M4Theme.background,
      automaticallyImplyLeading: false,
      pinned: true,
      flexibleSpace: FlexibleSpaceBar(
        background: Stack(
          fit: StackFit.expand,
          children: [
            // Hero Image
            Image.network(heroImage, fit: BoxFit.cover),
            
            // Gradient Overlay
            Container(
              decoration: BoxDecoration(
                gradient: LinearGradient(
                  begin: Alignment.topCenter,
                  end: Alignment.bottomCenter,
                  colors: [
                    Colors.black.withOpacity(0.4),
                    Colors.transparent,
                    M4Theme.background,
                  ],
                  stops: const [0.0, 0.5, 1.0],
                ),
              ),
            ),

            // Header Content
            Positioned(
              bottom: 40,
              left: 30,
              right: 30,
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    children: [
                      _Badge(text: project?['status']?.toUpperCase() ?? 'ONGOING'),
                      const SizedBox(width: 10),
                      const _Badge(text: 'ARTISTIC IMPRESSION', isOutline: true),
                    ],
                  ),
                  const SizedBox(height: 20),
                  Text(
                    project?['title']?.toUpperCase() ?? 'M4 PROJECT',
                    style: GoogleFonts.montserrat(
                      fontSize: 36,
                      fontWeight: FontWeight.w900,
                      color: Colors.white,
                      height: 1.1,
                      letterSpacing: -1,
                    ),
                  ),
                  const SizedBox(height: 12),
                  Row(
                    children: [
                      const Icon(LucideIcons.mapPin, color: M4Theme.premiumBlue, size: 16),
                      const SizedBox(width: 8),
                      Text(
                        project?['location']?['name'] ?? 'MUMBAI, INDIA',
                        style: GoogleFonts.montserrat(
                          fontSize: 14,
                          color: Colors.white70,
                          fontWeight: FontWeight.w600,
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
    );
  }

  Widget _buildSliverTabBar() {
    return SliverPersistentHeader(
      pinned: true,
      delegate: _SliverAppBarDelegate(
        TabBar(
          controller: _tabController,
          isScrollable: true,
          labelColor: Colors.white,
          unselectedLabelColor: Colors.white38,
          indicatorWeight: 3,
          indicatorColor: M4Theme.premiumBlue,
          indicatorPadding: const EdgeInsets.symmetric(horizontal: 10),
          labelStyle: GoogleFonts.montserrat(fontSize: 11, fontWeight: FontWeight.w900, letterSpacing: 1),
          tabs: _tabs.map((tab) => Tab(text: tab)).toList(),
        ),
      ),
    );
  }

  Widget _buildOverview(dynamic project) {
    return _buildTabContent(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            'PROJECT OVERVIEW',
            style: GoogleFonts.montserrat(
              fontSize: 10,
              fontWeight: FontWeight.w900,
              color: M4Theme.premiumBlue,
              letterSpacing: 2,
            ),
          ),
          const SizedBox(height: 16),
          Text(
            project?['description'] ?? 'Experience luxurious living redefined with M4 Family. Our projects blend architectural excellence with modern comforts to create homes that inspire.',
            style: GoogleFonts.montserrat(
              fontSize: 14,
              color: Colors.white.withOpacity(0.7),
              height: 1.8,
            ),
          ),
          const SizedBox(height: 32),
          
          // Action Grid
          GridView.count(
            shrinkWrap: true,
            physics: const NeverScrollableScrollPhysics(),
            crossAxisCount: 2,
            mainAxisSpacing: 16,
            crossAxisSpacing: 16,
            childAspectRatio: 2.2,
            children: [
              _OverviewActionCard(icon: LucideIcons.fileText, label: 'E-BROCHURE'),
              _OverviewActionCard(icon: LucideIcons.box, label: '3D VIEW'),
              _OverviewActionCard(icon: LucideIcons.glasses, label: 'VR TOUR'),
              _OverviewActionCard(icon: LucideIcons.video, label: 'PROJECT FILM'),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildAmenities(dynamic project) {
    final amenities = project?['amenities'] as List? ?? [];
    return _buildTabContent(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            'LUXURY AMENITIES',
            style: GoogleFonts.montserrat(
              fontSize: 10,
              fontWeight: FontWeight.w900,
              color: M4Theme.premiumBlue,
              letterSpacing: 2,
            ),
          ),
          const SizedBox(height: 24),
          if (amenities.isEmpty)
             _EmptyTabContent(message: 'Amenities details updated soon')
          else
            GridView.builder(
              shrinkWrap: true,
              physics: const NeverScrollableScrollPhysics(),
              gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
                crossAxisCount: 3,
                mainAxisSpacing: 20,
                crossAxisSpacing: 20,
                childAspectRatio: 0.8,
              ),
              itemCount: amenities.length,
              itemBuilder: (context, index) {
                final amenity = amenities[index];
                return Column(
                  children: [
                    Container(
                      padding: const EdgeInsets.all(16),
                      decoration: BoxDecoration(
                        color: Colors.white.withOpacity(0.03),
                        borderRadius: BorderRadius.circular(20),
                        border: Border.all(color: Colors.white.withOpacity(0.05)),
                      ),
                      child: Icon(
                        _getAmenityIcon(amenity['name']), 
                        color: Colors.white, 
                        size: 24
                      ),
                    ),
                    const SizedBox(height: 10),
                    Text(
                      amenity['name']?.toString().toUpperCase() ?? 'AMENITY',
                      textAlign: TextAlign.center,
                      style: GoogleFonts.montserrat(
                        fontSize: 8,
                        fontWeight: FontWeight.w700,
                        color: Colors.white54,
                        letterSpacing: 0.5,
                      ),
                    ),
                  ],
                );
              },
            ),
        ],
      ),
    );
  }

  Widget _buildPricing(dynamic project) {
    return _buildTabContent(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          _SectionHeader(title: 'PRICING STRUCTURE'),
          const SizedBox(height: 24),
          _PricingCard(
            config: project?['config'] ?? '2, 3 & 4 BHK',
            price: project?['startingPrice'] != null ? '₹ ${project['startingPrice']}' : 'Contact Us',
            area: 'Starting from 1200 Sq.Ft.',
          ),
        ],
      ),
    );
  }

  Widget _buildInventory() {
    return _buildTabContent(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          _SectionHeader(title: 'AVAILABLE INVENTORY'),
          const SizedBox(height: 24),
          if (_inventory.isEmpty && !_isLoading)
            _EmptyTabContent(message: 'Inventory data coming soon')
          else if (_isLoading)
            const Center(child: CircularProgressIndicator(color: Colors.white10))
          else
            ..._inventory.map((unit) => _InventoryItem(unit: unit)).toList(),
        ],
      ),
    );
  }

  Widget _buildUpdates() {
     return _buildTabContent(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          _SectionHeader(title: 'CONSTRUCTION PROGRESS'),
          const SizedBox(height: 24),
          if (_updates.isEmpty && !_isLoading)
            _EmptyTabContent(message: 'Updates being posted soon')
          else if (_isLoading)
             const Center(child: CircularProgressIndicator(color: Colors.white10))
          else
            ..._updates.map((update) => _UpdateItem(update: update)).toList(),
        ],
      ),
    );
  }

  Widget _buildLocation(dynamic project) {
    return _buildTabContent(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          _SectionHeader(title: 'PRIME LOCATION'),
          const SizedBox(height: 24),
          Container(
            height: 200,
            decoration: BoxDecoration(
              color: Colors.white.withOpacity(0.05),
              borderRadius: BorderRadius.circular(25),
              image: const DecorationImage(
                image: NetworkImage('https://images.unsplash.com/photo-1526778548025-fa2f459cd5ce?auto=format&fit=crop&q=80'),
                fit: BoxFit.cover,
                opacity: 0.4,
              ),
            ),
            child: const Center(
              child: Icon(LucideIcons.map, color: Colors.white24, size: 40),
            ),
          ),
          const SizedBox(height: 32),
          const _LocationLandmark(icon: LucideIcons.plane, title: 'Mumbai International Airport', distance: '12.4 KM'),
          const _LocationLandmark(icon: LucideIcons.train, title: 'Grant Road Railway Station', distance: '1.2 KM'),
          const _LocationLandmark(icon: LucideIcons.building, title: 'Bandra-Kurla Complex (BKC)', distance: '8.5 KM'),
        ],
      ),
    );
  }

  Widget _buildPlanning(dynamic project) {
    return _buildTabContent(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          _SectionHeader(title: 'ARCHITECTURAL PLANNING'),
          const SizedBox(height: 24),
          _EmptyTabContent(message: 'Floor plans and layouts are being finalized'),
        ],
      ),
    );
  }

  Widget _buildMedia(dynamic project) {
    return _buildTabContent(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          _SectionHeader(title: 'PROJECT GALLERY'),
          const SizedBox(height: 24),
          _EmptyTabContent(message: 'New photos and videos coming soon'),
        ],
      ),
    );
  }

  Widget _buildDocuments(dynamic project) {
    return _buildTabContent(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          _SectionHeader(title: 'LEGAL & COMPLIANCE'),
          const SizedBox(height: 24),
          _DocumentItem(title: 'RERA Registration Certificate', size: '1.2 MB'),
          _DocumentItem(title: 'Commencement Certificate', size: '2.4 MB'),
        ],
      ),
    );
  }

  Widget _buildTabContent({required Widget child}) {
    return SingleChildScrollView(
      padding: const EdgeInsets.fromLTRB(24, 30, 24, 150),
      child: child,
    );
  }

  Widget _buildBottomActions(dynamic project) {
    return ClipRRect(
      borderRadius: BorderRadius.circular(30),
      child: BackdropFilter(
        filter: ImageFilter.blur(sigmaX: 15, sigmaY: 15),
        child: Container(
          padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
          decoration: BoxDecoration(
            color: Colors.black.withOpacity(0.5),
            borderRadius: BorderRadius.circular(30),
            border: Border.all(color: Colors.white.withOpacity(0.1)),
          ),
          child: Row(
            children: [
              _BottomIconAction(icon: LucideIcons.phone, onTap: SupportHandlers.launchCall),
              const SizedBox(width: 8),
              _BottomIconAction(icon: LucideIcons.messageSquare, onTap: SupportHandlers.launchWhatsApp),
              const SizedBox(width: 12),
              Expanded(
                child: GestureDetector(
                  onTap: () {
                    // Logic for Book Now / Inquiry
                    ScaffoldMessenger.of(context).showSnackBar(
                      const SnackBar(content: Text('Booking request initiated!我们的 team will contact you soon.')),
                    );
                  },
                  child: Container(
                    height: 56,
                    decoration: BoxDecoration(
                      gradient: LinearGradient(
                        colors: [M4Theme.premiumBlue, Color(0xFF60A5FA)],
                      ),
                      borderRadius: BorderRadius.circular(20),
                    ),
                    child: Center(
                      child: Text(
                        'BOOK NOW',
                        style: GoogleFonts.montserrat(
                          color: Colors.white,
                          fontWeight: FontWeight.w900,
                          fontSize: 13,
                          letterSpacing: 2,
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
    );
  }

  IconData _getAmenityIcon(String? name) {
    final n = name?.toLowerCase() ?? '';
    if (n.contains('gym')) return LucideIcons.dumbbell;
    if (n.contains('pool')) return LucideIcons.waves;
    if (n.contains('garden')) return LucideIcons.leaf;
    if (n.contains('parking')) return LucideIcons.car;
    if (n.contains('security')) return LucideIcons.shieldCheck;
    if (n.contains('club')) return LucideIcons.coffee;
    return LucideIcons.sparkles;
  }
}

// Helper Widgets
class _Badge extends StatelessWidget {
  final String text;
  final bool isOutline;
  const _Badge({required this.text, this.isOutline = false});

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
      decoration: BoxDecoration(
        color: isOutline ? Colors.transparent : Colors.white,
        borderRadius: BorderRadius.circular(10),
        border: isOutline ? Border.all(color: Colors.white30) : null,
      ),
      child: Text(
        text,
        style: GoogleFonts.montserrat(
          fontSize: 8,
          fontWeight: FontWeight.w900,
          color: isOutline ? Colors.white70 : Colors.black,
          letterSpacing: 1,
        ),
      ),
    );
  }
}

class _OverviewActionCard extends StatelessWidget {
  final IconData icon;
  final String label;
  const _OverviewActionCard({required this.icon, required this.label});

  @override
  Widget build(BuildContext context) {
    return Container(
      decoration: BoxDecoration(
        color: Colors.white.withOpacity(0.03),
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: Colors.white.withOpacity(0.05)),
      ),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Icon(icon, color: Colors.white38, size: 16),
          const SizedBox(width: 10),
          Text(
            label,
            style: GoogleFonts.montserrat(
              color: Colors.white,
              fontSize: 9,
              fontWeight: FontWeight.w800,
              letterSpacing: 1,
            ),
          ),
        ],
      ),
    );
  }
}

class _PricingCard extends StatelessWidget {
  final String config;
  final String price;
  final String area;

  const _PricingCard({required this.config, required this.price, required this.area});

  @override
  Widget build(BuildContext context) {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(24),
      decoration: BoxDecoration(
        color: Colors.white.withOpacity(0.03),
        borderRadius: BorderRadius.circular(25),
        border: Border.all(color: Colors.white.withOpacity(0.05)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(config, style: GoogleFonts.montserrat(color: Colors.white, fontSize: 18, fontWeight: FontWeight.bold)),
          const SizedBox(height: 8),
          Text(area, style: GoogleFonts.montserrat(color: Colors.white38, fontSize: 12)),
          const SizedBox(height: 20),
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Text(price, style: GoogleFonts.montserrat(color: M4Theme.premiumBlue, fontSize: 22, fontWeight: FontWeight.w900)),
              const Icon(LucideIcons.chevronRight, color: Colors.white10),
            ],
          ),
        ],
      ),
    );
  }
}

class _UpdateItem extends StatelessWidget {
  final dynamic update;
  const _UpdateItem({required this.update});

  @override
  Widget build(BuildContext context) {
    return Container(
      margin: const EdgeInsets.only(bottom: 24),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Column(
            children: [
              CircleAvatar(radius: 6, backgroundColor: M4Theme.premiumBlue),
              Container(width: 2, height: 80, color: Colors.white10),
            ],
          ),
          const SizedBox(width: 20),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(update['date'] ?? 'March 2024', style: GoogleFonts.montserrat(color: Colors.white38, fontSize: 10, fontWeight: FontWeight.bold)),
                const SizedBox(height: 8),
                Text(update['title'] ?? 'Construction Update', style: GoogleFonts.montserrat(color: Colors.white, fontSize: 15, fontWeight: FontWeight.bold)),
                const SizedBox(height: 8),
                Text(update['content'] ?? 'Work on the foundation and basement levels has been completed. Currently focusing on the internal structure.', 
                  style: GoogleFonts.montserrat(color: Colors.white54, fontSize: 12, height: 1.5)),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

class _InventoryItem extends StatelessWidget {
  final dynamic unit;
  const _InventoryItem({required this.unit});

  @override
  Widget build(BuildContext context) {
    return Container(
      margin: const EdgeInsets.only(bottom: 12),
      padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 16),
      decoration: BoxDecoration(
        color: Colors.white.withOpacity(0.03),
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: Colors.white.withOpacity(0.05)),
      ),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(unit['unitNumber'] ?? 'Unit 402', style: GoogleFonts.montserrat(color: Colors.white, fontWeight: FontWeight.bold)),
              Text(unit['type'] ?? '3 BHK - Type A', style: GoogleFonts.montserrat(color: Colors.white38, fontSize: 11)),
            ],
          ),
          _Badge(
            text: unit['status']?.toString().toUpperCase() ?? 'AVAILABLE', 
            isOutline: unit['status']?.toString().toLowerCase() != 'available'
          ),
        ],
      ),
    );
  }
}

class _LocationLandmark extends StatelessWidget {
  final IconData icon;
  final String title;
  final String distance;
  const _LocationLandmark({required this.icon, required this.title, required this.distance});

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 20),
      child: Row(
        children: [
          Container(
            padding: const EdgeInsets.all(12),
            decoration: BoxDecoration(
              color: Colors.white.withOpacity(0.03),
              shape: BoxShape.circle,
            ),
            child: Icon(icon, color: Colors.white38, size: 18),
          ),
          const SizedBox(width: 16),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(title, style: GoogleFonts.montserrat(color: Colors.white, fontSize: 13, fontWeight: FontWeight.w600)),
                Text(distance, style: GoogleFonts.montserrat(color: Colors.white38, fontSize: 11)),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

class _DocumentItem extends StatelessWidget {
  final String title;
  final String size;
  const _DocumentItem({required this.title, required this.size});

  @override
  Widget build(BuildContext context) {
    return Container(
      margin: const EdgeInsets.only(bottom: 12),
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.white.withOpacity(0.03),
        borderRadius: BorderRadius.circular(16),
      ),
      child: Row(
        children: [
          Icon(LucideIcons.fileText, color: M4Theme.premiumBlue, size: 20),
          const SizedBox(width: 16),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(title, style: GoogleFonts.montserrat(color: Colors.white, fontSize: 12, fontWeight: FontWeight.bold)),
                Text(size, style: GoogleFonts.montserrat(color: Colors.white38, fontSize: 10)),
              ],
            ),
          ),
          const Icon(LucideIcons.download, color: Colors.white24, size: 18),
        ],
      ),
    );
  }
}

class _BottomIconAction extends StatelessWidget {
  final IconData icon;
  final VoidCallback onTap;
  const _BottomIconAction({required this.icon, required this.onTap});

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        height: 56,
        width: 56,
        decoration: BoxDecoration(
          color: Colors.white.withOpacity(0.08),
          borderRadius: BorderRadius.circular(20),
        ),
        child: Icon(icon, color: Colors.white, size: 20),
      ),
    );
  }
}

class _SectionHeader extends StatelessWidget {
  final String title;
  const _SectionHeader({required this.title});

  @override
  Widget build(BuildContext context) {
    return Text(
      title,
      style: GoogleFonts.montserrat(
        fontSize: 10,
        fontWeight: FontWeight.w900,
        color: M4Theme.premiumBlue,
        letterSpacing: 2,
      ),
    );
  }
}

class _EmptyTabContent extends StatelessWidget {
  final String message;
  const _EmptyTabContent({required this.message});

  @override
  Widget build(BuildContext context) {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          const SizedBox(height: 48),
          const Icon(LucideIcons.frown, color: Colors.white12, size: 40),
          const SizedBox(height: 16),
          Text(
            message,
            textAlign: TextAlign.center,
            style: GoogleFonts.montserrat(color: Colors.white24, fontSize: 12),
          ),
        ],
      ),
    );
  }
}

class _SliverAppBarDelegate extends SliverPersistentHeaderDelegate {
  final TabBar tabBar;
  _SliverAppBarDelegate(this.tabBar);

  @override
  double get minExtent => tabBar.preferredSize.height + 20;
  @override
  double get maxExtent => tabBar.preferredSize.height + 20;

  @override
  Widget build(BuildContext context, double shrinkOffset, bool overlapsContent) {
    return ClipRRect(
      child: BackdropFilter(
        filter: ImageFilter.blur(sigmaX: 15, sigmaY: 15),
        child: Container(
          color: M4Theme.background.withOpacity(0.85),
          padding: const EdgeInsets.symmetric(vertical: 10),
          child: tabBar,
        ),
      ),
    );
  }

  @override
  bool shouldRebuild(_SliverAppBarDelegate oldDelegate) => false;
}
