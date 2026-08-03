package com.bodypilot.backend.service.impl;

import com.bodypilot.backend.model.dto.workout.DailyWorkoutDTO;
import com.bodypilot.backend.model.dto.workout.DailyWorkoutItemDTO;
import com.bodypilot.backend.model.dto.workout.ExerciseCandidate;
import com.bodypilot.backend.model.entity.health.Injury;
import com.bodypilot.backend.model.entity.workout.Exercise;
import com.bodypilot.backend.model.entity.workout.WorkoutPlan;
import com.bodypilot.backend.model.entity.workout.WorkoutSession;
import com.bodypilot.backend.model.entity.workout.WorkoutSessionExercise;
import com.bodypilot.backend.model.entity.user.*;
import com.bodypilot.backend.repository.*;
import com.fasterxml.jackson.databind.JsonNode;
import com.fasterxml.jackson.databind.ObjectMapper;
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
    private final ObjectMapper objectMapper = new ObjectMapper();

    public List<ExerciseCandidate> getBalancedExerciseCandidates(UUID userId, String goalType) {
        List<UserInjury> injuries = userInjuryRepository.findAllByUserId(userId);
        List<Exercise> filteredExercises = getFilteredExercises(injuries);
        List<Exercise> limitedExercises = selectBalancedExercises(filteredExercises, 50, goalType);

        return limitedExercises.stream()
                .map(e -> new ExerciseCandidate(
                        e.getId(),
                        e.getName(),
                        e.getBodyPart() != null ? e.getBodyPart().getName() : "Không xác định",
                        e.getTargetMuscle() != null ? e.getTargetMuscle().getName() : "Không xác định",
                        e.getDifficulty() != null ? e.getDifficulty().name() : "BEGINNER",
                        e.getEquipment()
                ))
                .collect(Collectors.toList());
    }

    public String buildWorkoutPrompt(UserProfile profile, UserGoal goal, UserMetricHistory metric,
                                     List<UserInjury> injuries, List<ExerciseCandidate> candidates, 
                                     List<WorkoutPlan> existingPlans, LocalDate startDate, Integer days) {
        StringBuilder sb = new StringBuilder();
        sb.append("Tạo lịch tập luyện thể thao trong ").append(days).append(" ngày liên tiếp bắt đầu từ ngày ").append(startDate).append(" dựa trên thông tin người dùng và danh sách bài tập được cung cấp dưới đây:\n\n");

        if (profile != null) {
            sb.append("- Giới tính: ").append(profile.getGender() != null ? profile.getGender() : "Chưa cập nhật").append("\n");
            sb.append("- Tuổi: ").append(profile.getAge() != null ? profile.getAge() : "Chưa cập nhật").append("\n");
            sb.append("- Chiều cao: ").append(profile.getHeightCm() != null ? profile.getHeightCm() + " cm" : "Chưa cập nhật").append("\n");
            sb.append("- Cân nặng hiện tại: ").append(profile.getWeight() != null ? profile.getWeight() + " kg" : "Chưa cập nhật").append("\n");
            sb.append("- Mức độ hoạt động: ").append(profile.getActivityLevel() != null ? translateActivityLevel(profile.getActivityLevel()) : "Chưa cập nhật").append("\n");
        }

        if (goal != null) {
            sb.append("- Mục tiêu thể hình: ").append(translateGoal(goal.getType())).append("\n");
            sb.append("- Cân nặng mục tiêu: ").append(goal.getTargetWeight() != null ? goal.getTargetWeight() + " kg" : "Chưa cập nhật").append("\n");
        }

        if (!injuries.isEmpty()) {
            String injuryDetails = injuries.stream()
                    .map(i -> String.format("%s (Mức độ: %s)", 
                            i.getInjury().getName(),
                            i.getSeverityOverride() != null ? i.getSeverityOverride() : i.getInjury().getSeverityLevel()))
                    .collect(Collectors.joining(", "));
            sb.append("- Chấn thương (BẮT BUỘC TRÁNH bài tập tác động xấu đến vùng này): ").append(injuryDetails).append("\n");
        }

        sb.append("\nDANH SÁCH BÀI TẬP ĐƯỢC PHÉP SỬ DỤNG TRONG DATABASE (CANDIDATES):\n");
        try {
            String jsonCandidates = objectMapper.writeValueAsString(candidates);
            sb.append(jsonCandidates).append("\n");
        } catch (Exception e) {
            sb.append("[]\n");
        }

        if (existingPlans != null && !existingPlans.isEmpty()) {
            sb.append("\nDANH SÁCH GIÁO ÁN LUYỆN TẬP MẪU CÓ SẴN TRONG DATABASE (SỬ DỤNG NHƯ MỘT LỰA CHỌN GỢI Ý):\n");
            for (WorkoutPlan plan : existingPlans) {
                sb.append("- Giáo án: ").append(plan.getTitle())
                  .append(" (Độ khó: ").append(plan.getDifficulty())
                  .append(", Mục tiêu: ").append(plan.getGoal()).append(")\n");
                sb.append("  Chi tiết buổi tập của giáo án:\n");
                if (plan.getSessions() != null) {
                    for (WorkoutSession session : plan.getSessions()) {
                        sb.append("    + Buổi: ").append(session.getName()).append(" (Ngày thứ ").append(session.getDayNumber()).append(")\n");
                        if (session.getSessionExercises() != null) {
                            for (WorkoutSessionExercise se : session.getSessionExercises()) {
                                if (se.getExercise() != null) {
                                    sb.append("      * ").append(se.getExercise().getName())
                                      .append(" (ID: ").append(se.getExercise().getId()).append(")")
                                      .append(" - Sets: ").append(se.getSets() != null ? se.getSets() : 3)
                                      .append(", Reps: ").append(se.getReps() != null ? se.getReps() : 10)
                                      .append(", Tạ: ").append(se.getWeightKg() != null ? se.getWeightKg() + "kg" : "0kg")
                                      .append("\n");
                                }
                            }
                        }
                    }
                }
                sb.append("\n");
            }
        }

        sb.append("\nYêu cầu định dạng đầu ra:\n");
        sb.append("Bạn có 2 phương án để tạo lịch tập gợi ý ").append(days).append(" ngày:\n");
        sb.append("PHƯƠNG ÁN A: Tự thiết kế một lịch tập mới hoàn toàn sử dụng các bài tập trong danh sách ứng viên (CANDIDATES) ở trên.\n");
        sb.append("PHƯƠNG ÁN B: Nếu bạn thấy một trong các GIÁO ÁN MẪU CÓ SẴN (được liệt kê ở trên) PHÙ HỢP HOÀN HẢO với mục tiêu, độ khó, và không ảnh hưởng đến vùng chấn thương của người dùng, bạn có thể CHỌN ÁP DỤNG giáo án mẫu đó. Khi chọn phương án này, bạn hãy lấy chính xác các bài tập, sets, reps của các buổi trong giáo án đó để phân bổ vào lịch tập ").append(days).append(" ngày (những ngày không tập trong giáo án sẽ đặt là ngày nghỉ ngơi Rest day với danh sách workoutItems rỗng).\n\n");
        sb.append("Bất kể chọn phương án nào, bạn PHẢI trả về một JSON array duy nhất đại diện cho lịch tập gợi ý của ").append(days).append(" ngày liên tiếp bắt đầu từ ngày ").append(startDate).append(".\n");
        sb.append("RÀNG BUỘC CỐT LÕI: Bạn CHỈ ĐƯỢC CHỌN bài tập từ danh sách cung cấp ở trên. Bắt buộc phải khớp đúng UUID của bài tập trong trường `exerciseId`. KHÔNG tự ý tạo bài tập mới.\n");
        sb.append("Không được phép thêm bất kỳ chữ giải thích nào khác ngoài chuỗi JSON hợp lệ. Vui lòng cung cấp định dạng JSON chuẩn xác theo cấu trúc sau:\n");
        sb.append("[\n");
        sb.append("  {\n");
        sb.append("    \"date\": \"YYYY-MM-DD\",  // Ngày cụ thể của lịch tập (bắt đầu từ ").append(startDate).append(" và tăng dần 1 ngày cho mỗi phần tử tiếp theo)\n");
        sb.append("    \"note\": \"Ghi chú ngày tập (ví dụ: Tập ngực & tay sau hoặc Ngày nghỉ ngơi phục hồi)\",\n");
        sb.append("    \"isAiGenerated\": true,\n");
        sb.append("    \"workoutItems\": [\n");
        sb.append("      {\n");
        sb.append("        \"orderIndex\": 0,\n");
        sb.append("        \"exerciseId\": \"UUID của bài tập được chọn\", // Bắt buộc phải trùng với UUID của bài tập trong danh sách Candidates trên\n");
        sb.append("        \"sets\": 4,\n");
        sb.append("        \"reps\": 12,\n");
        sb.append("        \"weightKg\": 10.0, // Cân nặng tạ sử dụng (kg) (bằng 0 nếu tập bodyweight hoặc cardio)\n");
        sb.append("        \"restSeconds\": 60, // Thời gian nghỉ giữa các set (giây)\n");
        sb.append("        \"durationMinutes\": 10, // Tổng thời gian dự kiến (phút) của bài tập này\n");
        sb.append("        \"distanceKm\": 0.0, // Quãng đường di chuyển bằng km (áp dụng cho chạy bộ, đạp xe... còn lại đặt null hoặc 0)\n");
        sb.append("        \"caloriesBurned\": 80.0, // Calo dự kiến đốt cháy (kcal)\n");
        sb.append("        \"notes\": \"Hướng dẫn thực hiện ngắn gọn cho bài tập này\"\n");
        sb.append("      }\n");
        sb.append("    ]\n");
        sb.append("  }\n");
        sb.append("]\n");

        return sb.toString();
    }

    public String processAndLinkExercises(String rawJson) {
        try {
            JsonNode root = objectMapper.readTree(rawJson);
            if (!root.isArray()) {
                return rawJson;
            }

            List<Exercise> allExercises = exerciseRepository.findAll();
            Map<UUID, Exercise> exerciseMap = allExercises.stream()
                    .collect(Collectors.toMap(
                            Exercise::getId,
                            e -> e,
                            (e1, e2) -> e1
                    ));

            List<DailyWorkoutDTO> list = new ArrayList<>();
            for (JsonNode dayNode : root) {
                LocalDate date = LocalDate.parse(dayNode.path("date").asText());
                String note = dayNode.path("note").asText();
                boolean isAiGenerated = dayNode.path("isAiGenerated").asBoolean(true);

                List<DailyWorkoutItemDTO> items = new ArrayList<>();
                JsonNode itemsNode = dayNode.path("workoutItems");
                if (itemsNode.isArray()) {
                    for (JsonNode itemNode : itemsNode) {
                        String exerciseIdStr = itemNode.path("exerciseId").asText();
                        Integer orderIndex = itemNode.path("orderIndex").asInt(0);
                        Boolean isCompleted = itemNode.path("isCompleted").asBoolean(false);
                        Integer sets = itemNode.has("sets") && !itemNode.path("sets").isNull() ? itemNode.path("sets").asInt() : null;
                        Integer reps = itemNode.has("reps") && !itemNode.path("reps").isNull() ? itemNode.path("reps").asInt() : null;
                        Double weightKg = itemNode.has("weightKg") && !itemNode.path("weightKg").isNull() ? itemNode.path("weightKg").asDouble() : null;
                        Integer restSeconds = itemNode.has("restSeconds") && !itemNode.path("restSeconds").isNull() ? itemNode.path("restSeconds").asInt() : null;
                        Integer durationMinutes = itemNode.has("durationMinutes") && !itemNode.path("durationMinutes").isNull() ? itemNode.path("durationMinutes").asInt() : null;
                        Double distanceKm = itemNode.has("distanceKm") && !itemNode.path("distanceKm").isNull() ? itemNode.path("distanceKm").asDouble() : null;
                        Double caloriesBurned = itemNode.has("caloriesBurned") && !itemNode.path("caloriesBurned").isNull() ? itemNode.path("caloriesBurned").asDouble() : 0.0;
                        String itemNotes = itemNode.path("notes").asText();

                        UUID exerciseId = null;
                        Exercise exercise = null;
                        boolean isCustom = true;
                        String exerciseName = "Bài tập không xác định";

                        try {
                            exerciseId = UUID.fromString(exerciseIdStr);
                            exercise = exerciseMap.get(exerciseId);
                        } catch (Exception e) {
                            // ignore
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

    public String getFallbackWorkoutJson(LocalDate startDate, String message, Integer days) {
        try {
            List<DailyWorkoutDTO> fallbackList = new ArrayList<>();
            for (int i = 0; i < days; i++) {
                LocalDate date = startDate.plusDays(i);
                fallbackList.add(DailyWorkoutDTO.builder()
                        .date(date)
                        .note(message)
                        .isAiGenerated(true)
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
            if (injury == null) continue;
            
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

    private List<Exercise> selectBalancedExercises(List<Exercise> exercises, int limit, String goalType) {
        if (exercises.size() <= limit) {
            return exercises;
        }

        Map<UUID, List<Exercise>> categoryGroups = new HashMap<>();
        UUID nullCategoryUuid = UUID.randomUUID();

        Random random = new Random();
        Map<Exercise, Double> exerciseScores = new HashMap<>();
        for (Exercise ex : exercises) {
            UUID catId = (ex.getBodyPart() != null) ? ex.getBodyPart().getId() : nullCategoryUuid;
            categoryGroups.computeIfAbsent(catId, k -> new ArrayList<>()).add(ex);
            double score = calculateExerciseScore(ex, goalType) + (random.nextDouble() * 20.0);
            exerciseScores.put(ex, score);
        }

        for (List<Exercise> groupExs : categoryGroups.values()) {
            groupExs.sort((e1, e2) -> Double.compare(exerciseScores.get(e2), exerciseScores.get(e1)));
        }

        List<Exercise> selectedExercises = new ArrayList<>();
        List<UUID> catIds = new ArrayList<>(categoryGroups.keySet());

        Map<UUID, Integer> categoryCounts = new HashMap<>();
        for (UUID catId : catIds) {
            categoryCounts.put(catId, 0);
        }

        int index = 0;
        boolean addedAny;
        do {
            addedAny = false;
            for (UUID catId : catIds) {
                List<Exercise> groupExs = categoryGroups.get(catId);
                int count = categoryCounts.get(catId);

                String bodyPartCode = null;
                if (!groupExs.isEmpty() && groupExs.get(0).getBodyPart() != null) {
                    bodyPartCode = groupExs.get(0).getBodyPart().getCode();
                }

                int maxPerCategory = getMaxExerciseCategoryLimit(bodyPartCode, goalType);

                if (count < maxPerCategory && index < groupExs.size()) {
                    selectedExercises.add(groupExs.get(index));
                    categoryCounts.put(catId, count + 1);
                    addedAny = true;
                    if (selectedExercises.size() >= limit) {
                        break;
                    }
                }
            }
            index++;
        } while (addedAny && selectedExercises.size() < limit);

        return selectedExercises;
    }

    private int getMaxExerciseCategoryLimit(String bodyPartCode, String goalType) {
        if (bodyPartCode == null) return 5;
        bodyPartCode = bodyPartCode.toUpperCase().trim();

        if (goalType == null) return 10;

        return switch (goalType) {
            case "LOSE_0_5KG", "LOSE_1KG" -> switch (bodyPartCode) {
                case "CARDIO", "FULL_BODY" -> 15;
                case "LEGS" -> 12;
                case "CORE" -> 10;
                case "BACK", "CHEST" -> 8;
                case "ARMS" -> 5;
                default -> 8;
            };
            case "GAIN_MUSCLE" -> switch (bodyPartCode) {
                case "CHEST", "BACK", "LEGS" -> 15;
                case "SHOULDERS" -> 12;
                case "ARMS" -> 10;
                case "CORE" -> 8;
                case "CARDIO" -> 3;
                default -> 8;
            };
            case "GAIN_0_5KG", "GAIN_1KG" -> switch (bodyPartCode) {
                case "LEGS", "BACK", "CHEST" -> 15;
                case "SHOULDERS" -> 10;
                case "ARMS", "CORE" -> 8;
                case "CARDIO" -> 2;
                default -> 8;
            };
            case "ENDURANCE" -> switch (bodyPartCode) {
                case "CARDIO" -> 20;
                case "FULL_BODY", "LEGS" -> 15;
                case "CORE" -> 12;
                case "BACK", "CHEST" -> 8;
                case "ARMS" -> 5;
                default -> 8;
            };
            default -> switch (bodyPartCode) {
                case "LEGS", "BACK", "CHEST" -> 12;
                case "SHOULDERS" -> 10;
                case "ARMS", "CORE", "CARDIO" -> 8;
                default -> 8;
            };
        };
    }

    private double calculateExerciseScore(Exercise exercise, String goalType) {
        double score = 50.0;
        double met = exercise.getMetValue() != null ? exercise.getMetValue() : 3.0;

        if (goalType == null) return score + met * 2.0;

        return score + switch (goalType) {
            case "LOSE_0_5KG", "LOSE_1KG" -> {
                double boost = 0.0;
                if (exercise.getCategory() != null) {
                    String catCode = exercise.getCategory().getCode() != null ? exercise.getCategory().getCode().toUpperCase() : "";
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
                        if (eqUpper.contains("BARBELL") || eqUpper.contains("DUMBBELL") || eqUpper.contains("MACHINE") || eqUpper.contains("CABLE")) {
                            eqBoost += 10.0;
                        }
                    }
                }
                double catBoost = 0.0;
                if (exercise.getCategory() != null) {
                    String catCode = exercise.getCategory().getCode() != null ? exercise.getCategory().getCode().toUpperCase() : "";
                    if (catCode.contains("STRENGTH") || catCode.contains("WEIGHTS") || catCode.contains("RESISTANCE")) {
                        catBoost = 30.0;
                    }
                }
                yield eqBoost + catBoost;
            }
            case "GAIN_0_5KG", "GAIN_1KG" -> {
                double boost = 0.0;
                if (exercise.getCategory() != null) {
                    String catCode = exercise.getCategory().getCode() != null ? exercise.getCategory().getCode().toUpperCase() : "";
                    if (catCode.contains("STRENGTH") || catCode.contains("RESISTANCE")) {
                        boost = 25.0;
                    }
                }
                yield boost;
            }
            case "ENDURANCE" -> {
                double boost = 0.0;
                if (exercise.getCategory() != null) {
                    String catCode = exercise.getCategory().getCode() != null ? exercise.getCategory().getCode().toUpperCase() : "";
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
        if (goal == null) return null;
        return switch (goal) {
            case "MAINTAIN" -> "Duy trì cân nặng";
            case "LOSE_0_5KG" -> "Giảm cân chậm (0.5 kg/tuần)";
            case "LOSE_1KG" -> "Giảm cân nhanh (1.0 kg/tuần)";
            case "GAIN_0_5KG" -> "Tăng cân chậm (0.5 kg/tuần)";
            case "GAIN_1KG" -> "Tăng cân nhanh (1.0 kg/tuần)";
            case "GAIN_MUSCLE" -> "Tăng cơ giảm mỡ";
            case "HEALTHY_LIFESTYLE" -> "Lối sống lành mạnh, ăn sạch";
            case "ENDURANCE" -> "Tăng thể lực & sức bền";
            default -> goal;
        };
    }

    private String translateActivityLevel(String level) {
        if (level == null) return null;
        return switch (level) {
            case "SEDENTARY" -> "Ít vận động (nhân viên văn phòng, ít tập thể dục)";
            case "LIGHTLY_ACTIVE" -> "Vận động nhẹ (tập thể dục 1-3 ngày/tuần)";
            case "MODERATELY_ACTIVE" -> "Vận động vừa phải (tập thể dục 3-5 ngày/tuần)";
            case "VERY_ACTIVE" -> "Vận động nhiều (tập thể thao nặng 6-7 ngày/tuần)";
            case "EXTRA_ACTIVE" -> "Vận động cực kỳ nhiều (vận động viên, công việc lao động rất nặng)";
            default -> level;
        };
    }
}
