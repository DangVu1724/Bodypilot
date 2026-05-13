import 'package:core_shared/models/workout_plan_model.dart';
import 'package:core_shared/models/workout_session_model.dart';
import '../../core/network/api_client.dart';
import 'package:logger/logger.dart';

final _logger = Logger();

class WorkoutRepository {
  Future<List<WorkoutPlanModel>> getAllPlans({String? goal}) async {
    try {
      final queryParams = <String, dynamic>{};
      if (goal != null) queryParams['goal'] = goal;

      final response = await apiClient.get('/workout-plans', queryParameters: queryParams);
      final List<dynamic> data = response.data as List<dynamic>;
      return data.map((e) => WorkoutPlanModel.fromJson(e as Map<String, dynamic>)).toList();
    } catch (e) {
      _logger.e('Error fetching workout plans: $e');
      throw Exception('Failed to load workout plans: $e');
    }
  }

  Future<List<WorkoutPlanModel>> getAllPlansFull() async {
    try {
      final response = await apiClient.get('/workout-plans/full');
      final List<dynamic> data = response.data as List<dynamic>;
      return data.map((e) => WorkoutPlanModel.fromJson(e as Map<String, dynamic>)).toList();
    } catch (e) {
      _logger.e('Error fetching full workout plans: $e');
      throw Exception('Failed to load full workout plans: $e');
    }
  }

  Future<WorkoutPlanModel> getPlanById(String id) async {
    try {
      final response = await apiClient.get('/workout-plans/$id');
      return WorkoutPlanModel.fromJson(response.data as Map<String, dynamic>);
    } catch (e) {
      _logger.e('Error fetching workout plan by id: $e');
      throw Exception('Failed to load workout plan: $e');
    }
  }

  Future<List<WorkoutSessionModel>> getSessionsByPlanId(String planId) async {
    try {
      final response = await apiClient.get('/workout-sessions/plan/$planId');
      final List<dynamic> data = response.data as List<dynamic>;
      return data.map((e) => WorkoutSessionModel.fromJson(e as Map<String, dynamic>)).toList();
    } catch (e) {
      _logger.e('Error fetching workout sessions: $e');
      throw Exception('Failed to load workout sessions: $e');
    }
  }

  Future<WorkoutSessionModel> getSessionById(String id) async {
    try {
      final response = await apiClient.get('/workout-sessions/$id');
      return WorkoutSessionModel.fromJson(response.data as Map<String, dynamic>);
    } catch (e) {
      _logger.e('Error fetching workout session by id: $e');
      throw Exception('Failed to load workout session: $e');
    }
  }
}

final workoutRepository = WorkoutRepository();
