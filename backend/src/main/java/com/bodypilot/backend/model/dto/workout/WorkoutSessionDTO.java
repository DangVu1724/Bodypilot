package com.bodypilot.backend.model.dto.workout;

import lombok.AllArgsConstructor;
import lombok.Builder;
import lombok.Data;
import lombok.NoArgsConstructor;

import java.util.List;
import java.util.UUID;

@Data
@Builder
@NoArgsConstructor
@AllArgsConstructor
public class WorkoutSessionDTO {
    private UUID id;
    private UUID planId;
    private Integer dayNumber;
    private String name;
    private List<WorkoutSessionExerciseDTO> exercises;
}
