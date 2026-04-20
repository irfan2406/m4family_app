import 'package:dio/dio.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:intl/intl.dart';
import 'package:lucide_icons/lucide_icons.dart';
import 'package:m4_mobile/presentation/providers/auth_provider.dart';

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
      appBar: AppBar(
        title: Text(
          'Visits',
          style: GoogleFonts.montserrat(fontWeight: FontWeight.w800, fontSize: 16),
        ),
        leading: IconButton(
          icon: const Icon(LucideIcons.arrowLeft),
          onPressed: () => context.pop(),
        ),
        actions: [
          IconButton(
            icon: const Icon(LucideIcons.refreshCw),
            onPressed: () => _load(page: _page),
          ),
        ],
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
              : _visits.isEmpty
                  ? Center(
                      child: Text(
                        'No visits yet',
                        style: GoogleFonts.montserrat(color: scheme.onSurfaceVariant),
                      ),
                    )
                  : RefreshIndicator(
                      onRefresh: () => _load(page: _page),
                      child: ListView.builder(
                        padding: const EdgeInsets.fromLTRB(20, 8, 20, 32),
                        itemCount: _visits.length + (_totalPages > 1 ? 1 : 0),
                        itemBuilder: (context, i) {
                          if (i == _visits.length) {
                            return Padding(
                              padding: const EdgeInsets.only(top: 16),
                              child: Row(
                                mainAxisAlignment: MainAxisAlignment.center,
                                children: [
                                  TextButton(
                                    onPressed: _page > 1
                                        ? () {
                                            _load(page: _page - 1);
                                          }
                                        : null,
                                    child: const Text('Previous'),
                                  ),
                                  Text('Page $_page / $_totalPages', style: const TextStyle(fontSize: 12)),
                                  TextButton(
                                    onPressed: _page < _totalPages
                                        ? () {
                                            _load(page: _page + 1);
                                          }
                                        : null,
                                    child: const Text('Next'),
                                  ),
                                ],
                              ),
                            );
                          }
                          final v = _visits[i];
                          final status = (v['status'] ?? '').toString();
                          final dateStr = v['visitDate'] != null
                              ? DateFormat('d MMM y, h:mm a').format(DateTime.parse(v['visitDate'].toString()).toLocal())
                              : '—';

                          return Card(
                            margin: const EdgeInsets.only(bottom: 12),
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
                                    style: GoogleFonts.montserrat(fontWeight: FontWeight.w600, fontSize: 12),
                                  ),
                                  const SizedBox(height: 4),
                                  Text(
                                    'Employee: ${_employeeName(v)}',
                                    style: GoogleFonts.montserrat(fontSize: 11, color: scheme.onSurfaceVariant),
                                  ),
                                  Text(
                                    dateStr,
                                    style: GoogleFonts.montserrat(fontSize: 10, color: scheme.onSurfaceVariant),
                                  ),
                                  if (status == 'NEW') ...[
                                    const SizedBox(height: 12),
                                    Wrap(
                                      spacing: 8,
                                      runSpacing: 8,
                                      children: [
                                        OutlinedButton(
                                          onPressed: () => _patchStatus(_visitId(v), 'INTERESTED'),
                                          child: const Text('Interested'),
                                        ),
                                        OutlinedButton(
                                          onPressed: () => _patchStatus(_visitId(v), 'NOT_INTERESTED'),
                                          child: const Text('Not interested'),
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
