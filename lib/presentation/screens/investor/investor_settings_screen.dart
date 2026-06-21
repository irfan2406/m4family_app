import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:lucide_icons/lucide_icons.dart';
import 'package:m4_mobile/core/theme/app_theme.dart';
import 'package:m4_mobile/presentation/providers/auth_provider.dart';

/// Investor settings — parity with web `app/investor/settings/page.tsx`
/// (profile fields name/email/phone + save, biometric / notifications /
/// privacy-mode toggles, sign-out-all-devices). Follows M4 conventions.
class InvestorSettingsScreen extends ConsumerStatefulWidget {
  const InvestorSettingsScreen({super.key});

  @override
  ConsumerState<InvestorSettingsScreen> createState() => _InvestorSettingsScreenState();
}

class _InvestorSettingsScreenState extends ConsumerState<InvestorSettingsScreen> {
  static const _gold = Color(0xFFFFD700);

  final _nameController = TextEditingController();
  final _phoneController = TextEditingController();
  String _email = '';

  bool _biometric = true;
  bool _notifications = true;
  bool _privacyMode = false;

  bool _loading = true;
  bool _saving = false;
  String? _error;

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) => _fetchUser());
  }

  @override
  void dispose() {
    _nameController.dispose();
    _phoneController.dispose();
    super.dispose();
  }

  Future<void> _fetchUser() async {
    setState(() {
      _loading = true;
      _error = null;
    });
    try {
      final apiClient = ref.read(apiClientProvider);
      final res = await apiClient.getCurrentUser();
      final body = res.data;
      Map<String, dynamic>? user;
      if (body is Map && body['status'] == true && body['data'] is Map) {
        user = Map<String, dynamic>.from(body['data'] as Map);
      } else if (body is Map && body['data'] is Map) {
        user = Map<String, dynamic>.from(body['data'] as Map);
      }
      user ??= () {
        final u = ref.read(authProvider).user;
        return u != null ? Map<String, dynamic>.from(u) : <String, dynamic>{};
      }();
      _applyUser(user);

      // Load saved preferences (best-effort — defaults apply on failure).
      try {
        final prefRes = await apiClient.getMyPreferences();
        final prefBody = prefRes.data;
        if (prefBody is Map && prefBody['data'] is Map) {
          final prefs = Map<String, dynamic>.from(prefBody['data'] as Map);
          _biometric = prefs['biometricAccess'] ?? prefs['biometric'] ?? _biometric;
          _notifications = prefs['pushNotifications'] ?? prefs['notifications'] ?? _notifications;
          _privacyMode = prefs['privacyMode'] ?? _privacyMode;
        }
      } catch (_) {}
    } catch (_) {
      final u = ref.read(authProvider).user;
      if (u != null) {
        _applyUser(Map<String, dynamic>.from(u));
      } else {
        _error = 'Unable to load your settings. Please try again.';
      }
    }
    if (mounted) setState(() => _loading = false);
  }

  void _applyUser(Map<String, dynamic> u) {
    final fn = u['fullName']?.toString().trim();
    final combined = '${u['firstName'] ?? ''} ${u['lastName'] ?? ''}'.trim();
    _nameController.text = (fn != null && fn.isNotEmpty) ? fn : combined;
    _email = u['email']?.toString() ?? '';
    _phoneController.text = u['phone']?.toString() ?? '';
  }

  Future<void> _save() async {
    if (_saving) return;
    setState(() => _saving = true);
    final apiClient = ref.read(apiClientProvider);
    bool ok = true;
    try {
      await apiClient.updateMe({
        'fullName': _nameController.text.trim(),
        'phone': _phoneController.text.trim(),
      });
    } catch (_) {
      ok = false;
    }
    try {
      await apiClient.updatePreferences({
        'biometricAccess': _biometric,
        'pushNotifications': _notifications,
        'privacyMode': _privacyMode,
      });
    } catch (_) {
      // Preferences are best-effort; profile save success drives the toast.
    }
    if (!mounted) return;
    setState(() => _saving = false);
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        backgroundColor: ok ? _gold : Colors.red,
        content: Text(
          ok ? 'Preferences updated securely' : 'Could not save changes. Try again.',
          style: GoogleFonts.montserrat(
            fontSize: 12,
            fontWeight: FontWeight.w700,
            color: Colors.black,
          ),
        ),
      ),
    );
  }

  Future<void> _signOutAllDevices() async {
    final go = await showDialog<bool>(
      context: context,
      builder: (ctx) => AlertDialog(
        title: Text('Sign out everywhere', style: GoogleFonts.montserrat(fontWeight: FontWeight.w700)),
        content: const Text('Sign out of your investor account on all devices?'),
        actions: [
          TextButton(onPressed: () => Navigator.pop(ctx, false), child: const Text('Cancel')),
          TextButton(
            onPressed: () => Navigator.pop(ctx, true),
            child: const Text('Sign out', style: TextStyle(color: Colors.red)),
          ),
        ],
      ),
    );
    if (go != true) return;
    try {
      await ref.read(apiClientProvider).logoutAllSessions();
    } catch (_) {}
    if (!mounted) return;
    await ref.read(authProvider.notifier).logout();
    if (!mounted) return;
    context.go('/investor/login');
  }

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final bg = isDark ? Colors.black : Colors.white;
    final textPrimary = isDark ? Colors.white : Colors.black;
    final muted = textPrimary.withValues(alpha: 0.5);

    if (_loading) {
      return Scaffold(
        backgroundColor: bg,
        body: const Center(child: CircularProgressIndicator(color: M4Theme.premiumBlue)),
      );
    }

    if (_error != null) {
      return Scaffold(
        backgroundColor: bg,
        body: SafeArea(
          child: Center(
            child: Padding(
              padding: const EdgeInsets.all(32),
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Icon(LucideIcons.alertCircle, size: 40, color: muted),
                  const SizedBox(height: 16),
                  Text(
                    _error!,
                    textAlign: TextAlign.center,
                    style: GoogleFonts.montserrat(fontSize: 13, fontWeight: FontWeight.w600, color: muted),
                  ),
                  const SizedBox(height: 20),
                  TextButton(
                    onPressed: _fetchUser,
                    child: Text(
                      'RETRY',
                      style: GoogleFonts.montserrat(
                        fontSize: 11,
                        fontWeight: FontWeight.w800,
                        color: M4Theme.premiumBlue,
                        letterSpacing: 1.5,
                      ),
                    ),
                  ),
                ],
              ),
            ),
          ),
        ),
      );
    }

    return Scaffold(
      backgroundColor: bg,
      body: SafeArea(
        child: Column(
          children: [
            _buildHeader(isDark, textPrimary, muted),
            Expanded(
              child: SingleChildScrollView(
                physics: const BouncingScrollPhysics(),
                padding: const EdgeInsets.fromLTRB(24, 20, 24, 100),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    _sectionLabel('PERSONAL DETAIL', muted),
                    const SizedBox(height: 16),
                    _field(
                      isDark, textPrimary, muted,
                      label: 'FULL NAME',
                      icon: LucideIcons.user,
                      controller: _nameController,
                    ),
                    const SizedBox(height: 16),
                    _field(
                      isDark, textPrimary, muted,
                      label: 'EMAIL ADDRESS',
                      icon: LucideIcons.mail,
                      value: _email.isNotEmpty ? _email : 'no email provided',
                      enabled: false,
                      verified: _email.isNotEmpty,
                    ),
                    const SizedBox(height: 16),
                    _field(
                      isDark, textPrimary, muted,
                      label: 'MOBILE NUMBER',
                      icon: LucideIcons.phone,
                      controller: _phoneController,
                      keyboardType: TextInputType.phone,
                    ),
                    const SizedBox(height: 28),
                    _sectionLabel('SECURITY & ACCESS', muted),
                    const SizedBox(height: 16),
                    _toggleTile(
                      isDark, textPrimary, muted,
                      icon: LucideIcons.smartphone,
                      title: 'BIOMETRIC LOGIN',
                      subtitle: 'FACE ID / TOUCH ID',
                      value: _biometric,
                      onChanged: (v) => setState(() => _biometric = v),
                    ),
                    const SizedBox(height: 12),
                    _toggleTile(
                      isDark, textPrimary, muted,
                      icon: LucideIcons.bell,
                      title: 'NOTIFICATIONS',
                      subtitle: 'PORTFOLIO & DEAL ALERTS',
                      value: _notifications,
                      onChanged: (v) => setState(() => _notifications = v),
                    ),
                    const SizedBox(height: 12),
                    _toggleTile(
                      isDark, textPrimary, muted,
                      icon: LucideIcons.shield,
                      title: 'PRIVACY MODE',
                      subtitle: 'MASK SENSITIVE VALUES',
                      value: _privacyMode,
                      onChanged: (v) => setState(() => _privacyMode = v),
                    ),
                    const SizedBox(height: 28),
                    _signOutButton(),
                  ],
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildHeader(bool isDark, Color textPrimary, Color muted) {
    final border = (isDark ? Colors.white : Colors.black).withValues(alpha: 0.06);
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 16),
      decoration: BoxDecoration(
        border: Border(bottom: BorderSide(color: border)),
      ),
      child: Row(
        children: [
          Material(
            color: textPrimary.withValues(alpha: 0.04),
            borderRadius: BorderRadius.circular(14),
            child: InkWell(
              borderRadius: BorderRadius.circular(14),
              onTap: () {
                if (context.canPop()) {
                  context.pop();
                } else {
                  context.go('/investor/home');
                }
              },
              child: Container(
                padding: const EdgeInsets.all(12),
                decoration: BoxDecoration(
                  borderRadius: BorderRadius.circular(14),
                  border: Border.all(color: textPrimary.withValues(alpha: 0.08)),
                ),
                child: Icon(LucideIcons.chevronLeft, size: 20, color: muted),
              ),
            ),
          ),
          const SizedBox(width: 16),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  'CONFIGURATION',
                  style: GoogleFonts.montserrat(
                    fontSize: 14,
                    fontWeight: FontWeight.w800,
                    color: textPrimary,
                    letterSpacing: 2,
                  ),
                ),
                const SizedBox(height: 4),
                Text(
                  'PRIVATE OFFICE SETTINGS',
                  style: GoogleFonts.montserrat(
                    fontSize: 9,
                    fontWeight: FontWeight.w800,
                    color: muted,
                    letterSpacing: 2,
                  ),
                ),
              ],
            ),
          ),
          _saving
              ? const SizedBox(
                  width: 20,
                  height: 20,
                  child: CircularProgressIndicator(strokeWidth: 2, color: M4Theme.premiumBlue),
                )
              : Material(
                  color: _gold,
                  borderRadius: BorderRadius.circular(10),
                  child: InkWell(
                    borderRadius: BorderRadius.circular(10),
                    onTap: _save,
                    child: Padding(
                      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 9),
                      child: Text(
                        'SAVE',
                        style: GoogleFonts.montserrat(
                          fontSize: 9,
                          fontWeight: FontWeight.w800,
                          color: Colors.black,
                          letterSpacing: 1.5,
                        ),
                      ),
                    ),
                  ),
                ),
        ],
      ),
    );
  }

  Widget _sectionLabel(String text, Color muted) {
    return Text(
      text,
      style: GoogleFonts.montserrat(fontSize: 9, fontWeight: FontWeight.w900, color: muted, letterSpacing: 2.5),
    );
  }

  Widget _field(
    bool isDark,
    Color textPrimary,
    Color muted, {
    required String label,
    required IconData icon,
    TextEditingController? controller,
    String? value,
    bool enabled = true,
    bool verified = false,
    TextInputType? keyboardType,
  }) {
    final card = isDark ? Colors.white.withValues(alpha: 0.03) : Colors.white;
    final border = (isDark ? Colors.white : Colors.black).withValues(alpha: isDark ? 0.08 : 0.06);
    final fieldColor = enabled ? textPrimary : muted;

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          label,
          style: GoogleFonts.montserrat(fontSize: 9, fontWeight: FontWeight.w800, color: muted, letterSpacing: 1.5),
        ),
        const SizedBox(height: 6),
        Container(
          decoration: BoxDecoration(
            color: card,
            borderRadius: BorderRadius.circular(16),
            border: Border.all(color: border),
          ),
          padding: const EdgeInsets.symmetric(horizontal: 16),
          child: Row(
            children: [
              Icon(icon, size: 18, color: muted),
              const SizedBox(width: 12),
              Expanded(
                child: controller != null
                    ? TextField(
                        controller: controller,
                        enabled: enabled,
                        keyboardType: keyboardType,
                        style: GoogleFonts.montserrat(fontSize: 14, fontWeight: FontWeight.w600, color: fieldColor),
                        decoration: const InputDecoration(
                          border: InputBorder.none,
                          isDense: true,
                          contentPadding: EdgeInsets.symmetric(vertical: 16),
                        ),
                      )
                    : Padding(
                        padding: const EdgeInsets.symmetric(vertical: 16),
                        child: Text(
                          value ?? '',
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                          style: GoogleFonts.montserrat(fontSize: 14, fontWeight: FontWeight.w600, color: fieldColor),
                        ),
                      ),
              ),
              if (verified) ...[
                const SizedBox(width: 8),
                Container(
                  padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 3),
                  decoration: BoxDecoration(
                    borderRadius: BorderRadius.circular(6),
                    border: Border.all(color: _gold.withValues(alpha: 0.3)),
                  ),
                  child: Text(
                    'VERIFIED',
                    style: GoogleFonts.montserrat(fontSize: 8, fontWeight: FontWeight.w800, color: _gold, letterSpacing: 1),
                  ),
                ),
              ],
            ],
          ),
        ),
      ],
    );
  }

  Widget _toggleTile(
    bool isDark,
    Color textPrimary,
    Color muted, {
    required IconData icon,
    required String title,
    required String subtitle,
    required bool value,
    required ValueChanged<bool> onChanged,
  }) {
    final card = isDark ? Colors.white.withValues(alpha: 0.03) : Colors.white;
    final border = (isDark ? Colors.white : Colors.black).withValues(alpha: isDark ? 0.08 : 0.06);

    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
      decoration: BoxDecoration(
        color: card,
        borderRadius: BorderRadius.circular(20),
        border: Border.all(color: border),
      ),
      child: Row(
        children: [
          Container(
            width: 44,
            height: 44,
            alignment: Alignment.center,
            decoration: BoxDecoration(
              color: _gold.withValues(alpha: 0.1),
              borderRadius: BorderRadius.circular(12),
            ),
            child: Icon(icon, color: _gold, size: 20),
          ),
          const SizedBox(width: 14),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              mainAxisSize: MainAxisSize.min,
              children: [
                Text(
                  title,
                  style: GoogleFonts.montserrat(fontSize: 12, fontWeight: FontWeight.w700, color: textPrimary),
                ),
                const SizedBox(height: 2),
                Text(
                  subtitle,
                  style: GoogleFonts.montserrat(fontSize: 8, fontWeight: FontWeight.w800, color: muted, letterSpacing: 1),
                ),
              ],
            ),
          ),
          Switch(
            value: value,
            onChanged: onChanged,
            activeColor: _gold,
            activeTrackColor: _gold.withValues(alpha: 0.4),
          ),
        ],
      ),
    );
  }

  Widget _signOutButton() {
    return Material(
      color: Colors.transparent,
      child: InkWell(
        onTap: _signOutAllDevices,
        borderRadius: BorderRadius.circular(16),
        child: Container(
          height: 52,
          alignment: Alignment.center,
          decoration: BoxDecoration(
            borderRadius: BorderRadius.circular(16),
            border: Border.all(color: Colors.red.withValues(alpha: 0.2)),
            color: Colors.red.withValues(alpha: 0.05),
          ),
          child: Row(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              const Icon(LucideIcons.logOut, size: 16, color: Colors.red),
              const SizedBox(width: 8),
              Text(
                'SIGN OUT ON ALL DEVICES',
                style: GoogleFonts.montserrat(fontSize: 9, fontWeight: FontWeight.w800, color: Colors.red, letterSpacing: 2),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
