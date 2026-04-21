import 'user_profile_model.dart';
import 'user_metrics_model.dart';
import 'goal_model.dart';

class UserModel {
  final String id;
  final String email;
  final UserProfileModel? profile;
  final UserMetricsModel? metrics;
  final GoalModel? goal;

  UserModel({
    required this.id,
    required this.email,
    this.profile,
    this.metrics,
    this.goal,
  });

  factory UserModel.fromJson(Map<String, dynamic> json) {
    return UserModel(
      id: json['id'] as String,
      email: json['email'] as String,
      profile: json['profile'] != null
          ? UserProfileModel.fromJson(json['profile'] as Map<String, dynamic>)
          : null,
      metrics: json['metrics'] != null
          ? UserMetricsModel.fromJson(json['metrics'] as Map<String, dynamic>)
          : null,
      goal: json['goal'] != null
          ? GoalModel.fromJson(json['goal'] as Map<String, dynamic>)
          : null,
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'email': email,
      'profile': profile?.toJson(),
      'metrics': metrics?.toJson(),
      'goal': goal?.toJson(),
    };
  }
}
