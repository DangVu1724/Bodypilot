package com.bodypilot.backend.service.impl.workout;

import java.time.LocalDate;
import java.util.ArrayList;
import java.util.HashMap;
import java.util.List;
import java.util.Map;
import java.util.UUID;
import java.util.stream.Collectors;

import org.springframework.stereotype.Component;

import com.bodypilot.backend.model.dto.workout.DailyWorkoutDTO;
import com.bodypilot.backend.model.dto.workout.DailyWorkoutItemDTO;
import com.bodypilot.backend.model.entity.user.UserInjury;
import com.bodypilot.backend.model.entity.workout.Exercise;
import com.bodypilot.backend.repository.ExerciseRepository;
import com.bodypilot.backend.repository.UserInjuryRepository;
import com.bodypilot.backend.service.impl.PresetWorkoutPlanData;

import com.fasterxml.jackson.databind.ObjectMapper;
import com.fasterxml.jackson.databind.SerializationFeature;
import com.fasterxml.jackson.datatype.jsr310.JavaTimeModule;

import lombok.RequiredArgsConstructor;
import lombok.extern.slf4j.Slf4j;

/**
 * Service dedicated to medical-grade preset fallback workout plan generation.
 */
@Component
@RequiredArgsConstructor
@Slf4j
public class PresetWorkoutFallbackBuilder {

    private final ExerciseRepository exerciseRepository;
    private final UserInjuryRepository userInjuryRepository;
    private final WorkoutExerciseFilterService exerciseFilterService;

    private final ObjectMapper objectMapper = new ObjectMapper()
            .registerModule(new JavaTimeModule())
            .disable(SerializationFeature.WRITE_DATES_AS_TIMESTAMPS);

    public String generatePresetFallbackWorkoutPlan(UUID userId, LocalDate startDate, Integer days, String goalType,
            String focusBodyPart, String noteMessage) {
        log.info("[PRESET_WORKOUT_FALLBACK] Generating preset fallback workout plan for userId={}, startDate={}, days={}, goalType={}, focusBodyPart={}",
                userId, startDate, days, goalType, focusBodyPart);
        try {
            // 1. Lấy danh sách chấn thương và lọc ra các bài tập an toàn từ DB
            List<UserInjury> injuries = (userId != null) ? userInjuryRepository.findAllByUserId(userId)
                    : new ArrayList<>();
            List<Exercise> availableExercises = exerciseFilterService.getFilteredExercises(injuries);

            // 2. Tạo các Map tra cứu nhanh O(1) theo ID, Code, Name và Gom nhóm theo BodyPart
            Map<UUID, Exercise> exerciseMap = availableExercises.stream()
                    .collect(Collectors.toMap(Exercise::getId, e -> e, (e1, e2) -> e1));
            Map<String, Exercise> codeMap = availableExercises.stream()
                    .collect(Collectors.toMap(e -> e.getCode().toLowerCase().trim(), e -> e, (e1, e2) -> e1));
            Map<String, Exercise> nameMap = availableExercises.stream()
                    .collect(Collectors.toMap(e -> e.getName().toLowerCase().trim(), e -> e, (e1, e2) -> e1));

            Map<String, List<Exercise>> bodyPartMap = new HashMap<>();
            for (Exercise ex : availableExercises) {
                if (ex.getBodyPart() != null && ex.getBodyPart().getCode() != null) {
                    bodyPartMap.computeIfAbsent(ex.getBodyPart().getCode().toUpperCase().trim(), k -> new ArrayList<>()).add(ex);
                }
            }

            // 3. Rút bộ khung lịch tập mẫu theo Mục tiêu (GoalType) và Nhóm cơ tập trung (FocusBodyPart)
            List<PresetWorkoutPlanData.PresetWorkoutDay> presetDays = PresetWorkoutPlanData
                    .getPresetForGoal(goalType, focusBodyPart);
            List<DailyWorkoutDTO> dailyWorkoutList = new ArrayList<>();

            // 4. Vòng lặp duyệt tạo lịch từng ngày (Dùng phép chia lấy dư % để xoay vòng lịch mẫu)
            for (int dayIdx = 0; dayIdx < days; dayIdx++) {
                LocalDate date = startDate.plusDays(dayIdx);
                PresetWorkoutPlanData.PresetWorkoutDay presetDay = presetDays.get(dayIdx % presetDays.size());
                List<DailyWorkoutItemDTO> workoutItems = new ArrayList<>();
                int itemOrder = 0;

                // 5. Duyệt từng bài tập trong khung mẫu và ghép nối với bài tập trong DB
                for (PresetWorkoutPlanData.PresetExerciseItem presetItem : presetDay.getExerciseItems()) {
                    Exercise matchedExercise = null;

                    // Step 5.1: Khớp bài tập theo Tên hoặc Mã bài tập
                    if (presetItem.getExerciseName() != null) {
                        matchedExercise = nameMap.get(presetItem.getExerciseName().toLowerCase().trim());
                        if (matchedExercise == null) {
                            matchedExercise = codeMap.get(presetItem.getExerciseName().toLowerCase().trim());
                        }
                    }

                    // Step 5.2: Kiểm tra chấn thương kép (Loại bỏ nếu vi phạm chấn thương người dùng)
                    if (matchedExercise != null && exerciseFilterService.isViolatingInjuries(matchedExercise, injuries)) {
                        matchedExercise = null;
                    }

                    // Step 5.3: Nếu không tìm thấy hoặc bị dính chấn thương -> Đổi sang bài tập an toàn cùng nhóm cơ (BodyPart Fallback)
                    if (matchedExercise == null && presetItem.getBodyPartCode() != null) {
                        List<Exercise> candidates = bodyPartMap.getOrDefault(presetItem.getBodyPartCode().toUpperCase().trim(), availableExercises);
                        matchedExercise = candidates.stream()
                                .filter(e -> !exerciseFilterService.isViolatingInjuries(e, injuries))
                                .findFirst()
                                .orElse(!availableExercises.isEmpty() ? availableExercises.get(0) : null);
                    }

                    // Step 5.4: Nếu tìm được bài tập hợp lệ, đóng gói DTO chứa đầy đủ thông số tập
                    if (matchedExercise != null) {
                        workoutItems.add(DailyWorkoutItemDTO.builder()
                                .exerciseId(matchedExercise.getId())
                                .exerciseName(matchedExercise.getName())
                                .sets(presetItem.getSets())
                                .reps(presetItem.getReps())
                                .weightKg(presetItem.getWeightKg())
                                .restSeconds(presetItem.getRestSeconds())
                                .durationMinutes(presetItem.getDurationMinutes())
                                .distanceKm(presetItem.getDistanceKm())
                                .caloriesBurned(presetItem.getCaloriesBurned())
                                .notes(presetItem.getNotes())
                                .orderIndex(itemOrder++)
                                .isCompleted(false)
                                .build());
                    }
                }

                // 6. Đóng gói danh sách bài tập vào DTO của ngày
                dailyWorkoutList.add(DailyWorkoutDTO.builder()
                        .date(date)
                        .note(noteMessage != null ? noteMessage : presetDay.getNote())
                        .isAiGenerated(false)
                        .workoutItems(workoutItems)
                        .build());
            }

            return objectMapper.writeValueAsString(dailyWorkoutList);
        } catch (Exception e) {
            log.error("❌ [PRESET_WORKOUT_FALLBACK_ERROR] Error generating preset fallback workout plan: ", e);
            return getFallbackWorkoutJson(startDate, noteMessage, days);
        }
    }

    public String generatePresetFallbackWorkoutPlan(UUID userId, LocalDate startDate, Integer days, String goalType,
            String noteMessage) {
        return generatePresetFallbackWorkoutPlan(userId, startDate, days, goalType, null, noteMessage);
    }

    public String getFallbackWorkoutJson(LocalDate startDate, String message, Integer days) {
        int actualDays = (days != null && days > 0) ? days : 7;
        try {
            List<DailyWorkoutDTO> fallbackList = new ArrayList<>();
            for (int i = 0; i < actualDays; i++) {
                LocalDate date = startDate.plusDays(i);
                fallbackList.add(DailyWorkoutDTO.builder()
                        .date(date)
                        .note(message != null ? message : "Lịch tập chuẩn cân bằng sức khỏe (Dự phòng hệ thống)")
                        .isAiGenerated(false)
                        .workoutItems(new ArrayList<>())
                        .build());
            }
            return objectMapper.writeValueAsString(fallbackList);
        } catch (Exception e) {
            return "[]";
        }
    }
}
