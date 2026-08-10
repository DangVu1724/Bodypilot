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

    private final LlmRouterService llmRouterService;
    private final DietSuggestionHelper dietSuggestionHelper;
    private final WorkoutSuggestionHelper workoutSuggestionHelper;

    @Override
    public String generateMealSuggestion(UUID userId, LocalDate startDate, Integer days) {
        return generateMealSuggestion(userId, startDate, days, null);
    }

    @Override
    public String generateMealSuggestion(UUID userId, LocalDate startDate, Integer days, String userFeedback) {
        long startTime = System.currentTimeMillis();
        log.info("🚀 [MEAL_AI_START] Bắt đầu tạo gợi ý thực đơn (Meal) cho userId={}, startDate={}, days={}, userFeedback={}", userId, startDate, days, userFeedback);
        try {
            User user = userRepository.findById(userId)
                    .orElseThrow(() -> new ResourceNotFoundException("User not found with id: " + userId));

            log.info("Retrieving user profile, goals and metric history...");
            UserProfile profile = user.getProfile();
            UserGoal activeGoal = goalRepository.findByUserIdAndStatus(userId, "ACTIVE")
                    .stream().findFirst().orElse(null);
            UserMetricHistory latestMetric = metricHistoryRepository.findByUserIdOrderByCreatedAtDesc(userId)
                    .stream().findFirst().orElse(null);

            String goalType = null;
            if (activeGoal != null) {
                goalType = activeGoal.getType();
            } else if (latestMetric != null) {
                goalType = latestMetric.getGoal();
            }
            log.info("User goal type resolved to: {}", goalType);

            java.math.BigDecimal targetCal = (latestMetric != null && latestMetric.getTargetCalories() != null) 
                    ? java.math.BigDecimal.valueOf(latestMetric.getTargetCalories()) : null;

            boolean apiKeyConfigured = llmRouterService.isAiReady();
            log.info("AI API key configured for meal suggestion: {}", apiKeyConfigured);

            if (!apiKeyConfigured) {
                log.warn("AI API key is missing. Returning preset fallback JSON.");
                return dietSuggestionHelper.generatePresetFallbackMealPlan(userId, startDate, days, goalType, targetCal,
                        "Cấu hình AI Key Chưa Sẵn Sàng. Hệ thống đã tự động thiết lập thực đơn chuẩn phù hợp mục tiêu.");
            }

            log.info("Retrieving user allergies, diets, and food preferences...");
            List<UserAllergy> allergies = allergyRepository.findAllByUserIdAndIsActiveTrue(userId);
            List<UserDietPreference> diets = dietPreferenceRepository.findAllByUserIdAndIsActiveTrue(userId);
            List<UserFoodPreference> dislikedFoods = foodPreferenceRepository.findAllByUserIdAndIsActiveTrue(userId);

            log.info("Retrieving food candidates from database...");
            List<FoodCandidate> candidates = dietSuggestionHelper.getBalancedFoodCandidates(userId, goalType);
            log.info("Retrieved {} food candidates.", candidates.size());

            log.info("Building Gemini Prompt with user feedback...");
            String prompt = dietSuggestionHelper.buildPrompt(profile, activeGoal, latestMetric, allergies, diets, dislikedFoods, candidates, startDate, days, userFeedback);
            log.info("Sending meal suggestion prompt to AI for user {}: \n{}", userId, prompt);

            String rawJson = llmRouterService.routeChatRequest(null, prompt, "Bạn là một chuyên gia dinh dưỡng và lên thực đơn cá nhân hóa chuyên nghiệp. Hãy đưa ra thực đơn cực kỳ chi tiết, khoa học, thực tế dưới dạng JSON array hợp lệ phù hợp với danh sách thực phẩm được cung cấp.", true);
            log.info("Received raw meal suggestion JSON from AI for user {}: \n{}", userId, rawJson);
            
            log.info("Processing food mappings, exact macro scaling and saving to DTOs...");
            String result = dietSuggestionHelper.processAndLinkFoods(rawJson, targetCal);

            long elapsedTime = System.currentTimeMillis() - startTime;
            log.info("✅ [MEAL_AI_END] Hoàn thành tạo gợi ý thực đơn (Meal) cho userId={}! Tổng thời gian xử lý: {} ms ({} giây)", userId, elapsedTime, String.format("%.2f", elapsedTime / 1000.0));
            return result;
        } catch (Exception e) {
            long elapsedTime = System.currentTimeMillis() - startTime;
            log.error("❌ [MEAL_AI_ERROR] Thất bại sau {} ms ({} giây) khi tạo thực đơn: ", elapsedTime, String.format("%.2f", elapsedTime / 1000.0), e);
            try {
                UserGoal activeGoal = goalRepository.findByUserIdAndStatus(userId, "ACTIVE").stream().findFirst().orElse(null);
                UserMetricHistory latestMetric = metricHistoryRepository.findByUserIdOrderByCreatedAtDesc(userId).stream().findFirst().orElse(null);
                String goalType = (activeGoal != null) ? activeGoal.getType() : ((latestMetric != null) ? latestMetric.getGoal() : null);
                java.math.BigDecimal targetCal = (latestMetric != null && latestMetric.getTargetCalories() != null)
                        ? java.math.BigDecimal.valueOf(latestMetric.getTargetCalories()) : null;
                return dietSuggestionHelper.generatePresetFallbackMealPlan(userId, startDate, days, goalType, targetCal,
                        "Kết nối AI gián đoạn. Hệ thống đã tự động tạo thực đơn chuẩn phù hợp mục tiêu.");
            } catch (Exception ex) {
                return dietSuggestionHelper.generatePresetFallbackMealPlan(userId, startDate, days, null, null,
                        "Kết nối AI gián đoạn. Hệ thống đã tự động tạo thực đơn chuẩn.");
            }
        }
    }

    @Override
    public String generateWorkoutSuggestion(UUID userId, LocalDate startDate, Integer days, String focusBodyPart) {
        long startTime = System.currentTimeMillis();
        log.info("🚀 [WORKOUT_AI_START] Bắt đầu tạo gợi ý lịch tập (Workout) cho userId={}, startDate={}, days={}, focusBodyPart={}", userId, startDate, days, focusBodyPart);
        try {
            User user = userRepository.findById(userId)
                    .orElseThrow(() -> new ResourceNotFoundException("User not found with id: " + userId));

            UserProfile profile = user.getProfile();
            UserGoal activeGoal = goalRepository.findByUserIdAndStatus(userId, "ACTIVE")
                    .stream().findFirst().orElse(null);
            UserMetricHistory latestMetric = metricHistoryRepository.findByUserIdOrderByCreatedAtDesc(userId)
                    .stream().findFirst().orElse(null);

            String goalType = null;
            if (activeGoal != null) {
                goalType = activeGoal.getType();
            } else if (latestMetric != null) {
                goalType = latestMetric.getGoal();
            }

            boolean apiKeyConfigured = llmRouterService.isAiReady();
            log.info("AI API key configured for workout suggestion: {}", apiKeyConfigured);

            if (!apiKeyConfigured) {
                log.warn("AI API key is missing. Returning preset fallback workout JSON.");
                return workoutSuggestionHelper.generatePresetFallbackWorkoutPlan(userId, startDate, days, goalType, focusBodyPart,
                        "Cấu hình AI Key Chưa Sẵn Sàng. Hệ thống đã tự động thiết lập lịch tập chuẩn phù hợp mục tiêu.");
            }

            List<UserInjury> injuries = userInjuryRepository.findAllByUserId(userId);

            List<ExerciseCandidate> candidates = workoutSuggestionHelper.getBalancedExerciseCandidates(userId, goalType, focusBodyPart);

            String prompt = workoutSuggestionHelper.buildWorkoutPrompt(profile, activeGoal, latestMetric, injuries, candidates, startDate, days, focusBodyPart);
            log.info("Sending workout suggestion prompt to AI for user {}: \n{}", userId, prompt);

            String rawJson = llmRouterService.routeChatRequest(null, prompt, "Bạn là một huấn luyện viên cá nhân (PT) chuyên nghiệp. Hãy lên lịch trình tập luyện thể hình cực kỳ chi tiết, khoa học, thực tế phù hợp với thể trạng người dùng dưới dạng JSON array hợp lệ phù hợp với danh sách bài tập được cung cấp.", true);
            log.info("Received raw workout suggestion JSON from Gemini AI for user {}: \n{}", userId, rawJson);
            String result = workoutSuggestionHelper.processAndLinkExercises(rawJson);

            long elapsedTime = System.currentTimeMillis() - startTime;
            log.info("✅ [WORKOUT_AI_END] Hoàn thành tạo gợi ý lịch tập (Workout) cho userId={}! Tổng thời gian xử lý: {} ms ({} giây)", userId, elapsedTime, String.format("%.2f", elapsedTime / 1000.0));
            return result;
        } catch (Exception e) {
            long elapsedTime = System.currentTimeMillis() - startTime;
            log.error("❌ [WORKOUT_AI_ERROR] Thất bại sau {} ms ({} giây) khi tạo lịch tập: ", elapsedTime, String.format("%.2f", elapsedTime / 1000.0), e);
            try {
                UserGoal activeGoal = goalRepository.findByUserIdAndStatus(userId, "ACTIVE").stream().findFirst().orElse(null);
                UserMetricHistory latestMetric = metricHistoryRepository.findByUserIdOrderByCreatedAtDesc(userId).stream().findFirst().orElse(null);
                String goalType = (activeGoal != null) ? activeGoal.getType() : ((latestMetric != null) ? latestMetric.getGoal() : null);
                return workoutSuggestionHelper.generatePresetFallbackWorkoutPlan(userId, startDate, days, goalType, focusBodyPart,
                        "Kết nối AI gián đoạn. Hệ thống đã tự động tạo lịch tập chuẩn phù hợp mục tiêu.");
            } catch (Exception ex) {
                return workoutSuggestionHelper.generatePresetFallbackWorkoutPlan(userId, startDate, days, null, focusBodyPart,
                        "Kết nối AI gián đoạn. Hệ thống đã tự động tạo lịch tập chuẩn.");
            }
        }
    }

    @Override
    public String generateWorkoutSuggestion(UUID userId, LocalDate startDate, Integer days) {
        return generateWorkoutSuggestion(userId, startDate, days, null);
    }
}
