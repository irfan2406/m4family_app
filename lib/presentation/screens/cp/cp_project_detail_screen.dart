import 'package:cached_network_image/cached_network_image.dart';
import 'package:dio/dio.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:intl/intl.dart';
import 'package:lucide_icons/lucide_icons.dart';
import 'package:m4_mobile/presentation/providers/auth_provider.dart';
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
  ConsumerState<CpProjectDetailScreen> createState() => _CpProjectDetailScreenState();
}

class _CpProjectDetailScreenState extends ConsumerState<CpProjectDetailScreen> {
  bool _loading = true;
  Map<String, dynamic>? _project;
  List<dynamic> _progress = [];
  bool _liked = false;

  // Video call lead dialog
  bool _leadOpen = false;
  bool _leadSubmitting = false;
  List<Map<String, dynamic>> _employees = [];
  String _employeeMode = 'select'; // select | enter
  String? _employeeId;
  final _employeeEntered = TextEditingController();
  final _clientName = TextEditingController();
  final _clientPhone = TextEditingController();
  final _clientEmail = TextEditingController();
  DateTime? _videoCallDt;

  // Registration (interest) form — web section `#registration`
  bool _regSubmitting = false;
  String? _regEmployeeId;
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
    });
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
      final phases = _progress.whereType<Map>().map((m) => Map<String, dynamic>.from(m)).toList();
      phases.sort((a, b) => ((a['phaseOrder'] ?? 0) as num).toInt().compareTo(((b['phaseOrder'] ?? 0) as num).toInt()));
      final last = phases.where((p) {
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
      final ids = (prefs.getStringList('cp_favorites') ?? const <String>[]).toList();
      ids.removeWhere((x) => x == widget.projectId);
      if (next) ids.add(widget.projectId);
      await prefs.setStringList('cp_favorites', ids);
    } catch (_) {}
    if (!mounted) return;
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(content: Text(next ? 'Saved to favorites' : 'Removed from favorites')),
    );
  }

  Future<void> _shareProject() async {
    final title = (_project?['title'] ?? widget.projectData?['title'] ?? 'Project').toString();
    final link = ref.read(apiClientProvider).resolveUrl('/cp/projects/${widget.projectId}');
    await Share.share('Check out $title on M4 Family!\n$link');
  }

  void _openOrWarn(String? url, [String message = 'Not available']) {
    if (url == null || url.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text(message)));
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
    // fetch employees once (CP CRM)
    if (_employees.isEmpty) {
      try {
        final res = await ref.read(apiClientProvider).getCpEmployees();
        final body = res.data;
        if (body is Map && body['status'] == true && body['data'] is List) {
          _employees = (body['data'] as List).map((e) => Map<String, dynamic>.from(e as Map)).toList();
        }
      } catch (_) {}
    }

    // prefill with auth user
    final u = ref.read(authProvider).user;
    if (u != null) {
      _clientName.text = (u['fullName'] ?? '${u['firstName'] ?? ''} ${u['lastName'] ?? ''}').toString().trim();
      _clientPhone.text = (u['phone'] ?? '').toString();
      _clientEmail.text = (u['email'] ?? '').toString();
    }

    if (mounted) setState(() => _leadOpen = true);
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
          _employees = (body['data'] as List).map((e) => Map<String, dynamic>.from(e as Map)).toList();
        }
      } catch (_) {}
    }

    final typedEmp = _regEmployeeEntered.text.trim();
    final hasPick = _regEmployeeId != null && _regEmployeeId!.isNotEmpty;
    if (!typedEmp.isNotEmpty && !hasPick) {
      ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('Enter employee name or select from list')));
      return;
    }
    if (_regClientName.text.trim().isEmpty || _regClientPhone.text.trim().isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('Enter client name and number')));
      return;
    }
    if (_regClientEmail.text.trim().isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('Enter email address')));
      return;
    }

    final selectName = hasPick
        ? _employees.firstWhere((e) => e['_id']?.toString() == _regEmployeeId, orElse: () => {})['name']?.toString() ?? ''
        : '';
    final employeeName = selectName.isNotEmpty ? selectName : typedEmp;
    final notesStaff = typedEmp.isNotEmpty && hasPick
        ? 'Entered: $typedEmp • Selected: $selectName'
        : typedEmp.isNotEmpty
            ? 'Staff (entered): $typedEmp'
            : 'Staff (selected): $selectName';
    final loc = _regLocation.text.trim();

    final sourceId = ref.read(authProvider).user?['_id']?.toString() ?? ref.read(authProvider).user?['id']?.toString();

    setState(() => _regSubmitting = true);
    try {
      final api = ref.read(apiClientProvider);
      final res = await api.submitLead({
        'name': _regClientName.text.trim(),
        'email': _regClientEmail.text.trim(),
        'phone': _regClientPhone.text.trim(),
        'projectId': p['_id']?.toString() ?? p['id']?.toString() ?? widget.projectId,
        'project': (p['title'] ?? 'Project').toString(),
        'interest': 'Registration',
        'status': 'new',
        'source': 'cp',
        'message':
            'CP portal registration • Employee: $employeeName • Project: ${(p['title'] ?? 'N/A').toString()}${loc.isNotEmpty ? ' • Location: $loc' : ''}',
        'notes': 'Registration form (CP) • $notesStaff',
        if (loc.isNotEmpty) 'location': loc,
        if (sourceId != null && sourceId.length == 24) 'sourceId': sourceId,
        if (hasPick && (_regEmployeeId?.length ?? 0) == 24) 'assignedTo': _regEmployeeId,
      });
      if (!mounted) return;
      final ok = res.data is Map ? (res.data as Map)['status'] == true : false;
      if (ok) {
        ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('Registration submitted')));
        _regEmployeeEntered.clear();
        _regClientName.clear();
        _regClientPhone.clear();
        _regClientEmail.clear();
        _regLocation.clear();
        setState(() => _regEmployeeId = null);
      } else {
        final msg = res.data is Map ? (res.data as Map)['message']?.toString() : null;
        ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text(msg ?? 'Submission failed')));
      }
    } on DioException catch (e) {
      final msg = e.response?.data is Map ? (e.response!.data as Map)['message']?.toString() : null;
      if (mounted) ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text(msg ?? 'Submission failed')));
    } finally {
      if (mounted) setState(() => _regSubmitting = false);
    }
  }

  Future<void> _pickVideoDt() async {
    final d = await showDatePicker(
      context: context,
      firstDate: DateTime.now(),
      lastDate: DateTime.now().add(const Duration(days: 365)),
      initialDate: DateTime.now(),
    );
    if (d == null || !mounted) return;
    final t = await showTimePicker(context: context, initialTime: TimeOfDay.now());
    if (t == null || !mounted) return;
    setState(() => _videoCallDt = DateTime(d.year, d.month, d.day, t.hour, t.minute));
  }

  Future<void> _submitVideoCallLead() async {
    final p = _project ?? widget.projectData;
    if (p == null) return;

    final typedEmp = _employeeEntered.text.trim();
    final hasPick = _employeeId != null && _employeeId!.isNotEmpty;
    if (!typedEmp.isNotEmpty && !hasPick) {
      ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('Enter or select employee name')));
      return;
    }
    if (_clientName.text.trim().isEmpty || _clientPhone.text.trim().isEmpty || _clientEmail.text.trim().isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('Enter client name, number, and email')));
      return;
    }
    if (_videoCallDt == null) {
      ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('Select date and time')));
      return;
    }

    final selectName = hasPick
        ? _employees.firstWhere((e) => e['_id']?.toString() == _employeeId, orElse: () => {})['name']?.toString() ?? ''
        : '';
    final employeeName = selectName.isNotEmpty ? selectName : typedEmp;
    final notesStaff = typedEmp.isNotEmpty && hasPick ? 'Entered: $typedEmp • Selected: $selectName' : typedEmp.isNotEmpty ? 'Staff (entered): $typedEmp' : 'Staff (selected): $selectName';

    final sourceId = ref.read(authProvider).user?['_id']?.toString() ?? ref.read(authProvider).user?['id']?.toString();

    setState(() => _leadSubmitting = true);
    try {
      final api = ref.read(apiClientProvider);
      final res = await api.submitLead({
        'name': _clientName.text.trim(),
        'phone': _clientPhone.text.trim(),
        'email': _clientEmail.text.trim(),
        'projectId': p['_id']?.toString() ?? p['id']?.toString() ?? widget.projectId,
        'project': (p['title'] ?? 'Project').toString(),
        'interest': 'Video Call',
        'status': 'new',
        'source': 'cp',
        'message': 'CP video call • Employee: $employeeName • ${(p['title'] ?? '').toString()}',
        'notes': 'Video call booking • $notesStaff',
        'visitDate': _videoCallDt!.toIso8601String(),
        'visitTime': DateFormat.jm().format(_videoCallDt!.toLocal()),
        if (sourceId != null && sourceId.length == 24) 'sourceId': sourceId,
        if (hasPick && (_employeeId?.length ?? 0) == 24) 'assignedTo': _employeeId,
      });
      if (!mounted) return;
      final ok = res.data is Map ? (res.data as Map)['status'] == true : false;
      if (ok) {
        setState(() => _leadOpen = false);
        ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('Request submitted')));
      } else {
        final msg = res.data is Map ? (res.data as Map)['message']?.toString() : null;
        ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text(msg ?? 'Submission failed')));
      }
    } on DioException catch (e) {
      final msg = e.response?.data is Map ? (e.response!.data as Map)['message']?.toString() : null;
      if (mounted) ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text(msg ?? 'Submission failed')));
    } finally {
      if (mounted) setState(() => _leadSubmitting = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    final scheme = Theme.of(context).colorScheme;
    final accent = scheme.brightness == Brightness.light ? Colors.black : scheme.primary;
    final accentFg = scheme.brightness == Brightness.light ? Colors.white : scheme.onPrimary;
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
        appBar: AppBar(leading: IconButton(icon: const Icon(LucideIcons.arrowLeft), onPressed: () => context.pop())),
        body: const Center(child: Text('Project not found')),
      );
    }

    final overallPct = _overallProgressPct();
    final title = (p['title'] ?? 'PROJECT').toString();
    final status = (p['status'] ?? 'Ongoing').toString().toUpperCase();
    final hero = _heroImage();

    final exteriorThumb = (p['exteriorImages'] is List && (p['exteriorImages'] as List).isNotEmpty)
        ? (p['exteriorImages'] as List).first?.toString()
        : (p['heroImages'] is List && (p['heroImages'] as List).isNotEmpty)
            ? (p['heroImages'] as List).first?.toString()
            : p['heroImage']?.toString();
    final interiorThumb = (p['interiorImages'] is List && (p['interiorImages'] as List).isNotEmpty)
        ? (p['interiorImages'] as List).first?.toString()
        : (p['heroImages'] is List && (p['heroImages'] as List).length > 1)
            ? (p['heroImages'] as List)[1]?.toString()
            : (p['heroImages'] is List && (p['heroImages'] as List).isNotEmpty)
                ? (p['heroImages'] as List).first?.toString()
                : p['heroImage']?.toString();

    return Scaffold(
      backgroundColor: scheme.surface,
      body: Stack(
        children: [
          CustomScrollView(
            slivers: [
              SliverToBoxAdapter(
                child: Stack(
                  children: [
                    AspectRatio(
                      aspectRatio: 0.82,
                      child: CachedNetworkImage(
                        imageUrl: hero,
                        fit: BoxFit.cover,
                        errorWidget: (_, __, ___) => Container(color: scheme.surfaceContainerHighest),
                      ),
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
                                icon: LucideIcons.heart,
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
                      left: 20,
                      right: 20,
                      bottom: 90,
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Container(
                            padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                            decoration: BoxDecoration(
                              color: accent,
                              borderRadius: BorderRadius.circular(999),
                            ),
                            child: Text(
                              status,
                              style: GoogleFonts.montserrat(fontSize: 9, fontWeight: FontWeight.w900, letterSpacing: 2, color: accentFg),
                            ),
                          ),
                          const SizedBox(height: 6),
                          Text(
                            title.toUpperCase(),
                            maxLines: 2,
                            overflow: TextOverflow.ellipsis,
                            style: GoogleFonts.montserrat(
                              fontSize: 20,
                              fontWeight: FontWeight.w900,
                              letterSpacing: 0.8,
                              color: Colors.white,
                            ),
                          ),
                          const SizedBox(height: 10),
                          Container(
                            padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
                            decoration: BoxDecoration(
                              color: Colors.black.withValues(alpha: 0.35),
                              borderRadius: BorderRadius.circular(14),
                              border: Border.all(color: Colors.white.withValues(alpha: 0.15)),
                            ),
                            child: Row(
                              mainAxisSize: MainAxisSize.min,
                              children: [
                                const Icon(LucideIcons.mapPin, size: 14, color: Colors.white70),
                                const SizedBox(width: 6),
                                Flexible(
                                  child: Text(
                                    _locationLine(),
                                    overflow: TextOverflow.ellipsis,
                                    style: GoogleFonts.montserrat(fontSize: 10, fontWeight: FontWeight.w800, color: Colors.white),
                                  ),
                                ),
                              ],
                            ),
                          ),
                        ],
                      ),
                    ),
                    Positioned(
                      left: 20,
                      bottom: 18,
                      child: Row(
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
                                final fallback = hero.isNotEmpty ? hero : [p['heroImage']?.toString() ?? ''].where((x) => x.isNotEmpty).toList();
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
                                final fallback = hero.length > 1 ? [hero[1]] : hero;
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
                                  const SnackBar(content: Text('360° Virtual Tour coming soon')),
                                );
                              }
                            },
                          ),
                        ],
                      ),
                    ),
                  ],
                ),
              ),
              SliverToBoxAdapter(
                child: Transform.translate(
                  offset: const Offset(0, -10),
                  child: Padding(
                    padding: const EdgeInsets.symmetric(horizontal: 20),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.stretch,
                      children: [
                        const SizedBox(height: 6),
                        GridView.count(
                          crossAxisCount: 2,
                          shrinkWrap: true,
                          physics: const NeverScrollableScrollPhysics(),
                          crossAxisSpacing: 8,
                          mainAxisSpacing: 8,
                          childAspectRatio: 2.35,
                          children: [
                            _statCard('Completion', '$overallPct%', scheme),
                            _actionCard('Video Call', 'Connect Now', LucideIcons.video, scheme, onTap: _openVideoCallSheet),
                            _actionCard(
                              'Site Visit',
                              'Book Private Tour',
                              LucideIcons.eye,
                              scheme,
                              onTap: () => context.push('/cp/booking/site-visit?projectId=${widget.projectId}'),
                            ),
                          ],
                        ),
                        const SizedBox(height: 22),
                        _sectionTitle('Overview', scheme, accent),
                        const SizedBox(height: 12),
                        Text(
                          '${(p['description'] ?? '').toString()} Experience the pinnacle of luxury living with floor-to-ceiling windows, Italian marble flooring, and smart home automation.',
                          style: GoogleFonts.montserrat(
                            fontSize: 14,
                            fontWeight: FontWeight.w700,
                            color: scheme.onSurface.withValues(alpha: 0.78),
                            height: 1.6,
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
                          url: (p['plans'] is List && (p['plans'] as List).isNotEmpty) ? _stringUrl((p['plans'] as List).first) : null,
                        ),
                        const SizedBox(height: 10),
                        _assetRow(
                          scheme,
                          icon: LucideIcons.video,
                          title: 'Walkthrough',
                          subtitle: 'Cinematic Tour • 4K',
                          url: p['walkthrough']?.toString(),
                        ),
                        const SizedBox(height: 26),
                        _sectionTitle('Amenities', scheme, accent),
                        const SizedBox(height: 12),
                        _amenitiesGrid(p, scheme),
                        const SizedBox(height: 26),
                        _sectionTitle('Construction Progress', scheme, accent),
                        const SizedBox(height: 12),
                        _progressCard(p, overallPct, scheme),
                        if (_progress.isNotEmpty) ...[
                          const SizedBox(height: 16),
                          _progressTimeline(scheme),
                        ],
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
                        const SizedBox(height: 90),
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
          child: Icon(icon, size: 18, color: filled ? (activeColor ?? accent) : Colors.white),
        ),
      ),
    );
  }

  Widget _thumbButton({required String label, required String? url, required ColorScheme scheme, required VoidCallback onTap}) {
    final resolved = url == null ? null : ref.read(apiClientProvider).resolveUrl(url);
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
            border: Border.all(color: Colors.white.withValues(alpha: 0.7), width: 2),
            boxShadow: [BoxShadow(color: Colors.black.withValues(alpha: 0.35), blurRadius: 18, offset: const Offset(0, 8))],
          ),
          clipBehavior: Clip.antiAlias,
          child: Stack(
            children: [
              Positioned.fill(
                child: resolved == null
                    ? Container(color: scheme.surfaceContainerHighest)
                    : CachedNetworkImage(imageUrl: resolved, fit: BoxFit.cover),
              ),
              Positioned(
                left: 0,
                right: 0,
                bottom: 6,
                child: Text(
                  label,
                  textAlign: TextAlign.center,
                  style: GoogleFonts.montserrat(fontSize: 10, fontWeight: FontWeight.w900, color: Colors.white, shadows: const [
                    Shadow(blurRadius: 6, color: Colors.black, offset: Offset(0, 2)),
                  ]),
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
            border: Border.all(color: Colors.white.withValues(alpha: 0.7), width: 2),
            boxShadow: [BoxShadow(color: Colors.black.withValues(alpha: 0.35), blurRadius: 18, offset: const Offset(0, 8))],
          ),
          alignment: Alignment.center,
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              const Icon(LucideIcons.glasses, size: 26),
              const SizedBox(height: 2),
              Text('360°', style: GoogleFonts.montserrat(fontSize: 9, fontWeight: FontWeight.w900)),
            ],
          ),
        ),
      ),
    );
  }

  Widget _statCard(String label, String value, ColorScheme scheme) {
    return Container(
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(14),
        border: Border.all(color: scheme.outlineVariant.withValues(alpha: 0.45)),
        color: scheme.surfaceContainerHighest.withValues(alpha: 0.35),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Text(label.toUpperCase(), style: GoogleFonts.montserrat(fontSize: 7, fontWeight: FontWeight.w900, letterSpacing: 2, color: scheme.onSurfaceVariant)),
          const SizedBox(height: 3),
          Text(value, style: GoogleFonts.montserrat(fontSize: 11, fontWeight: FontWeight.w900, color: scheme.onSurface)),
        ],
      ),
    );
  }

  Widget _actionCard(String label, String value, IconData icon, ColorScheme scheme, {required VoidCallback onTap}) {
    final isLight = scheme.brightness == Brightness.light;
    final accent = isLight ? Colors.black : scheme.primary;
    return Material(
      color: scheme.surfaceContainerHighest.withValues(alpha: 0.35),
      borderRadius: BorderRadius.circular(14),
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(14),
        child: Container(
          padding: const EdgeInsets.all(12),
          decoration: BoxDecoration(
            borderRadius: BorderRadius.circular(14),
            border: Border.all(color: scheme.primary.withValues(alpha: 0.18)),
          ),
          child: Row(
            children: [
              Container(
                width: 34,
                height: 34,
                decoration: BoxDecoration(
                  borderRadius: BorderRadius.circular(12),
                  color: accent.withValues(alpha: 0.08),
                ),
                child: Icon(icon, size: 18, color: accent),
              ),
              const SizedBox(width: 10),
              Expanded(
                child: Column(
                  mainAxisAlignment: MainAxisAlignment.center,
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(label.toUpperCase(), style: GoogleFonts.montserrat(fontSize: 7, fontWeight: FontWeight.w900, letterSpacing: 2, color: scheme.onSurfaceVariant)),
                    const SizedBox(height: 3),
                    Text(value, style: GoogleFonts.montserrat(fontSize: 10, fontWeight: FontWeight.w900, color: scheme.onSurface)),
                  ],
                ),
              ),
              Icon(LucideIcons.chevronRight, size: 18, color: scheme.onSurfaceVariant.withValues(alpha: 0.6)),
            ],
          ),
        ),
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
          style: GoogleFonts.montserrat(fontSize: 13, fontWeight: FontWeight.w900, letterSpacing: 3, color: scheme.onSurface),
        ),
      ],
    );
  }

  Widget _assetRow(ColorScheme scheme, {required IconData icon, required String title, required String subtitle, required String? url}) {
    final isLight = scheme.brightness == Brightness.light;
    final accent = isLight ? Colors.black : scheme.primary;
    final titleColor = scheme.onSurface.withValues(alpha: isLight ? 0.92 : 1);
    final subColor = scheme.onSurface.withValues(alpha: isLight ? 0.55 : 0.6);
    return Container(
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(22),
        border: Border.all(color: scheme.outlineVariant.withValues(alpha: isLight ? 0.55 : 0.4)),
        color: scheme.surfaceContainerHighest.withValues(alpha: isLight ? 0.12 : 0.25),
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
                  style: GoogleFonts.montserrat(
                    fontSize: 12,
                    fontWeight: FontWeight.w900,
                    letterSpacing: 1.2,
                    color: titleColor,
                  ),
                ),
                const SizedBox(height: 3),
                Text(
                  subtitle.toUpperCase(),
                  style: GoogleFonts.montserrat(
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
          Row(
            mainAxisSize: MainAxisSize.min,
            children: [
              OutlinedButton(
                onPressed: () => _openOrWarn(url, '$title not available'),
                style: OutlinedButton.styleFrom(
                  padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
                  shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                  side: BorderSide(color: scheme.onSurface.withValues(alpha: isLight ? 0.65 : 0.22)),
                  foregroundColor: accent,
                  disabledForegroundColor: accent.withValues(alpha: 0.65),
                ),
                child: Text('VIEW', style: GoogleFonts.montserrat(fontSize: 10, fontWeight: FontWeight.w900, letterSpacing: 1.2)),
              ),
              const SizedBox(width: 10),
              SizedBox(
                width: 44,
                height: 44,
                child: OutlinedButton(
                  onPressed: () => _openOrWarn(url, '$title not available'),
                  style: OutlinedButton.styleFrom(
                    padding: EdgeInsets.zero,
                    shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                    side: BorderSide(color: scheme.onSurface.withValues(alpha: isLight ? 0.65 : 0.22)),
                    foregroundColor: accent,
                    disabledForegroundColor: accent.withValues(alpha: 0.65),
                  ),
                  child: Icon(LucideIcons.download, size: 18, color: scheme.onSurface),
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _amenitiesGrid(Map<String, dynamic> p, ColorScheme scheme) {
    final isLight = scheme.brightness == Brightness.light;
    final accent = isLight ? Colors.black : scheme.primary;
    final am = p['amenities'];
    final list = am is List ? am : <dynamic>[];
    if (list.isEmpty) {
      return Text('No amenities listed', style: GoogleFonts.montserrat(color: scheme.onSurfaceVariant, fontSize: 11));
    }
    return GridView.builder(
      shrinkWrap: true,
      physics: const NeverScrollableScrollPhysics(),
      gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
        crossAxisCount: 3,
        crossAxisSpacing: 10,
        mainAxisSpacing: 10,
      ),
      itemCount: list.length.clamp(0, 12),
      itemBuilder: (context, i) {
        final raw = list[i];
        final name = (raw is String ? raw : (raw is Map ? raw['name'] : raw)).toString();
        return Container(
          decoration: BoxDecoration(
            borderRadius: BorderRadius.circular(26),
            border: Border.all(color: scheme.outlineVariant.withValues(alpha: 0.35)),
            color: scheme.surfaceContainerHighest.withValues(alpha: 0.22),
          ),
          padding: const EdgeInsets.all(12),
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Container(
                width: 44,
                height: 44,
                decoration: BoxDecoration(
                  shape: BoxShape.circle,
                  color: accent.withValues(alpha: 0.08),
                ),
                child: Icon(LucideIcons.sparkles, size: 18, color: scheme.onSurfaceVariant),
              ),
              const SizedBox(height: 10),
              Text(
                name.toUpperCase(),
                textAlign: TextAlign.center,
                maxLines: 2,
                overflow: TextOverflow.ellipsis,
                style: GoogleFonts.montserrat(fontSize: 8, fontWeight: FontWeight.w900, letterSpacing: 1.1, color: scheme.onSurface.withValues(alpha: 0.8)),
              ),
            ],
          ),
        );
      },
    );
  }

  Widget _progressCard(Map<String, dynamic> p, int pct, ColorScheme scheme) {
    final est = (p['estimatedCompletionDate'] ?? 'Q1 2028').toString();
    final isLight = scheme.brightness == Brightness.light;
    final accent = isLight ? Colors.black : scheme.primary;
    return Container(
      padding: const EdgeInsets.all(18),
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(34),
        border: Border.all(color: scheme.outlineVariant.withValues(alpha: 0.35)),
        color: scheme.surfaceContainerHighest.withValues(alpha: 0.22),
      ),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  'ESTIMATED COMPLETION DATE',
                  style: GoogleFonts.montserrat(
                    fontSize: 9,
                    fontWeight: FontWeight.w800,
                    letterSpacing: 2,
                    color: accent.withValues(alpha: 0.7),
                  ),
                ),
                const SizedBox(height: 6),
                Text(
                  est,
                  style: GoogleFonts.montserrat(
                    fontSize: 28,
                    fontWeight: FontWeight.w900,
                    letterSpacing: -1,
                    color: isLight ? Colors.black : scheme.onSurface,
                  ),
                ),
                const SizedBox(height: 14),
                Text(
                  'As the project progresses, significant milestones are reached, showcasing our team’s dedication and expertise.',
                  style: GoogleFonts.montserrat(fontSize: 11, fontWeight: FontWeight.w600, color: scheme.onSurfaceVariant, height: 1.6),
                ),
              ],
            ),
          ),
          const SizedBox(width: 16),
          SizedBox(
            width: 110,
            height: 110,
            child: Stack(
              children: [
                Positioned.fill(
                  child: CircularProgressIndicator(
                    value: pct / 100.0,
                    strokeWidth: 4,
                    color: accent,
                    backgroundColor: scheme.onSurface.withValues(alpha: 0.08),
                  ),
                ),
                Positioned.fill(
                  child: Center(
                    child: Column(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        Text('$pct%', style: GoogleFonts.montserrat(fontSize: 22, fontWeight: FontWeight.w900)),
                        Text('OVERALL', style: GoogleFonts.montserrat(fontSize: 9, fontWeight: FontWeight.w800, color: scheme.onSurfaceVariant, letterSpacing: 1)),
                      ],
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

  Widget _progressTimeline(ColorScheme scheme) {
    final isLight = scheme.brightness == Brightness.light;
    final accent = isLight ? Colors.black : scheme.primary;
    final phases = _progress.whereType<Map>().map((m) => Map<String, dynamic>.from(m)).toList()
      ..sort((a, b) => ((a['phaseOrder'] ?? 0) as num).toInt().compareTo(((b['phaseOrder'] ?? 0) as num).toInt()));

    return SizedBox(
      height: 260,
      child: ListView.separated(
        scrollDirection: Axis.horizontal,
        padding: const EdgeInsets.symmetric(horizontal: 2),
        itemCount: phases.length,
        separatorBuilder: (_, __) => const SizedBox(width: 12),
        itemBuilder: (context, i) {
          final ph = phases[i];
          final img = (ph['images'] is List && (ph['images'] as List).isNotEmpty)
              ? _stringUrl((ph['images'] as List).first)
              : _stringUrl(ph['image']);
          final status = (ph['status'] ?? 'In Progress').toString();
          final name = (ph['name'] ?? ph['phaseName'] ?? 'Phase').toString();
          final pct = (ph['progressPercent'] is num) ? (ph['progressPercent'] as num).toInt().clamp(0, 100) : 0;

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
            width: 240,
            decoration: BoxDecoration(
              borderRadius: BorderRadius.circular(26),
              border: Border.all(color: scheme.outlineVariant.withValues(alpha: 0.35)),
              color: scheme.surfaceContainerHighest.withValues(alpha: 0.22),
            ),
            clipBehavior: Clip.antiAlias,
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                Expanded(
                  child: Stack(
                    fit: StackFit.expand,
                    children: [
                      if (img != null && img.isNotEmpty)
                        CachedNetworkImage(
                          imageUrl: ref.read(apiClientProvider).resolveUrl(img),
                          fit: BoxFit.cover,
                          errorWidget: (_, __, ___) => Container(color: scheme.surfaceContainerHighest),
                        )
                      else
                        Container(color: scheme.surfaceContainerHighest),
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
                                  const SnackBar(content: Text('No progress images available')),
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
                          padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
                          decoration: BoxDecoration(color: badgeBg, borderRadius: BorderRadius.circular(999)),
                          child: Text(
                            status.toUpperCase(),
                            style: GoogleFonts.montserrat(fontSize: 8, fontWeight: FontWeight.w900, letterSpacing: 1, color: badgeFg),
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
                                colors: [Colors.transparent, Colors.black.withValues(alpha: 0.55)],
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
                      Text(
                        name.toUpperCase(),
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                        style: GoogleFonts.montserrat(fontSize: 11, fontWeight: FontWeight.w900, letterSpacing: 1.2),
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
                                    backgroundColor: scheme.onSurface.withValues(alpha: 0.12),
                                  ),
                                ),
                                Positioned.fill(
                                  child: Center(
                                    child: Text(
                                      '$pct%',
                                      style: GoogleFonts.montserrat(fontSize: 9, fontWeight: FontWeight.w900, color: scheme.onSurfaceVariant),
                                    ),
                                  ),
                                ),
                              ],
                            ),
                          ),
                          const SizedBox(width: 12),
                          Expanded(
                            child: Text(
                              (_project?['title'] ?? '').toString(),
                              maxLines: 1,
                              overflow: TextOverflow.ellipsis,
                              style: GoogleFonts.montserrat(fontSize: 10, fontWeight: FontWeight.w800, color: scheme.onSurfaceVariant, letterSpacing: 0.6),
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
          Text('Registration', style: GoogleFonts.montserrat(fontSize: 18, fontWeight: FontWeight.w600)),
          const SizedBox(height: 12),
          _cpLabel(scheme, 'Enter employee name'),
          const SizedBox(height: 6),
          _cpField(controller: _regEmployeeEntered, hint: 'EMPLOYEE NAME', scheme: scheme),
          const SizedBox(height: 12),
          _cpLabel(scheme, 'Name of the employee'),
          const SizedBox(height: 2),
          Text(
            'SELECT A NAME FROM THE LIST',
            style: GoogleFonts.montserrat(fontSize: 8, fontWeight: FontWeight.w800, letterSpacing: 1.4, color: scheme.onSurfaceVariant.withValues(alpha: 0.8)),
          ),
          const SizedBox(height: 6),
          Theme(
            data: Theme.of(context).copyWith(
              focusColor: accent,
              canvasColor: scheme.surface,
              cardColor: scheme.surface,
              colorScheme: Theme.of(context).colorScheme.copyWith(primary: accent),
              dropdownMenuTheme: DropdownMenuThemeData(
                menuStyle: MenuStyle(
                  backgroundColor: WidgetStatePropertyAll(scheme.surface),
                  surfaceTintColor: const WidgetStatePropertyAll(Colors.transparent),
                ),
                textStyle: GoogleFonts.montserrat(
                  fontWeight: FontWeight.w700,
                  color: scheme.onSurface,
                ),
              ),
            ),
            child: DropdownButtonFormField<String>(
              initialValue: _regEmployeeId,
              items: [
                const DropdownMenuItem(value: null, child: Text('— Select —')),
                ..._employees.map((e) => DropdownMenuItem(value: e['_id']?.toString(), child: Text((e['name'] ?? '').toString()))),
              ],
              onChanged: (v) => setState(() => _regEmployeeId = v),
              decoration: _cpInputDec(scheme, hint: '— Select —'),
            ),
          ),
          const SizedBox(height: 12),
          _cpLabel(scheme, 'Client Name'),
          const SizedBox(height: 6),
          _cpField(controller: _regClientName, hint: 'CLIENT NAME', scheme: scheme),
          const SizedBox(height: 12),
          _cpLabel(scheme, 'Client Number'),
          const SizedBox(height: 6),
          _cpField(controller: _regClientPhone, hint: 'PHONE NUMBER', scheme: scheme, keyboardType: TextInputType.phone),
          const SizedBox(height: 12),
          _cpLabel(scheme, 'E-mail'),
          const SizedBox(height: 6),
          _cpField(controller: _regClientEmail, hint: 'EMAIL ADDRESS', scheme: scheme, keyboardType: TextInputType.emailAddress),
          const SizedBox(height: 12),
          _cpLabel(scheme, 'Location'),
          const SizedBox(height: 6),
          _cpField(controller: _regLocation, hint: 'LOCATION', scheme: scheme),
          const SizedBox(height: 14),
          FilledButton(
            onPressed: _regSubmitting ? null : _submitRegistration,
            style: FilledButton.styleFrom(
              backgroundColor: btnBg,
              foregroundColor: btnFg,
              minimumSize: const Size.fromHeight(52),
              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
            ),
            child: _regSubmitting
                ? const SizedBox(width: 18, height: 18, child: CircularProgressIndicator(strokeWidth: 2))
                : Text('SUBMIT', style: GoogleFonts.montserrat(fontWeight: FontWeight.w900, letterSpacing: 3)),
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
                    launchUrl(Uri.parse('https://wa.me/$phone'), mode: LaunchMode.externalApplication);
                  } else {
                    ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('Contact not available')));
                  }
                },
              ),
            ],
          ),
          const SizedBox(width: 16),
          Expanded(
            child: FilledButton(
              onPressed: () => context.push('/cp/booking/site-visit?projectId=${widget.projectId}'),
              style: FilledButton.styleFrom(
                backgroundColor: accent,
                foregroundColor: accentFg,
                minimumSize: const Size.fromHeight(50),
                shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
                elevation: 10,
                shadowColor: accent.withValues(alpha: 0.3),
              ),
              child: Text(
                'BOOK VISIT',
                style: GoogleFonts.montserrat(
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

  Widget _ctaCircleIcon({required IconData icon, required ColorScheme scheme, required VoidCallback onTap}) {
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
            border: Border.all(color: scheme.outlineVariant.withValues(alpha: 0.5)),
            color: scheme.surface,
          ),
          child: Icon(icon, size: 20, color: scheme.onSurface),
        ),
      ),
    );
  }

  Widget _locationCard(Map<String, dynamic> p, ColorScheme scheme) {
    const defaultLoc = 'NA 604, 6th Floor, M4 Aura Heights, Grant Road, Mumbai - 400007';
    bool invalid(String s) => s.isEmpty || ['NA', 'N/A', 'na', 'n/a', 'None', 'none'].contains(s.trim());
    final raw = p['location'];
    final loc = raw is String ? raw : (raw is Map ? (raw['name'] ?? '').toString() : '');
    final effective = invalid(loc) ? defaultLoc : loc;
    final isLight = scheme.brightness == Brightness.light;
    final btnBg = isLight ? Colors.black : scheme.primary;
    final btnFg = isLight ? Colors.white : scheme.onPrimary;
    final embed = 'https://www.google.com/maps?q=${Uri.encodeComponent(effective)}&output=embed';

    final controller = WebViewController()
      ..setJavaScriptMode(JavaScriptMode.unrestricted)
      ..setBackgroundColor(const Color(0x00000000))
      ..loadRequest(Uri.parse(embed));

    return Container(
      height: 280,
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(34),
        border: Border.all(color: scheme.outlineVariant.withValues(alpha: 0.35), width: 4),
        color: scheme.surfaceContainerHighest.withValues(alpha: 0.18),
      ),
      clipBehavior: Clip.antiAlias,
      child: Stack(
        children: [
          Positioned.fill(
            child: WebViewWidget(controller: controller),
          ),
          Positioned(
            top: 14,
            right: 14,
            child: FilledButton.icon(
              onPressed: () => _openUrl('https://www.google.com/maps?q=${Uri.encodeComponent(effective)}'),
              icon: const Icon(LucideIcons.mapPin, size: 16),
              label: Text('VIEW ON MAPS', style: GoogleFonts.montserrat(fontSize: 9, fontWeight: FontWeight.w900, letterSpacing: 2)),
              style: FilledButton.styleFrom(
                backgroundColor: btnBg,
                foregroundColor: btnFg,
                padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
                shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(999)),
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
    return Positioned.fill(
      child: Material(
        color: Colors.black.withValues(alpha: 0.45),
        child: SafeArea(
          child: Align(
            alignment: Alignment.bottomCenter,
            child: Container(
              padding: const EdgeInsets.fromLTRB(18, 14, 18, 18),
              decoration: BoxDecoration(
                color: scheme.surface,
                borderRadius: const BorderRadius.vertical(top: Radius.circular(34)),
              ),
              child: SingleChildScrollView(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.stretch,
                  children: [
                    Center(child: Container(width: 40, height: 4, decoration: BoxDecoration(color: scheme.onSurface.withValues(alpha: 0.12), borderRadius: BorderRadius.circular(99)))),
                    const SizedBox(height: 14),
                    Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text('VIDEO CALL', style: GoogleFonts.montserrat(fontSize: 16, fontWeight: FontWeight.w900, letterSpacing: -0.2)),
                            const SizedBox(height: 2),
                            Text((_project?['title'] ?? '').toString().toUpperCase(), style: GoogleFonts.montserrat(fontSize: 9, fontWeight: FontWeight.w900, letterSpacing: 1.4, color: scheme.onSurfaceVariant)),
                          ],
                        ),
                        IconButton(
                          onPressed: () => setState(() => _leadOpen = false),
                          icon: const Icon(LucideIcons.x),
                        ),
                      ],
                    ),
                    const SizedBox(height: 12),
                    _cpLabel(scheme, 'Enter employee name'),
                    const SizedBox(height: 6),
                    _cpField(controller: _employeeEntered, hint: 'EMPLOYEE NAME', scheme: scheme),
                    const SizedBox(height: 12),
                    _cpLabel(scheme, 'Name of the employee'),
                    const SizedBox(height: 2),
                    Text('SELECT A NAME FROM THE LIST', style: GoogleFonts.montserrat(fontSize: 8, fontWeight: FontWeight.w800, letterSpacing: 1.4, color: scheme.onSurfaceVariant.withValues(alpha: 0.8))),
                    const SizedBox(height: 6),
                    DropdownButtonFormField<String>(
                      initialValue: _employeeId,
                      items: [
                        const DropdownMenuItem(value: null, child: Text('— Select —')),
                        ..._employees.map((e) => DropdownMenuItem(value: e['_id']?.toString(), child: Text((e['name'] ?? '').toString()))),
                      ],
                      onChanged: (v) => setState(() => _employeeId = v),
                      decoration: _cpInputDec(scheme, hint: '— Select —'),
                    ),
                    const SizedBox(height: 12),
                    _cpLabel(scheme, 'Client Name'),
                    const SizedBox(height: 6),
                    _cpField(controller: _clientName, hint: 'CLIENT NAME', scheme: scheme),
                    const SizedBox(height: 12),
                    _cpLabel(scheme, 'Client Number'),
                    const SizedBox(height: 6),
                    _cpField(controller: _clientPhone, hint: 'PHONE NUMBER', scheme: scheme, keyboardType: TextInputType.phone),
                    const SizedBox(height: 12),
                    _cpLabel(scheme, 'E-mail'),
                    const SizedBox(height: 6),
                    _cpField(controller: _clientEmail, hint: 'EMAIL ADDRESS', scheme: scheme, keyboardType: TextInputType.emailAddress),
                    const SizedBox(height: 12),
                    OutlinedButton.icon(
                      onPressed: _pickVideoDt,
                      icon: const Icon(LucideIcons.calendar),
                      label: Text(
                        _videoCallDt == null ? 'Select date & time' : DateFormat('d MMM y, h:mm a').format(_videoCallDt!.toLocal()),
                      ),
                      style: OutlinedButton.styleFrom(
                        minimumSize: const Size.fromHeight(52),
                        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
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
                        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
                      ),
                      child: _leadSubmitting
                          ? const SizedBox(width: 18, height: 18, child: CircularProgressIndicator(strokeWidth: 2))
                          : Text('SUBMIT', style: GoogleFonts.montserrat(fontWeight: FontWeight.w900, letterSpacing: 3)),
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

  Widget _cpLabel(ColorScheme scheme, String text) {
    return Text(
      text,
      style: GoogleFonts.montserrat(
        fontSize: 11,
        fontWeight: FontWeight.w800,
        color: scheme.onSurface,
        letterSpacing: 0.2,
      ),
    );
  }

  Widget _cpField({
    required TextEditingController controller,
    required String hint,
    required ColorScheme scheme,
    TextInputType? keyboardType,
  }) {
    return TextField(
      controller: controller,
      keyboardType: keyboardType,
      decoration: _cpInputDec(scheme, hint: hint),
      style: GoogleFonts.montserrat(fontWeight: FontWeight.w700),
    );
  }

  InputDecoration _cpInputDec(ColorScheme scheme, {required String hint}) {
    final isLight = scheme.brightness == Brightness.light;
    return InputDecoration(
      hintText: hint,
      hintStyle: GoogleFonts.montserrat(
        fontSize: 10,
        fontWeight: FontWeight.w900,
        letterSpacing: 1.8,
        color: scheme.onSurface.withValues(alpha: isLight ? 0.55 : 0.45),
      ),
      filled: true,
      fillColor: scheme.surfaceContainerHighest.withValues(alpha: isLight ? 0.16 : 0.2),
      border: OutlineInputBorder(borderRadius: BorderRadius.circular(16), borderSide: BorderSide(color: scheme.outlineVariant.withValues(alpha: 0.5))),
      enabledBorder: OutlineInputBorder(borderRadius: BorderRadius.circular(16), borderSide: BorderSide(color: scheme.outlineVariant.withValues(alpha: 0.5))),
      focusedBorder: OutlineInputBorder(
        borderRadius: BorderRadius.circular(16),
        borderSide: BorderSide(color: scheme.onSurface.withValues(alpha: isLight ? 0.8 : 0.65)),
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
                  final url = ref.read(apiClientProvider).resolveUrl(_gallery[i]);
                  return InteractiveViewer(
                    minScale: 1,
                    maxScale: 4,
                    child: Center(
                      child: CachedNetworkImage(
                        imageUrl: url,
                        fit: BoxFit.contain,
                        errorWidget: (_, __, ___) => Icon(LucideIcons.imageOff, color: Colors.white.withValues(alpha: 0.7)),
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
                              final next = (_galleryIndex - 1).clamp(0, _gallery.length - 1);
                              ctrl.animateToPage(next, duration: const Duration(milliseconds: 220), curve: Curves.easeOut);
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
                              final next = (_galleryIndex + 1).clamp(0, _gallery.length - 1);
                              ctrl.animateToPage(next, duration: const Duration(milliseconds: 220), curve: Curves.easeOut);
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
                  style: GoogleFonts.montserrat(color: Colors.white, fontWeight: FontWeight.w800),
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
                          color: i == _galleryIndex ? (isLight ? Colors.white : Colors.white) : Colors.white.withValues(alpha: 0.35),
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

