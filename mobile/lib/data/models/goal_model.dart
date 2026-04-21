class GoalModel {
  final String? type;
  final double? targetWeight;
  final String? deadline;
  final String? status;

  GoalModel({
    this.type,
    this.targetWeight,
    this.deadline,
    this.status,
  });

  factory GoalModel.fromJson(Map<String, dynamic> json) {
    return GoalModel(
      type: json['type'] as String?,
      targetWeight: (json['targetWeight'] as num?)?.toDouble(),
      deadline: json['deadline'] as String?,
      status: json['status'] as String?,
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'type': type,
      'targetWeight': targetWeight,
      'deadline': deadline,
      'status': status,
    };
  }
}
