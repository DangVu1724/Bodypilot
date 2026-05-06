import 'package:core_shared/models/food_category_model.dart';
import 'package:core_shared/models/food_model.dart';
import 'package:core_shared/models/paginated_response.dart';
import 'package:dio/dio.dart';
import 'package:mobile/core/network/api_client.dart';
import 'package:logger/logger.dart';

final _logger = Logger();

class FoodRepository {
  Future<PaginatedResponse<FoodModel>> searchFoods(
    String query, {
    String? categoryId,
    int page = 0,
    int size = 10,
  }) async {
    _logger.d('Searching foods with query: $query, categoryId: $categoryId, page: $page, size: $size');
    try {
      final response = await apiClient.get(
        '/foods/search',
        queryParameters: {'query': query, if (categoryId != null) 'categoryId': categoryId, 'page': page, 'size': size},
      );

      _logger.d('Fetch foods response data: ${response.data}');

      return PaginatedResponse<FoodModel>.fromJson(
        response.data['data'] as Map<String, dynamic>,
        (json) => FoodModel.fromJson(json as Map<String, dynamic>),
      );
    } on DioException catch (e) {
      _logger.e('Error searching foods: $e, response: ${e.response?.data}');
      throw Exception(e.response?.data['message'] ?? 'Network error');
    }
  }

  Future<FoodModel> getFoodDetails(String foodId) async {
    try {
      final response = await apiClient.get('/foods/$foodId');
      return FoodModel.fromJson(response.data['data'] as Map<String, dynamic>);
    } on DioException catch (e) {
      throw Exception(e.response?.data['message'] ?? 'Network error');
    }
  }

  Future<List<FoodCategoryModel>> getFoodCategories() async {
    try {
      final response = await apiClient.get('/foods/categories');
      final List<dynamic> data = response.data['data'] as List<dynamic>;
      return data.map((e) => FoodCategoryModel.fromJson(e as Map<String, dynamic>)).toList();
    } on DioException catch (e) {
      throw Exception(e.response?.data['message'] ?? 'Network error');
    }
  }
}

final foodRepository = FoodRepository();
