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
    DietOption(title: 'Không theo chế độ', icon: Icons.fastfood, examples: ['Cơm', 'Bún phở', 'Đồ chiên', 'Đồ ngọt']),
  ];

  static const String experienceImage = 'assets/images/gym_workout.png';

  final String? selectedGoal;
  final String? selectedGender;
  final int selectedHeight;
  final int selectedWeight;
  final int selectedAge;
  final String? selectedDiet;
  final bool? hasExperience;

  const AssessmentState({
    this.selectedGoal,
    this.selectedGender,
    this.selectedHeight = 170,
    this.selectedWeight = 65,
    this.selectedAge = 25,
    this.selectedDiet,
    this.hasExperience,
  });

  AssessmentState copyWith({
    String? selectedGoal,
    String? selectedGender,
    int? selectedHeight,
    int? selectedWeight,
    int? selectedAge,
    String? selectedDiet,
    bool? hasExperience,
  }) {
    return AssessmentState(
      selectedGoal: selectedGoal ?? this.selectedGoal,
      selectedGender: selectedGender ?? this.selectedGender,
      selectedHeight: selectedHeight ?? this.selectedHeight,
      selectedWeight: selectedWeight ?? this.selectedWeight,
      selectedAge: selectedAge ?? this.selectedAge,
      selectedDiet: selectedDiet ?? this.selectedDiet,
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
    hasExperience,
  ];
}
