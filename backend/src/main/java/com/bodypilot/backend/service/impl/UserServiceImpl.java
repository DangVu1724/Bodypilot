package com.bodypilot.backend.service.impl;

import com.bodypilot.backend.model.entity.user.UserProfile;
import com.bodypilot.backend.model.entity.user.UserMetricHistory;
import com.bodypilot.backend.model.entity.user.User;
import com.bodypilot.backend.model.entity.user.UserGoal;
import com.bodypilot.backend.exception.ResourceNotFoundException;
import com.bodypilot.backend.model.dto.user.UserProfileResponse;
import com.bodypilot.backend.model.dto.user.UserResponse;
import com.bodypilot.backend.model.dto.user.UserMetricsResponse;
import com.bodypilot.backend.model.dto.health.GoalResponse;
import com.bodypilot.backend.repository.*;
import com.bodypilot.backend.service.UserService;
import lombok.RequiredArgsConstructor;
import org.springframework.stereotype.Service;

import java.util.List;
import java.util.UUID;
import java.util.stream.Collectors;

import com.bodypilot.backend.model.dto.nutrition.CalorieCalculationResult;
import com.bodypilot.backend.model.dto.user.UpdateProfileRequest;
import com.bodypilot.backend.model.enums.ActivityLevel;
import com.bodypilot.backend.model.enums.Gender;
import com.bodypilot.backend.service.CalorieCalculatorService;
import org.springframework.transaction.annotation.Transactional;

@Service
@RequiredArgsConstructor
public class UserServiceImpl implements UserService {

    private final UserRepository userRepository;
    private final UserProfileRepository userProfileRepository;
    private final UserMetricHistoryRepository userMetricHistoryRepository;
    private final UserGoalRepository goalRepository;
    private final CalorieCalculatorService calorieCalculatorService;

    @Override
    public User getById(UUID id) {
        return userRepository.findById(id)
                .orElseThrow(() -> new ResourceNotFoundException("User not found with id: " + id));
    }

    @Override
    public User getUserByEmail(String email) {
        return userRepository.findByEmail(email)
                .orElseThrow(() -> new ResourceNotFoundException("User not found with email: " + email));
    }

    @Override
    public UserResponse getUserDetails(UUID userId) {
        User user = getById(userId);
        return mapToUserResponse(user);
    }

    @Override
    public List<UserResponse> getAllUsers() {
        return userRepository.findAll().stream()
                .map(this::mapToUserResponse)
                .collect(Collectors.toList());
    }

    @Override
    public List<UserResponse> searchUsers(String query) {
        if (query == null || query.isBlank()) {
            return getAllUsers();
        }
        return userRepository.searchUsers(query).stream()
                .map(this::mapToUserResponse)
                .collect(Collectors.toList());
    }

    @Override
    @Transactional
    public UserResponse updateProfile(UUID userId, UpdateProfileRequest request) {
        User user = getById(userId);
        UserProfile profile = userProfileRepository.findByUserId(userId)
                .orElse(UserProfile.builder().user(user).build());

        if (request.getFullName() != null) {
            profile.setFullName(request.getFullName().trim());
        }
        if (request.getGender() != null) {
            profile.setGender(request.getGender());
        }
        if (request.getAge() != null) {
            profile.setAge(request.getAge());
        }
        if (request.getHeightCm() != null) {
            profile.setHeightCm(request.getHeightCm());
        }
        if (request.getWeight() != null) {
            profile.setWeight(request.getWeight());
        }
        if (request.getActivityLevel() != null) {
            profile.setActivityLevel(request.getActivityLevel());
        }
        if (request.getHasExperience() != null) {
            profile.setHasExperience(request.getHasExperience());
        }
        if (request.getAvatarUrl() != null) {
            profile.setAvatarUrl(request.getAvatarUrl());
        }

        userProfileRepository.save(profile);

        // Recalculate metrics if physical metrics are present
        if (profile.getWeight() != null && profile.getHeightCm() != null && profile.getAge() != null) {
            UserGoal activeGoal = goalRepository.findByUserIdAndStatus(userId, "ACTIVE")
                    .stream().findFirst().orElse(null);
            String goalStr = activeGoal != null ? activeGoal.getType() : "MAINTAIN";

            Gender enumGender = "Nam".equalsIgnoreCase(profile.getGender()) || "MALE".equalsIgnoreCase(profile.getGender())
                    ? Gender.MALE
                    : Gender.FEMALE;

            ActivityLevel enumActivityLevel;
            try {
                enumActivityLevel = profile.getActivityLevel() != null
                        ? ActivityLevel.valueOf(profile.getActivityLevel())
                        : ActivityLevel.SEDENTARY;
            } catch (Exception e) {
                enumActivityLevel = ActivityLevel.SEDENTARY;
            }

            com.bodypilot.backend.model.enums.Goal enumGoal;
            try {
                enumGoal = com.bodypilot.backend.model.enums.Goal.valueOf(goalStr);
            } catch (Exception e) {
                enumGoal = com.bodypilot.backend.model.enums.Goal.MAINTAIN;
            }

            CalorieCalculationResult calculationResult = calorieCalculatorService.calculateMetrics(
                    profile.getWeight(),
                    profile.getHeightCm(),
                    profile.getAge(),
                    enumGender,
                    enumActivityLevel,
                    enumGoal);

            UserMetricHistory newMetric = UserMetricHistory.builder()
                    .user(user)
                    .weight(profile.getWeight())
                    .heightCm(profile.getHeightCm())
                    .age(profile.getAge())
                    .goal(goalStr)
                    .activityLevel(profile.getActivityLevel())
                    .bmi(calculationResult.getBmi())
                    .bmr(calculationResult.getBmr())
                    .tdee(calculationResult.getTdee())
                    .targetCalories(calculationResult.getTargetCalories())
                    .build();

            userMetricHistoryRepository.save(newMetric);
        }

        return getUserDetails(userId);
    }

    private UserResponse mapToUserResponse(User user) {
        UUID userId = user.getId();
        UserProfile profile = user.getProfile();
        
        UserMetricHistory latestMetric = userMetricHistoryRepository.findByUserIdOrderByCreatedAtDesc(userId)
                .stream().findFirst().orElse(null);
                
        UserGoal activeGoal = goalRepository.findByUserIdAndStatus(userId, "ACTIVE")
                .stream().findFirst().orElse(null);
                
        UserMetricsResponse metricsResponse = latestMetric != null ? UserMetricsResponse.builder()
                .weight(latestMetric.getWeight())
                .heightCm(latestMetric.getHeightCm())
                .age(latestMetric.getAge())
                .goal(latestMetric.getGoal())
                .activityLevel(latestMetric.getActivityLevel())
                .bmi(latestMetric.getBmi())
                .bmr(latestMetric.getBmr())
                .tdee(latestMetric.getTdee())
                .targetCalories(latestMetric.getTargetCalories())
                .build() : null;
                
        GoalResponse goalResponse = activeGoal != null ? GoalResponse.builder()
                .type(activeGoal.getType())
                .targetWeight(activeGoal.getTargetWeight())
                .deadline(activeGoal.getDeadline())
                .status(activeGoal.getStatus())
                .build() : null;

        return UserResponse.builder()
                .id(user.getId())
                .email(user.getEmail())
                .role(user.getRole() != null ? user.getRole().name() : "CUSTOMER")
                .profile(UserProfileResponse.builder()
                        .fullName(profile != null ? profile.getFullName() : null)
                        .avatarUrl(profile != null ? profile.getAvatarUrl() : null)
                        .gender(profile != null ? profile.getGender() : null)
                        .hasExperience(profile != null ? profile.getHasExperience() : null)
                        .isAssessmentCompleted(isProfileComplete(userId))
                        .build())
                .metrics(metricsResponse)
                .goal(goalResponse)
                .build();
    }

    @Override
    public boolean isProfileComplete(UUID userId) {
        UserProfile profile = userProfileRepository.findByUserId(userId).orElse(null);
        return profile != null && profile.isAssessmentCompleted();
    }
}
