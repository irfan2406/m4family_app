import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:m4_mobile/core/theme/app_theme.dart';
import 'package:m4_mobile/presentation/providers/project_provider.dart';
import 'package:flutter_animate/flutter_animate.dart';
import 'package:lucide_icons/lucide_icons.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:m4_mobile/presentation/screens/projects/project_detail_screen.dart';
import 'package:m4_mobile/presentation/providers/auth_provider.dart';


class ProjectListScreen extends ConsumerWidget {
  const ProjectListScreen({super.key});

  void _showFilterBottomSheet(BuildContext context) {
    showModalBottomSheet(
      context: context,
      backgroundColor: M4Theme.surface,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(24)),
      ),
      builder: (context) {
        return Container(
          padding: const EdgeInsets.all(24),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                'FILTER PROJECTS',
                style: GoogleFonts.montserrat(
                  fontSize: 16,
                  fontWeight: FontWeight.w900,
                  color: Colors.white,
                  letterSpacing: 1,
                ),
              ),
              const SizedBox(height: 24),
              // Placeholder for future filter options (e.g., location, price)
              Text(
                'Filter options coming soon.',
                style: GoogleFonts.montserrat(
                  color: Colors.white70,
                ),
              ),
              const SizedBox(height: 48),
            ],
          ),
        );
      },
    );
  }

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final projectsAsync = ref.watch(projectsProvider);
    final filteredProjects = ref.watch(filteredProjectsProvider);
    final currentFilter = ref.watch(projectFilterProvider);
    final isGridView = ref.watch(projectLayoutProvider);

    final apiClient = ref.watch(apiClientProvider);

    return Scaffold(
      backgroundColor: M4Theme.background,
      body: SafeArea(
        child: Column(
          children: [
            // 🏷️ Custom Header
            Padding(
              padding: const EdgeInsets.fromLTRB(24, 20, 24, 20),
              child: Row(
                crossAxisAlignment: CrossAxisAlignment.start,
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        'DISCOVER',
                        style: GoogleFonts.montserrat(
                          fontSize: 10,
                          fontWeight: FontWeight.bold,
                          color: Colors.white54,
                          letterSpacing: 2,
                        ),
                      ),
                      Text(
                        'M4 PROJECTS',
                        style: GoogleFonts.montserrat(
                          fontSize: 24,
                          fontWeight: FontWeight.w900,
                          color: Colors.white,
                          letterSpacing: -1,
                        ),
                      ),
                    ],
                  ),
                  Row(
                    children: [
                      // Filter Icon
                      GestureDetector(
                        onTap: () => _showFilterBottomSheet(context),
                        child: Container(
                          padding: const EdgeInsets.all(8),
                          decoration: BoxDecoration(
                            color: Colors.white.withOpacity(0.05),
                            borderRadius: BorderRadius.circular(10),
                            border: Border.all(color: Colors.white10),
                          ),
                          child: const Icon(LucideIcons.slidersHorizontal, size: 16, color: Colors.white),
                        ),
                      ),
                      const SizedBox(width: 8),
                      // Grid/List Toggle Icon
                      GestureDetector(
                        onTap: () => ref.read(projectLayoutProvider.notifier).state = !isGridView,
                        child: Container(
                          padding: const EdgeInsets.all(8),
                          decoration: BoxDecoration(
                            color: isGridView ? Colors.white : Colors.white.withOpacity(0.05),
                            borderRadius: BorderRadius.circular(10),
                            border: isGridView ? null : Border.all(color: Colors.white10),
                          ),
                          child: Icon(
                            isGridView ? LucideIcons.layoutGrid : LucideIcons.list,
                            size: 16,
                            color: isGridView ? Colors.black : Colors.white,
                          ),
                        ),
                      ),
                    ],
                  ),
                ],
              ),
            ),

            // 🎛️ Pill Tabs
            Container(
              margin: const EdgeInsets.symmetric(horizontal: 24),
              height: 45,
              decoration: BoxDecoration(
                color: Colors.transparent,
                borderRadius: BorderRadius.circular(30),
                border: Border.all(color: Colors.white10),
              ),
              child: Row(
                children: ['Ongoing', 'Upcoming', 'Completed'].map((filter) {
                  final isSelected = currentFilter == filter;
                  return Expanded(
                    child: GestureDetector(
                      onTap: () => ref.read(projectFilterProvider.notifier).state = filter,
                      child: Container(
                        alignment: Alignment.center,
                        decoration: BoxDecoration(
                          color: isSelected ? Colors.white : Colors.transparent,
                          borderRadius: BorderRadius.circular(30),
                        ),
                        child: Text(
                          filter.toUpperCase(),
                          style: GoogleFonts.montserrat(
                            fontSize: 10,
                            fontWeight: isSelected ? FontWeight.w900 : FontWeight.bold,
                            color: isSelected ? Colors.black : Colors.white70,
                            letterSpacing: 1,
                          ),
                        ),
                      ),
                    ),
                  );
                }).toList(),
              ),
            ),

            const SizedBox(height: 24),

            // 🏙️ Project List
            Expanded(
              child: projectsAsync.when(
                data: (projects) => ListView.builder(
                  padding: const EdgeInsets.fromLTRB(24, 0, 24, 120), // Bottom padding for shell nav
                  itemCount: filteredProjects.length,
                  itemBuilder: (context, index) {
                    final project = filteredProjects[index];
                    final projectId = project['_id']?.toString() ?? '';
                    final imageUrl = apiClient.resolveUrl(project['heroImage']?.toString() ?? project['images']?[0]?.toString());
                    return GestureDetector(
                      onTap: () {
                        if (projectId.isNotEmpty) {
                          Navigator.push(
                            context,
                            MaterialPageRoute(
                              builder: (context) => ProjectDetailScreen(
                                projectId: projectId,
                                projectData: project,
                              ),
                            ),
                          );
                        }
                      },
                      child: isGridView
                          ? _ProjectGridItem(project: project, imageUrl: imageUrl)
                          : _ProjectListRowItem(project: project, imageUrl: imageUrl),
                    );
                  },
                ),
                loading: () => const Center(child: CircularProgressIndicator(color: M4Theme.premiumBlue)),
                error: (e, s) => Center(child: Text('Error: $e\n\nNo projects found.')),
              ),
            ),
          ],
        ),
      ),
    );
  }
}

// ==========================================
// LARGE GRID/FEED CARD (Default 'Grid' View)
// ==========================================
class _ProjectGridItem extends StatelessWidget {
  final dynamic project;
  final String imageUrl;
  const _ProjectGridItem({required this.project, required this.imageUrl});

  @override
  Widget build(BuildContext context) {
    return Container(
      margin: const EdgeInsets.only(bottom: 24),
      height: 480, // Premium tall aspect ratio
      decoration: BoxDecoration(
        color: M4Theme.surface,
        borderRadius: BorderRadius.circular(40),
        image: DecorationImage(
          image: NetworkImage(imageUrl),
          fit: BoxFit.cover,
        ),
      ),
      clipBehavior: Clip.antiAlias,
      child: Stack(
        children: [
          // Gradient Overlay
          Container(
            decoration: BoxDecoration(
              gradient: LinearGradient(
                begin: Alignment.topCenter,
                end: Alignment.bottomCenter,
                colors: [
                  Colors.black.withOpacity(0.3),
                  Colors.transparent,
                  Colors.black.withOpacity(0.9),
                ],
                stops: const [0.0, 0.5, 1.0],
              ),
            ),
          ),

          // Top Badges
          Positioned(
            top: 20,
            left: 20,
            right: 20,
            child: Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                _Badge(text: project['status']?.toUpperCase() ?? 'LIVE ESTATE'),
                const _Badge(text: 'ARTISTIC IMPRESSION'),
              ],
            ),
          ),

          // Bottom Content
          Positioned(
            bottom: 24,
            left: 24,
            right: 24,
            child: Row(
              crossAxisAlignment: CrossAxisAlignment.end,
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                // Title & Location
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        project['title'] ?? 'M4 PROJECT',
                        style: GoogleFonts.montserrat(
                          fontSize: 28,
                          fontWeight: FontWeight.w900,
                          color: Colors.white,
                          letterSpacing: -0.5,
                        ),
                        maxLines: 2,
                        overflow: TextOverflow.ellipsis,
                      ),
                      const SizedBox(height: 6),
                      Row(
                        children: [
                          const Icon(LucideIcons.mapPin, size: 14, color: Colors.white70),
                          const SizedBox(width: 4),
                          Expanded(
                            child: Text(
                              project['location']?['name'] ?? 'N/A',
                              style: GoogleFonts.montserrat(
                                fontSize: 13,
                                color: Colors.white70,
                                fontWeight: FontWeight.w600,
                                letterSpacing: 1,
                              ),
                              maxLines: 1,
                              overflow: TextOverflow.ellipsis,
                            ),
                          ),
                        ],
                      ),
                    ],
                  ),
                ),

                const SizedBox(width: 16),

                // Action Arrow Button
                Container(
                  padding: const EdgeInsets.all(16),
                  decoration: BoxDecoration(
                    color: Colors.black.withOpacity(0.5),
                    borderRadius: BorderRadius.circular(20),
                    border: Border.all(color: Colors.white.withOpacity(0.1)),
                  ),
                  child: const Icon(LucideIcons.arrowUpRight, color: Colors.white, size: 20),
                ),
              ],
            ),
          ),
        ],
      ),
    ).animate().fadeIn().slideY(begin: 0.05, end: 0);
  }
}

// ==========================================
// COMPACT ROW CARD ('List' View)
// ==========================================
class _ProjectListRowItem extends StatelessWidget {
  final dynamic project;
  final String imageUrl;
  const _ProjectListRowItem({required this.project, required this.imageUrl});

  @override
  Widget build(BuildContext context) {
    return Container(
      margin: const EdgeInsets.only(bottom: 16),
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: M4Theme.surface,
        borderRadius: BorderRadius.circular(24),
        border: Border.all(color: Colors.white.withOpacity(0.05)),
      ),
      child: Row(
        children: [
          // Left Thumbnail
          Container(
            width: 100,
            height: 100,
            decoration: BoxDecoration(
              borderRadius: BorderRadius.circular(16),
              image: DecorationImage(
                image: NetworkImage(imageUrl),
                fit: BoxFit.cover,
              ),
            ),
          ),
          const SizedBox(width: 16),
          // Right Content
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                _Badge(text: project['status']?.toUpperCase() ?? 'LIVE ESTATE'),
                const SizedBox(height: 8),
                Text(
                  project['title'] ?? 'M4 PROJECT',
                  style: GoogleFonts.montserrat(
                    fontSize: 16,
                    fontWeight: FontWeight.w900,
                    color: Colors.white,
                    letterSpacing: -0.5,
                  ),
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                ),
                const SizedBox(height: 4),
                Row(
                  children: [
                    const Icon(LucideIcons.mapPin, size: 12, color: Colors.white70),
                    const SizedBox(width: 4),
                    Expanded(
                      child: Text(
                        project['location']?['name'] ?? 'N/A',
                        style: GoogleFonts.montserrat(
                          fontSize: 11,
                          color: Colors.white70,
                          fontWeight: FontWeight.w600,
                        ),
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                      ),
                    ),
                  ],
                ),
              ],
            ),
          ),
          const SizedBox(width: 8),
          // Action button
          Container(
            padding: const EdgeInsets.all(10),
            decoration: BoxDecoration(
              color: Colors.white.withOpacity(0.05),
              borderRadius: BorderRadius.circular(12),
            ),
            child: const Icon(LucideIcons.chevronRight, color: Colors.white, size: 18),
          ),
        ],
      ),
    ).animate().fadeIn().slideX(begin: 0.1, end: 0);
  }
}

class _Badge extends StatelessWidget {
  final String text;
  const _Badge({required this.text});

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
      decoration: BoxDecoration(
        color: Colors.white.withOpacity(0.85),
        borderRadius: BorderRadius.circular(12),
      ),
      child: Text(
        text,
        style: GoogleFonts.montserrat(
          fontSize: 8,
          fontWeight: FontWeight.w900,
          color: Colors.black87,
          letterSpacing: 1.0,
        ),
      ),
    );
  }
}
