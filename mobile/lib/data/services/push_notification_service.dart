import 'package:firebase_core/firebase_core.dart';
import 'package:firebase_messaging/firebase_messaging.dart';
import 'package:flutter_local_notifications/flutter_local_notifications.dart';
import 'package:flutter_timezone/flutter_timezone.dart';
import 'package:logger/logger.dart';
import 'package:mobile/data/models/notification_model.dart';
import 'package:mobile/data/repositories/notification_repository.dart';
import 'package:mobile/data/services/token_service.dart';
import 'package:timezone/data/latest_all.dart' as tz;
import 'package:timezone/timezone.dart' as tz;

final _logger = Logger();

@pragma('vm:entry-point')
Future<void> _firebaseMessagingBackgroundHandler(RemoteMessage message) async {
  await Firebase.initializeApp();
  _logger.i("FCM Background message: ${message.messageId}");
  await PushNotificationService._saveIncomingNotificationToHive(message);
}

class PushNotificationService {
  static final FirebaseMessaging _firebaseMessaging = FirebaseMessaging.instance;
  static final FlutterLocalNotificationsPlugin _localNotificationsPlugin = FlutterLocalNotificationsPlugin();

  static Future<void> init() async {
    NotificationSettings settings = await _firebaseMessaging.requestPermission(
      alert: true,
      announcement: false,
      badge: true,
      carPlay: false,
      criticalAlert: false,
      provisional: false,
      sound: true,
    );

    await _firebaseMessaging.setForegroundNotificationPresentationOptions(alert: true, badge: true, sound: true);

    String? fcmToken = await _firebaseMessaging.getToken();

    _firebaseMessaging.onTokenRefresh.listen((newToken) {});

    FirebaseMessaging.onBackgroundMessage(_firebaseMessagingBackgroundHandler);

    try {
      await _firebaseMessaging.subscribeToTopic('all_users');
    } catch (e) {}

    await _initLocalNotifications();
    await cancelAllScheduledReminders();

    // Nhận thông báo khi ứng dụng đang chạy
    FirebaseMessaging.onMessage.listen((RemoteMessage message) async {
      await _saveIncomingNotificationToHive(message);
      _showLocalNotification(message);
    });

    // bấm vào thông báo trên thanh thông báo để mở ứng dung
    FirebaseMessaging.onMessageOpenedApp.listen((RemoteMessage message) async {
      await _saveIncomingNotificationToHive(message);
    });
  }

  static Future<void> _saveIncomingNotificationToHive(RemoteMessage message) async {
    try {
      final title = message.notification?.title ?? message.data['title'];
      final body = message.notification?.body ?? message.data['body'];
      if (title == null || title.toString().isEmpty) return;

      final userId = TokenService.getUserId();
      final repo = NotificationRepository();
      final currentList = repo.loadLocalNotifications(userId);

      NotificationCategory category = NotificationCategory.system;
      final catStr = (message.data['category'] ?? '').toString().toUpperCase();
      if (catStr == 'WORKOUT') {
        category = NotificationCategory.workout;
      } else if (catStr == 'MEAL') {
        category = NotificationCategory.meal;
      } else if (catStr == 'CHECKIN') {
        category = NotificationCategory.checkin;
      }

      final newItem = NotificationItemModel(
        id: message.messageId ?? DateTime.now().millisecondsSinceEpoch.toString(),
        title: title.toString(),
        body: (body ?? '').toString(),
        timestamp: DateTime.now(),
        isRead: false,
        category: category,
        routeToPush: message.data['routeToPush'] as String?,
      );

      if (!currentList.any((item) => item.id == newItem.id)) {
        final updated = [newItem, ...currentList];
        await repo.saveLocalNotifications(updated, userId);
      }
    } catch (e) {
      _logger.e("Error saving incoming FCM notification to Hive: $e");
    }
  }

  static Future<void> _initLocalNotifications() async {
    // Khởi tạo local notifications
    const AndroidInitializationSettings initializationSettingsAndroid = AndroidInitializationSettings(
      '@mipmap/ic_launcher',
    );

    const DarwinInitializationSettings initializationSettingsDarwin = DarwinInitializationSettings();

    const InitializationSettings initializationSettings = InitializationSettings(
      android: initializationSettingsAndroid,
      iOS: initializationSettingsDarwin,
    );

    await _localNotificationsPlugin.initialize(
      settings: initializationSettings,
      onDidReceiveNotificationResponse: (NotificationResponse details) {
        _logger.i("Local Notification clicked: ${details.payload}");
      },
    );

    await _localNotificationsPlugin
        .resolvePlatformSpecificImplementation<AndroidFlutterLocalNotificationsPlugin>()
        ?.requestNotificationsPermission();

    try {
      tz.initializeTimeZones();
      final timezoneInfo = await FlutterTimezone.getLocalTimezone();
      final String timeZoneName = timezoneInfo.identifier;
      tz.setLocalLocation(tz.getLocation(timeZoneName));
    } catch (e) {
      _logger.e("Notification Service timezone error: $e. Fallback to Asia/Ho_Chi_Minh");
      try {
        tz.initializeTimeZones();
        tz.setLocalLocation(tz.getLocation('Asia/Ho_Chi_Minh'));
      } catch (err) {
        _logger.e("Failed fallback timezone: $err");
      }
    }
  }

  static Future<void> cancelAllScheduledReminders() async {
    try {
      await _localNotificationsPlugin.cancelAll();
    } catch (e) {
      _logger.e('Error cancelling local reminders: $e');
    }
  }

  static Future<void> _showLocalNotification(RemoteMessage message) async {
    final notification = message.notification;
    final title = notification?.title ?? message.data['title'];
    final body = notification?.body ?? message.data['body'];

    if (title == null || title.toString().isEmpty) return;

    const AndroidNotificationDetails androidDetails = AndroidNotificationDetails(
      'bodypilot_channel',
      'BodyPilot Notifications',
      channelDescription: 'Kênh nhận thông báo của ứng dụng BodyPilot',
      importance: Importance.max,
      priority: Priority.high,
      playSound: true,
    );

    const DarwinNotificationDetails iosDetails = DarwinNotificationDetails();

    const NotificationDetails platformDetails = NotificationDetails(android: androidDetails, iOS: iosDetails);

    await _localNotificationsPlugin.show(
      id: message.hashCode,
      title: title.toString(),
      body: (body ?? '').toString(),
      notificationDetails: platformDetails,
      payload: message.data.toString(),
    );
  }

  /// Thông báo ngay lập tức khi BẤM HOÀN THÀNH BÀI TẬP
  static Future<void> showWorkoutCompletedNotification({
    String? title,
    String? body,
    double? totalCaloriesBurned,
  }) async {
    const AndroidNotificationDetails androidDetails = AndroidNotificationDetails(
      'bodypilot_workout_channel',
      'BodyPilot Workout Completed',
      channelDescription: 'Thông báo hoàn thành bài tập của ứng dụng BodyPilot',
      importance: Importance.max,
      priority: Priority.high,
      playSound: true,
    );

    const DarwinNotificationDetails iosDetails = DarwinNotificationDetails();

    const NotificationDetails platformDetails = NotificationDetails(android: androidDetails, iOS: iosDetails);

    final notificationTitle = title ?? 'Chúc mừng! Bạn đã hoàn thành buổi tập hôm nay! ';
    final caloText = (totalCaloriesBurned != null && totalCaloriesBurned > 0)
        ? ' Bạn đã đốt cháy khoảng ${totalCaloriesBurned.toInt()} kcal.'
        : '';
    final notificationBody =
        body ?? 'Tất cả các bài tập trong ngày đã được hoàn thành.$caloText Tiếp tục phát huy nhé!';

    await _localNotificationsPlugin.show(
      id: DateTime.now().millisecondsSinceEpoch ~/ 1000,
      title: notificationTitle,
      body: notificationBody,
      notificationDetails: platformDetails,
    );
  }
}
