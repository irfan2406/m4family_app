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
      backgroundColor: Colors.black,
      body: CustomScrollView(
        slivers: [
          // 🔝 Header (Logo & Back)
          SliverToBoxAdapter(
            child: Container(
              padding: const EdgeInsets.fromLTRB(25, 60, 25, 20),
              child: Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                   GestureDetector(
                    onTap: () {
                       if (Navigator.canPop(context)) {
                        Navigator.pop(context);
                      } else {
                        ref.read(navigationProvider.notifier).state = 0;
                      }
                    },
                    child: Container(
                      width: 45,
                      height: 45,
                      decoration: BoxDecoration(
                        shape: BoxShape.circle,
                        color: Colors.white.withOpacity(0.05),
                        border: Border.all(color: Colors.white.withOpacity(0.1)),
                      ),
                      child: const Icon(LucideIcons.chevronLeft, color: Colors.white, size: 20),
                    ),
                  ),
                  Column(
                    crossAxisAlignment: CrossAxisAlignment.end,
                    children: [
                      Text(
                        'M4 FAMILY',
                        style: GoogleFonts.inter(
                          color: Colors.white,
                          fontSize: 18,
                          fontWeight: FontWeight.w900,
                          letterSpacing: -1,
                        ),
                      ),
                      Text(
                        'DEVELOPMENTS',
                        style: GoogleFonts.inter(
                          color: Colors.white.withOpacity(0.5),
                          fontSize: 8,
                          fontWeight: FontWeight.bold,
                          letterSpacing: 3,
                        ),
                      ),
                    ],
                  ),
                ],
              ),
            ),
          ),

          // 🏗️ Intro Section
          SliverToBoxAdapter(
            child: Padding(
              padding: const EdgeInsets.symmetric(horizontal: 25, vertical: 20),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    'ABOUT THE',
                    style: GoogleFonts.lora(
                      fontSize: 32,
                      fontWeight: FontWeight.w300,
                      color: Colors.white.withOpacity(0.7),
                      height: 1,
                    ),
                  ),
                  Text(
                    'COMMUNITIES',
                    style: GoogleFonts.lora(
                      fontSize: 32,
                      fontWeight: FontWeight.w600,
                      color: Colors.white,
                      height: 1,
                    ),
                  ),
                  const SizedBox(height: 30),
                  AnimatedCrossFade(
                    duration: const Duration(milliseconds: 300),
                    crossFadeState: _isExpanded ? CrossFadeState.showSecond : CrossFadeState.showFirst,
                    firstChild: Text(
                      'At M4 Family Developments, we are dedicated to delivering a luxury experience that goes beyond the ordinary. Our commitment to exquisite living, unparalleled quality, and iconic design is evident in ...',
                      style: GoogleFonts.lora(
                        color: Colors.white.withOpacity(0.6),
                        fontSize: 14,
                        height: 1.8,
                        fontWeight: FontWeight.w500,
                      ),
                    ),
                    secondChild: Text(
                      'At M4 Family Developments, we are dedicated to delivering a luxury experience that goes beyond the ordinary. Our commitment to exquisite living, unparalleled quality, and iconic design is evident in every community we curate. We believe in creating spaces that faster connection, inspiration, and a sense of belonging for every resident. Our developments are strategically located to offer the best of urban living with a touch of serenity.',
                      style: GoogleFonts.lora(
                        color: Colors.white.withOpacity(0.6),
                        fontSize: 14,
                        height: 1.8,
                        fontWeight: FontWeight.w500,
                      ),
                    ),
                  ),
                  const SizedBox(height: 10),
                  GestureDetector(
                    onTap: () => setState(() => _isExpanded = !_isExpanded),
                    child: Container(
                      padding: const EdgeInsets.only(bottom: 2),
                      decoration: BoxDecoration(
                        border: Border(bottom: BorderSide(color: Colors.white.withOpacity(0.2), width: 1)),
                      ),
                      child: Text(
                        _isExpanded ? 'Read less' : 'Read more',
                        style: GoogleFonts.inter(
                          color: Colors.white,
                          fontSize: 13,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                    ),
                  ),
                ],
              ),
            ),
          ),

          // 🏗️ Grid of Communities
          if (state.isLoading)
            const SliverToBoxAdapter(
              child: Center(
                child: Padding(
                  padding: EdgeInsets.all(100.0),
                  child: CircularProgressIndicator(color: Colors.white),
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
              padding: const EdgeInsets.fromLTRB(25, 20, 25, 100),
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
        height: 350,
        margin: const EdgeInsets.only(bottom: 30),
        decoration: BoxDecoration(
          borderRadius: BorderRadius.circular(50),
          boxShadow: [
            BoxShadow(
              color: Colors.black.withOpacity(0.3),
              blurRadius: 20,
              offset: const Offset(0, 10),
            ),
          ],
        ),
        clipBehavior: Clip.antiAlias,
        child: Stack(
          children: [
            Positioned.fill(
              child: Image.network(
                imageUrl,
                fit: BoxFit.cover,
              ),
            ),
            // Gradient
            Positioned.fill(
              child: Container(
                decoration: BoxDecoration(
                  gradient: LinearGradient(
                    begin: Alignment.topCenter,
                    end: Alignment.bottomCenter,
                    colors: [
                      Colors.transparent,
                      Colors.black.withOpacity(0.2),
                      Colors.black.withOpacity(0.8),
                    ],
                  ),
                ),
              ),
            ),
            // Content
            Positioned(
              bottom: 40,
              left: 30,
              right: 30,
              child: Row(
                crossAxisAlignment: CrossAxisAlignment.end,
                children: [
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          community['title']?.toString() ?? 'COMMUNITY',
                          style: GoogleFonts.lora(
                            fontSize: 28,
                            fontWeight: FontWeight.w400,
                            color: Colors.white,
                            letterSpacing: -0.5,
                          ),
                        ),
                        const SizedBox(height: 8),
                        Text(
                          community['subtitle'] ?? community['description'] ?? '',
                          maxLines: 2,
                          overflow: TextOverflow.ellipsis,
                          style: GoogleFonts.inter(
                            fontSize: 12,
                            color: Colors.white.withOpacity(0.6),
                            height: 1.5,
                            fontWeight: FontWeight.w500,
                          ),
                        ),
                      ],
                    ),
                  ),
                  const SizedBox(width: 15),
                  Container(
                    width: 55,
                    height: 55,
                    decoration: BoxDecoration(
                      color: Colors.white,
                      borderRadius: BorderRadius.circular(20),
                      boxShadow: [
                        BoxShadow(
                          color: Colors.black.withOpacity(0.2),
                          blurRadius: 10,
                        ),
                      ],
                    ),
                    child: const Icon(LucideIcons.arrowRight, color: Colors.black, size: 24),
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
