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
    await _prefs?.remove(_tokenKey);
    await _prefs?.remove(_userIdKey);
    await _prefs?.remove(_isAssessmentCompletedKey);
    await _prefs?.remove(_isMealSurveyCompletedKey);
    await _prefs?.remove(_isWorkoutSurveyCompletedKey);
    await _prefs?.remove(_lastActivityKey);
    await _prefs?.remove(_cachedUserKey);
  }

  static bool hasToken() {
    return _prefs?.containsKey(_tokenKey) ?? false;
  }

  static Future<void> saveUserCache(UserModel user) async {
    await _prefs?.setString(_cachedUserKey, jsonEncode(user.toJson()));
  }

  static UserModel? getCachedUser() {
    final jsonString = _prefs?.getString(_cachedUserKey);
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

  static Future<void> saveSelectedModel(String model) async {
    await _prefs?.setString('selected_chat_model', model);
  }

  static String? getSelectedModel() {
    return _prefs?.getString('selected_chat_model');
  }

  static Future<void> saveFocusBodyPart(String bodyPart) async {
    await _prefs?.setString('focus_body_part', bodyPart);
  }

  static String getFocusBodyPart() {
    return _prefs?.getString('focus_body_part') ?? 'NONE';
  }
}
