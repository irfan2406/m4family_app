import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:google_fonts/google_fonts.dart';
import 'dart:ui';
import 'package:lucide_icons/lucide_icons.dart';
import 'package:flutter_animate/flutter_animate.dart';
import 'package:m4_mobile/presentation/widgets/conditional_drawer.dart';
import 'package:m4_mobile/presentation/widgets/cp_bottom_nav.dart';
import 'package:m4_mobile/presentation/providers/auth_provider.dart';
import 'package:m4_mobile/presentation/providers/cp_shell_provider.dart';
import 'package:m4_mobile/core/utils/media_url.dart';
import 'package:cached_network_image/cached_network_image.dart';
import 'package:go_router/go_router.dart';

class GuestCustomViewsScreen extends ConsumerStatefulWidget {
  const GuestCustomViewsScreen({super.key});

  @override
  ConsumerState<GuestCustomViewsScreen> createState() =>
      _GuestCustomViewsScreenState();
}

class _GuestCustomViewsScreenState
    extends ConsumerState<GuestCustomViewsScreen> {
  final ScrollController _scrollController = ScrollController();

  // Backend-driven: the "Interactive Living" tiles come from the admin's
  // SHOWCASE content (Central Content Hub). Admin add / edit / remove reflects
  // here on the next open — no hardcoded categories.
  List<Map<String, String>> _categories = [];

  @override
  void initState() {
    super.initState();
    _fetchShowcase();
  }

  Future<void> _fetchShowcase() async {
    try {
      final api = ref.read(apiClientProvider);
      final role = (ref.read(authProvider).user?['role'] ?? 'guest')
          .toString()
          .toLowerCase();
      final res = await api.getContent(
        'showcase',
        role: role.isEmpty ? 'guest' : role,
      );
      final data = res.data['data'] as List? ?? const [];
      final items = <Map<String, String>>[];
      for (final it in data) {
        if (it is! Map) continue;
        final title = (it['title'] ?? '').toString().trim();
        if (title.isEmpty) continue;
        final raw = firstMediaUrl([
          it['thumbnail'],
          it['image'],
          it['coverImage'],
        ]);
        items.add({
          'title': title.toUpperCase(),
          'image': raw.isEmpty ? '' : api.resolveUrl(raw),
        });
      }
      if (mounted) setState(() => _categories = items);
    } catch (_) {
      // Leave the grid empty on failure rather than showing stale/stock tiles.
    }
  }

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final role = (ref.watch(authProvider).user?['role'] ?? '')
        .toString()
        .toLowerCase();
    final isCp = role == 'cp';

    return Scaffold(
      backgroundColor: isDark ? Colors.black : const Color(0xFFF4EFE3),
      drawer: const ConditionalDrawer(),
      extendBody: true,
      bottomNavigationBar: isCp
          ? CpBottomNav(
              currentIndex: -1,
              onTap: (i) {
                ref.read(cpNavigationIndexProvider.notifier).state = i;
                if (context.canPop()) context.pop();
              },
            )
          : null,
      body: CustomScrollView(
        controller: _scrollController,
        slivers: [
          // 🔝 Premium Header
          SliverAppBar(
            pinned: true,
            backgroundColor: isDark
                ? const Color(0xFF0B1026)
                : const Color(0xFFF4EFE3),
            elevation: 0,
            leadingWidth: 72,
            toolbarHeight: 80,
            flexibleSpace: ClipRRect(
              child: BackdropFilter(
                filter: ImageFilter.blur(sigmaX: 10, sigmaY: 10),
                child: Container(color: Colors.transparent),
              ),
            ),
            leading: Center(
              child: _HeaderCircleAction(
                icon: LucideIcons.arrowLeft,
                // Pop back to wherever we came from (CP/user/guest all push this
                // screen); fall back to home only if there's nothing to pop.
                onTap: () =>
                    context.canPop() ? context.pop() : context.go('/home'),
              ),
            ),
            title: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  'INTERACTIVE LIVING',
                  style: GoogleFonts.inter(
                    color: isDark ? Colors.white : const Color(0xFF155A4F),
                    fontWeight: FontWeight.w600,
                    fontSize: 14,
                    letterSpacing: 0.5,
                  ),
                ),
              ],
            ),
          ),

          // 🎭 Hero Section
          SliverPadding(
            padding: const EdgeInsets.symmetric(horizontal: 25, vertical: 40),
            sliver: SliverToBoxAdapter(
              child: Column(
                children: [
                  Text(
                        'DESIGN\nYOUR\nDESTINY',
                        textAlign: TextAlign.center,
                        // Web parity: font-light serif (elegant, thin
                        // high-contrast), not a heavy slab display face.
                        style: GoogleFonts.gelasio(
                          color: isDark
                              ? Colors.white
                              : const Color(0xFF0C312B),
                          fontSize: 52,
                          fontWeight: FontWeight.w400,
                          height: 1.1,
                          letterSpacing: -1,
                        ),
                      )
                      .animate()
                      .fadeIn(duration: 800.ms)
                      .slideY(begin: 0.2, end: 0),
                  const SizedBox(height: 32),
                  Container(
                    width: 50,
                    height: 1.5,
                    color: (isDark ? Colors.white : const Color(0xFF0C312B))
                        .withOpacity(0.2),
                  ),
                  const SizedBox(height: 48),
                  Text(
                    'Experience the future of home personalisation. Our proprietary Custom Views suite allows you to visualise and craft your dream space before it\'s even built. Every M4 residence is a bespoke masterpiece, where your vision dictates the architecture of luxury. Beyond standard configurations, we offer a multi-sensory design experience—from haptic material selection to precision spatial planning. Our suite ensures that your digital blueprint translates into a tangible sanctuary of unparalleled refinement.',
                    textAlign: TextAlign.center,
                    style: GoogleFonts.inter(
                      color: (isDark ? Colors.white : const Color(0xFF0C312B))
                          .withOpacity(0.7),
                      fontSize: 14,
                      height: 1.8,
                      fontWeight: FontWeight.w500,
                    ),
                  ).animate().fadeIn(delay: 400.ms, duration: 800.ms),
                  const SizedBox(height: 60),
                ],
              ),
            ),
          ),

          // 🖼️ Grid of Categories
          SliverPadding(
            padding: const EdgeInsets.symmetric(horizontal: 25),
            sliver: SliverGrid(
              // 16:9 cards — the ratio every card image uses.
              gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
                crossAxisCount: 2,
                mainAxisSpacing: 25,
                crossAxisSpacing: 25,
                childAspectRatio: 16 / 9,
              ),
              delegate: SliverChildBuilderDelegate((context, index) {
                final cat = _categories[index];
                return Container(
                      decoration: BoxDecoration(
                        borderRadius: BorderRadius.circular(44),
                        boxShadow: [
                          BoxShadow(
                            color:
                                (isDark
                                        ? Colors.white
                                        : const Color(0xFF0C312B))
                                    .withOpacity(0.08),
                            blurRadius: 25,
                            offset: const Offset(0, 10),
                          ),
                        ],
                      ),
                      child: ClipRRect(
                        borderRadius: BorderRadius.circular(44),
                        child: Stack(
                          fit: StackFit.expand,
                          children: [
                            // Dark backdrop so an uploaded image with a
                            // transparent / white background (e.g. a logo PNG)
                            // is still visible, the way the admin panel shows it.
                            Container(color: const Color(0xFF0C312B)),
                            (cat['image'] ?? '').isEmpty
                                ? const SizedBox.shrink()
                                : CachedNetworkImage(
                                    imageUrl: cat['image']!,
                                    fit: BoxFit.cover,
                                    memCacheWidth: 800,
                                    maxWidthDiskCache: 1200,
                                    fadeInDuration: const Duration(
                                      milliseconds: 200,
                                    ),
                                    placeholder: (context, url) =>
                                        Container(color: Colors.black12),
                                    errorWidget: (context, url, error) =>
                                        Container(color: Colors.black12),
                                  ),
                            Container(
                              decoration: BoxDecoration(
                                gradient: LinearGradient(
                                  begin: Alignment.bottomCenter,
                                  end: Alignment.center,
                                  colors: [
                                    Colors.black.withOpacity(0.7),
                                    Colors.transparent,
                                  ],
                                ),
                              ),
                              // Web parity: title bottom-left, wide tracking.
                              padding: const EdgeInsets.fromLTRB(
                                24,
                                24,
                                16,
                                28,
                              ),
                              alignment: Alignment.bottomLeft,
                              child: Text(
                                cat['title']!,
                                style: GoogleFonts.gelasio(
                                  fontSize: 10,
                                  fontWeight: FontWeight.w700,
                                  color: Colors.white,
                                  letterSpacing: 2.5,
                                  height: 1.3,
                                ),
                              ),
                            ),
                          ],
                        ),
                      ),
                    )
                    .animate()
                    .fadeIn(delay: (150 * index).ms)
                    .scale(begin: const Offset(0.9, 0.9));
              }, childCount: _categories.length),
            ),
          ),

          // Final Space
          const SliverToBoxAdapter(child: SizedBox(height: 100)),
        ],
      ),
    );
  }
}

class _HeaderCircleAction extends StatelessWidget {
  final IconData icon;
  final VoidCallback onTap;

  const _HeaderCircleAction({required this.icon, required this.onTap});

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    return GestureDetector(
      onTap: onTap,
      child: Container(
        width: 36,
        height: 36,
        decoration: BoxDecoration(
          color: isDark
              ? Colors.white.withOpacity(0.1)
              : const Color(0xFFF4EFE3),
          shape: BoxShape.circle,
          border: Border.all(
            color: (isDark ? Colors.white : const Color(0xFF0C312B))
                .withOpacity(0.05),
          ),
          boxShadow: [
            BoxShadow(
              color: Colors.black.withOpacity(0.05),
              blurRadius: 10,
              offset: const Offset(0, 4),
            ),
          ],
        ),
        child: Icon(
          icon,
          color: isDark ? Colors.white : const Color(0xFF0C312B),
          size: 18,
        ),
      ),
    );
  }
}
