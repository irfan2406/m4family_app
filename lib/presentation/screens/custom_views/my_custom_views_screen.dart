import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:lucide_icons/lucide_icons.dart';
import 'package:flutter_animate/flutter_animate.dart';
import 'package:intl/intl.dart';
import 'dart:ui';
import 'package:m4_mobile/presentation/providers/my_custom_views_provider.dart';
import 'package:m4_mobile/presentation/providers/custom_views_provider.dart';
import 'package:m4_mobile/presentation/widgets/main_shell.dart';

class MyCustomViewsScreen extends ConsumerStatefulWidget {
  const MyCustomViewsScreen({super.key});

  @override
  ConsumerState<MyCustomViewsScreen> createState() => _MyCustomViewsScreenState();
}

class _MyCustomViewsScreenState extends ConsumerState<MyCustomViewsScreen> {
  String _activeTab = 'SELECTION'; // SELECTION or HISTORY
  String _searchQuery = '';

  @override
  void initState() {
    super.initState();
    Future.microtask(() => ref.read(myCustomViewsProvider.notifier).fetchAll());
  }

  @override
  Widget build(BuildContext context) {
    final state = ref.watch(myCustomViewsProvider);

    return Scaffold(
      backgroundColor: Theme.of(context).scaffoldBackgroundColor,
      body: Stack(
        children: [
          // Background Glows
          Positioned(
            top: -100,
            right: -100,
            child: Container(
              width: 300,
              height: 300,
              decoration: BoxDecoration(
                color: Colors.blueAccent.withOpacity(0.05),
                shape: BoxShape.circle,
              ),
            ),
          ),
          
          SafeArea(
            child: Column(
              children: [
                _buildHeader(context),
                _buildTabSwitcher(context),
                Expanded(
                  child: AnimatedSwitcher(
                    duration: const Duration(milliseconds: 300),
                    child: _activeTab == 'SELECTION' 
                      ? _buildSelectionTab(context, state) 
                      : _buildHistoryTab(context, state),
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildHeader(BuildContext context) {
    final foreground = Theme.of(context).colorScheme.onSurface;

    return Padding(
      padding: const EdgeInsets.fromLTRB(16, 20, 16, 12),
      child: Row(
        children: [
          GestureDetector(
            onTap: () {
              if (Navigator.canPop(context)) {
                Navigator.pop(context);
              } else {
                ref.read(navigationProvider.notifier).state = 3;
              }
            },
            child: Container(
              width: 40,
              height: 40,
              decoration: BoxDecoration(
                color: foreground.withOpacity(0.03),
                borderRadius: BorderRadius.circular(12),
                border: Border.all(color: foreground.withOpacity(0.05)),
              ),
              child: Icon(LucideIcons.arrowLeft, color: foreground.withOpacity(0.7), size: 20),
            ),
          ),
          const SizedBox(width: 16),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  'PERSONALISATION SUITE',
                  style: GoogleFonts.montserrat(
                    fontSize: 16,
                    fontWeight: FontWeight.w900,
                    color: foreground,
                    letterSpacing: -0.5,
                  ),
                ),
                Row(
                  children: [
                    Icon(LucideIcons.paintBucket, size: 10, color: foreground.withOpacity(0.3)),
                    const SizedBox(width: 6),
                    Text(
                      'DASHBOARD',
                      style: GoogleFonts.montserrat(
                        fontSize: 9,
                        fontWeight: FontWeight.w900,
                        color: foreground.withOpacity(0.3),
                        letterSpacing: 4,
                      ),
                    ),
                  ],
                ),
              ],
            ),
          ),
        ],
      ),
    ).animate().fadeIn().slideX(begin: -0.1);
  }

  Widget _buildTabSwitcher(BuildContext context) {
    final foreground = Theme.of(context).colorScheme.onSurface;
    return Container(
      margin: const EdgeInsets.symmetric(horizontal: 24, vertical: 20),
      padding: const EdgeInsets.all(4),
      decoration: BoxDecoration(
        color: foreground.withOpacity(0.03),
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: foreground.withOpacity(0.05)),
      ),
      child: Row(
        children: [
          Expanded(child: _buildTabButton(context, 'SELECTION', 'Selection')),
          Expanded(child: _buildTabButton(context, 'HISTORY', 'History')),
        ],
      ),
    );
  }

  Widget _buildTabButton(BuildContext context, String id, String label) {
    final isActive = _activeTab == id;
    final foreground = Theme.of(context).colorScheme.onSurface;
    final isDark = Theme.of(context).brightness == Brightness.dark;

    return GestureDetector(
      onTap: () => setState(() => _activeTab = id),
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 200),
        padding: const EdgeInsets.symmetric(vertical: 12),
        decoration: BoxDecoration(
          color: isActive ? foreground : Colors.transparent,
          borderRadius: BorderRadius.circular(12),
          boxShadow: isActive ? [
            BoxShadow(color: (isDark ? Colors.black : Colors.white).withOpacity(0.1), blurRadius: 10)
          ] : null,
        ),
        child: Center(
          child: Text(
            label.toUpperCase(),
            style: GoogleFonts.montserrat(
              fontSize: 10,
              fontWeight: FontWeight.w900,
              color: isActive ? Theme.of(context).colorScheme.surface : foreground.withOpacity(0.3),
              letterSpacing: 2,
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildSelectionTab(BuildContext context, MyCustomViewsState state) {
    if (state.isLoadingUnits) {
      return Center(child: CircularProgressIndicator(color: Theme.of(context).colorScheme.onSurface.withOpacity(0.2)));
    }

    if (state.units.isEmpty) {
      return _buildEmptyState(
        context,
        icon: LucideIcons.layoutGrid,
        title: 'NO UNITS FOUND',
        subtitle: 'YOU CURRENTLY HAVE NO PURCHASED UNITS SUPPORTING ONLINE CUSTOMIZATION.',
      );
    }

    return ListView.builder(
      padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 10),
      itemCount: state.units.length,
      itemBuilder: (context, index) {
        final unit = state.units[index];
        return _UnitCard(unit: unit).animate().fadeIn(delay: (index * 100).ms).slideY(begin: 0.1);
      },
    );
  }

  Widget _buildHistoryTab(BuildContext context, MyCustomViewsState state) {
    final foreground = Theme.of(context).colorScheme.onSurface;
    if (state.isLoadingHistory) {
      return Center(child: CircularProgressIndicator(color: foreground.withOpacity(0.2)));
    }

    final filtered = state.history.where((req) {
      final project = req['project']?['title']?.toString().toLowerCase() ?? '';
      final id = req['_id']?.toString().toLowerCase() ?? '';
      return project.contains(_searchQuery.toLowerCase()) || id.contains(_searchQuery.toLowerCase());
    }).toList();

    return Column(
      children: [
        // Search Bar
        Padding(
          padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 10),
          child: Container(
            decoration: BoxDecoration(
              color: foreground.withOpacity(0.03),
              borderRadius: BorderRadius.circular(16),
              border: Border.all(color: foreground.withOpacity(0.05)),
            ),
            child: TextField(
              onChanged: (v) => setState(() => _searchQuery = v),
              style: GoogleFonts.montserrat(color: foreground, fontSize: 13),
              decoration: InputDecoration(
                hintText: 'SEARCH BY PROJECT OR ID...',
                hintStyle: GoogleFonts.montserrat(color: foreground.withOpacity(0.24), fontSize: 10, fontWeight: FontWeight.w900, letterSpacing: 1),
                prefixIcon: Icon(LucideIcons.search, size: 16, color: foreground.withOpacity(0.24)),
                border: InputBorder.none,
                contentPadding: const EdgeInsets.symmetric(horizontal: 20, vertical: 15),
              ),
            ),
          ),
        ),

        Expanded(
          child: filtered.isEmpty
            ? _buildEmptyState(
                context,
                icon: LucideIcons.clock,
                title: 'NO HISTORY FOUND',
                subtitle: 'YOUR PREVIOUS CUSTOMIZATION LOGS WILL APPEAR HERE.',
              )
            : ListView.builder(
                padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 10),
                itemCount: filtered.length,
                itemBuilder: (context, index) {
                  final req = filtered[index];
                  return _HistoryCard(req: req).animate().fadeIn(delay: (index * 100).ms).slideY(begin: 0.1);
                },
              ),
        ),
      ],
    );
  }

  Widget _buildEmptyState(BuildContext context, {required IconData icon, required String title, required String subtitle}) {
    final foreground = Theme.of(context).colorScheme.onSurface;
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Container(
            padding: const EdgeInsets.all(32),
            decoration: BoxDecoration(
              color: foreground.withOpacity(0.03),
              shape: BoxShape.circle,
              border: Border.all(color: foreground.withOpacity(0.05)),
            ),
            child: Icon(icon, color: foreground.withOpacity(0.1), size: 48),
          ),
          const SizedBox(height: 24),
          Text(
            title,
            style: GoogleFonts.montserrat(
              color: foreground,
              fontWeight: FontWeight.w900,
              fontSize: 14,
              letterSpacing: 2,
            ),
          ),
          const SizedBox(height: 8),
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 48),
            child: Text(
              subtitle,
              textAlign: TextAlign.center,
              style: GoogleFonts.montserrat(
                color: foreground.withOpacity(0.2),
                fontWeight: FontWeight.bold,
                fontSize: 9,
                letterSpacing: 1,
              ),
            ),
          ),
        ],
      ),
    ).animate().fadeIn();
  }
}

class _UnitCard extends ConsumerWidget {
  final dynamic unit;
  const _UnitCard({required this.unit});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final status = unit['customizationStatus'] ?? 'NOT_STARTED';
    final isNew = status == 'NOT_STARTED';
    final foreground = Theme.of(context).colorScheme.onSurface;
    final isDark = Theme.of(context).brightness == Brightness.dark;

    return Container(
      margin: const EdgeInsets.only(bottom: 16),
      decoration: BoxDecoration(
        color: (isDark ? const Color(0xFF0F172A) : Colors.black).withOpacity(isDark ? 0.4 : 0.05),
        borderRadius: BorderRadius.circular(24),
        border: Border.all(color: foreground.withOpacity(0.05)),
      ),
      child: ClipRRect(
        borderRadius: BorderRadius.circular(24),
        child: BackdropFilter(
          filter: ImageFilter.blur(sigmaX: 20, sigmaY: 20),
          child: Padding(
            padding: const EdgeInsets.all(20),
            child: Row(
              children: [
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        (unit['projectName'] ?? 'Unknown Project').toString().toUpperCase(),
                        style: GoogleFonts.montserrat(
                          color: foreground,
                          fontSize: 14,
                          fontWeight: FontWeight.w900,
                          letterSpacing: -0.2,
                        ),
                      ),
                      const SizedBox(height: 8),
                      Row(
                        children: [
                          Container(
                            padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                            decoration: BoxDecoration(
                              color: Colors.blueAccent.withOpacity(0.1),
                              borderRadius: BorderRadius.circular(6),
                            ),
                            child: Text(
                              'UNIT ${unit['unitNumber']}',
                              style: GoogleFonts.montserrat(
                                color: Colors.blueAccent,
                                fontSize: 9,
                                fontWeight: FontWeight.w900,
                              ),
                            ),
                          ),
                          const SizedBox(width: 8),
                          Text(
                            (unit['config'] ?? '').toString().toUpperCase(),
                            style: GoogleFonts.montserrat(
                              color: foreground.withOpacity(0.3),
                              fontSize: 9,
                              fontWeight: FontWeight.w900,
                              letterSpacing: 1,
                            ),
                          ),
                        ],
                      ),
                    ],
                  ),
                ),
                const SizedBox(width: 12),
                GestureDetector(
                  onTap: () {
                    final project = unit['projectId'];
                    final unitNo = unit['unitNumber'];
                    final config = unit['config'];
                    final bookingId = unit['bookingId'];

                    ref.read(customViewsBookingIdProvider.notifier).state = bookingId;
                    ref.read(customViewsProjectProvider.notifier).state = project;
                    ref.read(customViewsUnitNumberProvider.notifier).state = unitNo?.toString();
                    ref.read(customViewsUnitProvider.notifier).state = config ?? '3 BHK';
                    ref.read(customViewsEditModeProvider.notifier).state = false;
                    ref.read(customViewsSelectionsProvider.notifier).state = {};
                    
                    // Navigate to Customizer Step 1 (since project is already set)
                    ref.read(customViewsStepProvider.notifier).state = 1;
                    ref.read(navigationProvider.notifier).state = 6; // Index for CustomViewsScreen
                  },
                  child: Container(
                    padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 12),
                    decoration: BoxDecoration(
                      color: foreground,
                      borderRadius: BorderRadius.circular(12),
                    ),
                    child: Row(
                      children: [
                        Text(
                          isNew ? 'START' : 'VIEW',
                          style: GoogleFonts.montserrat(
                            color: Theme.of(context).colorScheme.surface,
                            fontSize: 10,
                            fontWeight: FontWeight.w900,
                            letterSpacing: 1,
                          ),
                        ),
                        const SizedBox(width: 6),
                        Icon(LucideIcons.chevronRight, color: Theme.of(context).colorScheme.surface.withOpacity(0.5), size: 14),
                      ],
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
}

class _HistoryCard extends StatelessWidget {
  final dynamic req;
  const _HistoryCard({required this.req});

  @override
  Widget build(BuildContext context) {
    final foreground = Theme.of(context).colorScheme.onSurface;
    final isDark = Theme.of(context).brightness == Brightness.dark;
    
    final id = req['_id']?.toString() ?? '';
    final shortId = id.length >= 6 ? id.substring(id.length - 6).toUpperCase() : id;
    final projectTitle = req['project']?['title'] ?? 'Standard Unit';
    final status = req['status'] ?? 'Pending';
    final date = req['createdAt'] != null ? DateFormat('dd/MM/yyyy').format(DateTime.parse(req['createdAt'])) : 'N/A';

    return GestureDetector(
      onTap: () => _showDetailDialog(context, req),
      child: Container(
        margin: const EdgeInsets.only(bottom: 16),
        decoration: BoxDecoration(
          color: (isDark ? const Color(0xFF0F172A) : Colors.black).withOpacity(isDark ? 0.4 : 0.05),
          borderRadius: BorderRadius.circular(24),
          border: Border.all(color: foreground.withOpacity(0.05)),
        ),
        child: ClipRRect(
          borderRadius: BorderRadius.circular(24),
          child: BackdropFilter(
            filter: ImageFilter.blur(sigmaX: 20, sigmaY: 20),
            child: Padding(
              padding: const EdgeInsets.all(20),
              child: Column(
                children: [
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      Row(
                        children: [
                          Container(
                            padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 3),
                            decoration: BoxDecoration(
                              color: foreground.withOpacity(0.05),
                              borderRadius: BorderRadius.circular(6),
                              border: Border.all(color: foreground.withOpacity(0.05)),
                            ),
                            child: Text(
                              '#$shortId',
                              style: GoogleFonts.montserrat(
                                color: foreground.withOpacity(0.3),
                                fontSize: 8,
                                fontWeight: FontWeight.w900,
                              ),
                            ),
                          ),
                          const SizedBox(width: 8),
                          _buildStatusBadge(status),
                        ],
                      ),
                      Container(
                        width: 32,
                        height: 32,
                        decoration: BoxDecoration(
                          color: foreground.withOpacity(0.03),
                          borderRadius: BorderRadius.circular(10),
                          border: Border.all(color: foreground.withOpacity(0.05)),
                        ),
                        child: Icon(LucideIcons.chevronRight, color: foreground.withOpacity(0.7), size: 16),
                      ),
                    ],
                  ),
                  const SizedBox(height: 12),
                  Align(
                    alignment: Alignment.centerLeft,
                    child: Text(
                      projectTitle.toString().toUpperCase(),
                      style: GoogleFonts.montserrat(
                        color: foreground,
                        fontSize: 14,
                        fontWeight: FontWeight.w900,
                        letterSpacing: -0.2,
                      ),
                    ),
                  ),
                  const SizedBox(height: 16),
                  Container(height: 1, color: foreground.withOpacity(0.05)),
                  const SizedBox(height: 12),
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text('CONFIGURATION', style: GoogleFonts.montserrat(color: foreground.withOpacity(0.24), fontSize: 8, fontWeight: FontWeight.w900, letterSpacing: 1)),
                          const SizedBox(height: 2),
                          Text(
                            (req['space'] ?? 'N/A').toString().toUpperCase(),
                            style: GoogleFonts.montserrat(color: foreground.withOpacity(0.7), fontSize: 10, fontWeight: FontWeight.w900),
                          ),
                        ],
                      ),
                      Column(
                        crossAxisAlignment: CrossAxisAlignment.end,
                        children: [
                          Text('LOGGED ON', style: GoogleFonts.montserrat(color: foreground.withOpacity(0.24), fontSize: 8, fontWeight: FontWeight.w900, letterSpacing: 1)),
                          const SizedBox(height: 2),
                          Text(date, style: GoogleFonts.montserrat(color: foreground.withOpacity(0.7), fontSize: 10, fontWeight: FontWeight.w900)),
                        ],
                      ),
                    ],
                  ),
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildStatusBadge(String status) {
    Color color = Colors.amberAccent;
    if (['Approved', 'Completed'].contains(status)) color = const Color(0xFF10B981);
    if (['Rejected'].contains(status)) color = Colors.redAccent;

    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
      decoration: BoxDecoration(
        color: color.withOpacity(0.1),
        borderRadius: BorderRadius.circular(6),
        border: Border.all(color: color.withOpacity(0.2)),
      ),
      child: Text(
        status.toUpperCase(),
        style: GoogleFonts.montserrat(
          color: color,
          fontSize: 8,
          fontWeight: FontWeight.w900,
          letterSpacing: 0.5,
        ),
      ),
    );
  }

  void _showDetailDialog(BuildContext context, dynamic req) {
    showGeneralDialog(
      context: context,
      barrierDismissible: true,
      barrierLabel: '',
      barrierColor: Colors.black.withOpacity(0.8),
      transitionDuration: const Duration(milliseconds: 300),
      pageBuilder: (context, anim1, anim2) => _DetailDialog(req: req),
      transitionBuilder: (context, anim1, anim2, child) {
        return BackdropFilter(
          filter: ImageFilter.blur(sigmaX: 10 * anim1.value, sigmaY: 10 * anim1.value),
          child: ScaleTransition(
            scale: Tween<double>(begin: 0.9, end: 1.0).animate(CurvedAnimation(parent: anim1, curve: Curves.easeOutCubic)),
            child: FadeTransition(opacity: anim1, child: child),
          ),
        );
      },
    );
  }
}

class _DetailDialog extends ConsumerWidget {
  final dynamic req;
  const _DetailDialog({required this.req});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final selections = req['selections'] as Map? ?? {};
    final foreground = Theme.of(context).colorScheme.onSurface;
    final background = Theme.of(context).colorScheme.surface;
    final isDark = Theme.of(context).brightness == Brightness.dark;

    return Center(
      child: Material(
        color: Colors.transparent,
        child: Container(
          margin: const EdgeInsets.symmetric(horizontal: 24),
          width: double.infinity,
          constraints: const BoxConstraints(maxWidth: 400),
          decoration: BoxDecoration(
            color: isDark ? const Color(0xFF020617) : Colors.white,
            borderRadius: BorderRadius.circular(40),
            boxShadow: [
              BoxShadow(color: Colors.black.withOpacity(0.2), blurRadius: 40, spreadRadius: -10),
            ],
          ),
          child: ClipRRect(
            borderRadius: BorderRadius.circular(40),
            child: Stack(
              children: [
                SingleChildScrollView(
                  padding: const EdgeInsets.all(32),
                  child: Column(
                    mainAxisSize: MainAxisSize.min,
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Row(
                        children: [
                          _buildHeaderBadge(context, 'LOG ID: ${req['_id']?.toString().substring(req['_id'].toString().length - 8).toUpperCase()}'),
                          const SizedBox(width: 8),
                          _buildStatusBadge(req['status'] ?? 'Pending'),
                        ],
                      ),
                      const SizedBox(height: 32),
                      Text(
                        (req['project']?['title'] ?? 'Standard Selection').toString().toUpperCase(),
                        style: GoogleFonts.montserrat(
                          fontSize: 24,
                          fontWeight: FontWeight.w900,
                          color: foreground,
                          letterSpacing: -0.5,
                          decoration: TextDecoration.none,
                        ),
                      ),
                      const SizedBox(height: 8),
                      Row(
                        children: [
                          Icon(LucideIcons.mapPin, size: 12, color: foreground.withOpacity(0.3)),
                          const SizedBox(width: 6),
                          Text(
                            (req['space'] ?? 'FULL UNIT').toString().toUpperCase(),
                            style: GoogleFonts.montserrat(
                              color: foreground.withOpacity(0.3), 
                              fontSize: 10, 
                              fontWeight: FontWeight.w900, 
                              letterSpacing: 1,
                              decoration: TextDecoration.none,
                            ),
                          ),
                        ],
                      ),
                      const SizedBox(height: 32),
                      Text(
                        'CHOSEN SPECIFICATIONS',
                        style: GoogleFonts.montserrat(
                          fontSize: 8,
                          fontWeight: FontWeight.w900,
                          color: foreground.withOpacity(0.24),
                          letterSpacing: 2,
                          decoration: TextDecoration.none,
                        ),
                      ),
                      const SizedBox(height: 16),
                      ...selections.entries.map((e) => _buildSelectionItem(context, e.key, e.value)).toList(),
                      const SizedBox(height: 32),
                      _buildActionButtons(context, ref, req),
                    ],
                  ),
                ),
                Positioned(
                  top: 24,
                  right: 24,
                  child: GestureDetector(
                    onTap: () => Navigator.pop(context),
                    child: Container(
                      width: 32,
                      height: 32,
                      decoration: BoxDecoration(
                        color: foreground.withOpacity(0.03),
                        shape: BoxShape.circle,
                      ),
                      child: Icon(LucideIcons.x, color: foreground.withOpacity(0.3), size: 18),
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

  Widget _buildActionButtons(BuildContext context, WidgetRef ref, dynamic req) {
    final status = req['status'] ?? '';
    final canModify = !(["Approved", "Completed", "Rejected", "Closed"].contains(status));
    final foreground = Theme.of(context).colorScheme.onSurface;
    final background = Theme.of(context).colorScheme.surface;

    return Row(
      children: [
        if (canModify) ...[
          Expanded(
            child: GestureDetector(
              onTap: () {
                // Initialize Customizer State
                final booking = req['bookingId'];
                final bId = (booking is Map) ? booking['_id'] : booking;
                final unitNo = (booking is Map) ? booking['unitNumber'] : null;
                final config = req['unitType'];
                final project = req['project']?['_id'];

                ref.read(customViewsBookingIdProvider.notifier).state = bId;
                ref.read(customViewsProjectProvider.notifier).state = project;
                ref.read(customViewsUnitNumberProvider.notifier).state = unitNo;
                ref.read(customViewsUnitProvider.notifier).state = config ?? '3 BHK';
                ref.read(customViewsEditModeProvider.notifier).state = true;
                ref.read(customViewsSelectionsProvider.notifier).state = Map<String, dynamic>.from(req['selections'] as Map? ?? {});
                
                // Navigate to Customizer Step 1 (since project is already set)
                ref.read(customViewsStepProvider.notifier).state = 1;
                ref.read(navigationProvider.notifier).state = 6; // Index for CustomViewsScreen
                
                Navigator.pop(context); // Close dialog
              },
              child: Container(
                height: 48,
                decoration: BoxDecoration(
                  color: foreground,
                  borderRadius: BorderRadius.circular(16),
                ),
                child: Center(
                  child: Text(
                    'MODIFY SELECTIONS',
                    style: GoogleFonts.montserrat(
                      color: background,
                      fontSize: 9,
                      fontWeight: FontWeight.w900,
                      letterSpacing: 1,
                      decoration: TextDecoration.none,
                    ),
                  ),
                ),
              ),
            ),
          ),
          const SizedBox(width: 12),
        ],
        Expanded(
          child: GestureDetector(
            onTap: () => Navigator.pop(context),
            child: Container(
              height: 48,
              decoration: BoxDecoration(
                color: background,
                borderRadius: BorderRadius.circular(16),
                border: Border.all(color: foreground.withOpacity(0.1)),
              ),
              child: Center(
                child: Text(
                  'CLOSE VIEW',
                  style: GoogleFonts.montserrat(
                    color: foreground.withOpacity(0.7),
                    fontSize: 8,
                    fontWeight: FontWeight.w900,
                    letterSpacing: 2,
                  ),
                ),
              ),
            ),
          ),
        ),
      ],
    );
  }

  Widget _buildSelectionItem(BuildContext context, String key, dynamic val) {
    final foreground = Theme.of(context).colorScheme.onSurface;
    final isDark = Theme.of(context).brightness == Brightness.dark;
    String name = val.toString();
    if (val is Map) name = val['name'] ?? val['title'] ?? val.toString();

    IconData icon = LucideIcons.box;
    if (key.toLowerCase().contains('flooring')) icon = LucideIcons.layers;
    if (key.toLowerCase().contains('door')) icon = LucideIcons.box;
    if (key.toLowerCase().contains('bath')) icon = LucideIcons.paintBucket;
    if (key.toLowerCase().contains('lighting')) icon = LucideIcons.sparkles;

    return Container(
      margin: const EdgeInsets.only(bottom: 12),
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: (isDark ? Colors.white : Colors.black).withOpacity(0.03),
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: foreground.withOpacity(0.05)),
      ),
      child: Row(
        children: [
          Container(
            width: 40,
            height: 40,
            decoration: BoxDecoration(
              color: foreground.withOpacity(0.05),
              borderRadius: BorderRadius.circular(10),
            ),
            child: Icon(icon, color: foreground.withOpacity(0.5), size: 18),
          ),
          const SizedBox(width: 16),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(key.toUpperCase(), style: GoogleFonts.montserrat(color: foreground.withOpacity(0.24), fontSize: 7, fontWeight: FontWeight.w900, letterSpacing: 2)),
                const SizedBox(height: 2),
                Text(name.toUpperCase(), style: GoogleFonts.montserrat(color: foreground, fontSize: 12, fontWeight: FontWeight.w800)),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildHeaderBadge(BuildContext context, String label) {
    final foreground = Theme.of(context).colorScheme.onSurface;
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
      decoration: BoxDecoration(
        color: foreground.withOpacity(0.05),
        borderRadius: BorderRadius.circular(8),
        border: Border.all(color: foreground.withOpacity(0.05)),
      ),
      child: Text(
        label,
        style: GoogleFonts.montserrat(color: foreground.withOpacity(0.3), fontSize: 8, fontWeight: FontWeight.w900, letterSpacing: 1),
      ),
    );
  }

  Widget _buildStatusBadge(String status) {
    Color color = Colors.amberAccent;
    if (['Approved', 'Completed'].contains(status)) color = const Color(0xFF10B981);
    if (['Rejected'].contains(status)) color = Colors.redAccent;

    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
      decoration: BoxDecoration(
        color: color.withOpacity(0.1),
        borderRadius: BorderRadius.circular(8),
        border: Border.all(color: color.withOpacity(0.2)),
      ),
      child: Text(
        status.toUpperCase(),
        style: GoogleFonts.montserrat(color: color, fontSize: 8, fontWeight: FontWeight.w900, letterSpacing: 1),
      ),
    );
  }
}
