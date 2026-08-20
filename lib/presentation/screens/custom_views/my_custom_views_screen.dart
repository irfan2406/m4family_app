import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:lucide_icons/lucide_icons.dart';
import 'package:flutter_animate/flutter_animate.dart';
import 'package:m4_mobile/presentation/widgets/main_shell.dart';
import 'package:m4_mobile/presentation/providers/custom_views_provider.dart';
import 'package:m4_mobile/presentation/providers/my_custom_views_provider.dart';

// Web parity: the Portfolio Suite uses an orange accent (title highlight,
// active tab, section icons) instead of the neutral foreground colour.
// Portfolio accent: M4 deep green (was coral, which read as off-brand orange
// against the cream page and the bright hero photo).
const Color _kPortfolioOrange = Color(0xFF0C312B);

class MyCustomViewsScreen extends ConsumerStatefulWidget {
  const MyCustomViewsScreen({super.key});

  @override
  ConsumerState<MyCustomViewsScreen> createState() =>
      _MyCustomViewsScreenState();
}

class _MyCustomViewsScreenState extends ConsumerState<MyCustomViewsScreen> {
  int _activeTab = 0; // 0 for Selection, 1 for History
  String _historyQuery = ''; // Web parity: history search-by-project-or-id

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
      // Web parity: header is left-aligned (title right after the back button).
      centerTitle: false,
      titleSpacing: 8,
      backgroundColor: Theme.of(context).colorScheme.surface.withOpacity(0.8),
      surfaceTintColor: Colors.transparent,
      leadingWidth: 60,
      leading: Center(
        child: GestureDetector(
          // Pushed (from profile / menu) → pop the route; if it's shown as a
          // shell tab instead, fall back to switching to the Profile tab.
          onTap: () {
            if (context.canPop()) {
              context.pop();
            } else {
              ref.read(navigationProvider.notifier).state = 3;
            }
          },
          // Web parity: back button in a rounded bordered card box.
          child: Container(
            width: 40,
            height: 40,
            decoration: BoxDecoration(
              color: Theme.of(context).colorScheme.surface,
              borderRadius: BorderRadius.circular(12),
              border: Border.all(
                color: Theme.of(context).colorScheme.onSurface.withOpacity(0.1),
              ),
            ),
            child: const Icon(LucideIcons.arrowLeft, size: 20),
          ),
        ),
      ),
      title: Column(
        mainAxisSize: MainAxisSize.min,
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Web parity: "Personalisation Suite" title + "Portfolio Dashboard"
          // subtitle with a paint-bucket icon.
          Text(
            'PORTFOLIO SUITE',
            style: GoogleFonts.ebGaramond(
              fontSize: 14,
              fontWeight: FontWeight.w600,
              letterSpacing: -0.5,
            ),
          ),
          Row(
            mainAxisSize: MainAxisSize.min,
            children: [
              const Icon(
                LucideIcons.paintBucket,
                size: 10,
                color: _kPortfolioOrange,
              ),
              const SizedBox(width: 5),
              Text(
                'ASSET DASHBOARD',
                style: GoogleFonts.gelasio(
                  fontSize: 8,
                  fontWeight: FontWeight.w700,
                  letterSpacing: 2,
                  color: _kPortfolioOrange,
                ),
              ),
            ],
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
        // Web parity: same hero image web uses (/assets/custom_view_1.png).
        image: const DecorationImage(
          image: AssetImage('assets/custom_view_1.png'),
          fit: BoxFit.cover,
        ),
      ),
      child: Container(
        decoration: BoxDecoration(
          borderRadius: BorderRadius.circular(40),
          // Web parity: light overlay — transparent (top) -> white (bottom)
          // matches `bg-gradient-to-t from-background via-background/20 to-transparent`.
          gradient: LinearGradient(
            begin: Alignment.topCenter,
            end: Alignment.bottomCenter,
            colors: [
              Colors.transparent,
              Colors.white.withOpacity(0.15),
              Colors.white.withOpacity(0.88),
            ],
            stops: const [0.0, 0.5, 1.0],
          ),
        ),
        padding: const EdgeInsets.all(32),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.end,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Web parity: serif "MY" (light) + "PORTFOLIO" (bold).
            RichText(
              text: TextSpan(
                children: [
                  // Web parity: dark `text-foreground`; MY (light) + PORTFOLIO (bold).
                  TextSpan(
                    text: 'ELITE ',
                    style: GoogleFonts.gelasio(
                      color: Color(0xFF0C312B),
                      fontSize: 30,
                      fontWeight: FontWeight.w500,
                      letterSpacing: -0.5,
                    ),
                  ),
                  TextSpan(
                    text: 'PORTFOLIO',
                    style: GoogleFonts.gelasio(
                      color: _kPortfolioOrange,
                      fontSize: 30,
                      fontWeight: FontWeight.w700,
                      letterSpacing: -0.5,
                    ),
                  ),
                ],
              ),
            ).animate().fadeIn(duration: 800.ms).slideY(begin: 0.2, end: 0),
            Text(
              'PERSONALISATION SUITE',
              style: GoogleFonts.gelasio(
                // Web parity: orange `text-primary`, readable on the light fade.
                color: _kPortfolioOrange,
                fontSize: 12,
                fontWeight: FontWeight.w700,
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
            'Automatic reflection of your purchased units from the M4 Admin Panel. Select a unit below to start or manage your bespoke interior customizations.',
            style: GoogleFonts.ebGaramond(
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
          color: isDark
              ? Colors.white.withOpacity(0.05)
              : Colors.black.withOpacity(0.03),
          borderRadius: BorderRadius.circular(20),
        ),
        child: Row(
          children: [
            Expanded(
              child: GestureDetector(
                onTap: () => setState(() => _activeTab = 0),
                child: Container(
                  decoration: BoxDecoration(
                    color: _activeTab == 0
                        ? _kPortfolioOrange
                        : Colors.transparent,
                    borderRadius: BorderRadius.circular(16),
                  ),
                  alignment: Alignment.center,
                  child: Text(
                    'SELECTION',
                    style: GoogleFonts.ebGaramond(
                      fontSize: 10,
                      fontWeight: FontWeight.w600,
                      letterSpacing: 1,
                      color: _activeTab == 0
                          ? Colors.white
                          : Theme.of(
                              context,
                            ).colorScheme.onSurface.withOpacity(0.68),
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
                    color: _activeTab == 1
                        ? _kPortfolioOrange
                        : Colors.transparent,
                    borderRadius: BorderRadius.circular(16),
                  ),
                  alignment: Alignment.center,
                  child: Text(
                    'HISTORY',
                    style: GoogleFonts.ebGaramond(
                      fontSize: 10,
                      fontWeight: FontWeight.w600,
                      letterSpacing: 1,
                      color: _activeTab == 1
                          ? Colors.white
                          : Theme.of(
                              context,
                            ).colorScheme.onSurface.withOpacity(0.68),
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
      return const SliverFillRemaining(
        child: Center(child: CircularProgressIndicator()),
      );
    }
    if (state.units.isEmpty) {
      final foreground = isDark ? Colors.white : Color(0xFF163A2C);
      // Web parity: styled empty-state card (orange icon box + heading + copy)
      // under the "ASSET CUSTOMIZATION STATUS" header, not bare text.
      return SliverToBoxAdapter(
        child: Column(
          children: [
            Padding(
              padding: const EdgeInsets.only(top: 4, bottom: 20),
              child: Row(
                children: [
                  const Icon(
                    LucideIcons.paintBucket,
                    size: 16,
                    color: _kPortfolioOrange,
                  ),
                  const SizedBox(width: 12),
                  Text(
                    'ASSET CUSTOMIZATION STATUS',
                    style: GoogleFonts.gelasio(
                      fontSize: 10,
                      fontWeight: FontWeight.w700,
                      letterSpacing: 2,
                      color: foreground.withOpacity(0.6),
                    ),
                  ),
                ],
              ),
            ),
            Container(
              width: double.infinity,
              padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 48),
              decoration: BoxDecoration(
                color: isDark ? Colors.white.withOpacity(0.02) : const Color(0xFFF4EFE3),
                borderRadius: BorderRadius.circular(20),
                border: Border.all(color: foreground.withOpacity(0.06)),
                boxShadow: isDark
                    ? null
                    : [
                        BoxShadow(
                          color: Colors.black.withOpacity(0.03),
                          blurRadius: 20,
                          offset: const Offset(0, 10),
                        ),
                      ],
              ),
              child: Column(
                children: [
                  Container(
                    width: 72,
                    height: 72,
                    decoration: BoxDecoration(
                      color: _kPortfolioOrange.withOpacity(0.12),
                      borderRadius: BorderRadius.circular(24),
                    ),
                    child: const Icon(
                      LucideIcons.layoutGrid,
                      color: _kPortfolioOrange,
                      size: 30,
                    ),
                  ),
                  const SizedBox(height: 24),
                  Text(
                    'NO UNITS FOUND',
                    style: GoogleFonts.ebGaramond(
                      fontSize: 16,
                      fontWeight: FontWeight.w600,
                      color: foreground,
                      letterSpacing: 0.5,
                    ),
                  ),
                  const SizedBox(height: 12),
                  Text(
                    'You currently have no purchased units registered in your portfolio that support online customization.',
                    textAlign: TextAlign.center,
                    style: GoogleFonts.ebGaramond(
                      fontSize: 12,
                      fontWeight: FontWeight.w500,
                      height: 1.6,
                      color: foreground.withOpacity(0.5),
                    ),
                  ),
                ],
              ),
            ),
          ],
        ),
      );
    }

    return SliverList(
      delegate: SliverChildBuilderDelegate((context, index) {
        // Web parity: "Select Unit to Customize" header above the cards.
        if (index == 0) {
          return Padding(
            padding: const EdgeInsets.only(top: 4, bottom: 20),
            child: Row(
              children: [
                const Icon(
                  LucideIcons.paintBucket,
                  size: 16,
                  color: _kPortfolioOrange,
                ),
                const SizedBox(width: 12),
                Text(
                  'ASSET CUSTOMIZATION STATUS',
                  style: GoogleFonts.gelasio(
                    fontSize: 10,
                    fontWeight: FontWeight.w700,
                    letterSpacing: 2,
                    color: Theme.of(
                      context,
                    ).colorScheme.onSurface.withOpacity(0.6),
                  ),
                ),
              ],
            ),
          );
        }
        return _UnitCard(unit: state.units[index - 1], isDark: isDark);
      }, childCount: state.units.length + 1),
    );
  }

  Widget _buildHistoryList(MyCustomViewsState state, bool isDark) {
    if (state.isLoadingHistory) {
      return const SliverFillRemaining(
        child: Center(child: CircularProgressIndicator()),
      );
    }

    final foreground = isDark ? Colors.white : Color(0xFF163A2C);
    final q = _historyQuery.trim().toLowerCase();
    // Web parity: filter by project title or log id.
    final filtered = state.history.where((req) {
      if (q.isEmpty) return true;
      final title = (req['project']?['title'] ?? '').toString().toLowerCase();
      final id = (req['_id'] ?? '').toString().toLowerCase();
      return title.contains(q) || id.contains(q);
    }).toList();

    return SliverList(
      delegate: SliverChildBuilderDelegate((context, index) {
        if (index == 0) {
          return _buildHistoryHeader(filtered.length, foreground, isDark);
        }
        if (filtered.isEmpty) {
          // Web parity: dashed "No history found" box.
          return Container(
            padding: const EdgeInsets.symmetric(vertical: 60),
            decoration: BoxDecoration(
              color: foreground.withOpacity(0.02),
              borderRadius: BorderRadius.circular(20),
              border: Border.all(
                color: foreground.withOpacity(0.12),
                style: BorderStyle.solid,
              ),
            ),
            child: Center(
              child: Text(
                'NO HISTORY FOUND',
                style: GoogleFonts.gelasio(
                  fontSize: 10,
                  fontWeight: FontWeight.w700,
                  letterSpacing: 2,
                  color: foreground.withOpacity(0.68),
                ),
              ),
            ),
          );
        }
        final req = filtered[index - 1];
        return _HistoryCard(
          req: req,
          isDark: isDark,
          onTap: () => _DetailDialog.show(context, ref, req, state.units),
        );
      }, childCount: filtered.isEmpty ? 2 : filtered.length + 1),
    );
  }

  // Web parity: "SELECTION HISTORY" header + LOGS count + search bar.
  Widget _buildHistoryHeader(int count, Color fg, bool isDark) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            Row(
              children: [
                Icon(LucideIcons.clock, size: 16, color: fg),
                const SizedBox(width: 12),
                Text(
                  'SELECTION HISTORY',
                  style: GoogleFonts.gelasio(
                    fontSize: 10,
                    fontWeight: FontWeight.w700,
                    letterSpacing: 2,
                    color: fg.withOpacity(0.6),
                  ),
                ),
              ],
            ),
            Text(
              '$count LOGS',
              style: GoogleFonts.gelasio(
                fontSize: 8,
                fontWeight: FontWeight.w700,
                letterSpacing: 1.5,
                color: fg.withOpacity(0.68),
              ),
            ),
          ],
        ),
        const SizedBox(height: 24),
        Container(
          height: 52,
          decoration: BoxDecoration(
            color: isDark ? Colors.white.withOpacity(0.03) : const Color(0xFFF4EFE3),
            borderRadius: BorderRadius.circular(18),
            border: Border.all(color: fg.withOpacity(0.08)),
          ),
          child: TextField(
            onChanged: (v) => setState(() => _historyQuery = v),
            style: GoogleFonts.gelasio(
              fontSize: 15,
              fontWeight: FontWeight.w700,
              letterSpacing: 1.5,
              color: fg,
            ),
            decoration: InputDecoration(
              isCollapsed: true,
              contentPadding: const EdgeInsets.symmetric(vertical: 18),
              filled: false,
              border: InputBorder.none,
              enabledBorder: InputBorder.none,
              focusedBorder: InputBorder.none,
              prefixIcon: Icon(
                LucideIcons.search,
                size: 16,
                color: fg.withOpacity(0.4),
              ),
              hintText: 'SEARCH BY PROJECT OR ID...',
              hintStyle: GoogleFonts.gelasio(
                fontSize: 10,
                fontWeight: FontWeight.w700,
                letterSpacing: 1.5,
                color: fg.withOpacity(0.68),
              ),
            ),
          ),
        ),
        const SizedBox(height: 24),
      ],
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
    final foreground = isDark ? Colors.white : Color(0xFF163A2C);

    return Container(
      margin: const EdgeInsets.only(bottom: 24),
      decoration: BoxDecoration(
        color: isDark ? const Color(0xFF141B3A) : const Color(0xFFF4EFE3),
        borderRadius: BorderRadius.circular(20),
        border: Border.all(
          color: isDark
              ? Colors.white.withOpacity(0.1)
              : Colors.black.withOpacity(0.05),
        ),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.05),
            blurRadius: 20,
            offset: const Offset(0, 10),
          ),
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
                        unit['bookingId']
                                ?.toString()
                                .substring(
                                  unit['bookingId'].toString().length - 8,
                                )
                                .toUpperCase() ??
                            'UNIT',
                        style: GoogleFonts.ebGaramond(
                          fontSize: 7,
                          fontWeight: FontWeight.w600,
                          color: foreground.withOpacity(0.68),
                          letterSpacing: 1,
                        ),
                      ),
                      Text(
                        unit['projectName']?.toString().toUpperCase() ??
                            'M4 PROJECT',
                        style: GoogleFonts.ebGaramond(
                          fontSize: 13,
                          fontWeight: FontWeight.w600,
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

          Divider(
            height: 1,
            color: isDark
                ? Colors.white.withOpacity(0.05)
                : Colors.black.withOpacity(0.05),
          ),

          // Details Grid
          Padding(
            padding: const EdgeInsets.all(24),
            child: Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                // Web parity: Project / Unit No. / Config (status is in the badge).
                _DetailItem(
                  label: 'PROJECT',
                  value: unit['projectName']?.toString() ?? 'N/A',
                  isDark: isDark,
                ),
                _DetailItem(
                  label: 'UNIT NO.',
                  value: unit['unitNumber']?.toString() ?? 'N/A',
                  isDark: isDark,
                ),
                _DetailItem(
                  label: 'CONFIG',
                  value: unit['config']?.toString() ?? 'N/A',
                  isDark: isDark,
                  isPrimary: true,
                ),
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
                final currentStatus =
                    unit['customizationStatus'] ?? 'NOT_STARTED';

                const int modificationLimit = 2;
                const int daysLimit = 30;
                final int modCount = unit['modificationCount'] ?? 0;
                final String? allotmentDate = unit['allotmentDate'];

                bool isBreachedCount = modCount >= modificationLimit;
                bool isBreachedTime = false;
                if (allotmentDate != null) {
                  final allotment = DateTime.tryParse(allotmentDate);
                  if (allotment != null) {
                    final daysPassed = DateTime.now()
                        .difference(allotment)
                        .inDays;
                    if (daysPassed > daysLimit) isBreachedTime = true;
                  }
                }

                if ([
                  'SUBMITTED',
                  'APPROVED',
                  'COMPLETED',
                ].contains(currentStatus)) {
                  if (isBreachedCount) {
                    ScaffoldMessenger.of(context).showSnackBar(
                      const SnackBar(
                        content: Text(
                          'Maximum modification limit reached (2 revisions).',
                        ),
                        backgroundColor: Colors.redAccent,
                      ),
                    );
                    return;
                  }
                  if (isBreachedTime) {
                    ScaffoldMessenger.of(context).showSnackBar(
                      const SnackBar(
                        content: Text(
                          'The 30-day modification window has expired.',
                        ),
                        backgroundColor: Colors.redAccent,
                      ),
                    );
                    return;
                  }
                }

                ref.read(customViewsBookingIdProvider.notifier).state =
                    bookingId;
                ref.read(customViewsProjectProvider.notifier).state = project;
                ref.read(customViewsUnitNumberProvider.notifier).state = unitNo
                    ?.toString();
                ref.read(customViewsUnitProvider.notifier).state =
                    config ?? '3 BHK';
                ref.read(customViewsEditModeProvider.notifier).state = [
                  'SUBMITTED',
                  'APPROVED',
                  'COMPLETED',
                ].contains(currentStatus);
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
                        status == 'NOT_STARTED'
                            ? 'START PERSONALISATION'
                            : 'MANAGE SELECTION',
                        style: GoogleFonts.ebGaramond(
                          color: isDark ? Colors.black : const Color(0xFFF4EFE3),
                          fontSize: 11,
                          fontWeight: FontWeight.w600,
                          letterSpacing: 1.2,
                        ),
                      ),
                      const SizedBox(width: 10),
                      Icon(
                        LucideIcons.chevronRight,
                        size: 16,
                        color: isDark ? Colors.black : const Color(0xFFF4EFE3),
                      ),
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
  const _HistoryCard({
    required this.req,
    required this.isDark,
    required this.onTap,
  });

  String _fmtDate(dynamic raw) {
    if (raw == null) return 'N/A';
    try {
      final d = DateTime.parse(raw.toString()).toLocal();
      return '${d.month}/${d.day}/${d.year}';
    } catch (_) {
      return 'N/A';
    }
  }

  @override
  Widget build(BuildContext context) {
    final foreground = isDark ? Colors.white : Color(0xFF163A2C);
    final id =
        req['_id']
            ?.toString()
            .substring(req['_id'].toString().length - 6)
            .toUpperCase() ??
        'UNK';
    final status = req['status'] ?? 'Submitted';
    final space = req['space']?.toString().toUpperCase() ?? 'N/A';
    final date = _fmtDate(req['createdAt']);

    return GestureDetector(
      onTap: onTap,
      child: Container(
        margin: const EdgeInsets.only(bottom: 16),
        padding: const EdgeInsets.all(24),
        decoration: BoxDecoration(
          color: isDark
              ? const Color(0xFF141B3A).withOpacity(0.4)
              : Colors.white,
          borderRadius: BorderRadius.circular(28),
          border: Border.all(
            color: isDark
                ? Colors.white.withOpacity(0.1)
                : Colors.black.withOpacity(0.05),
          ),
          boxShadow: isDark
              ? null
              : [
                  BoxShadow(
                    color: Colors.black.withOpacity(0.04),
                    blurRadius: 20,
                    offset: const Offset(0, 8),
                  ),
                ],
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      // Web parity: #ID badge first, then status badge.
                      Row(
                        children: [
                          _StatusBadge(
                            status: '#$id',
                            isDark: isDark,
                            customColor: Colors.grey,
                          ),
                          const SizedBox(width: 8),
                          _StatusBadge(status: status, isDark: isDark),
                        ],
                      ),
                      const SizedBox(height: 12),
                      Text(
                        req['project']?['title']?.toString().toUpperCase() ??
                            'STANDARD UNIT',
                        style: GoogleFonts.ebGaramond(
                          fontSize: 13,
                          fontWeight: FontWeight.w600,
                          color: foreground,
                        ),
                      ),
                    ],
                  ),
                ),
                const SizedBox(width: 12),
                Container(
                  width: 40,
                  height: 40,
                  decoration: BoxDecoration(
                    color: isDark
                        ? Colors.white.withOpacity(0.05)
                        : Colors.black.withOpacity(0.03),
                    borderRadius: BorderRadius.circular(12),
                    border: Border.all(color: foreground.withOpacity(0.06)),
                  ),
                  child: Icon(
                    LucideIcons.chevronRight,
                    size: 18,
                    color: foreground.withOpacity(0.4),
                  ),
                ),
              ],
            ),
            const SizedBox(height: 20),
            Divider(height: 1, color: foreground.withOpacity(0.08)),
            const SizedBox(height: 16),
            // Web parity: CONFIGURATION (left) / LOGGED ON (right).
            Row(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Expanded(
                  child: _HistoryMeta(
                    label: 'CONFIGURATION',
                    value: space,
                    foreground: foreground,
                    alignEnd: false,
                  ),
                ),
                _HistoryMeta(
                  label: 'LOGGED ON',
                  value: date,
                  foreground: foreground,
                  alignEnd: true,
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }
}

class _HistoryMeta extends StatelessWidget {
  final String label;
  final String value;
  final Color foreground;
  final bool alignEnd;
  const _HistoryMeta({
    required this.label,
    required this.value,
    required this.foreground,
    required this.alignEnd,
  });

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: alignEnd
          ? CrossAxisAlignment.end
          : CrossAxisAlignment.start,
      children: [
        Text(
          label,
          style: GoogleFonts.gelasio(
            fontSize: 8,
            fontWeight: FontWeight.w700,
            letterSpacing: 1.5,
            color: foreground.withOpacity(0.68),
          ),
        ),
        const SizedBox(height: 6),
        Text(
          value,
          textAlign: alignEnd ? TextAlign.right : TextAlign.left,
          style: GoogleFonts.ebGaramond(
            fontSize: 10,
            fontWeight: FontWeight.w700,
            color: foreground,
          ),
        ),
      ],
    );
  }
}

class _DetailDialog {
  static void show(
    BuildContext context,
    WidgetRef ref,
    dynamic req,
    List<dynamic> units,
  ) {
    showDialog(
      context: context,
      builder: (context) {
        String? errorMessage;

        return StatefulBuilder(
          builder: (context, setState) {
            return Dialog(
              backgroundColor: Theme.of(context).colorScheme.surface,
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(20),
              ),
              child: Container(
                // Medium-size, internally scrollable modal.
                constraints: BoxConstraints(
                  maxWidth: 400,
                  maxHeight: MediaQuery.of(context).size.height * 0.72,
                ),
                child: Stack(
                  children: [
                    SingleChildScrollView(
                      child: Column(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          Padding(
                            padding: const EdgeInsets.fromLTRB(24, 52, 24, 0),
                            child: Row(
                              mainAxisAlignment: MainAxisAlignment.spaceBetween,
                              children: [
                                _StatusBadge(
                                  status:
                                      'LOG ID: ${req['_id'].toString().substring(req['_id'].toString().length - 8).toUpperCase()}',
                                  isDark:
                                      Theme.of(context).brightness ==
                                      Brightness.dark,
                                  customColor: Colors.grey,
                                ),
                                _StatusBadge(
                                  status:
                                      req['status']?.toString().toUpperCase() ??
                                      'PENDING',
                                  isDark:
                                      Theme.of(context).brightness ==
                                      Brightness.dark,
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
                                  req['project']?['title'] ??
                                      'Standard Selection',
                                  style: GoogleFonts.gelasio(
                                    fontSize: 18,
                                    fontWeight: FontWeight.w700,
                                    letterSpacing: -0.5,
                                  ),
                                ),
                                const SizedBox(height: 8),
                                Row(
                                  crossAxisAlignment: CrossAxisAlignment.start,
                                  children: [
                                    Padding(
                                      padding: const EdgeInsets.only(top: 2),
                                      child: Icon(
                                        LucideIcons.mapPin,
                                        size: 12,
                                        color: Theme.of(
                                          context,
                                        ).colorScheme.primary.withOpacity(0.6),
                                      ),
                                    ),
                                    const SizedBox(width: 6),
                                    // Web parity: wraps to a second line (no overflow).
                                    Expanded(
                                      child: Text(
                                        req['space']
                                                ?.toString()
                                                .toUpperCase() ??
                                            'FULL UNIT',
                                        style: GoogleFonts.ebGaramond(
                                          fontSize: 9,
                                          fontWeight: FontWeight.w500,
                                          letterSpacing: 1.2,
                                          height: 1.4,
                                          color: Theme.of(context)
                                              .colorScheme
                                              .onSurface
                                              .withOpacity(0.68),
                                        ),
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
                                // Web parity: skip space/spaces/status; per-space
                                // maps -> "{space} / {catId}" + material name.
                                ...(() {
                                  final scheme = Theme.of(context).colorScheme;
                                  final selections =
                                      req['selections'] as Map? ?? {};
                                  Widget specCard(String label, String name) {
                                    return Container(
                                      margin: const EdgeInsets.only(bottom: 12),
                                      padding: const EdgeInsets.all(12),
                                      decoration: BoxDecoration(
                                        color: scheme.onSurface.withOpacity(
                                          0.03,
                                        ),
                                        borderRadius: BorderRadius.circular(20),
                                        border: Border.all(
                                          color: scheme.onSurface.withOpacity(
                                            0.05,
                                          ),
                                        ),
                                      ),
                                      child: Row(
                                        children: [
                                          Container(
                                            width: 44,
                                            height: 44,
                                            decoration: BoxDecoration(
                                              color: scheme.onSurface
                                                  .withOpacity(0.06),
                                              borderRadius:
                                                  BorderRadius.circular(14),
                                            ),
                                            child: Icon(
                                              LucideIcons.box,
                                              size: 20,
                                              color: scheme.onSurface
                                                  .withOpacity(0.6),
                                            ),
                                          ),
                                          const SizedBox(width: 16),
                                          Expanded(
                                            child: Column(
                                              crossAxisAlignment:
                                                  CrossAxisAlignment.start,
                                              children: [
                                                Text(
                                                  label.toUpperCase(),
                                                  maxLines: 1,
                                                  overflow:
                                                      TextOverflow.ellipsis,
                                                  style:
                                                      GoogleFonts.ebGaramond(
                                                        fontSize: 7,
                                                        fontWeight:
                                                            FontWeight.w600,
                                                        letterSpacing: 1.0,
                                                        color: scheme.onSurface
                                                            .withOpacity(0.68),
                                                      ),
                                                ),
                                                const SizedBox(height: 2),
                                                Text(
                                                  name.toUpperCase(),
                                                  maxLines: 1,
                                                  overflow:
                                                      TextOverflow.ellipsis,
                                                  style:
                                                      GoogleFonts.ebGaramond(
                                                        fontSize: 11,
                                                        fontWeight:
                                                            FontWeight.w600,
                                                        letterSpacing: 0.5,
                                                      ),
                                                ),
                                              ],
                                            ),
                                          ),
                                        ],
                                      ),
                                    );
                                  }

                                  final rows = <Widget>[];
                                  selections.forEach((key, val) {
                                    if (key == 'space' ||
                                        key == 'spaces' ||
                                        key == 'status') {
                                      return;
                                    }
                                    if (val is Map &&
                                        val['name'] == null &&
                                        val['_id'] == null) {
                                      // Per-space map: {catId: opt}.
                                      val.forEach((catId, opt) {
                                        if (opt is Map && opt['name'] != null) {
                                          rows.add(
                                            specCard(
                                              '$key / $catId',
                                              opt['name'].toString(),
                                            ),
                                          );
                                        }
                                      });
                                    } else if (val is Map &&
                                        val['name'] != null) {
                                      // Flat: catId -> opt.
                                      rows.add(
                                        specCard(
                                          key.toString(),
                                          val['name'].toString(),
                                        ),
                                      );
                                    }
                                  });
                                  return rows;
                                })(),
                              ],
                            ),
                          ),
                          const SizedBox(height: 32),
                          if (errorMessage != null)
                            Padding(
                              padding: const EdgeInsets.symmetric(
                                horizontal: 24,
                                vertical: 8,
                              ),
                              child: Container(
                                width: double.infinity,
                                padding: const EdgeInsets.all(12),
                                decoration: BoxDecoration(
                                  color: Colors.red.withOpacity(0.1),
                                  borderRadius: BorderRadius.circular(12),
                                  border: Border.all(
                                    color: Colors.red.withOpacity(0.2),
                                  ),
                                ),
                                child: Text(
                                  errorMessage!.toUpperCase(),
                                  textAlign: TextAlign.center,
                                  style: GoogleFonts.ebGaramond(
                                    color: Colors.redAccent,
                                    fontSize: 9,
                                    fontWeight: FontWeight.w500,
                                    letterSpacing: 1.0,
                                  ),
                                ),
                              ),
                            ),
                          Padding(
                            padding: const EdgeInsets.fromLTRB(24, 0, 24, 32),
                            child: Row(
                              children: [
                                if (!([
                                  'Approved',
                                  'Completed',
                                  'Rejected',
                                  'Closed',
                                ].contains(req['status'])))
                                  Expanded(
                                    child: GestureDetector(
                                      onTap: () {
                                        const int modificationLimit = 2;
                                        const int daysLimit = 30;
                                        final int modCount =
                                            req['modificationCount'] ?? 0;
                                        final String? allotmentDate =
                                            req['allotmentDate'];

                                        bool isBreachedCount =
                                            modCount >= modificationLimit;
                                        bool isBreachedTime = false;
                                        if (allotmentDate != null) {
                                          final allotment = DateTime.tryParse(
                                            allotmentDate,
                                          );
                                          if (allotment != null) {
                                            final daysPassed = DateTime.now()
                                                .difference(allotment)
                                                .inDays;
                                            if (daysPassed > daysLimit)
                                              isBreachedTime = true;
                                          }
                                        }

                                        if (isBreachedCount) {
                                          setState(() {
                                            errorMessage =
                                                'LIMIT REACHED: YOU HAVE ALREADY USED YOUR 2 REVISION ATTEMPTS.';
                                          });
                                          return;
                                        }
                                        if (isBreachedTime) {
                                          setState(() {
                                            errorMessage =
                                                'THE 30-DAY MODIFICATION WINDOW FOR YOUR UNIT HAS EXPIRED.';
                                          });
                                          return;
                                        }

                                        final booking = req['bookingId'];
                                        final bId = (booking is Map)
                                            ? booking['_id']
                                            : booking;
                                        final unitNo = (booking is Map)
                                            ? booking['unitNumber']
                                            : null;
                                        final config = req['unitType'];
                                        final project = req['project']?['_id'];

                                        ref
                                                .read(
                                                  customViewsBookingIdProvider
                                                      .notifier,
                                                )
                                                .state =
                                            bId;
                                        ref
                                                .read(
                                                  customViewsProjectProvider
                                                      .notifier,
                                                )
                                                .state =
                                            project;
                                        ref
                                            .read(
                                              customViewsUnitNumberProvider
                                                  .notifier,
                                            )
                                            .state = unitNo
                                            ?.toString();
                                        ref
                                                .read(
                                                  customViewsUnitProvider
                                                      .notifier,
                                                )
                                                .state =
                                            config ?? '3 BHK';
                                        ref
                                                .read(
                                                  customViewsEditModeProvider
                                                      .notifier,
                                                )
                                                .state =
                                            true;
                                        ref
                                            .read(
                                              customViewsSelectionsProvider
                                                  .notifier,
                                            )
                                            .state = Map<String, dynamic>.from(
                                          req['selections'] as Map? ?? {},
                                        );

                                        ref
                                                .read(
                                                  customViewsStepProvider
                                                      .notifier,
                                                )
                                                .state =
                                            0;
                                        ref
                                                .read(
                                                  previousNavigationProvider
                                                      .notifier,
                                                )
                                                .state =
                                            7;
                                        ref
                                                .read(
                                                  navigationProvider.notifier,
                                                )
                                                .state =
                                            6;

                                        Navigator.pop(context);
                                      },
                                      child: Container(
                                        height: 54,
                                        decoration: BoxDecoration(
                                          color: Colors.black,
                                          borderRadius: BorderRadius.circular(
                                            20,
                                          ),
                                        ),
                                        alignment: Alignment.center,
                                        padding: const EdgeInsets.symmetric(
                                          horizontal: 18,
                                        ),
                                        child: FittedBox(
                                          fit: BoxFit.scaleDown,
                                          child: Text(
                                            'MODIFY SELECTIONS',
                                            textAlign: TextAlign.center,
                                            style: GoogleFonts.ebGaramond(
                                              color: Colors.white,
                                              fontSize: 10,
                                              fontWeight: FontWeight.w600,
                                              letterSpacing: 1,
                                            ),
                                          ),
                                        ),
                                      ),
                                    ),
                                  ),
                                if (!([
                                  'Approved',
                                  'Completed',
                                  'Rejected',
                                  'Closed',
                                ].contains(req['status'])))
                                  const SizedBox(width: 12),
                                Expanded(
                                  child: GestureDetector(
                                    onTap: () => Navigator.pop(context),
                                    child: Container(
                                      height: 54,
                                      decoration: BoxDecoration(
                                        color: Colors.transparent,
                                        borderRadius: BorderRadius.circular(20),
                                        border: Border.all(
                                          color: Theme.of(context)
                                              .colorScheme
                                              .onSurface
                                              .withOpacity(0.1),
                                        ),
                                      ),
                                      alignment: Alignment.center,
                                      padding: const EdgeInsets.symmetric(
                                        horizontal: 18,
                                      ),
                                      child: FittedBox(
                                        fit: BoxFit.scaleDown,
                                        child: Text(
                                          'CLOSE VIEW',
                                          textAlign: TextAlign.center,
                                          style: GoogleFonts.ebGaramond(
                                            color: Theme.of(context)
                                                .colorScheme
                                                .onSurface
                                                .withOpacity(0.68),
                                            fontSize: 9,
                                            fontWeight: FontWeight.w500,
                                            letterSpacing: 1,
                                          ),
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
                    // Web parity: close (X) button in the top-right corner.
                    Positioned(
                      top: 12,
                      right: 12,
                      child: GestureDetector(
                        onTap: () => Navigator.pop(context),
                        child: Container(
                          width: 32,
                          height: 32,
                          decoration: BoxDecoration(
                            color: Theme.of(
                              context,
                            ).colorScheme.onSurface.withOpacity(0.06),
                            shape: BoxShape.circle,
                          ),
                          child: Icon(
                            LucideIcons.x,
                            size: 16,
                            color: Theme.of(
                              context,
                            ).colorScheme.onSurface.withOpacity(0.6),
                          ),
                        ),
                      ),
                    ),
                  ],
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
      style: GoogleFonts.gelasio(
        fontSize: 8,
        fontWeight: FontWeight.w700,
        letterSpacing: 2,
        color: Theme.of(context).colorScheme.onSurface.withOpacity(0.68),
      ),
    );
  }
}

class _StatusBadge extends StatelessWidget {
  final String status;
  final bool isDark;
  final Color? customColor;
  const _StatusBadge({
    required this.status,
    required this.isDark,
    this.customColor,
  });

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
        // Web parity: "NOT STARTED" (space, not underscore).
        status.replaceAll('_', ' ').toUpperCase(),
        style: GoogleFonts.ebGaramond(
          color: color,
          fontSize: 8,
          fontWeight: FontWeight.w600,
        ),
      ),
    );
  }

  // Web parity: getStatusStyles() — requested/pending/submitted = amber,
  // approved/closed = green, completed/reviewed/contacted = blue,
  // rejected = red, everything else (draft, not_started) = grey.
  Color _getStatusColor(String status) {
    switch (status.toLowerCase()) {
      case 'approved':
      case 'closed':
        return const Color(0xFF163A2C); // green-500
      case 'completed':
      case 'reviewed':
      case 'contacted':
        return const Color(0xFFC5A35B); // blue-500
      case 'rejected':
        return const Color(0xFFC65B46); // red-500
      case 'requested':
      case 'pending':
      case 'submitted':
        return const Color(0xFFC5A35B); // amber-500
      default:
        return Colors.grey;
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
        color:
            color?.withOpacity(0.1) ??
            (isDark
                ? Colors.white.withOpacity(0.05)
                : Colors.black.withOpacity(0.03)),
        borderRadius: BorderRadius.circular(12),
      ),
      child: Icon(
        icon,
        size: 20,
        color: color ?? (isDark ? Colors.white : Color(0xFF163A2C)),
      ),
    );
  }
}

class _DetailItem extends StatelessWidget {
  final String label;
  final String value;
  final bool isDark;
  final bool isPrimary;
  const _DetailItem({
    required this.label,
    required this.value,
    required this.isDark,
    this.isPrimary = false,
  });

  @override
  Widget build(BuildContext context) {
    final foreground = isDark ? Colors.white : Color(0xFF163A2C);
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          label,
          style: GoogleFonts.ebGaramond(
            fontSize: 8,
            fontWeight: FontWeight.w600,
            color: foreground.withOpacity(0.68),
            letterSpacing: 1.2,
          ),
        ),
        const SizedBox(height: 6),
        Text(
          value.toUpperCase(),
          style: GoogleFonts.ebGaramond(
            fontSize: 11,
            fontWeight: FontWeight.w600,
            color: isPrimary
                ? Theme.of(context).colorScheme.primary
                : foreground,
          ),
        ),
      ],
    );
  }
}
