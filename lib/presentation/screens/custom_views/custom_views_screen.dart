import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:m4_mobile/core/utils/validators.dart';
import 'package:m4_mobile/presentation/providers/auth_provider.dart';
import 'package:m4_mobile/presentation/providers/custom_views_provider.dart';
import 'package:m4_mobile/presentation/providers/project_provider.dart';
import 'package:flutter_animate/flutter_animate.dart';
import 'package:lucide_icons/lucide_icons.dart';
import 'package:m4_mobile/presentation/widgets/side_menu_button.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:m4_mobile/presentation/widgets/conditional_drawer.dart';
import 'package:m4_mobile/presentation/widgets/main_shell.dart';
import 'package:m4_mobile/presentation/widgets/guest_main_shell.dart';
import 'package:go_router/go_router.dart';

class CustomViewsScreen extends ConsumerStatefulWidget {
  const CustomViewsScreen({super.key});

  @override
  ConsumerState<CustomViewsScreen> createState() => _CustomViewsScreenState();
}

class _CustomViewsScreenState extends ConsumerState<CustomViewsScreen> {
  @override
  void initState() {
    super.initState();
    // Web parity: auto-load the user's latest customization draft on entry so
    // project/unit/config resume seamlessly (web's fetchExistingCustomization).
    Future.microtask(_loadLatestCustomization);
  }

  Future<void> _loadLatestCustomization() async {
    // Don't override an explicit context (e.g. entered from My Custom Views).
    if (ref.read(customViewsProjectProvider) != null) return;
    try {
      final apiClient = ref.read(apiClientProvider);
      final res = await apiClient.getMyCustomViews();
      final data = res.data;
      final list = (data is Map ? (data['data'] ?? data) : data);
      if (list is List && list.isNotEmpty) {
        final existing = list[0] as Map;
        final project = existing['project'];
        final projectId = project is Map ? project['_id'] : project;
        if (projectId == null) return;

        ref.read(customViewsProjectProvider.notifier).state = projectId
            .toString();
        if (existing['unitType'] != null) {
          ref.read(customViewsUnitProvider.notifier).state =
              existing['unitType'].toString();
        }
        if (existing['unitNumber'] != null) {
          ref.read(customViewsUnitNumberProvider.notifier).state =
              existing['unitNumber'].toString();
        }
        if (existing['block'] != null) {
          ref.read(customViewsBlockProvider.notifier).state = existing['block']
              .toString();
        }
        if (existing['wing'] != null) {
          ref.read(customViewsWingProvider.notifier).state = existing['wing']
              .toString();
        }
        final selections = existing['selections'];
        if (selections is Map) {
          final sel = Map<String, dynamic>.from(selections);
          if (sel['space'] == null && existing['space'] != null) {
            sel['space'] = existing['space'];
          }
          if (sel['spaces'] == null && existing['space'] != null) {
            sel['spaces'] = existing['space']
                .toString()
                .split(',')
                .map((s) => s.trim())
                .where((s) => s.isNotEmpty)
                .toList();
          }
          ref.read(customViewsSelectionsProvider.notifier).state = sel;
        }

        // Web parity: resume at Select Space when a unit context is known.
        if (ref.read(customViewsStepProvider) == 0) {
          ref.read(customViewsStepProvider.notifier).state = 1;
        }
      }
    } catch (_) {
      // Ignore — fall back to fresh project selection.
    }
  }

  @override
  Widget build(BuildContext context) {
    final currentStep = ref.watch(customViewsStepProvider);
    final isSubmitted = false;

    return Scaffold(
      backgroundColor: Theme.of(context).scaffoldBackgroundColor,
      drawer: const ConditionalDrawer(),
      body: SafeArea(
        child: Column(
          children: [
            // Header
            Padding(
              padding: const EdgeInsets.fromLTRB(24, 20, 24, 20),
              child: Row(
                children: [
                  GestureDetector(
                    onTap: () {
                      if (currentStep > 0) {
                        ref.read(customViewsStepProvider.notifier).state =
                            currentStep - 1;
                      } else {
                        // Return to previous tab contextually
                        final prevIndex = ref.read(previousNavigationProvider);
                        ref.read(navigationProvider.notifier).state = prevIndex;
                      }
                    },
                    child: Container(
                      padding: const EdgeInsets.all(8),
                      decoration: BoxDecoration(
                        color: Theme.of(
                          context,
                        ).colorScheme.onSurface.withOpacity(0.05),
                        borderRadius: BorderRadius.circular(12),
                        border: Border.all(
                          color: Theme.of(
                            context,
                          ).colorScheme.onSurface.withOpacity(0.1),
                        ),
                      ),
                      child: Icon(
                        LucideIcons.arrowLeft,
                        size: 20,
                        color: Theme.of(context).colorScheme.onSurface,
                      ),
                    ),
                  ),
                  const SizedBox(width: 16),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.center,
                      children: [
                        Text(
                          'M4 CUSTOM VIEWS',
                          style: GoogleFonts.gelasio(
                            fontSize: 16,
                            fontWeight: FontWeight.w900,
                            color: Theme.of(context).colorScheme.onSurface,
                            letterSpacing: 1.5,
                          ),
                        ),
                        Text(
                          'PERSONALISATION SUITE',
                          style: GoogleFonts.gelasio(
                            fontSize: 8,
                            fontWeight: FontWeight.w900,
                            color: Theme.of(
                              context,
                            ).colorScheme.onSurface.withValues(alpha: 0.68),
                            letterSpacing: 5.5,
                          ),
                        ),
                      ],
                    ),
                  ),
                  const SideMenuButton(),
                ],
              ),
            ),
            Expanded(
              child: SingleChildScrollView(
                child: Column(
                  children: [
                    // Banner Section (always visible, exactly as Web CP)
                    Container(
                      height: 200,
                      width: double.infinity,
                      child: Stack(
                        fit: StackFit.expand,
                        children: [
                          // Web parity: same hero asset web uses (custom_view_1.png).
                          Image.asset(
                            'assets/custom_view_1.png',
                            fit: BoxFit.cover,
                            errorBuilder: (context, error, stackTrace) =>
                                Container(
                                  color: Theme.of(context).colorScheme.onSurface
                                      .withValues(alpha: 0.05),
                                ),
                          ),
                          Container(
                            decoration: BoxDecoration(
                              gradient: LinearGradient(
                                begin: Alignment.topCenter,
                                end: Alignment.bottomCenter,
                                colors: [
                                  Colors.transparent,
                                  Theme.of(context).scaffoldBackgroundColor
                                      .withValues(alpha: 0.4),
                                  Theme.of(context).scaffoldBackgroundColor,
                                ],
                              ),
                            ),
                          ),
                          Positioned(
                            bottom: 0,
                            left: 0,
                            right: 0,
                            child: Padding(
                              padding: const EdgeInsets.symmetric(
                                horizontal: 24,
                                vertical: 16,
                              ),
                              child: Column(
                                crossAxisAlignment: CrossAxisAlignment.center,
                                children: [
                                  Text(
                                    'PERSONALISE',
                                    style: GoogleFonts.gelasio(
                                      fontSize: 22,
                                      fontWeight: FontWeight.w400,
                                      color: Theme.of(
                                        context,
                                      ).colorScheme.onSurface,
                                      letterSpacing: 6,
                                      shadows: [
                                        Shadow(
                                          color:
                                              Theme.of(context).brightness ==
                                                  Brightness.light
                                              ? Colors.white.withOpacity(0.5)
                                              : Colors.black.withOpacity(0.5),
                                          offset: const Offset(0, 1),
                                          blurRadius: 4,
                                        ),
                                      ],
                                    ),
                                  ),
                                  Text(
                                    'YOUR LEGACY',
                                    style: GoogleFonts.gelasio(
                                      fontSize: 28,
                                      fontWeight: FontWeight.w900,
                                      color: Theme.of(
                                        context,
                                      ).colorScheme.onSurface,
                                      shadows: [
                                        Shadow(
                                          color:
                                              Theme.of(context).brightness ==
                                                  Brightness.light
                                              ? Colors.white.withOpacity(0.5)
                                              : Colors.black.withOpacity(0.5),
                                          offset: const Offset(0, 1),
                                          blurRadius: 4,
                                        ),
                                      ],
                                    ),
                                  ),
                                  const SizedBox(height: 8),
                                  Container(
                                    width: 40,
                                    height: 2,
                                    color: Theme.of(
                                      context,
                                    ).colorScheme.onSurface,
                                  ),
                                ],
                              ),
                            ),
                          ),
                        ],
                      ),
                    ),

                    // Overview Section
                    Padding(
                      padding: const EdgeInsets.fromLTRB(24, 24, 24, 8),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            'OVERVIEW',
                            style: GoogleFonts.gelasio(
                              fontSize: 10,
                              fontWeight: FontWeight.w900,
                              letterSpacing: 3,
                              color: Theme.of(context).colorScheme.onSurface,
                            ),
                          ),
                          const SizedBox(height: 16),
                          Text(
                            'Your home is a reflection of your soul. Experience total creative freedom in our Personalisation Suite. From master suites to bespoke kitchens, curate every detail of your future residence with real-time visualisation and elite material selections.',
                            style: GoogleFonts.ebGaramond(
                              fontSize: 14,
                              height: 1.7,
                              fontWeight: FontWeight.w500,
                              color: Theme.of(
                                context,
                              ).colorScheme.onSurface.withValues(alpha: 0.75),
                            ),
                          ),
                        ],
                      ),
                    ),

                    const SizedBox(height: 24),

                    // Journey Steps Track (4 steps with icons, exactly as Web CP)
                    Padding(
                      padding: const EdgeInsets.symmetric(horizontal: 24),
                      child: Row(
                        mainAxisAlignment: MainAxisAlignment.spaceBetween,
                        children: [
                          _StepIconIndicator(
                            index: 0,
                            title: 'PROJECT &\nUNIT',
                            icon: LucideIcons.building2,
                          ),
                          _StepIconIndicator(
                            index: 1,
                            title: 'SELECT\nSPACE',
                            icon: LucideIcons.home,
                          ),
                          _StepIconIndicator(
                            index: 2,
                            title: 'CHOOSE\nMATERIALS',
                            icon: LucideIcons.layers,
                          ),
                          _StepIconIndicator(
                            index: 3,
                            title: 'FINALISE',
                            icon: LucideIcons.check,
                          ),
                        ],
                      ),
                    ),

                    const SizedBox(height: 24),

                    // Wizard Content Card
                    Container(
                      margin: const EdgeInsets.symmetric(horizontal: 16),
                      padding: const EdgeInsets.all(28),
                      decoration: BoxDecoration(
                        color: Theme.of(context).brightness == Brightness.dark
                            ? const Color(0xFF18181B)
                            : Colors.white.withValues(alpha: 0.5),
                        borderRadius: BorderRadius.circular(40),
                        border: Border.all(
                          color: Theme.of(
                            context,
                          ).colorScheme.onSurface.withValues(alpha: 0.08),
                        ),
                        boxShadow: [
                          BoxShadow(
                            color: Colors.black.withValues(alpha: 0.04),
                            blurRadius: 24,
                            offset: const Offset(0, 12),
                          ),
                        ],
                      ),
                      child: Consumer(
                        builder: (context, ref, child) {
                          final currentStepVal = ref.watch(
                            customViewsStepProvider,
                          );
                          final activeStep = currentStepVal == -1
                              ? 0
                              : currentStepVal;
                          return Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              _buildStepWizardBody(activeStep),

                              const SizedBox(height: 32),

                              // Separator line before footer
                              Container(
                                height: 1,
                                color: Theme.of(
                                  context,
                                ).colorScheme.onSurface.withValues(alpha: 0.08),
                              ),
                              const SizedBox(height: 20),

                              // Navigation Footer — web parity: NEXT centered on
                              // top, BACK centered below (mobile flex-col-reverse).
                              SizedBox(
                                width: double.infinity,
                                child: Column(
                                  crossAxisAlignment: CrossAxisAlignment.center,
                                  verticalDirection: VerticalDirection.up,
                                  mainAxisSize: MainAxisSize.min,
                                  children: [
                                    GestureDetector(
                                      onTap: activeStep > 0
                                          ? () =>
                                                ref
                                                        .read(
                                                          customViewsStepProvider
                                                              .notifier,
                                                        )
                                                        .state =
                                                    activeStep - 1
                                          : null,
                                      child: Text(
                                        'BACK',
                                        style: GoogleFonts.gelasio(
                                          fontSize: 10,
                                          fontWeight: FontWeight.w900,
                                          color: activeStep > 0
                                              ? Theme.of(context)
                                                    .colorScheme
                                                    .onSurface
                                                    .withValues(alpha: 0.75)
                                              : Theme.of(context)
                                                    .colorScheme
                                                    .onSurface
                                                    .withValues(alpha: 0.68),
                                          letterSpacing: 2,
                                        ),
                                      ),
                                    ),
                                    const SizedBox(height: 18),
                                    GestureDetector(
                                      onTap: () async {
                                        if (activeStep < 3) {
                                          ref
                                                  .read(
                                                    customViewsStepProvider
                                                        .notifier,
                                                  )
                                                  .state =
                                              activeStep + 1;
                                        } else {
                                          final messenger =
                                              ScaffoldMessenger.of(context);
                                          try {
                                            final apiClient = ref.read(
                                              apiClientProvider,
                                            );
                                            final auth = ref.read(authProvider);
                                            final selectedProject = ref.read(
                                              customViewsProjectProvider,
                                            );
                                            final selectedUnit = ref.read(
                                              customViewsUnitProvider,
                                            );
                                            final selections = ref.read(
                                              customViewsSelectionsProvider,
                                            );

                                            final response = await apiClient
                                                .submitCustomViews({
                                                  'project': selectedProject,
                                                  'unitType': selectedUnit,
                                                  'unitNumber': ref.read(
                                                    customViewsUnitNumberProvider,
                                                  ),
                                                  'block': ref.read(
                                                    customViewsBlockProvider,
                                                  ),
                                                  'wing': ref.read(
                                                    customViewsWingProvider,
                                                  ),
                                                  'bookingId': ref.read(
                                                    customViewsBookingIdProvider,
                                                  ),
                                                  'space': selections['space'],
                                                  'selections': selections,
                                                  'guestName':
                                                      auth.identifier ??
                                                      'App Guest',
                                                  'guestPhone': 'N/A',
                                                  'guestEmail':
                                                      'app@m4family.com',
                                                  'status': 'SUBMITTED',
                                                });

                                            if (context.mounted) {
                                              if (response.data['status'] ==
                                                  true) {
                                                messenger.showSnackBar(
                                                  const SnackBar(
                                                    content: Text(
                                                      'Selections successfully saved!',
                                                    ),
                                                    backgroundColor:
                                                        Colors.green,
                                                  ),
                                                );
                                                ref
                                                        .read(
                                                          customViewsStepProvider
                                                              .notifier,
                                                        )
                                                        .state =
                                                    -1;
                                              }
                                            }
                                          } catch (e) {
                                            if (context.mounted)
                                              messenger.showSnackBar(
                                                const SnackBar(
                                                  content: Text(
                                                    'Failed to save selections.',
                                                  ),
                                                  backgroundColor: Colors.red,
                                                ),
                                              );
                                          }
                                        }
                                      },
                                      child: Container(
                                        padding: const EdgeInsets.symmetric(
                                          horizontal: 32,
                                          vertical: 14,
                                        ),
                                        decoration: BoxDecoration(
                                          color: Theme.of(
                                            context,
                                          ).colorScheme.onSurface,
                                          borderRadius: BorderRadius.circular(
                                            12,
                                          ),
                                        ),
                                        child: Text(
                                          activeStep < 3
                                              ? 'NEXT STEP'
                                              : 'CONFIRM SELECTIONS',
                                          style: GoogleFonts.gelasio(
                                            fontSize: 9,
                                            fontWeight: FontWeight.w900,
                                            color: Theme.of(
                                              context,
                                            ).colorScheme.surface,
                                            letterSpacing: 1.5,
                                          ),
                                        ),
                                      ),
                                    ),
                                  ],
                                ),
                              ),
                            ],
                          );
                        },
                      ),
                    ),

                    const SizedBox(height: 64),
                  ],
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildStepWizardBody(int step) {
    return AnimatedSwitcher(
      duration: const Duration(milliseconds: 300),
      child: () {
        switch (step) {
          case 0:
            return const _ProjectSelectionStep(key: ValueKey(0));
          case 1:
            return const _SpaceSelectionStep(key: ValueKey(1));
          case 2:
            return const _MaterialsSelectionStep(key: ValueKey(2));
          case 3:
            return const _FinaliseStep(key: ValueKey(3));
          default:
            return const SizedBox();
        }
      }(),
    );
  }
}

class _StepIconIndicator extends ConsumerWidget {
  final int index;
  final String title;
  final IconData icon;

  const _StepIconIndicator({
    required this.index,
    required this.title,
    required this.icon,
  });

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final currentStep = ref.watch(customViewsStepProvider);
    final activeStep = currentStep == -1 ? 0 : currentStep;
    final bookingId = ref.watch(customViewsBookingIdProvider);

    // Web logic: If bookingId exists, Step 0 is ALLOTTED and locked
    final bool isAllotted = bookingId != null && index == 0;
    final bool isFilled = activeStep >= index;
    final bool isActive = activeStep == index;

    final foreground = Theme.of(context).colorScheme.onSurface;
    final surface = Theme.of(context).colorScheme.surface;

    return GestureDetector(
      onTap: isAllotted
          ? null
          : () => ref.read(customViewsStepProvider.notifier).state = index,
      child: Opacity(
        opacity: isAllotted && !isActive ? 0.5 : 1.0,
        child: Column(
          children: [
            Container(
              padding: const EdgeInsets.all(14),
              decoration: BoxDecoration(
                color: isFilled ? foreground : Colors.transparent,
                borderRadius: BorderRadius.circular(16),
                border: Border.all(
                  color: isFilled ? foreground : foreground.withOpacity(0.12),
                ),
                boxShadow: isActive
                    ? [
                        BoxShadow(
                          color: foreground.withOpacity(0.12),
                          blurRadius: 12,
                          offset: const Offset(0, 5),
                        ),
                      ]
                    : null,
              ),
              child: Icon(
                isAllotted ? LucideIcons.check : icon,
                size: 24,
                color: isFilled ? surface : foreground,
              ),
            ),
            const SizedBox(height: 8),
            Text(
              isAllotted ? 'ALLOTTED' : title,
              textAlign: TextAlign.center,
              style: GoogleFonts.ebGaramond(
                fontSize: 9,
                fontWeight: FontWeight.w900,
                letterSpacing: 0.8,
                color: isFilled ? foreground : foreground.withOpacity(0.68),
              ),
            ),
          ],
        ),
      ),
    );
  }
}

// ======================== Step 0 ========================
class _ProjectSelectionStep extends ConsumerWidget {
  const _ProjectSelectionStep({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final projectsAsync = ref.watch(projectsProvider);
    final selectedProject = ref.watch(customViewsProjectProvider);
    final selectedUnit = ref.watch(customViewsUnitProvider);
    final scheme = Theme.of(context).colorScheme;

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          'PROJECT &\nUNIT',
          style: GoogleFonts.gelasio(
            fontSize: 28,
            fontWeight: FontWeight.w300,
            color: Theme.of(context).colorScheme.onSurface,
            height: 1.1,
          ),
        ),
        const SizedBox(height: 12),
        Text(
          'Select your project and unit\nconfiguration',
          style: GoogleFonts.ebGaramond(
            fontSize: 12,
            color: Theme.of(context).colorScheme.onSurface.withOpacity(0.68),
            height: 1.5,
          ),
        ),
        const SizedBox(height: 40),

        if (ref.watch(customViewsBookingIdProvider) != null) ...[
          Container(
            padding: const EdgeInsets.all(24),
            decoration: BoxDecoration(
              color: scheme.onSurface.withOpacity(0.05),
              borderRadius: BorderRadius.circular(24),
              border: Border.all(color: scheme.onSurface.withOpacity(0.1)),
            ),
            child: Row(
              children: [
                Icon(LucideIcons.checkCircle2, color: Colors.green, size: 20),
                const SizedBox(width: 16),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        'UNIT ALLOTTED',
                        style: GoogleFonts.ebGaramond(
                          fontSize: 10,
                          fontWeight: FontWeight.w900,
                          color: Colors.green,
                          letterSpacing: 1,
                        ),
                      ),
                      const SizedBox(height: 4),
                      Text(
                        'Your project and unit configuration are locked for this booking.',
                        style: GoogleFonts.ebGaramond(
                          fontSize: 11,
                          color: scheme.onSurface.withOpacity(0.68),
                        ),
                      ),
                    ],
                  ),
                ),
              ],
            ),
          ),
          const SizedBox(height: 32),
        ],

        // Projects List
        Row(
          children: [
            Icon(
              LucideIcons.building2,
              size: 14,
              color: Theme.of(context).colorScheme.onSurface.withOpacity(0.7),
            ),
            const SizedBox(width: 8),
            Text(
              'PROJECT SELECTION',
              style: GoogleFonts.gelasio(
                fontSize: 10,
                fontWeight: FontWeight.w900,
                letterSpacing: 2,
                color: Theme.of(context).colorScheme.onSurface,
              ),
            ),
          ],
        ),
        const SizedBox(height: 16),
        projectsAsync.when(
          data: (projects) => Column(
            children: projects.map<Widget>((p) {
              final isSelected = selectedProject == p['_id'];
              final isDark = Theme.of(context).brightness == Brightness.dark;
              return GestureDetector(
                onTap: () =>
                    ref.read(customViewsProjectProvider.notifier).state =
                        p['_id'],
                child: Container(
                  margin: const EdgeInsets.only(bottom: 16),
                  padding: const EdgeInsets.symmetric(
                    horizontal: 24,
                    vertical: 20,
                  ),
                  decoration: BoxDecoration(
                    color: isSelected ? scheme.onSurface : scheme.surface,
                    borderRadius: BorderRadius.circular(20),
                    border: Border.all(
                      color: scheme.onSurface.withValues(
                        alpha: isSelected ? 1 : 0.1,
                      ),
                    ),
                    boxShadow: isSelected
                        ? []
                        : [
                            BoxShadow(
                              color: Colors.black.withValues(alpha: 0.03),
                              blurRadius: 10,
                              offset: const Offset(0, 4),
                            ),
                          ],
                  ),
                  child: Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            p['title']?.toUpperCase() ?? 'PROJECT',
                            style: GoogleFonts.ebGaramond(
                              fontSize: 14,
                              fontWeight: FontWeight.w900,
                              color: isSelected
                                  ? scheme.surface
                                  : scheme.onSurface,
                              letterSpacing: 0.5,
                            ),
                          ),
                          const SizedBox(height: 4),
                          Text(
                            p['location']?['name']?.toUpperCase() ?? 'LOCATION',
                            style: GoogleFonts.gelasio(
                              fontSize: 8,
                              fontWeight: FontWeight.bold,
                              letterSpacing: 2,
                              color: isSelected
                                  ? scheme.surface.withValues(alpha: 0.7)
                                  : scheme.onSurface.withValues(alpha: 0.54),
                            ),
                          ),
                        ],
                      ),
                      if (isSelected)
                        Icon(
                          LucideIcons.check,
                          color: scheme.surface,
                          size: 20,
                        ),
                    ],
                  ),
                ),
              );
            }).toList(),
          ),
          loading: () => const Center(child: CircularProgressIndicator()),
          error: (e, s) => Text('Error: $e'),
        ),

        const SizedBox(height: 40),

        // Unit Config
        Row(
          children: [
            Icon(
              LucideIcons.layoutGrid,
              size: 14,
              color: Theme.of(context).colorScheme.onSurface.withOpacity(0.7),
            ),
            const SizedBox(width: 8),
            Text(
              'UNIT CONFIGURATION',
              style: GoogleFonts.gelasio(
                fontSize: 10,
                fontWeight: FontWeight.w900,
                letterSpacing: 2,
                color: Theme.of(context).colorScheme.onSurface,
              ),
            ),
          ],
        ),
        const SizedBox(height: 16),
        Wrap(
          spacing: 12,
          runSpacing: 12,
          children: ['1 BHK', '2 BHK', '3 BHK', '5 BHK'].map((unit) {
            final isSelected = selectedUnit == unit;
            final isDark = Theme.of(context).brightness == Brightness.dark;
            return GestureDetector(
              onTap: () =>
                  ref.read(customViewsUnitProvider.notifier).state = unit,
              child: Container(
                padding: const EdgeInsets.symmetric(
                  horizontal: 24,
                  vertical: 14,
                ),
                decoration: BoxDecoration(
                  color: isSelected
                      ? Theme.of(context).colorScheme.onBackground
                      : (isDark ? Colors.white : Colors.black).withOpacity(
                          0.04,
                        ),
                  borderRadius: BorderRadius.circular(12),
                  border: Border.all(
                    color: isSelected
                        ? Theme.of(context).colorScheme.onBackground
                        : (isDark ? Colors.white : Colors.black).withOpacity(
                            0.1,
                          ),
                  ),
                ),
                child: Text(
                  unit,
                  style: GoogleFonts.ebGaramond(
                    fontSize: 10,
                    fontWeight: FontWeight.w900,
                    letterSpacing: 1,
                    color: isSelected
                        ? Theme.of(context).colorScheme.background
                        : Theme.of(context).colorScheme.onSurface,
                  ),
                ),
              ),
            );
          }).toList(),
        ),

        const SizedBox(height: 32),

        // Web parity: Unit Number / Block-Tower / Wing fields with top divider.
        Container(
          padding: const EdgeInsets.only(top: 24),
          decoration: BoxDecoration(
            border: Border(
              top: BorderSide(color: scheme.onSurface.withValues(alpha: 0.08)),
            ),
          ),
          child: Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: const [
              Expanded(
                child: _UnitDetailField(
                  label: 'UNIT NUMBER',
                  hint: 'e.g. 101',
                  field: _UnitField.number,
                ),
              ),
              SizedBox(width: 12),
              Expanded(
                child: _UnitDetailField(
                  label: 'BLOCK / TOWER',
                  hint: 'e.g. A',
                  field: _UnitField.block,
                ),
              ),
              SizedBox(width: 12),
              Expanded(
                child: _UnitDetailField(
                  label: 'WING',
                  hint: 'e.g. B',
                  field: _UnitField.wing,
                ),
              ),
            ],
          ),
        ),
      ],
    ).animate().fadeIn();
  }
}

// Web parity: which detail field this input maps to.
enum _UnitField { number, block, wing }

class _UnitDetailField extends ConsumerStatefulWidget {
  final String label;
  final String hint;
  final _UnitField field;
  const _UnitDetailField({
    required this.label,
    required this.hint,
    required this.field,
  });

  @override
  ConsumerState<_UnitDetailField> createState() => _UnitDetailFieldState();
}

class _UnitDetailFieldState extends ConsumerState<_UnitDetailField> {
  late final TextEditingController _controller;

  StateProvider<String?> get _provider {
    switch (widget.field) {
      case _UnitField.number:
        return customViewsUnitNumberProvider;
      case _UnitField.block:
        return customViewsBlockProvider;
      case _UnitField.wing:
        return customViewsWingProvider;
    }
  }

  @override
  void initState() {
    super.initState();
    _controller = TextEditingController(text: ref.read(_provider));
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final scheme = Theme.of(context).colorScheme;
    final isDark = Theme.of(context).brightness == Brightness.dark;
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        // Fixed-height single-line label so all three inputs align on one row.
        SizedBox(
          height: 16,
          child: Padding(
            padding: const EdgeInsets.only(left: 4),
            child: FittedBox(
              fit: BoxFit.scaleDown,
              alignment: Alignment.centerLeft,
              child: Text(
                widget.label,
                maxLines: 1,
                style: GoogleFonts.ebGaramond(
                  fontSize: 9,
                  fontWeight: FontWeight.w900,
                  letterSpacing: 1.2,
                  color: scheme.onSurface.withValues(alpha: 0.65),
                ),
              ),
            ),
          ),
        ),
        const SizedBox(height: 8),
        Container(
          height: 44,
          decoration: BoxDecoration(
            color: (isDark ? Colors.white : Colors.black).withValues(
              alpha: 0.03,
            ),
            borderRadius: BorderRadius.circular(12),
            border: Border.all(color: scheme.onSurface.withValues(alpha: 0.1)),
          ),
          alignment: Alignment.center,
          child: TextField(
            controller: _controller,
            onChanged: (v) => ref.read(_provider.notifier).state = v,
            style: GoogleFonts.ebGaramond(
              fontSize: 15,
              fontWeight: FontWeight.w600,
              color: scheme.onSurface,
            ),
            decoration: InputDecoration(
              isCollapsed: true,
              contentPadding: const EdgeInsets.symmetric(horizontal: 12),
              border: InputBorder.none,
              hintText: widget.hint,
              hintStyle: GoogleFonts.ebGaramond(
                fontSize: 12,
                fontWeight: FontWeight.w500,
                color: scheme.onSurface.withValues(alpha: 0.68),
              ),
            ),
          ),
        ),
      ],
    );
  }
}

// Web parity: unique space names from the fetched config (categories[].spaces[].name).
List<String> configSpaceNames(Map<String, dynamic>? config) {
  if (config == null) return [];
  final set = <String>{};
  for (final c in ((config['categories'] as List?) ?? [])) {
    for (final s in (((c as Map)['spaces'] as List?) ?? [])) {
      final n = s is Map ? s['name'] : null;
      if (n != null) set.add(n.toString());
    }
  }
  return set.toList();
}

// ======================== Step 1 ========================
class _SpaceSelectionStep extends ConsumerWidget {
  const _SpaceSelectionStep({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final selections = ref.watch(customViewsSelectionsProvider);
    final scheme = Theme.of(context).colorScheme;
    final isDark = Theme.of(context).brightness == Brightness.dark;

    // Web reference: always present the 4 standard rooms as a 2x2 grid,
    // multi-select with a checkmark badge on each selected card.
    const spaces = [
      'Master Bedroom',
      'Living Hall',
      'Kitchen Space',
      'Guest Suite',
    ];

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        SizedBox(
          width: double.infinity,
          child: FittedBox(
            fit: BoxFit.scaleDown,
            alignment: Alignment.centerLeft,
            child: Text(
              'SELECT SPACE',
              maxLines: 1,
              style: GoogleFonts.gelasio(
                fontSize: 28,
                fontWeight: FontWeight.w300,
                color: scheme.onSurface,
                height: 1.1,
              ),
            ),
          ),
        ),
        const SizedBox(height: 12),
        Text(
          'Choose the area you want to personalise',
          style: GoogleFonts.ebGaramond(
            fontSize: 12,
            color: scheme.onSurface.withOpacity(0.54),
          ),
        ),
        const SizedBox(height: 40),
        GridView.count(
          shrinkWrap: true,
          physics: const NeverScrollableScrollPhysics(),
          clipBehavior: Clip.none,
          crossAxisCount: 2,
          mainAxisSpacing: 16,
          crossAxisSpacing: 16,
          childAspectRatio: 1.6,
          children: spaces.map((space) {
            final spacesList = selections['spaces'] is List
                ? List<String>.from(selections['spaces'])
                : <String>[];
            final isSelected = spacesList.contains(space);
            return GestureDetector(
              onTap: () {
                // Multi-select toggle (web reference behaviour).
                final next = List<String>.from(spacesList);
                if (next.contains(space)) {
                  next.remove(space);
                } else {
                  next.add(space);
                }
                final newSelections = Map<String, dynamic>.from(selections);
                newSelections['spaces'] = next;
                newSelections['space'] = next.join(', ');
                ref.read(customViewsSelectionsProvider.notifier).state =
                    newSelections;
                // Keep an active space pointer for later steps.
                if (next.isNotEmpty) {
                  ref.read(customViewsActiveSpaceProvider.notifier).state =
                      next.first;
                }
              },
              child: AnimatedScale(
                scale: isSelected ? 1.05 : 1.0,
                duration: const Duration(milliseconds: 200),
                child: Container(
                  padding: const EdgeInsets.all(20),
                  decoration: BoxDecoration(
                    color: isSelected ? scheme.onSurface : Colors.transparent,
                    borderRadius: BorderRadius.circular(16),
                    border: Border.all(
                      color: isSelected
                          ? scheme.onSurface
                          : (isDark ? Colors.white : Colors.black).withOpacity(
                              0.1,
                            ),
                    ),
                    boxShadow: isSelected
                        ? [
                            BoxShadow(
                              color: Colors.black.withOpacity(0.18),
                              blurRadius: 20,
                              offset: const Offset(0, 8),
                            ),
                          ]
                        : null,
                  ),
                  child: Stack(
                    clipBehavior: Clip.none,
                    children: [
                      Center(
                        child: Text(
                          space.toUpperCase(),
                          textAlign: TextAlign.center,
                          style: GoogleFonts.ebGaramond(
                            fontSize: 13,
                            fontWeight: FontWeight.w800,
                            letterSpacing: 1.2,
                            height: 1.15,
                            color: isSelected
                                ? scheme.surface
                                : scheme.onSurface,
                          ),
                        ),
                      ),
                      // Web parity: checkmark badge on the selected card.
                      if (isSelected)
                        Positioned(
                          top: -4,
                          right: -4,
                          child: Container(
                            width: 16,
                            height: 16,
                            decoration: BoxDecoration(
                              color: scheme.surface,
                              shape: BoxShape.circle,
                              boxShadow: [
                                BoxShadow(
                                  color: Colors.black.withOpacity(0.2),
                                  blurRadius: 4,
                                ),
                              ],
                            ),
                            child: Icon(
                              LucideIcons.check,
                              size: 10,
                              color: scheme.onSurface,
                            ),
                          ),
                        ),
                    ],
                  ),
                ),
              ),
            );
          }).toList(),
        ),
      ],
    ).animate().fadeIn();
  }
}

// ======================== Step 2 ========================
class _MaterialsSelectionStep extends ConsumerWidget {
  const _MaterialsSelectionStep({super.key});

  Color _hexToColor(String hexString) {
    final buffer = StringBuffer();
    if (hexString.length == 6 || hexString.length == 7) buffer.write('ff');
    buffer.write(hexString.replaceFirst('#', ''));
    return Color(int.parse(buffer.toString(), radix: 16));
  }

  // Web parity: category icon by title (tile->layers, paint->bucket, door->box).
  IconData _categoryIcon(String? title) {
    final t = (title ?? '').toLowerCase();
    if (t.contains('tile')) return LucideIcons.layers;
    if (t.contains('paint')) return LucideIcons.paintBucket;
    if (t.contains('door')) return LucideIcons.box;
    return LucideIcons.palette;
  }

  // Normalized categories {_id, title, options} for a space (config or generic).
  List<Map<String, dynamic>> _catsForSpace(
    Map<String, dynamic>? config,
    List genericCats,
    String space,
  ) {
    if (config != null && (config['categories'] as List?)?.isNotEmpty == true) {
      final result = <Map<String, dynamic>>[];
      for (final c in ((config['categories'] as List?) ?? [])) {
        final catObj = (c as Map)['category'];
        final catId =
            (catObj is Map ? catObj['_id'] : catObj)?.toString() ?? '';
        final catTitle = catObj is Map
            ? (catObj['title'] ?? 'Category')
            : 'Category';
        List options = [];
        for (final s in ((c['spaces'] as List?) ?? [])) {
          if (s is Map && s['name'] == space) {
            options = (s['options'] as List?) ?? [];
            break;
          }
        }
        if (options.isNotEmpty) {
          result.add({'_id': catId, 'title': catTitle, 'options': options});
        }
      }
      if (result.isNotEmpty) return result;
      // No config match for this room → fall back to generic categories.
    }
    return genericCats
        .map<Map<String, dynamic>>(
          (cat) => {
            '_id': cat['_id']?.toString() ?? '',
            'title': cat['title'] ?? 'Category',
            'options': (cat['options'] as List?) ?? [],
          },
        )
        .where((c) => (c['options'] as List).isNotEmpty)
        .toList();
  }

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final optionsAsync = ref.watch(customizationOptionsProvider);
    final selections = ref.watch(customViewsSelectionsProvider);
    final scheme = Theme.of(context).colorScheme;
    final config = ref.watch(customViewsConfigProvider).valueOrNull;
    final genericCats = optionsAsync.asData?.value ?? [];

    // Room tabs mirror the rooms selected on the SELECT SPACE step.
    final isConfigMode = configSpaceNames(config).isNotEmpty;
    final spacesList = selections['spaces'] is List
        ? List<String>.from(selections['spaces'])
        : <String>[];
    final activeSpace =
        ref.watch(customViewsActiveSpaceProvider) ??
        (spacesList.isNotEmpty ? spacesList.first : 'Full Unit');

    final spaceSel = selections[activeSpace] is Map
        ? Map<String, dynamic>.from(selections[activeSpace])
        : <String, dynamic>{};
    final activeCats = _catsForSpace(config, genericCats, activeSpace);

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          'CHOOSE\nMATERIALS',
          style: GoogleFonts.gelasio(
            fontSize: 28,
            fontWeight: FontWeight.w300,
            color: scheme.onSurface,
            height: 1.1,
          ),
        ),
        const SizedBox(height: 12),
        Text(
          'Select from our curated collection',
          style: GoogleFonts.ebGaramond(
            fontSize: 12,
            color: scheme.onSurface.withOpacity(0.54),
          ),
        ),
        const SizedBox(height: 32),
        if (!isConfigMode && optionsAsync.isLoading)
          const Center(child: CircularProgressIndicator())
        else
          Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // Web parity: horizontal room tab bar with completion count.
              if (spacesList.isNotEmpty)
                Container(
                  margin: const EdgeInsets.only(bottom: 32),
                  padding: const EdgeInsets.only(bottom: 12),
                  decoration: BoxDecoration(
                    border: Border(
                      bottom: BorderSide(
                        color: scheme.onSurface.withOpacity(0.12),
                      ),
                    ),
                  ),
                  child: SingleChildScrollView(
                    scrollDirection: Axis.horizontal,
                    child: Row(
                      children: spacesList.map((room) {
                        final isActive = activeSpace == room;
                        final roomSel = selections[room] is Map
                            ? Map<String, dynamic>.from(selections[room])
                            : <String, dynamic>{};
                        final selected = roomSel.length;
                        final total = _catsForSpace(
                          config,
                          genericCats,
                          room,
                        ).length;
                        return Padding(
                          padding: const EdgeInsets.only(right: 8),
                          child: GestureDetector(
                            onTap: () =>
                                ref
                                        .read(
                                          customViewsActiveSpaceProvider
                                              .notifier,
                                        )
                                        .state =
                                    room,
                            child: Container(
                              padding: const EdgeInsets.symmetric(
                                horizontal: 18,
                                vertical: 12,
                              ),
                              decoration: BoxDecoration(
                                color: isActive
                                    ? scheme.onSurface
                                    : scheme.onSurface.withOpacity(0.04),
                                borderRadius: BorderRadius.circular(12),
                                border: Border.all(
                                  color: isActive
                                      ? scheme.onSurface
                                      : scheme.onSurface.withOpacity(0.1),
                                ),
                              ),
                              child: Row(
                                children: [
                                  Text(
                                    room.toUpperCase(),
                                    style: GoogleFonts.ebGaramond(
                                      fontSize: 10,
                                      fontWeight: FontWeight.w800,
                                      letterSpacing: 1.2,
                                      color: isActive
                                          ? scheme.surface
                                          : scheme.onSurface.withOpacity(0.6),
                                    ),
                                  ),
                                  const SizedBox(width: 8),
                                  Container(
                                    padding: const EdgeInsets.symmetric(
                                      horizontal: 6,
                                      vertical: 2,
                                    ),
                                    decoration: BoxDecoration(
                                      color: isActive
                                          ? scheme.surface.withOpacity(0.2)
                                          : scheme.onSurface.withOpacity(0.1),
                                      borderRadius: BorderRadius.circular(20),
                                    ),
                                    child: Text(
                                      '$selected/$total',
                                      style: GoogleFonts.ebGaramond(
                                        fontSize: 9,
                                        fontWeight: FontWeight.w900,
                                        color: isActive
                                            ? scheme.surface
                                            : scheme.onSurface,
                                      ),
                                    ),
                                  ),
                                ],
                              ),
                            ),
                          ),
                        );
                      }).toList(),
                    ),
                  ),
                ),

              // Web parity: empty state when this space has no options.
              if (activeCats.isEmpty)
                Padding(
                  padding: const EdgeInsets.symmetric(vertical: 40),
                  child: Center(
                    child: Text(
                      'No materials available for this space.',
                      style: GoogleFonts.ebGaramond(
                        fontSize: 12,
                        color: scheme.onSurface.withOpacity(0.68),
                      ),
                    ),
                  ),
                ),
              // Categories with option cards (per active space).
              ...activeCats.map<Widget>((cat) {
                final catId = cat['_id'];
                final options = (cat['options'] as List?) ?? [];
                if (options.isEmpty) return const SizedBox.shrink();
                return Padding(
                  padding: const EdgeInsets.only(bottom: 32),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      // Web parity: icon circle + title + "Select materials for X".
                      Row(
                        children: [
                          Container(
                            width: 40,
                            height: 40,
                            decoration: BoxDecoration(
                              color: scheme.onSurface.withOpacity(0.06),
                              borderRadius: BorderRadius.circular(14),
                              border: Border.all(
                                color: scheme.onSurface.withOpacity(0.12),
                              ),
                            ),
                            child: Icon(
                              _categoryIcon(cat['title']),
                              size: 18,
                              color: scheme.onSurface,
                            ),
                          ),
                          const SizedBox(width: 14),
                          Expanded(
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Text(
                                  (cat['title']?.toUpperCase() ?? 'CATEGORY'),
                                  style: GoogleFonts.gelasio(
                                    fontSize: 12,
                                    fontWeight: FontWeight.w900,
                                    letterSpacing: 2,
                                    color: scheme.onSurface,
                                  ),
                                ),
                                const SizedBox(height: 3),
                                Text(
                                  'SELECT MATERIALS FOR ${activeSpace.toUpperCase()}',
                                  style: GoogleFonts.ebGaramond(
                                    fontSize: 8,
                                    fontWeight: FontWeight.w600,
                                    letterSpacing: 1.2,
                                    color: scheme.onSurface.withOpacity(0.68),
                                  ),
                                ),
                              ],
                            ),
                          ),
                        ],
                      ),
                      const SizedBox(height: 16),
                      GridView.builder(
                        shrinkWrap: true,
                        physics: const NeverScrollableScrollPhysics(),
                        gridDelegate:
                            const SliverGridDelegateWithFixedCrossAxisCount(
                              crossAxisCount: 2,
                              childAspectRatio: 0.78,
                              crossAxisSpacing: 12,
                              mainAxisSpacing: 12,
                            ),
                        itemCount: options.length,
                        itemBuilder: (context, index) {
                          final opt = options[index];
                          final isSelected =
                              spaceSel[catId]?['name'] == opt['name'];

                          return GestureDetector(
                            onTap: () {
                              final newSelections = Map<String, dynamic>.from(
                                selections,
                              );
                              final roomMap = Map<String, dynamic>.from(
                                newSelections[activeSpace] is Map
                                    ? newSelections[activeSpace]
                                    : {},
                              );
                              roomMap[catId] = opt;
                              newSelections[activeSpace] = roomMap;
                              ref
                                      .read(
                                        customViewsSelectionsProvider.notifier,
                                      )
                                      .state =
                                  newSelections;
                            },
                            child: Container(
                              padding: const EdgeInsets.all(10),
                              decoration: BoxDecoration(
                                color: isSelected
                                    ? scheme.onSurface.withOpacity(0.04)
                                    : scheme.onSurface.withOpacity(0.02),
                                borderRadius: BorderRadius.circular(20),
                                border: Border.all(
                                  color: isSelected
                                      ? scheme.onSurface
                                      : scheme.onSurface.withOpacity(0.1),
                                  width: isSelected ? 1.5 : 1,
                                ),
                              ),
                              child: Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  // Web parity: 4:3 swatch (color/image).
                                  AspectRatio(
                                    aspectRatio: 4 / 3,
                                    child: Stack(
                                      fit: StackFit.expand,
                                      children: [
                                        ClipRRect(
                                          borderRadius: BorderRadius.circular(
                                            12,
                                          ),
                                          child: opt['colorCode'] != null
                                              ? Container(
                                                  color: _hexToColor(
                                                    opt['colorCode'],
                                                  ),
                                                )
                                              : opt['image'] != null
                                              ? Image.network(
                                                  opt['image'],
                                                  fit: BoxFit.cover,
                                                  errorBuilder:
                                                      (
                                                        context,
                                                        error,
                                                        stackTrace,
                                                      ) => Container(
                                                        color: scheme.onSurface
                                                            .withOpacity(0.05),
                                                        child: Icon(
                                                          LucideIcons.image,
                                                          color: scheme
                                                              .onSurface
                                                              .withOpacity(0.2),
                                                        ),
                                                      ),
                                                )
                                              : Container(
                                                  color: scheme.onSurface
                                                      .withOpacity(0.05),
                                                  child: Icon(
                                                    LucideIcons.box,
                                                    color: scheme.onSurface
                                                        .withOpacity(0.2),
                                                  ),
                                                ),
                                        ),
                                        if (isSelected)
                                          Positioned(
                                            top: 8,
                                            right: 8,
                                            child: Container(
                                              width: 22,
                                              height: 22,
                                              decoration: BoxDecoration(
                                                color: scheme.onSurface,
                                                shape: BoxShape.circle,
                                                border: Border.all(
                                                  color: scheme.surface,
                                                ),
                                              ),
                                              child: Icon(
                                                LucideIcons.check,
                                                size: 12,
                                                color: scheme.surface,
                                              ),
                                            ),
                                          ),
                                      ],
                                    ),
                                  ),
                                  const SizedBox(height: 10),
                                  Text(
                                    opt['name']?.toUpperCase() ?? '',
                                    maxLines: 1,
                                    overflow: TextOverflow.ellipsis,
                                    style: GoogleFonts.ebGaramond(
                                      fontSize: 10,
                                      fontWeight: FontWeight.w800,
                                      letterSpacing: 0.3,
                                      color: scheme.onSurface,
                                    ),
                                  ),
                                  const SizedBox(height: 6),
                                  // Web parity: materialCode / materialType footer.
                                  Container(
                                    padding: const EdgeInsets.only(top: 6),
                                    decoration: BoxDecoration(
                                      border: Border(
                                        top: BorderSide(
                                          color: scheme.onSurface.withOpacity(
                                            0.08,
                                          ),
                                        ),
                                      ),
                                    ),
                                    child: Row(
                                      mainAxisAlignment:
                                          MainAxisAlignment.spaceBetween,
                                      children: [
                                        Text(
                                          opt['materialCode'] ?? 'M4-STD',
                                          style: GoogleFonts.ebGaramond(
                                            fontSize: 8,
                                            fontWeight: FontWeight.w700,
                                            letterSpacing: 1,
                                            color: scheme.onSurface.withOpacity(
                                              0.68,
                                            ),
                                          ),
                                        ),
                                        Text(
                                          opt['materialType'] ?? 'MATTE',
                                          style: GoogleFonts.ebGaramond(
                                            fontSize: 8,
                                            fontWeight: FontWeight.w700,
                                            letterSpacing: 1,
                                            color: scheme.onSurface.withOpacity(
                                              0.68,
                                            ),
                                          ),
                                        ),
                                      ],
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
                );
              }),
              // Web parity: "Ready to Proceed?" + Finalise Selections shortcut.
              Padding(
                padding: const EdgeInsets.only(top: 16),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.center,
                  children: [
                    Text(
                      'READY TO PROCEED?',
                      style: GoogleFonts.gelasio(
                        fontSize: 10,
                        fontWeight: FontWeight.w900,
                        letterSpacing: 3,
                        color: scheme.onSurface.withOpacity(0.68),
                      ),
                    ),
                    const SizedBox(height: 8),
                    Text(
                      'Review your choices in the final step',
                      style: GoogleFonts.ebGaramond(
                        fontSize: 11,
                        fontStyle: FontStyle.italic,
                        color: scheme.onSurface.withOpacity(0.68),
                      ),
                    ),
                    const SizedBox(height: 20),
                    GestureDetector(
                      onTap: () =>
                          ref.read(customViewsStepProvider.notifier).state = 3,
                      child: Container(
                        width: double.infinity,
                        height: 54,
                        decoration: BoxDecoration(
                          color: scheme.onSurface,
                          borderRadius: BorderRadius.circular(16),
                        ),
                        child: Row(
                          mainAxisAlignment: MainAxisAlignment.center,
                          children: [
                            Text(
                              'FINALISE SELECTIONS',
                              style: GoogleFonts.gelasio(
                                fontSize: 11,
                                fontWeight: FontWeight.w900,
                                letterSpacing: 2,
                                color: scheme.surface,
                              ),
                            ),
                            const SizedBox(width: 10),
                            Icon(
                              LucideIcons.arrowRight,
                              size: 16,
                              color: scheme.surface,
                            ),
                          ],
                        ),
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ),
      ],
    ).animate().fadeIn();
  }
}

// ======================== Step 3 ========================
class _FinaliseStep extends ConsumerWidget {
  const _FinaliseStep({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final selections = ref.watch(customViewsSelectionsProvider);
    final projectsAsync = ref.watch(projectsProvider);
    final selectedProject = ref.watch(customViewsProjectProvider);
    final selectedUnit = ref.watch(customViewsUnitProvider);
    final optionsAsync = ref.watch(customizationOptionsProvider);
    final unitNumber = ref.watch(customViewsUnitNumberProvider);
    final block = ref.watch(customViewsBlockProvider);
    final wing = ref.watch(customViewsWingProvider);
    final config = ref.watch(customViewsConfigProvider).valueOrNull;

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          'FINALISE',
          style: GoogleFonts.gelasio(
            fontSize: 28,
            fontWeight: FontWeight.w300,
            color: Theme.of(context).colorScheme.onSurface,
          ),
        ),
        const SizedBox(height: 12),
        Text(
          'Confirm your selections',
          style: GoogleFonts.ebGaramond(
            fontSize: 12,
            color: Theme.of(context).colorScheme.onSurface.withOpacity(0.75),
          ),
        ),
        const SizedBox(height: 40),

        Container(
          decoration: BoxDecoration(
            color: Theme.of(context).colorScheme.onSurface.withOpacity(0.02),
            border: Border.all(
              color: Theme.of(context).colorScheme.onSurface.withOpacity(0.1),
            ),
            borderRadius: BorderRadius.circular(24),
          ),
          clipBehavior: Clip.antiAlias,
          child: Column(
            children: [
              Container(
                padding: const EdgeInsets.symmetric(
                  horizontal: 24,
                  vertical: 16,
                ),
                // Whiter header background so the labels read clearly.
                color: Theme.of(context).colorScheme.surface,
                child: Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Text(
                      'ITEM',
                      style: GoogleFonts.gelasio(
                        fontSize: 10,
                        fontWeight: FontWeight.w900,
                        letterSpacing: 2,
                        color: Theme.of(
                          context,
                        ).colorScheme.onSurface.withOpacity(0.9),
                      ),
                    ),
                    Text(
                      'SELECTION',
                      style: GoogleFonts.gelasio(
                        fontSize: 10,
                        fontWeight: FontWeight.w900,
                        letterSpacing: 2,
                        color: Theme.of(
                          context,
                        ).colorScheme.onSurface.withOpacity(0.9),
                      ),
                    ),
                  ],
                ),
              ),
              // Web parity: Project / Unit Number / Configuration / Block / Wing.
              _SummaryRow(
                label: 'Project',
                value: projectsAsync.maybeWhen(
                  data: (p) => p.firstWhere(
                    (e) => e['_id'] == selectedProject,
                    orElse: () => {'title': 'Standard'},
                  )['title'],
                  orElse: () => 'Standard',
                ),
              ),
              _SummaryRow(
                label: 'Unit Number',
                value: (unitNumber == null || unitNumber.isEmpty)
                    ? 'N/A'
                    : unitNumber,
              ),
              _SummaryRow(label: 'Configuration', value: selectedUnit),
              _SummaryRow(
                label: 'Block / Tower',
                value: (block == null || block.isEmpty) ? 'N/A' : block,
              ),
              _SummaryRow(
                label: 'Wing',
                value: (wing == null || wing.isEmpty) ? 'N/A' : wing,
              ),
              // Web parity: iterate ALL selection entries — per-space maps
              // ({space: {catId: opt}}) and flat ({catId: opt}) selections.
              ...(() {
                String catTitleFor(dynamic catId) {
                  String title = catId.toString();
                  optionsAsync.maybeWhen(
                    data: (cats) {
                      final cat = cats.firstWhere(
                        (c) => c['_id'] == catId,
                        orElse: () => null,
                      );
                      if (cat != null) title = cat['title'];
                    },
                    orElse: () {},
                  );
                  return title;
                }

                final rows = <Widget>[];
                selections.forEach((key, val) {
                  if (key == 'space' || key == 'spaces' || key == 'status') {
                    return;
                  }
                  if (val is Map && val['_id'] == null && val['name'] == null) {
                    // Per-space map: {catId: opt}.
                    val.forEach((catId, opt) {
                      if (opt is Map && opt['name'] != null) {
                        rows.add(
                          _SummaryRow(
                            label: '$key / ${catTitleFor(catId)}'.toUpperCase(),
                            value: opt['name'].toString(),
                          ),
                        );
                      }
                    });
                  } else if (val is Map && val['name'] != null) {
                    // Flat: catId -> opt.
                    rows.add(
                      _SummaryRow(
                        label: catTitleFor(key).toUpperCase(),
                        value: val['name'].toString(),
                      ),
                    );
                  }
                });
                return rows;
              })(),
            ],
          ),
        ),
      ],
    ).animate().fadeIn();
  }
}

class _SummaryRow extends StatelessWidget {
  final String label;
  final String value;
  final String? subValue;

  const _SummaryRow({required this.label, required this.value, this.subValue});

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 16),
      decoration: BoxDecoration(
        border: Border(
          top: BorderSide(
            color: (isDark ? Colors.white : Colors.black).withOpacity(0.09),
          ),
        ),
      ),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Expanded(
            child: Text(
              label,
              style: GoogleFonts.ebGaramond(
                fontSize: 11,
                fontWeight: FontWeight.w700,
                color: Theme.of(context).colorScheme.onSurface.withOpacity(0.9),
              ),
            ),
          ),
          Column(
            crossAxisAlignment: CrossAxisAlignment.end,
            children: [
              Text(
                value.toUpperCase(),
                style: GoogleFonts.ebGaramond(
                  fontSize: 11,
                  fontWeight: FontWeight.bold,
                  color: Theme.of(context).colorScheme.onSurface,
                  letterSpacing: 0,
                ),
              ),
              if (subValue != null)
                Text(
                  subValue!,
                  style: GoogleFonts.ebGaramond(
                    fontSize: 9,
                    fontWeight: FontWeight.bold,
                    color: Theme.of(context).colorScheme.tertiary,
                  ),
                ),
            ],
          ),
        ],
      ),
    );
  }
}

// ======================== Additional Sections ========================

class _PremiumMaterialsSection extends StatelessWidget {
  const _PremiumMaterialsSection();

  @override
  Widget build(BuildContext context) {
    final List<Map<String, String>> materials = [
      {
        "title": "& Marble Variants",
        "img":
            "https://images.unsplash.com/photo-1600585154340-be6161a56a0c?auto=format&fit=crop&q=80",
        "count": "12+ VARIANTS",
      },
      {
        "title": "Best Wood Textures",
        "img":
            "https://images.unsplash.com/photo-1541888946425-d81bb19240f5?auto=format&fit=crop&q=80",
        "count": "8+ TEXTURES",
      },
      {
        "title": "Elite Finishes",
        "img":
            "https://images.unsplash.com/photo-1600607687939-ce8a6c25118c?auto=format&fit=crop&q=80",
        "count": "20+ OPTIONS",
      },
    ];

    return Column(
      children: [
        Text(
          'THE COLLECTION',
          style: GoogleFonts.gelasio(
            fontSize: 10,
            fontWeight: FontWeight.w900,
            letterSpacing: 4,
            color: Theme.of(context).colorScheme.onSurface.withOpacity(0.54),
          ),
        ),
        const SizedBox(height: 8),
        Text(
          'PREMIUM\nMATERIALS',
          textAlign: TextAlign.center,
          style: GoogleFonts.gelasio(
            fontSize: 32,
            fontWeight: FontWeight.w300,
            color: Theme.of(context).colorScheme.onSurface,
            height: 1.1,
          ),
        ),
        const SizedBox(height: 48),
        SizedBox(
          height: 180,
          child: ListView.separated(
            padding: const EdgeInsets.symmetric(horizontal: 24),
            scrollDirection: Axis.horizontal,
            itemCount: materials.length,
            separatorBuilder: (context, index) => const SizedBox(width: 16),
            itemBuilder: (context, index) {
              final mat = materials[index];
              return Container(
                width: 120, // Arch shape mimicking web
                child: Stack(
                  fit: StackFit.expand,
                  children: [
                    ClipRRect(
                      borderRadius: const BorderRadius.vertical(
                        top: Radius.circular(60),
                        bottom: Radius.circular(60),
                      ),
                      child: Image.network(
                        mat['img']!,
                        fit: BoxFit.cover,
                        errorBuilder: (context, error, stackTrace) => Container(
                          color: Colors.black.withOpacity(0.05),
                          child: const Center(
                            child: Icon(
                              LucideIcons.image,
                              color: Colors.black12,
                            ),
                          ),
                        ),
                      ),
                    ),
                    Container(
                      decoration: BoxDecoration(
                        borderRadius: const BorderRadius.vertical(
                          top: Radius.circular(60),
                          bottom: Radius.circular(60),
                        ),
                        gradient: LinearGradient(
                          begin: Alignment.bottomCenter,
                          end: Alignment.topCenter,
                          colors: [
                            Theme.of(
                              context,
                            ).colorScheme.onSurface.withOpacity(0.8),
                            Colors.transparent,
                          ],
                        ),
                      ),
                      padding: const EdgeInsets.all(16),
                      child: Column(
                        mainAxisAlignment: MainAxisAlignment.end,
                        children: [
                          Text(
                            mat['title']!,
                            textAlign: TextAlign.center,
                            style: GoogleFonts.ebGaramond(
                              fontSize: 10,
                              fontWeight: FontWeight.bold,
                              color: Theme.of(context).colorScheme.background,
                            ),
                          ),
                          const SizedBox(height: 4),
                          Text(
                            mat['count']!,
                            style: GoogleFonts.gelasio(
                              fontSize: 7,
                              fontWeight: FontWeight.bold,
                              color: Theme.of(
                                context,
                              ).colorScheme.background.withOpacity(0.54),
                              letterSpacing: 1.5,
                            ),
                          ),
                        ],
                      ),
                    ),
                  ],
                ),
              );
            },
          ),
        ),
      ],
    );
  }
}

class _ConsultationSection extends ConsumerWidget {
  const _ConsultationSection();

  void _showConsultationDialog(BuildContext context, WidgetRef ref) {
    final nameController = TextEditingController();
    final phoneController = TextEditingController();
    final emailController = TextEditingController();
    bool isLoading = false;

    showDialog(
      context: context,
      builder: (context) => StatefulBuilder(
        builder: (context, setState) => Dialog(
          backgroundColor: Colors.transparent,
          insetPadding: const EdgeInsets.symmetric(horizontal: 24),
          child: Container(
            width: double.infinity,
            padding: const EdgeInsets.all(24),
            decoration: BoxDecoration(
              color: Theme.of(context).colorScheme.surface,
              borderRadius: BorderRadius.circular(32),
              border: Border.all(
                color: Theme.of(context).colorScheme.onSurface.withOpacity(0.1),
              ),
            ),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Text(
                      'Book a Consultation',
                      style: GoogleFonts.gelasio(
                        fontSize: 20,
                        fontWeight: FontWeight.bold,
                        color: Theme.of(context).colorScheme.onSurface,
                      ),
                    ),
                    GestureDetector(
                      onTap: () => Navigator.pop(context),
                      child: Icon(
                        LucideIcons.x,
                        color: Theme.of(
                          context,
                        ).colorScheme.onSurface.withOpacity(0.54),
                        size: 20,
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 8),
                Text(
                  'Leave your details with us and our elite interior design team will be in touch shortly.',
                  style: GoogleFonts.ebGaramond(
                    fontSize: 10,
                    color: Theme.of(
                      context,
                    ).colorScheme.onSurface.withOpacity(0.54),
                    height: 1.5,
                  ),
                ),
                const SizedBox(height: 32),
                _buildField(
                  context,
                  'FULL NAME',
                  LucideIcons.user,
                  nameController,
                  keyboardType: TextInputType.name,
                  inputFormatters: Validators.nameFormatters,
                ),
                _buildField(
                  context,
                  'PHONE NUMBER',
                  LucideIcons.phone,
                  phoneController,
                  keyboardType: TextInputType.phone,
                  inputFormatters: Validators.phoneFormatters,
                ),
                _buildField(
                  context,
                  'EMAIL (OPTIONAL)',
                  LucideIcons.mail,
                  emailController,
                  keyboardType: TextInputType.emailAddress,
                  inputFormatters: Validators.emailFormatters,
                ),
                const SizedBox(height: 32),
                GestureDetector(
                  onTap: isLoading
                      ? null
                      : () async {
                          final vErr =
                              Validators.nameError(
                                nameController.text,
                                field: 'full name',
                              ) ??
                              Validators.phoneError(phoneController.text) ??
                              (emailController.text.trim().isEmpty
                                  ? null
                                  : Validators.emailError(
                                      emailController.text,
                                    ));
                          if (vErr != null) {
                            ScaffoldMessenger.of(context).showSnackBar(
                              SnackBar(
                                backgroundColor: const Color(0xFFE24B4A),
                                content: Text(vErr),
                              ),
                            );
                            return;
                          }

                          setState(() => isLoading = true);
                          try {
                            final apiClient = ref.read(apiClientProvider);
                            await apiClient.submitLead({
                              'name': nameController.text,
                              'phone': phoneController.text,
                              'email': emailController.text,
                              // Server-side enum: source = online | cp |
                              // walk-in | referral | other.
                              'source': 'online',
                            });

                            if (context.mounted) {
                              Navigator.pop(context);
                              ScaffoldMessenger.of(context).showSnackBar(
                                SnackBar(
                                  content: Text(
                                    'Consultation request sent successfully!',
                                    style: GoogleFonts.ebGaramond(
                                      color: Theme.of(
                                        context,
                                      ).colorScheme.background,
                                    ),
                                  ),
                                  backgroundColor: Theme.of(
                                    context,
                                  ).colorScheme.onBackground,
                                ),
                              );
                            }
                          } catch (e) {
                            if (context.mounted) {
                              ScaffoldMessenger.of(context).showSnackBar(
                                SnackBar(
                                  content: Text(
                                    'Failed to submit request. Please try again.',
                                    style: GoogleFonts.ebGaramond(
                                      color: Theme.of(
                                        context,
                                      ).colorScheme.onError,
                                    ),
                                  ),
                                  backgroundColor: Theme.of(
                                    context,
                                  ).colorScheme.error,
                                ),
                              );
                            }
                          } finally {
                            if (context.mounted)
                              setState(() => isLoading = false);
                          }
                        },
                  child: Container(
                    width: double.infinity,
                    padding: const EdgeInsets.symmetric(vertical: 18),
                    decoration: BoxDecoration(
                      color: Theme.of(context).colorScheme.onSurface,
                      borderRadius: BorderRadius.circular(16),
                    ),
                    alignment: Alignment.center,
                    child: isLoading
                        ? SizedBox(
                            height: 20,
                            width: 20,
                            child: CircularProgressIndicator(
                              color: Theme.of(context).colorScheme.surface,
                              strokeWidth: 2,
                            ),
                          )
                        : Text(
                            'SEND REQUEST',
                            style: GoogleFonts.gelasio(
                              fontSize: 12,
                              fontWeight: FontWeight.w900,
                              color: Theme.of(context).colorScheme.surface,
                              letterSpacing: 2,
                            ),
                          ),
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildField(
    BuildContext context,
    String label,
    IconData icon,
    TextEditingController controller, {
    TextInputType keyboardType = TextInputType.text,
    List<TextInputFormatter>? inputFormatters,
  }) {
    return Container(
      margin: const EdgeInsets.only(bottom: 16),
      decoration: BoxDecoration(
        color: Theme.of(context).colorScheme.onSurface.withOpacity(0.04),
        borderRadius: BorderRadius.circular(16),
        border: Border.all(
          color: Theme.of(context).colorScheme.onSurface.withOpacity(0.08),
        ),
      ),
      child: TextField(
        controller: controller,
        keyboardType: keyboardType,
        inputFormatters: inputFormatters,
        style: GoogleFonts.ebGaramond(
          color: Theme.of(context).colorScheme.onSurface,
          fontSize: 15,
        ),
        decoration: InputDecoration(
          labelText: label,
          labelStyle: GoogleFonts.ebGaramond(
            color: Theme.of(context).colorScheme.onSurface.withOpacity(0.68),
            fontSize: 11,
          ),
          prefixIcon: Icon(
            icon,
            color: Theme.of(context).colorScheme.onSurface.withOpacity(0.24),
            size: 18,
          ),
          border: InputBorder.none,
          contentPadding: const EdgeInsets.symmetric(
            horizontal: 20,
            vertical: 12,
          ),
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    return Container(
      margin: const EdgeInsets.symmetric(horizontal: 24),
      padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 48),
      decoration: BoxDecoration(
        color: Theme.of(context).colorScheme.surface,
        borderRadius: BorderRadius.circular(40),
      ),
      child: Column(
        children: [
          Text(
            'GET IN TOUCH',
            style: GoogleFonts.gelasio(
              fontSize: 10,
              fontWeight: FontWeight.w900,
              letterSpacing: 4,
              color: Theme.of(context).colorScheme.onSurface.withOpacity(0.68),
            ),
          ),
          const SizedBox(height: 16),
          Text(
            'READY TO\nSTART\nYOUR\nJOURNEY?',
            textAlign: TextAlign.center,
            style: GoogleFonts.gelasio(
              fontSize: 32,
              fontWeight: FontWeight.w300,
              color: Theme.of(context).colorScheme.onSurface,
              height: 1.1,
            ),
          ),
          const SizedBox(height: 24),
          Text(
            'Schedule a private session with our interior consultants at our Experience Centre in South Mumbai.',
            textAlign: TextAlign.center,
            style: GoogleFonts.ebGaramond(
              fontSize: 12,
              color: Theme.of(context).colorScheme.onSurface.withOpacity(0.54),
              height: 1.5,
            ),
          ),
          const SizedBox(height: 40),
          GestureDetector(
            onTap: () => _showConsultationDialog(context, ref),
            child: Container(
              width: double.infinity,
              padding: const EdgeInsets.symmetric(vertical: 16),
              decoration: BoxDecoration(
                color: Theme.of(context).colorScheme.onSurface,
                borderRadius: BorderRadius.circular(20),
              ),
              alignment: Alignment.center,
              child: Row(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Icon(
                    LucideIcons.phone,
                    size: 16,
                    color: Theme.of(context).colorScheme.surface,
                  ),
                  const SizedBox(width: 8),
                  Text(
                    'BOOK A CONSULTATION',
                    style: GoogleFonts.ebGaramond(
                      fontSize: 11,
                      fontWeight: FontWeight.w900,
                      color: Theme.of(context).colorScheme.surface,
                      letterSpacing: 1,
                    ),
                  ),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }
}
