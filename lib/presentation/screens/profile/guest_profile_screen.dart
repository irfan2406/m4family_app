import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:lucide_icons/lucide_icons.dart';
import 'package:go_router/go_router.dart';
import 'package:m4_mobile/core/utils/feature_flags.dart';
import 'package:m4_mobile/presentation/widgets/guest_main_shell.dart';
import 'package:m4_mobile/presentation/widgets/side_menu_button.dart';

/// Guest profile / Account tab — sign-in CTAs, portal feature cards, tools.
class GuestProfileScreen extends ConsumerWidget {
  /// When true, shown as the guest shell Account tab (side menu, no back).
  final bool embedded;

  const GuestProfileScreen({super.key, this.embedded = false});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final showPortalLogins = watchShowLoginOption(ref);

    final Color bg = isDark ? Colors.black : const Color(0xFFF4EFE3);
    final Color textPrimary = isDark ? Colors.white : const Color(0xFF0C312B);
    final Color textMuted = isDark
        ? Colors.white.withValues(alpha: 0.5)
        : Colors.black.withValues(alpha: 0.5);
    final Color cardColor = isDark
        ? Colors.white.withValues(alpha: 0.03)
        : Colors.white;
    final Color borderColor = isDark
        ? Colors.white.withValues(alpha: 0.08)
        : Colors.black.withValues(alpha: 0.06);

    return Scaffold(
      backgroundColor: bg,
      body: Stack(
        children: [
          Positioned(
            top: -60,
            left: -60,
            child: Container(
              width: 220,
              height: 220,
              decoration: BoxDecoration(
                shape: BoxShape.circle,
                color: (isDark ? Colors.white : const Color(0xFF0C312B))
                    .withValues(alpha: 0.04),
              ),
            ),
          ),
          SafeArea(
            bottom: false,
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Padding(
                  padding: const EdgeInsets.fromLTRB(20, 12, 24, 8),
                  child: Row(
                    children: [
                      if (embedded)
                        const SideMenuButton()
                      else
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
                      const SizedBox(width: 14),
                      Text(
                        'ACCOUNT',
                        style: GoogleFonts.gelasio(
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
                        Container(
                          padding: const EdgeInsets.all(28),
                          decoration: BoxDecoration(
                            color: cardColor,
                            borderRadius: BorderRadius.circular(32),
                            border: Border.all(color: borderColor),
                            boxShadow: isDark
                                ? []
                                : [
                                    BoxShadow(
                                      color: Colors.black.withValues(
                                        alpha: 0.05,
                                      ),
                                      blurRadius: 30,
                                      offset: const Offset(0, 10),
                                    ),
                                  ],
                          ),
                          child: Column(
                            children: [
                              Container(
                                width: 88,
                                height: 88,
                                decoration: BoxDecoration(
                                  shape: BoxShape.circle,
                                  color: isDark
                                      ? Colors.white.withValues(alpha: 0.04)
                                      : const Color(0xFFF4EFE3),
                                  border: Border.all(
                                    color: borderColor,
                                    width: 2,
                                  ),
                                ),
                                child: Center(
                                  child: Icon(
                                    LucideIcons.sparkles,
                                    size: 32,
                                    color: textMuted,
                                  ),
                                ),
                              ),
                              const SizedBox(height: 20),
                              Text(
                                showPortalLogins
                                    ? 'YOUR M4 ACCOUNT'
                                    : 'M4 FAMILY TOOLS',
                                style: GoogleFonts.gelasio(
                                  fontSize: 20,
                                  fontWeight: FontWeight.bold,
                                  color: textPrimary,
                                  letterSpacing: -0.5,
                                ),
                              ),
                              const SizedBox(height: 8),
                              Text(
                                showPortalLogins
                                    ? 'Sign in to track bookings, open support tickets, manage referrals, and access your property documents.'
                                    : 'Browse projects, schedule a site visit, save favourites, and estimate EMI — all without creating an account.',
                                textAlign: TextAlign.center,
                                style: GoogleFonts.inter(
                                  fontSize: 12,
                                  fontWeight: FontWeight.w500,
                                  color: textMuted,
                                  height: 1.5,
                                ),
                              ),
                              if (showPortalLogins) ...[
                                const SizedBox(height: 22),
                                _PrimaryButton(
                                  label: 'CUSTOMER SIGN IN',
                                  icon: LucideIcons.logIn,
                                  filled: true,
                                  onTap: () => context.go('/login'),
                                ),
                                const SizedBox(height: 12),
                                _PrimaryButton(
                                  label: 'CREATE CUSTOMER ACCOUNT',
                                  icon: LucideIcons.userPlus,
                                  filled: false,
                                  onTap: () => context.go('/login'),
                                ),
                              ],
                            ],
                          ),
                        ),
                        const SizedBox(height: 28),
                        Text(
                          showPortalLogins ? 'PORTALS & TOOLS' : 'TOOLS',
                          style: GoogleFonts.gelasio(
                            fontSize: 10,
                            fontWeight: FontWeight.w700,
                            color: textMuted,
                            letterSpacing: 2,
                          ),
                        ),
                        const SizedBox(height: 12),
                        if (showPortalLogins) ...[
                          _PortalCard(
                            icon: LucideIcons.home,
                            title: 'Customer',
                            body:
                                'Track bookings, site visits, support tickets, and your property portfolio.',
                            actionLabel: 'Sign in',
                            onTap: () => context.go('/login'),
                          ),
                          const SizedBox(height: 10),
                          _PortalCard(
                            icon: LucideIcons.briefcase,
                            title: 'Channel Partner',
                            body:
                                'Manage referrals, commissions, visit tracker, and your CP wallet.',
                            actionLabel: 'CP login',
                            onTap: () =>
                                context.push('/auth/cp/login?from=guest'),
                          ),
                          const SizedBox(height: 10),
                          _PortalCard(
                            icon: LucideIcons.trendingUp,
                            title: 'Investor',
                            body:
                                'Documents vault, installment schedule, payments, and portfolio.',
                            actionLabel: 'Investor login',
                            onTap: () => context.go('/investor/login'),
                          ),
                          const SizedBox(height: 10),
                        ],
                        _PortalCard(
                          icon: LucideIcons.calculator,
                          title: 'EMI Calculator',
                          body:
                              'Estimate monthly payments for a property — no sign-in required.',
                          actionLabel: 'Open',
                          onTap: () => context.push('/guest/calculator'),
                        ),
                        const SizedBox(height: 10),
                        _PortalCard(
                          icon: LucideIcons.calendarDays,
                          title: 'Book a Visit',
                          body:
                              'Schedule a site viewing with date, time, and project selection.',
                          actionLabel: 'Schedule',
                          onTap: () {
                            ref.read(guestNavigationProvider.notifier).state =
                                2;
                            context.go('/home');
                          },
                        ),
                        const SizedBox(height: 10),
                        _PortalCard(
                          icon: LucideIcons.heart,
                          title: 'Saved Projects',
                          body:
                              'Revisit properties you have shortlisted with the heart button.',
                          actionLabel: 'Open',
                          onTap: () {
                            ref.read(guestNavigationProvider.notifier).state =
                                3;
                            context.go('/home');
                          },
                        ),
                        const SizedBox(height: 10),
                        _PortalCard(
                          icon: LucideIcons.phone,
                          title: 'Contact Support',
                          body:
                              'Message our team from the app for questions about projects or visits.',
                          actionLabel: 'Contact',
                          onTap: () => context.push('/contact'),
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

class _PortalCard extends StatelessWidget {
  final IconData icon;
  final String title;
  final String body;
  final String actionLabel;
  final VoidCallback onTap;

  const _PortalCard({
    required this.icon,
    required this.title,
    required this.body,
    required this.actionLabel,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final textPrimary = isDark ? Colors.white : const Color(0xFF0C312B);
    final textMuted = isDark
        ? Colors.white.withValues(alpha: 0.5)
        : Colors.black.withValues(alpha: 0.5);

    return Material(
      color: isDark
          ? Colors.white.withValues(alpha: 0.03)
          : Colors.white.withValues(alpha: 0.85),
      borderRadius: BorderRadius.circular(18),
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(18),
        child: Container(
          padding: const EdgeInsets.all(16),
          decoration: BoxDecoration(
            borderRadius: BorderRadius.circular(18),
            border: Border.all(
              color: isDark
                  ? Colors.white.withValues(alpha: 0.08)
                  : Colors.black.withValues(alpha: 0.06),
            ),
          ),
          child: Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Container(
                width: 40,
                height: 40,
                decoration: BoxDecoration(
                  shape: BoxShape.circle,
                  color: textPrimary.withValues(alpha: 0.06),
                ),
                child: Icon(icon, size: 18, color: textPrimary),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      title,
                      style: GoogleFonts.inter(
                        fontSize: 14,
                        fontWeight: FontWeight.w700,
                        color: textPrimary,
                      ),
                    ),
                    const SizedBox(height: 4),
                    Text(
                      body,
                      style: GoogleFonts.inter(
                        fontSize: 12,
                        height: 1.4,
                        color: textMuted,
                      ),
                    ),
                    const SizedBox(height: 8),
                    Text(
                      actionLabel.toUpperCase(),
                      style: GoogleFonts.inter(
                        fontSize: 10,
                        fontWeight: FontWeight.w700,
                        letterSpacing: 1.2,
                        color: const Color(0xFF155A4F),
                      ),
                    ),
                  ],
                ),
              ),
              Icon(
                LucideIcons.chevronRight,
                size: 16,
                color: textMuted,
              ),
            ],
          ),
        ),
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
    final Color fg = filled
        ? (isDark ? Colors.black : const Color(0xFFF4EFE3))
        : (isDark ? Colors.white : const Color(0xFF0C312B));
    final Color bg = filled
        ? (isDark ? Colors.white : const Color(0xFF0C312B))
        : Colors.transparent;
    return _ScaleTap(
      onTap: onTap,
      child: Container(
        height: 52,
        width: double.infinity,
        decoration: BoxDecoration(
          color: bg,
          borderRadius: BorderRadius.circular(16),
          border: filled
              ? null
              : Border.all(
                  color: isDark
                      ? Colors.white.withValues(alpha: 0.15)
                      : Colors.black.withValues(alpha: 0.12),
                ),
        ),
        child: Center(
          child: Row(
            mainAxisSize: MainAxisSize.min,
            children: [
              Icon(icon, size: 16, color: fg),
              const SizedBox(width: 8),
              Text(
                label,
                style: GoogleFonts.gelasio(
                  fontSize: 11,
                  fontWeight: FontWeight.bold,
                  color: fg,
                  letterSpacing: 1.2,
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
          color: isDark
              ? Colors.white.withValues(alpha: 0.05)
              : const Color(0xFFF4EFE3),
          border: Border.all(
            color: isDark
                ? Colors.white.withValues(alpha: 0.08)
                : Colors.black.withValues(alpha: 0.06),
          ),
        ),
        child: Icon(
          icon,
          size: 20,
          color: isDark ? Colors.white : const Color(0xFF0C312B),
        ),
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
