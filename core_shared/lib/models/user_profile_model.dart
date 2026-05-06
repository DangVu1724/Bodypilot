class UserProfileModel {
  final String? fullName;
  final String? avatarUrl;
  final bool isAssessmentCompleted;

  UserProfileModel({
    this.fullName,
    this.avatarUrl,
    required this.isAssessmentCompleted,
  });

  factory UserProfileModel.fromJson(Map<String, dynamic> json) {
    return UserProfileModel(
      fullName: json['fullName'] as String?,
      avatarUrl: json['avatarUrl'] as String?,
      isAssessmentCompleted: json['isAssessmentCompleted'] as bool? ?? json['assessmentCompleted'] as bool? ?? false,
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'fullName': fullName,
      'avatarUrl': avatarUrl,
      'isAssessmentCompleted': isAssessmentCompleted,
    };
  }
}
