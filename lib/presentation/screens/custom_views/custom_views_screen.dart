import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:m4_mobile/core/theme/app_theme.dart';
import 'package:m4_mobile/presentation/providers/auth_provider.dart';
import 'package:m4_mobile/presentation/providers/custom_views_provider.dart';
import 'package:m4_mobile/presentation/providers/project_provider.dart';
import 'package:flutter_animate/flutter_animate.dart';
import 'package:lucide_icons/lucide_icons.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:m4_mobile/presentation/widgets/main_shell.dart';

class CustomViewsScreen extends ConsumerWidget {
  const CustomViewsScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final currentStep = ref.watch(customViewsStepProvider);
    final isSubmitted = false; // We can add an isSubmitted state later if needed

    return Scaffold(
      backgroundColor: Theme.of(context).scaffoldBackgroundColor,
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
                        ref.read(customViewsStepProvider.notifier).state = currentStep - 1;
                      } else {
                        // Return to Home tab
                        ref.read(navigationProvider.notifier).state = 0;
                      }
                    },
                    child: Container(
                      padding: const EdgeInsets.all(8),
                      decoration: BoxDecoration(
                        color: Theme.of(context).colorScheme.onSurface.withOpacity(0.05),
                        borderRadius: BorderRadius.circular(12),
                        border: Border.all(color: Theme.of(context).colorScheme.onSurface.withOpacity(0.1)),
                      ),
                      child: Icon(LucideIcons.arrowLeft, size: 20, color: Theme.of(context).colorScheme.onSurface),
                    ),
                  ),
                  const SizedBox(width: 16),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.center,
                      children: [
                        Text(
                          'M4 CUSTOM VIEWS',
                          style: GoogleFonts.montserrat(
                            fontSize: 16,
                            fontWeight: FontWeight.w900,
                            color: Theme.of(context).colorScheme.onSurface,
                            letterSpacing: 0,
                          ),
                        ),
                        Text(
                          'PERSONALISATION SUITE',
                          style: GoogleFonts.montserrat(
                            fontSize: 8,
                            fontWeight: FontWeight.bold,
                            color: Theme.of(context).colorScheme.onSurface.withOpacity(0.5),
                            letterSpacing: 3,
                          ),
                        ),
                      ],
                    ),
                  ),
                  const SizedBox(width: 36), // Balance the row
                ],
              ),
            ),

            // Main Scrolling Content
            Expanded(
              child: SingleChildScrollView(
                padding: const EdgeInsets.only(bottom: 120),
                child: Column(
                  children: [
                    // Journey Steps Track
                    SizedBox(
                      height: 90,
                      child: ListView(
                        scrollDirection: Axis.horizontal,
                        padding: const EdgeInsets.symmetric(horizontal: 24),
                        children: const [
                          _StepIndicator(index: 0, title: 'PROJECT & UNIT', icon: LucideIcons.building2),
                          SizedBox(width: 32),
                          _StepIndicator(index: 1, title: 'SELECT SPACE', icon: LucideIcons.home),
                          SizedBox(width: 32),
                          _StepIndicator(index: 2, title: 'CHOOSE MATERIALS', icon: LucideIcons.layers),
                          SizedBox(width: 32),
                          _StepIndicator(index: 3, title: 'FINALISE', icon: LucideIcons.check),
                        ],
                      ),
                    ),

                    const SizedBox(height: 24),

                    // Wizard Content Card
                    Container(
                      margin: const EdgeInsets.symmetric(horizontal: 24),
                      padding: const EdgeInsets.all(24),
                      decoration: BoxDecoration(
                        color: Theme.of(context).colorScheme.onSurface.withOpacity(0.03),
                        borderRadius: BorderRadius.circular(40),
                        border: Border.all(color: Theme.of(context).colorScheme.onSurface.withOpacity(0.05)),
                      ),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          _buildStepContent(currentStep),
                          
                          const SizedBox(height: 32),
                          
                          // Navigation Footer inside the card
                          if (!isSubmitted)
                            Row(
                              mainAxisAlignment: MainAxisAlignment.spaceBetween,
                              children: [
                                GestureDetector(
                                  onTap: currentStep > 0
                                      ? () => ref.read(customViewsStepProvider.notifier).state = currentStep - 1
                                      : null,
                                  child: Text(
                                    'BACK',
                                    style: GoogleFonts.montserrat(
                                      fontSize: 12,
                                      fontWeight: FontWeight.w900,
                                      color: currentStep > 0 ? Theme.of(context).colorScheme.onSurface.withOpacity(0.7) : Colors.transparent,
                                      letterSpacing: 2,
                                    ),
                                  ),
                                ),
                                GestureDetector(
                                  onTap: () async {
                                    if (currentStep < 3) {
                                      ref.read(customViewsStepProvider.notifier).state = currentStep + 1;
                                    } else {
                                      final messenger = ScaffoldMessenger.of(context);
                                      try {
                                        final apiClient = ref.read(apiClientProvider);
                                        final auth = ref.read(authProvider);
                                        final selectedProject = ref.read(customViewsProjectProvider);
                                        final selectedUnit = ref.read(customViewsUnitProvider);
                                        final selections = ref.read(customViewsSelectionsProvider);
                                        
                                        // Map identifier to phone or email if possible
                                        String? guestPhone;
                                        String? guestEmail;
                                        if (auth.identifier != null) {
                                          if (auth.identifier!.contains('@')) {
                                            guestEmail = auth.identifier;
                                          } else {
                                            guestPhone = auth.identifier;
                                          }
                                        }

                                        final response = await apiClient.submitCustomViews({
                                          'project': selectedProject,
                                          'unitType': selectedUnit,
                                          'space': selections['space'],
                                          'selections': selections,
                                          'guestName': auth.identifier ?? 'App Guest',
                                          'guestPhone': guestPhone ?? 'N/A',
                                          'guestEmail': guestEmail ?? 'app@m4family.com'
                                        });
                                        
                                        if (context.mounted) {
                                          if (response.data['status'] == true) {
                                            messenger.showSnackBar(
                                              const SnackBar(
                                                content: Text('Selections successfully saved and synced to Admin Panel!'),
                                                backgroundColor: Colors.green,
                                              ),
                                            );
                                            // Reset to Step 0 and clear states
                                            ref.read(customViewsStepProvider.notifier).state = 0;
                                            ref.read(customViewsSelectionsProvider.notifier).state = {};
                                            ref.read(customViewsProjectProvider.notifier).state = null;
                                          } else {
                                            messenger.showSnackBar(
                                              SnackBar(
                                                content: Text(response.data['message'] ?? 'Failed to save selections'),
                                                backgroundColor: Colors.red,
                                              ),
                                            );
                                          }
                                        }
                                      } catch (e) {
                                        if (context.mounted) {
                                          messenger.showSnackBar(
                                            SnackBar(
                                              content: Text('Failed to save selections. Please try again.'),
                                              backgroundColor: Colors.red,
                                            ),
                                          );
                                        }
                                      }
                                    }
                                  },
                                  child: Container(
                                    padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 14),
                                    decoration: BoxDecoration(
                                      color: Theme.of(context).colorScheme.onBackground,
                                      borderRadius: BorderRadius.circular(16),
                                    ),
                                    child: Text(
                                      currentStep < 3 ? 'NEXT STEP' : 'CONFIRM',
                                      style: GoogleFonts.montserrat(
                                        fontSize: 12,
                                        fontWeight: FontWeight.w900,
                                        color: Theme.of(context).colorScheme.background,
                                        letterSpacing: 1,
                                      ),
                                    ),
                                  ),
                                ),
                              ],
                            ),
                        ],
                      ),
                    ),

                    const SizedBox(height: 64),

                    // Premium Materials Section
                    const _PremiumMaterialsSection(),

                    const SizedBox(height: 64),

                    // Consultation Section
                    const _ConsultationSection(),
                  ],
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildStepContent(int step) {
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

class _StepIndicator extends ConsumerWidget {
  final int index;
  final String title;
  final IconData icon;

  const _StepIndicator({required this.index, required this.title, required this.icon});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final currentStep = ref.watch(customViewsStepProvider);
    final isActive = currentStep >= index;

    final isDark = Theme.of(context).brightness == Brightness.dark;
    return GestureDetector(
      onTap: () {
        if (index > 0 && ref.read(customViewsProjectProvider) == null) {
          // Keep them on step 0 if no project selected
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(content: Text('Please select a project first')),
          );
          return;
        }
        ref.read(customViewsStepProvider.notifier).state = index;
      },
      child: MouseRegion(
        cursor: SystemMouseCursors.click,
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.center,
          children: [
            Container(
              width: 52,
              height: 52,
              decoration: BoxDecoration(
                color: isActive ? M4Theme.premiumBlue : (isDark ? Colors.white : Colors.black).withOpacity(0.05),
                shape: BoxShape.circle,
                boxShadow: isActive ? [
                  BoxShadow(color: M4Theme.premiumBlue.withOpacity(0.3), blurRadius: 12, spreadRadius: 2)
                ] : [],
              ),
              child: Icon(
                icon,
                size: 20,
                color: isActive ? Colors.white : Theme.of(context).colorScheme.onSurface.withOpacity(0.2),
              ),
            ),
            const SizedBox(height: 12),
            Text(
              title,
              style: GoogleFonts.montserrat(
                fontSize: 8,
                fontWeight: FontWeight.w900,
                letterSpacing: 1,
                color: isActive ? Theme.of(context).colorScheme.onSurface : Theme.of(context).colorScheme.onSurface.withOpacity(0.3),
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

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          'PROJECT &\nUNIT',
          style: GoogleFonts.montserrat(fontSize: 28, fontWeight: FontWeight.w300, color: Theme.of(context).colorScheme.onSurface, height: 1.1),
        ),
        const SizedBox(height: 12),
        Text(
          'Select your project and unit\nconfiguration',
          style: GoogleFonts.montserrat(fontSize: 12, color: Theme.of(context).colorScheme.onSurface.withOpacity(0.5), height: 1.5),
        ),
        const SizedBox(height: 40),

        // Projects List
        Row(
          children: [
            Icon(LucideIcons.building2, size: 14, color: Theme.of(context).colorScheme.onSurface.withOpacity(0.7)),
            const SizedBox(width: 8),
            Text('PROJECT SELECTION', style: GoogleFonts.montserrat(fontSize: 10, fontWeight: FontWeight.w900, letterSpacing: 2, color: Theme.of(context).colorScheme.onSurface)),
          ],
        ),
        const SizedBox(height: 16),
        projectsAsync.when(
          data: (projects) => Column(
            children: projects.map<Widget>((p) {
              final isSelected = selectedProject == p['_id'];
              final isDark = Theme.of(context).brightness == Brightness.dark;
              return GestureDetector(
                onTap: () => ref.read(customViewsProjectProvider.notifier).state = p['_id'],
                child: Container(
                  margin: const EdgeInsets.only(bottom: 12),
                  padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 16),
                  decoration: BoxDecoration(
                    color: isSelected ? Theme.of(context).colorScheme.onBackground : (isDark ? Colors.white : Colors.black).withOpacity(0.04),
                    borderRadius: BorderRadius.circular(16),
                    border: Border.all(color: isSelected ? Theme.of(context).colorScheme.onBackground : (isDark ? Colors.white : Colors.black).withOpacity(0.08)),
                  ),
                  child: Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            p['title']?.toUpperCase() ?? 'PROJECT',
                            style: GoogleFonts.montserrat(
                              fontSize: 14,
                              fontWeight: FontWeight.w900,
                              color: isSelected ? Theme.of(context).colorScheme.background : Theme.of(context).colorScheme.onSurface,
                              letterSpacing: 0.5,
                            ),
                          ),
                          const SizedBox(height: 4),
                          Text(
                            p['location']?['name']?.toUpperCase() ?? 'LOCATION',
                            style: GoogleFonts.montserrat(
                              fontSize: 8,
                              fontWeight: FontWeight.bold,
                              letterSpacing: 2,
                              color: isSelected ? Theme.of(context).colorScheme.background.withOpacity(0.7) : Theme.of(context).colorScheme.onSurface.withOpacity(0.54),
                            ),
                          ),
                        ],
                      ),
                      if (isSelected) Icon(LucideIcons.check, color: Theme.of(context).colorScheme.background, size: 20),
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
            Icon(LucideIcons.layoutGrid, size: 14, color: Theme.of(context).colorScheme.onSurface.withOpacity(0.7)),
            const SizedBox(width: 8),
            Text('UNIT CONFIGURATION', style: GoogleFonts.montserrat(fontSize: 10, fontWeight: FontWeight.w900, letterSpacing: 2, color: Theme.of(context).colorScheme.onSurface)),
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
              onTap: () => ref.read(customViewsUnitProvider.notifier).state = unit,
              child: Container(
                padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 14),
                decoration: BoxDecoration(
                  color: isSelected ? Theme.of(context).colorScheme.onBackground : (isDark ? Colors.white : Colors.black).withOpacity(0.04),
                  borderRadius: BorderRadius.circular(12),
                  border: Border.all(color: isSelected ? Theme.of(context).colorScheme.onBackground : (isDark ? Colors.white : Colors.black).withOpacity(0.1)),
                ),
                child: Text(
                  unit,
                  style: GoogleFonts.montserrat(
                    fontSize: 10,
                    fontWeight: FontWeight.w900,
                    letterSpacing: 1,
                    color: isSelected ? Theme.of(context).colorScheme.background : Theme.of(context).colorScheme.onSurface,
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

// ======================== Step 1 ========================
class _SpaceSelectionStep extends ConsumerWidget {
  const _SpaceSelectionStep({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final selections = ref.watch(customViewsSelectionsProvider);

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          'SELECT\nSPACE',
          style: GoogleFonts.montserrat(fontSize: 28, fontWeight: FontWeight.w300, color: Theme.of(context).colorScheme.onSurface, height: 1.1),
        ),
        const SizedBox(height: 12),
        Text(
          'Choose the area you want to personalise',
          style: GoogleFonts.montserrat(fontSize: 12, color: Theme.of(context).colorScheme.onSurface.withOpacity(0.54)),
        ),
        const SizedBox(height: 40),
        GridView.count(
          shrinkWrap: true,
          physics: const NeverScrollableScrollPhysics(),
          crossAxisCount: 2,
          mainAxisSpacing: 16,
          crossAxisSpacing: 16,
          childAspectRatio: 1.4,
          children: ['Master Bedroom', 'Living Hall', 'Kitchen Space', 'Guest Suite'].map((space) {
            final isSelected = selections['space'] == space;
            final isDark = Theme.of(context).brightness == Brightness.dark;
            return GestureDetector(
              onTap: () {
                final newSelections = Map<String, dynamic>.from(selections);
                newSelections['space'] = space;
                ref.read(customViewsSelectionsProvider.notifier).state = newSelections;
              },
              child: Container(
                padding: const EdgeInsets.all(16),
                decoration: BoxDecoration(
                  color: isSelected ? Theme.of(context).colorScheme.onBackground : Colors.transparent,
                  borderRadius: BorderRadius.circular(20),
                  border: Border.all(color: isSelected ? Theme.of(context).colorScheme.onBackground : (isDark ? Colors.white : Colors.black).withOpacity(0.1)),
                ),
                alignment: Alignment.center,
                child: Text(
                  space.toUpperCase(),
                  textAlign: TextAlign.center,
                  style: GoogleFonts.montserrat(
                    fontSize: 11,
                    fontWeight: FontWeight.w900,
                    letterSpacing: 1,
                    color: isSelected ? Theme.of(context).colorScheme.background : Theme.of(context).colorScheme.onSurface,
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

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final optionsAsync = ref.watch(customizationOptionsProvider);
    final selections = ref.watch(customViewsSelectionsProvider);

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          'CHOOSE\nMATERIALS',
          style: GoogleFonts.montserrat(fontSize: 28, fontWeight: FontWeight.w300, color: Theme.of(context).colorScheme.onSurface, height: 1.1),
        ),
        const SizedBox(height: 12),
        Text(
          'Select from our curated collection',
          style: GoogleFonts.montserrat(fontSize: 12, color: Theme.of(context).colorScheme.onSurface.withOpacity(0.54)),
        ),
        const SizedBox(height: 40),
        optionsAsync.when(
          data: (categories) {
            if (categories.isEmpty) return const Center(child: Text("No materials available at the moment."));
            return Column(
              children: categories.map<Widget>((cat) {
                return Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(
                      children: [
                        const Icon(LucideIcons.palette, size: 14, color: Colors.white70),
                        const SizedBox(width: 8),
                        Text(
                          (cat['title']?.toUpperCase() ?? 'CATEGORY'),
                          style: GoogleFonts.montserrat(fontSize: 10, fontWeight: FontWeight.w900, letterSpacing: 2, color: Colors.white),
                        ),
                      ],
                    ),
                    const SizedBox(height: 16),
                    GridView.builder(
                      shrinkWrap: true,
                      physics: const NeverScrollableScrollPhysics(),
                      gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
                        crossAxisCount: 2,
                        childAspectRatio: 1.0,
                        crossAxisSpacing: 16,
                        mainAxisSpacing: 16,
                      ),
                      itemCount: cat['options']?.length ?? 0,
                      itemBuilder: (context, index) {
                        final opt = cat['options'][index];
                        final isSelected = selections[cat['_id']]?['name'] == opt['name'];

                        return GestureDetector(
                          onTap: () {
                            final newSelections = Map<String, dynamic>.from(selections);
                            newSelections[cat['_id']] = opt;
                            ref.read(customViewsSelectionsProvider.notifier).state = newSelections;
                          },
                          child: Container(
                            decoration: BoxDecoration(
                              borderRadius: BorderRadius.circular(20),
                              border: Border.all(color: isSelected ? Theme.of(context).colorScheme.onBackground : Colors.transparent, width: 2),
                            ),
                            clipBehavior: Clip.antiAlias,
                            child: Stack(
                              fit: StackFit.expand,
                              children: [
                                if (opt['colorCode'] != null)
                                  Container(color: _hexToColor(opt['colorCode']))
                                else if (opt['image'] != null)
                                  Image.network(opt['image'], fit: BoxFit.cover,
                                    errorBuilder: (context, error, stackTrace) => Container(
                                      color: Colors.black.withOpacity(0.05),
                                      child: const Center(child: Icon(LucideIcons.image, color: Colors.black12)),
                                    ),
                                  )
                                else
                                  Container(
                                    color: Theme.of(context).colorScheme.onSurface.withOpacity(0.05),
                                    alignment: Alignment.center,
                                    child: Text(opt['name'], textAlign: TextAlign.center),
                                  ),
                                
                                Align(
                                  alignment: Alignment.bottomCenter,
                                  child: Container(
                                    width: double.infinity,
                                    padding: const EdgeInsets.symmetric(vertical: 10),
                                    color: Theme.of(context).colorScheme.onSurface.withOpacity(0.6),
                                    child: Text(
                                      opt['name']?.toUpperCase() ?? '',
                                      textAlign: TextAlign.center,
                                      style: GoogleFonts.montserrat(fontSize: 9, fontWeight: FontWeight.bold, letterSpacing: 1, color: Theme.of(context).colorScheme.background),
                                    ),
                                  ),
                                ),

                                if (isSelected)
                                  Positioned(
                                    top: 12,
                                    right: 12,
                                    child: Container(
                                      padding: const EdgeInsets.all(4),
                                      decoration: BoxDecoration(color: Theme.of(context).colorScheme.background, shape: BoxShape.circle),
                                      child: Icon(LucideIcons.check, size: 14, color: Theme.of(context).colorScheme.onBackground),
                                    ),
                                  ),
                              ],
                            ),
                          ),
                        );
                      },
                    ),
                    const SizedBox(height: 32),
                  ],
                );
              }).toList(),
            );
          },
          loading: () => const Center(child: CircularProgressIndicator()),
          error: (e, s) => Text('Error: $e'),
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

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          'FINALISE',
          style: GoogleFonts.montserrat(fontSize: 28, fontWeight: FontWeight.w300, color: Theme.of(context).colorScheme.onSurface),
        ),
        const SizedBox(height: 12),
        Text(
          'Confirm your selections',
          style: GoogleFonts.montserrat(fontSize: 12, color: Theme.of(context).colorScheme.onSurface.withOpacity(0.54)),
        ),
        const SizedBox(height: 40),

        Container(
          decoration: BoxDecoration(
            color: Theme.of(context).colorScheme.onSurface.withOpacity(0.02),
            border: Border.all(color: Theme.of(context).colorScheme.onSurface.withOpacity(0.1)),
            borderRadius: BorderRadius.circular(24),
          ),
          clipBehavior: Clip.antiAlias,
          child: Column(
            children: [
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 16),
                color: Theme.of(context).colorScheme.onSurface.withOpacity(0.05),
                child: Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Text('ITEM', style: GoogleFonts.montserrat(fontSize: 10, fontWeight: FontWeight.w900, letterSpacing: 2, color: Theme.of(context).colorScheme.onSurface.withOpacity(0.54))),
                    Text('SELECTION', style: GoogleFonts.montserrat(fontSize: 10, fontWeight: FontWeight.w900, letterSpacing: 2, color: Theme.of(context).colorScheme.onSurface.withOpacity(0.54))),
                  ],
                ),
              ),
              _SummaryRow(
                label: 'Project',
                value: projectsAsync.maybeWhen(
                  data: (p) => p.firstWhere((e) => e['_id'] == selectedProject, orElse: () => {'title': 'Standard'})['title'],
                  orElse: () => 'Standard',
                ),
              ),
              _SummaryRow(label: 'Unit Type', value: selectedUnit),
              ...selections.entries.map((entry) {
                String labelStr = entry.key == 'space' ? 'Space' : 'Material';
                if (entry.key != 'space') {
                  optionsAsync.maybeWhen(
                    data: (cats) {
                      final cat = cats.firstWhere((c) => c['_id'] == entry.key, orElse: () => null);
                      if (cat != null) labelStr = cat['title'];
                    },
                    orElse: () {},
                  );
                }
                final valName = entry.value is String ? entry.value : entry.value['name'];
                final priceImpact = (entry.value is Map && entry.value['priceImpact'] != null) ? entry.value['priceImpact'] : 0;
                
                return _SummaryRow(
                  label: labelStr.toUpperCase(),
                  value: valName.toString(),
                  subValue: priceImpact > 0 ? '+$priceImpact% Impact' : null,
                );
              }),

              // Total Price Impact Row
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 24),
                decoration: BoxDecoration(
                  color: Theme.of(context).colorScheme.onSurface.withOpacity(0.05),
                  border: Border(top: BorderSide(color: Theme.of(context).colorScheme.onSurface.withOpacity(0.1))),
                ),
                child: Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Text(
                      'TOTAL PRICE IMPACT',
                      style: GoogleFonts.montserrat(
                        fontSize: 10,
                        fontWeight: FontWeight.w900,
                        letterSpacing: 2,
                        color: Theme.of(context).colorScheme.onSurface,
                      ),
                    ),
                    Builder(builder: (context) {
                      int total = 0;
                      selections.forEach((k, v) {
                        if (v is Map && v['priceImpact'] != null) {
                          total += (v['priceImpact'] as num).toInt();
                        }
                      });
                      return Text(
                        '$total%',
                        style: GoogleFonts.montserrat(
                          fontSize: 24,
                          fontWeight: FontWeight.w300,
                          color: Theme.of(context).colorScheme.onSurface,
                        ),
                      );
                    }),
                  ],
                ),
              ),
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
        border: Border(top: BorderSide(color: (isDark ? Colors.white : Colors.black).withOpacity(0.05))),
      ),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Expanded(child: Text(label, style: GoogleFonts.montserrat(fontSize: 11, fontWeight: FontWeight.w600, color: Theme.of(context).colorScheme.onSurface.withOpacity(0.7)))),
          Column(
            crossAxisAlignment: CrossAxisAlignment.end,
            children: [
              Text(value.toUpperCase(), style: GoogleFonts.montserrat(fontSize: 11, fontWeight: FontWeight.bold, color: Theme.of(context).colorScheme.onSurface, letterSpacing: 0)),
              if (subValue != null)
                Text(subValue!, style: GoogleFonts.montserrat(fontSize: 9, fontWeight: FontWeight.bold, color: Theme.of(context).colorScheme.tertiary)),
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
        "img": "https://images.unsplash.com/photo-1600585154340-be6161a56a0c?auto=format&fit=crop&q=80",
        "count": "12+ VARIANTS"
      },
      {
        "title": "Best Wood Textures",
        "img": "https://images.unsplash.com/photo-1541888946425-d81bb19240f5?auto=format&fit=crop&q=80",
        "count": "8+ TEXTURES"
      },
      {
        "title": "Elite Finishes",
        "img": "https://images.unsplash.com/photo-1600607687939-ce8a6c25118c?auto=format&fit=crop&q=80",
        "count": "20+ OPTIONS"
      },
    ];

    return Column(
      children: [
        Text(
          'THE COLLECTION',
          style: GoogleFonts.montserrat(fontSize: 10, fontWeight: FontWeight.w900, letterSpacing: 4, color: Theme.of(context).colorScheme.onSurface.withOpacity(0.54)),
        ),
        const SizedBox(height: 8),
        Text(
          'PREMIUM\nMATERIALS',
          textAlign: TextAlign.center,
          style: GoogleFonts.montserrat(fontSize: 32, fontWeight: FontWeight.w300, color: Theme.of(context).colorScheme.onSurface, height: 1.1),
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
                      borderRadius: const BorderRadius.vertical(top: Radius.circular(60), bottom: Radius.circular(60)),
                      child: Image.network(
                        mat['img']!,
                        fit: BoxFit.cover,
                        errorBuilder: (context, error, stackTrace) => Container(
                          color: Colors.black.withOpacity(0.05),
                          child: const Center(child: Icon(LucideIcons.image, color: Colors.black12)),
                        ),
                      ),
                    ),
                    Container(
                      decoration: BoxDecoration(
                        borderRadius: const BorderRadius.vertical(top: Radius.circular(60), bottom: Radius.circular(60)),
                        gradient: LinearGradient(
                          begin: Alignment.bottomCenter,
                          end: Alignment.topCenter,
                          colors: [Theme.of(context).colorScheme.onSurface.withOpacity(0.8), Colors.transparent],
                        ),
                      ),
                      padding: const EdgeInsets.all(16),
                      child: Column(
                        mainAxisAlignment: MainAxisAlignment.end,
                        children: [
                          Text(
                            mat['title']!,
                            textAlign: TextAlign.center,
                            style: GoogleFonts.montserrat(fontSize: 10, fontWeight: FontWeight.bold, color: Theme.of(context).colorScheme.background),
                          ),
                          const SizedBox(height: 4),
                          Text(
                            mat['count']!,
                            style: GoogleFonts.montserrat(fontSize: 7, fontWeight: FontWeight.bold, color: Theme.of(context).colorScheme.background.withOpacity(0.54), letterSpacing: 1.5),
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
              border: Border.all(color: Theme.of(context).colorScheme.onSurface.withOpacity(0.1)),
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
                      style: GoogleFonts.montserrat(
                        fontSize: 20,
                        fontWeight: FontWeight.bold,
                        color: Theme.of(context).colorScheme.onSurface,
                      ),
                    ),
                    GestureDetector(
                      onTap: () => Navigator.pop(context),
                      child: Icon(LucideIcons.x, color: Theme.of(context).colorScheme.onSurface.withOpacity(0.54), size: 20),
                    ),
                  ],
                ),
                const SizedBox(height: 8),
                Text(
                  'Leave your details with us and our elite interior design team will be in touch shortly.',
                  style: GoogleFonts.montserrat(
                    fontSize: 10,
                    color: Theme.of(context).colorScheme.onSurface.withOpacity(0.54),
                    height: 1.5,
                  ),
                ),
                const SizedBox(height: 32),
                _buildField(
                  context,
                  'FULL NAME',
                  LucideIcons.user,
                  nameController,
                ),
                _buildField(
                  context,
                  'PHONE NUMBER',
                  LucideIcons.phone,
                  phoneController,
                  keyboardType: TextInputType.phone,
                ),
                _buildField(
                  context,
                  'EMAIL (OPTIONAL)',
                  LucideIcons.mail,
                  emailController,
                  keyboardType: TextInputType.emailAddress,
                ),
                const SizedBox(height: 32),
                GestureDetector(
                  onTap: isLoading
                      ? null
                      : () async {
                          if (nameController.text.isEmpty || phoneController.text.isEmpty) {
                            ScaffoldMessenger.of(context).showSnackBar(
                              const SnackBar(content: Text('Name and Phone are required')),
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
                              'source': 'App Custom Views Consultation',
                            });

                            if (context.mounted) {
                              Navigator.pop(context);
                              ScaffoldMessenger.of(context).showSnackBar(
                                SnackBar(
                                  content: Text('Consultation request sent successfully!', style: GoogleFonts.montserrat(color: Theme.of(context).colorScheme.background)),
                                  backgroundColor: Theme.of(context).colorScheme.onBackground,
                                ),
                              );
                            }
                          } catch (e) {
                            if (context.mounted) {
                              ScaffoldMessenger.of(context).showSnackBar(
                                SnackBar(
                                  content: Text('Failed to submit request. Please try again.', style: GoogleFonts.montserrat(color: Theme.of(context).colorScheme.onError)),
                                  backgroundColor: Theme.of(context).colorScheme.error,
                                ),
                              );
                            }
                          } finally {
                            if (context.mounted) setState(() => isLoading = false);
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
                            child: CircularProgressIndicator(color: Theme.of(context).colorScheme.surface, strokeWidth: 2),
                          )
                        : Text(
                            'SEND REQUEST',
                            style: GoogleFonts.montserrat(
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

  Widget _buildField(BuildContext context, String label, IconData icon, TextEditingController controller, {TextInputType keyboardType = TextInputType.text}) {
    return Container(
      margin: const EdgeInsets.only(bottom: 16),
      decoration: BoxDecoration(
        color: Theme.of(context).colorScheme.onSurface.withOpacity(0.04),
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: Theme.of(context).colorScheme.onSurface.withOpacity(0.08)),
      ),
      child: TextField(
        controller: controller,
        keyboardType: keyboardType,
        style: GoogleFonts.montserrat(color: Theme.of(context).colorScheme.onSurface, fontSize: 13),
        decoration: InputDecoration(
          labelText: label,
          labelStyle: GoogleFonts.montserrat(color: Theme.of(context).colorScheme.onSurface.withOpacity(0.38), fontSize: 11),
          prefixIcon: Icon(icon, color: Theme.of(context).colorScheme.onSurface.withOpacity(0.24), size: 18),
          border: InputBorder.none,
          contentPadding: const EdgeInsets.symmetric(horizontal: 20, vertical: 12),
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
            style: GoogleFonts.montserrat(fontSize: 10, fontWeight: FontWeight.w900, letterSpacing: 4, color: Theme.of(context).colorScheme.onSurface.withOpacity(0.45)),
          ),
          const SizedBox(height: 16),
          Text(
            'READY TO\nSTART\nYOUR\nJOURNEY?',
            textAlign: TextAlign.center,
            style: GoogleFonts.montserrat(fontSize: 32, fontWeight: FontWeight.w300, color: Theme.of(context).colorScheme.onSurface, height: 1.1),
          ),
          const SizedBox(height: 24),
          Text(
            'Schedule a private session with our interior consultants at our Experience Centre in South Mumbai.',
            textAlign: TextAlign.center,
            style: GoogleFonts.montserrat(fontSize: 12, color: Theme.of(context).colorScheme.onSurface.withOpacity(0.54), height: 1.5),
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
                  Icon(LucideIcons.phone, size: 16, color: Theme.of(context).colorScheme.surface),
                  const SizedBox(width: 8),
                  Text(
                    'BOOK A CONSULTATION',
                    style: GoogleFonts.montserrat(fontSize: 11, fontWeight: FontWeight.w900, color: Theme.of(context).colorScheme.surface, letterSpacing: 1),
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
