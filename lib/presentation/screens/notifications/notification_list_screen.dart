import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:lucide_icons/lucide_icons.dart';
import 'package:m4_mobile/presentation/providers/notification_provider.dart';
import 'package:flutter_animate/flutter_animate.dart';
import 'package:intl/intl.dart';
import 'package:m4_mobile/presentation/widgets/main_shell.dart';
import 'package:m4_mobile/presentation/providers/cp_shell_provider.dart';
import 'package:m4_mobile/presentation/providers/auth_provider.dart';

/// Shared notifications screen — web parity with `(cp)/cp/notifications`,
/// `(user)/notifications`, `investor/notifications`. Card design is identical
/// across portals; only the subtitle ("Partner Updates" for CP vs "Stay
/// updated"), the sparkle icon, and the purple accents are CP-specific.

/// Web `getIcon(type)`: default→indigo, success→green, alert→amber,
/// promotion→purple. Returns (icon, foreground, background).
({IconData icon, Color fg}) _iconFor(String? type) {
  switch ((type ?? 'default').toLowerCase()) {
    case 'success':
      return (icon: LucideIcons.checkCircle, fg: const Color(0xFF16A34A));
    case 'alert':
      return (icon: LucideIcons.alertTriangle, fg: const Color(0xFFF59E0B));
    case 'promotion':
      return (icon: LucideIcons.percent, fg: const Color(0xFF9333EA));
    default:
      return (
        icon: LucideIcons.info,
        fg: const Color(0xFF4F46E5),
      ); // indigo-600
  }
}

class NotificationListScreen extends ConsumerWidget {
  const NotificationListScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final state = ref.watch(notificationProvider);
    final scheme = Theme.of(context).colorScheme;
    final auth = ref.watch(authProvider);
    final role = (auth.user?['role'] ?? auth.role ?? '')
        .toString()
        .toLowerCase();
    final isCp = role == 'cp';
    const purple = Color(0xFF9333EA);

    return Material(
      color: Theme.of(context).scaffoldBackgroundColor,
      child: SafeArea(
        child: Column(
          children: [
            // Header
            Padding(
              padding: const EdgeInsets.fromLTRB(16, 16, 16, 12),
              child: Row(
                children: [
                  // Back button in a rounded card (web: rounded-xl glass).
                  GestureDetector(
                    onTap: () {
                      if (Navigator.canPop(context)) {
                        Navigator.pop(context);
                      } else {
                        final previousIndex = ref.read(
                          previousNavigationProvider,
                        );
                        ref.read(navigationProvider.notifier).state =
                            previousIndex;
                        try {
                          ref.read(cpNavigationIndexProvider.notifier).state =
                              previousIndex;
                        } catch (_) {}
                      }
                    },
                    child: Container(
                      width: 40,
                      height: 40,
                      alignment: Alignment.center,
                      decoration: BoxDecoration(
                        color: scheme.surface,
                        borderRadius: BorderRadius.circular(12),
                        border: Border.all(
                          color: scheme.outlineVariant.withValues(alpha: 0.4),
                        ),
                      ),
                      child: Icon(
                        LucideIcons.arrowLeft,
                        color: scheme.onSurface,
                        size: 18,
                      ),
                    ),
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Row(
                          children: [
                            if (isCp) ...[
                              const Icon(
                                LucideIcons.sparkles,
                                size: 13,
                                color: purple,
                              ),
                              const SizedBox(width: 6),
                            ],
                            Flexible(
                              child: Text(
                                'NOTIFICATIONS',
                                style: GoogleFonts.montserrat(
                                  fontSize: 17,
                                  fontWeight: FontWeight.w800,
                                  color: scheme.onSurface,
                                  letterSpacing: 0.2,
                                ),
                                overflow: TextOverflow.ellipsis,
                              ),
                            ),
                          ],
                        ),
                        const SizedBox(height: 2),
                        Text(
                          isCp ? 'PARTNER UPDATES' : 'STAY UPDATED',
                          style: GoogleFonts.montserrat(
                            fontSize: 9,
                            fontWeight: FontWeight.w700,
                            color: scheme.onSurfaceVariant.withValues(
                              alpha: 0.7,
                            ),
                            letterSpacing: 2.5,
                          ),
                          overflow: TextOverflow.ellipsis,
                        ),
                      ],
                    ).animate().fadeIn(duration: 600.ms).slideX(begin: -0.2),
                  ),
                  // "Mark all" pill (web: purple for CP, neutral otherwise).
                  if (state.notifications.isNotEmpty)
                    GestureDetector(
                      onTap: () => ref
                          .read(notificationProvider.notifier)
                          .markAllAsRead(),
                      child: Container(
                        height: 36,
                        padding: const EdgeInsets.symmetric(horizontal: 12),
                        decoration: BoxDecoration(
                          color: isCp
                              ? purple.withValues(alpha: 0.08)
                              : scheme.surface,
                          borderRadius: BorderRadius.circular(10),
                          border: Border.all(
                            color: isCp
                                ? purple.withValues(alpha: 0.3)
                                : scheme.outlineVariant.withValues(alpha: 0.5),
                          ),
                        ),
                        child: Row(
                          mainAxisSize: MainAxisSize.min,
                          children: [
                            Icon(
                              LucideIcons.checkCheck,
                              size: 14,
                              color: isCp ? purple : scheme.onSurface,
                            ),
                            const SizedBox(width: 6),
                            Text(
                              'MARK ALL',
                              style: GoogleFonts.montserrat(
                                fontSize: 9,
                                fontWeight: FontWeight.w800,
                                color: isCp ? purple : scheme.onSurface,
                                letterSpacing: 1,
                              ),
                            ),
                          ],
                        ),
                      ),
                    ),
                ],
              ),
            ),
            Divider(
              height: 1,
              thickness: 1,
              color: scheme.outlineVariant.withValues(alpha: 0.35),
            ),

            // Notifications List
            Expanded(
              child: state.isLoading && state.notifications.isEmpty
                  ? Center(
                      child: CircularProgressIndicator(
                        color: isCp ? purple : scheme.primary,
                      ),
                    )
                  : state.notifications.isEmpty
                  ? _buildEmptyState(context)
                  : RefreshIndicator(
                      onRefresh: () => ref
                          .read(notificationProvider.notifier)
                          .fetchNotifications(),
                      color: scheme.onSurface,
                      backgroundColor: scheme.surface,
                      child: ListView.separated(
                        padding: const EdgeInsets.fromLTRB(20, 20, 20, 100),
                        itemCount: state.notifications.length,
                        separatorBuilder: (context, index) =>
                            const SizedBox(height: 16),
                        itemBuilder: (context, index) {
                          final notification = state.notifications[index];
                          return _NotificationItem(
                                notification: notification,
                                isCp: isCp,
                              )
                              .animate()
                              .fadeIn(delay: (index * 60).ms)
                              .slideY(begin: 0.1);
                        },
                      ),
                    ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildEmptyState(BuildContext context) {
    final scheme = Theme.of(context).colorScheme;
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Icon(
            LucideIcons.bellOff,
            size: 64,
            color: scheme.onSurface.withValues(alpha: 0.15),
          ),
          const SizedBox(height: 24),
          Text(
            'NO NOTIFICATIONS',
            style: GoogleFonts.montserrat(
              fontSize: 12,
              fontWeight: FontWeight.w900,
              color: scheme.onSurface.withValues(alpha: 0.4),
              letterSpacing: 2,
            ),
          ),
          const SizedBox(height: 8),
          Text(
            'We\'ll notify you when something important happens.',
            style: GoogleFonts.montserrat(
              fontSize: 10,
              color: scheme.onSurface.withValues(alpha: 0.3),
            ),
          ),
        ],
      ).animate().fadeIn(),
    );
  }
}

class _NotificationItem extends StatelessWidget {
  final dynamic notification;
  final bool isCp;

  const _NotificationItem({required this.notification, required this.isCp});

  @override
  Widget build(BuildContext context) {
    final scheme = Theme.of(context).colorScheme;
    final isDark = Theme.of(context).brightness == Brightness.dark;
    const purple = Color(0xFF9333EA);
    final accent = isCp ? purple : scheme.primary;

    // Web: "Mar 14, 2026, 11:19 AM" uppercased.
    final timeStr = DateFormat(
      'MMM d, y, h:mm a',
    ).format(notification.createdAt).toUpperCase();
    final bool isRead = notification.read == true;
    final ic = _iconFor(notification.type);

    return GestureDetector(
      onTap: () => _showNotificationDetail(context, notification, timeStr, ic),
      child: Container(
        decoration: BoxDecoration(
          // Web: unread → elevated white card + accent ring; read → faded.
          color: isDark
              ? scheme.surfaceContainerHighest.withValues(
                  alpha: isRead ? 0.12 : 0.3,
                )
              : Colors.white,
          borderRadius: BorderRadius.circular(30),
          border: Border.all(
            color: isRead
                ? scheme.outlineVariant.withValues(alpha: 0.4)
                : accent.withValues(alpha: 0.3),
            width: isRead ? 1 : 1.5,
          ),
          boxShadow: isDark
              ? null
              : [
                  BoxShadow(
                    color: Colors.black.withValues(alpha: isRead ? 0.03 : 0.07),
                    blurRadius: 24,
                    offset: const Offset(0, 12),
                  ),
                ],
        ),
        child: Opacity(
          opacity: isRead ? 0.6 : 1,
          child: Padding(
            padding: const EdgeInsets.all(18),
            child: Row(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                // Type icon (web: w-12 h-12 rounded-2xl, tinted by type).
                Container(
                  width: 48,
                  height: 48,
                  decoration: BoxDecoration(
                    color: ic.fg.withValues(alpha: isDark ? 0.2 : 0.1),
                    borderRadius: BorderRadius.circular(16),
                  ),
                  child: Icon(ic.icon, size: 24, color: ic.fg),
                ),
                const SizedBox(width: 16),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Row(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Expanded(
                            child: Text(
                              notification.title.toString().toUpperCase(),
                              style: GoogleFonts.montserrat(
                                fontSize: 14,
                                fontWeight: FontWeight.w800,
                                color: isRead
                                    ? scheme.onSurfaceVariant
                                    : scheme.onSurface,
                                letterSpacing: 0.2,
                              ),
                              overflow: TextOverflow.ellipsis,
                              maxLines: 1,
                            ),
                          ),
                          const SizedBox(width: 10),
                          Padding(
                            padding: const EdgeInsets.only(top: 2),
                            child: Text(
                              timeStr,
                              style: GoogleFonts.montserrat(
                                fontSize: 8,
                                color: scheme.onSurfaceVariant.withValues(
                                  alpha: 0.7,
                                ),
                                fontWeight: FontWeight.w700,
                                letterSpacing: 0.5,
                              ),
                            ),
                          ),
                          if (!isRead) ...[
                            const SizedBox(width: 8),
                            Container(
                              margin: const EdgeInsets.only(top: 4),
                              width: 8,
                              height: 8,
                              decoration: BoxDecoration(
                                color: accent,
                                shape: BoxShape.circle,
                              ),
                            ),
                          ],
                        ],
                      ),
                      const SizedBox(height: 6),
                      Text(
                        notification.message.toString(),
                        maxLines: 2,
                        overflow: TextOverflow.ellipsis,
                        style: GoogleFonts.montserrat(
                          fontSize: 11,
                          color: scheme.onSurfaceVariant,
                          height: 1.5,
                          fontWeight: FontWeight.w500,
                        ),
                      ),
                    ],
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }

  void _showNotificationDetail(
    BuildContext context,
    dynamic notification,
    String timeStr,
    ({IconData icon, Color fg}) ic,
  ) {
    final scheme = Theme.of(context).colorScheme;
    final isDark = Theme.of(context).brightness == Brightness.dark;
    const purple = Color(0xFF9333EA);
    final accent = isCp ? purple : scheme.primary;

    showDialog(
      context: context,
      barrierDismissible: true,
      builder: (context) => Material(
        color: Colors.transparent,
        child: Center(
          child: Container(
            margin: const EdgeInsets.symmetric(horizontal: 32),
            padding: const EdgeInsets.all(32),
            decoration: BoxDecoration(
              color: isDark ? const Color(0xFF18181B) : Colors.white,
              borderRadius: BorderRadius.circular(32),
              border: Border.all(
                color: scheme.outlineVariant.withValues(alpha: 0.2),
              ),
              boxShadow: [
                BoxShadow(
                  color: Colors.black.withValues(alpha: 0.4),
                  blurRadius: 40,
                  spreadRadius: 10,
                ),
              ],
            ),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                Align(
                  alignment: Alignment.topRight,
                  child: IconButton(
                    onPressed: () => Navigator.pop(context),
                    icon: Icon(
                      LucideIcons.x,
                      size: 18,
                      color: scheme.onSurface.withValues(alpha: 0.4),
                    ),
                    padding: EdgeInsets.zero,
                    constraints: const BoxConstraints(),
                  ),
                ),
                Container(
                  width: 80,
                  height: 80,
                  decoration: BoxDecoration(
                    color: ic.fg.withValues(alpha: isDark ? 0.2 : 0.1),
                    borderRadius: BorderRadius.circular(28),
                  ),
                  child: Icon(ic.icon, size: 36, color: ic.fg),
                ),
                const SizedBox(height: 24),
                Row(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    Container(
                      padding: const EdgeInsets.symmetric(
                        horizontal: 10,
                        vertical: 4,
                      ),
                      decoration: BoxDecoration(
                        color: accent.withValues(alpha: 0.1),
                        borderRadius: BorderRadius.circular(20),
                        border: Border.all(
                          color: accent.withValues(alpha: 0.25),
                        ),
                      ),
                      child: Text(
                        (notification.type ?? 'UPDATE')
                            .toString()
                            .toUpperCase(),
                        style: GoogleFonts.montserrat(
                          fontSize: 8,
                          fontWeight: FontWeight.w900,
                          letterSpacing: 1,
                          color: accent,
                        ),
                      ),
                    ),
                    const SizedBox(width: 8),
                    Flexible(
                      child: Text(
                        '• $timeStr',
                        style: GoogleFonts.montserrat(
                          fontSize: 8,
                          fontWeight: FontWeight.w900,
                          letterSpacing: 1,
                          color: scheme.onSurface.withValues(alpha: 0.4),
                        ),
                        overflow: TextOverflow.ellipsis,
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 16),
                Text(
                  notification.title.toString(),
                  textAlign: TextAlign.center,
                  style: GoogleFonts.montserrat(
                    fontSize: 22,
                    fontWeight: FontWeight.w900,
                    color: scheme.onSurface,
                  ),
                ),
                const SizedBox(height: 24),
                Container(
                  width: double.infinity,
                  padding: const EdgeInsets.all(20),
                  decoration: BoxDecoration(
                    color: scheme.onSurface.withValues(alpha: 0.02),
                    borderRadius: BorderRadius.circular(16),
                    border: Border.all(
                      color: scheme.outlineVariant.withValues(alpha: 0.1),
                    ),
                  ),
                  child: Text(
                    notification.message.toString(),
                    textAlign: TextAlign.center,
                    style: GoogleFonts.montserrat(
                      fontSize: 13,
                      fontWeight: FontWeight.w600,
                      color: scheme.onSurface.withValues(alpha: 0.8),
                      height: 1.6,
                    ),
                  ),
                ),
                const SizedBox(height: 32),
                SizedBox(
                  width: double.infinity,
                  child: ElevatedButton(
                    onPressed: () => Navigator.pop(context),
                    style: ElevatedButton.styleFrom(
                      backgroundColor: isCp ? purple : scheme.onSurface,
                      foregroundColor: isCp ? Colors.white : scheme.surface,
                      padding: const EdgeInsets.symmetric(vertical: 18),
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(16),
                      ),
                      elevation: 0,
                    ),
                    child: Text(
                      isCp ? 'ACKNOWLEDGE' : 'DONE',
                      style: GoogleFonts.montserrat(
                        fontSize: 12,
                        fontWeight: FontWeight.w900,
                        letterSpacing: 2,
                      ),
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
}
