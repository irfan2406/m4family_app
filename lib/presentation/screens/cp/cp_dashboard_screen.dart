import 'package:cached_network_image/cached_network_image.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:lucide_icons/lucide_icons.dart';
import 'package:m4_mobile/presentation/providers/auth_provider.dart';
import 'package:m4_mobile/presentation/providers/project_provider.dart';
import 'package:url_launcher/url_launcher.dart';

/// Web `/cp` (Partner Dashboard): high-fidelity wallet + referrals + projects + trace matrix.
class CpDashboardScreen extends ConsumerStatefulWidget {
  const CpDashboardScreen({super.key, this.embeddedInShell = false});
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
        if (d is List) _referrals = List<dynamic>.from(d);
      }
    } catch (_) {}
    if (mounted) setState(() => _loading = false);
  }

  num _balance() => (_wallet?['balance'] ?? _wallet?['availableBalance'] ?? 0) as num;
  num _totalEarned() => (_wallet?['totalEarned'] ?? 0) as num;

  String _leadName(dynamic l) => (l['referralName'] ?? l['clientName'] ?? l['name'] ?? 'Lead').toString();
  String _leadPhone(dynamic l) => (l['referralPhone'] ?? l['clientPhone'] ?? l['phone'] ?? '').toString();
  String _leadProject(dynamic l) {
    if (l['projectId'] is Map) return (l['projectId']['title'] ?? '').toString();
    return (l['projectName'] ?? 'General').toString();
  }
  String _status(dynamic l) => (l['status'] ?? 'Pending').toString();

  double _progress(String s) {
    if (['CLEARED', 'COMMISSION_ELIGIBLE'].contains(s)) return 1.0;
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
      if (res.statusCode == 200) {
        ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('Status updated')));
        _load();
      }
    } catch (e) {
      if (mounted) ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text('$e')));
    }
  }

  void _showStatusSheet(String id, String current) {
    const options = ['NEW', 'VISIT_SCHEDULED', 'VISIT_DONE', 'FOLLOW_UP', 'BOOKING_DONE', 'COMMISSION_ELIGIBLE', 'CLEARED', 'LOST'];
    showModalBottomSheet<void>(
      context: context,
      builder: (ctx) => SafeArea(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Padding(padding: const EdgeInsets.all(16), child: Text('Update status', style: GoogleFonts.montserrat(fontWeight: FontWeight.bold))),
            ...options.map((s) => ListTile(
              title: Text(s.replaceAll('_', ' ')),
              trailing: s == current ? const Icon(Icons.check, size: 18) : null,
              onTap: () { Navigator.pop(ctx); _patchStatus(id, s); },
            )),
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
      return q.isEmpty || _leadName(l).toLowerCase().contains(q) || _leadProject(l).toLowerCase().contains(q);
    }).toList();

    return Scaffold(
      backgroundColor: scheme.surface,
      body: CustomScrollView(
        slivers: [
          _sliverHeader(user, scheme),
          SliverToBoxAdapter(
            child: Padding(
              padding: const EdgeInsets.symmetric(horizontal: 16),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.stretch,
                children: [
                  if (_loading)
                    const Center(child: Padding(padding: EdgeInsets.all(32), child: CircularProgressIndicator()))
                  else ...[
                    _commissionVault(scheme),
                    const SizedBox(height: 24),
                    _sectionLabel('MARKET OPPORTUNITIES', onViewAll: () => context.push('/cp/projects')),
                    _opportunitiesCarousel(projectsAsync),
                    const SizedBox(height: 24),
                    _leadsHeader(scheme),
                    if (_showSearch) _searchBar(scheme),
                  ],
                ],
              ),
            ),
          ),
          if (!_loading && filtered.isEmpty)
            const SliverToBoxAdapter(child: Padding(padding: EdgeInsets.all(32), child: Center(child: Text('No prospects identified.')))),
          if (!_loading && filtered.isNotEmpty)
            SliverList(
              delegate: SliverChildBuilderDelegate(
                childCount: filtered.length,
                (context, i) => _leadCard(filtered[i], scheme),
              ),
            ),
          const SliverToBoxAdapter(child: SizedBox(height: 100)),
        ],
      ),
    );
  }

  Widget _sliverHeader(dynamic user, ColorScheme scheme) {
    return SliverPadding(
      padding: const EdgeInsets.fromLTRB(16, 24, 16, 12),
      sliver: SliverToBoxAdapter(
        child: Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            IconButton(
              onPressed: () => context.go('/cp/hub'),
              icon: const Icon(LucideIcons.arrowLeft, size: 20),
              style: IconButton.styleFrom(backgroundColor: scheme.surfaceContainer),
            ),
            Column(
              children: [
                Text('PARTNER DASHBOARD', style: GoogleFonts.montserrat(fontSize: 16, fontWeight: FontWeight.w900, letterSpacing: 0.5)),
                const SizedBox(height: 4),
                Container(
                  padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                  decoration: BoxDecoration(color: Colors.black12, borderRadius: BorderRadius.circular(4)),
                  child: Text('ID: ${(user?['cpId'] ?? 'BROKEN HOURS').toString().toUpperCase()}', style: GoogleFonts.firaCode(fontSize: 8, fontWeight: FontWeight.w700)),
                ),
                const SizedBox(height: 2),
                Text('• BROKEN HOURS', style: GoogleFonts.montserrat(fontSize: 9, fontWeight: FontWeight.w800, color: Colors.black54, letterSpacing: 1.5)),
              ],
            ),
            IconButton(
              onPressed: () => context.push('/cp/booking/site-visit'),
              icon: const Icon(LucideIcons.plus, size: 20),
              style: IconButton.styleFrom(backgroundColor: Colors.black, foregroundColor: Colors.white),
            ),
          ],
        ),
      ),
    );
  }

  Widget _commissionVault(ColorScheme scheme) {
    return Container(
      padding: const EdgeInsets.all(24),
      decoration: BoxDecoration(color: Colors.black, borderRadius: BorderRadius.circular(34)),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Text('AVAILABLE COMMISSION', style: GoogleFonts.montserrat(fontSize: 9, fontWeight: FontWeight.w900, letterSpacing: 2.5, color: Colors.white70)),
              const Icon(LucideIcons.wallet, color: Colors.white, size: 24),
            ],
          ),
          const SizedBox(height: 20),
          Row(
            crossAxisAlignment: CrossAxisAlignment.baseline,
            textBaseline: TextBaseline.alphabetic,
            children: [
              Text('AED ', style: GoogleFonts.montserrat(fontSize: 16, fontWeight: FontWeight.w900, color: Colors.white54)),
              Text(_balance().toString(), style: GoogleFonts.montserrat(fontSize: 48, fontWeight: FontWeight.w900, color: Colors.white, height: 1)),
            ],
          ),
          const SizedBox(height: 32),
          Row(
            children: [
              _statBox('TOTAL EARNED', 'AED ${_totalEarned()}'),
              const SizedBox(width: 12),
              _statBox('ACTIVE LEADS', '${_referrals.length}'),
            ],
          ),
        ],
      ),
    );
  }

  Widget _statBox(String label, String val) {
    return Expanded(
      child: Container(
        padding: const EdgeInsets.all(16),
        decoration: BoxDecoration(color: Colors.white.withOpacity(0.08), borderRadius: BorderRadius.circular(16)),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(label, style: GoogleFonts.montserrat(fontSize: 8, fontWeight: FontWeight.w900, color: Colors.white60, letterSpacing: 1)),
            const SizedBox(height: 6),
            Text(val, style: GoogleFonts.montserrat(fontSize: 12, fontWeight: FontWeight.w900, color: Colors.white)),
          ],
        ),
      ),
    );
  }

  Widget _sectionLabel(String title, {required VoidCallback onViewAll}) {
    return Row(
      mainAxisAlignment: MainAxisAlignment.spaceBetween,
      children: [
        Text(title, style: GoogleFonts.montserrat(fontWeight: FontWeight.w900, letterSpacing: 0.5)),
        TextButton(
          onPressed: onViewAll,
          child: Row(
            children: [
              Text('View all', style: GoogleFonts.montserrat(fontSize: 10, fontWeight: FontWeight.w700, color: Colors.black)),
              const SizedBox(width: 4),
              const Icon(LucideIcons.chevronRight, size: 12, color: Colors.black),
            ],
          ),
        ),
      ],
    );
  }

  Widget _opportunitiesCarousel(AsyncValue projectsAsync) {
    return SizedBox(
      height: 260,
      child: projectsAsync.when(
        loading: () => const Center(child: CircularProgressIndicator()),
        error: (_, __) => const Text('Load failed'),
        data: (list) {
          final projects = list as List;
          return ListView.separated(
            scrollDirection: Axis.horizontal,
            itemCount: projects.length.clamp(0, 20),
            separatorBuilder: (_, __) => const SizedBox(width: 14),
            itemBuilder: (ctx, i) {
              final p = projects[i];
              final img = (p['images'] is List && p['images'].isNotEmpty) ? p['images'][0].toString() : (p['heroImage']?.toString() ?? '');
              return _projectCard(p, img);
            },
          );
        },
      ),
    );
  }

  Widget _projectCard(dynamic p, String img) {
    return GestureDetector(
      onTap: () { if (p['_id'] != null) context.push('/cp/projects/${p['_id']}'); },
      child: Container(
        width: 180,
        decoration: BoxDecoration(borderRadius: BorderRadius.circular(34), boxShadow: [BoxShadow(color: Colors.black.withOpacity(0.05), blurRadius: 10, offset: const Offset(0, 4))]),
        child: ClipRRect(
          borderRadius: BorderRadius.circular(34),
          child: Stack(
            fit: StackFit.expand,
            children: [
              img.isNotEmpty ? CachedNetworkImage(imageUrl: img, fit: BoxFit.cover) : Container(color: Colors.grey.shade200),
              Container(decoration: BoxDecoration(gradient: LinearGradient(begin: Alignment.topCenter, end: Alignment.bottomCenter, colors: [Colors.transparent, Colors.black.withOpacity(0.8)]))),
              Positioned(top: 15, left: 15, child: Container(padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4), decoration: BoxDecoration(color: Colors.white, borderRadius: BorderRadius.circular(10)), child: Text('ONGOING', style: GoogleFonts.montserrat(fontSize: 8, fontWeight: FontWeight.w900)))),
              Positioned(left: 15, right: 15, bottom: 20, child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [Text(p['title'] ?? '', style: GoogleFonts.montserrat(color: Colors.white, fontWeight: FontWeight.w900, fontSize: 16)), const SizedBox(height: 4), Text('FROM 18% YOY', style: GoogleFonts.montserrat(color: Colors.white60, fontWeight: FontWeight.w800, fontSize: 8, letterSpacing: 1))])),
              Positioned(right: 15, bottom: 20, child: Container(width: 32, height: 32, decoration: BoxDecoration(color: Colors.white.withOpacity(0.2), shape: BoxShape.circle), child: const Icon(LucideIcons.arrowUpRight, color: Colors.white, size: 16))),
            ],
          ),
        ),
      ),
    );
  }

  Widget _leadsHeader(ColorScheme scheme) {
    return Row(
      mainAxisAlignment: MainAxisAlignment.spaceBetween,
      children: [
        Text('REGISTERED LEADS', style: GoogleFonts.montserrat(fontWeight: FontWeight.w900, letterSpacing: 0.5)),
        GestureDetector(
          onTap: () => setState(() => _showSearch = !_showSearch),
          child: Container(
            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
            decoration: BoxDecoration(color: scheme.surfaceContainer, borderRadius: BorderRadius.circular(99)),
            child: Row(children: [Icon(LucideIcons.search, size: 14, color: scheme.onSurface.withOpacity(0.3)), const SizedBox(width: 8), Text('FILTER', style: GoogleFonts.montserrat(fontSize: 10, fontWeight: FontWeight.w900, letterSpacing: 1))]),
          ),
        ),
      ],
    );
  }

  Widget _searchBar(ColorScheme scheme) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 16),
      child: TextField(
        onChanged: (v) => setState(() => _searchQuery = v),
        style: GoogleFonts.montserrat(fontSize: 14, fontWeight: FontWeight.w700),
        decoration: InputDecoration(
          hintText: 'SEARCH PROSPECTS...',
          hintStyle: GoogleFonts.montserrat(fontSize: 10, fontWeight: FontWeight.w900, color: Colors.black12, letterSpacing: 2),
          filled: true,
          fillColor: scheme.surfaceContainer,
          border: OutlineInputBorder(borderRadius: BorderRadius.circular(16), borderSide: BorderSide.none),
          prefixIcon: const Icon(LucideIcons.search, size: 16),
        ),
      ),
    );
  }

  Widget _leadCard(dynamic lead, ColorScheme scheme) {
    final status = _status(lead);
    final id = lead['_id']?.toString() ?? '';
    final phone = _leadPhone(lead);

    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 10),
      child: Container(
        decoration: BoxDecoration(color: Colors.white, borderRadius: BorderRadius.circular(34), boxShadow: [BoxShadow(color: Colors.black.withOpacity(0.04), blurRadius: 20, offset: const Offset(0, 10))]),
        child: Padding(
          padding: const EdgeInsets.all(26),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Column(crossAxisAlignment: CrossAxisAlignment.start, children: [Text(_leadName(lead).toLowerCase(), style: GoogleFonts.montserrat(fontSize: 20, fontWeight: FontWeight.w800, letterSpacing: -0.5)), Text(_leadProject(lead).toUpperCase(), style: GoogleFonts.montserrat(fontSize: 10, fontWeight: FontWeight.w800, color: Colors.black45, letterSpacing: 1.5))]),
                  Container(padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 6), decoration: BoxDecoration(color: const Color(0xFF14B8A6).withOpacity(0.15), borderRadius: BorderRadius.circular(99)), child: Text(status.replaceAll('_', ' ').toUpperCase(), style: GoogleFonts.montserrat(fontSize: 8, fontWeight: FontWeight.w900, color: const Color(0xFF14B8A6), letterSpacing: 1))),
                ],
              ),
              const SizedBox(height: 24),
              Row(mainAxisAlignment: MainAxisAlignment.spaceBetween, children: [_traceStep('REG', active: true), _traceStep('VISIT', active: status != 'NEW'), _traceStep('BOOKED', active: status == 'BOOKING_DONE' || status == 'CLEARED'), _traceStep('PAYOUT', active: status == 'CLEARED')]),
              const SizedBox(height: 8),
              Stack(children: [Container(height: 4, decoration: BoxDecoration(color: scheme.surfaceContainer, borderRadius: BorderRadius.circular(2))), FractionallySizedBox(widthFactor: _progress(status), child: Container(height: 4, decoration: BoxDecoration(color: const Color(0xFF14B8A6), borderRadius: BorderRadius.circular(2))))]),
              const SizedBox(height: 32),
              Row(
                children: [
                  Expanded(child: OutlinedButton(onPressed: phone.isEmpty ? null : () => launchUrl(Uri.parse('tel:$phone')), style: OutlinedButton.styleFrom(minimumSize: const Size(0, 56), side: BorderSide(color: Colors.black.withOpacity(0.05)), shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(28))), child: Text('CALL CLIENT', style: GoogleFonts.montserrat(fontSize: 10, fontWeight: FontWeight.w900, color: Colors.black, letterSpacing: 1)))),
                  const SizedBox(width: 12),
                  Expanded(child: ElevatedButton(onPressed: id.isEmpty ? null : () => _showStatusSheet(id, status), style: ElevatedButton.styleFrom(backgroundColor: Colors.black, foregroundColor: Colors.white, minimumSize: const Size(0, 56), shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(28))), child: Text('UPDATE STATUS', style: GoogleFonts.montserrat(fontSize: 10, fontWeight: FontWeight.w900, letterSpacing: 1)))),
                ],
              ),
              const SizedBox(height: 16),
              Container(padding: const EdgeInsets.all(20), decoration: BoxDecoration(color: scheme.surfaceContainer.withValues(alpha: 0.3), borderRadius: BorderRadius.circular(24), border: Border.all(color: scheme.surfaceContainer)), child: Row(children: [const Icon(LucideIcons.wallet, size: 16, color: Colors.black54), const SizedBox(width: 12), Expanded(child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [Text('PAYMENT JOURNEY', style: GoogleFonts.montserrat(fontSize: 9, fontWeight: FontWeight.w900, letterSpacing: 1)), const SizedBox(height: 4), Text('WAITING FOR FIRST PAYMENT\nSCHEDULE...', style: GoogleFonts.montserrat(fontSize: 8, fontWeight: FontWeight.w700, color: Colors.black45, height: 1.5))]))])),
            ],
          ),
        ),
      ),
    );
  }

  Widget _traceStep(String label, {required bool active}) {
    return Text(label, style: GoogleFonts.montserrat(fontSize: 8, fontWeight: FontWeight.w900, color: active ? Colors.black : Colors.black12, letterSpacing: 1));
  }
}
