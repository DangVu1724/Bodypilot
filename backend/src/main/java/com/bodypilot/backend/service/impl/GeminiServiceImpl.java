package com.bodypilot.backend.service.impl;

import java.time.LocalDate;
import java.util.List;
import java.util.UUID;

import org.springframework.stereotype.Service;

import com.bodypilot.backend.exception.ResourceNotFoundException;
import com.bodypilot.backend.model.dto.nutrition.FoodCandidate;
import com.bodypilot.backend.model.dto.workout.ExerciseCandidate;
import com.bodypilot.backend.model.entity.user.User;
import com.bodypilot.backend.model.entity.user.UserAllergy;
import com.bodypilot.backend.model.entity.user.UserDietPreference;
import com.bodypilot.backend.model.entity.user.UserFoodPreference;
import com.bodypilot.backend.model.entity.user.UserGoal;
import com.bodypilot.backend.model.entity.user.UserInjury;
import com.bodypilot.backend.model.entity.user.UserMetricHistory;
import com.bodypilot.backend.model.entity.user.UserProfile;
import com.bodypilot.backend.repository.UserAllergyRepository;
import com.bodypilot.backend.repository.UserDietPreferenceRepository;
import com.bodypilot.backend.repository.UserFoodPreferenceRepository;
import com.bodypilot.backend.repository.UserGoalRepository;
import com.bodypilot.backend.repository.UserInjuryRepository;
import com.bodypilot.backend.repository.UserMetricHistoryRepository;
import com.bodypilot.backend.repository.UserRepository;
import com.bodypilot.backend.repository.WorkoutPlanRepository;
import com.bodypilot.backend.service.GeminiService;
import com.bodypilot.backend.service.impl.diet.DietSuggestionHelper;
import com.bodypilot.backend.service.impl.workout.WorkoutSuggestionHelper;

import lombok.RequiredArgsConstructor;
import lombok.extern.slf4j.Slf4j;

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
        log.info("Bắt đầu tạo gợi ý thực đơn cho người dùng: userId={}, startDate={}, days={}", userId, startDate, days);

        String goalType = null;
        java.math.BigDecimal targetCal = null;

        try {
            User user = userRepository.findById(userId)
                    .orElseThrow(() -> new ResourceNotFoundException("Không tìm thấy người dùng với id: " + userId));

            UserProfile profile = user.getProfile();
            UserGoal activeGoal = goalRepository.findByUserIdAndStatus(userId, "ACTIVE")
                    .stream().findFirst().orElse(null);
            UserMetricHistory latestMetric = metricHistoryRepository
                    .findByUserIdOrderByCreatedAtDesc(userId)
                    .stream().findFirst().orElse(null);

            if (activeGoal != null) {
                goalType = activeGoal.getType();
            } else if (latestMetric != null) {
                goalType = latestMetric.getGoal();
            }

            targetCal = (latestMetric != null && latestMetric.getTargetCalories() != null)
                    ? java.math.BigDecimal.valueOf(latestMetric.getTargetCalories())
                    : null;

            if (!llmRouterService.isAiReady()) {
                log.warn("Chưa cấu hình API Key Gemini. Sử dụng thực đơn mẫu dự phòng.");
                return dietSuggestionHelper.generatePresetFallbackMealPlan(userId, startDate, days, goalType, targetCal,
                        "Cấu hình AI Key Chưa Sẵn Sàng. Hệ thống đã tự động thiết lập thực đơn chuẩn phù hợp mục tiêu.");
            }

            List<UserAllergy> allergies = allergyRepository.findAllByUserIdAndIsActiveTrue(userId);
            List<UserDietPreference> diets = dietPreferenceRepository.findAllByUserIdAndIsActiveTrue(userId);
            List<UserFoodPreference> dislikedFoods = foodPreferenceRepository.findAllByUserIdAndIsActiveTrue(userId);

            List<FoodCandidate> candidates = dietSuggestionHelper.getBalancedFoodCandidates(userId, goalType);

            String prompt = dietSuggestionHelper.buildPrompt(profile, activeGoal, latestMetric, allergies,
                    diets, dislikedFoods, candidates, startDate, days, userFeedback);

            String rawJson = llmRouterService.routeChatRequest(null, prompt,
                    "Bạn là một chuyên gia dinh dưỡng và lên thực đơn cá nhân hóa chuyên nghiệp. Hãy đưa ra thực đơn cực kỳ chi tiết, khoa học, thực tế dưới dạng JSON array hợp lệ phù hợp với danh sách thực phẩm được cung cấp.",
                    true);

            String result = dietSuggestionHelper.processAndLinkFoods(rawJson, targetCal);

            long elapsedTime = System.currentTimeMillis() - startTime;
            log.info("Hoàn thành tạo gợi ý thực đơn cho người dùng: userId={} trong {} ms", userId, elapsedTime);
            return result;
        } catch (Exception e) {
            long elapsedTime = System.currentTimeMillis() - startTime;
            log.error("Lỗi khi tạo gợi ý thực đơn cho người dùng: userId={} sau {} ms: {}", userId, elapsedTime, e.getMessage());
            return safeMealFallback(userId, startDate, days, goalType, targetCal);
        }
    }

    private String safeMealFallback(UUID userId, LocalDate startDate, Integer days, String goalType, java.math.BigDecimal targetCal) {
        try {
            return dietSuggestionHelper.generatePresetFallbackMealPlan(userId, startDate, days, goalType, targetCal,
                    "Kết nối AI gián đoạn. Hệ thống đã tự động tạo thực đơn chuẩn phù hợp mục tiêu.");
        } catch (Exception ex) {
            return dietSuggestionHelper.generatePresetFallbackMealPlan(userId, startDate, days, null, null,
                    "Kết nối AI gián đoạn. Hệ thống đã tự động tạo thực đơn chuẩn.");
        }
    }

    @Override
    public String generateWorkoutSuggestion(UUID userId, LocalDate startDate, Integer days) {
        return generateWorkoutSuggestion(userId, startDate, days, null);
    }

    @Override
    public String generateWorkoutSuggestion(UUID userId, LocalDate startDate, Integer days, String focusBodyPart) {
        long startTime = System.currentTimeMillis();
        log.info("Bắt đầu tạo gợi ý lịch tập cho người dùng: userId={}, startDate={}, days={}", userId, startDate, days);

        String goalType = null;

        try {
            User user = userRepository.findById(userId)
                    .orElseThrow(() -> new ResourceNotFoundException("Không tìm thấy người dùng với id: " + userId));

            UserProfile profile = user.getProfile();
            UserGoal activeGoal = goalRepository.findByUserIdAndStatus(userId, "ACTIVE")
                    .stream().findFirst().orElse(null);
            UserMetricHistory latestMetric = metricHistoryRepository
                    .findByUserIdOrderByCreatedAtDesc(userId)
                    .stream().findFirst().orElse(null);

            if (activeGoal != null) {
                goalType = activeGoal.getType();
            } else if (latestMetric != null) {
                goalType = latestMetric.getGoal();
            }

            if (!llmRouterService.isAiReady()) {
                log.warn("Chưa cấu hình API Key Gemini. Sử dụng lịch tập mẫu dự phòng.");
                return workoutSuggestionHelper.generatePresetFallbackWorkoutPlan(userId, startDate, days, goalType, focusBodyPart,
                        "Cấu hình AI Key Chưa Sẵn Sàng. Hệ thống đã tự động thiết lập lịch tập chuẩn phù hợp mục tiêu.");
            }

            List<UserInjury> injuries = userInjuryRepository.findAllByUserId(userId);
            List<ExerciseCandidate> candidates = workoutSuggestionHelper.getBalancedExerciseCandidates(userId, goalType, focusBodyPart);

            String prompt = workoutSuggestionHelper.buildWorkoutPrompt(profile, activeGoal, latestMetric, injuries, candidates, startDate, days, focusBodyPart);

            String rawJson = llmRouterService.routeChatRequest(null, prompt,
                    "Bạn là một huấn luyện viên cá nhân (PT) chuyên nghiệp. Hãy lên lịch trình tập luyện thể hình cực kỳ chi tiết, khoa học, thực tế phù hợp với thể trạng người dùng dưới dạng JSON array hợp lệ phù hợp với danh sách bài tập được cung cấp.",
                    true);

            String result = workoutSuggestionHelper.processAndLinkExercises(rawJson);

            long elapsedTime = System.currentTimeMillis() - startTime;
            log.info("Hoàn thành tạo gợi ý lịch tập cho người dùng: userId={} trong {} ms", userId, elapsedTime);
            return result;
        } catch (Exception e) {
            long elapsedTime = System.currentTimeMillis() - startTime;
            log.error("Lỗi khi tạo gợi ý lịch tập cho người dùng: userId={} sau {} ms: {}", userId, elapsedTime, e.getMessage());
            return safeWorkoutFallback(userId, startDate, days, goalType, focusBodyPart);
        }
    }

    private String safeWorkoutFallback(UUID userId, LocalDate startDate, Integer days, String goalType, String focusBodyPart) {
        try {
            return workoutSuggestionHelper.generatePresetFallbackWorkoutPlan(userId, startDate, days, goalType, focusBodyPart,
                    "Kết nối AI gián đoạn. Hệ thống đã tự động tạo lịch tập chuẩn phù hợp mục tiêu.");
        } catch (Exception ex) {
            return workoutSuggestionHelper.generatePresetFallbackWorkoutPlan(userId, startDate, days, null, focusBodyPart,
                    "Kết nối AI gián đoạn. Hệ thống đã tự động tạo lịch tập chuẩn.");
        }
    }
}
