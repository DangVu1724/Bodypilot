import 'dart:convert';

import 'package:core_shared/models/user_model.dart';
import 'package:shared_preferences/shared_preferences.dart';

class TokenService {
  static const String _tokenKey = 'jwt_token';
  static const String _userIdKey = 'user_id';
  static const String _isAssessmentCompletedKey = 'is_assessment_completed';
  static const String _isMealSurveyCompletedKey = 'is_meal_survey_completed';
  static const String _isWorkoutSurveyCompletedKey = 'is_workout_survey_completed';
  static const String _lastActivityKey = 'last_activity_at';
  static const String _cachedUserKey = 'cached_user';
  static const String _streakCountKey = 'streak_count';
  static const String _lastStreakDateKey = 'last_streak_date';
  static SharedPreferences? _prefs;

  static Future<void> init() async {
    _prefs = await SharedPreferences.getInstance();
  }

  static Future<void> saveToken(String token, String userId, bool isAssessmentCompleted) async {
    await _prefs?.setString(_tokenKey, token);
    await _prefs?.setString(_userIdKey, userId);
    await _prefs?.setBool(_isAssessmentCompletedKey, isAssessmentCompleted);
    await updateLastActivity();
  }

  static String? getToken() {
    return _prefs?.getString(_tokenKey);
  }

  static String? getUserId() {
    return _prefs?.getString(_userIdKey);
  }

  static bool isAssessmentCompleted() {
    return _prefs?.getBool(_isAssessmentCompletedKey) ?? false;
  }

  static Future<void> setAssessmentCompleted(bool isCompleted) async {
    await _prefs?.setBool(_isAssessmentCompletedKey, isCompleted);
  }

  static bool isMealSurveyCompleted() {
    return _prefs?.getBool(_isMealSurveyCompletedKey) ?? false;
  }

  static Future<void> setMealSurveyCompleted(bool isCompleted) async {
    await _prefs?.setBool(_isMealSurveyCompletedKey, isCompleted);
  }

  static bool isWorkoutSurveyCompleted() {
    return _prefs?.getBool(_isWorkoutSurveyCompletedKey) ?? false;
  }

  static Future<void> setWorkoutSurveyCompleted(bool isCompleted) async {
    await _prefs?.setBool(_isWorkoutSurveyCompletedKey, isCompleted);
  }

  static Future<void> updateLastActivity() async {
    await _prefs?.setInt(_lastActivityKey, DateTime.now().millisecondsSinceEpoch);
  }

  static bool isSessionValid() {
    final lastActivity = _prefs?.getInt(_lastActivityKey);
    if (lastActivity == null) return false;

    final lastActivityDate = DateTime.fromMillisecondsSinceEpoch(lastActivity);
    final now = DateTime.now();
    final difference = now.difference(lastActivityDate).inDays;

    return difference < 7;
  }

  static Future<void> removeToken() async {
    final currentUserId = getUserId();
    if (currentUserId != null && currentUserId.isNotEmpty) {
      await _prefs?.remove('${_mealCheckInSummaryKey}_$currentUserId');
      await _prefs?.remove('${_workoutCheckInSummaryKey}_$currentUserId');
      await _prefs?.remove('${_isMealCheckInDoneKey}_$currentUserId');
      await _prefs?.remove('${_isWorkoutCheckInDoneKey}_$currentUserId');
      await _prefs?.remove('${_streakCountKey}_$currentUserId');
      await _prefs?.remove('${_lastStreakDateKey}_$currentUserId');
      await _prefs?.remove('focus_body_part_$currentUserId');
      await _prefs?.remove('selected_chat_model_$currentUserId');
      await _prefs?.remove('${_cachedUserKey}_$currentUserId');
    }

    await _prefs?.remove(_tokenKey);
    await _prefs?.remove(_userIdKey);
    await _prefs?.remove(_isAssessmentCompletedKey);
    await _prefs?.remove(_isMealSurveyCompletedKey);
    await _prefs?.remove(_isWorkoutSurveyCompletedKey);
    await _prefs?.remove(_lastActivityKey);
    await _prefs?.remove(_cachedUserKey);
    await _prefs?.remove(_mealCheckInSummaryKey);
    await _prefs?.remove(_workoutCheckInSummaryKey);
    await _prefs?.remove(_isMealCheckInDoneKey);
    await _prefs?.remove(_isWorkoutCheckInDoneKey);
    await _prefs?.remove(_streakCountKey);
    await _prefs?.remove(_lastStreakDateKey);
    await _prefs?.remove('focus_body_part');
    await _prefs?.remove('selected_chat_model');
  }

  static bool hasToken() {
    return _prefs?.containsKey(_tokenKey) ?? false;
  }

  static Future<void> saveUserCache(UserModel user) async {
    final userJson = jsonEncode(user.toJson());
    await _prefs?.setString(_cachedUserKey, userJson);
    await _prefs?.setString('${_cachedUserKey}_${user.id}', userJson);
  }

  static UserModel? getCachedUser([String? userId]) {
    final uid = userId ?? getUserId();
    final jsonString = (uid != null ? _prefs?.getString('${_cachedUserKey}_$uid') : null) ??
        _prefs?.getString(_cachedUserKey);
    if (jsonString != null) {
      try {
        return UserModel.fromJson(jsonDecode(jsonString));
      } catch (e) {
        return null;
      }
    }
    return null;
  }

  static Future<void> saveChatHistory(String userId, List<Map<String, dynamic>> messagesJson) async {
    await _prefs?.setString('chat_history_$userId', jsonEncode(messagesJson));
  }

  static List<Map<String, dynamic>> getChatHistory(String userId) {
    final raw = _prefs?.getString('chat_history_$userId');
    if (raw != null && raw.isNotEmpty) {
      try {
        final List<dynamic> decoded = jsonDecode(raw);
        return decoded.map((e) => Map<String, dynamic>.from(e as Map)).toList();
      } catch (e) {
        return [];
      }
    }
    return [];
  }

  static Future<void> clearChatHistory(String userId) async {
    await _prefs?.remove('chat_history_$userId');
  }

  static Future<void> saveSelectedModel(String model, [String? userId]) async {
    final uid = userId ?? getUserId();
    if (uid != null) {
      await _prefs?.setString('selected_chat_model_$uid', model);
    }
    await _prefs?.setString('selected_chat_model', model);
  }

  static String? getSelectedModel([String? userId]) {
    final uid = userId ?? getUserId();
    return (uid != null ? _prefs?.getString('selected_chat_model_$uid') : null) ??
        _prefs?.getString('selected_chat_model');
  }

  static Future<void> saveFocusBodyPart(String bodyPart, [String? userId]) async {
    final uid = userId ?? getUserId();
    if (uid != null) {
      await _prefs?.setString('focus_body_part_$uid', bodyPart);
    }
    await _prefs?.setString('focus_body_part', bodyPart);
  }

  static String getFocusBodyPart([String? userId]) {
    final uid = userId ?? getUserId();
    return (uid != null ? _prefs?.getString('focus_body_part_$uid') : null) ??
        _prefs?.getString('focus_body_part') ??
        'NONE';
  }

  static const String _mealCheckInSummaryKey = 'meal_checkin_summary';
  static const String _workoutCheckInSummaryKey = 'workout_checkin_summary';
  static const String _isMealCheckInDoneKey = 'is_meal_checkin_done';
  static const String _isWorkoutCheckInDoneKey = 'is_workout_checkin_done';

  static bool isMealCheckInDone([String? userId]) {
    final uid = userId ?? getUserId();
    if (uid == null) return false;
    return _prefs?.getBool('${_isMealCheckInDoneKey}_$uid') ?? false;
  }

  static Future<void> setMealCheckInDone(bool isDone, {Map<String, dynamic>? summary, String? userId}) async {
    final uid = userId ?? getUserId();
    if (uid != null) {
      await _prefs?.setBool('${_isMealCheckInDoneKey}_$uid', isDone);
      if (summary != null) {
        await _prefs?.setString('${_mealCheckInSummaryKey}_$uid', jsonEncode(summary));
      }
    }
    await _prefs?.setBool(_isMealCheckInDoneKey, isDone);
    if (summary != null) {
      await _prefs?.setString(_mealCheckInSummaryKey, jsonEncode(summary));
    }
  }

  static Map<String, dynamic>? getMealCheckInSummary([String? userId]) {
    final uid = userId ?? getUserId();
    if (uid == null) return null;
    final raw = _prefs?.getString('${_mealCheckInSummaryKey}_$uid') ?? _prefs?.getString(_mealCheckInSummaryKey);
    if (raw != null && raw.isNotEmpty) {
      try {
        return jsonDecode(raw) as Map<String, dynamic>;
      } catch (_) {}
    }
    return null;
  }

  static bool isWorkoutCheckInDone([String? userId]) {
    final uid = userId ?? getUserId();
    if (uid == null) return false;
    return _prefs?.getBool('${_isWorkoutCheckInDoneKey}_$uid') ?? false;
  }

  static Future<void> setWorkoutCheckInDone(bool isDone, {Map<String, dynamic>? summary, String? userId}) async {
    final uid = userId ?? getUserId();
    if (uid != null) {
      await _prefs?.setBool('${_isWorkoutCheckInDoneKey}_$uid', isDone);
      if (summary != null) {
        await _prefs?.setString('${_workoutCheckInSummaryKey}_$uid', jsonEncode(summary));
      }
    }
    await _prefs?.setBool(_isWorkoutCheckInDoneKey, isDone);
    if (summary != null) {
      await _prefs?.setString(_workoutCheckInSummaryKey, jsonEncode(summary));
    }
  }

  static Map<String, dynamic>? getWorkoutCheckInSummary([String? userId]) {
    final uid = userId ?? getUserId();
    if (uid == null) return null;
    final raw = _prefs?.getString('${_workoutCheckInSummaryKey}_$uid') ?? _prefs?.getString(_workoutCheckInSummaryKey);
    if (raw != null && raw.isNotEmpty) {
      try {
        return jsonDecode(raw) as Map<String, dynamic>;
      } catch (_) {}
    }
    return null;
  }

  /// Cập nhật và lấy số ngày chuỗi đăng nhập (Streak) liên tiếp ngoại tuyến
  static int updateAndGetStreak([String? userId]) {
    if (_prefs == null) return 1;

    final uid = userId ?? getUserId();
    final streakKey = uid != null ? '${_streakCountKey}_$uid' : _streakCountKey;
    final dateKey = uid != null ? '${_lastStreakDateKey}_$uid' : _lastStreakDateKey;

    final now = DateTime.now();
    final todayStr = "${now.year}-${now.month.toString().padLeft(2, '0')}-${now.day.toString().padLeft(2, '0')}";
    final lastDateStr = _prefs?.getString(dateKey);
    int currentStreak = _prefs?.getInt(streakKey) ?? 0;

    if (lastDateStr == null || lastDateStr.isEmpty) {
      // Lần đầu vào ứng dụng -> Khởi tạo streak = 1
      currentStreak = 1;
      _prefs?.setString(dateKey, todayStr);
      _prefs?.setInt(streakKey, currentStreak);
    } else if (lastDateStr == todayStr) {
      // Trong cùng một ngày -> Giữ nguyên streak hiện tại
      if (currentStreak < 1) {
        currentStreak = 1;
        _prefs?.setInt(streakKey, currentStreak);
      }
    } else {
      try {
        final parts = lastDateStr.split('-').map(int.parse).toList();
        final lastDate = DateTime(parts[0], parts[1], parts[2]);
        final todayDate = DateTime(now.year, now.month, now.day);
        final differenceInDays = todayDate.difference(lastDate).inDays;

        if (differenceInDays == 1) {
          // Ngày kế tiếp liên tục -> Cộng 1 ngày vào chuỗi (+1)
          currentStreak += 1;
        } else if (differenceInDays > 1) {
          // Bỏ lỡ ít nhất 1 ngày -> Reset chuỗi về 1
          currentStreak = 1;
        } else {
          // Trường hợp đổi múi giờ hoặc lùi ngày -> giữ nguyên
          if (currentStreak < 1) currentStreak = 1;
        }

        _prefs?.setString(dateKey, todayStr);
        _prefs?.setInt(streakKey, currentStreak);
      } catch (e) {
        currentStreak = 1;
        _prefs?.setString(dateKey, todayStr);
        _prefs?.setInt(streakKey, currentStreak);
      }
    }

    return currentStreak;
  }

  /// Lấy số ngày streak hiện tại
  static int getStreakCount([String? userId]) {
    return updateAndGetStreak(userId);
  }
}
