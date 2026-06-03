package com.bodypilot.backend.service;

import com.bodypilot.backend.model.dto.nutrition.DailyEatingDTO;
import com.bodypilot.backend.model.dto.nutrition.MealItemDTO;
import com.bodypilot.backend.model.enums.MealType;
import com.bodypilot.backend.model.entity.user.User;

import java.time.LocalDate;
import java.util.List;
import java.util.UUID;

public interface NutritionDiaryService {
    DailyEatingDTO getDailyEating(User user, LocalDate date);
    List<DailyEatingDTO> getDailyEatingRange(User user, LocalDate startDate, LocalDate endDate);
    
    DailyEatingDTO addFoodToDiary(User user, LocalDate date, MealType mealType, MealItemDTO itemDTO);
    void removeFoodFromDiary(UUID mealItemId);
    void updateFoodInDiary(UUID mealItemId, MealItemDTO itemDTO);
    
    // New methods for reordering and clearing
    void reorderMealItems(UUID mealSlotId, List<UUID> itemIds);
    void clearMeal(User user, LocalDate date, MealType mealType);
    void clearDay(User user, LocalDate date);
    void updateDailyNote(User user, LocalDate date, String note);
    void addMultipleDailyEatings(User user, List<DailyEatingDTO> dailyEatingDTOs);
    DailyEatingDTO updateMealItemStatus(UUID mealItemId, Boolean isEaten);
    DailyEatingDTO updateMealSlotStatus(UUID mealSlotId, Boolean isEaten);
}
