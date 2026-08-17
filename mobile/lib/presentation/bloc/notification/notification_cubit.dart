import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:mobile/data/models/notification_model.dart';
import 'package:mobile/data/repositories/notification_repository.dart';
import 'package:mobile/data/services/token_service.dart';
import 'package:mobile/presentation/bloc/notification/notification_state.dart';

class NotificationCubit extends Cubit<NotificationState> {
  final NotificationRepository _repository;

  NotificationCubit({NotificationRepository? repository})
      : _repository = repository ?? NotificationRepository(),
        super(const NotificationState()) {
    loadNotificationsForUser(TokenService.getUserId());
  }

  void loadNotificationsForUser([String? userId]) {
    final effectiveUserId = userId ?? TokenService.getUserId();
    List<NotificationItemModel> localItems = _repository.loadLocalNotifications(effectiveUserId);

    emit(state.copyWith(notifications: localItems));

    if (effectiveUserId != null && effectiveUserId.isNotEmpty) {
      fetchRemoteNotifications(effectiveUserId);
    }
  }

  Future<void> fetchRemoteNotifications(String userId) async {
    final remoteItems = await _repository.fetchRemoteNotifications(userId);
    if (remoteItems.isNotEmpty) {
      // Merge remote items with existing local items avoiding duplicates by ID
      final existingIds = state.notifications.map((n) => n.id).toSet();
      final newRemoteOnly = remoteItems.where((n) => !existingIds.contains(n.id)).toList();

      final updatedList = [...newRemoteOnly, ...state.notifications];
      updatedList.sort((a, b) => b.timestamp.compareTo(a.timestamp));

      _repository.saveLocalNotifications(updatedList, userId);
      emit(state.copyWith(notifications: updatedList));
    }
  }

  void setFilter(NotificationFilter filter) {
    emit(state.copyWith(activeFilter: filter));
  }

  void markAsRead(String id, {String? userId}) {
    final effectiveUserId = userId ?? TokenService.getUserId();
    final updated = state.notifications.map((item) {
      if (item.id == id) {
        return item.copyWith(isRead: true);
      }
      return item;
    }).toList();

    _repository.saveLocalNotifications(updated, effectiveUserId);
    emit(state.copyWith(notifications: updated));

    if (effectiveUserId != null && effectiveUserId.isNotEmpty) {
      _repository.markRemoteAsRead(effectiveUserId, id);
    }
  }

  void markAllAsRead({String? userId}) {
    final effectiveUserId = userId ?? TokenService.getUserId();
    final updated = state.notifications.map((item) => item.copyWith(isRead: true)).toList();

    _repository.saveLocalNotifications(updated, effectiveUserId);
    emit(state.copyWith(notifications: updated));

    if (effectiveUserId != null && effectiveUserId.isNotEmpty) {
      _repository.markAllRemoteAsRead(effectiveUserId);
    }
  }

  void deleteNotification(String id, {String? userId}) {
    final effectiveUserId = userId ?? TokenService.getUserId();
    final updated = state.notifications.where((item) => item.id != id).toList();

    _repository.saveLocalNotifications(updated, effectiveUserId);
    emit(state.copyWith(notifications: updated));

    if (effectiveUserId != null && effectiveUserId.isNotEmpty) {
      _repository.deleteRemoteNotification(effectiveUserId, id);
    }
  }

  void clearAll({String? userId}) {
    final effectiveUserId = userId ?? TokenService.getUserId();
    _repository.saveLocalNotifications([], effectiveUserId);
    emit(state.copyWith(notifications: []));
  }

  void addNotification({
    required String title,
    required String body,
    NotificationCategory category = NotificationCategory.system,
    String? routeToPush,
    String? userId,
  }) {
    final effectiveUserId = userId ?? TokenService.getUserId();
    final newItem = NotificationItemModel(
      id: DateTime.now().millisecondsSinceEpoch.toString(),
      title: title,
      body: body,
      timestamp: DateTime.now(),
      isRead: false,
      category: category,
      routeToPush: routeToPush,
    );

    final updated = [newItem, ...state.notifications];
    _repository.saveLocalNotifications(updated, effectiveUserId);
    emit(state.copyWith(notifications: updated));
  }

  void addNotificationItem(NotificationItemModel item, {String? userId}) {
    final effectiveUserId = userId ?? TokenService.getUserId();
    // Prevent duplicate entries
    final exists = state.notifications.any((n) => n.id == item.id);
    if (exists) return;

    final updated = [item, ...state.notifications];
    updated.sort((a, b) => b.timestamp.compareTo(a.timestamp));

    _repository.saveLocalNotifications(updated, effectiveUserId);
    emit(state.copyWith(notifications: updated));
  }
}
