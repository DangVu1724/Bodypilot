package com.bodypilot.backend.model.dto;

import lombok.AllArgsConstructor;
import lombok.Builder;
import lombok.Data;
import lombok.NoArgsConstructor;

import java.util.List;

@Data
@Builder
@NoArgsConstructor
@AllArgsConstructor
public class RecipeRequest {
    private Integer servings;
    private Integer cookingTimeMinutes;
    private String instructions;
    private List<RecipeIngredientRequest> ingredients;
}
