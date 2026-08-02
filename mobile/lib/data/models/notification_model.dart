enum NotificationCategory {
  workout,
  meal,
  checkin,
  system;

  String get displayName {
    switch (this) {
      case NotificationCategory.workout:
        return 'Luyện tập';
      case NotificationCategory.meal:
        return 'Dinh dưỡng';
      case NotificationCategory.checkin:
        return 'Check-in';
      case NotificationCategory.system:
        return 'Hệ thống';
    }
  }

  static NotificationCategory fromString(String? catStr) {
    if (catStr == null) return NotificationCategory.system;
    switch (catStr.toLowerCase()) {
      case 'workout':
        return NotificationCategory.workout;
      case 'meal':
        return NotificationCategory.meal;
      case 'checkin':
        return NotificationCategory.checkin;
      default:
        return NotificationCategory.system;
    }
  }
}

class NotificationItemModel {
  final String id;
  final String title;
  final String body;
  final DateTime timestamp;
  final bool isRead;
  final NotificationCategory category;
  final String? routeToPush;

  NotificationItemModel({
    required this.id,
    required this.title,
    required this.body,
    required this.timestamp,
    this.isRead = false,
    this.category = NotificationCategory.system,
    this.routeToPush,
  });

  NotificationItemModel copyWith({
    String? id,
    String? title,
    String? body,
    DateTime? timestamp,
    bool? isRead,
    NotificationCategory? category,
    String? routeToPush,
  }) {
    return NotificationItemModel(
      id: id ?? this.id,
      title: title ?? this.title,
      body: body ?? this.body,
      timestamp: timestamp ?? this.timestamp,
      isRead: isRead ?? this.isRead,
      category: category ?? this.category,
      routeToPush: routeToPush ?? this.routeToPush,
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'title': title,
      'body': body,
      'timestamp': timestamp.toIso8601String(),
      'isRead': isRead,
      'category': category.name,
      'routeToPush': routeToPush,
    };
  }

  factory NotificationItemModel.fromJson(Map<String, dynamic> json) {
    return NotificationItemModel(
      id: json['id']?.toString() ?? '',
      title: json['title'] ?? '',
      body: json['body'] ?? '',
      timestamp: json['timestamp'] != null
          ? DateTime.parse(json['timestamp'])
          : (json['createdAt'] != null ? DateTime.parse(json['createdAt']) : DateTime.now()),
      isRead: json['isRead'] ?? json['read'] ?? false,
      category: NotificationCategory.fromString(json['category']?.toString()),
      routeToPush: json['routeToPush'],
    );
  }
}
