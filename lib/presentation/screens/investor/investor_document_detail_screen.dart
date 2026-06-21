import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:lucide_icons/lucide_icons.dart';
import 'package:flutter_animate/flutter_animate.dart';
import 'package:go_router/go_router.dart';
import 'package:intl/intl.dart';
import 'package:url_launcher/url_launcher.dart';
import 'package:m4_mobile/core/theme/app_theme.dart';
import 'package:m4_mobile/presentation/providers/auth_provider.dart';

/// Investor Document Detail — mirrors the web `/investor/documents/[id]`
/// secure document viewer / metadata dialog. Takes [documentId] as a
/// go_router pathParameter, fetches the investor's secure documents and
/// resolves the matching record, then presents it as a detail modal/dialog
/// with badges, a metadata grid, verification status, description and an
/// open / download action.
class InvestorDocumentDetailScreen extends ConsumerStatefulWidget {
  final String documentId;
  const InvestorDocumentDetailScreen({super.key, required this.documentId});

  @override
  ConsumerState<InvestorDocumentDetailScreen> createState() =>
      _InvestorDocumentDetailScreenState();
}

class _InvestorDocumentDetailScreenState
    extends ConsumerState<InvestorDocumentDetailScreen> {
  static const Color _gold = Color(0xFFFFD700);
  static const Color _green = Color(0xFF22C55E);

  bool _isLoading = true;
  bool _hasError = false;
  Map<String, dynamic>? _doc;

  @override
  void initState() {
    super.initState();
    _fetchDocument();
  }

  Future<void> _fetchDocument() async {
    setState(() {
      _isLoading = true;
      _hasError = false;
    });
    try {
      final apiClient = ref.read(apiClientProvider);
      final res = await apiClient.getMySupportDocuments();
      if (res.data['status'] == true) {
        final List<dynamic> docs = res.data['data'] ?? [];
        Map<String, dynamic>? match;
        for (final d in docs) {
          if (d is Map<String, dynamic>) {
            final id = (d['_id'] ?? d['id'] ?? '').toString();
            if (id == widget.documentId) {
              match = d;
              break;
            }
          }
        }
        if (mounted) {
          setState(() {
            _doc = match;
            _isLoading = false;
          });
        }
      } else {
        if (mounted) setState(() => _hasError = true);
      }
    } catch (e) {
      debugPrint('Error fetching investor document: $e');
      if (mounted) setState(() => _hasError = true);
    } finally {
      if (mounted) setState(() => _isLoading = false);
    }
  }

  void _close() {
    if (context.canPop()) {
      context.pop();
    } else {
      context.go('/investor/home');
    }
  }

  Future<void> _openDocument() async {
    final apiClient = ref.read(apiClientProvider);
    final raw = (_doc?['fileUrl'] ?? _doc?['url'] ?? '').toString();
    final resolved = apiClient.resolveUrl(raw);
    if (resolved.isEmpty) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(
            'Secure link not available for this document',
            style: GoogleFonts.montserrat(
                fontWeight: FontWeight.bold, fontSize: 12),
          ),
          backgroundColor: Colors.redAccent,
          behavior: SnackBarBehavior.floating,
          shape:
              RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
        ),
      );
      return;
    }
    final uri = Uri.tryParse(resolved);
    if (uri != null) {
      await launchUrl(uri, mode: LaunchMode.externalApplication);
    }
  }

  String _formatDate(dynamic dateStr) {
    if (dateStr == null) return '—';
    try {
      return DateFormat('d MMM yyyy').format(DateTime.parse(dateStr.toString()));
    } catch (_) {
      return dateStr.toString();
    }
  }

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final bg = isDark ? Colors.black : Colors.white;

    return Scaffold(
      backgroundColor: Colors.black.withValues(alpha: 0.6),
      body: GestureDetector(
        onTap: _close,
        child: Container(
          color: Colors.transparent,
          alignment: Alignment.center,
          child: GestureDetector(
            onTap: () {},
            child: ConstrainedBox(
              constraints: const BoxConstraints(maxWidth: 420),
              child: Padding(
                padding: const EdgeInsets.symmetric(horizontal: 20),
                child: Material(
                  color: bg,
                  borderRadius: BorderRadius.circular(32),
                  clipBehavior: Clip.antiAlias,
                  child: _buildContent(isDark, bg),
                ),
              ),
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildContent(bool isDark, Color bg) {
    if (_isLoading) {
      return const SizedBox(
        height: 320,
        child: Center(
          child: CircularProgressIndicator(color: M4Theme.premiumBlue),
        ),
      );
    }
    if (_hasError) {
      return _buildStatus(
        isDark,
        icon: LucideIcons.alertTriangle,
        title: 'UNABLE TO LOAD DOCUMENT',
        subtitle: 'Something went wrong. Please try again.',
        showRetry: true,
      );
    }
    if (_doc == null) {
      return _buildStatus(
        isDark,
        icon: LucideIcons.fileSearch,
        title: 'DOCUMENT NOT FOUND',
        subtitle: 'The requested document could not be found.',
      );
    }
    return _buildDocumentDetail(isDark);
  }

  Widget _buildStatus(
    bool isDark, {
    required IconData icon,
    required String title,
    required String subtitle,
    bool showRetry = false,
  }) {
    final textPrimary = isDark ? Colors.white : Colors.black;
    final muted = (isDark ? Colors.white : Colors.black).withValues(alpha: 0.5);
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 32, vertical: 48),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          Container(
            width: 80,
            height: 80,
            decoration: BoxDecoration(
              color: (isDark ? Colors.white : Colors.black)
                  .withValues(alpha: 0.05),
              borderRadius: BorderRadius.circular(24),
            ),
            child: Icon(icon, size: 36, color: muted),
          ),
          const SizedBox(height: 24),
          Text(
            title,
            textAlign: TextAlign.center,
            style: GoogleFonts.montserrat(
              fontSize: 14,
              fontWeight: FontWeight.w800,
              color: textPrimary,
              letterSpacing: 1.5,
            ),
          ),
          const SizedBox(height: 8),
          Text(
            subtitle,
            textAlign: TextAlign.center,
            style: GoogleFonts.montserrat(
              fontSize: 11,
              fontWeight: FontWeight.w500,
              color: muted,
              height: 1.5,
            ),
          ),
          const SizedBox(height: 28),
          if (showRetry)
            _PrimaryButton(
              label: 'RETRY',
              icon: LucideIcons.refreshCw,
              isDark: isDark,
              onTap: _fetchDocument,
            )
          else
            _PrimaryButton(
              label: 'CLOSE',
              icon: LucideIcons.x,
              isDark: isDark,
              onTap: _close,
            ),
        ],
      ),
    );
  }

  Widget _buildDocumentDetail(bool isDark) {
    final doc = _doc!;
    final textPrimary = isDark ? Colors.white : Colors.black;
    final muted = (isDark ? Colors.white : Colors.black).withValues(alpha: 0.5);
    final card = isDark ? Colors.white.withValues(alpha: 0.03) : Colors.white;
    final border = isDark
        ? Colors.white.withValues(alpha: 0.08)
        : Colors.black.withValues(alpha: 0.06);

    final title =
        (doc['name'] ?? doc['title'] ?? 'Document').toString();
    final type = (doc['type'] ?? doc['project']?['title'] ?? 'Document')
        .toString();
    final description =
        (doc['description'] ?? 'Standard encrypted asset payload.').toString();
    final size = (doc['size'] ?? 'Managed Asset').toString();
    final date = _formatDate(doc['createdAt'] ?? doc['uploadedAt']);

    return SingleChildScrollView(
      physics: const BouncingScrollPhysics(),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // ── Preview header ──────────────────────────────────────────
          Stack(
            children: [
              Container(
                height: 150,
                width: double.infinity,
                decoration: BoxDecoration(
                  gradient: LinearGradient(
                    begin: Alignment.topLeft,
                    end: Alignment.bottomRight,
                    colors: [
                      _gold.withValues(alpha: 0.18),
                      (isDark ? Colors.white : Colors.black)
                          .withValues(alpha: 0.03),
                    ],
                  ),
                  border: Border(bottom: BorderSide(color: border)),
                ),
                child: const Center(
                  child: Icon(LucideIcons.fileText, size: 56, color: _gold),
                ),
              ),
              Positioned(
                top: 12,
                right: 12,
                child: GestureDetector(
                  onTap: _close,
                  child: Container(
                    padding: const EdgeInsets.all(8),
                    decoration: BoxDecoration(
                      color: (isDark ? Colors.black : Colors.white)
                          .withValues(alpha: 0.4),
                      shape: BoxShape.circle,
                    ),
                    child: Icon(LucideIcons.x, size: 18, color: textPrimary),
                  ),
                ),
              ),
            ],
          ),

          Padding(
            padding: const EdgeInsets.all(28),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                // ── Badge + title ─────────────────────────────────────
                Container(
                  padding:
                      const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
                  decoration: BoxDecoration(
                    color: _gold.withValues(alpha: 0.12),
                    borderRadius: BorderRadius.circular(8),
                    border: Border.all(color: _gold.withValues(alpha: 0.25)),
                  ),
                  child: Text(
                    'SECURED ${type.toUpperCase()}',
                    style: GoogleFonts.montserrat(
                      fontSize: 8,
                      fontWeight: FontWeight.w800,
                      color: _gold,
                      letterSpacing: 1.5,
                    ),
                  ),
                ),
                const SizedBox(height: 12),
                Text(
                  title.toUpperCase(),
                  style: GoogleFonts.montserrat(
                    fontSize: 20,
                    fontWeight: FontWeight.w800,
                    color: textPrimary,
                    height: 1.15,
                  ),
                ),
                const SizedBox(height: 24),

                // ── Metadata grid ─────────────────────────────────────
                Row(
                  children: [
                    Expanded(
                      child: _MetaCell(
                        icon: LucideIcons.calendar,
                        label: 'ISSUE DATE',
                        value: date,
                        card: card,
                        border: border,
                        textPrimary: textPrimary,
                        muted: muted,
                        accent: _gold,
                      ),
                    ),
                    const SizedBox(width: 12),
                    Expanded(
                      child: _MetaCell(
                        icon: LucideIcons.hardDrive,
                        label: 'FILE SIZE',
                        value: size,
                        card: card,
                        border: border,
                        textPrimary: textPrimary,
                        muted: muted,
                        accent: _gold,
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 24),

                // ── Verification status ───────────────────────────────
                Text(
                  'VERIFICATION STATUS',
                  style: GoogleFonts.montserrat(
                    fontSize: 8,
                    fontWeight: FontWeight.w800,
                    color: muted,
                    letterSpacing: 1.5,
                  ),
                ),
                const SizedBox(height: 8),
                Container(
                  padding:
                      const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
                  decoration: BoxDecoration(
                    color: _green.withValues(alpha: 0.1),
                    borderRadius: BorderRadius.circular(12),
                    border: Border.all(color: _green.withValues(alpha: 0.2)),
                  ),
                  child: Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      const Icon(LucideIcons.shieldCheck, size: 14, color: _green),
                      const SizedBox(width: 8),
                      Text(
                        'ENCRYPTED & VERIFIED',
                        style: GoogleFonts.montserrat(
                          fontSize: 9,
                          fontWeight: FontWeight.w800,
                          color: _green,
                          letterSpacing: 1,
                        ),
                      ),
                    ],
                  ),
                ),
                const SizedBox(height: 24),

                // ── Description / overview ────────────────────────────
                Text(
                  'DOCUMENT OVERVIEW',
                  style: GoogleFonts.montserrat(
                    fontSize: 8,
                    fontWeight: FontWeight.w800,
                    color: muted,
                    letterSpacing: 1.5,
                  ),
                ),
                const SizedBox(height: 8),
                Text(
                  '"$description"',
                  style: GoogleFonts.montserrat(
                    fontSize: 11,
                    fontWeight: FontWeight.w500,
                    fontStyle: FontStyle.italic,
                    color: muted,
                    height: 1.6,
                  ),
                ),
                const SizedBox(height: 28),

                // ── Open / download action ────────────────────────────
                _PrimaryButton(
                  label: 'OPEN SECURE LINK',
                  icon: LucideIcons.eye,
                  isDark: isDark,
                  onTap: _openDocument,
                ),
              ],
            ),
          ),
        ],
      ),
    ).animate().fadeIn(duration: 250.ms).slideY(begin: 0.05);
  }
}

class _MetaCell extends StatelessWidget {
  final IconData icon;
  final String label;
  final String value;
  final Color card;
  final Color border;
  final Color textPrimary;
  final Color muted;
  final Color accent;

  const _MetaCell({
    required this.icon,
    required this.label,
    required this.value,
    required this.card,
    required this.border,
    required this.textPrimary,
    required this.muted,
    required this.accent,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: card,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: border),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Icon(icon, size: 11, color: accent.withValues(alpha: 0.7)),
              const SizedBox(width: 6),
              Text(
                label,
                style: GoogleFonts.montserrat(
                  fontSize: 7,
                  fontWeight: FontWeight.w800,
                  color: muted,
                  letterSpacing: 1,
                ),
              ),
            ],
          ),
          const SizedBox(height: 6),
          Text(
            value,
            style: GoogleFonts.montserrat(
              fontSize: 11,
              fontWeight: FontWeight.w800,
              color: textPrimary,
            ),
          ),
        ],
      ),
    );
  }
}

class _PrimaryButton extends StatelessWidget {
  final String label;
  final IconData icon;
  final bool isDark;
  final VoidCallback onTap;

  const _PrimaryButton({
    required this.label,
    required this.icon,
    required this.isDark,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return SizedBox(
      width: double.infinity,
      height: 56,
      child: ElevatedButton.icon(
        onPressed: onTap,
        icon: Icon(icon, size: 18),
        label: Text(
          label,
          style: GoogleFonts.montserrat(
            fontSize: 11,
            fontWeight: FontWeight.w900,
            letterSpacing: 1.5,
          ),
        ),
        style: ElevatedButton.styleFrom(
          backgroundColor: isDark ? Colors.white : Colors.black,
          foregroundColor: isDark ? Colors.black : Colors.white,
          elevation: 0,
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(18),
          ),
        ),
      ),
    );
  }
}
