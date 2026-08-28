class AdminStatsModel {
  final int totalUsers;
  final int totalDishes;
  final int totalIngredients;
  final int totalExercises;
  final int userGrowthPercentage;
  
  // AI Token & Call Analytics
  final int totalAiTokens;
  final int totalAiCalls;
  final double totalAiCostUsd;

  final List<DailyGrowthPoint> userGrowthChart;
  final List<DailyGrowthPoint> previousUserGrowthChart;
  final List<CategoryStatItem> exerciseCategories;
  final List<CategoryStatItem> foodCategories;
  final List<GoalStatItem> userGoalBreakdown;
  final List<ActivityItem> recentActivities;

  AdminStatsModel({
    required this.totalUsers,
    required this.totalDishes,
    required this.totalIngredients,
    required this.totalExercises,
    required this.userGrowthPercentage,
    this.totalAiTokens = 0,
    this.totalAiCalls = 0,
    this.totalAiCostUsd = 0.0,
    required this.userGrowthChart,
    required this.previousUserGrowthChart,
    required this.exerciseCategories,
    required this.foodCategories,
    required this.userGoalBreakdown,
    required this.recentActivities,
  });

  factory AdminStatsModel.fromJson(Map<String, dynamic> json) {
    return AdminStatsModel(
      totalUsers: json['totalUsers'] ?? 0,
      totalDishes: json['totalDishes'] ?? 0,
      totalIngredients: json['totalIngredients'] ?? 0,
      totalExercises: json['totalExercises'] ?? 0,
      userGrowthPercentage: json['userGrowthPercentage'] ?? 0,
      totalAiTokens: (json['totalAiTokens'] as num?)?.toInt() ?? 0,
      totalAiCalls: (json['totalAiCalls'] as num?)?.toInt() ?? 0,
      totalAiCostUsd: (json['totalAiCostUsd'] as num?)?.toDouble() ?? 0.0,
      userGrowthChart: (json['userGrowthChart'] as List? ?? [])
          .map((e) => DailyGrowthPoint.fromJson(e as Map<String, dynamic>))
          .toList(),
      previousUserGrowthChart: (json['previousUserGrowthChart'] as List? ?? [])
          .map((e) => DailyGrowthPoint.fromJson(e as Map<String, dynamic>))
          .toList(),
      exerciseCategories: (json['exerciseCategories'] as List? ?? [])
          .map((e) => CategoryStatItem.fromJson(e as Map<String, dynamic>))
          .toList(),
      foodCategories: (json['foodCategories'] as List? ?? [])
          .map((e) => CategoryStatItem.fromJson(e as Map<String, dynamic>))
          .toList(),
      userGoalBreakdown: (json['userGoalBreakdown'] as List? ?? [])
          .map((e) => GoalStatItem.fromJson(e as Map<String, dynamic>))
          .toList(),
      recentActivities: (json['recentActivities'] as List? ?? [])
          .map((e) => ActivityItem.fromJson(e as Map<String, dynamic>))
          .toList(),
    );
  }
}

class DailyGrowthPoint {
  final String date;
  final int count;

  DailyGrowthPoint({required this.date, required this.count});

  factory DailyGrowthPoint.fromJson(Map<String, dynamic> json) {
    return DailyGrowthPoint(
      date: json['date'] ?? '',
      count: json['count'] ?? 0,
    );
  }
}

class CategoryStatItem {
  final String name;
  final int count;
  final double percentage;

  CategoryStatItem({
    required this.name,
    required this.count,
    required this.percentage,
  });

  factory CategoryStatItem.fromJson(Map<String, dynamic> json) {
    return CategoryStatItem(
      name: json['name'] ?? '',
      count: json['count'] ?? 0,
      percentage: (json['percentage'] as num?)?.toDouble() ?? 0.0,
    );
  }
}

class GoalStatItem {
  final String goalType;
  final String label;
  final int count;
  final double percentage;

  GoalStatItem({
    required this.goalType,
    required this.label,
    required this.count,
    required this.percentage,
  });

  factory GoalStatItem.fromJson(Map<String, dynamic> json) {
    return GoalStatItem(
      goalType: json['goalType'] ?? '',
      label: json['label'] ?? '',
      count: json['count'] ?? 0,
      percentage: (json['percentage'] as num?)?.toDouble() ?? 0.0,
    );
  }
}

class ActivityItem {
  final String title;
  final String timeAgo;
  final String type;

  ActivityItem({
    required this.title,
    required this.timeAgo,
    required this.type,
  });

  factory ActivityItem.fromJson(Map<String, dynamic> json) {
    return ActivityItem(
      title: json['title'] ?? '',
      timeAgo: json['timeAgo'] ?? '',
      type: json['type'] ?? '',
    );
  }
}
