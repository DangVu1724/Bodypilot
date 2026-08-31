class UserProfileModel {
  final String? fullName;
  final String? avatarUrl;
  final String? gender;
  final bool? hasExperience;
  final bool isAssessmentCompleted;

  UserProfileModel({
    this.fullName,
    this.avatarUrl,
    this.gender,
    this.hasExperience,
    required this.isAssessmentCompleted,
  });

  factory UserProfileModel.fromJson(Map<String, dynamic> json) {
    return UserProfileModel(
      fullName: json['fullName'] as String?,
      avatarUrl: json['avatarUrl'] as String?,
      gender: json['gender'] as String?,
      hasExperience: json['hasExperience'] as bool?,
      isAssessmentCompleted: json['isAssessmentCompleted'] as bool? ?? json['assessmentCompleted'] as bool? ?? false,
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'fullName': fullName,
      'avatarUrl': avatarUrl,
      'gender': gender,
      'hasExperience': hasExperience,
      'isAssessmentCompleted': isAssessmentCompleted,
    };
  }
}
