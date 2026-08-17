package com.bodypilot.backend.service;

import java.util.List;
import java.util.UUID;

import org.springframework.data.domain.Pageable;

import com.bodypilot.backend.model.dto.common.PageResponse;
import com.bodypilot.backend.model.dto.nutrition.DietTagDTO;
import com.bodypilot.backend.model.dto.nutrition.FoodCategoryDTO;
import com.bodypilot.backend.model.dto.nutrition.FoodResponse;
import com.bodypilot.backend.model.dto.nutrition.FoodSummaryResponse;

public interface FoodService {
    PageResponse<FoodSummaryResponse> searchFoods(String query, UUID categoryId, Pageable pageable);

    PageResponse<FoodSummaryResponse> getFoodsByType(String type, Pageable pageable);

    FoodResponse getFoodById(UUID id);

    FoodResponse createFood(com.bodypilot.backend.model.dto.nutrition.FoodRequest request);

    FoodResponse updateFood(UUID id, com.bodypilot.backend.model.dto.nutrition.FoodRequest request);

    void deleteFood(UUID id);

    List<FoodCategoryDTO> getAllCategories();

    List<DietTagDTO> getDietTags();
}
