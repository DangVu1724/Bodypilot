import 'package:shared_preferences/shared_preferences.dart';

class TokenService {
  static const String _tokenKey = 'jwt_token';
  static const String _userIdKey = 'user_id';
  static SharedPreferences? _prefs;

  static Future<void> init() async {
    _prefs = await SharedPreferences.getInstance();
  }

  static Future<void> saveToken(String token, String userId) async {
    await _prefs?.setString(_tokenKey, token);
    await _prefs?.setString(_userIdKey, userId);
  }

  static String? getToken() {
    return _prefs?.getString(_tokenKey);
  }

  static String? getUserId() {
    return _prefs?.getString(_userIdKey);
  }

  static Future<void> removeToken() async {
    await _prefs?.remove(_tokenKey);
    await _prefs?.remove(_userIdKey);
  }

  static bool hasToken() {
    return _prefs?.containsKey(_tokenKey) ?? false;
  }
}
