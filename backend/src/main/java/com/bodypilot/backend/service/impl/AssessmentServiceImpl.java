package com.bodypilot.backend.service.impl;

import com.bodypilot.backend.exception.ResourceNotFoundException;
import com.bodypilot.backend.model.dto.AssessmentSubmissionRequest;
import com.bodypilot.backend.model.dto.CalorieCalculationResult;
import com.bodypilot.backend.model.entity.*;
import com.bodypilot.backend.model.enums.ActivityLevel;
import com.bodypilot.backend.model.enums.Gender;
import com.bodypilot.backend.repository.*;
import com.bodypilot.backend.service.AssessmentService;
import com.bodypilot.backend.service.CalorieCalculatorService;
import lombok.RequiredArgsConstructor;
import org.springframework.stereotype.Service;
import org.springframework.transaction.annotation.Transactional;

import java.time.LocalDate;
import java.util.UUID;

@Service
@RequiredArgsConstructor
public class AssessmentServiceImpl implements AssessmentService {

    private final UserRepository userRepository;
    private final UserProfileRepository userProfileRepository;
    private final GoalRepository goalRepository;
    private final HealthConditionRepository conditionRepository;
    private final InjuryRepository injuryRepository;
    private final UserHealthConditionRepository userConditionRepository;
    private final UserInjuryRepository userInjuryRepository;
    private final UserMetricHistoryRepository userMetricHistoryRepository;
    private final CalorieCalculatorService calorieCalculatorService;

    @Override
    @Transactional
    public void submitAssessment(UUID userId, AssessmentSubmissionRequest request) {
        User user = userRepository.findById(userId)
                .orElseThrow(() -> new ResourceNotFoundException("User not found with id: " + userId));

        // 1. Update UserProfile
        UserProfile profile = userProfileRepository.findByUserId(userId)
                .orElse(UserProfile.builder().user(user).build());

        profile.setGender(request.getSelectedGender());
        profile.setAge(request.getAge());
        profile.setHeightCm(request.getHeightCm());
        profile.setWeight(request.getWeight());
        profile.setHasExperience(request.getHasExperience());
        profile.setActivityLevel(request.getActivityLevel());
        profile.setAssessmentCompleted(true);
        userProfileRepository.save(profile);

        // Map strings to Enums for calculation
        Gender enumGender = "Nam".equalsIgnoreCase(request.getSelectedGender()) ? Gender.MALE : Gender.FEMALE;
        
        ActivityLevel enumActivityLevel;
        try {
            enumActivityLevel = ActivityLevel.valueOf(request.getActivityLevel());
        } catch (Exception e) {
            enumActivityLevel = ActivityLevel.SEDENTARY; // fallback
        }
        
        com.bodypilot.backend.model.enums.Goal enumGoal;
        try {
            enumGoal = com.bodypilot.backend.model.enums.Goal.valueOf(request.getSelectedGoal());
        } catch (Exception e) {
            enumGoal = com.bodypilot.backend.model.enums.Goal.MAINTAIN; // fallback
        }

        // Calculate metrics
        CalorieCalculationResult metrics = calorieCalculatorService.calculateMetrics(
            request.getWeight(),
            request.getHeightCm(),
            request.getAge(),
            enumGender,
            enumActivityLevel,
            enumGoal
        );

        // Save UserMetricHistory
        UserMetricHistory history = UserMetricHistory.builder()
            .user(user)
            .weight(request.getWeight())
            .heightCm(request.getHeightCm())
            .age(request.getAge())
            .goal(request.getSelectedGoal())
            .activityLevel(request.getActivityLevel())
            .bmi(metrics.getBmi())
            .bmr(metrics.getBmr())
            .tdee(metrics.getTdee())
            .targetCalories(metrics.getTargetCalories())
            .build();
        userMetricHistoryRepository.save(history);

        // 2. Create/Update Goal (Update instead of creating a new row if exists)
        Goal goal = goalRepository.findByUserIdAndStatus(userId, "ACTIVE").stream().findFirst()
                .orElse(Goal.builder().user(user).status("ACTIVE").build());
                
        goal.setType(request.getSelectedGoal());
        goal.setTargetWeight(request.getTargetWeight());
        if (goal.getId() == null) {
            goal.setDeadline(LocalDate.now().plusMonths(3)); // Default 3 months for new goals
        }
        goalRepository.save(goal);

        // 3. Link Conditions
        if (request.getSelectedConditions() != null) {
            for (String conditionCode : request.getSelectedConditions()) {
                conditionRepository.findByCode(conditionCode)
                        .ifPresent(c -> {
                            UserHealthCondition userCondition = UserHealthCondition.builder()
                                    .user(user)
                                    .condition(c)
                                    .build();
                            userConditionRepository.save(userCondition);
                        });
            }
        }

        // 4. Link Injuries
        if (request.getSelectedInjuries() != null) {
            for (String injuryCode : request.getSelectedInjuries()) {
                injuryRepository.findByCode(injuryCode)
                        .ifPresent(i -> {
                            UserInjury userInjury = UserInjury.builder()
                                    .user(user)
                                    .injury(i)
                                    .build();
                            userInjuryRepository.save(userInjury);
                        });
            }
        }
    }
}
