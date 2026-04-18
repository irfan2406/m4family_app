import 'package:dio/dio.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:intl/intl.dart';
import 'package:lucide_icons/lucide_icons.dart';
import 'package:m4_mobile/presentation/providers/auth_provider.dart';

/// CP Configuration — parity with web `app/(cp)/cp/settings/page.tsx`.
class CpProfileSettingsScreen extends ConsumerStatefulWidget {
  const CpProfileSettingsScreen({super.key});

  @override
  ConsumerState<CpProfileSettingsScreen> createState() => _CpProfileSettingsScreenState();
}

class _CpProfileSettingsScreenState extends ConsumerState<CpProfileSettingsScreen> {
  static const _purple = Color(0xFF9333EA);
  static const _indigo = Color(0xFF4F46E5);

  final _first = TextEditingController();
  final _last = TextEditingController();
  final _email = TextEditingController();
  final _phone = TextEditingController();

  bool _loading = true;
  bool _saving = false;
  String? _dobIso;

  bool _sessionsBusy = false;
  bool _deleteBusy = false;

  final _curPass = TextEditingController();
  final _newPass = TextEditingController();
  final _confPass = TextEditingController();

  @override
  void dispose() {
    _first.dispose();
    _last.dispose();
    _email.dispose();
    _phone.dispose();
    _curPass.dispose();
    _newPass.dispose();
    _confPass.dispose();
    super.dispose();
  }

  Future<void> _load() async {
    setState(() => _loading = true);
    try {
      final res = await ref.read(apiClientProvider).getCurrentUser();
      final body = res.data;
      Map<String, dynamic>? u;
      if (body is Map && body['data'] is Map) {
        u = Map<String, dynamic>.from(body['data'] as Map);
      } else if (body is Map && body['status'] == true && body['data'] is Map) {
        u = Map<String, dynamic>.from(body['data'] as Map);
      }
      u ??= ref.read(authProvider).user;
      if (u != null) {
        _first.text = u['firstName']?.toString() ?? '';
        _last.text = u['lastName']?.toString() ?? '';
        _email.text = u['email']?.toString() ?? '';
        _phone.text = u['phone']?.toString() ?? '';
        final raw = u['dob'];
        if (raw != null && raw.toString().isNotEmpty) {
          try {
            final d = DateTime.parse(raw.toString());
            _dobIso = DateFormat('yyyy-MM-dd').format(d);
          } catch (_) {
            _dobIso = null;
          }
        }
      }
    } catch (e) {
      debugPrint('CP settings load: $e');
      final u = ref.read(authProvider).user;
      if (u != null) {
        _first.text = u['firstName']?.toString() ?? '';
        _last.text = u['lastName']?.toString() ?? '';
        _email.text = u['email']?.toString() ?? '';
        _phone.text = u['phone']?.toString() ?? '';
        final raw = u['dob'];
        if (raw != null && raw.toString().isNotEmpty) {
          try {
            final d = DateTime.parse(raw.toString());
            _dobIso = DateFormat('yyyy-MM-dd').format(d);
          } catch (_) {}
        }
      }
    }
    if (mounted) setState(() => _loading = false);
  }

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) => _load());
  }

  Future<void> _save() async {
    setState(() => _saving = true);
    try {
      final res = await ref.read(apiClientProvider).updateMe({
        'firstName': _first.text.trim(),
        'lastName': _last.text.trim(),
        'phone': _phone.text.trim(),
        if (_dobIso != null && _dobIso!.isNotEmpty) 'dob': _dobIso,
      });
      if (!mounted) return;
      final ok = res.data is Map && (res.data as Map)['status'] == true;
      if (ok) {
        await ref.read(authProvider.notifier).fetchMe();
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(content: Text('Profile updated successfully')),
          );
        }
      } else {
        final msg = res.data is Map ? (res.data as Map)['message']?.toString() : null;
        ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text(msg ?? 'Update failed')));
      }
    } on DioException catch (e) {
      if (mounted) {
        final m = e.response?.data is Map ? (e.response!.data as Map)['message']?.toString() : null;
        ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text(m ?? e.message ?? 'Network error')));
      }
    } finally {
      if (mounted) setState(() => _saving = false);
    }
  }

  Future<void> _pickDob() async {
    final now = DateTime.now();
    final initial = _dobIso != null
        ? DateTime.tryParse(_dobIso!) ?? DateTime(now.year - 30, 1, 1)
        : DateTime(now.year - 30, 1, 1);
    final d = await showDatePicker(
      context: context,
      initialDate: initial,
      firstDate: DateTime(1900),
      lastDate: now,
    );
    if (d != null && mounted) {
      setState(() => _dobIso = DateFormat('yyyy-MM-dd').format(d));
    }
  }

  Future<void> _deactivateSessions() async {
    final go = await showDialog<bool>(
      context: context,
      builder: (ctx) => AlertDialog(
        title: Text('Deactivate sessions?', style: GoogleFonts.montserrat(fontWeight: FontWeight.w800)),
        content: const Text(
          'You will be logged out everywhere, including this device.',
        ),
        actions: [
          TextButton(onPressed: () => Navigator.pop(ctx, false), child: const Text('Cancel')),
          TextButton(
            onPressed: () => Navigator.pop(ctx, true),
            child: Text('Continue', style: TextStyle(color: Theme.of(ctx).colorScheme.error)),
          ),
        ],
      ),
    );
    if (go != true || !mounted) return;
    setState(() => _sessionsBusy = true);
    try {
      final res = await ref.read(apiClientProvider).logoutAllSessions();
      if (!mounted) return;
      final ok = res.data is Map && (res.data as Map)['status'] == true;
      if (ok) {
        await ref.read(authProvider.notifier).logout();
        if (!mounted) return;
        context.go('/auth/cp/login');
      } else {
        final msg = res.data is Map ? (res.data as Map)['message']?.toString() : null;
        ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text(msg ?? 'Failed')));
      }
    } on DioException catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text(e.message ?? 'Error')));
      }
    } finally {
      if (mounted) setState(() => _sessionsBusy = false);
    }
  }

  Future<void> _deleteAccount() async {
    final go = await showDialog<bool>(
      context: context,
      builder: (ctx) => AlertDialog(
        title: Text('Permanent deactivation', style: GoogleFonts.montserrat(fontWeight: FontWeight.w800)),
        content: const Text(
          'CRITICAL: This will remove your data from M4 Family. Continue?',
        ),
        actions: [
          TextButton(onPressed: () => Navigator.pop(ctx, false), child: const Text('Cancel')),
          TextButton(
            onPressed: () => Navigator.pop(ctx, true),
            child: Text('Deactivate', style: TextStyle(color: Theme.of(ctx).colorScheme.error)),
          ),
        ],
      ),
    );
    if (go != true || !mounted) return;
    setState(() => _deleteBusy = true);
    try {
      final res = await ref.read(apiClientProvider).deleteMe();
      if (!mounted) return;
      final ok = res.data is Map && (res.data as Map)['status'] == true;
      if (ok) {
        await ref.read(authProvider.notifier).logout();
        if (!mounted) return;
        context.go('/auth/cp/login');
      } else {
        final msg = res.data is Map ? (res.data as Map)['message']?.toString() : null;
        ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text(msg ?? 'Failed')));
      }
    } on DioException catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text(e.message ?? 'Error')));
      }
    } finally {
      if (mounted) setState(() => _deleteBusy = false);
    }
  }

  void _openPasscodeDialog() {
    _curPass.clear();
    _newPass.clear();
    _confPass.clear();
    showDialog<void>(
      context: context,
      builder: (ctx) {
        var submitting = false;
        return StatefulBuilder(
          builder: (ctx, setDialogState) {
            Future<void> submit() async {
              if (_newPass.text.length < 4) {
                ScaffoldMessenger.of(context).showSnackBar(
                  const SnackBar(content: Text('Passcode must be at least 4 digits')),
                );
                return;
              }
              if (_newPass.text != _confPass.text) {
                ScaffoldMessenger.of(context).showSnackBar(
                  const SnackBar(content: Text('New passcodes do not match')),
                );
                return;
              }
              setDialogState(() => submitting = true);
              try {
                final res = await ref.read(apiClientProvider).changePassword(
                      currentPassword: _curPass.text,
                      newPassword: _newPass.text,
                    );
                if (!context.mounted) return;
                final ok = res.data is Map && (res.data as Map)['status'] == true;
                if (ok) {
                  Navigator.of(ctx).pop();
                  _curPass.clear();
                  _newPass.clear();
                  _confPass.clear();
                  if (mounted) {
                    ScaffoldMessenger.of(context).showSnackBar(
                      const SnackBar(content: Text('Passcode updated successfully')),
                    );
                  }
                } else {
                  final msg = res.data is Map ? (res.data as Map)['message']?.toString() : null;
                  if (mounted) {
                    ScaffoldMessenger.of(context).showSnackBar(
                      SnackBar(content: Text(msg ?? 'Failed to update passcode')),
                    );
                  }
                }
              } on DioException catch (e) {
                if (mounted) {
                  final m = e.response?.data is Map ? (e.response!.data as Map)['message']?.toString() : null;
                  ScaffoldMessenger.of(context).showSnackBar(
                    SnackBar(content: Text(m ?? 'Error updating passcode')),
                  );
                }
              } finally {
                if (ctx.mounted) setDialogState(() => submitting = false);
              }
            }

            return AlertDialog(
              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(28)),
              title: Text(
                'UPDATE SECURITY PASSCODE',
                style: GoogleFonts.montserrat(fontSize: 12, fontWeight: FontWeight.w900, letterSpacing: 1.2),
              ),
              content: SingleChildScrollView(
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  crossAxisAlignment: CrossAxisAlignment.stretch,
                  children: [
                    Text(
                      'SET A NEW 4–6 DIGIT SECURE ACCESS CODE',
                      style: GoogleFonts.montserrat(
                        fontSize: 9,
                        color: Theme.of(ctx).colorScheme.onSurfaceVariant,
                        letterSpacing: 1,
                      ),
                    ),
                    const SizedBox(height: 16),
                    _passField(ctx, 'Current', _curPass),
                    const SizedBox(height: 12),
                    _passField(ctx, 'New', _newPass),
                    const SizedBox(height: 12),
                    _passField(ctx, 'Confirm', _confPass),
                  ],
                ),
              ),
              actions: [
                TextButton(
                  onPressed: submitting ? null : () => Navigator.pop(ctx),
                  child: Text('CANCEL', style: GoogleFonts.montserrat(fontSize: 9, fontWeight: FontWeight.w800)),
                ),
                FilledButton(
                  onPressed: submitting ? null : submit,
                  style: FilledButton.styleFrom(
                    backgroundColor: _purple,
                    shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
                  ),
                  child: submitting
                      ? const SizedBox(
                          width: 18,
                          height: 18,
                          child: CircularProgressIndicator(strokeWidth: 2, color: Colors.white),
                        )
                      : Text('CONFIRM', style: GoogleFonts.montserrat(fontSize: 9, fontWeight: FontWeight.w800)),
                ),
              ],
            );
          },
        );
      },
    );
  }

  Widget _passField(BuildContext ctx, String label, TextEditingController c) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          label.toUpperCase(),
          style: GoogleFonts.montserrat(fontSize: 8, fontWeight: FontWeight.w800, letterSpacing: 1.5),
        ),
        const SizedBox(height: 6),
        TextField(
          controller: c,
          obscureText: true,
          keyboardType: TextInputType.number,
          textAlign: TextAlign.center,
          style: GoogleFonts.montserrat(fontWeight: FontWeight.w700, letterSpacing: 6),
          decoration: InputDecoration(
            filled: true,
            fillColor: Theme.of(ctx).colorScheme.surfaceContainerHighest.withValues(alpha: 0.5),
            border: OutlineInputBorder(borderRadius: BorderRadius.circular(16)),
          ),
        ),
      ],
    );
  }

  @override
  Widget build(BuildContext context) {
    final scheme = Theme.of(context).colorScheme;

    if (_loading) {
      return Scaffold(
        backgroundColor: scheme.surface,
        body: Stack(
          children: [
            _ambient(),
            Center(
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  SizedBox(
                    width: 48,
                    height: 48,
                    child: CircularProgressIndicator(strokeWidth: 2, color: scheme.primary),
                  ),
                  const SizedBox(height: 16),
                  Text(
                    'ESTABLISHING SECURE CONNECTION...',
                    style: GoogleFonts.montserrat(
                      fontSize: 10,
                      fontWeight: FontWeight.w900,
                      letterSpacing: 3,
                      color: scheme.onSurface.withValues(alpha: 0.4),
                    ),
                  ),
                ],
              ),
            ),
          ],
        ),
      );
    }

    return Scaffold(
      backgroundColor: scheme.surface,
      body: Stack(
        children: [
          _ambient(),
          SafeArea(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                _header(context, scheme),
                Expanded(
                  child: SingleChildScrollView(
                    padding: const EdgeInsets.fromLTRB(28, 20, 28, 48),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.stretch,
                      children: [
                        _sectionBar('ACCOUNT IDENTITY', scheme),
                        const SizedBox(height: 16),
                        _accountCard(scheme),
                        const SizedBox(height: 32),
                        _sectionBar('SECURITY & ACCESS', scheme),
                        const SizedBox(height: 16),
                        _changePasscodeButton(scheme),
                        const SizedBox(height: 12),
                        _sessionsButton(scheme),
                        const SizedBox(height: 12),
                        _deleteAccountTextButton(scheme),
                        const SizedBox(height: 40),
                        Center(
                          child: Column(
                            children: [
                              Text(
                                'M4 FAMILY PRIVATE OFFICE',
                                style: GoogleFonts.montserrat(
                                  fontSize: 8,
                                  fontWeight: FontWeight.w900,
                                  letterSpacing: 4,
                                  color: scheme.onSurface.withValues(alpha: 0.2),
                                ),
                              ),
                              const SizedBox(height: 4),
                              Text(
                                'VERSION 2.4.0 • SECURE BUILD 882',
                                style: GoogleFonts.montserrat(
                                  fontSize: 7,
                                  fontWeight: FontWeight.w900,
                                  letterSpacing: 2,
                                  color: scheme.onSurface.withValues(alpha: 0.12),
                                ),
                              ),
                            ],
                          ),
                        ),
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

  Widget _ambient() {
    return IgnorePointer(
      child: Stack(
        children: [
          Positioned(
            top: -80,
            left: -60,
            child: Container(
              width: 280,
              height: 280,
              decoration: BoxDecoration(
                shape: BoxShape.circle,
                color: _purple.withValues(alpha: 0.08),
              ),
            ),
          ),
          Positioned(
            bottom: -100,
            right: -80,
            child: Container(
              width: 320,
              height: 320,
              decoration: BoxDecoration(
                shape: BoxShape.circle,
                color: _indigo.withValues(alpha: 0.05),
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _header(BuildContext context, ColorScheme scheme) {
    return Container(
      padding: const EdgeInsets.fromLTRB(12, 10, 16, 14),
      decoration: BoxDecoration(
        color: scheme.surface.withValues(alpha: 0.4),
        border: Border(bottom: BorderSide(color: scheme.outlineVariant.withValues(alpha: 0.35))),
      ),
      child: Row(
        children: [
          Material(
            color: scheme.surfaceContainerHighest.withValues(alpha: 0.6),
            borderRadius: BorderRadius.circular(8),
            child: InkWell(
              onTap: () => context.pop(),
              borderRadius: BorderRadius.circular(8),
              child: SizedBox(
                width: 32,
                height: 32,
                child: Icon(LucideIcons.arrowLeft, size: 18, color: scheme.onSurfaceVariant),
              ),
            ),
          ),
          const SizedBox(width: 10),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  children: [
                    Container(
                      width: 6,
                      height: 6,
                      decoration: const BoxDecoration(shape: BoxShape.circle, color: _purple),
                    ),
                    const SizedBox(width: 8),
                    Flexible(
                      child: Text(
                        'CONFIGURATION',
                        style: GoogleFonts.montserrat(
                          fontSize: 13,
                          fontWeight: FontWeight.w900,
                          letterSpacing: -0.3,
                          color: _purple,
                        ),
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 2),
                Text(
                  'PRIVATE OFFICE SETTINGS',
                  style: GoogleFonts.montserrat(
                    fontSize: 10,
                    fontWeight: FontWeight.w700,
                    letterSpacing: 2,
                    color: scheme.onSurface.withValues(alpha: 0.52),
                  ),
                ),
              ],
            ),
          ),
          DecoratedBox(
            decoration: BoxDecoration(
              gradient: const LinearGradient(colors: [_purple, _indigo]),
              borderRadius: BorderRadius.circular(8),
              boxShadow: [
                BoxShadow(color: _purple.withValues(alpha: 0.25), blurRadius: 12, offset: const Offset(0, 4)),
              ],
            ),
            child: Material(
              color: Colors.transparent,
              child: InkWell(
                onTap: _saving ? null : _save,
                borderRadius: BorderRadius.circular(8),
                child: Padding(
                  padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
                  child: _saving
                      ? const SizedBox(
                          width: 16,
                          height: 16,
                          child: CircularProgressIndicator(strokeWidth: 2, color: Colors.white),
                        )
                      : Text(
                          'SAVE CHANGES',
                          style: GoogleFonts.montserrat(
                            fontSize: 9,
                            fontWeight: FontWeight.w900,
                            letterSpacing: 1,
                            color: Colors.white,
                          ),
                        ),
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _sectionBar(String title, ColorScheme scheme) {
    return Row(
      children: [
        Container(
          width: 4,
          height: 12,
          decoration: BoxDecoration(
            color: scheme.primary,
            borderRadius: BorderRadius.circular(2),
            boxShadow: [
              BoxShadow(color: scheme.primary.withValues(alpha: 0.35), blurRadius: 8),
            ],
          ),
        ),
        const SizedBox(width: 8),
        Text(
          title,
          style: GoogleFonts.montserrat(
            fontSize: 10,
            fontWeight: FontWeight.w900,
            letterSpacing: 2.5,
            color: scheme.onSurface.withValues(alpha: 0.68),
          ),
        ),
      ],
    );
  }

  Widget _accountCard(ColorScheme scheme) {
    return Container(
      padding: const EdgeInsets.fromLTRB(18, 20, 18, 20),
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(32),
        border: Border.all(color: scheme.outlineVariant.withValues(alpha: 0.45)),
        color: scheme.surfaceContainerHighest.withValues(alpha: 0.35),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: Theme.of(context).brightness == Brightness.dark ? 0.35 : 0.07),
            blurRadius: 24,
            offset: const Offset(0, 12),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Expanded(
                child: _labeledField(
                  scheme,
                  'FIRST NAME',
                  TextField(
                    controller: _first,
                    style: GoogleFonts.montserrat(
                      fontWeight: FontWeight.w700,
                      fontSize: 14,
                      color: scheme.onSurface.withValues(alpha: 0.92),
                    ),
                    decoration: _inputDec(
                      scheme,
                      prefix: Icon(LucideIcons.user, size: 16, color: scheme.onSurface.withValues(alpha: 0.5)),
                    ),
                  ),
                ),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: _labeledField(
                  scheme,
                  'LAST NAME',
                  TextField(
                    controller: _last,
                    style: GoogleFonts.montserrat(
                      fontWeight: FontWeight.w700,
                      fontSize: 14,
                      color: scheme.onSurface.withValues(alpha: 0.92),
                    ),
                    decoration: _inputDec(scheme),
                  ),
                ),
              ),
            ],
          ),
          const SizedBox(height: 18),
          _labeledField(
            scheme,
            'EMAIL (READ ONLY)',
            Stack(
              alignment: Alignment.centerRight,
              children: [
                TextField(
                  controller: _email,
                  readOnly: true,
                  style: GoogleFonts.montserrat(
                    fontWeight: FontWeight.w600,
                    fontSize: 14,
                    color: scheme.onSurface.withValues(alpha: 0.92),
                  ),
                  decoration: _inputDec(
                    scheme,
                    prefix: Icon(LucideIcons.mail, size: 16, color: scheme.onSurface.withValues(alpha: 0.5)),
                  ).copyWith(
                    filled: true,
                    fillColor: scheme.surface.withValues(alpha: 0.85),
                    contentPadding: const EdgeInsets.fromLTRB(12, 14, 96, 14),
                  ),
                ),
                Padding(
                  padding: const EdgeInsets.only(right: 12),
                  child: Container(
                    padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                    decoration: BoxDecoration(
                      color: const Color(0xFF10B981).withValues(alpha: 0.1),
                      borderRadius: BorderRadius.circular(999),
                      border: Border.all(color: const Color(0xFF10B981).withValues(alpha: 0.25)),
                    ),
                    child: Row(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        const Icon(LucideIcons.check, size: 12, color: Color(0xFF10B981)),
                        const SizedBox(width: 4),
                        Text(
                          'VERIFIED',
                          style: GoogleFonts.montserrat(
                            fontSize: 8,
                            fontWeight: FontWeight.w900,
                            color: const Color(0xFF10B981),
                            letterSpacing: 0.5,
                          ),
                        ),
                      ],
                    ),
                  ),
                ),
              ],
            ),
          ),
          const SizedBox(height: 18),
          _labeledField(
            scheme,
            'SECURE CONTACT',
            TextField(
              controller: _phone,
              keyboardType: TextInputType.phone,
              style: GoogleFonts.montserrat(
                fontWeight: FontWeight.w700,
                fontSize: 14,
                color: scheme.onSurface.withValues(alpha: 0.92),
              ),
              decoration: _inputDec(
                scheme,
                prefix: Icon(LucideIcons.phone, size: 16, color: scheme.onSurface.withValues(alpha: 0.5)),
              ),
            ),
          ),
          const SizedBox(height: 18),
          _labeledField(
            scheme,
            'DATE OF BIRTH',
            Material(
              color: Colors.transparent,
              child: InkWell(
                onTap: _pickDob,
                borderRadius: BorderRadius.circular(20),
                child: Container(
                  constraints: const BoxConstraints(minHeight: 48),
                  padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
                  decoration: BoxDecoration(
                    color: const Color(0xFF1E1E24),
                    borderRadius: BorderRadius.circular(20),
                    border: Border.all(color: scheme.outlineVariant.withValues(alpha: 0.35)),
                  ),
                  child: Row(
                    children: [
                      Icon(LucideIcons.calendar, size: 16, color: Colors.white.withValues(alpha: 0.65)),
                      const SizedBox(width: 10),
                      Expanded(
                        child: Text(
                          _dobIso == null || _dobIso!.isEmpty
                              ? 'dd-mm-yyyy'
                              : DateFormat('dd-MM-yyyy').format(DateTime.parse(_dobIso!)),
                          style: GoogleFonts.montserrat(
                            fontWeight: FontWeight.w700,
                            fontSize: 14,
                            color: Colors.white.withValues(
                              alpha: _dobIso == null || _dobIso!.isEmpty ? 0.5 : 0.95,
                            ),
                          ),
                        ),
                      ),
                      Icon(LucideIcons.chevronDown, size: 16, color: Colors.white.withValues(alpha: 0.5)),
                    ],
                  ),
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }

  InputDecoration _inputDec(ColorScheme scheme, {Widget? prefix}) {
    return InputDecoration(
      isDense: true,
      prefixIcon: prefix != null ? Padding(padding: const EdgeInsets.only(left: 12, right: 8), child: prefix) : null,
      prefixIconConstraints: const BoxConstraints(minWidth: 40, minHeight: 48),
      contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
      filled: true,
      fillColor: scheme.surface.withValues(alpha: 0.72),
      border: OutlineInputBorder(
        borderRadius: BorderRadius.circular(20),
        borderSide: BorderSide(color: scheme.outlineVariant.withValues(alpha: 0.55)),
      ),
      enabledBorder: OutlineInputBorder(
        borderRadius: BorderRadius.circular(20),
        borderSide: BorderSide(color: scheme.outlineVariant.withValues(alpha: 0.55)),
      ),
      focusedBorder: OutlineInputBorder(
        borderRadius: BorderRadius.circular(20),
        borderSide: BorderSide(color: scheme.primary.withValues(alpha: 0.55)),
      ),
    );
  }

  Widget _labeledField(ColorScheme scheme, String label, Widget field) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Padding(
          padding: const EdgeInsets.only(left: 4, bottom: 8),
          child: Text(
            label,
            style: GoogleFonts.montserrat(
              fontSize: 9,
              fontWeight: FontWeight.w900,
              letterSpacing: 2,
              color: scheme.onSurface.withValues(alpha: 0.62),
            ),
          ),
        ),
        field,
      ],
    );
  }

  Widget _changePasscodeButton(ColorScheme scheme) {
    return Material(
      color: scheme.surfaceContainerHighest.withValues(alpha: 0.45),
      borderRadius: BorderRadius.circular(24),
      child: InkWell(
        onTap: _openPasscodeDialog,
        borderRadius: BorderRadius.circular(24),
        child: Container(
          padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 16),
          decoration: BoxDecoration(
            borderRadius: BorderRadius.circular(24),
            border: Border.all(color: scheme.outlineVariant.withValues(alpha: 0.45)),
          ),
          child: Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Text(
                'CHANGE ACCESS PASSCODE',
                style: GoogleFonts.montserrat(
                  fontSize: 10,
                  fontWeight: FontWeight.w900,
                  letterSpacing: 1.5,
                  color: scheme.onSurface.withValues(alpha: 0.82),
                ),
              ),
              Icon(LucideIcons.chevronRight, size: 18, color: scheme.onSurface.withValues(alpha: 0.45)),
            ],
          ),
        ),
      ),
    );
  }

  Widget _sessionsButton(ColorScheme scheme) {
    return Material(
      color: scheme.error.withValues(alpha: 0.06),
      borderRadius: BorderRadius.circular(24),
      child: InkWell(
        onTap: _sessionsBusy ? null : _deactivateSessions,
        borderRadius: BorderRadius.circular(24),
        child: Container(
          width: double.infinity,
          padding: const EdgeInsets.symmetric(vertical: 16),
          decoration: BoxDecoration(
            borderRadius: BorderRadius.circular(24),
            border: Border.all(color: scheme.error.withValues(alpha: 0.22)),
          ),
          alignment: Alignment.center,
          child: _sessionsBusy
              ? SizedBox(
                  width: 20,
                  height: 20,
                  child: CircularProgressIndicator(strokeWidth: 2, color: scheme.error),
                )
              : Text(
                  'DEACTIVATE ALL ACTIVE SESSIONS',
                  style: GoogleFonts.montserrat(
                    fontSize: 10,
                    fontWeight: FontWeight.w900,
                    letterSpacing: 1.5,
                    color: scheme.error,
                  ),
                ),
        ),
      ),
    );
  }

  Widget _deleteAccountTextButton(ColorScheme scheme) {
    return TextButton(
      onPressed: _deleteBusy ? null : _deleteAccount,
      child: _deleteBusy
          ? SizedBox(
              width: 18,
              height: 18,
              child: CircularProgressIndicator(strokeWidth: 2, color: scheme.onSurface.withValues(alpha: 0.3)),
            )
          :               Text(
                'PERMANENTLY DEACTIVATE ACCOUNT',
              style: GoogleFonts.montserrat(
                fontSize: 8,
                fontWeight: FontWeight.w900,
                letterSpacing: 2.5,
                color: scheme.onSurface.withValues(alpha: 0.48),
              ),
            ),
    );
  }
}
