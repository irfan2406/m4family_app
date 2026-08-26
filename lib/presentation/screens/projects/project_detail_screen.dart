import 'dart:convert';
import 'package:m4_mobile/presentation/widgets/m4_map_view.dart';
import 'package:dio/dio.dart';
import 'package:cached_network_image/cached_network_image.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:m4_mobile/core/utils/validators.dart';
import 'package:m4_mobile/core/theme/app_theme.dart';
import 'package:m4_mobile/core/network/api_client.dart';
import 'package:lucide_icons/lucide_icons.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:flutter_animate/flutter_animate.dart';
import 'package:flutter_svg/flutter_svg.dart';
import 'package:m4_mobile/presentation/widgets/wheel_date_time_picker.dart';
import 'package:m4_mobile/presentation/screens/support/raise_ticket_screen.dart';
import 'dart:ui';
import 'dart:math' as math;
import 'package:m4_mobile/core/utils/support_handlers.dart';
import 'package:m4_mobile/presentation/providers/auth_provider.dart';
import 'package:url_launcher/url_launcher.dart';
import 'package:share_plus/share_plus.dart';
import 'package:m4_mobile/presentation/screens/booking/booking_start_screen.dart';
import 'package:m4_mobile/presentation/widgets/luxury_amenity_icon.dart';

class ProjectDetailScreen extends ConsumerStatefulWidget {
  final dynamic projectData;
  final String projectId;

  const ProjectDetailScreen({
    super.key,
    required this.projectId,
    this.projectData,
  });

  @override
  ConsumerState<ProjectDetailScreen> createState() =>
      _ProjectDetailScreenState();
}

class _ProjectDetailScreenState extends ConsumerState<ProjectDetailScreen>
    with SingleTickerProviderStateMixin {
  late TabController _tabController;
  dynamic _fullProject;
  List<dynamic> _updates = [];
  List<dynamic> _inventory = [];
  List<dynamic> _progressPhases = [];
  bool _isLoading = true;
  final TextEditingController _nameController = TextEditingController();
  final TextEditingController _phoneController = TextEditingController();
  final TextEditingController _emailController = TextEditingController();
  final TextEditingController _notesController = TextEditingController();
  bool _isFavorited = false;
  String _mediaFilter = 'ALL';
  String _selectedConfig = '3 BHK';
  // Web parity: VC / Site Visit inquiries use a visit-type toggle + schedule.
  String _inquiryVisitType = 'VC';
  DateTime? _inquiryDateTime;
  bool _showFullOverviewDesc = false;
  bool _showFullProgressDesc = false;

  @override
  void initState() {
    super.initState();
    _fetchProjectData();
  }

  // Flip the wishlist heart + show an instant Saved/Removed toast (parity with
  // the CP detail screen). Clears any prior toast so rapid taps don't stack.
  void _toggleFavorite() {
    final next = !_isFavorited;
    setState(() => _isFavorited = next);
    ScaffoldMessenger.of(context)
      ..clearSnackBars()
      ..showSnackBar(
        SnackBar(
          backgroundColor: const Color(0xFF163A2C),
          duration: const Duration(milliseconds: 1100),
          behavior: SnackBarBehavior.fixed,
          content: Text(next ? 'Saved to favorites' : 'Removed from favorites'),
        ),
      );
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
            content: Text(
              message,
              style: GoogleFonts.inter(
                fontSize: 12,
                fontWeight: FontWeight.bold,
              ),
            ),
            backgroundColor: M4Theme.premiumBlue,
            duration: const Duration(seconds: 2),
            behavior: SnackBarBehavior.floating,
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(10),
            ),
          ),
        );

        await launchUrl(uri, mode: LaunchMode.externalApplication);
        return;
      } catch (e) {
        debugPrint('Error launching URL: $e');
      }
      return;
    }

    // No URL: the call is purely user feedback (validation errors, submit
    // results). This method used to surface the message ONLY as a side-effect
    // of opening a url — so every `_launchAction(msg, null)` silently did
    // nothing and submitting the form looked completely unresponsive.
    _showMessage(message);
  }

  /// Toast feedback — green on success, red on failure.
  ///
  /// Rendered in the ROOT overlay so it floats ABOVE the booking sheet, and
  /// sits just above the submit button — right where the user is looking. A
  /// normal SnackBar renders inside the Scaffold *under* the modal route, which
  /// pushed it to the very bottom of the screen, below the form.
  void _showMessage(String message, {bool success = false}) {
    if (!mounted) return;
    final overlay = Overlay.of(context, rootOverlay: true);
    late final OverlayEntry entry;
    entry = OverlayEntry(
      builder: (ctx) => Positioned(
        // Above the submit button; lifts with the keyboard when it's open.
        bottom: MediaQuery.of(ctx).viewInsets.bottom + 120,
        left: 16,
        right: 16,
        child: IgnorePointer(
          child: Material(
            color: Colors.transparent,
            child: Container(
              padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
              decoration: BoxDecoration(
                color: success
                    ? const Color(0xFF163A2C)
                    : const Color(0xFFC65B46),
                borderRadius: BorderRadius.circular(14),
                boxShadow: [
                  BoxShadow(
                    color: Colors.black.withValues(alpha: 0.25),
                    blurRadius: 20,
                    offset: const Offset(0, 8),
                  ),
                ],
              ),
              child: Row(
                children: [
                  Icon(
                    success ? LucideIcons.checkCircle : LucideIcons.alertCircle,
                    color: Colors.white,
                    size: 18,
                  ),
                  const SizedBox(width: 10),
                  Expanded(
                    child: Text(
                      message,
                      style: GoogleFonts.inter(
                        fontSize: 12.5,
                        fontWeight: FontWeight.w600,
                        color: Colors.white,
                        height: 1.35,
                      ),
                    ),
                  ),
                ],
              ),
            ),
          ),
        ),
      ),
    );
    overlay.insert(entry);
    Future.delayed(const Duration(seconds: 3), () {
      if (entry.mounted) entry.remove();
    });
  }

  @override
  void dispose() {
    _nameController.dispose();
    _phoneController.dispose();
    _emailController.dispose();
    _notesController.dispose();
    super.dispose();
  }

  Future<void> _submitInquiry(String type, [String? plan]) async {
    final isVisit = type == 'VC' || type == 'Site Visit';
    // Web parity: VC/Site Visit uses the toggled visit type + auth user + a
    // required date/time + optional notes (no name/phone fields).
    final effectiveType = isVisit ? _inquiryVisitType : type;
    final authUser = ref.read(authProvider).user;

    final name = isVisit
        ? (authUser?['fullName']?.toString() ??
              authUser?['username']?.toString() ??
              'App User')
        : _nameController.text.trim();
    // `phone` is REQUIRED by the API. For visits it comes from the profile, but
    // that can be blank — in which case the sheet shows a phone field and we
    // fall back to it. Submitting blank used to reach the server and come back
    // as a 400, which surfaced as a misleading "Connection error".
    final authPhone = (authUser?['phone']?.toString() ?? '').trim();
    final phone = isVisit
        ? (authPhone.isNotEmpty ? authPhone : _phoneController.text.trim())
        : _phoneController.text.trim();

    if (isVisit) {
      if (_inquiryDateTime == null) {
        _showMessage('Please select a date & time for your visit');
        return;
      }
      final pErr = Validators.phoneError(phone);
      if (pErr != null) {
        _showMessage(pErr);
        return;
      }
    } else {
      // Format checks (was empty-only): valid name + phone; email when given.
      final vErr =
          Validators.nameError(name, field: 'name') ??
          Validators.phoneError(phone) ??
          (_emailController.text.trim().isEmpty
              ? null
              : Validators.emailError(_emailController.text));
      if (vErr != null) {
        _showMessage(vErr);
        return;
      }
    }

    setState(() => _isLoading = true);
    try {
      final apiClient = ref.read(apiClientProvider);
      final project = _fullProject ?? widget.projectData;
      final notes = _notesController.text.trim();
      final dt = _inquiryDateTime;
      String two(int v) => v.toString().padLeft(2, '0');

      final res = await apiClient.submitLead({
        'name': name,
        'phone': phone,
        'email': _emailController.text.trim().isNotEmpty
            ? _emailController.text.trim()
            : authUser?['email']?.toString(),
        'interest': effectiveType == 'VC'
            ? 'Video Call'
            : effectiveType == 'Site Visit'
            ? 'Site Visit'
            : 'Buying',
        'configuration': _selectedConfig,
        // Server-side enum: source = online | cp | walk-in | referral | other.
        'source': 'online',
        // Only ever send a real ObjectId — widget.projectId can be a route slug,
        // which makes the API reject the whole lead (CastToObjectId/BSONError).
        if (widget.projectId.length == 24) 'projectId': widget.projectId,
        'project': project?['title'] ?? 'General',
        if (isVisit && dt != null)
          'visitDate': '${dt.year}-${two(dt.month)}-${two(dt.day)}',
        if (isVisit && dt != null) 'visitTime': _formatInquiryDateTime(dt),
        'message': notes.isNotEmpty
            ? notes
            : plan != null
            ? 'Inquiry about payment plan: $plan for project ${project?['title']}'
            : '${effectiveType == 'VC'
                  ? 'Video Call'
                  : effectiveType == 'Site Visit'
                  ? 'Site Visit'
                  : 'General'} request for project ${project?['title']}',
      });

      if (res.data['status'] == true) {
        if (mounted) {
          // Close the sheet FIRST so the confirmation isn't hidden behind it.
          Navigator.pop(context);
          _showMessage(
            type == 'General'
                ? 'Inquiry submitted! Our advisor will contact you shortly.'
                : 'Booking request received! Our team will call you to confirm the time.',
            success: true,
          );
        }
      } else {
        _showMessage(res.data['message'] ?? 'Failed to submit inquiry');
      }
    } catch (e) {
      _showMessage('Connection error. Please try again.');
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
          color: isDark ? const Color(0xFF141B3A) : const Color(0xFFF4EFE3),
          borderRadius: const BorderRadius.vertical(top: Radius.circular(40)),
          border: Border.all(
            color: isDark
                ? Colors.white.withOpacity(0.1)
                : Colors.black.withOpacity(0.1),
            width: 0.5,
          ),
        ),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Align(
              alignment: Alignment.center,
              child: Container(
                width: 40,
                height: 4,
                decoration: BoxDecoration(
                  color: isDark ? Colors.white24 : Colors.black12,
                  borderRadius: BorderRadius.circular(2),
                ),
              ),
            ),
            const SizedBox(height: 32),
            Text(
              'HOW CAN\nWE HELP?',
              style: GoogleFonts.gelasio(
                fontSize: 28,
                fontWeight: FontWeight.w700,
                color: isDark ? Colors.white : Color(0xFF0C312B),
                height: 0.9,
                letterSpacing: -1.5,
              ),
            ),
            const SizedBox(height: 12),
            Text(
              'INTERESTED IN ${project?['title']?.toString().toUpperCase() ?? 'PROJECT'}?\nCHOOSE HOW YOU\'D LIKE TO PROCEED.',
              style: GoogleFonts.gelasio(
                fontSize: 9,
                color: isDark ? Colors.white38 : Color(0xFF155A4F),
                fontWeight: FontWeight.w700,
                letterSpacing: 2,
              ),
            ),
            const SizedBox(height: 40),
            _buildBookingOption(
              icon: LucideIcons.messageSquare,
              title: 'SEND INQUIRY',
              desc: 'Get detailed brochure and pricing via email/WhatsApp.',
              color: const Color(0xFF163A2C),
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
              color: const Color(0xFF163A2C),
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
              color: const Color(0xFF163A2C),
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
                    decoration: BoxDecoration(
                      color: M4Theme.premiumBlue,
                      borderRadius: BorderRadius.circular(8),
                    ),
                    child: const Icon(
                      LucideIcons.info,
                      color: Colors.white,
                      size: 14,
                    ),
                  ),
                  const SizedBox(width: 16),
                  Expanded(
                    child: Text(
                      'M4 FAMILY MEMBERS GET PRIORITY SITE VISITS AND EXCLUSIVE UNIT SELECTION WINDOWS.',
                      style: GoogleFonts.inter(
                        fontSize: 8,
                        color: isDark
                            ? Colors.white70
                            : Color(0xFF0C312B).withOpacity(0.8),
                        fontWeight: FontWeight.w600,
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
          color: isDark ? const Color(0xFF141B3A) : const Color(0xFFF4EFE3),
          borderRadius: BorderRadius.circular(24),
          border: Border.all(
            color: isDark
                ? Colors.white.withOpacity(0.05)
                : Colors.black.withOpacity(0.05),
          ),
          boxShadow: isDark
              ? []
              : [
                  BoxShadow(
                    color: Colors.black.withOpacity(0.05),
                    blurRadius: 15,
                    offset: const Offset(0, 5),
                  ),
                ],
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
                    style: GoogleFonts.inter(
                      fontSize: 12,
                      fontWeight: FontWeight.w600,
                      color: isDark ? Colors.white : Color(0xFF155A4F),
                      letterSpacing: 0.5,
                    ),
                  ),
                  const SizedBox(height: 2),
                  Text(
                    desc,
                    style: GoogleFonts.inter(
                      fontSize: 9,
                      color: isDark ? Colors.white38 : Color(0xFF155A4F),
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                ],
              ),
            ),
            Icon(
              LucideIcons.chevronRight,
              color: isDark ? Colors.white12 : Color(0x1F0C312B),
              size: 18,
            ),
          ],
        ),
      ),
    );
  }

  void _showRequestDetailsDialog(
    dynamic project, [
    dynamic plan,
    String type = 'General',
  ]) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final planName = plan is Map ? plan['name']?.toString() : plan?.toString();
    final projectTitle = project?['title'] ?? 'this project';

    // Prefill auth user data ONLY for General inquiries, not for Video Call or Site Visit
    final authUser = ref.read(authProvider).user;
    if (authUser != null && type == 'General') {
      _nameController.text =
          authUser['fullName']?.toString() ??
          authUser['username']?.toString() ??
          '';
      _phoneController.text = authUser['phone']?.toString() ?? '';
      _emailController.text = authUser['email']?.toString() ?? '';
    } else {
      _nameController.clear();
      _phoneController.clear();
      _emailController.clear();
    }
    // Web parity: seed the visit-type toggle + reset schedule/notes.
    _inquiryVisitType = type == 'Site Visit' ? 'Site Visit' : 'VC';
    _inquiryDateTime = null;
    _notesController.clear();

    // Web parity: shown as a CENTERED dialog (same style as the date picker),
    // not a bottom sheet.
    showDialog(
      context: context,
      barrierColor: Colors.black.withOpacity(0.55),
      builder: (context) => StatefulBuilder(
        builder: (context, setModalState) => Dialog(
          backgroundColor: isDark
              ? const Color(0xFF141B3A)
              : const Color(0xFFF4EFE3),
          insetPadding: const EdgeInsets.symmetric(
            horizontal: 20,
            vertical: 40,
          ),
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(28),
          ),
          child: ConstrainedBox(
            constraints: BoxConstraints(
              maxHeight: MediaQuery.of(context).size.height * 0.85,
            ),
            child: SingleChildScrollView(
              padding: const EdgeInsets.fromLTRB(28, 18, 28, 28),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Align(
                    alignment: Alignment.topRight,
                    child: IconButton(
                      onPressed: () => Navigator.pop(context),
                      icon: Icon(
                        LucideIcons.x,
                        color: isDark ? Colors.white38 : Color(0xFF155A4F),
                        size: 20,
                      ),
                      padding: EdgeInsets.zero,
                      constraints: const BoxConstraints(),
                    ),
                  ),
                  Text(
                    type == 'VC'
                        ? 'BOOK A VIDEO CALL'
                        : type == 'Site Visit'
                        ? 'BOOK A SITE VISIT'
                        : 'REQUEST DETAILS',
                    style: GoogleFonts.gelasio(
                      fontSize: 18,
                      fontWeight: FontWeight.w700,
                      color: isDark ? Colors.white : Color(0xFF0C312B),
                      letterSpacing: -0.5,
                    ),
                  ),
                  const SizedBox(height: 4),
                  Text(
                    planName != null
                        ? 'INQUIRY FOR "$planName" PAYMENT PLAN'
                        // Web parity wording on the REQUEST DETAILS sheet.
                        : type == 'General'
                        ? 'A BESPOKE SHOWCASE OF LUXURY AT ${projectTitle.toUpperCase()}.'
                        : 'INQUIRY FOR ${projectTitle.toUpperCase()}',
                    style: GoogleFonts.inter(
                      fontSize: 10,
                      color: (isDark ? Colors.white : Color(0xFF0C312B))
                          .withOpacity(0.6),
                      fontWeight: FontWeight.w600,
                      letterSpacing: 1,
                    ),
                  ),
                  const SizedBox(height: 28),

                  // Web parity: the REQUEST DETAILS sheet collects only name,
                  // email, phone and notes — no configuration chips. The video
                  // call / site visit variants keep theirs.
                  if (type != 'General') ...[
                    Text(
                      'PREFERRED CONFIGURATION *',
                      style: GoogleFonts.inter(
                        fontSize: 10,
                        fontWeight: FontWeight.w600,
                        color: (isDark ? Colors.white : Color(0xFF0C312B))
                            .withOpacity(0.72),
                        letterSpacing: 1,
                      ),
                    ),
                    const SizedBox(height: 12),
                    // Web parity: 3-column grid (grid-cols-3), wider chips.
                    GridView.count(
                      shrinkWrap: true,
                      physics: const NeverScrollableScrollPhysics(),
                      padding: EdgeInsets.zero,
                      crossAxisCount: 3,
                      mainAxisSpacing: 8,
                      crossAxisSpacing: 8,
                      childAspectRatio: 2.8,
                      children:
                          [
                            "1 BHK",
                            "2 BHK",
                            "3 BHK",
                            "4 BHK",
                            "PENTHOUSE",
                          ].map((config) {
                            final isActive = _selectedConfig == config;
                            return GestureDetector(
                              onTap: () =>
                                  setModalState(() => _selectedConfig = config),
                              child: Container(
                                alignment: Alignment.center,
                                decoration: BoxDecoration(
                                  color: isActive
                                      ? (isDark
                                            ? Colors.white
                                            : Color(0xFF0C312B))
                                      : (isDark
                                            ? Colors.white.withOpacity(0.03)
                                            : Colors.black.withOpacity(0.04)),
                                  borderRadius: BorderRadius.circular(10),
                                  border: Border.all(
                                    color: isActive
                                        ? (isDark
                                              ? Colors.white
                                              : Color(0xFF0C312B))
                                        : (isDark
                                              ? Colors.white.withOpacity(0.1)
                                              : Colors.black.withOpacity(0.08)),
                                  ),
                                ),
                                child: Text(
                                  config,
                                  style: GoogleFonts.inter(
                                    fontSize: 9,
                                    fontWeight: FontWeight.w600,
                                    letterSpacing: 0.5,
                                    color: isActive
                                        ? (isDark
                                              ? const Color(0xFF0C312B)
                                              : Colors.white)
                                        : (isDark
                                              ? Colors.white54
                                              : Color(0xFF155A4F)),
                                  ),
                                ),
                              ),
                            );
                          }).toList(),
                    ),
                  ],

                  if (type == 'VC' || type == 'Site Visit') ...[
                    // VISIT TYPE toggle (web parity)
                    const SizedBox(height: 24),
                    _inquiryLabel('VISIT TYPE', isDark),
                    const SizedBox(height: 12),
                    Container(
                      padding: const EdgeInsets.all(4),
                      decoration: BoxDecoration(
                        color: (isDark ? Colors.white : Color(0xFF0C312B))
                            .withOpacity(0.04),
                        borderRadius: BorderRadius.circular(16),
                        border: Border.all(
                          color: (isDark ? Colors.white : Color(0xFF0C312B))
                              .withOpacity(0.08),
                        ),
                      ),
                      child: Row(
                        children: ['Site Visit', 'VC'].map((vt) {
                          final active = _inquiryVisitType == vt;
                          return Expanded(
                            child: GestureDetector(
                              onTap: () =>
                                  setModalState(() => _inquiryVisitType = vt),
                              child: Container(
                                padding: const EdgeInsets.symmetric(
                                  vertical: 14,
                                ),
                                decoration: BoxDecoration(
                                  color: active
                                      ? (isDark
                                            ? Colors.white
                                            : Color(0xFF0C312B))
                                      : Colors.transparent,
                                  borderRadius: BorderRadius.circular(12),
                                ),
                                child: Text(
                                  vt.toUpperCase(),
                                  textAlign: TextAlign.center,
                                  style: GoogleFonts.gelasio(
                                    fontSize: 9,
                                    fontWeight: FontWeight.w700,
                                    letterSpacing: 1.5,
                                    color: active
                                        ? (isDark
                                              ? const Color(0xFF0C312B)
                                              : Colors.white)
                                        : (isDark
                                              ? Colors.white54
                                              : Color(0x730C312B)),
                                  ),
                                ),
                              ),
                            ),
                          );
                        }).toList(),
                      ),
                    ),
                    // SCHEDULE
                    const SizedBox(height: 24),
                    _inquiryLabel('SCHEDULE', isDark),
                    const SizedBox(height: 12),
                    GestureDetector(
                      onTap: () async {
                        final picked = await _pickInquiryDateTime();
                        if (picked != null) {
                          setModalState(() => _inquiryDateTime = picked);
                        }
                      },
                      child: Container(
                        padding: const EdgeInsets.symmetric(
                          horizontal: 18,
                          vertical: 18,
                        ),
                        decoration: BoxDecoration(
                          color: (isDark ? Colors.white : Color(0xFF0C312B))
                              .withOpacity(0.03),
                          borderRadius: BorderRadius.circular(16),
                          border: Border.all(
                            color: (isDark ? Colors.white : Color(0xFF0C312B))
                                .withOpacity(0.08),
                          ),
                        ),
                        child: Row(
                          children: [
                            Icon(
                              LucideIcons.calendar,
                              size: 16,
                              color: isDark ? Colors.white : Color(0xFF0C312B),
                            ),
                            const SizedBox(width: 12),
                            Expanded(
                              child: Text(
                                _inquiryDateTime == null
                                    ? 'SELECT DATE & TIME'
                                    : _formatInquiryDateTime(_inquiryDateTime!),
                                style: GoogleFonts.inter(
                                  fontSize: 11,
                                  fontWeight: FontWeight.w600,
                                  color: isDark
                                      ? Colors.white
                                      : Color(0xFF155A4F),
                                  letterSpacing: 1,
                                ),
                              ),
                            ),
                            Icon(
                              LucideIcons.chevronRight,
                              size: 16,
                              color: (isDark ? Colors.white : Color(0xFF0C312B))
                                  .withOpacity(0.4),
                            ),
                          ],
                        ),
                      ),
                    ),
                    // The API requires a phone. Visits normally take it from
                    // the profile — ask for it here when that's blank, instead
                    // of submitting empty and failing with a 400.
                    if ((authUser?['phone']?.toString() ?? '')
                        .trim()
                        .isEmpty) ...[
                      const SizedBox(height: 24),
                      _buildInquiryField(
                        'PHONE NUMBER *',
                        _phoneController,
                        LucideIcons.phone,
                        keyboardType: TextInputType.phone,
                        inputFormatters: Validators.phoneFormatters,
                      ),
                    ],

                    // ADDITIONAL NOTES
                    const SizedBox(height: 24),
                    _inquiryLabel('ADDITIONAL NOTES', isDark),
                    const SizedBox(height: 12),
                    TextField(
                      controller: _notesController,
                      maxLines: 4,
                      textCapitalization: TextCapitalization.characters,
                      style: GoogleFonts.inter(
                        fontSize: 15,
                        fontWeight: FontWeight.w700,
                        color: isDark ? Colors.white : Color(0xFF155A4F),
                      ),
                      decoration: InputDecoration(
                        hintText:
                            'SPECIFIC REQUIREMENTS, PICKUP DETAILS, ETC...',
                        hintStyle: GoogleFonts.inter(
                          fontSize: 11,
                          fontWeight: FontWeight.w700,
                          color: (isDark ? Colors.white : Color(0xFF0C312B))
                              .withOpacity(0.72),
                        ),
                        filled: true,
                        fillColor: (isDark ? Colors.white : Color(0xFF0C312B))
                            .withOpacity(0.03),
                        contentPadding: const EdgeInsets.all(16),
                        border: OutlineInputBorder(
                          borderRadius: BorderRadius.circular(16),
                          borderSide: BorderSide(
                            color: (isDark ? Colors.white : Color(0xFF0C312B))
                                .withOpacity(0.08),
                          ),
                        ),
                        enabledBorder: OutlineInputBorder(
                          borderRadius: BorderRadius.circular(16),
                          borderSide: BorderSide(
                            color: (isDark ? Colors.white : Color(0xFF0C312B))
                                .withOpacity(0.08),
                          ),
                        ),
                      ),
                    ),
                  ] else ...[
                    // Web parity order: name, then email, then phone.
                    const SizedBox(height: 24),
                    _buildInquiryField(
                      'FULL NAME *',
                      _nameController,
                      LucideIcons.user,
                      keyboardType: TextInputType.name,
                      inputFormatters: Validators.nameFormatters,
                    ),
                    const SizedBox(height: 16),
                    _buildInquiryField(
                      'EMAIL ADDRESS (OPTIONAL)',
                      _emailController,
                      LucideIcons.mail,
                      keyboardType: TextInputType.emailAddress,
                      inputFormatters: Validators.emailFormatters,
                    ),
                    const SizedBox(height: 16),
                    _buildInquiryField(
                      'PHONE NUMBER *',
                      _phoneController,
                      LucideIcons.phone,
                      keyboardType: TextInputType.phone,
                      inputFormatters: Validators.phoneFormatters,
                    ),
                  ],

                  const SizedBox(height: 32),
                  _ScaleButton(
                    onTap: () => _submitInquiry(type, planName),
                    child: Container(
                      width: double.infinity,
                      padding: const EdgeInsets.symmetric(vertical: 20),
                      decoration: BoxDecoration(
                        color: isDark ? Colors.white : Color(0xFF0C312B),
                        borderRadius: BorderRadius.circular(20),
                        boxShadow: [
                          BoxShadow(
                            color: (isDark ? Colors.white : Color(0xFF0C312B))
                                .withOpacity(0.1),
                            blurRadius: 20,
                            offset: const Offset(0, 10),
                          ),
                        ],
                      ),
                      child: Row(
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: [
                          Text(
                            // Web parity: the REQUEST DETAILS sheet confirms a
                            // booking; the other variants stay an inquiry.
                            type == 'General'
                                ? 'CONFIRM BOOKING'
                                : 'SUBMIT INQUIRY',
                            style: GoogleFonts.inter(
                              fontSize: 10,
                              fontWeight: FontWeight.w600,
                              color: isDark
                                  ? const Color(0xFF0C312B)
                                  : const Color(0xFFF4EFE3),
                              letterSpacing: 1,
                            ),
                          ),
                          const SizedBox(width: 8),
                          Icon(
                            LucideIcons.arrowUpRight,
                            color: isDark
                                ? const Color(0xFF0C312B)
                                : const Color(0xFFF4EFE3),
                            size: 14,
                          ),
                        ],
                      ),
                    ),
                  ),
                  const SizedBox(height: 24),
                  Center(
                    child: Text(
                      'OUR ADVISOR WILL CONTACT YOU WITHIN 24 HOURS',
                      style: GoogleFonts.inter(
                        fontSize: 7,
                        color: isDark ? Colors.white24 : Color(0x420C312B),
                        fontWeight: FontWeight.w600,
                        letterSpacing: 1,
                      ),
                    ),
                  ),
                  const SizedBox(height: 32),
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }

  Widget _inquiryLabel(String text, bool isDark) {
    return Text(
      text,
      style: GoogleFonts.gelasio(
        fontSize: 10,
        fontWeight: FontWeight.w700,
        color: (isDark ? Colors.white : Color(0xFF0C312B)).withOpacity(0.72),
        letterSpacing: 1.5,
      ),
    );
  }

  Future<DateTime?> _pickInquiryDateTime() async {
    final now = DateTime.now();
    DateTime temp = _inquiryDateTime ?? now.add(const Duration(minutes: 30));
    if (temp.isBefore(now)) temp = now.add(const Duration(minutes: 30));
    final isDark = Theme.of(context).brightness == Brightness.dark;
    // Web parity: an absolute Day/Month/Year + time wheel picker, shown
    // centered on screen (not the Material calendar dialog).
    return showDialog<DateTime>(
      context: context,
      barrierColor: Colors.black.withOpacity(0.55),
      builder: (dCtx) => Dialog(
        backgroundColor: isDark
            ? const Color(0xFF141B3A)
            : const Color(0xFFF4EFE3),
        insetPadding: const EdgeInsets.symmetric(horizontal: 24, vertical: 24),
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(28)),
        child: Padding(
          padding: const EdgeInsets.fromLTRB(20, 22, 20, 20),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Align(
                alignment: Alignment.centerLeft,
                child: Text(
                  'SELECT DATE & TIME',
                  style: GoogleFonts.inter(
                    fontSize: 15,
                    fontWeight: FontWeight.w600,
                    letterSpacing: 0.5,
                    color: isDark ? Colors.white : Color(0xFF155A4F),
                  ),
                ),
              ),
              const SizedBox(height: 8),
              WheelDateTimePicker(
                initial: temp,
                minDate: now,
                isDark: isDark,
                onChanged: (dt) => temp = dt,
              ),
              const SizedBox(height: 16),
              Row(
                children: [
                  Expanded(
                    child: OutlinedButton(
                      onPressed: () => Navigator.pop(dCtx),
                      style: OutlinedButton.styleFrom(
                        minimumSize: const Size.fromHeight(52),
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(16),
                        ),
                        side: BorderSide(
                          color: (isDark ? Colors.white : Color(0xFF0C312B))
                              .withOpacity(0.2),
                        ),
                        foregroundColor: isDark
                            ? Colors.white
                            : Color(0xFF0C312B),
                      ),
                      child: Text(
                        'CANCEL',
                        style: GoogleFonts.inter(
                          fontWeight: FontWeight.w600,
                          letterSpacing: 1,
                          fontSize: 12,
                        ),
                      ),
                    ),
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    child: FilledButton(
                      onPressed: () => Navigator.pop(dCtx, temp),
                      style: FilledButton.styleFrom(
                        minimumSize: const Size.fromHeight(52),
                        backgroundColor: isDark
                            ? Colors.white
                            : Color(0xFF0C312B),
                        foregroundColor: isDark
                            ? Colors.black
                            : const Color(0xFFF4EFE3),
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(16),
                        ),
                      ),
                      child: Text(
                        'CONFIRM',
                        style: GoogleFonts.inter(
                          fontWeight: FontWeight.w600,
                          letterSpacing: 1,
                          fontSize: 12,
                        ),
                      ),
                    ),
                  ),
                ],
              ),
            ],
          ),
        ),
      ),
    );
  }

  String _formatInquiryDateTime(DateTime dt) {
    final h = dt.hour % 12 == 0 ? 12 : dt.hour % 12;
    final ampm = dt.hour < 12 ? 'AM' : 'PM';
    final m = dt.minute.toString().padLeft(2, '0');
    return '${dt.day}/${dt.month}/${dt.year}  •  $h:$m $ampm';
  }

  Widget _buildInquiryField(
    String label,
    TextEditingController controller,
    IconData icon, {
    TextInputType? keyboardType,
    List<TextInputFormatter>? inputFormatters,
  }) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          label,
          style: GoogleFonts.inter(
            fontSize: 10,
            fontWeight: FontWeight.w600,
            color: isDark ? Colors.white54 : Color(0xFF155A4F),
            letterSpacing: 1,
          ),
        ),
        const SizedBox(height: 10),
        Container(
          padding: const EdgeInsets.symmetric(horizontal: 20),
          decoration: BoxDecoration(
            color: isDark
                ? Colors.white.withOpacity(0.03)
                : Colors.black.withOpacity(0.04),
            borderRadius: BorderRadius.circular(16),
            border: Border.all(
              color: isDark
                  ? Colors.white.withOpacity(0.05)
                  : Colors.black.withOpacity(0.05),
            ),
          ),
          child: TextField(
            controller: controller,
            keyboardType: keyboardType,
            inputFormatters: inputFormatters,
            style: GoogleFonts.inter(
              fontSize: 15,
              fontWeight: FontWeight.bold,
              color: isDark ? Colors.white : Color(0xFF155A4F),
            ),
            decoration: InputDecoration(
              filled: false,
              border: InputBorder.none,
              enabledBorder: InputBorder.none,
              focusedBorder: InputBorder.none,
              icon: Icon(
                icon,
                color: isDark ? Colors.white24 : Color(0x420C312B),
                size: 16,
              ),
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
      list.addAll(
        media
            .where((m) => m['category']?.toString().toUpperCase() == 'EXTERIOR')
            .map((m) => m['url']?.toString() ?? '')
            .where((u) => u.isNotEmpty),
      );
    } else if (category == 'INTERIOR') {
      list.addAll((project?['interiorImages'] as List?)?.cast<String>() ?? []);
      list.addAll(
        media
            .where((m) => m['category']?.toString().toUpperCase() == 'INTERIOR')
            .map((m) => m['url']?.toString() ?? '')
            .where((u) => u.isNotEmpty),
      );
    }

    if (list.isNotEmpty) {
      _showMediaLightbox(list, 'IMAGE');
    } else {
      _launchAction('Gallery coming soon!', null);
    }
  }

  void _showMediaLightbox(
    dynamic urlOrList,
    String type, [
    int initialIndex = 0,
  ]) {
    final apiClient = ref.read(apiClientProvider);
    final List<String> urls = urlOrList is List
        ? urlOrList.map((u) => apiClient.resolveUrl(u.toString())).toList()
        : [apiClient.resolveUrl(urlOrList.toString())];

    final PageController pageController = PageController(
      initialPage: initialIndex,
    );

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
                        errorBuilder: (context, error, stackTrace) =>
                            const Icon(
                              LucideIcons.image,
                              color: Colors.white24,
                              size: 50,
                            ),
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
                      decoration: BoxDecoration(
                        color: Colors.black26,
                        shape: BoxShape.circle,
                      ),
                      child: const Icon(
                        LucideIcons.chevronLeft,
                        color: Colors.white,
                        size: 24,
                      ),
                    ),
                    onPressed: () => pageController.previousPage(
                      duration: const Duration(milliseconds: 300),
                      curve: Curves.easeInOut,
                    ),
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
                      decoration: BoxDecoration(
                        color: Colors.black26,
                        shape: BoxShape.circle,
                      ),
                      child: const Icon(
                        LucideIcons.chevronRight,
                        color: Colors.white,
                        size: 24,
                      ),
                    ),
                    onPressed: () => pageController.nextPage(
                      duration: const Duration(milliseconds: 300),
                      curve: Curves.easeInOut,
                    ),
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
                      padding: const EdgeInsets.symmetric(
                        horizontal: 16,
                        vertical: 8,
                      ),
                      decoration: BoxDecoration(
                        color: Colors.black54,
                        borderRadius: BorderRadius.circular(20),
                      ),
                      child: ListenableBuilder(
                        listenable: pageController,
                        builder: (context, child) {
                          final current =
                              (pageController.hasClients
                                  ? pageController.page?.round() ?? initialIndex
                                  : initialIndex) +
                              1;
                          return Text(
                            '$current / ${urls.length}',
                            style: GoogleFonts.inter(
                              color: Colors.white,
                              fontSize: 12,
                              fontWeight: FontWeight.bold,
                            ),
                          );
                        },
                      ),
                    ),
                  ),
                ),
              if (type == 'VIDEO')
                const Center(
                  child: Icon(
                    LucideIcons.playCircle,
                    color: Colors.white,
                    size: 60,
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

    if (_isLoading && project == null) {
      return Scaffold(
        backgroundColor: const Color(0xFF0C312B),
        body: Center(
          child: CircularProgressIndicator(color: M4Theme.premiumBlue),
        ),
      );
    }

    return Scaffold(
      backgroundColor: isDark
          ? const Color(0xFF141B3A)
          : const Color(0xFFF4EFE3),
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
                _buildTitleSection(project, isDark),
                const SizedBox(height: 24),
                // Web parity: one row of three — VIDEO CALL · COMPLETION ·
                // SITE VISIT. The web page carries no CONFIG tile here; the
                // configuration is listed in the Overview below.
                Padding(
                  padding: const EdgeInsets.symmetric(horizontal: 24),
                  child: Row(
                    children: [
                      Expanded(
                        child: _OverviewActionCard(
                          label: 'VIDEO CALL',
                          value: 'Connect Now',
                          icon: LucideIcons.video,
                          isAction: true,
                          onTap: () =>
                              _showRequestDetailsDialog(project, null, 'VC'),
                        ),
                      ),
                      const SizedBox(width: 10),
                      Expanded(
                        child: _OverviewActionCard(
                          label: 'COMPLETION',
                          value: '${project?['completion'] ?? 0}%',
                          icon: LucideIcons.calendar,
                        ),
                      ),
                      const SizedBox(width: 10),
                      Expanded(
                        child: _OverviewActionCard(
                          label: 'SITE VISIT',
                          value: 'Book Tour',
                          icon: LucideIcons.eye,
                          isAction: true,
                          onTap: () => _showRequestDetailsDialog(
                            project,
                            null,
                            'Site Visit',
                          ),
                        ),
                      ),
                    ],
                  ),
                ),
                const SizedBox(height: 24),
                Padding(
                  padding: const EdgeInsets.symmetric(horizontal: 24),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      _buildOverviewSection(project),
                      const SizedBox(height: 40),
                      // Web parity: Amenities come BEFORE Construction Progress.
                      _buildAmenitiesSection(project),
                      const SizedBox(height: 40),
                      _buildConstructionSection(project),
                      const SizedBox(height: 40),
                      // Web parity: no standalone Documents section here.
                      _buildContactSection(project),
                      const SizedBox(height: 40),
                      _buildLocationSection(project),
                    ],
                  ),
                ),
                const SizedBox(height: 48),
              ],
            ),
          ),
        ],
      ),
    );
  }

  // Web parity: the project title + location pill sit BELOW the hero, in large
  // dark serif on the page background (not overlaid on the image).
  Widget _buildTitleSection(dynamic project, bool isDark) {
    final onSurface = isDark ? Colors.white : Color(0xFF0C312B);
    final locName =
        ((project?['location'] is Map
                ? project?['location']?['name']
                : project?['location'])
            ?.toString() ??
        'Mazgaon');
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 24),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            (project?['title']?.toString() ?? 'PROJECT NAME').toUpperCase(),
            style: GoogleFonts.gelasio(
              color: onSurface,
              fontSize: 27,
              height: 1,
              letterSpacing: -0.5,
            ),
          ),
          const SizedBox(height: 12),
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 8),
            decoration: BoxDecoration(
              borderRadius: BorderRadius.circular(20),
              border: Border.all(color: onSurface.withOpacity(0.12)),
            ),
            child: Row(
              mainAxisSize: MainAxisSize.min,
              children: [
                Icon(
                  LucideIcons.mapPin,
                  size: 12,
                  color: onSurface.withOpacity(0.6),
                ),
                const SizedBox(width: 6),
                Text(
                  locName,
                  style: GoogleFonts.inter(
                    color: onSurface.withOpacity(0.9),
                    fontSize: 11,
                    fontWeight: FontWeight.w700,
                  ),
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
    final heroImages = project?['heroImages'] as List?;
    final firstHero = (heroImages != null && heroImages.isNotEmpty)
        ? heroImages[0]
        : '';
    final heroUrl = apiClient.resolveUrl(
      project?['heroImage'] ?? project?['coverImage'] ?? firstHero,
    );

    return AspectRatio(
      aspectRatio: 1920 / 1080,
      child: Stack(
        fit: StackFit.expand,
        children: [
          ClipRRect(
            borderRadius: const BorderRadius.vertical(
              bottom: Radius.circular(40),
            ),
            child: _ProjectImage(
              url: heroUrl,
              isDark: isDark,
              // Decode at roughly display size — full-res decodes are what
              // make the hero appear late.
              memCacheWidth: 1080,
            ),
          ),
          Container(
            decoration: BoxDecoration(
              borderRadius: const BorderRadius.vertical(
                bottom: Radius.circular(40),
              ),
              gradient: LinearGradient(
                begin: Alignment.topCenter,
                end: Alignment.bottomCenter,
                colors: [
                  Colors.black.withOpacity(0.12),
                  Colors.transparent,
                  Colors.black.withOpacity(0.35),
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
                _CircleAction(
                  icon: LucideIcons.chevronLeft,
                  onTap: () => Navigator.pop(context),
                ),
                Row(
                  children: [
                    _CircleAction(
                      icon: LucideIcons.share2,
                      onTap: () => Share.share(
                        'Check out ${project?['title']} on M4 Family!',
                      ),
                    ),
                    const SizedBox(width: 12),
                    _CircleAction(
                          // Filled heart when wishlisted; outline otherwise.
                          icon: _isFavorited
                              ? Icons.favorite
                              : LucideIcons.heart,
                          onTap: _toggleFavorite,
                          color: _isFavorited ? Colors.red : null,
                        )
                        .animate(key: ValueKey(_isFavorited))
                        .scaleXY(
                          begin: 0.6,
                          end: 1.0,
                          duration: 320.ms,
                          curve: Curves.elasticOut,
                        ),
                  ],
                ),
              ],
            ),
          ),
          // Web parity: a solid-black status pill sits at the hero's lower-left.
          // Title + location move BELOW the hero; no "Artistic Impression" here.
          Positioned(
            bottom: 20,
            left: 20,
            child: Container(
              padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
              decoration: BoxDecoration(
                color: Colors.black,
                borderRadius: BorderRadius.circular(20),
              ),
              child: Text(
                (project?['status']?.toString().toUpperCase() ?? 'ONGOING'),
                style: GoogleFonts.gelasio(
                  color: Colors.white,
                  fontSize: 10,
                  fontWeight: FontWeight.w700,
                  letterSpacing: 1.5,
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildMediaQuickActions(dynamic project, bool isDark) {
    final apiClient = ref.read(apiClientProvider);
    final heroImages = project?['heroImages'] as List?;
    final firstHero = (heroImages != null && heroImages.isNotEmpty)
        ? heroImages[0]
        : '';
    final heroUrl = apiClient.resolveUrl(
      project?['heroImage'] ?? project?['coverImage'] ?? firstHero,
    );
    // Web parity: distinct exterior/interior thumbnails, not the same hero twice.
    final exteriorImages = project?['exteriorImages'] as List?;
    final interiorImages = project?['interiorImages'] as List?;
    final extUrl = (exteriorImages != null && exteriorImages.isNotEmpty)
        ? apiClient.resolveUrl(exteriorImages[0])
        : heroUrl;
    final intUrl = (interiorImages != null && interiorImages.isNotEmpty)
        ? apiClient.resolveUrl(interiorImages[0])
        : heroUrl;

    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 24),
      child: Row(
        children: [
          _HeroMediaThumb(
            label: 'EXTERIOR',
            imageUrl: extUrl,
            onTap: () => _openHeroGallery(project, 'EXTERIOR'),
          ),
          const SizedBox(width: 12),
          _HeroMediaThumb(
            label: 'INTERIOR',
            imageUrl: intUrl,
            onTap: () => _openHeroGallery(project, 'INTERIOR'),
          ),
          const SizedBox(width: 12),
          _HeroMediaThumb(
            label: '360° VIEW',
            isVR: true,
            onTap: () => _launchAction(
              'Virtual Tour coming soon!',
              project?['threeSixtyUrl'] ?? project?['virtualTourUrl'],
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
        Container(
          width: 24,
          height: 1,
          color: (isDark ? Colors.white : Color(0xFF0C312B)).withOpacity(0.55),
        ),
        const SizedBox(width: 12),
        Text(
          title.toUpperCase(),
          style: GoogleFonts.gelasio(
            fontSize: 11,
            fontWeight: FontWeight.w700,
            color: isDark ? Colors.white : Color(0xFF0C312B),
            letterSpacing: 3,
          ),
        ),
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
          ('Experience the pinnacle of luxury living with floor-to-ceiling windows, Italian marble flooring, and smart home automation. ${project?['description'] ?? ''}')
              .toString()
              .trim()
              .toUpperCase(),
          // Web parity: overview copy capped at 3 lines.
          maxLines: 3,
          overflow: TextOverflow.ellipsis,
          style: GoogleFonts.inter(
            // Was 11 / 60% — small & faint. Bigger + darker.
            fontSize: 12.5,
            color: (isDark ? Colors.white : Color(0xFF0C312B)).withOpacity(
              0.78,
            ),
            height: 1.7,
            fontWeight: FontWeight.w600,
            letterSpacing: 0.2,
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
        // Web parity: E-BROCHURE shows only when the project actually has a
        // brochure (Cledor Mazgaon has one; Cledor Mumbai does not).
        if (project?['brochure']?.toString().trim().isNotEmpty ?? false) ...[
          const SizedBox(height: 12),
          _MultimediaAssetCard(
            title: 'E-BROCHURE',
            subtitle: 'FULL SHOWCASE • PDF',
            icon: LucideIcons.layers,
            onView: () => _launchAction('Opening...', project?['brochure']),
            onDownload: () =>
                _launchAction('Downloading...', project?['brochure']),
          ),
        ],
        const SizedBox(height: 12),
        // Web parity: floor plans appear here as resource cards
        // (e.g. "2BHK, MASTER BEDROOM" — CONFIGURATION N/A • AREA N/A).
        ...(((project?['plans'] as List?) ?? []).map((plan) {
          final cfg = plan is Map ? plan['config']?.toString() : null;
          final area = plan is Map ? plan['area']?.toString() : null;
          final planImg = plan is Map ? plan['image']?.toString() : null;
          final planTitle = (plan is Map ? plan['title']?.toString() : null);
          return Padding(
            padding: const EdgeInsets.only(top: 12),
            child: _MultimediaAssetCard(
              title: (planTitle == null || planTitle.isEmpty)
                  ? 'FLOOR PLAN'
                  : planTitle,
              subtitle:
                  '${(cfg == null || cfg.isEmpty) ? 'CONFIGURATION N/A' : cfg}'
                  ' • '
                  '${(area == null || area.isEmpty) ? 'AREA N/A' : area}',
              icon: LucideIcons.layoutGrid,
              onView: () => _launchAction('Opening plan...', planImg),
              onDownload: () => _launchAction('Downloading plan...', planImg),
            ),
          );
        })),
        const SizedBox(height: 12),
        _MultimediaAssetCard(
          title: 'WALKTHROUGH',
          subtitle: 'CINEMATIC TOUR • 4K',
          icon: LucideIcons.video,
          isPrimary: true,
          onView: () =>
              _launchAction('Watching Story...', project?['walkthrough']),
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
          projectTitle: project?['title']?.toString() ?? 'PROJECT',
          phases: _progressPhases,
          onPhaseTap: (img) => _showMediaLightbox(img, 'IMAGE'),
          showFullDesc: _showFullProgressDesc,
          onToggle: () =>
              setState(() => _showFullProgressDesc = !_showFullProgressDesc),
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

  Widget _buildPlansSection(dynamic project) {
    final plans = project?['plans'] as List? ?? [];
    if (plans.isEmpty) return const SizedBox.shrink();
    final apiClient = ref.read(apiClientProvider);

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        _buildSectionHeader('Plans'),
        const SizedBox(height: 24),
        ...plans
            .map(
              (plan) => _FloorPlanItem(
                plan: plan,
                imageUrl: apiClient.resolveUrl(plan['image']?.toString()),
                onLaunch: _launchAction,
                onView: _showMediaLightbox,
              ),
            )
            .toList(),
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
            style: GoogleFonts.gelasio(
              fontSize: 10,
              fontWeight: FontWeight.w700,
              color: M4Theme.premiumBlue,
              letterSpacing: 2,
            ),
          ),
          const SizedBox(height: 16),
          Text(
            (project?['description'] ??
                    'Experience luxurious living redefined with M4 Family. Our projects blend architectural excellence with modern comforts to create homes that inspire.')
                .toString()
                .toUpperCase(),
            style: GoogleFonts.inter(
              fontSize: 12,
              color: isDark
                  ? Colors.white.withOpacity(0.9)
                  : const Color(0xFF0C312B),
              height: 1.8,
              fontWeight: FontWeight.w600,
              letterSpacing: 0.2,
            ),
            maxLines: _showFullOverviewDesc ? null : 3,
            overflow: _showFullOverviewDesc
                ? TextOverflow.visible
                : TextOverflow.ellipsis,
          ),
          const SizedBox(height: 12),
          GestureDetector(
            onTap: () =>
                setState(() => _showFullOverviewDesc = !_showFullOverviewDesc),
            child: Text(
              _showFullOverviewDesc ? 'Read less' : 'Read more',
              style: GoogleFonts.inter(
                fontSize: 12,
                fontWeight: FontWeight.w600,
                color: isDark ? Colors.white : Color(0xFF155A4F),
                decoration: TextDecoration.underline,
              ),
            ),
          ),
          const SizedBox(height: 32),
          // Multimedia Assets Header
          Row(
            children: [
              Container(
                padding: const EdgeInsets.symmetric(
                  horizontal: 10,
                  vertical: 4,
                ),
                decoration: BoxDecoration(
                  color: M4Theme.premiumBlue.withOpacity(0.1),
                  borderRadius: BorderRadius.circular(6),
                ),
                child: Text(
                  'RESOURCES',
                  style: GoogleFonts.inter(
                    textStyle: const TextStyle(inherit: true),
                    fontSize: 8,
                    fontWeight: FontWeight.w600,
                    color: M4Theme.premiumBlue,
                    letterSpacing: 1,
                  ),
                ),
              ),
            ],
          ),
          const SizedBox(height: 16),
          // Project Assets (Flyer, Brochure, Walkthrough)
          _MultimediaAssetCard(
            title: 'PROJECT FLYER',
            subtitle: 'HIGH RES • PDF',
            icon: LucideIcons.fileText,
            onView: () => _launchAction('Opening Flyer...', project?['flyer']),
            onDownload: () =>
                _launchAction('Downloading Flyer...', project?['flyer']),
          ),
          const SizedBox(height: 12),
          _MultimediaAssetCard(
            title: 'E-BROCHURE',
            subtitle: 'FULL SHOWCASE • PDF',
            icon: LucideIcons.layers,
            onView: () =>
                _launchAction('Opening Brochure...', project?['brochure']),
            onDownload: () =>
                _launchAction('Downloading Brochure...', project?['brochure']),
          ),
          const SizedBox(height: 12),
          _MultimediaAssetCard(
            title: 'WALKTHROUGH',
            subtitle: 'CINEMATIC TOUR • 4K',
            icon: LucideIcons.video,
            isPrimary: true,
            onView: () => _launchAction(
              'Opening Walkthrough...',
              project?['walkthrough'],
            ),
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
              _OverviewActionCard(
                label: 'COMPLETION',
                value: '${project?['completion'] ?? 0}%',
                icon: LucideIcons.checkCircle2,
              ),
              _OverviewActionCard(
                label: 'CONFIG',
                value: project?['config'] ?? '3 & 4 BHK',
                icon: LucideIcons.layout,
              ),
              _OverviewActionCard(
                label: 'VIDEO CALL',
                value: 'CONNECT NOW',
                icon: LucideIcons.video,
                isAction: true,
                onTap: () => _launchAction(
                  'Connecting to Video Call...',
                  project?['videoCallUrl'],
                ),
              ),
              _OverviewActionCard(
                label: 'SITE VISIT',
                value: 'BOOK TOUR',
                icon: LucideIcons.eye,
                isAction: true,
                onTap: () => _launchAction(
                  'Opening Schedule Flow...',
                  project?['siteVisitUrl'],
                ),
              ),
            ],
          ),
          const SizedBox(height: 32),
          Text(
            'CONNECT WITH US',
            style: GoogleFonts.gelasio(
              fontSize: 10,
              fontWeight: FontWeight.w700,
              color: const Color(0xFF155A4F),
              letterSpacing: 2,
            ),
          ),
          const SizedBox(height: 16),
          Row(
            children: [
              _SocialIconButton(
                icon: LucideIcons.instagram,
                onTap: () => _launchAction(
                  'Opening Instagram',
                  project?['social']?['instagram'],
                ),
              ),
              const SizedBox(width: 12),
              _SocialIconButton(
                icon: LucideIcons.facebook,
                onTap: () => _launchAction(
                  'Opening Facebook',
                  project?['social']?['facebook'],
                ),
              ),
              const SizedBox(width: 12),
              _SocialIconButton(
                icon: LucideIcons.linkedin,
                onTap: () => _launchAction(
                  'Opening LinkedIn',
                  project?['social']?['linkedin'],
                ),
              ),
              const SizedBox(width: 12),
              _SocialIconButton(
                icon: LucideIcons.youtube,
                onTap: () => _launchAction(
                  'Opening YouTube',
                  project?['social']?['youtube'],
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildAmenities(dynamic project) {
    final amenitiesRaw = project?['amenities'] as List? ?? [];
    if (amenitiesRaw.isEmpty)
      return const _EmptyTabContent(message: 'Coming soon');
    final isDark = Theme.of(context).brightness == Brightness.dark;

    return GridView.builder(
      shrinkWrap: true,
      physics: const NeverScrollableScrollPhysics(),
      padding: EdgeInsets.zero,
      gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
        crossAxisCount: 3,
        mainAxisSpacing: 6,
        crossAxisSpacing: 8,
        childAspectRatio: 1.5,
      ),
      itemCount: amenitiesRaw.length,
      itemBuilder: (context, index) {
        final amenity = amenitiesRaw[index];
        final name =
            (amenity is Map
                    ? (amenity['name']?.toString() ?? 'Amenity')
                    : amenity.toString())
                .toUpperCase();
        // Web parity: use the shared LuxuryAmenityIcon with the backend-uploaded
        // (gold-tinted) icon — the "Lobby" concierge glyph is an uploaded asset,
        // not a Lucide/SVG fallback.
        final iconRaw = amenity is Map ? amenity['icon']?.toString() : null;
        final iconUrl = (iconRaw != null && iconRaw.isNotEmpty)
            ? ref.read(apiClientProvider).resolveUrl(iconRaw)
            : null;

        return Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            LuxuryAmenityIcon(name: name, iconUrl: iconUrl, size: 30),
            const SizedBox(height: 10),
            Text(
              name,
              textAlign: TextAlign.center,
              // Was 8px — too small. Bigger + a touch darker.
              style: GoogleFonts.inter(
                fontSize: 9.5,
                fontWeight: FontWeight.w700,
                color: isDark
                    ? Colors.white.withOpacity(0.9)
                    : const Color(0xFF141B3A),
                letterSpacing: 0.3,
                height: 1.15,
              ),
              maxLines: 2,
              overflow: TextOverflow.ellipsis,
            ),
          ],
        );
      },
    );
  }

  Widget _buildInventory(dynamic project) {
    if (_inventory.isEmpty && !_isLoading)
      return const _EmptyTabContent(message: 'Coming soon');
    if (_isLoading)
      return const Center(
        child: CircularProgressIndicator(color: Colors.white24),
      );

    return Column(
      children: _inventory
          .map(
            (unit) => _InventoryItem(
              unit: unit,
              onTap: () => _showBookingOptionsDialog(project),
            ),
          )
          .toList(),
    );
  }

  Widget _buildUpdates(dynamic project) {
    if (_isLoading)
      return const Center(
        child: CircularProgressIndicator(color: Colors.white24),
      );

    final overallProgress = (project?['completion'] ?? 0);
    final estimatedCompletion =
        project?['estimatedCompletionDate'] ?? 'Q1 2028';

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
            projectTitle: project?['title']?.toString() ?? 'PROJECT',
            phases: _progressPhases,
            onPhaseTap: (url) => _showMediaLightbox(url, 'IMAGE'),
            showFullDesc: _showFullProgressDesc,
            onToggle: () =>
                setState(() => _showFullProgressDesc = !_showFullProgressDesc),
          ),

          const SizedBox(height: 32),
          _SectionHeader(title: 'RECENT LOGS'),
          const SizedBox(height: 20),
          if (_updates.isEmpty)
            const _EmptyTabContent(
              message:
                  'Site logs will appear once construction reaches next milestone',
            )
          else
            ..._updates
                .map(
                  (update) => _ConstructionUpdateCard(
                    update: update,
                    imageUrl: ref
                        .read(apiClientProvider)
                        .resolveUrl(update['image']?.toString()),
                  ),
                )
                .toList(),
        ],
      ),
    );
  }

  Widget _buildLocation(dynamic project) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final apiClient = ref.read(apiClientProvider);
    final locName =
        (project?['location'] is Map
                ? project?['location']?['name']
                : project?['location'])
            ?.toString() ??
        'Mazgaon, Mumbai';

    return _buildTabContent(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const SizedBox(height: 0),
          M4MapView(
            query: locName,
            onOpen: () => _launchAction(
              'Opening Maps...',
              'https://www.google.com/maps?q=${Uri.encodeComponent(locName)}',
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
          if (project?['plans'] != null &&
              (project['plans'] as List).isNotEmpty)
            ...((project['plans'] as List)
                .map(
                  (plan) => _FloorPlanItem(
                    plan: plan,
                    imageUrl: apiClient.resolveUrl(plan['image']?.toString()),
                    onLaunch: _launchAction,
                    onView: _showMediaLightbox,
                  ),
                )
                .toList())
          else
            const _EmptyTabContent(
              message: 'Floor plans and layouts are being finalized',
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
          if (docs.isEmpty)
            _DocumentItem(
              title: 'RERA Registration Certificate',
              size: '1.2 MB',
              type: 'LEGAL',
              onLaunch: _launchAction,
            )
          else
            ...docs
                .map(
                  (doc) => _DocumentItem(
                    title: doc['name'] ?? 'Document',
                    size: doc['size'] ?? 'N/A',
                    type: doc['type'] ?? 'GENERAL',
                    onLaunch: _launchAction,
                  ),
                )
                .toList(),
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

  Widget _buildContactSection(dynamic project) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final colorScheme = Theme.of(context).colorScheme;

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        _buildSectionHeader('CONTACT'),
        const SizedBox(height: 24),
        Container(
          width: double.infinity,
          padding: const EdgeInsets.all(20),
          decoration: BoxDecoration(
            color: isDark
                ? colorScheme.surfaceContainerHighest.withValues(alpha: 0.3)
                : Colors.white,
            borderRadius: BorderRadius.circular(40),
            border: Border.all(
              color: colorScheme.outlineVariant.withValues(alpha: 0.5),
            ),
            boxShadow: [
              BoxShadow(
                color: Colors.black.withValues(alpha: 0.1),
                blurRadius: 40,
                offset: const Offset(0, 20),
              ),
            ],
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
                        Text(
                          'INTERESTED IN THIS PROJECT?',
                          style: GoogleFonts.inter(
                            fontSize: 10,
                            fontWeight: FontWeight.w600,
                            color: colorScheme.onSurface,
                            letterSpacing: 0.5,
                          ),
                        ),
                        const SizedBox(height: 4),
                        Text(
                          'CONNECT WITH OUR TEAM TODAY',
                          style: GoogleFonts.inter(
                            fontSize: 7,
                            fontWeight: FontWeight.w500,
                            color: colorScheme.onSurfaceVariant,
                            letterSpacing: 1.2,
                          ),
                        ),
                      ],
                    ),
                  ),
                  Row(
                    children: [
                      _ContactIconBtn(
                        icon: LucideIcons.phone,
                        onTap: () => SupportHandlers.launchCall(
                          project?['phone'] ?? project?['contactPhone'],
                        ),
                      ),
                      const SizedBox(width: 8),
                      _ContactIconBtn(
                        // Web parity: chat opens the Raise Ticket screen with the
                        // subject prefilled (INQUIRY: <project>).
                        icon: LucideIcons.messageCircle,
                        onTap: () => Navigator.push(
                          context,
                          MaterialPageRoute(
                            builder: (context) => RaiseTicketScreen(
                              initialSubject:
                                  'INQUIRY: ${(project?['title'] ?? 'PROJECT').toString().toUpperCase()}',
                            ),
                          ),
                        ),
                      ),
                    ],
                  ),
                ],
              ),
              const SizedBox(height: 24),
              _ScaleButton(
                // Web parity: BOOK YOUR UNIT NOW opens the REQUEST DETAILS
                // sheet straight away — the web has no intermediate
                // "how can we help?" chooser.
                onTap: () =>
                    _showRequestDetailsDialog(project, null, 'General'),
                child: Container(
                  width: double.infinity,
                  height: 64,
                  decoration: BoxDecoration(
                    color: isDark ? Colors.white : Color(0xFF0C312B),
                    borderRadius: BorderRadius.circular(24),
                  ),
                  child: Center(
                    child: Text(
                      'BOOK YOUR UNIT NOW',
                      style: GoogleFonts.gelasio(
                        color: isDark
                            ? const Color(0xFF0C312B)
                            : const Color(0xFFF4EFE3),
                        fontWeight: FontWeight.w700,
                        fontSize: 10,
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
    );
  }

  Widget _ContactIconBtn({
    required IconData icon,
    required VoidCallback onTap,
  }) {
    final colorScheme = Theme.of(context).colorScheme;
    return Material(
      color: colorScheme.surface,
      borderRadius: BorderRadius.circular(14),
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(14),
        child: Container(
          width: 44,
          height: 44,
          decoration: BoxDecoration(
            borderRadius: BorderRadius.circular(14),
            border: Border.all(
              color: colorScheme.outlineVariant.withValues(alpha: 0.5),
            ),
          ),
          child: Icon(icon, size: 18, color: colorScheme.onSurface),
        ),
      ),
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
          color: const Color(0xFFF4EFE3),
          borderRadius: BorderRadius.circular(20),
          boxShadow: [
            BoxShadow(
              color: Colors.black.withOpacity(0.2),
              blurRadius: 40,
              offset: const Offset(0, 20),
            ),
          ],
        ),
        child: Row(
          children: [
            _BottomIconAction(
              icon: LucideIcons.phone,
              onTap: () => SupportHandlers.launchCall(
                project?['phone'] ?? project?['contactPhone'],
              ),
            ),
            const SizedBox(width: 12),
            _BottomIconAction(
              icon: LucideIcons.messageSquare,
              onTap: () => SupportHandlers.launchWhatsApp(
                project?['whatsapp'] ??
                    project?['phone'] ??
                    project?['contactPhone'],
              ),
            ),
            const SizedBox(width: 12),
            Expanded(
              child: _ScaleButton(
                onTap: () =>
                    Navigator.push(
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
                      style: GoogleFonts.gelasio(
                        color: Colors.white,
                        fontWeight: FontWeight.w700,
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
    );
  }

  // Web parity: the same custom thin-line amenity vectors as
  // components/shared/LuxuryAmenityIcon.tsx, rendered via flutter_svg.
  static const Map<String, String> _amenitySvgPaths = {
    'pool':
        '<path d="M2 10c3-1.5 5-1.5 8 0s5 1.5 8 0 5-1.5 8 0"/><path d="M2 14c3-1.5 5-1.5 8 0s5 1.5 8 0 5-1.5 8 0"/><path d="M2 18c3-1.5 5-1.5 8 0s5 1.5 8 0 5-1.5 8 0"/>',
    'security':
        '<path d="M12 22s8-4 8-10V5l-8-3-8 3v7c0 6 8 10 8 10z"/><path d="M9 11l2 2 4-4"/>',
    'garden':
        '<path d="M12 19V9M12 9a3 3 0 0 0-3-3 3 3 0 0 0-3 3v10M12 9a3 3 0 0 1 3-3 3 3 0 0 1 3 3v10"/><path d="M6 19h12"/>',
    'sunroof':
        '<rect x="4" y="4" width="16" height="16" rx="2"/><path d="M4 12h16M12 4v16"/><circle cx="12" cy="12" r="3"/>',
    'gym':
        '<path d="M6 6h2v12H6zM16 6h2v12h-2zM2 9h4v6H2zM18 9h4v6h-4zM8 12h8"/>',
    'playground':
        '<path d="M4 20L10 4M20 20L14 4M10 4h4"/><path d="M8 8h8"/><path d="M9 8v6M15 8v6M8 14h8"/>',
    'cricket':
        '<path d="M18.5 5.5L5.5 18.5a1.5 1.5 0 0 0 0 2.1a1.5 1.5 0 0 0 2.1 0l13-13a1.5 1.5 0 0 0 0-2.1a1.5 1.5 0 0 0-2.1 0z"/><path d="M4 20l-2 2M6.5 17.5L5 19M16.5 7.5L15 9"/><circle cx="17" cy="17" r="2"/>',
    'parking':
        '<circle cx="12" cy="12" r="9"/><path d="M9 17V7h4a3 3 0 0 1 0 6H9"/>',
    'clubhouse':
        '<path d="M3 13v4h18v-4"/><path d="M3 13c0-3 2-4 5-4h8c3 0 5 1 5 4"/><path d="M6 17v2M18 17v2M3 13h18"/>',
    'reading':
        '<path d="M4 5h16M4 12h16M4 19h16"/><path d="M7 5v7M11 5v7M16 12v7M12 12v7"/>',
    'jogging':
        '<path d="M4 12c0-4.4 3.6-8 8-8s8 3.6 8 8-3.6 8-8 8"/><path d="M8 12c0-2.2 1.8-4 4-4s4 1.8 4 4-1.8 4-4 4"/>',
  };

  /// Web parity: mirrors getLuxuryIconKey() name→vector mapping (order matters —
  /// e.g. "Kids Pool" → playground before pool; "Parking" is excluded from park).
  String? _amenityKey(String name) {
    final n = name.toLowerCase();
    if (n.contains('clubhouse') || n.contains('pavilion')) return 'clubhouse';
    if (n.contains('playground') || n.contains('kids')) return 'playground';
    if (n.contains('reading') || n.contains('book')) return 'reading';
    if (n.contains('gym') || n.contains('fitness')) return 'gym';
    if (n.contains('pool')) return 'pool';
    if (n.contains('garden') ||
        n.contains('lawn') ||
        (n.contains('park') && !n.contains('parking'))) {
      return 'garden';
    }
    if (n.contains('parking') || n.contains('car')) return 'parking';
    if (n.contains('jogging') || n.contains('track')) return 'jogging';
    if (n.contains('security') ||
        n.contains('guard') ||
        n.contains('safe') ||
        n.contains('24/7')) {
      return 'security';
    }
    if (n.contains('cricket') ||
        n.contains('ground') ||
        n.contains('sports') ||
        n.contains('field') ||
        n.contains('court')) {
      return 'cricket';
    }
    if (n.contains('sunroof') || n.contains('skylight') || n.contains('roof')) {
      return 'sunroof';
    }
    return null;
  }

  Widget _amenityIconWidget(String name, {double size = 30}) {
    final key = _amenityKey(name);
    final paths = key != null ? _amenitySvgPaths[key] : null;
    if (paths != null) {
      final svg =
          '<svg viewBox="0 0 24 24" fill="none" stroke="#DFBA6B" '
          'stroke-width="1.5" stroke-linecap="round" stroke-linejoin="round">'
          '$paths</svg>';
      return SvgPicture.string(svg, width: size, height: size);
    }
    return Icon(
      _getAmenityIcon(name),
      color: const Color(0xFF155A4F),
      size: size,
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
    if (n.contains('playground') || n.contains('kids'))
      return LucideIcons.toyBrick;
    if (n.contains('clubhouse')) return LucideIcons.building2;
    if (n.contains('security')) return LucideIcons.shieldCheck;
    if (n.contains('parking')) return LucideIcons.car;
    return LucideIcons.sparkles;
  }
}

// Helper Widgets
/// Project imagery arrives either as a URL or as an inline `data:image;base64`
/// payload (the CMS stores some heroes that way — Skyline Heights is one).
/// CachedNetworkImage is an HTTP loader and renders a data URI as a blank box,
/// so those are decoded to bytes instead.
class _ProjectImage extends StatelessWidget {
  final String url;
  final bool isDark;
  final int? memCacheWidth;

  const _ProjectImage({
    required this.url,
    required this.isDark,
    this.memCacheWidth,
  });

  Widget _fallback() => Container(
    color: isDark ? Colors.white10 : const Color(0xFF163A2C).withOpacity(0.1),
  );

  @override
  Widget build(BuildContext context) {
    if (url.isEmpty) return _fallback();

    if (url.startsWith('data:')) {
      final comma = url.indexOf(',');
      if (comma == -1) return _fallback();
      try {
        final bytes = base64Decode(url.substring(comma + 1));
        return Image.memory(
          bytes,
          fit: BoxFit.cover,
          width: double.infinity,
          height: double.infinity,
          cacheWidth: memCacheWidth,
          gaplessPlayback: true,
          errorBuilder: (_, _, _) => _fallback(),
        );
      } catch (_) {
        return _fallback();
      }
    }

    return CachedNetworkImage(
      imageUrl: url,
      fit: BoxFit.cover,
      memCacheWidth: memCacheWidth,
      fadeInDuration: Duration.zero,
      placeholder: (context, url) => _fallback(),
      errorWidget: (context, url, error) => _fallback(),
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
    this.onTap,
  });

  @override
  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;

    return GestureDetector(
      onTap: onTap,
      // Web parity: icon stacked above the label and value, centred, so three
      // cards sit side by side. The old icon-beside-label row could not fit at
      // a third of the width.
      child: Container(
        height: 140,
        padding: const EdgeInsets.symmetric(vertical: 24, horizontal: 8),
        decoration: BoxDecoration(
          color: isDark ? const Color(0xFF141B3A) : const Color(0xFFF4EFE3),
          borderRadius: BorderRadius.circular(20),
          border: Border.all(
            color: isDark
                ? Colors.white.withOpacity(0.08)
                : Colors.black.withOpacity(0.05),
          ),
          boxShadow: isDark
              ? []
              : [
                  BoxShadow(
                    color: Colors.black.withOpacity(0.05),
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
              size: 24,
              color: isDark ? Colors.white60 : const Color(0xFF155A4F),
            ),
            Column(
              children: [
                Text(
                  label.toUpperCase(),
                  textAlign: TextAlign.center,
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                  style: GoogleFonts.gelasio(
                    fontSize: 9,
                    fontWeight: FontWeight.w700,
                    color: isDark ? Colors.white70 : const Color(0xFF155A4F),
                    letterSpacing: 1.2,
                  ),
                ),
                const SizedBox(height: 4),
                FittedBox(
                  fit: BoxFit.scaleDown,
                  child: Text(
                    value,
                    textAlign: TextAlign.center,
                    maxLines: 1,
                    style: GoogleFonts.inter(
                      fontSize: 13,
                      fontWeight: FontWeight.w700,
                      color: isDark ? Colors.white : const Color(0xFF155A4F),
                      letterSpacing: -0.2,
                    ),
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
        border: Border.all(
          color: color?.withOpacity(0.2) ?? Colors.white.withOpacity(0.4),
        ),
      ),
      child: Text(
        text,
        style: GoogleFonts.inter(
          fontSize: 8,
          fontWeight: FontWeight.w600,
          color: color != null
              ? Colors.white
              : const Color(0xFF0C312B).withOpacity(0.7),
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
        color: const Color(0xFFF4EFE3).withOpacity(0.6),
        borderRadius: BorderRadius.circular(24),
        border: Border.all(color: Colors.white.withOpacity(0.6)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Container(
            padding: const EdgeInsets.all(8),
            decoration: BoxDecoration(
              color: M4Theme.premiumBlue.withOpacity(0.05),
              borderRadius: BorderRadius.circular(10),
            ),
            child: Icon(icon, color: M4Theme.premiumBlue, size: 20),
          ),
          const SizedBox(height: 16),
          Text(
            title,
            style: GoogleFonts.inter(
              fontSize: 12,
              fontWeight: FontWeight.w600,
              color: const Color(0xFF0C312B),
              letterSpacing: 1,
            ),
          ),
          const SizedBox(height: 4),
          Text(
            subtitle,
            style: GoogleFonts.inter(
              fontSize: 8,
              fontWeight: FontWeight.bold,
              color: const Color(0xFF0C312B).withOpacity(0.72),
            ),
          ),
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
        child: Center(
          child: Icon(icon, color: const Color(0xFF0C312B), size: 20),
        ),
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
      style: GoogleFonts.gelasio(
        fontSize: 10,
        fontWeight: FontWeight.w700,
        color: M4Theme.premiumBlue,
        letterSpacing: 2,
      ),
    );
  }
}

class _LocationLandmark extends StatelessWidget {
  final IconData icon;
  final String title;
  final String distance;
  const _LocationLandmark({
    required this.icon,
    required this.title,
    required this.distance,
  });
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
              color: isDark
                  ? Colors.white.withOpacity(0.05)
                  : Colors.black.withOpacity(0.04),
              borderRadius: BorderRadius.circular(15),
            ),
            child: Icon(
              icon,
              color: isDark ? Colors.white38 : Color(0xFF155A4F),
              size: 20,
            ),
          ),
          const SizedBox(width: 16),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  title,
                  style: GoogleFonts.inter(
                    fontSize: 13,
                    fontWeight: FontWeight.bold,
                    color: isDark ? Colors.white : Color(0xFF155A4F),
                  ),
                ),
                Text(
                  distance.toUpperCase(),
                  style: GoogleFonts.inter(
                    fontSize: 10,
                    fontWeight: FontWeight.w600,
                    color: isDark ? Colors.white24 : Color(0x420C312B),
                    letterSpacing: 0.5,
                  ),
                ),
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
        color: isDark
            ? const Color(0xFF141B3A)
            : Color(0xFF163A2C).withOpacity(0.04),
        borderRadius: BorderRadius.circular(24),
        border: Border.all(
          color: isDark
              ? Colors.white.withOpacity(0.05)
              : Colors.black.withOpacity(0.05),
        ),
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
                memCacheWidth: 900,
                fadeInDuration: Duration.zero,
                placeholder: (context, url) =>
                    Container(height: 200, color: Colors.black12),
                errorWidget: (context, url, error) => Container(
                  height: 200,
                  color: isDark
                      ? Colors.white.withOpacity(0.05)
                      : Colors.black.withOpacity(0.05),
                  child: Center(
                    child: Icon(
                      LucideIcons.image,
                      color: isDark
                          ? Colors.white.withOpacity(0.1)
                          : const Color(0xFF0C312B).withOpacity(0.1),
                    ),
                  ),
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
                    Text(
                      (plan['title'] ?? 'Floor Plan').toUpperCase(),
                      style: GoogleFonts.inter(
                        fontSize: 12,
                        fontWeight: FontWeight.w600,
                        color: isDark ? Colors.white : Color(0xFF155A4F),
                        letterSpacing: 0.5,
                      ),
                    ),
                    if (plan['area'] != null &&
                        plan['area'].toString().isNotEmpty)
                      Text(
                        plan['area'].toUpperCase(),
                        style: GoogleFonts.inter(
                          fontSize: 8,
                          fontWeight: FontWeight.bold,
                          color: isDark ? Colors.white24 : Color(0x420C312B),
                          letterSpacing: 1,
                        ),
                      ),
                  ],
                ),
              ),
              GestureDetector(
                onTap: () => onLaunch('Downloading Floor Plan...', imageUrl),
                child: Icon(
                  LucideIcons.download,
                  color: isDark ? Colors.white38 : Color(0xFF155A4F),
                  size: 18,
                ),
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
    return Center(
      child: Text(
        message,
        textAlign: TextAlign.center,
        style: GoogleFonts.inter(
          fontSize: 12,
          color: isDark ? Colors.white38 : Color(0xFF155A4F),
        ),
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
          color: isDark
              ? const Color(0xFF141B3A)
              : Colors.white.withOpacity(0.6),
          borderRadius: BorderRadius.circular(24),
          border: Border.all(
            color: isDark
                ? Colors.white.withOpacity(0.05)
                : Colors.white.withOpacity(0.6),
          ),
        ),
        child: Column(
          children: [
            Row(
              children: [
                Container(
                  padding: const EdgeInsets.all(12),
                  decoration: BoxDecoration(
                    color: isDark
                        ? Colors.white.withOpacity(0.05)
                        : Colors.black.withOpacity(0.04),
                    borderRadius: BorderRadius.circular(15),
                  ),
                  child: Icon(
                    LucideIcons.home,
                    color: isDark ? Colors.white : Color(0xFF0C312B),
                    size: 20,
                  ),
                ),
                const SizedBox(width: 16),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        'UNIT ${unit['unitNumber']}',
                        style: GoogleFonts.inter(
                          fontSize: 14,
                          fontWeight: FontWeight.w600,
                          color: const Color(0xFF0C312B),
                        ),
                      ),
                      Text(
                        '${unit['type']} • ${unit['area']} SQFT',
                        style: GoogleFonts.inter(
                          fontSize: 11,
                          color: const Color(0xFF0C312B).withOpacity(0.72),
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                    ],
                  ),
                ),
                Column(
                  crossAxisAlignment: CrossAxisAlignment.end,
                  children: [
                    Text(
                      '$currency ${unit['price']}',
                      style: GoogleFonts.inter(
                        fontSize: 14,
                        fontWeight: FontWeight.w600,
                        color: M4Theme.premiumBlue,
                      ),
                    ),
                    Text(
                      'EXCL. TAXES',
                      style: GoogleFonts.inter(
                        fontSize: 8,
                        color: const Color(0xFF0C312B).withOpacity(0.72),
                        fontWeight: FontWeight.bold,
                        letterSpacing: 0.5,
                      ),
                    ),
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
                child: Text(
                  'BOOK NOW',
                  style: GoogleFonts.gelasio(
                    fontSize: 10,
                    fontWeight: FontWeight.w700,
                    letterSpacing: 2,
                    color: const Color(0xFF0C312B),
                  ),
                ),
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
    final progress =
        double.tryParse(update['progress']?.toString() ?? '0') ?? 10.0;
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
                  memCacheWidth: 900,
                  fadeInDuration: Duration.zero,
                  placeholder: (context, url) =>
                      Container(height: 180, color: Colors.black12),
                  errorWidget: (context, url, error) => Container(
                    height: 180,
                    color: Colors.black.withOpacity(0.05),
                    child: Center(
                      child: Icon(
                        LucideIcons.image,
                        color: const Color(0xFF0C312B).withOpacity(0.1),
                      ),
                    ),
                  ),
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
                        style: GoogleFonts.inter(
                          fontSize: 13,
                          fontWeight: FontWeight.w600,
                          color: const Color(0xFF0C312B),
                        ),
                        overflow: TextOverflow.ellipsis,
                      ),
                    ),
                    const SizedBox(width: 8),
                    Text(
                      update['date']?.toString() ?? '',
                      style: GoogleFonts.inter(
                        fontSize: 10,
                        color: const Color(0xFF0C312B).withOpacity(0.72),
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 8),
                Text(
                  update['description'] ?? '',
                  style: GoogleFonts.inter(
                    fontSize: 11,
                    color: const Color(0xFF0C312B).withOpacity(0.6),
                    height: 1.5,
                  ),
                ),
                const SizedBox(height: 20),
                // Progress Bar
                Stack(
                  children: [
                    Container(
                      height: 4,
                      width: double.infinity,
                      decoration: BoxDecoration(
                        color: Colors.black.withOpacity(0.05),
                        borderRadius: BorderRadius.circular(2),
                      ),
                    ),
                    FractionallySizedBox(
                      widthFactor: progress / 100,
                      child: Container(
                        height: 4,
                        decoration: BoxDecoration(
                          color: M4Theme.premiumBlue,
                          borderRadius: BorderRadius.circular(2),
                        ),
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
  const _DocumentItem({
    required this.title,
    required this.size,
    required this.type,
    required this.onLaunch,
  });

  @override
  Widget build(BuildContext context) {
    return _ScaleButton(
      onTap: () => onLaunch('Downloading Document...', null),
      child: Container(
        margin: const EdgeInsets.only(bottom: 12),
        padding: const EdgeInsets.all(16),
        decoration: BoxDecoration(
          color: const Color(0xFFF4EFE3).withOpacity(0.6),
          borderRadius: BorderRadius.circular(16),
          border: Border.all(color: Colors.white.withOpacity(0.6)),
        ),
        child: Row(
          children: [
            Container(
              padding: const EdgeInsets.all(10),
              decoration: BoxDecoration(
                color: M4Theme.premiumBlue.withOpacity(0.05),
                borderRadius: BorderRadius.circular(10),
              ),
              child: const Icon(
                LucideIcons.fileText,
                color: M4Theme.premiumBlue,
                size: 18,
              ),
            ),
            const SizedBox(width: 16),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    title.toUpperCase(),
                    style: GoogleFonts.inter(
                      fontSize: 11,
                      fontWeight: FontWeight.w600,
                      color: const Color(0xFF0C312B),
                    ),
                  ),
                  Text(
                    '$type • $size',
                    style: GoogleFonts.inter(
                      fontSize: 9,
                      color: const Color(0xFF0C312B).withOpacity(0.72),
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                ],
              ),
            ),
            Icon(
              LucideIcons.download,
              color: const Color(0xFF0C312B).withOpacity(0.24),
              size: 18,
            ),
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
  Widget build(
    BuildContext context,
    double shrinkOffset,
    bool overlapsContent,
  ) {
    return Container(color: Colors.white, child: tabBar);
  }

  @override
  bool shouldRebuild(_SliverAppBarDelegate oldDelegate) => false;
}

class _FilterChip extends StatelessWidget {
  final String label;
  final bool isActive;
  final VoidCallback onTap;

  const _FilterChip({
    required this.label,
    required this.isActive,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onTap,
      child:
          Container(
                padding: const EdgeInsets.symmetric(
                  horizontal: 16,
                  vertical: 8,
                ),
                decoration: BoxDecoration(
                  color: isActive
                      ? M4Theme.premiumBlue
                      : Colors.black.withOpacity(0.04),
                  borderRadius: BorderRadius.circular(12),
                  border: Border.all(
                    color: isActive
                        ? M4Theme.premiumBlue
                        : Colors.black.withOpacity(0.05),
                  ),
                ),
                child: Text(
                  label,
                  style: GoogleFonts.inter(
                    fontSize: 9,
                    fontWeight: FontWeight.w600,
                    color: isActive
                        ? Colors.white
                        : const Color(0xFF0C312B).withOpacity(0.72),
                    letterSpacing: 1.0,
                  ),
                ),
              )
              .animate(target: isActive ? 1 : 0)
              .scale(duration: 100.ms, end: const Offset(0.95, 0.95)),
    );
  }
}

class _TopIconButton extends StatelessWidget {
  final IconData icon;
  final VoidCallback onTap;
  final Color color;

  const _TopIconButton({
    required this.icon,
    required this.onTap,
    this.color = Colors.black,
  });

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
              color: const Color(0xFFF4EFE3).withOpacity(0.8),
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
          color: isDark
              ? Colors.white.withOpacity(0.05)
              : Colors.black.withOpacity(0.04),
          borderRadius: BorderRadius.circular(15),
          border: Border.all(
            color: isDark
                ? Colors.white.withOpacity(0.05)
                : Colors.black.withOpacity(0.05),
          ),
        ),
        child: Icon(
          icon,
          color: isDark ? Colors.white : Color(0xFF0C312B),
          size: 20,
        ),
      ),
    );
  }
}

/// Web parity: an embedded Google Map (matching the web iframe) with
/// "Open in Maps" and "VIEW ON MAPS" overlays, via webview_flutter.
/// Web parity: the construction progress ring is a DOTTED circle
/// (SVG strokeDasharray="1.5 1.5") — the filled portion in the accent color,
/// the remainder in a faded track. Rendered here with a dashed-arc painter.
class _DottedProgressRing extends StatelessWidget {
  final double percent;
  final double size;
  final double strokeWidth;
  final int dashCount;
  final Color activeColor;
  final Color trackColor;

  const _DottedProgressRing({
    required this.percent,
    required this.activeColor,
    required this.trackColor,
    this.size = 96,
    this.strokeWidth = 3,
    this.dashCount = 60,
  });

  @override
  Widget build(BuildContext context) {
    return SizedBox(
      width: size,
      height: size,
      child: CustomPaint(
        painter: _DottedRingPainter(
          percent: percent,
          strokeWidth: strokeWidth,
          dashCount: dashCount,
          activeColor: activeColor,
          trackColor: trackColor,
        ),
      ),
    );
  }
}

class _DottedRingPainter extends CustomPainter {
  final double percent;
  final double strokeWidth;
  final int dashCount;
  final Color activeColor;
  final Color trackColor;

  _DottedRingPainter({
    required this.percent,
    required this.strokeWidth,
    required this.dashCount,
    required this.activeColor,
    required this.trackColor,
  });

  @override
  void paint(Canvas canvas, Size size) {
    final center = Offset(size.width / 2, size.height / 2);
    final radius = (size.width - strokeWidth) / 2;
    final anglePer = 2 * math.pi / dashCount;
    // Web parity ("1.5 1.5" dasharray): equal dash/gap with BUTT caps so each
    // dash stays a distinct tick (round caps overlap into a solid ring).
    final dashAngle = anglePer * 0.5;
    final active = (percent.clamp(0, 100) / 100 * dashCount).round();
    final rect = Rect.fromCircle(center: center, radius: radius);
    for (int i = 0; i < dashCount; i++) {
      final start = -math.pi / 2 + i * anglePer;
      final paint = Paint()
        ..style = PaintingStyle.stroke
        ..strokeWidth = strokeWidth
        ..strokeCap = StrokeCap.butt
        ..color = i < active ? activeColor : trackColor;
      canvas.drawArc(rect, start, dashAngle, false, paint);
    }
  }

  @override
  bool shouldRepaint(covariant _DottedRingPainter old) =>
      old.percent != percent ||
      old.activeColor != activeColor ||
      old.trackColor != trackColor;
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
    required this.onTap,
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
          color: isDark ? const Color(0xFF141B3A) : const Color(0xFFEDE5D6),
          borderRadius: BorderRadius.circular(18),
          border: Border.all(
            color: isDark
                ? Colors.white.withOpacity(0.1)
                : Colors.black.withOpacity(0.08),
            width: 1.5,
          ),
          boxShadow: [
            BoxShadow(
              color: Colors.black.withOpacity(0.15),
              blurRadius: 10,
              offset: const Offset(0, 4),
            ),
          ],
        ),
        clipBehavior: Clip.antiAlias,
        child: Stack(
          fit: StackFit.expand,
          children: [
            if (isVR)
              Container(
                color: isDark
                    ? const Color(0xFF141B3A)
                    : const Color(0xFFF4EFE3),
                child: Center(
                  child: Column(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      // A vector icon rather than the 360-vr.png bitmap: it
                      // tints with the theme and needs no multiply blend to
                      // hide the PNG's white plate.
                      Icon(
                        LucideIcons.rotate3d,
                        size: 26,
                        color: isDark ? Colors.white : const Color(0xFF155A4F),
                      ),
                      const SizedBox(height: 4),
                      Text(
                        '360° VIEW',
                        style: GoogleFonts.inter(
                          fontSize: 7,
                          fontWeight: FontWeight.w600,
                          color: isDark ? Colors.white : Color(0xFF155A4F),
                        ),
                      ),
                    ],
                  ),
                ),
              )
            else if (imageUrl != null)
              _ProjectImage(url: imageUrl!, isDark: isDark, memCacheWidth: 900),

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
                  style: GoogleFonts.inter(
                    fontSize: 7,
                    fontWeight: FontWeight.w600,
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
    this.onDownload,
  });

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;

    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: isDark ? const Color(0xFF141B3A) : const Color(0xFFF4EFE3),
        borderRadius: BorderRadius.circular(24),
        border: Border.all(
          color: isDark
              ? Colors.white.withOpacity(0.05)
              : Colors.black.withOpacity(0.05),
        ),
      ),
      child: Row(
        children: [
          Container(
            width: 44,
            height: 44,
            decoration: BoxDecoration(
              // Web parity: all document icons are dark on a light-grey tile
              // (the WALKTHROUGH icon was gold via isPrimary).
              color: isDark
                  ? Colors.white.withOpacity(0.05)
                  : Colors.black.withOpacity(0.04),
              borderRadius: BorderRadius.circular(12),
            ),
            child: Icon(
              icon,
              color: isDark ? Colors.white : Color(0xFF0C312B),
              size: 18,
            ),
          ),
          const SizedBox(width: 16),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  title.toUpperCase(),
                  style: GoogleFonts.inter(
                    fontSize: 11,
                    fontWeight: FontWeight.w600,
                    color: isDark ? Colors.white : Color(0xFF155A4F),
                    letterSpacing: 0.5,
                  ),
                ),
                const SizedBox(height: 3),
                Text(
                  subtitle.toUpperCase(),
                  // Was 7px / 38% — too small & faint. Bigger + darker.
                  style: GoogleFonts.inter(
                    fontSize: 9,
                    fontWeight: FontWeight.w700,
                    color: isDark ? Colors.white60 : Color(0xFF155A4F),
                    letterSpacing: 0.5,
                  ),
                ),
              ],
            ),
          ),
          const SizedBox(width: 8),
          Row(
            children: [
              _ScaleButton(
                onTap: onView,
                child: Container(
                  padding: const EdgeInsets.symmetric(
                    horizontal: 14,
                    vertical: 8,
                  ),
                  decoration: BoxDecoration(
                    color: Colors.transparent,
                    borderRadius: BorderRadius.circular(8),
                    border: Border.all(
                      color: isDark ? Colors.white24 : Colors.black12,
                    ),
                  ),
                  child: Text(
                    'VIEW',
                    style: GoogleFonts.inter(
                      fontSize: 8,
                      fontWeight: FontWeight.w600,
                      color: isDark ? Colors.white : Color(0xFF155A4F),
                    ),
                  ),
                ),
              ),
              if (onDownload != null) ...[
                const SizedBox(width: 8),
                _ScaleButton(
                  onTap: onDownload!,
                  child: Container(
                    padding: const EdgeInsets.symmetric(
                      horizontal: 14,
                      vertical: 8,
                    ),
                    decoration: BoxDecoration(
                      color: isDark ? Colors.white : Color(0xFF0C312B),
                      borderRadius: BorderRadius.circular(8),
                    ),
                    child: Text(
                      'DOWNLOAD',
                      style: GoogleFonts.inter(
                        fontSize: 8,
                        fontWeight: FontWeight.w600,
                        color: isDark
                            ? const Color(0xFF0C312B)
                            : const Color(0xFFF4EFE3),
                      ),
                    ),
                  ),
                ),
              ],
              if (isPrimary) ...[
                const SizedBox(width: 8),
                _ScaleButton(
                  onTap: onView,
                  child: Container(
                    padding: const EdgeInsets.symmetric(
                      horizontal: 14,
                      vertical: 8,
                    ),
                    decoration: BoxDecoration(
                      color: isDark ? Colors.white : Color(0xFF0C312B),
                      borderRadius: BorderRadius.circular(8),
                    ),
                    child: Text(
                      'WATCH STORY',
                      style: GoogleFonts.inter(
                        fontSize: 8,
                        fontWeight: FontWeight.w600,
                        color: isDark
                            ? const Color(0xFF0C312B)
                            : const Color(0xFFF4EFE3),
                      ),
                    ),
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
  final String projectTitle;
  final List<dynamic> phases;
  final Function(String) onPhaseTap;
  final bool showFullDesc;
  final VoidCallback onToggle;

  const _ConstructionDashboardCard({
    required this.overallProgress,
    required this.estimatedCompletion,
    required this.projectTitle,
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
      // Investor-parity construction box (master design): subtle translucent
      // fill, radius 40, hairline border, no shadow.
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 36),
      decoration: BoxDecoration(
        color: isDark
            ? Colors.white.withOpacity(0.03)
            : const Color(0xFFF4EFE3),
        borderRadius: BorderRadius.circular(40),
        border: Border.all(
          color: isDark
              ? Colors.white.withOpacity(0.08)
              : Colors.black.withOpacity(0.06),
        ),
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
                    Text(
                      'ESTIMATED COMPLETION',
                      style: GoogleFonts.inter(
                        fontSize: 10,
                        fontWeight: FontWeight.w600,
                        color: isDark ? Colors.white : Color(0xFF155A4F),
                        letterSpacing: 1,
                      ),
                    ),
                    const SizedBox(height: 8),
                    Text(
                      estimatedCompletion.toUpperCase(),
                      style: GoogleFonts.gelasio(
                        fontSize: 40,
                        color: isDark ? Colors.white : Color(0xFF0C312B),
                        height: 1,
                      ),
                    ),
                    const SizedBox(height: 16),
                    Text(
                      'As the project progresses, significant milestones are reached, showcasing our team\'s dedication and expertise. We are steadily moving closer to our completion goal, ensuring quality and safety at every step. Each phase is handled with precision to meet our luxury standards and timeline.',
                      style: GoogleFonts.inter(
                        fontSize: 11,
                        color: (isDark ? Colors.white : Color(0xFF0C312B))
                            .withOpacity(0.6),
                        height: 1.6,
                        fontWeight: FontWeight.w500,
                      ),
                      maxLines: showFullDesc ? null : 3,
                      overflow: showFullDesc
                          ? TextOverflow.visible
                          : TextOverflow.ellipsis,
                    ),
                    const SizedBox(height: 8),
                    GestureDetector(
                      onTap: onToggle,
                      child: Text(
                        showFullDesc ? 'Show less' : 'Read more',
                        style: GoogleFonts.inter(
                          fontSize: 11,
                          fontWeight: FontWeight.w600,
                          color: isDark ? Colors.white : Color(0xFF155A4F),
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
                  // Web parity: the ring uses a repeating "1.5 1.5" dash on the
                  // primary(dark) circle, so dark dots wrap the WHOLE ring — it
                  // reads as a full dense dark dotted circle, not a 15% arc.
                  _DottedProgressRing(
                    // Guest-parity: same ring size + dot size (100 / 56 @ 6px)
                    // as the guest project detail so every portal matches.
                    percent: 100,
                    size: 100,
                    strokeWidth: 6,
                    dashCount: 56,
                    activeColor: isDark ? Colors.white : Color(0xFF0C312B),
                    trackColor: isDark ? Colors.white : Color(0xFF0C312B),
                  ),
                  Column(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Text(
                        '${overallProgress.toInt()}%',
                        style: GoogleFonts.gelasio(
                          fontSize: 22,
                          fontWeight: FontWeight.w700,
                          color: isDark ? Colors.white : Color(0xFF0C312B),
                        ),
                      ),
                      Text(
                        'OVERALL',
                        style: GoogleFonts.inter(
                          fontSize: 8,
                          fontWeight: FontWeight.w600,
                          letterSpacing: 0.5,
                          color: isDark ? Colors.white38 : Color(0x730C312B),
                        ),
                      ),
                    ],
                  ),
                ],
              ),
            ],
          ),
          const SizedBox(height: 40),
          // Web parity: timeline node (year + line + dot) above the phase cards.
          Builder(
            builder: (context) {
              // Web parity: the timeline node year is 2026.
              const year = '2026';
              return Row(
                children: [
                  Text(
                    year,
                    style: GoogleFonts.gelasio(
                      fontSize: 20,
                      fontWeight: FontWeight.w700,
                      color: isDark ? Colors.white : Color(0xFF0C312B),
                    ),
                  ),
                  const SizedBox(width: 16),
                  Container(
                    width: 12,
                    height: 12,
                    decoration: BoxDecoration(
                      shape: BoxShape.circle,
                      color: isDark
                          ? const Color(0xFF141B3A)
                          : const Color(0xFFF4EFE3),
                      border: Border.all(
                        color: isDark ? Colors.white : Color(0xFF0C312B),
                        width: 2,
                      ),
                    ),
                  ),
                  Expanded(
                    child: Container(
                      height: 1,
                      color: (isDark ? Colors.white : Color(0xFF0C312B))
                          .withOpacity(0.2),
                    ),
                  ),
                ],
              );
            },
          ),
          const SizedBox(height: 20),
          // Construction Dashboard Cards
          SizedBox(
            // Same as the guest portal: 220 image + ~125 footer.
            height: 345,
            child: PageView.builder(
              controller: PageController(viewportFraction: 1.0),
              physics: const BouncingScrollPhysics(),
              padEnds: false,
              itemCount: phases.length,
              itemBuilder: (context, index) {
                final phase = phases[index];
                final phaseImages = phase['images'] as List?;
                final firstPhaseImg =
                    (phaseImages != null && phaseImages.isNotEmpty)
                    ? phaseImages[0]
                    : '';
                final imageUrl = apiClient.resolveUrl(
                  phase['image'] ?? firstPhaseImg,
                );
                return Container(
                  // Match the guest portal phase card: full width + shadow
                  // (was a fixed 260-wide horizontal card).
                  margin: const EdgeInsets.symmetric(horizontal: 8),
                  decoration: BoxDecoration(
                    color: isDark
                        ? Colors.white.withOpacity(0.03)
                        : Colors.white,
                    borderRadius: BorderRadius.circular(24),
                    // Subtle in dark so the border doesn't show as a bright edge
                    // behind the image.
                    border: Border.all(
                      color: isDark
                          ? Colors.white.withOpacity(0.08)
                          : Colors.black.withOpacity(0.10),
                    ),
                    boxShadow: [
                      BoxShadow(
                        color: Colors.black.withOpacity(isDark ? 0.35 : 0.07),
                        blurRadius: 14,
                        offset: const Offset(0, 6),
                      ),
                    ],
                  ),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      _ScaleButton(
                        onTap: () => onPhaseTap(imageUrl),
                        child: Stack(
                          children: [
                            ClipRRect(
                              borderRadius: const BorderRadius.vertical(
                                top: Radius.circular(24),
                              ),
                              child: CachedNetworkImage(
                                imageUrl: imageUrl,
                                // Same image size as the guest portal (220).
                                height: 220,
                                width: double.infinity,
                                fit: BoxFit.cover,
                                memCacheWidth: 600,
                                fadeInDuration: Duration.zero,
                                placeholder: (context, url) => Container(
                                  height: 220,
                                  width: double.infinity,
                                  color: Colors.white10,
                                ),
                                errorWidget: (context, url, error) => Container(
                                  height: 220,
                                  width: double.infinity,
                                  color: Colors.white10,
                                ),
                              ),
                            ),
                            // Status badge (web parity): completed=green,
                            // in-progress=solid, else=muted.
                            Positioned(
                              top: 14,
                              left: 14,
                              child: Builder(
                                builder: (_) {
                                  final status =
                                      (phase['status']?.toString() ??
                                      'Upcoming');
                                  final s = status.toLowerCase();
                                  final bg = s == 'completed'
                                      ? const Color(0xFF163A2C)
                                      : s == 'in progress'
                                      ? (isDark
                                            ? Colors.white
                                            : Color(0xFF0C312B))
                                      : (isDark
                                            ? Colors.white24
                                            : Color(
                                                0xFF163A2C,
                                              ).withOpacity(0.12));
                                  final fg = s == 'completed'
                                      ? Colors.white
                                      : s == 'in progress'
                                      ? (isDark ? Colors.black : Colors.white)
                                      : (isDark
                                            ? Colors.white70
                                            : Color(0xFF0C312B));
                                  return Container(
                                    padding: const EdgeInsets.symmetric(
                                      horizontal: 10,
                                      vertical: 5,
                                    ),
                                    decoration: BoxDecoration(
                                      color: bg,
                                      borderRadius: BorderRadius.circular(20),
                                    ),
                                    child: Text(
                                      status.toUpperCase(),
                                      style: GoogleFonts.inter(
                                        fontSize: 8,
                                        fontWeight: FontWeight.w600,
                                        color: fg,
                                        letterSpacing: 1,
                                      ),
                                    ),
                                  );
                                },
                              ),
                            ),
                          ],
                        ),
                      ),
                      Padding(
                        padding: const EdgeInsets.all(20),
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            // Web parity: project title first (e.g. CLÉDOR).
                            Text(
                              projectTitle.toUpperCase(),
                              style: GoogleFonts.inter(
                                fontSize: 11,
                                fontWeight: FontWeight.w600,
                                color: isDark
                                    ? Colors.white
                                    : const Color(0xFF141B3A),
                                letterSpacing: 1,
                              ),
                            ),
                            const SizedBox(height: 14),
                            Row(
                              children: [
                                // Ring with % centered.
                                Stack(
                                  alignment: Alignment.center,
                                  children: [
                                    // Simple solid arc progress ring.
                                    SizedBox(
                                      width: 46,
                                      height: 46,
                                      child: CircularProgressIndicator(
                                        value:
                                            (phase['progressPercent'] ??
                                                    phase['progress'] ??
                                                    0)
                                                .toDouble() /
                                            100,
                                        strokeWidth: 3,
                                        backgroundColor:
                                            (isDark
                                                    ? Colors.white
                                                    : Color(0xFF0C312B))
                                                .withOpacity(0.12),
                                        valueColor:
                                            AlwaysStoppedAnimation<Color>(
                                              isDark
                                                  ? Colors.white
                                                  : Color(0xFF0C312B),
                                            ),
                                      ),
                                    ),
                                    Text(
                                      '${phase['progressPercent'] ?? phase['progress'] ?? 0}%',
                                      style: GoogleFonts.inter(
                                        fontSize: 10,
                                        fontWeight: FontWeight.w600,
                                        color: isDark
                                            ? Colors.white
                                            : Color(0xFF0C312B),
                                      ),
                                    ),
                                  ],
                                ),
                                const SizedBox(width: 14),
                                // Phase name (e.g. FOUNDATION).
                                Expanded(
                                  child: Text(
                                    (phase['name'] ??
                                            phase['phaseName'] ??
                                            'PHASE')
                                        .toString()
                                        .toUpperCase(),
                                    style: GoogleFonts.gelasio(
                                      fontSize: 10,
                                      fontWeight: FontWeight.w700,
                                      color:
                                          (isDark
                                                  ? Colors.white
                                                  : Color(0xFF0C312B))
                                              .withOpacity(0.8),
                                      letterSpacing: 2,
                                    ),
                                    maxLines: 1,
                                    overflow: TextOverflow.ellipsis,
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
              },
            ),
          ),
          const SizedBox(height: 32),
          // Web parity: PHASE TRACKING — real-time milestone list.
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    'PHASE TRACKING',
                    style: GoogleFonts.gelasio(
                      fontSize: 11,
                      fontWeight: FontWeight.w700,
                      color: isDark ? Colors.white : Color(0xFF0C312B),
                      letterSpacing: 4,
                    ),
                  ),
                  const SizedBox(height: 4),
                  Text(
                    'REAL-TIME DEVELOPMENT STATUS',
                    style: GoogleFonts.gelasio(
                      fontSize: 8,
                      fontWeight: FontWeight.w700,
                      color: (isDark ? Colors.white : Color(0xFF0C312B))
                          .withOpacity(0.5),
                      letterSpacing: 1.5,
                    ),
                  ),
                ],
              ),
              Container(
                padding: const EdgeInsets.symmetric(
                  horizontal: 12,
                  vertical: 7,
                ),
                decoration: BoxDecoration(
                  color: (isDark ? Colors.white : Color(0xFF0C312B))
                      .withOpacity(0.05),
                  borderRadius: BorderRadius.circular(20),
                  border: Border.all(
                    color: (isDark ? Colors.white : Color(0xFF0C312B))
                        .withOpacity(0.15),
                  ),
                ),
                child: Text(
                  '${phases.length} MILESTONES',
                  style: GoogleFonts.gelasio(
                    fontSize: 8,
                    fontWeight: FontWeight.w700,
                    color: isDark ? Colors.white : Color(0xFF0C312B),
                    letterSpacing: 1.5,
                  ),
                ),
              ),
            ],
          ),
          const SizedBox(height: 16),
          if (phases.isEmpty)
            Container(
              width: double.infinity,
              padding: const EdgeInsets.symmetric(vertical: 28),
              decoration: BoxDecoration(
                borderRadius: BorderRadius.circular(20),
                border: Border.all(
                  color: (isDark ? Colors.white : Color(0xFF0C312B))
                      .withOpacity(0.12),
                ),
              ),
              child: Center(
                child: Text(
                  'AWAITING CONSTRUCTION DATA',
                  style: GoogleFonts.gelasio(
                    fontSize: 9,
                    fontWeight: FontWeight.w700,
                    color: (isDark ? Colors.white : Color(0xFF0C312B))
                        .withOpacity(0.35),
                    letterSpacing: 1.5,
                  ),
                ),
              ),
            )
          else
            SizedBox(
              height: 96,
              child: ListView.builder(
                scrollDirection: Axis.horizontal,
                itemCount: phases.length,
                itemBuilder: (context, index) {
                  final phase = phases[index];
                  final pct =
                      (phase['progressPercent'] ?? phase['progress'] ?? 0)
                          .toDouble();
                  final status = phase['status']?.toString() ?? 'Upcoming';
                  final s = status.toLowerCase();
                  final dotColor = s == 'completed'
                      ? const Color(0xFF163A2C)
                      : s == 'in progress'
                      ? (isDark ? Colors.white : Color(0xFF0C312B))
                      : (isDark ? Colors.white38 : Colors.black26);
                  return Container(
                    width: 240,
                    margin: const EdgeInsets.only(right: 16),
                    padding: const EdgeInsets.all(16),
                    decoration: BoxDecoration(
                      color: isDark
                          ? Colors.white.withOpacity(0.05)
                          : Colors.white,
                      borderRadius: BorderRadius.circular(20),
                      border: Border.all(
                        color: (isDark ? Colors.white : Color(0xFF0C312B))
                            .withOpacity(0.08),
                      ),
                    ),
                    child: Column(
                      mainAxisAlignment: MainAxisAlignment.center,
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Row(
                          mainAxisAlignment: MainAxisAlignment.spaceBetween,
                          children: [
                            Expanded(
                              child: Row(
                                children: [
                                  Container(
                                    width: 34,
                                    height: 34,
                                    alignment: Alignment.center,
                                    decoration: BoxDecoration(
                                      borderRadius: BorderRadius.circular(10),
                                      border: Border.all(
                                        color:
                                            (isDark
                                                    ? Colors.white
                                                    : Color(0xFF0C312B))
                                                .withOpacity(0.15),
                                      ),
                                    ),
                                    child: Text(
                                      (index + 1).toString().padLeft(2, '0'),
                                      style: GoogleFonts.inter(
                                        fontSize: 10,
                                        fontWeight: FontWeight.w600,
                                        color:
                                            (isDark
                                                    ? Colors.white
                                                    : Color(0xFF0C312B))
                                                .withOpacity(0.72),
                                      ),
                                    ),
                                  ),
                                  const SizedBox(width: 12),
                                  Expanded(
                                    child: Column(
                                      crossAxisAlignment:
                                          CrossAxisAlignment.start,
                                      mainAxisSize: MainAxisSize.min,
                                      children: [
                                        Text(
                                          (phase['name'] ??
                                                  phase['phaseName'] ??
                                                  'PHASE')
                                              .toString()
                                              .toUpperCase(),
                                          maxLines: 1,
                                          overflow: TextOverflow.ellipsis,
                                          style: GoogleFonts.inter(
                                            fontSize: 11,
                                            fontWeight: FontWeight.w600,
                                            color: isDark
                                                ? Colors.white
                                                : Color(0xFF0C312B),
                                            letterSpacing: 1,
                                          ),
                                        ),
                                        const SizedBox(height: 4),
                                        Row(
                                          children: [
                                            Container(
                                              width: 6,
                                              height: 6,
                                              decoration: BoxDecoration(
                                                shape: BoxShape.circle,
                                                color: dotColor,
                                              ),
                                            ),
                                            const SizedBox(width: 6),
                                            Text(
                                              status.toUpperCase(),
                                              style: GoogleFonts.gelasio(
                                                fontSize: 9,
                                                fontWeight: FontWeight.w700,
                                                color:
                                                    (isDark
                                                            ? Colors.white
                                                            : Color(0xFF0C312B))
                                                        .withOpacity(0.5),
                                                letterSpacing: 1.5,
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
                            const SizedBox(width: 8),
                            Text(
                              '${pct.toInt()}%',
                              style: GoogleFonts.gelasio(
                                fontSize: 18,
                                fontWeight: FontWeight.w700,
                                color: isDark
                                    ? Colors.white
                                    : Color(0xFF0C312B),
                                letterSpacing: -0.5,
                              ),
                            ),
                          ],
                        ),
                        const SizedBox(height: 12),
                        ClipRRect(
                          borderRadius: BorderRadius.circular(999),
                          child: LinearProgressIndicator(
                            value: (pct / 100).clamp(0.0, 1.0),
                            minHeight: 6,
                            backgroundColor:
                                (isDark ? Colors.white : Color(0xFF0C312B))
                                    .withOpacity(0.08),
                            valueColor: AlwaysStoppedAnimation<Color>(
                              isDark ? Colors.white : Color(0xFF0C312B),
                            ),
                          ),
                        ),
                      ],
                    ),
                  );
                },
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

  const _MediaFloatThumbnail({
    required this.label,
    required this.image,
    this.is360 = false,
    required this.onTap,
  });

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
                    memCacheWidth: 1080,
                    fadeInDuration: Duration.zero,
                    placeholder: (context, url) =>
                        Container(color: Colors.black12),
                    errorWidget: (context, url, error) =>
                        Container(color: Colors.black12),
                  ),
                ),
                if (is360)
                  const Center(
                    child: Icon(
                      LucideIcons.rotateCcw,
                      color: Colors.white,
                      size: 20,
                    ),
                  ),
              ],
            ),
          ),
        ),
        const SizedBox(height: 2),
        Text(
          label,
          style: GoogleFonts.inter(
            color: Colors.white,
            fontSize: 6,
            fontWeight: FontWeight.w600,
            letterSpacing: 0.5,
          ),
        ),
      ],
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
        Text(
          label.toUpperCase(),
          style: GoogleFonts.inter(
            color: Colors.white70,
            fontSize: 8,
            fontWeight: FontWeight.w600,
            letterSpacing: 1,
          ),
        ),
        Text(
          value,
          style: GoogleFonts.inter(
            color: Colors.white,
            fontSize: 10,
            fontWeight: FontWeight.bold,
          ),
        ),
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
          color: isDark
              ? Colors.white.withOpacity(0.1)
              : const Color(0xFFF4EFE3),
          shape: BoxShape.circle,
          boxShadow: [
            BoxShadow(
              color: Colors.black.withOpacity(0.1),
              blurRadius: 10,
              offset: const Offset(0, 4),
            ),
          ],
          border: Border.all(
            color: isDark
                ? Colors.white.withOpacity(0.1)
                : Colors.black.withOpacity(0.05),
          ),
        ),
        child: Icon(
          icon,
          size: 20,
          color: color ?? (isDark ? Colors.white : Color(0xFF0C312B)),
        ),
      ),
    );
  }
}
