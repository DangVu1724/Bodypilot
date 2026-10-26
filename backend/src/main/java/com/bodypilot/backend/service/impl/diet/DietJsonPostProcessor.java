package com.bodypilot.backend.service.impl.diet;

import java.math.BigDecimal;
import java.math.RoundingMode;
import java.time.LocalDate;
import java.util.ArrayList;
import java.util.HashMap;
import java.util.List;
import java.util.Map;
import java.util.UUID;
import java.util.stream.Collectors;

import org.springframework.stereotype.Component;

import com.bodypilot.backend.model.dto.nutrition.DailyEatingDTO;
import com.bodypilot.backend.model.dto.nutrition.MealItemDTO;
import com.bodypilot.backend.model.dto.nutrition.MealSlotDTO;
import com.bodypilot.backend.model.entity.nutrition.Food;
import com.bodypilot.backend.model.enums.MealType;
import com.bodypilot.backend.service.AiDietEvaluationService;
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
 * Service dedicated to parsing and post-processing AI-generated Diet JSON
 * responses
 * using strongly-typed fail-safe Raw DTOs.
 */
@Component
@RequiredArgsConstructor
@Slf4j
public class DietJsonPostProcessor {

    private final DietFoodFilterService foodFilterService;
    private final PresetMealFallbackBuilder presetMealFallbackBuilder;
    private final AiDietEvaluationService aiDietEvaluationService;

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

    public String processAndLinkFoods(String rawJson, BigDecimal targetCalories) {
        return processAndLinkFoods(rawJson, targetCalories, null, 0, 0, 0, 0L);
    }

    public String processAndLinkFoods(String rawJson, BigDecimal targetCalories, UUID userId,
            int allergyCount, int dietCount, int dislikeCount, long executionTimeMs) {
        try {
            if (rawJson == null || rawJson.trim().isEmpty()) {
                return "[]";
            }
            String cleanedJson = cleanMarkdownJson(rawJson);

            // Ép thẳng chuỗi JSON thành mảng Raw DTOs (Fail-safe, 0-crash)
            RawDailyEating[] rawDays = objectMapper.readValue(cleanedJson, RawDailyEating[].class);

            // Lấy danh sách món ăn AN TOÀN ĐÃ QUA BỘ LỌC DỊ ỨNG/KIÊNG CỮ của User
            List<Food> availableFoods = (userId != null)
                    ? foodFilterService.getFilteredFoodsForUser(userId)
                    : foodFilterService.getAllFoodsCached();

            Map<UUID, Food> foodMap = availableFoods.stream()
                    .collect(Collectors.toMap(Food::getId, f -> f, (f1, f2) -> f1));
            Map<String, Food> nameMap = availableFoods.stream()
                    .collect(Collectors.toMap(f -> f.getName().toLowerCase().trim(), f -> f, (f1, f2) -> f1));

            // Phân loại danh sách món an toàn theo Category để hỗ trợ tráo đổi thế thân thông minh
            Map<String, List<Food>> catMap = new HashMap<>();
            for (Food f : availableFoods) {
                if (f.getCategory() != null && f.getCategory().getCode() != null) {
                    catMap.computeIfAbsent(f.getCategory().getCode().toUpperCase().trim(), k -> new ArrayList<>())
                            .add(f);
                }
            }
            List<Food> allFoodsGlobal = foodFilterService.getAllFoodsCached();

            List<DailyEatingDTO> list = new ArrayList<>();
            for (RawDailyEating rawDay : rawDays) {
                LocalDate date = (rawDay.getDate() != null && !rawDay.getDate().isEmpty())
                        ? LocalDate.parse(rawDay.getDate())
                        : LocalDate.now();
                String note = (rawDay.getNote() != null) ? rawDay.getNote() : "";
                boolean isAiGenerated = Boolean.TRUE.equals(rawDay.getIsAiGenerated());

                List<MealSlotDTO> mealSlots = new ArrayList<>();
                if (rawDay.getMealSlots() != null) {
                    for (RawMealSlot rawSlot : rawDay.getMealSlots()) {
                        String mealTypeStr = (rawSlot.getMealType() != null) ? rawSlot.getMealType() : "BREAKFAST";
                        MealType mealType = parseMealTypeSafely(mealTypeStr);
                        String customName = (rawSlot.getCustomName() != null) ? rawSlot.getCustomName() : "";
                        Integer orderIndex = (rawSlot.getOrderIndex() != null) ? rawSlot.getOrderIndex() : 0;

                        List<MealItemDTO> items = new ArrayList<>();
                        if (rawSlot.getItems() != null) {
                            int itemOrder = 0;
                            for (RawMealItem rawItem : rawSlot.getItems()) {
                                String foodIdStr = (rawItem.getFoodId() != null) ? rawItem.getFoodId().trim() : "";
                                String foodNameStr = (rawItem.getFoodName() != null) ? rawItem.getFoodName().trim()
                                        : "";
                                BigDecimal servingQuantity = (rawItem.getServingQuantity() != null)
                                        ? rawItem.getServingQuantity()
                                        : new BigDecimal("100.0");

                                Food food = matchFoodInDatabase(foodIdStr, foodNameStr, foodMap, nameMap, availableFoods);

                                // BƯỚC BẢO VỆ AN TOÀN & TRÁO ĐỔI THẾ THÂN THÔNG MINH
                                if (food == null && (!foodIdStr.isEmpty() || !foodNameStr.isEmpty())) {
                                    // Tra cứu món gốc trong kho dữ liệu tổng để xác định nhóm Category
                                    Food originalViolatingFood = findFoodInGlobalList(foodIdStr, foodNameStr, allFoodsGlobal);
                                    String catCode = (originalViolatingFood != null && originalViolatingFood.getCategory() != null && originalViolatingFood.getCategory().getCode() != null)
                                            ? originalViolatingFood.getCategory().getCode().toUpperCase()
                                            : "OTHERS";

                                    List<Food> candidates = catMap.getOrDefault(catCode, availableFoods);
                                    if (!candidates.isEmpty()) {
                                        if (originalViolatingFood != null && originalViolatingFood.getCaloriesPer100g() != null) {
                                            double origCal = originalViolatingFood.getCaloriesPer100g().doubleValue();
                                            double origProtein = originalViolatingFood.getProteinPer100g() != null
                                                    ? originalViolatingFood.getProteinPer100g().doubleValue() : 0.0;

                                            // Chọn món trong tệp AN TOÀN có độ tương đồng Calo & Macro gần nhất với món gốc
                                            food = candidates.stream()
                                                    .min((f1, f2) -> {
                                                        double cal1 = f1.getCaloriesPer100g() != null ? f1.getCaloriesPer100g().doubleValue() : 0.0;
                                                        double pro1 = f1.getProteinPer100g() != null ? f1.getProteinPer100g().doubleValue() : 0.0;
                                                        double diff1 = Math.abs(cal1 - origCal) + Math.abs(pro1 - origProtein) * 1.5;

                                                        double cal2 = f2.getCaloriesPer100g() != null ? f2.getCaloriesPer100g().doubleValue() : 0.0;
                                                        double pro2 = f2.getProteinPer100g() != null ? f2.getProteinPer100g().doubleValue() : 0.0;
                                                        double diff2 = Math.abs(cal2 - origCal) + Math.abs(pro2 - origProtein) * 1.5;

                                                        return Double.compare(diff1, diff2);
                                                    })
                                                    .orElse(candidates.get(0));
                                        } else {
                                            // Nếu AI bịa tên không có trong DB gốc, chọn món có healthScore cao nhất trong tệp an toàn
                                            food = candidates.stream()
                                                    .max((f1, f2) -> Integer.compare(
                                                            f1.getHealthScore() != null ? f1.getHealthScore() : 0,
                                                            f2.getHealthScore() != null ? f2.getHealthScore() : 0))
                                                    .orElse(candidates.get(0));
                                        }

                                        log.info("⚠️ [SMART_SWAP] Món [{}] vi phạm dị ứng hoặc ngoài danh mục an toàn. Đã tráo đổi sang món an toàn cùng nhóm [{}] có dinh dưỡng gần nhất: [{}] (Cal: {} kcal/100g)",
                                                foodNameStr, catCode, food.getName(), food.getCaloriesPer100g());
                                    }
                                }

                                if (food != null) {
                                    BigDecimal factor = servingQuantity.divide(new BigDecimal("100"), 4,
                                            RoundingMode.HALF_UP);
                                    BigDecimal calories = food.getCaloriesPer100g().multiply(factor).setScale(1,
                                            RoundingMode.HALF_UP);
                                    BigDecimal protein = food.getProteinPer100g().multiply(factor).setScale(1,
                                            RoundingMode.HALF_UP);
                                    BigDecimal fat = food.getFatPer100g().multiply(factor).setScale(1,
                                            RoundingMode.HALF_UP);
                                    BigDecimal carbs = food.getCarbsPer100g().multiply(factor).setScale(1,
                                            RoundingMode.HALF_UP);
                                    BigDecimal fiber = food.getFiberPer100g().multiply(factor).setScale(1,
                                            RoundingMode.HALF_UP);

                                    items.add(MealItemDTO.builder()
                                            .foodId(food.getId())
                                            .servingQuantity(servingQuantity)
                                            .orderIndex(rawItem.getOrderIndex() != null ? rawItem.getOrderIndex()
                                                    : itemOrder++)
                                            .foodName(food.getName())
                                            .calories(calories)
                                            .protein(protein)
                                            .fat(fat)
                                            .carbs(carbs)
                                            .fiber(fiber)
                                            .servingUnit("g")
                                            .imageUrl(food.getImageUrl())
                                            .isCustom(false)
                                            .isEaten(false)
                                            .build());
                                } else {
                                    log.warn("Suggested food ID [{}] / Name [{}] not found and could not be substituted.",
                                            foodIdStr, foodNameStr);
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

                BigDecimal rawTotalCal = totalCal;
                boolean wasScaled = false;
                BigDecimal scaleFactorUsed = BigDecimal.ONE;

                // Cân chỉnh Calo chuẩn mục tiêu TDEE của User khi sai số MAPE > 5%
                if (targetCalories != null && targetCalories.compareTo(BigDecimal.ZERO) > 0
                        && totalCal.compareTo(BigDecimal.ZERO) > 0) {
                    BigDecimal calDifference = targetCalories.subtract(totalCal).abs();
                    BigDecimal mape = calDifference.divide(targetCalories, 4, RoundingMode.HALF_UP)
                            .multiply(BigDecimal.valueOf(100));

                    // Sử dụng MAPE để xét: nếu MAPE <= 5.0% thì giữ nguyên định lượng tự nhiên của AI
                    boolean isWithinAcceptableRange = mape.compareTo(new BigDecimal("5.0")) <= 0;

                    if (!isWithinAcceptableRange) {
                        BigDecimal scaleFactor = targetCalories.divide(totalCal, 4, RoundingMode.HALF_UP);
                        log.info("Calorie deviation detected (Total: {} kcal, Target: {} kcal, MAPE: {}%). Scaling serving quantities...",
                                totalCal, targetCalories, mape.setScale(2, RoundingMode.HALF_UP));

                        wasScaled = true;
                        scaleFactorUsed = scaleFactor;

                        if (scaleFactor.compareTo(new BigDecimal("0.5")) < 0) {
                            scaleFactor = new BigDecimal("0.5");
                        } else if (scaleFactor.compareTo(new BigDecimal("2.0")) > 0) {
                            scaleFactor = new BigDecimal("2.0");
                        }

                        for (MealSlotDTO slot : mealSlots) {
                            for (MealItemDTO item : slot.getItems()) {
                                if (item.getFoodId() != null && foodMap.containsKey(item.getFoodId())) {
                                    Food food = foodMap.get(item.getFoodId());
                                    BigDecimal scaledQuantity = item.getServingQuantity().multiply(scaleFactor).setScale(1,
                                            RoundingMode.HALF_UP);
                                    BigDecimal minQty = presetMealFallbackBuilder.getMinQuantityForCategory(food);
                                    BigDecimal maxQty = presetMealFallbackBuilder.getMaxQuantityForCategory(food);
                                    if (scaledQuantity.compareTo(minQty) < 0) {
                                        scaledQuantity = minQty;
                                    } else if (scaledQuantity.compareTo(maxQty) > 0) {
                                        scaledQuantity = maxQty;
                                    }

                                    BigDecimal factor = scaledQuantity.divide(new BigDecimal("100"), 4,
                                            RoundingMode.HALF_UP);
                                    item.setServingQuantity(scaledQuantity);
                                    item.setCalories(
                                            food.getCaloriesPer100g().multiply(factor).setScale(1, RoundingMode.HALF_UP));
                                    item.setProtein(
                                            food.getProteinPer100g().multiply(factor).setScale(1, RoundingMode.HALF_UP));
                                    item.setFat(food.getFatPer100g().multiply(factor).setScale(1, RoundingMode.HALF_UP));
                                    item.setCarbs(
                                            food.getCarbsPer100g().multiply(factor).setScale(1, RoundingMode.HALF_UP));
                                    item.setFiber(
                                            food.getFiberPer100g().multiply(factor).setScale(1, RoundingMode.HALF_UP));
                                }
                            }
                        }

                        totalCal = mealSlots.stream()
                                .flatMap(slot -> slot.getItems().stream())
                                .map(item -> item.getCalories() != null ? item.getCalories() : BigDecimal.ZERO)
                                .reduce(BigDecimal.ZERO, BigDecimal::add);
                    } else {
                        log.info("Total calories ({} kcal) is well-aligned with target ({} kcal). Keeping AI suggested natural portions.",
                                totalCal, targetCalories);
                    }
                }

                // Ghi nhận chỉ số đo lường AI Evaluation Log
                int totalItemsCount = mealSlots.stream().mapToInt(slot -> slot.getItems() != null ? slot.getItems().size() : 0).sum();
                if (aiDietEvaluationService != null) {
                    aiDietEvaluationService.recordDietEvaluation(
                            userId,
                            targetCalories,
                            rawTotalCal,
                            totalCal,
                            wasScaled,
                            scaleFactorUsed,
                            totalItemsCount,
                            allergyCount,
                            dietCount,
                            dislikeCount,
                            executionTimeMs,
                            "AI Diet Plan Generation"
                    );
                }

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
            throw new RuntimeException("Lỗi đọc dữ liệu JSON thực đơn từ AI: " + e.getMessage(), e);
        }
    }

    private String cleanMarkdownJson(String rawJson) {
        if (rawJson == null)
            return "[]";
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

    private MealType parseMealTypeSafely(String mealTypeStr) {
        try {
            return MealType.valueOf(mealTypeStr.toUpperCase().trim());
        } catch (Exception e) {
            return MealType.BREAKFAST;
        }
    }

    private Food matchFoodInDatabase(String foodIdStr, String foodNameStr, Map<UUID, Food> foodMap,
            Map<String, Food> nameMap, List<Food> availableFoods) {
        Food food = null;
        if (!foodIdStr.isEmpty()) {
            try {
                UUID foodId = UUID.fromString(foodIdStr);
                food = foodMap.get(foodId);
            } catch (Exception ignored) {
            }
        }
        if (food == null && !foodNameStr.isEmpty()) {
            food = nameMap.get(foodNameStr.toLowerCase().trim());
        }
        if (food == null && !foodNameStr.isEmpty()) {
            String key = foodNameStr.toLowerCase().trim();
            food = availableFoods.stream()
                    .filter(f -> f.getName().toLowerCase().contains(key) || key.contains(f.getName().toLowerCase()))
                    .findFirst()
                    .orElse(null);
        }
        return food;
    }

    private Food findFoodInGlobalList(String foodIdStr, String foodNameStr, List<Food> allFoodsGlobal) {
        if (allFoodsGlobal == null) return null;
        if (!foodIdStr.isEmpty()) {
            try {
                UUID foodId = UUID.fromString(foodIdStr);
                Food f = allFoodsGlobal.stream().filter(item -> item.getId().equals(foodId)).findFirst().orElse(null);
                if (f != null) return f;
            } catch (Exception ignored) {}
        }
        if (!foodNameStr.isEmpty()) {
            String key = foodNameStr.toLowerCase().trim();
            return allFoodsGlobal.stream()
                    .filter(f -> f.getName().toLowerCase().contains(key) || key.contains(f.getName().toLowerCase()))
                    .findFirst()
                    .orElse(null);
        }
        return null;
    }

    // =========================================================================
    // DTOs TẠM HỨNG DỮ LIỆU THÔ TỪ AI (FAIL-SAFE, IGNORE UNKNOWN PROPERTIES)
    // =========================================================================

    @Data
    @NoArgsConstructor
    @AllArgsConstructor
    @JsonIgnoreProperties(ignoreUnknown = true)
    public static class RawDailyEating {
        private String date;
        private String note = "";
        private Boolean isAiGenerated = true;
        private List<RawMealSlot> mealSlots = new ArrayList<>();
    }

    @Data
    @NoArgsConstructor
    @AllArgsConstructor
    @JsonIgnoreProperties(ignoreUnknown = true)
    public static class RawMealSlot {
        private String mealType = "BREAKFAST";
        private String customName = "";
        private Integer orderIndex = 0;
        private List<RawMealItem> items = new ArrayList<>();
    }

    @Data
    @NoArgsConstructor
    @AllArgsConstructor
    @JsonIgnoreProperties(ignoreUnknown = true)
    public static class RawMealItem {
        private String foodId = "";
        private String foodName = "";
        private BigDecimal servingQuantity = new BigDecimal("100.0");
        private Integer orderIndex = 0;
    }
}
