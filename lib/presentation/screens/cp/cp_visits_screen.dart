import 'package:dio/dio.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:intl/intl.dart';
import 'package:lucide_icons/lucide_icons.dart';
import 'package:m4_mobile/presentation/providers/auth_provider.dart';
import 'package:m4_mobile/presentation/widgets/cp_bottom_nav.dart';

/// Web `/cp/visits` — lists CP site visits (`GET /api/cp/visits`).
class CpVisitsScreen extends ConsumerStatefulWidget {
  const CpVisitsScreen({super.key});

  @override
  ConsumerState<CpVisitsScreen> createState() => _CpVisitsScreenState();
}

class _CpVisitsScreenState extends ConsumerState<CpVisitsScreen> {
  bool _loading = true;
  String? _error;
  List<dynamic> _visits = [];
  int _page = 1;
  int _totalPages = 1;

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) => _load());
  }

  Future<void> _load({int page = 1}) async {
    setState(() {
      _loading = true;
      _error = null;
    });
    try {
      final res = await ref.read(apiClientProvider).getCpVisits(page: page, limit: 10);
      final body = res.data;
      if (body is Map && body['status'] == true && body['data'] is Map) {
        final d = body['data'] as Map;
        final raw = d['visits'];
        _visits = raw is List ? List<dynamic>.from(raw) : [];
        _page = (d['page'] as num?)?.toInt() ?? page;
        _totalPages = (d['totalPages'] as num?)?.toInt() ?? 1;
      } else {
        _error = 'Could not load visits';
        _visits = [];
      }
    } on DioException catch (e) {
      _error = e.response?.data is Map ? (e.response!.data as Map)['message']?.toString() : e.message;
      _visits = [];
    } catch (e) {
      _error = e.toString();
      _visits = [];
    }
    if (mounted) setState(() => _loading = false);
  }

  Future<void> _patchStatus(String id, String status) async {
    try {
      final res = await ref.read(apiClientProvider).patchCpVisitStatus(id, status);
      final body = res.data;
      if (body is Map && body['status'] == true) {
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text('Status updated to $status')));
        }
        await _load(page: _page);
      } else {
        final msg = body is Map ? body['message']?.toString() : null;
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text(msg ?? 'Update failed')));
        }
      }
    } on DioException catch (e) {
      final m = e.response?.data is Map ? (e.response!.data as Map)['message']?.toString() : e.message;
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text(m ?? 'Error')));
      }
    }
  }

  String _projectTitle(dynamic visit) {
    final p = visit['projectId'];
    if (p is Map) return p['title']?.toString() ?? p['name']?.toString() ?? 'Project';
    return 'Project';
  }

  String _employeeName(dynamic visit) {
    final e = visit['employeeId'];
    if (e is Map) return e['name']?.toString() ?? '—';
    return '—';
  }

  String _visitId(dynamic visit) {
    final id = visit['_id'];
    if (id != null) return id.toString();
    return '';
  }

  @override
  Widget build(BuildContext context) {
    final scheme = Theme.of(context).colorScheme;

    return Scaffold(
      backgroundColor: scheme.surface,
      extendBody: true,
      bottomNavigationBar: CpBottomNav(
        currentIndex: -1, // Sub-page: No main tab highlighted to match web parity
        onTap: (i) {
          switch (i) {
            case 0: context.go('/cp/home'); break;
            case 1: context.go('/cp/dashboard'); break;
            case 2: context.go('/cp/tracker'); break;
            case 3: context.go('/cp/projects'); break;
            case 4: context.go('/support'); break;
            case 5: context.go('/cp/profile'); break;
          }
        },
      ),
      body: _loading
          ? Center(child: CircularProgressIndicator(color: scheme.primary))
          : _error != null
              ? Center(
                  child: Padding(
                    padding: const EdgeInsets.all(24),
                    child: Column(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        Text(_error!, textAlign: TextAlign.center),
                        const SizedBox(height: 16),
                        FilledButton(onPressed: () => _load(), child: const Text('Retry')),
                      ],
                    ),
                  ),
                )
              : SafeArea(
                  child: _visits.isEmpty
                      ? Padding(
                          padding: const EdgeInsets.symmetric(horizontal: 20),
                          child: _buildEmptyState(scheme),
                        )
                      : RefreshIndicator(
                          onRefresh: () => _load(page: _page),
                          child: ListView.builder(
                            padding: const EdgeInsets.fromLTRB(20, 0, 20, 100),
                            itemCount: _visits.length + 1 + (_totalPages > 1 ? 1 : 0),
                            itemBuilder: (context, i) {
                              if (i == 0) return _buildSearchHeader(scheme);
                              
                              int index = i - 1;
                              if (index == _visits.length) {
                                if (_totalPages > 1) {
                                  return _buildPagination(scheme);
                                } else {
                                  return const SizedBox.shrink();
                                }
                              }

                              final v = _visits[index];
                              final status = (v['status'] ?? '').toString();
                              final dateStr = v['visitDate'] != null
                                  ? DateFormat('d MMM y, h:mm a').format(DateTime.parse(v['visitDate'].toString()).toLocal())
                                  : '—';

                              return Card(
                                margin: const EdgeInsets.only(bottom: 12),
                                elevation: 0,
                                shape: RoundedRectangleBorder(
                                  borderRadius: BorderRadius.circular(20),
                                  side: BorderSide(color: scheme.outlineVariant.withValues(alpha: 0.5)),
                                ),
                                child: Padding(
                                  padding: const EdgeInsets.all(16),
                                  child: Column(
                                    crossAxisAlignment: CrossAxisAlignment.start,
                                    children: [
                                      Row(
                                        crossAxisAlignment: CrossAxisAlignment.start,
                                        children: [
                                          Expanded(
                                            child: Column(
                                              crossAxisAlignment: CrossAxisAlignment.start,
                                              children: [
                                                Text(
                                                  v['clientName']?.toString() ?? 'Client',
                                                  style: GoogleFonts.montserrat(fontWeight: FontWeight.w800, fontSize: 14),
                                                ),
                                                const SizedBox(height: 4),
                                                Text(
                                                  v['clientPhone']?.toString() ?? '',
                                                  style: GoogleFonts.montserrat(fontSize: 12, color: scheme.onSurfaceVariant),
                                                ),
                                              ],
                                            ),
                                          ),
                                          _statusChip(scheme, status),
                                        ],
                                      ),
                                      const SizedBox(height: 8),
                                      Text(
                                        _projectTitle(v),
                                        style: GoogleFonts.montserrat(fontWeight: FontWeight.w600, fontSize: 12, color: scheme.primary),
                                      ),
                                      const SizedBox(height: 4),
                                      Text(
                                        'Employee: ${_employeeName(v)}',
                                        style: GoogleFonts.montserrat(fontSize: 11, color: scheme.onSurfaceVariant),
                                      ),
                                      Text(
                                        dateStr,
                                        style: GoogleFonts.montserrat(fontSize: 10, color: scheme.onSurfaceVariant.withValues(alpha: 0.7)),
                                      ),
                                      if (status == 'NEW') ...[
                                        const SizedBox(height: 12),
                                        Wrap(
                                          spacing: 8,
                                          runSpacing: 8,
                                          children: [
                                            OutlinedButton(
                                              onPressed: () => _patchStatus(_visitId(v), 'INTERESTED'),
                                              style: OutlinedButton.styleFrom(
                                                padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 0),
                                                textStyle: GoogleFonts.montserrat(fontSize: 10, fontWeight: FontWeight.bold),
                                              ),
                                              child: const Text('INTERESTED'),
                                            ),
                                            OutlinedButton(
                                              onPressed: () => _patchStatus(_visitId(v), 'NOT_INTERESTED'),
                                              style: OutlinedButton.styleFrom(
                                                padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 0),
                                                textStyle: GoogleFonts.montserrat(fontSize: 10, fontWeight: FontWeight.bold),
                                              ),
                                              child: const Text('NOT INTERESTED'),
                                            ),
                                          ],
                                        ),
                                      ],
                                    ],
                                  ),
                                ),
                              );
                            },
                          ),
                        ),
                ),
    );
  }

  Widget _buildSearchHeader(ColorScheme scheme) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const SizedBox(height: 8),
        Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            IconButton(
              onPressed: () => context.pop(),
              icon: Container(
                padding: const EdgeInsets.all(8),
                decoration: BoxDecoration(
                  color: scheme.onSurface.withValues(alpha: 0.03),
                  borderRadius: BorderRadius.circular(10),
                  border: Border.all(color: scheme.outlineVariant.withValues(alpha: 0.3)),
                ),
                child: Icon(LucideIcons.arrowLeft, size: 16, color: scheme.onSurface),
              ),
            ),
            Column(
              children: [
                Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Container(width: 4, height: 4, decoration: BoxDecoration(color: scheme.primary, shape: BoxShape.circle)),
                    const SizedBox(width: 8),
                    Text(
                      'VISITS CRM',
                      style: GoogleFonts.montserrat(fontWeight: FontWeight.w900, fontSize: 13, letterSpacing: 1.2),
                    ),
                  ],
                ),
                Text(
                  'CP CLIENT TRACKING SYSTEM',
                  style: GoogleFonts.montserrat(fontSize: 9, fontWeight: FontWeight.w700, color: scheme.onSurface.withValues(alpha: 0.5), letterSpacing: 0.5),
                ),
              ],
            ),
            IconButton(
              onPressed: () => _load(page: _page),
              icon: Container(
                padding: const EdgeInsets.all(8),
                decoration: BoxDecoration(
                  color: scheme.onSurface.withValues(alpha: 0.03),
                  borderRadius: BorderRadius.circular(10),
                  border: Border.all(color: scheme.outlineVariant.withValues(alpha: 0.3)),
                ),
                child: Icon(LucideIcons.refreshCw, size: 16, color: scheme.onSurface),
              ),
            ),
          ],
        ),
        const SizedBox(height: 24),
        Container(
          decoration: BoxDecoration(
            color: scheme.surface,
            borderRadius: BorderRadius.circular(50),
            boxShadow: [
              BoxShadow(
                color: Colors.black.withValues(alpha: 0.08),
                blurRadius: 20,
                offset: const Offset(0, 10),
              ),
            ],
            border: Border.all(color: scheme.outlineVariant.withValues(alpha: 0.4)),
          ),
          child: TextField(
            style: GoogleFonts.montserrat(fontSize: 12, fontWeight: FontWeight.bold),
            decoration: InputDecoration(
              hintText: 'SEARCH CLIENT OR PROJECT...',
              hintStyle: GoogleFonts.montserrat(fontSize: 10, fontWeight: FontWeight.w800, color: scheme.onSurface.withValues(alpha: 0.3), letterSpacing: 1.0),
              prefixIcon: Icon(LucideIcons.search, size: 18, color: scheme.onSurface.withValues(alpha: 0.4)),
              border: InputBorder.none,
              contentPadding: const EdgeInsets.symmetric(vertical: 16),
            ),
          ),
        ),
        const SizedBox(height: 24),
      ],
    );
  }

  Widget _buildEmptyState(ColorScheme scheme) {
    return Column(
      children: [
        _buildSearchHeader(scheme),
        const SizedBox(height: 20),
        Container(
          width: double.infinity,
          padding: const EdgeInsets.symmetric(vertical: 80, horizontal: 40),
          decoration: BoxDecoration(
            color: scheme.onSurface.withValues(alpha: 0.02),
            borderRadius: BorderRadius.circular(32),
            border: Border.all(color: scheme.outlineVariant.withValues(alpha: 0.2), style: BorderStyle.solid),
          ),
          child: Text(
            'NO RECORDS FOUND MATCHING YOUR SEARCH',
            textAlign: TextAlign.center,
            style: GoogleFonts.montserrat(fontSize: 12, fontWeight: FontWeight.w800, color: scheme.onSurface.withValues(alpha: 0.8), letterSpacing: 1.5, height: 1.5),
          ),
        ),
      ],
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
            icon: Icon(LucideIcons.chevronLeft, size: 18, color: _page > 1 ? scheme.onSurface : scheme.onSurface.withValues(alpha: 0.2)),
          ),
          const SizedBox(width: 12),
          Text(
            'PAGE $_page / $_totalPages',
            style: GoogleFonts.montserrat(fontSize: 10, fontWeight: FontWeight.w900, letterSpacing: 1.2),
          ),
          const SizedBox(width: 12),
          IconButton(
            onPressed: _page < _totalPages ? () => _load(page: _page + 1) : null,
            icon: Icon(LucideIcons.chevronRight, size: 18, color: _page < _totalPages ? scheme.onSurface : scheme.onSurface.withValues(alpha: 0.2)),
          ),
        ],
      ),
    );
  }

  Widget _statusChip(ColorScheme scheme, String status) {
    Color bg;
    Color fg;
    switch (status) {
      case 'NEW':
        bg = Colors.blue.withValues(alpha: 0.12);
        fg = Colors.blue;
        break;
      case 'INTERESTED':
        bg = Colors.amber.withValues(alpha: 0.12);
        fg = Colors.amber.shade800;
        break;
      case 'NOT_INTERESTED':
        bg = Colors.red.withValues(alpha: 0.12);
        fg = Colors.red;
        break;
      case 'CLOSED':
        bg = Colors.green.withValues(alpha: 0.12);
        fg = Colors.green;
        break;
      default:
        bg = scheme.surfaceContainerHighest;
        fg = scheme.onSurfaceVariant;
    }
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
      decoration: BoxDecoration(
        color: bg,
        borderRadius: BorderRadius.circular(8),
        border: Border.all(color: fg.withValues(alpha: 0.25)),
      ),
      child: Text(
        status.replaceAll('_', ' '),
        style: GoogleFonts.montserrat(fontSize: 9, fontWeight: FontWeight.w800, color: fg, letterSpacing: 0.5),
      ),
    );
  }
}
