import 'package:shared_preferences/shared_preferences.dart';

class TokenService {
  static const String _tokenKey = 'jwt_token';
  static const String _userIdKey = 'user_id';
  static const String _isAssessmentCompletedKey = 'is_assessment_completed';
  static SharedPreferences? _prefs;

  static Future<void> init() async {
    _prefs = await SharedPreferences.getInstance();
  }

  static Future<void> saveToken(String token, String userId, bool isAssessmentCompleted) async {
    await _prefs?.setString(_tokenKey, token);
    await _prefs?.setString(_userIdKey, userId);
    await _prefs?.setBool(_isAssessmentCompletedKey, isAssessmentCompleted);
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

  static Future<void> removeToken() async {
    await _prefs?.remove(_tokenKey);
    await _prefs?.remove(_userIdKey);
    await _prefs?.remove(_isAssessmentCompletedKey);
  }

  static bool hasToken() {
    return _prefs?.containsKey(_tokenKey) ?? false;
  }
}
