import 'package:core_shared/core_shared.dart';
import 'package:dio/dio.dart';
import 'package:mobile/core/network/api_client.dart';
import 'package:logger/logger.dart';
import 'package:mobile/data/services/token_service.dart';
import 'package:intl/intl.dart';

final _logger = Logger();

class WorkoutDiaryRepository {
  final String _basePath = '/workout-diary';

  String _formatDate(DateTime date) {
    return DateFormat('yyyy-MM-dd').format(date);
  }

  Future<DailyWorkoutModel> getDailyWorkout(DateTime date) async {
    try {
      _logger.d('Has token: ${TokenService.hasToken()}');
      final response = await apiClient.get('$_basePath/day', queryParameters: {'date': _formatDate(date)});
      _logger.i('Fetched daily workout for ${_formatDate(date)}');
      return DailyWorkoutModel.fromJson(response.data['data'] as Map<String, dynamic>);
    } on DioException catch (e) {
      final status = e.response?.statusCode;
      final body = e.response?.data;
      _logger.e('Error fetching daily workout: status=$status, body=$body, error=${e.message}');
      throw Exception('Request failed (status: $status): ${body ?? e.message}');
    }
  }

  Future<List<DailyWorkoutModel>> getDailyWorkoutRange(DateTime startDate, DateTime endDate) async {
    try {
      final response = await apiClient.get(
        '$_basePath/range',
        queryParameters: {'startDate': _formatDate(startDate), 'endDate': _formatDate(endDate)},
      );
      final List<dynamic> data = response.data['data'] as List<dynamic>;
      return data.map((e) => DailyWorkoutModel.fromJson(e as Map<String, dynamic>)).toList();
    } on DioException catch (e) {
      _logger.e('Error fetching daily workout range: $e');
      throw Exception(e.response?.data['message'] ?? 'Network error');
    }
  }

  Future<DailyWorkoutModel> addExerciseToDiary({
    required DateTime date,
    required Map<String, dynamic> itemData,
  }) async {
    try {
      final response = await apiClient.post(
        '$_basePath/add',
        data: itemData,
        queryParameters: {'date': _formatDate(date)},
      );
      return DailyWorkoutModel.fromJson(response.data['data'] as Map<String, dynamic>);
    } on DioException catch (e) {
      _logger.e('Error adding exercise: $e');
      throw Exception(e.response?.data['message'] ?? 'Network error');
    }
  }

  Future<void> removeExerciseFromDiary(String itemId) async {
    try {
      await apiClient.delete('$_basePath/item/$itemId');
    } on DioException catch (e) {
      _logger.e('Error removing exercise: $e');
      throw Exception(e.response?.data['message'] ?? 'Network error');
    }
  }

  Future<void> updateExerciseInDiary(String itemId, Map<String, dynamic> itemData) async {
    try {
      await apiClient.put('$_basePath/item/$itemId', data: itemData);
    } on DioException catch (e) {
      _logger.e('Error updating exercise in diary: $e');
      throw Exception(e.response?.data['message'] ?? 'Network error');
    }
  }

  Future<void> reorderWorkoutItems(String dailyWorkoutId, List<String> itemIds) async {
    try {
      await apiClient.post('$_basePath/reorder/$dailyWorkoutId', data: itemIds);
    } on DioException catch (e) {
      _logger.e('Error reordering items: $e');
      throw Exception(e.response?.data['message'] ?? 'Network error');
    }
  }

  Future<void> clearDay(DateTime date) async {
    try {
      await apiClient.delete('$_basePath/day', queryParameters: {'date': _formatDate(date)});
    } on DioException catch (e) {
      _logger.e('Error clearing day: $e');
      throw Exception(e.response?.data['message'] ?? 'Network error');
    }
  }

  Future<void> updateDailyNote(DateTime date, String note) async {
    try {
      await apiClient.patch('$_basePath/note', queryParameters: {'date': _formatDate(date), 'note': note});
    } on DioException catch (e) {
      _logger.e('Error updating note: $e');
      throw Exception(e.response?.data['message'] ?? 'Network error');
    }
  }

  Future<void> addMultipleDailyWorkouts(List<Map<String, dynamic>> dailyWorkouts) async {
    try {
      await apiClient.post('$_basePath/batch', data: dailyWorkouts);
    } on DioException catch (e) {
      _logger.e('Error adding batch daily workouts: $e');
      throw Exception(e.response?.data['message'] ?? 'Network error');
    }
  }

  Future<DailyWorkoutModel> updateExerciseStatus(String itemId, bool isCompleted) async {
    try {
      final response = await apiClient.patch('$_basePath/item/$itemId/status', queryParameters: {'isCompleted': isCompleted});
      return DailyWorkoutModel.fromJson(response.data['data'] as Map<String, dynamic>);
    } on DioException catch (e) {
      _logger.e('Error updating exercise status: $e');
      throw Exception(e.response?.data['message'] ?? 'Network error');
    }
  }
}

final workoutDiaryRepository = WorkoutDiaryRepository();
