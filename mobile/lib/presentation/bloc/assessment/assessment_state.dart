import 'package:equatable/equatable.dart';
import 'package:flutter/material.dart';

class GoalOption extends Equatable {
  final String title;
  final IconData icon;

  const GoalOption({required this.title, required this.icon});

  @override
  List<Object?> get props => [title, icon];
}

class GenderOption extends Equatable {
  final String title;
  final String description;
  final String imagePath;

  const GenderOption({required this.title, required this.description, required this.imagePath});

  @override
  List<Object?> get props => [title, description, imagePath];
}

class DietOption extends Equatable {
  final String title;
  final IconData icon;
  final List<String> examples;

  const DietOption({required this.title, required this.icon, this.examples = const []});

  @override
  List<Object?> get props => [title, icon, examples];
}

class ExerciseOption extends Equatable {
  final String title;
  final IconData icon;

  const ExerciseOption({required this.title, required this.icon});

  @override
  List<Object?> get props => [title, icon];
}

class ConditionOption extends Equatable {
  final String title;
  final IconData icon;

  const ConditionOption({required this.title, required this.icon});

  @override
  List<Object?> get props => [title, icon];
}

class AllergyOption extends Equatable {
  final String name;
  final String category;

  const AllergyOption({required this.name, required this.category});

  @override
  List<Object?> get props => [name, category];
}

class SleepOption extends Equatable {
  final String title;
  final IconData icon;
  final String description;

  const SleepOption({required this.title, required this.icon, required this.description});

  @override
  List<Object?> get props => [title, icon];
}

class AssessmentState extends Equatable {
  static const List<GoalOption> goalOptions = [
    GoalOption(title: 'Giảm cân', icon: Icons.fitness_center),
    GoalOption(title: 'Tăng cơ', icon: Icons.fitness_center),
    GoalOption(title: 'Cải thiện sức khỏe', icon: Icons.fitness_center),
    GoalOption(title: 'Trải nghiệm', icon: Icons.fitness_center),
  ];

  static const List<GenderOption> genderOptions = [
    GenderOption(title: 'Nam', description: 'Phù hợp với nam giới', imagePath: 'assets/images/man_gender.png'),
    GenderOption(title: 'Nữ', description: 'Phù hợp với nữ giới', imagePath: 'assets/images/woman_gender.png'),
  ];

  static const List<DietOption> dietOptions = [
    DietOption(title: 'Ăn chay', icon: Icons.eco, examples: ['Rau củ luộc', 'Đậu hũ', 'Salad', 'Canh rong biển']),
    DietOption(
      title: 'Low-carb',
      icon: Icons.local_fire_department,
      examples: ['Thịt bò', 'Trứng', 'Cá hồi', 'Rau xanh'],
    ),
    DietOption(title: 'Eat clean', icon: Icons.restaurant, examples: ['Ức gà', 'Gạo lứt', 'Khoai lang', 'Salad']),
    DietOption(title: 'Keto', icon: Icons.bolt, examples: ['Thịt mỡ', 'Trứng', 'Bơ', 'Phô mai']),
    DietOption(
      title: 'High-protein',
      icon: Icons.fitness_center,
      examples: ['Ức gà', 'Cá ngừ', 'Trứng', 'Whey protein'],
    ),
    DietOption(title: 'Không theo chế độ', icon: Icons.fastfood, examples: ['Cơm', 'Bún phở', 'Đồ chiên', 'Đồ ngọt']),
  ];

  static const List<ExerciseOption> exerciseOptions = [
    ExerciseOption(title: 'Jogging', icon: Icons.directions_run),
    ExerciseOption(title: 'Walking', icon: Icons.directions_walk),
    ExerciseOption(title: 'Hiking', icon: Icons.terrain),
    ExerciseOption(title: 'Skating', icon: Icons.roller_skating),
    ExerciseOption(title: 'Biking', icon: Icons.directions_bike),
    ExerciseOption(title: 'Weightlifting', icon: Icons.fitness_center),
    ExerciseOption(title: 'Yoga', icon: Icons.self_improvement),
    ExerciseOption(title: 'Cardio', icon: Icons.favorite),
    ExerciseOption(title: 'Other', icon: Icons.more_horiz),
  ];

  static const List<ConditionOption> conditionOptions = [
    ConditionOption(title: 'Tiểu đường', icon: Icons.bloodtype),
    ConditionOption(title: 'Tăng huyết áp', icon: Icons.favorite),
    ConditionOption(title: 'Bệnh tim', icon: Icons.health_and_safety),
    ConditionOption(title: 'Viêm khớp', icon: Icons.self_improvement),
    ConditionOption(title: 'Hen suyễn', icon: Icons.air),
    ConditionOption(title: 'Rối loạn tiêu hóa', icon: Icons.local_pizza),
    ConditionOption(title: 'Trầm cảm', icon: Icons.psychology),
    ConditionOption(title: 'Mất ngủ', icon: Icons.bedtime),
  ];

  static const List<String> allergyCategories = ['Không có', 'Hạt', 'Hải sản', 'Sữa', 'Trái cây'];

  static const List<AllergyOption> allergyOptions = [
    AllergyOption(name: 'Đậu phộng', category: 'Hạt'),
    AllergyOption(name: 'Hạt điều', category: 'Hạt'),
    AllergyOption(name: 'Hạt óc chó', category: 'Hạt'),
    AllergyOption(name: 'Tôm', category: 'Hải sản'),
    AllergyOption(name: 'Cá', category: 'Hải sản'),
    AllergyOption(name: 'Sữa', category: 'Sữa'),
    AllergyOption(name: 'Phô mai', category: 'Sữa'),
    AllergyOption(name: 'Dứa', category: 'Trái cây'),
    AllergyOption(name: 'Đào', category: 'Trái cây'),
  ];

  static const List<SleepOption> sleepOptions = [
    SleepOption(title: 'Ngủ nhiều', icon: Icons.hotel, description: 'Trên 8 tiếng/đêm'),
    SleepOption(title: 'Rất tốt', icon: Icons.emoji_emotions, description: '7-8 tiếng/đêm'),
    SleepOption(title: 'Tốt', icon: Icons.sentiment_satisfied, description: '6-7 tiếng/đêm'),
    SleepOption(title: 'Trung bình', icon: Icons.sentiment_neutral, description: '5-6 tiếng/đêm'),
    SleepOption(title: 'Kém', icon: Icons.sentiment_dissatisfied, description: '4-5 tiếng/đêm'),
    SleepOption(title: 'Rất kém', icon: Icons.mood_bad, description: 'Dưới 4 tiếng/đêm'),
  ];

  static const String experienceImage = 'assets/images/gym_workout.png';

  final String? selectedGoal;
  final String? selectedGender;
  final int selectedHeight;
  final int selectedWeight;
  final int selectedAge;
  final String? selectedDiet;
  final String? selectedExercise;
  final List<String> selectedConditions;
  final String? selectedAllergyCategory;
  final List<String> selectedAllergies;
  final int targetWeight;
  final String? selectedSleep;
  final bool? hasExperience;

  const AssessmentState({
    this.selectedGoal,
    this.selectedGender,
    this.selectedHeight = 170,
    this.selectedWeight = 65,
    this.selectedAge = 25,
    this.selectedDiet,
    this.selectedExercise,
    this.selectedConditions = const [],
    this.selectedAllergyCategory,
    this.selectedAllergies = const [],
    this.targetWeight = 65,
    this.selectedSleep,
    this.hasExperience,
  });

  AssessmentState copyWith({
    String? selectedGoal,
    String? selectedGender,
    int? selectedHeight,
    int? selectedWeight,
    int? selectedAge,
    String? selectedDiet,
    String? selectedExercise,
    List<String>? selectedConditions,
    String? selectedAllergyCategory,
    List<String>? selectedAllergies,
    int? targetWeight,
    String? selectedSleep,
    bool? hasExperience,
  }) {
    return AssessmentState(
      selectedGoal: selectedGoal ?? this.selectedGoal,
      selectedGender: selectedGender ?? this.selectedGender,
      selectedHeight: selectedHeight ?? this.selectedHeight,
      selectedWeight: selectedWeight ?? this.selectedWeight,
      selectedAge: selectedAge ?? this.selectedAge,
      selectedDiet: selectedDiet ?? this.selectedDiet,
      selectedExercise: selectedExercise ?? this.selectedExercise,
      selectedConditions: selectedConditions ?? this.selectedConditions,
      selectedAllergyCategory: selectedAllergyCategory ?? this.selectedAllergyCategory,
      selectedAllergies: selectedAllergies ?? this.selectedAllergies,
      targetWeight: targetWeight ?? this.targetWeight,
      selectedSleep: selectedSleep ?? this.selectedSleep,
      hasExperience: hasExperience ?? this.hasExperience,
    );
  }

  @override
  List<Object?> get props => [
    selectedGoal,
    selectedGender,
    selectedHeight,
    selectedWeight,
    selectedAge,
    selectedDiet,
    selectedExercise,
    selectedConditions,
    selectedAllergyCategory,
    selectedAllergies,
    targetWeight,
    selectedSleep,
    hasExperience,
  ];
}
