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
    private List<DailyGrowthPoint> userGrowthChart;
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
    public static class ActivityItem {
        private String title;
        private String timeAgo;
        private String type;
    }
}
