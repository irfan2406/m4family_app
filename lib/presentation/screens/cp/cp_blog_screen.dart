import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:lucide_icons/lucide_icons.dart';
import 'package:m4_mobile/presentation/widgets/side_menu_button.dart';
import 'package:m4_mobile/presentation/providers/auth_provider.dart';
import 'package:cached_network_image/cached_network_image.dart';
import 'package:intl/intl.dart';
import 'package:m4_mobile/presentation/widgets/cp_sidebar_menu.dart';
import 'package:m4_mobile/presentation/widgets/cp_bottom_nav.dart';
import 'package:m4_mobile/presentation/providers/cp_shell_provider.dart';
import 'package:go_router/go_router.dart';
import 'package:m4_mobile/presentation/screens/content/content_detail_screen.dart';

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
      extendBody: true,
      bottomNavigationBar: CpBottomNav(
        currentIndex: -1,
        onTap: (i) {
          ref.read(cpNavigationIndexProvider.notifier).state = i;
          if (context.canPop()) context.pop();
        },
      ),
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
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(14),
                    ),
                    fixedSize: const Size(48, 48),
                  ),
                ),
              ),
            ),
            title: Column(
              children: [
                Text(
                  'M4 FAMILY',
                  style: GoogleFonts.dmSerifDisplay(
                    fontSize: 14,
                    fontWeight: FontWeight.w900,
                    letterSpacing: 2,
                    height: 1,
                  ),
                ),
                Text(
                  'DEVELOPMENTS',
                  style: GoogleFonts.dmSerifDisplay(
                    fontSize: 8,
                    fontWeight: FontWeight.w700,
                    letterSpacing: 4,
                    color: scheme.onSurface.withOpacity(isLight ? 0.7 : 0.68),
                    height: 1.5,
                  ),
                ),
              ],
            ),
            actions: [
              const Padding(
                padding: EdgeInsets.only(right: 20),
                child: SideMenuButton(),
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
                          color: (isLight ? Colors.black : scheme.primary)
                              .withOpacity(0.1),
                          borderRadius: BorderRadius.circular(16),
                          border: Border.all(
                            color: (isLight ? Colors.black : scheme.primary)
                                .withOpacity(0.2),
                          ),
                        ),
                        child: Icon(
                          LucideIcons.fileText,
                          size: 20,
                          color: isLight ? Colors.black : scheme.primary,
                        ),
                      ),
                      const SizedBox(width: 14),
                      Text(
                        'CONTENT HUB',
                        style: GoogleFonts.dmSerifDisplay(
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
                    style: GoogleFonts.dmSerifDisplay(
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
                    style: GoogleFonts.dmSerifDisplay(
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
                  Icon(
                    LucideIcons.fileX,
                    size: 64,
                    color: scheme.onSurface.withOpacity(0.1),
                  ),
                  const SizedBox(height: 16),
                  Text(
                    'No blog posts found',
                    style: GoogleFonts.dmSerifDisplay(
                      fontSize: 18,
                      fontWeight: FontWeight.w900,
                      color: isLight ? Colors.black : Colors.white,
                    ),
                  ),
                  const SizedBox(height: 8),
                  Text(
                    "Check back soon for fresh updates.",
                    style: GoogleFonts.dmSerifDisplay(
                      color: scheme.onSurface.withOpacity(isLight ? 0.7 : 0.68),
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
                delegate: SliverChildBuilderDelegate((context, index) {
                  final item = _items[index];
                  return _BlogCard(item: item);
                }, childCount: _items.length),
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

    final imageUrl = api.resolveUrl(
      item['image'] ?? item['thumbnail'] ?? item['coverImage'],
    );
    final date = DateTime.tryParse(item['createdAt'] ?? '') ?? DateTime.now();
    final shortDate = DateFormat('M/d/yyyy').format(date);

    // Web parity: a compact horizontal card — small square cover on the left,
    // BLOG badge + title + READ ARTICLE on the right, date top-right. Tapping
    // anywhere opens the article (READ MORE / share were dead `() {}` before).
    return Container(
      margin: const EdgeInsets.only(bottom: 16),
      decoration: BoxDecoration(
        color: isDark ? const Color(0xFF18181B) : Colors.white,
        borderRadius: BorderRadius.circular(24),
        border: Border.all(color: scheme.onSurface.withOpacity(0.05)),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(isDark ? 0.2 : 0.05),
            blurRadius: 20,
            offset: const Offset(0, 8),
          ),
        ],
      ),
      clipBehavior: Clip.antiAlias,
      child: Material(
        color: Colors.transparent,
        child: InkWell(
          onTap: () => Navigator.push(
            context,
            MaterialPageRoute(
              builder: (_) => ContentDetailScreen(content: item),
            ),
          ),
          child: Padding(
            padding: const EdgeInsets.all(12),
            child: Row(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                ClipRRect(
                  borderRadius: BorderRadius.circular(16),
                  child: SizedBox(
                    width: 92,
                    height: 92,
                    child: CachedNetworkImage(
                      imageUrl: imageUrl,
                      fit: BoxFit.cover,
                      placeholder: (_, __) =>
                          Container(color: scheme.surfaceContainerHighest),
                      errorWidget: (_, __, ___) => Container(
                        color: scheme.surfaceContainerHighest,
                        child: const Icon(
                          LucideIcons.image,
                          color: Colors.grey,
                          size: 20,
                        ),
                      ),
                    ),
                  ),
                ),
                const SizedBox(width: 14),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Row(
                        children: [
                          Container(
                            padding: const EdgeInsets.symmetric(
                              horizontal: 10,
                              vertical: 4,
                            ),
                            decoration: BoxDecoration(
                              color: scheme.onSurface.withOpacity(0.06),
                              borderRadius: BorderRadius.circular(6),
                            ),
                            child: Text(
                              (item['type'] ?? 'BLOG').toString().toUpperCase(),
                              style: GoogleFonts.dmSerifDisplay(
                                fontSize: 8,
                                fontWeight: FontWeight.w900,
                                letterSpacing: 1.2,
                                color: scheme.onSurface.withOpacity(0.7),
                              ),
                            ),
                          ),
                          const Spacer(),
                          Text(
                            shortDate,
                            style: GoogleFonts.dmSerifDisplay(
                              fontSize: 9,
                              fontWeight: FontWeight.w700,
                              color: scheme.onSurface.withOpacity(0.4),
                            ),
                          ),
                        ],
                      ),
                      const SizedBox(height: 8),
                      Text(
                        (item['title'] ?? '').toString().toUpperCase(),
                        maxLines: 2,
                        overflow: TextOverflow.ellipsis,
                        style: GoogleFonts.dmSerifDisplay(
                          fontSize: 13,
                          fontWeight: FontWeight.w900,
                          height: 1.15,
                          letterSpacing: -0.3,
                          color: isLight ? Colors.black : Colors.white,
                        ),
                      ),
                      const SizedBox(height: 10),
                      Row(
                        children: [
                          Text(
                            'READ ARTICLE',
                            style: GoogleFonts.dmSerifDisplay(
                              fontSize: 9,
                              fontWeight: FontWeight.w900,
                              letterSpacing: 1,
                              color: isLight ? Colors.black : scheme.primary,
                            ),
                          ),
                          const Spacer(),
                          Icon(
                            LucideIcons.arrowRight,
                            size: 14,
                            color: isLight ? Colors.black : scheme.primary,
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
  }
}
