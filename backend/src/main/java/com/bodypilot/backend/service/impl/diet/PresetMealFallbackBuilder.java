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
import com.bodypilot.backend.model.entity.user.UserAllergy;
import com.bodypilot.backend.model.entity.user.UserDietPreference;
import com.bodypilot.backend.model.entity.user.UserFoodPreference;
import com.bodypilot.backend.repository.UserAllergyRepository;
import com.bodypilot.backend.repository.UserDietPreferenceRepository;
import com.bodypilot.backend.repository.UserFoodPreferenceRepository;
import com.bodypilot.backend.service.impl.PresetMealPlanData;

import com.fasterxml.jackson.databind.ObjectMapper;
import com.fasterxml.jackson.databind.SerializationFeature;
import com.fasterxml.jackson.datatype.jsr310.JavaTimeModule;

import lombok.RequiredArgsConstructor;
import lombok.extern.slf4j.Slf4j;

@Component
@RequiredArgsConstructor
@Slf4j
public class PresetMealFallbackBuilder {

    private final UserAllergyRepository allergyRepository;
    private final UserDietPreferenceRepository dietPreferenceRepository;
    private final UserFoodPreferenceRepository foodPreferenceRepository;
    private final DietFoodFilterService foodFilterService;

    private final ObjectMapper objectMapper = new ObjectMapper()
            .registerModule(new JavaTimeModule())
            .disable(SerializationFeature.WRITE_DATES_AS_TIMESTAMPS);

    /**
     * Sinh thực đơn 7 ngày dự phòng Y khoa chuẩn hóa theo TDEE của người dùng.
     * Tự động lọc dị ứng, kiêng cữ và tráo đổi món ăn thế thân đạt điểm số cao nhất cùng Category.
     */
    public String generatePresetFallbackMealPlan(UUID userId, LocalDate startDate, Integer days, String goalType,
            BigDecimal targetCalories, String noteMessage) {
        log.info("[PRESET_FALLBACK] Generating preset fallback meal plan for userId={}, startDate={}, days={}, goalType={}, targetCalories={}",
                userId, startDate, days, goalType, targetCalories);
        try {
            // Bước 1: Lấy danh sách dị ứng, chế độ ăn, kiêng cữ từ Database
            List<UserAllergy> allergies = (userId != null) ? allergyRepository.findAllByUserIdAndIsActiveTrue(userId)
                    : new ArrayList<>();
            List<UserDietPreference> diets = (userId != null)
                    ? dietPreferenceRepository.findAllByUserIdAndIsActiveTrue(userId)
                    : new ArrayList<>();
            List<UserFoodPreference> dislikes = (userId != null)
                    ? foodPreferenceRepository.findAllByUserIdAndIsActiveTrue(userId)
                    : new ArrayList<>();

            // Bước 2: Lọc các món an toàn và sắp xếp theo điểm số phù hợp giảm dần
            List<Food> safeFoods = foodFilterService.getFilteredFoods(allergies, diets, dislikes);
            List<Food> availableFoods = foodFilterService.selectBalancedFoods(safeFoods, 150, goalType, diets);
            Map<UUID, Food> foodMap = availableFoods.stream()
                    .collect(Collectors.toMap(Food::getId, f -> f, (f1, f2) -> f1));
            Map<String, Food> nameMap = availableFoods.stream()
                    .collect(Collectors.toMap(f -> f.getName().toLowerCase().trim(), f -> f, (f1, f2) -> f1));

            // Bước 3: Phân loại danh sách món ăn an toàn theo nhóm Category (MEAT, SEAFOOD, VEG...)
            Map<String, List<Food>> catMap = new HashMap<>();
            for (Food f : availableFoods) {
                if (f.getCategory() != null && f.getCategory().getCode() != null) {
                    catMap.computeIfAbsent(f.getCategory().getCode().toUpperCase().trim(), k -> new ArrayList<>())
                            .add(f);
                }
            }

            // Bước 4: Lấy bộ khung thực đơn y khoa mẫu theo mục tiêu thể hình
            List<PresetMealPlanData.PresetDay> presetDays = PresetMealPlanData.getPresetForGoal(goalType);
            List<DailyEatingDTO> dailyEatingList = new ArrayList<>();

            for (int dayIdx = 0; dayIdx < days; dayIdx++) {
                LocalDate date = startDate.plusDays(dayIdx);
                PresetMealPlanData.PresetDay presetDay = presetDays.get(dayIdx % presetDays.size());
                List<MealSlotDTO> mealSlots = new ArrayList<>();
                int slotIndex = 0;

                for (PresetMealPlanData.PresetSlot slot : presetDay.getSlots()) {
                    List<MealItemDTO> items = new ArrayList<>();
                    int itemIndex = 0;

                    for (PresetMealPlanData.PresetItem presetItem : slot.getItems()) {
                        // Bước 4.1: Tra cứu món mẫu ban đầu theo tên
                        Food matchedFood = nameMap.get(presetItem.getFoodName().toLowerCase().trim());
                        if (matchedFood == null) {
                            String pName = presetItem.getFoodName().toLowerCase();
                            matchedFood = availableFoods.stream()
                                    .filter(f -> f.getName().toLowerCase().contains(pName)
                                            || pName.contains(f.getName().toLowerCase()))
                                    .findFirst().orElse(null);
                        }

                        // Bước 4.2: Nếu món mẫu bị dính dị ứng/kiêng cữ -> Hủy món này
                        if (matchedFood != null && isViolatingAllergiesOrDislikes(matchedFood, allergies, dislikes)) {
                            matchedFood = null;
                        }

                        // Bước 4.3: Cơ chế tráo đổi thế thân: Chọn món cùng Category có ĐIỂM SỐ CAO NHẤT trong DB
                        if (matchedFood == null) {
                            String catCode = presetItem.getCategoryCode();
                            List<Food> candidates = catMap
                                    .getOrDefault(catCode != null ? catCode.toUpperCase() : "OTHERS", availableFoods);
                            matchedFood = candidates.stream()
                                    .filter(f -> !isViolatingAllergiesOrDislikes(f, allergies, dislikes))
                                    .findFirst().orElse(!availableFoods.isEmpty() ? availableFoods.get(0) : null);
                        }

                        // Bước 4.4: Tạo món ăn và quy đổi dinh dưỡng
                        if (matchedFood != null) {
                            BigDecimal qty = BigDecimal.valueOf(presetItem.getDefaultServingGrams());
                            items.add(buildMealItem(matchedFood, qty, itemIndex++));
                        }
                    }

                    mealSlots.add(MealSlotDTO.builder()
                            .mealType(slot.getMealType())
                            .customName(slot.getCustomName())
                            .orderIndex(slotIndex++)
                            .isEaten(false)
                            .items(items)
                            .build());
                }

                // Bước 5: Co/dãn định lượng khẩu phần ăn theo Target Calories của người dùng
                scaleMealSlotsToTargetCalories(mealSlots, targetCalories, foodMap);

                BigDecimal totalCal = mealSlots.stream()
                        .flatMap(s -> s.getItems().stream())
                        .map(i -> i.getCalories() != null ? i.getCalories() : BigDecimal.ZERO)
                        .reduce(BigDecimal.ZERO, BigDecimal::add);

                dailyEatingList.add(DailyEatingDTO.builder()
                        .date(date)
                        .note(noteMessage != null ? noteMessage
                                : "Thực đơn chuẩn cân bằng dinh dưỡng theo mục tiêu (Do hệ thống tự động thiết lập)")
                        .isAiGenerated(false)
                        .totalCaloriesPlanned(totalCal)
                        .totalCaloriesEaten(BigDecimal.ZERO)
                        .mealSlots(mealSlots)
                        .build());
            }

            return objectMapper.writeValueAsString(dailyEatingList);
        } catch (Exception e) {
            log.error("❌ [PRESET_FALLBACK_ERROR] Error generating preset fallback meal plan: ", e);
            return getFallbackJson(startDate, noteMessage, days);
        }
    }

    /**
     * Kiểm tra món ăn có vi phạm dị ứng hoặc thực phẩm kiêng cữ trong note của người dùng không.
     */
    public boolean isViolatingAllergiesOrDislikes(Food f, List<UserAllergy> allergies,
            List<UserFoodPreference> dislikes) {
        if (f == null)
            return true;
        boolean allergyMatch = allergies != null
                && allergies.stream().anyMatch(a -> foodFilterService.isAllergicFood(f, a));
        boolean dislikeMatch = dislikes != null
                && dislikes.stream().anyMatch(p -> foodFilterService.isDislikedFood(f, p));
        return allergyMatch || dislikeMatch;
    }

    public void scaleMealSlotsToTargetCalories(List<MealSlotDTO> mealSlots, BigDecimal targetCalories,
            Map<UUID, Food> foodMap) {
        if (targetCalories == null || targetCalories.compareTo(BigDecimal.ZERO) <= 0)
            return;
        BigDecimal currentTotal = mealSlots.stream()
                .flatMap(s -> s.getItems().stream())
                .map(i -> i.getCalories() != null ? i.getCalories() : BigDecimal.ZERO)
                .reduce(BigDecimal.ZERO, BigDecimal::add);

        if (currentTotal.compareTo(BigDecimal.ZERO) <= 0)
            return;

        BigDecimal ratio = targetCalories.divide(currentTotal, 4, RoundingMode.HALF_UP);
        if (ratio.compareTo(new BigDecimal("0.5")) < 0)
            ratio = new BigDecimal("0.5");
        if (ratio.compareTo(new BigDecimal("2.0")) > 0)
            ratio = new BigDecimal("2.0");

        for (MealSlotDTO slot : mealSlots) {
            for (MealItemDTO item : slot.getItems()) {
                if (item.getFoodId() != null && foodMap.containsKey(item.getFoodId())) {
                    Food food = foodMap.get(item.getFoodId());
                    BigDecimal scaledQty = item.getServingQuantity().multiply(ratio).setScale(1, RoundingMode.HALF_UP);
                    BigDecimal minQty = getMinQuantityForCategory(food);
                    BigDecimal maxQty = getMaxQuantityForCategory(food);

                    if (scaledQty.compareTo(minQty) < 0)
                        scaledQty = minQty;
                    if (scaledQty.compareTo(maxQty) > 0)
                        scaledQty = maxQty;

                    MealItemDTO updated = buildMealItem(food, scaledQty, item.getOrderIndex());
                    item.setServingQuantity(updated.getServingQuantity());
                    item.setCalories(updated.getCalories());
                    item.setProtein(updated.getProtein());
                    item.setFat(updated.getFat());
                    item.setCarbs(updated.getCarbs());
                    item.setFiber(updated.getFiber());
                }
            }
        }
    }

    private MealItemDTO buildMealItem(Food food, BigDecimal quantity, int orderIndex) {
        BigDecimal factor = quantity.divide(new BigDecimal("100"), 4, RoundingMode.HALF_UP);
        return MealItemDTO.builder()
                .foodId(food.getId())
                .foodName(food.getName())
                .servingQuantity(quantity)
                .servingUnit("g")
                .orderIndex(orderIndex)
                .calories(food.getCaloriesPer100g().multiply(factor).setScale(1, RoundingMode.HALF_UP))
                .protein(food.getProteinPer100g().multiply(factor).setScale(1, RoundingMode.HALF_UP))
                .fat(food.getFatPer100g().multiply(factor).setScale(1, RoundingMode.HALF_UP))
                .carbs(food.getCarbsPer100g().multiply(factor).setScale(1, RoundingMode.HALF_UP))
                .fiber(food.getFiberPer100g().multiply(factor).setScale(1, RoundingMode.HALF_UP))
                .imageUrl(food.getImageUrl())
                .isCustom(false)
                .isEaten(false)
                .build();
    }

    public BigDecimal getMinQuantityForCategory(Food food) {
        if (food == null || food.getCategory() == null || food.getCategory().getCode() == null)
            return new BigDecimal("50.0");
        return switch (food.getCategory().getCode().toUpperCase()) {
            case "FAT", "OIL", "CONDIMENT" -> new BigDecimal("5.0");
            case "NUTS", "SEED" -> new BigDecimal("10.0");
            case "VEG", "GRAIN", "RICE", "NOODLE", "FRUIT" -> new BigDecimal("50.0");
            case "MEAT", "SEAFOOD" -> new BigDecimal("60.0");
            case "DAIRY", "MILK" -> new BigDecimal("100.0");
            default -> new BigDecimal("30.0");
        };
    }

    public BigDecimal getMaxQuantityForCategory(Food food) {
        if (food == null || food.getCategory() == null || food.getCategory().getCode() == null)
            return new BigDecimal("350.0");
        return switch (food.getCategory().getCode().toUpperCase()) {
            case "FAT", "OIL", "CONDIMENT" -> new BigDecimal("30.0");
            case "NUTS", "SEED" -> new BigDecimal("60.0");
            case "MEAT", "SEAFOOD", "FRUIT" -> new BigDecimal("250.0");
            case "GRAIN", "RICE", "NOODLE" -> new BigDecimal("300.0");
            case "VEG" -> new BigDecimal("350.0");
            case "DAIRY", "MILK" -> new BigDecimal("400.0");
            default -> new BigDecimal("300.0");
        };
    }

    public String getFallbackJson(LocalDate startDate, String message, Integer days) {
        int actualDays = (days != null && days > 0) ? days : 7;
        List<DailyEatingDTO> list = new ArrayList<>();
        for (int i = 0; i < actualDays; i++) {
            list.add(DailyEatingDTO.builder()
                    .date(startDate.plusDays(i))
                    .note(message != null ? message : "Thực đơn chuẩn cân bằng dinh dưỡng (Dự phòng hệ thống)")
                    .isAiGenerated(false)
                    .totalCaloriesPlanned(BigDecimal.ZERO)
                    .totalCaloriesEaten(BigDecimal.ZERO)
                    .mealSlots(new ArrayList<>())
                    .build());
        }
        try {
            return objectMapper.writeValueAsString(list);
        } catch (Exception e) {
            return "[]";
        }
    }
}
