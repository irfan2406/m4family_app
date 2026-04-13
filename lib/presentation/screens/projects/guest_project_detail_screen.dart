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

class GuestProjectDetailScreen extends ConsumerStatefulWidget {
  final dynamic projectData; 
  final String projectId;

  const GuestProjectDetailScreen({
    super.key, 
    required this.projectId,
    this.projectData,
  });

  @override
  ConsumerState<GuestProjectDetailScreen> createState() => _GuestProjectDetailScreenState();
}

class _GuestProjectDetailScreenState extends ConsumerState<GuestProjectDetailScreen> with SingleTickerProviderStateMixin {

  dynamic _fullProject;
  List<dynamic> _updates = [];
  List<dynamic> _inventory = [];
  List<dynamic> _progressPhases = [];
  bool _isLoading = true;
  final TextEditingController _nameController = TextEditingController();
  final TextEditingController _phoneController = TextEditingController();
  final TextEditingController _emailController = TextEditingController();
  bool _isFavorited = false;
  String _mediaFilter = 'ALL';
  String _selectedConfig = '3 BHK';


  @override
  void initState() {
    super.initState();
    _fetchProjectData();
  }

  Future<void> _fetchProjectData() async {
    try {
      final apiClient = ref.read(apiClientProvider);
      
      final results = await Future.wait<Response<dynamic>>([
        apiClient.getProjectDetails(widget.projectId),
        apiClient.getProjectUpdates(widget.projectId),
        apiClient.getProjectInventory(widget.projectId),
        apiClient.getProjectProgress(widget.projectId),
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
           if (results[3].data['status'] == true) {
            _progressPhases = results[3].data['data'] ?? [];
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
      if (url.startsWith('tel:')) {
        await SupportHandlers.launchCall(url.replaceFirst('tel:', ''));
        return;
      }
      if (url.startsWith('mailto:')) {
        await SupportHandlers.launchEmail(url.replaceFirst('mailto:', ''));
        return;
      }
      
      final apiClient = ref.read(apiClientProvider);
      final resolvedUrl = apiClient.resolveUrl(url);
      final uri = Uri.parse(resolvedUrl);

      if (await canLaunchUrl(uri)) {
        await launchUrl(
          uri, 
          mode: resolvedUrl.startsWith('http') ? LaunchMode.inAppBrowserView : LaunchMode.platformDefault
        );
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
    _nameController.dispose();
    _phoneController.dispose();
    _emailController.dispose();
    super.dispose();
  }

  Future<void> _submitInquiry(String type, [String? plan]) async {
    final name = _nameController.text.trim();
    final phone = _phoneController.text.trim();
    if (name.isEmpty || phone.isEmpty) {
      _launchAction('Please enter your name and phone number', null);
      return;
    }

    setState(() => _isLoading = true);
    try {
      final apiClient = ref.read(apiClientProvider);
      final project = _fullProject ?? widget.projectData;
      
      final res = await apiClient.submitLead({
        'name': name,
        'phone': phone,
        'email': _emailController.text.trim().isNotEmpty ? _emailController.text.trim() : null,
        'interest': type == 'VC' ? 'Video Call' : type == 'Site Visit' ? 'Site Visit' : 'Buying',
        'configuration': _selectedConfig,
        'source': 'mobile_app',
        'projectId': widget.projectId,
        'project': project?['title'] ?? 'General',
        'message': plan != null 
            ? 'Inquiry about payment plan: $plan for project ${project?['title']}' 
            : '${type == 'VC' ? 'Video Call' : type == 'Site Visit' ? 'Site Visit' : 'General'} request for project ${project?['title']}',
      });

      if (res.data['status'] == true) {
        if (mounted) {
          Navigator.pop(context);
          _launchAction(type == 'General' ? 'Inquiry submitted! Our advisor will contact you shortly.' : 'Booking request received! Our team will call you to confirm the time.', null);
        }
      } else {
        _launchAction(res.data['message'] ?? 'Failed to submit inquiry', null);
      }
    } catch (e) {
      _launchAction('Connection error. Please try again.', null);
    } finally {
      if (mounted) setState(() => _isLoading = false);
    }
  }

  void _showRequestDetailsDialog(dynamic project, [dynamic plan, String type = 'General']) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final planName = plan is Map ? plan['name']?.toString() : plan?.toString();
    final projectTitle = project?['title'] ?? 'this project';

    // Prefill auth user data if available
    final authUser = ref.read(authProvider).user;
    if (authUser != null) {
      _nameController.text = authUser['fullName']?.toString() ?? authUser['username']?.toString() ?? '';
      _phoneController.text = authUser['phone']?.toString() ?? '';
      _emailController.text = authUser['email']?.toString() ?? '';
    }

    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (context) => StatefulBuilder(
        builder: (context, setModalState) => Container(
          padding: EdgeInsets.only(bottom: MediaQuery.of(context).viewInsets.bottom),
          decoration: BoxDecoration(
            color: isDark ? const Color(0xFF0F1115) : Colors.white,
            borderRadius: const BorderRadius.vertical(top: Radius.circular(40)),
            border: Border.all(color: isDark ? Colors.white.withValues(alpha: 0.1) : Colors.black.withValues(alpha: 0.1), width: 0.5),
            boxShadow: isDark ? [] : [BoxShadow(color: Colors.black.withValues(alpha: 0.1), blurRadius: 20, offset: const Offset(0, -5))],
          ),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              const SizedBox(height: 12),
              Container(width: 40, height: 4, decoration: BoxDecoration(color: isDark ? Colors.white24 : Colors.black12, borderRadius: BorderRadius.circular(2))),
              const SizedBox(height: 8),
              Align(
                alignment: Alignment.topRight,
                child: IconButton(
                  onPressed: () => Navigator.pop(context),
                  icon: Icon(LucideIcons.x, color: isDark ? Colors.white38 : Colors.black38, size: 20),
                  padding: const EdgeInsets.symmetric(horizontal: 24),
                ),
              ),
              Padding(
                padding: const EdgeInsets.symmetric(horizontal: 32),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                     Text(
                      type == 'VC' ? 'BOOK A VIDEO CALL' : type == 'Site Visit' ? 'BOOK A SITE VISIT' : 'REQUEST DETAILS',
                      style: GoogleFonts.montserrat(fontSize: 18, fontWeight: FontWeight.w900, color: isDark ? Colors.white : Colors.black, letterSpacing: -0.5),
                    ),
                    const SizedBox(height: 4),
                    Text(
                      'INQUIRY FOR ${projectTitle.toUpperCase()}',
                      style: GoogleFonts.montserrat(fontSize: 9, color: isDark ? Colors.white38 : Colors.black38, fontWeight: FontWeight.w900, letterSpacing: 1),
                    ),
                    const SizedBox(height: 32),
                    
                    Text('PREFERRED CONFIGURATION *', style: GoogleFonts.montserrat(fontSize: 8, fontWeight: FontWeight.w900, color: isDark ? Colors.white38 : Colors.black38, letterSpacing: 1)),
                    const SizedBox(height: 12),
                    Wrap(
                      spacing: 8,
                      runSpacing: 8,
                      children: ["1 BHK", "2 BHK", "3 BHK", "4 BHK", "Penthouse"].map((config) {
                        final isActive = _selectedConfig == config;
                        return GestureDetector(
                          onTap: () => setModalState(() => _selectedConfig = config),
                          child: Container(
                            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 10),
                            decoration: BoxDecoration(
                              color: isActive 
                                ? (isDark ? Colors.white : Colors.black) 
                                : (isDark ? Colors.white.withValues(alpha: 0.03) : Colors.black.withValues(alpha: 0.04)),
                              borderRadius: BorderRadius.circular(10),
                              border: Border.all(color: isActive ? (isDark ? Colors.white : Colors.black) : (isDark ? Colors.white.withValues(alpha: 0.1) : Colors.black.withValues(alpha: 0.05))),
                            ),
                            child: Text(
                              config, 
                              style: GoogleFonts.montserrat(
                                fontSize: 8, 
                                fontWeight: FontWeight.w900, 
                                color: isActive ? (isDark ? Colors.black : Colors.white) : (isDark ? Colors.white38 : Colors.black38)
                              ),
                            ),
                          ),
                        );
                      }).toList(),
                    ),
                    
                    const SizedBox(height: 24),
                    _buildInquiryField('FULL NAME *', _nameController, LucideIcons.user),
                    const SizedBox(height: 16),
                    _buildInquiryField('PHONE NUMBER *', _phoneController, LucideIcons.phone),
                    const SizedBox(height: 16),
                    _buildInquiryField('EMAIL (OPTIONAL)', _emailController, LucideIcons.mail),
                    
                    const SizedBox(height: 32),
                    _ScaleButton(
                      onTap: () => _submitInquiry(type, planName),
                      child: Container(
                        width: double.infinity,
                        padding: const EdgeInsets.symmetric(vertical: 20),
                        decoration: BoxDecoration(
                          color: isDark ? Colors.white : Colors.black,
                          borderRadius: BorderRadius.circular(20),
                          boxShadow: [
                            BoxShadow(
                              color: (isDark ? Colors.white : Colors.black).withValues(alpha: 0.1), 
                              blurRadius: 20, 
                              offset: const Offset(0, 10)
                            )
                          ],
                        ),
                        child: Row(
                          mainAxisAlignment: MainAxisAlignment.center,
                          children: [
                            Text(
                              'SUBMIT INQUIRY',
                              style: GoogleFonts.montserrat(fontSize: 10, fontWeight: FontWeight.w900, color: isDark ? Colors.black : Colors.white, letterSpacing: 1),
                            ),
                            const SizedBox(width: 8),
                            Icon(LucideIcons.arrowUpRight, color: isDark ? Colors.black : Colors.white, size: 14),
                          ],
                        ),
                      ),
                    ),
                    const SizedBox(height: 24),
                    Center(
                      child: Text(
                        'OUR ADVISOR WILL CONTACT YOU WITHIN 24 HOURS',
                        style: GoogleFonts.montserrat(fontSize: 7, color: isDark ? Colors.white24 : Colors.black26, fontWeight: FontWeight.w900, letterSpacing: 1),
                      ),
                    ),
                    const SizedBox(height: 32),
                  ],
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildInquiryField(String label, TextEditingController controller, IconData icon) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(label, style: GoogleFonts.montserrat(fontSize: 8, fontWeight: FontWeight.w900, color: isDark ? Colors.white38 : Colors.black38, letterSpacing: 1)),
        const SizedBox(height: 10),
        Container(
          padding: const EdgeInsets.symmetric(horizontal: 20),
          decoration: BoxDecoration(
            color: isDark ? Colors.white.withValues(alpha: 0.03) : Colors.black.withValues(alpha: 0.04),
            borderRadius: BorderRadius.circular(16),
            border: Border.all(color: isDark ? Colors.white.withValues(alpha: 0.05) : Colors.black.withValues(alpha: 0.05)),
          ),
          child: TextField(
            controller: controller,
            style: GoogleFonts.montserrat(fontSize: 13, fontWeight: FontWeight.bold, color: isDark ? Colors.white : Colors.black),
            decoration: InputDecoration(
              border: InputBorder.none,
              icon: Icon(icon, color: isDark ? Colors.white24 : Colors.black26, size: 16),
              contentPadding: const EdgeInsets.symmetric(vertical: 16),
            ),
          ),
        ),
      ],
    );
  }

  void _openHeroGallery(dynamic project, String category) {
    final List<dynamic> media = project?['media'] as List? ?? [];
    final List<String> list = [];
    
    if (category == 'EXTERIOR') {
      list.addAll((project?['exteriorImages'] as List?)?.cast<String>() ?? []);
      list.addAll(media.where((m) => m['category']?.toString().toUpperCase() == 'EXTERIOR').map((m) => m['url']?.toString() ?? '').where((u) => u.isNotEmpty));
    } else if (category == 'INTERIOR') {
      list.addAll((project?['interiorImages'] as List?)?.cast<String>() ?? []);
      list.addAll(media.where((m) => m['category']?.toString().toUpperCase() == 'INTERIOR').map((m) => m['url']?.toString() ?? '').where((u) => u.isNotEmpty));
    }

    if (list.isNotEmpty) {
      _showMediaLightbox(list[0], 'IMAGE');
    } else {
      _launchAction('Gallery coming soon!', null);
    }
  }

  void _showMediaLightbox(String url, String type) {
    final apiClient = ref.read(apiClientProvider);
    showGeneralDialog(
      context: context,
      barrierDismissible: true,
      barrierLabel: 'Lightbox',
      barrierColor: Colors.black.withValues(alpha: 0.9),
      transitionDuration: const Duration(milliseconds: 300),
      pageBuilder: (context, anim1, anim2) {
        return Scaffold(
          backgroundColor: Colors.transparent,
          body: Stack(
            fit: StackFit.expand,
            children: [
              Center(
                child: InteractiveViewer(
                  child: Image.network(
                    apiClient.resolveUrl(url),
                    fit: BoxFit.contain,
                    errorBuilder: (context, error, stackTrace) => const Icon(LucideIcons.image, color: Colors.white24, size: 50),
                  ),
                ),
              ),
              Positioned(
                top: MediaQuery.of(context).padding.top + 20,
                right: 20,
                child: IconButton(
                  icon: const Icon(LucideIcons.x, color: Colors.white),
                  onPressed: () => Navigator.pop(context),
                ),
              ),
              if (type == 'VIDEO')
                const Center(child: Icon(LucideIcons.playCircle, color: Colors.white, size: 60)),
            ],
          ),
        );
      },
    );
  }

  @override
  Widget build(BuildContext context) {
    final project = _fullProject ?? widget.projectData;
    final isDark = Theme.of(context).brightness == Brightness.dark;

    if (_isLoading && project == null) {
      return Scaffold(
        backgroundColor: isDark ? Colors.black : Colors.white,
        body: Center(
          child: CircularProgressIndicator(color: M4Theme.premiumBlue),
        ),
      );
    }

    return Scaffold(
      backgroundColor: isDark ? Colors.black : Colors.white,
      body: Stack(
        children: [
          SingleChildScrollView(
            physics: const BouncingScrollPhysics(),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                _buildHero(project, isDark),
                const SizedBox(height: 12),
                GridView.count(
                  padding: const EdgeInsets.symmetric(horizontal: 24),
                  shrinkWrap: true,
                  physics: const NeverScrollableScrollPhysics(),
                  crossAxisCount: 2,
                  mainAxisSpacing: 16,
                  crossAxisSpacing: 16,
                  childAspectRatio: 1.1,
                  children: [
                    _OverviewActionCard(label: 'VIDEO CALL', value: 'Connect Now', icon: LucideIcons.video, isAction: true, onTap: () => _showRequestDetailsDialog(project, null, 'VC')),
                    _OverviewActionCard(label: 'COMPLETION', value: '${project?['completion'] ?? 0}%', icon: LucideIcons.checkCircle2),
                    _OverviewActionCard(label: 'COLLECTION', value: project?['units']?.toString() ?? '40', icon: LucideIcons.layoutGrid),
                    _OverviewActionCard(label: 'SITE VISIT', value: 'Book Tour', icon: LucideIcons.eye, isAction: true, onTap: () => _showRequestDetailsDialog(project, null, 'Site Visit')),
                  ],
                ),
                const SizedBox(height: 24),
                _buildOverviewSection(project),
                const SizedBox(height: 32),
                _buildConstructionSection(project),
                const SizedBox(height: 32),
                _buildAmenitiesSection(project),
                const SizedBox(height: 32),
                _buildLocationSection(project),
                const SizedBox(height: 150),
              ],
            ),
          ),
          // Bottom actions removed for Guest Portal parity with web
          Positioned(
            top: MediaQuery.of(context).padding.top + 20,
            left: 20,
            right: 20,
            child: Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                _CircleAction(icon: LucideIcons.chevronLeft, onTap: () => Navigator.pop(context)),
                Row(
                  children: [
                    _CircleAction(icon: LucideIcons.share2, onTap: () => Share.share('Check out ${project?['title']} on M4 Family!')),
                    const SizedBox(width: 12),
                    _CircleAction(
                      icon: LucideIcons.heart, 
                      onTap: () => setState(() => _isFavorited = !_isFavorited),
                      color: _isFavorited ? Colors.red : null,
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


  Widget _buildHero(dynamic project, bool isDark) {
    final apiClient = ref.read(apiClientProvider);
    final heroUrl = apiClient.resolveUrl(project?['heroImage'] ?? project?['coverImage']);

    return SizedBox(
      height: 520,
      width: double.infinity,
      child: Stack(
        fit: StackFit.expand,
        children: [
          ClipRRect(
            borderRadius: const BorderRadius.vertical(bottom: Radius.circular(56)),
            child: Image.network(heroUrl, fit: BoxFit.cover),
          ),
          Container(
            decoration: BoxDecoration(
              borderRadius: const BorderRadius.vertical(bottom: Radius.circular(56)),
              gradient: LinearGradient(
                begin: Alignment.topCenter,
                end: Alignment.bottomCenter,
                colors: [
                  Colors.black.withValues(alpha: 0.3),
                  Colors.transparent,
                  Colors.black.withValues(alpha: 0.8),
                ],
              ),
            ),
          ),
          // Artistic Impression Badge
          Positioned(
            top: MediaQuery.of(context).padding.top + 20,
            right: 20,
            child: Container(
              padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
              decoration: BoxDecoration(
                color: Colors.black.withValues(alpha: 0.6),
                borderRadius: BorderRadius.circular(30),
                border: Border.all(color: Colors.white.withValues(alpha: 0.2)),
              ),
              child: Text('ARTISTIC IMPRESSION', style: GoogleFonts.montserrat(color: Colors.white, fontSize: 10, fontWeight: FontWeight.w900, letterSpacing: 1.5)),
            ),
          ),
          // Media Thumbnails
          Positioned(
            bottom: 40,
            left: 24,
            child: Row(
              children: [
                _HeroMediaThumb(
                  label: 'EXTERIOR', 
                  imageUrl: (_getCategoryThumbnail(project, 'EXTERIOR') != null && _getCategoryThumbnail(project, 'EXTERIOR')!.isNotEmpty)
                      ? apiClient.resolveUrl(_getCategoryThumbnail(project, 'EXTERIOR')!)
                      : heroUrl, 
                  onTap: () => _openHeroGallery(project, 'EXTERIOR')
                ),
                const SizedBox(width: 14),
                _HeroMediaThumb(
                  label: 'INTERIOR', 
                  imageUrl: (_getCategoryThumbnail(project, 'INTERIOR') != null && _getCategoryThumbnail(project, 'INTERIOR')!.isNotEmpty)
                      ? apiClient.resolveUrl(_getCategoryThumbnail(project, 'INTERIOR')!)
                      : heroUrl, 
                  onTap: () => _openHeroGallery(project, 'INTERIOR')
                ),
              ],
            ),
          ),
          // Project Identity
          Positioned(
            bottom: 140,
            left: 24,
            right: 24,
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Container(
                  padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 6),
                  decoration: BoxDecoration(color: M4Theme.premiumBlue, borderRadius: BorderRadius.circular(6)),
                  child: Text((project?['status']?.toString().toUpperCase() ?? 'ONGOING'), style: GoogleFonts.montserrat(color: Colors.white, fontSize: 10, fontWeight: FontWeight.w900, letterSpacing: 1)),
                ),
                const SizedBox(height: 16),
                Text(
                  (project?['title']?.toString() ?? 'Project Name'),
                  style: GoogleFonts.dmSerifDisplay(color: Colors.white, fontSize: 64, height: 1, letterSpacing: -1),
                ),
                const SizedBox(height: 12),
                Row(
                  children: [
                    const Icon(LucideIcons.mapPin, color: Colors.white60, size: 14),
                    const SizedBox(width: 6),
                    Text(
                      ((project?['location'] is Map ? project?['location']?['name'] : project?['location'])?.toString() ?? 'MAZGAON').toUpperCase(),
                      style: GoogleFonts.montserrat(color: Colors.white60, fontSize: 13, fontWeight: FontWeight.w900, letterSpacing: 2),
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


  Widget _buildSectionHeader(String title) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    return Row(
      children: [
        Container(width: 40, height: 2, color: M4Theme.premiumBlue),
        const SizedBox(width: 14),
        Text(title.toUpperCase(), style: GoogleFonts.montserrat(fontSize: 11, fontWeight: FontWeight.w900, color: isDark ? Colors.white : Colors.black, letterSpacing: 2)),
      ],
    );
  }

  Widget _buildOverviewSection(dynamic project) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        _buildSectionHeader('Overview'),
        const SizedBox(height: 24),
        Text(
          project?['description'] ?? 'Experience the pinnacle of luxury living with floor-to-ceiling windows, Italian marble flooring, and smart home automation.',
          style: GoogleFonts.montserrat(fontSize: 13, color: isDark ? Colors.white.withValues(alpha: 0.6) : Colors.black.withValues(alpha: 0.6), height: 1.8, fontWeight: FontWeight.w500),
        ),
        const SizedBox(height: 32),
        _MultimediaAssetCard(
          title: 'PROJECT FLYER',
          subtitle: 'HIGH RES • PDF',
          icon: LucideIcons.fileText,
          onView: () => _launchAction('Opening...', project?['flyer']),
          onDownload: () => _launchAction('Downloading...', project?['flyer']),
        ),
      ],
    );
  }

  Widget _buildConstructionSection(dynamic project) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        _buildSectionHeader('Construction Progress'),
        const SizedBox(height: 24),
        _ConstructionDashboardCard(
          overallProgress: project?['completion'] ?? 0,
          estimatedCompletion: (project?['possessionDate'] ?? 'DEC 2026').toString().toUpperCase(),
          phases: _progressPhases,
          onPhaseTap: (url) => _showMediaLightbox(url, 'IMAGE'),
        ),
      ],
    );
  }

  Widget _buildAmenitiesSection(dynamic project) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        _buildSectionHeader('Amenities'),
        const SizedBox(height: 24),
        _buildAmenities(project),
      ],
    );
  }

  Widget _buildLocationSection(dynamic project) {
     return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        _buildSectionHeader('Location'),
        const SizedBox(height: 24),
        _buildLocation(project),
      ],
    );
  }

  Widget _buildAmenities(dynamic project) {
    final amenitiesRaw = project?['amenities'] as List? ?? [];
    if (amenitiesRaw.isEmpty) return const _EmptyTabContent(message: 'Coming soon');
    final isDark = Theme.of(context).brightness == Brightness.dark;

    return GridView.builder(
      shrinkWrap: true,
      physics: const NeverScrollableScrollPhysics(),
      padding: EdgeInsets.zero,
      gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
        crossAxisCount: 3,
        mainAxisSpacing: 12,
        crossAxisSpacing: 12,
        childAspectRatio: 1.0,
      ),
      itemCount: amenitiesRaw.length,
      itemBuilder: (context, index) {
        final amenity = amenitiesRaw[index];
        final name = (amenity is Map ? (amenity['name']?.toString() ?? 'Amenity') : amenity.toString()).toUpperCase();
        
        return Container(
          decoration: BoxDecoration(
            color: isDark ? const Color(0xFF0F1115) : const Color(0xFFF4F4F5),
            borderRadius: BorderRadius.circular(32),
            border: Border.all(color: isDark ? Colors.white.withValues(alpha: 0.05) : Colors.black.withValues(alpha: 0.05)),
          ),
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Icon(_getAmenityIcon(name), color: isDark ? Colors.white.withValues(alpha: 0.6) : Colors.black.withValues(alpha: 0.6), size: 28),
              const SizedBox(height: 16),
              Padding(
                padding: const EdgeInsets.symmetric(horizontal: 8),
                child: Text(
                  name,
                  textAlign: TextAlign.center,
                  style: GoogleFonts.montserrat(
                    fontSize: 8, 
                    fontWeight: FontWeight.w900, 
                    color: isDark ? Colors.white.withValues(alpha: 0.8) : Colors.black.withValues(alpha: 0.8), 
                    letterSpacing: 1,
                    height: 1.2,
                  ),
                ),
              ),
            ],
          ),
        );
      },
    );
  }


  Widget _buildBottomActions(dynamic project) {
    return Positioned(
      bottom: 40,
      left: 20,
      right: 20,
      child: Container(
        height: 80,
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(40),
          boxShadow: [
             BoxShadow(color: Colors.black.withValues(alpha: 0.1), blurRadius: 20, offset: const Offset(0, 10)),
          ],
        ),
        child: Row(
          children: [
            const SizedBox(width: 20),
            _BottomIconAction(icon: LucideIcons.phone, onTap: () => SupportHandlers.launchCall(project?['phone'] ?? project?['contactPhone'])),
            const SizedBox(width: 12),
            Expanded(
              child: _ScaleButton(
                onTap: () => _showRequestDetailsDialog(project, null),
                child: Container(
                  height: 56,
                  decoration: BoxDecoration(
                    color: Colors.black,
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
            const SizedBox(width: 20),
          ],
        ),
      ),
    );
  }

  IconData _getAmenityIcon(String? name) {
    final n = name?.toLowerCase() ?? '';
    if (n.contains('lounge')) return LucideIcons.armchair;
    if (n.contains('reading')) return LucideIcons.bookOpen;
    if (n.contains('gym')) return LucideIcons.dumbbell;
    if (n.contains('pool')) return LucideIcons.waves;
    if (n.contains('jogging') || n.contains('track')) return LucideIcons.wind;
    if (n.contains('garden') || n.contains('park')) return LucideIcons.trees;
    if (n.contains('fire') || n.contains('pit')) return LucideIcons.flame;
    if (n.contains('playground') || n.contains('kids')) return LucideIcons.toyBrick;
    if (n.contains('clubhouse')) return LucideIcons.building2;
    if (n.contains('security')) return LucideIcons.shieldCheck;
    if (n.contains('parking')) return LucideIcons.car;
    if (n.contains('sunroof')) return LucideIcons.umbrella;
    return LucideIcons.sparkles;
  }

  Widget _buildLocation(dynamic project) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final locName = (project?['location'] is Map ? project?['location']?['name'] : project?['location'])?.toString() ?? 'Mazgaon, Mumbai';
    
    return Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          _ScaleButton(
            onTap: () => _launchAction('Opening Maps...', 'https://www.google.com/maps?q=${Uri.encodeComponent(locName)}'),
            child: Container(
              height: 220,
              width: double.infinity,
              decoration: BoxDecoration(
                color: isDark ? const Color(0xFF1E1F21) : const Color(0xFFF4F4F5),
                borderRadius: BorderRadius.circular(32),
                border: Border.all(color: isDark ? Colors.white.withValues(alpha: 0.05) : Colors.black.withValues(alpha: 0.05)),
              ),
              child: ClipRRect(
                borderRadius: BorderRadius.circular(32),
                child: Stack(
                  fit: StackFit.expand,
                  children: [
                    Image.network(
                      'https://images.unsplash.com/photo-1524661135-423995f22d0b?auto=format&fit=crop&q=80', 
                      fit: BoxFit.cover,
                      color: isDark ? Colors.black.withValues(alpha: 0.6) : Colors.white.withValues(alpha: 0.6),
                      colorBlendMode: BlendMode.dstATop,
                    ),
                    Positioned(
                      bottom: 20,
                      right: 20,
                      child: Container(
                        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 10),
                        decoration: BoxDecoration(
                          color: isDark ? const Color(0xFF1E293B) : Colors.white.withValues(alpha: 0.9),
                          borderRadius: BorderRadius.circular(30),
                        ),
                        child: Row(
                          mainAxisSize: MainAxisSize.min,
                          children: [
                            const Icon(LucideIcons.mapPin, color: M4Theme.premiumBlue, size: 12),
                            const SizedBox(width: 8),
                            Text('VIEW ON MAPS', style: GoogleFonts.montserrat(fontSize: 8, fontWeight: FontWeight.w900, color: isDark ? Colors.white : Colors.black, letterSpacing: 1)),
                          ],
                        ),
                      ),
                    ),
                    Positioned(
                      bottom: 25,
                      left: 20,
                      child: Text('Open in Maps â†—', style: GoogleFonts.montserrat(fontSize: 9, fontWeight: FontWeight.bold, color: M4Theme.premiumBlue, decoration: TextDecoration.underline)),
                    ),
                  ],
                ),
              ),
            ),
          ),
        ],
    );

  }
  String? _getCategoryThumbnail(dynamic project, String category) {
    final List<dynamic> media = project?['media'] as List? ?? [];
    if (category == 'EXTERIOR') {
      final ext = (project?['exteriorImages'] as List?)?.firstOrNull;
      if (ext != null) return ext.toString();
      final fromMedia = media.firstWhere((m) => m['category']?.toString().toUpperCase() == 'EXTERIOR', orElse: () => null);
      if (fromMedia != null) return fromMedia['url']?.toString();
    } else if (category == 'INTERIOR') {
      final int = (project?['interiorImages'] as List?)?.firstOrNull;
      if (int != null) return int.toString();
      final fromMedia = media.firstWhere((m) => m['category']?.toString().toUpperCase() == 'INTERIOR', orElse: () => null);
      if (fromMedia != null) return fromMedia['url']?.toString();
    }
    return null;
  }
} // End of _GuestProjectDetailScreenState

class _OverviewActionCard extends StatelessWidget {
  final String label;
  final String value;
  final IconData icon;
  final bool isAction;
  final VoidCallback? onTap;

  const _OverviewActionCard({
    required this.label, 
    required this.value, 
    required this.icon, 
    this.isAction = false, 
    this.onTap
  });

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    
    return GestureDetector(
      onTap: onTap,
      child: Container(
        padding: const EdgeInsets.all(20),
        decoration: BoxDecoration(
          color: isDark ? Colors.white.withValues(alpha: 0.03) : const Color(0xFFF1F5F9),
          borderRadius: BorderRadius.circular(32),
          border: Border.all(
            color: isAction 
              ? M4Theme.premiumBlue.withValues(alpha: 0.3) 
              : (isDark ? Colors.white.withValues(alpha: 0.08) : Colors.black.withValues(alpha: 0.05)),
            width: 1.5,
          ),
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.center,
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(icon, color: isAction ? M4Theme.premiumBlue : (isDark ? Colors.white38 : Colors.black38), size: 16),
            const SizedBox(height: 12),
            Text(
              label.toUpperCase(), 
              style: GoogleFonts.montserrat(
                color: isDark ? Colors.white38 : Colors.black38, 
                fontSize: 8, 
                fontWeight: FontWeight.w900, 
                letterSpacing: 2,
              ),
              maxLines: 1,
              overflow: TextOverflow.ellipsis,
            ),
            const SizedBox(height: 4),
            FittedBox(
              fit: BoxFit.scaleDown,
              child: Text(
                value, 
                style: GoogleFonts.montserrat(
                  color: isDark ? Colors.white : Colors.black, 
                  fontSize: 24, 
                  fontWeight: FontWeight.w900, 
                  letterSpacing: -0.5,
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _CircleAction extends StatelessWidget {
  final IconData icon;
  final VoidCallback onTap;
  final Color? color;

  const _CircleAction({required this.icon, required this.onTap, this.color});

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    return _ScaleButton(
      onTap: onTap,
      child: Container(
        padding: const EdgeInsets.all(12),
        decoration: BoxDecoration(
          color: isDark ? Colors.white.withValues(alpha: 0.05) : Colors.black.withValues(alpha: 0.04),
          border: Border.all(color: isDark ? Colors.white.withValues(alpha: 0.1) : Colors.black.withValues(alpha: 0.1)),
          shape: BoxShape.circle,
        ),
        child: Icon(icon, size: 20, color: color ?? (isDark ? Colors.white : Colors.black)),
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
    final isDark = Theme.of(context).brightness == Brightness.dark;
    return _ScaleButton(
      onTap: onTap,
      child: Container(
        width: 56,
        height: 56,
        decoration: BoxDecoration(
          color: isDark ? Colors.white.withValues(alpha: 0.05) : const Color(0xFFF4F4F5),
          borderRadius: BorderRadius.circular(20),
          border: Border.all(color: isDark ? Colors.white.withValues(alpha: 0.1) : Colors.black.withValues(alpha: 0.05)),
        ),
        child: Center(child: Icon(icon, color: isDark ? Colors.white : Colors.black, size: 20)),
      ),
    );
  }
}

class _HeroMediaThumb extends StatelessWidget {
  final String label;
  final String? imageUrl;
  final VoidCallback onTap;

  const _HeroMediaThumb({
    required this.label, 
    this.imageUrl, 
    required this.onTap
  });

  @override
  Widget build(BuildContext context) {
    return _ScaleButton(
      onTap: onTap,
      child: ClipRRect(
        borderRadius: BorderRadius.circular(16),
        child: BackdropFilter(
          filter: ImageFilter.blur(sigmaX: 5, sigmaY: 5),
          child: Container(
            width: 72,
            height: 72,
            decoration: BoxDecoration(
              color: Colors.black.withValues(alpha: 0.2),
              borderRadius: BorderRadius.circular(16),
              border: Border.all(color: Colors.white.withValues(alpha: 0.2), width: 1.5),
            ),
            clipBehavior: Clip.antiAlias,
            child: Stack(
              fit: StackFit.expand,
              children: [
                if (imageUrl != null)
                  Image.network(imageUrl!, fit: BoxFit.cover, errorBuilder: (c, e, s) => Container(color: Colors.white10)),
                Container(color: Colors.black.withValues(alpha: 0.3)),
                Center(
                  child: Text(
                    label,
                    textAlign: TextAlign.center,
                    style: GoogleFonts.montserrat(color: Colors.white, fontSize: 8, fontWeight: FontWeight.w900, letterSpacing: 0.5),
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

class _ScaleButton extends StatefulWidget {
  final Widget child;
  final VoidCallback? onTap;
  const _ScaleButton({required this.child, this.onTap});

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

class _SectionHeader extends StatelessWidget {
  final String title;
  const _SectionHeader({required this.title});
  @override
  Widget build(BuildContext context) {
    return Text(title.toUpperCase(), style: GoogleFonts.montserrat(fontSize: 10, fontWeight: FontWeight.w900, color: M4Theme.premiumBlue, letterSpacing: 2));
  }
}

class _EmptyTabContent extends StatelessWidget {
  final String message;
  const _EmptyTabContent({required this.message});
  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    return Center(child: Text(message.toUpperCase(), textAlign: TextAlign.center, style: GoogleFonts.montserrat(fontSize: 12, color: isDark ? Colors.white38 : Colors.black38)));
  }
}

class _MultimediaAssetCard extends StatelessWidget {
  final String title;
  final String subtitle;
  final IconData icon;
  final VoidCallback onView;
  final VoidCallback? onDownload;
  final bool isPrimary;

  const _MultimediaAssetCard({
    required this.title, 
    required this.subtitle, 
    required this.icon, 
    required this.onView, 
    this.onDownload,
    this.isPrimary = false,
  });

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    return ClipRRect(
      borderRadius: BorderRadius.circular(40),
      child: BackdropFilter(
        filter: ImageFilter.blur(sigmaX: 10, sigmaY: 10),
        child: Container(
          padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 24),
          decoration: BoxDecoration(
            color: isDark ? Colors.white.withValues(alpha: 0.03) : Colors.white,
            borderRadius: BorderRadius.circular(40),
            border: Border.all(color: isDark ? Colors.white.withValues(alpha: 0.08) : Colors.black.withValues(alpha: 0.05)),
          ),
          child: Row(
            children: [
              Container(
                padding: const EdgeInsets.all(14),
                decoration: BoxDecoration(
                  color: isDark ? Colors.white.withValues(alpha: 0.05) : Colors.black.withValues(alpha: 0.04),
                  borderRadius: BorderRadius.circular(16),
                ),
                child: Icon(icon, color: isDark ? Colors.white70 : Colors.black.withValues(alpha: 0.7), size: 20),
              ),
              const SizedBox(width: 16),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(title.toUpperCase(), style: GoogleFonts.montserrat(fontSize: 11, fontWeight: FontWeight.w900, color: isDark ? Colors.white : Colors.black, letterSpacing: 0.5)),
                    const SizedBox(height: 4),
                    Text(subtitle.replaceFirst('•', ' • ').toUpperCase(), style: GoogleFonts.montserrat(fontSize: 8, color: isDark ? Colors.white38 : Colors.black38, fontWeight: FontWeight.w900, letterSpacing: 1)),
                  ],
                ),
              ),
              const SizedBox(width: 8),
              _AssetButton(label: 'VIEW', isOutline: true, onTap: onView),
              if (onDownload != null) ...[
                const SizedBox(width: 8),
                _AssetButton(label: 'DOWNLOAD', isOutline: false, onTap: onDownload!),
              ],
            ],
          ),
        ),
      ),
    );
  }
}

class _AssetButton extends StatelessWidget {
  final String label;
  final bool isOutline;
  final VoidCallback onTap;
  const _AssetButton({required this.label, required this.isOutline, required this.onTap});

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    return _ScaleButton(
      onTap: onTap,
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
        decoration: BoxDecoration(
          color: isOutline ? Colors.transparent : (isDark ? Colors.white : Colors.black),
          borderRadius: BorderRadius.circular(30),
          border: isOutline ? Border.all(color: isDark ? Colors.white24 : Colors.black12, width: 1.5) : null,
        ),
        child: Text(label, style: GoogleFonts.montserrat(fontSize: 8, fontWeight: FontWeight.w900, color: isOutline ? (isDark ? Colors.white : Colors.black) : (isDark ? Colors.black : Colors.white), letterSpacing: 1)),
      ),
    );
  }
}

class _ConstructionDashboardCard extends ConsumerWidget {
  final num overallProgress;
  final String estimatedCompletion;
  final List<dynamic> phases;
  final Function(String) onPhaseTap;

  const _ConstructionDashboardCard({
    required this.overallProgress, 
    required this.estimatedCompletion, 
    required this.phases,
    required this.onPhaseTap,
  });

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final apiClient = ref.read(apiClientProvider);
    final isDark = Theme.of(context).brightness == Brightness.dark;
    
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(40),
      decoration: BoxDecoration(
        color: isDark ? const Color(0xFF0F1115) : const Color(0xFFF4F4F5),
        borderRadius: BorderRadius.circular(40),
        border: Border.all(color: isDark ? Colors.white.withValues(alpha: 0.05) : Colors.black.withValues(alpha: 0.05)),
      ),
      child: Column(
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text('ESTIMATED COMPLETION DATE', style: GoogleFonts.montserrat(fontSize: 9, fontWeight: FontWeight.w900, color: M4Theme.premiumBlue, letterSpacing: 1)),
                    const SizedBox(height: 12),
                    Text(estimatedCompletion, style: GoogleFonts.dmSerifDisplay(fontSize: 64, color: isDark ? Colors.white : Colors.black, height: 1)),
                    const SizedBox(height: 24),
                    Text(
                      'As the project progresses, significant milestones are reached, showcasing our team\'s dedication and expertise.',
                      style: GoogleFonts.montserrat(fontSize: 14, color: isDark ? Colors.white38 : Colors.black38, height: 1.6, fontWeight: FontWeight.w500),
                    ),
                  ],
                ),
              ),
              const SizedBox(width: 32),
              Stack(
                alignment: Alignment.center,
                children: [
                   SizedBox(
                    width: 100,
                    height: 100,
                    child: CircularProgressIndicator(
                      value: overallProgress.toDouble() / 100,
                      strokeWidth: 6,
                      backgroundColor: isDark ? Colors.white.withValues(alpha: 0.1) : Colors.black.withValues(alpha: 0.1),
                      valueColor: const AlwaysStoppedAnimation<Color>(M4Theme.premiumBlue),
                    ),
                  ),
                  Column(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Text('${overallProgress.toInt()}%', style: GoogleFonts.montserrat(fontSize: 22, fontWeight: FontWeight.w900, color: isDark ? Colors.white : Colors.black)),
                      Text('OVERALL', style: GoogleFonts.montserrat(fontSize: 8, fontWeight: FontWeight.w900, color: isDark ? Colors.white38 : Colors.black38, letterSpacing: 1)),
                    ],
                  ),
                ],
              ),
            ],
          ),
          if (phases.isNotEmpty) ...[
            const SizedBox(height: 64),
            SingleChildScrollView(
              scrollDirection: Axis.horizontal,
              clipBehavior: Clip.none,
              child: Row(
                children: phases.map((phase) {
                  final imageUrl = apiClient.resolveUrl(phase['image'] ?? (phase['images'] as List?)?.first);
                  return Container(
                    width: 320,
                    margin: const EdgeInsets.only(right: 24),
                    decoration: BoxDecoration(
                      color: isDark ? Colors.white.withValues(alpha: 0.03) : Colors.white,
                      borderRadius: BorderRadius.circular(32),
                      border: Border.all(color: isDark ? Colors.white.withValues(alpha: 0.05) : Colors.black.withValues(alpha: 0.05)),
                    ),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        _ScaleButton(
                          onTap: () => onPhaseTap(imageUrl),
                          child: ClipRRect(
                            borderRadius: const BorderRadius.vertical(top: Radius.circular(32)),
                            child: Image.network(imageUrl, height: 220, width: 320, fit: BoxFit.cover, errorBuilder: (c, e, s) => Container(height: 220, color: Colors.white10)),
                          ),
                        ),
                        Padding(
                          padding: const EdgeInsets.all(28),
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Text(phase['name']?.toString().toUpperCase() ?? 'INITIAL PHASE', style: GoogleFonts.montserrat(fontSize: 13, fontWeight: FontWeight.w900, color: isDark ? Colors.white : Colors.black, letterSpacing: 1.5)),
                              const SizedBox(height: 16),
                              Row(
                                children: [
                                  SizedBox(
                                    width: 32,
                                    height: 32,
                                    child: CircularProgressIndicator(
                                      value: (phase['progressPercent'] ?? phase['progress'] ?? 0).toDouble() / 100,
                                      strokeWidth: 3,
                                      backgroundColor: isDark ? Colors.white10 : Colors.black.withValues(alpha: 0.05),
                                      valueColor: const AlwaysStoppedAnimation<Color>(M4Theme.premiumBlue),
                                    ),
                                  ),
                                  const SizedBox(width: 16),
                                  Text('${phase['progressPercent'] ?? phase['progress'] ?? 0}% COMPLETED', style: GoogleFonts.montserrat(fontSize: 11, fontWeight: FontWeight.w900, color: isDark ? Colors.white38 : Colors.black38, letterSpacing: 1)),
                                ],
                              ),
                            ],
                          ),
                        ),
                      ],
                    ),
                  );
                }).toList(),
              ),
            ),
          ],
        ],
      ),
    );
  }
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
          color: isActive ? M4Theme.premiumBlue : Colors.black.withValues(alpha: 0.04),
          borderRadius: BorderRadius.circular(12),
          border: Border.all(color: isActive ? M4Theme.premiumBlue : Colors.black.withValues(alpha: 0.05)),
        ),
        child: Text(
          label,
          style: GoogleFonts.montserrat(
            fontSize: 9,
            fontWeight: FontWeight.w900,
            color: isActive ? Colors.white : Colors.black.withValues(alpha: 0.4),
            letterSpacing: 1.0,
          ),
        ),
      ).animate(target: isActive ? 1 : 0).scale(duration: 100.ms, end: const Offset(0.95, 0.95)),
    );
  }
}
