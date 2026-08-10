class CheckInStatusModel {
  final bool isCheckInDue;
  final bool onboardingNeeded;
  final String? lastCheckInDate;
  final int daysSinceLastCheckIn;
  final double currentWeight;
  final double currentHeightCm;
  final String currentGoal;
  final String goalDescription;

  CheckInStatusModel({
    required this.isCheckInDue,
    this.onboardingNeeded = false,
    this.lastCheckInDate,
    required this.daysSinceLastCheckIn,
    required this.currentWeight,
    required this.currentHeightCm,
    required this.currentGoal,
    required this.goalDescription,
  });

  factory CheckInStatusModel.fromJson(Map<String, dynamic> json) {
    return CheckInStatusModel(
      isCheckInDue: json['checkInDue'] ?? json['isCheckInDue'] ?? false,
      onboardingNeeded: json['onboardingNeeded'] ?? false,
      lastCheckInDate: json['lastCheckInDate'],
      daysSinceLastCheckIn: (json['daysSinceLastCheckIn'] as num?)?.toInt() ?? 0,
      currentWeight: (json['currentWeight'] as num?)?.toDouble() ?? 60.0,
      currentHeightCm: (json['currentHeightCm'] as num?)?.toDouble() ?? 170.0,
      currentGoal: json['currentGoal'] ?? 'LOSE_0_5KG',
      goalDescription: json['goalDescription'] ?? 'Giảm 0.5kg/tuần',
    );
  }
}

class CheckInRequestModel {
  final double newWeight;
  final double? newHeightCm;
  final String adherenceLevel;
  final String energyLevel;
  final String hungerLevel;
  final String goalChoice;
  final double? targetWeight;
  final String? workoutState;
  final bool? hasInjury;
  final List<String>? injuredParts;
  final String? notes;

  CheckInRequestModel({
    required this.newWeight,
    this.newHeightCm,
    required this.adherenceLevel,
    required this.energyLevel,
    required this.hungerLevel,
    required this.goalChoice,
    this.targetWeight,
    this.workoutState,
    this.hasInjury,
    this.injuredParts,
    this.notes,
  });

  Map<String, dynamic> toJson() {
    return {
      'newWeight': newWeight,
      if (newHeightCm != null) 'newHeightCm': newHeightCm,
      'adherenceLevel': adherenceLevel,
      'energyLevel': energyLevel,
      'hungerLevel': hungerLevel,
      'goalChoice': goalChoice,
      if (targetWeight != null) 'targetWeight': targetWeight,
      if (workoutState != null) 'workoutState': workoutState,
      if (hasInjury != null) 'hasInjury': hasInjury,
      if (injuredParts != null) 'injuredParts': injuredParts,
      if (notes != null) 'notes': notes,
    };
  }
}

class CheckInResultModel {
  final double previousWeight;
  final double newWeight;
  final double weightChange;
  final double newBmr;
  final double newTdee;
  final double newTargetCalories;
  final String aiFeedback;
  final String advice;

  CheckInResultModel({
    required this.previousWeight,
    required this.newWeight,
    required this.weightChange,
    required this.newBmr,
    required this.newTdee,
    required this.newTargetCalories,
    required this.aiFeedback,
    required this.advice,
  });

  factory CheckInResultModel.fromJson(Map<String, dynamic> json) {
    return CheckInResultModel(
      previousWeight: (json['previousWeight'] as num?)?.toDouble() ?? 0.0,
      newWeight: (json['newWeight'] as num?)?.toDouble() ?? 0.0,
      weightChange: (json['weightChange'] as num?)?.toDouble() ?? 0.0,
      newBmr: (json['newBmr'] as num?)?.toDouble() ?? 0.0,
      newTdee: (json['newTdee'] as num?)?.toDouble() ?? 0.0,
      newTargetCalories: (json['newTargetCalories'] as num?)?.toDouble() ?? 0.0,
      aiFeedback: json['aiFeedback'] ?? '',
      advice: json['advice'] ?? '',
    );
  }
}
