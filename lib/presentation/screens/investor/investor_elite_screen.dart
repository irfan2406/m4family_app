import 'dart:ui';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:lucide_icons/lucide_icons.dart';
import 'package:url_launcher/url_launcher.dart';
import 'package:m4_mobile/core/theme/app_theme.dart';
import 'package:m4_mobile/presentation/providers/auth_provider.dart';

/// Web `/investor/elite` parity: Elite Status card + Document Repository
/// (secure vault) + security notice. Mirrors [CpEliteScreen] with
/// investor-specific copy. Follows M4 conventions.
class InvestorEliteScreen extends ConsumerStatefulWidget {
  const InvestorEliteScreen({super.key});

  @override
  ConsumerState<InvestorEliteScreen> createState() => _InvestorEliteScreenState();
}

class _InvestorEliteScreenState extends ConsumerState<InvestorEliteScreen> {
  static const _gold = Color(0xFFFFD700);

  bool _loading = true;
  List<Map<String, dynamic>> _documents = [];

  // Web demo data (parity with investor/elite/page.tsx `documents`).
  static const List<Map<String, dynamic>> _demoDocs = [
    {'title': 'Booking Confirmation', 'type': 'PDF', 'size': '1.2 MB', 'date': 'Jan 15, 2026'},
    {'title': 'Payment Receipt #8812', 'type': 'PDF', 'size': '450 KB', 'date': 'Jan 15, 2026'},
    {'title': 'Project Brochure - M4 Elegance', 'type': 'PDF', 'size': '5.8 MB', 'date': 'Jan 10, 2026'},
    {'title': 'Legal Terms & Conditions', 'type': 'DOCX', 'size': '2.1 MB', 'date': 'Jan 05, 2026'},
  ];

  @override
  void initState() {
    super.initState();
    _load();
  }

  Future<void> _load() async {
    setState(() => _loading = true);
    List<Map<String, dynamic>> docs = [];
    try {
      // Investor vault documents (`GET /api/investor/documents`).
      final api = ref.read(apiClientProvider);
      final res = await api.getInvestorDocuments();
      if (res.statusCode == 200 && res.data['status'] == true) {
        final d = res.data['data'];
        if (d is List) {
          docs = d.map<Map<String, dynamic>>((e) {
            final m = e as Map;
            return {
              'title': (m['name'] ?? m['title'] ?? 'Document').toString(),
              'type': _typeFromUrl((m['fileUrl'] ?? m['url'] ?? '').toString()),
              'size': (m['size'] ?? '').toString(),
              'date': (m['createdAt'] ?? m['date'] ?? '').toString(),
              'url': (m['fileUrl'] ?? m['url'] ?? '').toString(),
            };
          }).toList();
        }
      }
    } catch (_) {}
    if (!mounted) return;
    // Fall back to demo data so the elite dashboard always renders.
    setState(() {
      _documents = docs.isNotEmpty ? docs : List<Map<String, dynamic>>.from(_demoDocs);
      _loading = false;
    });
  }

  String _typeFromUrl(String url) {
    final lower = url.toLowerCase();
    if (lower.endsWith('.docx') || lower.endsWith('.doc')) return 'DOCX';
    if (lower.endsWith('.pdf')) return 'PDF';
    return 'FILE';
  }

  Future<void> _openDocument(String url) async {
    if (url.isEmpty) {
      _toast('Preview not available in demo');
      return;
    }
    final api = ref.read(apiClientProvider);
    final resolved = api.resolveUrl(url);
    try {
      await launchUrl(Uri.parse(resolved), mode: LaunchMode.externalApplication);
    } catch (_) {
      _toast('Could not open document');
    }
  }

  Future<void> _downloadDocument(String url) async {
    if (url.isEmpty) {
      _toast('Download not available in demo');
      return;
    }
    final api = ref.read(apiClientProvider);
    final resolved = api.resolveUrl(url);
    try {
      await launchUrl(Uri.parse(resolved), mode: LaunchMode.externalApplication);
    } catch (_) {
      _toast('Could not download document');
    }
  }

  void _toast(String msg) {
    if (!mounted) return;
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(content: Text(msg)),
    );
  }

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final bg = isDark ? Colors.black : Colors.white;
    final textPrimary = isDark ? Colors.white : Colors.black;

    return Scaffold(
      backgroundColor: bg,
      body: SafeArea(
        child: Column(
          children: [
            _buildHeader(textPrimary),
            Expanded(
              child: _loading
                  ? const Center(
                      child: CircularProgressIndicator(color: M4Theme.premiumBlue, strokeWidth: 2),
                    )
                  : RefreshIndicator(
                      onRefresh: _load,
                      color: textPrimary,
                      child: SingleChildScrollView(
                        physics: const AlwaysScrollableScrollPhysics(),
                        padding: const EdgeInsets.symmetric(horizontal: 24),
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            const SizedBox(height: 8),
                            _buildEliteCard(isDark),
                            const SizedBox(height: 28),
                            _buildRepositoryHeader(isDark, textPrimary),
                            const SizedBox(height: 16),
                            _buildDocumentList(isDark, textPrimary),
                            const SizedBox(height: 24),
                            _buildSecurityNotice(isDark, textPrimary),
                            const SizedBox(height: 24),
                            _buildUpgradeButton(isDark, textPrimary),
                            const SizedBox(height: 100),
                          ],
                        ),
                      ),
                    ),
            ),
          ],
        ),
      ),
    );
  }

  // ━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━
  // HEADER
  // ━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━
  Widget _buildHeader(Color textPrimary) {
    return Padding(
      padding: const EdgeInsets.fromLTRB(24, 20, 24, 20),
      child: Row(
        children: [
          GestureDetector(
            onTap: () => context.canPop() ? context.pop() : context.go('/investor/home'),
            child: Container(
              padding: const EdgeInsets.all(10),
              decoration: BoxDecoration(
                color: textPrimary.withValues(alpha: 0.05),
                shape: BoxShape.circle,
                border: Border.all(color: textPrimary.withValues(alpha: 0.1)),
              ),
              child: Icon(LucideIcons.arrowLeft, size: 16, color: textPrimary),
            ),
          ),
          Expanded(
            child: Text(
              'MEMBER DASHBOARD',
              textAlign: TextAlign.center,
              style: GoogleFonts.montserrat(
                fontSize: 16,
                fontWeight: FontWeight.w900,
                color: textPrimary,
                letterSpacing: 1.5,
              ),
            ),
          ),
          const SizedBox(width: 36),
        ],
      ),
    );
  }

  // ━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━
  // ELITE STATUS CARD — dark gradient (parity web from-zinc-800→black)
  // ━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━
  Widget _buildEliteCard(bool isDark) {
    return Container(
      width: double.infinity,
      decoration: BoxDecoration(
        gradient: const LinearGradient(
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
          colors: [Color(0xFF27272A), Color(0xFF18181B), Colors.black],
        ),
        borderRadius: BorderRadius.circular(32),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.4),
            blurRadius: 30,
            offset: const Offset(0, 15),
          ),
        ],
      ),
      child: ClipRRect(
        borderRadius: BorderRadius.circular(32),
        child: Stack(
          children: [
            // Abstract glow shape (bottom-right)
            Positioned(
              right: -40,
              bottom: -40,
              child: Container(
                width: 180,
                height: 180,
                decoration: BoxDecoration(
                  shape: BoxShape.circle,
                  color: _gold.withValues(alpha: 0.12),
                ),
              ),
            ),
            Padding(
              padding: const EdgeInsets.all(24),
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
                            Row(
                              children: [
                                const Icon(LucideIcons.crown, size: 18, color: _gold),
                                const SizedBox(width: 8),
                                Text(
                                  'PLATINUM MEMBER',
                                  style: GoogleFonts.montserrat(
                                    fontSize: 10,
                                    fontWeight: FontWeight.w800,
                                    letterSpacing: 2,
                                    color: Colors.white.withValues(alpha: 0.85),
                                  ),
                                ),
                              ],
                            ),
                            const SizedBox(height: 6),
                            Text(
                              'Active Membership',
                              style: GoogleFonts.montserrat(
                                fontSize: 22,
                                fontWeight: FontWeight.w900,
                                color: Colors.white,
                              ),
                            ),
                          ],
                        ),
                      ),
                      // PRO badge
                      Container(
                        padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
                        decoration: BoxDecoration(
                          color: _gold.withValues(alpha: 0.2),
                          borderRadius: BorderRadius.circular(10),
                          border: Border.all(color: _gold.withValues(alpha: 0.5)),
                        ),
                        child: Text(
                          'PRO',
                          style: GoogleFonts.montserrat(
                            fontSize: 11,
                            fontWeight: FontWeight.w900,
                            letterSpacing: 1,
                            color: _gold,
                          ),
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 28),
                  // Two glass stat cards
                  Row(
                    children: [
                      Expanded(
                        child: _buildGlassStat('Priority Booking', 'Enabled'),
                      ),
                      const SizedBox(width: 12),
                      Expanded(
                        child: _buildGlassStat('Rewards Balance', '8,500 pts'),
                      ),
                    ],
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildGlassStat(String label, String value) {
    return ClipRRect(
      borderRadius: BorderRadius.circular(16),
      child: BackdropFilter(
        filter: ImageFilter.blur(sigmaX: 10, sigmaY: 10),
        child: Container(
          padding: const EdgeInsets.all(14),
          decoration: BoxDecoration(
            color: Colors.white.withValues(alpha: 0.08),
            borderRadius: BorderRadius.circular(16),
            border: Border.all(color: Colors.white.withValues(alpha: 0.12)),
          ),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                label.toUpperCase(),
                style: GoogleFonts.montserrat(
                  fontSize: 8,
                  fontWeight: FontWeight.w800,
                  letterSpacing: 1.5,
                  color: Colors.white.withValues(alpha: 0.7),
                ),
              ),
              const SizedBox(height: 6),
              Text(
                value,
                style: GoogleFonts.montserrat(
                  fontSize: 14,
                  fontWeight: FontWeight.w800,
                  color: Colors.white,
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  // ━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━
  // DOCUMENT REPOSITORY
  // ━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━
  Widget _buildRepositoryHeader(bool isDark, Color textPrimary) {
    return Row(
      mainAxisAlignment: MainAxisAlignment.spaceBetween,
      children: [
        Text(
          'DOCUMENT REPOSITORY',
          style: GoogleFonts.montserrat(
            fontSize: 9,
            fontWeight: FontWeight.w900,
            letterSpacing: 2,
            color: textPrimary.withValues(alpha: 0.5),
          ),
        ),
        Container(
          padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
          decoration: BoxDecoration(
            borderRadius: BorderRadius.circular(8),
            border: Border.all(color: textPrimary.withValues(alpha: 0.15)),
          ),
          child: Text(
            'M4 SECURE',
            style: GoogleFonts.montserrat(
              fontSize: 8,
              fontWeight: FontWeight.w900,
              letterSpacing: 1.5,
              color: textPrimary.withValues(alpha: 0.5),
            ),
          ),
        ),
      ],
    );
  }

  Widget _buildDocumentList(bool isDark, Color textPrimary) {
    if (_documents.isEmpty) {
      return Container(
        width: double.infinity,
        padding: const EdgeInsets.symmetric(vertical: 40),
        decoration: BoxDecoration(
          color: isDark ? Colors.white.withValues(alpha: 0.03) : Colors.white,
          borderRadius: BorderRadius.circular(20),
          border: Border.all(color: textPrimary.withValues(alpha: 0.06)),
        ),
        child: Column(
          children: [
            Icon(LucideIcons.fileText, size: 48, color: textPrimary.withValues(alpha: 0.12)),
            const SizedBox(height: 16),
            Text(
              'NO DOCUMENTS YET',
              style: GoogleFonts.montserrat(
                fontSize: 10,
                fontWeight: FontWeight.w900,
                letterSpacing: 2,
                color: textPrimary.withValues(alpha: 0.2),
              ),
            ),
          ],
        ),
      );
    }

    return Column(
      children: _documents.map((doc) => _buildDocumentCard(doc, isDark, textPrimary)).toList(),
    );
  }

  Widget _buildDocumentCard(Map<String, dynamic> doc, bool isDark, Color textPrimary) {
    final muted = textPrimary.withValues(alpha: 0.5);
    final title = (doc['title'] ?? 'Document').toString();
    final type = (doc['type'] ?? '').toString();
    final size = (doc['size'] ?? '').toString();
    final date = (doc['date'] ?? '').toString();
    final url = (doc['url'] ?? '').toString();

    final meta = [type, size, date].where((s) => s.isNotEmpty).toList();

    return Container(
      margin: const EdgeInsets.only(bottom: 12),
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: isDark ? Colors.white.withValues(alpha: 0.03) : Colors.white,
        borderRadius: BorderRadius.circular(20),
        border: Border.all(color: textPrimary.withValues(alpha: 0.06)),
        boxShadow: isDark
            ? []
            : [
                BoxShadow(
                  color: Colors.black.withValues(alpha: 0.04),
                  blurRadius: 10,
                  offset: const Offset(0, 4),
                ),
              ],
      ),
      child: Row(
        children: [
          // File icon
          Container(
            width: 48,
            height: 48,
            decoration: BoxDecoration(
              color: textPrimary.withValues(alpha: 0.04),
              borderRadius: BorderRadius.circular(14),
              border: Border.all(color: textPrimary.withValues(alpha: 0.08)),
            ),
            child: Icon(LucideIcons.fileText, size: 22, color: muted),
          ),
          const SizedBox(width: 14),
          // Title + meta
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  title,
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                  style: GoogleFonts.montserrat(
                    fontSize: 13,
                    fontWeight: FontWeight.w800,
                    color: textPrimary,
                  ),
                ),
                const SizedBox(height: 6),
                Row(
                  children: [
                    for (int i = 0; i < meta.length; i++) ...[
                      if (i > 0) ...[
                        const SizedBox(width: 6),
                        Container(
                          width: 3,
                          height: 3,
                          decoration: BoxDecoration(
                            color: textPrimary.withValues(alpha: 0.2),
                            shape: BoxShape.circle,
                          ),
                        ),
                        const SizedBox(width: 6),
                      ],
                      Text(
                        meta[i].toUpperCase(),
                        style: GoogleFonts.montserrat(
                          fontSize: 8,
                          fontWeight: FontWeight.w800,
                          letterSpacing: 0.8,
                          color: muted,
                        ),
                      ),
                    ],
                  ],
                ),
              ],
            ),
          ),
          // Action buttons
          _buildIconAction(LucideIcons.eye, muted, () => _openDocument(url)),
          const SizedBox(width: 4),
          _buildIconAction(LucideIcons.download, muted, () => _downloadDocument(url)),
        ],
      ),
    );
  }

  Widget _buildIconAction(IconData icon, Color color, VoidCallback onTap) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        padding: const EdgeInsets.all(8),
        child: Icon(icon, size: 18, color: color),
      ),
    );
  }

  // ━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━
  // SECURITY NOTICE
  // ━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━
  Widget _buildSecurityNotice(bool isDark, Color textPrimary) {
    return ClipRRect(
      borderRadius: BorderRadius.circular(20),
      child: Container(
        padding: const EdgeInsets.all(16),
        decoration: BoxDecoration(
          color: textPrimary.withValues(alpha: 0.03),
          borderRadius: BorderRadius.circular(20),
          border: Border.all(color: textPrimary.withValues(alpha: 0.06)),
        ),
        child: Stack(
          children: [
            // Watermark overlay (~3% opacity)
            Positioned.fill(
              child: Center(
                child: Opacity(
                  opacity: 0.03,
                  child: Transform.rotate(
                    angle: -0.2,
                    child: Text(
                      'M4 FAMILY  DOCUMENT REPOSITORY',
                      maxLines: 1,
                      softWrap: false,
                      overflow: TextOverflow.visible,
                      style: GoogleFonts.montserrat(
                        fontSize: 28,
                        fontWeight: FontWeight.w900,
                        color: textPrimary,
                      ),
                    ),
                  ),
                ),
              ),
            ),
            Row(
              children: [
                Container(
                  width: 40,
                  height: 40,
                  decoration: BoxDecoration(
                    color: textPrimary.withValues(alpha: 0.05),
                    shape: BoxShape.circle,
                    border: Border.all(color: textPrimary.withValues(alpha: 0.08)),
                  ),
                  child: Icon(LucideIcons.shieldCheck, size: 18, color: textPrimary.withValues(alpha: 0.6)),
                ),
                const SizedBox(width: 14),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        'SECURE ACCESS ONLY',
                        style: GoogleFonts.montserrat(
                          fontSize: 11,
                          fontWeight: FontWeight.w900,
                          letterSpacing: 1,
                          color: textPrimary,
                        ),
                      ),
                      const SizedBox(height: 4),
                      Text(
                        'All documents downloaded contain a unique user watermark for security. Unauthorized sharing is strictly prohibited.',
                        style: GoogleFonts.montserrat(
                          fontSize: 10,
                          fontWeight: FontWeight.w500,
                          height: 1.4,
                          color: textPrimary.withValues(alpha: 0.5),
                        ),
                      ),
                    ],
                  ),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }

  // ━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━
  // UPGRADE CTA
  // ━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━
  Widget _buildUpgradeButton(bool isDark, Color textPrimary) {
    return GestureDetector(
      onTap: () => _toast('Membership upgrade coming soon'),
      child: Container(
        width: double.infinity,
        height: 56,
        decoration: BoxDecoration(
          borderRadius: BorderRadius.circular(16),
          border: Border.all(color: textPrimary.withValues(alpha: 0.15)),
        ),
        child: Row(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(LucideIcons.star, size: 18, color: textPrimary),
            const SizedBox(width: 12),
            Text(
              'UPGRADE MEMBERSHIP TIER',
              style: GoogleFonts.montserrat(
                fontSize: 11,
                fontWeight: FontWeight.w900,
                letterSpacing: 1.5,
                color: textPrimary,
              ),
            ),
          ],
        ),
      ),
    );
  }
}
