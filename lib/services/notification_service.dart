import 'package:dio/dio.dart';

import '../core/constants/api_constants.dart';
import '../core/network/api_client.dart';
import '../models/notification_model.dart';

/// Result of fetching notifications (list + unread count).
class NotificationListResult {
  const NotificationListResult({
    required this.notifications,
    required this.unreadCount,
  });

  final List<NotificationModel> notifications;
  final int unreadCount;
}

/// Calls backend notification APIs (user_id as query param; auth via Bearer token).
class NotificationService {
  NotificationService(this._api);

  final ApiClient _api;

  /// GET /api/mobile-notifications?user_id=
  /// Returns list and total unread (data.notifications, data.total).
  Future<NotificationListResult?> getNotifications(int userId) async {
    try {
      final response = await _api.dio.get<Map<String, dynamic>>(
        ApiConstants.mobileNotificationsPath,
        queryParameters: {'user_id': userId},
      );
      if (response.statusCode != 200 || response.data == null) return null;
      final data = response.data!['data'];
      if (data is! Map<String, dynamic>) return null;
      final list = data['notifications'];
      final rawList = list is List ? list : <dynamic>[];
      final notifications = rawList
          .whereType<Map<String, dynamic>>()
          .map(NotificationModel.fromJson)
          .toList();
      final total = data['total'];
      int unreadCount = 0;
      if (total is int) {
        unreadCount = total;
      } else if (total is String) {
        unreadCount = int.tryParse(total) ?? 0;
        if (total == '9+') unreadCount = 9;
      }
      return NotificationListResult(
        notifications: notifications,
        unreadCount: unreadCount,
      );
    } on DioException {
      return null;
    }
  }

  /// GET /api/count_notification?user_id=
  Future<int> getUnreadCount(int userId) async {
    try {
      final response = await _api.dio.get<Map<String, dynamic>>(
        ApiConstants.countNotificationPath,
        queryParameters: {'user_id': userId},
      );
      if (response.statusCode != 200 || response.data == null) return 0;
      final data = response.data!['data'];
      if (data is! Map<String, dynamic>) return 0;
      final total = data['total'];
      if (total is int) return total;
      if (total is String) return int.tryParse(total) ?? 0;
      return 0;
    } on DioException {
      return 0;
    }
  }

  /// GET /api/notification/{id}/read?user_id=
  Future<bool> markAsRead(int userId, int notificationId) async {
    try {
      final response = await _api.dio.get<Map<String, dynamic>>(
        ApiConstants.notificationReadPath(notificationId),
        queryParameters: {'user_id': userId},
      );
      return response.statusCode == 200;
    } on DioException {
      return false;
    }
  }

  /// GET /api/notification/read-all?user_id=
  Future<bool> markAllAsRead(int userId) async {
    try {
      final response = await _api.dio.get<Map<String, dynamic>>(
        ApiConstants.notificationReadAllPath,
        queryParameters: {'user_id': userId},
      );
      return response.statusCode == 200;
    } on DioException {
      return false;
    }
  }

  /// GET /api/notification/{id}/destroy?user_id=
  Future<bool> destroy(int userId, int notificationId) async {
    try {
      final response = await _api.dio.get<Map<String, dynamic>>(
        ApiConstants.notificationDestroyPath(notificationId),
        queryParameters: {'user_id': userId},
      );
      return response.statusCode == 200;
    } on DioException {
      return false;
    }
  }
}
