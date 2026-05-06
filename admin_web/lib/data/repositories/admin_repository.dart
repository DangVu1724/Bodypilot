import 'package:core_shared/core_shared.dart';
import 'package:dio/dio.dart';
import '../../core/network/api_client.dart';

class AdminRepository {
  List<UserModel>? _cachedUsers;
  List<ExerciseModel>? _cachedExercises;
  List<FoodModel>? _cachedIngredients;
  List<FoodModel>? _cachedDishes;

  // 1. Lấy danh sách người dùng (Full)
  Future<List<UserModel>> getAllUsers({bool forceRefresh = false}) async {
    if (_cachedUsers != null && !forceRefresh) return _cachedUsers!;
    
    try {
      final response = await apiClient.get('api/v1/users');
      final dynamic rawData = response.data['data'] ?? response.data;

      if (rawData is List) {
        _cachedUsers = rawData.map((json) => UserModel.fromJson(json as Map<String, dynamic>)).toList();
        return _cachedUsers!;
      }
      return [];
    } on DioException catch (e) {
      throw Exception('Lỗi API Người dùng: ${e.response?.data['message'] ?? e.message}');
    } catch (e) {
      throw Exception('Lỗi xử lý dữ liệu Người dùng: $e');
    }
  }

  // 2. Lấy danh sách bài tập
  Future<List<ExerciseModel>> getAllExercises({bool forceRefresh = false}) async {
    if (_cachedExercises != null && !forceRefresh) return _cachedExercises!;

    try {
      final response = await apiClient.get('api/v1/exercises', queryParameters: {'size': 100});
      final dynamic rawData = response.data['data'] ?? response.data;
      
      List<dynamic> content = (rawData is Map) ? (rawData['content'] ?? []) : (rawData as List);
      _cachedExercises = content.map((json) => ExerciseModel.fromJson(json as Map<String, dynamic>)).toList();
      return _cachedExercises!;
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
  Future<List<FoodModel>> getAllIngredients({bool forceRefresh = false}) async {
    if (_cachedIngredients != null && !forceRefresh) return _cachedIngredients!;

    try {
      final response = await apiClient.get('api/v1/foods/ingredients', queryParameters: {'size': 100});
      final dynamic rawData = response.data['data'] ?? response.data;
      
      List<dynamic> content = (rawData is Map) ? (rawData['content'] ?? []) : (rawData as List);
      _cachedIngredients = content.map((json) => FoodModel.fromJson(json as Map<String, dynamic>)).toList();
      return _cachedIngredients!;
    } on DioException catch (e) {
      throw Exception('Lỗi API Nguyên liệu: ${e.response?.data['message'] ?? e.message}');
    } catch (e) {
      throw Exception('Lỗi xử lý Nguyên liệu: $e');
    }
  }

  // 4. Lấy danh sách Món ăn (Dishes)
  Future<List<FoodModel>> getAllDishes({bool forceRefresh = false}) async {
    if (_cachedDishes != null && !forceRefresh) return _cachedDishes!;

    try {
      final response = await apiClient.get('api/v1/foods/dishes', queryParameters: {'size': 100});
      final dynamic rawData = response.data['data'] ?? response.data;
      
      List<dynamic> content = (rawData is Map) ? (rawData['content'] ?? []) : (rawData as List);
      _cachedDishes = content.map((json) => FoodModel.fromJson(json as Map<String, dynamic>)).toList();
      return _cachedDishes!;
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
