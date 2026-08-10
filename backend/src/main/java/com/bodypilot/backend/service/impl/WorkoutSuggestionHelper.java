package com.bodypilot.backend.service.impl;

import com.bodypilot.backend.model.dto.workout.DailyWorkoutDTO;
import com.bodypilot.backend.model.dto.workout.DailyWorkoutItemDTO;
import com.bodypilot.backend.model.dto.workout.ExerciseCandidate;
import com.bodypilot.backend.model.entity.health.Injury;
import com.bodypilot.backend.model.entity.workout.Exercise;
import com.bodypilot.backend.model.entity.workout.WorkoutPlan;
import com.bodypilot.backend.model.entity.user.*;
import com.bodypilot.backend.repository.*;
import com.fasterxml.jackson.databind.JsonNode;
import com.fasterxml.jackson.databind.ObjectMapper;
import com.fasterxml.jackson.databind.SerializationFeature;
import com.fasterxml.jackson.datatype.jsr310.JavaTimeModule;
import lombok.RequiredArgsConstructor;
import lombok.extern.slf4j.Slf4j;
import org.springframework.stereotype.Component;

import java.time.LocalDate;
import java.util.*;
import java.util.stream.Collectors;

@Component
@RequiredArgsConstructor
@Slf4j
public class WorkoutSuggestionHelper {

    private final ExerciseRepository exerciseRepository;
    private final UserInjuryRepository userInjuryRepository;
    private final ObjectMapper objectMapper = new ObjectMapper()
            .registerModule(new JavaTimeModule())
            .disable(SerializationFeature.WRITE_DATES_AS_TIMESTAMPS);

    public List<ExerciseCandidate> getBalancedExerciseCandidates(UUID userId, String goalType, String focusBodyPart) {
        List<UserInjury> injuries = userInjuryRepository.findAllByUserId(userId);
        List<Exercise> filteredExercises = getFilteredExercises(injuries);
        List<Exercise> limitedExercises = selectBalancedExercises(filteredExercises, 100, goalType, focusBodyPart);

        return limitedExercises.stream()
                .map(e -> new ExerciseCandidate(
                        e.getId(),
                        e.getName(),
                        e.getBodyPart() != null ? e.getBodyPart().getName() : "Không xác định",
                        e.getTargetMuscle() != null ? e.getTargetMuscle().getName() : "Không xác định",
                        e.getDifficulty() != null ? e.getDifficulty().name() : "BEGINNER"))
                .collect(Collectors.toList());
    }

    public List<ExerciseCandidate> getBalancedExerciseCandidates(UUID userId, String goalType) {
        return getBalancedExerciseCandidates(userId, goalType, null);
    }

    public String buildWorkoutPrompt(UserProfile profile, UserGoal goal, UserMetricHistory metric,
            List<UserInjury> injuries, List<ExerciseCandidate> candidates,
            LocalDate startDate, Integer days, String focusBodyPart) {
        StringBuilder sb = new StringBuilder();
        sb.append("Tạo lịch tập luyện thể thao trong ").append(days).append(" ngày liên tiếp bắt đầu từ ngày ")
                .append(startDate)
                .append(" dựa trên thông tin người dùng và danh sách bài tập được cung cấp dưới đây:\n\n");

        if (profile != null) {
            sb.append("- Giới tính: ").append(profile.getGender() != null ? profile.getGender() : "Chưa cập nhật")
                    .append("\n");
            sb.append("- Tuổi: ").append(profile.getAge() != null ? profile.getAge() : "Chưa cập nhật").append("\n");
            sb.append("- Chiều cao: ")
                    .append(profile.getHeightCm() != null ? profile.getHeightCm() + " cm" : "Chưa cập nhật")
                    .append("\n");
            sb.append("- Cân nặng hiện tại: ")
                    .append(profile.getWeight() != null ? profile.getWeight() + " kg" : "Chưa cập nhật").append("\n");
            sb.append("- Mức độ hoạt động: ")
                    .append(profile.getActivityLevel() != null ? translateActivityLevel(profile.getActivityLevel())
                            : "Chưa cập nhật")
                    .append("\n");
        }

        if (goal != null) {
            sb.append("- Mục tiêu thể hình: ").append(translateGoal(goal.getType())).append("\n");
            sb.append("- Cân nặng mục tiêu: ")
                    .append(goal.getTargetWeight() != null ? goal.getTargetWeight() + " kg" : "Chưa cập nhật")
                    .append("\n");
        }

        String focusText = (focusBodyPart != null && !focusBodyPart.trim().isEmpty()
                && !"NONE".equalsIgnoreCase(focusBodyPart) && !"KHÔNG CÓ".equalsIgnoreCase(focusBodyPart))
                        ? focusBodyPart
                        : "Không có";
        sb.append("- Bộ phận muốn tập chủ yếu: ").append(focusText).append("\n");

        if (!injuries.isEmpty()) {
            String injuryDetails = injuries.stream()
                    .map(i -> String.format("%s (Mức độ: %s)",
                            i.getInjury().getName(),
                            i.getSeverityOverride() != null ? i.getSeverityOverride()
                                    : i.getInjury().getSeverityLevel()))
                    .collect(Collectors.joining(", "));
            sb.append("- Chấn thương (BẮT BUỘC TRÁNH bài tập tác động xấu đến vùng này): ").append(injuryDetails)
                    .append("\n");
        }

        sb.append("\nDANH SÁCH BÀI TẬP ĐƯỢC PHÉP SỬ DỤNG TRONG DATABASE (CANDIDATES):\n");
        try {
            String jsonCandidates = objectMapper.writeValueAsString(candidates);
            sb.append(jsonCandidates).append("\n");
        } catch (Exception e) {
            sb.append("[]\n");
        }

        sb.append("\nYêu cầu định dạng đầu ra:\n");
        sb.append(
                "Hãy tự thiết kế một lịch tập mới hoàn toàn sử dụng các bài tập trong danh sách ứng viên (CANDIDATES) ở trên để tạo lịch tập gợi ý trong ")
                .append(days).append(" ngày liên tiếp bắt đầu từ ngày ").append(startDate).append(".\n");
        sb.append(
                "RÀNG BUỘC CỐT LÕI: Bạn CHỈ ĐƯỢC CHỌN bài tập từ danh sách cung cấp ở trên. Bắt buộc phải khớp đúng UUID của bài tập trong trường `exerciseId`. KHÔNG tự ý tạo bài tập mới.\n");
        sb.append(
                "Không được phép thêm bất kỳ chữ giải thích nào khác ngoài chuỗi JSON hợp lệ. Vui lòng cung cấp định dạng JSON chuẩn xác theo cấu trúc sau:\n");
        sb.append("[\n");
        sb.append("  {\n");
        sb.append("    \"date\": \"YYYY-MM-DD\",  // Ngày cụ thể của lịch tập (bắt đầu từ ").append(startDate)
                .append(" và tăng dần 1 ngày cho mỗi phần tử tiếp theo)\n");
        sb.append("    \"note\": \"Ghi chú ngày tập (ví dụ: Tập ngực & tay sau hoặc Ngày nghỉ ngơi phục hồi)\",\n");
        sb.append("    \"isAiGenerated\": true,\n");
        sb.append("    \"workoutItems\": [\n");
        sb.append("      {\n");
        sb.append("        \"orderIndex\": 0,\n");
        sb.append(
                "        \"exerciseId\": \"UUID của bài tập được chọn\", // Bắt buộc phải trùng với UUID của bài tập trong danh sách Candidates trên\n");
        sb.append("        \"sets\": 4,\n");
        sb.append("        \"reps\": 12,\n");
        sb.append("        \"weightKg\": 10.0, // Cân nặng tạ sử dụng (kg) (bằng 0 nếu tập bodyweight hoặc cardio)\n");
        sb.append("        \"restSeconds\": 60, // Thời gian nghỉ giữa các set (giây)\n");
        sb.append("        \"durationMinutes\": 10, // Tổng thời gian dự kiến (phút) của bài tập này\n");
        sb.append(
                "        \"distanceKm\": 0.0, // Quãng đường di chuyển bằng km (áp dụng cho chạy bộ, đạp xe... còn lại đặt null hoặc 0)\n");
        sb.append("        \"caloriesBurned\": 80.0, // Calo dự kiến đốt cháy (kcal)\n");
        sb.append("        \"notes\": \"Hướng dẫn thực hiện ngắn gọn cho bài tập này\"\n");
        sb.append("      }\n");
        sb.append("    ]\n");
        sb.append("  }\n");
        sb.append("]\n");

        return sb.toString();
    }

    public String buildWorkoutPrompt(UserProfile profile, UserGoal goal, UserMetricHistory metric,
            List<UserInjury> injuries, List<ExerciseCandidate> candidates,
            List<WorkoutPlan> existingPlans, LocalDate startDate, Integer days) {
        return buildWorkoutPrompt(profile, goal, metric, injuries, candidates, startDate, days, null);
    }

    public String processAndLinkExercises(String rawJson) {
        try {
            if (rawJson == null || rawJson.trim().isEmpty()) {
                return "[]";
            }
            String cleanedJson = rawJson.trim();
            if (cleanedJson.startsWith("```json")) {
                cleanedJson = cleanedJson.substring(7);
            } else if (cleanedJson.startsWith("```")) {
                cleanedJson = cleanedJson.substring(3);
            }
            if (cleanedJson.endsWith("```")) {
                cleanedJson = cleanedJson.substring(0, cleanedJson.length() - 3);
            }
            cleanedJson = cleanedJson.trim();

            JsonNode root = parseOrRepairJson(cleanedJson);
            if (!root.isArray()) {
                if (root.isObject()) {
                    if (root.has("days") && root.get("days").isArray()) {
                        root = root.get("days");
                    } else if (root.has("suggestions") && root.get("suggestions").isArray()) {
                        root = root.get("suggestions");
                    } else if (root.has("data") && root.get("data").isArray()) {
                        root = root.get("data");
                    } else if (root.has("result") && root.get("result").isArray()) {
                        root = root.get("result");
                    } else {
                        throw new RuntimeException(
                                "Cấu trúc JSON từ AI không hợp lệ: không tìm thấy danh sách ngày tập.");
                    }
                } else {
                    throw new RuntimeException("Cấu trúc JSON từ AI không hợp lệ.");
                }
            }

            List<Exercise> allExercises = exerciseRepository.findAll();
            Map<UUID, Exercise> exerciseMap = allExercises.stream()
                    .collect(Collectors.toMap(
                            Exercise::getId,
                            e -> e,
                            (e1, e2) -> e1));

            List<DailyWorkoutDTO> list = new ArrayList<>();
            for (JsonNode dayNode : root) {
                LocalDate date = LocalDate.parse(dayNode.path("date").asText());
                String note = dayNode.path("note").asText();
                boolean isAiGenerated = dayNode.path("isAiGenerated").asBoolean(true);

                List<DailyWorkoutItemDTO> items = new ArrayList<>();
                JsonNode itemsNode = dayNode.path("workoutItems");
                if (!itemsNode.isArray() && dayNode.has("items")) {
                    itemsNode = dayNode.get("items");
                }
                if (itemsNode.isArray()) {
                    int itemOrder = 0;
                    for (JsonNode itemNode : itemsNode) {
                        String exerciseIdStr = itemNode.has("exerciseId") && !itemNode.path("exerciseId").isNull()
                                ? itemNode.path("exerciseId").asText()
                                : null;
                        Integer orderIndex = itemNode.has("orderIndex") && !itemNode.path("orderIndex").isNull()
                                ? itemNode.path("orderIndex").asInt()
                                : ++itemOrder;
                        Boolean isCompleted = itemNode.has("isCompleted") && !itemNode.path("isCompleted").isNull()
                                ? itemNode.path("isCompleted").asBoolean()
                                : false;

                        Integer sets = itemNode.has("sets") && !itemNode.path("sets").isNull()
                                ? itemNode.path("sets").asInt()
                                : null;
                        Integer reps = itemNode.has("reps") && !itemNode.path("reps").isNull()
                                ? itemNode.path("reps").asInt()
                                : null;
                        Double weightKg = itemNode.has("weightKg") && !itemNode.path("weightKg").isNull()
                                ? itemNode.path("weightKg").asDouble()
                                : null;
                        Integer restSeconds = itemNode.has("restSeconds") && !itemNode.path("restSeconds").isNull()
                                ? itemNode.path("restSeconds").asInt()
                                : null;
                        Integer durationMinutes = itemNode.has("durationMinutes")
                                && !itemNode.path("durationMinutes").isNull() ? itemNode.path("durationMinutes").asInt()
                                        : null;
                        Double distanceKm = itemNode.has("distanceKm") && !itemNode.path("distanceKm").isNull()
                                ? itemNode.path("distanceKm").asDouble()
                                : null;
                        Double caloriesBurned = itemNode.has("caloriesBurned")
                                && !itemNode.path("caloriesBurned").isNull()
                                        ? itemNode.path("caloriesBurned").asDouble()
                                        : 0.0;
                        String itemNotes = itemNode.path("notes").asText();

                        UUID exerciseId = null;
                        Exercise exercise = null;
                        boolean isCustom = true;
                        String exerciseName = "Bài tập không xác định";

                        if (exerciseIdStr != null && !exerciseIdStr.trim().isEmpty()) {
                            try {
                                exerciseId = UUID.fromString(exerciseIdStr);
                                exercise = exerciseMap.get(exerciseId);
                            } catch (Exception e) {
                                // ignore
                            }
                        }

                        if (exercise != null) {
                            exerciseName = exercise.getName();
                            isCustom = false;
                            if (durationMinutes == null && exercise.getDefaultDuration() != null) {
                                durationMinutes = exercise.getDefaultDuration().intValue();
                            }
                        } else {
                            exerciseName = itemNode.path("exerciseName").asText("Bài tập tự do");
                        }

                        items.add(DailyWorkoutItemDTO.builder()
                                .exerciseId(exerciseId)
                                .orderIndex(orderIndex)
                                .isCompleted(isCompleted)
                                .exerciseName(exerciseName)
                                .sets(sets)
                                .reps(reps)
                                .weightKg(weightKg)
                                .restSeconds(restSeconds)
                                .durationMinutes(durationMinutes)
                                .distanceKm(distanceKm)
                                .caloriesBurned(caloriesBurned)
                                .isCustom(isCustom)
                                .notes(itemNotes)
                                .build());
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
            return rawJson;
        }
    }

    public String generatePresetFallbackWorkoutPlan(UUID userId, LocalDate startDate, Integer days, String goalType, String focusBodyPart, String noteMessage) {
        log.info("📋 [PRESET_WORKOUT_FALLBACK] Generating preset fallback workout plan for userId={}, startDate={}, days={}, goalType={}, focusBodyPart={}",
                userId, startDate, days, goalType, focusBodyPart);
        try {
            List<UserInjury> injuries = (userId != null) ? userInjuryRepository.findAllByUserId(userId) : new ArrayList<>();
            List<Exercise> availableExercises = getFilteredExercises(injuries);
            Map<UUID, Exercise> exerciseMap = availableExercises.stream()
                    .collect(Collectors.toMap(Exercise::getId, e -> e, (e1, e2) -> e1));
            Map<String, Exercise> nameMap = availableExercises.stream()
                    .collect(Collectors.toMap(e -> e.getName().toLowerCase().trim(), e -> e, (e1, e2) -> e1));

            Map<String, List<Exercise>> bodyPartMap = new HashMap<>();
            for (Exercise ex : availableExercises) {
                if (ex.getBodyPart() != null && ex.getBodyPart().getCode() != null) {
                    String code = ex.getBodyPart().getCode().toUpperCase().trim();
                    bodyPartMap.computeIfAbsent(code, k -> new ArrayList<>()).add(ex);
                }
            }

            List<PresetWorkoutPlanData.PresetWorkoutDay> presetDays = PresetWorkoutPlanData.getPresetForGoal(goalType, focusBodyPart);
            List<DailyWorkoutDTO> dailyWorkoutList = new ArrayList<>();

            for (int dayIdx = 0; dayIdx < days; dayIdx++) {
                LocalDate date = startDate.plusDays(dayIdx);
                PresetWorkoutPlanData.PresetWorkoutDay presetDay = presetDays.get(dayIdx % presetDays.size());

                List<DailyWorkoutItemDTO> workoutItems = new ArrayList<>();
                int itemOrder = 0;

                for (PresetWorkoutPlanData.PresetExerciseItem presetItem : presetDay.getExerciseItems()) {
                    Exercise matchedExercise = nameMap.get(presetItem.getExerciseName().toLowerCase().trim());
                    if (matchedExercise == null) {
                        String exName = presetItem.getExerciseName().toLowerCase();
                        matchedExercise = availableExercises.stream()
                                .filter(e -> e.getName().toLowerCase().contains(exName)
                                        || exName.contains(e.getName().toLowerCase()))
                                .findFirst()
                                .orElse(null);
                    }

                    if (matchedExercise != null && isViolatingInjuries(matchedExercise, injuries)) {
                        matchedExercise = null;
                    }

                    if (matchedExercise == null) {
                        String bodyPartCode = presetItem.getBodyPartCode();
                        List<Exercise> candidates = bodyPartMap.getOrDefault(bodyPartCode != null ? bodyPartCode.toUpperCase() : "CARDIO", availableExercises);
                        if (candidates.isEmpty()) candidates = availableExercises;

                        matchedExercise = candidates.stream()
                                .filter(e -> !isViolatingInjuries(e, injuries))
                                .findFirst()
                                .orElse(!availableExercises.isEmpty() ? availableExercises.get(0) : null);
                    }

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

    private boolean isViolatingInjuries(Exercise e, List<UserInjury> injuries) {
        if (e == null) return true;
        if (injuries == null || injuries.isEmpty()) return false;
        for (UserInjury userInjury : injuries) {
            Injury injury = userInjury.getInjury();
            if (injury == null) continue;
            if (injury.getRestrictedExercises() != null && injury.getRestrictedExercises().contains(e.getCode())) {
                return true;
            }
            if (injury.getBodyPart() != null && e.getBodyPart() != null && injury.getBodyPart().getId().equals(e.getBodyPart().getId())) {
                return true;
            }
        }
        return false;
    }

    public String getFallbackWorkoutJson(LocalDate startDate, String message, Integer days) {
        try {
            List<DailyWorkoutDTO> fallbackList = new ArrayList<>();
            for (int i = 0; i < days; i++) {
                LocalDate date = startDate.plusDays(i);
                fallbackList.add(DailyWorkoutDTO.builder()
                        .date(date)
                        .note(message)
                        .isAiGenerated(false)
                        .workoutItems(new ArrayList<>())
                        .build());
            }
            return objectMapper.writeValueAsString(fallbackList);
        } catch (Exception e) {
            return "[]";
        }
    }

    private List<Exercise> getFilteredExercises(List<UserInjury> injuries) {
        List<Exercise> exercises = exerciseRepository.findAll();

        if (injuries == null || injuries.isEmpty()) {
            return exercises;
        }

        Set<String> restrictedExerciseCodes = new HashSet<>();
        Set<UUID> restrictedBodyPartIds = new HashSet<>();

        for (UserInjury userInjury : injuries) {
            Injury injury = userInjury.getInjury();
            if (injury == null)
                continue;

            if (injury.getRestrictedExercises() != null) {
                restrictedExerciseCodes.addAll(injury.getRestrictedExercises());
            }
            if (injury.getBodyPart() != null) {
                restrictedBodyPartIds.add(injury.getBodyPart().getId());
            }
        }

        return exercises.stream()
                .filter(e -> !restrictedExerciseCodes.contains(e.getCode()))
                .filter(e -> e.getBodyPart() == null || !restrictedBodyPartIds.contains(e.getBodyPart().getId()))
                .collect(Collectors.toList());
    }

    private List<Exercise> selectBalancedExercises(List<Exercise> exercises, int limit, String goalType,
            String focusBodyPart) {
        if (exercises.size() <= limit) {
            return exercises;
        }

        Random random = new Random();
        Map<Exercise, Double> exerciseScores = new HashMap<>();
        for (Exercise ex : exercises) {
            double score = calculateExerciseScore(ex, goalType, focusBodyPart) + (random.nextDouble() * 15.0);
            exerciseScores.put(ex, score);
        }

        List<Exercise> sortedExercises = new ArrayList<>(exercises);
        sortedExercises.sort((e1, e2) -> Double.compare(exerciseScores.get(e2), exerciseScores.get(e1)));

        List<Exercise> selected = new ArrayList<>();
        Set<UUID> selectedIds = new HashSet<>();

        // Tier 1: Scarce Categories (Cardio, Aerobics, Yoga) -> Include 100% of
        // available exercises
        List<Exercise> scarceExercises = sortedExercises.stream()
                .filter(e -> {
                    if (e.getCategory() == null)
                        return false;
                    String catName = e.getCategory().getName() != null ? e.getCategory().getName().toLowerCase() : "";
                    String catCode = e.getCategory().getCode() != null ? e.getCategory().getCode().toLowerCase() : "";
                    return catName.contains("tim mạch") || catName.contains("cardio") ||
                            catName.contains("nhịp điệu") || catName.contains("aerobic") ||
                            catName.contains("yoga");
                })
                .collect(Collectors.toList());

        for (Exercise ex : scarceExercises) {
            if (selected.size() < limit && selectedIds.add(ex.getId())) {
                selected.add(ex);
            }
        }

        // Tier 2: Focus Body Part Exercises (if user selected a specific focus body
        // part)
        if (focusBodyPart != null && !focusBodyPart.isBlank() && !"NONE".equalsIgnoreCase(focusBodyPart)
                && !"KHÔNG CÓ".equalsIgnoreCase(focusBodyPart)) {
            String focusUpper = focusBodyPart.toUpperCase();
            List<Exercise> focusExercises = sortedExercises.stream()
                    .filter(e -> !selectedIds.contains(e.getId()))
                    .filter(e -> {
                        boolean matchBody = e.getBodyPart() != null && e.getBodyPart().getName() != null &&
                                (e.getBodyPart().getName().toUpperCase().contains(focusUpper) ||
                                        (e.getBodyPart().getCode() != null
                                                && focusUpper.contains(e.getBodyPart().getCode().toUpperCase())));
                        boolean matchTarget = e.getTargetMuscle() != null && e.getTargetMuscle().getName() != null &&
                                e.getTargetMuscle().getName().toUpperCase().contains(focusUpper);
                        return matchBody || matchTarget;
                    })
                    .collect(Collectors.toList());

            int focusQuota = Math.min(40, focusExercises.size());
            for (int i = 0; i < focusQuota && selected.size() < limit; i++) {
                Exercise ex = focusExercises.get(i);
                if (selectedIds.add(ex.getId())) {
                    selected.add(ex);
                }
            }
        }

        // Tier 3: Goal-driven Category Quotas for remaining slots
        int remainingSlots = limit - selected.size();
        Map<String, List<Exercise>> categoryMap = new HashMap<>();
        for (Exercise ex : sortedExercises) {
            if (!selectedIds.contains(ex.getId())) {
                String catName = ex.getCategory() != null && ex.getCategory().getName() != null
                        ? ex.getCategory().getName()
                        : "Khác";
                categoryMap.computeIfAbsent(catName, k -> new ArrayList<>()).add(ex);
            }
        }

        Map<String, Integer> categoryQuotas = getGoalCategoryQuotas(goalType, remainingSlots);

        for (Map.Entry<String, List<Exercise>> entry : categoryMap.entrySet()) {
            String catName = entry.getKey();
            List<Exercise> catExs = entry.getValue();

            int quota = getCategoryQuotaForName(catName, categoryQuotas);
            int count = 0;
            for (Exercise ex : catExs) {
                if (count >= quota || selected.size() >= limit)
                    break;
                if (selectedIds.add(ex.getId())) {
                    selected.add(ex);
                    count++;
                }
            }
        }

        // Tier 4: Fill remaining slots up to limit (100) with top scoring exercises
        for (Exercise ex : sortedExercises) {
            if (selected.size() >= limit)
                break;
            if (selectedIds.add(ex.getId())) {
                selected.add(ex);
            }
        }

        return selected;
    }

    private Map<String, Integer> getGoalCategoryQuotas(String goalType, int remainingSlots) {
        Map<String, Integer> quotas = new HashMap<>();
        if (goalType == null)
            goalType = "MAINTAIN";

        switch (goalType) {
            case "GAIN_MUSCLE", "GAIN_0_5KG", "GAIN_1KG" -> {
                quotas.put("Sức mạnh", (int) (remainingSlots * 0.65));
                quotas.put("Cử tạ", (int) (remainingSlots * 0.15));
                quotas.put("Giãn cơ", (int) (remainingSlots * 0.12));
                quotas.put("Bật nhảy", (int) (remainingSlots * 0.08));
            }
            case "LOSE_0_5KG", "LOSE_1KG" -> {
                quotas.put("Sức mạnh", (int) (remainingSlots * 0.50));
                quotas.put("Bật nhảy", (int) (remainingSlots * 0.25));
                quotas.put("Giãn cơ", (int) (remainingSlots * 0.15));
                quotas.put("Cử tạ", (int) (remainingSlots * 0.10));
            }
            case "ENDURANCE" -> {
                quotas.put("Sức mạnh", (int) (remainingSlots * 0.45));
                quotas.put("Bật nhảy", (int) (remainingSlots * 0.30));
                quotas.put("Giãn cơ", (int) (remainingSlots * 0.15));
                quotas.put("Cử tạ", (int) (remainingSlots * 0.10));
            }
            default -> {
                quotas.put("Sức mạnh", (int) (remainingSlots * 0.55));
                quotas.put("Giãn cơ", (int) (remainingSlots * 0.20));
                quotas.put("Bật nhảy", (int) (remainingSlots * 0.15));
                quotas.put("Cử tạ", (int) (remainingSlots * 0.10));
            }
        }
        return quotas;
    }

    private int getCategoryQuotaForName(String catName, Map<String, Integer> quotas) {
        if (catName == null)
            return 15;
        for (Map.Entry<String, Integer> entry : quotas.entrySet()) {
            if (catName.toLowerCase().contains(entry.getKey().toLowerCase())) {
                return Math.max(5, entry.getValue());
            }
        }
        return 15;
    }

    private double calculateExerciseScore(Exercise exercise, String goalType, String focusBodyPart) {
        double score = 50.0;
        double met = exercise.getMetValue() != null ? exercise.getMetValue() : 3.0;

        if (focusBodyPart != null && !focusBodyPart.isBlank()) {
            String focusUpper = focusBodyPart.toUpperCase();
            boolean matchesBodyPart = exercise.getBodyPart() != null && exercise.getBodyPart().getName() != null &&
                    (exercise.getBodyPart().getName().toUpperCase().contains(focusUpper) || focusUpper.contains(
                            exercise.getBodyPart().getCode() != null ? exercise.getBodyPart().getCode().toUpperCase()
                                    : ""));
            boolean matchesTarget = exercise.getTargetMuscle() != null && exercise.getTargetMuscle().getName() != null
                    &&
                    exercise.getTargetMuscle().getName().toUpperCase().contains(focusUpper);
            if (matchesBodyPart || matchesTarget) {
                score += 60.0;
            }
        }

        if (goalType == null)
            return score + met * 2.0;

        return score + switch (goalType) {
            case "LOSE_0_5KG", "LOSE_1KG" -> {
                double boost = 0.0;
                if (exercise.getCategory() != null) {
                    String catCode = exercise.getCategory().getCode() != null
                            ? exercise.getCategory().getCode().toUpperCase()
                            : "";
                    if (catCode.contains("CARDIO") || catCode.contains("HIIT") || catCode.contains("BODYWEIGHT")) {
                        boost = 30.0;
                    }
                }
                yield (met * 5.0) + boost;
            }
            case "GAIN_MUSCLE" -> {
                double eqBoost = 0.0;
                if (exercise.getEquipment() != null) {
                    for (String eq : exercise.getEquipment()) {
                        String eqUpper = eq.toUpperCase();
                        if (eqUpper.contains("BARBELL") || eqUpper.contains("DUMBBELL") || eqUpper.contains("MACHINE")
                                || eqUpper.contains("CABLE")) {
                            eqBoost += 10.0;
                        }
                    }
                }
                double catBoost = 0.0;
                if (exercise.getCategory() != null) {
                    String catCode = exercise.getCategory().getCode() != null
                            ? exercise.getCategory().getCode().toUpperCase()
                            : "";
                    if (catCode.contains("STRENGTH") || catCode.contains("WEIGHTS") || catCode.contains("RESISTANCE")) {
                        catBoost = 30.0;
                    }
                }
                yield eqBoost + catBoost;
            }
            case "GAIN_0_5KG", "GAIN_1KG" -> {
                double boost = 0.0;
                if (exercise.getCategory() != null) {
                    String catCode = exercise.getCategory().getCode() != null
                            ? exercise.getCategory().getCode().toUpperCase()
                            : "";
                    if (catCode.contains("STRENGTH") || catCode.contains("RESISTANCE")) {
                        boost = 25.0;
                    }
                }
                yield boost;
            }
            case "ENDURANCE" -> {
                double boost = 0.0;
                if (exercise.getCategory() != null) {
                    String catCode = exercise.getCategory().getCode() != null
                            ? exercise.getCategory().getCode().toUpperCase()
                            : "";
                    if (catCode.contains("CARDIO") || catCode.contains("ENDURANCE") || catCode.contains("STRETCH")) {
                        boost = 25.0;
                    }
                }
                yield (met * 6.0) + boost;
            }
            default -> met * 2.0;
        };
    }

    private String translateGoal(String goal) {
        if (goal == null)
            return null;
        return switch (goal) {
            case "MAINTAIN" -> "Duy trì cân nặng";
            case "LOSE_0_5KG" -> "Giảm cân chậm (0.5 kg/tuần)";
            case "LOSE_1KG" -> "Giảm cân nhanh (1.0 kg/tuần)";
            case "GAIN_MUSCLE" -> "Tăng cơ giảm mỡ";
            case "HEALTHY_LIFESTYLE" -> "Lối sống lành mạnh, ăn sạch";
            case "ENDURANCE" -> "Tăng thể lực & sức bền";
            default -> goal;
        };
    }

    private String translateActivityLevel(String level) {
        if (level == null)
            return null;
        return switch (level) {
            case "SEDENTARY" -> "Ít vận động (nhân viên văn phòng, ít tập thể dục)";
            case "LIGHTLY_ACTIVE" -> "Vận động nhẹ (tập thể dục 1-3 ngày/tuần)";
            case "MODERATELY_ACTIVE" -> "Vận động vừa phải (tập thể dục 3-5 ngày/tuần)";
            case "VERY_ACTIVE" -> "Vận động nhiều (tập thể thao nặng 6-7 ngày/tuần)";
            case "EXTRA_ACTIVE" -> "Vận động cực kỳ nhiều (vận động viên, công việc lao động rất nặng)";
            default -> level;
        };
    }

    private JsonNode parseOrRepairJson(String cleanedJson) throws Exception {
        try {
            return objectMapper.readTree(cleanedJson);
        } catch (Exception parseException) {
            log.warn("⚠️ AI Workout JSON response appeared incomplete/truncated. Attempting auto-repair...");
            JsonNode repairedNode = repairTruncatedJsonNode(cleanedJson);
            if (repairedNode != null) {
                return repairedNode;
            }
            throw parseException;
        }
    }

    private JsonNode repairTruncatedJsonNode(String json) {
        if (json == null || json.trim().isEmpty())
            return null;
        String trimmed = json.trim();

        int startIdx = -1;
        for (int i = 0; i < trimmed.length(); i++) {
            char c = trimmed.charAt(i);
            if (c == '[' || c == '{') {
                startIdx = i;
                break;
            }
        }
        if (startIdx == -1)
            return null;
        trimmed = trimmed.substring(startIdx);

        for (int len = trimmed.length(); len > 0; len--) {
            String candidate = trimmed.substring(0, len);
            String repairedStr = tryRepairCandidate(candidate);
            if (repairedStr != null) {
                try {
                    JsonNode node = objectMapper.readTree(repairedStr);
                    if (node != null && (node.isArray() || node.isObject())) {
                        int size = node.isArray() ? node.size() : (node.fieldNames().hasNext() ? 1 : 0);
                        if (size > 0) {
                            log.info("✅ Auto-repaired truncated AI Workout JSON! Preserved valid structure (size: {}).", size);
                            return node;
                        }
                    }
                } catch (Exception ignored) {
                }
            }
        }
        return null;
    }

    private String tryRepairCandidate(String candidate) {
        if (candidate == null || candidate.isEmpty())
            return null;

        StringBuilder sb = new StringBuilder(candidate);
        Deque<Character> stack = new ArrayDeque<>();
        boolean inString = false;
        boolean escaped = false;

        for (int i = 0; i < candidate.length(); i++) {
            char c = candidate.charAt(i);
            if (inString) {
                if (escaped) {
                    escaped = false;
                } else if (c == '\\') {
                    escaped = true;
                } else if (c == '"') {
                    inString = false;
                }
            } else {
                if (c == '"') {
                    inString = true;
                } else if (c == '{' || c == '[') {
                    stack.push(c);
                } else if (c == '}') {
                    if (!stack.isEmpty() && stack.peek() == '{') {
                        stack.pop();
                    }
                } else if (c == ']') {
                    if (!stack.isEmpty() && stack.peek() == '[') {
                        stack.pop();
                    }
                }
            }
        }

        if (inString) {
            sb.append('"');
        }

        String current = sb.toString().trim();

        while (current.endsWith(",") || current.endsWith(":") || current.endsWith("{,") || current.endsWith("[,") || current.endsWith("\":")) {
            if (current.endsWith(",")) {
                current = current.substring(0, current.length() - 1).trim();
            } else if (current.endsWith(":")) {
                current = current.substring(0, current.length() - 1).trim();
                if (current.endsWith("\"")) {
                    int lastQuote = current.lastIndexOf('"', current.length() - 2);
                    if (lastQuote != -1) {
                        current = current.substring(0, lastQuote).trim();
                    }
                }
            }
        }

        if (current.endsWith(",")) {
            current = current.substring(0, current.length() - 1).trim();
        }

        stack.clear();
        inString = false;
        escaped = false;
        for (int i = 0; i < current.length(); i++) {
            char c = current.charAt(i);
            if (inString) {
                if (escaped) {
                    escaped = false;
                } else if (c == '\\') {
                    escaped = true;
                } else if (c == '"') {
                    inString = false;
                }
            } else {
                if (c == '"') {
                    inString = true;
                } else if (c == '{' || c == '[') {
                    stack.push(c);
                } else if (c == '}') {
                    if (!stack.isEmpty() && stack.peek() == '{') {
                        stack.pop();
                    }
                } else if (c == ']') {
                    if (!stack.isEmpty() && stack.peek() == '[') {
                        stack.pop();
                    }
                }
            }
        }

        if (inString) {
            current += "\"";
        }
        if (current.endsWith(",")) {
            current = current.substring(0, current.length() - 1).trim();
        }

        StringBuilder suffix = new StringBuilder();
        while (!stack.isEmpty()) {
            char open = stack.pop();
            if (open == '{') {
                suffix.append('}');
            } else if (open == '[') {
                suffix.append(']');
            }
        }

        return current + suffix.toString();
    }
}
