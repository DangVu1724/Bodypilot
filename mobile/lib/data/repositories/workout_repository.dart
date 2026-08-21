import 'package:core_shared/models/exercise_model.dart';
import 'package:core_shared/models/paginated_response.dart';
import 'package:core_shared/models/workout_plan_model.dart';
import 'package:core_shared/models/workout_session_model.dart';
import 'package:dio/dio.dart';
import 'package:logger/logger.dart';
import 'package:mobile/data/local/sqlite/workout_database_helper.dart';

import '../../core/network/api_client.dart';

final _logger = Logger();

class WorkoutRepository {
  final Map<String, List<WorkoutPlanModel>> _plansCache = {};
  bool _isExerciseSyncing = false;

  Future<List<WorkoutPlanModel>> getAllPlans({String? goal, bool forceRefresh = false}) async {
    final cacheKey = goal ?? 'ALL';
    if (!forceRefresh && _plansCache.containsKey(cacheKey)) {
      _logger.d('Serving workout plans ($cacheKey) from RAM cache');
      return _plansCache[cacheKey]!;
    }

    // Local-First SQLite Check
    if (!forceRefresh) {
      try {
        final localPlans = await WorkoutDatabaseHelper.instance.getPlansOffline(goal: goal);
        if (localPlans.isNotEmpty) {
          _logger.i('⚡ [Local-First] Served ${localPlans.length} workout plans from SQLite.');
          _plansCache[cacheKey] = localPlans;
          _refreshPlansInBackground(goal: goal);
          return localPlans;
        }
      } catch (dbError) {
        _logger.e('Failed to load local plans: $dbError');
      }
    }

    try {
      final queryParams = <String, dynamic>{};
      if (goal != null) queryParams['goal'] = goal;

      final response = await apiClient.get('/workout-plans', queryParameters: queryParams);
      final List<dynamic> data = response.data as List<dynamic>;
      final plans = data.map((e) => WorkoutPlanModel.fromJson(e as Map<String, dynamic>)).toList();

      _plansCache[cacheKey] = plans;

      try {
        await WorkoutDatabaseHelper.instance.insertPlans(plans);
      } catch (dbError) {
        _logger.e('Failed to cache workout plans in SQLite: $dbError');
      }

      return plans;
    } on DioException catch (e) {
      _logger.e('Error fetching workout plans: $e');
      throw Exception('Failed to load workout plans: $e');
    }
  }

  void _refreshPlansInBackground({String? goal}) async {
    try {
      final queryParams = <String, dynamic>{};
      if (goal != null) queryParams['goal'] = goal;
      final response = await apiClient.get('/workout-plans', queryParameters: queryParams);
      final List<dynamic> data = response.data as List<dynamic>;
      final plans = data.map((e) => WorkoutPlanModel.fromJson(e as Map<String, dynamic>)).toList();
      await WorkoutDatabaseHelper.instance.insertPlans(plans);
    } catch (_) {}
  }

  Future<List<WorkoutPlanModel>> getAllPlansFull({bool forceRefresh = false}) async {
    if (!forceRefresh) {
      try {
        final localPlans = await WorkoutDatabaseHelper.instance.getPlansOffline();
        if (localPlans.isNotEmpty) {
          _logger.i('⚡ [Local-First] Served ${localPlans.length} full workout plans from SQLite.');
          _refreshFullPlansInBackground();
          return localPlans;
        }
      } catch (dbError) {
        _logger.e('Failed to load local full plans: $dbError');
      }
    }

    try {
      final response = await apiClient.get('/workout-plans/full');
      final List<dynamic> data = response.data as List<dynamic>;
      final plans = data.map((e) => WorkoutPlanModel.fromJson(e as Map<String, dynamic>)).toList();

      try {
        await WorkoutDatabaseHelper.instance.insertPlans(plans);
      } catch (dbError) {
        _logger.e('Failed to cache full workout plans in SQLite: $dbError');
      }

      return plans;
    } on DioException catch (e) {
      _logger.e('Error fetching full workout plans: $e');
      throw Exception('Failed to load full workout plans: $e');
    }
  }

  void _refreshFullPlansInBackground() async {
    try {
      final response = await apiClient.get('/workout-plans/full');
      final List<dynamic> data = response.data as List<dynamic>;
      final plans = data.map((e) => WorkoutPlanModel.fromJson(e as Map<String, dynamic>)).toList();
      await WorkoutDatabaseHelper.instance.insertPlans(plans);
    } catch (_) {}
  }

  Future<WorkoutPlanModel> getPlanById(String id) async {
    try {
      final response = await apiClient.get('/workout-plans/$id');
      return WorkoutPlanModel.fromJson(response.data as Map<String, dynamic>);
    } catch (e) {
      _logger.e('Error fetching workout plan by id: $e');
      throw Exception('Failed to load workout plan: $e');
    }
  }

  Future<List<WorkoutSessionModel>> getSessionsByPlanId(String planId) async {
    try {
      final response = await apiClient.get('/workout-sessions/plan/$planId');
      final List<dynamic> data = response.data as List<dynamic>;
      return data.map((e) => WorkoutSessionModel.fromJson(e as Map<String, dynamic>)).toList();
    } catch (e) {
      _logger.e('Error fetching workout sessions: $e');
      throw Exception('Failed to load workout sessions: $e');
    }
  }

  Future<WorkoutSessionModel> getSessionById(String id) async {
    try {
      final response = await apiClient.get('/workout-sessions/$id');
      return WorkoutSessionModel.fromJson(response.data as Map<String, dynamic>);
    } catch (e) {
      _logger.e('Error fetching workout session by id: $e');
      throw Exception('Failed to load workout session: $e');
    }
  }

  bool _isExerciseSyncCompleted = false;

  // 🏋️ Local-First Exercise Search & Batched Background Sync
  Future<PaginatedResponse<ExerciseModel>> searchExercises(
    String query, {
    String? bodyPartId,
    String? categoryId,
    String? difficulty,
    int page = 0,
    int size = 20,
    bool forceRefresh = false,
  }) async {
    final trimmedQuery = query.trim();

    // 0. Sanitize Query: If query contains ONLY special characters (!@#$%^&*...), return 0 items immediately
    if (trimmedQuery.isNotEmpty &&
        RegExp(
          r'^[^a-zA-Z0-9àáâãèéêìíòóôõùúăđĩũơưăạảấầẩẫậắằẳẵặẹẻẽềềểễệỉịọỏốồổỗộớờởỡợụủứừửữựỳỵỷỹ\s]+$',
        ).hasMatch(trimmedQuery)) {
      _logger.d(
        '🚫 [SanitizeQuery] Exercise query "$query" contains only special characters. Returning 0 results instantly.',
      );
      return PaginatedResponse<ExerciseModel>(
        content: [],
        pageNumber: page,
        pageSize: size,
        totalElements: 0,
        totalPages: 0,
        last: true,
      );
    }

    if (!forceRefresh) {
      try {
        final localExercises = await WorkoutDatabaseHelper.instance.searchExercisesOffline(
          trimmedQuery,
          bodyPartId: bodyPartId,
          categoryId: categoryId,
          difficulty: difficulty,
          limit: size,
          offset: page * size,
        );

        if (localExercises.isNotEmpty) {
          _logger.i('⚡ [Local-First] Serving ${localExercises.length} exercises from SQLite for query "$trimmedQuery"');

          _revalidateExercisesInBackground(
            query: trimmedQuery,
            bodyPartId: bodyPartId,
            categoryId: categoryId,
            difficulty: difficulty,
            page: page,
            size: size,
          );

          return PaginatedResponse<ExerciseModel>(
            content: localExercises,
            pageNumber: page,
            pageSize: size,
            totalElements: localExercises.length,
            totalPages: 1,
            last: true,
          );
        }

        // If SQLite returned 0 items AND full background sync is completed, NO need to hit backend!
        if (_isExerciseSyncCompleted) {
          _logger.i(
            'ℹ️ [FullSyncCompleted] Exercise query "$trimmedQuery" not found in SQLite. Returning 0 results without hitting backend.',
          );
          return PaginatedResponse<ExerciseModel>(
            content: [],
            pageNumber: page,
            pageSize: size,
            totalElements: 0,
            totalPages: 0,
            last: true,
          );
        }
      } catch (dbError) {
        _logger.e('Failed local exercises read: $dbError');
      }
    }

    try {
      final queryParams = <String, dynamic>{'query': query, 'page': page, 'size': size};
      if (bodyPartId != null) queryParams['bodyPartId'] = bodyPartId;
      if (categoryId != null) queryParams['categoryId'] = categoryId;
      if (difficulty != null) queryParams['difficulty'] = difficulty;

      final response = await apiClient.get('/exercises/search', queryParameters: queryParams);

      final paginated = PaginatedResponse<ExerciseModel>.fromJson(
        response.data['data'] as Map<String, dynamic>,
        (json) => ExerciseModel.fromJson(json),
      );

      try {
        await WorkoutDatabaseHelper.instance.insertExercises(paginated.content);
      } catch (dbError) {
        _logger.e('Failed to cache exercises in SQLite: $dbError');
      }

      return paginated;
    } on DioException catch (e) {
      _logger.e('Error searching exercises: $e');
      throw Exception('Failed to search exercises: $e');
    }
  }

  void _revalidateExercisesInBackground({
    required String query,
    String? bodyPartId,
    String? categoryId,
    String? difficulty,
    required int page,
    required int size,
  }) async {
    try {
      final queryParams = <String, dynamic>{'query': query, 'page': page, 'size': size};
      if (bodyPartId != null) queryParams['bodyPartId'] = bodyPartId;
      if (categoryId != null) queryParams['categoryId'] = categoryId;
      if (difficulty != null) queryParams['difficulty'] = difficulty;

      final response = await apiClient.get('/exercises/search', queryParameters: queryParams);
      final paginated = PaginatedResponse<ExerciseModel>.fromJson(
        response.data['data'] as Map<String, dynamic>,
        (json) => ExerciseModel.fromJson(json),
      );
      await WorkoutDatabaseHelper.instance.insertExercises(paginated.content);
      _logger.d('🔄 [Background Revalidate] Refreshed ${paginated.content.length} exercises in SQLite');
    } catch (_) {}
  }

  /// Batched Background Sync for Exercises (Chunks of 100)
  Future<void> startBatchedExerciseSync({int batchSize = 100, int maxBatches = 10}) async {
    if (_isExerciseSyncing) {
      _logger.d('⏳ [BatchedExerciseSync] Sync already in progress, skipping...');
      return;
    }
    _isExerciseSyncing = true;
    _logger.i('🚀 [BatchedExerciseSync] Starting batched exercise sync (batchSize=$batchSize)...');

    try {
      for (int page = 0; page < maxBatches; page++) {
        final response = await apiClient.get(
          '/exercises/search',
          queryParameters: {'query': '', 'page': page, 'size': batchSize},
        );

        final paginated = PaginatedResponse<ExerciseModel>.fromJson(
          response.data['data'] as Map<String, dynamic>,
          (json) => ExerciseModel.fromJson(json),
        );

        if (paginated.content.isEmpty) break;

        await WorkoutDatabaseHelper.instance.insertExercises(paginated.content);
        _logger.d(
          '📦 [BatchedExerciseSync] Batch ${page + 1}/$maxBatches inserted (${paginated.content.length} exercises)',
        );

        if (paginated.last) break;

        // 100ms pause to give main UI thread processing room
        await Future.delayed(const Duration(milliseconds: 100));
      }
      _isExerciseSyncCompleted = true;
      _logger.i('✅ [BatchedExerciseSync] Exercise sync completed successfully.');
    } catch (e) {
      _logger.e('Error during batched exercise sync: $e');
    } finally {
      _isExerciseSyncing = false;
    }
  }
}

final workoutRepository = WorkoutRepository();
