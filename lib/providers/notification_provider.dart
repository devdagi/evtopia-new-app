import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../models/notification_model.dart';
import 'auth_provider.dart';
import '../services/notification_service.dart';

final notificationServiceProvider = Provider<NotificationService>((ref) {
  return NotificationService(ref.watch(apiClientProvider));
});

/// State for notifications list + unread count.
class NotificationState {
  const NotificationState({
    this.notifications = const [],
    this.unreadCount = 0,
    this.isLoading = false,
    this.errorMessage,
  });

  final List<NotificationModel> notifications;
  final int unreadCount;
  final bool isLoading;
  final String? errorMessage;

  NotificationState copyWith({
    List<NotificationModel>? notifications,
    int? unreadCount,
    bool? isLoading,
    String? errorMessage,
  }) {
    return NotificationState(
      notifications: notifications ?? this.notifications,
      unreadCount: unreadCount ?? this.unreadCount,
      isLoading: isLoading ?? this.isLoading,
      errorMessage: errorMessage,
    );
  }
}

/// Holds notifications list and unread count for the current user.
/// Pass [userId] when fetching; when null (logged out), state is cleared.
class NotificationNotifier extends StateNotifier<NotificationState> {
  NotificationNotifier(this._service) : super(const NotificationState());

  final NotificationService _service;

  int? _currentUserId;

  /// Fetch list and count. Call with logged-in user id.
  Future<void> fetchNotifications(int userId) async {
    _currentUserId = userId;
    state = state.copyWith(isLoading: true, errorMessage: null);
    final result = await _service.getNotifications(userId);
    if (_currentUserId != userId) return;
    if (result == null) {
      state = state.copyWith(
        isLoading: false,
        errorMessage: 'Failed to load notifications',
      );
      return;
    }
    state = state.copyWith(
      notifications: result.notifications,
      unreadCount: result.unreadCount,
      isLoading: false,
      errorMessage: null,
    );
  }

  /// Refresh only unread count (e.g. for badge).
  /// Always updates state so the badge shows even before user visits Notifications page.
  Future<void> refreshUnreadCount(int userId) async {
    final count = await _service.getUnreadCount(userId);
    state = state.copyWith(unreadCount: count);
  }

  /// Mark one as read and update local state.
  Future<void> markAsRead(int userId, int notificationId) async {
    final ok = await _service.markAsRead(userId, notificationId);
    if (!ok || _currentUserId != userId) return;
    final updated = state.notifications.map((n) {
      if (n.id == notificationId) {
        return NotificationModel(
          id: n.id,
          title: n.title,
          content: n.content,
          time: n.time,
          isRead: true,
          icon: n.icon,
          type: n.type,
          url: n.url,
          createdAt: n.createdAt,
        );
      }
      return n;
    }).toList();
    final newCount = state.unreadCount > 0 ? state.unreadCount - 1 : 0;
    state = state.copyWith(notifications: updated, unreadCount: newCount);
  }

  /// Mark all as read and refresh list.
  Future<void> markAllAsRead(int userId) async {
    final ok = await _service.markAllAsRead(userId);
    if (!ok || _currentUserId != userId) return;
    final updated = state.notifications
        .map((n) => NotificationModel(
              id: n.id,
              title: n.title,
              content: n.content,
              time: n.time,
              isRead: true,
              icon: n.icon,
              type: n.type,
              url: n.url,
              createdAt: n.createdAt,
            ))
        .toList();
    state = state.copyWith(notifications: updated, unreadCount: 0);
  }

  /// Delete one and remove from list.
  Future<void> deleteNotification(int userId, int notificationId) async {
    final ok = await _service.destroy(userId, notificationId);
    if (!ok || _currentUserId != userId) return;
    final wasUnread = state.notifications
        .any((n) => n.id == notificationId && !n.isRead);
    final updated = state.notifications
        .where((n) => n.id != notificationId)
        .toList();
    final newCount = wasUnread && state.unreadCount > 0
        ? state.unreadCount - 1
        : state.unreadCount;
    state = state.copyWith(notifications: updated, unreadCount: newCount);
  }

  void clear() {
    _currentUserId = null;
    state = const NotificationState();
  }
}

final notificationProvider =
    StateNotifierProvider<NotificationNotifier, NotificationState>((ref) {
  return NotificationNotifier(ref.watch(notificationServiceProvider));
});
