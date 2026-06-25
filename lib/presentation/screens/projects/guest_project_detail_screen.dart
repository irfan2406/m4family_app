import 'package:dio/dio.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter/material.dart';
import 'package:flutter/cupertino.dart';
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
import 'package:m4_mobile/presentation/widgets/sidebar_menu.dart';
import 'package:m4_mobile/presentation/widgets/luxury_amenity_icon.dart';
import 'package:go_router/go_router.dart';
import 'package:cached_network_image/cached_network_image.dart';
import 'package:webview_flutter/webview_flutter.dart';

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

class _GuestProjectDetailScreenState extends ConsumerState<GuestProjectDetailScreen> {
  List<dynamic> _paymentPlans = [];
  dynamic _fullProject;
  List<dynamic> _updates = [];
  List<dynamic> _inventory = [];
  List<dynamic> _progressPhases = [];
  List<String> _interiorImages = [];
  List<String> _exteriorImages = [];
  bool _isLoading = true;
  final TextEditingController _nameController = TextEditingController();
  final TextEditingController _phoneController = TextEditingController();
  final TextEditingController _emailController = TextEditingController();
  final TextEditingController _locationController = TextEditingController();
  bool _isFavorited = false;
  String _mediaFilter = 'ALL';
  String _selectedConfig = '3 BHK';
  bool _showFullOverview = false;
  bool _showFullProgress = false;
  // Booking dialog (web parity): visit type toggle + scheduled date/time + notes.
  String _leadType = 'VC';
  DateTime? _leadDate;
  TimeOfDay? _leadTime;
  final TextEditingController _notesController = TextEditingController();
  final GlobalKey<ScaffoldState> _scaffoldKey = GlobalKey<ScaffoldState>();

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
            // Extract interior and exterior images
            final media = _fullProject?['media'] as List? ?? [];
            
            // Extract exterior images (matching web logic)
            final List<String> ext = [];
            if (_fullProject?['exteriorImages'] != null) {
              ext.addAll((_fullProject!['exteriorImages'] as List).map((e) => e.toString()));
            }
            ext.addAll(media
                .where((m) => m['category']?.toString().toUpperCase() == 'EXTERIOR')
                .map((m) => m['url'].toString()));
            _exteriorImages = ext.toSet().toList(); // Remove duplicates

            // Extract interior images (matching web logic)
            final List<String> int = [];
            if (_fullProject?['interiorImages'] != null) {
              int.addAll((_fullProject!['interiorImages'] as List).map((e) => e.toString()));
            }
            int.addAll(media
                .where((m) => m['category']?.toString().toUpperCase() == 'INTERIOR')
                .map((m) => m['url'].toString()));
            _interiorImages = int.toSet().toList(); // Remove duplicates
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

  void _launchAction(String message, [String? url, bool isError = false]) async {
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
        content: Text(message, style: GoogleFonts.montserrat(fontSize: 12, fontWeight: FontWeight.bold, color: isError ? Colors.white : Colors.black)),
        backgroundColor: isError ? const Color(0xFFDC2626) : M4Theme.premiumBlue,
        behavior: SnackBarBehavior.floating,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
      ),
    );
  }

  // iOS-style wheel date+time picker (matches the web IOSDateTimePicker).
  Future<DateTime?> _pickIosDateTime(DateTime initial) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final minDate = DateTime.now().subtract(const Duration(minutes: 1));
    if (initial.isBefore(minDate)) initial = DateTime.now().add(const Duration(minutes: 30));
    DateTime temp = initial;
    return showModalBottomSheet<DateTime>(
      context: context,
      backgroundColor: Colors.transparent,
      builder: (sheetCtx) => Container(
        height: 340,
        decoration: BoxDecoration(
          color: isDark ? const Color(0xFF0B111E) : Colors.white,
          borderRadius: const BorderRadius.vertical(top: Radius.circular(28)),
        ),
        child: Column(
          children: [
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
              child: Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  TextButton(
                    onPressed: () => Navigator.pop(sheetCtx),
                    child: Text('CANCEL', style: GoogleFonts.montserrat(fontSize: 11, fontWeight: FontWeight.w900, color: isDark ? Colors.white54 : Colors.black54, letterSpacing: 1)),
                  ),
                  Text('SCHEDULE', style: GoogleFonts.montserrat(fontSize: 10, fontWeight: FontWeight.w900, color: isDark ? Colors.white : Colors.black, letterSpacing: 2)),
                  TextButton(
                    onPressed: () => Navigator.pop(sheetCtx, temp),
                    child: Text('DONE', style: GoogleFonts.montserrat(fontSize: 11, fontWeight: FontWeight.w900, color: M4Theme.premiumBlue, letterSpacing: 1)),
                  ),
                ],
              ),
            ),
            Divider(height: 1, color: isDark ? Colors.white12 : Colors.black12),
            Expanded(
              child: CupertinoTheme(
                data: CupertinoThemeData(
                  brightness: isDark ? Brightness.dark : Brightness.light,
                  textTheme: CupertinoTextThemeData(
                    dateTimePickerTextStyle: GoogleFonts.montserrat(fontSize: 17, fontWeight: FontWeight.w700, color: isDark ? Colors.white : Colors.black),
                  ),
                ),
                child: CupertinoDatePicker(
                  mode: CupertinoDatePickerMode.dateAndTime,
                  initialDateTime: initial,
                  minimumDate: minDate,
                  use24hFormat: false,
                  onDateTimeChanged: (dt) => temp = dt,
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  @override
  void dispose() {
    _nameController.dispose();
    _phoneController.dispose();
    _emailController.dispose();
    _locationController.dispose();
    _notesController.dispose();
    super.dispose();
  }

  Future<void> _submitInquiry(String type, [String? plan]) async {
    final name = _nameController.text.trim();
    final phone = _phoneController.text.trim();
    if (name.isEmpty || phone.isEmpty) {
      _launchAction('Please enter your name and phone number', null, true);
      return;
    }
    final isBooking = type == 'VC' || type == 'Site Visit';
    // Web parity: a Video Call / Site Visit requires a scheduled date + time.
    if (isBooking && (_leadDate == null || _leadTime == null)) {
      _launchAction('Please schedule a date and time for your visit', null, true);
      return;
    }

    setState(() => _isLoading = true);
    try {
      final apiClient = ref.read(apiClientProvider);
      final project = _fullProject ?? widget.projectData;
      final interest = type == 'VC' ? 'Video Call' : type == 'Site Visit' ? 'Site Visit' : 'General Enquiry';

      String? visitDate;
      String? visitTime;
      if (isBooking && _leadDate != null) {
        final d = _leadDate!;
        visitDate = '${d.year}-${d.month.toString().padLeft(2, '0')}-${d.day.toString().padLeft(2, '0')}';
        visitTime = _leadTime?.format(context);
      }
      final notes = _notesController.text.trim();

      final res = await apiClient.submitLead({
        'name': name,
        'phone': phone,
        'email': _emailController.text.trim().isNotEmpty ? _emailController.text.trim() : null,
        'interest': interest,
        'configuration': _selectedConfig,
        if (visitDate != null) 'visitDate': visitDate,
        if (visitTime != null) 'visitTime': visitTime,
        if (notes.isNotEmpty) 'notes': notes,
        'location': _locationController.text.trim().isNotEmpty ? _locationController.text.trim() : null,
        'source': 'mobile_app',
        'projectId': widget.projectId,
        'project': project?['title'] ?? 'General',
        'message': isBooking
            ? 'Requested $interest for ${project?['title']}'
            : 'Express interest in ${project?['title']}${_locationController.text.trim().isNotEmpty ? ' • Location: ${_locationController.text.trim()}' : ''}',
      });

      if (res.data['status'] == true) {
        if (mounted) {
          Navigator.pop(context);
          _launchAction(isBooking ? 'Booking request received! Our team will call you to confirm the time.' : 'Interest registered! Our team will contact you shortly.', null);
        }
      } else {
        _launchAction(res.data['message'] ?? 'Failed to submit', null, true);
      }
    } catch (e) {
      _launchAction('Connection error. Please try again.', null, true);
    } finally {
      if (mounted) setState(() => _isLoading = false);
    }
  }

  void _showRequestDetailsDialog(dynamic project, [dynamic plan, String type = 'General']) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final planName = plan is Map ? plan['name']?.toString() : plan?.toString();
    final projectTitle = project?['title'] ?? 'this project';

    final authUser = ref.read(authProvider).user;
    if (authUser != null) {
      _nameController.text = authUser['fullName']?.toString() ?? authUser['username']?.toString() ?? '';
      _phoneController.text = authUser['phone']?.toString() ?? '';
      _emailController.text = authUser['email']?.toString() ?? '';
    }
    // Reset booking state for this open (web: leadType/date/time/notes).
    _leadType = type == 'Site Visit' ? 'Site Visit' : 'VC';
    _leadDate = null;
    _leadTime = null;
    _notesController.clear();

    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (context) => StatefulBuilder(
        builder: (context, setModalState) => Container(
          padding: EdgeInsets.only(bottom: MediaQuery.of(context).viewInsets.bottom + 20),
          decoration: BoxDecoration(
            color: isDark ? const Color(0xFF0B111E) : Colors.white,
            borderRadius: const BorderRadius.vertical(top: Radius.circular(40)),
          ),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              const SizedBox(height: 12),
              Container(width: 40, height: 4, decoration: BoxDecoration(color: isDark ? Colors.white24 : Colors.black12, borderRadius: BorderRadius.circular(2))),
              Align(
                alignment: Alignment.topRight,
                child: IconButton(
                  onPressed: () {
                    if (Navigator.canPop(context)) {
                      Navigator.pop(context);
                    } else {
                      Navigator.pushReplacementNamed(context, '/guest/home');
                    }
                  },
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
                      _leadType == 'VC' ? 'BOOK A VIDEO CALL' : 'BOOK A SITE VISIT',
                      style: GoogleFonts.montserrat(fontSize: 26, fontWeight: FontWeight.w900, color: isDark ? Colors.white : Colors.black, height: 1.1, letterSpacing: -1),
                    ),
                    const SizedBox(height: 16),
                    Text(
                      'A BESPOKE SHOWCASE OF LUXURY AT ${projectTitle.toUpperCase()}.',
                      style: GoogleFonts.montserrat(fontSize: 9, color: isDark ? Colors.white38 : Colors.black38, fontWeight: FontWeight.w900, letterSpacing: 1),
                    ),
                    const SizedBox(height: 40),
                    
                    _buildInquiryField('Full Name', _nameController, LucideIcons.user),
                    const SizedBox(height: 16),
                    _buildInquiryField('Email Address', _emailController, LucideIcons.mail),
                    const SizedBox(height: 16),
                    _buildInquiryField('Phone Number', _phoneController, LucideIcons.phone),
                    
                    const SizedBox(height: 28),
                    // Visit Type toggle (web parity)
                    Text('VISIT TYPE', style: GoogleFonts.montserrat(fontSize: 8, fontWeight: FontWeight.w900, color: isDark ? Colors.white54 : Colors.black54, letterSpacing: 1.5)),
                    const SizedBox(height: 10),
                    Container(
                      padding: const EdgeInsets.all(4),
                      decoration: BoxDecoration(
                        color: isDark ? Colors.white.withValues(alpha: 0.05) : Colors.black.withValues(alpha: 0.04),
                        borderRadius: BorderRadius.circular(12),
                        border: Border.all(color: isDark ? Colors.white.withValues(alpha: 0.08) : Colors.black.withValues(alpha: 0.06)),
                      ),
                      child: Row(
                        children: [
                          for (final opt in const [['Site Visit', 'Site Visit'], ['Video Call', 'VC']])
                            Expanded(
                              child: GestureDetector(
                                onTap: () => setModalState(() => _leadType = opt[1]),
                                child: Container(
                                  alignment: Alignment.center,
                                  padding: const EdgeInsets.symmetric(vertical: 12),
                                  decoration: BoxDecoration(
                                    color: _leadType == opt[1] ? (isDark ? Colors.white : Colors.black) : Colors.transparent,
                                    borderRadius: BorderRadius.circular(9),
                                  ),
                                  child: Text(
                                    opt[0].toUpperCase(),
                                    style: GoogleFonts.montserrat(fontSize: 9, fontWeight: FontWeight.w900, letterSpacing: 1, color: _leadType == opt[1] ? (isDark ? Colors.black : Colors.white) : (isDark ? Colors.white54 : Colors.black54)),
                                  ),
                                ),
                              ),
                            ),
                        ],
                      ),
                    ),
                    const SizedBox(height: 20),
                    // Schedule date + time (web parity: IOSDateTimePicker)
                    Text('SCHEDULE', style: GoogleFonts.montserrat(fontSize: 8, fontWeight: FontWeight.w900, color: isDark ? Colors.white54 : Colors.black54, letterSpacing: 1.5)),
                    const SizedBox(height: 10),
                    GestureDetector(
                      onTap: () async {
                        final initial = _leadDate != null
                            ? DateTime(_leadDate!.year, _leadDate!.month, _leadDate!.day, _leadTime?.hour ?? 10, _leadTime?.minute ?? 0)
                            : DateTime.now().add(const Duration(hours: 1));
                        final dt = await _pickIosDateTime(initial);
                        if (dt != null) {
                          setModalState(() {
                            _leadDate = DateTime(dt.year, dt.month, dt.day);
                            _leadTime = TimeOfDay(hour: dt.hour, minute: dt.minute);
                          });
                        }
                      },
                      child: Container(
                        padding: const EdgeInsets.symmetric(horizontal: 18, vertical: 16),
                        decoration: BoxDecoration(
                          color: isDark ? Colors.white.withValues(alpha: 0.03) : const Color(0xFFF8FAFC),
                          borderRadius: BorderRadius.circular(12),
                          border: Border.all(color: isDark ? Colors.white.withValues(alpha: 0.08) : Colors.black.withValues(alpha: 0.08)),
                        ),
                        child: Row(
                          children: [
                            const Icon(LucideIcons.calendar, size: 16, color: M4Theme.premiumBlue),
                            const SizedBox(width: 12),
                            Expanded(
                              child: Text(
                                _leadDate == null
                                    ? 'SELECT DATE & TIME'
                                    : '${_leadDate!.day}/${_leadDate!.month}/${_leadDate!.year}   ${_leadTime?.format(context) ?? ''}',
                                style: GoogleFonts.montserrat(fontSize: 11, fontWeight: FontWeight.w800, color: isDark ? Colors.white : Colors.black, letterSpacing: 0.5),
                              ),
                            ),
                            Icon(LucideIcons.chevronRight, size: 16, color: isDark ? Colors.white38 : Colors.black38),
                          ],
                        ),
                      ),
                    ),
                    const SizedBox(height: 20),
                    // Additional notes (web parity)
                    Text('ADDITIONAL NOTES', style: GoogleFonts.montserrat(fontSize: 8, fontWeight: FontWeight.w900, color: isDark ? Colors.white54 : Colors.black54, letterSpacing: 1.5)),
                    const SizedBox(height: 10),
                    Container(
                      padding: const EdgeInsets.symmetric(horizontal: 18, vertical: 4),
                      decoration: BoxDecoration(
                        color: isDark ? Colors.white.withValues(alpha: 0.03) : const Color(0xFFF8FAFC),
                        borderRadius: BorderRadius.circular(12),
                        border: Border.all(color: isDark ? Colors.white.withValues(alpha: 0.08) : Colors.black.withValues(alpha: 0.08)),
                      ),
                      child: TextField(
                        controller: _notesController,
                        maxLines: 3,
                        style: GoogleFonts.montserrat(fontSize: 11, fontWeight: FontWeight.bold, color: isDark ? Colors.white : Colors.black),
                        decoration: InputDecoration(
                          border: InputBorder.none,
                          hintText: 'SPECIFIC REQUIREMENTS, PICKUP DETAILS, ETC...',
                          hintStyle: GoogleFonts.montserrat(fontSize: 9, fontWeight: FontWeight.w800, color: isDark ? Colors.white24 : Colors.black26, letterSpacing: 0.5),
                        ),
                      ),
                    ),
                    
                    const SizedBox(height: 40),
                    _ScaleButton(
                      onTap: () => _submitInquiry(_leadType, planName),
                      child: Container(
                        width: double.infinity,
                        padding: const EdgeInsets.symmetric(vertical: 20),
                        decoration: BoxDecoration(
                          color: isDark ? Colors.white : Colors.black,
                          borderRadius: BorderRadius.circular(12),
                        ),
                        child: Center(
                          child: Text(
                            'CONFIRM BOOKING',
                            style: GoogleFonts.montserrat(color: isDark ? Colors.black : Colors.white, fontSize: 11, fontWeight: FontWeight.w900, letterSpacing: 1.5)
                          )
                        ),
                      ),
                    ),
                    const SizedBox(height: 24),
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
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 4),
      decoration: BoxDecoration(
        color: isDark ? Colors.white.withValues(alpha: 0.03) : const Color(0xFFF8FAFC),
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: isDark ? Colors.white.withValues(alpha: 0.08) : Colors.black.withValues(alpha: 0.08)),
      ),
      child: TextField(
        controller: controller,
        style: GoogleFonts.montserrat(fontSize: 12, fontWeight: FontWeight.bold, color: isDark ? Colors.white : Colors.black),
        decoration: InputDecoration(
          border: InputBorder.none,
          hintText: label,
          hintStyle: GoogleFonts.montserrat(fontSize: 11, color: isDark ? Colors.white24 : Colors.black26),
          contentPadding: const EdgeInsets.symmetric(vertical: 16),
        ),
      ),
    );
  }

  void _openHeroGallery(List<String> urls) {
    if (urls.isNotEmpty) {
      _showMediaLightbox(urls, 'IMAGE');
    } else {
      _launchAction('Gallery coming soon!', null);
    }
  }

  void _showMediaLightbox(List<String> urls, String type) {
    final apiClient = ref.read(apiClientProvider);
    final PageController pageController = PageController();
    
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
              PageView.builder(
                controller: pageController,
                itemCount: urls.length,
                itemBuilder: (context, index) {
                  return Center(
                    child: InteractiveViewer(
                      child: CachedNetworkImage(
                        imageUrl: apiClient.resolveUrl(urls[index]),
                        fit: BoxFit.contain,
                        placeholder: (context, url) => const Center(child: CircularProgressIndicator(color: Colors.white24)),
                        errorWidget: (context, url, error) => const Icon(LucideIcons.image, color: Colors.white24, size: 50),
                      ),
                    ),
                  );
                },
              ),
              if (urls.length > 1) ...[
                Positioned(
                  left: 10,
                  top: 0,
                  bottom: 0,
                  child: Center(
                    child: IconButton(
                      onPressed: () => pageController.previousPage(duration: const Duration(milliseconds: 300), curve: Curves.easeInOut),
                      icon: Icon(LucideIcons.chevronLeft, color: Colors.white.withValues(alpha: 0.4), size: 20),
                    ),
                  ),
                ),
                Positioned(
                  right: 10,
                  top: 0,
                  bottom: 0,
                  child: Center(
                    child: IconButton(
                      onPressed: () => pageController.nextPage(duration: const Duration(milliseconds: 300), curve: Curves.easeInOut),
                      icon: Icon(LucideIcons.chevronRight, color: Colors.white.withValues(alpha: 0.4), size: 20),
                    ),
                  ),
                ),
              ],
              Positioned(
                top: MediaQuery.of(context).padding.top + 20,
                right: 20,
                child: _CircleAction(
                  icon: LucideIcons.x, 
                  onTap: () => Navigator.pop(context),
                  color: Colors.white,
                ),
              ),
              if (urls.length > 1)
                Positioned(
                  bottom: 50,
                  left: 0,
                  right: 0,
                  child: Center(
                    child: Container(
                      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
                      decoration: BoxDecoration(
                        color: Colors.black.withValues(alpha: 0.5),
                        borderRadius: BorderRadius.circular(20),
                      ),
                      child: ListenableBuilder(
                        listenable: pageController,
                        builder: (context, child) {
                          final page = (pageController.hasClients ? (pageController.page?.round() ?? 0) : 0) + 1;
                          return Text(
                            '$page / ${urls.length}',
                            style: GoogleFonts.montserrat(color: Colors.white, fontSize: 12, fontWeight: FontWeight.bold),
                          );
                        },
                      ),
                    ),
                  ),
                ),
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
    final apiClient = ref.read(apiClientProvider);

    if (_isLoading && project == null) {
      return Scaffold(
        backgroundColor: isDark ? Colors.black : Colors.white,
        body: Center(
          child: CircularProgressIndicator(color: M4Theme.premiumBlue),
        ),
      );
    }

    return Scaffold(
      key: _scaffoldKey,
      backgroundColor: isDark ? M4Theme.background : Colors.white,
      drawer: SidebarMenu(),
      body: Stack(
        children: [
          SingleChildScrollView(
            physics: const BouncingScrollPhysics(),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                _buildHero(project, isDark),
                const SizedBox(height: 20),
                // Web parity: only show Exterior/Interior quick-access when those images exist.
                if (_exteriorImages.isNotEmpty || _interiorImages.isNotEmpty) ...[
                  Padding(
                    padding: const EdgeInsets.symmetric(horizontal: 24),
                    child: Row(
                      children: [
                        if (_exteriorImages.isNotEmpty)
                          _HeroMediaThumb(
                            label: 'EXTERIOR',
                            imageUrl: apiClient.resolveUrl(_exteriorImages.first),
                            onTap: () => _openHeroGallery(_exteriorImages),
                          ),
                        if (_exteriorImages.isNotEmpty && _interiorImages.isNotEmpty)
                          const SizedBox(width: 12),
                        if (_interiorImages.isNotEmpty)
                          _HeroMediaThumb(
                            label: 'INTERIOR',
                            imageUrl: apiClient.resolveUrl(_interiorImages.first),
                            onTap: () => _openHeroGallery(_interiorImages),
                          ),
                      ],
                    ),
                  ),
                  const SizedBox(height: 24),
                ],
                // Title + Location — web parity (below the hero, on the content bg)
                Padding(
                  padding: const EdgeInsets.symmetric(horizontal: 24),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        (project?['title']?.toString() ?? 'Project Name').toUpperCase(),
                        style: GoogleFonts.dmSerifDisplay(
                          color: isDark ? Colors.white : const Color(0xFF09090B),
                          fontSize: 28,
                          height: 1.0,
                          letterSpacing: -0.5,
                        ),
                      ),
                      const SizedBox(height: 12),
                      Container(
                        padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
                        decoration: BoxDecoration(
                          color: isDark ? Colors.white.withValues(alpha: 0.05) : Colors.black.withValues(alpha: 0.03),
                          borderRadius: BorderRadius.circular(12),
                          border: Border.all(color: isDark ? Colors.white.withValues(alpha: 0.08) : Colors.black.withValues(alpha: 0.08)),
                        ),
                        child: Row(
                          mainAxisSize: MainAxisSize.min,
                          children: [
                            Icon(LucideIcons.mapPin, color: isDark ? Colors.white70 : Colors.black87, size: 14),
                            const SizedBox(width: 6),
                            Text(
                              (project?['locationName'] ?? (project?['location'] is Map ? project?['location']?['name'] : project?['location']) ?? 'Mazgaon').toString(),
                              style: GoogleFonts.montserrat(
                                color: isDark ? Colors.white : Colors.black,
                                fontSize: 11,
                                fontWeight: FontWeight.w800,
                              ),
                            ),
                          ],
                        ),
                      ),
                    ],
                  ),
                ),
                const SizedBox(height: 24),
                Padding(
                  padding: const EdgeInsets.symmetric(horizontal: 24),
                  child: Row(
                    children: [
                      Expanded(child: _OverviewActionCard(label: 'VIDEO CALL', value: 'Connect Now', icon: LucideIcons.video, isAction: true, onTap: () => _showRequestDetailsDialog(project, null, 'VC'))),
                      const SizedBox(width: 10),
                      Expanded(child: _OverviewActionCard(label: 'COMPLETION', value: '${project?['completion'] ?? 0}%', icon: LucideIcons.checkCircle2)),
                      const SizedBox(width: 10),
                      Expanded(child: _OverviewActionCard(label: 'SITE VISIT', value: 'Book Tour', icon: LucideIcons.eye, isAction: true, onTap: () => _showRequestDetailsDialog(project, null, 'Site Visit'))),
                    ],
                  ),
                ),
                const SizedBox(height: 32),
                _buildOverviewSection(project),
                const SizedBox(height: 32),
                _buildAmenitiesSection(project),
                const SizedBox(height: 32),
                _buildConstructionSection(project),
                const SizedBox(height: 32),
                _buildPaymentPlansSection(),
                const SizedBox(height: 32),
                _buildInterestSection(project),
                const SizedBox(height: 32),
                _buildLocationSection(project),
                const SizedBox(height: 100),
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

    return AspectRatio(
      aspectRatio: 16 / 9,
      child: Stack(
        fit: StackFit.expand,
        children: [
          CachedNetworkImage(
            imageUrl: heroUrl, 
            fit: BoxFit.cover,
            placeholder: (context, url) => Container(color: Colors.black12),
            errorWidget: (context, url, error) => Container(
              color: const Color(0xFF1A1A1A),
              child: const Center(child: Icon(LucideIcons.building2, color: Colors.white24, size: 40)),
            ),
          ),
          Container(
            decoration: BoxDecoration(
              gradient: LinearGradient(
                begin: Alignment.topCenter,
                end: Alignment.bottomCenter,
                colors: [
                  Colors.black.withValues(alpha: 0.1),
                  Colors.transparent,
                  (isDark ? M4Theme.background : Colors.white).withValues(alpha: 0.9),
                  (isDark ? M4Theme.background : Colors.white),
                ],
                stops: const [0.0, 0.4, 0.85, 1.0],
              ),
            ),
          ),
          // Web parity: hero shows ONLY the status badge (bottom-left).
          Positioned(
            bottom: 24,
            left: 24,
            child: Container(
              padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 5),
              decoration: BoxDecoration(color: Colors.black, borderRadius: BorderRadius.circular(4)),
              child: Text(
                (project?['status']?.toString().toUpperCase() ?? 'ONGOING'),
                style: GoogleFonts.montserrat(color: Colors.white, fontSize: 8, fontWeight: FontWeight.w900, letterSpacing: 1.5),
              ),
            ),
          ),
          // Scrollable Header Actions (Match Web Absolute Logic)
          Positioned(
            top: MediaQuery.of(context).padding.top + 6,
            left: 16,
            right: 16,
            child: Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                _SquareAction(
                  icon: LucideIcons.chevronLeft, 
                  onTap: () {
                    if (context.canPop()) {
                      context.pop();
                    } else {
                      // Safety fallback if opened directly
                      context.go('/home');
                    }
                  }
                ),
                Row(
                  children: [
                    _SquareAction(
                      icon: LucideIcons.share2, 
                      onTap: () => Share.share('Check out ${project?['title']} on M4 Family!')
                    ),
                    const SizedBox(width: 8),
                    _SquareAction(
                      icon: LucideIcons.moreHorizontal, 
                      onTap: () => _scaffoldKey.currentState?.openDrawer()
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

  Widget _buildOverviewSection(dynamic project) {
    final flyerUrl = project?['flyer'] ?? project?['brochure'];
    final isDark = Theme.of(context).brightness == Brightness.dark;
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 24),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          _buildSectionHeader('Overview'),
          const SizedBox(height: 24),
          Text(
            'EXPERIENCE THE PINNACLE OF LUXURY LIVING WITH FLOOR-TO-CEILING WINDOWS, ITALIAN MARBLE FLOORING, AND SMART HOME AUTOMATION.',
            style: GoogleFonts.montserrat(
              fontSize: 11, 
              color: isDark ? Colors.white.withValues(alpha: 0.8) : Colors.black.withValues(alpha: 0.8), 
              fontWeight: FontWeight.w900,
              height: 1.6,
              letterSpacing: 0.5
            ),
          ),
          if (flyerUrl != null) ...[
            const SizedBox(height: 32),
            _MultimediaAssetCard(
              title: 'PROJECT FLYER',
              subtitle: 'HIGH RES • PDF',
              icon: LucideIcons.fileText,
              onView: () => _launchAction('Opening...', flyerUrl),
            ),
          ],
        ],
      ),
    );
  }

  Widget _buildSectionHeader(String title) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    return Row(
      children: [
        Container(width: 40, height: 1.5, color: isDark ? Colors.white : Colors.black),
        const SizedBox(width: 16),
        Text(
          title.toUpperCase(), 
          style: GoogleFonts.montserrat(
            fontSize: 12, 
            fontWeight: FontWeight.w900, 
            color: isDark ? Colors.white : Colors.black, 
            letterSpacing: 4
          )
        ),
      ],
    );
  }

  Widget _buildConstructionSection(dynamic project) {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 24),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          _buildSectionHeader('Construction Progress'),
          const SizedBox(height: 24),
          _ConstructionDashboardCard(
            // Web parity: overall % = average of phase progress (falls back to project.completion).
            overallProgress: _progressPhases.isNotEmpty
                ? (_progressPhases.fold<num>(0, (a, p) => a + ((p['progressPercent'] ?? p['progress'] ?? 0) as num)) / _progressPhases.length).round()
                : (project?['completion'] ?? 0),
            estimatedCompletion: (project?['estimatedCompletionDate'] ?? project?['possessionDate'] ?? 'Q1 2029').toString().toUpperCase(),
            phases: _progressPhases,
            showFullProgress: _showFullProgress,
            onToggleReadMore: () => setState(() => _showFullProgress = !_showFullProgress),
            onPhaseTap: (url) => _showMediaLightbox([url], 'IMAGE'),
            projectName: project?['title'] ?? 'PROJECT',
          ),
        ],
      ),
    );
  }

  Widget _buildAmenitiesSection(dynamic project) {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 24),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          _buildSectionHeader('Amenities'),
          const SizedBox(height: 24),
          _buildAmenities(project),
        ],
      ),
    );
  }

  Widget _buildLocationSection(dynamic project) {
     return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 24),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          _buildSectionHeader('Location'),
          const SizedBox(height: 24),
          _buildLocation(project),
        ],
      ),
    );
  }

  Widget _buildAmenities(dynamic project) {
    final amenitiesRaw = project?['amenities'] as List? ?? [];
    if (amenitiesRaw.isEmpty) return const _EmptyTabContent(message: 'Coming soon');
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final apiClient = ref.read(apiClientProvider);

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
        final rawIcon = amenity is Map ? amenity['icon']?.toString() : null;
        final hasUploadedIcon = rawIcon != null && rawIcon.isNotEmpty &&
            (rawIcon.startsWith('/') || rawIcon.startsWith('http') || rawIcon.contains('.'));

        // Web parity: full LuxuryAmenityIcon (uploaded icon -> name-mapped SVG -> Lucide).
        return Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            LuxuryAmenityIcon(
              name: name,
              iconUrl: hasUploadedIcon ? apiClient.resolveUrl(rawIcon) : null,
              size: 42,
            ),
            const SizedBox(height: 10),
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 4),
              child: Text(
                name,
                textAlign: TextAlign.center,
                maxLines: 2,
                overflow: TextOverflow.ellipsis,
                style: GoogleFonts.montserrat(
                  fontSize: 8.5,
                  fontWeight: FontWeight.w600,
                  color: isDark ? Colors.white.withValues(alpha: 0.8) : Colors.black.withValues(alpha: 0.8),
                  letterSpacing: 0.5,
                  height: 1.2,
                ),
              ),
            ),
          ],
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
    final rawLoc = (project?['location'] is Map ? project?['location']?['name'] : project?['location'])?.toString() ?? '';
    const defaultLoc = 'NA 604, 6th Floor, M4 Aura Heights, Grant Road, Mumbai - 400007';
    final invalid = rawLoc.trim().isEmpty || ['NA', 'N/A', 'NONE'].contains(rawLoc.trim().toUpperCase());
    final loc = invalid ? defaultLoc : rawLoc;

    // Web parity: embedded Google Map (iframe -> WebView) + View on Maps button.
    return _LocationMap(
      location: loc,
      onOpenMaps: () => _launchAction('Opening Maps...', 'https://www.google.com/maps?q=${Uri.encodeComponent(loc)}'),
    );

  }
  Widget _buildInterestSection(dynamic project) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 24),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          _buildSectionHeader('Express Interest'),
          const SizedBox(height: 16),
          Container(
            padding: const EdgeInsets.all(32),
            decoration: BoxDecoration(
              color: isDark ? const Color(0xFF0B111E) : Colors.white,
              borderRadius: BorderRadius.circular(24),
              border: Border.all(color: isDark ? Colors.white.withValues(alpha: 0.05) : Colors.black.withValues(alpha: 0.05)),
              boxShadow: isDark ? [] : [
                BoxShadow(
                  color: Colors.black.withValues(alpha: 0.05),
                  blurRadius: 20,
                  offset: const Offset(0, 10),
                )
              ],
            ),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text('INITIALIZE YOUR PREMIUM EXPERIENCE', style: GoogleFonts.montserrat(fontSize: 9, fontWeight: FontWeight.w900, color: M4Theme.premiumBlue, letterSpacing: 1.5)),
                const SizedBox(height: 24),
                _InterestInput(hint: 'FULL NAME *', controller: _nameController),
                const SizedBox(height: 16),
                _InterestInput(hint: 'EMAIL ADDRESS', controller: _emailController),
                const SizedBox(height: 16),
                _InterestInput(hint: 'PHONE NUMBER *', controller: _phoneController),
                const SizedBox(height: 16),
                _InterestInput(hint: 'YOUR LOCATION (E.G. DUBAI, UAE)', controller: _locationController),
                const SizedBox(height: 24),
                _ScaleButton(
                  onTap: () => _submitInquiry('General'),
                  child: Container(
                    width: double.infinity,
                    padding: const EdgeInsets.symmetric(vertical: 18),
                    decoration: BoxDecoration(
                      color: isDark ? Colors.white : Colors.black,
                      borderRadius: BorderRadius.circular(20),
                    ),
                    child: Center(child: Text('REGISTER INTEREST', style: GoogleFonts.montserrat(color: isDark ? Colors.black : Colors.white, fontSize: 10, fontWeight: FontWeight.w900, letterSpacing: 2))),
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildPaymentPlansSection() {
    if (_paymentPlans.isEmpty) return const SizedBox.shrink();
    final isDark = Theme.of(context).brightness == Brightness.dark;
    
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 24),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          _buildSectionHeader('Payment Plans'),
          const SizedBox(height: 16),
          ..._paymentPlans.map((plan) => Container(
            margin: const EdgeInsets.only(bottom: 16),
            padding: const EdgeInsets.all(24),
            decoration: BoxDecoration(
              color: isDark ? Colors.white.withValues(alpha: 0.03) : const Color(0xFFF1F5F9),
              borderRadius: BorderRadius.circular(32),
              border: Border.all(color: isDark ? Colors.white.withValues(alpha: 0.05) : Colors.black.withValues(alpha: 0.05)),
            ),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Text(plan['name']?.toString().toUpperCase() ?? 'STANDARD PLAN', style: GoogleFonts.montserrat(fontSize: 11, fontWeight: FontWeight.w900, color: isDark ? Colors.white : Colors.black, letterSpacing: 0.5)),
                    const Icon(LucideIcons.wallet, color: M4Theme.premiumBlue, size: 16),
                  ],
                ),
                const SizedBox(height: 24),
                ...(plan['items'] as List? ?? []).map((item) => Padding(
                  padding: const EdgeInsets.only(bottom: 12),
                  child: Row(
                    children: [
                      Container(
                        width: 40,
                        height: 40,
                        decoration: BoxDecoration(color: M4Theme.premiumBlue.withValues(alpha: 0.1), shape: BoxShape.circle),
                        child: Center(child: Text('${item['percentage']}%', style: GoogleFonts.montserrat(fontSize: 10, fontWeight: FontWeight.w900, color: M4Theme.premiumBlue))),
                      ),
                      const SizedBox(width: 16),
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(item['description']?.toString().toUpperCase() ?? 'INSTALLMENT', style: GoogleFonts.montserrat(fontSize: 9, fontWeight: FontWeight.w900, color: isDark ? Colors.white : Colors.black, letterSpacing: 0.5)),
                            Text('INSTALLMENT ${item['installmentNumber'] ?? ''}', style: GoogleFonts.montserrat(fontSize: 8, color: isDark ? Colors.white38 : Colors.black38, fontWeight: FontWeight.bold)),
                          ],
                        ),
                      ),
                    ],
                  ),
                )).toList(),
              ],
            ),
          )).toList(),
        ],
      ),
    );
  }

  String? _getCategoryThumbnail(dynamic project, String category) {
    if (category == 'EXTERIOR') return _exteriorImages.firstOrNull;
    if (category == 'INTERIOR') return _interiorImages.firstOrNull;
    return null;
  }
} // End of _GuestProjectDetailScreenState

class _InterestInput extends StatelessWidget {
  final String hint;
  final IconData? icon;
  final TextEditingController controller;
  const _InterestInput({required this.hint, this.icon, required this.controller});
  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 4),
      decoration: BoxDecoration(
        color: isDark ? Colors.white.withValues(alpha: 0.03) : const Color(0xFFF8FAFC),
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: isDark ? Colors.white.withValues(alpha: 0.08) : Colors.black.withValues(alpha: 0.08)),
      ),
      child: TextField(
        controller: controller,
        style: GoogleFonts.montserrat(fontSize: 11, fontWeight: FontWeight.bold, color: isDark ? Colors.white : Colors.black),
        decoration: InputDecoration(
          border: InputBorder.none,
          hintText: hint,
          hintStyle: GoogleFonts.montserrat(fontSize: 9, fontWeight: FontWeight.w900, color: isDark ? Colors.white24 : Colors.black26, letterSpacing: 1),
          icon: icon != null ? Icon(icon, size: 14, color: M4Theme.premiumBlue) : null,
        ),
      ),
    );
  }
}

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
        height: 140,
        padding: const EdgeInsets.symmetric(vertical: 24, horizontal: 8),
        decoration: BoxDecoration(
          color: isDark ? Colors.white.withValues(alpha: 0.05) : Colors.white,
          borderRadius: BorderRadius.circular(32),
          border: Border.all(
            color: isDark ? Colors.white.withValues(alpha: 0.08) : Colors.black.withValues(alpha: 0.05),
            width: 1,
          ),
          boxShadow: isDark ? [] : [
            BoxShadow(
              color: Colors.black.withValues(alpha: 0.05),
              blurRadius: 20,
              offset: const Offset(0, 10),
            )
          ],
        ),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            Icon(icon, color: isDark ? Colors.white38 : Colors.black38, size: 24),
            Column(
              children: [
                Text(
                  label.toUpperCase(), 
                  style: GoogleFonts.montserrat(
                    color: isDark ? Colors.white38 : Colors.black38, 
                    fontSize: 8, 
                    fontWeight: FontWeight.w900, 
                    letterSpacing: 1.5,
                  ),
                  textAlign: TextAlign.center,
                ),
                const SizedBox(height: 4),
                Text(
                  value, 
                  style: GoogleFonts.montserrat(
                    color: isDark ? Colors.white : Colors.black, 
                    fontSize: 14, 
                    fontWeight: FontWeight.w900, 
                    letterSpacing: -0.2,
                  ),
                  textAlign: TextAlign.center,
                ),
              ],
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
    return _ScaleButton(
      onTap: onTap,
      child: ClipRRect(
        borderRadius: BorderRadius.circular(30),
        child: BackdropFilter(
          filter: ImageFilter.blur(sigmaX: 10, sigmaY: 10),
          child: Container(
            padding: const EdgeInsets.all(14),
            decoration: BoxDecoration(
              color: Colors.black.withValues(alpha: 0.05),
              shape: BoxShape.circle,
            ),
            child: Icon(icon, size: 18, color: color ?? Colors.white),
          ),
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
        borderRadius: BorderRadius.circular(20),
        child: BackdropFilter(
          filter: ImageFilter.blur(sigmaX: 5, sigmaY: 5),
          child: Container(
            width: 60,
            height: 60,
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
                  CachedNetworkImage(
                    imageUrl: imageUrl!, 
                    fit: BoxFit.cover, 
                    errorWidget: (c, e, s) => Container(color: Colors.white10),
                    placeholder: (c, e) => Container(color: Colors.white10),
                  ),
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
            boxShadow: isDark ? [] : [
              BoxShadow(
                color: Colors.black.withValues(alpha: 0.05),
                blurRadius: 30,
                offset: const Offset(0, 10),
              )
            ],
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
        padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
        decoration: BoxDecoration(
          color: isOutline ? (isDark ? Colors.white : Colors.black) : (isDark ? Colors.white : Colors.black),
          borderRadius: BorderRadius.circular(10),
        ),
        child: Text(label, style: GoogleFonts.montserrat(fontSize: 7.5, fontWeight: FontWeight.w900, color: isDark ? Colors.black : Colors.white, letterSpacing: 1.0)),
      ),
    );
  }
}

class _ConstructionDashboardCard extends ConsumerWidget {
  final num overallProgress;
  final String estimatedCompletion;
  final List<dynamic> phases;
  final bool showFullProgress;
  final VoidCallback onToggleReadMore;
  final Function(String) onPhaseTap;
  final String projectName;

  const _ConstructionDashboardCard({
    required this.overallProgress, 
    required this.estimatedCompletion, 
    required this.phases,
    required this.showFullProgress,
    required this.onToggleReadMore,
    required this.onPhaseTap,
    required this.projectName,
  });

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final apiClient = ref.read(apiClientProvider);
    final isDark = Theme.of(context).brightness == Brightness.dark;
    
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.symmetric(horizontal: 32, vertical: 40),
      decoration: BoxDecoration(
        color: isDark ? const Color(0xFF0B111E) : const Color(0xFFF8FAFC),
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
                    Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          'As the project progresses, significant milestones are reached, showcasing our team\'s dedication and expertise. We are steadily moving closer to our completion goal, ensuring quality and safety at every step. Each phase is handled with precision to meet our luxury standards and timeline.',
                          maxLines: showFullProgress ? null : 3,
                          overflow: showFullProgress ? TextOverflow.visible : TextOverflow.ellipsis,
                          style: GoogleFonts.montserrat(
                            fontSize: 11, 
                            color: isDark ? Colors.white.withValues(alpha: 0.5) : Colors.black.withValues(alpha: 0.6), 
                            height: 1.6, 
                            fontWeight: FontWeight.bold
                          ),
                        ),
                        const SizedBox(height: 10),
                        GestureDetector(
                          onTap: onToggleReadMore,
                          child: Text(
                            showFullProgress ? 'Show less' : 'Read more',
                            style: GoogleFonts.montserrat(fontSize: 11, fontWeight: FontWeight.w900, color: M4Theme.premiumBlue),
                          ),
                        ),
                      ],
                    ),
                  ],
                ),
              ),
              const SizedBox(width: 24),
              Stack(
                alignment: Alignment.center,
                children: [
                  SizedBox(
                    width: 100,
                    height: 100,
                    child: CustomPaint(
                      painter: _DashedCirclePainter(
                        progress: overallProgress.toDouble() / 100,
                        color: M4Theme.premiumBlue,
                        backgroundColor: isDark ? Colors.white.withValues(alpha: 0.1) : Colors.black.withValues(alpha: 0.1),
                      ),
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
            // Timeline Slider
            Row(
              children: [
                Text('2026', style: GoogleFonts.montserrat(fontSize: 18, fontWeight: FontWeight.w900, color: M4Theme.premiumBlue)),
                const SizedBox(width: 16),
                Expanded(
                  child: Stack(
                    alignment: Alignment.centerLeft,
                    children: [
                      Container(height: 1, color: isDark ? Colors.white10 : Colors.black.withValues(alpha: 0.1)),
                      Container(
                        width: 12,
                        height: 12,
                        decoration: BoxDecoration(
                          color: isDark ? Colors.black : Colors.white,
                          shape: BoxShape.circle,
                          border: Border.all(color: M4Theme.premiumBlue, width: 2),
                        ),
                      ),
                    ],
                  ),
                ),
              ],
            ),
            const SizedBox(height: 32),
            SizedBox(
              height: 480,
              child: ListView.builder(
                scrollDirection: Axis.horizontal,
                padding: const EdgeInsets.symmetric(horizontal: 24),
                itemCount: phases.length,
                itemBuilder: (context, index) {
                  final phase = phases[index];
                  final phaseImages = phase['images'] as List?;
                  final firstPhaseImg = (phaseImages != null && phaseImages.isNotEmpty) ? phaseImages[0] : '';
                  final imageUrl = apiClient.resolveUrl(phase['image'] ?? firstPhaseImg);
                  final status = phase['status']?.toString().toUpperCase() ?? 'UPCOMING';
                  
                  return Container(
                    width: 300,
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
                          child: Stack(
                            children: [
                              ClipRRect(
                                borderRadius: const BorderRadius.vertical(top: Radius.circular(32)),
                                child: CachedNetworkImage(
                                  imageUrl: imageUrl, 
                                  height: 200, 
                                  width: 300, 
                                  fit: BoxFit.cover, 
                                  placeholder: (c, u) => Container(height: 200, color: Colors.white10),
                                  errorWidget: (c, e, s) => Container(height: 200, color: Colors.white10),
                                ),
                              ),
                              Positioned(
                                top: 16,
                                left: 16,
                                child: Container(
                                  padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                                  decoration: BoxDecoration(
                                    color: status == 'COMPLETED' ? Colors.green : (status == 'IN PROGRESS' ? M4Theme.premiumBlue : Colors.black54),
                                    borderRadius: BorderRadius.circular(4),
                                  ),
                                  child: Text(status, style: GoogleFonts.montserrat(fontSize: 8, fontWeight: FontWeight.w900, color: Colors.white, letterSpacing: 1)),
                                ),
                              ),
                            ],
                          ),
                        ),
                        Padding(
                          padding: const EdgeInsets.all(24),
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Text(projectName.toUpperCase(), style: GoogleFonts.dmSerifDisplay(fontSize: 12, fontWeight: FontWeight.bold, color: isDark ? Colors.white : const Color(0xFF0F172A), letterSpacing: 1)),
                              const SizedBox(height: 16),
                              Row(
                                children: [
                                  Stack(
                                    alignment: Alignment.center,
                                    children: [
                                      SizedBox(
                                        width: 36,
                                        height: 36,
                                        child: CircularProgressIndicator(
                                          value: (phase['progressPercent'] ?? phase['progress'] ?? 0).toDouble() / 100,
                                          strokeWidth: 3,
                                          backgroundColor: isDark ? Colors.white10 : Colors.black.withValues(alpha: 0.05),
                                          valueColor: const AlwaysStoppedAnimation<Color>(M4Theme.premiumBlue),
                                        ),
                                      ),
                                      Text('${phase['progressPercent'] ?? phase['progress'] ?? 0}%', style: GoogleFonts.montserrat(fontSize: 8, fontWeight: FontWeight.w900)),
                                    ],
                                  ),
                                  const SizedBox(width: 16),
                                  Expanded(child: Text((phase['name'] ?? phase['phaseName'] ?? 'PHASE').toString().toUpperCase(), style: GoogleFonts.montserrat(fontSize: 10, fontWeight: FontWeight.w900, color: isDark ? Colors.white.withValues(alpha: 0.7) : Colors.black.withValues(alpha: 0.7), letterSpacing: 1.5))),
                                ],
                              ),
                            ],
                          ),
                        ),
                      ],
                    ),
                  );
                },
              ),
            ),
          const SizedBox(height: 64),
            // Phase Tracking List
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text('PHASE TRACKING', style: GoogleFonts.montserrat(fontSize: 12, fontWeight: FontWeight.w900, letterSpacing: 2)),
                    Text('REAL-TIME DEVELOPMENT STATUS', style: GoogleFonts.montserrat(fontSize: 8, fontWeight: FontWeight.bold, color: isDark ? Colors.white38 : Colors.black38, letterSpacing: 0.5)),
                  ],
                ),
                Container(
                  padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
                  decoration: BoxDecoration(color: M4Theme.premiumBlue.withValues(alpha: 0.1), borderRadius: BorderRadius.circular(8)),
                  child: Text('${phases.length} MILESTONES', style: GoogleFonts.montserrat(fontSize: 8, fontWeight: FontWeight.w900, color: M4Theme.premiumBlue)),
                ),
              ],
            ),
            const SizedBox(height: 32),
            SizedBox(
              height: 140,
              child: ListView.builder(
                scrollDirection: Axis.horizontal,
                padding: const EdgeInsets.symmetric(horizontal: 24),
                itemCount: phases.length,
                itemBuilder: (context, index) {
                  final phase = phases[index];
                  final progress = (phase['progressPercent'] ?? phase['progress'] ?? 0).toDouble();
                  final status = phase['status']?.toString().toUpperCase() ?? 'UPCOMING';
                  
                  return Container(
                    width: 280,
                    margin: const EdgeInsets.only(right: 16),
                    padding: const EdgeInsets.all(20),
                    decoration: BoxDecoration(
                      color: isDark ? Colors.white.withValues(alpha: 0.03) : Colors.white,
                      borderRadius: BorderRadius.circular(24),
                      border: Border.all(color: isDark ? Colors.white.withValues(alpha: 0.05) : Colors.black.withValues(alpha: 0.05)),
                      boxShadow: isDark ? [] : [BoxShadow(color: Colors.black.withValues(alpha: 0.03), blurRadius: 15, offset: const Offset(0, 6))],
                    ),
                    child: Column(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        Row(
                          children: [
                            Container(
                              width: 36,
                              height: 36,
                              decoration: BoxDecoration(color: isDark ? Colors.white.withValues(alpha: 0.05) : const Color(0xFFF1F5F9), borderRadius: BorderRadius.circular(10)),
                              child: Center(child: Text((index + 1).toString().padLeft(2, '0'), style: GoogleFonts.montserrat(fontSize: 10, fontWeight: FontWeight.w900, color: isDark ? Colors.white38 : Colors.black38))),
                            ),
                            const SizedBox(width: 12),
                            Expanded(
                              child: Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  Text((phase['name'] ?? phase['phaseName'] ?? 'PHASE').toString().toUpperCase(), style: GoogleFonts.montserrat(fontSize: 11, fontWeight: FontWeight.w900, color: isDark ? Colors.white : const Color(0xFF1E293B))),
                                  Row(
                                    children: [
                                      Container(width: 6, height: 6, decoration: BoxDecoration(color: progress >= 100 ? Colors.green : (progress > 0 ? M4Theme.premiumBlue : Colors.grey), shape: BoxShape.circle)),
                                      const SizedBox(width: 6),
                                      Text(status, style: GoogleFonts.montserrat(fontSize: 8, fontWeight: FontWeight.bold, color: isDark ? Colors.white38 : Colors.black38, letterSpacing: 0.5)),
                                    ],
                                  ),
                                ],
                              ),
                            ),
                            Text('${progress.toInt()}%', style: GoogleFonts.montserrat(fontSize: 16, fontWeight: FontWeight.w900, color: isDark ? Colors.white : const Color(0xFF0F172A))),
                          ],
                        ),
                        const SizedBox(height: 12),
                        Stack(
                          children: [
                            Container(
                              height: 6,
                              width: double.infinity,
                              decoration: BoxDecoration(color: isDark ? Colors.white.withValues(alpha: 0.05) : const Color(0xFFF1F5F9), borderRadius: BorderRadius.circular(10)),
                            ),
                            TweenAnimationBuilder<double>(
                              duration: const Duration(milliseconds: 1500),
                              curve: Curves.easeOutQuart,
                              tween: Tween<double>(begin: 0, end: progress / 100),
                              builder: (context, value, _) => FractionallySizedBox(
                                widthFactor: value,
                                child: Container(
                                  height: 6,
                                  decoration: BoxDecoration(
                                    gradient: const LinearGradient(colors: [M4Theme.premiumBlue, Color(0xFF6366F1)]),
                                    borderRadius: BorderRadius.circular(10),
                                    boxShadow: [BoxShadow(color: M4Theme.premiumBlue.withValues(alpha: 0.3), blurRadius: 8, offset: const Offset(0, 2))],
                                  ),
                                ),
                              ),
                            ),
                          ],
                        ),
                      ],
                    ),
                  );
                },
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

class _SquareAction extends StatelessWidget {
  final IconData icon;
  final VoidCallback onTap;
  final Color? color;

  const _SquareAction({required this.icon, required this.onTap, this.color});

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    return _ScaleButton(
      onTap: onTap,
      child: Container(
        width: 40,
        height: 40,
        decoration: BoxDecoration(
          color: color ?? (isDark ? Colors.white.withValues(alpha: 0.1) : Colors.white),
          borderRadius: BorderRadius.circular(12),
          border: Border.all(color: (isDark ? Colors.white : Colors.black).withValues(alpha: 0.05)),
          boxShadow: isDark ? [] : [
            BoxShadow(
              color: Colors.black.withValues(alpha: 0.05),
              blurRadius: 10,
              offset: const Offset(0, 4)
            )
          ],
        ),
        child: Icon(icon, color: isDark ? Colors.white : Colors.black, size: 20),
      ),
    );
  }
}

class _LocationMap extends StatefulWidget {
  final String location;
  final VoidCallback onOpenMaps;
  const _LocationMap({required this.location, required this.onOpenMaps});

  @override
  State<_LocationMap> createState() => _LocationMapState();
}

class _LocationMapState extends State<_LocationMap> {
  late final WebViewController _controller;

  @override
  void initState() {
    super.initState();
    final url = 'https://www.google.com/maps?q=${Uri.encodeComponent(widget.location)}&output=embed';
    _controller = WebViewController()
      ..setJavaScriptMode(JavaScriptMode.unrestricted)
      ..setBackgroundColor(const Color(0xFFE8EAED))
      ..loadRequest(Uri.parse(url));
  }

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    return Container(
      height: 280,
      decoration: BoxDecoration(
        color: const Color(0xFFE8EAED),
        borderRadius: BorderRadius.circular(32),
        border: Border.all(color: isDark ? Colors.white.withValues(alpha: 0.05) : Colors.black.withValues(alpha: 0.05)),
      ),
      clipBehavior: Clip.antiAlias,
      child: Stack(
        fit: StackFit.expand,
        children: [
          WebViewWidget(controller: _controller),
          Positioned(
            top: 16,
            right: 16,
            child: _ScaleButton(
              onTap: widget.onOpenMaps,
              child: Container(
                padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 9),
                decoration: BoxDecoration(
                  color: isDark ? const Color(0xFF1E293B) : Colors.white.withValues(alpha: 0.95),
                  borderRadius: BorderRadius.circular(30),
                  boxShadow: [BoxShadow(color: Colors.black.withValues(alpha: 0.15), blurRadius: 10)],
                ),
                child: Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    const Icon(LucideIcons.mapPin, color: M4Theme.premiumBlue, size: 12),
                    const SizedBox(width: 6),
                    Text('VIEW ON MAPS', style: GoogleFonts.montserrat(fontSize: 8, fontWeight: FontWeight.w900, color: isDark ? Colors.white : Colors.black, letterSpacing: 1)),
                  ],
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }
}

class _DashedCirclePainter extends CustomPainter {
  final double progress;
  final Color color;
  final Color backgroundColor;

  _DashedCirclePainter({required this.progress, required this.color, required this.backgroundColor});

  @override
  void paint(Canvas canvas, Size size) {
    final center = Offset(size.width / 2, size.height / 2);
    final radius = size.width / 2;
    const strokeWidth = 4.0;
    const dashCount = 60;
    const gap = 0.5;

    final bgPaint = Paint()
      ..color = backgroundColor
      ..strokeWidth = strokeWidth
      ..style = PaintingStyle.stroke;

    final progressPaint = Paint()
      ..color = color
      ..strokeWidth = strokeWidth
      ..style = PaintingStyle.stroke
      ..strokeCap = StrokeCap.round;

    final dashAngle = (2 * 3.14159) / dashCount;

    for (int i = 0; i < dashCount; i++) {
        final startAngle = i * dashAngle;
        final sweepAngle = dashAngle * (1 - gap);
        
        // Draw background segment
        canvas.drawArc(
            Rect.fromCircle(center: center, radius: radius),
            startAngle,
            sweepAngle,
            false,
            bgPaint
        );

        // Draw progress segment if within range
        if (i < dashCount * progress) {
            canvas.drawArc(
                Rect.fromCircle(center: center, radius: radius),
                startAngle,
                sweepAngle,
                false,
                progressPaint
            );
        }
    }
  }

  @override
  bool shouldRepaint(CustomPainter oldDelegate) => true;
}
