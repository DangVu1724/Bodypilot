package com.bodypilot.backend.service.impl.diet;

import java.math.BigDecimal;
import java.time.LocalDate;
import java.util.List;
import java.util.UUID;

import org.springframework.stereotype.Component;

import com.bodypilot.backend.model.dto.nutrition.FoodCandidate;
import com.bodypilot.backend.model.entity.nutrition.Food;
import com.bodypilot.backend.model.entity.user.UserAllergy;
import com.bodypilot.backend.model.entity.user.UserDietPreference;
import com.bodypilot.backend.model.entity.user.UserFoodPreference;
import com.bodypilot.backend.model.entity.user.UserGoal;
import com.bodypilot.backend.model.entity.user.UserMetricHistory;
import com.bodypilot.backend.model.entity.user.UserProfile;

import lombok.RequiredArgsConstructor;
import lombok.extern.slf4j.Slf4j;

/**
 * Clean Facade for AI Diet Suggestion operations.
 * Delegates responsibilities to:
 * - {@link DietFoodFilterService}: Food filtering, candidate selection & RAM caching.
 * - {@link DietPromptBuilder}: Construction of AI prompts & text translations.
 * - {@link DietJsonPostProcessor}: Fail-safe AI diet JSON parsing & food linking.
 * - {@link PresetMealFallbackBuilder}: Medical-grade preset fallback meal plan generation.
 */
@Component
@RequiredArgsConstructor
@Slf4j
public class DietSuggestionHelper {

    private final DietFoodFilterService foodFilterService;
    private final DietPromptBuilder promptBuilder;
    private final DietJsonPostProcessor jsonPostProcessor;
    private final PresetMealFallbackBuilder presetFallbackBuilder;

    public List<FoodCandidate> getBalancedFoodCandidates(UUID userId, String goalType) {
        return foodFilterService.getBalancedFoodCandidates(userId, goalType);
    }

    public List<Food> getFilteredFoods(List<UserAllergy> allergies, List<UserDietPreference> diets,
            List<UserFoodPreference> dislikes) {
        return foodFilterService.getFilteredFoods(allergies, diets, dislikes);
    }

    public List<Food> selectBalancedFoods(List<Food> foods, int limit, String goalType,
            List<UserDietPreference> diets) {
        return foodFilterService.selectBalancedFoods(foods, limit, goalType, diets);
    }

    public List<Food> getAllFoodsCached() {
        return foodFilterService.getAllFoodsCached();
    }

    public String buildPrompt(UserProfile profile, UserGoal goal, UserMetricHistory metric,
            List<UserAllergy> allergies, List<UserDietPreference> diets,
            List<UserFoodPreference> dislikes, List<FoodCandidate> candidates, LocalDate startDate, Integer days) {
        return promptBuilder.buildPrompt(profile, goal, metric, allergies, diets, dislikes, candidates, startDate, days);
    }

    public String buildPrompt(UserProfile profile, UserGoal goal, UserMetricHistory metric,
            List<UserAllergy> allergies, List<UserDietPreference> diets,
            List<UserFoodPreference> dislikes, List<FoodCandidate> candidates, LocalDate startDate, Integer days,
            String userFeedback) {
        return promptBuilder.buildPrompt(profile, goal, metric, allergies, diets, dislikes, candidates, startDate, days, userFeedback);
    }

    public String generatePresetFallbackMealPlan(UUID userId, LocalDate startDate, Integer days, String goalType,
            BigDecimal targetCalories, String noteMessage) {
        return presetFallbackBuilder.generatePresetFallbackMealPlan(userId, startDate, days, goalType, targetCalories, noteMessage);
    }

    public String processAndLinkFoods(String rawJson, BigDecimal targetCalories) {
        return jsonPostProcessor.processAndLinkFoods(rawJson, targetCalories);
    }

    public String getFallbackJson(LocalDate startDate, String message, Integer days) {
        return presetFallbackBuilder.getFallbackJson(startDate, message, days);
    }

    public BigDecimal getMinQuantityForCategory(Food food) {
        return presetFallbackBuilder.getMinQuantityForCategory(food);
    }

    public BigDecimal getMaxQuantityForCategory(Food food) {
        return presetFallbackBuilder.getMaxQuantityForCategory(food);
    }
}
