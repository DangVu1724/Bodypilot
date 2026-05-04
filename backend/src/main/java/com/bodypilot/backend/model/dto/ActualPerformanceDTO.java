package com.bodypilot.backend.model.dto;

import lombok.AllArgsConstructor;
import lombok.Builder;
import lombok.Data;
import lombok.NoArgsConstructor;

import java.util.UUID;

@Data
@Builder
@NoArgsConstructor
@AllArgsConstructor
public class ActualPerformanceDTO {
    private UUID exerciseId;
    private Integer actualSets;
    private Integer actualReps;
    private Double actualWeightKg;
    private Integer actualDurationMinutes;
    private Double actualDistanceKm;
}
