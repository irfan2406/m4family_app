import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:lucide_icons/lucide_icons.dart';
import 'package:m4_mobile/core/models/activity_log.dart';
import 'package:m4_mobile/presentation/providers/support_provider.dart';
import 'package:flutter_animate/flutter_animate.dart';
import 'package:intl/intl.dart';
import 'dart:ui';
import 'package:m4_mobile/presentation/providers/auth_provider.dart';

class SupportLogsScreen extends ConsumerStatefulWidget {
  final int initialIndex;
  const SupportLogsScreen({super.key, this.initialIndex = 0});

  @override
  ConsumerState<SupportLogsScreen> createState() => _SupportLogsScreenState();
}

class _SupportLogsScreenState extends ConsumerState<SupportLogsScreen> with SingleTickerProviderStateMixin {
  late TabController _tabController;
  final TextEditingController _searchController = TextEditingController();
  String _searchQuery = "";
  String? _selectedType;

  @override
  void initState() {
    super.initState();
    _tabController = TabController(length: 2, vsync: this, initialIndex: widget.initialIndex);
    Future.microtask(() {
      ref.read(supportProvider.notifier).fetchLogs();
      ref.read(supportProvider.notifier).fetchDocuments();
    });
  }

  @override
  void dispose() {
    _tabController.dispose();
    _searchController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final state = ref.watch(supportProvider);
    final isDark = Theme.of(context).brightness == Brightness.dark;

    return Scaffold(
      backgroundColor: Theme.of(context).scaffoldBackgroundColor,
      body: Container(
        color: Theme.of(context).scaffoldBackgroundColor,
        child: SafeArea(
          child: Column(
            children: [
              _buildHeader(context),
              _buildTabBar(isDark),
              const SizedBox(height: 10),
              _buildSearchAndFilter(isDark),
              Expanded(
                child: TabBarView(
                  controller: _tabController,
                  children: [
                    _buildLogsList(state, isDark),
                    _buildDocumentsList(state, isDark),
                  ],
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
            onPressed: () => Navigator.pop(context),
            icon: Icon(LucideIcons.chevronLeft, color: Theme.of(context).colorScheme.onSurface.withOpacity(0.7)),
          ),
          const SizedBox(width: 8),
          Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                'ACTIVITY & LOGS',
                style: GoogleFonts.montserrat(
                  fontSize: 18,
                  fontWeight: FontWeight.w700,
                  color: Theme.of(context).colorScheme.onSurface,
                  letterSpacing: 1,
                ),
              ),
              Text(
                'HISTORY & DOCUMENTS',
                style: GoogleFonts.montserrat(
                  fontSize: 9,
                  fontWeight: FontWeight.w900,
                  color: Theme.of(context).colorScheme.onSurface.withOpacity(0.5),
                  letterSpacing: 3,
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildTabBar(bool isDark) {
    return Container(
      margin: const EdgeInsets.symmetric(horizontal: 24),
      decoration: BoxDecoration(
        color: (isDark ? Colors.white : Colors.black).withOpacity(0.03),
        borderRadius: BorderRadius.circular(15),
      ),
      child: TabBar(
        controller: _tabController,
        indicator: BoxDecoration(
          color: isDark ? Colors.white : Colors.black,
          borderRadius: BorderRadius.circular(15),
        ),
        labelColor: isDark ? Colors.black : Colors.white,
        unselectedLabelColor: (isDark ? Colors.white : Colors.black).withOpacity(0.4),
        labelStyle: GoogleFonts.montserrat(fontSize: 10, fontWeight: FontWeight.w900, letterSpacing: 1),
        indicatorSize: TabBarIndicatorSize.tab,
        dividerColor: Colors.transparent,
        tabs: const [
          Tab(text: 'OPERATIONAL LOGS'),
          Tab(text: 'DOCUMENTS'),
        ],
      ),
    );
  }

  Widget _buildSearchAndFilter(bool isDark) {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 24),
      child: Container(
        height: 50,
        decoration: BoxDecoration(
          color: (isDark ? Colors.white : Colors.black).withOpacity(0.04),
          borderRadius: BorderRadius.circular(15),
        ),
        child: TextField(
          controller: _searchController,
          onChanged: (val) => setState(() => _searchQuery = val),
          style: GoogleFonts.montserrat(color: Theme.of(context).colorScheme.onSurface, fontSize: 13),
          decoration: InputDecoration(
            hintText: 'SEARCH RECORDS...',
            hintStyle: GoogleFonts.montserrat(
              color: Theme.of(context).colorScheme.onSurface.withOpacity(0.3),
              fontSize: 10,
              fontWeight: FontWeight.w700,
              letterSpacing: 1,
            ),
            prefixIcon: Icon(LucideIcons.search, size: 16, color: Theme.of(context).colorScheme.onSurface.withOpacity(0.3)),
            border: InputBorder.none,
            contentPadding: const EdgeInsets.symmetric(vertical: 14),
          ),
        ),
      ),
    );
  }

  Widget _buildLogsList(SupportState state, bool isDark) {
    final filteredLogs = state.logs.where((log) {
      return log.title.toLowerCase().contains(_searchQuery.toLowerCase()) ||
          log.description.toLowerCase().contains(_searchQuery.toLowerCase());
    }).toList();

    if (state.isLoading && state.logs.isEmpty) {
      return const Center(child: CircularProgressIndicator());
    }

    if (filteredLogs.isEmpty) {
      return _buildEmptyState('NO LOGS FOUND');
    }

    return ListView.builder(
      padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 20),
      itemCount: filteredLogs.length,
      itemBuilder: (context, index) => _LogCard(log: filteredLogs[index]),
    );
  }

  Widget _buildDocumentsList(SupportState state, bool isDark) {
    final filteredDocs = state.documents.where((doc) {
      final name = doc['name']?.toString().toLowerCase() ?? '';
      return name.contains(_searchQuery.toLowerCase());
    }).toList();

    if (state.isLoading && state.documents.isEmpty) {
      return const Center(child: CircularProgressIndicator());
    }

    if (filteredDocs.isEmpty) {
      return _buildEmptyState('NO DOCUMENTS FOUND');
    }

    return ListView.builder(
      padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 20),
      itemCount: filteredDocs.length,
      itemBuilder: (context, index) => _DocumentCard(doc: filteredDocs[index]),
    );
  }

  Widget _buildEmptyState(String msg) {
    return Center(
      child: Text(
        msg,
        style: GoogleFonts.montserrat(
          color: Theme.of(context).colorScheme.onSurface.withOpacity(0.2),
          fontSize: 10,
          fontWeight: FontWeight.w900,
          letterSpacing: 2,
        ),
      ),
    );
  }
}

class _LogCard extends StatelessWidget {
  final ActivityLog log;
  const _LogCard({required this.log});

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    return Container(
      margin: const EdgeInsets.only(bottom: 16),
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: (isDark ? Colors.white : Colors.black).withOpacity(0.04),
        borderRadius: BorderRadius.circular(20),
        border: Border.all(color: (isDark ? Colors.white : Colors.black).withOpacity(0.04)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Text(
                log.displayId,
                style: GoogleFonts.montserrat(
                  color: Colors.blueAccent,
                  fontSize: 10,
                  fontWeight: FontWeight.w900,
                ),
              ),
              _buildStatusChip(log.status),
            ],
          ),
          const SizedBox(height: 12),
          Text(
            log.title.toUpperCase(),
            style: GoogleFonts.montserrat(
              color: Theme.of(context).colorScheme.onSurface,
              fontWeight: FontWeight.w800,
              fontSize: 13,
            ),
          ),
          const SizedBox(height: 4),
          Text(
            log.description,
            style: GoogleFonts.montserrat(
              color: Theme.of(context).colorScheme.onSurface.withOpacity(0.4),
              fontSize: 10,
            ),
            maxLines: 2,
            overflow: TextOverflow.ellipsis,
          ),
        ],
      ),
    );
  }

  Widget _buildStatusChip(String status) {
    final bool isPositive = ['completed', 'verified', 'success', 'active'].contains(status.toLowerCase());
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
      decoration: BoxDecoration(
        color: (isPositive ? Colors.green : Colors.orange).withOpacity(0.1),
        borderRadius: BorderRadius.circular(8),
      ),
      child: Text(
        status.toUpperCase(),
        style: GoogleFonts.montserrat(
          color: isPositive ? Colors.green : Colors.orange,
          fontSize: 8,
          fontWeight: FontWeight.w900,
        ),
      ),
    );
  }
}

class _DocumentCard extends ConsumerWidget {
  final dynamic doc;
  const _DocumentCard({required this.doc});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final String name = doc['name'] ?? 'Document';
    final String type = doc['type'] ?? 'PDF';
    final String? url = doc['url'];

    return Container(
      margin: const EdgeInsets.only(bottom: 16),
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: (isDark ? Colors.white : Colors.black).withOpacity(0.04),
        borderRadius: BorderRadius.circular(20),
        border: Border.all(color: (isDark ? Colors.white : Colors.black).withOpacity(0.04)),
      ),
      child: Row(
        children: [
          Container(
            padding: const EdgeInsets.all(12),
            decoration: BoxDecoration(
              color: Colors.blueAccent.withOpacity(0.1),
              shape: BoxShape.circle,
            ),
            child: const Icon(LucideIcons.fileText, color: Colors.blueAccent, size: 20),
          ),
          const SizedBox(width: 20),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  name.toUpperCase(),
                  style: GoogleFonts.montserrat(
                    color: Theme.of(context).colorScheme.onSurface,
                    fontWeight: FontWeight.w800,
                    fontSize: 13,
                  ),
                ),
                Text(
                  type.toUpperCase(),
                  style: GoogleFonts.montserrat(
                    color: Theme.of(context).colorScheme.onSurface.withOpacity(0.4),
                    fontSize: 9,
                    fontWeight: FontWeight.w700,
                  ),
                ),
              ],
            ),
          ),
          IconButton(
            icon: Icon(LucideIcons.download, color: Theme.of(context).colorScheme.onSurface.withOpacity(0.3), size: 20),
            onPressed: () {
               if (url != null) {
                 // Launch URL logic
               }
            },
          ),
        ],
      ),
    );
  }
}
