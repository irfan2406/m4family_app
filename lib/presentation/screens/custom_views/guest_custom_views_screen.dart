import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:google_fonts/google_fonts.dart';
import 'dart:ui';
import 'package:lucide_icons/lucide_icons.dart';
import 'package:flutter_animate/flutter_animate.dart';
import 'package:m4_mobile/presentation/widgets/conditional_drawer.dart';
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

  final List<Map<String, String>> _categories = [
    {
      'title': 'EXPANSIVE LIVING',
      'image':
          'https://images.unsplash.com/photo-1600210492486-724fe5c67fb0?auto=format&fit=crop&q=80',
    },
    {
      'title': 'MASTER SUITES',
      'image':
          'https://images.unsplash.com/photo-1556911220-e15b29be8c8f?auto=format&fit=crop&q=80',
    },
    {
      'title': 'PRIVATE TERRACES',
      'image':
          'https://images.unsplash.com/photo-1512917774080-9991f1c4c750?auto=format&fit=crop&q=80',
    },
    {
      'title': 'ELITE SPA BATHROOMS',
      'image':
          'https://images.unsplash.com/photo-1552321554-5fefe8c9ef14?auto=format&fit=crop&q=80',
    },
  ];

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;

    return Scaffold(
      backgroundColor: isDark ? Colors.black : Colors.white,
      drawer: const ConditionalDrawer(),
      body: CustomScrollView(
        controller: _scrollController,
        slivers: [
          // 🔝 Premium Header
          SliverAppBar(
            pinned: true,
            backgroundColor: (isDark ? Colors.black : Colors.white).withOpacity(
              0.8,
            ),
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
                  style: GoogleFonts.montserrat(
                    color: isDark ? Colors.white : Colors.black,
                    fontWeight: FontWeight.w900,
                    fontSize: 14,
                    letterSpacing: 0.5,
                  ),
                ),
                Text(
                  'M4 CUSTOM SHOWCASE',
                  style: GoogleFonts.montserrat(
                    color: (isDark ? Colors.white : Colors.black).withOpacity(
                      0.5,
                    ),
                    fontWeight: FontWeight.w900,
                    fontSize: 7,
                    letterSpacing: 1.5,
                  ),
                ),
              ],
            ),
            actions: [
              Builder(
                builder: (context) => GestureDetector(
                  onTap: () => Scaffold.of(context).openDrawer(),
                  child: Container(
                    margin: const EdgeInsets.only(
                      right: 16,
                      top: 20,
                      bottom: 20,
                    ),
                    padding: const EdgeInsets.symmetric(horizontal: 14),
                    decoration: BoxDecoration(
                      color: isDark ? Colors.white : Colors.black,
                      borderRadius: BorderRadius.circular(20),
                    ),
                    child: Icon(
                      LucideIcons.moreHorizontal,
                      color: isDark ? Colors.black : Colors.white,
                      size: 18,
                    ),
                  ),
                ),
              ),
            ],
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
                        style: GoogleFonts.dmSerifDisplay(
                          color: isDark ? Colors.white : Colors.black,
                          fontSize: 52,
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
                    color: (isDark ? Colors.white : Colors.black).withOpacity(
                      0.2,
                    ),
                  ),
                  const SizedBox(height: 48),
                  Text(
                    'Experience the future of home personalisation. Our proprietary Custom Views suite allows you to visualise and craft your dream space before it\'s even built. Every M4 residence is a bespoke masterpiece, where your vision dictates the architecture of luxury. Beyond standard configurations, we offer a multi-sensory design experience—from haptic material selection to precision spatial planning. Our suite ensures that your digital blueprint translates into a tangible sanctuary of unparalleled refinement.',
                    textAlign: TextAlign.center,
                    style: GoogleFonts.montserrat(
                      color: (isDark ? Colors.white : Colors.black).withOpacity(
                        0.7,
                      ),
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
              // Web parity: aspect-[1/1.1] rounded-[3rem] cards (rounded
              // rectangles, not tall ovals).
              gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
                crossAxisCount: 2,
                mainAxisSpacing: 25,
                crossAxisSpacing: 25,
                childAspectRatio: 0.9,
              ),
              delegate: SliverChildBuilderDelegate((context, index) {
                final cat = _categories[index];
                return Container(
                      decoration: BoxDecoration(
                        borderRadius: BorderRadius.circular(44),
                        boxShadow: [
                          BoxShadow(
                            color: (isDark ? Colors.white : Colors.black)
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
                            CachedNetworkImage(
                              imageUrl: cat['image']!,
                              fit: BoxFit.cover,
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
                                style: GoogleFonts.montserrat(
                                  fontSize: 10,
                                  fontWeight: FontWeight.w900,
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
          color: isDark ? Colors.white.withOpacity(0.1) : Colors.white,
          shape: BoxShape.circle,
          border: Border.all(
            color: (isDark ? Colors.white : Colors.black).withOpacity(0.05),
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
          color: isDark ? Colors.white : Colors.black,
          size: 18,
        ),
      ),
    );
  }
}
