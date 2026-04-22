import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:lucide_icons/lucide_icons.dart';
import 'package:m4_mobile/presentation/providers/auth_provider.dart';
import 'package:cached_network_image/cached_network_image.dart';
import 'package:intl/intl.dart';
import 'package:m4_mobile/presentation/widgets/cp_sidebar_menu.dart';

class CpBlogScreen extends ConsumerStatefulWidget {
  const CpBlogScreen({super.key});

  @override
  ConsumerState<CpBlogScreen> createState() => _CpBlogScreenState();
}

class _CpBlogScreenState extends ConsumerState<CpBlogScreen> {
  List<dynamic> _items = [];
  bool _loading = true;

  @override
  void initState() {
    super.initState();
    _fetchBlogPosts();
  }

  Future<void> _fetchBlogPosts() async {
    try {
      final api = ref.read(apiClientProvider);
      final res = await api.getContent('blog', role: 'cp');
      if (res.statusCode == 200) {
        setState(() {
          _items = res.data['data'] ?? [];
          _loading = false;
        });
      }
    } catch (e) {
      debugPrint('Failed to load blog posts: $e');
      setState(() => _loading = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final isLight = !isDark;
    final scheme = Theme.of(context).colorScheme;

    return Scaffold(
      backgroundColor: scheme.surface,
      drawer: const CpSidebarMenu(),
      body: CustomScrollView(
        slivers: [
          // Standardized Header (Web Parity)
          SliverAppBar(
            pinned: true,
            floating: true,
            elevation: 0,
            backgroundColor: scheme.surface.withOpacity(0.8),
            leadingWidth: 76,
            leading: Padding(
              padding: const EdgeInsets.only(left: 20),
              child: Center(
                child: IconButton(
                  onPressed: () => Navigator.pop(context),
                  icon: const Icon(LucideIcons.arrowLeft, size: 20),
                  style: IconButton.styleFrom(
                    backgroundColor: scheme.onSurface.withOpacity(0.05),
                    shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(14)),
                    fixedSize: const Size(48, 48),
                  ),
                ),
              ),
            ),
            title: Column(
              children: [
                Text(
                  'M4 FAMILY',
                  style: GoogleFonts.montserrat(
                    fontSize: 14,
                    fontWeight: FontWeight.w900,
                    letterSpacing: 2,
                    height: 1,
                  ),
                ),
                Text(
                  'DEVELOPMENTS',
                  style: GoogleFonts.montserrat(
                    fontSize: 8,
                    fontWeight: FontWeight.w700,
                    letterSpacing: 4,
                    color: scheme.onSurface.withOpacity(isLight ? 0.7 : 0.5),
                    height: 1.5,
                  ),
                ),
              ],
            ),
            actions: [
              Builder(
                builder: (ctx) => Padding(
                  padding: const EdgeInsets.only(right: 20),
                  child: IconButton(
                    onPressed: () => Scaffold.of(ctx).openDrawer(),
                    icon: const Icon(LucideIcons.moreHorizontal, size: 22, color: Colors.white),
                    style: IconButton.styleFrom(
                      backgroundColor: Colors.black,
                      foregroundColor: Colors.white,
                      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(14)),
                      fixedSize: const Size(56, 48),
                    ),
                  ),
                ),
              ),
            ],
          ),

          // Section Header Content
          SliverToBoxAdapter(
            child: Padding(
              padding: const EdgeInsets.fromLTRB(24, 32, 24, 0),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    children: [
                      Container(
                        padding: const EdgeInsets.all(10),
                        decoration: BoxDecoration(
                          color: (isLight ? Colors.black : scheme.primary).withOpacity(0.1),
                          borderRadius: BorderRadius.circular(16),
                          border: Border.all(color: (isLight ? Colors.black : scheme.primary).withOpacity(0.2)),
                        ),
                        child: Icon(LucideIcons.fileText, size: 20, color: isLight ? Colors.black : scheme.primary),
                      ),
                      const SizedBox(width: 14),
                      Text(
                        'CONTENT HUB',
                        style: GoogleFonts.montserrat(
                          fontSize: 10,
                          fontWeight: FontWeight.w900,
                          letterSpacing: 3,
                          color: isLight ? Colors.black : scheme.primary,
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 16),
                  Text(
                    'M4 BLOG',
                    style: GoogleFonts.montserrat(
                      fontSize: 32,
                      fontWeight: FontWeight.w900,
                      letterSpacing: -1,
                      height: 1.0,
                      color: isLight ? Colors.black : Colors.white,
                    ),
                  ),
                  const SizedBox(height: 16),
                  Text(
                    'Stay updated with our latest insights and news.',
                    style: GoogleFonts.montserrat(
                      fontSize: 14,
                      fontWeight: FontWeight.w600,
                      color: scheme.onSurface.withOpacity(isLight ? 0.8 : 0.6),
                      height: 1.5,
                    ),
                  ),
                ],
              ),
            ),
          ),

          // Blog List
          if (_loading)
            const SliverFillRemaining(
              child: Center(child: CircularProgressIndicator()),
            )
          else if (_items.isEmpty)
            SliverFillRemaining(
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Icon(LucideIcons.fileX, size: 64, color: scheme.onSurface.withOpacity(0.1)),
                  const SizedBox(height: 16),
                  Text(
                    'No blog posts found',
                    style: GoogleFonts.montserrat(fontSize: 18, fontWeight: FontWeight.w900, color: isLight ? Colors.black : Colors.white),
                  ),
                  const SizedBox(height: 8),
                  Text(
                    "Check back soon for fresh updates.",
                    style: GoogleFonts.montserrat(
                      color: scheme.onSurface.withOpacity(isLight ? 0.7 : 0.5),
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                ],
              ),
            )
          else
            SliverPadding(
              padding: const EdgeInsets.fromLTRB(24, 32, 24, 100),
              sliver: SliverList(
                delegate: SliverChildBuilderDelegate(
                  (context, index) {
                    final item = _items[index];
                    return _BlogCard(item: item);
                  },
                  childCount: _items.length,
                ),
              ),
            ),
        ],
      ),
    );
  }
}

class _BlogCard extends ConsumerWidget {
  final dynamic item;
  const _BlogCard({required this.item});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final scheme = Theme.of(context).colorScheme;
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final isLight = !isDark;
    final api = ref.read(apiClientProvider);

    final imageUrl = api.resolveUrl(item['image'] ?? item['thumbnail'] ?? item['coverImage']);
    final date = DateTime.tryParse(item['createdAt'] ?? '') ?? DateTime.now();
    final formattedDate = DateFormat('MMMM dd, yyyy').format(date);

    return Container(
      margin: const EdgeInsets.only(bottom: 32),
      decoration: BoxDecoration(
        color: isDark ? const Color(0xFF18181B) : Colors.white,
        borderRadius: BorderRadius.circular(40),
        border: Border.all(color: scheme.onSurface.withOpacity(0.05)),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(isDark ? 0.2 : 0.05),
            blurRadius: 30,
            offset: const Offset(0, 15),
          ),
        ],
      ),
      clipBehavior: Clip.antiAlias,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Cover Image
          AspectRatio(
            aspectRatio: 16 / 10,
            child: Stack(
              fit: StackFit.expand,
              children: [
                CachedNetworkImage(
                  imageUrl: imageUrl,
                  fit: BoxFit.cover,
                  placeholder: (_, __) => Container(color: scheme.surfaceContainerHighest),
                  errorWidget: (_, __, ___) => Container(
                    color: scheme.surfaceContainerHighest,
                    child: const Icon(LucideIcons.image, color: Colors.grey),
                  ),
                ),
                Container(
                  decoration: BoxDecoration(
                    gradient: LinearGradient(
                      begin: Alignment.topCenter,
                      end: Alignment.bottomCenter,
                      colors: [
                        Colors.transparent,
                        Colors.black.withOpacity(0.6),
                      ],
                    ),
                  ),
                ),
                Positioned(
                  top: 20,
                  right: 20,
                  child: Container(
                    padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 6),
                    decoration: BoxDecoration(
                      color: Colors.white.withOpacity(0.1),
                      borderRadius: BorderRadius.circular(100),
                      border: Border.all(color: Colors.white.withOpacity(0.2)),
                    ),
                    child: Text(
                      (item['type'] ?? 'ARTICLE').toString().toUpperCase(),
                      style: GoogleFonts.montserrat(
                        fontSize: 8,
                        fontWeight: FontWeight.w900,
                        letterSpacing: 2,
                        color: Colors.white,
                      ),
                    ),
                  ),
                ),
              ],
            ),
          ),

          // Content
          Padding(
            padding: const EdgeInsets.all(28),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  children: [
                    Icon(LucideIcons.calendar, size: 12, color: scheme.onSurface.withOpacity(0.3)),
                    const SizedBox(width: 6),
                    Text(
                      formattedDate.toUpperCase(),
                      style: GoogleFonts.montserrat(
                        fontSize: 9,
                        fontWeight: FontWeight.w800,
                        letterSpacing: 1.5,
                        color: scheme.onSurface.withOpacity(0.5),
                      ),
                    ),
                    const SizedBox(width: 12),
                    Container(width: 4, height: 4, decoration: BoxDecoration(color: scheme.primary.withOpacity(0.4), shape: BoxShape.circle)),
                    const SizedBox(width: 12),
                    Icon(LucideIcons.user, size: 12, color: scheme.onSurface.withOpacity(0.3)),
                    const SizedBox(width: 6),
                    Text(
                      'BY M4 TEAM',
                      style: GoogleFonts.montserrat(
                        fontSize: 9,
                        fontWeight: FontWeight.w800,
                        letterSpacing: 1.5,
                        color: scheme.onSurface.withOpacity(0.5),
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 16),
                Text(
                  (item['title'] ?? '').toString().toUpperCase(),
                  style: GoogleFonts.montserrat(
                    fontSize: 20,
                    fontWeight: FontWeight.w900,
                    letterSpacing: -0.5,
                    height: 1.1,
                    color: isLight ? Colors.black : Colors.white,
                  ),
                  maxLines: 2,
                  overflow: TextOverflow.ellipsis,
                ),
                const SizedBox(height: 12),
                Text(
                  (item['description'] ?? '').toString(),
                  style: GoogleFonts.montserrat(
                    fontSize: 14,
                    fontWeight: FontWeight.w600,
                    color: scheme.onSurface.withOpacity(isLight ? 0.75 : 0.6),
                    height: 1.5,
                  ),
                  maxLines: 2,
                  overflow: TextOverflow.ellipsis,
                ),
                const SizedBox(height: 24),
                Container(height: 1, color: scheme.onSurface.withOpacity(0.05)),
                const SizedBox(height: 20),
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    TextButton.icon(
                      onPressed: () {}, 
                      icon: const Icon(LucideIcons.arrowRight, size: 16),
                      label: Text(
                        'READ MORE',
                        style: GoogleFonts.montserrat(
                          fontSize: 10,
                          fontWeight: FontWeight.w900,
                          letterSpacing: 1.5,
                        ),
                      ),
                      style: TextButton.styleFrom(
                        foregroundColor: isLight ? Colors.black : scheme.primary,
                        padding: EdgeInsets.zero,
                      ),
                    ),
                    IconButton(
                      onPressed: () {},
                      icon: const Icon(LucideIcons.share2, size: 18),
                      style: IconButton.styleFrom(
                        backgroundColor: scheme.onSurface.withOpacity(0.05),
                        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                      ),
                    ),
                  ],
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}
