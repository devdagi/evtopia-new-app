/// Notification model from API (WebNotificationResource).
class NotificationModel {
  const NotificationModel({
    required this.id,
    required this.title,
    required this.content,
    required this.time,
    required this.isRead,
    this.icon,
    this.type,
    this.url,
    this.createdAt,
  });

  final int id;
  final String title;
  final String content;
  final String time;
  final bool isRead;
  final String? icon;
  final String? type;
  /// Optional link to open when user taps "Go to".
  final String? url;
  final String? createdAt;

  factory NotificationModel.fromJson(Map<String, dynamic> json) {
    return NotificationModel(
      id: json['id'] as int,
      title: (json['title'] as String?) ?? '',
      content: (json['content'] as String?) ?? '',
      time: (json['time'] as String?) ?? '',
      isRead: json['is_read'] == true || json['is_read'] == 1,
      icon: json['icon'] as String?,
      type: json['type'] as String?,
      url: json['url'] as String?,
      createdAt: json['created_at'] as String?,
    );
  }
}
