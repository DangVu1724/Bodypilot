class AdminStatsModel {
  final int totalUsers;
  final int totalDishes;
  final int totalIngredients;
  final int totalExercises;
  final int userGrowthPercentage;
  final List<DailyGrowthPoint> userGrowthChart;
  final List<ActivityItem> recentActivities;

  AdminStatsModel({
    required this.totalUsers,
    required this.totalDishes,
    required this.totalIngredients,
    required this.totalExercises,
    required this.userGrowthPercentage,
    required this.userGrowthChart,
    required this.recentActivities,
  });

  factory AdminStatsModel.fromJson(Map<String, dynamic> json) {
    return AdminStatsModel(
      totalUsers: json['totalUsers'] ?? 0,
      totalDishes: json['totalDishes'] ?? 0,
      totalIngredients: json['totalIngredients'] ?? 0,
      totalExercises: json['totalExercises'] ?? 0,
      userGrowthPercentage: json['userGrowthPercentage'] ?? 0,
      userGrowthChart: (json['userGrowthChart'] as List? ?? [])
          .map((e) => DailyGrowthPoint.fromJson(e as Map<String, dynamic>))
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
