import 'package:core_shared/models/exercise_model.dart';
import 'package:core_shared/models/paginated_response.dart';
import 'package:core_shared/models/workout_category_model.dart';
import '../../core/network/api_client.dart';
import 'package:logger/logger.dart';

final _logger = Logger();

class ExerciseRepository {
  List<WorkoutCategoryModel>? _cachedCategories;
  final Map<String, PaginatedResponse<ExerciseModel>> _categoryCache = {};

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
    if (page == 0 && categoryId != null && !forceRefresh && name == null && bodyPartCode == null && muscleCode == null) {
      if (_categoryCache.containsKey(categoryId)) {
        _logger.d('Serving exercise category $categoryId from RAM cache');
        return _categoryCache[categoryId]!;
      }
    }

    try {
      final queryParams = <String, dynamic>{'page': page, 'size': size};

      if (name != null) queryParams['name'] = name;
      if (categoryId != null) queryParams['categoryId'] = categoryId;
      if (categoryCode != null) queryParams['categoryCode'] = categoryCode;
      if (bodyPartCode != null) queryParams['bodyPartCode'] = bodyPartCode;
      if (muscleCode != null) queryParams['muscleCode'] = muscleCode;

      _logger.d('Fetching exercises with params: $queryParams');
      final response = await apiClient.get('/exercises', queryParameters: queryParams);
      _logger.d('Fetch exercises response data: ${response.data}');

      final paginated = PaginatedResponse<ExerciseModel>.fromJson(response.data, (json) => ExerciseModel.fromJson(json));

      if (page == 0 && categoryId != null && name == null && bodyPartCode == null && muscleCode == null) {
        if (_categoryCache.length > 20) {
          _categoryCache.remove(_categoryCache.keys.first);
        }
        _categoryCache[categoryId] = paginated;
      }

      return paginated;
    } catch (e) {
      _logger.e('Error fetching exercises: $e');
      throw Exception('Failed to load exercises: $e');
    }
  }

  Future<void> prefetchPopularCategories() async {
    try {
      final categories = await getWorkoutCategories();
      for (final cat in categories.take(4)) {
        if (!_categoryCache.containsKey(cat.id)) {
          searchExercises(categoryId: cat.id, page: 0, size: 20);
        }
      }
    } catch (e) {
      _logger.w('Prefetch categories failed: $e');
    }
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
      _logger.e('Error fetching workout categories: $e');
      throw Exception('Failed to load workout categories: $e');
    }
  }
}

final exerciseRepository = ExerciseRepository();
