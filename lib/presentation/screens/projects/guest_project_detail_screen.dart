import 'package:dio/dio.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:m4_mobile/core/utils/validators.dart';
import 'package:flutter/cupertino.dart';
import 'package:m4_mobile/core/theme/app_theme.dart';
import 'package:m4_mobile/core/network/api_client.dart';
import 'package:lucide_icons/lucide_icons.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:flutter_animate/flutter_animate.dart';
import 'dart:convert';
import 'dart:typed_data';
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

/// Decoded base64 image bytes keyed by data-URI, so multi-MB inline hero
/// images (e.g. Cledor) decode once instead of on every rebuild.
final Map<String, Uint8List> _detailB64Cache = {};

/// Web parity: the booking dialog's accent (subtitle, section labels, schedule
/// row, field placeholders) is a premium slate-blue, not gray.
const Color _kBookingBlue = Color(0xFF2B4C7E);

/// Web parity: bespoke date+time wheel picker — separate Day | Month | Year |
/// Hour | Minute | AM/PM columns under a "SELECT DATE & TIME" header. Returns
/// the composed [DateTime] via Navigator.pop, or null on dismiss.
class _DateTimeWheelSheet extends StatefulWidget {
  final DateTime initial;
  final bool isDark;
  const _DateTimeWheelSheet({required this.initial, required this.isDark});

  @override
  State<_DateTimeWheelSheet> createState() => _DateTimeWheelSheetState();
}

class _DateTimeWheelSheetState extends State<_DateTimeWheelSheet> {
  static const _months = [
    'JAN',
    'FEB',
    'MAR',
    'APR',
    'MAY',
    'JUN',
    'JUL',
    'AUG',
    'SEP',
    'OCT',
    'NOV',
    'DEC',
  ];

  late int _baseYear; // first selectable year
  static const _yearSpan = 4; // current year .. +3

  late int _year; // absolute year
  late int _month; // 1..12
  late int _day; // 1..daysInMonth
  late int _hour12; // 1..12
  late int _minute; // 0..59
  late int _ampm; // 0 = AM, 1 = PM

  late FixedExtentScrollController _dayCtl,
      _monthCtl,
      _yearCtl,
      _hourCtl,
      _minCtl,
      _ampmCtl;

  @override
  void initState() {
    super.initState();
    final d = widget.initial;
    _baseYear = DateTime.now().year;
    _year = d.year.clamp(_baseYear, _baseYear + _yearSpan - 1);
    _month = d.month;
    _day = d.day;
    _ampm = d.hour >= 12 ? 1 : 0;
    _hour12 = d.hour % 12 == 0 ? 12 : d.hour % 12;
    _minute = d.minute;

    _dayCtl = FixedExtentScrollController(initialItem: _day - 1);
    _monthCtl = FixedExtentScrollController(initialItem: _month - 1);
    _yearCtl = FixedExtentScrollController(initialItem: _year - _baseYear);
    _hourCtl = FixedExtentScrollController(initialItem: _hour12 - 1);
    _minCtl = FixedExtentScrollController(initialItem: _minute);
    _ampmCtl = FixedExtentScrollController(initialItem: _ampm);
  }

  @override
  void dispose() {
    _dayCtl.dispose();
    _monthCtl.dispose();
    _yearCtl.dispose();
    _hourCtl.dispose();
    _minCtl.dispose();
    _ampmCtl.dispose();
    super.dispose();
  }

  int get _daysInMonth => DateTime(_year, _month + 1, 0).day;

  // After a month/year change the current day may no longer exist (e.g. 31 →
  // Feb). Clamp it and snap the day wheel back into range.
  void _clampDay() {
    final max = _daysInMonth;
    if (_day > max) {
      _day = max;
      WidgetsBinding.instance.addPostFrameCallback((_) {
        if (_dayCtl.hasClients) {
          _dayCtl.jumpToItem(_day - 1);
        }
      });
    }
  }

  DateTime _compose() {
    int h24 = _hour12 % 12; // 12 → 0
    if (_ampm == 1) h24 += 12; // PM
    final day = _day > _daysInMonth ? _daysInMonth : _day;
    return DateTime(_year, _month, day, h24, _minute);
  }

  Widget _wheel({
    required FixedExtentScrollController controller,
    required int count,
    required String Function(int) label,
    required ValueChanged<int> onChanged,
    int flex = 2,
  }) {
    final txt = widget.isDark ? Colors.white : Colors.black;
    return Expanded(
      flex: flex,
      child: CupertinoPicker(
        scrollController: controller,
        selectionOverlay: const SizedBox.shrink(),
        itemExtent: 40,
        magnification: 1.05,
        useMagnifier: true,
        squeeze: 1.05,
        onSelectedItemChanged: onChanged,
        children: List.generate(
          count,
          (i) => Center(
            child: Text(
              label(i),
              style: GoogleFonts.ebGaramond(
                fontSize: 17,
                fontWeight: FontWeight.w700,
                color: txt,
              ),
            ),
          ),
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final isDark = widget.isDark;
    final bg = isDark ? const Color(0xFF0B111E) : Colors.white;
    final txt = isDark ? Colors.white : Colors.black;
    // Defensive clamp so the day wheel never renders fewer rows than _day.
    if (_day > _daysInMonth) _day = _daysInMonth;

    return Container(
      padding: EdgeInsets.only(bottom: MediaQuery.of(context).padding.bottom),
      decoration: BoxDecoration(
        color: bg,
        borderRadius: const BorderRadius.vertical(top: Radius.circular(28)),
      ),
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
          const SizedBox(height: 24),
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 24),
            child: Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Text(
                  'SELECT DATE & TIME',
                  style: GoogleFonts.gelasio(
                    fontSize: 18,
                    fontWeight: FontWeight.w900,
                    color: txt,
                    letterSpacing: 0.5,
                  ),
                ),
                GestureDetector(
                  onTap: () => Navigator.pop(context, _compose()),
                  child: Text(
                    'DONE',
                    style: GoogleFonts.ebGaramond(
                      fontSize: 12,
                      fontWeight: FontWeight.w900,
                      color: isDark ? Colors.white : _kBookingBlue,
                      letterSpacing: 1,
                    ),
                  ),
                ),
              ],
            ),
          ),
          const SizedBox(height: 16),
          SizedBox(
            height: 216,
            child: Stack(
              children: [
                // Center selection highlight (rounded row like the web).
                Center(
                  child: Container(
                    height: 40,
                    margin: const EdgeInsets.symmetric(horizontal: 16),
                    decoration: BoxDecoration(
                      color: (isDark ? Colors.white : Colors.black).withValues(
                        alpha: 0.05,
                      ),
                      borderRadius: BorderRadius.circular(10),
                    ),
                  ),
                ),
                Padding(
                  padding: const EdgeInsets.symmetric(horizontal: 16),
                  child: Row(
                    children: [
                      // Day — row count follows the selected month/year; the
                      // persistent controller is snapped back in _clampDay.
                      _wheel(
                        controller: _dayCtl,
                        count: _daysInMonth,
                        label: (i) => (i + 1).toString(),
                        onChanged: (i) => _day = i + 1,
                        flex: 2,
                      ),
                      _wheel(
                        controller: _monthCtl,
                        count: 12,
                        label: (i) => _months[i],
                        onChanged: (i) => setState(() {
                          _month = i + 1;
                          _clampDay();
                        }),
                        flex: 2,
                      ),
                      _wheel(
                        controller: _yearCtl,
                        count: _yearSpan,
                        label: (i) => (_baseYear + i).toString(),
                        onChanged: (i) => setState(() {
                          _year = _baseYear + i;
                          _clampDay();
                        }),
                        flex: 3,
                      ),
                      const SizedBox(width: 8),
                      _wheel(
                        controller: _hourCtl,
                        count: 12,
                        label: (i) => (i + 1).toString().padLeft(2, '0'),
                        onChanged: (i) => _hour12 = i + 1,
                        flex: 2,
                      ),
                      Text(
                        ':',
                        style: GoogleFonts.gelasio(
                          fontSize: 18,
                          fontWeight: FontWeight.w900,
                          color: txt,
                        ),
                      ),
                      _wheel(
                        controller: _minCtl,
                        count: 60,
                        label: (i) => i.toString().padLeft(2, '0'),
                        onChanged: (i) => _minute = i,
                        flex: 2,
                      ),
                      _wheel(
                        controller: _ampmCtl,
                        count: 2,
                        label: (i) => i == 0 ? 'AM' : 'PM',
                        onChanged: (i) => _ampm = i,
                        flex: 2,
                      ),
                    ],
                  ),
                ),
              ],
            ),
          ),
          const SizedBox(height: 12),
          Padding(
            padding: const EdgeInsets.fromLTRB(24, 4, 24, 24),
            child: GestureDetector(
              onTap: () => Navigator.pop(context, _compose()),
              child: Container(
                width: double.infinity,
                padding: const EdgeInsets.symmetric(vertical: 16),
                decoration: BoxDecoration(
                  color: isDark ? Colors.white : Colors.black,
                  borderRadius: BorderRadius.circular(12),
                ),
                child: Center(
                  child: Text(
                    'CONFIRM',
                    style: GoogleFonts.gelasio(
                      color: isDark ? Colors.black : Colors.white,
                      fontSize: 11,
                      fontWeight: FontWeight.w900,
                      letterSpacing: 2,
                    ),
                  ),
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }
}

class GuestProjectDetailScreen extends ConsumerStatefulWidget {
  final dynamic projectData;
  final String projectId;

  const GuestProjectDetailScreen({
    super.key,
    required this.projectId,
    this.projectData,
  });

  @override
  ConsumerState<GuestProjectDetailScreen> createState() =>
      _GuestProjectDetailScreenState();
}

class _GuestProjectDetailScreenState
    extends ConsumerState<GuestProjectDetailScreen> {
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
  String? _modalErrorMessage;

  @override
  void initState() {
    super.initState();
    // Web parity: the card data passed in already carries the gallery fields,
    // so the EXTERIOR/INTERIOR thumbs show immediately instead of waiting for
    // the (multi-MB) detail payload.
    _seedGalleryImages(widget.projectData);
    _fetchProjectData();
  }

  /// Populates the EXTERIOR/INTERIOR thumb galleries from a project map —
  /// called with the instant card data first, then the full detail payload.
  void _seedGalleryImages(dynamic src) {
    if (src is! Map) return;
    final media = src['media'] as List? ?? [];
    final ext = <String>[
      if (src['exteriorImages'] is List)
        ...(src['exteriorImages'] as List).map((e) => e.toString()),
      ...media
          .where((m) => m['category']?.toString().toUpperCase() == 'EXTERIOR')
          .map((m) => m['url'].toString()),
    ].where((s) => s.trim().isNotEmpty).toSet().toList();
    final inter = <String>[
      if (src['interiorImages'] is List)
        ...(src['interiorImages'] as List).map((e) => e.toString()),
      ...media
          .where((m) => m['category']?.toString().toUpperCase() == 'INTERIOR')
          .map((m) => m['url'].toString()),
    ].where((s) => s.trim().isNotEmpty).toSet().toList();
    if (ext.isNotEmpty) _exteriorImages = ext;
    if (inter.isNotEmpty) _interiorImages = inter;
  }

  void _fetchProjectData() {
    final apiClient = ref.read(apiClientProvider);

    // Each payload renders the moment it arrives: the small
    // updates/inventory/progress responses (KBs, <1s) must not wait behind
    // the project-details call, whose payload can be multiple MB.
    apiClient
        .getProjectDetails(widget.projectId)
        .then((res) {
          if (!mounted) return;
          setState(() {
            if (res.data['status'] == true) {
              _fullProject = res.data['data'];
              // Refresh the galleries from the authoritative detail payload
              // (same extraction the web uses).
              _seedGalleryImages(_fullProject);
            }
            _isLoading = false;
          });
        })
        .catchError((_) {
          if (mounted) setState(() => _isLoading = false);
        });

    apiClient
        .getProjectUpdates(widget.projectId)
        .then((res) {
          if (!mounted || res.data['status'] != true) return;
          setState(() => _updates = res.data['data'] ?? []);
        })
        .catchError((_) {});

    apiClient
        .getProjectInventory(widget.projectId)
        .then((res) {
          if (!mounted || res.data['status'] != true) return;
          setState(() => _inventory = res.data['data'] ?? []);
        })
        .catchError((_) {});

    apiClient
        .getProjectProgress(widget.projectId)
        .then((res) {
          if (!mounted) return;
          final raw = (res.data is Map && res.data['status'] == true)
              ? res.data['data']
              : null;
          final list = raw is List ? List<dynamic>.from(raw) : <dynamic>[];
          // Fallback: projects with no phase records still render the phase
          // section (built from their OWN hero image + overall completion) so
          // the design matches projects that do carry phase data.
          setState(
            () => _progressPhases = list.isNotEmpty
                ? list
                : _guestFallbackPhases(),
          );
        })
        .catchError((_) {
          if (mounted) {
            setState(() => _progressPhases = _guestFallbackPhases());
          }
        });
  }

  List<dynamic> _guestFallbackPhases() {
    final dyn = _fullProject ?? widget.projectData;
    final project = dyn is Map ? dyn : const <String, dynamic>{};
    final heroList = project['heroImages'];
    final hero =
        (heroList is List && heroList.isNotEmpty
            ? heroList.first?.toString()
            : (project['heroImage'] ?? project['coverImage'])?.toString()) ??
        '';
    final imgs = hero.isNotEmpty ? <String>[hero] : const <String>[];
    final rawPct = project['completion'];
    final pct = rawPct is num
        ? rawPct.toInt().clamp(0, 100)
        : (int.tryParse('${rawPct ?? ''}') ?? 0).clamp(0, 100);
    final done = pct >= 100;
    final started = pct > 0;
    return [
      {
        'phaseName': 'Foundation',
        'name': 'Foundation',
        'status': done ? 'Completed' : (started ? 'In Progress' : 'Upcoming'),
        'progressPercent': pct,
        'phaseOrder': 1,
        'images': imgs,
      },
      {
        'phaseName': 'Structure & Handover',
        'name': 'Structure & Handover',
        'status': done ? 'Completed' : 'Upcoming',
        'progressPercent': done ? 100 : 0,
        'phaseOrder': 2,
        'images': imgs,
      },
    ];
  }

  void _launchAction(
    String message, [
    String? url,
    bool isError = false,
  ]) async {
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

      if (resolvedUrl.startsWith('http')) {
        // Open documents (PDF flyers etc.) in the device browser / PDF viewer,
        // which renders PDFs natively — the in-app WebView shows them blank.
        // Fall back to the platform default, then report if both fail.
        for (final mode in const [
          LaunchMode.externalApplication,
          LaunchMode.platformDefault,
        ]) {
          try {
            if (await launchUrl(uri, mode: mode)) return;
          } catch (_) {}
        }
        if (mounted) {
          _launchAction('This document isn\'t available right now', null, true);
        }
        return;
      }

      if (await canLaunchUrl(uri)) {
        await launchUrl(uri, mode: LaunchMode.platformDefault);
        return;
      }
    }

    if (!mounted) return;
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(
          message,
          style: GoogleFonts.ebGaramond(
            fontSize: 12,
            fontWeight: FontWeight.bold,
            color: isError ? Colors.white : Colors.black,
          ),
        ),
        backgroundColor: isError
            ? const Color(0xFFDC2626)
            : const Color(0xFF10B981),
        behavior: SnackBarBehavior.floating,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
      ),
    );
  }

  // Web parity: bespoke wheel picker with separate Day | Month | Year | Hour |
  // Minute | AM/PM columns under a "SELECT DATE & TIME" title (matches the
  // web IOSDateTimePicker), instead of Flutter's combined-date Cupertino sheet.
  Future<DateTime?> _pickIosDateTime(DateTime initial) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final now = DateTime.now();
    if (initial.isBefore(now)) initial = now.add(const Duration(minutes: 30));
    return showModalBottomSheet<DateTime>(
      context: context,
      backgroundColor: Colors.transparent,
      isScrollControlled: true,
      builder: (sheetCtx) =>
          _DateTimeWheelSheet(initial: initial, isDark: isDark),
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

  Future<void> _submitInquiry(
    String type, [
    String? plan,
    StateSetter? setModalState,
  ]) async {
    final name = _nameController.text.trim();
    final phone = _phoneController.text.trim();
    // Format checks (was empty-only): valid name + phone; email only when given.
    final vErr =
        Validators.nameError(name, field: 'name') ??
        Validators.phoneError(phone) ??
        (_emailController.text.trim().isEmpty
            ? null
            : Validators.emailError(_emailController.text));
    if (vErr != null) {
      if (setModalState != null) {
        setModalState(() => _modalErrorMessage = vErr);
      } else {
        _launchAction(vErr, null, true);
      }
      return;
    }
    final isBooking = type == 'VC' || type == 'Site Visit';
    // Web parity: a Video Call / Site Visit requires a scheduled date + time.
    if (isBooking && (_leadDate == null || _leadTime == null)) {
      if (setModalState != null) {
        setModalState(
          () => _modalErrorMessage =
              'Please schedule a date and time for your visit',
        );
      } else {
        _launchAction(
          'Please schedule a date and time for your visit',
          null,
          true,
        );
      }
      return;
    }
    // Reject a past slot (the wheels allow earlier-today selections).
    if (isBooking && _leadDate != null && _leadTime != null) {
      final composed = DateTime(
        _leadDate!.year,
        _leadDate!.month,
        _leadDate!.day,
        _leadTime!.hour,
        _leadTime!.minute,
      );
      if (composed.isBefore(DateTime.now())) {
        if (setModalState != null) {
          setModalState(
            () => _modalErrorMessage = 'Please pick a future date and time',
          );
        } else {
          _launchAction('Please pick a future date and time', null, true);
        }
        return;
      }
    }

    setState(() => _isLoading = true);
    try {
      final apiClient = ref.read(apiClientProvider);
      final project = _fullProject ?? widget.projectData;
      // Server-side enum: Buying | Selling | Site Visit | Video Call
      // (case-sensitive). 'General Enquiry' was rejected with a 400.
      final interest = type == 'VC'
          ? 'Video Call'
          : type == 'Site Visit'
          ? 'Site Visit'
          : 'Buying';

      String? visitDate;
      String? visitTime;
      if (isBooking && _leadDate != null) {
        final d = _leadDate!;
        visitDate =
            '${d.year}-${d.month.toString().padLeft(2, '0')}-${d.day.toString().padLeft(2, '0')}';
        visitTime = _leadTime?.format(context);
      }
      final notes = _notesController.text.trim();

      final res = await apiClient.submitLead({
        'name': name,
        'phone': phone,
        'email': _emailController.text.trim().isNotEmpty
            ? _emailController.text.trim()
            : null,
        'interest': interest,
        'configuration': _selectedConfig,
        if (visitDate != null) 'visitDate': visitDate,
        if (visitTime != null) 'visitTime': visitTime,
        if (notes.isNotEmpty) 'notes': notes,
        'location': _locationController.text.trim().isNotEmpty
            ? _locationController.text.trim()
            : null,
        // Server-side enum: source = online | cp | walk-in | referral | other.
        'source': 'online',
        // Only ever send a real ObjectId — widget.projectId can be a route slug,
        // which makes the API reject the whole lead (CastToObjectId/BSONError).
        if (widget.projectId.length == 24) 'projectId': widget.projectId,
        'project': project?['title'] ?? 'General',
        'message': isBooking
            ? 'Requested $interest for ${project?['title']}'
            : 'Express interest in ${project?['title']}${_locationController.text.trim().isNotEmpty ? ' • Location: ${_locationController.text.trim()}' : ''}',
      });

      if (res.data['status'] == true) {
        // Registration succeeded — clear the form so the fields don't keep the
        // submitted data (the next open starts fresh).
        _nameController.clear();
        _emailController.clear();
        _phoneController.clear();
        _locationController.clear();
        _notesController.clear();
        if (mounted) {
          Navigator.pop(context);
          _launchAction(
            isBooking
                ? 'Booking request received! Our team will call you to confirm the time.'
                : 'Interest registered! Our team will contact you shortly.',
            null,
          );
        }
      } else {
        final err = res.data['message'] ?? 'Failed to submit';
        if (setModalState != null) {
          setModalState(() => _modalErrorMessage = err);
        } else {
          _launchAction(err, null, true);
        }
      }
    } catch (e) {
      const err = 'Connection error. Please try again.';
      if (setModalState != null) {
        setModalState(() => _modalErrorMessage = err);
      } else {
        _launchAction(err, null, true);
      }
    } finally {
      if (mounted) setState(() => _isLoading = false);
    }
  }

  void _startCinematicTour(BuildContext context, dynamic project) {
    showGeneralDialog(
      context: context,
      barrierDismissible: false,
      barrierColor: Colors.black.withOpacity(0.85),
      transitionDuration: const Duration(milliseconds: 400),
      pageBuilder: (ctx, animation, secondaryAnimation) {
        return _CinematicTourOverlay(
          project: project,
          onBookVideoCall: () {
            Navigator.pop(ctx);
            _showRequestDetailsDialog(project, null, 'VC');
          },
          onBookSiteVisit: () {
            Navigator.pop(ctx);
            _showRequestDetailsDialog(project, null, 'Site Visit');
          },
        );
      },
    );
  }

  Future<void> _launchThreeSixty(String url) async {
    final uri = Uri.parse(url);
    if (await canLaunchUrl(uri)) {
      await launchUrl(uri, mode: LaunchMode.externalApplication);
    } else {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            backgroundColor: Color(0xFFE24B4A),
            content: Text('Could not launch virtual tour link'),
          ),
        );
      }
    }
  }

  void _showRequestDetailsDialog(
    dynamic project, [
    dynamic plan,
    String type = 'General',
  ]) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final planName = plan is Map ? plan['name']?.toString() : plan?.toString();
    final projectTitle = project?['title'] ?? 'this project';

    final authUser = ref.read(authProvider).user;
    if (authUser != null) {
      _nameController.text =
          authUser['fullName']?.toString() ??
          authUser['username']?.toString() ??
          '';
      _phoneController.text = authUser['phone']?.toString() ?? '';
      _emailController.text = authUser['email']?.toString() ?? '';
    }
    // Reset booking state for this open (web: leadType/date/time/notes).
    _leadType = type == 'Site Visit' ? 'Site Visit' : 'VC';
    _leadDate = null;
    _leadTime = null;
    _modalErrorMessage = null;
    _notesController.clear();

    showDialog(
      context: context,
      barrierColor: Colors.black.withValues(alpha: 0.6),
      builder: (context) => StatefulBuilder(
        builder: (context, setModalState) => Dialog(
          backgroundColor: isDark ? const Color(0xFF0B111E) : Colors.white,
          // Web parity: a centered floating card with margins on every edge,
          // rounded on all corners — not a full-width bottom sheet.
          insetPadding: const EdgeInsets.symmetric(
            horizontal: 20,
            vertical: 44,
          ),
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(28),
          ),
          clipBehavior: Clip.antiAlias,
          child: ConstrainedBox(
            constraints: BoxConstraints(
              maxHeight: MediaQuery.of(context).size.height * 0.82,
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
                      onPressed: () {
                        if (Navigator.canPop(context)) {
                          Navigator.pop(context);
                        } else {
                          Navigator.pushReplacementNamed(
                            context,
                            '/guest/home',
                          );
                        }
                      },
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
                          _leadType == 'VC'
                              ? 'BOOK A VIDEO CALL'
                              : 'BOOK A SITE VISIT',
                          style: GoogleFonts.gelasio(
                            fontSize: 26,
                            fontWeight: FontWeight.w900,
                            color: isDark ? Colors.white : Colors.black,
                            height: 1.1,
                            letterSpacing: -1,
                          ),
                        ),
                        const SizedBox(height: 16),
                        Text(
                          'A BESPOKE SHOWCASE OF LUXURY AT ${projectTitle.toUpperCase()}.',
                          // Web parity: slate-blue subtitle.
                          style: GoogleFonts.ebGaramond(
                            fontSize: 9,
                            color: isDark ? Colors.white54 : _kBookingBlue,
                            fontWeight: FontWeight.w900,
                            letterSpacing: 1,
                          ),
                        ),
                        const SizedBox(height: 40),

                        _buildInquiryField(
                          'Full Name',
                          _nameController,
                          LucideIcons.user,
                          keyboardType: TextInputType.name,
                          inputFormatters: Validators.nameFormatters,
                        ),
                        const SizedBox(height: 16),
                        _buildInquiryField(
                          'Email Address (Optional)',
                          _emailController,
                          LucideIcons.mail,
                          keyboardType: TextInputType.emailAddress,
                          inputFormatters: Validators.emailFormatters,
                        ),
                        const SizedBox(height: 16),
                        _buildInquiryField(
                          '+91 98653 21250',
                          _phoneController,
                          LucideIcons.phone,
                          keyboardType: TextInputType.phone,
                          inputFormatters: Validators.phoneFormatters,
                        ),

                        const SizedBox(height: 28),
                        // Visit Type toggle (web parity)
                        Text(
                          'VISIT TYPE',
                          style: GoogleFonts.gelasio(
                            fontSize: 8,
                            fontWeight: FontWeight.w900,
                            color: isDark ? Colors.white54 : _kBookingBlue,
                            letterSpacing: 1.5,
                          ),
                        ),
                        const SizedBox(height: 10),
                        Container(
                          padding: const EdgeInsets.all(4),
                          decoration: BoxDecoration(
                            color: isDark
                                ? Colors.white.withValues(alpha: 0.05)
                                : Colors.black.withValues(alpha: 0.04),
                            borderRadius: BorderRadius.circular(12),
                            border: Border.all(
                              color: isDark
                                  ? Colors.white.withValues(alpha: 0.08)
                                  : Colors.black.withValues(alpha: 0.06),
                            ),
                          ),
                          child: Row(
                            children: [
                              for (final opt in const [
                                ['Site Visit', 'Site Visit'],
                                ['Video Call', 'VC'],
                              ])
                                Expanded(
                                  child: GestureDetector(
                                    onTap: () =>
                                        setModalState(() => _leadType = opt[1]),
                                    child: Container(
                                      alignment: Alignment.center,
                                      padding: const EdgeInsets.symmetric(
                                        vertical: 12,
                                      ),
                                      decoration: BoxDecoration(
                                        color: _leadType == opt[1]
                                            ? (isDark
                                                  ? Colors.white
                                                  : Colors.black)
                                            : Colors.transparent,
                                        borderRadius: BorderRadius.circular(9),
                                      ),
                                      child: Text(
                                        opt[0].toUpperCase(),
                                        style: GoogleFonts.ebGaramond(
                                          fontSize: 9,
                                          fontWeight: FontWeight.w900,
                                          letterSpacing: 1,
                                          color: _leadType == opt[1]
                                              ? (isDark
                                                    ? Colors.black
                                                    : Colors.white)
                                              : (isDark
                                                    ? Colors.white54
                                                    : Colors.black54),
                                        ),
                                      ),
                                    ),
                                  ),
                                ),
                            ],
                          ),
                        ),
                        const SizedBox(height: 20),
                        // Schedule date + time (web parity: IOSDateTimePicker)
                        Text(
                          'SCHEDULE',
                          style: GoogleFonts.gelasio(
                            fontSize: 8,
                            fontWeight: FontWeight.w900,
                            color: isDark ? Colors.white54 : _kBookingBlue,
                            letterSpacing: 1.5,
                          ),
                        ),
                        const SizedBox(height: 10),
                        GestureDetector(
                          onTap: () async {
                            final initial = _leadDate != null
                                ? DateTime(
                                    _leadDate!.year,
                                    _leadDate!.month,
                                    _leadDate!.day,
                                    _leadTime?.hour ?? 10,
                                    _leadTime?.minute ?? 0,
                                  )
                                : DateTime.now().add(const Duration(hours: 1));
                            final dt = await _pickIosDateTime(initial);
                            if (dt != null) {
                              setModalState(() {
                                _leadDate = DateTime(dt.year, dt.month, dt.day);
                                _leadTime = TimeOfDay(
                                  hour: dt.hour,
                                  minute: dt.minute,
                                );
                              });
                            }
                          },
                          child: Container(
                            padding: const EdgeInsets.symmetric(
                              horizontal: 18,
                              vertical: 16,
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
                                // Web parity: blue calendar icon + blue label.
                                Icon(
                                  LucideIcons.calendar,
                                  size: 16,
                                  color: isDark ? Colors.white : _kBookingBlue,
                                ),
                                const SizedBox(width: 12),
                                Expanded(
                                  child: Text(
                                    _leadDate == null
                                        ? 'SELECT DATE & TIME'
                                        : '${_leadDate!.day}/${_leadDate!.month}/${_leadDate!.year}   ${_leadTime?.format(context) ?? ''}',
                                    style: GoogleFonts.ebGaramond(
                                      fontSize: 11,
                                      fontWeight: FontWeight.w800,
                                      color: isDark
                                          ? Colors.white
                                          : _kBookingBlue,
                                      letterSpacing: 0.5,
                                    ),
                                  ),
                                ),
                                Icon(
                                  LucideIcons.chevronRight,
                                  size: 16,
                                  color: isDark
                                      ? Colors.white38
                                      : _kBookingBlue.withValues(alpha: 0.6),
                                ),
                              ],
                            ),
                          ),
                        ),
                        const SizedBox(height: 20),
                        // Additional notes (web parity)
                        Text(
                          'ADDITIONAL NOTES',
                          style: GoogleFonts.gelasio(
                            fontSize: 8,
                            fontWeight: FontWeight.w900,
                            color: isDark ? Colors.white54 : _kBookingBlue,
                            letterSpacing: 1.5,
                          ),
                        ),
                        const SizedBox(height: 10),
                        Container(
                          padding: const EdgeInsets.symmetric(
                            horizontal: 18,
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
                            style: GoogleFonts.ebGaramond(
                              fontSize: 15,
                              fontWeight: FontWeight.bold,
                              color: isDark ? Colors.white : Colors.black,
                            ),
                            decoration: InputDecoration(
                              border: InputBorder.none,
                              hintText:
                                  'SPECIFIC REQUIREMENTS, PICKUP DETAILS, ETC...',
                              hintStyle: GoogleFonts.ebGaramond(
                                fontSize: 9,
                                fontWeight: FontWeight.w800,
                                color: isDark ? Colors.white24 : Colors.black26,
                                letterSpacing: 0.5,
                              ),
                            ),
                          ),
                        ),

                        const SizedBox(height: 40),
                        if (_modalErrorMessage != null) ...[
                          Container(
                            width: double.infinity,
                            padding: const EdgeInsets.symmetric(
                              horizontal: 16,
                              vertical: 12,
                            ),
                            decoration: BoxDecoration(
                              color: const Color(0xFFDC2626),
                              borderRadius: BorderRadius.circular(12),
                            ),
                            child: Text(
                              _modalErrorMessage!,
                              style: GoogleFonts.ebGaramond(
                                color: Colors.white,
                                fontSize: 11,
                                fontWeight: FontWeight.bold,
                              ),
                              textAlign: TextAlign.center,
                            ),
                          ),
                          const SizedBox(height: 16),
                        ],
                        _ScaleButton(
                          onTap: () {
                            final name = _nameController.text.trim();
                            final phone = _phoneController.text.trim();
                            // Valid name + phone (email only when provided).
                            final vErr =
                                Validators.nameError(name, field: 'name') ??
                                Validators.phoneError(phone) ??
                                (_emailController.text.trim().isEmpty
                                    ? null
                                    : Validators.emailError(
                                        _emailController.text,
                                      ));
                            if (vErr != null) {
                              setModalState(() => _modalErrorMessage = vErr);
                              return;
                            }
                            if (_leadDate == null || _leadTime == null) {
                              setModalState(
                                () => _modalErrorMessage =
                                    'Please schedule a date and time for your visit',
                              );
                              return;
                            }
                            // The free-scrolling wheels allow earlier-today
                            // selections; reject a past slot at submit.
                            final composed = DateTime(
                              _leadDate!.year,
                              _leadDate!.month,
                              _leadDate!.day,
                              _leadTime!.hour,
                              _leadTime!.minute,
                            );
                            if (composed.isBefore(DateTime.now())) {
                              setModalState(
                                () => _modalErrorMessage =
                                    'Please pick a future date and time',
                              );
                              return;
                            }
                            setModalState(() => _modalErrorMessage = null);
                            _submitInquiry(_leadType, planName, setModalState);
                          },
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
                                style: GoogleFonts.gelasio(
                                  color: isDark ? Colors.black : Colors.white,
                                  fontSize: 11,
                                  fontWeight: FontWeight.w900,
                                  letterSpacing: 1.5,
                                ),
                              ),
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
        ),
      ),
    );
  }

  Widget _buildInquiryField(
    String label,
    TextEditingController controller,
    IconData icon, {
    TextInputType? keyboardType,
    List<TextInputFormatter>? inputFormatters,
  }) {
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
        keyboardType: keyboardType,
        inputFormatters: inputFormatters,
        style: GoogleFonts.ebGaramond(
          fontSize: 15,
          fontWeight: FontWeight.bold,
          color: isDark ? Colors.white : Colors.black,
        ),
        decoration: InputDecoration(
          border: InputBorder.none,
          hintText: label,
          // Web parity: clearly-legible slate-blue placeholder text.
          hintStyle: GoogleFonts.ebGaramond(
            fontSize: 12,
            fontWeight: FontWeight.w500,
            color: isDark ? Colors.white54 : _kBookingBlue,
          ),
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
                  final raw = urls[index];
                  return Center(
                    child: InteractiveViewer(
                      // `asset:` entries render bundled images (used while the
                      // backend /uploads endpoint is broken).
                      child: raw.startsWith('asset:')
                          ? Image.asset(
                              raw.substring(6),
                              fit: BoxFit.contain,
                              filterQuality: FilterQuality.high,
                            )
                          : CachedNetworkImage(
                              imageUrl: apiClient.resolveUrl(raw),
                              fit: BoxFit.contain,
                              placeholder: (context, url) => const Center(
                                child: CircularProgressIndicator(
                                  color: Colors.white24,
                                ),
                              ),
                              errorWidget: (context, url, error) => const Icon(
                                LucideIcons.image,
                                color: Colors.white24,
                                size: 50,
                              ),
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
                      onPressed: () => pageController.previousPage(
                        duration: const Duration(milliseconds: 300),
                        curve: Curves.easeInOut,
                      ),
                      icon: Icon(
                        LucideIcons.chevronLeft,
                        color: Colors.white.withValues(alpha: 0.4),
                        size: 20,
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
                      onPressed: () => pageController.nextPage(
                        duration: const Duration(milliseconds: 300),
                        curve: Curves.easeInOut,
                      ),
                      icon: Icon(
                        LucideIcons.chevronRight,
                        color: Colors.white.withValues(alpha: 0.4),
                        size: 20,
                      ),
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
                      padding: const EdgeInsets.symmetric(
                        horizontal: 16,
                        vertical: 8,
                      ),
                      decoration: BoxDecoration(
                        color: Colors.black.withValues(alpha: 0.5),
                        borderRadius: BorderRadius.circular(20),
                      ),
                      child: ListenableBuilder(
                        listenable: pageController,
                        builder: (context, child) {
                          final page =
                              (pageController.hasClients
                                  ? (pageController.page?.round() ?? 0)
                                  : 0) +
                              1;
                          return Text(
                            '$page / ${urls.length}',
                            style: GoogleFonts.ebGaramond(
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
                // Quick-access row: Exterior, Interior (Web parity: no VR or Cinematic shown on guest portal)
                Builder(
                  builder: (context) {
                    final hasExterior = _exteriorImages.isNotEmpty;
                    final hasInterior = _interiorImages.isNotEmpty;

                    if (!hasExterior && !hasInterior) {
                      return const SizedBox.shrink();
                    }

                    return Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Padding(
                          padding: const EdgeInsets.symmetric(horizontal: 24),
                          child: Wrap(
                            spacing: 12,
                            runSpacing: 12,
                            crossAxisAlignment: WrapCrossAlignment.center,
                            children: [
                              // The /uploads endpoint is currently broken
                              // server-side (302 self-redirect loop). Fallback
                              // chain per thumb: live URL → bundled Cledor
                              // photo (temporary, until the backend is fixed)
                              // → project hero image.
                              if (hasExterior)
                                _HeroMediaThumb(
                                  label: 'EXTERIOR',
                                  imageUrl: apiClient.resolveUrl(
                                    _exteriorImages.first,
                                  ),
                                  fallback: _thumbFallback(
                                    project,
                                    'assets/cledor_exterior.jpg',
                                  ),
                                  // Bundled photo first so the gallery always
                                  // opens with a working full image while
                                  // /uploads is broken server-side.
                                  onTap: () => _openHeroGallery([
                                    if ((project?['title'] ?? '')
                                        .toString()
                                        .toLowerCase()
                                        .contains('cledor'))
                                      'asset:assets/cledor_exterior.jpg',
                                    ..._exteriorImages,
                                  ]),
                                ),
                              if (hasInterior)
                                _HeroMediaThumb(
                                  label: 'INTERIOR',
                                  imageUrl: apiClient.resolveUrl(
                                    _interiorImages.first,
                                  ),
                                  fallback: _thumbFallback(
                                    project,
                                    'assets/cledor_interior.jpg',
                                  ),
                                  onTap: () => _openHeroGallery([
                                    if ((project?['title'] ?? '')
                                        .toString()
                                        .toLowerCase()
                                        .contains('cledor'))
                                      'asset:assets/cledor_interior.jpg',
                                    ..._interiorImages,
                                  ]),
                                ),
                            ],
                          ),
                        ),
                        const SizedBox(height: 24),
                      ],
                    );
                  },
                ),
                // Title + Location — web parity (below the hero, on the content bg)
                Padding(
                  padding: const EdgeInsets.symmetric(horizontal: 24),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        (project?['title']?.toString() ?? 'Project Name')
                            .toUpperCase(),
                        // Web parity: heavy sans title, not serif.
                        style: GoogleFonts.gelasio(
                          color: isDark
                              ? Colors.white
                              : const Color(0xFF09090B),
                          fontSize: 24,
                          height: 1.0,
                          fontWeight: FontWeight.w800,
                          letterSpacing: 0.5,
                        ),
                      ),
                      const SizedBox(height: 12),
                      Container(
                        padding: const EdgeInsets.symmetric(
                          horizontal: 12,
                          vertical: 8,
                        ),
                        decoration: BoxDecoration(
                          color: isDark
                              ? Colors.white.withValues(alpha: 0.05)
                              : Colors.black.withValues(alpha: 0.03),
                          borderRadius: BorderRadius.circular(12),
                          border: Border.all(
                            color: isDark
                                ? Colors.white.withValues(alpha: 0.08)
                                : Colors.black.withValues(alpha: 0.08),
                          ),
                        ),
                        child: Row(
                          mainAxisSize: MainAxisSize.min,
                          children: [
                            Icon(
                              LucideIcons.mapPin,
                              color: isDark ? Colors.white70 : Colors.black87,
                              size: 14,
                            ),
                            const SizedBox(width: 6),
                            Text(
                              (project?['locationName'] ??
                                      (project?['location'] is Map
                                          ? project?['location']?['name']
                                          : project?['location']) ??
                                      'Mazgaon')
                                  .toString(),
                              style: GoogleFonts.ebGaramond(
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

  /// Thumb fallback while the backend's /uploads endpoint is broken: for the
  /// Cledor project, prefer the bundled gallery photos (dropped into assets/);
  /// for anything else — or if the asset file isn't present — use the
  /// project's hero image.
  Widget _thumbFallback(dynamic project, String assetPath) {
    final hero = _heroImage(_resolveHeroUrl(project));
    final isCledor = (project?['title'] ?? '')
        .toString()
        .toLowerCase()
        .contains('cledor');
    if (!isCledor) return hero;
    return Image.asset(
      assetPath,
      fit: BoxFit.cover,
      filterQuality: FilterQuality.high,
      errorBuilder: (_, __, ___) => hero,
    );
  }

  String _resolveHeroUrl(dynamic project) => ref
      .read(apiClientProvider)
      .resolveUrl(project?['heroImage'] ?? project?['coverImage']);

  /// Hero image that also understands inline base64 `data:` URIs (e.g.
  /// Cledor's heroImage) — CachedNetworkImage can only fetch network URLs.
  Widget _heroImage(String src) {
    Widget errorBox() => Container(
      color: const Color(0xFF1A1A1A),
      child: const Center(
        child: Icon(LucideIcons.building2, color: Colors.white24, size: 40),
      ),
    );
    if (src.startsWith('data:')) {
      try {
        final bytes = _detailB64Cache.putIfAbsent(
          src,
          () => base64Decode(
            src.substring(src.indexOf(',') + 1).replaceAll(RegExp(r'\s'), ''),
          ),
        );
        return Image.memory(
          bytes,
          fit: BoxFit.cover,
          gaplessPlayback: true,
          // Downsample the multi-MB originals to keep decode cost in check.
          cacheWidth: 1080,
          errorBuilder: (_, __, ___) => errorBox(),
        );
      } catch (_) {
        return errorBox();
      }
    }
    return CachedNetworkImage(
      imageUrl: src,
      fit: BoxFit.cover,
      // Decode near display size and skip the default 500ms fade.
      memCacheWidth: 900,
      fadeInDuration: Duration.zero,
      placeholder: (context, url) => Container(color: Colors.black12),
      errorWidget: (context, url, error) => errorBox(),
    );
  }

  Widget _buildHero(dynamic project, bool isDark) {
    final apiClient = ref.read(apiClientProvider);
    final heroUrl = apiClient.resolveUrl(
      project?['heroImage'] ?? project?['coverImage'],
    );

    return AspectRatio(
      aspectRatio: 16 / 9,
      child: Stack(
        fit: StackFit.expand,
        children: [
          _heroImage(heroUrl),
          Container(
            decoration: BoxDecoration(
              gradient: LinearGradient(
                begin: Alignment.topCenter,
                end: Alignment.bottomCenter,
                // Web parity: crisp image with only a light scrim at the top
                // for the header actions — no white fade at the bottom.
                colors: [
                  Colors.black.withValues(alpha: 0.18),
                  Colors.transparent,
                ],
                stops: const [0.0, 0.35],
              ),
            ),
          ),
          // Web parity: hero shows ONLY the status badge (bottom-left).
          Positioned(
            bottom: 24,
            left: 24,
            child: Container(
              padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 5),
              decoration: BoxDecoration(
                color: Colors.black,
                borderRadius: BorderRadius.circular(4),
              ),
              child: Text(
                (project?['status']?.toString().toUpperCase() ?? 'ONGOING'),
                style: GoogleFonts.gelasio(
                  color: Colors.white,
                  fontSize: 8,
                  fontWeight: FontWeight.w900,
                  letterSpacing: 1.5,
                ),
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
                  },
                ),
                Row(
                  children: [
                    _SquareAction(
                      icon: LucideIcons.share2,
                      onTap: () => Share.share(
                        'Check out ${project?['title']} on M4 Family!',
                      ),
                    ),
                    const SizedBox(width: 8),
                    _SquareAction(
                      icon: LucideIcons.menu,
                      onTap: () => _scaffoldKey.currentState?.openDrawer(),
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
            style: GoogleFonts.ebGaramond(
              fontSize: 11,
              color: isDark
                  ? Colors.white.withValues(alpha: 0.78)
                  : Colors.black.withValues(alpha: 0.78),
              fontWeight: FontWeight.w600,
              height: 1.6,
              letterSpacing: 0.5,
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
        Container(
          width: 40,
          height: 1.5,
          color: isDark ? Colors.white : Colors.black,
        ),
        const SizedBox(width: 16),
        Text(
          title.toUpperCase(),
          style: GoogleFonts.gelasio(
            fontSize: 12,
            fontWeight: FontWeight.w900,
            color: isDark ? Colors.white : Colors.black,
            letterSpacing: 4,
          ),
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
                ? (_progressPhases.fold<num>(
                            0,
                            (a, p) =>
                                a +
                                ((p['progressPercent'] ?? p['progress'] ?? 0)
                                    as num),
                          ) /
                          _progressPhases.length)
                      .round()
                : (project?['completion'] ?? 0),
            // Web parity: the API returns "" (empty, not null) here — fall
            // back to the same default the web displays.
            estimatedCompletion: () {
              for (final v in [
                project?['estimatedCompletionDate'],
                project?['possessionDate'],
              ]) {
                final s = (v ?? '').toString().trim();
                if (s.isNotEmpty) return s.toUpperCase();
              }
              return 'Q1 2029';
            }(),
            phases: _progressPhases,
            showFullProgress: _showFullProgress,
            onToggleReadMore: () =>
                setState(() => _showFullProgress = !_showFullProgress),
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
    if (amenitiesRaw.isEmpty)
      return const _EmptyTabContent(message: 'Coming soon');
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final apiClient = ref.read(apiClientProvider);

    return GridView.builder(
      shrinkWrap: true,
      physics: const NeverScrollableScrollPhysics(),
      padding: EdgeInsets.zero,
      gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
        crossAxisCount: 3,
        // Tighter row/column gaps so amenity icons sit closer together.
        mainAxisSpacing: 4,
        crossAxisSpacing: 4,
        childAspectRatio: 1.15,
      ),
      itemCount: amenitiesRaw.length,
      itemBuilder: (context, index) {
        final amenity = amenitiesRaw[index];
        final name =
            (amenity is Map
                    ? (amenity['name']?.toString() ?? 'Amenity')
                    : amenity.toString())
                .toUpperCase();
        final rawIcon = amenity is Map ? amenity['icon']?.toString() : null;
        final hasUploadedIcon =
            rawIcon != null &&
            rawIcon.isNotEmpty &&
            (rawIcon.startsWith('/') ||
                rawIcon.startsWith('http') ||
                rawIcon.contains('.'));

        // Web parity: full LuxuryAmenityIcon (uploaded icon -> name-mapped SVG -> Lucide).
        return Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            LuxuryAmenityIcon(
              name: name,
              iconUrl: hasUploadedIcon ? apiClient.resolveUrl(rawIcon) : null,
              size: 42,
              // Temporary: the backend /uploads endpoint is broken (302 loop);
              // bundled snapshot of the web's Lobby icon keeps parity.
              fallbackAsset: name == 'LOBBY'
                  ? 'assets/amenity_lobby.png'
                  : null,
            ),
            const SizedBox(height: 10),
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 4),
              child: Text(
                name,
                textAlign: TextAlign.center,
                maxLines: 2,
                overflow: TextOverflow.ellipsis,
                style: GoogleFonts.ebGaramond(
                  fontSize: 8.5,
                  fontWeight: FontWeight.w600,
                  color: isDark
                      ? Colors.white.withValues(alpha: 0.8)
                      : Colors.black.withValues(alpha: 0.8),
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
            BoxShadow(
              color: Colors.black.withValues(alpha: 0.1),
              blurRadius: 20,
              offset: const Offset(0, 10),
            ),
          ],
        ),
        child: Row(
          children: [
            const SizedBox(width: 20),
            _BottomIconAction(
              icon: LucideIcons.phone,
              onTap: () => SupportHandlers.launchCall(
                project?['phone'] ?? project?['contactPhone'],
              ),
            ),
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
                      style: GoogleFonts.gelasio(
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
    if (n.contains('playground') || n.contains('kids'))
      return LucideIcons.toyBrick;
    if (n.contains('clubhouse')) return LucideIcons.building2;
    if (n.contains('security')) return LucideIcons.shieldCheck;
    if (n.contains('parking')) return LucideIcons.car;
    if (n.contains('sunroof')) return LucideIcons.umbrella;
    return LucideIcons.sparkles;
  }

  Widget _buildLocation(dynamic project) {
    final rawLoc =
        (project?['location'] is Map
                ? project?['location']?['name']
                : project?['location'])
            ?.toString() ??
        '';
    const defaultLoc =
        'NA 604, 6th Floor, M4 Aura Heights, Grant Road, Mumbai - 400007';
    final invalid =
        rawLoc.trim().isEmpty ||
        ['NA', 'N/A', 'NONE'].contains(rawLoc.trim().toUpperCase());
    final loc = invalid ? defaultLoc : rawLoc;

    // Web parity: embedded Google Map (iframe -> WebView) + View on Maps button.
    return _LocationMap(
      location: loc,
      onOpenMaps: () => _launchAction(
        'Opening Maps...',
        'https://www.google.com/maps?q=${Uri.encodeComponent(loc)}',
      ),
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
              border: Border.all(
                color: isDark
                    ? Colors.white.withValues(alpha: 0.05)
                    : Colors.black.withValues(alpha: 0.05),
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
                // Web parity: black heading, not gold.
                Text(
                  'INITIALIZE YOUR PREMIUM EXPERIENCE',
                  style: GoogleFonts.gelasio(
                    fontSize: 9,
                    fontWeight: FontWeight.w900,
                    color: isDark ? Colors.white : Colors.black,
                    letterSpacing: 1.5,
                  ),
                ),
                const SizedBox(height: 24),
                _InterestInput(
                  hint: 'FULL NAME *',
                  controller: _nameController,
                  keyboardType: TextInputType.name,
                  inputFormatters: Validators.nameFormatters,
                ),
                const SizedBox(height: 16),
                _InterestInput(
                  hint: 'EMAIL ADDRESS',
                  controller: _emailController,
                  keyboardType: TextInputType.emailAddress,
                  inputFormatters: Validators.emailFormatters,
                ),
                const SizedBox(height: 16),
                _InterestInput(
                  hint: '+91 98653 21250 *',
                  controller: _phoneController,
                  keyboardType: TextInputType.phone,
                  inputFormatters: Validators.phoneFormatters,
                ),
                const SizedBox(height: 16),
                _InterestInput(
                  hint: 'YOUR LOCATION (E.G. DUBAI, UAE)',
                  controller: _locationController,
                ),
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
                    child: Center(
                      child: Text(
                        'REGISTER INTEREST',
                        style: GoogleFonts.gelasio(
                          color: isDark ? Colors.black : Colors.white,
                          fontSize: 10,
                          fontWeight: FontWeight.w900,
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
          ..._paymentPlans
              .map(
                (plan) => Container(
                  margin: const EdgeInsets.only(bottom: 16),
                  padding: const EdgeInsets.all(24),
                  decoration: BoxDecoration(
                    color: isDark
                        ? Colors.white.withValues(alpha: 0.03)
                        : const Color(0xFFF1F5F9),
                    borderRadius: BorderRadius.circular(32),
                    border: Border.all(
                      color: isDark
                          ? Colors.white.withValues(alpha: 0.05)
                          : Colors.black.withValues(alpha: 0.05),
                    ),
                  ),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Row(
                        mainAxisAlignment: MainAxisAlignment.spaceBetween,
                        children: [
                          Text(
                            plan['name']?.toString().toUpperCase() ??
                                'STANDARD PLAN',
                            style: GoogleFonts.ebGaramond(
                              fontSize: 11,
                              fontWeight: FontWeight.w900,
                              color: isDark ? Colors.white : Colors.black,
                              letterSpacing: 0.5,
                            ),
                          ),
                          const Icon(
                            LucideIcons.wallet,
                            color: M4Theme.premiumBlue,
                            size: 16,
                          ),
                        ],
                      ),
                      const SizedBox(height: 24),
                      ...(plan['items'] as List? ?? [])
                          .map(
                            (item) => Padding(
                              padding: const EdgeInsets.only(bottom: 12),
                              child: Row(
                                children: [
                                  Container(
                                    width: 40,
                                    height: 40,
                                    decoration: BoxDecoration(
                                      color: M4Theme.premiumBlue.withValues(
                                        alpha: 0.1,
                                      ),
                                      shape: BoxShape.circle,
                                    ),
                                    child: Center(
                                      child: Text(
                                        '${item['percentage']}%',
                                        style: GoogleFonts.ebGaramond(
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
                                      crossAxisAlignment:
                                          CrossAxisAlignment.start,
                                      children: [
                                        Text(
                                          item['description']
                                                  ?.toString()
                                                  .toUpperCase() ??
                                              'INSTALLMENT',
                                          style: GoogleFonts.ebGaramond(
                                            fontSize: 9,
                                            fontWeight: FontWeight.w900,
                                            color: isDark
                                                ? Colors.white
                                                : Colors.black,
                                            letterSpacing: 0.5,
                                          ),
                                        ),
                                        Text(
                                          'INSTALLMENT ${item['installmentNumber'] ?? ''}',
                                          style: GoogleFonts.ebGaramond(
                                            fontSize: 8,
                                            color: isDark
                                                ? Colors.white38
                                                : Colors.black38,
                                            fontWeight: FontWeight.bold,
                                          ),
                                        ),
                                      ],
                                    ),
                                  ),
                                ],
                              ),
                            ),
                          )
                          .toList(),
                    ],
                  ),
                ),
              )
              .toList(),
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
  final TextInputType? keyboardType;
  final List<TextInputFormatter>? inputFormatters;
  const _InterestInput({
    required this.hint,
    this.icon,
    required this.controller,
    this.keyboardType,
    this.inputFormatters,
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
        keyboardType: keyboardType,
        inputFormatters: inputFormatters,
        style: GoogleFonts.ebGaramond(
          fontSize: 15,
          fontWeight: FontWeight.bold,
          color: isDark ? Colors.white : Colors.black,
        ),
        decoration: InputDecoration(
          border: InputBorder.none,
          hintText: hint,
          hintStyle: GoogleFonts.ebGaramond(
            fontSize: 12,
            fontWeight: FontWeight.w900,
            color: isDark ? Colors.white38 : Colors.black45,
            letterSpacing: 1,
          ),
          icon: icon != null
              ? Icon(icon, size: 14, color: M4Theme.premiumBlue)
              : null,
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
          color: isDark ? Colors.white.withValues(alpha: 0.05) : Colors.white,
          borderRadius: BorderRadius.circular(32),
          border: Border.all(
            color: isDark
                ? Colors.white.withValues(alpha: 0.08)
                : Colors.black.withValues(alpha: 0.05),
            width: 1,
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
                  style: GoogleFonts.gelasio(
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
                  style: GoogleFonts.ebGaramond(
                    color: isDark ? Colors.white : Colors.black,
                    fontSize: 13,
                    fontWeight: FontWeight.w700,
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
          color: isDark
              ? Colors.white.withValues(alpha: 0.05)
              : const Color(0xFFF4F4F5),
          borderRadius: BorderRadius.circular(20),
          border: Border.all(
            color: isDark
                ? Colors.white.withValues(alpha: 0.1)
                : Colors.black.withValues(alpha: 0.05),
          ),
        ),
        child: Center(
          child: Icon(
            icon,
            color: isDark ? Colors.white : Colors.black,
            size: 20,
          ),
        ),
      ),
    );
  }
}

class _HeroMediaThumb extends StatelessWidget {
  final String label;
  final String? imageUrl;
  final Widget? fallback;
  final bool isVR;
  final bool isCinematic;
  final VoidCallback onTap;

  const _HeroMediaThumb({
    required this.label,
    this.imageUrl,
    this.fallback,
    this.isVR = false,
    this.isCinematic = false,
    required this.onTap,
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
            width: 66,
            height: 66,
            decoration: BoxDecoration(
              color: Colors.black.withValues(alpha: 0.2),
              borderRadius: BorderRadius.circular(16),
              border: Border.all(
                color: Colors.white.withValues(alpha: 0.35),
                width: 1.5,
              ),
            ),
            clipBehavior: Clip.antiAlias,
            child: Stack(
              fit: StackFit.expand,
              children: [
                if (isVR || isCinematic)
                  Container(
                    color: Colors.black.withValues(alpha: 0.4),
                    child: Center(
                      child: Column(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          Icon(
                            isVR
                                ? LucideIcons.refreshCw
                                : LucideIcons.playCircle,
                            color: Colors.white,
                            size: 16,
                          ),
                          const SizedBox(height: 2),
                          Text(
                            label,
                            textAlign: TextAlign.center,
                            style: GoogleFonts.ebGaramond(
                              color: Colors.white,
                              fontSize: 6,
                              fontWeight: FontWeight.w900,
                              letterSpacing: 0.5,
                            ),
                          ),
                        ],
                      ),
                    ),
                  )
                else ...[
                  if (imageUrl != null)
                    CachedNetworkImage(
                      imageUrl: imageUrl!,
                      fit: BoxFit.cover,
                      filterQuality: FilterQuality.high,
                      memCacheWidth: 1080,
                      fadeInDuration: Duration.zero,
                      errorWidget: (c, e, s) =>
                          fallback ?? Container(color: Colors.white10),
                      placeholder: (c, e) => Container(color: Colors.white10),
                    ),
                  // Web parity: image stays fully visible; the label sits on a
                  // high-contrast scrim along the bottom edge.
                  Align(
                    alignment: Alignment.bottomCenter,
                    child: Container(
                      width: double.infinity,
                      padding: const EdgeInsets.symmetric(vertical: 3.5),
                      color: Colors.black.withValues(alpha: 0.62),
                      child: Text(
                        label,
                        textAlign: TextAlign.center,
                        style: GoogleFonts.ebGaramond(
                          color: Colors.white,
                          fontSize: 7,
                          fontWeight: FontWeight.w800,
                          letterSpacing: 0.5,
                        ),
                      ),
                    ),
                  ),
                ],
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
    return Text(
      title.toUpperCase(),
      style: GoogleFonts.gelasio(
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
    final isDark = Theme.of(context).brightness == Brightness.dark;
    return Center(
      child: Text(
        message.toUpperCase(),
        textAlign: TextAlign.center,
        style: GoogleFonts.ebGaramond(
          fontSize: 12,
          color: isDark ? Colors.white38 : Colors.black38,
        ),
      ),
    );
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
            border: Border.all(
              color: isDark
                  ? Colors.white.withValues(alpha: 0.08)
                  : Colors.black.withValues(alpha: 0.05),
            ),
            boxShadow: isDark
                ? []
                : [
                    BoxShadow(
                      color: Colors.black.withValues(alpha: 0.05),
                      blurRadius: 30,
                      offset: const Offset(0, 10),
                    ),
                  ],
          ),
          child: Row(
            children: [
              Container(
                padding: const EdgeInsets.all(14),
                decoration: BoxDecoration(
                  color: isDark
                      ? Colors.white.withValues(alpha: 0.05)
                      : Colors.black.withValues(alpha: 0.04),
                  borderRadius: BorderRadius.circular(16),
                ),
                child: Icon(
                  icon,
                  color: isDark
                      ? Colors.white70
                      : Colors.black.withValues(alpha: 0.7),
                  size: 20,
                ),
              ),
              const SizedBox(width: 16),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      title.toUpperCase(),
                      style: GoogleFonts.ebGaramond(
                        fontSize: 11,
                        fontWeight: FontWeight.w900,
                        color: isDark ? Colors.white : Colors.black,
                        letterSpacing: 0.5,
                      ),
                    ),
                    const SizedBox(height: 4),
                    Text(
                      subtitle.replaceFirst('•', ' • ').toUpperCase(),
                      style: GoogleFonts.ebGaramond(
                        fontSize: 8,
                        color: isDark ? Colors.white38 : Colors.black38,
                        fontWeight: FontWeight.w900,
                        letterSpacing: 1,
                      ),
                    ),
                  ],
                ),
              ),
              const SizedBox(width: 8),
              _AssetButton(label: 'VIEW', isOutline: true, onTap: onView),
              if (onDownload != null) ...[
                const SizedBox(width: 8),
                _AssetButton(
                  label: 'DOWNLOAD',
                  isOutline: false,
                  onTap: onDownload!,
                ),
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
  const _AssetButton({
    required this.label,
    required this.isOutline,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    return _ScaleButton(
      onTap: onTap,
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
        decoration: BoxDecoration(
          color: isOutline
              ? (isDark ? Colors.white : Colors.black)
              : (isDark ? Colors.white : Colors.black),
          borderRadius: BorderRadius.circular(10),
        ),
        child: Text(
          label,
          style: GoogleFonts.ebGaramond(
            fontSize: 7.5,
            fontWeight: FontWeight.w900,
            color: isDark ? Colors.black : Colors.white,
            letterSpacing: 1.0,
          ),
        ),
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
      // Investor-parity construction box (master design): subtle translucent
      // fill, radius 40, hairline border, no shadow.
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 36),
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
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    // Web parity: muted dark label + heavy black sans date.
                    Text(
                      'ESTIMATED COMPLETION DATE',
                      style: GoogleFonts.ebGaramond(
                        fontSize: 9,
                        fontWeight: FontWeight.w900,
                        color: isDark ? Colors.white60 : Colors.black54,
                        letterSpacing: 1,
                      ),
                    ),
                    const SizedBox(height: 12),
                    Text(
                      estimatedCompletion,
                      style: GoogleFonts.gelasio(
                        fontSize: 44,
                        fontWeight: FontWeight.w900,
                        color: isDark ? Colors.white : Colors.black,
                        height: 1.02,
                      ),
                    ),
                    const SizedBox(height: 24),
                    Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          'As the project progresses, significant milestones are reached, showcasing our team\'s dedication and expertise. We are steadily moving closer to our completion goal, ensuring quality and safety at every step. Each phase is handled with precision to meet our luxury standards and timeline.',
                          maxLines: showFullProgress ? null : 3,
                          overflow: showFullProgress
                              ? TextOverflow.visible
                              : TextOverflow.ellipsis,
                          style: GoogleFonts.ebGaramond(
                            fontSize: 11,
                            color: isDark ? Colors.white54 : Colors.black54,
                            height: 1.6,
                            fontWeight: FontWeight.w500,
                          ),
                        ),
                        const SizedBox(height: 10),
                        GestureDetector(
                          onTap: onToggleReadMore,
                          child: Text(
                            showFullProgress ? 'Show less' : 'Read more',
                            style: GoogleFonts.ebGaramond(
                              fontSize: 11,
                              fontWeight: FontWeight.w900,
                              color: isDark ? Colors.white : Colors.black,
                            ),
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
                        // Web parity: bold black tick ring.
                        color: isDark ? Colors.white : Colors.black,
                        backgroundColor: isDark
                            ? Colors.white.withValues(alpha: 0.1)
                            : Colors.black.withValues(alpha: 0.1),
                        strokeWidth: 6,
                      ),
                    ),
                  ),
                  Column(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Text(
                        '${overallProgress.toInt()}%',
                        style: GoogleFonts.gelasio(
                          fontSize: 22,
                          fontWeight: FontWeight.w900,
                          color: isDark ? Colors.white : Colors.black,
                        ),
                      ),
                      Text(
                        'OVERALL',
                        style: GoogleFonts.ebGaramond(
                          fontSize: 8,
                          fontWeight: FontWeight.w900,
                          color: isDark ? Colors.white38 : Colors.black38,
                          letterSpacing: 1,
                        ),
                      ),
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
                Text(
                  '2026',
                  style: GoogleFonts.gelasio(
                    fontSize: 18,
                    fontWeight: FontWeight.w900,
                    color: isDark ? Colors.white : Colors.black,
                  ),
                ),
                const SizedBox(width: 16),
                Expanded(
                  child: Stack(
                    alignment: Alignment.centerLeft,
                    children: [
                      Container(
                        height: 1,
                        color: isDark
                            ? Colors.white10
                            : Colors.black.withValues(alpha: 0.1),
                      ),
                      Container(
                        width: 12,
                        height: 12,
                        decoration: BoxDecoration(
                          color: isDark ? Colors.black : Colors.white,
                          shape: BoxShape.circle,
                          border: Border.all(
                            color: isDark ? Colors.white : Colors.black,
                            width: 2,
                          ),
                        ),
                      ),
                    ],
                  ),
                ),
              ],
            ),
            const SizedBox(height: 32),
            SizedBox(
              // Bigger image (220) + footer (~125) now the card fills the box.
              height: 345,
              child: PageView.builder(
                // One card at a time: the card fills the width and snaps, so the
                // next phase is fully off-screen until you swipe (it used to be
                // a 240-wide list, which left the next image peeking).
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
                  final status =
                      phase['status']?.toString().toUpperCase() ?? 'UPCOMING';

                  return Container(
                    // Near box-width (was margin 24): card fills the construction
                    // box, matching the reference. Small margin keeps shadow room.
                    margin: const EdgeInsets.symmetric(horizontal: 8),
                    decoration: BoxDecoration(
                      color: isDark
                          ? Colors.white.withValues(alpha: 0.03)
                          : Colors.white,
                      // Match the CP phase card: 24 radius + soft shadow + a
                      // hairline border (subtle in dark so it doesn't show as a
                      // bright edge behind the image).
                      borderRadius: BorderRadius.circular(24),
                      border: Border.all(
                        color: isDark
                            ? Colors.white.withValues(alpha: 0.08)
                            : Colors.black.withValues(alpha: 0.10),
                      ),
                      boxShadow: [
                        BoxShadow(
                          color: Colors.black.withValues(
                            alpha: isDark ? 0.35 : 0.07,
                          ),
                          blurRadius: 14,
                          offset: const Offset(0, 6),
                        ),
                      ],
                    ),
                    // Clip the image + footer to the card's rounded corners so
                    // nothing peeks behind the image's top corners.
                    clipBehavior: Clip.antiAlias,
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        _ScaleButton(
                          // Temporary while /uploads is broken: the demolition
                          // phase opens its bundled photo in the lightbox.
                          onTap: () => onPhaseTap(
                            (phase['phaseName'] ?? phase['name'] ?? '')
                                    .toString()
                                    .toLowerCase()
                                    .contains('demolition')
                                ? 'asset:assets/cledor_phase_demolition.jpg'
                                : imageUrl,
                          ),
                          child: Stack(
                            children: [
                              ClipRRect(
                                borderRadius: const BorderRadius.vertical(
                                  top: Radius.circular(24),
                                ),
                                child: CachedNetworkImage(
                                  imageUrl: imageUrl,
                                  // Taller + full width now the card is wider.
                                  height: 220,
                                  width: double.infinity,
                                  fit: BoxFit.cover,
                                  placeholder: (c, u) => Container(
                                    height: 220,
                                    color: isDark
                                        ? const Color(0xFF1E293B)
                                        : const Color(0xFFF1F5F9),
                                    child: Icon(
                                      LucideIcons.image,
                                      color: isDark
                                          ? Colors.white24
                                          : Colors.black26,
                                      size: 24,
                                    ),
                                  ),
                                  // /uploads is broken server-side: for the
                                  // Demolition phase, fall back to the bundled
                                  // snapshot of the web's phase photo.
                                  errorWidget: (c, e, s) =>
                                      (phase['phaseName'] ??
                                              phase['name'] ??
                                              '')
                                          .toString()
                                          .toLowerCase()
                                          .contains('demolition')
                                      ? Image.asset(
                                          'assets/cledor_phase_demolition.jpg',
                                          height: 220,
                                          width: double.infinity,
                                          fit: BoxFit.cover,
                                          filterQuality: FilterQuality.high,
                                        )
                                      : Container(
                                          height: 220,
                                          color: isDark
                                              ? const Color(0xFF1E293B)
                                              : const Color(0xFFF1F5F9),
                                          child: Icon(
                                            LucideIcons.image,
                                            color: isDark
                                                ? Colors.white24
                                                : Colors.black26,
                                            size: 24,
                                          ),
                                        ),
                                ),
                              ),
                              Positioned(
                                top: 16,
                                left: 16,
                                child: Builder(
                                  builder: (context) {
                                    final done = status == 'COMPLETED';
                                    final active = status == 'IN PROGRESS';
                                    // Web parity: green=done, blue=active,
                                    // light pill w/ dark text = upcoming.
                                    final badgeBg = done
                                        ? const Color(0xFF22C55E)
                                        : (active
                                              ? M4Theme.premiumBlue
                                              : Colors.white);
                                    final badgeTxt = (done || active)
                                        ? Colors.white
                                        : const Color(0xFF0F172A);
                                    return Container(
                                      padding: const EdgeInsets.symmetric(
                                        horizontal: 10,
                                        vertical: 4,
                                      ),
                                      decoration: BoxDecoration(
                                        color: badgeBg,
                                        borderRadius: BorderRadius.circular(6),
                                        border: (!done && !active)
                                            ? Border.all(
                                                color: Colors.black.withValues(
                                                  alpha: 0.08,
                                                ),
                                              )
                                            : null,
                                      ),
                                      child: Text(
                                        status,
                                        style: GoogleFonts.ebGaramond(
                                          fontSize: 8,
                                          fontWeight: FontWeight.w900,
                                          color: badgeTxt,
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
                          padding: const EdgeInsets.all(16),
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Text(
                                projectName.toUpperCase(),
                                style: GoogleFonts.ebGaramond(
                                  fontSize: 12,
                                  fontWeight: FontWeight.bold,
                                  color: isDark
                                      ? Colors.white
                                      : const Color(0xFF0F172A),
                                  letterSpacing: 1,
                                ),
                              ),
                              const SizedBox(height: 12),
                              Row(
                                children: [
                                  // Circular progress ring around the percent —
                                  // solid black with ROUNDED stroke caps (the
                                  // old one was a dashed ring), bold number.
                                  SizedBox(
                                    width: 46,
                                    height: 46,
                                    child: Stack(
                                      alignment: Alignment.center,
                                      children: [
                                        SizedBox(
                                          width: 46,
                                          height: 46,
                                          child: CircularProgressIndicator(
                                            value:
                                                ((phase['progressPercent'] ??
                                                            phase['progress'] ??
                                                            0)
                                                        as num)
                                                    .toDouble() /
                                                100,
                                            strokeWidth: 3,
                                            strokeCap: StrokeCap.round,
                                            backgroundColor:
                                                (isDark
                                                        ? Colors.white
                                                        : Colors.black)
                                                    .withValues(alpha: 0.12),
                                            valueColor:
                                                AlwaysStoppedAnimation<Color>(
                                                  isDark
                                                      ? Colors.white
                                                      : Colors.black,
                                                ),
                                          ),
                                        ),
                                        Text(
                                          '${phase['progressPercent'] ?? phase['progress'] ?? 0}%',
                                          style: GoogleFonts.ebGaramond(
                                            fontSize: 10,
                                            fontWeight: FontWeight.w900,
                                            color: isDark
                                                ? Colors.white
                                                : Colors.black,
                                          ),
                                        ),
                                      ],
                                    ),
                                  ),
                                  const SizedBox(width: 12),
                                  Expanded(
                                    child: Text(
                                      (phase['name'] ??
                                              phase['phaseName'] ??
                                              'PHASE')
                                          .toString()
                                          .toUpperCase(),
                                      style: GoogleFonts.ebGaramond(
                                        fontSize: 10,
                                        fontWeight: FontWeight.w900,
                                        color: isDark
                                            ? Colors.white.withValues(
                                                alpha: 0.85,
                                              )
                                            : Colors.black.withValues(
                                                alpha: 0.85,
                                              ),
                                        letterSpacing: 1.2,
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
                    // Web parity: slate-navy heading + muted slate subtitle.
                    Text(
                      'PHASE TRACKING',
                      style: GoogleFonts.gelasio(
                        fontSize: 12,
                        fontWeight: FontWeight.w900,
                        letterSpacing: 2,
                        color: isDark ? Colors.white : const Color(0xFF1E293B),
                      ),
                    ),
                    Text(
                      'REAL-TIME DEVELOPMENT STATUS',
                      style: GoogleFonts.ebGaramond(
                        fontSize: 8,
                        fontWeight: FontWeight.bold,
                        color: isDark
                            ? Colors.white38
                            : const Color(0xFF94A3B8),
                        letterSpacing: 0.5,
                      ),
                    ),
                  ],
                ),
                Container(
                  padding: const EdgeInsets.symmetric(
                    horizontal: 12,
                    vertical: 6,
                  ),
                  // Web parity: soft outlined chip with black text.
                  decoration: BoxDecoration(
                    color: (isDark ? Colors.white : Colors.black).withValues(
                      alpha: 0.04,
                    ),
                    borderRadius: BorderRadius.circular(8),
                    border: Border.all(
                      color: (isDark ? Colors.white : Colors.black).withValues(
                        alpha: 0.15,
                      ),
                    ),
                  ),
                  child: Text(
                    '${phases.length} MILESTONES',
                    style: GoogleFonts.ebGaramond(
                      fontSize: 8,
                      fontWeight: FontWeight.w900,
                      color: isDark ? Colors.white : Colors.black,
                    ),
                  ),
                ),
              ],
            ),
            const SizedBox(height: 24),
            SizedBox(
              // Web parity: compact milestone card.
              height: 116,
              child: ListView.builder(
                scrollDirection: Axis.horizontal,
                padding: const EdgeInsets.symmetric(horizontal: 24),
                itemCount: phases.length,
                itemBuilder: (context, index) {
                  final phase = phases[index];
                  final progress =
                      (phase['progressPercent'] ?? phase['progress'] ?? 0)
                          .toDouble();
                  final status =
                      phase['status']?.toString().toUpperCase() ?? 'UPCOMING';

                  return Container(
                    width: 280,
                    margin: const EdgeInsets.only(right: 16),
                    padding: const EdgeInsets.all(16),
                    decoration: BoxDecoration(
                      color: isDark
                          ? Colors.white.withValues(alpha: 0.05)
                          : Colors.white,
                      borderRadius: BorderRadius.circular(20),
                      border: Border.all(
                        color: isDark
                            ? Colors.white.withValues(alpha: 0.05)
                            : Colors.black.withValues(alpha: 0.05),
                      ),
                      boxShadow: isDark
                          ? []
                          : [
                              BoxShadow(
                                color: Colors.black.withValues(alpha: 0.03),
                                blurRadius: 15,
                                offset: const Offset(0, 6),
                              ),
                            ],
                    ),
                    child: Column(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        Row(
                          children: [
                            Container(
                              width: 36,
                              height: 36,
                              decoration: BoxDecoration(
                                color: isDark
                                    ? Colors.white.withValues(alpha: 0.05)
                                    : const Color(0xFFF1F5F9),
                                borderRadius: BorderRadius.circular(10),
                              ),
                              child: Center(
                                child: Text(
                                  (index + 1).toString().padLeft(2, '0'),
                                  style: GoogleFonts.ebGaramond(
                                    fontSize: 10,
                                    fontWeight: FontWeight.w900,
                                    color: isDark
                                        ? Colors.white38
                                        : Colors.black38,
                                  ),
                                ),
                              ),
                            ),
                            const SizedBox(width: 12),
                            Expanded(
                              child: Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  Text(
                                    (phase['name'] ??
                                            phase['phaseName'] ??
                                            'PHASE')
                                        .toString()
                                        .toUpperCase(),
                                    style: GoogleFonts.ebGaramond(
                                      fontSize: 11,
                                      fontWeight: FontWeight.w900,
                                      color: isDark
                                          ? Colors.white
                                          : const Color(0xFF1E293B),
                                    ),
                                  ),
                                  Row(
                                    children: [
                                      Container(
                                        width: 6,
                                        height: 6,
                                        decoration: BoxDecoration(
                                          color: progress >= 100
                                              ? Colors.green
                                              : (progress > 0
                                                    ? M4Theme.premiumBlue
                                                    : Colors.grey),
                                          shape: BoxShape.circle,
                                        ),
                                      ),
                                      const SizedBox(width: 6),
                                      Text(
                                        status,
                                        style: GoogleFonts.ebGaramond(
                                          fontSize: 8,
                                          fontWeight: FontWeight.bold,
                                          color: isDark
                                              ? Colors.white38
                                              : Colors.black38,
                                          letterSpacing: 0.5,
                                        ),
                                      ),
                                    ],
                                  ),
                                ],
                              ),
                            ),
                            Text(
                              '${progress.toInt()}%',
                              style: GoogleFonts.ebGaramond(
                                fontSize: 16,
                                fontWeight: FontWeight.w900,
                                color: isDark
                                    ? Colors.white
                                    : const Color(0xFF0F172A),
                              ),
                            ),
                          ],
                        ),
                        const SizedBox(height: 12),
                        Stack(
                          children: [
                            Container(
                              height: 6,
                              width: double.infinity,
                              decoration: BoxDecoration(
                                color: isDark
                                    ? Colors.white.withValues(alpha: 0.05)
                                    : const Color(0xFFF1F5F9),
                                borderRadius: BorderRadius.circular(10),
                              ),
                            ),
                            TweenAnimationBuilder<double>(
                              duration: const Duration(milliseconds: 1500),
                              curve: Curves.easeOutQuart,
                              tween: Tween<double>(
                                begin: 0,
                                end: progress / 100,
                              ),
                              builder: (context, value, _) =>
                                  FractionallySizedBox(
                                    widthFactor: value,
                                    child: Container(
                                      height: 6,
                                      decoration: BoxDecoration(
                                        // Web parity: solid black progress bar.
                                        color: isDark
                                            ? Colors.white
                                            : Colors.black,
                                        borderRadius: BorderRadius.circular(10),
                                        boxShadow: [
                                          BoxShadow(
                                            color: Colors.black.withValues(
                                              alpha: 0.2,
                                            ),
                                            blurRadius: 8,
                                            offset: const Offset(0, 2),
                                          ),
                                        ],
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
                      : Colors.black.withValues(alpha: 0.04),
                  borderRadius: BorderRadius.circular(12),
                  border: Border.all(
                    color: isActive
                        ? M4Theme.premiumBlue
                        : Colors.black.withValues(alpha: 0.05),
                  ),
                ),
                child: Text(
                  label,
                  style: GoogleFonts.ebGaramond(
                    fontSize: 9,
                    fontWeight: FontWeight.w900,
                    color: isActive
                        ? Colors.white
                        : Colors.black.withValues(alpha: 0.4),
                    letterSpacing: 1.0,
                  ),
                ),
              )
              .animate(target: isActive ? 1 : 0)
              .scale(duration: 100.ms, end: const Offset(0.95, 0.95)),
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
          color:
              color ??
              (isDark ? Colors.white.withValues(alpha: 0.1) : Colors.white),
          borderRadius: BorderRadius.circular(12),
          border: Border.all(
            color: (isDark ? Colors.white : Colors.black).withValues(
              alpha: 0.05,
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
    _controller = WebViewController()
      ..setJavaScriptMode(JavaScriptMode.unrestricted)
      ..setBackgroundColor(const Color(0xFF0B111E));

    final locEncoded = Uri.encodeComponent(widget.location);
    final htmlContent =
        '''
      <!DOCTYPE html>
      <html>
        <head>
          <meta name="viewport" content="width=device-width, initial-scale=1.0, maximum-scale=1.0, user-scalable=no">
          <style>
            body, html { margin: 0; padding: 0; width: 100%; height: 100%; overflow: hidden; background: #0b111e; }
            iframe {
              width: 100%;
              height: 100%;
              border: 0;
              filter: invert(90%) hue-rotate(180deg) brightness(95%) contrast(90%);
            }
          </style>
        </head>
        <body>
          <iframe 
            src="https://www.google.com/maps?q=$locEncoded&output=embed"
            allowfullscreen
            loading="lazy"
          ></iframe>
        </body>
      </html>
    ''';
    _controller.loadHtmlString(htmlContent);
  }

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    return Container(
      height: 280,
      decoration: BoxDecoration(
        color: isDark ? const Color(0xFF0B111E) : Colors.white,
        borderRadius: BorderRadius.circular(40),
        border: Border.all(
          color: isDark ? const Color(0xFF0B111E) : Colors.white,
          width: 4,
        ),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.15),
            blurRadius: 20,
            offset: const Offset(0, 10),
          ),
        ],
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
                padding: const EdgeInsets.symmetric(
                  horizontal: 14,
                  vertical: 9,
                ),
                decoration: BoxDecoration(
                  color: isDark
                      ? const Color(0xFF0B111E)
                      : Colors.white.withValues(alpha: 0.95),
                  borderRadius: BorderRadius.circular(30),
                  border: Border.all(
                    color: isDark
                        ? Colors.white.withValues(alpha: 0.08)
                        : Colors.black.withValues(alpha: 0.08),
                  ),
                  boxShadow: [
                    BoxShadow(
                      color: Colors.black.withValues(alpha: 0.15),
                      blurRadius: 10,
                    ),
                  ],
                ),
                child: Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    const Icon(
                      LucideIcons.mapPin,
                      color: M4Theme.premiumBlue,
                      size: 12,
                    ),
                    const SizedBox(width: 6),
                    Text(
                      'VIEW ON MAPS',
                      style: GoogleFonts.ebGaramond(
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
  final double? strokeWidth;

  _DashedCirclePainter({
    required this.progress,
    required this.color,
    required this.backgroundColor,
    this.strokeWidth,
  });

  @override
  void paint(Canvas canvas, Size size) {
    final center = Offset(size.width / 2, size.height / 2);
    final radius = size.width / 2;
    final actualStrokeWidth = strokeWidth ?? 4.0;
    // Web parity: dense fine tick marks (like a watch bezel).
    const dashCount = 56;
    const gap = 0.5;

    final bgPaint = Paint()
      ..color = backgroundColor
      ..strokeWidth = actualStrokeWidth
      ..style = PaintingStyle.stroke;

    final progressPaint = Paint()
      ..color = color
      ..strokeWidth = actualStrokeWidth
      ..style = PaintingStyle.stroke
      // Web parity: butt caps keep the ticks crisply separated — round caps
      // extend each dash by strokeWidth and merge them into a solid ring.
      ..strokeCap = StrokeCap.butt;

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
        bgPaint,
      );

      // Draw progress segment if within range
      if (i < dashCount * progress) {
        canvas.drawArc(
          Rect.fromCircle(center: center, radius: radius),
          startAngle,
          sweepAngle,
          false,
          progressPaint,
        );
      }
    }
  }

  @override
  bool shouldRepaint(CustomPainter oldDelegate) => true;
}

class _CinematicTourOverlay extends StatefulWidget {
  final dynamic project;
  final VoidCallback onBookVideoCall;
  final VoidCallback onBookSiteVisit;

  const _CinematicTourOverlay({
    required this.project,
    required this.onBookVideoCall,
    required this.onBookSiteVisit,
  });

  @override
  State<_CinematicTourOverlay> createState() => _CinematicTourOverlayState();
}

class _CinematicTourOverlayState extends State<_CinematicTourOverlay> {
  int _currentStep = 0;
  final PageController _pageController = PageController();
  List<String> _uniqueImages = [];

  @override
  void initState() {
    super.initState();
    _compileImages();
  }

  void _compileImages() {
    final List<String> imgs = [];
    final project = widget.project;
    if (project['heroImage'] != null &&
        project['heroImage'].toString().isNotEmpty) {
      imgs.add(project['heroImage'].toString());
    }
    if (project['heroImages'] is List) {
      imgs.addAll((project['heroImages'] as List).map((e) => e.toString()));
    }
    if (project['images'] is List) {
      imgs.addAll((project['images'] as List).map((e) => e.toString()));
    }
    if (project['exteriorImages'] is List) {
      imgs.addAll((project['exteriorImages'] as List).map((e) => e.toString()));
    }
    if (project['interiorImages'] is List) {
      imgs.addAll((project['interiorImages'] as List).map((e) => e.toString()));
    }
    _uniqueImages = imgs.toSet().where((img) => img.isNotEmpty).toList();
    if (_uniqueImages.isEmpty) {
      _uniqueImages.add(
        'https://images.unsplash.com/photo-1486406146926-c627a92ad1ab?auto=format&fit=crop&q=80',
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    final title = (widget.project['title']?.toString() ?? 'M4 Estate')
        .toUpperCase();
    final description =
        widget.project['description']?.toString() ??
        'A curated luxury development by M4 Properties.';
    final primaryImg = _uniqueImages.first;

    return Scaffold(
      backgroundColor: Colors.black,
      body: SafeArea(
        child: Stack(
          children: [
            // Immersive background step-dependent
            Positioned.fill(
              child: AnimatedSwitcher(
                duration: const Duration(milliseconds: 500),
                child: _buildBackground(primaryImg),
              ),
            ),

            // Content
            Column(
              children: [
                // Top Progress Indicators & Close button
                Padding(
                  padding: const EdgeInsets.fromLTRB(24, 20, 24, 10),
                  child: Row(
                    children: [
                      // Linear step progress bars
                      Expanded(
                        child: Row(
                          children: List.generate(4, (index) {
                            return Expanded(
                              child: Container(
                                height: 3,
                                margin: const EdgeInsets.symmetric(
                                  horizontal: 3,
                                ),
                                decoration: BoxDecoration(
                                  color: index <= _currentStep
                                      ? M4Theme.premiumBlue
                                      : Colors.white.withOpacity(0.2),
                                  borderRadius: BorderRadius.circular(1.5),
                                ),
                              ),
                            );
                          }),
                        ),
                      ),
                      const SizedBox(width: 16),
                      // Close button
                      GestureDetector(
                        onTap: () => Navigator.pop(context),
                        child: Container(
                          width: 36,
                          height: 36,
                          decoration: BoxDecoration(
                            shape: BoxShape.circle,
                            color: Colors.white.withOpacity(0.1),
                          ),
                          child: const Icon(
                            LucideIcons.x,
                            color: Colors.white,
                            size: 18,
                          ),
                        ),
                      ),
                    ],
                  ),
                ),

                // Main step content
                Expanded(
                  child: AnimatedSwitcher(
                    duration: const Duration(milliseconds: 400),
                    child: _buildStepContent(title, description),
                  ),
                ),

                // Footer Navigation
                Padding(
                  padding: const EdgeInsets.fromLTRB(24, 10, 24, 30),
                  child: Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      // Back Button
                      if (_currentStep > 0)
                        GestureDetector(
                          onTap: () => setState(() => _currentStep--),
                          child: Text(
                            'BACK',
                            style: GoogleFonts.gelasio(
                              color: Colors.white.withOpacity(0.6),
                              fontSize: 10,
                              fontWeight: FontWeight.w900,
                              letterSpacing: 2.0,
                            ),
                          ),
                        )
                      else
                        const SizedBox.shrink(),

                      // Continue Button
                      GestureDetector(
                        onTap: () {
                          if (_currentStep < 3) {
                            setState(() => _currentStep++);
                          } else {
                            Navigator.pop(context);
                          }
                        },
                        child: Container(
                          padding: const EdgeInsets.symmetric(
                            horizontal: 24,
                            vertical: 12,
                          ),
                          decoration: BoxDecoration(
                            color: Colors.white,
                            borderRadius: BorderRadius.circular(20),
                          ),
                          child: Text(
                            _currentStep == 3 ? 'CLOSE EXPLORER' : 'CONTINUE',
                            style: GoogleFonts.gelasio(
                              color: Colors.black,
                              fontSize: 9,
                              fontWeight: FontWeight.w900,
                              letterSpacing: 1.5,
                            ),
                          ),
                        ),
                      ),
                    ],
                  ),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildBackground(String primaryImg) {
    if (_currentStep == 0) {
      return ImageBackground(imageUrl: primaryImg, blur: 0);
    } else if (_currentStep == 1) {
      return ImageBackground(imageUrl: primaryImg, blur: 15);
    } else {
      return Container(color: Colors.black);
    }
  }

  Widget _buildStepContent(String title, String description) {
    switch (_currentStep) {
      case 0:
        return _buildStep0(title);
      case 1:
        return _buildStep1(description);
      case 2:
        return _buildStep2();
      case 3:
        return _buildStep3();
      default:
        return const SizedBox.shrink();
    }
  }

  Widget _buildStep0(String title) {
    return Container(
      key: const ValueKey('step0'),
      padding: const EdgeInsets.symmetric(horizontal: 32),
      alignment: Alignment.center,
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Text(
            title,
            textAlign: TextAlign.center,
            style: GoogleFonts.gelasio(
              color: Colors.white,
              fontSize: 36,
              height: 1.1,
              letterSpacing: -0.5,
            ),
          ),
          const SizedBox(height: 16),
          Container(width: 40, height: 1.5, color: M4Theme.premiumBlue),
          const SizedBox(height: 16),
          Text(
            'DISCOVER THE UNSEEN',
            style: GoogleFonts.gelasio(
              color: Colors.white70,
              fontSize: 9,
              fontWeight: FontWeight.w900,
              letterSpacing: 4.0,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildStep1(String description) {
    return Container(
      key: const ValueKey('step1'),
      padding: const EdgeInsets.symmetric(horizontal: 32),
      alignment: Alignment.center,
      child: Container(
        padding: const EdgeInsets.all(24),
        decoration: BoxDecoration(
          color: Colors.white.withOpacity(0.08),
          borderRadius: BorderRadius.circular(24),
          border: Border.all(color: Colors.white.withOpacity(0.15), width: 1.5),
        ),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              'THE VISION',
              style: GoogleFonts.gelasio(
                color: M4Theme.premiumBlue,
                fontSize: 10,
                fontWeight: FontWeight.w900,
                letterSpacing: 3.0,
              ),
            ),
            const SizedBox(height: 16),
            Text(
              description,
              style: GoogleFonts.ebGaramond(
                color: Colors.white.withOpacity(0.85),
                fontSize: 13,
                height: 1.6,
                fontWeight: FontWeight.w500,
              ),
            ),
          ],
        ),
      ),
    ).animate().fadeIn(duration: 400.ms).slideY(begin: 0.05, end: 0);
  }

  Widget _buildStep2() {
    return Container(
      key: const ValueKey('step2'),
      alignment: Alignment.center,
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Text(
            'VISUAL DISCOVERY',
            style: GoogleFonts.gelasio(
              color: Colors.white,
              fontSize: 12,
              fontWeight: FontWeight.w900,
              letterSpacing: 3.0,
            ),
          ),
          const SizedBox(height: 6),
          Text(
            'Swipe to explore design details.',
            style: GoogleFonts.ebGaramond(
              color: Colors.white38,
              fontSize: 10,
              fontWeight: FontWeight.w600,
            ),
          ),
          const SizedBox(height: 32),
          SizedBox(
            height: 300,
            child: PageView.builder(
              controller: _pageController,
              itemCount: _uniqueImages.length,
              itemBuilder: (context, index) {
                final img = _uniqueImages[index];
                return Padding(
                  padding: const EdgeInsets.symmetric(horizontal: 16),
                  child: ClipRRect(
                    borderRadius: BorderRadius.circular(24),
                    child: Container(
                      decoration: BoxDecoration(
                        border: Border.all(color: Colors.white24, width: 1.5),
                      ),
                      child: ImageBackground(imageUrl: img, blur: 0),
                    ),
                  ),
                );
              },
            ),
          ),
          const SizedBox(height: 24),
          // Page indicators
          Row(
            mainAxisAlignment: MainAxisAlignment.center,
            children: List.generate(_uniqueImages.length, (index) {
              return ListenableBuilder(
                listenable: _pageController,
                builder: (context, _) {
                  final page = _pageController.hasClients
                      ? (_pageController.page ?? 0).round()
                      : 0;
                  final isSelected = page == index;
                  return AnimatedContainer(
                    duration: const Duration(milliseconds: 300),
                    width: isSelected ? 16 : 6,
                    height: 6,
                    margin: const EdgeInsets.symmetric(horizontal: 3),
                    decoration: BoxDecoration(
                      color: isSelected ? Colors.white : Colors.white24,
                      borderRadius: BorderRadius.circular(3),
                    ),
                  );
                },
              );
            }),
          ),
        ],
      ),
    ).animate().fadeIn(duration: 400.ms);
  }

  Widget _buildStep3() {
    return Container(
      key: const ValueKey('step3'),
      padding: const EdgeInsets.symmetric(horizontal: 32),
      alignment: Alignment.center,
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Container(
            padding: const EdgeInsets.all(16),
            decoration: BoxDecoration(
              shape: BoxShape.circle,
              color: M4Theme.premiumBlue.withOpacity(0.2),
              border: Border.all(color: M4Theme.premiumBlue, width: 2),
            ),
            child: const Icon(
              LucideIcons.check,
              color: M4Theme.premiumBlue,
              size: 36,
            ),
          ).animate().scale(
            delay: 150.ms,
            duration: 400.ms,
            curve: Curves.easeOutBack,
          ),
          const SizedBox(height: 32),
          Text(
            'YOUR JOURNEY STARTS HERE',
            textAlign: TextAlign.center,
            style: GoogleFonts.gelasio(
              color: Colors.white,
              fontSize: 16,
              fontWeight: FontWeight.w900,
              letterSpacing: 2.0,
            ),
          ),
          const SizedBox(height: 12),
          Text(
            'Select a booking mode to interact with our developers.',
            textAlign: TextAlign.center,
            style: GoogleFonts.ebGaramond(
              color: Colors.white38,
              fontSize: 10,
              fontWeight: FontWeight.w600,
            ),
          ),
          const SizedBox(height: 48),

          // Action buttons
          SizedBox(
            width: double.infinity,
            height: 56,
            child: ElevatedButton(
              onPressed: widget.onBookVideoCall,
              style: ElevatedButton.styleFrom(
                backgroundColor: M4Theme.premiumBlue,
                foregroundColor: Colors.white,
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(16),
                ),
              ),
              child: Text(
                'BOOK VIDEO CALL',
                style: GoogleFonts.gelasio(
                  fontSize: 11,
                  fontWeight: FontWeight.w900,
                  letterSpacing: 2,
                ),
              ),
            ),
          ),
          const SizedBox(height: 16),
          SizedBox(
            width: double.infinity,
            height: 56,
            child: OutlinedButton(
              onPressed: widget.onBookSiteVisit,
              style: OutlinedButton.styleFrom(
                side: const BorderSide(color: Colors.white24, width: 1.5),
                foregroundColor: Colors.white,
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(16),
                ),
              ),
              child: Text(
                'CONTINUE TO SITE VISIT',
                style: GoogleFonts.gelasio(
                  fontSize: 11,
                  fontWeight: FontWeight.w900,
                  letterSpacing: 2,
                ),
              ),
            ),
          ),
        ],
      ),
    ).animate().fadeIn(duration: 400.ms);
  }
}

class ImageBackground extends StatelessWidget {
  final String imageUrl;
  final double blur;

  const ImageBackground({required this.imageUrl, required this.blur});

  @override
  Widget build(BuildContext context) {
    final client = ProviderScope.containerOf(context).read(apiClientProvider);
    final resolvedUrl = client.resolveUrl(imageUrl);
    Widget childImage;
    if (resolvedUrl.startsWith('data:')) {
      // Inline base64 heroes (e.g. Cledor) can appear in the gallery too.
      try {
        final bytes = _detailB64Cache.putIfAbsent(
          resolvedUrl,
          () => base64Decode(
            resolvedUrl
                .substring(resolvedUrl.indexOf(',') + 1)
                .replaceAll(RegExp(r'\s'), ''),
          ),
        );
        childImage = Image.memory(
          bytes,
          fit: BoxFit.cover,
          gaplessPlayback: true,
          cacheWidth: 1080,
        );
      } catch (_) {
        childImage = Container(color: Colors.black26);
      }
    } else {
      childImage = CachedNetworkImage(
        imageUrl: resolvedUrl,
        fit: BoxFit.cover,
        memCacheWidth: 900,
        fadeInDuration: Duration.zero,
        placeholder: (context, url) => Container(color: Colors.black26),
        errorWidget: (context, url, error) => Image.network(
          'https://images.unsplash.com/photo-1486406146926-c627a92ad1ab?auto=format&fit=crop&q=80',
          fit: BoxFit.cover,
        ),
      );
    }

    if (blur == 0) return childImage;

    return ImageFiltered(
      imageFilter: ImageFilter.blur(sigmaX: blur, sigmaY: blur),
      child: childImage,
    );
  }
}
