import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:mobile/core/routes/app_routes.dart';
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

    if (localItems.isEmpty) {
      // Create initial seed notifications if Hive is empty for this user
      final now = DateTime.now();
      localItems = [
        NotificationItemModel(
          id: '1',
          title: 'Chúc mừng! Hoàn thành bài tập 🎉💪',
          body: 'Bạn đã hoàn thành 100% mục tiêu bài tập hôm nay. Tiêu hao khoảng 420 kcal.',
          timestamp: now.subtract(const Duration(minutes: 25)),
          isRead: false,
          category: NotificationCategory.workout,
          routeToPush: AppRoutes.workoutDiary,
        ),
        NotificationItemModel(
          id: '2',
          title: 'Gợi ý thực đơn từ Gemini AI 🥗',
          body: 'Thực đơn Bữa tối của bạn đã được tối ưu hóa tăng thêm 30g Protein để phù hợp với cường độ tập.',
          timestamp: now.subtract(const Duration(hours: 2)),
          isRead: false,
          category: NotificationCategory.meal,
          routeToPush: AppRoutes.mealPlan,
        ),
        NotificationItemModel(
          id: '3',
          title: 'Đã đến đợt Check-in tiến độ tuần này! 📊',
          body: 'Hãy dành 2 phút cập nhật cân nặng & vóc dáng để AI điều chỉnh kế hoạch TDEE mới cho bạn.',
          timestamp: now.subtract(const Duration(hours: 5)),
          isRead: false,
          category: NotificationCategory.checkin,
        ),
        NotificationItemModel(
          id: '4',
          title: 'Nhắc nhở uống nước 💧',
          body: 'Bạn đã đạt 1.5L / 2.5L nước cho ngày hôm nay. Đừng quên nạp thêm nước nhé!',
          timestamp: now.subtract(const Duration(hours: 8)),
          isRead: true,
          category: NotificationCategory.system,
        ),
        NotificationItemModel(
          id: '5',
          title: 'Báo cáo tổng quan tuần vừa qua 📈',
          body: 'Tuần này bạn đã duy trì 5 buổi tập và đạt 92% chỉ số Calo mục tiêu. Tuyệt vời lắm!',
          timestamp: now.subtract(const Duration(days: 1, hours: 3)),
          isRead: true,
          category: NotificationCategory.workout,
        ),
        NotificationItemModel(
          id: '6',
          title: 'Chào mừng bạn đến với BodyPilot! 🚀',
          body: 'Tài khoản của bạn đã thiết lập thành công. Hãy bắt đầu hành trình cải thiện vóc dáng ngay hôm nay.',
          timestamp: now.subtract(const Duration(days: 3)),
          isRead: true,
          category: NotificationCategory.system,
        ),
      ];

      // Save initial list into Hive
      _repository.saveLocalNotifications(localItems, effectiveUserId);
    }

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
