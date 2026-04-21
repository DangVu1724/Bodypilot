import 'package:dio/dio.dart';
import 'package:mobile/core/network/api_client.dart';
import 'package:mobile/data/models/health_condition_model.dart';
import 'package:mobile/data/models/injury_model.dart';
import 'package:mobile/data/models/user_model.dart';

class UserRepository {
  Future<UserModel> getUserDetails(String userId) async {
    try {
      final response = await apiClient.get('/users/$userId');
      return UserModel.fromJson(response.data['data']);
    } on DioException catch (e) {
      throw Exception(e.response?.data['message'] ?? 'Network error');
    }
  }

  Future<List<HealthConditionModel>> getHealthConditions() async {
    try {
      final response = await apiClient.get('/health-conditions');
      final List<dynamic> data = response.data;
      return data.map((json) => HealthConditionModel.fromJson(json)).toList();
    } on DioException catch (e) {
      throw Exception(e.response?.data['message'] ?? 'Network error');
    }
  }

  Future<List<InjuryModel>> getInjuries() async {
    try {
      final response = await apiClient.get('/injuries');
      final List<dynamic> data = response.data;
      return data.map((json) => InjuryModel.fromJson(json)).toList();
    } on DioException catch (e) {
      throw Exception(e.response?.data['message'] ?? 'Network error');
    }
  }

  Future<void> submitAssessment(String userId, Map<String, dynamic> data) async {
    try {
      final response = await apiClient.post(
        '/users/$userId/assessment',
        data: data,
      );

      if (response.data['success'] != true) {
        throw Exception(response.data['message'] ?? 'Failed to submit assessment');
      }
    } on DioException catch (e) {
      throw Exception(e.response?.data['message'] ?? 'Network error');
    }
  }
}

final userRepository = UserRepository();
