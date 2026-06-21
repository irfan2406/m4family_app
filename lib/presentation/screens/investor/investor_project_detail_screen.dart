import 'dart:ui';
import 'package:dio/dio.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:lucide_icons/lucide_icons.dart';
import 'package:cached_network_image/cached_network_image.dart';
import 'package:share_plus/share_plus.dart';
import 'package:url_launcher/url_launcher.dart';
import 'package:m4_mobile/core/theme/app_theme.dart';
import 'package:m4_mobile/core/utils/support_handlers.dart';
import 'package:m4_mobile/presentation/providers/auth_provider.dart';

/// Investor project detail — mirrors web `/investor/projects/[id]` (ProjectDetailsPage)
/// and the guest project detail structure, adapted with an investor inquiry flow
/// (General / Video Call / Site Visit) and an "Invest In This Project" CTA.
/// Fetches from `GET /api/catalog/projects/:id`.
class InvestorProjectDetailScreen extends ConsumerStatefulWidget {
  final String projectId;

  const InvestorProjectDetailScreen({super.key, required this.projectId});

  @override
  ConsumerState<InvestorProjectDetailScreen> createState() =>
      _InvestorProjectDetailScreenState();
}

class _InvestorProjectDetailScreenState
    extends ConsumerState<InvestorProjectDetailScreen> {
  static const _gold = Color(0xFFFFD700);

  Map<String, dynamic>? _project;
  List<dynamic> _paymentPlans = [];
  List<dynamic> _progressPhases = [];
  List<String> _exteriorImages = [];
  List<String> _interiorImages = [];

  bool _isLoading = true;
  bool _hasError = false;
  bool _submitting = false;
  bool _showFullProgress = false;

  final TextEditingController _nameController = TextEditingController();
  final TextEditingController _emailController = TextEditingController();
  final TextEditingController _phoneController = TextEditingController();
  final TextEditingController _notesController = TextEditingController();

  @override
  void initState() {
    super.initState();
    _fetchProject();
  }

  @override
  void dispose() {
    _nameController.dispose();
    _emailController.dispose();
    _phoneController.dispose();
    _notesController.dispose();
    super.dispose();
  }

  Future<void> _fetchProject() async {
    setState(() {
      _isLoading = true;
      _hasError = false;
    });
    try {
      final apiClient = ref.read(apiClientProvider);
      final results = await Future.wait<Response<dynamic>>([
        apiClient.getProjectDetails(widget.projectId),
        apiClient.getProjectProgress(widget.projectId),
      ]);

      if (!mounted) return;

      Map<String, dynamic>? project;
      if (results[0].data['status'] == true && results[0].data['data'] != null) {
        project = Map<String, dynamic>.from(results[0].data['data'] as Map);

        final media = project['media'] as List? ?? [];

        final List<String> ext = [];
        if (project['exteriorImages'] != null) {
          ext.addAll((project['exteriorImages'] as List).map((e) => e.toString()));
        }
        ext.addAll(media
            .where((m) => m['category']?.toString().toUpperCase() == 'EXTERIOR')
            .map((m) => m['url'].toString()));
        _exteriorImages = ext.toSet().toList();

        final List<String> intr = [];
        if (project['interiorImages'] != null) {
          intr.addAll((project['interiorImages'] as List).map((e) => e.toString()));
        }
        intr.addAll(media
            .where((m) => m['category']?.toString().toUpperCase() == 'INTERIOR')
            .map((m) => m['url'].toString()));
        _interiorImages = intr.toSet().toList();

        _paymentPlans = project['paymentPlans'] as List? ?? [];
      }

      if (results[1].data['status'] == true) {
        _progressPhases = results[1].data['data'] ?? [];
      }

      setState(() {
        _project = project;
        _isLoading = false;
        _hasError = project == null;
      });
    } catch (_) {
      if (mounted) {
        setState(() {
          _isLoading = false;
          _hasError = true;
        });
      }
    }
  }

  void _toast(String message) {
    if (!mounted) return;
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(message,
            style: GoogleFonts.montserrat(
                fontSize: 12, fontWeight: FontWeight.bold)),
        backgroundColor: M4Theme.premiumBlue,
        behavior: SnackBarBehavior.floating,
        shape:
            RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
      ),
    );
  }

  Future<void> _openUrl(String? url) async {
    if (url == null || url.isEmpty) {
      _toast('Coming soon');
      return;
    }
    if (url.startsWith('tel:')) {
      await SupportHandlers.launchCall(url.replaceFirst('tel:', ''));
      return;
    }
    if (url.startsWith('mailto:')) {
      await SupportHandlers.launchEmail(url.replaceFirst('mailto:', ''));
      return;
    }
    final apiClient = ref.read(apiClientProvider);
    final resolved = apiClient.resolveUrl(url);
    final uri = Uri.parse(resolved);
    if (await canLaunchUrl(uri)) {
      await launchUrl(
        uri,
        mode: resolved.startsWith('http')
            ? LaunchMode.inAppBrowserView
            : LaunchMode.platformDefault,
      );
    } else {
      _toast('Unable to open link');
    }
  }

  void _prefillFromAuth() {
    final authUser = ref.read(authProvider).user;
    if (authUser != null) {
      _nameController.text = authUser['fullName']?.toString() ??
          authUser['firstName']?.toString() ??
          authUser['username']?.toString() ??
          '';
      _phoneController.text = authUser['phone']?.toString() ?? '';
      _emailController.text = authUser['email']?.toString() ?? '';
    }
  }

  Future<void> _submitInquiry({
    required String type,
    String? planName,
    String? visitDate,
    String? visitTime,
    required VoidCallback onClose,
  }) async {
    final name = _nameController.text.trim();
    final phone = _phoneController.text.trim();
    if (name.isEmpty || phone.isEmpty) {
      _toast('Please enter your name and phone number');
      return;
    }
    if ((type == 'VC' || type == 'Site Visit') &&
        (visitDate == null || visitTime == null)) {
      _toast('Please select a date and time');
      return;
    }

    setState(() => _submitting = true);
    try {
      final apiClient = ref.read(apiClientProvider);
      final authUser = ref.read(authProvider).user;
      final title = _project?['title']?.toString() ?? 'General';
      final notes = _notesController.text.trim();

      final res = await apiClient.submitLead({
        'name': name,
        'phone': phone,
        if (_emailController.text.trim().isNotEmpty)
          'email': _emailController.text.trim(),
        'interest': type == 'VC'
            ? 'Video Call'
            : type == 'Site Visit'
                ? 'Site Visit'
                : 'Investing',
        'source': 'mobile_app',
        'projectId': widget.projectId,
        'project': title,
        if (authUser != null && (authUser['id'] ?? authUser['_id']) != null)
          'userId': (authUser['id'] ?? authUser['_id']).toString(),
        if (type == 'VC' || type == 'Site Visit') 'visitDate': visitDate,
        if (type == 'VC' || type == 'Site Visit') 'visitTime': visitTime,
        if (notes.isNotEmpty) 'notes': notes,
        'message': planName != null
            ? 'Inquiry about payment plan: $planName for project $title'
            : '$type request for project $title${notes.isNotEmpty ? ' - Notes: $notes' : ''}',
      });

      if (res.data['status'] == true) {
        onClose();
        _toast(type == 'General'
            ? 'Inquiry submitted! Our advisor will contact you shortly.'
            : 'Booking request received! Our team will call you to confirm the time.');
      } else {
        _toast(res.data['message']?.toString() ?? 'Failed to submit inquiry');
      }
    } catch (_) {
      _toast('Connection error. Please try again.');
    } finally {
      if (mounted) setState(() => _submitting = false);
    }
  }

  // ─── Inquiry modal ─────────────────────────────────────────────────────────
  void _openInquiry(String type, {String? planName}) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final title = _project?['title']?.toString() ?? 'this project';
    _prefillFromAuth();

    String localType = type;
    DateTime? scheduledAt;

    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (sheetContext) => StatefulBuilder(
        builder: (sheetContext, setModalState) {
          final headerLabel = localType == 'VC'
              ? 'BOOK A VIDEO CALL'
              : localType == 'Site Visit'
                  ? 'BOOK A SITE VISIT'
                  : 'REQUEST DETAILS';
          final ctaLabel = localType == 'General'
              ? 'SUBMIT INQUIRY'
              : 'CONFIRM BOOKING';

          return Container(
            padding: EdgeInsets.only(
                bottom: MediaQuery.of(sheetContext).viewInsets.bottom + 20),
            constraints: BoxConstraints(
                maxHeight: MediaQuery.of(sheetContext).size.height * 0.9),
            decoration: BoxDecoration(
              color: isDark ? const Color(0xFF0F1115) : Colors.white,
              borderRadius:
                  const BorderRadius.vertical(top: Radius.circular(40)),
            ),
            child: SingleChildScrollView(
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  const SizedBox(height: 12),
                  Container(
                    width: 40,
                    height: 4,
                    decoration: BoxDecoration(
                        color: isDark ? Colors.white24 : Colors.black12,
                        borderRadius: BorderRadius.circular(2)),
                  ),
                  Align(
                    alignment: Alignment.topRight,
                    child: IconButton(
                      onPressed: () => Navigator.pop(sheetContext),
                      icon: Icon(LucideIcons.x,
                          color: isDark ? Colors.white38 : Colors.black38,
                          size: 20),
                      padding: const EdgeInsets.symmetric(horizontal: 24),
                    ),
                  ),
                  Padding(
                    padding: const EdgeInsets.symmetric(horizontal: 32),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          headerLabel,
                          style: GoogleFonts.montserrat(
                              fontSize: 30,
                              fontWeight: FontWeight.w900,
                              color: isDark ? Colors.white : Colors.black,
                              height: 1.1,
                              letterSpacing: -1.2),
                        ),
                        const SizedBox(height: 14),
                        Text(
                          'A BESPOKE SHOWCASE OF LUXURY AT ${title.toUpperCase()}.',
                          style: GoogleFonts.montserrat(
                              fontSize: 9,
                              color: isDark ? Colors.white38 : Colors.black38,
                              fontWeight: FontWeight.w900,
                              letterSpacing: 1),
                        ),
                        const SizedBox(height: 32),
                        _InquiryField(
                            hint: 'FULL NAME *',
                            controller: _nameController,
                            icon: LucideIcons.user),
                        const SizedBox(height: 14),
                        _InquiryField(
                            hint: 'EMAIL ADDRESS',
                            controller: _emailController,
                            icon: LucideIcons.mail),
                        const SizedBox(height: 14),
                        _InquiryField(
                            hint: 'PHONE NUMBER *',
                            controller: _phoneController,
                            icon: LucideIcons.phone),

                        // Plan select
                        if (_paymentPlans.isNotEmpty) ...[
                          const SizedBox(height: 28),
                          Text('PREFERRED PLAN',
                              style: GoogleFonts.montserrat(
                                  fontSize: 8,
                                  fontWeight: FontWeight.w900,
                                  color:
                                      isDark ? Colors.white38 : Colors.black38,
                                  letterSpacing: 1)),
                          const SizedBox(height: 12),
                          Wrap(
                            spacing: 8,
                            runSpacing: 8,
                            children: _paymentPlans.map((plan) {
                              final n = (plan is Map
                                      ? plan['name']?.toString()
                                      : plan.toString()) ??
                                  'PLAN';
                              final isActive = planName == n;
                              return GestureDetector(
                                onTap: () =>
                                    setModalState(() => planName = n),
                                child: Container(
                                  padding: const EdgeInsets.symmetric(
                                      horizontal: 16, vertical: 12),
                                  decoration: BoxDecoration(
                                    color: isActive
                                        ? M4Theme.premiumBlue
                                        : Colors.transparent,
                                    borderRadius: BorderRadius.circular(10),
                                    border: Border.all(
                                        color: isActive
                                            ? M4Theme.premiumBlue
                                            : (isDark
                                                ? Colors.white
                                                    .withValues(alpha: 0.1)
                                                : Colors.black
                                                    .withValues(alpha: 0.08))),
                                  ),
                                  child: Text(
                                    n.toUpperCase(),
                                    style: GoogleFonts.montserrat(
                                        fontSize: 8,
                                        fontWeight: FontWeight.w900,
                                        color: isActive
                                            ? Colors.white
                                            : (isDark
                                                ? Colors.white38
                                                : Colors.black38)),
                                  ),
                                ),
                              );
                            }).toList(),
                          ),
                        ],

                        // Visit type toggle + schedule
                        if (localType == 'VC' ||
                            localType == 'Site Visit') ...[
                          const SizedBox(height: 28),
                          Text('VISIT TYPE',
                              style: GoogleFonts.montserrat(
                                  fontSize: 8,
                                  fontWeight: FontWeight.w900,
                                  color:
                                      isDark ? Colors.white38 : Colors.black38,
                                  letterSpacing: 1)),
                          const SizedBox(height: 12),
                          Row(
                            children: [
                              for (final t in const ['Site Visit', 'VC'])
                                Expanded(
                                  child: GestureDetector(
                                    onTap: () =>
                                        setModalState(() => localType = t),
                                    child: Container(
                                      margin: EdgeInsets.only(
                                          right: t == 'Site Visit' ? 8 : 0),
                                      padding: const EdgeInsets.symmetric(
                                          vertical: 12),
                                      decoration: BoxDecoration(
                                        color: localType == t
                                            ? (isDark
                                                ? Colors.white
                                                : Colors.black)
                                            : Colors.transparent,
                                        borderRadius: BorderRadius.circular(10),
                                        border: Border.all(
                                            color: isDark
                                                ? Colors.white
                                                    .withValues(alpha: 0.1)
                                                : Colors.black
                                                    .withValues(alpha: 0.08)),
                                      ),
                                      child: Center(
                                        child: Text(
                                          t == 'VC'
                                              ? 'VIDEO CALL'
                                              : 'SITE VISIT',
                                          style: GoogleFonts.montserrat(
                                              fontSize: 9,
                                              fontWeight: FontWeight.w900,
                                              color: localType == t
                                                  ? (isDark
                                                      ? Colors.black
                                                      : Colors.white)
                                                  : (isDark
                                                      ? Colors.white38
                                                      : Colors.black38),
                                              letterSpacing: 1),
                                        ),
                                      ),
                                    ),
                                  ),
                                ),
                            ],
                          ),
                          const SizedBox(height: 16),
                          GestureDetector(
                            onTap: () async {
                              final now = DateTime.now();
                              final date = await showDatePicker(
                                context: sheetContext,
                                initialDate: scheduledAt ?? now,
                                firstDate: now,
                                lastDate: now.add(const Duration(days: 180)),
                              );
                              if (date == null) return;
                              if (!sheetContext.mounted) return;
                              final time = await showTimePicker(
                                context: sheetContext,
                                initialTime: TimeOfDay.fromDateTime(
                                    scheduledAt ?? now),
                              );
                              if (time == null) return;
                              setModalState(() {
                                scheduledAt = DateTime(date.year, date.month,
                                    date.day, time.hour, time.minute);
                              });
                            },
                            child: Container(
                              width: double.infinity,
                              padding: const EdgeInsets.symmetric(
                                  horizontal: 20, vertical: 18),
                              decoration: BoxDecoration(
                                color: isDark
                                    ? Colors.white.withValues(alpha: 0.03)
                                    : const Color(0xFFF8FAFC),
                                borderRadius: BorderRadius.circular(12),
                                border: Border.all(
                                    color: isDark
                                        ? Colors.white.withValues(alpha: 0.08)
                                        : Colors.black
                                            .withValues(alpha: 0.08)),
                              ),
                              child: Row(
                                children: [
                                  const Icon(LucideIcons.calendar,
                                      size: 14, color: M4Theme.premiumBlue),
                                  const SizedBox(width: 12),
                                  Text(
                                    scheduledAt == null
                                        ? 'SELECT DATE & TIME'
                                        : _formatSchedule(scheduledAt!),
                                    style: GoogleFonts.montserrat(
                                        fontSize: 9,
                                        fontWeight: FontWeight.w900,
                                        color: scheduledAt == null
                                            ? (isDark
                                                ? Colors.white24
                                                : Colors.black26)
                                            : (isDark
                                                ? Colors.white
                                                : Colors.black),
                                        letterSpacing: 1),
                                  ),
                                ],
                              ),
                            ),
                          ),
                        ],

                        // Notes
                        const SizedBox(height: 24),
                        Text('ADDITIONAL NOTES',
                            style: GoogleFonts.montserrat(
                                fontSize: 8,
                                fontWeight: FontWeight.w900,
                                color: isDark ? Colors.white38 : Colors.black38,
                                letterSpacing: 1)),
                        const SizedBox(height: 12),
                        Container(
                          padding: const EdgeInsets.symmetric(
                              horizontal: 16, vertical: 4),
                          decoration: BoxDecoration(
                            color: isDark
                                ? Colors.white.withValues(alpha: 0.03)
                                : const Color(0xFFF8FAFC),
                            borderRadius: BorderRadius.circular(12),
                            border: Border.all(
                                color: isDark
                                    ? Colors.white.withValues(alpha: 0.08)
                                    : Colors.black.withValues(alpha: 0.08)),
                          ),
                          child: TextField(
                            controller: _notesController,
                            maxLines: 3,
                            style: GoogleFonts.montserrat(
                                fontSize: 11,
                                fontWeight: FontWeight.bold,
                                color: isDark ? Colors.white : Colors.black),
                            decoration: InputDecoration(
                              border: InputBorder.none,
                              hintText:
                                  'SPECIFIC REQUIREMENTS, PICKUP DETAILS, ETC...',
                              hintStyle: GoogleFonts.montserrat(
                                  fontSize: 9,
                                  fontWeight: FontWeight.w900,
                                  color: isDark
                                      ? Colors.white24
                                      : Colors.black26,
                                  letterSpacing: 1),
                            ),
                          ),
                        ),

                        const SizedBox(height: 32),
                        GestureDetector(
                          onTap: _submitting
                              ? null
                              : () => _submitInquiry(
                                    type: localType,
                                    planName: planName,
                                    visitDate: scheduledAt == null
                                        ? null
                                        : _dateOnly(scheduledAt!),
                                    visitTime: scheduledAt == null
                                        ? null
                                        : _timeOnly(scheduledAt!),
                                    onClose: () => Navigator.pop(sheetContext),
                                  ),
                          child: Container(
                            width: double.infinity,
                            padding:
                                const EdgeInsets.symmetric(vertical: 20),
                            decoration: BoxDecoration(
                              color: isDark ? Colors.white : Colors.black,
                              borderRadius: BorderRadius.circular(14),
                            ),
                            child: Center(
                              child: Text(
                                _submitting ? 'SUBMITTING...' : ctaLabel,
                                style: GoogleFonts.montserrat(
                                    color: isDark
                                        ? Colors.black
                                        : Colors.white,
                                    fontSize: 11,
                                    fontWeight: FontWeight.w900,
                                    letterSpacing: 2),
                              ),
                            ),
                          ),
                        ),
                        const SizedBox(height: 28),
                      ],
                    ),
                  ),
                ],
              ),
            ),
          );
        },
      ),
    );
  }

  String _dateOnly(DateTime d) =>
      '${d.year.toString().padLeft(4, '0')}-${d.month.toString().padLeft(2, '0')}-${d.day.toString().padLeft(2, '0')}';

  String _timeOnly(DateTime d) {
    final h = d.hour % 12 == 0 ? 12 : d.hour % 12;
    final ampm = d.hour >= 12 ? 'PM' : 'AM';
    return '${h.toString().padLeft(2, '0')}:${d.minute.toString().padLeft(2, '0')} $ampm';
  }

  String _formatSchedule(DateTime d) => '${_dateOnly(d)}  •  ${_timeOnly(d)}';

  // ─── Lightbox ──────────────────────────────────────────────────────────────
  void _openGallery(List<String> urls) {
    if (urls.isEmpty) {
      _toast('Gallery coming soon!');
      return;
    }
    final apiClient = ref.read(apiClientProvider);
    final pageController = PageController();
    showGeneralDialog(
      context: context,
      barrierDismissible: true,
      barrierLabel: 'Lightbox',
      barrierColor: Colors.black.withValues(alpha: 0.9),
      transitionDuration: const Duration(milliseconds: 300),
      pageBuilder: (context, _, __) => Scaffold(
        backgroundColor: Colors.transparent,
        body: Stack(
          fit: StackFit.expand,
          children: [
            PageView.builder(
              controller: pageController,
              itemCount: urls.length,
              itemBuilder: (context, index) => Center(
                child: InteractiveViewer(
                  child: CachedNetworkImage(
                    imageUrl: apiClient.resolveUrl(urls[index]),
                    fit: BoxFit.contain,
                    placeholder: (c, u) => const Center(
                        child: CircularProgressIndicator(
                            color: Colors.white24)),
                    errorWidget: (c, u, e) => const Icon(LucideIcons.image,
                        color: Colors.white24, size: 50),
                  ),
                ),
              ),
            ),
            Positioned(
              top: MediaQuery.of(context).padding.top + 20,
              right: 20,
              child: GestureDetector(
                onTap: () => Navigator.pop(context),
                child: Container(
                  padding: const EdgeInsets.all(12),
                  decoration: BoxDecoration(
                      color: Colors.black.withValues(alpha: 0.4),
                      shape: BoxShape.circle),
                  child: const Icon(LucideIcons.x,
                      color: Colors.white, size: 20),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  // ─── Build ───────────────────────────────────────────────────────────────
  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final bg = isDark ? Colors.black : Colors.white;

    if (_isLoading) {
      return Scaffold(
        backgroundColor: bg,
        body: Center(
            child: CircularProgressIndicator(color: M4Theme.premiumBlue)),
      );
    }

    if (_hasError || _project == null) {
      return Scaffold(
        backgroundColor: bg,
        body: SafeArea(
          child: Center(
            child: Padding(
              padding: const EdgeInsets.all(32),
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Icon(LucideIcons.building2,
                      size: 56,
                      color: (isDark ? Colors.white : Colors.black)
                          .withValues(alpha: 0.3)),
                  const SizedBox(height: 20),
                  Text('PROJECT NOT FOUND',
                      style: GoogleFonts.montserrat(
                          fontSize: 16,
                          fontWeight: FontWeight.w900,
                          color: isDark ? Colors.white : Colors.black,
                          letterSpacing: 1)),
                  const SizedBox(height: 10),
                  Text(
                    'The project you are looking for might have been moved or is no longer active.',
                    textAlign: TextAlign.center,
                    style: GoogleFonts.montserrat(
                        fontSize: 11,
                        fontWeight: FontWeight.w600,
                        color: (isDark ? Colors.white : Colors.black)
                            .withValues(alpha: 0.5)),
                  ),
                  const SizedBox(height: 24),
                  GestureDetector(
                    onTap: () {
                      if (context.canPop()) {
                        context.pop();
                      } else {
                        context.go('/investor/home');
                      }
                    },
                    child: Container(
                      padding: const EdgeInsets.symmetric(
                          horizontal: 32, vertical: 14),
                      decoration: BoxDecoration(
                          color: isDark ? Colors.white : Colors.black,
                          borderRadius: BorderRadius.circular(30)),
                      child: Text('GO BACK',
                          style: GoogleFonts.montserrat(
                              fontSize: 10,
                              fontWeight: FontWeight.w900,
                              color: isDark ? Colors.black : Colors.white,
                              letterSpacing: 1.5)),
                    ),
                  ),
                ],
              ),
            ),
          ),
        ),
      );
    }

    final project = _project!;
    return Scaffold(
      backgroundColor: bg,
      body: SingleChildScrollView(
        physics: const BouncingScrollPhysics(),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            _buildHero(project, isDark),
            const SizedBox(height: 20),
            _buildMediaThumbs(project, isDark),
            const SizedBox(height: 24),
            _buildActionCards(project, isDark),
            const SizedBox(height: 32),
            _buildOverviewSection(project, isDark),
            const SizedBox(height: 32),
            _buildAmenitiesSection(project, isDark),
            const SizedBox(height: 32),
            _buildPlansSection(project, isDark),
            const SizedBox(height: 32),
            _buildConstructionSection(project, isDark),
            const SizedBox(height: 32),
            _buildPaymentPlansSection(isDark),
            const SizedBox(height: 32),
            _buildInvestSection(project, isDark),
            const SizedBox(height: 32),
            _buildLocationSection(project, isDark),
            const SizedBox(height: 100),
          ],
        ),
      ),
    );
  }

  Widget _buildHero(Map<String, dynamic> project, bool isDark) {
    final apiClient = ref.read(apiClientProvider);
    final heroList = project['heroImages'] as List?;
    final heroSrc = (heroList != null && heroList.isNotEmpty)
        ? heroList.first.toString()
        : (project['heroImage'] ?? project['coverImage'])?.toString();
    final heroUrl = apiClient.resolveUrl(heroSrc);
    final location = _locationLabel(project);

    return AspectRatio(
      aspectRatio: 16 / 9,
      child: Stack(
        fit: StackFit.expand,
        children: [
          CachedNetworkImage(
            imageUrl: heroUrl,
            fit: BoxFit.cover,
            placeholder: (c, u) => Container(color: Colors.black12),
            errorWidget: (c, u, e) =>
                Container(color: Colors.black12, child: const Icon(Icons.error)),
          ),
          Container(
            decoration: BoxDecoration(
              gradient: LinearGradient(
                begin: Alignment.topCenter,
                end: Alignment.bottomCenter,
                colors: [
                  Colors.black.withValues(alpha: 0.1),
                  Colors.transparent,
                  (isDark ? Colors.black : Colors.white)
                      .withValues(alpha: 0.9),
                  (isDark ? Colors.black : Colors.white),
                ],
                stops: const [0.0, 0.4, 0.85, 1.0],
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
                Container(
                  padding:
                      const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                  decoration: BoxDecoration(
                      color: Colors.black,
                      borderRadius: BorderRadius.circular(4)),
                  child: Text(
                      (project['status']?.toString().toUpperCase() ??
                          'ONGOING'),
                      style: GoogleFonts.montserrat(
                          color: Colors.white,
                          fontSize: 8,
                          fontWeight: FontWeight.w900,
                          letterSpacing: 1)),
                ),
                const SizedBox(height: 12),
                Text(
                  (project['title']?.toString() ?? 'Project Name')
                      .toUpperCase(),
                  style: GoogleFonts.montserrat(
                      color: isDark ? Colors.white : Colors.black,
                      fontSize: 32,
                      height: 1.0,
                      fontWeight: FontWeight.w800,
                      letterSpacing: -1.5),
                ),
                const SizedBox(height: 8),
                Row(
                  children: [
                    Icon(LucideIcons.mapPin,
                        color: isDark
                            ? Colors.white70
                            : Colors.black.withValues(alpha: 0.7),
                        size: 14),
                    const SizedBox(width: 6),
                    Expanded(
                      child: Text(
                        location.toUpperCase(),
                        style: GoogleFonts.montserrat(
                            color: isDark ? Colors.white : Colors.black,
                            fontSize: 12,
                            fontWeight: FontWeight.w900,
                            letterSpacing: 1),
                      ),
                    ),
                  ],
                ),
              ],
            ),
          ),
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
                      context.go('/investor/home');
                    }
                  },
                ),
                _SquareAction(
                  icon: LucideIcons.share2,
                  onTap: () => Share.share(
                      'Check out ${project['title']} on M4 Family!'),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildMediaThumbs(Map<String, dynamic> project, bool isDark) {
    final apiClient = ref.read(apiClientProvider);
    final heroFallback = apiClient.resolveUrl(
        (project['heroImage'] ?? project['coverImage'])?.toString());
    final threeSixty = project['threeSixtyUrl']?.toString();

    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 24),
      child: Row(
        children: [
          _MediaThumb(
            label: 'EXTERIOR',
            imageUrl: _exteriorImages.isNotEmpty
                ? apiClient.resolveUrl(_exteriorImages.first)
                : heroFallback,
            onTap: () => _openGallery(_exteriorImages),
          ),
          const SizedBox(width: 12),
          _MediaThumb(
            label: 'INTERIOR',
            imageUrl: _interiorImages.isNotEmpty
                ? apiClient.resolveUrl(_interiorImages.first)
                : heroFallback,
            onTap: () => _openGallery(_interiorImages),
          ),
          const SizedBox(width: 12),
          // 360 view — web shows threeSixtyUrl reference.
          _IconThumb(
            label: '360° VIEW',
            icon: LucideIcons.view,
            isDark: isDark,
            onTap: () {
              if (threeSixty != null && threeSixty.isNotEmpty) {
                _openUrl(threeSixty);
              } else {
                _toast('360° Virtual Tour coming soon!');
              }
            },
          ),
        ],
      ),
    );
  }

  Widget _buildActionCards(Map<String, dynamic> project, bool isDark) {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 24),
      child: Row(
        children: [
          Expanded(
            child: _ActionCard(
              label: 'VIDEO CALL',
              value: 'Connect Now',
              icon: LucideIcons.video,
              isAction: true,
              onTap: () => _openInquiry('VC'),
            ),
          ),
          const SizedBox(width: 10),
          Expanded(
            child: _ActionCard(
              label: 'COMPLETION',
              value: '${project['completion'] ?? 0}%',
              icon: LucideIcons.calendar,
            ),
          ),
          const SizedBox(width: 10),
          Expanded(
            child: _ActionCard(
              label: 'SITE VISIT',
              value: 'Book Tour',
              icon: LucideIcons.eye,
              isAction: true,
              onTap: () => _openInquiry('Site Visit'),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildOverviewSection(Map<String, dynamic> project, bool isDark) {
    final flyer = project['flyer']?.toString();
    final brochure = project['brochure']?.toString();
    final description = project['description']?.toString();
    final startingPrice = project['startingPrice']?.toString();

    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 24),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          _sectionHeader('Overview', isDark),
          const SizedBox(height: 24),
          Text(
            (description != null && description.isNotEmpty
                    ? description
                    : 'Experience the pinnacle of luxury living with floor-to-ceiling windows, Italian marble flooring, and smart home automation.')
                .toUpperCase(),
            style: GoogleFonts.montserrat(
                fontSize: 11,
                color: (isDark ? Colors.white : Colors.black)
                    .withValues(alpha: 0.8),
                fontWeight: FontWeight.w900,
                height: 1.6,
                letterSpacing: 0.5),
          ),
          if (startingPrice != null &&
              startingPrice.isNotEmpty &&
              startingPrice != 'N/A') ...[
            const SizedBox(height: 24),
            Row(
              children: [
                const Icon(LucideIcons.indianRupee,
                    size: 16, color: M4Theme.premiumBlue),
                const SizedBox(width: 8),
                Text('STARTING PRICE',
                    style: GoogleFonts.montserrat(
                        fontSize: 8,
                        fontWeight: FontWeight.w900,
                        color: isDark ? Colors.white38 : Colors.black38,
                        letterSpacing: 1)),
                const SizedBox(width: 12),
                Text(startingPrice,
                    style: GoogleFonts.montserrat(
                        fontSize: 13,
                        fontWeight: FontWeight.w900,
                        color: isDark ? Colors.white : Colors.black)),
              ],
            ),
          ],
          if (flyer != null && flyer.isNotEmpty) ...[
            const SizedBox(height: 24),
            _AssetCard(
              title: 'PROJECT FLYER',
              subtitle: 'HIGH RES • PDF',
              icon: LucideIcons.fileText,
              isDark: isDark,
              onView: () => _openUrl(flyer),
              onDownload: () => _openUrl(flyer),
            ),
          ],
          if (brochure != null && brochure.isNotEmpty) ...[
            const SizedBox(height: 16),
            _AssetCard(
              title: 'PROJECT BROCHURE',
              subtitle: 'SHOWCASE • PDF',
              icon: LucideIcons.layers,
              isDark: isDark,
              onView: () => _openUrl(brochure),
              onDownload: () => _openUrl(brochure),
            ),
          ],
          ..._buildDocuments(project, isDark),
        ],
      ),
    );
  }

  List<Widget> _buildDocuments(Map<String, dynamic> project, bool isDark) {
    final docs = project['documents'] as List? ?? [];
    if (docs.isEmpty) return const [];
    return [
      const SizedBox(height: 24),
      Text('DOCUMENTS',
          style: GoogleFonts.montserrat(
              fontSize: 8,
              fontWeight: FontWeight.w900,
              color: isDark ? Colors.white38 : Colors.black38,
              letterSpacing: 1)),
      const SizedBox(height: 12),
      ...docs.map((doc) {
        final name = (doc is Map
                ? (doc['title'] ?? doc['name'])?.toString()
                : doc.toString()) ??
            'DOCUMENT';
        final url =
            doc is Map ? (doc['url'] ?? doc['file'])?.toString() : doc.toString();
        return Padding(
          padding: const EdgeInsets.only(bottom: 12),
          child: _AssetCard(
            title: name.toUpperCase(),
            subtitle: 'DOCUMENT • PDF',
            icon: LucideIcons.fileText,
            isDark: isDark,
            onView: () => _openUrl(url),
            onDownload: () => _openUrl(url),
          ),
        );
      }),
    ];
  }

  Widget _buildPlansSection(Map<String, dynamic> project, bool isDark) {
    final plans = project['plans'] as List? ?? [];
    if (plans.isEmpty) return const SizedBox.shrink();
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 24),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          _sectionHeader('Floor Plans', isDark),
          const SizedBox(height: 24),
          GridView.builder(
            shrinkWrap: true,
            physics: const NeverScrollableScrollPhysics(),
            padding: EdgeInsets.zero,
            gridDelegate:
                const SliverGridDelegateWithFixedCrossAxisCount(
              crossAxisCount: 2,
              mainAxisSpacing: 12,
              crossAxisSpacing: 12,
              childAspectRatio: 0.78,
            ),
            itemCount: plans.length,
            itemBuilder: (context, index) {
              final plan = plans[index];
              final apiClient = ref.read(apiClientProvider);
              final img = plan is Map ? plan['image']?.toString() : null;
              final title = (plan is Map
                      ? plan['title']?.toString()
                      : plan.toString()) ??
                  'PLAN';
              final config =
                  plan is Map ? plan['config']?.toString() : null;
              final area = plan is Map ? plan['area']?.toString() : null;
              return GestureDetector(
                onTap: () {
                  if (img != null && img.isNotEmpty) _openGallery([img]);
                },
                child: Container(
                  decoration: BoxDecoration(
                    color: isDark
                        ? Colors.white.withValues(alpha: 0.03)
                        : Colors.white,
                    borderRadius: BorderRadius.circular(24),
                    border: Border.all(
                        color: isDark
                            ? Colors.white.withValues(alpha: 0.08)
                            : Colors.black.withValues(alpha: 0.06)),
                  ),
                  clipBehavior: Clip.antiAlias,
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Expanded(
                        child: img != null && img.isNotEmpty
                            ? CachedNetworkImage(
                                imageUrl: apiClient.resolveUrl(img),
                                width: double.infinity,
                                fit: BoxFit.cover,
                                placeholder: (c, u) =>
                                    Container(color: Colors.black12),
                                errorWidget: (c, u, e) => Container(
                                  color: Colors.black12,
                                  child: const Icon(LucideIcons.layoutGrid,
                                      color: Colors.white30),
                                ),
                              )
                            : Container(
                                color: isDark
                                    ? Colors.white.withValues(alpha: 0.04)
                                    : const Color(0xFFF4F4F5),
                                child: const Center(
                                  child: Icon(LucideIcons.layoutGrid,
                                      color: M4Theme.premiumBlue, size: 28),
                                ),
                              ),
                      ),
                      Padding(
                        padding: const EdgeInsets.all(14),
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(title.toUpperCase(),
                                maxLines: 1,
                                overflow: TextOverflow.ellipsis,
                                style: GoogleFonts.montserrat(
                                    fontSize: 10,
                                    fontWeight: FontWeight.w900,
                                    color:
                                        isDark ? Colors.white : Colors.black,
                                    letterSpacing: 0.5)),
                            const SizedBox(height: 4),
                            Text(
                              [config, area]
                                  .where((e) => e != null && e.isNotEmpty)
                                  .join('  •  ')
                                  .toUpperCase(),
                              maxLines: 1,
                              overflow: TextOverflow.ellipsis,
                              style: GoogleFonts.montserrat(
                                  fontSize: 8,
                                  fontWeight: FontWeight.w900,
                                  color: isDark
                                      ? Colors.white38
                                      : Colors.black38,
                                  letterSpacing: 0.5),
                            ),
                          ],
                        ),
                      ),
                    ],
                  ),
                ),
              );
            },
          ),
        ],
      ),
    );
  }

  Widget _buildAmenitiesSection(Map<String, dynamic> project, bool isDark) {
    final amenities = project['amenities'] as List? ?? [];
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 24),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          _sectionHeader('Amenities', isDark),
          const SizedBox(height: 24),
          if (amenities.isEmpty)
            Center(
              child: Text('COMING SOON',
                  style: GoogleFonts.montserrat(
                      fontSize: 12,
                      color: isDark ? Colors.white38 : Colors.black38)),
            )
          else
            GridView.builder(
              shrinkWrap: true,
              physics: const NeverScrollableScrollPhysics(),
              padding: EdgeInsets.zero,
              gridDelegate:
                  const SliverGridDelegateWithFixedCrossAxisCount(
                crossAxisCount: 3,
                mainAxisSpacing: 12,
                crossAxisSpacing: 12,
                childAspectRatio: 1.0,
              ),
              itemCount: amenities.length,
              itemBuilder: (context, index) {
                final amenity = amenities[index];
                final name = (amenity is Map
                        ? (amenity['name']?.toString() ?? 'Amenity')
                        : amenity.toString())
                    .toUpperCase();
                return Container(
                  decoration: BoxDecoration(
                    color: isDark
                        ? Colors.white.withValues(alpha: 0.03)
                        : const Color(0xFFF4F4F5),
                    borderRadius: BorderRadius.circular(32),
                    border: Border.all(
                        color: isDark
                            ? Colors.white.withValues(alpha: 0.08)
                            : Colors.black.withValues(alpha: 0.06)),
                  ),
                  child: Column(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      Icon(_amenityIcon(name),
                          color: _gold, size: 28),
                      const SizedBox(height: 16),
                      Padding(
                        padding:
                            const EdgeInsets.symmetric(horizontal: 8),
                        child: Text(
                          name,
                          textAlign: TextAlign.center,
                          style: GoogleFonts.montserrat(
                              fontSize: 8,
                              fontWeight: FontWeight.w900,
                              color: (isDark ? Colors.white : Colors.black)
                                  .withValues(alpha: 0.8),
                              letterSpacing: 1,
                              height: 1.2),
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

  Widget _buildConstructionSection(Map<String, dynamic> project, bool isDark) {
    final apiClient = ref.read(apiClientProvider);
    final completion = (project['completion'] ?? 0);
    final estimated = (project['estimatedCompletionDate'] ??
            project['possessionDate'] ??
            'Q1 2028')
        .toString();
    final overall =
        completion is num ? completion : num.tryParse('$completion') ?? 0;

    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 24),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          _sectionHeader('Construction Progress', isDark),
          const SizedBox(height: 24),
          Container(
            width: double.infinity,
            padding:
                const EdgeInsets.symmetric(horizontal: 28, vertical: 36),
            decoration: BoxDecoration(
              color: isDark
                  ? Colors.white.withValues(alpha: 0.03)
                  : const Color(0xFFF8FAFC),
              borderRadius: BorderRadius.circular(40),
              border: Border.all(
                  color: isDark
                      ? Colors.white.withValues(alpha: 0.08)
                      : Colors.black.withValues(alpha: 0.06)),
            ),
            child: Column(
              children: [
                Row(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text('ESTIMATED COMPLETION',
                              style: GoogleFonts.montserrat(
                                  fontSize: 9,
                                  fontWeight: FontWeight.w900,
                                  color: M4Theme.premiumBlue,
                                  letterSpacing: 1)),
                          const SizedBox(height: 12),
                          Text(estimated.toUpperCase(),
                              style: GoogleFonts.montserrat(
                                  fontSize: 34,
                                  fontWeight: FontWeight.w900,
                                  height: 1.0,
                                  color: isDark
                                      ? Colors.white
                                      : Colors.black)),
                          const SizedBox(height: 20),
                          Text(
                            'As the project progresses, significant milestones are reached, showcasing our team\'s dedication and expertise. We are steadily moving closer to our completion goal, ensuring quality and safety at every step.',
                            maxLines: _showFullProgress ? null : 3,
                            overflow: _showFullProgress
                                ? TextOverflow.visible
                                : TextOverflow.ellipsis,
                            style: GoogleFonts.montserrat(
                                fontSize: 10,
                                fontWeight: FontWeight.bold,
                                height: 1.6,
                                color: (isDark ? Colors.white : Colors.black)
                                    .withValues(alpha: 0.5)),
                          ),
                          const SizedBox(height: 8),
                          GestureDetector(
                            onTap: () => setState(
                                () => _showFullProgress = !_showFullProgress),
                            child: Text(
                                _showFullProgress ? 'Show less' : 'Read more',
                                style: GoogleFonts.montserrat(
                                    fontSize: 10,
                                    fontWeight: FontWeight.w900,
                                    color: M4Theme.premiumBlue)),
                          ),
                        ],
                      ),
                    ),
                    const SizedBox(width: 16),
                    SizedBox(
                      width: 90,
                      height: 90,
                      child: Stack(
                        alignment: Alignment.center,
                        children: [
                          SizedBox(
                            width: 90,
                            height: 90,
                            child: CircularProgressIndicator(
                              value: overall.toDouble() / 100,
                              strokeWidth: 5,
                              backgroundColor: isDark
                                  ? Colors.white.withValues(alpha: 0.1)
                                  : Colors.black.withValues(alpha: 0.08),
                              valueColor:
                                  const AlwaysStoppedAnimation<Color>(
                                      M4Theme.premiumBlue),
                            ),
                          ),
                          Column(
                            mainAxisSize: MainAxisSize.min,
                            children: [
                              Text('${overall.toInt()}%',
                                  style: GoogleFonts.montserrat(
                                      fontSize: 20,
                                      fontWeight: FontWeight.w900,
                                      color: isDark
                                          ? Colors.white
                                          : Colors.black)),
                              Text('OVERALL',
                                  style: GoogleFonts.montserrat(
                                      fontSize: 7,
                                      fontWeight: FontWeight.w900,
                                      color: isDark
                                          ? Colors.white38
                                          : Colors.black38,
                                      letterSpacing: 1)),
                            ],
                          ),
                        ],
                      ),
                    ),
                  ],
                ),
                if (_progressPhases.isNotEmpty) ...[
                  const SizedBox(height: 36),
                  SizedBox(
                    height: 230,
                    child: ListView.builder(
                      scrollDirection: Axis.horizontal,
                      padding: EdgeInsets.zero,
                      itemCount: _progressPhases.length,
                      itemBuilder: (context, index) {
                        final phase = _progressPhases[index];
                        final phaseImages = phase['images'] as List?;
                        final firstImg = (phaseImages != null &&
                                phaseImages.isNotEmpty)
                            ? phaseImages[0]
                            : '';
                        final imageUrl = apiClient
                            .resolveUrl(phase['image'] ?? firstImg);
                        final status =
                            phase['status']?.toString().toUpperCase() ??
                                'UPCOMING';
                        final progress = (phase['progressPercent'] ??
                                phase['progress'] ??
                                0)
                            .toString();
                        return GestureDetector(
                          onTap: () {
                            if (imageUrl.isNotEmpty) {
                              _openGallery([
                                phase['image']?.toString() ??
                                    firstImg.toString()
                              ]);
                            }
                          },
                          child: Container(
                            width: 230,
                            margin: const EdgeInsets.only(right: 16),
                            decoration: BoxDecoration(
                              color: isDark
                                  ? Colors.white.withValues(alpha: 0.03)
                                  : Colors.white,
                              borderRadius: BorderRadius.circular(24),
                              border: Border.all(
                                  color: isDark
                                      ? Colors.white.withValues(alpha: 0.08)
                                      : Colors.black
                                          .withValues(alpha: 0.06)),
                            ),
                            clipBehavior: Clip.antiAlias,
                            child: Column(
                              crossAxisAlignment:
                                  CrossAxisAlignment.start,
                              children: [
                                Stack(
                                  children: [
                                    CachedNetworkImage(
                                      imageUrl: imageUrl,
                                      height: 130,
                                      width: 230,
                                      fit: BoxFit.cover,
                                      placeholder: (c, u) => Container(
                                          height: 130,
                                          color: Colors.black12),
                                      errorWidget: (c, u, e) => Container(
                                          height: 130,
                                          color: Colors.black12),
                                    ),
                                    Positioned(
                                      top: 12,
                                      left: 12,
                                      child: Container(
                                        padding: const EdgeInsets.symmetric(
                                            horizontal: 8, vertical: 4),
                                        decoration: BoxDecoration(
                                          color: status == 'COMPLETED'
                                              ? Colors.green
                                              : (status == 'IN PROGRESS'
                                                  ? M4Theme.premiumBlue
                                                  : Colors.black54),
                                          borderRadius:
                                              BorderRadius.circular(4),
                                        ),
                                        child: Text(status,
                                            style: GoogleFonts.montserrat(
                                                fontSize: 7,
                                                fontWeight: FontWeight.w900,
                                                color: Colors.white,
                                                letterSpacing: 1)),
                                      ),
                                    ),
                                  ],
                                ),
                                Padding(
                                  padding: const EdgeInsets.all(16),
                                  child: Row(
                                    children: [
                                      Text('$progress%',
                                          style: GoogleFonts.montserrat(
                                              fontSize: 14,
                                              fontWeight: FontWeight.w900,
                                              color: M4Theme.premiumBlue)),
                                      const SizedBox(width: 10),
                                      Expanded(
                                        child: Text(
                                          (phase['name'] ??
                                                  phase['phaseName'] ??
                                                  'PHASE')
                                              .toString()
                                              .toUpperCase(),
                                          maxLines: 1,
                                          overflow: TextOverflow.ellipsis,
                                          style: GoogleFonts.montserrat(
                                              fontSize: 9,
                                              fontWeight: FontWeight.w900,
                                              color: (isDark
                                                      ? Colors.white
                                                      : Colors.black)
                                                  .withValues(alpha: 0.7),
                                              letterSpacing: 1),
                                        ),
                                      ),
                                    ],
                                  ),
                                ),
                              ],
                            ),
                          ),
                        );
                      },
                    ),
                  ),
                ],
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildPaymentPlansSection(bool isDark) {
    if (_paymentPlans.isEmpty) return const SizedBox.shrink();
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 24),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          _sectionHeader('Payment Plans', isDark),
          const SizedBox(height: 16),
          ..._paymentPlans.map((plan) {
            final name = (plan is Map
                    ? plan['name']?.toString()
                    : plan.toString()) ??
                'STANDARD PLAN';
            final items = plan is Map ? (plan['items'] as List? ?? []) : [];
            return Container(
              margin: const EdgeInsets.only(bottom: 16),
              padding: const EdgeInsets.all(24),
              decoration: BoxDecoration(
                color: isDark
                    ? Colors.white.withValues(alpha: 0.03)
                    : const Color(0xFFF1F5F9),
                borderRadius: BorderRadius.circular(32),
                border: Border.all(
                    color: isDark
                        ? Colors.white.withValues(alpha: 0.08)
                        : Colors.black.withValues(alpha: 0.06)),
              ),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      Expanded(
                        child: Text(name.toUpperCase(),
                            style: GoogleFonts.montserrat(
                                fontSize: 11,
                                fontWeight: FontWeight.w900,
                                color: isDark ? Colors.white : Colors.black,
                                letterSpacing: 0.5)),
                      ),
                      const Icon(LucideIcons.wallet,
                          color: M4Theme.premiumBlue, size: 16),
                    ],
                  ),
                  const SizedBox(height: 20),
                  ...items.map((item) => Padding(
                        padding: const EdgeInsets.only(bottom: 12),
                        child: Row(
                          children: [
                            Container(
                              width: 40,
                              height: 40,
                              decoration: BoxDecoration(
                                  color: M4Theme.premiumBlue
                                      .withValues(alpha: 0.1),
                                  shape: BoxShape.circle),
                              child: Center(
                                child: Text('${item['percentage'] ?? 0}%',
                                    style: GoogleFonts.montserrat(
                                        fontSize: 10,
                                        fontWeight: FontWeight.w900,
                                        color: M4Theme.premiumBlue)),
                              ),
                            ),
                            const SizedBox(width: 16),
                            Expanded(
                              child: Column(
                                crossAxisAlignment:
                                    CrossAxisAlignment.start,
                                children: [
                                  Text(
                                      item['description']
                                              ?.toString()
                                              .toUpperCase() ??
                                          'INSTALLMENT',
                                      style: GoogleFonts.montserrat(
                                          fontSize: 9,
                                          fontWeight: FontWeight.w900,
                                          color: isDark
                                              ? Colors.white
                                              : Colors.black,
                                          letterSpacing: 0.5)),
                                  Text(
                                      'INSTALLMENT ${item['installmentNumber'] ?? ''}',
                                      style: GoogleFonts.montserrat(
                                          fontSize: 8,
                                          fontWeight: FontWeight.bold,
                                          color: isDark
                                              ? Colors.white38
                                              : Colors.black38)),
                                ],
                              ),
                            ),
                          ],
                        ),
                      )),
                  const SizedBox(height: 4),
                  GestureDetector(
                    onTap: () => _openInquiry('General', planName: name),
                    child: Container(
                      width: double.infinity,
                      padding: const EdgeInsets.symmetric(vertical: 14),
                      decoration: BoxDecoration(
                          color: M4Theme.premiumBlue.withValues(alpha: 0.1),
                          borderRadius: BorderRadius.circular(14)),
                      child: Center(
                        child: Text('INQUIRE ABOUT THIS PLAN',
                            style: GoogleFonts.montserrat(
                                fontSize: 9,
                                fontWeight: FontWeight.w900,
                                color: M4Theme.premiumBlue,
                                letterSpacing: 1)),
                      ),
                    ),
                  ),
                ],
              ),
            );
          }),
        ],
      ),
    );
  }

  Widget _buildInvestSection(Map<String, dynamic> project, bool isDark) {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 24),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          _sectionHeader('Contact', isDark),
          const SizedBox(height: 16),
          Container(
            padding: const EdgeInsets.all(20),
            decoration: BoxDecoration(
              color:
                  isDark ? Colors.white.withValues(alpha: 0.03) : Colors.white,
              borderRadius: BorderRadius.circular(28),
              border: Border.all(
                  color: isDark
                      ? Colors.white.withValues(alpha: 0.08)
                      : Colors.black.withValues(alpha: 0.06)),
              boxShadow: isDark
                  ? []
                  : [
                      BoxShadow(
                          color: Colors.black.withValues(alpha: 0.05),
                          blurRadius: 20,
                          offset: const Offset(0, 10))
                    ],
            ),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text('READY TO INVEST?',
                              style: GoogleFonts.montserrat(
                                  fontSize: 12,
                                  fontWeight: FontWeight.w900,
                                  color:
                                      isDark ? Colors.white : Colors.black)),
                          const SizedBox(height: 4),
                          Text('CONNECT WITH OUR WEALTH ADVISORS',
                              style: GoogleFonts.montserrat(
                                  fontSize: 8,
                                  fontWeight: FontWeight.w900,
                                  color: isDark
                                      ? Colors.white38
                                      : Colors.black38,
                                  letterSpacing: 1)),
                        ],
                      ),
                    ),
                    _RoundIcon(
                        icon: LucideIcons.phone,
                        isDark: isDark,
                        onTap: () => _openInquiry('General')),
                    const SizedBox(width: 10),
                    _RoundIcon(
                        icon: LucideIcons.messageCircle,
                        isDark: isDark,
                        onTap: () => _openInquiry('General')),
                  ],
                ),
                const SizedBox(height: 20),
                GestureDetector(
                  onTap: () => _openInquiry('General'),
                  child: Container(
                    width: double.infinity,
                    padding: const EdgeInsets.symmetric(vertical: 20),
                    decoration: BoxDecoration(
                        color: isDark ? Colors.white : Colors.black,
                        borderRadius: BorderRadius.circular(20)),
                    child: Center(
                      child: Text('INVEST IN THIS PROJECT NOW',
                          style: GoogleFonts.montserrat(
                              fontSize: 11,
                              fontWeight: FontWeight.w900,
                              color: isDark ? Colors.black : Colors.white,
                              letterSpacing: 2)),
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

  Widget _buildLocationSection(Map<String, dynamic> project, bool isDark) {
    final locName = _locationLabel(project);
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 24),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          _sectionHeader('Location', isDark),
          const SizedBox(height: 24),
          GestureDetector(
            onTap: () => _openUrl(
                'https://www.google.com/maps?q=${Uri.encodeComponent(locName)}'),
            child: Container(
              height: 220,
              width: double.infinity,
              decoration: BoxDecoration(
                color: isDark
                    ? Colors.white.withValues(alpha: 0.03)
                    : const Color(0xFFF4F4F5),
                borderRadius: BorderRadius.circular(32),
                border: Border.all(
                    color: isDark
                        ? Colors.white.withValues(alpha: 0.08)
                        : Colors.black.withValues(alpha: 0.06)),
              ),
              child: ClipRRect(
                borderRadius: BorderRadius.circular(32),
                child: Stack(
                  fit: StackFit.expand,
                  children: [
                    CachedNetworkImage(
                      imageUrl:
                          'https://images.unsplash.com/photo-1524661135-423995f22d0b?auto=format&fit=crop&q=80',
                      fit: BoxFit.cover,
                      color: isDark
                          ? Colors.black.withValues(alpha: 0.6)
                          : Colors.white.withValues(alpha: 0.6),
                      colorBlendMode: BlendMode.dstATop,
                      placeholder: (c, u) => Container(
                          color: isDark ? Colors.black26 : Colors.black12),
                      errorWidget: (c, u, e) =>
                          Container(color: Colors.black12),
                    ),
                    Positioned(
                      bottom: 20,
                      right: 20,
                      child: Container(
                        padding: const EdgeInsets.symmetric(
                            horizontal: 16, vertical: 10),
                        decoration: BoxDecoration(
                            color: isDark
                                ? const Color(0xFF1E293B)
                                : Colors.white.withValues(alpha: 0.9),
                            borderRadius: BorderRadius.circular(30)),
                        child: Row(
                          mainAxisSize: MainAxisSize.min,
                          children: [
                            const Icon(LucideIcons.mapPin,
                                color: M4Theme.premiumBlue, size: 12),
                            const SizedBox(width: 8),
                            Text('VIEW ON MAPS',
                                style: GoogleFonts.montserrat(
                                    fontSize: 8,
                                    fontWeight: FontWeight.w900,
                                    color: isDark
                                        ? Colors.white
                                        : Colors.black,
                                    letterSpacing: 1)),
                          ],
                        ),
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

  // ─── Helpers ───────────────────────────────────────────────────────────────
  Widget _sectionHeader(String title, bool isDark) {
    return Row(
      children: [
        Container(
            width: 40, height: 1.5, color: isDark ? Colors.white : Colors.black),
        const SizedBox(width: 16),
        Text(title.toUpperCase(),
            style: GoogleFonts.montserrat(
                fontSize: 12,
                fontWeight: FontWeight.w900,
                color: isDark ? Colors.white : Colors.black,
                letterSpacing: 4)),
      ],
    );
  }

  String _locationLabel(Map<String, dynamic> project) {
    final loc = project['location'];
    if (loc is Map) return (loc['name']?.toString() ?? 'N/A');
    if (loc is String && loc.isNotEmpty) return loc;
    return (project['locationName']?.toString() ?? 'N/A');
  }

  IconData _amenityIcon(String? name) {
    final n = name?.toLowerCase() ?? '';
    if (n.contains('lounge')) return LucideIcons.armchair;
    if (n.contains('reading')) return LucideIcons.bookOpen;
    if (n.contains('gym')) return LucideIcons.dumbbell;
    if (n.contains('pool')) return LucideIcons.waves;
    if (n.contains('jogging') || n.contains('track')) return LucideIcons.wind;
    if (n.contains('garden') || n.contains('park')) return LucideIcons.trees;
    if (n.contains('fire') || n.contains('pit')) return LucideIcons.flame;
    if (n.contains('playground') || n.contains('kids')) {
      return LucideIcons.toyBrick;
    }
    if (n.contains('clubhouse')) return LucideIcons.building2;
    if (n.contains('security')) return LucideIcons.shieldCheck;
    if (n.contains('parking')) return LucideIcons.car;
    if (n.contains('sunroof')) return LucideIcons.umbrella;
    return LucideIcons.sparkles;
  }
}

// ─── Small reusable widgets ────────────────────────────────────────────────
class _SquareAction extends StatelessWidget {
  final IconData icon;
  final VoidCallback onTap;
  const _SquareAction({required this.icon, required this.onTap});

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    return GestureDetector(
      onTap: onTap,
      child: Container(
        width: 40,
        height: 40,
        decoration: BoxDecoration(
          color: isDark ? Colors.white.withValues(alpha: 0.1) : Colors.white,
          borderRadius: BorderRadius.circular(12),
          border: Border.all(
              color: (isDark ? Colors.white : Colors.black)
                  .withValues(alpha: 0.06)),
          boxShadow: isDark
              ? []
              : [
                  BoxShadow(
                      color: Colors.black.withValues(alpha: 0.05),
                      blurRadius: 10,
                      offset: const Offset(0, 4))
                ],
        ),
        child: Icon(icon, color: isDark ? Colors.white : Colors.black, size: 20),
      ),
    );
  }
}

class _MediaThumb extends StatelessWidget {
  final String label;
  final String? imageUrl;
  final VoidCallback onTap;
  const _MediaThumb(
      {required this.label, this.imageUrl, required this.onTap});

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onTap,
      child: ClipRRect(
        borderRadius: BorderRadius.circular(16),
        child: BackdropFilter(
          filter: ImageFilter.blur(sigmaX: 5, sigmaY: 5),
          child: Container(
            width: 60,
            height: 60,
            decoration: BoxDecoration(
              color: Colors.black.withValues(alpha: 0.2),
              borderRadius: BorderRadius.circular(16),
              border: Border.all(
                  color: Colors.white.withValues(alpha: 0.2), width: 1.5),
            ),
            clipBehavior: Clip.antiAlias,
            child: Stack(
              fit: StackFit.expand,
              children: [
                if (imageUrl != null && imageUrl!.isNotEmpty)
                  CachedNetworkImage(
                    imageUrl: imageUrl!,
                    fit: BoxFit.cover,
                    errorWidget: (c, u, e) => Container(color: Colors.white10),
                    placeholder: (c, u) => Container(color: Colors.white10),
                  ),
                Container(color: Colors.black.withValues(alpha: 0.3)),
                Center(
                  child: Text(label,
                      textAlign: TextAlign.center,
                      style: GoogleFonts.montserrat(
                          color: Colors.white,
                          fontSize: 8,
                          fontWeight: FontWeight.w900,
                          letterSpacing: 0.5)),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}

class _IconThumb extends StatelessWidget {
  final String label;
  final IconData icon;
  final bool isDark;
  final VoidCallback onTap;
  const _IconThumb(
      {required this.label,
      required this.icon,
      required this.isDark,
      required this.onTap});

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        width: 60,
        height: 60,
        decoration: BoxDecoration(
          color: isDark ? Colors.white.withValues(alpha: 0.03) : Colors.white,
          borderRadius: BorderRadius.circular(16),
          border: Border.all(
              color: isDark
                  ? Colors.white.withValues(alpha: 0.08)
                  : Colors.black.withValues(alpha: 0.06)),
        ),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(icon, size: 20, color: isDark ? Colors.white : Colors.black),
            const SizedBox(height: 4),
            Text(label,
                style: GoogleFonts.montserrat(
                    fontSize: 6.5,
                    fontWeight: FontWeight.w900,
                    color: isDark ? Colors.white : Colors.black,
                    letterSpacing: 0.5)),
          ],
        ),
      ),
    );
  }
}

class _ActionCard extends StatelessWidget {
  final String label;
  final String value;
  final IconData icon;
  final bool isAction;
  final VoidCallback? onTap;
  const _ActionCard(
      {required this.label,
      required this.value,
      required this.icon,
      this.isAction = false,
      this.onTap});

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    return GestureDetector(
      onTap: onTap,
      child: Container(
        height: 140,
        padding: const EdgeInsets.symmetric(vertical: 24, horizontal: 8),
        decoration: BoxDecoration(
          color: isDark ? Colors.white.withValues(alpha: 0.03) : Colors.white,
          borderRadius: BorderRadius.circular(32),
          border: Border.all(
              color: isDark
                  ? Colors.white.withValues(alpha: 0.08)
                  : Colors.black.withValues(alpha: 0.06)),
          boxShadow: isDark
              ? []
              : [
                  BoxShadow(
                      color: Colors.black.withValues(alpha: 0.05),
                      blurRadius: 20,
                      offset: const Offset(0, 10))
                ],
        ),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            Icon(icon,
                color: isDark ? Colors.white38 : Colors.black38, size: 24),
            Column(
              children: [
                Text(label.toUpperCase(),
                    textAlign: TextAlign.center,
                    style: GoogleFonts.montserrat(
                        color: isDark ? Colors.white38 : Colors.black38,
                        fontSize: 8,
                        fontWeight: FontWeight.w900,
                        letterSpacing: 1.5)),
                const SizedBox(height: 4),
                Text(value,
                    textAlign: TextAlign.center,
                    style: GoogleFonts.montserrat(
                        color: isDark ? Colors.white : Colors.black,
                        fontSize: 13,
                        fontWeight: FontWeight.w900,
                        letterSpacing: -0.2)),
              ],
            ),
          ],
        ),
      ),
    );
  }
}

class _AssetCard extends StatelessWidget {
  final String title;
  final String subtitle;
  final IconData icon;
  final bool isDark;
  final VoidCallback onView;
  final VoidCallback onDownload;
  const _AssetCard(
      {required this.title,
      required this.subtitle,
      required this.icon,
      required this.isDark,
      required this.onView,
      required this.onDownload});

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 18),
      decoration: BoxDecoration(
        color: isDark ? Colors.white.withValues(alpha: 0.03) : Colors.white,
        borderRadius: BorderRadius.circular(24),
        border: Border.all(
            color: isDark
                ? Colors.white.withValues(alpha: 0.08)
                : Colors.black.withValues(alpha: 0.06)),
        boxShadow: isDark
            ? []
            : [
                BoxShadow(
                    color: Colors.black.withValues(alpha: 0.04),
                    blurRadius: 20,
                    offset: const Offset(0, 8))
              ],
      ),
      child: Row(
        children: [
          Container(
            padding: const EdgeInsets.all(12),
            decoration: BoxDecoration(
                color: M4Theme.premiumBlue.withValues(alpha: 0.1),
                borderRadius: BorderRadius.circular(14)),
            child: Icon(icon, color: M4Theme.premiumBlue, size: 18),
          ),
          const SizedBox(width: 14),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(title,
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                    style: GoogleFonts.montserrat(
                        fontSize: 10,
                        fontWeight: FontWeight.w900,
                        color: isDark ? Colors.white : Colors.black,
                        letterSpacing: 0.5)),
                const SizedBox(height: 4),
                Text(subtitle,
                    style: GoogleFonts.montserrat(
                        fontSize: 8,
                        fontWeight: FontWeight.w900,
                        color: isDark ? Colors.white38 : Colors.black38,
                        letterSpacing: 1)),
              ],
            ),
          ),
          const SizedBox(width: 8),
          _AssetButton(label: 'VIEW', onTap: onView),
          const SizedBox(width: 8),
          _AssetButton(label: 'GET', onTap: onDownload),
        ],
      ),
    );
  }
}

class _AssetButton extends StatelessWidget {
  final String label;
  final VoidCallback onTap;
  const _AssetButton({required this.label, required this.onTap});

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    return GestureDetector(
      onTap: onTap,
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
        decoration: BoxDecoration(
            color: isDark ? Colors.white : Colors.black,
            borderRadius: BorderRadius.circular(10)),
        child: Text(label,
            style: GoogleFonts.montserrat(
                fontSize: 7.5,
                fontWeight: FontWeight.w900,
                color: isDark ? Colors.black : Colors.white,
                letterSpacing: 1.0)),
      ),
    );
  }
}

class _RoundIcon extends StatelessWidget {
  final IconData icon;
  final bool isDark;
  final VoidCallback onTap;
  const _RoundIcon(
      {required this.icon, required this.isDark, required this.onTap});

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        width: 44,
        height: 44,
        decoration: BoxDecoration(
          color: isDark
              ? Colors.white.withValues(alpha: 0.05)
              : const Color(0xFFF4F4F5),
          borderRadius: BorderRadius.circular(14),
          border: Border.all(
              color: isDark
                  ? Colors.white.withValues(alpha: 0.08)
                  : Colors.black.withValues(alpha: 0.06)),
        ),
        child: Icon(icon, size: 18, color: isDark ? Colors.white : Colors.black),
      ),
    );
  }
}

class _InquiryField extends StatelessWidget {
  final String hint;
  final TextEditingController controller;
  final IconData icon;
  const _InquiryField(
      {required this.hint, required this.controller, required this.icon});

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 4),
      decoration: BoxDecoration(
        color: isDark
            ? Colors.white.withValues(alpha: 0.03)
            : const Color(0xFFF8FAFC),
        borderRadius: BorderRadius.circular(12),
        border: Border.all(
            color: isDark
                ? Colors.white.withValues(alpha: 0.08)
                : Colors.black.withValues(alpha: 0.08)),
      ),
      child: TextField(
        controller: controller,
        style: GoogleFonts.montserrat(
            fontSize: 12,
            fontWeight: FontWeight.bold,
            color: isDark ? Colors.white : Colors.black),
        decoration: InputDecoration(
          border: InputBorder.none,
          hintText: hint,
          hintStyle: GoogleFonts.montserrat(
              fontSize: 9,
              fontWeight: FontWeight.w900,
              color: isDark ? Colors.white24 : Colors.black26,
              letterSpacing: 1),
          icon: Icon(icon, size: 14, color: M4Theme.premiumBlue),
        ),
      ),
    );
  }
}
