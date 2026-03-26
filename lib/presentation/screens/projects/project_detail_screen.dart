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

  final List<String> _tabs = [
    'OVERVIEW',
    'LOCATION',
    'AMENITIES',
    'PLANS',
    'MEDIA',
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
                _buildLocation(project),
                _buildAmenities(project),
                _buildPlanning(project), // Planning is Plans in Web
                _buildMedia(project),
              ],
            ),
          ),
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
                      color: Colors.white.withOpacity(0.8),
                      borderRadius: BorderRadius.circular(15),
                      border: Border.all(color: Colors.black.withOpacity(0.05)),
                    ),
                    child: const Icon(LucideIcons.chevronLeft, color: Colors.black, size: 20),
                  ),
                ),
              ),
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
            Image.network(apiClient.resolveUrl(heroImage), fit: BoxFit.cover),
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
                    style: GoogleFonts.montserrat(
                      fontSize: 32,
                      fontWeight: FontWeight.w900,
                      color: Colors.black,
                      height: 1.1,
                      letterSpacing: -0.5,
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
                      Text('E-BROCHURE', style: GoogleFonts.montserrat(fontSize: 10, fontWeight: FontWeight.w900, color: Colors.white, letterSpacing: 1)),
                      Text('PDF • 4.2 MB', style: GoogleFonts.montserrat(fontSize: 8, fontWeight: FontWeight.bold, color: Colors.white54)),
                    ],
                  ),
                ),
                ElevatedButton(
                  onPressed: () => _launchAction('Brochure not available yet', project?['brochureUrl']),
                  style: ElevatedButton.styleFrom(
                    backgroundColor: Colors.black.withOpacity(0.05),
                    foregroundColor: Colors.black,
                    side: BorderSide(color: Colors.black.withOpacity(0.05)),
                    shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
                    elevation: 0,
                    padding: const EdgeInsets.symmetric(horizontal: 16),
                  ),
                  child: Text('DOWNLOAD', style: GoogleFonts.montserrat(fontSize: 9, fontWeight: FontWeight.bold, letterSpacing: 1)),
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
              _OverviewPremiumCard(
                icon: LucideIcons.box, 
                title: '3D VIEW', 
                subtitle: 'Interactive Model',
                onTap: () => _launchAction('3D View coming soon', project?['view3dUrl'])
              ),
              _OverviewPremiumCard(
                icon: LucideIcons.glasses, 
                title: 'VR TOUR', 
                subtitle: 'Immersive Experience',
                onTap: () => _launchAction('VR Tour being prepared', project?['vrTourUrl'])
              ),
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
          if (project?['paymentPlans'] != null)
             ...((project?['paymentPlans'] as List).map((plan) => _PaymentPlanCard(plan: plan)).toList())
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
          _SectionHeader(title: 'AVAILABLE INVENTORY'),
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
            child: Icon(LucideIcons.map, color: Theme.of(context).colorScheme.onSurface.withOpacity(0.24), size: 40),
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

    return _buildTabContent(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          _SectionHeader(title: 'PROJECT GALLERY'),
          const SizedBox(height: 24),
          if (uniqueGallery.isEmpty)
            const _EmptyTabContent(message: 'New photos and videos coming soon')
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
              itemCount: uniqueGallery.length,
              itemBuilder: (context, index) {
                return Stack(
                  children: [
                    ClipRRect(
                      borderRadius: BorderRadius.circular(20),
                      child: Image.network(
                        apiClient.resolveUrl(uniqueGallery[index]), 
                        fit: BoxFit.cover, height: double.infinity, width: double.infinity,
                        errorBuilder: (context, error, stackTrace) => Container(
                          color: Theme.of(context).colorScheme.onSurface.withOpacity(0.1),
                          child: Center(child: Icon(LucideIcons.image, color: Theme.of(context).colorScheme.onSurface.withOpacity(0.24))),
                        ),
                      ),
                    ),
                    const Positioned(top: 10, left: 10, child: _Badge(text: 'IMAGE', isOutline: true)),
                  ],
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
              _DocumentItem(title: 'RERA Registration Certificate', size: '1.2 MB', type: 'LEGAL')
          else
            ...docs.map((doc) => _DocumentItem(
              title: doc['name'] ?? 'Document', 
              size: doc['size'] ?? 'N/A',
              type: doc['type'] ?? 'GENERAL',
            )).toList(),
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
                  child: GestureDetector(
                    onTap: () => _showInquiryDialog(project),
                    child: Container(
                      height: 56,
                      decoration: BoxDecoration(
                        color: Colors.white,
                        borderRadius: BorderRadius.circular(20),
                      ),
                      child: Center(
                        child: Text(
                          'INQUIRE NOW',
                          style: GoogleFonts.montserrat(color: Colors.black, fontWeight: FontWeight.w900, fontSize: 13, letterSpacing: 2),
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

  void _showInquiryDialog(dynamic project) {
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (context) => Container(
        padding: EdgeInsets.fromLTRB(24, 32, 24, MediaQuery.of(context).viewInsets.bottom + 32),
        decoration: BoxDecoration(
          color: Theme.of(context).colorScheme.surface,
          borderRadius: const BorderRadius.only(topLeft: Radius.circular(30), topRight: Radius.circular(30)),
        ),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text('INTERESTED IN ${project?['title']?.toUpperCase() ?? 'PROJECT'}?', 
              style: GoogleFonts.montserrat(color: Theme.of(context).colorScheme.onSurface, fontSize: 18, fontWeight: FontWeight.w900, letterSpacing: 1)),
            const SizedBox(height: 8),
            Text('Share your details for a personalized presentation', style: TextStyle(color: Theme.of(context).colorScheme.onSurface.withOpacity(0.38), fontSize: 12)),
            const SizedBox(height: 24),
            TextFormField(
              controller: _nameController,
              decoration: InputDecoration(
                labelText: 'Full Name',
                labelStyle: TextStyle(color: Theme.of(context).colorScheme.onSurface.withOpacity(0.38)),
                filled: true,
                fillColor: Theme.of(context).colorScheme.onSurface.withOpacity(0.03),
                border: OutlineInputBorder(borderRadius: BorderRadius.circular(15), borderSide: BorderSide.none),
              ),
              style: TextStyle(color: Theme.of(context).colorScheme.onSurface),
            ),
            const SizedBox(height: 16),
            TextFormField(
              controller: _phoneController,
              decoration: InputDecoration(
                labelText: 'Phone Number',
                labelStyle: TextStyle(color: Theme.of(context).colorScheme.onSurface.withOpacity(0.38)),
                filled: true,
                fillColor: Theme.of(context).colorScheme.onSurface.withOpacity(0.03),
                border: OutlineInputBorder(borderRadius: BorderRadius.circular(15), borderSide: BorderSide.none),
              ),
              style: TextStyle(color: Theme.of(context).colorScheme.onSurface),
            ),
            const SizedBox(height: 24),
            SizedBox(
              width: double.infinity,
              height: 56,
              child: ElevatedButton(
                onPressed: () async {
                  final name = _nameController.text;
                  final phone = _phoneController.text;
                  
                  if (name.isEmpty || phone.isEmpty) {
                    _launchAction('Please fill in all details');
                    return;
                  }

                  try {
                    await ref.read(apiClientProvider).submitLead({
                      'name': name,
                      'phone': phone,
                      'project': project?['title'] ?? 'General Inquiry',
                      'projectId': widget.projectId,
                      'source': 'Mobile App'
                    });
                    
                    if (mounted) {
                      Navigator.pop(context);
                      _nameController.clear();
                      _phoneController.clear();
                      _launchAction('Enquiry submitted successfully!');
                    }
                  } catch (e) {
                    _launchAction('Failed to submit enquiry. Please try again.');
                  }
                },
                style: ElevatedButton.styleFrom(
                  backgroundColor: M4Theme.premiumBlue,
                  shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(15)),
                ),
                child: Text('SUBMIT ENQUIRY', style: GoogleFonts.montserrat(color: Theme.of(context).colorScheme.onPrimary, fontWeight: FontWeight.bold, letterSpacing: 2)),
              ),
            ),
          ],
        ),
      ),
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
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
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
  const _FloorPlanItem({required this.plan, required this.imageUrl});
  @override
  Widget build(BuildContext context) {
    return Container(
       margin: const EdgeInsets.only(bottom: 16),
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(color: Colors.black.withOpacity(0.04), borderRadius: BorderRadius.circular(24), border: Border.all(color: Colors.black.withOpacity(0.05))),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          ClipRRect(borderRadius: BorderRadius.circular(16), child: Image.network(imageUrl, fit: BoxFit.cover, height: 200, width: double.infinity)),
          const SizedBox(height: 16),
          Text(plan['title'] ?? 'Floor Plan', style: GoogleFonts.montserrat(fontSize: 14, fontWeight: FontWeight.bold, color: Colors.black)),
          Text(plan['area'] ?? '', style: GoogleFonts.montserrat(fontSize: 12, color: Colors.black.withOpacity(0.4))),
        ],
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
  const _PricingCard({required this.config, required this.price, required this.area});

  @override
  Widget build(BuildContext context) {
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
              Text(config.toUpperCase(), style: GoogleFonts.montserrat(fontSize: 14, fontWeight: FontWeight.w900, color: Colors.black)),
              const _Badge(text: 'BOOKING OPEN'),
            ],
          ),
          const SizedBox(height: 12),
          Divider(color: Colors.black.withOpacity(0.05)),
          const SizedBox(height: 12),
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text('STARTING FROM', style: GoogleFonts.montserrat(fontSize: 8, fontWeight: FontWeight.bold, color: Colors.black.withOpacity(0.38), letterSpacing: 1)),
                  Text(price, style: GoogleFonts.montserrat(fontSize: 20, fontWeight: FontWeight.w900, color: M4Theme.premiumBlue)),
                ],
              ),
              Column(
                crossAxisAlignment: CrossAxisAlignment.end,
                children: [
                  Text('SBA RANGE', style: GoogleFonts.montserrat(fontSize: 8, fontWeight: FontWeight.bold, color: Colors.black.withOpacity(0.38), letterSpacing: 1)),
                  Text(area, style: GoogleFonts.montserrat(fontSize: 12, fontWeight: FontWeight.bold, color: Colors.black.withOpacity(0.7))),
                ],
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
  const _PaymentPlanCard({required this.plan});

  @override
  Widget build(BuildContext context) {
    final steps = plan['steps'] as List? ?? [];
    return Container(
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
          ...steps.map((step) => Padding(
            padding: const EdgeInsets.only(bottom: 12),
            child: Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Text(step['label']?.toString() ?? '', style: GoogleFonts.montserrat(fontSize: 11, color: Colors.black.withOpacity(0.4))),
                Text(step['value']?.toString() ?? '', style: GoogleFonts.montserrat(fontSize: 11, fontWeight: FontWeight.bold, color: Colors.black)),
              ],
            ),
          )).toList(),
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
      margin: const EdgeInsets.only(bottom: 16),
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: Colors.white.withOpacity(0.6),
        borderRadius: BorderRadius.circular(20),
        border: Border.all(color: Colors.white.withOpacity(0.6)),
      ),
      child: Row(
        children: [
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text('UNIT ${unit['unitNumber']}', style: GoogleFonts.montserrat(fontSize: 14, fontWeight: FontWeight.w900, color: Colors.black)),
                Text('${unit['type']} • ${unit['area']} SQFT', style: GoogleFonts.montserrat(fontSize: 11, color: Colors.black.withOpacity(0.38))),
              ],
            ),
          ),
          Column(
            crossAxisAlignment: CrossAxisAlignment.end,
            children: [
              Text('₹ ${unit['price']}', style: GoogleFonts.montserrat(fontSize: 14, fontWeight: FontWeight.w900, color: M4Theme.premiumBlue)),
              Text('EXCL. TAXES', style: TextStyle(fontSize: 8, color: Colors.black.withOpacity(0.24), fontWeight: FontWeight.bold)),
            ],
          ),
        ],
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
            child: Image.network(imageUrl, height: 180, width: double.infinity, fit: BoxFit.cover, 
              errorBuilder: (context, error, stackTrace) => Container(height: 180, color: Colors.black.withOpacity(0.05), child: Center(child: Icon(LucideIcons.image, color: Colors.black.withOpacity(0.1))))),
          ),
          Padding(
            padding: const EdgeInsets.all(20),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Text(update['title']?.toString().toUpperCase() ?? 'UPDATE', style: GoogleFonts.montserrat(fontSize: 13, fontWeight: FontWeight.w900, color: Colors.black)),
                    Text(update['date']?.toString() ?? '', style: GoogleFonts.montserrat(fontSize: 10, color: Colors.black.withOpacity(0.4))),
                  ],
                ),
                const SizedBox(height: 8),
                Text(update['description'] ?? '', style: GoogleFonts.montserrat(fontSize: 11, color: Colors.black.withOpacity(0.6), height: 1.5)),
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
  const _DocumentItem({required this.title, required this.size, required this.type});

  @override
  Widget build(BuildContext context) {
    return Container(
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
