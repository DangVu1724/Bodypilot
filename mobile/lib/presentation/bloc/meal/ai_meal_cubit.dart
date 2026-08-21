import 'dart:convert';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:intl/intl.dart';
import 'package:core_shared/models/daily_eating_model.dart';
import '../../../data/repositories/user_repository.dart';
import '../../../data/services/token_service.dart';
import 'ai_meal_state.dart';

class AiMealCubit extends Cubit<AiMealState> {
  final UserRepository _userRepository;

  AiMealCubit({UserRepository? userRepository})
      : _userRepository = userRepository ?? UserRepository(),
        super(AiMealInitial());

  Future<void> fetchAiMealSuggestion({
    required int days,
    required bool startTomorrow,
  }) async {
    if (!isClosed) emit(AiMealLoading());
    try {
      final userId = TokenService.getUserId();
      if (userId == null) {
        throw Exception("Không tìm thấy thông tin tài khoản người dùng.");
      }
      final startDateStr = DateFormat('yyyy-MM-dd').format(
        startTomorrow ? DateTime.now().add(const Duration(days: 1)) : DateTime.now(),
      );
      final jsonString = await _userRepository.getAiDietSuggestion(
        userId,
        days: days,
        startDate: startDateStr,
      );
      final List<dynamic> decoded = jsonDecode(jsonString) as List<dynamic>;
      final suggestions = decoded
          .map((e) => DailyEatingModel.fromJson(e as Map<String, dynamic>))
          .toList();

      final bool isFallback = suggestions.any((e) => !e.isAiGenerated);

      if (!isClosed) {
        emit(AiMealSuccess(
          suggestions: suggestions,
          isFallback: isFallback,
          isRegenerated: false,
        ));
      }
    } catch (e) {
      if (!isClosed) {
        final errMsg = e.toString().replaceAll("Exception: ", "");
        emit(AiMealError(errMsg));
      }
    }
  }

  Future<void> regenerateWithFeedback({
    required int days,
    required bool startTomorrow,
    required String userFeedback,
  }) async {
    if (!isClosed) emit(AiMealRegenerating(userFeedback));
    try {
      final userId = TokenService.getUserId();
      if (userId == null) {
        throw Exception("Không tìm thấy thông tin tài khoản người dùng.");
      }
      final startDateStr = DateFormat('yyyy-MM-dd').format(
        startTomorrow ? DateTime.now().add(const Duration(days: 1)) : DateTime.now(),
      );
      final jsonString = await _userRepository.getAiDietSuggestion(
        userId,
        days: days,
        startDate: startDateStr,
        userFeedback: userFeedback,
      );
      final List<dynamic> decoded = jsonDecode(jsonString) as List<dynamic>;
      final suggestions = decoded
          .map((e) => DailyEatingModel.fromJson(e as Map<String, dynamic>))
          .toList();

      final bool isFallback = suggestions.any((e) => !e.isAiGenerated);

      if (!isClosed) {
        emit(AiMealSuccess(
          suggestions: suggestions,
          isFallback: isFallback,
          isRegenerated: true,
        ));
      }
    } catch (e) {
      if (!isClosed) {
        final errMsg = e.toString().replaceAll("Exception: ", "");
        emit(AiMealError(errMsg));
      }
    }
  }

  void reset() {
    emit(AiMealInitial());
  }
}
