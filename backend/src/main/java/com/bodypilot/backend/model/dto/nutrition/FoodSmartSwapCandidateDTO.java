package com.bodypilot.backend.model.dto.nutrition;

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
public class FoodSmartSwapCandidateDTO {
    private UUID foodId;
    private String foodName;
    private String categoryName;
    private String imageUrl;
    private BigDecimal recommendedServingQuantity;
    private BigDecimal calories;
    private BigDecimal protein;
    private BigDecimal fat;
    private BigDecimal carbs;
    private Double matchScore;
    private String matchReason;
}
