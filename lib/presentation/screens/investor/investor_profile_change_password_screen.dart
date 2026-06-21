import 'package:dio/dio.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:lucide_icons/lucide_icons.dart';
import 'package:m4_mobile/core/theme/app_theme.dart';
import 'package:m4_mobile/presentation/providers/auth_provider.dart';

/// Investor profile change password — parity with web
/// `app/investor/profile/change-password/page.tsx`.
///
/// Profile subroute for credential update. Mirrors the structure of
/// [CpChangePasswordScreen] (current / new / confirm fields with a live
/// requirements checklist) but adapts the copy to the investor web page
/// ("SECURITY" / "CREDENTIAL UPDATE") and uses the investor gold accent.
/// Submits to `PATCH /api/auth/change-password` via [ApiClient.changePassword]
/// with `{ currentPassword, newPassword }`.
class InvestorProfileChangePasswordScreen extends ConsumerStatefulWidget {
  const InvestorProfileChangePasswordScreen({super.key});

  @override
  ConsumerState<InvestorProfileChangePasswordScreen> createState() =>
      _InvestorProfileChangePasswordScreenState();
}

class _InvestorProfileChangePasswordScreenState
    extends ConsumerState<InvestorProfileChangePasswordScreen> {
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
  bool get _hasSpecial =>
      RegExp(r'''[!@#$%^&*(),.?":{}|<>_\-\[\]\\/;'`~+=]''').hasMatch(_newPass.text);

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
      _snack('New passwords do not match', error: true);
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
      final apiClient = ref.read(apiClientProvider);
      final res = await apiClient.changePassword(
        currentPassword: _current.text,
        newPassword: _newPass.text,
      );
      if (!mounted) return;
      final ok = res.data is Map && (res.data as Map)['status'] == true;
      if (ok) {
        _snack('Security credentials updated!');
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
                        // Current password
                        _fieldLabel('OLD CREDENTIAL', muted),
                        const SizedBox(height: 8),
                        _passwordField(
                          controller: _current,
                          hint: 'Enter current password',
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
                        _fieldLabel('NEW CREDENTIAL', muted),
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

                        const SizedBox(height: 16),

                        // Confirm password (shares show/hide with new password).
                        _fieldLabel('VERIFY CREDENTIAL', muted),
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
                  'CREDENTIAL UPDATE',
                  style: GoogleFonts.montserrat(
                    fontSize: 8,
                    fontWeight: FontWeight.w900,
                    letterSpacing: 2.5,
                    color: _gold.withValues(alpha: 0.8),
                  ),
                ),
                const SizedBox(height: 4),
                Text(
                  'Security',
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
        contentPadding: const EdgeInsets.symmetric(horizontal: 12, vertical: 16),
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
            gradient: const LinearGradient(colors: [_gold, Color(0xFFE6B800)]),
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
                  'SECURE UPDATE',
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
