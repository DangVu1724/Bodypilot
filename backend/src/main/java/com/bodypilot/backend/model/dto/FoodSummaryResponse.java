package com.bodypilot.backend.model.dto;

import com.bodypilot.backend.model.enums.FoodType;
import lombok.AllArgsConstructor;
import lombok.Builder;
import lombok.Data;
import lombok.NoArgsConstructor;

import java.math.BigDecimal;
import java.util.UUID;

@Data
@Builder
@NoArgsConstructor
@AllArgsConstructor
public class FoodSummaryResponse {
    private UUID id;
    private String name;
    private FoodType type;
    private BigDecimal caloriesPer100g;
    private BigDecimal proteinPer100g;
    private BigDecimal fatPer100g;
    private BigDecimal carbsPer100g;
    private String imageUrl;
    private String categoryName;
    private Integer healthScore;
}
