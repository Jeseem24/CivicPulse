class UserNotification {
  final String id;
  final String userId;
  final String reportId;
  final String type; // e.g. 'REPORT_RESOLVED'
  final String title;
  final String message;
  final bool isRead;
  final DateTime createdAt;

  UserNotification({
    required this.id,
    required this.userId,
    required this.reportId,
    required this.type,
    required this.title,
    required this.message,
    required this.isRead,
    required this.createdAt,
  });

  UserNotification copyWith({
    String? id,
    String? userId,
    String? reportId,
    String? type,
    String? title,
    String? message,
    bool? isRead,
    DateTime? createdAt,
  }) {
    return UserNotification(
      id: id ?? this.id,
      userId: userId ?? this.userId,
      reportId: reportId ?? this.reportId,
      type: type ?? this.type,
      title: title ?? this.title,
      message: message ?? this.message,
      isRead: isRead ?? this.isRead,
      createdAt: createdAt ?? this.createdAt,
    );
  }

  factory UserNotification.fromJson(Map<String, dynamic> json) {
    return UserNotification(
      id: json['id'] ?? '',
      userId: json['user_id'] ?? json['userId'] ?? '',
      reportId: json['report_id'] ?? json['reportId'] ?? '',
      type: json['type'] ?? 'REPORT_RESOLVED',
      title: json['title'] ?? '',
      message: json['message'] ?? '',
      isRead: json['is_read'] ?? json['isRead'] ?? false,
      createdAt: json['created_at'] != null
          ? DateTime.parse(json['created_at'])
          : DateTime.now(),
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'user_id': userId,
      'report_id': reportId,
      'type': type,
      'title': title,
      'message': message,
      'is_read': isRead,
      'created_at': createdAt.toIso8601String(),
    };
  }
}
