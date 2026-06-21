import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:lucide_icons/lucide_icons.dart';
import 'package:m4_mobile/core/theme/app_theme.dart';

/// CP Security & Privacy — biometric / 2FA toggles, login history, device sessions.
/// Web parity: app/(cp)/cp/security/page.tsx
/// (WealthModeLayout + SectionHeader patterns mirrored in native M4 styling.)
class CpSecurityScreen extends ConsumerStatefulWidget {
  const CpSecurityScreen({super.key});

  @override
  ConsumerState<CpSecurityScreen> createState() => _CpSecurityScreenState();
}

class _CpSecurityScreenState extends ConsumerState<CpSecurityScreen> {
  static const _green = Color(0xFF22C55E);
  static const _blue = Color(0xFF3B82F6);
  static const _purple = Color(0xFF8B5CF6);

  bool _biometricEnabled = true;
  bool _twoFactorEnabled = true;

  // Mirrors web mock login history (device sessions / recent activity).
  final List<Map<String, String>> _loginHistory = const [
    {
      'device': 'iPhone 14 Pro',
      'location': 'Mumbai, IN',
      'time': 'Just now',
      'status': 'Active',
    },
    {
      'device': 'Chrome / Windows',
      'location': 'Bangalore, IN',
      'time': 'Yesterday, 10:45 AM',
      'status': 'Logged out',
    },
    {
      'device': 'Safari / Mac',
      'location': 'Mumbai, IN',
      'time': 'Feb 02, 4:30 PM',
      'status': 'Logged out',
    },
  ];

  void _toast(String msg) {
    if (!mounted) return;
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(content: Text(msg, style: GoogleFonts.montserrat(fontSize: 12))),
    );
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
      appBar: AppBar(
        backgroundColor: bg,
        elevation: 0,
        leading: IconButton(
          icon: Icon(LucideIcons.arrowLeft, color: textPrimary),
          onPressed: () =>
              context.canPop() ? context.pop() : context.go('/cp/dashboard'),
        ),
        title: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          mainAxisSize: MainAxisSize.min,
          children: [
            Row(
              mainAxisSize: MainAxisSize.min,
              children: [
                Container(
                  width: 6,
                  height: 6,
                  decoration: const BoxDecoration(
                    shape: BoxShape.circle,
                    color: _purple,
                  ),
                ),
                const SizedBox(width: 8),
                Text(
                  'Security & Privacy',
                  style: GoogleFonts.montserrat(
                    fontWeight: FontWeight.w800,
                    fontSize: 16,
                    color: textPrimary,
                  ),
                ),
              ],
            ),
            Padding(
              padding: const EdgeInsets.only(left: 14, top: 1),
              child: Text(
                'ACCOUNT PROTECTION',
                style: GoogleFonts.montserrat(
                  fontSize: 9,
                  letterSpacing: 1.5,
                  fontWeight: FontWeight.w600,
                  color: muted,
                ),
              ),
            ),
          ],
        ),
      ),
      body: ListView(
        physics: const AlwaysScrollableScrollPhysics(),
        padding: EdgeInsets.zero,
        children: [
          _statusBanner(isDark, textPrimary, muted, border),
          Padding(
            padding: const EdgeInsets.fromLTRB(16, 24, 16, 8),
            child: _sectionLabel('AUTHENTICATION', muted),
          ),
          _authTile(
            icon: LucideIcons.smartphone,
            accent: _blue,
            title: 'Biometric Login',
            subtitle: 'FaceID / TouchID access',
            value: _biometricEnabled,
            onChanged: (v) {
              setState(() => _biometricEnabled = v);
              _toast(
                v ? 'Biometric login enabled' : 'Biometric login disabled',
              );
            },
            textPrimary: textPrimary,
            muted: muted,
            card: card,
            border: border,
          ),
          _authTile(
            icon: LucideIcons.key,
            accent: _purple,
            title: 'Two-Factor Auth',
            subtitle: 'OTP verification on login',
            value: _twoFactorEnabled,
            onChanged: (v) {
              setState(() => _twoFactorEnabled = v);
              _toast(v ? '2FA enabled' : '2FA disabled');
            },
            textPrimary: textPrimary,
            muted: muted,
            card: card,
            border: border,
          ),
          Padding(
            padding: const EdgeInsets.fromLTRB(16, 28, 16, 8),
            child: _sectionLabel('RECENT ACTIVITY', muted),
          ),
          _historyCard(isDark, textPrimary, muted, card, border),
          _signOutAllButton(muted, textPrimary),
          const SizedBox(height: 32),
        ],
      ),
    );
  }

  // ─── Security Status Banner ─────────────────────────────────────────────────
  Widget _statusBanner(
    bool isDark,
    Color textPrimary,
    Color muted,
    Color border,
  ) {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.fromLTRB(24, 28, 24, 28),
      decoration: BoxDecoration(
        border: Border(bottom: BorderSide(color: border)),
      ),
      child: Column(
        children: [
          SizedBox(
            width: 80,
            height: 80,
            child: Stack(
              clipBehavior: Clip.none,
              children: [
                Container(
                  width: 80,
                  height: 80,
                  decoration: BoxDecoration(
                    shape: BoxShape.circle,
                    color: _green.withValues(alpha: 0.1),
                    border: Border.all(color: _green.withValues(alpha: 0.2)),
                  ),
                  child: const Icon(LucideIcons.shield, size: 32, color: _green),
                ),
                Positioned(
                  top: 0,
                  right: 0,
                  child: Container(
                    width: 24,
                    height: 24,
                    decoration: BoxDecoration(
                      shape: BoxShape.circle,
                      color: _green,
                      border: Border.all(
                        color: isDark ? Colors.black : Colors.white,
                        width: 4,
                      ),
                    ),
                    child: Icon(
                      LucideIcons.check,
                      size: 12,
                      color: isDark ? Colors.black : Colors.white,
                    ),
                  ),
                ),
              ],
            ),
          ),
          const SizedBox(height: 16),
          Text(
            'Account Protected',
            style: GoogleFonts.montserrat(
              fontSize: 18,
              fontWeight: FontWeight.w700,
              color: textPrimary,
            ),
          ),
          const SizedBox(height: 4),
          SizedBox(
            width: 220,
            child: Text(
              'Your account is secured with military-grade encryption and 2FA.',
              textAlign: TextAlign.center,
              style: GoogleFonts.montserrat(
                fontSize: 11,
                fontWeight: FontWeight.w500,
                height: 1.4,
                color: muted,
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _sectionLabel(String label, Color muted) {
    return Text(
      label,
      style: GoogleFonts.montserrat(
        fontSize: 10,
        fontWeight: FontWeight.bold,
        letterSpacing: 2,
        color: muted,
      ),
    );
  }

  // ─── Authentication Toggle Tile ─────────────────────────────────────────────
  Widget _authTile({
    required IconData icon,
    required Color accent,
    required String title,
    required String subtitle,
    required bool value,
    required ValueChanged<bool> onChanged,
    required Color textPrimary,
    required Color muted,
    required Color card,
    required Color border,
  }) {
    return Padding(
      padding: const EdgeInsets.fromLTRB(16, 0, 16, 12),
      child: Container(
        padding: const EdgeInsets.all(16),
        decoration: BoxDecoration(
          color: card,
          borderRadius: BorderRadius.circular(14),
          border: Border.all(color: border),
        ),
        child: Row(
          children: [
            Container(
              width: 40,
              height: 40,
              decoration: BoxDecoration(
                color: accent.withValues(alpha: 0.1),
                borderRadius: BorderRadius.circular(10),
              ),
              child: Icon(icon, size: 20, color: accent),
            ),
            const SizedBox(width: 16),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    title,
                    style: GoogleFonts.montserrat(
                      fontSize: 13,
                      fontWeight: FontWeight.w600,
                      color: textPrimary,
                    ),
                  ),
                  const SizedBox(height: 2),
                  Text(
                    subtitle,
                    style: GoogleFonts.montserrat(
                      fontSize: 10,
                      fontWeight: FontWeight.w500,
                      color: muted,
                    ),
                  ),
                ],
              ),
            ),
            const SizedBox(width: 8),
            Switch.adaptive(
              value: value,
              onChanged: onChanged,
              activeThumbColor: Colors.white,
              activeTrackColor: M4Theme.premiumBlue,
            ),
          ],
        ),
      ),
    );
  }

  // ─── Login History / Device Sessions ────────────────────────────────────────
  Widget _historyCard(
    bool isDark,
    Color textPrimary,
    Color muted,
    Color card,
    Color border,
  ) {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 16),
      child: Container(
        decoration: BoxDecoration(
          borderRadius: BorderRadius.circular(14),
          border: Border.all(color: border),
        ),
        clipBehavior: Clip.antiAlias,
        child: Column(
          children: [
            for (int i = 0; i < _loginHistory.length; i++)
              _historyRow(
                _loginHistory[i],
                isLast: i == _loginHistory.length - 1,
                isDark: isDark,
                textPrimary: textPrimary,
                muted: muted,
                card: card,
                border: border,
              ),
          ],
        ),
      ),
    );
  }

  Widget _historyRow(
    Map<String, String> login, {
    required bool isLast,
    required bool isDark,
    required Color textPrimary,
    required Color muted,
    required Color card,
    required Color border,
  }) {
    final isActive = login['status'] == 'Active';
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: isDark ? Colors.white.withValues(alpha: 0.02) : card,
        border: isLast
            ? null
            : Border(bottom: BorderSide(color: border)),
      ),
      child: Row(
        children: [
          Icon(LucideIcons.history, size: 16, color: muted),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  login['device'] ?? '',
                  style: GoogleFonts.montserrat(
                    fontSize: 12,
                    fontWeight: FontWeight.w500,
                    color: textPrimary,
                  ),
                ),
                const SizedBox(height: 2),
                Text(
                  '${login['location'] ?? ''} • ${login['time'] ?? ''}',
                  style: GoogleFonts.montserrat(
                    fontSize: 9,
                    fontWeight: FontWeight.w500,
                    color: muted,
                  ),
                ),
              ],
            ),
          ),
          const SizedBox(width: 8),
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 3),
            decoration: BoxDecoration(
              color: isActive
                  ? _green.withValues(alpha: 0.1)
                  : card,
              borderRadius: BorderRadius.circular(6),
              border: Border.all(
                color: isActive ? _green.withValues(alpha: 0.2) : border,
              ),
            ),
            child: Text(
              (login['status'] ?? '').toUpperCase(),
              style: GoogleFonts.montserrat(
                fontSize: 8,
                fontWeight: FontWeight.bold,
                letterSpacing: 1,
                color: isActive ? _green : muted,
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _signOutAllButton(Color muted, Color textPrimary) {
    return Padding(
      padding: const EdgeInsets.fromLTRB(16, 12, 16, 0),
      child: SizedBox(
        width: double.infinity,
        child: TextButton(
          onPressed: () => _toast('Signed out of all devices'),
          style: TextButton.styleFrom(
            padding: const EdgeInsets.symmetric(vertical: 14),
          ),
          child: Text(
            'SIGN OUT OF ALL DEVICES',
            style: GoogleFonts.montserrat(
              fontSize: 10,
              fontWeight: FontWeight.bold,
              letterSpacing: 2,
              color: muted,
            ),
          ),
        ),
      ),
    );
  }
}
