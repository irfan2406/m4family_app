import 'package:dio/dio.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:lucide_icons/lucide_icons.dart';
import 'package:m4_mobile/core/theme/app_theme.dart';
import 'package:m4_mobile/presentation/providers/auth_provider.dart';

/// Investor Change Password — parity with web `app/investor/change-password/page.tsx`.
///
/// Mirrors the web prototype: current / new / confirm key fields with a live
/// requirements checklist (8+ chars, uppercase, number, special char) and a
/// strength indicator. Submits to `PATCH /auth/change-password` via
/// [ApiClient.changePassword]. Adapts the institutional "security key" copy and
/// uses the investor gold accent. Follows M4 conventions.
class InvestorChangePasswordScreen extends ConsumerStatefulWidget {
  const InvestorChangePasswordScreen({super.key});

  @override
  ConsumerState<InvestorChangePasswordScreen> createState() =>
      _InvestorChangePasswordScreenState();
}

class _InvestorChangePasswordScreenState
    extends ConsumerState<InvestorChangePasswordScreen> {
  static const _gold = Color(0xFFFFD700);

  final _current = TextEditingController();
  final _newPass = TextEditingController();
  final _confirm = TextEditingController();

  bool _showCurrent = false;
  bool _showNew = false;
  bool _submitting = false;

  @override
  void dispose() {
    _current.dispose();
    _newPass.dispose();
    _confirm.dispose();
    super.dispose();
  }

  // ─── Web validation parity ──────────────────────────────────────────
  bool get _hasMinLength => _newPass.text.length >= 8;
  bool get _hasUppercase => RegExp(r'[A-Z]').hasMatch(_newPass.text);
  bool get _hasNumber => RegExp(r'[0-9]').hasMatch(_newPass.text);
  bool get _hasSpecial => RegExp(
          r'''[!@#$%^&*(),.?":{}|<>_\-\[\]\\/;'`~+=]''')
      .hasMatch(_newPass.text);

  /// 0..4 strength score derived from the requirements checklist.
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
        return const Color(0xFFEF4444);
      case 2:
        return const Color(0xFFF59E0B);
      case 3:
        return const Color(0xFF10B981);
      default:
        return _gold;
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

  void _back() {
    if (context.canPop()) {
      context.pop();
    } else {
      context.go('/investor/home');
    }
  }

  Future<void> _submit() async {
    if (_submitting) return;

    if (_current.text.isEmpty ||
        _newPass.text.isEmpty ||
        _confirm.text.isEmpty) {
      _snack('Please fill in all fields', error: true);
      return;
    }
    if (_newPass.text != _confirm.text) {
      _snack('Security keys do not match', error: true);
      return;
    }
    if (!_hasMinLength) {
      _snack('Password must be at least 8 characters', error: true);
      return;
    }
    if (!_hasUppercase || !_hasNumber || !_hasSpecial) {
      _snack(
        'Password must include an uppercase letter, a number and a special character',
        error: true,
      );
      return;
    }

    setState(() => _submitting = true);
    try {
      final res = await ref.read(apiClientProvider).changePassword(
            currentPassword: _current.text,
            newPassword: _newPass.text,
          );
      if (!mounted) return;
      final ok = res.data is Map && (res.data as Map)['status'] == true;
      if (ok) {
        _snack('Security key established successfully');
        _current.clear();
        _newPass.clear();
        _confirm.clear();
        await Future.delayed(const Duration(milliseconds: 800));
        if (!mounted) return;
        _back();
      } else {
        final msg =
            res.data is Map ? (res.data as Map)['message']?.toString() : null;
        _snack(msg ?? 'Failed to update password', error: true);
      }
    } on DioException catch (e) {
      final m = e.response?.data is Map
          ? (e.response!.data as Map)['message']?.toString()
          : null;
      _snack(m ?? e.message ?? 'Error updating password', error: true);
    } catch (e) {
      _snack('Error updating password', error: true);
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
      body: Stack(
        children: [
          // Ambient background glows (mirrors web WealthModeLayout).
          _ambient(),
          SafeArea(
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
                        // Current / temporary key
                        _fieldLabel('CURRENT OR TEMPORARY KEY', muted),
                        const SizedBox(height: 8),
                        _passwordField(
                          controller: _current,
                          hint: 'Enter your current or temporary key',
                          obscure: !_showCurrent,
                          onToggle: () =>
                              setState(() => _showCurrent = !_showCurrent),
                          textPrimary: textPrimary,
                          muted: muted,
                          card: card,
                          border: border,
                        ),

                        const SizedBox(height: 24),
                        Container(height: 1, color: border),
                        const SizedBox(height: 24),

                        // New password
                        _fieldLabel('NEW PASSWORD', muted),
                        const SizedBox(height: 8),
                        _passwordField(
                          controller: _newPass,
                          hint: 'Enter new password',
                          obscure: !_showNew,
                          onToggle: () => setState(() => _showNew = !_showNew),
                          onChanged: (_) => setState(() {}),
                          textPrimary: textPrimary,
                          muted: muted,
                          card: card,
                          border: border,
                        ),

                        // Strength indicator (only once typing begins).
                        if (_newPass.text.isNotEmpty) ...[
                          const SizedBox(height: 12),
                          _strengthBar(muted, border),
                        ],

                        const SizedBox(height: 16),

                        // Confirm password (shares show/hide with new password).
                        _fieldLabel('CONFIRM NEW PASSWORD', muted),
                        const SizedBox(height: 8),
                        _passwordField(
                          controller: _confirm,
                          hint: 'Re-enter new password',
                          obscure: !_showNew,
                          showToggle: false,
                          onChanged: (_) => setState(() {}),
                          textPrimary: textPrimary,
                          muted: muted,
                          card: card,
                          border: border,
                        ),

                        // Match feedback.
                        if (_confirm.text.isNotEmpty) ...[
                          const SizedBox(height: 8),
                          _matchFeedback(muted),
                        ],

                        const SizedBox(height: 24),

                        // Requirements checklist
                        _requirements(muted),

                        const SizedBox(height: 28),

                        _submitButton(),
                        const SizedBox(height: 40),
                      ],
                    ),
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  // ━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━
  // AMBIENT BACKGROUND
  // ━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━
  Widget _ambient() {
    return IgnorePointer(
      child: Stack(
        children: [
          Positioned(
            top: -90,
            left: -70,
            child: Container(
              width: 300,
              height: 300,
              decoration: BoxDecoration(
                shape: BoxShape.circle,
                color: _gold.withValues(alpha: 0.08),
              ),
            ),
          ),
          Positioned(
            bottom: -110,
            right: -80,
            child: Container(
              width: 320,
              height: 320,
              decoration: BoxDecoration(
                shape: BoxShape.circle,
                color: M4Theme.premiumBlue.withValues(alpha: 0.05),
              ),
            ),
          ),
        ],
      ),
    );
  }

  // ━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━
  // HEADER (mirrors web SectionHeader)
  // ━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━
  Widget _header(Color textPrimary, Color muted, Color border) {
    return Container(
      padding: const EdgeInsets.fromLTRB(16, 16, 24, 16),
      decoration: BoxDecoration(
        border: Border(bottom: BorderSide(color: border)),
      ),
      child: Row(
        children: [
          GestureDetector(
            onTap: _back,
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
                  style: GoogleFonts.montserrat(
                    fontSize: 8,
                    fontWeight: FontWeight.w900,
                    letterSpacing: 2.5,
                    color: _gold.withValues(alpha: 0.8),
                  ),
                ),
                const SizedBox(height: 4),
                Text(
                  'Change Password',
                  style: GoogleFonts.montserrat(
                    fontSize: 18,
                    fontWeight: FontWeight.w900,
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

  Widget _fieldLabel(String label, Color muted) {
    return Padding(
      padding: const EdgeInsets.only(left: 4),
      child: Text(
        label,
        style: GoogleFonts.montserrat(
          fontSize: 10,
          fontWeight: FontWeight.w800,
          letterSpacing: 2,
          color: muted,
        ),
      ),
    );
  }

  // ━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━
  // PASSWORD FIELD
  // ━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━
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
      style: GoogleFonts.montserrat(
        fontSize: 14,
        fontWeight: FontWeight.w600,
        color: textPrimary,
      ),
      decoration: InputDecoration(
        hintText: hint,
        hintStyle: GoogleFonts.montserrat(
          fontSize: 14,
          fontWeight: FontWeight.w500,
          color: muted,
        ),
        filled: true,
        fillColor: card,
        isDense: true,
        contentPadding:
            const EdgeInsets.symmetric(horizontal: 12, vertical: 16),
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
          borderSide: BorderSide(color: _gold.withValues(alpha: 0.5)),
        ),
      ),
    );
  }

  // ━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━
  // STRENGTH INDICATOR
  // ━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━
  Widget _strengthBar(Color muted, Color border) {
    final color = _strengthColor;
    return Padding(
      padding: const EdgeInsets.only(left: 4, right: 4),
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
            style: GoogleFonts.montserrat(
              fontSize: 9,
              fontWeight: FontWeight.w800,
              letterSpacing: 1.5,
              color: color,
            ),
          ),
        ],
      ),
    );
  }

  // ━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━
  // MATCH FEEDBACK
  // ━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━
  Widget _matchFeedback(Color muted) {
    final matches =
        _confirm.text == _newPass.text && _newPass.text.isNotEmpty;
    const green = Color(0xFF10B981);
    const red = Color(0xFFEF4444);
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
            style: GoogleFonts.montserrat(
              fontSize: 10,
              fontWeight: FontWeight.w600,
              color: matches ? green : red,
            ),
          ),
        ],
      ),
    );
  }

  // ━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━
  // REQUIREMENTS CHECKLIST
  // ━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━
  Widget _requirements(Color muted) {
    final items = <MapEntry<String, bool>>[
      MapEntry('At least 8 characters long', _hasMinLength),
      MapEntry('Contains one uppercase letter', _hasUppercase),
      MapEntry('Contains one number', _hasNumber),
      MapEntry('Contains one special character', _hasSpecial),
    ];

    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: _gold.withValues(alpha: 0.05),
        borderRadius: BorderRadius.circular(14),
        border: Border.all(color: _gold.withValues(alpha: 0.12)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Icon(LucideIcons.alertCircle,
                  size: 14, color: _gold.withValues(alpha: 0.7)),
              const SizedBox(width: 8),
              Text(
                'REQUIREMENTS',
                style: GoogleFonts.montserrat(
                  fontSize: 10,
                  fontWeight: FontWeight.w800,
                  letterSpacing: 1.5,
                  color: _gold.withValues(alpha: 0.7),
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
    const green = Color(0xFF10B981);
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
          Text(
            label,
            style: GoogleFonts.montserrat(
              fontSize: 10,
              fontWeight: FontWeight.w600,
              color: met ? green : muted,
            ),
          ),
        ],
      ),
    );
  }

  // ━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━
  // SUBMIT BUTTON
  // ━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━
  Widget _submitButton() {
    return GestureDetector(
      onTap: _submitting ? null : _submit,
      child: Opacity(
        opacity: _submitting ? 0.6 : 1.0,
        child: Container(
          width: double.infinity,
          height: 54,
          decoration: BoxDecoration(
            color: _gold,
            borderRadius: BorderRadius.circular(14),
            boxShadow: [
              BoxShadow(
                color: _gold.withValues(alpha: 0.3),
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
                  child: CircularProgressIndicator(
                      strokeWidth: 2, color: Colors.black),
                )
              : Text(
                  'UPDATE PASSWORD',
                  style: GoogleFonts.montserrat(
                    fontSize: 12,
                    fontWeight: FontWeight.w900,
                    letterSpacing: 2,
                    color: Colors.black,
                  ),
                ),
        ),
      ),
    );
  }
}
