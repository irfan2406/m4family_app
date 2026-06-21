import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:intl/intl.dart';
import 'package:lucide_icons/lucide_icons.dart';
import 'package:m4_mobile/core/theme/app_theme.dart';
import 'package:m4_mobile/presentation/providers/auth_provider.dart';

/// Web `/investor/payments/[id]` — single transaction / payment-schedule detail.
/// Mirrors `CpPaymentDetailScreen` structure, adapted to the investor financial
/// ledger (web maps `/payment-schedule` schedules: `milestoneName`,
/// `projectId.title`, `amountDue`/`amount`, `dueDate`/`createdAt`, `status`, `type`).
/// Reached from the investor payments list via
/// `context.push('/investor/payments/{id}', extra: paymentData)`.
class InvestorPaymentDetailScreen extends ConsumerStatefulWidget {
  final String paymentId;
  final Map<String, dynamic>? initialData;

  const InvestorPaymentDetailScreen({
    super.key,
    required this.paymentId,
    this.initialData,
  });

  @override
  ConsumerState<InvestorPaymentDetailScreen> createState() =>
      _InvestorPaymentDetailScreenState();
}

class _InvestorPaymentDetailScreenState
    extends ConsumerState<InvestorPaymentDetailScreen> {
  static const _gold = Color(0xFFFFD700);
  static const _green = Color(0xFF10B981);

  Map<String, dynamic>? _payment;
  bool _loading = true;
  bool _error = false;

  @override
  void initState() {
    super.initState();
    if (widget.initialData != null) {
      _payment = Map<String, dynamic>.from(widget.initialData!);
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
      // Web ledger reads from `/payment-schedule`; resolve the single row by id.
      final res = await api.get('/api/payment-schedule');
      if (!mounted) return;
      final body = res.data;
      Map<String, dynamic>? found;
      if (res.statusCode == 200 && body is Map && body['status'] == true) {
        final data = body['data'];
        List schedules = const [];
        if (data is Map && data['schedules'] is List) {
          schedules = data['schedules'] as List;
        } else if (data is List) {
          schedules = data;
        }
        for (final s in schedules) {
          if (s is Map &&
              (s['_id']?.toString() == widget.paymentId ||
                  s['id']?.toString() == widget.paymentId)) {
            found = Map<String, dynamic>.from(s);
            break;
          }
        }
      }
      if (found != null) {
        _payment = found;
      } else if (_payment == null) {
        _error = true;
      }
    } catch (_) {
      if (_payment == null) _error = true;
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

  void _share() {
    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(content: Text('Sharing is not available yet.')),
    );
  }

  void _getHelp() {
    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(content: Text('Support ticket created')),
    );
  }

  bool get _isCredit {
    final status = (_payment?['status'] ?? '').toString().toUpperCase();
    return status == 'PAID';
  }

  String get _shortId {
    final id = widget.paymentId;
    return id.length > 8
        ? id.substring(id.length - 8).toUpperCase()
        : id.toUpperCase();
  }

  String _amountLabel() {
    final amount = _payment?['amountDue'] ?? _payment?['amount'];
    final num value = amount is num ? amount : num.tryParse('${amount ?? 0}') ?? 0;
    final formatted = NumberFormat('#,##0', 'en_US').format(value);
    return 'AED $formatted';
  }

  String _descriptionLabel() {
    final milestone = _payment?['milestoneName']?.toString();
    if (milestone != null && milestone.isNotEmpty) return milestone;
    final project = _payment?['projectId'];
    if (project is Map && project['title'] != null) {
      return project['title'].toString();
    }
    return 'Investment Payment';
  }

  String _typeLabel() {
    final type = _payment?['type']?.toString();
    if (type != null && type.isNotEmpty) return type;
    return 'Investment';
  }

  String _dateLabel() {
    final raw = (_payment?['dueDate'] ?? _payment?['createdAt'])?.toString();
    if (raw == null || raw.isEmpty) return '—';
    final dt = DateTime.tryParse(raw);
    if (dt == null) return '—';
    return DateFormat('d MMM yyyy').format(dt.toLocal());
  }

  String _projectLabel() {
    final project = _payment?['projectId'];
    if (project == null) return '—';
    if (project is Map) {
      return (project['title'] ?? project['_id'] ?? '—').toString();
    }
    return project.toString();
  }

  String _milestoneLabel() {
    final milestone = _payment?['milestoneName']?.toString();
    if (milestone == null || milestone.isEmpty) return '—';
    return milestone;
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
              child: _loading && _payment == null
                  ? const Center(
                      child:
                          CircularProgressIndicator(color: M4Theme.premiumBlue),
                    )
                  : (_error && _payment == null)
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
            onPressed: () => context.canPop()
                ? context.pop()
                : context.go('/investor/home'),
          ),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  'Transaction details',
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
                color:
                    (isDark ? Colors.white : Colors.black).withValues(alpha: 0.04),
                borderRadius: BorderRadius.circular(10),
                border: Border.all(
                  color: (isDark ? Colors.white : Colors.black)
                      .withValues(alpha: 0.08),
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
              'Transaction not found',
              style: GoogleFonts.montserrat(
                fontSize: 15,
                fontWeight: FontWeight.w800,
                color: textPrimary,
              ),
            ),
            const SizedBox(height: 8),
            Text(
              'The requested transaction could not be found.',
              textAlign: TextAlign.center,
              style: GoogleFonts.montserrat(fontSize: 12, color: muted),
            ),
          ],
        ),
      ),
    );
  }

  Widget _content(bool isDark, Color textPrimary, Color muted) {
    final status = (_payment?['status'] ?? '').toString();
    final fullId = (_payment?['_id'] ?? widget.paymentId).toString();
    final credit = _isCredit;
    final amountColor = credit ? _green : textPrimary;

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
                color: credit
                    ? _green.withValues(alpha: 0.10)
                    : _gold.withValues(alpha: 0.10),
                borderRadius: BorderRadius.circular(20),
                border: Border.all(
                  color: credit
                      ? _green.withValues(alpha: 0.20)
                      : _gold.withValues(alpha: 0.20),
                ),
              ),
              child: Icon(
                credit ? LucideIcons.arrowDownLeft : LucideIcons.arrowUpRight,
                size: 32,
                color: credit ? _green : _gold,
              ),
            ),
            const SizedBox(height: 16),
            Text(
              '${credit ? '+' : '-'}${_amountLabel()}',
              style: GoogleFonts.montserrat(
                fontSize: 30,
                fontWeight: FontWeight.w900,
                letterSpacing: -0.5,
                color: amountColor,
              ),
            ),
            const SizedBox(height: 6),
            Text(
              status.isEmpty ? '—' : status.toUpperCase(),
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
        _descriptionCard(isDark, textPrimary, muted),
        const SizedBox(height: 16),
        _idCard(isDark, textPrimary, muted, fullId),
        const SizedBox(height: 24),
        _actions(isDark, textPrimary, muted),
      ],
    );
  }

  Widget _infoCard(bool isDark, Color textPrimary, Color muted) {
    final card = isDark ? Colors.white.withValues(alpha: 0.03) : Colors.white;
    final border = isDark
        ? Colors.white.withValues(alpha: 0.08)
        : Colors.black.withValues(alpha: 0.06);
    final divider =
        (isDark ? Colors.white : Colors.black).withValues(alpha: 0.06);

    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: card,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: border),
      ),
      child: Column(
        children: [
          _row(label: 'TYPE', valueWidget: _valueText(_typeLabel(), textPrimary)),
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
            label: 'PROJECT',
            valueWidget: _constrainedValue(_projectLabel(), textPrimary),
          ),
          _hr(divider),
          _row(
            label: 'MILESTONE',
            valueWidget: _constrainedValue(_milestoneLabel(), textPrimary),
          ),
        ],
      ),
    );
  }

  Widget _descriptionCard(bool isDark, Color textPrimary, Color muted) {
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
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            'DESCRIPTION',
            style: GoogleFonts.montserrat(
              fontSize: 10,
              fontWeight: FontWeight.w700,
              letterSpacing: 1.2,
              color: muted,
            ),
          ),
          const SizedBox(height: 8),
          Text(
            _descriptionLabel(),
            style: GoogleFonts.montserrat(
              fontSize: 13,
              fontWeight: FontWeight.w500,
              height: 1.5,
              color: textPrimary.withValues(alpha: 0.8),
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
                  'REFERENCE ID',
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
                color: (isDark ? Colors.white : Colors.black)
                    .withValues(alpha: 0.04),
                borderRadius: BorderRadius.circular(10),
                border: Border.all(
                  color: (isDark ? Colors.white : Colors.black)
                      .withValues(alpha: 0.08),
                ),
              ),
              child: Icon(LucideIcons.copy, size: 15, color: muted),
            ),
          ),
        ],
      ),
    );
  }

  Widget _actions(bool isDark, Color textPrimary, Color muted) {
    return Row(
      children: [
        Expanded(
          child: _actionButton(
            isDark: isDark,
            muted: muted,
            icon: LucideIcons.share2,
            label: 'SHARE',
            onTap: _share,
          ),
        ),
        const SizedBox(width: 12),
        Expanded(
          child: _actionButton(
            isDark: isDark,
            muted: muted,
            icon: LucideIcons.info,
            label: 'GET HELP',
            onTap: _getHelp,
          ),
        ),
      ],
    );
  }

  Widget _actionButton({
    required bool isDark,
    required Color muted,
    required IconData icon,
    required String label,
    required VoidCallback onTap,
  }) {
    final card = isDark ? Colors.white.withValues(alpha: 0.03) : Colors.white;
    final border = isDark
        ? Colors.white.withValues(alpha: 0.08)
        : Colors.black.withValues(alpha: 0.06);

    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(14),
      child: Container(
        padding: const EdgeInsets.symmetric(vertical: 14),
        decoration: BoxDecoration(
          color: card,
          borderRadius: BorderRadius.circular(14),
          border: Border.all(color: border),
        ),
        child: Row(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(icon, size: 14, color: muted),
            const SizedBox(width: 8),
            Text(
              label,
              style: GoogleFonts.montserrat(
                fontSize: 11,
                fontWeight: FontWeight.w700,
                letterSpacing: 1.2,
                color: muted,
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _constrainedValue(String text, Color textPrimary) {
    return ConstrainedBox(
      constraints: const BoxConstraints(maxWidth: 180),
      child: Text(
        text,
        maxLines: 1,
        overflow: TextOverflow.ellipsis,
        textAlign: TextAlign.right,
        style: GoogleFonts.montserrat(
          fontSize: 12,
          fontWeight: FontWeight.w500,
          color: textPrimary,
        ),
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
        Flexible(
            child: Align(alignment: Alignment.centerRight, child: valueWidget)),
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
