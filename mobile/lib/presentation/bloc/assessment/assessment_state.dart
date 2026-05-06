import 'package:core_shared/models/health_condition_model.dart';
import 'package:core_shared/models/injury_model.dart';
import 'package:equatable/equatable.dart';
import 'package:flutter/material.dart';

enum AssessmentStatus { initial, loading, success, failure }

class GoalOption extends Equatable {
  final String title;
  final String value;
  final IconData icon;
  final String description;

  const GoalOption({required this.title, required this.value, required this.icon, required this.description});

  @override
  List<Object?> get props => [title, value, icon, description];
}

class GenderOption extends Equatable {
  final String title;
  final String description;
  final String imagePath;

  const GenderOption({required this.title, required this.description, required this.imagePath});

  @override
  List<Object?> get props => [title, description, imagePath];
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

class InjuryOption extends Equatable {
  final String title;
  final IconData icon;
  final String bodyPart;

  const InjuryOption({required this.title, required this.icon, required this.bodyPart});

  @override
  List<Object?> get props => [title, icon, bodyPart];
}

class ActivityLevelOption extends Equatable {
  final String title;
  final String value;
  final IconData icon;
  final String description;

  const ActivityLevelOption({required this.title, required this.value, required this.icon, required this.description});

  @override
  List<Object?> get props => [title, value, icon, description];
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
    GoalOption(
      title: 'Duy trì vóc dáng',
      value: 'MAINTAIN',
      icon: Icons.accessibility_new,
      description: 'Giữ cân nặng hiện tại',
    ),
    GoalOption(title: 'Giảm cân chậm', value: 'LOSE_0_5KG', icon: Icons.trending_down, description: 'Giảm 0.5kg/tuần'),
    GoalOption(title: 'Giảm cân nhanh', value: 'LOSE_1KG', icon: Icons.fast_rewind, description: 'Giảm 1kg/tuần'),
    GoalOption(title: 'Tăng cân chậm', value: 'GAIN_0_5KG', icon: Icons.trending_up, description: 'Tăng 0.5kg/tuần'),
    GoalOption(title: 'Tăng cân nhanh', value: 'GAIN_1KG', icon: Icons.fast_forward, description: 'Tăng 1kg/tuần'),
    GoalOption(
      title: 'Tăng cơ mỡ thấp',
      value: 'GAIN_MUSCLE',
      icon: Icons.fitness_center,
      description: 'Tập xả cơ kết hợp lean bulk',
    ),
    GoalOption(
      title: 'Cải thiện sức khỏe',
      value: 'HEALTHY_LIFESTYLE',
      icon: Icons.favorite,
      description: 'Sống lành mạnh vững bền',
    ),
  ];

  static const List<GenderOption> genderOptions = [
    GenderOption(title: 'Nam', description: 'Phù hợp với nam giới', imagePath: 'assets/images/man_gender.png'),
    GenderOption(title: 'Nữ', description: 'Phù hợp với nữ giới', imagePath: 'assets/images/woman_gender.png'),
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


  static const List<InjuryOption> injuryOptions = [
    InjuryOption(title: 'ACL Tear', icon: Icons.personal_injury, bodyPart: 'KNEE'),
    InjuryOption(title: 'Runner\'s Knee', icon: Icons.personal_injury, bodyPart: 'KNEE'),
    InjuryOption(title: 'Lower Back Pain', icon: Icons.accessibility_new, bodyPart: 'BACK'),
    InjuryOption(title: 'Herniated Disc', icon: Icons.accessibility_new, bodyPart: 'BACK'),
    InjuryOption(title: 'Shoulder Impingement', icon: Icons.boy, bodyPart: 'SHOULDER'),
    InjuryOption(title: 'Rotator Cuff Tear', icon: Icons.boy, bodyPart: 'SHOULDER'),
    InjuryOption(title: 'Tennis Elbow', icon: Icons.fitness_center, bodyPart: 'ARM'),
    InjuryOption(title: 'Ankle Sprain', icon: Icons.directions_walk, bodyPart: 'LEG'),
  ];

  static const List<ActivityLevelOption> activityLevelOptions = [
    ActivityLevelOption(
      title: 'Ít vận động',
      value: 'SEDENTARY',
      icon: Icons.desktop_mac,
      description: 'Ngồi nhiều, ít tập thể dục',
    ),
    ActivityLevelOption(
      title: 'Nhẹ nhàng',
      value: 'LIGHTLY_ACTIVE',
      icon: Icons.directions_walk,
      description: '1-2 lần/tuần',
    ),
    ActivityLevelOption(
      title: 'Vừa phải',
      value: 'MODERATELY_ACTIVE',
      icon: Icons.fitness_center,
      description: '3-5 lần/tuần',
    ),
    ActivityLevelOption(
      title: 'Tích cực',
      value: 'VERY_ACTIVE',
      icon: Icons.directions_run,
      description: '6-7 lần/tuần',
    ),
    ActivityLevelOption(
      title: 'Rất tích cực',
      value: 'EXTRA_ACTIVE',
      icon: Icons.local_fire_department,
      description: '2 lần/ngày',
    ),
    ActivityLevelOption(
      title: 'Chuyên nghiệp',
      value: 'PROFESSIONAL',
      icon: Icons.emoji_events,
      description: 'Vận động viên',
    ),
  ];

  static const String experienceImage = 'assets/images/gym_workout.png';

  static IconData getConditionIcon(String code) {
    switch (code) {
      case 'DIABETES':
        return Icons.bloodtype;
      case 'HYPERTENSION':
        return Icons.favorite;
      case 'HEART_DISEASE':
        return Icons.health_and_safety;
      case 'ARTHRITIS':
        return Icons.self_improvement;
      case 'ASTHMA':
        return Icons.air;
      case 'DIGESTIVE_DISORDER':
        return Icons.local_pizza;
      case 'DEPRESSION':
        return Icons.psychology;
      case 'INSOMNIA':
        return Icons.bedtime;
      default:
        return Icons.health_and_safety_outlined;
    }
  }

  static IconData getInjuryIcon(String code) {
    switch (code) {
      case 'ACL_TEAR':
      case 'RUNNERS_KNEE':
        return Icons.personal_injury;
      case 'LOWER_BACK_PAIN':
      case 'HERNIATED_DISC':
        return Icons.accessibility_new;
      case 'SHOULDER_IMPINGEMENT':
      case 'ROTATOR_CUFF_TEAR':
        return Icons.boy;
      case 'TENNIS_ELBOW':
        return Icons.fitness_center;
      case 'ANKLE_SPRAIN':
        return Icons.directions_walk;
      default:
        return Icons.personal_injury_outlined;
    }
  }

  final String? selectedGoal;
  final String? selectedGender;
  final int selectedHeight;
  final int selectedWeight;
  final int selectedAge;
  final List<String> selectedConditions; // Now stores codes
  final List<String> selectedInjuries; // Now stores codes
  final List<HealthConditionModel> availableConditions;
  final List<InjuryModel> availableInjuries;
  final String? selectedAllergyCategory;
  final List<String> selectedAllergies;
  final int targetWeight;
  final bool? hasExperience;
  final String? selectedActivityLevel;
  final AssessmentStatus status;

  const AssessmentState({
    this.selectedGoal,
    this.selectedGender,
    this.selectedHeight = 170,
    this.selectedWeight = 65,
    this.selectedAge = 25,
    this.selectedConditions = const [],
    this.selectedInjuries = const [],
    this.availableConditions = const [],
    this.availableInjuries = const [],
    this.selectedAllergyCategory,
    this.selectedAllergies = const [],
    this.targetWeight = 65,
    this.hasExperience,
    this.selectedActivityLevel,
    this.status = AssessmentStatus.initial,
  });

  AssessmentState copyWith({
    String? selectedGoal,
    String? selectedGender,
    int? selectedHeight,
    int? selectedWeight,
    int? selectedAge,
    List<String>? selectedConditions,
    List<String>? selectedInjuries,
    List<HealthConditionModel>? availableConditions,
    List<InjuryModel>? availableInjuries,
    String? selectedAllergyCategory,
    List<String>? selectedAllergies,
    int? targetWeight,
    bool? hasExperience,
    String? selectedActivityLevel,
    AssessmentStatus? status,
  }) {
    return AssessmentState(
      selectedGoal: selectedGoal ?? this.selectedGoal,
      selectedGender: selectedGender ?? this.selectedGender,
      selectedHeight: selectedHeight ?? this.selectedHeight,
      selectedWeight: selectedWeight ?? this.selectedWeight,
      selectedAge: selectedAge ?? this.selectedAge,
      selectedConditions: selectedConditions ?? this.selectedConditions,
      selectedInjuries: selectedInjuries ?? this.selectedInjuries,
      availableConditions: availableConditions ?? this.availableConditions,
      availableInjuries: availableInjuries ?? this.availableInjuries,
      selectedAllergyCategory: selectedAllergyCategory ?? this.selectedAllergyCategory,
      selectedAllergies: selectedAllergies ?? this.selectedAllergies,
      targetWeight: targetWeight ?? this.targetWeight,
      hasExperience: hasExperience ?? this.hasExperience,
      selectedActivityLevel: selectedActivityLevel ?? this.selectedActivityLevel,
      status: status ?? this.status,
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'selectedGoal': selectedGoal,
      'selectedGender': selectedGender,
      'heightCm': selectedHeight,
      'weight': selectedWeight,
      'age': selectedAge,
      'selectedConditions': selectedConditions,
      'selectedInjuries': selectedInjuries,
      'selectedAllergyCategory': selectedAllergyCategory,
      'selectedAllergies': selectedAllergies,
      'targetWeight': targetWeight,
      'hasExperience': hasExperience,
      'activityLevel': selectedActivityLevel,
      // Status is transient, don't persist it to avoid jumping to Home on reload
    };
  }

  factory AssessmentState.fromJson(Map<String, dynamic> json) {
    return AssessmentState(
      selectedGoal: json['selectedGoal'] as String?,
      selectedGender: json['selectedGender'] as String?,
      selectedHeight: (json['selectedHeight'] as num?)?.toInt() ?? 170,
      selectedWeight: (json['selectedWeight'] as num?)?.toInt() ?? 65,
      selectedAge: (json['selectedAge'] as num?)?.toInt() ?? 25,
      selectedConditions: List<String>.from(json['selectedConditions'] ?? []),
      selectedInjuries: List<String>.from(json['selectedInjuries'] ?? []),
      selectedAllergyCategory: json['selectedAllergyCategory'] as String?,
      selectedAllergies: List<String>.from(json['selectedAllergies'] ?? []),
      targetWeight: (json['targetWeight'] as num?)?.toInt() ?? 65,
      hasExperience: json['hasExperience'] as bool?,
      selectedActivityLevel: json['activityLevel'] as String?,
      status: AssessmentStatus.initial, // Always start as initial when loading from cache
    );
  }

  @override
  List<Object?> get props => [
    selectedGoal,
    selectedGender,
    selectedHeight,
    selectedWeight,
    selectedAge,
    selectedConditions,
    selectedInjuries,
    availableConditions,
    availableInjuries,
    selectedAllergyCategory,
    selectedAllergies,
    targetWeight,
    hasExperience,
    selectedActivityLevel,
    status,
  ];
}
