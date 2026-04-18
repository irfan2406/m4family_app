import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:intl/intl.dart';
import 'package:lucide_icons/lucide_icons.dart';
import 'package:m4_mobile/presentation/providers/auth_provider.dart';

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

  Future<void> _addTracker() async {
    final nameCtrl = TextEditingController();
    final projCtrl = TextEditingController();
    final uid = ref.read(authProvider).user?['id']?.toString() ?? ref.read(authProvider).user?['_id']?.toString();
    if (uid == null || uid.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('Missing user id')));
      return;
    }
    String status = 'Pending';
    final ok = await showDialog<bool>(
      context: context,
      builder: (ctx) => StatefulBuilder(
        builder: (ctx, setSt) => AlertDialog(
          title: const Text('New pipeline entry'),
          content: SingleChildScrollView(
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                TextField(controller: nameCtrl, decoration: const InputDecoration(labelText: 'Customer name')),
                TextField(controller: projCtrl, decoration: const InputDecoration(labelText: 'Project')),
                DropdownButton<String>(
                  isExpanded: true,
                  value: status,
                  items: _statuses
                      .where((s) => s != 'All')
                      .map((s) => DropdownMenuItem(value: s, child: Text(s)))
                      .toList(),
                  onChanged: (v) => setSt(() => status = v ?? status),
                ),
              ],
            ),
          ),
          actions: [
            TextButton(onPressed: () => Navigator.pop(ctx, false), child: const Text('Cancel')),
            FilledButton(onPressed: () => Navigator.pop(ctx, true), child: const Text('Save')),
          ],
        ),
      ),
    );
    if (ok != true || !mounted) return;
    if (nameCtrl.text.trim().isEmpty || projCtrl.text.trim().isEmpty) return;
    try {
      final res = await ref.read(apiClientProvider).createCpTracker({
        'cpId': uid,
        'customerName': nameCtrl.text.trim(),
        'project': projCtrl.text.trim(),
        'status': status,
      });
      if (!mounted) return;
      if (res.statusCode == 201 && res.data['status'] == true) {
        ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('Tracker created')));
        await _load();
      } else {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text(res.data['message']?.toString() ?? 'Failed')),
        );
      }
    } catch (e) {
      if (mounted) ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text('$e')));
    }
  }

  @override
  Widget build(BuildContext context) {
    final scheme = Theme.of(context).colorScheme;
    final fmt = NumberFormat.currency(locale: 'en_IN', symbol: '₹', decimalDigits: 0);

    return Scaffold(
      appBar: AppBar(
        automaticallyImplyLeading: !widget.embeddedInShell,
        leading: widget.embeddedInShell
            ? null
            : IconButton(icon: const Icon(LucideIcons.arrowLeft), onPressed: () => context.pop()),
        title: Text('Success pipeline', style: GoogleFonts.montserrat(fontWeight: FontWeight.w800)),
      ),
      floatingActionButton: FloatingActionButton.extended(
        onPressed: _addTracker,
        icon: const Icon(LucideIcons.plus),
        label: const Text('Add'),
      ),
      body: _loading
          ? const Center(child: CircularProgressIndicator())
          : RefreshIndicator(
              onRefresh: _load,
              child: ListView(
                padding: const EdgeInsets.all(16),
                children: [
                  if (_summary != null) ...[
                    Wrap(
                      spacing: 8,
                      runSpacing: 8,
                      children: [
                        _chip('Bookings', '${_summary!['totalTrackers'] ?? 0}', scheme),
                        _chip('Commission', fmt.format((_summary!['totalCommission'] ?? 0) as num), scheme),
                        _chip('Visits', '${_meetings.length}', scheme),
                      ],
                    ),
                    const SizedBox(height: 16),
                  ],
                  SingleChildScrollView(
                    scrollDirection: Axis.horizontal,
                    child: Row(
                      children: _statuses
                          .map((s) => Padding(
                                padding: const EdgeInsets.only(right: 8),
                                child: ChoiceChip(
                                  label: Text(s, style: const TextStyle(fontSize: 11)),
                                  selected: _statusFilter == s,
                                  onSelected: (_) {
                                    setState(() => _statusFilter = s);
                                    _load();
                                  },
                                ),
                              ))
                          .toList(),
                    ),
                  ),
                  const SizedBox(height: 12),
                  TextField(
                    decoration: const InputDecoration(
                      hintText: 'Search customer or project',
                      prefixIcon: Icon(LucideIcons.search, size: 20),
                      border: OutlineInputBorder(),
                      isDense: true,
                    ),
                    onChanged: (v) => setState(() => _search = v),
                  ),
                  const SizedBox(height: 16),
                  _monthHeader(context),
                  const SizedBox(height: 8),
                  _calendarGrid(),
                  const SizedBox(height: 20),
                  Text(
                    'PIPELINE',
                    style: GoogleFonts.montserrat(fontWeight: FontWeight.w800, letterSpacing: 2, fontSize: 10),
                  ),
                  const SizedBox(height: 8),
                  ..._filtered.map((t) {
                    final st = (t['status'] ?? '').toString();
                    return Card(
                      margin: const EdgeInsets.only(bottom: 10),
                      child: ListTile(
                        title: Text((t['customerName'] ?? '').toString(), style: const TextStyle(fontWeight: FontWeight.bold)),
                        subtitle: Text('${t['project']} · ${fmt.format((t['commissionEarned'] ?? 0) as num)}'),
                        trailing: Chip(label: Text(st, style: const TextStyle(fontSize: 10))),
                      ),
                    );
                  }),
                ],
              ),
            ),
    );
  }

  Widget _chip(String label, String value, ColorScheme scheme) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: scheme.outlineVariant),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(label, style: TextStyle(fontSize: 9, color: scheme.outline)),
          Text(value, style: const TextStyle(fontWeight: FontWeight.bold)),
        ],
      ),
    );
  }

  Widget _monthHeader(BuildContext context) {
    return Row(
      mainAxisAlignment: MainAxisAlignment.spaceBetween,
      children: [
        IconButton(
          onPressed: () => setState(() => _month = DateTime(_month.year, _month.month - 1)),
          icon: const Icon(LucideIcons.chevronLeft),
        ),
        Text(DateFormat('MMMM yyyy').format(DateTime(_month.year, _month.month)), style: GoogleFonts.montserrat(fontWeight: FontWeight.bold)),
        IconButton(
          onPressed: () => setState(() => _month = DateTime(_month.year, _month.month + 1)),
          icon: const Icon(LucideIcons.chevronRight),
        ),
      ],
    );
  }

  Widget _calendarGrid() {
    final first = DateTime(_month.year, _month.month, 1);
    final daysInMonth = DateTime(_month.year, _month.month + 1, 0).day;
    final startWeekday = first.weekday % 7;
    final cells = <Widget>[];
    for (var i = 0; i < startWeekday; i++) {
      cells.add(const SizedBox.shrink());
    }
    for (var d = 1; d <= daysInMonth; d++) {
      final day = DateTime(_month.year, _month.month, d);
      final sel = _selectedDay != null &&
          _selectedDay!.year == day.year &&
          _selectedDay!.month == day.month &&
          _selectedDay!.day == day.day;
      cells.add(
        InkWell(
          onTap: () => setState(() => _selectedDay = _selectedDay == day ? null : day),
          child: Container(
            alignment: Alignment.center,
            margin: const EdgeInsets.all(2),
            decoration: BoxDecoration(
              color: sel ? Colors.purple.withValues(alpha: 0.3) : null,
              borderRadius: BorderRadius.circular(8),
            ),
            child: Text('$d'),
          ),
        ),
      );
    }
    return GridView.count(
      shrinkWrap: true,
      physics: const NeverScrollableScrollPhysics(),
      crossAxisCount: 7,
      childAspectRatio: 1.2,
      children: cells,
    );
  }
}
