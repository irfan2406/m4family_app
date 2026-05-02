import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:lucide_icons/lucide_icons.dart';
import 'package:flutter_animate/flutter_animate.dart';
import 'package:intl/intl.dart';
import 'dart:ui';
import 'package:m4_mobile/presentation/providers/selection_logs_provider.dart';
import 'package:m4_mobile/presentation/providers/custom_views_provider.dart';
import 'package:m4_mobile/presentation/widgets/main_shell.dart';

class SelectionLogsScreen extends ConsumerStatefulWidget {
  const SelectionLogsScreen({super.key});

  @override
  ConsumerState<SelectionLogsScreen> createState() => _SelectionLogsScreenState();
}

class _SelectionLogsScreenState extends ConsumerState<SelectionLogsScreen> {
  String _searchQuery = '';

  @override
  void initState() {
    super.initState();
    Future.microtask(() => ref.read(selectionLogsProvider.notifier).fetchLogs());
  }

  @override
  Widget build(BuildContext context) {
    final state = ref.watch(selectionLogsProvider);
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final foreground = Theme.of(context).colorScheme.onSurface;

    final filteredLogs = state.logs.where((log) {
      final projectName = (log['project']?['title'] ?? 'Undefined Project').toString().toLowerCase();
      final id = log['_id']?.toString().toLowerCase() ?? '';
      return projectName.contains(_searchQuery.toLowerCase()) || id.contains(_searchQuery.toLowerCase());
    }).toList();

    return Scaffold(
      backgroundColor: Theme.of(context).scaffoldBackgroundColor,
      body: Container(
        color: Theme.of(context).scaffoldBackgroundColor,
        child: SafeArea(
          child: Column(
            children: [
              _buildHeader(context),
              _buildSearchBar(context, isDark, foreground),
              _buildSectionInfo(context, filteredLogs.length, foreground),
              Expanded(
                child: RefreshIndicator(
                  onRefresh: () => ref.read(selectionLogsProvider.notifier).fetchLogs(),
                  color: foreground,
                  backgroundColor: Theme.of(context).scaffoldBackgroundColor,
                  child: state.isLoading && state.logs.isEmpty
                      ? Center(child: CircularProgressIndicator(color: foreground.withOpacity(0.2)))
                      : filteredLogs.isEmpty
                          ? _buildEmptyState()
                          : ListView.builder(
                              padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 10),
                              itemCount: filteredLogs.length,
                              itemBuilder: (context, index) {
                                final log = filteredLogs[index];
                                return _LogCard(log: log).animate().fadeIn(delay: (index * 100).ms).slideY(begin: 0.1);
                              },
                            ),
                ),
              ),
            ],
          ),
        ),
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
            onTap: () => ref.read(navigationProvider.notifier).state = 3,
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
                  'CUSTOMIZATION LOGS',
                  style: GoogleFonts.montserrat(
                    fontSize: 16,
                    fontWeight: FontWeight.w900,
                    color: foreground,
                    letterSpacing: -0.5,
                  ),
                ),
                Text(
                  'PREVIOUS SELECTIONS',
                  style: GoogleFonts.montserrat(
                    fontSize: 9,
                    fontWeight: FontWeight.w900,
                    color: foreground.withOpacity(0.3),
                    letterSpacing: 4,
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    ).animate().fadeIn().slideX(begin: -0.1);
  }

  Widget _buildSearchBar(BuildContext context, bool isDark, Color foreground) {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 12),
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
            hintText: 'SEARCH BY ID OR PROJECT...',
            hintStyle: GoogleFonts.montserrat(
              color: foreground.withOpacity(0.24),
              fontSize: 10,
              fontWeight: FontWeight.w900,
              letterSpacing: 1,
            ),
            prefixIcon: Icon(LucideIcons.search, size: 16, color: foreground.withOpacity(0.24)),
            border: InputBorder.none,
            contentPadding: const EdgeInsets.symmetric(horizontal: 20, vertical: 15),
          ),
        ),
      ),
    );
  }

  Widget _buildSectionInfo(BuildContext context, int count, Color foreground) {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 8),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Text(
            'SELECTION AUDIT',
            style: GoogleFonts.montserrat(
              fontSize: 9,
              fontWeight: FontWeight.w900,
              color: foreground.withOpacity(0.45),
              letterSpacing: 2,
            ),
          ),
          Text(
            '$count LOGS RETRIEVED',
            style: GoogleFonts.montserrat(
              fontSize: 9,
              fontWeight: FontWeight.w900,
              color: foreground.withOpacity(0.45),
              letterSpacing: 1,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildEmptyState() {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Container(
            padding: const EdgeInsets.all(32),
            decoration: BoxDecoration(
              color: (isDark ? Colors.white : Colors.black).withOpacity(0.03),
              shape: BoxShape.circle,
              border: Border.all(color: (isDark ? Colors.white : Colors.black).withOpacity(0.05)),
            ),
            child: Icon(LucideIcons.fileStack, color: Theme.of(context).colorScheme.onSurface.withOpacity(0.1), size: 48),
          ),
          const SizedBox(height: 24),
          Text(
            'NO LOGS FOUND',
            style: GoogleFonts.montserrat(
              color: Theme.of(context).colorScheme.onSurface,
              fontWeight: FontWeight.w900,
              fontSize: 14,
              letterSpacing: 2,
            ),
          ),
          const SizedBox(height: 8),
          Text(
            'YOUR CUSTOMIZATION HISTORY WILL APPEAR HERE',
            style: GoogleFonts.montserrat(
              color: Theme.of(context).colorScheme.onSurface.withOpacity(0.2),
              fontWeight: FontWeight.bold,
              fontSize: 9,
              letterSpacing: 1,
            ),
          ),
        ],
      ),
    ).animate().fadeIn();
  }
}

class _LogCard extends StatelessWidget {
  final dynamic log;
  const _LogCard({required this.log});

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final foreground = Theme.of(context).colorScheme.onSurface;
    final id = log['_id']?.toString() ?? '';
    final shortId = id.length >= 6 ? id.substring(id.length - 6).toUpperCase() : id;
    final projectName = (log['project']?['title'] ?? log['project']?['name'] ?? 'Undefined Project').toString();
    final status = (log['status'] ?? 'REQUESTED').toString().toUpperCase();
    final createdAt = log['createdAt'] != null ? DateTime.parse(log['createdAt']) : DateTime.now();
    final dateStr = DateFormat('M/d/yyyy').format(createdAt);
    final selections = log['selections'] as Map? ?? {};
    final space = (log['space'] ?? selections['space'] ?? 'N/A').toString();

    // Extract summary chips (names only)
    List<String> summaryItems = [];
    selections.forEach((key, value) {
      if (key != 'space') {
        if (value is Map) {
          summaryItems.add(value['name'] ?? value['title'] ?? value['label'] ?? value.toString());
        } else {
          summaryItems.add(value.toString());
        }
      }
    });

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
            padding: const EdgeInsets.all(24),
            child: Column(
              children: [
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Row(
                      children: [
                        Container(
                          padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 5),
                          decoration: BoxDecoration(
                            color: foreground.withOpacity(0.05),
                            borderRadius: BorderRadius.circular(8),
                            border: Border.all(color: foreground.withOpacity(0.05)),
                          ),
                          child: Text(
                            '#$shortId',
                            style: GoogleFonts.montserrat(
                              color: foreground.withOpacity(0.3),
                              fontSize: 9,
                              fontWeight: FontWeight.w900,
                            ),
                          ),
                        ),
                        const SizedBox(width: 8),
                        _buildStatusBadge(status),
                      ],
                    ),
                    GestureDetector(
                      onTap: () => _showDetailDialog(context, log),
                      child: Container(
                        width: 36,
                        height: 36,
                        decoration: BoxDecoration(
                          color: foreground.withOpacity(0.03),
                          borderRadius: BorderRadius.circular(12),
                          border: Border.all(color: foreground.withOpacity(0.05)),
                        ),
                        child: Icon(LucideIcons.chevronRight, color: foreground.withOpacity(0.7), size: 18),
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 16),
                Align(
                  alignment: Alignment.centerLeft,
                  child: Text(
                    projectName.toUpperCase(),
                    style: GoogleFonts.montserrat(
                      color: foreground,
                      fontSize: 15,
                      fontWeight: FontWeight.w900,
                      letterSpacing: -0.2,
                    ),
                  ),
                ),
                const SizedBox(height: 20),
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    _buildDetailInfo(context, 'LOCATION', space.toUpperCase()),
                    _buildDetailInfo(context, 'LOGGED ON', dateStr, alignEnd: true),
                  ],
                ),
                const SizedBox(height: 20),
                Container(height: 1, color: foreground.withOpacity(0.05)),
                const SizedBox(height: 16),
                Align(
                  alignment: Alignment.centerLeft,
                  child: Text(
                    'SELECTION SUMMARY',
                    style: GoogleFonts.montserrat(
                      fontSize: 8,
                      fontWeight: FontWeight.w900,
                      color: foreground.withOpacity(0.3),
                      letterSpacing: 1.5,
                    ),
                  ),
                ),
                const SizedBox(height: 12),
                Row(
                  children: [
                    ...summaryItems.take(2).map((item) => _buildSummaryChip(context, item)),
                    if (summaryItems.length > 2)
                      Text(
                        ' +${summaryItems.length - 2} MORE',
                        style: GoogleFonts.montserrat(
                          fontSize: 8,
                          fontWeight: FontWeight.w900,
                          color: foreground.withOpacity(0.3),
                        ),
                      ),
                  ],
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildStatusBadge(String status) {
    Color color = Colors.orangeAccent;
    if (['APPROVED', 'COMPLETED'].contains(status)) color = const Color(0xFF10B981);
    if (['REJECTED'].contains(status)) color = Colors.redAccent;

    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 5),
      decoration: BoxDecoration(
        color: color.withOpacity(0.1),
        borderRadius: BorderRadius.circular(8),
        border: Border.all(color: color.withOpacity(0.2)),
      ),
      child: Text(
        status,
        style: GoogleFonts.montserrat(
          color: color,
          fontSize: 8,
          fontWeight: FontWeight.w900,
          letterSpacing: 0.5,
        ),
      ),
    );
  }

  Widget _buildDetailInfo(BuildContext context, String label, String value, {bool alignEnd = false}) {
    final foreground = Theme.of(context).colorScheme.onSurface;
    return Column(
      crossAxisAlignment: alignEnd ? CrossAxisAlignment.end : CrossAxisAlignment.start,
      children: [
        Text(
          label,
          style: GoogleFonts.montserrat(
            fontSize: 8,
            fontWeight: FontWeight.w900,
            color: foreground.withOpacity(0.2),
            letterSpacing: 1,
          ),
        ),
        const SizedBox(height: 4),
        Text(
          value,
          style: GoogleFonts.montserrat(
            fontSize: 11,
            fontWeight: FontWeight.w800,
            color: foreground.withOpacity(0.8),
            fontStyle: FontStyle.italic,
          ),
        ),
      ],
    );
  }

  Widget _buildSummaryChip(BuildContext context, String label) {
    final foreground = Theme.of(context).colorScheme.onSurface;
    return Container(
      margin: const EdgeInsets.only(right: 8),
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 5),
      decoration: BoxDecoration(
        color: foreground.withOpacity(0.05),
        borderRadius: BorderRadius.circular(20),
        border: Border.all(color: foreground.withOpacity(0.05)),
      ),
      child: Text(
        label.toUpperCase(),
        style: GoogleFonts.montserrat(
          color: foreground.withOpacity(0.7),
          fontSize: 7.5,
          fontWeight: FontWeight.w900,
        ),
      ),
    );
  }

  void _showDetailDialog(BuildContext context, dynamic log) {
    showGeneralDialog(
      context: context,
      barrierDismissible: true,
      barrierLabel: '',
      barrierColor: Colors.black.withOpacity(0.8),
      transitionDuration: const Duration(milliseconds: 300),
      pageBuilder: (context, anim1, anim2) => _LogDetailDialog(log: log),
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

class _LogDetailDialog extends ConsumerWidget {
  final dynamic log;
  const _LogDetailDialog({required this.log});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final foreground = Theme.of(context).colorScheme.onSurface;
    final id = log['_id']?.toString() ?? '';
    final shortId = id.length >= 6 ? id.substring(id.length - 6).toUpperCase() : id;
    final projectName = (log['project']?['title'] ?? log['project']?['name'] ?? 'Undefined Project').toString();
    final status = (log['status'] ?? 'REQUESTED').toString().toUpperCase();
    final selections = log['selections'] as Map? ?? {};
    final space = (log['space'] ?? selections['space'] ?? 'N/A').toString();

    return Center(
      child: Container(
        width: MediaQuery.of(context).size.width * 0.9,
        constraints: BoxConstraints(
          maxHeight: MediaQuery.of(context).size.height * 0.85,
        ),
        decoration: BoxDecoration(
          color: Theme.of(context).scaffoldBackgroundColor,
          borderRadius: BorderRadius.circular(40),
          border: Border.all(color: foreground.withOpacity(0.1)),
          boxShadow: [
            BoxShadow(color: Colors.black.withOpacity(0.5), blurRadius: 40, offset: const Offset(0, 20)),
          ],
        ),
        child: ClipRRect(
          borderRadius: BorderRadius.circular(40),
          child: Material(
            color: Colors.transparent,
            child: SingleChildScrollView(
              padding: const EdgeInsets.all(32),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      Row(
                        children: [
                          Container(
                            padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 5),
                            decoration: BoxDecoration(
                              color: foreground.withOpacity(0.05),
                              borderRadius: BorderRadius.circular(8),
                            ),
                            child: Text(
                              'LOG ID: #$shortId',
                              style: GoogleFonts.montserrat(
                                color: foreground.withOpacity(0.5),
                                fontSize: 9,
                                fontWeight: FontWeight.w900,
                              ),
                            ),
                          ),
                          const SizedBox(width: 8),
                          _buildStatusBadge(status),
                        ],
                      ),
                      IconButton(
                        onPressed: () => Navigator.pop(context),
                        icon: Icon(LucideIcons.x, color: foreground.withOpacity(0.3), size: 20),
                      ),
                    ],
                  ),
                  const SizedBox(height: 24),
                  Text(
                    projectName.toUpperCase(),
                    style: GoogleFonts.montserrat(
                      fontSize: 24,
                      fontWeight: FontWeight.w900,
                      color: foreground,
                      letterSpacing: -1,
                    ),
                  ),
                  const SizedBox(height: 40),
                  Text(
                    'CHOSEN SPECIFICATIONS',
                    style: GoogleFonts.montserrat(
                      fontSize: 10,
                      fontWeight: FontWeight.w900,
                      color: foreground.withOpacity(0.3),
                      letterSpacing: 2,
                    ),
                  ),
                  const SizedBox(height: 16),
                  ...selections.entries.map((entry) => _buildSpecItem(context, entry.key, entry.value)),
                  const SizedBox(height: 24),
                  Row(
                    children: [
                      Icon(LucideIcons.mapPin, size: 12, color: foreground.withOpacity(0.3)),
                      const SizedBox(width: 6),
                      Text(
                        'LOCATION: ${space.toUpperCase()}',
                        style: GoogleFonts.montserrat(
                          fontSize: 9,
                          fontWeight: FontWeight.w900,
                          color: foreground.withOpacity(0.3),
                          letterSpacing: 2,
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 40),
                  Text(
                    'PROTOCOL STATUS',
                    style: GoogleFonts.montserrat(
                      fontSize: 10,
                      fontWeight: FontWeight.w900,
                      color: foreground.withOpacity(0.3),
                      letterSpacing: 2,
                    ),
                  ),
                  const SizedBox(height: 16),
                  Container(
                    padding: const EdgeInsets.all(24),
                    decoration: BoxDecoration(
                      color: foreground.withOpacity(0.03),
                      borderRadius: BorderRadius.circular(20),
                      border: Border.all(color: foreground.withOpacity(0.05)),
                    ),
                    child: Text(
                      'Your selection is currently under review by our interior consultants. We will contact you shortly.',
                      style: GoogleFonts.montserrat(
                        fontSize: 12,
                        height: 1.6,
                        color: foreground.withOpacity(0.54),
                        fontStyle: FontStyle.italic,
                        fontWeight: FontWeight.w500,
                      ),
                    ),
                  ),
                  const SizedBox(height: 40),
                  Row(
                    children: [
                      Expanded(
                        child: _buildActionButton(
                          context,
                          'MODIFY SPECS',
                          onTap: () {
                            // Pre-load state for edit mode
                            final project = log['project'];
                            final projectId = project is Map ? project['_id']?.toString() : null;
                            final unitType = log['unitType']?.toString() ?? '3 BHK';
                            final unitNumber = log['unitNumber']?.toString();
                            final bookingId = log['bookingId'] is Map 
                                ? log['bookingId']['_id']?.toString() 
                                : log['bookingId']?.toString();
                            final selections = log['selections'] as Map? ?? {};
                            final space = log['space']?.toString();

                            // Update providers
                            ref.read(customViewsProjectProvider.notifier).state = projectId;
                            ref.read(customViewsUnitProvider.notifier).state = unitType;
                            ref.read(customViewsUnitNumberProvider.notifier).state = unitNumber;
                            ref.read(customViewsBookingIdProvider.notifier).state = bookingId;
                            
                            final selectionsMap = Map<String, dynamic>.from(selections);
                            if (space != null) selectionsMap['space'] = space;
                            ref.read(customViewsSelectionsProvider.notifier).state = selectionsMap;
                            
                            ref.read(customViewsEditModeProvider.notifier).state = true;
                            
                            // Reset step and navigate to wizard
                            if (projectId != null) {
                              ref.read(customViewsStepProvider.notifier).state = 1; // Advance to Space Selection if project known
                            } else {
                              ref.read(customViewsStepProvider.notifier).state = 0; // Start at Project Selection
                            }
                            
                            ref.read(navigationProvider.notifier).state = 6; // 6 is CustomViewsScreen (Wizard)
                            
                            Navigator.pop(context);
                          },
                          isPrimary: true,
                        ),
                      ),
                      const SizedBox(width: 12),
                      Expanded(
                        child: _buildActionButton(
                          context,
                          'CLOSE VIEW',
                          onTap: () => Navigator.pop(context),
                          isPrimary: false,
                        ),
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
    Color color = Colors.orangeAccent;
    if (['APPROVED', 'COMPLETED'].contains(status)) color = const Color(0xFF10B981);
    if (['REJECTED'].contains(status)) color = Colors.redAccent;

    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 5),
      decoration: BoxDecoration(
        color: color.withOpacity(0.1),
        borderRadius: BorderRadius.circular(8),
      ),
      child: Text(
        status,
        style: GoogleFonts.montserrat(
          color: color,
          fontSize: 8,
          fontWeight: FontWeight.w900,
        ),
      ),
    );
  }

  Widget _buildSpecItem(BuildContext context, String key, dynamic value) {
    final foreground = Theme.of(context).colorScheme.onSurface;
    String displayValue = value.toString();
    if (value is Map) {
      displayValue = value['name'] ?? value['title'] ?? value['label'] ?? value.toString();
    }

    return Container(
      margin: const EdgeInsets.only(bottom: 12),
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: foreground.withOpacity(0.03),
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: foreground.withOpacity(0.05)),
      ),
      child: Row(
        children: [
          Container(
            width: 36,
            height: 36,
            decoration: BoxDecoration(
              color: foreground.withOpacity(0.05),
              borderRadius: BorderRadius.circular(10),
            ),
            child: Icon(LucideIcons.box, size: 16, color: foreground.withOpacity(0.5)),
          ),
          const SizedBox(width: 16),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  key.toUpperCase(),
                  style: GoogleFonts.montserrat(
                    fontSize: 8,
                    fontWeight: FontWeight.w900,
                    color: foreground.withOpacity(0.3),
                    letterSpacing: 1,
                  ),
                ),
                const SizedBox(height: 2),
                Text(
                  displayValue.toUpperCase(),
                  style: GoogleFonts.montserrat(
                    fontSize: 12,
                    fontWeight: FontWeight.w900,
                    color: foreground,
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildActionButton(BuildContext context, String label, {required VoidCallback onTap, required bool isPrimary}) {
    final foreground = Theme.of(context).colorScheme.onSurface;
    return GestureDetector(
      onTap: onTap,
      child: Container(
        height: 54,
        decoration: BoxDecoration(
          color: isPrimary ? foreground : Colors.transparent,
          borderRadius: BorderRadius.circular(16),
          border: isPrimary ? null : Border.all(color: foreground.withOpacity(0.1)),
        ),
        alignment: Alignment.center,
        child: Text(
          label,
          style: GoogleFonts.montserrat(
            fontSize: 11,
            fontWeight: FontWeight.w900,
            color: isPrimary ? Theme.of(context).scaffoldBackgroundColor : foreground.withOpacity(0.6),
            letterSpacing: 1,
          ),
        ),
      ),
    );
  }
}
