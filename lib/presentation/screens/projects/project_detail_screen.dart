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
import 'package:url_launcher/url_launcher.dart';
import 'package:share_plus/share_plus.dart';

class ProjectDetailScreen extends ConsumerStatefulWidget {
  final dynamic projectData; 
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
  final TextEditingController _nameController = TextEditingController();
  final TextEditingController _phoneController = TextEditingController();
  final TextEditingController _emailController = TextEditingController();
  bool _isFavorited = false;
  String _mediaFilter = 'ALL';

  final List<String> _tabs = [
    'OVERVIEW',
    'PRICING',
    'INVENTORY',
    'LOCATION',
    'AMENITIES',
    'PLANNING',
    'UPDATES',
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

  void _launchAction(String message, [String? url]) async {
    if (url != null && url.isNotEmpty) {
      final uri = Uri.parse(url);
      if (await canLaunchUrl(uri)) {
        await launchUrl(uri, mode: LaunchMode.externalApplication);
        return;
      }
    }
    
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(message, style: GoogleFonts.montserrat(fontSize: 12, fontWeight: FontWeight.bold)),
        backgroundColor: M4Theme.premiumBlue,
        behavior: SnackBarBehavior.floating,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
      ),
    );
  }

  @override
  void dispose() {
    _tabController.dispose();
    _nameController.dispose();
    _phoneController.dispose();
    _emailController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final project = _fullProject ?? widget.projectData;
    if (project == null && _isLoading) {
      return Scaffold(
        backgroundColor: Theme.of(context).scaffoldBackgroundColor,
        body: const Center(child: CircularProgressIndicator(color: Colors.white24)),
      );
    }

    return Scaffold(
      backgroundColor: Colors.white,
      body: Stack(
        children: [
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
                _buildPricing(project),
                _buildInventory(project),
                _buildLocation(project),
                _buildAmenities(project),
                _buildPlanning(project),
                _buildUpdates(project),
                _buildMedia(project),
                _buildDocuments(project),
              ],
            ),
          ),
          Positioned(
            top: MediaQuery.of(context).padding.top + 10,
            left: 20,
            child: _TopIconButton(
              icon: LucideIcons.chevronLeft, 
              onTap: () => Navigator.pop(context)
            ),
          ),
          Positioned(
            top: MediaQuery.of(context).padding.top + 10,
            right: 20,
            child: Row(
              children: [
                _TopIconButton(
                  icon: LucideIcons.share2, 
                  onTap: () {
                    final title = project?['title'] ?? 'M4 Project';
                    final location = project?['location']?['name'] ?? 'Mumbai, India';
                    Share.share('Check out this premium project: $title in $location via M4 Family App!');
                  },
                ),
                const SizedBox(width: 12),
                _TopIconButton(
                  icon: _isFavorited ? LucideIcons.star : LucideIcons.star,
                  color: _isFavorited ? Colors.amber : Colors.black,
                  onTap: () {
                    setState(() => _isFavorited = !_isFavorited);
                    ScaffoldMessenger.of(context).showSnackBar(
                      SnackBar(content: Text(_isFavorited ? 'Added to favorites' : 'Removed from favorites'))
                    );
                  },
                ),
              ],
            ),
          ),
          _buildBottomActions(project),
        ],
      ),
    );
  }

  Widget _buildSliverAppBar(dynamic project) {
    final apiClient = ref.watch(apiClientProvider);

    final heroImage = project?['heroImage'] != null
        ? project['heroImage']
        : (project?['images'] is List && (project['images'] as List).isNotEmpty
            ? project['images'][0]
            : 'https://images.unsplash.com/photo-1545324418-cc1a3fa10c00?auto=format&fit=crop&q=80');

    return SliverAppBar(
      expandedHeight: 450,
      backgroundColor: Theme.of(context).scaffoldBackgroundColor,
      automaticallyImplyLeading: false,
      pinned: true,
      flexibleSpace: FlexibleSpaceBar(
        background: Stack(
          fit: StackFit.expand,
          children: [
            Image.network(apiClient.resolveUrl(heroImage), fit: BoxFit.cover,
              errorBuilder: (context, error, stackTrace) => Container(color: Colors.black.withOpacity(0.1), child: const Center(child: Icon(LucideIcons.image, color: Colors.black12, size: 50)))),
            Container(
              decoration: BoxDecoration(
                gradient: LinearGradient(
                  begin: Alignment.topCenter,
                  end: Alignment.bottomCenter,
                  colors: [
                    Colors.black.withOpacity(0.1),
                    Colors.transparent,
                    Colors.white,
                  ],
                  stops: const [0.0, 0.5, 1.0],
                ),
              ),
            ),
            Positioned(
              bottom: 40,
              left: 24,
              right: 24,
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    children: [
                      _Badge(text: project?['status']?.toUpperCase() ?? 'ONGOING'),
                      const SizedBox(width: 8),
                      const _Badge(text: 'ARTISTIC IMPRESSION', isOutline: true),
                    ],
                  ),
                  const SizedBox(height: 16),
                  Text(
                    project?['title']?.toUpperCase() ?? 'M4 PROJECT',
                    style: GoogleFonts.dmSerifDisplay(
                      fontSize: 40,
                      fontWeight: FontWeight.normal,
                      color: Colors.black,
                      height: 1.0,
                      letterSpacing: 0,
                    ),
                  ),
                  const SizedBox(height: 8),
                  Row(
                    children: [
                      Icon(LucideIcons.mapPin, color: Colors.black.withOpacity(0.4), size: 14),
                      const SizedBox(width: 6),
                      Text(
                        project?['location']?['name']?.toUpperCase() ?? 'MUMBAI, INDIA',
                        style: GoogleFonts.montserrat(
                          fontSize: 10,
                          fontWeight: FontWeight.bold,
                          color: Colors.black.withOpacity(0.4),
                          letterSpacing: 1,
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 24),
                  SingleChildScrollView(
                    scrollDirection: Axis.horizontal,
                    child: Row(
                      children: [
                        _HeaderStatCard(
                          label: 'CONFIG', 
                          value: project?['config'] ?? '3 & 4 BHK',
                          icon: LucideIcons.layout,
                        ),
                        const SizedBox(width: 12),
                        _HeaderStatCard(
                          label: 'VIDEO CALL', 
                          value: 'CONNECT',
                          icon: LucideIcons.video,
                          isAction: true,
                          onTap: () => _launchAction('Connecting to Video Call...', project?['videoCallUrl']),
                        ),
                         const SizedBox(width: 12),
                        _HeaderStatCard(
                          label: 'SITE VISIT', 
                          value: 'SCHEDULE',
                          icon: LucideIcons.calendar,
                          isAction: true,
                          onTap: () => _launchAction('Opening Schedule Flow...', project?['siteVisitUrl']),
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

  Widget _buildSliverTabBar() {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    return SliverPersistentHeader(
      pinned: true,
      delegate: _SliverAppBarDelegate(
        TabBar(
          controller: _tabController,
          isScrollable: true,
          labelColor: Colors.black,
          unselectedLabelColor: Colors.black.withOpacity(0.38),
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
            'ABOUT THE RESIDENCE',
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
              color: Colors.black.withOpacity(0.7),
              height: 1.8,
            ),
          ),
          const SizedBox(height: 32),
          // Brochure Card
          Container(
            padding: const EdgeInsets.all(20),
            decoration: BoxDecoration(
              color: Colors.black.withOpacity(0.04),
              borderRadius: BorderRadius.circular(24),
              border: Border.all(color: Colors.black.withOpacity(0.05)),
            ),
            child: Row(
              children: [
                Container(
                  padding: const EdgeInsets.all(12),
                  decoration: BoxDecoration(color: Colors.black.withOpacity(0.05), borderRadius: BorderRadius.circular(12)),
                  child: const Icon(LucideIcons.fileText, color: Colors.black, size: 20),
                ),
                const SizedBox(width: 16),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text('E-BROCHURE', style: GoogleFonts.montserrat(fontSize: 10, fontWeight: FontWeight.w900, color: Colors.black87, letterSpacing: 1)),
                      Text('PDF • 4.2 MB', style: GoogleFonts.montserrat(fontSize: 8, fontWeight: FontWeight.bold, color: Colors.black38)),
                    ],
                  ),
                ),
                _ScaleButton(
                  onTap: () => _launchAction('Brochure not available yet', project?['brochureUrl']),
                  child: Container(
                    padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 10),
                    decoration: BoxDecoration(
                      color: Colors.black.withOpacity(0.05),
                      borderRadius: BorderRadius.circular(10),
                      border: Border.all(color: Colors.black.withOpacity(0.05)),
                    ),
                    child: Text('DOWNLOAD', style: GoogleFonts.montserrat(fontSize: 9, fontWeight: FontWeight.bold, letterSpacing: 1, color: Colors.black)),
                  ),
                ),
              ],
            ),
          ),
          const SizedBox(height: 24),
          GridView.count(
            shrinkWrap: true,
            physics: const NeverScrollableScrollPhysics(),
            crossAxisCount: 2,
            mainAxisSpacing: 16,
            crossAxisSpacing: 16,
            childAspectRatio: 1.1,
            children: [
              _ScaleButton(
                onTap: () => _launchAction('VR Tour being prepared', project?['vrTourUrl']),
                child: _OverviewPremiumCard(
                  icon: LucideIcons.glasses, 
                  title: 'VR TOUR', 
                  subtitle: 'Immersive Experience',
                  onTap: () {}, // Handled by wrapper
                ),
              ),
            ],
          ),
          const SizedBox(height: 32),
          Text('CONNECT WITH US', style: GoogleFonts.montserrat(fontSize: 10, fontWeight: FontWeight.w900, color: Colors.black38, letterSpacing: 2)),
          const SizedBox(height: 16),
          Row(
            children: [
              _SocialIconButton(icon: LucideIcons.instagram, onTap: () => _launchAction('Opening Instagram', project?['social']?['instagram'])),
              const SizedBox(width: 12),
              _SocialIconButton(icon: LucideIcons.facebook, onTap: () => _launchAction('Opening Facebook', project?['social']?['facebook'])),
              const SizedBox(width: 12),
              _SocialIconButton(icon: LucideIcons.linkedin, onTap: () => _launchAction('Opening LinkedIn', project?['social']?['linkedin'])),
              const SizedBox(width: 12),
              _SocialIconButton(icon: LucideIcons.youtube, onTap: () => _launchAction('Opening YouTube', project?['social']?['youtube'])),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildAmenities(dynamic project) {
    final amenitiesRaw = project?['amenities'] as List? ?? [];
    return _buildTabContent(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          _SectionHeader(title: 'PREMIUM AMENITIES'),
          const SizedBox(height: 24),
          if (amenitiesRaw.isEmpty)
            const _EmptyTabContent(message: 'Amenities like fitness centers and green spaces are coming soon')
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
              itemCount: amenitiesRaw.length,
              itemBuilder: (context, index) {
                final amenity = amenitiesRaw[index];
                final name = amenity is Map ? (amenity['name']?.toString() ?? 'Amenity') : amenity.toString();
                
                return Column(
                  children: [
                    Container(
                      width: 60,
                      height: 60,
                      decoration: BoxDecoration(
                        color: Theme.of(context).colorScheme.onSurface.withOpacity(0.04),
                        borderRadius: BorderRadius.circular(20),
                        border: Border.all(color: Theme.of(context).colorScheme.onSurface.withOpacity(0.05)),
                      ),
                      child: Icon(_getAmenityIcon(name), color: Theme.of(context).colorScheme.onSurface, size: 24),
                    ),
                    const SizedBox(height: 10),
                    Text(
                      name.toUpperCase(),
                      textAlign: TextAlign.center,
                      style: GoogleFonts.montserrat(fontSize: 8, fontWeight: FontWeight.w700, color: Theme.of(context).colorScheme.onSurface.withOpacity(0.54), letterSpacing: 0.5),
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
    String startingPrice = project?['startingPrice']?.toString() ?? 'N/A';
    if (startingPrice == 'N/A') {
      if (_inventory.isNotEmpty) {
        final prices = _inventory.map((u) => double.tryParse(u['price']?.toString().replaceAll(',', '') ?? '0') ?? 0).where((p) => p > 0).toList();
        if (prices.isNotEmpty) {
          prices.sort();
          startingPrice = '₹ ${prices.first.toStringAsFixed(0)}';
        } else {
          startingPrice = 'Contact Us';
        }
      } else {
        startingPrice = 'Contact Us';
      }
    } else {
       if (!startingPrice.contains('₹')) startingPrice = '₹ $startingPrice';
    }

    return _buildTabContent(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          _PricingCard(
            config: project?['config'] ?? '2, 3 & 4 BHK',
            price: startingPrice,
            area: project?['areaRange'] ?? 'Starting from 1200 Sq.Ft.',
          ),
          const SizedBox(height: 48),
          _SectionHeader(title: 'PAYMENT PLANS'),
          const SizedBox(height: 24),
          if (project?['paymentPlans'] != null && (project?['paymentPlans'] as List).isNotEmpty)
             ...((project?['paymentPlans'] as List).map((plan) => _PaymentPlanCard(
               plan: plan, 
               onRequestDetails: () => _showRequestDetailsDialog(project, plan),
             )).toList())
          else
          _PaymentPlanCard(
              plan: {
                'name': '80/20 STANDARD PLAN',
                'status': 'Active',
                'steps': [
                  {'label': 'Booking Amount', 'value': '10%'},
                  {'label': 'During Construction', 'value': '50%'},
                  {'label': 'On Handover', 'value': '40%'},
                ]
              },
              onRequestDetails: () => _showRequestDetailsDialog(project, {'name': '80/20 STANDARD PLAN'}),
            ),
          const SizedBox(height: 32),
          // Disclaimer Note
          Container(
            padding: const EdgeInsets.all(20),
            decoration: BoxDecoration(
              color: Colors.black.withOpacity(0.04),
              borderRadius: BorderRadius.circular(20),
            ),
            child: Row(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Icon(LucideIcons.info, color: Colors.black.withOpacity(0.4), size: 16),
                const SizedBox(width: 12),
                Expanded(
                  child: Text(
                    'PRICES AND PAYMENT TERMS ARE SUBJECT TO CHANGE BY THE DEVELOPER. FINAL TERMS WILL BE OUTLINED IN THE SALES AND PURCHASE AGREEMENT (SPA).',
                    style: GoogleFonts.montserrat(
                      fontSize: 9,
                      fontWeight: FontWeight.bold,
                      color: Colors.black.withOpacity(0.6),
                      height: 1.5,
                      letterSpacing: 0.5,
                    ),
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildInventory(dynamic project) {
    return _buildTabContent(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              _SectionHeader(title: 'AVAILABLE INVENTORY'),
              const _Badge(text: 'LIVE INVENTORY', isOutline: true),
            ],
          ),
          const SizedBox(height: 24),
          if (_inventory.isEmpty && !_isLoading)
            const _EmptyTabContent(message: 'Inventory data coming soon')
          else if (_isLoading)
            Center(child: CircularProgressIndicator(color: Theme.of(context).colorScheme.onSurface.withOpacity(0.1)))
          else
            ..._inventory.map((unit) => _InventoryItem(unit: unit)).toList(),
        ],
      ),
    );
  }

  Widget _buildUpdates(dynamic project) {
    final apiClient = ref.watch(apiClientProvider);
    return _buildTabContent(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              _SectionHeader(title: 'CONSTRUCTION UPDATES'),
              const _Badge(text: 'LIVE TRACKING', isOutline: true),
            ],
          ),
          const SizedBox(height: 24),
          if (_updates.isEmpty && !_isLoading)
            const _EmptyTabContent(message: 'Construction is scheduled to begin soon')
          else if (_isLoading)
            Center(child: CircularProgressIndicator(color: Theme.of(context).colorScheme.onSurface.withOpacity(0.1)))
          else
            ..._updates.map((update) => _ConstructionUpdateCard(
              update: update,
              imageUrl: apiClient.resolveUrl(update['image']?.toString()),
            )).toList(),
        ],
      ),
    );
  }

  Widget _buildLocation(dynamic project) {
    final apiClient = ref.read(apiClientProvider);
    return _buildTabContent(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          _SectionHeader(title: 'LOCATION & ACCESSIBILITY'),
          const SizedBox(height: 24),
          Container(
            height: 200,
            width: double.infinity,
            decoration: BoxDecoration(
              color: Theme.of(context).colorScheme.onSurface.withOpacity(0.05),
              borderRadius: BorderRadius.circular(25),
              image: DecorationImage(
                image: NetworkImage(apiClient.resolveUrl(project?['locationMapUrl'] ?? 'https://images.unsplash.com/photo-1526778548025-fa2f459cd5ce?auto=format&fit=crop&q=80')),
                fit: BoxFit.cover,
                opacity: 0.4,
              ),
            ),
            child: const Center(child: Icon(LucideIcons.map, color: Colors.black12, size: 40)),
          ),
          const SizedBox(height: 32),
          const _LocationLandmark(icon: LucideIcons.plane, title: 'Mumbai International Airport', distance: '12.4 KM • 15 MINS'),
          const _LocationLandmark(icon: LucideIcons.train, title: 'Metro Station', distance: '1.2 KM • 5 MINS'),
          const _LocationLandmark(icon: LucideIcons.building, title: 'City Mall', distance: '8.5 KM • 10 MINS'),
        ],
      ),
    );
  }

  Widget _buildPlanning(dynamic project) {
    final apiClient = ref.read(apiClientProvider);
    return _buildTabContent(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          _SectionHeader(title: 'ARCHITECTURAL PLANNING'),
          const SizedBox(height: 24),
          if (project?['plans'] != null && (project['plans'] as List).isNotEmpty)
            ...((project['plans'] as List).map((plan) => _FloorPlanItem(
              plan: plan, 
              imageUrl: apiClient.resolveUrl(plan['image']?.toString()),
              onLaunch: _launchAction,
            )).toList())
          else
            const _EmptyTabContent(message: 'Floor plans and layouts are being finalized'),
        ],
      ),
    );
  }

  Widget _buildMedia(dynamic project) {
    final apiClient = ref.read(apiClientProvider);
    final List<String> gallery = [];
    if (project?['heroImage'] != null) gallery.add(project['heroImage']);
    if (project?['images'] is List) gallery.addAll((project['images'] as List).cast<String>());
    if (project?['media'] is List) {
      for (var item in project['media']) {
        if (item is Map && (item['type'] == 'Image' || item['type'] == 'Video')) {
          if (item['url'] != null) gallery.add(item['url']);
        }
      }
    }
    final uniqueGallery = gallery.toSet().toList();

    final allMedia = project?['media'] as List? ?? [];
    
    final List<dynamic> filteredMedia = allMedia.where((item) {
      if (_mediaFilter == 'ALL') return true;
      if (_mediaFilter == 'PHOTOS') return item['type'] == 'Image';
      if (_mediaFilter == 'VIDEOS') return item['type'] == 'Video';
      return true;
    }).toList();

    return _buildTabContent(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              _SectionHeader(title: 'PROJECT GALLERY'),
              _Badge(text: '${filteredMedia.length} ITEMS', isOutline: true),
            ],
          ),
          const SizedBox(height: 24),
          SingleChildScrollView(
            scrollDirection: Axis.horizontal,
            child: Row(
              children: [
                _FilterChip(
                  label: 'ALL', 
                  isActive: _mediaFilter == 'ALL', 
                  onTap: () => setState(() => _mediaFilter = 'ALL'),
                ),
                const SizedBox(width: 12),
                _FilterChip(
                  label: 'PHOTOS', 
                  isActive: _mediaFilter == 'PHOTOS', 
                  onTap: () => setState(() => _mediaFilter = 'PHOTOS'),
                ),
                const SizedBox(width: 12),
                _FilterChip(
                  label: 'VIDEOS', 
                  isActive: _mediaFilter == 'VIDEOS', 
                  onTap: () => setState(() => _mediaFilter = 'VIDEOS'),
                ),
              ],
            ),
          ),
          const SizedBox(height: 24),
          if (filteredMedia.isEmpty)
            const _EmptyTabContent(message: 'No media items found for this category')
          else
            GridView.builder(
              shrinkWrap: true,
              physics: const NeverScrollableScrollPhysics(),
              gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
                crossAxisCount: 2,
                mainAxisSpacing: 16,
                crossAxisSpacing: 16,
                childAspectRatio: 1,
              ),
              itemCount: filteredMedia.length,
              itemBuilder: (context, index) {
                final item = filteredMedia[index];
                final url = item['url']?.toString() ?? '';
                final type = item['type']?.toString().toUpperCase() ?? 'IMAGE';
                
                return GestureDetector(
                  onTap: () => _showMediaLightbox(url, type),
                  child: Stack(
                    children: [
                      ClipRRect(
                        borderRadius: BorderRadius.circular(20),
                        child: Image.network(
                          apiClient.resolveUrl(url), 
                          fit: BoxFit.cover, height: double.infinity, width: double.infinity,
                          errorBuilder: (context, error, stackTrace) => Container(
                            color: Colors.black.withOpacity(0.05),
                            child: const Center(child: Icon(LucideIcons.image, color: Colors.black26)),
                          ),
                        ),
                      ),
                      Positioned(
                        top: 10, 
                        left: 10, 
                        child: _Badge(text: type, isOutline: true),
                      ),
                      if (type == 'VIDEO')
                        Center(
                          child: Container(
                            padding: const EdgeInsets.all(12),
                            decoration: BoxDecoration(color: Colors.white.withOpacity(0.6), shape: BoxShape.circle),
                            child: const Icon(LucideIcons.play, color: Colors.black, size: 20),
                          ),
                        ),
                    ],
                  ),
                );
              },
            ),
        ],
      ),
    );
  }

  Widget _buildDocuments(dynamic project) {
    final docs = project?['documents'] as List? ?? [];
    return _buildTabContent(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          _SectionHeader(title: 'LEGAL & COMPLIANCE'),
          const SizedBox(height: 24),
          if (docs.isEmpty)
              _DocumentItem(title: 'RERA Registration Certificate', size: '1.2 MB', type: 'LEGAL', onLaunch: _launchAction)
          else
            ...docs.map((doc) => _DocumentItem(
              title: doc['name'] ?? 'Document', 
              size: doc['size'] ?? 'N/A',
              type: doc['type'] ?? 'GENERAL',
              onLaunch: _launchAction,
            )).toList(),
        ],
      ),
    );
  }

  void _showMediaLightbox(String url, String type) {
    final apiClient = ref.read(apiClientProvider);
    showGeneralDialog(
      context: context,
      barrierDismissible: true,
      barrierLabel: 'Media',
      pageBuilder: (context, anim1, anim2) => Scaffold(
        backgroundColor: Colors.black,
        body: Stack(
          children: [
            Center(
              child: InteractiveViewer(
                child: Image.network(apiClient.resolveUrl(url)),
              ),
            ),
            Positioned(
              top: 60,
              right: 20,
              child: GestureDetector(
                onTap: () => Navigator.pop(context),
                child: Container(
                  padding: const EdgeInsets.all(10),
                  decoration: BoxDecoration(color: Colors.white.withOpacity(0.2), shape: BoxShape.circle),
                  child: const Icon(LucideIcons.x, color: Colors.white, size: 20),
                ),
              ),
            ),
            Positioned(
              bottom: 60,
              left: 24,
              right: 24,
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  _Badge(text: '${type.toUpperCase()} MODE', isOutline: true),
                  const SizedBox(height: 12),
                  const _Badge(text: 'VISUAL ASSET • HIGH RESOLUTION'),
                  const SizedBox(height: 16),
                  Text('ASSET PREVIEW', style: GoogleFonts.montserrat(color: Colors.white, fontSize: 18, fontWeight: FontWeight.w900, letterSpacing: 1)),
                  const SizedBox(height: 4),
                  Text('Captured by M4 Creative Team', style: GoogleFonts.montserrat(color: Colors.white.withOpacity(0.4), fontSize: 10, fontWeight: FontWeight.bold)),
                ],
              ),
            ),
          ],
        ),
      ).animate().fadeIn(),
    );
  }

  Widget _buildTabContent({required Widget child}) {
    return SingleChildScrollView(
      padding: const EdgeInsets.fromLTRB(24, 30, 24, 150),
      child: child,
    );
  }

  Widget _buildBottomActions(dynamic project) {
    return Positioned(
      bottom: 30,
      left: 20,
      right: 20,
      child: ClipRRect(
        borderRadius: BorderRadius.circular(30),
        child: BackdropFilter(
          filter: ImageFilter.blur(sigmaX: 15, sigmaY: 15),
          child: Container(
            padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
            decoration: BoxDecoration(
              color: Colors.white.withOpacity(0.4),
              borderRadius: BorderRadius.circular(30),
              border: Border.all(color: Colors.white.withOpacity(0.4)),
            ),
            child: Row(
              children: [
                _BottomIconAction(icon: LucideIcons.phone, onTap: () => SupportHandlers.launchCall(project?['phoneNumber'] ?? project?['phone'])),
                const SizedBox(width: 8),
                _BottomIconAction(icon: LucideIcons.messageSquare, onTap: () => SupportHandlers.launchWhatsApp(project?['phoneNumber'] ?? project?['phone'])),
                const SizedBox(width: 12),
                Expanded(
                  child: _ScaleButton(
                    onTap: () => _showRequestDetailsDialog(project, null),
                    child: Container(
                      height: 56,
                      decoration: BoxDecoration(
                        color: Colors.black, // Premium Dark CTA to match web luxury feel
                        borderRadius: BorderRadius.circular(20),
                      ),
                      child: Center(
                        child: Text(
                          'BOOK NOW',
                          style: GoogleFonts.montserrat(color: Colors.white, fontWeight: FontWeight.w900, fontSize: 13, letterSpacing: 2),
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
    );
  }

  void _showRequestDetailsDialog(dynamic project, dynamic? plan) {
    final theme = Theme.of(context);
    final isDark = theme.brightness == Brightness.dark;

    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (context) => Container(
        padding: EdgeInsets.fromLTRB(24, 32, 24, MediaQuery.of(context).viewInsets.bottom + 32),
        decoration: BoxDecoration(
          color: theme.scaffoldBackgroundColor,
          borderRadius: const BorderRadius.only(topLeft: Radius.circular(30), topRight: Radius.circular(30)),
          boxShadow: [
             BoxShadow(
              color: Colors.black.withOpacity(0.1),
              blurRadius: 20,
              offset: const Offset(0, -5),
            )
          ]
        ),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Text('REQUEST DETAILS', 
                  style: GoogleFonts.montserrat(color: theme.colorScheme.onSurface, fontSize: 18, fontWeight: FontWeight.w900, letterSpacing: 1)),
                GestureDetector(
                  onTap: () => Navigator.pop(context),
                  child: Icon(LucideIcons.x, color: theme.colorScheme.onSurface.withOpacity(0.5), size: 20),
                ),
              ],
            ),
            const SizedBox(height: 8),
            Text('INQUIRY FOR "${plan?['name']?.toString().toUpperCase() ?? 'SELECTED'}" PAYMENT PLAN', 
              style: GoogleFonts.montserrat(color: theme.colorScheme.onSurface.withOpacity(0.5), fontSize: 10, fontWeight: FontWeight.bold, letterSpacing: 0.5)),
            const SizedBox(height: 32),
            
            _buildFieldLabel('FULL NAME *', theme),
            const SizedBox(height: 8),
            _buildThemedField(_nameController, 'Your full name', theme),
            const SizedBox(height: 20),
            
            _buildFieldLabel('PHONE NUMBER *', theme),
            const SizedBox(height: 8),
            _buildThemedField(_phoneController, '+971 50 XXX XXXX', theme),
            const SizedBox(height: 20),
            
            _buildFieldLabel('EMAIL (OPTIONAL)', theme),
            const SizedBox(height: 8),
            _buildThemedField(_emailController, 'irfan12@gmail.com', theme),
            
            const SizedBox(height: 32),
            SizedBox(
              width: double.infinity,
              height: 56,
              child: ElevatedButton(
                onPressed: () async {
                  final name = _nameController.text;
                  final phone = _phoneController.text;
                  final email = _emailController.text;
                  
                  if (name.isEmpty || phone.isEmpty) {
                    _launchAction('Please fill in all required fields');
                    return;
                  }

                  try {
                    await ref.read(apiClientProvider).submitLead({
                      'name': name,
                      'phone': phone,
                      'email': email,
                      'project': project?['title'] ?? 'General Inquiry',
                      'projectId': widget.projectId,
                      'paymentPlan': plan?['name'] ?? 'Custom Plan',
                      'source': 'Mobile App Payment Plan'
                    });
                    
                    if (mounted) {
                      Navigator.pop(context);
                      _nameController.clear();
                      _phoneController.clear();
                      _emailController.clear();
                      _launchAction('Inquiry submitted successfully!');
                    }
                  } catch (e) {
                    _launchAction('Failed to submit inquiry. Please try again.');
                  }
                },
                style: ElevatedButton.styleFrom(
                  backgroundColor: theme.colorScheme.onSurface,
                  foregroundColor: theme.scaffoldBackgroundColor,
                  shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(15)),
                  elevation: 0,
                ),
                child: Row(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    Text('SUBMIT INQUIRY', style: GoogleFonts.montserrat(fontWeight: FontWeight.w900, letterSpacing: 2, fontSize: 13)),
                    const SizedBox(width: 8),
                    const Icon(LucideIcons.arrowUpRight, size: 16),
                  ],
                ),
              ),
            ),
            const SizedBox(height: 24),
            Center(
              child: Text(
                'OUR ADVISOR WILL CONTACT YOU WITHIN 24 HOURS',
                style: GoogleFonts.montserrat(color: theme.colorScheme.onSurface.withOpacity(0.3), fontSize: 8, fontWeight: FontWeight.bold, letterSpacing: 0.5),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildFieldLabel(String label, ThemeData theme) {
    return Text(label, style: GoogleFonts.montserrat(color: theme.colorScheme.onSurface, fontSize: 10, fontWeight: FontWeight.bold, letterSpacing: 0.5));
  }

  Widget _buildThemedField(TextEditingController controller, String hint, ThemeData theme) {
    return TextFormField(
      controller: controller,
      decoration: InputDecoration(
        hintText: hint,
        hintStyle: TextStyle(color: theme.colorScheme.onSurface.withOpacity(0.2), fontSize: 14),
        filled: true,
        fillColor: theme.colorScheme.onSurface.withOpacity(0.03),
        contentPadding: const EdgeInsets.symmetric(horizontal: 20, vertical: 18),
        border: OutlineInputBorder(borderRadius: BorderRadius.circular(15), borderSide: BorderSide(color: theme.colorScheme.onSurface.withOpacity(0.1))),
        enabledBorder: OutlineInputBorder(borderRadius: BorderRadius.circular(15), borderSide: BorderSide(color: theme.colorScheme.onSurface.withOpacity(0.1))),
        focusedBorder: OutlineInputBorder(borderRadius: BorderRadius.circular(15), borderSide: BorderSide(color: theme.colorScheme.onSurface)),
      ),
      style: TextStyle(color: theme.colorScheme.onSurface, fontSize: 14),
    );
  }

  IconData _getAmenityIcon(String? name) {
    final n = name?.toLowerCase() ?? '';
    if (n.contains('gym') || n.contains('fitness')) return LucideIcons.dumbbell;
    if (n.contains('pool') || n.contains('swim')) return LucideIcons.waves;
    if (n.contains('security')) return LucideIcons.shieldCheck;
    if (n.contains('park') || n.contains('garden')) return LucideIcons.treePine;
    if (n.contains('wifi')) return LucideIcons.wifi;
    if (n.contains('window')) return LucideIcons.layout;
    if (n.contains('parking')) return LucideIcons.car;
    if (n.contains('club')) return LucideIcons.users;
    return LucideIcons.sparkles;
  }
}

// Helper Widgets
class _HeaderStatCard extends StatelessWidget {
  final String label;
  final String value;
  final IconData icon;
  final bool isAction;
  final VoidCallback? onTap;

  const _HeaderStatCard({
    required this.label, 
    required this.value, 
    required this.icon, 
    this.isAction = false, 
    this.onTap
  });

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
        decoration: BoxDecoration(
          color: isAction ? M4Theme.premiumBlue.withOpacity(0.1) : Colors.white.withOpacity(0.6),
          borderRadius: BorderRadius.circular(15),
          border: Border.all(color: isAction ? M4Theme.premiumBlue.withOpacity(0.2) : Colors.white.withOpacity(0.6)),
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Icon(icon, color: isAction ? M4Theme.premiumBlue : Colors.black.withOpacity(0.38), size: 10),
                const SizedBox(width: 6),
                Text(label, style: GoogleFonts.montserrat(color: Colors.black.withOpacity(0.38), fontSize: 8, fontWeight: FontWeight.bold, letterSpacing: 0.5)),
              ],
            ),
            const SizedBox(height: 4),
            Text(value, style: GoogleFonts.montserrat(color: Colors.black, fontSize: 13, fontWeight: FontWeight.w900, letterSpacing: 0.5)),
          ],
        ),
      ),
    );
  }
}

class _Badge extends StatelessWidget {
  final String text;
  final bool isOutline;
  const _Badge({required this.text, this.isOutline = false});

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
      decoration: BoxDecoration(
        color: Colors.white.withOpacity(0.4),
        borderRadius: BorderRadius.circular(10),
        border: Border.all(color: Colors.white.withOpacity(0.4)),
      ),
      child: Text(
        text,
        style: GoogleFonts.montserrat(
          fontSize: 8,
          fontWeight: FontWeight.w900,
          color: Colors.black.withOpacity(0.7),
          letterSpacing: 1.0,
        ),
      ),
    );
  }
}

class _OverviewPremiumCard extends StatelessWidget {
  final IconData icon;
  final String title;
  final String subtitle;
  final VoidCallback onTap;

  const _OverviewPremiumCard({
    required this.icon,
    required this.title,
    required this.subtitle,
    required this.onTap,
  });

  @override
  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: Colors.white.withOpacity(0.6),
        borderRadius: BorderRadius.circular(24),
        border: Border.all(color: Colors.white.withOpacity(0.6)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Container(
            padding: const EdgeInsets.all(8),
            decoration: BoxDecoration(color: M4Theme.premiumBlue.withOpacity(0.05), borderRadius: BorderRadius.circular(10)),
            child: Icon(icon, color: M4Theme.premiumBlue, size: 20),
          ),
          const SizedBox(height: 16),
          Text(title, style: GoogleFonts.montserrat(fontSize: 12, fontWeight: FontWeight.w900, color: Colors.black, letterSpacing: 1)),
          const SizedBox(height: 4),
          Text(subtitle, style: GoogleFonts.montserrat(fontSize: 8, fontWeight: FontWeight.bold, color: Colors.black.withOpacity(0.4))),
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
    return _ScaleButton(
      onTap: onTap,
      child: Container(
        width: 56,
        height: 56,
        decoration: BoxDecoration(
          color: Colors.black.withOpacity(0.05),
          borderRadius: BorderRadius.circular(20),
          border: Border.all(color: Colors.black.withOpacity(0.05)),
        ),
        child: Center(child: Icon(icon, color: Colors.black, size: 20)),
      ),
    );
  }
}

class _SectionHeader extends StatelessWidget {
  final String title;
  const _SectionHeader({required this.title});
  @override
  Widget build(BuildContext context) {
    return Text(title, style: GoogleFonts.montserrat(fontSize: 10, fontWeight: FontWeight.w900, color: M4Theme.premiumBlue, letterSpacing: 2));
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
            decoration: BoxDecoration(color: Colors.black.withOpacity(0.04), borderRadius: BorderRadius.circular(15)),
            child: Icon(icon, color: Colors.black.withOpacity(0.4), size: 20),
          ),
          const SizedBox(width: 16),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(title, style: GoogleFonts.montserrat(fontSize: 13, fontWeight: FontWeight.bold, color: Colors.black)),
                Text(distance, style: GoogleFonts.montserrat(fontSize: 11, fontWeight: FontWeight.w600, color: Colors.black.withOpacity(0.38))),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

class _FloorPlanItem extends StatelessWidget {
  final dynamic plan;
  final String imageUrl;
  final Function(String, String?) onLaunch;
  const _FloorPlanItem({required this.plan, required this.imageUrl, required this.onLaunch});
  @override
  Widget build(BuildContext context) {
    return _ScaleButton(
      onTap: () => onLaunch('Opening Floor Plan...', plan['fileUrl']),
      child: Container(
         margin: const EdgeInsets.only(bottom: 16),
        padding: const EdgeInsets.all(20),
        decoration: BoxDecoration(color: Colors.black.withOpacity(0.04), borderRadius: BorderRadius.circular(24), border: Border.all(color: Colors.black.withOpacity(0.05))),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            ClipRRect(borderRadius: BorderRadius.circular(16), child: Image.network(imageUrl, fit: BoxFit.cover, height: 200, width: double.infinity,
              errorBuilder: (context, error, stackTrace) => Container(height: 200, color: Colors.black.withOpacity(0.05), child: Center(child: Icon(LucideIcons.image, color: Colors.black.withOpacity(0.1)))))),
            const SizedBox(height: 16),
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(plan['title'] ?? 'Floor Plan', style: GoogleFonts.montserrat(fontSize: 14, fontWeight: FontWeight.bold, color: Colors.black)),
                      Text(plan['area'] ?? '', style: GoogleFonts.montserrat(fontSize: 12, color: Colors.black.withOpacity(0.4))),
                    ],
                  ),
                ),
                Icon(LucideIcons.download, color: Colors.black.withOpacity(0.24), size: 18),
              ],
            ),
          ],
        ),
      ),
    );
  }
}

class _EmptyTabContent extends StatelessWidget {
  final String message;
  const _EmptyTabContent({required this.message});
  @override
  Widget build(BuildContext context) {
     return Center(child: Text(message, textAlign: TextAlign.center, style: GoogleFonts.montserrat(fontSize: 12, color: Colors.black.withOpacity(0.24))));
  }
}

class _PricingCard extends StatelessWidget {
  final String config;
  final String price;
  final String area;
  final String currency;
  const _PricingCard({required this.config, required this.price, required this.area, this.currency = 'AED'});

  @override
  Widget build(BuildContext context) {
    // If price already contains a currency symbol, we don't need to prepend another one
    final displayPrice = price.contains('₹') || price.contains('AED') || price.contains('\$') 
        ? price 
        : '$currency $price';

    return Container(
      padding: const EdgeInsets.all(24),
      decoration: BoxDecoration(
        color: Colors.white.withOpacity(0.6),
        borderRadius: BorderRadius.circular(30),
        border: Border.all(color: Colors.white.withOpacity(0.6)),
      ),
      child: Column(
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Expanded(
                child: Text(config.toUpperCase(), 
                  style: GoogleFonts.montserrat(fontSize: 14, fontWeight: FontWeight.w900, color: Colors.black),
                  overflow: TextOverflow.ellipsis,
                ),
              ),
              _Badge(text: 'BOOKING OPEN', isOutline: true),
            ],
          ),
          const SizedBox(height: 12),
          Divider(color: Colors.black.withOpacity(0.05)),
          const SizedBox(height: 12),
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Expanded(
                flex: 3,
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text('STARTING FROM', style: GoogleFonts.montserrat(fontSize: 8, fontWeight: FontWeight.bold, color: Colors.black.withOpacity(0.38), letterSpacing: 1)),
                    Text(displayPrice, style: GoogleFonts.montserrat(fontSize: 18, fontWeight: FontWeight.w900, color: M4Theme.premiumBlue)),
                  ],
                ),
              ),
              const SizedBox(width: 8),
              Expanded(
                flex: 2,
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.end,
                  children: [
                    Text('SBA RANGE', style: GoogleFonts.montserrat(fontSize: 8, fontWeight: FontWeight.bold, color: Colors.black.withOpacity(0.38), letterSpacing: 1)),
                    Text(area, textAlign: TextAlign.right, style: GoogleFonts.montserrat(fontSize: 11, fontWeight: FontWeight.bold, color: Colors.black.withOpacity(0.7))),
                  ],
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }
}

class _PaymentPlanCard extends StatelessWidget {
  final dynamic plan;
  final VoidCallback onRequestDetails;
  const _PaymentPlanCard({required this.plan, required this.onRequestDetails});

  @override
  Widget build(BuildContext context) {
    final steps = plan['steps'] as List? ?? [];
    return _ScaleButton(
      onTap: onRequestDetails,
      child: Container(
        margin: const EdgeInsets.only(bottom: 16),
        padding: const EdgeInsets.all(24),
        decoration: BoxDecoration(
          color: Colors.black.withOpacity(0.04),
          borderRadius: BorderRadius.circular(24),
          border: Border.all(color: Colors.black.withOpacity(0.05)),
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Text(plan['name']?.toString().toUpperCase() ?? 'PLAN', style: GoogleFonts.montserrat(fontSize: 12, fontWeight: FontWeight.w900, color: Colors.black)),
                _Badge(text: plan['status']?.toString().toUpperCase() ?? 'ACTIVE', isOutline: true),
              ],
            ),
            const SizedBox(height: 20),
            ...List.generate(steps.length, (index) {
              final step = steps[index];
              final isLast = index == steps.length - 1;
              return Row(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Column(
                    children: [
                      Container(
                        width: 10,
                        height: 10,
                        decoration: const BoxDecoration(color: M4Theme.premiumBlue, shape: BoxShape.circle),
                      ),
                      if (!isLast)
                        Container(
                          width: 1,
                          height: 30,
                          color: M4Theme.premiumBlue.withOpacity(0.2),
                        ),
                    ],
                  ),
                  const SizedBox(width: 16),
                  Expanded(
                    child: Padding(
                      padding: const EdgeInsets.only(bottom: 20),
                      child: Row(
                        mainAxisAlignment: MainAxisAlignment.spaceBetween,
                        children: [
                          Text(step['label']?.toString() ?? '', style: GoogleFonts.montserrat(fontSize: 11, fontWeight: FontWeight.w600, color: Colors.black.withOpacity(0.6))),
                          Text(step['value']?.toString() ?? '', style: GoogleFonts.montserrat(fontSize: 11, fontWeight: FontWeight.w900, color: Colors.black)),
                        ],
                      ),
                    ),
                  ),
                ],
              );
            }),
            const SizedBox(height: 24),
            Container(
              width: double.infinity,
              height: 48,
              decoration: BoxDecoration(
                color: Colors.white,
                borderRadius: BorderRadius.circular(12),
              ),
              child: Row(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Text('REQUEST DETAILS', style: GoogleFonts.montserrat(fontSize: 10, fontWeight: FontWeight.w900, letterSpacing: 2, color: Colors.black)),
                  const SizedBox(width: 8),
                  const Icon(LucideIcons.arrowUpRight, size: 14, color: Colors.black),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _InventoryItem extends StatelessWidget {
  final dynamic unit;
  const _InventoryItem({required this.unit});

  @override
  Widget build(BuildContext context) {
    final currency = unit['currency'] ?? 'AED';
    return _ScaleButton(
      onTap: () {}, // TODO: Connect to booking/inquiry logic
      child: Container(
        margin: const EdgeInsets.only(bottom: 16),
        padding: const EdgeInsets.all(20),
        decoration: BoxDecoration(
          color: Colors.white.withOpacity(0.6),
          borderRadius: BorderRadius.circular(24),
          border: Border.all(color: Colors.white.withOpacity(0.6)),
        ),
        child: Column(
          children: [
            Row(
              children: [
                Container(
                  padding: const EdgeInsets.all(12),
                  decoration: BoxDecoration(color: Colors.black.withOpacity(0.04), borderRadius: BorderRadius.circular(15)),
                  child: const Icon(LucideIcons.home, color: Colors.black, size: 20),
                ),
                const SizedBox(width: 16),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text('UNIT ${unit['unitNumber']}', style: GoogleFonts.montserrat(fontSize: 14, fontWeight: FontWeight.w900, color: Colors.black)),
                      Text('${unit['type']} • ${unit['area']} SQFT', style: GoogleFonts.montserrat(fontSize: 11, color: Colors.black.withOpacity(0.38), fontWeight: FontWeight.bold)),
                    ],
                  ),
                ),
                Column(
                  crossAxisAlignment: CrossAxisAlignment.end,
                  children: [
                    Text('$currency ${unit['price']}', style: GoogleFonts.montserrat(fontSize: 14, fontWeight: FontWeight.w900, color: M4Theme.premiumBlue)),
                    Text('EXCL. TAXES', style: GoogleFonts.montserrat(fontSize: 8, color: Colors.black.withOpacity(0.24), fontWeight: FontWeight.bold, letterSpacing: 0.5)),
                  ],
                ),
              ],
            ),
            const SizedBox(height: 16),
            Container(
              width: double.infinity,
              height: 45,
              decoration: BoxDecoration(
                color: Colors.black.withOpacity(0.05),
                borderRadius: BorderRadius.circular(12),
              ),
              child: Center(
                child: Text('BOOK NOW', style: GoogleFonts.montserrat(fontSize: 10, fontWeight: FontWeight.w900, letterSpacing: 2, color: Colors.black)),
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _ConstructionUpdateCard extends StatelessWidget {
  final dynamic update;
  final String imageUrl;
  const _ConstructionUpdateCard({required this.update, required this.imageUrl});

  @override
  Widget build(BuildContext context) {
    final progress = double.tryParse(update['progress']?.toString() ?? '0') ?? 10.0;
    return Container(
      margin: const EdgeInsets.only(bottom: 24),
      decoration: BoxDecoration(
        color: Colors.black.withOpacity(0.04),
        borderRadius: BorderRadius.circular(24),
        border: Border.all(color: Colors.black.withOpacity(0.05)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          ClipRRect(
            borderRadius: const BorderRadius.vertical(top: Radius.circular(24)),
            child: Stack(
              children: [
                Image.network(imageUrl, height: 180, width: double.infinity, fit: BoxFit.cover, 
                  errorBuilder: (context, error, stackTrace) => Container(height: 180, color: Colors.black.withOpacity(0.05), child: Center(child: Icon(LucideIcons.image, color: Colors.black.withOpacity(0.1))))),
                Positioned(
                  top: 15,
                  right: 15,
                  child: _Badge(text: '${progress.toInt()}% COMPLETE'),
                ),
              ],
            ),
          ),
          Padding(
            padding: const EdgeInsets.all(20),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Expanded(
                      child: Text(
                        update['title']?.toString().toUpperCase() ?? 'UPDATE', 
                        style: GoogleFonts.montserrat(fontSize: 13, fontWeight: FontWeight.w900, color: Colors.black),
                        overflow: TextOverflow.ellipsis,
                      ),
                    ),
                    const SizedBox(width: 8),
                    Text(update['date']?.toString() ?? '', style: GoogleFonts.montserrat(fontSize: 10, color: Colors.black.withOpacity(0.4))),
                  ],
                ),
                const SizedBox(height: 8),
                Text(update['description'] ?? '', style: GoogleFonts.montserrat(fontSize: 11, color: Colors.black.withOpacity(0.6), height: 1.5)),
                const SizedBox(height: 20),
                // Progress Bar
                Stack(
                  children: [
                    Container(
                      height: 4,
                      width: double.infinity,
                      decoration: BoxDecoration(color: Colors.black.withOpacity(0.05), borderRadius: BorderRadius.circular(2)),
                    ),
                    FractionallySizedBox(
                      widthFactor: progress / 100,
                      child: Container(
                        height: 4,
                        decoration: BoxDecoration(color: M4Theme.premiumBlue, borderRadius: BorderRadius.circular(2)),
                      ),
                    ),
                  ],
                ),
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
  final String type;
  final Function(String, String?) onLaunch;
  const _DocumentItem({required this.title, required this.size, required this.type, required this.onLaunch});

  @override
  Widget build(BuildContext context) {
    return _ScaleButton(
      onTap: () => onLaunch('Downloading Document...', null),
      child: Container(
        margin: const EdgeInsets.only(bottom: 12),
        padding: const EdgeInsets.all(16),
        decoration: BoxDecoration(
          color: Colors.white.withOpacity(0.6),
          borderRadius: BorderRadius.circular(16),
          border: Border.all(color: Colors.white.withOpacity(0.6)),
        ),
        child: Row(
          children: [
            Container(
              padding: const EdgeInsets.all(10),
              decoration: BoxDecoration(color: M4Theme.premiumBlue.withOpacity(0.05), borderRadius: BorderRadius.circular(10)),
              child: const Icon(LucideIcons.fileText, color: M4Theme.premiumBlue, size: 18),
            ),
            const SizedBox(width: 16),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(title.toUpperCase(), style: GoogleFonts.montserrat(fontSize: 11, fontWeight: FontWeight.w900, color: Colors.black)),
                  Text('$type • $size', style: GoogleFonts.montserrat(fontSize: 9, color: Colors.black.withOpacity(0.4), fontWeight: FontWeight.bold)),
                ],
              ),
            ),
            Icon(LucideIcons.download, color: Colors.black.withOpacity(0.24), size: 18),
          ],
        ),
      ),
    );
  }
}

class _SliverAppBarDelegate extends SliverPersistentHeaderDelegate {
  final TabBar tabBar;
  _SliverAppBarDelegate(this.tabBar);
  @override
  double get minExtent => tabBar.preferredSize.height;
  @override
  double get maxExtent => tabBar.preferredSize.height;
  @override
  Widget build(BuildContext context, double shrinkOffset, bool overlapsContent) {
    return Container(
      color: Colors.white,
      child: tabBar,
    );
  }
  @override
  bool shouldRebuild(_SliverAppBarDelegate oldDelegate) => false;
}

class _FilterChip extends StatelessWidget {
  final String label;
  final bool isActive;
  final VoidCallback onTap;

  const _FilterChip({required this.label, required this.isActive, required this.onTap});

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
        decoration: BoxDecoration(
          color: isActive ? M4Theme.premiumBlue : Colors.black.withOpacity(0.04),
          borderRadius: BorderRadius.circular(12),
          border: Border.all(color: isActive ? M4Theme.premiumBlue : Colors.black.withOpacity(0.05)),
        ),
        child: Text(
          label,
          style: GoogleFonts.montserrat(
            fontSize: 9,
            fontWeight: FontWeight.w900,
            color: isActive ? Colors.white : Colors.black.withOpacity(0.4),
            letterSpacing: 1.0,
          ),
        ),
      ).animate(target: isActive ? 1 : 0).scale(duration: 100.ms, end: const Offset(0.95, 0.95)),
    );
  }
}

class _TopIconButton extends StatelessWidget {
  final IconData icon;
  final VoidCallback onTap;
  final Color color;

  const _TopIconButton({required this.icon, required this.onTap, this.color = Colors.black});

  @override
  Widget build(BuildContext context) {
    return _ScaleButton(
      onTap: onTap,
      child: ClipRRect(
        borderRadius: BorderRadius.circular(15),
        child: BackdropFilter(
          filter: ImageFilter.blur(sigmaX: 10, sigmaY: 10),
          child: Container(
            padding: const EdgeInsets.all(12),
            decoration: BoxDecoration(
              color: Colors.white.withOpacity(0.8),
              borderRadius: BorderRadius.circular(15),
              border: Border.all(color: Colors.black.withOpacity(0.05)),
            ),
            child: Icon(icon, color: color, size: 20),
          ),
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

class _ScaleButtonState extends State<_ScaleButton> {
  bool _isPressed = false;

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTapDown: (_) => setState(() => _isPressed = true),
      onTapUp: (_) => setState(() => _isPressed = false),
      onTapCancel: () => setState(() => _isPressed = false),
      onTap: widget.onTap,
      child: AnimatedScale(
        scale: _isPressed ? 0.95 : 1.0,
        duration: const Duration(milliseconds: 100),
        child: widget.child,
      ),
    );
  }
}

class _SocialIconButton extends StatelessWidget {
  final IconData icon;
  final VoidCallback onTap;
  const _SocialIconButton({required this.icon, required this.onTap});

  @override
  Widget build(BuildContext context) {
    return _ScaleButton(
      onTap: onTap,
      child: Container(
        padding: const EdgeInsets.all(12),
        decoration: BoxDecoration(
          color: Colors.black.withOpacity(0.04),
          borderRadius: BorderRadius.circular(15),
          border: Border.all(color: Colors.black.withOpacity(0.05)),
        ),
        child: Icon(icon, color: Colors.black, size: 20),
      ),
    );
  }
}
