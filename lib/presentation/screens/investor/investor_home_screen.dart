import 'package:cached_network_image/cached_network_image.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:lucide_icons/lucide_icons.dart';
import 'package:m4_mobile/core/theme/app_theme.dart';
import 'package:m4_mobile/presentation/providers/auth_provider.dart';
import 'package:m4_mobile/presentation/providers/project_provider.dart';

/// Investor home — mirrors web `/investor/home` (SharedHomePage role="investor") with a
/// portfolio-overview hero (`GET /api/investor/hub/dashboard`) above the catalog.
class InvestorHomeScreen extends ConsumerStatefulWidget {
  const InvestorHomeScreen({super.key});

  @override
  ConsumerState<InvestorHomeScreen> createState() => _InvestorHomeScreenState();
}

class _InvestorHomeScreenState extends ConsumerState<InvestorHomeScreen> {
  static const _gold = Color(0xFFFFD700);

  bool _loading = true;
  Map<String, dynamic>? _portfolio;
  Map<String, dynamic>? _priorityProject;
  String _activeTab = 'Properties';

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) => _fetchDashboard());
  }

  Future<void> _fetchDashboard() async {
    try {
      final res = await ref.read(apiClientProvider).getInvestorHubDashboard();
      final body = res.data;
      if (body is Map && body['status'] == true && body['data'] is Map) {
        final data = body['data'] as Map;
        setState(() {
          _portfolio = data['portfolio'] is Map ? Map<String, dynamic>.from(data['portfolio'] as Map) : null;
          _priorityProject = data['priorityProject'] is Map ? Map<String, dynamic>.from(data['priorityProject'] as Map) : null;
        });
      }
    } catch (_) {
      // Non-fatal: hero falls back to defaults.
    }
    if (mounted) setState(() => _loading = false);
  }

  String _heroUrl(dynamic p) {
    final imgs = p['images'];
    if (imgs is List && imgs.isNotEmpty) return imgs.first.toString();
    if (p['heroImage'] != null) return p['heroImage'].toString();
    return 'https://images.unsplash.com/photo-1600596542815-ffad4c1539a9';
  }

  String _locLine(dynamic p) {
    final loc = p['location'];
    if (loc is String) return loc.split(',').first.trim();
    if (loc is Map) return (loc['name']?.toString() ?? '').split(',').first.trim();
    return '';
  }

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final bg = isDark ? Colors.black : Colors.white;
    final textPrimary = isDark ? Colors.white : Colors.black;
    final muted = textPrimary.withValues(alpha: 0.5);

    final projectsAsync = ref.watch(projectsProvider);
    final user = ref.read(authProvider).user;
    final greetingName = (user?['firstName'] ?? user?['fullName'] ?? 'Investor').toString();

    return Scaffold(
      backgroundColor: bg,
      body: SafeArea(
        bottom: false,
        child: CustomScrollView(
          physics: const BouncingScrollPhysics(),
          slivers: [
            // Header
            SliverToBoxAdapter(
              child: Padding(
                padding: const EdgeInsets.fromLTRB(24, 16, 20, 8),
                child: Row(
                  children: [
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            'INVESTOR PORTAL',
                            style: GoogleFonts.montserrat(
                              fontSize: 10,
                              fontWeight: FontWeight.w900,
                              letterSpacing: 3,
                              color: muted,
                            ),
                          ),
                          const SizedBox(height: 4),
                          Text(
                            'Welcome, $greetingName',
                            style: GoogleFonts.montserrat(
                              fontSize: 22,
                              fontWeight: FontWeight.w800,
                              color: textPrimary,
                              letterSpacing: -0.5,
                            ),
                          ),
                        ],
                      ),
                    ),
                    Builder(
                      builder: (ctx) => Material(
                        color: textPrimary,
                        borderRadius: BorderRadius.circular(14),
                        child: InkWell(
                          onTap: () => Scaffold.of(ctx).openDrawer(),
                          borderRadius: BorderRadius.circular(14),
                          child: SizedBox(
                            width: 48,
                            height: 40,
                            child: Icon(LucideIcons.moreHorizontal, color: bg, size: 22),
                          ),
                        ),
                      ),
                    ),
                  ],
                ),
              ),
            ),

            // Portfolio overview hero
            SliverToBoxAdapter(child: _portfolioHero(isDark, textPrimary)),

            // Priority project (pre-launch / featured)
            if (_priorityProject != null)
              SliverToBoxAdapter(child: _priorityProjectCard(textPrimary, muted)),

            // Tabs (Properties / Communities)
            SliverToBoxAdapter(
              child: Padding(
                padding: const EdgeInsets.fromLTRB(24, 28, 24, 12),
                child: Row(
                  children: ['Properties', 'Communities'].map((tab) {
                    final selected = _activeTab == tab;
                    return Padding(
                      padding: const EdgeInsets.only(right: 24),
                      child: GestureDetector(
                        onTap: () => setState(() => _activeTab = tab),
                        child: Column(
                          mainAxisSize: MainAxisSize.min,
                          children: [
                            Text(
                              tab.toUpperCase(),
                              style: GoogleFonts.montserrat(
                                fontSize: 12,
                                fontWeight: FontWeight.w900,
                                letterSpacing: 1.5,
                                color: selected ? textPrimary : muted,
                              ),
                            ),
                            const SizedBox(height: 6),
                            Container(
                              width: 28,
                              height: 2.5,
                              color: selected ? _gold : Colors.transparent,
                            ),
                          ],
                        ),
                      ),
                    );
                  }).toList(),
                ),
              ),
            ),

            // Recommended projects
            projectsAsync.when(
              loading: () => const SliverToBoxAdapter(
                child: Padding(
                  padding: EdgeInsets.symmetric(vertical: 60),
                  child: Center(child: CircularProgressIndicator(color: M4Theme.premiumBlue)),
                ),
              ),
              error: (e, _) => SliverToBoxAdapter(
                child: Padding(
                  padding: const EdgeInsets.symmetric(vertical: 60),
                  child: Center(
                    child: Text('Failed to load projects', style: GoogleFonts.montserrat(color: muted)),
                  ),
                ),
              ),
              data: (projects) {
                if (projects.isEmpty) {
                  return SliverToBoxAdapter(
                    child: Padding(
                      padding: const EdgeInsets.symmetric(vertical: 60),
                      child: Center(
                        child: Text('No projects available', style: GoogleFonts.montserrat(color: muted)),
                      ),
                    ),
                  );
                }
                return SliverToBoxAdapter(child: _projectsRail(projects, textPrimary));
              },
            ),

            // Philosophy + action grid
            SliverToBoxAdapter(child: _actionGrid(isDark, textPrimary, muted)),

            const SliverToBoxAdapter(child: SizedBox(height: 120)),
          ],
        ),
      ),
    );
  }

  Widget _portfolioHero(bool isDark, Color textPrimary) {
    final totalRoi = _portfolio?['totalRoi']?.toString() ?? '0.0%';
    final netProfit = _portfolio?['netProfit']?.toString() ?? '₹0L';
    final avgYield = _portfolio?['avgYield']?.toString() ?? '0.0%';
    final nextPayout = _portfolio?['nextPayout']?.toString() ?? 'N/A';

    return Padding(
      padding: const EdgeInsets.fromLTRB(20, 12, 20, 0),
      child: Container(
        padding: const EdgeInsets.all(24),
        decoration: BoxDecoration(
          borderRadius: BorderRadius.circular(32),
          gradient: const LinearGradient(
            begin: Alignment.topLeft,
            end: Alignment.bottomRight,
            colors: [Color(0xFF1A1A1A), Color(0xFF0A0A0A)],
          ),
          border: Border.all(color: _gold.withValues(alpha: 0.25)),
          boxShadow: [
            BoxShadow(
              color: _gold.withValues(alpha: 0.08),
              blurRadius: 30,
              offset: const Offset(0, 12),
            ),
          ],
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                const Icon(LucideIcons.crown, size: 16, color: _gold),
                const SizedBox(width: 8),
                Text(
                  'PORTFOLIO OVERVIEW',
                  style: GoogleFonts.montserrat(
                    fontSize: 10,
                    fontWeight: FontWeight.w900,
                    letterSpacing: 2.5,
                    color: Colors.white.withValues(alpha: 0.6),
                  ),
                ),
              ],
            ),
            const SizedBox(height: 20),
            Row(
              crossAxisAlignment: CrossAxisAlignment.end,
              children: [
                Text(
                  netProfit,
                  style: GoogleFonts.montserrat(
                    fontSize: 40,
                    fontWeight: FontWeight.w900,
                    color: Colors.white,
                    height: 1.0,
                    letterSpacing: -1.5,
                  ),
                ),
                const SizedBox(width: 10),
                Padding(
                  padding: const EdgeInsets.only(bottom: 6),
                  child: Container(
                    padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
                    decoration: BoxDecoration(
                      color: const Color(0xFF4ADE80).withValues(alpha: 0.15),
                      borderRadius: BorderRadius.circular(8),
                    ),
                    child: Row(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        const Icon(LucideIcons.trendingUp, size: 12, color: Color(0xFF4ADE80)),
                        const SizedBox(width: 4),
                        Text(
                          totalRoi,
                          style: GoogleFonts.montserrat(
                            fontSize: 11,
                            fontWeight: FontWeight.w900,
                            color: const Color(0xFF4ADE80),
                          ),
                        ),
                      ],
                    ),
                  ),
                ),
              ],
            ),
            const SizedBox(height: 4),
            Text(
              'NET PORTFOLIO PROFIT',
              style: GoogleFonts.montserrat(
                fontSize: 9,
                fontWeight: FontWeight.w800,
                letterSpacing: 2,
                color: Colors.white.withValues(alpha: 0.4),
              ),
            ),
            const SizedBox(height: 24),
            Row(
              children: [
                Expanded(child: _heroStat('AVG YIELD', avgYield)),
                Container(width: 1, height: 36, color: Colors.white.withValues(alpha: 0.1)),
                Expanded(child: _heroStat('NEXT PAYOUT', nextPayout)),
              ],
            ),
            if (_loading) ...[
              const SizedBox(height: 16),
              const SizedBox(
                height: 2,
                child: LinearProgressIndicator(
                  backgroundColor: Colors.transparent,
                  color: _gold,
                ),
              ),
            ],
          ],
        ),
      ),
    );
  }

  Widget _heroStat(String label, String value) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.center,
      children: [
        Text(
          label,
          style: GoogleFonts.montserrat(
            fontSize: 8,
            fontWeight: FontWeight.w800,
            letterSpacing: 1.5,
            color: Colors.white.withValues(alpha: 0.4),
          ),
        ),
        const SizedBox(height: 6),
        Text(
          value,
          style: GoogleFonts.montserrat(
            fontSize: 16,
            fontWeight: FontWeight.w900,
            color: Colors.white,
          ),
        ),
      ],
    );
  }

  Widget _priorityProjectCard(Color textPrimary, Color muted) {
    final p = _priorityProject!;
    final img = (p['image'] ?? '').toString();
    final title = (p['title'] ?? '').toString();
    final tag = (p['tag'] ?? 'FEATURED').toString();
    final id = (p['id'] ?? p['_id'] ?? '').toString();

    return Padding(
      padding: const EdgeInsets.fromLTRB(20, 24, 20, 0),
      child: GestureDetector(
        onTap: () {
          if (id.isNotEmpty) context.push('/investor/projects/$id');
        },
        child: ClipRRect(
          borderRadius: BorderRadius.circular(28),
          child: AspectRatio(
            aspectRatio: 16 / 9,
            child: Stack(
              fit: StackFit.expand,
              children: [
                if (img.isNotEmpty)
                  CachedNetworkImage(
                    imageUrl: ref.read(apiClientProvider).resolveUrl(img),
                    fit: BoxFit.cover,
                    errorWidget: (_, __, ___) => Container(color: Colors.grey.shade300),
                  ),
                Container(
                  decoration: BoxDecoration(
                    gradient: LinearGradient(
                      begin: Alignment.topCenter,
                      end: Alignment.bottomCenter,
                      colors: [Colors.transparent, Colors.black.withValues(alpha: 0.85)],
                    ),
                  ),
                ),
                Positioned(
                  top: 14,
                  left: 14,
                  child: Container(
                    padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 5),
                    decoration: BoxDecoration(
                      color: _gold,
                      borderRadius: BorderRadius.circular(8),
                    ),
                    child: Text(
                      tag.toUpperCase(),
                      style: GoogleFonts.montserrat(
                        fontSize: 8,
                        fontWeight: FontWeight.w900,
                        letterSpacing: 1.5,
                        color: Colors.black,
                      ),
                    ),
                  ),
                ),
                Positioned(
                  left: 18,
                  right: 18,
                  bottom: 16,
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        'PRIORITY ACCESS',
                        style: GoogleFonts.montserrat(
                          fontSize: 9,
                          fontWeight: FontWeight.w800,
                          letterSpacing: 2.5,
                          color: _gold,
                        ),
                      ),
                      const SizedBox(height: 6),
                      Text(
                        title,
                        maxLines: 2,
                        overflow: TextOverflow.ellipsis,
                        style: GoogleFonts.montserrat(
                          fontSize: 22,
                          fontWeight: FontWeight.w800,
                          color: Colors.white,
                          height: 1.1,
                        ),
                      ),
                    ],
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }

  Widget _projectsRail(List<dynamic> projects, Color textPrimary) {
    return SizedBox(
      height: 300,
      child: ListView.builder(
        scrollDirection: Axis.horizontal,
        padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 4),
        itemCount: projects.length,
        itemBuilder: (context, i) {
          final p = projects[i];
          final id = p['_id']?.toString() ?? p['id']?.toString() ?? '';
          final status = (p['status'] ?? 'Upcoming').toString();
          return Padding(
            padding: const EdgeInsets.only(right: 14),
            child: GestureDetector(
              onTap: () {
                if (id.isNotEmpty) {
                  context.push('/investor/projects/$id', extra: Map<String, dynamic>.from(p as Map));
                }
              },
              child: ClipRRect(
                borderRadius: BorderRadius.circular(28),
                child: SizedBox(
                  width: 250,
                  child: Stack(
                    fit: StackFit.expand,
                    children: [
                      CachedNetworkImage(imageUrl: _heroUrl(p), fit: BoxFit.cover),
                      Container(
                        decoration: BoxDecoration(
                          gradient: LinearGradient(
                            begin: Alignment.topCenter,
                            end: Alignment.bottomCenter,
                            colors: [Colors.transparent, Colors.black.withValues(alpha: 0.8)],
                          ),
                        ),
                      ),
                      Positioned(
                        top: 10,
                        left: 10,
                        child: Container(
                          padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                          decoration: BoxDecoration(
                            color: Colors.white.withValues(alpha: 0.85),
                            borderRadius: BorderRadius.circular(6),
                          ),
                          child: Text(
                            status.toUpperCase(),
                            style: GoogleFonts.montserrat(fontSize: 8, fontWeight: FontWeight.w800),
                          ),
                        ),
                      ),
                      Positioned(
                        left: 16,
                        right: 16,
                        bottom: 16,
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(
                              (p['title'] ?? '').toString().toUpperCase(),
                              maxLines: 2,
                              overflow: TextOverflow.ellipsis,
                              style: GoogleFonts.montserrat(
                                color: Colors.white,
                                fontWeight: FontWeight.w700,
                                fontSize: 17,
                                height: 1.1,
                              ),
                            ),
                            const SizedBox(height: 6),
                            Row(
                              children: [
                                const Icon(LucideIcons.mapPin, size: 12, color: Colors.white70),
                                const SizedBox(width: 4),
                                Expanded(
                                  child: Text(
                                    _locLine(p).toUpperCase(),
                                    maxLines: 1,
                                    overflow: TextOverflow.ellipsis,
                                    style: GoogleFonts.montserrat(
                                      fontSize: 9,
                                      letterSpacing: 1.5,
                                      color: Colors.white70,
                                    ),
                                  ),
                                ),
                              ],
                            ),
                          ],
                        ),
                      ),
                    ],
                  ),
                ),
              ),
            ),
          );
        },
      ),
    );
  }

  Widget _actionGrid(bool isDark, Color textPrimary, Color muted) {
    final items = [
      (_AG('PORTFOLIO', 'Track your investments', LucideIcons.pieChart, '/investor/portfolio')),
      (_AG('PAYMENTS', 'View payment history', LucideIcons.creditCard, '/investor/payments')),
      (_AG('TAX REPORTS', 'Download statements', LucideIcons.fileText, '/investor/tax-reports')),
      (_AG('REFERRAL', 'Share & earn rewards', LucideIcons.users, '/investor/referral')),
    ];

    return Padding(
      padding: const EdgeInsets.fromLTRB(20, 32, 20, 0),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            'QUICK ACTIONS',
            style: GoogleFonts.montserrat(
              fontSize: 11,
              fontWeight: FontWeight.w900,
              letterSpacing: 2.5,
              color: muted,
            ),
          ),
          const SizedBox(height: 16),
          GridView.count(
            shrinkWrap: true,
            physics: const NeverScrollableScrollPhysics(),
            crossAxisCount: 2,
            mainAxisSpacing: 14,
            crossAxisSpacing: 14,
            childAspectRatio: 1.05,
            children: items
                .map((it) => _actionTile(it, isDark, textPrimary, muted))
                .toList(),
          ),
        ],
      ),
    );
  }

  Widget _actionTile(_AG it, bool isDark, Color textPrimary, Color muted) {
    final card = isDark ? Colors.white.withValues(alpha: 0.03) : Colors.white;
    final border = (isDark ? Colors.white : Colors.black).withValues(alpha: isDark ? 0.08 : 0.06);
    return Material(
      color: card,
      borderRadius: BorderRadius.circular(28),
      child: InkWell(
        onTap: () => context.push(it.route),
        borderRadius: BorderRadius.circular(28),
        child: Container(
          decoration: BoxDecoration(
            borderRadius: BorderRadius.circular(28),
            border: Border.all(color: border),
          ),
          padding: const EdgeInsets.all(18),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Container(
                width: 44,
                height: 44,
                decoration: BoxDecoration(
                  shape: BoxShape.circle,
                  color: _gold.withValues(alpha: 0.12),
                ),
                child: Icon(it.icon, size: 20, color: _gold),
              ),
              Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    it.title,
                    style: GoogleFonts.montserrat(
                      fontSize: 12,
                      fontWeight: FontWeight.w900,
                      color: textPrimary,
                      letterSpacing: 0.5,
                    ),
                  ),
                  const SizedBox(height: 4),
                  Text(
                    it.subtitle,
                    style: GoogleFonts.montserrat(
                      fontSize: 9,
                      fontWeight: FontWeight.w600,
                      color: muted,
                    ),
                  ),
                ],
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class _AG {
  final String title;
  final String subtitle;
  final IconData icon;
  final String route;
  _AG(this.title, this.subtitle, this.icon, this.route);
}
