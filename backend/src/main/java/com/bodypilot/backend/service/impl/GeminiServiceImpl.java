package com.bodypilot.backend.service.impl;

import com.bodypilot.backend.exception.ResourceNotFoundException;
import com.bodypilot.backend.model.entity.user.*;
import com.bodypilot.backend.repository.*;
import com.bodypilot.backend.service.GeminiService;
import com.fasterxml.jackson.databind.JsonNode;
import com.fasterxml.jackson.databind.ObjectMapper;
import lombok.RequiredArgsConstructor;
import lombok.extern.slf4j.Slf4j;
import okhttp3.*;
import org.springframework.beans.factory.annotation.Value;
import org.springframework.stereotype.Service;

import com.bodypilot.backend.model.dto.nutrition.DailyEatingDTO;
import com.bodypilot.backend.model.dto.nutrition.MealSlotDTO;
import com.bodypilot.backend.model.dto.nutrition.MealItemDTO;
import com.bodypilot.backend.model.dto.nutrition.FoodCandidate;
import com.bodypilot.backend.model.dto.workout.DailyWorkoutDTO;
import com.bodypilot.backend.model.dto.workout.DailyWorkoutItemDTO;
import com.bodypilot.backend.model.dto.workout.ExerciseCandidate;
import com.bodypilot.backend.model.entity.nutrition.Food;
import com.bodypilot.backend.model.entity.nutrition.FoodCategory;
import com.bodypilot.backend.model.entity.nutrition.DietTag;
import com.bodypilot.backend.model.entity.workout.Exercise;
import com.bodypilot.backend.model.entity.health.Injury;
import com.bodypilot.backend.model.enums.DislikedFoodGroup;
import com.bodypilot.backend.model.enums.MealType;
import lombok.Data;
import lombok.AllArgsConstructor;
import lombok.NoArgsConstructor;
import java.io.IOException;
import java.math.BigDecimal;
import java.math.RoundingMode;
import java.time.LocalDate;
import java.util.*;
import java.util.concurrent.TimeUnit;
import java.util.stream.Collectors;

@Service
@RequiredArgsConstructor
@Slf4j
public class GeminiServiceImpl implements GeminiService {

    private final UserRepository userRepository;
    private final UserProfileRepository userProfileRepository;
    private final UserGoalRepository goalRepository;
    private final UserMetricHistoryRepository metricHistoryRepository;
    private final UserAllergyRepository allergyRepository;
    private final UserDietPreferenceRepository dietPreferenceRepository;
    private final UserFoodPreferenceRepository foodPreferenceRepository;
    private final UserInjuryRepository userInjuryRepository;
    private final ExerciseRepository exerciseRepository;
    private final FoodRepository foodRepository;

    @Value("${gemini.api.key:}")
    private String apiKey;

    @Value("${gemini.api.url:https://generativelanguage.googleapis.com/v1beta/models/}")
    private String apiUrl;

    @Value("${gemini.model:gemini-1.5-flash}")
    private String model;

    private final ObjectMapper objectMapper = new ObjectMapper();

    private final OkHttpClient httpClient = new OkHttpClient.Builder()
            .connectTimeout(60, TimeUnit.SECONDS)
            .readTimeout(120, TimeUnit.SECONDS)
            .writeTimeout(60, TimeUnit.SECONDS)
            .build();

    @Override
    public String generateMealSuggestion(UUID userId, LocalDate startDate) {
        User user = userRepository.findById(userId)
                .orElseThrow(() -> new ResourceNotFoundException("User not found with id: " + userId));

        if (apiKey == null || apiKey.trim().isEmpty()) {
            log.warn("Gemini API key is missing. Returning fallback JSON.");
            return getFallbackJson(startDate, "Cấu hình Gemini Chưa Sẵn Sàng. Vui lòng cấu hình gemini.api.key trong application.properties.");
        }

        UserProfile profile = user.getProfile();
        UserGoal activeGoal = goalRepository.findByUserIdAndStatus(userId, "ACTIVE")
                .stream().findFirst().orElse(null);
        UserMetricHistory latestMetric = metricHistoryRepository.findByUserIdOrderByCreatedAtDesc(userId)
                .stream().findFirst().orElse(null);

        List<UserAllergy> allergies = allergyRepository.findAllByUserIdAndIsActiveTrue(userId);
        List<UserDietPreference> diets = dietPreferenceRepository.findAllByUserIdAndIsActiveTrue(userId);
        List<UserFoodPreference> dislikedFoods = foodPreferenceRepository.findAllByUserIdAndIsActiveTrue(userId);

        // Lọc thực phẩm thật từ Database theo dị ứng và sở thích
        List<Food> filteredFoods = getFilteredFoods(allergies, diets, dislikedFoods);
        List<FoodCandidate> candidates = filteredFoods.stream()
                .map(f -> new FoodCandidate(
                        f.getId(),
                        f.getName(),
                        f.getCaloriesPer100g().doubleValue(),
                        f.getProteinPer100g().doubleValue(),
                        f.getFatPer100g().doubleValue(),
                        f.getCarbsPer100g().doubleValue(),
                        f.getFiberPer100g().doubleValue(),
                        f.getDefaultServing() != null ? f.getDefaultServing().getName() : "g"
                ))
                .collect(Collectors.toList());

        String prompt = buildPrompt(profile, activeGoal, latestMetric, allergies, diets, dislikedFoods, candidates, startDate);

        try {
            String rawJson = callGemini(prompt, "Bạn là một chuyên gia dinh dưỡng và lên thực đơn cá nhân hóa chuyên nghiệp. Hãy đưa ra thực đơn cực kỳ chi tiết, khoa học, thực tế dưới dạng JSON array hợp lệ phù hợp với danh sách thực phẩm được cung cấp.");
            return processAndLinkFoods(rawJson);
        } catch (Exception e) {
            log.error("Error calling Gemini API: ", e);
            return getFallbackJson(startDate, "❌ Đã xảy ra lỗi khi gọi AI: " + e.getMessage());
        }
    }

    @Override
    public String generateWorkoutSuggestion(UUID userId, LocalDate startDate) {
        User user = userRepository.findById(userId)
                .orElseThrow(() -> new ResourceNotFoundException("User not found with id: " + userId));

        if (apiKey == null || apiKey.trim().isEmpty()) {
            log.warn("Gemini API key is missing. Returning fallback JSON.");
            return getFallbackWorkoutJson(startDate, "Cấu hình Gemini Chưa Sẵn Sàng. Vui lòng cấu hình gemini.api.key trong application.properties.");
        }

        UserProfile profile = user.getProfile();
        UserGoal activeGoal = goalRepository.findByUserIdAndStatus(userId, "ACTIVE")
                .stream().findFirst().orElse(null);
        UserMetricHistory latestMetric = metricHistoryRepository.findByUserIdOrderByCreatedAtDesc(userId)
                .stream().findFirst().orElse(null);

        List<UserInjury> injuries = userInjuryRepository.findAllByUserId(userId);

        // Lọc bài tập thật từ database tránh vùng chấn thương của user
        List<Exercise> filteredExercises = getFilteredExercises(injuries);
        List<ExerciseCandidate> candidates = filteredExercises.stream()
                .map(e -> new ExerciseCandidate(
                        e.getId(),
                        e.getName(),
                        e.getBodyPart() != null ? e.getBodyPart().getName() : "Không xác định",
                        e.getTargetMuscle() != null ? e.getTargetMuscle().getName() : "Không xác định",
                        e.getDifficulty() != null ? e.getDifficulty().name() : "BEGINNER",
                        e.getEquipment()
                ))
                .collect(Collectors.toList());

        String prompt = buildWorkoutPrompt(profile, activeGoal, latestMetric, injuries, candidates, startDate);

        try {
            String rawJson = callGemini(prompt, "Bạn là một huấn luyện viên cá nhân (PT) chuyên nghiệp. Hãy lên lịch trình tập luyện thể hình cực kỳ chi tiết, khoa học, thực tế phù hợp với thể trạng người dùng dưới dạng JSON array hợp lệ phù hợp với danh sách bài tập được cung cấp.");
            return processAndLinkExercises(rawJson);
        } catch (Exception e) {
            log.error("Error calling Gemini API for workout suggestion: ", e);
            return getFallbackWorkoutJson(startDate, "❌ Đã xảy ra lỗi khi gọi AI: " + e.getMessage());
        }
    }

    private String getFallbackWorkoutJson(LocalDate startDate, String message) {
        try {
            List<DailyWorkoutDTO> fallbackList = new ArrayList<>();
            for (int i = 0; i < 7; i++) {
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

    private String buildWorkoutPrompt(UserProfile profile, UserGoal goal, UserMetricHistory metric,
                                       List<UserInjury> injuries, List<ExerciseCandidate> candidates, LocalDate startDate) {
        StringBuilder sb = new StringBuilder();
        sb.append("Tạo lịch tập luyện thể thao trong tuần (7 ngày liên tiếp bắt đầu từ ngày ").append(startDate).append(") dựa trên thông tin người dùng và danh sách bài tập được cung cấp dưới đây:\n\n");

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

        // Đính kèm danh sách bài tập candidate từ database
        sb.append("\nDANH SÁCH BÀI TẬP ĐƯỢC PHÉP SỬ DỤNG TRONG DATABASE (CANDIDATES):\n");
        try {
            String jsonCandidates = objectMapper.writeValueAsString(candidates);
            sb.append(jsonCandidates).append("\n");
        } catch (Exception e) {
            sb.append("[]\n");
        }

        sb.append("\nYêu cầu định dạng đầu ra:\n");
        sb.append("Bạn PHẢI trả về một JSON array duy nhất đại diện cho lịch tập gợi ý của 7 ngày liên tiếp bắt đầu từ ngày ").append(startDate).append(".\n");
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

    private String processAndLinkExercises(String rawJson) {
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
                            // UUID không hợp lệ hoặc không có trong Map
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

    private String getFallbackJson(LocalDate startDate, String message) {
        try {
            List<DailyEatingDTO> fallbackList = new ArrayList<>();
            for (int i = 0; i < 7; i++) {
                LocalDate date = startDate.plusDays(i);
                fallbackList.add(DailyEatingDTO.builder()
                        .date(date)
                        .note(message)
                        .isAiGenerated(true)
                        .mealSlots(new ArrayList<>())
                        .build());
            }
            return objectMapper.writeValueAsString(fallbackList);
        } catch (Exception e) {
            return "[]";
        }
    }

    private String buildPrompt(UserProfile profile, UserGoal goal, UserMetricHistory metric,
                               List<UserAllergy> allergies, List<UserDietPreference> diets, 
                               List<UserFoodPreference> dislikes, List<FoodCandidate> candidates, LocalDate startDate) {
        StringBuilder sb = new StringBuilder();
        sb.append("Tạo thực đơn ăn uống trong tuần (7 ngày liên tiếp bắt đầu từ ngày ").append(startDate).append(") dựa trên thông tin người dùng và danh sách thực phẩm được cung cấp bên dưới.\n\n");

        if (profile != null) {
            sb.append("- Giới tính: ").append(profile.getGender() != null ? profile.getGender() : "Chưa cập nhật").append("\n");
            sb.append("- Tuổi: ").append(profile.getAge() != null ? profile.getAge() : "Chưa cập nhật").append("\n");
            sb.append("- Chiều cao: ").append(profile.getHeightCm() != null ? profile.getHeightCm() + " cm" : "Chưa cập nhật").append("\n");
            sb.append("- Cân nặng hiện tại: ").append(profile.getWeight() != null ? profile.getWeight() + " kg" : "Chưa cập nhật").append("\n");
            sb.append("- Mức độ hoạt động: ").append(profile.getActivityLevel() != null ? translateActivityLevel(profile.getActivityLevel()) : "Chưa cập nhật").append("\n");
            sb.append("- Ngân sách ăn uống: ").append(profile.getFoodBudget() != null ? translateBudget(profile.getFoodBudget().name()) : "Chưa cập nhật").append("\n");
        }

        if (goal != null) {
            sb.append("- Mục tiêu thể hình: ").append(translateGoal(goal.getType())).append("\n");
            sb.append("- Cân nặng mục tiêu: ").append(goal.getTargetWeight() != null ? goal.getTargetWeight() + " kg" : "Chưa cập nhật").append("\n");
        }

        if (metric != null && metric.getTargetCalories() != null) {
            sb.append("- Lượng calo tiêu thụ mục tiêu mỗi ngày: ").append(metric.getTargetCalories().intValue()).append(" kcal\n");
        }

        if (!allergies.isEmpty()) {
            String allergyNames = allergies.stream()
                    .map(a -> a.getAllergyMaster().getName())
                    .collect(Collectors.joining(", "));
            sb.append("- Dị ứng thực phẩm (BẮT BUỘC TRÁNH): ").append(allergyNames).append("\n");
        }

        if (!diets.isEmpty()) {
            String dietNames = diets.stream()
                    .map(d -> d.getDietTag().getName())
                    .collect(Collectors.joining(", "));
            sb.append("- Chế độ ăn ưu tiên: ").append(dietNames).append("\n");
        }

        if (!dislikes.isEmpty()) {
            String dislikeNames = dislikes.stream()
                    .map(d -> translateDislikeGroup(d.getDislikedFoodGroup().name()))
                    .collect(Collectors.joining(", "));
            sb.append("- Nhóm thực phẩm không thích: ").append(dislikeNames).append("\n");
        }

        // Đính kèm danh sách thực phẩm ứng viên từ database
        sb.append("\nDANH SÁCH THỰC PHẨM ĐƯỢC PHÉP SỬ DỤNG TRONG DATABASE (CANDIDATES):\n");
        try {
            String jsonCandidates = objectMapper.writeValueAsString(candidates);
            sb.append(jsonCandidates).append("\n");
        } catch (Exception e) {
            sb.append("[]\n");
        }

        sb.append("\nYêu cầu định dạng đầu ra:\n");
        sb.append("Bạn PHẢI trả về một JSON array duy nhất đại diện cho thực đơn gợi ý của 7 ngày liên tiếp bắt đầu từ ngày ").append(startDate).append(".\n");
        sb.append("RÀNG BUỘC CỐT LÕI: Bạn CHỈ ĐƯỢC CHỌN thực phẩm từ danh sách cung cấp ở trên. Bắt buộc phải khớp đúng UUID của thực phẩm đó trong trường `foodId`. KHÔNG tự ý tạo thực phẩm mới.\n");
        sb.append("Không được phép thêm bất kỳ chữ giải thích nào khác ngoài chuỗi JSON hợp lệ. Vui lòng cung cấp định dạng JSON chuẩn xác theo cấu trúc sau:\n");
        sb.append("[\n");
        sb.append("  {\n");
        sb.append("    \"date\": \"YYYY-MM-DD\",  // Ngày cụ thể của thực đơn (bắt đầu từ ").append(startDate).append(" và tăng dần 1 ngày cho mỗi phần tử tiếp theo)\n");
        sb.append("    \"note\": \"Ghi chú tổng quan dinh dưỡng hoặc lời khuyên cho ngày này\",\n");
        sb.append("    \"isAiGenerated\": true,\n");
        sb.append("    \"mealSlots\": [\n");
        sb.append("      {\n");
        sb.append("        \"mealType\": \"BREAKFAST\", // Một trong các giá trị: BREAKFAST, LUNCH, DINNER, SNACK\n");
        sb.append("        \"customName\": \"Bữa sáng\",\n");
        sb.append("        \"orderIndex\": 0,\n");
        sb.append("        \"items\": [\n");
        sb.append("          {\n");
        sb.append("            \"foodId\": \"UUID của thực phẩm được chọn\", // Bắt buộc phải trùng với UUID của thực phẩm trong danh sách Candidates trên\n");
        sb.append("            \"servingQuantity\": 150.0, // Khẩu phần ăn tính bằng gram (hoặc đơn vị được chỉ định), bạn tự tính toán lượng này sao cho tổng calo và dinh dưỡng trong ngày đạt mục tiêu của user\n");
        sb.append("            \"orderIndex\": 0\n");
        sb.append("          }\n");
        sb.append("        ]\n");
        sb.append("      },\n");
        sb.append("      ... (tạo đủ 4 bữa BREAKFAST, LUNCH, DINNER, SNACK mỗi ngày)\n");
        sb.append("    ]\n");
        sb.append("  }\n");
        sb.append("]\n");

        return sb.toString();
    }

    private String translateActivityLevel(String level) {
        if (level == null) return null;
        switch (level) {
            case "SEDENTARY": return "Ít vận động (nhân viên văn phòng, ít tập thể dục)";
            case "LIGHTLY_ACTIVE": return "Vận động nhẹ (tập thể dục 1-3 ngày/tuần)";
            case "MODERATELY_ACTIVE": return "Vận động vừa phải (tập thể dục 3-5 ngày/tuần)";
            case "VERY_ACTIVE": return "Vận động nhiều (tập thể thao nặng 6-7 ngày/tuần)";
            case "EXTRA_ACTIVE": return "Vận động cực kỳ nhiều (vận động viên, công việc lao động rất nặng)";
            default: return level;
        }
    }

    private String translateBudget(String budget) {
        if (budget == null) return null;
        switch (budget) {
            case "LOW": return "Tiết kiệm / Học sinh - sinh viên";
            case "MEDIUM": return "Trung bình / Phổ thông";
            case "HIGH": return "Cao / Ưu tiên thực phẩm cao cấp hoặc organic";
            default: return budget;
        }
    }

    private String translateGoal(String goal) {
        if (goal == null) return null;
        switch (goal) {
            case "MAINTAIN": return "Duy trì cân nặng";
            case "LOSE_0_5KG": return "Giảm cân chậm (0.5 kg/tuần)";
            case "LOSE_1KG": return "Giảm cân nhanh (1.0 kg/tuần)";
            case "GAIN_0_5KG": return "Tăng cân chậm (0.5 kg/tuần)";
            case "GAIN_1KG": return "Tăng cân nhanh (1.0 kg/tuần)";
            case "GAIN_MUSCLE": return "Tăng cơ giảm mỡ";
            case "HEALTHY_LIFESTYLE": return "Lối sống lành mạnh, ăn sạch";
            case "ENDURANCE": return "Tăng thể lực & sức bền";
            default: return goal;
        }
    }

    private String translateDislikeGroup(String group) {
        if (group == null) return null;
        switch (group) {
            case "ORGAN_MEAT": return "Nội tạng động vật";
            case "SEAFOOD": return "Hải sản";
            case "SPICY_FOOD": return "Đồ ăn cay";
            case "FRIED_FOOD": return "Đồ chiên rán nhiều dầu mỡ";
            case "FAST_FOOD": return "Thức ăn nhanh";
            case "SUGARY_FOOD": return "Đồ ngọt, đường nhiều";
            case "PROCESSED_FOOD": return "Thực phẩm chế biến sẵn (xúc xích, thịt nguội)";
            case "DAIRY_PRODUCTS": return "Sữa và chế phẩm từ sữa";
            case "OTHER": return "Thực phẩm khác";
            default: return group;
        }
    }

    private String callGemini(String prompt, String systemInstructionText) throws IOException {
        // Build Gemini Request Body
        Map<String, Object> requestBodyMap = new HashMap<>();

        // contents
        List<Map<String, Object>> contents = new ArrayList<>();
        Map<String, Object> contentMap = new HashMap<>();
        List<Map<String, String>> parts = new ArrayList<>();
        parts.add(Map.of("text", prompt));
        contentMap.put("parts", parts);
        contents.add(contentMap);
        requestBodyMap.put("contents", contents);

        // systemInstruction
        Map<String, Object> systemInstruction = new HashMap<>();
        List<Map<String, String>> sysParts = new ArrayList<>();
        sysParts.add(Map.of("text", systemInstructionText));
        systemInstruction.put("parts", sysParts);
        requestBodyMap.put("systemInstruction", systemInstruction);

        // generationConfig
        requestBodyMap.put("generationConfig", Map.of(
                "temperature", 0.7,
                "responseMimeType", "application/json"
        ));

        String jsonBody = objectMapper.writeValueAsString(requestBodyMap);
        RequestBody body = RequestBody.create(jsonBody, MediaType.get("application/json; charset=utf-8"));

        // URL format: https://generativelanguage.googleapis.com/v1beta/models/{model}:generateContent?key={apiKey}
        String requestUrl = apiUrl + model + ":generateContent?key=" + apiKey;

        Request request = new Request.Builder()
                .url(requestUrl)
                .post(body)
                .build();

        try (Response response = httpClient.newCall(request).execute()) {
            if (!response.isSuccessful()) {
                String errorMsg = response.body() != null ? response.body().string() : "No error details";
                throw new IOException("Gemini API call failed with code " + response.code() + ". Details: " + errorMsg);
            }

            String responseBody = response.body().string();
            JsonNode rootNode = objectMapper.readTree(responseBody);
            // Gemini response path: candidates[0].content.parts[0].text
            return rootNode.path("candidates").get(0)
                    .path("content").path("parts").get(0)
                    .path("text").asText();
        }
    }

    private String processAndLinkFoods(String rawJson) {
        try {
            JsonNode root = objectMapper.readTree(rawJson);
            if (!root.isArray()) {
                return rawJson;
            }

            List<Food> allFoods = foodRepository.findAll();
            Map<UUID, Food> foodMap = allFoods.stream()
                    .collect(Collectors.toMap(
                            Food::getId,
                            f -> f,
                            (f1, f2) -> f1
                    ));

            List<DailyEatingDTO> list = new ArrayList<>();
            for (JsonNode dayNode : root) {
                LocalDate date = LocalDate.parse(dayNode.path("date").asText());
                String note = dayNode.path("note").asText();
                boolean isAiGenerated = dayNode.path("isAiGenerated").asBoolean(true);

                List<MealSlotDTO> mealSlots = new ArrayList<>();
                JsonNode slotsNode = dayNode.path("mealSlots");
                if (slotsNode.isArray()) {
                    for (JsonNode slotNode : slotsNode) {
                        String mealTypeStr = slotNode.path("mealType").asText("BREAKFAST");
                        MealType mealType = MealType.valueOf(mealTypeStr);
                        String customName = slotNode.path("customName").asText("");
                        Integer orderIndex = slotNode.path("orderIndex").asInt(0);

                        List<MealItemDTO> items = new ArrayList<>();
                        JsonNode itemsNode = slotNode.path("items");
                        if (itemsNode.isArray()) {
                            int itemOrder = 0;
                            for (JsonNode itemNode : itemsNode) {
                                String foodIdStr = itemNode.path("foodId").asText();
                                BigDecimal servingQuantity = new BigDecimal(itemNode.path("servingQuantity").asText("100"));
                                
                                UUID foodId = null;
                                Food food = null;
                                try {
                                    foodId = UUID.fromString(foodIdStr);
                                    food = foodMap.get(foodId);
                                } catch (Exception e) {
                                    // foodId không đúng format hoặc không tìm thấy
                                }

                                if (food != null) {
                                    BigDecimal factor = servingQuantity.divide(new BigDecimal("100"), 4, RoundingMode.HALF_UP);
                                    BigDecimal calories = food.getCaloriesPer100g().multiply(factor);
                                    BigDecimal protein = food.getProteinPer100g().multiply(factor);
                                    BigDecimal fat = food.getFatPer100g().multiply(factor);
                                    BigDecimal carbs = food.getCarbsPer100g().multiply(factor);
                                    BigDecimal fiber = food.getFiberPer100g().multiply(factor);
                                    
                                    String unit = "g";
                                    if (food.getDefaultServing() != null) {
                                        unit = food.getDefaultServing().getName();
                                    }

                                    items.add(MealItemDTO.builder()
                                            .foodId(foodId)
                                            .servingQuantity(servingQuantity)
                                            .orderIndex(itemNode.has("orderIndex") ? itemNode.path("orderIndex").asInt() : itemOrder++)
                                            .foodName(food.getName())
                                            .calories(calories)
                                            .protein(protein)
                                            .fat(fat)
                                            .carbs(carbs)
                                            .fiber(fiber)
                                            .servingUnit(unit)
                                            .imageUrl(food.getImageUrl())
                                            .isCustom(false)
                                            .isEaten(false)
                                            .build());
                                } else {
                                    items.add(MealItemDTO.builder()
                                            .foodId(null)
                                            .servingQuantity(servingQuantity)
                                            .orderIndex(itemNode.has("orderIndex") ? itemNode.path("orderIndex").asInt() : itemOrder++)
                                            .foodName(itemNode.path("foodName").asText("Món ăn không xác định"))
                                            .calories(new BigDecimal(itemNode.path("calories").asDouble(0.0)))
                                            .protein(new BigDecimal(itemNode.path("protein").asDouble(0.0)))
                                            .fat(new BigDecimal(itemNode.path("fat").asDouble(0.0)))
                                            .carbs(new BigDecimal(itemNode.path("carbs").asDouble(0.0)))
                                            .fiber(new BigDecimal(itemNode.path("fiber").asDouble(0.0)))
                                            .servingUnit(itemNode.path("servingUnit").asText("g"))
                                            .isCustom(true)
                                            .isEaten(false)
                                            .build());
                                }
                            }
                        }

                        mealSlots.add(MealSlotDTO.builder()
                                .mealType(mealType)
                                .customName(customName)
                                .orderIndex(orderIndex)
                                .isEaten(false)
                                .items(items)
                                .build());
                    }
                }

                BigDecimal totalCal = mealSlots.stream()
                        .flatMap(slot -> slot.getItems().stream())
                        .map(item -> item.getCalories() != null ? item.getCalories() : BigDecimal.ZERO)
                        .reduce(BigDecimal.ZERO, BigDecimal::add);

                list.add(DailyEatingDTO.builder()
                        .date(date)
                        .note(note)
                        .isAiGenerated(isAiGenerated)
                        .totalCaloriesPlanned(totalCal)
                        .totalCaloriesEaten(BigDecimal.ZERO)
                        .mealSlots(mealSlots)
                        .build());
            }

            return objectMapper.writeValueAsString(list);
        } catch (Exception e) {
            log.error("Error post-processing AI meal suggestion JSON: ", e);
            return rawJson;
        }
    }

    private List<Food> getFilteredFoods(List<UserAllergy> allergies, List<UserDietPreference> diets, List<UserFoodPreference> dislikes) {
        List<Food> foods = foodRepository.findAll();
        
        // 1. Lọc dị ứng
        if (allergies != null && !allergies.isEmpty()) {
            for (UserAllergy allergy : allergies) {
                if (allergy.getAllergyMaster() == null) continue;
                String allergyName = allergy.getAllergyMaster().getName().toLowerCase().trim();
                String allergyCode = allergy.getAllergyMaster().getCode() != null ? allergy.getAllergyMaster().getCode().toLowerCase().trim() : "";
                
                foods = foods.stream()
                    .filter(f -> {
                        // Lọc theo Category
                        if (f.getCategory() != null) {
                            String catName = f.getCategory().getName().toLowerCase();
                            String catCode = f.getCategory().getCode() != null ? f.getCategory().getCode().toLowerCase() : "";
                            if (catName.contains(allergyName) || catCode.contains(allergyCode) || allergyName.contains(catName) || allergyCode.contains(catCode)) {
                                return false;
                            }
                        }
                        // Lọc theo Text
                        String name = f.getName().toLowerCase();
                        String desc = f.getDescription() != null ? f.getDescription().toLowerCase() : "";
                        return !name.contains(allergyName) && !desc.contains(allergyName);
                    })
                    .collect(Collectors.toList());
            }
        }
        
        // 2. Lọc theo Diet Preferences (Chế độ ăn ưu thích)
        if (diets != null && !diets.isEmpty()) {
            Set<UUID> userDietTagIds = diets.stream()
                .map(d -> d.getDietTag().getId())
                .collect(Collectors.toSet());
            foods = foods.stream()
                .filter(f -> f.getDietTags().stream().anyMatch(tag -> userDietTagIds.contains(tag.getId())))
                .collect(Collectors.toList());
        }
        
        // 3. Lọc theo nhóm món ăn không thích
        if (dislikes != null && !dislikes.isEmpty()) {
            for (UserFoodPreference preference : dislikes) {
                DislikedFoodGroup group = preference.getDislikedFoodGroup();
                if (group == null) continue;
                
                foods = foods.stream()
                    .filter(f -> !isDislikedFood(f, group))
                    .collect(Collectors.toList());
            }
        }
        
        return foods;
    }
    
    private boolean isDislikedFood(Food f, DislikedFoodGroup group) {
        String name = f.getName().toLowerCase();
        String desc = f.getDescription() != null ? f.getDescription().toLowerCase() : "";
        String catName = f.getCategory() != null ? f.getCategory().getName().toLowerCase() : "";
        String catCode = f.getCategory() != null && f.getCategory().getCode() != null ? f.getCategory().getCode().toLowerCase() : "";
        
        switch (group) {
            case SEAFOOD:
                if (catName.contains("hải sản") || catCode.contains("seafood")) return true;
                List<String> sfKeywords = Arrays.asList("tôm", "cua", "cá", "mực", "nghêu", "sò", "ốc", "hến", "bạch tuộc", "sứa", "hàu", "tôm hùm", "seafood", "fish", "shrimp", "squid", "crab", "octopus");
                return sfKeywords.stream().anyMatch(k -> name.contains(k) || desc.contains(k));
                
            case ORGAN_MEAT:
                List<String> organKeywords = Arrays.asList("lòng", "tim", "gan", "cật", "phèo", "mề", "sách", "dồi", "nội tạng", "dạ dày heo", "organ", "liver", "kidney", "gizzard");
                return organKeywords.stream().anyMatch(k -> name.contains(k) || desc.contains(k));
                
            case DAIRY_PRODUCTS:
                if (catName.contains("sữa") || catCode.contains("dairy") || catCode.contains("milk")) return true;
                List<String> dairyKeywords = Arrays.asList("sữa", "phô mai", "bơ", "milk", "cheese", "butter", "dairy", "yogurt", "sữa chua", "váng sữa");
                return dairyKeywords.stream().anyMatch(k -> name.contains(k) || desc.contains(k));
                
            case FRIED_FOOD:
            case FAST_FOOD:
                List<String> fastKeywords = Arrays.asList("chiên", "rán", "quay", "nướng dầu", "fastfood", "hamburger", "pizza", "fried", "kfc", "jollibee", "mcdonald");
                return fastKeywords.stream().anyMatch(k -> name.contains(k) || desc.contains(k));
                
            case SPICY_FOOD:
                List<String> spicyKeywords = Arrays.asList("cay", "ớt", "chilli", "spicy");
                return spicyKeywords.stream().anyMatch(k -> name.contains(k) || desc.contains(k));
                
            case SUGARY_FOOD:
                List<String> sugarKeywords = Arrays.asList("kẹo", "bánh ngọt", "sô cô la", "chocolate", "candy", "sweet", "đường cát", "nước ngọt", "soda");
                return sugarKeywords.stream().anyMatch(k -> name.contains(k) || desc.contains(k));
                
            case PROCESSED_FOOD:
                List<String> processedKeywords = Arrays.asList("xúc xích", "lạp xưởng", "thịt nguội", "lạp sườn", "giăm bông", "ham", "sausage", "đồ hộp", "cá hộp", "thịt hộp");
                return processedKeywords.stream().anyMatch(k -> name.contains(k) || desc.contains(k));
                
            default:
                return false;
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
}
