import 'package:mobile/data/models/notification_model.dart';

enum NotificationFilter { all, unread, workout, meal, checkin, system }

class NotificationState {
  final List<NotificationItemModel> notifications;
  final NotificationFilter activeFilter;

  const NotificationState({
    this.notifications = const [],
    this.activeFilter = NotificationFilter.all,
  });

  int get unreadCount => notifications.where((n) => !n.isRead).length;

  List<NotificationItemModel> get filteredNotifications {
    switch (activeFilter) {
      case NotificationFilter.all:
        return notifications;
      case NotificationFilter.unread:
        return notifications.where((n) => !n.isRead).toList();
      case NotificationFilter.workout:
        return notifications.where((n) => n.category == NotificationCategory.workout).toList();
      case NotificationFilter.meal:
        return notifications.where((n) => n.category == NotificationCategory.meal).toList();
      case NotificationFilter.checkin:
        return notifications.where((n) => n.category == NotificationCategory.checkin).toList();
      case NotificationFilter.system:
        return notifications.where((n) => n.category == NotificationCategory.system).toList();
    }
  }

  NotificationState copyWith({
    List<NotificationItemModel>? notifications,
    NotificationFilter? activeFilter,
  }) {
    return NotificationState(
      notifications: notifications ?? this.notifications,
      activeFilter: activeFilter ?? this.activeFilter,
    );
  }
}
