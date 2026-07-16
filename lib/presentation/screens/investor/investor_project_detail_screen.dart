import 'dart:math' as math;
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

  /// The project the caller already has (passed as go_router `extra`). Used to
  /// render immediately and — importantly — to stay usable when [projectId]
  /// isn't a real ObjectId: while the bloated catalog endpoint is loading the
  /// list falls back to placeholder projects whose ids are slugs ('cledor'), so
  /// re-fetching by id 404s and the screen showed "PROJECT NOT FOUND".
  final Map<String, dynamic>? projectData;

  const InvestorProjectDetailScreen({
    super.key,
    required this.projectId,
    this.projectData,
  });

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
    // Render straight away from what the caller already handed us; the fetch
    // below only enriches it (payment plans, progress, galleries).
    if (widget.projectData != null) {
      _project = Map<String, dynamic>.from(widget.projectData!);
      _isLoading = false;
    }
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
      // Don't flash a spinner over content we can already show.
      _isLoading = _project == null;
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
      if (results[0].data['status'] == true &&
          results[0].data['data'] != null) {
        project = Map<String, dynamic>.from(results[0].data['data'] as Map);

        final media = project['media'] as List? ?? [];

        final List<String> ext = [];
        if (project['exteriorImages'] != null) {
          ext.addAll(
            (project['exteriorImages'] as List).map((e) => e.toString()),
          );
        }
        ext.addAll(
          media
              .where(
                (m) => m['category']?.toString().toUpperCase() == 'EXTERIOR',
              )
              .map((m) => m['url'].toString()),
        );
        _exteriorImages = ext.toSet().toList();

        final List<String> intr = [];
        if (project['interiorImages'] != null) {
          intr.addAll(
            (project['interiorImages'] as List).map((e) => e.toString()),
          );
        }
        intr.addAll(
          media
              .where(
                (m) => m['category']?.toString().toUpperCase() == 'INTERIOR',
              )
              .map((m) => m['url'].toString()),
        );
        _interiorImages = intr.toSet().toList();

        _paymentPlans = project['paymentPlans'] as List? ?? [];
      }

      if (results[1].data['status'] == true) {
        _progressPhases = results[1].data['data'] ?? [];
      }

      setState(() {
        // Keep what the caller gave us if the lookup came back empty — only
        // dead-end when we have nothing at all to show.
        _project = project ?? _project;
        _isLoading = false;
        _hasError = _project == null;
      });
    } catch (_) {
      if (mounted) {
        setState(() {
          _isLoading = false;
          // A failed enrich must not blank out a project we can already render.
          _hasError = _project == null;
        });
      }
    }
  }

  void _toast(String message) {
    if (!mounted) return;
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(
          message,
          style: GoogleFonts.dmSerifDisplay(
            fontSize: 12,
            fontWeight: FontWeight.bold,
          ),
        ),
        backgroundColor: M4Theme.premiumBlue,
        behavior: SnackBarBehavior.floating,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
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
      _nameController.text =
          authUser['fullName']?.toString() ??
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
        // Server-side enums: interest = Buying | Selling | Site Visit | Video
        // Call (case-sensitive); source = online | cp | walk-in | referral |
        // other. 'Investing' / 'mobile_app' were rejected with a 400.
        'interest': type == 'VC'
            ? 'Video Call'
            : type == 'Site Visit'
            ? 'Site Visit'
            : 'Buying',
        'source': 'online',
        // Only ever send a real ObjectId — widget.projectId can be a route slug,
        // which makes the API reject the whole lead (CastToObjectId/BSONError).
        if (widget.projectId.length == 24) 'projectId': widget.projectId,
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
        _toast(
          type == 'General'
              ? 'Inquiry submitted! Our advisor will contact you shortly.'
              : 'Booking request received! Our team will call you to confirm the time.',
        );
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
              bottom: MediaQuery.of(sheetContext).viewInsets.bottom + 20,
            ),
            constraints: BoxConstraints(
              maxHeight: MediaQuery.of(sheetContext).size.height * 0.9,
            ),
            decoration: BoxDecoration(
              color: isDark ? const Color(0xFF0F1115) : Colors.white,
              borderRadius: const BorderRadius.vertical(
                top: Radius.circular(40),
              ),
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
                      borderRadius: BorderRadius.circular(2),
                    ),
                  ),
                  Align(
                    alignment: Alignment.topRight,
                    child: IconButton(
                      onPressed: () => Navigator.pop(sheetContext),
                      icon: Icon(
                        LucideIcons.x,
                        color: isDark ? Colors.white38 : Colors.black38,
                        size: 20,
                      ),
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
                          style: GoogleFonts.dmSerifDisplay(
                            fontSize: 30,
                            fontWeight: FontWeight.w900,
                            color: isDark ? Colors.white : Colors.black,
                            height: 1.1,
                            letterSpacing: -1.2,
                          ),
                        ),
                        const SizedBox(height: 14),
                        Text(
                          'A BESPOKE SHOWCASE OF LUXURY AT ${title.toUpperCase()}.',
                          style: GoogleFonts.dmSerifDisplay(
                            fontSize: 9,
                            color: isDark ? Colors.white38 : Colors.black38,
                            fontWeight: FontWeight.w900,
                            letterSpacing: 1,
                          ),
                        ),
                        const SizedBox(height: 32),
                        _InquiryField(
                          hint: 'FULL NAME *',
                          controller: _nameController,
                          icon: LucideIcons.user,
                        ),
                        const SizedBox(height: 14),
                        _InquiryField(
                          hint: 'EMAIL ADDRESS',
                          controller: _emailController,
                          icon: LucideIcons.mail,
                        ),
                        const SizedBox(height: 14),
                        _InquiryField(
                          hint: 'PHONE NUMBER *',
                          controller: _phoneController,
                          icon: LucideIcons.phone,
                        ),

                        // Plan select
                        if (_paymentPlans.isNotEmpty) ...[
                          const SizedBox(height: 28),
                          Text(
                            'PREFERRED PLAN',
                            style: GoogleFonts.dmSerifDisplay(
                              fontSize: 8,
                              fontWeight: FontWeight.w900,
                              color: isDark ? Colors.white38 : Colors.black38,
                              letterSpacing: 1,
                            ),
                          ),
                          const SizedBox(height: 12),
                          Wrap(
                            spacing: 8,
                            runSpacing: 8,
                            children: _paymentPlans.map((plan) {
                              final n =
                                  (plan is Map
                                      ? plan['name']?.toString()
                                      : plan.toString()) ??
                                  'PLAN';
                              final isActive = planName == n;
                              return GestureDetector(
                                onTap: () => setModalState(() => planName = n),
                                child: Container(
                                  padding: const EdgeInsets.symmetric(
                                    horizontal: 16,
                                    vertical: 12,
                                  ),
                                  decoration: BoxDecoration(
                                    color: isActive
                                        ? M4Theme.premiumBlue
                                        : Colors.transparent,
                                    borderRadius: BorderRadius.circular(10),
                                    border: Border.all(
                                      color: isActive
                                          ? M4Theme.premiumBlue
                                          : (isDark
                                                ? Colors.white.withValues(
                                                    alpha: 0.1,
                                                  )
                                                : Colors.black.withValues(
                                                    alpha: 0.08,
                                                  )),
                                    ),
                                  ),
                                  child: Text(
                                    n.toUpperCase(),
                                    style: GoogleFonts.dmSerifDisplay(
                                      fontSize: 8,
                                      fontWeight: FontWeight.w900,
                                      color: isActive
                                          ? Colors.white
                                          : (isDark
                                                ? Colors.white38
                                                : Colors.black38),
                                    ),
                                  ),
                                ),
                              );
                            }).toList(),
                          ),
                        ],

                        // Visit type toggle + schedule
                        if (localType == 'VC' || localType == 'Site Visit') ...[
                          const SizedBox(height: 28),
                          Text(
                            'VISIT TYPE',
                            style: GoogleFonts.dmSerifDisplay(
                              fontSize: 8,
                              fontWeight: FontWeight.w900,
                              color: isDark ? Colors.white38 : Colors.black38,
                              letterSpacing: 1,
                            ),
                          ),
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
                                        right: t == 'Site Visit' ? 8 : 0,
                                      ),
                                      padding: const EdgeInsets.symmetric(
                                        vertical: 12,
                                      ),
                                      decoration: BoxDecoration(
                                        color: localType == t
                                            ? (isDark
                                                  ? Colors.white
                                                  : Colors.black)
                                            : Colors.transparent,
                                        borderRadius: BorderRadius.circular(10),
                                        border: Border.all(
                                          color: isDark
                                              ? Colors.white.withValues(
                                                  alpha: 0.1,
                                                )
                                              : Colors.black.withValues(
                                                  alpha: 0.08,
                                                ),
                                        ),
                                      ),
                                      child: Center(
                                        child: Text(
                                          t == 'VC'
                                              ? 'VIDEO CALL'
                                              : 'SITE VISIT',
                                          style: GoogleFonts.dmSerifDisplay(
                                            fontSize: 9,
                                            fontWeight: FontWeight.w900,
                                            color: localType == t
                                                ? (isDark
                                                      ? Colors.black
                                                      : Colors.white)
                                                : (isDark
                                                      ? Colors.white38
                                                      : Colors.black38),
                                            letterSpacing: 1,
                                          ),
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
                                  scheduledAt ?? now,
                                ),
                              );
                              if (time == null) return;
                              setModalState(() {
                                scheduledAt = DateTime(
                                  date.year,
                                  date.month,
                                  date.day,
                                  time.hour,
                                  time.minute,
                                );
                              });
                            },
                            child: Container(
                              width: double.infinity,
                              padding: const EdgeInsets.symmetric(
                                horizontal: 20,
                                vertical: 18,
                              ),
                              decoration: BoxDecoration(
                                color: isDark
                                    ? Colors.white.withValues(alpha: 0.03)
                                    : const Color(0xFFF8FAFC),
                                borderRadius: BorderRadius.circular(12),
                                border: Border.all(
                                  color: isDark
                                      ? Colors.white.withValues(alpha: 0.08)
                                      : Colors.black.withValues(alpha: 0.08),
                                ),
                              ),
                              child: Row(
                                children: [
                                  const Icon(
                                    LucideIcons.calendar,
                                    size: 14,
                                    color: M4Theme.premiumBlue,
                                  ),
                                  const SizedBox(width: 12),
                                  Text(
                                    scheduledAt == null
                                        ? 'SELECT DATE & TIME'
                                        : _formatSchedule(scheduledAt!),
                                    style: GoogleFonts.dmSerifDisplay(
                                      fontSize: 9,
                                      fontWeight: FontWeight.w900,
                                      color: scheduledAt == null
                                          ? (isDark
                                                ? Colors.white24
                                                : Colors.black26)
                                          : (isDark
                                                ? Colors.white
                                                : Colors.black),
                                      letterSpacing: 1,
                                    ),
                                  ),
                                ],
                              ),
                            ),
                          ),
                        ],

                        // Notes
                        const SizedBox(height: 24),
                        Text(
                          'ADDITIONAL NOTES',
                          style: GoogleFonts.dmSerifDisplay(
                            fontSize: 8,
                            fontWeight: FontWeight.w900,
                            color: isDark ? Colors.white38 : Colors.black38,
                            letterSpacing: 1,
                          ),
                        ),
                        const SizedBox(height: 12),
                        Container(
                          padding: const EdgeInsets.symmetric(
                            horizontal: 16,
                            vertical: 4,
                          ),
                          decoration: BoxDecoration(
                            color: isDark
                                ? Colors.white.withValues(alpha: 0.03)
                                : const Color(0xFFF8FAFC),
                            borderRadius: BorderRadius.circular(12),
                            border: Border.all(
                              color: isDark
                                  ? Colors.white.withValues(alpha: 0.08)
                                  : Colors.black.withValues(alpha: 0.08),
                            ),
                          ),
                          child: TextField(
                            controller: _notesController,
                            maxLines: 3,
                            style: GoogleFonts.dmSerifDisplay(
                              fontSize: 11,
                              fontWeight: FontWeight.bold,
                              color: isDark ? Colors.white : Colors.black,
                            ),
                            decoration: InputDecoration(
                              border: InputBorder.none,
                              hintText:
                                  'SPECIFIC REQUIREMENTS, PICKUP DETAILS, ETC...',
                              hintStyle: GoogleFonts.dmSerifDisplay(
                                fontSize: 9,
                                fontWeight: FontWeight.w900,
                                color: isDark ? Colors.white24 : Colors.black26,
                                letterSpacing: 1,
                              ),
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
                            padding: const EdgeInsets.symmetric(vertical: 20),
                            decoration: BoxDecoration(
                              color: isDark ? Colors.white : Colors.black,
                              borderRadius: BorderRadius.circular(14),
                            ),
                            child: Center(
                              child: Text(
                                _submitting ? 'SUBMITTING...' : ctaLabel,
                                style: GoogleFonts.dmSerifDisplay(
                                  color: isDark ? Colors.black : Colors.white,
                                  fontSize: 11,
                                  fontWeight: FontWeight.w900,
                                  letterSpacing: 2,
                                ),
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
  void _openGallery(List<String> urls, {int initialIndex = 0}) {
    if (urls.isEmpty) {
      _toast('Gallery coming soon!');
      return;
    }
    final apiClient = ref.read(apiClientProvider);
    final pageController = PageController(initialPage: initialIndex);
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
                      child: CircularProgressIndicator(color: Colors.white24),
                    ),
                    errorWidget: (c, u, e) => const Icon(
                      LucideIcons.image,
                      color: Colors.white24,
                      size: 50,
                    ),
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
                    shape: BoxShape.circle,
                  ),
                  child: const Icon(
                    LucideIcons.x,
                    color: Colors.white,
                    size: 20,
                  ),
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
          child: CircularProgressIndicator(color: M4Theme.premiumBlue),
        ),
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
                  Icon(
                    LucideIcons.building2,
                    size: 56,
                    color: (isDark ? Colors.white : Colors.black).withValues(
                      alpha: 0.3,
                    ),
                  ),
                  const SizedBox(height: 20),
                  Text(
                    'PROJECT NOT FOUND',
                    style: GoogleFonts.dmSerifDisplay(
                      fontSize: 16,
                      fontWeight: FontWeight.w900,
                      color: isDark ? Colors.white : Colors.black,
                      letterSpacing: 1,
                    ),
                  ),
                  const SizedBox(height: 10),
                  Text(
                    'The project you are looking for might have been moved or is no longer active.',
                    textAlign: TextAlign.center,
                    style: GoogleFonts.dmSerifDisplay(
                      fontSize: 11,
                      fontWeight: FontWeight.w600,
                      color: (isDark ? Colors.white : Colors.black).withValues(
                        alpha: 0.5,
                      ),
                    ),
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
                        horizontal: 32,
                        vertical: 14,
                      ),
                      decoration: BoxDecoration(
                        color: isDark ? Colors.white : Colors.black,
                        borderRadius: BorderRadius.circular(30),
                      ),
                      child: Text(
                        'GO BACK',
                        style: GoogleFonts.dmSerifDisplay(
                          fontSize: 10,
                          fontWeight: FontWeight.w900,
                          color: isDark ? Colors.black : Colors.white,
                          letterSpacing: 1.5,
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
            _buildPhaseTrackingSection(isDark),
            const SizedBox(height: 32),
            _buildGallerySection(project, isDark),
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
            errorWidget: (c, u, e) => Container(
              color: Colors.black12,
              child: const Icon(Icons.error),
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
                  (isDark ? Colors.black : Colors.white).withValues(alpha: 0.9),
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
                  padding: const EdgeInsets.symmetric(
                    horizontal: 10,
                    vertical: 4,
                  ),
                  decoration: BoxDecoration(
                    color: Colors.black,
                    borderRadius: BorderRadius.circular(4),
                  ),
                  child: Text(
                    (project['status']?.toString().toUpperCase() ?? 'ONGOING'),
                    style: GoogleFonts.dmSerifDisplay(
                      color: Colors.white,
                      fontSize: 8,
                      fontWeight: FontWeight.w900,
                      letterSpacing: 1,
                    ),
                  ),
                ),
                const SizedBox(height: 12),
                Text(
                  (project['title']?.toString() ?? 'Project Name')
                      .toUpperCase(),
                  style: GoogleFonts.dmSerifDisplay(
                    color: isDark ? Colors.white : Colors.black,
                    fontSize: 32,
                    height: 1.0,
                    fontWeight: FontWeight.w800,
                    letterSpacing: -1.5,
                  ),
                ),
                const SizedBox(height: 12),
                // Web parity: location sits in a bordered rounded pill, not as
                // plain inline text.
                Align(
                  alignment: Alignment.centerLeft,
                  child: Container(
                    padding: const EdgeInsets.symmetric(
                      horizontal: 14,
                      vertical: 8,
                    ),
                    decoration: BoxDecoration(
                      color: isDark
                          ? Colors.white.withValues(alpha: 0.06)
                          : Colors.white,
                      borderRadius: BorderRadius.circular(30),
                      border: Border.all(
                        color: (isDark ? Colors.white : Colors.black)
                            .withValues(alpha: 0.14),
                      ),
                    ),
                    child: Row(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        Icon(
                          LucideIcons.mapPin,
                          color: isDark ? Colors.white : Colors.black,
                          size: 13,
                        ),
                        const SizedBox(width: 6),
                        Text(
                          location,
                          style: GoogleFonts.dmSerifDisplay(
                            color: isDark ? Colors.white : Colors.black,
                            fontSize: 12,
                            fontWeight: FontWeight.w700,
                            letterSpacing: 0.3,
                          ),
                        ),
                      ],
                    ),
                  ),
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
                    'Check out ${project['title']} on M4 Family!',
                  ),
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
      (project['heroImage'] ?? project['coverImage'])?.toString(),
    );
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
    // Web parity: the overview block always shows a WALKTHROUGH card. Pull the
    // best-available video/tour link; _openUrl gracefully toasts if absent.
    final walkthrough =
        (project['walkthroughUrl'] ??
                project['videoUrl'] ??
                project['virtualTour'] ??
                project['walkthrough'] ??
                project['videoTour'])
            ?.toString();

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
            style: GoogleFonts.dmSerifDisplay(
              fontSize: 11,
              // Web parity: overview copy is rendered in the brand blue, not black.
              color: M4Theme.premiumBlue,
              fontWeight: FontWeight.w900,
              height: 1.6,
              letterSpacing: 0.5,
            ),
          ),
          if (startingPrice != null &&
              startingPrice.isNotEmpty &&
              startingPrice != 'N/A') ...[
            const SizedBox(height: 24),
            Row(
              children: [
                const Icon(
                  LucideIcons.indianRupee,
                  size: 16,
                  color: M4Theme.premiumBlue,
                ),
                const SizedBox(width: 8),
                Text(
                  'STARTING PRICE',
                  style: GoogleFonts.dmSerifDisplay(
                    fontSize: 8,
                    fontWeight: FontWeight.w900,
                    color: isDark ? Colors.white38 : Colors.black38,
                    letterSpacing: 1,
                  ),
                ),
                const SizedBox(width: 12),
                Text(
                  startingPrice,
                  style: GoogleFonts.dmSerifDisplay(
                    fontSize: 13,
                    fontWeight: FontWeight.w900,
                    color: isDark ? Colors.white : Colors.black,
                  ),
                ),
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
          // Web parity: WALKTHROUGH card below the flyer, single WATCH STORY CTA.
          const SizedBox(height: 16),
          _WalkthroughCard(
            isDark: isDark,
            onWatch: () => _openUrl(walkthrough),
          ),
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
      Text(
        'DOCUMENTS',
        style: GoogleFonts.dmSerifDisplay(
          fontSize: 8,
          fontWeight: FontWeight.w900,
          color: isDark ? Colors.white38 : Colors.black38,
          letterSpacing: 1,
        ),
      ),
      const SizedBox(height: 12),
      ...docs.map((doc) {
        final name =
            (doc is Map
                ? (doc['title'] ?? doc['name'])?.toString()
                : doc.toString()) ??
            'DOCUMENT';
        final url = doc is Map
            ? (doc['url'] ?? doc['file'])?.toString()
            : doc.toString();
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
            gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
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
              final title =
                  (plan is Map ? plan['title']?.toString() : plan.toString()) ??
                  'PLAN';
              final config = plan is Map ? plan['config']?.toString() : null;
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
                          : Colors.black.withValues(alpha: 0.06),
                    ),
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
                                  child: const Icon(
                                    LucideIcons.layoutGrid,
                                    color: Colors.white30,
                                  ),
                                ),
                              )
                            : Container(
                                color: isDark
                                    ? Colors.white.withValues(alpha: 0.04)
                                    : const Color(0xFFF4F4F5),
                                child: const Center(
                                  child: Icon(
                                    LucideIcons.layoutGrid,
                                    color: M4Theme.premiumBlue,
                                    size: 28,
                                  ),
                                ),
                              ),
                      ),
                      Padding(
                        padding: const EdgeInsets.all(14),
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(
                              title.toUpperCase(),
                              maxLines: 1,
                              overflow: TextOverflow.ellipsis,
                              style: GoogleFonts.dmSerifDisplay(
                                fontSize: 10,
                                fontWeight: FontWeight.w900,
                                color: isDark ? Colors.white : Colors.black,
                                letterSpacing: 0.5,
                              ),
                            ),
                            const SizedBox(height: 4),
                            Text(
                              [config, area]
                                  .where((e) => e != null && e.isNotEmpty)
                                  .join('  •  ')
                                  .toUpperCase(),
                              maxLines: 1,
                              overflow: TextOverflow.ellipsis,
                              style: GoogleFonts.dmSerifDisplay(
                                fontSize: 8,
                                fontWeight: FontWeight.w900,
                                color: isDark ? Colors.white38 : Colors.black38,
                                letterSpacing: 0.5,
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
              child: Text(
                'COMING SOON',
                style: GoogleFonts.dmSerifDisplay(
                  fontSize: 12,
                  color: isDark ? Colors.white38 : Colors.black38,
                ),
              ),
            )
          else
            GridView.builder(
              shrinkWrap: true,
              physics: const NeverScrollableScrollPhysics(),
              padding: EdgeInsets.zero,
              gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
                crossAxisCount: 3,
                mainAxisSpacing: 12,
                crossAxisSpacing: 12,
                childAspectRatio: 1.0,
              ),
              itemCount: amenities.length,
              itemBuilder: (context, index) {
                final amenity = amenities[index];
                final name =
                    (amenity is Map
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
                          : Colors.black.withValues(alpha: 0.06),
                    ),
                  ),
                  child: Column(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      Icon(_amenityIcon(name), color: _gold, size: 28),
                      const SizedBox(height: 16),
                      Padding(
                        padding: const EdgeInsets.symmetric(horizontal: 8),
                        child: Text(
                          name,
                          textAlign: TextAlign.center,
                          style: GoogleFonts.dmSerifDisplay(
                            fontSize: 8,
                            fontWeight: FontWeight.w900,
                            color: (isDark ? Colors.white : Colors.black)
                                .withValues(alpha: 0.8),
                            letterSpacing: 1,
                            height: 1.2,
                          ),
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
    final estimated =
        (project['estimatedCompletionDate'] ??
                project['possessionDate'] ??
                'Q1 2028')
            .toString();
    final overall = completion is num
        ? completion
        : num.tryParse('$completion') ?? 0;

    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 24),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          _sectionHeader('Construction Progress', isDark),
          const SizedBox(height: 24),
          Container(
            width: double.infinity,
            padding: const EdgeInsets.symmetric(horizontal: 28, vertical: 36),
            decoration: BoxDecoration(
              color: isDark
                  ? Colors.white.withValues(alpha: 0.03)
                  : const Color(0xFFF8FAFC),
              borderRadius: BorderRadius.circular(40),
              border: Border.all(
                color: isDark
                    ? Colors.white.withValues(alpha: 0.08)
                    : Colors.black.withValues(alpha: 0.06),
              ),
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
                          Text(
                            'ESTIMATED COMPLETION',
                            style: GoogleFonts.dmSerifDisplay(
                              fontSize: 9,
                              fontWeight: FontWeight.w900,
                              color: M4Theme.premiumBlue,
                              letterSpacing: 1,
                            ),
                          ),
                          const SizedBox(height: 12),
                          Text(
                            estimated.toUpperCase(),
                            style: GoogleFonts.dmSerifDisplay(
                              fontSize: 34,
                              fontWeight: FontWeight.w900,
                              height: 1.0,
                              color: isDark ? Colors.white : Colors.black,
                            ),
                          ),
                          const SizedBox(height: 20),
                          Text(
                            'As the project progresses, significant milestones are reached, showcasing our team\'s dedication and expertise. We are steadily moving closer to our completion goal, ensuring quality and safety at every step.',
                            maxLines: _showFullProgress ? null : 3,
                            overflow: _showFullProgress
                                ? TextOverflow.visible
                                : TextOverflow.ellipsis,
                            style: GoogleFonts.dmSerifDisplay(
                              fontSize: 10,
                              fontWeight: FontWeight.bold,
                              height: 1.6,
                              color: (isDark ? Colors.white : Colors.black)
                                  .withValues(alpha: 0.5),
                            ),
                          ),
                          const SizedBox(height: 8),
                          GestureDetector(
                            onTap: () => setState(
                              () => _showFullProgress = !_showFullProgress,
                            ),
                            child: Text(
                              _showFullProgress ? 'Show less' : 'Read more',
                              style: GoogleFonts.dmSerifDisplay(
                                fontSize: 10,
                                fontWeight: FontWeight.w900,
                                color: M4Theme.premiumBlue,
                              ),
                            ),
                          ),
                        ],
                      ),
                    ),
                    const SizedBox(width: 16),
                    SizedBox(
                      width: 104,
                      height: 104,
                      child: Stack(
                        alignment: Alignment.center,
                        children: [
                          // Web parity (matches the CP properties detail): a
                          // dotted/dashed ring rather than a solid arc.
                          Positioned.fill(
                            child: CustomPaint(
                              painter: _DottedProgressRingPainter(
                                progress: overall.toDouble() / 100,
                                color: M4Theme.premiumBlue,
                                trackColor:
                                    (isDark ? Colors.white : Colors.black)
                                        .withValues(alpha: 0.22),
                                dotCount: 46,
                                dotRadius: 1.7,
                                dashLength: 7,
                                margin: 7,
                              ),
                            ),
                          ),
                          Column(
                            mainAxisSize: MainAxisSize.min,
                            children: [
                              Text(
                                '${overall.toInt()}%',
                                style: GoogleFonts.dmSerifDisplay(
                                  fontSize: 22,
                                  fontWeight: FontWeight.w900,
                                  color: isDark ? Colors.white : Colors.black,
                                ),
                              ),
                              Text(
                                'OVERALL',
                                style: GoogleFonts.dmSerifDisplay(
                                  fontSize: 8,
                                  fontWeight: FontWeight.w900,
                                  color: isDark
                                      ? Colors.white38
                                      : Colors.black38,
                                  letterSpacing: 1,
                                ),
                              ),
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
                        final firstImg =
                            (phaseImages != null && phaseImages.isNotEmpty)
                            ? phaseImages[0]
                            : '';
                        final imageUrl = apiClient.resolveUrl(
                          phase['image'] ?? firstImg,
                        );
                        final status =
                            phase['status']?.toString().toUpperCase() ??
                            'UPCOMING';
                        final progress =
                            (phase['progressPercent'] ?? phase['progress'] ?? 0)
                                .toString();
                        return GestureDetector(
                          onTap: () {
                            if (imageUrl.isNotEmpty) {
                              _openGallery([
                                phase['image']?.toString() ??
                                    firstImg.toString(),
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
                                    : Colors.black.withValues(alpha: 0.06),
                              ),
                            ),
                            clipBehavior: Clip.antiAlias,
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
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
                                        color: Colors.black12,
                                      ),
                                      errorWidget: (c, u, e) => Container(
                                        height: 130,
                                        color: Colors.black12,
                                      ),
                                    ),
                                    Positioned(
                                      top: 12,
                                      left: 12,
                                      child: Container(
                                        padding: const EdgeInsets.symmetric(
                                          horizontal: 8,
                                          vertical: 4,
                                        ),
                                        decoration: BoxDecoration(
                                          color: status == 'COMPLETED'
                                              ? Colors.green
                                              : (status == 'IN PROGRESS'
                                                    ? M4Theme.premiumBlue
                                                    : Colors.black54),
                                          borderRadius: BorderRadius.circular(
                                            4,
                                          ),
                                        ),
                                        child: Text(
                                          status,
                                          style: GoogleFonts.dmSerifDisplay(
                                            fontSize: 7,
                                            fontWeight: FontWeight.w900,
                                            color: Colors.white,
                                            letterSpacing: 1,
                                          ),
                                        ),
                                      ),
                                    ),
                                  ],
                                ),
                                Padding(
                                  padding: const EdgeInsets.all(16),
                                  child: Row(
                                    children: [
                                      Text(
                                        '$progress%',
                                        style: GoogleFonts.dmSerifDisplay(
                                          fontSize: 14,
                                          fontWeight: FontWeight.w900,
                                          color: M4Theme.premiumBlue,
                                        ),
                                      ),
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
                                          style: GoogleFonts.dmSerifDisplay(
                                            fontSize: 9,
                                            fontWeight: FontWeight.w900,
                                            color:
                                                (isDark
                                                        ? Colors.white
                                                        : Colors.black)
                                                    .withValues(alpha: 0.7),
                                            letterSpacing: 1,
                                          ),
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

  // Web parity (image 4 / CP properties): "PHASE TRACKING" summary — a header
  // with a milestone-count badge, then one card per phase showing index, name,
  // status and a progress bar.
  Widget _buildPhaseTrackingSection(bool isDark) {
    if (_progressPhases.isEmpty) return const SizedBox.shrink();
    final phases = _progressPhases
        .whereType<Map>()
        .map((m) => Map<String, dynamic>.from(m))
        .toList();
    if (phases.isEmpty) return const SizedBox.shrink();

    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 24),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    'PHASE TRACKING',
                    style: GoogleFonts.dmSerifDisplay(
                      fontSize: 13,
                      fontWeight: FontWeight.w900,
                      letterSpacing: 2,
                      color: isDark ? Colors.white : Colors.black,
                    ),
                  ),
                  const SizedBox(height: 4),
                  Text(
                    'REAL-TIME DEVELOPMENT STATUS',
                    style: GoogleFonts.dmSerifDisplay(
                      fontSize: 8,
                      fontWeight: FontWeight.w900,
                      letterSpacing: 1,
                      color: isDark ? Colors.white38 : Colors.black38,
                    ),
                  ),
                ],
              ),
              Container(
                padding: const EdgeInsets.symmetric(
                  horizontal: 12,
                  vertical: 6,
                ),
                decoration: BoxDecoration(
                  borderRadius: BorderRadius.circular(999),
                  border: Border.all(
                    color: M4Theme.premiumBlue.withValues(alpha: 0.25),
                  ),
                  color: M4Theme.premiumBlue.withValues(alpha: 0.06),
                ),
                child: Text(
                  '${phases.length} MILESTONES',
                  style: GoogleFonts.dmSerifDisplay(
                    fontSize: 8,
                    fontWeight: FontWeight.w900,
                    letterSpacing: 1,
                    color: M4Theme.premiumBlue,
                  ),
                ),
              ),
            ],
          ),
          const SizedBox(height: 16),
          ...phases.asMap().entries.map((entry) {
            final i = entry.key;
            final ph = entry.value;
            final status = (ph['status'] ?? 'In Progress').toString();
            final name = (ph['name'] ?? ph['phaseName'] ?? 'Phase').toString();
            final pctRaw = ph['progressPercent'] ?? ph['progress'] ?? 0;
            final pct = (pctRaw is num)
                ? pctRaw.toInt().clamp(0, 100)
                : (int.tryParse('$pctRaw') ?? 0).clamp(0, 100);
            final isCompleted = status.toUpperCase() == 'COMPLETED';
            final statusColor = isCompleted
                ? Colors.green
                : M4Theme.premiumBlue;
            return Container(
              margin: const EdgeInsets.only(bottom: 12),
              padding: const EdgeInsets.all(16),
              decoration: BoxDecoration(
                color: isDark
                    ? Colors.white.withValues(alpha: 0.03)
                    : const Color(0xFFF8FAFC),
                borderRadius: BorderRadius.circular(20),
                border: Border.all(
                  color: isDark
                      ? Colors.white.withValues(alpha: 0.08)
                      : Colors.black.withValues(alpha: 0.06),
                ),
              ),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    children: [
                      Container(
                        width: 34,
                        height: 34,
                        alignment: Alignment.center,
                        decoration: BoxDecoration(
                          borderRadius: BorderRadius.circular(10),
                          color: (isDark ? Colors.white : Colors.black)
                              .withValues(alpha: 0.05),
                          border: Border.all(
                            color: (isDark ? Colors.white : Colors.black)
                                .withValues(alpha: 0.08),
                          ),
                        ),
                        child: Text(
                          (i + 1).toString().padLeft(2, '0'),
                          style: GoogleFonts.dmSerifDisplay(
                            fontSize: 11,
                            fontWeight: FontWeight.w900,
                            color: isDark ? Colors.white54 : Colors.black54,
                          ),
                        ),
                      ),
                      const SizedBox(width: 12),
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(
                              name.toUpperCase(),
                              maxLines: 1,
                              overflow: TextOverflow.ellipsis,
                              style: GoogleFonts.dmSerifDisplay(
                                fontSize: 11,
                                fontWeight: FontWeight.w900,
                                letterSpacing: 0.5,
                                color: isDark ? Colors.white : Colors.black,
                              ),
                            ),
                            const SizedBox(height: 3),
                            Row(
                              children: [
                                Container(
                                  width: 6,
                                  height: 6,
                                  decoration: BoxDecoration(
                                    color: statusColor,
                                    shape: BoxShape.circle,
                                  ),
                                ),
                                const SizedBox(width: 6),
                                Text(
                                  status.toUpperCase(),
                                  style: GoogleFonts.dmSerifDisplay(
                                    fontSize: 8,
                                    fontWeight: FontWeight.w900,
                                    letterSpacing: 1,
                                    color: statusColor,
                                  ),
                                ),
                              ],
                            ),
                          ],
                        ),
                      ),
                      Text(
                        '$pct%',
                        style: GoogleFonts.dmSerifDisplay(
                          fontSize: 16,
                          fontWeight: FontWeight.w900,
                          color: isDark ? Colors.white : Colors.black,
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 12),
                  ClipRRect(
                    borderRadius: BorderRadius.circular(999),
                    child: LinearProgressIndicator(
                      value: pct / 100,
                      minHeight: 6,
                      backgroundColor: (isDark ? Colors.white : Colors.black)
                          .withValues(alpha: 0.08),
                      valueColor: AlwaysStoppedAnimation<Color>(
                        isCompleted
                            ? Colors.green
                            : (isDark ? Colors.white : Colors.black),
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

  // Collects every usable image for the gallery grid: dedicated gallery/images
  // fields, the exterior/interior sets, and any media urls.
  List<String> _galleryImages() {
    final imgs = <String>[];
    void addList(dynamic v) {
      if (v is List) {
        for (final e in v) {
          if (e is String) {
            imgs.add(e);
          } else if (e is Map && e['url'] != null) {
            imgs.add(e['url'].toString());
          }
        }
      }
    }

    addList(_project?['gallery']);
    addList(_project?['images']);
    addList(_project?['galleryImages']);
    imgs.addAll(_exteriorImages);
    imgs.addAll(_interiorImages);
    addList(_project?['media']);
    return imgs.where((s) => s.trim().isNotEmpty).toSet().toList();
  }

  Widget _buildGallerySection(Map<String, dynamic> project, bool isDark) {
    final apiClient = ref.read(apiClientProvider);
    final images = _galleryImages();
    if (images.isEmpty) return const SizedBox.shrink();
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 24),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          _sectionHeader('Gallery', isDark),
          const SizedBox(height: 24),
          GridView.builder(
            shrinkWrap: true,
            physics: const NeverScrollableScrollPhysics(),
            padding: EdgeInsets.zero,
            gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
              crossAxisCount: 2,
              mainAxisSpacing: 12,
              crossAxisSpacing: 12,
              childAspectRatio: 1.1,
            ),
            itemCount: images.length,
            itemBuilder: (context, index) {
              return GestureDetector(
                onTap: () => _openGallery(images, initialIndex: index),
                child: ClipRRect(
                  borderRadius: BorderRadius.circular(20),
                  child: CachedNetworkImage(
                    imageUrl: apiClient.resolveUrl(images[index]),
                    fit: BoxFit.cover,
                    placeholder: (c, u) => Container(
                      color: isDark
                          ? Colors.white.withValues(alpha: 0.04)
                          : Colors.black12,
                    ),
                    errorWidget: (c, u, e) => Container(
                      color: isDark
                          ? Colors.white.withValues(alpha: 0.04)
                          : Colors.black12,
                      child: const Icon(
                        LucideIcons.image,
                        color: Colors.white30,
                      ),
                    ),
                  ),
                ),
              );
            },
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
            final name =
                (plan is Map ? plan['name']?.toString() : plan.toString()) ??
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
                      : Colors.black.withValues(alpha: 0.06),
                ),
              ),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      Expanded(
                        child: Text(
                          name.toUpperCase(),
                          style: GoogleFonts.dmSerifDisplay(
                            fontSize: 11,
                            fontWeight: FontWeight.w900,
                            color: isDark ? Colors.white : Colors.black,
                            letterSpacing: 0.5,
                          ),
                        ),
                      ),
                      const Icon(
                        LucideIcons.wallet,
                        color: M4Theme.premiumBlue,
                        size: 16,
                      ),
                    ],
                  ),
                  const SizedBox(height: 20),
                  ...items.map(
                    (item) => Padding(
                      padding: const EdgeInsets.only(bottom: 12),
                      child: Row(
                        children: [
                          Container(
                            width: 40,
                            height: 40,
                            decoration: BoxDecoration(
                              color: M4Theme.premiumBlue.withValues(alpha: 0.1),
                              shape: BoxShape.circle,
                            ),
                            child: Center(
                              child: Text(
                                '${item['percentage'] ?? 0}%',
                                style: GoogleFonts.dmSerifDisplay(
                                  fontSize: 10,
                                  fontWeight: FontWeight.w900,
                                  color: M4Theme.premiumBlue,
                                ),
                              ),
                            ),
                          ),
                          const SizedBox(width: 16),
                          Expanded(
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Text(
                                  item['description']
                                          ?.toString()
                                          .toUpperCase() ??
                                      'INSTALLMENT',
                                  style: GoogleFonts.dmSerifDisplay(
                                    fontSize: 9,
                                    fontWeight: FontWeight.w900,
                                    color: isDark ? Colors.white : Colors.black,
                                    letterSpacing: 0.5,
                                  ),
                                ),
                                Text(
                                  'INSTALLMENT ${item['installmentNumber'] ?? ''}',
                                  style: GoogleFonts.dmSerifDisplay(
                                    fontSize: 8,
                                    fontWeight: FontWeight.bold,
                                    color: isDark
                                        ? Colors.white38
                                        : Colors.black38,
                                  ),
                                ),
                              ],
                            ),
                          ),
                        ],
                      ),
                    ),
                  ),
                  const SizedBox(height: 4),
                  GestureDetector(
                    onTap: () => _openInquiry('General', planName: name),
                    child: Container(
                      width: double.infinity,
                      padding: const EdgeInsets.symmetric(vertical: 14),
                      decoration: BoxDecoration(
                        color: M4Theme.premiumBlue.withValues(alpha: 0.1),
                        borderRadius: BorderRadius.circular(14),
                      ),
                      child: Center(
                        child: Text(
                          'INQUIRE ABOUT THIS PLAN',
                          style: GoogleFonts.dmSerifDisplay(
                            fontSize: 9,
                            fontWeight: FontWeight.w900,
                            color: M4Theme.premiumBlue,
                            letterSpacing: 1,
                          ),
                        ),
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
              color: isDark
                  ? Colors.white.withValues(alpha: 0.03)
                  : Colors.white,
              borderRadius: BorderRadius.circular(28),
              border: Border.all(
                color: isDark
                    ? Colors.white.withValues(alpha: 0.08)
                    : Colors.black.withValues(alpha: 0.06),
              ),
              boxShadow: isDark
                  ? []
                  : [
                      BoxShadow(
                        color: Colors.black.withValues(alpha: 0.05),
                        blurRadius: 20,
                        offset: const Offset(0, 10),
                      ),
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
                          Text(
                            'READY TO INVEST?',
                            style: GoogleFonts.dmSerifDisplay(
                              fontSize: 12,
                              fontWeight: FontWeight.w900,
                              color: isDark ? Colors.white : Colors.black,
                            ),
                          ),
                          const SizedBox(height: 4),
                          Text(
                            'CONNECT WITH OUR WEALTH ADVISORS',
                            style: GoogleFonts.dmSerifDisplay(
                              fontSize: 8,
                              fontWeight: FontWeight.w900,
                              color: isDark ? Colors.white38 : Colors.black38,
                              letterSpacing: 1,
                            ),
                          ),
                        ],
                      ),
                    ),
                    _RoundIcon(
                      icon: LucideIcons.phone,
                      isDark: isDark,
                      onTap: () => _openInquiry('General'),
                    ),
                    const SizedBox(width: 10),
                    _RoundIcon(
                      icon: LucideIcons.messageCircle,
                      isDark: isDark,
                      onTap: () => _openInquiry('General'),
                    ),
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
                      borderRadius: BorderRadius.circular(20),
                    ),
                    child: Center(
                      child: Text(
                        'INVEST IN THIS PROJECT NOW',
                        style: GoogleFonts.dmSerifDisplay(
                          fontSize: 11,
                          fontWeight: FontWeight.w900,
                          color: isDark ? Colors.black : Colors.white,
                          letterSpacing: 2,
                        ),
                      ),
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
              'https://www.google.com/maps?q=${Uri.encodeComponent(locName)}',
            ),
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
                      : Colors.black.withValues(alpha: 0.06),
                ),
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
                        color: isDark ? Colors.black26 : Colors.black12,
                      ),
                      errorWidget: (c, u, e) =>
                          Container(color: Colors.black12),
                    ),
                    Positioned(
                      bottom: 20,
                      right: 20,
                      child: Container(
                        padding: const EdgeInsets.symmetric(
                          horizontal: 16,
                          vertical: 10,
                        ),
                        decoration: BoxDecoration(
                          color: isDark
                              ? const Color(0xFF1E293B)
                              : Colors.white.withValues(alpha: 0.9),
                          borderRadius: BorderRadius.circular(30),
                        ),
                        child: Row(
                          mainAxisSize: MainAxisSize.min,
                          children: [
                            const Icon(
                              LucideIcons.mapPin,
                              color: M4Theme.premiumBlue,
                              size: 12,
                            ),
                            const SizedBox(width: 8),
                            Text(
                              'VIEW ON MAPS',
                              style: GoogleFonts.dmSerifDisplay(
                                fontSize: 8,
                                fontWeight: FontWeight.w900,
                                color: isDark ? Colors.white : Colors.black,
                                letterSpacing: 1,
                              ),
                            ),
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
          width: 40,
          height: 1.5,
          color: isDark ? Colors.white : Colors.black,
        ),
        const SizedBox(width: 16),
        Text(
          title.toUpperCase(),
          style: GoogleFonts.dmSerifDisplay(
            fontSize: 12,
            fontWeight: FontWeight.w900,
            color: isDark ? Colors.white : Colors.black,
            letterSpacing: 4,
          ),
        ),
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
            color: (isDark ? Colors.white : Colors.black).withValues(
              alpha: 0.06,
            ),
          ),
          boxShadow: isDark
              ? []
              : [
                  BoxShadow(
                    color: Colors.black.withValues(alpha: 0.05),
                    blurRadius: 10,
                    offset: const Offset(0, 4),
                  ),
                ],
        ),
        child: Icon(
          icon,
          color: isDark ? Colors.white : Colors.black,
          size: 20,
        ),
      ),
    );
  }
}

class _MediaThumb extends StatelessWidget {
  final String label;
  final String? imageUrl;
  final VoidCallback onTap;
  const _MediaThumb({required this.label, this.imageUrl, required this.onTap});

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
                color: Colors.white.withValues(alpha: 0.2),
                width: 1.5,
              ),
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
                  child: Text(
                    label,
                    textAlign: TextAlign.center,
                    style: GoogleFonts.dmSerifDisplay(
                      color: Colors.white,
                      fontSize: 8,
                      fontWeight: FontWeight.w900,
                      letterSpacing: 0.5,
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
}

class _IconThumb extends StatelessWidget {
  final String label;
  final IconData icon;
  final bool isDark;
  final VoidCallback onTap;
  const _IconThumb({
    required this.label,
    required this.icon,
    required this.isDark,
    required this.onTap,
  });

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
                : Colors.black.withValues(alpha: 0.06),
          ),
        ),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(icon, size: 20, color: isDark ? Colors.white : Colors.black),
            const SizedBox(height: 4),
            Text(
              label,
              style: GoogleFonts.dmSerifDisplay(
                fontSize: 6.5,
                fontWeight: FontWeight.w900,
                color: isDark ? Colors.white : Colors.black,
                letterSpacing: 0.5,
              ),
            ),
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
  const _ActionCard({
    required this.label,
    required this.value,
    required this.icon,
    this.isAction = false,
    this.onTap,
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
          color: isDark ? Colors.white.withValues(alpha: 0.03) : Colors.white,
          borderRadius: BorderRadius.circular(32),
          border: Border.all(
            color: isDark
                ? Colors.white.withValues(alpha: 0.08)
                : Colors.black.withValues(alpha: 0.06),
          ),
          boxShadow: isDark
              ? []
              : [
                  BoxShadow(
                    color: Colors.black.withValues(alpha: 0.05),
                    blurRadius: 20,
                    offset: const Offset(0, 10),
                  ),
                ],
        ),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            Icon(
              icon,
              color: isDark ? Colors.white38 : Colors.black38,
              size: 24,
            ),
            Column(
              children: [
                Text(
                  label.toUpperCase(),
                  textAlign: TextAlign.center,
                  style: GoogleFonts.dmSerifDisplay(
                    color: isDark ? Colors.white38 : Colors.black38,
                    fontSize: 8,
                    fontWeight: FontWeight.w900,
                    letterSpacing: 1.5,
                  ),
                ),
                const SizedBox(height: 4),
                Text(
                  value,
                  textAlign: TextAlign.center,
                  style: GoogleFonts.dmSerifDisplay(
                    color: isDark ? Colors.white : Colors.black,
                    fontSize: 13,
                    fontWeight: FontWeight.w900,
                    letterSpacing: -0.2,
                  ),
                ),
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
  const _AssetCard({
    required this.title,
    required this.subtitle,
    required this.icon,
    required this.isDark,
    required this.onView,
    required this.onDownload,
  });

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
              : Colors.black.withValues(alpha: 0.06),
        ),
        boxShadow: isDark
            ? []
            : [
                BoxShadow(
                  color: Colors.black.withValues(alpha: 0.04),
                  blurRadius: 20,
                  offset: const Offset(0, 8),
                ),
              ],
      ),
      child: Row(
        children: [
          Container(
            padding: const EdgeInsets.all(12),
            decoration: BoxDecoration(
              color: M4Theme.premiumBlue.withValues(alpha: 0.1),
              borderRadius: BorderRadius.circular(14),
            ),
            child: Icon(icon, color: M4Theme.premiumBlue, size: 18),
          ),
          const SizedBox(width: 14),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  title,
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                  style: GoogleFonts.dmSerifDisplay(
                    fontSize: 10,
                    fontWeight: FontWeight.w900,
                    color: isDark ? Colors.white : Colors.black,
                    letterSpacing: 0.5,
                  ),
                ),
                const SizedBox(height: 4),
                Text(
                  subtitle,
                  style: GoogleFonts.dmSerifDisplay(
                    fontSize: 8,
                    fontWeight: FontWeight.w900,
                    color: isDark ? Colors.white38 : Colors.black38,
                    letterSpacing: 1,
                  ),
                ),
              ],
            ),
          ),
          const SizedBox(width: 8),
          // Web parity: VIEW is an outline button, DOWNLOAD (was "GET") is filled.
          _AssetButton(label: 'VIEW', onTap: onView, filled: false),
          const SizedBox(width: 8),
          _AssetButton(label: 'DOWNLOAD', onTap: onDownload),
        ],
      ),
    );
  }
}

class _AssetButton extends StatelessWidget {
  final String label;
  final VoidCallback onTap;
  final bool filled;
  const _AssetButton({
    required this.label,
    required this.onTap,
    this.filled = true,
  });

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final fg = filled
        ? (isDark ? Colors.black : Colors.white)
        : (isDark ? Colors.white : Colors.black);
    return GestureDetector(
      onTap: onTap,
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
        decoration: BoxDecoration(
          color: filled
              ? (isDark ? Colors.white : Colors.black)
              : Colors.transparent,
          borderRadius: BorderRadius.circular(10),
          border: filled
              ? null
              : Border.all(
                  color: (isDark ? Colors.white : Colors.black).withValues(
                    alpha: 0.25,
                  ),
                ),
        ),
        child: Text(
          label,
          style: GoogleFonts.dmSerifDisplay(
            fontSize: 7.5,
            fontWeight: FontWeight.w900,
            color: fg,
            letterSpacing: 1.0,
          ),
        ),
      ),
    );
  }
}

// Web parity: a media asset card with a single "WATCH STORY" action (unlike
// _AssetCard's VIEW + DOWNLOAD pair). Used for the WALKTHROUGH row.
class _WalkthroughCard extends StatelessWidget {
  final bool isDark;
  final VoidCallback onWatch;
  const _WalkthroughCard({required this.isDark, required this.onWatch});

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
              : Colors.black.withValues(alpha: 0.06),
        ),
        boxShadow: isDark
            ? []
            : [
                BoxShadow(
                  color: Colors.black.withValues(alpha: 0.04),
                  blurRadius: 20,
                  offset: const Offset(0, 8),
                ),
              ],
      ),
      child: Row(
        children: [
          Container(
            padding: const EdgeInsets.all(12),
            decoration: BoxDecoration(
              color: M4Theme.premiumBlue.withValues(alpha: 0.1),
              borderRadius: BorderRadius.circular(14),
            ),
            child: Icon(
              LucideIcons.video,
              color: M4Theme.premiumBlue,
              size: 18,
            ),
          ),
          const SizedBox(width: 14),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  'WALKTHROUGH',
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                  style: GoogleFonts.dmSerifDisplay(
                    fontSize: 10,
                    fontWeight: FontWeight.w900,
                    color: isDark ? Colors.white : Colors.black,
                    letterSpacing: 0.5,
                  ),
                ),
                const SizedBox(height: 4),
                Text(
                  'CINEMATIC TOUR • 4K',
                  style: GoogleFonts.dmSerifDisplay(
                    fontSize: 8,
                    fontWeight: FontWeight.w900,
                    color: isDark ? Colors.white38 : Colors.black38,
                    letterSpacing: 1,
                  ),
                ),
              ],
            ),
          ),
          const SizedBox(width: 8),
          GestureDetector(
            onTap: onWatch,
            child: Container(
              padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
              decoration: BoxDecoration(
                color: isDark ? Colors.white : Colors.black,
                borderRadius: BorderRadius.circular(10),
              ),
              child: Text(
                'WATCH STORY',
                style: GoogleFonts.dmSerifDisplay(
                  fontSize: 7.5,
                  fontWeight: FontWeight.w900,
                  color: isDark ? Colors.black : Colors.white,
                  letterSpacing: 1.0,
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }
}

class _RoundIcon extends StatelessWidget {
  final IconData icon;
  final bool isDark;
  final VoidCallback onTap;
  const _RoundIcon({
    required this.icon,
    required this.isDark,
    required this.onTap,
  });

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
                : Colors.black.withValues(alpha: 0.06),
          ),
        ),
        child: Icon(
          icon,
          size: 18,
          color: isDark ? Colors.white : Colors.black,
        ),
      ),
    );
  }
}

class _InquiryField extends StatelessWidget {
  final String hint;
  final TextEditingController controller;
  final IconData icon;
  const _InquiryField({
    required this.hint,
    required this.controller,
    required this.icon,
  });

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
              : Colors.black.withValues(alpha: 0.08),
        ),
      ),
      child: TextField(
        controller: controller,
        style: GoogleFonts.dmSerifDisplay(
          fontSize: 12,
          fontWeight: FontWeight.bold,
          color: isDark ? Colors.white : Colors.black,
        ),
        decoration: InputDecoration(
          border: InputBorder.none,
          hintText: hint,
          hintStyle: GoogleFonts.dmSerifDisplay(
            fontSize: 9,
            fontWeight: FontWeight.w900,
            color: isDark ? Colors.white24 : Colors.black26,
            letterSpacing: 1,
          ),
          icon: Icon(icon, size: 14, color: M4Theme.premiumBlue),
        ),
      ),
    );
  }
}

// Web parity (shared with the CP properties detail): a ring of short radial
// dashes, filled up to [progress]. Matches the "100% OVERALL" ring on web.
class _DottedProgressRingPainter extends CustomPainter {
  const _DottedProgressRingPainter({
    required this.progress,
    required this.color,
    required this.trackColor,
    this.dotCount = 40,
    this.dotRadius = 2.8,
    this.margin = 5,
    this.dashLength = 0,
  });

  final double progress;
  final Color color;
  final Color trackColor;
  final int dotCount;
  final double dotRadius;
  final double margin;

  /// When > 0 each mark is drawn as a short radial dash (tick) of this length
  /// instead of a round dot — matches the web ring's elongated ticks.
  final double dashLength;

  @override
  void paint(Canvas canvas, Size size) {
    final center = Offset(size.width / 2, size.height / 2);
    final radius = (math.min(size.width, size.height) / 2) - margin;
    final filled = (progress.clamp(0.0, 1.0) * dotCount).round();
    for (int i = 0; i < dotCount; i++) {
      final angle = -math.pi / 2 + (2 * math.pi / dotCount) * i;
      final paint = Paint()..color = i < filled ? color : trackColor;
      if (dashLength > 0) {
        paint
          ..strokeWidth = dotRadius * 2
          ..strokeCap = StrokeCap.round;
        final inner = radius - dashLength / 2;
        final outer = radius + dashLength / 2;
        canvas.drawLine(
          Offset(
            center.dx + math.cos(angle) * inner,
            center.dy + math.sin(angle) * inner,
          ),
          Offset(
            center.dx + math.cos(angle) * outer,
            center.dy + math.sin(angle) * outer,
          ),
          paint,
        );
      } else {
        canvas.drawCircle(
          Offset(
            center.dx + math.cos(angle) * radius,
            center.dy + math.sin(angle) * radius,
          ),
          dotRadius,
          paint,
        );
      }
    }
  }

  @override
  bool shouldRepaint(covariant _DottedProgressRingPainter old) =>
      old.progress != progress ||
      old.color != color ||
      old.trackColor != trackColor ||
      old.dotCount != dotCount ||
      old.dotRadius != dotRadius ||
      old.margin != margin ||
      old.dashLength != dashLength;
}
