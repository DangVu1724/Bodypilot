import 'package:core_shared/models/exercise_model.dart';
import 'package:core_shared/models/paginated_response.dart';
import 'package:core_shared/models/workout_category_model.dart';
import 'package:logger/logger.dart';
import 'package:mobile/data/local/sqlite/workout_database_helper.dart';
import '../../core/network/api_client.dart';

final _logger = Logger();

class ExerciseRepository {
  List<WorkoutCategoryModel>? _cachedCategories;
  final Map<String, PaginatedResponse<ExerciseModel>> _categoryCache = {};

  /// Tìm kiếm bài tập (Ưu tiên SQLite local -> Backend API)
  Future<PaginatedResponse<ExerciseModel>> searchExercises({
    String? name,
    String? categoryId,
    String? categoryCode,
    String? bodyPartCode,
    String? muscleCode,
    int page = 0,
    int size = 50,
    bool forceRefresh = false,
  }) async {
    final trimmedName = name?.trim() ?? '';

    // 1. Kiểm tra bộ nhớ RAM Cache
    if (page == 0 && categoryId != null && !forceRefresh && trimmedName.isEmpty && bodyPartCode == null && muscleCode == null) {
      if (_categoryCache.containsKey(categoryId)) {
        return _categoryCache[categoryId]!;
      }
    }

    // 2. Tìm kiếm trong SQLite cục bộ (Local-First)
    if (!forceRefresh && categoryCode == null && muscleCode == null && bodyPartCode == null) {
      try {
        final localExercises = await WorkoutDatabaseHelper.instance.searchExercisesOffline(
          trimmedName,
          categoryId: categoryId,
          limit: size < 50 ? 50 : size,
          offset: page * size,
        );

        if (localExercises.isNotEmpty) {
          // Đồng bộ ngầm dữ liệu mới từ Backend
          _revalidateExercisesInBackground(
            name: name,
            categoryId: categoryId,
            categoryCode: categoryCode,
            bodyPartCode: bodyPartCode,
            muscleCode: muscleCode,
            page: page,
            size: size,
          );

          return PaginatedResponse<ExerciseModel>(
            content: localExercises,
            pageNumber: page,
            pageSize: size,
            totalElements: localExercises.length,
            totalPages: 1,
            last: localExercises.length < size,
          );
        }
      } catch (dbError) {
        _logger.e('Lỗi đọc dữ liệu SQLite: $dbError');
      }
    }

    // 3. Gọi Backend API khi chưa có dữ liệu local
    try {
      final queryParams = <String, dynamic>{'page': page, 'size': size};

      if (name != null && name.isNotEmpty) queryParams['name'] = name;
      if (categoryId != null && categoryId.isNotEmpty) queryParams['categoryId'] = categoryId;
      if (categoryCode != null && categoryCode.isNotEmpty) queryParams['categoryCode'] = categoryCode;
      if (bodyPartCode != null && bodyPartCode.isNotEmpty) queryParams['bodyPartCode'] = bodyPartCode;
      if (muscleCode != null && muscleCode.isNotEmpty) queryParams['muscleCode'] = muscleCode;

      final response = await apiClient.get('/exercises', queryParameters: queryParams);

      final paginated = PaginatedResponse<ExerciseModel>.fromJson(
        response.data as Map<String, dynamic>,
        (json) => ExerciseModel.fromJson(json as Map<String, dynamic>),
      );

      if (page == 0 && categoryId != null && trimmedName.isEmpty && bodyPartCode == null && muscleCode == null) {
        if (_categoryCache.length > 20) {
          _categoryCache.remove(_categoryCache.keys.first);
        }
        _categoryCache[categoryId] = paginated;
      }

      // Lưu kết quả vào SQLite
      try {
        await WorkoutDatabaseHelper.instance.insertExercises(paginated.content);
      } catch (dbError) {
        _logger.e('Lỗi lưu bài tập vào SQLite: $dbError');
      }

      return paginated;
    } catch (e) {
      _logger.e('Lỗi kết nối máy chủ: $e');
      throw Exception('Failed to load exercises: $e');
    }
  }

  /// Cập nhật dữ liệu ngầm từ Backend vào SQLite
  void _revalidateExercisesInBackground({
    String? name,
    String? categoryId,
    String? categoryCode,
    String? bodyPartCode,
    String? muscleCode,
    required int page,
    required int size,
  }) async {
    try {
      final queryParams = <String, dynamic>{'page': page, 'size': size};
      if (name != null && name.isNotEmpty) queryParams['name'] = name;
      if (categoryId != null && categoryId.isNotEmpty) queryParams['categoryId'] = categoryId;
      if (categoryCode != null && categoryCode.isNotEmpty) queryParams['categoryCode'] = categoryCode;
      if (bodyPartCode != null && bodyPartCode.isNotEmpty) queryParams['bodyPartCode'] = bodyPartCode;
      if (muscleCode != null && muscleCode.isNotEmpty) queryParams['muscleCode'] = muscleCode;

      final response = await apiClient.get('/exercises', queryParameters: queryParams);
      final paginated = PaginatedResponse<ExerciseModel>.fromJson(
        response.data as Map<String, dynamic>,
        (json) => ExerciseModel.fromJson(json as Map<String, dynamic>),
      );
      await WorkoutDatabaseHelper.instance.insertExercises(paginated.content);
    } catch (_) {}
  }

  Future<void> prefetchPopularCategories() async {
    try {
      final categories = await getWorkoutCategories();
      for (final cat in categories.take(4)) {
        if (!_categoryCache.containsKey(cat.id)) {
          searchExercises(categoryId: cat.id, page: 0, size: 20);
        }
      }
    } catch (_) {}
  }

  void clearCache() {
    _categoryCache.clear();
  }

  Future<List<WorkoutCategoryModel>> getWorkoutCategories() async {
    if (_cachedCategories != null && _cachedCategories!.isNotEmpty) {
      return _cachedCategories!;
    }
    try {
      final response = await apiClient.get('/exercises/categories');
      final List<dynamic> data = response.data as List<dynamic>;
      _cachedCategories = data.map((e) => WorkoutCategoryModel.fromJson(e as Map<String, dynamic>)).toList();
      return _cachedCategories!;
    } catch (e) {
      _logger.e('Lỗi tải danh mục bài tập: $e');
      throw Exception('Failed to load workout categories: $e');
    }
  }
}

final exerciseRepository = ExerciseRepository();
