import 'package:core_shared/models/food_category_model.dart';
import 'package:core_shared/models/food_model.dart';
import 'package:core_shared/models/paginated_response.dart';
import 'package:dio/dio.dart';
import 'package:mobile/core/network/api_client.dart';
import 'package:logger/logger.dart';
import 'package:mobile/data/local/sqlite/food_database_helper.dart';

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
        queryParameters: {'query': query, 'categoryId': ?categoryId, 'page': page, 'size': size},
      );

      _logger.d('Fetch foods response data: ${response.data}');

      final paginated = PaginatedResponse<FoodModel>.fromJson(
        response.data['data'] as Map<String, dynamic>,
        (json) => FoodModel.fromJson(json),
      );

      // Async cache results in SQLite
      try {
        await FoodDatabaseHelper.instance.insertFoods(paginated.content);
      } catch (dbError) {
        _logger.e('Failed to cache foods in SQLite: $dbError');
      }

      return paginated;
    } on DioException catch (e) {
      _logger.e('Error searching foods: $e, response: ${e.response?.data}');
      
      // Fallback: Query SQLite cache
      try {
        _logger.i('Network failed. Attempting offline SQLite search for query: "$query"...');
        final localFoods = await FoodDatabaseHelper.instance.searchFoodsOffline(
          query,
          categoryId: categoryId,
          limit: size,
          offset: page * size,
        );
        
        if (localFoods.isNotEmpty) {
          _logger.i('Offline search successful, returned ${localFoods.length} items.');
          return PaginatedResponse<FoodModel>(
            content: localFoods,
            pageNumber: page,
            pageSize: size,
            totalElements: localFoods.length,
            totalPages: 1,
            last: true,
          );
        }
      } catch (dbError) {
        _logger.e('Failed to read from local SQLite: $dbError');
      }

      throw Exception(e.response?.data['message'] ?? 'Network error');
    }
  }

  Future<FoodModel> getFoodDetails(String foodId) async {
    try {
      final response = await apiClient.get('/foods/$foodId');
      final food = FoodModel.fromJson(response.data['data'] as Map<String, dynamic>);
      
      // Cache detail in SQLite
      try {
        await FoodDatabaseHelper.instance.insertFoods([food]);
      } catch (dbError) {
        _logger.e('Failed to cache food details: $dbError');
      }

      return food;
    } on DioException catch (e) {
      _logger.e('Error fetching details, attempting offline SQLite search...: $e');
      try {
        final localFoods = await FoodDatabaseHelper.instance.searchFoodsOffline('');
        for (final food in localFoods) {
          if (food.id == foodId) {
            _logger.i('Found food details offline.');
            return food;
          }
        }
      } catch (dbError) {
        _logger.e('Failed to find food offline: $dbError');
      }
      throw Exception(e.response?.data['message'] ?? 'Network error');
    }
  }

  Future<List<FoodCategoryModel>> getFoodCategories() async {
    try {
      final response = await apiClient.get('/foods/categories');
      final List<dynamic> data = response.data['data'] as List<dynamic>;
      final categories = data.map((e) => FoodCategoryModel.fromJson(e as Map<String, dynamic>)).toList();
      
      // Cache categories in SQLite
      try {
        await FoodDatabaseHelper.instance.insertCategories(categories);
      } catch (dbError) {
        _logger.e('Failed to cache categories in SQLite: $dbError');
      }

      return categories;
    } on DioException catch (e) {
      _logger.e('Error fetching categories, attempting offline SQLite query...: $e');
      try {
        final localCategories = await FoodDatabaseHelper.instance.getCategoriesOffline();
        if (localCategories.isNotEmpty) {
          _logger.i('Loaded categories offline.');
          return localCategories;
        }
      } catch (dbError) {
        _logger.e('Failed to load categories offline: $dbError');
      }
      throw Exception(e.response?.data['message'] ?? 'Network error');
    }
  }
}

final foodRepository = FoodRepository();

