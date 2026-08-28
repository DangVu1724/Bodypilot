package com.bodypilot.backend.model.dto.admin;

import lombok.AllArgsConstructor;
import lombok.Builder;
import lombok.Data;
import lombok.NoArgsConstructor;

import java.util.List;

@Data
@Builder
@NoArgsConstructor
@AllArgsConstructor
public class AdminStatsDTO {
    private long totalUsers;
    private long totalDishes;
    private long totalIngredients;
    private long totalExercises;
    private long userGrowthPercentage;
    
    // AI Token & Usage Analytics
    private long totalAiTokens;
    private long totalAiCalls;
    private double totalAiCostUsd;

    private List<DailyGrowthPoint> userGrowthChart;
    private List<DailyGrowthPoint> previousUserGrowthChart;
    private List<CategoryStatItem> exerciseCategories;
    private List<CategoryStatItem> foodCategories;
    private List<GoalStatItem> userGoalBreakdown;
    private List<ActivityItem> recentActivities;

    @Data
    @Builder
    @NoArgsConstructor
    @AllArgsConstructor
    public static class DailyGrowthPoint {
        private String date;
        private long count;
    }

    @Data
    @Builder
    @NoArgsConstructor
    @AllArgsConstructor
    public static class CategoryStatItem {
        private String name;
        private long count;
        private double percentage;
    }

    @Data
    @Builder
    @NoArgsConstructor
    @AllArgsConstructor
    public static class GoalStatItem {
        private String goalType;
        private String label;
        private long count;
        private double percentage;
    }

    @Data
    @Builder
    @NoArgsConstructor
    @AllArgsConstructor
    public static class ActivityItem {
        private String title;
        private String timeAgo;
        private String type;
    }
}
