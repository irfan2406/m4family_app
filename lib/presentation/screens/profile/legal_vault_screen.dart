import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:lucide_icons/lucide_icons.dart';
import 'package:flutter_animate/flutter_animate.dart';
import 'package:intl/intl.dart';
import 'package:m4_mobile/core/providers/theme_provider.dart';
import 'package:m4_mobile/core/network/api_client.dart';
import 'package:m4_mobile/presentation/providers/auth_provider.dart';
import 'package:url_launcher/url_launcher.dart';

class LegalVaultScreen extends ConsumerStatefulWidget {
  const LegalVaultScreen({super.key});

  @override
  ConsumerState<LegalVaultScreen> createState() => _LegalVaultScreenState();
}

class _LegalVaultScreenState extends ConsumerState<LegalVaultScreen> {
  bool _isLoading = true;
  List<dynamic> _documents = [];
  String _selectedFilter = "ALL";

  @override
  void initState() {
    super.initState();
    _fetchDocuments();
  }

  Future<void> _fetchDocuments() async {
    try {
      final res = await ref.read(apiClientProvider).getMySupportDocuments();
      if (res.data['status'] == true) {
        setState(() => _documents = res.data['data'] ?? []);
      }
    } catch (e) {
      debugPrint('Error fetching documents: $e');
    } finally {
      if (mounted) setState(() => _isLoading = false);
    }
  }

  List<dynamic> get _filteredDocs {
    if (_selectedFilter == "ALL") return _documents;
    return _documents.where((doc) {
      final name = doc['name'].toString().toLowerCase();
      if (_selectedFilter == "AGREEMENTS") return name.contains("agreement");
      if (_selectedFilter == "PAYMENTS") return name.contains("payment") || name.contains("receipt");
      if (_selectedFilter == "PORTFOLIO") return name.contains("portfolio") || name.contains("overview");
      return true;
    }).toList();
  }

  @override
  Widget build(BuildContext context) {
    final isDark = ref.watch(themeProvider) == ThemeMode.dark;
    
    return Scaffold(
      backgroundColor: isDark ? const Color(0xFF09090B) : const Color(0xFFF8FAFC),
      body: SafeArea(
        child: Column(
          children: [
            _buildHeader(isDark),
            Expanded(
              child: _isLoading 
                ? const Center(child: CircularProgressIndicator())
                : Column(
                    children: [
                      _buildSecurityHeader(isDark),
                      _buildFilterTabs(isDark),
                      Expanded(
                        child: RefreshIndicator(
                          onRefresh: _fetchDocuments,
                          child: ListView.builder(
                            physics: const BouncingScrollPhysics(),
                            padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 12),
                            itemCount: _filteredDocs.isEmpty ? 1 : _filteredDocs.length,
                            itemBuilder: (context, index) {
                              if (_filteredDocs.isEmpty) return _buildEmptyState(isDark);
                              return _buildDocumentCard(_filteredDocs[index], isDark);
                            },
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
  }

  Widget _buildHeader(bool isDark) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 16),
      child: Row(
        children: [
          _IconButton(
            icon: LucideIcons.chevronLeft,
            isDark: isDark,
            onTap: () => Navigator.pop(context),
          ),
          Expanded(
            child: Center(
              child: Text(
                'LEGAL VAULT',
                style: GoogleFonts.montserrat(
                  fontSize: 16,
                  fontWeight: FontWeight.w800,
                  color: isDark ? Colors.white : Colors.black,
                  letterSpacing: 2,
                ),
              ),
            ),
          ),
          Container(
            padding: const EdgeInsets.all(10),
            decoration: BoxDecoration(
              color: isDark ? Colors.white.withOpacity(0.04) : Colors.black.withOpacity(0.04),
              shape: BoxShape.circle,
            ),
            child: Icon(LucideIcons.shield, color: isDark ? Colors.white54 : Colors.black54, size: 20),
          ),
        ],
      ),
    );
  }

  Widget _buildSecurityHeader(bool isDark) {
    return Container(
      margin: const EdgeInsets.all(24),
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: isDark ? const Color(0xFF18181B) : Colors.white,
        borderRadius: BorderRadius.circular(24),
        border: Border.all(color: (isDark ? Colors.white : Colors.black).withOpacity(0.05)),
        boxShadow: isDark ? [] : [BoxShadow(color: Colors.black.withOpacity(0.05), blurRadius: 20, offset: const Offset(0, 10))],
      ),
      child: Row(
        children: [
          Container(
            width: 44,
            height: 44,
            decoration: BoxDecoration(
              color: (isDark ? Colors.white : Colors.black).withOpacity(0.05),
              borderRadius: BorderRadius.circular(14),
            ),
            child: Icon(LucideIcons.lock, color: isDark ? Colors.white54 : Colors.black54, size: 20),
          ),
          const SizedBox(width: 16),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  'ENCRYPTED STORAGE',
                  style: GoogleFonts.montserrat(
                    fontSize: 8,
                    fontWeight: FontWeight.w800,
                    color: isDark ? Colors.white38 : Colors.black38,
                    letterSpacing: 1.5,
                  ),
                ),
                Text(
                  'SECURE DOCUMENT REPOSITORY',
                  style: GoogleFonts.montserrat(
                    fontSize: 10,
                    fontWeight: FontWeight.w800,
                    color: isDark ? Colors.white : Colors.black,
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    ).animate().fadeIn().slideY(begin: 0.1);
  }

  Widget _buildFilterTabs(bool isDark) {
    final filters = ["ALL", "AGREEMENTS", "PAYMENTS", "PORTFOLIO"];
    return SingleChildScrollView(
      scrollDirection: Axis.horizontal,
      padding: const EdgeInsets.symmetric(horizontal: 24),
      child: Row(
        children: filters.map((f) => Padding(
          padding: const EdgeInsets.only(right: 12),
          child: ChoiceChip(
            label: Text(f),
            selected: _selectedFilter == f,
            onSelected: (selected) {
              if (selected) setState(() => _selectedFilter = f);
            },
            labelStyle: GoogleFonts.montserrat(
              fontSize: 9,
              fontWeight: FontWeight.w800,
              color: _selectedFilter == f ? (isDark ? Colors.black : Colors.white) : (isDark ? Colors.white54 : Colors.black54),
            ),
            selectedColor: isDark ? Colors.white : Colors.black,
            backgroundColor: isDark ? const Color(0xFF18181B) : Colors.white,
            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
            shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
          ),
        )).toList(),
      ),
    );
  }

  Widget _buildDocumentCard(dynamic doc, bool isDark) {
    final project = doc['project'] ?? {};
    final date = _formatDate(doc['createdAt']);

    return Container(
      margin: const EdgeInsets.only(bottom: 12),
      decoration: BoxDecoration(
        color: isDark ? const Color(0xFF18181B) : Colors.white,
        borderRadius: BorderRadius.circular(24),
        border: Border.all(color: (isDark ? Colors.white : Colors.black).withOpacity(0.05)),
        boxShadow: isDark ? [] : [BoxShadow(color: Colors.black.withOpacity(0.05), blurRadius: 10, offset: const Offset(0, 4))],
      ),
      child: ListTile(
        contentPadding: const EdgeInsets.symmetric(horizontal: 20, vertical: 12),
        leading: Container(
          width: 44,
          height: 44,
          decoration: BoxDecoration(
            color: (isDark ? Colors.white : Colors.black).withOpacity(0.05),
            borderRadius: BorderRadius.circular(12),
          ),
          child: Icon(LucideIcons.fileText, color: isDark ? Colors.white54 : Colors.black54, size: 20),
        ),
        title: Text(
          (doc['name'] ?? 'DOCUMENT').toUpperCase(),
          style: GoogleFonts.montserrat(fontSize: 12, fontWeight: FontWeight.w800, color: isDark ? Colors.white : Colors.black),
          overflow: TextOverflow.ellipsis,
        ),
        subtitle: Row(
          children: [
            Text((project['title'] ?? 'GENERAL').toUpperCase(), style: GoogleFonts.montserrat(fontSize: 8, fontWeight: FontWeight.w700, color: isDark ? Colors.white38 : Colors.black38)),
            const SizedBox(width: 8),
            Container(width: 3, height: 3, decoration: BoxDecoration(color: (isDark ? Colors.white : Colors.black).withOpacity(0.2), shape: BoxShape.circle)),
            const SizedBox(width: 8),
            Text(date, style: GoogleFonts.montserrat(fontSize: 8, fontWeight: FontWeight.w700, color: isDark ? Colors.white38 : Colors.black38)),
          ],
        ),
        trailing: Icon(LucideIcons.chevronRight, size: 16, color: (isDark ? Colors.white : Colors.black).withOpacity(0.2)),
        onTap: () => _showDocumentDetails(doc, isDark),
      ),
    ).animate().fadeIn().slideX(begin: 0.1);
  }

  void _showDocumentDetails(dynamic doc, bool isDark) {
    showModalBottomSheet(
      context: context,
      backgroundColor: Colors.transparent,
      isScrollControlled: true,
      builder: (context) => _DocumentDetailSheet(doc: doc, isDark: isDark),
    );
  }

  String _formatDate(String dateStr) {
    try {
      final date = DateTime.parse(dateStr);
      return DateFormat('d MMM yyyy').format(date).toUpperCase();
    } catch (e) {
      return dateStr.toUpperCase();
    }
  }

  Widget _buildEmptyState(bool isDark) {
    return Column(
      children: [
        const SizedBox(height: 60),
        Icon(LucideIcons.fileWarning, size: 64, color: (isDark ? Colors.white : Colors.black).withOpacity(0.1)),
        const SizedBox(height: 24),
        Text(
          'NO DOCUMENTS FOUND',
          style: GoogleFonts.montserrat(
            fontSize: 10,
            fontWeight: FontWeight.w800,
            color: (isDark ? Colors.white : Colors.black).withOpacity(0.2),
            letterSpacing: 2,
          ),
        ),
      ],
    );
  }
}

class _DocumentDetailSheet extends StatelessWidget {
  final dynamic doc;
  final bool isDark;
  const _DocumentDetailSheet({required this.doc, required this.isDark});

  @override
  Widget build(BuildContext context) {
    return Container(
      decoration: BoxDecoration(
        color: isDark ? const Color(0xFF18181B) : Colors.white,
        borderRadius: const BorderRadius.vertical(top: Radius.circular(40)),
      ),
      padding: const EdgeInsets.all(32),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          Container(
            width: 80,
            height: 80,
            decoration: BoxDecoration(
              color: (isDark ? Colors.white : Colors.black).withOpacity(0.05),
              borderRadius: BorderRadius.circular(24),
              border: Border.all(color: (isDark ? Colors.white : Colors.black).withOpacity(0.05)),
            ),
            child: Icon(LucideIcons.fileText, color: isDark ? Colors.white54 : Colors.black54, size: 40),
          ),
          const SizedBox(height: 24),
          Text(
            (doc['name'] ?? 'DOCUMENT').toUpperCase(),
            textAlign: TextAlign.center,
            style: GoogleFonts.montserrat(fontSize: 18, fontWeight: FontWeight.w800, color: isDark ? Colors.white : Colors.black),
          ),
          const SizedBox(height: 8),
          Text(
            'SECURE DOCUMENT ACCESS',
            style: GoogleFonts.montserrat(fontSize: 9, fontWeight: FontWeight.w800, color: isDark ? Colors.white38 : Colors.black38, letterSpacing: 2),
          ),
          const SizedBox(height: 32),
          _DetailRow(label: 'ADDED ON', value: DateFormat('d MMM yyyy').format(DateTime.parse(doc['createdAt'])).toUpperCase(), isDark: isDark, icon: LucideIcons.calendar),
          const SizedBox(height: 12),
          _DetailRow(label: 'PROJECT', value: (doc['project']?['title'] ?? 'GENERAL').toUpperCase(), isDark: isDark, icon: LucideIcons.tag),
          const SizedBox(height: 12),
          _DetailRow(label: 'SECURITY', value: 'VERIFIED', isDark: isDark, icon: LucideIcons.shieldCheck, color: const Color(0xFF22C55E)),
          const SizedBox(height: 40),
          Row(
            children: [
              Expanded(
                child: _ActionButton(label: 'SHARE', icon: LucideIcons.share2, isDark: isDark, onTap: () {}),
              ),
              const SizedBox(width: 16),
              Expanded(
                child: _ActionButton(
                  label: 'VIEW DOC', 
                  icon: LucideIcons.eye, 
                  isDark: isDark, 
                  isPrimary: true,
                  onTap: () async {
                    final url = doc['fileUrl'] ?? doc['url'];
                    if (url != null) await launchUrl(Uri.parse(url));
                  },
                ),
              ),
            ],
          ),
          const SizedBox(height: 20),
        ],
      ),
    );
  }
}

class _DetailRow extends StatelessWidget {
  final String label;
  final String value;
  final bool isDark;
  final IconData icon;
  final Color? color;
  const _DetailRow({required this.label, required this.value, required this.isDark, required this.icon, this.color});

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 16),
      decoration: BoxDecoration(
        color: (isDark ? Colors.white : Colors.black).withOpacity(0.02),
        borderRadius: BorderRadius.circular(20),
        border: Border.all(color: (isDark ? Colors.white : Colors.black).withOpacity(0.04)),
      ),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Row(
            children: [
              Icon(icon, size: 16, color: color ?? (isDark ? Colors.white24 : Colors.black26)),
              const SizedBox(width: 12),
              Text(label, style: GoogleFonts.montserrat(fontSize: 9, fontWeight: FontWeight.w800, color: isDark ? Colors.white38 : Colors.black38, letterSpacing: 1)),
            ],
          ),
          Text(value, style: GoogleFonts.montserrat(fontSize: 10, fontWeight: FontWeight.w800, color: color ?? (isDark ? Colors.white : Colors.black))),
        ],
      ),
    );
  }
}

class _ActionButton extends StatelessWidget {
  final String label;
  final IconData icon;
  final bool isDark;
  final bool isPrimary;
  final VoidCallback onTap;
  const _ActionButton({required this.label, required this.icon, required this.isDark, this.isPrimary = false, required this.onTap});

  @override
  Widget build(BuildContext context) {
    return SizedBox(
      height: 60,
      child: ElevatedButton.icon(
        onPressed: onTap,
        icon: Icon(icon, size: 18),
        label: Text(label, style: GoogleFonts.montserrat(fontSize: 10, fontWeight: FontWeight.w900, letterSpacing: 1.5)),
        style: ElevatedButton.styleFrom(
          backgroundColor: isPrimary ? (isDark ? Colors.white : Colors.black) : (isDark ? const Color(0xFF18181B) : Colors.white),
          foregroundColor: isPrimary ? (isDark ? Colors.black : Colors.white) : (isDark ? Colors.white54 : Colors.black54),
          elevation: isPrimary ? 8 : 0,
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(24),
            side: isPrimary ? BorderSide.none : BorderSide(color: (isDark ? Colors.white : Colors.black).withOpacity(0.05)),
          ),
        ),
      ),
    );
  }
}

class _IconButton extends StatelessWidget {
  final IconData icon;
  final bool isDark;
  final VoidCallback onTap;
  const _IconButton({required this.icon, required this.isDark, required this.onTap});

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        padding: const EdgeInsets.all(12),
        decoration: BoxDecoration(
          color: isDark ? const Color(0xFF18181B) : Colors.white,
          borderRadius: BorderRadius.circular(14),
          border: Border.all(color: (isDark ? Colors.white : Colors.black).withOpacity(0.05)),
        ),
        child: Icon(icon, color: isDark ? Colors.white54 : Colors.black54, size: 20),
      ),
    );
  }
}
