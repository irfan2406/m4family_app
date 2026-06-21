import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:intl/intl.dart';
import 'package:lucide_icons/lucide_icons.dart';
import 'package:m4_mobile/core/theme/app_theme.dart';
import 'package:m4_mobile/presentation/providers/auth_provider.dart';

/// Web `/cp/payments/[id]` — single commission detail (`GET /api/cp/commissions/:id`).
/// Reached from `cp_payments_screen` rows via
/// `context.push('/cp/payments/{id}', extra: commissionData)`.
class CpPaymentDetailScreen extends ConsumerStatefulWidget {
  final String commissionId;
  final Map<String, dynamic>? initialData;

  const CpPaymentDetailScreen({
    super.key,
    required this.commissionId,
    this.initialData,
  });

  @override
  ConsumerState<CpPaymentDetailScreen> createState() => _CpPaymentDetailScreenState();
}

class _CpPaymentDetailScreenState extends ConsumerState<CpPaymentDetailScreen> {
  Map<String, dynamic>? _commission;
  bool _loading = true;
  bool _error = false;

  @override
  void initState() {
    super.initState();
    if (widget.initialData != null) {
      _commission = Map<String, dynamic>.from(widget.initialData!);
    }
    _load();
  }

  Future<void> _load() async {
    setState(() {
      _loading = true;
      _error = false;
    });
    try {
      final api = ref.read(apiClientProvider);
      final res = await api.get('/api/cp/commissions/${widget.commissionId}');
      if (!mounted) return;
      if (res.statusCode == 200 && res.data['status'] == true && res.data['data'] is Map) {
        _commission = Map<String, dynamic>.from(res.data['data'] as Map);
      } else if (_commission == null) {
        _error = true;
      }
    } catch (_) {
      if (_commission == null) _error = true;
    }
    if (mounted) {
      setState(() => _loading = false);
    }
  }

  void _copy(String text) {
    Clipboard.setData(ClipboardData(text: text));
    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(
        content: Text('Copied to clipboard'),
        backgroundColor: Colors.green,
        duration: Duration(seconds: 2),
      ),
    );
  }

  void _downloadReceipt() {
    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(content: Text('Receipt export is not available yet.')),
    );
  }

  String get _shortId {
    final id = widget.commissionId;
    return id.length > 8 ? id.substring(id.length - 8).toUpperCase() : id.toUpperCase();
  }

  String _amountLabel() {
    final amount = _commission?['amount'];
    final num value = amount is num ? amount : num.tryParse('${amount ?? 0}') ?? 0;
    final formatted = NumberFormat('#,##0', 'en_US').format(value);
    return 'AED $formatted';
  }

  String _dateLabel() {
    final created = _commission?['createdAt']?.toString();
    if (created == null || created.isEmpty) return '—';
    final dt = DateTime.tryParse(created);
    if (dt == null) return '—';
    return DateFormat('d MMM yyyy').format(dt.toLocal());
  }

  String _bookingLabel() {
    final b = _commission?['bookingId'];
    if (b == null) return '—';
    if (b is Map) {
      return (b['title'] ?? b['_id'] ?? '—').toString();
    }
    return b.toString();
  }

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final bg = isDark ? Colors.black : Colors.white;
    final textPrimary = isDark ? Colors.white : Colors.black;
    final muted = (isDark ? Colors.white : Colors.black).withValues(alpha: 0.5);

    return Scaffold(
      backgroundColor: bg,
      body: SafeArea(
        child: Column(
          children: [
            _header(textPrimary, muted, isDark),
            Expanded(
              child: _loading && _commission == null
                  ? const Center(
                      child: CircularProgressIndicator(color: M4Theme.premiumBlue),
                    )
                  : (_error && _commission == null)
                      ? _errorState(textPrimary, muted)
                      : _content(isDark, textPrimary, muted),
            ),
          ],
        ),
      ),
    );
  }

  Widget _header(Color textPrimary, Color muted, bool isDark) {
    return Padding(
      padding: const EdgeInsets.fromLTRB(8, 8, 12, 8),
      child: Row(
        children: [
          IconButton(
            icon: Icon(LucideIcons.arrowLeft, color: textPrimary),
            onPressed: () =>
                context.canPop() ? context.pop() : context.go('/cp/dashboard'),
          ),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  'Commission details',
                  style: GoogleFonts.montserrat(
                    fontWeight: FontWeight.w900,
                    fontSize: 16,
                    color: textPrimary,
                  ),
                ),
                const SizedBox(height: 2),
                Text(
                  _shortId,
                  style: GoogleFonts.montserrat(
                    fontSize: 12,
                    fontWeight: FontWeight.w600,
                    letterSpacing: 1,
                    color: muted,
                  ),
                ),
              ],
            ),
          ),
          InkWell(
            onTap: _downloadReceipt,
            borderRadius: BorderRadius.circular(10),
            child: Container(
              padding: const EdgeInsets.all(8),
              decoration: BoxDecoration(
                color: (isDark ? Colors.white : Colors.black).withValues(alpha: 0.04),
                borderRadius: BorderRadius.circular(10),
                border: Border.all(
                  color: (isDark ? Colors.white : Colors.black).withValues(alpha: 0.08),
                ),
              ),
              child: Icon(LucideIcons.download, size: 18, color: muted),
            ),
          ),
        ],
      ),
    );
  }

  Widget _errorState(Color textPrimary, Color muted) {
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(32),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(LucideIcons.info, size: 48, color: muted),
            const SizedBox(height: 16),
            Text(
              'Commission not found',
              style: GoogleFonts.montserrat(
                fontSize: 15,
                fontWeight: FontWeight.w800,
                color: textPrimary,
              ),
            ),
            const SizedBox(height: 8),
            Text(
              'This commission could not be found or you do not have access.',
              textAlign: TextAlign.center,
              style: GoogleFonts.montserrat(fontSize: 12, color: muted),
            ),
          ],
        ),
      ),
    );
  }

  Widget _content(bool isDark, Color textPrimary, Color muted) {
    const green = Color(0xFF10B981);
    final status = (_commission?['status'] ?? '').toString();
    final fullId = (_commission?['_id'] ?? widget.commissionId).toString();

    return ListView(
      padding: const EdgeInsets.fromLTRB(24, 12, 24, 32),
      children: [
        Column(
          children: [
            const SizedBox(height: 12),
            Container(
              width: 64,
              height: 64,
              decoration: BoxDecoration(
                color: green.withValues(alpha: 0.10),
                borderRadius: BorderRadius.circular(20),
                border: Border.all(color: green.withValues(alpha: 0.20)),
              ),
              child: const Icon(LucideIcons.arrowDownLeft, size: 32, color: green),
            ),
            const SizedBox(height: 16),
            Text(
              '+${_amountLabel()}',
              style: GoogleFonts.montserrat(
                fontSize: 30,
                fontWeight: FontWeight.w900,
                letterSpacing: -0.5,
                color: green,
              ),
            ),
            const SizedBox(height: 6),
            Text(
              status.toUpperCase(),
              style: GoogleFonts.montserrat(
                fontSize: 10,
                fontWeight: FontWeight.w700,
                letterSpacing: 1.5,
                color: muted,
              ),
            ),
            const SizedBox(height: 24),
          ],
        ),
        _infoCard(isDark, textPrimary, muted),
        const SizedBox(height: 16),
        _idCard(isDark, textPrimary, muted, fullId),
      ],
    );
  }

  Widget _infoCard(bool isDark, Color textPrimary, Color muted) {
    final card = isDark ? Colors.white.withValues(alpha: 0.03) : Colors.white;
    final border = isDark
        ? Colors.white.withValues(alpha: 0.08)
        : Colors.black.withValues(alpha: 0.06);
    final divider = (isDark ? Colors.white : Colors.black).withValues(alpha: 0.06);

    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: card,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: border),
      ),
      child: Column(
        children: [
          _row(label: 'TYPE', valueWidget: _valueText('Commission', textPrimary)),
          _hr(divider),
          _row(
            label: 'DATE',
            valueWidget: Row(
              mainAxisSize: MainAxisSize.min,
              children: [
                Icon(LucideIcons.calendar, size: 13, color: muted),
                const SizedBox(width: 6),
                _valueText(_dateLabel(), textPrimary),
              ],
            ),
          ),
          _hr(divider),
          _row(
            label: 'BOOKING',
            valueWidget: ConstrainedBox(
              constraints: const BoxConstraints(maxWidth: 180),
              child: Text(
                _bookingLabel(),
                maxLines: 1,
                overflow: TextOverflow.ellipsis,
                textAlign: TextAlign.right,
                style: GoogleFonts.montserrat(
                  fontSize: 12,
                  fontWeight: FontWeight.w500,
                  color: textPrimary,
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _idCard(bool isDark, Color textPrimary, Color muted, String fullId) {
    final card = isDark ? Colors.white.withValues(alpha: 0.03) : Colors.white;
    final border = isDark
        ? Colors.white.withValues(alpha: 0.08)
        : Colors.black.withValues(alpha: 0.06);

    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: card,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: border),
      ),
      child: Row(
        children: [
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  'COMMISSION ID',
                  style: GoogleFonts.montserrat(
                    fontSize: 10,
                    fontWeight: FontWeight.w700,
                    letterSpacing: 1.2,
                    color: muted,
                  ),
                ),
                const SizedBox(height: 4),
                Text(
                  fullId,
                  style: GoogleFonts.robotoMono(
                    fontSize: 12,
                    letterSpacing: 0.5,
                    color: textPrimary,
                  ),
                ),
              ],
            ),
          ),
          const SizedBox(width: 12),
          InkWell(
            onTap: () => _copy(fullId),
            borderRadius: BorderRadius.circular(10),
            child: Container(
              padding: const EdgeInsets.all(8),
              decoration: BoxDecoration(
                color: (isDark ? Colors.white : Colors.black).withValues(alpha: 0.04),
                borderRadius: BorderRadius.circular(10),
                border: Border.all(
                  color: (isDark ? Colors.white : Colors.black).withValues(alpha: 0.08),
                ),
              ),
              child: Icon(LucideIcons.copy, size: 15, color: muted),
            ),
          ),
        ],
      ),
    );
  }

  Widget _row({required String label, required Widget valueWidget}) {
    final muted = (Theme.of(context).brightness == Brightness.dark
            ? Colors.white
            : Colors.black)
        .withValues(alpha: 0.5);
    return Row(
      mainAxisAlignment: MainAxisAlignment.spaceBetween,
      crossAxisAlignment: CrossAxisAlignment.center,
      children: [
        Text(
          label,
          style: GoogleFonts.montserrat(
            fontSize: 10,
            fontWeight: FontWeight.w700,
            letterSpacing: 1.2,
            color: muted,
          ),
        ),
        Flexible(child: Align(alignment: Alignment.centerRight, child: valueWidget)),
      ],
    );
  }

  Widget _valueText(String text, Color textPrimary) {
    return Text(
      text,
      style: GoogleFonts.montserrat(
        fontSize: 12,
        fontWeight: FontWeight.w500,
        color: textPrimary,
      ),
    );
  }

  Widget _hr(Color color) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 14),
      child: Container(height: 1, color: color),
    );
  }
}
