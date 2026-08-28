import 'package:mobile/core/network/api_client.dart';
import 'package:mobile/data/models/food_smart_swap_model.dart';
import 'package:mobile/data/models/exercise_smart_swap_model.dart';


class SmartSwapRepository {
  Future<List<FoodSmartSwapCandidateModel>> getFoodSwapCandidates({
    required String foodId,
    double currentServingQuantity = 100.0,
  }) async {
    try {
      final response = await apiClient.post(
        '/smart-swap/food',
        data: {
          'foodId': foodId,
          'currentServingQuantity': currentServingQuantity,
        },
      );

      if (response.data['success'] == true && response.data['data'] is List) {
        final List<dynamic> list = response.data['data'];
        return list.map((e) => FoodSmartSwapCandidateModel.fromJson(e as Map<String, dynamic>)).toList();
      }
    } catch (_) {}
    return [];
  }

  Future<List<ExerciseSmartSwapCandidateModel>> getExerciseSwapCandidates({
    required String exerciseId,
  }) async {
    try {
      final response = await apiClient.post(
        '/smart-swap/exercise',
        data: {
          'exerciseId': exerciseId,
        },
      );

      if (response.data['success'] == true && response.data['data'] is List) {
        final List<dynamic> list = response.data['data'];
        return list.map((e) => ExerciseSmartSwapCandidateModel.fromJson(e as Map<String, dynamic>)).toList();
      }
    } catch (_) {}
    return [];
  }
}

final smartSwapRepository = SmartSwapRepository();
