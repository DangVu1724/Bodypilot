import 'package:firebase_core/firebase_core.dart';
import 'package:firebase_messaging/firebase_messaging.dart';
import 'package:flutter_local_notifications/flutter_local_notifications.dart';
import 'package:timezone/data/latest_all.dart' as tz;
import 'package:timezone/timezone.dart' as tz;
import 'package:flutter_timezone/flutter_timezone.dart';
import 'package:logger/logger.dart';

final _logger = Logger();

@pragma('vm:entry-point')
Future<void> _firebaseMessagingBackgroundHandler(RemoteMessage message) async {
  await Firebase.initializeApp();
  _logger.i("FCM Background message: ${message.messageId}");
}

class PushNotificationService {
  static final FirebaseMessaging _firebaseMessaging = FirebaseMessaging.instance;
  static final FlutterLocalNotificationsPlugin _localNotificationsPlugin =
      FlutterLocalNotificationsPlugin();

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

    _logger.i('FCM authorization status: ${settings.authorizationStatus}');

    String? fcmToken = await _firebaseMessaging.getToken();
    _logger.i("FCM TOKEN: $fcmToken");

    _firebaseMessaging.onTokenRefresh.listen((newToken) {
      _logger.i("FCM Token refreshed: $newToken");
    });

    FirebaseMessaging.onBackgroundMessage(_firebaseMessagingBackgroundHandler);

    try {
      await _firebaseMessaging.subscribeToTopic('all_users');
      _logger.i("Subscribed to FCM topic 'all_users'");
    } catch (e) {
      _logger.w("Failed to subscribe to FCM topic 'all_users': $e");
    }

    await _initLocalNotifications();
    await setupScheduledReminders();

    FirebaseMessaging.onMessage.listen((RemoteMessage message) {
      _logger.i("FCM Foreground message received: ${message.notification?.title}");
      _showLocalNotification(message);
    });

    FirebaseMessaging.onMessageOpenedApp.listen((RemoteMessage message) {
      _logger.i("FCM Message opened app: ${message.data}");
    });
  }

  static Future<void> _initLocalNotifications() async {
    const AndroidInitializationSettings initializationSettingsAndroid =
        AndroidInitializationSettings('@mipmap/ic_launcher');

    const DarwinInitializationSettings initializationSettingsDarwin =
        DarwinInitializationSettings();

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
        .resolvePlatformSpecificImplementation<
            AndroidFlutterLocalNotificationsPlugin>()
        ?.requestNotificationsPermission();

    try {
      tz.initializeTimeZones();
      final timezoneInfo = await FlutterTimezone.getLocalTimezone();
      final String timeZoneName = timezoneInfo.identifier;
      tz.setLocalLocation(tz.getLocation(timeZoneName));
    } catch (e) {
      _logger.e("Notification Service timezone error: $e. Fallback to Asia/Ho_Chi_Minh");
      try {
        tz.setLocalLocation(tz.getLocation('Asia/Ho_Chi_Minh'));
      } catch (_) {}
    }
  }

  static Future<void> scheduleDailyNotification({
    required int id,
    required String title,
    required String body,
    required int hour,
    required int minute,
  }) async {
    final tz.TZDateTime now = tz.TZDateTime.now(tz.local);
    tz.TZDateTime scheduledDate = tz.TZDateTime(
      tz.local,
      now.year,
      now.month,
      now.day,
      hour,
      minute,
    );

    if (scheduledDate.isBefore(now)) {
      scheduledDate = scheduledDate.add(const Duration(days: 1));
    }

    const AndroidNotificationDetails androidDetails = AndroidNotificationDetails(
      'bodypilot_reminder_channel',
      'BodyPilot Reminders',
      channelDescription: 'Nhắc nhở hàng ngày của ứng dụng BodyPilot',
      importance: Importance.high,
      priority: Priority.high,
      playSound: true,
    );

    const DarwinNotificationDetails iosDetails = DarwinNotificationDetails();

    const NotificationDetails platformDetails = NotificationDetails(
      android: androidDetails,
      iOS: iosDetails,
    );

    await _localNotificationsPlugin.zonedSchedule(
      id: id,
      title: title,
      body: body,
      scheduledDate: scheduledDate,
      notificationDetails: platformDetails,
      androidScheduleMode: AndroidScheduleMode.inexactAllowWhileIdle,
      matchDateTimeComponents: DateTimeComponents.time,
    );
    _logger.i('Daily notification scheduled (ID $id) at $hour:$minute');
  }

  static Future<void> scheduleWeeklyNotification({
    required int id,
    required String title,
    required String body,
    required int dayOfWeek,
    required int hour,
    required int minute,
  }) async {
    final tz.TZDateTime now = tz.TZDateTime.now(tz.local);
    tz.TZDateTime scheduledDate = tz.TZDateTime(
      tz.local,
      now.year,
      now.month,
      now.day,
      hour,
      minute,
    );

    int daysToAdd = dayOfWeek - scheduledDate.weekday;
    if (daysToAdd < 0 || (daysToAdd == 0 && scheduledDate.isBefore(now))) {
      daysToAdd += 7;
    }

    scheduledDate = scheduledDate.add(Duration(days: daysToAdd));

    const AndroidNotificationDetails androidDetails = AndroidNotificationDetails(
      'bodypilot_weekly_channel',
      'BodyPilot Weekly Reports',
      channelDescription: 'Báo cáo hàng tuần của ứng dụng BodyPilot',
      importance: Importance.high,
      priority: Priority.high,
      playSound: true,
    );

    const DarwinNotificationDetails iosDetails = DarwinNotificationDetails();

    const NotificationDetails platformDetails = NotificationDetails(
      android: androidDetails,
      iOS: iosDetails,
    );

    await _localNotificationsPlugin.zonedSchedule(
      id: id,
      title: title,
      body: body,
      scheduledDate: scheduledDate,
      notificationDetails: platformDetails,
      androidScheduleMode: AndroidScheduleMode.inexactAllowWhileIdle,
      matchDateTimeComponents: DateTimeComponents.dayOfWeekAndTime,
    );
    _logger.i('Weekly notification scheduled (ID $id) on Day $dayOfWeek at $hour:$minute');
  }

  static Future<void> setupScheduledReminders() async {
    try {
      await _localNotificationsPlugin.cancelAll();

      await scheduleDailyNotification(
        id: 1001,
        title: 'Chào buổi sáng cùng BodyPilot! 🍳🏋️',
        body: 'Đừng quên ghi lại bữa sáng lành mạnh và xem hôm nay chúng ta sẽ tập gì nhé!',
        hour: 7,
        minute: 0,
      );

      await scheduleDailyNotification(
        id: 1002,
        title: 'Đến giờ ăn trưa rồi! 🥗💧',
        body: 'Hãy ghi lại thực đơn hôm nay để BodyPilot tính toán lượng calo giúp bạn nhé!',
        hour: 12,
        minute: 0,
      );

      await scheduleDailyNotification(
        id: 1003,
        title: 'Thời gian tập luyện lý tưởng đã đến! 💪🏃',
        body: 'Cùng hoàn thành mục tiêu thể thao hôm nay để khỏe mạnh và tràn đầy năng lượng nào!',
        hour: 17,
        minute: 30,
      );

      await scheduleDailyNotification(
        id: 1004,
        title: 'Nhìn lại lượng calo hôm nay thôi! 🌛📊',
        body: 'Đừng quên lưu lại bữa tối và cùng đánh giá mức độ hoàn thành mục tiêu ngày hôm nay nhé.',
        hour: 20,
        minute: 30,
      );

      await scheduleWeeklyNotification(
        id: 1005,
        title: 'Báo cáo sức khỏe tuần này đã sẵn sàng! 📈🔥',
        body: 'Cùng BodyPilot tổng kết quá trình thay đổi tích cực của bạn trong 7 ngày qua nhé!',
        dayOfWeek: DateTime.sunday,
        hour: 20,
        minute: 0,
      );

      _logger.i('Completed scheduling all reminders.');
    } catch (e) {
      _logger.e('Error setting up reminders: $e');
    }
  }

  static Future<void> _showLocalNotification(RemoteMessage message) async {
    final notification = message.notification;
    if (notification == null) return;

    const AndroidNotificationDetails androidDetails = AndroidNotificationDetails(
      'bodypilot_channel',
      'BodyPilot Notifications',
      channelDescription: 'Kênh nhận thông báo của ứng dụng BodyPilot',
      importance: Importance.max,
      priority: Priority.high,
      playSound: true,
    );

    const DarwinNotificationDetails iosDetails = DarwinNotificationDetails();

    const NotificationDetails platformDetails = NotificationDetails(
      android: androidDetails,
      iOS: iosDetails,
    );

    await _localNotificationsPlugin.show(
      id: notification.hashCode,
      title: notification.title,
      body: notification.body,
      notificationDetails: platformDetails,
      payload: message.data.toString(),
    );
  }

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

    const NotificationDetails platformDetails = NotificationDetails(
      android: androidDetails,
      iOS: iosDetails,
    );

    final notificationTitle = title ?? 'Chúc mừng! Bạn đã hoàn thành buổi tập hôm nay! 🎉💪';
    final caloText = (totalCaloriesBurned != null && totalCaloriesBurned > 0)
        ? ' Bạn đã đốt cháy khoảng ${totalCaloriesBurned.toInt()} kcal.'
        : '';
    final notificationBody = body ?? 'Tất cả các bài tập trong ngày đã được hoàn thành.$caloText Tiếp tục phát huy nhé!';

    await _localNotificationsPlugin.show(
      id: DateTime.now().millisecondsSinceEpoch ~/ 1000,
      title: notificationTitle,
      body: notificationBody,
      notificationDetails: platformDetails,
    );
  }
}
