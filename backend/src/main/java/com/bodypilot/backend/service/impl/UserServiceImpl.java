package com.bodypilot.backend.service.impl;

import com.bodypilot.backend.exception.ResourceNotFoundException;
import com.bodypilot.backend.model.dto.AssessmentSubmissionRequest;
import com.bodypilot.backend.model.dto.UserProfileResponse;
import com.bodypilot.backend.model.dto.UserRegistrationRequest;
import com.bodypilot.backend.model.dto.UserResponse;
import com.bodypilot.backend.model.entity.*;
import com.bodypilot.backend.model.dto.CalorieCalculationResult;
import com.bodypilot.backend.model.enums.ActivityLevel;
import com.bodypilot.backend.model.enums.Gender;
import com.bodypilot.backend.service.CalorieCalculatorService;
import com.bodypilot.backend.repository.*;
import com.bodypilot.backend.service.UserService;
import com.bodypilot.backend.model.dto.UserMetricsResponse;
import com.bodypilot.backend.model.dto.GoalResponse;
import lombok.RequiredArgsConstructor;
import org.springframework.stereotype.Service;
import org.springframework.transaction.annotation.Transactional;

import java.time.LocalDate;
import java.util.UUID;

@Service
@RequiredArgsConstructor
public class UserServiceImpl implements UserService {

    private final UserRepository userRepository;
    private final UserProfileRepository userProfileRepository;
    private final UserMetricHistoryRepository userMetricHistoryRepository;
    private final GoalRepository goalRepository;

    @Override
    public User getById(UUID id) {
        return userRepository.findById(id)
                .orElseThrow(() -> new ResourceNotFoundException("User not found with id: " + id));
    }

    @Override
    public UserResponse getUserDetails(UUID userId) {
        User user = getById(userId);
        UserProfile profile = user.getProfile();
        
        UserMetricHistory latestMetric = userMetricHistoryRepository.findByUserIdOrderByCreatedAtDesc(userId)
                .stream().findFirst().orElse(null);
                
        Goal activeGoal = goalRepository.findByUserIdAndStatus(userId, "ACTIVE")
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
                .profile(UserProfileResponse.builder()
                        .fullName(profile != null ? profile.getFullName() : null)
                        .avatarUrl(profile != null ? profile.getAvatarUrl() : null)
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
