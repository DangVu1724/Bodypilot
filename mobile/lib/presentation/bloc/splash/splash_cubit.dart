import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:mobile/data/services/token_service.dart';
import 'package:mobile/presentation/bloc/user/user_cubit.dart';

enum SplashStatus { loading, authenticated, needsAssessment, unauthenticated, error }

class SplashCubit extends Cubit<SplashStatus> {
  final UserCubit userCubit;
  bool _isStarting = false;

  SplashCubit(this.userCubit) : super(SplashStatus.loading);

  Future<void> startSplash() async {
    if (_isStarting) return;
    _isStarting = true;

    // Minimum splash duration
    final minDuration = Future.delayed(const Duration(seconds: 2));

    try {
      if (!TokenService.hasToken()) {
        await minDuration;
        emit(SplashStatus.unauthenticated);
        return;
      }

      // 1. Check 7 days limit
      if (!TokenService.isSessionValid()) {
        await TokenService.removeToken();
        await minDuration;
        emit(SplashStatus.unauthenticated);
        return;
      }

      // 2. Update last activity
      await TokenService.updateLastActivity();

      // 3. Fetch user profile in background
      await userCubit.fetchUserProfile();

      await minDuration;

      if (TokenService.isAssessmentCompleted()) {
        emit(SplashStatus.authenticated);
      } else {
        emit(SplashStatus.needsAssessment);
      }
    } catch (e) {
      await minDuration;
      if (TokenService.isAssessmentCompleted()) {
        emit(SplashStatus.authenticated);
      } else {
        emit(SplashStatus.needsAssessment);
      }
    } finally {
      _isStarting = false;
    }
  }

  void retry() {
    emit(SplashStatus.loading);
    startSplash();
  }
}
