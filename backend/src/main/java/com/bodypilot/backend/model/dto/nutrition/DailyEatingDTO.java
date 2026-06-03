package com.bodypilot.backend.model.dto.nutrition;

import lombok.*;

import java.math.BigDecimal;
import java.time.LocalDate;
import java.util.List;
import java.util.UUID;

@Data
@Builder
@NoArgsConstructor
@AllArgsConstructor
public class DailyEatingDTO {
    private UUID id;
    private LocalDate date;
    private String note;
    private Boolean isAiGenerated;
    private BigDecimal totalCaloriesPlanned;
    private BigDecimal totalCaloriesEaten;
    private List<MealSlotDTO> mealSlots;
}
