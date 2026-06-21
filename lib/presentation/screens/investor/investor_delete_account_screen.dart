import 'package:dio/dio.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:lucide_icons/lucide_icons.dart';
import 'package:m4_mobile/presentation/providers/auth_provider.dart';

/// Investor account deactivation — parity with the web
/// `/investor/profile/delete-account` purge protocol.
///
/// Multi-factor destructive gate:
///   1. Critical warning banner.
///   2. Purge scope list (what gets erased).
///   3. Type `DELETE` confirmation.
///   4. Password credential authorization.
///   5. Acknowledgement checkbox.
/// All three verification factors must pass before the red action unlocks,
/// then the password is verified via `PATCH /api/auth/change-password` and
/// `DELETE /api/auth/me` is called before the session is destroyed.
class InvestorDeleteAccountScreen extends ConsumerStatefulWidget {
  const InvestorDeleteAccountScreen({super.key});

  @override
  ConsumerState<InvestorDeleteAccountScreen> createState() =>
      _InvestorDeleteAccountScreenState();
}

class _InvestorDeleteAccountScreenState
    extends ConsumerState<InvestorDeleteAccountScreen> {
  static const Color _danger = Color(0xFFEF4444);
  static const Color _dangerDeep = Color(0xFFDC2626);
  static const String _confirmWord = 'DELETE';

  final TextEditingController _confirmCtrl = TextEditingController();
  final TextEditingController _passCtrl = TextEditingController();

  bool _obscurePass = true;
  bool _acknowledged = false;
  bool _submitting = false;

  // What the purge erases (mirrors the web investor purge-scope list).
  static const List<Map<String, dynamic>> _purgeScope = [
    {
      'icon': LucideIcons.building2,
      'title': 'INSTITUTIONAL BOOKINGS',
      'subtitle': 'All institutional property bookings',
    },
    {
      'icon': LucideIcons.mapPin,
      'title': 'SITE VISIT LOGS',
      'subtitle': 'Historical site visit records',
    },
    {
      'icon': LucideIcons.fileText,
      'title': 'LEGAL DOCUMENTS',
      'subtitle': 'Legal documents & receipts',
    },
    {
      'icon': LucideIcons.sliders,
      'title': 'PLATFORM CUSTOMIZATIONS',
      'subtitle': 'Saved preferences & customizations',
    },
    {
      'icon': LucideIcons.userX,
      'title': 'PERSONAL IDENTITY',
      'subtitle': 'Personal identity data & profile',
    },
  ];

  @override
  void dispose() {
    _confirmCtrl.dispose();
    _passCtrl.dispose();
    super.dispose();
  }

  bool get _confirmMatches => _confirmCtrl.text.trim() == _confirmWord;
  bool get _passProvided => _passCtrl.text.isNotEmpty;
  bool get _canSubmit =>
      _confirmMatches && _passProvided && _acknowledged && !_submitting;

  void _snack(String msg, {bool error = false}) {
    if (!mounted) return;
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content:
            Text(msg, style: GoogleFonts.montserrat(fontWeight: FontWeight.w600)),
        backgroundColor: error ? _dangerDeep : Colors.green,
      ),
    );
  }

  Future<void> _handleDelete() async {
    if (!_canSubmit) return;

    final go = await showDialog<bool>(
      context: context,
      builder: (ctx) {
        final isDark = Theme.of(ctx).brightness == Brightness.dark;
        return AlertDialog(
          backgroundColor: isDark ? Colors.black : Colors.white,
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(24)),
          title: Text(
            'FINAL CONFIRMATION',
            style: GoogleFonts.montserrat(
              fontSize: 13,
              fontWeight: FontWeight.w900,
              letterSpacing: 1.2,
              color: _danger,
            ),
          ),
          content: Text(
            'This permanently purges your investor account and your entire '
            'digital legacy within M4. This action cannot be undone.',
            style: GoogleFonts.montserrat(
              fontSize: 12,
              fontWeight: FontWeight.w500,
              color:
                  (isDark ? Colors.white : Colors.black).withValues(alpha: 0.7),
            ),
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.pop(ctx, false),
              child: Text(
                'CANCEL',
                style: GoogleFonts.montserrat(
                  fontSize: 10,
                  fontWeight: FontWeight.w800,
                  color: (isDark ? Colors.white : Colors.black)
                      .withValues(alpha: 0.6),
                ),
              ),
            ),
            FilledButton(
              onPressed: () => Navigator.pop(ctx, true),
              style: FilledButton.styleFrom(
                backgroundColor: _dangerDeep,
                shape:
                    RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
              ),
              child: Text(
                'EXECUTE PURGE',
                style: GoogleFonts.montserrat(
                  fontSize: 10,
                  fontWeight: FontWeight.w900,
                  letterSpacing: 1,
                  color: Colors.white,
                ),
              ),
            ),
          ],
        );
      },
    );

    if (go != true || !mounted) return;

    setState(() => _submitting = true);
    try {
      final apiClient = ref.read(apiClientProvider);

      // First verify the supplied password is correct (web parity:
      // PATCH /auth/change-password with the same password to validate).
      try {
        await apiClient.changePassword(
          currentPassword: _passCtrl.text,
          newPassword: _passCtrl.text,
        );
      } on DioException catch (e) {
        final m = e.response?.data is Map
            ? (e.response!.data as Map)['message']?.toString()
            : null;
        if (!mounted) return;
        _snack(m ?? 'Password verification failed', error: true);
        setState(() => _submitting = false);
        return;
      }

      final res = await apiClient.deleteMe();
      if (!mounted) return;
      final ok = res.data is Map && (res.data as Map)['status'] == true;
      if (ok) {
        await ref.read(authProvider.notifier).logout();
        if (!mounted) return;
        _snack('Account deactivated successfully');
        context.go('/investor/login');
      } else {
        final msg =
            res.data is Map ? (res.data as Map)['message']?.toString() : null;
        _snack(msg ?? 'Failed to deactivate account', error: true);
      }
    } on DioException catch (e) {
      final m = e.response?.data is Map
          ? (e.response!.data as Map)['message']?.toString()
          : null;
      _snack(m ?? e.message ?? 'Network error', error: true);
    } catch (e) {
      _snack('An error occurred. Please try again.', error: true);
    } finally {
      if (mounted) setState(() => _submitting = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final bg = isDark ? Colors.black : Colors.white;
    final textPrimary = isDark ? Colors.white : Colors.black;
    final muted = (isDark ? Colors.white : Colors.black).withValues(alpha: 0.5);
    final card = isDark ? Colors.white.withValues(alpha: 0.03) : Colors.white;
    final border = isDark
        ? Colors.white.withValues(alpha: 0.08)
        : Colors.black.withValues(alpha: 0.06);

    return Scaffold(
      backgroundColor: bg,
      body: SafeArea(
        child: Column(
          children: [
            _header(textPrimary, muted),
            Expanded(
              child: SingleChildScrollView(
                physics: const AlwaysScrollableScrollPhysics(),
                padding: const EdgeInsets.fromLTRB(24, 12, 24, 48),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.stretch,
                  children: [
                    _criticalWarning(),
                    const SizedBox(height: 28),
                    _sectionLabel('PURGE SCOPE', muted),
                    const SizedBox(height: 14),
                    _purgeScopeCard(card, border, textPrimary, muted),
                    const SizedBox(height: 28),
                    _sectionLabel('MULTI-FACTOR VERIFICATION', muted),
                    const SizedBox(height: 14),
                    _confirmField(card, border, textPrimary, muted),
                    const SizedBox(height: 16),
                    _passwordField(card, border, textPrimary, muted),
                    const SizedBox(height: 20),
                    _acknowledgeRow(border, textPrimary, muted),
                    const SizedBox(height: 28),
                    _deleteButton(),
                    const SizedBox(height: 16),
                    _cancelButton(muted),
                  ],
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  // ── Header ─────────────────────────────────────────────────────────────
  Widget _header(Color textPrimary, Color muted) {
    return Padding(
      padding: const EdgeInsets.fromLTRB(20, 18, 20, 18),
      child: Row(
        children: [
          GestureDetector(
            onTap: () {
              if (context.canPop()) {
                context.pop();
              } else {
                context.go('/investor/profile');
              }
            },
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
            child: Column(
              children: [
                Text(
                  'DEACTIVATE',
                  textAlign: TextAlign.center,
                  style: GoogleFonts.montserrat(
                    fontSize: 16,
                    fontWeight: FontWeight.w900,
                    letterSpacing: 1.5,
                    color: _danger,
                  ),
                ),
                const SizedBox(height: 2),
                Text(
                  'PURGE PROTOCOL',
                  textAlign: TextAlign.center,
                  style: GoogleFonts.montserrat(
                    fontSize: 8,
                    fontWeight: FontWeight.w900,
                    letterSpacing: 2,
                    color: muted,
                  ),
                ),
              ],
            ),
          ),
          const SizedBox(width: 36),
        ],
      ),
    );
  }

  // ── Critical warning ───────────────────────────────────────────────────
  Widget _criticalWarning() {
    return Container(
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: _danger.withValues(alpha: 0.08),
        borderRadius: BorderRadius.circular(24),
        border: Border.all(color: _danger.withValues(alpha: 0.3)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Container(
                padding: const EdgeInsets.all(10),
                decoration: BoxDecoration(
                  color: _danger.withValues(alpha: 0.15),
                  borderRadius: BorderRadius.circular(14),
                ),
                child: const Icon(LucideIcons.alertTriangle,
                    size: 20, color: _danger),
              ),
              const SizedBox(width: 14),
              Expanded(
                child: Text(
                  'CRITICAL WARNING',
                  style: GoogleFonts.montserrat(
                    fontSize: 12,
                    fontWeight: FontWeight.w900,
                    letterSpacing: 1.5,
                    color: _danger,
                  ),
                ),
              ),
            ],
          ),
          const SizedBox(height: 14),
          Text(
            'Final action. All institutional ties, documents, and historical '
            'data will be permanently purged. This cannot be reversed and you '
            'will be signed out of every device.',
            style: GoogleFonts.montserrat(
              fontSize: 12,
              height: 1.55,
              fontWeight: FontWeight.w500,
              color: _danger.withValues(alpha: 0.85),
            ),
          ),
        ],
      ),
    );
  }

  // ── Section label ──────────────────────────────────────────────────────
  Widget _sectionLabel(String text, Color muted) {
    return Text(
      text,
      style: GoogleFonts.montserrat(
        fontSize: 9,
        fontWeight: FontWeight.w900,
        letterSpacing: 2,
        color: muted,
      ),
    );
  }

  // ── Purge scope list ───────────────────────────────────────────────────
  Widget _purgeScopeCard(
      Color card, Color border, Color textPrimary, Color muted) {
    return Container(
      decoration: BoxDecoration(
        color: card,
        borderRadius: BorderRadius.circular(24),
        border: Border.all(color: border),
      ),
      child: Column(
        children: [
          for (int i = 0; i < _purgeScope.length; i++) ...[
            Padding(
              padding: const EdgeInsets.all(18),
              child: Row(
                children: [
                  Container(
                    padding: const EdgeInsets.all(10),
                    decoration: BoxDecoration(
                      color: _danger.withValues(alpha: 0.1),
                      borderRadius: BorderRadius.circular(12),
                    ),
                    child: Icon(
                      _purgeScope[i]['icon'] as IconData,
                      size: 18,
                      color: _danger,
                    ),
                  ),
                  const SizedBox(width: 16),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          _purgeScope[i]['title'] as String,
                          style: GoogleFonts.montserrat(
                            fontSize: 12,
                            fontWeight: FontWeight.w800,
                            color: textPrimary,
                          ),
                        ),
                        const SizedBox(height: 3),
                        Text(
                          _purgeScope[i]['subtitle'] as String,
                          style: GoogleFonts.montserrat(
                            fontSize: 10,
                            fontWeight: FontWeight.w500,
                            height: 1.3,
                            color: muted,
                          ),
                        ),
                      ],
                    ),
                  ),
                  Icon(LucideIcons.x,
                      size: 16, color: _danger.withValues(alpha: 0.6)),
                ],
              ),
            ),
            if (i != _purgeScope.length - 1)
              Divider(height: 1, thickness: 1, color: border),
          ],
        ],
      ),
    );
  }

  // ── Type-DELETE confirmation ───────────────────────────────────────────
  Widget _confirmField(
      Color card, Color border, Color textPrimary, Color muted) {
    final ok = _confirmMatches;
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Padding(
          padding: const EdgeInsets.only(left: 4, bottom: 8),
          child: Text(
            'TYPE "$_confirmWord" TO CONFIRM',
            style: GoogleFonts.montserrat(
              fontSize: 9,
              fontWeight: FontWeight.w800,
              letterSpacing: 1.5,
              color: muted,
            ),
          ),
        ),
        Container(
          decoration: BoxDecoration(
            color: card,
            borderRadius: BorderRadius.circular(16),
            border: Border.all(
              color: _confirmCtrl.text.isEmpty
                  ? border
                  : (ok ? Colors.green : _danger).withValues(alpha: 0.6),
              width: _confirmCtrl.text.isEmpty ? 1 : 1.5,
            ),
          ),
          child: TextField(
            controller: _confirmCtrl,
            onChanged: (_) => setState(() {}),
            textCapitalization: TextCapitalization.characters,
            style: GoogleFonts.montserrat(
              fontSize: 16,
              fontWeight: FontWeight.w800,
              letterSpacing: 3,
              color: textPrimary,
            ),
            decoration: InputDecoration(
              hintText: _confirmWord,
              hintStyle: GoogleFonts.montserrat(
                fontSize: 16,
                fontWeight: FontWeight.w800,
                letterSpacing: 3,
                color: muted.withValues(alpha: 0.4),
              ),
              border: InputBorder.none,
              contentPadding:
                  const EdgeInsets.symmetric(horizontal: 18, vertical: 16),
              suffixIcon: _confirmCtrl.text.isEmpty
                  ? null
                  : Icon(
                      ok ? LucideIcons.checkCircle2 : LucideIcons.xCircle,
                      size: 18,
                      color: ok ? Colors.green : _danger,
                    ),
            ),
          ),
        ),
      ],
    );
  }

  // ── Password credential authorization ──────────────────────────────────
  Widget _passwordField(
      Color card, Color border, Color textPrimary, Color muted) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Padding(
          padding: const EdgeInsets.only(left: 4, bottom: 8),
          child: Text(
            'CREDENTIAL AUTHORIZATION',
            style: GoogleFonts.montserrat(
              fontSize: 9,
              fontWeight: FontWeight.w800,
              letterSpacing: 1.5,
              color: muted,
            ),
          ),
        ),
        Container(
          decoration: BoxDecoration(
            color: card,
            borderRadius: BorderRadius.circular(16),
            border: Border.all(color: border),
          ),
          child: TextField(
            controller: _passCtrl,
            obscureText: _obscurePass,
            onChanged: (_) => setState(() {}),
            style: GoogleFonts.montserrat(
              fontSize: 14,
              fontWeight: FontWeight.w700,
              color: textPrimary,
            ),
            decoration: InputDecoration(
              hintText: '••••••••',
              hintStyle: GoogleFonts.montserrat(
                fontSize: 14,
                fontWeight: FontWeight.w700,
                color: muted.withValues(alpha: 0.4),
              ),
              border: InputBorder.none,
              contentPadding:
                  const EdgeInsets.symmetric(horizontal: 18, vertical: 16),
              prefixIcon: Icon(LucideIcons.lock, size: 16, color: muted),
              suffixIcon: GestureDetector(
                onTap: () => setState(() => _obscurePass = !_obscurePass),
                child: Icon(
                  _obscurePass ? LucideIcons.eye : LucideIcons.eyeOff,
                  size: 16,
                  color: muted,
                ),
              ),
            ),
          ),
        ),
      ],
    );
  }

  // ── Acknowledgement ────────────────────────────────────────────────────
  Widget _acknowledgeRow(Color border, Color textPrimary, Color muted) {
    return GestureDetector(
      onTap: () => setState(() => _acknowledged = !_acknowledged),
      child: Container(
        padding: const EdgeInsets.all(16),
        decoration: BoxDecoration(
          color:
              _acknowledged ? _danger.withValues(alpha: 0.06) : Colors.transparent,
          borderRadius: BorderRadius.circular(16),
          border: Border.all(
            color: _acknowledged ? _danger.withValues(alpha: 0.4) : border,
          ),
        ),
        child: Row(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            AnimatedContainer(
              duration: const Duration(milliseconds: 150),
              width: 22,
              height: 22,
              decoration: BoxDecoration(
                color: _acknowledged ? _dangerDeep : Colors.transparent,
                borderRadius: BorderRadius.circular(6),
                border: Border.all(
                  color: _acknowledged ? _dangerDeep : muted,
                  width: 1.5,
                ),
              ),
              child: _acknowledged
                  ? const Icon(LucideIcons.check, size: 14, color: Colors.white)
                  : null,
            ),
            const SizedBox(width: 14),
            Expanded(
              child: Text(
                'I acknowledge that this protocol will erase my entire digital '
                'legacy within M4. Final & irreversible.',
                style: GoogleFonts.montserrat(
                  fontSize: 11,
                  height: 1.5,
                  fontWeight: FontWeight.w500,
                  color: textPrimary.withValues(alpha: 0.8),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  // ── Delete button ──────────────────────────────────────────────────────
  Widget _deleteButton() {
    return GestureDetector(
      onTap: _canSubmit ? _handleDelete : null,
      child: Opacity(
        opacity: _canSubmit ? 1.0 : 0.35,
        child: Container(
          width: double.infinity,
          height: 56,
          decoration: BoxDecoration(
            color: _dangerDeep,
            borderRadius: BorderRadius.circular(16),
            boxShadow: _canSubmit
                ? [
                    BoxShadow(
                      color: _dangerDeep.withValues(alpha: 0.4),
                      blurRadius: 18,
                      offset: const Offset(0, 8),
                    ),
                  ]
                : null,
          ),
          alignment: Alignment.center,
          child: _submitting
              ? const SizedBox(
                  width: 22,
                  height: 22,
                  child: CircularProgressIndicator(
                      strokeWidth: 2, color: Colors.white),
                )
              : Row(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    const Icon(LucideIcons.trash2,
                        color: Colors.white, size: 16),
                    const SizedBox(width: 12),
                    Text(
                      'EXECUTE PURGE',
                      style: GoogleFonts.montserrat(
                        fontSize: 11,
                        fontWeight: FontWeight.w900,
                        letterSpacing: 1.5,
                        color: Colors.white,
                      ),
                    ),
                  ],
                ),
        ),
      ),
    );
  }

  // ── Cancel button ──────────────────────────────────────────────────────
  Widget _cancelButton(Color muted) {
    return Center(
      child: TextButton(
        onPressed: _submitting
            ? null
            : () {
                if (context.canPop()) {
                  context.pop();
                } else {
                  context.go('/investor/profile');
                }
              },
        child: Text(
          'ABORT PROTOCOL',
          style: GoogleFonts.montserrat(
            fontSize: 10,
            fontWeight: FontWeight.w900,
            letterSpacing: 2,
            color: muted,
          ),
        ),
      ),
    );
  }
}
