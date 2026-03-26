import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:lucide_icons/lucide_icons.dart';
import 'package:flutter_animate/flutter_animate.dart';
import 'package:intl/intl.dart';
import 'dart:ui';
import 'package:m4_mobile/presentation/providers/selection_logs_provider.dart';
import 'package:m4_mobile/presentation/widgets/main_shell.dart';

class SelectionLogsScreen extends ConsumerStatefulWidget {
  const SelectionLogsScreen({super.key});

  @override
  ConsumerState<SelectionLogsScreen> createState() => _SelectionLogsScreenState();
}

class _SelectionLogsScreenState extends ConsumerState<SelectionLogsScreen> {
  @override
  void initState() {
    super.initState();
    Future.microtask(() => ref.read(selectionLogsProvider.notifier).fetchLogs());
  }

  @override
  Widget build(BuildContext context) {
    final state = ref.watch(selectionLogsProvider);

    return Scaffold(
      backgroundColor: Theme.of(context).scaffoldBackgroundColor,
      body: Container(
        color: Theme.of(context).scaffoldBackgroundColor,
        child: SafeArea(
          child: Column(
            children: [
              _buildHeader(context),
              Expanded(
                child: RefreshIndicator(
                  onRefresh: () => ref.read(selectionLogsProvider.notifier).fetchLogs(),
                  color: Colors.black,
                  backgroundColor: Colors.white,
                  child: state.isLoading && state.logs.isEmpty
                      ? const Center(child: CircularProgressIndicator(color: Colors.white24))
                      : state.logs.isEmpty
                          ? _buildEmptyState()
                          : ListView.builder(
                              padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 20),
                              itemCount: state.logs.length,
                              itemBuilder: (context, index) {
                                final log = state.logs[index];
                                return _LogItem(log: log).animate().fadeIn(delay: (index * 100).ms).slideY(begin: 0.1);
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
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 20),
      child: Row(
        children: [
          IconButton(
            onPressed: () => ref.read(navigationProvider.notifier).state = 0,
            icon: Icon(LucideIcons.chevronLeft, color: Theme.of(context).colorScheme.onSurface.withOpacity(0.7)),
          ),
          const SizedBox(width: 4),
          Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                'SELECTION LOGS',
                style: GoogleFonts.montserrat(
                  fontSize: 24,
                  fontWeight: FontWeight.w300,
                  color: Theme.of(context).colorScheme.onSurface,
                  letterSpacing: 2,
                ),
              ),
              Text(
                'YOUR CUSTOMIZATION HISTORY',
                style: GoogleFonts.montserrat(
                  fontSize: 9,
                  fontWeight: FontWeight.w900,
                  color: Theme.of(context).colorScheme.onSurface.withOpacity(0.5),
                  letterSpacing: 4,
                ),
              ),
            ],
          ),
        ],
      ),
    ).animate().fadeIn().slideX(begin: -0.1);
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
            child: Icon(LucideIcons.fileText, color: Theme.of(context).colorScheme.onSurface.withOpacity(0.2), size: 48),
          ),
          const SizedBox(height: 24),
          Text(
            'NO SELECTIONS YET',
            style: GoogleFonts.montserrat(
              color: Theme.of(context).colorScheme.onSurface,
              fontWeight: FontWeight.w900,
              fontSize: 14,
              letterSpacing: 2,
            ),
          ),
          const SizedBox(height: 8),
          Text(
            'YOUR PROJECT CUSTOMIZATIONS WILL APPEAR HERE',
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

class _LogItem extends StatelessWidget {
  final dynamic log;

  const _LogItem({required this.log});

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final DateTime? createdAt = log['createdAt'] != null ? DateTime.parse(log['createdAt']) : null;
    final String dateStr = createdAt != null ? DateFormat('MMM dd, yyyy • hh:mm a').format(createdAt) : 'Unknown Date';
    final project = log['project'];
    final String projectName = project is Map ? (project['title'] ?? project['name'] ?? 'Undefined Project') : 'Undefined Project';
    
    final selections = log['selections'] as Map? ?? {};

    return Container(
      margin: const EdgeInsets.only(bottom: 20),
      decoration: BoxDecoration(
        color: (isDark ? Colors.white : Colors.black).withOpacity(0.03),
        borderRadius: BorderRadius.circular(24),
        border: Border.all(color: (isDark ? Colors.white : Colors.black).withOpacity(0.05)),
      ),
      child: ClipRRect(
        borderRadius: BorderRadius.circular(24),
        child: BackdropFilter(
          filter: ImageFilter.blur(sigmaX: 10, sigmaY: 10),
          child: ExpansionTile(
            backgroundColor: Colors.transparent,
            collapsedBackgroundColor: Colors.transparent,
            tilePadding: const EdgeInsets.all(20),
            iconColor: Theme.of(context).colorScheme.onSurface,
            collapsedIconColor: Theme.of(context).colorScheme.onSurface.withOpacity(0.2),
            title: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  children: [
                    Container(
                      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                      decoration: BoxDecoration(
                        color: (isDark ? Colors.white : Colors.black).withOpacity(0.1),
                        borderRadius: BorderRadius.circular(6),
                      ),
                      child: Text(
                        '#${log['_id']?.toString().substring(log['_id'].toString().length >= 6 ? log['_id'].toString().length - 6 : 0).toUpperCase() ?? '000000'}',
                        style: GoogleFonts.montserrat(
                          color: Theme.of(context).colorScheme.onSurface.withOpacity(0.5),
                          fontSize: 9,
                          fontWeight: FontWeight.w900,
                        ),
                      ),
                    ),
                    const SizedBox(width: 8),
                    Flexible(
                      child: Text(
                        projectName.toUpperCase(),
                        style: GoogleFonts.montserrat(
                          color: Theme.of(context).colorScheme.onSurface,
                          fontWeight: FontWeight.w800,
                          fontSize: 14,
                          letterSpacing: 0.5,
                        ),
                        overflow: TextOverflow.ellipsis,
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 12),
                Row(
                  children: [
                    Icon(LucideIcons.calendar, size: 12, color: Theme.of(context).colorScheme.onSurface.withOpacity(0.2)),
                    const SizedBox(width: 6),
                    Text(
                      dateStr.toUpperCase(),
                      style: GoogleFonts.montserrat(
                        color: Theme.of(context).colorScheme.onSurface.withOpacity(0.2),
                        fontSize: 9,
                        fontWeight: FontWeight.w900,
                        letterSpacing: 1,
                      ),
                    ),
                  ],
                ),
              ],
            ),
            children: [
              Padding(
                padding: const EdgeInsets.fromLTRB(20, 0, 20, 20),
                child: Column(
                  children: [
                    Divider(color: (isDark ? Colors.white : Colors.black).withOpacity(0.1)),
                    const SizedBox(height: 16),
                    ...selections.entries.map((entry) => _buildSelectionRow(context, entry.key, entry.value)).toList(),
                  ],
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildSelectionRow(BuildContext context, String label, dynamic value) {
    String displayValue = value.toString();
    if (value is Map) {
      displayValue = value['name'] ?? value['title'] ?? value['label'] ?? value.toString();
    }

    return Padding(
      padding: const EdgeInsets.only(bottom: 12),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Expanded(
            flex: 2,
            child: Text(
              label.toUpperCase(),
              style: GoogleFonts.montserrat(
                color: Theme.of(context).colorScheme.onSurface.withOpacity(0.5),
                fontSize: 10,
                fontWeight: FontWeight.w700,
                letterSpacing: 1,
              ),
            ),
          ),
          const SizedBox(width: 10),
          Expanded(
            flex: 3,
            child: Text(
              displayValue.toUpperCase(),
              textAlign: TextAlign.right,
              style: GoogleFonts.montserrat(
                color: Theme.of(context).colorScheme.onSurface,
                fontSize: 11,
                fontWeight: FontWeight.w900,
              ),
            ),
          ),
        ],
      ),
    );
  }
}
