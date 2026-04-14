import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:m4_mobile/core/theme/app_theme.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:lucide_icons/lucide_icons.dart';
import 'package:flutter_animate/flutter_animate.dart';
import 'package:m4_mobile/presentation/widgets/conditional_drawer.dart';
import 'package:m4_mobile/presentation/providers/auth_provider.dart';
import 'package:m4_mobile/core/network/api_client.dart';
import 'package:cached_network_image/cached_network_image.dart';

class GuestCustomViewsScreen extends ConsumerStatefulWidget {
  const GuestCustomViewsScreen({super.key});

  @override
  ConsumerState<GuestCustomViewsScreen> createState() => _GuestCustomViewsScreenState();
}

class _GuestCustomViewsScreenState extends ConsumerState<GuestCustomViewsScreen> {
  final ScrollController _scrollController = ScrollController();

  final List<Map<String, String>> _categories = [
    {
      'title': 'EXPANSIVE LIVING',
      'image': 'https://images.unsplash.com/photo-1600210492486-724fe5c67fb0?auto=format&fit=crop&q=80',
    },
    {
      'title': 'MASTER SUITES',
      'image': 'https://images.unsplash.com/photo-1556911220-e15b29be8c8f?auto=format&fit=crop&q=80',
    },
    {
      'title': 'PRIVATE TERRACES',
      'image': 'https://images.unsplash.com/photo-1512917774080-9991f1c4c750?auto=format&fit=crop&q=80',
    },
    {
      'title': 'ELITE SPA BATHROOMS',
      'image': 'https://images.unsplash.com/photo-1552321554-5fefe8c9ef14?auto=format&fit=crop&q=80',
    },
    {
      'title': 'GOURMET KITCHENS',
      'image': 'https://images.unsplash.com/photo-1556912172-45b7abe8b7e1?auto=format&fit=crop&q=80',
    },
    {
      'title': 'CINEMATIC LOUNGES',
      'image': 'https://images.unsplash.com/photo-1593914621423-47c992d99991?auto=format&fit=crop&q=80',
    },
    {
      'title': 'PERSONAL GALLERIES',
      'image': 'https://images.unsplash.com/photo-1600607687939-ce8a6c25118c?auto=format&fit=crop&q=80',
    },
    {
      'title': 'OFFICE SUITES',
      'image': 'https://images.unsplash.com/photo-1600585154340-be6161a56a0c?auto=format&fit=crop&q=80',
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
          // 🔝 Sticky Header
          SliverToBoxAdapter(
            child: Container(
              padding: const EdgeInsets.fromLTRB(25, 60, 15, 20),
              child: Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  GestureDetector(
                    onTap: () => Navigator.pop(context),
                    child: Container(
                      width: 45,
                      height: 45,
                      decoration: BoxDecoration(
                        shape: BoxShape.circle,
                        color: (isDark ? Colors.white : Colors.black).withOpacity(0.05),
                        border: Border.all(color: (isDark ? Colors.white : Colors.black).withOpacity(0.1)),
                      ),
                      child: Icon(LucideIcons.chevronLeft, color: isDark ? Colors.white : Colors.black, size: 20),
                    ),
                  ),
                  Row(
                    children: [
                      Column(
                        crossAxisAlignment: CrossAxisAlignment.end,
                        children: [
                          Text(
                            'INTERACTIVE LIVING',
                            style: GoogleFonts.montserrat(
                              color: isDark ? Colors.white : Colors.black,
                              fontSize: 14,
                              fontWeight: FontWeight.w900,
                              letterSpacing: 0,
                            ),
                          ),
                          Text(
                            'M4 CUSTOM SHOWCASE',
                            style: GoogleFonts.montserrat(
                              color: (isDark ? Colors.white : Colors.black).withOpacity(0.5),
                              fontSize: 8,
                              fontWeight: FontWeight.bold,
                              letterSpacing: 2,
                            ),
                          ),
                        ],
                      ),
                      const SizedBox(width: 8),
                      Builder(
                        builder: (context) => IconButton(
                          icon: Icon(LucideIcons.moreHorizontal, color: isDark ? Colors.white : Colors.black, size: 28),
                          onPressed: () => Scaffold.of(context).openDrawer(),
                        ),
                      ),
                    ],
                  ),
                ],
              ),
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
                    style: GoogleFonts.dmSerifDisplay(
                      color: isDark ? Colors.white : Colors.black,
                      fontSize: 52,
                      height: 1.1,
                      letterSpacing: -1,
                    ),
                  ).animate().fadeIn(duration: 800.ms).slideY(begin: 0.2, end: 0),
                  const SizedBox(height: 32),
                  Container(
                    width: 50,
                    height: 1.5,
                    color: (isDark ? Colors.white : Colors.black).withOpacity(0.2),
                  ),
                  const SizedBox(height: 48),
                  Text(
                    'Experience the future of home personalisation. Our proprietary Custom Views suite allows you to visualise and craft your dream space before it\'s even built. Every M4 residence is a bespoke masterpiece, where your vision dictates the architecture of luxury. Beyond standard configurations, we offer a multi-sensory design experience—from haptic material selection to precision spatial planning. Our suite ensures that your digital blueprint translates into a tangible sanctuary of unparalleled refinement.',
                    textAlign: TextAlign.center,
                    style: GoogleFonts.montserrat(
                      color: (isDark ? Colors.white : Colors.black).withOpacity(0.7),
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
              gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
                crossAxisCount: 2,
                mainAxisSpacing: 25,
                crossAxisSpacing: 25,
                childAspectRatio: 0.8,
              ),
              delegate: SliverChildBuilderDelegate(
                (context, index) {
                  final cat = _categories[index];
                  return Container(
                    decoration: BoxDecoration(
                      borderRadius: BorderRadius.circular(100),
                      boxShadow: [
                        BoxShadow(
                          color: (isDark ? Colors.white : Colors.black).withOpacity(0.08),
                          blurRadius: 25,
                          offset: const Offset(0, 10),
                        )
                      ],
                    ),
                    child: ClipRRect(
                      borderRadius: BorderRadius.circular(100),
                      child: Stack(
                        fit: StackFit.expand,
                        children: [
                          CachedNetworkImage(
                            imageUrl: cat['image']!,
                            fit: BoxFit.cover,
                            placeholder: (context, url) => Container(color: Colors.black12),
                            errorWidget: (context, url, error) => Container(color: Colors.black12),
                          ),
                          Container(
                            decoration: BoxDecoration(
                              gradient: LinearGradient(
                                begin: Alignment.bottomCenter,
                                end: Alignment.topCenter,
                                colors: [
                                  Colors.black.withOpacity(0.6),
                                  Colors.transparent,
                                  Colors.transparent,
                                ],
                              ),
                            ),
                            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 24),
                            alignment: Alignment.center,
                            child: Text(
                              cat['title']!,
                              textAlign: TextAlign.center,
                              style: GoogleFonts.montserrat(
                                fontSize: 10,
                                fontWeight: FontWeight.w900,
                                color: Colors.white,
                                letterSpacing: 1.5,
                                height: 1.2,
                              ),
                            ),
                          ),
                        ],
                      ),
                    ),
                  ).animate().fadeIn(delay: (150 * index).ms).scale(begin: const Offset(0.9, 0.9));
                },
                childCount: _categories.length,
              ),
            ),
          ),

          // Final Space
          const SliverToBoxAdapter(
            child: SizedBox(height: 100),
          ),
        ],
      ),
    );
  }
}
