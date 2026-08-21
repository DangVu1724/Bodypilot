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

    _logger.i('FCM authorization status: ${settings.authorizationStatus}');

    await _firebaseMessaging.setForegroundNotificationPresentationOptions(alert: true, badge: true, sound: true);

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
    await cancelAllScheduledReminders();

    FirebaseMessaging.onMessage.listen((RemoteMessage message) async {
      _logger.i("FCM Foreground message received: ${message.notification?.title}");
      await _saveIncomingNotificationToHive(message);
      _showLocalNotification(message);
    });

    FirebaseMessaging.onMessageOpenedApp.listen((RemoteMessage message) async {
      _logger.i("FCM Message opened app: ${message.data}");
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

  static Future<void> scheduleDailyNotification({
    required int id,
    required String title,
    required String body,
    required int hour,
    required int minute,
  }) async {
    final tz.TZDateTime now = tz.TZDateTime.now(tz.local);
    tz.TZDateTime scheduledDate = tz.TZDateTime(tz.local, now.year, now.month, now.day, hour, minute);

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

    const NotificationDetails platformDetails = NotificationDetails(android: androidDetails, iOS: iosDetails);

    try {
      await _localNotificationsPlugin.zonedSchedule(
        id: id,
        title: title,
        body: body,
        scheduledDate: scheduledDate,
        notificationDetails: platformDetails,
        androidScheduleMode: AndroidScheduleMode.exactAllowWhileIdle,
        matchDateTimeComponents: DateTimeComponents.time,
      );
    } catch (e) {
      _logger.w("Exact schedule failed for ID $id: $e. Retrying with inexact schedule.");
      await _localNotificationsPlugin.zonedSchedule(
        id: id,
        title: title,
        body: body,
        scheduledDate: scheduledDate,
        notificationDetails: platformDetails,
        androidScheduleMode: AndroidScheduleMode.inexactAllowWhileIdle,
        matchDateTimeComponents: DateTimeComponents.time,
      );
    }
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
    tz.TZDateTime scheduledDate = tz.TZDateTime(tz.local, now.year, now.month, now.day, hour, minute);

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

    const NotificationDetails platformDetails = NotificationDetails(android: androidDetails, iOS: iosDetails);

    try {
      await _localNotificationsPlugin.zonedSchedule(
        id: id,
        title: title,
        body: body,
        scheduledDate: scheduledDate,
        notificationDetails: platformDetails,
        androidScheduleMode: AndroidScheduleMode.exactAllowWhileIdle,
        matchDateTimeComponents: DateTimeComponents.dayOfWeekAndTime,
      );
    } catch (e) {
      _logger.w("Exact weekly schedule failed for ID $id: $e. Retrying with inexact schedule.");
      await _localNotificationsPlugin.zonedSchedule(
        id: id,
        title: title,
        body: body,
        scheduledDate: scheduledDate,
        notificationDetails: platformDetails,
        androidScheduleMode: AndroidScheduleMode.inexactAllowWhileIdle,
        matchDateTimeComponents: DateTimeComponents.dayOfWeekAndTime,
      );
    }
    _logger.i('Weekly notification scheduled (ID $id) on Day $dayOfWeek at $hour:$minute');
  }

  // =========================================================================
  // 1. QUẢN LÝ THÔNG BÁO HẸN GIỜ: NHƯỜNG HOÀN TOÀN CHO BACKEND SERVER FCM
  // =========================================================================
  static Future<void> cancelAllScheduledReminders() async {
    try {
      await _localNotificationsPlugin.cancelAll();
      _logger.i(
        '✅ [LocalNoti] Cancelled all local scheduled alarms. All fixed scheduled notifications are managed by Backend FCM Server.',
      );
    } catch (e) {
      _logger.e('Error cancelling local reminders: $e');
    }
  }

  /// Nhắc nhở khi chưa lập thực đơn trong ngày
  static Future<void> scheduleUnloggedMealReminder({int hour = 11, int minute = 30}) async {
    const id = 1010;
    const title = 'Bạn chưa lên thực đơn hôm nay! 🥗';
    const body =
        'Dành 1 phút ghi nhận món ăn hoặc dùng tính năng Gợi ý Thực đơn thông minh để đạt chuẩn TDEE giúp bạn nhé!';

    await scheduleDailyNotification(id: id, title: title, body: body, hour: hour, minute: minute);
  }

  /// Nhắc nhở bài tập cá nhân hóa theo nhóm cơ / bài tập hôm nay
  static Future<void> scheduleTodayWorkoutReminder({
    required String workoutName,
    String? targetMuscle,
    int hour = 17,
    int minute = 0,
  }) async {
    const id = 1011;
    final title = 'Hôm nay bạn có lịch tập: $workoutName! 💪';
    final targetText = (targetMuscle != null && targetMuscle.isNotEmpty) ? ' (Nhóm cơ: $targetMuscle)' : '';
    final body = 'Buổi tập $workoutName$targetText đã sẵn sàng. Chuẩn bị năng lượng và hoàn thành bài tập ngay thôi!';

    await scheduleDailyNotification(id: id, title: title, body: body, hour: hour, minute: minute);
  }

  // =========================================================================
  // 2. CHỨC NĂNG 2: HIỂN THỊ POP-UP BANNER KHI ĐANG MỞ APP (FOREGROUND BANNER)
  // =========================================================================
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

  // =========================================================================
  // 3. CHỨC NĂNG 3: THÔNG BÁO SỰ KIỆN TẠI CHỖ (LOCAL INSTANT EVENTS)
  // =========================================================================

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

    final notificationTitle = title ?? 'Chúc mừng! Bạn đã hoàn thành buổi tập hôm nay! 🎉💪';
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

  /// Thông báo ngay lập tức hoặc nhắc nhở UỐNG NƯỚC tại chỗ
  static Future<void> showWaterReminderNotification({
    int waterAmountMl = 250,
    int? currentTotalMl,
    int? targetTotalMl,
  }) async {
    const AndroidNotificationDetails androidDetails = AndroidNotificationDetails(
      'bodypilot_water_channel',
      'BodyPilot Water Reminder',
      channelDescription: 'Nhắc nhở uống nước hàng ngày của BodyPilot',
      importance: Importance.high,
      priority: Priority.high,
      playSound: true,
    );

    const DarwinNotificationDetails iosDetails = DarwinNotificationDetails();

    const NotificationDetails platformDetails = NotificationDetails(android: androidDetails, iOS: iosDetails);

    final String progressText = (currentTotalMl != null && targetTotalMl != null)
        ? ' (Tiến độ: $currentTotalMl/$targetTotalMl ml)'
        : '';
    final String body =
        'Đã nạp thêm $waterAmountMl ml nước mát!$progressText Cơ thể bạn đang được cấp nước đầy đủ để vận động.';

    await _localNotificationsPlugin.show(
      id: DateTime.now().millisecondsSinceEpoch ~/ 1000 + 1,
      title: 'Đã ghi nhận uống nước! 💧🥛',
      body: body,
      notificationDetails: platformDetails,
    );
  }
}
