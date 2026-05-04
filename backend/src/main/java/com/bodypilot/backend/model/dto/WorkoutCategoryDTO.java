package com.bodypilot.backend.model.dto;

import com.bodypilot.backend.model.enums.WorkoutType;
import lombok.AllArgsConstructor;
import lombok.Builder;
import lombok.Data;
import lombok.NoArgsConstructor;

import java.util.UUID;

@Data
@Builder
@NoArgsConstructor
@AllArgsConstructor
public class WorkoutCategoryDTO {
    private UUID id;
    private String code;
    private String name;
    private String description;
    private WorkoutType workoutType;
}
