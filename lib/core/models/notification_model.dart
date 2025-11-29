class NotificationModel {
  final int id;
  final String title;
  final String body;
  final String type;
  bool isRead;
  final String createdAt;

  NotificationModel({
    required this.id,
    required this.title,
    required this.body,
    required this.type,
    required this.isRead,
    required this.createdAt,
  });

  factory NotificationModel.fromJson(Map<String, dynamic> json) {
    return NotificationModel(
      id: json['id'],
      title: json['title'],
      body: json['body'],
      type: json['type'] ?? 'info',
      isRead: (json['is_read'] == 1),
      createdAt: json['created_at'],
    );
  }
}