package com.bodypilot.backend.model.dto;

import lombok.AllArgsConstructor;
import lombok.Builder;
import lombok.Data;
import lombok.NoArgsConstructor;

import java.util.List;
import java.util.UUID;

@Data
@Builder
@NoArgsConstructor
@AllArgsConstructor
public class RecipeDTO {
    private UUID id;
    private Integer servings;
    private Integer cookingTimeMinutes;
    private String instructions;
    private List<RecipeIngredientDTO> ingredients;
}
