import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:mobile/data/services/token_service.dart';

enum SplashStatus { loading, authenticated, needsAssessment, unauthenticated }

class SplashCubit extends Cubit<SplashStatus> {
  SplashCubit() : super(SplashStatus.loading);

  Future<void> startSplash() async {
    await Future.delayed(const Duration(seconds: 5));
    
    if (TokenService.hasToken()) {
      if (TokenService.isAssessmentCompleted()) {
        emit(SplashStatus.authenticated);
      } else {
        emit(SplashStatus.needsAssessment);
      }
    } else {
      emit(SplashStatus.unauthenticated);
    }
  }
}
