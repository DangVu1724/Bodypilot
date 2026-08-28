import 'package:core_shared/models/goal_model.dart';
import 'package:core_shared/models/user_metrics_model.dart';
import 'package:core_shared/models/user_model.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:mobile/data/repositories/user_repository.dart';
import 'package:mobile/data/services/token_service.dart';
import 'user_state.dart';

class UserCubit extends Cubit<UserState> {
  final UserRepository _userRepository;

  UserCubit(this._userRepository) : super(UserInitial());

  Future<bool> fetchUserProfile() async {
    final userId = TokenService.getUserId();
    if (userId == null) {
      emit(const UserError('User not logged in'));
      return false;
    }

    // Load from cache first for instant UI response and offline support
    final cachedUser = TokenService.getCachedUser();
    if (cachedUser != null) {
      emit(UserLoaded(cachedUser));
    } else {
      emit(UserLoading());
    }

    try {
      final user = await _userRepository.getUserDetails(userId);
      await TokenService.saveUserCache(user);
      if (user.profile != null) {
        await TokenService.setAssessmentCompleted(user.profile!.isAssessmentCompleted);
      }
      emit(UserLoaded(user));
      return true;
    } catch (e) {
      // If we don't have cache, emit error
      if (cachedUser == null) {
        emit(UserError(e.toString()));
      }
      return false;
    }
  }

  Future<void> updateWeight(double newWeight) async {
    await updateGoalAndWeight(newWeight: newWeight);
  }

  Future<void> updateGoalAndWeight({double? newWeight, double? newTargetWeight}) async {
    if (state is UserLoaded) {
      final currentUser = (state as UserLoaded).user;
      final currentMetrics = currentUser.metrics;
      final currentWeightVal = newWeight ?? currentMetrics?.weight;
      final height = currentMetrics?.heightCm;

      final updatedMetrics = UserMetricsModel(
        weight: currentWeightVal,
        heightCm: height,
        age: currentMetrics?.age,
        goal: currentMetrics?.goal,
        activityLevel: currentMetrics?.activityLevel,
        bmi: (height != null && height > 0 && currentWeightVal != null)
            ? currentWeightVal / ((height / 100) * (height / 100))
            : currentMetrics?.bmi,
        bmr: currentMetrics?.bmr,
        tdee: currentMetrics?.tdee,
        targetCalories: currentMetrics?.targetCalories,
      );

      final currentGoal = currentUser.goal;
      final updatedGoal = GoalModel(
        type: currentGoal?.type,
        targetWeight: newTargetWeight ?? currentGoal?.targetWeight,
        deadline: currentGoal?.deadline,
        status: currentGoal?.status,
      );

      final updatedUser = UserModel(
        id: currentUser.id,
        email: currentUser.email,
        profile: currentUser.profile,
        metrics: updatedMetrics,
        goal: updatedGoal,
      );

      await TokenService.saveUserCache(updatedUser);
      emit(UserLoaded(updatedUser));
    }
  }

  void clear() {
    emit(UserInitial());
  }
}
