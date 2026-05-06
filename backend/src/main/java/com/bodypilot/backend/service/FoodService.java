package com.bodypilot.backend.service;

import com.bodypilot.backend.model.dto.*;
import org.springframework.data.domain.Pageable;

import java.util.List;
import java.util.UUID;

public interface FoodService {
    PageResponse<FoodSummaryResponse> searchFoods(String query, UUID categoryId, Pageable pageable);
    PageResponse<FoodSummaryResponse> getFoodsByType(String type, Pageable pageable);
    FoodResponse getFoodById(UUID id);
    FoodResponse createFood(com.bodypilot.backend.model.dto.FoodRequest request);
    FoodResponse updateFood(UUID id, com.bodypilot.backend.model.dto.FoodRequest request);
    void deleteFood(UUID id);
    List<FoodCategoryDTO> getAllCategories();
    List<DietTagDTO> getDietTags();
}
