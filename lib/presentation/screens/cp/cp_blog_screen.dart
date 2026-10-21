import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:m4_mobile/presentation/providers/live_sync_provider.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:lucide_icons/lucide_icons.dart';
import 'package:m4_mobile/presentation/widgets/side_menu_button.dart';
import 'package:m4_mobile/presentation/widgets/content_hub_card.dart';
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
      if (!mounted) return;
      if (res.statusCode == 200) {
        setState(() {
          _items = res.data['data'] ?? [];
          _loading = false;
        });
      }
    } catch (e) {
      debugPrint('Failed to load blog posts: $e');
      if (mounted) setState(() => _loading = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    // Admin edits: reload in place when the server reports a change.
    listenForAdminChanges(
      ref,
      const {SyncTopic.content},
      _fetchBlogPosts,
    );
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
                  style: GoogleFonts.gelasio(
                    fontSize: 14,
                    fontWeight: FontWeight.w700,
                    letterSpacing: 2,
                    height: 1,
                  ),
                ),
              ],
            ),
            actions: const [
              Padding(
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
                          color: isLight
                              ? const Color(0xFF0C312B)
                              : scheme.primary,
                        ),
                      ),
                      const SizedBox(width: 14),
                      Text(
                        'CONTENT HUB',
                        style: GoogleFonts.gelasio(
                          fontSize: 10,
                          fontWeight: FontWeight.w700,
                          letterSpacing: 3,
                          color: isLight
                              ? const Color(0xFF0C312B)
                              : scheme.primary,
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 16),
                  Text(
                    'M4 BLOG',
                    style: GoogleFonts.gelasio(
                      fontSize: 32,
                      fontWeight: FontWeight.w700,
                      letterSpacing: -1,
                      height: 1.0,
                      color: isLight ? const Color(0xFF0C312B) : Colors.white,
                    ),
                  ),
                  const SizedBox(height: 16),
                  Text(
                    'Stay updated with our latest insights and news.',
                    style: GoogleFonts.inter(
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
              child: Center(child: CircularProgressIndicator.adaptive()),
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
                    style: GoogleFonts.gelasio(
                      fontSize: 18,
                      fontWeight: FontWeight.w700,
                      color: isLight ? const Color(0xFF0C312B) : Colors.white,
                    ),
                  ),
                  const SizedBox(height: 8),
                  Text(
                    "Check back soon for fresh updates.",
                    style: GoogleFonts.inter(
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
                  // The shared Content Hub card — same as Media, Highlights,
                  // Events and every other portal's Blog.
                  return ContentHubCard(
                    item: item,
                    typeLabel: 'blog',
                    placeholderIcon: LucideIcons.fileText,
                    onTap: () => Navigator.push(
                      context,
                      MaterialPageRoute(
                        builder: (_) => ContentDetailScreen(content: item),
                      ),
                    ),
                  );
                }, childCount: _items.length),
              ),
            ),
        ],
      ),
    );
  }
}
