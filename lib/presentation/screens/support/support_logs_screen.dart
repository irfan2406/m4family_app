import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:lucide_icons/lucide_icons.dart';
import 'package:m4_mobile/core/models/activity_log.dart';
import 'package:m4_mobile/presentation/providers/support_provider.dart';
import 'package:flutter_animate/flutter_animate.dart';
import 'package:intl/intl.dart';
import 'dart:ui';

class SupportLogsScreen extends ConsumerStatefulWidget {
  const SupportLogsScreen({super.key});

  @override
  ConsumerState<SupportLogsScreen> createState() => _SupportLogsScreenState();
}

class _SupportLogsScreenState extends ConsumerState<SupportLogsScreen> {
  final TextEditingController _searchController = TextEditingController();
  String _searchQuery = "";
  String? _selectedType;

  @override
  void initState() {
    super.initState();
    Future.microtask(() => ref.read(supportProvider.notifier).fetchLogs());
  }

  @override
  Widget build(BuildContext context) {
    final state = ref.watch(supportProvider);
    
    final filteredLogs = state.logs.where((log) {
      final matchesSearch = log.title.toLowerCase().contains(_searchQuery.toLowerCase()) ||
          log.displayId.toLowerCase().contains(_searchQuery.toLowerCase()) ||
          log.description.toLowerCase().contains(_searchQuery.toLowerCase());
      final matchesType = _selectedType == null || log.type == _selectedType;
      return matchesSearch && matchesType;
    }).toList();

    final logTypes = state.logs.map((l) => l.type).toSet().toList();

    return Scaffold(
      backgroundColor: Colors.black,
      body: Container(
        decoration: const BoxDecoration(
          gradient: LinearGradient(
            begin: Alignment.topLeft,
            end: Alignment.bottomRight,
            colors: [Color(0xFF0F1115), Color(0xFF050505)],
          ),
        ),
        child: SafeArea(
          child: Column(
            children: [
              _buildHeader(context),
              _buildSearchAndFilter(logTypes),
              if (_selectedType != null) _buildActiveFilter(),
              Expanded(
                child: state.isLoading && state.logs.isEmpty
                    ? const Center(child: CircularProgressIndicator(color: Colors.white))
                    : filteredLogs.isEmpty
                        ? _buildEmptyState()
                        : ListView.builder(
                            padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 20),
                            itemCount: filteredLogs.length,
                            itemBuilder: (context, index) {
                              return _LogCard(log: filteredLogs[index]);
                            },
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
            icon: const Icon(LucideIcons.chevronLeft, color: Colors.white70),
          ),
          const SizedBox(width: 8),
          Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                'OPERATIONAL LOGS',
                style: GoogleFonts.montserrat(
                  fontSize: 18,
                  fontWeight: FontWeight.w700,
                  color: Colors.white,
                  letterSpacing: 1,
                ),
              ),
              Text(
                'FULL AUDIT HISTORY',
                style: GoogleFonts.montserrat(
                  fontSize: 9,
                  fontWeight: FontWeight.w900,
                  color: Colors.white54,
                  letterSpacing: 3,
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildSearchAndFilter(List<String> types) {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 24),
      child: Row(
        children: [
          Expanded(
            child: Container(
              height: 48,
              decoration: BoxDecoration(
                color: Colors.white.withOpacity(0.05),
                borderRadius: BorderRadius.circular(12),
                border: Border.all(color: Colors.white.withOpacity(0.1)),
              ),
              child: TextField(
                controller: _searchController,
                onChanged: (val) => setState(() => _searchQuery = val),
                style: GoogleFonts.montserrat(color: Colors.white, fontSize: 13),
                decoration: InputDecoration(
                  hintText: 'SEARCH LOGS...',
                  hintStyle: GoogleFonts.montserrat(
                    color: Colors.white24,
                    fontSize: 10,
                    fontWeight: FontWeight.w700,
                    letterSpacing: 1,
                  ),
                  prefixIcon: const Icon(LucideIcons.search, size: 16, color: Colors.white24),
                  border: InputBorder.none,
                  contentPadding: const EdgeInsets.symmetric(vertical: 12),
                ),
              ),
            ),
          ),
          const SizedBox(width: 12),
          GestureDetector(
            onTap: () => _showFilterSheet(types),
            child: Container(
              height: 48,
              width: 48,
              decoration: BoxDecoration(
                color: _selectedType != null ? Colors.white : Colors.white.withOpacity(0.05),
                borderRadius: BorderRadius.circular(12),
                border: Border.all(color: Colors.white.withOpacity(0.1)),
              ),
              child: Icon(
                LucideIcons.filter,
                size: 18,
                color: _selectedType != null ? Colors.black : Colors.white70,
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildActiveFilter() {
    return Padding(
      padding: const EdgeInsets.only(left: 24, top: 12, right: 24),
      child: Row(
        children: [
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
            decoration: BoxDecoration(
              color: Colors.white.withOpacity(0.1),
              borderRadius: BorderRadius.circular(20),
            ),
            child: Row(
              mainAxisSize: MainAxisSize.min,
              children: [
                Text(
                  'TYPE: $_selectedType',
                  style: GoogleFonts.montserrat(
                    color: Colors.white70,
                    fontSize: 8,
                    fontWeight: FontWeight.w900,
                  ),
                ),
                const SizedBox(width: 8),
                GestureDetector(
                  onTap: () => setState(() => _selectedType = null),
                  child: const Icon(LucideIcons.x, size: 12, color: Colors.white70),
                ),
              ],
            ),
          ),
          const Spacer(),
          TextButton(
            onPressed: () => setState(() => _selectedType = null),
            child: Text(
              'CLEAR ALL',
              style: GoogleFonts.montserrat(
                color: Colors.white38,
                fontSize: 8,
                fontWeight: FontWeight.bold,
              ),
            ),
          ),
        ],
      ),
    );
  }

  void _showFilterSheet(List<String> types) {
    showModalBottomSheet(
      context: context,
      backgroundColor: Colors.transparent,
      builder: (context) => Container(
        padding: const EdgeInsets.all(32),
        decoration: const BoxDecoration(
          color: Color(0xFF0D0D0D),
          borderRadius: BorderRadius.vertical(top: Radius.circular(40)),
          border: Border(top: BorderSide(color: Colors.white10)),
        ),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Center(
              child: Container(
                width: 40,
                height: 4,
                decoration: BoxDecoration(
                  color: Colors.white10,
                  borderRadius: BorderRadius.circular(2),
                ),
              ),
            ),
            const SizedBox(height: 32),
            Text(
              'FILTER LOGS',
              style: GoogleFonts.montserrat(
                fontSize: 20,
                fontWeight: FontWeight.w700,
                color: Colors.white,
              ),
            ),
            const SizedBox(height: 24),
            Text(
              'LOG CATEGORY',
              style: GoogleFonts.montserrat(
                fontSize: 10,
                fontWeight: FontWeight.w900,
                color: Colors.white38,
                letterSpacing: 2,
              ),
            ),
            const SizedBox(height: 16),
            Wrap(
              spacing: 12,
              runSpacing: 12,
              children: types.map((type) => GestureDetector(
                onTap: () {
                  setState(() => _selectedType = type);
                  Navigator.pop(context);
                },
                child: Container(
                  padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 12),
                  decoration: BoxDecoration(
                    color: _selectedType == type ? Colors.white : Colors.white.withOpacity(0.05),
                    borderRadius: BorderRadius.circular(16),
                    border: Border.all(color: Colors.white.withOpacity(0.1)),
                  ),
                  child: Text(
                    type.toUpperCase(),
                    style: GoogleFonts.montserrat(
                      color: _selectedType == type ? Colors.black : Colors.white70,
                      fontSize: 10,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                ),
              )).toList(),
            ),
            const SizedBox(height: 32),
          ],
        ),
      ),
    );
  }

  Widget _buildEmptyState() {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Icon(LucideIcons.search, size: 48, color: Colors.white.withOpacity(0.05)),
          const SizedBox(height: 16),
          Text(
            'NO LOGS FOUND',
            style: GoogleFonts.montserrat(
              color: Colors.white24,
              fontSize: 12,
              fontWeight: FontWeight.w900,
              letterSpacing: 2,
            ),
          ),
        ],
      ),
    );
  }
}

class _LogCard extends StatelessWidget {
  final ActivityLog log;

  const _LogCard({required this.log});

  @override
  Widget build(BuildContext context) {
    final dateFormat = DateFormat('MMM d, h:mm a');
    final timeAgo = _getTimeAgo(log.createdAt);

    return GestureDetector(
      onTap: () => _showLogDetails(context),
      child: Container(
        margin: const EdgeInsets.only(bottom: 16),
        padding: const EdgeInsets.all(20),
        decoration: BoxDecoration(
          color: Colors.white.withOpacity(0.03),
          borderRadius: BorderRadius.circular(24),
          border: Border.all(color: Colors.white.withOpacity(0.08)),
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Row(
                  children: [
                    _buildBadge(log.displayId, Colors.blueAccent.withOpacity(0.1), Colors.blueAccent),
                    const SizedBox(width: 8),
                    _buildBadge(log.type.toUpperCase(), Colors.white.withOpacity(0.05), Colors.white54),
                  ],
                ),
                _buildStatusChip(log.status),
              ],
            ),
            const SizedBox(height: 16),
            Text(
              log.title.toUpperCase(),
              style: GoogleFonts.montserrat(
                color: Colors.white,
                fontWeight: FontWeight.w700,
                fontSize: 14,
                letterSpacing: 0.5,
              ),
            ),
            const SizedBox(height: 4),
            Text(
              log.description,
              maxLines: 1,
              overflow: TextOverflow.ellipsis,
              style: GoogleFonts.montserrat(
                color: Colors.white38,
                fontSize: 10,
                fontWeight: FontWeight.w600,
              ),
            ),
            const SizedBox(height: 20),
            const Divider(color: Colors.white10),
            const SizedBox(height: 12),
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Row(
                  children: [
                    const Icon(LucideIcons.clock, size: 12, color: Colors.white24),
                    const SizedBox(width: 6),
                    Text(
                      timeAgo.toUpperCase(),
                      style: GoogleFonts.montserrat(
                        color: Colors.white24,
                        fontSize: 9,
                        fontWeight: FontWeight.w900,
                      ),
                    ),
                  ],
                ),
                Row(
                  children: [
                    Text(
                      'VIEW DETAILS',
                      style: GoogleFonts.montserrat(
                        color: Colors.white38,
                        fontSize: 8,
                        fontWeight: FontWeight.w900,
                      ),
                    ),
                    const SizedBox(width: 4),
                    const Icon(LucideIcons.chevronRight, size: 12, color: Colors.white24),
                  ],
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildBadge(String text, Color bgColor, Color textColor) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
      decoration: BoxDecoration(
        color: bgColor,
        borderRadius: BorderRadius.circular(6),
        border: Border.all(color: textColor.withOpacity(0.2)),
      ),
      child: Text(
        text,
        style: GoogleFonts.montserrat(
          color: textColor,
          fontSize: 8,
          fontWeight: FontWeight.w900,
        ),
      ),
    );
  }

  Widget _buildStatusChip(String status) {
    final bool isPositive = ['completed', 'verified', 'success', 'sent'].contains(status.toLowerCase());
    final bool isNeutral = ['open', 'active', 'pending'].contains(status.toLowerCase());
    
    final color = isPositive ? Colors.greenAccent : (isNeutral ? Colors.blueAccent : Colors.orangeAccent);

    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
      decoration: BoxDecoration(
        color: color.withOpacity(0.1),
        borderRadius: BorderRadius.circular(10),
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

  String _getTimeAgo(DateTime dateTime) {
    final duration = DateTime.now().difference(dateTime);
    if (duration.inMinutes < 60) return '${duration.inMinutes} mins ago';
    if (duration.inHours < 24) return '${duration.inHours} hours ago';
    return DateFormat('MMM d').format(dateTime);
  }

  void _showLogDetails(BuildContext context) {
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (context) => DraggableScrollableSheet(
        initialChildSize: 0.7,
        maxChildSize: 0.9,
        builder: (_, scrollController) => Container(
          decoration: const BoxDecoration(
            color: Color(0xFF0D0D0D),
            borderRadius: BorderRadius.vertical(top: Radius.circular(40)),
          ),
          child: Column(
            children: [
              const SizedBox(height: 12),
              Container(width: 40, height: 4, decoration: BoxDecoration(color: Colors.white10, borderRadius: BorderRadius.circular(2))),
              Expanded(
                child: ListView(
                  controller: scrollController,
                  padding: const EdgeInsets.all(32),
                  children: [
                    _buildBadge(log.displayId + ' • ' + log.type.toUpperCase(), Colors.white.withOpacity(0.05), Colors.white54),
                    const SizedBox(height: 16),
                    Text(log.title.toUpperCase(), style: GoogleFonts.montserrat(fontSize: 24, fontWeight: FontWeight.bold, color: Colors.white, height: 1.2)),
                    const SizedBox(height: 32),
                    Row(
                      children: [
                        Expanded(child: _buildInfoBox('STATUS', log.status.toUpperCase(), Colors.greenAccent)),
                        const SizedBox(width: 16),
                        Expanded(child: _buildInfoBox('ACTOR', log.actor.toUpperCase(), Colors.white)),
                      ],
                    ),
                    const SizedBox(height: 32),
                    _buildSectionHeader(LucideIcons.info, 'LOG SUMMARY'),
                    const SizedBox(height: 12),
                    Container(
                      padding: const EdgeInsets.all(24),
                      decoration: BoxDecoration(color: Colors.white.withOpacity(0.02), borderRadius: BorderRadius.circular(24), border: Border.all(color: Colors.white10)),
                      child: Text(log.description.toUpperCase(), style: GoogleFonts.montserrat(color: Colors.white70, fontSize: 11, fontWeight: FontWeight.bold, height: 1.5)),
                    ),
                    const SizedBox(height: 32),
                    _buildSectionHeader(LucideIcons.history, 'STRUCTURAL DATA'),
                    const SizedBox(height: 12),
                    ...log.details.entries.map((e) => _buildDetailRow(e.key, e.value.toString())).toList(),
                    const SizedBox(height: 48),
                    ElevatedButton(
                      onPressed: () => Navigator.pop(context),
                      style: ElevatedButton.styleFrom(
                        backgroundColor: Colors.white,
                        foregroundColor: Colors.black,
                        minimumSize: const Size(double.infinity, 64),
                        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
                      ),
                      child: Text('BACK TO OPERATIONAL LOGS', style: GoogleFonts.montserrat(fontWeight: FontWeight.w900, fontSize: 11, letterSpacing: 1)),
                    ),
                  ],
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildInfoBox(String label, String value, Color valueColor) {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(color: Colors.white.withOpacity(0.03), borderRadius: BorderRadius.circular(20), border: Border.all(color: Colors.white.withOpacity(0.05))),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(label, style: GoogleFonts.montserrat(color: Colors.white24, fontSize: 8, fontWeight: FontWeight.w900, letterSpacing: 1)),
          const SizedBox(height: 4),
          Text(value, style: GoogleFonts.montserrat(color: valueColor, fontSize: 11, fontWeight: FontWeight.bold)),
        ],
      ),
    );
  }

  Widget _buildSectionHeader(IconData icon, String title) {
    return Row(
      children: [
        Icon(icon, size: 14, color: Colors.white24),
        const SizedBox(width: 8),
        Text(title, style: GoogleFonts.montserrat(color: Colors.white24, fontSize: 9, fontWeight: FontWeight.w900, letterSpacing: 2)),
      ],
    );
  }

  Widget _buildDetailRow(String key, String value) {
    return Container(
      padding: const EdgeInsets.symmetric(vertical: 16),
      decoration: const BoxDecoration(
        border: Border(bottom: BorderSide(color: Colors.white10)),
      ),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Text(key.replaceAll(RegExp(r'(?=[A-Z])'), ' ').toUpperCase(), style: GoogleFonts.montserrat(color: Colors.white38, fontSize: 9, fontWeight: FontWeight.bold)),
          Text(value.toUpperCase(), style: GoogleFonts.montserrat(color: Colors.white, fontSize: 10, fontWeight: FontWeight.bold)),
        ],
      ),
    );
  }
}
