import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:lucide_icons/lucide_icons.dart';
import 'package:cached_network_image/cached_network_image.dart';
import 'package:go_router/go_router.dart';
import 'package:intl/intl.dart';
import 'package:m4_mobile/core/theme/app_theme.dart';
import 'package:m4_mobile/presentation/providers/auth_provider.dart';
import 'package:m4_mobile/presentation/widgets/ios/ios_sheets.dart';

/// INVESTOR PORTFOLIO — "MY INVESTMENTS" holdings dashboard.
///
/// Stakes are recorded in square feet: each holding carries a `squareFeet`
/// figure and the screen reports AREA (per stake) and TOTAL AREA (aggregate).
/// Amount / current value / equity share are no longer recorded for stakes,
/// so no money figures are rendered here and privacy masking isn't needed.
///
/// Structure:
///  - Header: PORTFOLIO
///  - Summary card: total area + active holdings count
///  - Performance strip: avg yield (only when the server still supplies one)
///  - Allocation breakdown by project (area share)
///  - INVESTMENT BREAKDOWN: image card per holding with project, location,
///    area, units/stake, status, and a VIEW PERFORMANCE sheet.
///
/// Data is fetched live from `GET /api/investor/holdings`
/// (`apiClient.getInvestorHoldings()`), falling back to the legacy
/// `GET /api/investor/portfolio` so the screen never breaks. Response shapes
/// are parsed defensively (bare list, `{status, data}`, or `data.holdings`).
class InvestorPortfolioScreen extends ConsumerStatefulWidget {
  const InvestorPortfolioScreen({super.key});

  @override
  ConsumerState<InvestorPortfolioScreen> createState() =>
      _InvestorPortfolioScreenState();
}

class _InvestorPortfolioScreenState
    extends ConsumerState<InvestorPortfolioScreen> {
  static const Color _gold = Color(0xFFC5A35B);
  static const Color _green = Color(0xFF163A2C);
  static const Color _amber = Color(0xFFC5A35B);

  bool _isLoading = true;
  bool _hasError = false;

  List<dynamic> _holdings = [];
  double _totalArea = 0;
  Map<String, dynamic>? _summary;

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
      List<dynamic>? holdings;
      Map<String, dynamic>? summary;

      // Stakes are denominated in square feet, so the holdings endpoint is
      // the source of truth. The legacy portfolio endpoint stays as a
      // fallback so the screen still renders if the new one is missing,
      // failing, or returns nothing list-shaped.
      try {
        final res = await apiClient.getInvestorHoldings();
        final parsed = _parseHoldingsBody(res.data);
        holdings = parsed.holdings;
        summary = parsed.summary;
      } catch (e) {
        debugPrint('Error fetching investor holdings: $e');
      }

      if (holdings == null) {
        final res = await apiClient.getInvestorPortfolio();
        final parsed = _parseHoldingsBody(res.data);
        holdings = parsed.holdings;
        summary = parsed.summary;
      }

      if (holdings == null) {
        if (mounted) setState(() => _hasError = true);
        return;
      }

      // Prefer a server-reported total; otherwise sum the stakes ourselves.
      final summedArea = holdings.fold<double>(
        0,
        (sum, h) => sum + _squareFeet(h),
      );
      final serverArea = _num(summary, [
        'totalArea',
        'totalSquareFeet',
        'totalSqft',
      ]);

      if (mounted) {
        setState(() {
          _holdings = holdings!;
          _summary = summary;
          _totalArea = serverArea > 0 ? serverArea : summedArea;
        });
      }
    } catch (e) {
      debugPrint('Error fetching investor portfolio: $e');
      if (mounted) setState(() => _hasError = true);
    } finally {
      if (mounted) setState(() => _isLoading = false);
    }
  }

  void _goBack() {
    if (context.canPop()) {
      context.pop();
    } else {
      context.go('/investor/home');
    }
  }

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final bg = isDark ? Colors.black : const Color(0xFFD4CFBC);

    return Scaffold(
      backgroundColor: bg,
      body: SafeArea(
        // Edge-to-edge: content runs under the gesture bar so scrolling fills
        // the screen. Trailing padding keeps the last item reachable.
        bottom: false,
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
    final textPrimary = isDark ? Colors.white : const Color(0xFF0C312B);
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
                    : const Color(0xFFF4EFE3),
                borderRadius: BorderRadius.circular(14),
                border: Border.all(color: border),
              ),
              child: Icon(
                LucideIcons.arrowLeft,
                size: 20,
                color: textPrimary.withValues(alpha: 0.6),
              ),
            ),
          ),
          const SizedBox(width: 16),
          Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                'PORTFOLIO',
                style: GoogleFonts.gelasio(
                  fontSize: 20,
                  fontWeight: FontWeight.w700,
                  color: textPrimary,
                  letterSpacing: 0.5,
                  height: 1,
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
      return Center(
        child: CircularProgressIndicator.adaptive(
          valueColor: AlwaysStoppedAnimation<Color>(
            M4Theme.loaderGreen(context),
          ),
        ),
      );
    }
    if (_hasError) {
      return _buildErrorState(isDark);
    }

    return RefreshIndicator.adaptive(
      color: M4Theme.loaderGreen(context),
      onRefresh: _fetchPortfolio,
      child: SingleChildScrollView(
        physics: const AlwaysScrollableScrollPhysics(
          parent: BouncingScrollPhysics(),
        ),
        padding: const EdgeInsets.fromLTRB(24, 24, 24, 120),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Web parity: with nothing allotted yet the page is just the
            // invitation to explore. The area card, performance tile and
            // breakdown only appear once there are real holdings to report.
            if (_holdings.isEmpty)
              _buildEmptyState(isDark)
            else ...[
              _buildSummaryCard(isDark),
              // Yield is the only performance metric still supplied for
              // stakes; hide the strip entirely when the server omits it.
              if (_avgYield != null) ...[
                const SizedBox(height: 16),
                _buildPerformanceStrip(isDark),
              ],
              const SizedBox(height: 28),
              _sectionLabel('AREA ALLOCATION', isDark),
              const SizedBox(height: 16),
              _buildAllocationCard(isDark),
              const SizedBox(height: 28),
              _sectionLabel('INVESTMENT BREAKDOWN', isDark),
              const SizedBox(height: 16),
              ..._holdings.map((h) => _buildHoldingCard(h, isDark)),
            ],
          ],
        ),
      ),
    );
  }

  Widget _sectionLabel(String text, bool isDark) {
    return Padding(
      padding: const EdgeInsets.only(left: 4),
      child: Text(
        text,
        style: GoogleFonts.gelasio(
          fontSize: 11,
          fontWeight: FontWeight.w700,
          color: (isDark ? Colors.white : const Color(0xFF0C312B)).withValues(
            alpha: 0.5,
          ),
          letterSpacing: 3,
        ),
      ),
    );
  }

  // ─── Summary card ────────────────────────────────────────────────────────────
  Widget _buildSummaryCard(bool isDark) {
    final muted = (isDark ? Colors.white : const Color(0xFF0C312B)).withValues(
      alpha: 0.5,
    );

    final count = _holdings.length.toString().padLeft(2, '0');

    return Container(
      padding: const EdgeInsets.all(24),
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(28),
        gradient: const LinearGradient(
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
          colors: [Color(0xFF141B3A), Color(0xFF141B3A)],
        ),
        border: Border.all(color: _gold.withValues(alpha: 0.25)),
        boxShadow: [
          BoxShadow(
            color: _gold.withValues(alpha: 0.08),
            blurRadius: 30,
            offset: const Offset(0, 12),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              const Icon(LucideIcons.crown, size: 16, color: _gold),
              const SizedBox(width: 8),
              Text(
                'PORTFOLIO AREA',
                style: GoogleFonts.gelasio(
                  fontSize: 11,
                  fontWeight: FontWeight.w700,
                  letterSpacing: 2.5,
                  color: Colors.white.withValues(alpha: 0.6),
                ),
              ),
            ],
          ),
          const SizedBox(height: 20),
          // Flexible keeps the grouped figure on one line on narrow screens.
          Row(
            crossAxisAlignment: CrossAxisAlignment.end,
            children: [
              Flexible(
                child: Text(
                  _formatArea(_totalArea),
                  style: GoogleFonts.gelasio(
                    fontSize: 32,
                    fontWeight: FontWeight.w700,
                    color: const Color(0xFFF4EFE3),
                    height: 1.0,
                    letterSpacing: -1,
                  ),
                ),
              ),
            ],
          ),
          const SizedBox(height: 6),
          Text(
            'TOTAL AREA',
            style: GoogleFonts.gelasio(
              fontSize: 11,
              fontWeight: FontWeight.w700,
              letterSpacing: 2,
              color: Colors.white.withValues(alpha: 0.72),
            ),
          ),
          const SizedBox(height: 22),
          Row(
            children: [
              Expanded(
                child: _summaryStat(
                  'ACTIVE HOLDINGS',
                  '$count ${_holdings.length == 1 ? "ASSET" : "ASSETS"}',
                  valueColor: _gold,
                  muted: muted,
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _summaryStat(
    String label,
    String value, {
    required Color valueColor,
    Color? muted,
  }) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          label,
          style: GoogleFonts.gelasio(
            fontSize: 10,
            fontWeight: FontWeight.w700,
            letterSpacing: 1.5,
            color: Colors.white.withValues(alpha: 0.72),
          ),
        ),
        const SizedBox(height: 6),
        Text(
          value,
          style: GoogleFonts.inter(
            fontSize: 16,
            fontWeight: FontWeight.w600,
            color: valueColor,
          ),
        ),
      ],
    );
  }

  // ─── Performance strip ───────────────────────────────────────────────────────
  // Yield is the only performance metric still reported for stakes, so the
  // strip is a single AVG YIELD tile (the strip itself is only built when
  // [_avgYield] is non-null).
  Widget _buildPerformanceStrip(bool isDark) {
    return Row(
      children: [
        Expanded(
          child: _metricTile(
            isDark,
            icon: LucideIcons.percent,
            label: 'AVG YIELD',
            value: _avgYield ?? '—',
            accent: M4Theme.premiumBlue,
          ),
        ),
      ],
    );
  }

  Widget _metricTile(
    bool isDark, {
    required IconData icon,
    required String label,
    required String value,
    required Color accent,
  }) {
    final textPrimary = isDark ? Colors.white : const Color(0xFF0C312B);
    final muted = textPrimary.withValues(alpha: 0.5);
    final card = isDark
        ? Colors.white.withValues(alpha: 0.03)
        : const Color(0xFFF4EFE3);
    final border = isDark
        ? Colors.white.withValues(alpha: 0.08)
        : Colors.black.withValues(alpha: 0.06);

    return Container(
      padding: const EdgeInsets.all(18),
      decoration: BoxDecoration(
        color: card,
        borderRadius: BorderRadius.circular(24),
        border: Border.all(color: border),
        boxShadow: isDark
            ? null
            : [
                BoxShadow(
                  color: Colors.black.withValues(alpha: 0.04),
                  blurRadius: 16,
                  offset: const Offset(0, 8),
                ),
              ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Container(
            width: 36,
            height: 36,
            decoration: BoxDecoration(
              shape: BoxShape.circle,
              color: accent.withValues(alpha: 0.12),
            ),
            child: Icon(icon, size: 16, color: accent),
          ),
          const SizedBox(height: 14),
          Text(
            value,
            maxLines: 1,
            overflow: TextOverflow.ellipsis,
            style: GoogleFonts.inter(
              fontSize: 16,
              fontWeight: FontWeight.w600,
              color: textPrimary,
              letterSpacing: -0.3,
            ),
          ),
          const SizedBox(height: 4),
          Text(
            label,
            style: GoogleFonts.gelasio(
              fontSize: 10,
              fontWeight: FontWeight.w700,
              color: muted,
              letterSpacing: 1.5,
            ),
          ),
        ],
      ),
    );
  }

  // ─── Allocation breakdown ────────────────────────────────────────────────────
  Widget _buildAllocationCard(bool isDark) {
    final textPrimary = isDark ? Colors.white : const Color(0xFF0C312B);
    final muted = textPrimary.withValues(alpha: 0.5);
    final card = isDark
        ? Colors.white.withValues(alpha: 0.03)
        : const Color(0xFFF4EFE3);
    final border = isDark
        ? Colors.white.withValues(alpha: 0.08)
        : Colors.black.withValues(alpha: 0.06);

    // Bar + percentages are weighted by allotted area, not money.
    final total = _holdings.fold<double>(0, (sum, h) => sum + _squareFeet(h));
    final palette = [
      _gold,
      M4Theme.premiumBlue,
      _green,
      const Color(0xFFC5A35B),
      const Color(0xFFC65B46),
      _amber,
    ];

    return Container(
      padding: const EdgeInsets.all(22),
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
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Stacked allocation bar
          ClipRRect(
            borderRadius: BorderRadius.circular(8),
            child: SizedBox(
              height: 10,
              child: Row(
                children: [
                  for (var i = 0; i < _holdings.length; i++)
                    Expanded(
                      flex:
                          ((_squareFeet(_holdings[i]) /
                                      (total <= 0 ? 1 : total)) *
                                  1000)
                              .round()
                              .clamp(1, 1000),
                      child: Container(color: palette[i % palette.length]),
                    ),
                ],
              ),
            ),
          ),
          const SizedBox(height: 20),
          for (var i = 0; i < _holdings.length; i++) ...[
            _allocationRow(
              _holdings[i],
              palette[i % palette.length],
              total,
              textPrimary,
              muted,
            ),
            if (i != _holdings.length - 1) const SizedBox(height: 14),
          ],
        ],
      ),
    );
  }

  Widget _allocationRow(
    dynamic h,
    Color color,
    double total,
    Color textPrimary,
    Color muted,
  ) {
    final name = _projectName(h);
    final area = _squareFeet(h);
    final pct = total <= 0 ? 0.0 : (area / total) * 100;

    return Row(
      children: [
        Container(
          width: 10,
          height: 10,
          decoration: BoxDecoration(shape: BoxShape.circle, color: color),
        ),
        const SizedBox(width: 12),
        Expanded(
          child: Text(
            name.toUpperCase(),
            maxLines: 1,
            overflow: TextOverflow.ellipsis,
            style: GoogleFonts.inter(
              fontSize: 11,
              fontWeight: FontWeight.w500,
              color: textPrimary,
              letterSpacing: 0.2,
            ),
          ),
        ),
        const SizedBox(width: 12),
        // Area share: square footage next to its percentage of the total.
        Flexible(
          child: Text(
            '${_formatArea(area)} · ${pct.toStringAsFixed(0)}%',
            maxLines: 1,
            overflow: TextOverflow.ellipsis,
            style: GoogleFonts.inter(
              fontSize: 11,
              fontWeight: FontWeight.w600,
              color: muted,
            ),
          ),
        ),
      ],
    );
  }

  // ─── Holding card ────────────────────────────────────────────────────────────
  Widget _buildHoldingCard(dynamic holding, bool isDark) {
    final textPrimary = isDark ? Colors.white : const Color(0xFF0C312B);
    final muted = textPrimary.withValues(alpha: 0.5);
    final card = isDark
        ? Colors.white.withValues(alpha: 0.03)
        : const Color(0xFFF4EFE3);
    final border = isDark
        ? Colors.white.withValues(alpha: 0.08)
        : Colors.black.withValues(alpha: 0.06);

    final name = _projectName(holding);
    final location = _location(holding);
    final id = (holding['id'] ?? holding['_id'] ?? '—').toString();
    final shortId = id.length > 8 ? id.substring(id.length - 8) : id;
    final status = (holding['status'] ?? 'Active').toString();
    final units =
        (holding['units'] ??
                holding['unitNumber'] ??
                holding['quantity'] ??
                '—')
            .toString();
    // Stakes are denominated in square feet; absent means not allotted yet.
    final area = _squareFeet(holding);
    final areaText = area > 0 ? _formatArea(area) : '—';
    final imageUrl = _firstImage(holding);

    return Container(
      margin: const EdgeInsets.only(bottom: 20),
      decoration: BoxDecoration(
        color: card,
        borderRadius: BorderRadius.circular(20),
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
        borderRadius: BorderRadius.circular(20),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // 16:9 cover — the ratio every card image uses.
            AspectRatio(
              aspectRatio: 16 / 9,
              child: Stack(
                fit: StackFit.expand,
                children: [
                  _buildImage(imageUrl, isDark),
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
                            (isDark ? Colors.black : const Color(0xFFF4EFE3))
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
                    style: GoogleFonts.gelasio(
                      fontSize: 18,
                      fontWeight: FontWeight.w700,
                      color: textPrimary,
                      letterSpacing: -0.2,
                    ),
                  ),
                  const SizedBox(height: 6),
                  Row(
                    children: [
                      Icon(
                        LucideIcons.mapPin,
                        size: 12,
                        color: M4Theme.premiumBlue.withValues(alpha: 0.6),
                      ),
                      const SizedBox(width: 6),
                      Expanded(
                        child: Text(
                          location.toUpperCase(),
                          style: GoogleFonts.inter(
                            fontSize: 11,
                            fontWeight: FontWeight.w700,
                            color: muted,
                            letterSpacing: 0.5,
                          ),
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 16),
                  // Wrap (not Row) so the items flow onto a second line instead
                  // of overflowing on narrow screens.
                  Container(
                    padding: const EdgeInsets.symmetric(vertical: 16),
                    decoration: BoxDecoration(
                      border: Border(
                        top: BorderSide(color: border),
                        bottom: BorderSide(color: border),
                      ),
                    ),
                    child: Wrap(
                      spacing: 24,
                      runSpacing: 12,
                      children: [
                        _DetailItem(
                          label: 'AREA',
                          value: areaText,
                          muted: muted,
                          textPrimary: textPrimary,
                        ),
                        _DetailItem(
                          label: 'UNITS / STAKE',
                          value: units,
                          muted: muted,
                          textPrimary: textPrimary,
                        ),
                      ],
                    ),
                  ),
                  const SizedBox(height: 16),
                  Row(
                    children: [
                      const Spacer(),
                      _PressableScale(
                        onTap: () => _showPerformance(holding, isDark),
                        child: Container(
                          height: 44,
                          padding: const EdgeInsets.symmetric(horizontal: 18),
                          alignment: Alignment.center,
                          decoration: BoxDecoration(
                            color: textPrimary,
                            borderRadius: BorderRadius.circular(14),
                          ),
                          child: Row(
                            mainAxisSize: MainAxisSize.min,
                            children: [
                              Text(
                                'VIEW PERFORMANCE',
                                style: GoogleFonts.gelasio(
                                  fontSize: 11,
                                  fontWeight: FontWeight.w700,
                                  color: isDark
                                      ? const Color(0xFF0C312B)
                                      : const Color(0xFFF4EFE3),
                                  letterSpacing: 1.5,
                                ),
                              ),
                              const SizedBox(width: 8),
                              Icon(
                                LucideIcons.maximize2,
                                size: 13,
                                color: isDark
                                    ? const Color(0xFF0C312B)
                                    : const Color(0xFFF4EFE3),
                              ),
                            ],
                          ),
                        ),
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

  Widget _buildImage(String? url, bool isDark) {
    final placeholderBg = (isDark ? Colors.white : const Color(0xFF0C312B))
        .withValues(alpha: 0.05);
    if (url == null || url.isEmpty) {
      return Container(
        color: placeholderBg,
        child: Icon(
          LucideIcons.building2,
          size: 48,
          color: (isDark ? Colors.white : const Color(0xFF0C312B)).withValues(
            alpha: 0.15,
          ),
        ),
      );
    }
    final apiClient = ref.read(apiClientProvider);
    return CachedNetworkImage(
      fadeInDuration: Duration.zero,
      fadeOutDuration: Duration.zero,
      memCacheWidth: 1080,
      imageUrl: apiClient.resolveUrl(url),
      fit: BoxFit.cover,
      placeholder: (context, _) => Container(color: placeholderBg),
      errorWidget: (context, _, __) => Container(
        color: placeholderBg,
        child: Icon(
          LucideIcons.building2,
          size: 48,
          color: (isDark ? Colors.white : const Color(0xFF0C312B)).withValues(
            alpha: 0.15,
          ),
        ),
      ),
    );
  }

  // ─── Performance sheet ───────────────────────────────────────────────────────
  void _showPerformance(dynamic holding, bool isDark) {
    final name = _projectName(holding);
    final location = _location(holding);
    final units =
        (holding['units'] ??
                holding['unitNumber'] ??
                holding['quantity'] ??
                '—')
            .toString();
    final area = _squareFeet(holding);
    final areaText = area > 0 ? _formatArea(area) : '—';
    final yieldVal =
        (holding['yield'] ??
                holding['rentalYield'] ??
                holding['annualYield'] ??
                '—')
            .toString();
    final imageUrl = _firstImage(holding);

    final textPrimary = isDark ? Colors.white : const Color(0xFF0C312B);
    final muted = textPrimary.withValues(alpha: 0.5);
    final sheetBg = isDark ? const Color(0xFF141B3A) : const Color(0xFFF4EFE3);
    final border = isDark
        ? Colors.white.withValues(alpha: 0.08)
        : Colors.black.withValues(alpha: 0.06);

    showM4Sheet(
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
            borderRadius: const BorderRadius.vertical(top: Radius.circular(36)),
            child: SingleChildScrollView(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  // 16:9 cover — the ratio every card image uses.
                  AspectRatio(
                    aspectRatio: 16 / 9,
                    child: Stack(
                      fit: StackFit.expand,
                      children: [
                        _buildImage(imageUrl, isDark),
                        Positioned(
                          left: 0,
                          right: 0,
                          bottom: 0,
                          height: 130,
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
                                style: GoogleFonts.gelasio(
                                  fontSize: 22,
                                  fontWeight: FontWeight.w700,
                                  color: textPrimary,
                                  letterSpacing: -0.3,
                                ),
                              ),
                              const SizedBox(height: 6),
                              Row(
                                children: [
                                  Icon(
                                    LucideIcons.mapPin,
                                    size: 11,
                                    color: M4Theme.premiumBlue.withValues(
                                      alpha: 0.7,
                                    ),
                                  ),
                                  const SizedBox(width: 6),
                                  Expanded(
                                    child: Text(
                                      location.toUpperCase(),
                                      maxLines: 1,
                                      overflow: TextOverflow.ellipsis,
                                      style: GoogleFonts.gelasio(
                                        fontSize: 11,
                                        fontWeight: FontWeight.w700,
                                        color: M4Theme.premiumBlue.withValues(
                                          alpha: 0.7,
                                        ),
                                        letterSpacing: 2,
                                      ),
                                    ),
                                  ),
                                ],
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
                                icon: LucideIcons.ruler,
                                label: 'AREA',
                                value: areaText,
                                muted: muted,
                                textPrimary: textPrimary,
                              ),
                            ),
                            Expanded(
                              child: _SpecItem(
                                icon: LucideIcons.percent,
                                label: 'YIELD',
                                value: yieldVal,
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
                                icon: LucideIcons.layers,
                                label: 'UNITS / STAKE',
                                value: units,
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
                                Icon(
                                  LucideIcons.shieldCheck,
                                  size: 16,
                                  color: isDark
                                      ? const Color(0xFF0C312B)
                                      : const Color(0xFFF4EFE3),
                                ),
                                const SizedBox(width: 8),
                                Text(
                                  'VERIFIED INVESTMENT',
                                  style: GoogleFonts.gelasio(
                                    fontSize: 11,
                                    fontWeight: FontWeight.w700,
                                    color: isDark
                                        ? const Color(0xFF0C312B)
                                        : const Color(0xFFF4EFE3),
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
    final faint = (isDark ? Colors.white : const Color(0xFF0C312B)).withValues(
      alpha: 0.55,
    );
    return Padding(
      padding: const EdgeInsets.only(top: 32),
      child: Center(
        child: Column(
          children: [
            Icon(LucideIcons.pieChart, size: 56, color: faint),
            const SizedBox(height: 20),
            Text(
              'NO INVESTMENTS YET',
              style: GoogleFonts.gelasio(
                fontSize: 13,
                fontWeight: FontWeight.w700,
                color: faint,
                letterSpacing: 2,
              ),
            ),
            const SizedBox(height: 8),
            Text(
              'Your portfolio holdings will appear here.',
              textAlign: TextAlign.center,
              style: GoogleFonts.inter(
                fontSize: 13,
                fontWeight: FontWeight.w600,
                color: (isDark ? Colors.white : const Color(0xFF0C312B))
                    .withValues(alpha: 0.35),
              ),
            ),
            const SizedBox(height: 20),
            _PressableScale(
              onTap: () => context.go('/investor/projects'),
              child: Container(
                padding: const EdgeInsets.symmetric(
                  horizontal: 24,
                  vertical: 12,
                ),
                decoration: BoxDecoration(
                  color: isDark ? Colors.white : const Color(0xFF0C312B),
                  borderRadius: BorderRadius.circular(14),
                ),
                child: Text(
                  'EXPLORE OPPORTUNITIES',
                  style: GoogleFonts.gelasio(
                    fontSize: 10,
                    fontWeight: FontWeight.w700,
                    color: isDark
                        ? const Color(0xFF0C312B)
                        : const Color(0xFFF4EFE3),
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

  Widget _buildErrorState(bool isDark) {
    final textPrimary = isDark ? Colors.white : const Color(0xFF0C312B);
    final muted = textPrimary.withValues(alpha: 0.5);
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(32),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(LucideIcons.alertTriangle, size: 48, color: muted),
            const SizedBox(height: 20),
            Text(
              'UNABLE TO LOAD PORTFOLIO',
              style: GoogleFonts.gelasio(
                fontSize: 11,
                fontWeight: FontWeight.w700,
                color: muted,
                letterSpacing: 2,
              ),
            ),
            const SizedBox(height: 20),
            _PressableScale(
              onTap: _fetchPortfolio,
              child: Container(
                padding: const EdgeInsets.symmetric(
                  horizontal: 24,
                  vertical: 12,
                ),
                decoration: BoxDecoration(
                  color: textPrimary,
                  borderRadius: BorderRadius.circular(14),
                ),
                child: Text(
                  'RETRY',
                  style: GoogleFonts.gelasio(
                    fontSize: 10,
                    fontWeight: FontWeight.w700,
                    color: isDark
                        ? const Color(0xFF0C312B)
                        : const Color(0xFFF4EFE3),
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
  double _num(dynamic source, List<String> keys) {
    if (source is! Map) return 0;
    for (final k in keys) {
      final v = source[k];
      if (v is num) return v.toDouble();
      if (v is String && v.isNotEmpty) {
        final digits = v.replaceAll(RegExp(r'[^0-9.]'), '');
        final parsed = double.tryParse(digits);
        if (parsed != null && parsed > 0) return parsed;
      }
    }
    return 0;
  }

  /// Square footage allotted to a stake. Stakes are denominated in area now;
  /// amounts / market value / equity share are no longer recorded for them.
  double _squareFeet(dynamic h) =>
      _num(h, ['squareFeet', 'square_ft', 'sqft', 'areaSqft', 'area']);

  /// Thousands-grouped square footage, e.g. `1,250 SQ FT`.
  String _formatArea(double area) {
    if (area <= 0) return '—';
    return '${NumberFormat('#,##0').format(area)} SQ FT';
  }

  // Yield is the only performance metric still supplied for stakes; when the
  // server omits it there is nothing to show and the strip stays hidden.
  String? get _avgYield {
    final s = _summary;
    if (s == null) return null;
    final v = s['avgYield'] ?? s['averageYield'] ?? s['yield'];
    if (v == null) return null;
    final str = v.toString();
    return str.isEmpty ? null : str;
  }

  /// Extracts the holdings list (and summary map, when present) from an
  /// investor response envelope: a bare list, `{status, data}`, or
  /// `data.holdings`-style nesting. A map-shaped payload without a list means
  /// "nothing held" (empty list), not an error; null means the body was
  /// unusable (`status: false` or no recognizable shape) so the caller can
  /// fall back to the legacy endpoint.
  ({List<dynamic>? holdings, Map<String, dynamic>? summary}) _parseHoldingsBody(
    dynamic body,
  ) {
    if (body is List) return (holdings: body, summary: null);
    if (body is Map) {
      if (body['status'] == false) return (holdings: null, summary: null);
      final dynamic data = body['data'] ?? body;
      if (data is List) return (holdings: data, summary: null);
      if (data is Map) {
        final summary = Map<String, dynamic>.from(data);
        final dynamic list =
            data['holdings'] ??
            data['investments'] ??
            data['items'] ??
            data['portfolio'];
        return (holdings: list is List ? list : <dynamic>[], summary: summary);
      }
    }
    return (holdings: null, summary: null);
  }

  String _projectName(dynamic h) {
    if (h is! Map) return 'Investment';
    final project = h['project'];
    if (project is Map) {
      final t = project['title'] ?? project['name'];
      if (t != null && t.toString().isNotEmpty) return t.toString();
    }
    final direct = h['projectName'] ?? h['title'] ?? h['name'];
    if (direct != null && direct.toString().isNotEmpty)
      return direct.toString();
    return 'Investment';
  }

  String _location(dynamic h) {
    if (h is! Map) return 'Developing Area';
    final project = h['project'];
    if (project is Map) {
      final loc = project['location'];
      if (loc is Map && loc['name'] != null) return loc['name'].toString();
      if (loc is String && loc.isNotEmpty) return loc;
    }
    final loc = h['location'];
    if (loc is Map && loc['name'] != null) return loc['name'].toString();
    if (loc is String && loc.isNotEmpty) return loc;
    return 'Developing Area';
  }

  String? _firstImage(dynamic holding) {
    if (holding is! Map) return null;
    // The project's Master Image (`heroImage`) leads. The old `coverImage` /
    // `thumbnail` fields held demo stock photos and have been removed.
    final candidates = [holding['heroImage'], holding['image']];
    for (final c in candidates) {
      if (c is String && c.isNotEmpty) return c;
    }
    final project = holding['project'];
    if (project is Map) {
      final pc = [project['heroImage'], project['image']];
      for (final c in pc) {
        if (c is String && c.isNotEmpty) return c;
      }
      final images = project['images'];
      if (images is List && images.isNotEmpty) {
        final first = images.first;
        if (first is String && first.isNotEmpty) return first;
        if (first is Map && first['url'] is String) {
          return first['url'] as String;
        }
      }
    }
    final images = holding['images'];
    if (images is List && images.isNotEmpty) {
      final first = images.first;
      if (first is String && first.isNotEmpty) return first;
      if (first is Map && first['url'] is String) return first['url'] as String;
    }
    return null;
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
        style: GoogleFonts.gelasio(
          fontSize: 10,
          fontWeight: FontWeight.w700,
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
    final s = status.toLowerCase();
    final positive =
        s.contains('active') ||
        s.contains('ready') ||
        s.contains('confirmed') ||
        s.contains('completed');
    final color = positive ? const Color(0xFF163A2C) : const Color(0xFFC5A35B);
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 5),
      decoration: BoxDecoration(
        color: color.withValues(alpha: 0.2),
        borderRadius: BorderRadius.circular(10),
        border: Border.all(color: color.withValues(alpha: 0.25)),
      ),
      child: Text(
        status.toUpperCase(),
        style: GoogleFonts.gelasio(
          fontSize: 10,
          fontWeight: FontWeight.w700,
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
  const _DetailItem({
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
        Text(
          label,
          style: GoogleFonts.gelasio(
            fontSize: 10,
            fontWeight: FontWeight.w700,
            color: muted,
            letterSpacing: 1.5,
          ),
        ),
        const SizedBox(height: 6),
        Text(
          value.toUpperCase(),
          style: GoogleFonts.inter(
            fontSize: 11,
            fontWeight: FontWeight.w500,
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
                style: GoogleFonts.gelasio(
                  fontSize: 10,
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
          style: GoogleFonts.inter(
            fontSize: 12,
            fontWeight: FontWeight.w500,
            color: textPrimary,
          ),
        ),
      ],
    );
  }
}
