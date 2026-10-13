import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:lucide_icons/lucide_icons.dart';
import 'package:m4_mobile/presentation/providers/auth_provider.dart';

/// Investor "Set New Password" — the forced first-login step when an admin
/// issued a temporary key (backend returns `firstLoginRequired: true`).
///
/// Per the backend spec ("Investor Login & Reset Flow"):
///  * fields are only New Password + Confirm (no current/temporary key — the
///    server does not need it);
///  * only the 8-character minimum is enforced (uppercase/number/symbol are
///    shown as hints, not enforced);
///  * it is a DEAD-END screen: no bottom nav or drawer, and Back discards the
///    in-memory token and returns to Login — it must never reveal the portal.
///    The token is never saved, so closing the app here reopens on Login;
///  * on success the token is discarded and the investor logs in AGAIN with the
///    new password (which then returns `firstLoginRequired: false`).
class InvestorSetPasswordScreen extends ConsumerStatefulWidget {
  const InvestorSetPasswordScreen({super.key});

  @override
  ConsumerState<InvestorSetPasswordScreen> createState() =>
      _InvestorSetPasswordScreenState();
}

class _InvestorSetPasswordScreenState
    extends ConsumerState<InvestorSetPasswordScreen> {
  // App deep-green accent (no gold/yellow on this screen).
  static const _accent = Color(0xFF0C312B);
  static const _cream = Color(0xFFF4EFE3);

  final _newPass = TextEditingController();
  final _confirm = TextEditingController();

  bool _showNew = false;
  bool _submitting = false;

  @override
  void dispose() {
    _newPass.dispose();
    _confirm.dispose();
    super.dispose();
  }

  // Hints shown to the user; only the 8-char minimum is enforced (spec).
  bool get _hasMinLength => _newPass.text.length >= 8;
  bool get _hasUppercase => RegExp(r'[A-Z]').hasMatch(_newPass.text);
  bool get _hasNumber => RegExp(r'[0-9]').hasMatch(_newPass.text);
  bool get _hasSpecial => RegExp(
    r'''[!@#$%^&*(),.?":{}|<>_\-\[\]\\/;'`~+=]''',
  ).hasMatch(_newPass.text);

  int get _strength {
    var score = 0;
    if (_hasMinLength) score++;
    if (_hasUppercase) score++;
    if (_hasNumber) score++;
    if (_hasSpecial) score++;
    return score;
  }

  String get _strengthLabel {
    switch (_strength) {
      case 0:
      case 1:
        return 'WEAK';
      case 2:
        return 'FAIR';
      case 3:
        return 'STRONG';
      default:
        return 'ELITE';
    }
  }

  Color get _strengthColor {
    switch (_strength) {
      case 0:
      case 1:
        return const Color(0xFFC65B46);
      case 2:
        return const Color(0xFF5B7A52);
      case 3:
        return const Color(0xFF163A2C);
      default:
        return _accent;
    }
  }

  void _snack(String msg, {bool error = false}) {
    if (!mounted) return;
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(msg),
        backgroundColor: error ? Colors.redAccent : Colors.green,
      ),
    );
  }

  /// Dead-end exit: discard the in-memory token and return to Login. Never
  /// reveals the portal.
  void _exitToLogin() {
    ref.read(authProvider.notifier).cancelFirstLogin();
    context.go('/investor/login');
  }

  Future<void> _submit() async {
    if (_submitting) return;

    // Spec validation order and messages.
    if (_newPass.text.isEmpty || _confirm.text.isEmpty) {
      _snack('Please fill in all fields', error: true);
      return;
    }
    if (_newPass.text != _confirm.text) {
      _snack('Security keys do not match', error: true);
      return;
    }
    if (!_hasMinLength) {
      _snack('Key too short: Minimum 8 characters required', error: true);
      return;
    }

    setState(() => _submitting = true);
    final err = await ref
        .read(authProvider.notifier)
        .completeFirstLoginPassword(_newPass.text);
    if (!mounted) return;
    setState(() => _submitting = false);

    if (err != null) {
      _snack(err, error: true);
      return;
    }
    // Success: token discarded. The investor logs in again with the new key.
    _snack('Security key established. Please sign in with your new key.');
    _newPass.clear();
    _confirm.clear();
    await Future.delayed(const Duration(milliseconds: 900));
    if (!mounted) return;
    context.go('/investor/login');
  }

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final bg = isDark ? Colors.black : const Color(0xFFD4CFBC);
    final textPrimary = isDark ? Colors.white : const Color(0xFF0C312B);
    final muted = (isDark ? Colors.white : const Color(0xFF0C312B)).withValues(
      alpha: 0.5,
    );
    final card = isDark
        ? Colors.white.withValues(alpha: 0.03)
        : const Color(0xFFF4EFE3);
    final border = isDark
        ? Colors.white.withValues(alpha: 0.08)
        : Colors.black.withValues(alpha: 0.06);

    // Dead-end: intercept the system back gesture and route it through the
    // controlled exit (discard token → Login) instead of popping to the portal.
    return PopScope(
      canPop: false,
      onPopInvokedWithResult: (didPop, _) {
        if (!didPop) _exitToLogin();
      },
      child: Scaffold(
        backgroundColor: bg,
        body: SafeArea(
          bottom: false,
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.stretch,
                children: [
                  _header(textPrimary, muted, border),
                  Expanded(
                    child: SingleChildScrollView(
                      padding: const EdgeInsets.fromLTRB(24, 24, 24, 48),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.stretch,
                        children: [
                          _noticeCard(textPrimary),
                          const SizedBox(height: 24),

                          _fieldLabel('NEW PASSWORD', muted),
                          const SizedBox(height: 8),
                          _passwordField(
                            controller: _newPass,
                            hint: 'Enter New Password',
                            obscure: !_showNew,
                            onToggle: () => setState(() => _showNew = !_showNew),
                            onChanged: (_) => setState(() {}),
                            textPrimary: textPrimary,
                            muted: muted,
                            card: card,
                            border: border,
                          ),

                          if (_newPass.text.isNotEmpty) ...[
                            const SizedBox(height: 12),
                            _strengthBar(border),
                          ],

                          const SizedBox(height: 16),

                          _fieldLabel('CONFIRM NEW PASSWORD', muted),
                          const SizedBox(height: 8),
                          _passwordField(
                            controller: _confirm,
                            hint: 'Confirm New Password',
                            obscure: !_showNew,
                            showToggle: false,
                            onChanged: (_) => setState(() {}),
                            textPrimary: textPrimary,
                            muted: muted,
                            card: card,
                            border: border,
                          ),

                          if (_confirm.text.isNotEmpty) ...[
                            const SizedBox(height: 8),
                            _matchFeedback(),
                          ],

                          const SizedBox(height: 24),
                          _requirements(muted),
                          const SizedBox(height: 28),
                          _submitButton(),
                          const SizedBox(height: 16),
                          Center(
                            child: GestureDetector(
                              onTap: _submitting ? null : _exitToLogin,
                              child: Container(
                                padding: const EdgeInsets.symmetric(
                                  horizontal: 22,
                                  vertical: 12,
                                ),
                                decoration: BoxDecoration(
                                  color: _accent.withValues(alpha: 0.06),
                                  borderRadius: BorderRadius.circular(12),
                                  border: Border.all(
                                    color: _accent.withValues(alpha: 0.35),
                                  ),
                                ),
                                child: Text(
                                  'Cancel and return to login',
                                  style: GoogleFonts.inter(
                                    fontSize: 13,
                                    fontWeight: FontWeight.w700,
                                    color: _accent,
                                  ),
                                ),
                              ),
                            ),
                          ),
                          const SizedBox(height: 40),
                        ],
                      ),
                    ),
                  ),
                ],
              ),
            ),
      ),
    );
  }

  Widget _header(Color textPrimary, Color muted, Color border) {
    return Container(
      padding: const EdgeInsets.fromLTRB(16, 16, 24, 16),
      decoration: BoxDecoration(
        border: Border(bottom: BorderSide(color: border)),
      ),
      child: Row(
        children: [
          GestureDetector(
            onTap: _exitToLogin,
            child: Container(
              padding: const EdgeInsets.all(10),
              decoration: BoxDecoration(
                color: textPrimary.withValues(alpha: 0.05),
                shape: BoxShape.circle,
                border: Border.all(color: border),
              ),
              child: Icon(LucideIcons.arrowLeft, size: 16, color: textPrimary),
            ),
          ),
          const SizedBox(width: 16),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  'SECURITY SETTINGS',
                  style: GoogleFonts.gelasio(
                    fontSize: 10,
                    fontWeight: FontWeight.w700,
                    letterSpacing: 2.5,
                    color: _accent.withValues(alpha: 0.8),
                  ),
                ),
                const SizedBox(height: 4),
                Text(
                  'Set New Password',
                  style: GoogleFonts.gelasio(
                    fontSize: 18,
                    fontWeight: FontWeight.w700,
                    letterSpacing: -0.3,
                    color: textPrimary,
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _noticeCard(Color textPrimary) {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: _accent.withValues(alpha: 0.06),
        borderRadius: BorderRadius.circular(14),
        border: Border.all(color: _accent.withValues(alpha: 0.2)),
      ),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Icon(LucideIcons.shieldCheck, size: 18, color: _accent),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  'SECURITY UPDATE REQUIRED',
                  style: GoogleFonts.gelasio(
                    fontSize: 11,
                    fontWeight: FontWeight.w700,
                    letterSpacing: 1.2,
                    color: _accent,
                  ),
                ),
                const SizedBox(height: 4),
                Text(
                  'Please establish a permanent security key before accessing '
                  'your portal.',
                  style: GoogleFonts.inter(
                    fontSize: 12,
                    height: 1.5,
                    fontWeight: FontWeight.w500,
                    color: textPrimary.withValues(alpha: 0.75),
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _fieldLabel(String label, Color muted) {
    return Padding(
      padding: const EdgeInsets.only(left: 4),
      child: Text(
        label,
        style: GoogleFonts.gelasio(
          fontSize: 10,
          fontWeight: FontWeight.w700,
          letterSpacing: 2,
          color: muted,
        ),
      ),
    );
  }

  Widget _passwordField({
    required TextEditingController controller,
    required String hint,
    required bool obscure,
    required Color textPrimary,
    required Color muted,
    required Color card,
    required Color border,
    VoidCallback? onToggle,
    ValueChanged<String>? onChanged,
    bool showToggle = true,
  }) {
    return TextField(
      controller: controller,
      obscureText: obscure,
      onChanged: onChanged,
      style: GoogleFonts.inter(
        fontSize: 15,
        fontWeight: FontWeight.w600,
        color: textPrimary,
      ),
      decoration: InputDecoration(
        hintText: hint,
        hintStyle: GoogleFonts.inter(
          fontSize: 13,
          fontWeight: FontWeight.w600,
          color: muted,
        ),
        filled: true,
        fillColor: card,
        isDense: true,
        contentPadding: const EdgeInsets.symmetric(
          horizontal: 12,
          vertical: 16,
        ),
        prefixIcon: Icon(LucideIcons.lock, size: 16, color: muted),
        suffixIcon: showToggle
            ? IconButton(
                onPressed: onToggle,
                icon: Icon(
                  obscure ? LucideIcons.eye : LucideIcons.eyeOff,
                  size: 16,
                  color: muted,
                ),
              )
            : null,
        border: OutlineInputBorder(
          borderRadius: BorderRadius.circular(14),
          borderSide: BorderSide(color: border),
        ),
        enabledBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(14),
          borderSide: BorderSide(color: border),
        ),
        focusedBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(14),
          borderSide: BorderSide(color: _accent.withValues(alpha: 0.5)),
        ),
      ),
    );
  }

  Widget _strengthBar(Color border) {
    final color = _strengthColor;
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 4),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: List.generate(4, (i) {
              final active = i < _strength;
              return Expanded(
                child: Container(
                  height: 4,
                  margin: EdgeInsets.only(right: i < 3 ? 6 : 0),
                  decoration: BoxDecoration(
                    borderRadius: BorderRadius.circular(100),
                    color: active ? color : border,
                  ),
                ),
              );
            }),
          ),
          const SizedBox(height: 6),
          Text(
            'STRENGTH: $_strengthLabel',
            style: GoogleFonts.gelasio(
              fontSize: 11,
              fontWeight: FontWeight.w700,
              letterSpacing: 1.5,
              color: color,
            ),
          ),
        ],
      ),
    );
  }

  Widget _matchFeedback() {
    final matches = _confirm.text == _newPass.text && _newPass.text.isNotEmpty;
    const green = Color(0xFF163A2C);
    const red = Color(0xFFC65B46);
    return Padding(
      padding: const EdgeInsets.only(left: 4),
      child: Row(
        children: [
          Icon(
            matches ? LucideIcons.checkCircle2 : LucideIcons.xCircle,
            size: 13,
            color: matches ? green : red,
          ),
          const SizedBox(width: 6),
          Text(
            matches ? 'Keys match' : 'Keys do not match',
            style: GoogleFonts.inter(
              fontSize: 10,
              fontWeight: FontWeight.w600,
              color: matches ? green : red,
            ),
          ),
        ],
      ),
    );
  }

  Widget _requirements(Color muted) {
    final items = <MapEntry<String, bool>>[
      MapEntry('At least 8 characters long', _hasMinLength),
      MapEntry('Contains one uppercase letter (recommended)', _hasUppercase),
      MapEntry('Contains one number (recommended)', _hasNumber),
      MapEntry('Contains one special character (recommended)', _hasSpecial),
    ];

    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: _accent.withValues(alpha: 0.05),
        borderRadius: BorderRadius.circular(14),
        border: Border.all(color: _accent.withValues(alpha: 0.12)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Icon(
                LucideIcons.alertCircle,
                size: 14,
                color: _accent.withValues(alpha: 0.7),
              ),
              const SizedBox(width: 8),
              Text(
                'REQUIREMENTS',
                style: GoogleFonts.gelasio(
                  fontSize: 10,
                  fontWeight: FontWeight.w700,
                  letterSpacing: 1.5,
                  color: _accent.withValues(alpha: 0.7),
                ),
              ),
            ],
          ),
          const SizedBox(height: 10),
          ...items.map((e) => _requirementRow(e.key, e.value, muted)),
        ],
      ),
    );
  }

  Widget _requirementRow(String label, bool met, Color muted) {
    const green = Color(0xFF163A2C);
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 3),
      child: Row(
        children: [
          met
              ? const Icon(LucideIcons.checkCircle2, size: 13, color: green)
              : Container(
                  width: 13,
                  height: 13,
                  alignment: Alignment.center,
                  child: Container(
                    width: 4,
                    height: 4,
                    decoration: BoxDecoration(
                      shape: BoxShape.circle,
                      color: muted.withValues(alpha: 0.6),
                    ),
                  ),
                ),
          const SizedBox(width: 8),
          Expanded(
            child: Text(
              label,
              style: GoogleFonts.inter(
                fontSize: 10,
                fontWeight: FontWeight.w600,
                color: met ? green : muted,
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _submitButton() {
    return GestureDetector(
      onTap: _submitting ? null : _submit,
      child: Opacity(
        opacity: _submitting ? 0.6 : 1.0,
        child: Container(
          width: double.infinity,
          height: 54,
          decoration: BoxDecoration(
            color: _accent,
            borderRadius: BorderRadius.circular(14),
            boxShadow: [
              BoxShadow(
                color: _accent.withValues(alpha: 0.3),
                blurRadius: 16,
                offset: const Offset(0, 8),
              ),
            ],
          ),
          alignment: Alignment.center,
          child: _submitting
              ? const SizedBox(
                  width: 20,
                  height: 20,
                  child: CircularProgressIndicator.adaptive(
                    strokeWidth: 2,
                    valueColor: AlwaysStoppedAnimation<Color>(_cream),
                  ),
                )
              : Text(
                  'UPDATE PASSWORD',
                  style: GoogleFonts.gelasio(
                    fontSize: 12,
                    fontWeight: FontWeight.w700,
                    letterSpacing: 2,
                    color: _cream,
                  ),
                ),
        ),
      ),
    );
  }
}
