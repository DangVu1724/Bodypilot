package com.bodypilot.backend.model.dto.nutrition;

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
    private String foodName;
    private BigDecimal calories;
    private BigDecimal protein;
    private BigDecimal fat;
    private BigDecimal carbs;
    private BigDecimal fiber;
    private String servingUnit;
    private String imageUrl;
    
    private Boolean isCustom;
    private Boolean isEaten;
}
