import 'package:dio/dio.dart';
import 'package:cached_network_image/cached_network_image.dart';
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
import 'package:m4_mobile/presentation/screens/booking/booking_start_screen.dart';

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
  List<dynamic> _progressPhases = [];
  bool _isLoading = true;
  final TextEditingController _nameController = TextEditingController();
  final TextEditingController _phoneController = TextEditingController();
  final TextEditingController _emailController = TextEditingController();
  bool _isFavorited = false;
  String _mediaFilter = 'ALL';
  String _selectedConfig = '3 BHK';
  bool _showFullOverviewDesc = false;
  bool _showFullProgressDesc = false;


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
      
      try {
        // We show the snackbar first to provide immediate feedback
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(message, style: GoogleFonts.montserrat(fontSize: 12, fontWeight: FontWeight.bold)),
            backgroundColor: M4Theme.premiumBlue,
            duration: const Duration(seconds: 2),
            behavior: SnackBarBehavior.floating,
            shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
          ),
        );
        
        await launchUrl(uri, mode: LaunchMode.externalApplication);
        return;
      } catch (e) {
        debugPrint('Error launching URL: $e');
      }
    }
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

  void _showBookingOptionsDialog(dynamic project) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    
    showModalBottomSheet(
      context: context,
      backgroundColor: Colors.transparent,
      isScrollControlled: true,
      builder: (context) => Container(
        padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 32),
        decoration: BoxDecoration(
          color: isDark ? const Color(0xFF0F1115) : Colors.white,
          borderRadius: const BorderRadius.vertical(top: Radius.circular(40)),
          border: Border.all(color: isDark ? Colors.white.withOpacity(0.1) : Colors.black.withOpacity(0.1), width: 0.5),
        ),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Align(
              alignment: Alignment.center,
              child: Container(width: 40, height: 4, decoration: BoxDecoration(color: isDark ? Colors.white24 : Colors.black12, borderRadius: BorderRadius.circular(2))),
            ),
            const SizedBox(height: 32),
            Text(
              'HOW CAN\nWE HELP?',
              style: GoogleFonts.montserrat(
                fontSize: 28, 
                fontWeight: FontWeight.w900, 
                color: isDark ? Colors.white : Colors.black,
                height: 0.9,
                letterSpacing: -1.5,
              ),
            ),
            const SizedBox(height: 12),
            Text(
              'INTERESTED IN ${project?['title']?.toString().toUpperCase() ?? 'PROJECT'}?\nCHOOSE HOW YOU\'D LIKE TO PROCEED.',
              style: GoogleFonts.montserrat(
                fontSize: 9, 
                color: isDark ? Colors.white38 : Colors.black38, 
                fontWeight: FontWeight.w900, 
                letterSpacing: 2,
              ),
            ),
            const SizedBox(height: 40),
            _buildBookingOption(
              icon: LucideIcons.messageSquare,
              title: 'SEND INQUIRY',
              desc: 'Get detailed brochure and pricing via email/WhatsApp.',
              color: const Color(0xFF3B82F6),
              onTap: () {
                Navigator.pop(context);
                _showRequestDetailsDialog(project, null, 'General');
              },
            ),
            const SizedBox(height: 16),
            _buildBookingOption(
              icon: LucideIcons.calendar,
              title: 'SCHEDULE SITE VISIT',
              desc: 'Book a personalized tour with our project manager.',
              color: const Color(0xFF10B981),
              onTap: () {
                Navigator.pop(context);
                _showRequestDetailsDialog(project, null, 'Site Visit');
              },
            ),
            const SizedBox(height: 16),
            _buildBookingOption(
              icon: LucideIcons.creditCard,
              title: 'TOKEN BOOKING',
              desc: 'Lock your preferred unit with a refundable token amount.',
              color: const Color(0xFFF59E0B),
              onTap: () {
                Navigator.pop(context);
                _showRequestDetailsDialog(project, 'TOKEN BOOKING', 'General');
              },
            ),
            const SizedBox(height: 32),
            Container(
              padding: const EdgeInsets.all(20),
              decoration: BoxDecoration(
                color: M4Theme.premiumBlue.withOpacity(0.05),
                borderRadius: BorderRadius.circular(20),
                border: Border.all(color: M4Theme.premiumBlue.withOpacity(0.1)),
              ),
              child: Row(
                children: [
                  Container(
                    padding: const EdgeInsets.all(8),
                    decoration: BoxDecoration(color: M4Theme.premiumBlue, borderRadius: BorderRadius.circular(8)),
                    child: const Icon(LucideIcons.info, color: Colors.white, size: 14),
                  ),
                  const SizedBox(width: 16),
                  Expanded(
                    child: Text(
                      'M4 FAMILY MEMBERS GET PRIORITY SITE VISITS AND EXCLUSIVE UNIT SELECTION WINDOWS.',
                      style: GoogleFonts.montserrat(
                        fontSize: 8, 
                        color: isDark ? Colors.white70 : Colors.black.withOpacity(0.8), 
                        fontWeight: FontWeight.w900, 
                        letterSpacing: 0.5,
                        height: 1.4,
                      ),
                    ),
                  ),
                ],
              ),
            ),
            const SizedBox(height: 20),
          ],
        ),
      ),
    );
  }

  Widget _buildBookingOption({
    required IconData icon,
    required String title,
    required String desc,
    required Color color,
    required VoidCallback onTap,
  }) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    return _ScaleButton(
      onTap: onTap,
      child: Container(
        padding: const EdgeInsets.all(20),
        decoration: BoxDecoration(
          color: isDark ? const Color(0xFF1E1F21) : Colors.white,
          borderRadius: BorderRadius.circular(24),
          border: Border.all(color: isDark ? Colors.white.withOpacity(0.05) : Colors.black.withOpacity(0.05)),
          boxShadow: isDark ? [] : [BoxShadow(color: Colors.black.withOpacity(0.05), blurRadius: 15, offset: const Offset(0, 5))],
        ),
        child: Row(
          children: [
            Container(
              width: 44,
              height: 44,
              decoration: BoxDecoration(
                color: color.withOpacity(0.1),
                borderRadius: BorderRadius.circular(12),
              ),
              child: Icon(icon, color: color, size: 20),
            ),
            const SizedBox(width: 16),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    title,
                    style: GoogleFonts.montserrat(fontSize: 12, fontWeight: FontWeight.w900, color: isDark ? Colors.white : Colors.black, letterSpacing: 0.5),
                  ),
                  const SizedBox(height: 2),
                  Text(
                    desc,
                    style: GoogleFonts.montserrat(fontSize: 9, color: isDark ? Colors.white38 : Colors.black38, fontWeight: FontWeight.w600),
                  ),
                ],
              ),
            ),
            Icon(LucideIcons.chevronRight, color: isDark ? Colors.white12 : Colors.black12, size: 18),
          ],
        ),
      ),
    );
  }

  void _showRequestDetailsDialog(dynamic project, [dynamic plan, String type = 'General']) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final planName = plan is Map ? plan['name']?.toString() : plan?.toString();
    final projectTitle = project?['title'] ?? 'this project';

    // Prefill auth user data ONLY for General inquiries, not for Video Call or Site Visit
    final authUser = ref.read(authProvider).user;
    if (authUser != null && type == 'General') {
      _nameController.text = authUser['fullName']?.toString() ?? authUser['username']?.toString() ?? '';
      _phoneController.text = authUser['phone']?.toString() ?? '';
      _emailController.text = authUser['email']?.toString() ?? '';
    } else {
      _nameController.clear();
      _phoneController.clear();
      _emailController.clear();
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
            border: Border.all(color: isDark ? Colors.white.withOpacity(0.1) : Colors.black.withOpacity(0.1), width: 0.5),
            boxShadow: isDark ? [] : [BoxShadow(color: Colors.black.withOpacity(0.1), blurRadius: 20, offset: const Offset(0, -5))],
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
                      planName != null 
                        ? 'INQUIRY FOR "$planName" PAYMENT PLAN'
                        : 'INQUIRY FOR ${projectTitle.toUpperCase()}',
                      style: GoogleFonts.montserrat(fontSize: 10, color: isDark ? Colors.white54 : Colors.black45, fontWeight: FontWeight.w900, letterSpacing: 1),
                    ),
                    const SizedBox(height: 24),
                    
                    if (authUser != null)
                      Container(
                        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
                        decoration: BoxDecoration(
                          color: isDark ? Colors.white.withOpacity(0.05) : Colors.black.withOpacity(0.05),
                          borderRadius: BorderRadius.circular(12),
                        ),
                        child: Row(
                          children: [
                            Container(width: 6, height: 6, decoration: const BoxDecoration(color: Color(0xFF10B981), shape: BoxShape.circle)),
                            const SizedBox(width: 12),
                            Text(
                              'ACTING AS: ${authUser['email']?.toString().toUpperCase()}',
                              style: GoogleFonts.montserrat(fontSize: 9, fontWeight: FontWeight.w900, color: isDark ? Colors.white70 : Colors.black87, letterSpacing: 0.5),
                            ),
                          ],
                        ),
                      ),
                    
                    const SizedBox(height: 32),
                    
                    Text('PREFERRED CONFIGURATION *', style: GoogleFonts.montserrat(fontSize: 10, fontWeight: FontWeight.w900, color: isDark ? Colors.white54 : Colors.black54, letterSpacing: 1)),
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
                                : (isDark ? Colors.white.withOpacity(0.03) : Colors.black.withOpacity(0.04)),
                              borderRadius: BorderRadius.circular(10),
                              border: Border.all(color: isActive ? (isDark ? Colors.white : Colors.black) : (isDark ? Colors.white.withOpacity(0.1) : Colors.black.withOpacity(0.05))),
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
                              color: (isDark ? Colors.white : Colors.black).withOpacity(0.1), 
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
        Text(label, style: GoogleFonts.montserrat(fontSize: 10, fontWeight: FontWeight.w900, color: isDark ? Colors.white54 : Colors.black54, letterSpacing: 1)),
        const SizedBox(height: 10),
        Container(
          padding: const EdgeInsets.symmetric(horizontal: 20),
          decoration: BoxDecoration(
            color: isDark ? Colors.white.withOpacity(0.03) : Colors.black.withOpacity(0.04),
            borderRadius: BorderRadius.circular(16),
            border: Border.all(color: isDark ? Colors.white.withOpacity(0.05) : Colors.black.withOpacity(0.05)),
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
      _showMediaLightbox(list, 'IMAGE');
    } else {
      _launchAction('Gallery coming soon!', null);
    }
  }

  void _showMediaLightbox(dynamic urlOrList, String type, [int initialIndex = 0]) {
    final apiClient = ref.read(apiClientProvider);
    final List<String> urls = urlOrList is List 
      ? urlOrList.map((u) => apiClient.resolveUrl(u.toString())).toList() 
      : [apiClient.resolveUrl(urlOrList.toString())];
    
    final PageController pageController = PageController(initialPage: initialIndex);

    showGeneralDialog(
      context: context,
      barrierDismissible: true,
      barrierLabel: 'Lightbox',
      barrierColor: Colors.black.withOpacity(0.9),
      transitionDuration: const Duration(milliseconds: 300),
      pageBuilder: (context, anim1, anim2) {
        return Scaffold(
          backgroundColor: Colors.transparent,
          body: Stack(
            fit: StackFit.expand,
            children: [
              PageView.builder(
                controller: pageController,
                itemCount: urls.length,
                itemBuilder: (context, index) {
                  return Center(
                    child: InteractiveViewer(
                      child: Image.network(
                        urls[index],
                        fit: BoxFit.contain,
                        errorBuilder: (context, error, stackTrace) => const Icon(LucideIcons.image, color: Colors.white24, size: 50),
                      ),
                    ),
                  );
                },
              ),
              Positioned(
                left: 10,
                top: 0,
                bottom: 0,
                child: Center(
                  child: IconButton(
                    icon: Container(
                      padding: const EdgeInsets.all(8),
                      decoration: BoxDecoration(color: Colors.black26, shape: BoxShape.circle),
                      child: const Icon(LucideIcons.chevronLeft, color: Colors.white, size: 24),
                    ),
                    onPressed: () => pageController.previousPage(duration: const Duration(milliseconds: 300), curve: Curves.easeInOut),
                  ),
                ),
              ),
              Positioned(
                right: 10,
                top: 0,
                bottom: 0,
                child: Center(
                  child: IconButton(
                    icon: Container(
                      padding: const EdgeInsets.all(8),
                      decoration: BoxDecoration(color: Colors.black26, shape: BoxShape.circle),
                      child: const Icon(LucideIcons.chevronRight, color: Colors.white, size: 24),
                    ),
                    onPressed: () => pageController.nextPage(duration: const Duration(milliseconds: 300), curve: Curves.easeInOut),
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
              if (urls.length > 1)
                Positioned(
                  bottom: 40,
                  left: 0,
                  right: 0,
                  child: Center(
                    child: Container(
                      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
                      decoration: BoxDecoration(
                        color: Colors.black54,
                        borderRadius: BorderRadius.circular(20),
                      ),
                      child: ListenableBuilder(
                        listenable: pageController,
                        builder: (context, child) {
                          final current = (pageController.hasClients ? pageController.page?.round() ?? initialIndex : initialIndex) + 1;
                          return Text(
                            '$current / ${urls.length}',
                            style: GoogleFonts.montserrat(color: Colors.white, fontSize: 12, fontWeight: FontWeight.bold),
                          );
                        }
                      ),
                    ),
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
        backgroundColor: Colors.black,
        body: Center(
          child: CircularProgressIndicator(color: M4Theme.premiumBlue),
        ),
      );
    }

    return Scaffold(
      backgroundColor: isDark ? const Color(0xFF0F1115) : Colors.white,
      body: Stack(
        children: [
          SingleChildScrollView(
            physics: const BouncingScrollPhysics(),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                _buildHero(project, isDark),
                const SizedBox(height: 16),
                _buildMediaQuickActions(project, isDark),
                const SizedBox(height: 24),
                GridView.count(
                  padding: const EdgeInsets.symmetric(horizontal: 24),
                  shrinkWrap: true,
                  physics: const NeverScrollableScrollPhysics(),
                  crossAxisCount: 2,
                  mainAxisSpacing: 12,
                  crossAxisSpacing: 12,
                  childAspectRatio: 2.5,
                  children: [
                    _OverviewActionCard(label: 'COMPLETION', value: '${project?['completion'] ?? 0}%', icon: LucideIcons.checkCircle2),
                    _OverviewActionCard(label: 'CONFIG', value: project?['config'] ?? '3 & 4 BHK', icon: LucideIcons.building2),
                    _OverviewActionCard(label: 'VIDEO CALL', value: 'CONNECT NOW', icon: LucideIcons.video, isAction: true, onTap: () => _showRequestDetailsDialog(project, null, 'VC')),
                    _OverviewActionCard(label: 'SITE VISIT', value: 'BOOK TOUR', icon: LucideIcons.eye, isAction: true, onTap: () => _showRequestDetailsDialog(project, null, 'Site Visit')),
                  ],
                ),
                const SizedBox(height: 24),
                Padding(
                  padding: const EdgeInsets.symmetric(horizontal: 24),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      _buildOverviewSection(project),
                      const SizedBox(height: 48),
                      _buildConstructionSection(project),
                      const SizedBox(height: 48),
                      _buildPricingSection(project),
                      const SizedBox(height: 48),
                      _buildAmenitiesSection(project),
                      const SizedBox(height: 48),
                      _buildPlansSection(project),
                      const SizedBox(height: 48),
                      _buildMediaGallerySection(project),
                      const SizedBox(height: 48),
                      _buildDocumentsSection(project),
                      const SizedBox(height: 48),
                      _buildLocationSection(project),
                    ],
                  ),
                ),
                const SizedBox(height: 150),
              ],
            ),
          ),
          _buildBottomActions(project),
        ],
      ),
    );
  }


  Widget _buildHero(dynamic project, bool isDark) {
    final apiClient = ref.read(apiClientProvider);
    final heroUrl = apiClient.resolveUrl(project?['heroImage'] ?? project?['coverImage'] ?? (project?['heroImages'] as List?)?.first ?? '');

    return AspectRatio(
      aspectRatio: 1920 / 1080,
      child: Stack(
        fit: StackFit.expand,
        children: [
          ClipRRect(
            borderRadius: const BorderRadius.vertical(bottom: Radius.circular(40)),
            child: CachedNetworkImage(
              imageUrl: heroUrl,
              fit: BoxFit.cover,
              placeholder: (context, url) => Container(color: isDark ? Colors.white10 : Colors.black.withOpacity(0.1)),
              errorWidget: (context, url, error) => Container(color: isDark ? Colors.white10 : Colors.black.withOpacity(0.1)),
            ),
          ),
          Container(
            decoration: BoxDecoration(
              borderRadius: const BorderRadius.vertical(bottom: Radius.circular(40)),
              gradient: LinearGradient(
                begin: Alignment.topCenter,
                end: Alignment.bottomCenter,
                colors: [
                  Colors.black.withOpacity(0.1),
                  Colors.transparent,
                  Colors.black.withOpacity(0.8),
                ],
              ),
            ),
          ),
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
          Positioned(
            top: MediaQuery.of(context).padding.top + 70,
            right: 20,
            child: Container(
              padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 5),
              decoration: BoxDecoration(
                color: Colors.black.withOpacity(0.5),
                borderRadius: BorderRadius.circular(20),
                border: Border.all(color: Colors.white.withOpacity(0.1)),
              ),
              child: Text(
                'ARTISTIC IMPRESSION', 
                style: GoogleFonts.montserrat(
                  color: Colors.white.withOpacity(0.8), 
                  fontSize: 7, 
                  fontWeight: FontWeight.w900, 
                  letterSpacing: 1.2
                )
              ),
            ),
          ),
          Positioned(
            bottom: 24,
            left: 24,
            right: 24,
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                _Badge(text: (project?['status']?.toString().toUpperCase() ?? 'ONGOING'), color: M4Theme.premiumBlue),
                const SizedBox(height: 8),
                Text(
                  (project?['title']?.toString() ?? 'PROJECT NAME').toUpperCase(),
                  style: GoogleFonts.dmSerifDisplay(color: Colors.white, fontSize: 24, height: 1),
                ),
                const SizedBox(height: 4),
                Row(
                  children: [
                    const Icon(LucideIcons.mapPin, color: Colors.white70, size: 10),
                    const SizedBox(width: 4),
                    Text(
                      ((project?['location'] is Map ? project?['location']?['name'] : project?['location'])?.toString() ?? 'MAZGAON').toUpperCase(),
                      style: GoogleFonts.montserrat(color: Colors.white70, fontSize: 8, fontWeight: FontWeight.bold, letterSpacing: 1),
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

  Widget _buildMediaQuickActions(dynamic project, bool isDark) {
    final apiClient = ref.read(apiClientProvider);
    final heroUrl = apiClient.resolveUrl(project?['heroImage'] ?? project?['coverImage'] ?? (project?['heroImages'] as List?)?.first ?? '');
    
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 24),
      child: Row(
        children: [
          _HeroMediaThumb(
            label: 'EXTERIOR', 
            imageUrl: heroUrl, 
            onTap: () => _openHeroGallery(project, 'EXTERIOR')
          ),
          const SizedBox(width: 12),
          _HeroMediaThumb(
            label: 'INTERIOR', 
            imageUrl: heroUrl, 
            onTap: () => _openHeroGallery(project, 'INTERIOR')
          ),
          const SizedBox(width: 12),
          _HeroMediaThumb(
            label: '360° VIEW', 
            isVR: true, 
            onTap: () => _launchAction('Virtual Tour coming soon!', project?['threeSixtyUrl'] ?? project?['virtualTourUrl']),
          ),
        ],
      ),
    );
  }


  Widget _buildSectionHeader(String title) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    return Row(
      children: [
        Container(width: 24, height: 1, color: M4Theme.premiumBlue),
        const SizedBox(width: 12),
        Text(title.toUpperCase(), style: GoogleFonts.montserrat(fontSize: 11, fontWeight: FontWeight.w900, color: isDark ? Colors.white : Colors.black, letterSpacing: 3)),
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
          ('Experience the pinnacle of luxury living with floor-to-ceiling windows, Italian marble flooring, and smart home automation. ${project?['description'] ?? ''}').toString().trim().toUpperCase(),
          style: GoogleFonts.montserrat(
            fontSize: 11, 
            color: isDark ? Colors.white.withOpacity(0.9) : Colors.black, 
            height: 1.8, 
            fontWeight: FontWeight.w900,
            letterSpacing: 0.2
          ),
        ),
        const SizedBox(height: 32),
        _MultimediaAssetCard(
          title: 'PROJECT FLYER',
          subtitle: 'HIGH RES • PDF',
          icon: LucideIcons.fileText,
          onView: () => _launchAction('Opening...', project?['flyer']),
          onDownload: () => _launchAction('Downloading...', project?['flyer']),
        ),
        const SizedBox(height: 12),
        _MultimediaAssetCard(
          title: 'E-BROCHURE',
          subtitle: 'FULL SHOWCASE • PDF',
          icon: LucideIcons.layers,
          onView: () => _launchAction('Opening...', project?['brochure']),
          onDownload: () => _launchAction('Downloading...', project?['brochure']),
        ),
        const SizedBox(height: 12),
        _MultimediaAssetCard(
          title: 'WALKTHROUGH',
          subtitle: 'CINEMATIC TOUR • 4K',
          icon: LucideIcons.video,
          isPrimary: true,
          onView: () => _launchAction('Watching Story...', project?['walkthrough']),
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
          estimatedCompletion: project?['estimatedCompletion'] ?? 'Q1 2029',
          phases: _progressPhases,
          onPhaseTap: (img) => _showMediaLightbox(img, 'IMAGE'),
          showFullDesc: _showFullProgressDesc,
          onToggle: () => setState(() => _showFullProgressDesc = !_showFullProgressDesc),
        ),
      ],
    );
  }

  Widget _buildPricingSection(dynamic project) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        _buildSectionHeader('Financials'),
        const SizedBox(height: 24),
        _PriceHighlightCard(price: project?['startingPrice']?.toString() ?? 'Price on Request'),
        const SizedBox(height: 16),
        if (project?['paymentPlans'] != null)
           ...((project?['paymentPlans'] as List).map((plan) => _PaymentPlanCard(
             plan: plan, 
             onInquire: () => _showRequestDetailsDialog(project, plan),
           )).toList())
        else
          const _EmptyTabContent(message: 'Financial details available on request'),
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

  Widget _buildMediaGallerySection(dynamic project) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        _buildSectionHeader('Gallery'),
        const SizedBox(height: 24),
        _buildMedia(project),
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

  Widget _buildPlansSection(dynamic project) {
    final plans = project?['plans'] as List? ?? [];
    if (plans.isEmpty) return const SizedBox.shrink();
    final apiClient = ref.read(apiClientProvider);

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        _buildSectionHeader('Plans'),
        const SizedBox(height: 24),
        ...plans.map((plan) => _FloorPlanItem(
          plan: plan,
          imageUrl: apiClient.resolveUrl(plan['image']?.toString()),
          onLaunch: _launchAction,
          onView: _showMediaLightbox,
        )).toList(),
        const SizedBox(height: 32),
      ],
    );
  }

  Widget _buildDocumentsSection(dynamic project) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        _buildSectionHeader('Documents'),
        const SizedBox(height: 24),
        _buildDocuments(project),
      ],
    );
  }


  Widget _buildOverview(dynamic project) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
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
            (project?['description'] ?? 'Experience luxurious living redefined with M4 Family. Our projects blend architectural excellence with modern comforts to create homes that inspire.').toString().toUpperCase(),
            style: GoogleFonts.montserrat(
              fontSize: 12, 
              color: isDark ? Colors.white.withOpacity(0.9) : Colors.black, 
              height: 1.8, 
              fontWeight: FontWeight.w900,
              letterSpacing: 0.2
            ),
            maxLines: _showFullOverviewDesc ? null : 3,
            overflow: _showFullOverviewDesc ? TextOverflow.visible : TextOverflow.ellipsis,
          ),
          const SizedBox(height: 12),
          GestureDetector(
            onTap: () => setState(() => _showFullOverviewDesc = !_showFullOverviewDesc),
            child: Text(
              _showFullOverviewDesc ? 'Read less' : 'Read more',
              style: GoogleFonts.montserrat(fontSize: 12, fontWeight: FontWeight.w900, color: isDark ? Colors.white : Colors.black, decoration: TextDecoration.underline),
            ),
          ),
          const SizedBox(height: 32),
          // Multimedia Assets Header
          Row(
            children: [
              Container(padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4), decoration: BoxDecoration(color: M4Theme.premiumBlue.withOpacity(0.1), borderRadius: BorderRadius.circular(6)), child: Text('RESOURCES', style: GoogleFonts.montserrat(textStyle: const TextStyle(inherit: true), fontSize: 8, fontWeight: FontWeight.w900, color: M4Theme.premiumBlue, letterSpacing: 1))),
            ],
          ),
          const SizedBox(height: 16),
          // Project Assets (Flyer, Brochure, Walkthrough)
          _MultimediaAssetCard(
            title: 'PROJECT FLYER',
            subtitle: 'HIGH RES • PDF',
            icon: LucideIcons.fileText,
            onView: () => _launchAction('Opening Flyer...', project?['flyer']),
            onDownload: () => _launchAction('Downloading Flyer...', project?['flyer']),
          ),
          const SizedBox(height: 12),
          _MultimediaAssetCard(
            title: 'E-BROCHURE',
            subtitle: 'FULL SHOWCASE • PDF',
            icon: LucideIcons.layers,
            onView: () => _launchAction('Opening Brochure...', project?['brochure']),
            onDownload: () => _launchAction('Downloading Brochure...', project?['brochure']),
          ),
          const SizedBox(height: 12),
          _MultimediaAssetCard(
            title: 'WALKTHROUGH',
            subtitle: 'CINEMATIC TOUR • 4K',
            icon: LucideIcons.video,
            isPrimary: true,
            onView: () => _launchAction('Opening Walkthrough...', project?['walkthrough']),
          ),
          const SizedBox(height: 32),
          // Action Grid (Completion, Config, VC, Site Visit) - Moved here from appBar for parity
          GridView.count(
            shrinkWrap: true,
            physics: const NeverScrollableScrollPhysics(),
            crossAxisCount: 2,
            mainAxisSpacing: 10,
            crossAxisSpacing: 10,
            childAspectRatio: 2.2,
            children: [
              _OverviewActionCard(label: 'COMPLETION', value: '${project?['completion'] ?? 0}%', icon: LucideIcons.checkCircle2),
              _OverviewActionCard(label: 'CONFIG', value: project?['config'] ?? '3 & 4 BHK', icon: LucideIcons.layout),
              _OverviewActionCard(label: 'VIDEO CALL', value: 'CONNECT NOW', icon: LucideIcons.video, isAction: true, onTap: () => _launchAction('Connecting to Video Call...', project?['videoCallUrl'])),
              _OverviewActionCard(label: 'SITE VISIT', value: 'BOOK TOUR', icon: LucideIcons.eye, isAction: true, onTap: () => _launchAction('Opening Schedule Flow...', project?['siteVisitUrl'])),
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
            color: isDark ? const Color(0xFF1E1F21).withOpacity(0.4) : Colors.black.withOpacity(0.03),
            borderRadius: BorderRadius.circular(20),
            border: Border.all(color: isDark ? Colors.white.withOpacity(0.05) : Colors.black.withOpacity(0.05)),
          ),
          padding: const EdgeInsets.all(8),
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Container(
                width: 36,
                height: 36,
                decoration: BoxDecoration(
                  color: isDark ? Colors.white.withOpacity(0.05) : Colors.black.withOpacity(0.04),
                  shape: BoxShape.circle,
                ),
                child: Icon(_getAmenityIcon(name), color: isDark ? Colors.white : Colors.black, size: 16),
              ),
              const SizedBox(height: 8),
              Text(
                name,
                textAlign: TextAlign.center,
                style: GoogleFonts.montserrat(
                  fontSize: 7, 
                  fontWeight: FontWeight.w900, 
                  color: isDark ? Colors.white.withOpacity(0.8) : Colors.black.withOpacity(0.8), 
                  letterSpacing: 0.5,
                  height: 1.1
                ),
                maxLines: 2,
                overflow: TextOverflow.ellipsis,
              ),
            ],
          ),
        );
      },
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
               onInquire: () => _showRequestDetailsDialog(project, plan),
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
              onInquire: () => _showRequestDetailsDialog(project, {'name': '80/20 STANDARD PLAN'}),
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
    if (_inventory.isEmpty && !_isLoading) return const _EmptyTabContent(message: 'Coming soon');
    if (_isLoading) return const Center(child: CircularProgressIndicator(color: Colors.white24));

    return Column(
      children: _inventory.map((unit) => _InventoryItem(
        unit: unit,
        onTap: () => _showBookingOptionsDialog(project),
      )).toList(),
    );
  }

  Widget _buildUpdates(dynamic project) {
    if (_isLoading) return const Center(child: CircularProgressIndicator(color: Colors.white24));

    final overallProgress = (project?['completion'] ?? 0);
    final estimatedCompletion = project?['estimatedCompletionDate'] ?? 'Q1 2028';

    return _buildTabContent(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              _SectionHeader(title: 'CONSTRUCTION PROGRESS'),
              const _Badge(text: 'LIVE TRACKING', isOutline: true),
            ],
          ),
          const SizedBox(height: 24),
          
          // Construction Dashboard Card
          _ConstructionDashboardCard(
            overallProgress: overallProgress,
            estimatedCompletion: estimatedCompletion,
            phases: _progressPhases,
            onPhaseTap: (url) => _showMediaLightbox(url, 'IMAGE'),
            showFullDesc: _showFullProgressDesc,
            onToggle: () => setState(() => _showFullProgressDesc = !_showFullProgressDesc),
          ),

          const SizedBox(height: 32),
          _SectionHeader(title: 'RECENT LOGS'),
          const SizedBox(height: 20),
          if (_updates.isEmpty)
             const _EmptyTabContent(message: 'Site logs will appear once construction reaches next milestone')
          else
            ..._updates.map((update) => _ConstructionUpdateCard(
              update: update,
              imageUrl: ref.read(apiClientProvider).resolveUrl(update['image']?.toString()),
            )).toList(),
        ],
      ),
    );
  }

  Widget _buildLocation(dynamic project) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final apiClient = ref.read(apiClientProvider);
    final locName = (project?['location'] is Map ? project?['location']?['name'] : project?['location'])?.toString() ?? 'Mazgaon, Mumbai';
    
    return _buildTabContent(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const SizedBox(height: 0),
          _ScaleButton(
            onTap: () => _launchAction('Opening Maps...', 'https://www.google.com/maps?q=${Uri.encodeComponent(locName)}'),
            child: Container(
              height: 220,
              width: double.infinity,
              decoration: BoxDecoration(
                color: isDark ? const Color(0xFF1E1F21) : const Color(0xFFF4F4F5),
                borderRadius: BorderRadius.circular(32),
                border: Border.all(color: isDark ? Colors.white.withOpacity(0.05) : Colors.black.withOpacity(0.05)),
              ),
              child: ClipRRect(
                borderRadius: BorderRadius.circular(32),
                child: Stack(
                  fit: StackFit.expand,
                  children: [
                    Image.network(
                      'https://images.unsplash.com/photo-1524661135-423995f22d0b?auto=format&fit=crop&q=80', // Map-like artistic placeholder
                      fit: BoxFit.cover,
                      color: isDark ? Colors.black.withOpacity(0.6) : Colors.white.withOpacity(0.6),
                      colorBlendMode: BlendMode.dstATop,
                    ),
                    Center(
                      child: Column(
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: [
                          Icon(LucideIcons.mapPin, color: M4Theme.premiumBlue, size: 40),
                          const SizedBox(height: 12),
                          Text(locName.toUpperCase(), style: GoogleFonts.montserrat(fontSize: 10, fontWeight: FontWeight.w900, color: isDark ? Colors.white : Colors.black, letterSpacing: 2)),
                        ],
                      ),
                    ),
                  ],
                ),
              ),
            ),
          ),
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
              onView: _showMediaLightbox,
            )).toList())
          else
            const _EmptyTabContent(message: 'Floor plans and layouts are being finalized'),
        ],
      ),
    );
  }

  Widget _buildMedia(dynamic project) {
    final allMedia = project?['media'] as List? ?? [];
    final List<dynamic> filteredMedia = allMedia;
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final apiClient = ref.read(apiClientProvider);

    if (filteredMedia.isEmpty) return const _EmptyTabContent(message: 'Coming soon');

    return Column(
      children: [
        GridView.builder(
          shrinkWrap: true,
          physics: const NeverScrollableScrollPhysics(),
          padding: EdgeInsets.zero,
          gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
            crossAxisCount: 2,
            mainAxisSpacing: 12,
            crossAxisSpacing: 12,
            childAspectRatio: 1.3,
          ),
          itemCount: filteredMedia.length,
          itemBuilder: (context, index) {
            final item = filteredMedia[index];
            final type = (item['type'] ?? 'Image').toString().toUpperCase();
            final isVideo = type == 'VIDEO' || type == 'VIDEO_THUMBNAIL';
            final url = apiClient.resolveUrl(item['url']?.toString());
            
            final allUrls = filteredMedia.map((m) => m['url']?.toString() ?? '').where((u) => u.isNotEmpty).toList();
            
            return _ScaleButton(
              onTap: () => _showMediaLightbox(allUrls, isVideo ? 'VIDEO' : 'IMAGE', index),
              child: Container(
                decoration: BoxDecoration(
                  borderRadius: BorderRadius.circular(20),
                  border: Border.all(color: isDark ? Colors.white.withOpacity(0.05) : Colors.black.withOpacity(0.05)),
                ),
                child: ClipRRect(
                  borderRadius: BorderRadius.circular(20),
                  child: Stack(
                    fit: StackFit.expand,
                    children: [
                      CachedNetworkImage(
                        imageUrl: url,
                        fit: BoxFit.cover,
                        placeholder: (context, url) => Container(color: isDark ? Colors.white10 : Colors.black.withOpacity(0.05)),
                        errorWidget: (context, url, error) => Container(color: isDark ? Colors.white10 : Colors.black.withOpacity(0.05)),
                      ),
                      if (isVideo)
                        const Center(child: Icon(LucideIcons.playCircle, color: Colors.white, size: 40)),
                    ],
                  ),
                ),
              ),
            );
          },
        ),
      ],
    );
  }

  Widget _buildDocuments(dynamic project) {
    final docs = project?['documents'] as List? ?? [];
    return _buildTabContent(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
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

  Widget _buildTabContent({required Widget child}) {
    return Padding(
      padding: const EdgeInsets.fromLTRB(24, 0, 24, 32),
      child: child,
    );
  }

  Widget _buildBottomActions(dynamic project) {
    return Positioned(
      bottom: 40,
      left: 20,
      right: 20,
      child: Container(
        height: 80,
        padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 12),
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(30),
          boxShadow: [
            BoxShadow(color: Colors.black.withOpacity(0.2), blurRadius: 40, offset: const Offset(0, 20)),
          ],
        ),
        child: Row(
          children: [
            _BottomIconAction(
              icon: LucideIcons.phone, 
              onTap: () => SupportHandlers.launchCall(project?['phone'] ?? project?['contactPhone']),
            ),
            const SizedBox(width: 12),
            _BottomIconAction(
              icon: LucideIcons.messageSquare, 
              onTap: () => SupportHandlers.launchWhatsApp(project?['whatsapp'] ?? project?['phone'] ?? project?['contactPhone']),
            ),
            const SizedBox(width: 12),
            Expanded(
              child: _ScaleButton(
                onTap: () => Navigator.push(
                  context,
                  MaterialPageRoute(
                    builder: (context) => BookingStartScreen(
                      projectId: widget.projectId,
                      project: project,
                    ),
                  ),
                ).then((_) {
                  // If they came back from a 'Send Inquiry' action (if we implement that bridge)
                }),
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
    return LucideIcons.sparkles;
  }
}

// Helper Widgets
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
  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    
    return GestureDetector(
      onTap: onTap,
      child: Container(
        padding: const EdgeInsets.all(16),
        decoration: BoxDecoration(
          color: isDark ? const Color(0xFF1E1F21) : const Color(0xFFF8F9FA),
          borderRadius: BorderRadius.circular(20),
          border: Border.all(color: isDark ? Colors.white.withOpacity(0.05) : Colors.black.withOpacity(0.03)),
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            Row(
              children: [
                Icon(icon, size: 14, color: isAction ? M4Theme.premiumBlue : (isDark ? Colors.white24 : Colors.black26)),
                const SizedBox(width: 8),
                Text(
                  label.toUpperCase(), 
                  style: GoogleFonts.montserrat(fontSize: 8, fontWeight: FontWeight.w900, color: isDark ? Colors.white38 : Colors.black38, letterSpacing: 0.5)
                ),
              ],
            ),
            Text(
              value.toUpperCase(), 
              style: GoogleFonts.montserrat(fontSize: 13, fontWeight: FontWeight.w900, color: isDark ? Colors.white : Colors.black, letterSpacing: -0.2)
            ),
          ],
        ),
      ),
    );
  }
}

class _Badge extends StatelessWidget {
  final String text;
  final bool isOutline;
  final Color? color;
  const _Badge({required this.text, this.isOutline = false, this.color});

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
      decoration: BoxDecoration(
        color: color ?? Colors.white.withOpacity(0.4),
        borderRadius: BorderRadius.circular(10),
        border: Border.all(color: color?.withOpacity(0.2) ?? Colors.white.withOpacity(0.4)),
      ),
      child: Text(
        text,
        style: GoogleFonts.montserrat(
          fontSize: 8,
          fontWeight: FontWeight.w900,
          color: color != null ? Colors.white : Colors.black.withOpacity(0.7),
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
    final isDark = Theme.of(context).brightness == Brightness.dark;
    return Padding(
      padding: const EdgeInsets.only(bottom: 24),
      child: Row(
        children: [
          Container(
            padding: const EdgeInsets.all(12),
            decoration: BoxDecoration(
              color: isDark ? Colors.white.withOpacity(0.05) : Colors.black.withOpacity(0.04), 
              borderRadius: BorderRadius.circular(15)
            ),
            child: Icon(icon, color: isDark ? Colors.white38 : Colors.black38, size: 20),
          ),
          const SizedBox(width: 16),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(title, style: GoogleFonts.montserrat(fontSize: 13, fontWeight: FontWeight.bold, color: isDark ? Colors.white : Colors.black)),
                Text(distance.toUpperCase(), style: GoogleFonts.montserrat(fontSize: 10, fontWeight: FontWeight.w900, color: isDark ? Colors.white24 : Colors.black26, letterSpacing: 0.5)),
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
  final Function(String, String) onView;
  
  const _FloorPlanItem({
    required this.plan, 
    required this.imageUrl, 
    required this.onLaunch,
    required this.onView,
  });
  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    return Container(
       margin: const EdgeInsets.only(bottom: 16),
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: isDark ? const Color(0xFF1E1F21) : Colors.black.withOpacity(0.04), 
        borderRadius: BorderRadius.circular(24), 
        border: Border.all(color: isDark ? Colors.white.withOpacity(0.05) : Colors.black.withOpacity(0.05))
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          GestureDetector(
            onTap: () => onView(imageUrl, 'IMAGE'),
            child: ClipRRect(
              borderRadius: BorderRadius.circular(16), 
              child: CachedNetworkImage(
                imageUrl: imageUrl, 
                fit: BoxFit.cover, 
                height: 200, 
                width: double.infinity,
                placeholder: (context, url) => Container(height: 200, color: Colors.black12),
                errorWidget: (context, url, error) => Container(
                  height: 200, 
                  color: isDark ? Colors.white.withOpacity(0.05) : Colors.black.withOpacity(0.05), 
                  child: Center(child: Icon(LucideIcons.image, color: isDark ? Colors.white.withOpacity(0.1) : Colors.black.withOpacity(0.1)))
                ),
              ),
            ),
          ),
          const SizedBox(height: 16),
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text((plan['title'] ?? 'Floor Plan').toUpperCase(), style: GoogleFonts.montserrat(fontSize: 12, fontWeight: FontWeight.w900, color: isDark ? Colors.white : Colors.black, letterSpacing: 0.5)),
                    if (plan['area'] != null && plan['area'].toString().isNotEmpty)
                      Text(plan['area'].toUpperCase(), style: GoogleFonts.montserrat(fontSize: 8, fontWeight: FontWeight.bold, color: isDark ? Colors.white24 : Colors.black26, letterSpacing: 1)),
                  ],
                ),
              ),
              GestureDetector(
                onTap: () => onLaunch('Downloading Floor Plan...', imageUrl),
                child: Icon(LucideIcons.download, color: isDark ? Colors.white38 : Colors.black38, size: 18),
              ),
            ],
          ),
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
    final isDark = Theme.of(context).brightness == Brightness.dark;
    return Center(child: Text(message, textAlign: TextAlign.center, style: GoogleFonts.montserrat(fontSize: 12, color: isDark ? Colors.white38 : Colors.black38)));
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
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final displayPrice = price.contains('₹') || price.contains('AED') || price.contains('\$') 
        ? price 
        : '$currency $price';

    return Container(
      padding: const EdgeInsets.all(24),
      decoration: BoxDecoration(
        color: isDark ? const Color(0xFF1E1F21) : Colors.white,
        borderRadius: BorderRadius.circular(30),
        border: Border.all(color: isDark ? Colors.white.withOpacity(0.05) : Colors.black.withOpacity(0.05)),
        boxShadow: isDark ? [] : [BoxShadow(color: Colors.black.withOpacity(0.05), blurRadius: 20, offset: const Offset(0, 10))],
      ),
      child: Column(
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Expanded(
                child: Text(config.toUpperCase(), 
                  style: GoogleFonts.montserrat(fontSize: 14, fontWeight: FontWeight.w900, color: isDark ? Colors.white : Colors.black),
                  overflow: TextOverflow.ellipsis,
                ),
              ),
              _Badge(text: 'BOOKING OPEN', isOutline: true),
            ],
          ),
          const SizedBox(height: 12),
          Divider(color: isDark ? Colors.white.withOpacity(0.05) : Colors.black.withOpacity(0.05)),
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
                    Text('STARTING FROM', style: GoogleFonts.montserrat(fontSize: 8, fontWeight: FontWeight.bold, color: isDark ? Colors.white38 : Colors.black38, letterSpacing: 1)),
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
                    Text('SBA RANGE', style: GoogleFonts.montserrat(fontSize: 8, fontWeight: FontWeight.bold, color: isDark ? Colors.white38 : Colors.black38, letterSpacing: 1)),
                    Text(area, textAlign: TextAlign.right, style: GoogleFonts.montserrat(fontSize: 11, fontWeight: FontWeight.bold, color: isDark ? Colors.white.withOpacity(0.8) : Colors.black.withOpacity(0.7))),
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
  final VoidCallback onInquire;
  const _PaymentPlanCard({required this.plan, required this.onInquire});

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final steps = plan['items'] as List? ?? plan['steps'] as List? ?? [];
    return Container(
      margin: const EdgeInsets.only(bottom: 20),
      padding: const EdgeInsets.all(24),
      decoration: BoxDecoration(
        color: isDark ? const Color(0xFF1E1F21) : const Color(0xFFF4F4F5),
        borderRadius: BorderRadius.circular(32),
        border: Border.all(color: isDark ? Colors.white.withOpacity(0.05) : Colors.black.withOpacity(0.05)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Text(plan['name']?.toString().toUpperCase() ?? 'PLAN', style: GoogleFonts.montserrat(fontSize: 11, fontWeight: FontWeight.w900, color: isDark ? Colors.white : Colors.black, letterSpacing: 1)),
              _Badge(text: plan['status']?.toString().toUpperCase() ?? 'ACTIVE', color: const Color(0xFF10B981)),
            ],
          ),
          const SizedBox(height: 32),
          ...List.generate(steps.length, (index) {
            final step = steps[index];
            return Padding(
              padding: const EdgeInsets.only(bottom: 20),
              child: Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Text(
                    (step['description'] ?? step['label'] ?? '').toString().toUpperCase(), 
                    style: GoogleFonts.montserrat(fontSize: 9, fontWeight: FontWeight.w900, color: isDark ? Colors.white70 : Colors.black, letterSpacing: 0.5)
                  ),
                  Text(
                    (step['percentage'] != null ? '${step['percentage']}%' : step['value'] ?? '').toString(), 
                    style: GoogleFonts.montserrat(fontSize: 11, fontWeight: FontWeight.w900, color: isDark ? Colors.white : Colors.black)
                  ),
                ],
              ),
            );
          }),
          const SizedBox(height: 12),
          _ScaleButton(
            onTap: onInquire,
            child: Container(
              padding: const EdgeInsets.symmetric(vertical: 16),
              decoration: BoxDecoration(
                color: isDark ? Colors.white : Colors.black,
                borderRadius: BorderRadius.circular(16),
              ),
              child: Row(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Text('REQUEST DETAILS', style: GoogleFonts.montserrat(fontSize: 9, fontWeight: FontWeight.w900, letterSpacing: 2, color: isDark ? Colors.black : Colors.white)),
                  const SizedBox(width: 8),
                  Icon(LucideIcons.arrowUpRight, size: 14, color: isDark ? Colors.black : Colors.white),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }
}

class _InventoryItem extends StatelessWidget {
  final dynamic unit;
  final VoidCallback onTap;
  const _InventoryItem({required this.unit, required this.onTap});

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final currency = unit?['currency'] ?? 'AED';
    
    return _ScaleButton(
      onTap: onTap,
      child: Container(
        margin: const EdgeInsets.only(bottom: 16),
        padding: const EdgeInsets.all(20),
        decoration: BoxDecoration(
          color: isDark ? const Color(0xFF1E1F21) : Colors.white.withOpacity(0.6),
          borderRadius: BorderRadius.circular(24),
          border: Border.all(color: isDark ? Colors.white.withOpacity(0.05) : Colors.white.withOpacity(0.6)),
        ),
        child: Column(
          children: [
            Row(
              children: [
                Container(
                  padding: const EdgeInsets.all(12),
                  decoration: BoxDecoration(
                    color: isDark ? Colors.white.withOpacity(0.05) : Colors.black.withOpacity(0.04), 
                    borderRadius: BorderRadius.circular(15)
                  ),
                  child: Icon(LucideIcons.home, color: isDark ? Colors.white : Colors.black, size: 20),
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
                CachedNetworkImage(
                  imageUrl: imageUrl, 
                  height: 180, 
                  width: double.infinity, 
                  fit: BoxFit.cover,
                  placeholder: (context, url) => Container(height: 180, color: Colors.black12),
                  errorWidget: (context, url, error) => Container(height: 180, color: Colors.black.withOpacity(0.05), child: Center(child: Icon(LucideIcons.image, color: Colors.black.withOpacity(0.1)))),
                ),
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

class _SocialIconButton extends StatelessWidget {
  final IconData icon;
  final VoidCallback onTap;
  const _SocialIconButton({required this.icon, required this.onTap});

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    return _ScaleButton(
      onTap: onTap,
      child: Container(
        padding: const EdgeInsets.all(12),
        decoration: BoxDecoration(
          color: isDark ? Colors.white.withOpacity(0.05) : Colors.black.withOpacity(0.04),
          borderRadius: BorderRadius.circular(15),
          border: Border.all(color: isDark ? Colors.white.withOpacity(0.05) : Colors.black.withOpacity(0.05)),
        ),
        child: Icon(icon, color: isDark ? Colors.white : Colors.black, size: 20),
      ),
    );
  }
}
class _HeroMediaThumb extends StatelessWidget {
  final String label;
  final String? imageUrl;
  final bool isVR;
  final VoidCallback onTap;

  const _HeroMediaThumb({
    required this.label, 
    this.imageUrl, 
    this.isVR = false, 
    required this.onTap
  });

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    return _ScaleButton(
      onTap: onTap,
      child: Container(
        width: 68,
        height: 68,
        decoration: BoxDecoration(
          color: isDark ? const Color(0xFF1E1F21) : Colors.white,
          borderRadius: BorderRadius.circular(18),
          border: Border.all(color: isDark ? Colors.white.withOpacity(0.1) : Colors.black.withOpacity(0.08), width: 1.5),
          boxShadow: [
            BoxShadow(color: Colors.black.withOpacity(0.15), blurRadius: 10, offset: const Offset(0, 4)),
          ],
        ),
        clipBehavior: Clip.antiAlias,
        child: Stack(
          fit: StackFit.expand,
          children: [
            if (isVR)
              Container(
                color: isDark ? const Color(0xFF1E1F21) : Colors.white,
                child: Center(
                  child: Column(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Container(
                        padding: const EdgeInsets.all(8),
                        decoration: BoxDecoration(
                          shape: BoxShape.circle,
                          border: Border.all(color: isDark ? Colors.white24 : Colors.black26, width: 1.5),
                        ),
                        child: Icon(LucideIcons.refreshCw, color: isDark ? Colors.white : Colors.black, size: 16),
                      ),
                      const SizedBox(height: 4),
                      Text('360° VIEW', style: GoogleFonts.montserrat(fontSize: 7, fontWeight: FontWeight.w900, color: isDark ? Colors.white : Colors.black)),
                    ],
                  ),
                ),
              )
            else if (imageUrl != null)
              CachedNetworkImage(
                imageUrl: imageUrl!, 
                fit: BoxFit.cover,
                placeholder: (context, url) => Container(color: isDark ? Colors.white10 : Colors.black.withOpacity(0.1)),
                errorWidget: (context, url, error) => Container(color: isDark ? Colors.white10 : Colors.black.withOpacity(0.1)),
              ),
            
            if (!isVR) ...[
              // Gradient Overlay for text readability
              Positioned.fill(
                child: Container(
                  decoration: BoxDecoration(
                    gradient: LinearGradient(
                      begin: Alignment.topCenter,
                      end: Alignment.bottomCenter,
                      stops: const [0.5, 1.0],
                      colors: [
                        Colors.transparent,
                        Colors.black.withOpacity(0.7),
                      ],
                    ),
                  ),
                ),
              ),
              Positioned(
                bottom: 8,
                left: 0,
                right: 0,
                child: Text(
                  label,
                  textAlign: TextAlign.center,
                  style: GoogleFonts.montserrat(
                    fontSize: 7, 
                    fontWeight: FontWeight.w900, 
                    color: Colors.white,
                    letterSpacing: 0.5,
                  ),
                ),
              ),
            ],
          ],
        ),
      ),
    );
  }
}


class _MultimediaAssetCard extends StatelessWidget {
  final String title;
  final String subtitle;
  final IconData icon;
  final bool isPrimary;
  final VoidCallback onView;
  final VoidCallback? onDownload;

  const _MultimediaAssetCard({
    required this.title, 
    required this.subtitle, 
    required this.icon, 
    this.isPrimary = false, 
    required this.onView, 
    this.onDownload
  });

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: isDark ? const Color(0xFF1E1F21) : const Color(0xFFF4F4F5),
        borderRadius: BorderRadius.circular(24),
        border: Border.all(color: isDark ? Colors.white.withOpacity(0.05) : Colors.black.withOpacity(0.05)),
      ),
      child: Row(
        children: [
          Container(
            width: 44,
            height: 44,
            decoration: BoxDecoration(
              color: isPrimary ? (isDark ? M4Theme.premiumBlue.withOpacity(0.2) : M4Theme.premiumBlue.withOpacity(0.1)) : (isDark ? Colors.white.withOpacity(0.05) : Colors.black.withOpacity(0.04)),
              borderRadius: BorderRadius.circular(12),
            ),
            child: Icon(icon, color: isPrimary ? M4Theme.premiumBlue : (isDark ? Colors.white : Colors.black), size: 18),
          ),
          const SizedBox(width: 16),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(title.toUpperCase(), style: GoogleFonts.montserrat(fontSize: 9, fontWeight: FontWeight.w900, color: isDark ? Colors.white : Colors.black, letterSpacing: 0.5)),
                const SizedBox(height: 2),
                Text(subtitle.toUpperCase(), style: GoogleFonts.montserrat(fontSize: 7, fontWeight: FontWeight.w700, color: isDark ? Colors.white38 : Colors.black38, letterSpacing: 0.5)),
              ],
            ),
          ),
          const SizedBox(width: 8),
          Row(
            children: [
               _ScaleButton(
                onTap: onView,
                child: Container(
                  padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 8),
                  decoration: BoxDecoration(
                    color: Colors.transparent,
                    borderRadius: BorderRadius.circular(8),
                    border: Border.all(color: isDark ? Colors.white24 : Colors.black12),
                  ),
                  child: Text('VIEW', style: GoogleFonts.montserrat(fontSize: 8, fontWeight: FontWeight.w900, color: isDark ? Colors.white : Colors.black)),
                ),
              ),
              if (onDownload != null) ...[
                const SizedBox(width: 8),
                _ScaleButton(
                  onTap: onDownload!,
                  child: Container(
                    padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 8),
                    decoration: BoxDecoration(
                      color: isDark ? Colors.white : Colors.black,
                      borderRadius: BorderRadius.circular(8),
                    ),
                    child: Text('DOWNLOAD', style: GoogleFonts.montserrat(fontSize: 8, fontWeight: FontWeight.w900, color: isDark ? Colors.black : Colors.white)),
                  ),
                ),
              ],
              if (isPrimary) ...[
                const SizedBox(width: 8),
                _ScaleButton(
                  onTap: onView,
                  child: Container(
                    padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 8),
                    decoration: BoxDecoration(
                      color: M4Theme.premiumBlue,
                      borderRadius: BorderRadius.circular(8),
                    ),
                    child: Text('WATCH STORY', style: GoogleFonts.montserrat(fontSize: 8, fontWeight: FontWeight.w900, color: Colors.white)),
                  ),
                ),
              ],
            ],
          ),
        ],
      ),
    );
  }
}


class _ConstructionDashboardCard extends ConsumerWidget {
  final int overallProgress;
  final String estimatedCompletion;
  final List<dynamic> phases;
  final Function(String) onPhaseTap;
  final bool showFullDesc;
  final VoidCallback onToggle;

  const _ConstructionDashboardCard({
    required this.overallProgress, 
    required this.estimatedCompletion, 
    required this.phases, 
    required this.onPhaseTap,
    required this.showFullDesc,
    required this.onToggle,
  });

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final apiClient = ref.read(apiClientProvider);
    final isDark = Theme.of(context).brightness == Brightness.dark;
    
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(24),
      decoration: BoxDecoration(
        color: isDark ? const Color(0xFF1E1F21) : const Color(0xFFF4F4F5),
        borderRadius: BorderRadius.circular(32),
        border: Border.all(color: isDark ? Colors.white.withOpacity(0.05) : Colors.black.withOpacity(0.05)),
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
                    Text('ESTIMATED COMPLETION', style: GoogleFonts.montserrat(fontSize: 10, fontWeight: FontWeight.w900, color: M4Theme.premiumBlue, letterSpacing: 1)),
                    const SizedBox(height: 8),
                    Text(estimatedCompletion.toUpperCase(), style: GoogleFonts.dmSerifDisplay(fontSize: 40, color: isDark ? Colors.white : Colors.black, height: 1)),
                    const SizedBox(height: 16),
                    Text(
                      'As the project progresses, significant milestones are reached, showcasing our team\'s dedication and expertise. We are steadily moving closer to our completion goal, ensuring quality and safety at every step. Each phase is handled with precision to meet our luxury standards and timeline.',
                      style: GoogleFonts.montserrat(
                        fontSize: 11, 
                        color: isDark ? Colors.white38 : Colors.black38, 
                        height: 1.6, 
                        fontWeight: FontWeight.w500
                      ),
                      maxLines: showFullDesc ? null : 3,
                      overflow: showFullDesc ? TextOverflow.visible : TextOverflow.ellipsis,
                    ),
                    const SizedBox(height: 8),
                    GestureDetector(
                      onTap: onToggle,
                      child: Text(
                        showFullDesc ? 'Show less' : 'Read more',
                        style: GoogleFonts.montserrat(
                          fontSize: 11,
                          fontWeight: FontWeight.w900,
                          color: M4Theme.premiumBlue,
                        ),
                      ),
                    ),
                  ],
                ),
              ),
              const SizedBox(width: 20),
              Stack(
                alignment: Alignment.center,
                children: [
                  SizedBox(
                    width: 70,
                    height: 70,
                    child: CircularProgressIndicator(
                      value: overallProgress.toDouble() / 100,
                      strokeWidth: 4,
                      backgroundColor: isDark ? Colors.white.withOpacity(0.05) : Colors.black.withOpacity(0.05),
                      valueColor: const AlwaysStoppedAnimation<Color>(M4Theme.premiumBlue),
                    ),
                  ),
                  Column(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Text('${overallProgress.toInt()}%', style: GoogleFonts.montserrat(fontSize: 14, fontWeight: FontWeight.w900, color: isDark ? Colors.white : Colors.black)),
                      Text('OVERALL', style: GoogleFonts.montserrat(fontSize: 6, fontWeight: FontWeight.w900, color: isDark ? Colors.white38 : Colors.black38)),
                    ],
                  ),
                ],
              ),
            ],
          ),
          const SizedBox(height: 48),
          SingleChildScrollView(
            scrollDirection: Axis.horizontal,
            child: Row(
              children: phases.map((phase) {
                final imageUrl = apiClient.resolveUrl(phase['image'] ?? (phase['images'] as List?)?.first);
                return Container(
                  width: 260,
                  margin: const EdgeInsets.only(right: 16),
                  decoration: BoxDecoration(
                    color: isDark ? Colors.black.withOpacity(0.2) : Colors.white,
                    borderRadius: BorderRadius.circular(24),
                    border: Border.all(color: isDark ? Colors.white.withOpacity(0.05) : Colors.black.withOpacity(0.05)),
                  ),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      _ScaleButton(
                        onTap: () => onPhaseTap(imageUrl),
                        child: ClipRRect(
                          borderRadius: const BorderRadius.vertical(top: Radius.circular(24)),
                          child: CachedNetworkImage(
                            imageUrl: imageUrl, 
                            height: 180, 
                            width: 260, 
                            fit: BoxFit.cover, 
                            placeholder: (context, url) => Container(height: 180, width: 260, color: Colors.white10),
                            errorWidget: (context, url, error) => Container(height: 180, width: 260, color: Colors.white10),
                          ),
                        ),
                      ),
                      Padding(
                        padding: const EdgeInsets.all(20),
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(
                              phase['name']?.toString().toUpperCase() ?? 'INITIAL PHASE', 
                              style: GoogleFonts.montserrat(
                                fontSize: 11, 
                                fontWeight: FontWeight.w900, 
                                color: isDark ? Colors.white : Colors.black, 
                                letterSpacing: 1
                              )
                            ),
                            const SizedBox(height: 12),
                            Row(
                              children: [
                                SizedBox(
                                  width: 24,
                                  height: 24,
                                  child: CircularProgressIndicator(
                                    value: (phase['progressPercent'] ?? phase['progress'] ?? 0).toDouble() / 100,
                                    strokeWidth: 2,
                                    backgroundColor: isDark ? Colors.white10 : Colors.black.withOpacity(0.05),
                                    valueColor: const AlwaysStoppedAnimation<Color>(M4Theme.premiumBlue),
                                  ),
                                ),
                                const SizedBox(width: 12),
                                Text(
                                  '${phase['progressPercent'] ?? phase['progress'] ?? 0}% COMPLETED', 
                                  style: GoogleFonts.montserrat(
                                    fontSize: 9, 
                                    fontWeight: FontWeight.w800, 
                                    color: isDark ? Colors.white38 : Colors.black38
                                  )
                                ),
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
      ),
    );
  }
}

class _CircularProgressPainter extends CustomPainter {
  final double progress;
  final Color color;

  _CircularProgressPainter({required this.progress, required this.color});

  @override
  void paint(Canvas canvas, Size size) {
    final center = Offset(size.width / 2, size.height / 2);
    final radius = size.width / 2;
    const strokeWidth = 5.0;

    final backgroundPaint = Paint()
      ..color = color.withOpacity(0.05)
      ..style = PaintingStyle.stroke
      ..strokeWidth = strokeWidth;

    canvas.drawCircle(center, radius, backgroundPaint);

    final progressPaint = Paint()
      ..color = color
      ..style = PaintingStyle.stroke
      ..strokeWidth = strokeWidth
      ..strokeCap = StrokeCap.round;

    final rect = Rect.fromCircle(center: center, radius: radius);
    canvas.drawArc(rect, -1.5708, 6.2832 * progress, false, progressPaint);
  }

  @override
  bool shouldRepaint(CustomPainter oldDelegate) => true;
}
class _MediaFloatThumbnail extends StatelessWidget {
  final String label;
  final String image;
  final bool is360;
  final VoidCallback onTap;

  const _MediaFloatThumbnail({required this.label, required this.image, this.is360 = false, required this.onTap});

  @override
  Widget build(BuildContext context) {
    return Column(
      children: [
        GestureDetector(
          onTap: onTap,
          child: Container(
            width: 50,
            height: 50,
            decoration: BoxDecoration(
              borderRadius: BorderRadius.circular(12),
              border: Border.all(color: Colors.white, width: 2),
            ),
            child: Stack(
              children: [
                ClipRRect(
                  borderRadius: BorderRadius.circular(10),
                  child: CachedNetworkImage(
                    imageUrl: image, 
                    fit: BoxFit.cover,
                    width: double.infinity,
                    height: double.infinity,
                    placeholder: (context, url) => Container(color: Colors.black12),
                    errorWidget: (context, url, error) => Container(color: Colors.black12),
                  ),
                ),
                if (is360) const Center(child: Icon(LucideIcons.rotateCcw, color: Colors.white, size: 20)),
              ],
            ),
          ),
        ),
        const SizedBox(height: 2),
        Text(label, style: GoogleFonts.montserrat(color: Colors.white, fontSize: 6, fontWeight: FontWeight.w900, letterSpacing: 0.5)),
      ],
    );
  }
}

class _PriceHighlightCard extends StatelessWidget {
  final String price;
  const _PriceHighlightCard({required this.price});

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(32),
      decoration: BoxDecoration(
        color: isDark ? const Color(0xFF1E1F21) : const Color(0xFFF4F4F5),
        borderRadius: BorderRadius.circular(32),
        border: Border.all(color: isDark ? Colors.white.withOpacity(0.05) : Colors.black.withOpacity(0.05)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text('STARTING PRICE', style: GoogleFonts.montserrat(fontSize: 9, fontWeight: FontWeight.w900, color: isDark ? Colors.white38 : Colors.black38, letterSpacing: 2)),
          const SizedBox(height: 12),
          Text(price.toUpperCase(), style: GoogleFonts.montserrat(fontSize: 24, fontWeight: FontWeight.w900, color: isDark ? Colors.white : Colors.black, height: 1, letterSpacing: -0.5)),
        ],
      ),
    );
  }
}


class _PlanRow extends StatelessWidget {
  final String label;
  final String value;
  const _PlanRow({required this.label, required this.value});

  @override
  Widget build(BuildContext context) {
    return Row(
      mainAxisAlignment: MainAxisAlignment.spaceBetween,
      children: [
        Text(label.toUpperCase(), style: GoogleFonts.montserrat(color: Colors.white70, fontSize: 8, fontWeight: FontWeight.w900, letterSpacing: 1)),
        Text(value, style: GoogleFonts.montserrat(color: Colors.white, fontSize: 10, fontWeight: FontWeight.bold)),
      ],
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
    return GestureDetector(
      onTap: onTap,
      child: Container(
        padding: const EdgeInsets.all(12),
        decoration: BoxDecoration(
          color: isDark ? Colors.white.withOpacity(0.1) : Colors.white,
          shape: BoxShape.circle,
          boxShadow: [
            BoxShadow(
              color: Colors.black.withOpacity(0.1),
              blurRadius: 10,
              offset: const Offset(0, 4),
            ),
          ],
          border: Border.all(color: isDark ? Colors.white.withOpacity(0.1) : Colors.black.withOpacity(0.05)),
        ),
        child: Icon(icon, size: 20, color: color ?? (isDark ? Colors.white : Colors.black)),
      ),
    );
  }
}
