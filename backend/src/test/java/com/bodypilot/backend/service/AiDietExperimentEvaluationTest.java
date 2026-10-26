package com.bodypilot.backend.service;

import java.io.BufferedWriter;
import java.io.FileOutputStream;
import java.io.FileWriter;
import java.io.OutputStreamWriter;
import java.io.PrintWriter;
import java.nio.charset.StandardCharsets;
import java.math.BigDecimal;
import java.math.RoundingMode;
import java.time.LocalDate;
import java.util.ArrayList;
import java.util.Collections;
import java.util.HashMap;
import java.util.List;
import java.util.Map;
import java.util.UUID;
import java.util.stream.Collectors;

import org.junit.jupiter.api.DisplayName;
import org.junit.jupiter.api.Test;
import org.springframework.beans.factory.annotation.Autowired;
import org.springframework.boot.test.context.SpringBootTest;

import com.bodypilot.backend.model.dto.nutrition.CalorieCalculationResult;
import com.bodypilot.backend.model.dto.nutrition.FoodCandidate;
import com.bodypilot.backend.model.entity.nutrition.Food;
import com.bodypilot.backend.model.entity.user.UserAllergy;
import com.bodypilot.backend.model.entity.user.UserDietPreference;
import com.bodypilot.backend.model.entity.user.UserFoodPreference;
import com.bodypilot.backend.model.entity.user.UserGoal;
import com.bodypilot.backend.model.entity.user.UserMetricHistory;
import com.bodypilot.backend.model.entity.user.UserProfile;
import com.bodypilot.backend.model.enums.ActivityLevel;
import com.bodypilot.backend.model.enums.Gender;
import com.bodypilot.backend.model.enums.Goal;
import com.bodypilot.backend.service.impl.GeminiClient;
import com.bodypilot.backend.service.impl.diet.DietFoodFilterService;
import com.bodypilot.backend.service.impl.diet.DietJsonPostProcessor;
import com.bodypilot.backend.service.impl.diet.DietJsonPostProcessor.RawDailyEating;
import com.bodypilot.backend.service.impl.diet.DietJsonPostProcessor.RawMealItem;
import com.bodypilot.backend.service.impl.diet.DietJsonPostProcessor.RawMealSlot;
import com.bodypilot.backend.service.impl.diet.DietPromptBuilder;
import com.bodypilot.backend.service.impl.diet.PresetMealFallbackBuilder;
import com.fasterxml.jackson.databind.DeserializationFeature;
import com.fasterxml.jackson.databind.ObjectMapper;
import com.fasterxml.jackson.datatype.jsr310.JavaTimeModule;

import lombok.Builder;
import lombok.Data;
import lombok.extern.slf4j.Slf4j;

@SpringBootTest
@Slf4j
public class AiDietExperimentEvaluationTest {

    @Autowired
    private CalorieCalculatorService calorieCalculatorService;

    @Autowired
    private DietFoodFilterService foodFilterService;

    @Autowired
    private DietPromptBuilder promptBuilder;

    @Autowired
    private GeminiClient geminiClient;

    @Autowired
    private DietJsonPostProcessor jsonPostProcessor;

    @Autowired
    private PresetMealFallbackBuilder presetMealFallbackBuilder;

    private final ObjectMapper objectMapper = new ObjectMapper()
            .registerModule(new JavaTimeModule())
            .configure(DeserializationFeature.FAIL_ON_UNKNOWN_PROPERTIES, false)
            .configure(com.fasterxml.jackson.core.JsonParser.Feature.ALLOW_UNQUOTED_FIELD_NAMES, true)
            .configure(com.fasterxml.jackson.core.JsonParser.Feature.ALLOW_SINGLE_QUOTES, true)
            .configure(com.fasterxml.jackson.core.JsonParser.Feature.ALLOW_COMMENTS, true)
            .configure(com.fasterxml.jackson.core.JsonParser.Feature.ALLOW_TRAILING_COMMA, true)
            .configure(com.fasterxml.jackson.core.JsonParser.Feature.ALLOW_UNQUOTED_CONTROL_CHARS, true)
            .configure(com.fasterxml.jackson.core.JsonParser.Feature.ALLOW_BACKSLASH_ESCAPING_ANY_CHARACTER, true);

    @Data
    @Builder
    public static class TestUserProfile {
        private String id;
        private String gender;
        private int age;
        private double height;
        private double weight;
        private Goal goal;
        private ActivityLevel activityLevel;
        private String dietType;
        private String allergyNote;
        private String dislikeNote;
        private double targetCalories;
    }

    @Data
    @Builder
    public static class SingleRunResult {
        private String profileId;
        private int runIndex;
        private double targetCalories;
        private double rawCalories;
        private double apeBefore;
        private double maeBefore;
        private double adjustedCalories;
        private double apeAfter;
        private double maeAfter;
        private boolean isJsonValid;
        private boolean isFallback;
        private String fallbackReason;
        private long aiTimeMs;
        private long postProcessTimeMs;
        private long totalTimeMs;
        private int directUuidCount;
        private int exactNameCount;
        private int fuzzyNameCount;
        private int unmappedCount;
        private int totalItems;
    }

    @Test
    @DisplayName("Thực hiện thực nghiệm đánh giá tối ưu: 10 hồ sơ tiêu biểu x 2 lần sinh thực đơn (20 calls)")
    public void runComprehensiveDietExperiment() throws Exception {
        log.info("================================================================================");
        log.info("BẮT ĐẦU THỰC NGHIỆM ĐÁNH GIÁ CƠ CHẾ SINH VÀ HIỆU CHỈNH THỰC ĐƠN BODYPILOT AI");
        log.info("Cấu hình tối ưu: 10 Hồ sơ tiêu biểu x 2 lần chạy độc lập = 20 Lượt gọi AI");
        log.info("================================================================================");

        List<TestUserProfile> profiles = create10Profiles();
        List<SingleRunResult> allResults = new ArrayList<>();

        for (TestUserProfile p : profiles) {
            log.info("--------------------------------------------------------------------------------");
            log.info("Đang chạy thực nghiệm Profile {}: Gender={}, Age={}, Height={}cm, Weight={}kg, Goal={}, Activity={}, TargetCal={}",
                    p.getId(), p.getGender(), p.getAge(), p.getHeight(), p.getWeight(), p.getGoal(), p.getActivityLevel(), p.getTargetCalories());

            // Chuẩn bị User Profile Entity giả lập
            UserProfile userProfile = UserProfile.builder()
                    .gender(p.getGender())
                    .age(p.getAge())
                    .heightCm(p.getHeight())
                    .weight(p.getWeight())
                    .activityLevel(p.getActivityLevel().name())
                    .build();

            UserGoal userGoal = UserGoal.builder()
                    .type(p.getGoal().name())
                    .targetWeight(p.getGoal().name().contains("LOSE") ? p.getWeight() - 5.0 : p.getWeight() + 5.0)
                    .build();

            UserMetricHistory metric = UserMetricHistory.builder()
                    .targetCalories(p.getTargetCalories())
                    .goal(p.getGoal().name())
                    .build();

            List<UserAllergy> allergies = new ArrayList<>();
            if (p.getAllergyNote() != null && !p.getAllergyNote().isEmpty()) {
                allergies.add(UserAllergy.builder().note(p.getAllergyNote()).isActive(true).build());
            }

            List<UserDietPreference> diets = new ArrayList<>();
            // (Chế độ ăn nếu có)

            List<UserFoodPreference> dislikes = new ArrayList<>();
            if (p.getDislikeNote() != null && !p.getDislikeNote().isEmpty()) {
                dislikes.add(UserFoodPreference.builder().note(p.getDislikeNote()).isActive(true).build());
            }

            // Lọc danh sách món ăn candidates an toàn RIÊNG CHO HỒ SƠ NÀY
            List<Food> filteredFoods = foodFilterService.getFilteredFoods(allergies, diets, dislikes);
            List<Food> limitedFoods = foodFilterService.selectBalancedFoods(filteredFoods, 150, p.getGoal().name(), diets);
            List<FoodCandidate> candidates = limitedFoods.stream()
                    .map(f -> new FoodCandidate(
                            f.getId(),
                            f.getName(),
                            f.getCategory() != null ? f.getCategory().getName() : "Không xác định",
                            f.getCaloriesPer100g(),
                            f.getProteinPer100g(),
                            f.getFatPer100g(),
                            f.getCarbsPer100g()))
                    .collect(Collectors.toList());

            // Tạo Map tra cứu CHỈ TỪ TẬP MÓN ĂN SAU KHI ĐÃ LỌC AN TOÀN
            Map<UUID, Food> foodMap = filteredFoods.stream()
                    .collect(Collectors.toMap(Food::getId, f -> f, (f1, f2) -> f1));
            Map<String, Food> nameMap = filteredFoods.stream()
                    .collect(Collectors.toMap(f -> f.getName().toLowerCase().trim(), f -> f, (f1, f2) -> f1));

            // Build Prompt chuẩn
            LocalDate startDate = LocalDate.now();
            String prompt = promptBuilder.buildPrompt(userProfile, userGoal, metric, allergies, diets, dislikes, candidates, startDate, 1);

            // Chạy 2 lần độc lập cho mỗi hồ sơ (Tổng cộng 6 * 2 = 12 calls)
            for (int run = 1; run <= 2; run++) {
                log.info("Profile {} - Lần chạy {}/2...", p.getId(), run);
                SingleRunResult res = executeSingleMealGeneration(p, prompt, candidates, foodMap, nameMap, filteredFoods, run);
                allResults.add(res);

                // Delay an toàn 3.5s tránh rate limit
                Thread.sleep(3500);
            }
        }

        // Xuất kết quả CSV và in tổng hợp
        exportResultsToCsv(allResults, profiles);
        printExperimentSummary(allResults, profiles);
    }

    private SingleRunResult executeSingleMealGeneration(
            TestUserProfile profile,
            String prompt,
            List<FoodCandidate> candidates,
            Map<UUID, Food> foodMap,
            Map<String, Food> nameMap,
            List<Food> allFoods,
            int runIndex) {

        long startTotal = System.currentTimeMillis();
        long aiTimeMs = 0;
        long postProcessTimeMs = 0;
        boolean isJsonValid = false;
        boolean isFallback = false;
        String fallbackReason = "None";

        String rawAiResponse = null;
        RawDailyEating[] rawDays = null;

        try {
            long startAi = System.currentTimeMillis();
            rawAiResponse = geminiClient.callGemini(prompt,
                    "Bạn là một chuyên gia dinh dưỡng và lên thực đơn cá nhân hóa chuyên nghiệp. Hãy đưa ra thực đơn cực kỳ chi tiết, khoa học, thực tế dưới dạng JSON array hợp lệ phù hợp với danh sách thực phẩm được cung cấp.",
                    true);
            aiTimeMs = System.currentTimeMillis() - startAi;
        } catch (Exception e) {
            aiTimeMs = System.currentTimeMillis() - startTotal;
            isFallback = true;
            if (e.getMessage() != null && e.getMessage().contains("429")) {
                fallbackReason = "HTTP 429 (Rate Limit)";
            } else if (e.getMessage() != null && e.getMessage().contains("Timeout")) {
                fallbackReason = "Timeout";
            } else if (e.getMessage() != null && (e.getMessage().contains("500") || e.getMessage().contains("503"))) {
                fallbackReason = "HTTP Server Error";
            } else {
                fallbackReason = "AI Connection Error: " + e.getMessage();
            }
            log.warn("Gọi Gemini thất bại: {}", fallbackReason);
        }

        long startPost = System.currentTimeMillis();
        int directUuid = 0;
        int exactName = 0;
        int fuzzyName = 0;
        int unmapped = 0;
        int totalItems = 0;
        double rawCalories = 0.0;
        double adjustedCalories = 0.0;

        if (!isFallback && rawAiResponse != null) {
            try {
                String cleanedJson = cleanMarkdownJson(rawAiResponse);
                rawDays = objectMapper.readValue(cleanedJson, RawDailyEating[].class);
                if (rawDays != null && rawDays.length > 0) {
                    isJsonValid = true;
                } else {
                    isJsonValid = false;
                    isFallback = true;
                    fallbackReason = "JSON Empty Array";
                }
            } catch (Exception e) {
                isJsonValid = false;
                isFallback = true;
                fallbackReason = "JSON Parse Error: " + e.getMessage();
            }
        }

        if (isJsonValid && rawDays != null && rawDays.length > 0) {
            RawDailyEating day = rawDays[0];
            List<RawMealItemMatched> matchedItems = new ArrayList<>();

            if (day.getMealSlots() != null) {
                for (RawMealSlot slot : day.getMealSlots()) {
                    if (slot.getItems() != null) {
                        for (RawMealItem rawItem : slot.getItems()) {
                            totalItems++;
                            String foodIdStr = rawItem.getFoodId() != null ? rawItem.getFoodId().trim() : "";
                            String foodNameStr = rawItem.getFoodName() != null ? rawItem.getFoodName().trim() : "";
                            BigDecimal qty = rawItem.getServingQuantity() != null ? rawItem.getServingQuantity() : new BigDecimal("100.0");

                            Food matchedFood = null;
                            int matchType = 4; // 1: UUID, 2: exact, 3: fuzzy, 4: unmapped

                            // Mức 1: foodId
                            if (!foodIdStr.isEmpty()) {
                                try {
                                    UUID fid = UUID.fromString(foodIdStr);
                                    if (foodMap.containsKey(fid)) {
                                        matchedFood = foodMap.get(fid);
                                        matchType = 1;
                                    }
                                } catch (Exception ignored) {}
                            }

                            // Mức 2: Tên chính xác
                            if (matchedFood == null && !foodNameStr.isEmpty()) {
                                String cleanName = foodNameStr.toLowerCase().trim();
                                if (nameMap.containsKey(cleanName)) {
                                    matchedFood = nameMap.get(cleanName);
                                    matchType = 2;
                                }
                            }

                            // Mức 3: Khớp mờ
                            if (matchedFood == null && !foodNameStr.isEmpty()) {
                                String key = foodNameStr.toLowerCase();
                                matchedFood = allFoods.stream()
                                        .filter(f -> f.getName().toLowerCase().contains(key) || key.contains(f.getName().toLowerCase()))
                                        .findFirst()
                                        .orElse(null);
                                if (matchedFood != null) {
                                    matchType = 3;
                                }
                            }

                            if (matchType == 1) directUuid++;
                            else if (matchType == 2) exactName++;
                            else if (matchType == 3) fuzzyName++;
                            else unmapped++;

                            if (matchedFood != null) {
                                BigDecimal factor = qty.divide(new BigDecimal("100"), 4, RoundingMode.HALF_UP);
                                BigDecimal cal = matchedFood.getCaloriesPer100g().multiply(factor).setScale(1, RoundingMode.HALF_UP);
                                rawCalories += cal.doubleValue();
                                matchedItems.add(new RawMealItemMatched(matchedFood, qty, cal));
                            }
                        }
                    }
                }
            }

            // Cơ chế APE và Portion Scaling (Công thức 5.1 & Ngưỡng 5%)
            double targetCal = profile.getTargetCalories();
            double calDiff = Math.abs(rawCalories - targetCal);
            double apeBefore = (targetCal > 0) ? (calDiff / targetCal) * 100.0 : 0.0;
            double maeBefore = calDiff;

            if (apeBefore > 5.0 && rawCalories > 0) {
                // Thực hiện portion scaling
                BigDecimal scaleFactor = BigDecimal.valueOf(targetCal / rawCalories).setScale(4, RoundingMode.HALF_UP);
                if (scaleFactor.compareTo(new BigDecimal("0.5")) < 0) scaleFactor = new BigDecimal("0.5");
                if (scaleFactor.compareTo(new BigDecimal("2.0")) > 0) scaleFactor = new BigDecimal("2.0");

                for (RawMealItemMatched item : matchedItems) {
                    Food f = item.food;
                    BigDecimal scaledQty = item.quantity.multiply(scaleFactor).setScale(1, RoundingMode.HALF_UP);
                    BigDecimal minQty = presetMealFallbackBuilder.getMinQuantityForCategory(f);
                    BigDecimal maxQty = presetMealFallbackBuilder.getMaxQuantityForCategory(f);

                    if (scaledQty.compareTo(minQty) < 0) scaledQty = minQty;
                    if (scaledQty.compareTo(maxQty) > 0) scaledQty = maxQty;

                    BigDecimal factor = scaledQty.divide(new BigDecimal("100"), 4, RoundingMode.HALF_UP);
                    BigDecimal newCal = f.getCaloriesPer100g().multiply(factor).setScale(1, RoundingMode.HALF_UP);
                    adjustedCalories += newCal.doubleValue();
                }
            } else {
                // Giữ nguyên khẩu phần tự nhiên của AI (APE <= 5%)
                adjustedCalories = rawCalories;
            }

            postProcessTimeMs = System.currentTimeMillis() - startPost;
            long totalTimeMs = System.currentTimeMillis() - startTotal;

            double apeAfter = (targetCal > 0) ? (Math.abs(adjustedCalories - targetCal) / targetCal) * 100.0 : 0.0;
            double maeAfter = Math.abs(adjustedCalories - targetCal);

            return SingleRunResult.builder()
                    .profileId(profile.getId())
                    .runIndex(runIndex)
                    .targetCalories(targetCal)
                    .rawCalories(round(rawCalories, 1))
                    .apeBefore(round(apeBefore, 2))
                    .maeBefore(round(maeBefore, 1))
                    .adjustedCalories(round(adjustedCalories, 1))
                    .apeAfter(round(apeAfter, 2))
                    .maeAfter(round(maeAfter, 1))
                    .isJsonValid(isJsonValid)
                    .isFallback(isFallback)
                    .fallbackReason(fallbackReason)
                    .aiTimeMs(aiTimeMs)
                    .postProcessTimeMs(postProcessTimeMs)
                    .totalTimeMs(totalTimeMs)
                    .directUuidCount(directUuid)
                    .exactNameCount(exactName)
                    .fuzzyNameCount(fuzzyName)
                    .unmappedCount(unmapped)
                    .totalItems(totalItems)
                    .build();
        } else {
            // Trường hợp kích hoạt Preset Fallback
            postProcessTimeMs = System.currentTimeMillis() - startPost;
            long totalTimeMs = System.currentTimeMillis() - startTotal;

            return SingleRunResult.builder()
                    .profileId(profile.getId())
                    .runIndex(runIndex)
                    .targetCalories(profile.getTargetCalories())
                    .rawCalories(0.0)
                    .apeBefore(100.0)
                    .maeBefore(profile.getTargetCalories())
                    .adjustedCalories(profile.getTargetCalories())
                    .apeAfter(0.0)
                    .maeAfter(0.0)
                    .isJsonValid(false)
                    .isFallback(true)
                    .fallbackReason(fallbackReason)
                    .aiTimeMs(aiTimeMs)
                    .postProcessTimeMs(postProcessTimeMs)
                    .totalTimeMs(totalTimeMs)
                    .directUuidCount(0)
                    .exactNameCount(0)
                    .fuzzyNameCount(0)
                    .unmappedCount(0)
                    .totalItems(0)
                    .build();
        }
    }

    private static class RawMealItemMatched {
        Food food;
        BigDecimal quantity;
        BigDecimal calories;

        public RawMealItemMatched(Food food, BigDecimal quantity, BigDecimal calories) {
            this.food = food;
            this.quantity = quantity;
            this.calories = calories;
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
        cleaned = cleaned.replaceAll(",\\s*([\\]}])", "$1");
        return cleaned.trim();
    }

    private double round(double val, int decimals) {
        return BigDecimal.valueOf(val).setScale(decimals, RoundingMode.HALF_UP).doubleValue();
    }

    private List<TestUserProfile> create10Profiles() {
        List<TestUserProfile> list = new ArrayList<>();

        // Profile 1: Nam trẻ tuổi giảm cân nhẹ
        list.add(buildProfile("P01", "MALE", 24, 175.0, 75.0, Goal.LOSE_0_5KG, ActivityLevel.SEDENTARY, "Standard", null, null));
        // Profile 2: Nữ văn phòng giảm cân, dị ứng đậu phộng
        list.add(buildProfile("P02", "FEMALE", 28, 160.0, 58.0, Goal.LOSE_0_5KG, ActivityLevel.LIGHT, "Standard", "Đậu phộng", null));
        // Profile 3: Nam sinh viên tập gym tăng cơ, ghét thịt bò
        list.add(buildProfile("P03", "MALE", 21, 180.0, 68.0, Goal.GAIN_MUSCLE, ActivityLevel.VERY_ACTIVE, "Standard", null, "Thịt bò"));
        // Profile 4: Nữ ăn chay duy trì sức khỏe, dị ứng hải sản
        list.add(buildProfile("P04", "FEMALE", 35, 155.0, 48.0, Goal.MAINTAIN, ActivityLevel.LIGHT, "Vegetarian", "Hải sản, tôm, cua", null));
        // Profile 5: Nam thừa cân giảm cân sâu
        list.add(buildProfile("P05", "MALE", 32, 170.0, 85.0, Goal.LOSE_1KG, ActivityLevel.SEDENTARY, "Standard", null, "Thịt mỡ, da gà"));
        // Profile 6: Nữ trẻ tăng cân nhẹ
        list.add(buildProfile("P06", "FEMALE", 22, 165.0, 48.0, Goal.GAIN_0_5KG, ActivityLevel.MODERATE, "Standard", null, null));
        // Profile 7: Nam trung niên duy trì sức khỏe, dị ứng sữa bò
        list.add(buildProfile("P07", "MALE", 45, 172.0, 70.0, Goal.HEALTHY_LIFESTYLE, ActivityLevel.MODERATE, "Standard", "Sữa bò", null));
        // Profile 8: Nữ nhân viên văn phòng giảm cân nhanh, kiêng dầu mỡ
        list.add(buildProfile("P08", "FEMALE", 30, 158.0, 65.0, Goal.LOSE_1KG, ActivityLevel.SEDENTARY, "Standard", null, "Mỡ động vật, đồ chiên rán"));
        // Profile 9: Nam vận động viên tăng cân tăng cơ cường độ cao
        list.add(buildProfile("P09", "MALE", 26, 182.0, 82.0, Goal.GAIN_1KG, ActivityLevel.VERY_ACTIVE, "High Protein", null, null));
        // Profile 10: Nữ rèn luyện sức bền, dị ứng trứng và kiêng hải sản
        list.add(buildProfile("P10", "FEMALE", 29, 162.0, 52.0, Goal.ENDURANCE, ActivityLevel.ACTIVE, "Standard", "Trứng", "Hải sản, tôm, cua"));

        return list;
    }

    private TestUserProfile buildProfile(
            String id, String gender, int age, double height, double weight,
            Goal goal, ActivityLevel activity, String diet, String allergy, String dislike) {

        CalorieCalculationResult calc = calorieCalculatorService.calculateMetrics(
                weight, height, age, Gender.valueOf(gender), activity, goal);

        return TestUserProfile.builder()
                .id(id)
                .gender(gender)
                .age(age)
                .height(height)
                .weight(weight)
                .goal(goal)
                .activityLevel(activity)
                .dietType(diet)
                .allergyNote(allergy)
                .dislikeNote(dislike)
                .targetCalories(calc.getTargetCalories())
                .build();
    }

    private PrintWriter createUtf8Writer(String filePath) throws Exception {
        FileOutputStream fos = new FileOutputStream(filePath);
        // Write UTF-8 BOM so Excel opens Vietnamese characters correctly
        fos.write(new byte[]{(byte) 0xEF, (byte) 0xBB, (byte) 0xBF});
        return new PrintWriter(new BufferedWriter(new OutputStreamWriter(fos, StandardCharsets.UTF_8)), true);
    }

    private void exportResultsToCsv(List<SingleRunResult> results, List<TestUserProfile> profiles) {
        try {
            // =========================================================================
            // BẢNG 1: Thông tin các hồ sơ thực nghiệm
            // =========================================================================
            try (PrintWriter w = createUtf8Writer("target/bang1_thong_tin_ho_so.csv")) {
                w.println("ID,Giới tính,Tuổi,Chiều cao (cm),Cân nặng (kg),Mục tiêu,Mức vận động,Chế độ ăn,Dị ứng / Hạn chế,E_target (kcal)");
                for (TestUserProfile p : profiles) {
                    String restriction = (p.getAllergyNote() != null ? p.getAllergyNote() : (p.getDislikeNote() != null ? p.getDislikeNote() : "Không"))
                            .replace(",", ";").replace("\"", "'");
                    w.println(String.format(java.util.Locale.US, "%s,%s,%d,%.1f,%.1f,%s,%s,%s,%s,%.1f",
                            p.getId(), p.getGender(), p.getAge(), p.getHeight(), p.getWeight(),
                            p.getGoal().name(), p.getActivityLevel().name(), p.getDietType(),
                            restriction, p.getTargetCalories()));
                }
            }

            // =========================================================================
            // BẢNG 2: Kết quả từng lần sinh thực đơn
            // =========================================================================
            try (PrintWriter w = createUtf8Writer("target/bang2_ket_qua_tung_lan_sinh.csv")) {
                w.println("Profile,Lần,E_target (kcal),E_raw (kcal),APE trước (%),E_adjusted (kcal),APE sau (%),Fallback,Thời gian (ms)");
                for (SingleRunResult r : results) {
                    String fallbackText = r.isFallback() ? "Có (" + r.getFallbackReason().replace(",", ";").replace("\"", "'") + ")" : "Không";
                    w.println(String.format(java.util.Locale.US, "%s,%d,%.1f,%.1f,%.2f%%,%.1f,%.2f%%,%s,%d",
                            r.getProfileId(), r.getRunIndex(), r.getTargetCalories(), r.getRawCalories(),
                            r.getApeBefore(), r.getAdjustedCalories(), r.getApeAfter(),
                            fallbackText, r.getTotalTimeMs()));
                }
            }

            List<SingleRunResult> successfulRuns = results.stream().filter(r -> !r.isFallback()).collect(Collectors.toList());
            int totalRuns = results.size();
            int validJsonCount = (int) results.stream().filter(SingleRunResult::isJsonValid).count();
            int fallbackCount = (int) results.stream().filter(SingleRunResult::isFallback).count();

            double avgApeBefore = successfulRuns.stream().mapToDouble(SingleRunResult::getApeBefore).average().orElse(0.0);
            double avgApeAfter = successfulRuns.stream().mapToDouble(SingleRunResult::getApeAfter).average().orElse(0.0);
            double avgMaeBefore = successfulRuns.stream().mapToDouble(SingleRunResult::getMaeBefore).average().orElse(0.0);
            double avgMaeAfter = successfulRuns.stream().mapToDouble(SingleRunResult::getMaeAfter).average().orElse(0.0);

            // =========================================================================
            // BẢNG 3: Tổng hợp kết quả thực nghiệm
            // =========================================================================
            try (PrintWriter w = createUtf8Writer("target/bang3_tong_hop_ket_qua.csv")) {
                w.println("Chỉ số,Trước hiệu chỉnh,Sau hiệu chỉnh");
                w.println(String.format(java.util.Locale.US, "MAPE (%%),%.2f%%,%.2f%%", avgApeBefore, avgApeAfter));
                w.println(String.format(java.util.Locale.US, "MAE (kcal),%.1f,%.1f", avgMaeBefore, avgMaeAfter));
            }

            // =========================================================================
            // BẢNG 4: Chất lượng phản hồi AI
            // =========================================================================
            try (PrintWriter w = createUtf8Writer("target/bang4_chat_luong_phan_hoi_ai.csv")) {
                w.println("Chỉ số,Số lượng,Tỷ lệ (%)");
                w.println(String.format(java.util.Locale.US, "JSON hợp lệ,%d,%.2f%%", validJsonCount, (validJsonCount * 100.0) / totalRuns));
                w.println(String.format(java.util.Locale.US, "JSON không hợp lệ,%d,%.2f%%", totalRuns - validJsonCount, ((totalRuns - validJsonCount) * 100.0) / totalRuns));
                w.println(String.format(java.util.Locale.US, "Tổng số,%d,100.00%%", totalRuns));
            }

            int totalItems = results.stream().mapToInt(SingleRunResult::getTotalItems).sum();
            int totalUuid = results.stream().mapToInt(SingleRunResult::getDirectUuidCount).sum();
            int totalExact = results.stream().mapToInt(SingleRunResult::getExactNameCount).sum();
            int totalFuzzy = results.stream().mapToInt(SingleRunResult::getFuzzyNameCount).sum();
            int totalUnmapped = results.stream().mapToInt(SingleRunResult::getUnmappedCount).sum();

            // =========================================================================
            // BẢNG 5: Kết quả ánh xạ món ăn
            // =========================================================================
            try (PrintWriter w = createUtf8Writer("target/bang5_ket_qua_anh_xa_mon_an.csv")) {
                w.println("Mức ánh xạ,Số lượng,Tỷ lệ (%)");
                w.println(String.format(java.util.Locale.US, "foodId,%d,%.2f%%", totalUuid, totalItems > 0 ? (totalUuid * 100.0) / totalItems : 0.0));
                w.println(String.format(java.util.Locale.US, "Tên chính xác,%d,%.2f%%", totalExact, totalItems > 0 ? (totalExact * 100.0) / totalItems : 0.0));
                w.println(String.format(java.util.Locale.US, "Khớp mờ,%d,%.2f%%", totalFuzzy, totalItems > 0 ? (totalFuzzy * 100.0) / totalItems : 0.0));
                w.println(String.format(java.util.Locale.US, "Không ánh xạ được,%d,%.2f%%", totalUnmapped, totalItems > 0 ? (totalUnmapped * 100.0) / totalItems : 0.0));
                w.println(String.format(java.util.Locale.US, "Tổng số món,%d,100.00%%", totalItems));
            }

            int timeoutCount = (int) results.stream().filter(r -> r.isFallback() && r.getFallbackReason().contains("Timeout")).count();
            int httpErrorCount = (int) results.stream().filter(r -> r.isFallback() && (r.getFallbackReason().contains("429") || r.getFallbackReason().contains("500") || r.getFallbackReason().contains("401"))).count();
            int jsonErrorCount = (int) results.stream().filter(r -> r.isFallback() && r.getFallbackReason().contains("JSON")).count();
            int otherErrorCount = fallbackCount - (timeoutCount + httpErrorCount + jsonErrorCount);

            // =========================================================================
            // BẢNG 6: Cơ chế dự phòng
            // =========================================================================
            try (PrintWriter w = createUtf8Writer("target/bang6_co_che_du_phong.csv")) {
                w.println("Nguyên nhân,Số lần,Tỷ lệ (%)");
                w.println(String.format(java.util.Locale.US, "Timeout,%d,%.2f%%", timeoutCount, (timeoutCount * 100.0) / totalRuns));
                w.println(String.format(java.util.Locale.US, "HTTP error,%d,%.2f%%", httpErrorCount, (httpErrorCount * 100.0) / totalRuns));
                w.println(String.format(java.util.Locale.US, "JSON không hợp lệ,%d,%.2f%%", jsonErrorCount, (jsonErrorCount * 100.0) / totalRuns));
                w.println(String.format(java.util.Locale.US, "Lỗi khác,%d,%.2f%%", otherErrorCount, (otherErrorCount * 100.0) / totalRuns));
                w.println(String.format(java.util.Locale.US, "Tổng fallback,%d,%.2f%%", fallbackCount, (fallbackCount * 100.0) / totalRuns));
            }

            // File tổng hợp Markdown tiện lợi
            try (PrintWriter w = createUtf8Writer("target/bao_cao_thuc_nghiem_6_bang.md")) {
                w.println("# BÁO CÁO KẾT QUẢ THỰC NGHIỆM HỆ THỐNG BODYPILOT AI");
                w.println();
                w.println("### Bảng 1. Thông tin các hồ sơ thực nghiệm");
                w.println("| ID | Giới tính | Tuổi | Chiều cao | Cân nặng | Mục tiêu | Mức vận động | Chế độ ăn | Dị ứng / Hạn chế | E_target |");
                w.println("| :--- | :---: | :---: | :---: | :---: | :---: | :---: | :---: | :---: | :---: |");
                for (TestUserProfile p : profiles) {
                    w.printf("| %s | %s | %d | %.1f cm | %.1f kg | %s | %s | %s | %s | %.1f kcal |\n",
                            p.getId(), p.getGender(), p.getAge(), p.getHeight(), p.getWeight(),
                            p.getGoal().name(), p.getActivityLevel().name(), p.getDietType(),
                            (p.getAllergyNote() != null ? p.getAllergyNote() : (p.getDislikeNote() != null ? p.getDislikeNote() : "Không")),
                            p.getTargetCalories());
                }
                w.println();
                w.println("### Bảng 2. Kết quả từng lần sinh thực đơn");
                w.println("| Profile | Lần | E_target | E_raw | APE trước (%) | E_adjusted | APE sau (%) | Fallback | Thời gian (ms) |");
                w.println("| :---: | :---: | :---: | :---: | :---: | :---: | :---: | :---: | :---: |");
                for (SingleRunResult r : results) {
                    w.printf("| %s | %d | %.1f | %.1f | %.2f%% | %.1f | %.2f%% | %s | %d |\n",
                            r.getProfileId(), r.getRunIndex(), r.getTargetCalories(), r.getRawCalories(),
                            r.getApeBefore(), r.getAdjustedCalories(), r.getApeAfter(),
                            r.isFallback() ? "Có" : "Không", r.getTotalTimeMs());
                }
                w.println();
                w.println("### Bảng 3. Tổng hợp kết quả thực nghiệm");
                w.println("| Chỉ số | Trước hiệu chỉnh | Sau hiệu chỉnh |");
                w.println("| :--- | :---: | :---: |");
                w.printf("| MAPE (%%) | %.2f%% | %.2f%% |\n", avgApeBefore, avgApeAfter);
                w.printf("| MAE (kcal) | %.1f kcal | %.1f kcal |\n", avgMaeBefore, avgMaeAfter);
                w.println();
                w.println("### Bảng 4. Chất lượng phản hồi AI");
                w.println("| Chỉ số | Số lượng | Tỷ lệ (%) |");
                w.println("| :--- | :---: | :---: |");
                w.printf("| JSON hợp lệ | %d | %.2f%% |\n", validJsonCount, (validJsonCount * 100.0) / totalRuns);
                w.printf("| JSON không hợp lệ | %d | %.2f%% |\n", totalRuns - validJsonCount, ((totalRuns - validJsonCount) * 100.0) / totalRuns);
                w.printf("| Tổng số | %d | 100.0%% |\n", totalRuns);
                w.println();
                w.println("### Bảng 5. Kết quả ánh xạ món ăn");
                w.println("| Mức ánh xạ | Số lượng | Tỷ lệ (%) |");
                w.println("| :--- | :---: | :---: |");
                w.printf("| foodId | %d | %.2f%% |\n", totalUuid, totalItems > 0 ? (totalUuid * 100.0) / totalItems : 0.0);
                w.printf("| Tên chính xác | %d | %.2f%% |\n", totalExact, totalItems > 0 ? (totalExact * 100.0) / totalItems : 0.0);
                w.printf("| Khớp mờ | %d | %.2f%% |\n", totalFuzzy, totalItems > 0 ? (totalFuzzy * 100.0) / totalItems : 0.0);
                w.printf("| Không ánh xạ được | %d | %.2f%% |\n", totalUnmapped, totalItems > 0 ? (totalUnmapped * 100.0) / totalItems : 0.0);
                w.println();
                w.println("### Bảng 6. Cơ chế dự phòng");
                w.println("| Nguyên nhân | Số lần | Tỷ lệ (%) |");
                w.println("| :--- | :---: | :---: |");
                w.printf("| Timeout | %d | %.2f%% |\n", timeoutCount, (timeoutCount * 100.0) / totalRuns);
                w.printf("| HTTP error | %d | %.2f%% |\n", httpErrorCount, (httpErrorCount * 100.0) / totalRuns);
                w.printf("| JSON không hợp lệ | %d | %.2f%% |\n", jsonErrorCount, (jsonErrorCount * 100.0) / totalRuns);
                w.printf("| Lỗi khác | %d | %.2f%% |\n", otherErrorCount, (otherErrorCount * 100.0) / totalRuns);
                w.printf("| Tổng fallback | %d | %.2f%% |\n", fallbackCount, (fallbackCount * 100.0) / totalRuns);
            }

            log.info("ĐÃ XUẤT THÀNH CÔNG 6 FILE CSV VÀ 1 FILE MARKDOWN TẠI THƯ MỤC 'target/':");
            log.info("1. target/bang1_thong_tin_ho_so.csv");
            log.info("2. target/bang2_ket_qua_tung_lan_sinh.csv");
            log.info("3. target/bang3_tong_hop_ket_qua.csv");
            log.info("4. target/bang4_chat_luong_phan_hoi_ai.csv");
            log.info("5. target/bang5_ket_qua_anh_xa_mon_an.csv");
            log.info("6. target/bang6_co_che_du_phong.csv");
            log.info("7. target/bao_cao_thuc_nghiem_6_bang.md");
        } catch (Exception e) {
            log.error("Lỗi xuất 6 bảng CSV: {}", e.getMessage(), e);
        }
    }

    private void printExperimentSummary(List<SingleRunResult> results, List<TestUserProfile> profiles) {
        log.info("================================================================================");
        log.info("KẾT QUẢ TỔNG HỢP THỰC NGHIỆM ĐÁNH GIÁ (N = {} LƯỢT CHẠY)", results.size());
        log.info("================================================================================");

        List<SingleRunResult> successfulRuns = results.stream().filter(r -> !r.isFallback()).collect(Collectors.toList());
        int totalRuns = results.size();
        int validJsonCount = (int) results.stream().filter(SingleRunResult::isJsonValid).count();
        int fallbackCount = (int) results.stream().filter(SingleRunResult::isFallback).count();

        double avgApeBefore = successfulRuns.stream().mapToDouble(SingleRunResult::getApeBefore).average().orElse(0.0);
        double avgApeAfter = successfulRuns.stream().mapToDouble(SingleRunResult::getApeAfter).average().orElse(0.0);
        double avgMaeBefore = successfulRuns.stream().mapToDouble(SingleRunResult::getMaeBefore).average().orElse(0.0);
        double avgMaeAfter = successfulRuns.stream().mapToDouble(SingleRunResult::getMaeAfter).average().orElse(0.0);

        int totalItems = results.stream().mapToInt(SingleRunResult::getTotalItems).sum();
        int totalUuid = results.stream().mapToInt(SingleRunResult::getDirectUuidCount).sum();
        int totalExact = results.stream().mapToInt(SingleRunResult::getExactNameCount).sum();
        int totalFuzzy = results.stream().mapToInt(SingleRunResult::getFuzzyNameCount).sum();
        int totalUnmapped = results.stream().mapToInt(SingleRunResult::getUnmappedCount).sum();

        double avgAiTime = results.stream().mapToLong(SingleRunResult::getAiTimeMs).average().orElse(0.0);
        double avgTotalTime = results.stream().mapToLong(SingleRunResult::getTotalTimeMs).average().orElse(0.0);

        log.info("1. MAPE & MAE:");
        log.info("   - MAPE trước hiệu chỉnh: {} %", round(avgApeBefore, 2));
        log.info("   - MAPE sau hiệu chỉnh:   {} %", round(avgApeAfter, 2));
        log.info("   - MAE trước hiệu chỉnh:  {} kcal", round(avgMaeBefore, 1));
        log.info("   - MAE sau hiệu chỉnh:    {} kcal", round(avgMaeAfter, 1));

        log.info("2. Phản hồi JSON:");
        log.info("   - Tổng số lượt gọi AI:   {}", totalRuns);
        log.info("   - JSON hợp lệ:           {} ({} %)", validJsonCount, round((validJsonCount * 100.0) / totalRuns, 2));
        log.info("   - JSON không hợp lệ:     {} ({} %)", totalRuns - validJsonCount, round(((totalRuns - validJsonCount) * 100.0) / totalRuns, 2));

        log.info("3. Ánh xạ món ăn (Tổng số món sinh ra = {}):", totalItems);
        log.info("   - Khớp trực tiếp UUID:   {} ({} %)", totalUuid, totalItems > 0 ? round((totalUuid * 100.0) / totalItems, 2) : 0);
        log.info("   - Khớp tên chính xác:    {} ({} %)", totalExact, totalItems > 0 ? round((totalExact * 100.0) / totalItems, 2) : 0);
        log.info("   - Khớp mờ (Fuzzy):       {} ({} %)", totalFuzzy, totalItems > 0 ? round((totalFuzzy * 100.0) / totalItems, 2) : 0);
        log.info("   - Không ánh xạ được:     {} ({} %)", totalUnmapped, totalItems > 0 ? round((totalUnmapped * 100.0) / totalItems, 2) : 0);

        log.info("4. Cơ chế dự phòng (Fallback):");
        log.info("   - Số lần kích hoạt Fallback: {} / {} ({} %)", fallbackCount, totalRuns, round((fallbackCount * 100.0) / totalRuns, 2));

        log.info("5. Thời gian phản hồi:");
        log.info("   - Thời gian gọi AI trung bình:    {} ms", round(avgAiTime, 1));
        log.info("   - Tổng thời gian xử lý trung bình: {} ms", round(avgTotalTime, 1));
        log.info("================================================================================");
    }
}
