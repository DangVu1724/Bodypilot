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
public class ExerciseItemDTO {
    private UUID exerciseId;
    private Integer order;
    private Integer sets;
    private Integer reps;
    private Double weightKg;
    private Integer restSeconds;
    private Integer durationMinutes;
    private Double distanceKm;
}
