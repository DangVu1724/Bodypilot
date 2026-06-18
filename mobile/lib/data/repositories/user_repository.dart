import 'package:core_shared/models/health_condition_model.dart';
import 'package:core_shared/models/injury_model.dart';
import 'package:core_shared/models/allergy_model.dart';
import 'package:core_shared/models/diet_tag_model.dart';
import 'package:core_shared/models/user_model.dart';
import 'package:dio/dio.dart';
import 'package:mobile/core/network/api_client.dart';
import 'package:mobile/data/services/token_service.dart';

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

  Future<List<AllergyModel>> getAllergies() async {
    try {
      final response = await apiClient.get('/allergies');
      final List<dynamic> data = response.data;
      return data.map((json) => AllergyModel.fromJson(json)).toList();
    } on DioException catch (e) {
      throw Exception(e.response?.data['message'] ?? 'Network error');
    }
  }

  Future<List<DietTagModel>> getDietTags() async {
    try {
      final response = await apiClient.get('/foods/diet-tags');
      final List<dynamic> data = response.data['data'];
      return data.map((json) => DietTagModel.fromJson(json)).toList();
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

      if (response.data['success'] == true) {
        await TokenService.setAssessmentCompleted(true);
      } else {
        throw Exception(response.data['message'] ?? 'Failed to submit assessment');
      }
    } on DioException catch (e) {
      throw Exception(e.response?.data['message'] ?? 'Network error');
    }
  }

  Future<void> updateUserAllergies(String userId, List<String> selectedAllergies, String allergyNote) async {
    try {
      await apiClient.post(
        '/users/$userId/allergies',
        data: {
          'selectedAllergies': selectedAllergies,
          'allergyNote': allergyNote,
        },
      );
    } on DioException catch (e) {
      throw Exception(e.response?.data['message'] ?? 'Network error');
    }
  }

  Future<void> updateUserPreferences(String userId, Map<String, dynamic> data) async {
    try {
      await apiClient.post(
        '/users/$userId/preferences',
        data: data,
      );
    } on DioException catch (e) {
      throw Exception(e.response?.data['message'] ?? 'Network error');
    }
  }

  Future<String> getAiDietSuggestion(String userId) async {
    try {
      final response = await apiClient.get('/users/$userId/ai-diet-suggestion');
      if (response.data['success'] == true) {
        return response.data['data'] as String;
      } else {
        throw Exception(response.data['message'] ?? 'Failed to load AI suggestion');
      }
    } on DioException catch (e) {
      throw Exception(e.response?.data['message'] ?? 'Network error');
    }
  }
}

final userRepository = UserRepository();
