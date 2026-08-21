import 'dart:convert';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:intl/intl.dart';
import 'package:core_shared/models/daily_workout_model.dart';
import '../../../data/repositories/user_repository.dart';
import '../../../data/services/token_service.dart';
import 'ai_workout_state.dart';

class AiWorkoutCubit extends Cubit<AiWorkoutState> {
  final UserRepository _userRepository;

  AiWorkoutCubit({UserRepository? userRepository})
      : _userRepository = userRepository ?? UserRepository(),
        super(AiWorkoutInitial());

  Future<void> fetchAiWorkoutSuggestion({
    required int days,
    required bool startTomorrow,
    String? focusBodyPart,
  }) async {
    if (!isClosed) emit(AiWorkoutLoading());
    try {
      final userId = TokenService.getUserId();
      if (userId == null) {
        throw Exception("Không tìm thấy thông tin tài khoản người dùng.");
      }
      final startDateStr = DateFormat('yyyy-MM-dd').format(
        startTomorrow ? DateTime.now().add(const Duration(days: 1)) : DateTime.now(),
      );
      final jsonString = await _userRepository.getAiWorkoutSuggestion(
        userId,
        days: days,
        focusBodyPart: focusBodyPart,
        startDate: startDateStr,
      );
      final List<dynamic> decoded = jsonDecode(jsonString) as List<dynamic>;
      final suggestions = decoded
          .map((e) => DailyWorkoutModel.fromJson(e as Map<String, dynamic>))
          .toList();

      final bool isFallback = suggestions.any((e) => !e.isAiGenerated);

      if (!isClosed) {
        emit(AiWorkoutSuccess(
          suggestions: suggestions,
          isFallback: isFallback,
        ));
      }
    } catch (e) {
      if (!isClosed) {
        final errMsg = e.toString().replaceAll("Exception: ", "");
        emit(AiWorkoutError(errMsg));
      }
    }
  }

  void reset() {
    emit(AiWorkoutInitial());
  }
}
