package com.bodypilot.backend.model.dto.ai;

import lombok.AllArgsConstructor;
import lombok.Builder;
import lombok.Data;
import lombok.NoArgsConstructor;

import java.math.BigDecimal;
import java.time.LocalDateTime;
import java.util.UUID;

@Data
@Builder
@NoArgsConstructor
@AllArgsConstructor
public class AiDietEvaluationLogDTO {
    private UUID id;
    private UUID userId;
    private BigDecimal targetCalories;
    private BigDecimal rawCalories;
    private BigDecimal finalCalories;
    private BigDecimal calorieMape;
    private BigDecimal calorieMae;
    private Boolean wasScaled;
    private BigDecimal scaleFactor;
    private Integer totalItemsCount;
    private Integer allergiesCheckedCount;
    private Integer dietsCheckedCount;
    private Integer dislikesCheckedCount;
    private Long executionTimeMs;
    private String note;
    private LocalDateTime createdAt;
}
