import 'package:flutter/material.dart';
import 'package:cached_network_image/cached_network_image.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:m4_mobile/core/theme/app_theme.dart';
import 'package:m4_mobile/presentation/providers/project_provider.dart';
import 'package:flutter_animate/flutter_animate.dart';
import 'package:lucide_icons/lucide_icons.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:m4_mobile/presentation/screens/projects/project_detail_screen.dart';
import 'package:m4_mobile/presentation/providers/auth_provider.dart';
import 'package:m4_mobile/presentation/widgets/main_shell.dart';
import 'package:m4_mobile/presentation/widgets/guest_main_shell.dart';
import 'package:m4_mobile/presentation/screens/projects/guest_project_detail_screen.dart';


class ProjectListScreen extends ConsumerWidget {
  const ProjectListScreen({super.key});

  void _showFilterBottomSheet(BuildContext context, WidgetRef ref) {
    final locations = ref.read(projectLocationsProvider);
    final categories = ref.read(projectCategoriesProvider);
    final selectedLocs = ref.watch(selectedLocationsProvider);
    final selectedBudgets = ref.watch(selectedBudgetsProvider);
    final selectedTypes = ref.watch(selectedTypesProvider);

    final budgetOptions = ["< 5 Cr", "5 - 10 Cr", "10 - 20 Cr", "20 Cr +"];

    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (context) {
        return StatefulBuilder(
          builder: (context, setModalState) {
            return Container(
              height: MediaQuery.of(context).size.height * 0.85,
              decoration: BoxDecoration(
                color: Theme.of(context).colorScheme.surface,
                borderRadius: const BorderRadius.vertical(top: Radius.circular(40)),
              ),
              child: Column(
                children: [
                  const SizedBox(height: 12),
                  Container(width: 40, height: 4, decoration: BoxDecoration(color: Theme.of(context).colorScheme.onSurface.withOpacity(0.1), borderRadius: BorderRadius.circular(2))),
                  const SizedBox(height: 24),
                  Padding(
                    padding: const EdgeInsets.symmetric(horizontal: 24),
                    child: Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        Text('REFINE SEARCH', style: GoogleFonts.montserrat(fontSize: 20, fontWeight: FontWeight.bold, color: Theme.of(context).colorScheme.onSurface, letterSpacing: -0.5)),
                        IconButton(
                          onPressed: () => Navigator.pop(context),
                          icon: Icon(LucideIcons.x, color: Theme.of(context).colorScheme.onSurface),
                          style: IconButton.styleFrom(backgroundColor: Theme.of(context).colorScheme.onSurface.withOpacity(0.05), shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12))),
                        ),
                      ],
                    ),
                  ),
                  const SizedBox(height: 32),
                  Expanded(
                    child: ListView(
                      padding: const EdgeInsets.symmetric(horizontal: 24),
                      children: [
                        _FilterSection(
                          title: 'LOCATION',
                          options: locations,
                          selectedOptions: selectedLocs,
                          onToggle: (val) {
                            final current = List<String>.from(ref.read(selectedLocationsProvider));
                            if (current.contains(val)) current.remove(val); else current.add(val);
                            ref.read(selectedLocationsProvider.notifier).state = current;
                            setModalState(() {});
                          },
                        ),
                        const SizedBox(height: 32),
                        _FilterSection(
                          title: 'BUDGET RANGE',
                          options: budgetOptions,
                          selectedOptions: selectedBudgets,
                          onToggle: (val) {
                            final current = List<String>.from(ref.read(selectedBudgetsProvider));
                            if (current.contains(val)) current.remove(val); else current.add(val);
                            ref.read(selectedBudgetsProvider.notifier).state = current;
                            setModalState(() {});
                          },
                        ),
                        const SizedBox(height: 32),
                        _FilterSection(
                          title: 'PROPERTY TYPE',
                          options: categories,
                          selectedOptions: selectedTypes,
                          onToggle: (val) {
                            final current = List<String>.from(ref.read(selectedTypesProvider));
                            if (current.contains(val)) current.remove(val); else current.add(val);
                            ref.read(selectedTypesProvider.notifier).state = current;
                            setModalState(() {});
                          },
                        ),
                        const SizedBox(height: 48),
                      ],
                    ),
                  ),
                  Padding(
                    padding: const EdgeInsets.fromLTRB(24, 0, 24, 48),
                    child: SizedBox(
                      width: double.infinity,
                      height: 64,
                      child: ElevatedButton(
                        onPressed: () => Navigator.pop(context),
                        style: ElevatedButton.styleFrom(
                          backgroundColor: Colors.black,
                          foregroundColor: Colors.white,
                          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
                          elevation: 0,
                        ),
                        child: Text(
                          'APPLY SEARCH MATRIX',
                          style: GoogleFonts.montserrat(
                            fontSize: 12, 
                            fontWeight: FontWeight.w900, 
                            color: Theme.of(context).brightness == Brightness.dark ? Colors.black : Colors.white,
                            letterSpacing: 1
                          ),
                        ),
                      ),
                    ),
                  ),
                ],
              ),
            );
          }
        );
      },
    );
  }

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final projectsAsync = ref.watch(projectsProvider);
    final filteredProjects = ref.watch(filteredProjectsProvider);
    final currentFilter = ref.watch(projectFilterProvider);
    final isGridView = ref.watch(projectLayoutProvider);

    final apiClient = ref.watch(apiClientProvider);

    return Scaffold(
      backgroundColor: Theme.of(context).scaffoldBackgroundColor,
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
                  Row(
                    children: [
                      InkWell(
                        onTap: () {
                          if (Navigator.canPop(context)) {
                            Navigator.pop(context);
                          }
                          ref.read(navigationProvider.notifier).state = 0;
                          ref.read(guestNavigationProvider.notifier).state = 0;
                        },
                        borderRadius: BorderRadius.circular(12),
                        child: Padding(
                          padding: const EdgeInsets.all(8.0),
                          child: Icon(LucideIcons.arrowLeft, color: Theme.of(context).colorScheme.onSurface, size: 24),
                        ),
                      ),
                      const SizedBox(width: 16),
                      Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            'DISCOVER',
                            style: GoogleFonts.montserrat(
                              fontSize: 10,
                              fontWeight: FontWeight.w400,
                              color: Theme.of(context).colorScheme.onSurface.withOpacity(0.55),
                              letterSpacing: 3,
                            ),
                          ),
                          Text(
                            'M4 PROJECTS',
                            style: GoogleFonts.montserrat(
                              fontSize: 24,
                              fontWeight: FontWeight.w400,
                              color: Theme.of(context).colorScheme.onSurface,
                              letterSpacing: -1,
                            ),
                          ),
                          const SizedBox(height: 4),
                          Text(
                            '${filteredProjects.length} PROPERTIES AVAILABLE',
                            style: GoogleFonts.montserrat(
                              fontSize: 10,
                              fontWeight: FontWeight.w500,
                              color: M4Theme.premiumBlue,
                              letterSpacing: 1.5,
                            ),
                          ),
                        ],
                      ),
                    ],
                  ),
                  Row(
                    children: [
                      // Filter Icon
                      GestureDetector(
                        onTap: () => _showFilterBottomSheet(context, ref),
                        child: Container(
                          padding: const EdgeInsets.all(8),
                          decoration: BoxDecoration(
                            color: (isDark ? Colors.white : Colors.black).withOpacity(0.05),
                            borderRadius: BorderRadius.circular(10),
                            border: Border.all(color: (isDark ? Colors.white : Colors.black).withOpacity(0.05)),
                          ),
                          child: Icon(LucideIcons.slidersHorizontal, size: 16, color: Theme.of(context).colorScheme.onSurface),
                        ),
                      ),
                      const SizedBox(width: 8),
                      // Grid/List Toggle Icon
                      GestureDetector(
                        onTap: () => ref.read(projectLayoutProvider.notifier).state = !isGridView,
                        child: Container(
                          padding: const EdgeInsets.all(8),
                          decoration: BoxDecoration(
                            color: isGridView ? (isDark ? Colors.white : Colors.black) : (isDark ? Colors.white : Colors.black).withOpacity(0.05),
                            borderRadius: BorderRadius.circular(10),
                            border: isGridView ? null : Border.all(color: (isDark ? Colors.white : Colors.black).withOpacity(0.1)),
                          ),
                          child: Icon(
                            isGridView ? LucideIcons.layoutGrid : LucideIcons.list,
                            size: 16,
                            color: isGridView 
                                ? (isDark ? Colors.black : Colors.white)
                                : (isDark ? Colors.white : Colors.black),
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
                border: Border.all(color: Theme.of(context).colorScheme.onSurface.withOpacity(0.08)),
              ),
              child: Row(
                children: ['Ongoing', 'Upcoming', 'Completed'].map((filter) {
                  final isSelected = currentFilter == filter;
                  return Expanded(
                    child: GestureDetector(
                      onTap: () => ref.read(projectFilterProvider.notifier).state = filter,
                      child: AnimatedContainer(
                        duration: const Duration(milliseconds: 300),
                        curve: Curves.easeInOut,
                        alignment: Alignment.center,
                        decoration: BoxDecoration(
                          color: isSelected 
                              ? (Theme.of(context).brightness == Brightness.dark ? Colors.white : Colors.black)
                              : Colors.transparent,
                          borderRadius: BorderRadius.circular(30),
                        ),
                        child: Text(
                          filter.toUpperCase(),
                          style: GoogleFonts.montserrat(
                            fontSize: 10,
                            fontWeight: isSelected ? FontWeight.w900 : FontWeight.bold,
                            color: isSelected 
                                ? (Theme.of(context).brightness == Brightness.dark ? Colors.black : Colors.white)
                                : Theme.of(context).colorScheme.onSurface.withOpacity(0.35),
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
                    final images = project['images'] as List?;
                    final imageUrl = apiClient.resolveUrl(
                      project['heroImage']?.toString() ?? 
                      ((images != null && images.isNotEmpty) ? images[0].toString() : null)
                    );
                    return GestureDetector(
                      onTap: () {
                        if (projectId.isNotEmpty) {
                          final authState = ref.read(authProvider);
                          if (authState.status == AuthStatus.authenticated) {
                            Navigator.push(
                              context,
                              MaterialPageRoute(
                                builder: (context) => ProjectDetailScreen(
                                  projectId: projectId,
                                  projectData: project,
                                ),
                              ),
                            );
                          } else {
                            Navigator.push(
                              context,
                              MaterialPageRoute(
                                builder: (context) => GuestProjectDetailScreen(
                                  projectId: projectId,
                                  projectData: project,
                                ),
                              ),
                            );
                          }
                        }
                      },
                      child: isGridView
                          ? _ProjectGridItem(project: project, imageUrl: imageUrl)
                          : _ProjectListRowItem(project: project, imageUrl: imageUrl),
                    );
                  },
                ),
                loading: () => Center(child: CircularProgressIndicator(color: M4Theme.premiumBlue)),
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
    final isDark = Theme.of(context).brightness == Brightness.dark;
    return Container(
      margin: const EdgeInsets.only(bottom: 24),
      height: 240, // Match Web 16:10 aspect ratio better
      decoration: BoxDecoration(
        color: isDark ? const Color(0xFF18181B) : Colors.white,
        borderRadius: BorderRadius.circular(40),
        boxShadow: [
          BoxShadow(color: (isDark ? Colors.black : Colors.black).withOpacity(isDark ? 0.3 : 0.05), blurRadius: 20, offset: const Offset(0, 10)),
        ],
      ),
      clipBehavior: Clip.antiAlias,
      child: Stack(
        fit: StackFit.expand,
        children: [
          CachedNetworkImage(
            imageUrl: imageUrl, 
            fit: BoxFit.cover,
            placeholder: (context, url) => Container(color: Colors.black12),
            errorWidget: (context, url, error) => const Icon(Icons.error),
          ),
          // Subtle Gradient Overlay for text readability on images
          Container(
            decoration: BoxDecoration(
              gradient: LinearGradient(
                begin: Alignment.topCenter,
                end: Alignment.bottomCenter,
                colors: [
                  Colors.black.withOpacity(0.1),
                  Colors.transparent,
                  Colors.black.withOpacity(0.6),
                ],
                stops: const [0.0, 0.4, 1.0],
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
    final isDark = Theme.of(context).brightness == Brightness.dark;
    return Container(
      margin: const EdgeInsets.only(bottom: 16),
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: isDark ? const Color(0xFF18181B) : Colors.white,
        borderRadius: BorderRadius.circular(24),
        boxShadow: [
          BoxShadow(color: (isDark ? Colors.black : Colors.black).withOpacity(isDark ? 0.3 : 0.04), blurRadius: 20, offset: const Offset(0, 4)),
        ],
        border: Border.all(color: (isDark ? Colors.white : Colors.black).withOpacity(0.05)),
      ),
      child: Row(
        children: [
          // Left Thumbnail
          Container(
            width: 100,
            height: 100,
            decoration: BoxDecoration(
              borderRadius: BorderRadius.circular(16),
            ),
            child: ClipRRect(
              borderRadius: BorderRadius.circular(16),
              child: CachedNetworkImage(
                imageUrl: imageUrl, 
                fit: BoxFit.cover,
                placeholder: (context, url) => Container(color: Colors.black12),
                errorWidget: (context, url, error) => const Icon(Icons.error),
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
                    color: isDark ? Colors.white : Colors.black,
                    letterSpacing: -0.5,
                  ),
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                ),
                const SizedBox(height: 4),
                Row(
                  children: [
                    Icon(LucideIcons.mapPin, size: 12, color: Theme.of(context).colorScheme.onSurface.withOpacity(0.4)),
                    const SizedBox(width: 4),
                    Expanded(
                      child: Text(
                        project['location']?['name'] ?? 'N/A',
                        style: GoogleFonts.montserrat(
                          fontSize: 11,
                          color: Theme.of(context).colorScheme.onSurface.withOpacity(0.4),
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
              color: Theme.of(context).colorScheme.onSurface.withOpacity(0.05),
              borderRadius: BorderRadius.circular(12),
            ),
            child: Icon(LucideIcons.chevronRight, color: Theme.of(context).colorScheme.onSurface, size: 18),
          ),
        ],
      ),
    ).animate().fadeIn().slideX(begin: 0.1, end: 0);
  }
}

class _Badge extends StatelessWidget {
  final String text;
  final bool isOutline;
  const _Badge({required this.text, this.isOutline = false});

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
      decoration: BoxDecoration(
        color: Theme.of(context).colorScheme.onSurface.withOpacity(0.1),
        borderRadius: BorderRadius.circular(10),
        border: Border.all(color: Theme.of(context).colorScheme.onSurface.withOpacity(0.1)),
      ),
      child: Text(
        text,
        style: GoogleFonts.montserrat(
          fontSize: 8,
          fontWeight: FontWeight.w900,
          color: Theme.of(context).colorScheme.onSurface,
          letterSpacing: 1.0,
        ),
      ),
    );
  }
}

class _FilterSection extends StatelessWidget {
  final String title;
  final List<String> options;
  final List<String> selectedOptions;
  final Function(String) onToggle;

  const _FilterSection({
    required this.title,
    required this.options,
    required this.selectedOptions,
    required this.onToggle,
  });

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          title, 
          style: GoogleFonts.montserrat(fontSize: 10, fontWeight: FontWeight.bold, color: Theme.of(context).colorScheme.onSurface.withOpacity(0.3), letterSpacing: 2)
        ),
        const SizedBox(height: 16),
        Wrap(
          spacing: 8,
          runSpacing: 12,
          children: options.map((opt) {
            final isSelected = selectedOptions.contains(opt);
            return GestureDetector(
              onTap: () => onToggle(opt),
              child: AnimatedContainer(
                duration: const Duration(milliseconds: 200),
                padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 12),
                decoration: BoxDecoration(
                  color: isSelected 
                      ? (Theme.of(context).brightness == Brightness.dark ? Colors.white : Colors.black)
                      : Theme.of(context).colorScheme.onSurface.withOpacity(0.05),
                  borderRadius: BorderRadius.circular(15),
                  border: Border.all(color: isSelected 
                      ? (Theme.of(context).brightness == Brightness.dark ? Colors.white : Colors.black)
                      : Theme.of(context).colorScheme.onSurface.withOpacity(0.08)),
                  boxShadow: isSelected ? [
                    BoxShadow(color: (Theme.of(context).brightness == Brightness.dark ? Colors.white24 : Colors.black26), blurRadius: 20, spreadRadius: -5)
                  ] : null,
                ),
                child: Text(
                  opt.toUpperCase(),
                  style: GoogleFonts.montserrat(
                    fontSize: 9, 
                    fontWeight: FontWeight.w900, 
                    color: isSelected 
                        ? (Theme.of(context).brightness == Brightness.dark ? Colors.black : Colors.white)
                        : Theme.of(context).colorScheme.onSurface.withOpacity(0.4),
                    letterSpacing: 1,
                  ),
                ),
              ),
            );
          }).toList(),
        ),
      ],
    );
  }
}
