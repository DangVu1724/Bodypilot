package com.bodypilot.backend.model.dto.step;

import lombok.AllArgsConstructor;
import lombok.Builder;
import lombok.Data;
import lombok.NoArgsConstructor;

import java.time.LocalDate;
import java.util.UUID;

@Data
@Builder
@NoArgsConstructor
@AllArgsConstructor
public class StepHistoryDTO {
    private UUID id;
    private LocalDate date;
    private Integer stepCount;
    private Double caloriesBurned;
    private Double distanceKm;
}
