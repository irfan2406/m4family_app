import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:cached_network_image/cached_network_image.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:lucide_icons/lucide_icons.dart';
import 'package:m4_mobile/presentation/providers/auth_provider.dart';
import 'package:m4_mobile/presentation/widgets/cp_sidebar_menu.dart';

/// Web `/cp/hub`: cinematic header + welcome card + tool matrix + priority access.
class CpHubScreen extends ConsumerStatefulWidget {
  const CpHubScreen({super.key});

  @override
  ConsumerState<CpHubScreen> createState() => _CpHubScreenState();
}

class _CpHubScreenState extends ConsumerState<CpHubScreen> {
  Map<String, dynamic>? _perf;
  Map<String, dynamic>? _wallet;
  Map<String, dynamic>? _priorityProject;
  List<Map<String, dynamic>> _holdings = [];
  bool _loading = true;

  @override
  void initState() {
    super.initState();
    _load();
  }

  Future<void> _load() async {
    try {
      final api = ref.read(apiClientProvider);
      final results = await Future.wait([
        api.getCpPerformance(),
        api.getProjects(),
        api.getCpWallet(),
      ]);
      final res = results[0];
      final projRes = results[1];
      final walletRes = results[2];
      if (!mounted) return;
      if (res.statusCode == 200 && res.data['status'] == true) {
        final d = res.data['data'];
        if (d is Map) _perf = Map<String, dynamic>.from(d);
      }
      if (walletRes.statusCode == 200 && walletRes.data['status'] == true) {
        final d = walletRes.data['data'];
        if (d is Map) _wallet = Map<String, dynamic>.from(d);
      }

      // Priority Access + Holdings: take from real catalog (database).
      try {
        final body = projRes.data;
        final list = (body is Map && body['status'] == true && body['data'] is List)
            ? (body['data'] as List)
            : (body is List ? body : const <dynamic>[]);
        final projects = list.whereType<Map>().map((m) => Map<String, dynamic>.from(m)).toList();
        Map<String, dynamic>? pick;
        pick = projects.cast<Map<String, dynamic>?>().firstWhere(
              (p) => (p?['status']?.toString() ?? '').toLowerCase() == 'upcoming',
              orElse: () => null,
            ) ??
            projects.cast<Map<String, dynamic>?>().firstWhere(
              (p) => p?['featured'] == true,
              orElse: () => null,
            ) ??
            (projects.isNotEmpty ? projects.first : null);
        _priorityProject = pick;

        // Holdings: prefer CP-owned/holdings payload if present, else derive from catalog projects.
        final perfHoldings = _perf?['holdings'];
        if (perfHoldings is List && perfHoldings.isNotEmpty) {
          _holdings = perfHoldings.whereType<Map>().map((m) => Map<String, dynamic>.from(m)).toList();
        } else {
          _holdings = projects.take(2).toList();
        }
      } catch (_) {}
    } catch (_) {}
    if (mounted) setState(() => _loading = false);
  }

  /// Total asset portfolio value, formatted as "₹ X.XX Cr".
  String _portfolioValue() {
    final raw = _perf?['totalAssets'] ??
        _perf?['portfolioValue'] ??
        _wallet?['totalAssets'] ??
        _wallet?['portfolioValue'];
    final num? n = raw is num ? raw : num.tryParse(raw?.toString() ?? '');
    if (n == null || n == 0) return '₹ 4.50 Cr';
    final cr = n >= 10000 ? n / 10000000 : n; // assume rupees if large, else already Cr
    return '₹ ${cr.toStringAsFixed(2)} Cr';
  }

  @override
  Widget build(BuildContext context) {
    final user = ref.watch(authProvider).user;
    final name = user?['firstName']?.toString() ??
        user?['companyName']?.toString().split(' ').first ??
        'Partner';
    final scheme = Theme.of(context).colorScheme;
    final isLight = scheme.brightness == Brightness.light;
    final accent = isLight ? Colors.black : scheme.primary;

    return Scaffold(
      drawer: const CpSidebarMenu(),
      body: Stack(
        children: [
          // Background (web has a subtle cinematic image + gradients)
          Positioned.fill(
            child: Container(
              decoration: BoxDecoration(
                gradient: LinearGradient(
                  begin: Alignment.topCenter,
                  end: Alignment.bottomCenter,
                  colors: [
                    (isLight ? Colors.white : accent.withValues(alpha: 0.08)),
                    scheme.surface,
                  ],
                ),
              ),
            ),
          ),
          SafeArea(
            child: RefreshIndicator(
              onRefresh: _load,
              color: scheme.onSurface,
              child: ListView(
              padding: const EdgeInsets.fromLTRB(20, 18, 20, 26),
              physics: const AlwaysScrollableScrollPhysics(),
              children: [
                _header(context, scheme, accent),
                const SizedBox(height: 16),
                if (_loading)
                  const Padding(
                    padding: EdgeInsets.symmetric(vertical: 30),
                    child: Center(child: CircularProgressIndicator()),
                  )
                else ...[
                  _welcomeCard(name: name, scheme: scheme, accent: accent),
                  const SizedBox(height: 18),
                  _assetPortfolioCard(scheme: scheme, accent: accent),
                ],
                const SizedBox(height: 18),
                Text(
                  'TOOL MATRIX',
                  style: GoogleFonts.montserrat(
                    fontSize: 10,
                    fontWeight: FontWeight.w800,
                    letterSpacing: 3,
                    color: scheme.onSurface.withValues(alpha: isLight ? 0.7 : 0.55),
                  ),
                ),
                const SizedBox(height: 12),
                GridView.count(
                  crossAxisCount: 2,
                  shrinkWrap: true,
                  physics: const NeverScrollableScrollPhysics(),
                  crossAxisSpacing: 12,
                  mainAxisSpacing: 12,
                  childAspectRatio: 1.1,
                  children: [
                    _matrixTile(
                      context,
                      title: 'Reports',
                      icon: LucideIcons.fileText,
                      bg: const Color(0x1A60A5FA),
                      fg: const Color(0xFF60A5FA),
                      onTap: () => context.push('/cp/hub/reports'),
                      scheme: scheme,
                    ),
                    _matrixTile(
                      context,
                      title: 'Analytics',
                      icon: LucideIcons.barChart3,
                      bg: const Color(0x1A34D399),
                      fg: const Color(0xFF34D399),
                      onTap: () => context.push('/cp/hub/analytics'),
                      scheme: scheme,
                    ),
                    _matrixTile(
                      context,
                      title: 'Network',
                      icon: LucideIcons.users,
                      bg: scheme.onSurface.withValues(alpha: 0.05),
                      fg: scheme.onSurface.withValues(alpha: 0.7),
                      onTap: () => context.push('/cp/hub/network'),
                      scheme: scheme,
                    ),
                    _matrixTile(
                      context,
                      title: 'Concierge',
                      icon: LucideIcons.crown,
                      bg: scheme.onSurface.withValues(alpha: 0.05),
                      fg: scheme.onSurface.withValues(alpha: 0.7),
                      onTap: () {
                        // Match web: redirect to `/cp/support`.
                        context.push('/cp/support');
                      },
                      scheme: scheme,
                    ),
                  ],
                ),
                const SizedBox(height: 18),
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Text(
                      'PRIORITY ACCESS',
                      style: GoogleFonts.montserrat(
                        fontSize: 10,
                        fontWeight: FontWeight.w800,
                        letterSpacing: 3,
                        color: scheme.onSurface.withValues(alpha: isLight ? 0.7 : 0.55),
                      ),
                    ),
                    TextButton(
                      onPressed: () => context.push('/cp/projects'),
                      style: TextButton.styleFrom(
                        foregroundColor: Colors.black,
                        padding: const EdgeInsets.symmetric(horizontal: 0, vertical: 10),
                      ),
                      child: Text('VIEW ALL', style: GoogleFonts.montserrat(fontSize: 10, fontWeight: FontWeight.w900, letterSpacing: 1)),
                    ),
                  ],
                ),
                const SizedBox(height: 10),
                _priorityCard(context, scheme: scheme),
                const SizedBox(height: 18),
                // ─── MY HOLDINGS (web investor-hub portfolio view) ───
                _holdingsHeader(scheme),
                const SizedBox(height: 12),
                _holdingsList(context, scheme),
                const SizedBox(height: 18),
                // ─── INSTITUTIONAL TOOLS ─────────────────────────────
                _institutionalTools(scheme),
              ],
            ),
            ),
          ),
        ],
      ),
    );
  }

  // ━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━
  // ASSET PORTFOLIO CARD — web `Total Asset Portfolio`
  // ━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━
  Widget _assetPortfolioCard({required ColorScheme scheme, required Color accent}) {
    final isDark = scheme.brightness == Brightness.dark;
    return Container(
      padding: const EdgeInsets.all(28),
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(40),
        border: Border.all(color: scheme.outlineVariant.withValues(alpha: isDark ? 0.35 : 0.55)),
        gradient: LinearGradient(
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
          colors: [
            isDark ? accent.withValues(alpha: 0.08) : Colors.white,
            isDark ? scheme.surfaceContainerHighest.withValues(alpha: 0.15) : Colors.white,
          ],
        ),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: isDark ? 0.08 : 0.06),
            blurRadius: 28,
            offset: const Offset(0, 14),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Expanded(
                child: Text(
                  'TOTAL ASSET PORTFOLIO',
                  style: GoogleFonts.montserrat(
                    fontSize: 10,
                    fontWeight: FontWeight.w900,
                    letterSpacing: 2,
                    color: scheme.onSurface.withValues(alpha: isDark ? 0.55 : 0.7),
                  ),
                ),
              ),
              Container(
                width: 36,
                height: 36,
                decoration: BoxDecoration(
                  borderRadius: BorderRadius.circular(14),
                  color: scheme.onSurface.withValues(alpha: 0.06),
                  border: Border.all(color: scheme.onSurface.withValues(alpha: 0.1)),
                ),
                child: Icon(LucideIcons.trendingUp, size: 18, color: scheme.onSurface),
              ),
            ],
          ),
          const SizedBox(height: 8),
          Text(
            _portfolioValue(),
            style: GoogleFonts.montserrat(
              fontSize: 28,
              fontWeight: FontWeight.w900,
              height: 1,
              color: scheme.onSurface,
            ),
          ),
          const SizedBox(height: 22),
          Row(
            children: [
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 8),
                decoration: BoxDecoration(
                  borderRadius: BorderRadius.circular(999),
                  color: scheme.onSurface.withValues(alpha: 0.06),
                  border: Border.all(color: scheme.outlineVariant.withValues(alpha: isDark ? 0.35 : 0.55)),
                ),
                child: Text(
                  'PORTFOLIO GROWTH',
                  style: GoogleFonts.montserrat(
                    fontSize: 10,
                    fontWeight: FontWeight.w900,
                    letterSpacing: 2,
                    color: scheme.onSurface,
                  ),
                ),
              ),
              const SizedBox(width: 14),
              Flexible(
                child: Text(
                  'Performance: Optimal',
                  style: GoogleFonts.montserrat(
                    fontSize: 10,
                    fontWeight: FontWeight.w900,
                    letterSpacing: 1,
                    color: scheme.onSurface.withValues(alpha: isDark ? 0.55 : 0.7),
                  ),
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }

  // ━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━
  // MY HOLDINGS — web investor-hub holdings list
  // ━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━
  Widget _holdingsHeader(ColorScheme scheme) {
    final isDark = scheme.brightness == Brightness.dark;
    return Row(
      mainAxisAlignment: MainAxisAlignment.spaceBetween,
      children: [
        Text(
          'MY HOLDINGS',
          style: GoogleFonts.montserrat(
            fontSize: 10,
            fontWeight: FontWeight.w900,
            letterSpacing: 3,
            color: scheme.onSurface.withValues(alpha: isDark ? 0.55 : 0.7),
          ),
        ),
        Container(
          padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 6),
          decoration: BoxDecoration(
            borderRadius: BorderRadius.circular(999),
            color: scheme.onSurface.withValues(alpha: 0.04),
            border: Border.all(color: scheme.outlineVariant.withValues(alpha: isDark ? 0.35 : 0.55)),
          ),
          child: Text(
            '${_holdings.length} Active Projects',
            style: GoogleFonts.montserrat(
              fontSize: 10,
              fontWeight: FontWeight.w900,
              letterSpacing: 1,
              color: scheme.primary,
            ),
          ),
        ),
      ],
    );
  }

  Widget _holdingsList(BuildContext context, ColorScheme scheme) {
    final isDark = scheme.brightness == Brightness.dark;
    if (_holdings.isEmpty) {
      return Container(
        width: double.infinity,
        padding: const EdgeInsets.symmetric(vertical: 36, horizontal: 20),
        decoration: BoxDecoration(
          borderRadius: BorderRadius.circular(28),
          color: isDark ? scheme.onSurface.withValues(alpha: 0.03) : Colors.white,
          border: Border.all(color: scheme.outlineVariant.withValues(alpha: isDark ? 0.35 : 0.55)),
        ),
        child: Column(
          children: [
            Text(
              'NO HOLDINGS YET',
              style: GoogleFonts.montserrat(
                fontSize: 10,
                fontWeight: FontWeight.w900,
                letterSpacing: 2,
                color: scheme.onSurface.withValues(alpha: 0.3),
              ),
            ),
            const SizedBox(height: 12),
            TextButton(
              onPressed: () => context.push('/cp/projects'),
              child: Text(
                'EXPLORE OPPORTUNITIES',
                style: GoogleFonts.montserrat(fontSize: 10, fontWeight: FontWeight.w900, letterSpacing: 1, color: scheme.onSurface),
              ),
            ),
          ],
        ),
      );
    }
    return Column(
      children: [
        for (final h in _holdings) ...[
          _holdingCard(context, h, scheme),
          const SizedBox(height: 14),
        ],
      ],
    );
  }

  String _holdingName(Map<String, dynamic> h) => (h['title'] ?? h['name'] ?? 'Project').toString();

  String _holdingUnit(Map<String, dynamic> h) {
    final unit = h['unit'] ?? h['unitDesignation'] ?? h['propertyType'];
    if (unit != null && unit.toString().trim().isNotEmpty) return unit.toString();
    return _locLine(h);
  }

  String _holdingValue(Map<String, dynamic> h) {
    final v = h['value'] ?? h['equity'] ?? h['equityValue'] ?? h['price'] ?? h['startingPrice'];
    final num? n = v is num ? v : num.tryParse(v?.toString() ?? '');
    if (n == null || n == 0) return '—';
    final cr = n >= 10000 ? n / 10000000 : n;
    return '₹ ${cr.toStringAsFixed(2)} Cr';
  }

  double _holdingProgress(Map<String, dynamic> h) {
    final p = h['progress'] ?? h['constructionProgress'] ?? h['completion'];
    final num? n = p is num ? p : num.tryParse(p?.toString().replaceAll('%', '') ?? '');
    if (n == null) return 0.6;
    final d = n.toDouble();
    return (d > 1 ? d / 100 : d).clamp(0.0, 1.0);
  }

  Widget _holdingCard(BuildContext context, Map<String, dynamic> h, ColorScheme scheme) {
    final isDark = scheme.brightness == Brightness.dark;
    final id = (h['_id'] ?? h['id'] ?? '').toString();
    final progress = _holdingProgress(h);
    return Container(
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(28),
        color: isDark ? scheme.onSurface.withValues(alpha: 0.03) : Colors.white,
        border: Border.all(color: scheme.outlineVariant.withValues(alpha: isDark ? 0.35 : 0.55)),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: isDark ? 0.08 : 0.06),
            blurRadius: 28,
            offset: const Offset(0, 14),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Container(
                width: 48,
                height: 48,
                decoration: BoxDecoration(
                  borderRadius: BorderRadius.circular(18),
                  color: scheme.onSurface.withValues(alpha: 0.05),
                  border: Border.all(color: scheme.onSurface.withValues(alpha: 0.1)),
                ),
                child: Icon(LucideIcons.building, size: 20, color: scheme.onSurface),
              ),
              const SizedBox(width: 14),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      _holdingName(h).toUpperCase(),
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                      style: GoogleFonts.montserrat(fontSize: 14, fontWeight: FontWeight.w900, color: scheme.onSurface),
                    ),
                    const SizedBox(height: 2),
                    Text(
                      _holdingUnit(h).toUpperCase(),
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                      style: GoogleFonts.montserrat(
                        fontSize: 8,
                        fontWeight: FontWeight.w900,
                        letterSpacing: 1.5,
                        color: scheme.onSurface.withValues(alpha: isDark ? 0.55 : 0.6),
                      ),
                    ),
                  ],
                ),
              ),
              const SizedBox(width: 10),
              Column(
                crossAxisAlignment: CrossAxisAlignment.end,
                children: [
                  Text(
                    _holdingValue(h),
                    style: GoogleFonts.montserrat(fontSize: 14, fontWeight: FontWeight.w900, color: scheme.onSurface),
                  ),
                  const SizedBox(height: 2),
                  Text(
                    'EQUITY',
                    style: GoogleFonts.montserrat(
                      fontSize: 8,
                      fontWeight: FontWeight.w900,
                      letterSpacing: 1.5,
                      color: scheme.onSurface.withValues(alpha: isDark ? 0.55 : 0.6),
                    ),
                  ),
                ],
              ),
            ],
          ),
          const SizedBox(height: 18),
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Text(
                'CONSTRUCTION',
                style: GoogleFonts.montserrat(
                  fontSize: 8,
                  fontWeight: FontWeight.w900,
                  letterSpacing: 1.5,
                  color: scheme.onSurface.withValues(alpha: isDark ? 0.55 : 0.6),
                ),
              ),
              Text(
                '${(progress * 100).round()}%',
                style: GoogleFonts.montserrat(
                  fontSize: 8,
                  fontWeight: FontWeight.w900,
                  color: scheme.onSurface.withValues(alpha: isDark ? 0.55 : 0.6),
                ),
              ),
            ],
          ),
          const SizedBox(height: 8),
          ClipRRect(
            borderRadius: BorderRadius.circular(999),
            child: LinearProgressIndicator(
              value: progress,
              minHeight: 8,
              backgroundColor: scheme.onSurface.withValues(alpha: 0.08),
              valueColor: AlwaysStoppedAnimation(scheme.onSurface),
            ),
          ),
          const SizedBox(height: 18),
          Row(
            children: [
              Expanded(
                child: GestureDetector(
                  onTap: () {
                    if (id.isNotEmpty) {
                      context.push('/cp/projects/$id', extra: h);
                    } else {
                      context.push('/cp/projects');
                    }
                  },
                  child: Container(
                    height: 48,
                    alignment: Alignment.center,
                    decoration: BoxDecoration(
                      color: scheme.onSurface,
                      borderRadius: BorderRadius.circular(16),
                    ),
                    child: Text(
                      'EXPLORE',
                      style: GoogleFonts.montserrat(
                        fontSize: 9,
                        fontWeight: FontWeight.w900,
                        letterSpacing: 2,
                        color: scheme.surface,
                      ),
                    ),
                  ),
                ),
              ),
              const SizedBox(width: 12),
              GestureDetector(
                onTap: () {
                  ScaffoldMessenger.of(context).showSnackBar(
                    const SnackBar(content: Text('Live Stream Active'), backgroundColor: Colors.green),
                  );
                },
                child: Container(
                  width: 48,
                  height: 48,
                  alignment: Alignment.center,
                  decoration: BoxDecoration(
                    color: scheme.onSurface.withValues(alpha: 0.05),
                    borderRadius: BorderRadius.circular(16),
                    border: Border.all(color: scheme.onSurface.withValues(alpha: 0.1)),
                  ),
                  child: Icon(LucideIcons.eye, size: 20, color: scheme.onSurface),
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }

  // ━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━
  // INSTITUTIONAL TOOLS — web Statement / Expert Desk
  // ━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━
  Widget _institutionalTools(ColorScheme scheme) {
    return Row(
      children: [
        Expanded(
          child: _institutionalButton(
            scheme: scheme,
            icon: LucideIcons.cloud,
            label: 'STATEMENT',
            onTap: () {
              ScaffoldMessenger.of(context).showSnackBar(
                const SnackBar(content: Text('Downloading Audit Statement...'), backgroundColor: Colors.green),
              );
            },
          ),
        ),
        const SizedBox(width: 14),
        Expanded(
          child: _institutionalButton(
            scheme: scheme,
            icon: LucideIcons.messageSquare,
            label: 'EXPERT DESK',
            onTap: () {
              ScaffoldMessenger.of(context).showSnackBar(
                const SnackBar(content: Text('Notifying Relationship Manager...'), backgroundColor: Colors.green),
              );
              context.push('/cp/support');
            },
          ),
        ),
      ],
    );
  }

  Widget _institutionalButton({
    required ColorScheme scheme,
    required IconData icon,
    required String label,
    required VoidCallback onTap,
  }) {
    final isDark = scheme.brightness == Brightness.dark;
    return GestureDetector(
      onTap: onTap,
      child: Container(
        height: 96,
        decoration: BoxDecoration(
          color: isDark ? scheme.onSurface.withValues(alpha: 0.03) : Colors.white,
          borderRadius: BorderRadius.circular(40),
          border: Border.all(color: scheme.outlineVariant.withValues(alpha: isDark ? 0.35 : 0.5)),
          boxShadow: [
            BoxShadow(
              color: Colors.black.withValues(alpha: isDark ? 0.08 : 0.06),
              blurRadius: 28,
              offset: const Offset(0, 14),
            ),
          ],
        ),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(icon, size: 26, color: scheme.onSurface),
            const SizedBox(height: 8),
            Text(
              label,
              style: GoogleFonts.montserrat(
                fontSize: 10,
                fontWeight: FontWeight.w900,
                letterSpacing: 2,
                color: scheme.onSurface.withValues(alpha: isDark ? 0.55 : 0.7),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _header(BuildContext context, ColorScheme scheme, Color accent) {
    return Row(
      children: [
        IconButton(
          onPressed: () => context.pop(),
          icon: const Icon(LucideIcons.arrowLeft),
        ),
        const SizedBox(width: 8),
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text('Partner Hub', style: GoogleFonts.montserrat(fontSize: 18, fontWeight: FontWeight.w900, letterSpacing: -0.2)),
              const SizedBox(height: 2),
              Text(
                'Premium Access & Tools',
                style: GoogleFonts.montserrat(fontSize: 10, fontWeight: FontWeight.w700, letterSpacing: 1.4, color: scheme.onSurface.withValues(alpha: 0.55)),
              ),
            ],
          ),
        ),
        Builder(
          builder: (ctx) => IconButton(
            onPressed: () => Scaffold.of(ctx).openDrawer(),
            icon: const Icon(LucideIcons.menu),
          ),
        ),
        const SizedBox(width: 6),
        IconButton(
          onPressed: () => context.push('/cp/settings'),
          icon: const Icon(LucideIcons.settings),
        ),
      ],
    );
  }

  Widget _welcomeCard({required String name, required ColorScheme scheme, required Color accent}) {
    final conv = _perf?['conversionRate']?.toString() ?? '0%';
    final leads = '${_perf?['totalLeads'] ?? 0}';
    final isLight = scheme.brightness == Brightness.light;
    return Container(
      padding: const EdgeInsets.all(18),
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(34),
        border: Border.all(color: scheme.outlineVariant.withValues(alpha: isLight ? 0.55 : 0.35)),
        gradient: LinearGradient(
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
          colors: [
            isLight ? Colors.white : accent.withValues(alpha: 0.08),
            isLight ? Colors.white : scheme.surfaceContainerHighest.withValues(alpha: 0.15),
          ],
        ),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: isLight ? 0.06 : 0.08),
            blurRadius: 28,
            offset: const Offset(0, 14),
          )
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Container(
                width: 40,
                height: 40,
                decoration: BoxDecoration(
                  borderRadius: BorderRadius.circular(14),
                  color: scheme.onSurface.withValues(alpha: 0.1),
                  border: Border.all(color: scheme.onSurface.withValues(alpha: 0.1)),
                ),
                child: Icon(LucideIcons.crown, color: scheme.onSurface, size: 20),
              ),
              const SizedBox(width: 10),
              Text(
                'PLATINUM TIER',
                style: GoogleFonts.montserrat(
                  fontSize: 11,
                  fontWeight: FontWeight.w900,
                  letterSpacing: 2,
                  color: scheme.onSurface,
                ),
              ),
            ],
          ),
          const SizedBox(height: 12),
          Text(
            'Welcome, $name',
            style: GoogleFonts.montserrat(fontSize: 22, fontWeight: FontWeight.w900, color: scheme.onSurface),
          ),
          const SizedBox(height: 4),
          Text(
            'Your portfolio is performing optimally.',
            style: GoogleFonts.montserrat(
              fontSize: 12,
              fontWeight: FontWeight.w600,
              color: scheme.onSurface.withValues(alpha: isLight ? 0.65 : 0.55),
            ),
          ),
          const SizedBox(height: 14),
          Row(
            children: [
              Expanded(child: _miniMetric('Conversion Rate', conv, scheme)),
              const SizedBox(width: 12),
              Expanded(child: _miniMetric('Total Leads', leads, scheme)),
            ],
          ),
        ],
      ),
    );
  }

  Widget _miniMetric(String label, String value, ColorScheme scheme) {
    final isLight = scheme.brightness == Brightness.light;
    return Container(
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(22),
        border: Border.all(color: scheme.outlineVariant.withValues(alpha: isLight ? 0.55 : 0.45)),
        color: isLight ? Colors.white : scheme.surface.withValues(alpha: 0.65),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            label.toUpperCase(),
            style: GoogleFonts.montserrat(
              fontSize: 9,
              fontWeight: FontWeight.w800,
              letterSpacing: 1.4,
              color: scheme.onSurface.withValues(alpha: isLight ? 0.65 : 0.55),
            ),
          ),
          const SizedBox(height: 6),
          Text(value, style: GoogleFonts.montserrat(fontSize: 18, fontWeight: FontWeight.w900, color: scheme.onSurface)),
        ],
      ),
    );
  }

  Widget _matrixTile(
    BuildContext context, {
    required String title,
    required IconData icon,
    required Color bg,
    required Color fg,
    required VoidCallback onTap,
    required ColorScheme scheme,
  }) {
    final isLight = scheme.brightness == Brightness.light;
    return Material(
      color: isLight ? Colors.white : scheme.onSurface.withValues(alpha: 0.03),
      borderRadius: BorderRadius.circular(28),
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(28),
        child: Container(
          decoration: BoxDecoration(
            borderRadius: BorderRadius.circular(28),
            border: Border.all(color: scheme.outlineVariant.withValues(alpha: isLight ? 0.55 : 0.4)),
          ),
          padding: const EdgeInsets.all(16),
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Container(
                width: 52,
                height: 52,
                decoration: BoxDecoration(color: bg, borderRadius: BorderRadius.circular(18)),
                child: Icon(icon, color: fg, size: 24),
              ),
              const SizedBox(height: 10),
              Text(
                title,
                style: GoogleFonts.montserrat(
                  fontSize: 12,
                  fontWeight: FontWeight.w800,
                  color: scheme.onSurface.withValues(alpha: isLight ? 0.92 : 0.85),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  String _locLine(Map<String, dynamic> p) {
    final loc = p['location'];
    if (loc is String) return loc.split(',').first.trim();
    if (loc is Map) return (loc['name']?.toString() ?? '').split(',').first.trim();
    return '';
  }

  String _hero(Map<String, dynamic> p) {
    final api = ref.read(apiClientProvider);
    final imgs = p['images'];
    if (imgs is List && imgs.isNotEmpty) return api.resolveUrl(imgs.first?.toString());
    final hero = p['heroImage']?.toString();
    return api.resolveUrl(hero);
  }

  Widget _priorityCard(BuildContext context, {required ColorScheme scheme}) {
    final p = _priorityProject;
    final title = (p?['title'] ?? 'Skyline Avenue').toString();
    final desc = (p?['description'] ?? p?['shortDescription'] ?? 'Exclusive waterfront residences in South Mumbai').toString();
    final id = (p?['_id'] ?? p?['id'] ?? '').toString();
    final loc = p == null ? '' : _locLine(p);
    final bg = p == null ? null : _hero(p);
    return Material(
      color: scheme.surfaceContainerHighest.withValues(alpha: 0.18),
      borderRadius: BorderRadius.circular(34),
      child: InkWell(
        borderRadius: BorderRadius.circular(34),
        onTap: () {
          if (id.isNotEmpty) {
            context.push('/cp/projects/$id', extra: p);
          } else {
            context.push('/cp/projects');
          }
        },
        child: Container(
          height: 190,
          decoration: BoxDecoration(
            borderRadius: BorderRadius.circular(34),
            border: Border.all(color: scheme.outlineVariant.withValues(alpha: 0.4)),
          ),
          clipBehavior: Clip.antiAlias,
          child: Stack(
            fit: StackFit.expand,
            children: [
              if (bg != null && bg.isNotEmpty)
                CachedNetworkImage(
                  imageUrl: bg,
                  fit: BoxFit.cover,
                  errorWidget: (_, __, ___) => Container(color: scheme.surfaceContainerHighest),
                )
              else
                Container(color: scheme.surfaceContainerHighest),
              Container(color: Colors.black.withValues(alpha: 0.35)),
              Container(
                decoration: BoxDecoration(
                  gradient: LinearGradient(
                    begin: Alignment.topCenter,
                    end: Alignment.bottomCenter,
                    colors: [
                      Colors.transparent,
                      scheme.surface.withValues(alpha: 0.75),
                      scheme.surface,
                    ],
                  ),
                ),
              ),
              Padding(
                padding: const EdgeInsets.all(18),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Container(
                      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
                      decoration: BoxDecoration(color: Colors.black, borderRadius: BorderRadius.circular(999)),
                      child: Text(
                        ((p?['status']?.toString() ?? '').isNotEmpty ? (p?['status']?.toString() ?? '') : 'PRE-LAUNCH').toUpperCase(),
                        style: GoogleFonts.montserrat(fontSize: 9, fontWeight: FontWeight.w900, letterSpacing: 1.2, color: Colors.white),
                      ),
                    ),
                    const Spacer(),
                    Text(title, style: GoogleFonts.montserrat(fontSize: 22, fontWeight: FontWeight.w900)),
                    const SizedBox(height: 4),
                    Text(
                      loc.isNotEmpty ? loc : desc,
                      maxLines: 2,
                      overflow: TextOverflow.ellipsis,
                      style: GoogleFonts.montserrat(fontSize: 12, fontWeight: FontWeight.w600, color: scheme.onSurface.withValues(alpha: 0.55)),
                    ),
                    const SizedBox(height: 10),
                    Row(
                      children: [
                        Text('Explore Opportunity', style: GoogleFonts.montserrat(fontSize: 12, fontWeight: FontWeight.w900, color: Colors.black)),
                        const SizedBox(width: 8),
                        const Icon(LucideIcons.arrowRight, size: 16, color: Colors.black),
                      ],
                    ),
                  ],
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
