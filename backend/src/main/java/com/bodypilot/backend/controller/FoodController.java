package com.bodypilot.backend.controller;

import com.bodypilot.backend.model.dto.*;
import com.bodypilot.backend.service.FoodService;
import lombok.RequiredArgsConstructor;
import org.springframework.data.domain.PageRequest;
import org.springframework.data.domain.Pageable;
import org.springframework.http.ResponseEntity;
import org.springframework.web.bind.annotation.*;

import java.util.List;
import java.util.UUID;

@RestController
@RequestMapping("/api/v1/foods")
@RequiredArgsConstructor
public class FoodController {

    private final FoodService foodService;

    @GetMapping("/search")
    public ResponseEntity<ApiResponse<PageResponse<FoodSummaryResponse>>> search(
            @RequestParam(required = false, defaultValue = "") String query,
            @RequestParam(required = false) UUID categoryId,
            @RequestParam(defaultValue = "0") int page,
            @RequestParam(defaultValue = "20") int size) {
        Pageable pageable = PageRequest.of(page, size);
        PageResponse<FoodSummaryResponse> results = foodService.searchFoods(query, categoryId, pageable);
        return ResponseEntity.ok(ApiResponse.ok("Search successful", results));
    }

    @GetMapping("/ingredients")
    public ResponseEntity<ApiResponse<PageResponse<FoodSummaryResponse>>> getIngredients(
            @RequestParam(defaultValue = "0") int page,
            @RequestParam(defaultValue = "100") int size) {
        Pageable pageable = PageRequest.of(page, size);
        PageResponse<FoodSummaryResponse> results = foodService.getFoodsByType("INGREDIENT", pageable);
        return ResponseEntity.ok(ApiResponse.ok("Ingredients retrieved", results));
    }

    @GetMapping("/dishes")
    public ResponseEntity<ApiResponse<PageResponse<FoodSummaryResponse>>> getDishes(
            @RequestParam(defaultValue = "0") int page,
            @RequestParam(defaultValue = "100") int size) {
        Pageable pageable = PageRequest.of(page, size);
        PageResponse<FoodSummaryResponse> results = foodService.getFoodsByType("DISH", pageable);
        return ResponseEntity.ok(ApiResponse.ok("Dishes retrieved", results));
    }

    @GetMapping("/{id}")
    public ResponseEntity<ApiResponse<FoodResponse>> getById(@PathVariable UUID id) {
        FoodResponse food = foodService.getFoodById(id);
        return ResponseEntity.ok(ApiResponse.ok("Food found", food));
    }

    @GetMapping("/categories")
    public ResponseEntity<ApiResponse<List<FoodCategoryDTO>>> getCategories() {
        List<FoodCategoryDTO> categories = foodService.getAllCategories();
        return ResponseEntity.ok(ApiResponse.ok("Categories retrieved", categories));
    }

    @GetMapping("/diet-tags")
    public ResponseEntity<ApiResponse<List<DietTagDTO>>> getDietTags() {
        List<DietTagDTO> tags = foodService.getDietTags();
        return ResponseEntity.ok(ApiResponse.ok("Diet tags retrieved", tags));
    }

    @PostMapping
    public ResponseEntity<ApiResponse<FoodResponse>> createFood(@RequestBody com.bodypilot.backend.model.dto.FoodRequest request) {
        FoodResponse food = foodService.createFood(request);
        return ResponseEntity.ok(ApiResponse.ok("Food created", food));
    }

    @PutMapping("/{id}")
    public ResponseEntity<ApiResponse<FoodResponse>> updateFood(@PathVariable UUID id, @RequestBody com.bodypilot.backend.model.dto.FoodRequest request) {
        FoodResponse food = foodService.updateFood(id, request);
        return ResponseEntity.ok(ApiResponse.ok("Food updated", food));
    }

    @DeleteMapping("/{id}")
    public ResponseEntity<ApiResponse<Void>> deleteFood(@PathVariable UUID id) {
        foodService.deleteFood(id);
        return ResponseEntity.ok(ApiResponse.ok("Food deleted", null));
    }
}
