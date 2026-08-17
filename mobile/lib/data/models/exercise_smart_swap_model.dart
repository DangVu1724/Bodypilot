class ExerciseSmartSwapCandidateModel {
  final String exerciseId;
  final String name;
  final String bodyPartName;
  final String targetMuscleName;
  final String difficulty;
  final double metValue;
  final String? mediaUrl;
  final double matchScore;
  final String matchReason;

  ExerciseSmartSwapCandidateModel({
    required this.exerciseId,
    required this.name,
    required this.bodyPartName,
    required this.targetMuscleName,
    required this.difficulty,
    required this.metValue,
    this.mediaUrl,
    required this.matchScore,
    required this.matchReason,
  });

  factory ExerciseSmartSwapCandidateModel.fromJson(Map<String, dynamic> json) {
    return ExerciseSmartSwapCandidateModel(
      exerciseId: json['exerciseId'] as String? ?? '',
      name: json['name'] as String? ?? 'Bài tập',
      bodyPartName: json['bodyPartName'] as String? ?? 'Toàn thân',
      targetMuscleName: json['targetMuscleName'] as String? ?? 'Cơ chính',
      difficulty: json['difficulty'] as String? ?? 'BEGINNER',
      metValue: (json['metValue'] as num?)?.toDouble() ?? 5.0,
      mediaUrl: json['mediaUrl'] as String?,
      matchScore: (json['matchScore'] as num?)?.toDouble() ?? 80.0,
      matchReason: json['matchReason'] as String? ?? 'Cùng nhóm cơ, an toàn chấn thương',
    );
  }
}
