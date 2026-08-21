package com.bodypilot.backend.service.impl.diet;

import java.math.BigDecimal;
import java.util.ArrayList;
import java.util.HashMap;
import java.util.HashSet;
import java.util.List;
import java.util.Map;
import java.util.Random;
import java.util.Set;
import java.util.UUID;
import java.util.stream.Collectors;

import org.springframework.cache.annotation.Cacheable;
import org.springframework.stereotype.Component;

import com.bodypilot.backend.model.dto.nutrition.FoodCandidate;
import com.bodypilot.backend.model.entity.nutrition.Food;
import com.bodypilot.backend.model.entity.user.UserAllergy;
import com.bodypilot.backend.model.entity.user.UserDietPreference;
import com.bodypilot.backend.model.entity.user.UserFoodPreference;
import com.bodypilot.backend.repository.AllergyMasterRepository;
import com.bodypilot.backend.repository.FoodRepository;
import com.bodypilot.backend.repository.UserAllergyRepository;
import com.bodypilot.backend.repository.UserDietPreferenceRepository;
import com.bodypilot.backend.repository.UserFoodPreferenceRepository;

import lombok.RequiredArgsConstructor;
import lombok.extern.slf4j.Slf4j;

/**
 * Service dedicated to filtering foods based on allergies, diets, dislikes,
 * candidate selection with macro-weighted scoring, and RAM caching.
 */
@Component
@RequiredArgsConstructor
@Slf4j
public class DietFoodFilterService {

    private final FoodRepository foodRepository;
    private final UserAllergyRepository allergyRepository;
    private final UserDietPreferenceRepository dietPreferenceRepository;
    private final UserFoodPreferenceRepository foodPreferenceRepository;
    private final AllergyMasterRepository allergyMasterRepository;

    private static final UUID MANDATORY_RICE_ID = UUID.fromString("4bc7d59e-5acc-568e-941f-b5b4bfa09b5c");

    @Cacheable("allFoods")
    public List<Food> getAllFoodsCached() {
        return foodRepository.findAllWithRelations();
    }

    public List<FoodCandidate> getBalancedFoodCandidates(UUID userId, String goalType) {
        List<UserAllergy> allergies = (userId != null) ? allergyRepository.findAllByUserIdAndIsActiveTrue(userId)
                : new ArrayList<>();
        List<UserDietPreference> diets = (userId != null)
                ? dietPreferenceRepository.findAllByUserIdAndIsActiveTrue(userId)
                : new ArrayList<>();
        List<UserFoodPreference> dislikes = (userId != null)
                ? foodPreferenceRepository.findAllByUserIdAndIsActiveTrue(userId)
                : new ArrayList<>();

        List<Food> filteredFoods = getFilteredFoods(allergies, diets, dislikes);
        List<Food> limitedFoods = selectBalancedFoods(filteredFoods, 150, goalType, diets);

        return limitedFoods.stream()
                .map(f -> new FoodCandidate(
                        f.getId(),
                        f.getName(),
                        f.getCategory() != null ? f.getCategory().getName() : "Không xác định",
                        f.getCaloriesPer100g(),
                        f.getProteinPer100g(),
                        f.getFatPer100g(),
                        f.getCarbsPer100g()))
                .collect(Collectors.toList());
    }

    public List<Food> getFilteredFoods(List<UserAllergy> allergies, List<UserDietPreference> diets,
            List<UserFoodPreference> dislikes) {
        List<Food> foods = getAllFoodsCached();
        log.info("🔍 [FOOD_FILTER] Total foods in DB: {}. Applying filters (allergies={}, diets={}, dislikes={})...",
                foods.size(),
                allergies != null ? allergies.size() : 0,
                diets != null ? diets.size() : 0,
                dislikes != null ? dislikes.size() : 0);

        return foods.stream()
                .filter(f -> (f.getId() != null && f.getId().equals(MANDATORY_RICE_ID)) || (
                        (allergies == null || allergies.stream().noneMatch(allergy -> isAllergicFood(f, allergy)))
                        && (diets == null || diets.stream().allMatch(diet -> isDietCompliant(f, diet)))
                        && (dislikes == null || dislikes.stream().noneMatch(dislike -> isDislikedFood(f, dislike)))
                ))
                .collect(Collectors.toList());
    }

    public boolean isAllergicFood(Food f, UserAllergy allergy) {
        if (f == null || allergy == null)
            return false;

        if (allergy.getNote() != null && !allergy.getNote().trim().isEmpty()) {
            String noteLower = allergy.getNote().toLowerCase();
            String[] keywords = noteLower.split("[,;\\n]+");
            String fName = f.getName() != null ? f.getName().toLowerCase() : "";
            String fDesc = f.getDescription() != null ? f.getDescription().toLowerCase() : "";

            for (String kw : keywords) {
                String trimmed = kw.trim();
                if (!trimmed.isEmpty() && (fName.contains(trimmed) || fDesc.contains(trimmed))) {
                    return true;
                }
            }
            return false;
        }

        if (allergy.getAllergyMaster() != null) {
            String masterName = allergy.getAllergyMaster().getName();
            if (masterName != null && !masterName.isEmpty()) {
                String allergyName = masterName.toLowerCase();
                String fName = f.getName() != null ? f.getName().toLowerCase() : "";
                String fDesc = f.getDescription() != null ? f.getDescription().toLowerCase() : "";
                return fName.contains(allergyName) || fDesc.contains(allergyName);
            }
        }

        return false;
    }

    public boolean isDietCompliant(Food f, UserDietPreference diet) {
        if (f == null || diet == null || diet.getDietTag() == null)
            return true;
        String dietName = diet.getDietTag().getName();
        if (dietName == null)
            return true;

        String categoryCode = (f.getCategory() != null && f.getCategory().getCode() != null)
                ? f.getCategory().getCode().toUpperCase()
                : "";

        return switch (dietName.toUpperCase()) {
            case "VEGETARIAN", "VEGAN" -> !categoryCode.equals("MEAT") && !categoryCode.equals("SEAFOOD");
            case "KETO" -> categoryCode.equals("MEAT") || categoryCode.equals("SEAFOOD")
                    || categoryCode.equals("VEG") || categoryCode.equals("FAT");
            case "LOW_CARB" -> !categoryCode.equals("GRAIN") && !categoryCode.equals("NOODLE_SOUP");
            default -> true;
        };
    }

    public boolean isDislikedFood(Food f, UserFoodPreference preference) {
        if (f == null || preference == null)
            return false;

        if (preference.getNote() != null && !preference.getNote().trim().isEmpty()) {
            String noteLower = preference.getNote().toLowerCase();
            String[] keywords = noteLower.split("[,;\\n]+");
            String fName = f.getName() != null ? f.getName().toLowerCase() : "";

            for (String kw : keywords) {
                String trimmed = kw.trim();
                if (!trimmed.isEmpty() && fName.contains(trimmed)) {
                    return true;
                }
            }
            return false;
        }

        if (preference.getDislikedFoodGroup() != null) {
            return isDislikedFoodGroup(f, preference.getDislikedFoodGroup());
        }

        return false;
    }

    private boolean isDislikedFoodGroup(Food f,
            com.bodypilot.backend.model.enums.DislikedFoodGroup group) {
        if (f == null || group == null || f.getCategory() == null)
            return false;
        String catCode = f.getCategory().getCode() != null ? f.getCategory().getCode().toUpperCase() : "";
        String catName = f.getCategory().getName() != null ? f.getCategory().getName().toUpperCase() : "";
        String groupName = group.name().toUpperCase();
        return catCode.contains(groupName) || catName.contains(groupName);
    }

    public List<Food> selectBalancedFoods(List<Food> foods, int limit, String goalType,
            List<UserDietPreference> diets) {
        if (foods.size() <= limit) {
            return foods;
        }

        Random random = new Random();
        Map<Food, Double> foodScores = new HashMap<>();
        for (Food f : foods) {
            double score = calculateFoodScore(f, goalType, diets) + (random.nextDouble() * 15.0);
            foodScores.put(f, score);
        }

        List<Food> sortedFoods = new ArrayList<>(foods);
        sortedFoods.sort((f1, f2) -> Double.compare(foodScores.get(f2), foodScores.get(f1)));

        List<Food> selected = new ArrayList<>();
        Set<UUID> selectedIds = new HashSet<>();

        // Bắt buộc ưu tiên đưa món Cơm đã nấu (MANDATORY_RICE_ID) vào danh sách ứng viên gửi cho AI
        foods.stream()
                .filter(f -> f.getId() != null && f.getId().equals(MANDATORY_RICE_ID))
                .findFirst()
                .ifPresent(rice -> {
                    if (selectedIds.add(rice.getId())) {
                        selected.add(rice);
                    }
                });

        Map<String, List<Food>> categoryMap = new HashMap<>();
        for (Food f : sortedFoods) {
            String catName = f.getCategory() != null && f.getCategory().getName() != null
                    ? f.getCategory().getName()
                    : "Khác";
            categoryMap.computeIfAbsent(catName, k -> new ArrayList<>()).add(f);
        }

        Map<String, Integer> categoryQuotas = getGoalCategoryQuotas(goalType, limit);

        for (Map.Entry<String, List<Food>> entry : categoryMap.entrySet()) {
            String catName = entry.getKey();
            List<Food> catFoods = entry.getValue();
            int quota = getCategoryQuotaForName(catName, categoryQuotas);
            int count = 0;
            for (Food f : catFoods) {
                if (count >= quota || selected.size() >= limit)
                    break;
                if (selectedIds.add(f.getId())) {
                    selected.add(f);
                    count++;
                }
            }
        }

        for (Food f : sortedFoods) {
            if (selected.size() >= limit)
                break;
            if (selectedIds.add(f.getId())) {
                selected.add(f);
            }
        }

        return selected;
    }

    private double calculateFoodScore(Food f, String goalType, List<UserDietPreference> diets) {
        double score = 50.0;
        if (f == null)
            return score;

        if (f.getId() != null && f.getId().equals(MANDATORY_RICE_ID)) {
            score += 2000.0;
        }

        BigDecimal protein = f.getProteinPer100g() != null ? f.getProteinPer100g() : BigDecimal.ZERO;
        BigDecimal fat = f.getFatPer100g() != null ? f.getFatPer100g() : BigDecimal.ZERO;
        BigDecimal carbs = f.getCarbsPer100g() != null ? f.getCarbsPer100g() : BigDecimal.ZERO;
        BigDecimal fiber = f.getFiberPer100g() != null ? f.getFiberPer100g() : BigDecimal.ZERO;

        if (goalType != null) {
            switch (goalType.toUpperCase()) {
                case "GAIN_MUSCLE", "GAIN_0_5KG", "GAIN_1KG" -> {
                    score += protein.doubleValue() * 2.5;
                    score += carbs.doubleValue() * 0.5;
                }
                case "LOSE_WEIGHT", "LOSE_0_5KG", "LOSE_1KG" -> {
                    score += protein.doubleValue() * 2.0;
                    score += fiber.doubleValue() * 3.0;
                    score -= carbs.doubleValue() * 0.5;
                    score -= fat.doubleValue() * 0.5;
                }
                case "MAINTAIN" -> {
                    score += protein.doubleValue() * 1.5;
                    score += fiber.doubleValue() * 1.5;
                }
            }
        }

        return score;
    }

    private Map<String, Integer> getGoalCategoryQuotas(String goalType, int totalLimit) {
        Map<String, Integer> quotas = new HashMap<>();
        if (goalType == null)
            goalType = "MAINTAIN";

        switch (goalType.toUpperCase()) {
            case "GAIN_MUSCLE", "GAIN_0_5KG", "GAIN_1KG" -> {
                quotas.put("Thịt", (int) (totalLimit * 0.25));
                quotas.put("Hải sản", (int) (totalLimit * 0.15));
                quotas.put("Ngũ cốc", (int) (totalLimit * 0.20));
                quotas.put("Món nước", (int) (totalLimit * 0.15));
                quotas.put("Rau", (int) (totalLimit * 0.15));
                quotas.put("Trái cây", (int) (totalLimit * 0.10));
            }
            case "LOSE_WEIGHT", "LOSE_0_5KG", "LOSE_1KG" -> {
                quotas.put("Rau", (int) (totalLimit * 0.30));
                quotas.put("Thịt", (int) (totalLimit * 0.20));
                quotas.put("Hải sản", (int) (totalLimit * 0.20));
                quotas.put("Trái cây", (int) (totalLimit * 0.15));
                quotas.put("Ngũ cốc", (int) (totalLimit * 0.10));
                quotas.put("Món nước", (int) (totalLimit * 0.05));
            }
            default -> {
                quotas.put("Thịt", (int) (totalLimit * 0.20));
                quotas.put("Rau", (int) (totalLimit * 0.20));
                quotas.put("Hải sản", (int) (totalLimit * 0.15));
                quotas.put("Ngũ cốc", (int) (totalLimit * 0.15));
                quotas.put("Trái cây", (int) (totalLimit * 0.15));
                quotas.put("Món nước", (int) (totalLimit * 0.15));
            }
        }
        return quotas;
    }

    private int getCategoryQuotaForName(String catName, Map<String, Integer> quotas) {
        if (catName == null)
            return 15;
        for (Map.Entry<String, Integer> entry : quotas.entrySet()) {
            if (catName.toLowerCase().contains(entry.getKey().toLowerCase())) {
                return entry.getValue();
            }
        }
        return 15;
    }
}
