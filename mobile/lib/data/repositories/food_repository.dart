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

  /// Tìm kiếm món ăn (Ưu tiên SQLite local -> Backend API)
  Future<PaginatedResponse<FoodModel>> searchFoods(
    String query, {
    String? categoryId,
    String? type,
    int page = 0,
    int size = 50,
    bool forceRefresh = false,
  }) async {
    final trimmedQuery = query.trim();

    // Kiểm tra ký tự đặc biệt
    if (trimmedQuery.isNotEmpty && RegExp(r'^[^a-zA-Z0-9àáâãèéêìíòóôõùúăđĩũơưăạảấầẩẫậắằẳẵặẹẻẽềềểễệỉịọỏốồổỗộớờởỡợụủứừửữựỳỵỷỹ\s]+$').hasMatch(trimmedQuery)) {
      return PaginatedResponse<FoodModel>(
        content: [],
        pageNumber: page,
        pageSize: size,
        totalElements: 0,
        totalPages: 0,
        last: true,
      );
    }

    // 1. Kiểm tra bộ nhớ RAM Cache
    if (page == 0 && categoryId != null && trimmedQuery.isEmpty && !forceRefresh) {
      if (_foodCategoryCache.containsKey(categoryId)) {
        return _foodCategoryCache[categoryId]!;
      }
    }

    // 2. Tìm kiếm trong SQLite cục bộ (Local-First)
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
          // Đồng bộ ngầm dữ liệu mới từ Backend
          _revalidateFoodsInBackground(query: trimmedQuery, categoryId: categoryId, page: page, size: size);

          return PaginatedResponse<FoodModel>(
            content: localFoods,
            pageNumber: page,
            pageSize: size,
            totalElements: localFoods.length,
            totalPages: 1,
            last: localFoods.length < size,
          );
        }

        if (_isSyncCompleted) {
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
        _logger.e('Lỗi đọc dữ liệu SQLite: $dbError');
      }
    }

    // 3. Gọi Backend API khi chưa có dữ liệu local
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

      // Lưu kết quả vào SQLite
      try {
        await FoodDatabaseHelper.instance.insertFoods(paginated.content);
      } catch (dbError) {
        _logger.e('Lỗi lưu món ăn vào SQLite: $dbError');
      }

      return paginated;
    } on DioException catch (e) {
      _logger.e('Lỗi kết nối máy chủ: $e');
      throw Exception(e.response?.data['message'] ?? 'Lỗi kết nối mạng');
    }
  }

  /// Cập nhật dữ liệu ngầm từ Backend vào SQLite
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
    } catch (_) {}
  }

  /// Đồng bộ dữ liệu món ăn theo lô khi khởi động
  Future<void> startBatchedFoodSync({int batchSize = 100, int maxBatches = 10}) async {
    if (_isSyncing) return;
    _isSyncing = true;

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

        if (paginated.last) break;

        await Future.delayed(const Duration(milliseconds: 100));
      }
      _isSyncCompleted = true;
    } catch (e) {
      _logger.e('Lỗi đồng bộ dữ liệu món ăn ngầm: $e');
    } finally {
      _isSyncing = false;
    }
  }

  /// Lấy chi tiết món ăn (Ưu tiên SQLite -> Backend API)
  Future<FoodModel> getFoodDetails(String foodId) async {
    try {
      final localFoods = await FoodDatabaseHelper.instance.searchFoodsOffline('');
      for (final food in localFoods) {
        if (food.id == foodId) return food;
      }
    } catch (_) {}

    try {
      final response = await apiClient.get('/foods/$foodId');
      final food = FoodModel.fromJson(response.data['data'] as Map<String, dynamic>);

      try {
        await FoodDatabaseHelper.instance.insertFoods([food]);
      } catch (_) {}

      return food;
    } on DioException catch (e) {
      throw Exception(e.response?.data['message'] ?? 'Lỗi kết nối mạng');
    }
  }

  /// Lấy danh mục món ăn (Ưu tiên SQLite -> Backend API)
  Future<List<FoodCategoryModel>> getFoodCategories({bool forceRefresh = false}) async {
    if (!forceRefresh) {
      try {
        final localCategories = await FoodDatabaseHelper.instance.getCategoriesOffline();
        if (localCategories.isNotEmpty) {
          _refreshCategoriesInBackground();
          return localCategories;
        }
      } catch (dbError) {
        _logger.e('Lỗi đọc danh mục từ SQLite: $dbError');
      }
    }

    try {
      final response = await apiClient.get('/foods/categories');
      final List<dynamic> data = response.data['data'] as List<dynamic>;
      final categories = data.map((e) => FoodCategoryModel.fromJson(e as Map<String, dynamic>)).toList();

      try {
        await FoodDatabaseHelper.instance.insertCategories(categories);
      } catch (_) {}

      return categories;
    } on DioException catch (e) {
      throw Exception(e.response?.data['message'] ?? 'Lỗi kết nối mạng');
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
    } catch (_) {}
  }

  void clearCache() {
    _foodCategoryCache.clear();
  }
}

final foodRepository = FoodRepository();
