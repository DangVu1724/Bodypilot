package com.bodypilot.backend.model.dto;

import com.bodypilot.backend.model.enums.FoodType;
import lombok.AllArgsConstructor;
import lombok.Builder;
import lombok.Data;
import lombok.NoArgsConstructor;

import java.math.BigDecimal;
import java.util.List;
import java.util.UUID;

@Data
@Builder
@NoArgsConstructor
@AllArgsConstructor
public class FoodResponse {
    private UUID id;
    private String name;
    private FoodType type;
    private BigDecimal caloriesPer100g;
    private BigDecimal proteinPer100g;
    private BigDecimal fatPer100g;
    private BigDecimal carbsPer100g;
    private BigDecimal fiberPer100g;
    private BigDecimal sugarPer100g;
    private BigDecimal sodiumMgPer100g;
    private FoodCategoryDTO category;
    private BigDecimal defaultServingSize;
    private String defaultUnit;
    private String imageUrl;
    private String description;
    private Integer healthScore;
    private List<FoodServingDTO> servings;
    private List<DietTagDTO> dietTags;
    private RecipeDTO recipe;
}
