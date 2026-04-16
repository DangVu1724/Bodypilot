import 'package:flutter_bloc/flutter_bloc.dart';
import 'assessment_state.dart';

class AssessmentCubit extends Cubit<AssessmentState> {
  AssessmentCubit() : super(const AssessmentState());

  void selectGoal(String goal) {
    emit(state.copyWith(selectedGoal: goal));
  }

  void selectGender(String gender) {
    emit(state.copyWith(selectedGender: gender));
  }

  void selectHeight(int height) {
    emit(state.copyWith(selectedHeight: height));
  }

  void selectWeight(int weight) {
    emit(state.copyWith(selectedWeight: weight));
  }

  void selectAge(int age) {
    emit(state.copyWith(selectedAge: age));
  }

  void selectDiet(String diet) {
    emit(state.copyWith(selectedDiet: diet));
  }

  void setExperience(bool value) {
    emit(state.copyWith(hasExperience: value));
  }
}
