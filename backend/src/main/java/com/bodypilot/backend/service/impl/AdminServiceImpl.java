package com.bodypilot.backend.service.impl;

import com.bodypilot.backend.model.dto.admin.AdminStatsDTO;
import com.bodypilot.backend.model.entity.user.User;
import com.bodypilot.backend.model.enums.FoodType;
import com.bodypilot.backend.repository.*;
import com.bodypilot.backend.service.AdminService;
import lombok.RequiredArgsConstructor;
import org.springframework.data.domain.PageRequest;
import org.springframework.data.domain.Sort;
import org.springframework.stereotype.Service;

import java.math.BigDecimal;
import java.math.RoundingMode;
import java.time.LocalDate;
import java.time.LocalDateTime;
import java.time.format.DateTimeFormatter;
import java.util.ArrayList;
import java.util.List;

@Service
@RequiredArgsConstructor
public class AdminServiceImpl implements AdminService {

    private final UserRepository userRepository;
    private final FoodRepository foodRepository;
    private final ExerciseRepository exerciseRepository;
    private final WorkoutCategoryRepository workoutCategoryRepository;
    private final FoodCategoryRepository foodCategoryRepository;
    private final UserGoalRepository userGoalRepository;
    private final AiUsageLogRepository aiUsageLogRepository;

    @Override
    public AdminStatsDTO getDashboardStats() {
        long totalUsers = userRepository.count();
        long totalDishes = foodRepository.countByType(FoodType.DISH);
        long totalIngredients = foodRepository.countByType(FoodType.INGREDIENT);
        long totalExercises = exerciseRepository.count();

        // AI Usage Analytics
        long totalAiTokens = aiUsageLogRepository.sumTotalTokens();
        long totalAiCalls = aiUsageLogRepository.countTotalAiCalls();
        double totalAiCostUsd = aiUsageLogRepository.sumTotalCostUsd();

        // 1. Build 7-day current week user growth chart
        List<AdminStatsDTO.DailyGrowthPoint> chartPoints = new ArrayList<>();
        // 2. Build 7-day previous week baseline user growth chart for comparison line
        List<AdminStatsDTO.DailyGrowthPoint> previousChartPoints = new ArrayList<>();

        LocalDate today = LocalDate.now();
        DateTimeFormatter formatter = DateTimeFormatter.ofPattern("dd/MM");

        for (int i = 6; i >= 0; i--) {
            LocalDate date = today.minusDays(i);
            LocalDateTime startOfDay = date.atStartOfDay();
            LocalDateTime endOfDay = date.atTime(23, 59, 59);

            long count = userRepository.findAll().stream()
                    .filter(u -> u.getCreatedAt() != null && !u.getCreatedAt().isBefore(startOfDay) && !u.getCreatedAt().isAfter(endOfDay))
                    .count();

            chartPoints.add(new AdminStatsDTO.DailyGrowthPoint(date.format(formatter), count));

            LocalDate prevDate = date.minusDays(7);
            LocalDateTime prevStart = prevDate.atStartOfDay();
            LocalDateTime prevEnd = prevDate.atTime(23, 59, 59);
            long prevCount = userRepository.findAll().stream()
                    .filter(u -> u.getCreatedAt() != null && !u.getCreatedAt().isBefore(prevStart) && !u.getCreatedAt().isAfter(prevEnd))
                    .count();

            previousChartPoints.add(new AdminStatsDTO.DailyGrowthPoint(date.format(formatter), prevCount));
        }

        // 3. Exercise Categories
        List<AdminStatsDTO.CategoryStatItem> exerciseCategories = exerciseRepository.findExerciseCategoryCounts();
        if (totalExercises > 0) {
            for (AdminStatsDTO.CategoryStatItem item : exerciseCategories) {
                double pct = (item.getCount() * 100.0) / totalExercises;
                item.setPercentage(BigDecimal.valueOf(pct).setScale(1, RoundingMode.HALF_UP).doubleValue());
            }
        }

        // 4. Food Categories
        List<AdminStatsDTO.CategoryStatItem> foodCategories = foodRepository.findFoodCategoryCounts();
        long totalFoods = totalDishes + totalIngredients;
        if (totalFoods > 0) {
            for (AdminStatsDTO.CategoryStatItem item : foodCategories) {
                double pct = (item.getCount() * 100.0) / totalFoods;
                item.setPercentage(BigDecimal.valueOf(pct).setScale(1, RoundingMode.HALF_UP).doubleValue());
            }
        }

        // 5. User Goal Categories
        List<AdminStatsDTO.GoalStatItem> rawGoalBreakdown = userGoalRepository.findGoalCategoryCounts();
        long totalGoalsWithData = rawGoalBreakdown.stream().mapToLong(AdminStatsDTO.GoalStatItem::getCount).sum();

        long loseCount = 0;
        long gainCount = 0;
        long maintainCount = 0;

        for (AdminStatsDTO.GoalStatItem item : rawGoalBreakdown) {
            String typeStr = (item.getGoalType() != null) ? item.getGoalType().toUpperCase() : "";
            if (typeStr.contains("LOSE") || typeStr.contains("WEIGHT_LOSS") || typeStr.contains("FAT_LOSS")) {
                loseCount += item.getCount();
            } else if (typeStr.contains("GAIN") || typeStr.contains("MUSCLE_GAIN")) {
                gainCount += item.getCount();
            } else if (typeStr.contains("MAINTAIN") || typeStr.contains("HEALTH")) {
                maintainCount += item.getCount();
            } else {
                maintainCount += item.getCount();
            }
        }

        long totalCalculatedGoals = loseCount + gainCount + maintainCount;
        long denominator = totalCalculatedGoals > 0 ? totalCalculatedGoals : (totalUsers > 0 ? totalUsers : 1);

        double losePct = BigDecimal.valueOf((loseCount * 100.0) / denominator).setScale(1, RoundingMode.HALF_UP).doubleValue();
        double gainPct = BigDecimal.valueOf((gainCount * 100.0) / denominator).setScale(1, RoundingMode.HALF_UP).doubleValue();
        double maintainPct = BigDecimal.valueOf((maintainCount * 100.0) / denominator).setScale(1, RoundingMode.HALF_UP).doubleValue();

        List<AdminStatsDTO.GoalStatItem> userGoalBreakdown = List.of(
                new AdminStatsDTO.GoalStatItem("LOSE", "Giảm cân & Giảm mỡ", loseCount, losePct),
                new AdminStatsDTO.GoalStatItem("GAIN", "Tăng cơ & Tăng cân", gainCount, gainPct),
                new AdminStatsDTO.GoalStatItem("MAINTAIN", "Duy trì vóc dáng", maintainCount, maintainPct)
        );

        // 6. Recent activities
        List<User> recentUsers = userRepository.findAll(
                PageRequest.of(0, 5, Sort.by(Sort.Direction.DESC, "createdAt"))
        ).getContent();

        List<AdminStatsDTO.ActivityItem> recentActivities = new ArrayList<>();
        for (User u : recentUsers) {
            String name = (u.getProfile() != null && u.getProfile().getFullName() != null)
                    ? u.getProfile().getFullName()
                    : u.getEmail();
            recentActivities.add(new AdminStatsDTO.ActivityItem(
                    "Người dùng mới: " + name,
                    formatTimeAgo(u.getCreatedAt()),
                    "USER"
            ));
        }

        long growthPercentage = 15;

        return AdminStatsDTO.builder()
                .totalUsers(totalUsers)
                .totalDishes(totalDishes)
                .totalIngredients(totalIngredients)
                .totalExercises(totalExercises)
                .userGrowthPercentage(growthPercentage)
                .totalAiTokens(totalAiTokens)
                .totalAiCalls(totalAiCalls)
                .totalAiCostUsd(totalAiCostUsd)
                .userGrowthChart(chartPoints)
                .previousUserGrowthChart(previousChartPoints)
                .exerciseCategories(exerciseCategories)
                .foodCategories(foodCategories)
                .userGoalBreakdown(userGoalBreakdown)
                .recentActivities(recentActivities)
                .build();
    }

    private String formatTimeAgo(LocalDateTime dateTime) {
        if (dateTime == null) return "Vừa xong";
        long seconds = java.time.Duration.between(dateTime, LocalDateTime.now()).getSeconds();
        if (seconds < 60) return "Vừa xong";
        long minutes = seconds / 60;
        if (minutes < 60) return minutes + " phút trước";
        long hours = minutes / 60;
        if (hours < 24) return hours + " giờ trước";
        long days = hours / 24;
        return days + " ngày trước";
    }
}
