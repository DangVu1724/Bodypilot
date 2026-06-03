package com.bodypilot.backend.controller;

import com.bodypilot.backend.model.dto.common.ApiResponse;
import com.bodypilot.backend.model.dto.nutrition.DailyEatingDTO;
import com.bodypilot.backend.model.dto.nutrition.MealItemDTO;
import com.bodypilot.backend.model.entity.user.User;
import com.bodypilot.backend.model.enums.MealType;
import com.bodypilot.backend.service.NutritionDiaryService;
import com.bodypilot.backend.service.UserService;
import lombok.RequiredArgsConstructor;
import org.springframework.format.annotation.DateTimeFormat;
import org.springframework.http.ResponseEntity;
import org.springframework.security.core.annotation.AuthenticationPrincipal;
import org.springframework.security.core.userdetails.UserDetails;
import org.springframework.web.bind.annotation.*;

import java.time.LocalDate;
import java.util.List;
import java.util.UUID;

@RestController
@RequestMapping("/api/v1/nutrition-diary")
@RequiredArgsConstructor
public class NutritionDiaryController {

    private final NutritionDiaryService nutritionDiaryService;
    private final UserService userService;

    @GetMapping("/day")
    public ResponseEntity<ApiResponse<DailyEatingDTO>> getDailyEating(
            @AuthenticationPrincipal UserDetails userDetails,
            @RequestParam @DateTimeFormat(iso = DateTimeFormat.ISO.DATE) LocalDate date) {
        User user = userService.getUserByEmail(userDetails.getUsername());
        DailyEatingDTO response = nutritionDiaryService.getDailyEating(user, date);
        return ResponseEntity.ok(ApiResponse.ok(response));
    }

    @GetMapping("/range")
    public ResponseEntity<ApiResponse<List<DailyEatingDTO>>> getDailyEatingRange(
            @AuthenticationPrincipal UserDetails userDetails,
            @RequestParam @DateTimeFormat(iso = DateTimeFormat.ISO.DATE) LocalDate startDate,
            @RequestParam @DateTimeFormat(iso = DateTimeFormat.ISO.DATE) LocalDate endDate) {
        User user = userService.getUserByEmail(userDetails.getUsername());
        List<DailyEatingDTO> response = nutritionDiaryService.getDailyEatingRange(user, startDate, endDate);
        return ResponseEntity.ok(ApiResponse.ok(response));
    }

    @PostMapping("/add")
    public ResponseEntity<ApiResponse<DailyEatingDTO>> addFood(
            @AuthenticationPrincipal UserDetails userDetails,
            @RequestParam @DateTimeFormat(iso = DateTimeFormat.ISO.DATE) LocalDate date,
            @RequestParam MealType mealType,
            @RequestBody MealItemDTO itemDTO) {
        User user = userService.getUserByEmail(userDetails.getUsername());
        DailyEatingDTO response = nutritionDiaryService.addFoodToDiary(user, date, mealType, itemDTO);
        return ResponseEntity.ok(ApiResponse.ok(response));
    }

    @PutMapping("/item/{id}")
    public ResponseEntity<ApiResponse<Void>> updateFood(
            @PathVariable UUID id,
            @RequestBody MealItemDTO itemDTO) {
        nutritionDiaryService.updateFoodInDiary(id, itemDTO);
        return ResponseEntity.ok(ApiResponse.ok("Food updated successfully", null));
    }

    @DeleteMapping("/item/{id}")
    public ResponseEntity<ApiResponse<Void>> deleteFood(@PathVariable UUID id) {
        nutritionDiaryService.removeFoodFromDiary(id);
        return ResponseEntity.ok(ApiResponse.ok("Food removed successfully", null));
    }

    @PostMapping("/reorder/{mealSlotId}")
    public ResponseEntity<ApiResponse<Void>> reorderItems(
            @PathVariable UUID mealSlotId,
            @RequestBody List<UUID> itemIds) {
        nutritionDiaryService.reorderMealItems(mealSlotId, itemIds);
        return ResponseEntity.ok(ApiResponse.ok("Items reordered successfully", null));
    }

    @DeleteMapping("/meal")
    public ResponseEntity<ApiResponse<Void>> clearMeal(
            @AuthenticationPrincipal UserDetails userDetails,
            @RequestParam @DateTimeFormat(iso = DateTimeFormat.ISO.DATE) LocalDate date,
            @RequestParam MealType mealType) {
        User user = userService.getUserByEmail(userDetails.getUsername());
        nutritionDiaryService.clearMeal(user, date, mealType);
        return ResponseEntity.ok(ApiResponse.ok("Meal cleared successfully", null));
    }

    @DeleteMapping("/day")
    public ResponseEntity<ApiResponse<Void>> clearDay(
            @AuthenticationPrincipal UserDetails userDetails,
            @RequestParam @DateTimeFormat(iso = DateTimeFormat.ISO.DATE) LocalDate date) {
        User user = userService.getUserByEmail(userDetails.getUsername());
        nutritionDiaryService.clearDay(user, date);
        return ResponseEntity.ok(ApiResponse.ok("Day cleared successfully", null));
    }

    @PatchMapping("/note")
    public ResponseEntity<ApiResponse<Void>> updateNote(
            @AuthenticationPrincipal UserDetails userDetails,
            @RequestParam @DateTimeFormat(iso = DateTimeFormat.ISO.DATE) LocalDate date,
            @RequestParam String note) {
        User user = userService.getUserByEmail(userDetails.getUsername());
        nutritionDiaryService.updateDailyNote(user, date, note);
        return ResponseEntity.ok(ApiResponse.ok("Note updated successfully", null));
    }

    @PostMapping("/batch")
    public ResponseEntity<ApiResponse<Void>> addBatch(
            @AuthenticationPrincipal UserDetails userDetails,
            @RequestBody List<DailyEatingDTO> dailyEatingDTOs) {
        User user = userService.getUserByEmail(userDetails.getUsername());
        nutritionDiaryService.addMultipleDailyEatings(user, dailyEatingDTOs);
        return ResponseEntity.ok(ApiResponse.ok("Batch added successfully", null));
    }

    @PatchMapping("/item/{id}/status")
    public ResponseEntity<ApiResponse<DailyEatingDTO>> updateMealItemStatus(
            @PathVariable UUID id,
            @RequestParam Boolean   isEaten) {
        DailyEatingDTO response = nutritionDiaryService.updateMealItemStatus(id, isEaten);
        return ResponseEntity.ok(ApiResponse.ok("Item status updated successfully", response));
    }

    @PatchMapping("/slot/{id}/status")
    public ResponseEntity<ApiResponse<DailyEatingDTO>> updateMealSlotStatus(
            @PathVariable UUID id,
            @RequestParam Boolean isEaten) {
        DailyEatingDTO response = nutritionDiaryService.updateMealSlotStatus(id, isEaten);
        return ResponseEntity.ok(ApiResponse.ok("Meal slot status updated successfully", response));
    }
}
