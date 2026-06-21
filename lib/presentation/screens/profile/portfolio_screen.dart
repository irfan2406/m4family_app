import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:lucide_icons/lucide_icons.dart';
import 'package:cached_network_image/cached_network_image.dart';
import 'package:go_router/go_router.dart';
import 'package:intl/intl.dart';
import 'package:m4_mobile/core/theme/app_theme.dart';
import 'package:m4_mobile/presentation/providers/auth_provider.dart';

/// PORTFOLIO — "MY INVESTMENTS" summary of the user's property holdings.
///
/// Mirrors the web prototype `app/(user)/profile/portfolio/page.tsx`:
///  - Header: PORTFOLIO / MY INVESTMENTS
///  - Summary card: Total Assets (count) + Combined Value
///  - CURRENT HOLDINGS: image card per holding with ID + status badges,
///    project name, location, unit/asset rows, and a VIEW SPECIFICATIONS
///    action that opens a specifications sheet.
///
/// Data is fetched live via `getUserBookings()` (same source as MyPropertyScreen)
/// but presented in the gallery/holdings layout of the web portfolio page.
class PortfolioScreen extends ConsumerStatefulWidget {
  const PortfolioScreen({super.key});

  @override
  ConsumerState<PortfolioScreen> createState() => _PortfolioScreenState();
}

class _PortfolioScreenState extends ConsumerState<PortfolioScreen> {
  static const Color _gold = Color(0xFFFFD700);

  bool _isLoading = true;
  bool _hasError = false;
  List<dynamic> _holdings = [];
  double _combinedValue = 0;

  @override
  void initState() {
    super.initState();
    _fetchPortfolio();
  }

  Future<void> _fetchPortfolio() async {
    if (mounted) {
      setState(() {
        _isLoading = true;
        _hasError = false;
      });
    }
    try {
      final apiClient = ref.read(apiClientProvider);
      final res = await apiClient.getUserBookings();
      if (res.data['status'] == true) {
        final List<dynamic> data = res.data['data'] ?? [];
        // Holdings = actual property reservations/bookings (exclude pure site visits).
        final holdings = data
            .where((b) =>
                b['type'] == 'Token Reservation' ||
                b['type'] == 'Booking Confirmation')
            .toList();
        final combined = holdings.fold<double>(0, (sum, b) {
          final raw = (b['amount'] ?? '').toString();
          final digits = raw.replaceAll(RegExp(r'[^0-9]'), '');
          return sum + (double.tryParse(digits) ?? 0);
        });
        if (mounted) {
          setState(() {
            _holdings = holdings;
            _combinedValue = combined;
          });
        }
      } else if (mounted) {
        setState(() => _hasError = true);
      }
    } catch (e) {
      debugPrint('Error fetching portfolio: $e');
      if (mounted) setState(() => _hasError = true);
    } finally {
      if (mounted) setState(() => _isLoading = false);
    }
  }

  void _goBack() {
    if (context.canPop()) {
      context.pop();
    } else {
      context.go('/profile');
    }
  }

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final bg = isDark ? Colors.black : Colors.white;

    return Scaffold(
      backgroundColor: bg,
      body: SafeArea(
        child: Column(
          children: [
            _buildHeader(isDark),
            Expanded(child: _buildBody(isDark)),
          ],
        ),
      ),
    );
  }

  // ─── Header ────────────────────────────────────────────────────────────────
  Widget _buildHeader(bool isDark) {
    final textPrimary = isDark ? Colors.white : Colors.black;
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
          _PressableScale(
            onTap: _goBack,
            child: Container(
              width: 44,
              height: 44,
              decoration: BoxDecoration(
                color: isDark
                    ? Colors.white.withValues(alpha: 0.03)
                    : Colors.white,
                borderRadius: BorderRadius.circular(14),
                border: Border.all(color: border),
              ),
              child: Icon(LucideIcons.arrowLeft,
                  size: 20,
                  color: textPrimary.withValues(alpha: 0.6)),
            ),
          ),
          const SizedBox(width: 16),
          Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                'PORTFOLIO',
                style: GoogleFonts.montserrat(
                  fontSize: 20,
                  fontWeight: FontWeight.w800,
                  color: textPrimary,
                  letterSpacing: 0.5,
                  height: 1,
                ),
              ),
              const SizedBox(height: 6),
              Text(
                'MY INVESTMENTS',
                style: GoogleFonts.montserrat(
                  fontSize: 8,
                  fontWeight: FontWeight.w700,
                  color: M4Theme.premiumBlue.withValues(alpha: 0.6),
                  letterSpacing: 3,
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }

  // ─── Body states ─────────────────────────────────────────────────────────────
  Widget _buildBody(bool isDark) {
    if (_isLoading) {
      return const Center(
        child: CircularProgressIndicator(color: M4Theme.premiumBlue),
      );
    }
    if (_hasError) {
      return _buildErrorState(isDark);
    }

    return RefreshIndicator(
      color: M4Theme.premiumBlue,
      onRefresh: _fetchPortfolio,
      child: SingleChildScrollView(
        physics: const AlwaysScrollableScrollPhysics(
            parent: BouncingScrollPhysics()),
        padding: const EdgeInsets.fromLTRB(24, 24, 24, 120),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            _buildSummaryCard(isDark),
            const SizedBox(height: 28),
            Padding(
              padding: const EdgeInsets.only(left: 4, bottom: 16),
              child: Text(
                'CURRENT HOLDINGS',
                style: GoogleFonts.montserrat(
                  fontSize: 9,
                  fontWeight: FontWeight.w700,
                  color: (isDark ? Colors.white : Colors.black)
                      .withValues(alpha: 0.5),
                  letterSpacing: 3,
                ),
              ),
            ),
            if (_holdings.isEmpty)
              _buildEmptyState(isDark)
            else
              ..._holdings.map((h) => _buildHoldingCard(h, isDark)),
          ],
        ),
      ),
    );
  }

  // ─── Summary card ────────────────────────────────────────────────────────────
  Widget _buildSummaryCard(bool isDark) {
    final textPrimary = isDark ? Colors.white : Colors.black;
    final muted = textPrimary.withValues(alpha: 0.5);
    final card = isDark ? Colors.white.withValues(alpha: 0.03) : Colors.white;
    final border = isDark
        ? Colors.white.withValues(alpha: 0.08)
        : Colors.black.withValues(alpha: 0.06);

    final count = _holdings.length.toString().padLeft(2, '0');

    return Container(
      padding: const EdgeInsets.all(24),
      decoration: BoxDecoration(
        color: card,
        borderRadius: BorderRadius.circular(28),
        border: Border.all(color: border),
        boxShadow: isDark
            ? null
            : [
                BoxShadow(
                  color: Colors.black.withValues(alpha: 0.05),
                  blurRadius: 20,
                  offset: const Offset(0, 10),
                ),
              ],
      ),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  'TOTAL ASSETS',
                  style: GoogleFonts.montserrat(
                    fontSize: 9,
                    fontWeight: FontWeight.w700,
                    color: muted,
                    letterSpacing: 1.5,
                  ),
                ),
                const SizedBox(height: 8),
                RichText(
                  text: TextSpan(
                    text: count,
                    style: GoogleFonts.montserrat(
                      fontSize: 24,
                      fontWeight: FontWeight.w800,
                      color: textPrimary,
                      letterSpacing: -0.5,
                    ),
                    children: [
                      TextSpan(
                        text: '  PROPERTIES',
                        style: GoogleFonts.montserrat(
                          fontSize: 11,
                          fontWeight: FontWeight.w500,
                          color: muted,
                          letterSpacing: 0,
                        ),
                      ),
                    ],
                  ),
                ),
              ],
            ),
          ),
          Column(
            crossAxisAlignment: CrossAxisAlignment.end,
            children: [
              Text(
                'COMBINED VALUE',
                style: GoogleFonts.montserrat(
                  fontSize: 9,
                  fontWeight: FontWeight.w700,
                  color: muted,
                  letterSpacing: 1.5,
                ),
              ),
              const SizedBox(height: 8),
              Text(
                _formatValue(_combinedValue),
                style: GoogleFonts.montserrat(
                  fontSize: 20,
                  fontWeight: FontWeight.w800,
                  color: _gold,
                  letterSpacing: -0.5,
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }

  // ─── Holding card ────────────────────────────────────────────────────────────
  Widget _buildHoldingCard(dynamic holding, bool isDark) {
    final textPrimary = isDark ? Colors.white : Colors.black;
    final muted = textPrimary.withValues(alpha: 0.5);
    final card = isDark ? Colors.white.withValues(alpha: 0.03) : Colors.white;
    final border = isDark
        ? Colors.white.withValues(alpha: 0.08)
        : Colors.black.withValues(alpha: 0.06);

    final project = holding['project'] ?? {};
    final name = (project['title'] ?? 'Unknown Project').toString();
    final location =
        (project['location']?['name'] ?? 'Developing Area').toString();
    final id = (holding['id'] ?? holding['_id'] ?? '—').toString();
    final shortId = id.length > 8 ? id.substring(id.length - 8) : id;
    final status = (holding['status'] ?? 'In Progress').toString();
    final unit = (holding['unitNumber'] ?? 'N/A').toString();
    final floor = (holding['floor'] ?? 'PENDING').toString();
    final assetType = (holding['configuration'] ?? 'PREMIUM BHK').toString();
    final imageUrl = _firstImage(project);

    return Container(
      margin: const EdgeInsets.only(bottom: 20),
      decoration: BoxDecoration(
        color: card,
        borderRadius: BorderRadius.circular(36),
        border: Border.all(color: border),
        boxShadow: isDark
            ? null
            : [
                BoxShadow(
                  color: Colors.black.withValues(alpha: 0.05),
                  blurRadius: 20,
                  offset: const Offset(0, 10),
                ),
              ],
      ),
      child: ClipRRect(
        borderRadius: BorderRadius.circular(36),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Image header with ID + status badges
            SizedBox(
              height: 180,
              width: double.infinity,
              child: Stack(
                fit: StackFit.expand,
                children: [
                  _buildImage(imageUrl, isDark),
                  // bottom fade for legibility
                  Positioned(
                    left: 0,
                    right: 0,
                    bottom: 0,
                    height: 90,
                    child: Container(
                      decoration: BoxDecoration(
                        gradient: LinearGradient(
                          begin: Alignment.topCenter,
                          end: Alignment.bottomCenter,
                          colors: [
                            Colors.transparent,
                            (isDark ? Colors.black : Colors.white)
                                .withValues(alpha: 0.9),
                          ],
                        ),
                      ),
                    ),
                  ),
                  Positioned(
                    left: 16,
                    right: 16,
                    top: 16,
                    child: Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        _Pill(
                          text: 'ID: $shortId',
                          bg: Colors.black.withValues(alpha: 0.6),
                          fg: Colors.white,
                        ),
                        _StatusPill(status: status),
                      ],
                    ),
                  ),
                ],
              ),
            ),
            Padding(
              padding: const EdgeInsets.fromLTRB(24, 16, 24, 24),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    name.toUpperCase(),
                    style: GoogleFonts.montserrat(
                      fontSize: 18,
                      fontWeight: FontWeight.w800,
                      color: textPrimary,
                      letterSpacing: -0.2,
                    ),
                  ),
                  const SizedBox(height: 6),
                  Row(
                    children: [
                      Icon(LucideIcons.mapPin,
                          size: 12, color: M4Theme.premiumBlue.withValues(alpha: 0.6)),
                      const SizedBox(width: 6),
                      Expanded(
                        child: Text(
                          location.toUpperCase(),
                          style: GoogleFonts.montserrat(
                            fontSize: 9,
                            fontWeight: FontWeight.w700,
                            color: muted,
                            letterSpacing: 0.5,
                          ),
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 16),
                  Container(
                    padding: const EdgeInsets.symmetric(vertical: 16),
                    decoration: BoxDecoration(
                      border: Border(
                        top: BorderSide(color: border),
                        bottom: BorderSide(color: border),
                      ),
                    ),
                    child: Row(
                      children: [
                        Expanded(
                          child: _DetailItem(
                            label: 'UNIT DETAILS',
                            value: '$unit • $floor',
                            muted: muted,
                            textPrimary: textPrimary,
                          ),
                        ),
                        Expanded(
                          child: _DetailItem(
                            label: 'ASSET TYPE',
                            value: assetType,
                            muted: muted,
                            textPrimary: textPrimary,
                            alignEnd: true,
                          ),
                        ),
                      ],
                    ),
                  ),
                  const SizedBox(height: 16),
                  _PressableScale(
                    onTap: () => _showSpecifications(holding, isDark),
                    child: Container(
                      height: 48,
                      alignment: Alignment.center,
                      decoration: BoxDecoration(
                        color: textPrimary,
                        borderRadius: BorderRadius.circular(16),
                      ),
                      child: Row(
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: [
                          Text(
                            'VIEW SPECIFICATIONS',
                            style: GoogleFonts.montserrat(
                              fontSize: 9,
                              fontWeight: FontWeight.w800,
                              color: isDark ? Colors.black : Colors.white,
                              letterSpacing: 2,
                            ),
                          ),
                          const SizedBox(width: 8),
                          Icon(LucideIcons.maximize2,
                              size: 14,
                              color: isDark ? Colors.black : Colors.white),
                        ],
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

  Widget _buildImage(String? url, bool isDark) {
    final placeholderBg = (isDark ? Colors.white : Colors.black)
        .withValues(alpha: 0.05);
    if (url == null || url.isEmpty) {
      return Container(
        color: placeholderBg,
        child: Icon(LucideIcons.building2,
            size: 48,
            color: (isDark ? Colors.white : Colors.black)
                .withValues(alpha: 0.15)),
      );
    }
    final apiClient = ref.read(apiClientProvider);
    return CachedNetworkImage(
      imageUrl: apiClient.resolveUrl(url),
      fit: BoxFit.cover,
      placeholder: (context, _) => Container(color: placeholderBg),
      errorWidget: (context, _, __) => Container(
        color: placeholderBg,
        child: Icon(LucideIcons.building2,
            size: 48,
            color: (isDark ? Colors.white : Colors.black)
                .withValues(alpha: 0.15)),
      ),
    );
  }

  // ─── Specifications sheet ─────────────────────────────────────────────────────
  void _showSpecifications(dynamic holding, bool isDark) {
    final project = holding['project'] ?? {};
    final name = (project['title'] ?? 'Unknown Project').toString();
    final unit = (holding['unitNumber'] ?? 'N/A').toString();
    final floor = (holding['floor'] ?? 'PENDING').toString();
    final area = (holding['area'] ?? holding['carpetArea'] ?? '—').toString();
    final facing = (holding['facing'] ?? '—').toString();
    final possession =
        (holding['possession'] ?? project['possession'] ?? '—').toString();
    final imageUrl = _firstImage(project);

    final textPrimary = isDark ? Colors.white : Colors.black;
    final muted = textPrimary.withValues(alpha: 0.5);
    final sheetBg = isDark ? const Color(0xFF0A0A0A) : Colors.white;
    final border = isDark
        ? Colors.white.withValues(alpha: 0.08)
        : Colors.black.withValues(alpha: 0.06);

    showModalBottomSheet(
      context: context,
      backgroundColor: Colors.transparent,
      isScrollControlled: true,
      builder: (sheetContext) {
        return Container(
          constraints: BoxConstraints(
            maxHeight: MediaQuery.of(sheetContext).size.height * 0.85,
          ),
          decoration: BoxDecoration(
            color: sheetBg,
            borderRadius: const BorderRadius.vertical(top: Radius.circular(36)),
            border: Border.all(color: border),
          ),
          child: ClipRRect(
            borderRadius:
                const BorderRadius.vertical(top: Radius.circular(36)),
            child: SingleChildScrollView(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  SizedBox(
                    height: 180,
                    width: double.infinity,
                    child: Stack(
                      fit: StackFit.expand,
                      children: [
                        _buildImage(imageUrl, isDark),
                        Positioned(
                          left: 0,
                          right: 0,
                          bottom: 0,
                          height: 120,
                          child: Container(
                            decoration: BoxDecoration(
                              gradient: LinearGradient(
                                begin: Alignment.topCenter,
                                end: Alignment.bottomCenter,
                                colors: [
                                  Colors.transparent,
                                  sheetBg.withValues(alpha: 0.95),
                                ],
                              ),
                            ),
                          ),
                        ),
                        Positioned(
                          left: 24,
                          right: 24,
                          bottom: 20,
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Text(
                                name.toUpperCase(),
                                style: GoogleFonts.montserrat(
                                  fontSize: 22,
                                  fontWeight: FontWeight.w800,
                                  color: textPrimary,
                                  letterSpacing: -0.3,
                                ),
                              ),
                              const SizedBox(height: 6),
                              Text(
                                'UNIT $unit SPECIFICATIONS',
                                style: GoogleFonts.montserrat(
                                  fontSize: 9,
                                  fontWeight: FontWeight.w700,
                                  color: M4Theme.premiumBlue
                                      .withValues(alpha: 0.7),
                                  letterSpacing: 2,
                                ),
                              ),
                            ],
                          ),
                        ),
                      ],
                    ),
                  ),
                  Padding(
                    padding: const EdgeInsets.all(24),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Row(
                          children: [
                            Expanded(
                              child: _SpecItem(
                                icon: LucideIcons.layers,
                                label: 'FLOOR LEVEL',
                                value: floor,
                                muted: muted,
                                textPrimary: textPrimary,
                              ),
                            ),
                            Expanded(
                              child: _SpecItem(
                                icon: LucideIcons.maximize2,
                                label: 'DIMENSION',
                                value: area,
                                muted: muted,
                                textPrimary: textPrimary,
                              ),
                            ),
                          ],
                        ),
                        const SizedBox(height: 24),
                        Row(
                          children: [
                            Expanded(
                              child: _SpecItem(
                                icon: LucideIcons.compass,
                                label: 'ORIENTATION',
                                value: facing,
                                muted: muted,
                                textPrimary: textPrimary,
                              ),
                            ),
                            Expanded(
                              child: _SpecItem(
                                icon: LucideIcons.calendar,
                                label: 'POSSESSION',
                                value: possession,
                                muted: muted,
                                textPrimary: textPrimary,
                              ),
                            ),
                          ],
                        ),
                        const SizedBox(height: 24),
                        Container(height: 1, color: border),
                        const SizedBox(height: 24),
                        _PressableScale(
                          onTap: () => Navigator.of(sheetContext).pop(),
                          child: Container(
                            height: 48,
                            alignment: Alignment.center,
                            decoration: BoxDecoration(
                              color: textPrimary,
                              borderRadius: BorderRadius.circular(16),
                            ),
                            child: Row(
                              mainAxisAlignment: MainAxisAlignment.center,
                              children: [
                                Icon(LucideIcons.shieldCheck,
                                    size: 16,
                                    color:
                                        isDark ? Colors.black : Colors.white),
                                const SizedBox(width: 8),
                                Text(
                                  'VERIFIED PROPERTY',
                                  style: GoogleFonts.montserrat(
                                    fontSize: 9,
                                    fontWeight: FontWeight.w800,
                                    color:
                                        isDark ? Colors.black : Colors.white,
                                    letterSpacing: 2,
                                  ),
                                ),
                              ],
                            ),
                          ),
                        ),
                        const SizedBox(height: 16),
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
  }

  // ─── Empty / error states ────────────────────────────────────────────────────
  Widget _buildEmptyState(bool isDark) {
    final faint = (isDark ? Colors.white : Colors.black).withValues(alpha: 0.2);
    return Padding(
      padding: const EdgeInsets.only(top: 48),
      child: Center(
        child: Column(
          children: [
            Icon(LucideIcons.building2, size: 56, color: faint),
            const SizedBox(height: 20),
            Text(
              'NO HOLDINGS YET',
              style: GoogleFonts.montserrat(
                fontSize: 11,
                fontWeight: FontWeight.w800,
                color: faint,
                letterSpacing: 2,
              ),
            ),
            const SizedBox(height: 8),
            Text(
              'Your acquired properties will appear here.',
              style: GoogleFonts.montserrat(
                fontSize: 11,
                fontWeight: FontWeight.w500,
                color: (isDark ? Colors.white : Colors.black)
                    .withValues(alpha: 0.35),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildErrorState(bool isDark) {
    final textPrimary = isDark ? Colors.white : Colors.black;
    final muted = textPrimary.withValues(alpha: 0.5);
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(32),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(LucideIcons.alertTriangle,
                size: 48, color: muted),
            const SizedBox(height: 20),
            Text(
              'UNABLE TO LOAD PORTFOLIO',
              style: GoogleFonts.montserrat(
                fontSize: 11,
                fontWeight: FontWeight.w800,
                color: muted,
                letterSpacing: 2,
              ),
            ),
            const SizedBox(height: 20),
            _PressableScale(
              onTap: _fetchPortfolio,
              child: Container(
                padding:
                    const EdgeInsets.symmetric(horizontal: 24, vertical: 12),
                decoration: BoxDecoration(
                  color: textPrimary,
                  borderRadius: BorderRadius.circular(14),
                ),
                child: Text(
                  'RETRY',
                  style: GoogleFonts.montserrat(
                    fontSize: 10,
                    fontWeight: FontWeight.w800,
                    color: isDark ? Colors.black : Colors.white,
                    letterSpacing: 2,
                  ),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  // ─── Helpers ────────────────────────────────────────────────────────────────
  String? _firstImage(dynamic project) {
    if (project == null) return null;
    final candidates = [
      project['coverImage'],
      project['image'],
      project['thumbnail'],
    ];
    for (final c in candidates) {
      if (c is String && c.isNotEmpty) return c;
    }
    final images = project['images'];
    if (images is List && images.isNotEmpty) {
      final first = images.first;
      if (first is String && first.isNotEmpty) return first;
      if (first is Map && first['url'] is String) return first['url'] as String;
    }
    return null;
  }

  String _formatValue(double value) {
    if (value <= 0) return 'AED --';
    // Indian-style grouping to match web ("₹" prototype) but keep AED currency
    // used elsewhere in the app's booking amounts.
    return 'AED ${NumberFormat('#,##,###').format(value)}';
  }
}

// ─── Reusable widgets ──────────────────────────────────────────────────────────

class _PressableScale extends StatefulWidget {
  final Widget child;
  final VoidCallback onTap;
  const _PressableScale({required this.child, required this.onTap});

  @override
  State<_PressableScale> createState() => _PressableScaleState();
}

class _PressableScaleState extends State<_PressableScale> {
  bool _pressed = false;

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: widget.onTap,
      onTapDown: (_) => setState(() => _pressed = true),
      onTapUp: (_) => setState(() => _pressed = false),
      onTapCancel: () => setState(() => _pressed = false),
      child: AnimatedScale(
        scale: _pressed ? 0.97 : 1.0,
        duration: const Duration(milliseconds: 120),
        curve: Curves.easeOut,
        child: widget.child,
      ),
    );
  }
}

class _Pill extends StatelessWidget {
  final String text;
  final Color bg;
  final Color fg;
  const _Pill({required this.text, required this.bg, required this.fg});

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 5),
      decoration: BoxDecoration(
        color: bg,
        borderRadius: BorderRadius.circular(10),
      ),
      child: Text(
        text.toUpperCase(),
        style: GoogleFonts.montserrat(
          fontSize: 8,
          fontWeight: FontWeight.w800,
          color: fg,
          letterSpacing: 1.5,
        ),
      ),
    );
  }
}

class _StatusPill extends StatelessWidget {
  final String status;
  const _StatusPill({required this.status});

  @override
  Widget build(BuildContext context) {
    final ready = status.toLowerCase().contains('ready') ||
        status.toLowerCase().contains('confirmed') ||
        status.toLowerCase().contains('move');
    final color = ready ? const Color(0xFF22C55E) : const Color(0xFFF59E0B);
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 5),
      decoration: BoxDecoration(
        color: color.withValues(alpha: 0.2),
        borderRadius: BorderRadius.circular(10),
        border: Border.all(color: color.withValues(alpha: 0.25)),
      ),
      child: Text(
        status.toUpperCase(),
        style: GoogleFonts.montserrat(
          fontSize: 8,
          fontWeight: FontWeight.w800,
          color: color,
          letterSpacing: 1.5,
        ),
      ),
    );
  }
}

class _DetailItem extends StatelessWidget {
  final String label;
  final String value;
  final Color muted;
  final Color textPrimary;
  final bool alignEnd;
  const _DetailItem({
    required this.label,
    required this.value,
    required this.muted,
    required this.textPrimary,
    this.alignEnd = false,
  });

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment:
          alignEnd ? CrossAxisAlignment.end : CrossAxisAlignment.start,
      children: [
        Text(
          label,
          style: GoogleFonts.montserrat(
            fontSize: 8,
            fontWeight: FontWeight.w700,
            color: muted,
            letterSpacing: 1.5,
          ),
        ),
        const SizedBox(height: 6),
        Text(
          value.toUpperCase(),
          textAlign: alignEnd ? TextAlign.right : TextAlign.left,
          style: GoogleFonts.montserrat(
            fontSize: 11,
            fontWeight: FontWeight.w800,
            fontStyle: FontStyle.italic,
            color: textPrimary,
          ),
        ),
      ],
    );
  }
}

class _SpecItem extends StatelessWidget {
  final IconData icon;
  final String label;
  final String value;
  final Color muted;
  final Color textPrimary;
  const _SpecItem({
    required this.icon,
    required this.label,
    required this.value,
    required this.muted,
    required this.textPrimary,
  });

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          children: [
            Icon(icon, size: 12, color: muted),
            const SizedBox(width: 6),
            Expanded(
              child: Text(
                label,
                style: GoogleFonts.montserrat(
                  fontSize: 8,
                  fontWeight: FontWeight.w700,
                  color: muted,
                  letterSpacing: 1.5,
                ),
              ),
            ),
          ],
        ),
        const SizedBox(height: 8),
        Text(
          value.toUpperCase(),
          style: GoogleFonts.montserrat(
            fontSize: 12,
            fontWeight: FontWeight.w800,
            color: textPrimary,
          ),
        ),
      ],
    );
  }
}
