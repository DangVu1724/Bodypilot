package com.bodypilot.backend.service.impl;

import com.bodypilot.backend.exception.ResourceNotFoundException;
import com.bodypilot.backend.model.dto.nutrition.FoodCandidate;
import com.bodypilot.backend.model.dto.workout.ExerciseCandidate;
import com.bodypilot.backend.model.entity.user.*;
import com.bodypilot.backend.model.entity.workout.WorkoutPlan;
import com.bodypilot.backend.model.enums.Goal;
import com.bodypilot.backend.repository.*;
import com.bodypilot.backend.service.GeminiService;
import lombok.RequiredArgsConstructor;
import lombok.extern.slf4j.Slf4j;
import org.springframework.stereotype.Service;

import java.time.LocalDate;
import java.util.List;
import java.util.UUID;

@Service
@RequiredArgsConstructor
@Slf4j
public class GeminiServiceImpl implements GeminiService {

    private final UserRepository userRepository;
    private final UserGoalRepository goalRepository;
    private final UserMetricHistoryRepository metricHistoryRepository;
    private final UserAllergyRepository allergyRepository;
    private final UserDietPreferenceRepository dietPreferenceRepository;
    private final UserFoodPreferenceRepository foodPreferenceRepository;
    private final UserInjuryRepository userInjuryRepository;
    private final WorkoutPlanRepository workoutPlanRepository;

    private final GeminiClient geminiClient;
    private final DietSuggestionHelper dietSuggestionHelper;
    private final WorkoutSuggestionHelper workoutSuggestionHelper;

    @Override
    public String generateMealSuggestion(UUID userId, LocalDate startDate, Integer days) {
        return generateMealSuggestion(userId, startDate, days, null);
    }

    @Override
    public String generateMealSuggestion(UUID userId, LocalDate startDate, Integer days, String userFeedback) {
        log.info("generateMealSuggestion invoked: userId={}, startDate={}, days={}, userFeedback={}", userId, startDate, days, userFeedback);
        try {
            User user = userRepository.findById(userId)
                    .orElseThrow(() -> new ResourceNotFoundException("User not found with id: " + userId));

            boolean apiKeyConfigured = geminiClient.isApiKeyConfigured();
            log.info("Gemini API key configured for meal suggestion: {}", apiKeyConfigured);

            if (!apiKeyConfigured) {
                log.warn("Gemini API key is missing. Returning fallback JSON.");
                return dietSuggestionHelper.getFallbackJson(startDate, "Cấu hình Gemini Chưa Sẵn Sàng. Vui lòng cấu hình gemini.api.key trong application.properties.", days);
            }

            log.info("Retrieving user profile, goals and metric history...");
            UserProfile profile = user.getProfile();
            UserGoal activeGoal = goalRepository.findByUserIdAndStatus(userId, "ACTIVE")
                    .stream().findFirst().orElse(null);
            UserMetricHistory latestMetric = metricHistoryRepository.findByUserIdOrderByCreatedAtDesc(userId)
                    .stream().findFirst().orElse(null);

            log.info("Retrieving user allergies, diets, and food preferences...");
            List<UserAllergy> allergies = allergyRepository.findAllByUserIdAndIsActiveTrue(userId);
            List<UserDietPreference> diets = dietPreferenceRepository.findAllByUserIdAndIsActiveTrue(userId);
            List<UserFoodPreference> dislikedFoods = foodPreferenceRepository.findAllByUserIdAndIsActiveTrue(userId);

            String goalType = null;
            if (activeGoal != null) {
                goalType = activeGoal.getType();
            } else if (latestMetric != null) {
                goalType = latestMetric.getGoal();
            }
            log.info("User goal type resolved to: {}", goalType);

            log.info("Retrieving food candidates from database...");
            List<FoodCandidate> candidates = dietSuggestionHelper.getBalancedFoodCandidates(userId, goalType);
            log.info("Retrieved {} food candidates.", candidates.size());

            log.info("Building Gemini Prompt with user feedback...");
            String prompt = dietSuggestionHelper.buildPrompt(profile, activeGoal, latestMetric, allergies, diets, dislikedFoods, candidates, startDate, days, userFeedback);
            log.info("Sending meal suggestion prompt to Gemini AI for user {}: \n{}", userId, prompt);

            String rawJson = geminiClient.callGemini(prompt, "Bạn là một chuyên gia dinh dưỡng và lên thực đơn cá nhân hóa chuyên nghiệp. Hãy đưa ra thực đơn cực kỳ chi tiết, khoa học, thực tế dưới dạng JSON array hợp lệ phù hợp với danh sách thực phẩm được cung cấp.");
            log.info("Received raw meal suggestion JSON from Gemini AI for user {}: \n{}", userId, rawJson);
            
            log.info("Processing food mappings, exact macro scaling and saving to DTOs...");
            java.math.BigDecimal targetCal = (latestMetric != null && latestMetric.getTargetCalories() != null) 
                    ? java.math.BigDecimal.valueOf(latestMetric.getTargetCalories()) : null;
            return dietSuggestionHelper.processAndLinkFoods(rawJson, targetCal);
        } catch (Exception e) {
            log.error("Exception in generateMealSuggestion: ", e);
            return dietSuggestionHelper.getFallbackJson(startDate, "❌ Đã xảy ra lỗi khi lập thực đơn: " + e.getMessage(), days);
        }
    }

    @Override
    public String generateWorkoutSuggestion(UUID userId, LocalDate startDate, Integer days) {
        log.info("generateWorkoutSuggestion invoked: userId={}, startDate={}, days={}", userId, startDate, days);
        User user = userRepository.findById(userId)
                .orElseThrow(() -> new ResourceNotFoundException("User not found with id: " + userId));

        boolean apiKeyConfigured = geminiClient.isApiKeyConfigured();
        log.info("Gemini API key configured for workout suggestion: {}", apiKeyConfigured);

        if (!apiKeyConfigured) {
            log.warn("Gemini API key is missing. Returning fallback JSON.");
            return workoutSuggestionHelper.getFallbackWorkoutJson(startDate, "Cáº¥u hÃ¬nh Gemini ChÆ°a Sáºµn SÃ ng. Vui lÃ²ng cáº¥u hÃ¬nh gemini.api.key trong application.properties.", days);
        }

        UserProfile profile = user.getProfile();
        UserGoal activeGoal = goalRepository.findByUserIdAndStatus(userId, "ACTIVE")
                .stream().findFirst().orElse(null);
        UserMetricHistory latestMetric = metricHistoryRepository.findByUserIdOrderByCreatedAtDesc(userId)
                .stream().findFirst().orElse(null);

        List<UserInjury> injuries = userInjuryRepository.findAllByUserId(userId);

        String goalType = null;
        if (activeGoal != null) {
            goalType = activeGoal.getType();
        } else if (latestMetric != null) {
            goalType = latestMetric.getGoal();
        }

        List<ExerciseCandidate> candidates = workoutSuggestionHelper.getBalancedExerciseCandidates(userId, goalType);

        // Láº¥y danh sÃ¡ch giÃ¡o Ã¡n luyá»‡n táº­p máº«u cÃ³ sáºµn phÃ¹ há»£p vá»›i má»¥c tiÃªu cá»§a user
        Goal goalEnum = null;
        if (goalType != null) {
            try {
                goalEnum = Goal.valueOf(goalType);
            } catch (IllegalArgumentException e) {
                // Ignore
            }
        }

        List<WorkoutPlan> existingPlans;
        if (goalEnum != null) {
            existingPlans = workoutPlanRepository.findByGoal(goalEnum);
        } else {
            existingPlans = workoutPlanRepository.findAll();
        }

        String prompt = workoutSuggestionHelper.buildWorkoutPrompt(profile, activeGoal, latestMetric, injuries, candidates, existingPlans, startDate, days);
        log.info("Sending workout suggestion prompt to Gemini AI for user {}: \n{}", userId, prompt);

        try {
            String rawJson = geminiClient.callGemini(prompt, "Báº¡n lÃ  má»™t huáº¥n luyá»‡n viÃªn cÃ¡ nhÃ¢n (PT) chuyÃªn nghiá»‡p. HÃ£y lÃªn lá»‹ch trÃ¬nh táº­p luyá»‡n thá»ƒ hÃ¬nh cá»±c ká»³ chi tiáº¿t, khoa há»c, thá»±c táº¿ phÃ¹ há»£p vá»›i thá»ƒ tráº¡ng ngÆ°á»i dÃ¹ng dÆ°á»›i dáº¡ng JSON array há»£p lá»‡ phÃ¹ há»£p vá»›i danh sÃ¡ch bÃ i táº­p Ä‘Æ°á»£c cung cáº¥p.");
            log.info("Received raw workout suggestion JSON from Gemini AI for user {}: \n{}", userId, rawJson);
            return workoutSuggestionHelper.processAndLinkExercises(rawJson);
        } catch (Exception e) {
            log.error("Error calling Gemini API for workout suggestion: ", e);
            return workoutSuggestionHelper.getFallbackWorkoutJson(startDate, "âŒ ÄÃ£ xáº£y ra lá»—i khi gá»i AI: " + e.getMessage(), days);
        }
    }
}

