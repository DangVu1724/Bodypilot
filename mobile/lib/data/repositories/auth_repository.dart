import 'package:dio/dio.dart';
import 'package:mobile/core/network/api_client.dart';
import 'package:mobile/data/services/token_service.dart';
import 'package:mobile/data/models/user_model.dart';

class AuthRepository {
  Future<bool> login(String email, String password) async {
    try {
      final response = await apiClient.post(
        '/auth/login',
        data: {'email': email, 'password': password},
      );

      if (response.data['success'] == true) {
        final token = response.data['data']['token'];
        final userData = response.data['data']['user'] as Map<String, dynamic>;
        final userId = userData['id'] as String;
        final profile = userData['profile'];
        final isComplete = profile != null ? (profile['isAssessmentCompleted'] ?? profile['assessmentCompleted'] ?? false) : false;
        await TokenService.saveToken(token, userId, isComplete);
        try {
          await TokenService.saveUserCache(UserModel.fromJson(userData));
        } catch (e) {
          // ignore cache error
        }
        return isComplete;
      } else {
        throw Exception(response.data['message'] ?? 'Login failed');
      }
    } on DioException catch (e) {
      throw Exception(e.response?.data['message'] ?? 'Network error');
    }
  }

  Future<bool> register(String email, String password, String fullName) async {
    try {
      final response = await apiClient.post(
        '/auth/register',
        data: {
          'email': email,
          'password': password,
          'fullName': fullName,
        },
      );

      if (response.data['success'] == true) {
        final token = response.data['data']['token'];
        final userData = response.data['data']['user'] as Map<String, dynamic>;
        final userId = userData['id'] as String;
        final profile = userData['profile'];
        final isComplete = profile != null ? (profile['isAssessmentCompleted'] ?? profile['assessmentCompleted'] ?? false) : false;
        await TokenService.saveToken(token, userId, isComplete);
        try {
          await TokenService.saveUserCache(UserModel.fromJson(userData));
        } catch (e) {
          // ignore cache error
        }
        return isComplete;
      } else {
        throw Exception(response.data['message'] ?? 'Registration failed');
      }
    } on DioException catch (e) {
      throw Exception(e.response?.data['message'] ?? 'Network error');
    }
  }

  Future<void> logout() async {
    await TokenService.removeToken();
  }
}

final authRepository = AuthRepository();
