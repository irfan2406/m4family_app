import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:lucide_icons/lucide_icons.dart';
import 'package:m4_mobile/presentation/providers/auth_provider.dart';
import 'package:url_launcher/url_launcher.dart';

/// Web `/cp/hub/insights` — market pulse + latest analysis cards.
/// Flutter: pulse backed by `GET /api/cp/performance`, latest analysis backed by `GET /api/content` (db).
class CpHubInsightsScreen extends ConsumerStatefulWidget {
  const CpHubInsightsScreen({super.key});

  @override
  ConsumerState<CpHubInsightsScreen> createState() => _CpHubInsightsScreenState();
}

class _CpHubInsightsScreenState extends ConsumerState<CpHubInsightsScreen> {
  Map<String, dynamic>? _data;
  List<dynamic> _articles = const [];
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
        api.getContent('blog', role: 'cp'),
      ]);
      final res = results[0];
      final content = results[1];
      if (!mounted) return;
      if (res.statusCode == 200 && res.data['status'] == true) {
        final d = res.data['data'];
        if (d is Map) _data = Map<String, dynamic>.from(d);
      }
      final cb = content.data;
      if (cb is Map && cb['status'] == true && cb['data'] is List) {
        _articles = List<dynamic>.from(cb['data'] as List);
      } else if (cb is List) {
        _articles = List<dynamic>.from(cb);
      }
    } catch (_) {}
    if (mounted) setState(() => _loading = false);
  }

  String? _stringUrl(dynamic v) {
    if (v == null) return null;
    if (v is String) return v;
    if (v is Map) {
      return v['url']?.toString() ?? v['fileUrl']?.toString() ?? v['src']?.toString() ?? v['image']?.toString() ?? v['cover']?.toString() ?? v['thumbnail']?.toString();
    }
    return v.toString();
  }

  Future<void> _open(String? url) async {
    if (url == null || url.isEmpty) return;
    final resolved = ref.read(apiClientProvider).resolveUrl(url);
    await launchUrl(Uri.parse(resolved), mode: LaunchMode.externalApplication);
  }

  @override
  Widget build(BuildContext context) {
    final scheme = Theme.of(context).colorScheme;
    final isLight = scheme.brightness == Brightness.light;
    final accent = isLight ? Colors.black : scheme.primary;
    const purple = Color(0xFFA855F7);

    final rate = _data?['conversionRate']?.toString() ?? '0%';
    final leads = _data?['totalLeads'] ?? 0;
    final books = _data?['totalConversions'] ?? 0;

    final fallback = const [
      {
        'category': 'Market Trend',
        'title': 'Commercial Real Estate in 2024: A Bullish Outlook',
        'readTime': '5 min read',
        'image': 'https://images.unsplash.com/photo-1486406146926-c627a92ad1ab?q=80&w=1000',
      },
      {
        'category': 'Analysis',
        'title': 'Why Tier-2 Cities are the New Goldmine',
        'readTime': '3 min read',
        'image': 'https://images.unsplash.com/photo-1582407947304-fd86f028f716?q=80&w=1000',
      },
      {
        'category': 'Policy',
        'title': 'New RERA Amendments: Impact on Partners',
        'readTime': '4 min read',
        'image': 'https://images.unsplash.com/photo-1554224155-8d04cb21cd6c?q=80&w=1000',
      },
    ];

    final items = _articles.isNotEmpty ? _articles : fallback;

    return Scaffold(
      appBar: AppBar(
        leading: IconButton(icon: const Icon(LucideIcons.arrowLeft), onPressed: () => context.pop()),
        title: Text('Insights', style: GoogleFonts.montserrat(fontWeight: FontWeight.w800)),
      ),
      body: _loading
          ? Center(child: CircularProgressIndicator(color: accent))
          : ListView(
              padding: const EdgeInsets.fromLTRB(16, 14, 16, 24),
              children: [
                // Market Pulse (web gradient card)
                Container(
                  padding: const EdgeInsets.all(16),
                  decoration: BoxDecoration(
                    borderRadius: BorderRadius.circular(18),
                    gradient: const LinearGradient(colors: [Color(0xFFA855F7), Color(0xFF7C3AED)]),
                    boxShadow: [BoxShadow(color: purple.withValues(alpha: 0.18), blurRadius: 22, offset: const Offset(0, 14))],
                  ),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Container(
                        padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                        decoration: BoxDecoration(
                          borderRadius: BorderRadius.circular(8),
                          color: Colors.black.withValues(alpha: 0.25),
                          border: Border.all(color: Colors.white.withValues(alpha: 0.2)),
                        ),
                        child: Text('DAILY PULSE', style: GoogleFonts.montserrat(fontSize: 8, fontWeight: FontWeight.w900, letterSpacing: 1.4, color: Colors.white)),
                      ),
                      const SizedBox(height: 10),
                      Text(
                        'Conversion rate $rate with $books bookings from $leads leads',
                        style: GoogleFonts.montserrat(fontSize: 16, fontWeight: FontWeight.w900, color: Colors.white, height: 1.2),
                      ),
                      const SizedBox(height: 12),
                      FilledButton(
                        onPressed: () => ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('Report coming soon'))),
                        style: FilledButton.styleFrom(
                          backgroundColor: Colors.black.withValues(alpha: 0.25),
                          foregroundColor: Colors.white,
                          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                        ),
                        child: Row(
                          mainAxisSize: MainAxisSize.min,
                          children: [
                            Text('READ REPORT', style: GoogleFonts.montserrat(fontSize: 9, fontWeight: FontWeight.w900, letterSpacing: 2)),
                            const SizedBox(width: 6),
                            const Icon(LucideIcons.arrowUpRight, size: 14),
                          ],
                        ),
                      ),
                    ],
                  ),
                ),
                const SizedBox(height: 18),
                Row(
                  children: [
                    const Icon(LucideIcons.newspaper, size: 16, color: purple),
                    const SizedBox(width: 8),
                    Text('Latest Analysis', style: GoogleFonts.montserrat(fontSize: 12, fontWeight: FontWeight.w900)),
                  ],
                ),
                const SizedBox(height: 12),
                for (final it in items) ...[
                  _articleCard(context, scheme, it),
                  const SizedBox(height: 14),
                ],
              ],
            ),
    );
  }

  Widget _articleCard(BuildContext context, ColorScheme scheme, dynamic raw) {
    final m = raw is Map ? Map<String, dynamic>.from(raw) : <String, dynamic>{};
    final title = (m['title'] ?? 'Article').toString();
    final category = (m['category'] ?? m['type'] ?? m['tag'] ?? 'Analysis').toString();
    final readTime = (m['readTime'] ?? m['duration'] ?? '').toString();
    final image = _stringUrl(m['image'] ?? m['coverImage'] ?? m['cover'] ?? m['thumbnail']);
    final url = _stringUrl(m['url'] ?? m['link']);

    return GestureDetector(
      onTap: () {
        if (url != null && url.isNotEmpty) {
          _open(url);
        } else {
          ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('Content coming soon')));
        }
      },
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          ClipRRect(
            borderRadius: BorderRadius.circular(14),
            child: SizedBox(
              height: 130,
              width: double.infinity,
              child: Stack(
                fit: StackFit.expand,
                children: [
                  if (image != null && image.isNotEmpty)
                    Image.network(
                      ref.read(apiClientProvider).resolveUrl(image),
                      fit: BoxFit.cover,
                      errorBuilder: (_, __, ___) => Container(color: scheme.surfaceContainerHighest),
                    )
                  else
                    Container(color: scheme.surfaceContainerHighest),
                  Container(color: Colors.black.withValues(alpha: 0.25)),
                  Positioned(
                    top: 10,
                    left: 10,
                    child: Container(
                      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 6),
                      decoration: BoxDecoration(
                        color: Colors.black.withValues(alpha: 0.55),
                        borderRadius: BorderRadius.circular(8),
                      ),
                      child: Text(
                        category.toUpperCase(),
                        style: GoogleFonts.montserrat(fontSize: 8, fontWeight: FontWeight.w900, letterSpacing: 1.3, color: const Color(0xFFA855F7)),
                      ),
                    ),
                  ),
                ],
              ),
            ),
          ),
          const SizedBox(height: 10),
          Text(
            title,
            style: GoogleFonts.montserrat(fontSize: 13, fontWeight: FontWeight.w900, height: 1.2),
          ),
          const SizedBox(height: 4),
          Text(
            readTime.isEmpty ? 'READ' : readTime.toUpperCase(),
            style: GoogleFonts.montserrat(fontSize: 9, fontWeight: FontWeight.w800, letterSpacing: 1.4, color: scheme.onSurface.withValues(alpha: 0.55)),
          ),
        ],
      ),
    );
  }
}
