import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:lucide_icons/lucide_icons.dart';
import 'package:cached_network_image/cached_network_image.dart';
import 'package:go_router/go_router.dart';
import 'package:intl/intl.dart';
import 'package:m4_mobile/core/theme/app_theme.dart';
import 'package:m4_mobile/presentation/providers/auth_provider.dart';

/// INVESTOR PORTFOLIO — "MY INVESTMENTS" performance dashboard.
///
/// Mirrors the structure of the user-side `PortfolioScreen`
/// (`app/(user)/profile/portfolio`) and the investor web prototype
/// `app/investor/profile/portfolio/page.tsx`, but reframed for an investor:
///  - Header: PORTFOLIO / MY INVESTMENTS
///  - Summary card: invested capital + current valuation
///  - Performance strip: total ROI, unrealised gains, avg yield
///  - Allocation breakdown by project (capital share + performance metric)
///  - INVESTMENT BREAKDOWN: image card per holding with project, location,
///    invested value, current value, ROI badge, and a VIEW PERFORMANCE sheet.
///
/// Data is fetched live from `GET /api/investor/portfolio`
/// (`apiClient.getInvestorPortfolio()`). Field shapes are parsed defensively so
/// the screen renders whether the backend returns a flat list or an envelope
/// with summary + holdings.
class InvestorPortfolioScreen extends ConsumerStatefulWidget {
  const InvestorPortfolioScreen({super.key});

  @override
  ConsumerState<InvestorPortfolioScreen> createState() =>
      _InvestorPortfolioScreenState();
}

class _InvestorPortfolioScreenState
    extends ConsumerState<InvestorPortfolioScreen> {
  static const Color _gold = Color(0xFFFFD700);
  static const Color _green = Color(0xFF22C55E);
  static const Color _amber = Color(0xFFF59E0B);

  bool _isLoading = true;
  bool _hasError = false;

  List<dynamic> _holdings = [];
  double _invested = 0;
  double _currentValue = 0;
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
      final res = await apiClient.getInvestorPortfolio();
      final body = res.data;
      if (body is Map && body['status'] == true) {
        final dynamic data = body['data'];

        List<dynamic> holdings = [];
        Map<String, dynamic>? summary;

        if (data is List) {
          holdings = data;
        } else if (data is Map) {
          summary = Map<String, dynamic>.from(data);
          final dynamic list = data['holdings'] ??
              data['investments'] ??
              data['items'] ??
              data['portfolio'];
          if (list is List) holdings = list;
        }

        final invested = holdings.fold<double>(
            0, (sum, h) => sum + _num(h, ['investedAmount', 'invested', 'amount', 'investment']));
        final current = holdings.fold<double>(
            0,
            (sum, h) => sum +
                _num(h, ['currentValue', 'marketValue', 'valuation', 'value']));

        if (mounted) {
          setState(() {
            _holdings = holdings;
            _summary = summary;
            _invested = _summary != null
                ? _summaryNum(['totalInvested', 'invested', 'capitalDeployed'],
                    fallback: invested)
                : invested;
            _currentValue = _summary != null
                ? _summaryNum(['currentValue', 'totalValue', 'valuation'],
                    fallback: current > 0 ? current : invested)
                : (current > 0 ? current : invested);
          });
        }
      } else if (mounted) {
        setState(() => _hasError = true);
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

  // ─── Derived metrics ──────────────────────────────────────────────────────
  double get _gains => _currentValue - _invested;
  double get _roiPct =>
      _invested <= 0 ? 0 : (_gains / _invested) * 100;

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
                color:
                    isDark ? Colors.white.withValues(alpha: 0.03) : Colors.white,
                borderRadius: BorderRadius.circular(14),
                border: Border.all(color: border),
              ),
              child: Icon(LucideIcons.arrowLeft,
                  size: 20, color: textPrimary.withValues(alpha: 0.6)),
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
            const SizedBox(height: 16),
            _buildPerformanceStrip(isDark),
            const SizedBox(height: 28),
            if (_holdings.isNotEmpty) ...[
              _sectionLabel('CAPITAL ALLOCATION', isDark),
              const SizedBox(height: 16),
              _buildAllocationCard(isDark),
              const SizedBox(height: 28),
            ],
            _sectionLabel('INVESTMENT BREAKDOWN', isDark),
            const SizedBox(height: 16),
            if (_holdings.isEmpty)
              _buildEmptyState(isDark)
            else
              ..._holdings.map((h) => _buildHoldingCard(h, isDark)),
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
        style: GoogleFonts.montserrat(
          fontSize: 9,
          fontWeight: FontWeight.w700,
          color: (isDark ? Colors.white : Colors.black).withValues(alpha: 0.5),
          letterSpacing: 3,
        ),
      ),
    );
  }

  // ─── Summary card ────────────────────────────────────────────────────────────
  Widget _buildSummaryCard(bool isDark) {
    final muted = (isDark ? Colors.white : Colors.black).withValues(alpha: 0.5);

    final count = _holdings.length.toString().padLeft(2, '0');

    return Container(
      padding: const EdgeInsets.all(24),
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(28),
        gradient: const LinearGradient(
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
          colors: [Color(0xFF1A1A1A), Color(0xFF0A0A0A)],
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
                'PORTFOLIO VALUATION',
                style: GoogleFonts.montserrat(
                  fontSize: 9,
                  fontWeight: FontWeight.w900,
                  letterSpacing: 2.5,
                  color: Colors.white.withValues(alpha: 0.6),
                ),
              ),
            ],
          ),
          const SizedBox(height: 20),
          Row(
            crossAxisAlignment: CrossAxisAlignment.end,
            children: [
              Flexible(
                child: Text(
                  _formatValue(_currentValue),
                  style: GoogleFonts.montserrat(
                    fontSize: 32,
                    fontWeight: FontWeight.w900,
                    color: Colors.white,
                    height: 1.0,
                    letterSpacing: -1,
                  ),
                ),
              ),
              const SizedBox(width: 10),
              Padding(
                padding: const EdgeInsets.only(bottom: 4),
                child: Container(
                  padding:
                      const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
                  decoration: BoxDecoration(
                    color: (_gains >= 0 ? _green : _amber)
                        .withValues(alpha: 0.15),
                    borderRadius: BorderRadius.circular(8),
                  ),
                  child: Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Icon(
                          _gains >= 0
                              ? LucideIcons.trendingUp
                              : LucideIcons.trendingDown,
                          size: 12,
                          color: _gains >= 0 ? _green : _amber),
                      const SizedBox(width: 4),
                      Text(
                        '${_roiPct >= 0 ? '+' : ''}${_roiPct.toStringAsFixed(1)}%',
                        style: GoogleFonts.montserrat(
                          fontSize: 11,
                          fontWeight: FontWeight.w900,
                          color: _gains >= 0 ? _green : _amber,
                        ),
                      ),
                    ],
                  ),
                ),
              ),
            ],
          ),
          const SizedBox(height: 6),
          Text(
            'CURRENT MARKET VALUE',
            style: GoogleFonts.montserrat(
              fontSize: 9,
              fontWeight: FontWeight.w800,
              letterSpacing: 2,
              color: Colors.white.withValues(alpha: 0.4),
            ),
          ),
          const SizedBox(height: 22),
          Row(
            children: [
              Expanded(
                child: _summaryStat(
                    'CAPITAL DEPLOYED', _formatValue(_invested),
                    valueColor: Colors.white),
              ),
              Container(
                  width: 1, height: 36, color: Colors.white.withValues(alpha: 0.1)),
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

  Widget _summaryStat(String label, String value,
      {required Color valueColor, Color? muted}) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          label,
          style: GoogleFonts.montserrat(
            fontSize: 8,
            fontWeight: FontWeight.w800,
            letterSpacing: 1.5,
            color: Colors.white.withValues(alpha: 0.4),
          ),
        ),
        const SizedBox(height: 6),
        Text(
          value,
          style: GoogleFonts.montserrat(
            fontSize: 16,
            fontWeight: FontWeight.w900,
            color: valueColor,
          ),
        ),
      ],
    );
  }

  // ─── Performance strip ───────────────────────────────────────────────────────
  Widget _buildPerformanceStrip(bool isDark) {
    final avgYield = (_summary?['avgYield'] ??
            _summary?['averageYield'] ??
            (_invested > 0 ? '${(_roiPct).toStringAsFixed(1)}%' : '0.0%'))
        .toString();

    return Row(
      children: [
        Expanded(
          child: _metricTile(
            isDark,
            icon: _gains >= 0
                ? LucideIcons.trendingUp
                : LucideIcons.trendingDown,
            label: 'UNREALISED GAINS',
            value: '${_gains >= 0 ? '+' : '-'}${_formatValue(_gains.abs())}',
            accent: _gains >= 0 ? _green : _amber,
          ),
        ),
        const SizedBox(width: 14),
        Expanded(
          child: _metricTile(
            isDark,
            icon: LucideIcons.percent,
            label: 'AVG YIELD',
            value: avgYield,
            accent: M4Theme.premiumBlue,
          ),
        ),
      ],
    );
  }

  Widget _metricTile(bool isDark,
      {required IconData icon,
      required String label,
      required String value,
      required Color accent}) {
    final textPrimary = isDark ? Colors.white : Colors.black;
    final muted = textPrimary.withValues(alpha: 0.5);
    final card = isDark ? Colors.white.withValues(alpha: 0.03) : Colors.white;
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
            style: GoogleFonts.montserrat(
              fontSize: 16,
              fontWeight: FontWeight.w900,
              color: textPrimary,
              letterSpacing: -0.3,
            ),
          ),
          const SizedBox(height: 4),
          Text(
            label,
            style: GoogleFonts.montserrat(
              fontSize: 8,
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
    final textPrimary = isDark ? Colors.white : Colors.black;
    final muted = textPrimary.withValues(alpha: 0.5);
    final card = isDark ? Colors.white.withValues(alpha: 0.03) : Colors.white;
    final border = isDark
        ? Colors.white.withValues(alpha: 0.08)
        : Colors.black.withValues(alpha: 0.06);

    final total = _holdings.fold<double>(
        0, (sum, h) => sum + _holdingValue(h));
    final palette = [
      _gold,
      M4Theme.premiumBlue,
      _green,
      const Color(0xFF8B5CF6),
      const Color(0xFFEC4899),
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
                      flex: ((_holdingValue(_holdings[i]) /
                                  (total <= 0 ? 1 : total)) *
                              1000)
                          .round()
                          .clamp(1, 1000),
                      child: Container(
                          color: palette[i % palette.length]),
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

  Widget _allocationRow(dynamic h, Color color, double total, Color textPrimary,
      Color muted) {
    final name = _projectName(h);
    final value = _holdingValue(h);
    final pct = total <= 0 ? 0.0 : (value / total) * 100;

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
            style: GoogleFonts.montserrat(
              fontSize: 11,
              fontWeight: FontWeight.w800,
              color: textPrimary,
              letterSpacing: 0.2,
            ),
          ),
        ),
        const SizedBox(width: 12),
        Text(
          '${pct.toStringAsFixed(0)}%',
          style: GoogleFonts.montserrat(
            fontSize: 11,
            fontWeight: FontWeight.w900,
            color: muted,
          ),
        ),
      ],
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

    final name = _projectName(holding);
    final location = _location(holding);
    final id = (holding['id'] ?? holding['_id'] ?? '—').toString();
    final shortId = id.length > 8 ? id.substring(id.length - 8) : id;
    final status = (holding['status'] ?? 'Active').toString();
    final invested = _num(holding, ['investedAmount', 'invested', 'amount']);
    final current =
        _holdingValue(holding);
    final roi = invested <= 0 ? 0.0 : ((current - invested) / invested) * 100;
    final imageUrl = _firstImage(holding);

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
                          size: 12,
                          color: M4Theme.premiumBlue.withValues(alpha: 0.6)),
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
                            label: 'INVESTED',
                            value: _formatValue(invested),
                            muted: muted,
                            textPrimary: textPrimary,
                          ),
                        ),
                        Expanded(
                          child: _DetailItem(
                            label: 'CURRENT VALUE',
                            value: _formatValue(current),
                            muted: muted,
                            textPrimary: textPrimary,
                            alignEnd: true,
                          ),
                        ),
                      ],
                    ),
                  ),
                  const SizedBox(height: 16),
                  Row(
                    children: [
                      _RoiBadge(roi: roi),
                      const Spacer(),
                      _PressableScale(
                        onTap: () =>
                            _showPerformance(holding, isDark),
                        child: Container(
                          height: 44,
                          padding:
                              const EdgeInsets.symmetric(horizontal: 18),
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
                                style: GoogleFonts.montserrat(
                                  fontSize: 9,
                                  fontWeight: FontWeight.w800,
                                  color:
                                      isDark ? Colors.black : Colors.white,
                                  letterSpacing: 1.5,
                                ),
                              ),
                              const SizedBox(width: 8),
                              Icon(LucideIcons.maximize2,
                                  size: 13,
                                  color:
                                      isDark ? Colors.black : Colors.white),
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
    final placeholderBg =
        (isDark ? Colors.white : Colors.black).withValues(alpha: 0.05);
    if (url == null || url.isEmpty) {
      return Container(
        color: placeholderBg,
        child: Icon(LucideIcons.building2,
            size: 48,
            color:
                (isDark ? Colors.white : Colors.black).withValues(alpha: 0.15)),
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
            color:
                (isDark ? Colors.white : Colors.black).withValues(alpha: 0.15)),
      ),
    );
  }

  // ─── Performance sheet ───────────────────────────────────────────────────────
  void _showPerformance(dynamic holding, bool isDark) {
    final name = _projectName(holding);
    final location = _location(holding);
    final invested = _num(holding, ['investedAmount', 'invested', 'amount']);
    final current = _holdingValue(holding);
    final gains = current - invested;
    final roi = invested <= 0 ? 0.0 : (gains / invested) * 100;
    final units = (holding['units'] ??
            holding['unitNumber'] ??
            holding['quantity'] ??
            '—')
        .toString();
    final yieldVal = (holding['yield'] ??
            holding['rentalYield'] ??
            holding['annualYield'] ??
            '—')
        .toString();
    final imageUrl = _firstImage(holding);

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
                                style: GoogleFonts.montserrat(
                                  fontSize: 22,
                                  fontWeight: FontWeight.w800,
                                  color: textPrimary,
                                  letterSpacing: -0.3,
                                ),
                              ),
                              const SizedBox(height: 6),
                              Row(
                                children: [
                                  Icon(LucideIcons.mapPin,
                                      size: 11,
                                      color: M4Theme.premiumBlue
                                          .withValues(alpha: 0.7)),
                                  const SizedBox(width: 6),
                                  Expanded(
                                    child: Text(
                                      location.toUpperCase(),
                                      maxLines: 1,
                                      overflow: TextOverflow.ellipsis,
                                      style: GoogleFonts.montserrat(
                                        fontSize: 9,
                                        fontWeight: FontWeight.w700,
                                        color: M4Theme.premiumBlue
                                            .withValues(alpha: 0.7),
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
                        // Net return banner
                        Container(
                          padding: const EdgeInsets.all(18),
                          decoration: BoxDecoration(
                            color: (gains >= 0 ? _green : _amber)
                                .withValues(alpha: 0.1),
                            borderRadius: BorderRadius.circular(20),
                            border: Border.all(
                                color: (gains >= 0 ? _green : _amber)
                                    .withValues(alpha: 0.25)),
                          ),
                          child: Row(
                            children: [
                              Icon(
                                  gains >= 0
                                      ? LucideIcons.trendingUp
                                      : LucideIcons.trendingDown,
                                  size: 22,
                                  color: gains >= 0 ? _green : _amber),
                              const SizedBox(width: 14),
                              Expanded(
                                child: Column(
                                  crossAxisAlignment:
                                      CrossAxisAlignment.start,
                                  children: [
                                    Text(
                                      'NET RETURN',
                                      style: GoogleFonts.montserrat(
                                        fontSize: 8,
                                        fontWeight: FontWeight.w800,
                                        color: muted,
                                        letterSpacing: 2,
                                      ),
                                    ),
                                    const SizedBox(height: 4),
                                    Text(
                                      '${gains >= 0 ? '+' : '-'}${_formatValue(gains.abs())}',
                                      style: GoogleFonts.montserrat(
                                        fontSize: 18,
                                        fontWeight: FontWeight.w900,
                                        color: gains >= 0 ? _green : _amber,
                                      ),
                                    ),
                                  ],
                                ),
                              ),
                              Text(
                                '${roi >= 0 ? '+' : ''}${roi.toStringAsFixed(1)}%',
                                style: GoogleFonts.montserrat(
                                  fontSize: 20,
                                  fontWeight: FontWeight.w900,
                                  color: gains >= 0 ? _green : _amber,
                                ),
                              ),
                            ],
                          ),
                        ),
                        const SizedBox(height: 24),
                        Row(
                          children: [
                            Expanded(
                              child: _SpecItem(
                                icon: LucideIcons.wallet,
                                label: 'INVESTED',
                                value: _formatValue(invested),
                                muted: muted,
                                textPrimary: textPrimary,
                              ),
                            ),
                            Expanded(
                              child: _SpecItem(
                                icon: LucideIcons.lineChart,
                                label: 'CURRENT VALUE',
                                value: _formatValue(current),
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
                                  'VERIFIED INVESTMENT',
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
      padding: const EdgeInsets.only(top: 32),
      child: Center(
        child: Column(
          children: [
            Icon(LucideIcons.pieChart, size: 56, color: faint),
            const SizedBox(height: 20),
            Text(
              'NO INVESTMENTS YET',
              style: GoogleFonts.montserrat(
                fontSize: 11,
                fontWeight: FontWeight.w800,
                color: faint,
                letterSpacing: 2,
              ),
            ),
            const SizedBox(height: 8),
            Text(
              'Your portfolio holdings will appear here.',
              textAlign: TextAlign.center,
              style: GoogleFonts.montserrat(
                fontSize: 11,
                fontWeight: FontWeight.w500,
                color:
                    (isDark ? Colors.white : Colors.black).withValues(alpha: 0.35),
              ),
            ),
            const SizedBox(height: 20),
            _PressableScale(
              onTap: () => context.go('/investor/projects'),
              child: Container(
                padding:
                    const EdgeInsets.symmetric(horizontal: 24, vertical: 12),
                decoration: BoxDecoration(
                  color: isDark ? Colors.white : Colors.black,
                  borderRadius: BorderRadius.circular(14),
                ),
                child: Text(
                  'EXPLORE OPPORTUNITIES',
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

  Widget _buildErrorState(bool isDark) {
    final textPrimary = isDark ? Colors.white : Colors.black;
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

  double _summaryNum(List<String> keys, {required double fallback}) {
    final s = _summary;
    if (s == null) return fallback;
    final v = _num(s, keys);
    return v > 0 ? v : fallback;
  }

  /// Best-effort "current value" of a holding, falling back to invested amount.
  double _holdingValue(dynamic h) {
    final current =
        _num(h, ['currentValue', 'marketValue', 'valuation', 'value']);
    if (current > 0) return current;
    return _num(h, ['investedAmount', 'invested', 'amount', 'investment']);
  }

  String _projectName(dynamic h) {
    if (h is! Map) return 'Investment';
    final project = h['project'];
    if (project is Map) {
      final t = project['title'] ?? project['name'];
      if (t != null && t.toString().isNotEmpty) return t.toString();
    }
    final direct = h['projectName'] ?? h['title'] ?? h['name'];
    if (direct != null && direct.toString().isNotEmpty) return direct.toString();
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
    final candidates = [
      holding['image'],
      holding['coverImage'],
      holding['thumbnail'],
    ];
    for (final c in candidates) {
      if (c is String && c.isNotEmpty) return c;
    }
    final project = holding['project'];
    if (project is Map) {
      final pc = [
        project['coverImage'],
        project['image'],
        project['thumbnail'],
      ];
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

  String _formatValue(double value) {
    if (value <= 0) return 'AED --';
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
    final s = status.toLowerCase();
    final positive = s.contains('active') ||
        s.contains('ready') ||
        s.contains('confirmed') ||
        s.contains('completed');
    final color =
        positive ? const Color(0xFF22C55E) : const Color(0xFFF59E0B);
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

class _RoiBadge extends StatelessWidget {
  final double roi;
  const _RoiBadge({required this.roi});

  @override
  Widget build(BuildContext context) {
    final positive = roi >= 0;
    final color = positive ? const Color(0xFF22C55E) : const Color(0xFFF59E0B);
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
      decoration: BoxDecoration(
        color: color.withValues(alpha: 0.12),
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: color.withValues(alpha: 0.25)),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(
              positive
                  ? LucideIcons.trendingUp
                  : LucideIcons.trendingDown,
              size: 13,
              color: color),
          const SizedBox(width: 6),
          Text(
            '${positive ? '+' : ''}${roi.toStringAsFixed(1)}% ROI',
            style: GoogleFonts.montserrat(
              fontSize: 10,
              fontWeight: FontWeight.w900,
              color: color,
              letterSpacing: 0.3,
            ),
          ),
        ],
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
