package com.bodypilot.backend.model.dto.step;

import lombok.AllArgsConstructor;
import lombok.Builder;
import lombok.Data;
import lombok.NoArgsConstructor;

import java.time.LocalDate;

@Data
@Builder
@NoArgsConstructor
@AllArgsConstructor
public class StepSyncRequest {
    private LocalDate date;
    private Integer stepCount;
    private Double caloriesBurned;
    private Double distanceKm;
}
