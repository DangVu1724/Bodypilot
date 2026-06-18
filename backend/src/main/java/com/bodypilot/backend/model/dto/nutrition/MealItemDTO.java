package com.bodypilot.backend.model.dto.nutrition;

import com.fasterxml.jackson.annotation.JsonAlias;
import lombok.*;

import java.math.BigDecimal;
import java.util.UUID;

@Data
@Builder
@NoArgsConstructor
@AllArgsConstructor
public class MealItemDTO {
    private UUID id;
    private UUID foodId;
    private BigDecimal servingQuantity;
    private Integer orderIndex;
    
    // Snapshots
    @JsonAlias({"foodName", "foodNameSnapshot"})
    private String foodName;

    @JsonAlias({"calories", "caloriesSnapshot"})
    private BigDecimal calories;

    @JsonAlias({"protein", "proteinSnapshot"})
    private BigDecimal protein;

    @JsonAlias({"fat", "fatSnapshot"})
    private BigDecimal fat;

    @JsonAlias({"carbs", "carbsSnapshot"})
    private BigDecimal carbs;

    @JsonAlias({"fiber", "fiberSnapshot"})
    private BigDecimal fiber;

    @JsonAlias({"servingUnit", "servingUnitSnapshot"})
    private String servingUnit;

    @JsonAlias({"imageUrl", "imageUrlSnapshot"})
    private String imageUrl;
    
    private Boolean isCustom;
    private Boolean isEaten;
}
