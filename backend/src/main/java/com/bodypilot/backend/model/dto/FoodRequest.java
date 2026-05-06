package com.bodypilot.backend.model.dto;

import lombok.AllArgsConstructor;
import lombok.Builder;
import lombok.Data;
import lombok.NoArgsConstructor;

import java.util.UUID;

@Data
@Builder
@NoArgsConstructor
@AllArgsConstructor
public class FoodRequest {
    private String name;
    private String type;
    private Double caloriesPer100g;
    private Double proteinPer100g;
    private Double fatPer100g;
    private Double carbsPer100g;
    private Double fiberPer100g;
    private Double sugarPer100g;
    private Double sodiumMgPer100g;
    private UUID categoryId;
    private Double defaultServingSize;
    private String defaultUnit;
    private String imageUrl;
    private String description;
    private Integer healthScore;
    private RecipeRequest recipe;
}
