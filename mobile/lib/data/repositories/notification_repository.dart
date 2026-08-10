import 'package:dio/dio.dart';
import 'package:hive_flutter/hive_flutter.dart';
import 'package:logger/logger.dart';
import 'package:mobile/core/network/api_client.dart';
import 'package:mobile/data/models/notification_model.dart';

final _logger = Logger();

class NotificationRepository {
  static const String _hiveBoxName = 'notification_box';

  Box get _box => Hive.box(_hiveBoxName);

  /// Load cached notifications from local Hive Box per user
  List<NotificationItemModel> loadLocalNotifications([String? userId]) {
    try {
      final key = (userId != null && userId.isNotEmpty) ? 'items_$userId' : 'items_anonymous';
      var rawList = _box.get(key);
      // Fallback to legacy 'items' key if user key not initialized yet
      if (rawList == null && _box.containsKey('items')) {
        rawList = _box.get('items');
      }
      if (rawList != null && rawList is List) {
        return rawList.map((e) => NotificationItemModel.fromJson(Map<String, dynamic>.from(e))).toList();
      }
    } catch (e) {
      _logger.e('Error loading notifications from Hive: $e');
    }
    return [];
  }

  /// Save notification list into local Hive Box per user
  Future<void> saveLocalNotifications(List<NotificationItemModel> list, [String? userId]) async {
    try {
      final key = (userId != null && userId.isNotEmpty) ? 'items_$userId' : 'items_anonymous';
      final jsonList = list.map((item) => item.toJson()).toList();
      await _box.put(key, jsonList);
    } catch (e) {
      _logger.e('Error saving notifications to Hive: $e');
    }
  }

  /// Fetch notifications from Backend Spring Boot Server for given userId
  Future<List<NotificationItemModel>> fetchRemoteNotifications(String userId) async {
    try {
      final response = await apiClient.get('/users/$userId/notifications');
      if (response.statusCode == 200 && response.data != null) {
        final data = response.data['data'];
        if (data is List) {
          final remoteList = data.map((json) => NotificationItemModel.fromJson(json)).toList();
          return remoteList;
        }
      }
    } on DioException catch (e) {
      _logger.w('Network error fetching remote notifications (offline mode active): $e');
    } catch (e) {
      _logger.e('Unexpected error fetching notifications: $e');
    }
    return [];
  }

  /// Sync local notification read status with Backend Server
  Future<void> markRemoteAsRead(String userId, String notificationId) async {
    try {
      await apiClient.put('/users/$userId/notifications/$notificationId/read');
    } catch (e) {
      _logger.w('Error syncing read status to server: $e');
    }
  }

  /// Mark all remote notifications as read
  Future<void> markAllRemoteAsRead(String userId) async {
    try {
      await apiClient.put('/users/$userId/notifications/read-all');
    } catch (e) {
      _logger.w('Error syncing read all status to server: $e');
    }
  }

  /// Delete remote notification
  Future<void> deleteRemoteNotification(String userId, String notificationId) async {
    try {
      await apiClient.delete('/users/$userId/notifications/$notificationId');
    } catch (e) {
      _logger.w('Error deleting remote notification: $e');
    }
  }
}
