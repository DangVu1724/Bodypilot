import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:mobile/data/repositories/user_repository.dart';
import 'package:mobile/data/services/token_service.dart';
import 'package:core_shared/models/user_model.dart';
import 'package:core_shared/models/user_metrics_model.dart';
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
    if (state is UserLoaded) {
      final currentUser = (state as UserLoaded).user;
      
      final updatedMetrics = UserMetricsModel(
        weight: newWeight,
        heightCm: currentUser.metrics?.heightCm,
        age: currentUser.metrics?.age,
        goal: currentUser.metrics?.goal,
        activityLevel: currentUser.metrics?.activityLevel,
        bmi: currentUser.metrics?.heightCm != null && currentUser.metrics!.heightCm! > 0
            ? newWeight / ((currentUser.metrics!.heightCm! / 100) * (currentUser.metrics!.heightCm! / 100))
            : currentUser.metrics?.bmi,
        bmr: currentUser.metrics?.bmr,
        tdee: currentUser.metrics?.tdee,
        targetCalories: currentUser.metrics?.targetCalories,
      );

      final updatedUser = UserModel(
        id: currentUser.id,
        email: currentUser.email,
        profile: currentUser.profile,
        metrics: updatedMetrics,
        goal: currentUser.goal,
      );

      await TokenService.saveUserCache(updatedUser);
      emit(UserLoaded(updatedUser));
    }
  }

  void clear() {
    emit(UserInitial());
  }
}
