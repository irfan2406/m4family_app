import 'package:flutter/material.dart';
import 'package:cached_network_image/cached_network_image.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:m4_mobile/core/theme/app_theme.dart';
import 'package:m4_mobile/presentation/providers/project_provider.dart';
import 'package:m4_mobile/presentation/providers/cp_shell_provider.dart';
import 'package:flutter_animate/flutter_animate.dart';
import 'package:lucide_icons/lucide_icons.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:m4_mobile/presentation/screens/projects/project_detail_screen.dart';
import 'package:m4_mobile/presentation/providers/auth_provider.dart';
import 'package:m4_mobile/presentation/widgets/main_shell.dart';
import 'package:m4_mobile/presentation/widgets/guest_main_shell.dart';
import 'package:m4_mobile/presentation/screens/projects/guest_project_detail_screen.dart';
import 'package:m4_mobile/presentation/widgets/conditional_drawer.dart';
import 'package:m4_mobile/presentation/widgets/cp_sidebar_menu.dart';

/// Channel Partner catalog: set [cpCatalogMode] so back + detail routes match web `/cp/projects`.
class ProjectListScreen extends ConsumerWidget {
  const ProjectListScreen({super.key, this.cpCatalogMode = false});

  final bool cpCatalogMode;

  void _showFilterBottomSheet(BuildContext context, WidgetRef ref) {
    final locationOptions = ["SOUTH MUMBAI", "WORLI", "BANDRA", "JUHU", "POWAI"];
    final configOptions = ["1 BHK", "2 BHK", "3 BHK", "4 BHK", "5 BHK", "DUPLEX", "PENTHOUSE"];
    final areaOptions = ["< 1000", "1000 - 2000", "2000 - 4000", "4000 +"];

    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (context) {
        return StatefulBuilder(
          builder: (context, setModalState) {
            final isDark = Theme.of(context).brightness == Brightness.dark;
            return Container(
              height: MediaQuery.of(context).size.height * 0.85,
              decoration: BoxDecoration(
                color: isDark ? const Color(0xFF111111) : Colors.white,
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
                        Text('REFINE SEARCH', style: GoogleFonts.montserrat(fontSize: 22, fontWeight: FontWeight.w900, color: Theme.of(context).colorScheme.onSurface, letterSpacing: -0.5)),
                        IconButton(
                          onPressed: () => Navigator.pop(context),
                          icon: Icon(LucideIcons.x, color: Theme.of(context).colorScheme.onSurface, size: 18),
                          style: IconButton.styleFrom(
                            backgroundColor: Theme.of(context).colorScheme.onSurface.withOpacity(0.05), 
                            shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                            fixedSize: const Size(40, 40),
                          ),
                        ),
                      ],
                    ),
                  ),
                  const SizedBox(height: 32),
                  Expanded(
                    child: Consumer(
                      builder: (context, ref, child) {
                        final selectedLocs = ref.watch(selectedLocationsProvider);
                        final selectedConfigs = ref.watch(selectedConfigsProvider);
                        final selectedAreas = ref.watch(selectedAreasProvider);

                        return ListView(
                          padding: const EdgeInsets.symmetric(horizontal: 24),
                          children: [
                            _FilterSection(
                              title: 'LOCATION',
                              options: locationOptions,
                              selectedOptions: selectedLocs,
                              onToggle: (val) {
                                final current = List<String>.from(ref.read(selectedLocationsProvider));
                                if (current.contains(val)) current.remove(val); else current.add(val);
                                ref.read(selectedLocationsProvider.notifier).state = current;
                              },
                            ),
                            const SizedBox(height: 32),
                            _FilterSection(
                              title: 'CONFIGURATION',
                              options: configOptions,
                              selectedOptions: selectedConfigs,
                              onToggle: (val) {
                                final current = List<String>.from(ref.read(selectedConfigsProvider));
                                if (current.contains(val)) current.remove(val); else current.add(val);
                                ref.read(selectedConfigsProvider.notifier).state = current;
                              },
                            ),
                            const SizedBox(height: 32),
                            _FilterSection(
                              title: 'AREA (SQ FT)',
                              options: areaOptions,
                              selectedOptions: selectedAreas,
                              onToggle: (val) {
                                final current = List<String>.from(ref.read(selectedAreasProvider));
                                if (current.contains(val)) current.remove(val); else current.add(val);
                                ref.read(selectedAreasProvider.notifier).state = current;
                              },
                            ),
                            const SizedBox(height: 48),
                          ],
                        );
                      },
                    ),
                  ),
                  Padding(
                    padding: const EdgeInsets.fromLTRB(24, 0, 24, 40),
                    child: SizedBox(
                      width: double.infinity,
                      height: 64,
                      child: ElevatedButton(
                        onPressed: () => Navigator.pop(context),
                        style: ElevatedButton.styleFrom(
                          backgroundColor: isDark ? Colors.white : Colors.black,
                          foregroundColor: isDark ? Colors.black : Colors.white,
                          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
                        ),
                        child: Text(
                          'APPLY SEARCH MATRIX',
                          style: GoogleFonts.montserrat(
                            fontSize: 12, 
                            fontWeight: FontWeight.w900, 
                            letterSpacing: 1.5
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
      drawer: cpCatalogMode ? const CpSidebarMenu() : const ConditionalDrawer(),
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
                          if (cpCatalogMode) {
                            ref.read(cpNavigationIndexProvider.notifier).state = 0;
                            context.go('/home');
                            return;
                          }
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
                          if (cpCatalogMode) ...[
                            Text(
                              'M4 PROPERTIES',
                              style: GoogleFonts.montserrat(
                                fontSize: 22,
                                fontWeight: FontWeight.w900,
                                color: Theme.of(context).colorScheme.onSurface,
                                letterSpacing: -0.5,
                              ),
                            ),
                            const SizedBox(height: 6),
                            Text(
                              'DISCOVER CURATED LUXURY',
                              style: GoogleFonts.montserrat(
                                fontSize: 9,
                                fontWeight: FontWeight.w700,
                                color: Theme.of(context).colorScheme.onSurface.withOpacity(0.45),
                                letterSpacing: 2.5,
                              ),
                            ),
                          ] else ...[
                            Text(
                              'DISCOVER',
                              style: GoogleFonts.montserrat(
                                fontSize: 9,
                                fontWeight: FontWeight.w700,
                                color: Theme.of(context).colorScheme.onSurface.withOpacity(0.45),
                                letterSpacing: 3,
                              ),
                            ),
                            const SizedBox(height: 2),
                            Text(
                              'M4 PROPERTIES',
                              style: GoogleFonts.montserrat(
                                fontSize: 18,
                                fontWeight: FontWeight.w800,
                                color: Theme.of(context).colorScheme.onSurface,
                                letterSpacing: -0.3,
                              ),
                            ),
                          ],
                        ],
                      ),
                    ],
                  ),
                  Row(
                    children: [
                      // View toggle pill (grid | list) — web parity
                      Container(
                        padding: const EdgeInsets.all(4),
                        decoration: BoxDecoration(
                          color: (isDark ? Colors.white : Colors.black).withOpacity(0.05),
                          borderRadius: BorderRadius.circular(12),
                          border: Border.all(color: (isDark ? Colors.white : Colors.black).withOpacity(0.08)),
                        ),
                        child: Row(
                          children: [
                            _ViewToggleBtn(
                              icon: LucideIcons.layoutGrid,
                              active: isGridView,
                              onTap: () => ref.read(projectLayoutProvider.notifier).state = true,
                            ),
                            const SizedBox(width: 4),
                            _ViewToggleBtn(
                              icon: LucideIcons.list,
                              active: !isGridView,
                              onTap: () => ref.read(projectLayoutProvider.notifier).state = false,
                            ),
                          ],
                        ),
                      ),
                      const SizedBox(width: 12),
                      // "..." menu -> sidebar drawer (web parity)
                      Builder(
                        builder: (ctx) => GestureDetector(
                          onTap: () => Scaffold.of(ctx).openDrawer(),
                          child: Container(
                            width: 48,
                            height: 36,
                            alignment: Alignment.center,
                            decoration: BoxDecoration(
                              color: isDark ? Colors.white : Colors.black,
                              borderRadius: BorderRadius.circular(12),
                            ),
                            child: Icon(LucideIcons.moreHorizontal, size: 18, color: isDark ? Colors.black : Colors.white),
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
                                : Theme.of(context).colorScheme.onSurface.withOpacity(0.55),
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
                    final heroImages = project['heroImages'] as List?;
                    final rawHero = project['heroImage']?.toString() ??
                        ((heroImages != null && heroImages.isNotEmpty) ? heroImages[0].toString() : null) ??
                        ((images != null && images.isNotEmpty) ? images[0].toString() : null);
                    // Web parity: fall back to a default building photo when a project
                    // has no image, instead of showing a broken-image icon.
                    final imageUrl = (rawHero == null || rawHero.isEmpty)
                        ? 'https://images.unsplash.com/photo-1486406146926-c627a92ad1ab?auto=format&fit=crop&q=80'
                        : apiClient.resolveUrl(rawHero);
                    return GestureDetector(
                      onTap: () {
                        if (projectId.isEmpty) return;
                        if (cpCatalogMode) {
                          final map = project is Map<String, dynamic>
                              ? project as Map<String, dynamic>
                              : Map<String, dynamic>.from(project as Map);
                          context.push('/cp/projects/$projectId', extra: map);
                          return;
                        }
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
    final loc = project['location'];
    final locName = (loc is Map ? (loc['name']?.toString() ?? '') : (loc?.toString() ?? ''));
    final locationLabel = (locName.isEmpty ? 'N/A' : locName).split(',').first;
    return Container(
      margin: const EdgeInsets.only(bottom: 24),
      height: 200, // Enforce 16:9 aspect ratio parity with web (approx for mobile width)
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
            errorWidget: (context, url, error) => Container(
              color: const Color(0xFF1A1A1A),
              child: const Center(child: Icon(LucideIcons.building2, color: Colors.white24, size: 40)),
            ),
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

          // Artistic Impression badge (web parity: only this badge, top-right, dark glass)
          if (project['status']?.toString().toLowerCase() != 'completed')
            Positioned(
              top: 20,
              right: 20,
              child: Container(
                padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
                decoration: BoxDecoration(
                  color: Colors.black.withOpacity(0.4),
                  borderRadius: BorderRadius.circular(20),
                  border: Border.all(color: Colors.white.withOpacity(0.1)),
                ),
                child: Text(
                  'ARTISTIC IMPRESSION',
                  style: GoogleFonts.montserrat(
                    fontSize: 7,
                    fontWeight: FontWeight.w900,
                    color: Colors.white.withOpacity(0.6),
                    letterSpacing: 1.5,
                  ),
                ),
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
                // Location (above) + Title — web order
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Row(
                        children: [
                          const Icon(LucideIcons.mapPin, size: 13, color: Colors.white70),
                          const SizedBox(width: 4),
                          Expanded(
                            child: Text(
                              locationLabel.toUpperCase(),
                              style: GoogleFonts.montserrat(
                                fontSize: 10,
                                color: Colors.white70,
                                fontWeight: FontWeight.w900,
                                letterSpacing: 1.5,
                              ),
                              maxLines: 1,
                              overflow: TextOverflow.ellipsis,
                            ),
                          ),
                        ],
                      ),
                      const SizedBox(height: 6),
                      Text(
                        project['title'] ?? 'M4 PROJECT',
                        style: GoogleFonts.montserrat(
                          fontSize: 22,
                          fontWeight: FontWeight.w800,
                          color: Colors.white,
                          letterSpacing: -0.5,
                        ),
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
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
                errorWidget: (context, url, error) => Container(
              color: const Color(0xFF1A1A1A),
              child: const Center(child: Icon(LucideIcons.building2, color: Colors.white24, size: 40)),
            ),
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

class _ViewToggleBtn extends StatelessWidget {
  final IconData icon;
  final bool active;
  final VoidCallback onTap;
  const _ViewToggleBtn({required this.icon, required this.active, required this.onTap});

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    return GestureDetector(
      onTap: onTap,
      child: Container(
        width: 32,
        height: 32,
        alignment: Alignment.center,
        decoration: BoxDecoration(
          color: active ? (isDark ? Colors.white : Colors.black) : Colors.transparent,
          borderRadius: BorderRadius.circular(8),
        ),
        child: Icon(
          icon,
          size: 16,
          color: active
              ? (isDark ? Colors.black : Colors.white)
              : Theme.of(context).colorScheme.onSurface.withOpacity(0.4),
        ),
      ),
    );
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
          style: GoogleFonts.montserrat(fontSize: 10, fontWeight: FontWeight.w900, color: Theme.of(context).colorScheme.onSurface.withOpacity(0.55), letterSpacing: 2)
        ),
        const SizedBox(height: 16),
        Wrap(
          spacing: 12,
          runSpacing: 12,
          children: options.map((opt) {
            final isSelected = selectedOptions.contains(opt);
            return GestureDetector(
              onTap: () => onToggle(opt),
              child: AnimatedContainer(
                duration: const Duration(milliseconds: 200),
                padding: const EdgeInsets.symmetric(horizontal: 22, vertical: 14),
                decoration: BoxDecoration(
                  color: isSelected 
                      ? (Theme.of(context).brightness == Brightness.dark ? Colors.white : Colors.black)
                      : Theme.of(context).colorScheme.onSurface.withOpacity(0.04),
                  borderRadius: BorderRadius.circular(30), // Rounded pill like web
                  border: Border.all(color: isSelected 
                      ? (Theme.of(context).brightness == Brightness.dark ? Colors.white : Colors.black)
                      : Theme.of(context).colorScheme.onSurface.withOpacity(0.08)),
                ),
                child: Text(
                  opt.toUpperCase(),
                  style: GoogleFonts.montserrat(
                    fontSize: 9, 
                    fontWeight: FontWeight.w900, 
                    color: isSelected 
                        ? (Theme.of(context).brightness == Brightness.dark ? Colors.black : Colors.white)
                        : Theme.of(context).colorScheme.onSurface.withOpacity(0.5),
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
