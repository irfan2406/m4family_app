import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:intl/intl.dart';
import 'package:lucide_icons/lucide_icons.dart';
import 'package:m4_mobile/presentation/providers/auth_provider.dart';

import 'package:m4_mobile/presentation/widgets/cp_sidebar_menu.dart';

/// Web `/cp/tracker` — `GET /api/cp/tracker`, leads for visits, pipeline cards.
class CpTrackerScreen extends ConsumerStatefulWidget {
  const CpTrackerScreen({super.key, this.embeddedInShell = false});

  /// When true (main shell tab), hide back button — matches web bottom-nav UX.
  final bool embeddedInShell;

  @override
  ConsumerState<CpTrackerScreen> createState() => _CpTrackerScreenState();
}

class _CpTrackerScreenState extends ConsumerState<CpTrackerScreen> {
  List<dynamic> _trackers = [];
  Map<String, dynamic>? _summary;
  List<dynamic> _meetings = [];
  bool _loading = true;
  String _search = '';
  String _statusFilter = 'All';
  DateTime _month = DateTime.now();
  DateTime? _selectedDay;

  static const _statuses = ['All', 'Pending', 'In Progress', 'Completed', 'Cancelled'];

  @override
  void initState() {
    super.initState();
    _load();
  }

  Future<void> _load() async {
    setState(() => _loading = true);
    try {
      final api = ref.read(apiClientProvider);
      final qp = <String, dynamic>{};
      if (_statusFilter != 'All') qp['status'] = _statusFilter;
      final tr = await api.getCpTracker(queryParameters: qp);
      if (tr.statusCode == 200 && tr.data['status'] == true) {
        final d = tr.data['data'];
        if (d is List) _trackers = List<dynamic>.from(d);
        final s = tr.data['summary'];
        if (s is Map) _summary = Map<String, dynamic>.from(s);
      }
      try {
        final lr = await api.getLeads(queryParameters: {'source': 'cp'});
        if (lr.statusCode == 200 && lr.data['status'] == true) {
          final list = lr.data['data'];
          if (list is List) {
            _meetings = list.where((l) {
              final st = (l['status'] ?? '').toString().toLowerCase();
              return st.contains('site') || st.contains('visit') || l['visitDate'] != null;
            }).toList();
          }
        }
      } catch (_) {}
    } catch (_) {}
    if (mounted) setState(() => _loading = false);
  }

  List<dynamic> get _filtered {
    return _trackers.where((t) {
      final q = _search.toLowerCase();
      final name = (t['customerName'] ?? '').toString().toLowerCase();
      final proj = (t['project'] ?? '').toString().toLowerCase();
      final searchOk = q.isEmpty || name.contains(q) || proj.contains(q);
      if (_selectedDay == null) return searchOk;
      final u = t['updatedAt'];
      if (u == null) return false;
      final dt = DateTime.tryParse(u.toString());
      if (dt == null) return searchOk;
      return searchOk &&
          dt.year == _selectedDay!.year &&
          dt.month == _selectedDay!.month &&
          dt.day == _selectedDay!.day;
    }).toList();
  }

  @override
  Widget build(BuildContext context) {
    final scheme = Theme.of(context).colorScheme;
    final fmt = NumberFormat.currency(locale: 'en_IN', symbol: '₹', decimalDigits: 0);

    return Scaffold(
      backgroundColor: scheme.surface,
      drawer: const CpSidebarMenu(),
      body: SafeArea(
        child: Column(
          children: [
            _buildCustomHeader(scheme),
            Expanded(
              child: _loading
                  ? const Center(child: CircularProgressIndicator(color: Colors.black, strokeWidth: 2))
                  : RefreshIndicator(
                      onRefresh: _load,
                      color: Colors.black,
                      child: ListView(
                        padding: const EdgeInsets.symmetric(horizontal: 20),
                        children: [
                          const SizedBox(height: 12),
                          _buildStatBar(scheme, fmt),
                          const SizedBox(height: 24),
                          _buildSearchAndFilter(scheme),
                          const SizedBox(height: 24),
                          ..._filtered.map((t) => _buildPipelineCard(t, scheme, fmt)),
                          const SizedBox(height: 32),
                          _buildPulseCalendar(scheme),
                          const SizedBox(height: 40),
                        ],
                      ),
                    ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildCustomHeader(ColorScheme scheme) {
    return Padding(
      padding: const EdgeInsets.fromLTRB(16, 12, 16, 20),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Row(
            children: [
              Builder(
                builder: (ctx) => IconButton(
                  onPressed: () => Scaffold.of(ctx).openDrawer(),
                  icon: const Icon(LucideIcons.menu, size: 18),
                  style: IconButton.styleFrom(
                    backgroundColor: scheme.onSurface.withValues(alpha: 0.05),
                    shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
                  ),
                ),
              ),
              const SizedBox(width: 8),
              IconButton(
                onPressed: () => context.go('/cp/hub'),
                icon: const Icon(LucideIcons.arrowLeft, size: 18),
                style: IconButton.styleFrom(
                  backgroundColor: scheme.onSurface.withValues(alpha: 0.05),
                  shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
                ),
              ),
            ],
          ),
          Column(
            children: [
              Row(
                children: [
                  Container(width: 4, height: 4, decoration: const BoxDecoration(color: Colors.purple, shape: BoxShape.circle)),
                  const SizedBox(width: 6),
                  Text(
                    'SUCCESS PIPELINE',
                    style: GoogleFonts.montserrat(fontSize: 14, fontWeight: FontWeight.w900, color: scheme.onSurface, letterSpacing: 1.5),
                  ),
                ],
              ),
              const SizedBox(height: 2),
              Text(
                'STATEMENT & PULSE',
                style: GoogleFonts.montserrat(fontSize: 8, fontWeight: FontWeight.w900, color: scheme.onSurface.withValues(alpha: 0.5), letterSpacing: 2),
              ),
            ],
          ),
          IconButton(
            onPressed: () => context.push('/cp/profile/settings'),
            icon: const Icon(LucideIcons.settings, size: 18),
            style: IconButton.styleFrom(
              backgroundColor: scheme.onSurface.withValues(alpha: 0.05),
              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildStatBar(ColorScheme scheme, NumberFormat fmt) {
    final s = _summary ?? {};
    return SingleChildScrollView(
      scrollDirection: Axis.horizontal,
      child: Row(
        children: [
          _statBox(LucideIcons.package, 'BOOKINGS', '${s['totalTrackers'] ?? 0}', Colors.blue, scheme),
          const SizedBox(width: 10),
          _statBox(LucideIcons.wallet, 'COMMISSION', fmt.format((s['totalCommission'] ?? 0) as num), Colors.grey, scheme),
          const SizedBox(width: 10),
          _statBox(LucideIcons.checkCircle, 'SETTLED', fmt.format(1000), Colors.teal, scheme),
          const SizedBox(width: 10),
          _statBox(LucideIcons.navigation, 'VISITS', '${_meetings.length}', Colors.orange, scheme),
        ],
      ),
    );
  }

  Widget _statBox(IconData icon, String label, String value, Color iconColor, ColorScheme scheme) {
    return Container(
      width: 100,
      padding: const EdgeInsets.symmetric(vertical: 14),
      decoration: BoxDecoration(
        color: scheme.surface,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: scheme.outlineVariant.withValues(alpha: 0.3)),
      ),
      child: Column(
        children: [
          Icon(icon, color: iconColor.withValues(alpha: 0.6), size: 16),
          const SizedBox(height: 8),
          Text(label, style: GoogleFonts.montserrat(fontSize: 7, fontWeight: FontWeight.w900, color: scheme.onSurface.withValues(alpha: 0.4), letterSpacing: 1)),
          const SizedBox(height: 4),
          Text(value, style: GoogleFonts.montserrat(fontSize: 11, fontWeight: FontWeight.w900, color: scheme.onSurface)),
        ],
      ),
    );
  }

  Widget _buildSearchAndFilter(ColorScheme scheme) {
    return Row(
      children: [
        Expanded(
          child: Container(
            height: 48,
            decoration: BoxDecoration(
              color: scheme.surface,
              borderRadius: BorderRadius.circular(12),
              border: Border.all(color: scheme.outlineVariant.withValues(alpha: 0.3)),
            ),
            padding: const EdgeInsets.symmetric(horizontal: 16),
            child: Row(
              children: [
                Icon(LucideIcons.search, size: 18, color: scheme.onSurface.withValues(alpha: 0.3)),
                const SizedBox(width: 12),
                Expanded(
                  child: TextField(
                    onChanged: (v) => setState(() => _search = v),
                    style: GoogleFonts.montserrat(fontSize: 12, fontWeight: FontWeight.w700),
                    decoration: InputDecoration(
                      hintText: 'SEARCH PROSPECT...',
                      hintStyle: GoogleFonts.montserrat(fontSize: 10, fontWeight: FontWeight.w900, color: scheme.onSurface.withValues(alpha: 0.3), letterSpacing: 1.5),
                      border: InputBorder.none,
                    ),
                  ),
                ),
              ],
            ),
          ),
        ),
        const SizedBox(width: 12),
        Container(
          height: 48,
          padding: const EdgeInsets.symmetric(horizontal: 16),
          decoration: BoxDecoration(
            color: scheme.surface,
            borderRadius: BorderRadius.circular(12),
            border: Border.all(color: scheme.outlineVariant.withValues(alpha: 0.3)),
          ),
          child: DropdownButtonHideUnderline(
            child: DropdownButton<String>(
              value: _statusFilter,
              icon: const Padding(padding: EdgeInsets.only(left: 8), child: Icon(LucideIcons.chevronDown, size: 14)),
              style: GoogleFonts.montserrat(fontSize: 10, fontWeight: FontWeight.w900, color: scheme.onSurface, letterSpacing: 1),
              items: _statuses.map((s) => DropdownMenuItem(value: s, child: Text(s.toUpperCase()))).toList(),
              onChanged: (v) {
                setState(() => _statusFilter = v ?? 'All');
                _load();
              },
            ),
          ),
        ),
      ],
    );
  }

  Widget _buildPipelineCard(dynamic t, ColorScheme scheme, NumberFormat fmt) {
    final status = (t['status'] ?? 'PENDING').toString().toUpperCase();
    final isCompleted = status == 'COMPLETED';

    return Container(
      margin: const EdgeInsets.only(bottom: 20),
      decoration: BoxDecoration(
        color: scheme.surface,
        borderRadius: BorderRadius.circular(32),
        border: Border.all(color: scheme.outlineVariant.withValues(alpha: 0.3)),
        boxShadow: [
          BoxShadow(color: Colors.black.withValues(alpha: 0.05), blurRadius: 30, offset: const Offset(0, 15)),
        ],
      ),
      child: Column(
        children: [
          Padding(
            padding: const EdgeInsets.all(20),
            child: Column(
              children: [
                Row(
                  children: [
                    Container(
                      width: 44,
                      height: 44,
                      decoration: BoxDecoration(
                        color: scheme.onSurface.withValues(alpha: 0.05),
                        shape: BoxShape.circle,
                        border: Border.all(color: scheme.outlineVariant.withValues(alpha: 0.3)),
                      ),
                      child: Icon(LucideIcons.user, size: 18, color: scheme.onSurface.withValues(alpha: 0.7)),
                    ),
                    const SizedBox(width: 12),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            (t['customerName'] ?? 'UNKNOWN').toString().toUpperCase(),
                            style: GoogleFonts.montserrat(fontSize: 13, fontWeight: FontWeight.w900, color: scheme.onSurface, letterSpacing: 0.5),
                          ),
                          Row(
                            children: [
                              Icon(LucideIcons.home, size: 12, color: scheme.onSurface.withValues(alpha: 0.3)),
                              const SizedBox(width: 4),
                              Text(
                                (t['project'] ?? 'PROJECT').toString().toUpperCase(),
                                style: GoogleFonts.montserrat(fontSize: 8, fontWeight: FontWeight.w900, color: scheme.onSurface.withValues(alpha: 0.4), letterSpacing: 1),
                              ),
                            ],
                          ),
                        ],
                      ),
                    ),
                    Container(
                      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
                      decoration: BoxDecoration(
                        color: isCompleted ? Colors.green.withValues(alpha: 0.1) : scheme.onSurface.withValues(alpha: 0.05),
                        borderRadius: BorderRadius.circular(20),
                      ),
                      child: Text(
                        status,
                        style: GoogleFonts.montserrat(fontSize: 8, fontWeight: FontWeight.w900, color: isCompleted ? Colors.green[700] : scheme.onSurface.withValues(alpha: 0.4), letterSpacing: 0.5),
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 24),
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    _traceInfo('PROPERTY TRACE', 'UNIT: ${t['unit'] ?? '501'}', 'CONFIG: ${t['config'] ?? '2BHK'}', scheme),
                    _traceInfo('FINANCIAL TRACE', 'PAYOUT: ${fmt.format((t['commissionEarned'] ?? 0) as num)}', 'VISITS: ${t['visits'] ?? '1'}', scheme),
                  ],
                ),
              ],
            ),
          ),
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 16),
            decoration: BoxDecoration(
              color: scheme.onSurface.withValues(alpha: 0.02),
              borderRadius: const BorderRadius.vertical(bottom: Radius.circular(32)),
              border: Border.all(color: scheme.outlineVariant.withValues(alpha: 0.1)),
            ),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  children: [
                    Icon(LucideIcons.layout, size: 14, color: scheme.onSurface.withValues(alpha: 0.2)),
                    const SizedBox(width: 8),
                    Text(
                      'VERIFICATION TRACE',
                      style: GoogleFonts.montserrat(fontSize: 8, fontWeight: FontWeight.w900, color: scheme.onSurface.withValues(alpha: 0.2), letterSpacing: 1.5),
                    ),
                  ],
                ),
                const SizedBox(height: 20),
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    _stepIndicator('SETTLED', isCompleted, scheme),
                    _stepIndicator('INITIATED', isCompleted, scheme),
                    _stepIndicator('CLEARED', false, scheme),
                  ],
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _traceInfo(String title, String line1, String line2, ColorScheme scheme) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(title, style: GoogleFonts.montserrat(fontSize: 8, fontWeight: FontWeight.w900, color: scheme.onSurface.withValues(alpha: 0.3), letterSpacing: 1.5)),
        const SizedBox(height: 10),
        Text(line1, style: GoogleFonts.montserrat(fontSize: 10, fontWeight: FontWeight.w900, color: scheme.onSurface.withValues(alpha: 0.7))),
        const SizedBox(height: 4),
        Text(line2, style: GoogleFonts.montserrat(fontSize: 10, fontWeight: FontWeight.w900, color: scheme.onSurface.withValues(alpha: 0.7))),
      ],
    );
  }

  Widget _stepIndicator(String label, bool active, ColorScheme scheme) {
    return Column(
      children: [
        Text(label, style: GoogleFonts.montserrat(fontSize: 7, fontWeight: FontWeight.w900, color: active ? scheme.onSurface.withValues(alpha: 0.6) : scheme.onSurface.withValues(alpha: 0.2), letterSpacing: 1)),
        const SizedBox(height: 8),
        Container(
          width: 80,
          height: 3,
          decoration: BoxDecoration(
            color: active ? Colors.purple : scheme.onSurface.withValues(alpha: 0.05),
            borderRadius: BorderRadius.circular(2),
          ),
        ),
      ],
    );
  }

  Widget _buildPulseCalendar(ColorScheme scheme) {
    return Container(
      padding: const EdgeInsets.all(24),
      decoration: BoxDecoration(
        color: scheme.surface,
        borderRadius: BorderRadius.circular(32),
        border: Border.all(color: scheme.outlineVariant.withValues(alpha: 0.3)),
        boxShadow: [
          BoxShadow(color: Colors.black.withValues(alpha: 0.05), blurRadius: 30, offset: const Offset(0, 15)),
        ],
      ),
      child: Column(
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Icon(LucideIcons.activity, size: 20, color: scheme.onSurface),
              Row(
                children: [
                  IconButton(onPressed: () => setState(() => _month = DateTime(_month.year, _month.month - 1)), icon: const Icon(LucideIcons.chevronLeft, size: 18)),
                  const SizedBox(width: 12),
                  Text(DateFormat('MMM yyyy').format(_month).toUpperCase(), style: GoogleFonts.montserrat(fontSize: 11, fontWeight: FontWeight.w900, letterSpacing: 2)),
                  const SizedBox(width: 12),
                  IconButton(onPressed: () => setState(() => _month = DateTime(_month.year, _month.month + 1)), icon: const Icon(LucideIcons.chevronRight, size: 18)),
                ],
              ),
            ],
          ),
          const SizedBox(height: 24),
          _calendarGridBoard(scheme),
        ],
      ),
    );
  }

  Widget _calendarGridBoard(ColorScheme scheme) {
    final first = DateTime(_month.year, _month.month, 1);
    final daysInMonth = DateTime(_month.year, _month.month + 1, 0).day;
    final startWeekday = (first.weekday % 7);
    
    final days = ['M', 'T', 'W', 'T', 'F', 'S', 'S'];
    
    return Column(
      children: [
        Row(
          mainAxisAlignment: MainAxisAlignment.spaceAround,
          children: days.map((d) => Text(d, style: GoogleFonts.montserrat(fontSize: 8, fontWeight: FontWeight.w900, color: scheme.onSurface.withValues(alpha: 0.2)))).toList(),
        ),
        const SizedBox(height: 16),
        GridView.builder(
          shrinkWrap: true,
          physics: const NeverScrollableScrollPhysics(),
          gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(crossAxisCount: 7, childAspectRatio: 1.2),
          itemCount: startWeekday + daysInMonth,
          itemBuilder: (context, i) {
            if (i < startWeekday) return const SizedBox.shrink();
            final dayNo = i - startWeekday + 1;
            final day = DateTime(_month.year, _month.month, dayNo);
            final sel = _selectedDay != null && _selectedDay!.day == day.day && _selectedDay!.month == day.month;

            return Center(
              child: GestureDetector(
                onTap: () => setState(() => _selectedDay = sel ? null : day),
                child: Text(
                  '$dayNo',
                  style: GoogleFonts.montserrat(fontSize: 10, fontWeight: sel ? FontWeight.w900 : FontWeight.w700, color: sel ? Colors.purple : scheme.onSurface.withValues(alpha: 0.8)),
                ),
              ),
            );
          },
        ),
      ],
    );
  }
}

