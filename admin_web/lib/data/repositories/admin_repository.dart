import 'package:core_shared/core_shared.dart';
import 'package:dio/dio.dart';
import '../../core/network/api_client.dart';
import '../models/admin_stats_model.dart';

class AdminRepository {
  List<UserModel>? _cachedUsers;
  List<ExerciseModel>? _cachedExercises;
  List<FoodModel>? _cachedIngredients;
  List<FoodModel>? _cachedDishes;

  // 0. Lấy thống kê tổng quan (Dashboard Stats)
  Future<AdminStatsModel> getDashboardStats() async {
    try {
      final response = await apiClient.get('api/v1/admin/dashboard-stats');
      final dynamic rawData = response.data['data'] ?? response.data;
      return AdminStatsModel.fromJson(rawData as Map<String, dynamic>);
    } on DioException catch (e) {
      throw Exception('Lỗi API Dashboard Stats: ${e.response?.data['message'] ?? e.message}');
    } catch (e) {
      throw Exception('Lỗi xử lý dữ liệu Dashboard Stats: $e');
    }
  }

  // 1. Lấy danh sách người dùng (Full & Search)
  Future<List<UserModel>> getAllUsers({String? search, bool forceRefresh = false}) async {
    if (_cachedUsers != null && !forceRefresh && (search == null || search.isEmpty)) return _cachedUsers!;
    
    try {
      final Map<String, dynamic> params = {};
      if (search != null && search.isNotEmpty) params['search'] = search;

      final response = await apiClient.get('api/v1/users', queryParameters: params);
      final dynamic rawData = response.data['data'] ?? response.data;

      if (rawData is List) {
        final users = rawData.map((json) => UserModel.fromJson(json as Map<String, dynamic>)).toList();
        if (search == null || search.isEmpty) _cachedUsers = users;
        return users;
      }
      return [];
    } on DioException catch (e) {
      throw Exception('Lỗi API Người dùng: ${e.response?.data['message'] ?? e.message}');
    } catch (e) {
      throw Exception('Lỗi xử lý dữ liệu Người dùng: $e');
    }
  }

  // 2. Lấy danh sách bài tập
  Future<List<ExerciseModel>> getAllExercises({String? search, bool forceRefresh = false}) async {
    if (_cachedExercises != null && !forceRefresh && (search == null || search.isEmpty)) return _cachedExercises!;

    try {
      final Map<String, dynamic> params = {'size': 100};
      if (search != null && search.isNotEmpty) params['name'] = search;

      final response = await apiClient.get('api/v1/exercises', queryParameters: params);
      final dynamic rawData = response.data['data'] ?? response.data;
      
      List<dynamic> content = (rawData is Map) ? (rawData['content'] ?? []) : (rawData as List);
      final exercises = content.map((json) => ExerciseModel.fromJson(json as Map<String, dynamic>)).toList();
      if (search == null || search.isEmpty) _cachedExercises = exercises;
      return exercises;
    } on DioException catch (e) {
      throw Exception('Lỗi API Bài tập: ${e.response?.data['message'] ?? e.message}');
    } catch (e) {
      throw Exception('Lỗi xử lý dữ liệu Bài tập: $e');
    }
  }

  // 2b. Lấy chi tiết bài tập
  Future<ExerciseModel> getExerciseById(String id) async {
    try {
      final response = await apiClient.get('api/v1/exercises/$id');
      final dynamic rawData = response.data['data'] ?? response.data;
      return ExerciseModel.fromJson(rawData as Map<String, dynamic>);
    } on DioException catch (e) {
      throw Exception('Lỗi API Chi tiết bài tập: ${e.response?.data['message'] ?? e.message}');
    }
  }

  // 2c. Thêm mới bài tập
  Future<ExerciseModel> createExercise(ExerciseModel exercise) async {
    try {
      final response = await apiClient.post('api/v1/exercises', data: exercise.toJson());
      final dynamic rawData = response.data['data'] ?? response.data;
      _cachedExercises = null; // Clear cache
      return ExerciseModel.fromJson(rawData as Map<String, dynamic>);
    } on DioException catch (e) {
      throw Exception('Lỗi thêm bài tập: ${e.response?.data['message'] ?? e.message}');
    }
  }

  // 2d. Cập nhật bài tập
  Future<ExerciseModel> updateExercise(String id, ExerciseModel exercise) async {
    try {
      final response = await apiClient.put('api/v1/exercises/$id', data: exercise.toJson());
      final dynamic rawData = response.data['data'] ?? response.data;
      _cachedExercises = null; // Clear cache
      return ExerciseModel.fromJson(rawData as Map<String, dynamic>);
    } on DioException catch (e) {
      throw Exception('Lỗi cập nhật bài tập: ${e.response?.data['message'] ?? e.message}');
    }
  }

  // 2e. Xóa bài tập
  Future<void> deleteExercise(String id) async {
    try {
      await apiClient.delete('api/v1/exercises/$id');
      _cachedExercises = null; // Clear cache
    } on DioException catch (e) {
      throw Exception('Lỗi xóa bài tập: ${e.response?.data['message'] ?? e.message}');
    }
  }

  // 3. Lấy danh sách Nguyên liệu (Ingredients)
  Future<List<FoodModel>> getAllIngredients({String? search, bool forceRefresh = false}) async {
    if (_cachedIngredients != null && !forceRefresh && (search == null || search.isEmpty)) return _cachedIngredients!;

    try {
      final String path = (search != null && search.isNotEmpty) ? 'api/v1/foods/search' : 'api/v1/foods/ingredients';
      final Map<String, dynamic> params = {'size': 100};
      if (search != null && search.isNotEmpty) params['query'] = search;

      final response = await apiClient.get(path, queryParameters: params);
      final dynamic rawData = response.data['data'] ?? response.data;
      
      List<dynamic> content = (rawData is Map) ? (rawData['content'] ?? []) : (rawData as List);
      final ingredients = content.map((json) => FoodModel.fromJson(json as Map<String, dynamic>)).toList();
      if (search == null || search.isEmpty) _cachedIngredients = ingredients;
      return ingredients;
    } on DioException catch (e) {
      throw Exception('Lỗi API Nguyên liệu: ${e.response?.data['message'] ?? e.message}');
    } catch (e) {
      throw Exception('Lỗi xử lý Nguyên liệu: $e');
    }
  }

  // 4. Lấy danh sách Món ăn (Dishes)
  Future<List<FoodModel>> getAllDishes({String? search, bool forceRefresh = false}) async {
    if (_cachedDishes != null && !forceRefresh && (search == null || search.isEmpty)) return _cachedDishes!;

    try {
      final String path = (search != null && search.isNotEmpty) ? 'api/v1/foods/search' : 'api/v1/foods/dishes';
      final Map<String, dynamic> params = {'size': 100};
      if (search != null && search.isNotEmpty) params['query'] = search;

      final response = await apiClient.get(path, queryParameters: params);
      final dynamic rawData = response.data['data'] ?? response.data;
      
      List<dynamic> content = (rawData is Map) ? (rawData['content'] ?? []) : (rawData as List);
      final dishes = content.map((json) => FoodModel.fromJson(json as Map<String, dynamic>)).toList();
      if (search == null || search.isEmpty) _cachedDishes = dishes;
      return dishes;
    } on DioException catch (e) {
      throw Exception('Lỗi API Món ăn: ${e.response?.data['message'] ?? e.message}');
    } catch (e) {
      throw Exception('Lỗi xử lý Món ăn: $e');
    }
  }

  // 5. Lấy chi tiết Thực phẩm (Dùng chung cho Ingredient & Dish)
  Future<FoodModel> getFoodById(String id) async {
    try {
      final response = await apiClient.get('api/v1/foods/$id');
      final dynamic rawData = response.data['data'] ?? response.data;
      return FoodModel.fromJson(rawData as Map<String, dynamic>);
    } on DioException catch (e) {
      throw Exception('Lỗi API Chi tiết thực phẩm: ${e.response?.data['message'] ?? e.message}');
    }
  }

  // 5b. Thêm mới thực phẩm (Dish/Ingredient)
  Future<FoodModel> createFood(FoodModel food) async {
    try {
      final response = await apiClient.post('api/v1/foods', data: food.toJson());
      final dynamic rawData = response.data['data'] ?? response.data;
      _clearFoodCache();
      return FoodModel.fromJson(rawData as Map<String, dynamic>);
    } on DioException catch (e) {
      throw Exception('Lỗi thêm thực phẩm: ${e.response?.data['message'] ?? e.message}');
    }
  }

  // 5c. Cập nhật thực phẩm
  Future<FoodModel> updateFood(String id, FoodModel food) async {
    try {
      final response = await apiClient.put('api/v1/foods/$id', data: food.toJson());
      final dynamic rawData = response.data['data'] ?? response.data;
      _clearFoodCache();
      return FoodModel.fromJson(rawData as Map<String, dynamic>);
    } on DioException catch (e) {
      throw Exception('Lỗi cập nhật thực phẩm: ${e.response?.data['message'] ?? e.message}');
    }
  }

  // 5d. Xóa thực phẩm
  Future<void> deleteFood(String id) async {
    try {
      await apiClient.delete('api/v1/foods/$id');
      _clearFoodCache();
    } on DioException catch (e) {
      throw Exception('Lỗi xóa thực phẩm: ${e.response?.data['message'] ?? e.message}');
    }
  }

  void _clearFoodCache() {
    _cachedIngredients = null;
    _cachedDishes = null;
  }

  void clearCache() {
    _cachedUsers = null;
    _cachedExercises = null;
    _cachedIngredients = null;
    _cachedDishes = null;
  }

  // Lấy Workout Categories
  Future<List<WorkoutCategoryModel>> getAllWorkoutCategories() async {
    try {
      final response = await apiClient.get('api/v1/exercises/categories');
      final List<dynamic> data = response.data is List ? response.data : (response.data['data'] ?? response.data);
      return data.map((e) => WorkoutCategoryModel.fromJson(e)).toList();
    } catch (e) {
      throw Exception('Lỗi API Workout Categories: $e');
    }
  }

  // Lấy Body Parts
  Future<List<BodyPartModel>> getAllBodyParts() async {
    try {
      final response = await apiClient.get('api/v1/exercises/body-parts');
      final List<dynamic> data = response.data is List ? response.data : (response.data['data'] ?? response.data);
      return data.map((e) => BodyPartModel.fromJson(e)).toList();
    } catch (e) {
      throw Exception('Lỗi API Body Parts: $e');
    }
  }

  // Lấy Muscles
  Future<List<MuscleModel>> getAllMuscles() async {
    try {
      final response = await apiClient.get('api/v1/exercises/muscles');
      final List<dynamic> data = response.data is List ? response.data : (response.data['data'] ?? response.data);
      return data.map((e) => MuscleModel.fromJson(e)).toList();
    } catch (e) {
      throw Exception('Lỗi API Muscles: $e');
    }
  }

  // Lấy Food Categories
  Future<List<FoodCategoryModel>> getAllFoodCategories() async {
    try {
      final response = await apiClient.get('api/v1/foods/categories');
      final List<dynamic> data = response.data is List ? response.data : (response.data['data'] ?? response.data);
      return data.map((e) => FoodCategoryModel.fromJson(e)).toList();
    } catch (e) {
      throw Exception('Lỗi API Food Categories: $e');
    }
  }
}

final adminRepository = AdminRepository();
