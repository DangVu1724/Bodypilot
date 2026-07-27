package com.bodypilot.backend.model.dto.workout;

import com.fasterxml.jackson.annotation.JsonAlias;
import lombok.*;

import java.util.UUID;

@Data
@Builder
@NoArgsConstructor
@AllArgsConstructor
public class DailyWorkoutItemDTO {
    private UUID id;
    private UUID exerciseId;
    private Integer orderIndex;
    private Boolean isCompleted;

    @JsonAlias({"exerciseName", "exerciseNameSnapshot"})
    private String exerciseName;

    @JsonAlias({"sets", "setsSnapshot"})
    private Integer sets;

    @JsonAlias({"reps", "repsSnapshot"})
    private Integer reps;

    @JsonAlias({"weightKg", "weightKgSnapshot"})
    private Double weightKg;

    @JsonAlias({"restSeconds", "restSecondsSnapshot"})
    private Integer restSeconds;

    @JsonAlias({"durationMinutes", "durationMinutesSnapshot"})
    private Integer durationMinutes;

    @JsonAlias({"distanceKm", "distanceKmSnapshot"})
    private Double distanceKm;

    @JsonAlias({"caloriesBurned", "caloriesBurnedSnapshot"})
    private Double caloriesBurned;

    private Boolean isCustom;
    private String notes;
}
