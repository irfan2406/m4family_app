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
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
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
                _buildInventory(project),
                _buildUpdates(project),
                _buildLocation(project),
                _buildPlanning(project),
                _buildMedia(project),
                _buildDocuments(project),
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
      backgroundColor: M4Theme.background,
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
                    Colors.black.withOpacity(0.4),
                    Colors.transparent,
                    M4Theme.background,
                  ],
                  stops: const [0.0, 0.5, 1.0],
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
                  const SizedBox(height: 24),
                  SingleChildScrollView(
                    scrollDirection: Axis.horizontal,
                    child: Row(
                      children: [
                        _HeaderStatCard(
                          label: 'COMPLETION', 
                          value: '${project?['completionPercentage'] ?? 0}%',
                          icon: LucideIcons.loader,
                        ),
                        const SizedBox(width: 12),
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
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Text(
                'THE RESIDENCE',
                style: GoogleFonts.montserrat(
                  fontSize: 10,
                  fontWeight: FontWeight.w900,
                  color: M4Theme.premiumBlue,
                  letterSpacing: 2,
                ),
              ),
              const _Badge(text: 'LIVE ESTATE', isOutline: true),
            ],
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
          GridView.count(
            shrinkWrap: true,
            physics: const NeverScrollableScrollPhysics(),
            crossAxisCount: 2,
            mainAxisSpacing: 16,
            crossAxisSpacing: 16,
            childAspectRatio: 2.2,
            children: [
              _OverviewActionCard(icon: LucideIcons.fileText, label: 'E-BROCHURE', onTap: () => _launchAction('Brochure not available yet', project?['brochureUrl'])),
              _OverviewActionCard(icon: LucideIcons.box, label: '3D VIEW', onTap: () => _launchAction('3D View coming soon', project?['view3dUrl'])),
              _OverviewActionCard(icon: LucideIcons.glasses, label: 'VR TOUR', onTap: () => _launchAction('VR Tour being prepared', project?['vrTourUrl'])),
              _OverviewActionCard(icon: LucideIcons.video, label: 'PROJECT FILM', onTap: () => _launchAction('Project Film in production', project?['videoUrl'])),
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
                        color: Colors.white.withOpacity(0.04),
                        borderRadius: BorderRadius.circular(20),
                        border: Border.all(color: Colors.white.withOpacity(0.05)),
                      ),
                      child: Icon(_getAmenityIcon(name), color: Colors.white, size: 24),
                    ),
                    const SizedBox(height: 10),
                    Text(
                      name.toUpperCase(),
                      textAlign: TextAlign.center,
                      style: GoogleFonts.montserrat(fontSize: 8, fontWeight: FontWeight.w700, color: Colors.white54, letterSpacing: 0.5),
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
            const _PaymentPlanCard(
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
            const Center(child: CircularProgressIndicator(color: Colors.white10))
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
            const Center(child: CircularProgressIndicator(color: Colors.white10))
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
              color: Colors.white.withOpacity(0.05),
              borderRadius: BorderRadius.circular(25),
              image: DecorationImage(
                image: NetworkImage(apiClient.resolveUrl(project?['locationMapUrl'] ?? 'https://images.unsplash.com/photo-1526778548025-fa2f459cd5ce?auto=format&fit=crop&q=80')),
                fit: BoxFit.cover,
                opacity: 0.4,
              ),
            ),
            child: const Center(child: Icon(LucideIcons.map, color: Colors.white24, size: 40)),
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
                          color: Colors.white10,
                          child: const Center(child: Icon(LucideIcons.image, color: Colors.white24)),
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
             const _DocumentItem(title: 'RERA Registration Certificate', size: '1.2 MB', type: 'LEGAL')
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
              _BottomIconAction(icon: LucideIcons.phone, onTap: () => SupportHandlers.launchCall(project?['phoneNumber'] ?? project?['phone'])),
              const SizedBox(width: 8),
              _BottomIconAction(icon: LucideIcons.messageSquare, onTap: () => SupportHandlers.launchWhatsApp(project?['phoneNumber'] ?? project?['phone'])),
              const SizedBox(width: 12),
              Expanded(
                child: GestureDetector(
                  onTap: () {
                    Navigator.pop(context);
                    _showInquiryDialog(project);
                  },
                  child: Container(
                    height: 56,
                    decoration: BoxDecoration(
                      gradient: LinearGradient(colors: [M4Theme.premiumBlue, Color(0xFF60A5FA)]),
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
    );
  }

  void _showInquiryDialog(dynamic project) {
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (context) => Container(
        padding: EdgeInsets.fromLTRB(24, 32, 24, MediaQuery.of(context).viewInsets.bottom + 32),
        decoration: const BoxDecoration(
          color: Color(0xFF0F1012),
          borderRadius: BorderRadius.only(topLeft: Radius.circular(30), topRight: Radius.circular(30)),
        ),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text('INTERESTED IN ${project?['title']?.toUpperCase() ?? 'PROJECT'}?', 
              style: GoogleFonts.montserrat(color: Colors.white, fontSize: 18, fontWeight: FontWeight.w900, letterSpacing: 1)),
            const SizedBox(height: 8),
            const Text('Share your details for a personalized presentation', style: TextStyle(color: Colors.white38, fontSize: 12)),
            const SizedBox(height: 24),
            TextFormField(
              decoration: InputDecoration(
                labelText: 'Full Name',
                labelStyle: const TextStyle(color: Colors.white38),
                filled: true,
                fillColor: Colors.white.withOpacity(0.03),
                border: OutlineInputBorder(borderRadius: BorderRadius.circular(15), borderSide: BorderSide.none),
              ),
              style: const TextStyle(color: Colors.white),
            ),
            const SizedBox(height: 16),
            TextFormField(
              decoration: InputDecoration(
                labelText: 'Phone Number',
                labelStyle: const TextStyle(color: Colors.white38),
                filled: true,
                fillColor: Colors.white.withOpacity(0.03),
                border: OutlineInputBorder(borderRadius: BorderRadius.circular(15), borderSide: BorderSide.none),
              ),
              style: const TextStyle(color: Colors.white),
            ),
            const SizedBox(height: 24),
            SizedBox(
              width: double.infinity,
              height: 56,
              child: ElevatedButton(
                onPressed: () {
                  Navigator.pop(context);
                  _launchAction('Thank you! Our advisor will call you shortly.');
                },
                style: ElevatedButton.styleFrom(
                  backgroundColor: M4Theme.premiumBlue,
                  shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(15)),
                ),
                child: const Text('SUBMIT ENQUIRY', style: TextStyle(fontWeight: FontWeight.bold, letterSpacing: 2)),
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
          color: isAction ? M4Theme.premiumBlue.withOpacity(0.1) : Colors.white.withOpacity(0.05),
          borderRadius: BorderRadius.circular(15),
          border: Border.all(color: isAction ? M4Theme.premiumBlue.withOpacity(0.3) : Colors.white.withOpacity(0.05)),
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Icon(icon, color: isAction ? M4Theme.premiumBlue : Colors.white38, size: 10),
                const SizedBox(width: 6),
                Text(label, style: GoogleFonts.montserrat(color: Colors.white38, fontSize: 8, fontWeight: FontWeight.bold, letterSpacing: 0.5)),
              ],
            ),
            const SizedBox(height: 4),
            Text(value, style: GoogleFonts.montserrat(color: Colors.white, fontSize: 13, fontWeight: FontWeight.w900, letterSpacing: 0.5)),
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
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
      decoration: BoxDecoration(
        color: isOutline ? Colors.transparent : Colors.white,
        borderRadius: BorderRadius.circular(10),
        border: isOutline ? Border.all(color: Colors.white30) : null,
      ),
      child: Text(text, style: GoogleFonts.montserrat(fontSize: 8, fontWeight: FontWeight.w900, color: isOutline ? Colors.white70 : Colors.black, letterSpacing: 1)),
    );
  }
}

class _OverviewActionCard extends StatelessWidget {
  final IconData icon;
  final String label;
  final VoidCallback onTap;
  const _OverviewActionCard({required this.icon, required this.label, required this.onTap});

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
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
            Text(label, style: GoogleFonts.montserrat(color: Colors.white, fontSize: 9, fontWeight: FontWeight.w800, letterSpacing: 1)),
          ],
        ),
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
        color: Colors.white.withOpacity(0.03),
        borderRadius: BorderRadius.circular(25),
        border: Border.all(color: Colors.white.withOpacity(0.05)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Text(plan['name']?.toUpperCase() ?? 'PAYMENT PLAN', style: GoogleFonts.montserrat(color: Colors.white, fontSize: 14, fontWeight: FontWeight.bold)),
              _Badge(text: plan['status'] ?? 'ACTIVE', isOutline: true),
            ],
          ),
          const SizedBox(height: 24),
          ...steps.map((step) => Padding(
            padding: const EdgeInsets.only(bottom: 12),
            child: Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Text(step['label'] ?? 'Step', style: const TextStyle(color: Colors.white38, fontSize: 12)),
                Text(step['value'] ?? '0%', style: GoogleFonts.montserrat(color: Colors.white, fontSize: 13, fontWeight: FontWeight.bold)),
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
    final config = unit['config'] ?? 'Unit';
    final area = unit['area'] != null ? '${unit['area']} Sq.Ft.' : 'N/A';
    final price = unit['price'] != null ? '₹ ${unit['price']}' : 'Contact Us';

    return Container(
      margin: const EdgeInsets.only(bottom: 16),
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: Colors.white.withOpacity(0.03),
        borderRadius: BorderRadius.circular(20),
        border: Border.all(color: Colors.white.withOpacity(0.05)),
      ),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(config, style: const TextStyle(color: Colors.white, fontWeight: FontWeight.bold)),
              Text(area, style: const TextStyle(color: Colors.white38, fontSize: 12)),
            ],
          ),
          Text(price, style: GoogleFonts.montserrat(color: M4Theme.premiumBlue, fontWeight: FontWeight.w900)),
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
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          ClipRRect(
            borderRadius: BorderRadius.circular(20),
            child: Image.network(imageUrl, height: 200, width: double.infinity, fit: BoxFit.cover,
              errorBuilder: (_,__,___) => Container(color: Colors.white10, height: 200, width: double.infinity, child: const Center(child: Icon(LucideIcons.image, color: Colors.white24)))),
          ),
          const SizedBox(height: 16),
          Text(update['date'] ?? 'March 2024', style: GoogleFonts.montserrat(color: M4Theme.premiumBlue, fontSize: 10, fontWeight: FontWeight.bold, letterSpacing: 1)),
          const SizedBox(height: 8),
          Text(update['title'] ?? 'Title', style: GoogleFonts.montserrat(color: Colors.white, fontSize: 18, fontWeight: FontWeight.w900)),
          const SizedBox(height: 8),
          Text(update['content'] ?? '', style: const TextStyle(color: Colors.white54, fontSize: 13, height: 1.5)),
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
      margin: const EdgeInsets.only(bottom: 24),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          ClipRRect(
            borderRadius: BorderRadius.circular(20),
            child: Image.network(imageUrl, height: 300, width: double.infinity, fit: BoxFit.contain,
              errorBuilder: (_,__,___) => Container(color: Colors.white10, height: 300, width: double.infinity, child: const Center(child: Icon(LucideIcons.layout, color: Colors.white24)))),
          ),
          const SizedBox(height: 16),
          Text(plan['title']?.toString() ?? 'Floor Plan', style: GoogleFonts.montserrat(color: Colors.white, fontSize: 16, fontWeight: FontWeight.bold)),
          Text(plan['area']?.toString() ?? '', style: const TextStyle(color: Colors.white38, fontSize: 12)),
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
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: Colors.white.withOpacity(0.03),
        borderRadius: BorderRadius.circular(20),
        border: Border.all(color: Colors.white.withOpacity(0.05)),
      ),
      child: Row(
        children: [
          Container(
            padding: const EdgeInsets.all(12),
            decoration: BoxDecoration(color: M4Theme.premiumBlue.withOpacity(0.1), borderRadius: BorderRadius.circular(12)),
            child: const Icon(LucideIcons.fileText, color: M4Theme.premiumBlue, size: 20),
          ),
          const SizedBox(width: 20),
          Expanded(
            child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
              Text(title, style: const TextStyle(color: Colors.white, fontWeight: FontWeight.bold, fontSize: 13)),
              const SizedBox(height: 4),
              Text('$type • $size', style: const TextStyle(color: Colors.white38, fontSize: 10)),
            ]),
          ),
          const Icon(LucideIcons.download, color: Colors.white24, size: 20),
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
        decoration: BoxDecoration(color: Colors.white.withOpacity(0.05), borderRadius: BorderRadius.circular(20), border: Border.all(color: Colors.white.withOpacity(0.05))),
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
    return Text(title, style: GoogleFonts.montserrat(fontSize: 10, fontWeight: FontWeight.w900, color: M4Theme.premiumBlue, letterSpacing: 2));
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
          const SizedBox(height: 40),
          Icon(LucideIcons.info, color: Colors.white.withOpacity(0.05), size: 48),
          const SizedBox(height: 16),
          Text(message, textAlign: TextAlign.center, style: const TextStyle(color: Colors.white24, fontSize: 12)),
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
          Icon(icon, color: Colors.white38, size: 16),
          const SizedBox(width: 16),
          Expanded(child: Text(title, style: const TextStyle(color: Colors.white, fontSize: 13))),
          Text(distance, style: GoogleFonts.montserrat(color: M4Theme.premiumBlue, fontSize: 11, fontWeight: FontWeight.bold)),
        ],
      ),
    );
  }
}

class _SliverAppBarDelegate extends SliverPersistentHeaderDelegate {
  final TabBar _tabBar;
  _SliverAppBarDelegate(this._tabBar);
  @override
  double get minExtent => _tabBar.preferredSize.height;
  @override
  double get maxExtent => _tabBar.preferredSize.height;
  @override
  Widget build(BuildContext context, double shrinkOffset, bool overlapsContent) {
    return ClipRRect(
      child: BackdropFilter(
        filter: ImageFilter.blur(sigmaX: 10, sigmaY: 10),
        child: Container(color: M4Theme.background.withOpacity(0.8), child: _tabBar),
      ),
    );
  }
  @override
  bool shouldRebuild(_SliverAppBarDelegate oldDelegate) => false;
}
