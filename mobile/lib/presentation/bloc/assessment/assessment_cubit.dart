import 'package:flutter/foundation.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:hive_flutter/hive_flutter.dart';
import 'package:mobile/data/repositories/user_repository.dart';
import 'package:mobile/data/services/token_service.dart';
import 'assessment_state.dart';

class AssessmentCubit extends Cubit<AssessmentState> {
  final Box _box = Hive.box('assessment_box');

  AssessmentCubit() : super(const AssessmentState()) {
    _loadFromHive();
    fetchOptions();
  }

  Future<void> fetchOptions() async {
    try {
      final conditions = await userRepository.getHealthConditions();
      final injuries = await userRepository.getInjuries();
      final allergies = await userRepository.getAllergies();
      final dietTags = await userRepository.getDietTags();
      emit(state.copyWith(
        availableConditions: conditions,
        availableInjuries: injuries,
        availableAllergies: allergies,
        availableDietTags: dietTags,
      ));
    } catch (e) {
      if (kDebugMode) {
        print('Error fetching options: $e');
      }
    }
  }

  void _loadFromHive() {
    final cachedData = _box.get('current_assessment');
    if (cachedData != null) {
      try {
        final Map<String, dynamic> json = Map<String, dynamic>.from(cachedData);
        emit(AssessmentState.fromJson(json));
      } catch (e) {
        if (kDebugMode) {
          print('Error loading from Hive: $e');
        }
      }
    }
  }

  @override
  void emit(AssessmentState state) {
    super.emit(state);
    // Only persist if we're not in a success or loading state to prevent auto-redirection on reload
    if (state.status != AssessmentStatus.success && state.status != AssessmentStatus.loading) {
      _box.put('current_assessment', state.toJson());
    }
  }

  Future<void> submitAssessment() async {
    final userId = TokenService.getUserId();
    if (userId == null) return;

    emit(state.copyWith(status: AssessmentStatus.loading));

    try {
      await userRepository.submitAssessment(userId, state.toJson());
      await _box.delete('current_assessment');
      emit(state.copyWith(status: AssessmentStatus.success));
    } catch (e) {
      emit(state.copyWith(status: AssessmentStatus.failure));
    }
  }

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

  void toggleCondition(String condition) {
    final selectedConditions = List<String>.from(state.selectedConditions);
    if (selectedConditions.contains(condition)) {
      selectedConditions.remove(condition);
    } else {
      selectedConditions.add(condition);
    }
    emit(state.copyWith(selectedConditions: selectedConditions));
  }

  void toggleInjury(String injury) {
    final selectedInjuries = List<String>.from(state.selectedInjuries);
    if (selectedInjuries.contains(injury)) {
      selectedInjuries.remove(injury);
    } else {
      selectedInjuries.add(injury);
    }
    emit(state.copyWith(selectedInjuries: selectedInjuries));
  }

  void toggleAllergy(String allergy) {
    List<String> selectedAllergies = List<String>.from(state.selectedAllergies);
    if (allergy == 'NONE') {
      if (selectedAllergies.contains('NONE')) {
        selectedAllergies.remove('NONE');
      } else {
        selectedAllergies = ['NONE'];
      }
    } else {
      selectedAllergies.remove('NONE');
      if (selectedAllergies.contains(allergy)) {
        selectedAllergies.remove(allergy);
      } else {
        selectedAllergies.add(allergy);
      }
    }
    emit(state.copyWith(selectedAllergies: selectedAllergies));
  }

  void setAllergyNote(String note) {
    emit(state.copyWith(allergyNote: note));
  }

  void setTargetWeight(int weight) {
    emit(state.copyWith(targetWeight: weight));
  }

  void setExperience(bool value) {
    emit(state.copyWith(hasExperience: value));
  }

  void selectActivityLevel(String level) {
    emit(state.copyWith(selectedActivityLevel: level));
  }

  void selectDietTag(String? dietTagId) {
    emit(state.copyWith(selectedDietTagId: dietTagId));
  }

  void toggleDislikedFoodGroup(String group) {
    List<String> disliked = List<String>.from(state.dislikedFoodGroups);
    if (group == 'NONE') {
      if (disliked.contains('NONE')) {
        disliked.remove('NONE');
      } else {
        disliked = ['NONE'];
      }
    } else {
      disliked.remove('NONE');
      if (disliked.contains(group)) {
        disliked.remove(group);
      } else {
        disliked.add(group);
      }
    }
    emit(state.copyWith(dislikedFoodGroups: disliked));
  }

  void setDislikedFoodsNote(String note) {
    emit(state.copyWith(dislikedFoodsNote: note));
  }

  void selectBudget(String budget) {
    emit(state.copyWith(selectedBudget: budget));
  }

  Future<void> submitMealPreferences() async {
    final userId = TokenService.getUserId();
    if (userId == null) return;

    emit(state.copyWith(status: AssessmentStatus.loading));

    try {
      final requestData = {
        'selectedAllergies': state.selectedAllergies,
        'allergyNote': state.allergyNote,
        'selectedDietTagId': state.selectedDietTagId,
        'dislikedFoodGroups': state.dislikedFoodGroups,
        'dislikedFoodsNote': state.dislikedFoodsNote,
        'foodBudget': state.selectedBudget,
      };

      await userRepository.updateUserPreferences(userId, requestData);
      emit(state.copyWith(status: AssessmentStatus.success));
    } catch (e) {
      emit(state.copyWith(status: AssessmentStatus.failure));
    }
  }
}
