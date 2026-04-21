import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:cached_network_image/cached_network_image.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:lucide_icons/lucide_icons.dart';
import 'package:m4_mobile/presentation/providers/auth_provider.dart';
import 'package:m4_mobile/presentation/providers/cp_shell_provider.dart';
import 'package:m4_mobile/presentation/widgets/cp_sidebar_menu.dart';

/// Web `/cp/hub`: cinematic header + welcome card + tool matrix + priority access.
class CpHubScreen extends ConsumerStatefulWidget {
  const CpHubScreen({super.key});

  @override
  ConsumerState<CpHubScreen> createState() => _CpHubScreenState();
}

class _CpHubScreenState extends ConsumerState<CpHubScreen> {
  Map<String, dynamic>? _perf;
  Map<String, dynamic>? _priorityProject;
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
      ]);
      final res = results[0];
      final projRes = results[1];
      if (!mounted) return;
      if (res.statusCode == 200 && res.data['status'] == true) {
        final d = res.data['data'];
        if (d is Map) _perf = Map<String, dynamic>.from(d);
      }

      // Priority Access: take from real catalog (database), prefer Upcoming, else featured, else first.
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
      } catch (_) {}
    } catch (_) {}
    if (mounted) setState(() => _loading = false);
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
            child: ListView(
              padding: const EdgeInsets.fromLTRB(20, 18, 20, 26),
              children: [
                _header(context, scheme, accent),
                const SizedBox(height: 16),
                if (_loading)
                  const Padding(
                    padding: EdgeInsets.symmetric(vertical: 30),
                    child: Center(child: CircularProgressIndicator()),
                  )
                else
                  _welcomeCard(name: name, scheme: scheme, accent: accent),
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
              ],
            ),
          ),
        ],
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
