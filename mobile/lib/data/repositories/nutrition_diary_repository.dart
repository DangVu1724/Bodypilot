import 'package:core_shared/models/daily_eating_model.dart';
import 'package:dio/dio.dart';
import 'package:mobile/core/network/api_client.dart';
import 'package:logger/logger.dart';
import 'package:mobile/data/services/token_service.dart';
import 'package:intl/intl.dart';

final _logger = Logger();

class NutritionDiaryRepository {
  final String _basePath = '/nutrition-diary';

  String _formatDate(DateTime date) {
    return DateFormat('yyyy-MM-dd').format(date);
  }

  Future<DailyEatingModel> getDailyEating(DateTime date) async {
    try {
      _logger.d('Has token: ${TokenService.hasToken()}');
      final response = await apiClient.get('$_basePath/day', queryParameters: {'date': _formatDate(date)});
      _logger.i('Fetched daily eating for ${_formatDate(date)}');
      return DailyEatingModel.fromJson(response.data['data'] as Map<String, dynamic>);
    } on DioException catch (e) {
      final status = e.response?.statusCode;
      final body = e.response?.data;
      _logger.e('Error fetching daily eating: status=$status, body=$body, error=${e.message}');
      throw Exception('Request failed (status: $status): ${body ?? e.message}');
    }
  }

  Future<List<DailyEatingModel>> getDailyEatingRange(DateTime startDate, DateTime endDate) async {
    try {
      final response = await apiClient.get(
        '$_basePath/range',
        queryParameters: {'startDate': _formatDate(startDate), 'endDate': _formatDate(endDate)},
      );
      final List<dynamic> data = response.data['data'] as List<dynamic>;
      return data.map((e) => DailyEatingModel.fromJson(e as Map<String, dynamic>)).toList();
    } on DioException catch (e) {
      _logger.e('Error fetching daily eating range: $e');
      throw Exception(e.response?.data['message'] ?? 'Network error');
    }
  }

  Future<DailyEatingModel> addFoodToDiary({
    required DateTime date,
    required MealType mealType,
    required Map<String, dynamic> itemData,
  }) async {
    try {
      final response = await apiClient.post(
        '$_basePath/add',
        data: itemData,
        queryParameters: {'date': _formatDate(date), 'mealType': mealType.name},
      );
      return DailyEatingModel.fromJson(response.data['data'] as Map<String, dynamic>);
    } on DioException catch (e) {
      _logger.e('Error adding food: $e');
      throw Exception(e.response?.data['message'] ?? 'Network error');
    }
  }

  Future<void> removeFoodFromDiary(String itemId) async {
    try {
      await apiClient.delete('$_basePath/item/$itemId');
    } on DioException catch (e) {
      _logger.e('Error removing food: $e');
      throw Exception(e.response?.data['message'] ?? 'Network error');
    }
  }

  Future<void> reorderMealItems(String mealSlotId, List<String> itemIds) async {
    try {
      await apiClient.post('$_basePath/reorder/$mealSlotId', data: itemIds);
    } on DioException catch (e) {
      _logger.e('Error reordering items: $e');
      throw Exception(e.response?.data['message'] ?? 'Network error');
    }
  }

  Future<void> clearMeal(DateTime date, MealType mealType) async {
    try {
      await apiClient.delete(
        '$_basePath/meal',
        queryParameters: {'date': _formatDate(date), 'mealType': mealType.name},
      );
    } on DioException catch (e) {
      _logger.e('Error clearing meal: $e');
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

  Future<void> addMultipleDailyEatings(List<Map<String, dynamic>> dailyEatings) async {
    try {
      await apiClient.post('$_basePath/batch', data: dailyEatings);
    } on DioException catch (e) {
      _logger.e('Error adding batch daily eatings: $e');
      throw Exception(e.response?.data['message'] ?? 'Network error');
    }
  }

  Future<DailyEatingModel> updateMealItemStatus(String itemId, bool isEaten) async {
    try {
      final response = await apiClient.patch('$_basePath/item/$itemId/status', queryParameters: {'isEaten': isEaten});
      return DailyEatingModel.fromJson(response.data['data'] as Map<String, dynamic>);
    } on DioException catch (e) {
      _logger.e('Error updating meal item status: $e');
      throw Exception(e.response?.data['message'] ?? 'Network error');
    }
  }

  Future<DailyEatingModel> updateMealSlotStatus(String slotId, bool isEaten) async {
    try {
      final response = await apiClient.patch('$_basePath/slot/$slotId/status', queryParameters: {'isEaten': isEaten});
      return DailyEatingModel.fromJson(response.data['data'] as Map<String, dynamic>);
    } on DioException catch (e) {
      _logger.e('Error updating meal slot status: $e');
      throw Exception(e.response?.data['message'] ?? 'Network error');
    }
  }
}

final nutritionDiaryRepository = NutritionDiaryRepository();
