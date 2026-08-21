package com.bodypilot.backend.service.impl.workout;

import java.time.LocalDate;
import java.util.ArrayList;
import java.util.List;
import java.util.Map;
import java.util.UUID;
import java.util.stream.Collectors;

import org.springframework.stereotype.Component;

import com.bodypilot.backend.model.dto.workout.DailyWorkoutDTO;
import com.bodypilot.backend.model.dto.workout.DailyWorkoutItemDTO;
import com.bodypilot.backend.model.entity.workout.Exercise;
import com.bodypilot.backend.repository.ExerciseRepository;

import com.fasterxml.jackson.annotation.JsonIgnoreProperties;
import com.fasterxml.jackson.databind.DeserializationFeature;
import com.fasterxml.jackson.databind.ObjectMapper;
import com.fasterxml.jackson.databind.SerializationFeature;
import com.fasterxml.jackson.datatype.jsr310.JavaTimeModule;

import lombok.AllArgsConstructor;
import lombok.Data;
import lombok.NoArgsConstructor;
import lombok.RequiredArgsConstructor;
import lombok.extern.slf4j.Slf4j;

/**
 * Component dedicated to parsing and post-processing AI Workout JSON responses
 * using strongly-typed fail-safe Raw DTOs.
 */
@Component
@RequiredArgsConstructor
@Slf4j
public class WorkoutJsonPostProcessor {

    private final ExerciseRepository exerciseRepository;

    private final ObjectMapper objectMapper = new ObjectMapper()
            .registerModule(new JavaTimeModule())
            .disable(SerializationFeature.WRITE_DATES_AS_TIMESTAMPS)
            .configure(DeserializationFeature.FAIL_ON_UNKNOWN_PROPERTIES, false)
            .configure(com.fasterxml.jackson.core.JsonParser.Feature.ALLOW_UNQUOTED_FIELD_NAMES, true)
            .configure(com.fasterxml.jackson.core.JsonParser.Feature.ALLOW_SINGLE_QUOTES, true)
            .configure(com.fasterxml.jackson.core.JsonParser.Feature.ALLOW_COMMENTS, true)
            .configure(com.fasterxml.jackson.core.JsonParser.Feature.ALLOW_TRAILING_COMMA, true)
            .configure(com.fasterxml.jackson.core.JsonParser.Feature.ALLOW_UNQUOTED_CONTROL_CHARS, true)
            .configure(com.fasterxml.jackson.core.JsonParser.Feature.ALLOW_BACKSLASH_ESCAPING_ANY_CHARACTER, true);

    public String processAndLinkExercises(String rawJson) {
        try {
            if (rawJson == null || rawJson.trim().isEmpty()) {
                return "[]";
            }
            String cleanedJson = cleanMarkdownJson(rawJson);

            // Ép trực tiếp chuỗi JSON thành mảng Raw DTOs (Fail-safe, 0-crash)
            RawDailyWorkout[] rawDays = objectMapper.readValue(cleanedJson, RawDailyWorkout[].class);

            List<Exercise> allExercises = exerciseRepository.findAll();
            Map<UUID, Exercise> exerciseMap = allExercises.stream()
                    .collect(Collectors.toMap(Exercise::getId, e -> e, (e1, e2) -> e1));
            Map<String, Exercise> nameMap = allExercises.stream()
                    .collect(Collectors.toMap(e -> e.getName().toLowerCase().trim(), e -> e, (e1, e2) -> e1));

            List<DailyWorkoutDTO> list = new ArrayList<>();
            for (RawDailyWorkout rawDay : rawDays) {
                LocalDate date = (rawDay.getDate() != null && !rawDay.getDate().isEmpty())
                        ? LocalDate.parse(rawDay.getDate())
                        : LocalDate.now();
                String note = (rawDay.getNote() != null) ? rawDay.getNote() : "";
                boolean isAiGenerated = Boolean.TRUE.equals(rawDay.getIsAiGenerated());

                List<DailyWorkoutItemDTO> items = new ArrayList<>();
                if (rawDay.getWorkoutItems() != null) {
                    int itemOrder = 0;
                    for (RawWorkoutItem rawItem : rawDay.getWorkoutItems()) {
                        String exerciseIdStr = (rawItem.getExerciseId() != null) ? rawItem.getExerciseId().trim() : "";
                        String exerciseNameStr = (rawItem.getExerciseName() != null) ? rawItem.getExerciseName().trim() : "";

                        Exercise exercise = matchExerciseInDatabase(exerciseIdStr, exerciseNameStr, exerciseMap, nameMap, allExercises);

                        if (exercise != null) {
                            items.add(DailyWorkoutItemDTO.builder()
                                    .exerciseId(exercise.getId())
                                    .exerciseName(exercise.getName())
                                    .orderIndex(rawItem.getOrderIndex() != null ? rawItem.getOrderIndex() : ++itemOrder)
                                    .isCompleted(Boolean.TRUE.equals(rawItem.getIsCompleted()))
                                    .sets(rawItem.getSets())
                                    .reps(rawItem.getReps())
                                    .weightKg(rawItem.getWeightKg())
                                    .restSeconds(rawItem.getRestSeconds())
                                    .durationMinutes(rawItem.getDurationMinutes())
                                    .distanceKm(rawItem.getDistanceKm())
                                    .caloriesBurned(rawItem.getCaloriesBurned())
                                    .notes(rawItem.getNotes() != null ? rawItem.getNotes() : "")
                                    .build());
                        } else {
                            log.warn("Suggested exercise ID [{}] / Name [{}] not found in database.", exerciseIdStr, exerciseNameStr);
                        }
                    }
                }

                list.add(DailyWorkoutDTO.builder()
                        .date(date)
                        .note(note)
                        .isAiGenerated(isAiGenerated)
                        .workoutItems(items)
                        .build());
            }

            return objectMapper.writeValueAsString(list);
        } catch (Exception e) {
            log.error("Error post-processing AI workout suggestion JSON: ", e);
            throw new RuntimeException("Lỗi đọc dữ liệu JSON lịch tập từ AI: " + e.getMessage(), e);
        }
    }

    private String cleanMarkdownJson(String rawJson) {
        if (rawJson == null) return "[]";
        String cleaned = rawJson.trim();
        if (cleaned.startsWith("```json")) {
            cleaned = cleaned.substring(7);
        } else if (cleaned.startsWith("```")) {
            cleaned = cleaned.substring(3);
        }
        if (cleaned.endsWith("```")) {
            cleaned = cleaned.substring(0, cleaned.length() - 3);
        }
        cleaned = cleaned.trim();

        int firstBracket = cleaned.indexOf('[');
        int lastBracket = cleaned.lastIndexOf(']');
        if (firstBracket != -1 && lastBracket != -1 && lastBracket > firstBracket) {
            cleaned = cleaned.substring(firstBracket, lastBracket + 1);
        }
        // Xóa dấu phẩy thừa trước ngoặc đóng
        cleaned = cleaned.replaceAll(",\\s*([\\]}])", "$1");
        return cleaned.trim();
    }

    private Exercise matchExerciseInDatabase(String exerciseIdStr, String exerciseNameStr,
            Map<UUID, Exercise> exerciseMap, Map<String, Exercise> nameMap, List<Exercise> allExercises) {
        Exercise exercise = null;
        if (!exerciseIdStr.isEmpty()) {
            try {
                UUID exerciseId = UUID.fromString(exerciseIdStr);
                exercise = exerciseMap.get(exerciseId);
            } catch (Exception ignored) {
            }
        }
        if (exercise == null && !exerciseNameStr.isEmpty()) {
            exercise = nameMap.get(exerciseNameStr.toLowerCase());
        }
        if (exercise == null && !exerciseNameStr.isEmpty()) {
            String key = exerciseNameStr.toLowerCase();
            exercise = allExercises.stream()
                    .filter(e -> e.getName().toLowerCase().contains(key) || key.contains(e.getName().toLowerCase()))
                    .findFirst()
                    .orElse(null);
        }
        return exercise;
    }

    // =========================================================================
    // DTOs TẠM HỨNG DỮ LIỆU THÔ TỪ AI (FAIL-SAFE, IGNORE UNKNOWN PROPERTIES)
    // =========================================================================

    @Data
    @NoArgsConstructor
    @AllArgsConstructor
    @JsonIgnoreProperties(ignoreUnknown = true)
    public static class RawDailyWorkout {
        private String date;
        private String note = "";
        private Boolean isAiGenerated = true;
        private List<RawWorkoutItem> workoutItems = new ArrayList<>();
    }

    @Data
    @NoArgsConstructor
    @AllArgsConstructor
    @JsonIgnoreProperties(ignoreUnknown = true)
    public static class RawWorkoutItem {
        private String exerciseId = "";
        private String exerciseName = "";
        private Integer orderIndex = 0;
        private Boolean isCompleted = false;
        private Integer sets;
        private Integer reps;
        private Double weightKg;
        private Integer restSeconds;
        private Integer durationMinutes;
        private Double distanceKm;
        private Double caloriesBurned;
        private String notes = "";
    }
}
