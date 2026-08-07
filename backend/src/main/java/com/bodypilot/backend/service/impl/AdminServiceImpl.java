package com.bodypilot.backend.service.impl;

import com.bodypilot.backend.model.dto.admin.AdminStatsDTO;
import com.bodypilot.backend.model.entity.user.User;
import com.bodypilot.backend.model.enums.FoodType;
import com.bodypilot.backend.repository.ExerciseRepository;
import com.bodypilot.backend.repository.FoodRepository;
import com.bodypilot.backend.repository.UserRepository;
import com.bodypilot.backend.service.AdminService;
import lombok.RequiredArgsConstructor;
import org.springframework.data.domain.PageRequest;
import org.springframework.data.domain.Sort;
import org.springframework.stereotype.Service;

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

    @Override
    public AdminStatsDTO getDashboardStats() {
        long totalUsers = userRepository.count();
        long totalDishes = foodRepository.countByType(FoodType.DISH);
        long totalIngredients = foodRepository.countByType(FoodType.INGREDIENT);
        long totalExercises = exerciseRepository.count();

        // Build 7-day user growth chart
        List<AdminStatsDTO.DailyGrowthPoint> chartPoints = new ArrayList<>();
        LocalDate today = LocalDate.now();
        DateTimeFormatter formatter = DateTimeFormatter.ofPattern("dd/MM");

        List<User> allUsers = userRepository.findAll();
        for (int i = 6; i >= 0; i--) {
            LocalDate date = today.minusDays(i);
            long countUntilDate = allUsers.stream()
                    .filter(u -> u.getCreatedAt() != null && !u.getCreatedAt().toLocalDate().isAfter(date))
                    .count();
            chartPoints.add(new AdminStatsDTO.DailyGrowthPoint(date.format(formatter), countUntilDate));
        }

        // Recent activities (recent users registered)
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

        long growthPercentage = 15; // default trend %

        return AdminStatsDTO.builder()
                .totalUsers(totalUsers)
                .totalDishes(totalDishes)
                .totalIngredients(totalIngredients)
                .totalExercises(totalExercises)
                .userGrowthPercentage(growthPercentage)
                .userGrowthChart(chartPoints)
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
