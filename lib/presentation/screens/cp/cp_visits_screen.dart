import 'dart:async';
import 'dart:convert';

import 'package:dio/dio.dart';
import 'package:flutter/material.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:intl/intl.dart';
import 'package:lucide_icons/lucide_icons.dart';
import 'package:url_launcher/url_launcher.dart';
import 'package:m4_mobile/presentation/providers/auth_provider.dart';
import 'package:m4_mobile/presentation/widgets/cp_bottom_nav.dart';

/// Web `/cp/visits` (`app/(cp)/cp/visits/page.tsx`) — "Performance Tracker":
/// two tabs, Visit Tracking (search + project filter + visit cards with a
/// status-update dropdown) and Payment Tracker (booking payment-progress
/// rings + notify-admin).
class CpVisitsScreen extends ConsumerStatefulWidget {
  const CpVisitsScreen({super.key});

  @override
  ConsumerState<CpVisitsScreen> createState() => _CpVisitsScreenState();
}

class _CpVisitsScreenState extends ConsumerState<CpVisitsScreen> {
  String _activeTab = 'visits'; // 'visits' | 'payments'

  // Visit Tracking state
  bool _loading = true;
  String? _error;
  List<dynamic> _visits = [];
  int _page = 1;
  int _totalPages = 1;
  String _searchQuery = '';
  String _selectedProject = 'all';

  // Payment Tracker state
  bool _bookingsLoading = false;
  List<dynamic> _bookings = [];

  static const _visitsCacheKey = 'cp_visits_cache';

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) async {
      // Show the last-loaded visits instantly, then refresh in the background —
      // so reopening the screen feels fast even when the backend is slow.
      await _loadCachedVisits();
      _load();
      _loadBookings();
    });
  }

  Future<void> _loadCachedVisits() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      final cached = prefs.getString(_visitsCacheKey);
      if (cached == null || !mounted || _visits.isNotEmpty) return;
      final list = jsonDecode(cached);
      if (list is List && list.isNotEmpty) {
        setState(() {
          _visits = list;
          _loading = false; // cache is shown; _load() still refreshes in bg
        });
      }
    } catch (_) {}
  }

  Future<void> _load({int page = 1, bool retried = false}) async {
    setState(() {
      _loading = true;
      _error = null;
    });
    try {
      final res = await ref
          .read(apiClientProvider)
          .getCpVisits(page: page, limit: 10)
          // The Dio client's receiveTimeout is 90s — far too long for a small
          // paginated list. Cap this at 15s so a slow/hung backend shows the
          // retry state fast instead of spinning "SYNCHRONIZING RECORDS...".
          .timeout(const Duration(seconds: 15));
      final body = res.data;
      if (body is Map && body['status'] == true && body['data'] is Map) {
        final d = body['data'] as Map;
        final raw = d['visits'];
        _visits = raw is List ? List<dynamic>.from(raw) : [];
        _page = (d['page'] as num?)?.toInt() ?? page;
        _totalPages = (d['totalPages'] as num?)?.toInt() ?? 1;
        // Cache so the next open shows this list instantly.
        try {
          final prefs = await SharedPreferences.getInstance();
          await prefs.setString(_visitsCacheKey, jsonEncode(_visits));
        } catch (_) {}
      } else {
        _error = 'Could not load visits';
        _visits = [];
      }
    } on TimeoutException {
      // The backend can cold-start: the first request often times out while it
      // wakes up. Retry once automatically — it is usually warm + fast by now,
      // so the user doesn't have to tap "Retry".
      if (!retried) {
        return _load(page: page, retried: true);
      }
      _error = 'Taking longer than usual — please retry.';
      _visits = [];
    } on DioException catch (e) {
      _error = e.response?.data is Map
          ? (e.response!.data as Map)['message']?.toString()
          : e.message;
      _visits = [];
    } catch (e) {
      _error = e.toString();
      _visits = [];
    }
    if (mounted) setState(() => _loading = false);
  }

  Future<void> _loadBookings() async {
    setState(() => _bookingsLoading = true);
    try {
      final res = await ref
          .read(apiClientProvider)
          .getCpBookings()
          .timeout(const Duration(seconds: 15));
      final body = res.data;
      if (body is Map && body['status'] == true && body['data'] is Map) {
        final raw = (body['data'] as Map)['bookings'];
        _bookings = raw is List ? List<dynamic>.from(raw) : [];
      }
    } catch (_) {}
    if (mounted) setState(() => _bookingsLoading = false);
  }

  Future<void> _notifyAdmin(String bookingId) async {
    try {
      final res = await ref
          .read(apiClientProvider)
          .notifyAdminForSettlement(bookingId);
      final body = res.data;
      final ok = body is Map && body['status'] == true;
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            backgroundColor: const Color(0xFFC65B46),
            content: Text(
              ok
                  ? 'Admin notified'
                  : (body is Map
                        ? (body['message']?.toString() ??
                              'Could not notify admin')
                        : 'Could not notify admin'),
            ),
          ),
        );
      }
    } catch (_) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            backgroundColor: Color(0xFFC65B46),
            content: Text('Failed to send notification'),
          ),
        );
      }
    }
  }

  Future<void> _patchStatus(String id, String status) async {
    try {
      final res = await ref
          .read(apiClientProvider)
          .patchCpVisitStatus(id, status);
      final body = res.data;
      if (body is Map && body['status'] == true) {
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
              backgroundColor: const Color(0xFF163A2C),
              content: Text('Status updated to $status'),
            ),
          );
        }
        await _load(page: _page);
      } else {
        final msg = body is Map ? body['message']?.toString() : null;
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
              backgroundColor: const Color(0xFFC65B46),
              content: Text(msg ?? 'Update failed'),
            ),
          );
        }
      }
    } on DioException catch (e) {
      final m = e.response?.data is Map
          ? (e.response!.data as Map)['message']?.toString()
          : e.message;
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            backgroundColor: const Color(0xFFC65B46),
            content: Text(m ?? 'Error'),
          ),
        );
      }
    }
  }

  String _projectTitle(dynamic visit) {
    final p = visit['projectId'];
    if (p is Map)
      return p['title']?.toString() ?? p['name']?.toString() ?? 'M4 Project';
    return 'M4 Project';
  }

  String _employeeName(dynamic visit) {
    final e = visit['employeeId'];
    if (e is Map) return e['name']?.toString() ?? 'Self';
    return 'Self';
  }

  String _visitId(dynamic visit) {
    final id = visit['_id'];
    return id?.toString() ?? '';
  }

  // Web parity: `projectNames = ["all", ...new Set(visits.map(title))]`.
  List<String> _projectNames() {
    final names = <String>{};
    for (final v in _visits) {
      final t = _projectTitle(v);
      if (t.isNotEmpty) names.add(t);
    }
    return ['all', ...names];
  }

  // Web parity: client-side search + project filter.
  List<dynamic> _filteredVisits() {
    final query = _searchQuery.toLowerCase().trim();
    return _visits.where((v) {
      final matchesSearch =
          query.isEmpty ||
          (v['clientName']?.toString() ?? '').toLowerCase().contains(query) ||
          _projectTitle(v).toLowerCase().contains(query) ||
          _visitId(v).toLowerCase().contains(query);
      final matchesProject =
          _selectedProject == 'all' || _projectTitle(v) == _selectedProject;
      return matchesSearch && matchesProject;
    }).toList();
  }

  @override
  Widget build(BuildContext context) {
    final scheme = Theme.of(context).colorScheme;
    final filtered = _filteredVisits();

    return Scaffold(
      backgroundColor: scheme.surface,
      extendBody: true,
      bottomNavigationBar: CpBottomNav(
        currentIndex:
            -1, // Sub-page: No main tab highlighted to match web parity
        onTap: (i) {
          switch (i) {
            case 0:
              context.go('/cp/home');
              break;
            case 1:
              context.go('/cp/dashboard');
              break;
            case 2:
              context.go('/cp/tracker');
              break;
            case 3:
              context.go('/cp/projects');
              break;
            case 4:
              context.go('/support');
              break;
            case 5:
              context.go('/cp/profile');
              break;
          }
        },
      ),
      body: SafeArea(
        // Edge-to-edge: content runs under the gesture bar so scrolling fills
        // the screen. Trailing padding keeps the last item reachable.
        bottom: false,
        child: ListView(
          padding: const EdgeInsets.fromLTRB(20, 0, 20, 100),
          children: [
            const SizedBox(height: 8),
            _buildHeader(scheme),
            const SizedBox(height: 20),
            _buildTabs(scheme),
            const SizedBox(height: 20),
            if (_activeTab == 'visits')
              _buildVisitTracking(scheme, filtered)
            else
              _buildPaymentTracker(scheme),
          ],
        ),
      ),
    );
  }

  // ---------------------------------------------------------------------
  // Header: back button, purple dot + "PERFORMANCE TRACKER", refresh (web
  // `SectionHeader`).
  // ---------------------------------------------------------------------
  Widget _buildHeader(ColorScheme scheme) {
    final busy = _loading || _bookingsLoading;
    return Row(
      mainAxisAlignment: MainAxisAlignment.spaceBetween,
      children: [
        IconButton(
          onPressed: () => context.pop(),
          icon: Container(
            padding: const EdgeInsets.all(8),
            decoration: BoxDecoration(
              color: scheme.onSurface.withValues(alpha: 0.03),
              borderRadius: BorderRadius.circular(10),
              border: Border.all(
                color: scheme.outlineVariant.withValues(alpha: 0.3),
              ),
            ),
            child: Icon(
              LucideIcons.arrowLeft,
              size: 16,
              color: scheme.onSurface,
            ),
          ),
        ),
        Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            Container(
              width: 6,
              height: 6,
              decoration: BoxDecoration(
                color: scheme.primary,
                shape: BoxShape.circle,
              ),
            ),
            const SizedBox(width: 8),
            Text(
              'PERFORMANCE TRACKER',
              style: GoogleFonts.inter(
                fontWeight: FontWeight.w600,
                fontSize: 13,
                letterSpacing: 1.2,
              ),
            ),
          ],
        ),
        IconButton(
          onPressed: () {
            _load(page: _page);
            _loadBookings();
          },
          icon: Container(
            padding: const EdgeInsets.all(8),
            decoration: BoxDecoration(
              color: scheme.onSurface.withValues(alpha: 0.03),
              borderRadius: BorderRadius.circular(10),
              border: Border.all(
                color: scheme.outlineVariant.withValues(alpha: 0.3),
              ),
            ),
            child: busy
                ? SizedBox(
                    width: 16,
                    height: 16,
                    child: CircularProgressIndicator(
                      strokeWidth: 2,
                      color: scheme.onSurfaceVariant,
                    ),
                  )
                : Icon(
                    LucideIcons.refreshCw,
                    size: 16,
                    color: scheme.onSurface,
                  ),
          ),
        ),
      ],
    );
  }

  // ---------------------------------------------------------------------
  // Tabs: "VISIT TRACKING" / "PAYMENT TRACKER" segmented control (web
  // `TabsList`).
  // ---------------------------------------------------------------------
  Widget _buildTabs(ColorScheme scheme) {
    Widget tab(String key, String label) {
      final active = _activeTab == key;
      return Expanded(
        child: GestureDetector(
          onTap: () => setState(() => _activeTab = key),
          child: Container(
            height: 40,
            alignment: Alignment.center,
            decoration: BoxDecoration(
              color: active ? scheme.primary : Colors.transparent,
              borderRadius: BorderRadius.circular(14),
            ),
            child: Text(
              label,
              style: GoogleFonts.inter(
                fontSize: 9,
                fontWeight: FontWeight.w600,
                letterSpacing: 1.2,
                color: active ? scheme.onPrimary : scheme.onSurfaceVariant,
              ),
            ),
          ),
        ),
      );
    }

    return Container(
      height: 44,
      padding: const EdgeInsets.all(3),
      decoration: BoxDecoration(
        color: scheme.surface,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: scheme.outlineVariant.withValues(alpha: 0.4)),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.06),
            blurRadius: 20,
            offset: const Offset(0, 10),
          ),
        ],
      ),
      child: Row(
        children: [
          tab('visits', 'VISIT TRACKING'),
          tab('payments', 'PAYMENT TRACKER'),
        ],
      ),
    );
  }

  // ---------------------------------------------------------------------
  // Visit Tracking tab
  // ---------------------------------------------------------------------
  Widget _buildVisitTracking(ColorScheme scheme, List<dynamic> filtered) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        _buildSearchAndFilter(scheme),
        const SizedBox(height: 20),
        if (_loading && _visits.isEmpty)
          Padding(
            padding: const EdgeInsets.symmetric(vertical: 60),
            child: Center(
              child: Column(
                children: [
                  CircularProgressIndicator(
                    color: scheme.primary,
                    strokeWidth: 2,
                  ),
                  const SizedBox(height: 16),
                  Text(
                    'SYNCHRONIZING RECORDS...',
                    style: GoogleFonts.inter(
                      fontSize: 9,
                      fontWeight: FontWeight.w600,
                      letterSpacing: 1,
                      color: scheme.onSurfaceVariant,
                    ),
                  ),
                ],
              ),
            ),
          )
        else if (_error != null)
          Padding(
            padding: const EdgeInsets.symmetric(vertical: 40),
            child: Column(
              children: [
                Text(_error!, textAlign: TextAlign.center),
                const SizedBox(height: 16),
                FilledButton(
                  onPressed: () => _load(),
                  child: const Text('Retry'),
                ),
              ],
            ),
          )
        else if (filtered.isEmpty)
          _buildEmptyState(scheme)
        else
          ...filtered.map((v) => _buildVisitCard(scheme, v)),
        if (_totalPages > 1) _buildPagination(scheme),
      ],
    );
  }

  Widget _buildSearchAndFilter(ColorScheme scheme) {
    return Row(
      children: [
        Expanded(
          child: Container(
            decoration: BoxDecoration(
              color: scheme.surface,
              borderRadius: BorderRadius.circular(18),
              boxShadow: [
                BoxShadow(
                  color: Colors.black.withValues(alpha: 0.08),
                  blurRadius: 20,
                  offset: const Offset(0, 10),
                ),
              ],
              border: Border.all(
                color: scheme.outlineVariant.withValues(alpha: 0.4),
              ),
            ),
            child: TextField(
              onChanged: (v) => setState(() => _searchQuery = v),
              style: GoogleFonts.inter(
                fontSize: 15,
                fontWeight: FontWeight.bold,
              ),
              decoration: InputDecoration(
                hintText: 'Search Visits',
                hintStyle: GoogleFonts.inter(
                  fontSize: 9,
                  fontWeight: FontWeight.w500,
                  color: scheme.onSurface.withValues(alpha: 0.62),
                  letterSpacing: 1.0,
                ),
                prefixIcon: Icon(
                  LucideIcons.search,
                  size: 18,
                  color: scheme.onSurface.withValues(alpha: 0.5),
                ),
                filled: false,
                border: InputBorder.none,
                enabledBorder: InputBorder.none,
                focusedBorder: InputBorder.none,
                contentPadding: const EdgeInsets.symmetric(vertical: 14),
              ),
            ),
          ),
        ),
        const SizedBox(width: 10),
        Container(
          height: 48,
          padding: const EdgeInsets.symmetric(horizontal: 14),
          decoration: BoxDecoration(
            color: scheme.surface,
            borderRadius: BorderRadius.circular(18),
            boxShadow: [
              BoxShadow(
                color: Colors.black.withValues(alpha: 0.08),
                blurRadius: 20,
                offset: const Offset(0, 10),
              ),
            ],
            border: Border.all(
              color: scheme.outlineVariant.withValues(alpha: 0.4),
            ),
          ),
          child: DropdownButtonHideUnderline(
            child: DropdownButton<String>(
              value: _selectedProject,
              icon: Icon(
                LucideIcons.chevronDown,
                size: 16,
                color: scheme.onSurfaceVariant,
              ),
              style: GoogleFonts.inter(
                fontSize: 9,
                fontWeight: FontWeight.w600,
                color: scheme.onSurface,
                letterSpacing: 0.8,
              ),
              items: _projectNames().map((n) {
                return DropdownMenuItem(
                  value: n,
                  child: Text(n == 'all' ? 'ALL PROJECTS' : n.toUpperCase()),
                );
              }).toList(),
              onChanged: (v) => setState(() => _selectedProject = v ?? 'all'),
            ),
          ),
        ),
      ],
    );
  }

  Widget _buildVisitCard(ColorScheme scheme, dynamic v) {
    final status = (v['status'] ?? '').toString();
    final dateStr = v['visitDate'] != null
        ? DateFormat('MMM d, y')
              .format(DateTime.parse(v['visitDate'].toString()).toLocal())
              .toUpperCase()
        : '—';
    final shortId = _visitId(v).length >= 6
        ? _visitId(v).substring(_visitId(v).length - 6).toUpperCase()
        : _visitId(v).toUpperCase();
    final phone = v['clientPhone']?.toString();
    final email = v['clientEmail']?.toString();

    return Container(
      margin: const EdgeInsets.only(bottom: 18),
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: scheme.surfaceContainerHighest,
        borderRadius: BorderRadius.circular(28),
        border: Border.all(
          color: scheme.brightness == Brightness.dark
              ? Colors.white.withValues(alpha: 0.07)
              : scheme.outlineVariant.withValues(alpha: 0.55),
        ),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(
              alpha: scheme.brightness == Brightness.dark ? 0.35 : 0.08,
            ),
            blurRadius: 24,
            offset: const Offset(0, 10),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Header: date + visit id, status badge
          Row(
            children: [
              Container(
                width: 40,
                height: 40,
                decoration: BoxDecoration(
                  color: scheme.onSurface.withValues(alpha: 0.05),
                  borderRadius: BorderRadius.circular(16),
                  border: Border.all(
                    color: scheme.outlineVariant.withValues(alpha: 0.4),
                  ),
                ),
                child: Icon(
                  LucideIcons.calendar,
                  size: 18,
                  color: scheme.onSurfaceVariant,
                ),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      dateStr,
                      style: GoogleFonts.inter(
                        fontSize: 11,
                        fontWeight: FontWeight.w600,
                        letterSpacing: 0.5,
                        color: scheme.onSurface,
                      ),
                    ),
                    const SizedBox(height: 2),
                    Text(
                      'VISIT ID: $shortId',
                      style: GoogleFonts.inter(
                        fontSize: 8,
                        fontWeight: FontWeight.w600,
                        letterSpacing: 0.8,
                        color: scheme.onSurfaceVariant.withValues(alpha: 0.6),
                      ),
                    ),
                  ],
                ),
              ),
              _statusChip(scheme, status),
            ],
          ),
          const SizedBox(height: 16),
          // 2x2 detail grid
          Container(
            padding: const EdgeInsets.symmetric(vertical: 14),
            child: Row(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Expanded(
                  child: _detailCell(
                    scheme,
                    label: 'LEAD CLIENT',
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          (v['clientName'] ?? 'Client')
                              .toString()
                              .toUpperCase(),
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                          style: GoogleFonts.inter(
                            fontSize: 11,
                            fontWeight: FontWeight.w600,
                            color: scheme.onSurface,
                          ),
                        ),
                        const SizedBox(height: 2),
                        Text(
                          phone ?? email ?? '',
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                          style: GoogleFonts.inter(
                            fontSize: 8,
                            fontWeight: FontWeight.w700,
                            color: scheme.onSurfaceVariant.withValues(
                              alpha: 0.7,
                            ),
                          ),
                        ),
                      ],
                    ),
                  ),
                ),
                Expanded(
                  child: _detailCell(
                    scheme,
                    label: 'HANDLED BY',
                    alignEnd: true,
                    child: Text(
                      _employeeName(v).toUpperCase(),
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                      textAlign: TextAlign.right,
                      style: GoogleFonts.inter(
                        fontSize: 11,
                        fontWeight: FontWeight.w600,
                        color: scheme.onSurface,
                      ),
                    ),
                  ),
                ),
              ],
            ),
          ),
          const SizedBox(height: 14),
          Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Expanded(
                child: _detailCell(
                  scheme,
                  label: 'PROJECT FOCUS',
                  child: Row(
                    children: [
                      Icon(
                        LucideIcons.building2,
                        size: 14,
                        color: scheme.primary.withValues(alpha: 0.5),
                      ),
                      const SizedBox(width: 6),
                      Expanded(
                        child: Text(
                          _projectTitle(v).toUpperCase(),
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                          style: GoogleFonts.inter(
                            fontSize: 11,
                            fontWeight: FontWeight.w600,
                            color: scheme.onSurface,
                          ),
                        ),
                      ),
                    ],
                  ),
                ),
              ),
              Expanded(
                child: _detailCell(
                  scheme,
                  label: 'CONFIGURATION',
                  alignEnd: true,
                  child: Text(
                    (v['configuration'] ?? 'N/A').toString().toUpperCase(),
                    textAlign: TextAlign.right,
                    style: GoogleFonts.inter(
                      fontSize: 11,
                      fontWeight: FontWeight.w600,
                      color: scheme.onSurface,
                    ),
                  ),
                ),
              ),
            ],
          ),
          const SizedBox(height: 16),
          // Footer actions
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Row(
                children: [
                  _iconAction(
                    scheme,
                    LucideIcons.phone,
                    phone != null && phone.isNotEmpty
                        ? () => _contact('tel', phone)
                        : null,
                  ),
                  const SizedBox(width: 8),
                  _iconAction(
                    scheme,
                    LucideIcons.messageSquare,
                    phone != null && phone.isNotEmpty
                        ? () => _contact('sms', phone)
                        : null,
                  ),
                  const SizedBox(width: 8),
                  _iconAction(
                    scheme,
                    LucideIcons.mail,
                    email != null && email.isNotEmpty
                        ? () => _contact('mailto', email)
                        : null,
                  ),
                ],
              ),
              if (status == 'CLOSED')
                FilledButton(
                  onPressed: () => context.push('/cp/booking/my-bookings'),
                  style: FilledButton.styleFrom(
                    backgroundColor: Colors.green,
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(16),
                    ),
                    padding: const EdgeInsets.symmetric(
                      horizontal: 16,
                      vertical: 10,
                    ),
                  ),
                  child: Text(
                    'VIEW BOOKING',
                    style: GoogleFonts.inter(
                      fontSize: 9,
                      fontWeight: FontWeight.w600,
                      letterSpacing: 1,
                    ),
                  ),
                )
              else if (status != 'NOT_INTERESTED')
                _updateStatusMenu(scheme, v, status),
            ],
          ),
        ],
      ),
    );
  }

  Widget _detailCell(
    ColorScheme scheme, {
    required String label,
    required Widget child,
    bool alignEnd = false,
  }) {
    return Column(
      crossAxisAlignment: alignEnd
          ? CrossAxisAlignment.end
          : CrossAxisAlignment.start,
      children: [
        Text(
          label,
          style: GoogleFonts.inter(
            fontSize: 7,
            fontWeight: FontWeight.w600,
            letterSpacing: 1,
            color: scheme.onSurfaceVariant.withValues(alpha: 0.68),
          ),
        ),
        const SizedBox(height: 4),
        child,
      ],
    );
  }

  // Opens the phone dialer (tel:), SMS composer (sms:) or e-mail client
  // (mailto:) for the client. Digits are stripped of spaces/formatting so the
  // dialer receives a clean number.
  Future<void> _contact(String scheme, String raw) async {
    final value = scheme == 'mailto'
        ? raw.trim()
        : raw.replaceAll(RegExp(r'[^0-9+]'), '');
    if (value.isEmpty) return;
    final uri = Uri(scheme: scheme, path: value);
    try {
      final ok = await launchUrl(uri, mode: LaunchMode.externalApplication);
      if (!ok && mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            backgroundColor: const Color(0xFFC65B46),
            content: Text('No app found to open $scheme'),
          ),
        );
      }
    } catch (_) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            backgroundColor: Color(0xFFC65B46),
            content: Text('Could not open'),
          ),
        );
      }
    }
  }

  Widget _iconAction(ColorScheme scheme, IconData icon, VoidCallback? onTap) {
    return Material(
      color: Colors.transparent,
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(14),
        child: Container(
          width: 38,
          height: 38,
          decoration: BoxDecoration(
            color: scheme.surface,
            borderRadius: BorderRadius.circular(14),
            border: Border.all(
              color: scheme.outlineVariant.withValues(alpha: 0.3),
            ),
          ),
          child: Icon(
            icon,
            size: 16,
            color: onTap != null
                ? scheme.onSurfaceVariant
                : scheme.onSurfaceVariant.withValues(alpha: 0.3),
          ),
        ),
      ),
    );
  }

  Widget _updateStatusMenu(ColorScheme scheme, dynamic v, String status) {
    if (status == 'INTERESTED') {
      return Text(
        'AWAITING ADMIN CLOSURE',
        style: GoogleFonts.inter(
          fontSize: 7,
          fontWeight: FontWeight.w600,
          letterSpacing: 0.8,
          color: scheme.onSurfaceVariant.withValues(alpha: 0.68),
        ),
      );
    }
    // status == 'NEW'
    return PopupMenuButton<String>(
      onSelected: (val) => _patchStatus(_visitId(v), val),
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(14)),
      itemBuilder: (context) => [
        PopupMenuItem(
          value: 'INTERESTED',
          child: Text(
            'Interested',
            style: GoogleFonts.inter(
              fontSize: 11,
              fontWeight: FontWeight.w600,
              color: Colors.amber.shade800,
            ),
          ),
        ),
        PopupMenuItem(
          value: 'NOT_INTERESTED',
          child: Text(
            'Not Interested',
            style: GoogleFonts.inter(
              fontSize: 11,
              fontWeight: FontWeight.w600,
              color: Colors.red,
            ),
          ),
        ),
      ],
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
        decoration: BoxDecoration(
          color: scheme.onSurface.withValues(alpha: 0.04),
          borderRadius: BorderRadius.circular(16),
          border: Border.all(
            color: scheme.outlineVariant.withValues(alpha: 0.35),
          ),
        ),
        child: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            Text(
              'UPDATE STATUS',
              style: GoogleFonts.inter(
                fontSize: 9,
                fontWeight: FontWeight.w600,
                letterSpacing: 1,
                color: scheme.onSurface,
              ),
            ),
            const SizedBox(width: 6),
            Icon(
              LucideIcons.moreVertical,
              size: 13,
              color: scheme.onSurfaceVariant,
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildEmptyState(ColorScheme scheme) {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.symmetric(vertical: 60, horizontal: 40),
      decoration: BoxDecoration(
        color: scheme.onSurface.withValues(alpha: 0.02),
        borderRadius: BorderRadius.circular(20),
        border: Border.all(color: scheme.outlineVariant.withValues(alpha: 0.2)),
      ),
      child: Column(
        children: [
          Icon(
            LucideIcons.clock,
            size: 32,
            color: scheme.onSurfaceVariant.withValues(alpha: 0.2),
          ),
          const SizedBox(height: 16),
          Text(
            'NO RECORDS FOUND MATCHING YOUR SEARCH',
            textAlign: TextAlign.center,
            style: GoogleFonts.inter(
              fontSize: 10,
              fontWeight: FontWeight.w600,
              color: scheme.onSurfaceVariant.withValues(alpha: 0.68),
              letterSpacing: 1,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildPagination(ColorScheme scheme) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 24),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          IconButton(
            onPressed: _page > 1 ? () => _load(page: _page - 1) : null,
            icon: Icon(
              LucideIcons.chevronLeft,
              size: 18,
              color: _page > 1
                  ? scheme.onSurface
                  : scheme.onSurface.withValues(alpha: 0.2),
            ),
          ),
          const SizedBox(width: 12),
          Text(
            'PAGE $_page / $_totalPages',
            style: GoogleFonts.inter(
              fontSize: 10,
              fontWeight: FontWeight.w600,
              letterSpacing: 1.2,
            ),
          ),
          const SizedBox(width: 12),
          IconButton(
            onPressed: _page < _totalPages
                ? () => _load(page: _page + 1)
                : null,
            icon: Icon(
              LucideIcons.chevronRight,
              size: 18,
              color: _page < _totalPages
                  ? scheme.onSurface
                  : scheme.onSurface.withValues(alpha: 0.2),
            ),
          ),
        ],
      ),
    );
  }

  Widget _statusChip(ColorScheme scheme, String status) {
    final isDark = scheme.brightness == Brightness.dark;
    Color base;
    String label;
    switch (status) {
      case 'NEW':
        base = const Color(0xFF0C312B); // blue
        label = 'NEW VISIT';
        break;
      case 'INTERESTED':
        base = const Color(0xFF0C312B); // amber
        label = 'INTERESTED';
        break;
      case 'NOT_INTERESTED':
        base = const Color(0xFFC65B46); // red
        label = 'NOT INTERESTED';
        break;
      case 'CLOSED':
        base = const Color(0xFF163A2C); // green
        label = 'CLOSED / BOOKING';
        break;
      default:
        base = scheme.onSurfaceVariant;
        label = status;
    }
    final fg = isDark ? Color.lerp(base, Colors.white, 0.28)! : base;
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 5),
      decoration: BoxDecoration(
        color: base.withValues(alpha: isDark ? 0.20 : 0.12),
        borderRadius: BorderRadius.circular(8),
        border: Border.all(color: base.withValues(alpha: isDark ? 0.45 : 0.30)),
      ),
      child: Text(
        label,
        style: GoogleFonts.inter(
          fontSize: 7,
          fontWeight: FontWeight.w600,
          color: fg,
          letterSpacing: 0.5,
        ),
      ),
    );
  }

  // ---------------------------------------------------------------------
  // Payment Tracker tab: booking payment-progress rings + notify-admin.
  // ---------------------------------------------------------------------
  Widget _buildPaymentTracker(ColorScheme scheme) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        Row(
          children: [
            Container(
              width: 40,
              height: 40,
              decoration: BoxDecoration(
                color: scheme.primary.withValues(alpha: 0.1),
                borderRadius: BorderRadius.circular(16),
                border: Border.all(
                  color: scheme.primary.withValues(alpha: 0.2),
                ),
              ),
              child: Icon(LucideIcons.wallet, size: 18, color: scheme.primary),
            ),
            const SizedBox(width: 12),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    'PAYMENT TRACKER',
                    style: GoogleFonts.inter(
                      fontSize: 10,
                      fontWeight: FontWeight.w600,
                      letterSpacing: 1,
                      color: scheme.onSurfaceVariant,
                    ),
                  ),
                  Text(
                    'SETTLEMENT & COMMISSION STATUS',
                    style: GoogleFonts.inter(
                      fontSize: 7,
                      fontWeight: FontWeight.w500,
                      color: scheme.onSurfaceVariant.withValues(alpha: 0.6),
                      letterSpacing: 0.6,
                    ),
                  ),
                ],
              ),
            ),
            if (_bookings.isNotEmpty)
              Container(
                padding: const EdgeInsets.symmetric(
                  horizontal: 10,
                  vertical: 5,
                ),
                decoration: BoxDecoration(
                  borderRadius: BorderRadius.circular(999),
                  border: Border.all(
                    color: scheme.primary.withValues(alpha: 0.25),
                  ),
                  color: scheme.primary.withValues(alpha: 0.06),
                ),
                child: Text(
                  '${_bookings.length} TOTAL',
                  style: GoogleFonts.inter(
                    fontSize: 8,
                    fontWeight: FontWeight.w600,
                    letterSpacing: 0.8,
                    color: scheme.primary,
                  ),
                ),
              ),
          ],
        ),
        const SizedBox(height: 20),
        if (_bookingsLoading && _bookings.isEmpty)
          Padding(
            padding: const EdgeInsets.symmetric(vertical: 60),
            child: Center(
              child: Column(
                children: [
                  CircularProgressIndicator(
                    color: scheme.primary,
                    strokeWidth: 2,
                  ),
                  const SizedBox(height: 16),
                  Text(
                    'LOADING FINANCIAL LOGS...',
                    style: GoogleFonts.inter(
                      fontSize: 9,
                      fontWeight: FontWeight.w600,
                      letterSpacing: 1,
                      color: scheme.onSurfaceVariant,
                    ),
                  ),
                ],
              ),
            ),
          )
        else if (_bookings.isEmpty)
          Container(
            padding: const EdgeInsets.symmetric(vertical: 50),
            decoration: BoxDecoration(
              color: scheme.onSurface.withValues(alpha: 0.02),
              borderRadius: BorderRadius.circular(20),
              border: Border.all(
                color: scheme.outlineVariant.withValues(alpha: 0.3),
                style: BorderStyle.solid,
              ),
            ),
            child: Column(
              children: [
                Container(
                  width: 64,
                  height: 64,
                  decoration: BoxDecoration(
                    color: scheme.surface,
                    borderRadius: BorderRadius.circular(20),
                    border: Border.all(
                      color: scheme.outlineVariant.withValues(alpha: 0.4),
                    ),
                  ),
                  child: Icon(
                    LucideIcons.wallet,
                    size: 26,
                    color: scheme.onSurfaceVariant.withValues(alpha: 0.3),
                  ),
                ),
                const SizedBox(height: 16),
                Text(
                  'ZERO FINANCIAL LOGS DETECTED',
                  style: GoogleFonts.inter(
                    fontSize: 9,
                    fontWeight: FontWeight.w600,
                    letterSpacing: 1.2,
                    color: scheme.onSurfaceVariant.withValues(alpha: 0.62),
                  ),
                ),
              ],
            ),
          )
        else
          ..._bookings.map((b) => _buildBookingCard(scheme, b)),
      ],
    );
  }

  Widget _buildBookingCard(ColorScheme scheme, dynamic b) {
    final progress = (b['paymentProgress'] is num)
        ? (b['paymentProgress'] as num).toInt().clamp(0, 100)
        : 0;
    final isReady = progress >= 100;
    final sanctioned = b['isSanctioned'] == true;
    final projectTitle =
        (b['project'] is Map ? b['project']['title'] : null)?.toString() ??
        'Project Name';
    final clientName = b['name']?.toString() ?? 'Client Name';
    final accent = isReady ? Colors.green : scheme.primary;

    return Container(
      margin: const EdgeInsets.only(bottom: 16),
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: isReady
            ? (scheme.brightness == Brightness.dark
                  ? const Color(0xFF141B3A)
                  : const Color(0xFFF4EFE3))
            : scheme.surfaceContainerHighest,
        borderRadius: BorderRadius.circular(28),
        border: Border.all(
          color: isReady
              ? const Color(0xFF163A2C).withValues(alpha: 0.35)
              : (scheme.brightness == Brightness.dark
                    ? Colors.white.withValues(alpha: 0.07)
                    : scheme.outlineVariant.withValues(alpha: 0.55)),
        ),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(
              alpha: scheme.brightness == Brightness.dark ? 0.35 : 0.08,
            ),
            blurRadius: 24,
            offset: const Offset(0, 10),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            crossAxisAlignment: CrossAxisAlignment.center,
            children: [
              SizedBox(
                width: 56,
                height: 56,
                child: Stack(
                  children: [
                    Positioned.fill(
                      child: CircularProgressIndicator(
                        value: progress / 100.0,
                        strokeWidth: 4,
                        strokeCap:
                            StrokeCap.round, // web: strokeLinecap="round"
                        color: accent,
                        backgroundColor: scheme.onSurface.withValues(
                          alpha: 0.08,
                        ),
                      ),
                    ),
                    Center(
                      child: Text(
                        '$progress%',
                        style: GoogleFonts.inter(
                          fontSize: 10,
                          fontWeight: FontWeight.w600,
                          fontStyle: FontStyle.italic,
                          color: accent,
                        ),
                      ),
                    ),
                  ],
                ),
              ),
              const SizedBox(width: 16),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(
                      children: [
                        Expanded(
                          child: Text(
                            projectTitle.toUpperCase(),
                            maxLines: 1,
                            overflow: TextOverflow.ellipsis,
                            style: GoogleFonts.inter(
                              fontSize: 13,
                              fontWeight: FontWeight.w600,
                              color: scheme.onSurface,
                            ),
                          ),
                        ),
                        if (isReady)
                          const Icon(
                            LucideIcons.check,
                            size: 14,
                            color: Colors.green,
                          ),
                      ],
                    ),
                    const SizedBox(height: 2),
                    Text(
                      'Client: ${clientName.toString().toUpperCase()}',
                      style: GoogleFonts.inter(
                        fontSize: 9,
                        fontWeight: FontWeight.w700,
                        color: scheme.onSurfaceVariant,
                        letterSpacing: 0.5,
                      ),
                    ),
                    const SizedBox(height: 8),
                    Container(
                      padding: const EdgeInsets.symmetric(
                        horizontal: 8,
                        vertical: 3,
                      ),
                      decoration: BoxDecoration(
                        borderRadius: BorderRadius.circular(6),
                        color: (sanctioned ? Colors.green : Colors.amber)
                            .withValues(alpha: 0.1),
                        border: Border.all(
                          color: (sanctioned ? Colors.green : Colors.amber)
                              .withValues(alpha: 0.2),
                        ),
                      ),
                      child: Text(
                        sanctioned ? 'SANCTIONED' : 'PENDING SANCTION',
                        style: GoogleFonts.inter(
                          fontSize: 7,
                          fontWeight: FontWeight.w600,
                          color: sanctioned
                              ? Colors.green
                              : Colors.amber.shade800,
                        ),
                      ),
                    ),
                  ],
                ),
              ),
              const SizedBox(width: 8),
              Material(
                color: Colors.transparent,
                child: InkWell(
                  onTap: isReady
                      ? () => _notifyAdmin((b['_id'] ?? '').toString())
                      : null,
                  borderRadius: BorderRadius.circular(16),
                  child: Container(
                    width: 48,
                    height: 48,
                    decoration: BoxDecoration(
                      color: isReady
                          ? scheme.onSurface
                          : scheme.surfaceContainerHighest.withValues(
                              alpha: 0.5,
                            ),
                      borderRadius: BorderRadius.circular(16),
                      border: isReady
                          ? null
                          : Border.all(
                              color: scheme.outlineVariant.withValues(
                                alpha: 0.4,
                              ),
                            ),
                    ),
                    child: Icon(
                      LucideIcons.bellRing,
                      size: 20,
                      color: isReady
                          ? scheme.surface
                          : scheme.onSurfaceVariant.withValues(alpha: 0.2),
                    ),
                  ),
                ),
              ),
            ],
          ),
          if (isReady && !sanctioned) ...[
            const SizedBox(height: 14),
            Container(
              padding: const EdgeInsets.only(top: 14),
              decoration: BoxDecoration(
                border: Border(
                  top: BorderSide(
                    color: scheme.outlineVariant.withValues(alpha: 0.3),
                  ),
                ),
              ),
              child: Row(
                children: [
                  Container(
                    width: 6,
                    height: 6,
                    decoration: const BoxDecoration(
                      color: Colors.amber,
                      shape: BoxShape.circle,
                    ),
                  ),
                  const SizedBox(width: 8),
                  Expanded(
                    child: Text(
                      '100% Payment achieved. Notify admin for commission settlement.'
                          .toUpperCase(),
                      style: GoogleFonts.inter(
                        fontSize: 7,
                        fontWeight: FontWeight.w600,
                        color: Colors.amber.shade800,
                        letterSpacing: 0.4,
                      ),
                    ),
                  ),
                ],
              ),
            ),
          ],
        ],
      ),
    );
  }
}
