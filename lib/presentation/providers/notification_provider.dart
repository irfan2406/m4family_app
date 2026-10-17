import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:m4_mobile/data/models/notification_model.dart';
import 'package:m4_mobile/presentation/providers/auth_provider.dart';

class NotificationState {
  final List<NotificationModel> notifications;
  final bool isLoading;
  final String? error;

  NotificationState({
    this.notifications = const [],
    this.isLoading = false,
    this.error,
  });

  NotificationState copyWith({
    List<NotificationModel>? notifications,
    bool? isLoading,
    String? error,
  }) {
    return NotificationState(
      notifications: notifications ?? this.notifications,
      isLoading: isLoading ?? this.isLoading,
      error: error,
    );
  }
}

class NotificationNotifier extends StateNotifier<NotificationState> {
  final Ref _ref;

  NotificationNotifier(this._ref) : super(NotificationState()) {
    fetchNotifications();
  }

  Future<void> fetchNotifications() async {
    state = state.copyWith(isLoading: true, error: null);
    try {
      final apiClient = _ref.read(apiClientProvider);
      final response = await apiClient.getNotifications();

      if (response.statusCode == 200 || response.statusCode == 201) {
        final List<dynamic> data = response.data['data'] ?? [];
        final List<NotificationModel> notifications = data
            .map((json) => NotificationModel.fromJson(json))
            .toList();

        // Sort by date newest first
        notifications.sort((a, b) => b.createdAt.compareTo(a.createdAt));

        state = state.copyWith(notifications: notifications, isLoading: false);
      } else {
        state = state.copyWith(
          isLoading: false,
          error: 'Failed to load notifications',
        );
      }
    } catch (e) {
      state = state.copyWith(isLoading: false, error: e.toString());
    }
  }

  /// Mark a single notification read (web `PATCH /notifications/:id/read`).
  /// Updates local state optimistically so the unread badge/dot clears at once.
  Future<void> markAsRead(String id) async {
    if (id.isEmpty) return;
    final already = state.notifications
        .firstWhere(
          (n) => n.id == id,
          orElse: () => NotificationModel(
            id: '',
            title: '',
            message: '',
            type: '',
            read: true,
            createdAt: DateTime.now(),
          ),
        )
        .read;
    if (already) return; // nothing to do

    // Optimistic update first.
    state = state.copyWith(
      notifications: state.notifications
          .map((n) => n.id == id ? n.copyWith(read: true) : n)
          .toList(),
    );
    try {
      await _ref.read(apiClientProvider).markNotificationAsRead(id);
    } catch (_) {
      // Keep the optimistic state; the next fetch reconciles if it failed.
    }
  }

  Future<void> markAllAsRead() async {
    try {
      final apiClient = _ref.read(apiClientProvider);
      final response = await apiClient.markAllNotificationsAsRead();

      if (response.statusCode == 200 || response.statusCode == 201) {
        // Optimistically update local state
        final updatedNotifications = state.notifications
            .map((n) => n.copyWith(read: true))
            .toList();
        state = state.copyWith(notifications: updatedNotifications);
      }
    } catch (e) {
      // Log error but don't disrupt state
      print('Error marking all as read: $e');
    }
  }

  int get unreadCount => state.notifications.where((n) => !n.read).length;
}

/// Convenience: the live unread count, for badges on the notification bell.
final unreadNotificationCountProvider = Provider<int>((ref) {
  return ref.watch(notificationProvider).notifications.where((n) => !n.read).length;
});

final notificationProvider =
    StateNotifierProvider<NotificationNotifier, NotificationState>((ref) {
      return NotificationNotifier(ref);
    });
