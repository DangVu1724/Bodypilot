import 'user_profile_model.dart';
import 'user_metrics_model.dart';
import 'goal_model.dart';

class UserModel {
  final String id;
  final String email;
  final String role;
  final UserProfileModel? profile;
  final UserMetricsModel? metrics;
  final GoalModel? goal;
  final DateTime? createdAt;

  UserModel({
    required this.id,
    required this.email,
    this.role = 'CUSTOMER',
    this.profile,
    this.metrics,
    this.goal,
    this.createdAt,
  });

  factory UserModel.fromJson(Map<String, dynamic> json) {
    return UserModel(
      id: json['id'] as String,
      email: json['email'] as String,
      role: json['role'] as String? ?? 'CUSTOMER',
      profile: json['profile'] != null
          ? UserProfileModel.fromJson(json['profile'] as Map<String, dynamic>)
          : null,
      metrics: json['metrics'] != null
          ? UserMetricsModel.fromJson(json['metrics'] as Map<String, dynamic>)
          : null,
      goal: json['goal'] != null
          ? GoalModel.fromJson(json['goal'] as Map<String, dynamic>)
          : null,
      createdAt: json['createdAt'] != null
          ? DateTime.tryParse(json['createdAt'].toString())
          : (json['created_at'] != null ? DateTime.tryParse(json['created_at'].toString()) : null),
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'email': email,
      'role': role,
      'profile': profile?.toJson(),
      'metrics': metrics?.toJson(),
      'goal': goal?.toJson(),
      'createdAt': createdAt?.toIso8601String(),
    };
  }
}
