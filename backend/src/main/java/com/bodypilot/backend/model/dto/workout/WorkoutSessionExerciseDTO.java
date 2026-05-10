package com.bodypilot.backend.model.dto.workout;

import lombok.AllArgsConstructor;
import lombok.Builder;
import lombok.Data;
import lombok.NoArgsConstructor;

import java.util.UUID;

@Data
@Builder
@NoArgsConstructor
@AllArgsConstructor
public class WorkoutSessionExerciseDTO {
    private UUID id;
    private ExerciseDTO exercise;
    private Integer order;
    private Integer sets;
    private Integer reps;
    private Double weightKg;
    private Integer restSeconds;
    private Integer durationMinutes;
    private Double distanceKm;
}
