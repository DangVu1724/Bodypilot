import '../../core/network/api_client.dart';
import '../models/exercise_model.dart';
import '../models/paginated_response.dart';
import '../models/workout_category_model.dart';
import 'package:logger/logger.dart';

final _logger = Logger();

class ExerciseRepository {
  Future<PaginatedResponse<ExerciseModel>> searchExercises({
    String? name,
    String? categoryId,
    String? categoryCode,
    String? bodyPartCode,
    String? muscleCode,
    int page = 0,
    int size = 10,
  }) async {
    try {
      final queryParams = <String, dynamic>{
        'page': page,
        'size': size,
      };

      if (name != null) queryParams['name'] = name;
      if (categoryId != null) queryParams['categoryId'] = categoryId;
      if (categoryCode != null) queryParams['categoryCode'] = categoryCode;
      if (bodyPartCode != null) queryParams['bodyPartCode'] = bodyPartCode;
      if (muscleCode != null) queryParams['muscleCode'] = muscleCode;

      _logger.d('Fetching exercises with params: $queryParams');
      final response = await apiClient.get('/exercises', queryParameters: queryParams);
      _logger.d('Fetch exercises response data: ${response.data}');

      return PaginatedResponse<ExerciseModel>.fromJson(
        response.data,
        (json) => ExerciseModel.fromJson(json),
      );
    } catch (e) {
      _logger.e('Error fetching exercises: $e');
      throw Exception('Failed to load exercises: $e');
    }
  }

  Future<List<WorkoutCategoryModel>> getWorkoutCategories() async {
    try {
      final response = await apiClient.get('/exercises/categories');
      final List<dynamic> data = response.data as List<dynamic>;
      return data.map((e) => WorkoutCategoryModel.fromJson(e as Map<String, dynamic>)).toList();
    } catch (e) {
      _logger.e('Error fetching workout categories: $e');
      throw Exception('Failed to load workout categories: $e');
    }
  }
}
