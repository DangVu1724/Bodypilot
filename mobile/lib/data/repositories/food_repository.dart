import 'package:core_shared/models/food_category_model.dart';
import 'package:core_shared/models/food_model.dart';
import 'package:core_shared/models/paginated_response.dart';
import 'package:dio/dio.dart';
import 'package:logger/logger.dart';
import 'package:mobile/core/network/api_client.dart';
import 'package:mobile/data/local/sqlite/food_database_helper.dart';

final _logger = Logger();

class FoodRepository {
  final Map<String, PaginatedResponse<FoodModel>> _foodCategoryCache = {};
  bool _isSyncing = false;

  bool _isSyncCompleted = false;

  Future<PaginatedResponse<FoodModel>> searchFoods(
    String query, {
    String? categoryId,
    String? type,
    int page = 0,
    int size = 50,
    bool forceRefresh = false,
  }) async {
    final trimmedQuery = query.trim();

    // 0. Sanitize Query: If query contains ONLY special characters (!@#$%^&*...), return 0 items immediately
    if (trimmedQuery.isNotEmpty && RegExp(r'^[^a-zA-Z0-9àáâãèéêìíòóôõùúăđĩũơưăạảấầẩẫậắằẳẵặẹẻẽềềểễệỉịọỏốồổỗộớờởỡợụủứừửữựỳỵỷỹ\s]+$').hasMatch(trimmedQuery)) {
      _logger.d('🚫 [SanitizeQuery] Query "$query" contains only special characters. Returning 0 results instantly.');
      return PaginatedResponse<FoodModel>(
        content: [],
        pageNumber: page,
        pageSize: size,
        totalElements: 0,
        totalPages: 0,
        last: true,
      );
    }

    // 1. RAM Cache check
    if (page == 0 && categoryId != null && trimmedQuery.isEmpty && !forceRefresh) {
      if (_foodCategoryCache.containsKey(categoryId)) {
        _logger.d('Serving food category $categoryId from RAM cache');
        return _foodCategoryCache[categoryId]!;
      }
    }

    // 2. Local SQLite First (Instant UX response)
    if (!forceRefresh) {
      try {
        final localFoods = await FoodDatabaseHelper.instance.searchFoodsOffline(
          trimmedQuery,
          categoryId: categoryId,
          type: type,
          limit: size < 50 ? 50 : size,
          offset: page * size,
        );

        if (localFoods.isNotEmpty) {
          _logger.i('⚡ [Local-First] Serving ${localFoods.length} foods from SQLite for query "$trimmedQuery"');

          // Trigger background revalidation silently
          _revalidateFoodsInBackground(query: trimmedQuery, categoryId: categoryId, page: page, size: size);

          return PaginatedResponse<FoodModel>(
            content: localFoods,
            pageNumber: page,
            pageSize: size,
            totalElements: localFoods.length,
            totalPages: 1,
            last: true,
          );
        }

        // If SQLite returned 0 items AND full background sync is completed, NO need to hit backend!
        if (_isSyncCompleted) {
          _logger.i('ℹ️ [FullSyncCompleted] Query "$trimmedQuery" not found in SQLite. Returning 0 results without hitting backend.');
          return PaginatedResponse<FoodModel>(
            content: [],
            pageNumber: page,
            pageSize: size,
            totalElements: 0,
            totalPages: 0,
            last: true,
          );
        }
      } catch (dbError) {
        _logger.e('Failed local SQLite read: $dbError');
      }
    }

    // 3. Fallback/Primary Backend Search
    _logger.d('Searching foods from Backend with query: $query, categoryId: $categoryId, page: $page, size: $size');
    try {
      final response = await apiClient.get(
        '/foods/search',
        queryParameters: {'query': query, 'categoryId': categoryId, 'page': page, 'size': size},
      );

      final paginated = PaginatedResponse<FoodModel>.fromJson(
        response.data['data'] as Map<String, dynamic>,
        (json) => FoodModel.fromJson(json),
      );

      if (page == 0 && categoryId != null && query.isEmpty) {
        if (_foodCategoryCache.length > 20) {
          _foodCategoryCache.remove(_foodCategoryCache.keys.first);
        }
        _foodCategoryCache[categoryId] = paginated;
      }

      // Async cache results in SQLite
      try {
        await FoodDatabaseHelper.instance.insertFoods(paginated.content);
      } catch (dbError) {
        _logger.e('Failed to cache foods in SQLite: $dbError');
      }

      return paginated;
    } on DioException catch (e) {
      _logger.e('Error searching foods from backend: $e');
      throw Exception(e.response?.data['message'] ?? 'Network error');
    }
  }

  /// Background revalidation (Stale-While-Revalidate pattern)
  void _revalidateFoodsInBackground({
    required String query,
    String? categoryId,
    required int page,
    required int size,
  }) async {
    try {
      final response = await apiClient.get(
        '/foods/search',
        queryParameters: {'query': query, 'categoryId': categoryId, 'page': page, 'size': size},
      );
      final paginated = PaginatedResponse<FoodModel>.fromJson(
        response.data['data'] as Map<String, dynamic>,
        (json) => FoodModel.fromJson(json),
      );
      await FoodDatabaseHelper.instance.insertFoods(paginated.content);
      _logger.d('🔄 [Background Revalidate] Refreshed SQLite with ${paginated.content.length} items');
    } catch (_) {
      // Ignore background errors quietly
    }
  }

  /// Batched Background Sync (Chunks of 100 items with non-blocking pauses)
  Future<void> startBatchedFoodSync({int batchSize = 100, int maxBatches = 10}) async {
    if (_isSyncing) {
      _logger.d('⏳ [BatchedFoodSync] Sync already in progress, skipping...');
      return;
    }
    _isSyncing = true;
    _logger.i('🚀 [BatchedFoodSync] Starting batched background sync (batchSize=$batchSize)...');

    try {
      for (int page = 0; page < maxBatches; page++) {
        final response = await apiClient.get(
          '/foods/search',
          queryParameters: {'query': '', 'page': page, 'size': batchSize},
        );

        final paginated = PaginatedResponse<FoodModel>.fromJson(
          response.data['data'] as Map<String, dynamic>,
          (json) => FoodModel.fromJson(json),
        );

        if (paginated.content.isEmpty) break;

        await FoodDatabaseHelper.instance.insertFoods(paginated.content);
        _logger.d('📦 [BatchedFoodSync] Batch ${page + 1}/$maxBatches inserted (${paginated.content.length} foods)');

        if (paginated.last) break;

        // Non-blocking 100ms pause between batches for smooth 60fps UI
        await Future.delayed(const Duration(milliseconds: 100));
      }
      _isSyncCompleted = true;
      _logger.i('✅ [BatchedFoodSync] Completed background sync successfully.');
    } catch (e) {
      _logger.e('Error during batched food sync: $e');
    } finally {
      _isSyncing = false;
    }
  }

  Future<FoodModel> getFoodDetails(String foodId) async {
    // Check local DB first
    try {
      final localFoods = await FoodDatabaseHelper.instance.searchFoodsOffline('');
      for (final food in localFoods) {
        if (food.id == foodId) {
          _logger.i('⚡ [Local-First] Found food details offline for ID: $foodId');
          return food;
        }
      }
    } catch (_) {}

    try {
      final response = await apiClient.get('/foods/$foodId');
      final food = FoodModel.fromJson(response.data['data'] as Map<String, dynamic>);

      try {
        await FoodDatabaseHelper.instance.insertFoods([food]);
      } catch (dbError) {
        _logger.e('Failed to cache food details: $dbError');
      }

      return food;
    } on DioException catch (e) {
      _logger.e('Error fetching details: $e');
      throw Exception(e.response?.data['message'] ?? 'Network error');
    }
  }

  Future<List<FoodCategoryModel>> getFoodCategories({bool forceRefresh = false}) async {
    if (!forceRefresh) {
      try {
        final localCategories = await FoodDatabaseHelper.instance.getCategoriesOffline();
        if (localCategories.isNotEmpty) {
          _logger.i('⚡ [Local-First] Loaded ${localCategories.length} food categories offline.');
          // Refresh in background
          _refreshCategoriesInBackground();
          return localCategories;
        }
      } catch (dbError) {
        _logger.e('Failed to load categories offline: $dbError');
      }
    }

    try {
      final response = await apiClient.get('/foods/categories');
      final List<dynamic> data = response.data['data'] as List<dynamic>;
      final categories = data.map((e) => FoodCategoryModel.fromJson(e as Map<String, dynamic>)).toList();

      try {
        await FoodDatabaseHelper.instance.insertCategories(categories);
      } catch (dbError) {
        _logger.e('Failed to cache categories in SQLite: $dbError');
      }

      return categories;
    } on DioException catch (e) {
      _logger.e('Error fetching categories: $e');
      throw Exception(e.response?.data['message'] ?? 'Network error');
    }
  }

  void _refreshCategoriesInBackground() async {
    try {
      final response = await apiClient.get('/foods/categories');
      final List<dynamic> data = response.data['data'] as List<dynamic>;
      final categories = data.map((e) => FoodCategoryModel.fromJson(e as Map<String, dynamic>)).toList();
      await FoodDatabaseHelper.instance.insertCategories(categories);
    } catch (_) {}
  }

  Future<void> prefetchPopularFoodCategories() async {
    try {
      final categories = await getFoodCategories();
      for (final cat in categories.take(4)) {
        if (!_foodCategoryCache.containsKey(cat.id)) {
          searchFoods('', categoryId: cat.id, page: 0, size: 10);
        }
      }
    } catch (e) {
      _logger.w('Prefetch food categories failed: $e');
    }
  }

  void clearCache() {
    _foodCategoryCache.clear();
  }
}

final foodRepository = FoodRepository();
