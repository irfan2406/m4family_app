import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:lucide_icons/lucide_icons.dart';
import 'package:go_router/go_router.dart';
import 'package:m4_mobile/core/providers/theme_provider.dart';

/// Guest profile screen — mirrors the web `/guest/profile` page.
/// Unauthenticated state: sign-in / create-account CTAs, "why join" grid,
/// dark-mode preference toggle, and an investor login shortcut.
class GuestProfileScreen extends ConsumerWidget {
  const GuestProfileScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final themeMode = ref.watch(themeProvider);
    final bool isDarkMode = themeMode == ThemeMode.dark;

    final Color bg = isDark ? Colors.black : Colors.white;
    final Color textPrimary = isDark ? Colors.white : Colors.black;
    final Color textMuted =
        isDark ? Colors.white.withValues(alpha: 0.5) : Colors.black.withValues(alpha: 0.5);
    final Color cardColor =
        isDark ? Colors.white.withValues(alpha: 0.03) : Colors.white;
    final Color borderColor =
        isDark ? Colors.white.withValues(alpha: 0.08) : Colors.black.withValues(alpha: 0.06);

    return Scaffold(
      backgroundColor: bg,
      body: Stack(
        children: [
          // Ambient glow (matches web primary/5 blur)
          Positioned(
            top: -60,
            left: -60,
            child: Container(
              width: 220,
              height: 220,
              decoration: BoxDecoration(
                shape: BoxShape.circle,
                color: (isDark ? Colors.white : Colors.black).withValues(alpha: 0.04),
              ),
            ),
          ),
          SafeArea(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                // Header
                Padding(
                  padding: const EdgeInsets.fromLTRB(24, 16, 24, 16),
                  child: Row(
                    children: [
                      _CircleButton(
                        icon: LucideIcons.chevronLeft,
                        onTap: () {
                          if (context.canPop()) {
                            context.pop();
                          } else {
                            context.go('/home');
                          }
                        },
                      ),
                      const SizedBox(width: 16),
                      Text(
                        'MY PROFILE',
                        style: GoogleFonts.montserrat(
                          fontSize: 18,
                          fontWeight: FontWeight.bold,
                          color: textPrimary,
                          letterSpacing: 0.5,
                        ),
                      ),
                    ],
                  ),
                ),
                Expanded(
                  child: SingleChildScrollView(
                    physics: const BouncingScrollPhysics(),
                    padding: const EdgeInsets.fromLTRB(24, 8, 24, 120),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.stretch,
                      children: [
                        // Guest profile card
                        Container(
                          padding: const EdgeInsets.all(32),
                          decoration: BoxDecoration(
                            color: cardColor,
                            borderRadius: BorderRadius.circular(40),
                            border: Border.all(color: borderColor),
                            boxShadow: isDark
                                ? []
                                : [
                                    BoxShadow(
                                      color: Colors.black.withValues(alpha: 0.05),
                                      blurRadius: 30,
                                      offset: const Offset(0, 10),
                                    )
                                  ],
                          ),
                          child: Column(
                            children: [
                              Container(
                                width: 96,
                                height: 96,
                                decoration: BoxDecoration(
                                  shape: BoxShape.circle,
                                  color: isDark
                                      ? Colors.white.withValues(alpha: 0.04)
                                      : const Color(0xFFF4F4F5),
                                  border: Border.all(
                                    color: borderColor,
                                    width: 2,
                                    style: BorderStyle.solid,
                                  ),
                                ),
                                child: Center(
                                  child: Text(
                                    '?',
                                    style: GoogleFonts.montserrat(
                                      fontSize: 30,
                                      fontWeight: FontWeight.bold,
                                      color: textMuted,
                                    ),
                                  ),
                                ),
                              ),
                              const SizedBox(height: 24),
                              Text(
                                'GUEST USER',
                                style: GoogleFonts.montserrat(
                                  fontSize: 22,
                                  fontWeight: FontWeight.bold,
                                  color: textPrimary,
                                  letterSpacing: -0.5,
                                ),
                              ),
                              const SizedBox(height: 8),
                              Text(
                                'SIGN IN TO ACCESS YOUR PERSONALIZED DASHBOARD, DOCUMENTS, AND EXCLUSIVE OFFERS.',
                                textAlign: TextAlign.center,
                                style: GoogleFonts.montserrat(
                                  fontSize: 9,
                                  fontWeight: FontWeight.w900,
                                  color: textMuted,
                                  letterSpacing: 1,
                                  height: 1.6,
                                ),
                              ),
                              const SizedBox(height: 24),
                              _PrimaryButton(
                                label: 'SIGN IN',
                                icon: LucideIcons.logIn,
                                filled: true,
                                onTap: () => context.go('/login'),
                              ),
                              const SizedBox(height: 12),
                              _PrimaryButton(
                                label: 'CREATE ACCOUNT',
                                icon: LucideIcons.userPlus,
                                filled: false,
                                onTap: () => context.go('/login'),
                              ),
                            ],
                          ),
                        ),
                        const SizedBox(height: 32),
                        // Why join
                        Center(
                          child: Text(
                            'WHY JOIN M4 FAMILY?',
                            style: GoogleFonts.montserrat(
                              fontSize: 10,
                              fontWeight: FontWeight.w700,
                              color: textMuted,
                              letterSpacing: 2,
                            ),
                          ),
                        ),
                        const SizedBox(height: 16),
                        Row(
                          children: const [
                            Expanded(
                              child: _InfoTile(
                                title: 'EXCLUSIVE ACCESS',
                                body: 'Get early access to new project launches.',
                              ),
                            ),
                            SizedBox(width: 16),
                            Expanded(
                              child: _InfoTile(
                                title: 'PERSONALIZED',
                                body: 'Track your favorite properties and visits.',
                              ),
                            ),
                          ],
                        ),
                        const SizedBox(height: 32),
                        // Preferences
                        Text(
                          'PREFERENCES',
                          style: GoogleFonts.montserrat(
                            fontSize: 9,
                            fontWeight: FontWeight.w700,
                            color: textMuted,
                            letterSpacing: 2,
                          ),
                        ),
                        const SizedBox(height: 16),
                        Container(
                          padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 16),
                          decoration: BoxDecoration(
                            color: cardColor,
                            borderRadius: BorderRadius.circular(28),
                            border: Border.all(color: borderColor),
                          ),
                          child: Row(
                            children: [
                              Container(
                                width: 40,
                                height: 40,
                                decoration: BoxDecoration(
                                  color: isDark
                                      ? Colors.white.withValues(alpha: 0.05)
                                      : const Color(0xFFF4F4F5),
                                  borderRadius: BorderRadius.circular(12),
                                  border: Border.all(color: borderColor),
                                ),
                                child: Icon(
                                  isDarkMode ? LucideIcons.moon : LucideIcons.globe,
                                  size: 20,
                                  color: textMuted,
                                ),
                              ),
                              const SizedBox(width: 16),
                              Expanded(
                                child: Column(
                                  crossAxisAlignment: CrossAxisAlignment.start,
                                  children: [
                                    Text(
                                      'DARK MODE',
                                      style: GoogleFonts.montserrat(
                                        fontSize: 12,
                                        fontWeight: FontWeight.bold,
                                        color: textPrimary,
                                      ),
                                    ),
                                    const SizedBox(height: 2),
                                    Text(
                                      isDarkMode ? 'ENABLED' : 'DISABLED',
                                      style: GoogleFonts.montserrat(
                                        fontSize: 8,
                                        fontWeight: FontWeight.w900,
                                        color: textMuted,
                                        letterSpacing: 1,
                                      ),
                                    ),
                                  ],
                                ),
                              ),
                              Switch(
                                value: isDarkMode,
                                activeThumbColor: isDark ? Colors.black : Colors.white,
                                activeTrackColor: isDark ? Colors.white : Colors.black,
                                onChanged: (checked) {
                                  ref
                                      .read(themeProvider.notifier)
                                      .setTheme(checked ? ThemeMode.dark : ThemeMode.light);
                                },
                              ),
                            ],
                          ),
                        ),
                        const SizedBox(height: 16),
                        // Investor login
                        _ScaleTap(
                          onTap: () => context.go('/investor/login'),
                          child: Container(
                            height: 56,
                            decoration: BoxDecoration(
                              color: const Color(0xFFFFD700).withValues(alpha: 0.08),
                              borderRadius: BorderRadius.circular(16),
                              border: Border.all(
                                color: const Color(0xFFFFD700).withValues(alpha: 0.25),
                              ),
                            ),
                            child: Center(
                              child: Row(
                                mainAxisSize: MainAxisSize.min,
                                children: [
                                  const Icon(LucideIcons.trendingUp,
                                      size: 16, color: Color(0xFFD4A93B)),
                                  const SizedBox(width: 8),
                                  Text(
                                    'INVESTOR LOGIN',
                                    style: GoogleFonts.montserrat(
                                      fontSize: 10,
                                      fontWeight: FontWeight.w900,
                                      color: const Color(0xFFD4A93B),
                                      letterSpacing: 1.5,
                                    ),
                                  ),
                                ],
                              ),
                            ),
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
}

class _InfoTile extends StatelessWidget {
  final String title;
  final String body;
  const _InfoTile({required this.title, required this.body});

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final Color textPrimary = isDark ? Colors.white : Colors.black;
    final Color textMuted =
        isDark ? Colors.white.withValues(alpha: 0.5) : Colors.black.withValues(alpha: 0.5);
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: (isDark ? Colors.white : Colors.black).withValues(alpha: 0.03),
        borderRadius: BorderRadius.circular(20),
        border: Border.all(
          color: isDark ? Colors.white.withValues(alpha: 0.08) : Colors.black.withValues(alpha: 0.06),
        ),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            title,
            style: GoogleFonts.montserrat(
              fontSize: 11,
              fontWeight: FontWeight.bold,
              color: textPrimary,
            ),
          ),
          const SizedBox(height: 4),
          Text(
            body,
            style: GoogleFonts.montserrat(
              fontSize: 9,
              color: textMuted,
              height: 1.4,
            ),
          ),
        ],
      ),
    );
  }
}

class _PrimaryButton extends StatelessWidget {
  final String label;
  final IconData icon;
  final bool filled;
  final VoidCallback onTap;
  const _PrimaryButton({
    required this.label,
    required this.icon,
    required this.filled,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final Color fg = filled ? (isDark ? Colors.black : Colors.white) : (isDark ? Colors.white : Colors.black);
    final Color bg = filled ? (isDark ? Colors.white : Colors.black) : Colors.transparent;
    return _ScaleTap(
      onTap: onTap,
      child: Container(
        height: 56,
        width: double.infinity,
        decoration: BoxDecoration(
          color: bg,
          borderRadius: BorderRadius.circular(18),
          border: filled
              ? null
              : Border.all(
                  color: isDark ? Colors.white.withValues(alpha: 0.15) : Colors.black.withValues(alpha: 0.12)),
        ),
        child: Center(
          child: Row(
            mainAxisSize: MainAxisSize.min,
            children: [
              Icon(icon, size: 16, color: fg),
              const SizedBox(width: 8),
              Text(
                label,
                style: GoogleFonts.montserrat(
                  fontSize: 11,
                  fontWeight: FontWeight.bold,
                  color: fg,
                  letterSpacing: 1.5,
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class _CircleButton extends StatelessWidget {
  final IconData icon;
  final VoidCallback onTap;
  const _CircleButton({required this.icon, required this.onTap});

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    return _ScaleTap(
      onTap: onTap,
      child: Container(
        width: 40,
        height: 40,
        decoration: BoxDecoration(
          shape: BoxShape.circle,
          color: isDark ? Colors.white.withValues(alpha: 0.05) : const Color(0xFFF4F4F5),
          border: Border.all(
            color: isDark ? Colors.white.withValues(alpha: 0.08) : Colors.black.withValues(alpha: 0.06),
          ),
        ),
        child: Icon(icon, size: 20, color: isDark ? Colors.white : Colors.black),
      ),
    );
  }
}

class _ScaleTap extends StatefulWidget {
  final Widget child;
  final VoidCallback onTap;
  const _ScaleTap({required this.child, required this.onTap});

  @override
  State<_ScaleTap> createState() => _ScaleTapState();
}

class _ScaleTapState extends State<_ScaleTap> {
  bool _pressed = false;
  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTapDown: (_) => setState(() => _pressed = true),
      onTapUp: (_) => setState(() => _pressed = false),
      onTapCancel: () => setState(() => _pressed = false),
      onTap: widget.onTap,
      child: AnimatedScale(
        scale: _pressed ? 0.96 : 1.0,
        duration: const Duration(milliseconds: 100),
        child: widget.child,
      ),
    );
  }
}
