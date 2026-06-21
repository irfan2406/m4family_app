import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:lucide_icons/lucide_icons.dart';
import 'package:go_router/go_router.dart';
import 'package:m4_mobile/core/providers/theme_provider.dart';
import 'package:m4_mobile/core/theme/app_theme.dart';
import 'package:m4_mobile/presentation/providers/auth_provider.dart';

class AppSettingsScreen extends ConsumerStatefulWidget {
  const AppSettingsScreen({super.key});

  @override
  ConsumerState<AppSettingsScreen> createState() => _AppSettingsScreenState();
}

class _AppSettingsScreenState extends ConsumerState<AppSettingsScreen> {
  bool _pushNotifications = true;
  bool _emailNotifications = false;
  bool _darkMode = false;
  bool _biometricAccess = true;
  bool _autoRefresh = true;

  @override
  void initState() {
    super.initState();
    _loadSettings();
  }

  void _loadSettings() {
    final user = ref.read(authProvider).user;
    _pushNotifications = user?['pushNotifications'] ?? true;
    _emailNotifications = user?['emailNotifications'] ?? false;
    _biometricAccess = user?['biometricAccess'] ?? true;
    _autoRefresh = user?['autoRefresh'] ?? true;
    // Dark mode is reflected from the active theme provider.
    _darkMode = ref.read(themeProvider) == ThemeMode.dark;
  }

  Future<void> _persist() async {
    try {
      await ref.read(apiClientProvider).updatePreferences({
        'darkMode': _darkMode,
        'pushNotifications': _pushNotifications,
        'emailNotifications': _emailNotifications,
        'biometricAccess': _biometricAccess,
        'autoRefresh': _autoRefresh,
      });
    } catch (_) {
      // Silent fail — settings apply locally (matches profile_settings pattern).
    }
  }

  void _onToggle(String key, bool value) {
    setState(() {
      switch (key) {
        case 'push':
          _pushNotifications = value;
          break;
        case 'email':
          _emailNotifications = value;
          break;
        case 'biometric':
          _biometricAccess = value;
          break;
        case 'autoRefresh':
          _autoRefresh = value;
          break;
      }
    });
    _persist();
  }

  void _onDarkModeToggle(bool value) {
    setState(() => _darkMode = value);
    ref.read(themeProvider.notifier).setTheme(value ? ThemeMode.dark : ThemeMode.light);
    _persist();
  }

  @override
  Widget build(BuildContext context) {
    // Keep local dark-mode flag in sync with the active theme.
    final themeMode = ref.watch(themeProvider);
    _darkMode = themeMode == ThemeMode.dark;
    final isDark = themeMode == ThemeMode.dark;

    final bg = isDark ? const Color(0xFF09090B) : const Color(0xFFF8FAFC);

    return Scaffold(
      backgroundColor: bg,
      body: SafeArea(
        child: Column(
          children: [
            _buildHeader(isDark),
            Expanded(
              child: SingleChildScrollView(
                physics: const BouncingScrollPhysics(),
                padding: const EdgeInsets.all(24),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    _buildCommunicationsCard(isDark),
                    const SizedBox(height: 16),
                    _buildAppearanceCard(isDark),
                    const SizedBox(height: 16),
                    _buildSecurityCard(isDark),
                    const SizedBox(height: 16),
                    _buildPreferencesCard(isDark),
                    const SizedBox(height: 100),
                  ],
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildHeader(bool isDark) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 16),
      decoration: BoxDecoration(
        border: Border(
          bottom: BorderSide(
            color: (isDark ? Colors.white : Colors.black).withValues(alpha: 0.06),
          ),
        ),
      ),
      child: Row(
        children: [
          _IconButton(
            icon: LucideIcons.chevronLeft,
            isDark: isDark,
            onTap: () {
              if (context.canPop()) {
                context.pop();
              } else {
                context.go('/profile');
              }
            },
          ),
          const SizedBox(width: 16),
          Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                'APP SETTINGS',
                style: GoogleFonts.montserrat(
                  fontSize: 14,
                  fontWeight: FontWeight.w800,
                  color: isDark ? Colors.white : Colors.black,
                  letterSpacing: 2,
                ),
              ),
              const SizedBox(height: 4),
              Text(
                'PLATFORM PREFERENCES',
                style: GoogleFonts.montserrat(
                  fontSize: 10,
                  fontWeight: FontWeight.w800,
                  color: (isDark ? Colors.white : Colors.black).withValues(alpha: 0.5),
                  letterSpacing: 2,
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }

  // ─── Cards ──────────────────────────────────────────────────────────────

  Widget _buildCommunicationsCard(bool isDark) {
    return _buildCard(
      isDark,
      label: 'COMMUNICATIONS',
      children: [
        _buildToggleTile(
          isDark,
          icon: LucideIcons.bell,
          title: 'PUSH ALERTS',
          subtitle: 'INSTANT UPDATES',
          value: _pushNotifications,
          onChanged: (v) => _onToggle('push', v),
        ),
        const SizedBox(height: 12),
        _buildToggleTile(
          isDark,
          icon: LucideIcons.globe,
          title: 'EMAIL REPORTS',
          subtitle: 'DEEPER INSIGHTS',
          value: _emailNotifications,
          onChanged: (v) => _onToggle('email', v),
        ),
      ],
    );
  }

  Widget _buildAppearanceCard(bool isDark) {
    return _buildCard(
      isDark,
      label: 'VISUAL EXPERIENCE',
      children: [
        _buildToggleTile(
          isDark,
          icon: LucideIcons.moon,
          title: 'FORCE DARK MODE',
          subtitle: 'PREMIUM AESTHETIC',
          value: _darkMode,
          onChanged: _onDarkModeToggle,
        ),
      ],
    );
  }

  Widget _buildSecurityCard(bool isDark) {
    return _buildCard(
      isDark,
      label: 'DATA SECURITY',
      children: [
        _buildToggleTile(
          isDark,
          icon: LucideIcons.smartphone,
          title: 'BIOMETRIC ACCESS',
          subtitle: 'FACE ID / TOUCH ID',
          value: _biometricAccess,
          onChanged: (v) => _onToggle('biometric', v),
        ),
      ],
    );
  }

  Widget _buildPreferencesCard(bool isDark) {
    return _buildCard(
      isDark,
      label: 'SYSTEM PREFERENCES',
      children: [
        _buildToggleTile(
          isDark,
          icon: LucideIcons.palette,
          title: 'AUTO REFRESH',
          subtitle: 'KEEP DATA UPDATED',
          value: _autoRefresh,
          onChanged: (v) => _onToggle('autoRefresh', v),
        ),
      ],
    );
  }

  // ─── Reusable building blocks ───────────────────────────────────────────

  Widget _buildCard(bool isDark, {required String label, required List<Widget> children}) {
    final card = isDark ? Colors.white.withValues(alpha: 0.03) : Colors.white;
    final border = isDark ? Colors.white.withValues(alpha: 0.08) : Colors.black.withValues(alpha: 0.06);

    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(24),
      decoration: BoxDecoration(
        color: card,
        borderRadius: BorderRadius.circular(32),
        border: Border.all(color: border),
        boxShadow: isDark
            ? []
            : [BoxShadow(color: Colors.black.withValues(alpha: 0.05), blurRadius: 20, offset: const Offset(0, 10))],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            label,
            style: GoogleFonts.montserrat(
              fontSize: 8,
              fontWeight: FontWeight.w800,
              color: (isDark ? Colors.white : Colors.black).withValues(alpha: 0.5),
              letterSpacing: 3.2,
            ),
          ),
          const SizedBox(height: 16),
          ...children,
        ],
      ),
    );
  }

  Widget _buildToggleTile(
    bool isDark, {
    required IconData icon,
    required String title,
    required String subtitle,
    required bool value,
    required ValueChanged<bool> onChanged,
  }) {
    final tileBg = isDark ? Colors.white.withValues(alpha: 0.03) : Colors.white;
    final tileBorder = isDark ? Colors.white.withValues(alpha: 0.08) : Colors.black.withValues(alpha: 0.06);
    final iconBg = isDark ? M4Theme.premiumBlue.withValues(alpha: 0.08) : Colors.black.withValues(alpha: 0.05);
    final iconColor = isDark ? Colors.white : Colors.black;
    final textPrimary = isDark ? Colors.white : Colors.black;
    final muted = (isDark ? Colors.white : Colors.black).withValues(alpha: 0.5);

    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 12),
      decoration: BoxDecoration(
        color: tileBg,
        borderRadius: BorderRadius.circular(20),
        border: Border.all(color: tileBorder),
      ),
      child: Row(
        children: [
          Container(
            width: 56,
            height: 56,
            decoration: BoxDecoration(
              color: iconBg,
              borderRadius: BorderRadius.circular(24),
            ),
            child: Icon(icon, color: iconColor, size: 20),
          ),
          const SizedBox(width: 16),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              mainAxisSize: MainAxisSize.min,
              children: [
                Text(
                  title,
                  style: GoogleFonts.montserrat(
                    fontSize: 10,
                    fontWeight: FontWeight.w800,
                    color: textPrimary,
                  ),
                ),
                const SizedBox(height: 4),
                Text(
                  subtitle,
                  style: GoogleFonts.montserrat(
                    fontSize: 8,
                    fontWeight: FontWeight.w700,
                    color: muted,
                    letterSpacing: 1.6,
                  ),
                ),
              ],
            ),
          ),
          Switch(
            value: value,
            onChanged: onChanged,
            activeColor: isDark ? Colors.white : Colors.black,
            activeTrackColor: isDark ? Colors.white24 : Colors.black12,
          ),
        ],
      ),
    );
  }
}

class _IconButton extends StatelessWidget {
  final IconData icon;
  final bool isDark;
  final VoidCallback onTap;
  const _IconButton({required this.icon, required this.isDark, required this.onTap});

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        padding: const EdgeInsets.all(12),
        decoration: BoxDecoration(
          color: isDark ? const Color(0xFF18181B) : Colors.white,
          borderRadius: BorderRadius.circular(14),
          border: Border.all(color: (isDark ? Colors.white : Colors.black).withValues(alpha: 0.05)),
          boxShadow: isDark
              ? []
              : [BoxShadow(color: Colors.black.withValues(alpha: 0.05), blurRadius: 10, offset: const Offset(0, 4))],
        ),
        child: Icon(icon, color: isDark ? Colors.white54 : Colors.black54, size: 20),
      ),
    );
  }
}
