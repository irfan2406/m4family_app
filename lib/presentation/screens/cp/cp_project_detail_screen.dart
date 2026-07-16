import 'dart:convert';

import 'package:cached_network_image/cached_network_image.dart';
import 'package:flutter/cupertino.dart';
import 'package:dio/dio.dart';
import 'dart:math' as math;
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:intl/intl.dart';
import 'package:lucide_icons/lucide_icons.dart';
import 'package:m4_mobile/presentation/providers/auth_provider.dart';
import 'package:m4_mobile/presentation/providers/project_provider.dart';
import 'package:m4_mobile/presentation/providers/cp_shell_provider.dart';
import 'package:m4_mobile/presentation/widgets/cp_bottom_nav.dart';
import 'package:m4_mobile/presentation/widgets/luxury_amenity_icon.dart';
import 'package:m4_mobile/presentation/widgets/wheel_date_time_picker.dart';
import 'package:share_plus/share_plus.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:url_launcher/url_launcher.dart';
import 'package:webview_flutter/webview_flutter.dart';

/// CP portal project details — visual parity with web `/cp/projects/[id]`.
///
/// Notes:
/// - Uses catalog endpoints for project data (same as web).
/// - CP actions: Video Call opens a CP lead sheet; Site Visit routes to `/cp/booking/site-visit?projectId=...`.
class CpProjectDetailScreen extends ConsumerStatefulWidget {
  final String projectId;
  final Map<String, dynamic>? projectData;

  const CpProjectDetailScreen({
    super.key,
    required this.projectId,
    this.projectData,
  });

  @override
  ConsumerState<CpProjectDetailScreen> createState() =>
      _CpProjectDetailScreenState();
}

class _CpProjectDetailScreenState extends ConsumerState<CpProjectDetailScreen> {
  bool _loading = true;
  Map<String, dynamic>? _project;
  List<dynamic> _progress = [];
  bool _liked = false;

  /// Decoded base64 `data:` images cached by URI so a rebuild (e.g. the heart
  /// toggle's setState) reuses the SAME provider instead of re-decoding and
  /// reloading the image — which caused the visible flicker.
  final Map<String, ImageProvider> _dataUriImages = {};

  // Video call lead dialog
  bool _leadOpen = false;
  bool _leadSubmitting = false;
  List<Map<String, dynamic>> _employees = [];
  List<Map<String, dynamic>> _allProjects = [];
  String? _selectedProjectId;
  String _employeeMode = 'select'; // select | enter
  String? _employeeId;
  final _employeeEntered = TextEditingController();
  final _clientName = TextEditingController();
  final _clientPhone = TextEditingController();
  final _clientEmail = TextEditingController();
  DateTime? _videoCallDt;
  String _visitType = 'Video Call'; // Video Call | Site Visit (web VISIT TYPE)
  bool _showFullProgressDesc = false; // "Read more" toggle (web parity)

  // Registration (interest) form — web section `#registration`
  bool _regSubmitting = false;
  String? _regEmployeeId;

  // Inline validation for the Registration form — each error is shown on its
  // own field rather than as a snackbar that didn't say which one was wrong.
  String? _regNameError;
  String? _regPhoneError;
  String? _regEmailError;

  /// Resolved project ObjectId for the registration payload — null when we only
  /// have a slug (the API rejects a non-ObjectId here).
  String? _regProjectId;
  final _regEmployeeEntered = TextEditingController();
  final _regClientName = TextEditingController();
  final _regClientPhone = TextEditingController();
  final _regClientEmail = TextEditingController();
  final _regLocation = TextEditingController();

  // Lightbox (Exterior/Interior/Floor plans/Progress)
  bool _galleryOpen = false;
  List<String> _gallery = const [];
  int _galleryIndex = 0;
  PageController? _galleryCtrl;

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      _load();
      _loadLiked();
      // Populate the Registration "Employee Name" dropdown up front — it used
      // to fetch only when the video-call sheet opened or on submit, so the
      // list showed just "Select / Other" until then (web loads it on mount).
      _fetchEmployees();
    });
  }

  Future<void> _fetchEmployees() async {
    if (_employees.isNotEmpty) return;
    try {
      final res = await ref.read(apiClientProvider).getCpEmployees();
      final body = res.data;
      if (body is Map && body['status'] == true && body['data'] is List) {
        final list = (body['data'] as List)
            .map((e) => Map<String, dynamic>.from(e as Map))
            .toList();
        if (mounted) setState(() => _employees = list);
      }
    } catch (_) {}
  }

  @override
  void dispose() {
    _employeeEntered.dispose();
    _clientName.dispose();
    _clientPhone.dispose();
    _clientEmail.dispose();
    _regEmployeeEntered.dispose();
    _regClientName.dispose();
    _regClientPhone.dispose();
    _regClientEmail.dispose();
    _regLocation.dispose();
    _galleryCtrl?.dispose();
    super.dispose();
  }

  Future<void> _load() async {
    setState(() => _loading = true);
    try {
      final api = ref.read(apiClientProvider);
      final res = await api.getProjectDetails(widget.projectId);
      final body = res.data;
      if (body is Map && body['status'] == true && body['data'] is Map) {
        _project = Map<String, dynamic>.from(body['data'] as Map);
      } else if (body is Map && body['data'] is Map) {
        _project = Map<String, dynamic>.from(body['data'] as Map);
      } else {
        _project = widget.projectData;
      }

      // progress (web calls `/catalog/projects/:id/progress`)
      try {
        final p = await api.getProjectProgress(widget.projectId);
        final pb = p.data;
        if (pb is Map && pb['status'] == true && pb['data'] is List) {
          _progress = List<dynamic>.from(pb['data'] as List);
        } else if (pb is List) {
          _progress = List<dynamic>.from(pb);
        }
      } catch (_) {}
    } catch (_) {
      _project = widget.projectData;
    }
    if (mounted) setState(() => _loading = false);
  }

  int _overallProgressPct() {
    // Mirror web logic: pick latest Completed/In Progress phase, fallback to `completion`.
    try {
      final phases = _progress
          .whereType<Map>()
          .map((m) => Map<String, dynamic>.from(m))
          .toList();
      phases.sort(
        (a, b) => ((a['phaseOrder'] ?? 0) as num).toInt().compareTo(
          ((b['phaseOrder'] ?? 0) as num).toInt(),
        ),
      );
      final last =
          phases.where((p) {
            final s = (p['status'] ?? '').toString();
            return s == 'Completed' || s == 'In Progress';
          }).isNotEmpty
          ? phases.where((p) {
              final s = (p['status'] ?? '').toString();
              return s == 'Completed' || s == 'In Progress';
            }).last
          : null;
      final pct = last?['progressPercent'];
      if (pct is num) return pct.toInt().clamp(0, 100);
    } catch (_) {}

    final raw = _project?['completion']?.toString();
    final parsed = int.tryParse(raw ?? '');
    return (parsed ?? 0).clamp(0, 100);
  }

  String _heroImage() {
    final p = _project ?? widget.projectData ?? {};
    final api = ref.read(apiClientProvider);
    final heroImages = p['heroImages'];
    if (heroImages is List && heroImages.isNotEmpty) {
      return api.resolveUrl(heroImages.first?.toString());
    }
    final hero = p['heroImage']?.toString();
    return api.resolveUrl(hero);
  }

  /// Renders a project image, handling base64 `data:` URIs (which
  /// CachedNetworkImage cannot fetch) via [Image.memory]; http/relative URLs go
  /// through the network loader. Mirrors the web, which puts data: URIs straight
  /// into an <img>.
  Widget _projectImage(
    String? raw, {
    BoxFit fit = BoxFit.cover,
    Widget? errorWidget,
  }) {
    final fallback =
        errorWidget ??
        Container(color: Theme.of(context).colorScheme.surfaceContainerHighest);
    final s = raw?.trim() ?? '';
    if (s.isEmpty) return fallback;
    if (s.startsWith('data:')) {
      try {
        // Cache the provider per data URI so rebuilds reuse it (no re-decode /
        // reload -> no flicker when setState fires, e.g. tapping the heart).
        final provider = _dataUriImages[s] ??= MemoryImage(
          base64Decode(
            s.substring(s.indexOf(',') + 1).replaceAll(RegExp(r'\s'), ''),
          ),
        );
        return Image(
          image: provider,
          fit: fit,
          errorBuilder: (_, __, ___) => fallback,
        );
      } catch (_) {
        return fallback;
      }
    }
    final url = s.startsWith('http')
        ? s
        : ref.read(apiClientProvider).resolveUrl(s);
    return CachedNetworkImage(
      imageUrl: url,
      fit: fit,
      errorWidget: (_, __, ___) => fallback,
    );
  }

  String _locationLine() {
    final loc = _project?['location'];
    if (loc is String) return loc;
    if (loc is Map) return (loc['name'] ?? '').toString();
    return 'N/A';
  }

  Future<void> _openUrl(String? url) async {
    if (url == null || url.isEmpty) return;
    final resolved = ref.read(apiClientProvider).resolveUrl(url);
    final uri = Uri.parse(resolved);
    await launchUrl(uri, mode: LaunchMode.externalApplication);
  }

  Future<void> _loadLiked() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      final ids = prefs.getStringList('cp_favorites') ?? const <String>[];
      if (!mounted) return;
      setState(() => _liked = ids.contains(widget.projectId));
    } catch (_) {}
  }

  Future<void> _toggleLiked() async {
    final next = !_liked;
    setState(() => _liked = next);
    try {
      final prefs = await SharedPreferences.getInstance();
      final ids = (prefs.getStringList('cp_favorites') ?? const <String>[])
          .toList();
      ids.removeWhere((x) => x == widget.projectId);
      if (next) ids.add(widget.projectId);
      await prefs.setStringList('cp_favorites', ids);
    } catch (_) {}
    if (!mounted) return;
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        backgroundColor: const Color(0xFF10B981),
        content: Text(next ? 'Saved to favorites' : 'Removed from favorites'),
      ),
    );
  }

  Future<void> _shareProject() async {
    final title =
        (_project?['title'] ?? widget.projectData?['title'] ?? 'Project')
            .toString();
    final link = ref
        .read(apiClientProvider)
        .resolveUrl('/cp/projects/${widget.projectId}');
    await Share.share('Check out $title on M4 Family!\n$link');
  }

  void _openOrWarn(String? url, [String message = 'Not available']) {
    if (url == null || url.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          backgroundColor: const Color(0xFFE24B4A),
          content: Text(message),
        ),
      );
      return;
    }
    _openUrl(url);
  }

  String? _stringUrl(dynamic v) {
    if (v == null) return null;
    if (v is String) return v;
    if (v is Map) {
      // Different APIs sometimes use different keys for media URLs.
      return v['url']?.toString() ??
          v['fileUrl']?.toString() ??
          v['src']?.toString() ??
          v['imageUrl']?.toString() ??
          v['image']?.toString() ??
          v['path']?.toString() ??
          v['location']?.toString();
    }
    return v.toString();
  }

  List<String> _stringList(dynamic v) {
    if (v is! List) return const [];
    final out = <String>[];
    for (final x in v) {
      final s = _stringUrl(x);
      if (s != null && s.trim().isNotEmpty) out.add(s.trim());
    }
    return out;
  }

  void _openGallery(List<String> urls, {int initial = 0}) {
    if (urls.isEmpty) return;
    setState(() {
      _galleryOpen = true;
      _gallery = urls;
      _galleryIndex = initial.clamp(0, urls.length - 1);
      _galleryCtrl?.dispose();
      _galleryCtrl = PageController(initialPage: _galleryIndex);
    });
  }

  Future<void> _openVideoCallSheet() async {
    // Open the sheet FIRST. These fetches used to be awaited before it opened —
    // and the projects catalog takes ~90s (multi-MB payload), so tapping
    // "Connect Now" appeared to do nothing at all for a minute and a half.
    // The dropdowns fill in as each fetch lands.
    //
    // Web parity: client fields start EMPTY — don't prefill with the CP's own
    // account details. "Select Project" also starts unselected, matching web.
    if (mounted) setState(() => _leadOpen = true);

    // Employees (CP CRM) — small payload, lands quickly.
    if (_employees.isEmpty) {
      try {
        final res = await ref.read(apiClientProvider).getCpEmployees();
        final body = res.data;
        if (body is Map && body['status'] == true && body['data'] is List) {
          _employees = (body['data'] as List)
              .map((e) => Map<String, dynamic>.from(e as Map))
              .toList();
          if (mounted) setState(() {});
        }
      } catch (_) {}
    }

    // Projects for the "Select Project" dropdown. Go through the shared
    // projectsProvider rather than a bare getProjects(): it's cached, so this
    // no longer re-downloads the multi-MB catalog every time the sheet opens.
    if (_allProjects.isEmpty) {
      try {
        final list = await ref.read(projectsProvider.future);
        _allProjects = list
            .whereType<Map>()
            .map((e) => Map<String, dynamic>.from(e))
            .toList();
        if (mounted) setState(() {});
      } catch (_) {}
    }
  }

  Future<void> _submitRegistration() async {
    final p = _project ?? widget.projectData;
    if (p == null) return;

    // Ensure we have employee list for the dropdown (same as web "Select a name from list")
    if (_employees.isEmpty) {
      try {
        final res = await ref.read(apiClientProvider).getCpEmployees();
        final body = res.data;
        if (body is Map && body['status'] == true && body['data'] is List) {
          _employees = (body['data'] as List)
              .map((e) => Map<String, dynamic>.from(e as Map))
              .toList();
        }
      } catch (_) {}
    }

    final typedEmp = _regEmployeeEntered.text.trim();
    // Employee name is OPTIONAL (web parity). "Other" (value 'other') is a
    // free-text choice, not a real employee id, so it never counts as a picked
    // employee — the typed name is used instead.
    final hasPick =
        _regEmployeeId != null &&
        _regEmployeeId!.isNotEmpty &&
        _regEmployeeId != 'other';
    // Each problem is reported ON its own field (red border + reason) instead
    // of a snackbar that didn't say which field was wrong.
    final email = _regClientEmail.text.trim();
    final phone = _regClientPhone.text.trim();
    final nameErr = _regClientName.text.trim().isEmpty
        ? 'Enter the client name'
        : null;
    final phoneErr = phone.isEmpty
        ? 'Enter the client number'
        : (phone.replaceAll(RegExp(r'\D'), '').length < 10
              ? 'Enter a valid 10-digit number'
              : null);
    final emailErr = email.isEmpty
        ? 'Enter the email address'
        : (!RegExp(r'^[\w.+-]+@[\w-]+\.[\w.-]+$').hasMatch(email)
              ? 'Enter a valid email address'
              : null);
    setState(() {
      _regNameError = nameErr;
      _regPhoneError = phoneErr;
      _regEmailError = emailErr;
    });
    if (nameErr != null || phoneErr != null || emailErr != null) return;

    final selectName = hasPick
        ? _employees
                  .firstWhere(
                    (e) => e['_id']?.toString() == _regEmployeeId,
                    orElse: () => {},
                  )['name']
                  ?.toString() ??
              ''
        : '';
    final employeeName = selectName.isNotEmpty ? selectName : typedEmp;
    final notesStaff = typedEmp.isNotEmpty && hasPick
        ? 'Entered: $typedEmp • Selected: $selectName'
        : typedEmp.isNotEmpty
        ? 'Staff (entered): $typedEmp'
        : 'Staff (selected): $selectName';
    final loc = _regLocation.text.trim();

    final sourceId =
        ref.read(authProvider).user?['_id']?.toString() ??
        ref.read(authProvider).user?['id']?.toString();

    // Resolve a REAL project ObjectId; widget.projectId may be a route slug.
    final regProjectIdRaw =
        p['_id']?.toString() ?? p['id']?.toString() ?? widget.projectId;
    _regProjectId = regProjectIdRaw.length == 24 ? regProjectIdRaw : null;

    setState(() => _regSubmitting = true);
    try {
      final api = ref.read(apiClientProvider);
      final res = await api.submitLead({
        'name': _regClientName.text.trim(),
        'email': _regClientEmail.text.trim(),
        'phone': _regClientPhone.text.trim(),
        // `projectId` is an ObjectId ref. widget.projectId can be a route SLUG
        // ("cledor"), which made the API reject the whole lead with a
        // CastToObjectId/BSONError — so only send a real id (same guard as
        // sourceId below). `project` still carries the title either way.
        if (_regProjectId != null) 'projectId': _regProjectId,
        'project': (p['title'] ?? 'Project').toString(),
        // Server-side enum — 'Registration' isn't a valid value and was
        // rejected with a 400. Valid: Buying | Selling | Site Visit | Video Call.
        'interest': 'Buying',
        // Enum is UPPERCASE ('new' was rejected). Valid: NEW | INTERESTED | …
        'status': 'NEW',
        'source': 'cp',
        'message':
            'CP portal registration • Employee: $employeeName • Project: ${(p['title'] ?? 'N/A').toString()}${loc.isNotEmpty ? ' • Location: $loc' : ''}',
        'notes': 'Registration form (CP) • $notesStaff',
        if (loc.isNotEmpty) 'location': loc,
        if (sourceId != null && sourceId.length == 24) 'sourceId': sourceId,
        if (hasPick && (_regEmployeeId?.length ?? 0) == 24)
          'assignedTo': _regEmployeeId,
      });
      if (!mounted) return;
      final ok = res.data is Map ? (res.data as Map)['status'] == true : false;
      if (ok) {
        _regToast('Registration submitted', success: true);
        _regEmployeeEntered.clear();
        _regClientName.clear();
        _regClientPhone.clear();
        _regClientEmail.clear();
        _regLocation.clear();
        setState(() => _regEmployeeId = null);
      } else {
        final msg = res.data is Map
            ? (res.data as Map)['message']?.toString()
            : null;
        _regToast(msg ?? 'Submission failed');
      }
    } on DioException catch (e) {
      final msg = e.response?.data is Map
          ? (e.response!.data as Map)['message']?.toString()
          : null;
      if (mounted) _regToast(msg ?? 'Submission failed');
    } finally {
      if (mounted) setState(() => _regSubmitting = false);
    }
  }

  // iOS-style wheel date+time picker (matches the web IOSDateTimePicker).
  Future<void> _pickVideoDt() async {
    final now = DateTime.now();
    DateTime temp = _videoCallDt ?? now.add(const Duration(minutes: 30));
    if (temp.isBefore(now)) temp = now.add(const Duration(minutes: 30));
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final result = await showModalBottomSheet<DateTime>(
      context: context,
      backgroundColor: Colors.transparent,
      isScrollControlled: true,
      builder: (sheetCtx) => Container(
        decoration: BoxDecoration(
          color: isDark ? const Color(0xFF0B111E) : Colors.white,
          borderRadius: const BorderRadius.vertical(top: Radius.circular(28)),
        ),
        padding: const EdgeInsets.fromLTRB(20, 14, 20, 20),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Center(
              child: Container(
                width: 40,
                height: 4,
                decoration: BoxDecoration(
                  color: (isDark ? Colors.white : Colors.black).withValues(
                    alpha: 0.15,
                  ),
                  borderRadius: BorderRadius.circular(99),
                ),
              ),
            ),
            const SizedBox(height: 16),
            Align(
              alignment: Alignment.centerLeft,
              child: Text(
                'SELECT DATE & TIME',
                style: GoogleFonts.dmSerifDisplay(
                  fontSize: 15,
                  fontWeight: FontWeight.w900,
                  letterSpacing: 0.5,
                  color: isDark ? Colors.white : Colors.black,
                ),
              ),
            ),
            const SizedBox(height: 8),
            // Web parity: absolute Day/Month/Year + Hour/Min/AM-PM wheels (the
            // web's IOSDateTimePicker never shows relative labels like "Today").
            // CupertinoDatePicker's dateAndTime mode always shows those relative
            // labels with no way to disable them, so this is a custom picker.
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
                    onPressed: () => Navigator.pop(sheetCtx),
                    style: OutlinedButton.styleFrom(
                      minimumSize: const Size.fromHeight(52),
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(16),
                      ),
                      side: BorderSide(
                        color: (isDark ? Colors.white : Colors.black)
                            .withValues(alpha: 0.2),
                      ),
                      foregroundColor: isDark ? Colors.white : Colors.black,
                    ),
                    child: Text(
                      'CANCEL',
                      style: GoogleFonts.dmSerifDisplay(
                        fontWeight: FontWeight.w900,
                        letterSpacing: 1,
                      ),
                    ),
                  ),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: FilledButton(
                    onPressed: () => Navigator.pop(sheetCtx, temp),
                    style: FilledButton.styleFrom(
                      backgroundColor: isDark ? Colors.white : Colors.black,
                      foregroundColor: isDark ? Colors.black : Colors.white,
                      minimumSize: const Size.fromHeight(52),
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(16),
                      ),
                    ),
                    child: Text(
                      'CONFIRM',
                      style: GoogleFonts.dmSerifDisplay(
                        fontWeight: FontWeight.w900,
                        letterSpacing: 1,
                      ),
                    ),
                  ),
                ),
              ],
            ),
          ],
        ),
      ),
    );
    if (result != null && mounted) {
      setState(() => _videoCallDt = result);
    }
  }

  Future<void> _submitVideoCallLead() async {
    final p = _project ?? widget.projectData;
    if (p == null) return;

    final typedEmp = _employeeEntered.text.trim();
    final hasPick = _employeeId != null && _employeeId!.isNotEmpty;
    if (!typedEmp.isNotEmpty && !hasPick) {
      _regToast('Enter or select employee name');
      return;
    }
    if (_clientName.text.trim().isEmpty ||
        _clientPhone.text.trim().isEmpty ||
        _clientEmail.text.trim().isEmpty) {
      _regToast('Enter client name, number, and email');
      return;
    }
    if (_videoCallDt == null) {
      _regToast('Select date and time');
      return;
    }

    final selectName = hasPick
        ? _employees
                  .firstWhere(
                    (e) => e['_id']?.toString() == _employeeId,
                    orElse: () => {},
                  )['name']
                  ?.toString() ??
              ''
        : '';
    final employeeName = selectName.isNotEmpty ? selectName : typedEmp;
    final notesStaff = typedEmp.isNotEmpty && hasPick
        ? 'Entered: $typedEmp • Selected: $selectName'
        : typedEmp.isNotEmpty
        ? 'Staff (entered): $typedEmp'
        : 'Staff (selected): $selectName';

    final sourceId =
        ref.read(authProvider).user?['_id']?.toString() ??
        ref.read(authProvider).user?['id']?.toString();

    // "Select Project" overrides the project this video call is registered
    // against; falls back to the project this page opened for.
    final chosenProject = _selectedProjectId == null
        ? null
        : _allProjects.firstWhere(
            (proj) =>
                (proj['_id'] ?? proj['id'])?.toString() == _selectedProjectId,
            orElse: () => {},
          );
    final effectiveProjectId =
        chosenProject?['_id']?.toString() ??
        chosenProject?['id']?.toString() ??
        p['_id']?.toString() ??
        p['id']?.toString() ??
        widget.projectId;
    final effectiveProjectTitle =
        (chosenProject?['title'] ?? p['title'] ?? 'Project').toString();

    setState(() => _leadSubmitting = true);
    try {
      final api = ref.read(apiClientProvider);
      final res = await api.submitLead({
        'name': _clientName.text.trim(),
        'phone': _clientPhone.text.trim(),
        'email': _clientEmail.text.trim(),
        // Only ever send a real ObjectId — a slug here made the API reject the
        // whole lead with a CastToObjectId/BSONError.
        if (effectiveProjectId.length == 24) 'projectId': effectiveProjectId,
        'project': effectiveProjectTitle,
        'interest': _visitType,
        // Enum is UPPERCASE ('new' was rejected). Valid: NEW | INTERESTED | …
        'status': 'NEW',
        'source': 'cp',
        'message':
            'CP video call • Employee: $employeeName • ${(p['title'] ?? '').toString()}',
        'notes': 'Video call booking • $notesStaff',
        'visitDate': _videoCallDt!.toIso8601String(),
        'visitTime': DateFormat.jm().format(_videoCallDt!.toLocal()),
        if (sourceId != null && sourceId.length == 24) 'sourceId': sourceId,
        if (hasPick && (_employeeId?.length ?? 0) == 24)
          'assignedTo': _employeeId,
      });
      if (!mounted) return;
      final ok = res.data is Map ? (res.data as Map)['status'] == true : false;
      if (ok) {
        setState(() => _leadOpen = false);
        _regToast('Request submitted', success: true);
      } else {
        final msg = res.data is Map
            ? (res.data as Map)['message']?.toString()
            : null;
        _regToast(msg ?? 'Submission failed');
      }
    } on DioException catch (e) {
      final msg = e.response?.data is Map
          ? (e.response!.data as Map)['message']?.toString()
          : null;
      if (mounted) _regToast(msg ?? 'Submission failed');
    } finally {
      if (mounted) setState(() => _leadSubmitting = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    final scheme = Theme.of(context).colorScheme;
    final accent = scheme.brightness == Brightness.light
        ? Colors.black
        : scheme.primary;
    final accentFg = scheme.brightness == Brightness.light
        ? Colors.white
        : scheme.onPrimary;
    final p = _project ?? widget.projectData;

    if (_loading) {
      return Scaffold(
        backgroundColor: scheme.surface,
        body: Center(child: CircularProgressIndicator(color: scheme.primary)),
      );
    }
    if (p == null) {
      return Scaffold(
        backgroundColor: scheme.surface,
        appBar: AppBar(
          leading: IconButton(
            icon: const Icon(LucideIcons.arrowLeft),
            onPressed: () => context.pop(),
          ),
        ),
        body: const Center(child: Text('Project not found')),
      );
    }

    final overallPct = _overallProgressPct();
    final title = (p['title'] ?? 'PROJECT').toString();
    final status = (p['status'] ?? 'Ongoing').toString().toUpperCase();
    final hero = _heroImage();

    final exteriorThumb =
        (p['exteriorImages'] is List &&
            (p['exteriorImages'] as List).isNotEmpty)
        ? (p['exteriorImages'] as List).first?.toString()
        : (p['heroImages'] is List && (p['heroImages'] as List).isNotEmpty)
        ? (p['heroImages'] as List).first?.toString()
        : p['heroImage']?.toString();
    final interiorThumb =
        (p['interiorImages'] is List &&
            (p['interiorImages'] as List).isNotEmpty)
        ? (p['interiorImages'] as List).first?.toString()
        : (p['heroImages'] is List && (p['heroImages'] as List).length > 1)
        ? (p['heroImages'] as List)[1]?.toString()
        : (p['heroImages'] is List && (p['heroImages'] as List).isNotEmpty)
        ? (p['heroImages'] as List).first?.toString()
        : p['heroImage']?.toString();

    final cpIdx = ref.watch(cpNavigationIndexProvider);

    return Scaffold(
      backgroundColor: scheme.surface,
      extendBody: true,
      bottomNavigationBar: CpBottomNav(
        currentIndex: cpIdx,
        onTap: (i) {
          context.go('/home');
          ref.read(cpNavigationIndexProvider.notifier).state = i;
        },
      ),
      body: Stack(
        children: [
          CustomScrollView(
            slivers: [
              SliverToBoxAdapter(
                child: Stack(
                  children: [
                    AspectRatio(
                      aspectRatio: 1920 / 1080,
                      child: _projectImage(hero, fit: BoxFit.cover),
                    ),
                    Positioned.fill(
                      child: Container(
                        decoration: const BoxDecoration(
                          gradient: LinearGradient(
                            begin: Alignment.topCenter,
                            end: Alignment.bottomCenter,
                            colors: [
                              Color(0x99000000),
                              Color(0x00000000),
                              Color(0xAA000000),
                            ],
                            stops: [0, 0.55, 1],
                          ),
                        ),
                      ),
                    ),
                    Positioned(
                      top: MediaQuery.of(context).padding.top + 12,
                      left: 16,
                      right: 16,
                      child: Row(
                        mainAxisAlignment: MainAxisAlignment.spaceBetween,
                        children: [
                          _iconPill(
                            icon: LucideIcons.arrowLeft,
                            onTap: () => context.pop(),
                            scheme: scheme,
                          ),
                          Row(
                            children: [
                              _iconPill(
                                icon: LucideIcons.share2,
                                onTap: _shareProject,
                                scheme: scheme,
                              ),
                              const SizedBox(width: 10),
                              _iconPill(
                                // Lucide heart is outline-only; use the filled
                                // Material heart when liked so it visibly fills red.
                                icon: _liked
                                    ? Icons.favorite
                                    : LucideIcons.heart,
                                filled: _liked,
                                activeColor: Colors.red,
                                onTap: _toggleLiked,
                                scheme: scheme,
                              ),
                            ],
                          ),
                        ],
                      ),
                    ),
                    Positioned(
                      left: 24,
                      bottom: 20,
                      child: Container(
                        padding: const EdgeInsets.symmetric(
                          horizontal: 12,
                          vertical: 5,
                        ),
                        decoration: BoxDecoration(
                          color: accent,
                          borderRadius: BorderRadius.circular(999),
                        ),
                        child: Text(
                          status,
                          style: GoogleFonts.dmSerifDisplay(
                            fontSize: 8,
                            fontWeight: FontWeight.w900,
                            letterSpacing: 2,
                            color: accentFg,
                          ),
                        ),
                      ),
                    ),
                  ],
                ),
              ),
              SliverToBoxAdapter(
                child: Transform.translate(
                  offset: const Offset(0, 12),
                  child: Padding(
                    padding: const EdgeInsets.symmetric(horizontal: 20),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.stretch,
                      children: [
                        const SizedBox(height: 6),
                        // Exterior / Interior / 360 thumbnails — below the hero (web parity)
                        Row(
                          children: [
                            _thumbButton(
                              label: 'Exterior',
                              url: exteriorThumb,
                              scheme: scheme,
                              onTap: () {
                                final urls = _stringList(p['exteriorImages']);
                                if (urls.isNotEmpty) {
                                  _openGallery(urls);
                                } else {
                                  final hero = _stringList(p['heroImages']);
                                  final fallback = hero.isNotEmpty
                                      ? hero
                                      : [
                                          p['heroImage']?.toString() ?? '',
                                        ].where((x) => x.isNotEmpty).toList();
                                  _openGallery(fallback);
                                }
                              },
                            ),
                            const SizedBox(width: 10),
                            _thumbButton(
                              label: 'Interior',
                              url: interiorThumb,
                              scheme: scheme,
                              onTap: () {
                                final urls = _stringList(p['interiorImages']);
                                if (urls.isNotEmpty) {
                                  _openGallery(urls);
                                } else {
                                  final hero = _stringList(p['heroImages']);
                                  final fallback = hero.length > 1
                                      ? [hero[1]]
                                      : hero;
                                  _openGallery(fallback);
                                }
                              },
                            ),
                            const SizedBox(width: 10),
                            _vrButton(
                              scheme: scheme,
                              onTap: () {
                                final u = p['threeSixtyUrl']?.toString();
                                if (u != null && u.isNotEmpty) {
                                  _openUrl(u);
                                } else {
                                  ScaffoldMessenger.of(context).showSnackBar(
                                    const SnackBar(
                                      backgroundColor: Color(0xFFE24B4A),
                                      content: Text(
                                        '360° Virtual Tour coming soon',
                                      ),
                                    ),
                                  );
                                }
                              },
                            ),
                          ],
                        ),
                        const SizedBox(height: 24),
                        // Title + location (dark, below hero — web parity)
                        Text(
                          title.toUpperCase(),
                          style: GoogleFonts.dmSerifDisplay(
                            fontSize: 22,
                            fontWeight: FontWeight.w900,
                            letterSpacing: 0.4,
                            color: scheme.onSurface,
                          ),
                        ),
                        const SizedBox(height: 10),
                        Align(
                          alignment: Alignment.centerLeft,
                          child: Container(
                            padding: const EdgeInsets.symmetric(
                              horizontal: 12,
                              vertical: 8,
                            ),
                            decoration: BoxDecoration(
                              borderRadius: BorderRadius.circular(14),
                              border: Border.all(
                                color: scheme.outlineVariant.withValues(
                                  alpha: 0.5,
                                ),
                              ),
                            ),
                            child: Row(
                              mainAxisSize: MainAxisSize.min,
                              children: [
                                Icon(
                                  LucideIcons.mapPin,
                                  size: 13,
                                  color: scheme.onSurface.withValues(
                                    alpha: 0.7,
                                  ),
                                ),
                                const SizedBox(width: 6),
                                Text(
                                  _locationLine(),
                                  style: GoogleFonts.dmSerifDisplay(
                                    fontSize: 11,
                                    fontWeight: FontWeight.w800,
                                    color: scheme.onSurface.withValues(
                                      alpha: 0.85,
                                    ),
                                  ),
                                ),
                              ],
                            ),
                          ),
                        ),
                        const SizedBox(height: 22),
                        // 3 equal stat cards in one row (web parity)
                        Row(
                          children: [
                            Expanded(
                              child: _webStatCard(
                                'Video Call',
                                'Connect Now',
                                LucideIcons.video,
                                scheme,
                                onTap: _openVideoCallSheet,
                              ),
                            ),
                            const SizedBox(width: 12),
                            Expanded(
                              child: _webStatCard(
                                'Completion',
                                '$overallPct%',
                                LucideIcons.calendar,
                                scheme,
                              ),
                            ),
                            const SizedBox(width: 12),
                            Expanded(
                              child: _webStatCard(
                                'Site Visit',
                                'Book Tour',
                                LucideIcons.eye,
                                scheme,
                                onTap: () => context.push(
                                  '/cp/booking/site-visit?projectId=${widget.projectId}',
                                ),
                              ),
                            ),
                          ],
                        ),
                        const SizedBox(height: 22),
                        _sectionTitle('Overview', scheme, accent),
                        const SizedBox(height: 12),
                        Text(
                          'EXPERIENCE THE PINNACLE OF LUXURY LIVING WITH FLOOR-TO-CEILING WINDOWS, ITALIAN MARBLE FLOORING, AND SMART HOME AUTOMATION.',
                          style: GoogleFonts.dmSerifDisplay(
                            fontSize: 11,
                            fontWeight: FontWeight.w700,
                            letterSpacing: -0.2,
                            color: scheme.onSurfaceVariant,
                            height: 1.5,
                          ),
                        ),
                        const SizedBox(height: 18),
                        _assetRow(
                          scheme,
                          icon: LucideIcons.fileText,
                          title: 'Project Flyer',
                          subtitle: 'High Res • PDF',
                          url: p['flyer']?.toString(),
                        ),
                        const SizedBox(height: 10),
                        _assetRow(
                          scheme,
                          icon: LucideIcons.layers,
                          title: 'E-Brochure',
                          subtitle: 'Full Showcase • PDF',
                          url: p['brochure']?.toString(),
                        ),
                        const SizedBox(height: 10),
                        _assetRow(
                          scheme,
                          icon: LucideIcons.image,
                          title: 'Floor Plans',
                          subtitle: 'Images • JPG/PNG',
                          url:
                              (p['plans'] is List &&
                                  (p['plans'] as List).isNotEmpty)
                              ? _stringUrl((p['plans'] as List).first)
                              : null,
                        ),
                        const SizedBox(height: 10),
                        _assetRow(
                          scheme,
                          icon: LucideIcons.video,
                          title: 'Walkthrough',
                          subtitle: 'Cinematic Tour • 4K',
                          url: p['walkthrough']?.toString(),
                          watchOnly: true,
                        ),
                        const SizedBox(height: 26),
                        _sectionTitle('Amenities', scheme, accent),
                        const SizedBox(height: 12),
                        _amenitiesGrid(p, scheme),
                        // Halved (was 26) — tighter gap below Amenities.
                        const SizedBox(height: 13),
                        _sectionTitle('Construction Progress', scheme, accent),
                        const SizedBox(height: 12),
                        _progressCard(p, overallPct, scheme),
                        if (_progress.isNotEmpty) ...[
                          const SizedBox(height: 20),
                          _progressYearHeader(scheme),
                          const SizedBox(height: 16),
                          _progressTimeline(scheme),
                          const SizedBox(height: 24),
                          _phaseTrackingSection(scheme),
                        ],
                        const SizedBox(height: 26),
                        _sectionTitle('Registration', scheme, accent),
                        const SizedBox(height: 12),
                        _registrationCard(scheme),
                        const SizedBox(height: 26),
                        _sectionTitle('Booking', scheme, accent),
                        const SizedBox(height: 12),
                        _buildBookingCtaBar(scheme),
                        const SizedBox(height: 26),
                        _sectionTitle('Location', scheme, accent),
                        const SizedBox(height: 12),
                        _locationCard(p, scheme),
                        const SizedBox(height: 130),
                      ],
                    ),
                  ),
                ),
              ),
            ],
          ),
          if (_leadOpen) _videoCallSheet(scheme),
          if (_galleryOpen) _galleryOverlay(scheme),
        ],
      ),
    );
  }

  Widget _iconPill({
    required IconData icon,
    required VoidCallback onTap,
    required ColorScheme scheme,
    bool filled = false,
    Color? activeColor,
  }) {
    final isLight = scheme.brightness == Brightness.light;
    final accent = isLight ? Colors.black : scheme.primary;
    return Material(
      color: Colors.black.withValues(alpha: 0.25),
      borderRadius: BorderRadius.circular(14),
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(14),
        child: Container(
          width: 42,
          height: 42,
          alignment: Alignment.center,
          decoration: BoxDecoration(
            borderRadius: BorderRadius.circular(14),
            border: Border.all(color: Colors.white.withValues(alpha: 0.18)),
          ),
          child: Icon(
            icon,
            size: 18,
            color: filled ? (activeColor ?? accent) : Colors.white,
          ),
        ),
      ),
    );
  }

  Widget _thumbButton({
    required String label,
    required String? url,
    required ColorScheme scheme,
    required VoidCallback onTap,
  }) {
    return Material(
      color: Colors.transparent,
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(18),
        child: Container(
          width: 66,
          height: 66,
          decoration: BoxDecoration(
            borderRadius: BorderRadius.circular(18),
            border: Border.all(
              color: Colors.white.withValues(alpha: 0.7),
              width: 2,
            ),
            boxShadow: [
              BoxShadow(
                color: Colors.black.withValues(alpha: 0.35),
                blurRadius: 18,
                offset: const Offset(0, 8),
              ),
            ],
          ),
          clipBehavior: Clip.antiAlias,
          child: Stack(
            children: [
              Positioned.fill(child: _projectImage(url, fit: BoxFit.cover)),
              Positioned(
                left: 0,
                right: 0,
                bottom: 6,
                child: Text(
                  label,
                  textAlign: TextAlign.center,
                  style: GoogleFonts.dmSerifDisplay(
                    fontSize: 10,
                    fontWeight: FontWeight.w900,
                    color: Colors.white,
                    shadows: const [
                      Shadow(
                        blurRadius: 6,
                        color: Colors.black,
                        offset: Offset(0, 2),
                      ),
                    ],
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _vrButton({required ColorScheme scheme, required VoidCallback onTap}) {
    return Material(
      color: Colors.white,
      borderRadius: BorderRadius.circular(18),
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(18),
        child: Container(
          width: 66,
          height: 66,
          decoration: BoxDecoration(
            borderRadius: BorderRadius.circular(18),
            border: Border.all(
              color: Colors.white.withValues(alpha: 0.7),
              width: 2,
            ),
            boxShadow: [
              BoxShadow(
                color: Colors.black.withValues(alpha: 0.35),
                blurRadius: 18,
                offset: const Offset(0, 8),
              ),
            ],
          ),
          alignment: Alignment.center,
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              const Icon(LucideIcons.glasses, size: 26),
              const SizedBox(height: 2),
              Text(
                '360°',
                style: GoogleFonts.dmSerifDisplay(
                  fontSize: 9,
                  fontWeight: FontWeight.w900,
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  /// Web-parity stat card: icon on top, centred label + value, fixed height —
  /// used for the Video Call / Completion / Site Visit row.
  Widget _webStatCard(
    String label,
    String value,
    IconData icon,
    ColorScheme scheme, {
    VoidCallback? onTap,
  }) {
    final card = Container(
      height: 128,
      padding: const EdgeInsets.all(10),
      decoration: BoxDecoration(
        color: scheme.surfaceContainerHighest.withValues(alpha: 0.35),
        borderRadius: BorderRadius.circular(24),
        border: Border.all(
          color: scheme.outlineVariant.withValues(alpha: 0.45),
        ),
      ),
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Icon(icon, size: 20, color: scheme.onSurface.withValues(alpha: 0.25)),
          const SizedBox(height: 10),
          Text(
            label.toUpperCase(),
            textAlign: TextAlign.center,
            style: GoogleFonts.dmSerifDisplay(
              fontSize: 8,
              fontWeight: FontWeight.w900,
              letterSpacing: 1.5,
              color: scheme.onSurfaceVariant,
            ),
          ),
          const SizedBox(height: 4),
          Text(
            value,
            textAlign: TextAlign.center,
            maxLines: 2,
            overflow: TextOverflow.ellipsis,
            style: GoogleFonts.dmSerifDisplay(
              fontSize: 13,
              fontWeight: FontWeight.w800,
              color: scheme.onSurface,
              height: 1.1,
            ),
          ),
        ],
      ),
    );
    if (onTap == null) return card;
    return Material(
      color: Colors.transparent,
      borderRadius: BorderRadius.circular(24),
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(24),
        child: card,
      ),
    );
  }

  Widget _sectionTitle(String title, ColorScheme scheme, Color accent) {
    return Row(
      children: [
        Container(width: 24, height: 1, color: accent),
        const SizedBox(width: 10),
        Text(
          title.toUpperCase(),
          style: GoogleFonts.dmSerifDisplay(
            fontSize: 13,
            fontWeight: FontWeight.w900,
            letterSpacing: 3,
            color: scheme.onSurface,
          ),
        ),
      ],
    );
  }

  Widget _assetRow(
    ColorScheme scheme, {
    required IconData icon,
    required String title,
    required String subtitle,
    required String? url,
    bool watchOnly = false,
  }) {
    final isLight = scheme.brightness == Brightness.light;
    final accent = isLight ? Colors.black : scheme.primary;
    final titleColor = scheme.onSurface.withValues(alpha: isLight ? 0.92 : 1);
    final subColor = scheme.onSurface.withValues(alpha: isLight ? 0.68 : 0.6);
    return Container(
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(22),
        border: Border.all(
          color: scheme.outlineVariant.withValues(alpha: isLight ? 0.55 : 0.4),
        ),
        color: scheme.surfaceContainerHighest.withValues(
          alpha: isLight ? 0.12 : 0.25,
        ),
      ),
      child: Row(
        children: [
          Container(
            width: 44,
            height: 44,
            decoration: BoxDecoration(
              borderRadius: BorderRadius.circular(14),
              color: accent.withValues(alpha: isLight ? 0.06 : 0.12),
            ),
            child: Icon(icon, color: accent, size: 20),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  title.toUpperCase(),
                  style: GoogleFonts.dmSerifDisplay(
                    fontSize: 12,
                    fontWeight: FontWeight.w900,
                    letterSpacing: 1.2,
                    color: titleColor,
                  ),
                ),
                const SizedBox(height: 3),
                Text(
                  subtitle.toUpperCase(),
                  style: GoogleFonts.dmSerifDisplay(
                    fontSize: 9,
                    fontWeight: FontWeight.w900,
                    color: subColor,
                    letterSpacing: 1.4,
                  ),
                ),
              ],
            ),
          ),
          const SizedBox(width: 10),
          if (watchOnly)
            // Single filled WATCH button (web parity for Walkthrough).
            FilledButton(
              onPressed: () => _openOrWarn(url, '$title not available'),
              style: FilledButton.styleFrom(
                backgroundColor: scheme.onSurface,
                foregroundColor: scheme.surface,
                padding: const EdgeInsets.symmetric(
                  horizontal: 26,
                  vertical: 14,
                ),
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(12),
                ),
              ),
              child: Text(
                'WATCH',
                style: GoogleFonts.dmSerifDisplay(
                  fontSize: 10,
                  fontWeight: FontWeight.w900,
                  letterSpacing: 1.4,
                ),
              ),
            )
          else
            Row(
              mainAxisSize: MainAxisSize.min,
              children: [
                OutlinedButton(
                  onPressed: () => _openOrWarn(url, '$title not available'),
                  style: OutlinedButton.styleFrom(
                    padding: const EdgeInsets.symmetric(
                      horizontal: 16,
                      vertical: 12,
                    ),
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(12),
                    ),
                    side: BorderSide(
                      color: scheme.onSurface.withValues(
                        alpha: isLight ? 0.65 : 0.22,
                      ),
                    ),
                    foregroundColor: accent,
                    disabledForegroundColor: accent.withValues(alpha: 0.65),
                  ),
                  child: Text(
                    'VIEW',
                    style: GoogleFonts.dmSerifDisplay(
                      fontSize: 10,
                      fontWeight: FontWeight.w900,
                      letterSpacing: 1.2,
                    ),
                  ),
                ),
                const SizedBox(width: 10),
                // Filled download button (web: bg-foreground text-background).
                SizedBox(
                  width: 44,
                  height: 44,
                  child: Material(
                    color: scheme.onSurface,
                    borderRadius: BorderRadius.circular(12),
                    child: InkWell(
                      onTap: () => _openOrWarn(url, '$title not available'),
                      borderRadius: BorderRadius.circular(12),
                      child: Center(
                        child: Icon(
                          LucideIcons.download,
                          size: 18,
                          color: scheme.surface,
                        ),
                      ),
                    ),
                  ),
                ),
              ],
            ),
        ],
      ),
    );
  }

  Widget _amenitiesGrid(Map<String, dynamic> p, ColorScheme scheme) {
    final am = p['amenities'];
    final rawList = am is List ? am : <dynamic>[];
    // Drop blank entries. The data carried empty amenity slots which rendered as
    // invisible grid cells — that's what left the big empty band under "Lobby".
    final list = rawList.where((e) {
      final n = (e is String ? e : (e is Map ? e['name'] : e))
              ?.toString()
              .trim() ??
          '';
      return n.isNotEmpty;
    }).toList();
    if (list.isEmpty) {
      return Text(
        'No amenities listed',
        style: GoogleFonts.dmSerifDisplay(
          color: scheme.onSurfaceVariant,
          fontSize: 11,
        ),
      );
    }
    return GridView.builder(
      shrinkWrap: true,
      physics: const NeverScrollableScrollPhysics(),
      gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
        crossAxisCount: 3,
        crossAxisSpacing: 8,
        mainAxisSpacing: 16,
        // Cap each cell to the icon+label height. Square cells (aspect 1.0) left
        // a tall empty band under a short row (e.g. just "Lobby").
        mainAxisExtent: 88,
      ),
      itemCount: list.length,
      itemBuilder: (context, i) {
        final raw = list[i];
        final name = (raw is String ? raw : (raw is Map ? raw['name'] : raw))
            .toString();
        final iconRaw = raw is Map ? raw['icon']?.toString() : null;
        final iconUrl = (iconRaw != null && iconRaw.isNotEmpty)
            ? ref.read(apiClientProvider).resolveUrl(iconRaw)
            : null;
        // Web parity: gold, name-mapped LuxuryAmenityIcon + Title-case label,
        // no card background.
        return Column(
          mainAxisAlignment: MainAxisAlignment.start,
          children: [
            LuxuryAmenityIcon(name: name, iconUrl: iconUrl, size: 44),
            const SizedBox(height: 10),
            Text(
              name,
              textAlign: TextAlign.center,
              maxLines: 2,
              overflow: TextOverflow.ellipsis,
              style: GoogleFonts.dmSerifDisplay(
                fontSize: 9.5,
                fontWeight: FontWeight.w600,
                height: 1.2,
                color: scheme.onSurface.withValues(alpha: 0.8),
              ),
            ),
          ],
        );
      },
    );
  }

  Widget _progressCard(Map<String, dynamic> p, int pct, ColorScheme scheme) {
    final estRaw = (p['estimatedCompletionDate'] ?? '').toString().trim();
    final est = estRaw.isEmpty ? 'Q1 2028' : estRaw;
    final isLight = scheme.brightness == Brightness.light;
    final accent = isLight ? Colors.black : scheme.primary;
    return Container(
      padding: const EdgeInsets.all(22),
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(28),
        border: Border.all(
          color: scheme.outlineVariant.withValues(alpha: isLight ? 0.10 : 0.35),
        ),
        color: isLight
            ? Colors.white
            : scheme.surfaceContainerHighest.withValues(alpha: 0.4),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: isLight ? 0.10 : 0.45),
            blurRadius: 28,
            offset: const Offset(0, 12),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        mainAxisSize: MainAxisSize.min,
        children: [
          Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Text(
                      'ESTIMATED\nCOMPLETION\nDATE',
                      style: GoogleFonts.montserrat(
                        fontSize: 12,
                        fontWeight: FontWeight.w700,
                        letterSpacing: 1.2,
                        height: 1.3,
                        // Was 0.5 — too faint to read.
                        color: scheme.onSurface.withValues(alpha: 0.72),
                      ),
                    ),
                    const SizedBox(height: 8),
                    Text(
                      est.replaceAll(' ', '\n'),
                      style: GoogleFonts.montserrat(
                        fontSize: 46,
                        fontWeight: FontWeight.w900,
                        letterSpacing: -1.5,
                        height: 1.02,
                        color: isLight ? Colors.black : scheme.onSurface,
                      ),
                    ),
                  ],
                ),
              ),
              const SizedBox(width: 12),
              SizedBox(
                width: 126,
                height: 126,
                child: Stack(
                  children: [
                    Positioned.fill(
                      child: CustomPaint(
                        painter: _DottedProgressRingPainter(
                          progress: pct / 100.0,
                          color: accent,
                          // Darker unfilled track + thicker, longer dashes so
                          // the ring reads clearly (was 1.0/5 — too faint).
                          trackColor: scheme.onSurface.withValues(alpha: 0.22),
                          dotCount: 46,
                          dotRadius: 1.7,
                          dashLength: 7,
                          margin: 7,
                        ),
                      ),
                    ),
                    Positioned.fill(
                      child: Center(
                        child: Column(
                          mainAxisSize: MainAxisSize.min,
                          children: [
                            Text(
                              '$pct%',
                              style: GoogleFonts.montserrat(
                                fontSize: 24,
                                fontWeight: FontWeight.w900,
                                // Was inheriting the theme's navy — force dark.
                                color: isLight ? Colors.black : scheme.onSurface,
                              ),
                            ),
                            Text(
                              'OVERALL',
                              style: GoogleFonts.montserrat(
                                fontSize: 10,
                                fontWeight: FontWeight.w800,
                                color: scheme.onSurface.withValues(alpha: 0.7),
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
            ],
          ),
          const SizedBox(height: 20),
          Text(
            'As the project progresses, significant milestones are reached, showcasing our team’s dedication and expertise. We are steadily moving closer to our completion goal, ensuring quality and safety at every step. Each phase is handled with precision to meet our luxury standards and timeline.',
            maxLines: _showFullProgressDesc ? null : 3,
            overflow: _showFullProgressDesc
                ? TextOverflow.visible
                : TextOverflow.ellipsis,
            style: GoogleFonts.montserrat(
              // Was 12.5 / 0.55 — small and faint. Bigger + darker for
              // readability.
              fontSize: 13.5,
              fontWeight: FontWeight.w500,
              color: scheme.onSurface.withValues(alpha: 0.72),
              height: 1.55,
            ),
          ),
          const SizedBox(height: 10),
          GestureDetector(
            onTap: () =>
                setState(() => _showFullProgressDesc = !_showFullProgressDesc),
            child: Text(
              _showFullProgressDesc ? 'Show less' : 'Read more',
              style: GoogleFonts.montserrat(
                fontSize: 12.5,
                fontWeight: FontWeight.w700,
                color: isLight ? Colors.black : scheme.onSurface,
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _progressTimeline(ColorScheme scheme) {
    final isLight = scheme.brightness == Brightness.light;
    final accent = isLight ? Colors.black : scheme.primary;
    final phases =
        _progress
            .whereType<Map>()
            .map((m) => Map<String, dynamic>.from(m))
            .toList()
          ..sort(
            (a, b) => ((a['phaseOrder'] ?? 0) as num).toInt().compareTo(
              ((b['phaseOrder'] ?? 0) as num).toInt(),
            ),
          );

    return Column(
      children: [
        for (int i = 0; i < phases.length; i++) ...[
          if (i > 0) const SizedBox(height: 16),
          _phaseCard(phases[i], scheme, isLight, accent),
        ],
      ],
    );
  }

  Widget _phaseCard(
    Map<String, dynamic> ph,
    ColorScheme scheme,
    bool isLight,
    Color accent,
  ) {
    final img = (ph['images'] is List && (ph['images'] as List).isNotEmpty)
        ? _stringUrl((ph['images'] as List).first)
        : _stringUrl(ph['image']);
    final status = (ph['status'] ?? 'In Progress').toString();
    final name = (ph['name'] ?? ph['phaseName'] ?? 'Phase').toString();
    final pct = (ph['progressPercent'] is num)
        ? (ph['progressPercent'] as num).toInt().clamp(0, 100)
        : 0;

    Color badgeBg;
    Color badgeFg;
    if (status == 'Completed') {
      badgeBg = Colors.green;
      badgeFg = Colors.white;
    } else if (status == 'In Progress') {
      badgeBg = accent;
      badgeFg = isLight ? Colors.white : scheme.onPrimary;
    } else {
      badgeBg = scheme.surfaceContainerHighest;
      badgeFg = scheme.onSurfaceVariant;
    }

    return Container(
      width: double.infinity,
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(24),
        border: Border.all(
          color: scheme.outlineVariant.withValues(alpha: isLight ? 0.10 : 0.35),
        ),
        color: isLight
            ? Colors.white
            : scheme.surfaceContainerHighest.withValues(alpha: 0.4),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: isLight ? 0.13 : 0.45),
            blurRadius: 26,
            offset: const Offset(0, 12),
          ),
        ],
      ),
      clipBehavior: Clip.antiAlias,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          AspectRatio(
            aspectRatio: 16 / 10,
            child: Stack(
              fit: StackFit.expand,
              children: [
                _projectImage(img, fit: BoxFit.cover),
                Positioned.fill(
                  child: Material(
                    color: Colors.transparent,
                    child: InkWell(
                      onTap: () {
                        final urls = _stringList(ph['images']);
                        if (urls.isNotEmpty) {
                          _openGallery(urls);
                        } else if (img != null && img.isNotEmpty) {
                          _openGallery([img]);
                        } else {
                          ScaffoldMessenger.of(context).showSnackBar(
                            const SnackBar(
                              backgroundColor: Color(0xFFE24B4A),
                              content: Text('No progress images available'),
                            ),
                          );
                        }
                      },
                    ),
                  ),
                ),
                Positioned(
                  top: 12,
                  left: 12,
                  child: Container(
                    padding: const EdgeInsets.symmetric(
                      horizontal: 10,
                      vertical: 6,
                    ),
                    decoration: BoxDecoration(
                      color: badgeBg,
                      borderRadius: BorderRadius.circular(999),
                    ),
                    child: Text(
                      status.toUpperCase(),
                      style: GoogleFonts.montserrat(
                        fontSize: 8,
                        fontWeight: FontWeight.w900,
                        letterSpacing: 1,
                        color: badgeFg,
                      ),
                    ),
                  ),
                ),
                Positioned.fill(
                  child: IgnorePointer(
                    ignoring: true,
                    child: Container(
                      decoration: BoxDecoration(
                        gradient: LinearGradient(
                          begin: Alignment.topCenter,
                          end: Alignment.bottomCenter,
                          colors: [
                            Colors.transparent,
                            Colors.black.withValues(alpha: 0.55),
                          ],
                        ),
                      ),
                    ),
                  ),
                ),
              ],
            ),
          ),
          Padding(
            padding: const EdgeInsets.all(14),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                // Web parity: the project title is the card's heading;
                // the phase name sits next to the small progress ring.
                Text(
                  (_project?['title'] ?? '').toString().toUpperCase(),
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                  style: GoogleFonts.montserrat(
                    fontSize: 11,
                    fontWeight: FontWeight.w900,
                    letterSpacing: 1.2,
                  ),
                ),
                const SizedBox(height: 10),
                Row(
                  children: [
                    SizedBox(
                      width: 42,
                      height: 42,
                      child: Stack(
                        children: [
                          Positioned.fill(
                            child: CircularProgressIndicator(
                              value: pct / 100.0,
                              strokeWidth: 3,
                              color: accent,
                              backgroundColor: scheme.onSurface.withValues(
                                alpha: 0.12,
                              ),
                            ),
                          ),
                          Positioned.fill(
                            child: Center(
                              child: Text(
                                '$pct%',
                                style: GoogleFonts.montserrat(
                                  fontSize: 9,
                                  fontWeight: FontWeight.w900,
                                  color: scheme.onSurfaceVariant,
                                ),
                              ),
                            ),
                          ),
                        ],
                      ),
                    ),
                    const SizedBox(width: 12),
                    Expanded(
                      child: Text(
                        name.toUpperCase(),
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                        style: GoogleFonts.montserrat(
                          fontSize: 10,
                          fontWeight: FontWeight.w800,
                          color: scheme.onSurfaceVariant,
                          letterSpacing: 0.6,
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

  // "2026" year label + horizontal timeline rail with a dot marker, above the
  // phase preview cards. Web hardcodes this year label verbatim, so this
  // mirrors that rather than deriving it from data.
  Widget _progressYearHeader(ColorScheme scheme) {
    final isLight = scheme.brightness == Brightness.light;
    final accent = isLight ? Colors.black : scheme.primary;
    return Row(
      children: [
        Text(
          '2026',
          style: GoogleFonts.montserrat(
            fontSize: 20,
            fontWeight: FontWeight.w900,
            color: accent,
          ),
        ),
        const SizedBox(width: 14),
        Expanded(
          child: Stack(
            alignment: Alignment.centerLeft,
            children: [
              Container(
                height: 1,
                color: scheme.outlineVariant.withValues(alpha: 0.4),
              ),
              Container(
                width: 12,
                height: 12,
                decoration: BoxDecoration(
                  shape: BoxShape.circle,
                  color: scheme.surface,
                  border: Border.all(color: accent, width: 2),
                ),
              ),
            ],
          ),
        ),
      ],
    );
  }

  // "PHASE TRACKING" — header + milestone count badge, then a scrollable list
  // of phase cards (index, name, status dot, percentage, progress bar).
  Widget _phaseTrackingSection(ColorScheme scheme) {
    final isLight = scheme.brightness == Brightness.light;
    final accent = isLight ? Colors.black : scheme.primary;
    final phases =
        _progress
            .whereType<Map>()
            .map((m) => Map<String, dynamic>.from(m))
            .toList()
          ..sort(
            (a, b) => ((a['phaseOrder'] ?? 0) as num).toInt().compareTo(
              ((b['phaseOrder'] ?? 0) as num).toInt(),
            ),
          );

    return Column(
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
                  style: GoogleFonts.montserrat(
                    fontSize: 13,
                    fontWeight: FontWeight.w900,
                    letterSpacing: 2,
                    color: scheme.onSurface,
                  ),
                ),
                const SizedBox(height: 4),
                Text(
                  'REAL-TIME DEVELOPMENT STATUS',
                  style: GoogleFonts.montserrat(
                    fontSize: 8,
                    fontWeight: FontWeight.w800,
                    letterSpacing: 1,
                    color: scheme.onSurfaceVariant,
                  ),
                ),
              ],
            ),
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
              decoration: BoxDecoration(
                borderRadius: BorderRadius.circular(999),
                border: Border.all(color: accent.withValues(alpha: 0.25)),
                color: accent.withValues(alpha: 0.06),
              ),
              child: Text(
                '${phases.length} MILESTONES',
                style: GoogleFonts.montserrat(
                  fontSize: 8,
                  fontWeight: FontWeight.w900,
                  letterSpacing: 1,
                  color: accent,
                ),
              ),
            ),
          ],
        ),
        const SizedBox(height: 16),
        SizedBox(
          height: 112,
          child: ListView.separated(
            scrollDirection: Axis.horizontal,
            itemCount: phases.length,
            separatorBuilder: (_, __) => const SizedBox(width: 12),
            itemBuilder: (context, i) {
              final ph = phases[i];
              final status = (ph['status'] ?? 'In Progress').toString();
              final name = (ph['name'] ?? ph['phaseName'] ?? 'Phase')
                  .toString();
              final pct = (ph['progressPercent'] is num)
                  ? (ph['progressPercent'] as num).toInt().clamp(0, 100)
                  : 0;

              Color dotColor;
              if (status == 'Completed') {
                dotColor = Colors.green;
              } else if (status == 'In Progress') {
                dotColor = accent;
              } else {
                dotColor = scheme.onSurfaceVariant.withValues(alpha: 0.4);
              }

              return Container(
                width: 220,
                padding: const EdgeInsets.all(14),
                decoration: BoxDecoration(
                  borderRadius: BorderRadius.circular(20),
                  border: Border.all(
                    color: scheme.outlineVariant.withValues(alpha: 0.3),
                  ),
                  color: scheme.surfaceContainerHighest.withValues(alpha: 0.14),
                ),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Container(
                          width: 30,
                          height: 30,
                          alignment: Alignment.center,
                          decoration: BoxDecoration(
                            borderRadius: BorderRadius.circular(10),
                            color: scheme.onSurface.withValues(alpha: 0.05),
                            border: Border.all(
                              color: scheme.outlineVariant.withValues(
                                alpha: 0.3,
                              ),
                            ),
                          ),
                          child: Text(
                            (i + 1).toString().padLeft(2, '0'),
                            style: GoogleFonts.montserrat(
                              fontSize: 10,
                              fontWeight: FontWeight.w900,
                              color: scheme.onSurfaceVariant,
                            ),
                          ),
                        ),
                        const SizedBox(width: 10),
                        Expanded(
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Text(
                                name.toUpperCase(),
                                maxLines: 1,
                                overflow: TextOverflow.ellipsis,
                                style: GoogleFonts.montserrat(
                                  fontSize: 10,
                                  fontWeight: FontWeight.w900,
                                  letterSpacing: 0.6,
                                  color: scheme.onSurface,
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
                                    style: GoogleFonts.montserrat(
                                      fontSize: 8,
                                      fontWeight: FontWeight.w800,
                                      letterSpacing: 0.6,
                                      color: scheme.onSurfaceVariant,
                                    ),
                                  ),
                                ],
                              ),
                            ],
                          ),
                        ),
                        Text(
                          '$pct%',
                          style: GoogleFonts.montserrat(
                            fontSize: 15,
                            fontWeight: FontWeight.w900,
                            color: scheme.onSurface,
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 10),
                    ClipRRect(
                      borderRadius: BorderRadius.circular(99),
                      child: LinearProgressIndicator(
                        value: pct / 100.0,
                        minHeight: 4,
                        color: accent,
                        backgroundColor: scheme.onSurface.withValues(
                          alpha: 0.08,
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
    );
  }

  Widget _registrationCard(ColorScheme scheme) {
    final isLight = scheme.brightness == Brightness.light;
    final btnBg = isLight ? Colors.black : Colors.white;
    final btnFg = isLight ? Colors.white : Colors.black;
    final accent = isLight ? Colors.black : scheme.primary;
    return Container(
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(22),
        border: Border.all(color: scheme.outlineVariant.withValues(alpha: 0.4)),
        color: scheme.surfaceContainerHighest.withValues(alpha: 0.22),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          Text(
            'Registration',
            style: GoogleFonts.dmSerifDisplay(
              fontSize: 18,
              fontWeight: FontWeight.w600,
              // Was inheriting the theme's blue/navy — force plain ink (black on
              // light, white on dark).
              color: scheme.onSurface,
            ),
          ),
          const SizedBox(height: 12),
          _cpLabel(scheme, 'Employee Name'),
          const SizedBox(height: 6),
          DropdownButtonFormField<String>(
            initialValue: _regEmployeeId,
            isExpanded: true,
            dropdownColor: isLight ? Colors.white : const Color(0xFF17212F),
            borderRadius: BorderRadius.circular(16),
            elevation: 4,
            iconEnabledColor: scheme.onSurface.withValues(alpha: 0.55),
            style: GoogleFonts.montserrat(
              fontSize: 13,
              fontWeight: FontWeight.w700,
              color: scheme.onSurface,
            ),
            items: [
              DropdownMenuItem(
                value: null,
                child: Text(
                  '— Select —',
                  style: GoogleFonts.montserrat(
                    fontSize: 13,
                    fontWeight: FontWeight.w700,
                    color: scheme.onSurface.withValues(alpha: 0.55),
                  ),
                ),
              ),
              ..._employees.map(
                (e) => DropdownMenuItem(
                  value: e['_id']?.toString(),
                  child: Text(
                    (e['name'] ?? '').toString().toUpperCase(),
                    style: GoogleFonts.montserrat(
                      fontSize: 13,
                      fontWeight: FontWeight.w700,
                      color: scheme.onSurface,
                    ),
                  ),
                ),
              ),
              DropdownMenuItem(
                value: 'other',
                child: Text(
                  '+ OTHER (TYPE NAME)',
                  style: GoogleFonts.montserrat(
                    fontSize: 13,
                    fontWeight: FontWeight.w800,
                    color: const Color(0xFFEAA33E),
                  ),
                ),
              ),
            ],
            onChanged: (v) => setState(() => _regEmployeeId = v),
            decoration: _cpInputDec(scheme, hint: '— Select —'),
          ),
          // Conditional free-text field — only when "Other" is picked (web parity).
          if (_regEmployeeId == 'other') ...[
            const SizedBox(height: 8),
            _cpField(
              controller: _regEmployeeEntered,
              hint: 'TYPE EMPLOYEE NAME HERE',
              scheme: scheme,
            ),
          ],
          const SizedBox(height: 12),
          _cpLabel(scheme, 'Client Name'),
          const SizedBox(height: 6),
          _cpField(
            controller: _regClientName,
            hint: 'CLIENT NAME',
            scheme: scheme,
            errorText: _regNameError,
            // Clear the red state as soon as they start typing.
            onChanged: (v) {
              if (_regNameError != null) setState(() => _regNameError = null);
            },
          ),
          const SizedBox(height: 12),
          _cpLabel(scheme, 'Client Number'),
          const SizedBox(height: 6),
          _cpField(
            controller: _regClientPhone,
            hint: '+91 98653 21250',
            scheme: scheme,
            keyboardType: TextInputType.phone,
            errorText: _regPhoneError,
            onChanged: (v) {
              if (_regPhoneError != null) setState(() => _regPhoneError = null);
            },
          ),
          const SizedBox(height: 12),
          _cpLabel(scheme, 'E-mail'),
          const SizedBox(height: 6),
          _cpField(
            controller: _regClientEmail,
            hint: 'EMAIL ADDRESS',
            scheme: scheme,
            keyboardType: TextInputType.emailAddress,
            errorText: _regEmailError,
            onChanged: (v) {
              if (_regEmailError != null) setState(() => _regEmailError = null);
            },
          ),
          const SizedBox(height: 12),
          _cpLabel(scheme, 'Location'),
          const SizedBox(height: 6),
          _cpField(
            controller: _regLocation,
            hint: 'CITY, COUNTRY',
            scheme: scheme,
          ),
          const SizedBox(height: 14),
          FilledButton(
            onPressed: _regSubmitting ? null : _submitRegistration,
            style: FilledButton.styleFrom(
              backgroundColor: btnBg,
              foregroundColor: btnFg,
              minimumSize: const Size.fromHeight(52),
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(16),
              ),
            ),
            child: _regSubmitting
                ? const SizedBox(
                    width: 18,
                    height: 18,
                    child: CircularProgressIndicator(strokeWidth: 2),
                  )
                : Text(
                    'PROCEED',
                    style: GoogleFonts.dmSerifDisplay(
                      fontWeight: FontWeight.w900,
                      letterSpacing: 3,
                    ),
                  ),
          ),
        ],
      ),
    );
  }

  Widget _buildBookingCtaBar(ColorScheme scheme) {
    final isLight = scheme.brightness == Brightness.light;
    final accent = isLight ? Colors.black : scheme.primary;
    final accentFg = isLight ? Colors.white : scheme.onPrimary;

    return Container(
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: scheme.surfaceContainerHighest.withValues(alpha: 0.3),
        borderRadius: BorderRadius.circular(22),
        border: Border.all(color: scheme.outlineVariant.withValues(alpha: 0.4)),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.05),
            blurRadius: 20,
            offset: const Offset(0, 10),
          ),
        ],
      ),
      child: Row(
        children: [
          Row(
            children: [
              _ctaCircleIcon(
                icon: LucideIcons.phone,
                scheme: scheme,
                onTap: () => _openOrWarn(_project?['contactPhone']),
              ),
              const SizedBox(width: 10),
              _ctaCircleIcon(
                icon: LucideIcons.messageCircle,
                scheme: scheme,
                onTap: () {
                  final phone = (_project?['contactPhone'] ?? '').toString();
                  if (phone.isNotEmpty) {
                    launchUrl(
                      Uri.parse('https://wa.me/$phone'),
                      mode: LaunchMode.externalApplication,
                    );
                  } else {
                    ScaffoldMessenger.of(context).showSnackBar(
                      const SnackBar(
                        backgroundColor: Color(0xFFE24B4A),
                        content: Text('Contact not available'),
                      ),
                    );
                  }
                },
              ),
            ],
          ),
          const SizedBox(width: 16),
          Expanded(
            child: FilledButton(
              onPressed: () => context.push(
                '/cp/booking/site-visit?projectId=${widget.projectId}',
              ),
              style: FilledButton.styleFrom(
                backgroundColor: accent,
                foregroundColor: accentFg,
                minimumSize: const Size.fromHeight(50),
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(16),
                ),
                elevation: 10,
                shadowColor: accent.withValues(alpha: 0.3),
              ),
              child: Text(
                'BOOK VISIT',
                style: GoogleFonts.dmSerifDisplay(
                  fontWeight: FontWeight.w900,
                  fontSize: 12,
                  letterSpacing: 2,
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _ctaCircleIcon({
    required IconData icon,
    required ColorScheme scheme,
    required VoidCallback onTap,
  }) {
    return Material(
      color: Colors.transparent,
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(14),
        child: Container(
          width: 48,
          height: 48,
          decoration: BoxDecoration(
            borderRadius: BorderRadius.circular(14),
            border: Border.all(
              color: scheme.outlineVariant.withValues(alpha: 0.5),
            ),
            color: scheme.surface,
          ),
          child: Icon(icon, size: 20, color: scheme.onSurface),
        ),
      ),
    );
  }

  Widget _locationCard(Map<String, dynamic> p, ColorScheme scheme) {
    const defaultLoc =
        'NA 604, 6th Floor, M4 Aura Heights, Grant Road, Mumbai - 400007';
    bool invalid(String s) =>
        s.isEmpty ||
        ['NA', 'N/A', 'na', 'n/a', 'None', 'none'].contains(s.trim());
    final raw = p['location'];
    final loc = raw is String
        ? raw
        : (raw is Map ? (raw['name'] ?? '').toString() : '');
    final effective = invalid(loc) ? defaultLoc : loc;
    final isLight = scheme.brightness == Brightness.light;
    final btnBg = isLight ? Colors.black : scheme.primary;
    final btnFg = isLight ? Colors.white : scheme.onPrimary;
    final embed =
        'https://www.google.com/maps?q=${Uri.encodeComponent(effective)}&output=embed';

    // Google's embed URL only renders inside an <iframe>; loading it directly
    // shows "must be used in an iframe". Wrap it in a minimal HTML page (this is
    // what the web does with its <iframe>).
    final mapHtml =
        '<!DOCTYPE html><html><head>'
        '<meta name="viewport" content="width=device-width, initial-scale=1.0">'
        '<style>html,body{margin:0;padding:0;height:100%;overflow:hidden;background:transparent;}'
        'iframe{border:0;width:100%;height:100%;}</style></head>'
        '<body><iframe src="$embed" allowfullscreen loading="lazy" '
        'referrerpolicy="no-referrer-when-downgrade"></iframe></body></html>';
    final controller = WebViewController()
      ..setJavaScriptMode(JavaScriptMode.unrestricted)
      ..setBackgroundColor(const Color(0x00000000))
      ..loadHtmlString(mapHtml);

    return Container(
      height: 280,
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(34),
        border: Border.all(
          color: scheme.outlineVariant.withValues(alpha: 0.35),
          width: 4,
        ),
        color: scheme.surfaceContainerHighest.withValues(alpha: 0.18),
      ),
      clipBehavior: Clip.antiAlias,
      child: Stack(
        children: [
          Positioned.fill(child: WebViewWidget(controller: controller)),
          Positioned(
            top: 14,
            right: 14,
            child: FilledButton.icon(
              onPressed: () => _openUrl(
                'https://www.google.com/maps?q=${Uri.encodeComponent(effective)}',
              ),
              icon: const Icon(LucideIcons.mapPin, size: 16),
              label: Text(
                'VIEW ON MAPS',
                style: GoogleFonts.dmSerifDisplay(
                  fontSize: 9,
                  fontWeight: FontWeight.w900,
                  letterSpacing: 2,
                ),
              ),
              style: FilledButton.styleFrom(
                backgroundColor: btnBg,
                foregroundColor: btnFg,
                padding: const EdgeInsets.symmetric(
                  horizontal: 14,
                  vertical: 10,
                ),
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(999),
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _videoCallSheet(ColorScheme scheme) {
    final isLight = scheme.brightness == Brightness.light;
    final btnBg = isLight ? Colors.black : Colors.white;
    final btnFg = isLight ? Colors.white : Colors.black;
    final accent = isLight ? Colors.black : scheme.primary;
    final media = MediaQuery.of(context);
    // Clear the floating bottom nav (the sheet used to butt straight into it),
    // and ride up with the keyboard when a field is focused.
    final bottomGap = media.viewInsets.bottom > 0
        ? media.viewInsets.bottom + 12
        : 96.0;
    return Positioned.fill(
      child: Material(
        color: Colors.black.withValues(alpha: 0.45),
        child: SafeArea(
          child: Align(
            alignment: Alignment.bottomCenter,
            child: Container(
              margin: EdgeInsets.fromLTRB(12, 12, 12, bottomGap),
              // Never swallow the whole screen — it had no height cap at all.
              constraints: BoxConstraints(maxHeight: media.size.height * 0.70),
              padding: const EdgeInsets.fromLTRB(18, 14, 18, 18),
              decoration: BoxDecoration(
                color: scheme.surface,
                // Floats clear of the nav now, so round every corner.
                borderRadius: BorderRadius.circular(28),
                boxShadow: [
                  BoxShadow(
                    color: Colors.black.withValues(alpha: 0.28),
                    blurRadius: 30,
                    offset: const Offset(0, 12),
                  ),
                ],
              ),
              child: SingleChildScrollView(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.stretch,
                  children: [
                    Center(
                      child: Container(
                        width: 40,
                        height: 4,
                        decoration: BoxDecoration(
                          color: scheme.onSurface.withValues(alpha: 0.12),
                          borderRadius: BorderRadius.circular(99),
                        ),
                      ),
                    ),
                    const SizedBox(height: 14),
                    Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(
                              'VIDEO CALL',
                              style: GoogleFonts.dmSerifDisplay(
                                fontSize: 16,
                                fontWeight: FontWeight.w900,
                                letterSpacing: -0.2,
                              ),
                            ),
                            const SizedBox(height: 2),
                            Text(
                              (_project?['title'] ?? '')
                                  .toString()
                                  .toUpperCase(),
                              style: GoogleFonts.dmSerifDisplay(
                                fontSize: 9,
                                fontWeight: FontWeight.w900,
                                letterSpacing: 1.4,
                                color: scheme.onSurfaceVariant,
                              ),
                            ),
                          ],
                        ),
                        IconButton(
                          onPressed: () => setState(() => _leadOpen = false),
                          icon: const Icon(LucideIcons.x),
                        ),
                      ],
                    ),
                    const SizedBox(height: 12),
                    _cpLabel(scheme, 'Select Project'),
                    const SizedBox(height: 6),
                    DropdownButtonFormField<String>(
                      initialValue: _selectedProjectId,
                      isExpanded: true,
                      dropdownColor: scheme.brightness == Brightness.light
                          ? Colors.white
                          : const Color(0xFF17212F),
                      borderRadius: BorderRadius.circular(16),
                      elevation: 4,
                      iconEnabledColor: scheme.onSurface.withValues(
                        alpha: 0.55,
                      ),
                      style: GoogleFonts.montserrat(
                        fontSize: 13,
                        fontWeight: FontWeight.w700,
                        color: scheme.onSurface,
                      ),
                      items: [
                        DropdownMenuItem(
                          value: null,
                          child: Text(
                            '— Select Project —',
                            style: GoogleFonts.montserrat(
                              fontSize: 13,
                              fontWeight: FontWeight.w700,
                              color: scheme.onSurface.withValues(alpha: 0.55),
                            ),
                          ),
                        ),
                        ..._allProjects.map(
                          (proj) => DropdownMenuItem(
                            value: (proj['_id'] ?? proj['id'])?.toString(),
                            child: Text(
                              (proj['title'] ?? '').toString().toUpperCase(),
                              style: GoogleFonts.montserrat(
                                fontSize: 13,
                                fontWeight: FontWeight.w700,
                                color: scheme.onSurface,
                              ),
                            ),
                          ),
                        ),
                      ],
                      onChanged: (v) => setState(() => _selectedProjectId = v),
                      decoration: _cpInputDec(
                        scheme,
                        hint: '— Select Project —',
                      ),
                    ),
                    const SizedBox(height: 12),
                    _cpLabel(scheme, 'Assigned Employee'),
                    const SizedBox(height: 6),
                    DropdownButtonFormField<String>(
                      initialValue: _employeeId,
                      isExpanded: true,
                      dropdownColor: scheme.brightness == Brightness.light
                          ? Colors.white
                          : const Color(0xFF17212F),
                      borderRadius: BorderRadius.circular(16),
                      elevation: 4,
                      iconEnabledColor: scheme.onSurface.withValues(
                        alpha: 0.55,
                      ),
                      style: GoogleFonts.montserrat(
                        fontSize: 13,
                        fontWeight: FontWeight.w700,
                        color: scheme.onSurface,
                      ),
                      items: [
                        DropdownMenuItem(
                          value: null,
                          child: Text(
                            '— Select —',
                            style: GoogleFonts.montserrat(
                              fontSize: 13,
                              fontWeight: FontWeight.w700,
                              color: scheme.onSurface.withValues(alpha: 0.55),
                            ),
                          ),
                        ),
                        ..._employees.map(
                          (e) => DropdownMenuItem(
                            value: e['_id']?.toString(),
                            child: Text(
                              (e['name'] ?? '').toString().toUpperCase(),
                              style: GoogleFonts.montserrat(
                                fontSize: 13,
                                fontWeight: FontWeight.w700,
                                color: scheme.onSurface,
                              ),
                            ),
                          ),
                        ),
                        DropdownMenuItem(
                          value: 'other',
                          child: Text(
                            '+ OTHER (TYPE NAME)',
                            style: GoogleFonts.montserrat(
                              fontSize: 13,
                              fontWeight: FontWeight.w800,
                              color: const Color(0xFFEAA33E),
                            ),
                          ),
                        ),
                      ],
                      onChanged: (v) => setState(() => _employeeId = v),
                      decoration: _cpInputDec(scheme, hint: '— Select —'),
                    ),
                    if (_employeeId == 'other') ...[
                      const SizedBox(height: 8),
                      _cpField(
                        controller: _employeeEntered,
                        hint: 'TYPE EMPLOYEE NAME HERE',
                        scheme: scheme,
                      ),
                    ],
                    const SizedBox(height: 12),
                    _cpLabel(scheme, 'Client Name'),
                    const SizedBox(height: 6),
                    _cpField(
                      controller: _clientName,
                      hint: 'CLIENT NAME',
                      scheme: scheme,
                    ),
                    const SizedBox(height: 12),
                    _cpLabel(scheme, 'Client Number'),
                    const SizedBox(height: 6),
                    _cpField(
                      controller: _clientPhone,
                      hint: 'PHONE NUMBER',
                      scheme: scheme,
                      keyboardType: TextInputType.phone,
                    ),
                    const SizedBox(height: 12),
                    _cpLabel(scheme, 'E-mail'),
                    const SizedBox(height: 6),
                    _cpField(
                      controller: _clientEmail,
                      hint: 'EMAIL ADDRESS',
                      scheme: scheme,
                      keyboardType: TextInputType.emailAddress,
                    ),
                    const SizedBox(height: 12),
                    _cpLabel(scheme, 'Visit Type'),
                    const SizedBox(height: 6),
                    Row(
                      children: [
                        Expanded(
                          child: _visitTypeChip('Video Call', accent, scheme),
                        ),
                        const SizedBox(width: 10),
                        Expanded(
                          child: _visitTypeChip('Site Visit', accent, scheme),
                        ),
                      ],
                    ),
                    const SizedBox(height: 12),
                    _cpLabel(scheme, 'Date & Time'),
                    const SizedBox(height: 6),
                    OutlinedButton.icon(
                      onPressed: _pickVideoDt,
                      icon: const Icon(LucideIcons.calendar),
                      label: Text(
                        _videoCallDt == null
                            ? 'Select date & time'
                            : DateFormat(
                                'd MMM y, h:mm a',
                              ).format(_videoCallDt!.toLocal()),
                      ),
                      style: OutlinedButton.styleFrom(
                        minimumSize: const Size.fromHeight(52),
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(16),
                        ),
                        foregroundColor: accent,
                        side: BorderSide(color: accent.withValues(alpha: 0.55)),
                      ),
                    ),
                    const SizedBox(height: 14),
                    FilledButton(
                      onPressed: _leadSubmitting ? null : _submitVideoCallLead,
                      style: FilledButton.styleFrom(
                        backgroundColor: btnBg,
                        foregroundColor: btnFg,
                        minimumSize: const Size.fromHeight(52),
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(16),
                        ),
                      ),
                      child: _leadSubmitting
                          ? const SizedBox(
                              width: 18,
                              height: 18,
                              child: CircularProgressIndicator(strokeWidth: 2),
                            )
                          : Text(
                              'SUBMIT',
                              style: GoogleFonts.dmSerifDisplay(
                                fontWeight: FontWeight.w900,
                                letterSpacing: 3,
                              ),
                            ),
                    ),
                  ],
                ),
              ),
            ),
          ),
        ),
      ),
    );
  }

  Widget _visitTypeChip(String label, Color accent, ColorScheme scheme) {
    final selected = _visitType == label;
    final isLight = scheme.brightness == Brightness.light;
    return GestureDetector(
      onTap: () => setState(() => _visitType = label),
      child: Container(
        height: 48,
        alignment: Alignment.center,
        decoration: BoxDecoration(
          color: selected
              ? accent
              : scheme.surfaceContainerHighest.withValues(alpha: 0.16),
          borderRadius: BorderRadius.circular(14),
          border: Border.all(
            color: selected
                ? accent
                : scheme.outlineVariant.withValues(alpha: 0.5),
          ),
        ),
        child: Text(
          label.toUpperCase(),
          style: GoogleFonts.dmSerifDisplay(
            fontSize: 11,
            fontWeight: FontWeight.w900,
            letterSpacing: 1,
            color: selected
                ? (isLight ? Colors.white : Colors.black)
                : scheme.onSurface,
          ),
        ),
      ),
    );
  }

  Widget _cpLabel(ColorScheme scheme, String text) {
    // Web labels are uppercase (text-[10.5px] font-black uppercase).
    return Text(
      text.toUpperCase(),
      style: GoogleFonts.dmSerifDisplay(
        fontSize: 10.5,
        fontWeight: FontWeight.w900,
        color: scheme.onSurface,
        letterSpacing: 0.2,
      ),
    );
  }

  /// Registration result toast — red on failure, green on success.
  void _regToast(String message, {bool success = false}) {
    if (!mounted) return;
    ScaffoldMessenger.of(context)
      ..hideCurrentSnackBar()
      ..showSnackBar(
        SnackBar(
          content: Text(
            message,
            style: GoogleFonts.dmSerifDisplay(
              fontSize: 12.5,
              fontWeight: FontWeight.w600,
              color: Colors.white,
            ),
          ),
          backgroundColor: success
              ? const Color(0xFF10B981)
              : const Color(0xFFE24B4A),
          behavior: SnackBarBehavior.floating,
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(12),
          ),
        ),
      );
  }

  Widget _cpField({
    required TextEditingController controller,
    required String hint,
    required ColorScheme scheme,
    TextInputType? keyboardType,
    // When set, the field turns red and shows the reason underneath — the
    // problem stays on the field it belongs to, no snackbar over the page.
    String? errorText,
    ValueChanged<String>? onChanged,
  }) {
    return TextField(
      controller: controller,
      keyboardType: keyboardType,
      onChanged: onChanged,
      decoration: _cpInputDec(scheme, hint: hint, errorText: errorText),
      style: GoogleFonts.dmSerifDisplay(fontWeight: FontWeight.w700),
    );
  }

  InputDecoration _cpInputDec(
    ColorScheme scheme, {
    required String hint,
    String? errorText,
  }) {
    final isLight = scheme.brightness == Brightness.light;
    const errorColor = Color(0xFFE24B4A);
    return InputDecoration(
      hintText: hint,
      errorText: errorText,
      errorStyle: GoogleFonts.dmSerifDisplay(
        fontSize: 11,
        fontWeight: FontWeight.w600,
        color: errorColor,
      ),
      errorBorder: OutlineInputBorder(
        borderRadius: BorderRadius.circular(16),
        borderSide: const BorderSide(color: errorColor, width: 1.5),
      ),
      focusedErrorBorder: OutlineInputBorder(
        borderRadius: BorderRadius.circular(16),
        borderSide: const BorderSide(color: errorColor, width: 1.5),
      ),
      hintStyle: GoogleFonts.dmSerifDisplay(
        fontSize: 10,
        fontWeight: FontWeight.w900,
        letterSpacing: 1.8,
        color: scheme.onSurface.withValues(alpha: isLight ? 0.68 : 0.68),
      ),
      filled: true,
      fillColor: scheme.surfaceContainerHighest.withValues(
        alpha: isLight ? 0.16 : 0.2,
      ),
      border: OutlineInputBorder(
        borderRadius: BorderRadius.circular(16),
        borderSide: BorderSide(
          color: scheme.outlineVariant.withValues(alpha: 0.5),
        ),
      ),
      enabledBorder: OutlineInputBorder(
        borderRadius: BorderRadius.circular(16),
        borderSide: BorderSide(
          color: scheme.outlineVariant.withValues(alpha: 0.5),
        ),
      ),
      focusedBorder: OutlineInputBorder(
        borderRadius: BorderRadius.circular(16),
        borderSide: BorderSide(
          color: scheme.onSurface.withValues(alpha: isLight ? 0.8 : 0.65),
        ),
      ),
      contentPadding: const EdgeInsets.symmetric(horizontal: 14, vertical: 14),
    );
  }

  Widget _galleryOverlay(ColorScheme scheme) {
    final isLight = scheme.brightness == Brightness.light;
    final ctrl = _galleryCtrl ?? PageController(initialPage: _galleryIndex);
    return Positioned.fill(
      child: Material(
        color: Colors.black.withValues(alpha: 0.92),
        child: SafeArea(
          child: Stack(
            children: [
              PageView.builder(
                controller: ctrl,
                itemCount: _gallery.length,
                onPageChanged: (i) => setState(() => _galleryIndex = i),
                itemBuilder: (context, i) {
                  return InteractiveViewer(
                    minScale: 1,
                    maxScale: 4,
                    child: Center(
                      child: _projectImage(
                        _gallery[i],
                        fit: BoxFit.contain,
                        errorWidget: Icon(
                          LucideIcons.imageOff,
                          color: Colors.white.withValues(alpha: 0.7),
                        ),
                      ),
                    ),
                  );
                },
              ),
              Positioned(
                top: 10,
                left: 10,
                child: IconButton(
                  onPressed: () => setState(() => _galleryOpen = false),
                  icon: const Icon(LucideIcons.x),
                  color: Colors.white,
                ),
              ),
              if (_gallery.length > 1)
                Positioned(
                  top: 0,
                  bottom: 0,
                  left: 4,
                  child: Center(
                    child: IconButton(
                      onPressed: _galleryIndex <= 0
                          ? null
                          : () {
                              final next = (_galleryIndex - 1).clamp(
                                0,
                                _gallery.length - 1,
                              );
                              ctrl.animateToPage(
                                next,
                                duration: const Duration(milliseconds: 220),
                                curve: Curves.easeOut,
                              );
                            },
                      icon: const Icon(LucideIcons.chevronLeft),
                      color: Colors.white,
                      disabledColor: Colors.white.withValues(alpha: 0.25),
                    ),
                  ),
                ),
              if (_gallery.length > 1)
                Positioned(
                  top: 0,
                  bottom: 0,
                  right: 4,
                  child: Center(
                    child: IconButton(
                      onPressed: _galleryIndex >= _gallery.length - 1
                          ? null
                          : () {
                              final next = (_galleryIndex + 1).clamp(
                                0,
                                _gallery.length - 1,
                              );
                              ctrl.animateToPage(
                                next,
                                duration: const Duration(milliseconds: 220),
                                curve: Curves.easeOut,
                              );
                            },
                      icon: const Icon(LucideIcons.chevronRight),
                      color: Colors.white,
                      disabledColor: Colors.white.withValues(alpha: 0.25),
                    ),
                  ),
                ),
              Positioned(
                top: 18,
                right: 16,
                child: Text(
                  '${_galleryIndex + 1} / ${_gallery.length}',
                  style: GoogleFonts.dmSerifDisplay(
                    color: Colors.white,
                    fontWeight: FontWeight.w800,
                  ),
                ),
              ),
              if (_gallery.length > 1)
                Positioned(
                  bottom: 12,
                  left: 0,
                  right: 0,
                  child: Row(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: List.generate(
                      _gallery.length.clamp(0, 8),
                      (i) => Container(
                        width: 6,
                        height: 6,
                        margin: const EdgeInsets.symmetric(horizontal: 4),
                        decoration: BoxDecoration(
                          shape: BoxShape.circle,
                          color: i == _galleryIndex
                              ? (isLight ? Colors.white : Colors.white)
                              : Colors.white.withValues(alpha: 0.35),
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
}

/// Dotted progress ring — matches the web "% OVERALL" circle: evenly-spaced
/// round dots around the ring, coloured up to [progress] (0–1), the remainder
/// shown faint in [trackColor].
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
