import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:lucide_icons/lucide_icons.dart';
import 'dart:ui';
import 'package:m4_mobile/core/theme/app_theme.dart';
import 'package:m4_mobile/presentation/widgets/main_shell.dart';
import 'package:m4_mobile/presentation/providers/communities_provider.dart';
import 'package:m4_mobile/presentation/providers/auth_provider.dart';
import 'package:m4_mobile/presentation/screens/communities/community_detail_screen.dart';

class CommunityListScreen extends ConsumerStatefulWidget {
  const CommunityListScreen({super.key});

  @override
  ConsumerState<CommunityListScreen> createState() => _CommunityListScreenState();
}

class _CommunityListScreenState extends ConsumerState<CommunityListScreen> {
  bool _isExpanded = false;

  @override
  void initState() {
    super.initState();
    Future.microtask(() => ref.read(communitiesProvider.notifier).fetchCommunities());
  }

  @override
  Widget build(BuildContext context) {
    final state = ref.watch(communitiesProvider);

    final isDark = Theme.of(context).brightness == Brightness.dark;
    return Scaffold(
      backgroundColor: Theme.of(context).scaffoldBackgroundColor,
      body: CustomScrollView(
        slivers: [
          // 🔝 Stage 1: Global Header
          SliverToBoxAdapter(
            child: Padding(
              padding: const EdgeInsets.fromLTRB(25, 60, 25, 30),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      // Back Button (Rounded Square Shell)
                      GestureDetector(
                        onTap: () => ref.read(navigationProvider.notifier).state = 0,
                        child: Container(
                          padding: const EdgeInsets.all(10),
                          decoration: BoxDecoration(
                            color: (isDark ? Colors.white : Colors.black).withOpacity(0.05),
                            borderRadius: BorderRadius.circular(12),
                            border: Border.all(color: (isDark ? Colors.white : Colors.black).withOpacity(0.1)),
                          ),
                          child: Icon(LucideIcons.arrowLeft, color: isDark ? Colors.white : Colors.black, size: 20),
                        ),
                      ),
                      // M4 Logo Placeholder
                      Column(
                        crossAxisAlignment: CrossAxisAlignment.end,
                        children: [
                          Text(
                            'M4 FAMILY',
                            style: GoogleFonts.montserrat(
                              color: isDark ? Colors.white : Colors.black,
                              fontSize: 14,
                              fontWeight: FontWeight.w900,
                              letterSpacing: 2,
                            ),
                          ),
                          Text(
                            'DEVELOPMENTS',
                            style: GoogleFonts.montserrat(
                              color: (isDark ? Colors.white : Colors.black).withOpacity(0.5),
                              fontSize: 8,
                              fontWeight: FontWeight.bold,
                              letterSpacing: 1,
                            ),
                          ),
                        ],
                      ),
                    ],
                  ),
                  const SizedBox(height: 50),
                  // Title: ABOUT THE COMMUNITIES (Outline/Large font)
                  Text(
                    'ABOUT THE',
                    style: GoogleFonts.montserrat(
                      fontSize: 42,
                      fontWeight: FontWeight.w300,
                      color: (isDark ? Colors.white : Colors.black).withOpacity(0.7),
                      height: 0.9,
                    ),
                  ),
                  Text(
                    'COMMUNITIES',
                    style: GoogleFonts.montserrat(
                      fontSize: 42,
                      fontWeight: FontWeight.w900,
                      color: isDark ? Colors.white : Colors.black,
                      height: 1.1,
                      letterSpacing: -1,
                    ),
                  ),
                  const SizedBox(height: 25),
                  Text(
                    _isExpanded 
                      ? 'At M4 Family Developments, we are dedicated to delivering a luxury experience that goes beyond the ordinary. Our commitment to exquisite living, unparalleled quality, and iconic design is evident in ...\n\nevery community we curate. We believe in creating spaces that faster connection, inspiration, and a sense of belonging for every resident. Our developments are strategically located to offer the best of urban living with a touch of serenity.'
                      : 'At M4 Family Developments, we are dedicated to delivering a luxury experience that goes beyond the ordinary. Our commitment to exquisite living, unparalleled quality, and iconic design is evident in ...',
                    style: GoogleFonts.montserrat(
                      color: (isDark ? Colors.white : Colors.black).withOpacity(0.5),
                      fontSize: 13,
                      height: 1.6,
                    ),
                  ),
                  const SizedBox(height: 15),
                  GestureDetector(
                    onTap: () {
                      setState(() {
                        _isExpanded = !_isExpanded;
                      });
                    },
                    child: Text(
                      _isExpanded ? 'Read less' : 'Read more',
                      style: GoogleFonts.montserrat(
                        color: isDark ? Colors.white : Colors.black,
                        fontSize: 13,
                        fontWeight: FontWeight.w900,
                        decoration: TextDecoration.underline,
                      ),
                    ),
                  ),
                ],
              ),
            ),
          ),

          // 🏗️ Stage 2: Community Cards
          if (state.isLoading)
            const SliverToBoxAdapter(
              child: Center(
                child: Padding(
                  padding: EdgeInsets.all(40.0),
                  child: CircularProgressIndicator(color: Colors.white24),
                ),
              ),
            )
          else if (state.error != null)
             SliverToBoxAdapter(
              child: Center(
                child: Padding(
                  padding: const EdgeInsets.all(40.0),
                  child: Text(state.error!, style: const TextStyle(color: Colors.white38)),
                ),
              ),
            )
          else
            SliverPadding(
              padding: const EdgeInsets.symmetric(horizontal: 20),
              sliver: SliverList(
                delegate: SliverChildBuilderDelegate(
                  (context, index) {
                    final community = state.communities[index];
                    return _CommunityCard(community: community);
                  },
                  childCount: state.communities.length,
                ),
              ),
            ),
          
          const SliverToBoxAdapter(child: SizedBox(height: 120)),
        ],
      ),
    );
  }
}

class _CommunityCard extends ConsumerWidget {
  final dynamic community;
  const _CommunityCard({required this.community});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final apiClient = ref.watch(apiClientProvider);
    final imageUrl = apiClient.resolveUrl(community['image'] ?? community['imageUrl']);

    return GestureDetector(
      onTap: () => Navigator.push(
        context,
        MaterialPageRoute(
          builder: (context) => CommunityDetailScreen(community: community),
        ),
      ),
      child: Container(
        height: 320,
        margin: const EdgeInsets.only(bottom: 25),
        decoration: BoxDecoration(
          borderRadius: BorderRadius.circular(40),
          image: DecorationImage(
            image: NetworkImage(imageUrl),
            fit: BoxFit.cover,
          ),
        ),
        child: Stack(
          children: [
            // Gradient Overlay
            Container(
              decoration: BoxDecoration(
                borderRadius: BorderRadius.circular(40),
                gradient: LinearGradient(
                  begin: Alignment.topCenter,
                  end: Alignment.bottomCenter,
                  colors: [
                    Colors.transparent,
                    Colors.black.withOpacity(0.8),
                  ],
                  stops: const [0.5, 1.0],
                ),
              ),
            ),
            // Content
            Padding(
              padding: const EdgeInsets.all(30),
              child: Column(
                mainAxisAlignment: MainAxisAlignment.end,
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    community['title']?.toString().toUpperCase() ?? 'COMMUNITY',
                    style: GoogleFonts.montserrat(
                      fontSize: 28,
                      fontWeight: FontWeight.bold,
                      color: Colors.white,
                    ),
                  ),
                  const SizedBox(height: 8),
                  Row(
                    crossAxisAlignment: CrossAxisAlignment.end,
                    children: [
                      Expanded(
                        child: Text(
                          community['description'] ?? '',
                          maxLines: 2,
                          overflow: TextOverflow.ellipsis,
                          style: GoogleFonts.montserrat(
                            fontSize: 11,
                            color: Colors.white70,
                            height: 1.5,
                          ),
                        ),
                      ),
                      const SizedBox(width: 20),
                      // Action Arrow Button (Rounded Square Shell)
                      GestureDetector(
                        onTap: () => Navigator.push(
                          context,
                          MaterialPageRoute(
                            builder: (context) => CommunityDetailScreen(community: community),
                          ),
                        ),
                        child: Container(
                          padding: const EdgeInsets.all(12),
                          decoration: BoxDecoration(
                            color: Colors.white,
                            borderRadius: BorderRadius.circular(15),
                          ),
                          child: const Icon(LucideIcons.arrowRight, color: Colors.black, size: 20),
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
    );
  }
}
