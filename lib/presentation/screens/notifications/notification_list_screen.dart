import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:lucide_icons/lucide_icons.dart';
import 'package:m4_mobile/presentation/providers/notification_provider.dart';
import 'package:flutter_animate/flutter_animate.dart';
import 'package:intl/intl.dart';
import 'package:m4_mobile/presentation/widgets/main_shell.dart';


class NotificationListScreen extends ConsumerWidget {
  const NotificationListScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final state = ref.watch(notificationProvider);

    return Scaffold(
      backgroundColor: Theme.of(context).scaffoldBackgroundColor,
      body: Container(
        color: Theme.of(context).scaffoldBackgroundColor,
        child: SafeArea(
          child: Column(
            children: [
              // Header
              Padding(
              padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 20),
              child: Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Expanded(
                    child: Row(
                      children: [
                        IconButton(
                          onPressed: () {
                            ref.read(navigationProvider.notifier).state = 0; // Go back to Home
                          },
                          icon: Icon(LucideIcons.chevronLeft, color: Theme.of(context).colorScheme.onSurface.withOpacity(0.7)),
                        ),
                        const SizedBox(width: 4),
                        Flexible(
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Text(
                                'NOTIFICATIONS',
                                style: GoogleFonts.montserrat(
                                  fontSize: 24,
                                  fontWeight: FontWeight.w300,
                                  color: Theme.of(context).colorScheme.onSurface,
                                  letterSpacing: 2,
                                ),
                                overflow: TextOverflow.ellipsis,
                              ),
                              Text(
                                'STAY UPDATED',
                                style: GoogleFonts.montserrat(
                                  fontSize: 9,
                                  fontWeight: FontWeight.w900,
                                  color: Theme.of(context).colorScheme.onSurface.withOpacity(0.5),
                                  letterSpacing: 4,
                                ),
                                overflow: TextOverflow.ellipsis,
                              ),
                            ],
                          ).animate().fadeIn(duration: 600.ms).slideX(begin: -0.2),
                        ),
                      ],
                    ),
                  ),

                  if (state.notifications.isNotEmpty)
                    TextButton(
                      onPressed: () => ref.read(notificationProvider.notifier).markAllAsRead(),
                      child: Text(
                        'MARK AS READ',
                        style: GoogleFonts.montserrat(
                          fontSize: 10,
                          fontWeight: FontWeight.w900,
                          color: Theme.of(context).colorScheme.onSurface.withOpacity(0.7),
                          letterSpacing: 1,
                        ),
                      ),
                    ),
                ],
              ),
            ),

              const SizedBox(height: 10),

              // Notifications List
              Expanded(
                child: state.isLoading && state.notifications.isEmpty
                    ? Center(child: CircularProgressIndicator(color: Theme.of(context).colorScheme.onSurface.withOpacity(0.1)))
                    : state.notifications.isEmpty
                        ? _buildEmptyState(context)
                        : RefreshIndicator(
                            onRefresh: () => ref.read(notificationProvider.notifier).fetchNotifications(),
                            color: Colors.black,
                            backgroundColor: Colors.white,
                            child: ListView.separated(
                              padding: const EdgeInsets.fromLTRB(24, 10, 24, 100),

                              itemCount: state.notifications.length,
                              separatorBuilder: (context, index) => const SizedBox(height: 16),
                              itemBuilder: (context, index) {
                                final notification = state.notifications[index];
                                return _NotificationItem(notification: notification)
                                    .animate()
                                    .fadeIn(delay: (index * 100).ms)
                                    .slideY(begin: 0.1);
                              },
                            ),
                          ),
              ),
            ],
          ),
        ),
      ),
    );
  }



  Widget _buildEmptyState(BuildContext context) {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Icon(LucideIcons.bellOff, size: 64, color: Theme.of(context).colorScheme.onSurface.withOpacity(0.1)),
          const SizedBox(height: 24),
          Text(
            'NO NOTIFICATIONS',
            style: GoogleFonts.montserrat(
              fontSize: 12,
              fontWeight: FontWeight.w900,
              color: Theme.of(context).colorScheme.onSurface.withOpacity(0.2),
              letterSpacing: 2,
            ),
          ),
          const SizedBox(height: 8),
          Text(
            'We\'ll notify you when something important happens.',
            style: GoogleFonts.montserrat(
              fontSize: 10,
              color: Theme.of(context).colorScheme.onSurface.withOpacity(0.1),
            ),
          ),
        ],
      ).animate().fadeIn(),
    );
  }
}

class _NotificationItem extends StatelessWidget {
  final notification;

  const _NotificationItem({required this.notification});

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final dateFormat = DateFormat('M/d/yyyy, h:mm a');
    final String timeStr = dateFormat.format(notification.createdAt);

    return Container(
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: (isDark ? Colors.white : Colors.black).withOpacity(0.04),
        borderRadius: BorderRadius.circular(16),
        border: Border.all(
          color: (isDark ? Colors.white : Colors.black).withOpacity(notification.read ? 0.05 : 0.1),
          width: 0.5,
        ),
      ),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Icon
          Container(
            padding: const EdgeInsets.all(10),
            decoration: BoxDecoration(
              color: Colors.blueAccent.withOpacity(0.1),
              shape: BoxShape.circle,
            ),
            child: const Icon(
              LucideIcons.info,
              size: 16,
              color: Colors.blueAccent,
            ),
          ),
          const SizedBox(width: 16),

          // Content
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Flexible(
                      child: Text(
                        notification.title.toUpperCase(),
                        style: GoogleFonts.montserrat(
                          fontSize: 12,
                          fontWeight: FontWeight.w900,
                          color: Theme.of(context).colorScheme.onSurface,
                          letterSpacing: 0.5,
                        ),
                        overflow: TextOverflow.ellipsis,
                        maxLines: 1,
                      ),
                    ),
                    const SizedBox(width: 12),

                    Row(
                      children: [
                        Text(
                          timeStr,
                          style: GoogleFonts.montserrat(
                            fontSize: 8,
                            color: Theme.of(context).colorScheme.onSurface.withOpacity(0.4),
                          ),
                        ),
                        if (!notification.read) ...[
                          const SizedBox(width: 8),
                          Container(
                            width: 6,
                            height: 6,
                            decoration: const BoxDecoration(
                              color: Colors.orangeAccent,
                              shape: BoxShape.circle,
                            ),
                          ),
                        ],
                      ],
                    ),
                  ],
                ),
                const SizedBox(height: 8),
                Text(
                  notification.message,
                  style: GoogleFonts.montserrat(
                    fontSize: 11,
                    color: Theme.of(context).colorScheme.onSurface.withOpacity(0.7),
                    height: 1.5,
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
