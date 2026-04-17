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

  void selectExercise(String exercise) {
    emit(state.copyWith(selectedExercise: exercise));
  }

  void toggleCondition(String condition) {
    final selectedConditions = List<String>.from(state.selectedConditions);
    if (selectedConditions.contains(condition)) {
      selectedConditions.remove(condition);
    } else {
      selectedConditions.add(condition);
    }
    emit(state.copyWith(selectedConditions: selectedConditions));
  }

  void selectAllergyCategory(String category) {
    if (category == 'Không có') {
      emit(state.copyWith(selectedAllergyCategory: category, selectedAllergies: []));
    } else {
      emit(state.copyWith(selectedAllergyCategory: category));
    }
  }

  void toggleAllergy(String allergy) {
    final selectedAllergies = List<String>.from(state.selectedAllergies);
    if (selectedAllergies.contains(allergy)) {
      selectedAllergies.remove(allergy);
    } else {
      selectedAllergies.add(allergy);
    }
    emit(state.copyWith(selectedAllergies: selectedAllergies));
  }

  void setTargetWeight(int weight) {
    emit(state.copyWith(targetWeight: weight));
  }

  void setSleepQuality(String sleep) {
    emit(state.copyWith(selectedSleep: sleep));
  }

  void setExperience(bool value) {
    emit(state.copyWith(hasExperience: value));
  }
}
