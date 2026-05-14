import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:lucide_icons/lucide_icons.dart';
import 'package:flutter_animate/flutter_animate.dart';
import 'package:m4_mobile/presentation/widgets/main_shell.dart';
import 'package:m4_mobile/presentation/providers/custom_views_provider.dart';
import 'package:m4_mobile/presentation/providers/my_custom_views_provider.dart';

class MyCustomViewsScreen extends ConsumerStatefulWidget {
  const MyCustomViewsScreen({super.key});

  @override
  ConsumerState<MyCustomViewsScreen> createState() => _MyCustomViewsScreenState();
}

class _MyCustomViewsScreenState extends ConsumerState<MyCustomViewsScreen> {
  int _activeTab = 0; // 0 for Selection, 1 for History

  @override
  void initState() {
    super.initState();
    Future.microtask(() => ref.read(myCustomViewsProvider.notifier).fetchAll());
  }

  @override
  Widget build(BuildContext context) {
    final state = ref.watch(myCustomViewsProvider);
    final isDark = Theme.of(context).brightness == Brightness.dark;

    return Scaffold(
      backgroundColor: Theme.of(context).colorScheme.surface,
      body: CustomScrollView(
        physics: const BouncingScrollPhysics(),
        slivers: [
          _buildSliverAppBar(context, isDark),
          SliverToBoxAdapter(child: _buildHero(context)),
          SliverToBoxAdapter(child: _buildOverview(context)),
          SliverToBoxAdapter(child: _buildTabSwitcher(context, isDark)),
          
          SliverPadding(
            padding: const EdgeInsets.fromLTRB(24, 24, 24, 120),
            sliver: _activeTab == 0
                ? _buildUnitsList(state, isDark)
                : _buildHistoryList(state, isDark),
          ),
        ],
      ),
    );
  }

  Widget _buildSliverAppBar(BuildContext context, bool isDark) {
    return SliverAppBar(
      floating: true,
      pinned: true,
      elevation: 0,
      centerTitle: true,
      backgroundColor: Theme.of(context).colorScheme.surface.withOpacity(0.8),
      surfaceTintColor: Colors.transparent,
      leading: IconButton(
        icon: const Icon(LucideIcons.arrowLeft, size: 20),
        onPressed: () => ref.read(navigationProvider.notifier).state = 3, // Back to Profile
      ),
      title: Column(
        children: [
          Text(
            'M4 CUSTOM VIEWS',
            style: GoogleFonts.montserrat(
              fontSize: 14,
              fontWeight: FontWeight.w900,
              letterSpacing: -0.5,
            ),
          ),
          Text(
            'PERSONALISATION SUITE',
            style: GoogleFonts.montserrat(
              fontSize: 8,
              fontWeight: FontWeight.w800,
              letterSpacing: 2,
              color: Theme.of(context).colorScheme.primary,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildHero(BuildContext context) {
    return Container(
      height: 240,
      width: double.infinity,
      margin: const EdgeInsets.all(24),
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(40),
        image: const DecorationImage(
          image: NetworkImage('https://images.unsplash.com/photo-1600607687920-4e2a09cf159d?q=80&w=2000&auto=format&fit=crop'),
          fit: BoxFit.cover,
        ),
      ),
      child: Container(
        decoration: BoxDecoration(
          borderRadius: BorderRadius.circular(40),
          gradient: LinearGradient(
            begin: Alignment.topCenter,
            end: Alignment.bottomCenter,
            colors: [
              Colors.black.withOpacity(0.1),
              Colors.black.withOpacity(0.6),
            ],
          ),
        ),
        padding: const EdgeInsets.all(32),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.end,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              'MY PORTFOLIO',
              style: GoogleFonts.montserrat(
                color: Colors.white,
                fontSize: 28,
                fontWeight: FontWeight.w900,
                letterSpacing: -1,
              ),
            ).animate().fadeIn(duration: 800.ms).slideY(begin: 0.2, end: 0),
            Text(
              'Personalisation Suite',
              style: GoogleFonts.montserrat(
                color: Theme.of(context).colorScheme.primary,
                fontSize: 10,
                fontWeight: FontWeight.w900,
                letterSpacing: 3,
              ),
            ).animate().fadeIn(delay: 400.ms),
          ],
        ),
      ),
    );
  }

  Widget _buildOverview(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 32),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          _SectionTitle(title: 'OVERVIEW'),
          const SizedBox(height: 12),
          Text(
            'Your purchased units from the M4 portfolio. Select a unit to start or manage your bespoke interior customizations.',
            style: GoogleFonts.montserrat(
              fontSize: 13,
              height: 1.6,
              fontWeight: FontWeight.w500,
              color: Theme.of(context).colorScheme.onSurface.withOpacity(0.6),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildTabSwitcher(BuildContext context, bool isDark) {
    return Padding(
      padding: const EdgeInsets.fromLTRB(24, 40, 24, 8),
      child: Container(
        height: 60,
        padding: const EdgeInsets.all(6),
        decoration: BoxDecoration(
          color: isDark ? Colors.white.withOpacity(0.05) : Colors.black.withOpacity(0.03),
          borderRadius: BorderRadius.circular(20),
        ),
        child: Row(
          children: [
            Expanded(
              child: GestureDetector(
                onTap: () => setState(() => _activeTab = 0),
                child: Container(
                  decoration: BoxDecoration(
                    color: _activeTab == 0 ? Theme.of(context).colorScheme.onSurface : Colors.transparent,
                    borderRadius: BorderRadius.circular(16),
                  ),
                  alignment: Alignment.center,
                  child: Text(
                    'SELECTION',
                    style: GoogleFonts.montserrat(
                      fontSize: 10,
                      fontWeight: FontWeight.w900,
                      letterSpacing: 1,
                      color: _activeTab == 0 ? Theme.of(context).colorScheme.surface : Theme.of(context).colorScheme.onSurface.withOpacity(0.4),
                    ),
                  ),
                ),
              ),
            ),
            Expanded(
              child: GestureDetector(
                onTap: () => setState(() => _activeTab = 1),
                child: Container(
                  decoration: BoxDecoration(
                    color: _activeTab == 1 ? Theme.of(context).colorScheme.onSurface : Colors.transparent,
                    borderRadius: BorderRadius.circular(16),
                  ),
                  alignment: Alignment.center,
                  child: Text(
                    'HISTORY',
                    style: GoogleFonts.montserrat(
                      fontSize: 10,
                      fontWeight: FontWeight.w900,
                      letterSpacing: 1,
                      color: _activeTab == 1 ? Theme.of(context).colorScheme.surface : Theme.of(context).colorScheme.onSurface.withOpacity(0.4),
                    ),
                  ),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildUnitsList(MyCustomViewsState state, bool isDark) {
    if (state.isLoadingUnits) {
      return const SliverFillRemaining(child: Center(child: CircularProgressIndicator()));
    }
    if (state.units.isEmpty) {
      return SliverFillRemaining(
        child: Center(
          child: Text(
            'NO UNITS FOUND',
            style: GoogleFonts.montserrat(fontSize: 10, fontWeight: FontWeight.w800, color: Colors.grey),
          ),
        ),
      );
    }

    return SliverList(
      delegate: SliverChildBuilderDelegate(
        (context, index) => _UnitCard(unit: state.units[index], isDark: isDark),
        childCount: state.units.length,
      ),
    );
  }

  Widget _buildHistoryList(MyCustomViewsState state, bool isDark) {
    if (state.isLoadingHistory) {
      return const SliverFillRemaining(child: Center(child: CircularProgressIndicator()));
    }
    if (state.history.isEmpty) {
      return SliverFillRemaining(
        child: Center(
          child: Text(
            'NO HISTORY LOGS',
            style: GoogleFonts.montserrat(fontSize: 10, fontWeight: FontWeight.w800, color: Colors.grey),
          ),
        ),
      );
    }

    return SliverList(
      delegate: SliverChildBuilderDelegate(
        (context, index) => _HistoryCard(
          req: state.history[index], 
          isDark: isDark, 
          onTap: () => _DetailDialog.show(context, ref, state.history[index], state.units),
        ),
        childCount: state.history.length,
      ),
    );
  }
}

class _UnitCard extends ConsumerWidget {
  final dynamic unit;
  final bool isDark;
  const _UnitCard({required this.unit, required this.isDark});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final status = unit['customizationStatus'] ?? 'NOT_STARTED';
    final foreground = isDark ? Colors.white : Colors.black;

    return Container(
      margin: const EdgeInsets.only(bottom: 24),
      decoration: BoxDecoration(
        color: isDark ? const Color(0xFF18181B) : Colors.white,
        borderRadius: BorderRadius.circular(32),
        border: Border.all(color: isDark ? Colors.white.withOpacity(0.1) : Colors.black.withOpacity(0.05)),
        boxShadow: [
          BoxShadow(color: Colors.black.withOpacity(0.05), blurRadius: 20, offset: const Offset(0, 10)),
        ],
      ),
      child: Column(
        children: [
          // Header
          Padding(
            padding: const EdgeInsets.all(24),
            child: Row(
              children: [
                _IconBox(icon: LucideIcons.building2, isDark: isDark),
                const SizedBox(width: 16),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        unit['bookingId']?.toString().substring(unit['bookingId'].toString().length - 8).toUpperCase() ?? 'UNIT',
                        style: GoogleFonts.montserrat(
                          fontSize: 7,
                          fontWeight: FontWeight.w900,
                          color: foreground.withOpacity(0.3),
                          letterSpacing: 1,
                        ),
                      ),
                      Text(
                        unit['projectName']?.toString().toUpperCase() ?? 'M4 PROJECT',
                        style: GoogleFonts.montserrat(
                          fontSize: 13,
                          fontWeight: FontWeight.w900,
                          color: foreground,
                        ),
                      ),
                    ],
                  ),
                ),
                _StatusBadge(status: status, isDark: isDark),
              ],
            ),
          ),
          
          Divider(height: 1, color: isDark ? Colors.white.withOpacity(0.05) : Colors.black.withOpacity(0.05)),
          
          // Details Grid
          Padding(
            padding: const EdgeInsets.all(24),
            child: Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                _DetailItem(label: 'UNIT NO', value: unit['unitNumber']?.toString() ?? 'N/A', isDark: isDark),
                _DetailItem(label: 'CONFIG', value: unit['config']?.toString() ?? 'N/A', isDark: isDark),
                _DetailItem(label: 'STATUS', value: status.replaceAll('_', ' '), isDark: isDark, isPrimary: true),
              ],
            ),
          ),

          // Action Button
          Padding(
            padding: const EdgeInsets.fromLTRB(24, 0, 24, 24),
            child: InkWell(
              onTap: () {
                final project = unit['projectId'];
                final unitNo = unit['unitNumber'];
                final config = unit['config'];
                final bookingId = unit['bookingId'];
                final currentStatus = unit['customizationStatus'] ?? 'NOT_STARTED';
                
                const int modificationLimit = 2;
                const int daysLimit = 30;
                final int modCount = unit['modificationCount'] ?? 0;
                final String? allotmentDate = unit['allotmentDate'];
                
                bool isBreachedCount = modCount >= modificationLimit;
                bool isBreachedTime = false;
                if (allotmentDate != null) {
                  final allotment = DateTime.tryParse(allotmentDate);
                  if (allotment != null) {
                    final daysPassed = DateTime.now().difference(allotment).inDays;
                    if (daysPassed > daysLimit) isBreachedTime = true;
                  }
                }

                if (['SUBMITTED', 'APPROVED', 'COMPLETED'].contains(currentStatus)) {
                  if (isBreachedCount) {
                    ScaffoldMessenger.of(context).showSnackBar(
                      const SnackBar(content: Text('Maximum modification limit reached (2 revisions).'), backgroundColor: Colors.redAccent),
                    );
                    return;
                  }
                  if (isBreachedTime) {
                    ScaffoldMessenger.of(context).showSnackBar(
                      const SnackBar(content: Text('The 30-day modification window has expired.'), backgroundColor: Colors.redAccent),
                    );
                    return;
                  }
                }

                ref.read(customViewsBookingIdProvider.notifier).state = bookingId;
                ref.read(customViewsProjectProvider.notifier).state = project;
                ref.read(customViewsUnitNumberProvider.notifier).state = unitNo?.toString();
                ref.read(customViewsUnitProvider.notifier).state = config ?? '3 BHK';
                ref.read(customViewsEditModeProvider.notifier).state = ['SUBMITTED', 'APPROVED', 'COMPLETED'].contains(currentStatus);
                ref.read(customViewsSelectionsProvider.notifier).state = {};
                
                ref.read(customViewsStepProvider.notifier).state = 0;
                ref.read(previousNavigationProvider.notifier).state = 7;
                ref.read(navigationProvider.notifier).state = 6;
              },
              borderRadius: BorderRadius.circular(20),
              child: Container(
                height: 58,
                decoration: BoxDecoration(
                  color: foreground,
                  borderRadius: BorderRadius.circular(22),
                ),
                child: Center(
                  child: Row(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      Text(
                        status == 'NOT_STARTED' ? 'START PERSONALISATION' : 'MANAGE SELECTION',
                        style: GoogleFonts.montserrat(
                          color: isDark ? Colors.black : Colors.white,
                          fontSize: 11,
                          fontWeight: FontWeight.w900,
                          letterSpacing: 1.2,
                        ),
                      ),
                      const SizedBox(width: 10),
                      Icon(LucideIcons.chevronRight, size: 16, color: isDark ? Colors.black : Colors.white),
                    ],
                  ),
                ),
              ),
            ),
          ),
        ],
      ),
    ).animate().fadeIn(duration: 600.ms).slideY(begin: 0.1, end: 0);
  }
}

class _HistoryCard extends StatelessWidget {
  final dynamic req;
  final bool isDark;
  final VoidCallback onTap;
  const _HistoryCard({required this.req, required this.isDark, required this.onTap});

  @override
  Widget build(BuildContext context) {
    final foreground = isDark ? Colors.white : Colors.black;
    final id = req['_id']?.toString().substring(req['_id'].toString().length - 6).toUpperCase() ?? 'UNK';
    final status = req['status'] ?? 'Submitted';

    return GestureDetector(
      onTap: onTap,
      child: Container(
        margin: const EdgeInsets.only(bottom: 16),
        padding: const EdgeInsets.all(24),
        decoration: BoxDecoration(
          color: isDark ? const Color(0xFF18181B).withOpacity(0.5) : Colors.white,
          borderRadius: BorderRadius.circular(28),
          border: Border.all(color: isDark ? Colors.white.withOpacity(0.1) : Colors.black.withOpacity(0.05)),
        ),
        child: Row(
          children: [
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    children: [
                      _StatusBadge(status: status, isDark: isDark),
                      const SizedBox(width: 8),
                      Text(
                        '#$id',
                        style: GoogleFonts.montserrat(
                          fontSize: 9,
                          fontWeight: FontWeight.w800,
                          color: foreground.withOpacity(0.3),
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 12),
                  Text(
                    req['project']?['title']?.toString().toUpperCase() ?? 'STANDARD UNIT',
                    style: GoogleFonts.montserrat(
                      fontSize: 13,
                      fontWeight: FontWeight.w900,
                      color: foreground,
                    ),
                  ),
                ],
              ),
            ),
            Container(
              width: 40,
              height: 40,
              decoration: BoxDecoration(
                color: isDark ? Colors.white.withOpacity(0.05) : Colors.black.withOpacity(0.03),
                borderRadius: BorderRadius.circular(12),
              ),
              child: Icon(LucideIcons.chevronRight, size: 18, color: foreground.withOpacity(0.3)),
            ),
          ],
        ),
      ),
    );
  }
}

class _DetailDialog {
  static void show(BuildContext context, WidgetRef ref, dynamic req, List<dynamic> units) {
    showDialog(
      context: context,
      builder: (context) {
        String? errorMessage;
        
        return StatefulBuilder(
          builder: (context, setState) {
            return Dialog(
              backgroundColor: Theme.of(context).colorScheme.surface,
              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(32)),
              child: Container(
                constraints: const BoxConstraints(maxWidth: 400),
                child: SingleChildScrollView(
                  child: Column(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Padding(
                        padding: const EdgeInsets.fromLTRB(24, 32, 24, 0),
                        child: Row(
                          mainAxisAlignment: MainAxisAlignment.spaceBetween,
                          children: [
                            _StatusBadge(
                              status: 'LOG ID: ${req['_id'].toString().substring(req['_id'].toString().length - 8).toUpperCase()}', 
                              isDark: Theme.of(context).brightness == Brightness.dark,
                              customColor: Colors.grey,
                            ),
                            _StatusBadge(
                              status: req['status']?.toString().toUpperCase() ?? 'PENDING',
                              isDark: Theme.of(context).brightness == Brightness.dark,
                            ),
                          ],
                        ),
                      ),
                      Padding(
                        padding: const EdgeInsets.fromLTRB(24, 24, 24, 0),
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(
                              req['project']?['title'] ?? 'Standard Selection',
                              style: GoogleFonts.montserrat(
                                fontSize: 18,
                                fontWeight: FontWeight.w900,
                                letterSpacing: -0.5,
                              ),
                            ),
                            const SizedBox(height: 8),
                            Row(
                              children: [
                                Icon(LucideIcons.mapPin, size: 12, color: Theme.of(context).colorScheme.primary.withOpacity(0.6)),
                                const SizedBox(width: 6),
                                Text(
                                  req['space']?.toString().toUpperCase() ?? 'FULL UNIT',
                                  style: GoogleFonts.montserrat(
                                    fontSize: 9,
                                    fontWeight: FontWeight.w800,
                                    letterSpacing: 1.2,
                                    color: Theme.of(context).colorScheme.onSurface.withOpacity(0.5),
                                  ),
                                ),
                              ],
                            ),
                          ],
                        ),
                      ),
                      Padding(
                        padding: const EdgeInsets.fromLTRB(24, 32, 24, 0),
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            _SectionTitle(title: 'CHOSEN SPECIFICATIONS'),
                            const SizedBox(height: 16),
                            ...(req['selections'] as Map? ?? {}).entries.map((e) {
                              final key = e.key.toString();
                              final val = e.value;
                              final name = (val is Map) ? val['name'] : val.toString();
                              final id = (val is Map) ? val['_id'] : null;

                              return Container(
                                margin: const EdgeInsets.only(bottom: 12),
                                padding: const EdgeInsets.all(12),
                                decoration: BoxDecoration(
                                  color: Theme.of(context).colorScheme.onSurface.withOpacity(0.03),
                                  borderRadius: BorderRadius.circular(20),
                                  border: Border.all(color: Theme.of(context).colorScheme.onSurface.withOpacity(0.05)),
                                ),
                                child: Row(
                                  children: [
                                    Container(
                                      width: 44,
                                      height: 44,
                                      decoration: BoxDecoration(
                                        color: Colors.grey[200],
                                        borderRadius: BorderRadius.circular(14),
                                      ),
                                      child: const Icon(LucideIcons.box, size: 20, color: Colors.black54),
                                    ),
                                    const SizedBox(width: 16),
                                    Expanded(
                                      child: Column(
                                        crossAxisAlignment: CrossAxisAlignment.start,
                                        children: [
                                          if (id != null)
                                            Text(
                                              id.toString().toUpperCase(),
                                              style: GoogleFonts.montserrat(
                                                fontSize: 6,
                                                fontWeight: FontWeight.w800,
                                                letterSpacing: 1.0,
                                                color: Theme.of(context).colorScheme.onSurface.withOpacity(0.3),
                                              ),
                                            ),
                                          const SizedBox(height: 2),
                                          Text(
                                            name.toString().toUpperCase(),
                                            style: GoogleFonts.montserrat(
                                              fontSize: 11,
                                              fontWeight: FontWeight.w900,
                                              letterSpacing: 0.5,
                                            ),
                                          ),
                                        ],
                                      ),
                                    ),
                                  ],
                                ),
                              );
                            }).toList(),
                          ],
                        ),
                      ),
                      Padding(
                        padding: const EdgeInsets.fromLTRB(24, 24, 24, 0),
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            _SectionTitle(title: 'PROTOCOL STATUS'),
                            const SizedBox(height: 16),
                            Container(
                              padding: const EdgeInsets.all(20),
                              decoration: BoxDecoration(
                                color: Theme.of(context).colorScheme.onSurface.withOpacity(0.03),
                                borderRadius: BorderRadius.circular(24),
                                border: Border.all(color: Theme.of(context).colorScheme.onSurface.withOpacity(0.05)),
                              ),
                              child: Text(
                                'Your selection is currently under review by our interior consultants. We will contact you shortly.',
                                style: GoogleFonts.montserrat(
                                  fontSize: 12,
                                  fontWeight: FontWeight.w500,
                                  fontStyle: FontStyle.italic,
                                  height: 1.5,
                                  color: Theme.of(context).colorScheme.onSurface.withOpacity(0.6),
                                ),
                              ),
                            ),
                          ],
                        ),
                      ),
                      const SizedBox(height: 32),
                      if (errorMessage != null)
                        Padding(
                          padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 8),
                          child: Container(
                            width: double.infinity,
                            padding: const EdgeInsets.all(12),
                            decoration: BoxDecoration(
                              color: Colors.red.withOpacity(0.1),
                              borderRadius: BorderRadius.circular(12),
                              border: Border.all(color: Colors.red.withOpacity(0.2)),
                            ),
                            child: Text(
                              errorMessage!.toUpperCase(),
                              textAlign: TextAlign.center,
                              style: GoogleFonts.montserrat(
                                color: Colors.redAccent,
                                fontSize: 9,
                                fontWeight: FontWeight.w800,
                                letterSpacing: 1.0,
                              ),
                            ),
                          ),
                        ),
                      Padding(
                        padding: const EdgeInsets.fromLTRB(24, 0, 24, 32),
                        child: Row(
                          children: [
                            if (!(['Approved', 'Completed', 'Rejected', 'Closed'].contains(req['status'])))
                              Expanded(
                                child: GestureDetector(
                                  onTap: () {
                                    const int modificationLimit = 2;
                                    const int daysLimit = 30;
                                    final int modCount = req['modificationCount'] ?? 0;
                                    final String? allotmentDate = req['allotmentDate'];
                                    
                                    bool isBreachedCount = modCount >= modificationLimit;
                                    bool isBreachedTime = false;
                                    if (allotmentDate != null) {
                                      final allotment = DateTime.tryParse(allotmentDate);
                                      if (allotment != null) {
                                        final daysPassed = DateTime.now().difference(allotment).inDays;
                                        if (daysPassed > daysLimit) isBreachedTime = true;
                                      }
                                    }

                                    if (isBreachedCount) {
                                      setState(() {
                                        errorMessage = 'LIMIT REACHED: YOU HAVE ALREADY USED YOUR 2 REVISION ATTEMPTS.';
                                      });
                                      return;
                                    }
                                    if (isBreachedTime) {
                                      setState(() {
                                        errorMessage = 'THE 30-DAY MODIFICATION WINDOW FOR YOUR UNIT HAS EXPIRED.';
                                      });
                                      return;
                                    }

                                    final booking = req['bookingId'];
                                    final bId = (booking is Map) ? booking['_id'] : booking;
                                    final unitNo = (booking is Map) ? booking['unitNumber'] : null;
                                    final config = req['unitType'];
                                    final project = req['project']?['_id'];

                                    ref.read(customViewsBookingIdProvider.notifier).state = bId;
                                    ref.read(customViewsProjectProvider.notifier).state = project;
                                    ref.read(customViewsUnitNumberProvider.notifier).state = unitNo?.toString();
                                    ref.read(customViewsUnitProvider.notifier).state = config ?? '3 BHK';
                                    ref.read(customViewsEditModeProvider.notifier).state = true;
                                    ref.read(customViewsSelectionsProvider.notifier).state = Map<String, dynamic>.from(req['selections'] as Map? ?? {});
                                    
                                    ref.read(customViewsStepProvider.notifier).state = 0;
                                    ref.read(previousNavigationProvider.notifier).state = 7;
                                    ref.read(navigationProvider.notifier).state = 6;
                                    
                                    Navigator.pop(context);
                                  },
                                  child: Container(
                                    height: 54,
                                    decoration: BoxDecoration(
                                      color: Colors.black,
                                      borderRadius: BorderRadius.circular(20),
                                    ),
                                    alignment: Alignment.center,
                                    child: Text(
                                      'MODIFY SELECTIONS',
                                      style: GoogleFonts.montserrat(
                                        color: Colors.white,
                                        fontSize: 10,
                                        fontWeight: FontWeight.w900,
                                        letterSpacing: 1,
                                      ),
                                    ),
                                  ),
                                ),
                              ),
                            if (!(['Approved', 'Completed', 'Rejected', 'Closed'].contains(req['status'])))
                              const SizedBox(width: 12),
                            Expanded(
                              child: GestureDetector(
                                onTap: () => Navigator.pop(context),
                                child: Container(
                                  height: 54,
                                  decoration: BoxDecoration(
                                    color: Colors.transparent,
                                    borderRadius: BorderRadius.circular(20),
                                    border: Border.all(color: Theme.of(context).colorScheme.onSurface.withOpacity(0.1)),
                                  ),
                                  alignment: Alignment.center,
                                  child: Text(
                                    'CLOSE VIEW',
                                    style: GoogleFonts.montserrat(
                                      color: Theme.of(context).colorScheme.onSurface.withOpacity(0.5),
                                      fontSize: 9,
                                      fontWeight: FontWeight.w800,
                                      letterSpacing: 1,
                                    ),
                                  ),
                                ),
                              ),
                            ),
                          ],
                        ),
                      ),
                    ],
                  ),
                ),
              ),
            );
          },
        );
      },
    );
  }
}

// Helpers
class _SectionTitle extends StatelessWidget {
  final String title;
  const _SectionTitle({required this.title});

  @override
  Widget build(BuildContext context) {
    return Text(
      title,
      style: GoogleFonts.montserrat(
        fontSize: 8,
        fontWeight: FontWeight.w900,
        letterSpacing: 2,
        color: Theme.of(context).colorScheme.onSurface.withOpacity(0.3),
      ),
    );
  }
}

class _StatusBadge extends StatelessWidget {
  final String status;
  final bool isDark;
  final Color? customColor;
  const _StatusBadge({required this.status, required this.isDark, this.customColor});

  @override
  Widget build(BuildContext context) {
    final Color color = customColor ?? _getStatusColor(status);
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 5),
      decoration: BoxDecoration(
        color: color.withOpacity(0.1),
        borderRadius: BorderRadius.circular(8),
        border: Border.all(color: color.withOpacity(0.2)),
      ),
      child: Text(
        status.toUpperCase(),
        style: GoogleFonts.montserrat(
          color: color,
          fontSize: 8,
          fontWeight: FontWeight.w900,
        ),
      ),
    );
  }

  Color _getStatusColor(String status) {
    switch (status.toLowerCase()) {
      case 'approved':
      case 'completed': return Colors.green;
      case 'submitted':
      case 'requested': return const Color(0xFF1E40AF); // Deep Professional Blue
      case 'draft': return Colors.amber;
      default: return Colors.grey;
    }
  }
}

class _IconBox extends StatelessWidget {
  final IconData icon;
  final bool isDark;
  final Color? color;
  const _IconBox({required this.icon, required this.isDark, this.color});

  @override
  Widget build(BuildContext context) {
    return Container(
      width: 44,
      height: 44,
      decoration: BoxDecoration(
        color: color?.withOpacity(0.1) ?? (isDark ? Colors.white.withOpacity(0.05) : Colors.black.withOpacity(0.03)),
        borderRadius: BorderRadius.circular(12),
      ),
      child: Icon(icon, size: 20, color: color ?? (isDark ? Colors.white : Colors.black)),
    );
  }
}

class _DetailItem extends StatelessWidget {
  final String label;
  final String value;
  final bool isDark;
  final bool isPrimary;
  const _DetailItem({required this.label, required this.value, required this.isDark, this.isPrimary = false});

  @override
  Widget build(BuildContext context) {
    final foreground = isDark ? Colors.white : Colors.black;
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          label,
          style: GoogleFonts.montserrat(
            fontSize: 8,
            fontWeight: FontWeight.w900,
            color: foreground.withOpacity(0.3),
            letterSpacing: 1.2,
          ),
        ),
        const SizedBox(height: 6),
        Text(
          value.toUpperCase(),
          style: GoogleFonts.montserrat(
            fontSize: 11,
            fontWeight: FontWeight.w900,
            color: isPrimary ? Theme.of(context).colorScheme.primary : foreground,
          ),
        ),
      ],
    );
  }
}
