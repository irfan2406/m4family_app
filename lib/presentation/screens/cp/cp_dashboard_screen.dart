import 'package:cached_network_image/cached_network_image.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:lucide_icons/lucide_icons.dart';
import 'package:m4_mobile/presentation/providers/auth_provider.dart';
import 'package:m4_mobile/presentation/providers/project_provider.dart';
import 'package:url_launcher/url_launcher.dart';

/// Web `/cp` (Partner Dashboard): wallet + referrals as leads + projects + lifecycle.
class CpDashboardScreen extends ConsumerStatefulWidget {
  const CpDashboardScreen({super.key, this.embeddedInShell = false});

  /// When true (main shell tab), hide back button.
  final bool embeddedInShell;

  @override
  ConsumerState<CpDashboardScreen> createState() => _CpDashboardScreenState();
}

class _CpDashboardScreenState extends ConsumerState<CpDashboardScreen> {
  Map<String, dynamic>? _wallet;
  List<dynamic> _referrals = [];
  bool _loading = true;
  String _searchQuery = '';
  bool _showSearch = false;

  @override
  void initState() {
    super.initState();
    _load();
  }

  Future<void> _load() async {
    setState(() => _loading = true);
    try {
      final api = ref.read(apiClientProvider);
      final w = await api.getCpWallet();
      final r = await api.getCpReferrals();
      if (!mounted) return;
      if (w.statusCode == 200 && w.data['status'] == true) {
        final d = w.data['data'];
        _wallet = d is Map<String, dynamic> ? d : (d is Map ? Map<String, dynamic>.from(d) : null);
      }
      if (r.statusCode == 200 && r.data['status'] == true) {
        final d = r.data['data'];
        if (d is List) {
          _referrals = List<dynamic>.from(d);
        }
      }
    } catch (_) {}
    if (mounted) setState(() => _loading = false);
  }

  num _balance() {
    final w = _wallet;
    if (w == null) return 0;
    return (w['balance'] ?? w['availableBalance'] ?? w['cashBalance'] ?? 0) as num? ?? 0;
  }

  num _totalEarned() {
    final w = _wallet;
    if (w == null) return 0;
    return (w['totalEarned'] ?? 0) as num? ?? 0;
  }

  String _leadName(dynamic lead) {
    return (lead['referralName'] ?? lead['clientName'] ?? lead['name'] ?? 'Lead').toString();
  }

  String _leadPhone(dynamic lead) {
    return (lead['referralPhone'] ?? lead['clientPhone'] ?? lead['phone'] ?? '').toString();
  }

  String _leadProject(dynamic lead) {
    final p = lead['projectId'];
    if (p is Map) return (p['title'] ?? '').toString();
    return (lead['projectName'] ?? 'General').toString();
  }

  String _status(dynamic lead) {
    return (lead['status'] ?? 'Pending').toString();
  }

  double _progressForStatus(String s) {
    if (['CLEARED', 'COMMISSION_ELIGIBLE'].contains(s)) return 1;
    if (s == 'BOOKING_DONE') return 0.75;
    if (s == 'VISIT_DONE') return 0.5;
    if (s == 'VISIT_SCHEDULED') return 0.25;
    return 0.1;
  }

  Future<void> _patchStatus(String id, String status) async {
    try {
      final api = ref.read(apiClientProvider);
      final res = await api.patchCpReferralStatus(id, status);
      if (!mounted) return;
      if (res.statusCode == 200 && res.data['status'] == true) {
        ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('Status updated')));
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

  void _showStatusSheet(String id, String current) {
    const options = [
      'NEW',
      'VISIT_SCHEDULED',
      'VISIT_DONE',
      'FOLLOW_UP',
      'BOOKING_DONE',
      'COMMISSION_ELIGIBLE',
      'CLEARED',
      'LOST',
    ];
    showModalBottomSheet<void>(
      context: context,
      builder: (ctx) => SafeArea(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Padding(
              padding: const EdgeInsets.all(16),
              child: Text('Update status', style: GoogleFonts.montserrat(fontWeight: FontWeight.bold)),
            ),
            ...options.map(
              (s) => ListTile(
                title: Text(s.replaceAll('_', ' ')),
                trailing: s == current ? const Icon(Icons.check, size: 18) : null,
                onTap: () {
                  Navigator.pop(ctx);
                  _patchStatus(id, s);
                },
              ),
            ),
          ],
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final user = ref.watch(authProvider).user;
    final projectsAsync = ref.watch(projectsProvider);
    final scheme = Theme.of(context).colorScheme;

    final filtered = _referrals.where((l) {
      final q = _searchQuery.toLowerCase();
      if (q.isEmpty) return true;
      return _leadName(l).toLowerCase().contains(q) || _leadProject(l).toLowerCase().contains(q);
    }).toList();

    return Scaffold(
      body: CustomScrollView(
        slivers: [
          SliverAppBar(
            pinned: true,
            automaticallyImplyLeading: !widget.embeddedInShell,
            leading: widget.embeddedInShell
                ? null
                : IconButton(
                    icon: const Icon(LucideIcons.arrowLeft),
                    onPressed: () => context.pop(),
                  ),
            title: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  'Partner Dashboard',
                  style: GoogleFonts.montserrat(fontWeight: FontWeight.w800, fontSize: 18),
                ),
                Text(
                  user?['cpId']?.toString() ?? user?['phone']?.toString() ?? '',
                  style: TextStyle(fontSize: 10, color: scheme.onSurface.withValues(alpha: 0.55)),
                ),
              ],
            ),
          ),
          SliverToBoxAdapter(
            child: Padding(
              padding: const EdgeInsets.all(16),
              child: _loading
                  ? const Center(child: Padding(padding: EdgeInsets.all(32), child: CircularProgressIndicator()))
                  : Column(
                      crossAxisAlignment: CrossAxisAlignment.stretch,
                      children: [
                        Card(
                          color: scheme.inverseSurface,
                          elevation: 4,
                          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(28)),
                          child: Padding(
                            padding: const EdgeInsets.all(24),
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Row(
                                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                                  children: [
                                    Text(
                                      'AVAILABLE COMMISSION',
                                      style: GoogleFonts.montserrat(
                                        fontSize: 9,
                                        fontWeight: FontWeight.w800,
                                        letterSpacing: 2,
                                        color: scheme.onInverseSurface.withValues(alpha: 0.55),
                                      ),
                                    ),
                                    Icon(LucideIcons.wallet, color: scheme.onInverseSurface.withValues(alpha: 0.8)),
                                  ],
                                ),
                                const SizedBox(height: 8),
                                Row(
                                  crossAxisAlignment: CrossAxisAlignment.baseline,
                                  textBaseline: TextBaseline.alphabetic,
                                  children: [
                                    Text(
                                      'AED ',
                                      style: TextStyle(
                                        fontSize: 14,
                                        fontStyle: FontStyle.italic,
                                        color: scheme.onInverseSurface.withValues(alpha: 0.45),
                                      ),
                                    ),
                                    Text(
                                      _balance().toString(),
                                      style: GoogleFonts.montserrat(
                                        fontSize: 40,
                                        fontWeight: FontWeight.w900,
                                        color: scheme.onInverseSurface,
                                      ),
                                    ),
                                  ],
                                ),
                                const SizedBox(height: 16),
                                Row(
                                  children: [
                                    Expanded(
                                      child: _miniStat(
                                        context,
                                        'TOTAL EARNED',
                                        'AED ${_totalEarned()}',
                                      ),
                                    ),
                                    const SizedBox(width: 12),
                                    Expanded(
                                      child: _miniStat(
                                        context,
                                        'ACTIVE LEADS',
                                        '${_referrals.length}',
                                      ),
                                    ),
                                  ],
                                ),
                                const SizedBox(height: 12),
                                Align(
                                  alignment: Alignment.centerRight,
                                  child: TextButton.icon(
                                    onPressed: () => context.push('/cp/payments'),
                                    icon: const Icon(LucideIcons.creditCard, size: 16),
                                    label: const Text('Wallet & history'),
                                  ),
                                ),
                              ],
                            ),
                          ),
                        ),
                        const SizedBox(height: 24),
                        Row(
                          mainAxisAlignment: MainAxisAlignment.spaceBetween,
                          children: [
                            Text(
                              'MARKET OPPORTUNITIES',
                              style: GoogleFonts.montserrat(fontWeight: FontWeight.w800, letterSpacing: 1),
                            ),
                            TextButton(
                              onPressed: () => context.push('/projects'),
                              child: const Text('View all'),
                            ),
                          ],
                        ),
                        SizedBox(
                          height: 220,
                          child: projectsAsync.when(
                            loading: () => const Center(child: CircularProgressIndicator()),
                            error: (_, __) => const Text('Failed to load projects'),
                            data: (projects) {
                              return ListView.separated(
                                scrollDirection: Axis.horizontal,
                                itemCount: projects.length.clamp(0, 20),
                                separatorBuilder: (_, __) => const SizedBox(width: 12),
                                itemBuilder: (context, i) {
                                  final p = projects[i];
                                  final id = p['_id']?.toString() ?? '';
                                  final img = (p['images'] is List && (p['images'] as List).isNotEmpty)
                                      ? p['images'][0].toString()
                                      : p['heroImage']?.toString() ?? '';
                                  return GestureDetector(
                                    onTap: () {
                                      if (id.isNotEmpty) context.push('/projects/$id');
                                    },
                                    child: ClipRRect(
                                      borderRadius: BorderRadius.circular(24),
                                      child: SizedBox(
                                        width: 160,
                                        child: Stack(
                                          fit: StackFit.expand,
                                          children: [
                                            if (img.isNotEmpty)
                                              CachedNetworkImage(imageUrl: img, fit: BoxFit.cover)
                                            else
                                              Container(color: Colors.grey.shade800),
                                            Container(
                                              decoration: BoxDecoration(
                                                gradient: LinearGradient(
                                                  begin: Alignment.topCenter,
                                                  end: Alignment.bottomCenter,
                                                  colors: [
                                                    Colors.transparent,
                                                    Colors.black.withValues(alpha: 0.85),
                                                  ],
                                                ),
                                              ),
                                            ),
                                            Positioned(
                                              left: 10,
                                              right: 10,
                                              bottom: 12,
                                              child: Text(
                                                (p['title'] ?? '').toString(),
                                                maxLines: 2,
                                                style: const TextStyle(
                                                  color: Colors.white,
                                                  fontWeight: FontWeight.bold,
                                                  fontSize: 12,
                                                ),
                                              ),
                                            ),
                                          ],
                                        ),
                                      ),
                                    ),
                                  );
                                },
                              );
                            },
                          ),
                        ),
                        const SizedBox(height: 24),
                        Row(
                          mainAxisAlignment: MainAxisAlignment.spaceBetween,
                          children: [
                            Text(
                              'REGISTERED LEADS',
                              style: GoogleFonts.montserrat(fontWeight: FontWeight.w800, letterSpacing: 1),
                            ),
                            IconButton(
                              onPressed: () => setState(() => _showSearch = !_showSearch),
                              icon: Icon(_showSearch ? LucideIcons.x : LucideIcons.search, size: 20),
                            ),
                          ],
                        ),
                        if (_showSearch)
                          Padding(
                            padding: const EdgeInsets.only(bottom: 12),
                            child: TextField(
                              onChanged: (v) => setState(() => _searchQuery = v),
                              decoration: const InputDecoration(
                                hintText: 'Search by name or project',
                                border: OutlineInputBorder(),
                                isDense: true,
                              ),
                            ),
                          ),
                      ],
                    ),
            ),
          ),
          if (!_loading && filtered.isEmpty)
            const SliverToBoxAdapter(
              child: Padding(
                padding: EdgeInsets.all(32),
                child: Center(child: Text('No referrals yet — add one from Referral & Rewards')),
              ),
            ),
          if (!_loading && filtered.isNotEmpty)
            SliverList(
              delegate: SliverChildBuilderDelegate(
                childCount: filtered.length,
                (context, i) {
                  final lead = filtered[i];
                  final id = lead['_id']?.toString() ?? '';
                  final status = _status(lead);
                  final phone = _leadPhone(lead);
                  return Padding(
                    padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
                    child: Card(
                      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(24)),
                      child: Padding(
                        padding: const EdgeInsets.all(20),
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
                                        _leadName(lead),
                                        style: GoogleFonts.montserrat(
                                          fontSize: 18,
                                          fontWeight: FontWeight.w800,
                                        ),
                                      ),
                                      const SizedBox(height: 4),
                                      Text(
                                        _leadProject(lead).toUpperCase(),
                                        style: TextStyle(
                                          fontSize: 10,
                                          fontWeight: FontWeight.w700,
                                          letterSpacing: 2,
                                          color: scheme.primary,
                                        ),
                                      ),
                                    ],
                                  ),
                                ),
                                Chip(
                                  label: Text(
                                    status.replaceAll('_', ' '),
                                    style: const TextStyle(fontSize: 10, fontWeight: FontWeight.bold),
                                  ),
                                ),
                              ],
                            ),
                            const SizedBox(height: 12),
                            ClipRRect(
                              borderRadius: BorderRadius.circular(8),
                              child: LinearProgressIndicator(
                                value: _progressForStatus(status),
                                minHeight: 6,
                                backgroundColor: scheme.surfaceContainerHighest,
                              ),
                            ),
                            const SizedBox(height: 16),
                            Row(
                              children: [
                                Expanded(
                                  child: OutlinedButton.icon(
                                    onPressed: phone.isEmpty
                                        ? null
                                        : () => launchUrl(Uri.parse('tel:$phone')),
                                    icon: const Icon(LucideIcons.phone, size: 16),
                                    label: const Text('Call'),
                                  ),
                                ),
                                const SizedBox(width: 8),
                                Expanded(
                                  child: FilledButton(
                                    onPressed: id.isEmpty ? null : () => _showStatusSheet(id, status),
                                    child: const Text('Update status'),
                                  ),
                                ),
                              ],
                            ),
                          ],
                        ),
                      ),
                    ),
                  );
                },
              ),
            ),
        ],
      ),
    );
  }


  Widget _miniStat(BuildContext context, String label, String value) {
    return Container(
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(16),
        color: Theme.of(context).colorScheme.inverseSurface.withValues(alpha: 0.15),
        border: Border.all(color: Colors.white.withValues(alpha: 0.08)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            label,
            style: GoogleFonts.montserrat(fontSize: 8, fontWeight: FontWeight.w800, letterSpacing: 1),
          ),
          const SizedBox(height: 4),
          Text(value, style: GoogleFonts.montserrat(fontWeight: FontWeight.bold)),
        ],
      ),
    );
  }
}
