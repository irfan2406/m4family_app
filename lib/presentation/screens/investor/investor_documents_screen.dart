import 'package:flutter/foundation.dart' show kIsWeb;
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_animate/flutter_animate.dart';
import 'package:go_router/go_router.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:intl/intl.dart';
import 'package:lucide_icons/lucide_icons.dart';
import 'package:url_launcher/url_launcher.dart';
import 'package:m4_mobile/core/theme/app_theme.dart';
import 'package:m4_mobile/presentation/providers/auth_provider.dart';

/// Investor legal vault — parity with web `app/investor/documents/page.tsx`.
/// Secure document repository: filters (All/Agreement/Receipt/NOC/Plan/Booking),
/// document list with file icon/name/date/size, view + download actions, and a
/// metadata dialog (web) / bottom sheet (mobile) on tap. Documents are fetched
/// from `/documents` and `/bookings/my` combined. Follows M4 conventions.
class InvestorDocumentsScreen extends ConsumerStatefulWidget {
  const InvestorDocumentsScreen({super.key});

  @override
  ConsumerState<InvestorDocumentsScreen> createState() =>
      _InvestorDocumentsScreenState();
}

class _InvestorDocumentsScreenState
    extends ConsumerState<InvestorDocumentsScreen> {
  static const _gold = Color(0xFFFFD700);
  static const _filters = ['All', 'Agreement', 'Receipt', 'NOC', 'Plan', 'Booking'];

  bool _loading = true;
  String? _error;
  List<Map<String, dynamic>> _documents = [];
  String _selectedFilter = 'All';

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) => _fetchDocuments());
  }

  Future<void> _fetchDocuments() async {
    if (mounted) {
      setState(() {
        _loading = true;
        _error = null;
      });
    }
    try {
      final apiClient = ref.read(apiClientProvider);
      final results = await Future.wait(<Future<dynamic>>[
        apiClient.get('/api/documents'),
        apiClient.get('/api/bookings/my'),
      ]);

      final combined = <Map<String, dynamic>>[];

      final docRes = results[0];
      if (docRes.data is Map &&
          docRes.data['status'] == true &&
          docRes.data['data'] is List) {
        for (final raw in (docRes.data['data'] as List)) {
          if (raw is! Map) continue;
          final doc = Map<String, dynamic>.from(raw);
          combined.add({
            'id': doc['_id']?.toString() ?? UniqueKey().toString(),
            'title': doc['title'] ?? doc['name'] ?? 'Document',
            'type': doc['type'] ?? 'Document',
            'url': doc['url'] ?? doc['fileUrl'],
            'createdAt': doc['createdAt'],
            'size': doc['size'] ?? 'Managed Asset',
            'description': doc['description'],
          });
        }
      }

      final bookingRes = results[1];
      if (bookingRes.data is Map &&
          bookingRes.data['status'] == true &&
          bookingRes.data['data'] is List) {
        for (final raw in (bookingRes.data['data'] as List)) {
          if (raw is! Map) continue;
          final booking = Map<String, dynamic>.from(raw);
          final docs = booking['documents'];
          if (docs is! List) continue;
          final project = booking['project'];
          final projectTitle = (project is Map ? project['title'] : null) ?? 'Property';
          for (final bRaw in docs) {
            if (bRaw is! Map) continue;
            final bDoc = Map<String, dynamic>.from(bRaw);
            final url = bDoc['url'];
            // Prevent duplicates if same URL already added.
            if (url != null && combined.any((d) => d['url'] == url)) continue;
            combined.add({
              'id': bDoc['_id']?.toString() ?? UniqueKey().toString(),
              'title': bDoc['name'] ?? 'Booking Document',
              'type': 'Booking',
              'url': url,
              'createdAt': bDoc['uploadedAt'] ?? booking['createdAt'],
              'size': bDoc['size'] ?? 'Managed Asset',
              'description': 'Official document for $projectTitle',
            });
          }
        }
      }

      combined.sort((a, b) {
        final da = _parseDate(a['createdAt']);
        final db = _parseDate(b['createdAt']);
        return db.compareTo(da);
      });

      if (mounted) setState(() => _documents = combined);
    } catch (e) {
      if (mounted) setState(() => _error = 'Failed to load secure documents');
    } finally {
      if (mounted) setState(() => _loading = false);
    }
  }

  DateTime _parseDate(dynamic value) {
    if (value is String) {
      return DateTime.tryParse(value) ?? DateTime.fromMillisecondsSinceEpoch(0);
    }
    return DateTime.fromMillisecondsSinceEpoch(0);
  }

  String _formatDate(dynamic value) {
    final parsed = _parseDate(value);
    if (parsed.millisecondsSinceEpoch == 0) return '--';
    return DateFormat('MMM d, yyyy').format(parsed);
  }

  List<Map<String, dynamic>> get _filteredDocs {
    if (_selectedFilter == 'All') return _documents;
    return _documents.where((d) => d['type'] == _selectedFilter).toList();
  }

  Future<void> _openUrl(BuildContext context, dynamic url) async {
    final apiClient = ref.read(apiClientProvider);
    final resolved = apiClient.resolveUrl(url?.toString());
    if (resolved.isEmpty) {
      if (context.mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Secure link not available for this document')),
        );
      }
      return;
    }
    final uri = Uri.tryParse(resolved);
    if (uri != null) {
      await launchUrl(uri, mode: LaunchMode.externalApplication);
    }
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
            _buildHeader(isDark, textPrimary),
            Expanded(
              child: _loading
                  ? const Center(
                      child: CircularProgressIndicator(color: M4Theme.premiumBlue),
                    )
                  : Column(
                      children: [
                        _buildFilterTabs(isDark, textPrimary),
                        Expanded(child: _buildBody(isDark, textPrimary)),
                      ],
                    ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildHeader(bool isDark, Color textPrimary) {
    final card = isDark ? Colors.white.withValues(alpha: 0.03) : Colors.white;
    final border = isDark
        ? Colors.white.withValues(alpha: 0.08)
        : Colors.black.withValues(alpha: 0.06);

    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 16),
      decoration: BoxDecoration(
        border: Border(bottom: BorderSide(color: border)),
      ),
      child: Row(
        children: [
          GestureDetector(
            onTap: () => context.canPop()
                ? context.pop()
                : context.go('/investor/home'),
            child: Container(
              width: 40,
              height: 40,
              decoration: BoxDecoration(
                color: card,
                borderRadius: BorderRadius.circular(14),
                border: Border.all(color: border),
              ),
              child: Icon(LucideIcons.arrowLeft,
                  size: 20,
                  color: (isDark ? Colors.white : Colors.black)
                      .withValues(alpha: 0.5)),
            ),
          ),
          const SizedBox(width: 16),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  'LEGAL VAULT',
                  style: GoogleFonts.montserrat(
                    fontSize: 18,
                    fontWeight: FontWeight.w800,
                    color: textPrimary,
                    letterSpacing: -0.3,
                  ),
                ),
                const SizedBox(height: 3),
                Row(
                  children: [
                    const Icon(LucideIcons.lock, size: 10, color: _gold),
                    const SizedBox(width: 5),
                    Text(
                      'SECURE REPOSITORY',
                      style: GoogleFonts.montserrat(
                        fontSize: 8,
                        fontWeight: FontWeight.w700,
                        color: (isDark ? Colors.white : Colors.black)
                            .withValues(alpha: 0.5),
                        letterSpacing: 2,
                      ),
                    ),
                  ],
                ),
              ],
            ),
          ),
          Container(
            width: 40,
            height: 40,
            decoration: BoxDecoration(
              color: card,
              borderRadius: BorderRadius.circular(14),
              border: Border.all(color: border),
            ),
            child: Icon(LucideIcons.shield,
                size: 18,
                color: (isDark ? Colors.white : Colors.black)
                    .withValues(alpha: 0.5)),
          ),
        ],
      ),
    );
  }

  Widget _buildFilterTabs(bool isDark, Color textPrimary) {
    return SingleChildScrollView(
      scrollDirection: Axis.horizontal,
      padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 16),
      child: Row(
        children: _filters.map((f) {
          final selected = _selectedFilter == f;
          final border = isDark
              ? Colors.white.withValues(alpha: 0.08)
              : Colors.black.withValues(alpha: 0.06);
          return Padding(
            padding: const EdgeInsets.only(right: 10),
            child: GestureDetector(
              onTap: () => setState(() => _selectedFilter = f),
              child: Container(
                height: 36,
                padding: const EdgeInsets.symmetric(horizontal: 24),
                alignment: Alignment.center,
                decoration: BoxDecoration(
                  color: selected
                      ? textPrimary
                      : (isDark ? Colors.white.withValues(alpha: 0.03) : Colors.white),
                  borderRadius: BorderRadius.circular(12),
                  border: Border.all(color: selected ? textPrimary : border),
                ),
                child: Text(
                  f.toUpperCase(),
                  style: GoogleFonts.montserrat(
                    fontSize: 9,
                    fontWeight: FontWeight.w800,
                    letterSpacing: 1.5,
                    color: selected
                        ? (isDark ? Colors.black : Colors.white)
                        : (isDark ? Colors.white : Colors.black)
                            .withValues(alpha: 0.5),
                  ),
                ),
              ),
            ),
          );
        }).toList(),
      ),
    );
  }

  Widget _buildBody(bool isDark, Color textPrimary) {
    if (_error != null) {
      return _buildErrorState(isDark, textPrimary);
    }
    final docs = _filteredDocs;
    return RefreshIndicator(
      color: M4Theme.premiumBlue,
      onRefresh: _fetchDocuments,
      child: docs.isEmpty
          ? ListView(
              physics: const AlwaysScrollableScrollPhysics(),
              children: [
                SizedBox(height: MediaQuery.of(context).size.height * 0.18),
                _buildEmptyState(isDark),
              ],
            )
          : ListView.builder(
              physics: const BouncingScrollPhysics(),
              padding: const EdgeInsets.fromLTRB(24, 4, 24, 32),
              itemCount: docs.length,
              itemBuilder: (context, index) =>
                  _buildDocumentCard(docs[index], isDark, textPrimary),
            ),
    );
  }

  Widget _buildDocumentCard(
      Map<String, dynamic> doc, bool isDark, Color textPrimary) {
    final card = isDark ? Colors.white.withValues(alpha: 0.03) : Colors.white;
    final border = isDark
        ? Colors.white.withValues(alpha: 0.08)
        : Colors.black.withValues(alpha: 0.06);
    final muted = (isDark ? Colors.white : Colors.black).withValues(alpha: 0.5);

    return Container(
      margin: const EdgeInsets.only(bottom: 12),
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: card,
        borderRadius: BorderRadius.circular(24),
        border: Border.all(color: border),
        boxShadow: isDark
            ? []
            : [
                BoxShadow(
                  color: Colors.black.withValues(alpha: 0.04),
                  blurRadius: 12,
                  offset: const Offset(0, 4),
                ),
              ],
      ),
      child: InkWell(
        borderRadius: BorderRadius.circular(24),
        onTap: () => _showDocumentDetails(doc, isDark, textPrimary),
        child: Row(
          children: [
            Container(
              width: 48,
              height: 48,
              decoration: BoxDecoration(
                color: (isDark ? Colors.white : Colors.black)
                    .withValues(alpha: 0.05),
                borderRadius: BorderRadius.circular(16),
                border: Border.all(color: border),
              ),
              child: Icon(LucideIcons.fileText, size: 22, color: textPrimary),
            ),
            const SizedBox(width: 14),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    (doc['title'] ?? 'DOCUMENT').toString().toUpperCase(),
                    maxLines: 2,
                    overflow: TextOverflow.ellipsis,
                    style: GoogleFonts.montserrat(
                      fontSize: 13,
                      fontWeight: FontWeight.w800,
                      color: textPrimary,
                      letterSpacing: -0.2,
                    ),
                  ),
                  const SizedBox(height: 5),
                  Row(
                    children: [
                      Text(
                        _formatDate(doc['createdAt']).toUpperCase(),
                        style: GoogleFonts.montserrat(
                          fontSize: 8,
                          fontWeight: FontWeight.w700,
                          color: muted,
                          letterSpacing: 1,
                        ),
                      ),
                      const SizedBox(width: 8),
                      Container(
                        width: 3,
                        height: 3,
                        decoration: BoxDecoration(
                          color: _gold.withValues(alpha: 0.5),
                          shape: BoxShape.circle,
                        ),
                      ),
                      const SizedBox(width: 8),
                      Flexible(
                        child: Text(
                          (doc['size'] ?? '').toString().toUpperCase(),
                          overflow: TextOverflow.ellipsis,
                          style: GoogleFonts.montserrat(
                            fontSize: 8,
                            fontWeight: FontWeight.w700,
                            color: _gold.withValues(alpha: 0.7),
                            letterSpacing: 1,
                          ),
                        ),
                      ),
                    ],
                  ),
                ],
              ),
            ),
            const SizedBox(width: 8),
            _SquareIconButton(
              icon: LucideIcons.eye,
              isDark: isDark,
              onTap: () => _showDocumentDetails(doc, isDark, textPrimary),
            ),
            const SizedBox(width: 8),
            _SquareIconButton(
              icon: LucideIcons.download,
              isDark: isDark,
              onTap: () => _openUrl(context, doc['url']),
            ),
          ],
        ),
      ),
    ).animate().fadeIn(duration: 300.ms).slideX(begin: 0.05);
  }

  void _showDocumentDetails(
      Map<String, dynamic> doc, bool isDark, Color textPrimary) {
    if (kIsWeb) {
      showDialog(
        context: context,
        barrierColor: Colors.black.withValues(alpha: 0.6),
        builder: (ctx) => Dialog(
          backgroundColor: Colors.transparent,
          insetPadding: const EdgeInsets.all(24),
          child: ConstrainedBox(
            constraints: const BoxConstraints(maxWidth: 420),
            child: _DocumentDetail(
              doc: doc,
              isDark: isDark,
              formattedDate: _formatDate(doc['createdAt']),
              onOpen: () => _openUrl(ctx, doc['url']),
              rounded: true,
            ),
          ),
        ),
      );
    } else {
      showModalBottomSheet(
        context: context,
        backgroundColor: Colors.transparent,
        isScrollControlled: true,
        builder: (ctx) => _DocumentDetail(
          doc: doc,
          isDark: isDark,
          formattedDate: _formatDate(doc['createdAt']),
          onOpen: () => _openUrl(ctx, doc['url']),
          rounded: false,
        ),
      );
    }
  }

  Widget _buildEmptyState(bool isDark) {
    final muted = (isDark ? Colors.white : Colors.black).withValues(alpha: 0.5);
    return Column(
      children: [
        Container(
          width: 80,
          height: 80,
          decoration: BoxDecoration(
            color: (isDark ? Colors.white : Colors.black).withValues(alpha: 0.04),
            shape: BoxShape.circle,
          ),
          child: Icon(LucideIcons.fileSearch,
              size: 36, color: muted.withValues(alpha: 0.5)),
        ),
        const SizedBox(height: 24),
        Text(
          'NO DOCUMENTS FOUND',
          style: GoogleFonts.montserrat(
            fontSize: 10,
            fontWeight: FontWeight.w800,
            color: muted,
            letterSpacing: 3,
          ),
        ),
      ],
    );
  }

  Widget _buildErrorState(bool isDark, Color textPrimary) {
    final muted = (isDark ? Colors.white : Colors.black).withValues(alpha: 0.5);
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(32),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(LucideIcons.fileWarning,
                size: 48, color: muted.withValues(alpha: 0.6)),
            const SizedBox(height: 20),
            Text(
              _error ?? 'Something went wrong',
              textAlign: TextAlign.center,
              style: GoogleFonts.montserrat(
                fontSize: 12,
                fontWeight: FontWeight.w700,
                color: textPrimary,
              ),
            ),
            const SizedBox(height: 20),
            GestureDetector(
              onTap: _fetchDocuments,
              child: Container(
                padding:
                    const EdgeInsets.symmetric(horizontal: 28, vertical: 14),
                decoration: BoxDecoration(
                  color: textPrimary,
                  borderRadius: BorderRadius.circular(14),
                ),
                child: Text(
                  'RETRY',
                  style: GoogleFonts.montserrat(
                    fontSize: 10,
                    fontWeight: FontWeight.w800,
                    letterSpacing: 2,
                    color: isDark ? Colors.black : Colors.white,
                  ),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _SquareIconButton extends StatelessWidget {
  final IconData icon;
  final bool isDark;
  final VoidCallback onTap;
  const _SquareIconButton({
    required this.icon,
    required this.isDark,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    final border = isDark
        ? Colors.white.withValues(alpha: 0.08)
        : Colors.black.withValues(alpha: 0.06);
    return GestureDetector(
      onTap: onTap,
      child: Container(
        width: 40,
        height: 40,
        decoration: BoxDecoration(
          color: isDark ? Colors.white.withValues(alpha: 0.03) : Colors.white,
          borderRadius: BorderRadius.circular(12),
          border: Border.all(color: border),
        ),
        child: Icon(icon,
            size: 16,
            color:
                (isDark ? Colors.white : Colors.black).withValues(alpha: 0.5)),
      ),
    );
  }
}

class _DocumentDetail extends StatelessWidget {
  final Map<String, dynamic> doc;
  final bool isDark;
  final String formattedDate;
  final VoidCallback onOpen;
  final bool rounded;
  const _DocumentDetail({
    required this.doc,
    required this.isDark,
    required this.formattedDate,
    required this.onOpen,
    required this.rounded,
  });

  static const _gold = Color(0xFFFFD700);

  @override
  Widget build(BuildContext context) {
    final bg = isDark ? Colors.black : Colors.white;
    final textPrimary = isDark ? Colors.white : Colors.black;
    final muted = (isDark ? Colors.white : Colors.black).withValues(alpha: 0.5);
    final border = isDark
        ? Colors.white.withValues(alpha: 0.08)
        : Colors.black.withValues(alpha: 0.06);
    final type = (doc['type'] ?? 'Document').toString();

    return Container(
      decoration: BoxDecoration(
        color: bg,
        borderRadius: rounded
            ? BorderRadius.circular(36)
            : const BorderRadius.vertical(top: Radius.circular(36)),
        border: rounded ? Border.all(color: border) : null,
      ),
      child: ClipRRect(
        borderRadius: rounded
            ? BorderRadius.circular(36)
            : const BorderRadius.vertical(top: Radius.circular(36)),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            // Hero band
            Container(
              height: 140,
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
              child: const Icon(LucideIcons.fileText, size: 56, color: _gold),
            ),
            Padding(
              padding: const EdgeInsets.all(28),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                mainAxisSize: MainAxisSize.min,
                children: [
                  Container(
                    padding: const EdgeInsets.symmetric(
                        horizontal: 12, vertical: 6),
                    decoration: BoxDecoration(
                      color: _gold.withValues(alpha: 0.1),
                      borderRadius: BorderRadius.circular(10),
                      border:
                          Border.all(color: _gold.withValues(alpha: 0.25)),
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
                    (doc['title'] ?? 'DOCUMENT').toString().toUpperCase(),
                    style: GoogleFonts.montserrat(
                      fontSize: 20,
                      fontWeight: FontWeight.w800,
                      color: textPrimary,
                      letterSpacing: -0.3,
                      height: 1.2,
                    ),
                  ),
                  const SizedBox(height: 24),
                  Row(
                    children: [
                      Expanded(
                        child: _MetaTile(
                          icon: LucideIcons.calendar,
                          label: 'ISSUE DATE',
                          value: formattedDate,
                          isDark: isDark,
                        ),
                      ),
                      const SizedBox(width: 12),
                      Expanded(
                        child: _MetaTile(
                          icon: LucideIcons.hardDrive,
                          label: 'FILE SIZE',
                          value: (doc['size'] ?? '--').toString(),
                          isDark: isDark,
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 20),
                  Text(
                    'VERIFICATION STATUS',
                    style: GoogleFonts.montserrat(
                      fontSize: 8,
                      fontWeight: FontWeight.w800,
                      color: muted,
                      letterSpacing: 2,
                    ),
                  ),
                  const SizedBox(height: 8),
                  Container(
                    padding: const EdgeInsets.symmetric(
                        horizontal: 14, vertical: 8),
                    decoration: BoxDecoration(
                      color: const Color(0xFF22C55E).withValues(alpha: 0.1),
                      borderRadius: BorderRadius.circular(12),
                      border: Border.all(
                          color: const Color(0xFF22C55E)
                              .withValues(alpha: 0.25)),
                    ),
                    child: Row(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        const Icon(LucideIcons.shieldCheck,
                            size: 14, color: Color(0xFF22C55E)),
                        const SizedBox(width: 8),
                        Text(
                          'ENCRYPTED & VERIFIED',
                          style: GoogleFonts.montserrat(
                            fontSize: 9,
                            fontWeight: FontWeight.w800,
                            color: const Color(0xFF22C55E),
                            letterSpacing: 1.5,
                          ),
                        ),
                      ],
                    ),
                  ),
                  if (doc['description'] != null &&
                      doc['description'].toString().isNotEmpty) ...[
                    const SizedBox(height: 20),
                    Text(
                      'DOCUMENT OVERVIEW',
                      style: GoogleFonts.montserrat(
                        fontSize: 8,
                        fontWeight: FontWeight.w800,
                        color: muted,
                        letterSpacing: 2,
                      ),
                    ),
                    const SizedBox(height: 8),
                    Text(
                      '"${doc['description']}"',
                      style: GoogleFonts.montserrat(
                        fontSize: 11,
                        fontWeight: FontWeight.w600,
                        fontStyle: FontStyle.italic,
                        color: muted,
                        height: 1.5,
                      ),
                    ),
                  ],
                  const SizedBox(height: 28),
                  SizedBox(
                    width: double.infinity,
                    height: 54,
                    child: ElevatedButton.icon(
                      onPressed: () {
                        Navigator.of(context).pop();
                        onOpen();
                      },
                      icon: const Icon(LucideIcons.eye, size: 18),
                      label: Text(
                        'OPEN SECURE LINK',
                        style: GoogleFonts.montserrat(
                          fontSize: 10,
                          fontWeight: FontWeight.w900,
                          letterSpacing: 1.5,
                        ),
                      ),
                      style: ElevatedButton.styleFrom(
                        backgroundColor: textPrimary,
                        foregroundColor: isDark ? Colors.black : Colors.white,
                        elevation: 0,
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(18),
                        ),
                      ),
                    ),
                  ),
                  if (!rounded)
                    SizedBox(
                        height: MediaQuery.of(context).padding.bottom + 8),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _MetaTile extends StatelessWidget {
  final IconData icon;
  final String label;
  final String value;
  final bool isDark;
  const _MetaTile({
    required this.icon,
    required this.label,
    required this.value,
    required this.isDark,
  });

  static const _gold = Color(0xFFFFD700);

  @override
  Widget build(BuildContext context) {
    final textPrimary = isDark ? Colors.white : Colors.black;
    final muted = (isDark ? Colors.white : Colors.black).withValues(alpha: 0.5);
    final card = isDark ? Colors.white.withValues(alpha: 0.03) : Colors.white;
    final border = isDark
        ? Colors.white.withValues(alpha: 0.08)
        : Colors.black.withValues(alpha: 0.06);

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
              Icon(icon, size: 11, color: _gold.withValues(alpha: 0.7)),
              const SizedBox(width: 6),
              Flexible(
                child: Text(
                  label,
                  overflow: TextOverflow.ellipsis,
                  style: GoogleFonts.montserrat(
                    fontSize: 7,
                    fontWeight: FontWeight.w800,
                    color: muted,
                    letterSpacing: 1.5,
                  ),
                ),
              ),
            ],
          ),
          const SizedBox(height: 6),
          Text(
            value,
            maxLines: 1,
            overflow: TextOverflow.ellipsis,
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
