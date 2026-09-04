import 'package:m4_mobile/presentation/widgets/guest_sidebar_menu.dart';
import 'dart:convert';

import 'package:flutter/material.dart';
import 'package:cached_network_image/cached_network_image.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:m4_mobile/core/theme/app_theme.dart';
import 'package:m4_mobile/presentation/providers/project_provider.dart';
import 'package:m4_mobile/presentation/providers/cp_shell_provider.dart';
import 'package:m4_mobile/presentation/providers/investor_shell_provider.dart';
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

/// Renders a project image, decoding base64 `data:` URIs via [Image.memory]
/// (CachedNetworkImage can only fetch network URLs). Used by the project cards.
Widget _projListImage(String url, {BoxFit fit = BoxFit.cover}) {
  Widget errorBox() => Container(
    color: const Color(0xFF1C4535),
    child: const Center(
      child: Icon(LucideIcons.building2, color: Colors.white24, size: 40),
    ),
  );
  if (url.startsWith('data:')) {
    try {
      final bytes = base64Decode(
        url.substring(url.indexOf(',') + 1).replaceAll(RegExp(r'\s'), ''),
      );
      return Image.memory(
        bytes,
        fit: fit,
        cacheWidth: 1080,
        errorBuilder: (_, __, ___) => errorBox(),
      );
    } catch (_) {
      return errorBox();
    }
  }
  return CachedNetworkImage(
    memCacheWidth: 1080,
    imageUrl: url,
    fit: fit,
    placeholder: (context, u) => Container(color: Colors.black12),
    errorWidget: (context, u, e) => errorBox(),
  );
}

/// Channel Partner catalog: set [cpCatalogMode] so back + detail routes match web `/cp/projects`.
class ProjectListScreen extends ConsumerWidget {
  const ProjectListScreen({
    super.key,
    this.cpCatalogMode = false,
    this.guestMode = false,
    this.embedded = false,
  });

  /// True when this is a tab inside a shell, which already owns the menu.
  /// A nested drawer of our own would open underneath the shell's floating
  /// nav pill instead of over it.
  final bool embedded;

  final bool cpCatalogMode;

  /// When shown as the guest portal's Properties tab, the drawer must be the
  /// guest menu — the same one the guest Home uses — not the role-guessed
  /// ConditionalDrawer, so the whole guest portal shares one menu.
  final bool guestMode;

  // Retained for future use; the header filter button was removed for web
  // parity (screenshot has only the grid/list toggle and the "..." menu).
  // ignore: unused_element
  void _showFilterBottomSheet(BuildContext context, WidgetRef ref) {
    // From the catalog, so a chip always corresponds to a real property.
    final catalogLocations = ref
        .read(projectLocationsProvider)
        .map((l) => l.toUpperCase())
        .where((l) => l.isNotEmpty)
        .toList();
    final locationOptions = catalogLocations.isNotEmpty
        ? catalogLocations
        : const ["SOUTH MUMBAI", "WORLI", "BANDRA", "JUHU", "POWAI"];
    final configOptions = [
      "1 BHK",
      "2 BHK",
      "3 BHK",
      "4 BHK",
      "5 BHK",
      "DUPLEX",
      "PENTHOUSE",
    ];
    final areaOptions = ["< 1000", "1000 - 2000", "2000 - 4000", "4000 +"];

    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (context) {
        return StatefulBuilder(
          builder: (context, setModalState) {
            // The refine sheet is always the cream surface, in both app
            // themes. Running its subtree under the light theme flips the
            // whole sheet together — surface, type, chips and button — so no
            // white-on-cream text can slip through.
            return Theme(
              data: M4Theme.lightTheme,
              child: Builder(
                builder: (context) {
                  final isDark =
                      Theme.of(context).brightness == Brightness.dark;
                  return Container(
                    // Half-sheet popup: the filter list scrolls inside it rather than
                    // the sheet swallowing the screen.
                    height: MediaQuery.of(context).size.height * 0.55,
                    decoration: BoxDecoration(
                      color: isDark
                          ? const Color(0xFF1C4535)
                          : const Color(0xFFF4EFE3),
                      borderRadius: const BorderRadius.vertical(
                        top: Radius.circular(40),
                      ),
                    ),
                    child: Column(
                      children: [
                        const SizedBox(height: 12),
                        Container(
                          width: 40,
                          height: 4,
                          decoration: BoxDecoration(
                            color: Theme.of(
                              context,
                            ).colorScheme.onSurface.withOpacity(0.1),
                            borderRadius: BorderRadius.circular(2),
                          ),
                        ),
                        const SizedBox(height: 16),
                        Padding(
                          padding: const EdgeInsets.symmetric(horizontal: 24),
                          child: Row(
                            mainAxisAlignment: MainAxisAlignment.spaceBetween,
                            children: [
                              Text(
                                'REFINE SEARCH',
                                style: GoogleFonts.gelasio(
                                  fontSize: 22,
                                  fontWeight: FontWeight.w700,
                                  color: Theme.of(
                                    context,
                                  ).colorScheme.onSurface,
                                  letterSpacing: -0.5,
                                ),
                              ),
                              IconButton(
                                onPressed: () => Navigator.pop(context),
                                icon: Icon(
                                  LucideIcons.x,
                                  color: Theme.of(
                                    context,
                                  ).colorScheme.onSurface,
                                  size: 18,
                                ),
                                style: IconButton.styleFrom(
                                  backgroundColor: Theme.of(
                                    context,
                                  ).colorScheme.onSurface.withOpacity(0.05),
                                  shape: RoundedRectangleBorder(
                                    borderRadius: BorderRadius.circular(12),
                                  ),
                                  fixedSize: const Size(40, 40),
                                ),
                              ),
                            ],
                          ),
                        ),
                        const SizedBox(height: 20),
                        Expanded(
                          child: Consumer(
                            builder: (context, ref, child) {
                              final selectedLocs = ref.watch(
                                selectedLocationsProvider,
                              );
                              final selectedConfigs = ref.watch(
                                selectedConfigsProvider,
                              );
                              final selectedAreas = ref.watch(
                                selectedAreasProvider,
                              );
                              final selectedTypes = ref.watch(
                                selectedTypesProvider,
                              );

                              return ListView(
                                padding: const EdgeInsets.fromLTRB(
                                  24,
                                  0,
                                  24,
                                  8,
                                ),
                                children: [
                                  _FilterSection(
                                    title: 'LOCATION',
                                    options: locationOptions,
                                    selectedOptions: selectedLocs,
                                    onToggle: (val) {
                                      final current = List<String>.from(
                                        ref.read(selectedLocationsProvider),
                                      );
                                      if (current.contains(val))
                                        current.remove(val);
                                      else
                                        current.add(val);
                                      ref
                                              .read(
                                                selectedLocationsProvider
                                                    .notifier,
                                              )
                                              .state =
                                          current;
                                    },
                                  ),
                                  const SizedBox(height: 32),
                                  _FilterSection(
                                    title: 'CONFIGURATION',
                                    options: configOptions,
                                    selectedOptions: selectedConfigs,
                                    onToggle: (val) {
                                      final current = List<String>.from(
                                        ref.read(selectedConfigsProvider),
                                      );
                                      if (current.contains(val))
                                        current.remove(val);
                                      else
                                        current.add(val);
                                      ref
                                              .read(
                                                selectedConfigsProvider
                                                    .notifier,
                                              )
                                              .state =
                                          current;
                                    },
                                  ),
                                  const SizedBox(height: 32),
                                  _FilterSection(
                                    title: 'AREA (SQ FT)',
                                    options: areaOptions,
                                    selectedOptions: selectedAreas,
                                    onToggle: (val) {
                                      final current = List<String>.from(
                                        ref.read(selectedAreasProvider),
                                      );
                                      if (current.contains(val))
                                        current.remove(val);
                                      else
                                        current.add(val);
                                      ref
                                              .read(
                                                selectedAreasProvider.notifier,
                                              )
                                              .state =
                                          current;
                                    },
                                  ),
                                  const SizedBox(height: 32),
                                  _FilterSection(
                                    title: 'PROPERTY TYPE',
                                    options: const [
                                      "RESIDENTIAL",
                                      "COMMERCIAL",
                                    ],
                                    selectedOptions: selectedTypes,
                                    onToggle: (val) {
                                      final current = List<String>.from(
                                        ref.read(selectedTypesProvider),
                                      );
                                      if (current.contains(val))
                                        current.remove(val);
                                      else
                                        current.add(val);
                                      ref
                                              .read(
                                                selectedTypesProvider.notifier,
                                              )
                                              .state =
                                          current;
                                    },
                                  ),
                                  const SizedBox(height: 8),
                                ],
                              );
                            },
                          ),
                        ),
                        Padding(
                          padding: EdgeInsets.fromLTRB(
                            24,
                            12,
                            24,
                            12 + MediaQuery.of(context).padding.bottom,
                          ),
                          child: SizedBox(
                            width: double.infinity,
                            height: 64,
                            child: ElevatedButton(
                              onPressed: () => Navigator.pop(context),
                              style: ElevatedButton.styleFrom(
                                backgroundColor: isDark
                                    ? Colors.white
                                    : const Color(0xFF0C312B),
                                foregroundColor: isDark
                                    ? Colors.black
                                    : const Color(0xFFF4EFE3),
                                shape: RoundedRectangleBorder(
                                  borderRadius: BorderRadius.circular(20),
                                ),
                              ),
                              child: Text(
                                'APPLY SEARCH MATRIX',
                                style: GoogleFonts.gelasio(
                                  fontSize: 12,
                                  fontWeight: FontWeight.w700,
                                  letterSpacing: 1.5,
                                ),
                              ),
                            ),
                          ),
                        ),
                      ],
                    ),
                  );
                },
              ),
            );
          },
        );
      },
    );
  }

  /// Shown when the selected status tab holds nothing. Cream on the green
  /// showcase surface, forest green on cream — the same pair the rest of the
  /// app uses, so it reads as part of the page rather than a system message.
  Widget _buildNoMatches(bool isDark, WidgetRef ref) {
    final Color ink = isDark
        ? const Color(0xFFF4EFE3)
        : const Color(0xFF0C312B);
    // A refine-search filter left on hides everything and looks identical to
    // an empty catalog, so the two are told apart here.
    final filtersOn =
        ref.watch(selectedLocationsProvider).isNotEmpty ||
        ref.watch(selectedBudgetsProvider).isNotEmpty ||
        ref.watch(selectedTypesProvider).isNotEmpty ||
        ref.watch(selectedConfigsProvider).isNotEmpty ||
        ref.watch(selectedAreasProvider).isNotEmpty;
    return Center(
      child: Padding(
        padding: const EdgeInsets.fromLTRB(40, 0, 40, 120),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Container(
              width: 86,
              height: 86,
              alignment: Alignment.center,
              decoration: BoxDecoration(
                color: ink.withValues(alpha: 0.05),
                shape: BoxShape.circle,
                border: Border.all(color: ink.withValues(alpha: 0.08)),
              ),
              child: Icon(
                LucideIcons.layoutGrid,
                size: 30,
                color: ink.withValues(alpha: 0.35),
              ),
            ),
            const SizedBox(height: 26),
            Text(
              'NO ARCHITECTURAL MATCHES',
              textAlign: TextAlign.center,
              maxLines: 2,
              overflow: TextOverflow.ellipsis,
              style: GoogleFonts.gelasio(
                fontSize: 11,
                fontWeight: FontWeight.w700,
                letterSpacing: 2,
                color: ink.withValues(alpha: 0.85),
              ),
            ),
            const SizedBox(height: 10),
            Text(
              filtersOn
                  ? 'Your refine-search filters are hiding every property here.'
                  : 'Try expanding your search criteria.',
              textAlign: TextAlign.center,
              maxLines: 3,
              overflow: TextOverflow.ellipsis,
              style: GoogleFonts.inter(
                fontSize: 12,
                fontWeight: FontWeight.w500,
                color: ink.withValues(alpha: 0.5),
              ),
            ),
            if (filtersOn) ...[
              const SizedBox(height: 22),
              GestureDetector(
                onTap: () {
                  ref.read(selectedLocationsProvider.notifier).state = [];
                  ref.read(selectedBudgetsProvider.notifier).state = [];
                  ref.read(selectedTypesProvider.notifier).state = [];
                  ref.read(selectedConfigsProvider.notifier).state = [];
                  ref.read(selectedAreasProvider.notifier).state = [];
                },
                child: Container(
                  padding: const EdgeInsets.symmetric(
                    horizontal: 24,
                    vertical: 14,
                  ),
                  decoration: BoxDecoration(
                    color: ink.withValues(alpha: 0.08),
                    borderRadius: BorderRadius.circular(99),
                    border: Border.all(color: ink.withValues(alpha: 0.18)),
                  ),
                  child: Text(
                    'CLEAR FILTERS',
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                    style: GoogleFonts.gelasio(
                      fontSize: 10,
                      fontWeight: FontWeight.w700,
                      letterSpacing: 2,
                      color: ink.withValues(alpha: 0.9),
                    ),
                  ),
                ),
              ),
            ],
          ],
        ),
      ),
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
      // A tab inside a shell leaves the menu to the shell (see [embedded]).
      drawer: embedded
          ? null
          : cpCatalogMode
          ? const CpSidebarMenu()
          : guestMode
          ? const GuestSidebarMenu()
          : const ConditionalDrawer(),
      body: Stack(
        children: [
          // No page-level mesh: it ran to the top edge and showed through the
          // header and nav. The texture lives on the cards only, like Figma.
          SafeArea(
            // Edge-to-edge: content runs under the gesture bar so scrolling fills
            // the screen. Trailing padding keeps the last item reachable.
            bottom: false,
            child: Column(
              children: [
                // 🏷️ Custom Header
                Padding(
                  padding: const EdgeInsets.fromLTRB(16, 20, 16, 20),
                  child: Row(
                    children: [
                      Expanded(
                        child: Row(
                          children: [
                            InkWell(
                              onTap: () {
                                // Robust back: if a route was pushed, pop it;
                                // otherwise this is a shell tab, so switch that
                                // portal's shell back to its Home tab.
                                if (context.canPop()) {
                                  context.pop();
                                  return;
                                }
                                if (cpCatalogMode) {
                                  ref
                                          .read(
                                            cpNavigationIndexProvider.notifier,
                                          )
                                          .state =
                                      0;
                                } else {
                                  // Reset whichever shell is actually active back to
                                  // its Home tab. The inactive shells' providers are
                                  // simply ignored, so setting all is safe — and the
                                  // investor one was missing, which broke back on
                                  // the investor Properties tab.
                                  ref.read(navigationProvider.notifier).state =
                                      0;
                                  ref
                                          .read(
                                            guestNavigationProvider.notifier,
                                          )
                                          .state =
                                      0;
                                  ref
                                          .read(
                                            investorNavigationIndexProvider
                                                .notifier,
                                          )
                                          .state =
                                      0;
                                }
                              },
                              borderRadius: BorderRadius.circular(12),
                              // Web parity: contained back button (light rounded
                              // square with a subtle border), not a bare icon.
                              child: Container(
                                width: 40,
                                height: 40,
                                alignment: Alignment.center,
                                decoration: BoxDecoration(
                                  color:
                                      (isDark
                                              ? Colors.white
                                              : const Color(0xFF0C312B))
                                          .withOpacity(0.05),
                                  borderRadius: BorderRadius.circular(12),
                                  border: Border.all(
                                    color:
                                        (isDark
                                                ? Colors.white
                                                : const Color(0xFF0C312B))
                                            .withOpacity(0.08),
                                  ),
                                ),
                                child: Icon(
                                  LucideIcons.arrowLeft,
                                  color: Theme.of(
                                    context,
                                  ).colorScheme.onSurface,
                                  size: 18,
                                ),
                              ),
                            ),
                            const SizedBox(width: 10),
                            Expanded(
                              child: Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                mainAxisSize: MainAxisSize.min,
                                children: [
                                  if (cpCatalogMode) ...[
                                    Text(
                                      'M4 PROPERTIES',
                                      maxLines: 1,
                                      overflow: TextOverflow.ellipsis,
                                      style: GoogleFonts.inter(
                                        fontSize: 16,
                                        fontWeight: FontWeight.w600,
                                        color: Theme.of(
                                          context,
                                        ).colorScheme.onSurface,
                                        letterSpacing: -0.5,
                                      ),
                                    ),
                                    const SizedBox(height: 2),
                                    Text(
                                      'DISCOVER CURATED LUXURY',
                                      maxLines: 1,
                                      overflow: TextOverflow.ellipsis,
                                      style: GoogleFonts.gelasio(
                                        fontSize: 8,
                                        fontWeight: FontWeight.w700,
                                        color: Theme.of(context)
                                            .colorScheme
                                            .onSurface
                                            .withOpacity(0.72),
                                        letterSpacing: 1.5,
                                      ),
                                    ),
                                  ] else ...[
                                    Text(
                                      'DISCOVER',
                                      maxLines: 1,
                                      overflow: TextOverflow.ellipsis,
                                      style: GoogleFonts.gelasio(
                                        fontSize: 8,
                                        fontWeight: FontWeight.w700,
                                        color: Theme.of(context)
                                            .colorScheme
                                            .onSurface
                                            .withOpacity(0.72),
                                        letterSpacing: 2,
                                      ),
                                    ),
                                    const SizedBox(height: 2),
                                    Text(
                                      'M4 PROPERTIES',
                                      maxLines: 1,
                                      overflow: TextOverflow.ellipsis,
                                      style: GoogleFonts.inter(
                                        // Figma sets the wordmark a touch
                                        // larger than the app had it.
                                        fontSize: 16,
                                        fontWeight: FontWeight.w500,
                                        color: Theme.of(
                                          context,
                                        ).colorScheme.onSurface,
                                        letterSpacing: -0.3,
                                      ),
                                    ),
                                  ],
                                ],
                              ),
                            ),
                          ],
                        ),
                      ),
                      const SizedBox(width: 8),
                      Row(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          // Web parity: filter icon (light rounded square) to the
                          // left of the view toggle. Opens the REFINE SEARCH sheet.
                          // Guest has no refine-search filter; CP and investor keep it.
                          if (!guestMode) ...[
                            GestureDetector(
                              behavior: HitTestBehavior.opaque,
                              onTap: () => _showFilterBottomSheet(context, ref),
                              child: Container(
                                width: 40,
                                height: 40,
                                alignment: Alignment.center,
                                decoration: BoxDecoration(
                                  color:
                                      (isDark
                                              ? Colors.white
                                              : const Color(0xFF0C312B))
                                          .withOpacity(0.05),
                                  borderRadius: BorderRadius.circular(12),
                                  border: Border.all(
                                    color:
                                        (isDark
                                                ? Colors.white
                                                : const Color(0xFF0C312B))
                                            .withOpacity(0.08),
                                  ),
                                ),
                                child: Icon(
                                  LucideIcons.slidersHorizontal,
                                  color: Theme.of(
                                    context,
                                  ).colorScheme.onSurface,
                                  size: 18,
                                ),
                              ),
                            ),
                            const SizedBox(width: 12),
                          ],
                          // Web parity: grid / list view segmented toggle
                          // (active button filled black, matching projects/page.tsx).
                          // CP catalog shows one fixed card layout - no grid/list switch.
                          if (!cpCatalogMode) ...[
                            const SizedBox(width: 6),
                            Container(
                              padding: const EdgeInsets.all(3),
                              // No outline on the toggle: the soft fill alone
                              // holds the pair together.
                              decoration: BoxDecoration(
                                color:
                                    (isDark
                                            ? Colors.white
                                            : const Color(0xFF0C312B))
                                        .withOpacity(0.05),
                                borderRadius: BorderRadius.circular(12),
                              ),
                              child: Row(
                                mainAxisSize: MainAxisSize.min,
                                children: [
                                  _ViewToggleButton(
                                    icon: LucideIcons.layoutGrid,
                                    active: isGridView,
                                    isDark: isDark,
                                    onTap: () =>
                                        ref
                                                .read(
                                                  projectLayoutProvider
                                                      .notifier,
                                                )
                                                .state =
                                            true,
                                  ),
                                  const SizedBox(width: 3),
                                  _ViewToggleButton(
                                    icon: LucideIcons.list,
                                    active: !isGridView,
                                    isDark: isDark,
                                    onTap: () =>
                                        ref
                                                .read(
                                                  projectLayoutProvider
                                                      .notifier,
                                                )
                                                .state =
                                            false,
                                  ),
                                ],
                              ),
                            ),
                          ],
                        ],
                      ),
                    ],
                  ),
                ),

                // 🎛️ Pill Tabs
                Container(
                  margin: const EdgeInsets.symmetric(horizontal: 24),
                  // Figma runs this control noticeably slimmer than a stock
                  // 45pt tab bar — that lower height is what makes it read as
                  // sleek rather than chunky.
                  height: 38,
                  padding: const EdgeInsets.all(3),
                  // Figma: a soft tinted track behind the three tabs — a lift
                  // off the green, not a drawn outline.
                  decoration: BoxDecoration(
                    color: isDark
                        ? Colors.white.withOpacity(0.05)
                        : Colors.black.withOpacity(0.04),
                    borderRadius: BorderRadius.circular(19),
                    // Faint outline around the track, as in the reference.
                    border: Border.all(
                      color: (isDark ? Colors.white : Colors.black).withOpacity(
                        0.08,
                      ),
                    ),
                  ),
                  // The selected plate is ONE widget that slides between the
                  // three slots, rather than three chips cross-fading in
                  // place — that cross-fade is what made switching read as
                  // abrupt. AnimatedPositioned glides the plate and the
                  // labels ease their weight/colour over the same curve.
                  child: LayoutBuilder(
                    builder: (context, constraints) {
                      const filters = ['Ongoing', 'Upcoming', 'Completed'];
                      const duration = Duration(milliseconds: 280);
                      final index = filters
                          .indexOf(currentFilter)
                          .clamp(0, filters.length - 1);
                      final tabWidth = constraints.maxWidth / filters.length;
                      return Stack(
                        // Tight constraints come down from the 38pt track, so
                        // expand keeps the label row full-height and centred
                        // exactly where the old per-tab chips put it.
                        fit: StackFit.expand,
                        children: [
                          AnimatedPositioned(
                            duration: duration,
                            curve: Curves.easeOutCubic,
                            left: tabWidth * index,
                            top: 0,
                            bottom: 0,
                            width: tabWidth,
                            child: DecoratedBox(
                              decoration: BoxDecoration(
                                // Figma: the selected tab is a polished light
                                // chip — a top-to-bottom sheen from near-white
                                // into warm grey, so the surface catches light
                                // instead of reading as flat paint.
                                gradient: const LinearGradient(
                                  begin: Alignment.topCenter,
                                  end: Alignment.bottomCenter,
                                  colors: [
                                    Color(0xFFFDFCF9),
                                    Color(0xFFDCD9D0),
                                  ],
                                ),
                                borderRadius: BorderRadius.circular(16),
                                // Lifted inside the track: soft shadow
                                // beneath, bright hairline on the edge.
                                boxShadow: [
                                  BoxShadow(
                                    color: Colors.black.withOpacity(
                                      isDark ? 0.30 : 0.16,
                                    ),
                                    blurRadius: 12,
                                    spreadRadius: -2,
                                    offset: const Offset(0, 3),
                                  ),
                                ],
                                border: Border.all(
                                  color: Colors.white.withOpacity(0.6),
                                  width: 0.8,
                                ),
                              ),
                            ),
                          ),
                          Row(
                            children: filters.map((filter) {
                              final isSelected = currentFilter == filter;
                              return Expanded(
                                child: GestureDetector(
                                  behavior: HitTestBehavior.opaque,
                                  onTap: () =>
                                      ref
                                              .read(
                                                projectFilterProvider.notifier,
                                              )
                                              .state =
                                          filter,
                                  child: Center(
                                    child: AnimatedDefaultTextStyle(
                                      duration: duration,
                                      curve: Curves.easeOutCubic,
                                      style: GoogleFonts.inter(
                                        fontSize: 10,
                                        fontWeight: isSelected
                                            ? FontWeight.w600
                                            : FontWeight.bold,
                                        color: isSelected
                                            ? const Color(0xFF15271E)
                                            : Theme.of(context)
                                                  .colorScheme
                                                  .onSurface
                                                  .withOpacity(0.55),
                                        letterSpacing: 1,
                                      ),
                                      child: Text(filter.toUpperCase()),
                                    ),
                                  ),
                                ),
                              );
                            }).toList(),
                          ),
                        ],
                      );
                    },
                  ),
                ),

                const SizedBox(height: 24),

                // 🏙️ Project List
                Expanded(
                  child: Stack(
                    children: [
                      projectsAsync.when(
                        data: (projects) => filteredProjects.isEmpty
                            ? _buildNoMatches(isDark, ref)
                            : ListView.builder(
                                padding: const EdgeInsets.fromLTRB(
                                  24,
                                  0,
                                  24,
                                  120,
                                ), // Bottom padding for shell nav
                                itemCount: filteredProjects.length,
                                itemBuilder: (context, index) {
                                  final project = filteredProjects[index];
                                  final projectId =
                                      project['_id']?.toString() ?? '';
                                  // Thumbnail source, in order of preference. The
                                  // catalog populates `heroImage` (SINGULAR) on every
                                  // project and that is the image the web card shows;
                                  // `heroImages` (plural) is not a field the payload
                                  // has at all, so the old chain always skipped
                                  // straight to the galleries — and for a project
                                  // with no gallery (Skyline Heights, M4 Aura
                                  // Heights) all the way to one shared stock photo,
                                  // which is why those cards showed the same
                                  // building. `heroImage` is a plain string: either
                                  // an http URL or a base64 `data:` URI, both of
                                  // which _projListImage renders.
                                  String? plainOf(String key) {
                                    final v = project[key];
                                    if (v is String && v.trim().isNotEmpty)
                                      return v;
                                    return null;
                                  }

                                  String? firstOf(String key) {
                                    final v = project[key];
                                    if (v is List && v.isNotEmpty) {
                                      final f = v.first;
                                      final str = f is Map
                                          ? (f['url'] ?? f['image'] ?? '')
                                                .toString()
                                          : f.toString();
                                      return str.isEmpty ? null : str;
                                    }
                                    return null;
                                  }

                                  final rawHero =
                                      plainOf('heroImage') ??
                                      firstOf('heroImages') ??
                                      firstOf('exteriorImages') ??
                                      firstOf('interiorImages') ??
                                      firstOf('media');
                                  final imageUrl =
                                      (rawHero == null || rawHero.isEmpty)
                                      ? 'https://images.unsplash.com/photo-1486406146926-c627a92ad1ab?auto=format&fit=crop&q=80'
                                      : apiClient.resolveUrl(rawHero);
                                  return GestureDetector(
                                    onTap: () {
                                      if (projectId.isEmpty) return;
                                      if (cpCatalogMode) {
                                        final map =
                                            project is Map<String, dynamic>
                                            ? project as Map<String, dynamic>
                                            : Map<String, dynamic>.from(
                                                project as Map,
                                              );
                                        context.push(
                                          '/cp/projects/$projectId',
                                          extra: map,
                                        );
                                        return;
                                      }
                                      final authState = ref.read(authProvider);
                                      if (authState.status ==
                                          AuthStatus.authenticated) {
                                        Navigator.push(
                                          context,
                                          MaterialPageRoute(
                                            builder: (context) =>
                                                ProjectDetailScreen(
                                                  projectId: projectId,
                                                  projectData: project,
                                                ),
                                          ),
                                        );
                                      } else {
                                        Navigator.push(
                                          context,
                                          MaterialPageRoute(
                                            builder: (context) =>
                                                GuestProjectDetailScreen(
                                                  projectId: projectId,
                                                  projectData: project,
                                                ),
                                          ),
                                        );
                                      }
                                    },
                                    child: isGridView
                                        ? _ProjectGridItem(
                                            project: project,
                                            imageUrl: imageUrl,
                                          )
                                        : _ProjectListRowItem(
                                            project: project,
                                            imageUrl: imageUrl,
                                          ),
                                  );
                                },
                              ),
                        loading: () => const Center(
                          child: CircularProgressIndicator(
                            color: M4Theme.premiumBlue,
                          ),
                        ),
                        error: (e, s) {
                          final isDark =
                              Theme.of(context).brightness == Brightness.dark;
                          final onSurface = isDark
                              ? Colors.white
                              : const Color(0xFF0C312B);
                          final msg = e.toString().toLowerCase();
                          final isTimeout =
                              msg.contains('timeout') ||
                              msg.contains('connection');
                          return Center(
                            child: Padding(
                              padding: const EdgeInsets.all(32),
                              child: Column(
                                mainAxisSize: MainAxisSize.min,
                                children: [
                                  Icon(
                                    LucideIcons.wifiOff,
                                    size: 38,
                                    color: onSurface.withOpacity(0.3),
                                  ),
                                  const SizedBox(height: 16),
                                  Text(
                                    isTimeout
                                        ? 'TAKING LONGER THAN USUAL'
                                        : "COULDN'T LOAD PROPERTIES",
                                    textAlign: TextAlign.center,
                                    style: GoogleFonts.inter(
                                      fontSize: 12,
                                      fontWeight: FontWeight.w600,
                                      color: onSurface,
                                      letterSpacing: 1,
                                    ),
                                  ),
                                  const SizedBox(height: 8),
                                  Text(
                                    isTimeout
                                        ? 'The server may be waking up. Please try again.'
                                        : 'Please check your connection and try again.',
                                    textAlign: TextAlign.center,
                                    style: GoogleFonts.inter(
                                      fontSize: 11,
                                      fontWeight: FontWeight.w500,
                                      color: onSurface.withOpacity(0.5),
                                      height: 1.5,
                                    ),
                                  ),
                                  const SizedBox(height: 20),
                                  GestureDetector(
                                    onTap: () =>
                                        ref.invalidate(projectsProvider),
                                    child: Container(
                                      padding: const EdgeInsets.symmetric(
                                        horizontal: 28,
                                        vertical: 12,
                                      ),
                                      decoration: BoxDecoration(
                                        color: onSurface,
                                        borderRadius: BorderRadius.circular(20),
                                      ),
                                      child: Text(
                                        'RETRY',
                                        style: GoogleFonts.gelasio(
                                          fontSize: 11,
                                          fontWeight: FontWeight.w700,
                                          color: isDark
                                              ? const Color(0xFF0C312B)
                                              : const Color(0xFFF4EFE3),
                                          letterSpacing: 1.5,
                                        ),
                                      ),
                                    ),
                                  ),
                                ],
                              ),
                            ),
                          );
                        },
                      ),
                    ],
                  ),
                ),
              ],
            ),
          ),
        ],
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
    final locName = (loc is Map
        ? (loc['name']?.toString() ?? '')
        : (loc?.toString() ?? ''));
    final locationLabel = (locName.isEmpty ? 'N/A' : locName).split(',').first;
    return Container(
      // Figma: cards stack close together and are softly rounded, not
      // pill-round.
      margin: const EdgeInsets.only(bottom: 12),
      height:
          200, // Enforce 16:9 aspect ratio parity with web (approx for mobile width)
      decoration: BoxDecoration(
        color: isDark ? const Color(0xFF1C4535) : const Color(0xFFF4EFE3),
        borderRadius: BorderRadius.circular(24),
        // Figma depth: the card sits ON the green, lifted by a soft shadow that
        // falls straight down and stays tucked under the card. The negative
        // spread is what keeps it from haloing past the corners.
        // (The dark branch used to be Colors.transparent — i.e. no shadow at
        // all — so cards read as flat cut-outs on the green.)
        boxShadow: [
          BoxShadow(
            color: isDark
                ? Colors.black.withOpacity(0.34)
                : const Color(0xFF163A2C).withOpacity(0.10),
            blurRadius: 26,
            spreadRadius: -6,
            offset: const Offset(0, 12),
          ),
        ],
      ),
      clipBehavior: Clip.antiAlias,
      child: Stack(
        fit: StackFit.expand,
        children: [
          _projListImage(imageUrl),
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
                padding: const EdgeInsets.symmetric(
                  horizontal: 10,
                  vertical: 6,
                ),
                decoration: BoxDecoration(
                  // Figma: pale translucent glass over the photo, not a dark
                  // chip — the label reads light against the image.
                  color: Colors.white.withOpacity(0.18),
                  borderRadius: BorderRadius.circular(20),
                  border: Border.all(color: Colors.white.withOpacity(0.22)),
                ),
                child: Text(
                  'ARTISTIC IMPRESSION',
                  style: GoogleFonts.gelasio(
                    fontSize: 8,
                    fontWeight: FontWeight.w700,
                    color: Colors.white.withOpacity(0.9),
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
                // Figma order: a small tracked-out locality sits above the
                // project name, and the name carries all the weight.
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Text(
                        locationLabel.toUpperCase(),
                        style: GoogleFonts.gelasio(
                          fontSize: 9,
                          color: Colors.white70,
                          fontWeight: FontWeight.w700,
                          letterSpacing: 1.5,
                        ),
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                      ),
                      const SizedBox(height: 4),
                      Text(
                        (project['title'] ?? 'M4 Project')
                            .toString()
                            .toUpperCase(),
                        style: GoogleFonts.gelasio(
                          fontSize: 22,
                          fontWeight: FontWeight.w700,
                          color: Colors.white,
                          letterSpacing: -0.5,
                          height: 1.05,
                        ),
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                      ),
                    ],
                  ),
                ),

                const SizedBox(width: 16),

                // Guest-portal parity: white glass circle with a green arrow.
                Container(
                  width: 48,
                  height: 48,
                  decoration: BoxDecoration(
                    color: Colors.white.withValues(alpha: 0.9),
                    borderRadius: BorderRadius.circular(16),
                    border: Border.all(
                      color: Colors.white.withValues(alpha: 0.4),
                    ),
                  ),
                  child: const Icon(
                    LucideIcons.arrowUpRight,
                    color: Color(0xFF0C312B),
                    size: 20,
                  ),
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
        color: isDark ? const Color(0xFF1C4535) : const Color(0xFFF4EFE3),
        borderRadius: BorderRadius.circular(24),
        boxShadow: [
          BoxShadow(
            color: (isDark ? Colors.transparent : const Color(0xFF163A2C))
                .withOpacity(isDark ? 0.3 : 0.04),
            blurRadius: 20,
            offset: const Offset(0, 4),
          ),
        ],
        border: Border.all(
          color: (isDark ? Colors.white : const Color(0xFF0C312B)).withOpacity(
            0.05,
          ),
        ),
      ),
      child: Row(
        children: [
          // Left Thumbnail
          Container(
            width: 100,
            height: 100,
            decoration: BoxDecoration(borderRadius: BorderRadius.circular(16)),
            child: ClipRRect(
              borderRadius: BorderRadius.circular(16),
              child: _projListImage(imageUrl),
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
                  (project['title'] ?? 'M4 PROJECT').toString().toUpperCase(),
                  style: GoogleFonts.inter(
                    fontSize: 16,
                    fontWeight: FontWeight.w600,
                    color: isDark ? Colors.white : const Color(0xFF155A4F),
                    letterSpacing: -0.5,
                  ),
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                ),
                const SizedBox(height: 4),
                Row(
                  children: [
                    Icon(
                      LucideIcons.mapPin,
                      size: 12,
                      color: Theme.of(
                        context,
                      ).colorScheme.onSurface.withOpacity(0.4),
                    ),
                    const SizedBox(width: 4),
                    Expanded(
                      child: Text(
                        project['location']?['name'] ?? 'N/A',
                        style: GoogleFonts.inter(
                          fontSize: 11,
                          color: Theme.of(
                            context,
                          ).colorScheme.onSurface.withOpacity(0.72),
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
            child: Icon(
              LucideIcons.chevronRight,
              color: Theme.of(context).colorScheme.onSurface,
              size: 18,
            ),
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
        border: Border.all(
          color: Theme.of(context).colorScheme.onSurface.withOpacity(0.1),
        ),
      ),
      child: Text(
        text,
        style: GoogleFonts.inter(
          fontSize: 8,
          fontWeight: FontWeight.w600,
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
          style: GoogleFonts.gelasio(
            fontSize: 10,
            fontWeight: FontWeight.w700,
            color: Theme.of(context).colorScheme.onSurface.withOpacity(0.75),
            letterSpacing: 2,
          ),
        ),
        const SizedBox(height: 16),
        Wrap(
          spacing: 12,
          runSpacing: 12,
          children: options.map((opt) {
            final isSelected = selectedOptions.contains(opt);
            final isDarkMode = Theme.of(context).brightness == Brightness.dark;
            final onSurface = Theme.of(context).colorScheme.onSurface;
            return GestureDetector(
              onTap: () => onToggle(opt),
              child: AnimatedContainer(
                duration: const Duration(milliseconds: 200),
                padding: const EdgeInsets.symmetric(
                  horizontal: 22,
                  vertical: 14,
                ),
                // Web parity: white pill with soft shadow + dark text
                // (unselected); solid dark pill when selected.
                decoration: BoxDecoration(
                  color: isSelected
                      ? (isDarkMode ? Colors.white : Colors.black)
                      : (isDarkMode
                            ? Colors.white.withOpacity(0.06)
                            : Colors.white),
                  borderRadius: BorderRadius.circular(20),
                  border: Border.all(
                    color: isSelected
                        ? (isDarkMode ? Colors.white : Colors.black)
                        : onSurface.withOpacity(0.1),
                  ),
                  boxShadow: (isSelected || isDarkMode)
                      ? null
                      : [
                          BoxShadow(
                            color: Colors.black.withOpacity(0.05),
                            blurRadius: 12,
                            offset: const Offset(0, 4),
                          ),
                        ],
                ),
                child: Text(
                  opt.toUpperCase(),
                  style: GoogleFonts.inter(
                    fontSize: 9,
                    fontWeight: FontWeight.w600,
                    color: isSelected
                        ? (isDarkMode ? const Color(0xFF0C312B) : Colors.white)
                        : onSurface.withOpacity(0.85),
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

// Web parity: a single grid/list toggle button (active = filled).
class _ViewToggleButton extends StatelessWidget {
  final IconData icon;
  final bool active;
  final bool isDark;
  final VoidCallback onTap;
  const _ViewToggleButton({
    required this.icon,
    required this.active,
    required this.isDark,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    final Color fg = active
        ? (isDark ? Colors.black : Colors.white)
        : (isDark ? Colors.white : const Color(0xFF0C312B)).withOpacity(0.4);
    return GestureDetector(
      onTap: onTap,
      child: Container(
        width: 30,
        height: 26,
        alignment: Alignment.center,
        decoration: BoxDecoration(
          color: active
              ? (isDark ? Colors.white : const Color(0xFF0C312B))
              : Colors.transparent,
          borderRadius: BorderRadius.circular(8),
        ),
        // Figma parity: the grid glyph is a compact 2x2 of solid squares —
        // smaller and much heavier than Lucide's thin-stroke layoutGrid.
        child: icon == LucideIcons.layoutGrid
            ? _BoldGridGlyph(color: fg, size: 11)
            : Icon(icon, size: 15, color: fg),
      ),
    );
  }
}

// Figma parity: bold 2x2 grid mark used by the properties view toggle.
class _BoldGridGlyph extends StatelessWidget {
  final Color color;
  final double size;
  const _BoldGridGlyph({required this.color, required this.size});

  @override
  Widget build(BuildContext context) {
    // Gap between the four squares; the remainder is split evenly so the
    // mark stays optically centred inside the 30x26 toggle button. 11/3 keeps
    // each cell on a whole 4.0 logical pixels, so the mark stays crisp — and
    // the wider gutter reads as a crisper cross between smaller squares.
    const double gap = 3;
    final double cell = (size - gap) / 2;
    final BorderRadius radius = BorderRadius.circular(1);

    Widget square() => Container(
      width: cell,
      height: cell,
      decoration: BoxDecoration(color: color, borderRadius: radius),
    );

    return SizedBox(
      width: size,
      height: size,
      child: Column(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [square(), square()],
          ),
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [square(), square()],
          ),
        ],
      ),
    );
  }
}
