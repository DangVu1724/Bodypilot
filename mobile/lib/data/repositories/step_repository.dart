import 'package:intl/intl.dart';
import 'package:mobile/core/network/api_client.dart';

class StepHistoryModel {
  final String? id;
  final DateTime date;
  final int stepCount;
  final double caloriesBurned;
  final double distanceKm;

  StepHistoryModel({
    this.id,
    required this.date,
    required this.stepCount,
    required this.caloriesBurned,
    required this.distanceKm,
  });

  factory StepHistoryModel.fromJson(Map<String, dynamic> json) {
    return StepHistoryModel(
      id: json['id'] as String?,
      date: json['date'] != null ? DateTime.parse(json['date'] as String) : DateTime.now(),
      stepCount: (json['stepCount'] as num?)?.toInt() ?? 0,
      caloriesBurned: (json['caloriesBurned'] as num?)?.toDouble() ?? 0.0,
      distanceKm: (json['distanceKm'] as num?)?.toDouble() ?? 0.0,
    );
  }
}

class StepRepository {
  Future<StepHistoryModel?> syncTodaySteps({
    required String userId,
    required int stepCount,
    required double caloriesBurned,
    required double distanceKm,
    DateTime? date,
  }) async {
    try {
      final syncDate = DateFormat('yyyy-MM-dd').format(date ?? DateTime.now());
      final response = await apiClient.post(
        '/users/$userId/steps/sync',
        data: {
          'date': syncDate,
          'stepCount': stepCount,
          'caloriesBurned': caloriesBurned,
          'distanceKm': distanceKm,
        },
      );

      if (response.data['success'] == true && response.data['data'] != null) {
        return StepHistoryModel.fromJson(response.data['data']);
      }
    } catch (e) {
      print('🚨 [StepRepository.syncTodaySteps error]: $e');
    }
    return null;
  }

  Future<List<StepHistoryModel>> getStepHistory(
    String userId, {
    DateTime? startDate,
    DateTime? endDate,
  }) async {
    try {
      final queryParams = <String, dynamic>{};
      if (startDate != null) {
        queryParams['startDate'] = DateFormat('yyyy-MM-dd').format(startDate);
      }
      if (endDate != null) {
        queryParams['endDate'] = DateFormat('yyyy-MM-dd').format(endDate);
      }

      final response = await apiClient.get(
        '/users/$userId/steps/history',
        queryParameters: queryParams.isNotEmpty ? queryParams : null,
      );

      if (response.data['success'] == true && response.data['data'] is List) {
        final List<dynamic> list = response.data['data'];
        return list.map((e) => StepHistoryModel.fromJson(e as Map<String, dynamic>)).toList();
      }
    } catch (e) {
      print('🚨 [StepRepository.getStepHistory error]: $e');
    }
    return [];
  }
}

final stepRepository = StepRepository();
