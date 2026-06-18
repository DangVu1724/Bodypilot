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
import java.io.IOException;
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
            return getFallbackJson(startDate, "⚠️ Cấu hình Gemini Chưa Sẵn Sàng. Vui lòng cấu hình gemini.api.key trong application.properties.");
        }

        UserProfile profile = user.getProfile();
        UserGoal activeGoal = goalRepository.findByUserIdAndStatus(userId, "ACTIVE")
                .stream().findFirst().orElse(null);
        UserMetricHistory latestMetric = metricHistoryRepository.findByUserIdOrderByCreatedAtDesc(userId)
                .stream().findFirst().orElse(null);

        List<UserAllergy> allergies = allergyRepository.findAllByUserIdAndIsActiveTrue(userId);
        List<UserDietPreference> diets = dietPreferenceRepository.findAllByUserIdAndIsActiveTrue(userId);
        List<UserFoodPreference> dislikedFoods = foodPreferenceRepository.findAllByUserIdAndIsActiveTrue(userId);

        String prompt = buildPrompt(profile, activeGoal, latestMetric, allergies, diets, dislikedFoods, startDate);

        try {
            return callGemini(prompt);
        } catch (Exception e) {
            log.error("Error calling Gemini API: ", e);
            return getFallbackJson(startDate, "❌ Đã xảy ra lỗi khi gọi AI: " + e.getMessage());
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
                               List<UserAllergy> allergies, List<UserDietPreference> diets, List<UserFoodPreference> dislikes, LocalDate startDate) {
        StringBuilder sb = new StringBuilder();
        sb.append("Tạo thực đơn ăn uống trong tuần (7 ngày liên tiếp bắt đầu từ ngày ").append(startDate).append(") dựa trên thông tin người dùng sau đây:\n\n");

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
            if (allergies.get(0).getNote() != null && !allergies.get(0).getNote().trim().isEmpty()) {
                sb.append("  * Ghi chú dị ứng: ").append(allergies.get(0).getNote()).append("\n");
            }
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
            if (dislikes.get(0).getNote() != null && !dislikes.get(0).getNote().trim().isEmpty()) {
                sb.append("  * Ghi chú thực phẩm ghét: ").append(dislikes.get(0).getNote()).append("\n");
            }
        }

        sb.append("\nYêu cầu định dạng đầu ra:\n");
        sb.append("Bạn PHẢI trả về một JSON array duy nhất đại diện cho thực đơn gợi ý của 7 ngày liên tiếp bắt đầu từ ngày ").append(startDate).append(".\n");
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
        sb.append("            \"servingQuantity\": 150,\n");
        sb.append("            \"orderIndex\": 0,\n");
        sb.append("            \"foodName\": \"Tên món ăn cụ thể bằng Tiếng Việt\",\n");
        sb.append("            \"calories\": 350.0, // Calo (kcal)\n");
        sb.append("            \"protein\": 15.0,  // Protein (g)\n");
        sb.append("            \"fat\": 10.0,      // Chất béo (g)\n");
        sb.append("            \"carbs\": 50.0,     // Carb (g)\n");
        sb.append("            \"fiber\": 3.0,      // Chất xơ (g)\n");
        sb.append("            \"servingUnit\": \"g\", // Đơn vị tính (g, chén, quả, bát, đĩa, cái...)\n");
        sb.append("            \"isCustom\": true,\n");
        sb.append("            \"isEaten\": false\n");
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
        switch (budget) {
            case "LOW": return "Tiết kiệm / Học sinh - sinh viên";
            case "MEDIUM": return "Trung bình / Phổ thông";
            case "HIGH": return "Cao / Ưu tiên thực phẩm cao cấp hoặc organic";
            default: return budget;
        }
    }

    private String translateGoal(String goal) {
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

    private String callGemini(String prompt) throws IOException {
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
        sysParts.add(Map.of("text", "Bạn là một chuyên gia dinh dưỡng và lên thực đơn cá nhân hóa chuyên nghiệp. Hãy đưa ra thực đơn cực kỳ chi tiết, khoa học, thực tế dưới dạng JSON array hợp lệ phù hợp với đặc tả DTO của hệ thống."));
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
}
